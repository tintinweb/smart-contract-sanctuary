// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

import "./lib/InstantWithdrawManager.sol";
import "./interfaces/VerifierRollupInterface.sol";
import "./interfaces/VerifierWithdrawInterface.sol";
import "../interfaces/IHermezAuctionProtocol.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Hermez is InstantWithdrawManager {
    struct VerifierRollup {
        VerifierRollupInterface verifierInterface;
        uint256 maxTx; // maximum rollup transactions in a batch: L2-tx + L1-tx transactions
        uint256 nLevels; // number of levels of the circuit
    }

    // ERC20 signatures:

    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant _TRANSFER_SIGNATURE = 0xa9059cbb;

    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant _TRANSFER_FROM_SIGNATURE = 0x23b872dd;

    // bytes4(keccak256(bytes("approve(address,uint256)")));
    bytes4 constant _APPROVE_SIGNATURE = 0x095ea7b3;

    // ERC20 extensions:

    // bytes4(keccak256(bytes("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)")));
    bytes4 constant _PERMIT_SIGNATURE = 0xd505accf;

    // First 256 indexes reserved, first user index will be the 256
    uint48 constant _RESERVED_IDX = 255;

    // IDX 1 is reserved for exits
    uint48 constant _EXIT_IDX = 1;

    // Max load amount allowed (loadAmount: L1 --> L2)
    uint256 constant _LIMIT_LOAD_AMOUNT = (1 << 128);

    // Max amount allowed (amount L2 --> L2)
    uint256 constant _LIMIT_L2TRANSFER_AMOUNT = (1 << 192);

    // Max number of tokens allowed to be registered inside the rollup
    uint256 constant _LIMIT_TOKENS = (1 << 32);

    // [65 bytes] compressedSignature + [32 bytes] fromBjj-compressed + [4 bytes] tokenId
    uint256 constant _L1_COORDINATOR_TOTALBYTES = 101;

    // [20 bytes] fromEthAddr + [32 bytes] fromBjj-compressed + [6 bytes] fromIdx +
    // [5 bytes] loadAmountFloat40 + [5 bytes] amountFloat40 + [4 bytes] tokenId + [6 bytes] toIdx
    uint256 constant _L1_USER_TOTALBYTES = 78;

    // User TXs are the TX made by the user with a L1 TX
    // Coordinator TXs are the L2 account creation made by the coordinator whose signature
    // needs to be verified in L1.
    // The maximum number of L1-user TXs and L1-coordinartor-TX is limited by the _MAX_L1_TX
    // And the maximum User TX is _MAX_L1_USER_TX

    // Maximum L1-user transactions allowed to be queued in a batch
    uint256 constant _MAX_L1_USER_TX = 128;

    // Maximum L1 transactions allowed to be queued in a batch
    uint256 constant _MAX_L1_TX = 256;

    // Modulus zkSNARK
    uint256 constant _RFIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // [6 bytes] lastIdx + [6 bytes] newLastIdx  + [32 bytes] stateRoot  + [32 bytes] newStRoot  + [32 bytes] newExitRoot +
    // [_MAX_L1_TX * _L1_USER_TOTALBYTES bytes] l1TxsData + totall1L2TxsDataLength + feeIdxCoordinatorLength + [2 bytes] chainID + [4 bytes] batchNum =
    // 18546 bytes + totall1L2TxsDataLength + feeIdxCoordinatorLength

    uint256 constant _INPUT_SHA_CONSTANT_BYTES = 20082;

    uint8 public constant ABSOLUTE_MAX_L1L2BATCHTIMEOUT = 240;

    // This ethereum address is used internally for rollup accounts that don't have ethereum address, only Babyjubjub
    // This non-ethereum accounts can be created by the coordinator and allow users to have a rollup
    // account without needing an ethereum address
    address constant _ETH_ADDRESS_INTERNAL_ONLY = address(
        0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
    );

    // Verifiers array
    VerifierRollup[] public rollupVerifiers;

    // Withdraw verifier interface
    VerifierWithdrawInterface public withdrawVerifier;

    // Last account index created inside the rollup
    uint48 public lastIdx;

    // Last batch forged
    uint32 public lastForgedBatch;

    // Each batch forged will have a correlated 'state root'
    mapping(uint32 => uint256) public stateRootMap;

    // Each batch forged will have a correlated 'exit tree' represented by the exit root
    mapping(uint32 => uint256) public exitRootsMap;

    // Each batch forged will have a correlated 'l1L2TxDataHash'
    mapping(uint32 => bytes32) public l1L2TxsDataHashMap;

    // Mapping of exit nullifiers, only allowing each withdrawal to be made once
    // rootId => (Idx => true/false)
    mapping(uint32 => mapping(uint48 => bool)) public exitNullifierMap;

    // List of ERC20 tokens that can be used in rollup
    // ID = 0 will be reserved for ether
    address[] public tokenList;

    // Mapping addres of the token, with the tokenID associated
    mapping(address => uint256) public tokenMap;

    // Fee for adding a new token to the rollup in HEZ tokens
    uint256 public feeAddToken;

    // Contract interface of the hermez auction
    IHermezAuctionProtocol public hermezAuctionContract;

    // Map of queues of L1-user-tx transactions, the transactions are stored in bytes32 sequentially
    // The coordinator is forced to forge the next queue in the next L1-L2-batch
    mapping(uint32 => bytes) public mapL1TxQueue;

    // Ethereum block where the last L1-L2-batch was forged
    uint64 public lastL1L2Batch;

    // Queue index that will be forged in the next L1-L2-batch
    uint32 public nextL1ToForgeQueue;

    // Queue index wich will be filled with the following L1-User-Tx
    uint32 public nextL1FillingQueue;

    // Max ethereum blocks after the last L1-L2-batch, when exceeds the timeout only L1-L2-batch are allowed
    uint8 public forgeL1L2BatchTimeout;

    // HEZ token address
    address public tokenHEZ;

    // Event emitted when a L1-user transaction is called and added to the nextL1FillingQueue queue
    event L1UserTxEvent(
        uint32 indexed queueIndex,
        uint8 indexed position, // Position inside the queue where the TX resides
        bytes l1UserTx
    );

    // Event emitted when a new token is added
    event AddToken(address indexed tokenAddress, uint32 tokenID);

    // Event emitted every time a batch is forged
    event ForgeBatch(uint32 indexed batchNum, uint16 l1UserTxsLen);

    // Event emitted when the governance update the `forgeL1L2BatchTimeout`
    event UpdateForgeL1L2BatchTimeout(uint8 newForgeL1L2BatchTimeout);

    // Event emitted when the governance update the `feeAddToken`
    event UpdateFeeAddToken(uint256 newFeeAddToken);

    // Event emitted when a withdrawal is done
    event WithdrawEvent(
        uint48 indexed idx,
        uint32 indexed numExitRoot,
        bool indexed instantWithdraw
    );

    // Event emitted when the contract is initialized
    event InitializeHermezEvent(
        uint8 forgeL1L2BatchTimeout,
        uint256 feeAddToken,
        uint64 withdrawalDelay
    );

    // Event emitted when the contract is updated to the new version
    event hermezV2();

    function updateVerifiers() external {
        require(
            msg.sender == address(0xb6D3f1056c015962fA66A4020E50522B58292D1E),
            "Hermez::updateVerifiers ONLY_DEPLOYER"
        );
        require(
            rollupVerifiers[0].maxTx == 344, // Old verifier 344 tx
            "Hermez::updateVerifiers VERIFIERS_ALREADY_UPDATED"
        );
        rollupVerifiers[0] = VerifierRollup({
            verifierInterface: VerifierRollupInterface(
                address(0x3DAa0B2a994b1BC60dB9e312aD0a8d87a1Bb16D2) // New verifier 400 tx
            ),
            maxTx: 400,
            nLevels: 32
        });

        rollupVerifiers[1] = VerifierRollup({
            verifierInterface: VerifierRollupInterface(
                address(0x1DC4b451DFcD0e848881eDE8c7A99978F00b1342) // New verifier 2048 tx
            ),
            maxTx: 2048,
            nLevels: 32
        });

        withdrawVerifier = VerifierWithdrawInterface(
            0x4464A1E499cf5443541da6728871af1D5C4920ca
        );
        emit hermezV2();
    }

    /**
     * @dev Initializer function (equivalent to the constructor). Since we use
     * upgradeable smartcontracts the state vars have to be initialized here.
     */
    function initializeHermez(
        address[] memory _verifiers,
        uint256[] memory _verifiersParams,
        address _withdrawVerifier,
        address _hermezAuctionContract,
        address _tokenHEZ,
        uint8 _forgeL1L2BatchTimeout,
        uint256 _feeAddToken,
        address _poseidon2Elements,
        address _poseidon3Elements,
        address _poseidon4Elements,
        address _hermezGovernanceAddress,
        uint64 _withdrawalDelay,
        address _withdrawDelayerContract
    ) external initializer {
        require(
            _hermezAuctionContract != address(0) &&
                _withdrawDelayerContract != address(0),
            "Hermez::initializeHermez ADDRESS_0_NOT_VALID"
        );

        // set state variables
        _initializeVerifiers(_verifiers, _verifiersParams);
        withdrawVerifier = VerifierWithdrawInterface(_withdrawVerifier);
        hermezAuctionContract = IHermezAuctionProtocol(_hermezAuctionContract);
        tokenHEZ = _tokenHEZ;
        forgeL1L2BatchTimeout = _forgeL1L2BatchTimeout;
        feeAddToken = _feeAddToken;

        // set default state variables
        lastIdx = _RESERVED_IDX;
        // lastL1L2Batch = 0 --> first batch forced to be L1Batch
        // nextL1ToForgeQueue = 0 --> First queue will be forged
        nextL1FillingQueue = 1;
        // stateRootMap[0] = 0 --> genesis batch will have root = 0
        tokenList.push(address(0)); // Token 0 is ETH

        // initialize libs
        _initializeHelpers(
            _poseidon2Elements,
            _poseidon3Elements,
            _poseidon4Elements
        );
        _initializeWithdraw(
            _hermezGovernanceAddress,
            _withdrawalDelay,
            _withdrawDelayerContract
        );
        emit InitializeHermezEvent(
            _forgeL1L2BatchTimeout,
            _feeAddToken,
            _withdrawalDelay
        );
    }

    //////////////
    // Coordinator operations
    /////////////

    /**
     * @dev Forge a new batch providing the L2 Transactions, L1Corrdinator transactions and the proof.
     * If the proof is succesfully verified, update the current state, adding a new state and exit root.
     * In order to optimize the gas consumption the parameters `encodedL1CoordinatorTx`, `l1L2TxsData` and `feeIdxCoordinator`
     * are read directly from the calldata using assembly with the instruction `calldatacopy`
     * @param newLastIdx New total rollup accounts
     * @param newStRoot New state root
     * @param newExitRoot New exit root
     * @param encodedL1CoordinatorTx Encoded L1-coordinator transactions
     * @param l1L2TxsData Encoded l2 data
     * @param feeIdxCoordinator Encoded idx accounts of the coordinator where the fees will be payed
     * @param verifierIdx Verifier index
     * @param l1Batch Indicates if this batch will be L2 or L1-L2
     * @param proofA zk-snark input
     * @param proofB zk-snark input
     * @param proofC zk-snark input
     * Events: `ForgeBatch`
     */
    function forgeBatch(
        uint48 newLastIdx,
        uint256 newStRoot,
        uint256 newExitRoot,
        bytes calldata encodedL1CoordinatorTx,
        bytes calldata l1L2TxsData,
        bytes calldata feeIdxCoordinator,
        uint8 verifierIdx,
        bool l1Batch,
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC
    ) external virtual {
        // Assure data availability from regular ethereum nodes
        // We include this line because it's easier to track the transaction data, as it will never be in an internal TX.
        // In general this makes no sense, as callling this function from another smart contract will have to pay the calldata twice.
        // But forcing, it avoids having to check.
        require(
            msg.sender == tx.origin,
            "Hermez::forgeBatch: INTENAL_TX_NOT_ALLOWED"
        );

        // ask the auction if this coordinator is allow to forge
        require(
            hermezAuctionContract.canForge(msg.sender, block.number) == true,
            "Hermez::forgeBatch: AUCTION_DENIED"
        );

        if (!l1Batch) {
            require(
                block.number < (lastL1L2Batch + forgeL1L2BatchTimeout), // No overflow since forgeL1L2BatchTimeout is an uint8
                "Hermez::forgeBatch: L1L2BATCH_REQUIRED"
            );
        }

        // calculate input
        uint256 input = _constructCircuitInput(
            newLastIdx,
            newStRoot,
            newExitRoot,
            l1Batch,
            verifierIdx
        );

        // verify proof
        require(
            rollupVerifiers[verifierIdx].verifierInterface.verifyProof(
                proofA,
                proofB,
                proofC,
                [input]
            ),
            "Hermez::forgeBatch: INVALID_PROOF"
        );

        // update state
        lastForgedBatch++;
        lastIdx = newLastIdx;
        stateRootMap[lastForgedBatch] = newStRoot;
        exitRootsMap[lastForgedBatch] = newExitRoot;
        l1L2TxsDataHashMap[lastForgedBatch] = sha256(l1L2TxsData);

        uint16 l1UserTxsLen;
        if (l1Batch) {
            // restart the timeout
            lastL1L2Batch = uint64(block.number);
            // clear current queue
            l1UserTxsLen = _clearQueue();
        }

        // auction must be aware that a batch is being forged
        hermezAuctionContract.forge(msg.sender);

        emit ForgeBatch(lastForgedBatch, l1UserTxsLen);
    }

    //////////////
    // User L1 rollup tx
    /////////////

    // This are all the possible L1-User transactions:
    // | fromIdx | toIdx | loadAmountF | amountF | tokenID(SC) | babyPubKey |           l1-user-TX            |
    // |:-------:|:-----:|:-----------:|:-------:|:-----------:|:----------:|:-------------------------------:|
    // |    0    |   0   |      0      |  0(SC)  |      X      |  !=0(SC)   |          createAccount          |
    // |    0    |   0   |     !=0     |  0(SC)  |      X      |  !=0(SC)   |      createAccountDeposit       |
    // |    0    | 255+  |      X      |    X    |      X      |  !=0(SC)   | createAccountDepositAndTransfer |
    // |  255+   |   0   |      X      |  0(SC)  |      X      |   0(SC)    |             Deposit             |
    // |  255+   |   1   |      0      |    X    |      X      |   0(SC)    |              Exit               |
    // |  255+   | 255+  |      0      |    X    |      X      |   0(SC)    |            Transfer             |
    // |  255+   | 255+  |     !=0     |    X    |      X      |   0(SC)    |       DepositAndTransfer        |
    // As can be seen in the table the type of transaction is determined basically by the "fromIdx" and "toIdx"
    // The 'X' means that can be any valid value and does not change the l1-user-tx type
    // Other parameters must be consistent, for example, if toIdx is 0, amountF must be 0, because there's no L2 transfer

    /**
     * @dev Create a new rollup l1 user transaction
     * @param babyPubKey Public key babyjubjub represented as point: sign + (Ay)
     * @param fromIdx Index leaf of sender account or 0 if create new account
     * @param loadAmountF Amount from L1 to L2 to sender account or new account
     * @param amountF Amount transfered between L2 accounts
     * @param tokenID Token identifier
     * @param toIdx Index leaf of recipient account, or _EXIT_IDX if exit, or 0 if not transfer
     * Events: `L1UserTxEvent`
     */
    function addL1Transaction(
        uint256 babyPubKey,
        uint48 fromIdx,
        uint40 loadAmountF,
        uint40 amountF,
        uint32 tokenID,
        uint48 toIdx,
        bytes calldata permit
    ) external payable {
        // check tokenID
        require(
            tokenID < tokenList.length,
            "Hermez::addL1Transaction: TOKEN_NOT_REGISTERED"
        );

        // check loadAmount
        uint256 loadAmount = _float2Fix(loadAmountF);
        require(
            loadAmount < _LIMIT_LOAD_AMOUNT,
            "Hermez::addL1Transaction: LOADAMOUNT_EXCEED_LIMIT"
        );

        // deposit token or ether
        if (loadAmount > 0) {
            if (tokenID == 0) {
                require(
                    loadAmount == msg.value,
                    "Hermez::addL1Transaction: LOADAMOUNT_ETH_DOES_NOT_MATCH"
                );
            } else {
                require(
                    msg.value == 0,
                    "Hermez::addL1Transaction: MSG_VALUE_NOT_EQUAL_0"
                );
                if (permit.length != 0) {
                    _permit(tokenList[tokenID], loadAmount, permit);
                }
                uint256 prevBalance = IERC20(tokenList[tokenID]).balanceOf(
                    address(this)
                );
                _safeTransferFrom(
                    tokenList[tokenID],
                    msg.sender,
                    address(this),
                    loadAmount
                );
                uint256 postBalance = IERC20(tokenList[tokenID]).balanceOf(
                    address(this)
                );
                require(
                    postBalance - prevBalance == loadAmount,
                    "Hermez::addL1Transaction: LOADAMOUNT_ERC20_DOES_NOT_MATCH"
                );
            }
        }

        // perform L1 User Tx
        _addL1Transaction(
            msg.sender,
            babyPubKey,
            fromIdx,
            loadAmountF,
            amountF,
            tokenID,
            toIdx
        );
    }

    /**
     * @dev Create a new rollup l1 user transaction
     * @param ethAddress Ethereum addres of the sender account or new account
     * @param babyPubKey Public key babyjubjub represented as point: sign + (Ay)
     * @param fromIdx Index leaf of sender account or 0 if create new account
     * @param loadAmountF Amount from L1 to L2 to sender account or new account
     * @param amountF Amount transfered between L2 accounts
     * @param tokenID Token identifier
     * @param toIdx Index leaf of recipient account, or _EXIT_IDX if exit, or 0 if not transfer
     * Events: `L1UserTxEvent`
     */
    function _addL1Transaction(
        address ethAddress,
        uint256 babyPubKey,
        uint48 fromIdx,
        uint40 loadAmountF,
        uint40 amountF,
        uint32 tokenID,
        uint48 toIdx
    ) internal {
        uint256 amount = _float2Fix(amountF);
        require(
            amount < _LIMIT_L2TRANSFER_AMOUNT,
            "Hermez::_addL1Transaction: AMOUNT_EXCEED_LIMIT"
        );

        // toIdx can be: 0, _EXIT_IDX or (toIdx > _RESERVED_IDX)
        if (toIdx == 0) {
            require(
                (amount == 0),
                "Hermez::_addL1Transaction: AMOUNT_MUST_BE_0_IF_NOT_TRANSFER"
            );
        } else {
            if ((toIdx == _EXIT_IDX)) {
                require(
                    (loadAmountF == 0),
                    "Hermez::_addL1Transaction: LOADAMOUNT_MUST_BE_0_IF_EXIT"
                );
            } else {
                require(
                    ((toIdx > _RESERVED_IDX) && (toIdx <= lastIdx)),
                    "Hermez::_addL1Transaction: INVALID_TOIDX"
                );
            }
        }
        // fromIdx can be: 0 if create account or (fromIdx > _RESERVED_IDX)
        if (fromIdx == 0) {
            require(
                babyPubKey != 0,
                "Hermez::_addL1Transaction: INVALID_CREATE_ACCOUNT_WITH_NO_BABYJUB"
            );
        } else {
            require(
                (fromIdx > _RESERVED_IDX) && (fromIdx <= lastIdx),
                "Hermez::_addL1Transaction: INVALID_FROMIDX"
            );
            require(
                babyPubKey == 0,
                "Hermez::_addL1Transaction: BABYJUB_MUST_BE_0_IF_NOT_CREATE_ACCOUNT"
            );
        }

        _l1QueueAddTx(
            ethAddress,
            babyPubKey,
            fromIdx,
            loadAmountF,
            amountF,
            tokenID,
            toIdx
        );
    }

    //////////////
    // User operations
    /////////////

    /**
     * @dev Withdraw to retrieve the tokens from the exit tree to the owner account
     * Before this call an exit transaction must be done
     * @param tokenID Token identifier
     * @param amount Amount to retrieve
     * @param babyPubKey Public key babyjubjub represented as point: sign + (Ay)
     * @param numExitRoot Batch number where the exit transaction has been done
     * @param siblings Siblings to demonstrate merkle tree proof
     * @param idx Index of the exit tree account
     * @param instantWithdraw true if is an instant withdraw
     * Events: `WithdrawEvent`
     */
    function withdrawMerkleProof(
        uint32 tokenID,
        uint192 amount,
        uint256 babyPubKey,
        uint32 numExitRoot,
        uint256[] memory siblings,
        uint48 idx,
        bool instantWithdraw
    ) external {
        // numExitRoot is not checked because an invalid numExitRoot will bring to a 0 root
        // and this is an empty tree.
        // in case of instant withdraw assure that is available
        if (instantWithdraw) {
            require(
                _processInstantWithdrawal(tokenList[tokenID], amount),
                "Hermez::withdrawMerkleProof: INSTANT_WITHDRAW_WASTED_FOR_THIS_USD_RANGE"
            );
        }

        // build 'key' and 'value' for exit tree
        uint256[4] memory arrayState = _buildTreeState(
            tokenID,
            0,
            amount,
            babyPubKey,
            msg.sender
        );
        uint256 stateHash = _hash4Elements(arrayState);
        // get exit root given its index depth
        uint256 exitRoot = exitRootsMap[numExitRoot];
        // check exit tree nullifier
        require(
            exitNullifierMap[numExitRoot][idx] == false,
            "Hermez::withdrawMerkleProof: WITHDRAW_ALREADY_DONE"
        );
        // check sparse merkle tree proof
        require(
            _smtVerifier(exitRoot, siblings, idx, stateHash) == true,
            "Hermez::withdrawMerkleProof: SMT_PROOF_INVALID"
        );

        // set nullifier
        exitNullifierMap[numExitRoot][idx] = true;

        _withdrawFunds(amount, tokenID, instantWithdraw);

        emit WithdrawEvent(idx, numExitRoot, instantWithdraw);
    }

    /**
     * @dev Withdraw to retrieve the tokens from the exit tree to the owner account
     * Before this call an exit transaction must be done
     * @param proofA zk-snark input
     * @param proofB zk-snark input
     * @param proofC zk-snark input
     * @param tokenID Token identifier
     * @param amount Amount to retrieve
     * @param numExitRoot Batch number where the exit transaction has been done
     * @param idx Index of the exit tree account
     * @param instantWithdraw true if is an instant withdraw
     * Events: `WithdrawEvent`
     */
    function withdrawCircuit(
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC,
        uint32 tokenID,
        uint192 amount,
        uint32 numExitRoot,
        uint48 idx,
        bool instantWithdraw
    ) external {
        // in case of instant withdraw assure that is available
        if (instantWithdraw) {
            require(
                _processInstantWithdrawal(tokenList[tokenID], amount),
                "Hermez::withdrawCircuit: INSTANT_WITHDRAW_WASTED_FOR_THIS_USD_RANGE"
            );
        }
        require(
            exitNullifierMap[numExitRoot][idx] == false,
            "Hermez::withdrawCircuit: WITHDRAW_ALREADY_DONE"
        );

        // get exit root given its index depth
        uint256 exitRoot = exitRootsMap[numExitRoot];

        uint256 input = uint256(
            sha256(abi.encodePacked(exitRoot, msg.sender, tokenID, amount, idx))
        ) % _RFIELD;
        // verify zk-snark circuit
        require(
            withdrawVerifier.verifyProof(proofA, proofB, proofC, [input]) ==
                true,
            "Hermez::withdrawCircuit: INVALID_ZK_PROOF"
        );

        // set nullifier
        exitNullifierMap[numExitRoot][idx] = true;

        _withdrawFunds(amount, tokenID, instantWithdraw);

        emit WithdrawEvent(idx, numExitRoot, instantWithdraw);
    }

    //////////////
    // Governance methods
    /////////////
    /**
     * @dev Update ForgeL1L2BatchTimeout
     * @param newForgeL1L2BatchTimeout New ForgeL1L2BatchTimeout
     * Events: `UpdateForgeL1L2BatchTimeout`
     */
    function updateForgeL1L2BatchTimeout(uint8 newForgeL1L2BatchTimeout)
        external
        onlyGovernance
    {
        require(
            newForgeL1L2BatchTimeout <= ABSOLUTE_MAX_L1L2BATCHTIMEOUT,
            "Hermez::updateForgeL1L2BatchTimeout: MAX_FORGETIMEOUT_EXCEED"
        );
        forgeL1L2BatchTimeout = newForgeL1L2BatchTimeout;
        emit UpdateForgeL1L2BatchTimeout(newForgeL1L2BatchTimeout);
    }

    /**
     * @dev Update feeAddToken
     * @param newFeeAddToken New feeAddToken
     * Events: `UpdateFeeAddToken`
     */
    function updateFeeAddToken(uint256 newFeeAddToken) external onlyGovernance {
        feeAddToken = newFeeAddToken;
        emit UpdateFeeAddToken(newFeeAddToken);
    }

    //////////////
    // Viewers
    /////////////

    /**
     * @dev Retrieve the number of tokens added in rollup
     * @return Number of tokens added in rollup
     */
    function registerTokensCount() public view returns (uint256) {
        return tokenList.length;
    }

    /**
     * @dev Retrieve the number of rollup verifiers
     * @return Number of verifiers
     */
    function rollupVerifiersLength() public view returns (uint256) {
        return rollupVerifiers.length;
    }

    //////////////
    // Internal/private methods
    /////////////

    /**
     * @dev Inclusion of a new token to the rollup
     * @param tokenAddress Smart contract token address
     * Events: `AddToken`
     */
    function addToken(address tokenAddress, bytes calldata permit) public {
        require(
            IERC20(tokenAddress).totalSupply() > 0,
            "Hermez::addToken: TOTAL_SUPPLY_ZERO"
        );
        uint256 currentTokens = tokenList.length;
        require(
            currentTokens < _LIMIT_TOKENS,
            "Hermez::addToken: TOKEN_LIST_FULL"
        );
        require(
            tokenAddress != address(0),
            "Hermez::addToken: ADDRESS_0_INVALID"
        );
        require(tokenMap[tokenAddress] == 0, "Hermez::addToken: ALREADY_ADDED");

        if (msg.sender != hermezGovernanceAddress) {
            // permit and transfer HEZ tokens
            if (permit.length != 0) {
                _permit(tokenHEZ, feeAddToken, permit);
            }
            _safeTransferFrom(
                tokenHEZ,
                msg.sender,
                hermezGovernanceAddress,
                feeAddToken
            );
        }

        tokenList.push(tokenAddress);
        tokenMap[tokenAddress] = currentTokens;

        emit AddToken(tokenAddress, uint32(currentTokens));
    }

    /**
     * @dev Initialize verifiers
     * @param _verifiers verifiers address array
     * @param _verifiersParams encoeded maxTx and nlevels of the verifier as follows:
     * [8 bits]nLevels || [248 bits] maxTx
     */
    function _initializeVerifiers(
        address[] memory _verifiers,
        uint256[] memory _verifiersParams
    ) internal {
        for (uint256 i = 0; i < _verifiers.length; i++) {
            rollupVerifiers.push(
                VerifierRollup({
                    verifierInterface: VerifierRollupInterface(_verifiers[i]),
                    maxTx: (_verifiersParams[i] << 8) >> 8,
                    nLevels: _verifiersParams[i] >> (256 - 8)
                })
            );
        }
    }

    /**
     * @dev Add L1-user-tx, add it to the correspoding queue
     * l1Tx L1-user-tx encoded in bytes as follows: [20 bytes] fromEthAddr || [32 bytes] fromBjj-compressed || [4 bytes] fromIdx ||
     * [5 bytes] loadAmountFloat40 || [5 bytes] amountFloat40 || [4 bytes] tokenId || [4 bytes] toIdx
     * @param ethAddress Ethereum address of the rollup account
     * @param babyPubKey Public key babyjubjub represented as point: sign + (Ay)
     * @param fromIdx Index account of the sender account
     * @param loadAmountF Amount from L1 to L2
     * @param amountF  Amount transfered between L2 accounts
     * @param tokenID  Token identifier
     * @param toIdx Index leaf of recipient account
     * Events: `L1UserTxEvent`
     */
    function _l1QueueAddTx(
        address ethAddress,
        uint256 babyPubKey,
        uint48 fromIdx,
        uint40 loadAmountF,
        uint40 amountF,
        uint32 tokenID,
        uint48 toIdx
    ) internal {
        bytes memory l1Tx = abi.encodePacked(
            ethAddress,
            babyPubKey,
            fromIdx,
            loadAmountF,
            amountF,
            tokenID,
            toIdx
        );

        uint256 currentPosition = mapL1TxQueue[nextL1FillingQueue].length /
            _L1_USER_TOTALBYTES;

        // concatenate storage byte array with the new l1Tx
        _concatStorage(mapL1TxQueue[nextL1FillingQueue], l1Tx);

        emit L1UserTxEvent(nextL1FillingQueue, uint8(currentPosition), l1Tx);
        if (currentPosition + 1 >= _MAX_L1_USER_TX) {
            nextL1FillingQueue++;
        }
    }

    /**
     * @dev return the current L1-user-tx queue adding the L1-coordinator-tx
     * @param ptr Ptr where L1 data is set
     * @param l1Batch if true, the include l1TXs from the queue
     * [1 byte] V(ecdsa signature) || [32 bytes] S(ecdsa signature) ||
     * [32 bytes] R(ecdsa signature) || [32 bytes] fromBjj-compressed || [4 bytes] tokenId
     */
    function _buildL1Data(uint256 ptr, bool l1Batch) internal view {
        uint256 dPtr;
        uint256 dLen;

        (dPtr, dLen) = _getCallData(3);
        uint256 l1CoordinatorLength = dLen / _L1_COORDINATOR_TOTALBYTES;

        uint256 l1UserLength;
        bytes memory l1UserTxQueue;
        if (l1Batch) {
            l1UserTxQueue = mapL1TxQueue[nextL1ToForgeQueue];
            l1UserLength = l1UserTxQueue.length / _L1_USER_TOTALBYTES;
        } else {
            l1UserLength = 0;
        }

        require(
            l1UserLength + l1CoordinatorLength <= _MAX_L1_TX,
            "Hermez::_buildL1Data: L1_TX_OVERFLOW"
        );

        if (l1UserLength > 0) {
            // Copy the queue to the ptr and update ptr
            assembly {
                let ptrFrom := add(l1UserTxQueue, 0x20)
                let ptrTo := ptr
                ptr := add(ptr, mul(l1UserLength, _L1_USER_TOTALBYTES))
                for {

                } lt(ptrTo, ptr) {
                    ptrTo := add(ptrTo, 32)
                    ptrFrom := add(ptrFrom, 32)
                } {
                    mstore(ptrTo, mload(ptrFrom))
                }
            }
        }

        for (uint256 i = 0; i < l1CoordinatorLength; i++) {
            uint8 v; // L1-Coordinator-Tx bytes[0]
            bytes32 s; // L1-Coordinator-Tx bytes[1:32]
            bytes32 r; // L1-Coordinator-Tx bytes[33:64]
            bytes32 babyPubKey; // L1-Coordinator-Tx bytes[65:96]
            uint256 tokenID; // L1-Coordinator-Tx bytes[97:100]

            assembly {
                v := byte(0, calldataload(dPtr))
                dPtr := add(dPtr, 1)

                s := calldataload(dPtr)
                dPtr := add(dPtr, 32)

                r := calldataload(dPtr)
                dPtr := add(dPtr, 32)

                babyPubKey := calldataload(dPtr)
                dPtr := add(dPtr, 32)

                tokenID := shr(224, calldataload(dPtr)) // 256-32 = 224
                dPtr := add(dPtr, 4)
            }

            require(
                tokenID < tokenList.length,
                "Hermez::_buildL1Data: TOKEN_NOT_REGISTERED"
            );

            address ethAddress = _ETH_ADDRESS_INTERNAL_ONLY;

            // v must be >=27 --> EIP-155, v == 0 means no signature
            if (v != 0) {
                ethAddress = _checkSig(babyPubKey, r, s, v);
            }

            // add L1-Coordinator-Tx to the L1-tx queue
            assembly {
                mstore(ptr, shl(96, ethAddress)) // 256 - 160 = 96, write ethAddress: bytes[0:19]
                ptr := add(ptr, 20)

                mstore(ptr, babyPubKey) // write babyPubKey: bytes[20:51]
                ptr := add(ptr, 32)

                mstore(ptr, 0) // write zeros
                // [6 Bytes] fromIdx ,
                // [5 bytes] loadAmountFloat40 .
                // [5 bytes] amountFloat40
                ptr := add(ptr, 16)

                mstore(ptr, shl(224, tokenID)) // 256 - 32 = 224 write tokenID: bytes[62:65]
                ptr := add(ptr, 4)

                mstore(ptr, 0) // write [6 Bytes] toIdx
                ptr := add(ptr, 6)
            }
        }

        _fillZeros(
            ptr,
            (_MAX_L1_TX - l1UserLength - l1CoordinatorLength) *
                _L1_USER_TOTALBYTES
        );
    }

    /**
     * @dev Calculate the circuit input hashing all the elements
     * @param newLastIdx New total rollup accounts
     * @param newStRoot New state root
     * @param newExitRoot New exit root
     * @param l1Batch Indicates if this forge will be L2 or L1-L2
     * @param verifierIdx Verifier index
     */
    function _constructCircuitInput(
        uint48 newLastIdx,
        uint256 newStRoot,
        uint256 newExitRoot,
        bool l1Batch,
        uint8 verifierIdx
    ) internal view returns (uint256) {
        uint256 oldStRoot = stateRootMap[lastForgedBatch];
        uint256 oldLastIdx = lastIdx;
        uint256 dPtr; // Pointer to the calldata parameter data
        uint256 dLen; // Length of the calldata parameter

        // l1L2TxsData = l2Bytes * maxTx =
        // ([(nLevels / 8) bytes] fromIdx + [(nLevels / 8) bytes] toIdx + [5 bytes] amountFloat40 + [1 bytes] fee) * maxTx =
        // ((nLevels / 4) bytes + 3 bytes) * maxTx
        uint256 l1L2TxsDataLength = ((rollupVerifiers[verifierIdx].nLevels /
            8) *
            2 +
            5 +
            1) * rollupVerifiers[verifierIdx].maxTx;

        // [(nLevels / 8) bytes]
        uint256 feeIdxCoordinatorLength = (rollupVerifiers[verifierIdx]
            .nLevels / 8) * 64;

        // the concatenation of all arguments could be done with abi.encodePacked(args), but is suboptimal, especially with a large bytes arrays
        // [6 bytes] lastIdx +
        // [6 bytes] newLastIdx  +
        // [32 bytes] stateRoot  +
        // [32 bytes] newStRoot  +
        // [32 bytes] newExitRoot +
        // [_MAX_L1_TX * _L1_USER_TOTALBYTES bytes] l1TxsData +
        // totall1L2TxsDataLength +
        // feeIdxCoordinatorLength +
        // [2 bytes] chainID +
        // [4 bytes] batchNum =
        // _INPUT_SHA_CONSTANT_BYTES bytes +  totall1L2TxsDataLength + feeIdxCoordinatorLength
        bytes memory inputBytes;

        uint256 ptr; // Position for writing the bufftr

        assembly {
            let inputBytesLength := add(
                add(_INPUT_SHA_CONSTANT_BYTES, l1L2TxsDataLength),
                feeIdxCoordinatorLength
            )

            // Set inputBytes to the next free memory space
            inputBytes := mload(0x40)
            // Reserve the memory. 32 for the length , the input bytes and 32
            // extra bytes at the end for word manipulation
            mstore(0x40, add(add(inputBytes, 0x40), inputBytesLength))

            // Set the actua length of the input bytes
            mstore(inputBytes, inputBytesLength)

            // Set The Ptr at the begining of the inputPubber
            ptr := add(inputBytes, 32)

            mstore(ptr, shl(208, oldLastIdx)) // 256-48 = 208
            ptr := add(ptr, 6)

            mstore(ptr, shl(208, newLastIdx)) // 256-48 = 208
            ptr := add(ptr, 6)

            mstore(ptr, oldStRoot)
            ptr := add(ptr, 32)

            mstore(ptr, newStRoot)
            ptr := add(ptr, 32)

            mstore(ptr, newExitRoot)
            ptr := add(ptr, 32)
        }

        // Copy the L1TX Data
        _buildL1Data(ptr, l1Batch);
        ptr += _MAX_L1_TX * _L1_USER_TOTALBYTES;

        // Copy the L2 TX Data from calldata
        (dPtr, dLen) = _getCallData(4);
        require(
            dLen <= l1L2TxsDataLength,
            "Hermez::_constructCircuitInput: L2_TX_OVERFLOW"
        );
        assembly {
            calldatacopy(ptr, dPtr, dLen)
        }
        ptr += dLen;

        // L2 TX unused data is padded with 0 at the end
        _fillZeros(ptr, l1L2TxsDataLength - dLen);
        ptr += l1L2TxsDataLength - dLen;

        // Copy the FeeIdxCoordinator from the calldata
        (dPtr, dLen) = _getCallData(5);
        require(
            dLen <= feeIdxCoordinatorLength,
            "Hermez::_constructCircuitInput: INVALID_FEEIDXCOORDINATOR_LENGTH"
        );
        assembly {
            calldatacopy(ptr, dPtr, dLen)
        }
        ptr += dLen;
        _fillZeros(ptr, feeIdxCoordinatorLength - dLen);
        ptr += feeIdxCoordinatorLength - dLen;

        // store 2 bytes of chainID at the end of the inputBytes
        assembly {
            mstore(ptr, shl(240, chainid())) // 256 - 16 = 240
        }
        ptr += 2;

        uint256 batchNum = lastForgedBatch + 1;

        // store 4 bytes of batch number at the end of the inputBytes
        assembly {
            mstore(ptr, shl(224, batchNum)) // 256 - 32 = 224
        }

        return uint256(sha256(inputBytes)) % _RFIELD;
    }

    /**
     * @dev Clear the current queue, and update the `nextL1ToForgeQueue` and `nextL1FillingQueue` if needed
     */
    function _clearQueue() internal returns (uint16) {
        uint16 l1UserTxsLen = uint16(
            mapL1TxQueue[nextL1ToForgeQueue].length / _L1_USER_TOTALBYTES
        );
        delete mapL1TxQueue[nextL1ToForgeQueue];
        nextL1ToForgeQueue++;
        if (nextL1ToForgeQueue == nextL1FillingQueue) {
            nextL1FillingQueue++;
        }
        return l1UserTxsLen;
    }

    /**
     * @dev Withdraw the funds to the msg.sender if instant withdraw or to the withdraw delayer if delayed
     * @param amount Amount to retrieve
     * @param tokenID Token identifier
     * @param instantWithdraw true if is an instant withdraw
     */
    function _withdrawFunds(
        uint192 amount,
        uint32 tokenID,
        bool instantWithdraw
    ) internal {
        if (instantWithdraw) {
            _safeTransfer(tokenList[tokenID], msg.sender, amount);
        } else {
            if (tokenID == 0) {
                withdrawDelayerContract.deposit{value: amount}(
                    msg.sender,
                    address(0),
                    amount
                );
            } else {
                address tokenAddress = tokenList[tokenID];

                _safeApprove(
                    tokenAddress,
                    address(withdrawDelayerContract),
                    amount
                );

                withdrawDelayerContract.deposit(
                    msg.sender,
                    tokenAddress,
                    amount
                );
            }
        }
    }

    ///////////
    // helpers ERC20 functions
    ///////////

    /**
     * @dev Approve ERC20
     * @param token Token address
     * @param to Recievers
     * @param value Quantity of tokens to approve
     */
    function _safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        /* solhint-disable avoid-low-level-calls */
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(_APPROVE_SIGNATURE, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Hermez::_safeApprove: ERC20_APPROVE_FAILED"
        );
    }

    /**
     * @dev Transfer tokens or ether from the smart contract
     * @param token Token address
     * @param to Address to recieve the tokens
     * @param value Quantity to transfer
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // address 0 is reserved for eth
        if (token == address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = msg.sender.call{value: value}(new bytes(0));
            require(success, "Hermez::_safeTransfer: ETH_TRANSFER_FAILED");
        } else {
            /* solhint-disable avoid-low-level-calls */
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(_TRANSFER_SIGNATURE, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "Hermez::_safeTransfer: ERC20_TRANSFER_FAILED"
            );
        }
    }

    /**
     * @dev transferFrom ERC20
     * Require approve tokens for this contract previously
     * @param token Token address
     * @param from Sender
     * @param to Reciever
     * @param value Quantity of tokens to send
     */
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(_TRANSFER_FROM_SIGNATURE, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Hermez::_safeTransferFrom: ERC20_TRANSFERFROM_FAILED"
        );
    }

    ///////////
    // helpers ERC20 extension functions
    ///////////

    /**
     * @notice Function to call token permit method of extended ERC20
     * @param _amount Quantity that is expected to be allowed
     * @param _permitData Raw data of the call `permit` of the token
     */
    function _permit(
        address token,
        uint256 _amount,
        bytes calldata _permitData
    ) internal {
        bytes4 sig = abi.decode(_permitData, (bytes4));
        require(
            sig == _PERMIT_SIGNATURE,
            "HermezAuctionProtocol::_permit: NOT_VALID_CALL"
        );
        (
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
            _permitData[4:],
            (address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        require(
            owner == msg.sender,
            "Hermez::_permit: PERMIT_OWNER_MUST_BE_THE_SENDER"
        );
        require(
            spender == address(this),
            "Hermez::_permit: SPENDER_MUST_BE_THIS"
        );
        require(
            value == _amount,
            "Hermez::_permit: PERMIT_AMOUNT_DOES_NOT_MATCH"
        );

        // we call without checking the result, in case it fails and he doesn't have enough balance
        // the following transferFrom should be fail. This prevents DoS attacks from using a signature
        // before the smartcontract call
        /* solhint-disable avoid-low-level-calls */
        address(token).call(
            abi.encodeWithSelector(
                _PERMIT_SIGNATURE,
                owner,
                spender,
                value,
                deadline,
                v,
                r,
                s
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

import "../../interfaces/IWithdrawalDelayer.sol";
import "./HermezHelpers.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


contract InstantWithdrawManager is HermezHelpers {
    using SafeMath for uint256;


    // Number of buckets
    uint256 private constant _MAX_BUCKETS = 5;

    // Bucket array
    uint256 public nBuckets;
    mapping (int256 => uint256) public buckets;

    // Governance address
    address public hermezGovernanceAddress;

    // Withdraw delay in seconds
    uint64 public withdrawalDelay;

    // ERC20 decimals signature
    //  bytes4(keccak256(bytes("decimals()")))
    bytes4 private constant _ERC20_DECIMALS = 0x313ce567;

    uint256 private constant _MAX_WITHDRAWAL_DELAY = 2 weeks;

    // Withdraw delayer interface
    IWithdrawalDelayer public withdrawDelayerContract;

    // Mapping tokenAddress --> (USD value)/token , default 0, means that token does not worth
    // 2^64 = 1.8446744e+19
    // fixed point codification is used, 9 digits for integer part, 10 digits for decimal
    // In other words, the USD value of a token base unit is multiplied by 1e10
    // MaxUSD value for a base unit token: 1844674407,3709551616$
    // MinUSD value for a base unit token: 1e-10$
    mapping(address => uint64) public tokenExchange;

    uint256 private constant _EXCHANGE_MULTIPLIER = 1e10;

    event UpdateBucketWithdraw(
        uint8 indexed numBucket,
        uint256 indexed blockStamp,
        uint256 withdrawals
    );

    event UpdateWithdrawalDelay(uint64 newWithdrawalDelay);
    event UpdateBucketsParameters(uint256[] arrayBuckets);
    event UpdateTokenExchange(address[] addressArray, uint64[] valueArray);
    event SafeMode();

    function _initializeWithdraw(
        address _hermezGovernanceAddress,
        uint64 _withdrawalDelay,
        address _withdrawDelayerContract
    ) internal initializer {
        hermezGovernanceAddress = _hermezGovernanceAddress;
        withdrawalDelay = _withdrawalDelay;
        withdrawDelayerContract = IWithdrawalDelayer(_withdrawDelayerContract);
    }

    modifier onlyGovernance {
        require(
            msg.sender == hermezGovernanceAddress,
            "InstantWithdrawManager::onlyGovernance: ONLY_GOVERNANCE_ADDRESS"
        );
        _;
    }

    /**
     * @dev Attempt to use instant withdraw
     * @param tokenAddress Token address
     * @param amount Amount to withdraw
     */
    function _processInstantWithdrawal(address tokenAddress, uint192 amount)
        internal
        returns (bool)
    {
        // find amount in USD and then the corresponding bucketIdx
        uint256 amountUSD = _token2USD(tokenAddress, amount);

        if (amountUSD == 0) {
            return true;
        }

        // find the appropiate bucketId
        int256 bucketIdx = _findBucketIdx(amountUSD);
        if (bucketIdx == -1) return true;

        (uint256 ceilUSD, uint256 blockStamp, uint256 withdrawals, uint256 rateBlocks, uint256 rateWithdrawals, uint256 maxWithdrawals) = unpackBucket(buckets[bucketIdx]);

        // update the bucket and check again if are withdrawals available
        uint256 differenceBlocks = block.number.sub(blockStamp);
        uint256 periods = differenceBlocks.div(rateBlocks);

        // add the withdrawals available
        withdrawals = withdrawals.add(periods.mul(rateWithdrawals));
        if (withdrawals >= maxWithdrawals) {
            withdrawals = maxWithdrawals;
            blockStamp = block.number;
        } else {
            blockStamp = blockStamp.add(periods.mul(rateBlocks));
        }

        if (withdrawals == 0) return false;

        withdrawals = withdrawals.sub(1);

        // update the bucket with the new values
        buckets[bucketIdx] = packBucket(ceilUSD, blockStamp, withdrawals, rateBlocks, rateWithdrawals, maxWithdrawals);

        emit UpdateBucketWithdraw(uint8(bucketIdx), blockStamp, withdrawals);
        return true;
    }

    /**
     * @dev Update bucket parameters
     * @param newBuckets Array of buckets to replace the current ones, this array includes the
     * following parameters: [ceilUSD, withdrawals, rateBlocks, rateWithdrawals, maxWithdrawals]
     */
    function updateBucketsParameters(
        uint256[] memory newBuckets
    ) external onlyGovernance {
        uint256 n = newBuckets.length;
        require(
            n <= _MAX_BUCKETS,
            "InstantWithdrawManager::updateBucketsParameters: MAX_NUM_BUCKETS"
        );

        nBuckets = n;
        for (uint256 i = 0; i < n; i++) {
            (uint256 ceilUSD, , uint256 withdrawals, uint256 rateBlocks, uint256 rateWithdrawals, uint256 maxWithdrawals) = unpackBucket(newBuckets[i]);
            require(
                withdrawals <= maxWithdrawals,
                "InstantWithdrawManager::updateBucketsParameters: WITHDRAWALS_MUST_BE_LESS_THAN_MAXWITHDRAWALS"
            );
            require(
                rateBlocks > 0,
                "InstantWithdrawManager::updateBucketsParameters: RATE_BLOCKS_MUST_BE_MORE_THAN_0"
            );
            buckets[int256(i)] = packBucket(
                ceilUSD,
                block.number,
                withdrawals,
                rateBlocks,
                rateWithdrawals,
                maxWithdrawals
            );
        }
        emit UpdateBucketsParameters(newBuckets);
    }

    /**
     * @dev Update token USD value
     * @param addressArray Array of the token address
     * @param valueArray Array of USD values
     */
    function updateTokenExchange(
        address[] memory addressArray,
        uint64[] memory valueArray
    ) external onlyGovernance {
        require(
            addressArray.length == valueArray.length,
            "InstantWithdrawManager::updateTokenExchange: INVALID_ARRAY_LENGTH"
        );
        for (uint256 i = 0; i < addressArray.length; i++) {
            tokenExchange[addressArray[i]] = valueArray[i];
        }
        emit UpdateTokenExchange(addressArray, valueArray);
    }

    /**
     * @dev Update WithdrawalDelay
     * @param newWithdrawalDelay New WithdrawalDelay
     * Events: `UpdateWithdrawalDelay`
     */
    function updateWithdrawalDelay(uint64 newWithdrawalDelay)
        external
        onlyGovernance
    {
        require(
            newWithdrawalDelay <= _MAX_WITHDRAWAL_DELAY,
            "InstantWithdrawManager::updateWithdrawalDelay: EXCEED_MAX_WITHDRAWAL_DELAY"
        );
        withdrawalDelay = newWithdrawalDelay;
        emit UpdateWithdrawalDelay(newWithdrawalDelay);
    }

    /**
     * @dev Put the smartcontract in safe mode, only delayed withdrawals allowed,
     * also update the 'withdrawalDelay' of the 'withdrawDelayer' contract
     */
    function safeMode() external onlyGovernance {
        // only 1 bucket that does not allow any instant withdraw
        nBuckets = 1;
        buckets[0] = packBucket(
            0xFFFFFFFF_FFFFFFFF_FFFFFFFF,
            0,
            0,
            1,
            0,
            0
        );
        withdrawDelayerContract.changeWithdrawalDelay(withdrawalDelay);
        emit SafeMode();
    }

    /**
     * @dev Return true if a instant withdraw could be done with that 'tokenAddress' and 'amount'
     * @param tokenAddress Token address
     * @param amount Amount to withdraw
     * @return true if the instant withdrawal is allowed
     */
    function instantWithdrawalViewer(address tokenAddress, uint192 amount)
        public
        view
        returns (bool)
    {
        // find amount in USD and then the corresponding bucketIdx
        uint256 amountUSD = _token2USD(tokenAddress, amount);
        if (amountUSD == 0) return true;

        int256 bucketIdx = _findBucketIdx(amountUSD);
        if (bucketIdx == -1) return true;


        (, uint256 blockStamp, uint256 withdrawals, uint256 rateBlocks, uint256 rateWithdrawals, uint256 maxWithdrawals) = unpackBucket(buckets[bucketIdx]);

        uint256 differenceBlocks = block.number.sub(blockStamp);
        uint256 periods = differenceBlocks.div(rateBlocks);

        withdrawals = withdrawals.add(periods.mul(rateWithdrawals));
        if (withdrawals>maxWithdrawals) withdrawals = maxWithdrawals;

        if (withdrawals == 0) return false;

        return true;
    }

    /**
     * @dev Converts tokens to USD
     * @param tokenAddress Token address
     * @param amount Token amount
     * @return Total USD amount
     */
    function _token2USD(address tokenAddress, uint192 amount)
        internal
        view
        returns (uint256)
    {
        if (tokenExchange[tokenAddress] == 0) return 0;

        // this multiplication never overflows 192bits * 64 bits
        uint256 baseUnitTokenUSD = (uint256(amount) *
            uint256(tokenExchange[tokenAddress])) / _EXCHANGE_MULTIPLIER;

        uint8 decimals;
        // in case of ether, set 18 decimals
        if (tokenAddress == address(0)) {
            decimals = 18;
        } else {
            // if decimals() is not implemented 0 decimals are assumed
            (bool success, bytes memory data) = tokenAddress.staticcall(
                abi.encodeWithSelector(_ERC20_DECIMALS)
            );
            if (success) {
                decimals = abi.decode(data, (uint8));
            }
        }
        require(
            decimals < 77,
            "InstantWithdrawManager::_token2USD: TOKEN_DECIMALS_OVERFLOW"
        );
        return baseUnitTokenUSD / (10**uint256(decimals));
    }

    /**
     * @dev Find the corresponding bucket for the input amount
     * @param amountUSD USD amount
     * @return Bucket index, -1 in case there is no match
     */
    function _findBucketIdx(uint256 amountUSD) internal view returns (int256) {
        for (int256 i = 0; i < int256(nBuckets); i++) {
            uint256 ceilUSD = buckets[i] & 0xFFFFFFFF_FFFFFFFF_FFFFFFFF;
            if ((amountUSD <= ceilUSD) ||
                (ceilUSD == 0xFFFFFFFF_FFFFFFFF_FFFFFFFF))
            {
                return i;
            }
        }
        return -1;
    }

     /**
     * @dev Unpack a packed uint256 into the bucket parameters
     * @param bucket Token address
     * @return ceilUSD max USD value that bucket holds
     * @return blockStamp block number of the last bucket update
     * @return withdrawals available withdrawals of the bucket
     * @return rateBlocks every `rateBlocks` blocks add `rateWithdrawals` withdrawal
     * @return rateWithdrawals add `rateWithdrawals` every `rateBlocks`
     * @return maxWithdrawals max withdrawals the bucket can hold
     */
    function unpackBucket(uint256 bucket) public pure returns(
        uint256 ceilUSD,
        uint256 blockStamp,
        uint256 withdrawals,
        uint256 rateBlocks,
        uint256 rateWithdrawals,
        uint256 maxWithdrawals
    ) {
        ceilUSD = bucket & 0xFFFFFFFF_FFFFFFFF_FFFFFFFF;
        blockStamp = (bucket >> 96) & 0xFFFFFFFF;
        withdrawals = (bucket >> 128) & 0xFFFFFFFF;
        rateBlocks = (bucket >> 160) & 0xFFFFFFFF;
        rateWithdrawals = (bucket >> 192) & 0xFFFFFFFF;
        maxWithdrawals = (bucket >> 224) & 0xFFFFFFFF;
    }

     /**
     * @dev Pack all the bucket parameters into a uint256
     * @param ceilUSD max USD value that bucket holds
     * @param blockStamp block number of the last bucket update
     * @param withdrawals available withdrawals of the bucket
     * @param rateBlocks every `rateBlocks` blocks add `rateWithdrawals` withdrawal
     * @param rateWithdrawals add `rateWithdrawals` every `rateBlocks`
     * @param maxWithdrawals max withdrawals the bucket can hold
     * @return ret all bucket varaibles packed [ceilUSD, blockStamp, withdrawals, rateBlocks, rateWithdrawals, maxWithdrawals]
     */
    function packBucket(
        uint256 ceilUSD,
        uint256 blockStamp,
        uint256 withdrawals,
        uint256 rateBlocks,
        uint256 rateWithdrawals,
        uint256 maxWithdrawals
    ) public pure returns(uint256 ret) {
        ret = ceilUSD |
              (blockStamp << 96) |
              (withdrawals << 128) |
              (rateBlocks << 160) |
              (rateWithdrawals << 192) |
              (maxWithdrawals << 224);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Define interface verifier
 */
interface VerifierRollupInterface {
    function verifyProof(
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC,
        uint256[1] calldata input
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Define interface verifier
 */
interface VerifierWithdrawInterface {
    function verifyProof(
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC,
        uint256[1] calldata input
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

/**
 * @dev Hermez will run an auction to incentivise efficiency in coordinators,
 * meaning that they need to be very effective and include as many transactions
 * as they can in the slots in order to compensate for their bidding costs, gas
 * costs and operations costs.The general porpouse of this smartcontract is to
 * define the rules to coordinate this auction where the bids will be placed
 * only in HEZ utility token.
 */
interface IHermezAuctionProtocol {
    /**
     * @notice Getter of the current `_slotDeadline`
     * @return The `_slotDeadline` value
     */
    function getSlotDeadline() external view returns (uint8);

    /**
     * @notice Allows to change the `_slotDeadline` if it's called by the owner
     * @param newDeadline new `_slotDeadline`
     * Events: `NewSlotDeadline`
     */
    function setSlotDeadline(uint8 newDeadline) external;

    /**
     * @notice Getter of the current `_openAuctionSlots`
     * @return The `_openAuctionSlots` value
     */
    function getOpenAuctionSlots() external view returns (uint16);

    /**
     * @notice Allows to change the `_openAuctionSlots` if it's called by the owner
     * @dev Max newOpenAuctionSlots = 65536 slots
     * @param newOpenAuctionSlots new `_openAuctionSlots`
     * Events: `NewOpenAuctionSlots`
     * Note: the governance could set this parameter equal to `ClosedAuctionSlots`, this means that it can prevent bids
     * from being made and that only the boot coordinator can forge
     */
    function setOpenAuctionSlots(uint16 newOpenAuctionSlots) external;

    /**
     * @notice Getter of the current `_closedAuctionSlots`
     * @return The `_closedAuctionSlots` value
     */
    function getClosedAuctionSlots() external view returns (uint16);

    /**
     * @notice Allows to change the `_closedAuctionSlots` if it's called by the owner
     * @dev Max newClosedAuctionSlots = 65536 slots
     * @param newClosedAuctionSlots new `_closedAuctionSlots`
     * Events: `NewClosedAuctionSlots`
     * Note: the governance could set this parameter equal to `OpenAuctionSlots`, this means that it can prevent bids
     * from being made and that only the boot coordinator can forge
     */
    function setClosedAuctionSlots(uint16 newClosedAuctionSlots) external;

    /**
     * @notice Getter of the current `_outbidding`
     * @return The `_outbidding` value
     */
    function getOutbidding() external view returns (uint16);

    /**
     * @notice Allows to change the `_outbidding` if it's called by the owner
     * @dev newOutbidding between 0.00% and 655.36%
     * @param newOutbidding new `_outbidding`
     * Events: `NewOutbidding`
     */
    function setOutbidding(uint16 newOutbidding) external;

    /**
     * @notice Getter of the current `_allocationRatio`
     * @return The `_allocationRatio` array
     */
    function getAllocationRatio() external view returns (uint16[3] memory);

    /**
     * @notice Allows to change the `_allocationRatio` array if it's called by the owner
     * @param newAllocationRatio new `_allocationRatio` uint8[3] array
     * Events: `NewAllocationRatio`
     */
    function setAllocationRatio(uint16[3] memory newAllocationRatio) external;

    /**
     * @notice Getter of the current `_donationAddress`
     * @return The `_donationAddress`
     */
    function getDonationAddress() external view returns (address);

    /**
     * @notice Allows to change the `_donationAddress` if it's called by the owner
     * @param newDonationAddress new `_donationAddress`
     * Events: `NewDonationAddress`
     */
    function setDonationAddress(address newDonationAddress) external;

    /**
     * @notice Getter of the current `_bootCoordinator`
     * @return The `_bootCoordinator`
     */
    function getBootCoordinator() external view returns (address);

    /**
     * @notice Allows to change the `_bootCoordinator` if it's called by the owner
     * @param newBootCoordinator new `_bootCoordinator` uint8[3] array
     * Events: `NewBootCoordinator`
     */
    function setBootCoordinator(
        address newBootCoordinator,
        string memory newBootCoordinatorURL
    ) external;

    /**
     * @notice Allows to change the change the min bid for an slotSet if it's called by the owner.
     * @dev If an slotSet has the value of 0 it's considered decentralized, so the minbid cannot be modified
     * @param slotSet the slotSet to update
     * @param newInitialMinBid the minBid
     * Events: `NewDefaultSlotSetBid`
     */
    function changeDefaultSlotSetBid(uint128 slotSet, uint128 newInitialMinBid)
        external;

    /**
     * @notice Allows to register a new coordinator
     * @dev The `msg.sender` will be considered the `bidder`, who can change the forger address and the url
     * @param forger the address allowed to forger batches
     * @param coordinatorURL endopoint for this coordinator
     * Events: `NewCoordinator`
     */
    function setCoordinator(address forger, string memory coordinatorURL)
        external;

    /**
     * @notice Function to process a single bid
     * @dev If the bytes calldata permit parameter is empty the smart contract assume that it has enough allowance to
     * make the transferFrom. In case you want to use permit, you need to send the data of the permit call in bytes
     * @param amount the amount of tokens that have been sent
     * @param slot the slot for which the caller is bidding
     * @param bidAmount the amount of the bidding
     */
    function processBid(
        uint128 amount,
        uint128 slot,
        uint128 bidAmount,
        bytes calldata permit
    ) external;

    /**
     * @notice function to process a multi bid
     * @dev If the bytes calldata permit parameter is empty the smart contract assume that it has enough allowance to
     * make the transferFrom. In case you want to use permit, you need to send the data of the permit call in bytes
     * @param amount the amount of tokens that have been sent
     * @param startingSlot the first slot to bid
     * @param endingSlot the last slot to bid
     * @param slotSets the set of slots to which the coordinator wants to bid
     * @param maxBid the maximum bid that is allowed
     * @param minBid the minimum that you want to bid
     */
    function processMultiBid(
        uint128 amount,
        uint128 startingSlot,
        uint128 endingSlot,
        bool[6] memory slotSets,
        uint128 maxBid,
        uint128 minBid,
        bytes calldata permit
    ) external;

    /**
     * @notice function to process the forging
     * @param forger the address of the coodirnator's forger
     * Events: `NewForgeAllocated` and `NewForge`
     */
    function forge(address forger) external;

    /**
     * @notice function to know if a certain address can forge into a certain block
     * @param forger the address of the coodirnator's forger
     * @param blockNumber block number to check
     * @return a bool true in case it can forge, false otherwise
     */
    function canForge(address forger, uint256 blockNumber)
        external
        view
        returns (bool);
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

interface IWithdrawalDelayer {
    /**
     * @notice Getter of the current `_hermezGovernanceAddress`
     * @return The `_hermezGovernanceAddress` value
     */
    function getHermezGovernanceAddress() external view returns (address);

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param newGovernance The address to transfer governance to.
     */
    function transferGovernance(address newGovernance) external;

    /**
     * @dev Allows the pendingGovernance address to finalize the transfer.
     */
    function claimGovernance() external;

    /**
     * @notice Getter of the current `_emergencyCouncil`
     * @return The `_emergencyCouncil` value
     */
    function getEmergencyCouncil() external view returns (address);

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param newEmergencyCouncil The address to transfer governance to.
     */
    function transferEmergencyCouncil(address payable newEmergencyCouncil)
        external;

    /**
     * @dev Allows the pendingGovernance address to finalize the transfer.
     */
    function claimEmergencyCouncil() external;

    /**
     * @notice Getter of the current `_emergencyMode` status to know if the emergency mode is enable or disable
     * @return The `_emergencyMode` value
     */
    function isEmergencyMode() external view returns (bool);

    /**
     * @notice Getter to obtain the current withdrawal delay
     * @return the current withdrawal delay time in seconds: `_withdrawalDelay`
     */
    function getWithdrawalDelay() external view returns (uint64);

    /**
     * @notice Getter to obtain when emergency mode started
     * @return the emergency mode starting time in seconds: `_emergencyModeStartingTime`
     */
    function getEmergencyModeStartingTime() external view returns (uint64);

    /**
     * @notice This function enables the emergency mode. Only the keeper of the system can enable this mode. This cannot
     * be deactivated in any case so it will be irreversible.
     * @dev The activation time is saved in `_emergencyModeStartingTime` and this function can only be called
     * once if it has not been previously activated.
     * Events: `EmergencyModeEnabled` event.
     */
    function enableEmergencyMode() external;

    /**
     * @notice This function allows the HermezKeeperAddress to change the withdrawal delay time, this is the time that
     * anyone needs to wait until a withdrawal of the funds is allowed. Since this time is calculated at the time of
     * withdrawal, this change affects existing deposits. Can never exceed `MAX_WITHDRAWAL_DELAY`
     * @dev It changes `_withdrawalDelay` if `_newWithdrawalDelay` it is less than or equal to MAX_WITHDRAWAL_DELAY
     * @param _newWithdrawalDelay new delay time in seconds
     * Events: `NewWithdrawalDelay` event.
     */
    function changeWithdrawalDelay(uint64 _newWithdrawalDelay) external;

    /**
     * Returns the balance and the timestamp for a specific owner and token
     * @param _owner who can claim the deposit once the delay time has expired (if not in emergency mode)
     * @param _token address of the token to withdrawal (0x0 in case of Ether)
     * @return `amount` Total amount withdrawable (if not in emergency mode)
     * @return `depositTimestamp` Moment at which funds were deposited
     */
    function depositInfo(address payable _owner, address _token)
        external
        view
        returns (uint192, uint64);

    /**
     * Function to make a deposit in the WithdrawalDelayer smartcontract, only the Hermez rollup smartcontract can do it
     * @dev In case of an Ether deposit, the address `0x0` will be used and the corresponding amount must be sent in the
     * `msg.value`. In case of an ERC20 this smartcontract must have the approval to expend the token to
     * deposit to be able to make a transferFrom to itself.
     * @param _owner is who can claim the deposit once the withdrawal delay time has been exceeded
     * @param _token address of the token deposited (`0x0` in case of Ether)
     * @param _amount deposit amount
     * Events: `Deposit`
     */
    function deposit(
        address _owner,
        address _token,
        uint192 _amount
    ) external payable;

    /**
     * This function allows the owner to withdawal the funds. Emergency mode cannot be enabled and it must have exceeded
     * the withdrawal delay time
     * @dev `NonReentrant` modifier is used as a protection despite the state is being previously updated
     * @param _owner can claim the deposit once the delay time has expired
     * @param _token address of the token to withdrawal (0x0 in case of Ether)
     * Events: `Withdraw`
     */
    function withdrawal(address payable _owner, address _token) external;

    /**
     * Allows the Hermez Governance to withdawal the funds in the event that emergency mode was enable.
     * Note: An Aragon Court will have the right to veto over the call to this method
     * @dev `NonReentrant` modifier is used as a protection despite the state is being previously updated and this is
     * a security mechanism
     * @param _to where the funds will be sent
     * @param _token address of the token withdraw (0x0 in case of Ether)
     * @param _amount the amount to send
     * Events: `EscapeHatchWithdrawal`
     */
    function escapeHatchWithdrawal(
        address _to,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @dev Interface poseidon hash function 2 elements
 */
contract PoseidonUnit2 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

/**
 * @dev Interface poseidon hash function 3 elements
 */
contract PoseidonUnit3 {
    function poseidon(uint256[3] memory) public pure returns (uint256) {}
}

/**
 * @dev Interface poseidon hash function 4 elements
 */
contract PoseidonUnit4 {
    function poseidon(uint256[4] memory) public pure returns (uint256) {}
}

/**
 * @dev Rollup helper functions
 */
contract HermezHelpers is Initializable {
    PoseidonUnit2 _insPoseidonUnit2;
    PoseidonUnit3 _insPoseidonUnit3;
    PoseidonUnit4 _insPoseidonUnit4;

    uint256 private constant _WORD_SIZE = 32;

    // bytes32 public constant EIP712DOMAIN_HASH =
    //      keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712DOMAIN_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // bytes32 public constant NAME_HASH =
    //      keccak256("Hermez Network")
    bytes32 public constant NAME_HASH =
        0xbe287413178bfeddef8d9753ad4be825ae998706a6dabff23978b59dccaea0ad;
    // bytes32 public constant VERSION_HASH =
    //      keccak256("1")
    bytes32 public constant VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    // bytes32 public constant AUTHORISE_TYPEHASH =
    //      keccak256("Authorise(string Provider,string Authorisation,bytes32 BJJKey)");
    bytes32 public constant AUTHORISE_TYPEHASH =
        0xafd642c6a37a2e6887dc4ad5142f84197828a904e53d3204ecb1100329231eaa;
    // bytes32 public constant HERMEZ_NETWORK_HASH = keccak256(bytes("Hermez Network")),
    bytes32 public constant HERMEZ_NETWORK_HASH =
        0xbe287413178bfeddef8d9753ad4be825ae998706a6dabff23978b59dccaea0ad;
    // bytes32 public constant ACCOUNT_CREATION_HASH = keccak256(bytes("Account creation")),
    bytes32 public constant ACCOUNT_CREATION_HASH =
        0xff946cf82975b1a2b6e6d28c9a76a4b8d7a1fd0592b785cb92771933310f9ee7;

    /**
     * @dev Load poseidon smart contract
     * @param _poseidon2Elements Poseidon contract address for 2 elements
     * @param _poseidon3Elements Poseidon contract address for 3 elements
     * @param _poseidon4Elements Poseidon contract address for 4 elements
     */
    function _initializeHelpers(
        address _poseidon2Elements,
        address _poseidon3Elements,
        address _poseidon4Elements
    ) internal initializer {
        _insPoseidonUnit2 = PoseidonUnit2(_poseidon2Elements);
        _insPoseidonUnit3 = PoseidonUnit3(_poseidon3Elements);
        _insPoseidonUnit4 = PoseidonUnit4(_poseidon4Elements);
    }

    /**
     * @dev Hash poseidon for 2 elements
     * @param inputs Poseidon input array of 2 elements
     * @return Poseidon hash
     */
    function _hash2Elements(uint256[2] memory inputs)
        internal
        view
        returns (uint256)
    {
        return _insPoseidonUnit2.poseidon(inputs);
    }

    /**
     * @dev Hash poseidon for 3 elements
     * @param inputs Poseidon input array of 3 elements
     * @return Poseidon hash
     */
    function _hash3Elements(uint256[3] memory inputs)
        internal
        view
        returns (uint256)
    {
        return _insPoseidonUnit3.poseidon(inputs);
    }

    /**
     * @dev Hash poseidon for 4 elements
     * @param inputs Poseidon input array of 4 elements
     * @return Poseidon hash
     */
    function _hash4Elements(uint256[4] memory inputs)
        internal
        view
        returns (uint256)
    {
        return _insPoseidonUnit4.poseidon(inputs);
    }

    /**
     * @dev Hash poseidon for sparse merkle tree nodes
     * @param left Input element array
     * @param right Input element array
     * @return Poseidon hash
     */
    function _hashNode(uint256 left, uint256 right)
        internal
        view
        returns (uint256)
    {
        uint256[2] memory inputs;
        inputs[0] = left;
        inputs[1] = right;
        return _hash2Elements(inputs);
    }

    /**
     * @dev Hash poseidon for sparse merkle tree final nodes
     * @param key Input element array
     * @param value Input element array
     * @return Poseidon hash1
     */
    function _hashFinalNode(uint256 key, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256[3] memory inputs;
        inputs[0] = key;
        inputs[1] = value;
        inputs[2] = 1;
        return _hash3Elements(inputs);
    }

    /**
     * @dev Verify sparse merkle tree proof
     * @param root Root to verify
     * @param siblings Siblings necessary to compute the merkle proof
     * @param key Key to verify
     * @param value Value to verify
     * @return True if verification is correct, false otherwise
     */
    function _smtVerifier(
        uint256 root,
        uint256[] memory siblings,
        uint256 key,
        uint256 value
    ) internal view returns (bool) {
        // Step 2: Calcuate root
        uint256 nextHash = _hashFinalNode(key, value);
        uint256 siblingTmp;
        for (int256 i = int256(siblings.length) - 1; i >= 0; i--) {
            siblingTmp = siblings[uint256(i)];
            bool leftRight = (uint8(key >> i) & 0x01) == 1;
            nextHash = leftRight
                ? _hashNode(siblingTmp, nextHash)
                : _hashNode(nextHash, siblingTmp);
        }

        // Step 3: Check root
        return root == nextHash;
    }

    /**
     * @dev Build entry for the exit tree leaf
     * @param token Token identifier
     * @param nonce nonce parameter, only use 40 bits instead of 48
     * @param balance Balance of the account
     * @param ay Public key babyjubjub represented as point: sign + (Ay)
     * @param ethAddress Ethereum address
     * @return uint256 array with the state variables
     */
    function _buildTreeState(
        uint32 token,
        uint48 nonce,
        uint256 balance,
        uint256 ay,
        address ethAddress
    ) internal pure returns (uint256[4] memory) {
        uint256[4] memory stateArray;

        stateArray[0] = token;
        stateArray[0] |= nonce << 32;
        stateArray[0] |= (ay >> 255) << (32 + 40);
        // build element 2
        stateArray[1] = balance;
        // build element 4
        stateArray[2] = (ay << 1) >> 1; // last bit set to 0
        // build element 5
        stateArray[3] = uint256(ethAddress);
        return stateArray;
    }

    /**
     * @dev Decode half floating precision.
     * Max value encoded with this codification: 0x1f8def8800cca870c773f6eb4d980000000 (aprox 137 bits)
     * @param float Float half precision encode number
     * @return Decoded floating half precision
     */
    function _float2Fix(uint40 float) internal pure returns (uint256) {
        uint256 m = float & 0x7FFFFFFFF;
        uint256 e = float >> 35;

        // never overflow, max "e" value is 32
        uint256 exp = 10**e;

        // never overflow, max "fix" value is 1023 * 10^32
        uint256 fix = m * exp;

        return fix;
    }

    /**
     * @dev Retrieve the DOMAIN_SEPARATOR hash
     * @return domainSeparator hash used for sign messages
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_HASH,
                    NAME_HASH,
                    VERSION_HASH,
                    getChainId(),
                    address(this)
                )
            );
    }

    /**
     * @return chainId The current chainId where the smarctoncract is executed
     */
    function getChainId() public pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev Retrieve ethereum address from a (defaultMessage + babyjub) signature
     * @param babyjub Public key babyjubjub represented as point: sign + (Ay)
     * @param r Signature parameter
     * @param s Signature parameter
     * @param v Signature parameter
     * @return Ethereum address recovered from the signature
     */
    function _checkSig(
        bytes32 babyjub,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (address) {
        // from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L46
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "HermezHelpers::_checkSig: INVALID_S_VALUE"
        );

        bytes32 encodeData =
            keccak256(
                abi.encode(
                    AUTHORISE_TYPEHASH,
                    HERMEZ_NETWORK_HASH,
                    ACCOUNT_CREATION_HASH,
                    babyjub
                )
            );

        bytes32 messageDigest =
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), encodeData)
            );

        address ethAddress = ecrecover(messageDigest, v, r, s);

        require(
            ethAddress != address(0),
            "HermezHelpers::_checkSig: INVALID_SIGNATURE"
        );

        return ethAddress;
    }

    /**
     * @dev return information from specific call data info
     * @param posParam parameter number relative to 0 to extract the info
     * @return ptr ptr to the call data position where the actual data starts
     * @return len Length of the data
     */
    function _getCallData(uint256 posParam)
        internal
        pure
        returns (uint256 ptr, uint256 len)
    {
        assembly {
            let pos := add(4, mul(posParam, 32))
            ptr := add(calldataload(pos), 4)
            len := calldataload(ptr)
            ptr := add(ptr, 32)
        }
    }

    /**
     * @dev This package fills at least len zeros in memory and a maximum of len+31
     * @param ptr The position where it starts to fill zeros
     * @param len The minimum quantity of zeros it's added
     */
    function _fillZeros(uint256 ptr, uint256 len) internal pure {
        assembly {
            let ptrTo := ptr
            ptr := add(ptr, len)
            for {

            } lt(ptrTo, ptr) {
                ptrTo := add(ptrTo, 32)
            } {
                mstore(ptrTo, 0)
            }
        }
    }

    /**
     * @dev Copy 'len' bytes from memory address 'src', to address 'dest'.
     * From https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     * @param _preBytes bytes storage
     * @param _postBytes Bytes array memory
     */
    function _concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
                case 2 {
                    // Since the new array still fits in the slot, we just need to
                    // update the contents of the slot.
                    // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                    sstore(
                        _preBytes_slot,
                        // all the modifications to the slot are inside this
                        // next block
                        add(
                            // we can just add to the slot contents because the
                            // bytes we want to change are the LSBs
                            fslot,
                            add(
                                mul(
                                    div(
                                        // load the bytes from memory
                                        mload(add(_postBytes, 0x20)),
                                        // zero all bytes to the right
                                        exp(0x100, sub(32, mlength))
                                    ),
                                    // and now shift left the number of bytes to
                                    // leave space for the length in the slot
                                    exp(0x100, sub(32, newlength))
                                ),
                                // increase length by the double of the memory
                                // bytes length
                                mul(mlength, 2)
                            )
                        )
                    )
                }
                case 1 {
                    // The stored value fits in the slot, but the combined value
                    // will exceed it.
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // The contents of the _postBytes array start 32 bytes into
                    // the structure. Our first read should obtain the `submod`
                    // bytes that can fit into the unused space in the last word
                    // of the stored array. To get this, we read 32 bytes starting
                    // from `submod`, so the data we read overlaps with the array
                    // contents by `submod` bytes. Masking the lowest-order
                    // `submod` bytes allows us to add that value directly to the
                    // stored value.

                    let submod := sub(32, slength)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(
                        sc,
                        add(
                            and(
                                fslot,
                                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                            ),
                            and(mload(mc), mask)
                        )
                    )

                    for {
                        mc := add(mc, 0x20)
                        sc := add(sc, 1)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
                default {
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    // Start copying to the last used word of the stored array.
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // Copy over the first `submod` bytes of the new data as in
                    // case 1 above.
                    let slengthmod := mod(slength, 32)
                    let mlengthmod := mod(mlength, 32)
                    let submod := sub(32, slengthmod)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(sc, add(sload(sc), and(mload(mc), mask)))

                    for {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}