pragma solidity ^0.5.0;
import "./include/PausableToken.sol";
import "./include/MintableToken.sol";
import "./include/BurnableToken.sol";

contract AGold is PausableToken, MintableToken, BurnableToken {
  // public variables
  string public name = "aGold";
  string public symbol = "AoE";
  uint8 public decimals = 0;
  uint256 public maxTX = 75000; //75.000 max TX size

  address public mktWallet_;
  uint256 public mktFee_;
  address public devWallet_;
  uint256 public devFee_;
  address public optWallet_;
  uint256 public optFee_;

  address public preSaleWallet_;
  address public liquidityWallet_;

  mapping(address => bool) internal blockedAddresses_;

  constructor() public {
    //aGold - Total Supply
    //totalSupply_ = 15000000 * (10**uint256(decimals));

    //Initial Setup
    devWallet_ = 0xf77609882FB9e2F4485D34fF7228F795727110AC;
    devFee_ = 4;
    mktWallet_ = 0x079caB2439f81d22FB1977B32cD67d102a931e4f;
    mktFee_ = 4;
    optWallet_ = 0x000000000000000000000000000000000000dEaD;
    optFee_ = 0;

    preSaleWallet_ = 0xb9C68AB3Ca4dC4d4636BAB38fa320C191b6cA6A5;
    liquidityWallet_ = 0x1e9138048d12BB89f66834948b7e77CA6885a668;

    //Distribution
    mint(preSaleWallet_, 3750000); //25% > Presale Wallet
    mint(devWallet_, 750000); //5% > devWallet
    mint(address(this), 6750000); //45% Play2Earn
    mint(liquidityWallet_, 3750000); //25% > Liquidity Wallet to Liquidity Pair
  }

  function queryBotBlockedAddress(
    address query
  ) public view returns (bool){
    return blockedAddresses_[query];
  }

  function blockBotAddress(
    address add, 
    bool status
  ) public onlyOwner returns (bool){
    blockedAddresses_[add] = status;
  }

  function updateWallets(
    address devWallet, 
    uint256 devFee, 
    address mktWallet, 
    uint256 mktFee, 
    address optWallet, 
    uint256 optFee
  ) public onlyOwner returns (bool){
    require(mktWallet != address(0), "Can't set zero account wallet");
    require(devWallet != address(0), "Can't set zero account wallet");
    devWallet_ = devWallet;
    devFee_ = devFee;
    mktWallet_ = mktWallet;
    mktFee_ = mktFee;
    optWallet_ = optWallet;
    optFee_ = optFee;

    return true;
  }
  
  //address private
  function transfer(
    address _to, 
    uint256 _value
  ) public returns (bool) {
    require(_to != address(0), "Can't transfer to zero account"); //Not burn address
    require(blockedAddresses_[_to] != true, "Destination address is blocked. Contact us for help");
    require(blockedAddresses_[address(msg.sender)] != true, "Your wallet is blocked. Contact us for help");
    require(_value <= balances[msg.sender], "Not enough balance");
    require(_value <= maxTX, "Max TX can't be more than 0,5% of Total Supply");

    uint256 _feeMkt = (mktFee_ * _value).div(100);
    uint256 _feeDev = (devFee_ * _value).div(100);
    uint256 _aaf = _value.sub(_feeMkt).sub(_feeDev);

    //Marketing Fees
    balances[msg.sender] = balances[msg.sender].sub(_feeMkt);
    balances[mktWallet_] = balances[mktWallet_].add(_feeMkt);
    emit Transfer(msg.sender, mktWallet_, _feeMkt);

    //Developers Fees
    balances[msg.sender] = balances[msg.sender].sub(_feeDev);
    balances[devWallet_] = balances[devWallet_].add(_feeDev);
    emit Transfer(msg.sender, devWallet_, _feeDev);

    //Final transfer
    balances[msg.sender] = balances[msg.sender].sub(_aaf);
    balances[_to] = balances[_to].add(_aaf);
    emit Transfer(msg.sender, _to, _aaf);

    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    require(_to != address(0), "You can't transfer to zero address");
    require(blockedAddresses_[_to] != true, "Destination address is blocked. Contact us for help");
    require(blockedAddresses_[address(msg.sender)] != true, "Your wallet is blocked. Contact us for help");
    require(_value <= balances[_from], "Insufficient Balance");
    require(_value <= allowed[_from][msg.sender], "Not allowed to spend this amount");
    require(_value <= maxTX, "Max TX can't be more than 0,5% of Total Supply");

    uint256 _feeMkt = (mktFee_ * _value).div(100);
    uint256 _feeDev = (devFee_ * _value).div(100);
    uint256 _aaf = _value.sub(_feeMkt).sub(_feeDev);

    //Marketing Fees
    balances[_from] = balances[_from].sub(_feeMkt);
    balances[mktWallet_] = balances[mktWallet_].add(_feeMkt);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_feeMkt);
    emit Transfer(_from, mktWallet_, _feeMkt);

    //Developers Fees
    balances[_from] = balances[_from].sub(_feeDev);
    balances[devWallet_] = balances[devWallet_].add(_feeDev);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_feeDev);
    emit Transfer(_from, devWallet_, _feeDev);

    //Final transfer
    balances[_from] = balances[_from].sub(_aaf);
    balances[_to] = balances[_to].add(_aaf);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_aaf);
    emit Transfer(_from, _to, _aaf);

    return true;
  }

  function() external payable {
    revert("Contract build failed");
  }
}

pragma solidity ^0.5.0;
import "./StandardToken.sol";

contract BurnableToken is StandardToken {

  // @notice An address for the transfer event where the burned tokens are transferred in a faux Transfer event
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  /** How many tokens we burned */
  event Burned(address burner, uint burnedAmount);

  /**
   * Burn extra tokens from a balance.
   *
   */
  function burn(uint burnAmount) public {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply_ = totalSupply_.sub(burnAmount);
    emit Burned(burner, burnAmount);

    // Inform the blockchain explores that track the
    // balances only by a transfer event that the balance in this
    // address has decreased
    emit Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

pragma solidity ^0.5.0;
/**
 * @title ERC20BasicS

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
import "./SafeMath.sol";

contract ERC20Basic {
  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
   * @dev total number of tokens in existence
   */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "You can't transfer to zero address");
    require(_value <= balances[msg.sender], "You need more tokens");

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public
    view
    returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
import "./Ownable.sol";
import "./StandardToken.sol";
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);

  //bool public mintingFinished = false;
  uint256 public mintTotal;

  modifier canMint() {
  //  require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner, "You need mint permission");
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount)
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    //uint256 tmpTotal = mintTotal.add(_amount);
    //require(tmpTotal <= totalSupply_);
    mintTotal = mintTotal.add(_amount);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
pragma solidity ^0.5.0;
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can do this");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Owner can't be zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

pragma solidity ^0.5.0;
/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
 /**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
 import "./Ownable.sol";
 import "./StandardToken.sol";
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused, "The contract is not paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused, "The contract is paused");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint256 _value)
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value)
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint256 _addedValue)
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

pragma solidity ^0.5.0;

// based on https://github.com/OpenZeppelin/openzeppelin-solidity/tree/v1.10.0
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

pragma solidity ^0.5.0;
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
 import "./ERC20Basic.sol";
contract StandardToken is ERC20, BasicToken {
  mapping(address => mapping(address => uint256)) internal allowed;

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
  ) public returns (bool) {
    require(_to != address(0), "You can't transfer to zero address");
    require(_value <= balances[_from], "Insufficient Balance");
    require(_value <= allowed[_from][msg.sender], "Not allowed to spend this amount");

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
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
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint256 _addedValue)
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue)
    );
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint256 _subtractedValue)
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

