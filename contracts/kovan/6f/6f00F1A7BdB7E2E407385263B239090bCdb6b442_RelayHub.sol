// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/GsnTypes.sol";
import "./interfaces/IPaymaster.sol";
import "./interfaces/IRelayHub.sol";
import "./utils/GsnEip712Library.sol";
import "./forwarder/IForwarder.sol";

/**
 * Abstract base class to be inherited by a concrete Paymaster
 * A subclass must implement:
 *  - preRelayedCall
 *  - postRelayedCall
 */
abstract contract BasePaymaster is IPaymaster, Ownable {

    IRelayHub internal relayHub;
    IForwarder public override trustedForwarder;

    function getHubAddr() public override view returns (address) {
        return address(relayHub);
    }

    //overhead of forwarder verify+signature, plus hub overhead.
    uint256 constant public FORWARDER_HUB_OVERHEAD = 50000;

    //These parameters are documented in IPaymaster.GasAndDataLimits
    uint256 constant public PRE_RELAYED_CALL_GAS_LIMIT = 100000;
    uint256 constant public POST_RELAYED_CALL_GAS_LIMIT = 110000;
    uint256 constant public PAYMASTER_ACCEPTANCE_BUDGET = PRE_RELAYED_CALL_GAS_LIMIT + FORWARDER_HUB_OVERHEAD;
    uint256 constant public CALLDATA_SIZE_LIMIT = 10500;

    function getGasAndDataLimits()
    public
    override
    virtual
    view
    returns (
        IPaymaster.GasAndDataLimits memory limits
    ) {
        return IPaymaster.GasAndDataLimits(
            PAYMASTER_ACCEPTANCE_BUDGET,
            PRE_RELAYED_CALL_GAS_LIMIT,
            POST_RELAYED_CALL_GAS_LIMIT,
            CALLDATA_SIZE_LIMIT
        );
    }

    // this method must be called from preRelayedCall to validate that the forwarder
    // is approved by the paymaster as well as by the recipient contract.
    function _verifyForwarder(GsnTypes.RelayRequest calldata relayRequest)
    public
    view
    {
        require(address(trustedForwarder) == relayRequest.relayData.forwarder, "Forwarder is not trusted");
        GsnEip712Library.verifyForwarderTrusted(relayRequest);
    }

    /*
     * modifier to be used by recipients as access control protection for preRelayedCall & postRelayedCall
     */
    modifier relayHubOnly() {
        require(msg.sender == getHubAddr(), "can only be called by RelayHub");
        _;
    }

    function setRelayHub(IRelayHub hub) public onlyOwner {
        relayHub = hub;
    }

    function setTrustedForwarder(IForwarder forwarder) public onlyOwner {
        trustedForwarder = forwarder;
    }

    /// check current deposit on relay hub.
    function getRelayHubDeposit()
    public
    override
    view
    returns (uint) {
        return relayHub.balanceOf(address(this));
    }

    // any money moved into the paymaster is transferred as a deposit.
    // This way, we don't need to understand the RelayHub API in order to replenish
    // the paymaster.
    receive() external virtual payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    /// withdraw deposit from relayHub
    function withdrawRelayHubDepositTo(uint amount, address payable target) public onlyOwner {
        relayHub.withdraw(amount, target);
    }
}

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.7.6;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./forwarder/Forwarder.sol";
import "./BaseRelayRecipient.sol";
import "./utils/GsnUtils.sol";

/**
 * batch forwarder support calling a method sendBatch in the forwarder itself.
 * NOTE: the "target" of the request should be the BatchForwarder itself
 */
contract BatchForwarder is Forwarder, BaseRelayRecipient {

    string public override versionRecipient = "2.2.0+opengsn.batched.irelayrecipient";

    constructor() {
        //needed for sendBatch
        trustedForwarder = address(this);
    }

    function sendBatch(address[] calldata targets, bytes[] calldata encodedFunctions) external {
        require(targets.length == encodedFunctions.length, "BatchForwarder: wrong length");
        address sender = _msgSender();
        for (uint i = 0; i < targets.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory ret) = targets[i].call(abi.encodePacked(encodedFunctions[i], sender));
            if (!success){
                //re-throw the revert with the same revert reason.
                GsnUtils.revertWithData(ret);
            }
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./utils/RLPReader.sol";
import "./utils/GsnUtils.sol";
import "./interfaces/IRelayHub.sol";
import "./interfaces/IPenalizer.sol";

contract Penalizer is IPenalizer {

    string public override versionPenalizer = "2.2.0+opengsn.penalizer.ipenalizer";

    using ECDSA for bytes32;

    uint256 public immutable override penalizeBlockDelay;
    uint256 public immutable override penalizeBlockExpiration;

    constructor(
        uint256 _penalizeBlockDelay,
        uint256 _penalizeBlockExpiration
    ) {
        penalizeBlockDelay = _penalizeBlockDelay;
        penalizeBlockExpiration = _penalizeBlockExpiration;
    }

    function isTransactionType1(bytes calldata rawTransaction) public pure returns (bool) {
        return (uint8(rawTransaction[0]) == 1);
    }

    function isTransactionTypeValid(bytes calldata rawTransaction) public pure returns(bool) {
        uint8 transactionTypeByte = uint8(rawTransaction[0]);
        return (transactionTypeByte >= 0xc0 && transactionTypeByte <= 0xfe);
    }

    function decodeTransaction(bytes calldata rawTransaction) public pure returns (Transaction memory transaction) {
        if (isTransactionType1(rawTransaction)) {
            (transaction.nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            transaction.data) = RLPReader.decodeTransactionType1(rawTransaction);
        } else {
            (transaction.nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            transaction.data) = RLPReader.decodeLegacyTransaction(rawTransaction);
        }
        return transaction;
    }

    mapping(bytes32 => uint) public commits;

    /**
     * any sender can call "commit(keccak(encodedPenalizeFunction))", to make sure
     * no-one can front-run it to claim this penalization
     */
    function commit(bytes32 commitHash) external override {
        uint256 readyBlockNumber = block.number + penalizeBlockDelay;
        commits[commitHash] = readyBlockNumber;
        emit CommitAdded(msg.sender, commitHash, readyBlockNumber);
    }

    modifier commitRevealOnly() {
        bytes32 commitHash = keccak256(abi.encodePacked(keccak256(msg.data), msg.sender));
        uint256 readyBlockNumber = commits[commitHash];
        delete commits[commitHash];
        // msg.sender can only be fake during off-chain view call, allowing Penalizer process to check transactions
        if(msg.sender != address(0)) {
            require(readyBlockNumber != 0, "no commit");
            require(readyBlockNumber < block.number, "reveal penalize too soon");
            require(readyBlockNumber + penalizeBlockExpiration > block.number, "reveal penalize too late");
        }
        _;
    }

    function penalizeRepeatedNonce(
        bytes calldata unsignedTx1,
        bytes calldata signature1,
        bytes calldata unsignedTx2,
        bytes calldata signature2,
        IRelayHub hub,
        uint256 randomValue
    )
    public
    override
    commitRevealOnly {
        (randomValue);
        _penalizeRepeatedNonce(unsignedTx1, signature1, unsignedTx2, signature2, hub);
    }

    function _penalizeRepeatedNonce(
        bytes calldata unsignedTx1,
        bytes calldata signature1,
        bytes calldata unsignedTx2,
        bytes calldata signature2,
        IRelayHub hub
    )
    private
    {
        // If a relay attacked the system by signing multiple transactions with the same nonce
        // (so only one is accepted), anyone can grab both transactions from the blockchain and submit them here.
        // Check whether unsignedTx1 != unsignedTx2, that both are signed by the same address,
        // and that unsignedTx1.nonce == unsignedTx2.nonce.
        // If all conditions are met, relay is considered an "offending relay".
        // The offending relay will be unregistered immediately, its stake will be forfeited and given
        // to the address who reported it (msg.sender), thus incentivizing anyone to report offending relays.
        // If reported via a relay, the forfeited stake is split between
        // msg.sender (the relay used for reporting) and the address that reported it.

        address addr1 = keccak256(unsignedTx1).recover(signature1);
        address addr2 = keccak256(unsignedTx2).recover(signature2);

        require(addr1 == addr2, "Different signer");
        require(addr1 != address(0), "ecrecover failed");

        Transaction memory decodedTx1 = decodeTransaction(unsignedTx1);
        Transaction memory decodedTx2 = decodeTransaction(unsignedTx2);

        // checking that the same nonce is used in both transaction, with both signed by the same address
        // and the actual data is different
        // note: we compare the hash of the tx to save gas over iterating both byte arrays
        require(decodedTx1.nonce == decodedTx2.nonce, "Different nonce");

        bytes memory dataToCheck1 =
        abi.encodePacked(decodedTx1.data, decodedTx1.gasLimit, decodedTx1.to, decodedTx1.value);

        bytes memory dataToCheck2 =
        abi.encodePacked(decodedTx2.data, decodedTx2.gasLimit, decodedTx2.to, decodedTx2.value);

        require(keccak256(dataToCheck1) != keccak256(dataToCheck2), "tx is equal");

        penalize(addr1, hub);
    }

    function penalizeIllegalTransaction(
        bytes calldata unsignedTx,
        bytes calldata signature,
        IRelayHub hub,
        uint256 randomValue
    )
    public
    override
    commitRevealOnly {
        (randomValue);
        _penalizeIllegalTransaction(unsignedTx, signature, hub);
    }

    function _penalizeIllegalTransaction(
        bytes calldata unsignedTx,
        bytes calldata signature,
        IRelayHub hub
    )
    private
    {
        if (isTransactionTypeValid(unsignedTx)) {
            Transaction memory decodedTx = decodeTransaction(unsignedTx);
            if (decodedTx.to == address(hub)) {
                bytes4 selector = GsnUtils.getMethodSig(decodedTx.data);
                bool isWrongMethodCall = selector != IRelayHub.relayCall.selector;
                bool isGasLimitWrong = GsnUtils.getParam(decodedTx.data, 4) != decodedTx.gasLimit;
                require(
                    isWrongMethodCall || isGasLimitWrong,
                    "Legal relay transaction");
            }
        }
        address relay = keccak256(unsignedTx).recover(signature);
        require(relay != address(0), "ecrecover failed");
        penalize(relay, hub);
    }

    function penalize(address relayWorker, IRelayHub hub) private {
        hub.penalize(relayWorker, msg.sender);
    }
}

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable not-rely-on-time */
/* solhint-disable avoid-tx-origin */
/* solhint-disable bracket-align */
// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./utils/MinLibBytes.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/GsnUtils.sol";
import "./utils/GsnEip712Library.sol";
import "./utils/RelayHubValidator.sol";
import "./utils/GsnTypes.sol";
import "./interfaces/IRelayHub.sol";
import "./interfaces/IPaymaster.sol";
import "./forwarder/IForwarder.sol";
import "./interfaces/IStakeManager.sol";

contract RelayHub is IRelayHub, Ownable {
    using SafeMath for uint256;

    string public override versionHub = "2.2.0+opengsn.hub.irelayhub";

    IStakeManager immutable override public stakeManager;
    address immutable override public penalizer;

    RelayHubConfig private config;

    function getConfiguration() public override view returns (RelayHubConfig memory) {
        return config;
    }

    function setConfiguration(RelayHubConfig memory _config) public override onlyOwner {
        config = _config;
        emit RelayHubConfigured(config);
    }

    uint256 public constant G_NONZERO = 16;

    // maps relay worker's address to its manager's address
    mapping(address => address) public override workerToManager;

    // maps relay managers to the number of their workers
    mapping(address => uint256) public override workerCount;

    mapping(address => uint256) private balances;

    uint256 public override deprecationBlock = type(uint).max;

    constructor (
        IStakeManager _stakeManager,
        address _penalizer,
        uint256 _maxWorkerCount,
        uint256 _gasReserve,
        uint256 _postOverhead,
        uint256 _gasOverhead,
        uint256 _maximumRecipientDeposit,
        uint256 _minimumUnstakeDelay,
        uint256 _minimumStake,
        uint256 _dataGasCostPerByte,
        uint256 _externalCallDataCostOverhead
    ) {
        stakeManager = _stakeManager;
        penalizer = _penalizer;
        setConfiguration(RelayHubConfig(
            _maxWorkerCount,
            _gasReserve,
            _postOverhead,
            _gasOverhead,
            _maximumRecipientDeposit,
            _minimumUnstakeDelay,
            _minimumStake,
            _dataGasCostPerByte,
            _externalCallDataCostOverhead
        ));
    }

    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external override {
        address relayManager = msg.sender;
        require(
            isRelayManagerStaked(relayManager),
            "relay manager not staked"
        );
        require(workerCount[relayManager] > 0, "no relay workers");
        emit RelayServerRegistered(relayManager, baseRelayFee, pctRelayFee, url);
    }

    function addRelayWorkers(address[] calldata newRelayWorkers) external override {
        address relayManager = msg.sender;
        uint256 newWorkerCount = workerCount[relayManager] + newRelayWorkers.length;
        workerCount[relayManager] = newWorkerCount;
        require(newWorkerCount <= config.maxWorkerCount, "too many workers");

        require(
            isRelayManagerStaked(relayManager),
            "relay manager not staked"
        );

        for (uint256 i = 0; i < newRelayWorkers.length; i++) {
            require(workerToManager[newRelayWorkers[i]] == address(0), "this worker has a manager");
            workerToManager[newRelayWorkers[i]] = relayManager;
        }

        emit RelayWorkersAdded(relayManager, newRelayWorkers, newWorkerCount);
    }

    function depositFor(address target) public override payable {
        uint256 amount = msg.value;
        require(amount <= config.maximumRecipientDeposit, "deposit too big");

        balances[target] = balances[target].add(amount);

        emit Deposited(target, msg.sender, amount);
    }

    function balanceOf(address target) external override view returns (uint256) {
        return balances[target];
    }

    function withdraw(uint256 amount, address payable dest) public override {
        address payable account = msg.sender;
        require(balances[account] >= amount, "insufficient funds");

        balances[account] = balances[account].sub(amount);
        dest.transfer(amount);

        emit Withdrawn(account, dest, amount);
    }

    function calldataGasCost(uint256 length) public override view returns (uint256) {
        return config.dataGasCostPerByte.mul(length);
}

    function verifyGasAndDataLimits(
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        uint256 initialGasLeft,
        uint256 externalGasLimit
    )
    private
    view
    returns (IPaymaster.GasAndDataLimits memory gasAndDataLimits, uint256 maxPossibleGas) {
        gasAndDataLimits =
            IPaymaster(relayRequest.relayData.paymaster).getGasAndDataLimits{gas:50000}();
        require(msg.data.length <= gasAndDataLimits.calldataSizeLimit, "msg.data exceeded limit" );
        uint256 dataGasCost = calldataGasCost(msg.data.length);
        uint256 externalCallDataCost = externalGasLimit - initialGasLeft - config.externalCallDataCostOverhead;
        uint256 txDataCostPerByte = externalCallDataCost/msg.data.length;
        require(txDataCostPerByte <= G_NONZERO, "invalid externalGasLimit");

        require(maxAcceptanceBudget >= gasAndDataLimits.acceptanceBudget, "acceptance budget too high");
        require(gasAndDataLimits.acceptanceBudget >= gasAndDataLimits.preRelayedCallGasLimit, "acceptance budget too low");

        maxPossibleGas =
            config.gasOverhead.add(
            gasAndDataLimits.preRelayedCallGasLimit).add(
            gasAndDataLimits.postRelayedCallGasLimit).add(
            relayRequest.request.gas).add(
            dataGasCost).add(
            externalCallDataCost);

        // This transaction must have enough gas to forward the call to the recipient with the requested amount, and not
        // run out of gas later in this function.
        require(
            externalGasLimit >= maxPossibleGas,
            "no gas for innerRelayCall");

        uint256 maxPossibleCharge = calculateCharge(
            maxPossibleGas,
            relayRequest.relayData
        );

        // We don't yet know how much gas will be used by the recipient, so we make sure there are enough funds to pay
        // for the maximum possible charge.
        require(maxPossibleCharge <= balances[relayRequest.relayData.paymaster],
            "Paymaster balance too low");
    }

    struct RelayCallData {
        bool success;
        bytes4 functionSelector;
        uint256 initialGasLeft;
        bytes recipientContext;
        bytes relayedCallReturnValue;
        IPaymaster.GasAndDataLimits gasAndDataLimits;
        RelayCallStatus status;
        uint256 innerGasUsed;
        uint256 maxPossibleGas;
        uint256 gasBeforeInner;
        bytes retData;
        address relayManager;
        uint256 dataGasCost;
    }

    function relayCall(
        uint maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint externalGasLimit
    )
    external
    override
    returns (bool paymasterAccepted, bytes memory returnValue)
    {
        RelayCallData memory vars;
        vars.initialGasLeft = gasleft();
        require(!isDeprecated(), "hub deprecated");
        vars.functionSelector = relayRequest.request.data.length>=4 ? MinLibBytes.readBytes4(relayRequest.request.data, 0) : bytes4(0);
        require(msg.sender == tx.origin, "relay worker must be EOA");
        vars.relayManager = workerToManager[msg.sender];
        require(vars.relayManager != address(0), "Unknown relay worker");
        require(relayRequest.relayData.relayWorker == msg.sender, "Not a right worker");
        require(
            isRelayManagerStaked(vars.relayManager),
            "relay manager not staked"
        );
        require(relayRequest.relayData.gasPrice <= tx.gasprice, "Invalid gas price");
        require(externalGasLimit <= block.gaslimit, "Impossible gas limit");

        (vars.gasAndDataLimits, vars.maxPossibleGas) =
             verifyGasAndDataLimits(maxAcceptanceBudget, relayRequest, vars.initialGasLeft, externalGasLimit);

        RelayHubValidator.verifyTransactionPacking(relayRequest,signature,approvalData);

    {

        //How much gas to pass down to innerRelayCall. must be lower than the default 63/64
        // actually, min(gasleft*63/64, gasleft-GAS_RESERVE) might be enough.
        uint256 innerGasLimit = gasleft()*63/64- config.gasReserve;
        vars.gasBeforeInner = gasleft();

        uint256 _tmpInitialGas = innerGasLimit + externalGasLimit + config.gasOverhead + config.postOverhead;
        // Calls to the recipient are performed atomically inside an inner transaction which may revert in case of
        // errors in the recipient. In either case (revert or regular execution) the return data encodes the
        // RelayCallStatus value.
        (bool success, bytes memory relayCallStatus) = address(this).call{gas:innerGasLimit}(
            abi.encodeWithSelector(RelayHub.innerRelayCall.selector, relayRequest, signature, approvalData, vars.gasAndDataLimits,
                _tmpInitialGas - gasleft(),
                vars.maxPossibleGas
                )
        );
        vars.success = success;
        vars.innerGasUsed = vars.gasBeforeInner-gasleft();
        (vars.status, vars.relayedCallReturnValue) = abi.decode(relayCallStatus, (RelayCallStatus, bytes));
        if ( vars.relayedCallReturnValue.length>0 ) {
            emit TransactionResult(vars.status, vars.relayedCallReturnValue);
        }
    }
    {
        vars.dataGasCost = calldataGasCost(msg.data.length);
        if (!vars.success) {
            //Failure cases where the PM doesn't pay
            if (vars.status == RelayCallStatus.RejectedByPreRelayed ||
                    (vars.innerGasUsed <= vars.gasAndDataLimits.acceptanceBudget.add(vars.dataGasCost)) && (
                    vars.status == RelayCallStatus.RejectedByForwarder ||
                    vars.status == RelayCallStatus.RejectedByRecipientRevert  //can only be thrown if rejectOnRecipientRevert==true
            )) {
                paymasterAccepted=false;

                emit TransactionRejectedByPaymaster(
                    vars.relayManager,
                    relayRequest.relayData.paymaster,
                    relayRequest.request.from,
                    relayRequest.request.to,
                    msg.sender,
                    vars.functionSelector,
                    vars.innerGasUsed,
                    vars.relayedCallReturnValue);
                return (false, vars.relayedCallReturnValue);
            }
        }
        // We now perform the actual charge calculation, based on the measured gas used
        uint256 gasUsed = (externalGasLimit - gasleft()) + config.gasOverhead;
        uint256 charge = calculateCharge(gasUsed, relayRequest.relayData);

        balances[relayRequest.relayData.paymaster] = balances[relayRequest.relayData.paymaster].sub(charge);
        balances[vars.relayManager] = balances[vars.relayManager].add(charge);

        emit TransactionRelayed(
            vars.relayManager,
            msg.sender,
            relayRequest.request.from,
            relayRequest.request.to,
            relayRequest.relayData.paymaster,
            vars.functionSelector,
            vars.status,
            charge);
        return (true, "");
    }
    }

    struct InnerRelayCallData {
        uint256 balanceBefore;
        bytes32 preReturnValue;
        bool relayedCallSuccess;
        bytes relayedCallReturnValue;
        bytes recipientContext;
        bytes data;
        bool rejectOnRecipientRevert;
    }

    function innerRelayCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        IPaymaster.GasAndDataLimits calldata gasAndDataLimits,
        uint256 totalInitialGas,
        uint256 maxPossibleGas
    )
    external
    returns (RelayCallStatus, bytes memory)
    {
        InnerRelayCallData memory vars;
        // A new gas measurement is performed inside innerRelayCall, since
        // due to EIP150 available gas amounts cannot be directly compared across external calls

        // This external function can only be called by RelayHub itself, creating an internal transaction. Calls to the
        // recipient (preRelayedCall, the relayedCall, and postRelayedCall) are called from inside this transaction.
        require(msg.sender == address(this), "Must be called by RelayHub");

        // If either pre or post reverts, the whole internal transaction will be reverted, reverting all side effects on
        // the recipient. The recipient will still be charged for the used gas by the relay.

        // The paymaster is no allowed to withdraw balance from RelayHub during a relayed transaction. We check pre and
        // post state to ensure this doesn't happen.
        vars.balanceBefore = balances[relayRequest.relayData.paymaster];

        // First preRelayedCall is executed.
        // Note: we open a new block to avoid growing the stack too much.
        vars.data = abi.encodeWithSelector(
            IPaymaster.preRelayedCall.selector,
                relayRequest, signature, approvalData, maxPossibleGas
        );
        {
            bool success;
            bytes memory retData;
            (success, retData) = relayRequest.relayData.paymaster.call{gas:gasAndDataLimits.preRelayedCallGasLimit}(vars.data);
            if (!success) {
                GsnEip712Library.truncateInPlace(retData);
                revertWithStatus(RelayCallStatus.RejectedByPreRelayed, retData);
            }
            (vars.recipientContext, vars.rejectOnRecipientRevert) = abi.decode(retData, (bytes,bool));
        }

        // The actual relayed call is now executed. The sender's address is appended at the end of the transaction data

        {
            bool forwarderSuccess;
            (forwarderSuccess, vars.relayedCallSuccess, vars.relayedCallReturnValue) = GsnEip712Library.execute(relayRequest, signature);
            if ( !forwarderSuccess ) {
                revertWithStatus(RelayCallStatus.RejectedByForwarder, vars.relayedCallReturnValue);
            }

            if (vars.rejectOnRecipientRevert && !vars.relayedCallSuccess) {
                // we trusted the recipient, but it reverted...
                revertWithStatus(RelayCallStatus.RejectedByRecipientRevert, vars.relayedCallReturnValue);
            }
        }
        // Finally, postRelayedCall is executed, with the relayedCall execution's status and a charge estimate
        // We now determine how much the recipient will be charged, to pass this value to postRelayedCall for accurate
        // accounting.
        vars.data = abi.encodeWithSelector(
            IPaymaster.postRelayedCall.selector,
            vars.recipientContext,
            vars.relayedCallSuccess,
            totalInitialGas - gasleft(), /*gasUseWithoutPost*/
            relayRequest.relayData
        );

        {
        (bool successPost,bytes memory ret) = relayRequest.relayData.paymaster.call{gas:gasAndDataLimits.postRelayedCallGasLimit}(vars.data);

        if (!successPost) {
            revertWithStatus(RelayCallStatus.PostRelayedFailed, ret);
        }
        }

        if (balances[relayRequest.relayData.paymaster] < vars.balanceBefore) {
            revertWithStatus(RelayCallStatus.PaymasterBalanceChanged, "");
        }

        return (vars.relayedCallSuccess ? RelayCallStatus.OK : RelayCallStatus.RelayedCallFailed, vars.relayedCallReturnValue);
    }

    /**
     * @dev Reverts the transaction with return data set to the ABI encoding of the status argument (and revert reason data)
     */
    function revertWithStatus(RelayCallStatus status, bytes memory ret) private pure {
        bytes memory data = abi.encode(status, ret);
        GsnEip712Library.truncateInPlace(data);

        assembly {
            let dataSize := mload(data)
            let dataPtr := add(data, 32)

            revert(dataPtr, dataSize)
        }
    }

    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) public override virtual view returns (uint256) {
        return relayData.baseRelayFee.add((gasUsed.mul(relayData.gasPrice).mul(relayData.pctRelayFee.add(100))).div(100));
    }

    function isRelayManagerStaked(address relayManager) public override view returns (bool) {
        return stakeManager.isRelayManagerStaked(relayManager, address(this), config.minimumStake, config.minimumUnstakeDelay);
    }

    function deprecateHub(uint256 fromBlock) public override onlyOwner {
        require(deprecationBlock > block.number, "Already deprecated");
        deprecationBlock = fromBlock;
        emit HubDeprecated(fromBlock);
    }

    function isDeprecated() public override view returns (bool) {
        return block.number >= deprecationBlock;
    }

    modifier penalizerOnly () {
        require(msg.sender == penalizer, "Not penalizer");
        _;
    }

    function penalize(address relayWorker, address payable beneficiary) external override penalizerOnly {
        address relayManager = workerToManager[relayWorker];
        // The worker must be controlled by a manager with a locked stake
        require(relayManager != address(0), "Unknown relay worker");
        require(
            isRelayManagerStaked(relayManager),
            "relay manager not staked"
        );
        IStakeManager.StakeInfo memory stakeInfo = stakeManager.getStakeInfo(relayManager);
        stakeManager.penalizeRelayManager(relayManager, beneficiary, stakeInfo.stake);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IStakeManager.sol";

contract StakeManager is IStakeManager {
    using SafeMath for uint256;

    string public override versionSM = "2.2.0+opengsn.stakemanager.istakemanager";
    uint256 public immutable override maxUnstakeDelay;

    /// maps relay managers to their stakes
    mapping(address => StakeInfo) public stakes;
    function getStakeInfo(address relayManager) external override view returns (StakeInfo memory stakeInfo) {
        return stakes[relayManager];
    }

    /// maps relay managers to a map of addressed of their authorized hubs to the information on that hub
    mapping(address => mapping(address => RelayHubInfo)) public authorizedHubs;

    constructor(uint256 _maxUnstakeDelay) {
        maxUnstakeDelay = _maxUnstakeDelay;
    }

    function setRelayManagerOwner(address payable owner) external override {
        require(owner != address(0), "invalid owner");
        require(stakes[msg.sender].owner == address(0), "already owned");
        stakes[msg.sender].owner = owner;
        emit OwnerSet(msg.sender, owner);
    }

    /// Put a stake for a relayManager and set its unstake delay. Only the owner can call this function.
    /// @param relayManager - address that represents a stake entry and controls relay registrations on relay hubs
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    function stakeForRelayManager(address relayManager, uint256 unstakeDelay) external override payable ownerOnly(relayManager) {
        require(unstakeDelay >= stakes[relayManager].unstakeDelay, "unstakeDelay cannot be decreased");
        require(unstakeDelay <= maxUnstakeDelay, "unstakeDelay too big");
        stakes[relayManager].stake += msg.value;
        stakes[relayManager].unstakeDelay = unstakeDelay;
        emit StakeAdded(relayManager, stakes[relayManager].owner, stakes[relayManager].stake, stakes[relayManager].unstakeDelay);
    }

    function unlockStake(address relayManager) external override ownerOnly(relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.withdrawBlock == 0, "already pending");
        uint withdrawBlock = block.number.add(info.unstakeDelay);
        info.withdrawBlock = withdrawBlock;
        emit StakeUnlocked(relayManager, msg.sender, withdrawBlock);
    }

    function withdrawStake(address relayManager) external override ownerOnly(relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.withdrawBlock > 0, "Withdrawal is not scheduled");
        require(info.withdrawBlock <= block.number, "Withdrawal is not due");
        uint256 amount = info.stake;
        info.stake = 0;
        info.withdrawBlock = 0;
        msg.sender.transfer(amount);
        emit StakeWithdrawn(relayManager, msg.sender, amount);
    }

    modifier ownerOnly (address relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.owner == msg.sender, "not owner");
        _;
    }

    modifier managerOnly () {
        StakeInfo storage info = stakes[msg.sender];
        require(info.owner != address(0), "not manager");
        _;
    }

    function authorizeHubByOwner(address relayManager, address relayHub) external ownerOnly(relayManager) override {
        _authorizeHub(relayManager, relayHub);
    }

    function authorizeHubByManager(address relayHub) external managerOnly override {
        _authorizeHub(msg.sender, relayHub);
    }

    function _authorizeHub(address relayManager, address relayHub) internal {
        authorizedHubs[relayManager][relayHub].removalBlock = uint(-1);
        emit HubAuthorized(relayManager, relayHub);
    }

    function unauthorizeHubByOwner(address relayManager, address relayHub) external override ownerOnly(relayManager) {
        _unauthorizeHub(relayManager, relayHub);
    }

    function unauthorizeHubByManager(address relayHub) external override managerOnly {
        _unauthorizeHub(msg.sender, relayHub);
    }

    function _unauthorizeHub(address relayManager, address relayHub) internal {
        RelayHubInfo storage hubInfo = authorizedHubs[relayManager][relayHub];
        require(hubInfo.removalBlock == uint(-1), "hub not authorized");
        uint256 removalBlock = block.number.add(stakes[relayManager].unstakeDelay);
        hubInfo.removalBlock = removalBlock;
        emit HubUnauthorized(relayManager, relayHub, removalBlock);
    }

    function isRelayManagerStaked(address relayManager, address relayHub, uint256 minAmount, uint256 minUnstakeDelay)
    external
    override
    view
    returns (bool) {
        StakeInfo storage info = stakes[relayManager];
        bool isAmountSufficient = info.stake >= minAmount;
        bool isDelaySufficient = info.unstakeDelay >= minUnstakeDelay;
        bool isStakeLocked = info.withdrawBlock == 0;
        bool isHubAuthorized = authorizedHubs[relayManager][relayHub].removalBlock == uint(-1);
        return
        isAmountSufficient &&
        isDelaySufficient &&
        isStakeLocked &&
        isHubAuthorized;
    }

    /// Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns half of stake on the way.
    /// @param relayManager - entry to penalize
    /// @param beneficiary - address that receives half of the penalty amount
    /// @param amount - amount to withdraw from stake
    function penalizeRelayManager(address relayManager, address payable beneficiary, uint256 amount) external override {
        uint256 removalBlock =  authorizedHubs[relayManager][msg.sender].removalBlock;
        require(removalBlock != 0, "hub not authorized");
        require(removalBlock > block.number, "hub authorization expired");

        // Half of the stake will be burned (sent to address 0)
        require(stakes[relayManager].stake >= amount, "penalty exceeds stake");
        stakes[relayManager].stake = SafeMath.sub(stakes[relayManager].stake, amount);

        uint256 toBurn = SafeMath.div(amount, 2);
        uint256 reward = SafeMath.sub(amount, toBurn);

        // Ether is burned and transferred
        address(0).transfer(toBurn);
        beneficiary.transfer(reward);
        emit StakePenalized(relayManager, beneficiary, reward);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./IForwarder.sol";

contract Forwarder is IForwarder {
    using ECDSA for bytes32;

    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil";

    string public constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    mapping(bytes32 => bool) public typeHashes;
    mapping(bytes32 => bool) public domains;

    // Nonces of senders, used to prevent replay attacks
    mapping(address => uint256) private nonces;

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function getNonce(address from)
    public view override
    returns (uint256) {
        return nonces[from];
    }

    constructor() {

        string memory requestType = string(abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")"));
        registerRequestTypeInternal(requestType);
    }

    function verify(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    external override view {

        _verifyNonce(req);
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
    }

    function execute(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig
    )
    external payable
    override
    returns (bool success, bytes memory ret) {
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
        _verifyAndUpdateNonce(req);

        require(req.validUntil == 0 || req.validUntil > block.number, "FWD: request expired");

        uint gasForTransfer = 0;
        if ( req.value != 0 ) {
            gasForTransfer = 40000; //buffer in case we need to move eth after the transaction.
        }
        bytes memory callData = abi.encodePacked(req.data, req.from);
        require(gasleft()*63/64 >= req.gas + gasForTransfer, "FWD: insufficient gas");
        // solhint-disable-next-line avoid-low-level-calls
        (success,ret) = req.to.call{gas : req.gas, value : req.value}(callData);
        if ( req.value != 0 && address(this).balance>0 ) {
            // can't fail: req.from signed (off-chain) the request, so it must be an EOA...
            payable(req.from).transfer(address(this).balance);
        }

        return (success,ret);
    }


    function _verifyNonce(ForwardRequest calldata req) internal view {
        require(nonces[req.from] == req.nonce, "FWD: nonce mismatch");
    }

    function _verifyAndUpdateNonce(ForwardRequest calldata req) internal {
        require(nonces[req.from]++ == req.nonce, "FWD: nonce mismatch");
    }

    function registerRequestType(string calldata typeName, string calldata typeSuffix) external override {

        for (uint i = 0; i < bytes(typeName).length; i++) {
            bytes1 c = bytes(typeName)[i];
            require(c != "(" && c != ")", "FWD: invalid typename");
        }

        string memory requestType = string(abi.encodePacked(typeName, "(", GENERIC_PARAMS, ",", typeSuffix));
        registerRequestTypeInternal(requestType);
    }

    function registerDomainSeparator(string calldata name, string calldata version) external override {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly { chainId := chainid() }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this));

        bytes32 domainHash = keccak256(domainValue);

        domains[domainHash] = true;
        emit DomainRegistered(domainHash, domainValue);
    }

    function registerRequestTypeInternal(string memory requestType) internal {

        bytes32 requestTypehash = keccak256(bytes(requestType));
        typeHashes[requestTypehash] = true;
        emit RequestTypeRegistered(requestTypehash, requestType);
    }

    function _verifySig(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    internal
    view
    {
        require(domains[domainSeparator], "FWD: unregistered domain sep.");
        require(typeHashes[requestTypeHash], "FWD: unregistered typehash");
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01", domainSeparator,
                keccak256(_getEncoded(req, requestTypeHash, suffixData))
            ));
        require(digest.recover(sig) == req.from, "FWD: signature mismatch");
    }

    function _getEncoded(
        ForwardRequest calldata req,
        bytes32 requestTypeHash,
        bytes calldata suffixData
    )
    public
    pure
    returns (
        bytes memory
    ) {
        // we use encodePacked since we append suffixData as-is, not as dynamic param.
        // still, we must make sure all first params are encoded as abi.encode()
        // would encode them - as 256-bit-wide params.
        return abi.encodePacked(
            requestTypeHash,
            uint256(uint160(req.from)),
            uint256(uint160(req.to)),
            req.value,
            req.gas,
            req.nonce,
            keccak256(req.data),
            req.validUntil,
            suffixData
        );
    }
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * verify the transaction would execute.
     * validate the signature and the nonce of the request.
     * revert if either signature or nonce are incorrect.
     * also revert if domainSeparator or requestTypeHash are not registered.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * execute a transaction
     * @param forwardRequest - all transaction parameters
     * @param domainSeparator - domain used when signing this request
     * @param requestTypeHash - request type used when signing this request.
     * @param suffixData - the extension data used when signing this request.
     * @param signature - signature to validate.
     *
     * the transaction is verified, and then executed.
     * the success and ret of "call" are returned.
     * This method would revert only verification errors. target errors
     * are reported using the returned "success" and ret string
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * Register a new Request typehash.
     * @param typeName - the name of the request type.
     * @param typeSuffix - any extra data after the generic params.
     *  (must add at least one param. The generic ForwardRequest type is always registered by the constructor)
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * Register a new domain separator.
     * The domain separator must have the following fields: name,version,chainId, verifyingContract.
     * the chainId is the current network's chainId, and the verifyingContract is this forwarder.
     * This method is given the domain name and version to create and register the domain separator value.
     * @param name the domain's display name
     * @param version the domain/protocol version
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../Forwarder.sol";

// helper class for testing the forwarder.
contract TestForwarder {
    function callExecute(Forwarder forwarder, Forwarder.ForwardRequest memory req,
        bytes32 domainSeparator, bytes32 requestTypeHash, bytes memory suffixData, bytes memory sig) public payable {
        (bool success, bytes memory error) = forwarder.execute{value:msg.value}(req, domainSeparator, requestTypeHash, suffixData, sig);
        emit Result(success, success ? "" : this.decodeErrorMessage(error));
    }

    event Result(bool success, string error);

    function decodeErrorMessage(bytes calldata ret) external pure returns (string memory message) {
        //decode evert string: assume it has a standard Error(string) signature: simply skip the (selector,offset,length) fields
        if ( ret.length>4+32+32 ) {
            return abi.decode(ret[4:], (string));
        }
        //unknown buffer. return as-is
        return string(ret);
    }

    function getChainId() public pure returns (uint256 id){
        /* solhint-disable-next-line no-inline-assembly */
        assembly { id := chainid() }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;

import "../../BaseRelayRecipient.sol";

contract TestForwarderTarget is BaseRelayRecipient {

    string public override versionRecipient = "2.2.0+opengsn.test.recipient";

    constructor(address forwarder) {
        trustedForwarder = forwarder;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    event TestForwarderMessage(string message, bytes realMsgData, address realSender, address msgSender, address origin);

    function emitMessage(string memory message) public {

        // solhint-disable-next-line avoid-tx-origin
        emit TestForwarderMessage(message, _msgData(), _msgSender(), msg.sender, tx.origin);
    }

    function publicMsgSender() public view returns (address) {
        return _msgSender();
    }

    function publicMsgData() public view returns (bytes memory) {
        return _msgData();
    }

    function mustReceiveEth(uint value) public payable {
        require( msg.value == value, "didn't receive value");
    }

    event Reverting(string message);

    function testRevert() public {
        require(address(this) == address(0), "always fail");
        emit Reverting("if you see this revert failed...");
    }
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";

interface IPaymaster {

    /**
     * @param acceptanceBudget -
     *      Paymaster expected gas budget to accept (or reject) a request
     *      This a gas required by any calculations that might need to reject the
     *      transaction, by preRelayedCall, forwarder and recipient.
     *      See value in BasePaymaster.PAYMASTER_ACCEPTANCE_BUDGET
     *      Transaction that gets rejected above that gas usage is on the paymaster's expense.
     *      As long this value is above preRelayedCallGasLimit (see defaults in BasePaymaster), the
     *      Paymaster is guaranteed it will never pay for rejected transactions.
     *      If this value is below preRelayedCallGasLimt, it might might make Paymaster open to a "griefing" attack.
     *
     *      Specifying value too high might make the call rejected by some relayers.
     *
     *      From a Relay's point of view, this is the highest gas value a paymaster might "grief" the relay,
     *      since the paymaster will pay anything above that (regardless if the tx reverts)
     *
     * @param preRelayedCallGasLimit - the max gas usage of preRelayedCall. any revert (including OOG)
     *      of preRelayedCall is a reject by the paymaster.
     *      as long as acceptanceBudget is above preRelayedCallGasLimit, any such revert (including OOG)
     *      is not payed by the paymaster.
     * @param postRelayedCallGasLimit - the max gas usage of postRelayedCall.
     *      note that an OOG will revert the transaction, but the paymaster already committed to pay,
     *      so the relay will get compensated, at the expense of the paymaster
     */
    struct GasAndDataLimits {
        uint256 acceptanceBudget;
        uint256 preRelayedCallGasLimit;
        uint256 postRelayedCallGasLimit;
        uint256 calldataSizeLimit;
    }

    /**
     * Return the Gas Limits and msg.data max size constants used by the Paymaster.
     */
    function getGasAndDataLimits()
    external
    view
    returns (
        GasAndDataLimits memory limits
    );

    function trustedForwarder() external view returns (IForwarder);

/**
 * return the relayHub of this contract.
 */
    function getHubAddr() external view returns (address);

    /**
     * Can be used to determine if the contract can pay for incoming calls before making any.
     * @return the paymaster's deposit in the RelayHub.
     */
    function getRelayHubDeposit() external view returns (uint256);

    /**
     * Called by Relay (and RelayHub), to validate if the paymaster agrees to pay for this call.
     *
     * MUST be protected with relayHubOnly() in case it modifies state.
     *
     * The Paymaster rejects by the following "revert" operations
     *  - preRelayedCall() method reverts
     *  - the forwarder reverts because of nonce or signature error
     *  - the paymaster returned "rejectOnRecipientRevert", and the recipient contract reverted.
     * In any of the above cases, all paymaster calls (and recipient call) are reverted.
     * In any other case, the paymaster agrees to pay for the gas cost of the transaction (note
     *  that this includes also postRelayedCall revert)
     *
     * The rejectOnRecipientRevert flag means the Paymaster "delegate" the rejection to the recipient
     *  code.  It also means the Paymaster trust the recipient to reject fast: both preRelayedCall,
     *  forwarder check and receipient checks must fit into the GasLimits.acceptanceBudget,
     *  otherwise the TX is paid by the Paymaster.
     *
     *  @param relayRequest - the full relay request structure
     *  @param signature - user's EIP712-compatible signature of the {@link relayRequest}.
     *              Note that in most cases the paymaster shouldn't try use it at all. It is always checked
     *              by the forwarder immediately after preRelayedCall returns.
     *  @param approvalData - extra dapp-specific data (e.g. signature from trusted party)
     *  @param maxPossibleGas - based on values returned from {@link getGasAndDataLimits},
     *         the RelayHub will calculate the maximum possible amount of gas the user may be charged for.
     *         In order to convert this value to wei, the Paymaster has to call "relayHub.calculateCharge()"
     *  return:
     *      a context to be passed to postRelayedCall
     *      rejectOnRecipientRevert - TRUE if paymaster want to reject the TX if the recipient reverts.
     *          FALSE means that rejects by the recipient will be completed on chain, and paid by the paymaster.
     *          (note that in the latter case, the preRelayedCall and postRelayedCall are not reverted).
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    returns (bytes memory context, bool rejectOnRecipientRevert);

    /**
     * This method is called after the actual relayed function call.
     * It may be used to record the transaction (e.g. charge the caller by some contract logic) for this call.
     *
     * MUST be protected with relayHubOnly() in case it modifies state.
     *
     * @param context - the call context, as returned by the preRelayedCall
     * @param success - true if the relayed call succeeded, false if it reverted
     * @param gasUseWithoutPost - the actual amount of gas used by the entire transaction, EXCEPT
     *        the gas used by the postRelayedCall itself.
     * @param relayData - the relay params of the request. can be used by relayHub.calculateCharge()
     *
     * Revert in this functions causes a revert of the client's relayed call (and preRelayedCall(), but the Paymaster
     * is still committed to pay the relay for the entire transaction.
     */
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external;

    function versionPaymaster() external view returns (string memory);
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;

import "./IRelayHub.sol";

interface IPenalizer {

    event CommitAdded(address indexed sender, bytes32 indexed commitHash, uint256 readyBlockNumber);

    struct Transaction {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
    }

    function commit(bytes32 commitHash) external;

    function penalizeRepeatedNonce(
        bytes calldata unsignedTx1,
        bytes calldata signature1,
        bytes calldata unsignedTx2,
        bytes calldata signature2,
        IRelayHub hub,
        uint256 randomValue
    ) external;

    function penalizeIllegalTransaction(
        bytes calldata unsignedTx,
        bytes calldata signature,
        IRelayHub hub,
        uint256 randomValue
    ) external;

    function versionPenalizer() external view returns (string memory);
    function penalizeBlockDelay() external view returns (uint256);
    function penalizeBlockExpiration() external view returns (uint256);
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

interface IRelayHub {
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Maximum funds that can be deposited at once. Prevents user error by disallowing large deposits.
        uint256 maximumRecipientDeposit;
        // Minimum unstake delay blocks of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Minimum stake a relay can have. An attack on the network will never cost less than half this value.
        uint256 minimumStake;
        // relayCall()'s msg.data upper bound gas cost per byte
        uint256 dataGasCostPerByte;
        // relayCalls() minimal gas overhead when calculating cost of putting tx on chain.
        uint256 externalCallDataCostOverhead;
    }

    event RelayHubConfigured(RelayHubConfig config);

    /// Emitted when a relay server registers or updates its details
    /// Looking at these events lets a client discover relay servers
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        string relayUrl
    );

    /// Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// Emitted when an account withdraws funds from RelayHub.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// Emitted when depositFor is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// Emitted when an attempt to relay a call fails and Paymaster does not accept the transaction.
    /// The actual relayed call was not executed, and the recipient not charged.
    /// @param reason contains a revert reason returned from preRelayedCall or forwarder.
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        address indexed from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /// Emitted when a transaction is relayed. Note that the actual encoded function might be reverted: this will be
    /// indicated in the status field.
    /// Useful when monitoring a relay's operation and relayed calls to a contract.
    /// Charge is the ether value deducted from the recipient's balance, paid to the relay's manager.
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        address indexed from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    event HubDeprecated(uint256 fromBlock);

    /// Reason error codes for the TransactionRelayed event
    /// @param OK - the transaction was successfully relayed and execution successful - never included in the event
    /// @param RelayedCallFailed - the transaction was relayed, but the relayed call failed
    /// @param RejectedByPreRelayed - the transaction was not relayed due to preRelatedCall reverting
    /// @param RejectedByForwarder - the transaction was not relayed due to forwarder check (signature,nonce)
    /// @param PostRelayedFailed - the transaction was relayed and reverted due to postRelatedCall reverting
    /// @param PaymasterBalanceChanged - the transaction was relayed and reverted due to the paymaster balance change
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /// Add new worker addresses controlled by sender who must be a staked Relay Manager address.
    /// Emits a RelayWorkersAdded event.
    /// This function can be called multiple times, emitting new events
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external;

    // Balance management

    /// Deposits ether for a contract, so that it can receive (and pay for) relayed transactions. Unused balance can only
    /// be withdrawn by the contract itself, by calling withdraw.
    /// Emits a Deposited event.
    function depositFor(address target) external payable;

    /// Withdraws from an account's balance, sending it back to it. Relay managers call this to retrieve their revenue, and
    /// contracts can also use it to reduce their funding.
    /// Emits a Withdrawn event.
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying


    /// Relays a transaction. For this to succeed, multiple conditions must be met:
    ///  - Paymaster's "preRelayCall" method must succeed and not revert
    ///  - the sender must be a registered Relay Worker that the user signed
    ///  - the transaction's gas price must be equal or larger than the one that was signed by the sender
    ///  - the transaction must have enough gas to run all internal transactions if they use all gas available to them
    ///  - the Paymaster must have enough balance to pay the Relay Worker for the scenario when all gas is spent
    ///
    /// If all conditions are met, the call will be relayed and the recipient charged.
    ///
    /// Arguments:
    /// @param maxAcceptanceBudget - max valid value for paymaster.getGasLimits().acceptanceBudget
    /// @param relayRequest - all details of the requested relayed call
    /// @param signature - client's EIP-712 signature over the relayRequest struct
    /// @param approvalData: dapp-specific data forwarded to preRelayedCall.
    ///        This value is *not* verified by the Hub. For example, it can be used to pass a signature to the Paymaster
    /// @param externalGasLimit - the value passed as gasLimit to the transaction.
    ///
    /// Emits a TransactionRelayed event.
    function relayCall(
        uint maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint externalGasLimit
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    function penalize(address relayWorker, address payable beneficiary) external;

    function setConfiguration(RelayHubConfig memory _config) external;

    // Deprecate hub (reverting relayCall()) from block number 'fromBlock'
    // Can only be called by owner
    function deprecateHub(uint256 fromBlock) external;

    /// The fee is expressed as a base fee in wei plus percentage on actual charge.
    /// E.g. a value of 40 stands for a 40% fee, so the recipient will be
    /// charged for 1.4 times the spent amount.
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /* getters */

    /// Returns the whole hub configuration
    function getConfiguration() external view returns (RelayHubConfig memory config);

    function calldataGasCost(uint256 length) external view returns (uint256);

    function workerToManager(address worker) external view returns(address);

    function workerCount(address manager) external view returns(uint256);

    /// Returns an account's deposits. It can be either a deposit of a paymaster, or a revenue of a relay manager.
    function balanceOf(address target) external view returns (uint256);

    function stakeManager() external view returns (IStakeManager);

    function penalizer() external view returns (address);

    /// Uses StakeManager info to decide if the Relay Manager can be considered staked
    /// @return true if stake size and delay satisfy all requirements
    function isRelayManagerStaked(address relayManager) external view returns(bool);

    // Checks hubs' deprecation status
    function isDeprecated() external view returns (bool);

    // Returns the block number from which the hub no longer allows relaying calls.
    function deprecationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the hub contract
    function versionHub() external view returns (string memory);
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IStakeManager {

    /// Emitted when a stake or unstakeDelay are initialized or increased
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawBlock
    );

    /// Emitted when owner withdraws relayManager funds
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        uint256 amount
    );

    /// Emitted when an authorized Relay Hub penalizes a relayManager
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        uint256 reward
    );

    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalBlock
    );

    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @param stake - amount of ether staked for this relay
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    /// @param withdrawBlock - first block number 'withdraw' will be callable, or zero if the unlock has not been called
    /// @param owner - address that receives revenue and manages relayManager's stake
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawBlock;
        address payable owner;
    }

    struct RelayHubInfo {
        uint256 removalBlock;
    }

    /// Set the owner of a Relay Manager. Called only by the RelayManager itself.
    /// Note that owners cannot transfer ownership - if the entry already exists, reverts.
    /// @param owner - owner of the relay (as configured off-chain)
    function setRelayManagerOwner(address payable owner) external;

    /// Only the owner can call this function. If the entry does not exist, reverts.
    /// @param relayManager - address that represents a stake entry and controls relay registrations on relay hubs
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    function stakeForRelayManager(address relayManager, uint256 unstakeDelay) external payable;

    function unlockStake(address relayManager) external;

    function withdrawStake(address relayManager) external;

    function authorizeHubByOwner(address relayManager, address relayHub) external;

    function authorizeHubByManager(address relayHub) external;

    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    function unauthorizeHubByManager(address relayHub) external;

    function isRelayManagerStaked(address relayManager, address relayHub, uint256 minAmount, uint256 minUnstakeDelay)
    external
    view
    returns (bool);

    /// Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns half of stake on the way.
    /// @param relayManager - entry to penalize
    /// @param beneficiary - address that receives half of the penalty amount
    /// @param amount - amount to withdraw from stake
    function penalizeRelayManager(address relayManager, address payable beneficiary, uint256 amount) external;

    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo);

    function maxUnstakeDelay() external view returns (uint256);

    function versionSM() external view returns (string memory);
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;

interface IVersionRegistry {

    //event emitted whenever a version is added
    event VersionAdded(bytes32 indexed id, bytes32 version, string value, uint time);

    //event emitted whenever a version is canceled
    event VersionCanceled(bytes32 indexed id, bytes32 version, string reason);

    /**
     * add a version
     * @param id the object-id to add a version (32-byte string)
     * @param version the new version to add (32-byte string)
     * @param value value to attach to this version
     */
    function addVersion(bytes32 id, bytes32 version, string calldata value) external;

    /**
     * cancel a version.
     */
    function cancelVersion(bytes32 id, bytes32 version, string calldata reason) external;
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

//make sure that "payable" function that uses _msgSender() still works
// (its not required to use _msgSender(), since the default function
// will never be called through GSN, but still, if someone uses it,
// it should work)
contract PayableWithEmit is BaseRelayRecipient {

  string public override versionRecipient = "2.2.0+opengsn.payablewithemit.irelayrecipient";

  event Received(address sender, uint value, uint gasleft);

  receive () external payable {

    emit Received(_msgSender(), msg.value, gasleft());
  }


  //helper: send value to another contract
  function doSend(address payable target) public payable {

    uint before = gasleft();
    // solhint-disable-next-line check-send-result
    bool success = target.send(msg.value);
    uint gasAfter = gasleft();
    emit GasUsed(before-gasAfter, success);
  }
  event GasUsed(uint gasUsed, bool success);
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterConfigurableMisbehavior is TestPaymasterEverythingAccepted {

    bool public withdrawDuringPostRelayedCall;
    bool public withdrawDuringPreRelayedCall;
    bool public returnInvalidErrorCode;
    bool public revertPostRelayCall;
    bool public outOfGasPre;
    bool public revertPreRelayCall;
    bool public revertPreRelayCallOnEvenBlocks;
    bool public greedyAcceptanceBudget;
    bool public expensiveGasLimits;

    function setWithdrawDuringPostRelayedCall(bool val) public {
        withdrawDuringPostRelayedCall = val;
    }
    function setWithdrawDuringPreRelayedCall(bool val) public {
        withdrawDuringPreRelayedCall = val;
    }
    function setReturnInvalidErrorCode(bool val) public {
        returnInvalidErrorCode = val;
    }
    function setRevertPostRelayCall(bool val) public {
        revertPostRelayCall = val;
    }
    function setRevertPreRelayCall(bool val) public {
        revertPreRelayCall = val;
    }
    function setRevertPreRelayCallOnEvenBlocks(bool val) public {
        revertPreRelayCallOnEvenBlocks = val;
    }
    function setOutOfGasPre(bool val) public {
        outOfGasPre = val;
    }

    function setGreedyAcceptanceBudget(bool val) public {
        greedyAcceptanceBudget = val;
    }
    function setExpensiveGasLimits(bool val) public {
        expensiveGasLimits = val;
    }

    // solhint-disable reason-string
    // contains comments that are checked in tests
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    relayHubOnly
    returns (bytes memory, bool) {
        (signature, approvalData, maxPossibleGas);
        if (outOfGasPre) {
            uint i = 0;
            while (true) {
                i++;
            }
        }

        require(!returnInvalidErrorCode, "invalid code");

        if (withdrawDuringPreRelayedCall) {
            withdrawAllBalance();
        }
        if (revertPreRelayCall) {
            revert("You asked me to revert, remember?");
        }
        if (revertPreRelayCallOnEvenBlocks && block.number % 2 == 0) {
            revert("You asked me to revert on even blocks, remember?");
        }
        _verifyForwarder(relayRequest);
        return ("", trustRecipientRevert);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        if (withdrawDuringPostRelayedCall) {
            withdrawAllBalance();
        }
        if (revertPostRelayCall) {
            revert("You asked me to revert, remember?");
        }
    }

    /// leaving withdrawal public and unprotected
    function withdrawAllBalance() public returns (uint256) {
        require(address(relayHub) != address(0), "relay hub address not set");
        uint256 balance = relayHub.balanceOf(address(this));
        relayHub.withdraw(balance, address(this));
        return balance;
    }

    IPaymaster.GasAndDataLimits private limits = super.getGasAndDataLimits();

    function getGasAndDataLimits()
    public override view
    returns (IPaymaster.GasAndDataLimits memory) {

        if (expensiveGasLimits) {
            uint sum;
            //memory access is 700gas, so we waste ~50000
            for ( int i=0; i<60000; i+=700 ) {
                sum  = sum + limits.acceptanceBudget;
            }
        }
        if (greedyAcceptanceBudget) {
            return IPaymaster.GasAndDataLimits(limits.acceptanceBudget * 9, limits.preRelayedCallGasLimit, limits.postRelayedCallGasLimit,
            limits.calldataSizeLimit);
        }
        return limits;
    }

    bool private trustRecipientRevert;

    function setGasLimits(uint acceptanceBudget, uint preRelayedCallGasLimit, uint postRelayedCallGasLimit) public {
        limits = IPaymaster.GasAndDataLimits(
            acceptanceBudget,
            preRelayedCallGasLimit,
            postRelayedCallGasLimit,
            limits.calldataSizeLimit
        );
    }

    function setTrustRecipientRevert(bool on) public {
        trustRecipientRevert = on;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external override payable {}
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../forwarder/IForwarder.sol";
import "../BasePaymaster.sol";

contract TestPaymasterEverythingAccepted is BasePaymaster {

    function versionPaymaster() external view override virtual returns (string memory){
        return "2.2.0+opengsn.test-pea.ipaymaster";
    }

    event SampleRecipientPreCall();
    event SampleRecipientPostCall(bool success, uint actualCharge);

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    virtual
    returns (bytes memory, bool) {
        (signature);
        _verifyForwarder(relayRequest);
        (approvalData, maxPossibleGas);
        emit SampleRecipientPreCall();
        return ("no revert here",false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    virtual
    {
        (context, gasUseWithoutPost, relayData);
        emit SampleRecipientPostCall(success, gasUseWithoutPost);
    }

    function deposit() public payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    function withdrawAll(address payable destination) public {
        uint256 amount = relayHub.balanceOf(address(this));
        withdrawRelayHubDepositTo(amount, destination);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterOwnerSignature is TestPaymasterEverythingAccepted {
    using ECDSA for bytes32;

    /**
     * This demonstrates how dapps can provide an off-chain signatures to relayed transactions.
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    view
    override
    returns (bytes memory, bool) {
        (signature, maxPossibleGas);
        _verifyForwarder(relayRequest);

        address signer =
            keccak256(abi.encodePacked("I approve", relayRequest.request.from))
            .toEthSignedMessageHash()
            .recover(approvalData);
        require(signer == owner(), "test: not approved");
        return ("",false);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterPreconfiguredApproval is TestPaymasterEverythingAccepted {

    bytes public expectedApprovalData;

    function setExpectedApprovalData(bytes memory val) public {
        expectedApprovalData = val;
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    view
    override
    returns (bytes memory, bool) {
        (relayRequest, signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);
        require(keccak256(expectedApprovalData) == keccak256(approvalData),
            string(abi.encodePacked(
                "test: unexpected approvalData: '", approvalData, "' instead of '", expectedApprovalData, "'")));
        return ("",false);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterStoreContext is TestPaymasterEverythingAccepted {

    event SampleRecipientPreCallWithValues(
        address relay,
        address from,
        bytes encodedFunction,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes approvalData,
        uint256 maxPossibleGas
    );

    event SampleRecipientPostCallWithValues(
        string context
    );

    /**
     * This demonstrates how preRelayedCall can return 'context' data for reuse in postRelayedCall.
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        (signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);

        emit SampleRecipientPreCallWithValues(
            relayRequest.relayData.relayWorker,
            relayRequest.request.from,
            relayRequest.request.data,
            relayRequest.relayData.baseRelayFee,
            relayRequest.relayData.pctRelayFee,
            relayRequest.relayData.gasPrice,
            relayRequest.request.gas,
            approvalData,
            maxPossibleGas);
        return ("context passed from preRelayedCall to postRelayedCall",false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        emit SampleRecipientPostCallWithValues(string(context));
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterVariableGasLimits is TestPaymasterEverythingAccepted {

    string public override versionPaymaster = "2.2.0+opengsn.test-vgl.ipaymaster";

    event SampleRecipientPreCallWithValues(
        uint256 gasleft,
        uint256 maxPossibleGas
    );

    event SampleRecipientPostCallWithValues(
        uint256 gasleft,
        uint256 gasUseWithoutPost
    );

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        (signature, approvalData);
        _verifyForwarder(relayRequest);
        emit SampleRecipientPreCallWithValues(
            gasleft(), maxPossibleGas);
        return ("", false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        emit SampleRecipientPostCallWithValues(gasleft(), gasUseWithoutPost);
    }
}

/* solhint-disable avoid-tx-origin */
// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;

import "../utils/GsnUtils.sol";
import "../BaseRelayRecipient.sol";
import "./TestPaymasterConfigurableMisbehavior.sol";

contract TestRecipient is BaseRelayRecipient {

    string public override versionRecipient = "2.2.0+opengsn.test.irelayrecipient";

    constructor(address forwarder) {
        setTrustedForwarder(forwarder);
    }

    function getTrustedForwarder() public view returns(address) {
        return trustedForwarder;
    }

    function setTrustedForwarder(address forwarder) internal {
        trustedForwarder = forwarder;
    }

    event Reverting(string message);

    function testRevert() public {
        require(address(this) == address(0), "always fail");
        emit Reverting("if you see this revert failed...");
    }

    address payable public paymaster;

    function setWithdrawDuringRelayedCall(address payable _paymaster) public {
        paymaster = _paymaster;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    event SampleRecipientEmitted(string message, address realSender, address msgSender, address origin, uint256 msgValue, uint256 gasLeft, uint256 balance);

    function emitMessage(string memory message) public payable returns (string memory) {
        uint256 gasLeft = gasleft();
        if (paymaster != address(0)) {
            withdrawAllBalance();
        }

        emit SampleRecipientEmitted(message, _msgSender(), msg.sender, tx.origin, msg.value, gasLeft, address(this).balance);
        return "emitMessage return value";
    }

    function withdrawAllBalance() public {
        TestPaymasterConfigurableMisbehavior(paymaster).withdrawAllBalance();
    }

    // solhint-disable-next-line no-empty-blocks
    function dontEmitMessage(string calldata message) public {}

    function emitMessageNoParams() public {
        emit SampleRecipientEmitted("Method with no parameters", _msgSender(), msg.sender, tx.origin, 0, gasleft(), address(this).balance);
    }

    //return (or revert) with a string in the given length
    function checkReturnValues(uint len, bool doRevert) public view returns (string memory) {
        (this);
        string memory mesg = "this is a long message that we are going to return a small part from. we don't use a loop since we want a fixed gas usage of the method itself.";
        require( bytes(mesg).length>=len, "invalid len: too large");

        /* solhint-disable no-inline-assembly */
        //cut the msg at that length
        assembly { mstore(mesg, len) }
        require(!doRevert, mesg);
        return mesg;
    }

    //function with no return value (also test revert with no msg.
    function checkNoReturnValues(bool doRevert) public view {
        (this);
        /* solhint-disable reason-string*/
        require(!doRevert);
    }

}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../utils/RelayHubValidator.sol";

contract TestRelayHubValidator {

    //for testing purposes, we must be called from a method with same param signature as RelayCall
    function dummyRelayCall(
        uint, //paymasterMaxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint //externalGasLimit
    ) external pure {
        RelayHubValidator.verifyTransactionPacking(relayRequest, signature, approvalData);
    }

    // helper method for verifyTransactionPacking
    function dynamicParamSize(bytes calldata buf) external pure returns (uint) {
        return RelayHubValidator.dynamicParamSize(buf);
    }
}

/* solhint-disable avoid-tx-origin */
// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IRelayHub.sol";

contract TestRelayWorkerContract {

    function relayCall(
        IRelayHub hub,
        uint maxAcceptanceBudget,
        GsnTypes.RelayRequest memory relayRequest,
        bytes memory signature,
        uint externalGasLimit)
    public
    {
        hub.relayCall{gas:externalGasLimit}(maxAcceptanceBudget, relayRequest, signature, "", externalGasLimit);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "../utils/GsnEip712Library.sol";
import "../utils/GsnUtils.sol";

contract TestUtil {

    function libRelayRequestName() public pure returns (string memory) {
        return GsnEip712Library.RELAY_REQUEST_NAME;
    }

    function libRelayRequestType() public pure returns (string memory) {
        return string(GsnEip712Library.RELAY_REQUEST_TYPE);
    }

    function libRelayRequestTypeHash() public pure returns (bytes32) {
        return GsnEip712Library.RELAY_REQUEST_TYPEHASH;
    }

    function libRelayRequestSuffix() public pure returns (string memory) {
        return GsnEip712Library.RELAY_REQUEST_SUFFIX;
    }

    //helpers for test to call the library funcs:
    function callForwarderVerify(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    )
    external
    view {
        GsnEip712Library.verify(relayRequest, signature);
    }

    function callForwarderVerifyAndCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    )
    external
    returns (
        bool success,
        bytes memory ret
    ) {
        bool forwarderSuccess;
        (forwarderSuccess, success, ret) = GsnEip712Library.execute(relayRequest, signature);
        if ( !forwarderSuccess) {
            GsnUtils.revertWithData(ret);
        }
        emit Called(success, success == false ? ret : bytes(""));
    }

    event Called(bool success, bytes error);

    function splitRequest(
        GsnTypes.RelayRequest calldata relayRequest
    )
    external
    pure
    returns (
        bytes32 typeHash,
        bytes memory suffixData
    ) {
        (suffixData) = GsnEip712Library.splitRequest(relayRequest);
        typeHash = GsnEip712Library.RELAY_REQUEST_TYPEHASH;
    }

    function libDomainSeparator(address forwarder) public pure returns (bytes32) {
        return GsnEip712Library.domainSeparator(forwarder);
    }

    function libGetChainID() public pure returns (uint256) {
        return GsnEip712Library.getChainID();
    }
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "../interfaces/IRelayRecipient.sol";
import "../forwarder/IForwarder.sol";

import "./GsnUtils.sol";

/**
 * Bridge Library to map GSN RelayRequest into a call of a Forwarder
 */
library GsnEip712Library {
    // maximum length of return value/revert reason for 'execute' method. Will truncate result if exceeded.
    uint256 private constant MAX_RETURN_SIZE = 1024;

    //copied from Forwarder (can't reference string constants even from another library)
    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil";

    bytes public constant RELAYDATA_TYPE = "RelayData(uint256 gasPrice,uint256 pctRelayFee,uint256 baseRelayFee,address relayWorker,address paymaster,address forwarder,bytes paymasterData,uint256 clientId)";

    string public constant RELAY_REQUEST_NAME = "RelayRequest";
    string public constant RELAY_REQUEST_SUFFIX = string(abi.encodePacked("RelayData relayData)", RELAYDATA_TYPE));

    bytes public constant RELAY_REQUEST_TYPE = abi.encodePacked(
        RELAY_REQUEST_NAME,"(",GENERIC_PARAMS,",", RELAY_REQUEST_SUFFIX);

    bytes32 public constant RELAYDATA_TYPEHASH = keccak256(RELAYDATA_TYPE);
    bytes32 public constant RELAY_REQUEST_TYPEHASH = keccak256(RELAY_REQUEST_TYPE);


    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    function splitRequest(
        GsnTypes.RelayRequest calldata req
    )
    internal
    pure
    returns (
        bytes memory suffixData
    ) {
        suffixData = abi.encode(
            hashRelayData(req.relayData));
    }

    //verify that the recipient trusts the given forwarder
    // MUST be called by paymaster
    function verifyForwarderTrusted(GsnTypes.RelayRequest calldata relayRequest) internal view {
        (bool success, bytes memory ret) = relayRequest.request.to.staticcall(
            abi.encodeWithSelector(
                IRelayRecipient.isTrustedForwarder.selector, relayRequest.relayData.forwarder
            )
        );
        require(success, "isTrustedForwarder: reverted");
        require(ret.length == 32, "isTrustedForwarder: bad response");
        require(abi.decode(ret, (bool)), "invalid forwarder for recipient");
    }

    function verifySignature(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal view {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(relayRequest.relayData.forwarder);
        IForwarder forwarder = IForwarder(payable(relayRequest.relayData.forwarder));
        forwarder.verify(relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature);
    }

    function verify(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal view {
        verifyForwarderTrusted(relayRequest);
        verifySignature(relayRequest, signature);
    }

    function execute(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal returns (bool forwarderSuccess, bool callSuccess, bytes memory ret) {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(relayRequest.relayData.forwarder);
        /* solhint-disable-next-line avoid-low-level-calls */
        (forwarderSuccess, ret) = relayRequest.relayData.forwarder.call(
            abi.encodeWithSelector(IForwarder.execute.selector,
            relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature
        ));
        if ( forwarderSuccess ) {

          //decode return value of execute:
          (callSuccess, ret) = abi.decode(ret, (bool, bytes));
        }
        truncateInPlace(ret);
    }

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data) internal pure {
        MinLibBytes.truncateInPlace(data, MAX_RETURN_SIZE);
    }

    function domainSeparator(address forwarder) internal pure returns (bytes32) {
        return hashDomain(EIP712Domain({
            name : "GSN Relayed Transaction",
            version : "2",
            chainId : getChainID(),
            verifyingContract : forwarder
            }));
    }

    function getChainID() internal pure returns (uint256 id) {
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
    }

    function hashDomain(EIP712Domain memory req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(req.name)),
                keccak256(bytes(req.version)),
                req.chainId,
                req.verifyingContract));
    }

    function hashRelayData(GsnTypes.RelayData calldata req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                RELAYDATA_TYPEHASH,
                req.gasPrice,
                req.pctRelayFee,
                req.baseRelayFee,
                req.relayWorker,
                req.paymaster,
                req.forwarder,
                keccak256(req.paymasterData),
                req.clientId
            ));
    }
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice gasPrice, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 gasPrice;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

/* solhint-disable no-inline-assembly */
// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;

import "../utils/MinLibBytes.sol";

library GsnUtils {

    /**
     * extract method sig from encoded function call
     */
    function getMethodSig(bytes memory msgData) internal pure returns (bytes4) {
        return MinLibBytes.readBytes4(msgData, 0);
    }

    /**
     * extract parameter from encoded-function block.
     * see: https://solidity.readthedocs.io/en/develop/abi-spec.html#formal-specification-of-the-encoding
     * the return value should be casted to the right type (uintXXX/bytesXXX/address/bool/enum)
     */
    function getParam(bytes memory msgData, uint index) internal pure returns (uint) {
        return MinLibBytes.readUint256(msgData, 4 + index * 32);
    }

    //re-throw revert with the same revert data.
    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data,32), mload(data))
        }
    }

}

// SPDX-License-Identifier: MIT
// minimal bytes manipulation required by GSN
// a minimal subset from 0x/LibBytes
/* solhint-disable no-inline-assembly */
pragma solidity >=0.7.6;

library MinLibBytes {

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data, uint256 maxlen) internal pure {
        if (data.length > maxlen) {
            assembly { mstore(data, maxlen) }
        }
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require (b.length >= index + 20, "readAddress: data too short");

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index + 32, "readBytes32: data too short" );

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
        }
        return result;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "readBytes4: data too short");

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

// SPDX-License-Identifier:APACHE-2.0
/*
* Taken from https://github.com/hamdiallam/Solidity-RLP
*/
/* solhint-disable */
pragma solidity ^0.7.6;

library RLPReader {

    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    using RLPReader for bytes;
    using RLPReader for uint;
    using RLPReader for RLPReader.RLPItem;

    // helper function to decode rlp encoded legacy ethereum transaction
    /*
    * @param rawTransaction RLP encoded legacy ethereum transaction rlp([nonce, gasPrice, gasLimit, to, value, data]))
    * @return tuple (nonce,gasPrice,gasLimit,to,value,data)
    */

    function decodeLegacyTransaction(bytes calldata rawTransaction) internal pure returns (uint, uint, uint, address, uint, bytes memory){
        RLPReader.RLPItem[] memory values = rawTransaction.toRlpItem().toList(); // must convert to an rlpItem first!
        return (values[0].toUint(), values[1].toUint(), values[2].toUint(), values[3].toAddress(), values[4].toUint(), values[5].toBytes());
    }

    /*
    * @param rawTransaction format: 0x01 || rlp([chainId, nonce, gasPrice, gasLimit, to, value, data, access_list]))
    * @return tuple (nonce,gasPrice,gasLimit,to,value,data)
    */
    function decodeTransactionType1(bytes calldata rawTransaction) internal pure returns (uint, uint, uint, address, uint, bytes memory){
        bytes memory payload = rawTransaction[1:rawTransaction.length];
        RLPReader.RLPItem[] memory values = payload.toRlpItem().toList(); // must convert to an rlpItem first!
        return (values[1].toUint(), values[2].toUint(), values[3].toUint(), values[4].toAddress(), values[5].toUint(), values[6].toBytes());
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0)
            return RLPItem(0, 0);
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }
        return RLPItem(item.length, memPtr);
    }
    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item), "isList failed");
        uint items = numItems(item);
        result = new RLPItem[](items);
        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }
    /*
    * Helpers
    */
    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }
    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr);
            // skip over an item
            count++;
        }
        return count;
    }
    // @return entire rlp item byte length
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START)
            return 1;
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
            /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }
        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        }
        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }
    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }
    /** RLPItem conversions into data types **/
    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }
        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }
        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");
        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;
        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }
        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        // data length
        bytes memory result = new bytes(len);
        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }
        copy(item.memPtr + offset, destPtr, len);
        return result;
    }
    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) internal pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            src += WORD_SIZE;
            dest += WORD_SIZE;
        }
        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "../utils/GsnTypes.sol";

library RelayHubValidator {

    // validate that encoded relayCall is properly packed without any extra bytes
    function verifyTransactionPacking(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    ) internal pure {
        // abicoder v2: https://docs.soliditylang.org/en/latest/abi-spec.html
        // each static param/member is 1 word
        // struct (with dynamic members) has offset to struct which is 1 word
        // dynamic member is 1 word offset to actual value, which is 1-word length and ceil(length/32) words for data
        // relayCall has 5 method params,
        // relayRequest: 2 members
        // relayData 8 members
        // ForwardRequest: 7 members
        // total 22 32-byte words if all dynamic params are zero-length.
        uint expectedMsgDataLen = 4 + 22 * 32 +
            dynamicParamSize(signature) +
            dynamicParamSize(approvalData) +
            dynamicParamSize(relayRequest.request.data) +
            dynamicParamSize(relayRequest.relayData.paymasterData);
        require(signature.length <= 65, "invalid signature length");
        require(expectedMsgDataLen == msg.data.length, "extra msg.data bytes" );
    }

    // helper method for verifyTransactionPacking:
    // size (in bytes) of the given "bytes" parameter. size include the length (32-byte word),
    // and actual data size, rounded up to full 32-byte words
    function dynamicParamSize(bytes calldata buf) internal pure returns (uint) {
        return 32 + ((buf.length + 31) & uint(~31));
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
// solhint-disable not-rely-on-time

import "../interfaces/IVersionRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VersionRegistry is IVersionRegistry, Ownable {

    function addVersion(bytes32 id, bytes32 version, string calldata value) external override onlyOwner {
        require(id != bytes32(0), "missing id");
        require(version != bytes32(0), "missing version");
        emit VersionAdded(id, version, value, block.timestamp);
    }

    function cancelVersion(bytes32 id, bytes32 version, string calldata reason) external override onlyOwner {
        emit VersionCanceled(id, version, reason);
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
    constructor () /*internal*/ {
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

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.7.6;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
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

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

