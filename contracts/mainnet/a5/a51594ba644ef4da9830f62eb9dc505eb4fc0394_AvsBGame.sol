/**
 *Submitted for verification at Etherscan.io on 2022-01-06
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

    uint256 public immutable voteDeadline = 1642233600; // Vote phase ends Jan 15, 2022
    uint256 public immutable revealDeadline = 1642665600; // Reveal phase ends Jan 20, 2022
    uint256 public immutable minVoteIncrement = 1e16; // 0.01 ETH
    uint256 public immutable maxVoteAmount = 1e18; // 1 ETH
    uint256 public immutable fee = 20; // 5% fee (1/20th), paid out at reveal
    address public immutable feeAddress =
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

    event Vote(address indexed player, uint256 amount);
    event Reveal(address indexed player, Choice choice);
    event Payout(address indexed player, uint256 amount);

    constructor() {}

    /// ============ Functions ============

    /// @notice Cast a vote without revealing the vote by posting a commitment
    /// @param commitment Commitment to A or B, by commit-reveal scheme
    function castHiddenVote(bytes32 commitment) external payable {
        // Ensure vote is placed before vote deadline
        require(
            block.timestamp <= voteDeadline,
            "Cannot vote past vote deadline."
        );

        // Ensure vote is greater than and a multiple of min vote increment
        require(
            (msg.value >= minVoteIncrement) &&
                (msg.value % minVoteIncrement == 0),
            "Vote value must be greater than and multiple of min vote amount."
        );

        // Ensure vote is less than max vote amount
        require(
            msg.value <= maxVoteAmount,
            "Vote value must be less than max vote amount."
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
            "Cannot reveal past reveal deadline."
        );

        // Ensure reveal is either for choice A or B
        require(
            (choice == Choice.A) || (choice == Choice.B),
            "Invalid choice, must reveal A or B."
        );

        // Ensure sender has voted
        require(
            (votes[msg.sender].amount >= minVoteIncrement) &&
                (votes[msg.sender].amount <= maxVoteAmount),
            "Cannot reveal before voting."
        );

        // Ensure sender has not already revealed
        require(
            votes[msg.sender].choice == Choice.Hidden,
            "Cannot reveal more than once."
        );

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

        // Ensure that sender has revealed a vote
        VoteCommit memory senderVote = votes[msg.sender];
        require(
            (senderVote.choice == Choice.A) || (senderVote.choice == Choice.B),
            "Cannot claim payout without revealed vote."
        );

        // Get winner
        // If first time being called, take founder fee and set prizePool
        // If a tie, winner is returned as Choice.Hidden
        Choice winner = getWinner();

        // Require that sender is winner to claim funds
        require(
            (senderVote.choice == winner) || (winner == Choice.Hidden),
            "Cannot claim payout since did not win game."
        );

        // Calc share of winnings
        uint256 denominator;
        if (winner == Choice.A) {
            denominator = revealedA;
        } else if (winner == Choice.B) {
            denominator = revealedB;
        } else {
            // Everybody wins
            require(winner == Choice.Hidden, "Invalid winner.");
            denominator = revealedA + revealedB;
        }
        uint256 winnings = (prizePool * senderVote.amount) / denominator;

        // Remove vote data to prevent double claim
        delete votes[msg.sender];

        // Transfer funds
        payable(msg.sender).transfer(winnings);

        // Emit payout event
        emit Payout(msg.sender, winnings);
    }

    /// @notice Returns winner, if first time pays founder's fee and sets prizePool
    function getWinner() private returns (Choice) {
        // Collect founder's fee if first time
        if (prizePool == 0) {
            collectFee();
            // Set prize pool to be remaining funds in the contract
            prizePool = address(this).balance;
        }

        // Choose winner
        // In case one side did not reveal any votes, the other side wins
        // One side must have revealed votes as required in claimPayout
        if (revealedA == 0) {
            return Choice.B;
        } else if (revealedB == 0) {
            return Choice.A;
        } else if (revealedA < revealedB) {
            return Choice.A;
        } else if (revealedB < revealedA) {
            return Choice.B;
        } else {
            // Tie
            return Choice.Hidden;
        }
    }

    /// @notice Collects the founder's fee, is only be called once
    function collectFee() private {
        // Collect fee
        uint256 feeAmount = address(this).balance / fee;
        payable(feeAddress).transfer(feeAmount);

        // Emit payout event
        emit Payout(feeAddress, feeAmount);
    }
}