/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-05
*/

// File: libraries/helpers/RequiemErrors.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.11;

// solhint-disable
library RequiemErrors {
    /**
     * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
     * supported.
     */
    function _require(bool condition, uint256 errorCode) internal pure {
        if (!condition) RequiemErrors._revert(errorCode);
    }

    /**
     * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
     */
    function _revert(uint256 errorCode) internal pure {
        // We're going to dynamically create a revert string based on the error code, with the following format:
        // 'REQ#{errorCode}'
        // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
        //
        // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
        // number (8 to 16 bits) than the individual string characters.
        //
        // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
        // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
        // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
        assembly {
            // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
            // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
            // the '0' character.

            let units := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let tenths := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let hundreds := add(mod(errorCode, 10), 0x30)

            // With the individual characters, we can now construct the full string. The "REQ#" part is a known constant
            // (0x52455123): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
            // characters to it, each shifted by a multiple of 8.
            // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
            // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
            // array).

            let revertReason := shl(200, add(0x52455123000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

            // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
            // message will have the following layout:
            // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

            // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
            // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
            mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
            mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
            // The string length is fixed: 7 characters.
            mstore(0x24, 7)
            // Finally, the string itself is stored.
            mstore(0x44, revertReason)

            // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
            // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
            revert(0, 100)
        }
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// File: interfaces/IOwnable.sol


pragma solidity 0.8.11;

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}
// File: libraries/Ownable.sol


pragma solidity 0.8.11;


contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}
// File: interfaces/ERC20/IERC20.sol


pragma solidity 0.8.11;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: libraries/SafeERC20.sol



// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.11;



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
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    RequiemErrors._require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      Errors.SAFE_ERC20_CALL_FAILED
    );
  }
}

// File: interfaces/IMiniChefV2.sol


pragma solidity ^0.8.11;


interface IMiniChefV2 {
  function lpToken(uint256 _pid) external view returns (IERC20);
}

// File: interfaces/IRewarder.sol



pragma solidity ^0.8.11;


interface IRewarder {
  function onReward(
    uint256 pid,
    address user,
    address recipient,
    uint256 rewardAmount,
    uint256 newLpAmount
  ) external;

  function pendingTokens(
    uint256 pid,
    address user,
    uint256 rewardAmount
  ) external view returns (IERC20[] memory, uint256[] memory);
}

// File: rewarders/ComplexRewarderTime.sol



pragma solidity ^0.8.11;





contract ComplexRewarderTime is IRewarder, Ownable {
  using SafeERC20 for IERC20;

  IERC20 private rewardToken;

  /// @notice Info of each MCV2 user.
  /// `amount` LP token amount the user has provided.
  /// `rewardDebt` The amount of reward entitled to the user.
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  /// @notice Info of each MCV2 pool.
  /// `allocPoint` The amount of allocation points assigned to the pool.
  /// Also known as the amount of SUSHI to distribute per block.
  struct PoolInfo {
    uint256 accRewardPerShare;
    uint256 lastRewardTime;
    uint256 allocPoint;
  }

  /// @notice Info of each pool.
  mapping(uint256 => PoolInfo) public poolInfo;

  uint256[] public poolIds;

  /// @notice Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 totalAllocPoint;

  uint256 public rewardPerSecond;
  uint256 private constant ACC_TOKEN_PRECISION = 1e12;

  address private REQUIEM_CHEF;

  event LogOnReward(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    address indexed to
  );
  event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
  event LogSetPool(uint256 indexed pid, uint256 allocPoint);
  event LogUpdatePool(
    uint256 indexed pid,
    uint256 lastRewardTime,
    uint256 lpSupply,
    uint256 accRewardPerShare
  );
  event LogRewardPerSecond(uint256 rewardPerSecond);
  event LogInit();

  constructor(
    IERC20 _rewardToken,
    uint256 _rewardPerSecond,
    address _REQUIEM_CHEF
  ) {
    rewardToken = _rewardToken;
    rewardPerSecond = _rewardPerSecond;
    REQUIEM_CHEF = _REQUIEM_CHEF;
  }

  function onReward(
    uint256 pid,
    address _user,
    address to,
    uint256,
    uint256 lpToken
  ) external override onlyMCV2 {
    PoolInfo memory pool = updatePool(pid);
    UserInfo storage user = userInfo[pid][_user];
    uint256 pending;
    if (user.amount > 0) {
      pending =
        (user.amount * pool.accRewardPerShare) /
        ACC_TOKEN_PRECISION -
        user.rewardDebt;
      rewardToken.safeTransfer(to, pending);
    }
    user.amount = lpToken;
    user.rewardDebt = (lpToken * pool.accRewardPerShare) / ACC_TOKEN_PRECISION;
    emit LogOnReward(_user, pid, pending, to);
  }

  function pendingTokens(
    uint256 pid,
    address user,
    uint256
  )
    external
    view
    override
    returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
  {
    IERC20[] memory _rewardTokens = new IERC20[](1);
    _rewardTokens[0] = (rewardToken);
    uint256[] memory _rewardAmounts = new uint256[](1);
    _rewardAmounts[0] = pendingToken(pid, user);
    return (_rewardTokens, _rewardAmounts);
  }

  /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
  /// @param _rewardPerSecond The amount of Sushi to be distributed per second.
  function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
    rewardPerSecond = _rewardPerSecond;
    emit LogRewardPerSecond(_rewardPerSecond);
  }

  modifier onlyMCV2() {
    require(msg.sender == REQUIEM_CHEF, "Only MCV2 can call this function.");
    _;
  }

  /// @notice Returns the number of MCV2 pools.
  function poolLength() public view returns (uint256 pools) {
    pools = poolIds.length;
  }

  /// @notice Add a new LP to the pool. Can only be called by the owner.
  /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  /// @param allocPoint AP of the new pool.
  /// @param _pid Pid on MCV2
  function add(uint256 allocPoint, uint256 _pid) public onlyOwner {
    require(poolInfo[_pid].lastRewardTime == 0, "Pool already exists");
    uint256 lastRewardTime = block.timestamp;
    totalAllocPoint += allocPoint;

    poolInfo[_pid] = PoolInfo({
      allocPoint: allocPoint,
      lastRewardTime: lastRewardTime,
      accRewardPerShare: 0
    });
    poolIds.push(_pid);
    emit LogPoolAddition(_pid, allocPoint);
  }

  /// @notice Update the given pool's reward allocation point and `IRewarder` contract. Can only be called by the owner.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _allocPoint New AP of the pool.
  function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
    totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
    poolInfo[_pid].allocPoint = _allocPoint;
    emit LogSetPool(_pid, _allocPoint);
  }

  /// @notice View function to see pending Token
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return pending reward for a given user.
  function pendingToken(uint256 _pid, address _user)
    public
    view
    returns (uint256 pending)
  {
    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accRewardPerShare = pool.accRewardPerShare;
    uint256 lpSupply = IMiniChefV2(REQUIEM_CHEF).lpToken(_pid).balanceOf(
      REQUIEM_CHEF
    );
    if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
      uint256 time = block.timestamp - pool.lastRewardTime;
      uint256 rewardAmount = (time * rewardPerSecond * pool.allocPoint) /
        totalAllocPoint;
      accRewardPerShare += (rewardAmount * ACC_TOKEN_PRECISION) / lpSupply;
    }
    pending =
      (user.amount * accRewardPerShare) /
      ACC_TOKEN_PRECISION -
      user.rewardDebt;
  }

  /// @notice Update reward variables for all pools. Be careful of gas spending!
  /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
  function massUpdatePools(uint256[] calldata pids) external {
    uint256 len = pids.length;
    for (uint256 i = 0; i < len; ++i) {
      updatePool(pids[i]);
    }
  }

  /// @notice Update reward variables of the given pool.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @return pool Returns the pool that was updated.
  function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
    pool = poolInfo[pid];
    if (block.timestamp > pool.lastRewardTime) {
      uint256 lpSupply = IMiniChefV2(REQUIEM_CHEF).lpToken(pid).balanceOf(
        REQUIEM_CHEF
      );

      if (lpSupply > 0) {
        uint256 time = block.timestamp - pool.lastRewardTime;
        uint256 rewardAmount = (time * rewardPerSecond * pool.allocPoint) /
          totalAllocPoint;
        pool.accRewardPerShare =
          pool.accRewardPerShare +
          (rewardAmount * ACC_TOKEN_PRECISION) /
          lpSupply;
      }
      pool.lastRewardTime = block.timestamp;
      poolInfo[pid] = pool;
      emit LogUpdatePool(
        pid,
        pool.lastRewardTime,
        lpSupply,
        pool.accRewardPerShare
      );
    }
  }
}