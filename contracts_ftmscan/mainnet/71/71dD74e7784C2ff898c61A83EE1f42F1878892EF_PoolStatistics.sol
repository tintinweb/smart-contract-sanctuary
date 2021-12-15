// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./AbstractBaseStrategy.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
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
        uint256 daily_strategy_yield = pool.strategy_harvest_amount_per_staked_token.mul(average_blocks_per_day).div(PRECISION);
        uint256 daily_generator_yield = pool.generator_harvest_amount_per_staked_token.mul(average_blocks_per_day).div(PRECISION);
        return (daily_strategy_yield, daily_generator_yield);
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
    function claim() external;
    function pending() external view returns (uint256);

    // governance
    function pause() external;
    function unpause() external;
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