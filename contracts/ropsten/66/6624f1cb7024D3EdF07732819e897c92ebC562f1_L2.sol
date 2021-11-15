// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Deserializer {
    enum OpType {
        NotSubmittedTx,
        Swap1,
        Swap2,
        AddLiquidity,
        RemoveLiquidity,
        HiddenTx,
        ForLaterUse,
        DepositToNew,
        Deposit,
        Withdraw,
        Exit
    }

    uint256 internal constant NOT_SUBMITTED_BYTES_SIZE = 1;
    uint256 internal constant SWAP_BYTES_SIZE = 11;
    uint256 internal constant ADD_LIQUIDITY_BYTES_SIZE = 16;
    uint256 internal constant REMOVE_LIQUIDITY_BYTES_SIZE = 11;
    uint256 internal constant TX_COMMITMENT_SIZE = 32;

    uint256 internal constant DEPOSIT_BYTES_SIZE = 6;
    uint256 internal constant WITHDRAW_BYTES_SIZE = 13;
    uint256 internal constant OPERATION_COMMITMENT_SIZE = 32;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@kyber.network/utils-sc/contracts/PermissionGroups.sol";

import "./libraries/UniERC20.sol";
import "./libraries/Tree.sol";
import "./libraries/BitStream.sol";

import "./Deserializer.sol";
import "./interface/ILayer2.sol";
import "./interface/IZkVerifier.sol";

// import "hardhat/console.sol";
// import "./libraries/BytesDebugger.sol";

contract L2 is ILayer2, Deserializer, PermissionGroups, ReentrancyGuard {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    uint48 private constant MAX_DEPOSIT_ID = 2**44 - 1;
    uint256 private constant MAX_TOKEN_ID = 2**10 - 1;
    uint256 private constant MAX_ACCOUNT_ID = 2**32 - 1;
    // TODO: review below constants
    uint32 private constant NUM_CHUNKS = 32;
    uint256 private constant NUM_TX_IN_BLOCKS = 8;
    uint256 private constant NUM_BLOCKS_IN_BATCH = 4;

    bytes32
        private constant EMPTY_OPERATION_COMMIMENT_ROOT = 0x5341e6b2646979a70e57653007a1f310169421ec9bdd9f1a5648f75ade005af1;
    bytes32
        private constant EMPTY_TX_COMMIMENT_ROOT = 0x5341e6b2646979a70e57653007a1f310169421ec9bdd9f1a5648f75ade005af1;
    bytes32
        private constant EMPTY_HIDDEN_TX_COMMIMENT_ROOT = 0x5341e6b2646979a70e57653007a1f310169421ec9bdd9f1a5648f75ade005af1;

    enum BatchStatus {NOT_SUBMITTED, SUBMITTED, CONFIRMED, FINALIZED, REVERT}

    struct BatchCallData {
        bytes[] operationData;
        bytes[] txData;
        bytes[] hiddenTxData;
        bytes32[] stateHashes;
    }

    struct BatchData {
        bytes32 batchRoot;
        BatchStatus status;
        uint64 submitBlockTime;
    }

    struct TokenData {
        bool isListed;
        bool isEnabled;
        uint16 tokenID;
        uint256 minDepositAmount;
    }

    /// @dev size = 224 < 1 word
    struct WithdrawRequest {
        uint16 tokenID;
        uint32 accountID;
        uint32 amountMantisa;
        uint8 amountExp;
        uint32 batchNumber;
        bool isCompleted;
    }

    struct ExitRequest {
        uint256 timeStamp;
        bool isConfirmed;
        address withdrawTo;
        bytes32 balanceRoot;
    }

    // TODO: emit finalize event
    struct AccountData {
        bool isAdded;
        uint32 accountID;
    }

    event TokenListed(IERC20 indexed token, uint16 tokenID, uint256 minDepositAmount);

    event TokenEnabled(IERC20 indexed token, bool isEnabled);

    event MinDepositSet(IERC20 indexed token, uint256 minDepositAmount);

    event SubmitDeposit(uint32 indexed accountID, uint48 depositID, uint16 tokenID, uint256 amount);

    event SubmitDepositToNew(
        address indexed withdrawTo,
        uint48 depositID,
        bytes32 pubKey,
        uint256 accountID,
        uint16 tokenID,
        uint256 amount
    );

    event SubmitBatch(uint32 indexed batchNumber, bytes32 blockDataHash, bytes32 batchRoot);

    event SubmitZkProof(
        uint32 indexed startBlock,
        uint32 indexed endBlock,
        uint256 zkProofDataID,
        bytes32 zkProofHash
    );

    event SubmitExit(uint32 indexed accountID);

    event CompleteExit(uint32 indexed accountID, uint16 tokenID, uint256 amount);

    event CompleteWithdraw(
        uint256 indexed withdrawID,
        uint32 indexed accountID,
        address indexed destAddress,
        uint16 tokenID,
        uint256 amount
    );

    // Chain of batch, each contains batchRoot
    mapping(uint256 => BatchData) public batches;
    uint256 public batchesLength;
    uint256 public lastFinalizedBatchID = 0;

    // List of token, and map from address to ID
    IERC20[] internal tokens;
    mapping(IERC20 => TokenData) public tokenInfos;

    //deposit data
    uint48 public numDeposits;
    uint48 public numIncludedDeposits;
    mapping(uint48 => bytes32) public depositHashes;

    //withdraw data
    uint256 public numWithdraws;
    mapping(uint256 => WithdrawRequest) public withdrawRequests;

    // exit data
    mapping(uint32 => ExitRequest) public exitRequests;
    mapping(uint32 => mapping(uint16 => bool)) public isCompleteExits;

    // account data
    uint32 public numOccupiedAccounts;
    mapping(bytes32 => AccountData) public pubKeyToAccountData;
    mapping(uint32 => address) public withdrawAddresses;

    // sha256 of all validators
    bytes32 public immutable validatorsPubkeyRoot;
    IZkVerifier public immutable verifier;

    /// @dev constructor also create the 1st account where fee will transfer to
    constructor(
        address _admin,
        bytes32 _adminPubKey,
        address _adminWithdrawTo,
        bytes32 _validatorsPubkeyRoot,
        bytes32 genesisRoot,
        IZkVerifier _verifier
    ) public PermissionGroups(_admin) {
        batches[0].batchRoot = genesisRoot;
        batches[0].status = BatchStatus.FINALIZED;
        batches[0].submitBlockTime = uint64(block.timestamp);
        batchesLength = 1;
        validatorsPubkeyRoot = _validatorsPubkeyRoot;
        verifier = _verifier;
        // create the 1st account
        numOccupiedAccounts = 1;
        pubKeyToAccountData[_adminPubKey] = AccountData({isAdded: true, accountID: 0});
        withdrawAddresses[0] = _adminWithdrawTo;
    }

    receive() external payable {}

    function listToken(IERC20 _token, uint256 _minDepositAmount) external onlyAdmin {
        listTokenInternal(_token, _minDepositAmount);

        emit MinDepositSet(_token, _minDepositAmount);
    }

    function setMinDepositAmount(IERC20 _token, uint256 _minDepositAmount) external onlyAdmin {
        tokenInfos[_token].minDepositAmount = _minDepositAmount;

        emit MinDepositSet(_token, _minDepositAmount);
    }

    /// @dev this function to block deposit
    function enableToken(IERC20 _token, bool _isEnabled) external onlyAdmin {
        tokenInfos[_token].isEnabled = _isEnabled;

        emit TokenEnabled(_token, _isEnabled);
    }

    function depositNewUser(
        bytes32 publicKey,
        address withdrawTo,
        IERC20 token,
        uint256 amount
    ) external payable {
        require(numDeposits < MAX_DEPOSIT_ID, "overflow depositID");
        bool isEnabled = tokenInfos[token].isEnabled;
        uint16 tokenID = tokenInfos[token].tokenID;
        require(isEnabled, "token is not enabled");
        uint256 minDepositAmount = tokenInfos[token].minDepositAmount;
        require(amount >= minDepositAmount, "insufficient deposit amount");
        require(!pubKeyToAccountData[publicKey].isAdded, "pubKey is already added");

        token.uniTransferFromSender(payable(address(this)), amount);
        uint48 depositID = numDeposits;
        depositHashes[depositID] = sha256(abi.encodePacked(depositID, publicKey, withdrawTo, tokenID, amount));
        numDeposits += 1;

        require(numOccupiedAccounts <= MAX_ACCOUNT_ID, "overflow accountID");
        uint32 accountID = numOccupiedAccounts;
        pubKeyToAccountData[publicKey] = AccountData({isAdded: true, accountID: accountID});
        withdrawAddresses[accountID] = withdrawTo;
        numOccupiedAccounts += 1;

        emit SubmitDepositToNew(withdrawTo, depositID, publicKey, accountID, tokenID, amount);
    }

    function deposit(
        uint32 accountID,
        IERC20 token,
        uint256 amount
    ) external payable {
        require(numDeposits < MAX_DEPOSIT_ID, "overflow depositID");
        bool isEnabled = tokenInfos[token].isEnabled;
        uint16 tokenID = tokenInfos[token].tokenID;
        require(isEnabled, "token is not enabled");
        uint256 minDepositAmount = tokenInfos[token].minDepositAmount;
        require(amount >= minDepositAmount, "insufficient deposit amount");
        require(accountID < numOccupiedAccounts, "deposit into uncreated account");

        token.uniTransferFromSender(payable(address(this)), amount);
        uint48 depositID = numDeposits;
        depositHashes[depositID] = sha256(abi.encodePacked(depositID, accountID, tokenID, amount));
        numDeposits = depositID + 1;

        emit SubmitDeposit(accountID, depositID, tokenID, amount);
    }

    function submitBatch(
        uint32 batchNumber,
        BatchCallData calldata batch,
        bytes32 preBlockRoot,
        uint32 timeStamp
    ) external onlyOperator {
        require(batchesLength == uint256(batchNumber), "unmatch batchNumber");
        // verfiy batch calldata
        uint256 batchLength = batch.operationData.length;
        require(
            batch.txData.length == batchLength &&
                batch.hiddenTxData.length == batchLength &&
                batch.stateHashes.length == batchLength,
            "unmatch length"
        );
        require(batchLength <= NUM_BLOCKS_IN_BATCH && batchLength > 0, "batchLength > NUM_BLOCKS_IN_BATCH");
        bytes32[] memory blockHashes = new bytes32[](NUM_BLOCKS_IN_BATCH);
        // avoid stack too deep, local sope for currentDepositID, currentWithdrawID
        {
            uint48 currentDepositID = numIncludedDeposits;
            uint256 currentWithdrawID = numWithdraws;
            for (uint256 i = 0; i < NUM_BLOCKS_IN_BATCH; i++) {
                uint256 blockNumber = i + batchNumber * NUM_BLOCKS_IN_BATCH;
                if (i < batchLength) {
                    bytes32 operationRoot;
                    (operationRoot, currentDepositID, currentWithdrawID) = handleOperation(
                        batch.operationData[i],
                        NUM_TX_IN_BLOCKS * OPERATION_COMMITMENT_SIZE,
                        currentDepositID,
                        currentWithdrawID,
                        batchNumber
                    );
                    bytes32 txRoot = handleTx(batch.txData[i], NUM_TX_IN_BLOCKS * TX_COMMITMENT_SIZE);
                    bytes32 hiddenTxRoot = handleHiddenTx(batch.hiddenTxData[i], NUM_TX_IN_BLOCKS * 32);
                    bytes32 stateHash = batch.stateHashes[i];
                    blockHashes[i] = sha256(
                        abi.encodePacked(
                            operationRoot,
                            txRoot,
                            hiddenTxRoot,
                            i == 0 ? preBlockRoot : blockHashes[i - 1],
                            blockNumber,
                            stateHash
                        )
                    );
                } else {
                    bytes32 stateHash = batch.stateHashes[batchLength - 1];
                    blockHashes[i] = sha256(
                        abi.encodePacked(
                            EMPTY_OPERATION_COMMIMENT_ROOT,
                            EMPTY_TX_COMMIMENT_ROOT,
                            EMPTY_HIDDEN_TX_COMMIMENT_ROOT,
                            blockHashes[i - 1],
                            blockNumber,
                            stateHash
                        )
                    );
                }
            }
            // at here currentDepositID == numIncludedDeposits
            require(currentDepositID <= numDeposits, "IncludedDeposits > Deposits");
            numIncludedDeposits = currentDepositID;
            numWithdraws = currentWithdrawID;
        }
        bytes32 blockDataHash = sha256(abi.encodePacked(blockHashes));
        bytes32 prevBatchRoot = batches[batchNumber - 1].batchRoot;
        bytes32 batchRoot = sha256(
            abi.encodePacked(
                prevBatchRoot,
                blockDataHash,
                timeStamp,
                uint32(batchNumber * NUM_BLOCKS_IN_BATCH),
                uint8(NUM_BLOCKS_IN_BATCH),
                batch.stateHashes[batchLength - 1]
            )
        );
        // save batch root to storage
        batches[batchNumber].batchRoot = batchRoot;
        batches[batchNumber].status = BatchStatus.SUBMITTED;
        batches[batchNumber].submitBlockTime = timeStamp;
        batchesLength++;

        emit SubmitBatch(batchNumber, blockDataHash, batchRoot);
    }

    function submitZkProof(uint256 batchNumber, uint256[] calldata zkProof) external onlyOperator {
        BatchData memory batchData = batches[batchNumber];
        require(batchData.status == BatchStatus.SUBMITTED, "invalid batchData status");
        bytes32 batchCommitment = sha256(abi.encodePacked(validatorsPubkeyRoot, batchData.batchRoot));
        require(verifier.verifyBlockProof(zkProof, batchCommitment, NUM_CHUNKS), "invalid proof");
        // if the previous batch is not finalized, then early return
        if (lastFinalizedBatchID != batchNumber - 1) {
            batchData.status = BatchStatus.CONFIRMED;
            return;
        }
        uint256 i = batchNumber;
        for (; i < batchesLength; i++) {
            if (i == batchNumber || batches[i].status == BatchStatus.CONFIRMED) {
                batches[i].status = BatchStatus.FINALIZED;
            } else {
                break;
            }
        }
        lastFinalizedBatchID = i;
        // TODO: emit finalize event
    }

    function completeWithdraw(uint256[] calldata withdrawIDs) external virtual nonReentrant {
        for (uint256 i = 0; i < withdrawIDs.length; i++) {
            uint256 withdrawID = withdrawIDs[i];
            WithdrawRequest memory withdrawRequest = withdrawRequests[withdrawID];
            if (withdrawRequest.isCompleted) {
                continue;
            }

            if (batches[withdrawRequest.batchNumber].status == BatchStatus.FINALIZED) {
                continue;
            }
            IERC20 token = IERC20(tokens[withdrawRequest.tokenID]);
            uint256 amount = uint256(withdrawRequest.amountMantisa) * (10**uint256(withdrawRequest.amountExp));
            address payable destAddress = address(uint256(withdrawAddresses[withdrawRequest.accountID]));

            withdrawRequests[withdrawID].isCompleted = true;
            //TODO: how to implement a fail safe here
            token.uniTransfer(destAddress, amount);
            emit CompleteWithdraw(
                withdrawIDs[i],
                withdrawRequest.accountID,
                destAddress,
                withdrawRequest.tokenID,
                amount
            );
        }
    }

    function isAllowedWithdraw(uint256[] calldata withdrawIDs)
        external
        view
        returns (bool[] memory isAllowedWithdrawFlags)
    {
        isAllowedWithdrawFlags = new bool[](withdrawIDs.length);
        for (uint256 i = 0; i < withdrawIDs.length; i++) {
            uint256 withdrawID = withdrawIDs[i];
            WithdrawRequest memory withdrawRequest = withdrawRequests[withdrawID];
            if (withdrawRequest.isCompleted) {
                isAllowedWithdrawFlags[i] = false;
                continue;
            }

            if (batches[withdrawRequest.batchNumber].status == BatchStatus.FINALIZED) {
                isAllowedWithdrawFlags[i] = false;
                continue;
            }
            isAllowedWithdrawFlags[i] = true;
        }
    }

    function getBatchRoot(uint256 batchNumber) external override view returns (bytes32 batchRoot) {
        return batches[batchNumber].batchRoot;
    }

    function lastestBatch() external override view returns (bytes32 batchRoot, uint256 batchNumber) {
        uint256 _batchesLength = batchesLength;
        batchRoot = batches[_batchesLength - 1].batchRoot;
        batchNumber = _batchesLength - 1;
    }

    function getTokens() external view returns (IERC20[] memory) {
        return tokens;
    }

    function listTokenInternal(IERC20 token, uint256 minDepositAmount) internal {
        require(tokens.length <= MAX_TOKEN_ID, "overflow tokenID");
        require(minDepositAmount > 0, "zero minDepositAmount");
        require(!tokenInfos[token].isListed, "listed Token");
        uint16 tokenID = uint16(tokens.length);
        tokens.push(token);
        tokenInfos[token] = TokenData({
            isListed: true,
            isEnabled: true,
            tokenID: tokenID,
            minDepositAmount: minDepositAmount
        });

        emit TokenListed(token, tokenID, minDepositAmount);
    }

    /// @dev marks incoming Depoist and Exit as done, calculates operation Root
    function handleOperation(
        bytes memory operationData,
        uint256 operationCommitmentLength,
        uint48 _currentDepositID,
        uint256 _currentWithdrawID,
        uint32 batchNumber
    )
        internal
        returns (
            bytes32 operationRoot,
            uint48 currentDepositID,
            uint256 currentWithdrawID
        )
    {
        currentDepositID = _currentDepositID;
        currentWithdrawID = _currentWithdrawID;

        bytes memory operationCommitment = new bytes(operationCommitmentLength);
        uint256 operationPtr = BitStream.getPtr(operationData);
        uint256 commitmentPtr = BitStream.getPtr(operationCommitment);
        uint256 operationPtrEnd = operationPtr + operationData.length;
        uint256 commitmentPtrEnd = commitmentPtr + operationCommitmentLength;
        while (operationPtr < operationPtrEnd) {
            // 1st 4 bit for OpcodeType
            OpType opType = OpType(BitStream.readBits(operationPtr, 0, 4));
            if (opType == OpType.Deposit || opType == OpType.DepositToNew) {
                require(operationPtr + DEPOSIT_BYTES_SIZE <= operationPtrEnd, "deposit bad data 1");
                require(commitmentPtr + OPERATION_COMMITMENT_SIZE <= commitmentPtrEnd, "deposit bad data 2");
                uint48 depositID = uint48(BitStream.readBits(operationPtr, 4, 44));
                require(depositID == currentDepositID, "roll-up unexpected depositID");
                bytes32 depositHash = depositHashes[depositID];
                currentDepositID++;
                // write commitment data and increase offset
                BitStream.writeBits(commitmentPtr, uint256(depositHash), 0, 256);
                operationPtr += DEPOSIT_BYTES_SIZE;
                commitmentPtr += OPERATION_COMMITMENT_SIZE;
            } else if (opType == OpType.Withdraw) {
                require(operationPtr + WITHDRAW_BYTES_SIZE <= operationPtrEnd, "withdraw bad data 1");
                require(commitmentPtr + OPERATION_COMMITMENT_SIZE <= commitmentPtrEnd, "deposit bad data 2");
                WithdrawRequest memory withdrawRequest;
                withdrawRequest.tokenID = uint16(BitStream.readBits(operationPtr, 4, 10));
                withdrawRequest.amountMantisa = uint32(BitStream.readBits(operationPtr + 2, 0, 32));
                withdrawRequest.amountExp = uint8(BitStream.readBits(operationPtr + 6, 0, 8));
                withdrawRequest.accountID = uint32(BitStream.readBits(operationPtr + 7, 0, 32));
                withdrawRequest.isCompleted = false;
                withdrawRequest.batchNumber = batchNumber;
                // // create withdraw request to onchain data;
                withdrawRequests[currentWithdrawID] = withdrawRequest;
                currentWithdrawID += 1;
                BitStream.copyBits(commitmentPtr, operationPtr, 0, 0, WITHDRAW_BYTES_SIZE * 8);
                operationPtr += WITHDRAW_BYTES_SIZE;
                commitmentPtr += OPERATION_COMMITMENT_SIZE;
            } else {
                // TODO: opType == OpType.Exit
                revert("invalid opcode");
            }
        }
        operationRoot = sha256(operationCommitment);
    }

    function handleTx(bytes memory txData, uint256 txCommitmentLength) internal pure returns (bytes32 txRoot) {
        bytes memory operationCommitment = new bytes(txCommitmentLength);
        uint256 txPtr = BitStream.getPtr(txData);
        uint256 commitmentPtr = BitStream.getPtr(operationCommitment);
        uint256 txPtrEnd = txPtr + txData.length;
        uint256 commitmentPtrEnd = commitmentPtr + txCommitmentLength;
        while (txPtr < txPtrEnd) {
            // 1st 4 bit for OpcodeType
            OpType opType = OpType(BitStream.readBits(txPtr, 0, 4));
            if (opType == OpType.Swap1 || opType == OpType.Swap2) {
                require(txPtr + SWAP_BYTES_SIZE <= txPtrEnd, "swap bad data 1");
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "swap bad data 2");
                BitStream.copyBits(commitmentPtr, txPtr, 0, 0, SWAP_BYTES_SIZE * 8);
                txPtr += SWAP_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else if (opType == OpType.AddLiquidity) {
                require(txPtr + ADD_LIQUIDITY_BYTES_SIZE <= txPtrEnd, "addLiquidity bad data 1");
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "addLiquidity bad data 2");
                BitStream.copyBits(commitmentPtr, txPtr, 0, 0, ADD_LIQUIDITY_BYTES_SIZE * 8);
                txPtr += ADD_LIQUIDITY_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else if (opType == OpType.RemoveLiquidity) {
                require(txPtr + REMOVE_LIQUIDITY_BYTES_SIZE <= txPtrEnd, "removeLiquidity bad data 1");
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "removeLiquidity bad data 2");
                BitStream.copyBits(commitmentPtr, txPtr, 0, 0, REMOVE_LIQUIDITY_BYTES_SIZE * 8);
                txPtr += REMOVE_LIQUIDITY_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else if (opType == OpType.NotSubmittedTx) {
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "not submited bad data");
                txPtr += NOT_SUBMITTED_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else {
                revert("invalid opcode");
            }
        }
        txRoot = sha256(operationCommitment);
    }

    function handleHiddenTx(bytes memory hiddenTxData, uint256 commitmentLength)
        internal
        pure
        returns (bytes32 hiddenTxRoot)
    {
        require(hiddenTxData.length % 32 == 0 && hiddenTxData.length < commitmentLength, "invalid hidden tx data 1");
        bytes memory commitment = new bytes(commitmentLength);
        uint256 dataPtr = BitStream.getPtr(hiddenTxData);
        uint256 commitmentPtr = BitStream.getPtr(commitment);
        uint256 dataPtrEnd = dataPtr + hiddenTxData.length;
        while (dataPtr < dataPtrEnd) {
            assembly {
                mstore(commitmentPtr, mload(dataPtr))
            }
            dataPtr += 32;
            commitmentPtr += 32;
        }
        hiddenTxRoot = sha256(commitment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.6.6;

contract PermissionGroups {
    uint256 internal constant MAX_GROUP_SIZE = 50;

    address public admin;
    address public pendingAdmin;
    mapping(address => bool) internal operators;
    mapping(address => bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    event OperatorAdded(address newOperator, bool isAdd);

    event AlerterAdded(address newAlerter, bool isAdd);

    constructor(address _admin) public {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender], "only alerter");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function getAlerters() external view returns (address[] memory) {
        return alertersGroup;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter], "alerter exists"); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE, "max alerters");

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter(address alerter) public onlyAdmin {
        require(alerters[alerter], "not alerter");
        alerters[alerter] = false;

        for (uint256 i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.pop();
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// source: https://github.com/CryptoManiacsZone/1inchProtocol/blob/591a0b4910567abd2f2fcbbf8b85fa3a089d5650/contracts/libraries/UniERC20.sol
library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function isETH(IERC20 token) internal pure returns (bool) {
        return token == ETH_ADDRESS;
    }

    function eq(IERC20 tokenA, IERC20 tokenB) internal pure returns (bool) {
        return (isETH(tokenA) && isETH(tokenB)) || (tokenA == tokenB);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "UniERC20: failed to transfer eth to target");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function uniTransferFromSender(
        IERC20 token,
        address target,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(msg.value >= amount, "UniERC20: not enough value");
            if (target != address(this)) {
                (bool success, ) = target.call{value: amount}("");
                require(success, "UniERC20: failed to transfer eth to target");
            }
            if (msg.value > amount) {
                // Return remainder if exist
                (bool success, ) = msg.sender.call{value: msg.value - amount}("");
                require(success, "UniERC20: failed to transfer back eth");
            }
        } else {
            token.safeTransferFrom(msg.sender, target, amount);
        }
    }

    function uniApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (isETH(token)) {
            return;
        }

        if (amount == 0) {
            token.safeApprove(to, 0);
            return;
        }

        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function uniDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 20000}(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{gas: 20000}(abi.encodeWithSignature("DECIMALS()"));
        }

        return success ? abi.decode(data, (uint8)) : 18;
    }

    function uniSymbol(IERC20 token) internal view returns (string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 20000}(abi.encodeWithSignature("symbol()"));
        if (!success) {
            (success, data) = address(token).staticcall{gas: 20000}(abi.encodeWithSignature("SYMBOL()"));
        }

        if (success && data.length >= 96) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && len <= 256) {
                return string(abi.decode(data, (bytes)));
            }
        }

        if (success && data.length == 32) {
            uint256 len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                len++;
            }

            if (len > 0) {
                bytes memory result = new bytes(len);
                for (uint256 i = 0; i < len; i++) {
                    result[i] = data[i];
                }
                return string(result);
            }
        }

        return _toHex(address(token));
    }

    function _toHex(address account) private pure returns (string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns (string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint256 j = 2;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 a = uint8(data[i]) >> 4;
            uint256 b = uint8(data[i]) & 0x0f;
            str[j++] = bytes1(uint8(a + 48 + (a / 10) * 39));
            str[j++] = bytes1(uint8(b + 48 + (b / 10) * 39));
        }

        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Tree {
    bytes32 public constant NULL_NODE = 0;

    function merkleBytes32Arr(bytes32[] memory miniBlockHashes) internal pure returns (bytes32) {
        uint256 size = miniBlockHashes.length;
        bytes32[] memory tmpMiniBlockHashes = miniBlockHashes;
        while (size != 1) {
            for (uint256 i = 0; i * 2 < size; i++) {
                if (i * 2 == size - 1) {
                    tmpMiniBlockHashes[i] = sha256(abi.encodePacked(tmpMiniBlockHashes[i * 2], NULL_NODE));
                } else {
                    tmpMiniBlockHashes[i] = sha256(
                        abi.encodePacked(tmpMiniBlockHashes[i * 2], tmpMiniBlockHashes[i * 2 + 1])
                    );
                }
            }
            size = (size + 1) / 2;
        }
        return tmpMiniBlockHashes[0];
    }
}

pragma solidity ^0.6.0;

/// @dev based on https://github.com/ethereum/solidity-examples/blob/master/src/bytes/Bytes.sol
library BitStream {
    uint256 internal constant WORD_SIZE = 256;

    /// @dev unsafe wrapper to get dataPtr
    function getPtr(bytes memory data) internal pure returns (uint256 dataPtr) {
        assembly {
            dataPtr := add(data, 32)
        }
    }

    /// @param self pointer to memory source to read
    /// @param offset number of bits is skipped
    /// @param len number of bit to read
    /// @dev this function suppose to use in memory <= 1 word
    function readBits(
        uint256 self,
        uint256 offset,
        uint256 len
    ) internal pure returns (uint256 out) {
        self += offset / 8;
        offset = offset % 8;
        require(len + offset <= WORD_SIZE, "too much bytes");
        uint256 endOffset = WORD_SIZE - offset - len;
        uint256 mask = ((1 << len) - 1) << (endOffset);
        assembly {
            out := and(mload(self), mask)
            out := shr(endOffset, out)
        }
    }

    /// @param self pointer to memory source to write
    /// @param data data to write
    /// @param offset number of bits is skipped
    /// @param len number of bit to write
    /// @dev this function suppose to use in memory <= 1 word
    function writeBits(
        uint256 self,
        uint256 data,
        uint256 offset,
        uint256 len
    ) internal pure {
        self += offset / 8;
        offset = offset % 8;
        require(len + offset <= WORD_SIZE, "too much bytes");
        uint256 endOffset = WORD_SIZE - offset - len;
        data = data << endOffset;
        uint256 mask = ((1 << len) - 1) << (endOffset);
        assembly {
            let destpart := and(mload(self), not(mask))
            mstore(self, or(destpart, data))
        }
    }

    function copyBits(
        uint256 self,
        uint256 src,
        uint256 srcOffset,
        uint256 dstOffset,
        uint256 len
    ) internal pure {
        uint256 data = readBits(src, srcOffset, len);
        writeBits(self, data, dstOffset, len);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ILayer2 {
    function getBatchRoot(uint256 batchNumber) external view returns (bytes32 batchRoot);

    function lastestBatch() external view returns (bytes32 batchRoot, uint256 batchNumber);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IZkVerifier {
    function verifyBlockProof(
        uint256[] calldata _proof,
        bytes32 _commitment,
        uint32 _chunks
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

import "../interface/IZkVerifier.sol";

import "./KeysWithPlonkVerifier.sol";

// Hardcoded constants to avoid accessing store
contract ZkVerifier is KeysWithPlonkVerifier, IZkVerifier {
    bool constant DUMMY_VERIFIER = false;

    function initialize(bytes calldata) external {}

    /// @notice Verifier contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    function isBlockSizeSupported(uint32 _size) public pure returns (bool) {
        if (DUMMY_VERIFIER) {
            return true;
        } else {
            return isBlockSizeSupportedInternal(_size);
        }
    }

    function verifyBlockProof(
        uint256[] calldata _proof,
        bytes32 _commitment,
        uint32 _chunks
    ) external override view returns (bool) {
        if (DUMMY_VERIFIER) {
            uint256 oldGasValue = gasleft();
            uint256 tmp;
            while (gasleft() + 470000 > oldGasValue) {
                tmp += 1;
            }
            return true;
        }
        uint256[] memory inputs = new uint256[](1);
        uint256 mask = (~uint256(0)) >> 3;
        inputs[0] = uint256(_commitment) & mask;
        Proof memory proof = deserialize_proof(inputs, _proof);
        VerificationKey memory vk = getVkBlock(_chunks);
        require(vk.num_inputs == inputs.length, "ZkVerifier: inputs length mismatch");
        return verify(proof, vk);
    }
}

pragma solidity >=0.5.0 <0.7.0;

import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {
    function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
        if (_size == uint32(192)) {
            return true;
        } else {
            return false;
        }
    }

    function getVkBlock(uint32 _chunks) internal pure returns (VerificationKey memory vk) {
        if (_chunks == uint32(192)) {
            return getVkBlock192();
        }
        revert("invalid chunks size");
    }

    function getVkBlock192() internal pure returns (VerificationKey memory vk) {
        vk.domain_size = 16777216;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x197d148d1daf98f7824d16d8fe3859ae1428eb9be9455a4cc346893393260620,
            0x2e170f046820bd1e35c61db1e36668a51e8ecec02cc54b776426955a44bc0141
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x1a94840d2e0a9296c4d2cc9615db884ada9d0d70e241214e177a0b945e56a67e,
            0x24a58bce1aaf83a21868db990d6a219f37b6e6307f83a8d018a3a6187bc92283
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x1b2599d6bc312f060709dfaedddc3e0dd66c3bef08ee42234bfa2bc25bcfd1d7,
            0x2296ea0020329f4fff00a1ae43b183d400ecbd44765b522063c7ce06053b6c35
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x015616cd34b165a6cddb1766b797bfaa01e914929a40cd93b39a504549d55b02,
            0x01a0b355205d6f2a946e849da556ef6c6722d9757137a020e60a8aa2ae87f664
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x0516b55d7246e2c0c3ca7f72f15a112c69b9cbd0f24b43083d5440c291b0f1d1,
            0x1756077d1d3d6186d7f09e81150db4f423540be89da7c70f8ccda434a857871c
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x1dee669383bd9ac977add09b68a222ecc982c98f6b5d6b09483a26fb65d1c695,
            0x158cff4caf37eb40a39cc04c9d7fd8ef3ffe45542078919a1c497a79a495c424
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1ef95abcff00652576225b8e47837a3307b7f41622099aa2b180c72fc8238c5a,
            0x16301b9d8681ece1bf49bc9e59762451a62d8fdf85b0ae62ddb9d0ac75210026
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1c311250d7e60ee2d1d3a130faa4f41c029fb99748a92f1888318b294ca1ae37,
            0x0c5df13e3b3454a0d9ecdcacd92d718f8c2fb68216a11f9c6f0e81937da023cd
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x17321464aa3b707c3c8aebd60b6568d4efd0d9186847f9e3fd32b3581e1ff183,
            0x0029784d6d86149651408aca524849c94de7476dd1fd09d421fbde6977a1ab0a
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x1cc31727c44e9af71ca492671f68b304507cc01d7501afb0863c594da3da5838,
            0x17669596e86f6c58bd93c77cab45f203cdf3b2c916e99c6d98b68212bb3d3e84
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x051acecc81eaac61ef05e6f443b7e7191a9d57a29d7bc5de8e4becee5949c3b3,
            0x2b2dba729476a4886f0fbda66242a4cba7a112e5c2b9a4c473863dfc3293b40c
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [
                0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
                0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0
            ],
            [
                0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
                0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55
            ]
        );
    }
}

pragma solidity >=0.5.0 <0.7.0;

library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod - 2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod);
        require(y < q_mod);
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs);

        return G1Point(x, y);
    }

    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return
            G2Point(
                [
                    0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                    0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
                ],
                [
                    0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                    0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
                ]
            );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_sub_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s) internal view returns (G1Point memory r) {
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s) internal view {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(
        G1Point memory p,
        Fr memory s,
        G1Point memory dest
    ) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

library TranscriptLibrary {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(abi.encodePacked(DST_0, old_state_0, self.state_1, value));
        self.state_1 = keccak256(abi.encodePacked(DST_1, old_state_0, self.state_1, value));
    }

    function update_with_fr(Transcript memory self, PairingsBn254.Fr memory value) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(Transcript memory self, PairingsBn254.G1Point memory p) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self) internal pure returns (PairingsBn254.Fr memory challenge) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state_0, self.state_1, self.challenge_counter));
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

contract Plonk4VerifierWithAccessToDNext {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[STATE_WIDTH + 2] selector_commitments; // STATE_WIDTH for witness + multiplication + constant
        PairingsBn254.G1Point[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] next_step_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH - 1] permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(uint256 domain_size, PairingsBn254.Fr memory at)
        internal
        view
        returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            rhs.add_assign(tmp);
        }

        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function reconstruct_d(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^(6..8) * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^9 (z(x) - z(z*omega)) <- we need this power
        // + v^10 * (d(x) - d(z*omega))
        // ]
        //
        // we pay a little for a few arithmetic operations to not introduce another constant
        uint256 power_for_z_omega_opening = 1 + 1 + STATE_WIDTH + STATE_WIDTH - 1;
        res = PairingsBn254.copy_g1(vk.selector_commitments[STATE_WIDTH + 1]);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.selector_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.selector_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.next_step_selector_commitments[0].point_mul(proof.wire_values_at_z_omega[0]);
        res.point_add_assign(tmp_g1);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(state.alpha);
        tmp_fr.mul_assign(state.alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        PairingsBn254.Fr memory grand_product_part_at_z_omega = state.v.pow(power_for_z_omega_opening);
        grand_product_part_at_z_omega.mul_assign(state.u);

        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(state.alpha);

        // add to the linearization
        tmp_g1 = proof.grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.permutation_commitments[STATE_WIDTH - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        res.point_mul_assign(state.v);

        res.point_add_assign(proof.grand_product_commitment.point_mul(grand_product_part_at_z_omega));
    }

    function verify_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.G1Point memory d = reconstruct_d(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(
            proof.quotient_poly_commitments[0]
        );
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        return PairingsBn254.pairingProd2(pair_with_generator, PairingsBn254.P2(), pair_with_x, vk.g2_x);
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        PartialVerifierState memory state;

        bool valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return false;
        }

        valid = verify_commitments(state, proof, vk);

        return valid;
    }
}

contract VerifierWithDeserialize is Plonk4VerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 33;

    function deserialize_proof(uint256[] memory public_inputs, uint256[] memory serialized_proof)
        internal
        pure
        returns (Proof memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.grand_product_commitment = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interface/IZkVerifier.sol";

contract MockVerifier is IZkVerifier {
    bool public result = true;

    function setResult(bool _result) external {
        result = _result;
    }

    function verifyBlockProof(
        uint256[] calldata, /* _proof */
        bytes32, /* _commitment */
        uint32 /* _chunks */
    ) external override view returns (bool) {
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "../libraries/Tree.sol";

contract MockTree {
    function merkleBytes32Arr(bytes32[] calldata miniBlockHashes) external pure returns (bytes32) {
        return Tree.merkleBytes32Arr(miniBlockHashes);
    }
}

