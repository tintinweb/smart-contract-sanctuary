// "SPDX-License-Identifier: MIT"
pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 lockedAmount;
    uint256 withdrawn;
  }

  struct PoolInfo {
    uint8 index;
    string name;
    uint256 startTime;
    uint256 endTime;
    uint256 totalLocked;
  }

  address public sale;
  IERC20 public token;
  PoolInfo[] public lockPools;
  mapping (uint8 => mapping (address => UserInfo)) internal userInfo;

  event Claimed(uint8 pid, address indexed beneficiary, uint256 value);
  event Recovered(address token, uint256 amount);

  modifier onlyOwnerOrSale() {
    require(owner() == msg.sender || sale == msg.sender, "TokenVesting: caller is not the owner or sale");
    _;
  }

  constructor(address _token) public {
    token = IERC20(_token);
  }

  /**
   * @param _sale name of sale
   *
   * @dev method sets sales contract address
   */
  function setSale(address _sale) external onlyOwner {
    sale = _sale;
  }

  /**
   * @param _name       name of pool
   * @param _startTime  pool start time
   * @param _endTime    pool end time
   *
   * @dev method initialize new vesting pool
   */
  function initVestingPool(string calldata _name, uint256 _startTime, uint256 _endTime) external onlyOwner() returns(uint8) {
    require(block.timestamp < _startTime, "TokenVesting: invalid pool start time");
    require(_startTime < _endTime, "TokenVesting: invalid pool end time");

    lockPools.push(PoolInfo({
      name: _name,
      startTime: _startTime,
      endTime: _endTime,
      totalLocked: 0,
      index: (uint8)(lockPools.length)
    }));

    return (uint8)(lockPools.length) - 1;
  }

  /**
   * @param _pid        pool id
   * @param _name       name of pool
   * @param _startTime  pool start time
   * @param _endTime    pool end time
   *
   * @dev method sets new parameters to the vesting pool
   */
  function setVestingPool(uint8 _pid, string calldata _name, uint256 _startTime, uint256 _endTime) external onlyOwner() {
    require(lockPools[_pid].startTime > block.timestamp, "TokenVesting: pool is already running");
    require(_startTime < _endTime, "TokenVesting: invalid pool end time");

    lockPools[_pid].name = _name;
    lockPools[_pid].startTime = _startTime;
    lockPools[_pid].endTime = _endTime;
  }

  /**
   * @param _pid            pool id
   * @param _beneficiary    new beneficiary
   * @param _lockedAmount   amount to be locked for distribution
   *
   * @dev method adds new beneficiary to the pool
   */
  function addBeneficiary(uint8 _pid, address _beneficiary, uint256 _lockedAmount) external onlyOwnerOrSale() {
    require(_pid < lockPools.length, "TokenVesting: non existing pool");
    require(userInfo[_pid][_beneficiary].lockedAmount == 0, "TokenVesting: existing beneficiary");

    userInfo[_pid][_beneficiary].lockedAmount = _lockedAmount;
    lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(userInfo[_pid][_beneficiary].lockedAmount);
  }

  /**
   * @param _pid            pool id
   * @param _beneficiaries  array of beneficiaries
   * @param _lockedAmounts   array of amounts to be locked for distribution
   *
   * @dev method adds new beneficiaries to the pool
   */
  function addBeneficiaryBatches(uint8 _pid, address[] calldata _beneficiaries, uint256[] calldata _lockedAmounts) external onlyOwnerOrSale() {
    require(_beneficiaries.length == _lockedAmounts.length, "TokenVesting: params invalid length");
    require(_pid < lockPools.length, "TokenVesting: non existing pool");

    for(uint8 i = 0; i < _beneficiaries.length; i++) {
      address beneficiary = _beneficiaries[i];
      uint256 lockedAmount = _lockedAmounts[i];
      require(userInfo[_pid][beneficiary].lockedAmount == 0, "TokenVesting: existing beneficiary");

      userInfo[_pid][beneficiary].lockedAmount = lockedAmount;
      lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(userInfo[_pid][beneficiary].lockedAmount);
    }
  }

  /**
   * @param _pid  pool id
   *
   * @dev method allows to claim beneficiary locked amount
   */
  function claim(uint8 _pid) external returns(uint256 amount) {
    amount = getReleasableAmount(_pid, msg.sender);
    require (amount > 0, "TokenVesting: can't claim 0 amount");

    userInfo[_pid][msg.sender].withdrawn = userInfo[_pid][msg.sender].withdrawn.add(amount);
    token.safeTransfer(msg.sender, amount);
    
    emit Claimed(_pid, msg.sender, amount);
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   *
   * @dev method returns amount of releasable funds per beneficiary
   */
  function getReleasableAmount(uint8 _pid, address _beneficiary) public view returns(uint256) {
    return getVestedAmount(_pid, _beneficiary, block.timestamp).sub(userInfo[_pid][_beneficiary].withdrawn);
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   * @param _time         time of vesting
   *
   * @dev method returns amount of available for vesting token per beneficiary and time
   */
  function getVestedAmount(uint8 _pid, address _beneficiary, uint256 _time) public view returns(uint256) {
    if (_pid >= lockPools.length){
      return 0;
    }
    
    if(_time < lockPools[_pid].startTime) {
      return 0;
    }

    uint256 lockedAmount = userInfo[_pid][_beneficiary].lockedAmount;
    if (lockedAmount == 0) {
      return 0;
    }

    uint256 vestingDuration = lockPools[_pid].endTime.sub(lockPools[_pid].startTime);
    uint256 timeDuration = _time.sub(lockPools[_pid].startTime);
    uint256 amount = lockedAmount.mul(timeDuration).div(vestingDuration);

    if(amount > lockedAmount){
      amount = lockedAmount;
    }
    return amount;
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   *
   * @dev method returns beneficiary details per pool
   */
  function getBeneficiaryInfo(uint8 _pid, address _beneficiary) public view 
    returns(address beneficiary, uint256 totalLocked, uint256 withdrawn, uint256 releasableAmount, uint256 currentTime) {
      beneficiary = _beneficiary;
      currentTime = block.timestamp;

      if(_pid < lockPools.length) {
        totalLocked = userInfo[_pid][_beneficiary].lockedAmount;
        withdrawn = userInfo[_pid][_beneficiary].withdrawn;
        releasableAmount = getReleasableAmount(_pid, _beneficiary);
      }
  }

  /**
   *
   * @dev method returns amount of pools
   */
  function getPoolsCount() external view returns(uint256 poolsCount) {
    return lockPools.length;
  }

  /**
   * @param _pid pool id
   *
   * @dev method returns pool details
   */
  function getPoolInfo(uint8 _pid) external view 
    returns(string memory name, uint256 totalLocked, uint256 startTime, uint256 endTime) {
      if(_pid < lockPools.length) {
        name = lockPools[_pid].name;
        totalLocked = lockPools[_pid].totalLocked;
        startTime = lockPools[_pid].startTime;
        endTime = lockPools[_pid].endTime;
      }
  }

  /**
   *
   * @dev method returns total locked funds
   */
  function getTotalLocked() external view returns(uint256 totalLocked) {
    totalLocked = 0;
    for(uint8 i = 0; i < lockPools.length; i++) {
      totalLocked = totalLocked.add(lockPools[i].totalLocked);
    }
  }

  /**
   * @param _token  token address
   * @param _amount amount to be recovered
   *
   * @dev method allows to recover erc20 tokens
   */
  function recoverERC20(address _token, uint256 _amount) external onlyOwner() {
    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit Recovered(_token, _amount);
  }
}

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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
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

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

