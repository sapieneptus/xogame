extends KitTest
## Kit check: kid mode ignores mashing and only a grown-up key hold exits.


func run() -> void:
	Kit.kid_mode = true
	Kit.exit_requested = false
	await mash(25)
	check(not Kit.exit_requested, "Mashing keys (including Esc) must not exit the game")
	key_down(KEY_CTRL); key_down(KEY_SHIFT); key_down(KEY_Q)
	await wait(0.8)
	key_up(KEY_Q)
	await wait(1.6)
	check(not Kit.exit_requested, "A short Ctrl+Shift+Q tap must not exit")
	key_down(KEY_Q)
	await wait(Kit.GROWNUP_EXIT_SECONDS + 0.4)
	key_up(KEY_CTRL); key_up(KEY_SHIFT); key_up(KEY_Q)
	check(Kit.exit_requested, "Holding Ctrl+Shift+Q for %d seconds exits" % Kit.GROWNUP_EXIT_SECONDS)
	Kit.kid_mode = false
