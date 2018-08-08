pragma solidity 		^0.4.21	;						
										
	contract	SEAPORT_Portfolio_VIII_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	SEAPORT_Portfolio_VIII_883		"	;
		string	public		symbol =	"	SEAPORT883VIII		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		835546197072062000000000000					;	
										
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
	//     < SEAPORT_Portfolio_VIII_metadata_line_1_____Sovgavan_Port_Limited_20230515 >									
	//        < 6NniN7vm9fOE60LnGT6I805oZjS4kGkLC572t1B82LhVJ200LM4UhDj6LaIrdQmO >									
	//        < 1E-018 limites [ 1E-018 ; 19761758,9288857 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000000075CA0F08 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_2_____State_Enterprise_Dikson_Sea_Trade_Port_20230515 >									
	//        < 10kwm576F1QosRN9hK202Km06p84OV37zQUDWlF60U689HNG57BN4x2iwkvc0I7C >									
	//        < 1E-018 limites [ 19761758,9288857 ; 41059313,7369108 ] >									
	//        < 0x00000000000000000000000000000000000000000000000075CA0F08F4BB8C61 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_3_____Surgut_Port_Spe_Value_20230515 >									
	//        < gc7N7IXGLBVKbyyB2reDM6zHqDob7K0L1gBz544VO7BTD00YbpYgwMl0ZEmqkS7X >									
	//        < 1E-018 limites [ 41059313,7369108 ; 63449433,488897 ] >									
	//        < 0x00000000000000000000000000000000000000000000000F4BB8C6117A3028E8 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_4_____Taganrog Port of Taganrog_Port_Spe_Value_20230515 >									
	//        < w0qJQtmjG3A7Lg7SNl69cCk5RD2EQ9qzJ16jOo1vuoL23521Izy4OWK0IFODvv7m >									
	//        < 1E-018 limites [ 63449433,488897 ; 85194638,9793359 ] >									
	//        < 0x000000000000000000000000000000000000000000000017A3028E81FBCCB5CD >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_5_____Taganrog_Port_Authority_20230515 >									
	//        < 8G2WaLJPeMAhO92Azr6Zr5f0TGYRAyT696TNVEkWJ0CvBP5OIY0F8FZc7s59heQi >									
	//        < 1E-018 limites [ 85194638,9793359 ; 111291798,222891 ] >									
	//        < 0x00000000000000000000000000000000000000000000001FBCCB5CD29759D0A2 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_6_____Tara_Port_Spe_Value_20230515 >									
	//        < kZDb9S6po7KNX86y7i2gFdn88L7R5JD1bYZn321W8z33Em22U6qRaDe60eeG0QY9 >									
	//        < 1E-018 limites [ 111291798,222891 ; 130649623,052959 ] >									
	//        < 0x000000000000000000000000000000000000000000000029759D0A230ABB82F5 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_7_____Temryuk_Port_Authority_20230515 >									
	//        < 9oo9s6SDtdEfMq6sStz743k1THZN7yjIb0535t2ev8658KucdJ29HNGXm8tP3w01 >									
	//        < 1E-018 limites [ 130649623,052959 ; 148518721,227912 ] >									
	//        < 0x000000000000000000000000000000000000000000000030ABB82F53753D976E >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_8_____The_Commercial_Port_of_Vladivostok_JSC_20230515 >									
	//        < uc8Ig43vG6KB32dHYVI5O3ca28fw7pmYXr7fApibE880F54W048saqMs72uxB6f6 >									
	//        < 1E-018 limites [ 148518721,227912 ; 171926247,395874 ] >									
	//        < 0x00000000000000000000000000000000000000000000003753D976E400C2A457 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_9_____Tiksi Port of Tiksi_Port_Spe_Value_20230515 >									
	//        < 7DGGW6gG2u7bqc91tA4gUj3l0Za0C9puPg5Z2Azz739SC7d4WPZc77WoknU64S7N >									
	//        < 1E-018 limites [ 171926247,395874 ; 199799403,89251 ] >									
	//        < 0x0000000000000000000000000000000000000000000000400C2A4574A6E5B419 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_10_____Tiksi_Sea_Trade_Port_20230515 >									
	//        < MBdDZ193DFpqKYz35g2Qz8J38gBQ95RxAJbnmS54rI8Xh94C8yZZ5C7Rh9Q6P2nV >									
	//        < 1E-018 limites [ 199799403,89251 ; 215856832,240956 ] >									
	//        < 0x00000000000000000000000000000000000000000000004A6E5B4195069B650C >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_VIII_metadata_line_11_____Tobolsk_Port_Spe_Value_20230515 >									
	//        < 324RfJK62Q4tRDC8HlhPB8ycIgu6i30ngY031c74c8wjgFJ3H3J4O8LFPS6o6MMm >									
	//        < 1E-018 limites [ 215856832,240956 ; 233690074,829712 ] >									
	//        < 0x00000000000000000000000000000000000000000000005069B650C570E6C36E >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_12_____Tuapse Port of Tuapse_Port_Spe_Value_20230515 >									
	//        < 3vKWkDhcPGFhAvO7SXeY64K2tB75vpoWR5s44XAv5HCkT9Dpp5v16XEi6N36QH2g >									
	//        < 1E-018 limites [ 233690074,829712 ; 258372329,623274 ] >									
	//        < 0x0000000000000000000000000000000000000000000000570E6C36E60404E536 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_13_____Tuapse_Port_Authorities_20230515 >									
	//        < PvR8614iMRa8sRK23sn6wI541Vnkr12ARZ0o9433SeP0zjNH9Szrz17EvpZNzt1U >									
	//        < 1E-018 limites [ 258372329,623274 ; 279311805,42799 ] >									
	//        < 0x000000000000000000000000000000000000000000000060404E536680D3FFF2 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_14_____Tver_Port_Spe_Value_20230515 >									
	//        < 8NcSi8Wxs28HODs050OdTI69fF03z8aTnrL74M7V5tBU6NC48AXK1Gwl0P4h5FgE >									
	//        < 1E-018 limites [ 279311805,42799 ; 301372469,406869 ] >									
	//        < 0x0000000000000000000000000000000000000000000000680D3FFF270451E6D0 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_15_____Tyumen_Port_Spe_Value_20230515 >									
	//        < vIa8efJ6a9QWS9qeD39Sz05u0NXH8Jvs82ZIgaU71txtJUm6MYqyl26olYN04MaN >									
	//        < 1E-018 limites [ 301372469,406869 ; 318059650,336773 ] >									
	//        < 0x000000000000000000000000000000000000000000000070451E6D0767C884DD >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_16_____Ufa_Port_Spe_Value_20230515 >									
	//        < QCg6Hk9sL2V2EL5oo7ImC7FdFEW9vmhTGsk59Fjsk4xdjDwH1grS0TQ741j688T7 >									
	//        < 1E-018 limites [ 318059650,336773 ; 342621780,114441 ] >									
	//        < 0x0000000000000000000000000000000000000000000000767C884DD7FA2F5ACF >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_17_____Uglegorsk Port of Uglegorsk_Port_Spe_Value_20230515 >									
	//        < MQcRabhpnEa02n9z5KagJs2Nnrh54BC6Ta8unp70ug8CH0y38oX1tW53ZUfp727J >									
	//        < 1E-018 limites [ 342621780,114441 ; 371990608,338677 ] >									
	//        < 0x00000000000000000000000000000000000000000000007FA2F5ACF8A93CA155 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_18_____Uglegorsk_Port_Authority_20230515 >									
	//        < 62BmJZc83i6FS2C5rtGNHTqaSEHudBY8H29VTP99O66y1A06P8EVOWU8MOE2S0Lt >									
	//        < 1E-018 limites [ 371990608,338677 ; 389871128,35345 ] >									
	//        < 0x00000000000000000000000000000000000000000000008A93CA155913D02377 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_19_____Ulan_Ude_Port_Spe_Value_20230515 >									
	//        < h8EcPt9KN7CtF89BuqJ3k06yn2qG39zQf0tGt6EunZU6mn4A51cbIEcBf6ulbN7j >									
	//        < 1E-018 limites [ 389871128,35345 ; 406054846,930269 ] >									
	//        < 0x0000000000000000000000000000000000000000000000913D02377974468889 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_20_____Ulyanovsk_Port_Spe_Value_20230515 >									
	//        < 74zy352Iow68YHSv2CEfdS5jH0W99CpQO4o26Jr0ycJ8C9rjIQ4HEU00Ms86h2QK >									
	//        < 1E-018 limites [ 406054846,930269 ; 432927290,027787 ] >									
	//        < 0x0000000000000000000000000000000000000000000000974468889A1472A09E >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_VIII_metadata_line_21_____Ust Kamchatsk Port of Ust Kamchatsk_Port_Spe_Value_20230515 >									
	//        < DvQEn4E726Gb18YYk7GlR5U9gbS28X2d0V447G3F9yv4VKJMqYw93VRM3CBOWoOX >									
	//        < 1E-018 limites [ 432927290,027787 ; 448857660,399411 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A1472A09EA7366718B >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_22_____Ust_Kamchatsk_Sea_Trade_Port_20230515 >									
	//        < n6WaRbnec8iprzzjvof397GND2e86bsfrC4pY26f5iPd81Ow3Vj6FbO8yfyMsqCV >									
	//        < 1E-018 limites [ 448857660,399411 ; 474285355,8993 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A7366718BB0AF60719 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_23_____Ust_Luga Port of Ust_Luga_Port_Spe_Value_20230515 >									
	//        < p3d9d3Y8CHYgHcwJOe0Zq2UJ2c0VQPoQ7bhx8T9JZ26pn8RR3N47K5nTH542OpzA >									
	//        < 1E-018 limites [ 474285355,8993 ; 495664373,552418 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B0AF60719B8A63D1DF >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_24_____Ust_Luga_Sea_Port_20230515 >									
	//        < l937W527WZi1AMv8lDv3ddNkBC0Tvt63X4xBlJ5wOdR0Wtn5FYQWf9I1rlWKMpf5 >									
	//        < 1E-018 limites [ 495664373,552418 ; 519894201,925429 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B8A63D1DFC1ACF9A94 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_25_____Vanino Port of Vanino_Port_Spe_Value_20230515 >									
	//        < 33iZIY48WOtiTrAUQOl9Yef4sfia9bAi7iRi3G1W312C0g8M97FG4w4a6NO9rc1H >									
	//        < 1E-018 limites [ 519894201,925429 ; 535145059,991797 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C1ACF9A94C75B69103 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_26_____Vanino_Port_Authority_20230515 >									
	//        < MohcTrb8177b00W7E3K7yKXJhQWxfaLG8NYCN50741muZ1fZ4A9VZ717PIih65EK >									
	//        < 1E-018 limites [ 535145059,991797 ; 551207248,373753 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C75B69103CD5738559 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_27_____Vidradne_Port_Spe_Value_20230515 >									
	//        < 91c1F776a2029wIT7DzjRlw2F7EvB96U1oOU4GEkW84Hh55RLKLaqSmMMW04f050 >									
	//        < 1E-018 limites [ 551207248,373753 ; 574666957,009596 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CD5738559D61483208 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_28_____Vladivostok Port of Vladivostok_Port_Spe_Value_20230515 >									
	//        < uz0I476Nn7JgO1BeE1gOXaSdjWIG7r3319feEouKTHhncWg62BS2me60yVuuQOr5 >									
	//        < 1E-018 limites [ 574666957,009596 ; 596830529,357854 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D61483208DE5631F7B >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_29_____Volgodonsk_Port_Spe_Value_20230515 >									
	//        < A7xa1b2yY5rh8Z1xiAyfnY6409Acq3H8BL2BiC3s7OH349V6ZeiPStG9DdCP7R3B >									
	//        < 1E-018 limites [ 596830529,357854 ; 613663657,298783 ] >									
	//        < 0x0000000000000000000000000000000000000000000000DE5631F7BE49B87015 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_30_____Volgograd_Port_Spe_Value_20230515 >									
	//        < F4Xdn2GJ1s5kDKHE3fKSNuADFJdPy1dQ56HQljej1V1Ysggh64A4pfKhGngLtSud >									
	//        < 1E-018 limites [ 613663657,298783 ; 640987653,812905 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E49B87015EEC958C39 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_VIII_metadata_line_31_____Vostochny Port of Vostochny_Port_Spe_Value_20230515 >									
	//        < 9nNR8i4quM32Dpk5O0p39oO4fbyslS5pOdcc4T7AYm7bJYJYHT2Gel0rAQ136Z9u >									
	//        < 1E-018 limites [ 640987653,812905 ; 658403911,197153 ] >									
	//        < 0x0000000000000000000000000000000000000000000000EEC958C39F5464A5C3 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_32_____Vostochny_Port_Joint_Stock_Company_20230515 >									
	//        < rOqvrC62HQ42PaT9V27LY86N5n0Te9Z2846mbb992rN8NM9X7svfEiGQrE7AvGqG >									
	//        < 1E-018 limites [ 658403911,197153 ; 676080574,858138 ] >									
	//        < 0x0000000000000000000000000000000000000000000000F5464A5C3FBDC11881 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_33_____Vyborg Port of Vyborg_Port_Spe_Value_20230515 >									
	//        < vVyZ1W66xyptZ5JloJTA73G6xDrU8hWNYqTyJPG4dT7KbHck4uv4ORgUlHutc5I4 >									
	//        < 1E-018 limites [ 676080574,858138 ; 694545185,576836 ] >									
	//        < 0x000000000000000000000000000000000000000000000FBDC11881102BCFDB11 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_34_____Vyborg_Port_Authority_20230515 >									
	//        < Ap79ZwUHabxH69w5U6GWrKcJfoNM80upFYfC8zUiH9Nn3szn06eXXt0H9nMOjDUv >									
	//        < 1E-018 limites [ 694545185,576836 ; 710398604,933373 ] >									
	//        < 0x00000000000000000000000000000000000000000000102BCFDB11108A4E4101 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_35_____Vysotsk_Marine_Authority_20230515 >									
	//        < 54jcYnpo9vpbG550AKxF4ikhELByL97gtcgR9l79F1sz2Csac4blijBQpw50Y9sU >									
	//        < 1E-018 limites [ 710398604,933373 ; 734250052,789908 ] >									
	//        < 0x00000000000000000000000000000000000000000000108A4E4101111878ACD2 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_36_____Yakutsk_Port_Spe_Value_20230515 >									
	//        < R16xp47wyk9UNOOf4G1xL87W2JO40ns5BM8uUK6G03UUa2Puv2m5vI8KewxThULK >									
	//        < 1E-018 limites [ 734250052,789908 ;  ] >									
	//        < 0x00000000000000000000000000000000000000000000111878ACD211757C0794 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_37_____Yalta_Port_Spe_Value_20230515 >									
	//        < 3YJX1fUQ2X0jRKva02FHr5W7cP88jV4xQKV0t1cP20m9BR2lN1E7r7c9sZ659QrX >									
	//        < 1E-018 limites [ 749855062,081324 ; 771324893,231986 ] >									
	//        < 0x0000000000000000000000000000000000000000000011757C079411F574645F >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_38_____Yaroslavl_Port_Spe_Value_20230515 >									
	//        < bIm2X08hGe2V73tARDjqF9VlY821hE0RYiUnHRurBmaG10W36GlnhFgra7h5mLa7 >									
	//        < 1E-018 limites [ 771324893,231986 ; 786627737,956064 ] >									
	//        < 0x0000000000000000000000000000000000000000000011F574645F1250AAAE17 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_39_____Yeysk Port of Yeysk_Port_Spe_Value_20230515 >									
	//        < 1Y5TH5Cz5fNPYjSI0ZE3WcJhwkGHau25DHUi5u0h7J7Dl8oBItDoUW5W0gTf1Q0L >									
	//        < 1E-018 limites [ 786627737,956064 ; 813646524,178767 ] >									
	//        < 0x000000000000000000000000000000000000000000001250AAAE1712F1B61375 >									
	//     < SEAPORT_Portfolio_VIII_metadata_line_40_____Zarubino_Port_Spe_Value_20230515 >									
	//        < YVT32lOoQGW4mzKtBeQ00dqic5fHsgYQsVhUa2298UC7j71c2QLLe8Cap324Odko >									
	//        < 1E-018 limites [ 813646524,178767 ; 835546197,072062 ] >									
	//        < 0x0000000000000000000000000000000000000000000012F1B6137513743E532F >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}