pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
   
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
 
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

    
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }



}

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract IonicCoin is StandardToken, owned {
	string public constant name = &#39;IonicCoin&#39;;
	string public constant symbol = &#39;INC&#39;;
	uint public constant decimals = 18;
	uint private constant INITIAL_SUPPLY =  50000000 * (10 ** uint256(decimals));
  uint private constant RESERVE =  20000000 * (10 ** uint256(decimals)); 
    // Gathered funds can be withdrawn only to ionicteam address.
  
  uint256 public sellPrice;
  uint256 public buyPrice;
  bool public sellingAccepted = false;
    //1 Ether = 2000 Token
  
  uint256 private constant FREE_TOKEN = 100;

  uint256 private constant RATE_PHASE_1 = 2000;
  uint256 private constant RATE_PHASE_2 = 1500;
  uint256 private constant RATE_PHASE_3 = 1000;
  uint256 private constant RATE_PHASE_4 = 500;
  uint256 private phase = 1;

  struct User{
    address addr;
    uint balance;
    bool claimed;
    bool allowed;
  }
    
  mapping (address => User) users;
	address[] public userAccounts;

	function IonicCoin() {
        owner = msg.sender; 
		totalSupply = INITIAL_SUPPLY + RESERVE;
		balances[msg.sender] = totalSupply;
	}


    // accpet ether
    function () payable {
        createTokens();
    }

    function createTokens() payable {
        uint256 tokens = msg.value.mul(getTokeRate());
        // min - 0.1 ETH
        require(msg.value >= ((1 ether / 1 wei) / 10));
        require(
            msg.value > 0
            && tokens <= totalSupply
        );
        userAccounts.push(msg.sender)-1;
         
        users[msg.sender].addr = msg.sender;
        users[msg.sender].allowed = false;
        users[msg.sender].claimed = false;
        users[msg.sender].balance = tokens;

        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.sub(tokens);
        owner.transfer(msg.value);
    }

    function getUsers() onlyOwner view public returns(address[]){
      return userAccounts;
    }
    
    function getUser(address _address) onlyOwner view public returns(bool,bool, uint){
      return (users[_address].claimed , users[_address].allowed ,users[_address].balance);
    }

    function countUsers() view public returns (uint){
      userAccounts.length;
    }

    function setAllowClaimUser(address _address) onlyOwner public {
        users[_address].allowed = true;
        users[_address].claimed = true;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }


    function sellingAccept(bool value) onlyOwner public {
        sellingAccepted = value;
    }
    
    function setPhase(uint256 value) onlyOwner public {
        phase = value;
    }
    
    function getTokeRate() private
    constant
    returns (uint256 currentPrice) {
        if(phase == 1) return RATE_PHASE_1;
        else if(phase == 2) return RATE_PHASE_2;
        else if(phase == 3) return RATE_PHASE_3;
        else if(phase == 4) return RATE_PHASE_4;
    }
    
    
    function sell(uint256 amount) public {
      require (sellingAccepted == true); // selling accept when ICO is eneded
      require (sellPrice > 0);
      // min - 0.1 ETH
      require(msg.value >= ((1 ether / 1 wei) / 10));
      require(balances[owner] >= amount * sellPrice);      // checks if the contract has enough ether to buy
      transferFrom(msg.sender, owner, amount);           // makes the transfers
      msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    
    }
    
    
    
    function withdrawEther(address ethFundDeposit) public onlyOwner
    { 
        uint256 amount = balances[owner];
        if(amount > 0) 
        {
            ethFundDeposit.transfer(amount);
        }
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require (_to != 0x0); 
        require(
            balances[msg.sender] >= _value
            && _value > 0
        ); 

        if (balances[msg.sender] >= _value && _value > 0) {
            if(totalSupply <= RESERVE){ // run out of token
                return false;
            }
            
            balances[_to] = balances[_to].add(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value); 
            totalSupply = totalSupply.sub(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    require (_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
	  require (_value > 0); 
    require (balances[_from] > _value);                 // Check if the sender has enough
    require (balances[_to] + _value > balances[_to]);  // Check for overflows
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    require (_value <= _allowance);
    
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

    
}