pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_VI_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_VI_883		"	;
		string	public		symbol =	"	RE883VI		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1518671758713550000000000000					;	
										
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
	//     < RE_Portfolio_VI_metadata_line_1_____AXIS_Specialty_Limited_Ap_Ap_20250515 >									
	//        < 93UIUUPx6sXIljgB6wKnK41815M98i3HjW955tOfBN13X835395AxFju9OaFz4Wm >									
	//        < 1E-018 limites [ 1E-018 ; 58476194,9549572 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000015C8B999B >									
	//     < RE_Portfolio_VI_metadata_line_2_____Bahrain_National_Insurance_Company_Bpp_20250515 >									
	//        < A0Ftit5FRsZMdG0Q4y3UN38RyhZ2HDeZOi890747WXB7yZfAiXlJJC42fHA5uzsh >									
	//        < 1E-018 limites [ 58476194,9549572 ; 106810047,899488 ] >									
	//        < 0x000000000000000000000000000000000000000000000015C8B999B27CA334E9 >									
	//     < RE_Portfolio_VI_metadata_line_3_____Bahrain_National_Insurance_Company_Bpp_20250515 >									
	//        < D8X5DEcV2ljt38zeueMRvfbRJkMnpl21bAq94223EwQ7ufn95UU1j7OCbzM82ru1 >									
	//        < 1E-018 limites [ 106810047,899488 ; 161992546,978692 ] >									
	//        < 0x000000000000000000000000000000000000000000000027CA334E93C58D049D >									
	//     < RE_Portfolio_VI_metadata_line_4_____Barbados_BBp_Ocean_International_Reinsurance_Company_Limited_Am_20250515 >									
	//        < bkT29z0k6X3wjlNaOCO3iG3FTMq6622sR3KCZHmp2rHpyZ271qJD36KZGLBSG5b8 >									
	//        < 1E-018 limites [ 161992546,978692 ; 240256011,960736 ] >									
	//        < 0x00000000000000000000000000000000000000000000003C58D049D5980996A0 >									
	//     < RE_Portfolio_VI_metadata_line_5_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < UXKa8g8Vp56OERa4zq5fj1DmkrwMsojS14171Cup5y3G298nuNiO2W0GYyDdqnXm >									
	//        < 1E-018 limites [ 240256011,960736 ; 260014161,993263 ] >									
	//        < 0x00000000000000000000000000000000000000000000005980996A060DCE21FB >									
	//     < RE_Portfolio_VI_metadata_line_6_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < 0Wzzd3oBi3a78e4qxPUn2VXvL7t98C0vj6OP3jYBY7ZPqNMc78ogVT1misV1OXIZ >									
	//        < 1E-018 limites [ 260014161,993263 ; 271442165,890077 ] >									
	//        < 0x000000000000000000000000000000000000000000000060DCE21FB651EBE201 >									
	//     < RE_Portfolio_VI_metadata_line_7_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < 4cImKXx249139eAAiyULf5YofF9heUeZMVVSosX3UE2H3uHX863G54xdhtZ0UJZ0 >									
	//        < 1E-018 limites [ 271442165,890077 ; 282379409,648774 ] >									
	//        < 0x0000000000000000000000000000000000000000000000651EBE2016931CCAD8 >									
	//     < RE_Portfolio_VI_metadata_line_8_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < KHQj1D1JdVUgG9xfjUj8zBlPm31WjLw71nf4adoVhTBj8jjSClSEXRWnJamw3ka0 >									
	//        < 1E-018 limites [ 282379409,648774 ; 329416072,370832 ] >									
	//        < 0x00000000000000000000000000000000000000000000006931CCAD87AB790B39 >									
	//     < RE_Portfolio_VI_metadata_line_9_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < aoNb2kvhm2hf4nu4L9W2Qf7D72atkN9D3j25bW5zNUI8cdm5wKjfFjI1m6CABgj1 >									
	//        < 1E-018 limites [ 329416072,370832 ; 342667547,849822 ] >									
	//        < 0x00000000000000000000000000000000000000000000007AB790B397FA7530D4 >									
	//     < RE_Portfolio_VI_metadata_line_10_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < 66006KP3THB17gQe10yx9hKeLBJ5H8o33k1gnuw98dLc69SK8g3dnQjy1T1qP2AW >									
	//        < 1E-018 limites [ 342667547,849822 ; 369687045,578735 ] >									
	//        < 0x00000000000000000000000000000000000000000000007FA7530D489B81AC21 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VI_metadata_line_11_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < fgnIPwESd3JvFfQwGfPT4MO3Bi8cSusebELTFXLh8ie4g6p1wUQMyPnngO278821 >									
	//        < 1E-018 limites [ 369687045,578735 ; 421910988,385822 ] >									
	//        < 0x000000000000000000000000000000000000000000000089B81AC219D2C915CA >									
	//     < RE_Portfolio_VI_metadata_line_12_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < 1tV2vmNG34w4J76ua504Vq98iy4qbR4DUzB1OcAZIA6IHK9lDiL3Jj1jG7CI3AK2 >									
	//        < 1E-018 limites [ 421910988,385822 ; 452326717,02779 ] >									
	//        < 0x00000000000000000000000000000000000000000000009D2C915CAA8813CDCA >									
	//     < RE_Portfolio_VI_metadata_line_13_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < IYrztLqBVwlA4R73aAlK2Wbv16YcOZV6mf0aT148g14nxvb0YPU0ebr9zLB2og49 >									
	//        < 1E-018 limites [ 452326717,02779 ; 476891498,519504 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A8813CDCAB1A7EAF8F >									
	//     < RE_Portfolio_VI_metadata_line_14_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < vwtH8E72Nicex9G7tkijWUG4E4ui3QNceow5PU84O26232Yogqa420652J37kGkq >									
	//        < 1E-018 limites [ 476891498,519504 ; 529298156,81933 ] >									
	//        < 0x0000000000000000000000000000000000000000000000B1A7EAF8FC52DCE675 >									
	//     < RE_Portfolio_VI_metadata_line_15_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < S5c2teDwzwGKBX4QTNY2R4U8ZfX49A9585Y395814b05EeKF1moWo0wxHDkT7pp1 >									
	//        < 1E-018 limites [ 529298156,81933 ; 586861651,584666 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C52DCE675DA9F7D29A >									
	//     < RE_Portfolio_VI_metadata_line_16_____Barbican_Managing_Agency_Limited_20250515 >									
	//        < Ws9TRPf9KUt25Y0Sc9Vade5lVuY229bZHCo7eN8r1sq1WJV5wRN9lsQrv5Oo2cCC >									
	//        < 1E-018 limites [ 586861651,584666 ; 647953651,818747 ] >									
	//        < 0x0000000000000000000000000000000000000000000000DA9F7D29AF161AD131 >									
	//     < RE_Portfolio_VI_metadata_line_17_____BB_Arab_Orient_Insurance_Company__gig_Jordan__Bpp_20250515 >									
	//        < ZA6zLJgkFx4V0E7LLo81AnIZQXm66304FAtJe4C2W043hJ8aI2s71PiPl58uSu0A >									
	//        < 1E-018 limites [ 647953651,818747 ; 722676815,135166 ] >									
	//        < 0x000000000000000000000000000000000000000000000F161AD13110D37D50DD >									
	//     < RE_Portfolio_VI_metadata_line_18_____Beaufort_Underwriting_Agency_Limited_20250515 >									
	//        < l47nOwhRnbj1GMXx7003Huj0fu1Zj5B86KW8qwq6mmLF8b68C3I4LJqQ25aiAl2r >									
	//        < 1E-018 limites [ 722676815,135166 ; 737785773,924694 ] >									
	//        < 0x0000000000000000000000000000000000000000000010D37D50DD112D8BC1E4 >									
	//     < RE_Portfolio_VI_metadata_line_19_____Beaufort_Underwriting_Agency_Limited_20250515 >									
	//        < 49b1Z8f3ImhwBJ57Mprz4B05XP56q8Hsiz35fivnFrTKe22ijuG44f229Rbs4WIE >									
	//        < 1E-018 limites [ 737785773,924694 ; 816289199,481009 ] >									
	//        < 0x00000000000000000000000000000000000000000000112D8BC1E41301767A80 >									
	//     < RE_Portfolio_VI_metadata_line_20_____Beaufort_Underwriting_Agency_Limited_20250515 >									
	//        < r39fOmBVMZvFoaO0C9E0208F8b00dsoGty1pVkG8ouCNtE9UFB53AhRTi144B7h8 >									
	//        < 1E-018 limites [ 816289199,481009 ; 867562577,72788 ] >									
	//        < 0x000000000000000000000000000000000000000000001301767A8014331371E0 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VI_metadata_line_21_____Beaufort_Underwriting_Agency_Limited_20250515 >									
	//        < k7IPE6AH92H6Z0W0f7fXk5rsgSB239q9bV8a735rKRHOA2V0h1xlt7dj6ckml60a >									
	//        < 1E-018 limites [ 867562577,72788 ; 913190317,096599 ] >									
	//        < 0x0000000000000000000000000000000000000000000014331371E0154309D991 >									
	//     < RE_Portfolio_VI_metadata_line_22_____Beaufort_Underwriting_Agency_Limited_20250515 >									
	//        < 2t6bqH2y3paeS5aBRrY79DTgEe4w05lsz2EBM9n9T8g4k7Ek83a32ICD2ydv93sx >									
	//        < 1E-018 limites [ 913190317,096599 ; 961785546,146919 ] >									
	//        < 0x00000000000000000000000000000000000000000000154309D9911664B048EA >									
	//     < RE_Portfolio_VI_metadata_line_23_____Beazley_Furlonge_Limited_20250515 >									
	//        < X465Ox66wLf09Z96I4mU07x2Jm586MKI3S67P493qQ6UDV26GScs2O1ycVbbJDS3 >									
	//        < 1E-018 limites [ 961785546,146919 ; 973625504,348361 ] >									
	//        < 0x000000000000000000000000000000000000000000001664B048EA16AB42A096 >									
	//     < RE_Portfolio_VI_metadata_line_24_____Beazley_Furlonge_Limited_20250515 >									
	//        < d42x39rMK8rSxxZ3J1y9yTK9GP7ge63jQq3DO058E2Xv6C37lZru8xA1t932OAe3 >									
	//        < 1E-018 limites [ 973625504,348361 ; 987132117,658167 ] >									
	//        < 0x0000000000000000000000000000000000000000000016AB42A09616FBC41569 >									
	//     < RE_Portfolio_VI_metadata_line_25_____Beazley_Furlonge_Limited_20250515 >									
	//        < 6gvuH8915D5F1xv0GS8go2zBsRf0L3gB8JgK5eflN3jbnAc17w9zemjhL361n0h9 >									
	//        < 1E-018 limites [ 987132117,658167 ; 1049031449,41095 ] >									
	//        < 0x0000000000000000000000000000000000000000000016FBC41569186CB6F7E1 >									
	//     < RE_Portfolio_VI_metadata_line_26_____Beazley_Furlonge_Limited_20250515 >									
	//        < 91HE6eya3NSnHAK6Wb41E8HWIy1jqcTr61XT10y5gj93F41kJs0z0v4v1S96h36u >									
	//        < 1E-018 limites [ 1049031449,41095 ; 1061078629,80403 ] >									
	//        < 0x00000000000000000000000000000000000000000000186CB6F7E118B48581B8 >									
	//     < RE_Portfolio_VI_metadata_line_27_____Beazley_Furlonge_Limited_20250515 >									
	//        < PY74vbjUfO02hw9GS5K7Ghgpv6j3ocsX3k9pn2Am4I696hX48aZoVb3wo76CGUOI >									
	//        < 1E-018 limites [ 1061078629,80403 ; 1127323020,54141 ] >									
	//        < 0x0000000000000000000000000000000000000000000018B48581B81A3F5E6CDA >									
	//     < RE_Portfolio_VI_metadata_line_28_____Beazley_Furlonge_Limited_20250515 >									
	//        < dgveAm8a50n2EUBZd91XOFt4nZRRytvbhF907w4kNmvl9g55iikDIqhfvl86tahv >									
	//        < 1E-018 limites [ 1127323020,54141 ; 1144498730,42965 ] >									
	//        < 0x000000000000000000000000000000000000000000001A3F5E6CDA1AA5BE7A86 >									
	//     < RE_Portfolio_VI_metadata_line_29_____Beazley_Furlonge_Limited_20250515 >									
	//        < 549v09673D169bHdGlM7qe5dfYnKNBY7CUQxUOBhnp49FAJ0Du0VB6aD0PV4P0X1 >									
	//        < 1E-018 limites [ 1144498730,42965 ; 1162248478,27049 ] >									
	//        < 0x000000000000000000000000000000000000000000001AA5BE7A861B0F8A71C7 >									
	//     < RE_Portfolio_VI_metadata_line_30_____Beazley_Furlonge_Limited_20250515 >									
	//        < l7PYT0xen3e55O8n22lJ8s2k993y5GSVORtaUlOG99VIHA9b3f38tkK84e1WbJIK >									
	//        < 1E-018 limites [ 1162248478,27049 ; 1211123828,41166 ] >									
	//        < 0x000000000000000000000000000000000000000000001B0F8A71C71C32DC4F6D >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_VI_metadata_line_31_____Beazley_Furlonge_Limited_20250515 >									
	//        < pfYnBXTSyHOOH8bd6DrqZFga5x8yoUnEs9O320Y3ELm7REu7g8m9S80tpn8W7S4f >									
	//        < 1E-018 limites [ 1211123828,41166 ; 1229969630,17424 ] >									
	//        < 0x000000000000000000000000000000000000000000001C32DC4F6D1CA330B8BD >									
	//     < RE_Portfolio_VI_metadata_line_32_____Beazley_Furlonge_Limited_20250515 >									
	//        < CQb7u29014hI4j31iuIIKC10cPqnmYiG8QX5Btjv58x1QpY67Ctnfw28qrlksh7V >									
	//        < 1E-018 limites [ 1229969630,17424 ; 1254347214,90725 ] >									
	//        < 0x000000000000000000000000000000000000000000001CA330B8BD1D347DF6C6 >									
	//     < RE_Portfolio_VI_metadata_line_33_____Beazley_Furlonge_Limited_20250515 >									
	//        < e4t3LnjaXFA1NFc9p4fCS69fp6nM551pBG2086AGe8On29brno2ZxXvw5g06HzXJ >									
	//        < 1E-018 limites [ 1254347214,90725 ; 1319205031,23991 ] >									
	//        < 0x000000000000000000000000000000000000000000001D347DF6C61EB7132347 >									
	//     < RE_Portfolio_VI_metadata_line_34_____Beazley_Furlonge_Limited_20250515 >									
	//        < B67U0gq8S8T3kKQ2U1Iv72WTN2wVFo9BVxiO33rS495L4gWr263LSLnwDCY6Y962 >									
	//        < 1E-018 limites [ 1319205031,23991 ; 1353643044,52268 ] >									
	//        < 0x000000000000000000000000000000000000000000001EB71323471F84576038 >									
	//     < RE_Portfolio_VI_metadata_line_35_____Beazley_Furlonge_Limited_20250515 >									
	//        < bUDby43CVmoa3m46w15ky76r6V59F1eC26Rgk5Uy697tyFO06Ne4A7ey92aX2O32 >									
	//        < 1E-018 limites [ 1353643044,52268 ; 1369547932,88141 ] >									
	//        < 0x000000000000000000000000000000000000000000001F845760381FE3244F3C >									
	//     < RE_Portfolio_VI_metadata_line_36_____Beazley_Furlonge_Limited_20250515 >									
	//        < g8X540lhZmq5b54n9ZTZjh1O2xAvwceKPLJFUibe9EBCa654OomIO7zGuOCfgZPb >									
	//        < 1E-018 limites [ 1369547932,88141 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001FE3244F3C212273C6CF >									
	//     < RE_Portfolio_VI_metadata_line_37_____Belgium_AA_Aviabel_Cie_Belge_d_Assurances_Aviation_SA_Am_20250515 >									
	//        < XDqH1E8711jF47Ip2R4G020242t9l4YQ4Kc335Nc347lVXSPtZi585QbqN14PB2A >									
	//        < 1E-018 limites [ 1423119331,47459 ; 1439452408,3517 ] >									
	//        < 0x00000000000000000000000000000000000000000000212273C6CF2183CE12F7 >									
	//     < RE_Portfolio_VI_metadata_line_38_____Belgium_AA_Aviabel_Cie_Belge_d_Assurances_Aviation_SA_Am_20250515 >									
	//        < FkPclwS6IU2NEoj9o4Sci3ziI4123s06165lZ5L93Y541C736ek86TZ6uR58B8Gi >									
	//        < 1E-018 limites [ 1439452408,3517 ; 1467333157,99716 ] >									
	//        < 0x000000000000000000000000000000000000000000002183CE12F72229FCB8CB >									
	//     < RE_Portfolio_VI_metadata_line_39_____Berkley_Regional_Insurance_Co_Ap_Ap_20250515 >									
	//        < XTMveZ91O2SpwQEbgZ7pr4ru8capXo3TEkFS0DxeOV58DNO1d289NUV1YBTMp194 >									
	//        < 1E-018 limites [ 1467333157,99716 ; 1487515326,21528 ] >									
	//        < 0x000000000000000000000000000000000000000000002229FCB8CB22A2484441 >									
	//     < RE_Portfolio_VI_metadata_line_40_____Berkshire_Hathaway_Incorporated_20250515 >									
	//        < 5IgmT65b0y8d8W6XAv68qMoDGMch92ypHef0X2PPnrDrzAi6j1Ur8iO86p2scwY1 >									
	//        < 1E-018 limites [ 1487515326,21528 ; 1518671758,71355 ] >									
	//        < 0x0000000000000000000000000000000000000000000022A2484441235BFD35B3 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}