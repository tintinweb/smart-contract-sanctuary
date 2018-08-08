pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_VIII_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_VIII_883		"	;
		string	public		symbol =	"	RE883VIII		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1334895047129150000000000000					;	
										
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
	//     < RE_Portfolio_VIII_metadata_line_1_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < DwsY2Zat60K6EY21sL1Sc1YYAZ9bCp2Jhqlbg9q3ig4W6TeFql9jCj6CDZI6LbM6 >									
	//        < 1E-018 limites [ 1E-018 ; 15784204,1437922 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000005E14CAB2 >									
	//     < RE_Portfolio_VIII_metadata_line_2_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < x7clmy7EonD03kvLwyS9g6bvZ4HnuGT9a00aCG0X2J7gthTWt9Jue07GL0xLK3w4 >									
	//        < 1E-018 limites [ 15784204,1437922 ; 38528572,5428022 ] >									
	//        < 0x0000000000000000000000000000000000000000000000005E14CAB2E5A5F19A >									
	//     < RE_Portfolio_VIII_metadata_line_3_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < 9XWXaia77GxMP3Jtx7rZ77QQQvPoDllA4bQiKmf2wzl4t2CLgX471yH1nFNR3ECN >									
	//        < 1E-018 limites [ 38528572,5428022 ; 103214545,262743 ] >									
	//        < 0x00000000000000000000000000000000000000000000000E5A5F19A26734E7B2 >									
	//     < RE_Portfolio_VIII_metadata_line_4_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < h6827RAED121x4kdEr0Zre9m7a781n0PBJkd7JNBQ39yYTUv9ff54vOD5sO33OH1 >									
	//        < 1E-018 limites [ 103214545,262743 ; 121686096,439178 ] >									
	//        < 0x000000000000000000000000000000000000000000000026734E7B22D54E415F >									
	//     < RE_Portfolio_VIII_metadata_line_5_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < 2pfuGTNSwA9wiz5nqACCwRjb3E0gvJ1pr7EFN1YF50V0hwdYyJ4gl583Kk9S502h >									
	//        < 1E-018 limites [ 121686096,439178 ; 133828546,545525 ] >									
	//        < 0x00000000000000000000000000000000000000000000002D54E415F31DAE29F2 >									
	//     < RE_Portfolio_VIII_metadata_line_6_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < tXqc494GO641J1Ngk01EmH1Z6Qh0ooFISrfeuq9651fkR84fr8c7F4P6odU0970d >									
	//        < 1E-018 limites [ 133828546,545525 ; 185825172,955978 ] >									
	//        < 0x000000000000000000000000000000000000000000000031DAE29F24539AB823 >									
	//     < RE_Portfolio_VIII_metadata_line_7_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < e334m7cUf065aPL31G8Guo3O3NolwT85GNT51KVnQdFOAS6wK1320hzXr39e75VZ >									
	//        < 1E-018 limites [ 185825172,955978 ; 249414589,341309 ] >									
	//        < 0x00000000000000000000000000000000000000000000004539AB8235CEA077EA >									
	//     < RE_Portfolio_VIII_metadata_line_8_____Catlin_Underwriting_Agencies_Limited&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;_20250515 >									
	//        < 65cAfv8ejy9qLmhbvDX3P7a6T6hg34bz5cXFn2GxR00O881Bv0pc0V70SqWXg39k >									
	//        < 1E-018 limites [ 249414589,341309 ; 266238811,477905 ] >									
	//        < 0x00000000000000000000000000000000000000000000005CEA077EA632E831AF >									
	//     < RE_Portfolio_VIII_metadata_line_9_____CCR_FAPDS_Fonds_de_Garantie_des_Dommages_Consecutifs_a_des_Actes_de_Prevention_de_Diagnostic_ou_de_Soins_Dispens&#233;s_par_des_Professionnels_de_Sant&#233;_20250515 >									
	//        < 0u1340UEGCOez129Bh43U1LZsuMDw2RCTB01sI9ZtzLNkXXdUT0D4yf6nF65FOlz >									
	//        < 1E-018 limites [ 266238811,477905 ; 296412783,871162 ] >									
	//        < 0x0000000000000000000000000000000000000000000000632E831AF6E6C205A7 >									
	//     < RE_Portfolio_VIII_metadata_line_10_____CCR_FCAC_Fonds_de_Compensation_des_Risques_de_l_Assurance_de_la_Construction_20250515 >									
	//        < rbH3kPGp9k8I84dWpxtx8X6S0bt9eJFq1S1Zg0rdg34rS1NmDtVX2K4LlXVRh6me >									
	//        < 1E-018 limites [ 296412783,871162 ; 338755612,615921 ] >									
	//        < 0x00000000000000000000000000000000000000000000006E6C205A77E3240D21 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VIII_metadata_line_11_____CCR_FGRE_Fonds_de_Garantie_des_Risques_li&#233;s_a_l_Epandage_des_Boues_d_Epuration_Urbaines_et_Industrielles_20250515 >									
	//        < Y40PRI9548l36O7N1p3N5y5xswtcp72RUJv35U4F7Kl2NCHY54sUH90v9m82t180 >									
	//        < 1E-018 limites [ 338755612,615921 ; 399891284,160556 ] >									
	//        < 0x00000000000000000000000000000000000000000000007E3240D2194F89AED4 >									
	//     < RE_Portfolio_VIII_metadata_line_12_____CCR_FNGRA_Fonds_National_de_Gestion_des_Risques_en_Agriculture_20250515 >									
	//        < 8d1t778Z2r256wO7382Za76eBoJ2yKl4eW8kWBC72IeGDvFbQsO58Y28qnVz26HX >									
	//        < 1E-018 limites [ 399891284,160556 ; 413497818,725314 ] >									
	//        < 0x000000000000000000000000000000000000000000000094F89AED49A0A39B64 >									
	//     < RE_Portfolio_VIII_metadata_line_13_____CCR_FPRNM_Fonds_de_Pr&#233;vention_des_Risques_Naturels_Majeurs_20250515 >									
	//        < aEoShl27sl0OUWrYz6QW0r1bpj3LtEpzwwUZdp7I1O3dzfaGS4hn10ZII4B158kx >									
	//        < 1E-018 limites [ 413497818,725314 ; 426425303,820843 ] >									
	//        < 0x00000000000000000000000000000000000000000000009A0A39B649EDB16242 >									
	//     < RE_Portfolio_VIII_metadata_line_14_____Central_Reinsurance_Corporation_20250515 >									
	//        < gLkOFiY7d32cuj9327AVZg86C6hyobc0u26phBwM41fQ0LINUT72lq8q9FOLw5T7 >									
	//        < 1E-018 limites [ 426425303,820843 ; 464199621,318477 ] >									
	//        < 0x00000000000000000000000000000000000000000000009EDB16242ACED86B07 >									
	//     < RE_Portfolio_VIII_metadata_line_15_____Centre_Group_20250515 >									
	//        < nkwCvAjb34725DwWN25LkNP746oUKidMIFCFX6asys5Qk679oeRZV6m1UlYQO851 >									
	//        < 1E-018 limites [ 464199621,318477 ; 511363633,048014 ] >									
	//        < 0x0000000000000000000000000000000000000000000000ACED86B07BE7F6FD1C >									
	//     < RE_Portfolio_VIII_metadata_line_16_____Centre_Solutions_20250515 >									
	//        < XPPz06NLlkiVcX02RRq5wbwyES8QzNA2u4pCOY80p8Rj0Q4u904JTCMeTHW4s18W >									
	//        < 1E-018 limites [ 511363633,048014 ; 566886616,490547 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BE7F6FD1CD32E85685 >									
	//     < RE_Portfolio_VIII_metadata_line_17_____Charles_Taylor_Managing_Agency_Limited_20250515 >									
	//        < nD4m5v3jQurVfo1hELaEx4qp14y5FJViLa68732vpczM2gNrSHqL15g81dC8S7yV >									
	//        < 1E-018 limites [ 566886616,490547 ; 602550215,251437 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D32E85685E077AABC9 >									
	//     < RE_Portfolio_VIII_metadata_line_18_____Charles_Taylor_Managing_Agency_Limited_20250515 >									
	//        < L4Nes0d2gZ9e68lPb8Nqstw6fX2LJdX1I6RbNZW26BD03587b49U4yuB92Fmz71a >									
	//        < 1E-018 limites [ 602550215,251437 ; 652636130,551788 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E077AABC9F3203B673 >									
	//     < RE_Portfolio_VIII_metadata_line_19_____Chaucer_Syndicates_Limited_20250515 >									
	//        < tKM5ZPp6X59KyZb4X426gPqS775FLdjE8On5OjYB2SPWLwo1478HbFybZNxolRkt >									
	//        < 1E-018 limites [ 652636130,551788 ; 678849348,97191 ] >									
	//        < 0x0000000000000000000000000000000000000000000000F3203B673FCE41E8E5 >									
	//     < RE_Portfolio_VIII_metadata_line_20_____Chaucer_Syndicates_Limited_20250515 >									
	//        < 57R5eURn9maEpF3N74p7AmGxjbJXPUr98tpOs42wvlK9S1obG3L5vDfF5f6FfAhI >									
	//        < 1E-018 limites [ 678849348,97191 ; 701574017,294842 ] >									
	//        < 0x000000000000000000000000000000000000000000000FCE41E8E51055B50075 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VIII_metadata_line_21_____Chaucer_Syndicates_Limited_20250515 >									
	//        < n2f5E01AAOIfIv71CTlOH2DU1bYybCSbeiQrTDDONF7wkru9MxQDUE1u6T99V1BT >									
	//        < 1E-018 limites [ 701574017,294842 ; 730482441,221206 ] >									
	//        < 0x000000000000000000000000000000000000000000001055B50075110203C18E >									
	//     < RE_Portfolio_VIII_metadata_line_22_____Chaucer_Syndicates_Limited_20250515 >									
	//        < 25nca4pH7h0Tt69Gn5HE896Gg0gYZ3MNlt0U1J47O54J8AQXoYLM5GzALB5B1HNR >									
	//        < 1E-018 limites [ 730482441,221206 ; 750673148,679721 ] >									
	//        < 0x00000000000000000000000000000000000000000000110203C18E117A5C54A7 >									
	//     < RE_Portfolio_VIII_metadata_line_23_____Chaucer_Syndicates_Limited_20250515 >									
	//        < 5peIX0uRyOP2Fl6p4U22k92JIZiC2HAwO8WygfE6ejjDP6wmXn2D5T2Wu0Q2elcH >									
	//        < 1E-018 limites [ 750673148,679721 ; 831282229,815834 ] >									
	//        < 0x00000000000000000000000000000000000000000000117A5C54A7135AD406F9 >									
	//     < RE_Portfolio_VIII_metadata_line_24_____Chaucer_Syndicates_Limited_20250515 >									
	//        < 9Ht6d5AmmAnG8A2uLMZU3P9CpnM8i2XjXsS3pIwv5c89EMMJBBuM1nHipq55ggYb >									
	//        < 1E-018 limites [ 831282229,815834 ; 850160873,748592 ] >									
	//        < 0x00000000000000000000000000000000000000000000135AD406F913CB5A8D42 >									
	//     < RE_Portfolio_VIII_metadata_line_25_____Chaucer_Syndicates_Limited_20250515 >									
	//        < Tc41Ta6lRMLxR1jsz904pRgGh6032yim0F8jcrMdAMfMzy4oG1wg0Vsbr0Jy8J1Q >									
	//        < 1E-018 limites [ 850160873,748592 ; 889518017,239167 ] >									
	//        < 0x0000000000000000000000000000000000000000000013CB5A8D4214B5F0C96F >									
	//     < RE_Portfolio_VIII_metadata_line_26_____Chaucer_Syndicates_Limited_20250515 >									
	//        < bEKJI06p8n5Ox2mvGbTFg42JJIsJI5905ioX28uG6zip95NjxgDZ9jph9r6q1m41 >									
	//        < 1E-018 limites [ 889518017,239167 ; 915097501,202549 ] >									
	//        < 0x0000000000000000000000000000000000000000000014B5F0C96F154E67FB5C >									
	//     < RE_Portfolio_VIII_metadata_line_27_____Chaucer_Syndicates_Limited_20250515 >									
	//        < lVm3HOC87dmZS3XovB2FN12BG96UXezWBOo5l8kUv83lQ2Ywb80qr0c8bvMOAzOU >									
	//        < 1E-018 limites [ 915097501,202549 ; 962564383,484516 ] >									
	//        < 0x00000000000000000000000000000000000000000000154E67FB5C166954B240 >									
	//     < RE_Portfolio_VIII_metadata_line_28_____Chaucer_Syndicates_Limited_20250515 >									
	//        < 9mO0wqCb504nVm5iH7aJ9v7Qp3jbq3M7O8739B7VOLoOR3ODLjh0cqfPMk0HT3of >									
	//        < 1E-018 limites [ 962564383,484516 ; 994564964,837168 ] >									
	//        < 0x00000000000000000000000000000000000000000000166954B240172811B557 >									
	//     < RE_Portfolio_VIII_metadata_line_29_____Chaucer_Syndicates_Limited_20250515 >									
	//        < 8ydB9BLxhxTG6GZ41Lyj90xGdTZg3M71YLLI2mV6Ma2e017H0CnVUIKE1Wb1Ol20 >									
	//        < 1E-018 limites [ 994564964,837168 ; 1006177733,56803 ] >									
	//        < 0x00000000000000000000000000000000000000000000172811B557176D496320 >									
	//     < RE_Portfolio_VIII_metadata_line_30_____China_Reinsurance__Group__Corporation_Ap_A_20250515 >									
	//        < w3JvuP9OPI1ae2W10e1W37Ar0I90zs8vX2P83Z723K9CpMIc0Fdr7093krx73yvw >									
	//        < 1E-018 limites [ 1006177733,56803 ; 1056288029,9055 ] >									
	//        < 0x00000000000000000000000000000000000000000000176D4963201897F7A1A2 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VIII_metadata_line_31_____China_Reinsurance_Group_Corporation_20250515 >									
	//        < oNN995GFKnHex8BKs6110Ht38PY2hPW0yJI8CjyRDZa3ANu3clAB9I6zAE452X4r >									
	//        < 1E-018 limites [ 1056288029,9055 ; 1090013207,20052 ] >									
	//        < 0x000000000000000000000000000000000000000000001897F7A1A21960FC2B04 >									
	//     < RE_Portfolio_VIII_metadata_line_32_____Chubb_Insurance_Co_of_Europe_SE_AA_App_20250515 >									
	//        < 660x2R62AK5zgL95wD1pf3Ja5u35Gv5e6Eui1nVwO81i5b3N408m09WKuM63eGBK >									
	//        < 1E-018 limites [ 1090013207,20052 ; 1135599644,50709 ] >									
	//        < 0x000000000000000000000000000000000000000000001960FC2B041A70B38D16 >									
	//     < RE_Portfolio_VIII_metadata_line_33_____Chubb_Limited_20250515 >									
	//        < 6QaUT1GEb70La8e6H58Bdx30Auu32LgS4GUP2aPDBq10N02s0rZ9DjUnSc5rMGRm >									
	//        < 1E-018 limites [ 1135599644,50709 ; 1155381170,59916 ] >									
	//        < 0x000000000000000000000000000000000000000000001A70B38D161AE69BC3B7 >									
	//     < RE_Portfolio_VIII_metadata_line_34_____Chubb_Managing_Agency_Limited_20250515 >									
	//        < wb2AdYvaxppZqG1ZZML7Pwk6SZUj1576U1O3LeW56r3o53z3fqWr5U8MK14m9Gxc >									
	//        < 1E-018 limites [ 1155381170,59916 ; 1200519125,52471 ] >									
	//        < 0x000000000000000000000000000000000000000000001AE69BC3B71BF3A6D15C >									
	//     < RE_Portfolio_VIII_metadata_line_35_____Chubb_Underwriting_Agencies_Limited_20250515 >									
	//        < 517f2P64nKY8i52aP0Ex90N9L7y8RNG2pqAPE254e7jl60SIJw9cG9UWrlLbo7hk >									
	//        < 1E-018 limites [ 1200519125,52471 ; 1212422572,06786 ] >									
	//        < 0x000000000000000000000000000000000000000000001BF3A6D15C1C3A9A092A >									
	//     < RE_Portfolio_VIII_metadata_line_36_____Chubb_Underwriting_Agencies_Limited_20250515 >									
	//        < OrZsPDyC3BRF7JIhL0fF1V5CXz0dJQT6WCUFpMPjsJljTgsz5KyChVEChn0iC5YE >									
	//        < 1E-018 limites [ 1212422572,06786 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001C3A9A092A1C875427CC >									
	//     < RE_Portfolio_VIII_metadata_line_37_____CL_Frates_20250515 >									
	//        < 65sp19lgKP3Bvw3Ka20m2bM3u48DdIyqY246oPb6Eg1i65UkbQu2y59q2g95g8Am >									
	//        < 1E-018 limites [ 1225295231,60078 ; 1237446064,68879 ] >									
	//        < 0x000000000000000000000000000000000000000000001C875427CC1CCFC0DAF8 >									
	//     < RE_Portfolio_VIII_metadata_line_38_____CNA_Insurance_Co_Limited_A_m_20250515 >									
	//        < 4xf3g8Bmgsu5c7IOUo8jl90a75fXPpuoOcSS0WxtLjs3X5tIS9VNy24p6g44wg4o >									
	//        < 1E-018 limites [ 1237446064,68879 ; 1297845547,98672 ] >									
	//        < 0x000000000000000000000000000000000000000000001CCFC0DAF81E37C32722 >									
	//     < RE_Portfolio_VIII_metadata_line_39_____CNA_Re_20250515 >									
	//        < hT6NdF6dSyqfN2d81GTLBqy890Qwxtl830gtkUq9zfkqapqS49pv9LBX1S74UDf0 >									
	//        < 1E-018 limites [ 1297845547,98672 ; 1315824709,94854 ] >									
	//        < 0x000000000000000000000000000000000000000000001E37C327221EA2ED2D46 >									
	//     < RE_Portfolio_VIII_metadata_line_40_____CNA_Re_Smartfac_20250515 >									
	//        < XwjYBwkI0O943qcOUwq4y629t44P7apOCr9FSn2jF0mKiP7usfKiEjiHHPHK0V6d >									
	//        < 1E-018 limites [ 1315824709,94854 ; 1334895047,12915 ] >									
	//        < 0x000000000000000000000000000000000000000000001EA2ED2D461F149833BC >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}