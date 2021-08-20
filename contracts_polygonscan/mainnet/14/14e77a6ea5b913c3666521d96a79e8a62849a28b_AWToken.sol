/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

/***
 *        _                                              __      __                  
 *       /_\   __ __ __  ___   ___  ___   _ __    ___    \ \    / /  __ _   _ _   ___
 *      / _ \  \ V  V / / -_) (_-< / _ \ | '  \  / -_)    \ \/\/ /  / _` | | '_| (_-<
 *     /_/ \_\  \_/\_/  \___| /__/ \___/ |_|_|_| \___|     \_/\_/   \__,_| |_|   /__/
 *
 * 
 *  Project: Awesome Wars
 *  Website: https://awesomewars.com/
 *  Contract: AW Token Contract (Version 3)
 *  
 *  Description: AW is the ERC20 coin on which our NFT game is based. You can use AW to upgrade NFTs, buy addons and provide liquidity on AW/MATIC pools.
 * 
 */

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
     * @dev Burns `burnQuantity` tokens from from the caller's account.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 burnQuantity) external returns (bool);


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


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library SafeMath16 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            uint16 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint16 a, uint16 b) internal pure returns (bool, uint16) {
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
    function tryMul(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint16 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint16 a, uint16 b) internal pure returns (bool, uint16) {
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
    function tryMod(uint16 a, uint16 b) internal pure returns (bool, uint16) {
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
    function add(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function sub(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
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
    function mod(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library SafeMath32 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            uint32 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint32 a, uint32 b) internal pure returns (bool, uint32) {
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
    function tryMul(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint32 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint32 a, uint32 b) internal pure returns (bool, uint32) {
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
    function tryMod(uint32 a, uint32 b) internal pure returns (bool, uint32) {
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
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
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
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
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
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
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
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
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
    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
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
    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
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
    function mod(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IFA is IERC721, IERC721Enumerable {
    function _increaseWins(uint16 tokenId) external;
    function _increaseLosses(uint16 tokenId) external;
    function isBanned(uint16 tokenId) external view returns (bool);
    function getStats_scU(uint16 _id) external view returns (uint32, uint32, uint32, uint32, uint32, uint32);
    function getStamina(uint16 tokenId) external view returns (uint32);
    function getBirthday(uint16 tokenId) external view returns (uint256);
    function getDNA(uint16 tokenId) external view returns (uint32);
    function getRarity(uint16 tokenId) external view returns (uint32);
    function getWinCount(uint16 tokenId) external view returns (uint32);
    function getLossCount(uint16 tokenId) external view returns (uint32);
    
    //old
    function getLife(uint16 _id) external view returns (uint32);
    function getArmour(uint16 _id) external view returns (uint32);
    function getAttack(uint16 _id) external view returns (uint32); 
    function getDefence(uint16 _id) external view returns (uint32);
    function getMagic(uint16 _id) external view returns (uint32);
    function getLuck(uint16 _id) external view returns (uint32);
}


interface IFAAD is IERC721, IERC721Enumerable {
    function newBattlePoints(uint16 _fromId, uint16 _toId) external view returns (uint32);
    function getAddonArray(uint32 _addonId) external view returns (uint16, uint32);
}
 
/**
 * @dev Implementation of the {IERC20} interface. 
 *
 */
contract AWToken is Context, IERC20Metadata, Ownable { 
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint16 => uint256) private _lastHarvest;
    
    mapping (uint16 => uint16) public nftBattleCount;
    mapping (uint16 => uint256) public nftBattleEndTime;
    mapping (uint16 => uint256) public totalTokensWon;
    mapping (address => uint256) public buffEndTime;
    
    address private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _nftAddress;
    address private _nftAddonsAddress;
    address private _tournamentContract;
    address private _additionalContract1;
    address private _additionalContract2;
    address private _pool;
     
    uint256 public WIN_REWARD = 1000000000000000000;
    uint256 public LOSE_REWARD = 100000000000000000;
    uint256 public TOKENS_PER_DAY = 1000000000000000000;
    uint256 public WINS_BONUS = 10;
    uint256 public capLP = 50;
    uint256 public BATTLE_PENALTY = 10;
    uint256 public BUFF_BONUS = 20;
    uint256 public BUFF_COST = 2000000000000000000;
    
    uint[2] public LOW_EMISSIONS_CAP = [250000000000000000000000, 500000000000000000000000];
    uint[2] public LOW_EMISSIONS_PERC = [50, 95];
    
    uint public constant SECONDS_PER_DAY = 86400;
    bool public gamePaused; 
    
    uint16[3] public farmCap = [10, 30, 50]; 
    uint16[3] public farmBonus = [10, 15, 20];
    uint16[3] public winCap = [100, 300, 500];
    uint16[3] public winBonus = [10, 15, 20];

    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    
    event BattleCompleted(uint16 indexed _fromId, uint16 indexed _toId, bool _outcome);
    
    /**
     * @dev Sets the values for {name}, {symbol} and {owner}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply_;
        _balances[msg.sender] = initialSupply_;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, initialSupply_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        //uint256 currentAllowance = _allowances[sender][_msgSender()];
        //require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        //_approve(sender, _msgSender(), currentAllowance - amount);
        if ((msg.sender != _nftAddress) && (msg.sender != _nftAddonsAddress) && (msg.sender != _tournamentContract) && (msg.sender != _additionalContract1) && (msg.sender != _additionalContract2)) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!gamePaused, "Game paused by admin");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        if (totalSupply() > LOW_EMISSIONS_CAP[1])
            amount -= (amount * LOW_EMISSIONS_PERC[1]).div(100);
        else if (totalSupply() > LOW_EMISSIONS_CAP[0])
            amount -= (amount * LOW_EMISSIONS_PERC[0]).div(100);

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(!gamePaused, "Game paused by admin");
         
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    /**
     * @dev Burns a quantity of tokens held by the caller.
     *
     * Emits an {Transfer} event to 0 address
     *
     */
    function burn(uint256 burnQuantity) public virtual override returns (bool) {
        _burn(msg.sender, burnQuantity);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(!gamePaused, "Game paused by admin");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Set NFT address
     */
    function setNFTContractAddress(address nftAddress) public onlyOwner{
        _nftAddress = nftAddress;
    }
    
    /**
     * @dev Set Addon address 
     */
    function setNFTAddonsContractAddress(address nftAddonsAddress) public onlyOwner{
       _nftAddonsAddress = nftAddonsAddress;
    }
    
     /**
     * @dev Set LP address
     */
    function setLP(address LPAddress) public onlyOwner{
        _pool = LPAddress;
    }
    
     /**
     * @dev Set additional contract 1 address
     */
    function setAdditionalContract1Address (address contractAddress) public onlyOwner{
        _additionalContract1 = contractAddress;
    }
    
    /**
     * @dev Set additional contract 2 address
     */
    function setAdditionalContract2Address (address contractAddress) public onlyOwner{
        _additionalContract2 = contractAddress;
    }
    
    /**
     * @dev Set tournament contract address 
     */
    function setTournamentContractAddress (address contractAddress) public onlyOwner{
        _tournamentContract = contractAddress;
    }
    
    /**
     * @dev Check LP tokens
     */
    function lpTokens(address _playerAddress) public view returns (uint) {
        return IERC20(_pool).balanceOf(_playerAddress).div(1000000000000000000);
    }
    
    /**
     * @dev Logic of the battle between 2 NFTs with addons. _fromId is the initiator of the battle.
     *      Returns true if the initiator wins, false otherwise.
     */
    function newBattleFA(uint16 _fromId, uint16 _toId) internal returns(bool){
        
        //LP bonus 
        uint _LPsFrom = lpTokens(IFA(_nftAddress).ownerOf(_fromId));
        uint _LPsTo = lpTokens(IFA(_nftAddress).ownerOf(_toId));
        if (_LPsFrom > capLP)
            _LPsFrom = capLP;
        if (_LPsTo > capLP)
            _LPsTo = capLP;
        
        //winCount bonus    
        uint _winsBonusFrom;    
        uint _winsBonusTo;    
        if (IFA(_nftAddress).getWinCount(_fromId) > IFA(_nftAddress).getWinCount(_toId))
            _winsBonusFrom = WINS_BONUS;
        else
            _winsBonusTo = WINS_BONUS;
        
        //buff bonus    
        uint _buffBonusFrom;    
        uint _buffBonusTo;    
        if(buffEndTime[msg.sender] >= block.timestamp)
            _buffBonusFrom = BUFF_BONUS;
        if(buffEndTime[IFA(_nftAddress).ownerOf(_toId)] >= block.timestamp)
            _buffBonusTo = BUFF_BONUS;    
        
        if ((IFAAD(_nftAddonsAddress).newBattlePoints(_fromId, _toId) + _LPsFrom + _winsBonusFrom + _buffBonusFrom) >= (IFAAD(_nftAddonsAddress).newBattlePoints(_toId, _fromId) + _LPsTo + _winsBonusTo + _buffBonusTo)) {
            IFA(_nftAddress)._increaseWins(_fromId);
            IFA(_nftAddress)._increaseLosses(_toId);
            _mint(IFA(_nftAddress).ownerOf(_fromId), WIN_REWARD); 
            _mint(IFA(_nftAddress).ownerOf(_toId), LOSE_REWARD);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(WIN_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(LOSE_REWARD));
            return true;
        } else {
            IFA(_nftAddress)._increaseWins(_toId);
            IFA(_nftAddress)._increaseLosses(_fromId);
            _mint(IFA(_nftAddress).ownerOf(_fromId), LOSE_REWARD); 
            _mint(IFA(_nftAddress).ownerOf(_toId), WIN_REWARD);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(LOSE_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(WIN_REWARD));
            return false;
        }
    } 
    
    /**
     * @dev Returns a random NFT id, different from the _Id input.
     */
    function getRandomNFTId(uint16 _Id, uint nonce) internal view returns (uint16) {
        require(_Id < IFA(_nftAddress).totalSupply());
        bool success;
        uint randomNFTId;
        uint _seed;
        
        for(uint16 i=0;i<50;i++)
        {
            randomNFTId = uint(keccak256(abi.encodePacked(block.timestamp, _seed, nonce))).mod(IFA(_nftAddress).totalSupply());
            if(randomNFTId == _Id)
            {
                _seed = _seed.add(1);
            }
            else
            {
                success = true;
                break;
            }
        }
        
        require(success, "Try again");
        return uint16(randomNFTId);
    }
    
    /**
     * @dev Callable battle function.
     */
    function battle_V9A(uint16 _fromId, uint nonce) public returns (bool) {
        require(msg.sender == IFA(_nftAddress).ownerOf(_fromId));
        require(!IFA(_nftAddress).isBanned(_fromId),"This NFT is banned");
        require(!gamePaused, "Game paused by admin");
        
        if(nftBattleEndTime[_fromId] >= block.timestamp )
        {
            require(nftBattleCount[_fromId] <  IFA(_nftAddress).getStamina(_fromId), "Enough battles for today");
            nftBattleCount[_fromId] = nftBattleCount[_fromId].add(1);
        }
        else
        {
            nftBattleEndTime[_fromId] = block.timestamp.add(SECONDS_PER_DAY);
            nftBattleCount[_fromId] = 1;
        }   

        uint16 _toId = getRandomNFTId(_fromId, nonce);
        bool battleResult = newBattleFA(_fromId, _toId);
        emit BattleCompleted(_fromId, _toId, battleResult);
        return battleResult;
    }
    
    /**
     * @dev Logic of the battle between 2 NFTs with addons for multi-battle. _fromId is the initiator of the battle.
     *      Returns true if the initiator wins, false otherwise.
     */
    function newBattleFAMulti(uint16 _fromId, uint16 _toId) internal returns(bool) {
        //LP bonus
        uint _LPsFrom = lpTokens(IFA(_nftAddress).ownerOf(_fromId));
        uint _LPsTo = lpTokens(IFA(_nftAddress).ownerOf(_toId));
        if (_LPsFrom > capLP)
            _LPsFrom = capLP;
        if (_LPsTo > capLP)
            _LPsTo = capLP;
        
        //winCount bonus
        uint _winsBonusFrom;    
        uint _winsBonusTo;    
        if (IFA(_nftAddress).getWinCount(_fromId) > IFA(_nftAddress).getWinCount(_toId))
            _winsBonusFrom = WINS_BONUS;
        else
            _winsBonusTo = WINS_BONUS;
            
        //buff bonus
        uint _buffBonusFrom;    
        uint _buffBonusTo;    
        if(buffEndTime[msg.sender] >= block.timestamp)
            _buffBonusFrom = BUFF_BONUS;
        if(buffEndTime[IFA(_nftAddress).ownerOf(_toId)] >= block.timestamp)
            _buffBonusTo = BUFF_BONUS;    
            
        if ((IFAAD(_nftAddonsAddress).newBattlePoints(_fromId, _toId) + _LPsFrom + _winsBonusFrom + _buffBonusFrom) >= (IFAAD(_nftAddonsAddress).newBattlePoints(_toId, _fromId) + _LPsTo + _winsBonusTo + _buffBonusTo)) {
            IFA(_nftAddress)._increaseWins(_fromId); 
            IFA(_nftAddress)._increaseLosses(_toId);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(WIN_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(LOSE_REWARD));
            _mint(IFA(_nftAddress).ownerOf(_toId), LOSE_REWARD);
            return true;
        } else {
            IFA(_nftAddress)._increaseWins(_toId);
            IFA(_nftAddress)._increaseLosses(_fromId);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(LOSE_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(WIN_REWARD));
            _mint(IFA(_nftAddress).ownerOf(_toId), WIN_REWARD);
            return false;
        }
    } 
    
    /**
     * @dev Optimized callable battle function for multi-battle.
     */
    function battleMulti(uint16 _fromId, uint nonce) internal returns (bool) {
        require(!gamePaused, "Game paused by admin");
        
        if(nftBattleEndTime[_fromId] >= block.timestamp )
        {
            require(nftBattleCount[_fromId] <  IFA(_nftAddress).getStamina(_fromId), "Enough battles for today");
            nftBattleCount[_fromId] = nftBattleCount[_fromId].add(1);
        }
        else
        {
            nftBattleEndTime[_fromId] = block.timestamp.add(SECONDS_PER_DAY);
            nftBattleCount[_fromId] = 1;
        }   

        uint16 _toId = getRandomNFTId(_fromId, nonce);
        bool battleResult = newBattleFAMulti(_fromId, _toId);
        emit BattleCompleted(_fromId, _toId, battleResult);
        return battleResult;
    }
    
    /**
     * @dev Optimized multi-battle.
     */
    function battleAll_Hn5(uint16[] memory tokenIds) public {
        uint _toMint;
        bool outcome;
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IFA(_nftAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint16 tokenIndex = tokenIds[i];
            require(IFA(_nftAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            require(!IFA(_nftAddress).isBanned(tokenIndex),"This NFT is banned");
            
            if(nftBattleEndTime[tokenIndex] >= block.timestamp )
            {   
                if(nftBattleCount[tokenIndex] <  IFA(_nftAddress).getStamina(tokenIndex))
                {
                    uint difference = IFA(_nftAddress).getStamina(tokenIndex).sub(nftBattleCount[tokenIndex]);
                    for (uint k = 0; k < difference; k++)
                    {    
                        outcome = battleMulti(tokenIndex, k);
                        if (outcome)
                            _toMint += WIN_REWARD;
                        else
                            _toMint += LOSE_REWARD;
                    }
                }
            }
            else
            {
                for (uint k = 0; k < IFA(_nftAddress).getStamina(tokenIndex); k++)
                {    
                        outcome = battleMulti(tokenIndex, k);
                        if (outcome)
                            _toMint += WIN_REWARD;
                        else
                            _toMint += LOSE_REWARD;
                }
            }
        }
        _mint(IFA(_nftAddress).ownerOf(tokenIds[0]), _toMint);
    }
    
    /**
     * @dev Mints daily tokens assigned to a NFT. Returns the minted quantity.
     */
    function harvestTokens_l3Y(uint16[] memory tokenIds) public returns (uint256) {
        require(!gamePaused, "Game paused by admin");
        uint256 totalHarvestQty = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IFA(_nftAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint16 tokenIndex = tokenIds[i];
            require(IFA(_nftAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            require(!IFA(_nftAddress).isBanned(tokenIndex),"This NFT is banned");

            uint256 harvestQty = tokensToHarvest(tokenIndex); 
            if (harvestQty != 0) {
                totalTokensWon[tokenIndex] = totalTokensWon[tokenIndex].add(harvestQty);
                totalHarvestQty = totalHarvestQty.add(harvestQty);
                _lastHarvest[tokenIndex] = block.timestamp;
            }
        }

        require(totalHarvestQty != 0, "Nothing to harvest");
        
        //LP bonus
        uint _LPs = lpTokens(IFA(_nftAddress).ownerOf(tokenIds[0]));
        if (_LPs > farmCap[2])
            totalHarvestQty = totalHarvestQty + (totalHarvestQty * farmBonus[2]).mod(100);  
        else if (_LPs > farmCap[1])
            totalHarvestQty = totalHarvestQty + (totalHarvestQty * farmBonus[1]).mod(100); 
        else if (_LPs > farmCap[0])
            totalHarvestQty = totalHarvestQty + (totalHarvestQty * farmBonus[0]).mod(100);
            
        //buff bonus
        if(buffEndTime[msg.sender] >= block.timestamp)
            totalHarvestQty = totalHarvestQty + (totalHarvestQty * BUFF_BONUS).mod(100);   
        
        _mint(msg.sender, totalHarvestQty); 
        return totalHarvestQty;
    }
   
    /**
     * @dev Measures daily tokens assigned to a NFT, that are ready to be harvested.
     */
    function tokensToHarvest(uint16 tokenIndex) internal view returns (uint256) {
        require(IFA(_nftAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IFA(_nftAddress).totalSupply(), "NFT has not been minted yet");
        uint256 lastHarvested;
        if (_lastHarvest[tokenIndex]==0)
            lastHarvested = IFA(_nftAddress).getBirthday(tokenIndex); 
        else
            lastHarvested = _lastHarvest[tokenIndex];
        
        uint256 totalAccumulated = (block.timestamp).sub(lastHarvested).mul(TOKENS_PER_DAY).div(SECONDS_PER_DAY);
            
        //winCount bonus
        if (IFA(_nftAddress).getWinCount(tokenIndex) > winCap[2])
            totalAccumulated = totalAccumulated + (totalAccumulated * winBonus[2]).mod(100);
        else if (IFA(_nftAddress).getWinCount(tokenIndex) > winCap[1])
            totalAccumulated = totalAccumulated + (totalAccumulated * winBonus[1]).mod(100);    
        else if (IFA(_nftAddress).getWinCount(tokenIndex) > winCap[0])
            totalAccumulated = totalAccumulated + (totalAccumulated * winBonus[0]).mod(100);    
            
        //battle penalty - at least 1 battle in the last 2 days
         if (nftBattleEndTime[tokenIndex].add(SECONDS_PER_DAY) >= block.timestamp)
            return totalAccumulated;
        else     
            return totalAccumulated.div(BATTLE_PENALTY);
    }
    
     /**
     * @dev Measures daily tokens assigned to a NFT array that are ready to be harvested.
     */
    function tokensArrayToHarvest(uint16[] memory tokenIds) public view returns (uint256) {
        uint256 totalSum;
        for (uint i = 0; i < tokenIds.length; i++)
           totalSum = totalSum.add(tokensToHarvest(tokenIds[i]));
    
        return totalSum;
    }
    
    /**
     * @dev Modifies win reward
     */
    function modifyBattleReward(uint _winReward, uint _loseReward) public onlyOwner {
        WIN_REWARD = _winReward;
        LOSE_REWARD = _loseReward;
    }
    
    /**
     * @dev Modifies daily reward
     */
    function modifyDailyReward(uint _dailyReward) public onlyOwner {
        TOKENS_PER_DAY = _dailyReward;
    }
    
    /**
     * @dev Modifies wins bonus
     */
    function modifyWinsBonus(uint _newBonus) public onlyOwner {
        WINS_BONUS = _newBonus;
    }
    
    /**
     * @dev Modifies LP cap
     */
    function modifyLPCap(uint _newCapLP) public onlyOwner {
        capLP = _newCapLP;
    }
    
    /**
     * @dev Modifies farm Cap
     */
    function modifyFarmCap(uint16[3] memory _newFarmCap) public onlyOwner {
        farmCap = _newFarmCap;
    }
    
    /**
     * @dev Modifies farm Bonus
     */
    function modifyFarmBonus(uint16[3] memory _newBonus) public onlyOwner {
        farmBonus = _newBonus;
    }
    
    /**
     * @dev Modifies win Cap
     */
    function modifyWinCap(uint16[3] memory _newWinCap) public onlyOwner {
        winCap = _newWinCap;
    }
    
    /**
     * @dev Modifies win Bonus
     */
    function modifyWinBonus(uint16[3] memory _newBonus) public onlyOwner {
        winBonus = _newBonus;
    }
    
    /**
     * @dev Modifies low emissions cap
     */
    function modifyLowEmissionsCap(uint[2] memory _newCap) public onlyOwner {
        LOW_EMISSIONS_CAP = _newCap;
    }
    
     /**
     * @dev Modifies low emissions percent
     */
    function modifyLowEmissionsPerc(uint[2] memory _newPerc) public onlyOwner {
        LOW_EMISSIONS_PERC = _newPerc;
    }
    
    /**
     * @dev Modifies battle penalty 
     */
    function modifyBattlePenalty(uint _newPenalty) public onlyOwner {
        BATTLE_PENALTY = _newPenalty;
    }
    
    /**
     * @dev Pauses game for future updates
     */
    function switchGamePaused() public onlyOwner {
        if (gamePaused == false){
            gamePaused = true;
        }
        else{
            gamePaused = false;  
        }
    }
    
    /**
     * @dev Buffs and NFT
     */
    function getBuff() public {
        require(balanceOf(msg.sender) >= BUFF_COST, "Not enough AW");
        require(buffEndTime[msg.sender] <= block.timestamp, "Still under buff");
        increaseAllowance(address(this), BUFF_COST);
        burn(BUFF_COST);
        buffEndTime[msg.sender] = block.timestamp.add(SECONDS_PER_DAY);
    }
    
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}