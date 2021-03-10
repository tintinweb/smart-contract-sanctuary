// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { IStorageStateCommittee } from "IStorageStateCommittee.sol";

interface IDAOCommittee is IStorageStateCommittee {
    //--owner
    function setSeigManager(address _seigManager) external;
    function setCandidatesSeigManager(address[] calldata _candidateContracts, address _seigManager) external;
    function setCandidatesCommittee(address[] calldata _candidateContracts, address _committee) external;
    function setLayer2Registry(address _layer2Registry) external;
    function setAgendaManager(address _agendaManager) external;
    function setCandidateFactory(address _candidateFactory) external;
    function setTon(address _ton) external;
    function setActivityRewardPerSecond(uint256 _value) external;
    function setDaoVault(address _daoVault) external;

    function increaseMaxMember(uint256 _newMaxMember, uint256 _quorum) external;
    function decreaseMaxMember(uint256 _reducingMemberIndex, uint256 _quorum) external;
    function createCandidate(string calldata _memo) external;
    function registerLayer2Candidate(address _layer2, string memory _memo) external;
    function registerLayer2CandidateByOwner(address _operator, address _layer2, string memory _memo) external;
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function setMemoOnCandidate(address _candidate, string calldata _memo) external;
    function setMemoOnCandidateContract(address _candidate, string calldata _memo) external;

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    )
        external
        returns (bool);

    function setQuorum(uint256 _quorum) external;
    function setCreateAgendaFees(uint256 _fees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriod) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriod) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function castVote(uint256 _AgendaID, uint256 _vote, string calldata _comment) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function executeAgenda(uint256 _AgendaID) external;
    function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) external;

    function updateSeigniorage(address _candidate) external returns (bool);
    function updateSeigniorages(address[] calldata _candidates) external returns (bool);
    function claimActivityReward(address _receiver) external;

    function isCandidate(address _candidate) external view returns (bool);
    function totalSupplyOnCandidate(address _candidate) external view returns (uint256);
    function balanceOfOnCandidate(address _candidate, address _account) external view returns (uint256);
    function totalSupplyOnCandidateContract(address _candidateContract) external view returns (uint256);
    function balanceOfOnCandidateContract(address _candidateContract, address _account) external view returns (uint256);
    function candidatesLength() external view returns (uint256);
    function isExistCandidate(address _candidate) external view returns (bool);
    function getClaimableActivityReward(address _candidate) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

library LibAgenda {
    //using LibAgenda for Agenda;

    enum AgendaStatus { NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED }
    enum AgendaResult { PENDING, ACCEPT, REJECT, DISMISS }

    //votor : based operator 
    struct Voter {
        bool isVoter;
        bool hasVoted;
        uint256 vote;
    }

    // counting abstainVotes yesVotes noVotes
    struct Agenda {
        uint256 createdTimestamp;
        uint256 noticeEndTimestamp;
        uint256 votingPeriodInSeconds;
        uint256 votingStartedTimestamp;
        uint256 votingEndTimestamp;
        uint256 executableLimitTimestamp;
        uint256 executedTimestamp;
        uint256 countingYes;
        uint256 countingNo;
        uint256 countingAbstain;
        AgendaStatus status;
        AgendaResult result;
        address[] voters;
        bool executed;
    }

    struct AgendaExecutionInfo {
        address[] targets;
        bytes[] functionBytecodes;
        bool atomicExecute;
        uint256 executeStartFrom;
    }

    /*function getAgenda(Agenda[] storage agendas, uint256 index) public view returns (Agenda storage agenda) {
        return agendas[index];
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "SafeMath.sol";
import { IERC20 } from  "IERC20.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";
import { ICandidate } from "ICandidate.sol";
import { LibAgenda } from "LibAgenda.sol";
import "Ownable.sol";

contract DAOAgendaManager is Ownable, IDAOAgendaManager {
    using SafeMath for uint256;
    using LibAgenda for *;

    enum VoteChoice { ABSTAIN, YES, NO, MAX }

    IDAOCommittee public override committee;
    
    uint256 public override createAgendaFees;
    
    uint256 public override minimumNoticePeriodSeconds;
    uint256 public override minimumVotingPeriodSeconds;
    uint256 public override executingPeriodSeconds;
    
    LibAgenda.Agenda[] internal _agendas;
    mapping(uint256 => mapping(address => LibAgenda.Voter)) internal _voterInfos;
    mapping(uint256 => LibAgenda.AgendaExecutionInfo) internal _executionInfos;
    
    event AgendaStatusChanged(
        uint256 indexed agendaID,
        uint256 prevStatus,
        uint256 newStatus
    );

    event AgendaResultChanged(
        uint256 indexed agendaID,
        uint256 result
    );

    event CreatingAgendaFeeChanged(
        uint256 newFee
    );

    event MinimumNoticePeriodChanged(
        uint256 newPeriod
    );

    event MinimumVotingPeriodChanged(
        uint256 newPeriod
    );

    event ExecutingPeriodChanged(
        uint256 newPeriod
    );

    modifier validAgenda(uint256 _agendaID) {
        require(_agendaID < _agendas.length, "DAOAgendaManager: invalid agenda id");
        _;
    }
    
    constructor() {
        minimumNoticePeriodSeconds = 16 days;
        minimumVotingPeriodSeconds = 2 days;
        executingPeriodSeconds = 7 days;
        
        createAgendaFees = 100000000000000000000; // 100 TON
    }

    function getStatus(uint256 _status) public pure override returns (LibAgenda.AgendaStatus emnustatus) {
        require(_status < 6, "DAOAgendaManager: invalid status value");
        if (_status == uint256(LibAgenda.AgendaStatus.NOTICE))
            return LibAgenda.AgendaStatus.NOTICE;
        else if (_status == uint256(LibAgenda.AgendaStatus.VOTING))
            return LibAgenda.AgendaStatus.VOTING;
        else if (_status == uint256(LibAgenda.AgendaStatus.EXECUTED))
            return LibAgenda.AgendaStatus.EXECUTED;
        else if (_status == uint256(LibAgenda.AgendaStatus.ENDED))
            return LibAgenda.AgendaStatus.ENDED;
        else
            return LibAgenda.AgendaStatus.NONE;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @param _committee New DAOCommitteeProxy contract address
    function setCommittee(address _committee) external override onlyOwner {
        require(_committee != address(0), "DAOAgendaManager: address is zero");
        committee = IDAOCommittee(_committee);
    }

    /// @notice Set the fee(TON) of creating an agenda
    /// @param _createAgendaFees New fee(TON)
    function setCreateAgendaFees(uint256 _createAgendaFees) external override onlyOwner {
        createAgendaFees = _createAgendaFees;
        emit CreatingAgendaFeeChanged(_createAgendaFees);
    }

    /// @notice Set the minimum notice period in seconds
    /// @param _minimumNoticePeriodSeconds New minimum notice period in seconds
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external override onlyOwner {
        minimumNoticePeriodSeconds = _minimumNoticePeriodSeconds;
        emit MinimumNoticePeriodChanged(_minimumNoticePeriodSeconds);
    }

    /// @notice Set the executing period in seconds
    /// @param _executingPeriodSeconds New executing period in seconds
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external override onlyOwner {
        executingPeriodSeconds = _executingPeriodSeconds;
        emit ExecutingPeriodChanged(_executingPeriodSeconds);
    }

    /// @notice Set the minimum voting period in seconds
    /// @param _minimumVotingPeriodSeconds New minimum voting period in seconds
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external override onlyOwner {
        minimumVotingPeriodSeconds = _minimumVotingPeriodSeconds;
        emit MinimumVotingPeriodChanged(_minimumVotingPeriodSeconds);
    }
      
    /// @notice Creates an agenda
    /// @param _targets Target addresses for executions of the agenda
    /// @param _noticePeriodSeconds Notice period in seconds
    /// @param _votingPeriodSeconds Voting period in seconds
    /// @param _functionBytecodes RLP-Encoded parameters for executions of the agenda
    /// @return agendaID Created agenda ID
    function newAgenda(
        address[] calldata _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        override
        onlyOwner
        returns (uint256 agendaID)
    {
        require(
            _noticePeriodSeconds >= minimumNoticePeriodSeconds,
            "DAOAgendaManager: minimumNoticePeriod is short"
        );

        agendaID = _agendas.length;
         
        address[] memory emptyArray;
        _agendas.push(LibAgenda.Agenda({
            status: LibAgenda.AgendaStatus.NOTICE,
            result: LibAgenda.AgendaResult.PENDING,
            executed: false,
            createdTimestamp: block.timestamp,
            noticeEndTimestamp: block.timestamp + _noticePeriodSeconds,
            votingPeriodInSeconds: _votingPeriodSeconds,
            votingStartedTimestamp: 0,
            votingEndTimestamp: 0,
            executableLimitTimestamp: 0,
            executedTimestamp: 0,
            countingYes: 0,
            countingNo: 0,
            countingAbstain: 0,
            voters: emptyArray
        }));

        LibAgenda.AgendaExecutionInfo storage executionInfo = _executionInfos[agendaID];
        executionInfo.atomicExecute = _atomicExecute;
        executionInfo.executeStartFrom = 0;
        for (uint256 i = 0; i < _targets.length; i++) {
            executionInfo.targets.push(_targets[i]);
            executionInfo.functionBytecodes.push(_functionBytecodes[i]);
        }
    }

    /// @notice Casts vote for an agenda
    /// @param _agendaID Agenda ID
    /// @param _voter Voter
    /// @param _vote Voting type
    /// @return Whether or not the execution succeeded
    function castVote(
        uint256 _agendaID,
        address _voter,
        uint256 _vote
    )
        external
        override
        onlyOwner
        validAgenda(_agendaID)
        returns (bool)
    {
        require(_vote < uint256(VoteChoice.MAX), "DAOAgendaManager: invalid vote");

        require(
            isVotableStatus(_agendaID),
            "DAOAgendaManager: invalid status"
        );

        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        if (agenda.status == LibAgenda.AgendaStatus.NOTICE) {
            _startVoting(_agendaID);
        }

        require(isVoter(_agendaID, _voter), "DAOAgendaManager: not a voter");
        require(!hasVoted(_agendaID, _voter), "DAOAgendaManager: already voted");

        require(
            block.timestamp <= agenda.votingEndTimestamp,
            "DAOAgendaManager: for this agenda, the voting time expired"
        );
        
        LibAgenda.Voter storage voter = _voterInfos[_agendaID][_voter];
        voter.hasVoted = true;
        voter.vote = _vote;
             
        // counting 0:abstainVotes 1:yesVotes 2:noVotes
        if (_vote == uint256(VoteChoice.ABSTAIN))
            agenda.countingAbstain = agenda.countingAbstain.add(1);
        else if (_vote == uint256(VoteChoice.YES))
            agenda.countingYes = agenda.countingYes.add(1);
        else if (_vote == uint256(VoteChoice.NO))
            agenda.countingNo = agenda.countingNo.add(1);
        else
            revert("DAOAgendaManager: invalid voting");
        
        return true;
    }
    
    /// @notice Set the agenda status as executed
    /// @param _agendaID Agenda ID
    function setExecutedAgenda(uint256 _agendaID)
        external
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        agenda.executed = true;
        agenda.executedTimestamp = block.timestamp;

        uint256 prevStatus = uint256(agenda.status);
        agenda.status = LibAgenda.AgendaStatus.EXECUTED;
        emit AgendaStatusChanged(_agendaID, prevStatus, uint256(LibAgenda.AgendaStatus.EXECUTED));
    }

    /// @notice Set the agenda result
    /// @param _agendaID Agenda ID
    /// @param _result New result
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result)
        public
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        agenda.result = _result;

        emit AgendaResultChanged(_agendaID, uint256(_result));
    }
     
    /// @notice Set the agenda status
    /// @param _agendaID Agenda ID
    /// @param _status New status
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status)
        public
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        uint256 prevStatus = uint256(agenda.status);
        agenda.status = _status;
        emit AgendaStatusChanged(_agendaID, prevStatus, uint256(_status));
    }

    /// @notice Set the agenda status as ended(denied or dismissed)
    /// @param _agendaID Agenda ID
    function endAgendaVoting(uint256 _agendaID)
        external
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        require(
            agenda.status == LibAgenda.AgendaStatus.VOTING,
            "DAOAgendaManager: agenda status is not changable"
        );

        require(
            agenda.votingEndTimestamp <= block.timestamp,
            "DAOAgendaManager: voting is not ended yet"
        );

        setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
    }
     
    function _startVoting(uint256 _agendaID) internal validAgenda(_agendaID) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        agenda.votingStartedTimestamp = block.timestamp;
        agenda.votingEndTimestamp = block.timestamp.add(agenda.votingPeriodInSeconds);
        agenda.executableLimitTimestamp = agenda.votingEndTimestamp.add(executingPeriodSeconds);
        agenda.status = LibAgenda.AgendaStatus.VOTING;

        uint256 memberCount = committee.maxMember();
        for (uint256 i = 0; i < memberCount; i++) {
            address voter = committee.members(i);
            agenda.voters.push(voter);
            _voterInfos[_agendaID][voter].isVoter = true;
        }

        emit AgendaStatusChanged(_agendaID, uint256(LibAgenda.AgendaStatus.NOTICE), uint256(LibAgenda.AgendaStatus.VOTING));
    }
    
    function isVoter(uint256 _agendaID, address _candidate) public view override validAgenda(_agendaID) returns (bool) {
        require(_candidate != address(0), "DAOAgendaManager: user address is zero");
        return _voterInfos[_agendaID][_candidate].isVoter;
    }
    
    function hasVoted(uint256 _agendaID, address _user) public view override validAgenda(_agendaID) returns (bool) {
        return _voterInfos[_agendaID][_user].hasVoted;
    }

    function getVoteStatus(uint256 _agendaID, address _user) external view override validAgenda(_agendaID) returns (bool, uint256) {
        LibAgenda.Voter storage voter = _voterInfos[_agendaID][_user];

        return (
            voter.hasVoted,
            voter.vote
        );
    }
    
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].noticeEndTimestamp;
    }
    
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].votingStartedTimestamp;
    }

    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].votingEndTimestamp;
    }

    function canExecuteAgenda(uint256 _agendaID) external view override validAgenda(_agendaID) returns (bool) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        return agenda.status == LibAgenda.AgendaStatus.WAITING_EXEC &&
            block.timestamp <= agenda.executableLimitTimestamp &&
            agenda.result == LibAgenda.AgendaResult.ACCEPT &&
            agenda.votingEndTimestamp <= block.timestamp &&
            agenda.executed == false;
    }
    
    function getAgendaStatus(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256 status) {
        return uint256(_agendas[_agendaID].status);
    }

    function totalAgendas() external view override returns (uint256) {
        return _agendas.length;
    }

    function getAgendaResult(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256 result, bool executed) {
        return (uint256(_agendas[_agendaID].result), _agendas[_agendaID].executed);
    }
   
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        override
        validAgenda(_agendaID)
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        )
    {
        LibAgenda.AgendaExecutionInfo storage agenda = _executionInfos[_agendaID];
        return (
            agenda.targets,
            agenda.functionBytecodes,
            agenda.atomicExecute,
            agenda.executeStartFrom
        );
    }

    function setExecutedCount(uint256 _agendaID, uint256 _count) external override {
        LibAgenda.AgendaExecutionInfo storage agenda = _executionInfos[_agendaID];
        agenda.executeStartFrom = agenda.executeStartFrom.add(_count);
    }

    function isVotableStatus(uint256 _agendaID) public view override validAgenda(_agendaID) returns (bool) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        return block.timestamp <= agenda.votingEndTimestamp ||
            (agenda.status == LibAgenda.AgendaStatus.NOTICE &&
                agenda.noticeEndTimestamp <= block.timestamp);
    }

    function getVotingCount(uint256 _agendaID)
        external
        view
        override
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        )
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        return (
            agenda.countingYes,
            agenda.countingNo,
            agenda.countingAbstain
        );
    }

    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        override
        validAgenda(_agendaID)
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        )
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        return (
            agenda.createdTimestamp,
            agenda.noticeEndTimestamp,
            agenda.votingStartedTimestamp,
            agenda.votingEndTimestamp,
            agenda.executedTimestamp
        );
    }

    function numAgendas() external view override returns (uint256) {
        return _agendas.length;
    }

    function getVoters(uint256 _agendaID) external view override validAgenda(_agendaID) returns (address[] memory) {
        return _agendas[_agendaID].voters;
    }

    function agendas(uint256 _index) external view override validAgenda(_index) returns (LibAgenda.Agenda memory) {
        return _agendas[_index];
    }

    function voterInfos(uint256 _agendaID, address _voter) external view override validAgenda(_agendaID) returns (LibAgenda.Voter memory) {
        return _voterInfos[_agendaID][_voter];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IDAOCommittee } from "IDAOCommittee.sol";
import { ISeigManager } from "ISeigManager.sol";

interface ICandidate {
    function setSeigManager(address _seigMan) external;
    function setCommittee(address _committee) external;
    function updateSeigniorage() external returns (bool);
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function castVote(uint256 _agendaID, uint256 _vote, string calldata _comment) external;
    function isCandidateContract() external view returns (bool);
    function totalStaked() external view returns (uint256 totalsupply);
    function stakedOf(address _account) external view returns (uint256 amount);
    function setMemo(string calldata _memo) external;
    function claimActivityReward() external;

    // getter
    function candidate() external view returns (address);
    function isLayer2Candidate() external view returns (bool);
    function memo() external view returns (string memory);
    function committee() external view returns (IDAOCommittee);
    function seigManager() external view returns (ISeigManager);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ISeigManager {
    function registry() external view returns (address);
    function depositManager() external view returns (address);
    function ton() external view returns (address);
    function wton() external view returns (address);
    function powerton() external view returns (address);
    function tot() external view returns (address);
    function coinages(address layer2) external view returns (address);
    function commissionRates(address layer2) external view returns (uint256);

    function lastCommitBlock(address layer2) external view returns (uint256);
    function seigPerBlock() external view returns (uint256);
    function lastSeigBlock() external view returns (uint256);
    function pausedBlock() external view returns (uint256);
    function unpausedBlock() external view returns (uint256);
    function DEFAULT_FACTOR() external view returns (uint256);

    function deployCoinage(address layer2) external returns (bool);
    function setCommissionRate(address layer2, uint256 commission, bool isCommissionRateNegative) external returns (bool);

    function uncomittedStakeOf(address layer2, address account) external view returns (uint256);
    function stakeOf(address layer2, address account) external view returns (uint256);
    function additionalTotBurnAmount(address layer2, address account, uint256 amount) external view returns (uint256 totAmount);

    function onTransfer(address sender, address recipient, uint256 amount) external returns (bool);
    function updateSeigniorage() external returns (bool);
    function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { ICandidateFactory } from "ICandidateFactory.sol";
import { ILayer2Registry } from "ILayer2Registry.sol";
import { ISeigManager } from "ISeigManager.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOVault } from "IDAOVault.sol";

interface IStorageStateCommittee {
    struct CandidateInfo {
        address candidateContract;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    function ton() external returns (address);
    function daoVault() external returns (IDAOVault);
    function agendaManager() external returns (IDAOAgendaManager);
    function candidateFactory() external returns (ICandidateFactory);
    function layer2Registry() external returns (ILayer2Registry);
    function seigManager() external returns (ISeigManager);
    function candidates(uint256 _index) external returns (address);
    function members(uint256 _index) external returns (address);
    function maxMember() external returns (uint256);
    function candidateInfos(address _candidate) external returns (CandidateInfo memory);
    function quorum() external returns (uint256);
    function activityRewardPerSecond() external returns (uint256);

    function isMember(address _candidate) external returns (bool);
    function candidateContract(address _candidate) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ICandidateFactory {
    function deploy(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    )
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2Registry {
    function layer2s(address layer2) external view returns (bool);

    function register(address layer2) external returns (bool);
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);

    function deployCoinage(address layer2, address seigManager) external returns (bool);
    function registerAndDeployCoinage(address layer2, address seigManager) external returns (bool);
    function unregister(address layer2) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IDAOVault {
    function setTON(address _ton) external;
    function setWTON(address _wton) external;
    function approveTON(address _to, uint256 _amount) external;
    function approveWTON(address _to, uint256 _amount) external;
    function approveERC20(address _token, address _to, uint256 _amount) external;
    function claimTON(address _to, uint256 _amount) external;
    function claimWTON(address _to, uint256 _amount) external;
    function claimERC20(address _token, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { LibAgenda } from "LibAgenda.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";

interface IDAOAgendaManager  {
    struct Ratio {
        uint256 numerator;
        uint256 denominator;
    }

    function setCommittee(address _committee) external;
    function setCreateAgendaFees(uint256 _createAgendaFees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function newAgenda(
        address[] memory _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        returns (uint256 agendaID);
    function castVote(uint256 _agendaID, address voter, uint256 _vote) external returns (bool);
    function setExecutedAgenda(uint256 _agendaID) external;
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result) external;
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function setExecutedCount(uint256 _agendaID, uint256 _count) external;
     
    // -- view functions
    function isVoter(uint256 _agendaID, address _user) external view returns (bool);
    function hasVoted(uint256 _agendaID, address _user) external view returns (bool);
    function getVoteStatus(uint256 _agendaID, address _user) external view returns (bool, uint256);
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view returns (uint256) ;

    function canExecuteAgenda(uint256 _agendaID) external view returns (bool);
    function getAgendaStatus(uint256 _agendaID) external view returns (uint256 status);
    function totalAgendas() external view returns (uint256);
    function getAgendaResult(uint256 _agendaID) external view returns (uint256 result, bool executed);
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        );
    function isVotableStatus(uint256 _agendaID) external view returns (bool);
    function getVotingCount(uint256 _agendaID)
        external
        view
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        );
    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        );
    function numAgendas() external view returns (uint256);
    function getVoters(uint256 _agendaID) external view returns (address[] memory);

    function getStatus(uint256 _createAgendaFees) external pure returns (LibAgenda.AgendaStatus);

    // getter
    function committee() external view returns (IDAOCommittee);
    function createAgendaFees() external view returns (uint256);
    function minimumNoticePeriodSeconds() external view returns (uint256);
    function minimumVotingPeriodSeconds() external view returns (uint256);
    function executingPeriodSeconds() external view returns (uint256);
    function agendas(uint256 _index) external view returns (LibAgenda.Agenda memory);
    function voterInfos(uint256 _index1, address _index2) external view returns (LibAgenda.Voter memory);
}