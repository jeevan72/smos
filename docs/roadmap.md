# SimpleMode OS — Development Roadmap

## Phase 1 ✅ (Implemented — Demo Ready)

### 1. Debian Customization (Cubic)
- ✅ Custom wallpaper configuration
- ✅ Custom branding (os-release)
- ✅ Boot splash theme (Plymouth)
- ✅ Pre-installed applications (packages.list)
- ✅ First-boot welcome screen script

### 2. User Onboarding Wizard
- ✅ Welcome screen with animated UI
- ✅ User type selection: Beginner / Elder / Advanced
- ✅ Desktop style selection: Windows / macOS / Linux
- ✅ Profile persistence (localStorage)

### 3. Adaptive UI System
- ✅ **Elder Mode**: Bigger icons (48px+), bigger fonts (20px+), high contrast
- ✅ **Beginner Mode**: Simplified menus, help button everywhere
- ✅ **Advanced Mode**: Normal Linux desktop
- ✅ Live profile switching (demo feature)

### 4. Traditional ML — Typo Detection
- ✅ Levenshtein Distance algorithm
- ✅ 200+ word dictionary (Linux/OS vocabulary)
- ✅ Common misspelling overrides (60+ patterns)
- ✅ Examples: `chorme → chrome`, `instal → install`, `wfi → wifi`

### 5. PageTree Knowledge System
- ✅ 7 knowledge documents (WiFi, Printer, Updates, Software, Permissions, Files, Terminal)
- ✅ Keyword → document mapping (index.json)
- ✅ Score-based document retrieval
- ✅ No RAG, no LLM required

### 6. Basic Assistant
- ✅ Chat UI with message bubbles
- ✅ Full workflow: Question → Typo Fix → Intent Detection → Knowledge Lookup → Response
- ✅ Visual typo correction feedback
- ✅ Source attribution for answers
- ✅ Mode-adaptive responses (simpler language for Elder/Beginner)
- ✅ Suggested follow-up questions

---

## Phase 2 🔄 (Next Week)

### Intent Classification
- TF-IDF vectorization
- Logistic Regression classifier
- Detect: Install Software, Update System, Open App, Connect WiFi

### Action Engine
- Assistant can execute system commands
- Confirmation before execution
- Example: "Install VLC" → `sudo apt install vlc`

### Voice Commands
- Speech-to-Text using Vosk or Whisper Small
- Voice input for the assistant

---

## Phase 3 🚀 (LLM Integration)

### Local LLM
- Qwen2.5 1.5B or Phi-3 Mini
- Requirements: 3-4GB RAM, 1-2GB storage
- Runtime: llama.cpp or Ollama

### Enhanced Workflow
```
Question → Typo Fix → Intent Detection → PageTree Lookup → LLM → Response
```

LLM converts documentation into beginner-friendly explanations.

---

## Phase 4 🚀 (Hybrid AI)

### Smart Router
- Simple queries → Traditional ML (no LLM overhead)
- Complex queries → LLM
- Example: "Open Firefox" → no LLM needed
- Example: "Explain Linux permissions" → LLM

---

## Phase 5 🚀 (Future Research)

### Full RAG System
- Markdown docs → Embeddings → FAISS → Retriever → LLM

### User Learning Engine
- Track user behavior patterns
- Adapt tutorials based on repeated questions
- Decision Trees / Random Forest / User Profiling

### Full Voice Assistant
- Speech-to-Text → Intent Detection → LLM → Text-to-Speech

---

## Summary for Examiners

### ✅ Implemented
- Debian customization using Cubic
- Adaptive onboarding system
- User profiles (Beginner/Elder/Advanced)
- Windows/macOS/Linux style selection
- Traditional ML typo correction (Levenshtein Distance)
- PageTree knowledge retrieval
- Basic assistant prototype

### 🔄 In Progress
- Intent classification (TF-IDF + Logistic Regression)
- Action execution engine
- Voice support

### 🚀 Future Work
- Local LLM integration (Qwen2.5/Phi-3)
- Hybrid AI architecture (Smart Router)
- RAG knowledge retrieval
- Personalized learning system
- Full voice assistant
