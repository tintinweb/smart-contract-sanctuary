pragma solidity 0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}

contract Ownable {
  address public manager;


  event OwnershipTransferred(address indexed previousManager, address indexed newManager);


  /**
   * @dev The Ownable constructor sets the original `manager` of the contract to the sender
   * account.
   */
   constructor() public payable {
    manager = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the manager.
   */
  modifier onlyManager() {
    require(msg.sender == manager);
    _;
  }


  /**
   * @dev Allows the current manager to transfer control of the contract to a newManager.
   * @param newManager The address to transfer ownership to.
   */
  function transferOwnership(address newManager) onlyManager public {
    require(newManager != address(0));
    emit OwnershipTransferred(manager, newManager);
    manager = newManager;
  }

}

contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Taxi is Ownable,ERC20Interface{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals;
    
    
    //state variables
    string public taxi_driver;
    string public car_dealer;
    uint public contract_balance=0;
    uint256 public fixed_expenses;
    uint256 public participation_fee=1;
 
   
    struct OwnedCar {  
        uint256   CarID;  
    }
    
    struct ProposedCar {  
        uint256  CarID;
        uint256  price; 
        uint256  offer_valid_time;
    }
    
    struct ProposedPurchase{
        uint256 CarID;
        uint256 price;
        uint256 offer_valid_time;
        bool approval_state;
    }
     
    
    mapping(address=>uint256) participants;
    
    mapping(address => uint256) tokenBalances; 
    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public _totalSupply;
    
    //events
     event Receive(uint value);
    
    constructor() public payable {
        manager = msg.sender;
        name  = "Feed";
        symbol = "FEED";
        decimals = 18;
        _totalSupply = 1000000000 * 10 ** uint(decimals);
        tokenBalances[ msg.sender] = _totalSupply;   //Since we divided the token into 10^18 parts
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - tokenBalances[address(0)];
    }
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
    
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
         //checkTokenVesting(msg.sender, tokens);
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    //checkTokenVesting(_from,_value);
    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
    
    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
       allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
       return true;
    }
    
    /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    // my custom functins
    
    function joinFunction() public payable returns(bool success){
        require(msg.value>0);
        require(msg.value>=participation_fee);
        msg.sender.transfer(participation_fee);
        return true; 
        
    }
    
     
    
}