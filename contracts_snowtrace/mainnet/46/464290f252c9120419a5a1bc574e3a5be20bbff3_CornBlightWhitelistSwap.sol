/**
 *Submitted for verification at snowtrace.io on 2021-12-20
*/

/**
 *Submitted for verification at snowtrace.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT

/**
 * XXX
 * 𝗖𝗼𝗻𝘁𝗿𝗮𝗰𝘁 𝗼𝗿𝗶𝗴𝗶𝗻𝗮𝗹𝗹𝘆 𝗰𝗿𝗲𝗮𝘁𝗲𝗱 𝗯𝘆 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆 𝗗𝗲𝘃
 * 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆: 𝗮𝗻 𝗶𝗻𝗻𝗼𝘃𝗮𝘁𝗶𝘃𝗲 𝗗𝗲𝗙𝗶 𝗽𝗿𝗼𝘁𝗼𝗰𝗼𝗹 𝗳𝗼𝗿 𝗬𝗶𝗲𝗹𝗱 𝗙𝗮𝗿𝗺𝗶𝗻𝗴 𝗼𝗻 𝗔𝘃𝗮𝗹𝗮𝗻𝗰𝗵𝗲
 * 
 * 𝗟𝗶𝗻𝗸𝘀:
 * 𝗵𝘁𝘁𝗽𝘀://𝗳𝗮𝗿𝗺𝗲𝗿𝘀𝗼𝗻𝗹𝘆.𝗳𝗮𝗿𝗺
 * 𝗵𝘁𝘁𝗽𝘀://𝘁.𝗺𝗲/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝟮
 * 𝗵𝘁𝘁𝗽𝘀://𝘁𝘄𝗶𝘁𝘁𝗲𝗿.𝗰𝗼𝗺/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝗗𝗲𝗙𝗶
 * XXX
 */

pragma solidity ^0.8.10;

// File [email protected]
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

// File [email protected]
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

// File [email protected]
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
abstract contract ReentrancyGuard {
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

    constructor() {
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

// File [email protected]
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

// File [email protected]
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

        
    𝑮𝑼𝒀 𝑾𝑯𝑶 𝑩𝑳𝑰𝑵𝑫𝑳𝒀 𝑭𝑶𝑹𝑲𝑬𝑫 𝑻𝑯𝑬 𝑪𝑶𝑵𝑻𝑹𝑨𝑪𝑻
                    |
                   |
                  |
                 V
                    
        
 /     \             \            /    \       
|       |             \          |      |      
|       `.             |         |       :     
`        F             |        \|       |     
 \       | /       /  \\\   --__ \\       :    
  \      \/   _--~~          ~--__| A     |      
   \      \_-~                    ~-_\    |    
    \_     R        _.--------.______\|   |    
      \     \______// _ ___ _ (_(__>  \   |    
       \   .  C ___)  ______ (_(____>  M  /    
       /\ |   C ____)/      \ (_____>  |_/     
      / /\|   C_____)       |  (___>   /  \    
     |   E   _C_____)\______/  // _/ /     \   
     |    \  |__   \\_________// (__/       |  
    | \    \____)   `----   --'             R  
    |  \_          ___\       /_          _/ | 
   S              /    |     |  \            | 
   |             |    /       \  \           | 
   |          / /    O         |  \           |
   |         / /      \__/\___/    N          |
  |           /        |    |       |         |
  L          |         |    |       |         Y
                      
                      
                       ^
                      /
                    / 
                  /
            𝑭𝑨𝑹𝑴𝑬𝑹𝑺𝑶𝑵𝑳𝒀 𝑫𝑬𝑽'𝒔 𝑩𝑰𝑮 𝑩𝑶𝒀


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

// File [email protected]
/**
 * XXX
 * 𝗖𝗼𝗻𝘁𝗿𝗮𝗰𝘁 𝗼𝗿𝗶𝗴𝗶𝗻𝗮𝗹𝗹𝘆 𝗰𝗿𝗲𝗮𝘁𝗲𝗱 𝗯𝘆 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆 𝗗𝗲𝘃
 * 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆: 𝗮𝗻 𝗶𝗻𝗻𝗼𝘃𝗮𝘁𝗶𝘃𝗲 𝗗𝗲𝗙𝗶 𝗽𝗿𝗼𝘁𝗼𝗰𝗼𝗹 𝗳𝗼𝗿 𝗬𝗶𝗲𝗹𝗱 𝗙𝗮𝗿𝗺𝗶𝗻𝗴 𝗼𝗻 𝗔𝘃𝗮𝗹𝗮𝗻𝗰𝗵𝗲
 * 
 * 𝗟𝗶𝗻𝗸𝘀:
 * 𝗵𝘁𝘁𝗽𝘀://𝗳𝗮𝗿𝗺𝗲𝗿𝘀𝗼𝗻𝗹𝘆.𝗳𝗮𝗿𝗺
 * 𝗵𝘁𝘁𝗽𝘀://𝘁.𝗺𝗲/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝟮
 * 𝗵𝘁𝘁𝗽𝘀://𝘁𝘄𝗶𝘁𝘁𝗲𝗿.𝗰𝗼𝗺/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝗗𝗲𝗙𝗶
 * XXX
 */
contract CornBlightWhitelistSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    IERC20 public immutable token;
    IERC20 public immutable whitelist;
    address public immutable devAddress;
    
    constructor (
        IERC20 _whitelist,
        IERC20 _token
        ){
            whitelist = _whitelist;
            token = _token;
            devAddress = msg.sender;
        }

    function swap() nonReentrant public {
        require(token.balanceOf(msg.sender) >= 500000000000000000000, "swap: you haven't got enough tokens to swap");
        require(whitelist.balanceOf(address(this)) >= 1000000000000000000, "swap: contract hasn't got enough WhitelistToken to swap");

        token.transferFrom(msg.sender, devAddress, 500000000000000000000);
        whitelist.transfer(msg.sender, 1000000000000000000);
    }
}