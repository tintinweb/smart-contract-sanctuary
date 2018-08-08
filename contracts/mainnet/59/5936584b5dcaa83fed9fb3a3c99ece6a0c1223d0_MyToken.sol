pragma solidity ^0.4.18;

interface ERC223
{
	function transfer(address _to, uint _value, bytes _data) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed data);
}

interface ERC20
{
	function transferFrom(address _from, address _to, uint _value) public returns(bool);
	function approve(address _spender, uint _value) public returns (bool);
	function allowance(address _owner, address _spender) public constant returns(uint);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract ERC223ReceivingContract
{
	function tokenFallBack(address _from, uint _value, bytes _data)public;	 
}

contract Token
{
	string internal _symbol;
	string internal _name;
	uint8 internal _decimals;	
    uint256 internal _totalSupply;
   	mapping(address =>uint) internal _balanceOf;
	mapping(address => mapping(address => uint)) internal _allowances;

    function Token(string symbol, string name, uint8 decimals, uint256 totalSupply) public{
	    _symbol = symbol;
		_name = name;
		_decimals = decimals;
		_totalSupply = totalSupply;
    }

	function name() public constant returns (string){
        	return _name;    
	}

	function symbol() public constant returns (string){
        	return _symbol;    
	}

	function decimals() public constant returns (uint8){
		return _decimals;
	}

	function totalSupply() public constant returns (uint256){
        	return _totalSupply;
	}
            	
	event Transfer(address indexed _from, address indexed _to, uint _value);	
}


contract admined{
	address public admin;
	function admined()public
	{
		admin = msg.sender;	
	}
	modifier onlyAdmin()
	{
		require(msg.sender == admin);		// if msg.sender is not an admin then throw exception
		_;					// to execute as it is where this modifier will call
	}

	function transferAdminShip(address newAdmin) public onlyAdmin
	{
		admin = newAdmin;
	}
}

contract MyToken is Token("TANT","Talent Token",18,50000000000000000000000000),ERC20,ERC223,admined
{   
    uint256 public sellPrice;
    uint256 public buyPrice;
    function MyToken() public
    {
    	_balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256){
    	return _totalSupply;  
	}
	
	function findBalance(address _addr) public constant returns (uint) {
	    return _balanceOf[_addr];
	}

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(_balanceOf[_from] >= _value);
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
        _balanceOf[_from] -= _value;
        _balanceOf[_to]+=_value;
        Transfer(_from, _to, _value);
        assert(_balanceOf[_from] +_balanceOf[_to] == previousBalances);
    }
    
	function transfer(address _to, uint256 _value)public{
    	if(!isContract(_to))
    	{
		    _transfer(msg.sender, _to, _value); 
	    }
	}
	
	function transferFrom(address _from, address _to, uint256 _value)public returns(bool){
    	require(_allowances[_from][msg.sender] >= _value);
    	{
			_allowances[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);            
			return true;
    	}
    	return false;
   }

	function transfer(address _to, uint _value, bytes _data)public returns(bool)
	{
	    require(_value>0 && _value <= _balanceOf[msg.sender]);
		if(isContract(_to))
		{
			_balanceOf[msg.sender]-= _value;
	       	_balanceOf[_to]+=_value;
			ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
			_contract.tokenFallBack(msg.sender,_value,_data);
			Transfer(msg.sender, _to, _value, _data); 
    		return true;
		}
		return false;
	}

	function isContract(address _addr) internal view returns(bool){
		uint codeLength;
		assembly
		{
		    codeLength := extcodesize(_addr)
	    }
		return codeLength > 0;
	}	
    
	function approve(address _spender, uint _value) public returns (bool)
	{
    	_allowances[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);	
    	return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns(uint)
    {
    	return _allowances[_owner][_spender];
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice){
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy () public payable
	{
		uint256 amount = (msg.value/(1 ether))/ buyPrice;
		require(_balanceOf[this]< amount);
		_balanceOf[msg.sender]+=amount;
		_balanceOf[this]-=amount;
		Transfer(this,msg.sender,amount);
	}

	function sell(uint256 amount) public
	{
		require(_balanceOf[msg.sender]<amount);
		_balanceOf[this]+= amount;
		_balanceOf[msg.sender]-=amount;
		require(!msg.sender.send(amount*sellPrice * 1 ether));
		Transfer(msg.sender,this,amount);
	}
}