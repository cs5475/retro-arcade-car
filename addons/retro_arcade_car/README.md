# Retro Arcade Car for Godot 4

A low-poly arcade car in one script: gas, brake and reverse, steering that only bites once the car is rolling, a bounce when you hit a wall, and anything in front of the bumper at speed gets knocked flying. No models or textures: the car is built from boxes, or you can turn that off and use your own model.

Tested in Godot 4.6 with the Compatibility renderer.

## Try it

Open `addons/retro_arcade_car/demo/demo.tscn` and press F6 (or open this project and press F5). Drive with the arrows or WASD, and knock the crates around the lot.

## Use it

1. Copy `addons/retro_arcade_car/` into your project.
2. Add an `ArcadeCar` node to a scene that has a floor. The nose points along +X.
3. Anything you want the car to knock over: put it in the `knockable` group and on a collision layer the car doesn't hit (the car uses layer 1 and mask 1). A `RigidBody3D` gets an impulse; any other node with `on_car_hit(dir, speed)` gets that call instead.

Handy bits:
- `driven = false` parks it. Set `gas` and `turn` (-1 to 1) yourself for an AI driver.
- Signals: `crashed(speed)` for wall hits, `knocked(body, speed)` for anything it hits.
- Exported tuning: `max_speed`, `accel`, `brake`, `drag`, `turn_rate`, and the four input actions.
- `build_box_body = false` and add your own mesh and collision shape.

## License

MIT, see `LICENSE.txt`.

Want cops that chase and ram this car? That's the full [Retro Crime Sandbox Kit](https://cs5475.itch.io/retro-crime-sandbox-kit): a low-poly city to drive, wanted stars, cops on foot and in cars, a pistol and street fights on foot.
