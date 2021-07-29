/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract Quran {

   address private owner;
    
    string [540] ruku;
    
    // null address = 0x0000000000000000000000000000000000000000
    
                    //Contract Security 
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
      constructor() {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }
        
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
   
                    //Store Quran by Ruku
   
    function store(string  memory _data, uint256 _index) public isOwner{
        ruku[_index] = _data;
    }


                    //Get  Quran by Ruku   
                    
   function ruku_0() public view returns (string memory){
        return ruku[0];
    }
    
    function ruku_1() public view returns (string memory){
        return ruku[1];
    }
     
    function ruku_2() public view returns (string memory){
        return ruku[2];
    }
    
    function ruku_3() public view returns (string memory){
        return ruku[3];
    }
    
    function ruku_4() public view returns (string memory){
        return ruku[4];
    }
    
    function ruku_5() public view returns (string memory){
        return ruku[5];
    }
    
    function ruku_6() public view returns (string memory){
        return ruku[6];
    }
    
    function ruku_7() public view returns (string memory){
        return ruku[7];
    }
    
    function ruku_8() public view returns (string memory){
        return ruku[8];
    }
    
    function ruku_9() public view returns (string memory){
        return ruku[9];
    }
    
    function ruku_10() public view returns (string memory){
        return ruku[10];
    }
    
    function ruku_11() public view returns (string memory){
        return ruku[11];
    }
    
    function ruku_12() public view returns (string memory){
        return ruku[12];
    }
    
    function ruku_13() public view returns (string memory){
        return ruku[13];
    }
    
    function ruku_14() public view returns (string memory){
        return ruku[14];
    }
    
    function ruku_15() public view returns (string memory){
        return ruku[15];
    }
    
    function ruku_16() public view returns (string memory){
        return ruku[16];
    }
    
    function ruku_17() public view returns (string memory){
        return ruku[17];
    }
    
    function ruku_18() public view returns (string memory){
        return ruku[18];
    }
    
    function ruku_19() public view returns (string memory){
        return ruku[19];
    }
    
    function ruku_20() public view returns (string memory){
        return ruku[20];
    }
    
    function ruku_21() public view returns (string memory){
        return ruku[21];
    }
    
    function ruku_22() public view returns (string memory){
        return ruku[22];
    }
    
    function ruku_23() public view returns (string memory){
        return ruku[23];
    }
    
    function ruku_24() public view returns (string memory){
        return ruku[24];
    }
    
    function ruku_25() public view returns (string memory){
        return ruku[25];
    }
    
    function ruku_26() public view returns (string memory){
        return ruku[26];
    }
    
    function ruku_27() public view returns (string memory){
        return ruku[27];
    }
    
    function ruku_28() public view returns (string memory){
        return ruku[28];
    }
    
    function ruku_29() public view returns (string memory){
        return ruku[29];
    }
    
    function ruku_30() public view returns (string memory){
        return ruku[30];
    }
    
    function ruku_31() public view returns (string memory){
        return ruku[31];
    }
    
    function ruku_32() public view returns (string memory){
        return ruku[32];
    }
    
    function ruku_33() public view returns (string memory){
        return ruku[33];
    }
    
    function ruku_34() public view returns (string memory){
        return ruku[34];
    }
    
    function ruku_35() public view returns (string memory){
        return ruku[35];
    }
    
    function ruku_36() public view returns (string memory){
        return ruku[36];
    }
    
    function ruku_37() public view returns (string memory){
        return ruku[37];
    }
    
    function ruku_38() public view returns (string memory){
        return ruku[38];
    }
    
    function ruku_39() public view returns (string memory){
        return ruku[39];
    }
    
    function ruku_40() public view returns (string memory){
        return ruku[40];
    }
    
    function ruku_41() public view returns (string memory){
        return ruku[41];
    }
    
    function ruku_42() public view returns (string memory){
        return ruku[42];
    }
    
    function ruku_43() public view returns (string memory){
        return ruku[43];
    }
    
    function ruku_44() public view returns (string memory){
        return ruku[44];
    }
    
    function ruku_45() public view returns (string memory){
        return ruku[45];
    }
    
    function ruku_46() public view returns (string memory){
        return ruku[46];
    }
    
    function ruku_47() public view returns (string memory){
        return ruku[47];
    }
    
    function ruku_48() public view returns (string memory){
        return ruku[48];
    }
    
    function ruku_49() public view returns (string memory){
        return ruku[49];
    }
    
    function ruku_50() public view returns (string memory){
        return ruku[50];
    }
    
    function ruku_51() public view returns (string memory){
        return ruku[51];
    }
    
    function ruku_52() public view returns (string memory){
        return ruku[52];
    }
    
    function ruku_53() public view returns (string memory){
        return ruku[53];
    }
    
    function ruku_54() public view returns (string memory){
        return ruku[54];
    }
    
    function ruku_55() public view returns (string memory){
        return ruku[55];
    }
    
    function ruku_56() public view returns (string memory){
        return ruku[56];
    }
    
    function ruku_57() public view returns (string memory){
        return ruku[57];
    }
    
    function ruku_58() public view returns (string memory){
        return ruku[58];
    }
    
    function ruku_59() public view returns (string memory){
        return ruku[59];
    }
    
    function ruku_60() public view returns (string memory){
        return ruku[60];
    }
    
    function ruku_61() public view returns (string memory){
        return ruku[61];
    }
    
    function ruku_62() public view returns (string memory){
        return ruku[62];
    }
    
    function ruku_63() public view returns (string memory){
        return ruku[63];
    }
    
    function ruku_64() public view returns (string memory){
        return ruku[64];
    }
    
    function ruku_65() public view returns (string memory){
        return ruku[65];
    }
    
    function ruku_66() public view returns (string memory){
        return ruku[66];
    }
    
    function ruku_67() public view returns (string memory){
        return ruku[67];
    }
    
    function ruku_68() public view returns (string memory){
        return ruku[68];
    }
    
    function ruku_69() public view returns (string memory){
        return ruku[69];
    }
    
    function ruku_70() public view returns (string memory){
        return ruku[70];
    }
    
    function ruku_71() public view returns (string memory){
        return ruku[71];
    }
    
    function ruku_72() public view returns (string memory){
        return ruku[72];
    }
    
    function ruku_73() public view returns (string memory){
        return ruku[73];
    }
    
    function ruku_74() public view returns (string memory){
        return ruku[74];
    }
    
    function ruku_75() public view returns (string memory){
        return ruku[75];
    }
    
    function ruku_76() public view returns (string memory){
        return ruku[76];
    }
    
    function ruku_77() public view returns (string memory){
        return ruku[77];
    }
    
    function ruku_78() public view returns (string memory){
        return ruku[78];
    }
    
    function ruku_79() public view returns (string memory){
        return ruku[79];
    }
    
    function ruku_80() public view returns (string memory){
        return ruku[80];
    }
    
    function ruku_81() public view returns (string memory){
        return ruku[81];
    }
    
    function ruku_82() public view returns (string memory){
        return ruku[82];
    }
    
    function ruku_83() public view returns (string memory){
        return ruku[83];
    }
    
    function ruku_84() public view returns (string memory){
        return ruku[84];
    }
    
    function ruku_85() public view returns (string memory){
        return ruku[85];
    }
    
    function ruku_86() public view returns (string memory){
        return ruku[86];
    }
    
    function ruku_87() public view returns (string memory){
        return ruku[87];
    }
    
    function ruku_88() public view returns (string memory){
        return ruku[88];
    }
    
    function ruku_89() public view returns (string memory){
        return ruku[89];
    }
    
    function ruku_90() public view returns (string memory){
        return ruku[90];
    }
    
    function ruku_91() public view returns (string memory){
        return ruku[91];
    }
    
    function ruku_92() public view returns (string memory){
        return ruku[92];
    }
    
    function ruku_93() public view returns (string memory){
        return ruku[93];
    }
    
    function ruku_94() public view returns (string memory){
        return ruku[94];
    }
    
    function ruku_95() public view returns (string memory){
        return ruku[95];
    }
    
    function ruku_96() public view returns (string memory){
        return ruku[96];
    }
    
    function ruku_97() public view returns (string memory){
        return ruku[97];
    }
    
    function ruku_98() public view returns (string memory){
        return ruku[98];
    }
    
    function ruku_99() public view returns (string memory){
        return ruku[99];
    }
    
    function ruku_100() public view returns (string memory){
        return ruku[100];
    }
    
     function ruku_101() public view returns (string memory){
        return ruku[101];
    }
     
    function ruku_102() public view returns (string memory){
        return ruku[102];
    }
    
    function ruku_103() public view returns (string memory){
        return ruku[103];
    }
    
    function ruku_104() public view returns (string memory){
        return ruku[104];
    }
    
    function ruku_105() public view returns (string memory){
        return ruku[105];
    }
    
    function ruku_106() public view returns (string memory){
        return ruku[106];
    }
    
    function ruku_107() public view returns (string memory){
        return ruku[107];
    }
    
    function ruku_108() public view returns (string memory){
        return ruku[108];
    }
    
    function ruku_109() public view returns (string memory){
        return ruku[109];
    }
    
    function ruku_110() public view returns (string memory){
        return ruku[110];
    }
    
    function ruku_111() public view returns (string memory){
        return ruku[111];
    }
    
    function ruku_112() public view returns (string memory){
        return ruku[112];
    }
    
    function ruku_113() public view returns (string memory){
        return ruku[113];
    }
    
    function ruku_114() public view returns (string memory){
        return ruku[114];
    }
    
    function ruku_115() public view returns (string memory){
        return ruku[115];
    }
    
    function ruku_116() public view returns (string memory){
        return ruku[116];
    }
    
    function ruku_117() public view returns (string memory){
        return ruku[117];
    }
    
    function ruku_118() public view returns (string memory){
        return ruku[118];
    }
    
    function ruku_119() public view returns (string memory){
        return ruku[119];
    }
    
    function ruku_120() public view returns (string memory){
        return ruku[120];
    }
    
    function ruku_121() public view returns (string memory){
        return ruku[121];
    }
    
    function ruku_122() public view returns (string memory){
        return ruku[122];
    }
    
    function ruku_123() public view returns (string memory){
        return ruku[123];
    }
    
    function ruku_124() public view returns (string memory){
        return ruku[124];
    }
    
    function ruku_125() public view returns (string memory){
        return ruku[125];
    }
    
    function ruku_126() public view returns (string memory){
        return ruku[126];
    }
    
    function ruku_127() public view returns (string memory){
        return ruku[127];
    }
    
    function ruku_128() public view returns (string memory){
        return ruku[128];
    }
    
    function ruku_129() public view returns (string memory){
        return ruku[129];
    }
    
    function ruku_130() public view returns (string memory){
        return ruku[130];
    }
    
    function ruku_131() public view returns (string memory){
        return ruku[131];
    }
    
    function ruku_132() public view returns (string memory){
        return ruku[132];
    }
    
    function ruku_133() public view returns (string memory){
        return ruku[133];
    }
    
    function ruku_134() public view returns (string memory){
        return ruku[134];
    }
    
    function ruku_135() public view returns (string memory){
        return ruku[135];
    }
    
    function ruku_136() public view returns (string memory){
        return ruku[136];
    }
    
    function ruku_137() public view returns (string memory){
        return ruku[137];
    }
    
    function ruku_138() public view returns (string memory){
        return ruku[138];
    }
    
    function ruku_139() public view returns (string memory){
        return ruku[139];
    }
    
    function ruku_140() public view returns (string memory){
        return ruku[140];
    }
    
    function ruku_141() public view returns (string memory){
        return ruku[141];
    }
    
    function ruku_142() public view returns (string memory){
        return ruku[142];
    }
    
    function ruku_143() public view returns (string memory){
        return ruku[143];
    }
    
    function ruku_144() public view returns (string memory){
        return ruku[144];
    }
    
    function ruku_145() public view returns (string memory){
        return ruku[145];
    }
    
    function ruku_146() public view returns (string memory){
        return ruku[146];
    }
    
    function ruku_147() public view returns (string memory){
        return ruku[147];
    }
    
    function ruku_148() public view returns (string memory){
        return ruku[148];
    }
    
    function ruku_149() public view returns (string memory){
        return ruku[149];
    }
    
    function ruku_150() public view returns (string memory){
        return ruku[150];
    }
    
    function ruku_151() public view returns (string memory){
        return ruku[151];
    }
    
    function ruku_152() public view returns (string memory){
        return ruku[152];
    }
    
    function ruku_153() public view returns (string memory){
        return ruku[153];
    }
    
    function ruku_154() public view returns (string memory){
        return ruku[154];
    }
    
    function ruku_155() public view returns (string memory){
        return ruku[155];
    }
    
    function ruku_156() public view returns (string memory){
        return ruku[156];
    }
    
    function ruku_157() public view returns (string memory){
        return ruku[157];
    }
    
    function ruku_158() public view returns (string memory){
        return ruku[158];
    }
    
    function ruku_159() public view returns (string memory){
        return ruku[159];
    }
    
    function ruku_160() public view returns (string memory){
        return ruku[160];
    }
    
    function ruku_161() public view returns (string memory){
        return ruku[161];
    }
    
    function ruku_162() public view returns (string memory){
        return ruku[162];
    }
    
    function ruku_163() public view returns (string memory){
        return ruku[163];
    }
    
    function ruku_164() public view returns (string memory){
        return ruku[164];
    }
    
    function ruku_165() public view returns (string memory){
        return ruku[165];
    }
    
    function ruku_166() public view returns (string memory){
        return ruku[166];
    }
    
    function ruku_167() public view returns (string memory){
        return ruku[167];
    }
    
    function ruku_168() public view returns (string memory){
        return ruku[168];
    }
    
    function ruku_169() public view returns (string memory){
        return ruku[169];
    }
    
    function ruku_170() public view returns (string memory){
        return ruku[170];
    }
    
    function ruku_171() public view returns (string memory){
        return ruku[171];
    }
    
    function ruku_172() public view returns (string memory){
        return ruku[172];
    }
    
    function ruku_173() public view returns (string memory){
        return ruku[173];
    }
    
    function ruku_174() public view returns (string memory){
        return ruku[174];
    }
    
    function ruku_175() public view returns (string memory){
        return ruku[175];
    }
    
    function ruku_176() public view returns (string memory){
        return ruku[176];
    }
    
    function ruku_177() public view returns (string memory){
        return ruku[177];
    }
    
    function ruku_178() public view returns (string memory){
        return ruku[178];
    }
    
    function ruku_179() public view returns (string memory){
        return ruku[179];
    }
    
    function ruku_180() public view returns (string memory){
        return ruku[180];
    }
    
    function ruku_181() public view returns (string memory){
        return ruku[181];
    }
    
    function ruku_182() public view returns (string memory){
        return ruku[182];
    }
    
    function ruku_183() public view returns (string memory){
        return ruku[183];
    }
    
    function ruku_184() public view returns (string memory){
        return ruku[184];
    }
    
    function ruku_185() public view returns (string memory){
        return ruku[185];
    }
    
    function ruku_186() public view returns (string memory){
        return ruku[186];
    }
    
    function ruku_187() public view returns (string memory){
        return ruku[187];
    }
    
    function ruku_188() public view returns (string memory){
        return ruku[188];
    }
    
    function ruku_189() public view returns (string memory){
        return ruku[189];
    }
    
    function ruku_190() public view returns (string memory){
        return ruku[190];
    }
    
    function ruku_191() public view returns (string memory){
        return ruku[191];
    }
    
    function ruku_192() public view returns (string memory){
        return ruku[192];
    }
    
    function ruku_193() public view returns (string memory){
        return ruku[193];
    }
    
    function ruku_194() public view returns (string memory){
        return ruku[194];
    }
    
    function ruku_195() public view returns (string memory){
        return ruku[195];
    }
    
    function ruku_196() public view returns (string memory){
        return ruku[196];
    }
    
    function ruku_197() public view returns (string memory){
        return ruku[197];
    }
    
    function ruku_198() public view returns (string memory){
        return ruku[198];
    }
    
    function ruku_199() public view returns (string memory){
        return ruku[199];
    }
    
    function ruku_200() public view returns (string memory){
        return ruku[200];
    }
    
     function ruku_201() public view returns (string memory){
        return ruku[201];
    }
     
    function ruku_202() public view returns (string memory){
        return ruku[202];
    }
    
    function ruku_203() public view returns (string memory){
        return ruku[203];
    }
    
    function ruku_204() public view returns (string memory){
        return ruku[204];
    }
    
    function ruku_205() public view returns (string memory){
        return ruku[205];
    }
    
    function ruku_206() public view returns (string memory){
        return ruku[206];
    }
    
    function ruku_207() public view returns (string memory){
        return ruku[207];
    }
    
    function ruku_208() public view returns (string memory){
        return ruku[208];
    }
    
    function ruku_209() public view returns (string memory){
        return ruku[209];
    }
    
    function ruku_210() public view returns (string memory){
        return ruku[210];
    }
    
    function ruku_211() public view returns (string memory){
        return ruku[211];
    }
    
    function ruku_212() public view returns (string memory){
        return ruku[212];
    }
    
    function ruku_213() public view returns (string memory){
        return ruku[213];
    }
    
    function ruku_214() public view returns (string memory){
        return ruku[214];
    }
    
    function ruku_215() public view returns (string memory){
        return ruku[215];
    }
    
    function ruku_216() public view returns (string memory){
        return ruku[216];
    }
    
    function ruku_217() public view returns (string memory){
        return ruku[217];
    }
    
    function ruku_218() public view returns (string memory){
        return ruku[218];
    }
    
    function ruku_219() public view returns (string memory){
        return ruku[219];
    }
    
    function ruku_220() public view returns (string memory){
        return ruku[220];
    }
    
    function ruku_221() public view returns (string memory){
        return ruku[221];
    }
    
    function ruku_222() public view returns (string memory){
        return ruku[222];
    }
    
    function ruku_223() public view returns (string memory){
        return ruku[223];
    }
    
    function ruku_224() public view returns (string memory){
        return ruku[224];
    }
    
    function ruku_225() public view returns (string memory){
        return ruku[225];
    }
    
    function ruku_226() public view returns (string memory){
        return ruku[226];
    }
    
    function ruku_227() public view returns (string memory){
        return ruku[227];
    }
    
    function ruku_228() public view returns (string memory){
        return ruku[228];
    }
    
    function ruku_229() public view returns (string memory){
        return ruku[229];
    }
    
    function ruku_230() public view returns (string memory){
        return ruku[230];
    }
    
    function ruku_231() public view returns (string memory){
        return ruku[231];
    }
    
    function ruku_232() public view returns (string memory){
        return ruku[232];
    }
    
    function ruku_233() public view returns (string memory){
        return ruku[233];
    }
    
    function ruku_234() public view returns (string memory){
        return ruku[234];
    }
    
    function ruku_235() public view returns (string memory){
        return ruku[235];
    }
    
    function ruku_236() public view returns (string memory){
        return ruku[236];
    }
    
    function ruku_237() public view returns (string memory){
        return ruku[237];
    }
    
    function ruku_238() public view returns (string memory){
        return ruku[238];
    }
    
    function ruku_239() public view returns (string memory){
        return ruku[239];
    }
    
    function ruku_240() public view returns (string memory){
        return ruku[240];
    }
    
    function ruku_241() public view returns (string memory){
        return ruku[241];
    }
    
    function ruku_242() public view returns (string memory){
        return ruku[242];
    }
    
    function ruku_243() public view returns (string memory){
        return ruku[243];
    }
    
    function ruku_244() public view returns (string memory){
        return ruku[244];
    }
    
    function ruku_245() public view returns (string memory){
        return ruku[245];
    }
    
    function ruku_246() public view returns (string memory){
        return ruku[246];
    }
    
    function ruku_247() public view returns (string memory){
        return ruku[247];
    }
    
    function ruku_248() public view returns (string memory){
        return ruku[248];
    }
    
    function ruku_249() public view returns (string memory){
        return ruku[249];
    }
    
    function ruku_250() public view returns (string memory){
        return ruku[250];
    }
    
    function ruku_251() public view returns (string memory){
        return ruku[251];
    }
    
    function ruku_252() public view returns (string memory){
        return ruku[252];
    }
    
    function ruku_253() public view returns (string memory){
        return ruku[253];
    }
    
    function ruku_254() public view returns (string memory){
        return ruku[254];
    }
    
    function ruku_255() public view returns (string memory){
        return ruku[255];
    }
    
    function ruku_256() public view returns (string memory){
        return ruku[256];
    }
    
    function ruku_257() public view returns (string memory){
        return ruku[257];
    }
    
    function ruku_258() public view returns (string memory){
        return ruku[258];
    }
    
    function ruku_259() public view returns (string memory){
        return ruku[259];
    }
    
    function ruku_260() public view returns (string memory){
        return ruku[260];
    }
    
    function ruku_261() public view returns (string memory){
        return ruku[261];
    }
    
    function ruku_262() public view returns (string memory){
        return ruku[262];
    }
    
    function ruku_263() public view returns (string memory){
        return ruku[263];
    }
    
    function ruku_264() public view returns (string memory){
        return ruku[264];
    }
    
    function ruku_265() public view returns (string memory){
        return ruku[265];
    }
    
    function ruku_266() public view returns (string memory){
        return ruku[266];
    }
    
    function ruku_267() public view returns (string memory){
        return ruku[267];
    }
    
    function ruku_268() public view returns (string memory){
        return ruku[268];
    }
    
    function ruku_269() public view returns (string memory){
        return ruku[269];
    }
    
    function ruku_270() public view returns (string memory){
        return ruku[270];
    }
    
    function ruku_271() public view returns (string memory){
        return ruku[271];
    }
    
    function ruku_272() public view returns (string memory){
        return ruku[272];
    }
    
    function ruku_273() public view returns (string memory){
        return ruku[273];
    }
    
    function ruku_274() public view returns (string memory){
        return ruku[274];
    }
    
    function ruku_275() public view returns (string memory){
        return ruku[275];
    }
    
    function ruku_276() public view returns (string memory){
        return ruku[276];
    }
    
    function ruku_277() public view returns (string memory){
        return ruku[277];
    }
    
    function ruku_278() public view returns (string memory){
        return ruku[278];
    }
    
    function ruku_279() public view returns (string memory){
        return ruku[279];
    }
    
    function ruku_280() public view returns (string memory){
        return ruku[280];
    }
    
    function ruku_281() public view returns (string memory){
        return ruku[281];
    }
    
    function ruku_282() public view returns (string memory){
        return ruku[282];
    }
    
    function ruku_283() public view returns (string memory){
        return ruku[283];
    }
    
    function ruku_284() public view returns (string memory){
        return ruku[284];
    }
    
    function ruku_285() public view returns (string memory){
        return ruku[285];
    }
    
    function ruku_286() public view returns (string memory){
        return ruku[286];
    }
    
    function ruku_287() public view returns (string memory){
        return ruku[287];
    }
    
    function ruku_288() public view returns (string memory){
        return ruku[288];
    }
    
    function ruku_289() public view returns (string memory){
        return ruku[289];
    }
    
    function ruku_290() public view returns (string memory){
        return ruku[290];
    }
    
    function ruku_291() public view returns (string memory){
        return ruku[291];
    }
    
    function ruku_292() public view returns (string memory){
        return ruku[292];
    }
    
    function ruku_293() public view returns (string memory){
        return ruku[293];
    }
    
    function ruku_294() public view returns (string memory){
        return ruku[294];
    }
    
    function ruku_295() public view returns (string memory){
        return ruku[295];
    }
    
    function ruku_296() public view returns (string memory){
        return ruku[296];
    }
    
    function ruku_297() public view returns (string memory){
        return ruku[297];
    }
    
    function ruku_298() public view returns (string memory){
        return ruku[298];
    }
    
    function ruku_299() public view returns (string memory){
        return ruku[299];
    }
    
    function ruku_300() public view returns (string memory){
        return ruku[300];
    }
    
     function ruku_301() public view returns (string memory){
        return ruku[301];
    }
     
    function ruku_302() public view returns (string memory){
        return ruku[302];
    }
    
    function ruku_303() public view returns (string memory){
        return ruku[303];
    }
    
    function ruku_304() public view returns (string memory){
        return ruku[304];
    }
    
    function ruku_305() public view returns (string memory){
        return ruku[305];
    }
    
    function ruku_306() public view returns (string memory){
        return ruku[306];
    }
    
    function ruku_307() public view returns (string memory){
        return ruku[307];
    }
    
    function ruku_308() public view returns (string memory){
        return ruku[308];
    }
    
    function ruku_309() public view returns (string memory){
        return ruku[309];
    }
    
    function ruku_310() public view returns (string memory){
        return ruku[310];
    }
    
    function ruku_311() public view returns (string memory){
        return ruku[311];
    }
    
    function ruku_312() public view returns (string memory){
        return ruku[312];
    }
    
    function ruku_313() public view returns (string memory){
        return ruku[313];
    }
    
    function ruku_314() public view returns (string memory){
        return ruku[314];
    }
    
    function ruku_315() public view returns (string memory){
        return ruku[315];
    }
    
    function ruku_316() public view returns (string memory){
        return ruku[316];
    }
    
    function ruku_317() public view returns (string memory){
        return ruku[317];
    }
    
    function ruku_318() public view returns (string memory){
        return ruku[318];
    }
    
    function ruku_319() public view returns (string memory){
        return ruku[319];
    }
    
    function ruku_320() public view returns (string memory){
        return ruku[320];
    }
    
    function ruku_321() public view returns (string memory){
        return ruku[321];
    }
    
    function ruku_322() public view returns (string memory){
        return ruku[322];
    }
    
    function ruku_323() public view returns (string memory){
        return ruku[323];
    }
    
    function ruku_324() public view returns (string memory){
        return ruku[324];
    }
    
    function ruku_325() public view returns (string memory){
        return ruku[325];
    }
    
    function ruku_326() public view returns (string memory){
        return ruku[326];
    }
    
    function ruku_327() public view returns (string memory){
        return ruku[327];
    }
    
    function ruku_328() public view returns (string memory){
        return ruku[328];
    }
    
    function ruku_329() public view returns (string memory){
        return ruku[329];
    }
    
    function ruku_330() public view returns (string memory){
        return ruku[330];
    }
    
    function ruku_331() public view returns (string memory){
        return ruku[331];
    }
    
    function ruku_332() public view returns (string memory){
        return ruku[332];
    }
    
    function ruku_333() public view returns (string memory){
        return ruku[333];
    }
    
    function ruku_334() public view returns (string memory){
        return ruku[334];
    }
    
    function ruku_335() public view returns (string memory){
        return ruku[335];
    }
    
    function ruku_336() public view returns (string memory){
        return ruku[336];
    }
    
    function ruku_337() public view returns (string memory){
        return ruku[337];
    }
    
    function ruku_338() public view returns (string memory){
        return ruku[338];
    }
    
    function ruku_339() public view returns (string memory){
        return ruku[339];
    }
    
    function ruku_340() public view returns (string memory){
        return ruku[340];
    }
    
    function ruku_341() public view returns (string memory){
        return ruku[341];
    }
    
    function ruku_342() public view returns (string memory){
        return ruku[342];
    }
    
    function ruku_343() public view returns (string memory){
        return ruku[343];
    }
    
    function ruku_344() public view returns (string memory){
        return ruku[344];
    }
    
    function ruku_345() public view returns (string memory){
        return ruku[345];
    }
    
    function ruku_346() public view returns (string memory){
        return ruku[346];
    }
    
    function ruku_347() public view returns (string memory){
        return ruku[347];
    }
    
    function ruku_348() public view returns (string memory){
        return ruku[348];
    }
    
    function ruku_349() public view returns (string memory){
        return ruku[349];
    }
    
    function ruku_350() public view returns (string memory){
        return ruku[350];
    }
    
    function ruku_351() public view returns (string memory){
        return ruku[351];
    }
    
    function ruku_352() public view returns (string memory){
        return ruku[352];
    }
    
    function ruku_353() public view returns (string memory){
        return ruku[353];
    }
    
    function ruku_354() public view returns (string memory){
        return ruku[354];
    }
    
    function ruku_355() public view returns (string memory){
        return ruku[355];
    }
    
    function ruku_356() public view returns (string memory){
        return ruku[356];
    }
    
    function ruku_357() public view returns (string memory){
        return ruku[357];
    }
    
    function ruku_358() public view returns (string memory){
        return ruku[358];
    }
    
    function ruku_359() public view returns (string memory){
        return ruku[359];
    }
    
    function ruku_360() public view returns (string memory){
        return ruku[360];
    }
    
    function ruku_361() public view returns (string memory){
        return ruku[361];
    }
    
    function ruku_362() public view returns (string memory){
        return ruku[362];
    }
    
    function ruku_363() public view returns (string memory){
        return ruku[363];
    }
    
    function ruku_364() public view returns (string memory){
        return ruku[364];
    }
    
    function ruku_365() public view returns (string memory){
        return ruku[365];
    }
    
    function ruku_366() public view returns (string memory){
        return ruku[366];
    }
    
    function ruku_367() public view returns (string memory){
        return ruku[367];
    }
    
    function ruku_368() public view returns (string memory){
        return ruku[368];
    }
    
    function ruku_369() public view returns (string memory){
        return ruku[369];
    }
    
    function ruku_370() public view returns (string memory){
        return ruku[370];
    }
    
    function ruku_371() public view returns (string memory){
        return ruku[371];
    }
    
    function ruku_372() public view returns (string memory){
        return ruku[372];
    }
    
    function ruku_373() public view returns (string memory){
        return ruku[373];
    }
    
    function ruku_374() public view returns (string memory){
        return ruku[374];
    }
    
    function ruku_375() public view returns (string memory){
        return ruku[375];
    }
    
    function ruku_376() public view returns (string memory){
        return ruku[376];
    }
    
    function ruku_377() public view returns (string memory){
        return ruku[377];
    }
    
    function ruku_378() public view returns (string memory){
        return ruku[378];
    }
    
    function ruku_379() public view returns (string memory){
        return ruku[379];
    }
    
    function ruku_380() public view returns (string memory){
        return ruku[380];
    }
    
    function ruku_381() public view returns (string memory){
        return ruku[381];
    }
    
    function ruku_382() public view returns (string memory){
        return ruku[382];
    }
    
    function ruku_383() public view returns (string memory){
        return ruku[383];
    }
    
    function ruku_384() public view returns (string memory){
        return ruku[384];
    }
    
    function ruku_385() public view returns (string memory){
        return ruku[385];
    }
    
    function ruku_386() public view returns (string memory){
        return ruku[386];
    }
    
    function ruku_387() public view returns (string memory){
        return ruku[387];
    }
    
    function ruku_388() public view returns (string memory){
        return ruku[388];
    }
    
    function ruku_389() public view returns (string memory){
        return ruku[389];
    }
    
    function ruku_390() public view returns (string memory){
        return ruku[390];
    }
    
    function ruku_391() public view returns (string memory){
        return ruku[391];
    }
    
    function ruku_392() public view returns (string memory){
        return ruku[392];
    }
    
    function ruku_393() public view returns (string memory){
        return ruku[393];
    }
    
    function ruku_394() public view returns (string memory){
        return ruku[394];
    }
    
    function ruku_395() public view returns (string memory){
        return ruku[395];
    }
    
    function ruku_396() public view returns (string memory){
        return ruku[396];
    }
    
    function ruku_397() public view returns (string memory){
        return ruku[397];
    }
    
    function ruku_398() public view returns (string memory){
        return ruku[398];
    }
    
    function ruku_399() public view returns (string memory){
        return ruku[399];
    }
    
    function ruku_400() public view returns (string memory){
        return ruku[400];
    }
    
     function ruku_401() public view returns (string memory){
        return ruku[401];
    }
     
    function ruku_402() public view returns (string memory){
        return ruku[402];
    }
    
    function ruku_403() public view returns (string memory){
        return ruku[403];
    }
    
    function ruku_404() public view returns (string memory){
        return ruku[404];
    }
    
    function ruku_405() public view returns (string memory){
        return ruku[405];
    }
    
    function ruku_406() public view returns (string memory){
        return ruku[406];
    }
    
    function ruku_407() public view returns (string memory){
        return ruku[407];
    }
    
    function ruku_408() public view returns (string memory){
        return ruku[408];
    }
    
    function ruku_409() public view returns (string memory){
        return ruku[409];
    }
    
    function ruku_410() public view returns (string memory){
        return ruku[410];
    }
    
    function ruku_411() public view returns (string memory){
        return ruku[411];
    }
    
    function ruku_412() public view returns (string memory){
        return ruku[412];
    }
    
    function ruku_413() public view returns (string memory){
        return ruku[413];
    }
    
    function ruku_414() public view returns (string memory){
        return ruku[414];
    }
    
    function ruku_415() public view returns (string memory){
        return ruku[415];
    }
    
    function ruku_416() public view returns (string memory){
        return ruku[416];
    }
    
    function ruku_417() public view returns (string memory){
        return ruku[417];
    }
    
    function ruku_418() public view returns (string memory){
        return ruku[418];
    }
    
    function ruku_419() public view returns (string memory){
        return ruku[419];
    }
    
    function ruku_420() public view returns (string memory){
        return ruku[420];
    }
    
    function ruku_421() public view returns (string memory){
        return ruku[421];
    }
    
    function ruku_422() public view returns (string memory){
        return ruku[422];
    }
    
    function ruku_423() public view returns (string memory){
        return ruku[423];
    }
    
    function ruku_424() public view returns (string memory){
        return ruku[424];
    }
    
    function ruku_425() public view returns (string memory){
        return ruku[425];
    }
    
    function ruku_426() public view returns (string memory){
        return ruku[426];
    }
    
    function ruku_427() public view returns (string memory){
        return ruku[427];
    }
    
    function ruku_428() public view returns (string memory){
        return ruku[428];
    }
    
    function ruku_429() public view returns (string memory){
        return ruku[429];
    }
    
    function ruku_430() public view returns (string memory){
        return ruku[430];
    }
    
    function ruku_431() public view returns (string memory){
        return ruku[431];
    }
    
    function ruku_432() public view returns (string memory){
        return ruku[432];
    }
    
    function ruku_433() public view returns (string memory){
        return ruku[433];
    }
    
    function ruku_434() public view returns (string memory){
        return ruku[434];
    }
    
    function ruku_435() public view returns (string memory){
        return ruku[435];
    }
    
    function ruku_436() public view returns (string memory){
        return ruku[436];
    }
    
    function ruku_437() public view returns (string memory){
        return ruku[437];
    }
    
    function ruku_438() public view returns (string memory){
        return ruku[438];
    }
    
    function ruku_439() public view returns (string memory){
        return ruku[439];
    }
    
    function ruku_440() public view returns (string memory){
        return ruku[440];
    }
    
    function ruku_441() public view returns (string memory){
        return ruku[441];
    }
    
    function ruku_442() public view returns (string memory){
        return ruku[442];
    }
    
    function ruku_443() public view returns (string memory){
        return ruku[443];
    }
    
    function ruku_444() public view returns (string memory){
        return ruku[444];
    }
    
    function ruku_445() public view returns (string memory){
        return ruku[445];
    }
    
    function ruku_446() public view returns (string memory){
        return ruku[446];
    }
    
    function ruku_447() public view returns (string memory){
        return ruku[447];
    }
    
    function ruku_448() public view returns (string memory){
        return ruku[448];
    }
    
    function ruku_449() public view returns (string memory){
        return ruku[449];
    }
    
    function ruku_450() public view returns (string memory){
        return ruku[450];
    }
    
    function ruku_451() public view returns (string memory){
        return ruku[451];
    }
    
    function ruku_452() public view returns (string memory){
        return ruku[452];
    }
    
    function ruku_453() public view returns (string memory){
        return ruku[453];
    }
    
    function ruku_454() public view returns (string memory){
        return ruku[454];
    }
    
    function ruku_455() public view returns (string memory){
        return ruku[455];
    }
    
    function ruku_456() public view returns (string memory){
        return ruku[456];
    }
    
    function ruku_457() public view returns (string memory){
        return ruku[457];
    }
    
    function ruku_458() public view returns (string memory){
        return ruku[458];
    }
    
    function ruku_459() public view returns (string memory){
        return ruku[459];
    }
    
    function ruku_460() public view returns (string memory){
        return ruku[460];
    }
    
    function ruku_461() public view returns (string memory){
        return ruku[461];
    }
    
    function ruku_462() public view returns (string memory){
        return ruku[462];
    }
    
    function ruku_463() public view returns (string memory){
        return ruku[463];
    }
    
    function ruku_464() public view returns (string memory){
        return ruku[464];
    }
    
    function ruku_465() public view returns (string memory){
        return ruku[465];
    }
    
    function ruku_466() public view returns (string memory){
        return ruku[466];
    }
    
    function ruku_467() public view returns (string memory){
        return ruku[467];
    }
    
    function ruku_468() public view returns (string memory){
        return ruku[468];
    }
    
    function ruku_469() public view returns (string memory){
        return ruku[469];
    }
    
    function ruku_470() public view returns (string memory){
        return ruku[470];
    }
    
    function ruku_471() public view returns (string memory){
        return ruku[471];
    }
    
    function ruku_472() public view returns (string memory){
        return ruku[472];
    }
    
    function ruku_473() public view returns (string memory){
        return ruku[473];
    }
    
    function ruku_474() public view returns (string memory){
        return ruku[474];
    }
    
    function ruku_475() public view returns (string memory){
        return ruku[475];
    }
    
    function ruku_476() public view returns (string memory){
        return ruku[476];
    }
    
    function ruku_477() public view returns (string memory){
        return ruku[477];
    }
    
    function ruku_478() public view returns (string memory){
        return ruku[478];
    }
    
    function ruku_479() public view returns (string memory){
        return ruku[479];
    }
    
    function ruku_480() public view returns (string memory){
        return ruku[480];
    }
    
    function ruku_481() public view returns (string memory){
        return ruku[481];
    }
    
    function ruku_482() public view returns (string memory){
        return ruku[482];
    }
    
    function ruku_483() public view returns (string memory){
        return ruku[483];
    }
    
    function ruku_484() public view returns (string memory){
        return ruku[484];
    }
    
    function ruku_485() public view returns (string memory){
        return ruku[485];
    }
    
    function ruku_486() public view returns (string memory){
        return ruku[486];
    }
    
    function ruku_487() public view returns (string memory){
        return ruku[487];
    }
    
    function ruku_488() public view returns (string memory){
        return ruku[488];
    }
    
    function ruku_489() public view returns (string memory){
        return ruku[489];
    }
    
    function ruku_490() public view returns (string memory){
        return ruku[490];
    }
    
    function ruku_491() public view returns (string memory){
        return ruku[491];
    }
    
    function ruku_492() public view returns (string memory){
        return ruku[492];
    }
    
    function ruku_493() public view returns (string memory){
        return ruku[493];
    }
    
    function ruku_494() public view returns (string memory){
        return ruku[494];
    }
    
    function ruku_495() public view returns (string memory){
        return ruku[495];
    }
    
    function ruku_496() public view returns (string memory){
        return ruku[496];
    }
    
    function ruku_497() public view returns (string memory){
        return ruku[497];
    }
    
    function ruku_498() public view returns (string memory){
        return ruku[498];
    }
    
    function ruku_499() public view returns (string memory){
        return ruku[499];
    }
    
    function ruku_500() public view returns (string memory){
        return ruku[500];
    }
    
     function ruku_501() public view returns (string memory){
        return ruku[501];
    }
     
    function ruku_502() public view returns (string memory){
        return ruku[502];
    }
    
    function ruku_503() public view returns (string memory){
        return ruku[503];
    }
    
    function ruku_504() public view returns (string memory){
        return ruku[504];
    }
    
    function ruku_505() public view returns (string memory){
        return ruku[505];
    }
    
    function ruku_506() public view returns (string memory){
        return ruku[506];
    }
    
    function ruku_507() public view returns (string memory){
        return ruku[507];
    }
    
    function ruku_508() public view returns (string memory){
        return ruku[508];
    }
    
    function ruku_509() public view returns (string memory){
        return ruku[509];
    }
    
    function ruku_510() public view returns (string memory){
        return ruku[510];
    }
    
    function ruku_511() public view returns (string memory){
        return ruku[511];
    }
    
    function ruku_512() public view returns (string memory){
        return ruku[512];
    }
    
    function ruku_513() public view returns (string memory){
        return ruku[513];
    }
    
    function ruku_514() public view returns (string memory){
        return ruku[514];
    }
    
    function ruku_515() public view returns (string memory){
        return ruku[515];
    }
    
    function ruku_516() public view returns (string memory){
        return ruku[516];
    }
    
    function ruku_517() public view returns (string memory){
        return ruku[517];
    }
    
    function ruku_518() public view returns (string memory){
        return ruku[518];
    }
    
    function ruku_519() public view returns (string memory){
        return ruku[519];
    }
    
    function ruku_520() public view returns (string memory){
        return ruku[520];
    }
    
    function ruku_521() public view returns (string memory){
        return ruku[521];
    }
    
    function ruku_522() public view returns (string memory){
        return ruku[522];
    }
    
    function ruku_523() public view returns (string memory){
        return ruku[523];
    }
    
    function ruku_524() public view returns (string memory){
        return ruku[524];
    }
    
    function ruku_525() public view returns (string memory){
        return ruku[525];
    }
    
    function ruku_526() public view returns (string memory){
        return ruku[526];
    }
    
    function ruku_527() public view returns (string memory){
        return ruku[527];
    }
    
    function ruku_528() public view returns (string memory){
        return ruku[528];
    }
    
    function ruku_529() public view returns (string memory){
        return ruku[529];
    }
    
    function ruku_530() public view returns (string memory){
        return ruku[530];
    }
    
    function ruku_531() public view returns (string memory){
        return ruku[531];
    }
    
    function ruku_532() public view returns (string memory){
        return ruku[532];
    }
    
    function ruku_533() public view returns (string memory){
        return ruku[533];
    }
    
    function ruku_534() public view returns (string memory){
        return ruku[534];
    }
    
    function ruku_535() public view returns (string memory){
        return ruku[535];
    }
    
    function ruku_536() public view returns (string memory){
        return ruku[536];
    }
    
    function ruku_537() public view returns (string memory){
        return ruku[537];
    }
    
    function ruku_538() public view returns (string memory){
        return ruku[538];
    }
    
    function ruku_539() public view returns (string memory){
        return ruku[539];
    }
    

}