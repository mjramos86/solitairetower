extends Node

## Runtime localization.
##
## Text is authored in English at the call site and wrapped with Locale.t();
## when the language is French and a translation exists in the FR map, the French
## is returned, otherwise the English source passes through unchanged. This keeps
## every string written once (in English, at the point it is used) and lets the
## French layer on without restructuring any data — an untranslated string simply
## shows in English rather than breaking.
##
## Format strings keep their %-placeholders: translate first, then apply args,
## e.g. Locale.t("★ %d pts") % score, or Locale.tf("%d/%d floors", [a, b]).

signal changed

const _FR := preload("res://scripts/data/translations_fr.gd")

## Supported languages: code → its own-language display name.
const LANGUAGES := {"en": "English", "fr": "Français"}

var lang := "en"


func _ready() -> void:
	lang = _valid(String(SaveManager.profile.get("language", "en")))


func _valid(l: String) -> String:
	return l if LANGUAGES.has(l) else "en"


## Translate an English source string for the current language.
func t(source) -> String:
	var text := str(source)
	if lang == "en" or text == "":
		return text
	return String(_FR.MAP.get(text, text))


## Translate a format string, then apply args (so placeholders survive).
func tf(source: String, args: Array) -> String:
	return t(source) % args


## Switch language, persist it, and notify listeners so open screens rebuild.
func set_language(l: String) -> void:
	l = _valid(l)
	if l == lang:
		return
	lang = l
	SaveManager.profile["language"] = l
	SaveManager.mark_dirty()
	SaveManager.save_game()
	changed.emit()
