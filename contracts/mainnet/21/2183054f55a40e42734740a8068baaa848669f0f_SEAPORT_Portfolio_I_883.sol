pragma solidity 		^0.4.21	;						
										
	contract	SEAPORT_Portfolio_I_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	SEAPORT_Portfolio_I_883		"	;
		string	public		symbol =	"	SEAPORT883I		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1315013459513460000000000000					;	
										
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
	//     < SEAPORT_Portfolio_I_metadata_line_1_____Abakan_Spe_Value_20250515 >									
	//        < l8YQ7L17zYAReUoWyFSW82OGRtoAtms9Sm6wWMSAEYO7R1Qnp1lGYO68ZR077Aw0 >									
	//        < 1E-018 limites [ 1E-018 ; 34589487,3823024 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000000034C785 >									
	//     < SEAPORT_Portfolio_I_metadata_line_2_____Aleksandrovsk_Sakhalinsky_Sea_Port_20250515 >									
	//        < 99vOJKum36hA7nr46w0sOvlrco1T997yAO28gY6bFQY5GHLbRgPOolQN8L99IsV5 >									
	//        < 1E-018 limites [ 34589487,3823024 ; 69065378,9771162 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000034C7856962AA >									
	//     < SEAPORT_Portfolio_I_metadata_line_3_____Amderma_Maritime_Trade_Port_20250515 >									
	//        < HSCt9niAXx0R3vM21bfFT8onp7a89so8EFvVsA4s72aeRu1xpiVj6ne62MLCT3nN >									
	//        < 1E-018 limites [ 69065378,9771162 ; 118259276,627101 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000006962AAB47308 >									
	//     < SEAPORT_Portfolio_I_metadata_line_4_____Anadyr_Sea_Port_Ltd_20250515 >									
	//        < 76fr6XwcV6tP58xd3HmtcB81MBz94D1Y1E6E64tefjl0FT5EPs0w4ga49gmOtf48 >									
	//        < 1E-018 limites [ 118259276,627101 ; 154060140,389963 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000B47308EB13BE >									
	//     < SEAPORT_Portfolio_I_metadata_line_5_____Anadyr_Port_Spe_Value_20250515 >									
	//        < TawG6s5F520LBQT3tIDt3908YmHPn7JikvtE5LYOwW800E31J5b8qS04xNDg2j5Y >									
	//        < 1E-018 limites [ 154060140,389963 ; 182741903,899121 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000EB13BE116D78E >									
	//     < SEAPORT_Portfolio_I_metadata_line_6_____Maritime_Port_Administration_of_Novorossiysk_20250515 >									
	//        < 5Z511kCtrwC5v948l83E72907BtRIkQ3Ye5Kr8d1GgYz0t097cBp4i0tzl3hJ3LN >									
	//        < 1E-018 limites [ 182741903,899121 ; 212691228,411382 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000116D78E1448A83 >									
	//     < SEAPORT_Portfolio_I_metadata_line_7_____Anapa_Port_Spe_Value_20250515 >									
	//        < N8Gidl5Q4rS9l4mM45LWHSgS1bjkl5z14kLl8fGgOA0D4U214lgaGsQFH8vB13R5 >									
	//        < 1E-018 limites [ 212691228,411382 ; 254199183,730671 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001448A83183E08E >									
	//     < SEAPORT_Portfolio_I_metadata_line_8_____JSC_Arkhangelsk_Sea_Commercial_Port_20250515 >									
	//        < ax291UBF4355AmJug6KPBHM2t8mF5oYcrVtxgxZZapr724r6tZUs7D2Z54InHWPn >									
	//        < 1E-018 limites [ 254199183,730671 ; 286081042,088676 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000183E08E1B48668 >									
	//     < SEAPORT_Portfolio_I_metadata_line_9_____Arkhangelsk_Port_Spe_Value_20250515 >									
	//        < 6H3ACuiVfIaE252T1q66Tr7x1jmHl5PrVz5659G8MwZbGJnEYBWtw3Tdb8T7CQ7C >									
	//        < 1E-018 limites [ 286081042,088676 ; 325388661,988454 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001B486681F080F2 >									
	//     < SEAPORT_Portfolio_I_metadata_line_10_____Astrakhan_Sea_Commercial_Port_20250515 >									
	//        < TX6s7B5H15O4RDd5Aj8iru2Mc339vS9XQ3y2gY9S4u6M9206p62g75grb6PyIQeC >									
	//        < 1E-018 limites [ 325388661,988454 ; 352732232,607 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001F080F221A3A07 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_I_metadata_line_11_____Astrakhan_Port_Spe_Value_20250515 >									
	//        < 1KKEj55zo5m5HwWOAdbd25Yho2d1s85sxR0xFl4k3TA5MRn5S9bZdL591E0XBOC5 >									
	//        < 1E-018 limites [ 352732232,607 ; 371968714,510636 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000021A3A072379447 >									
	//     < SEAPORT_Portfolio_I_metadata_line_12_____JSC_Azov_Sea_Port_20250515 >									
	//        < 5zEm7mDZKQ5cRGpPCUfR26mgY0sC65bNG5b87LaynVztpDUaV2VYuX830YD649v7 >									
	//        < 1E-018 limites [ 371968714,510636 ; 390095899,323935 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000023794472533D36 >									
	//     < SEAPORT_Portfolio_I_metadata_line_13_____Barnaul_Port_Spe_Value_20250515 >									
	//        < 0HBCfiC5U8mtwx5v318AOPiTy75DbwI7QmseRH670M98KyhTwq5u8hb7I9HVDi5l >									
	//        < 1E-018 limites [ 390095899,323935 ; 408387567,146848 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002533D3626F2665 >									
	//     < SEAPORT_Portfolio_I_metadata_line_14_____Beringovsky_Port_Spe_Value_20250515 >									
	//        < Dq336GQ7NL2i0lU75Vzy5e39bTn8PUueFF0QP2DH9nEyOXofnDrDGEFG5Vh5fV8m >									
	//        < 1E-018 limites [ 408387567,146848 ; 436319523,963194 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000026F2665299C550 >									
	//     < SEAPORT_Portfolio_I_metadata_line_15_____Beryozovo_Port_Spe_Value_20250515 >									
	//        < 50hLrz6Af99y11Iq0qn38zj7pL7eCan4A61oppYy0E6TSU3JxmtVbtAjr097vb5Z >									
	//        < 1E-018 limites [ 436319523,963194 ; 472346127,958446 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000299C5502D0BE35 >									
	//     < SEAPORT_Portfolio_I_metadata_line_16_____Bratsk_Port_Spe_Value_20250515 >									
	//        < 13T59NVB20n165oZmQsdsX6i96JKsj1MwCO2EEVv33icRSrG19Euj4g5O1L00v4M >									
	//        < 1E-018 limites [ 472346127,958446 ; 501700566,632217 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002D0BE352FD88C9 >									
	//     < SEAPORT_Portfolio_I_metadata_line_17_____Bukhta_Nagayeva_Port_Spe_Value_20250515 >									
	//        < wP6mNJM5h62v2FQ0OTmlsgSz7mu9W1C99K4Qrkc905vlS8i40wi8Mgk73D6mUX5I >									
	//        < 1E-018 limites [ 501700566,632217 ; 528541201,703527 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002FD88C93267D68 >									
	//     < SEAPORT_Portfolio_I_metadata_line_18_____Cherepovets_Port_Spe_Value_20250515 >									
	//        < VmPzX5kQsq7t20o4AvhTqorkY1gUak6i1m2CES2yZ3slUETVHMg4r14Q4KvDed33 >									
	//        < 1E-018 limites [ 528541201,703527 ; 561756129,119174 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003267D683592BFD >									
	//     < SEAPORT_Portfolio_I_metadata_line_19_____De_Kastri_Port_Spe_Value_20250515 >									
	//        < 93GJzjI0H8d4SctOG3633P5Hr06G3PkfK5GCfgNGbbnj017K6kwbhoWqlQUUlCUq >									
	//        < 1E-018 limites [ 561756129,119174 ; 602361587,711232 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003592BFD397217F >									
	//     < SEAPORT_Portfolio_I_metadata_line_20_____State_Enterprise_Dikson_Sea_Trade_Port_20250515 >									
	//        < hf5Dsjz6k77aXPfilv9B2m7B3IbY44xT63UJUomVs77EoN1H7z1mhX09XMXi7f8F >									
	//        < 1E-018 limites [ 602361587,711232 ; 628215907,434235 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000397217F3BE94D7 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_I_metadata_line_21_____Dudinka_Port_Spe_Value_20250515 >									
	//        < 9bpj7CY2y0274f9fj8CV752f955nQTbgBk79p4AV5j3UyNN2Xni9H203mLoNAm85 >									
	//        < 1E-018 limites [ 628215907,434235 ; 664249187,620668 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003BE94D73F59057 >									
	//     < SEAPORT_Portfolio_I_metadata_line_22_____Dzerzhinsk_Port_Spe_Value_20250515 >									
	//        < z1kx9i5Ec3auS028Txg3B9z2r2XGnZynHoW6B2066rH2UqaCC8Io26JSTj1Tiho3 >									
	//        < 1E-018 limites [ 664249187,620668 ; 709092707,967714 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003F59057439FD57 >									
	//     < SEAPORT_Portfolio_I_metadata_line_23_____Egvekinot_Port_Spe_Value_20250515 >									
	//        < H4brHcn9VTt216yq5mLlrVspa4H90L0f1U9TWINFm505xdf1ZvJLl60cryq3Y36O >									
	//        < 1E-018 limites [ 709092707,967714 ; 734455461,126257 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000439FD57460B0AA >									
	//     < SEAPORT_Portfolio_I_metadata_line_24_____Ekonomiya_Port_Spe_Value_20250515 >									
	//        < 0Lrmw70Xq5f4UEWN8ze56PKle190J68mbx3rfNq1WZa82GitKcuG85wmQf6gc9Hv >									
	//        < 1E-018 limites [ 734455461,126257 ; 769322600,101612 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000460B0AA495E4A4 >									
	//     < SEAPORT_Portfolio_I_metadata_line_25_____Gelendzhgic_Port_Spe_Value_20250515 >									
	//        < 4Md4s1egr5OgL4r3TJ02n919UOdQQJf1j4unwj67zUJ1RcQ266RRSoc763O0B04z >									
	//        < 1E-018 limites [ 769322600,101612 ; 799897605,711594 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000495E4A44C48C01 >									
	//     < SEAPORT_Portfolio_I_metadata_line_26_____Sea_Port_Hatanga_20250515 >									
	//        < fNL7U5kU53G8YytTe0f4S9VMIWva0v5HldliI6kG7VLe046TD1O79qhg98rdP2zC >									
	//        < 1E-018 limites [ 799897605,711594 ; 845683113,73383 ] >									
	//        < 0x000000000000000000000000000000000000000000000000004C48C0150A68F7 >									
	//     < SEAPORT_Portfolio_I_metadata_line_27_____Igarka_Port_Authority_20250515 >									
	//        < y2s06Irb11CbWc9b5yq9867C97mpRy4unmLl56hD6d0w847N1E8Eal73RHGq4uZx >									
	//        < 1E-018 limites [ 845683113,73383 ; 880610166,209277 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000050A68F753FB459 >									
	//     < SEAPORT_Portfolio_I_metadata_line_28_____Irkutsk_Port_Spe_Value_20250515 >									
	//        < jjuk201RzNZ39TpfhAC3iKc6Xf4337cSdNl2fSP1cCe6Z93q3CCNufVoBs0mtXKF >									
	//        < 1E-018 limites [ 880610166,209277 ; 899978409,57312 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000053FB45955D4211 >									
	//     < SEAPORT_Portfolio_I_metadata_line_29_____Irtyshskiy_Port_Spe_Value_20250515 >									
	//        < 016gO3zpw4iaVH37NYs5H1kO30J9tG51fC3rXD8xxO6Xjlo9Bv2C5Yiv247hh433 >									
	//        < 1E-018 limites [ 899978409,57312 ; 922757793,000955 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000055D42115800443 >									
	//     < SEAPORT_Portfolio_I_metadata_line_30_____Kalach_na_Donu_Port_Spe_Value_20250515 >									
	//        < 8uOX13TDkG1W0SaP3KrXZ0YwPbJrs7C79wGR1YPQ9Sd69lfbVx6gHR4TpDf09z48 >									
	//        < 1E-018 limites [ 922757793,000955 ; 960657936,34675 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000058004435B9D902 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_I_metadata_line_31_____Kaliningrad_Port_Authorities_20250515 >									
	//        < V0bag60js6I6SfqW538onKUtPT69346npmtomHVbXj458mH8CS3NggBAWlBw9UuZ >									
	//        < 1E-018 limites [ 960657936,34675 ; 987430053,976926 ] >									
	//        < 0x000000000000000000000000000000000000000000000000005B9D9025E2B2DD >									
	//     < SEAPORT_Portfolio_I_metadata_line_32_____Kaluga_Port_Spe_Value_20250515 >									
	//        < f6trg3dDr8aae88MkTQkF559XvalvRRtOEZT5BBw6rwX1lNlxmonh9H9x29iFAWd >									
	//        < 1E-018 limites [ 987430053,976926 ; 1027805808,79615 ] >									
	//        < 0x000000000000000000000000000000000000000000000000005E2B2DD6204EA5 >									
	//     < SEAPORT_Portfolio_I_metadata_line_33_____Kandalaksha_Port_Spe_Value_20250515 >									
	//        < sWXO0xaK7fkAh82s9TmSwyozNR6AOgi4SrMPV2DyG3WfqfSRiTW02Wm5oK89YUNu >									
	//        < 1E-018 limites [ 1027805808,79615 ; 1075420583,15064 ] >									
	//        < 0x000000000000000000000000000000000000000000000000006204EA5668F62A >									
	//     < SEAPORT_Portfolio_I_metadata_line_34_____Kasimov_Port_Spe_Value_20250515 >									
	//        < pSdS0irYA991G0InokXYp87282239ml7uD7ZXVUpuatwtCIU045xKvI93ipM1Gaj >									
	//        < 1E-018 limites [ 1075420583,15064 ; 1095498326,97416 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000668F62A6879909 >									
	//     < SEAPORT_Portfolio_I_metadata_line_35_____Kazan_Port_Spe_Value_20250515 >									
	//        < v8eX7831F2sDQbEpTruxMj4vBzX9P02bR15r30slOP22wXtrK31MSwa9dp0tI2ug >									
	//        < 1E-018 limites [ 1095498326,97416 ; 1115140726,87138 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000068799096A591D9 >									
	//     < SEAPORT_Portfolio_I_metadata_line_36_____Khanty_Mansiysk_Port_Spe_Value_20250515 >									
	//        < 1U066GFeMWa0JF0777z10wvNPIl5yRRxMAV67kiSoLC2KiWSvmRi4f0nuKjOBuMu >									
	//        < 1E-018 limites [ 1115140726,87138 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000000000006A591D96EADB9D >									
	//     < SEAPORT_Portfolio_I_metadata_line_37_____Kholmsk_Port_Spe_Value_20250515 >									
	//        < zK26UZ019yJyP4ywHuI42YcUWatO34jvezs5en80nec3zpA4FgovHs14sOF0TfOh >									
	//        < 1E-018 limites [ 1160549414,78432 ; 1202640357,68869 ] >									
	//        < 0x000000000000000000000000000000000000000000000000006EADB9D72B1564 >									
	//     < SEAPORT_Portfolio_I_metadata_line_38_____Kolomna_Port_Spe_Value_20250515 >									
	//        < g7gc35EouNCtH8qx54qc8tTvI8S2D109iK4CK0q433IIPKJ03mU9Idx70wqRM6Hw >									
	//        < 1E-018 limites [ 1202640357,68869 ; 1247570179,81282 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000072B156476FA41A >									
	//     < SEAPORT_Portfolio_I_metadata_line_39_____Kolpashevo_Port_Spe_Value_20250515 >									
	//        < 4M6NAlTi73GRY35vIv7bvB95X8C0UN39C090nZv409lP0g26HDJ2DDN8yC1Vt5rH >									
	//        < 1E-018 limites [ 1247570179,81282 ; 1284416486,51369 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000076FA41A7A7DD31 >									
	//     < SEAPORT_Portfolio_I_metadata_line_40_____Korsakov_Port_Spe_Value_20250515 >									
	//        < h2Teu64dtajTo08bR9a86DDzlu3KOwLEPf7h7627zWDy9Eqf8k0PVc8IL5q1uM56 >									
	//        < 1E-018 limites [ 1284416486,51369 ; 1315013459,51346 ] >									
	//        < 0x000000000000000000000000000000000000000000000000007A7DD317D68D22 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}