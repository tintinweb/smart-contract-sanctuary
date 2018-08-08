pragma solidity 		^0.4.21	;						
										
	contract	FGRE_Portfolio_II_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	FGRE_Portfolio_II_883		"	;
		string	public		symbol =	"	FGRE883II		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		27616600125087200000000000000					;	
										
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
	//     < FGRE_Portfolio_II_metadata_line_1_____Caisse_Centrale_de_Reassurance_20580515 >									
	//        < qJH456shAVxlEf54A8FO7cJo4E9w0Xc1Rte2EJ1u73Z9Vw3pu1ne03ZgIn2o3E8m >									
	//        < 1E-018 limites [ 1E-018 ; 71629097,3929053 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000006D4C1E >									
	//     < FGRE_Portfolio_II_metadata_line_2_____CCR_FGRE_Fonds_de_Garantie_des_Risques_li&#233;s_a_l_Epandage_des_Boues_d_Epuration_Urbaines_et_Industrielles_i_20580515 >									
	//        < 79C907463mh7j2sL5iKHJMsFUzIWeh7K4Pyy71t11aRLJ3cj2Z9wDAn6r2jz05g6 >									
	//        < 1E-018 limites [ 71629097,3929053 ; 219337972,168712 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000006D4C1E14EAEE5 >									
	//     < FGRE_Portfolio_II_metadata_line_3_____CCR_FGRE_Fonds_de_Garantie_des_Risques_li&#233;s_a_l_Epandage_des_Boues_d_Epuration_Urbaines_et_Industrielles_ii_20580515 >									
	//        < 1DVsuw99psx9wE360Uz9fVsaaF33dLj6FP4Qt5D4g0K6m3Y9e1BmD0R6Z95zkuLZ >									
	//        < 1E-018 limites [ 219337972,168712 ; 1435018837,45658 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000014EAEE588DAA3C >									
	//     < FGRE_Portfolio_II_metadata_line_4_____FGRE__Cap_default_20580515 >									
	//        < eop5ro1ow1CAbTF1VGwIZFLLk77c6EuCYQ6zN6r71AW8JjKv5tv99G0i573BFOIM >									
	//        < 1E-018 limites [ 1435018837,45658 ; 1526318567,62157 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000088DAA3C918FA31 >									
	//     < FGRE_Portfolio_II_metadata_line_5_____FGRE__Cap_lim_20580515 >									
	//        < x3Phom69re0vLi72J8vbk2W5097YkKW8VdPSiGXrKQmgxwpM5w61iF55xru2b5y5 >									
	//        < 1E-018 limites [ 1526318567,62157 ; 2825094805,14306 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000918FA3110D6C0A9 >									
	//     < FGRE_Portfolio_II_metadata_line_6_____FGRE__Cap_ill_20580515 >									
	//        < VTi58x8VQ52xnxT150N4P2z57zS25Gm8BcnMqH58e9i1DXF95hIEw49f9f1S9o94 >									
	//        < 1E-018 limites [ 2825094805,14306 ; 3323729939,28347 ] >									
	//        < 0x00000000000000000000000000000000000000000000000010D6C0A913CF9C02 >									
	//     < FGRE_Portfolio_II_metadata_line_7_____FGRE__Tre_Cap_1_20580515 >									
	//        < 6J26UJqpL2eG9J17Id44fw675tiuAJ7090WMK8AVH1N2p9rI34r8An6SKgxo6GQd >									
	//        < 1E-018 limites [ 3323729939,28347 ; 3441598939,90094 ] >									
	//        < 0x00000000000000000000000000000000000000000000000013CF9C0214837696 >									
	//     < FGRE_Portfolio_II_metadata_line_8_____FGRE__Tre_Cap_2_20580515 >									
	//        < Q3S67TN6BpQcKXiWjTZEN10un2ftqh5t7tlf22Y8mYVKn78S0b7767C99LOv8Ao5 >									
	//        < 1E-018 limites [ 3441598939,90094 ; 3531740815,47801 ] >									
	//        < 0x00000000000000000000000000000000000000000000000014837696150D0242 >									
	//     < FGRE_Portfolio_II_metadata_line_9_____FGRE__Fac_Cap_1_20580515 >									
	//        < YdKJcopsJf3eBYyM9r69S2s3Cv4C23ovzE44g6b1eN01tKzKxeJ5xm9QW14fa1Fu >									
	//        < 1E-018 limites [ 3531740815,47801 ; 3635901445,63885 ] >									
	//        < 0x000000000000000000000000000000000000000000000000150D024215ABF201 >									
	//     < FGRE_Portfolio_II_metadata_line_10_____FGRE__Fac_Cap_2_20580515 >									
	//        < 6ym5BL1Sexqs8Kx29LGGZ5e77uIz2ACQcJ4I8SMnfWj544H1FD893l257sUhmF8K >									
	//        < 1E-018 limites [ 3635901445,63885 ; 4568661469,69768 ] >									
	//        < 0x00000000000000000000000000000000000000000000000015ABF2011B3B3963 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < FGRE_Portfolio_II_metadata_line_11_____FGRE__Cap_default_iii_origin_p_C_default_20580515 >									
	//        < 0XKML8TV7B9odO4D5Gb1Fd5m4754EsA65x4oxGi8hcCr5t2ij4V9b8in4VzP73sz >									
	//        < 1E-018 limites [ 4568661469,69768 ; 5629055858,9209 ] >									
	//        < 0x0000000000000000000000000000000000000000000000001B3B3963218D41F2 >									
	//     < FGRE_Portfolio_II_metadata_line_12_____FGRE__Cap_default_iii_origin_p_iii_default_20580515 >									
	//        < 0jkRj2MmTwQAl2A6V5i6xold1kcqdBH6423M38JNV8F8FwFiheyh98pCiMb03431 >									
	//        < 1E-018 limites [ 5629055858,9209 ; 6049295441,87584 ] >									
	//        < 0x000000000000000000000000000000000000000000000000218D41F2240E7E08 >									
	//     < FGRE_Portfolio_II_metadata_line_13_____FGRE__Cap_lim_iii_origin_p_C_default_20580515 >									
	//        < z09v8iK7s858Oco1v8d45O06GOid4O716s44txbfto66kP2Y6N0D2ywfGI7nWs87 >									
	//        < 1E-018 limites [ 6049295441,87584 ; 6895400277,11564 ] >									
	//        < 0x000000000000000000000000000000000000000000000000240E7E0829198BBC >									
	//     < FGRE_Portfolio_II_metadata_line_14_____FGRE__Cap_lim_iii_origin_p_iii_default_20580515 >									
	//        < aoj358690I3zh8Tq4FAnpfB5lQSB95r472on527a8OR4dG61WtbBG741DFAqq4Zc >									
	//        < 1E-018 limites [ 6895400277,11564 ; 8328045361,08831 ] >									
	//        < 0x00000000000000000000000000000000000000000000000029198BBC31A396B8 >									
	//     < FGRE_Portfolio_II_metadata_line_15_____FGRE__Cap_ill_iii_origin_p_C_default_20580515 >									
	//        < QdX9Km1HXjGJgYqo1xqla46W43FlR199LF09o1WTM6AD89OiPYK4eoLg4DcYE1o2 >									
	//        < 1E-018 limites [ 8328045361,08831 ; 9439303492,65989 ] >									
	//        < 0x00000000000000000000000000000000000000000000000031A396B838433BED >									
	//     < FGRE_Portfolio_II_metadata_line_16_____FGRE__Cap_ill_iii_origin_p_iii_default_20580515 >									
	//        < jv0Z4Y251GGad1lh34PRBKwl7lmUwY0MOL8TiV5o7U5X9s4FqAo4j7bh618ZALY3 >									
	//        < 1E-018 limites [ 9439303492,65989 ; 10541590279,1838 ] >									
	//        < 0x00000000000000000000000000000000000000000000000038433BED3ED530B4 >									
	//     < FGRE_Portfolio_II_metadata_line_17_____FGRE__Tre_Cap_3_20580515 >									
	//        < FD235ETy6VjNHv8QP8qb5y6Z5FI08g2eZ1o0sOXV7aNmM3d2lA24Y25ZAlXLam74 >									
	//        < 1E-018 limites [ 10541590279,1838 ; 10857051123,6721 ] >									
	//        < 0x0000000000000000000000000000000000000000000000003ED530B440B68B98 >									
	//     < FGRE_Portfolio_II_metadata_line_18_____FGRE__Tre_Cap_4_20580515 >									
	//        < LN59S23J8jkkrV41l9kpv5vW5PBi9V6tL97lxpC42549LtHbkX54FuNVdw4q63It >									
	//        < 1E-018 limites [ 10857051123,6721 ; 11060046599,4754 ] >									
	//        < 0x00000000000000000000000000000000000000000000000040B68B9841EC4AB4 >									
	//     < FGRE_Portfolio_II_metadata_line_19_____FGRE__Fac_Cap_3_20580515 >									
	//        < Uf6R2KE26Q5hwp0XQ92bwb1VQYa97f7atC1KNZA236aF97ImaV27Ty5o4cx2S7bv >									
	//        < 1E-018 limites [ 11060046599,4754 ; 11179474573,7217 ] >									
	//        < 0x00000000000000000000000000000000000000000000000041EC4AB442A28641 >									
	//     < FGRE_Portfolio_II_metadata_line_20_____FGRE__Fac_Cap_4_20580515 >									
	//        < 6e0Pzp56Ugq2hyL4S840hL9HKb913bZ9m0dd8kslj9X7pe9vCrUEWVvI1eT55Ynt >									
	//        < 1E-018 limites [ 11179474573,7217 ; 12150811562,5234 ] >									
	//        < 0x00000000000000000000000000000000000000000000000042A28641486CAAC4 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < FGRE_Portfolio_II_metadata_line_21_____FGRE__C_default_20580515 >									
	//        < Ux3NWNppH1RuPk0N75wDL33WBBmsb0ffR64W0h0u005u8ldtjqj07Z7vpK62k9uD >									
	//        < 1E-018 limites [ 12150811562,5234 ; 12878870143,632 ] >									
	//        < 0x000000000000000000000000000000000000000000000000486CAAC44CC398A6 >									
	//     < FGRE_Portfolio_II_metadata_line_22_____FGRE__Tre_C_1_20580515 >									
	//        < 6N3OVIrL4k076t3085DB79v19XZO2395hw51POg8A21A25UG0ziW5nrrl0wnzZ8m >									
	//        < 1E-018 limites [ 12878870143,632 ; 13197987234,1808 ] >									
	//        < 0x0000000000000000000000000000000000000000000000004CC398A64EAA87C3 >									
	//     < FGRE_Portfolio_II_metadata_line_23_____FGRE__Tre_C_2_20580515 >									
	//        < 47k50q7V0387qtMgp03OLDR59DABiry3jngMT0nbjbrmLo38UkjgH151gyL8vOtC >									
	//        < 1E-018 limites [ 13197987234,1808 ; 13647709269,9694 ] >									
	//        < 0x0000000000000000000000000000000000000000000000004EAA87C35158C06F >									
	//     < FGRE_Portfolio_II_metadata_line_24_____FGRE__Fac_C_1_20580515 >									
	//        < awA7jant85id1fKnunDFfi6Q8vZcG65LSegkV4p9ONQow434TU33YOsfxmDi9Xyk >									
	//        < 1E-018 limites [ 13647709269,9694 ; 13850646362,7421 ] >									
	//        < 0x0000000000000000000000000000000000000000000000005158C06F528E68BC >									
	//     < FGRE_Portfolio_II_metadata_line_25_____FGRE__Fac_C_2_20580515 >									
	//        < ta2ofDGjv9oI2kQw4v9NQNdJnhd6a8J6Hy68M2q79w5smV2BK6Otzs3mwCo2mWph >									
	//        < 1E-018 limites [ 13850646362,7421 ; 14018441531,3877 ] >									
	//        < 0x000000000000000000000000000000000000000000000000528E68BC538E71B9 >									
	//     < FGRE_Portfolio_II_metadata_line_26_____FGRE__IV_default_20580515 >									
	//        < QFc3Cfb208aATDv3WPF57w5ne7cNZca6i0a1U9sx6z32nKEwb3R0YRKNkF3GP955 >									
	//        < 1E-018 limites [ 14018441531,3877 ; 15707235010,5298 ] >									
	//        < 0x000000000000000000000000000000000000000000000000538E71B95D9F56AD >									
	//     < FGRE_Portfolio_II_metadata_line_27_____FGRE__Tre_iv_1_20580515 >									
	//        < qG3XDlAlmd69Y6kE5t52MEn6jrnAMvu2Z9zS42p04G20Wtcg28egynj8ozipno91 >									
	//        < 1E-018 limites [ 15707235010,5298 ; 15801136464,6251 ] >									
	//        < 0x0000000000000000000000000000000000000000000000005D9F56AD5E2E9EEE >									
	//     < FGRE_Portfolio_II_metadata_line_28_____FGRE__Tre_iv_2_20580515 >									
	//        < AD8TthMkjUn13ob1SOgcAp1EfQi92v85DvH1oz6m4uJZ439l2CluEvGHJ45nd1pm >									
	//        < 1E-018 limites [ 15801136464,6251 ; 18510047623,3186 ] >									
	//        < 0x0000000000000000000000000000000000000000000000005E2E9EEE6E54175A >									
	//     < FGRE_Portfolio_II_metadata_line_29_____FGRE__Fac_iv_1_20580515 >									
	//        < 6j7RiXl20TVGz37sg7vm23k7noG3d93k9cYCW7klrF4ASJ9H3A2C0elD7kqfZBz1 >									
	//        < 1E-018 limites [ 18510047623,3186 ; 19462887700,4856 ] >									
	//        < 0x0000000000000000000000000000000000000000000000006E54175A74020282 >									
	//     < FGRE_Portfolio_II_metadata_line_30_____FGRE__Fac_iv_2_20580515 >									
	//        < s1q9pe2xpoz2kD94LEuO29W7i9hrT2EGR09Fu7251La3Q96pMp0b9w0ZWui2bJsI >									
	//        < 1E-018 limites [ 19462887700,4856 ; 19651486962,9987 ] >									
	//        < 0x000000000000000000000000000000000000000000000000740202827521CA18 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < FGRE_Portfolio_II_metadata_line_31_____FGRE__Cx_default_20580515 >									
	//        < vaJ191Tj2pk8wc60nH8ztlcSYF11GsQ39o9eoLFXPO368JKrTE79Z9S9AQbkhof0 >									
	//        < 1E-018 limites [ 19651486962,9987 ; 20586488342,4875 ] >									
	//        < 0x0000000000000000000000000000000000000000000000007521CA187AB47D02 >									
	//     < FGRE_Portfolio_II_metadata_line_32_____FGRE__Tre_Cx_1_20580515 >									
	//        < 0TeI5ECMIJcje19mNR7nLW7oAp04UpS3224waK6VCqaMjH9ZMHQ3YmGMrxV009M3 >									
	//        < 1E-018 limites [ 20586488342,4875 ; 20691762282,7993 ] >									
	//        < 0x0000000000000000000000000000000000000000000000007AB47D027B551FA4 >									
	//     < FGRE_Portfolio_II_metadata_line_33_____FGRE__Tre_Cx_2_20580515 >									
	//        < L781lq0mdkA6c7V3M12wB236y2Gjd47o67FKYqD2QZ4Y3u75pI0BN5Gn87bCplaJ >									
	//        < 1E-018 limites [ 20691762282,7993 ; 20915421507,0282 ] >									
	//        < 0x0000000000000000000000000000000000000000000000007B551FA47CAA6687 >									
	//     < FGRE_Portfolio_II_metadata_line_34_____FGRE__Fac_Cx_1_20580515 >									
	//        < N8GF9znNSkfZP0m5nX32isqojwVb31EC69Jc3B6K7Z6O1OQz2DTXEfu1tov652e4 >									
	//        < 1E-018 limites [ 20915421507,0282 ; 21080512678,7107 ] >									
	//        < 0x0000000000000000000000000000000000000000000000007CAA66877DA64F44 >									
	//     < FGRE_Portfolio_II_metadata_line_35_____FGRE__Fac_Cx_2_20580515 >									
	//        < UW8wwNjDVF6Xh2G55b5k6U4Fr8FFAFC5xrJk3I13KKZQJQHs62yMy6m2n498DV97 >									
	//        < 1E-018 limites [ 21080512678,7107 ; 22322567851,328 ] >									
	//        < 0x0000000000000000000000000000000000000000000000007DA64F44850D8911 >									
	//     < FGRE_Portfolio_II_metadata_line_36_____FGRE__VIII_default_20580515 >									
	//        < yKz9Wt4X7u5mMNlesqGUJ0s41Ss9u289oDB1Iq5w6U1J4ALx307nw2zE7Fm5SUKU >									
	//        < 1E-018 limites [ 22322567851,328 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000000000850D89118B15375D >									
	//     < FGRE_Portfolio_II_metadata_line_37_____FGRE__Tre_viii_1_20580515 >									
	//        < U5H67WN5b3pXnXcnXRJ668qdKjf3q8N12rfn681fyxj1Rcr1P0fPmSUC64VJnWs4 >									
	//        < 1E-018 limites [ 23334234534,5793 ; 24872776038,9251 ] >									
	//        < 0x0000000000000000000000000000000000000000000000008B15375D9440D824 >									
	//     < FGRE_Portfolio_II_metadata_line_38_____FGRE__Tre_viii_2_20580515 >									
	//        < nG8OlLfN7KxHjEP0eHKYJWXxv5w7f6eWs2gX3X0n4073OFGNB7qz9g1A840Q7O7K >									
	//        < 1E-018 limites [ 24872776038,9251 ; 26252611921,4392 ] >									
	//        < 0x0000000000000000000000000000000000000000000000009440D8249C7A4E88 >									
	//     < FGRE_Portfolio_II_metadata_line_39_____FGRE__Fac_viii_1_20580515 >									
	//        < 9VkF505j12DzLwmihDcN6xB2WE38qFK1lUt427svq0OJe0kTX7fY2134rMIXKuan >									
	//        < 1E-018 limites [ 26252611921,4392 ; 27184179220,2758 ] >									
	//        < 0x0000000000000000000000000000000000000000000000009C7A4E88A207C402 >									
	//     < FGRE_Portfolio_II_metadata_line_40_____FGRE__Fac_viii_2_20580515 >									
	//        < b9k1tF01h18x578hIwRE9PeQaOhAaFonbku7tQJ406E7ZDq89yvaSNlX6Vii4922 >									
	//        < 1E-018 limites [ 27184179220,2758 ; 27616600125,0872 ] >									
	//        < 0x000000000000000000000000000000000000000000000000A207C402A49B966D >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}