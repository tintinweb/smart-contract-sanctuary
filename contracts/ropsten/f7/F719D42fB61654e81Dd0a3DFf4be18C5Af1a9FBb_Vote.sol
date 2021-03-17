// Contract where users submit a proposal and cast votes, using staked ether.

pragma solidity ^0.5.0;

import "./lib/SafeMath.sol";

contract Vote {
    
    using SafeMath for uint256;
    address public admin;

    constructor() public {
        admin = msg.sender;
        lastBlockNumber = block.number;
    }

    /**
     * This struct defines the Proposal object.
     * @param id - Unique identifier for the proposal.
     * @param proposer - The address created the proposal.
     * @param title - The description of the proposal.
     * @param yay_count - Count votes in proportion to their deposit eth amount for the proposal.
     * @param nay_count - Count votes in proportion to their deposit eth amount against the proposal.
     * @param deposit_balance - The total amount of ETH deposited for the proposal.
     * @param begin_block_number - The block number when the proposal is created.
     * @param end_block_number - The block number when the proposal becomes inactive.
     * @param max_deposit - The maximum amount of ETH can be staked by the voters to avoid manipulation of the vote consensus.
     */
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        uint256 yay_count;
        uint256 nay_count;
        uint256 deposit_balance;
        uint256 begin_block_number;
        uint256 end_block_number;
        uint256 max_deposit;
    }

    enum Voter_Status {
        UNDECIDED,
        YAY,
        NAY
    }

    // Proposal Variables
    uint256 public total_proposals;
    mapping (uint256 => Proposal) public Proposals; // Find the proposals with the given ID.
    mapping (uint256 => uint256[]) internal active_proposals; // block end number mapped to array of proposal ids.
    uint256[] internal inactiveIds; // track inactive proposals to claim eth.
    uint256 public endProp_count; // counts the number of inactive proposals.
    mapping (address => uint256[]) internal myProposalIds; // users to locate their created/voted proposal by id.
    mapping (address => uint256) public myProposal_count; // counts the number of proposals the user created.

    // Keep track of processed block number
    uint public lastBlockNumber;

    // Votes variables
    mapping (uint256 => mapping (address => Voter_Status)) internal addressToVote; // Show votes given by address and id.
    mapping (uint256 => Voter_Status) public winVotes; // Proposal majority votes.

    // Funds variables.
    mapping (uint256 => mapping (uint => mapping (address => uint256))) internal votingStake; // Show the amount of eth staked for the vote
    mapping (address => uint256) internal withdraw; // Keeping track of user withdrawable amount.
    mapping (address => uint256) internal totalStake; // Keeping track of the user's total staked ETH.

    event Transfer(address indexed _from, address indexed _to, uint256 amount); // Transfer of ETH event.
    event Voted(address indexed _voter, uint256 id, bool votesYay); // Users cast votes event.
    event EndOfProposal(uint256 id); // Proposal ended event trigger.

    /**
     * @dev Modifier to be called periodically to detect proposals that are no longer active and call for the winner.
     */
    modifier checkWinner() {
        // update proposals since last update to current block number.
        uint256 current = block.number;
        for (uint i = lastBlockNumber.add(1); i <= current; i++) {
            uint256[] memory endProposalIds = active_proposals[i];
            uint n = endProposalIds.length;
            for (uint j = 0; j < n; j++) {
                uint id = endProposalIds[j];
                Proposal memory prop = Proposals[id];
                if (prop.yay_count > prop.nay_count) {
                    winVotes[id] = Voter_Status.YAY;
                }
                else if (prop.yay_count < prop.nay_count) {
                    winVotes[id] = Voter_Status.NAY;
                }
                else {
                    winVotes[id] = Voter_Status.UNDECIDED;
                }
                inactiveIds.push(id);
                endProp_count = endProp_count.add(1);
                emit EndOfProposal(id);
            }
            delete active_proposals[i];
        }
        lastBlockNumber = current;
        _;
    }

    /** 
     * @dev Function to calculate earnings from winning proposals.
     */
    function earnedEth(address _winner, uint256 id) internal {
        if (totalStake[_winner] > 0) {
            Proposal memory prop = Proposals[id];
            uint wonVote = uint(winVotes[id]);
            uint earned;
            uint stake;
            if (wonVote == 1) {
                stake = votingStake[id][wonVote][_winner];
                uint total = prop.yay_count;
                uint percent = stake.mul(100).div(total);
                earned = prop.deposit_balance.mul(percent).div(100);
            } else if (wonVote == 2) {
                stake = votingStake[id][wonVote][_winner];
                uint total = prop.nay_count;
                uint percent = stake.mul(100).div(total);
                earned = prop.deposit_balance.mul(percent).div(100);
            } else {
                stake = votingStake[id][uint(addressToVote[id][_winner])][_winner];
                uint total = prop.deposit_balance;
                uint percent = stake.mul(100).div(total);
                earned = prop.deposit_balance.mul(percent).div(100);
            }
            if (stake > 0) {
                totalStake[_winner] = totalStake[_winner].sub(stake);
            }
            withdraw[_winner] = withdraw[_winner].add(earned);
            delete votingStake[id][uint(addressToVote[id][_winner])][_winner];
        }
    }

    /**
     * @dev Function to create a proposal, requires a minimum deposit amount of 0.001 ETH.
     * @return The proposal id
     */
    function create(string memory title, uint endOffset) public payable checkWinner() returns(uint256) {
        require(msg.value >= 0.001 ether, "Deposit does not meet the minimum requirement");
        require(endOffset > 0, "End block number undefined");

        uint id = total_proposals.add(1);
        total_proposals = id;
        uint endBlock = block.number.add(endOffset);
        uint maximum = msg.value.mul(90).div(100); // voters can only deposit 90% of the proposer's amount at most -- prevention of whales.
        Proposal memory newProposal = Proposal(id, msg.sender, title, msg.value, 0, msg.value, block.number, endBlock, maximum);
        Proposals[total_proposals] = newProposal;
        active_proposals[newProposal.end_block_number].push(id);
        myProposalIds[msg.sender].push(id);
        myProposal_count[msg.sender] = myProposal_count[msg.sender].add(1);

        // Proposer votes yay by default.
        addressToVote[id][msg.sender] = Voter_Status.YAY;
        votingStake[id][uint(Voter_Status.YAY)][msg.sender] = msg.value;
        totalStake[msg.sender] = totalStake[msg.sender].add(msg.value);

        emit Transfer(msg.sender, address(this), msg.value);
        emit Voted(msg.sender, id, true);

        return id;
    }

    /**
     * @dev Function to vote on a proposal.
     */
    function vote(uint256 id, bool votesYay) public payable checkWinner() returns(bool success) {
        require(id <= total_proposals, "Invalid proposal");
        require(addressToVote[id][msg.sender] == Voter_Status.UNDECIDED, "Can not vote twice");
        Proposal storage proposal = Proposals[id];
        require(proposal.end_block_number > block.number, "Proposal is no longer active");
        require(msg.value <= proposal.max_deposit, "Deposit exceeded the maximum amount");

        proposal.deposit_balance = proposal.deposit_balance.add(msg.value);
        totalStake[msg.sender] = totalStake[msg.sender].add(msg.value);

        if (votesYay) {
            addressToVote[id][msg.sender] = Voter_Status.YAY;
            votingStake[id][uint(Voter_Status.YAY)][msg.sender] = msg.value;
            proposal.yay_count = proposal.yay_count.add(msg.value);
        }
        else {
            addressToVote[id][msg.sender] = Voter_Status.NAY;
            votingStake[id][uint(Voter_Status.NAY)][msg.sender] = msg.value;
            proposal.nay_count = proposal.nay_count.add(msg.value);
        }

        myProposalIds[msg.sender].push(id);
        myProposal_count[msg.sender] = myProposal_count[msg.sender].add(1);

        emit Transfer(msg.sender, address(this), msg.value);
        emit Voted(msg.sender, id, votesYay);

        return true;
    }

    /**
     * @dev User-callable function to update their withdrawable earnings.
     * TEMP: I need to figure out a way to shrink inactiveIds. This function call can become very expensive, if not fixed.
     */
    function updateEthEarned() public checkWinner() returns(uint256) {
        for (uint i = 0; i < inactiveIds.length; i++) {
            earnedEth(msg.sender, inactiveIds[i]);
        }
        return get_withdraw();
    }

    /**
     * @dev User-callable function to get their withdrawable amount. It is recommended to invoke updateEthEarned() first.
     */
    function get_withdraw() public view returns(uint256) {
        return withdraw[msg.sender];
    }

    /**
     * @dev User-callable function to get their staked ETH amount
     */
    function get_staked() public view returns(uint256) {
        return totalStake[msg.sender];
    }

    /**
     * @dev User-callable function for proposer owners to look at their proposals or find a proposal in general.
     * @dev if ownerProposal is true, i is used as index of the myProposal Array. Otherwise, it is simply the proposal id.
     * @return the values that comform to the Proposal object.
     */
    function get_proposals(uint i, bool ownerProposal) public view returns
    (
        uint256, 
        address, 
        string memory, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256
    ) {
        Proposal memory prop;
        if (ownerProposal) {
            require(i < myProposal_count[msg.sender], "Invalid index");
            uint id = myProposalIds[msg.sender][i];
            prop = Proposals[id];
        }
        else {
            require(i <= total_proposals, "Proposal does not exist");
            prop = Proposals[i];
        }
        return (prop.id, prop.proposer, prop.title, prop.yay_count, prop.nay_count, prop.deposit_balance, prop.begin_block_number, prop.end_block_number, prop.max_deposit);
    }

    /**
     * @dev Function to get the user's vote on a proposal given by ID.
     */
    function get_votes(uint256 id) public view returns(uint) {
        return uint(addressToVote[id][msg.sender]);
    }

    /**
     * @dev Function for users to withdraw all of their eth. It is recommended to invoke updateEthEarned() first.
     */
    function withdrawEth() public payable checkWinner() returns(bool success) {
        uint256 withdrawBal = withdraw[msg.sender];
        require(withdrawBal > 0, "No funds available to withdraw");

        msg.sender.transfer(withdrawBal);
        withdraw[msg.sender] = 0;

        emit Transfer(address(this), msg.sender, withdrawBal);

        return true;
    }

}

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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