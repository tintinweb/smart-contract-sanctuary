pragma solidity 0.4.15;

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
  function transferFrom(address from, address to, uint256 value) returns (bool);
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
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

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

contract IWWEE is StandardToken, Ownable
{

    string public name = "IW World Exchange Token";
    string public symbol = "IWWEE";

    uint public decimals = 8;
    uint public buyRate = 251;
    uint public sellRate = 251;

    bool public allowBuying = true;
    bool public allowSelling = true;

    uint private INITIAL_SUPPLY = 120*10**14;
    
    function () payable 
    {
        BuyTokens(msg.sender);
    }
    
    function IWWEE()
    {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
    }

    function transferOwnership(address newOwner) 
    onlyOwner
    {
        address oldOwner = owner;
        super.transferOwnership(newOwner);
        OwnerTransfered(oldOwner, newOwner);
    }

    function ChangeBuyRate(uint newRate)
    onlyOwner
    {
        require(newRate > 0);
        uint oldRate = buyRate;
        buyRate = newRate;
        BuyRateChanged(oldRate, newRate);
    }

    function ChangeSellRate(uint newRate)
    onlyOwner
    {
        require(newRate > 0);
        uint oldRate = sellRate;
        sellRate = newRate;
        SellRateChanged(oldRate, newRate);
    }

    function BuyTokens(address beneficiary) 
    OnlyIfBuyingAllowed
    payable 
    {
        require(beneficiary != 0x0);
        require(beneficiary != owner);
        require(msg.value > 0);

        uint weiAmount = msg.value;
        uint etherAmount = WeiToEther(weiAmount);
        
        uint tokens = etherAmount.mul(buyRate);

        balances[beneficiary] = balances[beneficiary].add(tokens);
        balances[owner] = balances[owner].sub(tokens);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function SellTokens(uint amount)
    OnlyIfSellingAllowed
    {
        require(msg.sender != owner);
        require(msg.sender != 0x0);
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        
        balances[owner] = balances[owner].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
    
        uint checkAmount = EtherToWei(amount.div(sellRate));
        if (!msg.sender.send(checkAmount))
            revert();
        else
            TokenSold(msg.sender, amount);
    }

    function RetrieveFunds()
    onlyOwner
    {
        owner.transfer(this.balance);
    }

    function Destroy()
    onlyOwner
    {
        selfdestruct(owner);
    }
    
    function WeiToEther(uint v) internal 
    returns (uint)
    {
        require(v > 0);
        return v.div(1000000000000000000);
    }

    function EtherToWei(uint v) internal
    returns (uint)
    {
      require(v > 0);
      return v.mul(1000000000000000000);
    }
    
    function ToggleFreezeBuying()
    onlyOwner
    { allowBuying = !allowBuying; }

    function ToggleFreezeSelling()
    onlyOwner
    { allowSelling = !allowSelling; }

    modifier OnlyIfBuyingAllowed()
    { require(allowBuying); _; }

    modifier OnlyIfSellingAllowed()
    { require(allowSelling); _; }

    event OwnerTransfered(address oldOwner, address newOwner);

    event BuyRateChanged(uint oldRate, uint newRate);
    event SellRateChanged(uint oldRate, uint newRate);

    event TokenSold(address indexed seller, uint amount);

    event TokenPurchase(
    address indexed purchaser, 
    address indexed beneficiary, 
    uint256 value, 
    uint256 amount);
}