// SolidStamp contract for https://www.solidstamp.com
// The source code is available at https://github.com/SolidStamp/smart-contract/

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

pragma solidity ^0.4.23;

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

pragma solidity ^0.4.23;


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

pragma solidity ^0.4.23;

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

pragma solidity ^0.4.24;

contract SolidStampRegister is Ownable
{
/// @dev address of the current SolidStamp contract which can add audits
    address public contractSolidStamp;

    /// @dev const value to indicate the contract is audited and approved
    uint8 public constant NOT_AUDITED = 0x00;

    /// @dev const value to indicate the contract is audited and approved
    uint8 public constant AUDITED_AND_APPROVED = 0x01;

    /// @dev const value to indicate the contract is audited and rejected
    uint8 public constant AUDITED_AND_REJECTED = 0x02;

    /// @dev Maps auditor and code hash to the outcome of the audit of
    /// the particular contract by the particular auditor.
    /// Map key is: keccack256(auditor address, contract codeHash)
    /// @dev codeHash is a sha3 from the contract byte code
    mapping (bytes32 => uint8) public AuditOutcomes;

    /// @dev event fired when a contract is sucessfully audited
    event AuditRegistered(address auditor, bytes32 codeHash, bool isApproved);

    /// @notice SolidStampRegister constructor
    /// @dev import audits from the SolidStamp v1 contract deployed to: 0x0aA7A4482780F67c6B2862Bd68CD67A83faCe355
    /// @param _existingAuditors list of existing auditors
    /// @param _existingCodeHashes list of existing code hashes
    /// @param _outcomes list of existing audit outcomes
    /// @dev each n-th element represents an existing audit conducted by _existingAuditors[n]
    /// on code hash _existingCodeHashes[n] with an outcome _outcomes[n]
    constructor(address[] _existingAuditors, bytes32[] _existingCodeHashes, bool[] _outcomes) public {
        uint noOfExistingAudits = _existingAuditors.length;
        require(noOfExistingAudits == _existingCodeHashes.length, "paramters mismatch");
        require(noOfExistingAudits == _outcomes.length, "paramters mismatch");

        // set contract address temporarily to owner so that registerAuditOutcome does not revert
        contractSolidStamp = msg.sender;
        for (uint i=0; i<noOfExistingAudits; i++){
            registerAuditOutcome(_existingAuditors[i], _existingCodeHashes[i], _outcomes[i]);
        }
        contractSolidStamp = 0x0;
    }

    function getAuditOutcome(address _auditor, bytes32 _codeHash) public view returns (uint8)
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        return AuditOutcomes[hashAuditorCode];
    }

    function registerAuditOutcome(address _auditor, bytes32 _codeHash, bool _isApproved) public onlySolidStampContract
    {
        require(_auditor != 0x0, "auditor cannot be 0x0");
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        if ( _isApproved )
            AuditOutcomes[hashAuditorCode] = AUDITED_AND_APPROVED;
        else
            AuditOutcomes[hashAuditorCode] = AUDITED_AND_REJECTED;
        emit AuditRegistered(_auditor, _codeHash, _isApproved);
    }


    event SolidStampContractChanged(address newSolidStamp);
    /**
     * @dev Throws if called by any account other than the contractSolidStamp
     */
    modifier onlySolidStampContract() {
      require(msg.sender == contractSolidStamp, "cannot be run by not SolidStamp contract");
      _;
    }

    /**
     * @dev Transfers control of the registry to a _newSolidStamp.
     * @param _newSolidStamp The address to transfer control registry to.
     */
    function changeSolidStampContract(address _newSolidStamp) public onlyOwner {
      require(_newSolidStamp != address(0), "SolidStamp contract cannot be 0x0");
      emit SolidStampContractChanged(_newSolidStamp);
      contractSolidStamp = _newSolidStamp;
    }

}

pragma solidity ^0.4.24;

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

    // @dev commission percentage, initially 9%
    uint public Commission = 9;

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
    event ContractAudited(address auditor, bytes32 codeHash, uint reward, bool isApproved);

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

    /// @notice marks contract as audited
    /// @param _codeHash the code hash of the stamped contract. _codeHash equals to sha3 of the contract byte-code
    /// @param _isApproved whether the contract is approved or rejected
    function auditContract(bytes32 _codeHash, bool _isApproved)
    public whenNotPaused
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(msg.sender, _codeHash));

        // revert if the contract is already audited by the auditor
        uint8 outcome = SolidStampRegister(SolidStampRegisterAddress).getAuditOutcome(msg.sender, _codeHash);
        require(outcome == NOT_AUDITED, "contract already audited");

        SolidStampRegister(SolidStampRegisterAddress).registerAuditOutcome(msg.sender, _codeHash, _isApproved);
        uint reward = Rewards[hashAuditorCode];
        TotalRequestsAmount = TotalRequestsAmount.sub(reward);
        uint commissionKept = calcCommission(reward);
        AvailableCommission = AvailableCommission.add(commissionKept);
        emit ContractAudited(msg.sender, _codeHash, reward, _isApproved);
        msg.sender.transfer(reward.sub(commissionKept));
    }

    /// @dev const value to indicate the maximum commision service owner can set
    uint public constant MAX_COMMISSION = 33;

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

    /// @notice We don&#39;t welcome tips & donations
    function() payable public {
        revert();
    }
}