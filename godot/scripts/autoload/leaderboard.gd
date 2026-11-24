extends Node

## Online leaderboard, mirroring the web build's Firestore `scores_v2` board.
##
## The web client uses the Firebase JS SDK; a Godot export can't, so this talks
## to the same database over the Firestore REST API with plain HTTPRequest. The
## `scores_v2` collection is world-readable and world-creatable (validated by
## security rules), so no auth or SDK is needed — only the public project id and
## web API key, the very values shipped in index.html.
##
## Flow:
##   • Every finished run is saved locally first (SaveManager), then this tries to
##     push it online. A push that fails (offline, blocked) simply leaves the
##     local entry marked unsynced.
##   • `sync_pending()` retries every unsynced local score — call it to catch up
##     retroactively once the player is back online.
##   • `fetch_online()` pulls the global top scores for the combined view.
##
## Units on the wire match the web build: `date` and `time` are both
## MILLISECONDS. Locally (SaveManager) both are seconds; the encode/decode below
## converts. Godot builds before this fix uploaded `time` in seconds as a
## Firestore double — those legacy rows are recognised by that type and read back
## as seconds, so they still display correctly.
##
## Test and capture harnesses must never publish: set `online_enabled = false`
## before they touch scores. A session that does not persist its save
## (`SaveManager.persist == false`) never reaches the network either.
##
## All network work is best-effort: a failure updates `status`/`last_error` and
## emits `sync_state_changed`, never crashes or blocks the game.

const PROJECT_ID := "solitaire-tower-9b415"
const API_KEY := "AIzaSyD5WyhbaRz209eadnuIO_2piPr5WsLY0RE"
const COLLECTION := "scores_v2"
const FETCH_LIMIT := 50
const REQUEST_TIMEOUT := 12.0

const BASE := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents"

## The last fetched global scores, newest fetch wins. Each is a plain entry dict
## shaped like a local highscore: {name, score, time, all_floors, date}.
var online_scores: Array = []
## "idle" | "syncing" | "ok" | "offline" | "error"
var status := "idle"
var last_error := ""

## Master switch for every request this node makes. Harnesses turn it off.
var online_enabled := true

signal online_scores_updated(scores: Array)
signal sync_state_changed(status: String)

var _syncing := false
## Keys (see `_entry_key`) of scores whose upload is in flight, so a sync
## started while the end screen's upload is still pending cannot send the same
## run a second time.
var _in_flight := {}


func _ready() -> void:
	# Push each finished run online right after it is saved locally.
	if SaveManager.has_signal("score_recorded"):
		SaveManager.score_recorded.connect(_on_score_recorded)


func _on_score_recorded(entry: Dictionary) -> void:
	submit_score(entry)


# ── Public API ────────────────────────────────────────────────────────────────

## Pushes one local entry to the online board. On success marks it synced in the
## local table so it is not sent twice.
func submit_score(entry: Dictionary) -> void:
	if not _can_go_online():
		return
	if bool(entry.get("synced", false)) or _in_flight.has(_entry_key(entry)):
		return
	_set_status("syncing")
	_upload(entry, func(ok: bool):
		_set_status("ok" if ok else "offline"))


## Retries every local score not yet on the board, then refreshes the online
## view. Safe to call anytime the player is (or might be) back online.
func sync_pending() -> void:
	if _syncing or not _can_go_online():
		return
	var pending := []
	for e in SaveManager.unsynced_scores():
		if not _in_flight.has(_entry_key(e)):
			pending.append(e)
	if pending.is_empty():
		fetch_online()
		return
	_syncing = true
	_set_status("syncing")
	_sync_next(pending, 0)


func _sync_next(pending: Array, i: int) -> void:
	if i >= pending.size():
		_syncing = false
		fetch_online()
		return
	var entry: Dictionary = pending[i]
	if bool(entry.get("synced", false)) or _in_flight.has(_entry_key(entry)):
		_sync_next(pending, i + 1)  # uploaded meanwhile by submit_score()
		return
	_upload(entry, func(ok: bool):
		if ok:
			_sync_next(pending, i + 1)
		else:
			# Stop on the first failure — almost certainly offline; try again later.
			_syncing = false
			_set_status("offline"))


## Pulls the global top scores, ordered like the web query (score desc, time asc).
func fetch_online() -> void:
	if not _can_go_online():
		return
	var query := {
		"structuredQuery": {
			"from": [{"collectionId": COLLECTION}],
			"orderBy": [
				{"field": {"fieldPath": "score"}, "direction": "DESCENDING"},
				{"field": {"fieldPath": "time"}, "direction": "ASCENDING"},
			],
			"limit": FETCH_LIMIT,
		}
	}
	var url := "%s:runQuery?key=%s" % [BASE % PROJECT_ID, API_KEY]
	_send(url, HTTPClient.METHOD_POST, JSON.stringify(query), func(ok: bool, _code: int, resp):
		if not ok:
			_set_status("offline")
			return
		online_scores = parse_run_query(resp)
		_set_status("ok")
		online_scores_updated.emit(online_scores))


## POSTs one entry, tracking it as in flight until the answer arrives.
func _upload(entry: Dictionary, on_done: Callable) -> void:
	var key := _entry_key(entry)
	_in_flight[key] = true
	var body := JSON.stringify({"fields": to_firestore_fields(entry)})
	var url := "%s/%s?key=%s" % [BASE % PROJECT_ID, COLLECTION, API_KEY]
	_send(url, HTTPClient.METHOD_POST, body, func(ok: bool, _code: int, _resp):
		_in_flight.erase(key)
		if ok:
			SaveManager.mark_score_synced(entry)
		on_done.call(ok))


func _can_go_online() -> bool:
	return online_enabled and SaveManager.persist


## Identity of one recorded run. The local date is part of it, so two genuine
## runs with the same name, score and time are still two runs.
static func _entry_key(e: Dictionary) -> String:
	return "%s|%d|%.3f|%d" % [String(e.get("name", "")), int(e.get("score", 0)),
		float(e.get("time", 0.0)), int(e.get("date", 0))]


# ── Encoding / decoding (pure, unit-tested) ──────────────────────────────────

## A local highscore entry → Firestore typed fields. Sends exactly the five keys
## the security rules allow, with the date AND time in integer milliseconds like
## the web build (locally both are seconds).
static func to_firestore_fields(entry: Dictionary) -> Dictionary:
	var date_ms := int(entry.get("date", 0))
	# Local dates are unix seconds; the web writes milliseconds. Normalise up so
	# the two clients' timestamps share a scale.
	if date_ms > 0 and date_ms < 100000000000:
		date_ms *= 1000
	var name := String(entry.get("name", "Anonymous")).substr(0, 20)
	if name == "":
		name = "Anonymous"
	return {
		"name": {"stringValue": name},
		"score": {"integerValue": str(int(entry.get("score", 0)))},
		"time": {"integerValue": str(int(round(float(entry.get("time", 0.0)) * 1000.0)))},
		"date": {"integerValue": str(date_ms)},
		"allFloors": {"booleanValue": bool(entry.get("all_floors", false))},
	}


## One Firestore document's fields → a local-shaped entry.
static func from_firestore_fields(fields: Dictionary) -> Dictionary:
	return {
		"name": _string_of(fields.get("name", {})),
		"score": _number_of(fields.get("score", {})),
		"time": time_seconds_of(fields.get("time", {})),
		"date": _number_of(fields.get("date", {})),
		"all_floors": bool(fields.get("allFloors", {}).get("booleanValue", false)),
		"synced": true,
	}


## A runQuery response body → sorted entries. Rows without a document (the empty
## `readTime` marker) are skipped.
static func parse_run_query(body: String) -> Array:
	var parsed = JSON.parse_string(body)
	var out := []
	if typeof(parsed) != TYPE_ARRAY:
		return out
	for row in parsed:
		if typeof(row) == TYPE_DICTIONARY and row.has("document"):
			var fields = row["document"].get("fields", {})
			if typeof(fields) == TYPE_DICTIONARY:
				out.append(from_firestore_fields(fields))
	return out


## Local + online into one board: deduped, sorted score desc then time asc.
## A local score already uploaded appears once. Capped at `limit`.
static func merge_scores(local: Array, online: Array, limit: int = FETCH_LIMIT) -> Array:
	var seen := {}
	var merged := []
	for source in [local, online]:
		for e in source:
			var key := "%s|%d|%.3f" % [String(e.get("name", "")), int(e.get("score", 0)),
				float(e.get("time", 0.0))]
			if seen.has(key):
				continue
			seen[key] = true
			merged.append(e)
	merged.sort_custom(func(a, b):
		if int(a.get("score", 0)) != int(b.get("score", 0)):
			return int(a.get("score", 0)) > int(b.get("score", 0))
		return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	if merged.size() > limit:
		merged.resize(limit)
	return merged


## A Firestore `time` field → seconds. The web build and current Godot builds
## write integer milliseconds; Godot builds before the fix wrote seconds as a
## double, and only they ever produced a doubleValue here.
static func time_seconds_of(field: Dictionary) -> float:
	if field.has("doubleValue"):
		return float(field["doubleValue"])
	return float(_number_of(field)) / 1000.0


static func _string_of(field: Dictionary) -> String:
	return String(field.get("stringValue", ""))


static func _number_of(field: Dictionary):
	if field.has("integerValue"):
		return int(String(field["integerValue"]))
	if field.has("doubleValue"):
		return field["doubleValue"]
	return 0


# ── HTTP plumbing ─────────────────────────────────────────────────────────────

## Fires one request on a throwaway HTTPRequest node and hands the callback
## (ok, http_code, body_text). `ok` is true only on a 2xx transport success.
func _send(url: String, method: int, body: String, on_done: Callable) -> void:
	# Last line of defence: nothing leaves the machine from a harness run.
	if not _can_go_online():
		on_done.call(false, 0, "")
		return
	var req := HTTPRequest.new()
	req.timeout = REQUEST_TIMEOUT
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _headers, data: PackedByteArray):
		var text := data.get_string_from_utf8()
		var ok := result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300
		if not ok:
			last_error = "result=%d http=%d" % [result, code]
		on_done.call(ok, code, text)
		req.queue_free())
	var headers := ["Content-Type: application/json"]
	var err := req.request(url, headers, method, body)
	if err != OK:
		last_error = "request error %d" % err
		on_done.call(false, 0, "")
		req.queue_free()


func _set_status(s: String) -> void:
	status = s
	sync_state_changed.emit(s)
