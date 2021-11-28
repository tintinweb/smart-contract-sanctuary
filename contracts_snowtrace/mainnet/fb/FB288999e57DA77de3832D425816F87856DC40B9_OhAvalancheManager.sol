// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {OhManager} from "@ohfinance/oh-contracts/contracts/manager/OhManager.sol";
import {OhSubscriber} from "@ohfinance/oh-contracts/contracts/registry/OhSubscriber.sol";
import {TransferHelper} from "@ohfinance/oh-contracts/contracts/libraries/TransferHelper.sol";
import {ILiquidator} from "@ohfinance/oh-contracts/contracts/interfaces/ILiquidator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAvalancheManager} from "../interfaces/manager/IAvalancheManager.sol";

contract OhAvalancheManager is OhManager, IAvalancheManager {
    address public override burner;

    /// @notice Deploy the Manager with the Registry reference
    /// @dev Sets initial buyback and management fee parameters
    /// @param registry_ The address of the registry
    /// @param token_ The address of the Oh! Token
    constructor(address registry_, address token_) OhManager(registry_, token_) {}

    /// @notice Perform a token buyback with accrued revenue
    /// @dev Burns all proceeds
    /// @param from The address of the token to liquidate for Oh! Tokens
    function buyback(address from) external override defense {
        // get token, liquidator, and liquidation amount
        address _token = token;
        address liquidator = liquidators[from][_token];
        uint256 amount = IERC20(from).balanceOf(address(this));

        // send to liquidator, buyback and burn
        TransferHelper.safeTokenTransfer(liquidator, from, amount);
        uint256 received = ILiquidator(liquidator).liquidate(address(this), from, _token, amount, 1);

        emit Buyback(from, amount, received);
    }

    function burn() external override defense {
        require(burner != address(0), "Manager: No Burner");
        uint256 amount = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTokenTransfer(burner, token, amount);
    }

    function setBurner(address _burner) external override onlyGovernance {
        burner = _burner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IBank} from "../interfaces/bank/IBank.sol";
import {ILiquidator} from "../interfaces/ILiquidator.sol";
import {IManager} from "../interfaces/IManager.sol";
import {IToken} from "../interfaces/IToken.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {OhSubscriber} from "../registry/OhSubscriber.sol";

/// @title Oh! Finance Manager
/// @notice The Manager contains references to all active banks, strategies, and liquidation contracts.
/// @dev This contract is used as the main control point for executing strategies
contract OhManager is OhSubscriber, IManager {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    /// @notice Denominator for calculating protocol fees
    uint256 public constant FEE_DENOMINATOR = 1000;

    /// @notice Maximum buyback fee, 50%
    uint256 public constant MAX_BUYBACK_FEE = 500;

    /// @notice Minimum buyback fee, 10%
    uint256 public constant MIN_BUYBACK_FEE = 100;

    /// @notice Maximum management fee, 10%
    uint256 public constant MAX_MANAGEMENT_FEE = 100;

    /// @notice Minimum management fee, 0%
    uint256 public constant MIN_MANAGEMENT_FEE = 0;

    /// @notice The address of the Oh! Finance Token
    address public override token;

    /// @notice The amount of profits reserved for protocol buybacks, base 1000
    uint256 public override buybackFee;

    /// @notice The amount of profits reserved for fund management, base 1000
    uint256 public override managementFee;

    /// @notice The mapping of `from` token to `to` token to liquidator contract
    mapping(address => mapping(address => address)) public override liquidators;

    /// @notice The mapping of contracts that are whitelisted for Bank use/management
    mapping(address => bool) public override whitelisted;

    /// @dev The set of Banks approved for investing
    EnumerableSet.AddressSet internal _banks;

    /// @dev The mapping of Banks to active Strategies
    mapping(address => EnumerableSet.AddressSet) internal _strategies;

    /// @dev The mapping of Banks to next Strategy index it will deposit to
    mapping(address => uint8) internal _depositQueue;

    /// @dev The mapping of Banks to next Strategy index it will withdraw from
    mapping(address => uint8) internal _withdrawQueue;

    /// @notice Emitted when a Bank's capital is rebalanced
    event Rebalance(address indexed bank);

    /// @notice Emitted when a Bank's capital is invested in a single Strategy 
    event Finance(address indexed bank, address indexed strategy);

    /// @notice Emitted when a Bank's capital is invested in all Strategies
    event FinanceAll(address indexed bank);

    /// @notice Emitted when a buyback is performed with an amount of from tokens
    event Buyback(address indexed from, uint256 amount, uint256 buybackAmount);

    /// @notice Emitted when a Bank realizes profit via liquidation 
    event AccrueRevenue(
        address indexed bank,
        address indexed strategy,
        uint256 profitAmount,
        uint256 buybackAmount,
        uint256 managementAmount
    );

    /// @notice Only allow function calls if sender is an approved Bank
    /// @param sender The address of the caller to validate
    modifier onlyBank(address sender) {
        require(_banks.contains(sender), "Manager: Only Bank");
        _;
    }
    
    /// @notice Only allow function calls if sender is an approved Strategy
    /// @param bank The address of the Bank that uses the Strategy
    /// @param sender The address of the caller to validate
    modifier onlyStrategy(address bank, address sender) {
        require(_strategies[bank].contains(sender), "Manager: Only Strategy");
        _;
    }

    /// @notice Only allow EOAs or Whitelisted contracts to interact
    /// @dev Prevents sandwich / flash loan attacks & re-entrancy
    modifier defense {
        require(msg.sender == tx.origin || whitelisted[msg.sender], "Manager: Only EOA or Whitelist");
        _;
    }

    /// @notice Deploy the Manager with the Registry reference
    /// @dev Sets initial buyback and management fee parameters
    /// @param registry_ The address of the registry
    /// @param token_ The address of the Oh! Token
    constructor(address registry_, address token_) OhSubscriber(registry_) {
        token = token_;
        buybackFee = 200; // 20%
        managementFee = 20; // 2%
    }

    /// @notice Get the Bank
    function banks(uint256 i) external view override returns (address) {
        return _banks.at(i);
    }

    function totalBanks() external view override returns (uint256) {
        return _banks.length();
    }

    /// @notice Get the Strategy at a given index for a given Bank
    /// @param bank The address of the Bank that contains the Strategy
    /// @param i The Bank queue index to check
    function strategies(address bank, uint256 i) external view override returns (address) {
        return _strategies[bank].at(i);
    }

    /// @notice Get total number of strategies for a given bank
    /// @param bank The Bank we are checking
    /// @return Amount of active strategies
    function totalStrategies(address bank) external view override returns (uint256) {
        return _strategies[bank].length();
    }

    /// @notice Get the index of the Strategy to withdraw from for a given Bank
    /// @param bank The Bank to check the next Strategy for
    /// @return The index of the Strategy
    function withdrawIndex(address bank) external view override returns (uint256) {
        return _withdrawQueue[bank];
    }

    /// @notice Set the withdrawal index
    /// @param i The index value
    function setWithdrawIndex(uint256 i) external override onlyBank(msg.sender) {
        _withdrawQueue[msg.sender] = uint8(i);
    }

    /// @notice Rebalance Bank exposure by withdrawing all, then evenly distributing underlying to all strategies
    /// @param bank The bank to rebalance
    function rebalance(address bank) external override defense onlyBank(bank) {
        // Exit all strategies
        uint256 length = _strategies[bank].length();
        for (uint256 i; i < length; i++) {
            IBank(bank).exitAll(_strategies[bank].at(i));
        }

        // Re-invest underlying evenly
        uint256 toInvest = IBank(bank).underlyingBalance();
        for (uint256 i; i < length; i++) {
            uint256 amount = toInvest / length;
            IBank(bank).invest(_strategies[bank].at(i), amount);
        }

        emit Rebalance(bank);
    }

    /// @notice Finance the next Strategy in the Bank queue with all available underlying
    /// @param bank The address of the Bank to finance
    /// @dev Only allow this function to be called on approved Banks
    function finance(address bank) external override defense onlyBank(bank) {
        uint256 length = _strategies[bank].length();
        require(length > 0, "Manager: No Strategies");

        // get the next Strategy, reset if current index out of bounds
        uint8 i;
        uint8 queued = _depositQueue[bank];
        if (queued < length) {
            i = queued;
        } else {
            i = 0;
        }
        address strategy = _strategies[bank].at(i);

        // finance the strategy, increment index and update delay (+24h)
        IBank(bank).investAll(strategy);
        _depositQueue[bank] = i + 1;

        emit Finance(bank, strategy);
    }

    /// @notice Evenly finance underlying to all strategies
    /// @param bank The address of the Bank to finance
    /// @dev Deposit queue not needed here as all Strategies are equally invested in
    /// @dev Only allow this function to be called on approved Banks
    function financeAll(address bank) external override defense onlyBank(bank) {
        uint256 length = _strategies[bank].length();
        require(length > 0, "Manager: No Strategies");

        uint256 toInvest = IBank(bank).underlyingBalance();
        for (uint256 i; i < length; i++) {
            uint256 amount = toInvest / length;
            IBank(bank).invest(_strategies[bank].at(i), amount);
        }

        emit FinanceAll(bank);
    }

    /// @notice Perform a token buyback with accrued revenue
    /// @dev Burns all proceeds
    /// @param from The address of the token to liquidate for Oh! Tokens
    function buyback(address from) external virtual override defense {
        // get token, liquidator, and liquidation amount
        address _token = token;
        address liquidator = liquidators[from][_token];
        uint256 amount = IERC20(from).balanceOf(address(this));

        // send to liquidator, buyback and burn
        TransferHelper.safeTokenTransfer(liquidator, from, amount);
        uint256 received = ILiquidator(liquidator).liquidate(address(this), from, _token, amount, 1);
        IToken(_token).burn(received);

        emit Buyback(from, amount, received);
    }

    /// @notice Accrue revenue from a Strategy
    /// @dev Only callable by approved Strategies
    /// @param bank The address of the Bank which uses the Strategy
    /// @param amount The total amount of profit received from liquidation
    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external override onlyStrategy(bank, msg.sender) {
        // calculate protocol and management fees, find remaining
        uint256 fee = amount.mul(buybackFee).div(FEE_DENOMINATOR);
        uint256 reward = amount.mul(managementFee).div(FEE_DENOMINATOR);
        uint256 remaining = amount.sub(fee).sub(reward);

        // send original function caller the management fee, transfer remaining to the Strategy
        TransferHelper.safeTokenTransfer(tx.origin, underlying, reward);
        TransferHelper.safeTokenTransfer(msg.sender, underlying, remaining);

        emit AccrueRevenue(bank, msg.sender, remaining, fee, reward);
    }

    /// @notice Exit a given strategy for a given bank
    /// @param bank The bank that will be used to exit the strategy
    /// @param strategy The strategy to be exited
    function exit(address bank, address strategy) public onlyGovernance {
        IBank(bank).exitAll(strategy);
    }

    /// @notice Exit from all strategies for a given bank
    /// @param bank The bank that will be used to exit the strategy
    function exitAll(address bank) public override onlyGovernance {
        uint256 length = _strategies[bank].length();
        for (uint256 i = 0; i < length; i++) {
            IBank(bank).exitAll(_strategies[bank].at(i));
        }
    }

    /// @notice Adds or removes a Bank for investment
    /// @dev Only Governance can call this function
    /// @param _bank the bank to be approved/unapproved
    /// @param _approved the approval status of the bank
    function setBank(address _bank, bool _approved) external onlyGovernance {
        require(_bank.isContract(), "Manager: Not Contract");
        bool approved = _banks.contains(_bank);
        require(approved != _approved, "Manager: No Change");

        // if Bank is already approved, withdraw all capital
        if (approved) {
            exitAll(_bank);
            _banks.remove(_bank);
        } else {
            _banks.add(_bank);
        }
    }

    /// @notice Adds or removes a Strategy for a given Bank
    /// @param _bank the bank which uses the strategy
    /// @param _strategy the strategy to be approved/unapproved
    /// @param _approved the approval status of the Strategy
    /// @dev Only Governance can call this function
    function setStrategy(address _bank, address _strategy, bool _approved) external onlyGovernance {
        require(_strategy.isContract() && _bank.isContract(), "Manager: Not Contract");
        bool approved = _strategies[_bank].contains(_strategy);
        require(approved != _approved, "Manager: No Change");

        // if Strategy is already approved, withdraw all capital
        if (approved) {
            exit(_bank, _strategy);
            _strategies[_bank].remove(_strategy);
        } else {
            _strategies[_bank].add(_strategy);
        }
    }

    /// @notice Sets the Liquidator contract for a given token
    /// @param _liquidator the liquidator contract
    /// @param _from the token we have to liquidate
    /// @param _to the token we want to receive
    /// @dev Only Governance can call this function
    function setLiquidator(
        address _liquidator,
        address _from,
        address _to
    ) external onlyGovernance {
        require(_liquidator.isContract(), "Manager: Not Contract");
        liquidators[_from][_to] = _liquidator;
    }

    /// @notice Whitelists strategy for Bank use/management
    /// @param _contract the strategy contract
    /// @param _whitelisted the whitelisted status of the strategy
    /// @dev Only Governance can call this function
    function setWhitelisted(address _contract, bool _whitelisted) external onlyGovernance {
        require(_contract.isContract(), "Registry: Not Contract");
        whitelisted[_contract] = _whitelisted;
    }

    /// @notice Sets the protocol buyback percentage (Profit Share)
    /// @param _buybackFee The new buyback fee
    /// @dev Only Governance; base 1000, 1% = 10
    function setBuybackFee(uint256 _buybackFee) external onlyGovernance {
        require(_buybackFee > MIN_BUYBACK_FEE, "Registry: Invalid Buyback");
        require(_buybackFee < MAX_BUYBACK_FEE, "Registry: Buyback Too High");
        buybackFee = _buybackFee;
    }

    /// @notice Sets the protocol management fee percentage
    /// @param _managementFee The new management fee
    /// @dev Only Governance; base 1000, 1% = 10
    function setManagementFee(uint256 _managementFee) external onlyGovernance {
        require(_managementFee > MIN_MANAGEMENT_FEE, "Registry: Invalid Mgmt");
        require(_managementFee < MAX_MANAGEMENT_FEE, "Registry: Mgmt Too High");
        managementFee = _managementFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ISubscriber} from "../interfaces/ISubscriber.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";

/// @title Oh! Finance Subscriber
/// @notice Base Oh! Finance contract used to control access throughout the protocol
abstract contract OhSubscriber is ISubscriber {
    address internal _registry;

    /// @notice Only allow authorized addresses (governance or manager) to execute a function
    modifier onlyAuthorized {
        require(msg.sender == governance() || msg.sender == manager(), "Subscriber: Only Authorized");
        _;
    }

    /// @notice Only allow the governance address to execute a function
    modifier onlyGovernance {
        require(msg.sender == governance(), "Subscriber: Only Governance");
        _;
    }

    /// @notice Construct contract with the Registry
    /// @param registry_ The address of the Registry
    constructor(address registry_) {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");
        _registry = registry_;
    }

    /// @notice Get the Governance address
    /// @return The current Governance address
    function governance() public view override returns (address) {
        return IRegistry(registry()).governance();
    }

    /// @notice Get the Manager address
    /// @return The current Manager address
    function manager() public view override returns (address) {
        return IRegistry(registry()).manager();
    }

    /// @notice Get the Registry address
    /// @return The current Registry address
    function registry() public view override returns (address) {
        return _registry;
    }

    /// @notice Set the Registry for the contract. Only callable by Governance.
    /// @param registry_ The new registry
    /// @dev Requires sender to be Governance of the new Registry to avoid bricking.
    /// @dev Ideally should not be used
    function setRegistry(address registry_) external onlyGovernance {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");

        _registry = registry_;
        require(msg.sender == governance(), "Subscriber: Bad Governance");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

    // safely transfer tokens without underflowing
    function safeTokenTransfer(
        address recipient,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            IERC20(token).safeTransfer(recipient, balance);
            return balance;
        } else {
            IERC20(token).safeTransfer(recipient, amount);
            return amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILiquidator {
    function liquidate(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 minOut
    ) external returns (uint256);

    function getSwapInfo(address from, address to) external view returns (address router, address[] memory path);

    function sushiswapRouter() external view returns (address);

    function uniswapRouter() external view returns (address);

    function weth() external view returns (address);
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

pragma solidity 0.7.6;

interface IAvalancheManager {
    function burner() external view returns (address);
    
    function burn() external;

    function setBurner(address _burner) external;
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IBankStorage} from "./IBankStorage.sol";

interface IBank is IBankStorage {
    function strategies(uint256 i) external view returns (address);

    function totalStrategies() external view returns (uint256);

    function underlyingBalance() external view returns (uint256);

    function strategyBalance(uint256 i) external view returns (uint256);

    function investedBalance() external view returns (uint256);

    function virtualBalance() external view returns (uint256);

    function virtualPrice() external view returns (uint256);

    function pause() external;

    function unpause() external;

    function invest(address strategy, uint256 amount) external;

    function investAll(address strategy) external;

    function exit(address strategy, uint256 amount) external;

    function exitAll(address strategy) external;

    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address recipient) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IManager {
    function token() external view returns (address);

    function buybackFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function liquidators(address from, address to) external view returns (address);

    function whitelisted(address _contract) external view returns (bool);

    function banks(uint256 i) external view returns (address);

    function totalBanks() external view returns (uint256);

    function strategies(address bank, uint256 i) external view returns (address);

    function totalStrategies(address bank) external view returns (uint256);

    function withdrawIndex(address bank) external view returns (uint256);

    function setWithdrawIndex(uint256 i) external;

    function rebalance(address bank) external;

    function finance(address bank) external;

    function financeAll(address bank) external;

    function buyback(address from) external;

    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external;

    function exitAll(address bank) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function burn(uint256 amount) external;

    function mint(address recipient, uint256 amount) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBankStorage {
    function paused() external view returns (bool);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISubscriber {
    function registry() external view returns (address);

    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRegistry {
    function governance() external view returns (address);

    function manager() external view returns (address);
}