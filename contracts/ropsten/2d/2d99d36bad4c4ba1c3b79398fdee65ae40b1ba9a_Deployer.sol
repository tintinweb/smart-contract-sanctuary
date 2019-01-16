pragma solidity ^0.4.24;

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

/**
* Vault only instantiation, only focuses on eth value
*/
contract Will is Ownable {
  using SafeMath for uint;

  uint256 constant decimals = 8; //Allow fractions for disposition
  uint256 waitingTime; //How long to wait before initiating distribution
  uint256 lastInteraction; //Last time contract was interacted with
  address[] beneficiaries; //Address for each beneficiary
  mapping( address => uint256) disposition; //Percentage of total balacne to be sent to each beneficiary

  event BeneficiaryUpdated( address _beneficiary, uint256 _disposition, uint256 _timestamp); //Notify of update to beneficiaries / disposition

  constructor (uint256 _waitTime )
    public
  {
    beneficiaries.push(msg.sender);
    waitingTime = _waitTime;
    lastInteraction = now;
  }

  function unit ()
    public pure
  returns (uint) {
    return 10**decimals;
  }

  function totalDisposed ()
    public view
  returns (uint256 _total) {//Total amount already disposed
    for (uint256 i=0; i<beneficiaries.length; i++){
      _total.add(disposition[ beneficiaries[i] ].div(unit()));
    }
    return _total;
  }

  function isDispositionDue ()
    public view
  returns (bool) {
    return now.sub(lastInteraction) >= waitingTime;
  }

  function getBeneficiaryIndex (address _beneficiary)
    public view
  returns (uint256){
    for (uint256 _b=0; _b<beneficiaries.length; _b++) {
      if (beneficiaries[_b] == _beneficiary) {
        return _b;
      }
    }
    return 0;
  }

  function addBeneficiary (address _beneficiary, uint256 _disposition)
    public onlyOwner
  {
    require(_beneficiary != 0x0);
    require(getBeneficiaryIndex(_beneficiary) == 0);
    disposition[_beneficiary] = _disposition;
    beneficiaries.push(_beneficiary);
    emit BeneficiaryUpdated(_beneficiary, _disposition, block.timestamp);
  }

  function updateBeneficiary (address _beneficiary, uint256 _disposition)
    public onlyOwner
  {
    require(_beneficiary != 0x0);
    if (getBeneficiaryIndex(_beneficiary) == 0) {
      return addBeneficiary(_beneficiary,_disposition);
    } else {
      disposition[_beneficiary] = _disposition;
      emit BeneficiaryUpdated(_beneficiary, _disposition, block.timestamp);
    }
  }

  function removeBeneficiary (address _beneficiary)
    public onlyOwner
  {
    require(_beneficiary != 0x0);
    uint256 idx = getBeneficiaryIndex(_beneficiary);

    assert(beneficiaries[idx] == _beneficiary);
    require(idx != 0);//Ensure  first beneficiary can never be removed

    delete(disposition[_beneficiary]);
    beneficiaries[idx] = beneficiaries[ beneficiaries.length-1 ];
    delete(beneficiaries[beneficiaries.length-1]);
    beneficiaries.length--;
    emit BeneficiaryUpdated(_beneficiary, 0, block.timestamp);
  }

  function triggerDisposition () //Send balances to beneficiaries and send remainder to contract creator
    public
  {
    require(isDispositionDue());
    uint256 _balance = address(this).balance;
    for (uint256 _b=1;_b<beneficiaries.length;_b++) {
      beneficiaries[_b].transfer( _balance.mul(disposition[beneficiaries[_b]]).div(unit()) );
    }
    beneficiaries[0].transfer(address(this).balance);
  }

  function ()
    public payable
  {
    if (msg.value == 0) {
      triggerDisposition();
    }
  }
}

/**
* Wallet instantiation, is albe to run almost any Interaction: eth, toke, transactions
* It is basically a minimalistic implementation of Proxy contract discussed in EIP 725 and EIP 1167
*/
contract Wallet is Ownable {

  constructor ()
    public
  {
  }

  function transfer (address _destination, uint256 _value)
    public onlyOwner
  returns (bool) {
    _destination.transfer(_value);
    return true;
  }

  function callFunction (address _address, uint256 _value, bytes32 _callData) //Can be used to make wallet type calls, to interact with smart contracts
    public payable onlyOwner
  returns (bool) {
    return _address.call.value(_value)(_callData);
  }

  function ()
    public payable
  {
  }
}

/**
* Vault only instantiation, only focuses on eth value
*/
contract WillWallet is Will, Wallet {

  uint256 constant decimals = 8; //Allow fractions for disposition
  uint256 waitingTime; //How long to wait before initiating distribution
  uint256 lastInteraction; //Last time contract was interacted with
  address[] beneficiaries; //Address for each beneficiary
  mapping( address => uint256) disposition; //Percentage of total balacne to be sent to each beneficiary

  event BeneficiaryUpdated( address _beneficiary, uint256 _disposition, uint256 _timestamp); //Notify of update to beneficiaries / disposition

  constructor (uint256 _waitTime )
    Will(_waitTime)
    public
  {
  }
}

contract Deployer is Pausable {
  constructor ()
  public {

  }

  enum ContractTypes { will, wallet, willwallet }
  event ContractDeployed(string _type, address _contract, address creator);

  function _transferOwnership(address _contract, address _newOwner)
  internal
  {
    Ownable(_contract).transferOwnership(_newOwner);
  }

  function _deployContract(ContractTypes _type, uint256 _waitTime)
  internal
  returns (address newContract)
  {
    if (_type == ContractTypes.will) {
      newContract = new Will(_waitTime);
    } else if (_type == ContractTypes.wallet) {
      newContract = new Wallet();
    } else if (_type == ContractTypes.willwallet) {
      newContract = new WillWallet(_waitTime);
    }
    if (newContract != 0x0) {
      _transferOwnership(newContract, msg.sender);
      _handleDeposit(newContract);
    }
  }

  function _handleDeposit(address _newContract)
  internal
  {
    if (msg.value > 0) {
      _newContract.transfer(msg.value);
    }
  }

  function deployWill(uint256 _waitTime)
  public whenNotPaused
  {
    address newContract = _deployContract(ContractTypes.will, _waitTime);
    require(newContract != 0x0, &#39;Will not successfull deployed&#39;);
    emit ContractDeployed(&#39;will&#39;, newContract, msg.sender);
  }

  function deployWallet()
  public whenNotPaused
  {
    address newContract = _deployContract(ContractTypes.wallet, 0x0);
    require(newContract != 0x0, &#39;Wallet not successfull deployed&#39;);
    emit ContractDeployed(&#39;wallet&#39;, newContract, msg.sender);
  }

  function deployWillWallet(uint256 _waitTime)
  public whenNotPaused
  {
    address newContract = _deployContract(ContractTypes.willwallet, _waitTime);
    require(newContract != 0x0, &#39;Willwallet not successfull deployed&#39;);
    emit ContractDeployed(&#39;willwallet&#39;, newContract, msg.sender);
  }
}