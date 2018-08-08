pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_IX_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_IX_883		"	;
		string	public		symbol =	"	RE883IX		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1404357449531340000000000000					;	
										
		event Transfer(address indexed from, address indexed to, uint256 value);								
										
		function SimpleERC20Token() public {								
			balanceOf[msg.sender] = totalSupply;							
			emit Transfer(address(0), msg.sender, totalSupply);							
		}								
										
		function transfer(address to, uint256 value) public returns (bool success) {								
			require(balanceOf[msg.sender] >= value);							
										
			balanceOf[msg.sender] -= value;  // deduct from sender&#39;s balance							
			balanceOf[to] += value;          // add to recipient&#39;s balance							
			emit Transfer(msg.sender, to, value);							
			return true;							
		}								
										
		event Approval(address indexed owner, address indexed spender, uint256 value);								
										
		mapping(address => mapping(address => uint256)) public allowance;								
										
		function approve(address spender, uint256 value)								
			public							
			returns (bool success)							
		{								
			allowance[msg.sender][spender] = value;							
			emit Approval(msg.sender, spender, value);							
			return true;							
		}								
										
		function transferFrom(address from, address to, uint256 value)								
			public							
			returns (bool success)							
		{								
			require(value <= balanceOf[from]);							
			require(value <= allowance[from][msg.sender]);							
										
			balanceOf[from] -= value;							
			balanceOf[to] += value;							
			allowance[from][msg.sender] -= value;							
			emit Transfer(from, to, value);							
			return true;							
		}								
//	}									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 1 &#224; 10									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     < RE_Portfolio_IX_metadata_line_1_____Coface_sa_NR_m_AAm_A2_20250515 >									
	//        < 88AgS2F5z46BUk9go47NZRGbUUF9L1ulxVbFChaYRSgnkIPKkb0CexcSa9C9LI0M >									
	//        < 1E-018 limites [ 1E-018 ; 18624924,6937051 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000006F036329 >									
	//     < RE_Portfolio_IX_metadata_line_2_____Collard_and_Partners_20250515 >									
	//        < vlyvT9gB2FYccmP6U3LoLV2rV90D1fHPP5wf2rsA584Du44Mdl86EGh34zFB8BYZ >									
	//        < 1E-018 limites [ 18624924,6937051 ; 68874631,9508929 ] >									
	//        < 0x000000000000000000000000000000000000000000000006F03632919A865B0F >									
	//     < RE_Portfolio_IX_metadata_line_3_____Continental_Casualty_Co_A_A_20250515 >									
	//        < hH2UrZ74q9xzE9yfj7GRpfFCHMd42c20Wm87Az4pZN0WLW4lN458s3SaE9VWwh9k >									
	//        < 1E-018 limites [ 68874631,9508929 ; 101498328,385074 ] >									
	//        < 0x000000000000000000000000000000000000000000000019A865B0F25CFA2A7A >									
	//     < RE_Portfolio_IX_metadata_line_4_____Continental_Reinsurance_Plc_Bp_20250515 >									
	//        < 115gWxp0JrqasadIp7kQnbP29LcfxTfN0nQu9HXFDy1z48y3g4H5hYRTL93rSKO2 >									
	//        < 1E-018 limites [ 101498328,385074 ; 116002561,283613 ] >									
	//        < 0x000000000000000000000000000000000000000000000025CFA2A7A2B36DDE74 >									
	//     < RE_Portfolio_IX_metadata_line_5_____Converium_20250515 >									
	//        < 0CLLaJt136L02HH7V6MpZBT4IqNUOGE6YHs3wD5uR7H5Ukare8ePOkyY5mho8AQq >									
	//        < 1E-018 limites [ 116002561,283613 ; 139649964,386638 ] >									
	//        < 0x00000000000000000000000000000000000000000000002B36DDE7434060F14A >									
	//     < RE_Portfolio_IX_metadata_line_6_____Copenhagen_Reinsurance_Company_20250515 >									
	//        < Qzl522Bq70Q392lQ8p72mCRkRtge8dUTQLhkEVm6GEs0cmojP2ZhK4IjJOzQo85P >									
	//        < 1E-018 limites [ 139649964,386638 ; 205712184,04366 ] >									
	//        < 0x000000000000000000000000000000000000000000000034060F14A4CA23E3D8 >									
	//     < RE_Portfolio_IX_metadata_line_7_____Coverys_Managing_Agency_Limited_20250515 >									
	//        < i4D6TuTh9Igs3bbAY8FFi0nqBJMr27gT7dkh99b73Ozhzx0sXNirsdn0o7N6ZFob >									
	//        < 1E-018 limites [ 205712184,04366 ; 224867352,068255 ] >									
	//        < 0x00000000000000000000000000000000000000000000004CA23E3D853C505B5A >									
	//     < RE_Portfolio_IX_metadata_line_8_____Coverys_Managing_Agency_Limited_20250515 >									
	//        < xG9R9JlfO5642fzFKTY3Q328k0TfN3h97UeWUqO75rKCkEQ2QZiRvC3n50A575Fa >									
	//        < 1E-018 limites [ 224867352,068255 ; 274254167,804167 ] >									
	//        < 0x000000000000000000000000000000000000000000000053C505B5A662AEA840 >									
	//     < RE_Portfolio_IX_metadata_line_9_____Coverys_Managing_Agency_Limited_20250515 >									
	//        < v6pRPC2v8V43pCu4Y9owQ4ufI9bFtdNM9YVw64hzoBm0sAO26ew52QKHz7H6qcep >									
	//        < 1E-018 limites [ 274254167,804167 ; 292366457,709014 ] >									
	//        < 0x0000000000000000000000000000000000000000000000662AEA8406CEA3D17E >									
	//     < RE_Portfolio_IX_metadata_line_10_____Coverys_Managing_Agency_Limited_20250515 >									
	//        < afPat8fDGKD5Trz2rTRVhjUuVKX6Ki9eZ3RL6tJ60FIw06KuRnCn92V4bWYv4kDJ >									
	//        < 1E-018 limites [ 292366457,709014 ; 333609481,239023 ] >									
	//        < 0x00000000000000000000000000000000000000000000006CEA3D17E7C477AD8F >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 11 &#224; 20									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     < RE_Portfolio_IX_metadata_line_11_____Coverys_Managing_Agency_Limited_20250515 >									
	//        < 96r29cfzPjb5s9v0PkeC4z5v7TnwTkifXM89Q3oS629vZrLIfPKS77PwuURiq08Z >									
	//        < 1E-018 limites [ 333609481,239023 ; 374945539,340977 ] >									
	//        < 0x00000000000000000000000000000000000000000000007C477AD8F8BAD97F42 >									
	//     < RE_Portfolio_IX_metadata_line_12_____Coverys_Managing_Agency_Limited_20250515 >									
	//        < Qa0HEbtO36xd8Qw28BNao0CZ4g8GEF82pNVV25Zai5T0MR7rUwdSjqlV9q37io38 >									
	//        < 1E-018 limites [ 374945539,340977 ; 409790344,441723 ] >									
	//        < 0x00000000000000000000000000000000000000000000008BAD97F4298A8A7340 >									
	//     < RE_Portfolio_IX_metadata_line_13_____Credit_Guarantee_20250515 >									
	//        < SYiYy9QxAzh3Q7IV690025M212MFH8ViKh903dAX3b372B73HqmKZC4l35wlvBgr >									
	//        < 1E-018 limites [ 409790344,441723 ; 438481185,387929 ] >									
	//        < 0x000000000000000000000000000000000000000000000098A8A7340A358D32FE >									
	//     < RE_Portfolio_IX_metadata_line_14_____Delta_Lloyd_Schadeverzekerina_NV_Am_20250515 >									
	//        < BhpUcI8eUPPRR2hEBds294RBDMy490H0Q9nwSQa14Xtoss5X0v0SZT21Pd6vlR9h >									
	//        < 1E-018 limites [ 438481185,387929 ; 454547146,537046 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A358D32FEA954FE911 >									
	//     < RE_Portfolio_IX_metadata_line_15_____Delvag_LuftfahrtversicherungsmAG_m_A_20250515 >									
	//        < 14hRl8NO9FIrnH1TDzSlJ937Rw9qRD18111TI49wrNpX2y4wNhsy6Jk91m5qMVxd >									
	//        < 1E-018 limites [ 454547146,537046 ; 478104850,249938 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A954FE911B21BA1D14 >									
	//     < RE_Portfolio_IX_metadata_line_16_____Deutsche_Rueckversicherung_20250515 >									
	//        < 4ABE2v2nz3VVQyKOET13L242t26K05059UnMQ9690m818bq6my8cKkesDb8unKUb >									
	//        < 1E-018 limites [ 478104850,249938 ; 521879887,120306 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B21BA1D14C26A584DC >									
	//     < RE_Portfolio_IX_metadata_line_17_____DEVK_Deutche_Ap_m_20250515 >									
	//        < v8wDs2NzZ6xODg1L94J3HvBQt31N8g9akEw13WLnO7LD86ljh1rRL6ReE83X5DX4 >									
	//        < 1E-018 limites [ 521879887,120306 ; 545797069,567282 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C26A584DCCB5343E40 >									
	//     < RE_Portfolio_IX_metadata_line_18_____Devonshire_Group_20250515 >									
	//        < wymO39mF2D9fizJkw7xT157Md4P251syJ881i0B35q36wfpG9QJid0391exT74Ls >									
	//        < 1E-018 limites [ 545797069,567282 ; 612010223,580769 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CB5343E40E3FDD7F8A >									
	//     < RE_Portfolio_IX_metadata_line_19_____Doha_insurance_CO_QSC_Am_Am_20250515 >									
	//        < tyF22LGce9p727e394xBTeGGKq6GXK5BKiIiE0MO349Qt79AxTG6waPH8BqyxiqK >									
	//        < 1E-018 limites [ 612010223,580769 ; 672065865,298308 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E3FDD7F8AFA5D32295 >									
	//     < RE_Portfolio_IX_metadata_line_20_____Dongbu_Insurance_Co_Limited_Am_20250515 >									
	//        < rz53f3ly6p3ZP0ya2vQyx2LuHZVmQTjdH1s0v6K15e3VGX6bU7lH405mqA5W0rXm >									
	//        < 1E-018 limites [ 672065865,298308 ; 748241209,849411 ] >									
	//        < 0x000000000000000000000000000000000000000000000FA5D32295116BDD7C8C >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 21 &#224; 30									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     < RE_Portfolio_IX_metadata_line_21_____Dorinco_Reinsurance_Company_20250515 >									
	//        < 13W17RUGn435IxW078dy8Y5TQ9e5nmwMG269OaEzX4QhI4X80izuT35iuE29B4Sd >									
	//        < 1E-018 limites [ 748241209,849411 ; 817808730,727887 ] >									
	//        < 0x00000000000000000000000000000000000000000000116BDD7C8C130A851964 >									
	//     < RE_Portfolio_IX_metadata_line_22_____Ecclesiastical_Insurance_Office_PLC_Am_A_20250515 >									
	//        < 59sNGCHMpZdLGti6D852440ivcBdQN0oVK8eqZlkL5ZTLDljK091ZOnyF5I4k6bW >									
	//        < 1E-018 limites [ 817808730,727887 ; 833829771,722031 ] >									
	//        < 0x00000000000000000000000000000000000000000000130A851964136A034488 >									
	//     < RE_Portfolio_IX_metadata_line_23_____Echo_Rueckversicherungs_m_AG__Echo_Re__Am_20250515 >									
	//        < lsg5Zfdk4o0VVgQRcBX3771t1m8BqUO5a3irHKsoUq6afZevL1HEgfQ0Jrx6whS3 >									
	//        < 1E-018 limites [ 833829771,722031 ; 857703894,624017 ] >									
	//        < 0x00000000000000000000000000000000000000000000136A03448813F85049CA >									
	//     < RE_Portfolio_IX_metadata_line_24_____Emirates_Ins_Co__PSC__Am_20250515 >									
	//        < J7zT5NN3v2j08EsUY7sRw5I0sq1e7o2k6J53a78g42D0mQ7NT4ovxKKbxms5ytl3 >									
	//        < 1E-018 limites [ 857703894,624017 ; 927407740,383387 ] >									
	//        < 0x0000000000000000000000000000000000000000000013F85049CA1597C7EA8A >									
	//     < RE_Portfolio_IX_metadata_line_25_____Emirates_Retakaful_limited_Bpp_20250515 >									
	//        < 0Y0kTso43otg59rq0G498a5fUksL866fI5OsRpbV1eIyu30L2a5cRM025uiel7YA >									
	//        < 1E-018 limites [ 927407740,383387 ; 939222985,153632 ] >									
	//        < 0x000000000000000000000000000000000000000000001597C7EA8A15DE348C87 >									
	//     < RE_Portfolio_IX_metadata_line_26_____Endurance_at_Lloyd_s_Limited_20250515 >									
	//        < pZwY7WmF4KNMs7x1CItuox4cDSf84eVARbAXiJxbQI2scSL35b8V0EH7sitkEp0E >									
	//        < 1E-018 limites [ 939222985,153632 ; 978807189,240854 ] >									
	//        < 0x0000000000000000000000000000000000000000000015DE348C8716CA254040 >									
	//     < RE_Portfolio_IX_metadata_line_27_____Endurance_at_Lloyd_s_Limited_20250515 >									
	//        < A8F7EHKo20un388VWu898Y0RF0P40o9hQBb93MM61LoIHBC5Z1RUQpTp0gCNIF3G >									
	//        < 1E-018 limites [ 978807189,240854 ; 999684565,540226 ] >									
	//        < 0x0000000000000000000000000000000000000000000016CA254040174695995E >									
	//     < RE_Portfolio_IX_metadata_line_28_____Endurance_at_Lloyd_s_Limited_20250515 >									
	//        < 0K1fjU734A8WEJ3H3xs6B41685523757JeIdJgCRBb2Rzelt052Q84j9a8OkxtOS >									
	//        < 1E-018 limites [ 999684565,540226 ; 1045088529,15821 ] >									
	//        < 0x00000000000000000000000000000000000000000000174695995E1855368CA7 >									
	//     < RE_Portfolio_IX_metadata_line_29_____Endurance_Specialty_Holdings_Limited_20250515 >									
	//        < 6Lj195g0n3Ow8kLKu0KV3UD136Q61mYaW33QO73pPUrbghDtKaA212sJ40o9sI9L >									
	//        < 1E-018 limites [ 1045088529,15821 ; 1084699261,5999 ] >									
	//        < 0x000000000000000000000000000000000000000000001855368CA719414FBB03 >									
	//     < RE_Portfolio_IX_metadata_line_30_____Endurance_Specialty_Holdings_Limited_20250515 >									
	//        < 4bA5O0DK4Wh0ZNka0qv3f36wY6Qo789g8ZhkGoGmO0LiD5EO8120g7G5707v77p0 >									
	//        < 1E-018 limites [ 1084699261,5999 ; 1123329642,39898 ] >									
	//        < 0x0000000000000000000000000000000000000000000019414FBB031A27910383 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 31 &#224; 40									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     < RE_Portfolio_IX_metadata_line_31_____Endurance_Specialty_Holdings_Limited_20250515 >									
	//        < F510Gx7m9VNvRJBOX547ZvTKpB3kcyRAcpm1k1Q9JPHVDBGN7PmSO906Yn973jYc >									
	//        < 1E-018 limites [ 1123329642,39898 ; 1176216062,36013 ] >									
	//        < 0x000000000000000000000000000000000000000000001A279103831B62CB4950 >									
	//     < RE_Portfolio_IX_metadata_line_32_____Endurance_Specialty_Insurance_Limited__Montpelier_Reinsurance_Limited__A_A_20250515 >									
	//        < 5iromV0pBYZe98vgY56xWyS99ulp46f94wYk12vnB9c7PfgbT2KIP1Xt6j1m3f5e >									
	//        < 1E-018 limites [ 1176216062,36013 ; 1212196789,15603 ] >									
	//        < 0x000000000000000000000000000000000000000000001B62CB49501C394184B7 >									
	//     < RE_Portfolio_IX_metadata_line_33_____Eni_Insurance_Limited_A_20250515 >									
	//        < 91jxwPQ8H2Nd8MYF14DB3847igk1y64yOlGIxpJ4T7uU9s88RKdzM2XC4RO0mJ27 >									
	//        < 1E-018 limites [ 1212196789,15603 ; 1225897192,68736 ] >									
	//        < 0x000000000000000000000000000000000000000000001C394184B71C8AEAACD8 >									
	//     < RE_Portfolio_IX_metadata_line_34_____Enterprise_Reinsurance_20250515 >									
	//        < Fhiw2tJHuF3SJF0wEXS22Y2QzHICwP36U61vZCV2rFFzh6Wwn8g0Pi282KYp5Z6d >									
	//        < 1E-018 limites [ 1225897192,68736 ; 1244307994,52385 ] >									
	//        < 0x000000000000000000000000000000000000000000001C8AEAACD81CF8A75450 >									
	//     < RE_Portfolio_IX_metadata_line_35_____Equator_Reinsurances_Limited_Ap_20250515 >									
	//        < 7230XL5dcdUmmd2p19r73yA655TNfsz8C9T94W721sxhqc2p5FrlB5EPD39t271K >									
	//        < 1E-018 limites [ 1244307994,52385 ; 1283064101,15244 ] >									
	//        < 0x000000000000000000000000000000000000000000001CF8A754501DDFA87477 >									
	//     < RE_Portfolio_IX_metadata_line_36_____Equity_Syndicate_Management_Limited_20250515 >									
	//        < 0BG6pRvAV4F7EFVK1kvvjXi3T0djw5S9F8kWwM9TIaq34L43u56rx95lkUMpEZ90 >									
	//        < 1E-018 limites [ 1283064101,15244 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001DDFA874771E8D4BCDCE >									
	//     < RE_Portfolio_IX_metadata_line_37_____ERS_Syndicate_Management_Limited_20250515 >									
	//        < 3G8tQWhisWj6PTYym9fbzi7p0N46JpcQ8d9Fi7Ptc37FG3sI81659T39q0mHpb5R >									
	//        < 1E-018 limites [ 1312195737,22211 ; 1330508826,2292 ] >									
	//        < 0x000000000000000000000000000000000000000000001E8D4BCDCE1EFA735C32 >									
	//     < RE_Portfolio_IX_metadata_line_38_____ERS_Syndicate_Management_Limited_20250515 >									
	//        < 5F7bN446VBrp46aSb9sVhjcb58SJj815Kb4gjqH59t17uK8he42ZdegTW0pn57a9 >									
	//        < 1E-018 limites [ 1330508826,2292 ; 1372864750,2701 ] >									
	//        < 0x000000000000000000000000000000000000000000001EFA735C321FF6E95F07 >									
	//     < RE_Portfolio_IX_metadata_line_39_____ERS_Syndicate_Management_Limited_20250515 >									
	//        < 9yaSaA7h7cn3Qkd31qBke6Qv76m65xH2chLViy586WMTJfLxW0svsWMaco9ahljr >									
	//        < 1E-018 limites [ 1372864750,2701 ; 1392217700,90178 ] >									
	//        < 0x000000000000000000000000000000000000000000001FF6E95F07206A43A15E >									
	//     < RE_Portfolio_IX_metadata_line_40_____Euler_Hermes_Reinsurance_AG_AAm_m_20250515 >									
	//        < UIry0a7US3zbBvfL1639YTtQq6255ghkwLc7u8270BgvERu0VjSe3pzMlbw5iN0t >									
	//        < 1E-018 limites [ 1392217700,90178 ; 1404357449,53134 ] >									
	//        < 0x00000000000000000000000000000000000000000000206A43A15E20B29F6AAD >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}