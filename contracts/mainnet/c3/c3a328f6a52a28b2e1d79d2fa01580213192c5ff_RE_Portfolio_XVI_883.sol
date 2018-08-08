pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_XVI_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_XVI_883		"	;
		string	public		symbol =	"	RE883XVI		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1518764476488520000000000000					;	
										
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
	//     < RE_Portfolio_XVI_metadata_line_1_____Provider_Risk_20250515 >									
	//        < 24hVSNw6R0B3SOE6kGgYW4BYrvsU09QWWc058rDnFt6P9eR84qE4jD30Yp6ggeeH >									
	//        < 1E-018 limites [ 1E-018 ; 10610077,0219288 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000003F3DB34A >									
	//     < RE_Portfolio_XVI_metadata_line_2_____Prudential_Ins_Co_of_America_AAm_Ap_20250515 >									
	//        < wDSn10jI3qqfyMDfEPQ6daDJTGQ3w0rcLOduS27NvynS124USFwcy3xpx03xHC5j >									
	//        < 1E-018 limites [ 10610077,0219288 ; 42558100,173885 ] >									
	//        < 0x0000000000000000000000000000000000000000000000003F3DB34AFDAA83D5 >									
	//     < RE_Portfolio_XVI_metadata_line_3_____PTA_Reinsurance_20250515 >									
	//        < DJtm4EX1G3v8S3Sad4j1QEWT5mGsXbq679w0m7LOEkSh66lB6X81o0tXj2w526f6 >									
	//        < 1E-018 limites [ 42558100,173885 ; 53446628,327494 ] >									
	//        < 0x00000000000000000000000000000000000000000000000FDAA83D513E911724 >									
	//     < RE_Portfolio_XVI_metadata_line_4_____PXRE_Reinsurance_Company_20250515 >									
	//        < 5g5T6H2e0MJ1c92n3oN1uNTmmE200v3jV9cqRkT09t6Xya4X8kv97c37ma778NFS >									
	//        < 1E-018 limites [ 53446628,327494 ; 89413898,8703253 ] >									
	//        < 0x000000000000000000000000000000000000000000000013E911724214F2CA33 >									
	//     < RE_Portfolio_XVI_metadata_line_5_____Qatar_General_Insurance_and_Reinsurance_Company_SAQ_m_Am_20250515 >									
	//        < jYyUzkcxoyC62Bdyh8E68Nkg82YuaN24i7ERUvbCwaReN932jCAE4fN0ueh5o5i6 >									
	//        < 1E-018 limites [ 89413898,8703253 ; 121272137,742799 ] >									
	//        < 0x0000000000000000000000000000000000000000000000214F2CA332D2D69AC2 >									
	//     < RE_Portfolio_XVI_metadata_line_6_____Qatar_Insurance_Co_SAQ_A_A_20250515 >									
	//        < wLzMSZ2IE37Iu7cUSdkshkLhkSqmzMz0Xk253l4eq4H4Cuk3XwGbAm7nGh6M9ET7 >									
	//        < 1E-018 limites [ 121272137,742799 ; 145669503,291727 ] >									
	//        < 0x00000000000000000000000000000000000000000000002D2D69AC23644207AD >									
	//     < RE_Portfolio_XVI_metadata_line_7_____Qatar_Reinsurance_20250515 >									
	//        < sy9n16U8t713ewMCpnTonS9HJc6hu78vl41WcQz8V4k4f8M3Jy35CY8FXJujIFD3 >									
	//        < 1E-018 limites [ 145669503,291727 ; 196247332,457158 ] >									
	//        < 0x00000000000000000000000000000000000000000000003644207AD491B9AC31 >									
	//     < RE_Portfolio_XVI_metadata_line_8_____Qatar_Reinsurance_Company_Limited_A_20250515 >									
	//        < BVqenG95Szq4b30y0TJ98XUZ50K93awdRPQnVC1N4MDH0Z4r683QCXYwea3m7cJt >									
	//        < 1E-018 limites [ 196247332,457158 ; 272679244,427854 ] >									
	//        < 0x0000000000000000000000000000000000000000000000491B9AC316594B83CE >									
	//     < RE_Portfolio_XVI_metadata_line_9_____Qatar_Reinsurance_Company_Limited_A_m_20250515 >									
	//        < 72dwX50Y1a4W6hW1En6m033HCzn13j3aHvdEq56v7THHqRx2Y89z4iYRD7LmPU3x >									
	//        < 1E-018 limites [ 272679244,427854 ; 354091750,960496 ] >									
	//        < 0x00000000000000000000000000000000000000000000006594B83CE83E8D242C >									
	//     < RE_Portfolio_XVI_metadata_line_10_____QBE&#160;Underwriting_Limited_20250515 >									
	//        < LDq1359FY7413VyOfWqR16kwVx4qQ0m48u13fl5dNgoAw14KgB73T2a5ouKaqGv7 >									
	//        < 1E-018 limites [ 354091750,960496 ; 393495530,392016 ] >									
	//        < 0x000000000000000000000000000000000000000000000083E8D242C9296A8983 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XVI_metadata_line_11_____QBE_Insurance__Europe__Limited_Ap_A_20250515 >									
	//        < 9aKin7bTm4f5bCW3iBjrH954zOh9a25nJg2U86469Q30GLBN6qiLOx3N9uM8x15H >									
	//        < 1E-018 limites [ 393495530,392016 ; 414796047,185251 ] >									
	//        < 0x00000000000000000000000000000000000000000000009296A89839A8608BE2 >									
	//     < RE_Portfolio_XVI_metadata_line_12_____QBE_Insurance_Group_Limited_20250515 >									
	//        < 4TG1fy8Iv63QhWxd67H98khBT6cmUgoS7Z2lC74Iz7j605p9VQ61v8sDKFNcSETM >									
	//        < 1E-018 limites [ 414796047,185251 ; 427418413,988585 ] >									
	//        < 0x00000000000000000000000000000000000000000000009A8608BE29F39CBFEA >									
	//     < RE_Portfolio_XVI_metadata_line_13_____QBE_Insurance_Group_Limited_20250515 >									
	//        < HXTxOFOui5vWqwP93udKcXmfyAspps9amB3qNH05ANVnt767nZPBGzG14U1ggCc7 >									
	//        < 1E-018 limites [ 427418413,988585 ; 448896235,243965 ] >									
	//        < 0x00000000000000000000000000000000000000000000009F39CBFEAA73A14DD8 >									
	//     < RE_Portfolio_XVI_metadata_line_14_____QBE_Insurance_Group_Limited_20250515 >									
	//        < nX8U913JAMD57zhg7bc7k6KYj0yEQf53w8wRMc4vAZA7tcdQ87bw6IeQ8Z3xDypc >									
	//        < 1E-018 limites [ 448896235,243965 ; 515995848,11175 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A73A14DD8C0393301F >									
	//     < RE_Portfolio_XVI_metadata_line_15_____QBE_Re__Europe__Limited_Ap_A_20250515 >									
	//        < km5jkPGAUCuH1yAcfiwR81Q2iQ5O87eevr7vHChX3561r7Kta8VYv91Gf9kQu8LS >									
	//        < 1E-018 limites [ 515995848,11175 ; 549754145,161276 ] >									
	//        < 0x0000000000000000000000000000000000000000000000C0393301FCCCCA42E8 >									
	//     < RE_Portfolio_XVI_metadata_line_16_____QBE_Underwriting_Limited_20250515 >									
	//        < bDH3xZ3Bs15HA73h7cq393q5XwwOZltm6bO76diM6iyX6uNsL41r7o0TVOl5yX5E >									
	//        < 1E-018 limites [ 549754145,161276 ; 607961740,947483 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CCCCA42E8E27BC0102 >									
	//     < RE_Portfolio_XVI_metadata_line_17_____QBE_Underwriting_Limited_20250515 >									
	//        < bzBAPX4nNEMo354TP2D81c6eVFzn78E902t29w555S51t3EaVBNnvVPrM5dNlWjv >									
	//        < 1E-018 limites [ 607961740,947483 ; 675220039,982088 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E27BC0102FB8A00612 >									
	//     < RE_Portfolio_XVI_metadata_line_18_____QBE_Underwriting_Limited_20250515 >									
	//        < 0JqwcwTwVe6Wv0K0KFRTbYBHwtBQ9NXiIfGP3gqc683uwxrUgC3v33FrxYvJF56i >									
	//        < 1E-018 limites [ 675220039,982088 ; 714932159,768788 ] >									
	//        < 0x000000000000000000000000000000000000000000000FB8A0061210A553E8DC >									
	//     < RE_Portfolio_XVI_metadata_line_19_____QBE_Underwriting_Limited_20250515 >									
	//        < EgI5eayP1L39Xgpsd7qVOCLKTG2CM80gS5FvhMJ914DW077RAmfl9D825hCZip3l >									
	//        < 1E-018 limites [ 714932159,768788 ; 763820373,710236 ] >									
	//        < 0x0000000000000000000000000000000000000000000010A553E8DC11C8B9676F >									
	//     < RE_Portfolio_XVI_metadata_line_20_____QBE_Underwriting_Limited_20250515 >									
	//        < 964za98ZC5a3oMRizLkENph27Qw98WF6OdR44EzBN0AsscYCvuSo6pMF8KmpOih7 >									
	//        < 1E-018 limites [ 763820373,710236 ; 796123601,236996 ] >									
	//        < 0x0000000000000000000000000000000000000000000011C8B9676F12894437AF >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XVI_metadata_line_21_____QBE_Underwriting_Limited_20250515 >									
	//        < 7atz2Hwm3437gXZ1413kQW21A5db2K593IiIzH7wR2F9i0fuXbCn1b151Zx4R691 >									
	//        < 1E-018 limites [ 796123601,236996 ; 840719500,617993 ] >									
	//        < 0x0000000000000000000000000000000000000000000012894437AF13931428E1 >									
	//     < RE_Portfolio_XVI_metadata_line_22_____QBE_Underwriting_Limited_20250515 >									
	//        < Q7n9RM15dOMlX5BTq4vG55XeX54f6Z26ky21YsUxm34rbnc12h2M7kqRzCfFr6R1 >									
	//        < 1E-018 limites [ 840719500,617993 ; 855758886,63015 ] >									
	//        < 0x0000000000000000000000000000000000000000000013931428E113ECB8710B >									
	//     < RE_Portfolio_XVI_metadata_line_23_____QBE_Underwriting_Limited_20250515 >									
	//        < CPg5DZ6eZvU7bDY86mP0p0m6UF01H5jW1Wo9GG15cHJoYRuJn73m4dRMxM7W2U7R >									
	//        < 1E-018 limites [ 855758886,63015 ; 875002577,280056 ] >									
	//        < 0x0000000000000000000000000000000000000000000013ECB8710B145F6BFBB4 >									
	//     < RE_Portfolio_XVI_metadata_line_24_____R_J_Kiln_and_Co_Limited_20250515 >									
	//        < OB8G5l3eY10mJp85G4i9ozEc4TfPymDt2Y30ILy3fR48s34zxpLnv8I45g5fVd76 >									
	//        < 1E-018 limites [ 875002577,280056 ; 890839652,912361 ] >									
	//        < 0x00000000000000000000000000000000000000000000145F6BFBB414BDD1715F >									
	//     < RE_Portfolio_XVI_metadata_line_25_____R_J_Kiln_and_Co_Limited_20250515 >									
	//        < SfEj85wBHRC4DBHwRb2Ha1IM540k3xNQ6YQF7210tQ7w2LPK2aKbZiG89Uq0A2e8 >									
	//        < 1E-018 limites [ 890839652,912361 ; 906489267,563774 ] >									
	//        < 0x0000000000000000000000000000000000000000000014BDD1715F151B18DC18 >									
	//     < RE_Portfolio_XVI_metadata_line_26_____R_J_Kiln_and_Co_Limited_20250515 >									
	//        < RMG9sQwufaRhYoTSODbr0lmmbe5W1lCmoxVfqg08O3AIM5yvdqb3jTp5aeWu2O2Z >									
	//        < 1E-018 limites [ 906489267,563774 ; 960590931,886529 ] >									
	//        < 0x00000000000000000000000000000000000000000000151B18DC18165D9172B8 >									
	//     < RE_Portfolio_XVI_metadata_line_27_____R_J_Kiln_and_Co_Limited&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;_20250515 >									
	//        < I59st9WAk84j82W5A7WTV176r8HPX9285zk04Y7815JR07ciU0e29eI6m2Gsh427 >									
	//        < 1E-018 limites [ 960590931,886529 ; 1041700687,55752 ] >									
	//        < 0x00000000000000000000000000000000000000000000165D9172B81841051D07 >									
	//     < RE_Portfolio_XVI_metadata_line_28_____R_p_V_Versicherung_AG_AAm_m_20250515 >									
	//        < 8p023EZh4q92maVlW7j2AraOTdFVvo1tQuLxPs155vxouDpeaML7yfASC6Qw4qnk >									
	//        < 1E-018 limites [ 1041700687,55752 ; 1077004986,2118 ] >									
	//        < 0x000000000000000000000000000000000000000000001841051D0719137332B1 >									
	//     < RE_Portfolio_XVI_metadata_line_29_____RandQ_Managing_Agency_Limited_20250515 >									
	//        < F5o4UEt490Jp44loI6W058y7EZEg5ONHCI2Uc8h96tDs1ofNB4HCl521fzB1S63e >									
	//        < 1E-018 limites [ 1077004986,2118 ; 1090803126,34613 ] >									
	//        < 0x0000000000000000000000000000000000000000000019137332B11965B17D2E >									
	//     < RE_Portfolio_XVI_metadata_line_30_____RandQ_Managing_Agency_Limited_20250515 >									
	//        < bncLhihB8M2x2NS9wc9Sn86flL5qY1V6m6lMwG8101IY7FCROWO3Hda5dwr3BQBi >									
	//        < 1E-018 limites [ 1090803126,34613 ; 1108634722,3514 ] >									
	//        < 0x000000000000000000000000000000000000000000001965B17D2E19CFFA585F >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_XVI_metadata_line_31_____RandQ_Managing_Agency_Limited_20250515 >									
	//        < iPr15LjOImu3Gu33H7D9JJEpz9E0GedI1qCe8ufjKUqv2gw3BT5L42o9lBFWpXuO >									
	//        < 1E-018 limites [ 1108634722,3514 ; 1175243299,9734 ] >									
	//        < 0x0000000000000000000000000000000000000000000019CFFA585F1B5CFEF801 >									
	//     < RE_Portfolio_XVI_metadata_line_32_____RandQ_Managing_Agency_Limited_ex_Cavell_Managing_Agency_Limited_20250515 >									
	//        < NN4c8C9Od62aI4bDi9oUH0OE9Be9U04wwcUXnN66z4hnRMG4nlN2ARMhQNUy1SM4 >									
	//        < 1E-018 limites [ 1175243299,9734 ; 1205830031,2785 ] >									
	//        < 0x000000000000000000000000000000000000000000001B5CFEF8011C134E9DEB >									
	//     < RE_Portfolio_XVI_metadata_line_33_____RBC_Insurance_20250515 >									
	//        < DH0Db3SB1T8P98Xm0wYL4XoNx4Hz23DI5gBH68ya9o4R0WLY2dGLuku2N4odAo0Q >									
	//        < 1E-018 limites [ 1205830031,2785 ; 1225866086,69567 ] >									
	//        < 0x000000000000000000000000000000000000000000001C134E9DEB1C8ABB3611 >									
	//     < RE_Portfolio_XVI_metadata_line_34_____Reinsurance_Association_of_America_20250515 >									
	//        < yZASI86g7jJEs7ads9roKb0H1fA57g3Ae8dXK3052cay6G9mll7w5POoOrQQ0R42 >									
	//        < 1E-018 limites [ 1225866086,69567 ; 1278050752,98377 ] >									
	//        < 0x000000000000000000000000000000000000000000001C8ABB36111DC1C6B156 >									
	//     < RE_Portfolio_XVI_metadata_line_35_____Reinsurance_Australia_Corporation_20250515 >									
	//        < vswj03v6b7ggoAs2qpb93v2GI8GZkzv065257fiRQwHhCUD30fIT7c48g59jqjTV >									
	//        < 1E-018 limites [ 1278050752,98377 ; 1301097996,47127 ] >									
	//        < 0x000000000000000000000000000000000000000000001DC1C6B1561E4B25FED3 >									
	//     < RE_Portfolio_XVI_metadata_line_36_____Reinsurance_Directions_Consulting_20250515 >									
	//        < N006AGE4O3ZZ7l21YhvX9qY4nhloM7iO966Q5YB6MdjHp9Sf1z19632L2D1m26Jj >									
	//        < 1E-018 limites [ 1301097996,47127 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001E4B25FED31F29E0C9E1 >									
	//     < RE_Portfolio_XVI_metadata_line_37_____Reinsurance_Group_of_America_20250515 >									
	//        < QTlt6JLCHV95l8p3I253qEYtm4h32vEopdyO18QDy5FTc7Yu47k2o0R88lNrJ353 >									
	//        < 1E-018 limites [ 1338465832,77278 ; 1379691558,86544 ] >									
	//        < 0x000000000000000000000000000000000000000000001F29E0C9E1201F9A4122 >									
	//     < RE_Portfolio_XVI_metadata_line_38_____Reinsurance_Group_of_America_Incorporated_20250515 >									
	//        < YP1sMV208CC4u6UaEirvdMYFmKdf6flQ00S16dsx9JhX7siBjsWOJi12l69uOOc0 >									
	//        < 1E-018 limites [ 1379691558,86544 ; 1396672068,80612 ] >									
	//        < 0x00000000000000000000000000000000000000000000201F9A41222084D074D4 >									
	//     < RE_Portfolio_XVI_metadata_line_39_____Reinsurance_Magazine_Online_20250515 >									
	//        < DCa8xqCEl8096z6KVqA2s7A02SC836Gh600DyQ9DR95qWWtDCF0P8Jlf436S8989 >									
	//        < 1E-018 limites [ 1396672068,80612 ; 1471747029,05055 ] >									
	//        < 0x000000000000000000000000000000000000000000002084D074D422444BC12D >									
	//     < RE_Portfolio_XVI_metadata_line_40_____Reinsurance_News_Network_20250515 >									
	//        < K1G2Cwn6ILEC13bdp8630i95KaZk5bSrXlYjg9zrCBYOT5hjKGiyR4TvTpJIFkSY >									
	//        < 1E-018 limites [ 1471747029,05055 ; 1518764476,48852 ] >									
	//        < 0x0000000000000000000000000000000000000000000022444BC12D235C8AAF94 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}