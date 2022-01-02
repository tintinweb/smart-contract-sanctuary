// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ClaimTokens is Ownable{
    using SafeMath for uint256;
    IERC20 public token; // token to be claimed.
    mapping(address => bool) public claimed; // if true it means claimed, if false nothing claimed.
    bool public canClaim = false;
    bool public threeMonthsInitialized = false;
    bool public sixMonthsInitialized = false;
    mapping (address => uint256) private _threeMonthsLock;
    mapping (address => uint256) private _sixMonthsLock;
    uint256 public initializedTime = 0; 
    uint256 public  totalTokenToBeClaimed   = 0;
    
    constructor(){
        // main net BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        // test net 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47
        token = IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47);
        canClaim = false;
        threeMonthsInitialized = false;
        sixMonthsInitialized = false;
        totalTokenToBeClaimed   = 0;
        
    }

    function initialize(address tokenAddres) external onlyOwner {
        require(threeMonthsInitialized == true, "Tokens are not Added");
        require(sixMonthsInitialized == true, "Tokens are not Added");
        require(initializedTime < 1, 'Can not reinitialize');
        initializedTime = block.timestamp;
        token = IERC20(tokenAddres);
        canClaim = true;
    }

    modifier threeMonthsOnly() {
        require(
            initializedTime + 5 minutes >= block.timestamp,
            "Tokens are not unlocked"
        );
        _;
    }

    modifier sixMonthsOnly() {
        require(initializedTime + 10 minutes >= block.timestamp, "Tokens are not unlocked");
        _;
    }

    function addThreeMonthsLockTokens(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length < 501, "Only 500 address at a time");
        require(_recipients.length == _amounts.length, "Number of recipients not the same as the number of amounts");
        threeMonthsInitialized = true;
        for (uint256 index = 0; index < _recipients.length; index++) {
            if (_threeMonthsLock[_recipients[index]]<1) {
                _threeMonthsLock[_recipients[index]] = _amounts[index];
                totalTokenToBeClaimed = totalTokenToBeClaimed + _amounts[index];
            }
        }

    }

    function addSixMonthsLockTokens(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length < 501, "Only 500 address at a time");
        require(_recipients.length == _amounts.length, "Number of recipients not the same as the number of amounts");
        sixMonthsInitialized = true;
        for (uint256 index = 0; index < _recipients.length; index++) {
            if (_sixMonthsLock[_recipients[index]]<1) {
                _sixMonthsLock[_recipients[index]] = _amounts[index];
                totalTokenToBeClaimed = totalTokenToBeClaimed + _amounts[index];
            }
        }
    }

    function updateThreeMonthsLockTokens(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length < 501, "Only 500 address at a time");
        require(_recipients.length == _amounts.length, "Number of recipients not the same as the number of amounts");
        for (uint256 index = 0; index < _recipients.length; index++) {
            _threeMonthsLock[_recipients[index]] = _threeMonthsLock[_recipients[index]] + _amounts[index];
            totalTokenToBeClaimed = totalTokenToBeClaimed + _amounts[index];
        }

    }

    function updateSixMonthsLockTokens(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length < 501, "Only 500 address at a time");
        require(_recipients.length == _amounts.length, "Number of recipients not the same as the number of amounts");
        for (uint256 index = 0; index < _recipients.length; index++) {
            _sixMonthsLock[_recipients[index]] = _sixMonthsLock[_recipients[index]] + _amounts[index];
            totalTokenToBeClaimed = totalTokenToBeClaimed + _amounts[index];
        }
    }

     function checkThreeMonthsLockTokens(address  _recipients) external view returns (uint256) {
       return _threeMonthsLock[_recipients];

    }

    function checkSixMonthsLockTokens(address  _recipients) external view returns (uint256) {
       return _sixMonthsLock[_recipients];

    }

    function claimThreeMonthLockTokens() external threeMonthsOnly {
        require(canClaim == true, "claim not available yet");
        require(claimed[msg.sender] == false, "Already claimed");
        require( _threeMonthsLock[msg.sender] > 0, "Already claimed");
        uint256 tokenToTransfer = _threeMonthsLock[msg.sender];
        require(IERC20(token).balanceOf(address(this)) > tokenToTransfer, "insufficient tokens in contract");
        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        _threeMonthsLock[msg.sender] = 0;
        IERC20(token).transfer(msg.sender,tokenToTransfer);
        totalTokenToBeClaimed = totalTokenToBeClaimed - tokenToTransfer; 
    }

     function claimSixMonthLockTokens() external threeMonthsOnly {
        require(canClaim == true, "claim not available yet");
        require(claimed[msg.sender] == false, "Already claimed");
        require( _sixMonthsLock[msg.sender] > 0, "Already claimed");
       
        uint256 tokenToTransfer = _sixMonthsLock[msg.sender];
        require(IERC20(token).balanceOf(address(this)) > tokenToTransfer, "insufficient tokens in contract");
        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        _sixMonthsLock[msg.sender] = 0;
        IERC20(token).transfer(msg.sender,tokenToTransfer);
        totalTokenToBeClaimed = totalTokenToBeClaimed - tokenToTransfer; 
    }

     function remainingTokens() external view returns (uint256) {
       return IERC20(token).balanceOf(address(this));

    }

    function recoverToken(address _to) external onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        require(_contractBalance > 0);
        _sent = IERC20(token).transfer(_to, _contractBalance);
        totalTokenToBeClaimed = 0; 
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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