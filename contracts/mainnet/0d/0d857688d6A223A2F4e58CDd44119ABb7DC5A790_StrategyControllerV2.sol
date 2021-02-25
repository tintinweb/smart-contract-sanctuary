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

pragma solidity 0.6.12;

interface IController {
    function balanceOf(address) external view returns (uint256);
    function earn(address, uint256) external;
    function investEnabled() external view returns (bool);
    function harvestStrategy(address) external;
    function strategyTokens(address) external returns (address);
    function vaults(address) external view returns (address);
    function want(address) external view returns (address);
    function withdraw(address, uint256) external;
    function withdrawFee(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IConverter {
    function token() external view returns (address _share);
    function convert(
        address _input,
        address _output,
        uint _inputAmount
    ) external returns (uint _outputAmount);
    function convert_rate(
        address _input,
        address _output,
        uint _inputAmount
    ) external view returns (uint _outputAmount);
    function convert_stables(
        uint[3] calldata amounts
    ) external returns (uint _shareAmount); // 0: DAI, 1: USDC, 2: USDT
    function calc_token_amount(
        uint[3] calldata amounts,
        bool deposit
    ) external view returns (uint _shareAmount);
    function calc_token_amount_withdraw(
        uint _shares,
        address _output
    ) external view returns (uint _outputAmount);
    function setStrategy(address _strategy, bool _status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IHarvester {
    function addStrategy(address, address, uint256) external;
    function removeStrategy(address, address, uint256) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IMetaVault {
    function balance() external view returns (uint);
    function setController(address _controller) external;
    function claimInsurance() external;
    function token() external view returns (address);
    function available() external view returns (uint);
    function withdrawFee(uint _amount) external view returns (uint);
    function earn() external;
    function calc_token_amount_deposit(uint[3] calldata amounts) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function convert_rate(address _input, uint _amount) external view returns (uint);
    function deposit(uint _amount, address _input, uint _min_mint_amount, bool _isStake) external;
    function harvest(address reserve, uint amount) external;
    function withdraw(uint _shares, address _output) external;
    function want() external view returns (address);
    function getPricePerFullShare() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IStrategy {
    function balanceOf() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function deposit() external;
    function harvest() external;
    function name() external view returns (string memory);
    function skim() external;
    function want() external view returns (address);
    function withdraw(address) external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultManager {
    function controllers(address) external view returns (bool);
    function getHarvestFeeInfo() external view returns (address, address, uint256, address, uint256, address, uint256);
    function governance() external view returns (address);
    function harvester() external view returns (address);
    function insuranceFee() external view returns (uint256);
    function insurancePool() external view returns (address);
    function insurancePoolFee() external view returns (uint256);
    function stakingPool() external view returns (address);
    function stakingPoolShareFee() external view returns (uint256);
    function strategist() external view returns (address);
    function treasury() external view returns (address);
    function treasuryBalance() external view returns (uint256);
    function treasuryFee() external view returns (uint256);
    function vaults(address) external view returns (bool);
    function withdrawalProtectionFee() external view returns (uint256);
    function yax() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../IController.sol";
import "../IConverter.sol";
import "../IHarvester.sol";
import "../IMetaVault.sol";
import "../IStrategy.sol";
import "../IVaultManager.sol";

/**
 * @title StrategyControllerV2
 * @notice This controller allows multiple strategies to be used
 * for a single token, and multiple tokens are supported.
 */
contract StrategyControllerV2 is IController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool public globalInvestEnabled;
    uint256 public maxStrategies;
    IVaultManager public vaultManager;

    struct TokenStrategy {
        address[] strategies;
        mapping(address => uint256) index;
        mapping(address => bool) active;
        mapping(address => uint256) caps;
    }

    // token => (want => converter)
    mapping(address => mapping(address => address)) public converters;
    // token => TokenStrategy
    mapping(address => TokenStrategy) internal tokenStrategies;
    // strategy => token
    mapping(address => address) public override strategyTokens;
    // token => vault
    mapping(address => address) public override vaults;
    // vault => token
    mapping(address => address) public vaultTokens;

    /**
     * @notice Logged when earn is called for a strategy
     */
    event Earn(address indexed strategy);

    /**
     * @notice Logged when harvest is called for a strategy
     */
    event Harvest(address indexed strategy);

    /**
     * @notice Logged when insurance is claimed for a vault
     */
    event InsuranceClaimed(address indexed vault);

    /**
     * @notice Logged when a converter is set
     */
    event SetConverter(address input, address output, address converter);

    /**
     * @notice Logged when a vault manager is set
     */
    event SetVaultManager(address vaultManager);

    /**
     * @notice Logged when a strategy is added for a token
     */
    event StrategyAdded(address indexed token, address indexed strategy, uint256 cap);

    /**
     * @notice Logged when a strategy is removed for a token
     */
    event StrategyRemoved(address indexed token, address indexed strategy);

    /**
     * @notice Logged when strategies are reordered for a token
     */
    event StrategiesReordered(
        address indexed token,
        address indexed strategy1,
        address indexed strategy2
    );

    /**
     * @param _vaultManager The address of the vaultManager
     */
    constructor(address _vaultManager) public {
        vaultManager = IVaultManager(_vaultManager);
        globalInvestEnabled = true;
        maxStrategies = 10;
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    /**
     * @notice Adds a strategy for a given token
     * @dev Only callable by governance
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _cap The cap of the strategy
     * @param _converter The converter of the strategy (can be zero address)
     * @param _canHarvest Flag for whether the strategy can be harvested
     * @param _timeout The timeout between harvests
     */
    function addStrategy(
        address _token,
        address _strategy,
        uint256 _cap,
        address _converter,
        bool _canHarvest,
        uint256 _timeout
    ) external onlyGovernance {
        // ensure the strategy hasn't been added
        require(!tokenStrategies[_token].active[_strategy], "active");
        address _want = IStrategy(_strategy).want();
        // ensure a converter is added if the strategy's want token is
        // different than the want token of the vault
        if (_want != IMetaVault(vaults[_token]).want()) {
            require(_converter != address(0), "!_converter");
            converters[_token][_want] = _converter;
            // enable the strategy on the converter
            IConverter(_converter).setStrategy(_strategy, true);
        }
        // get the index of the newly added strategy
        uint256 index = tokenStrategies[_token].strategies.length;
        // ensure we haven't added too many strategies already
        require(index < maxStrategies, "!maxStrategies");
        // push the strategy to the array of strategies
        tokenStrategies[_token].strategies.push(_strategy);
        // set the cap
        tokenStrategies[_token].caps[_strategy] = _cap;
        // set the index
        tokenStrategies[_token].index[_strategy] = index;
        // activate the strategy
        tokenStrategies[_token].active[_strategy] = true;
        // store the reverse mapping
        strategyTokens[_strategy] = _token;
        // if the strategy should be harvested
        if (_canHarvest) {
            // add it to the harvester
            IHarvester(vaultManager.harvester()).addStrategy(_token, _strategy, _timeout);
        }
        emit StrategyAdded(_token, _strategy, _cap);
    }

    /**
     * @notice Claims the insurance fund of a vault
     * @dev Only callable by governance
     * @dev When insurance is claimed by the controller, the insurance fund of
     * the vault is zeroed out, increasing the getPricePerFullShare and applying
     * the gains to everyone in the vault.
     * @param _vault The address of the vault
     */
    function claimInsurance(address _vault) external onlyGovernance {
        IMetaVault(_vault).claimInsurance();
        emit InsuranceClaimed(_vault);
    }

    /**
     * @notice Sets the address of the vault manager contract
     * @dev Only callable by governance
     * @param _vaultManager The address of the vault manager
     */
    function setVaultManager(address _vaultManager) external onlyGovernance {
        vaultManager = IVaultManager(_vaultManager);
        emit SetVaultManager(_vaultManager);
    }

    /**
     * (GOVERNANCE|STRATEGIST)-ONLY FUNCTIONS
     */

    /**
     * @notice Withdraws token from a strategy to governance
     * @dev Only callable by governance or the strategist
     * @param _strategy The address of the strategy
     * @param _token The address of the token
     */
    function inCaseStrategyGetStuck(
        address _strategy,
        address _token
    ) external onlyStrategist {
        IStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(
            vaultManager.governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    /**
     * @notice Withdraws token from the controller to governance
     * @dev Only callable by governance or the strategist
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) external onlyStrategist {
        IERC20(_token).safeTransfer(vaultManager.governance(), _amount);
    }

    /**
     * @notice Removes a strategy for a given token
     * @dev Only callable by governance or strategist
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _timeout The timeout between harvests
     */
    function removeStrategy(
        address _token,
        address _strategy,
        uint256 _timeout
    ) external onlyStrategist {
        TokenStrategy storage tokenStrategy = tokenStrategies[_token];
        // ensure the strategy is already added
        require(tokenStrategy.active[_strategy], "!active");
        // get the index of the strategy to remove
        uint256 index = tokenStrategy.index[_strategy];
        // get the index of the last strategy
        uint256 tail = tokenStrategy.strategies.length.sub(1);
        // get the address of the last strategy
        address replace = tokenStrategy.strategies[tail];
        // replace the removed strategy with the tail
        tokenStrategy.strategies[index] = replace;
        // set the new index for the replaced strategy
        tokenStrategy.index[replace] = index;
        // remove the duplicate replaced strategy
        tokenStrategy.strategies.pop();
        // remove the strategy's index
        delete tokenStrategy.index[_strategy];
        // remove the strategy's cap
        delete tokenStrategy.caps[_strategy];
        // deactivate the strategy
        delete tokenStrategy.active[_strategy];
        // pull funds from the removed strategy to the vault
        IStrategy(_strategy).withdrawAll();
        // remove the strategy from the harvester
        IHarvester(vaultManager.harvester()).removeStrategy(_token, _strategy, _timeout);
        // get the strategy want token
        address _want = IStrategy(_strategy).want();
        // if a converter is used
        if (_want != IMetaVault(vaults[_token]).want()) {
            // disable the strategy on the converter
            IConverter(converters[_token][_want]).setStrategy(_strategy, false);
        }
        emit StrategyRemoved(_token, _strategy);
    }

    /**
     * @notice Reorders two strategies for a given token
     * @dev Only callable by governance or strategist
     * @param _token The address of the token
     * @param _strategy1 The address of the first strategy
     * @param _strategy2 The address of the second strategy
     */
    function reorderStrategies(
        address _token,
        address _strategy1,
        address _strategy2
    ) external onlyStrategist {
        require(_strategy1 != _strategy2, "_strategy1 == _strategy2");
        TokenStrategy storage tokenStrategy = tokenStrategies[_token];
        // ensure the strategies are already added
        require(tokenStrategy.active[_strategy1]
             && tokenStrategy.active[_strategy2],
             "!active");
        // get the indexes of the strategies
        uint256 index1 = tokenStrategy.index[_strategy1];
        uint256 index2 = tokenStrategy.index[_strategy2];
        // set the new addresses at their indexes
        tokenStrategy.strategies[index1] = _strategy2;
        tokenStrategy.strategies[index2] = _strategy1;
        // update indexes
        tokenStrategy.index[_strategy1] = index2;
        tokenStrategy.index[_strategy2] = index1;
        emit StrategiesReordered(_token, _strategy1, _strategy2);
    }

    /**
     * @notice Sets/updates the cap of a strategy for a token
     * @dev Only callable by governance or strategist
     * @dev If the balance of the strategy is greater than the new cap (except if
     * the cap is 0), then withdraw the difference from the strategy to the vault.
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _cap The new cap of the strategy
     */
    function setCap(
        address _token,
        address _strategy,
        uint256 _cap
    ) external onlyStrategist {
        require(tokenStrategies[_token].active[_strategy], "!active");
        tokenStrategies[_token].caps[_strategy] = _cap;
        uint256 _balance = IStrategy(_strategy).balanceOf();
        // send excess funds (over cap) back to the vault
        if (_balance > _cap && _cap != 0) {
            uint256 _diff = _balance.sub(_cap);
            IStrategy(_strategy).withdraw(_diff);
        }
    }

    /**
     * @notice Sets/updates the converter for given input and output tokens
     * @dev Only callable by governance or strategist
     * @param _input The address of the input token
     * @param _output The address of the output token
     * @param _converter The address of the converter
     */
    function setConverter(
        address _input,
        address _output,
        address _converter
    ) external onlyStrategist {
        converters[_input][_output] = _converter;
        emit SetConverter(_input, _output, _converter);
    }

    /**
     * @notice Sets/updates the global invest enabled flag
     * @dev Only callable by governance or strategist
     * @param _investEnabled The new bool of the invest enabled flag
     */
    function setInvestEnabled(bool _investEnabled) external onlyStrategist {
        globalInvestEnabled = _investEnabled;
    }

    /**
     * @notice Sets/updates the maximum number of strategies for a token
     * @dev Only callable by governance or strategist
     * @param _maxStrategies The new value of the maximum strategies
     */
    function setMaxStrategies(uint256 _maxStrategies) external onlyStrategist {
        require(_maxStrategies > 0, "!_maxStrategies");
        maxStrategies = _maxStrategies;
    }

    /**
     * @notice Sets the address of a vault for a given token
     * @dev Only callable by governance or strategist
     * @param _token The address of the token
     * @param _vault The address of the vault
     */
    function setVault(address _token, address _vault) external onlyStrategist {
        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
        vaultTokens[_vault] = _token;
    }

    /**
     * @notice Withdraws all funds from a strategy
     * @dev Only callable by governance or the strategist
     * @param _strategy The address of the strategy
     */
    function withdrawAll(address _strategy) external onlyStrategist {
        // WithdrawAll sends 'want' to 'vault'
        IStrategy(_strategy).withdrawAll();
    }

    /**
     * (GOVERNANCE|STRATEGIST|HARVESTER)-ONLY FUNCTIONS
     */

    /**
     * @notice Harvests the specified strategy
     * @dev Only callable by governance, the strategist, or the harvester
     * @param _strategy The address of the strategy
     */
    function harvestStrategy(address _strategy) external override onlyHarvester {
        IStrategy(_strategy).harvest();
        emit Harvest(_strategy);
    }

    /**
     * VAULT-ONLY FUNCTIONS
     */

    /**
     * @notice Invests funds into a strategy
     * @dev Only callable by a vault
     * @param _token The address of the token
     * @param _amount The amount that will be invested
     */
    function earn(address _token, uint256 _amount) external override onlyVault(_token) {
        // get the first strategy that will accept the deposit
        address _strategy = getBestStrategyEarn(_token, _amount);
        // get the want token of the strategy
        address _want = IStrategy(_strategy).want();
        // if the depositing token is not what the strategy wants, convert it
        // then transfer it to the strategy
        if (_want != _token) {
            address _converter = converters[_token][_want];
            IERC20(_token).safeTransfer(_converter, _amount);
            _amount = IConverter(_converter).convert(
                _token,
                _want,
                _amount
            );
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        // call the strategy's deposit function
        IStrategy(_strategy).deposit();
        emit Earn(_strategy);
    }

    /**
     * @notice Withdraws funds from a strategy
     * @dev Only callable by a vault
     * @dev If the withdraw amount is greater than the first strategy given
     * by getBestStrategyWithdraw, this function will loop over strategies
     * until the requested amount is met.
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function withdraw(address _token, uint256 _amount) external override onlyVault(_token) {
        (
            address[] memory _strategies,
            uint256[] memory _amounts
        ) = getBestStrategyWithdraw(_token, _amount);
        for (uint i = 0; i < _strategies.length; i++) {
            // getBestStrategyWithdraw will return arrays larger than needed
            // if this happens, simply exit the loop
            if (_strategies[i] == address(0)) {
                break;
            }
            IStrategy(_strategies[i]).withdraw(_amounts[i]);
        }
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the balance of the sum of all strategies for a given token
     * @dev This function would make deposits more expensive for the more strategies
     * that are added for a given token
     * @param _token The address of the token
     */
    function balanceOf(address _token) external view override returns (uint256 _balance) {
        uint256 k = tokenStrategies[_token].strategies.length;
        for (uint i = 0; i < k; i++) {
            IStrategy _strategy = IStrategy(tokenStrategies[_token].strategies[i]);
            address _want = _strategy.want();
            if (_want != _token) {
                address _converter = converters[_token][_want];
                _balance = _balance.add(IConverter(_converter).convert_rate(
                    _want,
                    _token,
                    _strategy.balanceOf()
               ));
            } else {
                _balance = _balance.add(_strategy.balanceOf());
            }
        }
    }

    /**
     * @notice Returns the cap of a strategy for a given token
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     */
    function getCap(address _token, address _strategy) external view returns (uint256) {
        return tokenStrategies[_token].caps[_strategy];
    }

    /**
     * @notice Returns whether investing is enabled for the calling vault
     * @dev Should be called by the vault
     */
    function investEnabled() external view override returns (bool) {
        if (globalInvestEnabled) {
            return tokenStrategies[vaultTokens[msg.sender]].strategies.length > 0;
        }
        return false;
    }

    /**
     * @notice Returns all the strategies for a given token
     * @param _token The address of the token
     */
    function strategies(address _token) external view returns (address[] memory) {
        return tokenStrategies[_token].strategies;
    }

    /**
     * @notice Returns the want address of a given token
     * @dev Since strategies can have different want tokens, default to using the
     * want token of the vault for a given token.
     * @param _token The address of the token
     */
    function want(address _token) external view override returns (address) {
        return IMetaVault(vaults[_token]).want();
    }

    /**
     * @notice Returns the fee for withdrawing a specified amount
     * @param _amount The amount that will be withdrawn
     */
    function withdrawFee(
        address,
        uint256 _amount
    ) external view override returns (uint256 _fee) {
        return vaultManager.withdrawalProtectionFee().mul(_amount).div(10000);
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the best (optimistic) strategy for funds to be sent to with earn
     * @param _token The address of the token
     * @param _amount The amount that will be invested
     */
    function getBestStrategyEarn(
        address _token,
        uint256 _amount
    ) public view returns (address _strategy) {
        // get the index of the last strategy
        uint256 k = tokenStrategies[_token].strategies.length;
        // scan backwards from the index to the beginning of strategies
        for (uint i = k; i > 0; i--) {
            _strategy = tokenStrategies[_token].strategies[i - 1];
            // get the new balance if the _amount were added to the strategy
            uint256 balance = IStrategy(_strategy).balanceOf().add(_amount);
            uint256 cap = tokenStrategies[_token].caps[_strategy];
            // stop scanning if the deposit wouldn't go over the cap
            if (balance <= cap || cap == 0) {
                break;
            }
        }
        // if never broken from the loop, use the last scanned strategy
        // this could cause it to go over cap if (for some reason) no strategies
        // were added with 0 cap
    }

    /**
     * @notice Returns the best (optimistic) strategy for funds to be withdrawn from
     * @dev Since Solidity doesn't support dynamic arrays in memory, the returned arrays
     * from this function will always be the same length as the amount of strategies for
     * a token. Check that _strategies[i] != address(0) when consuming to know when to
     * break out of the loop.
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function getBestStrategyWithdraw(
        address _token,
        uint256 _amount
    ) public view returns (
        address[] memory _strategies,
        uint256[] memory _amounts
    ) {
        // get the length of strategies
        uint256 k = tokenStrategies[_token].strategies.length;
        // initialize fixed-length memory arrays
        _strategies = new address[](k);
        _amounts = new uint256[](k);
        // scan forward from the the beginning of strategies
        for (uint i = 0; i < k; i++) {
            address _strategy = tokenStrategies[_token].strategies[i];
            _strategies[i] = _strategy;
            // get the balance of the strategy
            uint256 _balance = IStrategy(_strategy).balanceOf();
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
     * MODIFIERS
     */

    modifier onlyGovernance() {
        require(msg.sender == vaultManager.governance(), "!governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == vaultManager.strategist()
             || msg.sender == vaultManager.governance(),
             "!strategist"
        );
        _;
    }

    modifier onlyHarvester() {
        require(
            msg.sender == vaultManager.harvester() ||
            msg.sender == vaultManager.strategist() ||
            msg.sender == vaultManager.governance(),
            "!harvester"
        );
        _;
    }

    modifier onlyVault(address _token) {
        require(msg.sender == vaults[_token], "!vault");
        _;
    }
}