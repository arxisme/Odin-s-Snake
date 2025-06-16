package snake

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

WINDOW_SIZE :: 800
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
Vec2i :: [2]int
MAX_SNAKE_LEGTH :: GRID_WIDTH * GRID_WIDTH


snake:[MAX_SNAKE_LEGTH]Vec2i
snake_length: int
TICK_RATE :: 0.13
tick_timer : f32 = TICK_RATE

move_direction: Vec2i
game_over:bool
food_pos: Vec2i

place_food::proc(){
    Occupied: [GRID_WIDTH][GRID_WIDTH]bool;
    for i in 0..<snake_length{
        Occupied[snake[i].x][snake[i].y] = true

    }
    free_cells := make([dynamic]Vec2i, context.temp_allocator)
    for x in 0..< GRID_WIDTH{
        for y in 0..< GRID_WIDTH{
            if!Occupied[x][y]{
                append(&free_cells, Vec2i{x,y})
            }
        }
    }
    if len(free_cells)>0{
        random_cell_index :=  rl.GetRandomValue(0, i32(len(free_cells)-1))
        food_pos = free_cells[random_cell_index]
    }

}

restart :: proc() {
    start_head_pos :=Vec2i { GRID_WIDTH / 2, GRID_WIDTH / 2 }
    snake[0] = start_head_pos
    snake[1] = start_head_pos - { 0, 1 }
    snake[2] = start_head_pos - { 0, 2 }
    snake_length = 2
    move_direction = { 0, 1 }
    game_over = false
    place_food()

}


main :: proc() {
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Odin Snake")
    rl.InitAudioDevice()
    eat_sound := rl.LoadSound("bin/eat.wav")
    crash_sound := rl.LoadSound("bin/crash.wav")


    start_head_pos :=Vec2i { GRID_WIDTH / 2, GRID_WIDTH / 2 }
    restart()

    food_sprite := rl.LoadTexture("bin/food.png")
    head_sprite := rl.LoadTexture("bin/head.png")
    body_sprite := rl.LoadTexture("bin/body.png")
    tail_sprite := rl.LoadTexture("bin/tail.png")

    for !rl.WindowShouldClose(){
        if rl.IsKeyDown(.UP){
            move_direction = { 0, -1 }

        }
        if rl.IsKeyDown(.DOWN){
            move_direction = { 0, 1 }
        }
        if rl.IsKeyDown(.LEFT){
            move_direction = { -1, 0 }
        }
        if rl.IsKeyDown(.RIGHT){
            move_direction = { 1, 0 }
        }
        if game_over{
            if rl.IsKeyPressed(.ENTER){
                restart()
            }

        }
        else {

            tick_timer -= rl.GetFrameTime()
        }

        if tick_timer <= 0{
            next_part_pos := snake[0]
            snake[0] += move_direction

            head_pos := snake[0]
            if head_pos.x < 0 || head_pos.x >= GRID_WIDTH || head_pos.y < 0 || head_pos.y > GRID_WIDTH{
                game_over = true
                rl.PlaySound(crash_sound)

            }


            for i in 1 ..< snake_length{
                curr_pos := snake[i]
                if(curr_pos == head_pos){
                    game_over = true
                    rl.PlaySound(crash_sound)
                }
                snake[i] = next_part_pos
                next_part_pos = curr_pos
            }

            if head_pos == food_pos{
                snake_length+=1
                rl.PlaySound(eat_sound)
                snake[snake_length-1] = next_part_pos
                place_food()
            }
            tick_timer = TICK_RATE + tick_timer
        }

        rl.BeginDrawing()
        rl.ClearBackground({ 15, 56, 15, 255 })

        camera := rl.Camera2D{
            zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
        }
        rl.BeginMode2D(camera)
        rl.DrawTextureV(food_sprite,{f32(food_pos.x), f32(food_pos.y)}*CELL_SIZE ,rl.GREEN)
        for i in  0 ..< snake_length{
            part_sprite := body_sprite
            dir : Vec2i
            if i == 0{

                part_sprite = head_sprite
                dir = snake[i] -snake[i+1]
            }
            if i == snake_length -1{
                part_sprite = tail_sprite
                dir = snake[i-1]-snake[i]
            }
            else{
                dir = snake[i]-snake[i+1]
            }
            rot := math.atan2(f32(dir.y),f32(dir.x)) *math.DEG_PER_RAD
            source:= rl.Rectangle{
                0,0,
                f32(part_sprite.width),f32(part_sprite.height)
            }
            dest:= rl.Rectangle{
                f32(snake[i].x*CELL_SIZE +0.5*CELL_SIZE), f32(snake[i].y*CELL_SIZE +0.5*CELL_SIZE),
                CELL_SIZE, CELL_SIZE,
            }
            rl.DrawTexturePro(part_sprite,source, dest, {CELL_SIZE , CELL_SIZE}*0.5,rot,rl.GREEN)


        }


        if game_over{
            rl.DrawText("Game Over!", 4, 8, 10, rl.RED)
            rl.DrawText("Press Enter to restart!", 4, 20, 7, rl.BLACK)
        }
        score:= snake_length -2
        scoreStr := fmt.ctprintf("SCORE : %v", score)
        rl.DrawText(scoreStr,4, CANVAS_SIZE -14 ,10, rl.GREEN)




        rl.EndMode2D()
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
    rl.UnloadTexture(head_sprite)
    rl.UnloadTexture(food_sprite)
    rl.UnloadTexture(body_sprite)
    rl.UnloadTexture(tail_sprite)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}