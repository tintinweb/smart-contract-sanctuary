/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// File: contracts/zeppelin/math/SafeMath.sol

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

// File: contracts/zeppelin/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/zeppelin/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/AllowTokens.sol

pragma solidity >=0.4.21 <0.6.0;



contract AllowTokens is Ownable {
    using SafeMath for uint256;

    address constant private NULL_ADDRESS = address(0);

    mapping (address => bool) public allowedTokens;
    bool private validateAllowedTokens;
    uint256 private maxTokensAllowed;
    uint256 private minTokensAllowed;
    uint256 public dailyLimit;

    event AllowedTokenAdded(address indexed _tokenAddress);
    event AllowedTokenRemoved(address indexed _tokenAddress);
    event AllowedTokenValidation(bool _enabled);
    event MaxTokensAllowedChanged(uint256 _maxTokens);
    event MinTokensAllowedChanged(uint256 _minTokens);
    event DailyLimitChanged(uint256 dailyLimit);

    modifier notNull(address _address) {
        require(_address != NULL_ADDRESS, "AllowTokens: Address cannot be empty");
        _;
    }

    constructor(address _manager) public  {
        transferOwnership(_manager);
        validateAllowedTokens = true;
        maxTokensAllowed = 10000 ether;
        minTokensAllowed = 1 ether;
        dailyLimit = 100000 ether;
    }

    function isValidatingAllowedTokens() external view returns(bool) {
        return validateAllowedTokens;
    }

    function getMaxTokensAllowed() external view returns(uint256) {
        return maxTokensAllowed;
    }

    function getMinTokensAllowed() external view returns(uint256) {
        return minTokensAllowed;
    }

    function allowedTokenExist(address token) private view notNull(token) returns (bool) {
        return allowedTokens[token];
    }

    function isTokenAllowed(address token) public view notNull(token) returns (bool) {
        if (validateAllowedTokens) {
            return allowedTokenExist(token);
        }
        return true;
    }

    function addAllowedToken(address token) external onlyOwner {
        require(!allowedTokenExist(token), "AllowTokens: Token already exists in allowedTokens");
        allowedTokens[token] = true;
        emit AllowedTokenAdded(token);
    }

    function removeAllowedToken(address token) external onlyOwner {
        require(allowedTokenExist(token), "AllowTokens: Token does not exis  in allowedTokenst");
        allowedTokens[token] = false;
        emit AllowedTokenRemoved(token);
    }

    function enableAllowedTokensValidation() external onlyOwner {
        validateAllowedTokens = true;
        emit AllowedTokenValidation(validateAllowedTokens);
    }

    function disableAllowedTokensValidation() external onlyOwner {
        // Before disabling Allowed Tokens Validations some kind of contract validation system
        // should be implemented on the Bridge for the methods receiveTokens, tokenFallback and tokensReceived
        validateAllowedTokens = false;
        emit AllowedTokenValidation(validateAllowedTokens);
    }

    function setMaxTokensAllowed(uint256 maxTokens) external onlyOwner {
        require(maxTokens >= minTokensAllowed, "AllowTokens: Max Tokens should be equal or bigger than Min Tokens");
        maxTokensAllowed = maxTokens;
        emit MaxTokensAllowedChanged(maxTokensAllowed);
    }

    function setMinTokensAllowed(uint256 minTokens) external onlyOwner {
        require(maxTokensAllowed >= minTokens, "AllowTokens: Min Tokens should be equal or smaller than Max Tokens");
        minTokensAllowed = minTokens;
        emit MinTokensAllowedChanged(minTokensAllowed);
    }

    function changeDailyLimit(uint256 _dailyLimit) external onlyOwner {
        require(_dailyLimit >= maxTokensAllowed, "AllowTokens: Daily Limit should be equal or bigger than Max Tokens");
        dailyLimit = _dailyLimit;
        emit DailyLimitChanged(_dailyLimit);
    }

    // solium-disable-next-line max-len
    function isValidTokenTransfer(address tokenToUse, uint amount, uint spentToday, bool isSideToken) external view returns (bool) {
        if(amount > maxTokensAllowed)
            return false;
        if(amount < minTokensAllowed)
            return false;
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;
        if(!isSideToken && !isTokenAllowed(tokenToUse))
            return false;
        return true;
    }

    function calcMaxWithdraw(uint spentToday) external view returns (uint) {
        uint maxWithrow = dailyLimit - spentToday;
        if (dailyLimit < spentToday)
            return 0;
        if(maxWithrow > maxTokensAllowed)
            maxWithrow = maxTokensAllowed;
        return maxWithrow;
    }

}