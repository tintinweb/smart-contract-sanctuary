pragma solidity ^0.4.18;

contract EIP20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract STTR is EIP20Interface {
    
    using SafeMath for uint;
    using SafeMath for uint256;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    address public wallet;
    address public contractOwner;
    
    uint public price = 0.0000000000995 ether;
    
    bool public isSalePaused = false;
    bool public transfersPaused = false;
    

    function STTR(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        address _wallet,
        address _contractOwner
        
    ) public {
        balances[msg.sender] = _initialAmount;             
        totalSupply = _initialAmount;                   
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;     
        wallet = _wallet;
        contractOwner = _contractOwner;
        
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] =  allowed[_from][msg.sender].sub(_value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
    
   

    
      modifier onlyWhileOpen {
        require(!isSalePaused);
        _;
    }
       modifier onlyOwner() {
        require(contractOwner == msg.sender);
        _;
    }
    
   
    function () public payable onlyWhileOpen{
        require(msg.value>0);
        require(msg.value<=200 ether);
        require(msg.sender != address(0));
        
        uint toMint = msg.value/price;
        totalSupply += toMint;
        balances[msg.sender] = balances[msg.sender].add(toMint);
        wallet.transfer(msg.value);
        Transfer(0, msg.sender, toMint);
        
    }
    
   
    function pauseSale()
        public
        onlyOwner
        returns (bool) {
            isSalePaused = true;
            return true;
        }

    function restartSale()
        public
        onlyOwner
        returns (bool) {
            isSalePaused = false;
            return true;
        }
        
    function setPrice(uint newPrice)
        public
        onlyOwner {
            price = newPrice;
        }
   
      modifier whenNotPaused() {
    require(!transfersPaused);
    _;
  }
  
  modifier whenPaused() {
    require(transfersPaused);
    _;
  }

  function pauseTransfers() 
    onlyOwner 
    whenNotPaused 
    public {
    transfersPaused = true;
  }

  function unPauseTransfers() 
    onlyOwner 
    whenPaused 
    public {
    transfersPaused = false;
  }
     function withdrawTokens(address where) onlyOwner public returns (bool) {
        uint256 Amount = balances[address(this)];
        balances[address(this)] = balances[address(this)].sub(Amount);
        balances[where] = balances[where].add(Amount);
        Transfer(address(this), where, Amount);
    }

    
}