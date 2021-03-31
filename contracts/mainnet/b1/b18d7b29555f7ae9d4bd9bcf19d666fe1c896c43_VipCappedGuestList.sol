/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// Dependency file: /Users/starfish/code/badger-system/deps/@openzeppelin/contracts/cryptography/MerkleProof.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
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


// Dependency file: /Users/starfish/code/badger-system/deps/@openzeppelin/contracts/math/SafeMath.sol


// pragma solidity ^0.6.0;

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


// Dependency file: /Users/starfish/code/badger-system/interfaces/yearn/GuestlistApi.sol

// pragma solidity >=0.6.0 <0.7.0;
// pragma solidity >=0.6.0 <0.7.0;

interface GuestListAPI {
    function authorized(address guest, uint256 amount) external view returns (bool);
}

// Dependency file: /Users/starfish/code/badger-system/deps/@openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: /Users/starfish/code/badger-system/interfaces/yearn/VaultAPI.sol

// pragma solidity >=0.6.0 <0.7.0;

// import "/Users/starfish/code/badger-system/deps/@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function guestList() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function setDepositLimit(uint256 limit) external;

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    function setGuestList(address guestList) external;

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

// Root file: contracts/yearn/VipCappedGuestList.sol

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

// import "/Users/starfish/code/badger-system/deps/@openzeppelin/contracts/cryptography/MerkleProof.sol";
// import "/Users/starfish/code/badger-system/deps/@openzeppelin/contracts/math/SafeMath.sol";
// import "/Users/starfish/code/badger-system/interfaces/yearn/GuestlistApi.sol";
// import "/Users/starfish/code/badger-system/interfaces/yearn/VaultAPI.sol";

/**
 * @notice A basic guest list contract for testing.
 * @dev For a Vyper implementation of this contract containing additional
 * functionality, see https://github.com/banteg/guest-list/blob/master/contracts/GuestList.vy
 * The bouncer can invite arbitrary guests
 * A guest can be added permissionlessly with proof of inclusion in current merkle set
 * The bouncer can change the merkle root at any time
 * Merkle-based permission that has been claimed cannot be revoked permissionlessly.
 * Any guests can be revoked by the bouncer at-will
 * The TVL cap is based on the number of want tokens in the underlying vaults.
 * This can only be made more permissive over time. If decreased, existing TVL is maintained and no deposits are possible until the TVL has gone below the threshold
 * A variant of the yearn AffiliateToken that supports guest list control of deposits
 * A guest list that gates access by merkle root and a TVL cap
 */
contract VipCappedGuestList {
    using SafeMath for uint256;

    address public vault;
    address public bouncer;

    bytes32 public guestRoot;
    uint256 public userDepositCap;

    mapping(address => bool) public guests;

    event ProveInvitation(address indexed account, bytes32 indexed guestRoot);
    event SetGuestRoot(bytes32 indexed guestRoot);
    event SetUserDepositCap(uint256 cap);

    /**
     * @notice Create the test guest list, setting the message sender as
     * `bouncer`.
     * @dev Note that since this is just for testing, you're unable to change
     * `bouncer`.
     */
    constructor(address vault_) public {
        vault = vault_;
        bouncer = msg.sender;
    }

    /**
     * @notice Invite guests or kick them from the party.
     * @param _guests The guests to add or update.
     * @param _invited A flag for each guest at the matching index, inviting or
     * uninviting the guest.
     */
    function setGuests(address[] calldata _guests, bool[] calldata _invited) external {
        require(msg.sender == bouncer, "onlyBouncer");
        _setGuests(_guests, _invited);
    }

    function vaultBalance(address user) public view returns (uint256) {
        return (VaultAPI(vault).balanceOf(user).mul(VaultAPI(vault).pricePerShare())).div((10**VaultAPI(vault).decimals()));
    }

    function remainingDepositAllowed(address user) public view returns (uint256) {
        return userDepositCap - vaultBalance(user);
    }

    /**
     * @notice Permissionly prove an address is included in the current merkle root, thereby granting access
     * @notice Note that the list is designed to ONLY EXPAND in future instances
     * @notice The admin does retain the ability to ban individual addresses
     */
    function proveInvitation(address account, bytes32[] calldata merkleProof) external {
        // Verify Merkle Proof
        bytes32 node = keccak256(abi.encode(account));
        require(MerkleProof.verify(merkleProof, guestRoot, node), "Invalid merkle proof.");

        address[] memory accounts = new address[](1);
        bool[] memory invited = new bool[](1);

        accounts[0] = account;
        invited[0] = true;

        _setGuests(accounts, invited);

        emit ProveInvitation(account, guestRoot);
    }

    /**
     * @notice Set the merkle root to verify invitation proofs against.
     * @notice Note that accounts not included in the root will still be invited if their inviation was previously approved.
     */
    function setGuestRoot(bytes32 guestRoot_) external {
        require(msg.sender == bouncer, "onlyBouncer");
        guestRoot = guestRoot_;

        emit SetGuestRoot(guestRoot);
    }

    /**
     * @notice Set the merkle root to verify invitation proofs against.
     * @notice Note that accounts not included in the root will still be invited if their inviation was previously approved.
     */
    function setUserDepositCap(uint256 cap_) external {
        require(msg.sender == bouncer, "onlyBouncer");
        userDepositCap = cap_;

        emit SetUserDepositCap(userDepositCap);
    }

    /**
     * @notice Check if a guest with a bag of a certain size is allowed into
     * the party.
     * @dev Note that `_amount` isn't checked to keep test setup simple, since
     * from the vault tests' perspective this is a pass/fail call anyway.
     * @param _guest The guest's address to check.
     */
    function authorized(address _guest, uint256 _amount) external view returns (bool) {
        return guests[_guest] && (vaultBalance(_guest) + _amount <= userDepositCap);
    }

    function _setGuests(address[] memory _guests, bool[] memory _invited) internal {
        require(_guests.length == _invited.length);
        for (uint256 i = 0; i < _guests.length; i++) {
            if (_guests[i] == address(0)) {
                break;
            }
            guests[_guests[i]] = _invited[i];
        }
    }
}