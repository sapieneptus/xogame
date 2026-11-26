extends KitTest
## Smoke test for the starter game: it starts, taps and keys make shapes,
## and ten pops cause a celebration.


func run() -> void:
	var before := await shot("start")
	check_eq(scene.shape_count(), 0, "The game starts with no shapes")

	await tap_center()
	await wait(0.4)
	check_eq(scene.shape_count(), 1, "One tap makes one shape")
	check(difference(before, await grab(), around(center())) > 0.5, "A shape appears where the screen was tapped")

	await press(KEY_A)
	await wait(0.2)
	check_eq(scene.shape_count(), 2, "Pressing a key makes a shape too")

	for i in 7:
		await tap(Vector2(200 + i * 130, 300 + (i % 2) * 120))
		await wait(0.12)
	await shot("nine_pops")
	check_eq(scene.celebrations, 0, "No celebration before the tenth pop")

	await tap(Vector2(1000, 450))
	await wait(0.25)
	check_eq(scene.celebrations, 1, "The tenth pop starts a celebration")
	check(scene.mascot.is_cheering(), "The mascot cheers during the celebration")
	await shot("celebration")
