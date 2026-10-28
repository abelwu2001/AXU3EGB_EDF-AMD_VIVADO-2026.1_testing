-- hdl/axi_pwm_v1_0_S00_AXI.vhd
-- AXI4-Lite slave interface for axi_pwm IP.
-- Four 32-bit slave registers:
--   reg0 CTRL   : bit0=enable, bit1=polarity
--   reg1 PERIOD : PWM period in clock cycles
--   reg2 DUTY   : High cycles (0..period)
--   reg3 STATUS : unused (read-back of reg3)
-- Instantiates pwm_core to drive pwm_out.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_pwm_v1_0_S00_AXI is
  generic (
    C_S_AXI_DATA_WIDTH : integer := 32;
    C_S_AXI_ADDR_WIDTH : integer := 4
  );
  port (
    -- Users to add ports here
    pwm_out        : out std_logic;
    -- User ports ends
    -- Do not modify the ports beyond this line
    S_AXI_ACLK    : in  std_logic;
    S_AXI_ARESETN : in  std_logic;
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic
  );
end axi_pwm_v1_0_S00_AXI;

architecture arch_imp of axi_pwm_v1_0_S00_AXI is

  -- AXI4LITE internal signals
  signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  -- ADDR_LSB is 2 for 32-bit data bus
  constant ADDR_LSB          : integer := (C_S_AXI_DATA_WIDTH/32) + 1;
  constant OPT_MEM_ADDR_BITS : integer := 1;

  -- Slave registers
  signal slv_reg0 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg1 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg2 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg3 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg_rden : std_logic;
  signal slv_reg_wren : std_logic;
  signal reg_data_out : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal aw_en        : std_logic;

begin

  -- I/O connections
  S_AXI_AWREADY <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP   <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY <= axi_arready;
  S_AXI_RDATA   <= axi_rdata;
  S_AXI_RRESP   <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;

  -- Implement axi_awready generation
  p_awready : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awready <= '0';
        aw_en <= '1';
      else
        if axi_awready = '0' and S_AXI_AWVALID = '1' and
           S_AXI_WVALID = '1' and aw_en = '1' then
          axi_awready <= '1';
          aw_en <= '0';
        elsif S_AXI_BREADY = '1' and axi_bvalid = '1' then
          aw_en <= '1';
          axi_awready <= '0';
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process p_awready;

  -- Implement axi_awaddr latching
  p_awaddr : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awaddr <= (others => '0');
      else
        if axi_awready = '0' and S_AXI_AWVALID = '1' and
           S_AXI_WVALID = '1' and aw_en = '1' then
          axi_awaddr <= S_AXI_AWADDR;
        end if;
      end if;
    end if;
  end process p_awaddr;

  -- Implement axi_wready generation
  p_wready : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_wready <= '0';
      else
        if axi_wready = '0' and S_AXI_WVALID = '1' and
           S_AXI_AWVALID = '1' and aw_en = '1' then
          axi_wready <= '1';
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process p_wready;

  slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID;

  -- Implement register write logic
  p_regs : process(S_AXI_ACLK)
    variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        slv_reg0 <= (others => '0');
        slv_reg1 <= (others => '0');
        slv_reg2 <= (others => '0');
        slv_reg3 <= (others => '0');
      else
        loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
        if slv_reg_wren = '1' then
          case loc_addr is
            when "00" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg0(byte_index*8+7 downto byte_index*8) <=
                    S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when "01" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg1(byte_index*8+7 downto byte_index*8) <=
                    S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when "10" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg2(byte_index*8+7 downto byte_index*8) <=
                    S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when "11" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                if S_AXI_WSTRB(byte_index) = '1' then
                  slv_reg3(byte_index*8+7 downto byte_index*8) <=
                    S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when others =>
              slv_reg0 <= slv_reg0;
              slv_reg1 <= slv_reg1;
              slv_reg2 <= slv_reg2;
              slv_reg3 <= slv_reg3;
          end case;
        end if;
      end if;
    end if;
  end process p_regs;

  -- Implement write response logic
  p_bresp : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_bvalid <= '0';
        axi_bresp  <= "00";
      else
        if axi_awready = '1' and S_AXI_AWVALID = '1' and
           axi_bvalid = '0' and axi_wready = '1' and S_AXI_WVALID = '1' then
          axi_bvalid <= '1';
          axi_bresp  <= "00";
        elsif S_AXI_BREADY = '1' and axi_bvalid = '1' then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;
  end process p_bresp;

  -- Implement axi_arready generation
  p_arready : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_arready <= '0';
        axi_araddr  <= (others => '0');
      else
        if axi_arready = '0' and S_AXI_ARVALID = '1' then
          axi_arready <= '1';
          axi_araddr  <= S_AXI_ARADDR;
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process p_arready;

  -- Implement axi_rvalid generation
  p_rvalid : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
      else
        if axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0' then
          axi_rvalid <= '1';
          axi_rresp  <= "00";
        elsif axi_rvalid = '1' and S_AXI_RREADY = '1' then
          axi_rvalid <= '0';
        end if;
      end if;
    end if;
  end process p_rvalid;

  slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid);

  -- Register read mux (combinational)
  p_rmux : process(slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr)
    variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
  begin
    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
    case loc_addr is
      when "00"   => reg_data_out <= slv_reg0;
      when "01"   => reg_data_out <= slv_reg1;
      when "10"   => reg_data_out <= slv_reg2;
      when "11"   => reg_data_out <= slv_reg3;
      when others => reg_data_out <= (others => '0');
    end case;
  end process p_rmux;

  -- Output register read data
  p_rdata : process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_rdata <= (others => '0');
      else
        if slv_reg_rden = '1' then
          axi_rdata <= reg_data_out;
        end if;
      end if;
    end if;
  end process p_rdata;

  -- Add user logic here
  u_pwm : entity work.pwm_core
    port map (
      clk       => S_AXI_ACLK,
      rst_n     => S_AXI_ARESETN,
      enable    => slv_reg0(0),
      polarity  => slv_reg0(1),
      period    => unsigned(slv_reg1),
      duty      => unsigned(slv_reg2),
      pwm_out   => pwm_out,
      raw_level => open
    );
  -- User logic ends

end arch_imp;

