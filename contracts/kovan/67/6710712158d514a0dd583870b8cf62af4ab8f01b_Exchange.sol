/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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

// File: contracts/ExchangeAdminStorage.sol

pragma solidity ^0.6.12;


contract ExchangeAdminStorage is Ownable{

    address public admin;

    address public pendingAdmin;

    address public implementation;
}

// File: contracts/ExchangeStorage.sol

pragma solidity ^0.6.12;


contract ExchangeStorage is ExchangeAdminStorage{

    struct PoolInfo{
        address lpToken;
        uint256 exchangeRate;
        uint256 totalAmount;
        uint256 totalAmountLimit;
    }

    struct UserInfo{
        uint256 amount;
        uint256 accSashimi;
        uint256 unconfirmAmount;
        uint256 timestamp;
    }

    uint256 public constant secondsPerDay = 86400;

    uint256 public constant confirmTimeLimit = 3600; //10 days

    uint256 public constant depositTimeLimit = 7200; // 90 days

    uint256 public startTime;

    uint256 public endTime;

    address public SASHIMI;

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(address => bool) public badAddresses;

    bool public paused;

    event Deposit(address indexed user, uint256 indexed pid, address lpToken, uint256 amount);
}

// File: contracts/Exchange.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;




contract Exchange is ExchangeStorage {
    using SafeMath for uint256;

    event Paused(address account);
    event Unpaused(address account);

    modifier onlyAdmin() {
        require(admin == msg.sender, "Caller is not the admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function initialize(
        address _sashimi,
        uint256 _startTime
    ) external  {
        require(admin == msg.sender, "UNAUTHORIZED");
        require(SASHIMI == address(0), "ALREADY INITIALIZED");
        SASHIMI = _sashimi;
        startTime = _startTime;
        endTime = _startTime.add(secondsPerDay);
        paused = false;
    }

    function addExchangeInfo(address[] memory lpTokens, uint256[] memory rates, uint256[] memory totalAmountLimits) external onlyAdmin{
        uint256 length = lpTokens.length;
        require(length == rates.length && length == totalAmountLimits.length, "Invalid length");
        for(uint256 i = 0; i < length; i++){
            poolInfo.push(PoolInfo({
                lpToken: lpTokens[i],
                exchangeRate: rates[i],
                totalAmount: 0,
                totalAmountLimit: totalAmountLimits[i]
            }));
        }
    }

    function deposit(uint256 pid, uint256 amount) external whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp.sub(startTime) <= depositTimeLimit, "Invalid Time");
        require(msg.sender == tx.origin, "Invalid sender");
        require(!badAddresses[msg.sender], "Bad address");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        IERC20(pool.lpToken).transferFrom(msg.sender, address(this), amount);
        user.unconfirmAmount = user.unconfirmAmount.add(amount);
        user.timestamp = block.timestamp;
        emit Deposit(msg.sender, pid, pool.lpToken, amount);
    }

    function accSashimi(uint256 pid) external whenNotPaused{
        require(block.timestamp >= startTime, "Invalid Time");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        if(user.unconfirmAmount > 0 && block.timestamp.sub(user.timestamp) > confirmTimeLimit && !badAddresses[msg.sender] &&
        pool.totalAmount.add(user.unconfirmAmount) <= pool.totalAmountLimit){
            user.amount = user.amount.add(user.unconfirmAmount);
            pool.totalAmount = pool.totalAmount.add(user.unconfirmAmount);
            user.unconfirmAmount = 0;
        }
        require(user.amount > 0, "Invalid amount");
        uint256 userTotalSashimi = user.amount.mul(pool.exchangeRate).div(10**9);
        uint256 time = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 sashimiAmount = userTotalSashimi.mul(time.sub(startTime)).div(secondsPerDay).div(180);
        sashimiAmount = sashimiAmount > userTotalSashimi? userTotalSashimi : sashimiAmount;
        sashimiAmount = sashimiAmount.sub(user.accSashimi);
        if(sashimiAmount == 0) return;
        user.accSashimi = user.accSashimi.add(sashimiAmount);
        IERC20(SASHIMI).transfer(msg.sender, sashimiAmount);
    }

    function getUserInfos(uint256[] memory pids, address user) external view returns(UserInfo[] memory userInfos){
        userInfos = new UserInfo[](pids.length);
        for(uint256 i=0; i < pids.length; i++){
            userInfos[i] = userInfo[pids[i]][user];
        }
    }

    function getPendingSashimi(uint256[] memory pids, address user) external view returns (uint256[] memory pendings){
        pendings = new uint256[](pids.length);
        for(uint256 i=0; i < pids.length; i++){
            pendings[i] = pendingSashimi(pids[i],user);
        }
    }

    function pendingSashimi(uint256 pid, address _user) public view returns (uint256){
        if(block.timestamp <= startTime) return 0;
        PoolInfo memory pool = poolInfo[pid];
        UserInfo memory user = userInfo[pid][_user];
        if(user.unconfirmAmount > 0 && block.timestamp.sub(user.timestamp) > confirmTimeLimit && !badAddresses[_user] &&
        pool.totalAmount.add(user.unconfirmAmount) <= pool.totalAmountLimit){
            user.amount = user.amount.add(user.unconfirmAmount);
        }
        if(user.amount == 0) return 0;
        uint256 userTotalSashimi = user.amount.mul(pool.exchangeRate).div(10**9);
        uint256 time = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 sashimiAmount = userTotalSashimi.mul(time.sub(startTime)).div(secondsPerDay).div(180);
        sashimiAmount = sashimiAmount > userTotalSashimi? userTotalSashimi : sashimiAmount;
        sashimiAmount = sashimiAmount.sub(user.accSashimi);
        return sashimiAmount;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addBadAddress(address user) external onlyOwner{
        badAddresses[user] = true;
    }

    function removeBadAddress(address user) external onlyOwner{
        badAddresses[user] = false;
    }

    function transferToken(address token, uint256 amount, address to) external onlyAdmin {
        IERC20(token).transfer(to, amount);
    }

    function pause() external whenNotPaused onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}