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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";

contract PriorityOperations is Ownable {
    address public controller;

    // Track pending L1-initiated even roundtrip status across L1->L2->L1.
    // Each event record ID is a count++ (i.e. it's a queue).
    // - L1 event creates it in "pending" status
    // - commitBlock() moves it to "done" status
    // - fraudulent block moves it back to "pending" status
    // - executeBlock() deletes it
    enum PendingEventStatus {
        Pending,
        Done
    }
    struct PendingEvent {
        bytes32 ehash;
        uint64 blockId; // rollup block; "pending": baseline of censorship, "done": block holding L2 transition
        PendingEventStatus status;
    }
    struct EventQueuePointer {
        uint64 executeHead; // moves up inside blockExecute() -- lowest
        uint64 commitHead; // moves up inside blockCommit() -- intermediate
        uint64 tail; // moves up inside L1 event -- highest
    }

    // pending deposit queue
    // ehash = keccak256(abi.encodePacked(account, assetId, amount))
    mapping(uint256 => PendingEvent) public pendingDeposits;
    EventQueuePointer public depositQueuePointer;

    // strategyId -> (aggregateId -> PendingExecResult)
    // ehash = keccak256(abi.encodePacked(strategyId, aggregateId, success, sharesFromBuy, amountFromSell))
    mapping(uint32 => mapping(uint256 => PendingEvent)) public pendingExecResults;
    // strategyId -> execResultQueuePointer
    mapping(uint32 => EventQueuePointer) public execResultQueuePointers;

    // group fields to avoid "stack too deep" error
    struct ExecResultInfo {
        uint32 strategyId;
        bool success;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
        uint256 blockLen;
        uint256 blockId;
    }

    struct PendingEpochUpdate {
        uint64 epoch;
        uint64 blockId; // rollup block; "pending": baseline of censorship, "done": block holding L2 transition
        PendingEventStatus status;
    }
    mapping(uint256 => PendingEpochUpdate) public pendingEpochUpdates;
    EventQueuePointer public epochQueuePointer;

    modifier onlyController() {
        require(msg.sender == controller, "caller is not controller");
        _;
    }

    function setController(address _controller) external onlyOwner {
        require(controller == address(0), "controller already set");
        controller = _controller;
    }

    /**
     * @notice Add pending deposit record.
     * @param _account The deposit account address.
     * @param _assetId The deposit asset Id.
     * @param _amount The deposit amount.
     * @param _blockId Commit block Id.
     * @return deposit Id
     */
    function addPendingDeposit(
        address _account,
        uint32 _assetId,
        uint256 _amount,
        uint256 _blockId
    ) external onlyController returns (uint64) {
        // Add a pending deposit record.
        uint64 depositId = depositQueuePointer.tail++;
        bytes32 ehash = keccak256(abi.encodePacked(_account, _assetId, _amount));
        pendingDeposits[depositId] = PendingEvent({
            ehash: ehash,
            blockId: uint64(_blockId), // "pending": baseline of censorship delay
            status: PendingEventStatus.Pending
        });
        return depositId;
    }

    /**
     * @notice Check and update the pending deposit record.
     * @param _account The deposit account address.
     * @param _assetId The deposit asset Id.
     * @param _amount The deposit amount.
     * @param _blockId Commit block Id.
     */
    function checkPendingDeposit(
        address _account,
        uint32 _assetId,
        uint256 _amount,
        uint256 _blockId
    ) external onlyController {
        EventQueuePointer memory queuePointer = depositQueuePointer;
        uint64 depositId = queuePointer.commitHead;
        require(depositId < queuePointer.tail, ErrMsg.REQ_BAD_DEP_TN);

        bytes32 ehash = keccak256(abi.encodePacked(_account, _assetId, _amount));
        require(pendingDeposits[depositId].ehash == ehash, ErrMsg.REQ_BAD_HASH);

        pendingDeposits[depositId].status = PendingEventStatus.Done;
        pendingDeposits[depositId].blockId = uint64(_blockId); // "done": block holding the transition
        queuePointer.commitHead++;
        depositQueuePointer = queuePointer;
    }

    /**
     * @notice Delete pending queue events finalized by this or previous block.
     * @param _blockId Executed block Id.
     */
    function cleanupPendingQueue(uint256 _blockId) external onlyController {
        // cleanup deposit queue
        EventQueuePointer memory dQueuePointer = depositQueuePointer;
        while (dQueuePointer.executeHead < dQueuePointer.commitHead) {
            PendingEvent memory pend = pendingDeposits[dQueuePointer.executeHead];
            if (pend.status != PendingEventStatus.Done || pend.blockId > _blockId) {
                break;
            }
            delete pendingDeposits[dQueuePointer.executeHead];
            dQueuePointer.executeHead++;
        }
        depositQueuePointer = dQueuePointer;

        // cleanup epoch queue
        EventQueuePointer memory eQueuePointer = epochQueuePointer;
        while (eQueuePointer.executeHead < eQueuePointer.commitHead) {
            PendingEpochUpdate memory pend = pendingEpochUpdates[eQueuePointer.executeHead];
            if (pend.status != PendingEventStatus.Done || pend.blockId > _blockId) {
                break;
            }
            delete pendingEpochUpdates[eQueuePointer.executeHead];
            eQueuePointer.executeHead++;
        }
        epochQueuePointer = eQueuePointer;
    }

    /**
     * @notice Check and update the pending executionResult record.
     * @param _tnBytes The packedExecutionResult transition bytes.
     * @param _blockId Commit block Id.
     */
    function checkPendingExecutionResult(bytes memory _tnBytes, uint256 _blockId) external onlyController {
        dt.ExecutionResultTransition memory er = tn.decodePackedExecutionResultTransition(_tnBytes);
        EventQueuePointer memory queuePointer = execResultQueuePointers[er.strategyId];
        uint64 aggregateId = queuePointer.commitHead;
        require(aggregateId < queuePointer.tail, ErrMsg.REQ_BAD_EXECRES_TN);

        bytes32 ehash = keccak256(
            abi.encodePacked(er.strategyId, er.aggregateId, er.success, er.sharesFromBuy, er.amountFromSell)
        );
        require(pendingExecResults[er.strategyId][aggregateId].ehash == ehash, ErrMsg.REQ_BAD_HASH);

        pendingExecResults[er.strategyId][aggregateId].status = PendingEventStatus.Done;
        pendingExecResults[er.strategyId][aggregateId].blockId = uint64(_blockId); // "done": block holding the transition
        queuePointer.commitHead++;
        execResultQueuePointers[er.strategyId] = queuePointer;
    }

    /**
     * @notice Add pending execution result record.
     * @return aggregate Id
     */
    function addPendingExecutionResult(ExecResultInfo calldata _er) external onlyController returns (uint64) {
        EventQueuePointer memory queuePointer = execResultQueuePointers[_er.strategyId];
        uint64 aggregateId = queuePointer.tail++;
        bytes32 ehash = keccak256(
            abi.encodePacked(_er.strategyId, aggregateId, _er.success, _er.sharesFromBuy, _er.amountFromSell)
        );
        pendingExecResults[_er.strategyId][aggregateId] = PendingEvent({
            ehash: ehash,
            blockId: uint64(_er.blockLen) - 1, // "pending": baseline of censorship delay
            status: PendingEventStatus.Pending
        });

        // Delete pending execution result finalized by this or previous block.
        while (queuePointer.executeHead < queuePointer.commitHead) {
            PendingEvent memory pend = pendingExecResults[_er.strategyId][queuePointer.executeHead];
            if (pend.status != PendingEventStatus.Done || pend.blockId > _er.blockId) {
                break;
            }
            delete pendingExecResults[_er.strategyId][queuePointer.executeHead];
            queuePointer.executeHead++;
        }
        execResultQueuePointers[_er.strategyId] = queuePointer;
        return aggregateId;
    }

    /**
     * @notice add pending epoch update
     * @param _blockLen number of committed blocks
     * @return epoch value
     */
    function addPendingEpochUpdate(uint256 _blockLen) external onlyController returns (uint64) {
        uint64 epochId = epochQueuePointer.tail++;
        uint64 epoch = uint64(block.number);
        pendingEpochUpdates[epochId] = PendingEpochUpdate({
            epoch: epoch,
            blockId: uint64(_blockLen), // "pending": baseline of censorship delay
            status: PendingEventStatus.Pending
        });
        return epoch;
    }

    /**
     * @notice Check and update the pending epoch update record.
     * @param _epoch The epoch value.
     * @param _blockId Commit block Id.
     */
    function checkPendingEpochUpdate(uint64 _epoch, uint256 _blockId) external onlyController {
        EventQueuePointer memory queuePointer = epochQueuePointer;
        uint64 epochId = queuePointer.commitHead;
        require(epochId < queuePointer.tail, ErrMsg.REQ_BAD_EPOCH_TN);

        require(pendingEpochUpdates[epochId].epoch == _epoch, ErrMsg.REQ_BAD_EPOCH);
        pendingEpochUpdates[epochId].status = PendingEventStatus.Done;
        pendingEpochUpdates[epochId].blockId = uint64(_blockId); // "done": block holding the transition
        queuePointer.commitHead++;
        epochQueuePointer = queuePointer;
    }

    /**
     * @notice if operator failed to reflect an L1-initiated priority tx
     * in a rollup block within the maxPriorityTxDelay
     * @param _blockLen number of committed blocks.
     * @param _maxPriorityTxDelay maximm allowed delay for priority tx
     */
    function isPriorityTxDelayViolated(uint256 _blockLen, uint256 _maxPriorityTxDelay) external view returns (bool) {
        if (_blockLen > 0) {
            uint256 currentBlockId = _blockLen - 1;

            EventQueuePointer memory dQueuePointer = depositQueuePointer;
            if (dQueuePointer.commitHead < dQueuePointer.tail) {
                if (currentBlockId - pendingDeposits[dQueuePointer.commitHead].blockId > _maxPriorityTxDelay) {
                    return true;
                }
            }

            EventQueuePointer memory eQueuePointer = epochQueuePointer;
            if (eQueuePointer.commitHead < eQueuePointer.tail) {
                if (currentBlockId - pendingEpochUpdates[eQueuePointer.commitHead].blockId > _maxPriorityTxDelay) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @notice Revert rollup block on dispute success
     * @param _blockId Rollup block Id.
     */
    function revertBlock(uint256 _blockId) external onlyController {
        bool first;
        for (uint64 i = depositQueuePointer.executeHead; i < depositQueuePointer.tail; i++) {
            if (pendingDeposits[i].blockId >= _blockId) {
                if (!first) {
                    depositQueuePointer.commitHead = i;
                    first = true;
                }
                pendingDeposits[i].blockId = uint64(_blockId);
                pendingDeposits[i].status = PendingEventStatus.Pending;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library DataTypes {
    struct Block {
        bytes32 rootHash;
        bytes32 intentHash; // hash of L2-to-L1 aggregate-orders transitions
        uint32 intentExecCount; // count of intents executed so far (MAX_UINT32 == all done)
        uint32 blockSize; // number of transitions in the block
        uint64 blockTime; // blockNum when this rollup block is committed
    }

    struct InitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
    }

    // decoded from calldata submitted as PackedDepositTransition
    struct DepositTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account;
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
    }

    // decoded from calldata submitted as PackedWithdrawTransition
    struct WithdrawTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // target address for "pending withdraw" handling
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
        uint128 fee;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedBuySellTransition
    struct BuyTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 amount;
        uint128 maxSharePrice;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedBuySellTransition
    struct SellTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 shares;
        uint128 minSharePrice;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedTransferTransition
    struct TransferAssetTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 fromAccountId;
        uint32 toAccountId;
        address toAccount;
        uint32 assetId;
        uint256 amount;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedTransferTransition
    struct TransferShareTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 fromAccountId;
        uint32 toAccountId;
        address toAccount;
        uint32 strategyId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedSettlementTransition
    struct SettlementTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint64 aggregateId;
        uint32 accountId;
        uint128 celrRefund; // fee refund in celr
        uint128 assetRefund; // fee refund in asset
    }

    // decoded from calldata submitted as PackedAggregateOrdersTransition
    struct AggregateOrdersTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 minSharesFromBuy;
        uint256 minAmountFromSell;
    }

    // decoded from calldata submitted as PackedExecutionResultTransition
    struct ExecutionResultTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint64 aggregateId;
        bool success;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
    }

    // decoded from calldata submitted as PackedStakingTransition
    struct StakeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint32 accountId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedStakingTransition
    struct UnstakeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 poolId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    struct AddPoolTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint32 strategyId;
        uint32[] rewardAssetIds;
        uint256[] rewardPerEpoch;
        uint256 stakeAdjustmentFactor;
        uint64 startEpoch;
    }

    struct UpdatePoolTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint256[] rewardPerEpoch;
    }

    struct DepositRewardTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 assetId;
        uint256 amount;
    }

    struct WithdrawProtocolFeeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 assetId;
        uint256 amount;
    }

    struct TransferOperatorFeeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId; // destination account Id
    }

    struct UpdateEpochTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint64 epoch;
    }

    struct OperatorFees {
        uint256[] assets; // assetId -> collected asset fees. CELR has assetId 1.
        uint256[] shares; // strategyId -> collected strategy share fees.
    }

    struct GlobalInfo {
        uint256[] protoFees; // assetId -> collected asset fees owned by contract owner (governance multi-sig account)
        OperatorFees opFees; // fee owned by operator
        uint64 currEpoch; // liquidity mining epoch
        uint256[] rewards; // assetId -> available reward amount
    }

    // Pending account actions (buy/sell) per account, strategy, aggregateId.
    // The array of PendingAccountInfo structs is sorted by ascending aggregateId, and holes are ok.
    struct PendingAccountInfo {
        uint64 aggregateId;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 buyFees; // fees (in asset) for buy transitions
        uint256 sellFees; // fees (in asset) for sell transitions
        uint256 celrFees; // fees (in celr) for buy and sell transitions
    }

    struct AccountInfo {
        address account;
        uint32 accountId; // mapping only on L2 must be part of stateRoot
        uint256[] idleAssets; // indexed by assetId
        uint256[] shares; // indexed by strategyId
        PendingAccountInfo[][] pending; // indexed by [strategyId][i], i.e. array of pending records per strategy
        uint256[] stakedShares; // poolID -> share balance
        uint256[] stakes; // poolID -> Adjusted stake
        uint256[][] rewardDebts; // poolID -> rewardTokenID -> Reward debt
        uint64 timestamp; // Unix epoch (msec, UTC)
    }

    // Pending strategy actions per strategy, aggregateId.
    // The array of PendingStrategyInfo structs is sorted by ascending aggregateId, and holes are ok.
    struct PendingStrategyInfo {
        uint64 aggregateId;
        uint128 maxSharePriceForBuy; // decimal in 1e18
        uint128 minSharePriceForSell; // decimal in 1e18
        uint256 buyAmount;
        uint256 sellShares;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
        uint256 unsettledBuyAmount;
        uint256 unsettledSellShares;
        bool executionSucceed;
    }

    struct StrategyInfo {
        uint32 assetId;
        uint256 assetBalance;
        uint256 shareSupply;
        uint64 nextAggregateId;
        uint64 lastExecAggregateId;
        PendingStrategyInfo[] pending; // array of pending records
    }

    struct StakingPoolInfo {
        uint32 strategyId;
        uint32[] rewardAssetIds; // reward asset index -> asset ID
        uint256[] rewardPerEpoch; // reward asset index -> reward per epoch, must be limited in length
        uint256 totalShares;
        uint256 totalStakes;
        uint256[] accumulatedRewardPerUnit; // reward asset index -> Accumulated reward per unit of stake, times 1e12 to avoid very small numbers
        uint64 lastRewardEpoch; // Last epoch that reward distribution occurs. Initially set by an AddPoolTransition
        uint256 stakeAdjustmentFactor; // A fraction to dilute whales. i.e. (0, 1) * 1e12
    }

    struct TransitionProof {
        bytes transition;
        uint256 blockId;
        uint32 index;
        bytes32[] siblings;
    }

    // Even when the disputed transition only affects an account without a strategy or only
    // affects a strategy without an account, both AccountProof and StrategyProof must be sent
    // to at least give the root hashes of the two separate Merkle trees (account and strategy).
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

    struct StakingPoolProof {
        bytes32 stateRoot; // for the staking pool Merkle tree
        StakingPoolInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct EvaluateInfos {
        AccountInfo[] accountInfos;
        StrategyInfo strategyInfo;
        StakingPoolInfo stakingPoolInfo;
        GlobalInfo globalInfo;
    }

    // ------------------ packed transitions submitted as calldata ------------------

    // calldata size: 4 x 32 bytes
    struct PackedDepositTransition {
        /* infoCode packing:
        96:127 [uint32 accountId]
        64:95  [uint32 assetId]
        8:63   [0]
        0:7    [uint8 tntype] */
        uint128 infoCode;
        bytes32 stateRoot;
        address account;
        uint256 amount;
    }

    // calldata size: 7 x 32 bytes
    struct PackedWithdrawTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 assetId]
        128:191 [uint64 timestamp]
        16:127  [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        address account;
        uint256 amtfee; // [128bit-amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 6 x 32 bytes
    struct PackedBuySellTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 strategyId]
        128:191 [uint64 timestamp]
        16:127  [uint112 minSharePrice or maxSharePrice] // 112 bits are enough
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 amtfee; // [128bit-share/amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 6 x 32 bytes
    struct PackedTransferTransition {
        /* infoCode packing:
        224:255 [0]
        192:223 [uint32 assetId or strategyId]
        160:191 [uint32 fromAccountId]
        128:159 [uint32 toAccountId]
        64:127  [uint64 timestamp]
        16:63   [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        address toAccount;
        uint256 amtfee; // [128bit-share/amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 2 x 32 bytes
    struct PackedSettlementTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 strategyId]
        160:191 [uint32 aggregateId] // uint32 is enough for per-strategy aggregateId
        104:159 [uint56 celrRefund] // celr refund in 9 decimal
        8:103   [uint96 assetRefund] // asseet refund
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
    }

    // calldata size: 6 x 32 bytes
    struct PackedAggregateOrdersTransition {
        /* infoCode packing:
        32:63  [uint32 strategyId]
        8:31   [0]
        0:7    [uint8 tntype] */
        uint64 infoCode;
        bytes32 stateRoot;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 minSharesFromBuy;
        uint256 minAmountFromSell;
    }

    // calldata size: 4 x 32 bytes
    struct PackedExecutionResultTransition {
        /* infoCode packing:
        64:127  [uint64 aggregateId]
        32:63   [uint32 strategyId]
        9:31    [0]
        8:8     [bool success]
        0:7     [uint8 tntype] */
        uint128 infoCode;
        bytes32 stateRoot;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
    }

    // calldata size: 6 x 32 bytes
    struct PackedStakingTransition {
        /* infoCode packing:
        192:255 [0]
        160:191 [uint32 poolId]
        128:159 [uint32 accountId]
        64:127  [uint64 timestamp]
        16:63   [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 sharefee; // [128bit-share]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library ErrMsg {
    // err message for `require` checks
    string internal constant REQ_NOT_OPER = "caller not operator";
    string internal constant REQ_BAD_AMOUNT = "invalid amount";
    string internal constant REQ_NO_WITHDRAW = "withdraw failed";
    string internal constant REQ_BAD_BLOCKID = "invalid block ID";
    string internal constant REQ_BAD_CHALLENGE = "challenge period error";
    string internal constant REQ_BAD_HASH = "invalid data hash";
    string internal constant REQ_BAD_LEN = "invalid data length";
    string internal constant REQ_NO_DRAIN = "drain failed";
    string internal constant REQ_BAD_ASSET = "invalid asset";
    string internal constant REQ_BAD_ST = "invalid strategy";
    string internal constant REQ_BAD_SP = "invalid staking pool";
    string internal constant REQ_BAD_EPOCH = "invalid epoch";
    string internal constant REQ_OVER_LIMIT = "exceeds limit";
    string internal constant REQ_BAD_DEP_TN = "invalid deposit tn";
    string internal constant REQ_BAD_EXECRES_TN = "invalid execRes tn";
    string internal constant REQ_BAD_EPOCH_TN = "invalid epoch tn";
    string internal constant REQ_ONE_ACCT = "need 1 account";
    string internal constant REQ_TWO_ACCT = "need 2 accounts";
    string internal constant REQ_ACCT_NOT_EMPTY = "account not empty";
    string internal constant REQ_BAD_ACCT = "wrong account";
    string internal constant REQ_BAD_SIG = "invalid signature";
    string internal constant REQ_BAD_TS = "old timestamp";
    string internal constant REQ_NO_PEND = "no pending info";
    string internal constant REQ_BAD_SHARES = "wrong shares";
    string internal constant REQ_BAD_AGGR = "wrong aggregate ID";
    string internal constant REQ_ST_NOT_EMPTY = "strategy not empty";
    string internal constant REQ_NO_FRAUD = "no fraud found";
    string internal constant REQ_BAD_NTREE = "bad n-tree verify";
    string internal constant REQ_BAD_SROOT = "state roots not equal";
    string internal constant REQ_BAD_INDEX = "wrong proof index";
    string internal constant REQ_BAD_PREV_TN = "invalid prev tn";
    string internal constant REQ_TN_NOT_IN = "tn not in block";
    string internal constant REQ_TN_NOT_SEQ = "tns not sequential";
    string internal constant REQ_BAD_MERKLE = "failed Merkle proof check";
    // err message for dispute success reasons
    string internal constant RSN_BAD_INIT_TN = "invalid init tn";
    string internal constant RSN_BAD_ENCODING = "invalid encoding";
    string internal constant RSN_BAD_ACCT_ID = "invalid account id";
    string internal constant RSN_EVAL_FAILURE = "failed to evaluate";
    string internal constant RSN_BAD_POST_SROOT = "invalid post-state root";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../libraries/DataTypes.sol";

library Transitions {
    // Transition Types
    uint8 public constant TN_TYPE_INVALID = 0;
    uint8 public constant TN_TYPE_INIT = 1;
    uint8 public constant TN_TYPE_DEPOSIT = 2;
    uint8 public constant TN_TYPE_WITHDRAW = 3;
    uint8 public constant TN_TYPE_BUY = 4;
    uint8 public constant TN_TYPE_SELL = 5;
    uint8 public constant TN_TYPE_XFER_ASSET = 6;
    uint8 public constant TN_TYPE_XFER_SHARE = 7;
    uint8 public constant TN_TYPE_AGGREGATE_ORDER = 8;
    uint8 public constant TN_TYPE_EXEC_RESULT = 9;
    uint8 public constant TN_TYPE_SETTLE = 10;
    uint8 public constant TN_TYPE_WITHDRAW_PROTO_FEE = 11;
    uint8 public constant TN_TYPE_XFER_OP_FEE = 12;

    // Staking / liquidity mining
    uint8 public constant TN_TYPE_STAKE = 13;
    uint8 public constant TN_TYPE_UNSTAKE = 14;
    uint8 public constant TN_TYPE_ADD_POOL = 15;
    uint8 public constant TN_TYPE_UPDATE_POOL = 16;
    uint8 public constant TN_TYPE_DEPOSIT_REWARD = 17;
    uint8 public constant TN_TYPE_UPDATE_EPOCH = 18;

    // fee encoding
    uint128 public constant UINT128_HIBIT = 2**127;

    function extractTransitionType(bytes memory _bytes) internal pure returns (uint8) {
        uint8 transitionType;
        assembly {
            transitionType := mload(add(_bytes, 0x20))
        }
        return transitionType;
    }

    function decodeInitTransition(bytes memory _rawBytes) internal pure returns (DataTypes.InitTransition memory) {
        (uint8 transitionType, bytes32 stateRoot) = abi.decode((_rawBytes), (uint8, bytes32));
        DataTypes.InitTransition memory transition = DataTypes.InitTransition(transitionType, stateRoot);
        return transition;
    }

    function decodePackedDepositTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositTransition memory)
    {
        (uint128 infoCode, bytes32 stateRoot, address account, uint256 amount) = abi.decode(
            (_rawBytes),
            (uint128, bytes32, address, uint256)
        );
        (uint32 accountId, uint32 assetId, uint8 transitionType) = decodeDepositInfoCode(infoCode);
        DataTypes.DepositTransition memory transition = DataTypes.DepositTransition(
            transitionType,
            stateRoot,
            account,
            accountId,
            assetId,
            amount
        );
        return transition;
    }

    function decodeDepositInfoCode(uint128 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // assetId
            uint8 // transitionType
        )
    {
        (uint64 high, uint64 low) = splitUint128(_infoCode);
        (uint32 accountId, uint32 assetId) = splitUint64(high);
        uint8 transitionType = uint8(low);
        return (accountId, assetId, transitionType);
    }

    function decodePackedWithdrawTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address account, uint256 amtfee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, address, uint256, bytes32, bytes32)
        );
        (uint32 accountId, uint32 assetId, uint64 timestamp, uint8 v, uint8 transitionType) = decodeWithdrawInfoCode(
            infoCode
        );
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.WithdrawTransition memory transition = DataTypes.WithdrawTransition(
            transitionType,
            stateRoot,
            account,
            accountId,
            assetId,
            amount,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeWithdrawInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // assetId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (uint64 ids, uint64 timestamp) = splitUint128(high);
        (uint32 accountId, uint32 assetId) = splitUint64(ids);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(low));
        return (accountId, assetId, timestamp, v, transitionType);
    }

    function decodePackedBuyTransition(bytes memory _rawBytes) internal pure returns (DataTypes.BuyTransition memory) {
        (uint256 infoCode, bytes32 stateRoot, uint256 amtfee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 timestamp,
            uint128 maxSharePrice,
            uint8 v,
            uint8 transitionType
        ) = decodeBuySellInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.BuyTransition memory transition = DataTypes.BuyTransition(
            transitionType,
            stateRoot,
            accountId,
            strategyId,
            amount,
            maxSharePrice,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodePackedSellTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.SellTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 timestamp,
            uint128 minSharePrice,
            uint8 v,
            uint8 transitionType
        ) = decodeBuySellInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.SellTransition memory transition = DataTypes.SellTransition(
            transitionType,
            stateRoot,
            accountId,
            strategyId,
            shares,
            minSharePrice,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeBuySellInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // strategyId
            uint64, // timestamp
            uint128, // maxSharePrice or minSharePrice
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 h1, uint128 low) = splitUint256(_infoCode);
        (uint64 h2, uint64 timestamp) = splitUint128(h1);
        (uint32 accountId, uint32 strategyId) = splitUint64(h2);
        uint128 sharePrice = uint128(low >> 16);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(low));
        return (accountId, strategyId, timestamp, sharePrice, v, transitionType);
    }

    function decodePackedTransferAssetTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferAssetTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address toAccount, uint256 amtfee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, address, uint256, bytes32, bytes32)
        );
        (
            uint32 assetId,
            uint32 fromAccountId,
            uint32 toAccountId,
            uint64 timestamp,
            uint8 v,
            uint8 transitionType
        ) = decodeTransferInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.TransferAssetTransition memory transition = DataTypes.TransferAssetTransition(
            transitionType,
            stateRoot,
            fromAccountId,
            toAccountId,
            toAccount,
            assetId,
            amount,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodePackedTransferShareTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferShareTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address toAccount, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, address, uint256, bytes32, bytes32)
        );
        (
            uint32 strategyId,
            uint32 fromAccountId,
            uint32 toAccountId,
            uint64 timestamp,
            uint8 v,
            uint8 transitionType
        ) = decodeTransferInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.TransferShareTransition memory transition = DataTypes.TransferShareTransition(
            transitionType,
            stateRoot,
            fromAccountId,
            toAccountId,
            toAccount,
            strategyId,
            shares,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeTransferInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // assetId or strategyId
            uint32, // fromAccountId
            uint32, // toAccountId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (uint64 astId, uint64 acctIds) = splitUint128(high);
        (uint32 fromAccountId, uint32 toAccountId) = splitUint64(acctIds);
        (uint64 timestamp, uint64 vt) = splitUint128(low);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(vt));
        return (uint32(astId), fromAccountId, toAccountId, timestamp, v, transitionType);
    }

    function decodePackedSettlementTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.SettlementTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot) = abi.decode((_rawBytes), (uint256, bytes32));
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 aggregateId,
            uint128 celrRefund,
            uint128 assetRefund,
            uint8 transitionType
        ) = decodeSettlementInfoCode(infoCode);
        DataTypes.SettlementTransition memory transition = DataTypes.SettlementTransition(
            transitionType,
            stateRoot,
            strategyId,
            aggregateId,
            accountId,
            celrRefund,
            assetRefund
        );
        return transition;
    }

    function decodeSettlementInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // strategyId
            uint64, // aggregateId
            uint128, // celrRefund
            uint128, // assetRefund
            uint8 // transitionType
        )
    {
        uint128 ids = uint128(_infoCode >> 160);
        uint64 aggregateId = uint32(ids);
        ids = uint64(ids >> 32);
        uint32 strategyId = uint32(ids);
        uint32 accountId = uint32(ids >> 32);
        uint256 refund = uint152(_infoCode >> 8);
        uint128 assetRefund = uint96(refund);
        uint128 celrRefund = uint128(refund >> 96) * 1e9;
        uint8 transitionType = uint8(_infoCode);
        return (accountId, strategyId, aggregateId, celrRefund, assetRefund, transitionType);
    }

    function decodePackedAggregateOrdersTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.AggregateOrdersTransition memory)
    {
        (
            uint64 infoCode,
            bytes32 stateRoot,
            uint256 buyAmount,
            uint256 sellShares,
            uint256 minSharesFromBuy,
            uint256 minAmountFromSell
        ) = abi.decode((_rawBytes), (uint64, bytes32, uint256, uint256, uint256, uint256));
        (uint32 strategyId, uint8 transitionType) = decodeAggregateOrdersInfoCode(infoCode);
        DataTypes.AggregateOrdersTransition memory transition = DataTypes.AggregateOrdersTransition(
            transitionType,
            stateRoot,
            strategyId,
            buyAmount,
            sellShares,
            minSharesFromBuy,
            minAmountFromSell
        );
        return transition;
    }

    function decodeAggregateOrdersInfoCode(uint64 _infoCode)
        internal
        pure
        returns (
            uint32, // strategyId
            uint8 // transitionType
        )
    {
        (uint32 strategyId, uint32 low) = splitUint64(_infoCode);
        uint8 transitionType = uint8(low);
        return (strategyId, transitionType);
    }

    function decodePackedExecutionResultTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.ExecutionResultTransition memory)
    {
        (uint128 infoCode, bytes32 stateRoot, uint256 sharesFromBuy, uint256 amountFromSell) = abi.decode(
            (_rawBytes),
            (uint128, bytes32, uint256, uint256)
        );
        (uint64 aggregateId, uint32 strategyId, bool success, uint8 transitionType) = decodeExecutionResultInfoCode(
            infoCode
        );
        DataTypes.ExecutionResultTransition memory transition = DataTypes.ExecutionResultTransition(
            transitionType,
            stateRoot,
            strategyId,
            aggregateId,
            success,
            sharesFromBuy,
            amountFromSell
        );
        return transition;
    }

    function decodeExecutionResultInfoCode(uint128 _infoCode)
        internal
        pure
        returns (
            uint64, // aggregateId
            uint32, // strategyId
            bool, // success
            uint8 // transitionType
        )
    {
        (uint64 aggregateId, uint64 low) = splitUint128(_infoCode);
        (uint32 strategyId, uint32 low2) = splitUint64(low);
        uint8 transitionType = uint8(low2);
        bool success = uint8(low2 >> 8) == 1;
        return (aggregateId, strategyId, success, transitionType);
    }

    function decodePackedStakeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.StakeTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (uint32 poolId, uint32 accountId, uint64 timestamp, uint8 v, uint8 transitionType) = decodeStakingInfoCode(
            infoCode
        );
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.StakeTransition memory transition = DataTypes.StakeTransition(
            transitionType,
            stateRoot,
            poolId,
            accountId,
            shares,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodePackedUnstakeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UnstakeTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (uint32 poolId, uint32 accountId, uint64 timestamp, uint8 v, uint8 transitionType) = decodeStakingInfoCode(
            infoCode
        );
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.UnstakeTransition memory transition = DataTypes.UnstakeTransition(
            transitionType,
            stateRoot,
            poolId,
            accountId,
            shares,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeStakingInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // poolId
            uint32, // accountId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (, uint64 poolIdAccountId) = splitUint128(high);
        (uint32 poolId, uint32 accountId) = splitUint64(poolIdAccountId);
        (uint64 timestamp, uint64 vt) = splitUint128(low);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(vt));
        return (poolId, accountId, timestamp, v, transitionType);
    }

    function decodeAddPoolTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.AddPoolTransition memory)
    {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            uint32 poolId,
            uint32 strategyId,
            uint32[] memory rewardAssetIds,
            uint256[] memory rewardPerEpoch,
            uint256 stakeAdjustmentFactor,
            uint64 startEpoch
        ) = abi.decode((_rawBytes), (uint8, bytes32, uint32, uint32, uint32[], uint256[], uint256, uint64));
        DataTypes.AddPoolTransition memory transition = DataTypes.AddPoolTransition(
            transitionType,
            stateRoot,
            poolId,
            strategyId,
            rewardAssetIds,
            rewardPerEpoch,
            stakeAdjustmentFactor,
            startEpoch
        );
        return transition;
    }

    function decodeUpdatePoolTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UpdatePoolTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 poolId, uint256[] memory rewardPerEpoch) = abi.decode(
            (_rawBytes),
            (uint8, bytes32, uint32, uint256[])
        );
        DataTypes.UpdatePoolTransition memory transition = DataTypes.UpdatePoolTransition(
            transitionType,
            stateRoot,
            poolId,
            rewardPerEpoch
        );
        return transition;
    }

    function decodeDepositRewardTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositRewardTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 assetId, uint256 amount) = abi.decode(
            (_rawBytes),
            (uint8, bytes32, uint32, uint256)
        );
        DataTypes.DepositRewardTransition memory transition = DataTypes.DepositRewardTransition(
            transitionType,
            stateRoot,
            assetId,
            amount
        );
        return transition;
    }

    function decodeWithdrawProtocolFeeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawProtocolFeeTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 assetId, uint256 amount) = abi.decode(
            (_rawBytes),
            (uint8, bytes32, uint32, uint256)
        );
        DataTypes.WithdrawProtocolFeeTransition memory transition = DataTypes.WithdrawProtocolFeeTransition(
            transitionType,
            stateRoot,
            assetId,
            amount
        );
        return transition;
    }

    function decodeTransferOperatorFeeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferOperatorFeeTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 accountId) = abi.decode((_rawBytes), (uint8, bytes32, uint32));
        DataTypes.TransferOperatorFeeTransition memory transition = DataTypes.TransferOperatorFeeTransition(
            transitionType,
            stateRoot,
            accountId
        );
        return transition;
    }

    function decodeUpdateEpochTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UpdateEpochTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint64 epoch) = abi.decode((_rawBytes), (uint8, bytes32, uint64));
        DataTypes.UpdateEpochTransition memory transition = DataTypes.UpdateEpochTransition(
            transitionType,
            stateRoot,
            epoch
        );
        return transition;
    }

    /**
     * Helper to expand the account array of idle assets if needed.
     */
    function adjustAccountIdleAssetEntries(DataTypes.AccountInfo memory _accountInfo, uint32 assetId) internal pure {
        uint32 n = uint32(_accountInfo.idleAssets.length);
        if (n <= assetId) {
            uint256[] memory arr = new uint256[](assetId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.idleAssets[i];
            }
            for (uint32 i = n; i <= assetId; i++) {
                arr[i] = 0;
            }
            _accountInfo.idleAssets = arr;
        }
    }

    /**
     * Helper to expand the account array of shares if needed.
     */
    function adjustAccountShareEntries(DataTypes.AccountInfo memory _accountInfo, uint32 stId) internal pure {
        uint32 n = uint32(_accountInfo.shares.length);
        if (n <= stId) {
            uint256[] memory arr = new uint256[](stId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.shares[i];
            }
            for (uint32 i = n; i <= stId; i++) {
                arr[i] = 0;
            }
            _accountInfo.shares = arr;
        }
    }

    /**
     * Helper to expand protocol fee array (if needed) and add given fee.
     */
    function addProtoFee(
        DataTypes.GlobalInfo memory _globalInfo,
        uint32 _assetId,
        uint256 _fee
    ) internal pure {
        _globalInfo.protoFees = adjustUint256Array(_globalInfo.protoFees, _assetId);
        _globalInfo.protoFees[_assetId] += _fee;
    }

    /**
     * Helper to expand the chosen operator fee array (if needed) and add a given fee.
     * If "_assets" is true, use the assets fee array, otherwise use the shares fee array.
     */
    function updateOpFee(
        DataTypes.GlobalInfo memory _globalInfo,
        bool _assets,
        uint32 _idx,
        uint256 _fee
    ) internal pure {
        if (_assets) {
            _globalInfo.opFees.assets = adjustUint256Array(_globalInfo.opFees.assets, _idx);
            _globalInfo.opFees.assets[_idx] += _fee;
        } else {
            _globalInfo.opFees.shares = adjustUint256Array(_globalInfo.opFees.shares, _idx);
            _globalInfo.opFees.shares[_idx] += _fee;
        }
    }

    /**
     * Helper to expand an array of uint256, e.g. the various fee arrays in globalInfo.
     * Takes the array and the needed index and returns the unchanged array or a new expanded one.
     */
    function adjustUint256Array(uint256[] memory _array, uint32 _idx) internal pure returns (uint256[] memory) {
        uint32 n = uint32(_array.length);
        if (_idx < n) {
            return _array;
        }

        uint256[] memory newArray = new uint256[](_idx + 1);
        for (uint32 i = 0; i < n; i++) {
            newArray[i] = _array[i];
        }
        for (uint32 i = n; i <= _idx; i++) {
            newArray[i] = 0;
        }

        return newArray;
    }

    /**
     * Helper to get the fee type and amount.
     * Returns (isCelr, fee).
     */
    function getFeeInfo(uint128 _fee) internal pure returns (bool, uint256) {
        bool isCelr = _fee & UINT128_HIBIT == UINT128_HIBIT;
        if (isCelr) {
            _fee = _fee ^ UINT128_HIBIT;
        }
        return (isCelr, uint256(_fee));
    }

    function splitUint16(uint16 _code) internal pure returns (uint8, uint8) {
        uint8 high = uint8(_code >> 8);
        uint8 low = uint8(_code);
        return (high, low);
    }

    function splitUint64(uint64 _code) internal pure returns (uint32, uint32) {
        uint32 high = uint32(_code >> 32);
        uint32 low = uint32(_code);
        return (high, low);
    }

    function splitUint128(uint128 _code) internal pure returns (uint64, uint64) {
        uint64 high = uint64(_code >> 64);
        uint64 low = uint64(_code);
        return (high, low);
    }

    function splitUint256(uint256 _code) internal pure returns (uint128, uint128) {
        uint128 high = uint128(_code >> 128);
        uint128 low = uint128(_code);
        return (high, low);
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}