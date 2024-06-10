-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.NeonBlaster_pkg.all;
entity CAD_VGA_Quartus is
	port
	(
		--//////////// CLOCK //////////
		CLOCK_50 : in STD_LOGIC;
		CLOCK2_50 : in STD_LOGIC;
		CLOCK3_50 : in STD_LOGIC;
		CLOCK4_50 : inout STD_LOGIC;

		--//////////// KEY //////////
		RESET_N : in STD_LOGIC;
		Key : in STD_LOGIC_VECTOR(3 downto 0);

		--//////////// SEG7 //////////
		HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
		HEX1 : out STD_LOGIC_VECTOR(6 downto 0);
		HEX2 : out STD_LOGIC_VECTOR(6 downto 0);
		HEX3 : out STD_LOGIC_VECTOR(6 downto 0);
		HEX4 : out STD_LOGIC_VECTOR(6 downto 0);
		HEX5 : out STD_LOGIC_VECTOR(6 downto 0);

		--//////////// LED //////////
		LEDR : out STD_LOGIC_VECTOR(9 downto 0);

		--//////////// SWITCH //////////
		SW : in STD_LOGIC_VECTOR(9 downto 0);

		--//////////// SDRAM //////////
		DRAM_ADDR : out STD_LOGIC_VECTOR (12 downto 0);
		DRAM_BA : out STD_LOGIC_VECTOR (1 downto 0);
		DRAM_CAS_N : out STD_LOGIC;
		DRAM_CKE : out STD_LOGIC;
		DRAM_CLK : out STD_LOGIC;
		DRAM_CS_N : out STD_LOGIC;
		DRAM_DQ : inout STD_LOGIC_VECTOR(15 downto 0);
		DRAM_LDQM : out STD_LOGIC;
		DRAM_RAS_N : out STD_LOGIC;
		DRAM_UDQM : out STD_LOGIC;
		DRAM_WE_N : out STD_LOGIC;

		--//////////// microSD Card //////////
		SD_CLK : out STD_LOGIC;
		SD_CMD : inout STD_LOGIC;
		SD_DATA : inout STD_LOGIC_VECTOR(3 downto 0);

		--//////////// PS2 //////////
		PS2_CLK : inout STD_LOGIC;
		PS2_CLK2 : inout STD_LOGIC;
		PS2_DAT : inout STD_LOGIC;
		PS2_DAT2 : inout STD_LOGIC;

		--//////////// VGA //////////
		VGA_B : out STD_LOGIC_VECTOR(3 downto 0);
		VGA_G : out STD_LOGIC_VECTOR(3 downto 0);
		VGA_HS : out STD_LOGIC;
		VGA_R : out STD_LOGIC_VECTOR(3 downto 0);
		VGA_VS : out STD_LOGIC
	);
end CAD_VGA_Quartus;

--}} End of automatically maintained section

architecture CAD_VGA_Quartus of CAD_VGA_Quartus is

	component VGA_controller
		port
		(
			CLK_50MHz : in STD_LOGIC;
			VS : out STD_LOGIC;
			HS : out STD_LOGIC;
			RED : out STD_LOGIC_VECTOR(3 downto 0);
			GREEN : out STD_LOGIC_VECTOR(3 downto 0);
			BLUE : out STD_LOGIC_VECTOR(3 downto 0);
			RESET : in STD_LOGIC;
			ColorIN : in STD_LOGIC_VECTOR(11 downto 0);
			ScanlineX : out STD_LOGIC_VECTOR(10 downto 0);
			ScanlineY : out STD_LOGIC_VECTOR(10 downto 0)
		);
	end component;

	component Game
		port
		(
			CLK_50MHz : in STD_LOGIC;
			RESET : in STD_LOGIC;
			LeftInput : in STD_LOGIC;
			RightInput : in STD_LOGIC;
			StartInput : in STD_LOGIC;
			DownInput : in STD_LOGIC;
			ForcePause : in STD_LOGIC;
			ColorOut : out STD_LOGIC_VECTOR(11 downto 0); -- RED & GREEN & BLUE
			HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
			HEX1 : out STD_LOGIC_VECTOR(6 downto 0);
			HEX2 : out STD_LOGIC_VECTOR(6 downto 0);
			HEX3 : out STD_LOGIC_VECTOR(6 downto 0);
			HEX4 : out STD_LOGIC_VECTOR(6 downto 0);
			HEX5 : out STD_LOGIC_VECTOR(6 downto 0);
			LEDR : out STD_LOGIC_VECTOR(9 downto 0);
			ScanlineX : in STD_LOGIC_VECTOR(10 downto 0);
			ScanlineY : in STD_LOGIC_VECTOR(10 downto 0)
		);
	end component;

	signal ScanlineX, ScanlineY : STD_LOGIC_VECTOR(10 downto 0);
	signal ColorTable : STD_LOGIC_VECTOR(11 downto 0);

	signal RESET : STD_LOGIC := not RESET_N;
begin

	--------- VGA Controller -----------
	VGA_Control : vga_controller
	port map
	(
		CLK_50MHz => CLOCK3_50,
		VS => VGA_VS,
		HS => VGA_HS,
		RED => VGA_R,
		GREEN => VGA_G,
		BLUE => VGA_B,
		RESET => not RESET_N,
		ColorIN => ColorTable,
		ScanlineX => ScanlineX,
		ScanlineY => ScanlineY
	);

	--------- Moving Square -----------
	VGA_SQ : Game
	port
	map(
	CLK_50MHz => CLOCK3_50,
	RESET => not RESET_N,
	LeftInput => not Key(3),
	RightInput => not Key(0),
	StartInput => not Key(2),
	DownInput => not Key(1),
	ForcePause => not SW(9),
	HEX0 => HEX0,
	HEX1 => HEX1,
	HEX2 => HEX2,
	HEX3 => HEX3,
	HEX4 => HEX4,
	HEX5 => HEX5,
	LEDR => LEDR,
	ColorOut => ColorTable,
	ScanlineX => ScanlineX,
	ScanlineY => ScanlineY
	);

	--------- 7Segment Show ------------
	RESET <= not RESET_N;

	

end CAD_VGA_Quartus;