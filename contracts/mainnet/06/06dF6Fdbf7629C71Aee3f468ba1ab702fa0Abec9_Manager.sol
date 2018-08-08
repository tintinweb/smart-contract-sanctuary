pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

contract BBODServiceRegistry is Ownable {

  //1. Manager
  //2. CustodyStorage
  mapping(uint => address) public registry;

    constructor(address _owner) {
        owner = _owner;
    }

  function setServiceRegistryEntry (uint key, address entry) external onlyOwner {
    registry[key] = entry;
  }
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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ManagerInterface {
  function createCustody(address) external {}

  function isExchangeAlive() public pure returns (bool) {}

  function isDailySettlementOnGoing() public pure returns (bool) {}
}

contract Custody {

  using SafeMath for uint;

  BBODServiceRegistry public bbodServiceRegistry;
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor(address _serviceRegistryAddress, address _owner) public {
    bbodServiceRegistry = BBODServiceRegistry(_serviceRegistryAddress);
    owner = _owner;
  }

  function() public payable {}

  modifier liveExchangeOrOwner(address _recipient) {
    var manager = ManagerInterface(bbodServiceRegistry.registry(1));

    if (manager.isExchangeAlive()) {

      require(msg.sender == address(manager));

      if (manager.isDailySettlementOnGoing()) {
        require(_recipient == address(manager), "Only manager can do this when the settlement is ongoing");
      } else {
        require(_recipient == owner);
      }

    } else {
      require(msg.sender == owner, "Only owner can do this when exchange is dead");
    }
    _;
  }

  function withdraw(uint _amount, address _recipient) external liveExchangeOrOwner(_recipient) {
    _recipient.transfer(_amount);
  }

  function transferToken(address _erc20Address, address _recipient, uint _amount)
    external liveExchangeOrOwner(_recipient) {

    ERC20 token = ERC20(_erc20Address);

    token.transfer(_recipient, _amount);
  }

  function transferOwnership(address newOwner) public {
    require(msg.sender == owner, "Only the owner can transfer ownership");
    require(newOwner != address(0));

    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract CustodyStorage {

  BBODServiceRegistry public bbodServiceRegistry;

  mapping(address => bool) public custodiesMap;

  //Number of all custodies in the contract
  uint public custodyCounter = 0;

  address[] public custodiesArray;

  event CustodyRemoved(address indexed custody);

  constructor(address _serviceRegistryAddress) public {
    bbodServiceRegistry = BBODServiceRegistry(_serviceRegistryAddress);
  }

  modifier onlyManager() {
    require(msg.sender == bbodServiceRegistry.registry(1));
    _;
  }

  function addCustody(address _custody) external onlyManager {
    custodiesMap[_custody] = true;
    custodiesArray.push(_custody);
    custodyCounter++;
  }

  function removeCustody(address _custodyAddress, uint _arrayIndex) external onlyManager {
    require(custodiesArray[_arrayIndex] == _custodyAddress);

    if (_arrayIndex == custodyCounter - 1) {
      //Removing last custody
      custodiesMap[_custodyAddress] = false;
      emit CustodyRemoved(_custodyAddress);
      custodyCounter--;
      return;
    }

    custodiesMap[_custodyAddress] = false;
    //Overwriting deleted custody with the last custody in the array
    custodiesArray[_arrayIndex] = custodiesArray[custodyCounter - 1];
    custodyCounter--;

    emit CustodyRemoved(_custodyAddress);
  }
}
contract Insurance is Custody {

  constructor(address _serviceRegistryAddress, address _owner)
  Custody(_serviceRegistryAddress, _owner) public {}

  function useInsurance (uint _amount) external {
    var manager = ManagerInterface(bbodServiceRegistry.registry(1));
    //Only usable for manager during settlement
    require(manager.isDailySettlementOnGoing() && msg.sender == address(manager));

    address(manager).transfer(_amount);
  }
}

contract Manager is Pausable {
using SafeMath for uint;

mapping(address => bool) public ownerAccountsMap;
mapping(address => bool) public exchangeAccountsMap;

//SETTLEMENT PREPARATION####

enum SettlementPhase {
PREPARING, ONGOING, FINISHED
}

enum Cryptocurrency {
ETH, BBD
}

//Initially ready for a settlement
SettlementPhase public currentSettlementPhase = SettlementPhase.FINISHED;

uint public startingFeeBalance = 0;
uint public totalFeeFlows = 0;
uint public startingInsuranceBalance = 0;
uint public totalInsuranceFlows = 0;

uint public lastSettlementStartedTimestamp = 0;
uint public earliestNextSettlementTimestamp = 0;

mapping(uint => mapping(address => bool)) public custodiesServedETH;
mapping(uint => mapping(address => bool)) public custodiesServedBBD;

address public feeAccount;
address public insuranceAccount;
ERC20 public bbdToken;
CustodyStorage public custodyStorage;

address public custodyFactory;
uint public gweiBBDPriceInWei;
uint public lastTimePriceSet;
uint constant public gwei = 1000000000;

uint public maxTimeIntervalHB = 1 weeks;
uint public heartBeat = now;

constructor(address _feeAccount, address _insuranceAccount, address _bbdTokenAddress, address _custodyStorage,
address _serviceRegistryAddress) public {
//Contract creator is the first owner
ownerAccountsMap[msg.sender] = true;
feeAccount = _feeAccount;
insuranceAccount = _insuranceAccount;
bbdToken = ERC20(_bbdTokenAddress);
custodyStorage = CustodyStorage(_custodyStorage);
}

function() public payable {}

function setCustodyFactory(address _custodyFactory) external onlyOwner {
custodyFactory = _custodyFactory;
}

function pause() public onlyExchangeOrOwner {
paused = true;
}

function unpause() public onlyExchangeOrOwner {
paused = false;
}

modifier onlyAllowedInPhase(SettlementPhase _phase) {
require(currentSettlementPhase == _phase, "Not allowed in this phase");
_;
}

modifier onlyOwner() {
require(ownerAccountsMap[msg.sender] == true, "Only an owner can perform this action");
_;
}

modifier onlyExchange() {
require(exchangeAccountsMap[msg.sender] == true, "Only an exchange can perform this action");
_;
}

modifier onlyExchangeOrOwner() {
require(exchangeAccountsMap[msg.sender] == true ||
ownerAccountsMap[msg.sender] == true);
_;
}

function isDailySettlementOnGoing() external view returns (bool) {
return currentSettlementPhase != SettlementPhase.FINISHED;
}

function updateHeartBeat() external whenNotPaused onlyOwner {
heartBeat = now;
}

function isExchangeAlive() external view returns (bool) {
return now - heartBeat < maxTimeIntervalHB;
}

function addOwnerAccount(address _exchangeAccount) external onlyOwner {
ownerAccountsMap[_exchangeAccount] = true;
}

function addExchangeAccount(address _exchangeAccount) external onlyOwner whenNotPaused {
exchangeAccountsMap[_exchangeAccount] = true;
}

function rmExchangeAccount(address _exchangeAccount) external onlyOwner whenNotPaused {
exchangeAccountsMap[_exchangeAccount] = false;
}

function setBBDPrice(uint _priceInWei) external onlyExchangeOrOwner whenNotPaused
onlyAllowedInPhase(SettlementPhase.FINISHED) {
if(gweiBBDPriceInWei == 0) {
gweiBBDPriceInWei = _priceInWei;
} else {
//Max 100% daily increase in price
if(_priceInWei > gweiBBDPriceInWei) {
require(_priceInWei - gweiBBDPriceInWei <= (gweiBBDPriceInWei / 2));
//Max 50% daily decrease in price
} else if(_priceInWei < gweiBBDPriceInWei) {
require(gweiBBDPriceInWei - _priceInWei <= (gweiBBDPriceInWei / 2));
}
gweiBBDPriceInWei = _priceInWei;
}
//Price can only be set once per day
require(now - lastTimePriceSet > 23 hours);

lastTimePriceSet = now;
}

function createCustody(address _custody) external whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) {
require(msg.sender == custodyFactory);
custodyStorage.addCustody(_custody);
}

function removeCustody(address _custodyAddress, uint _arrayIndex) external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.FINISHED) {
custodyStorage.removeCustody(_custodyAddress, _arrayIndex);
}

/// @dev Exchange uses this function to withdraw ether from the contract
/// @param _amount to withdraw
/// @param _recipient to send withdrawn ether to
function withdrawFromManager(uint _amount, address _recipient) external onlyExchangeOrOwner
whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) {
_recipient.transfer(_amount);
}

/// @dev Users use this function to withdraw ether from their custody
/// @param _amount to withdraw
/// @param _custodyAddress to withdraw from
function withdrawFromCustody(uint _amount, address _custodyAddress,address _recipient) external onlyExchangeOrOwner
whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) {
Custody custody = Custody(_custodyAddress);
custody.withdraw(_amount, _recipient);
}

/// @dev Users use this function to withdraw ether from their custody
/// @param _tokenAddress of the ERC20 to withdraw from
/// @param _amount to withdraw
/// @param _custodyAddress to withdraw from
function withdrawTokensFromCustody(address _tokenAddress, uint _amount, address _custodyAddress, address _recipient)
external whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) onlyExchangeOrOwner {
Custody custody = Custody(_custodyAddress);
custody.transferToken(_tokenAddress, _recipient,_amount);
}

//DAILY SETTLEMENT

/// @dev This function prepares the daily settlement - resets all settlement
/// @dev scope storage variables to 0.
function startSettlementPreparation() external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.FINISHED) {
require(now > earliestNextSettlementTimestamp, "A settlement can happen once per day");
require(gweiBBDPriceInWei > 0, "BBD Price cannot be 0 during settlement");

lastSettlementStartedTimestamp = now;
totalFeeFlows = 0;
totalInsuranceFlows = 0;

currentSettlementPhase = SettlementPhase.ONGOING;


startingFeeBalance = feeAccount.balance +
((bbdToken.balanceOf(feeAccount) * gweiBBDPriceInWei) / gwei);

startingInsuranceBalance = insuranceAccount.balance;
}

/// @dev This function is used to process a batch of net eth flows, two arrays
/// @dev are pairs of custody addresses and the balance changes that should
/// @dev be executed. Transaction will revert if exchange rules are violated.
/// @param _custodies flow addresses
/// @param _flows flow balance changes (can be negative or positive)
/// @param _fee calculated and deducted from all batch flows
/// @param _insurance to be used
function settleETHBatch(address[] _custodies, int[] _flows, uint _fee, uint _insurance) external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.ONGOING) {

require(_custodies.length == _flows.length);

uint preBatchBalance = address(this).balance;

if(_insurance > 0) {
Insurance(insuranceAccount).useInsurance(_insurance);
}

for (uint flowIndex = 0; flowIndex < _flows.length; flowIndex++) {

//Every custody can be served ETH once during settlement
require(custodiesServedETH[lastSettlementStartedTimestamp][_custodies[flowIndex]] == false);

//All addresses must be custodies
require(custodyStorage.custodiesMap(_custodies[flowIndex]));

if (_flows[flowIndex] > 0) {
//10% rule
var outboundFlow = uint(_flows[flowIndex]);

//100% rule exception threshold
if(outboundFlow > 10 ether) {
//100% rule
require(getTotalBalanceFor(_custodies[flowIndex]) >= outboundFlow);
}

_custodies[flowIndex].transfer(uint(_flows[flowIndex]));

} else if (_flows[flowIndex] < 0) {
Custody custody = Custody(_custodies[flowIndex]);

custody.withdraw(uint(-_flows[flowIndex]), address(this));
}

custodiesServedETH[lastSettlementStartedTimestamp][_custodies[flowIndex]] = true;
}

if(_fee > 0) {
feeAccount.transfer(_fee);
totalFeeFlows = totalFeeFlows + _fee;
//100% rule for fee account
require(totalFeeFlows <= startingFeeBalance);
}

uint postBatchBalance = address(this).balance;

//Zero-sum guaranteed for ever batch
if(address(this).balance > preBatchBalance) {
uint leftovers = address(this).balance - preBatchBalance;
insuranceAccount.transfer(leftovers);
totalInsuranceFlows += leftovers;
//100% rule for insurance account
require(totalInsuranceFlows <= startingInsuranceBalance);
}
}

/// @dev This function is used to process a batch of net bbd flows, two arrays
/// @dev are pairs of custody addresses and the balance changes that should
/// @dev be executed. Transaction will revert if exchange rules are violated.
/// @param _custodies flow addresses
/// @param _flows flow balance changes (can be negative or positive)
/// @param _fee calculated and deducted from all batch flows
function settleBBDBatch(address[] _custodies, int[] _flows, uint _fee) external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.ONGOING) {
//TODO optimize for gas usage

require(_custodies.length == _flows.length);

uint preBatchBalance = bbdToken.balanceOf(address(this));

for (uint flowIndex = 0; flowIndex < _flows.length; flowIndex++) {

//Every custody can be served BBD once during settlement
require(custodiesServedBBD[lastSettlementStartedTimestamp][_custodies[flowIndex]] == false);
//All addresses must be custodies
require(custodyStorage.custodiesMap(_custodies[flowIndex]));

if (_flows[flowIndex] > 0) {
var flowValue = ((uint(_flows[flowIndex]) * gweiBBDPriceInWei)/gwei);

//Minimal BBD transfer is 1gWeiBBD
require(flowValue >= 1);

//50% rule threshold
if(flowValue > 10 ether) {
//50% rule for bbd
require((getTotalBalanceFor(_custodies[flowIndex]) / 2) >= flowValue);
}

bbdToken.transfer(_custodies[flowIndex], uint(_flows[flowIndex]));

} else if (_flows[flowIndex] < 0) {
Custody custody = Custody(_custodies[flowIndex]);

custody.transferToken(address(bbdToken),address(this), uint(-(_flows[flowIndex])));
}

custodiesServedBBD[lastSettlementStartedTimestamp][_custodies[flowIndex]] = true;
}

if(_fee > 0) {
bbdToken.transfer(feeAccount, _fee);
//No need for safe math, as transfer will trow if _fee could cause overflow
totalFeeFlows += ((_fee * gweiBBDPriceInWei) / gwei);
require (totalFeeFlows <= startingFeeBalance);
}

uint postBatchBalance = bbdToken.balanceOf(address(this));

//Zero-or-less-sum guaranteed for every batch, no insurance for spots
require(postBatchBalance <= preBatchBalance);
}

/// @dev This function is used to finish the settlement process
function finishSettlement() external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.ONGOING) {
//TODO phase change event?
earliestNextSettlementTimestamp = lastSettlementStartedTimestamp + 23 hours;

currentSettlementPhase = SettlementPhase.FINISHED;
}

function getTotalBalanceFor(address _custody) internal view returns (uint) {

var bbdHoldingsInWei = ((bbdToken.balanceOf(_custody) * gweiBBDPriceInWei) / gwei);

return _custody.balance + bbdHoldingsInWei;
}

function checkIfCustodiesServedETH(address[] _custodies) external view returns (bool) {
for (uint custodyIndex = 0; custodyIndex < _custodies.length; custodyIndex++) {
if(custodiesServedETH[lastSettlementStartedTimestamp][_custodies[custodyIndex]]) {
return true;
}
}
return false;
}

function checkIfCustodiesServedBBD(address[] _custodies) external view returns (bool) {
for (uint custodyIndex = 0; custodyIndex < _custodies.length; custodyIndex++) {
if(custodiesServedBBD[lastSettlementStartedTimestamp][_custodies[custodyIndex]]) {
return true;
}
}
return false;
}
}