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
										
contract	DTCC_ILOW_7		{							
										
	address	owner	;							
										
	function	DTCC_ILOW_7		()	public	{				
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
		require(	Securities_2.transfer(User_1, Standard_2)			);				
		require(	ID == ID_control			);				
		require(	Cmd == Cmd_control			);				
		require(	Depositary_function == Depositary_function_control			);				
	}									
										
	function	retrait_3				()	public	{		
		require(	msg.sender == User_3			);				
		require(	Securities_3.transfer(User_1, Standard_3)			);				
		require(	ID == ID_control			);				
		require(	Cmd == Cmd_control			);				
		require(	Depositary_function == Depositary_function_control			);				
	}									
										
	function	retrait_4				()	public	{		
		require(	msg.sender == User_4			);				
		require(	Securities_4.transfer(User_1, Standard_4)			);				
		require(	ID == ID_control			);				
		require(	Cmd == Cmd_control			);				
		require(	Depositary_function == Depositary_function_control			);				
	}									
										
	function	retrait_5				()	public	{		
		require(	msg.sender == User_5			);				
		require(	Securities_5.transfer(User_1, Standard_5)			);				
		require(	ID == ID_control			);				
		require(	Cmd == Cmd_control			);				
		require(	Depositary_function == Depositary_function_control			);				
	}									
										
										
										
										
// Descriptif					0					
// Forme juridique					&#171;&#160;Organisation autonome et d&#233;centralis&#233;e&#160;&#187;					
// D&#233;nomination					&#171;&#160;TYUMEN-LUZERN CONNECT&#160;&#187;					
// Statut					&#171;&#160;D.A.O.&#160;&#187;					
// Propri&#233;taires & responsables implicites					Le pool d’utilisateurs					
// Juridiction (i)					Oblast de Tyumen, F&#233;d&#233;ration de Russie					
// Juridiction (ii)					Ville et canton de Luzern, Conf&#233;d&#233;ration H&#233;lv&#233;tique					
// instrument mon&#233;taire de r&#233;f&#233;rence (i)					&#171;&#160;ethrub&#160;&#187;					
// instrument mon&#233;taire de r&#233;f&#233;rence (ii)					&#171;&#160;ethchf&#160;&#187;					
// instrument mon&#233;taire de r&#233;f&#233;rence (iii)					&#171;&#160;ethkzt&#160;&#187;					
// devise de r&#233;f&#233;rence (i)					&#171;&#160;RUB&#160;&#187;					
// devise de r&#233;f&#233;rence (ii)					&#171;&#160;CHF&#160;&#187;					
// devise de r&#233;f&#233;rence (iii)					&#171;&#160;KZT&#160;&#187;					
// Date de d&#233;ployement initiale					09.03.2017					
// Environnement de d&#233;ployement initial					suite protocolaire sur-couche &#171;&#160;88.2&#160;&#187; blockchain BITCOIN					
// Objet principal (i)					Gestion des activit&#233;s post-march&#233;					
// Objet principal (ii)					Contrepartie centrale					
// Objet principal (iii)					Garant					
// Objet principal (iv)					D&#233;positaire					
// Objet principal (v)					Teneur de compte					
// Objet principal (vi)					&#171;&#160;Chambre de compensation&#160;&#187;					
// Objet principal (vii)					Op&#233;rateur &#171;&#160;r&#232;glement-livraison&#160;&#187;					
// @ de communication additionnelle (i)					0xa24794106a6be5d644dd9ace9cbb98478ac289f5					
// @ de communication additionnelle (ii)					0x8580dF106C8fF87911d4c2a9c815fa73CAD1cA38					
// @ de publication additionnelle (protocole PP, i)					0xf7Aa11C7d092d956FC7Ca08c108a1b2DaEaf3171					
// @ de publication additionnelle (protocole PP, ii)					0x2Eab17625B3040E02c97cE84bEBEEc8eFA703ce4					
// Entit&#233; responsable du d&#233;veloppement					Programme d’apprentissage autonome &#171;&#160;KYOKO&#160;&#187; / MS (sign)					
// Entit&#233; responsable de l’&#233;dition					Programme d’apprentissage autonome &#171;&#160;KYOKO&#160;&#187; / MS (sign)					
// Entit&#233; responsable du d&#233;ployement initial					Programme d’apprentissage autonome &#171;&#160;KYOKO&#160;&#187; / MS (sign)					
										
										
}