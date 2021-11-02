// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MerkleWhitelist.sol";

contract MerkleLaunchpad is MerkleWhitelist, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Pool {
      address token;
      address onlyHolderToken;
      uint256 cap;
      uint256 price;
      uint256 maxContribution;
      uint256 minHolderBalance;
      uint256 startTime;
      uint256 timespan;
      bool isWhiteList;
      bool enabled;
      bool finished;
  }

  uint32 private constant scaleFactor = 1e8;
  uint32 private constant maxSpan = 1e7;
  uint32 private constant minSpan = 1e5;

  string public idoTitle;

  Pool[] public pools;
  mapping(uint256 => uint256) public poolsSold;
  mapping(uint256 => mapping(address => uint256)) public lockedTokens;

  event NewSelfStarter(address creator, address instance, uint256 blockCreated, uint version);
  event NewPool(address owner, address listing, uint256 id);
  event Swap(uint256 id, uint256 roundID, address sender, uint256 amount, uint256 amt);
  event Claim(uint256 id, address claimer, uint256 amount);
  event PoolFinished(uint256 id);
  event PoolStarted(uint256 id);
  event WhiteList(uint256 id, bytes32 roothash);

  constructor(string memory _title) {
    idoTitle = _title;
    emit NewSelfStarter(msg.sender, address(this), block.timestamp, uint(0));
  }

  modifier onlyPreLaunch(uint256 _id) {
    if(_isManual(_id)){
      require(!pools[_id].enabled, "Pool is already enabled");
      require(!pools[_id].finished, "Pool is already completed");
    }else{
      require(block.timestamp < pools[_id].startTime, "Pool start time has passed");
    }
    _;
  }

  //validators

  function _isOnlyHolder(uint256 _id) internal view returns(bool){
    return ( pools[_id].onlyHolderToken != address(0) &&  pools[_id].minHolderBalance > uint256(0));
  }

  function _isManual(uint256 _id) internal view returns(bool){
    return ( pools[_id].startTime == 0 && pools[_id].timespan == 0);
  }

  //setters

  function setMinHolderAmount(uint256 _id, uint256 _minHolderBalance) external onlyOwner onlyPreLaunch(_id) {
      pools[_id].minHolderBalance = _minHolderBalance;
  }

  function setHolderToken(uint256 _id, address _holderToken) external onlyOwner onlyPreLaunch(_id) {
      pools[_id].onlyHolderToken = _holderToken;
  }

  function setTimeData(uint256 _id, uint256 _startTime, uint256 _timespan) external onlyOwner onlyPreLaunch(_id) {
      if(_startTime > 0){
        require(_startTime > block.timestamp, "Start time must be in future");
      }
      if(_timespan > 0){
        require(_startTime.add(_timespan) > block.timestamp, "pool must end in the future, set start time");
        require(_timespan < maxSpan, "Excessive pool timespan, must be fewer than 100 days");
      }
      pools[_id].startTime = _startTime;
      uint256 computedTimespan = (pools[_id].startTime > 0 && _timespan < minSpan) ? minSpan : _timespan;
      pools[_id].timespan = computedTimespan;
  }

  function setTitle(string memory _title) external onlyOwner{
      idoTitle = _title;
  }

  function updateWhitelist(uint256 _roundId, bytes32 _newRootHash ) external onlyOwner onlyPreLaunch(_roundId) {
      _setRoundRoot(_roundId, _newRootHash);
      emit WhiteList(_roundId, _newRootHash);
  }

  function poolsLength() external view returns (uint256) {
      return pools.length;
  }

  function createPool(
      address token,
      address onlyHolderToken,
      uint256 cap,
      uint256 price,
      uint256 maxContribution,
      uint256 minHolderBalance,
      uint256 startTime,
      uint256 timespan,
      bytes32 wlRootHash
  ) external onlyOwner returns (uint256) {
      require(cap <= IERC20(token).balanceOf(msg.sender) && cap > 0, "Cap check");
      require(address(token) != address(0), "Pool token cannot be zero address");
      require(price > uint256(0), "Price must be greater than 0");
      if(startTime > 0){
        require(startTime > block.timestamp, "Start time must be in future");
      }
      uint256 computedTimespan = (startTime > 0 && timespan < minSpan) ? minSpan : timespan;

      Pool memory newPool =
          Pool(
              token,
              onlyHolderToken,
              cap,
              price,
              maxContribution,
              minHolderBalance,
              startTime,
              computedTimespan,
              (wlRootHash != 0),
              false,
              false
          );
      if(wlRootHash != 0){
        _setRoundRoot(pools.length, wlRootHash);
      }
      pools.push(newPool);

      IERC20(token).transferFrom(msg.sender, address(this), cap);
      emit NewPool(msg.sender, address(this), pools.length);
      return pools.length;
  }

  function swap(uint256 id, uint256 amount, uint256 index, bytes32[] calldata proofs) external payable {
      require(amount != 0, "Amount should not be zero");
      if(_isManual(id)){
        require(pools[id].enabled, "Pool must be enabled");
      }else{
        require(pools[id].startTime < block.timestamp && block.timestamp < pools[id].startTime.add(pools[id].timespan), "TIME: Pool not open");
      }
      if (_isOnlyHolder(id)) {
          require(IERC20(pools[id].onlyHolderToken).balanceOf(msg.sender) >= pools[id].minHolderBalance, "Miniumum balance not met");
      }
      if (pools[id].isWhiteList) {
        require(_validate(id, index, msg.sender, amount, proofs), "Failed validation");
      }
      require(amount == msg.value, "Amount is not equal msg.value");

      Pool memory pool = pools[id];
      uint256 left = pool.cap.sub(poolsSold[id]);
      uint256 curLocked = lockedTokens[id][msg.sender];
      if (left > pool.maxContribution.sub(curLocked)) {
          left = pool.maxContribution.sub(curLocked);
      }
      if (pools[id].isWhiteList && left >= amount.sub(curLocked)) {
          left = amount.sub(curLocked);
      }

      uint256 amt = pool.price.mul(amount).div(scaleFactor);
      require(left > 0, "Not enough tokens for swap");
      uint256 back = 0;
      if (left < amt) {
          amt = left;
          uint256 newAmount = amt.mul(scaleFactor).div(pool.price);
          back = amount.sub(newAmount);
          amount = newAmount;
      }
      if (pools[id].isWhiteList) {
        _setClaimed(id, index);
      }
      lockedTokens[id][msg.sender] = curLocked.add(amt);
      poolsSold[id] = poolsSold[id].add(amt);

      (bool success, ) = payable(owner()).call{value: amount}("");
      require(success, "Should transfer ethers to the pool creator");
      if (back > 0) {
          (success, ) = payable(msg.sender).call{value: back}("");
          require(success, "Should transfer left ethers back to the user");
      }

      emit Swap(id, 0, msg.sender, amount, amt);
  }

  function startPool(uint256 id) external onlyOwner {
      require(_isManual(id), "Pool is timed and not manual start");
      require(!pools[id].enabled, "Pool is already enabled");
      require(!pools[id].finished, "Pool is already completed");
      pools[id].enabled = true;
      emit PoolStarted(id);
  }

  function stopPool(uint256 id) external onlyOwner {
      require(_isManual(id), "Pool is timed and not manual stop");
      require(pools[id].enabled, "Pool is not enabled");
      require(!pools[id].finished, "Pool is already completed");
      pools[id].enabled = false;
      pools[id].finished = true;
      emit PoolFinished(id);
  }

  function claim(uint256 id) external {
      if(_isManual(id)){
        require(pools[id].finished, "Cannot claim until pool is finished");
      }else{
        require(block.timestamp > pools[id].startTime.add(pools[id].timespan));
      }
      require(lockedTokens[id][msg.sender] > 0, "Should have tokens to claim");
      uint256 amount = lockedTokens[id][msg.sender];
      lockedTokens[id][msg.sender] = 0;
      IERC20(pools[id].token).transfer(msg.sender, amount);
      emit Claim(id, msg.sender, amount);
  }

  function sweep(uint256 _id, address _token) external onlyOwner {
      if(_isManual(_id)){
        require(pools[_id].finished, "Cannot sweep until pool is finished, stop pool first");
      }else{
        require(block.timestamp > pools[_id].startTime.add(pools[_id].timespan), "Cannot sweep until pool is finished, timespan not complete");
      }
      uint256 balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransferFrom(address(this), msg.sender, balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

contract MerkleWhitelist {

    //bytes32 public immutable override merkleRoot;
    mapping ( uint256 => bytes32 ) public merkleRoots;

    //remaining allocation balances
    mapping( uint256 => mapping( uint256 => uint256) ) private claimedBitMap;

    function _setRoundRoot(uint256 roundId, bytes32 merkleRoot) internal {
      merkleRoots[roundId] = merkleRoot;
    }

    function isClaimed( uint256 roundId, uint256 index ) public view returns ( bool ) {
      uint256 claimedWordIndex = index / 256;
      uint256 claimedBitIndex = index % 256;
      uint256 claimedWord = claimedBitMap[roundId][claimedWordIndex];
      uint256 mask = ( 1 << claimedBitIndex );
      return claimedWord & mask == mask;
    }

    function _setClaimed( uint256 roundId, uint256 index ) internal {
      uint256 claimedWordIndex = index / 256;
      uint256 claimedBitIndex = index % 256;
      claimedBitMap[roundId][claimedWordIndex] = claimedBitMap[roundId][claimedWordIndex] | ( 1 << claimedBitIndex );
    }

    function _validate(
      uint256 roundId,
      uint256 index,
      address account,
      uint256 amount,
      bytes32[] calldata merkleProof
    ) internal view returns (bool) {
      if(isClaimed( roundId, index )){
        return false;
      }
      // Verify the merkle proof.
      bytes32 node = keccak256(abi.encodePacked(index, account, amount));
      uint256 path = index;
      for (uint16 i = 0; i < merkleProof.length; i++) {
          if ((path & 0x01) == 1) {
              node = keccak256(abi.encodePacked(merkleProof[i], node));
          } else {
              node = keccak256(abi.encodePacked(node, merkleProof[i]));
          }
          path /= 2;
      }
      return (node == merkleRoots[roundId]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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