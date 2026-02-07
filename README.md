# OptionStatusChip

A macOS push-to-talk dictation assistant with a floating status chip.

- Hold trigger key: starts recording (`active`)
- Release trigger key: transcribes speech with AI (`transcribing`)
- Optional cleanup/translation with AI (`cloud` Gemini or `local` Ollama)
- Types result into the currently focused app (`typing`)

## Repository structure

- `Sources/App`: App entry and orchestration (`AppDelegate`, `main`)
- `Sources/UI`: UI components (`StatusChipController`)
- `Sources/Services`: runtime services (keyboard monitor, recorder, transcriber, AI clients, typer, logger)
- `Sources/Core`: pure configuration/prompt-building logic (unit tested)
- `Tests/OptionStatusChipCoreTestsRunner`: runnable unit-test cases for core module
- `build.sh`: builds `build/OptionStatusChip.app`
- `test.sh`: runs the core test suite

## Requirements

- macOS 13+
- Xcode Command Line Tools (`swiftc`, `swift run`)

## Quick commands (npm-style)

Use the single runner:

```bash
./run build
./run start
./run dev
./run test
./run logs
./run stop
```

## Build app

```bash
./run build
```

## Run app

Cloud (Gemini):

```bash
./run start
```

Local (Ollama cleanup):

```bash
AI_MODE=local ./run start
```

Trigger key override (`Fn`):

```bash
TRIGGER_KEY=fn ./run start
```

Run in terminal (recommended while debugging):

```bash
./run dev
```

## No-option workflow with .env

1. Copy `.env.example` to `.env`
2. Set your values once (especially `GEMINI_API_KEY`)
3. Run using short commands:

```bash
cp .env.example .env
./run start
```

## Configuration

- `TRIGGER_KEY`: `option` (default) or `fn`
- `AI_MODE`: `cloud` (default) or `local`
- `TARGET_LANGUAGE`: e.g. `English`, `Hindi`, `Spanish` (optional)

Cloud settings:

- `GEMINI_API_KEY` required for `AI_MODE=cloud`
- `GEMINI_MODEL` default: `gemini-2.5-flash`
- `GEMINI_TRANSCRIBE_MODEL` default: `gemini-2.5-flash` (audio transcription)
- `GEMINI_TRANSCRIBE_FALLBACK_MODEL` default: `gemini-2.0-flash` (used only when primary transcription model is rate-limited)
- `GEMINI_URL` default: `https://generativelanguage.googleapis.com`
- `CLOUD_SINGLE_PASS` default: `1` (faster; single Gemini call for transcribe+cleanup+translate)
- `RECORDING_TAIL_MS` default: `220` (captures last spoken syllables after key release)

Local settings:

- `OLLAMA_URL` default: `http://127.0.0.1:11434`
- `OLLAMA_MODEL` default: `qwen2.5:3b-instruct`
- `LOCAL_STT_COMMAND` default: `whisper-cli`
- `LOCAL_STT_MODEL_PATH` required in `AI_MODE=local` (path to whisper.cpp model)
- `LOCAL_STT_LANGUAGE` optional (e.g. `en`, `hi`, `es`; unset = auto-detect)

Logging settings:

- `LOG_LEVEL`: `debug` | `info` | `warning` | `error` (default: `info`)
- `LOG_SHOW_SECRETS`: `0` (default, mask keys) or `1` (show full secrets in logs)

## Permissions

Grant these in **System Settings -> Privacy & Security**:

1. Accessibility
2. Microphone

## Logs

Startup logs include a full configuration snapshot:

- mode (`cloud` / `local`)
- trigger key
- target language
- Gemini/Ollama model + URLs
- Gemini transcription model
- local STT command/model/language
- API key value (masked by default)
- log level and runtime metadata (app version, OS, session, pid)

Realtime app log file:

```bash
tail -f ~/Library/Logs/OptionStatusChip.log
```

Timing fields to monitor speed:

- `transcribe_ms`
- `cleanup_ms` (only when `CLOUD_SINGLE_PASS=0` or local mode)
- `total_ms`

macOS unified logs:

```bash
log stream --style compact --predicate 'process == "OptionStatusChip"'
```

Clear app log:

```bash
: > ~/Library/Logs/OptionStatusChip.log
```

## Tests

Run unit tests for core module:

```bash
./run test
```

## Close app

```bash
osascript -e 'tell application id "com.abcom.optionstatuschip" to quit'
```

or

```bash
pkill -x OptionStatusChip
```
# wispr
