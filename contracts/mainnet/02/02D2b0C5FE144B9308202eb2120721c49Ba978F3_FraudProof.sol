pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { ITokenRegistry } from "./interfaces/ITokenRegistry.sol";

import { Types } from "./libs/Types.sol";
import { RollupUtils } from "./libs/RollupUtils.sol";
import { ParamManager } from "./libs/ParamManager.sol";
import { ECVerify } from "./libs/ECVerify.sol";

import { MerkleTreeUtils as MTUtils } from "./MerkleTreeUtils.sol";
import { Governance } from "./Governance.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";

contract FraudProofSetup {
    using SafeMath for uint256;
    using ECVerify for bytes32;

    MTUtils public merkleUtils;
    ITokenRegistry public tokenRegistry;
    Registry public nameRegistry;

    bytes32
        public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    Governance public governance;
}

contract FraudProofHelpers is FraudProofSetup {
    function ValidatePubkeyAvailability(
        bytes32 _accountsRoot,
        Types.PDAMerkleProof memory _from_pda_proof,
        uint256 from_index
    ) public view {
        // verify from account pubkey exists in PDA tree
        // NOTE: We dont need to prove that to address has the pubkey available
        Types.PDALeaf memory fromPDA = Types.PDALeaf({
            pubkey: _from_pda_proof._pda.pubkey_leaf.pubkey
        });

        require(
            merkleUtils.verifyLeaf(
                _accountsRoot,
                RollupUtils.PDALeafToHash(fromPDA),
                _from_pda_proof._pda.pathToPubkey,
                _from_pda_proof.siblings
            ),
            "From PDA proof is incorrect"
        );

        // convert pubkey path to ID
        uint256 computedID = merkleUtils.pathToIndex(
            _from_pda_proof._pda.pathToPubkey,
            governance.MAX_DEPTH()
        );

        // make sure the ID in transaction is the same account for which account proof was provided
        require(
            computedID == from_index,
            "Pubkey not related to the from account in the transaction"
        );
    }

    function ValidateAccountMP(
        bytes32 root,
        Types.AccountMerkleProof memory merkle_proof
    ) public view {
        bytes32 accountLeaf = RollupUtils.getAccountHash(
            merkle_proof.accountIP.account.ID,
            merkle_proof.accountIP.account.balance,
            merkle_proof.accountIP.account.nonce,
            merkle_proof.accountIP.account.tokenType
        );

        // verify from leaf exists in the balance tree
        require(
            merkleUtils.verifyLeaf(
                root,
                accountLeaf,
                merkle_proof.accountIP.pathToAccount,
                merkle_proof.siblings
            ),
            "Merkle Proof is incorrect"
        );
    }

    function validateTxBasic(
        Types.Transaction memory _tx,
        Types.UserAccount memory _from_account
    ) public view returns (Types.ErrorCode) {
        // verify that tokens are registered
        if (tokenRegistry.registeredTokens(_tx.tokenType) == address(0)) {
            // invalid state transition
            // to be slashed because the submitted transaction
            // had invalid token type
            return Types.ErrorCode.InvalidTokenAddress;
        }

        if (_tx.amount == 0) {
            // invalid state transition
            // needs to be slashed because the submitted transaction
            // had 0 amount.
            return Types.ErrorCode.InvalidTokenAmount;
        }

        // check from leaf has enough balance
        if (_from_account.balance < _tx.amount) {
            // invalid state transition
            // needs to be slashed because the account doesnt have enough balance
            // for the transfer
            return Types.ErrorCode.NotEnoughTokenBalance;
        }

        return Types.ErrorCode.NoError;
    }

    function RemoveTokensFromAccount(
        Types.UserAccount memory account,
        uint256 numOfTokens
    ) public pure returns (Types.UserAccount memory updatedAccount) {
        return (
            RollupUtils.UpdateBalanceInAccount(
                account,
                RollupUtils.BalanceFromAccount(account).sub(numOfTokens)
            )
        );
    }

    /**
     * @notice ApplyTx applies the transaction on the account. This is where
     * people need to define the logic for the application
     * @param _merkle_proof contains the siblings and path to the account
     * @param transaction is the transaction that needs to be applied
     * @return returns updated account and updated state root
     * */
    function ApplyTx(
        Types.AccountMerkleProof memory _merkle_proof,
        Types.Transaction memory transaction
    ) public view returns (bytes memory updatedAccount, bytes32 newRoot) {
        Types.UserAccount memory account = _merkle_proof.accountIP.account;
        if (transaction.fromIndex == account.ID) {
            account = RemoveTokensFromAccount(account, transaction.amount);
            account.nonce++;
        }

        if (transaction.toIndex == account.ID) {
            account = AddTokensToAccount(account, transaction.amount);
        }

        newRoot = UpdateAccountWithSiblings(account, _merkle_proof);

        return (RollupUtils.BytesFromAccount(account), newRoot);
    }

    function AddTokensToAccount(
        Types.UserAccount memory account,
        uint256 numOfTokens
    ) public pure returns (Types.UserAccount memory updatedAccount) {
        return (
            RollupUtils.UpdateBalanceInAccount(
                account,
                RollupUtils.BalanceFromAccount(account).add(numOfTokens)
            )
        );
    }

    /**
     * @notice Returns the updated root and balance
     */
    function UpdateAccountWithSiblings(
        Types.UserAccount memory new_account,
        Types.AccountMerkleProof memory _merkle_proof
    ) public view returns (bytes32) {
        bytes32 newRoot = merkleUtils.updateLeafWithSiblings(
            keccak256(RollupUtils.BytesFromAccount(new_account)),
            _merkle_proof.accountIP.pathToAccount,
            _merkle_proof.siblings
        );
        return (newRoot);
    }

    function ValidateSignature(
        Types.Transaction memory _tx,
        Types.PDAMerkleProof memory _from_pda_proof
    ) public pure returns (bool) {
        require(
            RollupUtils.calculateAddress(
                _from_pda_proof._pda.pubkey_leaf.pubkey
            ) ==
                RollupUtils
                    .getTxSignBytes(
                    _tx
                        .fromIndex,
                    _tx
                        .toIndex,
                    _tx
                        .tokenType,
                    _tx
                        .txType,
                    _tx
                        .nonce,
                    _tx
                        .amount
                )
                    .ecrecovery(_tx.signature),
            "Signature is incorrect"
        );
    }
}

contract FraudProof is FraudProofHelpers {
    /*********************
     * Constructor *
     ********************/
    constructor(address _registryAddr) public {
        nameRegistry = Registry(_registryAddr);

        governance = Governance(
            nameRegistry.getContractDetails(ParamManager.Governance())
        );

        merkleUtils = MTUtils(
            nameRegistry.getContractDetails(ParamManager.MERKLE_UTILS())
        );

        tokenRegistry = ITokenRegistry(
            nameRegistry.getContractDetails(ParamManager.TOKEN_REGISTRY())
        );
    }

    function generateTxRoot(Types.Transaction[] memory _txs)
        public
        view
        returns (bytes32 txRoot)
    {
        // generate merkle tree from the txs provided by user
        bytes[] memory txs = new bytes[](_txs.length);
        for (uint256 i = 0; i < _txs.length; i++) {
            txs[i] = RollupUtils.CompressTx(_txs[i]);
        }
        txRoot = merkleUtils.getMerkleRoot(txs);
        return txRoot;
    }

    /**
     * @notice processBatch processes a whole batch
     * @return returns updatedRoot, txRoot and if the batch is valid or not
     * */
    function processBatch(
        bytes32 stateRoot,
        bytes32 accountsRoot,
        Types.Transaction[] memory _txs,
        Types.BatchValidationProofs memory batchProofs,
        bytes32 expectedTxRoot
    )
        public
        view
        returns (
            bytes32,
            bytes32,
            bool
        )
    {
        bytes32 actualTxRoot = generateTxRoot(_txs);
        // if there is an expectation set, revert if it's not met
        if (expectedTxRoot == ZERO_BYTES32) {
            // if tx root while submission doesnt match tx root of given txs
            // dispute is unsuccessful
            require(
                actualTxRoot == expectedTxRoot,
                "Invalid dispute, tx root doesn't match"
            );
        }

        bool isTxValid;
        {
            for (uint256 i = 0; i < _txs.length; i++) {
                // call process tx update for every transaction to check if any
                // tx evaluates correctly
                (stateRoot, , , , isTxValid) = processTx(
                    stateRoot,
                    accountsRoot,
                    _txs[i],
                    batchProofs.pdaProof[i],
                    batchProofs.accountProofs[i]
                );

                if (!isTxValid) {
                    break;
                }
            }
        }
        return (stateRoot, actualTxRoot, !isTxValid);
    }

    /**
     * @notice processTx processes a transactions and returns the updated balance tree
     *  and the updated leaves
     * conditions in require mean that the dispute be declared invalid
     * if conditons evaluate if the coordinator was at fault
     * @return Total number of batches submitted onchain
     */
    function processTx(
        bytes32 _balanceRoot,
        bytes32 _accountsRoot,
        Types.Transaction memory _tx,
        Types.PDAMerkleProof memory _from_pda_proof,
        Types.AccountProofs memory accountProofs
    )
        public
        view
        returns (
            bytes32,
            bytes memory,
            bytes memory,
            Types.ErrorCode,
            bool
        )
    {
        // Step-1 Prove that from address's public keys are available
        ValidatePubkeyAvailability(
            _accountsRoot,
            _from_pda_proof,
            _tx.fromIndex
        );

        // STEP:2 Ensure the transaction has been signed using the from public key
        // ValidateSignature(_tx, _from_pda_proof);

        // Validate the from account merkle proof
        ValidateAccountMP(_balanceRoot, accountProofs.from);

        Types.ErrorCode err_code = validateTxBasic(
            _tx,
            accountProofs.from.accountIP.account
        );
        if (err_code != Types.ErrorCode.NoError)
            return (ZERO_BYTES32, "", "", err_code, false);

        // account holds the token type in the tx
        if (accountProofs.from.accountIP.account.tokenType != _tx.tokenType)
            // invalid state transition
            // needs to be slashed because the submitted transaction
            // had invalid token type
            return (
                ZERO_BYTES32,
                "",
                "",
                Types.ErrorCode.BadFromTokenType,
                false
            );

        bytes32 newRoot;
        bytes memory new_from_account;
        bytes memory new_to_account;

        (new_from_account, newRoot) = ApplyTx(accountProofs.from, _tx);

        // validate if leaf exists in the updated balance tree
        ValidateAccountMP(newRoot, accountProofs.to);

        // account holds the token type in the tx
        if (accountProofs.to.accountIP.account.tokenType != _tx.tokenType)
            // invalid state transition
            // needs to be slashed because the submitted transaction
            // had invalid token type
            return (
                ZERO_BYTES32,
                "",
                "",
                Types.ErrorCode.BadToTokenType,
                false
            );

        (new_to_account, newRoot) = ApplyTx(accountProofs.to, _tx);

        return (
            newRoot,
            new_from_account,
            new_to_account,
            Types.ErrorCode.NoError,
            true
        );
    }
}

pragma solidity ^0.5.15;

/*
Governance contract handles all the proof of burn related functionality
*/
contract Governance {
    constructor(uint256 maxDepth, uint256 maxDepositSubTree) public {
        _MAX_DEPTH = maxDepth;
        _MAX_DEPOSIT_SUBTREE = maxDepositSubTree;
    }

    uint256 public _MAX_DEPTH = 4;

    function MAX_DEPTH() public view returns (uint256) {
        return _MAX_DEPTH;
    }

    uint256 public _MAX_DEPOSIT_SUBTREE = 2;

    function MAX_DEPOSIT_SUBTREE() public view returns (uint256) {
        return _MAX_DEPOSIT_SUBTREE;
    }

    // finalisation time is the number of blocks required by a batch to finalise
    // Delay period = 7 days. Block time = 15 seconds
    uint256 public _TIME_TO_FINALISE = 7 days;

    function TIME_TO_FINALISE() public view returns (uint256) {
        return _TIME_TO_FINALISE;
    }

    // min gas required before rollback pauses
    uint256 public _MIN_GAS_LIMIT_LEFT = 100000;

    function MIN_GAS_LIMIT_LEFT() public view returns (uint256) {
        return _MIN_GAS_LIMIT_LEFT;
    }

    uint256 public _MAX_TXS_PER_BATCH = 10;

    function MAX_TXS_PER_BATCH() public view returns (uint256) {
        return _MAX_TXS_PER_BATCH;
    }

    uint256 public _STAKE_AMOUNT = 32 ether;

    function STAKE_AMOUNT() public view returns (uint256) {
        return _STAKE_AMOUNT;
    }
}

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;
import { ParamManager } from "./libs/ParamManager.sol";
import { Governance } from "./Governance.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";

contract MerkleTreeUtils {
    // The default hashes
    bytes32[] public defaultHashes;
    uint256 public MAX_DEPTH;
    Governance public governance;

    /**
     * @notice Initialize a new MerkleTree contract, computing the default hashes for the merkle tree (MT)
     */
    constructor(address _registryAddr) public {
        Registry nameRegistry = Registry(_registryAddr);
        governance = Governance(
            nameRegistry.getContractDetails(ParamManager.Governance())
        );
        MAX_DEPTH = governance.MAX_DEPTH();
        defaultHashes = new bytes32[](MAX_DEPTH);
        // Calculate & set the default hashes
        setDefaultHashes(MAX_DEPTH);
    }

    /* Methods */

    /**
     * @notice Set default hashes
     */
    function setDefaultHashes(uint256 depth) internal {
        // Set the initial default hash.
        defaultHashes[0] = keccak256(abi.encode(0));
        for (uint256 i = 1; i < depth; i++) {
            defaultHashes[i] = keccak256(
                abi.encode(defaultHashes[i - 1], defaultHashes[i - 1])
            );
        }
    }

    function getZeroRoot() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    defaultHashes[MAX_DEPTH - 1],
                    defaultHashes[MAX_DEPTH - 1]
                )
            );
    }

    function getMaxTreeDepth() public view returns (uint256) {
        return MAX_DEPTH;
    }

    function getRoot(uint256 index) public view returns (bytes32) {
        return defaultHashes[index];
    }

    function getDefaultHashAtLevel(uint256 index)
        public
        view
        returns (bytes32)
    {
        return defaultHashes[index];
    }

    function keecakHash(bytes memory data) public pure returns (bytes32) {
        return keccak256(data);
    }

    /**
     * @notice Get the merkle root computed from some set of data blocks.
     * @param _dataBlocks The data being used to generate the tree.
     * @return the merkle tree root
     * NOTE: This is a stateless operation
     */
    function getMerkleRoot(bytes[] calldata _dataBlocks)
        external
        view
        returns (bytes32)
    {
        uint256 nextLevelLength = _dataBlocks.length;
        uint256 currentLevel = 0;
        bytes32[] memory nodes = new bytes32[](nextLevelLength + 1); // Add one in case we have an odd number of leaves
        // Generate the leaves
        for (uint256 i = 0; i < _dataBlocks.length; i++) {
            nodes[i] = keccak256(_dataBlocks[i]);
        }
        if (_dataBlocks.length == 1) {
            return nodes[0];
        }
        // Add a defaultNode if we've got an odd number of leaves
        if (nextLevelLength % 2 == 1) {
            nodes[nextLevelLength] = defaultHashes[currentLevel];
            nextLevelLength += 1;
        }

        // Now generate each level
        while (nextLevelLength > 1) {
            currentLevel += 1;
            // Calculate the nodes for the currentLevel
            for (uint256 i = 0; i < nextLevelLength / 2; i++) {
                nodes[i] = getParent(nodes[i * 2], nodes[i * 2 + 1]);
            }
            nextLevelLength = nextLevelLength / 2;
            // Check if we will need to add an extra node
            if (nextLevelLength % 2 == 1 && nextLevelLength != 1) {
                nodes[nextLevelLength] = defaultHashes[currentLevel];
                nextLevelLength += 1;
            }
        }
        // Alright! We should be left with a single node! Return it...
        return nodes[0];
    }

    /**
     * @notice Get the merkle root computed from some set of data blocks.
     * @param nodes The data being used to generate the tree.
     * @return the merkle tree root
     * NOTE: This is a stateless operation
     */
    function getMerkleRootFromLeaves(bytes32[] memory nodes)
        public
        view
        returns (bytes32)
    {
        uint256 nextLevelLength = nodes.length;
        uint256 currentLevel = 0;
        if (nodes.length == 1) {
            return nodes[0];
        }

        // Add a defaultNode if we've got an odd number of leaves
        if (nextLevelLength % 2 == 1) {
            nodes[nextLevelLength] = defaultHashes[currentLevel];
            nextLevelLength += 1;
        }

        // Now generate each level
        while (nextLevelLength > 1) {
            currentLevel += 1;

            // Calculate the nodes for the currentLevel
            for (uint256 i = 0; i < nextLevelLength / 2; i++) {
                nodes[i] = getParent(nodes[i * 2], nodes[i * 2 + 1]);
            }

            nextLevelLength = nextLevelLength / 2;
            // Check if we will need to add an extra node
            if (nextLevelLength % 2 == 1 && nextLevelLength != 1) {
                nodes[nextLevelLength] = defaultHashes[currentLevel];
                nextLevelLength += 1;
            }
        }

        // Alright! We should be left with a single node! Return it...
        return nodes[0];
    }

    /**
     * @notice Calculate root from an inclusion proof.
     * @param _dataBlock The data block we're calculating root for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function computeInclusionProofRoot(
        bytes memory _dataBlock,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bytes32) {
        // First compute the leaf node
        bytes32 computedNode = keccak256(_dataBlock);

        for (uint256 i = 0; i < _siblings.length; i++) {
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                computedNode = getParent(computedNode, sibling);
            } else {
                computedNode = getParent(sibling, computedNode);
            }
        }
        // Check if the computed node (_root) is equal to the provided root
        return computedNode;
    }

    /**
     * @notice Calculate root from an inclusion proof.
     * @param _leaf The data block we're calculating root for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function computeInclusionProofRootWithLeaf(
        bytes32 _leaf,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bytes32) {
        // First compute the leaf node
        bytes32 computedNode = _leaf;
        for (uint256 i = 0; i < _siblings.length; i++) {
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                computedNode = getParent(computedNode, sibling);
            } else {
                computedNode = getParent(sibling, computedNode);
            }
        }
        // Check if the computed node (_root) is equal to the provided root
        return computedNode;
    }

    /**
     * @notice Verify an inclusion proof.
     * @param _root The root of the tree we are verifying inclusion for.
     * @param _dataBlock The data block we're verifying inclusion for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function verify(
        bytes32 _root,
        bytes memory _dataBlock,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bool) {
        // First compute the leaf node
        bytes32 calculatedRoot = computeInclusionProofRoot(
            _dataBlock,
            _path,
            _siblings
        );
        return calculatedRoot == _root;
    }

    /**
     * @notice Verify an inclusion proof.
     * @param _root The root of the tree we are verifying inclusion for.
     * @param _leaf The data block we're verifying inclusion for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function verifyLeaf(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bool) {
        bytes32 calculatedRoot = computeInclusionProofRootWithLeaf(
            _leaf,
            _path,
            _siblings
        );
        return calculatedRoot == _root;
    }

    /**
     * @notice Update a leaf using siblings and root
     *         This is a stateless operation
     * @param _leaf The leaf we're updating.
     * @param _path The path from the leaf to the root / the index of the leaf.
     * @param _siblings The sibling nodes along the way.
     * @return Updated root
     */
    function updateLeafWithSiblings(
        bytes32 _leaf,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bytes32) {
        bytes32 computedNode = _leaf;
        for (uint256 i = 0; i < _siblings.length; i++) {
            bytes32 parent;
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                parent = getParent(computedNode, sibling);
            } else {
                parent = getParent(sibling, computedNode);
            }
            computedNode = parent;
        }
        return computedNode;
    }

    /**
     * @notice Get the parent of two children nodes in the tree
     * @param _left The left child
     * @param _right The right child
     * @return The parent node
     */
    function getParent(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_left, _right));
    }

    /**
     * @notice get the n'th bit in a uint.
     *         For instance, if exampleUint=binary(11), getNth(exampleUint, 0) == 1, getNth(2, 1) == 1
     * @param _intVal The uint we are extracting a bit out of
     * @param _index The index of the bit we want to extract
     * @return The bit (1 or 0) in a uint8
     */
    function getNthBitFromRight(uint256 _intVal, uint256 _index)
        public
        pure
        returns (uint8)
    {
        return uint8((_intVal >> _index) & 1);
    }

    /**
     * @notice Get the right sibling key. Note that these keys overwrite the first bit of the hash
               to signify if it is on the right side of the parent or on the left
     * @param _parent The parent node
     * @return the key for the left sibling (0 as the first bit)
     */
    function getLeftSiblingKey(bytes32 _parent) public pure returns (bytes32) {
        return
            _parent &
            0x0111111111111111111111111111111111111111111111111111111111111111;
    }

    /**
     * @notice Get the right sibling key. Note that these keys overwrite the first bit of the hash
               to signify if it is on the right side of the parent or on the left
     * @param _parent The parent node
     * @return the key for the right sibling (1 as the first bit)
     */
    function getRightSiblingKey(bytes32 _parent) public pure returns (bytes32) {
        return
            _parent |
            0x1000000000000000000000000000000000000000000000000000000000000000;
    }

    function pathToIndex(uint256 path, uint256 height)
        public
        pure
        returns (uint256)
    {
        uint256 result = 0;
        for (uint256 i = 0; i < height; i++) {
            uint8 temp = getNthBitFromRight(path, i);
            // UNSAFE FIX THIS
            result = result + (temp * (2**i));
        }
        return result;
    }
}

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

// ERC20 token interface
contract IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {}

    function transfer(address recipient, uint256 value) public returns (bool) {}
}

pragma solidity ^0.5.15;

// token registry contract interface
contract ITokenRegistry {
    uint256 public numTokens;
    mapping(address => bool) public pendingRegistrations;
    mapping(uint256 => address) public registeredTokens;

    function requestTokenRegistration(address tokenContract) public {}

    function finaliseTokenRegistration(address tokenContract) public {}
}

pragma solidity ^0.5.15;

library ECVerify {
    function ecrecovery(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0x0);
        }

        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecrecovery(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecverify(
        bytes32 hash,
        bytes memory sig,
        address signer
    ) public pure returns (bool) {
        return signer == ecrecovery(hash, sig);
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
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";

library RollupUtils {
    // ---------- Account Related Utils -------------------
    function PDALeafToHash(Types.PDALeaf memory _PDA_Leaf)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_PDA_Leaf.pubkey));
    }

    // returns a new User Account with updated balance
    function UpdateBalanceInAccount(
        Types.UserAccount memory original_account,
        uint256 new_balance
    ) public pure returns (Types.UserAccount memory updated_account) {
        original_account.balance = new_balance;
        return original_account;
    }

    function BalanceFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (uint256)
    {
        return account.balance;
    }

    // AccountFromBytes decodes the bytes to account
    function AccountFromBytes(bytes memory accountBytes)
        public
        pure
        returns (
            uint256 ID,
            uint256 balance,
            uint256 nonce,
            uint256 tokenType
        )
    {
        return abi.decode(accountBytes, (uint256, uint256, uint256, uint256));
    }

    //
    // BytesFromAccount and BytesFromAccountDeconstructed do the same thing i.e encode account to bytes
    //
    function BytesFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (bytes memory)
    {
        bytes memory data = abi.encodePacked(
            account.ID,
            account.balance,
            account.nonce,
            account.tokenType
        );

        return data;
    }

    function BytesFromAccountDeconstructed(
        uint256 ID,
        uint256 balance,
        uint256 nonce,
        uint256 tokenType
    ) public pure returns (bytes memory) {
        return abi.encodePacked(ID, balance, nonce, tokenType);
    }

    //
    // HashFromAccount and getAccountHash do the same thing i.e hash account
    //
    function getAccountHash(
        uint256 id,
        uint256 balance,
        uint256 nonce,
        uint256 tokenType
    ) public pure returns (bytes32) {
        return
            keccak256(
                BytesFromAccountDeconstructed(id, balance, nonce, tokenType)
            );
    }

    function HashFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                BytesFromAccountDeconstructed(
                    account.ID,
                    account.balance,
                    account.nonce,
                    account.tokenType
                )
            );
    }

    // ---------- Tx Related Utils -------------------
    function CompressTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encode(_tx.fromIndex, _tx.toIndex, _tx.amount, _tx.signature);
    }

    function DecompressTx(bytes memory txBytes)
        public
        pure
        returns (
            uint256 from,
            uint256 to,
            uint256 nonce,
            bytes memory sig
        )
    {
        return abi.decode(txBytes, (uint256, uint256, uint256, bytes));
    }

    function CompressTxWithMessage(bytes memory message, bytes memory sig)
        public
        pure
        returns (bytes memory)
    {
        Types.Transaction memory _tx = TxFromBytes(message);
        return abi.encode(_tx.fromIndex, _tx.toIndex, _tx.amount, sig);
    }

    // Decoding transaction from bytes
    function TxFromBytesDeconstructed(bytes memory txBytes)
        public
        pure
        returns (
            uint256 from,
            uint256 to,
            uint256 tokenType,
            uint256 nonce,
            uint256 txType,
            uint256 amount
        )
    {
        return
            abi.decode(
                txBytes,
                (uint256, uint256, uint256, uint256, uint256, uint256)
            );
    }

    function TxFromBytes(bytes memory txBytes)
        public
        pure
        returns (Types.Transaction memory)
    {
        Types.Transaction memory transaction;
        (
            transaction.fromIndex,
            transaction.toIndex,
            transaction.tokenType,
            transaction.nonce,
            transaction.txType,
            transaction.amount
        ) = abi.decode(
            txBytes,
            (uint256, uint256, uint256, uint256, uint256, uint256)
        );
        return transaction;
    }

    //
    // BytesFromTx and BytesFromTxDeconstructed do the same thing i.e encode transaction to bytes
    //
    function BytesFromTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _tx.fromIndex,
                _tx.toIndex,
                _tx.tokenType,
                _tx.nonce,
                _tx.txType,
                _tx.amount
            );
    }

    function BytesFromTxDeconstructed(
        uint256 from,
        uint256 to,
        uint256 tokenType,
        uint256 nonce,
        uint256 txType,
        uint256 amount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(from, to, tokenType, nonce, txType, amount);
    }

    //
    // HashFromTx and getTxSignBytes do the same thing i.e get the tx data to be signed
    //
    function HashFromTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                BytesFromTxDeconstructed(
                    _tx.fromIndex,
                    _tx.toIndex,
                    _tx.tokenType,
                    _tx.nonce,
                    _tx.txType,
                    _tx.amount
                )
            );
    }

    function getTxSignBytes(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 tokenType,
        uint256 txType,
        uint256 nonce,
        uint256 amount
    ) public pure returns (bytes32) {
        return
            keccak256(
                BytesFromTxDeconstructed(
                    fromIndex,
                    toIndex,
                    tokenType,
                    nonce,
                    txType,
                    amount
                )
            );
    }

    /**
     * @notice Calculates the address from the pubkey
     * @param pub is the pubkey
     * @return Returns the address that has been calculated from the pubkey
     */
    function calculateAddress(bytes memory pub)
        public
        pure
        returns (address addr)
    {
        bytes32 hash = keccak256(pub);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }

    function GetGenesisLeaves() public view returns (bytes32[2] memory leaves) {
        Types.UserAccount memory account1 = Types.UserAccount({
            ID: 0,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        Types.UserAccount memory account2 = Types.UserAccount({
            ID: 1,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        leaves[0] = HashFromAccount(account1);
        leaves[1] = HashFromAccount(account2);
    }

    function GetGenesisDataBlocks()
        public
        view
        returns (bytes[2] memory dataBlocks)
    {
        Types.UserAccount memory account1 = Types.UserAccount({
            ID: 0,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        Types.UserAccount memory account2 = Types.UserAccount({
            ID: 1,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        dataBlocks[0] = BytesFromAccount(account1);
        dataBlocks[1] = BytesFromAccount(account2);
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

