pragma solidity ^0.4.18;

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: contracts/math/SafeMath.sol

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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/StagedCrowdsale.sol

contract StagedCrowdsale is Pausable {

  using SafeMath for uint;

  struct Stage {
    uint hardcap;
    uint price;
    uint invested;
    uint closed;
  }

  uint public start;

  uint public period;

  uint public totalHardcap;

  uint public totalInvested;

  Stage[] public stages;

  function stagesCount() public constant returns(uint) {
    return stages.length;
  }

  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function addStage(uint hardcap, uint price) public onlyOwner {
    require(hardcap > 0 && price > 0);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    stages.push(stage);
    totalHardcap = totalHardcap.add(stage.hardcap);
  }

  function removeStage(uint8 number) public onlyOwner {
    require(number >= 0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);
    delete stages[number];
    for (uint i = number; i < stages.length - 1; i++) {
      stages[i] = stages[i+1];
    }
    stages.length--;
  }

  function changeStage(uint8 number, uint hardcap, uint price) public onlyOwner {
    require(number >= 0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);
    stage.hardcap = hardcap.mul(1 ether);
    stage.price = price;
    totalHardcap = totalHardcap.add(stage.hardcap);
  }

  function insertStage(uint8 numberAfter, uint hardcap, uint price) public onlyOwner {
    require(numberAfter < stages.length);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    totalHardcap = totalHardcap.add(stage.hardcap);
    stages.length++;
    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }
    stages[numberAfter + 1] = stage;
  }

  function clearStages() public onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    totalHardcap = 0;
  }

  function lastSaleDate() public constant returns(uint) {
    return start + period * 1 days;
  }

  modifier saleIsOn() {
    require(stages.length > 0 && now >= start && now < lastSaleDate());
    _;
  }

  modifier isUnderHardcap() {
    require(totalInvested <= totalHardcap);
    _;
  }

  function currentStage() public saleIsOn isUnderHardcap constant returns(uint) {
    for (uint i = 0; i < stages.length; i++) {
      if (stages[i].closed == 0) {
        return i;
      }
    }
    revert();
  }

}

// File: contracts/ReceivingContractCallback.sol

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

// File: contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: contracts/StasyqToken.sol

contract StasyqToken is MintableToken {

  string public constant name = "Stasyq";

  string public constant symbol = "SQOIN";

  uint32 public constant decimals = 18;

  address public saleAgent;

  mapping (address => uint) public locked;

  mapping(address => bool)  public registeredCallbacks;

  modifier canTransfer() {
    require(msg.sender == owner || msg.sender == saleAgent || mintingFinished);
    _;
  }

  modifier onlyOwnerOrSaleAgent() {
    require(msg.sender == owner || msg.sender == saleAgent);
    _;
  }

  function setSaleAgent(address newSaleAgnet) public onlyOwnerOrSaleAgent {
    saleAgent = newSaleAgnet;
  }

  function mint(address _to, uint256 _amount) public onlyOwnerOrSaleAgent canMint returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() public onlyOwnerOrSaleAgent canMint returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
    require(locked[msg.sender] < now);
    return processCallback(super.transfer(_to, _value), msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
    require(locked[_from] < now);
    return processCallback(super.transferFrom(_from, _to, _value), _from, _to, _value);
  }

  function lock(address addr, uint periodInDays) public {
    require(locked[addr] < now && (msg.sender == saleAgent || msg.sender == addr));
    locked[addr] = now.add(periodInDays * 1 days);
  }

  function registerCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = true;
  }

  function deregisterCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = false;
  }

  function processCallback(bool result, address from, address to, uint value) internal returns(bool) {
    if (result && registeredCallbacks[to]) {
      ReceivingContractCallback targetCallback = ReceivingContractCallback(to);
      targetCallback.tokenFallback(from, value);
    }
    return result;
  }

}

// File: contracts/CommonSale.sol

contract CommonSale is StagedCrowdsale {

  address public masterWallet;

  address public slaveWallet;

  address public directMintAgent;

  uint public slaveWalletPercent;

  uint public percentRate = 100;

  uint public minPrice;

  uint public totalTokensMinted;

  StasyqToken public token = StasyqToken(0xF300cC72613D575A4567405C2A07d2AaF182aEBf);

  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }

  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }

  function setMinPrice(uint newMinPrice) public onlyOwner {
    minPrice = newMinPrice;
  }

  function setMasterWallet(address newMasterWallet) public onlyOwner {
    masterWallet = newMasterWallet;
  }

  function setToken(address newToken) public onlyOwner {
    token = StasyqToken(newToken);
  }

  function directMint(address to, uint investedWei) public onlyDirectMintAgentOrOwner saleIsOn {
    mintTokens(to, investedWei);
  }

  function createTokens() public whenNotPaused payable {
    require(msg.value >= minPrice);
    uint masterValue = msg.value.mul(percentRate.sub(slaveWalletPercent)).div(percentRate);
    uint slaveValue = msg.value.sub(masterValue);
    masterWallet.transfer(masterValue);
    slaveWallet.transfer(slaveValue);
    mintTokens(msg.sender, msg.value);
  }

  function mintTokens(address to, uint weiInvested) internal {
    uint stageIndex = currentStage();
    Stage storage stage = stages[stageIndex];
    uint tokens = weiInvested.mul(stage.price);
    token.mint(this, tokens);
    token.transfer(to, tokens);
    totalTokensMinted = totalTokensMinted.add(tokens);
    totalInvested = totalInvested.add(weiInvested);
    stage.invested = stage.invested.add(weiInvested);
    if (stage.invested >= stage.hardcap) {
      stage.closed = now;
    }
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken, address to) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }


}

// File: contracts/ITO.sol

contract ITO is CommonSale {

  address public foundersTokensWalletMaster;
  
  address public foundersTokensWalletSlave;

  address public bountyTokensWallet;

  uint public foundersTokensPercent;

  uint public bountyTokensPercent;

  uint public lockPeriod;

  function ITO() public {
    addStage(2000,14500);
    addStage(2000,14000);
    addStage(2000,13500);
    addStage(2000,13000);
    addStage(2000,12500);
    addStage(2000,12000);
    addStage(2000,11500);
    addStage(2000,11000);
    addStage(2000,10500);
    addStage(2000,10000);
    masterWallet = 0x6715Feb90B78d4d7aD92FbaCA7Fd70481e12f836;
    slaveWallet = 0x8029618Ecb5445B73515d7C51AbB316A91FC7f23;
    slaveWalletPercent = 50;
    foundersTokensWalletMaster = 0x05E87Dc9c075256cB94951e0b35C581b93961885;
    foundersTokensWalletSlave = 0x8029618Ecb5445B73515d7C51AbB316A91FC7f23;
    bountyTokensWallet = 0x6715Feb90B78d4d7aD92FbaCA7Fd70481e12f836;
    start = 1523019600;
    period = 60;
    lockPeriod = 180;
    minPrice = 100000000000000000;
    foundersTokensPercent = 25;
    bountyTokensPercent = 5;
  }

  function setLockPeriod(uint newLockPeriod) public onlyOwner {
    lockPeriod = newLockPeriod;
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner {
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }

  function setFoundersTokensWalletMaster(address newFoundersTokensWalletMaster) public onlyOwner {
    foundersTokensWalletMaster = newFoundersTokensWalletMaster;
  }
  
  function setFoundersTokensWalletSlave(address newFoundersTokensWalletSlave) public onlyOwner {
    foundersTokensWalletSlave = newFoundersTokensWalletSlave;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }
  
  function finishMinting() public whenNotPaused onlyOwner {
    uint summaryTokensPercent = bountyTokensPercent.add(foundersTokensPercent);
    uint mintedTokens = token.totalSupply();
    uint totalSupply = mintedTokens.mul(percentRate).div(percentRate.sub(summaryTokensPercent));
    uint foundersTokens = totalSupply.mul(foundersTokensPercent).div(percentRate);
    uint bountyTokens = totalSupply.mul(bountyTokensPercent).div(percentRate);
    
    uint foundersTokensMaster = foundersTokens.mul(slaveWalletPercent).div(percentRate);
    uint foundersTokensSlave = foundersTokens.mul(percentRate.sub(slaveWalletPercent)).div(percentRate);
    
    token.mint(this, foundersTokensMaster);
    token.transfer(foundersTokensWalletMaster, foundersTokensMaster);
    token.lock(foundersTokensWalletMaster, lockPeriod);
    
    token.mint(this, foundersTokensSlave);
    token.transfer(foundersTokensWalletSlave, foundersTokensSlave);
    token.lock(foundersTokensWalletSlave, lockPeriod);
    
    token.mint(this, bountyTokens);
    token.transfer(bountyTokensWallet, bountyTokens);
    totalTokensMinted = totalTokensMinted.add(foundersTokens).add(bountyTokens);
    token.finishMinting();
  }

}