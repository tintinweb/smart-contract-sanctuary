pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IyVaren {
    // Event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    // Event emitted when a vote has been cast on a proposal
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        bool support,
        uint256 votes
    );
    // Event emitted when a proposal has been executed
    // Success=true if all actions were executed successfully
    // Success=false if not all actions were executed successfully (executeProposal will not revert)
    event ProposalExecuted(uint256 id, bool success);

    // Maximum number of actions that can be included in a proposal
    function MAX_OPERATIONS() external pure returns (uint256);

    // https://etherscan.io/token/0x72377f31e30a405282b522d588aebbea202b4f23
    function VAREN() external pure returns (IERC20);

    struct Proposal {
        // Address that created the proposal
        address proposer;
        // Number of votes in support of the proposal by a particular address
        mapping(address => uint256) forVotes;
        // Number of votes against the proposal by a particular address
        mapping(address => uint256) againstVotes;
        // Total number of votes in support of the proposal
        uint256 totalForVotes;
        // Total number of votes against the proposal
        uint256 totalAgainstVotes;
        // Number of votes in support of a proposal required for a quorum to be reached and for a vote to succeed
        uint256 quorumVotes;
        // Block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        // Ordered list of target addresses for calls to be made on
        address[] targets;
        // Ordered list of ETH values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // Ordered list of function signatures to be called
        string[] signatures;
        // Ordered list of calldata to be passed to each call
        bytes[] calldatas;
        // Flag marking whether the proposal has been executed
        bool executed;
    }

    // Number of blocks after staking when the early withdrawal fee stops applying
    function blocksForNoWithdrawalFee() external view returns (uint256);

    // Fee for withdrawing before blocksForNoWithdrawalFee have passed, divide by 1,000,000 to get decimal form
    function earlyWithdrawalFeePercent() external view returns (uint256);

    function earlyWithdrawalFeeExpiry(address) external view returns (uint256);

    function treasury() external view returns (address);

    // Share of early withdrawal fee that goes to treasury (remainder goes to governance),
    // divide by 1,000,000 to get decimal form
    function treasuryEarlyWithdrawalFeeShare() external view returns (uint256);

    // Amount of an address's stake that is locked for voting
    function voteLockAmount(address) external view returns (uint256);

    // Block number when an address's vote-locked amount will be unlock
    function voteLockExpiry(address) external view returns (uint256);

    function hasActiveProposal(address) external view returns (bool);

    function proposals(uint256 id)
        external
        view
        returns (
            address proposer,
            uint256 totalForVotes,
            uint256 totalAgainstVotes,
            uint256 quorumVotes,
            uint256 endBlock,
            bool executed
        );

    // Number of proposals created, used as the id for the next proposal
    function proposalCount() external view returns (uint256);

    // Length of voting period in blocks
    function votingPeriodBlocks() external view returns (uint256);

    function minVarenForProposal() external view returns (uint256);

    // Need to divide by 1,000,000
    function quorumPercent() external view returns (uint256);

    // Need to divide by 1,000,000
    function voteThresholdPercent() external view returns (uint256);

    // Number of blocks after voting ends where proposals are allowed to be executed
    function executionPeriodBlocks() external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 shares) external;

    function getPricePerFullShare() external view returns (uint256);

    function getStakeVarenValue(address staker) external view returns (uint256);

    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256 id);

    function vote(
        uint256 id,
        bool support,
        uint256 voteAmount
    ) external;

    function executeProposal(uint256 id) external payable;

    function getVotes(uint256 proposalId, address voter)
        external
        view
        returns (bool support, uint256 voteAmount);

    function getProposalCalls(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );

    function setTreasury(address) external;

    function setTreasuryEarlyWithdrawalFeeShare(uint256) external;

    function setBlocksForNoWithdrawalFee(uint256) external;

    function setEarlyWithdrawalFeePercent(uint256) external;

    function setVotingPeriodBlocks(uint256) external;

    function setMinVarenForProposal(uint256) external;

    function setQuorumPercent(uint256) external;

    function setVoteThresholdPercent(uint256) external;

    function setExecutionPeriodBlocks(uint256) external;
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IyVaren.sol";

contract yVaren is IyVaren, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant override MAX_OPERATIONS = 10;
    IERC20 public immutable override VAREN;

    uint256 public override blocksForNoWithdrawalFee;
    uint256 public override earlyWithdrawalFeePercent = 5000; // 0.5%
    mapping(address => uint256) public override earlyWithdrawalFeeExpiry;
    address public override treasury;
    uint256 public override treasuryEarlyWithdrawalFeeShare = 1000000; // 100%
    mapping(address => uint256) public override voteLockAmount;
    mapping(address => uint256) public override voteLockExpiry;
    mapping(address => bool) public override hasActiveProposal;
    mapping(uint256 => Proposal) public override proposals;
    uint256 public override proposalCount;
    uint256 public override votingPeriodBlocks;
    uint256 public override minVarenForProposal = 1e17; // 0.1 Varen
    uint256 public override quorumPercent = 150000; // 15%
    uint256 public override voteThresholdPercent = 500000; // 50%
    uint256 public override executionPeriodBlocks;

    modifier onlyThis() {
        require(msg.sender == address(this), "yVaren: FORBIDDEN");
        _;
    }

    constructor(
        address _varen,
        address _treasury,
        uint256 _blocksForNoWithdrawalFee,
        uint256 _votingPeriodBlocks,
        uint256 _executionPeriodBlocks
    ) public ERC20("Varen Staking Share", "yVaren") {
        require(
            _varen != address(0) && _treasury != address(0),
            "yVaren: ZERO_ADDRESS"
        );
        _setupDecimals(ERC20(_varen).decimals());
        VAREN = IERC20(_varen);
        treasury = _treasury;
        blocksForNoWithdrawalFee = _blocksForNoWithdrawalFee;
        votingPeriodBlocks = _votingPeriodBlocks;
        executionPeriodBlocks = _executionPeriodBlocks;
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "yVaren: ZERO");
        uint256 shares = totalSupply() == 0
            ? amount
            : (amount.mul(totalSupply())).div(VAREN.balanceOf(address(this)));
        VAREN.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
        earlyWithdrawalFeeExpiry[msg.sender] = blocksForNoWithdrawalFee.add(
            block.number
        );
    }

    function withdraw(uint256 shares) external override nonReentrant {
        require(shares > 0, "yVaren: ZERO");
        _updateVoteExpiry();
        require(_checkVoteExpiry(msg.sender, shares), "voteLockExpiry");
        uint256 varenAmount = (VAREN.balanceOf(address(this))).mul(shares).div(
            totalSupply()
        );
        _burn(msg.sender, shares);
        if (block.number < earlyWithdrawalFeeExpiry[msg.sender]) {
            uint256 feeAmount = varenAmount.mul(earlyWithdrawalFeePercent) /
                1000000;
            VAREN.safeTransfer(
                treasury,
                feeAmount.mul(treasuryEarlyWithdrawalFeeShare) / 1000000
            );
            varenAmount = varenAmount.sub(feeAmount);
        }
        VAREN.safeTransfer(msg.sender, varenAmount);
    }

    function getPricePerFullShare() external view override returns (uint256) {
        return VAREN.balanceOf(address(this)).mul(1e18).div(totalSupply());
    }

    function getStakeVarenValue(address staker)
        external
        view
        override
        returns (uint256)
    {
        return
            (VAREN.balanceOf(address(this)).mul(balanceOf(staker))).div(
                totalSupply()
            );
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public override nonReentrant returns (uint256 id) {
        require(!hasActiveProposal[msg.sender], "yVaren: HAS_ACTIVE_PROPOSAL");
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "yVaren: PARITY_MISMATCH"
        );
        require(targets.length != 0, "yVaren: NO_ACTIONS");
        require(targets.length <= MAX_OPERATIONS, "yVaren: TOO_MANY_ACTIONS");
        require(
            (VAREN.balanceOf(address(this)).mul(balanceOf(msg.sender))).div(
                totalSupply()
            ) >= minVarenForProposal,
            "yVaren: INSUFFICIENT_VAREN_FOR_PROPOSAL"
        );
        uint256 endBlock = votingPeriodBlocks.add(block.number);
        id = proposalCount;
        proposals[id] = Proposal({
            proposer: msg.sender,
            endBlock: endBlock,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            quorumVotes: VAREN.balanceOf(address(this)).mul(quorumPercent) /
                1000000,
            executed: false
        });
        hasActiveProposal[msg.sender] = true;
        proposalCount = proposalCount.add(1);

        emit ProposalCreated(
            id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            block.number,
            endBlock,
            description
        );
    }

    function _checkVoteExpiry(address _sender, uint256 _shares)
        private
        view
        returns (bool)
    {
        // ?????
        return _shares <= balanceOf(_sender).sub(voteLockAmount[_sender]);
    }

    function _updateVoteExpiry() private {
        if (block.number >= voteLockExpiry[msg.sender]) {
            voteLockExpiry[msg.sender] = 0;
            voteLockAmount[msg.sender] = 0;
        }
    }

    function vote(
        uint256 id,
        bool support,
        uint256 voteAmount
    ) external override nonReentrant {
        Proposal storage proposal = proposals[id];
        require(proposal.proposer != address(0), "yVaren: INVALID_PROPOSAL_ID");
        require(block.number < proposal.endBlock, "yVaren: VOTING_ENDED");
        require(voteAmount > 0, "yVaren: ZERO");
        require(
            voteAmount <= balanceOf(msg.sender),
            "yVaren: INSUFFICIENT_BALANCE"
        );
        _updateVoteExpiry();
        require(
            voteAmount >= voteLockAmount[msg.sender],
            "yVaren: SMALLER_VOTE"
        );
        if (
            (support && voteAmount == proposal.forVotes[msg.sender]) ||
            (!support && voteAmount == proposal.againstVotes[msg.sender])
        ) {
            revert("yVaren: SAME_VOTE");
        }
        if (voteAmount > voteLockAmount[msg.sender]) {
            voteLockAmount[msg.sender] = voteAmount;
        }

        voteLockExpiry[msg.sender] = proposal.endBlock >
            voteLockExpiry[msg.sender]
            ? proposal.endBlock
            : voteLockExpiry[msg.sender];

        if (support) {
            proposal.totalForVotes = proposal.totalForVotes.add(voteAmount).sub(
                proposal.forVotes[msg.sender]
            );
            proposal.forVotes[msg.sender] = voteAmount;
            // remove opposite votes
            proposal.totalAgainstVotes = proposal.totalAgainstVotes.sub(
                proposal.againstVotes[msg.sender]
            );
            proposal.againstVotes[msg.sender] = 0;
        } else {
            proposal.totalAgainstVotes = proposal
            .totalAgainstVotes
            .add(voteAmount)
            .sub(proposal.againstVotes[msg.sender]);
            proposal.againstVotes[msg.sender] = voteAmount;
            // remove opposite votes
            proposal.totalForVotes = proposal.totalForVotes.sub(
                proposal.forVotes[msg.sender]
            );
            proposal.forVotes[msg.sender] = 0;
        }

        emit VoteCast(msg.sender, id, support, voteAmount);
    }

    function executeProposal(uint256 id)
        external
        payable
        override
        nonReentrant
    {
        Proposal storage proposal = proposals[id];
        require(!proposal.executed, "yVaren: PROPOSAL_ALREADY_EXECUTED");
        {
            // check if proposal passed
            require(
                proposal.proposer != address(0),
                "yVaren: INVALID_PROPOSAL_ID"
            );
            require(
                block.number >= proposal.endBlock,
                "yVaren: PROPOSAL_IN_VOTING"
            );
            hasActiveProposal[proposal.proposer] = false;
            uint256 totalVotes = proposal.totalForVotes.add(
                proposal.totalAgainstVotes
            );
            if (
                totalVotes < proposal.quorumVotes ||
                proposal.totalForVotes <
                totalVotes.mul(voteThresholdPercent) / 1000000 ||
                block.number >= proposal.endBlock.add(executionPeriodBlocks) // execution period ended
            ) {
                return;
            }
        }

        bool success = true;
        uint256 remainingValue = msg.value;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            if (proposal.values[i] > 0) {
                require(
                    remainingValue >= proposal.values[i],
                    "yVaren: INSUFFICIENT_ETH"
                );
                remainingValue = remainingValue - proposal.values[i];
            }
            (success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                abi.encodePacked(
                    bytes4(keccak256(bytes(proposal.signatures[i]))),
                    proposal.calldatas[i]
                )
            );
            if (!success) break;
        }
        proposal.executed = true;

        emit ProposalExecuted(id, success);
    }

    function getVotes(uint256 proposalId, address voter)
        external
        view
        override
        returns (bool support, uint256 voteAmount)
    {
        support = proposals[proposalId].forVotes[voter] > 0;
        voteAmount = support
            ? proposals[proposalId].forVotes[voter]
            : proposals[proposalId].againstVotes[voter];
    }

    function getProposalCalls(uint256 proposalId)
        external
        view
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        targets = proposals[proposalId].targets;
        values = proposals[proposalId].values;
        signatures = proposals[proposalId].signatures;
        calldatas = proposals[proposalId].calldatas;
    }

    // SETTERS
    function setTreasury(address _treasury) external override onlyThis {
        treasury = _treasury;
    }

    function setTreasuryEarlyWithdrawalFeeShare(
        uint256 _treasuryEarlyWithdrawalFeeShare
    ) external override onlyThis {
        require(_treasuryEarlyWithdrawalFeeShare <= 1000000);
        treasuryEarlyWithdrawalFeeShare = _treasuryEarlyWithdrawalFeeShare;
    }

    function setBlocksForNoWithdrawalFee(uint256 _blocksForNoWithdrawalFee)
        external
        override
        onlyThis
    {
        // max 60 days
        require(_blocksForNoWithdrawalFee <= 345600);
        blocksForNoWithdrawalFee = _blocksForNoWithdrawalFee;
    }

    function setEarlyWithdrawalFeePercent(uint256 _earlyWithdrawalFeePercent)
        external
        override
        onlyThis
    {
        // max 100%
        require(_earlyWithdrawalFeePercent <= 1000000);
        earlyWithdrawalFeePercent = _earlyWithdrawalFeePercent;
    }

    function setVotingPeriodBlocks(uint256 _votingPeriodBlocks)
        external
        override
        onlyThis
    {
        // min 8 hours, max 2 weeks
        require(_votingPeriodBlocks >= 1920 && _votingPeriodBlocks <= 80640);
        votingPeriodBlocks = _votingPeriodBlocks;
    }

    function setMinVarenForProposal(uint256 _minVarenForProposal)
        external
        override
        onlyThis
    {
        // min 0.01 Varen, max 520 Varen (1% of total supply)
        require(
            _minVarenForProposal >= 1e16 && _minVarenForProposal <= 520 * (1e18)
        );
        minVarenForProposal = _minVarenForProposal;
    }

    function setQuorumPercent(uint256 _quorumPercent)
        external
        override
        onlyThis
    {
        // min 10%, max 33%
        require(_quorumPercent >= 100000 && _quorumPercent <= 330000);
        quorumPercent = _quorumPercent;
    }

    function setVoteThresholdPercent(uint256 _voteThresholdPercent)
        external
        override
        onlyThis
    {
        // min 50%, max 66%
        require(
            _voteThresholdPercent >= 500000 && _voteThresholdPercent <= 660000
        );
        voteThresholdPercent = _voteThresholdPercent;
    }

    function setExecutionPeriodBlocks(uint256 _executionPeriodBlocks)
        external
        override
        onlyThis
    {
        // min 8 hours, max 30 days
        require(
            _executionPeriodBlocks >= 1920 && _executionPeriodBlocks <= 172800
        );
        executionPeriodBlocks = _executionPeriodBlocks;
    }

    // ERC20 functions (overridden to add modifiers)
    function transfer(address recipient, uint256 amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        _updateVoteExpiry();
        require(_checkVoteExpiry(msg.sender, amount), "voteLockExpiry");
        super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override nonReentrant returns (bool) {
        _updateVoteExpiry();
        require(_checkVoteExpiry(sender, amount), "voteLockExpiry");
        super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        nonReentrant
        returns (bool)
    {
        super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        nonReentrant
        returns (bool)
    {
        super.decreaseAllowance(spender, subtractedValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

