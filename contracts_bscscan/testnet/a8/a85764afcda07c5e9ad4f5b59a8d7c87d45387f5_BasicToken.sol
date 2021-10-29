/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

/**
 *Submitted for verification at Etherscan.io on 2018-10-27
*/

pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address previousOwner,
    address newOwner
  );

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == address(this));
    _;
  }
  
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause(bool isPause);

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause(paused);
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Pause(paused);
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  
  struct Purchase {
    uint unlockTokens;
    uint unlockDate;
  }
  mapping(address => Purchase[]) balancesLock;

  uint256 totalSupply_;

  address public rubusBlackAddress;
  uint256 public priceEthPerToken;
  uint256 public depositCommission;
  uint256 public withdrawCommission;
  uint256 public investCommission;
  address public depositWallet;
  address public withdrawWallet;
  address public investWallet;
  bool public lock;
  uint256 public minimalEthers;
  uint256 public lockTokensPercent;
  uint256 public lockTimestamp;
  event Deposit(address indexed buyer, uint256 weiAmount, uint256 tokensAmount, uint256 tokenPrice, uint256 commission);
  event Withdraw(address indexed buyer, uint256 weiAmount, uint256 tokensAmount, uint256 tokenPrice, uint256 commission);

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value <= checkVesting(msg.sender));

    if (_to == rubusBlackAddress) {
      require(!lock);
      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);
      require(weiAmount <= uint256(address(this).balance));
      
      totalSupply_ = totalSupply_.sub(_value);
      msg.sender.transfer(weiAmount);
      withdrawWallet.transfer(weiAmount.mul(uint256(100).sub(withdrawCommission)).div(100));
      
      emit Withdraw(msg.sender, weiAmount, _value, priceEthPerToken, withdrawCommission);
    } else {
      balances[_to] = balances[_to].add(_value);
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function getPurchases(address sender, uint index) public view returns(uint, uint) {
    return (balancesLock[sender][index].unlockTokens, balancesLock[sender][index].unlockDate);
  }
  
  function checkVesting(address sender) public view returns (uint256) {
    uint256 availableTokens = balances[sender];

    if (balancesLock[sender].length != 0) {
      for (uint i = 0; i < balancesLock[sender].length; i++) {
        (uint lockTokens, uint lockTime) = getPurchases(sender, i);
        if (lockTime >= now) {
          availableTokens = availableTokens.sub(lockTokens);
        }
      }
    }
    
    return availableTokens;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return checkVesting(_owner);
  }
  
  function balanceOfUnlockTokens(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_value <= checkVesting(_from));

    if (_to == rubusBlackAddress) {
      require(!lock);
      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);
      require(weiAmount <= uint256(address(this).balance));
      
      totalSupply_ = totalSupply_.sub(_value);
      msg.sender.transfer(weiAmount);
      withdrawWallet.transfer(weiAmount.mul(uint256(100).sub(withdrawCommission)).div(100));
      
      emit Withdraw(msg.sender, weiAmount, _value, priceEthPerToken, withdrawCommission);
    } else {
      balances[_to] = balances[_to].add(_value);
    }

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract RubusFundBlackToken is StandardToken {

  string constant public name = "Rubus Fund Black Token";
  uint256 constant public decimals = 18;
  string constant public symbol = "RTB";

  event Lock(bool lockStatus);
  event DeleteTokens(address indexed user, uint256 tokensAmount);
  event AddTokens(address indexed user, uint256 tokensAmount, uint256 _price);
  event NewTokenPrice(uint256 tokenPrice);
  event GetWei(uint256 weiAmount);
  event AddWei(uint256 weiAmount);
  
  event DepositCommission(uint256 deposit);
  event InvestCommission(uint256 invest);
  event WithdrawCommission(uint256 withdraw);
  
  event DepositWallet(address deposit);
  event InvestWallet(address invest);
  event WithdrawWallet(address withdraw);

  constructor() public {
    rubusBlackAddress = address(this);
    setNewPrice(33333);
    lockUp(false);
    newDepositCommission(100);
    newInvestCommission(80);
    newWithdrawCommission(100);
    newMinimalEthers(500000000000000000);
    newTokenUnlockPercent(100);
    newLockTimestamp(2160000);
    newDepositWallet(0x73D5f035B8CB58b4aF065d6cE49fC8E7288536F3);
    newInvestWallet(0xf0EF10870308013903bd6Dc8f86E7a7EAF1a86Ab);
    newWithdraWallet(0x7c4C8b371d4348f7A1fd2e76f05aa60846b442DD);
  }
  
  function _lockPaymentTokens(address sender, uint _amount, uint _date) internal {
    balancesLock[sender].push(Purchase(_amount, _date));
  }

  function priceOf() external view returns(uint256) {
    return priceEthPerToken;
  }

  function () payable external whenNotPaused {
    require(msg.value >= minimalEthers);
    uint256 tokens = msg.value.mul(depositCommission).mul(priceEthPerToken).div(10000);
    
    totalSupply_ = totalSupply_.add(tokens);
    uint256 lockTokens = tokens.mul(100).div(lockTokensPercent);
    
    _lockPaymentTokens(msg.sender, lockTokens, now.add(lockTimestamp));
    
    balances[msg.sender] = balances[msg.sender].add(tokens);

    investWallet.transfer(msg.value.mul(investCommission).div(100));
    depositWallet.transfer(msg.value.mul(uint256(100).sub(depositCommission)).div(100)); 
    
    emit Transfer(rubusBlackAddress, msg.sender, tokens);
    emit Deposit(msg.sender, msg.value, tokens, priceEthPerToken, depositCommission);
  }

  function getWei(uint256 weiAmount) external onlyOwner {
    owner.transfer(weiAmount);
    emit GetWei(weiAmount);
  }

  function addEther() payable external onlyOwner {
    emit AddWei(msg.value);
  }

  function airdrop(address[] receiver, uint256[] amount) external onlyOwner {
    require(receiver.length > 0 && receiver.length == amount.length);
    
    for(uint256 i = 0; i < receiver.length; i++) {
      uint256 tokens = amount[i];
      totalSupply_ = totalSupply_.add(tokens);
      balances[receiver[i]] = balances[receiver[i]].add(tokens);
      emit Transfer(address(this), receiver[i], tokens);
      emit AddTokens(receiver[i], tokens, priceEthPerToken);
    }
  }
  
  function deleteInvestorTokens(address[] user, uint256[] amount) external onlyOwner {
    require(user.length > 0 && user.length == amount.length);
    
    for(uint256 i = 0; i < user.length; i++) {
      uint256 tokens = amount[i];
      require(tokens <= balances[user[i]]);
      totalSupply_ = totalSupply_.sub(tokens);
      balances[user[i]] = balances[user[i]].sub(tokens);
      emit Transfer(user[i], address(this), tokens);
      emit DeleteTokens(user[i], tokens);
    }
  }
  
  function setNewPrice(uint256 _ethPerToken) public onlyOwner {
    priceEthPerToken = _ethPerToken;
    emit NewTokenPrice(priceEthPerToken);
  }

  function newDepositCommission(uint256 _newDepositCommission) public onlyOwner {
    depositCommission = _newDepositCommission;
    emit DepositCommission(depositCommission);
  }
  
  function newInvestCommission(uint256 _newInvestCommission) public onlyOwner {
    investCommission = _newInvestCommission;
    emit InvestCommission(investCommission);
  }
  
  function newWithdrawCommission(uint256 _newWithdrawCommission) public onlyOwner {
    withdrawCommission = _newWithdrawCommission;
    emit WithdrawCommission(withdrawCommission);
  }
  
  function newDepositWallet(address _depositWallet) public onlyOwner {
    depositWallet = _depositWallet;
    emit DepositWallet(depositWallet);
  }
  
  function newInvestWallet(address _investWallet) public onlyOwner {
    investWallet = _investWallet;
    emit InvestWallet(investWallet);
  }
  
  function newWithdraWallet(address _withdrawWallet) public onlyOwner {
    withdrawWallet = _withdrawWallet;
    emit WithdrawWallet(withdrawWallet);
  }

  function lockUp(bool _lock) public onlyOwner {
    lock = _lock;
    emit Lock(lock);
  }
  
  function newMinimalEthers(uint256 _weiAMount) public onlyOwner {
    minimalEthers = _weiAMount;
  }
  
  function newTokenUnlockPercent(uint256 _lockTokensPercent) public onlyOwner {
    lockTokensPercent = _lockTokensPercent;
  }
  
  function newLockTimestamp(uint256 _lockTimestamp) public onlyOwner {
    lockTimestamp = _lockTimestamp;
  }
}