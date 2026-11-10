# Barrer Software AMP Templates

Custom sovereign application templates for the [CubeCoders AMP](https://cubecoders.com/AMP) Generic Module, engineered and maintained by Barrer Software.

## Repository Setup in AMP

To add this repository to your AMP installation:

1. Open your AMP instance management portal (e.g. `https://game.barrer.net`).
2. Navigate to **Configuration** -> **Application** -> **Template Repositories**.
3. Add a new repository:
   * **URL / Source**: `https://github.com/ssfdre38/barrer-amp-templates.git`
4. Fetch updates. All templates from this repository will appear under the `barrer/` prefix without duplicating any upstream community game templates.

---

## Included Templates

### 1. `llama-cpp` (llama.cpp Inference Server)
* **Manifests**: `llama-cpp.kvp`, `llama-cppconfig.json`, `llama-cppports.json`, `llama-cppupdates.json`
* **Features**:
  * **Built-in Web Chat UI**: Access `llama-server`'s in-browser chat UI directly from the AMP dashboard button (`http://{ip}:{port}`).
  * **OpenAI-Compatible API**: Seamless `/v1/chat/completions` endpoint for local bots, developer tools, and sovereign companions.
  * **Panel Model Selection**: Configure GGUF model path, context length, GPU offloading (`-ngl`), CPU threads, and parallel slots directly in the AMP web panel.
  * **Automated Updates**: One-click updates powered by GitHub Release downloads directly from `ggerganov/llama.cpp`.
  * **Hardware Telemetry**: Process supervision, memory tracking, and auto-restart via AMP's native process watchdog.

---

## Authors & Maintenance
* **Daniel Elliott** ([@ssfdre38](https://github.com/ssfdre38))
* **Ash** (Autonomous Companion Architecture)
* **Barrer Software**
