// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

// TODO refactor the whole thing to have a Hackathon factory and one contract per Hackathon
contract Hacka is Ownable, KeeperCompatibleInterface {
    bool private s_demoMode = false; // to be deleted
    uint private s_counter = 0;

    enum HackathonStage {NEW, STARTED, JUDGING, FINALIZED}

    struct HackathonMetadata {
        address organizer;
        uint timestampStart;
        uint timestampEnd;
        uint8 judgingPeriod;
        HackathonStage stage;
        string name;
        string url;
        uint balance;
        // TODO cid for description
    }

    struct HackathonSubmission {
        address payable participant;
        string name;
        string description; // TODO cid for description...
        uint hackathonId;
        uint[] prizes;
    }

    struct HackathonPrize {
        uint reward;
        address[] judges;
        string name;
        string description;
        uint[] submissions;
        mapping(uint => uint8) submissionScores;
        mapping(address => bool) isJudge;
        mapping(address => bool) alreadyVoted;
        address payable winner;
        bool finalized;
    }

    mapping(uint => HackathonMetadata) public s_hackathons;
    mapping(uint => HackathonPrize[]) public s_prizes;
    mapping(uint => HackathonSubmission[]) public s_submissions;
    mapping(address => uint[]) public s_organizerHackathons;

    event HackathonCreated(uint indexed hackathonId, address indexed organizer, string name, string url, uint timestampStart, uint timestampEnd, uint8 judgingPeriod);
    event HackathonChanged(uint indexed hackathonId, string name, string url, uint timestampStart, uint timestampEnd, uint8 judgingPeriod);
    event HackathonStageChanged(uint indexed hackathonId, HackathonStage previousStage, HackathonStage newStage);
    event HackathonSubmissionCreated(uint indexed submissionId, uint indexed hackathonId, address indexed participant, string name);
    event HackathonSubmissionAddedPrize(uint indexed submissionId, uint indexed hackathonId, uint indexed prizeId);
    event HackathonPrizeCreated(uint indexed hackathonId, uint indexed prizeId, uint reward, string name, string description);
    event HackathonPrizeJudgeAdded(uint indexed hackathonId, uint indexed prizeId, address judge);

    uint public immutable s_interval = 1 hours;
    uint public s_lastTimeStamp;

    function createHackathon(
        uint _timestampStart,
        uint _timestampEnd,
        string calldata _name,
        string calldata _url,
        uint8 _judgingPeriod
    ) external returns (uint hackathonId) {
        if (s_demoMode == false) {
            validateMetadata(
                _timestampStart,
                _timestampEnd,
                _name,
                _judgingPeriod,
                block.timestamp
            );
        }

        hackathonId = s_counter;
        s_counter = s_counter + 1;

        s_hackathons[hackathonId].organizer = msg.sender;
        s_hackathons[hackathonId].timestampStart = _timestampStart;
        s_hackathons[hackathonId].timestampEnd = _timestampEnd;
        s_hackathons[hackathonId].judgingPeriod = _judgingPeriod;
        s_hackathons[hackathonId].stage = HackathonStage.NEW;
        s_hackathons[hackathonId].name = _name;
        s_hackathons[hackathonId].url = _url;

        s_organizerHackathons[msg.sender].push(hackathonId);

        emit HackathonCreated(hackathonId, msg.sender, _name, _url, _timestampStart, _timestampEnd, _judgingPeriod);

        return hackathonId;
    }

    function updateHackathonMetadata(
        uint _hackathonId,
        uint _timestampStart,
        uint _timestampEnd,
        string calldata _name,
        string calldata _url,
        uint8 _judgingPeriod
    ) external {
        require(s_hackathons[_hackathonId].organizer == msg.sender, "Only hackathon's organizer can change its metadata");
        require(s_hackathons[_hackathonId].timestampStart - block.timestamp > 1 hours, "Hackathon metadata can be changed up until 1 hour before start");
        require(s_hackathons[_hackathonId].stage == HackathonStage.NEW, "Hackathon metadata can't change after it has started");
        validateMetadata(
            _timestampStart,
            _timestampEnd,
            _name,
            _judgingPeriod,
            block.timestamp
        );

        s_hackathons[_hackathonId].timestampStart = _timestampStart;
        s_hackathons[_hackathonId].timestampEnd = _timestampEnd;
        s_hackathons[_hackathonId].name = _name;
        s_hackathons[_hackathonId].url = _url;
        s_hackathons[_hackathonId].judgingPeriod = _judgingPeriod;

        emit HackathonChanged(_hackathonId, _name, _url, _timestampStart, _timestampStart, _judgingPeriod);
    }

    function updateHackathonStage(
        uint _hackathonId,
        HackathonStage _newStage
    ) internal {
        emit HackathonStageChanged(_hackathonId, s_hackathons[_hackathonId].stage, _newStage);
        s_hackathons[_hackathonId].stage = _newStage;
    }

    // TODO method to transfer hackathon ownership to another address (change organizer)

    function validateMetadata(
        uint _timestampStart,
        uint _timestampEnd,
        string calldata _name,
        uint8 _judgingPeriod,
        uint _currentTimestamp
    ) pure internal {
        require(_timestampEnd - _timestampStart > 1 days, "Hackathon must be at least 1 day long");
        require(_timestampStart - _currentTimestamp >= 1 days, "Hackathon start date must be at least 1 day in the future");
        require(_judgingPeriod >= 24, "Judging period must be at least 1 day (24 hours)");
        require(_judgingPeriod <= 168, "Judging period must not be longer than 7 days (168 hours)");
        require(bytes(_name).length >= 8, "Hackathon name must be at least 8 characters");
        require(bytes(_name).length <= 100, "Hackathon name must be at most 100 characters");
    }

    // TODO should accept other tokens, or more specifically - "Hackathon Token" ERC20, for now just use ETH
    function addPrize(
        uint256 _amount,
        uint _hackathonId,
        string calldata _name,
        string calldata _description
    ) external payable returns (uint prizeId) {
        require(msg.value == _amount);
        require(s_hackathons[_hackathonId].stage == HackathonStage.NEW, "Can't add a prize to an ongoing or finished hackathon");
        require(s_hackathons[_hackathonId].organizer == msg.sender, "Only hackathon's organizer can add a prize");
        require(bytes(_name).length > 8, "Prize name must be at least 8 characters");
        require(msg.value >= 0.0001 ether, "Minimum prize reward is 0.0001 ETH");

        s_hackathons[_hackathonId].balance += msg.value;

        uint prizeIdx = s_prizes[_hackathonId].length;
        s_prizes[_hackathonId].push();

        HackathonPrize storage prize = s_prizes[_hackathonId][prizeIdx];
        prize.reward = msg.value;
        prize.name = _name;
        prize.description = _description;

        emit HackathonPrizeCreated(_hackathonId, prizeIdx, _amount, _name, _description);

        return prizeIdx;
    }

    function addJudge(
        uint _hackathonId,
        uint _prizeId,
        address _judge
    ) external {
        require(s_hackathons[_hackathonId].organizer == msg.sender, "Only hackathon's organizer can add a judge");
        require(s_prizes[_hackathonId][_prizeId].reward > 0, "Prize not found");

        s_prizes[_hackathonId][_prizeId].judges.push(_judge);
        s_prizes[_hackathonId][_prizeId].isJudge[_judge] = true;
        emit HackathonPrizeJudgeAdded(_hackathonId, _prizeId, _judge);
    }

    function getHackathonsByOrganizer(
        address _organizer
    ) external view returns (uint[] memory) {
        return s_organizerHackathons[_organizer];
    }

    function getHackathonMetadata(uint _hackathonId) external view returns (HackathonMetadata memory) {
        return s_hackathons[_hackathonId];
    }

    // TODO delete for actual use! demo mode is to be able to skip date checks to create a demo hackathon
    function enableDemoMode() public onlyOwner {
        s_demoMode = true;
    }

    // TODO delete for actual use! demo mode is to be able to skip date checks to create a demo hackathon
    function disableDemoMode() public onlyOwner {
        s_demoMode = false;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool intervalPassed = s_demoMode || (block.timestamp - s_lastTimeStamp) > s_interval;
        bool hasHackathons = s_counter > 0;

        // TODO optimize - return IDs of hackathons that need to have their status changed! this way performUpkeep won't have to iterate all hackathons
        bool hasHackathonsPendingChange = false;
        for (uint id = 0; id < s_counter; id++) {
            if (s_hackathons[id].stage == HackathonStage.FINALIZED) {
                continue;
            }

            if (s_hackathons[id].stage == HackathonStage.NEW && block.timestamp > s_hackathons[id].timestampStart) {
                hasHackathonsPendingChange = true;
                break;
            }

            if (s_hackathons[id].stage == HackathonStage.STARTED && block.timestamp > s_hackathons[id].timestampEnd) {
                hasHackathonsPendingChange = true;
                break;
            }

            if (s_hackathons[id].stage == HackathonStage.JUDGING && block.timestamp > s_hackathons[id].timestampEnd + (s_hackathons[id].judgingPeriod * 1 hours)) {
                hasHackathonsPendingChange = true;
                break;
            }
        }

        upkeepNeeded = intervalPassed && hasHackathons && hasHackathonsPendingChange;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        s_lastTimeStamp = block.timestamp;
        for (uint id = 0; id < s_counter; id++) {
            if (s_hackathons[id].stage == HackathonStage.NEW && block.timestamp > s_hackathons[id].timestampStart) {
                updateHackathonStage(id, HackathonStage.STARTED);
                continue;
            }

            if (s_hackathons[id].stage == HackathonStage.STARTED && block.timestamp > s_hackathons[id].timestampEnd) {
                updateHackathonStage(id, HackathonStage.JUDGING);
                continue;
            }

            if (s_hackathons[id].stage == HackathonStage.JUDGING && block.timestamp > s_hackathons[id].timestampEnd + (s_hackathons[id].judgingPeriod * 1 hours)) {
                finalizeHackathon(id);
            }
        }
    }

    function finalizeHackathon(uint hackathonId) internal {
        for (uint prizeIdx = 0; prizeIdx < s_prizes[hackathonId].length; prizeIdx++) {
            uint maxScore = 0;
            uint winningSubmissionIdx = 0;
            for (uint submissionIdx = 0; submissionIdx < s_prizes[hackathonId][prizeIdx].submissions.length; submissionIdx++) {
                if (s_prizes[hackathonId][prizeIdx].submissionScores[submissionIdx] > maxScore) {
                    winningSubmissionIdx = submissionIdx;
                    maxScore = s_prizes[hackathonId][prizeIdx].submissionScores[submissionIdx];
                }
            }

            s_prizes[hackathonId][prizeIdx].finalized = true;

            // Clean, self-documenting code right here
            s_prizes[hackathonId][prizeIdx].winner = s_submissions[hackathonId][s_prizes[hackathonId][prizeIdx].submissions[winningSubmissionIdx]].participant;

            // TODO should not pay out directly, but rather have a "redeem" external function
            s_prizes[hackathonId][prizeIdx].winner.transfer(s_prizes[hackathonId][prizeIdx].reward);
            s_hackathons[hackathonId].balance -= s_prizes[hackathonId][prizeIdx].reward;
        }

        updateHackathonStage(hackathonId, HackathonStage.FINALIZED);
    }

    function submitProject(
        uint _hackathonId,
        string calldata _name,
        string calldata _description,
        uint[] calldata _prizes // add cid
    ) external {
        require(s_hackathons[_hackathonId].stage == HackathonStage.STARTED, "Hackathon doesn't accept submissions at this stage");
        require(bytes(_name).length >= 4, "Submission name must be at least 4 characters");
        require(_prizes.length >= 1, "You must apply for at least one prize");
        for (uint prizeIdx = 0; prizeIdx < _prizes.length; prizeIdx++) {
            require(_prizes[prizeIdx] < s_prizes[_hackathonId].length, "One of the prizes you applied for does not exist");
        }

        uint submissionId = s_submissions[_hackathonId].length;
        s_submissions[_hackathonId].push();

        HackathonSubmission storage submission = s_submissions[_hackathonId][submissionId];
        submission.participant = payable(msg.sender);
        submission.name = _name;
        submission.description = _description;
        submission.hackathonId = _hackathonId;
        for (uint prizeIdx = 0; prizeIdx < _prizes.length; prizeIdx++) {
            submission.prizes.push(_prizes[prizeIdx]);
            s_prizes[_hackathonId][_prizes[prizeIdx]].submissions.push(submissionId);
            emit HackathonSubmissionAddedPrize(submissionId, _hackathonId, _prizes[prizeIdx]);
        }

        emit HackathonSubmissionCreated(submissionId, _hackathonId, msg.sender, _name);
    }

    function voteOnProjects(
        uint _hackathonId,
        uint _prizeId,
        uint8[] calldata _votes
    ) external {
        require(s_hackathons[_hackathonId].stage == HackathonStage.JUDGING, "Hackathon is not in a judging stage");
        require(s_prizes[_hackathonId][_prizeId].isJudge[msg.sender] == true, "You are not this hackathon's judge");
        require(s_prizes[_hackathonId][_prizeId].alreadyVoted[msg.sender] == false, "You have already voted for this prize");
        require(_votes.length == s_prizes[_hackathonId][_prizeId].submissions.length, "You must provide a score for each submission");
        for (uint scoreIdx = 0; scoreIdx < _votes.length; scoreIdx++) {
            require(_votes[scoreIdx] >= 0, "Scores must be between 0 and 5");
            require(_votes[scoreIdx] <= 5, "Scores must be between 0 and 5");
            s_prizes[_hackathonId][_prizeId].submissionScores[scoreIdx] += _votes[scoreIdx];
        }

        s_prizes[_hackathonId][_prizeId].alreadyVoted[msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}