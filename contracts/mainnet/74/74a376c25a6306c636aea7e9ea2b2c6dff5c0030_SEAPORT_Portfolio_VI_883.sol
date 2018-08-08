pragma solidity 		^0.4.21	;						
										
	contract	SEAPORT_Portfolio_VI_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	SEAPORT_Portfolio_VI_883		"	;
		string	public		symbol =	"	SEAPORT883VI		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		897688033763432000000000000					;	
										
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
	//     < SEAPORT_Portfolio_VI_metadata_line_1_____Lazarev Port of Lazarev_Port_Spe_Value_20230515 >									
	//        < PD8HMPRz8f9Nn9Y75JRiUWHlv2Nb13BXJeTKG4rz66l6sFEE383yz6Y332h83cFr >									
	//        < 1E-018 limites [ 1E-018 ; 20532396,7569184 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000007A61F56F >									
	//     < SEAPORT_Portfolio_VI_metadata_line_2_____Lazarev_Port_Spe_Value_20230515 >									
	//        < L7qjH51lFJQpiKTHAAcn97fkc27WT1546DP27YLI7Pw6tc7o14rxMZ6pJg8XYlTz >									
	//        < 1E-018 limites [ 20532396,7569184 ; 40731936,343651 ] >									
	//        < 0x0000000000000000000000000000000000000000000000007A61F56FF2C80296 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_3_____Lomonosov Port of Lomonosov_Port_Spe_Value_20230515 >									
	//        < Do6m66AwvssG7WjUa5hn1w0E851b283W603mCcz5EuPOFNvzyZjJ4MKVDzP116Um >									
	//        < 1E-018 limites [ 40731936,343651 ; 67176822,8351274 ] >									
	//        < 0x00000000000000000000000000000000000000000000000F2C8029619067B45F >									
	//     < SEAPORT_Portfolio_VI_metadata_line_4_____Lomonosov_Port_Authority_20230515 >									
	//        < PkkNg3Q3JKY5G3DqK6Ohyp3GIGv2Hjr0PYaC05nhHA7F8dbZR6EhJ0XhE4W66SyU >									
	//        < 1E-018 limites [ 67176822,8351274 ; 84556181,1374236 ] >									
	//        < 0x000000000000000000000000000000000000000000000019067B45F1F7FE8035 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_5_____Lomonosov_Port_Authority_20230515 >									
	//        < lGrgWI1P4QEpAv1I6R1A77YKAr4c903v6ofkdH81cx24hSDwGpm6mGTNZT5C8JuI >									
	//        < 1E-018 limites [ 84556181,1374236 ; 102257108,640016 ] >									
	//        < 0x00000000000000000000000000000000000000000000001F7FE80352617FF904 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_6_____Magadan Port of Magadan_Port_Spe_Value_20230515 >									
	//        < 47YQ9iu0RJQeV2O056w98824IFXwYq1dD9N3deudsX4AR9MVZ09b7Y5Fu5VyOOaT >									
	//        < 1E-018 limites [ 102257108,640016 ; 120014173,090999 ] >									
	//        < 0x00000000000000000000000000000000000000000000002617FF9042CB571A51 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_7_____Magadan_Port_Authority_20230515 >									
	//        < 0F94hlL37925Ydm62Ch6c57yZW53nOH56Q6ViE90TQ15bjaZdS8q35VX5nD2Jg62 >									
	//        < 1E-018 limites [ 120014173,090999 ; 141679491,296472 ] >									
	//        < 0x00000000000000000000000000000000000000000000002CB571A5134C79C13D >									
	//     < SEAPORT_Portfolio_VI_metadata_line_8_____Magadan_Port_Authority_20230515 >									
	//        < cGag5JW4j14Wq747b3o0f4U5w2B6NpJSHjghO36v9jK2eRG3RhTXOPzwoHag4p6I >									
	//        < 1E-018 limites [ 141679491,296472 ; 156875714,936206 ] >									
	//        < 0x000000000000000000000000000000000000000000000034C79C13D3A70D5A19 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_9_____Mago Port of Mago_Port_Spe_Value_20230515 >									
	//        < I3k2ND4zIYv3u367M5H9X68Ay5k31g91dperA80VZgtW7pVt6b89paO3a5ZUciAX >									
	//        < 1E-018 limites [ 156875714,936206 ; 183619302,033957 ] >									
	//        < 0x00000000000000000000000000000000000000000000003A70D5A1944674D3CF >									
	//     < SEAPORT_Portfolio_VI_metadata_line_10_____Mago_Port_Spe_Value_20230515 >									
	//        < I2R7459dLjmny74njI3SokVNFr1x73U0aJVY33ew4I9169e19IO59woBX1q5KC18 >									
	//        < 1E-018 limites [ 183619302,033957 ; 199605969,514197 ] >									
	//        < 0x000000000000000000000000000000000000000000000044674D3CF4A5BE8BCB >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_VI_metadata_line_11_____Makhachkala Port of Makhachkala_Port_Spe_Value_20230515 >									
	//        < y8Kt2KqN7TiiasqexF1718dPCaIw9dg7WSPW39Mpmr7E8WfX8uaBsrQ5v00d76fp >									
	//        < 1E-018 limites [ 199605969,514197 ; 224120220,607068 ] >									
	//        < 0x00000000000000000000000000000000000000000000004A5BE8BCB537DC5320 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_12_____Makhachkala_Port_Spe_Value_20230515 >									
	//        < 9Ir0ZQ0lqdby37549n79i7NJ5KD09p569Q9Q0T5u9nZMPiSZqkg2BEoqgD8zs2e6 >									
	//        < 1E-018 limites [ 224120220,607068 ; 251407023,780672 ] >									
	//        < 0x0000000000000000000000000000000000000000000000537DC53205DA80AE9E >									
	//     < SEAPORT_Portfolio_VI_metadata_line_13_____Makhachkala_Sea_Trade_Port_20230515 >									
	//        < 4xI5A1US2Qlk46s3qjp1OQ0P5vWGnsXqyK43vDbnHTdyC6J99CHl92JhG0z1N5PL >									
	//        < 1E-018 limites [ 251407023,780672 ; 279869542,404284 ] >									
	//        < 0x00000000000000000000000000000000000000000000005DA80AE9E6842709F4 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_14_____Makhachkala_Sea_Trade_Port_20230515 >									
	//        < zzmr89iUg39k1P2bWEGlXUEoP42OzX5Crnh5DP4AvUs2FOHYvTVboem85NUR24Ho >									
	//        < 1E-018 limites [ 279869542,404284 ; 299727968,195181 ] >									
	//        < 0x00000000000000000000000000000000000000000000006842709F46FA849787 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_15_____Marine_Administration_of_Chukotka_Ports_20230515 >									
	//        < 5bTCGbmQ7CLVT6A7j9x0yYoLksXw7nryG123NJI5M10beVK7zDI9sW30ULZUDQ8Y >									
	//        < 1E-018 limites [ 299727968,195181 ; 318614495,138317 ] >									
	//        < 0x00000000000000000000000000000000000000000000006FA84978776B17251D >									
	//     < SEAPORT_Portfolio_VI_metadata_line_16_____Marine_Administration_of_Chukotka_Ports_I_20230515 >									
	//        < 1n5FcrZkjA9aWSk1qfC8yZmKbfty9FK9B2SKmq0DGVD89Tp92MMsjcog4i9rIx5w >									
	//        < 1E-018 limites [ 318614495,138317 ; 336805404,997074 ] >									
	//        < 0x000000000000000000000000000000000000000000000076B17251D7D7844547 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_17_____Marine_Administration_of_Vladivostok_Port_Posyet_Branch_20230515 >									
	//        < glHj16pG5KvPJBnN0ld0I27o4h79Mh02H47aTiD8WMj49h4mRqSzr41arMaQWMX2 >									
	//        < 1E-018 limites [ 336805404,997074 ; 363384885,833866 ] >									
	//        < 0x00000000000000000000000000000000000000000000007D7844547875F156FB >									
	//     < SEAPORT_Portfolio_VI_metadata_line_18_____Marine_Administration_of_Vladivostok_Port_Posyet_Branch_20230515 >									
	//        < L6r32k9Ogy671clrHvY22EvhCnrhC5O2suMi3MUd7SD4Et23TtY9l2a9DoBu0P65 >									
	//        < 1E-018 limites [ 363384885,833866 ; 378734314,14678 ] >									
	//        < 0x0000000000000000000000000000000000000000000000875F156FB8D16EB56A >									
	//     < SEAPORT_Portfolio_VI_metadata_line_19_____Maritime_Port_Administration_of_Novorossiysk_20230515 >									
	//        < y497KmmXDs1bhg6MEox4drF822B5IGr8g8cW5Md0YikIHI5P5NO1hQ1oPJF4U29C >									
	//        < 1E-018 limites [ 378734314,14678 ; 393987869,152679 ] >									
	//        < 0x00000000000000000000000000000000000000000000008D16EB56A92C59C957 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_20_____Maritime_Port_Administration_of_Novorossiysk_20230515 >									
	//        < pQ7g63Ze6ig84FJsPm2jy2cs7s6e7YzKJE4cgjoJ424Tbh76b0dsqM9k4zGc2Lgu >									
	//        < 1E-018 limites [ 393987869,152679 ; 421129513,397691 ] >									
	//        < 0x000000000000000000000000000000000000000000000092C59C9579CE20A61F >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_VI_metadata_line_21_____0_20230515 >									
	//        < KMLX1KTCk3oQ6JVNJLXs5607w7e50Pm7D28r2ji4jqv272RC1DJHDIOUN6Q0b3ga >									
	//        < 1E-018 limites [ 421129513,397691 ; 450545884,295621 ] >									
	//        < 0x00000000000000000000000000000000000000000000009CE20A61FA7D767801 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_22_____Mezen Port of Mezen_Port_Spe_Value_20230515 >									
	//        < mvX1MIvGTMH1TT5Fn3G5TNkPnTq5E2A0kO976MYH772CAK0kV9qrWMw8Q3rowh3u >									
	//        < 1E-018 limites [ 450545884,295621 ; 467171474,097526 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A7D767801AE08F1B05 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_23_____Mezen_Port_Authority_20230515 >									
	//        < ZW995x9Xy5J0lW5811I6zNEDOYRloNpbf8XfF0HNmeMOizc8Vmqby1P9SA9m9yHh >									
	//        < 1E-018 limites [ 467171474,097526 ; 496690418,528729 ] >									
	//        < 0x0000000000000000000000000000000000000000000000AE08F1B05B908170B0 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_24_____Mezen_Port_Authority_20230515 >									
	//        < p6huN5H4V9uz6m0uN4ZvQN21QJrjZdh1eooiA2fHnBA3p63s46091z7fvdhXBnzK >									
	//        < 1E-018 limites [ 496690418,528729 ; 512311320,080516 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B908170B0BED9D0B5C >									
	//     < SEAPORT_Portfolio_VI_metadata_line_25_____Moscow_Port_Spe_Value_20230515 >									
	//        < 984L9nD18627PeP0jVqVbM54pdjmJ303pSFNb4CQruc8fWM1qZ4y0l0aLTHRM742 >									
	//        < 1E-018 limites [ 512311320,080516 ; 535107340,275707 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BED9D0B5CC757D02BF >									
	//     < SEAPORT_Portfolio_VI_metadata_line_26_____Murmansk Port of Murmansk_Port_Spe_Value_20230515 >									
	//        < G5aBqVP8uqpj3U51Eepp4Bn941RfClw60iPG1pfJ9Yy8Vq2B88W2KU2LStcw9f66 >									
	//        < 1E-018 limites [ 535107340,275707 ; 561975331,392672 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C757D02BFD15A24FC7 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_27_____Murmansk_Port_Authority_20230515 >									
	//        < 7Uw3188q29mT248QXMSRE286T7r1i4D651Z912eyFgyqRiPhjd77wJwPb872R08C >									
	//        < 1E-018 limites [ 561975331,392672 ; 577376937,201808 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D15A24FC7D716F4C0C >									
	//     < SEAPORT_Portfolio_VI_metadata_line_28_____Murmansk_Port_Authority_20230515 >									
	//        < 8R1AUnG2eL969a47563eJA6yN6qhUTv6VmmlNoEWA6DaRj2e4QH4A4sZfFkB6pif >									
	//        < 1E-018 limites [ 577376937,201808 ; 602581742,51462 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D716F4C0CE07AAC71F >									
	//     < SEAPORT_Portfolio_VI_metadata_line_29_____Murom_Port_Spe_Value_20230515 >									
	//        < xoqE7pBvY4rRk5X47KN8p2jWp9sK3m96dHnHKH4ewDSsnf6VDIM708h4v7uCibOO >									
	//        < 1E-018 limites [ 602581742,51462 ; 620757257,508426 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E07AAC71FE740069AA >									
	//     < SEAPORT_Portfolio_VI_metadata_line_30_____Nakhodka Port of Nakhodka_Port_Spe_Value_20230515 >									
	//        < A41e5CZ9sx2cTiUa26X2jrCfZ6829unduT5gi8nFC1gIqI7eCbG1392956yC2R2s >									
	//        < 1E-018 limites [ 620757257,508426 ; 645761923,903174 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E740069AAF090A817A >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_VI_metadata_line_31_____Naryan_Mar Port of Naryan_Mar_Port_Spe_Value_20230515 >									
	//        < Ub3rxaNfeVOLsH0TgZUOZhSFO5NmZ4dbDqVqv0dE8vQC50a36T068XgdjUDP8eA6 >									
	//        < 1E-018 limites [ 645761923,903174 ; 665949256,14032 ] >									
	//        < 0x0000000000000000000000000000000000000000000000F090A817AF815DEE22 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_32_____Naryan_Mar_Port_Authority_20230515 >									
	//        < KmqpiuRssH5y2EUK3Yiu6O9B0lJpEWWgry9RnT42f1Gz1zc0Bg94kWB530Q1vCc5 >									
	//        < 1E-018 limites [ 665949256,14032 ; 695750989,476352 ] >									
	//        < 0x000000000000000000000000000000000000000000000F815DEE221032FFC437 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_33_____Naryan_Mar_Port_Authority_20230515 >									
	//        < WxMC4Ida74OzXznY0318d6tmy6K0V78uCX72nZ8kkYcIxWn02Kvnjgzaln17l5V2 >									
	//        < 1E-018 limites [ 695750989,476352 ; 714106890,772429 ] >									
	//        < 0x000000000000000000000000000000000000000000001032FFC43710A068A629 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_34_____Nevelsk Port of Nevelsk_Port_Spe_Value_20230515 >									
	//        < Cy1uu8dCG344VBvxujSBv2f6bhn5gkB10G1OZRRWO759i14d6zFNGqtkyYnCn00p >									
	//        < 1E-018 limites [ 714106890,772429 ; 741823458,016212 ] >									
	//        < 0x0000000000000000000000000000000000000000000010A068A62911459CC63D >									
	//     < SEAPORT_Portfolio_VI_metadata_line_35_____Nevelsk_Port_Authority_20230515 >									
	//        < Lo6N48Qp5GX0kx801imdXXtG5u5UuOVxiDHylNnv5KFkpGFY11F2lTqtXs4Fv130 >									
	//        < 1E-018 limites [ 741823458,016212 ; 768954845,388412 ] >									
	//        < 0x0000000000000000000000000000000000000000000011459CC63D11E753FC6E >									
	//     < SEAPORT_Portfolio_VI_metadata_line_36_____Nevelsk_Port_Authority_20230515 >									
	//        < HtrOl3nI3ul7GEY0t5N27520nV6jiPliPAkQyDKQ3117j31298SMJ1Sjh56IAp9c >									
	//        < 1E-018 limites [ 768954845,388412 ;  ] >									
	//        < 0x0000000000000000000000000000000000000000000011E753FC6E1295530B52 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_37_____Nikolaevsk on Amur Port of Nikolaevsk on Amur_Port_Spe_Value_20230515 >									
	//        < V8D747yF47eH722733cn1s1uv182n9KS6HV554IC0Gp5r51cF9N3f24840gN388w >									
	//        < 1E-018 limites [ 798146583,987227 ; 826175174,38341 ] >									
	//        < 0x000000000000000000000000000000000000000000001295530B52133C634772 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_38_____Nikolaevsk_on_Amur_Sea_Port_20230515 >									
	//        < FTtY5Nb31fRx94Io6wp7OHK9E9qzqwttX64Gh1AXBPV75Q25eItnv0r4cTeN9FYv >									
	//        < 1E-018 limites [ 826175174,38341 ; 849657061,45984 ] >									
	//        < 0x00000000000000000000000000000000000000000000133C63477213C859CB95 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_39_____Nikolaevsk_on_Amur_Sea_Port_20230515 >									
	//        < 3uHQKlk2kC31xp93B7TLrLz7TM59XN1s4zIF65kUxUI2ZL8HZ0hhn665b9Sxu101 >									
	//        < 1E-018 limites [ 849657061,45984 ; 875475936,783258 ] >									
	//        < 0x0000000000000000000000000000000000000000000013C859CB9514623E45C2 >									
	//     < SEAPORT_Portfolio_VI_metadata_line_40_____Nizhnevartovsk_Port_Spe_Value_20230515 >									
	//        < 21eM1EJ61d9Xod79KUO2ZYx1SX7q9R1v8yG04X2AJl36G0PbbG7IIwrMYk6GANXG >									
	//        < 1E-018 limites [ 875475936,783258 ; 897688033,763432 ] >									
	//        < 0x0000000000000000000000000000000000000000000014623E45C214E6A33E24 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}