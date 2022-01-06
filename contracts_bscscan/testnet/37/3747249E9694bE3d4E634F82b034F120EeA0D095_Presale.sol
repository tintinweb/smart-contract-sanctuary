// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable{
    using SafeMath for uint256;
    uint256 private _minUserCap;
    uint256 private _maxUserCap;
    uint256 private _rateNumerator;
    uint256 private _rateDenominator;
    uint256 private _weiRaised;
    uint256 public totalToken;
    uint256 private _hardCap;
    uint256 private _openingTime;
    uint256 private _closingTime;
    mapping(address => uint256) private _balances;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, address referral, uint256 BNBvalue, uint256 amountToken);

    constructor(
        uint256 rateNumerator,
        uint256 rateDenominator,
        uint256 hardCap,
        uint256 minUserCap,
        uint256 maxUserCap,
        uint256 openingTime,
        uint256 closingTime
    ) public{
        require(rateNumerator > 0, "rateNumerator is 0");
        require(rateDenominator > 0, "rateDenominator is 0");
        require(hardCap > 0, "hard cap is 0");
        require(openingTime > 0, "opening time is 0");
        require(closingTime > openingTime, "opening time is not before closing time");
        _rateNumerator = rateNumerator;
        _rateDenominator = rateDenominator;
        _hardCap = hardCap;
        _minUserCap = minUserCap;
        _maxUserCap = maxUserCap;
        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    receive() external payable{
        if(msg.value > 0){
            buyTokens(address(0));
        }
    }

    modifier onlyWhileOpen {
        require(isOpen(), "not open");
        _;
    }

    function hardCap() public view returns (uint256) {
        return _hardCap;
    }

    function setHardCap(uint cap) external onlyOwner {
        _hardCap = cap;
    }

    function minUserCap() public view returns(uint256){
        return _minUserCap;
    }

    function setMinUserCap(uint cap) external onlyOwner{
        _minUserCap = cap;
    }

    function maxUserCap() public view returns(uint256){
        return _maxUserCap;
    }

    function setMaxUserCap(uint cap) external onlyOwner{
        _maxUserCap = cap;
    }

    function capReached() public view returns (bool) {
        return _weiRaised >= _hardCap;
    }

    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    function setOpeningTime(uint256 time) external onlyOwner{
        _openingTime = time;
    }

    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    function setClosingTime(uint time) external onlyOwner{
        _closingTime = time;
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > _closingTime;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function rateNumerator() public view returns (uint256) {
        return _rateNumerator;
    }

    function setRateNumerator(uint rate) external onlyOwner{
        _rateNumerator = rate;
    }

    function rateDenominator() public view returns (uint256) {
        return _rateDenominator;
    }

    function setRateDenominator(uint rate) external onlyOwner{
        _rateDenominator = rate;
    }

    function withdrawBNB(address to, uint256 amount) external onlyOwner{
        payable(to).call{value:amount}("");
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _toBNB(uint tokenAmount) private view returns(uint){
        return tokenAmount.mul(rateNumerator()).div(rateDenominator());
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) virtual internal onlyWhileOpen view {
        require(beneficiary != address(0), "beneficiary is the zero address");
        require(weiAmount > 0, "weiAmount is 0");
        require(_weiRaised.add(weiAmount) <= _hardCap, "cap exceeded");
        uint currentBNB = _toBNB(_balances[beneficiary]);
        require(currentBNB.add(weiAmount) <= _maxUserCap, "beneficiary's cap exceeded");
        require(currentBNB.add(weiAmount) >= _minUserCap, "beneficiary's cap minimal required");
    }

    function getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(_rateDenominator).div(_rateNumerator);
    }

    function buyTokens(address referral) payable public {
        address beneficiary = _msgSender();
        uint weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokenAmount = getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        totalToken = totalToken.add(tokenAmount);
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        emit TokensPurchased(_msgSender(), beneficiary, referral, weiAmount, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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