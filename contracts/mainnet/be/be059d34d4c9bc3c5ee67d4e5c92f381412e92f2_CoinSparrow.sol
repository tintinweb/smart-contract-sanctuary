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
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
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






contract Arbitrator is Ownable {

  mapping(address => bool) private aribitratorWhitelist;
  address private primaryArbitrator;

  event ArbitratorAdded(address indexed newArbitrator);
  event ArbitratorRemoved(address indexed newArbitrator);
  event ChangePrimaryArbitratorWallet(address indexed newPrimaryWallet);

  constructor() public {
    primaryArbitrator = msg.sender;
  }

  modifier onlyArbitrator() {
    require(aribitratorWhitelist[msg.sender] == true || msg.sender == primaryArbitrator);
    _;
  }

  function changePrimaryArbitrator(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    emit ChangePrimaryArbitratorWallet(walletAddress);
    primaryArbitrator = walletAddress;
  }

  function addArbitrator(address newArbitrator) public onlyOwner {
    require(newArbitrator != address(0));
    emit ArbitratorAdded(newArbitrator);
    aribitratorWhitelist[newArbitrator] = true;
  }

  function deleteArbitrator(address arbitrator) public onlyOwner {
    require(arbitrator != address(0));
    require(arbitrator != msg.sender); //ensure owner isn&#39;t removed
    emit ArbitratorRemoved(arbitrator);
    delete aribitratorWhitelist[arbitrator];
  }

  //Mainly for front-end administration
  function isArbitrator(address arbitratorCheck) external view returns(bool) {
    return (aribitratorWhitelist[arbitratorCheck] || arbitratorCheck == primaryArbitrator);
  }
}







contract ApprovedWithdrawer is Ownable {

  mapping(address => bool) private withdrawerWhitelist;
  address private primaryWallet;

  event WalletApproved(address indexed newAddress);
  event WalletRemoved(address indexed removedAddress);
  event ChangePrimaryApprovedWallet(address indexed newPrimaryWallet);

  constructor() public {
    primaryWallet = msg.sender;
  }

  modifier onlyApprovedWallet(address _to) {
    require(withdrawerWhitelist[_to] == true || primaryWallet == _to);
    _;
  }

  function changePrimaryApprovedWallet(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    emit ChangePrimaryApprovedWallet(walletAddress);
    primaryWallet = walletAddress;
  }

  function addApprovedWalletAddress(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    emit WalletApproved(walletAddress);
    withdrawerWhitelist[walletAddress] = true;
  }

  function deleteApprovedWalletAddress(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    require(walletAddress != msg.sender); //ensure owner isn&#39;t removed
    emit WalletRemoved(walletAddress);
    delete withdrawerWhitelist[walletAddress];
  }

  //Mainly for front-end administration
  function isApprovedWallet(address walletCheck) external view returns(bool) {
    return (withdrawerWhitelist[walletCheck] || walletCheck == primaryWallet);
  }
}


/**
 * @title CoinSparrow
 */


contract CoinSparrow  is Ownable, Arbitrator, ApprovedWithdrawer, Pausable {

  //Who wouldn&#39;t?
  using SafeMath for uint256;

  /**
   * ------------------------------------
   * SET UP SOME CONSTANTS FOR JOB STATUS
   * ------------------------------------
   */

  //Some of these are not used in the contract, but are for reference and are used in the front-end&#39;s database.
  uint8 constant private STATUS_JOB_NOT_EXIST = 1; //Not used in contract. Here for reference (used externally)
  uint8 constant private STATUS_JOB_CREATED = 2; //Job has been created. Set by createJobEscrow()
  uint8 constant private STATUS_JOB_STARTED = 3; //Contractor flags job as started. Set by jobStarted()
  uint8 constant private STATUS_HIRER_REQUEST_CANCEL = 4; //Hirer requested cancellation on started job.
                                                  //Set by requestMutualJobCancelation()
  uint8 constant private STATUS_JOB_COMPLETED = 5; //Contractor flags job as completed. Set by jobCompleted()
  uint8 constant private STATUS_JOB_IN_DISPUTE = 6; //Either party raised dispute. Set by requestDispute()
  uint8 constant private STATUS_HIRER_CANCELLED = 7; //Not used in contract. Here for reference
  uint8 constant private STATUS_CONTRACTOR_CANCELLED = 8; //Not used in contract. Here for reference
  uint8 constant private STATUS_FINISHED_FUNDS_RELEASED = 9; //Not used in contract. Here for reference
  uint8 constant private STATUS_FINISHED_FUNDS_RELEASED_BY_CONTRACTOR = 10; //Not used in contract. Here for reference
  uint8 constant private STATUS_CONTRACTOR_REQUEST_CANCEL = 11; //Contractor requested cancellation on started job.
                                                        //Set by requestMutualJobCancelation()
  uint8 constant private STATUS_MUTUAL_CANCELLATION_PROCESSED = 12; //Not used in contract. Here for reference

  //Deployment script will check for existing CoinSparrow contracts, and only
  //deploy if this value is > than existing version.
  //TODO: to be implemented
  uint8 constant private COINSPARROW_CONTRACT_VERSION = 1;

  /**
   * ------
   * EVENTS
   * ------
   */

  event JobCreated(bytes32 _jobHash, address _who, uint256 _value);
  event ContractorStartedJob(bytes32 _jobHash, address _who);
  event ContractorCompletedJob(bytes32 _jobHash, address _who);
  event HirerRequestedCancel(bytes32 _jobHash, address _who);
  event ContractorRequestedCancel(bytes32 _jobHash, address _who);
  event CancelledByHirer(bytes32 _jobHash, address _who);
  event CancelledByContractor(bytes32 _jobHash, address _who);
  event MutuallyAgreedCancellation(
    bytes32 _jobHash,
    address _who,
    uint256 _hirerAmount,
    uint256 _contractorAmount
  );
  event DisputeRequested(bytes32 _jobHash, address _who);
  event DisputeResolved(
    bytes32 _jobHash,
    address _who,
    uint256 _hirerAmount,
    uint256 _contractorAmount
  );
  event HirerReleased(bytes32 _jobHash, address _hirer, address _contractor, uint256 _value);
  event AddFeesToCoinSparrowPool(bytes32 _jobHash, uint256 _value);
  event ContractorReleased(bytes32 _jobHash, address _hirer, address _contractor, uint256 _value);
  event HirerLastResortRefund(bytes32 _jobHash, address _hirer, address _contractor, uint256 _value);
  event WithdrawFeesFromCoinSparrowPool(address _whoCalled, address _to, uint256 _amount);
  event LogFallbackFunctionCalled(address _from, uint256 _amount);


  /**
   * ----------
   * STRUCTURES
   * ----------
   */

  /**
   * @dev Structure to hold live Escrow data - current status, times etc.
   */
  struct JobEscrow {
    // Set so we know the job has already been created. Set when job created in createJobEscrow()
    bool exists;
    // The timestamp after which the hirer can cancel the task if the contractor has not yet flagged as job started.
    // Set in createJobEscrow(). If the Contractor has not called jobStarted() within this time, then the hirer
    // can call hirerCancel() to get a full refund (minus gas fees)
    uint32 hirerCanCancelAfter;
    //Job&#39;s current status (see STATUS_JOB_* constants above). Updated in multiple functions
    uint8 status;
    //timestamp for job completion. Set when jobCompleted() is called.
    uint32 jobCompleteDate;
    //num agreed seconds it will take to complete the job, once flagged as STATUS_JOB_STARTED. Set in createJobEscrow()
    uint32 secondsToComplete;
    //timestamp calculated for agreed completion date. Set when jobStarted() is called.
    uint32 agreedCompletionDate;
  }

  /**
   * ------------------
   * CONTRACT VARIABLES
   * ------------------
   */


  //Total Wei currently held in Escrow
  uint256 private totalInEscrow;
  //Amount of Wei available to CoinSparrow to withdraw
  uint256 private feesAvailableForWithdraw;

  /*
   * Set max limit for how much (in wei) contract will accept. Can be modified by owner using setMaxSend()
   * This ensures that arbitrarily large amounts of ETH can&#39;t be sent.
   * Front end will check this value before processing new jobs
   */
  uint256 private MAX_SEND;

  /*
   * Mapping of active jobs. Key is a hash of the job data:
   * JobEscrow = keccak256(_jobId,_hirer,_contractor, _value, _fee)
   * Once job is complete, and refunds released, the
   * mapping for that job is deleted to conserve space.
   */
  mapping(bytes32 => JobEscrow) private jobEscrows;

  /*
   * mapping of Hirer&#39;s funds in Escrow for each job.
   * This is referenced when any ETH transactions occur
   */
  mapping(address => mapping(bytes32 => uint256)) private hirerEscrowMap;

  /**
   * ---------
   * MODIFIERS
   * ---------
   */

  /**
   * @dev modifier to ensure only the Hirer can execute
   * @param _hirer Address of the hirer to check against msg.sender
   */

  modifier onlyHirer(address _hirer) {
    require(msg.sender == _hirer);
    _;
  }

  /**
   * @dev modifier to ensure only the Contractor can execute
   * @param _contractor Address of the contractor to check against msg.sender
   */

  modifier onlyContractor(address _contractor) {
    require(msg.sender == _contractor);
    _;
  }

  /**
   * @dev modifier to ensure only the Contractor can execute
   * @param _contractor Address of the contractor to check against msg.sender
   */

  modifier onlyHirerOrContractor(address _hirer, address _contractor) {
    require(msg.sender == _hirer || msg.sender == _contractor);
    _;
  }

  /**
   * ----------------------
   * CONTRACT FUNCTIONALITY
   * ----------------------
   */

  /**
   * @dev Constructor function for the contract
   * @param _maxSend Maximum Wei the contract will accept in a transaction
   */

  constructor(uint256 _maxSend) public {
    require(_maxSend > 0);
    //a bit of protection. Set a limit, so users can&#39;t send stupid amounts of ETH
    MAX_SEND = _maxSend;
  }

  /**
   * @dev fallback function for the contract. Log event so ETH can be tracked and returned
   */

  function() payable {
    //Log who sent, and how much so it can be returned
    emit LogFallbackFunctionCalled(msg.sender, msg.value);
  }

  /**
   * @dev Create a new escrow and add it to the `jobEscrows` mapping.
   * Also updates/creates a reference to the job, and amount in Escrow for the job in hirerEscrowMap
   * jobHash is created by hashing _jobId, _seller, _buyer, _value and _fee params.
   * These params must be supplied on future contract calls.
   * A hash of the job parameters (_jobId, _hirer, _contractor, _value, _fee) is created and used
   * to access job data held in the contract. All functions that interact with a job in Escrow
   * require these parameters.
   * Pausable - only runs whenNotPaused. Can pause to prevent taking any more
   *            ETH if there is a problem with the Smart Contract.
   *            Parties can still access/transfer their existing ETH held in Escrow, complete jobs etc.
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @param _jobStartedWindowInSeconds time within which the contractor must flag as job started
   *                                   if job hasn&#39;t started AFTER this time, hirer can cancel contract.
   *                                   Hirer cannot cancel contract before this time.
   * @param _secondsToComplete agreed time to complete job once it&#39;s flagged as STATUS_JOB_STARTED
   */
  function createJobEscrow(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee,
    uint32 _jobStartedWindowInSeconds,
    uint32 _secondsToComplete
  ) payable external whenNotPaused onlyHirer(_hirer)
  {

    // Check sent eth against _value and also make sure is not 0
    require(msg.value == _value && msg.value > 0);

    //CoinSparrow&#39;s Fee should be less than the Job Value, because anything else would be daft.
    require(_fee < _value);

    //Check the amount sent is below the acceptable threshold
    require(msg.value <= MAX_SEND);

    //needs to be more than 0 seconds
    require(_jobStartedWindowInSeconds > 0);

    //needs to be more than 0 seconds
    require(_secondsToComplete > 0);

    //generate the job hash. Used to reference the job in all future function calls/transactions.
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //Check that the job does not already exist.
    require(!jobEscrows[jobHash].exists);

    //create the job and store it in the mapping
    jobEscrows[jobHash] = JobEscrow(
      true,
      uint32(block.timestamp) + _jobStartedWindowInSeconds,
      STATUS_JOB_CREATED,
      0,
      _secondsToComplete,
      0);

    //update total held in escrow
    totalInEscrow = totalInEscrow.add(msg.value);

    //Update hirer&#39;s job => value mapping
    hirerEscrowMap[msg.sender][jobHash] = msg.value;

    //Let the world know.
    emit JobCreated(jobHash, msg.sender, msg.value);
  }

  /**
   * -----------------------
   * RELEASE FUNDS FUNCTIONS
   * -----------------------
   */

  /**
   * @dev Release funds to contractor. Can only be called by Hirer. Can be called at any time as long as the
   * job exists in the contract (for example, two parties may have agreed job is complete external to the
   * CoinSparrow website). Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function hirerReleaseFunds(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirer(_hirer)
  {

    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);

    //check hirer has funds in the Smart Contract assigned to this job
    require(hirerEscrowMap[msg.sender][jobHash] > 0);

    //get the value from the stored hirer => job => value mapping
    uint256 jobValue = hirerEscrowMap[msg.sender][jobHash];

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

     //Log event
    emit HirerReleased(
      jobHash,
      msg.sender,
      _contractor,
      jobValue);

     //Log event
    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    //no longer required. Remove to save storage. Also prevents reentrancy
    delete jobEscrows[jobHash];
    //no longer required. Remove to save storage. Also prevents reentrancy
    delete hirerEscrowMap[msg.sender][jobHash];

    //add to CoinSparrow&#39;s fee pool
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);

    //update total in escrow
    totalInEscrow = totalInEscrow.sub(jobValue);

    //Finally, transfer the funds, minus CoinSparrow fees
    _contractor.transfer(jobValue.sub(_fee));

  }

  /**
   * @dev Release funds to contractor in the event that the Hirer is unresponsive after job has been flagged as complete.
   * Can only be called by the contractor, and only 4 weeks after the job has been flagged as complete.
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function contractorReleaseFunds(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {

    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);

    //check job is actually completed
    require(jobEscrows[jobHash].status == STATUS_JOB_COMPLETED);
    //can only self-release 4 weeks after completion
    require(block.timestamp > jobEscrows[jobHash].jobCompleteDate + 4 weeks);

    //get value for job
    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    emit ContractorReleased(
      jobHash,
      _hirer,
      _contractor,
      jobValue); //Log event
    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    delete jobEscrows[jobHash]; //no longer required. Remove to save storage.
    delete  hirerEscrowMap[_hirer][jobHash]; //no longer required. Remove to save storage.

    //add fees to coinsparrow pool
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);

    //update total in escrow
    totalInEscrow = totalInEscrow.sub(jobValue);

    //transfer funds to contractor, minus fees
    _contractor.transfer(jobValue.sub(_fee));

  }

  /**
   * @dev Can be called by the hirer to claim a full refund, if job has been started but contractor has not
   * completed within 4 weeks after agreed completion date, and becomes unresponsive.
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function hirerLastResortRefund(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirer(_hirer)
  {
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);
    
    //check job is started
    require(jobEscrows[jobHash].status == STATUS_JOB_STARTED);
    //can only self-refund 4 weeks after agreed completion date
    require(block.timestamp > jobEscrows[jobHash].agreedCompletionDate + 4 weeks);

    //get value for job
    uint256 jobValue = hirerEscrowMap[msg.sender][jobHash];

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    emit HirerLastResortRefund(
      jobHash,
      _hirer,
      _contractor,
      jobValue); //Log event

    delete jobEscrows[jobHash]; //no longer required. Remove to save storage.
    delete  hirerEscrowMap[_hirer][jobHash]; //no longer required. Remove to save storage.

    //update total in escrow
    totalInEscrow = totalInEscrow.sub(jobValue);

    //transfer funds to hirer
    _hirer.transfer(jobValue);
  }

  /**
   * ---------------------------
   * UPDATE JOB STATUS FUNCTIONS
   * ---------------------------
   */

  /**
   * @dev Flags job started, and Stops the hirer from cancelling the job.
   * Can only be called the contractor when job starts.
   * Used to mark the job as started. After this point, hirer must request cancellation
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function jobStarted(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);
    //check job status.
    require(jobEscrows[jobHash].status == STATUS_JOB_CREATED);
    jobEscrows[jobHash].status = STATUS_JOB_STARTED; //set status
    jobEscrows[jobHash].hirerCanCancelAfter = 0;
    jobEscrows[jobHash].agreedCompletionDate = uint32(block.timestamp) + jobEscrows[jobHash].secondsToComplete;
    emit ContractorStartedJob(jobHash, msg.sender);
  }

  /**
   * @dev Flags job completed to inform hirer. Also sets flag to allow contractor to get their funds 4 weeks after
   * completion in the event that the hirer is unresponsive and doesn&#39;t release the funds.
   * Can only be called the contractor when job complete.
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function jobCompleted(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    require(jobEscrows[jobHash].exists); //check the job exists in the contract
    require(jobEscrows[jobHash].status == STATUS_JOB_STARTED); //check job status.
    jobEscrows[jobHash].status = STATUS_JOB_COMPLETED;
    jobEscrows[jobHash].jobCompleteDate = uint32(block.timestamp);
    emit ContractorCompletedJob(jobHash, msg.sender);
  }

  /**
   * --------------------------
   * JOB CANCELLATION FUNCTIONS
   * --------------------------
   */

  /**
   * @dev Cancels the job and returns the ether to the hirer.
   * Can only be called the contractor. Can be called at any time during the process
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function contractorCancel(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[_hirer][jobHash];
    emit CancelledByContractor(jobHash, msg.sender);

    totalInEscrow = totalInEscrow.sub(jobValue);

    _hirer.transfer(jobValue);
  }

  /**
   * @dev Cancels the job and returns the ether to the hirer.
   * Can only be called the hirer.
   * Can only be called if the job start window was missed by the contractor
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function hirerCancel(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirer(_hirer)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);

    require(jobEscrows[jobHash].hirerCanCancelAfter > 0);
    require(jobEscrows[jobHash].status == STATUS_JOB_CREATED);
    require(jobEscrows[jobHash].hirerCanCancelAfter < block.timestamp);

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[msg.sender][jobHash];
    emit CancelledByHirer(jobHash, msg.sender);

    totalInEscrow = totalInEscrow.sub(jobValue);

    _hirer.transfer(jobValue);
  }

  /**
   * @dev Called by the hirer or contractor to request mutual cancellation once job has started
   * Can only be called when status = STATUS_JOB_STARTED
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function requestMutualJobCancellation(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirerOrContractor(_hirer, _contractor)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);
    require(jobEscrows[jobHash].status == STATUS_JOB_STARTED);

    if (msg.sender == _hirer) {
      jobEscrows[jobHash].status = STATUS_HIRER_REQUEST_CANCEL;
      emit HirerRequestedCancel(jobHash, msg.sender);
    }
    if (msg.sender == _contractor) {
      jobEscrows[jobHash].status = STATUS_CONTRACTOR_REQUEST_CANCEL;
      emit ContractorRequestedCancel(jobHash, msg.sender);
    }
  }

  /**
   * @dev Called when both hirer and contractor have agreed on cancellation conditions, and amount each will receive
   * can be called by hirer or contractor once % amount has been signed by both parties.
   * Both parties sign a hash of the % agreed upon. The signatures of both parties must be sent and verified
   * before the transaction is processed, to ensure that the % processed is valid.
   * can be called at any time
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @param _contractorPercent percentage the contractor will be paid
   * @param _hirerMsgSig Signed message from hiring party agreeing on _contractorPercent
   * @param _contractorMsgSig Signed message from contractor agreeing on _contractorPercent
   */
  function processMutuallyAgreedJobCancellation(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee,
    uint8 _contractorPercent,
    bytes _hirerMsgSig,
    bytes _contractorMsgSig
  ) external
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);

    require(msg.sender == _hirer || msg.sender == _contractor);
    require(_contractorPercent <= 100 && _contractorPercent >= 0);

    //Checks the signature of both parties to ensure % is correct.
    //Attempts to prevent the party calling the function from modifying the pre-agreed %
    require(
      checkRefundSignature(_contractorPercent,_hirerMsgSig,_hirer)&&
      checkRefundSignature(_contractorPercent,_contractorMsgSig,_contractor));

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    totalInEscrow = totalInEscrow.sub(jobValue);
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[_hirer][jobHash];

    uint256 contractorAmount = jobValue.sub(_fee).mul(_contractorPercent).div(100);
    uint256 hirerAmount = jobValue.sub(_fee).mul(100 - _contractorPercent).div(100);

    emit MutuallyAgreedCancellation(
      jobHash,
      msg.sender,
      hirerAmount,
      contractorAmount);

    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    if (contractorAmount > 0) {
      _contractor.transfer(contractorAmount);
    }
    if (hirerAmount > 0) {
      _hirer.transfer(hirerAmount);
    }
  }

  /**
   * -------------------------
   * DISPUTE RELATED FUNCTIONS
   * -------------------------
   */

  /**
   * @dev Called by hirer or contractor to raise a dispute during started, completed or canellation request statuses
   * Once called, funds are locked until arbitrator can resolve the dispute. Assigned arbitrator
   * will review all information relating to the job, and decide on a fair course of action.
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   */
  function requestDispute(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirerOrContractor(_hirer, _contractor)
  {

    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);
    require(
      jobEscrows[jobHash].status == STATUS_JOB_STARTED||
      jobEscrows[jobHash].status == STATUS_JOB_COMPLETED||
      jobEscrows[jobHash].status == STATUS_HIRER_REQUEST_CANCEL||
      jobEscrows[jobHash].status == STATUS_CONTRACTOR_REQUEST_CANCEL);

    jobEscrows[jobHash].status = STATUS_JOB_IN_DISPUTE;

    emit DisputeRequested(jobHash, msg.sender);
  }

  /**
   * @dev Called by the arbitrator to resolve a dispute
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @param _contractorPercent percentage the contractor will receive
   */

  function resolveDispute(

    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee,
    uint8 _contractorPercent
  ) external onlyArbitrator
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    //check the job exists in the contract
    require(jobEscrows[jobHash].exists);

    require(jobEscrows[jobHash].status == STATUS_JOB_IN_DISPUTE);
    require(_contractorPercent <= 100);

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

    //Check values in contract and sent are valid
    require(jobValue > 0 && jobValue == _value);

    //check fee amount is valid
    require(jobValue >= jobValue.sub(_fee));

    //check there is enough in escrow
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    totalInEscrow = totalInEscrow.sub(jobValue);
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);
    // Add the the pot for localethereum to withdraw

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[_hirer][jobHash];

    uint256 contractorAmount = jobValue.sub(_fee).mul(_contractorPercent).div(100);
    uint256 hirerAmount = jobValue.sub(_fee).mul(100 - _contractorPercent).div(100);
    emit DisputeResolved(
      jobHash,
      msg.sender,
      hirerAmount,
      contractorAmount);

    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    _contractor.transfer(contractorAmount);
    _hirer.transfer(hirerAmount);

  }

  /**
   * ------------------------
   * ADMINISTRATIVE FUNCTIONS
   * ------------------------
   */

  /**
   * @dev Allows owner to transfer funds from the collected fees pool to an approved wallet address
   * @param _to receiver wallet address
   * @param _amount amount to withdraw and transfer
   */
  function withdrawFees(address _to, uint256 _amount) onlyOwner onlyApprovedWallet(_to) external {
    /**
     * Withdraw fees collected by the contract. Only the owner can call this.
     * Can only be sent to an approved wallet address
     */
    require(_amount > 0);
    require(_amount <= feesAvailableForWithdraw && feesAvailableForWithdraw > 0);

    feesAvailableForWithdraw = feesAvailableForWithdraw.sub(_amount);

    emit WithdrawFeesFromCoinSparrowPool(msg.sender,_to, _amount);

    _to.transfer(_amount);
  }

  /**
   * @dev returns how much has been collected in fees, and how much is available to withdraw
   * @return feesAvailableForWithdraw amount available for CoinSparrow to withdraw
   */

  function howManyFees() external view returns (uint256) {
    return feesAvailableForWithdraw;
  }

  /**
   * @dev returns how much is currently held in escrow
   * @return totalInEscrow amount currently held in escrow
   */

  function howMuchInEscrow() external view returns (uint256) {
    return totalInEscrow;
  }

  /**
   * @dev modify the maximum amount of ETH the contract will allow in a transaction (when creating a new job)
   * @param _maxSend amount in Wei
   */

  function setMaxSend(uint256 _maxSend) onlyOwner external {
    require(_maxSend > 0);
    MAX_SEND = _maxSend;
  }

  /**
   * @dev return the current maximum amount the contract will allow in a transaction
   * @return MAX_SEND current maximum value
   */

  function getMaxSend() external view returns (uint256) {
    return MAX_SEND;
  }

  /**
   * @dev returns THIS contract instance&#39;s version
   * @return COINSPARROW_CONTRACT_VERSION version number of THIS instance of the contract
   */

  function getContractVersion() external pure returns(uint8) {
    return COINSPARROW_CONTRACT_VERSION;
  }

  /**
   * -------------------------
   * JOB INFORMATION FUNCTIONS
   * -------------------------
   */

  /**
   * @dev returns the status of the requested job
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return status job&#39;s current status
   */

  function getJobStatus(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint8)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint8 status = STATUS_JOB_NOT_EXIST;

    if (jobEscrows[jobHash].exists) {
      status = jobEscrows[jobHash].status;
    }
    return status;
  }

  /**
   * @dev returns the date after which the Hirer can cancel the job
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return hirerCanCancelAfter timestamp for date after which the hirer can cancel
   */

  function getJobCanCancelAfter(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 hirerCanCancelAfter = 0;

    if (jobEscrows[jobHash].exists) {
      hirerCanCancelAfter = jobEscrows[jobHash].hirerCanCancelAfter;
    }
    return hirerCanCancelAfter;
  }

  /**
   * @dev returns the number of seconds for job completion
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return secondsToComplete number of seconds to complete job
   */

  function getSecondsToComplete(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 secondsToComplete = 0;

    if (jobEscrows[jobHash].exists) {
      secondsToComplete = jobEscrows[jobHash].secondsToComplete;
    }
    return secondsToComplete;
  }

  /**
   * @dev returns the agreed completion date of the requested job
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return agreedCompletionDate timestamp for agreed completion date
   */

  function getAgreedCompletionDate(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 agreedCompletionDate = 0;

    if (jobEscrows[jobHash].exists) {
      agreedCompletionDate = jobEscrows[jobHash].agreedCompletionDate;
    }
    return agreedCompletionDate;
  }

  /**
   * @dev returns the actual completion date of the job of the requested job
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return jobCompleteDate timestamp for actual completion date
   */

  function getActualCompletionDate(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 jobCompleteDate = 0;

    if (jobEscrows[jobHash].exists) {
      jobCompleteDate = jobEscrows[jobHash].jobCompleteDate;
    }
    return jobCompleteDate;
  }

  /**
   * @dev returns the value for the requested job
   * Following parameters are used to regenerate the jobHash:
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return amount job&#39;s value
   */

  function getJobValue(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns(uint256)
  {
    //get job Hash
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint256 amount = 0;
    if (jobEscrows[jobHash].exists) {
      amount = hirerEscrowMap[_hirer][jobHash];
    }
    return amount;
  }

  /**
   * @dev Helper function to pre-validate mutual cancellation signatures. Used by front-end app
   * to let each party know that the other has signed off the agreed %
   * @param _contractorPercent percentage agreed upon
   * @param _sigMsg signed message to be validated
   * @param _signer wallet address of the message signer to validate against
   * @return bool whether or not the signature is valid
   */
  function validateRefundSignature(
    uint8 _contractorPercent,
    bytes _sigMsg,
    address _signer) external pure returns(bool)
  {

    return checkRefundSignature(_contractorPercent,_sigMsg,_signer);

  }

  /**
   * @dev Executes the actual signature verification.
   * @param _contractorPercent percentage agreed upon
   * @param _sigMsg signed message to be validated
   * @param _signer wallet address of the message signer to validate against
   * @return bool whether or not the signature is valid
   */
  function checkRefundSignature(
    uint8 _contractorPercent,
    bytes _sigMsg,
    address _signer) private pure returns(bool)
  {
    bytes32 percHash = keccak256(abi.encodePacked(_contractorPercent));
    bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",percHash));

    address addr = ECRecovery.recover(msgHash,_sigMsg);
    return addr == _signer;
  }

  /**
   * @dev Generates the sha256 jobHash based on job parameters. Used in several functions
   * @param _jobId The unique ID of the job, from the CoinSparrow database
   * @param _hirer The wallet address of the hiring (buying) party
   * @param _contractor The wallet address of the contractor (selling) party
   * @param _value The ether amount being held in escrow. I.e. job cost - amount hirer is paying contractor
   * @param _fee CoinSparrow fee for this job. Pre-calculated
   * @return bytes32 the calculated jobHash value
   */
  function getJobHash(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  )  private pure returns(bytes32)
  {
    return keccak256(abi.encodePacked(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee));
  }

}