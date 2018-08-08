pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_XI_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_XI_883		"	;
		string	public		symbol =	"	RE883XI		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1453938925589850000000000000					;	
										
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
	//     < RE_Portfolio_XI_metadata_line_1_____Great_West_Lifeco_20250515 >									
	//        < XzZ1DK8ngUhgEyXE3ZR66LIPqEAvB37n4csP9MALEudGa8Q56LXe40sBIyL9ZqcZ >									
	//        < 1E-018 limites [ 1E-018 ; 19569831,6845323 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000000074A53374 >									
	//     < RE_Portfolio_XI_metadata_line_2_____Greenlight_Capital_Re_20250515 >									
	//        < dmX04Cfe126MxSKk6eX78Xvrd6LcjLqfaAFFQ6iGjsJ4t4lZdDnohIJo85S5X7tf >									
	//        < 1E-018 limites [ 19569831,6845323 ; 65367910,7980701 ] >									
	//        < 0x0000000000000000000000000000000000000000000000074A533741859F861B >									
	//     < RE_Portfolio_XI_metadata_line_3_____Griffiths_and_Wanklyn_Reinsurance_Brokers_20250515 >									
	//        < 75iGCneq5vn4qh7CsZZsTYO4k0qk4fxdXivI00UPHtUXAi4UjIbmhriCp9kOMu7f >									
	//        < 1E-018 limites [ 65367910,7980701 ; 131251358,732801 ] >									
	//        < 0x00000000000000000000000000000000000000000000001859F861B30E51AFF5 >									
	//     < RE_Portfolio_XI_metadata_line_4_____Grinnell_Mutual_Group_20250515 >									
	//        < uDlGL8vNI9GBOFyuQ5g0zineaLC77BAFZXUH7WjNfraEWeuOlbOQ3PLoh2z0ehV1 >									
	//        < 1E-018 limites [ 131251358,732801 ; 146876548,757537 ] >									
	//        < 0x000000000000000000000000000000000000000000000030E51AFF536B73D5CF >									
	//     < RE_Portfolio_XI_metadata_line_5_____Guaranty_Fund_Management_Services_20250515 >									
	//        < JXi8J6NPS8TmnV91qMlNKwcN9K6Id26Y7uCq76CVfhXNky77bcyT4k2T0s932Wd6 >									
	//        < 1E-018 limites [ 146876548,757537 ; 187712386,118772 ] >									
	//        < 0x000000000000000000000000000000000000000000000036B73D5CF45EDA60C7 >									
	//     < RE_Portfolio_XI_metadata_line_6_____Guernsey_AAp_Jupiter_Insurance_Limited_A_20250515 >									
	//        < jgwwz88rIrp2mD1t166mR6R68ewbiHbD5mItO9VONb4eX98ZY0CRqJ051Ls2ckDX >									
	//        < 1E-018 limites [ 187712386,118772 ; 227222284,992817 ] >									
	//        < 0x000000000000000000000000000000000000000000000045EDA60C754A59B307 >									
	//     < RE_Portfolio_XI_metadata_line_7_____Gulf_Ins_And_Reinsuerance_Co_Am_m_20250515 >									
	//        < 40LJPs0oS2EzTJPY1704MI2h29nhz17DeHK046Y1a6vcnhbMh1BilN50LMACY3i5 >									
	//        < 1E-018 limites [ 227222284,992817 ; 279883619,620244 ] >									
	//        < 0x000000000000000000000000000000000000000000000054A59B3076843C84DE >									
	//     < RE_Portfolio_XI_metadata_line_8_____Gulf_Reinsurance_limited_Am_20250515 >									
	//        < xX7pb6X9I0a08A46fqLxG4G13yS72GXdFwh9dRA4CYr32DOHxB06c2Gx85Ir5Pck >									
	//        < 1E-018 limites [ 279883619,620244 ; 291627888,479581 ] >									
	//        < 0x00000000000000000000000000000000000000000000006843C84DE6CA3CD9E3 >									
	//     < RE_Portfolio_XI_metadata_line_9_____Guy_Carpenter_Reinsurance_20250515 >									
	//        < 2r1q1xdVg9k2c0iBUR5puegxcJnqwVEBfS0gwCD4Y6ryXChXwhrHY8G0kC1ctwB0 >									
	//        < 1E-018 limites [ 291627888,479581 ; 323838938,886402 ] >									
	//        < 0x00000000000000000000000000000000000000000000006CA3CD9E378A3B0374 >									
	//     < RE_Portfolio_XI_metadata_line_10_____Hamilton_Underwriting_Limited_20250515 >									
	//        < kmgIh2013y1irMRjeLSoQ1tj9piHrcPZvYsTfPTo8g86DnyS6W1058Y7LDin3Tkc >									
	//        < 1E-018 limites [ 323838938,886402 ; 336243829,869306 ] >									
	//        < 0x000000000000000000000000000000000000000000000078A3B03747D42B5FFE >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XI_metadata_line_11_____Hamilton_Underwriting_Limited_20250515 >									
	//        < D594nbS0ToQqtvCH5zBi79azli04hZWY86F8ARtw95F64QEMB2wIrNa7b5M87D62 >									
	//        < 1E-018 limites [ 336243829,869306 ; 397167608,586775 ] >									
	//        < 0x00000000000000000000000000000000000000000000007D42B5FFE93F4DAF0E >									
	//     < RE_Portfolio_XI_metadata_line_12_____Hannover_Life_Re_20250515 >									
	//        < MRjWta7M21Egw3NL8Edlr14kd18vWY64w934NV8ygbT78nSwwdA8QElBJROahy6x >									
	//        < 1E-018 limites [ 397167608,586775 ; 433692041,918113 ] >									
	//        < 0x000000000000000000000000000000000000000000000093F4DAF0EA19018BD3 >									
	//     < RE_Portfolio_XI_metadata_line_13_____Hannover_Re_Group_20250515 >									
	//        < er8oB6YcQqzGb3uueri195WIAjqad3KjzE8dg91Qkp1s4Ap5lYC7Vsqqe4463nxw >									
	//        < 1E-018 limites [ 433692041,918113 ; 446309827,635949 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A19018BD3A6436C25F >									
	//     < RE_Portfolio_XI_metadata_line_14_____Hannover_Re_Group_20250515 >									
	//        < lYNa07Um2ZS1Rj8qkqfGYZFv56z4u1SluFbzdHuDyIz2E1m7BI7uN9n6jSjq43qm >									
	//        < 1E-018 limites [ 446309827,635949 ; 490892761,227866 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A6436C25FB6DF2EACE >									
	//     < RE_Portfolio_XI_metadata_line_15_____Hannover_Reinsurance_Group_Africa_20250515 >									
	//        < p68739A96QEAIr66foGMjnA35ZCn75191CzAf9028Xt6aR1V55J7PbdJHsjt01Im >									
	//        < 1E-018 limites [ 490892761,227866 ; 558925993,846774 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B6DF2EACED0375644C >									
	//     < RE_Portfolio_XI_metadata_line_16_____Hannover_ReTakaful_BSC_Ap_m_20250515 >									
	//        < CVv4ZWvI2s5D425K8k45pG1yE3B38gY1M14RW3LTq8kiMA97E2v2YGZtxDABbpTi >									
	//        < 1E-018 limites [ 558925993,846774 ; 604025094,139495 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D0375644CE10452859 >									
	//     < RE_Portfolio_XI_metadata_line_17_____Hannover_ReTakaful_BSC_Ap_m_20250515 >									
	//        < n81066sGJebjWFhtdD1the0f0z8kwDI33Ep9yZVxt5e1aq6ll739wQQG7c6cO276 >									
	//        < 1E-018 limites [ 604025094,139495 ; 631006955,172866 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E10452859EB11835D1 >									
	//     < RE_Portfolio_XI_metadata_line_18_____Hannover_Rueck_SE_AAm_20250515 >									
	//        < MbfRlcj5j8D41Wtf34q6t7fM2ixp686bd6nYKe3eGj8nJw8q2C4oJOi8m9DQoXqM >									
	//        < 1E-018 limites [ 631006955,172866 ; 641615496,058131 ] >									
	//        < 0x0000000000000000000000000000000000000000000000EB11835D1EF0538F19 >									
	//     < RE_Portfolio_XI_metadata_line_19_____Hannover_Rueckversicherung_AG_20250515 >									
	//        < 4os04EAg93MxrUaZgu0oqb5j6v3wd1I7Cg1ahTSSM21cl9up88CJ6dzSRAi3a54z >									
	//        < 1E-018 limites [ 641615496,058131 ; 697699360,277755 ] >									
	//        < 0x000000000000000000000000000000000000000000000EF0538F19103E9CBE8F >									
	//     < RE_Portfolio_XI_metadata_line_20_____Hardy__Underwriting_Agencies__Limited_20250515 >									
	//        < 922x2wiwk0V3v4kwVQ9rbfRq12JZ5Pp0N8v8rya37C4BTVwIS992hVIUzk9klCjB >									
	//        < 1E-018 limites [ 697699360,277755 ; 759840916,352554 ] >									
	//        < 0x00000000000000000000000000000000000000000000103E9CBE8F11B1013BE7 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XI_metadata_line_21_____Hardy__Underwriting_Agencies__Limited_20250515 >									
	//        < V93zF15O670Ee3CYHZDlW819GCD6iQBFKcNk6lStxDwXoIvqO2H8H8lhq071WZD1 >									
	//        < 1E-018 limites [ 759840916,352554 ; 788560124,817188 ] >									
	//        < 0x0000000000000000000000000000000000000000000011B1013BE7125C2F44B5 >									
	//     < RE_Portfolio_XI_metadata_line_22_____Hardy_(Underwriting_Agencies)_Limited_20250515 >									
	//        < hhso34PeDkJU1M620TeW1AfV7a1L6Pa33KJiTE005UPs7mvdRDJs8O66u7blP61U >									
	//        < 1E-018 limites [ 788560124,817188 ; 826897315,451359 ] >									
	//        < 0x00000000000000000000000000000000000000000000125C2F44B51340B12DCD >									
	//     < RE_Portfolio_XI_metadata_line_23_____HCC_International_Insurance_Co_PLC_AAm_m_20250515 >									
	//        < A8BlNrFf44m8r8tWTA1b4l705Jm2827nB23qba3c12Lr80Z9b7QxiqJq0GXj8E2W >									
	//        < 1E-018 limites [ 826897315,451359 ; 865840983,603299 ] >									
	//        < 0x000000000000000000000000000000000000000000001340B12DCD1428D0802C >									
	//     < RE_Portfolio_XI_metadata_line_24_____HCC_Underwriting_Agency_Limited_20250515 >									
	//        < 8x57d5e6Y0W262vjN7ZUauZOyAIhG7EqZF7IainY97VNZL6KDR7CkCo95j8NRh88 >									
	//        < 1E-018 limites [ 865840983,603299 ; 877311036,88113 ] >									
	//        < 0x000000000000000000000000000000000000000000001428D0802C146D2E69BC >									
	//     < RE_Portfolio_XI_metadata_line_25_____HCC_Underwriting_Agency_Limited_20250515 >									
	//        < VS0IH2BuA70NWJAL7K248Ug7Dugz4iZ75H3YaBIxIBa8ea2jx4XcvH4sWao4sxEf >									
	//        < 1E-018 limites [ 877311036,88113 ; 916878075,111654 ] >									
	//        < 0x00000000000000000000000000000000000000000000146D2E69BC155904EC0B >									
	//     < RE_Portfolio_XI_metadata_line_26_____HDImGerling_Welt_Service_Ag_Ap_m_20250515 >									
	//        < I1r4UPmglSrMcE5LiSxxr8yXAwk1sFI41kbJNP8Gn1969EijvgcE9q7G2M26Q824 >									
	//        < 1E-018 limites [ 916878075,111654 ; 927646922,32741 ] >									
	//        < 0x00000000000000000000000000000000000000000000155904EC0B159934E0FC >									
	//     < RE_Portfolio_XI_metadata_line_27_____Helvetia_Schweizerische_Co_A_m_20250515 >									
	//        < 96O7N3jo7lcMprlxSFlws4fJxC4iG1gtwtpNZrf54uR8Vzxi4q75bd108YO0FRji >									
	//        < 1E-018 limites [ 927646922,32741 ; 970959569,603872 ] >									
	//        < 0x00000000000000000000000000000000000000000000159934E0FC169B5EBBD4 >									
	//     < RE_Portfolio_XI_metadata_line_28_____Helvetia_Schweizerische_Versicherungs_Gesellschaft_in_Liechtenstein_AG_20250515 >									
	//        < 56P9M19o28k1oG05T9kNz1dVjl2vveZ9d13M705GVcHcx4L5N684lFJVI26G3LOb >									
	//        < 1E-018 limites [ 970959569,603872 ; 994566143,702659 ] >									
	//        < 0x00000000000000000000000000000000000000000000169B5EBBD417281381D6 >									
	//     < RE_Portfolio_XI_metadata_line_29_____Helvetia_Schweizerische_VersicherungsmGesellschaft_in_Liechtenstein_AG_A_20250515 >									
	//        < BlO59nC63RsN2105DBTOk6XwQEHe1zu7gL99dBtAeJ5z5Gn5R6x4XplheQ0u3Vs1 >									
	//        < 1E-018 limites [ 994566143,702659 ; 1019227912,49957 ] >									
	//        < 0x0000000000000000000000000000000000000000000017281381D617BB126145 >									
	//     < RE_Portfolio_XI_metadata_line_30_____Hiscox_20250515 >									
	//        < 8W127Qgnkk128F7UYYrCWRpxhye6Rid6d42Q84yZ4qQ1hqfRXm7hiIwwk48447Oo >									
	//        < 1E-018 limites [ 1019227912,49957 ; 1078846253,8967 ] >									
	//        < 0x0000000000000000000000000000000000000000000017BB126145191E6CBFE1 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XI_metadata_line_31_____Hiscox_Ins_Co_Limited_A_A_20250515 >									
	//        < A882Gf3stw5cNo8KO2d962zRGtK5P1lj6z04mm3nHpeJ9AZh2Sv6r5Nn14XMke5A >									
	//        < 1E-018 limites [ 1078846253,8967 ; 1101825983,47766 ] >									
	//        < 0x00000000000000000000000000000000000000000000191E6CBFE119A76508BF >									
	//     < RE_Portfolio_XI_metadata_line_32_____Hiscox_Syndicates_Limited_20250515 >									
	//        < zfe849X8W6Mwyg5M1fi6h44cB49836hB5I3o68P99N63x50X4h2xD0OpNz0qLuHd >									
	//        < 1E-018 limites [ 1101825983,47766 ; 1148451235,99953 ] >									
	//        < 0x0000000000000000000000000000000000000000000019A76508BF1ABD4D8603 >									
	//     < RE_Portfolio_XI_metadata_line_33_____Hiscox_Syndicates_Limited_20250515 >									
	//        < t7pP2Vy9g8h6t1a1NL50M26VZ44fgM0O510r533eBAowJGaC31YwAeIm4p8v7w3s >									
	//        < 1E-018 limites [ 1148451235,99953 ; 1164744108,05645 ] >									
	//        < 0x000000000000000000000000000000000000000000001ABD4D86031B1E6A7929 >									
	//     < RE_Portfolio_XI_metadata_line_34_____Hiscox_Syndicates_Limited_20250515 >									
	//        < 0o37Nva4yOpB1rSKYT3jEHB0V7aMc06d7cerpS736y4JL6EG9E96jpK104YxqAQ1 >									
	//        < 1E-018 limites [ 1164744108,05645 ; 1223787655,74777 ] >									
	//        < 0x000000000000000000000000000000000000000000001B1E6A79291C7E57C6FA >									
	//     < RE_Portfolio_XI_metadata_line_35_____Hiscox_Syndicates_Limited_20250515 >									
	//        < AR30JyfUBtUMB0hL5qBB7ddoQrFp1DdR31Y2FpqEtI6Jh9nK35m6pB2k2wBJLenU >									
	//        < 1E-018 limites [ 1223787655,74777 ; 1249832336,60374 ] >									
	//        < 0x000000000000000000000000000000000000000000001C7E57C6FA1D1994CE70 >									
	//     < RE_Portfolio_XI_metadata_line_36_____Hiscox_Syndicates_Limited_20250515 >									
	//        < ovH75844WVH84zxbT647xdV425yc53WNF8z83kDCVtJ21vOU7eQ5h1uIJ2gi6D2A >									
	//        < 1E-018 limites [ 1249832336,60374 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001D1994CE701D5FFA7AF9 >									
	//     < RE_Portfolio_XI_metadata_line_37_____Hiscox_Syndicates_Limited_20250515 >									
	//        < GoGbBfYy3corIo8VjVvxw3X83vg6F97r8p4k97gu3VKc8mpYuH7HNuwb2Z97icfl >									
	//        < 1E-018 limites [ 1261643020,85112 ; 1284495587,87034 ] >									
	//        < 0x000000000000000000000000000000000000000000001D5FFA7AF91DE830BAF7 >									
	//     < RE_Portfolio_XI_metadata_line_38_____Hiscox_Syndicates_Limited_20250515 >									
	//        < u8HWB9j1q9CF7cgwo5Y7OH10f8n0F0L7x4vH6QrPgy71iECvCRVM0DO2S5ccBk0s >									
	//        < 1E-018 limites [ 1284495587,87034 ; 1345041522,12734 ] >									
	//        < 0x000000000000000000000000000000000000000000001DE830BAF71F51127E88 >									
	//     < RE_Portfolio_XI_metadata_line_39_____Hiscox_Syndicates_Limited&#160;&#160;&#160;&#160;_20250515 >									
	//        < Y04o3Zi826RQ11rMHEGCm8h8L40auB1EFqvln79UyKRu93EREKv2m9q4N9KeW2Ql >									
	//        < 1E-018 limites [ 1345041522,12734 ; 1384825398,98107 ] >									
	//        < 0x000000000000000000000000000000000000000000001F51127E88203E33DF6E >									
	//     < RE_Portfolio_XI_metadata_line_40_____Hiscox_Syndicates_Limited&#160;&#160;&#160;&#160;_20250515 >									
	//        < 5MDwmPS9Ei0w7Z57P02Tqo98sK432RaHA9dzp0Fh958cN706Zb8RdXMa080u2aze >									
	//        < 1E-018 limites [ 1384825398,98107 ; 1453938925,58985 ] >									
	//        < 0x00000000000000000000000000000000000000000000203E33DF6E21DA26BEC2 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}