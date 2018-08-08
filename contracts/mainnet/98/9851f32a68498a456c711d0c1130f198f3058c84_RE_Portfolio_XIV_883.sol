pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_XIV_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_XIV_883		"	;
		string	public		symbol =	"	RE883XIV		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1544348011475110000000000000					;	
										
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
	//     < RE_Portfolio_XIV_metadata_line_1_____Montpelier_Underwriting_Agencies_Limited_20250515 >									
	//        < x5Vts2z5Cq772X6WtJR8pW1Un7OKQI6a5LpsEKc73NKQuo3Z4BeK3ME9ugSrw0d9 >									
	//        < 1E-018 limites [ 1E-018 ; 12117403,5211375 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000004839B2B4 >									
	//     < RE_Portfolio_XIV_metadata_line_2_____Montpelier_Underwriting_Agencies_Limited_20250515 >									
	//        < pB5A0Lm77lsvV296vJfouKCB8N333Xs2508O6b6UgQ66u138yYtZr4e6QuGKVG1B >									
	//        < 1E-018 limites [ 12117403,5211375 ; 72283429,5542331 ] >									
	//        < 0x000000000000000000000000000000000000000000000004839B2B41AED7C49F >									
	//     < RE_Portfolio_XIV_metadata_line_3_____MS_Amlin_Plc_20250515 >									
	//        < 57j804app68uttTCx2jHn2WLgxKr8u25t86810z4lk85YTlaGQaqGOU5I7515jek >									
	//        < 1E-018 limites [ 72283429,5542331 ; 138917010,987791 ] >									
	//        < 0x00000000000000000000000000000000000000000000001AED7C49F33C028B5E >									
	//     < RE_Portfolio_XIV_metadata_line_4_____MS_Amlin_PLC_BBBp_20250515 >									
	//        < UUkeeea0A82Anx8usU2jQL5q1pmfjF415K83mL2FVjio0ixb7qk1WNp3Np3KO1Xs >									
	//        < 1E-018 limites [ 138917010,987791 ; 150740217,679471 ] >									
	//        < 0x000000000000000000000000000000000000000000000033C028B5E3827B537B >									
	//     < RE_Portfolio_XIV_metadata_line_5_____MS_Amlin_Underwriting_Limited_20250515 >									
	//        < WMZ8C6Q5qZ53c9i7MeWiCAHPXv0NZyaoHPnDB0HZNFpZSAlXKLD0O2IabUMfga1g >									
	//        < 1E-018 limites [ 150740217,679471 ; 194247264,480008 ] >									
	//        < 0x00000000000000000000000000000000000000000000003827B537B485CDCFA4 >									
	//     < RE_Portfolio_XIV_metadata_line_6_____MS_Amlin_Underwriting_Limited_20250515 >									
	//        < gM6o88XIxz05817IE6RyU9zbNxzs6VX19A86m59AowccUB8Bow7mVH5e5F64VqSa >									
	//        < 1E-018 limites [ 194247264,480008 ; 219903880,764582 ] >									
	//        < 0x0000000000000000000000000000000000000000000000485CDCFA451EBAB360 >									
	//     < RE_Portfolio_XIV_metadata_line_7_____MS_Amlin_Underwriting_Limited_20250515 >									
	//        < f4tDM6YTsAqP7U6F817QBAEn1O9alV3iM19VH1ztZTosrl2K0Ya28M28oR88fX6b >									
	//        < 1E-018 limites [ 219903880,764582 ; 261370390,417575 ] >									
	//        < 0x000000000000000000000000000000000000000000000051EBAB360615E392B5 >									
	//     < RE_Portfolio_XIV_metadata_line_8_____MSAD_Insurance_Group_Holdings_Incorporated_20250515 >									
	//        < xZssI11x93PJf0375DKLKMykmInbAXC03Fqcb0BouplFVZqX59H6i9i29ocy2LPS >									
	//        < 1E-018 limites [ 261370390,417575 ; 310154419,08619 ] >									
	//        < 0x0000000000000000000000000000000000000000000000615E392B5738AA17E8 >									
	//     < RE_Portfolio_XIV_metadata_line_9_____Munchener_Ruck_Munich_Re__Ap_20250515 >									
	//        < GF8XEi8d8Pd6SeUhT75Ut4Zz51e3Po8w5KYJ2GBE3QX9rXH7z5667eH4xUy59d9H >									
	//        < 1E-018 limites [ 310154419,08619 ; 351448543,719141 ] >									
	//        < 0x0000000000000000000000000000000000000000000000738AA17E882ECBED57 >									
	//     < RE_Portfolio_XIV_metadata_line_10_____Munich_American_Reassurance_Company_20250515 >									
	//        < leXW729EvKBt9T0nMoSUWGb1791sxX67ROBV1aQOi24TCp56AsB5TSMQHNkszOkO >									
	//        < 1E-018 limites [ 351448543,719141 ; 368934345,889944 ] >									
	//        < 0x000000000000000000000000000000000000000000000082ECBED578970524D0 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XIV_metadata_line_11_____Munich_Re_Group_20250515 >									
	//        < nSKL2c363g3BLa5Z8I4OsBH9AP9800H9aNNUX9815uM3m06BjMfhYmJL7x9oL2ui >									
	//        < 1E-018 limites [ 368934345,889944 ; 389958536,948538 ] >									
	//        < 0x00000000000000000000000000000000000000000000008970524D0914558372 >									
	//     < RE_Portfolio_XIV_metadata_line_12_____Munich_Re_Group_20250515 >									
	//        < Fi40jHIdQO5bOCsCE8684H10HHM104O32b4XNqZVG098IMb6Z9LjwDSw44MzqN5I >									
	//        < 1E-018 limites [ 389958536,948538 ; 435388713,555604 ] >									
	//        < 0x0000000000000000000000000000000000000000000000914558372A231E762F >									
	//     < RE_Portfolio_XIV_metadata_line_13_____Munich_Re_Group_20250515 >									
	//        < YW49f5KG8LP4TBS9m04sbW77F8Y770k387Oj7hy6FvvVzwaGiQCdN75KxH36aLwh >									
	//        < 1E-018 limites [ 435388713,555604 ; 486969634,303127 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A231E762FB5690B35A >									
	//     < RE_Portfolio_XIV_metadata_line_14_____Munich_Re_Syndicate_Limited_20250515 >									
	//        < IG3X3F9KZ5i84Gp33LE4v2GT9l2I71uX0FrsbOnTmWXyoJZ3YAJpItKm856bLk09 >									
	//        < 1E-018 limites [ 486969634,303127 ; 498847945,56237 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B5690B35AB9D5D90B0 >									
	//     < RE_Portfolio_XIV_metadata_line_15_____Munich_Re_Syndicate_Limited_20250515 >									
	//        < zzwsgEhuK5KSx2QKdu0ltIOC0JA8rOSVa89F4CfF7IP5u893IUjM82F7mIJm7oFa >									
	//        < 1E-018 limites [ 498847945,56237 ; 518787182,556995 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B9D5D90B0C14366D23 >									
	//     < RE_Portfolio_XIV_metadata_line_16_____Munich_Re_Syndicate_Limited_20250515 >									
	//        < 1h3l2OaHHBHAvoV9ab04z8aq63Qv03hjGGg5BrE28VRm2hU5RnMi604J5itY5369 >									
	//        < 1E-018 limites [ 518787182,556995 ; 538720502,724537 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C14366D23C8B064254 >									
	//     < RE_Portfolio_XIV_metadata_line_17_____Munich_Reinsurance_Company_20250515 >									
	//        < 6in8MpHCS3AX9y2wU54pKw7aF2t7cZL6Sn7iC9E00KJR6FUhY3eXCr4PCw9Gq8pe >									
	//        < 1E-018 limites [ 538720502,724537 ; 561929625,744253 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C8B064254D155C9202 >									
	//     < RE_Portfolio_XIV_metadata_line_18_____Mutual_Reinsurance_Bureau_20250515 >									
	//        < m0STK0z318eYLHL98AEP23if1RpEDVh12a8tI6V63pha1g9NN2Ipbq734abwmz6R >									
	//        < 1E-018 limites [ 561929625,744253 ; 572623162,432259 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D155C9202D55199CC7 >									
	//     < RE_Portfolio_XIV_metadata_line_19_____National_General_Insurance_Company__PSC__m_Am_20250515 >									
	//        < u4Uebd8v979X8Hp6Pk47572GZq7Jp1W6g316xW6VpeoDSjZ1YB2fSh0R9hY47ck9 >									
	//        < 1E-018 limites [ 572623162,432259 ; 606718391,550442 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D55199CC7E2052CDA7 >									
	//     < RE_Portfolio_XIV_metadata_line_20_____National_Liability_&_Fire_Ins_Co_AAp_App_20250515 >									
	//        < t500zc2OQzBWm8FnSze1v2hV83SXX250iZd32a188aUD8d9EK9be3MRnHKnO8D8s >									
	//        < 1E-018 limites [ 606718391,550442 ; 643137191,242521 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E2052CDA7EF9657B48 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XIV_metadata_line_21_____National_Union_Fire_Ins_Co_Of_Pitisburgh_Pennsylvania_Ap_A_20250515 >									
	//        < 0e7lK37Gk59BdaFn1VOFL1LLRdkzAnbTl1g25T16Yjg0Ip0CXNZ22DC0yI60h97r >									
	//        < 1E-018 limites [ 643137191,242521 ; 658000285,62596 ] >									
	//        < 0x0000000000000000000000000000000000000000000000EF9657B48F51FCC386 >									
	//     < RE_Portfolio_XIV_metadata_line_22_____Navigators_Ins_Co_A_A_20250515 >									
	//        < 0G8Vr72Ij885VT5PMz214S3g64zEL5f07Jo8bE4fCtboanp4y4T0w9nP0UOI4Khj >									
	//        < 1E-018 limites [ 658000285,62596 ; 737808183,566224 ] >									
	//        < 0x000000000000000000000000000000000000000000000F51FCC386112DADF3A8 >									
	//     < RE_Portfolio_XIV_metadata_line_23_____Navigators_Underwriting_Agency_Limited_20250515 >									
	//        < 77Z57Hf1vs8ihdC1017tiCqD2ZwlvXv3ZBqi3aD15HOtM46ej62D15K4Umg1vF0B >									
	//        < 1E-018 limites [ 737808183,566224 ; 788150204,765719 ] >									
	//        < 0x00000000000000000000000000000000000000000000112DADF3A81259BDC7B0 >									
	//     < RE_Portfolio_XIV_metadata_line_24_____Navigators_Underwriting_Agency_Limited_20250515 >									
	//        < j2Lku1w867tqTLjHBszu9emBq8yIvH2U44xOd6IXuh569nOSZ3181zCu76fXzDd7 >									
	//        < 1E-018 limites [ 788150204,765719 ; 812462552,295025 ] >									
	//        < 0x000000000000000000000000000000000000000000001259BDC7B012EAA77A71 >									
	//     < RE_Portfolio_XIV_metadata_line_25_____Neon_Underwriting_Limited_20250515 >									
	//        < IuGgH35o773r0u250rV15GPW36q48jJS8092H662Ka1vq0SaTevY3j58Ka33zKUZ >									
	//        < 1E-018 limites [ 812462552,295025 ; 859182749,164533 ] >									
	//        < 0x0000000000000000000000000000000000000000000012EAA77A71140120D758 >									
	//     < RE_Portfolio_XIV_metadata_line_26_____Neon_Underwriting_Limited_20250515 >									
	//        < o33fgjH43kFpYE5MNNzMl8u042S1G0WoI5S9ol6Z37nDcwG03nJODJhqJjhdWRR3 >									
	//        < 1E-018 limites [ 859182749,164533 ; 886672597,947944 ] >									
	//        < 0x00000000000000000000000000000000000000000000140120D75814A4FB0586 >									
	//     < RE_Portfolio_XIV_metadata_line_27_____New_Hampshire_Ins_Ap_A_20250515 >									
	//        < pZ40I7ediK0mYQ2l92g2XX971MKioy0pL4bIL9ny85aX5wKF1lCObURyj4UYl1B5 >									
	//        < 1E-018 limites [ 886672597,947944 ; 963425755,543964 ] >									
	//        < 0x0000000000000000000000000000000000000000000014A4FB0586166E770BB6 >									
	//     < RE_Portfolio_XIV_metadata_line_28_____New_Zealand_AA_CBL_Insurance_Limited_Am_20250515 >									
	//        < sw5H61ZY7b4a8p5wA1s0ghb2885liN3iV2xqR3z3SUEtDjwsWdnvgJ0lO82WReh9 >									
	//        < 1E-018 limites [ 963425755,543964 ; 1015707449,91526 ] >									
	//        < 0x00000000000000000000000000000000000000000000166E770BB617A6169493 >									
	//     < RE_Portfolio_XIV_metadata_line_29_____Newline_Underwriting_Management_Limited_20250515 >									
	//        < viS41171qp6PnkHg3yWY61GWk0In0dKZ4uOVXj597i97oyxvNR6j7QwRW0fHBet8 >									
	//        < 1E-018 limites [ 1015707449,91526 ; 1034219423,962 ] >									
	//        < 0x0000000000000000000000000000000000000000000017A616949318146D9C70 >									
	//     < RE_Portfolio_XIV_metadata_line_30_____Newline_Underwriting_Management_Limited_20250515 >									
	//        < qF7m00AWiVW5AIM7A5bDe8rRj69zo2H2rK9ZorY6W1P934w544atV9TJ9LbDX80s >									
	//        < 1E-018 limites [ 1034219423,962 ; 1045982336,26699 ] >									
	//        < 0x0000000000000000000000000000000000000000000018146D9C70185A8A640E >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XIV_metadata_line_31_____Nipponkoa_Insurance_CO__China__Limited_m_Am_20250515 >									
	//        < 8GGXdlr0PdUseHyjFXNXr9212b02XIFoJF65qjMV4yki13n99tvD5VenT7kW6jRS >									
	//        < 1E-018 limites [ 1045982336,26699 ; 1103787829,04471 ] >									
	//        < 0x00000000000000000000000000000000000000000000185A8A640E19B31692AC >									
	//     < RE_Portfolio_XIV_metadata_line_32_____NKSJ_Holdings_Incorporated_20250515 >									
	//        < pPrlpyM1CAWxch7T0iFy7WIL5Z34QU4B9KusJJwHv2zM9zF2V1D9027pXIxP7J8y >									
	//        < 1E-018 limites [ 1103787829,04471 ; 1118141576,81781 ] >									
	//        < 0x0000000000000000000000000000000000000000000019B31692AC1A08A4A765 >									
	//     < RE_Portfolio_XIV_metadata_line_33_____Noacional_de_Reasseguros_20250515 >									
	//        < 6dJo6f8od8juGGGv1rLKA75uq4Ql10I6Avm657v59O47r3Qyx4J2E6EVA4f3f8q6 >									
	//        < 1E-018 limites [ 1118141576,81781 ; 1141141470,27767 ] >									
	//        < 0x000000000000000000000000000000000000000000001A08A4A7651A91BBB4C7 >									
	//     < RE_Portfolio_XIV_metadata_line_34_____Novae_Syndicates_Limited_20250515 >									
	//        < trl4x30W3h5NVtbGMBfEy08o99PeKs3dR8KY07XKyRK24B8LPu723zOv0c5SmSUL >									
	//        < 1E-018 limites [ 1141141470,27767 ; 1165277159,52978 ] >									
	//        < 0x000000000000000000000000000000000000000000001A91BBB4C71B2197D864 >									
	//     < RE_Portfolio_XIV_metadata_line_35_____Novae_Syndicates_Limited_20250515 >									
	//        < 8z95BrEb70pqSe1C3gsuB15e5Qx40n5HrPg23352Ns2Wkov97e3AxGrSaKWO8ojh >									
	//        < 1E-018 limites [ 1165277159,52978 ; 1232882860,41083 ] >									
	//        < 0x000000000000000000000000000000000000000000001B2197D8641CB48DF54D >									
	//     < RE_Portfolio_XIV_metadata_line_36_____Novae_Syndicates_Limited_20250515 >									
	//        < vy8qm5YxFMIwELo9k8lC33SgcT77D5Rp5ZILSgvUO03E42AHomR4m4ztQApimSgC >									
	//        < 1E-018 limites [ 1232882860,41083 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001CB48DF54D1E0E1A85C7 >									
	//     < RE_Portfolio_XIV_metadata_line_37_____Odyssey_Re_20250515 >									
	//        < G71923TXVOd5JsG44MYW7ubtFdphx892EqilV1sw9tM4f0W58WIxir7xnUlSQBf2 >									
	//        < 1E-018 limites [ 1290856375,87123 ; 1365562355,90604 ] >									
	//        < 0x000000000000000000000000000000000000000000001E0E1A85C71FCB62CD3A >									
	//     < RE_Portfolio_XIV_metadata_line_38_____Odyssey_Re_Holdings_Corp_20250515 >									
	//        < 56ofL2KZ745JgHB77mic6n61vHD5C5Y90O2YTg8q9OFg21E4w2S60U3umN3AX7Tp >									
	//        < 1E-018 limites [ 1365562355,90604 ; 1421707651,22514 ] >									
	//        < 0x000000000000000000000000000000000000000000001FCB62CD3A211A09B936 >									
	//     < RE_Portfolio_XIV_metadata_line_39_____Odyssey_Re_Holdings_Corp_20250515 >									
	//        < nZlJD224351Shp525xF7eGMd9375Q32851mnuJK1PfhiWYG8ro6k2WU4jdj7Hw60 >									
	//        < 1E-018 limites [ 1421707651,22514 ; 1472011578,74957 ] >									
	//        < 0x00000000000000000000000000000000000000000000211A09B9362245DF6CE6 >									
	//     < RE_Portfolio_XIV_metadata_line_40_____Odyssey_Re_Holdings_Corporation_20250515 >									
	//        < TGIXDSzN4apX4iBXki5k1hd54Oj5SleeXyW8WNLQN1JQylo0eJoJ8N1kcD6Xm8UG >									
	//        < 1E-018 limites [ 1472011578,74957 ; 1544348011,47511 ] >									
	//        < 0x000000000000000000000000000000000000000000002245DF6CE623F5080FEF >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}