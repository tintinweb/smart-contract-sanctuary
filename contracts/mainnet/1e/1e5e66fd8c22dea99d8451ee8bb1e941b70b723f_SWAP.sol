pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assertCheck(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assertCheck(b > 0);
    uint256 c = a / b;
    assertCheck(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assertCheck(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assertCheck(c>=a && c>=b);
    return c;
  }

  function assertCheck(bool assertion) internal pure {
    require(assertion == true);
  }
}
contract SWAP is SafeMath{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
	address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function setName(string _name) onlyOwner public returns (string){
         name = _name;
         return name;
    }
    function setSymbol(string _symbol) onlyOwner public returns (string){
         symbol = _symbol;
         return symbol;
     }
    
     function setDecimals(uint256 _decimals) onlyOwner public returns (uint256){
         decimals = _decimals;
         return decimals;
     }
    
    
     function getOwner() view public returns(address){
        return owner;
     }
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    event Withdraw(address to, uint amount);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public payable {
        balanceOf[msg.sender] = 100000000000*10**18;
        totalSupply = balanceOf[msg.sender];
        name = &#39;SWAP&#39;; 
        symbol = &#39;SWAP&#39;; 
        decimals = 18; 
		owner = msg.sender;
    }

   
    function _transfer(address _from, address _to, uint _value) internal{
        require(_to != 0x0); 
		require(_value > 0); 
        require(balanceOf[_from] >= _value);   
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);               
        emit Transfer(_from, _to, _value);       
    }


    function transfer(address _to, uint256 _value) public payable returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success) {
		require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) 
    public
    payable  {
        require (_to != 0x0) ;             
		require (_value > 0); 
        require (balanceOf[_from] >= _value) ;       
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;
        require (_value <= allowance[_from][msg.sender]) ;   
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);               
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);  
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
		require (_value > 0) ; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value); // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    function create(uint256 _value) public onlyOwner returns (bool success) {
        require (_value > 0) ; 
        totalSupply = SafeMath.safeAdd(totalSupply,_value);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        return true;
    }
    
	// transfer balance to owner
	function withdraw() external onlyOwner{
		require(msg.sender == owner);
		msg.sender.transfer(address(this).balance);
        emit Withdraw(msg.sender,address(this).balance);
	}
	
	// can accept ether
	function() private payable {
    }
}