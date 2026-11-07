extends RefCounted
## World scale: 1 Godot unit = 1 metre. Divide km/h by 3.6 for m/s.
## Relative multiplier applies only to cruising traffic, not parking or walking.
const BASE_TRAFFIC_SPEED_KMH := 10.8
const TRAFFIC_SPEED_FACTOR := 2.0
const TRAFFIC_SPEED_KMH := BASE_TRAFFIC_SPEED_KMH * TRAFFIC_SPEED_FACTOR
const PARKING_SPEED_KMH := 9.0
const WALK_SPEED_KMH := 12.6
const SPRINT_SPEED_KMH := 21.6
