// SPDX-License-Identifier: MIT
/*                 | |                            | |      
**   __ _ _ __   __| |_ __ ___  _ __ ___   ___  __| | __ _ 
**  / _` | '_ \ / _` | '__/ _ \| '_ ` _ \ / _ \/ _` |/ _` |
** | (_| | | | | (_| | | | (_) | | | | | |  __/ (_| | (_| |
**  \__,_|_| |_|\__,_|_|  \___/|_| |_| |_|\___|\__,_|\__,_|
*/
pragma solidity ^0.6.12;
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract Andromeda is Ownable {
    
    using SafeMath for uint;
    
    address payable public top = 0x036908228b1c3Ab35C48212398B9d469A8D6F886;
    address[] empty;
    struct User {
        address payable inviter;
        address payable self;
        address[] myReferred;
    }
    mapping(address => User) public tree;

    constructor() public {
        tree[top] = User(top, top, empty);
    }

    function enter(address payable inviter) external payable {
        require(msg.value == 0.25 ether, "Debes enviar 0.25 ETH");
        require(tree[msg.sender].inviter == address(0), "No puedes registrarte más de una vez con el mismo patrocinador");
        require(tree[inviter].self == inviter, "Ese patrocinador no existe");
        require(tree[inviter].myReferred.length < 90, "Tu patrocinador ya alcanzó su máximo de invitados");
        
        tree[msg.sender] = User(inviter, msg.sender, empty);
        tree[inviter].myReferred.push(msg.sender);
        
        if (
            tree[inviter].myReferred.length == 3 || 
            tree[inviter].myReferred.length == 6 ||
            tree[inviter].myReferred.length == 9 ||
            tree[inviter].myReferred.length == 10 ||
            tree[inviter].myReferred.length == 12 ||
            tree[inviter].myReferred.length == 15 ||
            tree[inviter].myReferred.length == 18 ||
            tree[inviter].myReferred.length == 19 ||
            tree[inviter].myReferred.length == 21 ||
            tree[inviter].myReferred.length == 24 || 
            tree[inviter].myReferred.length == 27 ||
            tree[inviter].myReferred.length == 28 ||
            tree[inviter].myReferred.length == 30 ||
            tree[inviter].myReferred.length == 33 ||
            tree[inviter].myReferred.length == 36 ||
            tree[inviter].myReferred.length == 37 ||
            tree[inviter].myReferred.length == 39 ||
            tree[inviter].myReferred.length == 42 ||
            tree[inviter].myReferred.length == 45 ||
            tree[inviter].myReferred.length == 46 ||
            tree[inviter].myReferred.length == 48 ||
            tree[inviter].myReferred.length == 51 ||
            tree[inviter].myReferred.length == 54 ||
            tree[inviter].myReferred.length == 55 ||
            tree[inviter].myReferred.length == 57 ||
            tree[inviter].myReferred.length == 60 ||
            tree[inviter].myReferred.length == 63 ||
            tree[inviter].myReferred.length == 64 ||
            tree[inviter].myReferred.length == 66 ||
            tree[inviter].myReferred.length == 69 ||
            tree[inviter].myReferred.length == 72 ||
            tree[inviter].myReferred.length == 73 ||
            tree[inviter].myReferred.length == 75 ||
            tree[inviter].myReferred.length == 78 ||
            tree[inviter].myReferred.length == 81 ||
            tree[inviter].myReferred.length == 82 ||
            tree[inviter].myReferred.length == 84 ||
            tree[inviter].myReferred.length == 87 ||
            tree[inviter].myReferred.length == 90 
            ) {
                inviter.transfer (0.125 ether);
                top.transfer (0.125 ether); 
        } else {
                inviter.transfer (0.175 ether);
                top.transfer (0.075 ether); 
        }
    }
    
    function ReferredNumber(address consultado) external view returns(uint) {
        return tree[consultado].myReferred.length;
    }
    function ReferredList(address consultado) external view returns(address[] memory) {
        return tree[consultado].myReferred;
    }
    
    function send() public onlyOwner payable {
        top.transfer(address(this).balance);
    }  
}