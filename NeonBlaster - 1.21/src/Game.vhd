LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.NeonBlaster_pkg.ALL;

ENTITY Game IS
    PORT (
        CLK_50MHz : IN STD_LOGIC;
        RESET : IN STD_LOGIC;
        LeftInput : IN STD_LOGIC;
        RightInput : IN STD_LOGIC;
        StartInput : IN STD_LOGIC;
        DownInput : IN STD_LOGIC;
        ForcePause : IN STD_LOGIC;
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        ColorOut : OUT STD_LOGIC_VECTOR(11 DOWNTO 0); -- RED & GREEN & BLUE
        ScanlineX : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        ScanlineY : IN STD_LOGIC_VECTOR(10 DOWNTO 0)
    );
END Game;

ARCHITECTURE Behavioral OF Game IS
    -- Spaceship, background
    SIGNAL PlayerMoveClk : STD_LOGIC := '0';
    SIGNAL EnemyMoveClk : STD_LOGIC := '0';
    SIGNAL EnemyMoveLimit : INTEGER := 2500000; -- 50ms
    SIGNAL TimerClk : STD_LOGIC := '0'; -- one second

    CONSTANT ENEMY_WIDTH : INTEGER := 20; -- don't change!
    CONSTANT MAX_ENEMIES_NUMBER : INTEGER := 4; 
    CONSTANT PLAYERS_WIDTH : INTEGER := 35; -- don't change!
    CONSTANT PLAYERS_LENGTH : INTEGER := 50; -- don't change!
    CONSTANT BOMBS_NUMBER : INTEGER := 10;
    CONSTANT BOMB_WIDTH : INTEGER := 8; -- don't change!

    CONSTANT MAX_X : INTEGER := 600; -- maximum 640
    CONSTANT MIN_X : INTEGER := 40; 
    CONSTANT MAX_Y : INTEGER := 480; -- maximum 480
    CONSTANT MIN_Y : INTEGER := 0;

    CONSTANT DEFAULT_ENEMY : EnemyType := (
        x_position => 0,
        y_position => 0,
        x_speed => 1,
        y_speed => 0,
        x_direction => '0',
        y_direction => '0',
        gravity => 0,
        color => "001",
        is_alive => '0',
        spawning => '0',
        health => 5,
        initial_health => 5
    );
    CONSTANT DEFAULT_PLAYER : PlayerType := (
        x_position => MIN_X,
        y_position => MAX_Y - PLAYERS_WIDTH - 10,
        score => 0,
        is_alive => '1'
    );
    CONSTANT DEFAULT_GAME : GameType := (
        state => HOLD,
        timer => 0,
        enemies_killed => 0,
        enemies_number => 0
    );
    CONSTANT DEFAULT_BOMB_0 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_1 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_2 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 2 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_3 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 3 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_4 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 4 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_5 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 5 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_6 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 6 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_7 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 7 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_8 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 8 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    CONSTANT DEFAULT_BOMB_9 : BombType := (
        x_position => MIN_X + (PLAYERS_LENGTH - BOMB_WIDTH)/2,
        y_position => MAX_Y - PLAYERS_WIDTH - 9 * (MAX_Y - PLAYERS_WIDTH)/BOMBS_NUMBER,
        hit => '0'
    );
    SIGNAL enemies : EnemyArrayType(0 TO MAX_ENEMIES_NUMBER - 1) := (OTHERS => DEFAULT_ENEMY);
    SIGNAL player : PlayerType := DEFAULT_PLAYER;
    SIGNAL game : GameType := DEFAULT_GAME;
    SIGNAL bombs : BombArrayType(0 TO BOMBS_NUMBER - 1) := (DEFAULT_BOMB_0, DEFAULT_BOMB_1, DEFAULT_BOMB_2, DEFAULT_BOMB_3, DEFAULT_BOMB_4, DEFAULT_BOMB_5, DEFAULT_BOMB_6, DEFAULT_BOMB_7, DEFAULT_BOMB_8, DEFAULT_BOMB_9);

    SIGNAL ColorOutput : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL pseudo_rand_50 : STD_LOGIC_VECTOR(49 DOWNTO 0) := (OTHERS => '0');
BEGIN
    Main : PROCESS (CLK_50MHz, RESET) 
    BEGIN
        IF RESET = '1' THEN
            enemies <= (OTHERS => DEFAULT_ENEMY);
            player <= DEFAULT_PLAYER;
            bombs <= (DEFAULT_BOMB_0, DEFAULT_BOMB_1, DEFAULT_BOMB_2, DEFAULT_BOMB_3, DEFAULT_BOMB_4, DEFAULT_BOMB_5, DEFAULT_BOMB_6, DEFAULT_BOMB_7, DEFAULT_BOMB_8, DEFAULT_BOMB_9);
            game <= DEFAULT_GAME;
            pseudo_rand_50 <= (OTHERS => '0');
            EnemyMoveLimit <= 2500000;
        ELSIF rising_edge(CLK_50MHz) THEN
            pseudo_rand_50 <= lfsr50(pseudo_rand_50);
            IF (RightInput = '1' OR LeftInput = '1') AND game.state = HOLD THEN -- start game condition!
                game.state <= STARTED;
            END IF;
            IF game.state = started THEN
                IF PlayerMoveClk = '1' THEN -- bomb & player
                    IF RightInput = '1' AND player.x_position + PLAYERS_LENGTH < MAX_X THEN
                        player.x_position <= player.x_position + 1;
                    ELSIF LeftInput = '1' AND player.x_position - 1 > MIN_X THEN
                        player.x_position <= player.x_position - 1;
                    END IF;
                    FOR i IN 0 TO BOMBS_NUMBER - 1 LOOP -- bomb handler:
                        IF (bombs(i).y_position - 1 < MIN_Y) THEN -- bomb movement
                            bombs(i).hit <= '0';
                            bombs(i).y_position <= MAX_Y - PLAYERS_WIDTH;
                            bombs(i).x_position <= player.x_position + (PLAYERS_LENGTH - BOMB_WIDTH)/2;
                        ELSE
                            bombs(i).y_position <= bombs(i).y_position - 1;
                        END IF;
                        FOR ii IN 0 TO MAX_ENEMIES_NUMBER - 1 LOOP -- bomb hit?
                            IF (bombs(i).hit = '0') AND (enemies(ii).is_alive = '1') AND (bombs(i).x_position < enemies(ii).x_position + ENEMY_WIDTH AND
                                bombs(i).x_position + BOMB_WIDTH > enemies(ii).x_position AND
                                bombs(i).y_position < enemies(ii).y_position + ENEMY_WIDTH AND
                                bombs(i).y_position + BOMB_WIDTH > enemies(ii).y_position) THEN -- bomb is hit
                                IF (enemies(ii).health - 1 <= 0) THEN
                                    enemies(ii).is_alive <= '0';
                                    game.enemies_killed <= game.enemies_killed + 1;
                                    player.score <= player.score + enemies(ii).initial_health;
                                    enemies(ii).health <= 0;
                                ELSE
                                    enemies(ii).health <= enemies(ii).health - 1;
                                END IF;
                                bombs(i).hit <= '1';
                            END IF;
                        END LOOP;
                    END LOOP;
                END IF;

                IF EnemyMoveClk = '1' THEN -- enemy
                    IF (game.enemies_killed = game.enemies_number) THEN -- respawn enemies!
                        FOR i IN 0 TO MAX_ENEMIES_NUMBER - 1 LOOP
                            IF enemies(i).is_alive = '0' AND i <= game.enemies_number THEN
                                IF (game.enemies_number = MAX_ENEMIES_NUMBER) THEN
                                    game.enemies_number <= MAX_ENEMIES_NUMBER; -- 
                                ELSE
                                    game.enemies_number <= game.enemies_number + 1;
                                    EnemyMoveLimit <= EnemyMoveLimit - 250000; -- 5ms!
                                END IF;
                                enemies(i).x_position <= to_integer(unsigned(pseudo_rand_50(i + 8 * (i + 1) DOWNTO i + 8 * i)));
                                enemies(i).y_position <= MIN_Y;
                                enemies(i).x_speed <= 3 + to_integer(unsigned(pseudo_rand_50(i + 2 * (i + 1) DOWNTO i + 2 * i)));
                                enemies(i).y_speed <= 0;
                                enemies(i).gravity <= 1;
                                enemies(i).is_alive <= '1';
                                enemies(i).health <= 1 + to_integer(unsigned(pseudo_rand_50(i + 2 * (i + 1) DOWNTO i + 2 * i)));
                                enemies(i).initial_health <= 1 + to_integer(unsigned(pseudo_rand_50(i + 2 * (i + 1) DOWNTO i + 2 * i)));
                            END IF;
                        END LOOP;
                        game.enemies_killed <= 0;
                    END IF;

                    FOR i IN 0 TO MAX_ENEMIES_NUMBER - 1 LOOP -- enemies movement!
                        IF enemies(i).is_alive = '1' AND (player.x_position < enemies(i).x_position + ENEMY_WIDTH AND
                            player.x_position + PLAYERS_LENGTH > enemies(i).x_position AND
                            player.y_position < enemies(i).y_position + ENEMY_WIDTH AND
                            player.y_position + PLAYERS_WIDTH > enemies(i).y_position) THEN -- player dead?
                            player.is_alive <= '0';
                            game.state <= ENDED;
                        END IF;
                        IF enemies(i).is_alive = '1' THEN
                            IF enemies(i).x_direction = '0' THEN
                                IF enemies(i).x_position < MAX_X - ENEMY_WIDTH THEN
                                    enemies(i).x_position <= enemies(i).x_position + enemies(i).x_speed;
                                ELSE
                                    enemies(i).x_direction <= '1';
                                END IF;
                            ELSE
                                IF enemies(i).x_position > MIN_X THEN
                                    enemies(i).x_position <= enemies(i).x_position - enemies(i).x_speed;
                                ELSE
                                    enemies(i).x_direction <= '0';
                                END IF;
                            END IF;
                            IF enemies(i).y_direction = '0' THEN
                                IF enemies(i).y_position < MAX_Y - ENEMY_WIDTH THEN
                                    enemies(i).y_position <= enemies(i).y_position + enemies(i).y_speed;
                                    enemies(i).y_speed <= enemies(i).y_speed + enemies(i).gravity;
                                ELSE
                                    enemies(i).y_speed <= 25;
                                    enemies(i).y_direction <= '1';
                                END IF;
                            ELSE
                                IF enemies(i).y_position > MIN_Y AND enemies(i).y_speed > 0 THEN
                                    enemies(i).y_position <= enemies(i).y_position - enemies(i).y_speed;
                                    enemies(i).y_speed <= enemies(i).y_speed - enemies(i).gravity;
                                ELSE
                                    enemies(i).y_direction <= '0';
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
                IF TimerClk = '1' THEN
                    IF (game.state = started) THEN
                        game.timer <= game.timer + 1;
                        IF (game.timer = 60) THEN
                            game.timer <= 0;
                            game.state <= ENDED;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    SegmentOutput : PROCESS (game.state, player.score, game.timer)
    BEGIN
        IF (game.state = HOLD) THEN
            HEX0 <= convSeg("1001"); -- 9
            HEX1 <= convSeg("0000"); -- 0
            HEX2 <= convSeg("0100"); -- 4
            HEX3 <= convSeg("0011"); -- 3
            HEX4 <= convSeg("0000");
            HEX5 <= convSeg("0000");
            LEDR <= "1000000000";
        ELSIF (game.state = started) THEN
            LEDR <= "1100000000";
            HEX0 <= convSeg(STD_LOGIC_VECTOR(to_unsigned(player.score MOD 10, 4)));
            HEX1 <= convSeg(STD_LOGIC_VECTOR(to_unsigned((player.score /10) MOD 10, 4)));
            HEX2 <= convSeg(STD_LOGIC_VECTOR(to_unsigned((player.score /100) MOD 10, 4)));
            HEX3 <= convSeg(STD_LOGIC_VECTOR(to_unsigned(player.score /1000, 4)));
            HEX4 <= convSeg(STD_LOGIC_VECTOR(to_unsigned(game.timer MOD 10, 4)));
            HEX5 <= convSeg(STD_LOGIC_VECTOR(to_unsigned((game.timer/10) MOD 10, 4)));
        ELSE
				LEDR <= "1110000000";
            HEX0 <= convSeg(STD_LOGIC_VECTOR(to_unsigned(player.score MOD 10, 4)));
            HEX1 <= convSeg(STD_LOGIC_VECTOR(to_unsigned((player.score /10) MOD 10, 4)));
            HEX2 <= convSeg(STD_LOGIC_VECTOR(to_unsigned((player.score /100) MOD 10, 4)));
            HEX3 <= convSeg(STD_LOGIC_VECTOR(to_unsigned(player.score /1000, 4)));
            HEX4 <= convSeg(STD_LOGIC_VECTOR(to_unsigned(game.timer MOD 10, 4)));
            HEX5 <= convSeg(STD_LOGIC_VECTOR(to_unsigned((game.timer/10) MOD 10, 4)));

        END IF;
    END PROCESS;
    vga_output : PROCESS (ScanlineX, ScanlineY, player, enemies, bombs, game)
    BEGIN
        ColorOutput <= "000000000000"; -- black
        IF ((unsigned(ScanlineX) >= MIN_X AND unsigned(ScanlineY) > MIN_Y AND unsigned(ScanlineX) < MAX_X AND unsigned(ScanlineY) < MAX_Y)) THEN
            ColorOutput <= "000011001111"; -- sky blue
        END IF;
		  
        IF (player.is_alive = '1' AND 0 <= (unsigned(ScanlineX) - player.x_position) AND (unsigned(ScanlineX) - player.x_position) < PLAYERS_LENGTH AND 0 <= (unsigned(ScanlineY) - player.y_position) AND (unsigned(ScanlineY) - player.y_position) < PLAYERS_WIDTH) THEN
            IF MAP_PLAYER(to_integer(unsigned(ScanlineY) - player.y_position))(to_integer(unsigned(ScanlineX) - player.x_position)) = '1' THEN
                ColorOutput <= "000000000000";
            END IF;
        END IF;
        FOR i IN 0 TO BOMBS_NUMBER - 1 LOOP
            IF bombs(i).hit = '0' AND game.state = started AND (0 <= (unsigned(ScanlineX) - bombs(i).x_position) AND (unsigned(ScanlineX) - bombs(i).x_position) < BOMB_WIDTH AND 0 <= (unsigned(ScanlineY) - bombs(i).y_position) AND (unsigned(ScanlineY) - bombs(i).y_position) < BOMB_WIDTH) THEN
                IF MAP_SHOT(to_integer(unsigned(ScanlineY) - bombs(i).y_position))(to_integer(unsigned(ScanlineX) - bombs(i).x_position)) = '1' THEN
                    ColorOutput <= "111111100000"; -- yellow
                END IF;
            END IF;
        END LOOP;

        FOR i IN 0 TO MAX_ENEMIES_NUMBER - 1 LOOP
            IF enemies(i).is_alive = '1' AND game.state = started AND unsigned(ScanlineX) >= enemies(i).x_position AND unsigned(ScanlineY) >= enemies(i).y_position AND unsigned(ScanlineX) < enemies(i).x_position + ENEMY_WIDTH AND unsigned(ScanlineY) < enemies(i).y_position + ENEMY_WIDTH THEN
                ColorOutput <= "111100000000";
                IF ((ENEMY_WIDTH - 7)/2 <= (unsigned(ScanlineX) - enemies(i).x_position) AND (unsigned(ScanlineX) - enemies(i).x_position) <= (ENEMY_WIDTH + 7)/2 AND (ENEMY_WIDTH - 15)/2 <= (unsigned(ScanlineY) - enemies(i).y_position) AND (unsigned(ScanlineY) - enemies(i).y_position) <= (ENEMY_WIDTH + 15)/2) THEN
                    IF HEALTH_MAP(enemies(i).health)(to_integer(unsigned(ScanlineY) - enemies(i).y_position - (ENEMY_WIDTH - 15)/2))(to_integer(unsigned(ScanlineX) - enemies(i).x_position - (ENEMY_WIDTH - 7)/2)) = '1' THEN
                        ColorOutput <= "000000000000"; -- white
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END PROCESS;
    Seconds : PROCESS (CLK_50MHz, RESET)
        VARIABLE PlayerMoveCounter : INTEGER := 0;
        VARIABLE EnemyMoveCounter : INTEGER := 0;
        VARIABLE TimerCounter : INTEGER := 0;
    BEGIN
        IF RESET = '1' THEN
            PlayerMoveCounter := 0;
            EnemyMoveCounter := 0; -- enemy
            TimerCounter := 0;
        ELSIF rising_edge(CLK_50MHz) THEN
            -- two millisecs => 100000 clk
            -- five millisecs => 250000 clk
            PlayerMoveCounter := PlayerMoveCounter + 1; -- player
            EnemyMoveCounter := EnemyMoveCounter + 1;
            TimerCounter := TimerCounter + 1;
            IF PlayerMoveCounter = 100000 THEN -- 10 ^ 5
                PlayerMoveClk <= '1';
                PlayerMoveCounter := 0;
            ELSE
                PlayerMoveClk <= '0';
            END IF;
            IF EnemyMoveCounter = EnemyMoveLimit THEN -- variant from 50 mili to 20 mili
                EnemyMoveClk <= '1';
                EnemyMoveCounter := 0;
            ELSE
                EnemyMoveClk <= '0';
            END IF;
            IF TimerCounter = 50000000 THEN -- one sec
                TimerClk <= '1';
                TimerCounter := 0;
            ELSE
                TimerClk <= '0';
            END IF;
        END IF;
    END PROCESS;

    ColorOut <= ColorOutput;

END Behavioral;