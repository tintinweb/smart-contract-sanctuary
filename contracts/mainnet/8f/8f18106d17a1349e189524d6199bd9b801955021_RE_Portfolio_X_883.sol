pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_X_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_X_883		"	;
		string	public		symbol =	"	RE883X		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1724616534055050000000000000					;	
										
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
	//     < RE_Portfolio_X_metadata_line_1_____European_Reinsurance_Consultants_20250515 >									
	//        < D8v81h27FBSiRtPlNUVdolxTsvg4ncf8r2M34lMwYWEh286X5H0sH4mMd88cC0JA >									
	//        < 1E-018 limites [ 1E-018 ; 35205224,2350521 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000D1D6EAAB >									
	//     < RE_Portfolio_X_metadata_line_2_____Everest_National_Insurance_Co_Ap_Ap_20250515 >									
	//        < 7dMdUH7TN5u875a70BvW0rJwCv1zhkdpTrQtH3RUXHd0q9HYKmURM2caVGPy2jjh >									
	//        < 1E-018 limites [ 35205224,2350521 ; 98251222,5673903 ] >									
	//        < 0x00000000000000000000000000000000000000000000000D1D6EAAB2499F79C4 >									
	//     < RE_Portfolio_X_metadata_line_3_____Everest_Re_Group_20250515 >									
	//        < zVF0rYI70D7b0OZ2tojFJGC48T2J60L6hnLWuW71Jgu8jq5Fv9G6mTz6y1kvd44n >									
	//        < 1E-018 limites [ 98251222,5673903 ; 154556676,857003 ] >									
	//        < 0x00000000000000000000000000000000000000000000002499F79C43993AC7D9 >									
	//     < RE_Portfolio_X_metadata_line_4_____Everest_Re_Group_20250515 >									
	//        < rlKfySod6adx9adzH5n5Z6hQA599J1O77VIe50sS73qa4ua3Rdu6qy43vrXl8aa2 >									
	//        < 1E-018 limites [ 154556676,857003 ; 207287970,828712 ] >									
	//        < 0x00000000000000000000000000000000000000000000003993AC7D94D388598E >									
	//     < RE_Portfolio_X_metadata_line_5_____Everest_Re_Group_20250515 >									
	//        < uqVK1eBQilSmY2VV14N9Ms0tum5s45uC02850O18UToO2G7TOjj21N3zO8b25ij5 >									
	//        < 1E-018 limites [ 207287970,828712 ; 220688404,426694 ] >									
	//        < 0x00000000000000000000000000000000000000000000004D388598E52367C9EE >									
	//     < RE_Portfolio_X_metadata_line_6_____Everest_Re_Group_Limited_20250515 >									
	//        < n28srWQSUFTx3r0vWdoIE02pw9w7H8f02OCKNEPWe6BK86x09jobh6UT933Ji61m >									
	//        < 1E-018 limites [ 220688404,426694 ; 294655852,371998 ] >									
	//        < 0x000000000000000000000000000000000000000000000052367C9EE6DC492849 >									
	//     < RE_Portfolio_X_metadata_line_7_____Evergreen_Insurance_Company_Limited_m_A_20250515 >									
	//        < qob52coqYbYlaI70L3P2k4U5Rr3AGG7e36r2IrtsVXd7342497XUEY6V6821Xh3f >									
	//        < 1E-018 limites [ 294655852,371998 ; 354261799,826067 ] >									
	//        < 0x00000000000000000000000000000000000000000000006DC49284983F909D82 >									
	//     < RE_Portfolio_X_metadata_line_8_____Evergreen_Re_20250515 >									
	//        < VZKXtWFqx1zsJouVbp67WpICU0MAIjHBRW7i2437HM47HjFZ4SliEJ4Z02Hc565N >									
	//        < 1E-018 limites [ 354261799,826067 ; 378253365,098779 ] >									
	//        < 0x000000000000000000000000000000000000000000000083F909D828CE90D6B1 >									
	//     < RE_Portfolio_X_metadata_line_9_____EWI_Re_Intermediaries_and_Consultants_20250515 >									
	//        < bk1WAE4jxce00Cua4l2z9Fib0Xo1NokvEukEQrZ3UmT7VKpfzwDMfsN9vgwuzp70 >									
	//        < 1E-018 limites [ 378253365,098779 ; 456146448,873707 ] >									
	//        < 0x00000000000000000000000000000000000000000000008CE90D6B1A9ED8408B >									
	//     < RE_Portfolio_X_metadata_line_10_____Factory_Mutual_Insurance_Co_Ap_Ap_20250515 >									
	//        < LeCPC7IVqW6ivvM23iYzV800fXES92fdV5Ro5Ry2h28r7j0pyWCZ8b3vI7F5HfjV >									
	//        < 1E-018 limites [ 456146448,873707 ; 471398070,734583 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A9ED8408BAF9C06155 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_X_metadata_line_11_____Faraday_Underwriting_Limited_20250515 >									
	//        < 7py5tEh3TTSM3D511qSeMRPC62csW1LC5iI8s31vA9xL32861Y3XPXHNl6teScrL >									
	//        < 1E-018 limites [ 471398070,734583 ; 552066324,876761 ] >									
	//        < 0x0000000000000000000000000000000000000000000000AF9C06155CDA925E1B >									
	//     < RE_Portfolio_X_metadata_line_12_____Faraday_Underwriting_Limited_20250515 >									
	//        < Y6yqnZK075G96m9O12i52DpIc0v8W9jT77QDneVt74gO13Si4GX1yc4ccx1S583Y >									
	//        < 1E-018 limites [ 552066324,876761 ; 565449517,856386 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CDA925E1BD2A577FDD >									
	//     < RE_Portfolio_X_metadata_line_13_____Faraday_Underwriting_Limited_20250515 >									
	//        < 4uGick1mI3SyVF8dzqi27gwx7x0YlD546GXb563zKAl9enL859W0qO48a9U0SB26 >									
	//        < 1E-018 limites [ 565449517,856386 ; 639504901,630417 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D2A577FDDEE3BF0C27 >									
	//     < RE_Portfolio_X_metadata_line_14_____Faraday_Underwriting_Limited_20250515 >									
	//        < D8HgeA7KQzg8s1AHncyFky9nW6p4fi3DJGv8NHbT72fKVMQlk5Mwul9pmt6quAc1 >									
	//        < 1E-018 limites [ 639504901,630417 ; 715695508,049936 ] >									
	//        < 0x000000000000000000000000000000000000000000000EE3BF0C2710A9E0AFC8 >									
	//     < RE_Portfolio_X_metadata_line_15_____Fiduciary_Intermediary_20250515 >									
	//        < N1fu7Si68f14m7i6YLiSVQ97qz33861Fy04zi7nRGTP4mt87wi1K167Gr5b0kX74 >									
	//        < 1E-018 limites [ 715695508,049936 ; 743637461,618944 ] >									
	//        < 0x0000000000000000000000000000000000000000000010A9E0AFC811506CB965 >									
	//     < RE_Portfolio_X_metadata_line_16_____First_Capital_Insurance_Limited_A_20250515 >									
	//        < wCBWF7V08gp0mSoLL40cA1BVxgR2sCZLMx5dUxtq78Dg9wSc9PyWBJ0KECQLM2sm >									
	//        < 1E-018 limites [ 743637461,618944 ; 785991183,168893 ] >									
	//        < 0x0000000000000000000000000000000000000000000011506CB965124CDF5FE0 >									
	//     < RE_Portfolio_X_metadata_line_17_____Flagstone_Reinsurance_Holdings_Limited_20250515 >									
	//        < EdxgK3q0a8D23GYrTX0zPG9026O9HHQ37v1T2z3FX9wSXkK7ks2Xg8F9AWEoP81n >									
	//        < 1E-018 limites [ 785991183,168893 ; 846829386,163266 ] >									
	//        < 0x00000000000000000000000000000000000000000000124CDF5FE013B77F1AEC >									
	//     < RE_Portfolio_X_metadata_line_18_____FolksAmerica_Reinsurance_Company_20250515 >									
	//        < 87qV9kH2SsA408r95gSXjBrv84sAzHn82hfLujCOY8dn6xwh8WpK37S9lnr9V3Er >									
	//        < 1E-018 limites [ 846829386,163266 ; 901925330,651468 ] >									
	//        < 0x0000000000000000000000000000000000000000000013B77F1AEC14FFE4D83D >									
	//     < RE_Portfolio_X_metadata_line_19_____GBG_Insurance_limited_USA_Bpp_20250515 >									
	//        < j7j5mAMiZ2XJAy7W6g9M47b805wjn0b0W8NDPS1hcYChUFTvVX180ILar64i5se5 >									
	//        < 1E-018 limites [ 901925330,651468 ; 963613439,131181 ] >									
	//        < 0x0000000000000000000000000000000000000000000014FFE4D83D166F956D9D >									
	//     < RE_Portfolio_X_metadata_line_20_____GE_ERC_20250515 >									
	//        < B8lQQKxTfltr7IydVrtZS21V742Trp5dxnuNYubmnk4P603r3011240BbP1haHng >									
	//        < 1E-018 limites [ 963613439,131181 ; 1007149153,42193 ] >									
	//        < 0x00000000000000000000000000000000000000000000166F956D9D177313A802 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_X_metadata_line_21_____General_Cologne_Re_20250515 >									
	//        < 47zVCP1yaRw527wI9To02P6A4l1L0XWrb89oKmKJmiA1iNy6UXz15z9p0y04bzW5 >									
	//        < 1E-018 limites [ 1007149153,42193 ; 1048176399,60965 ] >									
	//        < 0x00000000000000000000000000000000000000000000177313A80218679E440C >									
	//     < RE_Portfolio_X_metadata_line_22_____General_Insurance_Corporation_of_India_20250515 >									
	//        < WcI8agjWu00HLuOXPcgIW93U4dRsd38ayqQBM3z4918HsPojU053Tu8523e02zA3 >									
	//        < 1E-018 limites [ 1048176399,60965 ; 1094781549,32812 ] >									
	//        < 0x0000000000000000000000000000000000000000000018679E440C197D6814A8 >									
	//     < RE_Portfolio_X_metadata_line_23_____General_Insurance_Corporation_of_India_Am_20250515 >									
	//        < b272RujYz55e4526K3x06I4oTnW3v6swg4jJ53mCS6o697FHsCjYZmv1lq10CmmK >									
	//        < 1E-018 limites [ 1094781549,32812 ; 1105997978,5313 ] >									
	//        < 0x00000000000000000000000000000000000000000000197D6814A819C042FE51 >									
	//     < RE_Portfolio_X_metadata_line_24_____General_Re_Co_AA_App_20250515 >									
	//        < 8iSY8q4g0I1EKYi3nXL0G127S4h5N1C8ChR9NGjW9gk9sQ35KLSB9lzK3572U7q3 >									
	//        < 1E-018 limites [ 1105997978,5313 ; 1170640506,34888 ] >									
	//        < 0x0000000000000000000000000000000000000000000019C042FE511B418FA9BE >									
	//     < RE_Portfolio_X_metadata_line_25_____General_Reinsurance_AG_AAm_App_20250515 >									
	//        < 506mnh92Qnjd98H6JGPEePJSjqZK2WFVwPP9scSh8mg755V2aQ975ghBj8tY6I58 >									
	//        < 1E-018 limites [ 1170640506,34888 ; 1205540508,06079 ] >									
	//        < 0x000000000000000000000000000000000000000000001B418FA9BE1C1194D6EA >									
	//     < RE_Portfolio_X_metadata_line_26_____General_Security_Indemnity_Co_of_Arizona_AAm_A_20250515 >									
	//        < NwJ56wpssU33BXRh5tpJX7z8G7nVP7A86RmpIy1704a324a51YL6Qb5IPs7iZ3r1 >									
	//        < 1E-018 limites [ 1205540508,06079 ; 1228073254,88163 ] >									
	//        < 0x000000000000000000000000000000000000000000001C1194D6EA1C97E31524 >									
	//     < RE_Portfolio_X_metadata_line_27_____Generali_Group_20250515 >									
	//        < GXdph0Ey7ht53Wx46rI7r34Nw1lRYp91gwe5em47xjL0vDyzrGk86P5NcUgh8u7f >									
	//        < 1E-018 limites [ 1228073254,88163 ; 1246314210,20301 ] >									
	//        < 0x000000000000000000000000000000000000000000001C97E315241D049C9250 >									
	//     < RE_Portfolio_X_metadata_line_28_____Generali_Itallia_SPA_A_20250515 >									
	//        < EziC4N6N8Qe526PTj2qjeB3J9ifpKAp4z98XXnA8RHfwl4898g0z71r6kuAfMdui >									
	//        < 1E-018 limites [ 1246314210,20301 ; 1262776759,6049 ] >									
	//        < 0x000000000000000000000000000000000000000000001D049C92501D66BC6DAC >									
	//     < RE_Portfolio_X_metadata_line_29_____Gerling_Global_Financial_Services_20250515 >									
	//        < 57Z6p79tqy4VdQ8ee6Efw61KbZm29UoSnke0QYrK172YX7x262E4HJHbNoyBqxYQ >									
	//        < 1E-018 limites [ 1262776759,6049 ; 1317515363,57484 ] >									
	//        < 0x000000000000000000000000000000000000000000001D66BC6DAC1EAD00E8D9 >									
	//     < RE_Portfolio_X_metadata_line_30_____Gerling_Global_Re_20250515 >									
	//        < fndhvrI82gqh4b104s4xyGE551oJj45LaBnbE1G2Fu0pK47Z04R123F9V4R370Rs >									
	//        < 1E-018 limites [ 1317515363,57484 ; 1328252163,78192 ] >									
	//        < 0x000000000000000000000000000000000000000000001EAD00E8D91EECFFF76E >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_X_metadata_line_31_____Gerling_Reinsurance_Australia_20250515 >									
	//        < S54BBy0WgSerb40zls8mmfM4b1R0Nks7D5xXz72B2H9WfeYnfR3t47uQxZo7YOnj >									
	//        < 1E-018 limites [ 1328252163,78192 ; 1389263686,16927 ] >									
	//        < 0x000000000000000000000000000000000000000000001EECFFF76E2058A8295C >									
	//     < RE_Portfolio_X_metadata_line_32_____Ghana_Re_20250515 >									
	//        < Xep07ob9dGSp2d2ELyw3c9dOyffxB8oX9zu3M2J69KFD1doYAugrz5932v0Oslg4 >									
	//        < 1E-018 limites [ 1389263686,16927 ; 1412155401,035 ] >									
	//        < 0x000000000000000000000000000000000000000000002058A8295C20E11A257B >									
	//     < RE_Portfolio_X_metadata_line_33_____Gill_and_Roeser_20250515 >									
	//        < shI4a8zbvo3kvH7js7M43Px1i5nGGX3L9Xrp9Alq1UvKK7I95347d3ZAMbz145u0 >									
	//        < 1E-018 limites [ 1412155401,035 ; 1443837426,52427 ] >									
	//        < 0x0000000000000000000000000000000000000000000020E11A257B219DF114B0 >									
	//     < RE_Portfolio_X_metadata_line_34_____Glacier_Group_20250515 >									
	//        < 62GoA3czxuX9gX3IEKduaWWrrYYbwQat1qco9swKndtE6qP590eFL6h7CF1ezsdx >									
	//        < 1E-018 limites [ 1443837426,52427 ; 1514306817,90679 ] >									
	//        < 0x00000000000000000000000000000000000000000000219DF114B02341F8D6B2 >									
	//     < RE_Portfolio_X_metadata_line_35_____Glacier_Group_20250515 >									
	//        < pVa1i24T24zGsciDN2N3c0yUGJOOW7DnufLAflv52tV2r5bfdsjuzwcg5GHhT5FI >									
	//        < 1E-018 limites [ 1514306817,90679 ; 1561105223,20555 ] >									
	//        < 0x000000000000000000000000000000000000000000002341F8D6B22458E989C4 >									
	//     < RE_Portfolio_X_metadata_line_36_____Global_Reinsurance_20250515 >									
	//        < xT7tNv6JsRskofyS3F849821DH9VKA1a1f0G4rdfyYP9FIcvz6b4NfG5B2Ezm9K2 >									
	//        < 1E-018 limites [ 1561105223,20555 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000002458E989C424E6F08D4D >									
	//     < RE_Portfolio_X_metadata_line_37_____GMAC_Re_20250515 >									
	//        < jU4CJnL0d97607640u99MyrRrV71KC4iXmmEMe6O8G9g7as04cUrUUx5TwpB8bk8 >									
	//        < 1E-018 limites [ 1584933466,49313 ; 1653537746,74199 ] >									
	//        < 0x0000000000000000000000000000000000000000000024E6F08D4D267FDA6046 >									
	//     < RE_Portfolio_X_metadata_line_38_____GMF_Assurances_BBB_Baa3_20250515 >									
	//        < 79vx3Blc8rW03wG3jNL6ugR9Cg7MuV3tuA7Z6J1U6a57NHb16G9zv399oc8S3cBt >									
	//        < 1E-018 limites [ 1653537746,74199 ; 1670808102,81451 ] >									
	//        < 0x00000000000000000000000000000000000000000000267FDA604626E6CAD91D >									
	//     < RE_Portfolio_X_metadata_line_39_____Gothaer_Allgemeine_Versicherung_AG_Am_Am_20250515 >									
	//        < qz5CMsmU5s3f5aYBM92Y8d6l25K97x14mG49ysfB6DhP5pyuW3r0wEA595jOHrkO >									
	//        < 1E-018 limites [ 1670808102,81451 ; 1697655608,00777 ] >									
	//        < 0x0000000000000000000000000000000000000000000026E6CAD91D2786D0E3D4 >									
	//     < RE_Portfolio_X_metadata_line_40_____Great_Lakes_Reinsurance__UK__SE_AAm_Ap_20250515 >									
	//        < d728oj78xG9405BgT69TPvGmuIv9tBo0p89hNad0eP69qh4k7Q72jnAX5BeKv1OV >									
	//        < 1E-018 limites [ 1697655608,00777 ; 1724616534,05505 ] >									
	//        < 0x000000000000000000000000000000000000000000002786D0E3D4282783FF91 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}