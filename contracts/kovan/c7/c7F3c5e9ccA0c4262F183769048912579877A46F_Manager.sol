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
// solhint-disable max-states-count
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IController.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/IHarvester.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";

/**
 * @title Manager
 * @notice This contract serves as the central point for governance-voted
 * variables. Fees and permissioned addresses are stored and referenced in
 * this contract only.
 */
contract Manager is IManager {
    using SafeMath for uint256;

    uint256 public constant PENDING_STRATEGIST_TIMELOCK = 7 days;
    uint256 public constant MAX_TOKENS = 256;

    address public immutable override yaxis;

    address public override governance;
    address public override harvester;
    address public override insurancePool;
    address public override stakingPool;
    address public override strategist;
    address public override pendingStrategist;
    address public override treasury;

    // The following fees are all mutable.
    // They are updated by governance (community vote).
    uint256 public override insuranceFee;
    uint256 public override insurancePoolFee;
    uint256 public override stakingPoolShareFee;
    uint256 public override treasuryFee;
    uint256 public override withdrawalProtectionFee;

    bool public override halted;

    uint256 private setPendingStrategistTime;

    // Governance must first allow the following properties before
    // the strategist can make use of them
    mapping(address => bool) public override allowedControllers;
    mapping(address => bool) public override allowedConverters;
    mapping(address => bool) public override allowedStrategies;
    mapping(address => bool) public override allowedTokens;
    mapping(address => bool) public override allowedVaults;

    // vault => controller
    mapping(address => address) public override controllers;
    // vault => tokens[]
    mapping(address => address[]) public override tokens;
    // token => vault
    mapping(address => address) public override vaults;

    event AllowedController(
        address indexed _controller,
        bool _allowed
    );
    event AllowedConverter(
        address indexed _converter,
        bool _allowed
    );
    event AllowedStrategy(
        address indexed _strategy,
        bool _allowed
    );
    event AllowedToken(
        address indexed _token,
        bool _allowed
    );
    event AllowedVault(
        address indexed _vault,
        bool _allowed
    );
    event Halted();
    event SetController(
        address indexed _vault,
        address indexed _controller
    );
    event SetGovernance(
        address indexed _governance
    );
    event SetPendingStrategist(
        address indexed _strategist
    );
    event SetStrategist(
        address indexed _strategist
    );
    event TokenAdded(
        address indexed _vault,
        address indexed _token
    );
    event TokenRemoved(
        address indexed _vault,
        address indexed _token
    );

    /**
     * @param _yaxis The address of the YAX token
     */
    constructor(
        address _yaxis
    )
        public
    {
        require(_yaxis != address(0), "!_yaxis");
        yaxis = _yaxis;
        governance = msg.sender;
        strategist = msg.sender;
        harvester = msg.sender;
        treasury = msg.sender;
        stakingPoolShareFee = 2000;
        treasuryFee = 500;
        withdrawalProtectionFee = 10;
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    function setAllowedController(
        address _controller,
        bool _allowed
    )
        external
        notHalted
        onlyGovernance
    {
        require(address(IController(_controller).manager()) == address(this), "!manager");
        allowedControllers[_controller] = _allowed;
        emit AllowedController(_controller, _allowed);
    }

    function setAllowedConverter(
        address _converter,
        bool _allowed
    )
        external
        notHalted
        onlyGovernance
    {
        require(address(IConverter(_converter).manager()) == address(this), "!manager");
        allowedConverters[_converter] = _allowed;
        emit AllowedConverter(_converter, _allowed);
    }

    function setAllowedStrategy(
        address _strategy,
        bool _allowed
    )
        external
        notHalted
        onlyGovernance
    {
        require(address(IStrategy(_strategy).manager()) == address(this), "!manager");
        allowedStrategies[_strategy] = _allowed;
        emit AllowedStrategy(_strategy, _allowed);
    }

    function setAllowedToken(
        address _token,
        bool _allowed
    )
        external
        notHalted
        onlyGovernance
    {
        allowedTokens[_token] = _allowed;
        emit AllowedToken(_token, _allowed);
    }

    function setAllowedVault(
        address _vault,
        bool _allowed
    )
        external
        notHalted
        onlyGovernance
    {
        require(address(IVault(_vault).manager()) == address(this), "!manager");
        allowedVaults[_vault] = _allowed;
        emit AllowedVault(_vault, _allowed);
    }

    /**
     * @notice Sets the governance address
     * @param _governance The address of the governance
     */
    function setGovernance(
        address _governance
    )
        external
        notHalted
        onlyGovernance
    {
        governance = _governance;
        emit SetGovernance(_governance);
    }

    /**
     * @notice Sets the harvester address
     * @param _harvester The address of the harvester
     */
    function setHarvester(
        address _harvester
    )
        external
        notHalted
        onlyGovernance
    {
        require(address(IHarvester(_harvester).manager()) == address(this), "!manager");
        harvester = _harvester;
    }

    /**
     * @notice Sets the insurance fee
     * @dev Throws if setting fee over 1%
     * @param _insuranceFee The value for the insurance fee
     */
    function setInsuranceFee(
        uint256 _insuranceFee
    )
        external
        notHalted
        onlyGovernance
    {
        require(_insuranceFee <= 100, "_insuranceFee over 1%");
        insuranceFee = _insuranceFee;
    }

    /**
     * @notice Sets the insurance pool address
     * @param _insurancePool The address of the insurance pool
     */
    function setInsurancePool(
        address _insurancePool
    )
        external
        notHalted
        onlyGovernance
    {
        insurancePool = _insurancePool;
    }

    /**
     * @notice Sets the insurance pool fee
     * @dev Throws if setting fee over 20%
     * @param _insurancePoolFee The value for the insurance pool fee
     */
    function setInsurancePoolFee(
        uint256 _insurancePoolFee
    )
        external
        notHalted
        onlyGovernance
    {
        require(_insurancePoolFee <= 2000, "_insurancePoolFee over 20%");
        insurancePoolFee = _insurancePoolFee;
    }

    /**
     * @notice Sets the staking pool address
     * @param _stakingPool The address of the staking pool
     */
    function setStakingPool(
        address _stakingPool
    )
        external
        notHalted
        onlyGovernance
    {
        stakingPool = _stakingPool;
    }

    /**
     * @notice Sets the staking pool share fee
     * @dev Throws if setting fee over 50%
     * @param _stakingPoolShareFee The value for the staking pool fee
     */
    function setStakingPoolShareFee(
        uint256 _stakingPoolShareFee
    )
        external
        notHalted
        onlyGovernance
    {
        require(_stakingPoolShareFee <= 5000, "_stakingPoolShareFee over 50%");
        stakingPoolShareFee = _stakingPoolShareFee;
    }

    /**
     * @notice Sets the pending strategist and the timestamp
     * @param _strategist The address of the strategist
     */
    function setStrategist(
        address _strategist
    )
        external
        notHalted
        onlyGovernance
    {
        require(_strategist != address(0), "!_strategist");
        pendingStrategist = _strategist;
        // solhint-disable-next-line not-rely-on-time
        setPendingStrategistTime = block.timestamp;
        emit SetPendingStrategist(_strategist);
    }

    /**
     * @notice Sets the treasury address
     * @param _treasury The address of the treasury
     */
    function setTreasury(
        address _treasury
    )
        external
        notHalted
        onlyGovernance
    {
        require(_treasury != address(0), "!_treasury");
        treasury = _treasury;
    }

    /**
     * @notice Sets the treasury fee
     * @dev Throws if setting fee over 20%
     * @param _treasuryFee The value for the treasury fee
     */
    function setTreasuryFee(
        uint256 _treasuryFee
    )
        external
        notHalted
        onlyGovernance
    {
        require(_treasuryFee <= 2000, "_treasuryFee over 20%");
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Sets the withdrawal protection fee
     * @dev Throws if setting fee over 1%
     * @param _withdrawalProtectionFee The value for the withdrawal protection fee
     */
    function setWithdrawalProtectionFee(
        uint256 _withdrawalProtectionFee
    )
        external
        notHalted
        onlyGovernance
    {
        require(_withdrawalProtectionFee <= 100, "_withdrawalProtectionFee over 1%");
        withdrawalProtectionFee = _withdrawalProtectionFee;
    }

    /**
     * STRATEGIST-ONLY FUNCTIONS
     */

    function acceptStrategist()
        external
        notHalted
    {
        require(msg.sender == pendingStrategist, "!pendingStrategist");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > setPendingStrategistTime.add(PENDING_STRATEGIST_TIMELOCK), "PENDING_STRATEGIST_TIMELOCK");
        delete pendingStrategist;
        delete setPendingStrategistTime;
        strategist = msg.sender;
        emit SetStrategist(msg.sender);
    }

    function addToken(
        address _vault,
        address _token
    )
        external
        override
        notHalted
        onlyStrategist
    {
        require(allowedTokens[_token], "!allowedTokens");
        require(allowedVaults[_vault], "!allowedVaults");
        require(tokens[_vault].length < MAX_TOKENS, ">tokens");
        vaults[_token] = _vault;
        tokens[_vault].push(_token);
        emit TokenAdded(_vault, _token);
    }

    /**
     * @notice Allows the strategist to pull tokens out of this contract
     * @dev This contract should never hold tokens
     * @param _token The address of the token
     * @param _amount The amount to withdraw
     * @param _to The address to send to
     */
    function recoverToken(
        IERC20 _token,
        uint256 _amount,
        address _to
    )
        external
        notHalted
        onlyStrategist
    {
        _token.transfer(_to, _amount);
    }

    function removeToken(
        address _vault,
        address _token
    )
        external
        override
        notHalted
        onlyStrategist
    {
        uint256 k = tokens[_vault].length;
        uint256 index;
        bool found;

        for (uint i = 0; i < k; i++) {
            if (tokens[_vault][i] == _token) {
                index = i;
                found = true;
                break;
            }
        }

        // TODO: Verify added check
        if (found) {
            tokens[_vault][index] = tokens[_vault][k-1];
            tokens[_vault].pop();
            delete vaults[_token];
            emit TokenRemoved(_vault, _token);
        }
    }

    /**
     * @notice Sets the vault address for a controller
     * @param _vault The address of the vault
     * @param _controller The address of the controller
     */
    function setController(
        address _vault,
        address _controller
    )
        external
        notHalted
        onlyStrategist
    {
        require(allowedVaults[_vault], "!_vault");
        require(allowedControllers[_controller], "!_controller");
        controllers[_vault] = _controller;
        emit SetController(_vault, _controller);
    }

    function setHalted()
        external
        notHalted
        onlyStrategist
    {
        halted = true;
        emit Halted();
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    function getTokens(
        address _vault
    )
        external
        view
        override
        returns (address[] memory)
    {
        return tokens[_vault];
    }

    /**
     * @notice Returns a tuple of:
     *     YAXIS token address,
     *     Treasury address,
     *     Treasury fee
     */
    function getHarvestFeeInfo()
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            yaxis,
            treasury,
            treasuryFee
        );
    }

    modifier notHalted() {
        require(!halted, "halted");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IController {
    function balanceOf() external view returns (uint256);
    function converter(address _vault) external view returns (address);
    function earn(address _strategy, address _token, uint256 _amount) external;
    function investEnabled() external view returns (bool);
    function harvestStrategy(address _strategy, uint256 _estimatedWETH, uint256 _estimatedYAXIS) external;
    function manager() external view returns (IManager);
    function strategies() external view returns (uint256);
    function withdraw(address _token, uint256 _amount) external;
    function withdrawAll(address _strategy, address _convert) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IConverter {
    function manager() external view returns (IManager);
    function convert(
        address _input,
        address _output,
        uint256 _inputAmount,
        uint256 _estimatedOutput
    ) external returns (uint256 _outputAmount);
    function expected(
        address _input,
        address _output,
        uint256 _inputAmount
    ) external view returns (uint256 _outputAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IHarvester {
    function addStrategy(address, address, uint256) external;
    function manager() external view returns (IManager);
    function removeStrategy(address, address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IManager {
    function addToken(address, address) external;
    function allowedControllers(address) external view returns (bool);
    function allowedConverters(address) external view returns (bool);
    function allowedStrategies(address) external view returns (bool);
    function allowedTokens(address) external view returns (bool);
    function allowedVaults(address) external view returns (bool);
    function controllers(address) external view returns (address);
    function getHarvestFeeInfo() external view returns (address, address, uint256);
    function getTokens(address) external view returns (address[] memory);
    function governance() external view returns (address);
    function halted() external view returns (bool);
    function harvester() external view returns (address);
    function insuranceFee() external view returns (uint256);
    function insurancePool() external view returns (address);
    function insurancePoolFee() external view returns (uint256);
    function pendingStrategist() external view returns (address);
    function removeToken(address, address) external;
    function stakingPool() external view returns (address);
    function stakingPoolShareFee() external view returns (uint256);
    function strategist() external view returns (address);
    function tokens(address, uint256) external view returns (address);
    function treasury() external view returns (address);
    function treasuryFee() external view returns (uint256);
    function vaults(address) external view returns (address);
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
    function harvest(uint256, uint256) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ISwap {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external;
    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IVault {
    function available(address _token) external view returns (uint256);
    function balance() external view returns (uint256);
    function deposit(address _token, uint256 _amount) external;
    function depositMultiple(address[] calldata _tokens, uint256[] calldata _amount) external;
    function earn(address _token, address _strategy) external;
    function getPricePerFullShare() external view returns (uint256);
    function getTokens() external view returns (address[] memory);
    function manager() external view returns (IManager);
    function withdraw(uint256 _amount, address _output) external;
    function withdrawAll(address _output) external;
    function withdrawFee(uint256 _amount) external view returns (uint256);
}

