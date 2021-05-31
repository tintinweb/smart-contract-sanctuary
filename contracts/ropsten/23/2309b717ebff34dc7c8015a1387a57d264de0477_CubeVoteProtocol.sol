/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: contracts/ICubeVoteProtocol.sol

pragma solidity ^0.8.0;

/// @title CubeVoteProtocol interface.
interface ICubeVoteProtocol {
    /// Emitted when new voting is created with `id`, `name` and from `address`.
    event VotingCreated(uint256 indexed id, string name, address owner);
    
    /// Emitted when new voter voted on the voting with `id`, from address `voter` and for candidate with `id`.
    event VoterVoted(uint256 indexed id, address indexed voter, uint256 indexed candidateId );
    
    /// Emitted when owner calls announce winner with `id` and `candidateId`, if tie sent true and 0 candidateId
    event WinnerAnnounced(uint256 indexed id, uint256 indexed candidateId, bool indexed tie);

    /// @dev Contains information about voting
    struct Voting{
        uint64 startTime;
        uint64 endTime;
        string name;
        string description;
        address owner;
        address[] voters;
        string[] candidates;
    }

    /// @notice Create new voting.
    /// @dev Will emit VotingCreated. Creator becomes owner of that voting.
    /// @param _newVoting New Voting struct.
    /// @return True if creation success.
    function createVoting(Voting memory _newVoting) external returns(bool);
    
    /// @notice Cast vote.
    /// @dev Will emit VoterVoted when mixer emits. Can be called from admitted addresses
    /// @param _votingNum Voting id.
    /// @param _candidateNum Number of chosen candidate.
    /// @return True if vote was successful.
    function vote(uint256 _votingNum, uint256 _candidateNum) external returns(bool);
        
    /// @notice Admit voter to the voting.
    /// @dev Will not emit anything. Can be called by the owner of the voting.
    /// @param _votingNum Voting id.
    /// @param _voter Address of the voter to admit.
    /// @return True if admitting was successful.
    function admitVoter(uint256 _votingNum, address _voter) external returns(bool);
    
    /// @notice Exclude voter from the voting.
    /// @dev Will not emit anything. Can be called by the owner of the voting.
    /// @param _votingNum Voting id.
    /// @param _voter Address of the voter to exclude.
    /// @return True if excluding was successful.
    function excludeVoter(uint256 _votingNum, address _voter) external returns(bool);

    /// @notice Announce winner of the voting.
    /// @dev Will emit WinnerAnnounced. Can be called by the owner of the voting.
    /// @param _votingNum Voting id.
    /// @return True if announcing was successful.
    function announceWinner(uint256 _votingNum) external returns(bool);
}

// File: contracts/CubeVoteProtocol.sol

pragma solidity ^0.8.0;



/// @title CubeVoteProtocol contract.
contract CubeVoteProtocol is ICubeVoteProtocol, Ownable {
    uint256 public votingCount = 0;
    mapping(uint256 => Voting) public votings;

    mapping(uint256 => mapping(address => bool)) isAdmitted;

    mapping(uint256 => mapping(address => bool)) voterVoted;

    mapping(uint256 => mapping(address => uint256)) votes;

    mapping(uint256 => mapping(string => uint256)) voteCount;

    mapping(uint256 => bool) winnerAnnounced;

    mapping(uint256 => bool) winnerTie;

    mapping(uint256 => uint256) winner;

    function createVoting(Voting memory _newVoting) external override returns (bool){
        require(_newVoting.startTime > block.timestamp, "[E-1] - Start time less than current timestamp");
        require(_newVoting.startTime < _newVoting.endTime, "[E-2] - End time less than start time");
        require(_newVoting.candidates.length > 0, "[E-4] - Candidates length less than 1");

        uint256 votingNumber = votingCount;
        votings[votingNumber] = _newVoting;
        votingCount++;

        for (uint256 i = 0; i < _newVoting.voters.length; i++) {
            isAdmitted[votingNumber][_newVoting.voters[i]] = true;
        }

        emit VotingCreated(votingNumber, _newVoting.name, msg.sender);
        return true;
    }

    function vote(uint256 _votingNum, uint256 _candidateNum) external override returns (bool){
        require(votings[_votingNum].startTime < block.timestamp, "[E-12] - Voting not started yet");
        require(votings[_votingNum].endTime > block.timestamp, "[E-11] - Voting already ended");
        require(isAdmitted[_votingNum][msg.sender], "[E-9] - Not admitted to vote here");
        require(_votingNum >= 0, "[E-5] - Voting id is negative");
        require(_votingNum < votingCount, "[E-6] - Voting with such id doesn't exist");
        require(_candidateNum >= 0, "[E-7] - Candidate id is negative");
        require(_candidateNum < votings[_votingNum].candidates.length, "[E-8] - Such candidate doesn't exist");

        if (voterVoted[_votingNum][msg.sender]) {
            voteCount[_votingNum][votings[_votingNum].candidates[_candidateNum]]--;
        }
        else {
            voterVoted[_votingNum][msg.sender] = true;
        }

        votes[_votingNum][msg.sender] = _candidateNum;
        voteCount[_votingNum][votings[_votingNum].candidates[_candidateNum]]++;

        emit VoterVoted(_votingNum, msg.sender, _candidateNum);

        return true;
    }

    function admitVoter(uint256 _votingNum, address _voter) external override returns (bool){
        require(votings[_votingNum].endTime > block.timestamp, "[E-11] - Voting already ended");
        require(msg.sender == votings[_votingNum].owner, "[E-10] - Can be called only by voting owner");
        require(_votingNum >= 0, "[E-5] - Voting id is negative");
        require(_votingNum < votingCount, "[E-6] - Voting with such id doesn't exist");


        if (!isAdmitted[_votingNum][_voter]) {
            isAdmitted[_votingNum][_voter] = true;

            return true;
        }

        return false;
    }

    function excludeVoter(uint256 _votingNum, address _voter) external override returns (bool){
        require(votings[_votingNum].endTime > block.timestamp, "[E-11] - Voting already ended");
        require(msg.sender == votings[_votingNum].owner, "[E-10] - Can be called only by voting owner");
        require(_votingNum >= 0, "[E-5] - Voting id is negative");
        require(_votingNum < votingCount, "[E-6] - Voting with such id doesn't exist");


        if (isAdmitted[_votingNum][_voter]) {
            isAdmitted[_votingNum][_voter] = false;

            return true;
        }

        return false;
    }

    function announceWinner(uint256 _votingNum) external override returns (bool){
        require(votings[_votingNum].endTime < block.timestamp, "[E-13] - Voting not ended yet");
        require(msg.sender == votings[_votingNum].owner, "[E-10] - Can be called only by voting owner");
        require(_votingNum >= 0, "[E-5] - Voting id is negative");
        require(_votingNum < votingCount, "[E-6] - Voting with such id doesn't exist");
        require(winnerAnnounced[_votingNum] == false, "[E-14] - Winner already announced");

        winnerAnnounced[_votingNum] = true;

        uint256 maxVotes;
        uint256 candidateId;

        bool duplicate = false;

        for (uint256 i = 0; i < votings[_votingNum].candidates.length; i++) {
            if (maxVotes < voteCount[_votingNum][votings[_votingNum].candidates[i]]) {
                maxVotes = voteCount[_votingNum][votings[_votingNum].candidates[i]];
                candidateId = i;
                duplicate = false;
            } else if (maxVotes == voteCount[_votingNum][votings[_votingNum].candidates[i]]) {
                duplicate = true;
            }
        }

        if (duplicate) {
            winnerTie[_votingNum] = true;

            emit WinnerAnnounced(_votingNum, 0, true);
            return false;
        } else {
            winner[_votingNum] = candidateId;
        }

        emit WinnerAnnounced(_votingNum, candidateId, false);
        return true;
    }
}