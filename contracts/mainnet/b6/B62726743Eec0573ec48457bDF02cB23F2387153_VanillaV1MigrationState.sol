// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVanillaV1MigrationState, IVanillaV1Converter} from "./interfaces/IVanillaV1Migration01.sol";

/// @title The contract keeping the record of VNL v1 -> v1.1 migration state
contract VanillaV1MigrationState is IVanillaV1MigrationState {

    address private immutable owner;

    /// @inheritdoc IVanillaV1MigrationState
    bytes32 public override stateRoot;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override blockNumber;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override conversionDeadline;

    /// @dev the conversion deadline is initialized to 30 days from the deployment
    /// @param migrationOwner The address of the owner of migration state
    constructor(address migrationOwner) {
        owner = migrationOwner;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier beforeDeadline() {
        if (block.timestamp >= conversionDeadline) {
            revert MigrationStateUpdateDisabled();
        }
        _;
    }

    /// @inheritdoc IVanillaV1MigrationState
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) onlyOwner beforeDeadline external override {
        stateRoot = newStateRoot;
        blockNumber = blockNum;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    /// @inheritdoc IVanillaV1MigrationState
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view override returns (bool) {
        // deliberately using encodePacked with a delimiter string to resolve ambiguity and let client implementations be simpler
        bytes32 leafInTree = keccak256(abi.encodePacked(tokenOwner, ":", amount));
        return block.timestamp < conversionDeadline && MerkleProof.verify(proof, stateRoot, leafInTree);
    }

}

/// @title Conversion functionality for migrating VNL v1 tokens to VNL v1.1
abstract contract VanillaV1Converter is IVanillaV1Converter {
    /// @inheritdoc IVanillaV1Converter
    IVanillaV1MigrationState public override migrationState;
    IERC20 internal vnl;

    constructor(IVanillaV1MigrationState _state, IERC20 _VNLv1) {
        migrationState = _state;
        vnl = _VNLv1;
    }

    function mintConverted(address target, uint256 amount) internal virtual;


    /// @inheritdoc IVanillaV1Converter
    function checkEligibility(bytes32[] memory proof) external view override returns (bool convertible, bool transferable) {
        uint256 balance = vnl.balanceOf(msg.sender);

        convertible = migrationState.verifyEligibility(proof, msg.sender, balance);
        transferable = balance > 0 && vnl.allowance(msg.sender, address(this)) >= balance;
    }

    /// @inheritdoc IVanillaV1Converter
    function convertVNL(bytes32[] memory proof) external override {
        if (block.timestamp >= migrationState.conversionDeadline()) {
            revert ConversionWindowClosed();
        }

        uint256 convertedAmount = vnl.balanceOf(msg.sender);
        if (convertedAmount == 0) {
            revert NoConvertibleVNL();
        }

        // because VanillaV1Token01's cannot be burned, the conversion just locks them into this contract permanently
        address freezer = address(this);
        uint256 previouslyFrozen = vnl.balanceOf(freezer);

        // we know that OpenZeppelin ERC20 returns always true and reverts on failure, so no need to check the return value
        vnl.transferFrom(msg.sender, freezer, convertedAmount);

        // These should never fail as we know precisely how VanillaV1Token01.transferFrom is implemented
        if (vnl.balanceOf(freezer) != previouslyFrozen + convertedAmount) {
            revert FreezerBalanceMismatch();
        }
        if (vnl.balanceOf(msg.sender) > 0) {
            revert UnexpectedTokensAfterConversion();
        }

        if (!migrationState.verifyEligibility(proof, msg.sender, convertedAmount)) {
            revert VerificationFailed();
        }

        // finally let implementor to mint the converted amount of tokens and log the event
        mintConverted(msg.sender, convertedAmount);
        emit VNLConverted(msg.sender, convertedAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IVanillaV1MigrationState {

    /// @notice The current Merkle tree root for checking the eligibility for token conversion
    /// @dev tree leaves are tuples of (VNLv1-owner-address, VNLv1-token-balance), ordered as keccak256(abi.encodePacked(tokenOwner, ":", amount))
    function stateRoot() external view returns (bytes32);

    /// @notice Gets the block.number which was used to calculate the `stateRoot()` (for off-chain verification)
    function blockNumber() external view returns (uint64);

    /// @notice Gets the current deadline for conversion as block.timestamp
    function conversionDeadline() external view returns (uint64);

    /// @notice Checks if `tokenOwner` owning `amount` of VNL v1s is eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing,
    /// leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @param tokenOwner The address owning the VanillaV1Token01 tokens
    /// @param amount The amount of VanillaV1Token01 tokens (i.e. the balance of the tokenowner)
    /// @return true iff `tokenOwner` is eligible to convert `amount` tokens to VanillaV1Token02
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view returns (bool);

    /// @notice Updates the Merkle tree for provable ownership of convertible VNL v1 tokens. Only for the owner.
    /// @dev Moves also the internal deadline forward 30 days
    /// @param newStateRoot The new Merkle tree root for checking the eligibility for token conversion
    /// @param blockNum The block.number whose state was used to calculate the `newStateRoot`
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) external;

    /// @notice thrown if non-owners try to modify state
    error UnauthorizedAccess();

    /// @notice thrown if attempting to update migration state after conversion deadline
    error MigrationStateUpdateDisabled();
}

interface IVanillaV1Converter {
    /// @notice Gets the address of the migration state contract
    function migrationState() external view returns (IVanillaV1MigrationState);

    /// @dev Emitted when VNL v1.01 is converted to v1.02
    /// @param converter The owner of tokens.
    /// @param amount Number of converted tokens.
    event VNLConverted(address converter, uint256 amount);

    /// @notice Checks if all `msg.sender`s VanillaV1Token01's are eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @return convertible true if `msg.sender` is eligible to convert all VanillaV1Token01 tokens to VanillaV1Token02 and conversion window is open
    /// @return transferable true if `msg.sender`'s VanillaV1Token01 tokens are ready to be transferred for conversion
    function checkEligibility(bytes32[] memory proof) external view returns (bool convertible, bool transferable);

    /// @notice Converts _ALL_ `msg.sender`s VanillaV1Token01's to VanillaV1Token02 if eligible. The conversion is irreversible.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    function convertVNL(bytes32[] memory proof) external;

    /// @notice thrown when attempting to convert VNL after deadline
    error ConversionWindowClosed();

    /// @notice thrown when attempting to convert 0 VNL
    error NoConvertibleVNL();

    /// @notice thrown if for some reason VNL freezer balance doesn't match the transferred amount + old balance
    error FreezerBalanceMismatch();

    /// @notice thrown if for some reason user holds VNL v1 tokens after conversion (i.e. transfer failed)
    error UnexpectedTokensAfterConversion();

    /// @notice thrown if user provided incorrect proof for conversion eligibility
    error VerificationFailed();
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}