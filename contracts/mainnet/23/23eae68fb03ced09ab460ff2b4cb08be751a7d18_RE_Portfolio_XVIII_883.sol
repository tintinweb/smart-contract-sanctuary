pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_XVIII_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_XVIII_883		"	;
		string	public		symbol =	"	RE883XVIII		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1495671977653760000000000000					;	
										
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
	//     < RE_Portfolio_XVIII_metadata_line_1_____Sirius_Inter_Ins_Corp_Am_A_20250515 >									
	//        < x3YHV01gIBOYqOL7yCZ3hT5Bs7oaarKDn1D27zFD6buyjFD05LP01y0uDr605laY >									
	//        < 1E-018 limites [ 1E-018 ; 37910689,45243 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000E1F72105 >									
	//     < RE_Portfolio_XVIII_metadata_line_2_____Sirius_International_20250515 >									
	//        < Er4o4nq0k411bzblCxrYgXs6TW4A8279b8tNZEH7jwGUp1h4Kp85el0drWPogfeO >									
	//        < 1E-018 limites [ 37910689,45243 ; 113948388,745289 ] >									
	//        < 0x00000000000000000000000000000000000000000000000E1F721052A72F734E >									
	//     < RE_Portfolio_XVIII_metadata_line_3_____Sirius_International_Managing_Agency_Limited_20250515 >									
	//        < Qr32qWo8P8c599351UA7ahlePyufMPl5HaKJQsoa2DYlu5ro5S1o8KMOB060CCd5 >									
	//        < 1E-018 limites [ 113948388,745289 ; 135618188,328164 ] >									
	//        < 0x00000000000000000000000000000000000000000000002A72F734E32858F0C4 >									
	//     < RE_Portfolio_XVIII_metadata_line_4_____Sirius_International_Managing_Agency_Limited_20250515 >									
	//        < DA7A1IbV77F4z9wTGE2y6a36G9Rw3OH3V8hCx1MWoyZ5LSK3fhQIK369jTTMZPyz >									
	//        < 1E-018 limites [ 135618188,328164 ; 165055861,16124 ] >									
	//        < 0x000000000000000000000000000000000000000000000032858F0C43D7CF43B8 >									
	//     < RE_Portfolio_XVIII_metadata_line_5_____SOGECAP_SA_Am_m_20250515 >									
	//        < SBU9mONsdr6KYN496VBPM3Iexa9win38hCwX9JoXuCPA1bTj11Uvs8u1Ow6Zfp1H >									
	//        < 1E-018 limites [ 165055861,16124 ; 181190672,278281 ] >									
	//        < 0x00000000000000000000000000000000000000000000003D7CF43B8437FB084F >									
	//     < RE_Portfolio_XVIII_metadata_line_6_____SOMPO_Japan_Insurance_Co_Ap_Ap_20250515 >									
	//        < RULv3YQ4EJQbk10C5tN1kjM7sj1aX66TU8D61zA1DXBRNpdHY42nUK2OawuaktY5 >									
	//        < 1E-018 limites [ 181190672,278281 ; 226276836,731109 ] >									
	//        < 0x0000000000000000000000000000000000000000000000437FB084F544B70F4D >									
	//     < RE_Portfolio_XVIII_metadata_line_7_____Sompo_Japan_Nipponkoa_20250515 >									
	//        < FiKh79CcGI1277p5TR7J23LiV7S87V28Uak5uWei8111aJQ6L03nN62aN0A4zv3R >									
	//        < 1E-018 limites [ 226276836,731109 ; 267738596,903903 ] >									
	//        < 0x0000000000000000000000000000000000000000000000544B70F4D63BD8AF5E >									
	//     < RE_Portfolio_XVIII_metadata_line_8_____South_Africa_BBBp_Santam_Limited_BBB_m_20250515 >									
	//        < uw86OWJJdPDNLB8uR84Qd52a2kYrSwD0fyf2ZxcYRXe7kNGSwA875tL7dnh0vsH3 >									
	//        < 1E-018 limites [ 267738596,903903 ; 302480770,305557 ] >									
	//        < 0x000000000000000000000000000000000000000000000063BD8AF5E70AED08DA >									
	//     < RE_Portfolio_XVIII_metadata_line_9_____Southern_Africa_Reinsurance_Company_20250515 >									
	//        < nMGnVQO9qZ346u7s76a2b2S7jy6U2snK0mFO96B649wolI371VOHc3c1acd16EqB >									
	//        < 1E-018 limites [ 302480770,305557 ; 317702125,065442 ] >									
	//        < 0x000000000000000000000000000000000000000000000070AED08DA765A6FA8E >									
	//     < RE_Portfolio_XVIII_metadata_line_10_____Spain_BBBp_Mapfre_Global_Risks_compania_Intenacional_de_Sguros_y_Reasegrous_SA_A_20250515 >									
	//        < o02SNKt5D9mxm08XPysX3s0B8kSqw15F8W2Kps077Wt81Fri38EJuIx67dTEDZF3 >									
	//        < 1E-018 limites [ 317702125,065442 ; 329967803,57596 ] >									
	//        < 0x0000000000000000000000000000000000000000000000765A6FA8E7AEC2EB39 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XVIII_metadata_line_11_____Sportscover_Underwriting_Limited_20250515 >									
	//        < PBdNZ1vn6gQ5161zX6Y6l5DyPUzyq31Oue707ERnmQg9m42L3JUVyncbJwCY18R0 >									
	//        < 1E-018 limites [ 329967803,57596 ; 399633261,510476 ] >									
	//        < 0x00000000000000000000000000000000000000000000007AEC2EB3994DFFF8BB >									
	//     < RE_Portfolio_XVIII_metadata_line_12_____SRI_Re_20250515 >									
	//        < PUPj7FKoM03MeLUR54b7WrsZB5N0Wdz93L251vJYvK6pbM5QNs059RBS61ZR1M5G >									
	//        < 1E-018 limites [ 399633261,510476 ; 461878143,987474 ] >									
	//        < 0x000000000000000000000000000000000000000000000094DFFF8BBAC1021FF2 >									
	//     < RE_Portfolio_XVIII_metadata_line_13_____St_Paul_Re_20250515 >									
	//        < fnKqub201HEiX08Yg27ABAHLPy7DbTTSsIW3hV5FRCDy1H8xWqC4laWb6mXBVCfN >									
	//        < 1E-018 limites [ 461878143,987474 ; 523082850,302061 ] >									
	//        < 0x0000000000000000000000000000000000000000000000AC1021FF2C2DD1185A >									
	//     < RE_Portfolio_XVIII_metadata_line_14_____Starr_Insurance_&_Reinsurance_Limited_A_20250515 >									
	//        < 055tX480nd3dSJfejO171qruCefE51cl7wLk2d35CnW1c1iNI4ap9bMk5Q3thQrI >									
	//        < 1E-018 limites [ 523082850,302061 ; 580265369,388946 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C2DD1185AD82A6B1DE >									
	//     < RE_Portfolio_XVIII_metadata_line_15_____Starr_International__Europe__Limited_A_20250515 >									
	//        < kRm0CnfDkL2e47WVMT39ciIdo5R8Z97t60NTCLi4Ds33VykE6PpoJX3WXW75nT82 >									
	//        < 1E-018 limites [ 580265369,388946 ; 611419061,594167 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D82A6B1DEE3C5774E3 >									
	//     < RE_Portfolio_XVIII_metadata_line_16_____Starr_Managing_Agents_Limited_20250515 >									
	//        < Mkz7u0ow7Yl12c71EUYj6oH49kT66A8T0X8sO1t744uR60674t5WeIIIUsh81Tt5 >									
	//        < 1E-018 limites [ 611419061,594167 ; 622175064,534208 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E3C5774E3E7C73D089 >									
	//     < RE_Portfolio_XVIII_metadata_line_17_____Starr_Managing_Agents_Limited_20250515 >									
	//        < 7c8RmV2vh43343R2B0h4o3gmvamdmWmO7dNvw9iZ655wKh8N04Zp4O0nutK3nIq9 >									
	//        < 1E-018 limites [ 622175064,534208 ; 679312081,833849 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E7C73D089FD103FBEB >									
	//     < RE_Portfolio_XVIII_metadata_line_18_____Starr_Managing_Agents_Limited_20250515 >									
	//        < CT5oX902n9kiM1L5H81a56zga1w2veOHri7tpcJA0dJ20A3pCHi2d1M5XN9x738a >									
	//        < 1E-018 limites [ 679312081,833849 ; 704322804,550256 ] >									
	//        < 0x000000000000000000000000000000000000000000000FD103FBEB106617517B >									
	//     < RE_Portfolio_XVIII_metadata_line_19_____StarStone_Insurance_plc_m_Am_20250515 >									
	//        < 933TNR6I6gw46Twi44QQlOw9563B3E4JkwHkFmoNcz2e6zyr9BQfTSK8A47U8k8P >									
	//        < 1E-018 limites [ 704322804,550256 ; 753058495,702459 ] >									
	//        < 0x00000000000000000000000000000000000000000000106617517B11889414D6 >									
	//     < RE_Portfolio_XVIII_metadata_line_20_____StarStone_Underwriting_Limited_20250515 >									
	//        < 7s66QO6LEEfFB7NSL6A9H4n38dzra73f98H4G24fq1w956705rJ2W3b3J38YRAbW >									
	//        < 1E-018 limites [ 753058495,702459 ; 775779365,801598 ] >									
	//        < 0x0000000000000000000000000000000000000000000011889414D612100160B8 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XVIII_metadata_line_21_____StarStone_Underwriting_Limited_20250515 >									
	//        < 8Qx54GTs45K1kpIjYgO554MmsM8g22NI3U53yst5Z42568qCN4TOhDX9v0i6KNRS >									
	//        < 1E-018 limites [ 775779365,801598 ; 787779047,752426 ] >									
	//        < 0x0000000000000000000000000000000000000000000012100160B8125787707B >									
	//     < RE_Portfolio_XVIII_metadata_line_22_____StarStone_Underwriting_Limited_20250515 >									
	//        < i7FMT47fDo9SU6KPOAQQ4ziop57UM5xlNl7367O9G1qyiIGDL9R5Ez12xnfzIT1p >									
	//        < 1E-018 limites [ 787779047,752426 ; 844006867,846166 ] >									
	//        < 0x00000000000000000000000000000000000000000000125787707B13A6AC48B4 >									
	//     < RE_Portfolio_XVIII_metadata_line_23_____StarStone_Underwriting_Limited_20250515 >									
	//        < KTBrqZ5QJz5z2XFVX95I52GU3RG841s2393PnOjbZDldq7nX2cqiCCu3673j0PBo >									
	//        < 1E-018 limites [ 844006867,846166 ; 879149537,223673 ] >									
	//        < 0x0000000000000000000000000000000000000000000013A6AC48B4147823BDEE >									
	//     < RE_Portfolio_XVIII_metadata_line_24_____State_Automobile_Mutual_Ins_Co_m_Am_20250515 >									
	//        < E0qUajzC4rvAtVcRy7YuDLP3y23679uq59oy930w9x454WHXd76LL1w5jFy1e4tP >									
	//        < 1E-018 limites [ 879149537,223673 ; 897116485,555558 ] >									
	//        < 0x00000000000000000000000000000000000000000000147823BDEE14E33B211F >									
	//     < RE_Portfolio_XVIII_metadata_line_25_____Stockton_Reinsurance_20250515 >									
	//        < V856NZHHneT58tC2Jb5h3lTVw371Zi8klzgVyiTvDeUlvJmcBEs64Uc5t7iq0q39 >									
	//        < 1E-018 limites [ 897116485,555558 ; 917000848,3652 ] >									
	//        < 0x0000000000000000000000000000000000000000000014E33B211F1559C04258 >									
	//     < RE_Portfolio_XVIII_metadata_line_26_____Stop_Loss_Finders_20250515 >									
	//        < C046yg57HOMk37030k1BYu2n6B93F5OqhFu3CJ40ynimIy3udtbejW4251O53xvf >									
	//        < 1E-018 limites [ 917000848,3652 ; 961703331,68288 ] >									
	//        < 0x000000000000000000000000000000000000000000001559C04258166432D5E4 >									
	//     < RE_Portfolio_XVIII_metadata_line_27_____Summit_Reinsurance_Services_20250515 >									
	//        < 8As8OcNS98A3Lfb9Iql4xNZV60cWNA40j2myW55zY3e1Kj73sIglsCdBDR4dEX1n >									
	//        < 1E-018 limites [ 961703331,68288 ; 974606073,355426 ] >									
	//        < 0x00000000000000000000000000000000000000000000166432D5E416B11ADB5B >									
	//     < RE_Portfolio_XVIII_metadata_line_28_____Sun_Life_Financial_Incorporated_20250515 >									
	//        < dwfNay7Ra20n4m8MXU2fPexHZ2Ot7S1tZiUkeGpX45z31xh20u6ID71uABDpVi88 >									
	//        < 1E-018 limites [ 974606073,355426 ; 1038952670,95378 ] >									
	//        < 0x0000000000000000000000000000000000000000000016B11ADB5B1830A3F90B >									
	//     < RE_Portfolio_XVIII_metadata_line_29_____Swiss_Re_20250515 >									
	//        < 2LspTGa2z97fIdsiYlhOb82g87T8hrqr4w6QlnJNJnnlBh5UGl3LUnb14S43vg41 >									
	//        < 1E-018 limites [ 1038952670,95378 ; 1067987755,07711 ] >									
	//        < 0x000000000000000000000000000000000000000000001830A3F90B18DDB3FEC7 >									
	//     < RE_Portfolio_XVIII_metadata_line_30_____Swiss_Re_Co_AAm_Ap_20250515 >									
	//        < N4tKM74LRTt8607x68Tn66JW7y2ANLtMF8UsuoRCicHAjQzT9ToyeD775JnGd68c >									
	//        < 1E-018 limites [ 1067987755,07711 ; 1106222537,81319 ] >									
	//        < 0x0000000000000000000000000000000000000000000018DDB3FEC719C199A4C9 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XVIII_metadata_line_31_____Swiss_Re_Group_20250515 >									
	//        < 30lm40EO14h66T7Y99y3jW1YM9rhkRxuLr1oj4B328jswAmq1RRLMt2Sy09KuVI2 >									
	//        < 1E-018 limites [ 1106222537,81319 ; 1179864061,50206 ] >									
	//        < 0x0000000000000000000000000000000000000000000019C199A4C91B7889B0FA >									
	//     < RE_Portfolio_XVIII_metadata_line_32_____Swiss_Re_Group_20250515 >									
	//        < IjL5R7Ldc0G5LGu536YM825UHhHcvGBOYDm28zvLW7n3ke2cM4gPkZShNP4001f7 >									
	//        < 1E-018 limites [ 1179864061,50206 ; 1226576738,58686 ] >									
	//        < 0x000000000000000000000000000000000000000000001B7889B0FA1C8EF79476 >									
	//     < RE_Portfolio_XVIII_metadata_line_33_____Swiss_Re_Limited_20250515 >									
	//        < 1p80mtmA3SddD63c9xJ629A99x2EB4gD6oA3E8qtuNblpq1Mw1YLV0CN4BeGCG8E >									
	//        < 1E-018 limites [ 1226576738,58686 ; 1241303333,83469 ] >									
	//        < 0x000000000000000000000000000000000000000000001C8EF794761CE6BE94BB >									
	//     < RE_Portfolio_XVIII_metadata_line_34_____Taiping_Reinsurance_20250515 >									
	//        < iLUfX8QD84zaOt5V6Lk5HAa0J5990MKSfJ842Kj8dRIj161470Vux4xi6FcutBSz >									
	//        < 1E-018 limites [ 1241303333,83469 ; 1301562260,12121 ] >									
	//        < 0x000000000000000000000000000000000000000000001CE6BE94BB1E4DEA67D0 >									
	//     < RE_Portfolio_XVIII_metadata_line_35_____Taiwan_AAm_Central_Reinsurance_Corporation_A_A_20250515 >									
	//        < JnlTwog2g5tKB6LLZZ8kND24Vem3XKGZ4D4B1oZwA39Ur66mQMDX5I24Luc43jX9 >									
	//        < 1E-018 limites [ 1301562260,12121 ; 1376866194,73293 ] >									
	//        < 0x000000000000000000000000000000000000000000001E4DEA67D0200EC31745 >									
	//     < RE_Portfolio_XVIII_metadata_line_36_____Taiwan_Central_Reinsurance_Corporation_20250515 >									
	//        < 3ie9c602O2LqFjg2v2T29ScHkfdM9l9JPgneE9VKB4A6E2Fkt2OilBKnCye26lXO >									
	//        < 1E-018 limites [ 1376866194,73293 ;  ] >									
	//        < 0x00000000000000000000000000000000000000000000200EC31745205D7C368D >									
	//     < RE_Portfolio_XVIII_metadata_line_37_____Takaful_Re_20250515 >									
	//        < H4dkX5DcSl0tRuPJxVq4VzvExo3b0ZWQfLnB8R93Zmq8818OP2qOziDHvT39b09P >									
	//        < 1E-018 limites [ 1390073744,89508 ; 1422842159,52193 ] >									
	//        < 0x00000000000000000000000000000000000000000000205D7C368D2120CCD884 >									
	//     < RE_Portfolio_XVIII_metadata_line_38_____Takaful_Re_BBB_20250515 >									
	//        < wkPz4A6Qo4489u4nD8MwIHmeZkv52DI1M468Cd7Tte25vl75R76ppRa3IdbHvLvB >									
	//        < 1E-018 limites [ 1422842159,52193 ; 1436353877,40291 ] >									
	//        < 0x000000000000000000000000000000000000000000002120CCD8842171561750 >									
	//     < RE_Portfolio_XVIII_metadata_line_39_____Talbot_Underwriting_Limited_20250515 >									
	//        < 8K36CEZqV6LjSgS5FV0n5E3eoX80HHoMd0ZKkZOjZ2U3cRPQb47q9vML67KWCd8Q >									
	//        < 1E-018 limites [ 1436353877,40291 ; 1480239919,72621 ] >									
	//        < 0x0000000000000000000000000000000000000000000021715617502276EAE098 >									
	//     < RE_Portfolio_XVIII_metadata_line_40_____Talbot_Underwriting_Limited_20250515 >									
	//        < mjdquvnO4if5e9yynCHzgh2J48PoWVdCG6319q9fIhV7Ht74tfWk108d27CdeSHb >									
	//        < 1E-018 limites [ 1480239919,72621 ; 1495671977,65376 ] >									
	//        < 0x000000000000000000000000000000000000000000002276EAE09822D2E65439 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}