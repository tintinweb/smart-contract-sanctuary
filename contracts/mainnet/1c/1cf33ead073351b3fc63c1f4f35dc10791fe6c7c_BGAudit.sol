pragma solidity 0.4.24;

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

contract BGAudit is Ownable {

    using SafeMath for uint;

    event AddedAuditor(address indexed auditor);
    event BannedAuditor(address indexed auditor);
    event AllowedAuditor(address indexed auditor);

    event CreatedAudit(uint indexed id);
    event ReviewingAudit(uint indexed id);
    event AuditorRewarded(uint indexed id, address indexed auditor, uint indexed reward);

    event AuditorStaked(uint indexed id, address indexed auditor, uint indexed amount);
    event WithdrawedStake(uint indexed id, address indexed auditor, uint indexed amount);
    event SlashedStake(uint indexed id, address indexed auditor);

    enum AuditStatus { New, InProgress, InReview, Completed }

    struct Auditor {
        bool banned;
        address addr;
        uint totalEarned;
        uint completedAudits;
        uint[] stakedAudits; // array of audit IDs they&#39;ve staked
        mapping(uint => bool) stakedInAudit; // key is AuditID; useful so we don&#39;t need to loop through the audits array above
        mapping(uint => bool) canWithdrawStake; // Audit ID => can withdraw stake or not
    }

    struct Audit {
        AuditStatus status;
        address owner;
        uint id;
        uint totalReward; // total reward shared b/w all auditors
        uint remainingReward; // keep track of how much reward is left
        uint stake; // required stake for each auditor in wei
        uint endTime; // scheduled end time for the audit
        uint maxAuditors; // max auditors allowed for this Audit
        address[] participants; // array of auditor that have staked
    }

    //=== Storage
    uint public stakePeriod = 90 days; // number of days to wait before stake can be withdrawn
    uint public maxAuditDuration = 365 days; // max amount of time for a security audit
    Audit[] public audits;
    mapping(address => Auditor) public auditors;

    //=== Owner related
    function transfer(address _to, uint _amountInWei) external onlyOwner {
        require(address(this).balance > _amountInWei);
        _to.transfer(_amountInWei);
    }

    function setStakePeriod(uint _days) external onlyOwner {
        stakePeriod = _days * 1 days;
    }

    function setMaxAuditDuration(uint _days) external onlyOwner {
        maxAuditDuration = _days * 1 days;
    }


    //=== Auditors
    function addAuditor(address _auditor) external onlyOwner {
        require(auditors[_auditor].addr == address(0)); // Only add if they&#39;re not already added

        auditors[_auditor].banned = false;
        auditors[_auditor].addr = _auditor;
        auditors[_auditor].completedAudits = 0;
        auditors[_auditor].totalEarned = 0;
        emit AddedAuditor(_auditor);
    }

    function banAuditor(address _auditor) external onlyOwner {
        require(auditors[_auditor].addr != address(0));
        auditors[_auditor].banned = true;
        emit BannedAuditor(_auditor);
    }

    function allowAuditor(address _auditor) external onlyOwner {
        require(auditors[_auditor].addr != address(0));
        auditors[_auditor].banned = false;
        emit AllowedAuditor(_auditor);
    }


    //=== Audits and Rewards
    function createAudit(uint _stake, uint _endTimeInDays, uint _maxAuditors) external payable onlyOwner {
        uint endTime = _endTimeInDays * 1 days;
        require(endTime < maxAuditDuration);
        require(block.timestamp + endTime * 1 days > block.timestamp);
        require(msg.value > 0 && _maxAuditors > 0 && _stake > 0);

        Audit memory audit;
        audit.status = AuditStatus.New;
        audit.owner = msg.sender;
        audit.id = audits.length;
        audit.totalReward = msg.value;
        audit.remainingReward = audit.totalReward;
        audit.stake = _stake;
        audit.endTime = block.timestamp + endTime;
        audit.maxAuditors = _maxAuditors;

        audits.push(audit); // push into storage
        emit CreatedAudit(audit.id);
    }

    function reviewAudit(uint _id) external onlyOwner {
        require(audits[_id].status == AuditStatus.InProgress);
        require(block.timestamp >= audits[_id].endTime);
        audits[_id].endTime = block.timestamp; // override the endTime to when it actually ended
        audits[_id].status = AuditStatus.InReview;
        emit ReviewingAudit(_id);
    }

    function rewardAuditor(uint _id, address _auditor, uint _reward) external onlyOwner {

        audits[_id].remainingReward.sub(_reward);
        audits[_id].status = AuditStatus.Completed;

        auditors[_auditor].totalEarned.add(_reward);
        auditors[_auditor].completedAudits.add(1);
        auditors[_auditor].canWithdrawStake[_id] = true; // allow them to withdraw their stake after stakePeriod
        _auditor.transfer(_reward);
        emit AuditorRewarded(_id, _auditor, _reward);
    }

    function slashStake(uint _id, address _auditor) external onlyOwner {
        require(auditors[_auditor].addr != address(0));
        require(auditors[_auditor].stakedInAudit[_id]); // participated in audit
        auditors[_auditor].canWithdrawStake[_id] = false;
        emit SlashedStake(_id, _auditor);
    }

    //=== User Actions
    function stake(uint _id) public payable {
        // Check conditions of the Audit
        require(msg.value == audits[_id].stake);
        require(block.timestamp < audits[_id].endTime);
        require(audits[_id].participants.length < audits[_id].maxAuditors);
        require(audits[_id].status == AuditStatus.New || audits[_id].status == AuditStatus.InProgress);

        // Check conditions of the Auditor
        require(auditors[msg.sender].addr == msg.sender && !auditors[msg.sender].banned); // auditor is authorized
        require(!auditors[msg.sender].stakedInAudit[_id]); //check if auditor has staked for this audit already

        // Update audit&#39;s states
        audits[_id].status = AuditStatus.InProgress;
        audits[_id].participants.push(msg.sender);

        // Update auditor&#39;s states
        auditors[msg.sender].stakedInAudit[_id] = true;
        auditors[msg.sender].stakedAudits.push(_id);
        emit AuditorStaked(_id, msg.sender, msg.value);
    }

    function withdrawStake(uint _id) public {
        require(audits[_id].status == AuditStatus.Completed);
        require(auditors[msg.sender].canWithdrawStake[_id]);
        require(block.timestamp >= audits[_id].endTime + stakePeriod);

        auditors[msg.sender].canWithdrawStake[_id] = false; //prevent replay attack
        address(msg.sender).transfer(audits[_id].stake); // do this last to prevent re-entrancy
        emit WithdrawedStake(_id, msg.sender, audits[_id].stake);
    }

    //=== Getters
    function auditorHasStaked(uint _id, address _auditor) public view returns(bool) {
        return auditors[_auditor].stakedInAudit[_id];
    }

    function auditorCanWithdrawStake(uint _id, address _auditor) public view returns(bool) {
        if(auditors[_auditor].stakedInAudit[_id] && auditors[_auditor].canWithdrawStake[_id]) {
            return true;
        }
        return false;
    }

    // return a list of ids that _auditor has staked in
    function getStakedAudits(address _auditor) public view returns(uint[]) {
        return auditors[_auditor].stakedAudits;
    }

    // return a list of auditors that participated in this audit
    function getAuditors(uint _id) public view returns(address[]) {
        return audits[_id].participants;
    }
}