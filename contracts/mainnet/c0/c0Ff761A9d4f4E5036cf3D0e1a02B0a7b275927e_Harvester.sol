// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IController.sol";
import "./interfaces/IHarvester.sol";
import "./interfaces/ILegacyController.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/ISwap.sol";

/**
 * @title Harvester
 * @notice This contract is to be used as a central point to call
 * harvest on all strategies for any given vault. It has its own
 * permissions for harvesters (set by the strategist or governance).
 */
contract Harvester is IHarvester {
    using SafeMath for uint256;

    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    IManager public immutable override manager;
    IController public immutable controller;
    ILegacyController public immutable legacyController;

    uint256 public override slippage;

    struct Strategy {
        uint256 timeout;
        uint256 lastCalled;
        address[] addresses;
    }

    mapping(address => Strategy) public strategies;
    mapping(address => bool) public isHarvester;

    /**
     * @notice Logged when harvest is called for a strategy
     */
    event Harvest(
        address indexed controller,
        address indexed strategy
    );

    /**
     * @notice Logged when a harvester is set
     */
    event HarvesterSet(address indexed harvester, bool status);

    /**
     * @notice Logged when a strategy is added for a vault
     */
    event StrategyAdded(address indexed vault, address indexed strategy, uint256 timeout);

    /**
     * @notice Logged when a strategy is removed for a vault
     */
    event StrategyRemoved(address indexed vault, address indexed strategy, uint256 timeout);

    /**
     * @param _manager The address of the yAxisMetaVaultManager contract
     * @param _controller The address of the controller
     */
    constructor(
        address _manager,
        address _controller,
        address _legacyController
    )
        public
    {
        manager = IManager(_manager);
        controller = IController(_controller);
        legacyController = ILegacyController(_legacyController);
    }

    /**
     * (GOVERNANCE|STRATEGIST)-ONLY FUNCTIONS
     */

    /**
     * @notice Adds a strategy to the rotation for a given vault and sets a timeout
     * @param _vault The address of the vault
     * @param _strategy The address of the strategy
     * @param _timeout The timeout between harvests
     */
    function addStrategy(
        address _vault,
        address _strategy,
        uint256 _timeout
    )
        external
        override
        onlyController
    {
        strategies[_vault].addresses.push(_strategy);
        strategies[_vault].timeout = _timeout;
        emit StrategyAdded(_vault, _strategy, _timeout);
    }

    /**
     * @notice Removes a strategy from the rotation for a given vault and sets a timeout
     * @param _vault The address of the vault
     * @param _strategy The address of the strategy
     * @param _timeout The timeout between harvests
     */
    function removeStrategy(
        address _vault,
        address _strategy,
        uint256 _timeout
    )
        external
        override
        onlyController
    {
        uint256 tail = strategies[_vault].addresses.length;
        uint256 index;
        bool found;
        for (uint i; i < tail; i++) {
            if (strategies[_vault].addresses[i] == _strategy) {
                index = i;
                found = true;
                break;
            }
        }

        if (found) {
            strategies[_vault].addresses[index] = strategies[_vault].addresses[tail.sub(1)];
            strategies[_vault].addresses.pop();
            strategies[_vault].timeout = _timeout;
            emit StrategyRemoved(_vault, _strategy, _timeout);
        }
    }

    /**
     * @notice Sets the status of a harvester address to be able to call harvest functions
     * @param _harvester The address of the harvester
     * @param _status The status to allow the harvester to harvest
     */
    function setHarvester(
        address _harvester,
        bool _status
    )
        external
        onlyStrategist
    {
        isHarvester[_harvester] = _status;
        emit HarvesterSet(_harvester, _status);
    }

    function setSlippage(
        uint256 _slippage
    )
        external
        onlyStrategist
    {
        require(_slippage < ONE_HUNDRED_PERCENT, "!_slippage");
        slippage = _slippage;
    }

    /**
     * HARVESTER-ONLY FUNCTIONS
     */

    function earn(
        address _strategy,
        address _vault
    )
        external
        onlyHarvester
    {
        IVault(_vault).earn(_strategy);
    }

    /**
     * @notice Harvests a given strategy on the provided controller
     * @dev This function ignores the timeout
     * @param _controller The address of the controller
     * @param _strategy The address of the strategy
     * @param _estimates The estimated outputs from swaps during harvest
     */
    function harvest(
        IController _controller,
        address _strategy,
        uint256[] calldata _estimates
    )
        public
        onlyHarvester
    {
        _controller.harvestStrategy(_strategy, _estimates);
        emit Harvest(address(_controller), _strategy);
    }

    /**
     * @notice Harvests the next available strategy for a given vault and
     * rotates the strategies
     * @param _vault The address of the vault
     * @param _estimates The estimated outputs from swaps during harvest
     */
    function harvestNextStrategy(
        address _vault,
        uint256[] calldata _estimates
    )
        external
    {
        require(canHarvest(_vault), "!canHarvest");
        address strategy = strategies[_vault].addresses[0];
        harvest(controller, strategy, _estimates);
        uint256 k = strategies[_vault].addresses.length;
        if (k > 1) {
            address[] memory _strategies = new address[](k);
            for (uint i; i < k-1; i++) {
                _strategies[i] = strategies[_vault].addresses[i+1];
            }
            _strategies[k-1] = strategy;
            strategies[_vault].addresses = _strategies;
        }
        // solhint-disable-next-line not-rely-on-time
        strategies[_vault].lastCalled = block.timestamp;
    }

    /**
     * @notice Earns tokens in the LegacyController to the v3 vault
     * @param _expected The expected amount to deposit after conversion
     */
    function legacyEarn(
        uint256 _expected
    )
        external
        onlyHarvester
    {
        legacyController.legacyDeposit(_expected);
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the addresses of the strategies for a given vault
     * @param _vault The address of the vault
     */
    function strategyAddresses(
        address _vault
    )
        external
        view
        returns (address[] memory)
    {
        return strategies[_vault].addresses;
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the availability of a vault's strategy to be harvested
     * @param _vault The address of the vault
     */
    function canHarvest(
        address _vault
    )
        public
        view
        returns (bool)
    {
        Strategy storage strategy = strategies[_vault];
        // only can harvest if there are strategies, and when sufficient time has elapsed
        // solhint-disable-next-line not-rely-on-time
        return (strategy.addresses.length > 0 && strategy.lastCalled <= block.timestamp.sub(strategy.timeout));
    }

    /**
     * @notice Returns the estimated amount of WETH and YAXIS for the given strategy
     * @param _strategy The address of the strategy
     */
    function getEstimates(
        address _strategy
    )
        public
        view
        returns (uint256[] memory _estimates)
    {
        _estimates = IStrategyExtended(_strategy).getEstimates();
    }

    /**
     * MODIFIERS
     */

    modifier onlyController() {
        require(manager.allowedControllers(msg.sender), "!controller");
        _;
    }

    modifier onlyHarvester() {
        require(isHarvester[msg.sender], "!harvester");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == manager.strategist(), "!strategist");
        _;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IVault {
    function available() external view returns (uint256);
    function balance() external view returns (uint256);
    function deposit(uint256 _amount) external returns (uint256);
    function earn(address _strategy) external;
    function gauge() external returns (address);
    function getLPToken() external view returns (address);
    function getPricePerFullShare() external view returns (uint256);
    function getToken() external view returns (address);
    function manager() external view returns (IManager);
    function withdraw(uint256 _amount) external;
    function withdrawAll() external;
    function withdrawFee(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IController {
    function balanceOf() external view returns (uint256);
    function converter(address _vault) external view returns (address);
    function earn(address _strategy, address _token, uint256 _amount) external;
    function investEnabled() external view returns (bool);
    function harvestStrategy(address _strategy, uint256[] calldata _estimates) external;
    function manager() external view returns (IManager);
    function strategies() external view returns (uint256);
    function withdraw(address _token, uint256 _amount) external;
    function withdrawAll(address _strategy, address _convert) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IHarvester {
    function addStrategy(address, address, uint256) external;
    function manager() external view returns (IManager);
    function removeStrategy(address, address, uint256) external;
    function slippage() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ILegacyController {
    function legacyDeposit(uint256 _expected) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IManager {
    function addVault(address) external;
    function allowedControllers(address) external view returns (bool);
    function allowedConverters(address) external view returns (bool);
    function allowedStrategies(address) external view returns (bool);
    function allowedVaults(address) external view returns (bool);
    function controllers(address) external view returns (address);
    function getHarvestFeeInfo() external view returns (address, address, uint256);
    function getToken(address) external view returns (address);
    function governance() external view returns (address);
    function halted() external view returns (bool);
    function harvester() external view returns (address);
    function insuranceFee() external view returns (uint256);
    function insurancePool() external view returns (address);
    function insurancePoolFee() external view returns (uint256);
    function pendingStrategist() external view returns (address);
    function removeVault(address) external;
    function stakingPool() external view returns (address);
    function stakingPoolShareFee() external view returns (uint256);
    function strategist() external view returns (address);
    function treasury() external view returns (address);
    function treasuryFee() external view returns (uint256);
    function withdrawalProtectionFee() external view returns (uint256);
    function yaxis() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";
import "./ISwap.sol";

interface IStrategy {
    function balanceOf() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function deposit() external;
    function harvest(uint256[] calldata) external;
    function manager() external view returns (IManager);
    function name() external view returns (string memory);
    function router() external view returns (ISwap);
    function skim() external;
    function want() external view returns (address);
    function weth() external view returns (address);
    function withdraw(address) external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}

interface IStrategyExtended {
    function getEstimates() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ISwap {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external;
    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] memory);
}