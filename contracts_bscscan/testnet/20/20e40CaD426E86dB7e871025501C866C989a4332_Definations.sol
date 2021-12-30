//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/RequireUtils.sol";

contract Definations is Ownable {
    using SafeMath for uint256;

    //events
    event UpdateExcludeFee(address account, bool isExcluded);
    event UpdateBlacklist(address account, bool isExcluded);
    event TransferFeeChanged(Fee oldFee, Fee newFee);
    event SwappingFeeChanged(Fee oldFee, Fee newFee);
    event MarketingWalletAddressChanged(address oldAddress, address newAddress);
    event DevWalletAddressChanged(address oldAddress, address newAddress);

    //maps
    mapping(address => bool) excludedFeeAccounts;
    mapping(address => bool) blacklistAccounts;

    //contract parameters
    string private _name;

    //addresses
    address public _marketingWalletAddress;
    address public _devWalletAddress;

    //structs
    struct Fee {
        uint256 divident;
        uint256 devAndMarketing;
        uint256 liquidity;
    }

    //initial fee definations
    Fee private swappingFees =
        Fee({divident: 8, devAndMarketing: 3, liquidity: 4});

    Fee private transfeFees =
        Fee({divident: 3, devAndMarketing: 1, liquidity: 1});

    constructor(
        string memory name,
        address marketingWalletAddress,
        address devWalletAddress
    ) {
        _name = name;
        _marketingWalletAddress = marketingWalletAddress;
        _devWalletAddress = devWalletAddress;
    }

    function getSwappingFees() external view returns (Fee memory) {
        return swappingFees;
    }

    function getTransferFees() external view returns (Fee memory) {
        return transfeFees;
    }

    function getName() external view returns (string memory) {
        return _name;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return excludedFeeAccounts[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklistAccounts[account];
    }

    //update methods

    function updateMarketingWalletAddress(address newAddress)
        external
        onlyOwner
    {
        RequireUtils.addressNewValueCannotBeSame(
            _marketingWalletAddress,
            newAddress
        );

        emit MarketingWalletAddressChanged(_marketingWalletAddress, newAddress);
        _marketingWalletAddress = newAddress;
    }

    function updateDevWalletAddress(address newAddress) external onlyOwner {
        RequireUtils.addressNewValueCannotBeSame(_devWalletAddress, newAddress);
        emit DevWalletAddressChanged(_devWalletAddress, newAddress);
        _devWalletAddress = newAddress;
    }

    function updateBlacklist(address[] memory addresses, bool newValue)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (blacklistAccounts[addresses[i]] != newValue) {
                blacklistAccounts[addresses[i]] = newValue;
                emit UpdateBlacklist(addresses[i], newValue);
            }
        }
    }

    function updateExcludedFeeAccounts(
        address[] memory addresses,
        bool newValue
    ) external onlyOwner {
        _updateExcludedFeeAccounts(addresses, newValue);
    }

    function _updateExcludedFeeAccounts(
        address[] memory addresses,
        bool newValue
    ) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (excludedFeeAccounts[addresses[i]] != newValue) {
                excludedFeeAccounts[addresses[i]] = newValue;
                emit UpdateExcludeFee(addresses[i], newValue);
            }
        }
    }

    function updateSwappingFees(
        uint256 divident,
        uint256 devAndMarketing,
        uint256 liquidty
    ) external onlyOwner {
        Fee memory oldFee = swappingFees;
        swappingFees = Fee({
            divident: divident,
            devAndMarketing: devAndMarketing,
            liquidity: liquidty
        });
        emit SwappingFeeChanged(oldFee, swappingFees);
    }

    function updateTransferFees(
        uint256 divident,
        uint256 devAndMarketing,
        uint256 liquidty
    ) external onlyOwner {
        Fee memory oldFee = transfeFees;
        transfeFees = Fee({
            divident: divident,
            devAndMarketing: devAndMarketing,
            liquidity: liquidty
        });
        emit SwappingFeeChanged(oldFee, transfeFees);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

library RequireUtils {
    function uint256NewValueCannotBeSame(
        uint256 requiredField,
        uint256 newValue
    ) internal pure {
        require(
            requiredField != newValue,
            "New Value cannot be same with old value"
        );
    }

    function addressNewValueCannotBeSame(address oldAddress, address newAddress)
        internal
        pure
    {
        require(
            oldAddress != newAddress,
            "New address cannot be same with old address"
        );
    }

    function checkValueExistsInMap(
        mapping(address => bool) storage referenceMap,
        address a
    ) internal view {
        require(referenceMap[a] == false, "Already added!");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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