pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_I_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_I_883		"	;
		string	public		symbol =	"	RE883I		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1591676265575320000000000000					;	
										
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
	//     < RE_Portfolio_I_metadata_line_1_____AA_Euler_Hermes_SA_AAm_20250515 >									
	//        < MGR3m39Pcxxd38Tw15eOSc39puzA1XdnMjO1JHMf02oDPoLqwPr22COs40XkOvAt >									
	//        < 1E-018 limites [ 1E-018 ; 23466777,8761341 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000008BDF780F >									
	//     < RE_Portfolio_I_metadata_line_2_____AA_Euler_Hermes_SA_AAm_20250515 >									
	//        < 14uzr4et42wJvn10409D50cNoG5ATiJYs1gG2UdU9Pk0rzU7se3540s6BZVu2h41 >									
	//        < 1E-018 limites [ 23466777,8761341 ; 37807926,3543451 ] >									
	//        < 0x0000000000000000000000000000000000000000000000008BDF780FE15A532F >									
	//     < RE_Portfolio_I_metadata_line_3_____Abu_Dhabi_National_Insurance_Co__PSC__Am_m_20250515 >									
	//        < 54ARHxYNL41UCnnZb6B3h2bVq2qJXGuHo3EtaO78elTemh7NFet0oNmsmiEUQ8FK >									
	//        < 1E-018 limites [ 37807926,3543451 ; 73081950,0897789 ] >									
	//        < 0x00000000000000000000000000000000000000000000000E15A532F1B39A36B4 >									
	//     < RE_Portfolio_I_metadata_line_7_____Ace_Group_of_Companies_20250515 >									
	//        < MGR3m39Pcxxd38Tw15eOSc39puzA1XdnMjO1JHMf02oDPoLqwPr22COs40XkOvAt >									
	//        < 1E-018 limites [ 73081950,0897789 ; 134176053,834668 ] >									
	//        < 0x00000000000000000000000000000000000000000000001B39A36B431FC06AFB >									
	//     < RE_Portfolio_I_metadata_line_8_____Ace_Group_of_Companies_20250515 >									
	//        < I69v5ClJ4b14E3l6RfmXqI8035jUy46Qc7lNQhL7B80LQ8ZZ5phVPAxe4laZyyn0 >									
	//        < 1E-018 limites [ 277969870,344396 ; 294602007,09604 ] >									
	//        < 0x000000000000000000000000000000000000000000000031FC06AFB44E3A6C93 >									
	//     < RE_Portfolio_I_metadata_line_6_____ACE_European_Group_Limited_AA_App_20250515 >									
	//        < uirf25wA9t6VuCEU796GMdLF8wIQfnoe58yp6cWocsg4Ajphu3RK3wZFT6qnY6Xu >									
	//        < 1E-018 limites [ 294602007,09604 ; 328167666,886427 ] >									
	//        < 0x000000000000000000000000000000000000000000000044E3A6C9361C5B96C1 >									
	//     < RE_Portfolio_I_metadata_line_10_____ACE_Tembest_Reinsurance_Limited__Chubb_Tembest_Reinsurance_Limited___m_App_20250515 >									
	//        < 89SsNu3CC9Qm4FTp1kDah1Aq0MU9WAADyG9ZuC0LsgMp3oD2Q8r6HVHs4Yzkd8Cy >									
	//        < 1E-018 limites [ 328167666,886427 ; 388131600,02045 ] >									
	//        < 0x000000000000000000000000000000000000000000000061C5B96C1678D45E8E >									
	//     < RE_Portfolio_I_metadata_line_8_____Ace_Group_of_Companies_20250515 >									
	//        < 5yuBsTtVr0Z2CDm4BcxDFZjk4BOT71d5dqd37aFqodjtHwXa59Nk7GB84GYKBB3B >									
	//        < 1E-018 limites [ 277969870,344396 ; 294602007,09604 ] >									
	//        < 0x0000000000000000000000000000000000000000000000678D45E8E6DBF6FEF9 >									
	//     < RE_Portfolio_I_metadata_line_9_____ACE_Limited_20250515 >									
	//        < h42QuYHXTu84f30rMj56ozR6nz0dHs3MkU2L12v1jcN21XEYEPeg1q42YcP38H88 >									
	//        < 1E-018 limites [ 294602007,09604 ; 328167666,886427 ] >									
	//        < 0x00000000000000000000000000000000000000000000006DBF6FEF97A40820D4 >									
	//     < RE_Portfolio_I_metadata_line_10_____ACE_Tembest_Reinsurance_Limited__Chubb_Tembest_Reinsurance_Limited___m_App_20250515 >									
	//        < SACtV58n2y34TUl56K58ISbV82AS3hJO5CLtS2N0lGk9ep2v28YvGl4O3cltv91h >									
	//        < 1E-018 limites [ 328167666,886427 ; 388131600,02045 ] >									
	//        < 0x00000000000000000000000000000000000000000000007A40820D490971D436 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_I_metadata_line_11_____ACE_Tempest_Reinsurance_Limited_20250515 >									
	//        < 5VbH9L78M031ns1O5VbtzcQ8hrUI7q68arlr6O1m3y4eh0K5hghs0a3PW31jk74F >									
	//        < 1E-018 limites [ 388131600,02045 ; 415184250,130549 ] >									
	//        < 0x000000000000000000000000000000000000000000000090971D4369AAB0E5A9 >									
	//     < RE_Portfolio_I_metadata_line_12_____ACE_Tempest_Reinsurance_Limited_20250515 >									
	//        < efrCS1gj7F73u81xfD3x49jzpV4pd7AmARTQ7j222sWEO5tq6QH0vPaqAErZT4R1 >									
	//        < 1E-018 limites [ 415184250,130549 ; 451109181,358069 ] >									
	//        < 0x00000000000000000000000000000000000000000000009AAB0E5A9A80D1FDEB >									
	//     < RE_Portfolio_I_metadata_line_13_____Ace_Underwriting_Agencies_Limited_20250515 >									
	//        < QQ2HA8Vmr4fVf6W1ZR8cH8w95rM7FsVZq6844bB0RLhJr016n58zAJ84qx3Q30oa >									
	//        < 1E-018 limites [ 451109181,358069 ; 507141771,80459 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A80D1FDEBBCECCF090 >									
	//     < RE_Portfolio_I_metadata_line_14_____ACR_Capital_20250515 >									
	//        < vfzNTP9749Iq8S01v0q140rptXqFa70NT563p8W838zbYyDiBzLzw83i49ZRZ7j1 >									
	//        < 1E-018 limites [ 507141771,80459 ; 574494906,22049 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BCECCF090D6041AAB2 >									
	//     < RE_Portfolio_I_metadata_line_15_____ACR_Capital_Holdings_Pte_Limited_20250515 >									
	//        < JU10vasbp22K1TMryZwfd9810molwwdIt7GrdQjx1r7dQz4iGMbD369w8G3Ci1LI >									
	//        < 1E-018 limites [ 574494906,22049 ; 599550539,492484 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D6041AAB2DF5998771 >									
	//     < RE_Portfolio_I_metadata_line_16_____ACR_ReTakaful_Berhad__ACR_ReTakaful__Bpp_20250515 >									
	//        < D6e0O4LsHeJGWTeNANkfM7Di30n4S6kCwD0boHWoqIoc9ur23Iqa7v8j2P7G472m >									
	//        < 1E-018 limites [ 599550539,492484 ; 626047205,336318 ] >									
	//        < 0x0000000000000000000000000000000000000000000000DF5998771E93883B89 >									
	//     < RE_Portfolio_I_metadata_line_17_____Advent_Underwriting_Limited_20250515 >									
	//        < ykd44EaA2mXrY45V868yDyE4z68ukFIj6cu2pYIfF0Z59tOa1zNyslM61y4D5qpg >									
	//        < 1E-018 limites [ 626047205,336318 ; 675225782,0429 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E93883B89FB8A8C910 >									
	//     < RE_Portfolio_I_metadata_line_18_____Advent_Underwriting_Limited_20250515 >									
	//        < 6558YU905Wq4Ai14FyhWIdYdRf2DgnHAafQbML2xkRRp2MklQMkQku8UiC5lz804 >									
	//        < 1E-018 limites [ 675225782,0429 ; 756137595,825876 ] >									
	//        < 0x000000000000000000000000000000000000000000000FB8A8C910119AEE6A52 >									
	//     < RE_Portfolio_I_metadata_line_19_____Aegis_Managing_Agency_Limited_20250515 >									
	//        < Yg1Nz8XWGKZ5A865VzDjR1rn0T46L00wx5CJ2J579rkIb8UK5mHY7rj8DWOpmbxo >									
	//        < 1E-018 limites [ 756137595,825876 ; 798741625,876159 ] >									
	//        < 0x00000000000000000000000000000000000000000000119AEE6A521298DF018F >									
	//     < RE_Portfolio_I_metadata_line_20_____AEGIS_Managing_Agency_Limited_20250515 >									
	//        < XA5RmDhQe1gg0tlXspwGq80o98Q6X5HkBVJ03FH1m8kBDx4sAT378Eyv05b8s6I7 >									
	//        < 1E-018 limites [ 798741625,876159 ; 868138618,229641 ] >									
	//        < 0x000000000000000000000000000000000000000000001298DF018F14368269B2 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_I_metadata_line_21_____AEGON_NV_20250515 >									
	//        < m26v9Tz0FsLszrDM10eJ68FKp0s61s3H0HJn3J3n5aEbu8HoLU6Xu7TgJZTbaFw8 >									
	//        < 1E-018 limites [ 868138618,229641 ; 882720794,826364 ] >									
	//        < 0x0000000000000000000000000000000000000000000014368269B2148D6D0C6E >									
	//     < RE_Portfolio_I_metadata_line_22_____Aegon_NV_Am_20250515 >									
	//        < ElLDG106wbX8SH8pJvGpxOnMJxGlET4yu2NkKJKOgz2szohj20o2JVxe9cQlX8cA >									
	//        < 1E-018 limites [ 882720794,826364 ; 898758885,078411 ] >									
	//        < 0x00000000000000000000000000000000000000000000148D6D0C6E14ED053B6F >									
	//     < RE_Portfolio_I_metadata_line_23_____Africa_Re_20250515 >									
	//        < P6WH9g794sj698L00i7dFACuGrd0f0Vur67mtDd466pt35Cd7Es9BhATik6Ees75 >									
	//        < 1E-018 limites [ 898758885,078411 ; 946122877,964643 ] >									
	//        < 0x0000000000000000000000000000000000000000000014ED053B6F160754F328 >									
	//     < RE_Portfolio_I_metadata_line_24_____African_Re_Am_A_20250515 >									
	//        < p7YRryw12T9tC0Z39N7nq559f3I5yNBo2rWc75c06bOy19vM7Bc67UO07s9OafJV >									
	//        < 1E-018 limites [ 946122877,964643 ; 965358372,633065 ] >									
	//        < 0x00000000000000000000000000000000000000000000160754F3281679FBFC43 >									
	//     < RE_Portfolio_I_metadata_line_25_____AIG_Europe_Limited_Ap_A_20250515 >									
	//        < uKX10f6Yo1w9sA8I8u83ufyC972m828A370ROe6iG22Tee5G5H5gkIwHJX84vk8T >									
	//        < 1E-018 limites [ 965358372,633065 ; 989910438,093553 ] >									
	//        < 0x000000000000000000000000000000000000000000001679FBFC43170C5376D5 >									
	//     < RE_Portfolio_I_metadata_line_26_____AIOI_Nissay_Dowa_Insurance_co_Limited_Ap_Ap_20250515 >									
	//        < av00w72qCa3REFpUA56Rv3pSuZnA9LBzIgz012vbKv08SpDXREi92KuX7l36OK9P >									
	//        < 1E-018 limites [ 989910438,093553 ; 1005036319,37359 ] >									
	//        < 0x00000000000000000000000000000000000000000000170C5376D517667BBA35 >									
	//     < RE_Portfolio_I_metadata_line_27_____Al_Ain_Ahlia_Co_m_m_A3_20250515 >									
	//        < 9H6UlMINa2H1soX0iBPX1s2M007cFciXmeKA4k422edw9PDUX91IGZhy25fbT7mb >									
	//        < 1E-018 limites [ 1005036319,37359 ; 1074144145,91984 ] >									
	//        < 0x0000000000000000000000000000000000000000000017667BBA35190265E6F3 >									
	//     < RE_Portfolio_I_metadata_line_28_____Al_Buhaira_National_Insurance_Co__PSC__BBp_m_20250515 >									
	//        < 7KR2BZYnxCj3W4pMj9p03Xkgw7eH7WDX1mqVBeNBSBShhI16h5WjWjHTYs4uLk6E >									
	//        < 1E-018 limites [ 1074144145,91984 ; 1155256692,99988 ] >									
	//        < 0x00000000000000000000000000000000000000000000190265E6F31AE5DDD3A7 >									
	//     < RE_Portfolio_I_metadata_line_29_____Al_Dhafra_Ins_Co_20250515 >									
	//        < buBigs1y460UNH9V4K49q57e9686068EMdXNv6MEd2QB1qt59WOVm12jms0MJyXI >									
	//        < 1E-018 limites [ 1155256692,99988 ; 1183878672,65548 ] >									
	//        < 0x000000000000000000000000000000000000000000001AE5DDD3A71B90778075 >									
	//     < RE_Portfolio_I_metadata_line_30_____Al_Koot_Insurance_&_Reinsurance_Company_SAQ_Am_20250515 >									
	//        < 4BRouiCWCQ68P1KeR5ua8AT4ph3q8GwJqvfrH0F39XR6y8B1zYU4U9Ir80qG006x >									
	//        < 1E-018 limites [ 1183878672,65548 ; 1233858401,84714 ] >									
	//        < 0x000000000000000000000000000000000000000000001B907780751CBA5E842C >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_I_metadata_line_31_____Alamance_Reinsurance_Marketplace_20250515 >									
	//        < Vn3Es8zT3ND7qxXzjb6upKBmuqW4JGiiLV6KvP9DxFJq15GpPmqBfJft6Rs60u8A >									
	//        < 1E-018 limites [ 1233858401,84714 ; 1264820467,11963 ] >									
	//        < 0x000000000000000000000000000000000000000000001CBA5E842C1D72EAE0EB >									
	//     < RE_Portfolio_I_metadata_line_32_____Alamance_Reinsurance_Marketplace_20250515 >									
	//        < e8GxjzejB6y9r32WQL9Iab17d6Kvj4I1wB51og5TXDxH0CLsEACDc3FM3uqf0YKH >									
	//        < 1E-018 limites [ 1264820467,11963 ; 1283756862,01428 ] >									
	//        < 0x000000000000000000000000000000000000000000001D72EAE0EB1DE3C9862D >									
	//     < RE_Portfolio_I_metadata_line_33_____Alfa_Strakhovanie_Plc_20250515 >									
	//        < 0WViis0N2O930PuZ3fpzQLdS7q009KOBuFdv9r88ixdb5WIN2qtyUkk910ympbCp >									
	//        < 1E-018 limites [ 1283756862,01428 ; 1349863972,00733 ] >									
	//        < 0x000000000000000000000000000000000000000000001DE3C9862D1F6DD0F804 >									
	//     < RE_Portfolio_I_metadata_line_34_____Algeria_BBBm_Compagnie_Centrale_De_Reassurance__CCR__Bp_20250515 >									
	//        < w3Q7dSK50A5rjkYs5Y3GN4i6cYkV23tMwhcGG9cYVt7cXs0RML8g72gv686253s5 >									
	//        < 1E-018 limites [ 1349863972,00733 ; 1423344515,98195 ] >									
	//        < 0x000000000000000000000000000000000000000000001F6DD0F8042123CB6182 >									
	//     < RE_Portfolio_I_metadata_line_35_____Algeria_BBBm_Compagnie_Centrale_De_Reassurance__CCR__Bp_20250515 >									
	//        < 1L09VSpqd5352A9I09tvNfc05DlKBaQ3Qb8ymoHrP52VU5s5447e1R1lRKg40PEl >									
	//        < 1E-018 limites [ 1423344515,98195 ; 1437217512,29135 ] >									
	//        < 0x000000000000000000000000000000000000000000002123CB618221767BE4B1 >									
	//     < RE_Portfolio_I_metadata_line_36_____Alliance_Insurance__PSC__Am_20250515 >									
	//        < sgH7pJ29ja0Nx2u457YV0ts6NB51vINil960fDYno6ynS0zrL17Ow51dS40h1L8l >									
	//        < 1E-018 limites [ 1437217512,29135 ;  ] >									
	//        < 0x0000000000000000000000000000000000000000000021767BE4B122D2D1D670 >									
	//     < RE_Portfolio_I_metadata_line_37_____Allianz_Global_Corporate_&_Specialty_SE_AA_Ap_20250515 >									
	//        < n56b380a50AH7M1YM4TlPYc632KL80uEP7zA295H8e1c9vpgJcTAmqoqYE4s7168 >									
	//        < 1E-018 limites [ 1495658548,44372 ; 1537055049,94057 ] >									
	//        < 0x0000000000000000000000000000000000000000000022D2D1D67023C98FE2D6 >									
	//     < RE_Portfolio_I_metadata_line_38_____Allianz_Global_Risks_US_Insurance_Co_AA_20250515 >									
	//        < jjo6iUwbdK1qCqdn85DX6b99SYZ21UN6z0yvWII49iXv1LUvgClG1O4JE10HkCSg >									
	//        < 1E-018 limites [ 1537055049,94057 ; 1548694914,34345 ] >									
	//        < 0x0000000000000000000000000000000000000000000023C98FE2D6240EF0E8DE >									
	//     < RE_Portfolio_I_metadata_line_39_____Allianz_Private_KrankenversicherungsmAG_AA_20250515 >									
	//        < 77Fbsr5HRr252IN58Wpy5V9AOXAimYkpYS6OX60jzp4bRVjB7rZPswdo8r64jrPt >									
	//        < 1E-018 limites [ 1548694914,34345 ; 1578492143,45902 ] >									
	//        < 0x00000000000000000000000000000000000000000000240EF0E8DE24C08BDF7D >									
	//     < RE_Portfolio_I_metadata_line_40_____Allianz_Risk_Transfer_AG_AAm_20250515 >									
	//        < 8gw9ZNBr5JvL1m8vcB9Me21T8y6R4lrmzDes8wxmE7F9pxuWp49T2b2GyHoi9EM9 >									
	//        < 1E-018 limites [ 1578492143,45902 ; 1591676265,57532 ] >									
	//        < 0x0000000000000000000000000000000000000000000024C08BDF7D250F213F31 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}