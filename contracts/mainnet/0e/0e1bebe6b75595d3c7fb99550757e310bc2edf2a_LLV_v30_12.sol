pragma solidity 		^0.4.21	;							
											
	interface IERC20Token {										
		function totalSupply() public constant returns (uint);									
		function balanceOf(address tokenlender) public constant returns (uint balance);									
		function allowance(address tokenlender, address spender) public constant returns (uint remaining);									
		function transfer(address to, uint tokens) public returns (bool success);									
		function approve(address spender, uint tokens) public returns (bool success);									
		function transferFrom(address from, address to, uint tokens) public returns (bool success);									
											
		event Transfer(address indexed from, address indexed to, uint tokens);									
		event Approval(address indexed tokenlender, address indexed spender, uint tokens);									
	}										
											
	contract	LLV_v30_12		{							
											
		address	owner	;							
											
		function	LLV_v30_12		()	public	{				
			owner	= msg.sender;							
		}									
											
		modifier	onlyOwner	() {							
			require(msg.sender ==		owner	);					
			_;								
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	ID	=	1000	;					
											
		function	setID	(	uint256	newID	)	public	onlyOwner	{	
			ID	=	newID	;					
		}									
											
		function	getID	()	public	constant	returns	(	uint256	)	{
			return	ID	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	ID_control	=	1000	;					
											
		function	setID_control	(	uint256	newID_control	)	public	onlyOwner	{	
			ID_control	=	newID_control	;					
		}									
											
		function	getID_control	()	public	constant	returns	(	uint256	)	{
			return	ID_control	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	Cmd	=	1000	;					
											
		function	setCmd	(	uint256	newCmd	)	public	onlyOwner	{	
			Cmd	=	newCmd	;					
		}									
											
		function	getCmd	()	public	constant	returns	(	uint256	)	{
			return	Cmd	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	Cmd_control	=	1000	;					
											
		function	setCmd_control	(	uint256	newCmd_control	)	public	onlyOwner	{	
			Cmd_control	=	newCmd_control	;					
		}									
											
		function	getCmd_control	()	public	constant	returns	(	uint256	)	{
			return	Cmd_control	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	Depositary_function	=	1000	;					
											
		function	setDepositary_function	(	uint256	newDepositary_function	)	public	onlyOwner	{	
			Depositary_function	=	newDepositary_function	;					
		}									
											
		function	getDepositary_function	()	public	constant	returns	(	uint256	)	{
			return	Depositary_function	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	Depositary_function_control	=	1000	;					
											
		function	setDepositary_function_control	(	uint256	newDepositary_function_control	)	public	onlyOwner	{	
			Depositary_function_control	=	newDepositary_function_control	;					
		}									
											
		function	getDepositary_function_control	()	public	constant	returns	(	uint256	)	{
			return	Depositary_function_control	;						
		}									
											
											
											
		address	public	User_1		=	msg.sender				;
		address	public	User_2		;//	_User_2				;
		address	public	User_3		;//	_User_3				;
		address	public	User_4		;//	_User_4				;
		address	public	User_5		;//	_User_5				;
											
		IERC20Token	public	Securities_1		;//	_Securities_1				;
		IERC20Token	public	Securities_2		;//	_Securities_2				;
		IERC20Token	public	Securities_3		;//	_Securities_3				;
		IERC20Token	public	Securities_4		;//	_Securities_4				;
		IERC20Token	public	Securities_5		;//	_Securities_5				;
											
		uint256	public	Standard_1		;//	_Standard_1				;
		uint256	public	Standard_2		;//	_Standard_2				;
		uint256	public	Standard_3		;//	_Standard_3				;
		uint256	public	Standard_4		;//	_Standard_4				;
		uint256	public	Standard_5		;//	_Standard_5				;
											
		function	Eligibility_Group_1				(				
			address	_User_1		,					
			IERC20Token	_Securities_1		,					
			uint256	_Standard_1							
		)									
			public	onlyOwner							
		{									
			User_1		=	_User_1		;			
			Securities_1		=	_Securities_1		;			
			Standard_1		=	_Standard_1		;			
		}									
											
		function	Eligibility_Group_2				(				
			address	_User_2		,					
			IERC20Token	_Securities_2		,					
			uint256	_Standard_2							
		)									
			public	onlyOwner							
		{									
			User_2		=	_User_2		;			
			Securities_2		=	_Securities_2		;			
			Standard_2		=	_Standard_2		;			
		}									
											
		function	Eligibility_Group_3				(				
			address	_User_3		,					
			IERC20Token	_Securities_3		,					
			uint256	_Standard_3							
		)									
			public	onlyOwner							
		{									
			User_3		=	_User_3		;			
			Securities_3		=	_Securities_3		;			
			Standard_3		=	_Standard_3		;			
		}									
											
		function	Eligibility_Group_4				(				
			address	_User_4		,					
			IERC20Token	_Securities_4		,					
			uint256	_Standard_4							
		)									
			public	onlyOwner							
		{									
			User_4		=	_User_4		;			
			Securities_4		=	_Securities_4		;			
			Standard_4		=	_Standard_4		;			
		}									
											
		function	Eligibility_Group_5				(				
			address	_User_5		,					
			IERC20Token	_Securities_5		,					
			uint256	_Standard_5							
		)									
			public	onlyOwner							
		{									
			User_5		=	_User_5		;			
			Securities_5		=	_Securities_5		;			
			Standard_5		=	_Standard_5		;			
		}									
		//									
		//									
											
		function	retrait_1				()	public	{		
			require(	msg.sender == User_1			);				
			require(	Securities_1.transfer(User_1, Standard_1)			);				
			require(	ID == ID_control			);				
			require(	Cmd == Cmd_control			);				
			require(	Depositary_function == Depositary_function_control			);				
		}									
											
		function	retrait_2				()	public	{		
			require(	msg.sender == User_2			);				
			require(	Securities_2.transfer(User_2, Standard_2)			);				
			require(	ID == ID_control			);				
			require(	Cmd == Cmd_control			);				
			require(	Depositary_function == Depositary_function_control			);				
		}									
											
		function	retrait_3				()	public	{		
			require(	msg.sender == User_3			);				
			require(	Securities_3.transfer(User_3, Standard_3)			);				
			require(	ID == ID_control			);				
			require(	Cmd == Cmd_control			);				
			require(	Depositary_function == Depositary_function_control			);				
		}									
											
		function	retrait_4				()	public	{		
			require(	msg.sender == User_4			);				
			require(	Securities_4.transfer(User_4, Standard_4)			);				
			require(	ID == ID_control			);				
			require(	Cmd == Cmd_control			);				
			require(	Depositary_function == Depositary_function_control			);				
		}									
											
		function	retrait_5				()	public	{		
			require(	msg.sender == User_1			);				
			require(	Securities_5.transfer(User_5, Standard_5)			);				
			require(	ID == ID_control			);				
			require(	Cmd == Cmd_control			);				
			require(	Depositary_function == Depositary_function_control			);				
		}									
											
											
											
											
//	1	Descriptif									
//	2	Place de march&#233; d&#233;centralis&#233;e									
//	3	Forme juridique									
//	4	Pool pair &#224; pair d&#233;ploy&#233; dans un environnement TP/SC-CDC (*)									
//	5	D&#233;nomination									
//	6	&#171;&#160;LUEBECK_LA_VALETTE&#160;&#187; / &#171;&#160;LLV_gruppe_v30.12&#160;&#187;									
//	7	Statut									
//	8	&#171;&#160;D.A.O.&#160;&#187; (Organisation autonome et d&#233;centralis&#233;e)									
//	9	Propri&#233;taires & responsables implicites									
//	10	Les Utilisateurs du pool									
//	11	Juridiction (i)									
//	12	&#171;&#160;Lausanne, Canton de Vaud, Conf&#233;d&#233;ration Helv&#233;tique&#160;&#187;									
//	13	Juridiction (ii)									
//	14	&#171;&#160;Wien, Bundesland Wien, Austria&#160;&#187;									
//	15	Instrument mon&#233;taire de r&#233;f&#233;rence (i)									
//	16	&#171;&#160;ethchf&#160;&#187;									
//	17	Instrument mon&#233;taire de r&#233;f&#233;rence (ii)									
//	18	&#171;&#160;etheur&#160;&#187;									
//	19	Instrument mon&#233;taire de r&#233;f&#233;rence (iii)									
//	20	&#171;&#160;ethczk&#160;&#187;									
//	21	Devise de r&#233;f&#233;rence (i)									
//	22	&#171;&#160;CHF&#160;&#187;									
//	23	Devise de r&#233;f&#233;rence (ii)									
//	24	&#171;&#160;EUR&#160;&#187;									
//	25	Devise de r&#233;f&#233;rence (iii)									
//	26	&#171;&#160;CZK&#160;&#187;									
//	27	Date de d&#233;ployement initial									
//	28	19.09.2008 (date de reprise des actifs de la holding en liquidation)									
//	29	Environnement de d&#233;ployement initial									
//	30	(1&#160;: 19.09.2008-01.08.2017) OTC (Lausanne)&#160;; (2&#160;: 01.08.2017-29.04.2018) suite protocolaire sur-couche &#171;&#160;88.2&#160;&#187; 									
//	31	Objet principal (i)									
//	32	Services de place de march&#233; et de teneur de march&#233; sous la forme d’un pool mutuel									
//	33	Objet principal (ii)									
//	34	Gestion des activit&#233;s post-march&#233;, dont&#160;: contrepartie centrale et d&#233;positaire									
//	35	Objet principal (iii)									
//	36	Garant									
//	37	Objet principal (iv)									
//	38	Teneur de compte									
//	39	Objet principal (v)									
//	40	&#171;&#160;Chambre de compensation&#160;&#187;									
//	41	Objet principal (vi)									
//	42	Op&#233;rateur &#171;&#160;r&#232;glement-livraison&#160;&#187;									
//	43	@ de communication additionnelle (i)									
//	44	0x49720E96dC488c75DFE1576b3b2965b4fED92575 (# 15)									
//	45	@ de communication additionnelle (ii)									
//	46	0x2DF6FfB4e9B27Df827a7c8DEb31555875e095b3e (# 16)									
//	47	@ de publication additionnelle (protocole PP, i)									
//	48	0xD1dEB350B3ea3FEF2d6f0Ece4F19419B1c37A43f (# 17)									
//	49	Entit&#233; responsable du d&#233;veloppement									
//	50	Programme d’apprentissage autonome &#171;&#160;EVA&#160;&#187; / &#171;&#160;KYOKO&#160;&#187; / MS (sign)									
//	51	Entit&#233; responsable de l’&#233;dition									
//	52	Programme d’apprentissage autonome &#171;&#160;EVA&#160;&#187; / &#171;&#160;KYOKO&#160;&#187; / MS (sign)									
//	53	Entit&#233; responsable du d&#233;ployement initial									
//	54	Programme d’apprentissage autonome &#171;&#160;EVA&#160;&#187; / &#171;&#160;KYOKO&#160;&#187; / MS (sign)									
//	55	(*) Environnement technologique protocolaire / sous-couche de type &#171;&#160;Consensus Distribu&#233; et Chiffr&#233;&#160;&#187;									
//	56	(**) @ Annexes et formulaires&#160;: <<<< --------------------------------- >>>> (confer&#160;: points 43 &#224; 48)									
//	57	-									
//	58	-									
//	59	-									
//	60	-									
//	61	-									
//	62	-									
//	63	-									
//	64	-									
//	65	-									
//	66	-									
//	67	-									
//	68	-									
//	69	-									
//	70	-									
//	71	-									
//	72	-									
//	73	-									
//	74	-									
//	75	-									
//	76	-									
//	77	-									
//	78	-									
											
											
}