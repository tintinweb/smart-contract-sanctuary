/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.7;  

library DataTypes { 
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

interface ILendingPool {
	/**
	 * @dev Emitted on deposit()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
	 * @param amount The amount deposited
	 * @param referral The referral code used
	 **/
	event Deposit(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on withdraw()
	 * @param reserve The address of the underlyng asset being withdrawn
	 * @param user The address initiating the withdrawal, owner of aTokens
	 * @param to Address that will receive the underlying
	 * @param amount The amount to be withdrawn
	 **/
	event Withdraw(
		address indexed reserve,
		address indexed user,
		address indexed to,
		uint256 amount
	);

	/**
	 * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
	 * @param reserve The address of the underlying asset being borrowed
	 * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
	 * initiator of the transaction on flashLoan()
	 * @param onBehalfOf The address that will be getting the debt
	 * @param amount The amount borrowed out
	 * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
	 * @param borrowRate The numeric rate at which the user has borrowed
	 * @param referral The referral code used
	 **/
	event Borrow(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on repay()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The beneficiary of the repayment, getting his debt reduced
	 * @param repayer The address of the user initiating the repay(), providing the funds
	 * @param amount The amount repaid
	 **/
	event Repay(
		address indexed reserve,
		address indexed user,
		address indexed repayer,
		uint256 amount
	);

	/**
	 * @dev Emitted on swapBorrowRateMode()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user swapping his rate mode
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	event Swap(address indexed reserve, address indexed user, uint256 rateMode);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralEnabled(
		address indexed reserve,
		address indexed user
	);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralDisabled(
		address indexed reserve,
		address indexed user
	);

	/**
	 * @dev Emitted on rebalanceStableBorrowRate()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user for which the rebalance has been executed
	 **/
	event RebalanceStableBorrowRate(
		address indexed reserve,
		address indexed user
	);

	/**
	 * @dev Emitted on flashLoan()
	 * @param target The address of the flash loan receiver contract
	 * @param initiator The address initiating the flash loan
	 * @param asset The address of the asset being flash borrowed
	 * @param amount The amount flash borrowed
	 * @param premium The fee flash borrowed
	 * @param referralCode The referral code used
	 **/
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	/**
	 * @dev Emitted when the pause is triggered.
	 */
	event Paused();

	/**
	 * @dev Emitted when the pause is lifted.
	 */
	event Unpaused();

	/**
	 * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
	 * LendingPoolCollateral manager using a DELEGATECALL
	 * This allows to have the events in the generated ABI for LendingPool.
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
	 * @param liquidator The address of the liquidator
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	event LiquidationCall(
		address indexed collateralAsset,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	/**
	 * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
	 * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
	 * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
	 * gets added to the LendingPool ABI
	 * @param reserve The address of the underlying asset of the reserve
	 * @param liquidityRate The new liquidity rate
	 * @param stableBorrowRate The new stable borrow rate
	 * @param variableBorrowRate The new variable borrow rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableBorrowIndex The new variable borrow index
	 **/
	event ReserveDataUpdated(
		address indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
	 * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding debt token (StableDebtToken or VariableDebtToken)
	 * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
	 *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
	 * @param asset The address of the underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
	 * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
	 * if he has been given credit delegation allowance
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
	 * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @return The final amount repaid
	 **/
	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);

	/**
	 * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
	 * @param asset The address of the underlying asset borrowed
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	function swapBorrowRateMode(address asset, uint256 rateMode) external;

	/**
	 * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
	 * - Users can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
	 *        borrowed at a stable rate and depositors are not earning enough
	 * @param asset The address of the underlying asset borrowed
	 * @param user The address of the user to be rebalanced
	 **/
	function rebalanceStableBorrowRate(address asset, address user) external;

	/**
	 * @dev Allows depositors to enable/disable a specific deposited asset as collateral
	 * @param asset The address of the underlying asset deposited
	 * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
	 **/
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
		external;

	/**
	 * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
	 * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
	 *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	function liquidationCall(
		address collateralAsset,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	/**
	 * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
	 * as long as the amount taken plus a fee is returned.
	 * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
	 * For further details please visit https://developers.aave.com
	 * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
	 * @param assets The addresses of the assets being flash-borrowed
	 * @param amounts The amounts amounts being flash-borrowed
	 * @param modes Types of the debt to open if the flash loan is not returned:
	 *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
	 *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
	 * @param params Variadic packed params to pass to the receiver as extra information
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function flashLoan(
		address receiverAddress,
		address[] calldata assets,
		uint256[] calldata amounts,
		uint256[] calldata modes,
		address onBehalfOf,
		bytes calldata params,
		uint16 referralCode
	) external;

	/**
	 * @dev Returns the user account data across all the reserves
	 * @param user The address of the user
	 * @return totalCollateralETH the total collateral in ETH of the user
	 * @return totalDebtETH the total debt in ETH of the user
	 * @return availableBorrowsETH the borrowing power left of the user
	 * @return currentLiquidationThreshold the liquidation threshold of the user
	 * @return ltv the loan to value of the user
	 * @return healthFactor the current health factor of the user
	 **/
	function getUserAccountData(address user)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		address reserve,
		address aTokenAddress,
		address stableDebtAddress,
		address variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(
		address reserve,
		address rateStrategyAddress
	) external;

	function setConfiguration(address reserve, uint256 configuration) external;

	/**
	 * @dev Returns the configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The configuration of the reserve
	 **/
	function getConfiguration(address asset)
		external
		view
		returns (DataTypes.ReserveConfigurationMap memory);

	/**
	 * @dev Returns the configuration of the user across all the reserves
	 * @param user The user address
	 * @return The configuration of the user
	 **/
	function getUserConfiguration(address user)
		external
		view
		returns (DataTypes.UserConfigurationMap memory);

	/**
	 * @dev Returns the normalized income normalized income of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve's normalized income
	 */
	function getReserveNormalizedIncome(address asset)
		external
		view
		returns (uint256);

	/**
	 * @dev Returns the normalized variable debt per unit of asset
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve normalized variable debt
	 */
	function getReserveNormalizedVariableDebt(address asset)
		external
		view
		returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset)
		external
		view
		returns (DataTypes.ReserveData memory);

	function finalizeTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (address[] memory);

	function getAddressesProvider()
		external
		view
		returns (ILendingPoolAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);
}

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;
}

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


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// TESTTOK Utility Token.
// Price is set via bonding curve vs. USDC.
// All USDC is deposited in a singular lending pool (nominaly at AAVE).
// 100% USDC is maintained against burning. (see variable reserveInUSDCin6dec, in 6 decimals format)
// Collected fees and interest are withdrawable to the owner to a set recipient address.
// Fee discounts are calculated based on TESTTOK balance.
// Reentrancy is protected against via OpenZeppelin's ReentrancyGuard
contract TesterTokens is Ownable, ERC20, Pausable, ReentrancyGuard {
    
  ILendingPool public polygonLendingPool;       // Aave lending pool on Polygon
  IERC20 public polygonUSDC;                    // USDC crypto currency on Polygon
  IERC20 public polygonAMUSDC;                  // Aave's amUSDC crypto currency on Polygon

  address public feeReceiver;                   // beneficiary address for collected fees

  uint256 public reserveInUSDCin6dec;           // end user USDC on deposit
  uint256 public USDCscaleFactor =    1000000;  // 6 decimals scale of USDC crypto currency
  uint256 public USDCcentsScaleFactor = 10000;  // 4 decimals scale of USDC crypto currency cents
  uint256 public blocksPerDay;                  // amount of blocks minted per day on polygon mainnet // TODO: change to 43200, value now is for testing
  uint8   private _decimals;                    // storing TESTTOK decimals, set to 0 in constructor
     
  uint256 public curveFactor;                   // inverse slope of the bonding curve
  uint256 public baseFeeTimes10k;               // percent * 10,000 as an integer (for ex. 1% baseFee expressed as 10000)

  uint256 public neededTESTTOKperLevel;            // amount of TESTTOK needed per discount level
  uint16[] public holdingTimes;                 // holding times in days
  uint16[] public discounts;                    // discounts in percent
  
  // mapping of user to timestamp, relating to when levels can be decreased again
  mapping (address => uint256) minHoldingtimeUntil;

  // user accounts can be levels 0 - 3
  mapping (address => uint256) usersAccountLevel;

  // event for withdrawGains function
  // availableIn6dec shows how many USDC were available to withdraw, in 6 decimals format
  // amountUSDCin6dec shows how many USDC were withdrawn, in 6 decimals format
  event ProfitTaken(uint256 availableUSDCIn6dec, uint256 withdrawnUSDCin6dec);

  // event for deposits into the lending pool
  event LendingPoolDeposit (uint256 amountUSDCin6dec, address sender);

  // event for withdrawals from the lending pool
  event LendingPoolWithdrawal (uint256 amountUSDCBeforeFeein6dec, address receiver);

  // event for increasing discount level
  event DiscountLevelIncreased(address owner, uint256 blockHeightNow,  uint256 newDiscountLevel, uint256 minimumHoldingUntil); 
 
  // event for decreasing discount level
  event DiscountLevelDecreased(address owner, uint256 blockHeightNow,  uint256 newDiscountLevel);

  // event for exchanging USDC and TESTTOK
  event Exchanged(
    bool isMint,
    address fromAddress,
    address toAddress,
    uint256 inTokens,
    uint256 beforeFeeUSDCin6dec,
    uint256 feeUSDCin6dec
  );

  // event for updating these addresses: feeReceiver, polygonUSDC, polygonAMUSDC
  event AddressUpdate(address newAddress, string typeOfUpdate); 

  // event for updating the amounts of blocks mined on Polygon network per day
  event BlocksPerDayUpdate(uint256 newAmountOfBlocksPerDay);

  // event for updating the inverse slope of the bonding curve
  event CurveFactorUpdate(uint256 newCurveFactor);
  
  // event for updating the contract's approval to Aave's USDC lending pool
  event LendingPoolApprovalUpdate(uint256 amountToApproveIn6dec);

  // event for updating Aave's lendingPool address
  event LendingPoolUpdated(address lendingPoolAddressNow);  

  // event for updating the table of necessary TESTTOK amounts per discount level
  event NeededTESTTOKperLevelUpdate(uint256 neededTESTTOKperLevel);

  // event for updating the table of necessary holding periods for the respective discount level
  event HoldingTimesUpdate(uint16[] newHoldingTimes);

  // event for updating the table of discounts for the respective discount level
  event DiscountsUpdate(uint16[] newDiscounts);

  // event for updating the baseFeeTimes10k variable
  event BaseFeeUpdate(uint256 newbaseFeeTimes10k); 
 
  // owner overrides paused.
  modifier whenAvailable() {        
    require(!paused() || (msg.sender == owner()), "TesterTokens is paused.");
    _;
  }

  // checking that account has sufficient funds
  modifier hasTheTesterTokens(uint256 want2Spend) {
    require(balanceOf(msg.sender) >= want2Spend, "Insufficient TesterTokens.");
    _;
  }

  // Redundant reserveInUSDCin6dec protection vs. user withdraws.
  modifier wontBreakTheBank(uint256 amountTESTTOKtoBurn) {        
    // calculating the USDC value of the TESTTOK tokens to burn, and rounding them to full cents
    uint256 beforeFeesNotRoundedIn6dec = quoteUSDC(amountTESTTOKtoBurn, false);        
    uint256 beforeFeesRoundedDownIn6dec = beforeFeesNotRoundedIn6dec - (beforeFeesNotRoundedIn6dec % USDCcentsScaleFactor);
    // if the USDC reserve counter shows less than what is needed, check the existing amUSDC balance of the contract
    if(reserveInUSDCin6dec < beforeFeesRoundedDownIn6dec) {
      uint256 fundsOnTabIn6dec = polygonAMUSDC.balanceOf(address(this));
      // if there are enough amUSDC available, set the tracker to allow the transfer 
      if (fundsOnTabIn6dec >= beforeFeesRoundedDownIn6dec ) {
        reserveInUSDCin6dec = beforeFeesRoundedDownIn6dec;                
      }
    }
    // if there are not enough amUSDC, throw an error 
    require(reserveInUSDCin6dec >= beforeFeesRoundedDownIn6dec, "TTK: wontBreakTheBank threw");
    _;
  }

  constructor() ERC20("TesterTokens", "TESTTOK") {
    // Manage TesterTokens
    _decimals = 0;                          // TesterTokens have 0 decimals, only full tokens exist.
    reserveInUSDCin6dec = 0;                // upon contract creation, the reserve in USDC is 0

    // setting addresses for feeReceiver, USDC-, amUSDC- and Aave lending pool contracts
    feeReceiver = 0xE51c8401fe1E70f78BBD3AC660692597D33dbaFF;
    polygonUSDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    polygonAMUSDC = IERC20(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);
    polygonLendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    // setting blocksPerDay, curveFactor and baseFeeTimes10k 
    blocksPerDay =        2; 
    curveFactor =   8000000;       
    baseFeeTimes10k = 10000;    

    // setting neededTESTTOKperLevel, holdingTimes and discounts 
    neededTESTTOKperLevel = 1000;              // necessary amount of TESTTOK to lock per level (level 1 needs 1000 TESTTOK locked up, etc.)
    holdingTimes = [0, 30, 90, 300];        // holding times in days, relating to discount level (level 1 needs 30 days holding, etc.)
    discounts =    [0, 10, 25,  50];        // discounts in percent, relating to discount level (level 1 gets 10% discounts, etc.)
    
    // calling OpenZeppelin's (pausable) pause function for initial preparations after deployment
    pause();
  }
  
  // pausing funcionality from OpenZeppelin's Pausable
  function pause() public onlyOwner {
    _pause();
  }

  // unpausing funcionality from OpenZeppelin's Pausable
  function unpause() public onlyOwner {
    _unpause();
  }

  // Overriding OpenZeppelin's ERC20 function
  function decimals() public view override whenAvailable returns (uint8) {
    return _decimals;
  }

  function getUsersDiscountLevel(address _userToCheck) public view whenAvailable returns (uint256 discountLevel) {
    return usersAccountLevel[_userToCheck];
  }

  function lockedBalanceOf(address _userToCheck) public view whenAvailable returns (uint256 lockedTESTTOKofUser) {
    return (getUsersDiscountLevel(_userToCheck)*neededTESTTOKperLevel);
  }

  function getUsersDiscountPercentageTimes10k(address _userToCheck) public view whenAvailable returns (uint256 discountInPercentTimes10k) {
    uint256 usersDiscountLevel = getUsersDiscountLevel(_userToCheck);

    uint256 usersDiscountInPercentTimes10k = uint256(discounts[usersDiscountLevel]) * baseFeeTimes10k;

    return usersDiscountInPercentTimes10k;
  }  

  function getUsersUnlockTimestamp(address _userToCheck) public view whenAvailable returns (uint256 usersUnlockTimestamp) {
    return minHoldingtimeUntil[_userToCheck];
  }

  function howManyBlocksUntilUnlock (address _userToCheck) public view whenAvailable returns(uint256 timeLeftInBlocks) {
    // this is now, expressed in blockheight
    uint256 blockHeightNow = block.number;

    uint256 willUnlockAtThisBlockheight = getUsersUnlockTimestamp(_userToCheck);
   
    int256 amountOfBlocksStillLocked = int256(willUnlockAtThisBlockheight) - int256(blockHeightNow);

    if (amountOfBlocksStillLocked < 0) {
      return 0;
    } else {
      return uint256(amountOfBlocksStillLocked);
    }

  }
  
  function increaseDiscountLevels (uint256 _amountOfLevelsToIncrease) public whenAvailable hasTheTesterTokens(_amountOfLevelsToIncrease * neededTESTTOKperLevel) {
    
    uint256 endAmountOfLevels = getUsersDiscountLevel(msg.sender) + _amountOfLevelsToIncrease;

    require(0 < _amountOfLevelsToIncrease && endAmountOfLevels <=3, "You can increase the discount level up to level 3");
    
    uint256 amountOfTESTTOKtoLock = (_amountOfLevelsToIncrease * neededTESTTOKperLevel);

    // transferring TESTTOK from msg.sender to this contract
    transfer(address(this), amountOfTESTTOKtoLock);
    
    // this is now, expressed in blockheight
    uint256 blockHeightNow = block.number;    

    uint256 amountOfTimeToLock = holdingTimes[endAmountOfLevels] * blocksPerDay;

    uint256 discountShouldBeActiveUntil = blockHeightNow + amountOfTimeToLock;    

    minHoldingtimeUntil[msg.sender] = discountShouldBeActiveUntil;
    
    usersAccountLevel[msg.sender] = endAmountOfLevels;    

    // emitting event with all related useful details
    emit DiscountLevelIncreased (msg.sender, blockHeightNow, endAmountOfLevels, discountShouldBeActiveUntil);  
  }  

  function decreaseDiscountLevels (uint256 _amountOfLevelsToDecrease) public whenAvailable {

    uint256 usersDiscountLevelNow = getUsersDiscountLevel(msg.sender);

    uint256 endAmountOfLevels = usersDiscountLevelNow - _amountOfLevelsToDecrease;

    require(_amountOfLevelsToDecrease > 0 &&_amountOfLevelsToDecrease <= usersDiscountLevelNow && endAmountOfLevels >=0, "You can lower the discount level down to level 0");

    // this is now, expressed in blockheight
    uint256 blockHeightNow = block.number;  

    // timestamp must be smaller than now (i.e. enough time has passed)
    require(getUsersUnlockTimestamp(msg.sender) <= blockHeightNow, "Discounts are still active, levels cannot be decreased. You can check howManyBlocksUntilUnlock");

    usersAccountLevel[msg.sender] = endAmountOfLevels;    

    uint256 amountOfTESTTOKunlocked = _amountOfLevelsToDecrease * neededTESTTOKperLevel;

    // this contract approves msg.sender to use transferFrom and pull in amountOfTESTTOKunlocked TESTTOK
    _approve(address(this), msg.sender, amountOfTESTTOKunlocked);    

    // this contract pushes msg.sender amountOfTESTTOKunlocked to msg.sender
    transferFrom(address(this), msg.sender, amountOfTESTTOKunlocked);    

    emit DiscountLevelDecreased(msg.sender, blockHeightNow, endAmountOfLevels);  
    
  }





  // Modified ERC20 transfer()   
  function transfer(address recipient, uint256 amountTESTTOK)
    public
    override
    nonReentrant
    whenAvailable    
  returns(bool) {  
    // transferring TESTTOK
    _transfer(_msgSender(), recipient, amountTESTTOK);
    
    return true;
  }

  // modified ERC20 transferFrom()   
  function transferFrom(address sender, address recipient, uint256 amountTESTTOK)
    public
    override
    nonReentrant
    whenAvailable    
  returns (bool) {    
    // checking if allowance for TESTTOK is enough
    uint256 currentTESTTOKAllowance = allowance(sender, _msgSender());
    require(currentTESTTOKAllowance >= amountTESTTOK, "TesterTokens: transfer amount exceeds allowance");
    // transferring TESTTOK
    _transfer (sender, recipient, amountTESTTOK);

    // decreasing TESTTOK allowance by transferred amount
    _approve(sender, _msgSender(), currentTESTTOKAllowance - amountTESTTOK);   
   
    return true;
  }

  // Buy TESTTOK with USDC.
  function mint(uint256 _amount) public {
    mintTo(_amount, msg.sender);
  }

  // Buy TESTTOK with USDC for another address.
  function mintTo(uint256 _amount, address _toWhom) public whenAvailable {   
    // minting to user
    changeSupply(_toWhom, _amount, true);
  }

  // Sell TESTTOK for USDC.
  function burn(uint256 _amount) public {
    burnTo(_amount, msg.sender);
  }

  // Sell your TESTTOK and send USDC to another address.
  function burnTo(uint256 _amount, address _toWhom)
    public
    whenAvailable
    hasTheTesterTokens(_amount)
    wontBreakTheBank(_amount)   
  {
    changeSupply(_toWhom, _amount, false);
  }

  // Quote USDC for mint or burn
  // based on TESTTOK in circulation and amount to mint/burn
  function quoteUSDC(uint256 _amount, bool isMint) public view whenAvailable returns (uint256) {

    uint256 supply = totalSupply();                     // total supply of TESTTOK
    uint256 supply2 = supply*supply;                    // Supply squared
    uint256 supplyAfterTx;                              // post-mint supply, see below
    uint256 supplyAfterTx2;                             // post-mint supply squared, see below
    uint256 squareDiff;                                 // difference in supply, before and after, see below

    // this calculation is for minting TESTTOK
    if (isMint==true){                                  
      supplyAfterTx = supply + _amount;               
      supplyAfterTx2 = supplyAfterTx*supplyAfterTx;   
      squareDiff = supplyAfterTx2 - supply2;
    } 
        
    // this calculation is for burning TESTTOK
    else {                                              
      supplyAfterTx = supply - _amount;               
      supplyAfterTx2 = supplyAfterTx*supplyAfterTx;
      squareDiff = supply2 - supplyAfterTx2;
    }

    // bringing difference into 6 decimals format for USDC
    uint256 scaledSquareDiff = squareDiff * USDCscaleFactor;       

    // finishing bonding curve calculation 
    uint256 amountInUSDCin6dec = scaledSquareDiff / curveFactor;    

    // rounding down to USDC cents
    uint256 endAmountUSDCin6dec = amountInUSDCin6dec - (amountInUSDCin6dec % USDCcentsScaleFactor); 

    // the amount of TESTTOK to be moved must be at least currently valued at $5 of USDC
    require (endAmountUSDCin6dec >= 5000000, "TTK, quoteUSDC: Minimum TESTTOK value to move is $5 USDC" );

    // returning USDC value of TESTTOK before fees
    return endAmountUSDCin6dec;                         
  }
    
  // Execute mint or burn
  function changeSupply(address _forWhom, uint256 _amountTESTTOK, bool isMint) internal nonReentrant whenAvailable {
    uint256 beforeFeeInUSDCin6dec;
    // Calculate change in tokens and value of difference
    if (isMint == true) {
      beforeFeeInUSDCin6dec = quoteUSDC(_amountTESTTOK, true);
    } else {
      beforeFeeInUSDCin6dec = quoteUSDC(_amountTESTTOK, false);
    }
    // baseFeeTimes10k is brought into full percent format by dividing by 10000, then applied as percent by dividing by 100
    uint256 feeNotRoundedIn6dec = (beforeFeeInUSDCin6dec * baseFeeTimes10k) / 1000000;
    // rounding down to full cents
    uint256 feeRoundedDownIn6dec = feeNotRoundedIn6dec - (feeNotRoundedIn6dec % USDCcentsScaleFactor);
    // Execute exchange
    if (isMint == true) {
      // moving funds for minting
      moveUSDC(msg.sender, _forWhom, beforeFeeInUSDCin6dec, feeRoundedDownIn6dec, true);
      // minting
      _mint(_forWhom, _amountTESTTOK);
      // update reserve
      reserveInUSDCin6dec += beforeFeeInUSDCin6dec;
    } else {
      // burning
      _burn(msg.sender, _amountTESTTOK);
      // moving funds for burning
      moveUSDC(msg.sender, _forWhom, beforeFeeInUSDCin6dec, feeRoundedDownIn6dec, false);
      // update reserve            
      reserveInUSDCin6dec -= beforeFeeInUSDCin6dec;
    }

    emit Exchanged(isMint, msg.sender, _forWhom, _amountTESTTOK, beforeFeeInUSDCin6dec, feeRoundedDownIn6dec);
  }

  // Move USDC for a supply change.  Note: sign of amount is the mint/burn direction.
  function moveUSDC(
    address _payer,
    address _payee,
    uint256 _beforeFeeInUSDCin6dec,
    uint256 _feeRoundedDownIn6dec,
    bool isMint
  ) internal whenAvailable {
    if (isMint == true) {
      // on minting, fee is added to price
      uint256 _afterFeeUSDCin6dec = _beforeFeeInUSDCin6dec + _feeRoundedDownIn6dec;

      // pull USDC from user (_payer), push to this contract
      polygonUSDC.transferFrom(_payer, address(this), _afterFeeUSDCin6dec);

      // pushing fee from this contract to feeReceiver address
      polygonUSDC.transfer(feeReceiver, _feeRoundedDownIn6dec);

      // this contract gives the Aave lending pool allowance to pull in the amount without fee from this contract
      polygonUSDC.approve(address(polygonLendingPool), _beforeFeeInUSDCin6dec);

      // lending pool is queried to pull in the approved USDC (in 6 decimals format)
      polygonLendingPool.deposit(address(polygonUSDC), _beforeFeeInUSDCin6dec, address(this), 0);
      emit LendingPoolDeposit(_beforeFeeInUSDCin6dec, _payer);
    } else {
      // on burning, fee is substracted from return
      uint256 _afterFeeUSDCin6dec = _beforeFeeInUSDCin6dec - _feeRoundedDownIn6dec;
            
      // lending pool is queried to push USDC (in 6 decimals format) including fee back to this contract
      polygonLendingPool.withdraw(address(polygonUSDC), _beforeFeeInUSDCin6dec, address(this));
      emit LendingPoolWithdrawal(_beforeFeeInUSDCin6dec, _payee);

      // pushing fee from this contract to feeReceiver address
      polygonUSDC.transfer(feeReceiver, _feeRoundedDownIn6dec);

      // pushing USDC from this contract to user (_payee)
      polygonUSDC.transfer(_payee, _afterFeeUSDCin6dec);
    }
  }    
  
  function checkGains() public view onlyOwner returns (uint256 availableNowIn6dec) {

    uint256 amUSDCbalOfContractIn6dec = polygonAMUSDC.balanceOf(address(this));

    // calculating with $100 extra as a redundant mathmatical buffer
    uint256 bufferIn6dec = 100*USDCscaleFactor;    

    if (amUSDCbalOfContractIn6dec > bufferIn6dec) {
      uint256 amUSDCbalBufferedIn6dec = amUSDCbalOfContractIn6dec - bufferIn6dec;      

      if (amUSDCbalBufferedIn6dec > reserveInUSDCin6dec) {
        uint256 availableIn6dec = amUSDCbalBufferedIn6dec - reserveInUSDCin6dec;        

        return availableIn6dec;
      } 
      else {
        return 0;
      }
    } 
    else {
      return 0;
    }        
  }
  
  // Withdraw available fees and interest gains from lending pool to receiver address.
  function withdrawGains(uint256 _amountIn6dec) public onlyOwner {
    uint256 availableIn6dec = checkGains();
    

    require(availableIn6dec > _amountIn6dec, "Insufficient funds.");
    polygonAMUSDC.transfer(feeReceiver, _amountIn6dec); 
    emit ProfitTaken(availableIn6dec, _amountIn6dec);
  }

  // Returns the reserveInUSDCin6dec tracker, which logs the amount of USDC (in 6 decimals format),
  // to be 100% backed against burning tokens at all times
  function getReserveIn6dec() public view returns (uint256 reserveInUSDCin6decNow) {
    return reserveInUSDCin6dec;
  }
    
  function getFeeReceiver() public view returns (address feeReceiverNow) {
    return feeReceiver;           
  } 

  function getPolygonUSDC() public view returns (address addressNow) {
    return address(polygonUSDC);           
  }

  function getPolygonAMUSDC() public view returns (address addressNow) {
    return address(polygonAMUSDC);           
  }

  function getPolygonLendingPool() public view returns (address addressNow) {
    return address(polygonLendingPool);           
  }
 
  function getBlocksPerDay() public view returns (uint256 amountOfBlocksPerDayNow) {
    return blocksPerDay;           
  }

  // Returns the inverse slope of the bonding curve
  function getCurveFactor() public view returns (uint256 curveFactorNow) {
    return curveFactor;
  }

  function getneededTESTTOKperLevel() public view returns (uint256 neededTESTTOKperLevelNow) {
    return neededTESTTOKperLevel;           
  }

  function getHoldingTimes() public view returns (uint16[] memory holdingTimesNow) {
    return holdingTimes;           
  }

  function getDiscounts() public view returns (uint16[] memory discountsNow) {
    return discounts;           
  }

  function getBaseFeeTimes10k() public view returns (uint256 baseFeeTimes10kNow){
    return baseFeeTimes10k;
  }
      
  // function for owner to withdraw MATIC that were sent directly to contract by mistake
  function cleanMATICtips() public onlyOwner {
    address payable receiver = payable(msg.sender);
    uint256 accumulatedMatic = address(this).balance;
    (bool success, ) = receiver.call{value: accumulatedMatic}("");
    require(success, "Transfer failed.");
  }
    
  // function for owner to withdraw ERC20 tokens that were sent directly to contract by mistake
  function cleanERC20Tips(address erc20ContractAddress) public onlyOwner {
    require(erc20ContractAddress != 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, 'ERC20 cannot be USDC.');     // ERC20 cannot be USDC
    require(erc20ContractAddress != 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F, 'ERC20 cannot be amUSDC.');   // ERC20 cannot be amUSDC
    require(erc20ContractAddress != address(this), 'ERC20 cannot be TESTTOK.');                                  // ERC20 cannot be TESTTOK

    IERC20 erc20contract = IERC20(erc20ContractAddress);                // Instance of ERC20 token at erc20ContractAddress    
    uint256 accumulatedTokens = erc20contract.balanceOf(address(this)); // Querying balance of this token, owned by this contract    
    erc20contract.transfer(msg.sender, accumulatedTokens);              // Sending it to calling owner
  } 

  // Receives all incoming Matic, sent directly (there is no need to send Matic)
  receive() external payable {
    // blind accumulate all other payment types and tokens.
  }

  // Update Aave's lending pool address on Polygon
  function updatePolygonLendingPoolAddress (address newAddress) public onlyOwner {
    // setting new lending pool address and emitting event
    polygonLendingPool = ILendingPool(newAddress);
    emit LendingPoolUpdated(newAddress);
  }        
 
  // Update the feeReceiver address
  function updateFeeReceiver(address newFeeReceiver) public onlyOwner {
    feeReceiver = newFeeReceiver;     
    emit AddressUpdate(newFeeReceiver, "feeReceiver");           
  }  

  // Update the USDC token address on Polygon
  function updatePolygonUSDC(address newAddress) public onlyOwner {
    polygonUSDC = IERC20(newAddress);
    emit AddressUpdate(newAddress, "polygonUSDC");
  }  

  // Update the amUSDC token address on Polygon
  function updatePolygonAMUSDC(address newAddress) public onlyOwner {
    polygonAMUSDC = IERC20(newAddress);
    emit AddressUpdate(newAddress, "polygonAMUSDC");
  }

  // Update amount of blocks mined per day on Polygon
  function updateBlocksPerDay (uint256 newAmountOfBlocksPerDay) public onlyOwner {
    blocksPerDay = newAmountOfBlocksPerDay;
    emit BlocksPerDayUpdate(newAmountOfBlocksPerDay);
  }

  // Update the inverse slope of the bonding curve
  function updateCurveFactor (uint256 newCurveFactor) public onlyOwner {
    curveFactor = newCurveFactor;
    emit CurveFactorUpdate(curveFactor);
  }

  // Update approval from this contract to Aave's USDC lending pool.
  function updateApproveLendingPool (uint256 amountToApproveIn6dec) public onlyOwner {
    polygonUSDC.approve(address(polygonLendingPool), amountToApproveIn6dec);
    emit LendingPoolApprovalUpdate(amountToApproveIn6dec);
  }
  
  // Update token amount required per discount level
  function updateNeededTESTTOKperLevel (uint256 newNeededTESTTOKperLevel) public onlyOwner {
    neededTESTTOKperLevel = newNeededTESTTOKperLevel;
    emit NeededTESTTOKperLevelUpdate(neededTESTTOKperLevel);
  }

  // Update timeout times required by discount levels
  function updateHoldingTimes (uint16[] memory newHoldingTimes) public onlyOwner {
    holdingTimes = newHoldingTimes;
    emit HoldingTimesUpdate(holdingTimes);
  }

  // Update fee discounts for discount levels
  function updateDiscounts (uint16[] memory newDiscounts) public onlyOwner {
    discounts = newDiscounts;
    emit DiscountsUpdate(discounts);
  }    
    
  function updateBaseFee(uint256 _newbaseFeeTimes10k) public onlyOwner {
    baseFeeTimes10k = _newbaseFeeTimes10k;
    emit BaseFeeUpdate(_newbaseFeeTimes10k);
  }
}