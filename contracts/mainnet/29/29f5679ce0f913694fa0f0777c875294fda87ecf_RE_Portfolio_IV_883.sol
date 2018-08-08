pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_IV_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_IV_883		"	;
		string	public		symbol =	"	RE883IV		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1286737478908320000000000000					;	
										
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
	//     < RE_Portfolio_IV_metadata_line_1_____Ark_Syndicate_Management_Limited_20250515 >									
	//        < GNK77qUw5nah0bVnAR6K96cg0y176f3N56yy9l5037es113KkxZ91MQ6i0wU7ws7 >									
	//        < 1E-018 limites [ 1E-018 ; 33233233,2929992 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000C615E5B5 >									
	//     < RE_Portfolio_IV_metadata_line_2_____Ark_Syndicate_Management_Limited_20250515 >									
	//        < bhGU2V2uwRMiIg7H9X7jwaw06437iSTfJ1DUFJzVRNOZubV77p6HC3C454m5u005 >									
	//        < 1E-018 limites [ 33233233,2929992 ; 56512602,1085473 ] >									
	//        < 0x00000000000000000000000000000000000000000000000C615E5B5150D76526 >									
	//     < RE_Portfolio_IV_metadata_line_3_____Ark_Syndicate_Management_Limited_20250515 >									
	//        < 0966mB9LBI8sRJ48K9E1p3q1t86M1106Kog5ewl8DW7GF04l33z2iFo1RiL40bS5 >									
	//        < 1E-018 limites [ 56512602,1085473 ; 93152756,5213228 ] >									
	//        < 0x0000000000000000000000000000000000000000000000150D7652622B3BD578 >									
	//     < RE_Portfolio_IV_metadata_line_4_____Ark_Syndicate_Management_Limited_20250515 >									
	//        < n93Nc33HhleZfZHKY1U2HST89Zaq7PD0Zzh18ds6Y1b0ZVT1390kvKOh83weQc0y >									
	//        < 1E-018 limites [ 93152756,5213228 ; 107851101,880834 ] >									
	//        < 0x000000000000000000000000000000000000000000000022B3BD578282D7BAA0 >									
	//     < RE_Portfolio_IV_metadata_line_5_____Ark_Syndicate_Management_Limited_20250515 >									
	//        < b26vmyq4pxJ6M6Q672b3r9Hz12nixaL8TsURft2A7nvJ6K40m16MJ8Kg9O88g57C >									
	//        < 1E-018 limites [ 107851101,880834 ; 170318758,593458 ] >									
	//        < 0x0000000000000000000000000000000000000000000000282D7BAA03F72DCF07 >									
	//     < RE_Portfolio_IV_metadata_line_6_____Artis_Group_20250515 >									
	//        < dGr6S1T35w70AUsC0A4Dk8BurwXAHmVR7gV30q1N3HJ996a1UjkLX8Tk2RLSSY4y >									
	//        < 1E-018 limites [ 170318758,593458 ; 200430677,593728 ] >									
	//        < 0x00000000000000000000000000000000000000000000003F72DCF074AAA8F363 >									
	//     < RE_Portfolio_IV_metadata_line_7_____Artis_Group_20250515 >									
	//        < sfRoP1CWA8ITVJ458XyvA06Phv0KzxmnUmK9xIJMbt0F3xAU479O9iPwYpP97BW2 >									
	//        < 1E-018 limites [ 200430677,593728 ; 246257644,7963 ] >									
	//        < 0x00000000000000000000000000000000000000000000004AAA8F3635BBCF5A73 >									
	//     < RE_Portfolio_IV_metadata_line_8_____Ascot_Underwriting_Limited_20250515 >									
	//        < 25fAKnhY57s0QI1u2Kp1KH2uq8D0TNC7Ix3XnaxVu45Yek6sO3V010g9gfWZn805 >									
	//        < 1E-018 limites [ 246257644,7963 ; 315699955,468848 ] >									
	//        < 0x00000000000000000000000000000000000000000000005BBCF5A73759B7E90E >									
	//     < RE_Portfolio_IV_metadata_line_9_____Ascot_Underwriting_Limited_20250515 >									
	//        < 6o6Utc5bk15euaVkZ7DTaebNGk1UzH77Jp6Fx2qxjeBtN7826TiWAqFVs2QImB1W >									
	//        < 1E-018 limites [ 315699955,468848 ; 345515317,012035 ] >									
	//        < 0x0000000000000000000000000000000000000000000000759B7E90E80B6E8AA9 >									
	//     < RE_Portfolio_IV_metadata_line_10_____Asia_CapitaL_Rereinsurance_group_pte_Limited_Am_Am_20250515 >									
	//        < S0BAWavYHkixv3FmKSJX4o385OjyuG4nD8x2Bl37KAM6NN5OQl6FBK0MZwB39MLR >									
	//        < 1E-018 limites [ 345515317,012035 ; 417699154,358107 ] >									
	//        < 0x000000000000000000000000000000000000000000000080B6E8AA99B9AE561F >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_IV_metadata_line_11_____Aspen_Insurance_Holdings_Limited_20250515 >									
	//        < ncIBKNkx06tEz50Bb0KH6wEkX5RP30XwcJGIgch3FzVKTFQN9jn4f9OTDxrY9VbT >									
	//        < 1E-018 limites [ 417699154,358107 ; 434329542,732928 ] >									
	//        < 0x00000000000000000000000000000000000000000000009B9AE561FA1CCE4B95 >									
	//     < RE_Portfolio_IV_metadata_line_12_____Aspen_Insurance_UK_Limited_A_A_20250515 >									
	//        < 66g20ollYBow0DQ67N7qi5YlXzdRyN9WaL700Y1AXCb0763iRZI13pkx8FjRd38Y >									
	//        < 1E-018 limites [ 434329542,732928 ; 445834677,879017 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A1CCE4B95A6161BCFF >									
	//     < RE_Portfolio_IV_metadata_line_13_____Aspen_Managing_Agency_Limited_20250515 >									
	//        < 9kwf2FyXdLl9O3OkTv4QUTS33Y8tNZ3nH3bRd04y8xNFH6e7938BiXbxuXCBRfz4 >									
	//        < 1E-018 limites [ 445834677,879017 ; 491843738,404566 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A6161BCFFB739DFE44 >									
	//     < RE_Portfolio_IV_metadata_line_14_____Aspen_Managing_Agency_Limited_20250515 >									
	//        < 0tN5A17tlVAC40ksVor267d57HhJB0bwYsHfY6loZ7Mgq3wCswG92Y35ysbpbKm0 >									
	//        < 1E-018 limites [ 491843738,404566 ; 504405119,006281 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B739DFE44BBE7D2390 >									
	//     < RE_Portfolio_IV_metadata_line_15_____Aspen_Managing_Agency_Limited_20250515 >									
	//        < GO1QB0HJkz74wdfZyWGA0bXFbbpQP9OXF9h46am9CUuhUslCjX1JIKZjR6wtD6AG >									
	//        < 1E-018 limites [ 504405119,006281 ; 564261471,246337 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BBE7D2390D2342AF28 >									
	//     < RE_Portfolio_IV_metadata_line_16_____Assicurazioni_Generali_SPA_A_20250515 >									
	//        < R3R7DZvZiZLBuPGgWp6Mp5IF49g2Cs28q3iqQ187MUIPfoY372Y50ttFL8XY5N41 >									
	//        < 1E-018 limites [ 564261471,246337 ; 575032246,721798 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D2342AF28D63759554 >									
	//     < RE_Portfolio_IV_metadata_line_17_____Assicurazioni_Generalli_Spa_20250515 >									
	//        < 13n0ANWi89iZ1P68eNJ29156449Q9bC1HquHnK145hS55ZdTEX1psH8CKfQ1iuy3 >									
	//        < 1E-018 limites [ 575032246,721798 ; 601358654,525638 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D63759554E00607E60 >									
	//     < RE_Portfolio_IV_metadata_line_18_____Assurances_Mutuelles_De_France_Ap_A_20250515 >									
	//        < AI393JLT74408s029gIg23Cj2IcJ5AX9VddR5mSIgX8GLx0y9g1CHG9EidQU3nRP >									
	//        < 1E-018 limites [ 601358654,525638 ; 624452202,696774 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E00607E60E8A0673A1 >									
	//     < RE_Portfolio_IV_metadata_line_19_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 6S7227YRsaBZ684bB7ov8Za6boNgpB744C2v4ny0J6aNVRLUWPSl262blC7YI94C >									
	//        < 1E-018 limites [ 624452202,696774 ; 643038877,043383 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E8A0673A1EF8CF774C >									
	//     < RE_Portfolio_IV_metadata_line_20_____Asta_Managing_Agency_Limited_20250515 >									
	//        < F4D77bz7KJNtyMiN7lh0dokp8gANkKTcV1D8OhMgl9Of1jaBs3MwEe2TDi6XWAKG >									
	//        < 1E-018 limites [ 643038877,043383 ; 699352562,34391 ] >									
	//        < 0x000000000000000000000000000000000000000000000EF8CF774C104877549E >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_IV_metadata_line_21_____Asta_Managing_Agency_Limited_20250515 >									
	//        < LftlGQ8ABEzLOWuxBMcgX52SuCJt6er7xER8zfIe5I5zA68ibiGqWWz8P68y57n1 >									
	//        < 1E-018 limites [ 699352562,34391 ; 741743264,010354 ] >									
	//        < 0x00000000000000000000000000000000000000000000104877549E1145226875 >									
	//     < RE_Portfolio_IV_metadata_line_22_____Asta_Managing_Agency_Limited_20250515 >									
	//        < ZmJx1npTDGYL7BsMJMouXMZTVznSe4N3W9no2FqzdHCQn9iHVcakAeUayHhD0KxT >									
	//        < 1E-018 limites [ 741743264,010354 ; 758213668,448121 ] >									
	//        < 0x00000000000000000000000000000000000000000000114522687511A74E4030 >									
	//     < RE_Portfolio_IV_metadata_line_23_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 543y486VlEuGSna98wnEpgn1x6o8s6yKctZrUz7vUj8GY253vA5689a2JcPD9yVL >									
	//        < 1E-018 limites [ 758213668,448121 ; 771595164,020047 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A74E403011F710CAE6 >									
	//     < RE_Portfolio_IV_metadata_line_24_____Asta_Managing_Agency_Limited_20250515 >									
	//        < r3U6NyOl6kE797vafUX44OK86KtsK9G326a1te97PR51lVwD1V4Ni1vrj6m74ftx >									
	//        < 1E-018 limites [ 771595164,020047 ; 820866271,535796 ] >									
	//        < 0x0000000000000000000000000000000000000000000011F710CAE6131CBE8945 >									
	//     < RE_Portfolio_IV_metadata_line_25_____Asta_Managing_Agency_Limited_20250515 >									
	//        < zdNa9kA870ND7JTy25rrQe1f8BEnqbp0janxMWfp8nnY1j9pX990rig356SDKmyy >									
	//        < 1E-018 limites [ 820866271,535796 ; 832162888,135598 ] >									
	//        < 0x00000000000000000000000000000000000000000000131CBE8945136013CE21 >									
	//     < RE_Portfolio_IV_metadata_line_26_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 9IBX1W05z7kXE6viPk0w69bRDngQ84C3RyS8FijXLKVE55DKs6KbWGga0v3Sn80m >									
	//        < 1E-018 limites [ 832162888,135598 ; 853826333,353964 ] >									
	//        < 0x00000000000000000000000000000000000000000000136013CE2113E133996B >									
	//     < RE_Portfolio_IV_metadata_line_27_____Asta_Managing_Agency_Limited_20250515 >									
	//        < H3LLWhD3RZF7Qhcw9Ps1gawwS6CSC6Sb25b093D34308d6aw024cL8aTIvFUrH0n >									
	//        < 1E-018 limites [ 853826333,353964 ; 873606943,744548 ] >									
	//        < 0x0000000000000000000000000000000000000000000013E133996B14571A6A5A >									
	//     < RE_Portfolio_IV_metadata_line_28_____Asta_Managing_Agency_Limited_20250515 >									
	//        < Zz0KWuhROZ6G0019574A3LH6C1fnSU8Ufd2474C0Z3NeZ7tp54b137BJiULrv0dM >									
	//        < 1E-018 limites [ 873606943,744548 ; 926867203,013495 ] >									
	//        < 0x0000000000000000000000000000000000000000000014571A6A5A15948F1F21 >									
	//     < RE_Portfolio_IV_metadata_line_29_____Asta_Managing_Agency_Limited_20250515 >									
	//        < Y0R7uX28Tm9OyXs3QsNWWU7BJu2PYi9FI4243GY7jZ2F4N9m0W91m82c0XZjEPAn >									
	//        < 1E-018 limites [ 926867203,013495 ; 943650367,1903 ] >									
	//        < 0x0000000000000000000000000000000000000000000015948F1F2115F89832A3 >									
	//     < RE_Portfolio_IV_metadata_line_30_____Asta_Managing_Agency_Limited_20250515 >									
	//        < QX6v1t8Jwv4WU6y0Z6SYADzW55BnD96qz2K7e6Opx61p9GgEDip7Q4qH21c355BH >									
	//        < 1E-018 limites [ 943650367,1903 ; 964042863,975243 ] >									
	//        < 0x0000000000000000000000000000000000000000000015F89832A3167224ADB1 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_IV_metadata_line_31_____Asta_Managing_Agency_Limited_20250515 >									
	//        < Of4pSWtPyUQ2VN8EpyQR2l8ssd28Vs94woyA2udkUOCn1C3pYMVl6q0tGpYI4K0G >									
	//        < 1E-018 limites [ 964042863,975243 ; 1012544844,12417 ] >									
	//        < 0x00000000000000000000000000000000000000000000167224ADB117933CD3B0 >									
	//     < RE_Portfolio_IV_metadata_line_32_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 7j215s65589GN9ZU2QmUUA50J7n24ja04n9xlV98eU1q2Kup59px1zN684vfK90r >									
	//        < 1E-018 limites [ 1012544844,12417 ; 1030763908,61855 ] >									
	//        < 0x0000000000000000000000000000000000000000000017933CD3B017FFD4E9C1 >									
	//     < RE_Portfolio_IV_metadata_line_33_____Asta_Managing_Agency_Limited_20250515 >									
	//        < zTqCw74u1QbCbnBUuLNaF93f0em0404L7Cfu5C2sSwv2NyfPe7ty0OGZ3p3SE0du >									
	//        < 1E-018 limites [ 1030763908,61855 ; 1064233725,87595 ] >									
	//        < 0x0000000000000000000000000000000000000000000017FFD4E9C118C753CD1F >									
	//     < RE_Portfolio_IV_metadata_line_34_____Asta_Managing_Agency_Limited_20250515 >									
	//        < Zgw7uai87T9aytL220y8DYs1DV89CdAVq58z0e3fWFfy3YEJng8w44mUGyg9u6id >									
	//        < 1E-018 limites [ 1064233725,87595 ; 1080233240,99136 ] >									
	//        < 0x0000000000000000000000000000000000000000000018C753CD1F1926B11FB7 >									
	//     < RE_Portfolio_IV_metadata_line_35_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 9q1687xuSI2i4k02EpX54mAG4VvAd51w8W2vMG9Gd4lud53JNS8H2p3U60U6Li20 >									
	//        < 1E-018 limites [ 1080233240,99136 ; 1093559904,41456 ] >									
	//        < 0x000000000000000000000000000000000000000000001926B11FB719761FFF9D >									
	//     < RE_Portfolio_IV_metadata_line_36_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 4AgVi9OFdzIqTS6tp1Q6OQtslObQxYUIN8qxMBb2OH0A4878K4Q2b1G9ZZk5IpId >									
	//        < 1E-018 limites [ 1093559904,41456 ;  ] >									
	//        < 0x0000000000000000000000000000000000000000000019761FFF9D1A400DE845 >									
	//     < RE_Portfolio_IV_metadata_line_37_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 61stanSI9tYMGV31mzg2qru375J3K86mzAp20lL7OumeZHB1b1im53UnT2AevMH4 >									
	//        < 1E-018 limites [ 1127438024,49399 ; 1159792529,58135 ] >									
	//        < 0x000000000000000000000000000000000000000000001A400DE8451B00E6F6D2 >									
	//     < RE_Portfolio_IV_metadata_line_38_____Asta_Managing_Agency_Limited_20250515 >									
	//        < dSoSW0glrN7tk3f78wsuQDn3108u82l7W8MHs6UPI1uflTX8HQMD9z3oEnTovDe1 >									
	//        < 1E-018 limites [ 1159792529,58135 ; 1181038175,10479 ] >									
	//        < 0x000000000000000000000000000000000000000000001B00E6F6D21B7F893F1A >									
	//     < RE_Portfolio_IV_metadata_line_39_____Asta_Managing_Agency_Limited_20250515 >									
	//        < i7r131cOFs0zsf7Lc915ke695qbjq864CBF9lDkC9nm48P62xU4CBVssi8aFln5t >									
	//        < 1E-018 limites [ 1181038175,10479 ; 1238241050,28727 ] >									
	//        < 0x000000000000000000000000000000000000000000001B7F893F1A1CD47DE838 >									
	//     < RE_Portfolio_IV_metadata_line_40_____Asta_Managing_Agency_Limited_20250515 >									
	//        < f720wEA3DNcKbmzLwBsvBT5e3x5sA05Ol4JYBwoWr56Nh3MaPtcp7T5aePRxvphs >									
	//        < 1E-018 limites [ 1238241050,28727 ; 1286737478,90832 ] >									
	//        < 0x000000000000000000000000000000000000000000001CD47DE8381DF58D95A6 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}