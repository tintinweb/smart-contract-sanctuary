pragma solidity 0.4.23;

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
 * @title Oracle Escrow
 * @dev The Oracle Escrow contract has an owner address, acting as the agent, a depositor,
 * and a beneficiary. It allows for funds to be held in escrow until a given real-world
 * external event has occurred. Relies on a unique Oracle contract address to be created
 * using smartcontract.com. Inheriting the Ownable contract allows for the agent to be updated
 * or removed from the contract without altering the execution of the contract or outcome. 
 */
contract OracleEscrow is Ownable {
  uint256 public expiration;
  bool public contractExecuted;
  address public depositor;
  address public beneficiary;
  IOracle internal oracle;
  

  // Expected value is hard-coded into the contract and can be verified by all parties
  // before any deposit is made.
  bytes32 public constant EXPECTED = "yes";

  // Expiration date should be a factor of days to prevent timestamp dependence.
  // https://consensys.github.io/smart-contract-best-practices/recommendations/#timestamp-dependence
  uint256 internal constant TO_EXPIRE = 75 days;

  /** 
   * @dev The OracleEscrow constructor sets the oracle, depositor, and beneficiary addresses.
   * It also sets the `contractExecuted` field to `false` and sets the expiration of the agreement
   * to be 30 days after the OracleEscrow contract has been deployed.
   * @param _oracle address, the address of the deployed Oracle contract.
   * @param _depositor address, the address of the depositor.
   * @param _beneficiary address, the address of the beneficiary.
   */
  constructor(address _oracle, address _depositor, address _beneficiary) public payable Ownable() {
    oracle = IOracle(_oracle);
    depositor = _depositor;
    beneficiary = _beneficiary;
    contractExecuted = false;
    expiration = now + TO_EXPIRE;
  }

  /**
   * @dev Logs a message indicating where the escrow payment was sent to.
   */
  event ContractExecuted(bytes32 message);
  
  /**
   * @dev payable fallback only allows the depositor to send funds, as long as the contract
   * hasn&#39;t been executed already, and the expiration has not been passed.
   */
  function() external payable onlyDepositor {
    require(contractExecuted == false);
    require(now < expiration);
  }
  
  /**
   * @dev Executes the contract if called by an authorized user and the balance of the escrow
   * is greater than 0. If the Oracle contract&#39;s reported value is the expected value, payment
   * goes to the beneficiary. If the escrow contract has gone passed the expiration and the
   * Oracle contract&#39;s reported value still is not what is expected, payment is returned to
   * the depositor.
   */
  function executeContract() public checkAuthorizedUser() {
    require(address(this).balance > 0);
    if (oracle.current() == EXPECTED) {
      contractExecuted = true;
      emit ContractExecuted("Payment sent to beneficiary.");
      beneficiary.transfer(address(this).balance);
    } else if (now >= expiration) {
      contractExecuted = true;
      emit ContractExecuted("Payment refunded to depositor.");
      depositor.transfer(address(this).balance);
    }
  }

  /**
   * @dev Check the current value stored on the Oracle contract.
   * @return The current value at the Oracle contract.
   */
  function requestOracleValue() public view onlyOwner returns(bytes32) {
    return oracle.current();
  }

  /**
   * @dev Reverts if called by any account other than the owner, depositor, or beneficiary.
   */
  modifier checkAuthorizedUser() {
    require(msg.sender == owner || msg.sender == depositor || msg.sender == beneficiary, "Only authorized users may call this function.");
    _;
  }
  
  /**
   * @dev Reverts if called by any account other than the depositor.
   */
  modifier onlyDepositor() {
    require(msg.sender == depositor, "Only the depositor may call this function.");
    _;
  }
}

/**
 * @dev Interface for the Oracle contract.
 */
interface IOracle{
  function current() view external returns(bytes32);
}