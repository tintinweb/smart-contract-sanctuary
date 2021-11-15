// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/BoringMath.sol";
import "./libraries/SignedSafeMath.sol";
import "./libraries/BoringERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/************************************************************************************************
Originally from
https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChefV2.sol
and
https://github.com/sdaoswap/sushiswap/blob/master/contracts/MasterChef.sol
This source code has been modified from the original, which was copied from the github repository
at commit hash 10148a31d9192bc803dac5d24fe0319b52ae99a4.
*************************************************************************************************/


contract SDAOTokenStaking is Ownable {
  using BoringMath for uint256;
  using BoringMath128 for uint128;
  using BoringERC20 for IERC20;
  using SignedSafeMath for int256;

  //==========  Structs  ==========
  
  /// @dev Info of each user.
  /// @param amount LP token amount the user has provided.
  /// @param rewardDebt The amount of rewards entitled to the user.
  struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
  }


  /// @dev Info of each rewards pool.
  /// @param tokenPerBlock Reward tokens per block number.
  /// @param lpSupply Total staked amount.
  /// @param accRewardsPerShare Total rewards accumulated per staked token.
  /// @param lastRewardBlock Last time rewards were updated for the pool.
  /// @param endOfEpochBlock End of epoc block number for compute and to avoid deposits.
  struct PoolInfo {
    uint256 tokenPerBlock;
    uint256 lpSupply;
    uint128 accRewardsPerShare;
    uint64 lastRewardBlock;
    uint endOfEpochBlock;
  }

  //==========  Constants  ==========

  /// @dev For percision calculation while computing the rewards.
  uint256 private constant ACC_REWARDS_PRECISION = 1e18;

  /// @dev ERC20 token used to distribute rewards.   
  IERC20 public immutable rewardsToken;

  /** ==========  Storage  ========== */

  /// @dev Indicates whether a staking pool exists for a given staking token.
  //mapping(address => bool) public stakingPoolExists;
  
  /// @dev Info of each staking pool.
  PoolInfo[] public poolInfo;
  
  /// @dev Address of the LP token for each staking pool.
  mapping(uint256 => IERC20) public lpToken;
  
  /// @dev Info of each user that stakes tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @dev Account allowed to allocate points.
  address public pointsAllocator;

  /// @dev Total rewards received from governance for distribution.
  /// Used to return remaining rewards if staking is canceled.
  uint256 public totalRewardsReceived;

  // ==========  Events  ==========

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event LogPoolAddition(uint256 indexed pid, IERC20 indexed lpToken);
  event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accRewardsPerShare);
  event RewardsAdded(uint256 amount);
  event PointsAllocatorSet(address pointsAllocator);

  // ==========  Modifiers  ========== 

  /// @dev Ensure the caller is allowed to allocate points.
  modifier onlyPointsAllocatorOrOwner {
    require(
      msg.sender == pointsAllocator || msg.sender == owner(),
      "MultiTokenStaking: not authorized to allocate points"
    );
    _;
  }

  // ==========  Constructor  ==========

  /// @dev During the deployment of the contract pass the ERC-20 contract address used for rewards.
  constructor(address _rewardsToken) public {
    rewardsToken = IERC20(_rewardsToken);
  }

  // ==========  Governance  ========== 

  /// @dev Set the address of the points allocator.
  /// This account will have the ability to set allocation points for LP rewards.
  function setPointsAllocator(address _pointsAllocator) external onlyOwner {
    require(_pointsAllocator != address(0), "Invalid points allocator address.");
    pointsAllocator = _pointsAllocator;
    emit PointsAllocatorSet(_pointsAllocator);
  }

  /// @dev Add rewards to be distributed.
  /// Note: This function must be used to add rewards if the owner
  /// wants to retain the option to cancel distribution and reclaim
  /// undistributed tokens.  
  function addRewards(uint256 amount) external onlyPointsAllocatorOrOwner {
    
    require(rewardsToken.balanceOf(msg.sender) > 0, "ERC20: not enough tokens to transfer");

    totalRewardsReceived = totalRewardsReceived.add(amount);
    rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
    
    emit RewardsAdded(amount);
  }



  // ==========  Pools  ==========
  
  /// @dev Add a new LP to the pool.
  /// Can only be called by the owner or the points allocator.
  /// @param _lpToken Address of the LP ERC-20 token.
  /// @param _sdaoPerBlock Rewards per block.
  /// @param _endofepochblock Epocs end block number.
  function add(IERC20 _lpToken, uint256 _sdaoPerBlock, uint64 _endofepochblock) public onlyPointsAllocatorOrOwner {

    //This is not needed as we are going to use the contract for multiple pools with the same LP Tokens
    //require(!stakingPoolExists[address(_lpToken)], " Staking pool already exists.");
    
    require(_endofepochblock > block.number, "Cannot create the pool for past time.");

    uint256 pid = poolInfo.length;

    lpToken[pid] = _lpToken;

    poolInfo.push(PoolInfo({
      tokenPerBlock: _sdaoPerBlock,
      endOfEpochBlock:_endofepochblock,
      lastRewardBlock: block.number.to64(),
      lpSupply:0,
      accRewardsPerShare: 0
    }));

    //stakingPoolExists[address(_lpToken)] = true;

    emit LogPoolAddition(pid, _lpToken);
  }


  /// @dev To get the rewards per block.
  function sdaoPerBlock(uint256 _pid) public view returns (uint256 amount) {
      PoolInfo memory pool = poolInfo[_pid];
      amount = pool.tokenPerBlock;
  }

  /// @dev Update reward variables for all pools in `pids`.
  /// Note: This can become very expensive.
  /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
  function massUpdatePools(uint256[] calldata pids) external onlyOwner {
    uint256 len = pids.length;
    for (uint256 i = 0; i < len; ++i) {
      updatePool(pids[i]);
    }
  }


  /// @dev Update reward variables of the given pool.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @return pool Returns the pool that was updated.
 function updatePool(uint256 _pid) private returns (PoolInfo memory pool) {

    pool = poolInfo[_pid];
    uint256 lpSupply = pool.lpSupply;

    if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.endOfEpochBlock) {

       if(lpSupply > 0){
         
           uint256 blocks;
           if(block.number < pool.endOfEpochBlock) {
             blocks = block.number.sub(pool.lastRewardBlock);
           } else {
             blocks = pool.endOfEpochBlock.sub(pool.lastRewardBlock);
          }

          uint256 sdaoReward = blocks.mul(sdaoPerBlock(_pid));
          pool.accRewardsPerShare = pool.accRewardsPerShare.add((sdaoReward.mul(ACC_REWARDS_PRECISION) / lpSupply).to128());

       }

       pool.lastRewardBlock = block.number.to64();
       poolInfo[_pid] = pool;
       emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accRewardsPerShare);

    }

  }



  // ==========  Users  ==========

  /// @dev View function to see pending rewards on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return pending rewards for a given user.
  function pendingRewards(uint256 _pid, address _user) external view returns (uint256 pending) {

    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];

    uint256 accRewardsPerShare = pool.accRewardsPerShare;
    uint256 lpSupply = pool.lpSupply;

    if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.endOfEpochBlock) {

      if(lpSupply > 0){

        uint256 blocks;

        if(block.number < pool.endOfEpochBlock) {
            blocks = block.number.sub(pool.lastRewardBlock);
        } else {
          blocks = pool.endOfEpochBlock.sub(pool.lastRewardBlock);
        }
        
        uint256 sdaoReward = blocks.mul(sdaoPerBlock(_pid));
        accRewardsPerShare = accRewardsPerShare.add(sdaoReward.mul(ACC_REWARDS_PRECISION) / lpSupply);

      }

    }

    pending = int256(user.amount.mul(accRewardsPerShare) / ACC_REWARDS_PRECISION).sub(user.rewardDebt).toUInt256();
  }


  /// @dev Deposit LP tokens to earn rewards.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount LP token amount to deposit.
  /// @param _to The receiver of `_amount` deposit benefit.
  function deposit(uint256 _pid, uint256 _amount, address _to) public {

    // Input Validation
    require(_amount > 0 && _to != address(0), "Invalid inputs for deposit.");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][_to];

    // check if epoch as ended or if pool doesnot exist 
    require (pool.endOfEpochBlock > block.number,"This pool epoch has ended. Please join staking new session.");
    
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.rewardDebt.add(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));

    // Add to total supply
    pool.lpSupply = pool.lpSupply.add(_amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposit(msg.sender, _pid, _amount, _to);
  }

  /// @dev Withdraw LP tokens from the staking contract.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount LP token amount to withdraw.
  /// @param _to Receiver of the LP tokens.
  function withdraw(uint256 _pid, uint256 _amount, address _to) public {

    require(_to != address(0), "ERC20: transfer to the zero address");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    // Check whether user has deposited stake
    require(user.amount >= _amount && _amount > 0, "Invalid amount to withdraw.");

    // Effects
    user.rewardDebt = user.rewardDebt.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Subtract from total supply
    pool.lpSupply = pool.lpSupply.sub(_amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    lpToken[_pid].safeTransfer(_to, _amount);

    emit Withdraw(msg.sender, _pid, _amount, _to);
  }


   /// @dev Harvest proceeds for transaction sender to `_to`.
   /// @param _pid The index of the pool. See `poolInfo`.
   /// @param _to Receiver of rewards.
   function harvest(uint256 _pid, address _to) public {
    
    require(_to != address(0), "ERC20: transfer to the zero address");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);
    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedRewards;

    // Interactions
    if(_pendingRewards > 0 ) {
      rewardsToken.safeTransfer(_to, _pendingRewards);
    }
    
    emit Harvest(msg.sender, _pid, _pendingRewards);
  }

  //// @dev Withdraw LP tokens and harvest accumulated rewards, sending both to `to`.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount LP token amount to withdraw.
  /// @param _to Receiver of the LP tokens and rewards.
  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) public {

    require(_to != address(0), "ERC20: transfer to the zero address");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    // Check if the user has stake in the pool
    require(user.amount >= _amount && _amount > 0, "Cannot withdraw more than staked.");

    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);
    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedRewards.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Subtract from total supply
    pool.lpSupply = pool.lpSupply.sub(_amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    if(_pendingRewards > 0) {
      rewardsToken.safeTransfer(_to, _pendingRewards);
    }
    lpToken[_pid].safeTransfer(_to, _amount);

    emit Harvest(msg.sender, _pid, _pendingRewards);
    emit Withdraw(msg.sender, _pid, _amount, _to);
  }


  /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _to Receiver of the LP tokens.  
  function emergencyWithdraw(uint256 _pid, address _to) public {

    require(_to != address(0), "ERC20: transfer to the zero address");

    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    PoolInfo memory pool = updatePool(_pid);
    pool.lpSupply = pool.lpSupply.sub(amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Note: transfer can fail or succeed if `amount` is zero.
    lpToken[_pid].safeTransfer(_to, amount);

    emit EmergencyWithdraw(msg.sender, _pid, amount, _to);
  }

  function withdrawETHAndAnyTokens(address token) external onlyOwner {
    msg.sender.send(address(this).balance);
    IERC20 Token = IERC20(token);
    uint256 currentTokenBalance = Token.balanceOf(address(this));
    Token.safeTransfer(msg.sender, currentTokenBalance); 
  }

  // ==========  Getter Functions  ==========

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SignedSafeMath {
  int256 constant private _INT256_MIN = -2**255;

  /**
    * @dev Returns the multiplication of two signed integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    *
    * - Multiplication cannot overflow.
    */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

    int256 c = a * b;
    require(c / a == b, "SignedSafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two signed integers. Reverts on
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
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

    int256 c = a / b;

    return c;
  }

  /**
    * @dev Returns the subtraction of two signed integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  /**
    * @dev Returns the addition of two signed integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    *
    * - Addition cannot overflow.
    */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function toUInt256(int256 a) internal pure returns (uint256) {
    require(a >= 0, "Integer < 0");
    return uint256(a);
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

