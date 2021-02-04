/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ITACData {
     function balanceOf(address account) public virtual view returns (uint256);
     function transfer(address recipient, uint256 amount) public virtual returns (bool);
}

abstract contract ICoopData {
    function getUser(address _address) public virtual view returns(address userAddress, string memory displayName, uint16 locationCode,
    uint16 dojangCode, bool isMale, uint16 weight, string memory notes, uint8 numTickets, uint64[] memory matches, string memory imageURL, uint16 role);
    function getMatch(uint64 _id) public virtual view returns(uint64 id, address winner, uint8 winnerPoints,
    address loser, uint8 loserPoints, uint64 time, string memory notes, address referee);
    function getUserMatchNumber(address _address) public virtual view returns (uint256);
}

abstract contract ITACLockup {
     function getTACLocked(address user) public virtual view returns (uint256 lockedAmount);
}

 //Control who can access various functions.
contract AccessControl {
   address payable public creatorAddress;
   
   modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, "You are not the creator of the contract.");
        _;
    }

   // Constructor
    constructor() public {
        creatorAddress = 0x813dd04A76A716634968822f4D30Dfe359641194;
    }
}


contract TACVoting is AccessControl {
    using SafeMath for uint256;

    /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////
    uint256 public numElections = 0;

    //How long to open an election for
    uint64 public electionDuration = 604800;

    //The oldest any match can be to still compete. maxMatchAge of 0 means all matches are valid.
    uint64 public maxMatchAge = 0;
    
    uint256 public defaultVotes = 100000000000000000000;

    //Main data structure to hold info about a vote
    struct Vote {
        address voter; //since the address is unique this also serves as their id
        uint64 choice;
    }

    //Data structure that holds inforamtion about one of the options for the election.
    struct Option {
        uint64 matchId;
        string videoURL;
        string description;
        address bluePlayer;
    }

    //Data structure storing the information about each election.
    struct Election {
        uint64 id;
        bool isLive;
        uint64 startTime;
        mapping (address => uint16) voteId; //which choice each address selected.
        uint64 winningMatch;
    }

    mapping(uint64 => Option[]) optionsPerElection;
    mapping(uint64 => Vote[]) votesPerElection;

    //Payout percentages of the contract balance for each winning video. The number is divided 100, so each athlete received 20% of the pot.
    uint8 payoutDivisor = 5;
   
    address public TACContract = 0xABa8ace37f301E7a3A3FaD44682C8Ec8DC2BD18A;
    address public TACLockupContract = 0xbE6492206f460136921308c80D390c3D1D3f1716;
    address public coopDataContract = 0x4E81fc0Eeef51c516773Eb6b6Ec05c452B0c8F5f;
    
    //Main mapping storing an Election record for each election id.
    Election[] Elections;

    //Once you've won, the same match cannot be entered again.
    mapping(uint64 => bool) public allWinners;

    //Total number of votes each match has received. Reset after counting votes
    mapping (uint64 => uint256) public voteTotals;

    //Shows which match is currently in which election.
    mapping(uint64 => uint64) public MatchElections;

  /////////////////////////////////////////////////CONTRACT ADMIN FUNCTIONS ///////////////////////////////////////////////////////////////////////
    function setParameters(uint8 _payoutDivisor, uint64 _electionDuration, uint64 _maxMatchAge, uint256 _defaultVotes) public onlyCREATOR {
        payoutDivisor = _payoutDivisor;
        electionDuration = _electionDuration;
        maxMatchAge = _maxMatchAge;
        defaultVotes = _defaultVotes;
    }

    function setAddresss(address _TACContract, address _TACLockupContract, address _coopDataContract) public onlyCREATOR {
        TACContract = _TACContract;
        TACLockupContract = _TACLockupContract;
        coopDataContract = _coopDataContract;
    }

    //returns how many elections there have been so far.
    function getNumElections() public view returns (uint256) {
        return numElections;
    }

    //Returns the contract's TAC balance.
    function getTACBalance() public view returns (uint256 balance) {
        ITACData TAC = ITACData(TACContract);
        balance = TAC.balanceOf(address(this));
    }

 
     /////////////////////////////////////////////////ELECTION FUNCTIONS ///////////////////////////////////////////////////////////////////////
     
    function init() public {
        //Make sure there currently isn't an open election.
        require(numElections == 0, "The contract has already been initialized");
        Election memory election;
        election.id = uint64(numElections);
        election.startTime = uint64(now);
        election.winningMatch = 0;
        election.isLive = true;
        Elections.push(election);
        numElections ++;
    }     
     
    function openElection() public {
        //Make sure there currently isn't an open election.
        require(Elections[numElections-1].isLive == false, "The current election must finish before you can open another one");
        //Open the new election
        Election memory election;
        election.id = uint64(numElections);
        election.startTime = uint64(now);
        election.winningMatch = 0;
        election.isLive = true;
        Elections.push(election);
        numElections ++;
    }

    //Function called to add a match to an election. 
    function joinElection(uint64 electionId, uint64 matchId, string memory videoURL, string memory description, address bluePlayer) public {
        //Anyone can join - UI limits to match players.
        //Make sure this match is valid
        require(isMatchValid(matchId) == true, "Sorry, but you can't submit this match to an election.");
        //Make sure the election is the proper one to join
        checkElection(electionId);
        //Add the option to the election
        require(MatchElections[matchId] != electionId || electionId == 0, "Sorry, but this match is already in this election");
        Option memory option;
        option.matchId = matchId;
        option.videoURL = videoURL;
        option.description = description;
        option.bluePlayer = bluePlayer;
        optionsPerElection[electionId].push(option);
        MatchElections[matchId] = electionId;
    }


    //Function to return election information. 
    function getElection(uint64 electionId) public view returns (uint64 id, bool isLive, uint64 startTime, Option[] memory options, Vote[] memory votes, uint64 winningMatch) {
        id=Elections[electionId].id;
        isLive = Elections[electionId].isLive;
        startTime = Elections[electionId].startTime;
        options = optionsPerElection[electionId];
        votes = votesPerElection[electionId];
        winningMatch = Elections[electionId].winningMatch;
    }
    
    //Returns information about each choice a voter could make. 
    function getElectionOptions(uint64 electionId, uint16 optionNumber) public view returns (uint64 option, string memory videoURL, string memory description) {
        option = optionsPerElection[electionId][optionNumber].matchId; 
        videoURL = optionsPerElection[electionId][optionNumber].videoURL; 
        description = optionsPerElection[electionId][optionNumber].description;
    }

    //Function that makes sure that the specified match can be entered.
    function isMatchValid(uint64 matchId) public view returns (bool) {
        if (allWinners[matchId] == true) {return false;}  //Cannot enter another election if your match has already won.
        if (maxMatchAge == 0) {return true;} //All match ages are allowed.
        
         //Find out when the match was sparred
        ICoopData CoopData = ICoopData(coopDataContract);
        uint64 time;
        (,,,,,time,,) = CoopData.getMatch(matchId);

        if (time > SafeMath.sub(now, maxMatchAge)) { 
            return true;
        }  //The match is recent enough.
        else {
            return false;
        }
    }

    //Function to make sure election parameters are correct.
    function checkElection(uint64 electionId) public view returns (bool) {
         require(Elections[electionId].isLive == true, "This election is not open");
         require(electionId >= 0, "Please submit a valid electionId");
         require(electionId < numElections, "We haven't had that many elections yet");
         return true;
    }
    
    //Function to close an election, add up votes, and pay winners. 
    function closeElection(uint64 electionId) public {
         //first make sure the election is open and valid.
        checkElection(electionId);

        //Next, make sure that the election has been open long enough
        require((Elections[electionId].startTime + electionDuration <= uint64(now)), "Hold on - the election still needs more time to resolve");

        ICoopData CoopData = ICoopData(coopDataContract);
        ITACLockup TACLockup = ITACLockup(TACLockupContract);
        Elections[electionId].isLive = false;
        
        //map the total score for each match Id
        for (uint i = 0;i < votesPerElection[electionId].length; i++) {
            voteTotals[votesPerElection[electionId][i].choice] = voteTotals[votesPerElection[electionId][i].choice] +   SafeMath.mul(CoopData.getUserMatchNumber(votesPerElection[electionId][i].voter) + defaultVotes, TACLockup.getTACLocked(votesPerElection[electionId][i].voter ));
        }
        
        //Assume the first option is the winner, and then change if another match has more votes
        uint64 winner = optionsPerElection[electionId][0].matchId;
        uint256 mostVotes = 0;
        for (uint j = 0; j < optionsPerElection[electionId].length; j++) {
            if (voteTotals[optionsPerElection[electionId][j].matchId] > mostVotes) {
                winner = optionsPerElection[electionId][j].matchId;
                mostVotes = voteTotals[winner];
            }
            //Reset voteTotals back to 0 for next election
            voteTotals[optionsPerElection[electionId][j].matchId] = 0;
        }
        
        allWinners[winner] = true; //mark that the match has won and can't be entered into another election. 
        Elections[electionId].winningMatch = winner;
        //Winner is the id of the winning match
        payWinners(winner);   
    }
    
    
    function payWinners(uint64 winner) internal {
           ICoopData CoopData = ICoopData(coopDataContract);
           ITACData TAC = ITACData(TACContract);
           address athlete1;
           address athlete2;
           (,athlete1,,athlete2,,,,) = CoopData.getMatch(winner);
           uint256 winningAmount = TAC.balanceOf(address(this)) / payoutDivisor;
           
           TAC.transfer(athlete1, winningAmount);
           TAC.transfer(athlete2, winningAmount);
    }
 
    //DEV only function to close an election, in the case that there are so many options that chooseing a winner doesn't fit in a block. 
    function devCloseElection(uint64 electionId, uint64 winner, address athlete1, address athlete2, uint256 winningAmount) public onlyCREATOR {
        Elections[electionId].isLive = false;  
        Elections[electionId].winningMatch = winner;
        allWinners[winner] = true;    
        ITACData TAC = ITACData(TACContract);
        TAC.transfer(athlete1, winningAmount);
        TAC.transfer(athlete2, winningAmount);   
    }


  /////////////////////////////////////////////////VOTING FUNCTIONS ///////////////////////////////////////////////////////////////////////

    function vote(uint64 electionId, uint64 matchId) public {
       checkElection(electionId);
       uint16 voteId;
       Vote memory proposedVote;
       proposedVote.voter = msg.sender;
       proposedVote.choice = matchId;

       //next check if the voter has already voted. If not, add the vote. If so, change it.

       if (Elections[electionId].voteId[msg.sender] != 0) {
           voteId = Elections[electionId].voteId[msg.sender];
           votesPerElection[electionId][voteId] = proposedVote;
       }
        else {
            votesPerElection[electionId].push(proposedVote);
            Elections[electionId].voteId[msg.sender] = uint16(votesPerElection[electionId].length-1);
        }
    }
    
    //Function to return the matchId that the voter has chosen, or 0 if they have not yet voted.
    function getVote(uint64 electionId, address voter) public view returns (uint64 choice) {
         checkElection(electionId);
         return votesPerElection[electionId][Elections[electionId].voteId[voter]].choice;
    }
  
}