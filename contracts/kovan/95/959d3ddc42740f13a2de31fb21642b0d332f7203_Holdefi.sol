// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./HoldefiPausableOwnable.sol";
import "./HoldefiCollaterals.sol";


/// @notice File: contracts/HoldefiPrices.sol
interface HoldefiPricesInterface {
	function getAssetValueFromAmount(address asset, uint256 amount) external view returns(uint256 value);
	function getAssetAmountFromValue(address asset, uint256 value) external view returns(uint256 amount);	
}

/// @notice File: contracts/HoldefiSettings.sol
interface HoldefiSettingsInterface {

	/// @notice Markets Features
	struct MarketSettings {
		bool isExist;
		bool isActive;      

		uint256 borrowRate;
		uint256 borrowRateUpdateTime;

		uint256 suppliersShareRate;
		uint256 suppliersShareRateUpdateTime;

		uint256 promotionRate;
	}

	/// @notice Collateral Features
	struct CollateralSettings {
		bool isExist;
		bool isActive;    

		uint256 valueToLoanRate; 
		uint256 VTLUpdateTime;

		uint256 penaltyRate;
		uint256 penaltyUpdateTime;

		uint256 bonusRate;
	}

	function getInterests(address market)
		external
		view
		returns (uint256 borrowRate, uint256 supplyRateBase, uint256 promotionRate);
	function resetPromotionRate (address market) external;
	function getMarketsList() external view returns(address[] memory marketsList);
	function marketAssets(address market) external view returns(MarketSettings memory);
	function collateralAssets(address collateral) external view returns(CollateralSettings memory);
}

/// @title Main Holdefi contract
/// @author Holdefi Team
/// @dev The address of ETH considered as 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
/// @dev All indexes are scaled by (secondsPerYear * rateDecimals)
/// @dev All values are based ETH price considered 1 and all values decimals considered 30
/// @dev Error codes description: 
/// 	E01: Asset should not be ETH
/// 	E02: Market is not active
/// 	E03: Collateral is not active
/// 	E04: Account should not be the `msg.sender`
/// 	E05: User borrow balance is zero
/// 	E06: User should be under collateral or should have ativity in the past year
/// 	E07: Amount should be less than Max
/// 	E08: Cannot transfer
/// 	E09: Total balance should not be zero
/// 	E10: Borrow power should not be zero
/// 	E11: Requested amount is not available
/// 	E12: Borrow power should be more than the value of the requested amount to borrow
/// 	E13: Promotion debt should be less than the promotion reserve
///		E14: Transfer amount exceeds allowance
///		E15: Sender should be Holdefi Settings contract
///		E16: There is not enough collateral
///		E17: Amount should be less than the market debt
contract Holdefi is HoldefiPausableOwnable, ReentrancyGuard {

	using SafeMath for uint256;

	using SafeERC20 for IERC20;

	/// @notice Markets are assets can be supplied and borrowed
	struct Market {
		uint256 totalSupply;

		uint256 supplyIndex;      				// Scaled by: secondsPerYear * rateDecimals
		uint256 supplyIndexUpdateTime;

		uint256 totalBorrow;

		uint256 borrowIndex;      				// Scaled by: secondsPerYear * rateDecimals
		uint256 borrowIndexUpdateTime;

		uint256 promotionReserveScaled;      	// Scaled by: secondsPerYear * rateDecimals
		uint256 promotionReserveLastUpdateTime;

		uint256 promotionDebtScaled;      		// Scaled by: secondsPerYear * rateDecimals
		uint256 promotionDebtLastUpdateTime;
	}

	/// @notice Collaterals are assets can be used only as collateral for borrowing with no interest
	struct Collateral {
		uint256 totalCollateral;
		uint256 totalLiquidatedCollateral;
	}

	/// @notice Users profile for each market
	struct MarketAccount {
		mapping (address => uint) allowance;
		uint256 balance;
		uint256 accumulatedInterest;

		uint256 lastInterestIndex;      		// Scaled by: secondsPerYear * rateDecimals
	}

	/// @notice Users profile for each collateral
	struct CollateralAccount {
		mapping (address => uint) allowance;
		uint256 balance;
		uint256 lastUpdateTime;
	}

	struct MarketData {
		uint256 balance;
		uint256 interest;
		uint256 currentIndex; 
	}

	address constant private ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	/// @dev All rates in this contract are scaled by rateDecimals
	uint256 constant private rateDecimals = 10 ** 4;

	uint256 constant private secondsPerYear = 31536000;

	/// @dev For round up borrow interests
	uint256 constant private oneUnit = 1;

	/// @dev Used for calculating liquidation threshold 
	/// @dev There is 5% gap between value to loan rate and liquidation rate
	uint256 constant private fivePercentLiquidationGap = 500;

	/// @notice Contract for getting protocol settings
	HoldefiSettingsInterface public holdefiSettings;

	/// @notice Contract for getting asset prices
	HoldefiPricesInterface public holdefiPrices;

	/// @notice Contract for holding collaterals
	HoldefiCollaterals public holdefiCollaterals;

	/// @dev Markets: marketAddress => marketDetails
	mapping (address => Market) public marketAssets;

	/// @dev Collaterals: collateralAddress => collateralDetails
	mapping (address => Collateral) public collateralAssets;

	/// @dev Markets Debt after liquidation: collateralAddress => marketAddress => marketDebtBalance
	mapping (address => mapping (address => uint256)) public marketDebt;

	/// @dev Users Supplies: userAddress => marketAddress => supplyDetails
	mapping (address => mapping (address => MarketAccount)) private supplies;

	/// @dev Users Borrows: userAddress => collateralAddress => marketAddress => borrowDetails
	mapping (address => mapping (address => mapping (address => MarketAccount))) private borrows;

	/// @dev Users Collaterals: userAddress => collateralAddress => collateralDetails
	mapping (address => mapping (address => CollateralAccount)) private collaterals;
	
	// ----------- Events -----------

	/// @notice Event emitted when a market asset is supplied
	event Supply(
		address sender,
		address indexed supplier,
		address indexed market,
		uint256 amount,
		uint256 balance,
		uint256 interest,
		uint256 index,
		uint16 referralCode
	);

	/// @notice Event emitted when a supply is withdrawn
	event WithdrawSupply(
		address sender,
		address indexed supplier,
		address indexed market,
		uint256 amount,
		uint256 balance,
		uint256 interest,
		uint256 index
	);

	/// @notice Event emitted when the collateral asset is deposited
	event Collateralize(
		address sender,
		address indexed collateralizer,
		address indexed collateral,
		uint256 amount,
		uint256 balance
	);

	/// @notice Event emitted when the collateral is withdrawn
	event WithdrawCollateral(
		address sender,
		address indexed collateralizer,
		address indexed collateral,
		uint256 amount,
		uint256 balance
	);

	/// @notice Event emitted when a market asset is borrowed
	event Borrow(
		address sender,
		address indexed borrower,
		address indexed market,
		address indexed collateral,
		uint256 amount,
		uint256 balance,
		uint256 interest,
		uint256 index,
		uint16 referralCode
	);

	/// @notice Event emitted when a borrow is repaid
	event RepayBorrow(
		address sender,
		address indexed borrower,
		address indexed market,
		address indexed collateral,
		uint256 amount,
		uint256 balance,
		uint256 interest,
		uint256 index
	);

	/// @notice Event emitted when the supply index is updated for a market asset
	event UpdateSupplyIndex(address indexed market, uint256 newSupplyIndex, uint256 supplyRate);

	/// @notice Event emitted when the borrow index is updated for a market asset
	event UpdateBorrowIndex(address indexed market, uint256 newBorrowIndex, uint256 borrowRate);

	/// @notice Event emitted when the collateral is liquidated
	event CollateralLiquidated(
		address indexed borrower,
		address indexed market,
		address indexed collateral,
		uint256 marketDebt,
		uint256 liquidatedCollateral
	);

	/// @notice Event emitted when a liquidated collateral is purchased in exchange for the specified market
	event BuyLiquidatedCollateral(
		address indexed market,
		address indexed collateral,
		uint256 marketAmount,
		uint256 collateralAmount
	);

	/// @notice Event emitted when HoldefiPrices contract is changed
	event HoldefiPricesContractChanged(address newAddress, address oldAddress);

	/// @notice Event emitted when a liquidation reserve is withdrawn by the owner
	event LiquidationReserveWithdrawn(address indexed collateral, uint256 amount);

	/// @notice Event emitted when a liquidation reserve is deposited
	event LiquidationReserveDeposited(address indexed collateral, uint256 amount);

	/// @notice Event emitted when a promotion reserve is withdrawn by the owner
	event PromotionReserveWithdrawn(address indexed market, uint256 amount, uint256 newPromotionReserve);

	/// @notice Event emitted when a promotion reserve is deposited
	event PromotionReserveDeposited(address indexed market, uint256 amount, uint256 newPromotionReserve);

	/// @notice Event emitted when a promotion reserve is updated
	event PromotionReserveUpdated(address indexed market, uint256 promotionReserve);

	/// @notice Event emitted when a promotion debt is updated
	event PromotionDebtUpdated(address indexed market, uint256 promotionDebt);

	/// @notice Initializes the Holdefi contract
    /// @param holdefiSettingsAddress Holdefi settings contract address
    /// @param holdefiPricesAddress Holdefi prices contract address
	constructor(
		HoldefiSettingsInterface holdefiSettingsAddress,
		HoldefiPricesInterface holdefiPricesAddress
	)
		public
	{
		holdefiSettings = holdefiSettingsAddress;
		holdefiPrices = holdefiPricesAddress;
		holdefiCollaterals = new HoldefiCollaterals();
	}


	/// @dev Modifier to check if the asset is ETH or not
	/// @param asset Address of the given asset
    modifier isNotETHAddress(address asset) {
        require (asset != ethAddress, "E01");
        _;
    }

	/// @dev Modifier to check if the market is active or not
	/// @param market Address of the given market
    modifier marketIsActive(address market) {
		require (holdefiSettings.marketAssets(market).isActive, "E02");
        _;
    }

	/// @dev Modifier to check if the collateral is active or not
	/// @param collateral Address of the given collateral
    modifier collateralIsActive(address collateral) {
		require (holdefiSettings.collateralAssets(collateral).isActive, "E03");
        _;
    }

	/// @dev Modifier to check if the account address is equal to the msg.sender or not
    /// @param account The given account address
    modifier accountIsValid(address account) {
		require (msg.sender != account, "E04");
        _;
    }

    receive() external payable {
        revert();
    }

	/// @notice Returns balance and interest of an account for a given market
    /// @dev supplyInterest = accumulatedInterest + (balance * (marketSupplyIndex - userLastSupplyInterestIndex))
    /// @param account Supplier address to get supply information
    /// @param market Address of the given market
    /// @return balance Supplied amount on the specified market
    /// @return interest Profit earned
    /// @return currentSupplyIndex Supply index for the given market at current time
	function getAccountSupply(address account, address market)
		public
		view
		returns (uint256 balance, uint256 interest, uint256 currentSupplyIndex)
	{
		balance = supplies[account][market].balance;

		(currentSupplyIndex,) = getCurrentSupplyIndex(market);

		uint256 deltaInterestIndex = currentSupplyIndex.sub(supplies[account][market].lastInterestIndex);
		uint256 deltaInterestScaled = deltaInterestIndex.mul(balance);
		uint256 deltaInterest = deltaInterestScaled.div(secondsPerYear).div(rateDecimals);
		
		interest = supplies[account][market].accumulatedInterest.add(deltaInterest);
	}

	/// @notice Returns balance and interest of an account for a given market on a given collateral
    /// @dev borrowInterest = accumulatedInterest + (balance * (marketBorrowIndex - userLastBorrowInterestIndex))
    /// @param account Borrower address to get Borrow information
    /// @param market Address of the given market
    /// @param collateral Address of the given collateral
    /// @return balance Borrowed amount on the specified market
    /// @return interest The amount of interest the borrower should pay
    /// @return currentBorrowIndex Borrow index for the given market at current time
	function getAccountBorrow(address account, address market, address collateral)
		public
		view
		returns (uint256 balance, uint256 interest, uint256 currentBorrowIndex)
	{
		balance = borrows[account][collateral][market].balance;

		(currentBorrowIndex,) = getCurrentBorrowIndex(market);

		uint256 deltaInterestIndex =
			currentBorrowIndex.sub(borrows[account][collateral][market].lastInterestIndex);

		uint256 deltaInterestScaled = deltaInterestIndex.mul(balance);
		uint256 deltaInterest = deltaInterestScaled.div(secondsPerYear).div(rateDecimals);
		if (balance > 0) {
			deltaInterest = deltaInterest.add(oneUnit);
		}

		interest = borrows[account][collateral][market].accumulatedInterest.add(deltaInterest);
	}


	/// @notice Returns collateral balance, time since last activity, borrow power, total borrow value, and liquidation status for a given collateral
    /// @dev borrowPower = (collateralValue / collateralValueToLoanRate) - totalBorrowValue
    /// @dev liquidationThreshold = collateralValueToLoanRate - 5%
    /// @dev User will be in liquidation state if (collateralValue / totalBorrowValue) < liquidationThreshold
    /// @param account Account address to get collateral information
    /// @param collateral Address of the given collateral
    /// @return balance Amount of the specified collateral
    /// @return timeSinceLastActivity Time since last activity performed by the account
    /// @return borrowPowerValue The borrowing power for the account of the given collateral
    /// @return totalBorrowValue Accumulative borrowed values on the given collateral
    /// @return underCollateral A boolean value indicates whether the user is in the liquidation state or not
	function getAccountCollateral(address account, address collateral)
		public
		view
		returns (
			uint256 balance,
			uint256 timeSinceLastActivity,
			uint256 borrowPowerValue,
			uint256 totalBorrowValue,
			bool underCollateral
		)
	{
		uint256 valueToLoanRate = holdefiSettings.collateralAssets(collateral).valueToLoanRate;
		if (valueToLoanRate == 0) {
			return (0, 0, 0, 0, false);
		}

		balance = collaterals[account][collateral].balance;

		uint256 collateralValue = holdefiPrices.getAssetValueFromAmount(collateral, balance);
		uint256 liquidationThresholdRate = valueToLoanRate.sub(fivePercentLiquidationGap);

		uint256 totalBorrowPowerValue = collateralValue.mul(rateDecimals).div(valueToLoanRate);
		uint256 liquidationThresholdValue = collateralValue.mul(rateDecimals).div(liquidationThresholdRate);

		totalBorrowValue = getAccountTotalBorrowValue(account, collateral);
		if (totalBorrowValue > 0) {
			timeSinceLastActivity = block.timestamp.sub(collaterals[account][collateral].lastUpdateTime);
		}

		borrowPowerValue = 0;
		if (totalBorrowValue < totalBorrowPowerValue) {
			borrowPowerValue = totalBorrowPowerValue.sub(totalBorrowValue);
		}

		underCollateral = false;	
		if (totalBorrowValue > liquidationThresholdValue) {
			underCollateral = true;
		}
	}

	/// @notice Returns total borrow value of an account based on a given collateral 
	/// @param account Account address
    /// @param collateral Address of the given collateral
    /// @return totalBorrowValue Accumulative borrowed values on the given collateral
	function getAccountTotalBorrowValue (address account, address collateral)
		public
		view
		returns (uint256 totalBorrowValue)
	{
		MarketData memory borrowData;
		address market;
		uint256 totalDebt;
		uint256 assetValue;
		
		totalBorrowValue = 0;
		address[] memory marketsList = holdefiSettings.getMarketsList();
		for (uint256 i = 0 ; i < marketsList.length ; i++) {
			market = marketsList[i];
			
			(borrowData.balance, borrowData.interest,) = getAccountBorrow(account, market, collateral);
			totalDebt = borrowData.balance.add(borrowData.interest);

			assetValue = holdefiPrices.getAssetValueFromAmount(market, totalDebt);
			totalBorrowValue = totalBorrowValue.add(assetValue);
		}
	}

	/// @notice The collateral reserve amount for buying liquidated collateral
    /// @param collateral Address of the given collateral
    /// @return reserve Liquidation reserves for the given collateral
	function getLiquidationReserve (address collateral) public view returns(uint256 reserve) {
		address market;
		uint256 assetValue;
		uint256 totalDebtValue = 0;

		address[] memory marketsList = holdefiSettings.getMarketsList();
		for (uint256 i = 0 ; i < marketsList.length ; i++) {
			market = marketsList[i];
			assetValue = holdefiPrices.getAssetValueFromAmount(market, marketDebt[collateral][market]);
			totalDebtValue = totalDebtValue.add(assetValue); 
		}

		uint256 bonusRate = holdefiSettings.collateralAssets(collateral).bonusRate;
		uint256 totalDebtCollateralValue = totalDebtValue.mul(bonusRate).div(rateDecimals);
		uint256 liquidatedCollateralNeeded = holdefiPrices.getAssetAmountFromValue(
			collateral,
			totalDebtCollateralValue
		);
		
		reserve = 0;
		uint256 totalLiquidatedCollateral = collateralAssets[collateral].totalLiquidatedCollateral;
		if (totalLiquidatedCollateral > liquidatedCollateralNeeded) {
			reserve = totalLiquidatedCollateral.sub(liquidatedCollateralNeeded);
		}
	}

	/// @notice Returns the amount of discounted collateral can be bought in exchange for the amount of a given market
    /// @param market Address of the given market
    /// @param collateral Address of the given collateral
    /// @param marketAmount The amount of market should be paid
    /// @return collateralAmountWithDiscount Amount of discounted collateral can be bought
	function getDiscountedCollateralAmount (address market, address collateral, uint256 marketAmount)
		public
		view
		returns (uint256 collateralAmountWithDiscount)
	{
		uint256 marketValue = holdefiPrices.getAssetValueFromAmount(market, marketAmount);
		uint256 bonusRate = holdefiSettings.collateralAssets(collateral).bonusRate;
		uint256 collateralValue = marketValue.mul(bonusRate).div(rateDecimals);

		collateralAmountWithDiscount = holdefiPrices.getAssetAmountFromValue(collateral, collateralValue);
	}

	/// @notice Returns supply index and supply rate for a given market at current time
	/// @dev newSupplyIndex = oldSupplyIndex + (deltaTime * supplyRate)
    /// @param market Address of the given market
    /// @return supplyIndex Supply index of the given market
    /// @return supplyRate Supply rate of the given market
	function getCurrentSupplyIndex (address market)
		public
		view
		returns (
			uint256 supplyIndex,
			uint256 supplyRate
		)
	{
		(, uint256 supplyRateBase, uint256 promotionRate) = holdefiSettings.getInterests(market);
		uint256 deltaTimeSupply = block.timestamp.sub(marketAssets[market].supplyIndexUpdateTime);

		supplyRate = supplyRateBase.add(promotionRate);
		uint256 deltaTimeInterest = deltaTimeSupply.mul(supplyRate);
		supplyIndex = marketAssets[market].supplyIndex.add(deltaTimeInterest);
	}

	/// @notice Returns borrow index and borrow rate for the given market at current time
	/// @dev newBorrowIndex = oldBorrowIndex + (deltaTime * borrowRate)
    /// @param market Address of the given market
    /// @return borrowIndex Borrow index of the given market
    /// @return borrowRate Borrow rate of the given market
	function getCurrentBorrowIndex (address market)
		public
		view
		returns (
			uint256 borrowIndex,
			uint256 borrowRate
		)
	{
		borrowRate = holdefiSettings.marketAssets(market).borrowRate;
		uint256 deltaTimeBorrow = block.timestamp.sub(marketAssets[market].borrowIndexUpdateTime);

		uint256 deltaTimeInterest = deltaTimeBorrow.mul(borrowRate);
		borrowIndex = marketAssets[market].borrowIndex.add(deltaTimeInterest);
	}

	/// @notice Returns promotion reserve for a given market at current time
	/// @dev promotionReserveScaled is scaled by (secondsPerYear * rateDecimals)
	/// @param market Address of the given market
    /// @return promotionReserveScaled Promotion reserve of the given market
	function getPromotionReserve (address market)
		public
		view
		returns (uint256 promotionReserveScaled)
	{
		(uint256 borrowRate, uint256 supplyRateBase,) = holdefiSettings.getInterests(market);
	
		uint256 allSupplyInterest = marketAssets[market].totalSupply.mul(supplyRateBase);
		uint256 allBorrowInterest = marketAssets[market].totalBorrow.mul(borrowRate);

		uint256 deltaTime = block.timestamp.sub(marketAssets[market].promotionReserveLastUpdateTime);
		uint256 currentInterest = allBorrowInterest.sub(allSupplyInterest);
		uint256 deltaTimeInterest = currentInterest.mul(deltaTime);
		promotionReserveScaled = marketAssets[market].promotionReserveScaled.add(deltaTimeInterest);
	}

	/// @notice Returns promotion debt for a given market at current time
	/// @dev promotionDebtScaled is scaled by secondsPerYear * rateDecimals
	/// @param market Address of the given market
    /// @return promotionDebtScaled Promotion debt of the given market
	function getPromotionDebt (address market)
		public
		view
		returns (uint256 promotionDebtScaled)
	{
		uint256 promotionRate = holdefiSettings.marketAssets(market).promotionRate;
		promotionDebtScaled = marketAssets[market].promotionDebtScaled;

		if (promotionRate != 0) {
			uint256 deltaTime = block.timestamp.sub(marketAssets[market].promotionDebtLastUpdateTime);
			uint256 currentInterest = marketAssets[market].totalSupply.mul(promotionRate);
			uint256 deltaTimeInterest = currentInterest.mul(deltaTime);
			promotionDebtScaled = promotionDebtScaled.add(deltaTimeInterest);
		}
	}

	/// @notice Update a market supply index, promotion reserve, and promotion debt
	/// @param market Address of the given market
	function beforeChangeSupplyRate (address market) public {
		updateSupplyIndex(market);
		
		uint256 reserveScaled = getPromotionReserve(market);
		uint256 debtScaled = getPromotionDebt(market);

    	if (marketAssets[market].promotionDebtScaled != debtScaled) {
    		if (debtScaled >= reserveScaled) {
	      		holdefiSettings.resetPromotionRate(market);
	      	}

	      	marketAssets[market].promotionDebtScaled = debtScaled;
	      	marketAssets[market].promotionDebtLastUpdateTime = block.timestamp;
	      	emit PromotionDebtUpdated(market, debtScaled);
    	}

		marketAssets[market].promotionReserveScaled = reserveScaled;
    	marketAssets[market].promotionReserveLastUpdateTime = block.timestamp;
		emit PromotionReserveUpdated(market, reserveScaled);
	}

	/// @notice Update a market borrow index, supply index, promotion reserve, and promotion debt 
	/// @param market Address of the given market
	function beforeChangeBorrowRate (address market) external {
		updateBorrowIndex(market);
		beforeChangeSupplyRate(market);
	}

	/// @notice Returns maximum amount spender can withdraw from account supplies on a given market
	/// @param account Supplier address
	/// @param spender Spender address
	/// @param market Address of the given market
	/// @return res Maximum amount spender can withdraw from account supplies on a given market
	function getAccountWithdrawSupplyAllowance (address account, address spender, address market)
		external 
		view
		returns (uint256 res)
	{
		res = supplies[account][market].allowance[spender];
	}

	/// @notice Returns maximum amount spender can withdraw from account balance on a given collateral
	/// @param account Account address
	/// @param spender Spender address
	/// @param collateral Address of the given collateral
	/// @return res Maximum amount spender can withdraw from account balance on a given collateral
	function getAccountWithdrawCollateralAllowance (
		address account, 
		address spender, 
		address collateral
	)
		external 
		view
		returns (uint256 res)
	{
		res = collaterals[account][collateral].allowance[spender];
	}

	/// @notice Returns maximum amount spender can withdraw from account borrows on a given market based on a given collteral
	/// @param account Borrower address
	/// @param spender Spender address
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @return res Maximum amount spender can withdraw from account borrows on a given market based on a given collteral
	function getAccountBorrowAllowance (
		address account, 
		address spender, 
		address market, 
		address collateral
	)
		external 
		view
		returns (uint256 res)
	{
		res = borrows[account][collateral][market].allowance[spender];
	}

	/// @notice Deposit ERC20 asset for supplying
	/// @param market Address of the given market
	/// @param amount The amount of asset supplier supplies
	/// @param referralCode A unique code used as an identifier of the referrer
	function supply(address market, uint256 amount, uint16 referralCode)
		external
		isNotETHAddress(market)
	{
		supplyInternal(msg.sender, market, amount, referralCode);
	}

	/// @notice Deposit ETH for supplying
	/// @notice msg.value The amount of asset supplier supplies
	/// @param referralCode A unique code used as an identifier of the referrer
	function supply(uint16 referralCode) external payable {		
		supplyInternal(msg.sender, ethAddress, msg.value, referralCode);
	}

	/// @notice Sender supplies ERC20 asset belonging to the supplier
	/// @param account Address of the supplier
	/// @param market Address of the given market
	/// @param amount The amount of asset sender deposits
	/// @param referralCode A unique code used as an identifier of the referrer
	function supplyBehalf(address account, address market, uint256 amount, uint16 referralCode)
		external
		isNotETHAddress(market)
	{
		supplyInternal(account, market, amount, referralCode);
	}

	/// @notice Sender supplies ETH belonging to the supplier
	/// @notice msg.value The amount of ETH sender deposits
	/// @param account Address of the supplier
	/// @param referralCode A unique code used as an identifier of the referrer
	function supplyBehalf(address account, uint16 referralCode) 
		external
		payable
	{
		supplyInternal(account, ethAddress, msg.value, referralCode);
	}

	/// @notice Sender approves the account to withdraw supply
	/// @param account Address of the spender
	/// @param market Address of the given market
	/// @param amount The amount is allowed to be withdrawn
	function approveWithdrawSupply(address account, address market, uint256 amount)
		external
		accountIsValid(account)
		marketIsActive(market)
	{
		supplies[msg.sender][market].allowance[account] = amount;
	}

	/// @notice Withdraw supply of a given market
	/// @param market Address of the given market
	/// @param amount The amount will be withdrawn from the market
	function withdrawSupply(address market, uint256 amount)
		external
	{
		withdrawSupplyInternal(msg.sender, market, amount);
	}

	/// @notice Sender withdraws supply belonging to the supplier
	/// @param account Address of the supplier
	/// @param market Address of the given market
	/// @param amount The amount will be withdrawn from the market
	function withdrawSupplyBehalf(address account, address market, uint256 amount) external {
		supplies[account][market].allowance[msg.sender] = supplies[account][market].allowance[msg.sender].sub(amount, 'E14');
		withdrawSupplyInternal(account, market, amount);
	}

	/// @notice Deposit ERC20 asset as collateral
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be collateralized
	function collateralize (address collateral, uint256 amount)
		external
		isNotETHAddress(collateral)
	{
		collateralizeInternal(msg.sender, collateral, amount);
	}

	/// @notice Deposit ETH as collateral
	/// @notice msg.value The amount of ETH will be collateralized
	function collateralize () external payable {
		collateralizeInternal(msg.sender, ethAddress, msg.value);
	}

	/// @notice Sender deposits ERC20 asset as collateral belonging to another user
	/// @param account Address of the user
	/// @param collateral Address of the given collateral
	/// @param amount The amount of asset sender deposits
	function collateralizeBehalf (address account, address collateral, uint256 amount)
		external
		isNotETHAddress(collateral)
	{
		collateralizeInternal(account, collateral, amount);
	}

	/// @notice Sender deposits ETH as collateral belonging to another user
	/// @notice msg.value The amount of ETH sender deposits
	/// @param account Address of the user
	function collateralizeBehalf (address account) external payable {
		collateralizeInternal(account, ethAddress, msg.value);
	}

	/// @notice Sender approves the account to withdraw the collateral
	/// @param account Address of the spender
	/// @param collateral Address of the given collateral
	/// @param amount The amount is allowed to be withdrawn
	function approveWithdrawCollateral (address account, address collateral, uint256 amount)
		external
		accountIsValid(account)
		collateralIsActive(collateral)
	{
		collaterals[msg.sender][collateral].allowance[account] = amount;
	}

	/// @notice Withdraw the collateral
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be withdrawn from the collateral
	function withdrawCollateral (address collateral, uint256 amount)
		external
	{
		withdrawCollateralInternal(msg.sender, collateral, amount);
	}

	/// @notice Sender withdraws the collateral belonging to another user
	/// @param account Address of the user
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be withdrawn from the collateral
	function withdrawCollateralBehalf (address account, address collateral, uint256 amount)
		external
	{
		collaterals[account][collateral].allowance[msg.sender] = 
			collaterals[account][collateral].allowance[msg.sender].sub(amount, 'E14');
		withdrawCollateralInternal(account, collateral, amount);
	}

	/// @notice Sender approves the account to borrow a given market based on given collateral
	/// @param account Address of the spender
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @param amount The amount is allowed to be withdrawn
	function approveBorrow (address account, address market, address collateral, uint256 amount)
		external
		accountIsValid(account)
		marketIsActive(market)
	{
		borrows[msg.sender][collateral][market].allowance[account] = amount;
	}

	/// @notice Borrow an asset
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @param amount The amount of the given market will be borrowed
	/// @param referralCode A unique code used as an identifier of the referrer
	function borrow (address market, address collateral, uint256 amount, uint16 referralCode)
		external
	{
		borrowInternal(msg.sender, market, collateral, amount, referralCode);
	}

	/// @notice Sender borrows an asset belonging to the borrower
	/// @param account Address of the borrower
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be borrowed
	/// @param referralCode A unique code used as an identifier of the referrer
	function borrowBehalf (address account, address market, address collateral, uint256 amount, uint16 referralCode)
		external
	{
		borrows[account][collateral][market].allowance[msg.sender] = 
			borrows[account][collateral][market].allowance[msg.sender].sub(amount, 'E14');
		borrowInternal(account, market, collateral, amount, referralCode);
	}

	/// @notice Repay an ERC20 asset based on a given collateral
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @param amount The amount of the market will be Repaid
	function repayBorrow (address market, address collateral, uint256 amount)
		external
		isNotETHAddress(market)
	{
		repayBorrowInternal(msg.sender, market, collateral, amount);
	}

	/// @notice Repay an ETH based on a given collateral
	/// @notice msg.value The amount of ETH will be repaid
	/// @param collateral Address of the given collateral
	function repayBorrow (address collateral) external payable {		
		repayBorrowInternal(msg.sender, ethAddress, collateral, msg.value);
	}

	/// @notice Sender repays an ERC20 asset based on a given collateral belonging to the borrower
	/// @param account Address of the borrower
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @param amount The amount of the market will be repaid
	function repayBorrowBehalf (address account, address market, address collateral, uint256 amount)
		external
		isNotETHAddress(market)
	{
		repayBorrowInternal(account, market, collateral, amount);
	}

	/// @notice Sender repays an ETH based on a given collateral belonging to the borrower
	/// @notice msg.value The amount of ETH sender repays
	/// @param account Address of the borrower
	/// @param collateral Address of the given collateral
	function repayBorrowBehalf (address account, address collateral)
		external
		payable
	{		
		repayBorrowInternal(account, ethAddress, collateral, msg.value);
	}

	/// @notice Liquidate borrower's collateral
	/// @param borrower Address of the borrower who should be liquidated
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	function liquidateBorrowerCollateral (address borrower, address market, address collateral)
		external
		whenNotPaused("liquidateBorrowerCollateral")
	{
		MarketData memory borrowData;
		(borrowData.balance, borrowData.interest,) = getAccountBorrow(borrower, market, collateral);
		require(borrowData.balance > 0, "E05");

		(uint256 collateralBalance, uint256 timeSinceLastActivity,,, bool underCollateral) = 
			getAccountCollateral(borrower, collateral);
		require (underCollateral || (timeSinceLastActivity > secondsPerYear),
			"E06"
		);

		uint256 totalBorrowedBalance = borrowData.balance.add(borrowData.interest);
		uint256 totalBorrowedBalanceValue = holdefiPrices.getAssetValueFromAmount(market, totalBorrowedBalance);
		
		uint256 liquidatedCollateralValue = totalBorrowedBalanceValue
			.mul(holdefiSettings.collateralAssets(collateral).penaltyRate)
			.div(rateDecimals);

		uint256 liquidatedCollateral =
			holdefiPrices.getAssetAmountFromValue(collateral, liquidatedCollateralValue);

		if (liquidatedCollateral > collateralBalance) {
			liquidatedCollateral = collateralBalance;
		}

		collaterals[borrower][collateral].balance = collateralBalance.sub(liquidatedCollateral);
		collateralAssets[collateral].totalCollateral =
			collateralAssets[collateral].totalCollateral.sub(liquidatedCollateral);
		collateralAssets[collateral].totalLiquidatedCollateral =
			collateralAssets[collateral].totalLiquidatedCollateral.add(liquidatedCollateral);

		delete borrows[borrower][collateral][market];
		beforeChangeSupplyRate(market);
		marketAssets[market].totalBorrow = marketAssets[market].totalBorrow.sub(borrowData.balance);
		marketDebt[collateral][market] = marketDebt[collateral][market].add(totalBorrowedBalance);

		emit CollateralLiquidated(borrower, market, collateral, totalBorrowedBalance, liquidatedCollateral);	
	}

	/// @notice Buy collateral in exchange for ERC20 asset
	/// @param market Address of the market asset should be paid to buy collateral
	/// @param collateral Address of the liquidated collateral
	/// @param marketAmount The amount of the given market will be paid
	function buyLiquidatedCollateral (address market, address collateral, uint256 marketAmount)
		external
		isNotETHAddress(market)
	{
		buyLiquidatedCollateralInternal(market, collateral, marketAmount);
	}

	/// @notice Buy collateral in exchange for ETH
	/// @notice msg.value The amount of the given market that will be paid
	/// @param collateral Address of the liquidated collateral
	function buyLiquidatedCollateral (address collateral) external payable {
		buyLiquidatedCollateralInternal(ethAddress, collateral, msg.value);
	}

	/// @notice Deposit ERC20 asset as liquidation reserve
	/// @param collateral Address of the given collateral
	/// @param amount The amount that will be deposited
	function depositLiquidationReserve(address collateral, uint256 amount)
		external
		isNotETHAddress(collateral)
	{
		depositLiquidationReserveInternal(collateral, amount);
	}

	/// @notice Deposit ETH asset as liquidation reserve
	/// @notice msg.value The amount of ETH that will be deposited
	function depositLiquidationReserve() external payable {
		depositLiquidationReserveInternal(ethAddress, msg.value);
	}

	/// @notice Withdraw liquidation reserve only by the owner
	/// @param collateral Address of the given collateral
	/// @param amount The amount that will be withdrawn
	function withdrawLiquidationReserve (address collateral, uint256 amount) external onlyOwner {
		uint256 maxWithdraw = getLiquidationReserve(collateral);
		uint256 transferAmount = amount;
		
		if (transferAmount > maxWithdraw){
			transferAmount = maxWithdraw;
		}

		collateralAssets[collateral].totalLiquidatedCollateral =
			collateralAssets[collateral].totalLiquidatedCollateral.sub(transferAmount);
		holdefiCollaterals.withdraw(collateral, msg.sender, transferAmount);

		emit LiquidationReserveWithdrawn(collateral, transferAmount);
	}

	/// @notice Deposit ERC20 asset as promotion reserve
	/// @param market Address of the given market
	/// @param amount The amount that will be deposited
	function depositPromotionReserve (address market, uint256 amount)
		external
		isNotETHAddress(market)
	{
		depositPromotionReserveInternal(market, amount);
	}

	/// @notice Deposit ETH as promotion reserve
	/// @notice msg.value The amount of ETH that will be deposited
	function depositPromotionReserve () external payable {
		depositPromotionReserveInternal(ethAddress, msg.value);
	}

	/// @notice Withdraw promotion reserve only by the owner
	/// @param market Address of the given market
	/// @param amount The amount that will be withdrawn
	function withdrawPromotionReserve (address market, uint256 amount) external onlyOwner {
	    uint256 reserveScaled = getPromotionReserve(market);
	    uint256 debtScaled = getPromotionDebt(market);

	    uint256 amountScaled = amount.mul(secondsPerYear).mul(rateDecimals);
	    require (reserveScaled > amountScaled.add(debtScaled), "E07");

	    marketAssets[market].promotionReserveScaled = reserveScaled.sub(amountScaled);
	    marketAssets[market].promotionReserveLastUpdateTime = block.timestamp;

	    transferFromHoldefi(msg.sender, market, amount);

	    emit PromotionReserveWithdrawn(market, amount, marketAssets[market].promotionReserveScaled);
	 }


	/// @notice Set Holdefi prices contract only by the owner
	/// @param newHoldefiPrices Address of the new Holdefi prices contract
	function setHoldefiPricesContract (HoldefiPricesInterface newHoldefiPrices) external onlyOwner {
		emit HoldefiPricesContractChanged(address(newHoldefiPrices), address(holdefiPrices));
		holdefiPrices = newHoldefiPrices;
	}

	/// @notice Promotion reserve and debt settlement
	/// @param market Address of the given market
	function reserveSettlement (address market) external {
		require(msg.sender == address(holdefiSettings), "E15");

		updateSupplyIndex(market);
		uint256 reserveScaled = getPromotionReserve(market);
		uint256 debtScaled = getPromotionDebt(market);

		marketAssets[market].promotionReserveScaled = reserveScaled.sub(debtScaled, "E13");
		marketAssets[market].promotionDebtScaled = 0;

		marketAssets[market].promotionReserveLastUpdateTime = block.timestamp;
		marketAssets[market].promotionDebtLastUpdateTime = block.timestamp;

		emit PromotionReserveUpdated(market, marketAssets[market].promotionReserveScaled);
		emit PromotionDebtUpdated(market, 0);
	}

	/// @notice Update supply index of a market
	/// @param market Address of the given market
	function updateSupplyIndex (address market) internal {
		(uint256 currentSupplyIndex, uint256 supplyRate) = getCurrentSupplyIndex(market);

		marketAssets[market].supplyIndex = currentSupplyIndex;
		marketAssets[market].supplyIndexUpdateTime = block.timestamp;

		emit UpdateSupplyIndex(market, currentSupplyIndex, supplyRate);
	}

	/// @notice Update borrow index of a market
	/// @param market Address of the given market
	function updateBorrowIndex (address market) internal {
		(uint256 currentBorrowIndex, uint256 borrowRate) = getCurrentBorrowIndex(market);

		marketAssets[market].borrowIndex = currentBorrowIndex;
		marketAssets[market].borrowIndexUpdateTime = block.timestamp;

		emit UpdateBorrowIndex(market, currentBorrowIndex, borrowRate);
	}

	/// @notice Transfer ETH or ERC20 asset from this contract
	function transferFromHoldefi(address receiver, address asset, uint256 amount) internal {
		if (asset == ethAddress){
			(bool success, ) = receiver.call{value:amount}("");
			require (success, "E08");
		}
		else {
			IERC20 token = IERC20(asset);
			token.safeTransfer(receiver, amount);
		}
	}

	/// @notice Transfer ERC20 asset from msg.sender
	function transferFromSender(address receiver, address asset, uint256 amount) internal returns(uint256 transferAmount) {
		transferAmount = amount;
		if (asset != ethAddress) {
			IERC20 token = IERC20(asset);
			uint256 oldBalance = token.balanceOf(receiver);
			token.safeTransferFrom(msg.sender, receiver, amount);
			transferAmount = token.balanceOf(receiver).sub(oldBalance);
		}
	}

	/// @notice Perform supply operation
	function supplyInternal(address account, address market, uint256 amount, uint16 referralCode)
		internal
		nonReentrant
		whenNotPaused("supply")
		marketIsActive(market)
	{
		uint256 transferAmount = transferFromSender(address(this), market, amount);

		MarketData memory supplyData;
		(supplyData.balance, supplyData.interest, supplyData.currentIndex) = getAccountSupply(account, market);
		
		supplyData.balance = supplyData.balance.add(transferAmount);
		supplies[account][market].balance = supplyData.balance;
		supplies[account][market].accumulatedInterest = supplyData.interest;
		supplies[account][market].lastInterestIndex = supplyData.currentIndex;

		beforeChangeSupplyRate(market);
		marketAssets[market].totalSupply = marketAssets[market].totalSupply.add(transferAmount);

		emit Supply(
			msg.sender,
			account,
			market,
			transferAmount,
			supplyData.balance,
			supplyData.interest,
			supplyData.currentIndex,
			referralCode
		);
	}

	/// @notice Perform withdraw supply operation
	function withdrawSupplyInternal (address account, address market, uint256 amount) 
		internal
		nonReentrant
		whenNotPaused("withdrawSupply")
	{
		MarketData memory supplyData;
		(supplyData.balance, supplyData.interest, supplyData.currentIndex) = getAccountSupply(account, market);
		uint256 totalSuppliedBalance = supplyData.balance.add(supplyData.interest);
		require (totalSuppliedBalance != 0, "E09");

		uint256 transferAmount = amount;
		if (transferAmount > totalSuppliedBalance){
			transferAmount = totalSuppliedBalance;
		}

		if (transferAmount <= supplyData.interest) {
			supplyData.interest = supplyData.interest.sub(transferAmount);
		}
		else {
			uint256 remaining = transferAmount.sub(supplyData.interest);
			supplyData.interest = 0;
			supplyData.balance = supplyData.balance.sub(remaining);

			beforeChangeSupplyRate(market);
			marketAssets[market].totalSupply = marketAssets[market].totalSupply.sub(remaining);	
		}

		supplies[account][market].balance = supplyData.balance;
		supplies[account][market].accumulatedInterest = supplyData.interest;
		supplies[account][market].lastInterestIndex = supplyData.currentIndex;

		transferFromHoldefi(msg.sender, market, transferAmount);
	
		emit WithdrawSupply(
			msg.sender,
			account,
			market,
			transferAmount,
			supplyData.balance,
			supplyData.interest,
			supplyData.currentIndex
		);
	}

	/// @notice Perform collateralize operation
	function collateralizeInternal (address account, address collateral, uint256 amount)
		internal
		nonReentrant
		whenNotPaused("collateralize")
		collateralIsActive(collateral)
	{
		uint256 transferAmount = transferFromSender(address(holdefiCollaterals), collateral, amount);
		if (collateral == ethAddress) {
			transferFromHoldefi(address(holdefiCollaterals), collateral, amount);
		}

		uint256 balance = collaterals[account][collateral].balance.add(transferAmount);
		collaterals[account][collateral].balance = balance;
		collaterals[account][collateral].lastUpdateTime = block.timestamp;

		collateralAssets[collateral].totalCollateral = collateralAssets[collateral].totalCollateral.add(transferAmount);	
		
		emit Collateralize(msg.sender, account, collateral, transferAmount, balance);
	}

	/// @notice Perform withdraw collateral operation
	function withdrawCollateralInternal (address account, address collateral, uint256 amount) 
		internal
		nonReentrant
		whenNotPaused("withdrawCollateral")
	{
		(uint256 balance,, uint256 borrowPowerValue, uint256 totalBorrowValue,) =
			getAccountCollateral(account, collateral);

		require (borrowPowerValue != 0, "E10");

		uint256 collateralNedeed = 0;
		if (totalBorrowValue != 0) {
			uint256 valueToLoanRate = holdefiSettings.collateralAssets(collateral).valueToLoanRate;
			uint256 totalCollateralValue = totalBorrowValue.mul(valueToLoanRate).div(rateDecimals);
			collateralNedeed = holdefiPrices.getAssetAmountFromValue(collateral, totalCollateralValue);
		}

		uint256 maxWithdraw = balance.sub(collateralNedeed);
		uint256 transferAmount = amount;
		if (transferAmount > maxWithdraw){
			transferAmount = maxWithdraw;
		}
		balance = balance.sub(transferAmount);
		collaterals[account][collateral].balance = balance;
		collaterals[account][collateral].lastUpdateTime = block.timestamp;

		collateralAssets[collateral].totalCollateral =
			collateralAssets[collateral].totalCollateral.sub(transferAmount);

		holdefiCollaterals.withdraw(collateral, msg.sender, transferAmount);

		emit WithdrawCollateral(msg.sender, account, collateral, transferAmount, balance);
	}

	/// @notice Perform borrow operation
	function borrowInternal (address account, address market, address collateral, uint256 amount, uint16 referralCode)
		internal
		nonReentrant
		whenNotPaused("borrow")
		marketIsActive(market)
		collateralIsActive(collateral)
	{
		require (amount <= (marketAssets[market].totalSupply.sub(marketAssets[market].totalBorrow)), "E11");

		(,, uint256 borrowPowerValue,,) = getAccountCollateral(account, collateral);
		uint256 assetToBorrowValue = holdefiPrices.getAssetValueFromAmount(market, amount);
		require (borrowPowerValue >= assetToBorrowValue, "E12");

		MarketData memory borrowData;
		(borrowData.balance, borrowData.interest, borrowData.currentIndex) = getAccountBorrow(account, market, collateral);
		
		borrowData.balance = borrowData.balance.add(amount);
		borrows[account][collateral][market].balance = borrowData.balance;
		borrows[account][collateral][market].accumulatedInterest = borrowData.interest;
		borrows[account][collateral][market].lastInterestIndex = borrowData.currentIndex;
		collaterals[account][collateral].lastUpdateTime = block.timestamp;

		beforeChangeSupplyRate(market);
		marketAssets[market].totalBorrow = marketAssets[market].totalBorrow.add(amount);

		transferFromHoldefi(msg.sender, market, amount);

		emit Borrow(
			msg.sender, 
			account,
			market,
			collateral,
			amount,
			borrowData.balance,
			borrowData.interest,
			borrowData.currentIndex,
			referralCode
		);
	}

	/// @notice Perform repay borrow operation
	function repayBorrowInternal (address account, address market, address collateral, uint256 amount)
		internal
		nonReentrant
		whenNotPaused("repayBorrow")
	{
		MarketData memory borrowData;
		(borrowData.balance, borrowData.interest, borrowData.currentIndex) =
			getAccountBorrow(account, market, collateral);

		uint256 totalBorrowedBalance = borrowData.balance.add(borrowData.interest);
		require (totalBorrowedBalance != 0, "E09");

		uint256 transferAmount = transferFromSender(address(this), market, amount);
		uint256 extra = 0;
		if (transferAmount > totalBorrowedBalance) {
			extra = transferAmount.sub(totalBorrowedBalance);
			transferAmount = totalBorrowedBalance;
		}

		if (transferAmount <= borrowData.interest) {
			borrowData.interest = borrowData.interest.sub(transferAmount);
		}
		else {
			uint256 remaining = transferAmount.sub(borrowData.interest);
			borrowData.interest = 0;
			borrowData.balance = borrowData.balance.sub(remaining);

			beforeChangeSupplyRate(market);
			marketAssets[market].totalBorrow = marketAssets[market].totalBorrow.sub(remaining);	
		}
		borrows[account][collateral][market].balance = borrowData.balance;
		borrows[account][collateral][market].accumulatedInterest = borrowData.interest;
		borrows[account][collateral][market].lastInterestIndex = borrowData.currentIndex;
		collaterals[account][collateral].lastUpdateTime = block.timestamp;

		if (extra > 0) {
			transferFromHoldefi(msg.sender, market, extra);
		}
		
		emit RepayBorrow (
			msg.sender,
			account,
			market,
			collateral,
			transferAmount,
			borrowData.balance,
			borrowData.interest,
			borrowData.currentIndex
		);
	}

	/// @notice Perform buy liquidated collateral operation
	function buyLiquidatedCollateralInternal (address market, address collateral, uint256 marketAmount)
		internal
		nonReentrant
		whenNotPaused("buyLiquidatedCollateral")
	{
		uint256 transferAmount = transferFromSender(address(this), market, marketAmount);
		marketDebt[collateral][market] = marketDebt[collateral][market].sub(transferAmount, 'E17');

		uint256 collateralAmountWithDiscount =
			getDiscountedCollateralAmount(market, collateral, transferAmount);		
		collateralAssets[collateral].totalLiquidatedCollateral = 
			collateralAssets[collateral].totalLiquidatedCollateral.sub(collateralAmountWithDiscount, 'E16');
		
		holdefiCollaterals.withdraw(collateral, msg.sender, collateralAmountWithDiscount);

		emit BuyLiquidatedCollateral(market, collateral, transferAmount, collateralAmountWithDiscount);
	}

	/// @notice Perform deposit promotion reserve operation
	function depositPromotionReserveInternal (address market, uint256 amount)
		internal
		nonReentrant
		whenNotPaused("depositPromotionReserve")
		marketIsActive(market)
	{
		uint256 transferAmount = transferFromSender(address(this), market, amount);

		uint256 amountScaled = transferAmount.mul(secondsPerYear).mul(rateDecimals);

		marketAssets[market].promotionReserveScaled = 
			marketAssets[market].promotionReserveScaled.add(amountScaled);

		emit PromotionReserveDeposited(market, transferAmount, marketAssets[market].promotionReserveScaled);
	}

	/// @notice Perform deposit liquidation reserve operation
	function depositLiquidationReserveInternal (address collateral, uint256 amount)
		internal
		nonReentrant
		whenNotPaused("depositLiquidationReserve")
		collateralIsActive(collateral)
	{
		uint256 transferAmount = transferFromSender(address(holdefiCollaterals), collateral, amount);
		if (collateral == ethAddress) {
			transferFromHoldefi(address(holdefiCollaterals), collateral, amount);
		}

		collateralAssets[collateral].totalLiquidatedCollateral =
			collateralAssets[collateral].totalLiquidatedCollateral.add(transferAmount);
		
		emit LiquidationReserveDeposited(collateral, transferAmount);
	}
}