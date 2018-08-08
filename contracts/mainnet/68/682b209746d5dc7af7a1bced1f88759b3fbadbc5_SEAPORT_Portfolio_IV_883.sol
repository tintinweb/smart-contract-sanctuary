pragma solidity 		^0.4.21	;						
										
	contract	SEAPORT_Portfolio_IV_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	SEAPORT_Portfolio_IV_883		"	;
		string	public		symbol =	"	SEAPORT883IV		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		903053077115554000000000000					;	
										
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
	//     < SEAPORT_Portfolio_IV_metadata_line_1_____Abakan_Spe_Value_20230515 >									
	//        < YIu6x2WW5X3IQvw388rT7uU6m4vnnQXJ6TuxI10Zpoe0UZ1Wf681wvGn7a8555Fd >									
	//        < 1E-018 limites [ 1E-018 ; 25704415,9015215 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000009935D56A >									
	//     < SEAPORT_Portfolio_IV_metadata_line_2_____Aleksandrovsk_Sakhalinsky_Sea_Port_20230515 >									
	//        < pLp6XEz0v38W0b1BhivwU6jh9w4n3Da1NMn5bS9fP0brEmcQQiiPVqKo8QeQE0K4 >									
	//        < 1E-018 limites [ 25704415,9015215 ; 48178534,2275302 ] >									
	//        < 0x000000000000000000000000000000000000000000000009935D56A11F2A9DE2 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_3_____Alexandrovsk Port of Alexandrovsk_Port_Spe_Value_20230515 >									
	//        < 3rXD2d8HTlwog9O51WK08brkH6x02j9O8a01WTvQv41kHZPfYlqCzZh41eoYR7j7 >									
	//        < 1E-018 limites [ 48178534,2275302 ; 74798147,905154 ] >									
	//        < 0x000000000000000000000000000000000000000000000011F2A9DE21BDD4EC7A >									
	//     < SEAPORT_Portfolio_IV_metadata_line_4_____Amderma Port of Amderma_Port_Spe_Value_20230515 >									
	//        < H3r3RdaOvKFDp2852ddUI3fm2bb8jwZck05aMt3mQS7RrLqnC2imjvL88S21hw0N >									
	//        < 1E-018 limites [ 74798147,905154 ; 99892843,7100847 ] >									
	//        < 0x00000000000000000000000000000000000000000000001BDD4EC7A253686407 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_5_____Amderma_Maritime_Trade_Port_20230515 >									
	//        < V65W67P69R773isIP68q7Zemhk18aa786LZ68a7Az9PRHyHilw4FZl9qQ99Jg399 >									
	//        < 1E-018 limites [ 99892843,7100847 ; 124210658,879511 ] >									
	//        < 0x00000000000000000000000000000000000000000000002536864072E45A6E93 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_6_____Anadyr Port of Anadyr_Port_Spe_Value_20230515 >									
	//        < bGrQCamIR3n8D32lDGC3m4KsR9cdXnoZ6STX0x91rd5r7a1oAGvU3U3Pi2B85stv >									
	//        < 1E-018 limites [ 124210658,879511 ; 141519099,751623 ] >									
	//        < 0x00000000000000000000000000000000000000000000002E45A6E9334B85044B >									
	//     < SEAPORT_Portfolio_IV_metadata_line_7_____Anadyr_Port_Spe_Value_20230515 >									
	//        < i1BX7Om3036P0JQ10rcp0x3UJX1tBvDuzD8YjwU7aPG6jtMTc6LncnWiroM53L53 >									
	//        < 1E-018 limites [ 141519099,751623 ; 170437051,489341 ] >									
	//        < 0x000000000000000000000000000000000000000000000034B85044B3F7E24F30 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_8_____Anadyr_Sea_Port_Ltd_20230515 >									
	//        < cHAis1BDxH9M57P8KV96kd5gYh0Tz03W3BLDSGQo5z2wgF5YfAV6czGnWYqwR1KO >									
	//        < 1E-018 limites [ 170437051,489341 ; 193424389,731618 ] >									
	//        < 0x00000000000000000000000000000000000000000000003F7E24F30480E63431 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_9_____Anapa Port of Anapa_Port_Spe_Value_20230515 >									
	//        < Fd90H1qFIPfk0uhlP89vl985xb6s2nI99kVTWmD75G39wtn1L11h7virp3D04032 >									
	//        < 1E-018 limites [ 193424389,731618 ; 215909284,550554 ] >									
	//        < 0x0000000000000000000000000000000000000000000000480E63431506EB6E3B >									
	//     < SEAPORT_Portfolio_IV_metadata_line_10_____Anapa_Port_Spe_Value_20230515 >									
	//        < 6c953291zTjPirGJl3ZIzVrAW0aJ00Ox3ls7P38I90ej1lNzhfb4cIKs1ivgS3l6 >									
	//        < 1E-018 limites [ 215909284,550554 ; 243730525,179161 ] >									
	//        < 0x0000000000000000000000000000000000000000000000506EB6E3B5ACBF4659 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_IV_metadata_line_11_____Archangel Port of Archangel_Port_Spe_Value_20230515 >									
	//        < qla0BZlsz1Qz04lmBE3bY8lIA099goaz4DRS5vdGek8YEHUvA4g21Ie0o5L809SV >									
	//        < 1E-018 limites [ 243730525,179161 ; 259594586,79276 ] >									
	//        < 0x00000000000000000000000000000000000000000000005ACBF465960B4DE96B >									
	//     < SEAPORT_Portfolio_IV_metadata_line_12_____Arkhangelsk Port of Arkhangelsk_Port_Spe_Value_20230515 >									
	//        < 85DABUQrAla50y989pld0C01X6EaOz8F62Bh0AMKae699AK35MR7888U0X8Tsil9 >									
	//        < 1E-018 limites [ 259594586,79276 ; 282877387,923155 ] >									
	//        < 0x000000000000000000000000000000000000000000000060B4DE96B69614A59C >									
	//     < SEAPORT_Portfolio_IV_metadata_line_13_____Arkhangelsk_Port_Spe_Value_20230515 >									
	//        < Nb52Bobp2E86eaw7lK87MUo4tjKSlT06r39iNcO73PiCHJ1BghXPQ3y8I0VeMfUI >									
	//        < 1E-018 limites [ 282877387,923155 ; 299693504,110468 ] >									
	//        < 0x000000000000000000000000000000000000000000000069614A59C6FA5000FF >									
	//     < SEAPORT_Portfolio_IV_metadata_line_14_____Astrakhan Port of Astrakhan_Port_Spe_Value_20230515 >									
	//        < WCm2eDP8ryFEDfDA7GoZk7x3hI97q0Z0EJ9fu2I0297B7SL218HnK047NXGaS45v >									
	//        < 1E-018 limites [ 299693504,110468 ; 320204388,876235 ] >									
	//        < 0x00000000000000000000000000000000000000000000006FA5000FF77491215B >									
	//     < SEAPORT_Portfolio_IV_metadata_line_15_____Astrakhan_Port_Spe_Value_20230515 >									
	//        < kN6rYRiB82I7HFgGr5tNn0xCmZsi18G6K7wa18C0x8nb5YRaoLZaLL0Yy0N09O6W >									
	//        < 1E-018 limites [ 320204388,876235 ; 340774050,132965 ] >									
	//        < 0x000000000000000000000000000000000000000000000077491215B7EF2BF149 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_16_____Astrakhan_Sea_Commercial_Port_20230515 >									
	//        < 9zZy82SCXTt4kkkdM7rHU2k7bzl4Eavk2mY7IGhT0VmzWp0k9m8l5EAj7Plxl959 >									
	//        < 1E-018 limites [ 340774050,132965 ; 366917637,241202 ] >									
	//        < 0x00000000000000000000000000000000000000000000007EF2BF14988AFFE400 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_17_____Astrakhan_Sea_Commercial_Port_I_20230515 >									
	//        < B2D4NS99jg48GLzfFmT072P8t2zouAa3xQ6OM4J83Ux4d3YMv2akoRQ0a885ju1M >									
	//        < 1E-018 limites [ 366917637,241202 ; 388320458,223693 ] >									
	//        < 0x000000000000000000000000000000000000000000000088AFFE40090A9200F2 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_18_____Azov Port of Azov_Port_Spe_Value_20230515 >									
	//        < TwafO563iq1wU95H58iT73tw5B6RG8z89T5C3EXwiDG9cNl4115BBsTJqH1qlyX0 >									
	//        < 1E-018 limites [ 388320458,223693 ; 417207319,192309 ] >									
	//        < 0x000000000000000000000000000000000000000000000090A9200F29B6BFDB03 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_19_____Baltyisk Port of Baltyisk_Port_Spe_Value_20230515 >									
	//        < f5449FcaZuWTX9a55ds11Z17OydSm220qX89wqUHy3Ygdii1j7o7Sehn9GO8ZtsQ >									
	//        < 1E-018 limites [ 417207319,192309 ; 434305016,917108 ] >									
	//        < 0x00000000000000000000000000000000000000000000009B6BFDB03A1CA8DF2F >									
	//     < SEAPORT_Portfolio_IV_metadata_line_20_____Barnaul_Port_Spe_Value_20230515 >									
	//        < zA3efK1nCZDaxK21sZi2W545JPod7qxjGqL13Gl0gOPKWz28o3J5V1u3KVUiWyvt >									
	//        < 1E-018 limites [ 434305016,917108 ; 454214990,847313 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A1CA8DF2FA935514C0 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_IV_metadata_line_21_____Beringovsky Port of Beringovsky_Port_Spe_Value_20230515 >									
	//        < ygE0U3SWCQKO3AmDvvDS7l4L1KT2unp20bPVK2fwX2uR2dnz406O82zdYgbII559 >									
	//        < 1E-018 limites [ 454214990,847313 ; 471722208,836635 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A935514C0AFBAEF9C7 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_22_____Beringovsky_Port_Spe_Value_20230515 >									
	//        < n2Hw9Smuv7575yWD3wLifMoR8ZRt71IdXKd4W8D65ck3F9P7KqqtVHh2hXFftw6i >									
	//        < 1E-018 limites [ 471722208,836635 ; 498319377,499027 ] >									
	//        < 0x0000000000000000000000000000000000000000000000AFBAEF9C7B9A3708C9 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_23_____Beryozovo_Port_Spe_Value_20230515 >									
	//        < xqqUq2bk869If95I42v9Mi0TlPxK8e1NFxRhGBD9i7f9Ai7l2LZMZWSE1Qe1MfqN >									
	//        < 1E-018 limites [ 498319377,499027 ; 517033952,063838 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B9A3708C9C09C3357A >									
	//     < SEAPORT_Portfolio_IV_metadata_line_24_____Bratsk_Port_Spe_Value_20230515 >									
	//        < WR3xbsrjCDBVVTB636LBIdJLYJ4fA13geVANnxlJR5891xvfN4804d68be4zkt4F >									
	//        < 1E-018 limites [ 517033952,063838 ; 532781471,154111 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C09C3357AC67A0041F >									
	//     < SEAPORT_Portfolio_IV_metadata_line_25_____Bukhta_Nagayeva_Port_Spe_Value_20230515 >									
	//        < Yib38j54afQ3p92Jvu927ws78bjvk76aaBe7RAvbra7j461PGLYOKfuBa89k2z9l >									
	//        < 1E-018 limites [ 532781471,154111 ; 559212293,469135 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C67A0041FD052A4016 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_26_____Central_Office_of_the_Port_Vitino_20230515 >									
	//        < snfTLXTX4xY30Z3v1bqXqf6f6fcVep7U8eyneDhHRHf79QbJImye4aiedc6fsw5b >									
	//        < 1E-018 limites [ 559212293,469135 ; 586063411,447972 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D052A4016DA535CE0C >									
	//     < SEAPORT_Portfolio_IV_metadata_line_27_____Central_Office_of_the_Port_Vitino_20230515 >									
	//        < 2WDDjdql8TFx3UvVEH8BdX5B6T2SspdUoik90c4v2Nhtos6V6i3o8LKqPQF0Iaz2 >									
	//        < 1E-018 limites [ 586063411,447972 ; 606841676,203753 ] >									
	//        < 0x0000000000000000000000000000000000000000000000DA535CE0CE210EEBB8 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_28_____Cherepovets_Port_Spe_Value_20230515 >									
	//        < 83Q6UIuwZSxk58zhTYurb1W17J78T7kn20tZm81IfOb2gf6haKX65lhcgdxbyIO2 >									
	//        < 1E-018 limites [ 606841676,203753 ; 635725199,678673 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E210EEBB8ECD37AE13 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_29_____Commercial_Port_Livadia_Limited_20230515 >									
	//        < RueYN5Wou0zvC6Wjh32I77WhGek98XFcJGl9Zd6lZ503MML83tK6MLT99TkX8m27 >									
	//        < 1E-018 limites [ 635725199,678673 ; 655475982,08664 ] >									
	//        < 0x0000000000000000000000000000000000000000000000ECD37AE13F42F0FB74 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_30_____Commercial_Port_Livadia_Limited_20230515 >									
	//        < akPcyo1Hn1WvGY1afy0LFea5Tw99E4lSH4I0RDP9zU58Rql6hZ6ec9Lu88z65M1o >									
	//        < 1E-018 limites [ 655475982,08664 ; 679259830,887871 ] >									
	//        < 0x0000000000000000000000000000000000000000000000F42F0FB74FD0B44164 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < SEAPORT_Portfolio_IV_metadata_line_31_____De Kastri Port of De Kastri_Port_Spe_Value_20230515 >									
	//        < Cbaa8bdX7eTt4b0vE77LfECEGHIKiLML62qrd15ik9x62K3dGg5wwVCkbKPzxv54 >									
	//        < 1E-018 limites [ 679259830,887871 ; 704996877,54202 ] >									
	//        < 0x000000000000000000000000000000000000000000000FD0B44164106A1BDF3E >									
	//     < SEAPORT_Portfolio_IV_metadata_line_32_____De_Kastri_Port_Spe_Value_20230515 >									
	//        < issVYsiJ086AumzdbBfbSIPL9Ou13BeQ5czJo70NzRgB68GdUepj85MsUPOEd0wO >									
	//        < 1E-018 limites [ 704996877,54202 ; 730037958,342547 ] >									
	//        < 0x00000000000000000000000000000000000000000000106A1BDF3E10FF5D876E >									
	//     < SEAPORT_Portfolio_IV_metadata_line_33_____Dikson Port of Dikson_Port_Spe_Value_20230515 >									
	//        < zknn51i8qJDH3v68Lxm9zk5u1114J5TebAVq2dNjYo8ayLwI9O7f9Txb4YM87h6D >									
	//        < 1E-018 limites [ 730037958,342547 ; 757028901,735398 ] >									
	//        < 0x0000000000000000000000000000000000000000000010FF5D876E11A03E70B1 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_34_____Dudinka Port of Dudinka_Port_Spe_Value_20230515 >									
	//        < ksU1Nkf2P2E5EI0NMp9a8rNQTa6j7FEaDj8QCwowrzCQxqXrTaz62kv5L31X8I3z >									
	//        < 1E-018 limites [ 757028901,735398 ; 776290213,194866 ] >									
	//        < 0x0000000000000000000000000000000000000000000011A03E70B112130CDE7B >									
	//     < SEAPORT_Portfolio_IV_metadata_line_35_____Dudinka_Port_Spe_Value_20230515 >									
	//        < B5Z65EmbGwTcyn91P9Z3JA1gbD9mBXU4t9wv6H6401kJq34IwrZBp3H33CPm6nnM >									
	//        < 1E-018 limites [ 776290213,194866 ; 792919765,209935 ] >									
	//        < 0x0000000000000000000000000000000000000000000012130CDE7B12762B8D3C >									
	//     < SEAPORT_Portfolio_IV_metadata_line_36_____Dzerzhinsk_Port_Spe_Value_20230515 >									
	//        < y2MX710fxwzs2mx3D05LPJFNz44AOO9R4GSGCqrxJ242o60v6Zn6G670aR0NNvPH >									
	//        < 1E-018 limites [ 792919765,209935 ;  ] >									
	//        < 0x0000000000000000000000000000000000000000000012762B8D3C130213FDFE >									
	//     < SEAPORT_Portfolio_IV_metadata_line_37_____Egvekinot Port of Egvekinot_Port_Spe_Value_20230515 >									
	//        < WL8iJ31oS2iPT6e7qRn4N8Xr6TE4x46ry570FlrU700FDjx80PBa6p1d5F5dMZsh >									
	//        < 1E-018 limites [ 816392427,620288 ; 838214717,335677 ] >									
	//        < 0x00000000000000000000000000000000000000000000130213FDFE13842629E9 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_38_____Egvekinot_Port_Spe_Value_20230515 >									
	//        < 5RcB7Ljk71w4033CT1NL68BI2VO18nvlRNkJn6iLDsfyDBTPgPR235PdxpNaqWt8 >									
	//        < 1E-018 limites [ 838214717,335677 ; 858255203,257222 ] >									
	//        < 0x0000000000000000000000000000000000000000000013842629E913FB9984B9 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_39_____Ekonomiya_Port_Spe_Value_20230515 >									
	//        < rNGFGpO29lF2I7zHnD2JhKNXZyc3c0Erey1rQ4vw83GPJ9tdKCQ21M63Q8mUz5UW >									
	//        < 1E-018 limites [ 858255203,257222 ; 883961427,0895 ] >									
	//        < 0x0000000000000000000000000000000000000000000013FB9984B91494D21A68 >									
	//     < SEAPORT_Portfolio_IV_metadata_line_40_____Feodossiya_Port_Spe_Value_20230515 >									
	//        < nJScjbP7w9l65MYh0hFoXVHI703PA6EbzBma524eS22Lh1i42vah27Pxu55s3vv3 >									
	//        < 1E-018 limites [ 883961427,0895 ; 903053077,115555 ] >									
	//        < 0x000000000000000000000000000000000000000000001494D21A6815069DA633 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}