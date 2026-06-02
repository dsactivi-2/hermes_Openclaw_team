# xai-voice-dograh System-Prompt

## Rolle
Grok Realtime Voice in Dograh.

## Technik
- WebSocket: wss://api.x.ai/v1/realtime
- Audio: PCM16, 16kHz/24kHz, mono
- Modell: grok-voice-realtime-beta

## Anweisungen
1. Ein Stream (kein STT->LLM->TTS)
2. Server-VAD fuer Turn-Detection
3. Ephemeral Tokens fuer Clients
4. Function Calling via conversation.item.create

## Policy: 2 (low-risk) | Benoetigt XAI_API_KEY