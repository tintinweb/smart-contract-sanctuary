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
											
	contract	BOT_ELEMENT_4		{							
											
		address	owner	;							
											
		function	BOT_ELEMENT_4		()	public	{				
			owner	= msg.sender;							
		}									
											
		modifier	onlyOwner	() {							
			require(msg.sender ==		owner	);					
			_;								
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	arg_1	=	190191	;					
											
		function	setarg_1	(	uint256	newarg_1	)	public	onlyOwner	{	
			arg_1	=	newarg_1	;					
		}									
											
		function	getarg_1	()	public	constant	returns	(	uint256	)	{
			return	arg_1	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	arg_1_input	=	1000	;					
											
		function	setarg_1_input	(	uint256	newarg_1_input	)	public	onlyOwner	{	
			arg_1_input	=	newarg_1_input	;					
		}									
											
		function	getarg_1_input	()	public	constant	returns	(	uint256	)	{
			return	arg_1_input	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	arg_2	=	1000	;					
											
		function	setarg_2	(	uint256	newarg_2	)	public	onlyOwner	{	
			arg_2	=	newarg_2	;					
		}									
											
		function	getarg_2	()	public	constant	returns	(	uint256	)	{
			return	arg_2	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	arg_2_input	=	1000	;					
											
		function	setarg_2_input	(	uint256	newarg_2_input	)	public	onlyOwner	{	
			arg_2_input	=	newarg_2_input	;					
		}									
											
		function	getarg_2_input	()	public	constant	returns	(	uint256	)	{
			return	arg_2_input	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	arg_3	=	1000	;					
											
		function	setarg_3	(	uint256	newarg_3	)	public	onlyOwner	{	
			arg_3	=	newarg_3	;					
		}									
											
		function	getarg_3	()	public	constant	returns	(	uint256	)	{
			return	arg_3	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		uint256	arg_3_input	=	1000	;					
											
		function	setarg_3_input	(	uint256	newarg_3_input	)	public	onlyOwner	{	
			arg_3_input	=	newarg_3_input	;					
		}									
											
		function	getarg_3_input	()	public	constant	returns	(	uint256	)	{
			return	arg_3_input	;						
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
											
		function	Admin_1				(				
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
											
		function	Admin_2				(				
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
											
		function	Admin_3				(				
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
											
		function	Admin_4				(				
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
											
		function	Admin_5				(				
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
											
		function	instruct_1				()	public	{		
			require(	msg.sender == User_1			);				
			require(	Securities_1.transfer(User_1, Standard_1)			);				
			require(	arg_1 == arg_1_input			);				
			require(	arg_2 == arg_2_input			);				
			require(	arg_3 == arg_3_input			);				
		}									
											
		function	instruct_2				()	public	{		
			require(	msg.sender == User_2			);				
			require(	Securities_2.transfer(User_2, Standard_2)			);				
			require(	arg_1 == arg_1_input			);				
			require(	arg_2 == arg_2_input			);				
			require(	arg_3 == arg_3_input			);				
		}									
											
		function	instruct_3				()	public	{		
			require(	msg.sender == User_3			);				
			require(	Securities_3.transfer(User_3, Standard_3)			);				
			require(	arg_1 == arg_1_input			);				
			require(	arg_2 == arg_2_input			);				
			require(	arg_3 == arg_3_input			);				
		}									
											
		function	instruct_4				()	public	{		
			require(	msg.sender == User_1			);				
			require(	Securities_4.transfer(User_4, Standard_4)			);				
			require(	arg_1 == arg_1_input			);				
			require(	arg_2 == arg_2_input			);				
			require(	arg_3 == arg_3_input			);				
		}									
											
		function	instruct_5				()	public	{		
			require(	msg.sender == User_1			);				
			require(	Securities_5.transfer(User_5, Standard_5)			);				
			require(	arg_1 == arg_1_input			);				
			require(	arg_2 == arg_2_input			);				
			require(	arg_3 == arg_3_input			);				
		}									
											
											
}