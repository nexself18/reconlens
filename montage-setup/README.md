# Набор для монтажа — установка на Windows

Скачай папку `montage-setup` и дважды кликни `install.bat`. Нужны Windows 10/11, видеокарта NVIDIA со свежим драйвером и около 15 ГБ места на диске.

Что ставится:

| Компонент | Как |
|---|---|
| ffmpeg с NVENC | winget `Gyan.FFmpeg` (full build) |
| Python 3.11 | winget |
| PyTorch с CUDA 12.8 | pip, `download.pytorch.org/whl/cu128` |
| openai-whisper, faster-whisper | pip |
| Модели faster-whisper large-v3 и large-v3-turbo | скачиваются сразу, около 4,5 ГБ |
| Demucs и модель htdemucs | pip, модель скачивается сразу |
| yt-dlp, PySceneDetect, MediaPipe | pip |
| Node.js LTS и Git | winget |
| HyperFrames CLI | `npm i -g hyperframes`, работает и `npx hyperframes` |
| Шрифт TikTok Sans | Google Fonts, ставится для текущего пользователя, копия лежит в `%USERPROFILE%\montage` |
| Папка `clipfinder` | создаётся пустой в `%USERPROFILE%\montage\clipfinder` |

Скрипт можно запускать повторно: всё, что уже установлено, он пропустит. В конце он проверяет, видит ли ffmpeg NVENC и видит ли PyTorch CUDA (`cuda: True`).

## Что скрипт не ставит

- **Скрипты clipfinder.** Их нет ни в этом репозитории, ни в облаке, поэтому скопируй их в созданную папку сам.
- **Скиллы из `~/.claude/skills`.** Они хранятся на компьютере, где ты их ставил. Чтобы перенести их на другой ПК, скопируй папку `%USERPROFILE%\.claude\skills` целиком.
- **Плагины и коннекторы claude.ai** (Higgsfield, Gmail, Drive, Slack, Figma и другие). Они привязаны к аккаунту и сами появятся в любой сессии после входа. Скачивать их не нужно.
