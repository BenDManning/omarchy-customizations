/* Exercise the actual slurp callbacks without a compositor.
 * Surfaces and pending frame callbacks are identity-only sentinels: no Wayland
 * requests are issued. This does not test rendering or physical touch events.
 */
#define main slurp_cli_main
#include "main.c"
#undef main

#define CHECK(condition) do { \
	if (!(condition)) { \
		fprintf(stderr, "  line %d: %s\n", __LINE__, #condition); \
		return false; \
	} \
} while (0)

struct fixture {
	struct slurp_state state;
	struct slurp_seat seat;
	struct slurp_output outputs[2];
	struct slurp_box boxes[3];
	int identities[4];
};

static void fixture_init(struct fixture *f) {
	memset(f, 0, sizeof(*f));
	f->state.running = true;
	wl_list_init(&f->state.outputs);
	wl_list_init(&f->state.boxes);
	wl_list_init(&f->state.seats);
	f->seat.state = &f->state;
	f->seat.touch_id = TOUCH_ID_EMPTY;
	f->seat.button_state = WL_POINTER_BUTTON_STATE_RELEASED;
	wl_list_insert(&f->state.seats, &f->seat.link);
	for (size_t i = 0; i < 2; ++i) {
		struct slurp_output *o = &f->outputs[i];
		o->state = &f->state;
		o->logical_geometry = (struct slurp_box){.x = (int)i * 1000,
			.y = 0, .width = 1000, .height = 800};
		o->surface = (struct wl_surface *)&f->identities[i];
		/* set_output_dirty stops at an already pending frame callback. */
		o->frame_callback = (struct wl_callback *)&f->identities[i + 2];
		wl_list_insert(&f->state.outputs, &o->link);
	}
	f->boxes[0] = (struct slurp_box){.x = 0, .y = 0,
		.width = 1000, .height = 800, .label = "screen"};
	f->boxes[1] = (struct slurp_box){.x = 100, .y = 100,
		.width = 300, .height = 250, .label = "window"};
	f->boxes[2] = (struct slurp_box){.x = 180, .y = 140,
		.width = 80, .height = 40, .label = "small"};
	for (size_t i = 0; i < 3; ++i) {
		wl_list_insert(&f->state.boxes, &f->boxes[i].link);
	}
	f->seat.pointer_selection.current_output = &f->outputs[0];
	f->seat.pointer_selection.x = 190;
	f->seat.pointer_selection.y = 150;
}

static void hover(struct fixture *f) {
	pointer_handle_motion(&f->seat, NULL, 0,
		wl_fixed_from_int(190), wl_fixed_from_int(150));
	f->outputs[0].dirty = f->outputs[1].dirty = false;
}

static void down(struct fixture *f, int output, int id, int x, int y) {
	touch_handle_down(&f->seat, NULL, 0, 0, f->outputs[output].surface,
		id, wl_fixed_from_int(x), wl_fixed_from_int(y));
}

static void motion(struct fixture *f, int id, int x, int y) {
	touch_handle_motion(&f->seat, NULL, 0, id,
		wl_fixed_from_int(x), wl_fixed_from_int(y));
}

static void up(struct fixture *f, int id) {
	touch_handle_up(&f->seat, NULL, 0, 0, id);
}

static void button(struct fixture *f, uint32_t value, uint32_t state) {
	pointer_handle_button(&f->seat, NULL, 0, 0, value, state);
}

static bool result_is(struct fixture *f, int x, int y, int width, int height) {
	struct slurp_box *r = &f->state.result;
	return !f->state.running && r->x == x && r->y == y &&
		r->width == width && r->height == height;
}

static bool touch_after_hover(void) {
	struct fixture f;
	fixture_init(&f);
	hover(&f);
	down(&f, 1, 7, 100, 100);
	CHECK(f.seat.touch_id == 7);
	CHECK(!f.seat.pointer_selection.has_selection);
	CHECK(f.outputs[0].dirty);
	motion(&f, 7, 140, 180);
	CHECK(f.outputs[1].dirty);
	up(&f, 7);
	CHECK(result_is(&f, 1100, 100, 41, 81));
	return true;
}

static bool mouse_drag(void) {
	struct fixture f;
	fixture_init(&f);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
	pointer_handle_motion(&f.seat, NULL, 0,
		wl_fixed_from_int(230), wl_fixed_from_int(210));
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_RELEASED);
	CHECK(result_is(&f, 190, 150, 41, 61));
	return true;
}

static bool mouse_drag_rejects_touch(void) {
	struct fixture f;
	fixture_init(&f);
	hover(&f);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
	pointer_handle_motion(&f.seat, NULL, 0,
		wl_fixed_from_int(230), wl_fixed_from_int(210));
	down(&f, 1, 7, 100, 100);
	motion(&f, 7, 140, 180);
	up(&f, 7);
	CHECK(f.state.running);
	CHECK(f.seat.touch_id == TOUCH_ID_EMPTY);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_RELEASED);
	CHECK(result_is(&f, 190, 150, 41, 61));
	return true;
}

static bool mouse_press_before_motion(void) {
	struct fixture f;
	fixture_init(&f);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
	down(&f, 1, 7, 100, 100);
	CHECK(f.seat.touch_id == TOUCH_ID_EMPTY);
	up(&f, 7);
	CHECK(f.state.running);
	pointer_handle_motion(&f.seat, NULL, 0,
		wl_fixed_from_int(230), wl_fixed_from_int(210));
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_RELEASED);
	CHECK(result_is(&f, 190, 150, 41, 61));
	return true;
}

static bool second_finger_release(void) {
	struct fixture f;
	fixture_init(&f);
	down(&f, 0, 7, 600, 500);
	down(&f, 1, 8, 100, 100);
	motion(&f, 8, 200, 200);
	up(&f, 8);
	CHECK(f.state.running);
	CHECK(f.seat.touch_id == 7);
	motion(&f, 7, 650, 550);
	up(&f, 7);
	CHECK(result_is(&f, 600, 500, 51, 51));
	return true;
}

static bool untracked_release(void) {
	struct fixture f;
	fixture_init(&f);
	up(&f, 7);
	CHECK(f.state.running);
	CHECK(f.seat.touch_id == TOUCH_ID_EMPTY);
	return true;
}

static bool freeform_touch(void) {
	struct fixture f;
	fixture_init(&f);
	down(&f, 0, 7, 650, 550);
	motion(&f, 7, 600, 500);
	up(&f, 7);
	CHECK(result_is(&f, 600, 500, 51, 51));
	return true;
}

static bool touch_point_after_hover(void) {
	struct fixture f;
	fixture_init(&f);
	f.state.single_point = true;
	hover(&f);
	down(&f, 1, 7, 100, 100);
	CHECK(result_is(&f, 1100, 100, 1, 1));
	return true;
}

static bool cancel_before_motion(void) {
	struct fixture f;
	fixture_init(&f);
	down(&f, 0, 7, 600, 500);
	touch_handle_cancel(&f.seat, NULL);
	CHECK(f.state.running);
	CHECK(f.seat.touch_id == TOUCH_ID_EMPTY);
	down(&f, 1, 8, 100, 100);
	motion(&f, 8, 140, 180);
	up(&f, 8);
	CHECK(result_is(&f, 1100, 100, 41, 81));
	return true;
}

static bool right_button_cancel(void) {
	struct fixture f;
	fixture_init(&f);
	hover(&f);
	button(&f, BTN_RIGHT, WL_POINTER_BUTTON_STATE_PRESSED);
	CHECK(!f.state.running);
	CHECK(!f.seat.pointer_selection.has_selection);
	CHECK(f.state.result.width == 0 && f.state.result.height == 0);
	return true;
}

static bool selection_cancel(void) {
	struct fixture f;
	fixture_init(&f);
	down(&f, 0, 7, 600, 500);
	motion(&f, 7, 650, 550);
	handle_selection_cancelled(&f.seat);
	CHECK(!f.state.running);
	CHECK(!f.seat.touch_selection.has_selection);
	CHECK(f.state.result.width == 0 && f.state.result.height == 0);
	return true;
}

static bool mouse_window_click(void) {
	struct fixture f;
	fixture_init(&f);
	hover(&f);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_RELEASED);
	CHECK(result_is(&f, 180, 140, 80, 40));
	CHECK(strcmp(f.state.result.label, "small") == 0);
	return true;
}

static bool mouse_restricted_choice(void) {
	struct fixture f;
	fixture_init(&f);
	f.state.restrict_selection = true;
	hover(&f);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
	CHECK(result_is(&f, 180, 140, 80, 40));
	return true;
}

static bool mouse_single_point(void) {
	struct fixture f;
	fixture_init(&f);
	f.state.single_point = true;
	hover(&f);
	button(&f, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
	CHECK(result_is(&f, 190, 150, 1, 1));
	return true;
}

static bool restricted_touch_miss(void) {
	struct fixture f;
	fixture_init(&f);
	f.state.restrict_selection = true;
	down(&f, 1, 7, 100, 100);
	up(&f, 7);
	CHECK(f.state.running);
	CHECK(f.seat.touch_id == TOUCH_ID_EMPTY);
	return true;
}

static bool touch_choice(void) {
	struct fixture f;
	fixture_init(&f);
	down(&f, 0, 7, 190, 150);
	CHECK(f.outputs[0].dirty);
	up(&f, 7);
	CHECK(result_is(&f, 180, 140, 80, 40));
	CHECK(strcmp(f.state.result.label, "small") == 0);
	return true;
}

static bool restricted_touch_choice(void) {
	struct fixture f;
	fixture_init(&f);
	f.state.restrict_selection = true;
	hover(&f);
	down(&f, 0, 7, 190, 150);
	CHECK(result_is(&f, 180, 140, 80, 40));
	return true;
}

static bool drag_overrides_choice(void) {
	struct fixture f;
	fixture_init(&f);
	hover(&f);
	down(&f, 0, 7, 190, 150);
	motion(&f, 7, 260, 230);
	up(&f, 7);
	CHECK(result_is(&f, 190, 150, 71, 81));
	return true;
}

int main(int argc, char **argv) {
	bool baseline = argc == 2 && strcmp(argv[1], "--baseline") == 0;
	bool with_tap = argc == 2 && strcmp(argv[1], "--with-tap") == 0;
	if (argc > 2 || (argc == 2 && !baseline && !with_tap)) {
		fprintf(stderr, "Usage: %s [--baseline|--with-tap]\n", argv[0]);
		return 2;
	}
	struct test {
		const char *name;
		bool (*run)(void);
		bool fails_baseline;
		bool needs_tap;
	} tests[] = {
		{"touch after hover, with two outputs", touch_after_hover, true, false},
		{"ordinary mouse drag", mouse_drag, false, false},
		{"touch cannot finish a mouse drag", mouse_drag_rejects_touch, true, false},
		{"mouse press before first motion", mouse_press_before_motion, true, false},
		{"second finger release", second_finger_release, true, false},
		{"untracked touch release", untracked_release, true, false},
		{"reverse freeform touch drag", freeform_touch, false, false},
		{"single-point touch after hover", touch_point_after_hover, true, false},
		{"touch cancellation before motion", cancel_before_motion, false, false},
		{"right-button cancellation", right_button_cancel, false, false},
		{"selection cancellation", selection_cancel, false, false},
		{"mouse choice-box click and label", mouse_window_click, false, false},
		{"restricted mouse choice", mouse_restricted_choice, false, false},
		{"mouse single point", mouse_single_point, false, false},
		{"restricted touch outside choices", restricted_touch_miss, false, false},
		{"touch picks smallest choice and label", touch_choice, false, true},
		{"restricted touch selects on down", restricted_touch_choice, false, true},
		{"touch drag replaces tapped choice", drag_overrides_choice, false, true},
	};
	unsigned passed = 0, expected_failures = 0, unexpected = 0;
	for (size_t i = 0; i < sizeof(tests) / sizeof(tests[0]); ++i) {
		struct test *t = &tests[i];
		if (t->needs_tap && !with_tap) {
			continue;
		}
		bool ok = t->run();
		if (!ok && baseline && t->fails_baseline) {
			printf("XFAIL %s (known upstream defect)\n", t->name);
			++expected_failures;
		} else if (ok && baseline && t->fails_baseline) {
			printf("XPASS %s (baseline changed; investigate)\n", t->name);
			++unexpected;
		} else if (ok) {
			printf("PASS  %s\n", t->name);
			++passed;
		} else {
			printf("FAIL  %s\n", t->name);
			++unexpected;
		}
	}
	printf("%u passed, %u expected baseline failures, %u unexpected\n",
		passed, expected_failures, unexpected);
	return unexpected ? 1 : 0;
}
