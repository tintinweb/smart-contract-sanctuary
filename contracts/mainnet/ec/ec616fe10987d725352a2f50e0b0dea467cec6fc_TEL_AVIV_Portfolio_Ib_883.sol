pragma solidity 		^0.4.21	;						
										
	contract	TEL_AVIV_Portfolio_Ib_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	TEL_AVIV_Portfolio_Ib_883		"	;
		string	public		symbol =	"	TELAVIV883		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		742949791335499000000000000					;	
										
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
	//     < TEL_AVIV_Portfolio_I_metadata_line_1_____AIRPORT_CITY_20250515 >									
	//        < bzH5HK82276hJx7Qu0KBqpeu2mV1Tej8Xtm4yCh3I65Fs2VgL70jE1x7dZkGuyZ8 >									
	//        <  u =="0.000000000000000001" : ] 000000000000000.000000000000000000 ; 000000017829804.445288500000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000001B34C4 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_2_____ALONY_HETZ_20250515 >									
	//        < ip67jgI0CY5M26jvkm2e564m3aXv8XPkQCC3ZoGdtQCaa6n1W6Rd9oXH2Ce1RQ2g >									
	//        <  u =="0.000000000000000001" : ] 000000017829804.445288500000000000 ; 000000035206770.620516200000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000001B34C435B8A5 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_3_____AMOT _20250515 >									
	//        < 7fbfZ881g58U2d5Zy1rWovmnhM4N5lJ5NB9Xm7PmG9aQkaQoj5eqq64odnnupx2V >									
	//        <  u =="0.000000000000000001" : ] 000000035206770.620516200000000000 ; 000000053461882.464237800000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000035B8A551938C >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_4_____AZRIELI_GROUP_20250515 >									
	//        < ZJzs8zu2z27n2v65mtk9yip6g2Aw260U8HbWtYIYDijNZVLgbwNSGmMXDs44W1g7 >									
	//        <  u =="0.000000000000000001" : ] 000000053461882.464237800000000000 ; 000000072227855.591166300000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000051938C6E3602 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_5_____BAZAN _20250515 >									
	//        < XYAp8B0Pbt4WnEGW7342A79yslMEo563Up5F8nwY61619Q5h578B82csGJjleWT6 >									
	//        <  u =="0.000000000000000001" : ] 000000072227855.591166300000000000 ; 000000090677974.703951700000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000006E36028A5D15 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_6_____BEZEQ _20250515 >									
	//        < oZuc2X7ybsCBl641O7MXX409o0NlIsHU9GY37Huwyr8ZLIwA8b64V6t7Yut7yG5Y >									
	//        <  u =="0.000000000000000001" : ] 000000090677974.703951700000000000 ; 000000109626596.289989000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000008A5D15A746E4 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_7_____CELLCOM _20250515 >									
	//        < 5E58F4Gi0Rb7Lz2i00PXEAJ2glOLISb0yhG0WT6maq3MoHK77S93s5jaO55T5XQx >									
	//        <  u =="0.000000000000000001" : ] 000000109626596.289989000000000000 ; 000000128572084.913411000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000A746E4C42F78 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_8_____DELEK_DRILL_L_20250515 >									
	//        < EpzXzPJ57Gbe91nL2s335fdQU776ZLcsraSCGeM4udZCI1JTq8YDuTywX8sVA3Vq >									
	//        <  u =="0.000000000000000001" : ] 000000128572084.913411000000000000 ; 000000145849364.627172000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000C42F78DE8C68 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_9_____DELEK_GROUP_20250515 >									
	//        < 5Vyq38T2GLf0LLgsT592FK7U182B7NIPr9RQNPRuvG70ZIPxan1zY7mOXSCpK2Qi >									
	//        <  u =="0.000000000000000001" : ] 000000145849364.627172000000000000 ; 000000165166470.196802000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000DE8C68FC0627 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_10_____DISCOUNT _20250515 >									
	//        < D0Q14huvFn79o9Tt6gQ2aYyPvtc0CA341gs3gOB52T8hX22WaJNDEfGWP0op4hi4 >									
	//        <  u =="0.000000000000000001" : ] 000000165166470.196802000000000000 ; 000000184406591.142403000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000FC062711961D3 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < TEL_AVIV_Portfolio_I_metadata_line_11_____ELBIT_SYSTEMS_20250515 >									
	//        < B23ccOoQ8M5Ej5977FG0j456pFXaZzrC5b0y10y7ElTm2do6L725U1FT44nQZXct >									
	//        <  u =="0.000000000000000001" : ] 000000184406591.142403000000000000 ; 000000203784580.836843000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000011961D3136F35A >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_12_____FATTAL _20250515 >									
	//        < 2P7sStd9FYhI5D3H16B2zJmD9C2XRllCbpQYT0U09m57PZJjaxpdP9U60RKX0h58 >									
	//        <  u =="0.000000000000000001" : ] 000000203784580.836843000000000000 ; 000000222445116.792987000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000136F35A1536CA0 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_13_____FIBI_BANK_20250515 >									
	//        < PerqgA39O63xfo1qP842v744HBRR8I3ZPa5JQN0xB0G9YHbMXG897gkMSaA0vZgb >									
	//        <  u =="0.000000000000000001" : ] 000000222445116.792987000000000000 ; 000000240571321.416899000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001536CA016F152C >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_14_____FRUTAROM _20250515 >									
	//        < RdSXlRCaEtcDF1727L6xtMdDC2WORVvz7sI7RnJnA39Tl117pK0gq4D3i82uQE9C >									
	//        <  u =="0.000000000000000001" : ] 000000240571321.416899000000000000 ; 000000258189029.872720000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000016F152C189F717 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_15_____GAZIT_GLOBE_20250515 >									
	//        < 27TBh06Bszj78ZcdiT87Hp53D40JZ751A6vQss7Wl3XW1vLDBM4WSmFBt6BC4O53 >									
	//        <  u =="0.000000000000000001" : ] 000000258189029.872720000000000000 ; 000000276687263.860035000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000189F7171A630F6 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_16_____HAREL _20250515 >									
	//        < l7cMaDIyH9voimUI5C7b4bGTPAe50GVv4d14UE2HL6hEy348cNOVA8DD3Q3Y69M3 >									
	//        <  u =="0.000000000000000001" : ] 000000276687263.860035000000000000 ; 000000294500249.648784000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001A630F61C15F29 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_17_____ICL _20250515 >									
	//        < 9pGa1O155E82V7422dF36bV1r3i4di7r9hJ8nEInR7g1dkPpCHi0e2044n0Y2g7p >									
	//        <  u =="0.000000000000000001" : ] 000000294500249.648784000000000000 ; 000000312679698.426715000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001C15F291DD1C82 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_18_____ISRAEL_CORP_20250515 >									
	//        < N7sMQY3iYClCpoaqj0VXcqG7vh4TV6sM17Ia9hZ12qyVhi7hyKNz49Y25BT83KTq >									
	//        <  u =="0.000000000000000001" : ] 000000312679698.426715000000000000 ; 000000331644577.869794000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001DD1C821FA0CAA >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_19_____ISRAMCO_L_20250515 >									
	//        < KAR4a8o13W2EImz48TrqPXC65HR0mAoMI46oTuKRUtmNzYhD3vw1Tg67l8MB8i5J >									
	//        <  u =="0.000000000000000001" : ] 000000331644577.869794000000000000 ; 000000350635907.896545000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001FA0CAA2170727 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_20_____LEUMI _20250515 >									
	//        < iVYLX93OIHoWFVO1x7RiPOY67el3u2ptlNqM94bq1Xn5MEkrmE0NXfqaXZ0y2AC6 >									
	//        <  u =="0.000000000000000001" : ] 000000350635907.896545000000000000 ; 000000369859250.253827000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000021707272345C45 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < TEL_AVIV_Portfolio_I_metadata_line_21_____MAZOR_ROBOTICS_20250515 >									
	//        < sJ9UoYpZPcY14IX21x70aO2q59cRIN5uz577tn5vrUE8jxMXWUuLw5YwFH74fQDs >									
	//        <  u =="0.000000000000000001" : ] 000000369859250.253827000000000000 ; 000000387943952.211727000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002345C4524FF49B >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_22_____MELISRON _20250515 >									
	//        < K2Nrxb9HX07TV4YTYY5f1bR90omNThX9ZS30EnTXUZYQ8kZKfrnUBdGj0236SPvq >									
	//        <  u =="0.000000000000000001" : ] 000000387943952.211727000000000000 ; 000000405845119.799501000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000024FF49B26B4540 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_23_____MIZRAHI_TEFAHOT_20250515 >									
	//        < Y7NKM4oYfIes0b5N3uOTY9A9SK5ZQhsobCC13wwdnggwyp0eir6x1BgKce404g33 >									
	//        <  u =="0.000000000000000001" : ] 000000405845119.799501000000000000 ; 000000425207150.359787000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000026B4540288D08B >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_24_____NICE _20250515 >									
	//        < 00Q9lv13hz4Q43V6K91819NPTfJ34P2aBxdP3RwbfIcGWPCCa94S452eYU2vvY93 >									
	//        <  u =="0.000000000000000001" : ] 000000425207150.359787000000000000 ; 000000443638670.015076000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000288D08B2A4F05B >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_25_____OPKO_HEALTH_20250515 >									
	//        < IGt8ZuET1bzI33O0Aod8PC9J8s2Bh774uP86eZzszV9dhp9364DCVzriQX707Grw >									
	//        <  u =="0.000000000000000001" : ] 000000443638670.015076000000000000 ; 000000462727999.422327000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002A4F05B2C21120 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_26_____ORMAT_TECHNO_20250515 >									
	//        < t9qs6eu9iI16t6pSMTJXIvXjr72XV3MzqVkVDUhAtsUXRUNQwbwPlGvdZx3C0pD4 >									
	//        <  u =="0.000000000000000001" : ] 000000462727999.422327000000000000 ; 000000481836043.392780000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002C211202DF3934 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_27_____PARTNER _20250515 >									
	//        < cFzcr98G860f94ZPBHozwIqWpnbmjBAGnbh249Wa8072T6d02D8V2328XY14k5Pz >									
	//        <  u =="0.000000000000000001" : ] 000000481836043.392780000000000000 ; 000000499388176.606323000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002DF39342FA0182 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_28_____PAZ_OIL_20250515 >									
	//        < u67mL5I1C3u7Cr1nt1iJYUTjYKi02NpuRz4750T54YXr6y5Xf2G56j20BH23NkJ8 >									
	//        <  u =="0.000000000000000001" : ] 000000499388176.606323000000000000 ; 000000518439335.856793000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002FA0182317135E >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_29_____PERRIGO _20250515 >									
	//        < kAVq1HNl7tsuoevn67uG4jL5lSw6tT0i9I8XL98BVFRLXiitiIN5xlGPF6Be2QIu >									
	//        <  u =="0.000000000000000001" : ] 000000518439335.856793000000000000 ; 000000536742138.180214000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000317135E33300E6 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_30_____PHOENIX _20250515 >									
	//        < AQW8ARHKtf818T0YMzMhVpqLb788u4tK9Aqc86gW4spm8YvL45zyhl66DMG30IF3 >									
	//        <  u =="0.000000000000000001" : ] 000000536742138.180214000000000000 ; 000000555334212.329979000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000033300E634F5F6D >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < TEL_AVIV_Portfolio_I_metadata_line_31_____POALIM _20250515 >									
	//        < f4H758r9V6be98OFP2x7neD55Z3V9Ie66f56oLULBS0LMCMU3h6u5Vam20X2w83L >									
	//        <  u =="0.000000000000000001" : ] 000000555334212.329979000000000000 ; 000000573536940.450021000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000034F5F6D36B25DE >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_32_____SHUFERSAL _20250515 >									
	//        < 7rMK6GLEfMVPM274fZxcG0zNqEjderhmDZa63WcW132D3Zj21Uw0h7bjXJY5jYMW >									
	//        <  u =="0.000000000000000001" : ] 000000573536940.450021000000000000 ; 000000592313516.674927000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000036B25DE387CC78 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_33_____SODASTREAM _20250515 >									
	//        < jsSO3IlqmR45K7zLl0jKP69LNm9n84d7UDPTXX6W985aK925v04y5zU6V580deVN >									
	//        <  u =="0.000000000000000001" : ] 000000592313516.674927000000000000 ; 000000611688290.442397000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000387CC783A55CBD >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_34_____STRAUSS_GROUP_20250515 >									
	//        < 7yE0x3Hr98E5aHfp7jWwp1AH87arMK58ry1cVDbtJ3Z50GzUr3Cc6m6b41Rlwwg4 >									
	//        <  u =="0.000000000000000001" : ] 000000611688290.442397000000000000 ; 000000631157094.412311000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003A55CBD3C311BD >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_35_____TEVA _20250515 >									
	//        < 6i69PE1EOqZ2un5fyb834C63UF0oGnQdTFX693ek6vPq0Wa5Cw194AxfYP9BMr1f >									
	//        <  u =="0.000000000000000001" : ] 000000631157094.412311000000000000 ; 000000649577307.310899000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003C311BD3DF2D23 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_36_____TOWER _20250515 >									
	//        < gKi8Kgw9NQE0ghOal17YsRo1l2SE47dtu67q1cBGEUJO40UvU9Yv3qP72M8SV7mt >									
	//        <  u =="0.000000000000000001" : ] 000000649577307.310899000000000000 ; 000000668731259.517109000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003DF2D233FC6726 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_37_____COHEN_DEV_20250515 >									
	//        < cC379go9SA28qZ1GaBx0MkadkwkLJhDE2AZLr7k11egcHgf25mTEwoxd3CId5URW >									
	//        <  u =="0.000000000000000001" : ] 000000668731259.517109000000000000 ; 000000687658398.724933000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003FC67264194890 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_38_____DELEK_ENERGY_20250515 >									
	//        < OL0Y4u7kGf98F1zT80O4zKc3sxF0sDVIi7kHXB2B4jVWz8x080Cvp30d7s4WvQpx >									
	//        <  u =="0.000000000000000001" : ] 000000687658398.724933000000000000 ; 000000705378984.161863000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000419489043452AA >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_39_____NAPHTHA_20250515 >									
	//        < 60Owc7UEulNfIT20lH401ymd247169472NzdmS61nqjKr4I63298h29KhBa4c6W4 >									
	//        <  u =="0.000000000000000001" : ] 000000705378984.161863000000000000 ; 000000724119873.300513000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000043452AA450EB53 >									
	//     < TEL_AVIV_Portfolio_I_metadata_line_40_____TAMAR_20250515 >									
	//        < JVnIW5Y9Fdfr8Hp9eR76v5po1N41QvJb934Q1x8iahU88RBV9Pz9z597fnq4Lof8 >									
	//        <  u =="0.000000000000000001" : ] 000000724119873.300513000000000000 ; 000000742949791.335499000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000450EB5346DA6C3 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}