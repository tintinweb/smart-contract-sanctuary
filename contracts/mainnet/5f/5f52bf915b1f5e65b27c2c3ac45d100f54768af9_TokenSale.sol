pragma solidity ^0.4.18;

contract Token {

  function totalSupply () constant returns (uint256 _totalSupply);

  function balanceOf (address _owner) constant returns (uint256 balance);

  function transfer (address _to, uint256 _value) returns (bool success);

  function transferFrom (address _from, address _to, uint256 _value) returns (bool success);

  function approve (address _spender, uint256 _value) returns (bool success);

  function allowance (address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  event Approval (address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
  uint256 constant private MAX_UINT256 =
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  function safeAdd (uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

  function safeSub (uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

  function safeMul (uint256 x, uint256 y)  constant internal  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
  
  
   function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  
}


contract AbstractToken is Token, SafeMath {

  function AbstractToken () {
    // Do nothing
  }
 
  function balanceOf (address _owner) constant returns (uint256 balance) {
    return accounts [_owner];
  }

  function transfer (address _to, uint256 _value) returns (bool success) {
    if (accounts [msg.sender] < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

  function transferFrom (address _from, address _to, uint256 _value)  returns (bool success) {
    if (allowances [_from][msg.sender] < _value) return false;
    if (accounts [_from] < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (allowances [_from][msg.sender], _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (_from, _to, _value);
    return true;
  }

 
  function approve (address _spender, uint256 _value) returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);
    return true;
  }

  
  function allowance (address _owner, address _spender) constant
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

  /**
   * Mapping from addresses of token holders to the numbers of tokens belonging
   * to these token holders.
   */
  mapping (address => uint256) accounts;

  /**
   * Mapping from addresses of token holders to the mapping of addresses of
   * spenders to the allowances set by these token holders to these spenders.
   */
  mapping (address => mapping (address => uint256)) private allowances;
}


contract TerraEcoToken is AbstractToken {
    
     address public owner;
     
     uint256 tokenCount = 0;
     
     bool frozen = false;
     
     uint256 constant MAX_TOKEN_COUNT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
     
    uint public constant _decimals = (10**8);
     
    modifier onlyOwner() {
	    require(owner == msg.sender);
	    _;
	}
     
    function TerraEcoToken() {
         owner = msg.sender;
         createTokens(200 * (10**14));
     }
     
    function totalSupply () constant returns (uint256 _totalSupply) {
        return tokenCount;
     }
     
    function name () constant returns (string result) {
            return "TerraEcoToken";
    }
	
    function symbol () constant returns (string result) {
            return "TET";
    }
	
    function decimals () constant returns (uint result) {
        return 8;
    }
    
    function transfer (address _to, uint256 _value) returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

  
  function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

  
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

  function burnTokens (uint256 _value) returns (bool success) {
    if (_value > accounts [msg.sender]) return false;
    else if (_value > 0) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      tokenCount = safeSub (tokenCount, _value);
      return true;
    } else return true;
  }


  function createTokens (uint256 _value) returns (bool success) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value > safeSub (MAX_TOKEN_COUNT, tokenCount)) return false;
      accounts [msg.sender] = safeAdd (accounts [msg.sender], _value);
      tokenCount = safeAdd (tokenCount, _value);
    }

    return true;
  }


  function setOwner (address _newOwner) {
    require (msg.sender == owner);

    owner = _newOwner;
  }

  function freezeTransfers () {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;
      Freeze ();
    }
  }


  function unfreezeTransfers () {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;
      Unfreeze ();
    }
  }

  event Freeze ();

  event Unfreeze ();

}


contract TokenSale is TerraEcoToken  {
 
    enum State { ICO_FIRST, ICO_SECOND, STOPPED, CLOSED }
    
    // 0 , 1 , 2 , 3 
    
    State public currentState = State.ICO_FIRST;

    uint public tokenPrice = 250000000000000; // wei , 0.00025 eth , 0.12 usd
    uint public _minAmount = 0.025 ether;
	
    address public beneficiary;
	
    uint256 public totalSold = 0;

    uint256 private _hardcap = 30000 ether;
    uint256 private _softcap = 3750 ether;
	
    bool private _allowedTransfers = true;
	
    modifier minAmount() {
        require(msg.value >= _minAmount);
        _;
    }
    
    modifier saleIsOn() {
        require(currentState != State.STOPPED && currentState != State.CLOSED);
        _;
    }
    
    function TokenSale() {
        owner = msg.sender;
        beneficiary = msg.sender;
    }

    function setState(State _newState) public onlyOwner {
        require(currentState != State.CLOSED);
        currentState = _newState;
    }

    function setMinAmount(uint _new) public onlyOwner {

        _minAmount = _new;

    }

    function allowTransfers() public onlyOwner {
            _allowedTransfers = true;		
    }

    function stopTransfers() public onlyOwner {
        
            _allowedTransfers = false;
            
    }

    function stopSale() public onlyOwner {
        
        currentState = State.CLOSED;
        
    }
	
    function setBeneficiaryAddress(address _new) public onlyOwner {
        
        beneficiary = _new;
        
    }


    function transferPayable(address _address, uint _amount) private returns (bool) {

        accounts[_address] = safeAdd(accounts[_address], _amount);
        accounts[owner] = safeSub(accounts[owner], _amount);

        totalSold = safeAdd(totalSold, _amount);


        return true;

    }
	
	
    function getTokens() public saleIsOn() minAmount() payable {


        uint tokens = get_tokens_count(msg.value);
        require(transferPayable(msg.sender , tokens));
        if(_allowedTransfers) { beneficiary.transfer(msg.value); }

    }

	
    function get_tokens_count(uint _amount) private returns (uint) {

         uint currentPrice = tokenPrice;
         uint tokens = safeDiv( safeMul(_amount, _decimals), currentPrice ) ;
         tokens = safeAdd(tokens, get_bounty_count(tokens));
         return tokens;

    }
	
	
    function get_bounty_count(uint _tokens) private returns (uint) {

        uint bonuses = 0;


        if(currentState == State.ICO_FIRST) {
             bonuses = _tokens * 30 / 100;
        }

        if(currentState == State.ICO_SECOND) {
             bonuses = _tokens * 30 / 100;
        }

        return bonuses;

    }
	
    function() external payable {
      getTokens();
    }
	
    
}