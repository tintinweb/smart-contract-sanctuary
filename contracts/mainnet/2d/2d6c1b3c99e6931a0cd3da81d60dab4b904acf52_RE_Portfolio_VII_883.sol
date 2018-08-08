pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_VII_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_VII_883		"	;
		string	public		symbol =	"	RE883VII		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1592025577783000000000000000					;	
										
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
	//     < RE_Portfolio_VII_metadata_line_1_____Berkshire_Hathaway_International_Insurance_Limited_AAp_m_20250515 >									
	//        < b2Kw7N8NLpexUO9DEYi3BzwDFFOzXE40G65XdI97oPS6RUMggy8x8Rtkb5HJJDh1 >									
	//        < 1E-018 limites [ 1E-018 ; 28861009,3216454 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000AC0669B8 >									
	//     < RE_Portfolio_VII_metadata_line_2_____Berkshire_Hathaway_Reinsurance_Group_20250515 >									
	//        < q8N3AiSQHotWCy8QaoMidG5VNk6nk7UD4284UfEWO19c4ie4rk4wxO53DcC5z2zA >									
	//        < 1E-018 limites [ 28861009,3216454 ; 107464025,849827 ] >									
	//        < 0x00000000000000000000000000000000000000000000000AC0669B828089190C >									
	//     < RE_Portfolio_VII_metadata_line_3_____Berkshire_Hathaway_Reinsurance_Group_20250515 >									
	//        < ItB1QMaSI43svE614VC54wE43pTHK4GcSjbbq21s95VP18Poh2t06U96MUubV83j >									
	//        < 1E-018 limites [ 107464025,849827 ; 156578902,884003 ] >									
	//        < 0x000000000000000000000000000000000000000000000028089190C3A54873E4 >									
	//     < RE_Portfolio_VII_metadata_line_4_____BMA_Reinsurance_20250515 >									
	//        < 90n5m1q50K17iUBt7rUP29etVnJ4ctxfYFrB4Ub3ls4KmnQ30XAM7W8436h6LIbO >									
	//        < 1E-018 limites [ 156578902,884003 ; 225896638,136609 ] >									
	//        < 0x00000000000000000000000000000000000000000000003A54873E454272EC39 >									
	//     < RE_Portfolio_VII_metadata_line_5_____BMS_Group_20250515 >									
	//        < LrA09QyS6bkUkdaknm7PZDX1X588y9N8p13SS2RWISX7H8Cm3UmoM95Js53821FT >									
	//        < 1E-018 limites [ 225896638,136609 ; 268843872,939129 ] >									
	//        < 0x000000000000000000000000000000000000000000000054272EC396426F33D1 >									
	//     < RE_Portfolio_VII_metadata_line_6_____Brazil_BBBm_IRB_Brasil_Resseguros_SA_Am_20250515 >									
	//        < iAqv2Ie5kCO6C5y6Y4O9Y61E3K45JC0H913yvt70MrM4lTTNIkSzC8PNy53ZjeT8 >									
	//        < 1E-018 limites [ 268843872,939129 ; 308603123,761401 ] >									
	//        < 0x00000000000000000000000000000000000000000000006426F33D172F6B012C >									
	//     < RE_Portfolio_VII_metadata_line_7_____Brit_Syndicates_Limited_20250515 >									
	//        < S7A2xFrB261sM3Ov9trH9pikH5q6MvIZ92ie38mpWIxIYoLc1D1yR8l2b6FI3I9A >									
	//        < 1E-018 limites [ 308603123,761401 ; 343931584,044248 ] >									
	//        < 0x000000000000000000000000000000000000000000000072F6B012C801FDF4F8 >									
	//     < RE_Portfolio_VII_metadata_line_8_____Brit_Syndicates_Limited_20250515 >									
	//        < m115VJCWvGd95ZU2sU1LSZ3yS5o9L3K9I36sKGjwIkKBftNtffo7vLcjO6BN5U5D >									
	//        < 1E-018 limites [ 343931584,044248 ; 358777504,407766 ] >									
	//        < 0x0000000000000000000000000000000000000000000000801FDF4F885A7B089C >									
	//     < RE_Portfolio_VII_metadata_line_9_____Brit_Syndicates_Limited_20250515 >									
	//        < 3IsEaM4aUW6EOzlM229lwPP2O79e85Tf0Ta0nZh6Wtn5MfA1KWespDC134GH8819 >									
	//        < 1E-018 limites [ 358777504,407766 ; 372565099,747833 ] >									
	//        < 0x000000000000000000000000000000000000000000000085A7B089C8ACA93C0A >									
	//     < RE_Portfolio_VII_metadata_line_10_____Brit_Syndicates_Limited_20250515 >									
	//        < AGuXVF6ZY4O21cq4ty4XPN99LYigVghLBc1L09Vj7870B26u4blzi8g5V18MA38X >									
	//        < 1E-018 limites [ 372565099,747833 ; 385953922,720421 ] >									
	//        < 0x00000000000000000000000000000000000000000000008ACA93C0A8FC76F504 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VII_metadata_line_11_____Brit_Syndicates_Limited_20250515 >									
	//        < U6Xx2H39v5l6Y9Z73Y54l7q51QOFyAo50A3NGJA39AZ0k7aJ2iU6nDTyAEeQWYjr >									
	//        < 1E-018 limites [ 385953922,720421 ; 412504411,61062 ] >									
	//        < 0x00000000000000000000000000000000000000000000008FC76F50499AB7C9BD >									
	//     < RE_Portfolio_VII_metadata_line_12_____Brokers_and_Reinsurance_Markets_Association_20250515 >									
	//        < nm1PPphX6q44Elqew1o14Sh43mMjmu29vT42bSvH3X7p9cd59gEPEFg3qtGz8Nyh >									
	//        < 1E-018 limites [ 412504411,61062 ; 470029652,520769 ] >									
	//        < 0x000000000000000000000000000000000000000000000099AB7C9BDAF19856F8 >									
	//     < RE_Portfolio_VII_metadata_line_13_____Bupa_Insurance_Limited_m_m_Ap_20250515 >									
	//        < K710Q7qakg8G04VxjM119Ag7zyUnFVCvAp3750pxn0q1lJ8RUDj4n16FgjO09Ipf >									
	//        < 1E-018 limites [ 470029652,520769 ; 529445170,584736 ] >									
	//        < 0x0000000000000000000000000000000000000000000000AF19856F8C53BD39B6 >									
	//     < RE_Portfolio_VII_metadata_line_14_____Caisse_Centrale_de_Reassurance_20250515 >									
	//        < plW6bPISG5QOtNj1q80KTU7DxRVfuGnRAKLbVHvYSAJhh477OUn8bB0eU2aFIjpN >									
	//        < 1E-018 limites [ 529445170,584736 ; 570996370,239225 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C53BD39B6D4B675313 >									
	//     < RE_Portfolio_VII_metadata_line_15_____Caisse_Centrale_De_Reassurances_AA_Ap_20250515 >									
	//        < Tb5iztS43oSmPHuBRLGBb8B13w6MheR601cCN72yf2L0h5JJSG5VaS8b4YA54D8Y >									
	//        < 1E-018 limites [ 570996370,239225 ; 610567161,106495 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D4B675313E37438F42 >									
	//     < RE_Portfolio_VII_metadata_line_16_____Canopius_Managing_Agents_Limited_20250515 >									
	//        < 18id6wj89rSlBWm6zh5w9T2dJckc5IIK61r3V2Le82wIkV4z7sIW98Maukbd5NfD >									
	//        < 1E-018 limites [ 610567161,106495 ; 634621545,227274 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E37438F42EC6A3A30E >									
	//     < RE_Portfolio_VII_metadata_line_17_____Canopius_Managing_Agents_Limited_20250515 >									
	//        < 8Wdt3IQq7L9gyiSK9ratR9W53KhsZO39NRyK52R7Y06l66rvLurgvSH9mlryDY2Q >									
	//        < 1E-018 limites [ 634621545,227274 ; 709240475,887454 ] >									
	//        < 0x000000000000000000000000000000000000000000000EC6A3A30E10836716D8 >									
	//     < RE_Portfolio_VII_metadata_line_18_____Canopius_Managing_Agents_Limited_20250515 >									
	//        < 743Asq989tw5Pg25SOe98z8D8Qr2txb7z6ttvk7zm87I8LhRI8htp0FJurB9jHb0 >									
	//        < 1E-018 limites [ 709240475,887454 ; 728455638,269099 ] >									
	//        < 0x0000000000000000000000000000000000000000000010836716D810F5EF19A6 >									
	//     < RE_Portfolio_VII_metadata_line_19_____Canopius_Managing_Agents_Limited_20250515 >									
	//        < GH980xvE51LE4Ck4l67w0DNSN4sBWenVAKtZmEgcYSj7jGo9NCv5K4sXo7OKlYz4 >									
	//        < 1E-018 limites [ 728455638,269099 ; 796646250,67732 ] >									
	//        < 0x0000000000000000000000000000000000000000000010F5EF19A6128C61B79F >									
	//     < RE_Portfolio_VII_metadata_line_20_____Canopius_Managing_Agents_Limited_20250515 >									
	//        < 3NjghNjmTp8wIYy65BawvhZQ5841nAXSq8Fgf9OoAZfCEk87jlv7cIQAnk9yk8F8 >									
	//        < 1E-018 limites [ 796646250,67732 ; 866150965,247675 ] >									
	//        < 0x00000000000000000000000000000000000000000000128C61B79F142AA97EC0 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VII_metadata_line_21_____Canopius_Managing_Agents_Limited_20250515 >									
	//        < oB2qV58TLsEIplhD773ezluCTpT233XtMp2z8CAJ90G1m80Ewk8fpq74v7YB81dP >									
	//        < 1E-018 limites [ 866150965,247675 ; 911550225,474008 ] >									
	//        < 0x00000000000000000000000000000000000000000000142AA97EC015394344C7 >									
	//     < RE_Portfolio_VII_metadata_line_22_____Capita_Managing_Agency_Limited_20250515 >									
	//        < Y4HxliqD4Bkba3qZ64pJe959ka7O705i9BqzEKtf956XZ2N5335o882J5c98J904 >									
	//        < 1E-018 limites [ 911550225,474008 ; 928785290,209167 ] >									
	//        < 0x0000000000000000000000000000000000000000000015394344C7159FFDE3F0 >									
	//     < RE_Portfolio_VII_metadata_line_23_____Capita_Managing_Agency_Limited_20250515 >									
	//        < tRKSkJh254Ct15siHPIxstOy6ixDaq87LT7ULR43tfg8Q84MRNMH0gok4kXjE8c0 >									
	//        < 1E-018 limites [ 928785290,209167 ; 963046935,558646 ] >									
	//        < 0x00000000000000000000000000000000000000000000159FFDE3F0166C350327 >									
	//     < RE_Portfolio_VII_metadata_line_24_____Capita_Managing_Agency_Limited_20250515 >									
	//        < 71dDpv6l1PN84VUr6Vg3gDu6L2P4rnL611q1XLzLVu0j4gow6n5N8L1spP7mz0Ow >									
	//        < 1E-018 limites [ 963046935,558646 ; 991939291,134446 ] >									
	//        < 0x00000000000000000000000000000000000000000000166C35032717186B3F8D >									
	//     < RE_Portfolio_VII_metadata_line_25_____Capita_Syndicate_Management_Limited_20250515 >									
	//        < kbJS4Q0zWqi939zCwx819gt29981vLVh06N79a20e1nNSLiSueN523Pl2yQqv7lQ >									
	//        < 1E-018 limites [ 991939291,134446 ; 1037908231,48745 ] >									
	//        < 0x0000000000000000000000000000000000000000000017186B3F8D182A6A48E0 >									
	//     < RE_Portfolio_VII_metadata_line_26_____CATEX_20250515 >									
	//        < 3L349am55q947sNG4cQtrjo9x67Nq4fZ5wyq7OKXq4RV1c0g54E9jVhHbgLMaQc9 >									
	//        < 1E-018 limites [ 1037908231,48745 ; 1078340115,43145 ] >									
	//        < 0x00000000000000000000000000000000000000000000182A6A48E0191B68718B >									
	//     < RE_Portfolio_VII_metadata_line_27_____Cathedral_Underwriting_Limited_20250515 >									
	//        < 9p32f1X77t66v3bd030ZTxzhkr4dPdi8tR0Gax41G5z1KU9KZ1drJGr04K1hnNFD >									
	//        < 1E-018 limites [ 1078340115,43145 ; 1101365908,94578 ] >									
	//        < 0x00000000000000000000000000000000000000000000191B68718B19A4A70422 >									
	//     < RE_Portfolio_VII_metadata_line_28_____Cathedral_Underwriting_Limited_20250515 >									
	//        < kQdG979c3vqaJE0xU0NOcAaVc11p8DPdR9Xr8oxFpx90Q1fdLmwrv267082c8Vg7 >									
	//        < 1E-018 limites [ 1101365908,94578 ; 1112971320,90702 ] >									
	//        < 0x0000000000000000000000000000000000000000000019A4A7042219E9D3782E >									
	//     < RE_Portfolio_VII_metadata_line_29_____Cathedral_Underwriting_Limited_20250515 >									
	//        < X9O45WNjJS7Mnsus4Z1mt6jT9GuTyKtRw4sp5wqVf2go6qfS6Bz8W25MK65Z5WOu >									
	//        < 1E-018 limites [ 1112971320,90702 ; 1154178273,69648 ] >									
	//        < 0x0000000000000000000000000000000000000000000019E9D3782E1ADF704A1D >									
	//     < RE_Portfolio_VII_metadata_line_30_____Cathedral_Underwriting_Limited_20250515 >									
	//        < P36TQxq24OSV4ws8fnK2DA3r3m4W5110u3OABNq428mrc396x2jJGPDoos5nE7QE >									
	//        < 1E-018 limites [ 1154178273,69648 ; 1231472431,73042 ] >									
	//        < 0x000000000000000000000000000000000000000000001ADF704A1D1CAC25D099 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VII_metadata_line_31_____Catlin_Group_Limited_20250515 >									
	//        < 61GVGIQYL8Q9kT5hodT5hWFoMyt4DD904h9Tm654761W5Si3rete9g5gq2n1dhM6 >									
	//        < 1E-018 limites [ 1231472431,73042 ; 1284605995,8667 ] >									
	//        < 0x000000000000000000000000000000000000000000001CAC25D0991DE8D93316 >									
	//     < RE_Portfolio_VII_metadata_line_32_____Catlin_Insurance_Co__UK__Limited_Ap_A_20250515 >									
	//        < 2xVmTVG1tECxk5VMvw255OiyL2B1I326Xjm4x9t29Ny1bLAZ168EwcHZ32zV0hry >									
	//        < 1E-018 limites [ 1284605995,8667 ; 1336052033,84697 ] >									
	//        < 0x000000000000000000000000000000000000000000001DE8D933161F1B7D9FAC >									
	//     < RE_Portfolio_VII_metadata_line_33_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < E3bp6E00FJ99x188Tx4Z3tlW1TCtc2G673b23tu4gqo94sCW8s8c14GnlVWI31PE >									
	//        < 1E-018 limites [ 1336052033,84697 ; 1370206406,98323 ] >									
	//        < 0x000000000000000000000000000000000000000000001F1B7D9FAC1FE7110FAE >									
	//     < RE_Portfolio_VII_metadata_line_34_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < 88lH0RC20NtFHzc6J3lANBl62ZvM4jF3i25aGyr2GWvFqoEQGNv51UqnLubTS152 >									
	//        < 1E-018 limites [ 1370206406,98323 ; 1420776102,95507 ] >									
	//        < 0x000000000000000000000000000000000000000000001FE7110FAE21147C4B2B >									
	//     < RE_Portfolio_VII_metadata_line_35_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < Em9G1QTC4bY8YdArAG5elayZC8ZcZ4Xclj88QuCElSjw73xf24s8SBS0zST45mCy >									
	//        < 1E-018 limites [ 1420776102,95507 ; 1437757599,24907 ] >									
	//        < 0x0000000000000000000000000000000000000000000021147C4B2B2179B40028 >									
	//     < RE_Portfolio_VII_metadata_line_36_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < r9ot7qP0606n0aMHjz4646u5CL3e45x37apcQVVNEY6Yf2RQGNv8rq1kF6ID12OL >									
	//        < 1E-018 limites [ 1437757599,24907 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000002179B4002821BF0C8EA6 >									
	//     < RE_Portfolio_VII_metadata_line_37_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < kq1DM5qMxzs1H8XNfzh45Zd57PBCCZdWux227wuG9y7R2Wdt3IalFgCMxMK6nR69 >									
	//        < 1E-018 limites [ 1449391914,74149 ; 1481978387,72403 ] >									
	//        < 0x0000000000000000000000000000000000000000000021BF0C8EA622814791A8 >									
	//     < RE_Portfolio_VII_metadata_line_38_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < z0gO77HGAoF8sEX1xC6J0GQ6r008lKzr7Z6J6UEl0dxbwe3C6E18L998TYW2vJlh >									
	//        < 1E-018 limites [ 1481978387,72403 ; 1499789073,80768 ] >									
	//        < 0x0000000000000000000000000000000000000000000022814791A822EB7084E8 >									
	//     < RE_Portfolio_VII_metadata_line_39_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < 3taHI79Yi7Hu789aeRe83J72k532iwuAl602g83C2oDbqn65duAhpAiupY809JUM >									
	//        < 1E-018 limites [ 1499789073,80768 ; 1556004519,32335 ] >									
	//        < 0x0000000000000000000000000000000000000000000022EB7084E8243A827B50 >									
	//     < RE_Portfolio_VII_metadata_line_40_____Catlin_Underwriting_Agencies_Limited_20250515 >									
	//        < 5Q1rUNRh1I6y20uLrt7V3ano8Akgo5374EyJtn2s4HpJ7cMPJA3BXK60pi2PT55p >									
	//        < 1E-018 limites [ 1556004519,32335 ; 1592025577,783 ] >									
	//        < 0x00000000000000000000000000000000000000000000243A827B502511364146 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}