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

contract SmartPool is Ownable, ReentrancyGuard, CloneFactory {
    using SafeMath for uint256;
    
    uint256 public constant VERSION = 2;
    uint256 public constant CLAIMABLE_PRECISION = 1e12;

    uint256 public average_blocks_per_day;
    
    // User Info
    struct UserInfo {
        uint256 stakedAmount; // How many tokens the user has staked.
        uint256 rewardFloor;  // Reward floor of rewards to be collected
    }
    mapping (address => UserInfo) public userInfo;
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
        address strategy;           // Strategy used by smart pool
        bool paused;                // disable deposits when pool has been paused
        uint256 shrimpThreshold;    // staking less than this threshold, will result in not claiming and not seeing pending from strategy until some non shrimp deposits/withdraws/claims
        uint256 fishThreshold;      // staking less than this threshold, will result in not claiming and not seeing pending from generators until non shrimp/fish deposits/withdraws/claims
        uint256 dolphinThreshold;   // staking less than this threshold, will result in not compounding/rebalancing generators until a dolphin deposits/withdraws/claims
    }
    PoolInfo[] public poolInfo;
    
    // Harvest Info
    struct HarvestInfo {
        uint256 fromBlock; // First block number that assets were staked.
        uint256 toBlock;   // Last block number that rewards distribution occurred.
        uint256 amount;    // Total claim amount harvested between first deposit and last claim
    }
    HarvestInfo public strategyHarvest;
    HarvestInfo public generatorHarvest;
    
    // Strategies
    mapping(address => bool) public allowedStrategy;
    event AddedAllowedStrategy(address implementation);
    event DisallowedStrategy(address implementation);
    event SwitchedStrategy(address implementation, uint256 timestamp);
    address strategist;
    
    // The reward token
    IBEP20 public rewardToken;

    event Cloned(uint256 timestamp, address master, address clone);
    
    // get cloned smart pool
    function getClone() public onlyOwner returns (address) {
        address cloneAddress = createClone(address(this));
        emit Cloned(block.timestamp, address(this), cloneAddress);
        return cloneAddress;
    }

    // setup smart pool
    function setupSmartPool(IBEP20 _rewardToken) public onlyOwner {
        require(address(rewardToken) == address(0), "Smart Pool already initialized!");
        rewardToken = _rewardToken;
        average_blocks_per_day = 86400;
    }
    
    // add possibility to update average blocks per day to fine tune daily yield calculations
    function configureAverageBlocksPerDay(uint256 _average_blocks_per_day) external onlyOwner {
        average_blocks_per_day = _average_blocks_per_day;
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
                strategy: _strategy,
                paused: false,
                shrimpThreshold: 0,
                fishThreshold: 0,
                dolphinThreshold: 0
            })
        );
        allowedStrategy[_strategy] = true;
        _want.approve(_strategy, type(uint256).max);
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

    function calculate_daily_yield(uint256 amount, uint256 nr_of_blocks) view internal returns (uint256) {
        return amount.mul(average_blocks_per_day).div(nr_of_blocks);
    }
    function daily_yield(uint256 _pool_index) poolExists(_pool_index) external view returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pool_index];
        uint256 strategy_pending = ISmartStrategy(pool.strategy).pending();
        uint256 generator_pending = IInvestmentManager(ISmartStrategy(pool.strategy).manager()).pending();
        uint256 blocks_since_strategy_harvest = block.number - pool.lastRewardBlock + 1;
        uint256 blocks_since_generator_harvest = block.number - generatorHarvest.toBlock + 1;
        uint256 daily_strategy_yield = calculate_daily_yield(strategy_pending, blocks_since_strategy_harvest);
        uint256 daily_generator_yield = calculate_daily_yield(generator_pending, blocks_since_generator_harvest);
        if (strategyHarvest.amount > 0 && strategyHarvest.toBlock > strategyHarvest.fromBlock) {
           daily_strategy_yield = daily_strategy_yield.add(calculate_daily_yield(strategyHarvest.amount, strategyHarvest.toBlock.sub(strategyHarvest.fromBlock))).div(2);
        }
        if (generatorHarvest.amount > 0 && generatorHarvest.toBlock > generatorHarvest.fromBlock) {
           daily_generator_yield = daily_generator_yield.add(calculate_daily_yield(generatorHarvest.amount, generatorHarvest.toBlock.sub(generatorHarvest.fromBlock))).div(2);
        }
        return (daily_strategy_yield, daily_generator_yield);
    }

    // View function to see pending rewards on frontend.
    function pendingReward(uint256 _pool_index, address _user) poolExists(_pool_index) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_user];
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

    function resetHarvestInfo() internal {
        generatorHarvest.fromBlock = block.number;
        generatorHarvest.toBlock = block.number;
        generatorHarvest.amount = 0;
    }

    // Converts pending yield into claimable yield for a given pool by collecting rewards.
    function claimPoolYield(uint256 _pool_index, uint256 _deposit_amount, bool alwaysClaim) poolExists(_pool_index) public {
        PoolInfo storage pool = poolInfo[_pool_index];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            if (_deposit_amount > 0) {
                strategyHarvest.fromBlock = block.number;
                strategyHarvest.toBlock = block.number;
                strategyHarvest.amount = 0;
            }
            return;
        }
        if (generatorHarvest.fromBlock == 0) {
           generatorHarvest.fromBlock = block.number;
           generatorHarvest.toBlock = block.number;
           generatorHarvest.amount = 0;
        }
        uint256 yield_before = rewardToken.balanceOf(address(this));
        ISmartStrategy(pool.strategy).claim();
        uint256 yield_after = rewardToken.balanceOf(address(this));
        strategyHarvest.toBlock = block.number;
        strategyHarvest.amount = strategyHarvest.amount.add(yield_after.sub(yield_before));
        if (alwaysClaim || userInfo[_msgSender()].stakedAmount.add(_deposit_amount) >= pool.fishThreshold) {
            IInvestmentManager(ISmartStrategy(pool.strategy).manager()).claim(userInfo[_msgSender()].stakedAmount.add(_deposit_amount) >= pool.dolphinThreshold);
            generatorHarvest.toBlock = block.number;
            generatorHarvest.amount = generatorHarvest.amount.add(rewardToken.balanceOf(address(this)).sub(yield_after));
        }
        uint256 harvested = rewardToken.balanceOf(address(this)).sub(yield_before);
        pool.accRewardsPerShare = pool.accRewardsPerShare.add(harvested.mul(CLAIMABLE_PRECISION).div(pool.totalStaked));
        pool.lastRewardBlock = block.number;
    }

    function transferClaimableYield(uint256 _pool_index) internal {
        UserInfo storage user = userInfo[_msgSender()];
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
        UserInfo storage user = userInfo[_msgSender()];
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
        for (uint256 pool_id = 0; pool_id < length; ++pool_id) {
            claimPoolYield(pool_id, 0, true);
        }
    }

    // Deposit staking tokens to Smart Pool
    function deposit(uint256 _pool_index, uint256 _amount) isNotPaused(_pool_index) handlePoolRewards(_pool_index, _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_msgSender()];

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
        UserInfo storage user = userInfo[_msgSender()];
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
        withdraw(_pool_index, userInfo[_msgSender()].stakedAmount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pool_index) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pool_index];
        UserInfo storage user = userInfo[_msgSender()];
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
        ISmartStrategy(pool.strategy).setManager(manager);
        pool.stakedToken.approve(pool.strategy, type(uint256).max);
        ISmartStrategy(pool.strategy).deposit(pool_balance);
        emit SwitchedStrategy(pool.strategy, block.timestamp);
    }

    function switchStrategy(uint256 _pool_index, address _new_strategy) external {
        require(msg.sender == strategist, "Only the strategist is allowed to change strategies!");
        require(allowedStrategy[_new_strategy], "Not allowed to switch pool to new strategy!");
        if (poolInfo[_pool_index].strategy == _new_strategy) return;
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

    function configureConvertorRegistry(address _convertor_registry) external;
    function approveConvertor(address _from_token, address _to_token) external;

    function pending() external view returns (uint256);
    function claim(bool compound) external;

    function invested(address smart_pool) external view returns (uint256, address);
    function pendingRewards(address smart_pool) external view returns (uint256, address);
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