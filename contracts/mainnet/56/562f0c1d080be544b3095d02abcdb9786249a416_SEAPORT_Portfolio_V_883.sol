pragma solidity 		^0.4.21	;						
										
	contract	SEAPORT_Portfolio_V_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	SEAPORT_Portfolio_V_883		"	;
		string	public		symbol =	"	SEAPORT883V		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		926816166179938000000000000					;	
										
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
	//     < SEAPORT_Portfolio_V_metadata_line_1_____Gelendzhgic_Port_Spe_Value_20230515 >									
	//        < YXkQDNBZ2zu8UeeGvNs229Bn1iF33hqm5y5tIZFt1g59oEKq265pVfErR1Aox8Yf >									
	//        < 1E-018 limites [ 1E-018 ; 19700512,1623823 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000756C9A84 >									
	//     < SEAPORT_Portfolio_V_metadata_line_2_____Hatanga Port of Hatanga_Port_Spe_Value_20230515 >									
	//        < 5j5h1tnAZC78QQF951I0C0CK5GJ5MEVX7V5rjjIx4Qou6TJHj4v9u46059L7z10s >									
	//        < 1E-018 limites [ 19700512,1623823 ; 43633702,1775054 ] >									
	//        < 0x00000000000000000000000000000000000000000000000756C9A8410413C0DD >									
	//     < SEAPORT_Portfolio_V_metadata_line_3_____Igarka Port of Igarka_Port_Spe_Value_20230515 >									
	//        < sr3tm7GPzioBdFx7t50tv61m9o2ppn5j9SWc2x17Zmjp8r1f86A9HY2YTsO8kYNb >									
	//        < 1E-018 limites [ 43633702,1775054 ; 65764616,6539869 ] >									
	//        < 0x000000000000000000000000000000000000000000000010413C0DD187FCD955 >									
	//     < SEAPORT_Portfolio_V_metadata_line_4_____Igarka_Port_Authority_20230515 >									
	//        < 2t35ZxX6MAf3T5150lY4rySdrtNC7mRA1aTBo4D9yikHFn6FmhkIfKMp9qky7QWf >									
	//        < 1E-018 limites [ 65764616,6539869 ; 90138831,533778 ] >									
	//        < 0x0000000000000000000000000000000000000000000000187FCD95521944F305 >									
	//     < SEAPORT_Portfolio_V_metadata_line_5_____Igarka_Port_Authority_20230515 >									
	//        < o4Kkuu6ReZRdUhE8MGX4YyxLjlScxVUzTf0WkQ5oaRrBQ3qOAVw8g2y6uno51kF1 >									
	//        < 1E-018 limites [ 90138831,533778 ; 109686050,709904 ] >									
	//        < 0x000000000000000000000000000000000000000000000021944F30528DC7A382 >									
	//     < SEAPORT_Portfolio_V_metadata_line_6_____Irkutsk_Port_Spe_Value_20230515 >									
	//        < rjZc9xnDvoe7uz2EBkuMn8dZFfR6ZiBJc34Xg4O2S0D9t1ETd50a1Zsk6I7c7v49 >									
	//        < 1E-018 limites [ 109686050,709904 ; 133737440,63301 ] >									
	//        < 0x000000000000000000000000000000000000000000000028DC7A38231D2325B3 >									
	//     < SEAPORT_Portfolio_V_metadata_line_7_____Irtyshskiy_Port_Spe_Value_20230515 >									
	//        < 2rKI9jpPGp412RNJ5P28Fa273bFm23V3IUeWTNv1LaJ67KVChUsBE75fxn90M944 >									
	//        < 1E-018 limites [ 133737440,63301 ; 158208227,118916 ] >									
	//        < 0x000000000000000000000000000000000000000000000031D2325B33AEFE9AAB >									
	//     < SEAPORT_Portfolio_V_metadata_line_8_____Joint_Stock_Company_Nakhodka_Commercial_Sea_Port_20230515 >									
	//        < YAqvdHkws2m4q17pfOHheku5L77JaM59qZjIul6JI47u6D2ZU6Nc54Hp1WBFvGo4 >									
	//        < 1E-018 limites [ 158208227,118916 ; 183862710,319518 ] >									
	//        < 0x00000000000000000000000000000000000000000000003AEFE9AAB447E83D2B >									
	//     < SEAPORT_Portfolio_V_metadata_line_9_____Joint_Stock_Company_Nakhodka_Commercial_Sea_Port_20230515 >									
	//        < tJ5OM47V05P15J07Gp4gJge1dx2Tlx9RZgD0VMKsH2FMI4VwYIeoJuNazDplxjrm >									
	//        < 1E-018 limites [ 183862710,319518 ; 205261373,769363 ] >									
	//        < 0x0000000000000000000000000000000000000000000000447E83D2B4C7740214 >									
	//     < SEAPORT_Portfolio_V_metadata_line_10_____JSC_Arkhangelsk_Sea_Commercial_Port_20230515 >									
	//        < gSU3Yy9L15h8V2Zamj3yl4TwwyV6QI73vkc7WS7L5YN56cAKGAICYV28jRF7Qch3 >									
	//        < 1E-018 limites [ 205261373,769363 ; 225109272,426007 ] >									
	//        < 0x00000000000000000000000000000000000000000000004C774021453DC17F7E >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_V_metadata_line_11_____JSC_Arkhangelsk_Sea_Commercial_Port_20230515 >									
	//        < KV1oB572HUY4Xk1E14ELRQtCLUIm3ZuPTSamefuG2qUOyC9uiqCwGQ5T3QDp33T7 >									
	//        < 1E-018 limites [ 225109272,426007 ; 251274073,934363 ] >									
	//        < 0x000000000000000000000000000000000000000000000053DC17F7E5D9B5D115 >									
	//     < SEAPORT_Portfolio_V_metadata_line_12_____JSC_Azov_Sea_Port_20230515 >									
	//        < XkbShBP57CXHfK915s2IE8v7f73XPSQ1PJ924o25W48CcbRuGK8aU3A9qwOkZb4L >									
	//        < 1E-018 limites [ 251274073,934363 ; 275314628,366666 ] >									
	//        < 0x00000000000000000000000000000000000000000000005D9B5D11566900CAA8 >									
	//     < SEAPORT_Portfolio_V_metadata_line_13_____JSC_Azov_Sea_Port_20230515 >									
	//        < bXwXrUPCCe5M9v7rRND539u7S8e157DYf45iR8HQNYhsT4ol796KzaF6t82gQwI9 >									
	//        < 1E-018 limites [ 275314628,366666 ; 291639672,755782 ] >									
	//        < 0x000000000000000000000000000000000000000000000066900CAA86CA4ED51F >									
	//     < SEAPORT_Portfolio_V_metadata_line_14_____JSC_Novoroslesexport_20230515 >									
	//        < kfPEEdsGdZPb9Di9A16ewkSCWW3CH4wtCS5s0yZT3k6uAIGsy42vfS1nGZdB8Izx >									
	//        < 1E-018 limites [ 291639672,755782 ; 319651003,135844 ] >									
	//        < 0x00000000000000000000000000000000000000000000006CA4ED51F77144BB0D >									
	//     < SEAPORT_Portfolio_V_metadata_line_15_____JSC_Novoroslesexport_20230515 >									
	//        < 9dZTgYh202Bix5b95QA715fU8La2ZflCkE37i3dFkP8NNQLrYwVG1fgQBvaQ1yeo >									
	//        < 1E-018 limites [ 319651003,135844 ; 347486562,186463 ] >									
	//        < 0x000000000000000000000000000000000000000000000077144BB0D8172E6C4E >									
	//     < SEAPORT_Portfolio_V_metadata_line_16_____JSC_Yeysk_Sea_Port_20230515 >									
	//        < K0mcdlW9zI4vb6jbeHBxcCZ4k5p30UeqL3LvW1w4T2oI5wss3sljt1mPkf7pzyUJ >									
	//        < 1E-018 limites [ 347486562,186463 ; 372417716,896553 ] >									
	//        < 0x00000000000000000000000000000000000000000000008172E6C4E8ABC8589D >									
	//     < SEAPORT_Portfolio_V_metadata_line_17_____JSC_Yeysk_Sea_Port_20230515 >									
	//        < 4hzv7bE438KBW9O2i80yzCTF85bE1f1mjc5C4G76M59oa73l73seIR14QEd6212h >									
	//        < 1E-018 limites [ 372417716,896553 ; 395047810,385356 ] >									
	//        < 0x00000000000000000000000000000000000000000000008ABC8589D932AB20E2 >									
	//     < SEAPORT_Portfolio_V_metadata_line_18_____Kalach_na_Donu_Port_Spe_Value_20230515 >									
	//        < q9H2FNyT0KJIEsivGpTQI6Llqd81E52gG0974k7Q706YB4jFDC6XoLvJP4Y8mcil >									
	//        < 1E-018 limites [ 395047810,385356 ; 420592665,428759 ] >									
	//        < 0x0000000000000000000000000000000000000000000000932AB20E29CAED7BE2 >									
	//     < SEAPORT_Portfolio_V_metadata_line_19_____Kaliningrad Port of Kaliningrad_Port_Spe_Value_20230515 >									
	//        < 37kmnDOIUM5QAoPc2GD2TEoONOEBfJ6XFQbe12XuONLt0oP5lWnoyZcF09FjA73C >									
	//        < 1E-018 limites [ 420592665,428759 ; 439885667,552474 ] >									
	//        < 0x00000000000000000000000000000000000000000000009CAED7BE2A3DEC44D7 >									
	//     < SEAPORT_Portfolio_V_metadata_line_20_____Kaliningrad_Port_Authorities_20230515 >									
	//        < r9FZQn5OZq2Gn4L7gOji52YS072042X587hSR1RBmJsy7oEAP0hvvM0eDe60o6Hu >									
	//        < 1E-018 limites [ 439885667,552474 ; 463796200,156979 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A3DEC44D7ACC70D8A3 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_V_metadata_line_21_____Kaliningrad_Port_Authorities_20230515 >									
	//        < 9D2Rhw5xfZioCO27R3LsK3y3Xyss5OLqB5VvTgq67TM3poamVbVPozWwB6Mi38iB >									
	//        < 1E-018 limites [ 463796200,156979 ; 479007571,628296 ] >									
	//        < 0x0000000000000000000000000000000000000000000000ACC70D8A3B271B8E9E >									
	//     < SEAPORT_Portfolio_V_metadata_line_22_____Kaluga_Port_Spe_Value_20230515 >									
	//        < qcS0FPy2hoX85Fx4cWiM71K2i8RmPso96Vng94P5OLTqCic0l3R7Kf3gI9NSetWX >									
	//        < 1E-018 limites [ 479007571,628296 ; 500834058,449992 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B271B8E9EBA9342208 >									
	//     < SEAPORT_Portfolio_V_metadata_line_23_____Kandalaksha Port of Kandalaksha_Port_Spe_Value_20230515 >									
	//        < 9oFcHMc50X9z9QwKKkBd6M7pxlj0GPtTV16tUo9drA3l76qykA6qHnzj8zH1cSLm >									
	//        < 1E-018 limites [ 500834058,449992 ; 521437883,921742 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BA9342208C2403135C >									
	//     < SEAPORT_Portfolio_V_metadata_line_24_____Kandalaksha_Port_Spe_Value_20230515 >									
	//        < 20uHStHkNs3Ea19TO1o26C0BO4XPVp1J02N8mq9xLPg6psxcYsMZRw86y10qrCMh >									
	//        < 1E-018 limites [ 521437883,921742 ; 542573965,901628 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C2403135CCA1FE2D62 >									
	//     < SEAPORT_Portfolio_V_metadata_line_25_____Kasimov_Port_Spe_Value_20230515 >									
	//        < 42Jw1A79tJSwOm3l2z13iE7e5P7r5h67SWso6zPZ20x4AT331Kd3GXT45FD0GQ57 >									
	//        < 1E-018 limites [ 542573965,901628 ; 558526527,143129 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CA1FE2D62D0113DA9E >									
	//     < SEAPORT_Portfolio_V_metadata_line_26_____Kazan_Port_Spe_Value_20230515 >									
	//        < CO9b9HP9Dff9naRm9OH22M0DltaUCK67r1uLdig9mnS60Vru0FwVYh421liapKpz >									
	//        < 1E-018 limites [ 558526527,143129 ; 578673784,685111 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D0113DA9ED792A2118 >									
	//     < SEAPORT_Portfolio_V_metadata_line_27_____Kerch_Port_Spe_Value_20230515 >									
	//        < Ww7Zj77mc61R12Hp6dX31pjRn82ypipj6ftXXulr3RpyYEb4gNHoO495swWtVVvo >									
	//        < 1E-018 limites [ 578673784,685111 ; 605692154,529751 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D792A2118E1A34E3D0 >									
	//     < SEAPORT_Portfolio_V_metadata_line_28_____Kerchenskaya_Port_Spe_Value_20230515 >									
	//        < pXZJ4sHJ4WWV093KU4TO24b22N0J8a526v55qJdHwSE780xml258xHsa0U7ane1z >									
	//        < 1E-018 limites [ 605692154,529751 ; 630564105,210962 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E1A34E3D0EAE74798D >									
	//     < SEAPORT_Portfolio_V_metadata_line_29_____Kerchenskaya_Port_Spe_Value_I_20230515 >									
	//        < JC2vK7Lm8ElVNCR3VxLl37Iw4s3U7s70Zx96ph87EVeRWxui1EVegd5gw36VQN53 >									
	//        < 1E-018 limites [ 630564105,210962 ; 659488743,286901 ] >									
	//        < 0x0000000000000000000000000000000000000000000000EAE74798DF5ADBF84C >									
	//     < SEAPORT_Portfolio_V_metadata_line_30_____Khanty_Mansiysk_Port_Spe_Value_20230515 >									
	//        < 4r084JmA9rT6z1BBZy6mPAy4mnOH4Oss51M0o8xFjNnpV0YP5FGVw99vR1247OFV >									
	//        < 1E-018 limites [ 659488743,286901 ; 682317572,146876 ] >									
	//        < 0x0000000000000000000000000000000000000000000000F5ADBF84CFE2EDFF92 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_V_metadata_line_31_____Kholmsk Port of Kholmsk_Port_Spe_Value_20230515 >									
	//        < 1r002CJdNKXPItWsGa1fhatGKLJA07B6P9Sx7xFu7h0fXxrG8EgwG2uD0u0ZV4Ts >									
	//        < 1E-018 limites [ 682317572,146876 ; 706113212,169304 ] >									
	//        < 0x000000000000000000000000000000000000000000000FE2EDFF921070C34374 >									
	//     < SEAPORT_Portfolio_V_metadata_line_32_____Kholmsk_Port_Spe_Value_20230515 >									
	//        < 3XUDiuo89221F5te0rnfhD29cTpKAB83Wf58i2h1ZonF4tEvw88xHgvp506BF6JH >									
	//        < 1E-018 limites [ 706113212,169304 ; 734858201,81138 ] >									
	//        < 0x000000000000000000000000000000000000000000001070C34374111C18A309 >									
	//     < SEAPORT_Portfolio_V_metadata_line_33_____Kolomna_Port_Spe_Value_20230515 >									
	//        < 5Sp4Js16d33nOw2SPTX1a0O6615GJ1o7MBJaztQ3A14TdYEnU8Y2y6emu84m7qX4 >									
	//        < 1E-018 limites [ 734858201,81138 ; 757553568,878122 ] >									
	//        < 0x00000000000000000000000000000000000000000000111C18A30911A35F04CB >									
	//     < SEAPORT_Portfolio_V_metadata_line_34_____Kolpashevo_Port_Spe_Value_20230515 >									
	//        < 79XmUAcxc80kAhm57jrZ37JwgN5RW8130xog67Av07xM8Fv0eJDhqQkwTHet44aj >									
	//        < 1E-018 limites [ 757553568,878122 ; 779877983,505221 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A35F04CB12286F5F42 >									
	//     < SEAPORT_Portfolio_V_metadata_line_35_____Korsakov Port of Korsakov_Port_Spe_Value_20230515 >									
	//        < TolJTfwU9G20q5iQrLayFro93FuiV8BDepL10A0z8HeU6DJLYn3M6fukDFO6RMNl >									
	//        < 1E-018 limites [ 779877983,505221 ; 809465030,878833 ] >									
	//        < 0x0000000000000000000000000000000000000000000012286F5F4212D8C99FA3 >									
	//     < SEAPORT_Portfolio_V_metadata_line_36_____Korsakov_Port_Spe_Value_20230515 >									
	//        < 7aqR1m3ecejfZOh6kjeyVq03hP2aZ9W9HQBiIpmuxfrWa6H91RI0qtOq4FTZHW5Q >									
	//        < 1E-018 limites [ 809465030,878833 ;  ] >									
	//        < 0x0000000000000000000000000000000000000000000012D8C99FA3134175714F >									
	//     < SEAPORT_Portfolio_V_metadata_line_37_____Krasnoyarsk_Port_Spe_Value_20230515 >									
	//        < 49Puo5T3813ASRt31G7LcBy6Ll4hr46K33mbUXp7hQ84yx7l08Dj97c1492Md112 >									
	//        < 1E-018 limites [ 827025938,83848 ; 851416004,493967 ] >									
	//        < 0x00000000000000000000000000000000000000000000134175714F13D2D5BAB5 >									
	//     < SEAPORT_Portfolio_V_metadata_line_38_____Kronshtadt Port of Kronshtadt_Port_Spe_Value_20230515 >									
	//        < X3MS55Qy634Q0H7HSSAp8C4zkg46yal5JYQ388T8zCFlAzDJ0UZ53AyD34W8M75E >									
	//        < 1E-018 limites [ 851416004,493967 ; 878206498,187373 ] >									
	//        < 0x0000000000000000000000000000000000000000000013D2D5BAB5147284C74E >									
	//     < SEAPORT_Portfolio_V_metadata_line_39_____Kronshtadt_Port_Spe_Value_20230515 >									
	//        < U35UY2rdGsCb4a3lKNJR186YAoAbCiPdzoT22Qnvsd03L1oQiUi73O2P40awjF4m >									
	//        < 1E-018 limites [ 878206498,187373 ; 905499642,938257 ] >									
	//        < 0x00000000000000000000000000000000000000000000147284C74E151532CFF9 >									
	//     < SEAPORT_Portfolio_V_metadata_line_40_____Labytnangi_Port_Spe_Value_20230515 >									
	//        < EhN9RPX63T7r306rI957iKzEiJ2piCNAjQ3i1491S8ap735lAzd09h5tfgefABbU >									
	//        < 1E-018 limites [ 905499642,938257 ; 926816166,179938 ] >									
	//        < 0x00000000000000000000000000000000000000000000151532CFF91594413EDD >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}