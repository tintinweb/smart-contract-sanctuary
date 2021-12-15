// SPDX-License-Identifier: MIT
//   
//               ,▄▄▓████████▓▓▄,            
//           ,▄████████████████████▓╥        
//         ▄██████████████╬╠██████████▌      
//       ▄██████████████▒╠╠╠████████████▌    
//     ,██████████╬▒╠╠╠╠╠╠╠╠╠╠╠╠╬╜╠▓██████µ  
//    ┌█████████▒╠╠╠╠╠╠╠╠╠╠╠╠╝╙ ╓██████████▄ 
//    █████████▒╠╠╠╠╠╠╠╠╠╠╜   ▄█████████████ 
//   ╟█████████▒╠╠╠╠╠╠╝╙    Æ████████████████
//   ███████████▒╠╠╠╠╠Γ     ▒▒╚▀█████████████
//   █████████████▄▒╠╠Γ     ▒▒▒▒░╫███████████
//   ╟███████████████▀    ╔φ▒▒▒▒▒▒███████████
//    █████████████▀  ,φ╠▒▒▒▒▒▒▒▒▒██████████⌐
//    ╙██████████▀ ╓φ╠▒▒▒▒▒▒▒▒▒▒░▓█████████▌ 
//     ╙███████╠φ╠▒▒▒▒▒▒▒▒▒▒▒▒▄▓██████████▀  
//       █████████████▌▒▒░▓██████████████└   
//        ╙███████████▌░▓██████████████╙     
//           ╙██████████████████████▀─       
//              └▀▀████████████▀▀╙   
//              
pragma solidity ^0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/ISmartStrategy.sol";
import "../interfaces/IInvestmentManager.sol";
import "../utils/CloneFactory.sol";
import "./PoolStatistics.sol";

contract SmartPool is Ownable, ReentrancyGuard, CloneFactory {
    using SafeMath for uint256;
    
    uint256 public constant VERSION = 2;
    uint256 public constant CLAIMABLE_PRECISION = 1e12;

    // User Info
    struct UserInfo {
        uint256 stakedAmount; // How many tokens the user has staked.
        uint256 rewardFloor;  // Reward floor of rewards to be collected
    }
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyWithdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event Claimed(address indexed user, uint256 amount, uint256 timestamp);

    // Pool Info
    struct PoolInfo {
        IBEP20 stakedToken;         // Address of token contract to stake in pool.
        uint256 totalStaked;        // Total tokens staked in pool
        uint256 lastRewardBlock;    // Last block number that rewards distribution occurred.
        uint256 accRewardsPerShare; // Accumulated rewards per share (times CLAIMABLE_PRECISION)
        uint256 lastGeneratorRewardBlock; // Last block number that generator rewards distribution occurred
        address strategy;           // Strategy used by smart pool
        bool paused;                // disable deposits when pool has been paused
        uint256 shrimpThreshold;    // staking less than this threshold, will result in not claiming and not seeing pending from strategy until some non shrimp deposits/withdraws/claims
        uint256 fishThreshold;      // staking less than this threshold, will result in not claiming and not seeing pending from generators until non shrimp/fish deposits/withdraws/claims
        uint256 dolphinThreshold;   // staking less than this threshold, will result in not compounding/rebalancing generators until a dolphin deposits/withdraws/claims
    }
    PoolInfo[] public poolInfo;
    
    // Strategies
    mapping(address => bool) public allowedStrategy;
    event AddedAllowedStrategy(address implementation);
    event DisallowedStrategy(address implementation);
    event SwitchedStrategy(address implementation, uint256 timestamp);
    address strategist;
    
    // The rewards
    IBEP20 public rewardToken;
    address public pool_statistics;

    event Cloned(uint256 timestamp, address master, address clone);
    
    // get cloned smart pool
    function getClone() public onlyOwner returns (address) {
        address cloneAddress = createClone(address(this));
        emit Cloned(block.timestamp, address(this), cloneAddress);
        return cloneAddress;
    }

    // setup smart pool
    function setupSmartPool(IBEP20 _rewardToken, address _pool_statistics) public onlyOwner {
        require(address(rewardToken) == address(0), "Smart Pool already initialized!");
        rewardToken = _rewardToken;
        strategist = owner();
        pool_statistics = _pool_statistics;
    }

    function configurePoolStatistics(address _pool_statistics) public onlyOwner {
        pool_statistics = _pool_statistics;
    }
    
    function addPool(
        IBEP20 _want,
        address _strategy
    ) public onlyOwner {
        require(ISmartStrategy(_strategy).want() == address(_want), 'The strategy for a pool requires the same want token!');
        poolInfo.push(
            PoolInfo({
                stakedToken: _want,
                totalStaked: 0,
                lastRewardBlock: block.number,
                accRewardsPerShare: 0,
                lastGeneratorRewardBlock: block.number,
                strategy: _strategy,
                paused: false,
                shrimpThreshold: 0,
                fishThreshold: 0,
                dolphinThreshold: 0
            })
        );
        allowedStrategy[_strategy] = true;
        _want.approve(_strategy, type(uint256).max);
        PoolStatistics(pool_statistics).initStatistics(poolInfo.length - 1, address(_want), address(rewardToken));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    modifier poolExists(uint256 _pool_index) {
        require(_pool_index < poolInfo.length, "non-existant pool id");
        _;
    }

    modifier isNotPaused(uint256 _pool_index) {
        require(!poolInfo[_pool_index].paused, "pool id has been paused");
        _;
    }

    function pause(uint256 _pool_index) public onlyOwner {
        poolInfo[_pool_index].paused = true;
    }

    function unpause(uint256 _pool_index) public onlyOwner {
        poolInfo[_pool_index].paused = false;
    }

    function configureThresholds(uint256 _pool_index, uint256 shrimp, uint256 fish, uint256 dolphin) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pool_index];
        pool.shrimpThreshold = shrimp;
        pool.fishThreshold = fish;
        pool.dolphinThreshold = dolphin;
    }
    
    function pending(uint256 _pool_index) poolExists(_pool_index) external view returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pool_index];
        uint256 strategy_pending = ISmartStrategy(pool.strategy).pending();
        uint256 generator_pending = IInvestmentManager(ISmartStrategy(pool.strategy).manager()).pending();
        return (strategy_pending, generator_pending);
    }

    // View function to see pending rewards on frontend.
    function pendingReward(uint256 _pool_index, address _user) poolExists(_pool_index) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_pool_index][_user];
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0 && user.stakedAmount >= pool.shrimpThreshold) {
            uint256 pendingHarvest = ISmartStrategy(pool.strategy).pending();
            if (user.stakedAmount >= pool.fishThreshold) {
               IInvestmentManager manager = IInvestmentManager(ISmartStrategy(pool.strategy).manager());
               pendingHarvest = pendingHarvest.add(manager.pending());
            }
            accRewardsPerShare = accRewardsPerShare.add(pendingHarvest.mul(CLAIMABLE_PRECISION).div(pool.totalStaked));
        }
        return user.stakedAmount.mul(accRewardsPerShare).div(CLAIMABLE_PRECISION).sub(user.rewardFloor);
    }

    // Converts pending yield into claimable yield for a given pool by collecting rewards.
    function claimPoolYield(uint256 _pool_index, uint256 _deposit_amount, bool alwaysClaim) poolExists(_pool_index) public {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_pool_index][_msgSender()];
        if (block.number <= pool.lastRewardBlock || (!alwaysClaim && user.stakedAmount.add(_deposit_amount) == 0)) {
            return;
        }
        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            pool.lastGeneratorRewardBlock = block.number;
            return;
        }
        uint256 reward_balance_before = rewardToken.balanceOf(address(this));
        ISmartStrategy(pool.strategy).claim();
        uint256 reward_balance_after = rewardToken.balanceOf(address(this));
        uint256 harvested = reward_balance_after.sub(reward_balance_before);
        PoolStatistics(pool_statistics).reportStrategyHarvest(_pool_index, user.stakedAmount, pool.strategy, pool.lastRewardBlock, block.number, harvested);

        if (alwaysClaim || user.stakedAmount.add(_deposit_amount) >= pool.fishThreshold) {
            IInvestmentManager manager = IInvestmentManager(ISmartStrategy(pool.strategy).manager());
            manager.claim(user.stakedAmount.add(_deposit_amount) >= pool.dolphinThreshold);
            uint256 generator_harvest = rewardToken.balanceOf(address(this)).sub(reward_balance_after);
            harvested = harvested.add(generator_harvest);
            PoolStatistics(pool_statistics).reportGeneratorHarvest(_pool_index, user.stakedAmount, pool.strategy, manager.smartPoolGenerator(address(this)), pool.lastGeneratorRewardBlock, block.number, generator_harvest);
            pool.lastGeneratorRewardBlock = block.number;
        }
        pool.accRewardsPerShare = pool.accRewardsPerShare.add(harvested.mul(CLAIMABLE_PRECISION).div(pool.totalStaked));
        pool.lastRewardBlock = block.number;
    }

    function transferClaimableYield(uint256 _pool_index) internal {
        UserInfo storage user = userInfo[_pool_index][_msgSender()];
        if (user.stakedAmount > 0) {
            uint256 claimable = user.stakedAmount.mul(poolInfo[_pool_index].accRewardsPerShare).div(CLAIMABLE_PRECISION).sub(user.rewardFloor);
            if (claimable > 0) {
                rewardToken.transfer(address(_msgSender()), claimable);
                emit Claimed(_msgSender(), claimable, block.timestamp);
            }
        }  
    }

    modifier handlePoolRewards(uint256 _pool_index, uint256 _deposit_amount) {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_pool_index][_msgSender()];
        if (user.stakedAmount.add(_deposit_amount) >= pool.shrimpThreshold) {
            claimPoolYield(_pool_index, _deposit_amount, false);
        }
        transferClaimableYield(_pool_index);
        _;
        user.rewardFloor = user.stakedAmount.mul(pool.accRewardsPerShare).div(CLAIMABLE_PRECISION);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pool_index = 0; pool_index < length; ++pool_index) {
            claimPoolYield(pool_index, 0, true);
        }
    }

    // Deposit staking tokens to Smart Pool
    function deposit(uint256 _pool_index, uint256 _amount) isNotPaused(_pool_index) handlePoolRewards(_pool_index, _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_pool_index][_msgSender()];

        if(_amount > 0) {
            uint256 _before = pool.stakedToken.balanceOf(address(this));
            pool.stakedToken.transferFrom(address(_msgSender()), address(this), _amount);
            uint256 _tokens_deposited = pool.stakedToken.balanceOf(address(this)).sub(_before);
            pool.totalStaked = pool.totalStaked.add(_tokens_deposited);
            ISmartStrategy(poolInfo[_pool_index].strategy).deposit(_tokens_deposited);
            user.stakedAmount = user.stakedAmount.add(_tokens_deposited);
            emit Deposited(_msgSender(), _tokens_deposited, block.timestamp);
        }
    }

    // Withdraw staking tokens from SmartPool.
    function withdraw(uint256 _pool_index, uint256 _amount) handlePoolRewards(_pool_index, 0) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_pool_index][_msgSender()];
        require(user.stakedAmount >= _amount, "Can't withdraw more than available");

        if(_amount > 0) {
            uint256 _balance_before = pool.stakedToken.balanceOf(address(this));
            ISmartStrategy(pool.strategy).withdraw(_amount);
            uint256 _token_balance = pool.stakedToken.balanceOf(address(this));
            uint256 _tokens_withdrawn = _token_balance.sub(_balance_before);
            pool.totalStaked = pool.totalStaked.sub(_tokens_withdrawn);

            if (_tokens_withdrawn > user.stakedAmount) {
                user.stakedAmount = 0;
            } else {
                user.stakedAmount = user.stakedAmount.sub(_tokens_withdrawn);
            }

            if (_token_balance < _amount) {
                _amount = _token_balance;
            }
            pool.stakedToken.transfer(address(_msgSender()), _amount);
            emit Withdrawn(_msgSender(), _amount, block.timestamp);
        }
    }
    
    function withdrawAll(uint256 _pool_index) public {
        withdraw(_pool_index, userInfo[_pool_index][_msgSender()].stakedAmount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pool_index) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_pool_index][_msgSender()];
        uint256 amount = user.stakedAmount;
        user.stakedAmount = 0;
        user.rewardFloor = 0;
        if (amount > 0) pool.stakedToken.transfer(address(_msgSender()), amount);
        pool.totalStaked = pool.totalStaked.sub(amount);
        emit EmergencyWithdrawn(_msgSender(), amount, block.timestamp);
    }
    
    
    // Strategies
    function allowStrategy(address _strategy) external onlyOwner {
        allowedStrategy[_strategy] = true;
        emit AddedAllowedStrategy(_strategy);
    }

    function disallowStrategy(address _strategy) external onlyOwner {
        allowedStrategy[_strategy] = false;
        emit DisallowedStrategy(_strategy);
    }

    function setStrategist(address _strategist) external onlyOwner {
        strategist = _strategist;
    }

    function initNewStrategy(uint256 _pool_index, address _new_strategy) internal {
        PoolInfo storage pool = poolInfo[_pool_index];
        address manager = ISmartStrategy(pool.strategy).manager();
        uint256 pool_balance = IBEP20(pool.stakedToken).balanceOf(address(this));
        pool.strategy = _new_strategy;
        pool.stakedToken.approve(pool.strategy, type(uint256).max);
        ISmartStrategy(pool.strategy).deposit(pool_balance);
        emit SwitchedStrategy(pool.strategy, block.timestamp);
    }

    function switchStrategy(uint256 _pool_index, address _new_strategy) external {
        require(msg.sender == strategist, "Only the strategist is allowed to change strategies!");
        require(allowedStrategy[_new_strategy], "Not allowed to switch pool to new strategy!");
        if (poolInfo[_pool_index].strategy == _new_strategy) return;
        claimPoolYield(_pool_index, 0, true);
        ISmartStrategy(poolInfo[_pool_index].strategy).withdrawAll();
        initNewStrategy(_pool_index, _new_strategy);
    }

    function panicStrategy(uint256 _pool_index, address _new_strategy) external {
        require(msg.sender == strategist, "Only the strategist is allowed to panic strategies!");
        require(allowedStrategy[_new_strategy], "Not allowed to panic pool to new strategy!");
        ISmartStrategy(poolInfo[_pool_index].strategy).panic();
        initNewStrategy(_pool_index, _new_strategy);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function initOwnerAfterCloning(address newOwner) public {
        require(_owner == address(0), "Ownable: owner has already been initialized");
        emit OwnershipTransferred(address(0), newOwner);
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0x000000000000000000000031337000b017000d0114);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;
interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
interface ISmartStrategy {
    function want() external view returns (address);

    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;

    function pending() external view returns (uint256);
    function claim() external;
    
    function manager() external view returns (address);
    function setManager(address investment_manager) external;

    function panic() external;    
    
    function external_3rd_party_balance() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "../common/ConvertorConfig.sol";

interface IInvestmentManager {
    function reinvest(address smartPool, uint256 toReinvest, address token) external;

    function configureGenerator(address _generator, address _wanttoken, address _yieldtoken, uint256 compound) external;
    function switchGenerator(address _smartpool, address _generator) external;
    function configureGeneratorSwitch(address _smartpool, address _generator, address _wanttoken, address _yieldtoken, uint256 compound) external;

    function configureConvertorRegistry(address _convertor_registry) external;
    function approveConvertor(address _from_token, address _to_token) external;
    // approve convertors both ways
    function approveConvertors(address _from_token, address _to_token) external;

    function pending() external view returns (uint256);
    function claim(bool compound) external;

    function invested(address smart_pool) external view returns (uint256, address);
    function pendingRewards(address smart_pool) external view returns (uint256, address);
    
    function smartPoolGenerator(address smart_pool) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
//solhint-disable max-line-length
//solhint-disable no-inline-assembly
import "../common/Ownable.sol";

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
    Ownable(result).initOwnerAfterCloning(msg.sender);
    return result;
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./SmartBaseStrategy.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "../interfaces/IInvestmentManager.sol";

contract PoolStatistics is Ownable {
    using SafeMath for uint256;

    uint256 public constant PRECISION = 1e12;
    
    struct Statistics {
        address staked_token;
        address harvest_token;
        uint256 total_blocks;
        uint256 total_harvested;
        uint256 strategy_harvest_amount_per_staked_token;  // multiplied by PRECISION
        uint256 generator_harvest_amount_per_staked_token; // multiplied by PRECISION
    }
    mapping(address => mapping (uint256 => Statistics)) public poolStatistics;

    uint256 public average_blocks_per_day;

    constructor() {
        average_blocks_per_day = 86400;
    }

    function initStatistics(uint256 pool_index, address _staked_token, address _harvest_token) public {
        poolStatistics[msg.sender][pool_index].staked_token = _staked_token;
        poolStatistics[msg.sender][pool_index].harvest_token = _harvest_token;
    }

    function reportStrategyHarvest(uint256 pool_index, uint256 _staked_amount, address _strategy, uint256 _fromBlock, uint256 _toBlock, uint256 _harvest_amount) public {
        address pool = AbstractBaseStrategy(_strategy).smartpool();
        require(msg.sender == pool, 'Only the pool may report strategy harvests.');
        uint256 blocks = (_fromBlock>_toBlock) ? _toBlock.sub(_fromBlock) : 0;
        if (blocks == 0) return;
        uint256 yield_per_staked_token_per_block = _harvest_amount.mul(PRECISION).div(blocks).div(_staked_amount);
        poolStatistics[pool][pool_index].strategy_harvest_amount_per_staked_token = yield_per_staked_token_per_block;
        poolStatistics[pool][pool_index].total_blocks = poolStatistics[pool][pool_index].total_blocks.add(blocks);
        poolStatistics[pool][pool_index].total_harvested = poolStatistics[pool][pool_index].total_harvested.add(_harvest_amount);
    }

    function reportGeneratorHarvest(uint256 pool_index, uint256 _staked_amount, address _strategy, address _generator, uint256 _fromBlock, uint256 _toBlock, uint256 _harvest_amount) public {
        address pool = AbstractBaseStrategy(_strategy).smartpool();
        require(msg.sender == pool && IInvestmentManager(SmartBaseStrategy(_strategy).manager()).smartPoolGenerator(pool) == _generator, 'Only the pool may report generator harvests.');
        uint256 blocks = (_fromBlock>_toBlock) ? _toBlock.sub(_fromBlock) : 0;
        if (blocks == 0) return;
        uint256 yield_per_staked_token_per_block = _harvest_amount.mul(PRECISION).div(blocks).div(_staked_amount);
        poolStatistics[pool][pool_index].generator_harvest_amount_per_staked_token = yield_per_staked_token_per_block;
        poolStatistics[pool][pool_index].total_harvested = poolStatistics[pool][pool_index].total_harvested.add(_harvest_amount);
    }
    
    // add possibility to update average blocks per day to fine tune daily yield calculations
    function configureAverageBlocksPerDay(uint256 _average_blocks_per_day) external onlyOwner {
        average_blocks_per_day = _average_blocks_per_day;
    }

    function daily_yield(address _pool_address, uint256 pool_index) external view returns (uint256, uint256) {
        Statistics memory pool = poolStatistics[_pool_address][pool_index];
        uint256 daily_strategy_yield = pool.strategy_harvest_amount_per_staked_token.mul(average_blocks_per_day).div(PRECISION);
        uint256 daily_generator_yield = pool.generator_harvest_amount_per_staked_token.mul(average_blocks_per_day).div(PRECISION);
        return (daily_strategy_yield, daily_generator_yield);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

struct ConvertorConfig {
    address router;
    address[] path;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./SafeMath.sol";
import "./Pausable.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/ISmartStrategy.sol";
import "../interfaces/IInvestmentManager.sol";
import "../common/BaseYieldStrategyV1.sol";

abstract contract SmartBaseStrategy is BaseYieldStrategyV1 {
    using SafeMath for uint256;
    
    address public manager;
    uint256 public minimum_reinvestment;

    function initSmartBaseStrategy(address _token, address _yieldtoken, address _consolidationtoken, address _smart_pool, address _convertor_registry, address _investment_manager, address _settings) public {
        initBaseYieldStrategyV1(_token, _yieldtoken, _smart_pool, _convertor_registry, _settings);
        manager = _investment_manager;
        if (manager == address(0)) return;
        IBEP20(_token).approve(manager, type(uint256).max);
        if (_token != _consolidationtoken) {
           IBEP20(_consolidationtoken).approve(manager, type(uint256).max);
        }
        minimum_reinvestment = 1e12;
    }
    
    // investment manager
    function setManager(address investment_manager) external onlyOwner {
        manager = investment_manager;
    }
    
    function configureMinimumReinvestAmount(uint256 _minimum_reinvest_amount) external onlyOwner {
        minimum_reinvestment = _minimum_reinvest_amount;
    }

    function reinvest(uint256 _harvested, address consolidationtoken) internal override returns (uint256) {
        if (manager == address(0)) return 0;
        uint256 toReinvest = _harvested.mul(REINVESTMENT).div(MAX_PCT);
        if (toReinvest < minimum_reinvestment) return 0;
        uint256 _token_before = IBEP20(consolidationtoken).balanceOf(address(this));
        IInvestmentManager(manager).reinvest(smartpool, toReinvest, consolidationtoken);
        uint256 reinvested = _token_before.sub(IBEP20(consolidationtoken).balanceOf(address(this)));
        return reinvested;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
        
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IRouter.sol";
import "./BaseStrategyV1.sol";
import "./ConvertorRegistry.sol";
import "./Settings.sol";

abstract contract BaseYieldStrategyV1 is BaseStrategyV1 {
    using SafeMath for uint256;

    address public yieldtoken;    
    address public strategist_fee_address;
    address public treasury_fee_address;

    uint public REINVESTMENT;
    uint public TREASURY_FEE;
    uint public STRATEGIST_FEE;
    uint constant public MAX_FEE =   500; // max 5% of performance fee can be configured
    uint constant public MAX_INV =  2500; // max 25% of harvest can be reinvested
    uint constant public MAX_PCT = 10000;
    
    address convertorRegistry;
    uint256 convertor_deadline;
    address[] list_3rd_party_yieldtokens;
    address[] list_consolidation_yieldtokens;

    function initBaseYieldStrategyV1(address _token, address _yieldtoken, address _smart_pool, address _convertor_registry, address _settings) public {
        initBaseStrategyV1(_token, _smart_pool, _settings);
        yieldtoken = _yieldtoken;
        convertorRegistry = _convertor_registry;
        convertor_deadline = ConvertorRegistry(convertorRegistry).convertor_deadline();
        treasury_fee_address = Settings(settings).default_treasury_fee_address();
        strategist_fee_address = Settings(settings).default_strategist_fee_address();
        TREASURY_FEE = Settings(settings).default_treasury_fee();
        STRATEGIST_FEE = Settings(settings).default_strategist_fee();
        REINVESTMENT = Settings(settings).default_reinvestment();
    }
    
    // configure 3rd party yield
    function internal_3rd_party_yieldtoken(address _3rd_party_yieldtoken, address _consolidationtoken) internal {
        list_3rd_party_yieldtokens.push(_3rd_party_yieldtoken);
        list_consolidation_yieldtokens.push(_consolidationtoken);
        if (_3rd_party_yieldtoken != _consolidationtoken) {
           (address router,) = ConvertorRegistry(convertorRegistry).getConvertorConfig(_3rd_party_yieldtoken, _consolidationtoken);
           require(router != address(0), 'Missing convertor configuration from 3rd party yieldtoken to consolidation token');
           IBEP20(_3rd_party_yieldtoken).approve(router, uint(-1));
        }
        (address router,) = ConvertorRegistry(convertorRegistry).getConvertorConfig(_consolidationtoken, yieldtoken);
        require(router != address(0), 'Missing convertor configuration from consolidation token to yield token');
        IBEP20(_consolidationtoken).approve(router, uint(-1));
    }
    function pending_3rd_party_yield() view virtual public returns (uint256[] memory);
    function collect_3rd_party_yield() virtual internal;

    // conversion methods
    function convert(uint256 amount, address _from_token, address _to_token) internal {
        if (amount == 0) return;
        (address router, address[] memory path) = ConvertorRegistry(convertorRegistry).getConvertorConfig(_from_token, _to_token);
        IRouter(router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp + convertor_deadline);
    }

    // fee governance
    function configureTreasuryFee(address _treasury, uint _treasury_fee) external onlyOwner {
        require(_treasury_fee <= MAX_FEE, 'Requested treasury fee exceeds maximum!');
        treasury_fee_address = _treasury;
        TREASURY_FEE = _treasury_fee;
    }

    function configureStrategistFee(address _strategist, uint _strategist_fee) external onlyOwner {
        require(_strategist_fee <= MAX_FEE, 'Requested strategist fee exceeds maximum!');
        strategist_fee_address = _strategist;
        STRATEGIST_FEE = _strategist_fee;
    }

    function configureReinvestment(uint _reinvestment) external onlyOwner {
        require(_reinvestment <= MAX_INV, 'Requested reinvestment percentage exceeds maximum!');
        REINVESTMENT = _reinvestment;
    }
    
    // yield functions
    function pending() external view override returns (uint256) {
        uint256[] memory _3rd_party_yield = this.pending_3rd_party_yield();
        require(list_3rd_party_yieldtokens.length == _3rd_party_yield.length, "require pending yield for each yield token");
        uint256 pending_yield = 0;
        for (uint i=0; i<list_3rd_party_yieldtokens.length; i++) {
             if (_3rd_party_yield[i] > 0 ) {
                 uint256 estimated_3rd_party_yield = _3rd_party_yield[i].mul(MAX_PCT-(TREASURY_FEE+STRATEGIST_FEE+REINVESTMENT)).div(MAX_PCT);
                 if (list_consolidation_yieldtokens[i] == list_3rd_party_yieldtokens[i]) {
                    pending_yield = pending_yield.add(ConvertorRegistry(convertorRegistry).estimateConversion(estimated_3rd_party_yield, list_3rd_party_yieldtokens[i], yieldtoken));
                 } else {
                    uint256 consolidated_yield = ConvertorRegistry(convertorRegistry).estimateConversion(estimated_3rd_party_yield, list_3rd_party_yieldtokens[i], list_consolidation_yieldtokens[i]);
                    pending_yield = pending_yield.add(ConvertorRegistry(convertorRegistry).estimateConversion(consolidated_yield, list_consolidation_yieldtokens[i], yieldtoken));
                 }
             }
        }
        return pending_yield;
    }
    function internal_harvest() internal override {
        uint256[] memory balancesBefore = new uint256[](list_3rd_party_yieldtokens.length);
        for (uint i=0; i<list_3rd_party_yieldtokens.length; i++) {
            balancesBefore[i] = IBEP20(list_3rd_party_yieldtokens[i]).balanceOf(address(this));
        }
        // this method should realize gains or losses
        collect_3rd_party_yield();
        address consolidationtoken;
        for (uint i=0; i<list_3rd_party_yieldtokens.length; i++) {
            uint256 harvested = IBEP20(list_3rd_party_yieldtokens[i]).balanceOf(address(this)).sub(balancesBefore[i]);
            if (list_consolidation_yieldtokens[i] != list_3rd_party_yieldtokens[i]) {
                convert(harvested, list_3rd_party_yieldtokens[i], list_consolidation_yieldtokens[i]);
            }
            consolidationtoken = list_consolidation_yieldtokens[i];
        }
        uint256 consolidated = IBEP20(consolidationtoken).balanceOf(address(this));
        if (consolidated > 0) {
            uint256 reinvested = reinvest(consolidated, consolidationtoken);
            uint256 toConvert = consolidated.sub(reinvested);
            if (toConvert > 0) {           

  uint256 bal = IBEP20(consolidationtoken).balanceOf(address(this));
  (address router,) = ConvertorRegistry(convertorRegistry).getConvertorConfig(consolidationtoken, yieldtoken);
  uint256 allowed = IBEP20(consolidationtoken).allowance(address(this), router);
  
               uint256 converted = convertYield(toConvert, consolidationtoken);
            }
        }
    }
    function reinvest(uint256 _to_invest, address consolidationtoken) virtual internal returns (uint256);
    function convertYield(uint256 _harvested, address consolidationtoken) internal returns (uint256) {
        uint256 _yield_before = balanceOfYieldToken();
        convert(_harvested, consolidationtoken, yieldtoken);
        uint256 _yield = balanceOfYieldToken().sub(_yield_before);
        
        uint256 treasuryFee = _yield.mul(TREASURY_FEE).div(MAX_PCT);
        if (treasuryFee > 0) IBEP20(yieldtoken).transfer(treasury_fee_address, treasuryFee);

        uint256 strategistFee = _yield.mul(STRATEGIST_FEE).div(MAX_PCT);
        if (strategistFee > 0) IBEP20(yieldtoken).transfer(strategist_fee_address, strategistFee);
        
        uint256 toYield = _yield.sub(treasuryFee).sub(strategistFee);
        return toYield;
    }
    
    function internal_return_yield() internal override {
        uint256 yield = balanceOfYieldToken();
        if (yield > 0) IBEP20(yieldtoken).transfer(smartpool, yield);
    }

    function balanceOfYieldToken() public view returns (uint256) {
        return IBEP20(yieldtoken).balanceOf(address(this));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "../interfaces/IBEP20.sol";
import "./AbstractBaseStrategy.sol";

abstract contract BaseStrategyV1 is AbstractBaseStrategy {
    using SafeMath for uint256;

    address public settings;
    
    // strategy statistics
    uint256 public total_deposited;
    uint256 public total_withdrawn;
    // 3rd party statistics
    uint256 public total_3rd_party_invested;
    uint256 public total_3rd_party_collected;
    
    function initBaseStrategyV1(address _token, address _smart_pool, address _settings) public {
       initAbstractBaseStrategy(_token, _smart_pool);
       settings = _settings;
    }
    
    // 3rd party functions
    function internal_3rd_party_deposit(uint256 _amount) virtual internal;
    function internal_3rd_party_withdraw(uint256 _amount) virtual internal;
    function internal_3rd_party_withdraw_all() virtual internal;
    function internal_3rd_party_emergencywithdraw() virtual internal;
    function external_3rd_party_balance() view virtual external returns (uint256);

    // internal functions
    function internal_deposit() internal override {
        uint256 tokenBalanceBefore = balanceOfToken();
        if (tokenBalanceBefore > 0) {
            internal_3rd_party_deposit(tokenBalanceBefore);
            uint256 invested = tokenBalanceBefore.sub(balanceOfToken());
            total_3rd_party_invested = total_3rd_party_invested.add(invested);
        }
    }

    function internal_collect_tokens(uint256 _amount) internal override returns (uint256) {
        if (_amount == 0) return 0;
        uint256 balanceBefore = balanceOfToken();
        IBEP20(token).transferFrom(address(smartpool), address(this), _amount);
        uint256 deposited = balanceOfToken().sub(balanceBefore);
        total_deposited = total_deposited.add(deposited);
        return deposited;
    }

    function internal_return_tokens(uint256 _amount) internal override returns (uint256) {
        if (_amount == 0) return 0;
        uint256 balanceBefore = balanceOfToken();
        IBEP20(token).transfer(msg.sender, _amount);
        uint256 returned = balanceBefore.sub(balanceOfToken());
        total_withdrawn = total_withdrawn.add(returned);
        return returned;
    }

    function internal_withdraw(uint256 _amount) internal override {
        uint256 balanceBefore = balanceOfToken();
        internal_3rd_party_withdraw(_amount);
        uint256 balanceReceived = balanceOfToken().sub(balanceBefore);
        total_3rd_party_collected = total_3rd_party_collected.add(balanceReceived);
        if (balanceReceived > 0) {
           uint256 returned = internal_return_tokens(balanceReceived);
        }
    }

    function internal_withdraw_all() internal override {
        uint256 balanceBefore = balanceOfToken();
        internal_3rd_party_withdraw_all();
        uint256 balanceReceived = balanceOfToken().sub(balanceBefore);
        total_3rd_party_collected = total_3rd_party_collected.add(balanceReceived);
        if (balanceReceived > 0) {
           uint256 returned = internal_return_tokens(balanceReceived);
        }
    }

    function internal_emergencywithdraw() internal override {
        uint256 balanceBefore = balanceOfToken();
        internal_3rd_party_emergencywithdraw();
        uint256 balanceReceived = balanceOfToken().sub(balanceBefore);
        total_3rd_party_collected = total_3rd_party_collected.add(balanceReceived);
        if (balanceReceived > 0) {
           uint256 returned = internal_return_tokens(balanceReceived);

        }
    }

    // yield functions
    function pending() virtual external view override returns (uint256);
    function internal_harvest() virtual internal override;
    function internal_return_yield() virtual internal override;

    // balance functions
    function balanceOfToken() public view returns (uint256) {
        return IBEP20(token).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return this.external_3rd_party_balance();
    }
    
    function expectedAmountInStrategy() public view returns (uint256) {
        if (total_deposited > total_withdrawn) {
            return total_deposited.sub(total_withdrawn);
        }
        return 0;
    }

}

// SPDX-License-Identifier: MIT
//   
//                    ▄█           
//                  ▄███           
//               ,▓█████           
//        ╓▓█████████████████████▀`
//      ╓████████████████████▀╓╛   
//     ▐█████████████████▀╙ ,╛     
//     ███████████████▀─  ╓╜       
//     ███████████▀╙    ╓╙         
//     ╟█████████      ╟██▄,       
//      ╙████████      ╟█████▄     
//        ╙▀█████      ╟███████    
//            └╟▀    ,▄█████████   
//           #╙   ▄▓████████████   
//         #└ ,▄███████████████▌   
//       é─▄▓█████████████████▀    
//    ,Q▄███████████████████▀─     
//   "▀▀▀▀▀▀▀▀▀▀██████▀▀▀╙─        
//              ████▀              
//              ██▀                
//              └      
//   
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ConvertorConfig.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IRouter.sol";

contract ConvertorRegistry is Ownable {
    uint256 public convertor_deadline = 20000;
    mapping(address => mapping(address => ConvertorConfig)) private convertorConfig;

    // convertor governance
    function configureConvertorDeadline(uint256 _convertor_deadline) public onlyOwner {
        convertor_deadline = _convertor_deadline;
    }
    function configureConvertor(address _from_token, address _to_token, address _exchange_router, address[] calldata _exchange_path) public onlyOwner {
        convertorConfig[_from_token][_to_token] = ConvertorConfig({router: _exchange_router, path:_exchange_path});
        IBEP20(_from_token).approve(_exchange_router, type(uint256).max);
    }
    function configureConvertorPath(address _exchange_router, address[] calldata _exchange_path) public onlyOwner {
        address _from_token = _exchange_path[0];
        address _to_token = _exchange_path[_exchange_path.length-1];
        convertorConfig[_from_token][_to_token] = ConvertorConfig({router: _exchange_router, path:_exchange_path});
        IBEP20(_from_token).approve(_exchange_router, type(uint256).max);
    }
    
    // conversion methods
    function getConvertorConfig(address _from_token, address _to_token) public view returns (address router, address[] memory path) {
        ConvertorConfig storage config = convertorConfig[_from_token][_to_token];
        return (config.router, config.path);
    }

    function estimateConversion(uint256 amount, address _from_token, address _to_token) public view returns (uint256) {
        if (amount == 0) return 0;
        ConvertorConfig storage config = convertorConfig[_from_token][_to_token];
        require(config.router != address(0), "Unable to estimate conversion due to missing router configuration!");
        uint[] memory amounts = IRouter(config.router).getAmountsOut(amount, config.path);
        uint256 amountOut = amounts[amounts.length - 1];
        return amountOut;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Ownable.sol";

contract Settings is Ownable {
    address public default_yieldtoken;    
    address public default_strategist_fee_address;
    address public default_treasury_fee_address;

    uint256 public default_treasury_fee;
    uint256 public default_strategist_fee;
    uint256 public default_reinvestment = 1000; // by default 10% will be reinvested
    
    uint256 public default_minimum_yield;
    
    uint256 constant public MAX_FEE =   500; // max 5% of performance fee can be configured
    uint256 constant public MAX_INV =  2500; // max 25% of harvest can be reinvested
    uint256 constant public MAX_PCT = 10000;
    
    constructor(address _default_yieldtoken) {
        default_yieldtoken = _default_yieldtoken;
    }

    // fee governance
    function configureDefaultTreasuryFee(address _treasury, uint _treasury_fee) external onlyOwner {
        require(_treasury_fee <= MAX_FEE, 'Requested treasury fee exceeds maximum!');
        default_treasury_fee_address = _treasury;
        default_treasury_fee = _treasury_fee;
    }

    function configureDefaultStrategistFee(address _strategist, uint _strategist_fee) external onlyOwner {
        require(_strategist_fee <= MAX_FEE, 'Requested strategist fee exceeds maximum!');
        default_strategist_fee_address = _strategist;
        default_strategist_fee = _strategist_fee;
    }

    function configureDefaultReinvestment(uint _reinvestment) external onlyOwner {
        require(_reinvestment <= MAX_INV, 'Requested reinvestment percentage exceeds maximum!');
        default_reinvestment = _reinvestment;
    }
    
    function configureDefaultMinimumYield(uint256 _minimum_yield) external onlyOwner {
        default_minimum_yield = _minimum_yield;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./Pausable.sol";
import "../interfaces/IBaseStrategy.sol";
import "../interfaces/IBEP20.sol";
import "../utils/CloneFactory.sol";

abstract contract AbstractBaseStrategy is Ownable, Pausable, IBaseStrategy, CloneFactory {
    address public token;
    uint256 public token_decimals;
    address public smartpool;
    event Cloned(uint256 timestamp, address master, address clone);
    
    function getClone() public onlyOwner returns (address) {
        address cloneAddress = createClone(address(this));
        emit Cloned(block.timestamp, address(this), cloneAddress);
        return cloneAddress;
    }
    
    function initAbstractBaseStrategy(address _token, address _smart_pool) public onlyOwner {
        token = _token;
        token_decimals = IBEP20(token).decimals();
        smartpool = _smart_pool;
    }
    
    function want() public override view returns (address) {
        return address(token);
    }

    // internal abstract functions
    function internal_collect_tokens(uint256 _amount) virtual internal returns (uint256);
    function internal_deposit() virtual internal;
    function internal_harvest() virtual internal;
    function internal_return_yield() virtual internal;
    function internal_withdraw(uint256 _amount) virtual internal;
    function internal_withdraw_all() virtual internal;
    function internal_return_tokens(uint256 _amount) virtual internal returns (uint256);
    function internal_emergencywithdraw() virtual internal;

    modifier onlySmartpool() {
        require(msg.sender == smartpool, "!smartpool");
        _;
    }
    
    // external functions
    function deposit(uint256 _amount) external override onlySmartpool {
        uint256 collected = internal_collect_tokens(_amount);
        internal_deposit();
    }

    function withdraw(uint256 _amount) external override onlySmartpool {
        internal_withdraw(_amount);
    }

    function withdrawAll() external override onlySmartpool {
        internal_withdraw_all();
    }

    function panic() external override onlySmartpool {
        internal_emergencywithdraw();
    }

    function claim() external override onlySmartpool whenNotPaused {
        internal_harvest();
        internal_return_yield();
    }

    // external abstract functions
    function pending() virtual external override view returns (uint256);

   // governance
    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
interface IBaseStrategy {
    function want() external view returns (address);

    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function panic() external;
    function claim() external;
    function pending() external view returns (uint256);

    // governance
    function pause() external;
    function unpause() external;
}