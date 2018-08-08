pragma solidity 		^0.4.21	;						
										
	contract	DUBAI_Portfolio_II_883				{				
										
		mapping (address => uint256) public balanceOf;								
										
		string	public		name =	"	DUBAI_Portfolio_II_883		"	;
		string	public		symbol =	"	DUBAI883II		"	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		747599432793525000000000000					;	
										
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
	//     < DUBAI_Portfolio_II_metadata_line_1_____Agility_Public_Warehousing_Company_KSC_20250515 >									
	//        < FtsPpN1DwzTzWX6jdVT5rKcXhr5t3bs074M1O08Kaw26qrnmIkBPlE9Q4xY7AXt3 >									
	//        <  u =="0.000000000000000001" : ] 000000000000000.000000000000000000 ; 000000019145135.531349000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000000000001D3692 >									
	//     < DUBAI_Portfolio_II_metadata_line_2_____Air_Arabia_20250515 >									
	//        < I19Ah2z3zex7CQ01Vm9QRjN1npMyHj4A6pj5J2as1qM7CuWp8iknM7Fexh0Pl8E4 >									
	//        <  u =="0.000000000000000001" : ] 000000019145135.531349000000000000 ; 000000040724763.106576000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000001D36923E241C >									
	//     < DUBAI_Portfolio_II_metadata_line_3_____ARAMEX_20250515 >									
	//        < U2D06H7k9dA7485J46HU81rtmueV0iJWW5uSJ3h6G7uVETD2nCP4v4P3HuKAJH06 >									
	//        <  u =="0.000000000000000001" : ] 000000040724763.106576000000000000 ; 000000056380860.880529300000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000003E241C5607C6 >									
	//     < DUBAI_Portfolio_II_metadata_line_4_____Gulf_Navigation_Holding_20250515 >									
	//        < lO17Pwvt3bgEbWRbNIUCUw0va5H15O5bXI4whk85T16i2k9TanP55aL2O4mO2U1I >									
	//        <  u =="0.000000000000000001" : ] 000000056380860.880529300000000000 ; 000000076374791.225424100000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000005607C67489E7 >									
	//     < DUBAI_Portfolio_II_metadata_line_5_____National_Cement_Company_20250515 >									
	//        < WI9P5oFf0T1rTgVZniWEU47KvKd7OhB5788L4lGOOsML2ZDR10mtj514Rc2U9S2v >									
	//        <  u =="0.000000000000000001" : ] 000000076374791.225424100000000000 ; 000000096299561.904439500000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000007489E792F104 >									
	//     < DUBAI_Portfolio_II_metadata_line_6_____National_Industries_Group_Holding_SAK_20250515 >									
	//        < YcBnj20m8674wfi6Wk6x2SxOF63QU2G99p3r7qMHGFBaJpPLCowM9IKmS0jn14N7 >									
	//        <  u =="0.000000000000000001" : ] 000000096299561.904439500000000000 ; 000000113032053.304132000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000092F104AC7925 >									
	//     < DUBAI_Portfolio_II_metadata_line_7_____Dubai_Refreshments_Company_20250515 >									
	//        < lYy8rduj7at3nzw65HRosBbrHIF1pbTQWzzBKa0tLs8yTz6O490ri9rW9R1ZR1Fq >									
	//        <  u =="0.000000000000000001" : ] 000000113032053.304132000000000000 ; 000000133572118.908301000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000AC7925CBD09C >									
	//     < DUBAI_Portfolio_II_metadata_line_8_____Emirates_Refreshments_Company_20250515 >									
	//        < 8Jcp52QycTf9MZ42lEYevTR6NsBEUux50jdtJ7fryLP6pL0Jh0bP9qKE5ds3Ms6O >									
	//        <  u =="0.000000000000000001" : ] 000000133572118.908301000000000000 ; 000000150667214.297915000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000000CBD09CE5E661 >									
	//     < DUBAI_Portfolio_II_metadata_line_9_____Gulfa_Mineral_Water_Processing_Industries_20250515 >									
	//        < vx4Y811TAZv8I8A2B83BPdGeN8RBcEH9R80TUXkmrBP8TGI4H70tkwYD44FsHF1p >									
	//        <  u =="0.000000000000000001" : ] 000000150667214.297915000000000000 ; 000000171117833.275274000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000000E5E6611051AE7 >									
	//     < DUBAI_Portfolio_II_metadata_line_10_____MARKA_20250515 >									
	//        < YT5tum3HkX8Kccv3i3R6GQFv2TRLgKXyLHgvCvt6IuWeXk8c1u84vXu8lRDFD3Nt >									
	//        <  u =="0.000000000000000001" : ] 000000171117833.275274000000000000 ; 000000191766384.378673000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001051AE71249CBE >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < DUBAI_Portfolio_II_metadata_line_11_____United_Foods_Company_20250515 >									
	//        < L8g74b2643T4xxyBrVP0T2bG1g44NtxY5Cr15c1Crnb7wPn8ufYq158Z383xDU9F >									
	//        <  u =="0.000000000000000001" : ] 000000191766384.378673000000000000 ; 000000207291319.040710000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001249CBE13C4D2C >									
	//     < DUBAI_Portfolio_II_metadata_line_12_____UNITED_KAIPARA_DAIRIES_CO_20250515 >									
	//        < L92H1Y6ZjeQQ8z7yi3uj9u9M7wEJs2Dt97nx2u570Vl45vpZ858uM0UQ57sHZ25f >									
	//        <  u =="0.000000000000000001" : ] 000000207291319.040710000000000000 ; 000000227898244.886770000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000013C4D2C15BBEC0 >									
	//     < DUBAI_Portfolio_II_metadata_line_13_____Emirate_Integrated_Telecommunications_Company_20250515 >									
	//        < 1T21q3dH170eJXIP4eCp5R38y2QkT688scs5F38lT7O5X2ks5q8iLOfAPT5YPqDj >									
	//        <  u =="0.000000000000000001" : ] 000000227898244.886770000000000000 ; 000000247483557.174604000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000015BBEC0179A144 >									
	//     < DUBAI_Portfolio_II_metadata_line_14_____Hits_Telecom_Holding__20250515 >									
	//        < Eqk4m96xZ5zBCldunilh9N9x98iex6Q48uJkzUYtA95a16W7R10nkMZ3g72Q8U0X >									
	//        <  u =="0.000000000000000001" : ] 000000247483557.174604000000000000 ; 000000264803026.135155000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000179A1441940EAF >									
	//     < DUBAI_Portfolio_II_metadata_line_15_____Al_Firdous_Holdings_20250515 >									
	//        < J35Y1EJzaUGXK032IRhaWbw92k9j02pD3s9dAP2M103YvNmSoX88554kHyOE2vOw >									
	//        <  u =="0.000000000000000001" : ] 000000264803026.135155000000000000 ; 000000282443783.191644000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001940EAF1AEF99A >									
	//     < DUBAI_Portfolio_II_metadata_line_16_____National_Central_Cooling_Co_20250515 >									
	//        < 6u00YhEOpbyW99v07L43dc77M3E3fceQyNPM186H7D8wG30Fc0J7Ujbtd0WZt73n >									
	//        <  u =="0.000000000000000001" : ] 000000282443783.191644000000000000 ; 000000299959351.106340000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001AEF99A1C9B39F >									
	//     < DUBAI_Portfolio_II_metadata_line_17_____AJMAN_BANK_PJSC_obs_20250515 >									
	//        < Stx2017Oy0UT5T4Gd9655L0Zh8757aYhvsRcQ6YQr9D2Ube9umSwa3azR66jn670 >									
	//        <  u =="0.000000000000000001" : ] 000000299959351.106340000000000000 ; 000000320671487.173123000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001C9B39F1E94E4D >									
	//     < DUBAI_Portfolio_II_metadata_line_18_____Amlak_Finance_PJSC_obs_20250515 >									
	//        < TXIdtqNeEs0yq52D4s10z5D2zKhbjtEmm2B2p4574RK21WMeLm3Z0Y43tHWLyBd4 >									
	//        <  u =="0.000000000000000001" : ] 000000320671487.173123000000000000 ; 000000342520645.295861000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000001E94E4D20AA521 >									
	//     < DUBAI_Portfolio_II_metadata_line_19_____Commercial_Bank_of_Dubai_PSC_obs_20250515 >									
	//        < 9gE0A0XwGr3I513nt0nq777qcoQ6S2SphF91G7H035eH68dTo2FEOWWZdzOUga1m >									
	//        <  u =="0.000000000000000001" : ] 000000342520645.295861000000000000 ; 000000362082770.472910000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000020AA5212287E95 >									
	//     < DUBAI_Portfolio_II_metadata_line_20_____Dubai_Islamic_Bank_obs_20250515 >									
	//        < 7k4K18oEOz56VHl85pv1e3Ujz30tgbibl3KtxTRg2Al2D1957sAU9ekZg0k7SmUk >									
	//        <  u =="0.000000000000000001" : ] 000000362082770.472910000000000000 ; 000000379710397.142206000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002287E952436460 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < DUBAI_Portfolio_II_metadata_line_21_____Emirates_Islamic_Bank_PJSC_obs_20250515 >									
	//        < 1HJ9g1F0op3Zh3D0o1fz65vrr8I0KtS5o6kgPCOJ7qgrCrs9M0JW8v6p0ippEAS7 >									
	//        <  u =="0.000000000000000001" : ] 000000379710397.142206000000000000 ; 000000396991594.335108000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000243646025DC2D7 >									
	//     < DUBAI_Portfolio_II_metadata_line_22_____Emirates_Investment_Bank_PJSC_obs_20250515 >									
	//        < ADt9cblsQI6jgFQlPJBC2waiipW1Yz825Z9rR521T2hPyZ9e3nj0NrUh9Rv66i18 >									
	//        <  u =="0.000000000000000001" : ] 000000396991594.335108000000000000 ; 000000412638352.538844000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000025DC2D7275A2DB >									
	//     < DUBAI_Portfolio_II_metadata_line_23_____Emirates_NBD_PJSC_obs_20250515 >									
	//        < 2SwqRrL6knAAHqQJhgn4VUR564Sz3z4ysdNW4926oNvVp3mzXrqko7oI1DdgayTa >									
	//        <  u =="0.000000000000000001" : ] 000000412638352.538844000000000000 ; 000000434601363.620330000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000275A2DB2972628 >									
	//     < DUBAI_Portfolio_II_metadata_line_24_____GFH_Financial_Group_BSC_obs_20250515 >									
	//        < u36c9M1h0G312S6l5g134T7f8k1GeN3dLaTr3hvvm3rG2N5kMPh1J0CJstJ4307D >									
	//        <  u =="0.000000000000000001" : ] 000000434601363.620330000000000000 ; 000000450996283.414670000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000029726282B02A6C >									
	//     < DUBAI_Portfolio_II_metadata_line_25_____Mashreqbank_PSc_obs_20250515 >									
	//        < RnXh1DOMC8mlmQ7H6qa76t5InL2DMwrI3co7U35QQe6V0254uQ6X5z9j6r85tryJ >									
	//        <  u =="0.000000000000000001" : ] 000000450996283.414670000000000000 ; 000000467108232.387072000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002B02A6C2C8C027 >									
	//     < DUBAI_Portfolio_II_metadata_line_26_____Al_Salam_Bank _Bahrain_obs_20250515 >									
	//        < 4N7y9Wa803sMkKe4s7VcEu5LuShls43KbDIW4o2XLZ5YLv3841X1v0r55i8rOskJ >									
	//        <  u =="0.000000000000000001" : ] 000000467108232.387072000000000000 ; 000000488282242.001695000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002C8C0272E90F40 >									
	//     < DUBAI_Portfolio_II_metadata_line_27_____Khaleeji_Commercial_Bank_BSC_obs_20250515 >									
	//        < R7ib5993bL7hWKvu75sT3XgHz6MgQK6eIpvqFToS5895o82vWig530538TO12ybZ >									
	//        <  u =="0.000000000000000001" : ] 000000488282242.001695000000000000 ; 000000504843785.451178000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000002E90F40302549B >									
	//     < DUBAI_Portfolio_II_metadata_line_28_____Ithmaar_Holding_BSC_obs_20250515 >									
	//        < 8W2l7800ejuI7jXr46m3vItm3VDtOniPMY5wLd77Lob6GiRc7X5M32Q7134X4gBs >									
	//        <  u =="0.000000000000000001" : ] 000000504843785.451178000000000000 ; 000000522263575.187808000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000302549B31CE936 >									
	//     < DUBAI_Portfolio_II_metadata_line_29_____Alliance_Insurance_obs_20250515 >									
	//        < yN3f98IS95cGvoFX1i0iPn49cl8O0c99PB2H4CN18wd868CZ4C5vAv2rQ63UReqc >									
	//        <  u =="0.000000000000000001" : ] 000000522263575.187808000000000000 ; 000000542133848.793775000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000031CE93633B3B09 >									
	//     < DUBAI_Portfolio_II_metadata_line_30_____Dubai_Islamic_Insurance_and_Reinsurance_Co_obs_20250515 >									
	//        < 6257B3dINWf071Qyyg9k23305k3d3532N183ulssImAIMGR4iOJrDK24eUzxe49P >									
	//        <  u =="0.000000000000000001" : ] 000000542133848.793775000000000000 ; 000000559687250.731489000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000033B3B0935603D5 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
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
	//     < DUBAI_Portfolio_II_metadata_line_31_____Arab_Insurance_Group_BSC_obs_20250515 >									
	//        < 33Nj94ob0pVg7bmG2GV91Th1eGWtFuZfqOgNhAd22K8a9xyMBQ3DzV9bFc9hgmkd >									
	//        <  u =="0.000000000000000001" : ] 000000559687250.731489000000000000 ; 000000580070881.273668000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000035603D53751E30 >									
	//     < DUBAI_Portfolio_II_metadata_line_32_____Arabian_Scandinavian_Insurance_Takaful_obs_20250515 >									
	//        < 6AY9YGzLbQE5M0rqigsSB8ZU2Gh841cPnKA5xD8205Ff8RGuk036JPgJpm1E4orU >									
	//        <  u =="0.000000000000000001" : ] 000000580070881.273668000000000000 ; 000000599563514.297923000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003751E30392DC7F >									
	//     < DUBAI_Portfolio_II_metadata_line_33_____Al_Sagr_National_Insurance_Company_obs_20250515 >									
	//        < kNh0lwz6O7l3In2C216hNVv1fn0g4Pu14jntb5aSA97w3knOWz2yL8WnpKtwh91H >									
	//        <  u =="0.000000000000000001" : ] 000000599563514.297923000000000000 ; 000000618827113.692892000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000392DC7F3B04157 >									
	//     < DUBAI_Portfolio_II_metadata_line_34_____Dar_Al_Takaful_obs_20250515 >									
	//        < 285OI2e3931C6qaH4fO2Aj385cjco1nk1G6l2bpY331V7svcmSS0dL0wXGbOs1Vq >									
	//        <  u =="0.000000000000000001" : ] 000000618827113.692892000000000000 ; 000000638190967.090498000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003B041573CDCD59 >									
	//     < DUBAI_Portfolio_II_metadata_line_35_____Dubai_Insurance_Co_PSC_obs_20250515 >									
	//        < 69s5fv1m3VeQa9i1YfymO6MHQ084HHdtxD42aVyZ7j5kxVf8lTjr59GEOhe16NEF >									
	//        <  u =="0.000000000000000001" : ] 000000638190967.090498000000000000 ; 000000659975286.393057000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003CDCD593EF0AD9 >									
	//     < DUBAI_Portfolio_II_metadata_line_36_____Dubai_National_Insurance_a_Reinsurance_obs_20250515 >									
	//        < cW39IgEcc7fb0Y454QIUzArV65p2INqgRgS9vMVca85F61tbL395eaKrjN0E54l5 >									
	//        <  u =="0.000000000000000001" : ] 000000659975286.393057000000000000 ; 000000676811673.556890000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000003EF0AD9408BB8F >									
	//     < DUBAI_Portfolio_II_metadata_line_37_____National_General_Insurance_Company_PSC_obs_20250515 >									
	//        < mwuRsPb2gxfFa8V4b6rJn08751chu1H8JPIDgH7R1AFAC17771NeOl3xrB0VzZ33 >									
	//        <  u =="0.000000000000000001" : ] 000000676811673.556890000000000000 ; 000000695078961.416265000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000408BB8F4249B38 >									
	//     < DUBAI_Portfolio_II_metadata_line_38_____Oman_Insurance_Company_PSC_obs_20250515 >									
	//        < 1X9OjT8Wef5gMUY8Z4HMA3tO8m68095yl85682R0eBm8VqNOo2Dc4bAM1qah2tyE >									
	//        <  u =="0.000000000000000001" : ] 000000695078961.416265000000000000 ; 000000715643774.227475000000000000 ] >									
	//        < 0x000000000000000000000000000000000000000000000000004249B38443FC59 >									
	//     < DUBAI_Portfolio_II_metadata_line_39_____Islamic_Arab_Insurance_Company_obs_20250515 >									
	//        < OOzmp281ih35FC240p2RJf8GHyX5nmqNUFunDRtwtgV3067WP4LV8v8ooxKZu1J4 >									
	//        <  u =="0.000000000000000001" : ] 000000715643774.227475000000000000 ; 000000732108212.494711000000000000 ] >									
	//        < 0x00000000000000000000000000000000000000000000000000443FC5945D1BC5 >									
	//     < DUBAI_Portfolio_II_metadata_line_40_____Takaful_Emarat_PSC_obs_20250515 >									
	//        < KBp4457B0z1UtcclVEvu3n3ucT9VGmeDD07KD8C84G6Ftwyzi87kN42u4jFQtrE5 >									
	//        <  u =="0.000000000000000001" : ] 000000732108212.494711000000000000 ; 000000747599432.793525000000000000 ] >									
	//        < 0x0000000000000000000000000000000000000000000000000045D1BC5474BF07 >									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}