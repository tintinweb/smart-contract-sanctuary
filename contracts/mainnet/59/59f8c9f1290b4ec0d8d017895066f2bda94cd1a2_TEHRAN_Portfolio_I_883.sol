pragma solidity 		^0.4.21	;						
										
	contract	TEHRAN_Portfolio_I_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	TEHRAN_Portfolio_I_883		"	;
		string	public		symbol =	"	TEHRAN883		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		2140354551050680000000000000					;	
										
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
	//     < TEHRAN_Portfolio_I_metadata_line_1_____Asan_Pardakht_Pers_20250515 >									
	//        < CJO0TdiK0uiWB0lIp8R4jD9W3NpZiV2O7ibv5Fe8AybOjP320HioFP404o3y9Nt8 >									
	//        <  u =="0.000000000000000001" : ] 000000000000000.000000000000000000 ; 000000061210881.473286600000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000037A0ED4 >									
	//     < TEHRAN_Portfolio_I_metadata_line_2_____Bank_Melli_Inv_20250515 >									
	//        < 757g2ap9JV3eU0k18t4IjG867qIE0rdcwu8N6u48FiFWUY46jYT16LEt481wAn3f >									
	//        <  u =="0.000000000000000001" : ] 000000061210881.473286600000000000 ; 000000116460677.664409000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000037A0ED456471373 >									
	//     < TEHRAN_Portfolio_I_metadata_line_3_____Fajr_Petrochemical_20250515 >									
	//        < z1G01Kjfz6uI2KwkOM56ZgChx2CgjyKk8sTj279r591zck24pcKTXC0F6AJ41q3y >									
	//        <  u =="0.000000000000000001" : ] 000000116460677.664409000000000000 ; 000000171382463.440255000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000564713732B64E852B >									
	//     < TEHRAN_Portfolio_I_metadata_line_4_____Mellat_Bank_20250515 >									
	//        < pvk5r3SRcL08r8v1XQh80R8B2gm5eASP39SiXaiC99i5WqLBpCDEwZtI0EAc0q45 >									
	//        <  u =="0.000000000000000001" : ] 000000171382463.440255000000000000 ; 000000208353305.657455000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000002B64E852B4E34C5460 >									
	//     < TEHRAN_Portfolio_I_metadata_line_5_____Chadormalu_20250515 >									
	//        < li2TG8666iOSDrgJ878M2N3A3A19aN23Rt6xbvAarkDiHC30LsA226spOk3g1X06 >									
	//        <  u =="0.000000000000000001" : ] 000000208353305.657455000000000000 ; 000000252385082.637906000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000004E34C54604ECBCF485 >									
	//     < TEHRAN_Portfolio_I_metadata_line_6_____Khouz_Steel_20250515 >									
	//        < MVG84bw9wR083X7q9lFvMNerqu7gRE3ZSZZ5avTX2654d8e5v3C5UHT37zJAffaL >									
	//        <  u =="0.000000000000000001" : ] 000000252385082.637906000000000000 ; 000000291751435.337723000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000004ECBCF48550ED00309 >									
	//     < TEHRAN_Portfolio_I_metadata_line_7_____Mobarakeh_Steel_20250515 >									
	//        < UxJ0h6Ub5rOFq3R8166mHcLevX5eXq2UfoutUTXo79ZCgSgp5H2YM5195ya512od >									
	//        <  u =="0.000000000000000001" : ] 000000291751435.337723000000000000 ; 000000343072100.951209000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000050ED00309816B8E20D >									
	//     < TEHRAN_Portfolio_I_metadata_line_8_____Ghadir_Inv_20250515 >									
	//        < 02muY5Ca7HZ7hB90ueT1yqyrE7CrihUYBS4RQIxtZCf1WJ1AKMcdBE490Q1GS84C >									
	//        <  u =="0.000000000000000001" : ] 000000343072100.951209000000000000 ; 000000397620165.608982000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000816B8E20DBFD699807 >									
	//     < TEHRAN_Portfolio_I_metadata_line_9_____Gol_E_Gohar_20250515 >									
	//        < c634eWNMtsB8lomjYCSBKrwg8B7rWBSS63Hb6Rs2suA5M79kGfMwImJD2eCIxnru >									
	//        <  u =="0.000000000000000001" : ] 000000397620165.608982000000000000 ; 000000476761514.460519000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BFD699807C00CC925C >									
	//     < TEHRAN_Portfolio_I_metadata_line_10_____Iran_Mobil_Tele_20250515 >									
	//        < GHy2nJ8217UvQ686c3uN387nhYv6U0isPL0A6OCzz15k87aEhgULivrKHn9YXPIh >									
	//        <  u =="0.000000000000000001" : ] 000000476761514.460519000000000000 ; 000000541506851.333809000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C00CC925CC8B19E052 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < TEHRAN_Portfolio_I_metadata_line_11_____Iran_Khodro_20250515 >									
	//        < iX1B36lIfohy6nr8J15kvXJ3Y829npAH73PTQ3s5Jdqyt37fxLY08h0m3Izr4Rmo >									
	//        <  u =="0.000000000000000001" : ] 000000541506851.333809000000000000 ; 000000616108313.583000000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C8B19E052C95A3ECBC >									
	//     < TEHRAN_Portfolio_I_metadata_line_12_____IRI_Marine_Co_20250515 >									
	//        < T2F2XmuSgNzql7yJb6XT21H1v3rlG73J0vXdve2vQ7w6d7ic8cbT8n2D1t5Tj32G >									
	//        <  u =="0.000000000000000001" : ] 000000616108313.583000000000000000 ; 000000652705135.584955000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C95A3ECBCCA5EAC970 >									
	//     < TEHRAN_Portfolio_I_metadata_line_13_____Metals_Min_20250515 >									
	//        < H15yBY3c0C1ju5t0en19sux3msBqmf3842TQGL6nEyFFIGf609149v3lZ7dD83lM >									
	//        <  u =="0.000000000000000001" : ] 000000652705135.584955000000000000 ; 000000718182786.421577000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CA5EAC970CFBA12F64 >									
	//     < TEHRAN_Portfolio_I_metadata_line_14_____MAPNA_20250515 >									
	//        < 8I82SG1yNK9kIuE30orKF7CJo33QZMiA176mkv66Mp26clRtE59npC78J3XoTE3a >									
	//        <  u =="0.000000000000000001" : ] 000000718182786.421577000000000000 ; 000000764558559.723822000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CFBA12F64D359422C8 >									
	//     < TEHRAN_Portfolio_I_metadata_line_15_____Iran_Tele_Co_20250515 >									
	//        < i9Icd0eLY2D3iOvbZ5T5ZUZdBKrjxV4UI67M6yN05X2tdrWf2v4U9o7EP1jzrVXH >									
	//        <  u =="0.000000000000000001" : ] 000000764558559.723822000000000000 ; 000000841393243.264593000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000D359422C81191394DA5 >									
	//     < TEHRAN_Portfolio_I_metadata_line_16_____Mobin_Petr_20250515 >									
	//        < Ob9Ay7W1Ke7ngjrgl3zjBA12b4TCb408XF5zVG9me0e8qS2cMte82S1EBUO7u6g9 >									
	//        <  u =="0.000000000000000001" : ] 000000841393243.264593000000000000 ; 000000886895158.844619000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001191394DA5119E78BA38 >									
	//     < TEHRAN_Portfolio_I_metadata_line_17_____I_N_C_Ind_20250515 >									
	//        < Uo1SlsPKjGhB5uH6t1f267811O3h36hElju09LS1B0927L2pK1XVg9q6XnuZ46Wp >									
	//        <  u =="0.000000000000000001" : ] 000000886895158.844619000000000000 ; 000000938814504.253922000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000119E78BA3811A5A651C7 >									
	//     < TEHRAN_Portfolio_I_metadata_line_18_____Omid_Inv_Mng_20250515 >									
	//        < 0tu1Zf8X0xz03k3gWV0wtmLy885VT72o3buu8O33Uqqe7MGG0r2EDm20qNdiJ6ED >									
	//        <  u =="0.000000000000000001" : ] 000000938814504.253922000000000000 ; 000001006010100.736080000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A5A651C711A7337AA6 >									
	//     < TEHRAN_Portfolio_I_metadata_line_19_____Parsian_Oil_Gas_20250515 >									
	//        < gCJ4N8Sh229LFUkIGHD0Edfr94uYcASk8ISn8Y6YvraP0Hv9LJw5Gkoi916dYwj5 >									
	//        <  u =="0.000000000000000001" : ] 000001006010100.736080000000000000 ; 000001059393442.681370000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A7337AA611A80D764A >									
	//     < TEHRAN_Portfolio_I_metadata_line_20_____Fanavaran_Petr_20250515 >									
	//        < 5pO3wh9sB877u026945fUftWNnb18k228zyn7zQ1h3ej2yecR7sV45fufUQAiOdv >									
	//        <  u =="0.000000000000000001" : ] 000001059393442.681370000000000000 ; 000001103775973.755440000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A80D764A11A9E0DEC1 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < TEHRAN_Portfolio_I_metadata_line_21_____Jam_Petr_20250515 >									
	//        < 1726okLV3BR36B6jG51TCfy1752d70ao1784LGFmKmazeSr8QPzqc5HCR423hTfE >									
	//        <  u =="0.000000000000000001" : ] 000001103775973.755440000000000000 ; 000001158796138.464220000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A9E0DEC11337C233DB >									
	//     < TEHRAN_Portfolio_I_metadata_line_22_____Khark_Petr_20250515 >									
	//        < QAo66E5QD3A49PdgO3b9nlA723XfFF66FT4WQBQ061P310a4byPSW8I2WROKI34Y >									
	//        <  u =="0.000000000000000001" : ] 000001158796138.464220000000000000 ; 000001238453992.454110000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001337C233DB16FC133A49 >									
	//     < TEHRAN_Portfolio_I_metadata_line_23_____Khalij_Fars_20250515 >									
	//        < x6EWsrz1C66G4K0qBT7Rq0o3QQO95heFL95pAAv0J1Nmh3GM36Oqc7SR8G3LCwHE >									
	//        <  u =="0.000000000000000001" : ] 000001238453992.454110000000000000 ; 000001295153126.350380000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000016FC133A4916FCE8C776 >									
	//     < TEHRAN_Portfolio_I_metadata_line_24_____BA_Oil_Refinie_20250515 >									
	//        < BJ5571Q2TAEe0yKf6095R51u1Chuz5gTkGUkDJNi8kXGmn5me2R36Z387x880n7x >									
	//        <  u =="0.000000000000000001" : ] 000001295153126.350380000000000000 ; 000001331882490.001130000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000016FCE8C77616FE4B3578 >									
	//     < TEHRAN_Portfolio_I_metadata_line_25_____Isf_Oil_Ref_Co_20250515 >									
	//        < 4wkB3H1Ejh5q96FEr1h68EX4qHYV1898VzqMf7hw4eZ4jA6YNs50VK3Kp8GFlRW5 >									
	//        <  u =="0.000000000000000001" : ] 000001331882490.001130000000000000 ; 000001372467359.378910000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000016FE4B357817094B7C8A >									
	//     < TEHRAN_Portfolio_I_metadata_line_26_____Pardis_Petr_20250515 >									
	//        < 6976Bf6rB8xqvt53nWO02IblZ6i6IBlKYEvSi5q5KgDS7JoWns3TpY7DM22Zg2t0 >									
	//        <  u =="0.000000000000000001" : ] 000001372467359.378910000000000000 ; 000001442005160.931830000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000017094B7C8A170A9FCB93 >									
	//     < TEHRAN_Portfolio_I_metadata_line_27_____Tamin_Petro_20250515 >									
	//        < UE9Plj5Xu1xts7r9TFR8J8S9WKjr74p6C4ns1l92ax9IUqLGwxWq636nr52H2V63 >									
	//        <  u =="0.000000000000000001" : ] 000001442005160.931830000000000000 ; 000001483346707.538130000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000170A9FCB931710216274 >									
	//     < TEHRAN_Portfolio_I_metadata_line_28_____Palayesh_Tehran_20250515 >									
	//        < wh6Be2p87jY5L256U64dUkul4K3Sm3l53w90vrY3hIq5xh9NCEWBROZhs3Z8vIyU >									
	//        <  u =="0.000000000000000001" : ] 000001483346707.538130000000000000 ; 000001536886446.281760000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000017102162741710DAFC71 >									
	//     < TEHRAN_Portfolio_I_metadata_line_29_____Pension_Fund_20250515 >									
	//        < zyCBwuXC1p4RKGez6gucHmUFrb33bRDe6sdpRSmyH8n17SQ2KpQCAI7bkLN8Kb7q >									
	//        <  u =="0.000000000000000001" : ] 000001536886446.281760000000000000 ; 000001609848020.489690000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001710DAFC71171F5B98B4 >									
	//     < TEHRAN_Portfolio_I_metadata_line_30_____Saipa_20250515 >									
	//        < 3eHX0wKcN8iu78t3Pw18C16cTZnE6Y3e438G7AbLOw6kvv9lT0wr9864e2ehLVaL >									
	//        <  u =="0.000000000000000001" : ] 000001609848020.489690000000000000 ; 000001670977351.576980000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000171F5B98B41B22EC3D9C >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < TEHRAN_Portfolio_I_metadata_line_31_____Hegmatan_Sugar_20250515 >									
	//        < eL4Rp6K62TfJG0hFW59g8fQ3Y3QwIHU8asGPgzHz12LeM1fXAT392JR8z7qTx54F >									
	//        <  u =="0.000000000000000001" : ] 000001670977351.576980000000000000 ; 000001719124820.482130000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001B22EC3D9C1E0D333C03 >									
	//     < TEHRAN_Portfolio_I_metadata_line_32_____F_Kh_Cement_20250515 >									
	//        < mo2Z231Z1R1ea7LN4v27p68qZGskf5V8f1480pM70GL0j8AcGSuoE1pmh5M0G7DU >									
	//        <  u =="0.000000000000000001" : ] 000001719124820.482130000000000000 ; 000001776529382.001640000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001E0D333C031E29356C3E >									
	//     < TEHRAN_Portfolio_I_metadata_line_33_____Iran_Aluminium_20250515 >									
	//        < L5hatOCJ2sTdQL9yx94tnOXPn2vYG0Vz3R0YXbvgoq3hwp7ErDFCYMeSY96J39T8 >									
	//        <  u =="0.000000000000000001" : ] 000001776529382.001640000000000000 ; 000001820306550.556860000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001E29356C3E1E2A15F705 >									
	//     < TEHRAN_Portfolio_I_metadata_line_34_____Margarin_20250515 >									
	//        < bphJ456D5Z23iI03dD0VKnq3u5m40GBHl6jX90E7U4QlKcsnruL030C052L91oJw >									
	//        <  u =="0.000000000000000001" : ] 000001820306550.556860000000000000 ; 000001870624899.426850000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001E2A15F7051E37D2E629 >									
	//     < TEHRAN_Portfolio_I_metadata_line_35_____Qayen_Cement_20250515 >									
	//        < P0470BCzNVwuvg1I8b0y9Vb5Mwu38Wg3O01kQc5Q6371xfrn99FS2Ejy2Nk74IM7 >									
	//        <  u =="0.000000000000000001" : ] 000001870624899.426850000000000000 ; 000001916006437.994380000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000001E37D2E62921F0EF1D76 >									
	//     < TEHRAN_Portfolio_I_metadata_line_36_____Isfahan_Cement_20250515 >									
	//        < yva9qPHPK9KRQxI2tvQ014Rzdy16z8Wu2aO0n2m28oBCgBPgU5YfBZRmElB6Gj2D >									
	//        <  u =="0.000000000000000001" : ] 000001916006437.994380000000000000 ; 000001974212601.827640000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000021F0EF1D7623C829D434 >									
	//     < TEHRAN_Portfolio_I_metadata_line_37_____Mazandaran_Cement_20250515 >									
	//        < v63MfSre8ZYIHEe9Y4KC5p7TkZ1yGRn5m1tcyY9xRHJuEXKy9e9D1x5QlBZ3QCsg >									
	//        <  u =="0.000000000000000001" : ] 000001974212601.827640000000000000 ; 000002022950243.758070000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000023C829D43423C95BAE77 >									
	//     < TEHRAN_Portfolio_I_metadata_line_38_____Tejarat_Bank_20250515 >									
	//        < GqHPds8351RtcMFWlC7Br4YizCVYqNs0cqebOof6c9AvePio0cuz494TQjtJa49j >									
	//        <  u =="0.000000000000000001" : ] 000002022950243.758070000000000000 ; 000002061752131.332030000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000023C95BAE7724A65522E8 >									
	//     < TEHRAN_Portfolio_I_metadata_line_39_____Ghazvin_Sugar_20250515 >									
	//        < 1BM3s10ziD4aeqRO5eS5H91Kk9810r9CD5P0do8T05NB4f43Z2rK8Gfs9Md6Q7rS >									
	//        <  u =="0.000000000000000001" : ] 000002061752131.332030000000000000 ; 000002103894666.113420000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000024A65522E824C0198909 >									
	//     < TEHRAN_Portfolio_I_metadata_line_40_____Mashad_Wheel_20250515 >									
	//        < mKRtx4cQf930aNdKWa2CNyN23F8gLJZcqmBpp4K9R8DtA38hhu7x68B9KU1KK36I >									
	//        <  u =="0.000000000000000001" : ] 000002103894666.113420000000000000 ; 000002140354551.050680000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000024C019890924C8475D18 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}