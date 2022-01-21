pragma solidity ^0.5.11;

contract Poll {
    // The block at which the poll ends and votes can no longer be submitted.
    uint256 public endBlock;

    // Vote is emitted when an account submits a vote with 'choiceID'.
    // This event can be indexed to tally all votes for each choiceID
    event Vote(address indexed voter, uint256 choiceID);

    modifier isActive() {
        require(block.number <= endBlock, "poll is over");
        _;
    }

    constructor(uint256 _endBlock) public {
        endBlock = _endBlock;
    }

    /**
     * @dev Vote for the poll's proposal.
     *      Reverts if the poll period is over.
     * @param _choiceID the ID of the option to vote for
     */
    function vote(uint256 _choiceID) external isActive {
        emit Vote(msg.sender, _choiceID);
    }

    /**
     * @dev Destroy the Poll contract after the poll has finished
     *      Reverts if the poll is still active
     */
    function destroy() external {
        require(block.number > endBlock, "poll is active");
        selfdestruct(msg.sender);
    }
}

pragma solidity ^0.5.11;

import "./Poll.sol";

interface IBondingManager {
    function transcoderTotalStake(address _addr) external view returns (uint256);

    function pendingStake(address _addr, uint256 _endRound) external view returns (uint256);
}

contract PollCreator {
    // 33.33%
    uint256 public constant QUORUM = 333300;
    // 50%
    uint256 public constant QUOTA = 500000;
    // 10 rounds
    uint256 public constant POLL_PERIOD = 10 * 5760;
    uint256 public constant POLL_CREATION_COST = 100 * 1 ether;

    IBondingManager public bondingManager;

    event PollCreated(address indexed poll, bytes proposal, uint256 endBlock, uint256 quorum, uint256 quota);

    constructor(address _bondingManagerAddr) public {
        bondingManager = IBondingManager(_bondingManagerAddr);
    }

    /**
     * @notice Create a poll if caller has POLL_CREATION_COST LPT stake (own stake or stake delegated to it).
     * @param _proposal The IPFS multihash for the proposal.
     */
    function createPoll(bytes calldata _proposal) external {
        require(
            // pendingStake() ignores the second arg
            bondingManager.pendingStake(msg.sender, 0) >= POLL_CREATION_COST ||
                bondingManager.transcoderTotalStake(msg.sender) >= POLL_CREATION_COST,
            "PollCreator#createPoll: INSUFFICIENT_STAKE"
        );

        uint256 endBlock = block.number + POLL_PERIOD;
        Poll poll = new Poll(endBlock);

        emit PollCreated(address(poll), _proposal, endBlock, QUORUM, QUOTA);
    }
}