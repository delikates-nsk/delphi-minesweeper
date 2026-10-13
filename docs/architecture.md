# Архитектура minesweeper

## Слои

### UI (VCL)
- `MainForm` — главная форма, игровой цикл.
- `SettingsForm` — выбор сложности.
- `RecordsForm` — таблица рекордов.
- `AboutForm` — о программе.

### Логика (без UI)
- `GameLogic` — игровое поле, правила, очки, события.
- `RecordsManager` — топ-30, XOR + CRC32.
- `Settings` — сложности, константы, настройки.
- `FileUtils` — работа с файлами.

### Рендеринг
- `DigitRenderer` — 7-сегментные LCD-цифры.
- `FieldRenderer` — клетки, мины, флажки.

## Ключевые решения

### Точечная перерисовка

Вместо `pbField.Invalidate` (перерисовать всё поле) — `RedrawCell(Col, Row)`.
`GameLogic.OpenCell` и `ToggleFlag` возвращают `TCellPosArray` — список
изменившихся клеток. UI перерисовывает только их.

### Chord

Обрабатывается через `Shift` в `OnMouseDown` / `OnMouseUp` / `OnMouseMove`:
- `(ssLeft in Shift) and (ssRight in Shift)` — обе кнопки зажаты.
- `ssMiddle in Shift` — эмуляция средней кнопки (некоторые мыши).

### Владение данными

- `TAppSettings` создаётся в `MainForm`, живёт до `FormDestroy`.
- `TRecordsManager` — тоже в `MainForm`, блокирует `records.dat`.
- Формы (`SettingsForm`, `RecordsForm`) **не владеют** настройками —
  только редактируют.