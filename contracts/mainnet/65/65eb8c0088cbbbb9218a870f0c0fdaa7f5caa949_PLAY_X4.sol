pragma solidity 		^0.4.8	;							
											
	contract	Ownable		{							
		address	owner	;							
											
		function	Ownable	() {							
			owner	= msg.sender;							
		}									
											
		modifier	onlyOwner	() {							
			require(msg.sender ==		owner	);					
			_;								
		}									
											
		function 	transfertOwnership		(address	newOwner	)	onlyOwner	{		
			owner	=	newOwner	;					
		}									
	}										
											
											
											
	contract	PLAY_X4				is	Ownable	{			
											
		string	public	constant	name =	"	PLAY_X4		"	;	
		string	public	constant	symbol =	"	PLAYX4		"	;	
		uint32	public	constant	decimals =		18			;	
		uint	public		totalSupply =		10000000000000000000000000			;	
											
		mapping (address => uint) balances;									
		mapping (address => mapping(address => uint)) allowed;									
											
		function mint(address _to, uint _value) onlyOwner {									
			assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);								
			balances[_to] += _value;								
			totalSupply += _value;								
		}									
											
		function balanceOf(address _owner) constant returns (uint balance) {									
			return balances[_owner];								
		}									
											
		function transfer(address _to, uint _value) returns (bool success) {									
			if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {								
				balances[msg.sender] -= _value; 							
				balances[_to] += _value;							
				return true;							
			}								
			return false;								
		}									
											
		function transferFrom(address _from, address _to, uint _value) returns (bool success) {									
			if( allowed[_from][msg.sender] >= _value &&								
				balances[_from] >= _value 							
				&& balances[_to] + _value >= balances[_to]) {							
				allowed[_from][msg.sender] -= _value;							
				balances[_from] -= _value;							
				balances[_to] += _value;							
				Transfer(_from, _to, _value);							
				return true;							
			}								
			return false;								
		}									
											
		function approve(address _spender, uint _value) returns (bool success) {									
			allowed[msg.sender][_spender] = _value;								
			Approval(msg.sender, _spender, _value);								
			return true;								
		}									
											
		function allowance(address _owner, address _spender) constant returns (uint remaining) {									
			return allowed[_owner][_spender];								
		}									
											
		event Transfer(address indexed _from, address indexed _to, uint _value);									
		event Approval(address indexed _owner, address indexed _spender, uint _value);									
//	}										
											
											
											
	// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		string	inData_1	=	"	FIFA WORLD CUP 2018			"	;	
											
		function	setData_1	(	string	newData_1	)	public	onlyOwner	{	
			inData_1	=	newData_1	;					
		}									
											
		function	getData_1	()	public	constant	returns	(	string	)	{
			return	inData_1	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		string	inData_2	=	"	Match : 16.06.2018 21:00 (Bern Time)			"	;	
											
		function	setData_2	(	string	newData_2	)	public	onlyOwner	{	
			inData_2	=	newData_2	;					
		}									
											
		function	getData_2	()	public	constant	returns	(	string	)	{
			return	inData_2	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		string	inData_3	=	"	CROATIA - NIGERIA			"	;	
											
		function	setData_3	(	string	newData_3	)	public	onlyOwner	{	
			inData_3	=	newData_3	;					
		}									
											
		function	getData_3	()	public	constant	returns	(	string	)	{
			return	inData_3	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		string	inData_4	=	"	COTES [2.2676 ; 4.2113 ; 3.1099]			"	;	
											
		function	setData_4	(	string	newData_4	)	public	onlyOwner	{	
			inData_4	=	newData_4	;					
		}									
											
		function	getData_4	()	public	constant	returns	(	string	)	{
			return	inData_4	;						
		}									
											
											
											
	// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
											
											
		string	inData_5	=	"	X			"	;	
											
		function	setData_5	(	string	newData_5	)	public	onlyOwner	{	
			inData_5	=	newData_5	;					
		}									
											
		function	getData_5	()	public	constant	returns	(	string	)	{
			return	inData_5	;						
		}									
											
											
	}