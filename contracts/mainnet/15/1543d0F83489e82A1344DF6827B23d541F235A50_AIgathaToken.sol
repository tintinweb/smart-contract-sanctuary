pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title tokenRecipient
 * @dev An interface capable of calling `receiveApproval`, which is used by `approveAndCall` to notify the contract from this interface
 */
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


/**
 * @title TokenERC20
 * @author Jun-You Liu, Ping Chen
 * @dev A simple ERC20 standard token with burnable function
 */
contract TokenERC20 {
  using SafeMath for uint256;

  uint256 public totalSupply;
  bool public transferable;

  // This creates an array with all balances
  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowed;

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address _owner) view public returns(uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) view public returns(uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Basic transfer of all transfer-related functions
   * @param _from The address of sender
   * @param _to The address of recipient
   * @param _value The amount sender want to transfer to recipient
   */
  function _transfer(address _from, address _to, uint _value) internal {
  	require(transferable);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer( _from, _to, _value);
  }

  /**
   * @notice Transfer tokens
   * @dev Send `_value` tokens to `_to` from your account
   * @param _to The address of the recipient
   * @param _value The amount to send
   * @return True if the transfer is done without error
   */
  function transfer(address _to, uint256 _value) public returns(bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @notice Transfer tokens from other address
   * @dev Send `_value` tokens to `_to` on behalf of `_from`
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value The amount to send
   * @return True if the transfer is done without error
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  /**
   * @notice Set allowance for other address
   * @dev Allows `_spender` to spend no more than `_value` tokens on your behalf
   * @param _spender The address authorized to spend
   * @param _value the max amount they can spend
   * @return True if the approval is done without error
   */
  function approve(address _spender, uint256 _value) public returns(bool) {
    // Avoid the front-running attack
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @notice Set allowance for other address and notify
   * @dev Allows contract `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
   * @param _spender The contract address authorized to spend
   * @param _value the max amount they can spend
   * @param _extraData some extra information to send to the approved contract
   * @return True if it is done without error
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
    return false;
  }

  /**
   * @notice Destroy tokens
   * @dev Remove `_value` tokens from the system irreversibly
   * @param _value The amount of money will be burned
   * @return True if `_value` is burned successfully
   */
  function burn(uint256 _value) public returns(bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

  /**
   * @notice Destroy tokens from other account
   * @dev Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   * @param _from The address of the sender
   * @param _value The amount of money will be burned
   * @return True if `_value` is burned successfully
   */
  function burnFrom(address _from, uint256 _value) public returns(bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_from, _value);
    return true;
  }
}


/**
 * @title AIgathaToken
 * @author Jun-You Liu, Ping Chen, (auditors Hans Lin, Luka Chen)
 * @dev The AIgatha Token which is comply with burnable erc20 standard, referred to Cobinhood token contract: https://etherscan.io/address/0xb2f7eb1f2c37645be61d73953035360e768d81e6#code
 */
contract AIgathaToken is TokenERC20, Ownable {
  using SafeMath for uint256;

  // Token Info.
  string public constant name = "AIgatha Token";
  string public constant symbol = "ATH";
  uint8 public constant decimals = 18;

  // Sales period.
  uint256 public startDate;
  uint256 public endDate;

  // Token Cap for each rounds
  uint256 public saleCap;

  // Address where funds are collected.
  address public wallet;

  // Amount of raised money in wei.
  uint256 public weiRaised;

  // Threshold of sold amount
  uint256 public threshold;

  // Whether in the extended period
  bool public extended;

  // Event
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
  event PreICOTokenPushed(address indexed buyer, uint256 amount);
  event UserIDChanged(address owner, bytes32 user_id);

  /**
   * @dev Constructor of Aigatha Token
   * @param _wallet The address where funds are collected
   * @param _saleCap The token cap in public round
   * @param _totalSupply The total amount of token
   * @param _threshold The percentage of selling amount need to achieve at least e.g. 40% -> _threshold = 40
   * @param _start The start date in seconds
   * @param _end The end date in seconds
   */
  function AIgathaToken(address _wallet, uint256 _saleCap, uint256 _totalSupply, uint256 _threshold, uint256 _start, uint256 _end) public {
    wallet = _wallet;
    saleCap = _saleCap * (10 ** uint256(decimals));
    totalSupply = _totalSupply * (10 ** uint256(decimals));
    startDate = _start;
    endDate = _end;

    threshold = _threshold * totalSupply / 2 / 100;
    balances[0xbeef] = saleCap;
    balances[wallet] = totalSupply.sub(saleCap);
  }

  function supply() internal view returns (uint256) {
    return balances[0xbeef];
  }

  function saleActive() public view returns (bool) {
    return (now >= startDate &&
            now <= endDate && supply() > 0);
  }

  function extendSaleTime() onlyOwner public {
    require(!saleActive());
    require(!extended);
    require((saleCap-supply()) < threshold); //check
    extended = true;
    endDate += 60 days;
  }

  /**
   * @dev Get the rate of exchange according to the purchase date
   * @param at The date converted into seconds
   * @return The corresponding rate
   */
  function getRateAt(uint256 at) public view returns (uint256) {
    if (at < startDate) {
      return 0;
    }
    else if (at < (startDate + 15 days)) { //check
      return 10500;
    }
    else {
      return 10000;
    }
  }

  /**
   * @dev Fallback function can be used to buy tokens
   */
  function () payable public{
    buyTokens(msg.sender, msg.value);
  }

  /**
   * @dev For pushing pre-ICO records
   * @param buyer The address of buyer in pre-ICO
   * @param amount The amount of token bought
   */
  function push(address buyer, uint256 amount) onlyOwner public {
    require(balances[wallet] >= amount);
    balances[wallet] = balances[wallet].sub(amount);
    balances[buyer] = balances[buyer].add(amount);
    emit PreICOTokenPushed(buyer, amount);
  }

  /**
   * @dev Buy tokens
   * @param sender The address of buyer
   * @param value The amount of token bought
   */
  function buyTokens(address sender, uint256 value) internal {
    require(saleActive());

    uint256 weiAmount = value;
    uint256 updatedWeiRaised = weiRaised.add(weiAmount);

    // Calculate token amount to be purchased
    uint256 actualRate = getRateAt(now);
    uint256 amount = weiAmount.mul(actualRate);

    // We have enough token to sale
    require(supply() >= amount);

    // Transfer
    balances[0xbeef] = balances[0xbeef].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit TokenPurchase(sender, weiAmount, amount);

    // Update state.
    weiRaised = updatedWeiRaised;
  }

  /**
   * @dev Withdraw all ether in this contract back to the wallet
   */
  function withdraw() onlyOwner public {
    wallet.transfer(address(this).balance);
  }

  /**
   * @dev Collect all the remain token which is unsold after the selling period and make this token can be tranferred
   */
  function finalize() onlyOwner public {
    require(!saleActive());
    balances[wallet] = balances[wallet].add(balances[0xbeef]);
    balances[0xbeef] = 0;
    transferable = true;
  }
}