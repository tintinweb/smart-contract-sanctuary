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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract Upgradable is Ownable, Pausable {
    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyOwner whenPaused {
        require(_v2Address != 0x0);
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

}

/// @title The main SolidStamp.com contract
contract SolidStamp is Ownable, Pausable, Upgradable {
    using SafeMath for uint;

    /// @dev const value to indicate the contract is audited and approved
    uint8 public constant NOT_AUDITED = 0x00;

    /// @dev minimum amount of time for an audit request
    uint public constant MIN_AUDIT_TIME = 24 hours;

    /// @dev maximum amount of time for an audit request
    uint public constant MAX_AUDIT_TIME = 28 days;

    /// @dev aggregated amount of audit requests
    uint public TotalRequestsAmount = 0;

    // @dev amount of collected commision available to withdraw
    uint public AvailableCommission = 0;

    // @dev commission percentage, initially 1%
    uint public Commission = 1;

    /// @dev event fired when the service commission is changed
    event NewCommission(uint commmission);

    address public SolidStampRegisterAddress;

    /// @notice SolidStamp constructor
    constructor(address _addressRegistrySolidStamp) public {
        SolidStampRegisterAddress = _addressRegistrySolidStamp;
    }

    /// @notice Audit request
    struct AuditRequest {
        // amount of Ethers offered by a particular requestor for an audit
        uint amount;
        // request expiration date
        uint expireDate;
    }

    /// @dev Maps auditor and code hash to the total reward offered for auditing
    /// the particular contract by the particular auditor.
    /// Map key is: keccack256(auditor address, contract codeHash)
    /// @dev codeHash is a sha3 from the contract byte code
    mapping (bytes32 => uint) public Rewards;

    /// @dev Maps requestor, auditor and codeHash to an AuditRequest
    /// Map key is: keccack256(auditor address, requestor address, contract codeHash)
    mapping (bytes32 => AuditRequest) public AuditRequests;

    /// @dev event fired upon successul audit request
    event AuditRequested(address auditor, address bidder, bytes32 codeHash, uint amount, uint expireDate);
    /// @dev event fired when an request is sucessfully withdrawn
    event RequestWithdrawn(address auditor, address bidder, bytes32 codeHash, uint amount);
    /// @dev event fired when a contract is sucessfully audited
    event ContractAudited(address auditor, bytes32 codeHash, bytes reportIPFS, bool isApproved, uint reward);

    /// @notice registers an audit request
    /// @param _auditor the address of the auditor the request is directed to
    /// @param _codeHash the code hash of the contract to audit. _codeHash equals to sha3 of the contract byte-code
    /// @param _auditTime the amount of time after which the requestor can withdraw the request
    function requestAudit(address _auditor, bytes32 _codeHash, uint _auditTime)
    public whenNotPaused payable
    {
        require(_auditor != 0x0, "_auditor cannot be 0x0");
        // audit request cannot expire too quickly or last too long
        require(_auditTime >= MIN_AUDIT_TIME, "_auditTime should be >= MIN_AUDIT_TIME");
        require(_auditTime <= MAX_AUDIT_TIME, "_auditTime should be <= MIN_AUDIT_TIME");
        require(msg.value > 0, "msg.value should be >0");

        // revert if the contract is already audited by the auditor
        uint8 outcome = SolidStampRegister(SolidStampRegisterAddress).getAuditOutcome(_auditor, _codeHash);
        require(outcome == NOT_AUDITED, "contract already audited");

        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        uint currentReward = Rewards[hashAuditorCode];
        uint expireDate = now.add(_auditTime);
        Rewards[hashAuditorCode] = currentReward.add(msg.value);
        TotalRequestsAmount = TotalRequestsAmount.add(msg.value);

        bytes32 hashAuditorRequestorCode = keccak256(abi.encodePacked(_auditor, msg.sender, _codeHash));
        AuditRequest storage request = AuditRequests[hashAuditorRequestorCode];
        if ( request.amount == 0 ) {
            // first request from msg.sender to audit contract _codeHash by _auditor
            AuditRequests[hashAuditorRequestorCode] = AuditRequest({
                amount : msg.value,
                expireDate : expireDate
            });
            emit AuditRequested(_auditor, msg.sender, _codeHash, msg.value, expireDate);
        } else {
            // Request already exists. Increasing value
            request.amount = request.amount.add(msg.value);
            // if new expireDate is later than existing one - increase the existing one
            if ( expireDate > request.expireDate )
                request.expireDate = expireDate;
            // event returns the total request value and its expireDate
            emit AuditRequested(_auditor, msg.sender, _codeHash, request.amount, request.expireDate);
        }
    }

    /// @notice withdraws an audit request
    /// @param _auditor the address of the auditor the request is directed to
    /// @param _codeHash the code hash of the contract to audit. _codeHash equals to sha3 of the contract byte-code
    function withdrawRequest(address _auditor, bytes32 _codeHash)
    public
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));

        // revert if the contract is already audited by the auditor
        uint8 outcome = SolidStampRegister(SolidStampRegisterAddress).getAuditOutcome(_auditor, _codeHash);
        require(outcome == NOT_AUDITED, "contract already audited");

        bytes32 hashAuditorRequestorCode = keccak256(abi.encodePacked(_auditor, msg.sender, _codeHash));
        AuditRequest storage request = AuditRequests[hashAuditorRequestorCode];
        require(request.amount > 0, "nothing to withdraw");
        require(now > request.expireDate, "cannot withdraw before request.expireDate");

        uint amount = request.amount;
        delete request.amount;
        delete request.expireDate;
        Rewards[hashAuditorCode] = Rewards[hashAuditorCode].sub(amount);
        TotalRequestsAmount = TotalRequestsAmount.sub(amount);
        emit RequestWithdrawn(_auditor, msg.sender, _codeHash, amount);
        msg.sender.transfer(amount);
    }

    /// @notice transfers reward to the auditor. Called by SolidStampRegister after the contract is audited
    /// @param _auditor the auditor who audited the contract
    /// @param _codeHash the code hash of the stamped contract. _codeHash equals to sha3 of the contract byte-code
    /// @param _reportIPFS IPFS hash of the audit report
    /// @param _isApproved whether the contract is approved or rejected
    function auditContract(address _auditor, bytes32 _codeHash, bytes _reportIPFS, bool _isApproved)
    public whenNotPaused onlySolidStampRegisterContract
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        uint reward = Rewards[hashAuditorCode];
        TotalRequestsAmount = TotalRequestsAmount.sub(reward);
        uint commissionKept = calcCommission(reward);
        AvailableCommission = AvailableCommission.add(commissionKept);
        emit ContractAudited(_auditor, _codeHash, _reportIPFS, _isApproved, reward);
        _auditor.transfer(reward.sub(commissionKept));
    }

    /**
     * @dev Throws if called by any account other than the contractSolidStamp
     */
    modifier onlySolidStampRegisterContract() {
      require(msg.sender == SolidStampRegisterAddress, "can be only run by SolidStampRegister contract");
      _;
    }

    /// @dev const value to indicate the maximum commision service owner can set
    uint public constant MAX_COMMISSION = 9;

    /// @notice ability for owner to change the service commmission
    /// @param _newCommission new commision percentage
    function changeCommission(uint _newCommission) public onlyOwner whenNotPaused {
        require(_newCommission <= MAX_COMMISSION, "commission should be <= MAX_COMMISSION");
        require(_newCommission != Commission, "_newCommission==Commmission");
        Commission = _newCommission;
        emit NewCommission(Commission);
    }

    /// @notice calculates the SolidStamp commmission
    /// @param _amount amount to calcuate the commission from
    function calcCommission(uint _amount) private view returns(uint) {
        return _amount.mul(Commission)/100; // service commision
    }

    /// @notice ability for owner to withdraw the commission
    /// @param _amount amount to withdraw
    function withdrawCommission(uint _amount) public onlyOwner {
        // cannot withdraw money reserved for requests
        require(_amount <= AvailableCommission, "Cannot withdraw more than available");
        AvailableCommission = AvailableCommission.sub(_amount);
        msg.sender.transfer(_amount);
    }

    /// @dev Override unpause so we can&#39;t have newContractAddress set,
    ///  because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyOwner whenPaused {
        require(newContractAddress == address(0), "new contract cannot be 0x0");

        // Actually unpause the contract.
        super.unpause();
    }

    /// @notice We don&#39;t want your arbitrary ether
    function() payable public {
        revert();
    }
}

contract SolidStampRegister is Ownable
{
/// @dev address of the current SolidStamp contract which can add audits
    address public ContractSolidStamp;

    /// @dev const value to indicate the contract is not audited
    uint8 public constant NOT_AUDITED = 0x00;

    /// @dev const value to indicate the contract is audited and approved
    uint8 public constant AUDITED_AND_APPROVED = 0x01;

    /// @dev const value to indicate the contract is audited and rejected
    uint8 public constant AUDITED_AND_REJECTED = 0x02;

    /// @dev struct representing the audit report and the audit outcome
    struct Audit {
        /// @dev AUDITED_AND_APPROVED or AUDITED_AND_REJECTED
        uint8 outcome;
        /// @dev IPFS hash of the audit report
        bytes reportIPFS;
    }

    /// @dev Maps auditor and code hash to the Audit struct.
    /// Map key is: keccack256(auditor address, contract codeHash)
    /// @dev codeHash is a sha3 from the contract byte code
    mapping (bytes32 => Audit) public Audits;

    /// @dev event fired when a contract is sucessfully audited
    event AuditRegistered(address auditor, bytes32 codeHash, bytes reportIPFS, bool isApproved);

    /// @notice SolidStampRegister constructor
    constructor() public {
    }

    /// @notice returns the outcome of the audit or NOT_AUDITED (0) if none
    /// @param _auditor audtior address
    /// @param _codeHash contract code-hash
    function getAuditOutcome(address _auditor, bytes32 _codeHash) public view returns (uint8)
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        return Audits[hashAuditorCode].outcome;
    }

    /// @notice returns the audit report IPFS of the audit or 0x0 if none
    /// @param _auditor audtior address
    /// @param _codeHash contract code-hash
    function getAuditReportIPFS(address _auditor, bytes32 _codeHash) public view returns (bytes)
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        return Audits[hashAuditorCode].reportIPFS;
    }

    /// @notice marks contract as audited
    /// @param _codeHash the code hash of the stamped contract. _codeHash equals to sha3 of the contract byte-code
    /// @param _reportIPFS IPFS hash of the audit report
    /// @param _isApproved whether the contract is approved or rejected
    function registerAudit(bytes32 _codeHash, bytes _reportIPFS, bool _isApproved) public
    {
        require(_codeHash != 0x0, "codeHash cannot be 0x0");
        require(_reportIPFS.length != 0x0, "report IPFS cannot be 0x0");
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(msg.sender, _codeHash));

        Audit storage audit = Audits[hashAuditorCode];
        require(audit.outcome == NOT_AUDITED, "already audited");

        if ( _isApproved )
            audit.outcome = AUDITED_AND_APPROVED;
        else
            audit.outcome = AUDITED_AND_REJECTED;
        audit.reportIPFS = _reportIPFS;
        SolidStamp(ContractSolidStamp).auditContract(msg.sender, _codeHash, _reportIPFS, _isApproved);
        emit AuditRegistered(msg.sender, _codeHash, _reportIPFS, _isApproved);
    }

    /// @notice marks multiple contracts as audited
    /// @param _codeHashes the code hashes of the stamped contracts. each _codeHash equals to sha3 of the contract byte-code
    /// @param _reportIPFS IPFS hash of the audit report
    /// @param _isApproved whether the contracts are approved or rejected
    function registerAudits(bytes32[] _codeHashes, bytes _reportIPFS, bool _isApproved) public
    {
        for(uint i=0; i<_codeHashes.length; i++ )
        {
            registerAudit(_codeHashes[i], _reportIPFS, _isApproved);
        }
    }


    event SolidStampContractChanged(address newSolidStamp);

    /// @dev Transfers SolidStamp contract a _newSolidStamp.
    /// @param _newSolidStamp The address to transfer SolidStamp address to.
    function changeSolidStampContract(address _newSolidStamp) public onlyOwner {
      require(_newSolidStamp != address(0), "SolidStamp contract cannot be 0x0");
      emit SolidStampContractChanged(_newSolidStamp);
      ContractSolidStamp = _newSolidStamp;
    }

    /// @notice We don&#39;t want your arbitrary ether
    function() payable public {
        revert();
    }    
}