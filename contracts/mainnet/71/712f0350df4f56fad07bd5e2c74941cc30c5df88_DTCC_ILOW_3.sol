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
										
contract	DTCC_ILOW_3		{							
										
	address	owner	;							
										
	function	DTCC_ILOW_2		()	public	{				
		owner	= msg.sender;							
	}									
										
	modifier	onlyOwner	() {							
		require(msg.sender ==		owner	);					
		_;								
	}									
										
										
										
// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
										
										
	uint256	inData_1	=	1000	;					
										
	function	setData_1	(	uint256	newData_1	)	public	onlyOwner	{	
		inData_1	=	newData_1	;					
	}									
										
	function	getData_1	()	public	constant	returns	(	uint256	)	{
		return	inData_1	;						
	}									
										
										
										
// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
										
										
	uint256	inData_2	=	1000	;					
										
	function	setData_2	(	uint256	newData_2	)	public	onlyOwner	{	
		inData_2	=	newData_2	;					
	}									
										
	function	getData_2	()	public	constant	returns	(	uint256	)	{
		return	inData_2	;						
	}									
										
										
										
// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
										
										
	uint256	inData_3	=	1000	;					
										
	function	setData_3	(	uint256	newData_3	)	public	onlyOwner	{	
		inData_3	=	newData_3	;					
	}									
										
	function	getData_3	()	public	constant	returns	(	uint256	)	{
		return	inData_3	;						
	}									
										
										
										
// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
										
										
	uint256	inData_4	=	1000	;					
										
	function	setData_4	(	uint256	newData_4	)	public	onlyOwner	{	
		inData_4	=	newData_4	;					
	}									
										
	function	getData_4	()	public	constant	returns	(	uint256	)	{
		return	inData_4	;						
	}									
										
										
										
// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
										
										
	uint256	inData_5	=	1000	;					
										
	function	setData_5	(	uint256	newData_5	)	public	onlyOwner	{	
		inData_5	=	newData_5	;					
	}									
										
	function	getData_5	()	public	constant	returns	(	uint256	)	{
		return	inData_5	;						
	}									
										
										
										
// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
										
										
	uint256	inData_6	=	1000	;					
										
	function	setData_6	(	uint256	newData_6	)	public	onlyOwner	{	
		inData_6	=	newData_6	;					
	}									
										
	function	getData_6	()	public	constant	returns	(	uint256	)	{
		return	inData_6	;						
	}									
										
										
										
	address	public	User_1		=	msg.sender				;
	address	public	User_2		;//	_User_2				;
	address	public	User_3		;//	_User_3				;
	address	public	User_4		;//	_User_4				;
	address	public	User_5		;//	_User_5				;
										
	IERC20Token	public	Token_1		;//	_Token_1				;
	IERC20Token	public	Token_2		;//	_Token_2				;
	IERC20Token	public	Token_3		;//	_Token_3				;
	IERC20Token	public	Token_4		;//	_Token_4				;
	IERC20Token	public	Token_5		;//	_Token_5				;
										
	uint256	public	retraitStandard_1		;//	_retraitStandard_1				;
	uint256	public	retraitStandard_2		;//	_retraitStandard_2				;
	uint256	public	retraitStandard_3		;//	_retraitStandard_3				;
	uint256	public	retraitStandard_4		;//	_retraitStandard_4				;
	uint256	public	retraitStandard_5		;//	_retraitStandard_5				;
										
	function	admiss_1				(				
		address	_User_1		,					
		IERC20Token	_Token_1		,					
		uint256	_retraitStandard_1							
	)									
		public	onlyOwner							
	{									
		User_1		=	_User_1		;			
		Token_1		=	_Token_1		;			
		retraitStandard_1		=	_retraitStandard_1		;			
	}									
										
	function	admiss_2				(				
		address	_User_2		,					
		IERC20Token	_Token_2		,					
		uint256	_retraitStandard_2							
	)									
		public	onlyOwner							
	{									
		User_2		=	_User_2		;			
		Token_2		=	_Token_2		;			
		retraitStandard_2		=	_retraitStandard_2		;			
	}									
										
	function	admiss_3				(				
		address	_User_3		,					
		IERC20Token	_Token_3		,					
		uint256	_retraitStandard_3							
	)									
		public	onlyOwner							
	{									
		User_3		=	_User_3		;			
		Token_3		=	_Token_3		;			
		retraitStandard_3		=	_retraitStandard_3		;			
	}									
										
	function	admiss_4				(				
		address	_User_4		,					
		IERC20Token	_Token_4		,					
		uint256	_retraitStandard_4							
	)									
		public	onlyOwner							
	{									
		User_4		=	_User_4		;			
		Token_4		=	_Token_4		;			
		retraitStandard_4		=	_retraitStandard_4		;			
	}									
										
	function	admiss_5				(				
		address	_User_5		,					
		IERC20Token	_Token_5		,					
		uint256	_retraitStandard_5							
	)									
		public	onlyOwner							
	{									
		User_5		=	_User_5		;			
		Token_5		=	_Token_5		;			
		retraitStandard_5		=	_retraitStandard_5		;			
	}									
	//									
	//									
										
	function	retrait_1				()	public	{		
		require(	msg.sender == User_1			);				
		require(	Token_1.transfer(User_1, retraitStandard_1)			);				
		require(	inData_1 == inData_2			);				
		require(	inData_3 == inData_4			);				
		require(	inData_5 == inData_6			);				
	}									
										
	function	retrait_2				()	public	{		
		require(	msg.sender == User_2			);				
		require(	Token_2.transfer(User_2, retraitStandard_2)			);				
		require(	inData_1 == inData_2			);				
		require(	inData_3 == inData_4			);				
		require(	inData_5 == inData_6			);				
	}									
										
	function	retrait_3				()	public	{		
		require(	msg.sender == User_3			);				
		require(	Token_3.transfer(User_3, retraitStandard_3)			);				
		require(	inData_1 == inData_2			);				
		require(	inData_3 == inData_4			);				
		require(	inData_5 == inData_6			);				
	}									
										
	function	retrait_4				()	public	{		
		require(	msg.sender == User_4			);				
		require(	Token_4.transfer(User_4, retraitStandard_4)			);				
		require(	inData_1 == inData_2			);				
		require(	inData_3 == inData_4			);				
		require(	inData_5 == inData_6			);				
	}									
										
	function	retrait_5				()	public	{		
		require(	msg.sender == User_5			);				
		require(	Token_5.transfer(User_5, retraitStandard_5)			);				
		require(	inData_1 == inData_2			);				
		require(	inData_3 == inData_4			);				
		require(	inData_5 == inData_6			);				
	}									
										

}