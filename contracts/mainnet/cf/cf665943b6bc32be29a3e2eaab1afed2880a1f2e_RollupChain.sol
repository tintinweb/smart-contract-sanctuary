// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import "./TransitionDisputer.sol";
import "./Registry.sol";
import "./strategies/interfaces/IStrategy.sol";
import "./libraries/MerkleTree.sol";
import "./libraries/Transitions.sol";
import "./interfaces/IWETH.sol";

contract RollupChain is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* Fields */
    // The state transition disputer
    TransitionDisputer transitionDisputer;
    // Asset and strategy registry
    Registry registry;

    // All the blocks (prepared and/or executed).
    dt.Block[] public blocks;
    uint256 public countExecuted = 0;

    // Track pending deposits roundtrip status across L1->L2->L1.
    // Each deposit record ID is a count++ (i.e. it's a queue).
    // - L1 deposit() creates it in "pending" status
    // - commitBlock() moves it to "done" status
    // - fraudulent block moves it back to "pending" status
    // - executeBlock() deletes it
    enum PendingDepositStatus {Pending, Done}
    struct PendingDeposit {
        bytes32 dhash; // keccak256(abi.encodePacked(account, assetId, amount))
        uint64 blockId; // rollup block; "pending": baseline of censorship, "done": block holding L2 transition
        PendingDepositStatus status;
    }
    mapping(uint256 => PendingDeposit) public pendingDeposits;
    uint256 public pendingDepositsExecuteHead; // moves up inside blockExecute() -- lowest
    uint256 public pendingDepositsCommitHead; // moves up inside blockCommit() -- intermediate
    uint256 public pendingDepositsTail; // moves up inside L1 deposit() -- highest

    // Track pending withdraws arriving from L2 then done on L1 across 2 phases.
    // A separate mapping is used for each phase:
    // (1) pendingWithdrawCommits: commitBlock() --> executeBlock(), per blockId
    // (2) pendingWithdraws: executeBlock() --> L1-withdraw, per user account address
    //
    // - commitBlock() creates pendingWithdrawCommits entries for the blockId.
    // - executeBlock() aggregates them into per-account pendingWithdraws entries and
    //   deletes the pendingWithdrawCommits entries.
    // - fraudulent block deletes the pendingWithdrawCommits during the blockId rollback.
    // - L1 withdraw() gives the funds and deletes the account's pendingWithdraws entries.
    struct PendingWithdrawCommit {
        address account;
        uint32 assetId;
        uint256 amount;
    }
    mapping(uint256 => PendingWithdrawCommit[]) public pendingWithdrawCommits;

    // Mapping of account => assetId => pendingWithdrawAmount
    mapping(address => mapping(uint32 => uint256)) public pendingWithdraws;

    // Track pending L1-to-L2 balance sync roundtrip across L1->L2->L1.
    // Each balance sync record ID is a count++ (i.e. it's a queue).
    // - L1-to-L2 Balance Sync creates in "pending" status
    // - commitBlock() moves it to "done" status
    // - fraudulent block moves it back to "pending" status
    // - executeBlock() deletes it
    enum PendingBalanceSyncStatus {Pending, Done}
    struct PendingBalanceSync {
        bytes32 bhash; // keccak256(abi.encodePacked(strategyId, delta))
        uint64 blockId; // rollup block; "pending": baseline of censorship, "done": block holding L2 transition
        PendingBalanceSyncStatus status;
    }
    mapping(uint256 => PendingBalanceSync) public pendingBalanceSyncs;
    uint256 public pendingBalanceSyncsExecuteHead; // moves up inside blockExecute() -- lowest
    uint256 public pendingBalanceSyncsCommitHead; // moves up inside blockCommit() -- intermediate
    uint256 public pendingBalanceSyncsTail; // moves up inside L1 Balance Sync -- highest

    // Track the asset balances of strategies to compute deltas after syncBalance() calls.
    mapping(uint32 => uint256) public strategyAssetBalances;

    // per-asset (total deposit - total withdrawal) amount
    mapping(address => uint256) public netDeposits;
    // per-asset (total deposit - total withdrawal) limit
    mapping(address => uint256) public netDepositLimits;

    uint256 public blockChallengePeriod; // delay (in # of ETH blocks) to challenge a rollup block
    uint256 public maxPriorityTxDelay; // delay (in # of rollup blocks) to reflect an L1-initiated tx in a rollup block

    address public operator;

    /* Events */
    event RollupBlockCommitted(uint256 blockId);
    event RollupBlockExecuted(uint256 blockId);
    event RollupBlockReverted(uint256 blockId, string reason);
    event BalanceSync(uint32 strategyId, int256 delta, uint256 syncId);
    event AssetDeposited(address account, uint32 assetId, uint256 amount, uint256 depositId);
    event AssetWithdrawn(address account, uint32 assetId, uint256 amount);
    event OperatorChanged(address previousOperator, address newOperator);

    constructor(
        uint256 _blockChallengePeriod,
        uint256 _maxPriorityTxDelay,
        address _transitionDisputerAddress,
        address _registryAddress,
        address _operator
    ) {
        blockChallengePeriod = _blockChallengePeriod;
        maxPriorityTxDelay = _maxPriorityTxDelay;
        transitionDisputer = TransitionDisputer(_transitionDisputerAddress);
        registry = Registry(_registryAddress);
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not operator");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Deposits ERC20 asset.
     *
     * @param _asset The asset address;
     * @param _amount The amount;
     */
    function deposit(address _asset, uint256 _amount) external whenNotPaused {
        _deposit(_asset, _amount);
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Deposits ETH.
     *
     * @param _amount The amount;
     * @param _weth The address for WETH.
     */
    function depositETH(address _weth, uint256 _amount) external payable whenNotPaused {
        require(msg.value == _amount, "ETH amount mismatch");
        _deposit(_weth, _amount);
        IWETH(_weth).deposit{value: _amount}();
    }

    /**
     * @notice Executes pending withdraw of an asset to an account.
     *
     * @param _account The destination account.
     * @param _asset The asset address;
     */
    function withdraw(address _account, address _asset) external whenNotPaused {
        uint256 amount = _withdraw(_account, _asset);
        IERC20(_asset).safeTransfer(_account, amount);
    }

    /**
     * @notice Executes pending withdraw of ETH to an account.
     *
     * @param _account The destination account.
     * @param _weth The address for WETH.
     */
    function withdrawETH(address _account, address _weth) external whenNotPaused {
        uint256 amount = _withdraw(_account, _weth);
        IWETH(_weth).withdraw(amount);
        (bool sent, ) = _account.call{value: amount}("");
        require(sent, "Failed to withdraw ETH");
    }

    /**
     * @notice Submit a prepared batch as a new rollup block.
     *
     * @param _blockId Rollup block id
     * @param _transitions List of layer-2 transitions
     */
    function commitBlock(uint256 _blockId, bytes[] calldata _transitions) external whenNotPaused onlyOperator {
        require(_blockId == blocks.length, "Wrong block ID");

        bytes32[] memory leafs = new bytes32[](_transitions.length);
        for (uint256 i = 0; i < _transitions.length; i++) {
            leafs[i] = keccak256(_transitions[i]);
        }
        bytes32 root = MerkleTree.getMerkleRoot(leafs);

        // Loop over transition and handle these cases:
        // 1- deposit: update the pending deposit record
        // 2- withdraw: create a pending withdraw-commit record
        // 3- commitment sync: fill the "intents" array for future executeBlock()
        // 4- balance sync: update the pending balance sync record

        uint256[] memory intentIndexes = new uint256[](_transitions.length);
        uint32 numIntents = 0;

        for (uint256 i = 0; i < _transitions.length; i++) {
            uint8 transitionType = Transitions.extractTransitionType(_transitions[i]);
            if (
                transitionType == Transitions.TRANSITION_TYPE_COMMIT ||
                transitionType == Transitions.TRANSITION_TYPE_UNCOMMIT
            ) {
                continue;
            } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_COMMITMENT) {
                intentIndexes[numIntents++] = i;
            } else if (transitionType == Transitions.TRANSITION_TYPE_DEPOSIT) {
                // Update the pending deposit record.
                dt.DepositTransition memory dp = Transitions.decodeDepositTransition(_transitions[i]);
                uint256 depositId = pendingDepositsCommitHead;
                require(depositId < pendingDepositsTail, "invalid deposit transition, no pending deposits");

                PendingDeposit memory pend = pendingDeposits[depositId];
                bytes32 dhash = keccak256(abi.encodePacked(dp.account, dp.assetId, dp.amount));
                require(pend.dhash == dhash, "invalid deposit transition, mismatch or wrong ordering");

                pendingDeposits[depositId].status = PendingDepositStatus.Done;
                pendingDeposits[depositId].blockId = uint64(_blockId); // "done": block holding the transition
                pendingDepositsCommitHead++;
            } else if (transitionType == Transitions.TRANSITION_TYPE_WITHDRAW) {
                // Append the pending withdraw-commit record for this blockId.
                dt.WithdrawTransition memory wd = Transitions.decodeWithdrawTransition(_transitions[i]);
                pendingWithdrawCommits[_blockId].push(
                    PendingWithdrawCommit({account: wd.account, assetId: wd.assetId, amount: wd.amount})
                );
            } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_BALANCE) {
                // Update the pending balance sync record.
                dt.BalanceSyncTransition memory bs = Transitions.decodeBalanceSyncTransition(_transitions[i]);
                uint256 syncId = pendingBalanceSyncsCommitHead;
                require(syncId < pendingBalanceSyncsTail, "invalid balance sync transition, no pending balance syncs");

                PendingBalanceSync memory pend = pendingBalanceSyncs[syncId];
                bytes32 bhash = keccak256(abi.encodePacked(bs.strategyId, bs.newAssetDelta));
                require(pend.bhash == bhash, "invalid balance sync transition, mismatch or wrong ordering");

                pendingBalanceSyncs[syncId].status = PendingBalanceSyncStatus.Done;
                pendingBalanceSyncs[syncId].blockId = uint64(_blockId); // "done": block holding the transition
                pendingBalanceSyncsCommitHead++;
            }
        }

        // Compute the intent hash.
        bytes32 intentHash = bytes32(0);
        if (numIntents > 0) {
            bytes32[] memory intents = new bytes32[](numIntents);
            for (uint256 i = 0; i < numIntents; i++) {
                intents[i] = keccak256(_transitions[intentIndexes[i]]);
            }
            intentHash = keccak256(abi.encodePacked(intents));
        }

        dt.Block memory rollupBlock =
            dt.Block({
                rootHash: root,
                intentHash: intentHash,
                blockTime: uint128(block.number),
                blockSize: uint128(_transitions.length)
            });
        blocks.push(rollupBlock);

        emit RollupBlockCommitted(_blockId);
    }

    /**
     * @notice Execute a rollup block after it passes the challenge period.
     * @dev Note: only the "intent" transitions (commitment sync) are given to executeBlock() instead of
     * re-sending the whole rollup block. This includes the case of a rollup block with zero intents.
     *
     * @param _intents List of CommitmentSync transitions of the rollup block
     */
    function executeBlock(bytes[] calldata _intents) external whenNotPaused {
        uint256 blockId = countExecuted;
        require(blockId < blocks.length, "No blocks pending execution");
        require(blocks[blockId].blockTime + blockChallengePeriod < block.number, "Block still in challenge period");

        // Validate the input intent transitions.
        bytes32 intentHash = bytes32(0);
        if (_intents.length > 0) {
            bytes32[] memory hashes = new bytes32[](_intents.length);
            for (uint256 i = 0; i < _intents.length; i++) {
                hashes[i] = keccak256(_intents[i]);
            }

            intentHash = keccak256(abi.encodePacked(hashes));
        }

        require(intentHash == blocks[blockId].intentHash, "Invalid block intent transitions");

        // Decode the intent transitions and execute the strategy updates.
        for (uint256 i = 0; i < _intents.length; i++) {
            dt.CommitmentSyncTransition memory cs = Transitions.decodeCommitmentSyncTransition(_intents[i]);

            address stAddr = registry.strategyIndexToAddress(cs.strategyId);
            require(stAddr != address(0), "Unknown strategy ID");
            IStrategy strategy = IStrategy(stAddr);

            if (cs.pendingCommitAmount > cs.pendingUncommitAmount) {
                uint256 commitAmount = cs.pendingCommitAmount.sub(cs.pendingUncommitAmount);
                IERC20(strategy.getAssetAddress()).safeIncreaseAllowance(stAddr, commitAmount);
                strategy.aggregateCommit(commitAmount);
                strategyAssetBalances[cs.strategyId] = strategyAssetBalances[cs.strategyId].add(commitAmount);
            } else if (cs.pendingCommitAmount < cs.pendingUncommitAmount) {
                uint256 uncommitAmount = cs.pendingUncommitAmount.sub(cs.pendingCommitAmount);
                strategy.aggregateUncommit(uncommitAmount);
                strategyAssetBalances[cs.strategyId] = strategyAssetBalances[cs.strategyId].sub(uncommitAmount);
            }
        }

        countExecuted++;

        // Delete pending deposit records finalized by this block.
        while (pendingDepositsExecuteHead < pendingDepositsCommitHead) {
            PendingDeposit memory pend = pendingDeposits[pendingDepositsExecuteHead];
            if (pend.status != PendingDepositStatus.Done || pend.blockId > blockId) {
                break;
            }
            delete pendingDeposits[pendingDepositsExecuteHead];
            pendingDepositsExecuteHead++;
        }

        // Aggregate the pending withdraw-commit records for this blockId into the final
        // pending withdraw records per account (for later L1 withdraw), and delete them.
        for (uint256 i = 0; i < pendingWithdrawCommits[blockId].length; i++) {
            PendingWithdrawCommit memory pwc = pendingWithdrawCommits[blockId][i];

            // Find and increment this account's assetId total amount
            pendingWithdraws[pwc.account][pwc.assetId] += pwc.amount;
        }

        delete pendingWithdrawCommits[blockId];

        // Delete pending balance sync records finalized by this block.
        while (pendingBalanceSyncsExecuteHead < pendingBalanceSyncsCommitHead) {
            PendingBalanceSync memory pend = pendingBalanceSyncs[pendingBalanceSyncsExecuteHead];
            if (pend.status != PendingBalanceSyncStatus.Done || pend.blockId > blockId) {
                break;
            }
            delete pendingBalanceSyncs[pendingBalanceSyncsExecuteHead];
            pendingBalanceSyncsExecuteHead++;
        }

        emit RollupBlockExecuted(blockId);
    }

    /**
     * @notice Sync the latest L1 strategy asset balance to L2
     * @dev L2 operator will submit BalanceSync transition based on the emitted event
     *
     * @param _strategyId Strategy id
     */
    function syncBalance(uint32 _strategyId) external whenNotPaused onlyOperator {
        address stAddr = registry.strategyIndexToAddress(_strategyId);
        require(stAddr != address(0), "Unknown strategy ID");

        uint256 newBalance = IStrategy(stAddr).syncBalance();
        uint256 oldBalance = strategyAssetBalances[_strategyId];
        int256 delta;
        if (newBalance >= oldBalance) {
            delta = int256(newBalance.sub(oldBalance));
        } else {
            delta = -int256(oldBalance.sub(newBalance));
        }
        strategyAssetBalances[_strategyId] = newBalance;

        // Add a pending balance sync record.
        uint256 syncId = pendingBalanceSyncsTail++;
        bytes32 bhash = keccak256(abi.encodePacked(_strategyId, delta));
        pendingBalanceSyncs[syncId] = PendingBalanceSync({
            bhash: bhash,
            blockId: uint64(blocks.length), // "pending": baseline of censorship delay
            status: PendingBalanceSyncStatus.Pending
        });

        emit BalanceSync(_strategyId, delta, syncId);
    }

    /**
     * @notice Dispute a transition in a block.
     * @dev Provide the transition proofs of the previous (valid) transition
     * and the disputed transition, the account proof, and the strategy proof. Both the account proof and
     * strategy proof are always needed even if the disputed transition only updates the account or only
     * updates the strategy because the transition stateRoot = hash(accountStateRoot, strategyStateRoot).
     * If the transition is invalid, prune the chain from that invalid block.
     *
     * @param _prevTransitionProof The inclusion proof of the transition immediately before the fraudulent transition.
     * @param _invalidTransitionProof The inclusion proof of the fraudulent transition.
     * @param _accountProof The inclusion proof of the account involved.
     * @param _strategyProof The inclusion proof of the strategy involved.
     */
    function disputeTransition(
        dt.TransitionProof calldata _prevTransitionProof,
        dt.TransitionProof calldata _invalidTransitionProof,
        dt.AccountProof calldata _accountProof,
        dt.StrategyProof calldata _strategyProof
    ) external {
        uint256 invalidTransitionBlockId = _invalidTransitionProof.blockId;
        dt.Block memory invalidTransitionBlock = blocks[invalidTransitionBlockId];
        require(
            invalidTransitionBlock.blockTime + blockChallengePeriod > block.number,
            "Block challenge period is over"
        );

        bool success;
        bytes memory returnData;
        (success, returnData) = address(transitionDisputer).call(
            abi.encodeWithSelector(
                transitionDisputer.disputeTransition.selector,
                _prevTransitionProof,
                _invalidTransitionProof,
                _accountProof,
                _strategyProof,
                blocks[_prevTransitionProof.blockId],
                invalidTransitionBlock,
                registry
            )
        );

        if (success) {
            string memory reason = abi.decode((returnData), (string));
            _revertBlock(invalidTransitionBlockId, reason);
        } else {
            revert("Failed to dispute");
        }
    }

    /**
     * @notice Dispute if operator failed to reflect an L1-initiated priority tx
     * in a rollup block within the maxPriorityTxDelay
     */
    function disputePriorityTxDelay() external {
        uint256 currentBlockId = getCurrentBlockId();

        if (pendingDepositsCommitHead < pendingDepositsTail) {
            if (currentBlockId.sub(pendingDeposits[pendingDepositsCommitHead].blockId) > maxPriorityTxDelay) {
                _pause();
                return;
            }
        }

        if (pendingBalanceSyncsCommitHead < pendingBalanceSyncsTail) {
            if (currentBlockId.sub(pendingBalanceSyncs[pendingBalanceSyncsCommitHead].blockId) > maxPriorityTxDelay) {
                _pause();
                return;
            }
        }
        revert("Not exceed max priority tx delay");
    }

    /**
     * @notice Called by the owner to pause contract
     * @dev emergency use only
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Called by the owner to unpause contract
     * @dev emergency use only
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Owner drains one type of tokens when the contract is paused
     * @dev emergency use only
     *
     * @param _asset drained asset address
     * @param _amount drained asset amount
     */
    function drainToken(address _asset, uint256 _amount) external whenPaused onlyOwner {
        IERC20(_asset).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Owner drains ETH when the contract is paused
     * @dev This is for emergency situations.
     *
     * @param _amount drained ETH amount
     */
    function drainETH(uint256 _amount) external whenPaused onlyOwner {
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to drain ETH");
    }

    /**
     * @notice Called by the owner to set blockChallengePeriod
     * @param _blockChallengePeriod delay (in # of ETH blocks) to challenge a rollup block
     */
    function setBlockChallengePeriod(uint256 _blockChallengePeriod) external onlyOwner {
        blockChallengePeriod = _blockChallengePeriod;
    }

    /**
     * @notice Called by the owner to set maxPriorityTxDelay
     * @param _maxPriorityTxDelay delay (in # of rollup blocks) to reflect an L1-initiated tx in a rollup block
     */
    function setMaxPriorityTxDelay(uint256 _maxPriorityTxDelay) external onlyOwner {
        maxPriorityTxDelay = _maxPriorityTxDelay;
    }

    /**
     * @notice Called by the owner to set operator account address
     * @param _operator operator's ETH address
     */
    function setOperator(address _operator) external onlyOwner {
        emit OperatorChanged(operator, _operator);
        operator = _operator;
    }

    /**
     * @notice Called by the owner to set net deposit limit
     * @param _asset asset token address
     * @param _limit asset net deposit limit amount
     */
    function setNetDepositLimit(address _asset, uint256 _limit) external onlyOwner {
        uint32 assetId = registry.assetAddressToIndex(_asset);
        require(assetId != 0, "Unknown asset");
        netDepositLimits[_asset] = _limit;
    }

    /**
     * @notice Get current rollup block id
     * @return current rollup block id
     */
    function getCurrentBlockId() public view returns (uint256) {
        return blocks.length - 1;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice internal deposit processing without actual token transfer.
     *
     * @param _asset The asset token address.
     * @param _amount The asset token amount.
     */
    function _deposit(address _asset, uint256 _amount) private {
        address account = msg.sender;
        uint32 assetId = registry.assetAddressToIndex(_asset);

        require(assetId != 0, "Unknown asset");

        uint256 netDeposit = netDeposits[_asset].add(_amount);
        require(netDeposit <= netDepositLimits[_asset], "net deposit exceeds limit");
        netDeposits[_asset] = netDeposit;

        // Add a pending deposit record.
        uint256 depositId = pendingDepositsTail++;
        bytes32 dhash = keccak256(abi.encodePacked(account, assetId, _amount));
        pendingDeposits[depositId] = PendingDeposit({
            dhash: dhash,
            blockId: uint64(blocks.length), // "pending": baseline of censorship delay
            status: PendingDepositStatus.Pending
        });

        emit AssetDeposited(account, assetId, _amount, depositId);
    }

    /**
     * @notice internal withdrawal processing without actual token transfer.
     *
     * @param _account The destination account.
     * @param _asset The asset token address.
     * @return amount to withdraw
     */
    function _withdraw(address _account, address _asset) private returns (uint256) {
        uint32 assetId = registry.assetAddressToIndex(_asset);
        require(assetId > 0, "Asset not registered");

        uint256 amount = pendingWithdraws[_account][assetId];
        require(amount > 0, "Nothing to withdraw");

        if (netDeposits[_asset] < amount) {
            netDeposits[_asset] = 0;
        } else {
            netDeposits[_asset] = netDeposits[_asset].sub(amount);
        }
        pendingWithdraws[_account][assetId] = 0;

        emit AssetWithdrawn(_account, assetId, amount);
        return amount;
    }

    /**
     * @notice Revert rollup block on dispute success
     *
     * @param _blockId Rollup block id
     * @param _reason Revert reason
     */
    function _revertBlock(uint256 _blockId, string memory _reason) private {
        // pause contract
        _pause();

        // revert blocks and pending states
        while (blocks.length > _blockId) {
            pendingWithdrawCommits[blocks.length - 1];
            blocks.pop();
        }
        bool first;
        for (uint256 i = pendingDepositsExecuteHead; i < pendingDepositsTail; i++) {
            if (pendingDeposits[i].blockId >= _blockId) {
                if (!first) {
                    pendingDepositsCommitHead = i;
                    first = true;
                }
                pendingDeposits[i].blockId = uint64(_blockId);
                pendingDeposits[i].status = PendingDepositStatus.Pending;
            }
        }
        first = false;
        for (uint256 i = pendingBalanceSyncsExecuteHead; i < pendingBalanceSyncsTail; i++) {
            if (pendingBalanceSyncs[i].blockId >= _blockId) {
                if (!first) {
                    pendingBalanceSyncsCommitHead = i;
                    first = true;
                }
                pendingBalanceSyncs[i].blockId = uint64(_blockId);
                pendingBalanceSyncs[i].status = PendingBalanceSyncStatus.Pending;
            }
        }

        emit RollupBlockReverted(_blockId, _reason);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library DataTypes {
    struct Block {
        bytes32 rootHash;
        bytes32 intentHash; // hash of L2-to-L1 commitment sync transitions
        uint128 blockTime; // blockNum when this rollup block is committed
        uint128 blockSize; // number of transitions in the block
    }

    struct InitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
    }

    struct DepositTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // must provide L1 address for "pending deposit" handling
        uint32 accountId; // needed for transition evaluation in case of dispute
        uint32 assetId;
        uint256 amount;
    }

    struct WithdrawTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // must provide L1 target address for "pending withdraw" handling
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes signature;
    }

    struct CommitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 assetAmount;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes signature;
    }

    struct UncommitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 stTokenAmount;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes signature;
    }

    struct BalanceSyncTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        int256 newAssetDelta;
    }

    struct CommitmentSyncTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint256 pendingCommitAmount;
        uint256 pendingUncommitAmount;
    }

    struct AccountInfo {
        address account;
        uint32 accountId; // mapping only on L2 must be part of stateRoot
        uint256[] idleAssets; // indexed by assetId
        uint256[] stTokens; // indexed by strategyId
        uint64 timestamp; // Unix epoch (msec, UTC)
    }

    struct StrategyInfo {
        uint32 assetId;
        uint256 assetBalance;
        uint256 stTokenSupply;
        uint256 pendingCommitAmount;
        uint256 pendingUncommitAmount;
    }

    struct TransitionProof {
        bytes transition;
        uint256 blockId;
        uint32 index;
        bytes32[] siblings;
    }

    // Even when the disputed transition only affects an account without not a strategy
    // (e.g. deposit), or only affects a strategy without an account (e.g. syncBalance),
    // both AccountProof and StrategyProof must be sent to at least give the root hashes
    // of the two separate Merkle trees (account and strategy).
    // Each transition stateRoot = hash(accountStateRoot, strategyStateRoot).
    struct AccountProof {
        bytes32 stateRoot; // for the account Merkle tree
        AccountInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct StrategyProof {
        bytes32 stateRoot; // for the strategy Merkle tree
        StrategyInfo value;
        uint32 index;
        bytes32[] siblings;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import {DataTypes as dt} from "./libraries/DataTypes.sol";
import "./libraries/MerkleTree.sol";
import "./libraries/Transitions.sol";
import "./TransitionEvaluator.sol";
import "./Registry.sol";

contract TransitionDisputer {
    // state root of empty strategy set and empty account set
    bytes32 public constant INIT_TRANSITION_STATE_ROOT =
        bytes32(0xcf277fb80a82478460e8988570b718f1e083ceb76f7e271a1a1497e5975f53ae);

    using SafeMath for uint256;

    TransitionEvaluator transitionEvaluator;

    constructor(TransitionEvaluator _transitionEvaluator) {
        transitionEvaluator = _transitionEvaluator;
    }

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Dispute a transition.
     *
     * @param _prevTransitionProof The inclusion proof of the transition immediately before the disputed transition.
     * @param _invalidTransitionProof The inclusion proof of the disputed transition.
     * @param _accountProof The inclusion proof of the account involved.
     * @param _strategyProof The inclusion proof of the strategy involved.
     * @param _prevTransitionBlock The block containing the previous transition.
     * @param _invalidTransitionBlock The block containing the disputed transition.
     * @param _registry The address of the Registry contract.
     *
     * @return reason of the transition being determined as invalid
     */
    function disputeTransition(
        dt.TransitionProof calldata _prevTransitionProof,
        dt.TransitionProof calldata _invalidTransitionProof,
        dt.AccountProof calldata _accountProof,
        dt.StrategyProof calldata _strategyProof,
        dt.Block calldata _prevTransitionBlock,
        dt.Block calldata _invalidTransitionBlock,
        Registry _registry
    ) external returns (string memory) {
        if (_invalidTransitionProof.blockId == 0 && _invalidTransitionProof.index == 0) {
            require(_invalidInitTransition(_invalidTransitionProof, _invalidTransitionBlock), "no fraud detected");
            return "invalid init transition";
        }

        // ------ #1: verify sequential transitions
        // First verify that the transitions are sequential and in their respective block root hashes.
        _verifySequentialTransitions(
            _prevTransitionProof,
            _invalidTransitionProof,
            _prevTransitionBlock,
            _invalidTransitionBlock
        );

        // ------ #2: decode transitions to get post- and pre-StateRoot, and ids of account and strategy
        (bool ok, bytes32 preStateRoot, bytes32 postStateRoot, uint32 accountId, uint32 strategyId) =
            _getStateRootsAndIds(_prevTransitionProof.transition, _invalidTransitionProof.transition);
        // If not success something went wrong with the decoding...
        if (!ok) {
            // revert the block if it has an incorrectly encoded transition!
            return "invalid encoding";
        }

        // ------ #3: verify transition stateRoot == hash(accountStateRoot, strategyStateRoot)
        // The account and strategy stateRoots must always be given irrespective of what is being disputed.
        require(
            _checkTwoTreeStateRoot(preStateRoot, _accountProof.stateRoot, _strategyProof.stateRoot),
            "Failed combined two-tree stateRoot verification check"
        );

        // ------ #4: verify account and strategy inclusion
        if (accountId > 0) {
            _verifyProofInclusion(
                _accountProof.stateRoot,
                keccak256(_getAccountInfoBytes(_accountProof.value)),
                _accountProof.index,
                _accountProof.siblings
            );
        }
        if (strategyId > 0) {
            _verifyProofInclusion(
                _strategyProof.stateRoot,
                keccak256(_getStrategyInfoBytes(_strategyProof.value)),
                _strategyProof.index,
                _strategyProof.siblings
            );
        }

        // ------ #5: verify deposit account id mapping
        uint8 transitionType = Transitions.extractTransitionType(_invalidTransitionProof.transition);
        if (transitionType == Transitions.TRANSITION_TYPE_DEPOSIT) {
            DataTypes.DepositTransition memory transition =
                Transitions.decodeDepositTransition(_invalidTransitionProof.transition);
            if (_accountProof.value.account == transition.account && _accountProof.value.accountId != accountId) {
                // same account address with different id
                return "invalid account id";
            }
        }

        // ------ #6: verify transition account and strategy indexes
        if (accountId > 0) {
            require(_accountProof.index == accountId, "Supplied account index is incorrect");
        }
        if (strategyId > 0) {
            require(_strategyProof.index == strategyId, "Supplied strategy index is incorrect");
        }

        // ------ #7: evaluate transition and verify new state root
        // split function to address "stack too deep" compiler error
        return
            _evaluateInvalidTransition(
                _invalidTransitionProof.transition,
                _accountProof,
                _strategyProof,
                postStateRoot,
                _registry
            );
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice Evaluate a disputed transition
     * @dev This was split from the disputeTransition function to address "stack too deep" compiler error
     *
     * @param _invalidTransition The disputed transition.
     * @param _accountProof The inclusion proof of the account involved.
     * @param _strategyProof The inclusion proof of the strategy involved.
     * @param _postStateRoot State root of the disputed transition.
     * @param _registry The address of the Registry contract.
     */
    function _evaluateInvalidTransition(
        bytes calldata _invalidTransition,
        dt.AccountProof calldata _accountProof,
        dt.StrategyProof calldata _strategyProof,
        bytes32 _postStateRoot,
        Registry _registry
    ) private returns (string memory) {
        // Apply the transaction and verify the state root after that.
        bool ok;
        bytes memory returnData;
        // Make the external call
        (ok, returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(
                transitionEvaluator.evaluateTransition.selector,
                _invalidTransition,
                _accountProof.value,
                _strategyProof.value,
                _registry
            )
        );
        // Check if it was successful. If not, we've got to revert.
        if (!ok) {
            return "failed to evaluate";
        }
        // It was successful so let's decode the outputs to get the new leaf nodes we'll have to insert
        bytes32[2] memory outputs = abi.decode((returnData), (bytes32[2]));

        // Check if the combined new stateRoots of account and strategy Merkle trees is incorrect.
        ok = _updateAndVerify(_postStateRoot, outputs, _accountProof, _strategyProof);
        if (!ok) {
            // revert the block because we found an invalid post state root
            return "invalid post-state root";
        }

        revert("No fraud detected");
    }

    /**
     * @notice Get state roots, account id, and strategy id of the disputed transition.
     *
     * @param _preStateTransition transition immediately before the disputed transition
     * @param _invalidTransition the disputed transition
     */
    function _getStateRootsAndIds(bytes memory _preStateTransition, bytes memory _invalidTransition)
        private
        returns (
            bool,
            bytes32,
            bytes32,
            uint32,
            uint32
        )
    {
        bool success;
        bytes memory returnData;
        bytes32 preStateRoot;
        bytes32 postStateRoot;
        uint32 accountId;
        uint32 strategyId;

        // First decode the prestate root
        (success, returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(transitionEvaluator.getTransitionStateRootAndAccessIds.selector, _preStateTransition)
        );

        // Make sure the call was successful
        require(success, "If the preStateRoot is invalid, then prove that invalid instead");
        (preStateRoot, , ) = abi.decode((returnData), (bytes32, uint32, uint32));

        // Now that we have the prestateRoot, let's decode the postState
        (success, returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(TransitionEvaluator.getTransitionStateRootAndAccessIds.selector, _invalidTransition)
        );

        // If the call was successful let's decode!
        if (success) {
            (postStateRoot, accountId, strategyId) = abi.decode((returnData), (bytes32, uint32, uint32));
        }
        return (success, preStateRoot, postStateRoot, accountId, strategyId);
    }

    /**
     * @notice Evaluate if the init transition of the first block is invalid
     *
     * @param _initTransitionProof The inclusion proof of the disputed initial transition.
     * @param _firstBlock The first rollup block
     */
    function _invalidInitTransition(dt.TransitionProof calldata _initTransitionProof, dt.Block calldata _firstBlock)
        private
        returns (bool)
    {
        require(_checkTransitionInclusion(_initTransitionProof, _firstBlock), "transition not included in block");
        (bool success, bytes memory returnData) =
            address(transitionEvaluator).call(
                abi.encodeWithSelector(
                    TransitionEvaluator.getTransitionStateRootAndAccessIds.selector,
                    _initTransitionProof.transition
                )
            );
        if (!success) {
            return true; // transition is invalid
        }
        (bytes32 postStateRoot, , ) = abi.decode((returnData), (bytes32, uint32, uint32));

        // Transition is invalid if stateRoot not match the expected init root
        // It's OK that other fields of the transition are incorrect.
        return postStateRoot != INIT_TRANSITION_STATE_ROOT;
    }

    /**
     * @notice Get the bytes value for this account.
     *
     * @param _accountInfo Account info
     */
    function _getAccountInfoBytes(dt.AccountInfo memory _accountInfo) private pure returns (bytes memory) {
        // If it's an empty storage slot, return 32 bytes of zeros (empty value)
        if (
            _accountInfo.account == address(0) &&
            _accountInfo.accountId == 0 &&
            _accountInfo.idleAssets.length == 0 &&
            _accountInfo.stTokens.length == 0 &&
            _accountInfo.timestamp == 0
        ) {
            return abi.encodePacked(uint256(0));
        }
        // Here we don't use `abi.encode([struct])` because it's not clear
        // how to generate that encoding client-side.
        return
            abi.encode(
                _accountInfo.account,
                _accountInfo.accountId,
                _accountInfo.idleAssets,
                _accountInfo.stTokens,
                _accountInfo.timestamp
            );
    }

    /**
     * @notice Get the bytes value for this strategy.
     * @param _strategyInfo Strategy info
     */
    function _getStrategyInfoBytes(dt.StrategyInfo memory _strategyInfo) private pure returns (bytes memory) {
        // If it's an empty storage slot, return 32 bytes of zeros (empty value)
        if (
            _strategyInfo.assetId == 0 &&
            _strategyInfo.assetBalance == 0 &&
            _strategyInfo.stTokenSupply == 0 &&
            _strategyInfo.pendingCommitAmount == 0 &&
            _strategyInfo.pendingUncommitAmount == 0
        ) {
            return abi.encodePacked(uint256(0));
        }
        // Here we don't use `abi.encode([struct])` because it's not clear
        // how to generate that encoding client-side.
        return
            abi.encode(
                _strategyInfo.assetId,
                _strategyInfo.assetBalance,
                _strategyInfo.stTokenSupply,
                _strategyInfo.pendingCommitAmount,
                _strategyInfo.pendingUncommitAmount
            );
    }

    /**
     * @notice Verifies that two transitions were included one after another.
     * @dev This is used to make sure we are comparing the correct prestate & poststate.
     */
    function _verifySequentialTransitions(
        dt.TransitionProof calldata _tp0,
        dt.TransitionProof calldata _tp1,
        dt.Block calldata _prevTransitionBlock,
        dt.Block calldata _invalidTransitionBlock
    ) private pure returns (bool) {
        // Start by checking if they are in the same block
        if (_tp0.blockId == _tp1.blockId) {
            // If the blocknumber is the same, check that tp0 precedes tp1
            require(_tp0.index + 1 == _tp1.index, "Transitions must be sequential");
            require(_tp1.index < _invalidTransitionBlock.blockSize, "_tp1 outside block range");
        } else {
            // If not in the same block, check that:
            // 0) the blocks are one after another
            require(_tp0.blockId + 1 == _tp1.blockId, "Blocks must be sequential or equal");

            // 1) the index of tp0 is the last in its block
            require(_tp0.index == _prevTransitionBlock.blockSize - 1, "_tp0 must be last in its block");

            // 2) the index of tp1 is the first in its block
            require(_tp1.index == 0, "_tp1 must be first in its block");
        }

        // Verify inclusion
        require(_checkTransitionInclusion(_tp0, _prevTransitionBlock), "_tp0 must be included in its block");
        require(_checkTransitionInclusion(_tp1, _invalidTransitionBlock), "_tp1 must be included in its block");

        return true;
    }

    /**
     * @notice Check to see if a transition is included in the block.
     */
    function _checkTransitionInclusion(dt.TransitionProof memory _tp, dt.Block memory _block)
        private
        pure
        returns (bool)
    {
        bytes32 rootHash = _block.rootHash;
        bytes32 leafHash = keccak256(_tp.transition);
        return MerkleTree.verify(rootHash, leafHash, _tp.index, _tp.siblings);
    }

    /**
     * @notice Check if the combined stateRoot of the two Merkle trees (account, strategy) matches the stateRoot.
     */
    function _checkTwoTreeStateRoot(
        bytes32 _stateRoot,
        bytes32 _accountStateRoot,
        bytes32 _strategyStateRoot
    ) private pure returns (bool) {
        bytes32 newStateRoot = keccak256(abi.encodePacked(_accountStateRoot, _strategyStateRoot));
        return (_stateRoot == newStateRoot);
    }

    /**
     * @notice Check if an account or strategy proof is included in the state root.
     */
    function _verifyProofInclusion(
        bytes32 _stateRoot,
        bytes32 _leafHash,
        uint32 _index,
        bytes32[] memory _siblings
    ) private pure {
        bool ok = MerkleTree.verify(_stateRoot, _leafHash, _index, _siblings);
        require(ok, "Failed proof inclusion verification check");
    }

    /**
     * @notice Update the account and strategy Merkle trees with their new leaf nodes and check validity.
     */
    function _updateAndVerify(
        bytes32 _stateRoot,
        bytes32[2] memory _leafHashes,
        dt.AccountProof memory _accountProof,
        dt.StrategyProof memory _strategyProof
    ) private pure returns (bool) {
        if (_leafHashes[0] == bytes32(0) && _leafHashes[1] == bytes32(0)) {
            return false;
        }

        // If there is an account update, compute its new Merkle tree root.
        bytes32 accountStateRoot = _accountProof.stateRoot;
        if (_leafHashes[0] != bytes32(0)) {
            accountStateRoot = MerkleTree.computeRoot(_leafHashes[0], _accountProof.index, _accountProof.siblings);
        }

        // If there is a strategy update, compute its new Merkle tree root.
        bytes32 strategyStateRoot = _strategyProof.stateRoot;
        if (_leafHashes[1] != bytes32(0)) {
            strategyStateRoot = MerkleTree.computeRoot(_leafHashes[1], _strategyProof.index, _strategyProof.siblings);
        }

        return _checkTwoTreeStateRoot(_stateRoot, accountStateRoot, strategyStateRoot);
    }
}

// SPDX-License-Identifier: MIT
/*
(The MIT License)

Copyright 2020 Optimism

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity >0.5.0 <0.8.0;

/**
 * @title MerkleTree
 * @author River Keefer
 */
library MerkleTree {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying,
     * then this may allow empty leaves past _elements.length to pass a verification check down the line.
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(bytes32[] memory _elements) internal pure returns (bytes32) {
        require(_elements.length > 0, "MerkleTree: Must provide at least one leaf hash.");

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[32] memory defaults =
            [
                0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
                0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
                0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
                0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
                0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
                0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
                0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
                0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
                0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
                0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
                0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
                0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
                0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
                0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
                0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
                0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10,
                0x776a31db34a1a0a7caaf862cffdfff1789297ffadc380bd3d39281d340abd3ad,
                0xe2e7610b87a5fdf3a72ebe271287d923ab990eefac64b6e59d79f8b7e08c46e3,
                0x504364a5c6858bf98fff714ab5be9de19ed31a976860efbd0e772a2efe23e2e0,
                0x4f05f4acb83f5b65168d9fef89d56d4d77b8944015e6b1eed81b0238e2d0dba3,
                0x44a6d974c75b07423e1d6d33f481916fdd45830aea11b6347e700cd8b9f0767c,
                0xedf260291f734ddac396a956127dde4c34c0cfb8d8052f88ac139658ccf2d507,
                0x6075c657a105351e7f0fce53bc320113324a522e8fd52dc878c762551e01a46e,
                0x6ca6a3f763a9395f7da16014725ca7ee17e4815c0ff8119bf33f273dee11833b,
                0x1c25ef10ffeb3c7d08aa707d17286e0b0d3cbcb50f1bd3b6523b63ba3b52dd0f,
                0xfffc43bd08273ccf135fd3cacbeef055418e09eb728d727c4d5d5c556cdea7e3,
                0xc5ab8111456b1f28f3c7a0a604b4553ce905cb019c463ee159137af83c350b22,
                0x0ff273fcbf4ae0f2bd88d6cf319ff4004f8d7dca70d4ced4e74d2c74139739e6,
                0x7fa06ba11241ddd5efdc65d4e39c9f6991b74fd4b81b62230808216c876f827c,
                0x7e275adf313a996c7e2950cac67caba02a5ff925ebf9906b58949f3e77aec5b9,
                0x8f6162fa308d2b3a15dc33cffac85f13ab349173121645aedf00f471663108be,
                0x78ccaaab73373552f207a63599de54d7d8d0c1805f86ce7da15818d09f4cff62
            ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize; // rowSize / 2
        bool rowSizeIsOdd; // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling = _elements[(2 * i)];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibling nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings
    ) internal pure returns (bool) {
        return (_root == computeRoot(_leaf, _index, _siblings));
    }

    /**
     * Compute the root of a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibling nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @return The new merkle root.
     */
    function computeRoot(
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings
    ) internal pure returns (bytes32) {
        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings[i]));
            }
            _index >>= 1;
        }

        return computedRoot;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "../libraries/DataTypes.sol";

library Transitions {
    // Transition Types
    uint8 public constant TRANSITION_TYPE_INVALID = 0;
    uint8 public constant TRANSITION_TYPE_DEPOSIT = 1;
    uint8 public constant TRANSITION_TYPE_WITHDRAW = 2;
    uint8 public constant TRANSITION_TYPE_COMMIT = 3;
    uint8 public constant TRANSITION_TYPE_UNCOMMIT = 4;
    uint8 public constant TRANSITION_TYPE_SYNC_COMMITMENT = 5;
    uint8 public constant TRANSITION_TYPE_SYNC_BALANCE = 6;
    uint8 public constant TRANSITION_TYPE_INIT = 7;

    function extractTransitionType(bytes memory _bytes) internal pure returns (uint8) {
        uint8 transitionType;
        assembly {
            transitionType := mload(add(_bytes, 0x20))
        }
        return transitionType;
    }

    function decodeDepositTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, address account, uint32 accountId, uint32 assetId, uint256 amount) =
            abi.decode((_rawBytes), (uint8, bytes32, address, uint32, uint32, uint256));
        DataTypes.DepositTransition memory transition =
            DataTypes.DepositTransition(transitionType, stateRoot, account, accountId, assetId, amount);
        return transition;
    }

    function decodeWithdrawTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawTransition memory)
    {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            address account,
            uint32 accountId,
            uint32 assetId,
            uint256 amount,
            uint64 timestamp,
            bytes memory signature
        ) = abi.decode((_rawBytes), (uint8, bytes32, address, uint32, uint32, uint256, uint64, bytes));
        DataTypes.WithdrawTransition memory transition =
            DataTypes.WithdrawTransition(
                transitionType,
                stateRoot,
                account,
                accountId,
                assetId,
                amount,
                timestamp,
                signature
            );
        return transition;
    }

    function decodeCommitTransition(bytes memory _rawBytes) internal pure returns (DataTypes.CommitTransition memory) {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            uint32 accountId,
            uint32 strategyId,
            uint256 assetAmount,
            uint64 timestamp,
            bytes memory signature
        ) = abi.decode((_rawBytes), (uint8, bytes32, uint32, uint32, uint256, uint64, bytes));
        DataTypes.CommitTransition memory transition =
            DataTypes.CommitTransition(
                transitionType,
                stateRoot,
                accountId,
                strategyId,
                assetAmount,
                timestamp,
                signature
            );
        return transition;
    }

    function decodeUncommitTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UncommitTransition memory)
    {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            uint32 accountId,
            uint32 strategyId,
            uint256 stTokenAmount,
            uint64 timestamp,
            bytes memory signature
        ) = abi.decode((_rawBytes), (uint8, bytes32, uint32, uint32, uint256, uint64, bytes));
        DataTypes.UncommitTransition memory transition =
            DataTypes.UncommitTransition(
                transitionType,
                stateRoot,
                accountId,
                strategyId,
                stTokenAmount,
                timestamp,
                signature
            );
        return transition;
    }

    function decodeCommitmentSyncTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.CommitmentSyncTransition memory)
    {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            uint32 strategyId,
            uint256 pendingCommitAmount,
            uint256 pendingUncommitAmount
        ) = abi.decode((_rawBytes), (uint8, bytes32, uint32, uint256, uint256));
        DataTypes.CommitmentSyncTransition memory transition =
            DataTypes.CommitmentSyncTransition(
                transitionType,
                stateRoot,
                strategyId,
                pendingCommitAmount,
                pendingUncommitAmount
            );
        return transition;
    }

    function decodeBalanceSyncTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.BalanceSyncTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 strategyId, int256 newAssetDelta) =
            abi.decode((_rawBytes), (uint8, bytes32, uint32, int256));
        DataTypes.BalanceSyncTransition memory transition =
            DataTypes.BalanceSyncTransition(transitionType, stateRoot, strategyId, newAssetDelta);
        return transition;
    }

    function decodeInitTransition(bytes memory _rawBytes) internal pure returns (DataTypes.InitTransition memory) {
        (uint8 transitionType, bytes32 stateRoot) = abi.decode((_rawBytes), (uint8, bytes32));
        DataTypes.InitTransition memory transition = DataTypes.InitTransition(transitionType, stateRoot);
        return transition;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

/* Internal Imports */
import "./libraries/DataTypes.sol";
import "./libraries/Transitions.sol";
import "./Registry.sol";
import "./strategies/interfaces/IStrategy.sol";

contract TransitionEvaluator {
    using SafeMath for uint256;

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Evaluate a transition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @param _registry The address of the Registry contract.
     * @return hashes of account and strategy after applying the transition.
     */
    function evaluateTransition(
        bytes calldata _transition,
        DataTypes.AccountInfo calldata _accountInfo,
        DataTypes.StrategyInfo calldata _strategyInfo,
        Registry _registry
    ) external view returns (bytes32[2] memory) {
        // Extract the transition type
        uint8 transitionType = Transitions.extractTransitionType(_transition);
        bytes32[2] memory outputs;
        DataTypes.AccountInfo memory updatedAccountInfo;
        DataTypes.StrategyInfo memory updatedStrategyInfo;
        // Apply the transition and record the resulting storage slots
        if (transitionType == Transitions.TRANSITION_TYPE_DEPOSIT) {
            DataTypes.DepositTransition memory deposit = Transitions.decodeDepositTransition(_transition);
            updatedAccountInfo = _applyDepositTransition(deposit, _accountInfo);
            outputs[0] = _getAccountInfoHash(updatedAccountInfo);
        } else if (transitionType == Transitions.TRANSITION_TYPE_WITHDRAW) {
            DataTypes.WithdrawTransition memory withdraw = Transitions.decodeWithdrawTransition(_transition);
            updatedAccountInfo = _applyWithdrawTransition(withdraw, _accountInfo);
            outputs[0] = _getAccountInfoHash(updatedAccountInfo);
        } else if (transitionType == Transitions.TRANSITION_TYPE_COMMIT) {
            DataTypes.CommitTransition memory commit = Transitions.decodeCommitTransition(_transition);
            (updatedAccountInfo, updatedStrategyInfo) = _applyCommitTransition(
                commit,
                _accountInfo,
                _strategyInfo,
                _registry
            );
            outputs[0] = _getAccountInfoHash(updatedAccountInfo);
            outputs[1] = _getStrategyInfoHash(updatedStrategyInfo);
        } else if (transitionType == Transitions.TRANSITION_TYPE_UNCOMMIT) {
            DataTypes.UncommitTransition memory uncommit = Transitions.decodeUncommitTransition(_transition);
            (updatedAccountInfo, updatedStrategyInfo) = _applyUncommitTransition(uncommit, _accountInfo, _strategyInfo);
            outputs[0] = _getAccountInfoHash(updatedAccountInfo);
            outputs[1] = _getStrategyInfoHash(updatedStrategyInfo);
        } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_COMMITMENT) {
            DataTypes.CommitmentSyncTransition memory commitmentSync =
                Transitions.decodeCommitmentSyncTransition(_transition);
            updatedStrategyInfo = _applyCommitmentSyncTransition(commitmentSync, _strategyInfo);
            outputs[1] = _getStrategyInfoHash(updatedStrategyInfo);
        } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_BALANCE) {
            DataTypes.BalanceSyncTransition memory balanceSync = Transitions.decodeBalanceSyncTransition(_transition);
            updatedStrategyInfo = _applyBalanceSyncTransition(balanceSync, _strategyInfo);
            outputs[1] = _getStrategyInfoHash(updatedStrategyInfo);
        } else {
            revert("Transition type not recognized");
        }
        return outputs;
    }

    /**
     * @notice Return the (stateRoot, accountId, strategyId) for this transition.
     */
    function getTransitionStateRootAndAccessIds(bytes calldata _rawTransition)
        external
        pure
        returns (
            bytes32,
            uint32,
            uint32
        )
    {
        // Initialize memory rawTransition
        bytes memory rawTransition = _rawTransition;
        // Initialize stateRoot and account and strategy IDs.
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint8 transitionType = Transitions.extractTransitionType(rawTransition);
        if (transitionType == Transitions.TRANSITION_TYPE_DEPOSIT) {
            DataTypes.DepositTransition memory transition = Transitions.decodeDepositTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == Transitions.TRANSITION_TYPE_WITHDRAW) {
            DataTypes.WithdrawTransition memory transition = Transitions.decodeWithdrawTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == Transitions.TRANSITION_TYPE_COMMIT) {
            DataTypes.CommitTransition memory transition = Transitions.decodeCommitTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == Transitions.TRANSITION_TYPE_UNCOMMIT) {
            DataTypes.UncommitTransition memory transition = Transitions.decodeUncommitTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_COMMITMENT) {
            DataTypes.CommitmentSyncTransition memory transition =
                Transitions.decodeCommitmentSyncTransition(rawTransition);
            stateRoot = transition.stateRoot;
            strategyId = transition.strategyId;
        } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_BALANCE) {
            DataTypes.BalanceSyncTransition memory transition = Transitions.decodeBalanceSyncTransition(rawTransition);
            stateRoot = transition.stateRoot;
            strategyId = transition.strategyId;
        } else if (transitionType == Transitions.TRANSITION_TYPE_INIT) {
            DataTypes.InitTransition memory transition = Transitions.decodeInitTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else {
            revert("Transition type not recognized");
        }
        return (stateRoot, accountId, strategyId);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice Apply a DepositTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @return new account info after apply the disputed transition
     */
    function _applyDepositTransition(
        DataTypes.DepositTransition memory _transition,
        DataTypes.AccountInfo memory _accountInfo
    ) private pure returns (DataTypes.AccountInfo memory) {
        if (_accountInfo.account == address(0)) {
            // first time deposit of this account
            require(_accountInfo.accountId == 0, "empty account id must be zero");
            require(_accountInfo.idleAssets.length == 0, "empty account idleAssets must be empty");
            require(_accountInfo.stTokens.length == 0, "empty account stTokens must be empty");
            require(_accountInfo.timestamp == 0, "empty account timestamp must be zero");
            _accountInfo.account = _transition.account;
            _accountInfo.accountId = _transition.accountId;
        } else {
            require(_accountInfo.account == _transition.account, "account address not match");
            require(_accountInfo.accountId == _transition.accountId, "account id not match");
        }
        if (_transition.assetId >= _accountInfo.idleAssets.length) {
            uint256[] memory idleAssets = new uint256[](_transition.assetId + 1);
            for (uint256 i = 0; i < _accountInfo.idleAssets.length; i++) {
                idleAssets[i] = _accountInfo.idleAssets[i];
            }
            _accountInfo.idleAssets = idleAssets;
        }
        _accountInfo.idleAssets[_transition.assetId] = _accountInfo.idleAssets[_transition.assetId].add(
            _transition.amount
        );

        return _accountInfo;
    }

    /**
     * @notice Apply a WithdrawTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @return new account info after apply the disputed transition
     */
    function _applyWithdrawTransition(
        DataTypes.WithdrawTransition memory _transition,
        DataTypes.AccountInfo memory _accountInfo
    ) private pure returns (DataTypes.AccountInfo memory) {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.account,
                    _transition.assetId,
                    _transition.amount,
                    _transition.timestamp
                )
            );
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(txHash);
        require(
            ECDSA.recover(prefixedHash, _transition.signature) == _accountInfo.account,
            "Withdraw signature is invalid"
        );

        require(_accountInfo.accountId == _transition.accountId, "account id not match");
        require(_accountInfo.timestamp < _transition.timestamp, "timestamp should monotonically increasing");
        _accountInfo.timestamp = _transition.timestamp;

        _accountInfo.idleAssets[_transition.assetId] = _accountInfo.idleAssets[_transition.assetId].sub(
            _transition.amount
        );

        return _accountInfo;
    }

    /**
     * @notice Apply a CommitTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new account and strategy info after apply the disputed transition
     */
    function _applyCommitTransition(
        DataTypes.CommitTransition memory _transition,
        DataTypes.AccountInfo memory _accountInfo,
        DataTypes.StrategyInfo memory _strategyInfo,
        Registry _registry
    ) private view returns (DataTypes.AccountInfo memory, DataTypes.StrategyInfo memory) {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.strategyId,
                    _transition.assetAmount,
                    _transition.timestamp
                )
            );
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(txHash);
        require(
            ECDSA.recover(prefixedHash, _transition.signature) == _accountInfo.account,
            "Commit signature is invalid"
        );

        uint256 newStToken;
        if (_strategyInfo.assetBalance == 0 || _strategyInfo.stTokenSupply == 0) {
            require(_strategyInfo.stTokenSupply == 0, "empty strategy stTokenSupply must be zero");
            require(_strategyInfo.pendingCommitAmount == 0, "empty strategy pendingCommitAmount must be zero");
            if (_strategyInfo.assetId == 0) {
                // first time commit of new strategy
                require(_strategyInfo.pendingUncommitAmount == 0, "new strategy pendingUncommitAmount must be zero");
                address strategyAddr = _registry.strategyIndexToAddress(_transition.strategyId);
                address assetAddr = IStrategy(strategyAddr).getAssetAddress();
                _strategyInfo.assetId = _registry.assetAddressToIndex(assetAddr);
            }
            newStToken = _transition.assetAmount;
        } else {
            newStToken = _transition.assetAmount.mul(_strategyInfo.stTokenSupply).div(_strategyInfo.assetBalance);
        }

        _accountInfo.idleAssets[_strategyInfo.assetId] = _accountInfo.idleAssets[_strategyInfo.assetId].sub(
            _transition.assetAmount
        );

        if (_transition.strategyId >= _accountInfo.stTokens.length) {
            uint256[] memory stTokens = new uint256[](_transition.strategyId + 1);
            for (uint256 i = 0; i < _accountInfo.stTokens.length; i++) {
                stTokens[i] = _accountInfo.stTokens[i];
            }
            _accountInfo.stTokens = stTokens;
        }
        _accountInfo.stTokens[_transition.strategyId] = _accountInfo.stTokens[_transition.strategyId].add(newStToken);
        require(_accountInfo.accountId == _transition.accountId, "account id not match");
        require(_accountInfo.timestamp < _transition.timestamp, "timestamp should monotonically increasing");
        _accountInfo.timestamp = _transition.timestamp;

        _strategyInfo.stTokenSupply = _strategyInfo.stTokenSupply.add(newStToken);
        _strategyInfo.assetBalance = _strategyInfo.assetBalance.add(_transition.assetAmount);
        _strategyInfo.pendingCommitAmount = _strategyInfo.pendingCommitAmount.add(_transition.assetAmount);

        return (_accountInfo, _strategyInfo);
    }

    /**
     * @notice Apply a UncommitTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new account and strategy info after apply the disputed transition
     */
    function _applyUncommitTransition(
        DataTypes.UncommitTransition memory _transition,
        DataTypes.AccountInfo memory _accountInfo,
        DataTypes.StrategyInfo memory _strategyInfo
    ) private pure returns (DataTypes.AccountInfo memory, DataTypes.StrategyInfo memory) {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.strategyId,
                    _transition.stTokenAmount,
                    _transition.timestamp
                )
            );
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(txHash);
        require(
            ECDSA.recover(prefixedHash, _transition.signature) == _accountInfo.account,
            "Uncommit signature is invalid"
        );

        uint256 newIdleAsset =
            _transition.stTokenAmount.mul(_strategyInfo.assetBalance).div(_strategyInfo.stTokenSupply);

        _accountInfo.idleAssets[_strategyInfo.assetId] = _accountInfo.idleAssets[_strategyInfo.assetId].add(
            newIdleAsset
        );
        _accountInfo.stTokens[_transition.strategyId] = _accountInfo.stTokens[_transition.strategyId].sub(
            _transition.stTokenAmount
        );
        require(_accountInfo.accountId == _transition.accountId, "account id not match");
        require(_accountInfo.timestamp < _transition.timestamp, "timestamp should monotonically increasing");
        _accountInfo.timestamp = _transition.timestamp;

        _strategyInfo.stTokenSupply = _strategyInfo.stTokenSupply.sub(_transition.stTokenAmount);
        _strategyInfo.assetBalance = _strategyInfo.assetBalance.sub(newIdleAsset);
        _strategyInfo.pendingUncommitAmount = _strategyInfo.pendingUncommitAmount.add(newIdleAsset);

        return (_accountInfo, _strategyInfo);
    }

    /**
     * @notice Apply a CommitmentSyncTransition.
     *
     * @param _transition The disputed transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new strategy info after apply the disputed transition
     */
    function _applyCommitmentSyncTransition(
        DataTypes.CommitmentSyncTransition memory _transition,
        DataTypes.StrategyInfo memory _strategyInfo
    ) private pure returns (DataTypes.StrategyInfo memory) {
        require(
            _transition.pendingCommitAmount == _strategyInfo.pendingCommitAmount,
            "pending commitment amount not match"
        );
        require(
            _transition.pendingUncommitAmount == _strategyInfo.pendingUncommitAmount,
            "pending uncommitment amount not match"
        );
        _strategyInfo.pendingCommitAmount = 0;
        _strategyInfo.pendingUncommitAmount = 0;

        return _strategyInfo;
    }

    /**
     * @notice Apply a BalanceSyncTransition.
     *
     * @param _transition The disputed transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new strategy info after apply the disputed transition
     */
    function _applyBalanceSyncTransition(
        DataTypes.BalanceSyncTransition memory _transition,
        DataTypes.StrategyInfo memory _strategyInfo
    ) private pure returns (DataTypes.StrategyInfo memory) {
        if (_transition.newAssetDelta >= 0) {
            uint256 delta = uint256(_transition.newAssetDelta);
            _strategyInfo.assetBalance = _strategyInfo.assetBalance.add(delta);
        } else {
            uint256 delta = uint256(-_transition.newAssetDelta);
            _strategyInfo.assetBalance = _strategyInfo.assetBalance.sub(delta);
        }
        return _strategyInfo;
    }

    /**
     * @notice Get the hash of the AccountInfo.
     * @param _accountInfo Account info
     */
    function _getAccountInfoHash(DataTypes.AccountInfo memory _accountInfo) private pure returns (bytes32) {
        // Here we don't use `abi.encode([struct])` because it's not clear
        // how to generate that encoding client-side.
        return
            keccak256(
                abi.encode(
                    _accountInfo.account,
                    _accountInfo.accountId,
                    _accountInfo.idleAssets,
                    _accountInfo.stTokens,
                    _accountInfo.timestamp
                )
            );
    }

    /**
     * Get the hash of the StrategyInfo.
     */
    /**
     * @notice Get the hash of the StrategyInfo.
     * @param _strategyInfo Strategy info
     */
    function _getStrategyInfoHash(DataTypes.StrategyInfo memory _strategyInfo) private pure returns (bytes32) {
        // Here we don't use `abi.encode([struct])` because it's not clear
        // how to generate that encoding client-side.
        return
            keccak256(
                abi.encode(
                    _strategyInfo.assetId,
                    _strategyInfo.assetBalance,
                    _strategyInfo.stTokenSupply,
                    _strategyInfo.pendingCommitAmount,
                    _strategyInfo.pendingUncommitAmount
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    // Map asset addresses to indexes.
    mapping(address => uint32) public assetAddressToIndex;
    mapping(uint32 => address) public assetIndexToAddress;
    uint32 numAssets = 0;

    // Valid strategies.
    mapping(address => uint32) public strategyAddressToIndex;
    mapping(uint32 => address) public strategyIndexToAddress;
    uint32 numStrategies = 0;

    event AssetRegistered(address asset, uint32 assetId);
    event StrategyRegistered(address strategy, uint32 strategyId);

    /**
     * @notice Register a asset
     * @param _asset The asset token address;
     */
    function registerAsset(address _asset) external onlyOwner {
        require(assetAddressToIndex[_asset] == 0, "Asset already registered");

        // Register asset with an index >= 1 (zero is reserved).
        numAssets++;
        assetAddressToIndex[_asset] = numAssets;
        assetIndexToAddress[numAssets] = _asset;

        emit AssetRegistered(_asset, numAssets);
    }

    /**
     * @notice Register a strategy
     * @param _strategy The strategy contract address;
     */
    function registerStrategy(address _strategy) external onlyOwner {
        require(strategyAddressToIndex[_strategy] == 0, "Strategy already registered");

        // Register strategy with an index >= 1 (zero is reserved).
        numStrategies++;
        strategyAddressToIndex[_strategy] = numStrategies;
        strategyIndexToAddress[numStrategies] = _strategy;

        emit StrategyRegistered(_strategy, numStrategies);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface for DeFi strategies
 *
 * @notice Strategy provides abstraction for a DeFi strategy. A single type of asset token can be committed to or
 * uncommitted from a strategy per instructions from L2. Periodically, the yield is reflected in the asset balance and
 * synced back to L2.
 */
interface IStrategy {
    event Committed(uint256 commitAmount);

    event UnCommitted(uint256 uncommitAmount);

    event ControllerChanged(address previousController, address newController);

    /**
     * @dev Returns the address of the asset token.
     */
    function getAssetAddress() external view returns (address);

    /**
     * @dev Harvests protocol tokens and update the asset balance.
     */
    function harvest() external;

    /**
     * @dev Returns the asset balance. May sync with the protocol to update the balance.
     */
    function syncBalance() external returns (uint256);

    /**
     * @dev Commits to strategy per instructions from L2.
     *
     * @param commitAmount The aggregated asset amount to commit.
     */
    function aggregateCommit(uint256 commitAmount) external;

    /**
     * @dev Uncommits from strategy per instructions from L2.
     *
     * @param uncommitAmount The aggregated asset amount to uncommit.
     */
    function aggregateUncommit(uint256 uncommitAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

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
    constructor () internal {
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

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

