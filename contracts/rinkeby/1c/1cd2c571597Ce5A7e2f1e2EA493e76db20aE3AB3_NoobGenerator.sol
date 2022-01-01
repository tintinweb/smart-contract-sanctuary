//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library NoobGenerator {
    
    struct FaceRands {
        int cx;
        int cy;
        int r;
        uint [4] angs;
        uint start;
        uint [10] path;
        uint color;
        string d;
    }

    struct HeadRands {
        int cx;
        int cy;
        int r;
        uint [4] angs;
        uint start;
        uint [10] path;
        uint color;
        string d;
    }

    struct TongueRands {
        int cx;
        int cy;
        int r;
        uint [4] angs;
        uint start;
        uint [10] path;
        uint color;
        string d;
    }

    struct EyesRands {
        int ex1;
        int ey1;
        int iris1;
        int pupil1;
        int center1;
        int ex2;
        int ey2;
        int iris2;
        int pupil2;
        int center2;
    }
    
    uint256 constant PI = 3141592653589793238; // pi as an 18 decimal value (wad)


    function renderFace(uint[10] memory path) 
        public 
        pure 
        returns(string memory)
    {
    string memory d = string(abi.encodePacked('M',Strings.toString(path[0]),',',Strings.toString(path[1])));
    for(uint i = 2; i < 10 ; i += 2) {
        d = string(abi.encodePacked(d, (i==2) ? 'Q' : (i>4 && i%2==0) ? 'T' : ','));
        d = string(abi.encodePacked(d, Strings.toString(path[i]) , ',' , Strings.toString(path[i + 1])));
      }
      d = string(abi.encodePacked(d, 'T', Strings.toString(path[0]) , ',' , Strings.toString(path[1]),'Z'));
   
      return d;
    }
    
    function renderTongue(uint[10] memory path) 
        public 
        pure 
        returns(string memory)
    {
    string memory d = string(abi.encodePacked('M',Strings.toString(path[0]),',',Strings.toString(path[1])));
    for(uint i = 2; i < 6 ; i += 2) {
        d = string(abi.encodePacked(d, (i==2) ? 'Q' : (i>4 && i%2==0) ? 'T' : ','));
        d = string(abi.encodePacked(d, Strings.toString(path[i]) , ',' , Strings.toString(path[i + 1])));
      }
      d = string(abi.encodePacked(d, 'Z'));

      return d;
    }
  
    function getPath(uint[4] memory angs, int r, int cx, int cy, uint start) 
        public 
        pure
        returns (uint[10] memory){
        
        uint[10] memory path;
        int[4] memory cpxpoint;
        int[4] memory cpypoint;
        uint pc = 0;
        for (uint x = 0; x < 4; x++){
        uint ang = (angs[x]*PI/2/100) + PI/2*x;
        int cpx = cx + Trigonometry.cos(ang)/1e17*r/10;
        int cpy = cy + Trigonometry.sin(ang)/1e17*r/10;
        cpxpoint[x] = cpx;
        cpypoint[x] = cpy;
        }

        for (uint x = start; x < start + 4 ; x++){
        int pathx = (cpxpoint[x%4]+cpxpoint[(x+1)%4])/2;
        int pathy = (cpypoint[x%4]+cpypoint[(x+1)%4])/2;
        path[pc] = uint(pathx); 
        pc += 1;
        path[pc] = uint(pathy);
        pc += 1;
        if( (x%4) == start){
        path[pc] = uint(cpxpoint[(x+1)%4]);
        pc += 1;
        path[pc] = uint(cpypoint[(x+1)%4]);
        pc += 1;
        }
        }
        delete cpxpoint;
        delete cpypoint;
        return path;
    }
    // function test(int r , string memory seed)   public 
    //     pure
    //     returns (int){
    //   return (random(seed, "hr") % 100) > 50 ? r + int( random(seed, "hsize") % 20 ) * -1 : r + int( random(seed, "hsize") % 20 ) ;
    // }

    function getEye(int eyex, int eyey, int iris, int pupil, int center) 
        public 
        pure 
        returns(string memory){
        
        int pupilx = eyex-(Trigonometry.cos(PI*uint(center))/1e17*center*iris/10)/4;
        int pupily = eyey-(Trigonometry.sin(PI*uint(center)+PI/2)/1e17*center*iris/10)/4;

        string memory eye =
            string(
                abi.encodePacked(
                    '<g filter="url(#squiggly5)" opacity="0.75">',
                    '<circle fill="#ffffff" r="',
                    Strings.toString(uint(iris)),
                    '" transform="matrix(1 0 0 1 ',
                    Strings.toString(uint(eyex)), 
                    ' ',
                    Strings.toString(uint(eyey)), 
                    ')"></circle>',
                    '<circle fill="#000000" r="',
                    Strings.toString(uint(pupil)),
                    '" transform="matrix(1 0 0 1 ',
                    Strings.toString(uint(pupilx)), 
                    ' ',
                    Strings.toString(uint(pupily)), 
                    ')"></circle>',
                    '</g>'
                )
            );
        return eye;
    }

    function getnoobForSeed(string memory seed)
        public 
        pure
        returns (string memory)
    {
        FaceRands memory frand;
        HeadRands memory headrand;
        TongueRands memory tonguerand;
        EyesRands memory eyesrand;
        //face random attributes
        frand.r = int( random(seed, "fr") % 300 + 150 );
        frand.start = random(seed, "fstart") % 4;
        frand.color = random(seed, "fcolor") % 25;
        frand.cx = 320;
        frand.cy = 320;

        //head random attributes
        headrand.r = (random(seed, "hr") % 100) > 50 ? frand.r + int( random(seed, "hsize") % 20 ) * -1 : frand.r + int( random(seed, "hsize") % 20 ) ;
        headrand.start = random(seed, "hstart") % 4;
        headrand.color = random(seed, "hcolor") % 25;
        headrand.cx = 320;
        headrand.cy = 320;
        
        //tongue random attributes
        tonguerand.r = int( random(seed, "tr") % 150 + 160 );
        tonguerand.start = random(seed, "tstart") % 4;
        tonguerand.color = random(seed, "tcolor") % 10;
        tonguerand.cx = 320;
        tonguerand.cy = 320;

        //eye random attributes
        eyesrand.ex1 = int( random(seed, "eyex1") % 500 + 60 );
        eyesrand.ey1 = int( random(seed, "eyey1") % 500 + 60 );
        eyesrand.iris1 = int( random(seed, "iris1") % 20 + 25 );
        eyesrand.pupil1 = int( random(seed, "pupil1") % 20 + 5 );
        eyesrand.center1 = int( random(seed, "pupil1") % 4 );
        
        eyesrand.ex2 = int( random(seed, "eyex2") % 500 + 60 );
        eyesrand.ey2 = int( random(seed, "eyey2") % 500 + 60 );
        eyesrand.iris2 = int( random(seed, "iris2") % 20 + 25 );
        eyesrand.pupil2 = int( random(seed, "pupil2") % 20 + 5 );
        eyesrand.center2 = int( random(seed, "pupil2") % 4 );
 
        for (uint x = 0; x < 4; x++){
             frand.angs[x] = random(seed, string(abi.encodePacked("fnode",Strings.toString(x)))) % 100;
        }

        for (uint x = 0; x < 4; x++){
             headrand.angs[x] = random(seed, string(abi.encodePacked("hnode",Strings.toString(x)))) % 100;
        }

        for (uint x = 0; x < 4; x++){
             tonguerand.angs[x] = random(seed, string(abi.encodePacked("tnode",Strings.toString(x)))) % 100;
        }

        frand.path = getPath(frand.angs, frand.r, frand.cx, frand.cy, frand.start);
        frand.d = renderFace(frand.path);

        headrand.path = getPath(headrand.angs, headrand.r, headrand.cx, headrand.cy, headrand.start);
        headrand.d = renderFace(headrand.path);
        
        tonguerand.path = getPath(tonguerand.angs, tonguerand.r, tonguerand.cx, tonguerand.cy, tonguerand.start);
        tonguerand.d = renderTongue(tonguerand.path);
     
        string[25] memory colors = [           
                "000000","FFFFFF","EEE77E","F0DA45","FBB040","B86228","D16562","D15054","A51E22","F1B7C9","E17FA0","B54365","670917","A789A6","603E6F","2C1D52","241537","67B8BE","13999F","0B6976","004554","8FD0BA","21B18A","087561","024235"
        ];
        
        string[10] memory colors1 = [
                "#000000","#FFFFFF","#EAB94E","#DD683B","#D53C52","#B5347E","#603387","#2F69AC","#449F9C","#7AB551"
        ];

        string[4] memory animation = [
            '<animate xlink:href="#t1" attributeName="seed" from="1" to="4" dur=".4s" repeatCount="indefinite"/>',
            '<animate xlink:href="#t2" attributeName="seed" from="3" to="8" dur=".6s" repeatCount="indefinite"/>',
            '<animate xlink:href="#t4" attributeName="seed" from="5" to="9" dur=".5s" repeatCount="indefinite"/>',
            '<animate xlink:href="#t5" attributeName="seed" from="6" to="9" dur=".4s" repeatCount="indefinite"/>'
        ];
        string memory face =
            string(
                abi.encodePacked(
                    '<path fill="#',
                    colors[frand.color],
                    '" stroke="none" d="',
                    frand.d, 
                    '" filter="url(#squiggly1)" fill-opacity="0.5">',
                    '</path>'
                )
            );
    
       string memory head =
            string(
                abi.encodePacked(
                    '<path stroke="#',
                    colors[headrand.color],
                    '" stroke-width="12" fill="none" d="',
                    headrand.d, 
                    '" filter="url(#squiggly4)" stroke-opacity="0.5">',
                    '</path>'
                )
            );
        string memory tongue =
            string(
                abi.encodePacked(
                    '<path fill="#',
                    colors1[tonguerand.color],
                    '" stroke="none" d="',
                    tonguerand.d, 
                    '" filter="url(#squiggly1)" fill-opacity="0.5">',
                    '</path>'
                )
            );
        
        string memory eye1 = getEye(eyesrand.ex1,eyesrand.ey1,eyesrand.iris1,eyesrand.pupil1,eyesrand.center1);
        string memory eye2 = getEye(eyesrand.ex2,eyesrand.ey2,eyesrand.iris2,eyesrand.pupil2,eyesrand.center2);
    
        // Build the SVG from various parts
        //string[7] memory svgParts;
        
        string memory svg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" presevAspectRatio="xMidYMid meet"><defs>',
                '<filter id="squiggly1" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence id="t1" baseFrequency=".001" numOctaves="1" result="noise" seed="1"/><feDisplacementMap xChannelSelector="A" yChannelSelector="A" in="SourceGraphic" in2="noise" scale="35"/></filter>',
                '<filter id="squiggly2" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence id="t2" baseFrequency=".002" numOctaves="1" result="noise" seed="1"/><feDisplacementMap xChannelSelector="A" yChannelSelector="A" in="SourceGraphic" in2="noise" scale="30"/></filter>',
                '<filter id="squiggly4" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence id="t4" baseFrequency=".002" numOctaves="1" result="noise" seed="1"/><feDisplacementMap xChannelSelector="A" yChannelSelector="A" in="SourceGraphic" in2="noise" scale="20"/></filter>',
                '<filter id="squiggly5" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence id="t5" baseFrequency=".0015" numOctaves="1" result="noise" seed="1"/><feDisplacementMap xChannelSelector="A" yChannelSelector="A" in="SourceGraphic" in2="noise" scale="40"/></filter>',
                '</defs>',
                '<rect x="0" y="0" width="640" height="640" fill="rgb(188,188,188)"/>',
                face,
                head,
                tongue,
                eye1,
                eye2,
                animation[0],
                animation[1],
                animation[2],
                animation[3],
                '</svg>'
            )
        );


        return svg;
    }

    function random(string memory seed, string memory key)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(key, seed)));
    }
}

library Trigonometry {
  // Table index into the trigonometric table
  uint256 constant INDEX_WIDTH        = 8;
  // Interpolation between successive entries in the table
  uint256 constant INTERP_WIDTH       = 16;
  uint256 constant INDEX_OFFSET       = 28 - INDEX_WIDTH;
  uint256 constant INTERP_OFFSET      = INDEX_OFFSET - INTERP_WIDTH;
  uint32  constant ANGLES_IN_CYCLE    = 1073741824;
  uint32  constant QUADRANT_HIGH_MASK = 536870912;
  uint32  constant QUADRANT_LOW_MASK  = 268435456;
  uint256 constant SINE_TABLE_SIZE    = 256;

  // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
  // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
  uint256 constant PI          = 3141592653589793238;
  uint256 constant TWO_PI      = 2 * PI;
  uint256 constant PI_OVER_TWO = PI / 2;

  // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
  // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
  // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
  // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
  // 256 defined above)
  uint8   constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
  uint256 constant entry_mask  = ((1 << 8*entry_bytes) - 1); // mask used to cast bytes32 -> lookup table entry
  bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

  /**
   * @notice Return the sine of a value, specified in radians scaled by 1e18
   * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
   * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
   * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
   * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
   * range of -1 to 1, again scaled by 1e18
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function sin(uint256 _angle) internal pure returns (int256) {
    unchecked {
      // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
      // of 0 to 1,073,741,824
      _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;

      // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
      // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
      // and the offset is the offset of the bits (in bits) we want to extract. The result is an
      // integer containing _width bits of _value starting at the offset bit
      uint256 interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
      uint256 index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);

      // The lookup table only contains data for one quadrant (since sin is symmetric around both
      // axes), so here we figure out which quadrant we're in, then we lookup the values in the
      // table then modify values accordingly
      bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
      bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

      if (!is_odd_quadrant) {
        index = SINE_TABLE_SIZE - 1 - index;
      }

      bytes memory table = sin_table;
      // We are looking for two consecutive indices in our lookup table
      // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
      // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
      uint256 offset1_2 = (index + 2) * entry_bytes;

      // This following snippet will function for any entry_bytes <= 15
      uint256 x1_2; assembly {
        // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
        x1_2 := mload(add(table, offset1_2))
      }

      // We now read the last two numbers of size entry_bytes from x1_2
      // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
      // therefore: entry_mask = 0xFFFFFFFF

      // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
      // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
      uint256 x1 = x1_2 >> 8*entry_bytes & entry_mask;
      // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
      uint256 x2 = x1_2 & entry_mask;

      // Approximate angle by interpolating in the table, accounting for the quadrant
      uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
      int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
      if (is_negative_quadrant) {
        sine *= -1;
      }

      // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
      // This can never overflow because sine is bounded by the above values
      return sine * 1e18 / 2_147_483_647;
    }
  }

  /**
   * @notice Return the cosine of a value, specified in radians scaled by 1e18
   * @dev This is identical to the sin() method, and just computes the value by delegating to the
   * sin() method using the identity cos(x) = sin(x + pi/2)
   * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function cos(uint256 _angle) internal pure returns (int256) {
    unchecked {
      return sin(_angle + PI_OVER_TWO);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}