/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

/// @title AvsBGame
/// @notice A Liar's Game: Vote by putting ETH behind A or B ... the side with the least votes gets all the ETH
/// @author AvsB Team
/// @dev Built using a Commit-Reveal scheme

contract AvsBGame {
    /// ============ Types ============

    // Possible votes (and Hidden before votes are revealed)
    enum Choice {
        Hidden,
        A,
        B
    }

    // A cryptographic committment to a certain vote
    struct VoteCommit {
        bytes32 commitment;
        uint256 amount;
        Choice choice;
    }

    /// ============ Immutable storage ============

    uint256 public immutable voteDeadline = 1643702400; // Vote phase ends Feb 1, 2022
    uint256 public immutable revealDeadline = 1644912000; // Reveal phase ends Feb 15, 2022
    uint256 public immutable minVoteIncrement = 5e15; // 0.005 ETH
    uint256 public immutable foundersFee = 20; // 5% fee (1/20th), paid out at reveal
    address public immutable founderAddress =
        0x7B91649D893B2e4Feef78b6891dE383d5a8491eE;

    /// ============ Mutable storage ============

    // Tracks vote commitments
    mapping(address => VoteCommit) public votes;

    // Tracks revealed votes, updated every reveal
    // We need to track these because some votes may remain unrevealed
    uint256 public revealedA = 0;
    uint256 public revealedB = 0;

    // Stores total prize pool (only updated during payout phase)
    uint256 public prizePool = 0;

    /// ============ Events ============

    event Vote(address player, uint256 amount);
    event Reveal(address player, Choice choice);
    event Payout(address player, uint256 amount);

    constructor() {}

    /// ============ Functions ============

    /// @notice Cast a vote without revealing the vote by posting a commitment
    /// @param commitment Commitment to A or B, by commit-reveal scheme
    function castHiddenVote(bytes32 commitment) external payable {
        // Ensure vote is placed before vote deadline
        require(
            block.timestamp <= voteDeadline,
            "Cannot vote past the vote deadline."
        );

        // Ensure vote is greater than and a multiple of min vote increment
        require(
            msg.value >= minVoteIncrement && msg.value % minVoteIncrement == 0,
            "Vote value must be greater than and multiple of minimum vote amount."
        );

        // Ensure player has not voted before
        require(votes[msg.sender].amount == 0, "Cannot vote twice.");

        // Store the commitment for the commit-reveal scheme
        votes[msg.sender] = VoteCommit(commitment, msg.value, Choice.Hidden);

        // Emit Vote event
        emit Vote(msg.sender, msg.value);
    }

    /// @notice Reveal a vote that was previously commited to
    /// @param choice Choice that is being revealed by sender
    /// @param blindingFactor Salt used by the voter in their previous vote commitment
    function reveal(Choice choice, bytes32 blindingFactor) external {
        // Ensure reveal is before reveal deadline ("early" reveals during voting period are technically permitted)
        require(
            block.timestamp <= revealDeadline,
            "Cannot reveal past the reveal deadline."
        );

        // Ensure reveal is either for choice A or B
        require(
            choice == Choice.A || choice == Choice.B,
            "Invalid choice, must reveal A or B."
        );

        // Ensure sender has not already revealed
        require(votes[msg.sender].choice == Choice.Hidden, "Already revealed.");

        // Check hash and reveal if correct
        VoteCommit storage vote = votes[msg.sender];
        require(
            keccak256(abi.encodePacked(msg.sender, choice, blindingFactor)) ==
                vote.commitment,
            "Invalid reveal, hash does not match committment."
        );
        vote.choice = choice;

        // Update revealed vote counts
        if (choice == Choice.A) {
            revealedA += vote.amount;
        } else {
            revealedB += vote.amount;
        }

        // Emit reveal event
        emit Reveal(msg.sender, choice);
    }

    /// @notice Claim payout at game end
    function claimPayout() external {
        // Ensure reveal deadline has passed before claiming payout
        require(
            block.timestamp > revealDeadline,
            "Cannot claim payout before reveal deadline has passed."
        );

        // Require that sender has revealed a vote on the winning side
        VoteCommit memory senderVote = votes[msg.sender];
        require(
            senderVote.choice != Choice.Hidden,
            "Cannot claim payout since vote was not revealed."
        );

        // If first time being called, choose winner and take founder fee
        Choice winner = getWinner();

        // Require that sender is winner to claim funds
        // If a tie, winner is returned as Choice.Hidden
        require(
            senderVote.choice == winner || winner == Choice.Hidden,
            "Cannot claim payout since did not win game."
        );

        // Claim share of winnings
        uint256 denominator;
        if (winner == Choice.A) {
            denominator = revealedA;
        } else if (winner == Choice.B) {
            denominator = revealedB;
        } else {
            // Everybody wins
            denominator = revealedA + revealedB;
        }
        uint256 winnings = (prizePool * senderVote.amount) / denominator;
        payable(msg.sender).transfer(winnings);

        // Emit payout event
        emit Payout(msg.sender, winnings);
    }

    /// @notice Returns winner and pays founder's fee if first time, returns Hidden if tie
    function getWinner() private returns (Choice) {
        // Collect founder's fee if first time
        if (prizePool == 0) {
            collectFoundersFee();
            // Set prize pool to be remaining funds in the contract
            prizePool = address(this).balance;
        }

        // Choose winner
        // In case one side did not reveal any votes, the other side winw
        // One side must have revealed votes as required in claimPayout
        if (revealedA == 0) {
            return Choice.B;
        } else if (revealedB == 0) {
            return Choice.A;
        } else if (revealedA < revealedB) {
            return Choice.A;
        } else if (revealedA > revealedB) {
            return Choice.B;
        } else {
            return Choice.Hidden;
        }
    }

    /// @notice Collects the founder's fee and updated prizePool, is only be called once
    function collectFoundersFee() private {
        // Collect fee
        uint256 fee = address(this).balance / foundersFee;
        payable(founderAddress).transfer(fee);

        // Emit payout event
        emit Payout(founderAddress, fee);
    }
}