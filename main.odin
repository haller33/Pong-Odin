package pong_odin

import fmt "core:fmt"
import la "core:math/linalg"
import n "core:math/linalg/hlsl"
import rl "vendor:raylib"
import rand "core:math/rand"
import "core:strings"

Paddle :: struct {

    p : n.float2,
	score : int,
	size : n.int2,
}

Ball :: struct {
    p : n.float2,
    v : n.float2,
}
// TODO: verify heap allocation on debuger
player1 : Paddle
player2 : Paddle 

ball : Ball

main :: proc ( ) {

    windown_dim :: n.int2{800, 600}
    
    // fmt.println ("Hello World")

    rl.InitWindow(windown_dim.x, windown_dim.y, "Pong Odin")
    rl.SetTargetFPS(60)

	player1.p = n.float2{100.0, f32(windown_dim.x/2)}
	player2.p = n.float2{f32(windown_dim.x - 100.0), f32(windown_dim.x / 2)}

	player1.size = n.int2{10, 70}
	player2.size = n.int2{10, 70}

    ball.v = n.float2 { 0, 0 }

    ball.p = {f32(windown_dim.x/2), f32(windown_dim.y/2)}
    ball.v = n.float2{
        rand.float32_normal(0, 1),
        rand.float32_normal(0, 1),
    }

    is_running := true

    keyfor : rl.KeyboardKey
    keyfor = rl.GetKeyPressed()

    
    fmt.println(keyfor)

	rl.BeginDrawing()
	
	current_speed : f32 = 6.0
	old_current_speed : f32 = current_speed

	pause : bool = false
		
    for is_running && rl.WindowShouldClose() == false {

		// rl.DrawText("Hello World!", 100, 100, 20, rl.DARKGRAY)
		scores : cstring = strings.clone_to_cstring(fmt.tprintf("Score p1 %v, p2 %v", player1.score, player2.score), context.temp_allocator)
		
		// rl.DrawText(string(windown_dim.x), 0, 0, 20, rl.DARKGRAY)
		// rl.DrawText(string(windown_dim.y), 0, 10, 20, rl.DARKGRAY)


		/// handle game play velocity
        keyfor = rl.GetKeyPressed()
		if keyfor == rl.KeyboardKey.RIGHT {
			current_speed *= 1.25
		} else if keyfor == rl.KeyboardKey.LEFT {
			current_speed = old_current_speed
		} else if (keyfor == rl.KeyboardKey.P) {
			pause = !pause
			if pause {
				continue
			}
		} else if (keyfor == rl.KeyboardKey.R) {

			ball.p = {f32(windown_dim.x/2), f32(windown_dim.y/2)}
            ball.v = n.float2{
                rand.float32_normal(0, 1),
                rand.float32_normal(0, 1),
            }
            
            fmt.println(keyfor)

        }

		if pause {
			
			rl.DrawText("Odin Pause!", (windown_dim.x/2)-10, (windown_dim.y/2)-10, 20, rl.DARKGRAY)
			
		} else {

			handle_game_mechanics ( &ball, current_speed, &player1, &player2, windown_dim )
			// ball.v = ball.v * (1-0.01)
		}
		
		rl.ClearBackground(rl.WHITE)
		
		rl.DrawText("Pong Odin!", 100, 100, 20, rl.DARKGRAY)

		rl.DrawRectangle(i32(player1.p.x), i32(player1.p.y), player1.size.x, player1.size.y, rl.BLACK)
		rl.DrawRectangle(i32(player2.p.x), i32(player2.p.y), player2.size.x, player2.size.y, rl.BLACK)
		rl.DrawRectangle(i32(ball.p.x), i32(ball.p.y), 10, 10, rl.BLACK)
		rl.DrawText(scores, 1, 1, 20, rl.GRAY)
    
		rl.EndDrawing()
	}
    
}

handle_game_mechanics :: proc (ball : ^Ball, current_speed : f32,
							   player1 : ^Paddle, player2 : ^Paddle, windown_dim : n.int2 ) {

	// Movimentation of ball accordily with velocity
	ball.p += (ball.v * current_speed)

	// Colision with Wall
	if ball.p.x < 0 {

		ball.p.x = 10
		ball.v.x = ball.v.x * (-1.0)
		player2.score += 1
	} else if ball.p.x > f32(windown_dim.x) {

		ball.p.x = f32(windown_dim.x)
		ball.v.x = ball.v.x * (-1.0)
		player1.score += 1
	} else if ball.p.y < 0 {

		ball.p.y = 10
		ball.v.y = ball.v.y * (-1.0)
	} else if ball.p.y > f32(windown_dim.y) {

		ball.p.y = f32(windown_dim.y)
		ball.v.y = ball.v.y * (-1.0)
	}

	// handle Paddles control moviment
	if rl.IsKeyDown(rl.KeyboardKey.W) {
		player1.p.y -= 10.0
	} else if rl.IsKeyDown(rl.KeyboardKey.S) {
		player1.p.y += 10.0
	}
	if rl.IsKeyDown(rl.KeyboardKey.UP) {
		player2.p.y -= 10.0
	} else if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
		player2.p.y += 10.0
	}

	/// handle paddles colision on walls
	handle_paddles_wall ( &player1, windown_dim )
	handle_paddles_wall ( &player2, windown_dim )
	
	/// colision detection
	paddle_colision_detection ( ball, player1 )
	paddle_colision_detection ( ball, player2 )
	
}


paddle_colision_detection :: proc(ball : ^Ball, player : Paddle) {

	/// handle colision
	if ball.p.x < (player.p.x + f32(player.size.x)) &&
		ball.p.x > (player.p.x - f32(player.size.x)) &&
		ball.p.y < (player.p.y + f32(player.size.y/2)) &&
		ball.p.y > (player.p.y - f32(player.size.y)) {
			ball.v.x = -ball.v.x
			// fmt.println("colision on player")
		}
}

handle_paddles_wall :: proc (player : ^Paddle, windown_dim : n.int2) {

	
	/// handle walls for Paddles
	if player.p.y > (f32(windown_dim.y) - f32(player.size.y)) {
		player.p.y = f32(windown_dim.y) - f32(player.size.y)
	} else if player.p.y < 0.0 {
		player.p.y = 0.0
	}
}
