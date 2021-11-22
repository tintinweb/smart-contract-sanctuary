// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../../shared/ProtocolConstants.sol";

import "../../interfaces/tokens/converter/IConverter.sol";
import "../../interfaces/tokens/vesting/ILinearVesting.sol";

/**
 * @dev Implementation of the {IConverter} interface.
 *
 * A simple converter contract that allows users to convert
 * their Vether tokens by "burning" them (See {convert}) to
 * acquire their equivalent Vader tokens based on the constant
 * {VADER_VETHER_CONVERSION_RATE}.
 *
 * The contract assumes that it has been sufficiently funded with
 * Vader tokens and will fail to execute trades if it has not been
 * done so yet.
 */
contract Converter is IConverter, ProtocolConstants {
    /* ========== LIBRARIES ========== */

    // Using MerkleProof for validating claims
    using MerkleProof for bytes32[];

    /* ========== STATE VARIABLES ========== */

    // The VETHER token
    IERC20 public immutable vether;

    // The VADER token
    IERC20 public immutable vader;

    // The VADER vesting contract
    ILinearVesting public vesting;

    // The merkle proof root for validating claims
    bytes32 public root;

    // Unique deployment salt
    uint256 public immutable salt;

    // Signals whether a particular leaf has been claimed of the merkle proof
    mapping(bytes32 => bool) public claimed;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes the contract's {vether} and {vader} addresses.
     *
     * Performs rudimentary checks to ensure that the variables haven't
     * been declared incorrectly.
     */
    constructor(
        IERC20 _vether,
        IERC20 _vader,
        bytes32 _root,
        uint256 _salt
    ) {
        require(
            _vether != IERC20(_ZERO_ADDRESS) && _vader != IERC20(_ZERO_ADDRESS),
            "Converter::constructor: Misconfiguration"
        );

        vether = _vether;
        vader = _vader;

        root = _root;
        salt = _salt;
    }

    function setRoot(bytes32 _root) external {
        root = _root;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /*
     * @dev Sets address of vesting contract.
     *
     * The LinearVesting and Converter contracts are dependent upon
     * eachother, hence this setter is introduced.
     *
     * Also approves Vesting to spend Vader tokens on its behalf.
     *
     * Requirements:
     * - only owner can call it.
     **/
    function setVesting(ILinearVesting _vesting) external {
        require(
            vesting == ILinearVesting(_ZERO_ADDRESS),
            "Converter::setVesting: Vesting is already set"
        );
        require(
            _vesting != ILinearVesting(_ZERO_ADDRESS),
            "Converter::setVesting: Cannot Set Zero Vesting Address"
        );
        vader.approve(address(_vesting), type(uint256).max);
        vesting = _vesting;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows a user to convert their Vether to Vader.
     *
     * Emits a {Conversion} event indicating the amount of Vether the user
     * "burned" and the amount of Vader that they acquired.
     *
     * Here, "burned" refers to the action of transferring them to an irrecoverable
     * address, the {BURN} address.
     *
     * Requirements:
     *
     * - the caller has approved the contract for the necessary amount via Vether
     * - the amount specified is non-zero
     * - the contract has been supplied with the necessary Vader amount to fulfill the trade
     */
    function convert(bytes32[] calldata proof, uint256 amount)
        external
        override
        returns (uint256 vaderReceived)
    {
        require(
            amount != 0,
            "Converter::convert: Non-Zero Conversion Amount Required"
        );

        ILinearVesting _vesting = vesting;

        require(
            _vesting != ILinearVesting(_ZERO_ADDRESS),
            "Converter::convert: Vesting is not set"
        );

        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, amount, salt, getChainId())
        );
        require(
            !claimed[leaf] && proof.verify(root, leaf),
            "Converter::convert: Incorrect Proof Provided"
        );
        claimed[leaf] = true;

        uint256 allowance = vether.allowance(msg.sender, address(this));

        amount = amount > allowance ? allowance : amount;

        uint256 balanceBefore = vether.balanceOf(_BURN);
        vether.transferFrom(msg.sender, _BURN, amount);
        amount = vether.balanceOf(_BURN) - balanceBefore;

        vaderReceived = amount * _VADER_VETHER_CONVERSION_RATE;

        emit Conversion(msg.sender, amount, vaderReceived);

        uint256 half = vaderReceived / 2;
        vader.transfer(msg.sender, half);
        _vesting.vestFor(msg.sender, vaderReceived - half);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    /*
     * @dev Returns the {chainId} of current network.
     **/
    function getChainId() public view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

abstract contract ProtocolConstants {
    /* ========== GENERAL ========== */

    // The zero address, utility
    address internal constant _ZERO_ADDRESS = address(0);

    // One year, utility
    uint256 internal constant _ONE_YEAR = 365 days;

    // Basis Points
    uint256 internal constant _MAX_BASIS_POINTS = 100_00;

    /* ========== VADER TOKEN ========== */

    // Max VADER supply
    uint256 internal constant _INITIAL_VADER_SUPPLY = 25_000_000_000 * 1 ether;

    // Allocation for VETH holders
    uint256 internal constant _VETH_ALLOCATION = 7_500_000_000 * 1 ether;

    // Team allocation vested over {VESTING_DURATION} years
    uint256 internal constant _TEAM_ALLOCATION = 2_500_000_000 * 1 ether;

    // Ecosystem growth fund unlocked for partnerships & USDV provision
    uint256 internal constant _ECOSYSTEM_GROWTH = 2_500_000_000 * 1 ether;

    // Total grant tokens
    uint256 internal constant _GRANT_ALLOCATION = 12_500_000_000 * 1 ether;

    // Emission Era
    uint256 internal constant _EMISSION_ERA = 24 hours;

    // Initial Emission Curve, 5
    uint256 internal constant _INITIAL_EMISSION_CURVE = 5;

    // Fee Basis Points
    uint256 internal constant _MAX_FEE_BASIS_POINTS = 1_00;

    /* ========== VESTING ========== */

    // Vesting Duration
    uint256 internal constant _VESTING_DURATION = 2 * _ONE_YEAR;

    /* ========== CONVERTER ========== */

    // Vader -> Vether Conversion Rate (1000:1)
    uint256 internal constant _VADER_VETHER_CONVERSION_RATE = 10_000;

    // Burn Address
    address internal constant _BURN =
        0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD;

    /* ========== SWAP QUEUE ========== */

    // A minimum of 10 swaps will be executed per block
    uint256 internal constant _MIN_SWAPS_EXECUTED = 10;

    // Expressed in basis points (50%)
    uint256 internal constant _DEFAULT_SWAPS_EXECUTED = 50_00;

    // The queue size of each block is 100 units
    uint256 internal constant _QUEUE_SIZE = 100;

    /* ========== GAS QUEUE ========== */

    // Address of Chainlink Fast Gas Price Oracle
    address internal constant _FAST_GAS_ORACLE =
        0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    /* ========== VADER RESERVE ========== */

    // Minimum delay between grants
    uint256 internal constant _GRANT_DELAY = 30 days;

    // Maximum grant size divisor
    uint256 internal constant _MAX_GRANT_BASIS_POINTS = 10_00;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface ILinearVesting {
    /* ========== STRUCTS ========== */

    // Struct of a vesting member, tight-packed to 256-bits
    struct Vester {
        uint192 amount;
        uint64 lastClaim;
        uint128 start;
        uint128 end;
    }

    /* ========== FUNCTIONS ========== */

    function getClaim(address _vester)
        external
        view
        returns (uint256 vestedAmount);

    function claim() external returns (uint256 vestedAmount);

    //    function claimConverted() external returns (uint256 vestedAmount);

    function begin(address[] calldata vesters, uint192[] calldata amounts)
        external;

    function vestFor(address user, uint256 amount) external;

    /* ========== EVENTS ========== */

    event VestingInitialized(uint256 duration);

    event VestingCreated(address user, uint256 amount);

    event Vested(address indexed from, uint256 amount);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface IConverter {
    /* ========== FUNCTIONS ========== */

    function convert(bytes32[] calldata proof, uint256 amount)
        external
        returns (uint256 vaderReceived);

    /* ========== EVENTS ========== */

    event Conversion(
        address indexed user,
        uint256 vetherAmount,
        uint256 vaderAmount
    );
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
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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
        return msg.data;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}