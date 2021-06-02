// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
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
contract Holdefi is HoldefiPausableOwnable {

	using SafeMath for uint256;

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

	address constant public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	/// @notice All rates in this contract are scaled by rateDecimals
	uint256 constant public rateDecimals = 10 ** 4;

	uint256 constant public secondsPerYear = 31536000;

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
	mapping (address => mapping (address => uint)) public marketDebt;

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

	/// @notice Event emitted when a collateral asset is deposited
	event Collateralize(
		address sender,
		address indexed collateralizer,
		address indexed collateral,
		uint256 amount,
		uint256 balance
	);

	/// @notice Event emitted when a collateral is withdrawn
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
	event UpdateBorrowIndex(address indexed market, uint256 newBorrowIndex);

	/// @notice Event emitted when a collateral is liquidated
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
	event PromotionReserveWithdrawn(address indexed market, uint256 amount);

	/// @notice Event emitted when a promotion reserve is deposited
	event PromotionReserveDeposited(address indexed market, uint256 amount);

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
        require (asset != ethAddress, "Asset should not be ETH address");
        _;
    }

	/// @dev Modifier to check if the market is active or not
	/// @param market Address of the given market
    modifier marketIsActive(address market) {
		require (holdefiSettings.marketAssets(market).isActive, "Market is not active");
        _;
    }

	/// @dev Modifier to check if the collateral is active or not
	/// @param collateral Address of the given collateral
    modifier collateralIsActive(address collateral) {
		require (holdefiSettings.collateralAssets(collateral).isActive, "Collateral is not active");
        _;
    }

	/// @dev Modifier to check if the account address is equal to the msg.sender or not
    /// @param account The given account address
    modifier accountIsValid(address account) {
		require (msg.sender != account, "Account is not valid");
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

		(currentSupplyIndex,,) = getCurrentSupplyIndex(market);

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

		(currentBorrowIndex,,) = getCurrentBorrowIndex(market);

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
    /// @return currentTime Current block timestamp
	function getCurrentSupplyIndex (address market)
		public
		view
		returns (
			uint256 supplyIndex,
			uint256 supplyRate,
			uint256 currentTime
		)
	{
		(, uint256 supplyRateBase, uint256 promotionRate) = holdefiSettings.getInterests(market);
		
		currentTime = block.timestamp;
		uint256 deltaTimeSupply = currentTime.sub(marketAssets[market].supplyIndexUpdateTime);

		supplyRate = supplyRateBase.add(promotionRate);
		uint256 deltaTimeInterest = deltaTimeSupply.mul(supplyRate);
		supplyIndex = marketAssets[market].supplyIndex.add(deltaTimeInterest);
	}

	/// @notice Returns borrow index and borrow rate for the given market at current time
	/// @dev newBorrowIndex = oldBorrowIndex + (deltaTime * borrowRate)
    /// @param market Address of the given market
    /// @return borrowIndex Borrow index of the given market
    /// @return borrowRate Borrow rate of the given market
    /// @return currentTime Current block timestamp
	function getCurrentBorrowIndex (address market)
		public
		view
		returns (
			uint256 borrowIndex,
			uint256 borrowRate,
			uint256 currentTime
		)
	{
		borrowRate = holdefiSettings.marketAssets(market).borrowRate;
		
		currentTime = block.timestamp;
		uint256 deltaTimeBorrow = currentTime.sub(marketAssets[market].borrowIndexUpdateTime);

		uint256 deltaTimeInterest = deltaTimeBorrow.mul(borrowRate);
		borrowIndex = marketAssets[market].borrowIndex.add(deltaTimeInterest);
	}

	/// @notice Returns promotion reserve for a given market at current time
	/// @dev promotionReserveScaled is scaled by (secondsPerYear * rateDecimals)
	/// @param market Address of the given market
    /// @return promotionReserveScaled Promotion reserve of the given market
    /// @return currentTime Current block timestamp
	function getPromotionReserve (address market)
		public
		view
		returns (uint256 promotionReserveScaled, uint256 currentTime)
	{
		(uint256 borrowRate, uint256 supplyRateBase,) = holdefiSettings.getInterests(market);
		currentTime = block.timestamp;
	
		uint256 allSupplyInterest = marketAssets[market].totalSupply.mul(supplyRateBase);
		uint256 allBorrowInterest = marketAssets[market].totalBorrow.mul(borrowRate);

		uint256 deltaTime = currentTime.sub(marketAssets[market].promotionReserveLastUpdateTime);
		uint256 currentInterest = allBorrowInterest.sub(allSupplyInterest);
		uint256 deltaTimeInterest = currentInterest.mul(deltaTime);
		promotionReserveScaled = marketAssets[market].promotionReserveScaled.add(deltaTimeInterest);
	}

	/// @notice Returns promotion debt for a given market at current time
	/// @dev promotionDebtScaled is scaled by secondsPerYear * rateDecimals
	/// @param market Address of the given market
    /// @return promotionDebtScaled Promotion debt of the given market
    /// @return currentTime Current block timestamp
	function getPromotionDebt (address market)
		public
		view
		returns (uint256 promotionDebtScaled, uint256 currentTime)
	{
		uint256 promotionRate = holdefiSettings.marketAssets(market).promotionRate;

		currentTime = block.timestamp;
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
		updatePromotionReserve(market);
		updatePromotionDebt(market);
	}

	/// @notice Update a market borrow index, supply index, promotion reserve, and promotion debt 
	/// @param market Address of the given market
	function beforeChangeBorrowRate (address market) external {
		updateBorrowIndex(market);
		beforeChangeSupplyRate(market);
	}

	/// @notice Deposit ERC20 asset for supplying
	/// @param market Address of the given market
	/// @param amount The amount of asset supplier supplies
	/// @param referralCode A unique code used as an identifier of referrer
	function supply(address market, uint256 amount, uint16 referralCode)
		external
		isNotETHAddress(market)
	{
		supplyInternal(msg.sender, market, amount, referralCode);
	}

	/// @notice Deposit ETH for supplying
	/// @notice msg.value The amount of asset supplier supplies
	/// @param referralCode A unique code used as an identifier of referrer
	function supply(uint16 referralCode) external payable {		
		supplyInternal(msg.sender, ethAddress, msg.value, referralCode);
	}

	/// @notice Sender deposits ERC20 asset belonging to the supplier
	/// @param account Address of the supplier
	/// @param market Address of the given market
	/// @param amount The amount of asset supplier supplies
	/// @param referralCode A unique code used as an identifier of referrer
	function supplyBehalf(address account, address market, uint256 amount, uint16 referralCode)
		external
		isNotETHAddress(market)
	{
		supplyInternal(account, market, amount, referralCode);
	}

	/// @notice Sender deposits ETH belonging to the supplier
	/// @notice msg.value The amount of ETH sender deposits belonging to the supplier
	/// @param account Address of the supplier
	/// @param referralCode A unique code used as an identifier of referrer
	function supplyBehalf(address account, uint16 referralCode) 
		external
		payable
	{
		supplyInternal(account, ethAddress, msg.value, referralCode);
	}

	/// @notice Sender approves of the withdarawl for the account in the market asset
	/// @param account Address of the account allowed to withdrawn
	/// @param market Address of the given market
	/// @param amount The amount is allowed to withdrawn
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
		uint256 allowance = supplies[account][market].allowance[msg.sender];
		require(
			amount <= allowance, 
			"Withdraw not allowed"
		);
		supplies[account][market].allowance[msg.sender] = allowance.sub(amount);
		withdrawSupplyInternal(account, market, amount);
	}

	/// @notice Deposit ERC20 asset as a collateral
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be collateralized
	function collateralize (address collateral, uint256 amount)
		external
		isNotETHAddress(collateral)
	{
		collateralizeInternal(msg.sender, collateral, amount);
	}

	/// @notice Deposit ETH as a collateral
	/// @notice msg.value The amount of ETH will be collateralized
	function collateralize () external payable {
		collateralizeInternal(msg.sender, ethAddress, msg.value);
	}

	/// @notice Sender deposits ERC20 asset as a collateral belonging to the user
	/// @param account Address of the user
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be collateralized
	function collateralizeBehalf (address account, address collateral, uint256 amount)
		external
		isNotETHAddress(collateral)
	{
		collateralizeInternal(account, collateral, amount);
	}

	/// @notice Sender deposits ETH as a collateral belonging to the user
	/// @notice msg.value The amount of ETH Sender deposits as a collateral belonging to the user
	/// @param account Address of the user
	function collateralizeBehalf (address account) external payable {
		collateralizeInternal(account, ethAddress, msg.value);
	}

	/// @notice Sender approves the account to withdraw the collateral
	/// @param account Address is allowed to withdraw the collateral
	/// @param collateral Address of the given collateral
	/// @param amount The amount is allowed to withdrawn
	function approveWithdrawCollateral (address account, address collateral, uint256 amount)
		external
		accountIsValid(account)
		collateralIsActive(collateral)
	{
		collaterals[msg.sender][collateral].allowance[account] = amount;
	}

	/// @notice Withdraw a collateral
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be withdrawn from the collateral
	function withdrawCollateral (address collateral, uint256 amount)
		external
	{
		withdrawCollateralInternal(msg.sender, collateral, amount);
	}

	/// @notice Sender withdraws a collateral belonging to the user
	/// @param account Address of the user
	/// @param collateral Address of the given collateral
	/// @param amount The amount will be withdrawn from the collateral
	function withdrawCollateralBehalf (address account, address collateral, uint256 amount)
		external
	{
		uint256 allowance = collaterals[account][collateral].allowance[msg.sender];
		require(
			amount <= allowance,
			"Withdraw not allowed"
		);
		collaterals[account][collateral].allowance[msg.sender] = allowance.sub(amount);
		withdrawCollateralInternal(account, collateral, amount);
	}

	/// @notice Sender approves the account to borrow a given market based on given collateral
	/// @param account Address that is allowed to borrow the given market
	/// @param market Address of the given market
	/// @param collateral Address of the given collateral
	/// @param amount The amount is allowed to withdrawn
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
	/// @param referralCode A unique code used as an identifier of referrer
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
	/// @param referralCode A unique code used as an identifier of referrer
	function borrowBehalf (address account, address market, address collateral, uint256 amount, uint16 referralCode)
		external
	{
		uint256 allowance = borrows[account][collateral][market].allowance[msg.sender];
		require(
			amount <= allowance,
			"Withdraw not allowed"
		);
		borrows[account][collateral][market].allowance[msg.sender] = allowance.sub(amount);
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
	/// @notice msg.value The amount of ETH sender repays belonging to the borrower
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
		require(borrowData.balance > 0, "User should have debt");

		(uint256 collateralBalance, uint256 timeSinceLastActivity,,, bool underCollateral) = 
			getAccountCollateral(borrower, collateral);
		require (underCollateral || (timeSinceLastActivity > secondsPerYear),
			"User should be under collateral or time is over"
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

		emit LiquidationReserveWithdrawn(collateral, amount);
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
	    (uint256 reserveScaled,) = getPromotionReserve(market);
	    (uint256 debtScaled,) = getPromotionDebt(market);

	    uint256 amountScaled = amount.mul(secondsPerYear).mul(rateDecimals);
	    uint256 increasedDebtScaled = amountScaled.add(debtScaled);
	    require (reserveScaled > increasedDebtScaled, "Amount should be less than max");

	    marketAssets[market].promotionReserveScaled = reserveScaled.sub(amountScaled);

	    transferFromHoldefi(msg.sender, market, amount);

	    emit PromotionReserveWithdrawn(market, amount);
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
		require(msg.sender == address(holdefiSettings), "Sender should be Holdefi Settings contract");

		uint256 promotionReserve = marketAssets[market].promotionReserveScaled;
		uint256 promotionDebt = marketAssets[market].promotionDebtScaled;
		require(promotionReserve > promotionDebt, "Not enough promotion reserve");
		
		promotionReserve = promotionReserve.sub(promotionDebt);
		marketAssets[market].promotionReserveScaled = promotionReserve;
		marketAssets[market].promotionDebtScaled = 0;

		marketAssets[market].promotionReserveLastUpdateTime = block.timestamp;
		marketAssets[market].promotionDebtLastUpdateTime = block.timestamp;

		emit PromotionReserveUpdated(market, promotionReserve);
		emit PromotionDebtUpdated(market, 0);
	}

	/// @notice Update supply index of a market
	/// @param market Address of the given market
	function updateSupplyIndex (address market) internal {
		(uint256 currentSupplyIndex, uint256 supplyRate, uint256 currentTime) =
			getCurrentSupplyIndex(market);

		marketAssets[market].supplyIndex = currentSupplyIndex;
		marketAssets[market].supplyIndexUpdateTime = currentTime;

		emit UpdateSupplyIndex(market, currentSupplyIndex, supplyRate);
	}

	/// @notice Update borrow index of a market
	/// @param market Address of the given market
	function updateBorrowIndex (address market) internal {
		(uint256 currentBorrowIndex,, uint256 currentTime) = getCurrentBorrowIndex(market);

		marketAssets[market].borrowIndex = currentBorrowIndex;
		marketAssets[market].borrowIndexUpdateTime = currentTime;

		emit UpdateBorrowIndex(market, currentBorrowIndex);
	}

	/// @notice Update promotion reserve of a market
	/// @param market Address of the given market
	function updatePromotionReserve(address market) internal {
		(uint256 reserveScaled,) = getPromotionReserve(market);

		marketAssets[market].promotionReserveScaled = reserveScaled;
		marketAssets[market].promotionReserveLastUpdateTime = block.timestamp;

		emit PromotionReserveUpdated(market, reserveScaled);
	}

	/// @notice Update promotion debt of a market
	/// @dev Promotion rate will be set to 0 if (promotionDebt >= promotionReserve)
	/// @param market Address of the given market
	function updatePromotionDebt(address market) internal {
    	(uint256 debtScaled,) = getPromotionDebt(market);
    	if (marketAssets[market].promotionDebtScaled != debtScaled){
      		marketAssets[market].promotionDebtScaled = debtScaled;
      		marketAssets[market].promotionDebtLastUpdateTime = block.timestamp;

      		emit PromotionDebtUpdated(market, debtScaled);
    	}
    	if (marketAssets[market].promotionReserveScaled <= debtScaled) {
      		holdefiSettings.resetPromotionRate(market);
    	}
  	}

	/// @notice transfer ETH or ERC20 asset from this contract
	function transferFromHoldefi(address receiver, address asset, uint256 amount) internal {
		bool success = false;
		if (asset == ethAddress){
			(success, ) = receiver.call{value:amount}("");
		}
		else {
			IERC20 token = IERC20(asset);
			success = token.transfer(receiver, amount);
		}
		require (success, "Cannot Transfer");
	}
	/// @notice transfer ERC20 asset to this contract
	function transferToHoldefi(address receiver, address asset, uint256 amount) internal {
		IERC20 token = IERC20(asset);
		bool success = token.transferFrom(msg.sender, receiver, amount);
		require (success, "Cannot Transfer");
	}

	/// @notice Perform supply operation
	function supplyInternal(address account, address market, uint256 amount, uint16 referralCode)
		internal
		whenNotPaused("supply")
		marketIsActive(market)
	{
		if (market != ethAddress) {
			transferToHoldefi(address(this), market, amount);
		}

		MarketData memory supplyData;
		(supplyData.balance, supplyData.interest, supplyData.currentIndex) = getAccountSupply(account, market);
		
		supplyData.balance = supplyData.balance.add(amount);
		supplies[account][market].balance = supplyData.balance;
		supplies[account][market].accumulatedInterest = supplyData.interest;
		supplies[account][market].lastInterestIndex = supplyData.currentIndex;

		beforeChangeSupplyRate(market);
		
		marketAssets[market].totalSupply = marketAssets[market].totalSupply.add(amount);

		emit Supply(
			msg.sender,
			account,
			market,
			amount,
			supplyData.balance,
			supplyData.interest,
			supplyData.currentIndex,
			referralCode
		);
	}

	/// @notice Perform withdraw supply operation
	function withdrawSupplyInternal (address account, address market, uint256 amount) 
		internal
		whenNotPaused("withdrawSupply")
	{
		MarketData memory supplyData;
		(supplyData.balance, supplyData.interest, supplyData.currentIndex) = getAccountSupply(account, market);
		uint256 totalSuppliedBalance = supplyData.balance.add(supplyData.interest);
		require (totalSuppliedBalance != 0, "Total balance should not be zero");

		uint256 transferAmount = amount;
		if (transferAmount > totalSuppliedBalance){
			transferAmount = totalSuppliedBalance;
		}

		uint256 remaining = 0;
		if (transferAmount <= supplyData.interest) {
			supplyData.interest = supplyData.interest.sub(transferAmount);
		}
		else {
			remaining = transferAmount.sub(supplyData.interest);
			supplyData.interest = 0;
			supplyData.balance = supplyData.balance.sub(remaining);
		}

		supplies[account][market].balance = supplyData.balance;
		supplies[account][market].accumulatedInterest = supplyData.interest;
		supplies[account][market].lastInterestIndex = supplyData.currentIndex;

		beforeChangeSupplyRate(market);
		
		marketAssets[market].totalSupply = marketAssets[market].totalSupply.sub(remaining);	
		
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
		whenNotPaused("collateralize")
		collateralIsActive(collateral)
	{
		if (collateral != ethAddress) {
			transferToHoldefi(address(holdefiCollaterals), collateral, amount);
		}
		else {
			transferFromHoldefi(address(holdefiCollaterals), collateral, amount);
		}

		uint256 balance = collaterals[account][collateral].balance.add(amount);
		collaterals[account][collateral].balance = balance;
		collaterals[account][collateral].lastUpdateTime = block.timestamp;

		collateralAssets[collateral].totalCollateral = collateralAssets[collateral].totalCollateral.add(amount);	
		
		emit Collateralize(msg.sender, account, collateral, amount, balance);
	}

	/// @notice Perform withdraw collateral operation
	function withdrawCollateralInternal (address account, address collateral, uint256 amount) 
		internal
		whenNotPaused("withdrawCollateral")
	{
		(uint256 balance,, uint256 borrowPowerValue, uint256 totalBorrowValue,) =
			getAccountCollateral(account, collateral);

		require (borrowPowerValue != 0, "Borrow power should not be zero");

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
		whenNotPaused("borrow")
		marketIsActive(market)
		collateralIsActive(collateral)
	{
		require (
			amount <= (marketAssets[market].totalSupply.sub(marketAssets[market].totalBorrow)),
			"Amount should be less than cash"
		);

		(,, uint256 borrowPowerValue,,) = getAccountCollateral(account, collateral);
		uint256 assetToBorrowValue = holdefiPrices.getAssetValueFromAmount(market, amount);
		require (
			borrowPowerValue >= assetToBorrowValue,
			"Borrow power should be more than new borrow value"
		);

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
		whenNotPaused("repayBorrow")
	{
		MarketData memory borrowData;
		(borrowData.balance, borrowData.interest, borrowData.currentIndex) =
			getAccountBorrow(account, market, collateral);

		uint256 totalBorrowedBalance = borrowData.balance.add(borrowData.interest);
		require (totalBorrowedBalance != 0, "Total balance should not be zero");

		uint256 transferAmount = amount;
		if (transferAmount > totalBorrowedBalance) {
			transferAmount = totalBorrowedBalance;
			if (market == ethAddress) {
				uint256 extra = amount.sub(transferAmount);
				transferFromHoldefi(msg.sender, ethAddress, extra);
			}
		}
		
		if (market != ethAddress) {
			transferToHoldefi(address(this), market, transferAmount);
		}

		uint256 remaining = 0;
		if (transferAmount <= borrowData.interest) {
			borrowData.interest = borrowData.interest.sub(transferAmount);
		}
		else {
			remaining = transferAmount.sub(borrowData.interest);
			borrowData.interest = 0;
			borrowData.balance = borrowData.balance.sub(remaining);
		}
		borrows[account][collateral][market].balance = borrowData.balance;
		borrows[account][collateral][market].accumulatedInterest = borrowData.interest;
		borrows[account][collateral][market].lastInterestIndex = borrowData.currentIndex;
		collaterals[account][collateral].lastUpdateTime = block.timestamp;

		beforeChangeSupplyRate(market);
		
		marketAssets[market].totalBorrow = marketAssets[market].totalBorrow.sub(remaining);	

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
		whenNotPaused("buyLiquidatedCollateral")
	{
		uint256 debt = marketDebt[collateral][market];
		require (marketAmount <= debt,
			"Amount should be less than total liquidated assets"
		);

		uint256 collateralAmountWithDiscount =
			getDiscountedCollateralAmount(market, collateral, marketAmount);

		uint256 totalLiquidatedCollateral = collateralAssets[collateral].totalLiquidatedCollateral;
		require (
			collateralAmountWithDiscount <= totalLiquidatedCollateral,
			"Collateral amount with discount should be less than total liquidated assets"
		);

		if (market != ethAddress) {
			transferToHoldefi(address(this), market, marketAmount);
		}

		collateralAssets[collateral].totalLiquidatedCollateral = totalLiquidatedCollateral.sub(collateralAmountWithDiscount);
		marketDebt[collateral][market] = debt.sub(marketAmount);

		holdefiCollaterals.withdraw(collateral, msg.sender, collateralAmountWithDiscount);

		emit BuyLiquidatedCollateral(market, collateral, marketAmount, collateralAmountWithDiscount);
	}

	/// @notice Perform deposit promotion reserve operation
	function depositPromotionReserveInternal (address market, uint256 amount)
		internal
		marketIsActive(market)
	{
		if (market != ethAddress) {
			transferToHoldefi(address(this), market, amount);
		}
		uint256 amountScaled = amount.mul(secondsPerYear).mul(rateDecimals);

		marketAssets[market].promotionReserveScaled = 
			marketAssets[market].promotionReserveScaled.add(amountScaled);

		emit PromotionReserveDeposited(market, amount);
	}

	/// @notice Perform deposit liquidation reserve operation
	function depositLiquidationReserveInternal (address collateral, uint256 amount)
		internal
		collateralIsActive(ethAddress)
	{
		if (collateral != ethAddress) {
			transferToHoldefi(address(holdefiCollaterals), collateral, amount);
		}
		else {
			transferFromHoldefi(address(holdefiCollaterals), collateral, amount);
		}
		collateralAssets[ethAddress].totalLiquidatedCollateral =
			collateralAssets[ethAddress].totalLiquidatedCollateral.add(msg.value);
		
		emit LiquidationReserveDeposited(ethAddress, msg.value);
	}
}