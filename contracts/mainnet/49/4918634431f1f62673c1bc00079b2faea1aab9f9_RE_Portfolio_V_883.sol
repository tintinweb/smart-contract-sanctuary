pragma solidity 		^0.4.21	;						
										
	contract	RE_Portfolio_V_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	RE_Portfolio_V_883		"	;
		string	public		symbol =	"	RE883V		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		1438753004438170000000000000					;	
										
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
	//     < RE_Portfolio_V_metadata_line_1_____Asta_Managing_Agency_Limited_20250515 >									
	//        < WP4JqCa29fLy9G8T2bN9Lf77jXpG978g1h7Y930GCs7DsRTNsOBQuj35gqAOzV9E >									
	//        < 1E-018 limites [ 1E-018 ; 18469005,8688919 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000000006E15795E >									
	//     < RE_Portfolio_V_metadata_line_2_____Asta_Managing_Agency_Limited_20250515 >									
	//        < Jd5MBwk29Y97136p864xEf42rRc5n9hK7CL5p71BhXEJR82GW2VmEbv938Z80ftS >									
	//        < 1E-018 limites [ 18469005,8688919 ; 98537245,7608129 ] >									
	//        < 0x000000000000000000000000000000000000000000000006E15795E24B53E994 >									
	//     < RE_Portfolio_V_metadata_line_3_____Asta_Managing_Agency_Limited_20250515 >									
	//        < Q87uMQ7YWUCx1GCMs6p38u7tkv5KR9Azz81A16A178OYT15SaR73thHY89T5dB1D >									
	//        < 1E-018 limites [ 98537245,7608129 ; 132591827,66541 ] >									
	//        < 0x000000000000000000000000000000000000000000000024B53E9943164F14A2 >									
	//     < RE_Portfolio_V_metadata_line_4_____Asta_Managing_Agency_Limited_20250515 >									
	//        < ID37fMPIys9lj1R59UBg77gwJjR96XSud8Ids1h7659PXG9b31EpfzPiXbjyixqg >									
	//        < 1E-018 limites [ 132591827,66541 ; 156430209,772614 ] >									
	//        < 0x00000000000000000000000000000000000000000000003164F14A23A46590A5 >									
	//     < RE_Portfolio_V_metadata_line_5_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 5N6o6G0k2cmANWKpg85105N084B4uzd9H9Yx194DupvlUGn00uJGKwx86Z9V0kzW >									
	//        < 1E-018 limites [ 156430209,772614 ; 202545345,493554 ] >									
	//        < 0x00000000000000000000000000000000000000000000003A46590A54B743AD89 >									
	//     < RE_Portfolio_V_metadata_line_6_____Asta_Managing_Agency_Limited_20250515 >									
	//        < wCvk39Bb5XFVCwdESZm9CJ87YjSPbrlHC26Q657bpM5LyiY0Hni3J6i337sjDQK5 >									
	//        < 1E-018 limites [ 202545345,493554 ; 219179688,780864 ] >									
	//        < 0x00000000000000000000000000000000000000000000004B743AD8951A69ABE2 >									
	//     < RE_Portfolio_V_metadata_line_7_____Asta_Managing_Agency_Limited_20250515 >									
	//        < bZebU6K7XNlzmDK59IcwUwmloW09Xse2GIN5OTPmT41ES3RHyN43zw3ACzaMsimk >									
	//        < 1E-018 limites [ 219179688,780864 ; 260636152,826453 ] >									
	//        < 0x000000000000000000000000000000000000000000000051A69ABE2611833726 >									
	//     < RE_Portfolio_V_metadata_line_8_____Asta_Managing_Agency_Limited_20250515 >									
	//        < F8LwO4h78saV8PGG2Qa1QKHMxNRaWUdfWO5jK4un8xS378VM5jx76WsQmB220V4t >									
	//        < 1E-018 limites [ 260636152,826453 ; 275150257,949163 ] >									
	//        < 0x000000000000000000000000000000000000000000000061183372666805FB76 >									
	//     < RE_Portfolio_V_metadata_line_9_____Asta_Managing_Agency_Limited_20250515 >									
	//        < LN2l9jh3RmsG5ME3ezJ7K7vGOZREck1C758Lmu25CTNjss686rIVyVP5tl1xhMPj >									
	//        < 1E-018 limites [ 275150257,949163 ; 286015822,041262 ] >									
	//        < 0x000000000000000000000000000000000000000000000066805FB766A8C98470 >									
	//     < RE_Portfolio_V_metadata_line_10_____Asta_Managing_Agency_Limited_20250515 >									
	//        < 76U3oaS270j936Ss61AfVwYUPKj59b75zdsMUYgrjAzRGy41VBvhn0XQ72N59J8d >									
	//        < 1E-018 limites [ 286015822,041262 ; 307343770,416015 ] >									
	//        < 0x00000000000000000000000000000000000000000000006A8C98470727E96245 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_V_metadata_line_11_____Atradius_ReinsLimited_A_20250515 >									
	//        < Uve10lUiBCZMml39ZRQ7UphDQ5keCIXBf9bd65tFlbtKFDS4CfII93FsBZXrgWT8 >									
	//        < 1E-018 limites [ 307343770,416015 ; 325080364,120425 ] >									
	//        < 0x0000000000000000000000000000000000000000000000727E96245791A14730 >									
	//     < RE_Portfolio_V_metadata_line_12_____Atrium_Underwriters_Limited_20250515 >									
	//        < 17CpC1mGLLl6X1n8VvNPxIQwZCKM5iu7jL2pd1fh6bXBrOiRG9oEb0gxE11Dwc0O >									
	//        < 1E-018 limites [ 325080364,120425 ; 361572162,824439 ] >									
	//        < 0x0000000000000000000000000000000000000000000000791A1473086B23580E >									
	//     < RE_Portfolio_V_metadata_line_13_____Atrium_Underwriters_Limited_20250515 >									
	//        < 7alSbD975ydyTph2a362o3029OFEDn3D0tr4WuCqxMh0a85Vz5gc9gd5MshffAgG >									
	//        < 1E-018 limites [ 361572162,824439 ; 415192252,059023 ] >									
	//        < 0x000000000000000000000000000000000000000000000086B23580E9AABD1B69 >									
	//     < RE_Portfolio_V_metadata_line_14_____Atrium_Underwriters_Limited_20250515 >									
	//        < NPqBhcq7t4m67aI5246M54Uy1VFtpG1N8y1ggv4fmx60Q0UuR2tk9vj47cMkwr37 >									
	//        < 1E-018 limites [ 415192252,059023 ; 445973126,511267 ] >									
	//        < 0x00000000000000000000000000000000000000000000009AABD1B69A6234FE7F >									
	//     < RE_Portfolio_V_metadata_line_15_____Atrium_Underwriters_Limited_20250515 >									
	//        < 8Pc7axGoi3te0uRB5Jrn5KgSd4N7BVFKTB199vUfIc58Nea4w0EJYhD8Jl58iz5i >									
	//        < 1E-018 limites [ 445973126,511267 ; 503241109,214056 ] >									
	//        < 0x0000000000000000000000000000000000000000000000A6234FE7FBB78D003D >									
	//     < RE_Portfolio_V_metadata_line_16_____Australia_AAA_QBE_Insurance__International__Limited_Ap_A_20250515 >									
	//        < T1Hy0TabPD7d519ngJZN0Z7G27sR6B37nW6pb8Ark53pd55YNdijmQEbR4BX49OD >									
	//        < 1E-018 limites [ 503241109,214056 ; 551457233,853145 ] >									
	//        < 0x0000000000000000000000000000000000000000000000BB78D003DCD6F0F7ED >									
	//     < RE_Portfolio_V_metadata_line_17_____Australia_AAA_QBE_Insurance__International__Limited_Ap_A_20250515 >									
	//        < 3L657Ky7e6kFm9Xy4pd540ajSePWsPSq8m9Tck9Kus56cj7DT2qP2w44GxhQTiNT >									
	//        < 1E-018 limites [ 551457233,853145 ; 569681071,392991 ] >									
	//        < 0x0000000000000000000000000000000000000000000000CD6F0F7EDD43905677 >									
	//     < RE_Portfolio_V_metadata_line_18_____Aviva_Insurance_Limited_Ap_A_20250515 >									
	//        < UKIKqlSf7GgT1b5d6D0JdJ1L4YQs7tqB1sd57Bbil5R9E6EFdF81qHU15oECha37 >									
	//        < 1E-018 limites [ 569681071,392991 ; 607680471,231113 ] >									
	//        < 0x0000000000000000000000000000000000000000000000D43905677E260ED207 >									
	//     < RE_Portfolio_V_metadata_line_19_____Aviva_Re_Limited_Ap_m_20250515 >									
	//        < Z0LSj2vtCAQz2C0902CQ1MvDDa4fWL1n69wux1F2243YvLU5XD24P7E6G9q0mV96 >									
	//        < 1E-018 limites [ 607680471,231113 ; 655868639,043572 ] >									
	//        < 0x0000000000000000000000000000000000000000000000E260ED207F45482114 >									
	//     < RE_Portfolio_V_metadata_line_20_____AWP_Health_&_Life_SA_Ap_20250515 >									
	//        < n2P6YegPl43V9d4S85ybQ88DPoEZximtoNmQwToX1qq4kv3191l93JSp9OP1Rd7m >									
	//        < 1E-018 limites [ 655868639,043572 ; 734988668,91077 ] >									
	//        < 0x000000000000000000000000000000000000000000000F45482114111CDFB6BF >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_V_metadata_line_21_____AXA_Corporate_Solutions_Assurance_AAm_20250515 >									
	//        < 7TlSQ1ulkQ7x5Ge9QG6V1XKxOF5LxPAww5N83iKL8IH2SEoUG6V57gjYw1u2Dfai >									
	//        < 1E-018 limites [ 734988668,91077 ; 752087800,446 ] >									
	//        < 0x00000000000000000000000000000000000000000000111CDFB6BF1182CAEB00 >									
	//     < RE_Portfolio_V_metadata_line_22_____AXA_Corporate_Solutions_Assurance_AAm_m_20250515 >									
	//        < 3bBRZsMPY88eBP795f9mk2kn6X6wGAdUxH0NLs8mMrzR8O7j85F83TpP5K2AXa71 >									
	//        < 1E-018 limites [ 752087800,446 ; 824467231,792289 ] >									
	//        < 0x000000000000000000000000000000000000000000001182CAEB001332352A5F >									
	//     < RE_Portfolio_V_metadata_line_23_____AXA_France_IARD_AAm_m_20250515 >									
	//        < beAlDu8tUh6o6QU97iz5RC407kBWQi7L435Q968oGi2hp4h7u4JWShi70H2wl1i3 >									
	//        < 1E-018 limites [ 824467231,792289 ; 888860762,047968 ] >									
	//        < 0x000000000000000000000000000000000000000000001332352A5F14B205E520 >									
	//     < RE_Portfolio_V_metadata_line_24_____AXA_France_Vie_AAm_20250515 >									
	//        < 8LgL7XRURFWC78TXpbnZw7P4NmV3qwM1RkNT2Z7J33Y6Om6Hj0jVvo13Nla6n8Sq >									
	//        < 1E-018 limites [ 888860762,047968 ; 952890111,711953 ] >									
	//        < 0x0000000000000000000000000000000000000000000014B205E520162FAAEDD7 >									
	//     < RE_Portfolio_V_metadata_line_25_____AXA_Global_P&C_A_Ap_20250515 >									
	//        < HvaqAhzVlkQ11kpkqpdy2qp60X1FDDGsjHf40fZ74v1H5Bjs1ycbQ7p6NQcvBwvO >									
	//        < 1E-018 limites [ 952890111,711953 ; 973331769,147193 ] >									
	//        < 0x00000000000000000000000000000000000000000000162FAAEDD716A9826C46 >									
	//     < RE_Portfolio_V_metadata_line_26_____AXA_Reassurance_20250515 >									
	//        < zS844I4KKb7ElSp2763ayRwe4mj7eu2U36W8238qR72Paa57AmBdQ7Fgi4JE4uJs >									
	//        < 1E-018 limites [ 973331769,147193 ; 991932373,293938 ] >									
	//        < 0x0000000000000000000000000000000000000000000016A9826C46171860B145 >									
	//     < RE_Portfolio_V_metadata_line_27_____AXA_Reassurance_20250515 >									
	//        < 2Yu6SN9QDhgS805K7tYln92862flO43095SiredjuJJAKUAntV0pjohxM5w3M0M6 >									
	//        < 1E-018 limites [ 991932373,293938 ; 1020948753,88637 ] >									
	//        < 0x00000000000000000000000000000000000000000000171860B14517C5542CF0 >									
	//     < RE_Portfolio_V_metadata_line_28_____AXAmPPP_HEALTHCARE_LIMITED_AAm_m_20250515 >									
	//        < F10g08XO7W2W36TOZPjjotz25CK6fvqzZQ9pYgwOe1A0rmjw8Q5NB4b38aJ35b0k >									
	//        < 1E-018 limites [ 1020948753,88637 ; 1038742948,79752 ] >									
	//        < 0x0000000000000000000000000000000000000000000017C5542CF0182F63F653 >									
	//     < RE_Portfolio_V_metadata_line_29_____Axis_Capital_20250515 >									
	//        < DdobipY6P391GUtI0q7KO116Bwsyr110DCdP9Xj3Cy72W70keH4U0TsZ070dh785 >									
	//        < 1E-018 limites [ 1038742948,79752 ; 1057547175,56601 ] >									
	//        < 0x00000000000000000000000000000000000000000000182F63F653189F78EF68 >									
	//     < RE_Portfolio_V_metadata_line_30_____Axis_Capital_20250515 >									
	//        < n99X173H9vkCvi3Vv4jr7p46Ly721ySXZJR3tC56ICMG3H627Km1ueUYk2WIZO1L >									
	//        < 1E-018 limites [ 1057547175,56601 ; 1108289461,6947 ] >									
	//        < 0x00000000000000000000000000000000000000000000189F78EF6819CDEB84ED >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < RE_Portfolio_V_metadata_line_31_____Axis_Capital_Holdings_Limited_20250515 >									
	//        < 754M3359NcyCU50W7Sl88kM5NMn9HM75fz5oyZ1JchPYOB3zVR0941nLp9l288NQ >									
	//        < 1E-018 limites [ 1108289461,6947 ; 1151435005,60256 ] >									
	//        < 0x0000000000000000000000000000000000000000000019CDEB84ED1ACF166504 >									
	//     < RE_Portfolio_V_metadata_line_32_____Axis_Management_Group_20250515 >									
	//        < 8F2Ir93d0PVWzc0FNALD0ShZW1Dj5U6R45Ra6XhoK5bTTs3aj1795Sh3h04q9wYP >									
	//        < 1E-018 limites [ 1151435005,60256 ; 1178154672,23737 ] >									
	//        < 0x000000000000000000000000000000000000000000001ACF1665041B6E595ECB >									
	//     < RE_Portfolio_V_metadata_line_33_____Axis_Management_Group_20250515 >									
	//        < 8DB1596KpMZl3zY3pPe3x1yxiZARc93X0X5jbJz188rxg6lL0a4A3ojF2qt5Yr58 >									
	//        < 1E-018 limites [ 1178154672,23737 ; 1213908739,07236 ] >									
	//        < 0x000000000000000000000000000000000000000000001B6E595ECB1C4375BF27 >									
	//     < RE_Portfolio_V_metadata_line_34_____Axis_Managing_Agency_Limited_20250515 >									
	//        < psh5aa6N8Cl7BNp6t676fCc5hLNp9v6Rn29fpoa77PsGxKvAg43YCUFTnJt7AM9y >									
	//        < 1E-018 limites [ 1213908739,07236 ; 1225059997,9036 ] >									
	//        < 0x000000000000000000000000000000000000000000001C4375BF271C85ED37A2 >									
	//     < RE_Portfolio_V_metadata_line_35_____Axis_Managing_Agency_Limited_20250515 >									
	//        < jcefa1we6dU2BmcPDUpE15285n4QaN2rx2p7Txj16l34JEmHx0uKpSE9FgzPV7EV >									
	//        < 1E-018 limites [ 1225059997,9036 ; 1262133215,03445 ] >									
	//        < 0x000000000000000000000000000000000000000000001C85ED37A21D62E67513 >									
	//     < RE_Portfolio_V_metadata_line_36_____Axis_Managing_Agency_Limited_20250515 >									
	//        < PWIXLE9z0o8M3lEyp86Aj5H309rwl5GP46ZqbdM24zh9GBEQAH6hd8937x8nWq9A >									
	//        < 1E-018 limites [ 1262133215,03445 ;  ] >									
	//        < 0x000000000000000000000000000000000000000000001D62E675131EDAF64895 >									
	//     < RE_Portfolio_V_metadata_line_37_____Axis_Managing_Agency_Limited_20250515 >									
	//        < XY5zH3bQ5I9QJOch8zETUp4812PJa21ym0u7l42fI2kExZ5859pg64cuWO55CJXx >									
	//        < 1E-018 limites [ 1325225919,05019 ; 1339253251,61118 ] >									
	//        < 0x000000000000000000000000000000000000000000001EDAF648951F2E924B5D >									
	//     < RE_Portfolio_V_metadata_line_38_____Axis_Managing_Agency_Limited_20250515 >									
	//        < 3tMxMx0ptz73A6al9S3EawHF187E5u832l49lA812uvYlplKL9ySS4W84T3Glq5N >									
	//        < 1E-018 limites [ 1339253251,61118 ; 1385190157,24825 ] >									
	//        < 0x000000000000000000000000000000000000000000001F2E924B5D2040607320 >									
	//     < RE_Portfolio_V_metadata_line_39_____Axis_Managing_Agency_Limited_20250515 >									
	//        < Ask6YMag5gS7DD8RsqC3eKZI35ku0m1X607PjL922PYyd2Q6Ude0CV7yEDzaXQz7 >									
	//        < 1E-018 limites [ 1385190157,24825 ; 1405087030,92401 ] >									
	//        < 0x00000000000000000000000000000000000000000000204060732020B6F8AB68 >									
	//     < RE_Portfolio_V_metadata_line_40_____Axis_Managing_Agency_Limited_20250515 >									
	//        < 0G24P2t9By89Oz3h3X893rX2b69EFQLp8Scx4Vz2DCzOZ7MolstyCpq1ksmIo4N3 >									
	//        < 1E-018 limites [ 1405087030,92401 ; 1438753004,43817 ] >									
	//        < 0x0000000000000000000000000000000000000000000020B6F8AB68217FA2DE4F >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}