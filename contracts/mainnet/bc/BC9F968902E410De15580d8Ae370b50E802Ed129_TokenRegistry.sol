pragma solidity ^0.5.15;

contract NameRegistry {
    struct ContractDetails {
        // registered contract address
        address contractAddress;
    }
    event RegisteredNewContract(bytes32 name, address contractAddr);
    mapping(bytes32 => ContractDetails) registry;

    function registerName(bytes32 name, address addr) external returns (bool) {
        ContractDetails memory info = registry[name];
        // create info if it doesn't exist in the registry
        if (info.contractAddress == address(0)) {
            info.contractAddress = addr;
            registry[name] = info;
            // added to registry
            return true;
        } else {
            // already was registered
            return false;
        }
    }

    function getContractDetails(bytes32 name) external view returns (address) {
        return (registry[name].contractAddress);
    }

    function updateContractDetails(bytes32 name, address addr) external {
        // TODO not sure if we should do this
        // If we do we need a plan on how to remove this
    }
}

pragma solidity ^0.5.15;

/*
POB contract handles all the proof of burn related functionality
*/
contract POB {
    address public coordinator;

    constructor() public {
        coordinator = msg.sender;
    }

    function getCoordinator() public view returns (address) {
        return coordinator;
    }
}

pragma solidity >=0.4.21;

import { Logger } from "./logger.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";
import { ParamManager } from "./libs/ParamManager.sol";
import { POB } from "./POB.sol";

contract TokenRegistry {
    address public rollupNC;
    Logger public logger;
    mapping(address => bool) public pendingRegistrations;
    mapping(uint256 => address) public registeredTokens;

    uint256 public numTokens;

    modifier onlyCoordinator() {
        POB pobContract = POB(
            nameRegistry.getContractDetails(ParamManager.POB())
        );
        assert(msg.sender == pobContract.getCoordinator());
        _;
    }
    Registry public nameRegistry;

    constructor(address _registryAddr) public {
        nameRegistry = Registry(_registryAddr);

        logger = Logger(nameRegistry.getContractDetails(ParamManager.LOGGER()));
    }

    /**
     * @notice Requests addition of a new token to the chain, can be called by anyone
     * @param tokenContract Address for the new token being added
     */
    function requestTokenRegistration(address tokenContract) public {
        require(
            pendingRegistrations[tokenContract] == false,
            "Token already registered."
        );
        pendingRegistrations[tokenContract] = true;
        logger.logRegistrationRequest(tokenContract);
    }

    /**
     * @notice Add new tokens to the rollup chain by assigning them an ID called tokenType from here on
     * @param tokenContract Deposit tree depth or depth of subtree that is being deposited
     * TODO: add a modifier to allow only coordinator
     */
    function finaliseTokenRegistration(address tokenContract) public {
        require(
            pendingRegistrations[tokenContract],
            "Token was not registered"
        );
        numTokens++;
        registeredTokens[numTokens] = tokenContract; // tokenType => token contract address
        logger.logRegisteredToken(numTokens, tokenContract);
    }
}

pragma solidity ^0.5.15;

library ParamManager {
    function DEPOSIT_MANAGER() public pure returns (bytes32) {
        return keccak256("deposit_manager");
    }

    function WITHDRAW_MANAGER() public pure returns (bytes32) {
        return keccak256("withdraw_manager");
    }

    function TOKEN() public pure returns (bytes32) {
        return keccak256("token");
    }

    function POB() public pure returns (bytes32) {
        return keccak256("pob");
    }

    function Governance() public pure returns (bytes32) {
        return keccak256("governance");
    }

    function ROLLUP_CORE() public pure returns (bytes32) {
        return keccak256("rollup_core");
    }

    function ACCOUNTS_TREE() public pure returns (bytes32) {
        return keccak256("accounts_tree");
    }

    function LOGGER() public pure returns (bytes32) {
        return keccak256("logger");
    }

    function MERKLE_UTILS() public pure returns (bytes32) {
        return keccak256("merkle_lib");
    }

    function PARAM_MANAGER() public pure returns (bytes32) {
        return keccak256("param_manager");
    }

    function TOKEN_REGISTRY() public pure returns (bytes32) {
        return keccak256("token_registry");
    }

    function FRAUD_PROOF() public pure returns (bytes32) {
        return keccak256("fraud_proof");
    }

    bytes32 public constant _CHAIN_ID = keccak256("opru-123");

    function CHAIN_ID() public pure returns (bytes32) {
        return _CHAIN_ID;
    }
}

pragma solidity ^0.5.15;

/**
 * @title DataTypes
 */
library Types {
    // We define Usage for a batch or for a tx
    // to check if the usage of a batch and all txs in it are the same
    enum Usage {
        Genesis, // The Genesis type is only applicable to batch but not tx
        Transfer,
        Deposit
    }
    // PDALeaf represents the leaf in
    // Pubkey DataAvailability Tree
    struct PDALeaf {
        bytes pubkey;
    }

    // Batch represents the batch submitted periodically to the ethereum chain
    struct Batch {
        bytes32 stateRoot;
        bytes32 accountRoot;
        bytes32 depositTree;
        address committer;
        bytes32 txRoot;
        uint256 stakeCommitted;
        uint256 finalisesOn;
        uint256 timestamp;
        Usage batchType;
    }

    // Transaction represents how each transaction looks like for
    // this rollup chain
    struct Transaction {
        uint256 fromIndex;
        uint256 toIndex;
        uint256 tokenType;
        uint256 nonce;
        uint256 txType;
        uint256 amount;
        bytes signature;
    }

    // AccountInclusionProof consists of the following fields
    // 1. Path to the account leaf from root in the balances tree
    // 2. Actual data stored in the leaf
    struct AccountInclusionProof {
        uint256 pathToAccount;
        UserAccount account;
    }

    struct TranasctionInclusionProof {
        uint256 pathToTx;
        Transaction data;
    }

    struct PDAInclusionProof {
        uint256 pathToPubkey;
        PDALeaf pubkey_leaf;
    }

    // UserAccount contains the actual data stored in the leaf of balance tree
    struct UserAccount {
        // ID is the path to the pubkey in the PDA tree
        uint256 ID;
        uint256 tokenType;
        uint256 balance;
        uint256 nonce;
    }

    struct AccountMerkleProof {
        AccountInclusionProof accountIP;
        bytes32[] siblings;
    }

    struct AccountProofs {
        AccountMerkleProof from;
        AccountMerkleProof to;
    }

    struct BatchValidationProofs {
        AccountProofs[] accountProofs;
        PDAMerkleProof[] pdaProof;
    }

    struct TransactionMerkleProof {
        TranasctionInclusionProof _tx;
        bytes32[] siblings;
    }

    struct PDAMerkleProof {
        PDAInclusionProof _pda;
        bytes32[] siblings;
    }

    enum ErrorCode {
        NoError,
        InvalidTokenAddress,
        InvalidTokenAmount,
        NotEnoughTokenBalance,
        BadFromTokenType,
        BadToTokenType
    }
}

pragma solidity ^0.5.15;

import { Types } from "./libs/Types.sol";

contract Logger {
    /*********************
     * Rollup Contract *
     ********************/
    event NewBatch(
        address committer,
        bytes32 txroot,
        bytes32 updatedRoot,
        uint256 index,
        Types.Usage batchType
    );

    function logNewBatch(
        address committer,
        bytes32 txroot,
        bytes32 updatedRoot,
        uint256 index,
        Types.Usage batchType
    ) public {
        emit NewBatch(committer, txroot, updatedRoot, index, batchType);
    }

    event StakeWithdraw(address committed, uint256 amount, uint256 batch_id);

    function logStakeWithdraw(
        address committed,
        uint256 amount,
        uint256 batch_id
    ) public {
        emit StakeWithdraw(committed, amount, batch_id);
    }

    event BatchRollback(
        uint256 batch_id,
        address committer,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 stakeSlashed
    );

    function logBatchRollback(
        uint256 batch_id,
        address committer,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 stakeSlashed
    ) public {
        emit BatchRollback(
            batch_id,
            committer,
            stateRoot,
            txRoot,
            stakeSlashed
        );
    }

    event RollbackFinalisation(uint256 totalBatchesSlashed);

    function logRollbackFinalisation(uint256 totalBatchesSlashed) public {
        emit RollbackFinalisation(totalBatchesSlashed);
    }

    event RegisteredToken(uint256 tokenType, address tokenContract);

    function logRegisteredToken(uint256 tokenType, address tokenContract)
        public
    {
        emit RegisteredToken(tokenType, tokenContract);
    }

    event RegistrationRequest(address tokenContract);

    function logRegistrationRequest(address tokenContract) public {
        emit RegistrationRequest(tokenContract);
    }

    event NewPubkeyAdded(uint256 AccountID, bytes pubkey);

    function logNewPubkeyAdded(uint256 accountID, bytes memory pubkey) public {
        emit NewPubkeyAdded(accountID, pubkey);
    }

    event DepositQueued(uint256 AccountID, bytes pubkey, bytes data);

    function logDepositQueued(
        uint256 accountID,
        bytes memory pubkey,
        bytes memory data
    ) public {
        emit DepositQueued(accountID, pubkey, data);
    }

    event DepositLeafMerged(bytes32 left, bytes32 right, bytes32 newRoot);

    function logDepositLeafMerged(
        bytes32 left,
        bytes32 right,
        bytes32 newRoot
    ) public {
        emit DepositLeafMerged(left, right, newRoot);
    }

    event DepositSubTreeReady(bytes32 root);

    function logDepositSubTreeReady(bytes32 root) public {
        emit DepositSubTreeReady(root);
    }

    event DepositsFinalised(bytes32 depositSubTreeRoot, uint256 pathToSubTree);

    function logDepositFinalised(
        bytes32 depositSubTreeRoot,
        uint256 pathToSubTree
    ) public {
        emit DepositsFinalised(depositSubTreeRoot, pathToSubTree);
    }
}

