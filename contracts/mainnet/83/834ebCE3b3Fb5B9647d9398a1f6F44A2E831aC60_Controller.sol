// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IController.sol";
import "../interfaces/IConverter.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IHarvester.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IManager.sol";

/**
 * @title Controller
 * @notice This controller allows multiple strategies to be used
 * for a single vault supporting multiple tokens.
 */
contract Controller is IController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IManager public immutable override manager;

    bool public globalInvestEnabled;
    uint256 public maxStrategies;

    struct VaultDetail {
        address converter;
        uint256 balance;
        address[] strategies;
        mapping(address => uint256) balances;
        mapping(address => uint256) index;
        mapping(address => uint256) caps;
    }

    // vault => Vault
    mapping(address => VaultDetail) internal _vaultDetails;
    // strategy => vault
    mapping(address => address) internal _vaultStrategies;

    /**
     * @notice Logged when harvest is called for a strategy
     */
    event Harvest(address indexed strategy);

    /**
     * @notice Logged when a strategy is added for a vault
     */
    event StrategyAdded(address indexed vault, address indexed strategy, uint256 cap);

    /**
     * @notice Logged when a strategy is removed for a vault
     */
    event StrategyRemoved(address indexed vault, address indexed strategy);

    /**
     * @notice Logged when strategies are reordered for a vault
     */
    event StrategiesReordered(
        address indexed vault,
        address indexed strategy1,
        address indexed strategy2
    );

    /**
     * @param _manager The address of the manager
     */
    constructor(
        address _manager
    )
        public
    {
        manager = IManager(_manager);
        globalInvestEnabled = true;
        maxStrategies = 10;
    }

    /**
     * STRATEGIST-ONLY FUNCTIONS
     */

    /**
     * @notice Adds a strategy for a given vault
     * @param _vault The address of the vault
     * @param _strategy The address of the strategy
     * @param _cap The cap of the strategy
     * @param _timeout The timeout between harvests
     */
    function addStrategy(
        address _vault,
        address _strategy,
        uint256 _cap,
        uint256 _timeout
    )
        external
        notHalted
        onlyStrategist
        onlyStrategy(_strategy)
    {
        require(manager.allowedVaults(_vault), "!_vault");
        if(IStrategy(_strategy).want() != IVault(_vault).getToken()) {
            require(_vaultDetails[_vault].converter != address(0), "!converter");
        }
        // checking if strategy is already added
        require(_vaultStrategies[_strategy] == address(0), "Strategy is already added"); 
        // get the index of the newly added strategy
        uint256 index = _vaultDetails[_vault].strategies.length;
        // ensure we haven't added too many strategies already
        require(index < maxStrategies, "!maxStrategies");
        // push the strategy to the array of strategies
        _vaultDetails[_vault].strategies.push(_strategy);
        // set the cap
        _vaultDetails[_vault].caps[_strategy] = _cap;
        // set the index
        _vaultDetails[_vault].index[_strategy] = index;
        // store the mapping of strategy to the vault
        _vaultStrategies[_strategy] = _vault;
        if (_timeout > 0) {
            // add it to the harvester
            IHarvester(manager.harvester()).addStrategy(_vault, _strategy, _timeout);
        }
        emit StrategyAdded(_vault, _strategy, _cap);
    }

    /**
     * @notice Withdraws token from a strategy to the treasury address as returned by the manager
     * @param _strategy The address of the strategy
     * @param _token The address of the token
     */
    function inCaseStrategyGetStuck(
        address _strategy,
        address _token
    )
        external
        onlyStrategist
    {
        IStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(
            manager.treasury(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    /**
     * @notice Withdraws token from the controller to the treasury
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    )
        external
        onlyStrategist
    {
        IERC20(_token).safeTransfer(manager.treasury(), _amount);
    }

    /**
     * @notice Removes a strategy for a given token
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
        notHalted
        onlyStrategist
    {
        require(manager.allowedVaults(_vault), "!_vault");
        VaultDetail storage vaultDetail = _vaultDetails[_vault];
        // get the index of the strategy to remove
        uint256 index = vaultDetail.index[_strategy];
        // get the index of the last strategy
        uint256 tail = vaultDetail.strategies.length.sub(1);
        // get the address of the last strategy
        address replace = vaultDetail.strategies[tail];
        // replace the removed strategy with the tail
        vaultDetail.strategies[index] = replace;
        // set the new index for the replaced strategy
        vaultDetail.index[replace] = index;
        // remove the duplicate replaced strategy
        vaultDetail.strategies.pop();
        // remove the strategy's index
        delete vaultDetail.index[_strategy];
        // remove the strategy's cap
        delete vaultDetail.caps[_strategy];
        // remove the strategy's balance
        delete vaultDetail.balances[_strategy];
        // remove the mapping of strategy to the vault
        delete _vaultStrategies[_strategy];
        // pull funds from the removed strategy to the vault
        IStrategy(_strategy).withdrawAll();
        // remove the strategy from the harvester
        IHarvester(manager.harvester()).removeStrategy(_vault, _strategy, _timeout);
        emit StrategyRemoved(_vault, _strategy);
    }

    /**
     * @notice Reorders two strategies for a given vault
     * @param _vault The address of the vault
     * @param _strategy1 The address of the first strategy
     * @param _strategy2 The address of the second strategy
     */
    function reorderStrategies(
        address _vault,
        address _strategy1,
        address _strategy2
    )
        external
        notHalted
        onlyStrategist
    {
        require(manager.allowedVaults(_vault), "!_vault");
        require(_vaultStrategies[_strategy1] == _vault, "!_strategy1");
        require(_vaultStrategies[_strategy2] == _vault, "!_strategy2");
        VaultDetail storage vaultDetail = _vaultDetails[_vault];
        // get the indexes of the strategies
        uint256 index1 = vaultDetail.index[_strategy1];
        uint256 index2 = vaultDetail.index[_strategy2];
        // set the new addresses at their indexes
        vaultDetail.strategies[index1] = _strategy2;
        vaultDetail.strategies[index2] = _strategy1;
        // update indexes
        vaultDetail.index[_strategy1] = index2;
        vaultDetail.index[_strategy2] = index1;
        emit StrategiesReordered(_vault, _strategy1, _strategy2);
    }

    /**
     * @notice Sets/updates the cap of a strategy for a vault
     * @dev If the balance of the strategy is greater than the new cap (except if
     * the cap is 0), then withdraw the difference from the strategy to the vault.
     * @param _vault The address of the vault
     * @param _strategy The address of the strategy
     * @param _cap The new cap of the strategy
     */
    function setCap(
        address _vault,
        address _strategy,
        uint256 _cap,
        address _convert
    )
        external
        notHalted
        onlyStrategist
        onlyStrategy(_strategy)
    {
        _vaultDetails[_vault].caps[_strategy] = _cap;
        uint256 _balance = IStrategy(_strategy).balanceOf();
        // send excess funds (over cap) back to the vault
        if (_balance > _cap && _cap != 0) {
            uint256 _diff = _balance.sub(_cap);
            IStrategy(_strategy).withdraw(_diff);
            updateBalance(_vault, _strategy);
            _balance = IStrategy(_strategy).balanceOf();
            _vaultDetails[_vault].balance = _vaultDetails[_vault].balance.sub(_diff);
            address _want = IStrategy(_strategy).want();
            _balance = IERC20(_want).balanceOf(address(this));
            if (_convert != address(0)) {
                IConverter _converter = IConverter(_vaultDetails[_vault].converter);
                IERC20(_want).safeTransfer(address(_converter), _balance);
                _balance = _converter.convert(_want, _convert, _balance, 1);
                IERC20(_convert).safeTransfer(_vault, _balance);
            } else {
                IERC20(_want).safeTransfer(_vault, _balance);
            }
        }
    }

    /**
     * @notice Sets/updates the converter for a given vault
     * @param _vault The address of the vault
     * @param _converter The address of the converter
     */
    function setConverter(
        address _vault,
        address _converter
    )
        external
        notHalted
        onlyStrategist
    {
        require(manager.allowedConverters(_converter), "!allowedConverters");
        _vaultDetails[_vault].converter = _converter;
    }

    /**
     * @notice Sets/updates the global invest enabled flag
     * @param _investEnabled The new bool of the invest enabled flag
     */
    function setInvestEnabled(
        bool _investEnabled
    )
        external
        notHalted
        onlyStrategist
    {
        globalInvestEnabled = _investEnabled;
    }

    /**
     * @notice Sets/updates the maximum number of strategies for a vault
     * @param _maxStrategies The new value of the maximum strategies
     */
    function setMaxStrategies(
        uint256 _maxStrategies
    )
        external
        notHalted
        onlyStrategist
    {
        maxStrategies = _maxStrategies;
    }

    function skim(
        address _strategy
    )
        external
        onlyStrategist
        onlyStrategy(_strategy)
    {
        address _want = IStrategy(_strategy).want();
        IStrategy(_strategy).skim();
        IERC20(_want).safeTransfer(_vaultStrategies[_strategy], IERC20(_want).balanceOf(address(this)));
    }

    /**
     * @notice Withdraws all funds from a strategy
     * @param _strategy The address of the strategy
     * @param _convert The token address to convert to
     */
    function withdrawAll(
        address _strategy,
        address _convert
    )
        external
        override
        onlyStrategist
        onlyStrategy(_strategy)
    {
        address _want = IStrategy(_strategy).want();
        IStrategy(_strategy).withdrawAll();
        uint256 _amount = IERC20(_want).balanceOf(address(this));
        address _vault = _vaultStrategies[_strategy];
        updateBalance(_vault, _strategy);
        if (_convert != address(0)) {
            IConverter _converter = IConverter(_vaultDetails[_vault].converter);
            IERC20(_want).safeTransfer(address(_converter), _amount);
            _amount = _converter.convert(_want, _convert, _amount, 1);
            IERC20(_convert).safeTransfer(_vault, _amount);
        } else {
            IERC20(_want).safeTransfer(_vault, _amount);
        }
        uint256 _balance = _vaultDetails[_vault].balance;
        if (_balance >= _amount) {
            _vaultDetails[_vault].balance = _balance.sub(_amount);
        } else {
            _vaultDetails[_vault].balance = 0;
        }
    }

    /**
     * HARVESTER-ONLY FUNCTIONS
     */

    /**
     * @notice Harvests the specified strategy
     * @param _strategy The address of the strategy
     */
    function harvestStrategy(
        address _strategy,
        uint256[] calldata _estimates
    )
        external
        override
        notHalted
        onlyHarvester
        onlyStrategy(_strategy)
    {
        uint256 _before = IStrategy(_strategy).balanceOf();
        IStrategy(_strategy).harvest(_estimates);
        uint256 _after = IStrategy(_strategy).balanceOf();
        address _vault = _vaultStrategies[_strategy];
        _vaultDetails[_vault].balance = _vaultDetails[_vault].balance.add(_after.sub(_before));
        _vaultDetails[_vault].balances[_strategy] = _after;
        emit Harvest(_strategy);
    }

    /**
     * VAULT-ONLY FUNCTIONS
     */

    /**
     * @notice Invests funds into a strategy
     * @param _strategy The address of the strategy
     * @param _token The address of the token
     * @param _amount The amount that will be invested
     */
    function earn(
        address _strategy,
        address _token,
        uint256 _amount
    )
        external
        override
        notHalted
        onlyStrategy(_strategy)
        onlyVault()
    {
        // get the want token of the strategy
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            IConverter _converter = IConverter(_vaultDetails[msg.sender].converter);
            IERC20(_token).safeTransfer(address(_converter), _amount);
            // TODO: do estimation for received
            _amount = _converter.convert(_token, _want, _amount, 1);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        _vaultDetails[msg.sender].balance = _vaultDetails[msg.sender].balance.add(_amount);
        // call the strategy deposit function
        IStrategy(_strategy).deposit();
        updateBalance(msg.sender, _strategy);
    }

    /**
     * @notice Withdraws funds from a strategy
     * @dev If the withdraw amount is greater than the first strategy given
     * by getBestStrategyWithdraw, this function will loop over strategies
     * until the requested amount is met.
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function withdraw(
        address _token,
        uint256 _amount
    )
        external
        override
        onlyVault()
    {
        (
            address[] memory _strategies,
            uint256[] memory _amounts
        ) = getBestStrategyWithdraw(msg.sender, _amount);
        for (uint i = 0; i < _strategies.length; i++) {
            // getBestStrategyWithdraw will return arrays larger than needed
            // if this happens, simply exit the loop
            if (_strategies[i] == address(0)) {
                break;
            }
            IStrategy(_strategies[i]).withdraw(_amounts[i]);
            updateBalance(msg.sender, _strategies[i]);
            address _want = IStrategy(_strategies[i]).want();
            if (_want != _token) {
                address _converter = _vaultDetails[msg.sender].converter;
                IERC20(_want).safeTransfer(_converter, _amounts[i]);
                // TODO: do estimation for received
                IConverter(_converter).convert(_want, _token, _amounts[i], 1);
            }
        }
        _amount = IERC20(_token).balanceOf(address(this));
        _vaultDetails[msg.sender].balance = _vaultDetails[msg.sender].balance.sub(_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the rough balance of the sum of all strategies for a given vault
     * @dev This function is optimized to prevent looping over all strategy balances,
     * and instead the controller tracks the earn, withdraw, and harvest amounts.
     */
    function balanceOf()
        external
        view
        override
        returns (uint256 _balance)
    {
        return _vaultDetails[msg.sender].balance;
    }

    /**
     * @notice Returns the converter assigned for the given vault
     * @param _vault Address of the vault
     */
    function converter(
        address _vault
    )
        external
        view
        override
        returns (address)
    {
        return _vaultDetails[_vault].converter;
    }

    /**
     * @notice Returns the cap of a strategy for a given vault
     * @param _vault The address of the vault
     * @param _strategy The address of the strategy
     */
    function getCap(
        address _vault,
        address _strategy
    )
        external
        view
        returns (uint256)
    {
        return _vaultDetails[_vault].caps[_strategy];
    }

    /**
     * @notice Returns whether investing is enabled for the calling vault
     * @dev Should be called by the vault
     */
    function investEnabled()
        external
        view
        override
        returns (bool)
    {
        if (globalInvestEnabled) {
            return _vaultDetails[msg.sender].strategies.length > 0;
        }
        return false;
    }

    /**
     * @notice Returns all the strategies for a given vault
     * @param _vault The address of the vault
     */
    function strategies(
        address _vault
    )
        external
        view
        returns (address[] memory)
    {
        return _vaultDetails[_vault].strategies;
    }

    /**
     * @notice Returns the length of the strategies of the calling vault
     * @dev This function is expected to be called by a vault
     */
    function strategies()
        external
        view
        override
        returns (uint256)
    {
        return _vaultDetails[msg.sender].strategies.length;
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @notice Returns the best (optimistic) strategy for funds to be withdrawn from
     * @dev Since Solidity doesn't support dynamic arrays in memory, the returned arrays
     * from this function will always be the same length as the amount of strategies for
     * a token. Check that _strategies[i] != address(0) when consuming to know when to
     * break out of the loop.
     * @param _vault The address of the vault
     * @param _amount The amount that will be withdrawn
     */
    function getBestStrategyWithdraw(
        address _vault,
        uint256 _amount
    )
        internal
        view
        returns (
            address[] memory _strategies,
            uint256[] memory _amounts
        )
    {
        // get the length of strategies for a single token
        uint256 k = _vaultDetails[_vault].strategies.length;
        // initialize fixed-length memory arrays
        _strategies = new address[](k);
        _amounts = new uint256[](k);
        address _strategy;
        uint256 _balance;
        // scan forward from the the beginning of strategies
        for (uint i = 0; i < k; i++) {
            _strategy = _vaultDetails[_vault].strategies[i];
            _strategies[i] = _strategy;
            // get the balance of the strategy
            _balance = _vaultDetails[_vault].balances[_strategy];
            // if the strategy doesn't have the balance to cover the withdraw
            if (_balance < _amount) {
                // withdraw what we can and add to the _amounts
                _amounts[i] = _balance;
                _amount = _amount.sub(_balance);
            } else {
                // stop scanning if the balance is more than the withdraw amount
                _amounts[i] = _amount;
                break;
            }
        }
    }

    /**
     * @notice Updates the stored balance of a given strategy for a vault
     * @param _vault The address of the vault
     * @param _strategy The address of the strategy
     */
    function updateBalance(
        address _vault,
        address _strategy
    )
        internal
    {
        _vaultDetails[_vault].balances[_strategy] = IStrategy(_strategy).balanceOf();
    }

    /**
     * MODIFIERS
     */

    /**
     * @notice Reverts if the protocol is halted
     */
    modifier notHalted() {
        require(!manager.halted(), "halted");
        _;
    }

    /**
     * @notice Reverts if the caller is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == manager.governance(), "!governance");
        _;
    }

    /**
     * @notice Reverts if the caller is not the strategist
     */
    modifier onlyStrategist() {
        require(msg.sender == manager.strategist(), "!strategist");
        _;
    }

    /**
     * @notice Reverts if the strategy is not allowed in the manager
     */
    modifier onlyStrategy(address _strategy) {
        require(manager.allowedStrategies(_strategy), "!allowedStrategy");
        _;
    }

    /**
     * @notice Reverts if the caller is not the harvester
     */
    modifier onlyHarvester() {
        require(msg.sender == manager.harvester(), "!harvester");
        _;
    }

    /**
     * @notice Reverts if the caller is not the vault for the given token
     */
    modifier onlyVault() {
        require(manager.allowedVaults(msg.sender), "!vault");
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

interface IHarvester {
    function addStrategy(address, address, uint256) external;
    function manager() external view returns (IManager);
    function removeStrategy(address, address, uint256) external;
    function slippage() external view returns (uint256);
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
pragma solidity ^0.6.2;

interface ISwap {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external;
    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] memory);
}