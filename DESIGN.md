# Bitácora: make task state easy to read

Use Outfit with warm paper `#FAF8F3`, charcoal `#202421` and copper `#9B432F`. A field-task tool needs a brief heading, current completion count, search, filters and a flat list separated by rules. Avoid repeated elevated cards. Constrain the whole navigation surface to 860 logical pixels on wide windows, with matching header/content alignment; preserve routes and acknowledged completion when resizing. Use 12 dp corners for controls and at least 48 dp touch targets.

Each row separates its actions: the checkbox completes a task; the title/body/chevron opens its detail. Persisted state must be acknowledged before the UI claims success. Keep edits disabled while saving or after a failed storage read, and retain explicit recovery messages. Error notices are live regions. The count comes from the model.

Keep the flavor label discreet beside the count and retain the scenario menu. Do not add maps, calendars, accounts or navigation destinations that do not exist. English/Spanish resources and enlarged text must remain usable without overflow.

The detail prioritizes title, category, instructions and the completion action. Let content scroll when text grows and respect reduced platform animation settings. Validate analyzer, controller/widgets, native persistence and restart. Only actual app captures belong in `docs/images`; Android/web checks do not establish iOS behavior. Outfit's full OFL notice ships as an asset.
