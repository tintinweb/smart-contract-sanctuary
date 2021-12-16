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
        uint256 length = poolInfo.length;
        for (uint256 pool_index = 0; pool_index < length; ++pool_index) {
            PoolStatistics(pool_statistics).initStatistics(pool_index, address(poolInfo[pool_index].stakedToken), address(rewardToken));
        }
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
        ISmartStrategy(pool.strategy).claim(user.stakedAmount.add(_deposit_amount) >= pool.fishThreshold);
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
    function claim(bool may_reinvest) external;
    
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

import "./AbstractBaseStrategy.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IInvestmentManager.sol";
import "../interfaces/ISmartBaseStrategy.sol";

contract PoolStatistics is Ownable {
    using SafeMath for uint256;

    uint256 public constant PRECISION = 1e24;
    
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
        uint256 blocks = (_fromBlock<_toBlock) ? _toBlock.sub(_fromBlock) : 0;
        if (blocks == 0) return;
        uint256 yield_per_staked_token_per_block = _harvest_amount.mul(PRECISION).div(blocks).div(_staked_amount);
        poolStatistics[pool][pool_index].strategy_harvest_amount_per_staked_token = yield_per_staked_token_per_block;
        poolStatistics[pool][pool_index].total_blocks = poolStatistics[pool][pool_index].total_blocks.add(blocks);
        poolStatistics[pool][pool_index].total_harvested = poolStatistics[pool][pool_index].total_harvested.add(_harvest_amount);
    }

    function reportGeneratorHarvest(uint256 pool_index, uint256 _staked_amount, address _strategy, address _generator, uint256 _fromBlock, uint256 _toBlock, uint256 _harvest_amount) public {
        address pool = AbstractBaseStrategy(_strategy).smartpool();
        require(msg.sender == pool && IInvestmentManager(ISmartBaseStrategy(_strategy).manager()).smartPoolGenerator(pool) == _generator, 'Only the pool may report generator harvests.');
        uint256 blocks = (_fromBlock<_toBlock) ? _toBlock.sub(_fromBlock) : 0;
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
        uint256 harvest_token_decimals = IBEP20(pool.harvest_token).decimals();
        uint256 daily_strategy_yield = pool.strategy_harvest_amount_per_staked_token.mul(average_blocks_per_day).mul(10 ** harvest_token_decimals).div(PRECISION);
        uint256 daily_generator_yield = pool.generator_harvest_amount_per_staked_token.mul(average_blocks_per_day).mul(10 ** harvest_token_decimals).div(PRECISION);
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

import "./Ownable.sol";
import "./Pausable.sol";
import "../interfaces/IBaseStrategy.sol";
import "../interfaces/IBEP20.sol";
import "../utils/CloneFactory.sol";

abstract contract AbstractBaseStrategy is Ownable, Pausable, IBaseStrategy, CloneFactory {
    address public token;
    uint256 public token_decimals;
    address public smartpool;
    mapping(address => uint256) last_deposit_block;
    
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
    function internal_harvest(bool may_reinvest) virtual internal;
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
        last_deposit_block[_msgSender()] = block.number;
        uint256 collected = internal_collect_tokens(_amount);
        internal_deposit();
    }

    function withdraw(uint256 _amount) external override onlySmartpool {
        require(last_deposit_block[_msgSender()] != block.number, 'No withdraw possible in the same block as deposit!');
        internal_withdraw(_amount);
    }

    function withdrawAll() external override onlySmartpool {
        internal_withdraw_all();
    }

    function panic() external override onlySmartpool {
        require(last_deposit_block[_msgSender()] != block.number, 'No emergency withdraw possible in the same block as deposit!');
        internal_emergencywithdraw();
    }

    function claim(bool may_reinvest) external override onlySmartpool whenNotPaused {
        internal_harvest(may_reinvest);
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
interface ISmartBaseStrategy {
    function manager() external view returns (address);
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
interface IBaseStrategy {
    function want() external view returns (address);

    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function panic() external;
    function claim(bool may_reinvest) external;
    function pending() external view returns (uint256);

    // governance
    function pause() external;
    function unpause() external;
}