// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IHoldefi {

	struct Market {
		uint256 totalSupply;

		uint256 supplyIndex;
		uint256 supplyIndexUpdateTime;

		uint256 totalBorrow;

		uint256 borrowIndex;
		uint256 borrowIndexUpdateTime;

		uint256 promotionReserveScaled;
		uint256 promotionReserveLastUpdateTime;

		uint256 promotionDebtScaled;
		uint256 promotionDebtLastUpdateTime;
	}


	struct Collateral {
		uint256 totalCollateral;
		uint256 totalLiquidatedCollateral;
	}

	function marketAssets(address market) external view returns(Market memory);
	function collateralAssets(address collateral) external view returns(Collateral memory);

	function getAccountSupply(address account, address market)
		external
		view
		returns (uint256 balance, uint256 interest, uint256 currentSupplyIndex);

	function getAccountBorrow(address account, address market, address collateral)
		external
		view
		returns (uint256 balance, uint256 interest, uint256 currentBorrowIndex);

	function getAccountCollateral(address account, address collateral)
		external
		view
		returns (
			uint256 balance,
			uint256 timeSinceLastActivity,
			uint256 borrowPowerValue,
			uint256 totalBorrowValue,
			bool underCollateral
		);

	function getCurrentSupplyIndex (address market)
		external
		view
		returns (
			uint256 supplyIndex,
			uint256 supplyRate,
			uint256 currentTime
		);

	function getCurrentBorrowIndex (address market)
		external
		view
		returns (
			uint256 borrowIndex,
			uint256 borrowRate,
			uint256 currentTime
		);

	function marketDebt (address collateral, address market)
		external
		view
		returns(
			uint256 debt
		);

	function isPaused(string memory operation) external view returns (bool res);
}

interface IHoldefiSettings {

	struct MarketSettings {
		bool isExist;
		bool isActive;      

		uint256 borrowRate;
		uint256 borrowRateUpdateTime;

		uint256 suppliersShareRate;
		uint256 suppliersShareRateUpdateTime;

		uint256 promotionRate;
	}

	struct CollateralSettings {
		bool isExist;
		bool isActive;    

		uint256 valueToLoanRate; 
		uint256 VTLUpdateTime;

		uint256 penaltyRate;
		uint256 penaltyUpdateTime;

		uint256 bonusRate;
	}

	function marketAssets(address market) external view returns(MarketSettings memory);
	function collateralAssets(address collateral) external view returns(CollateralSettings memory);
}


interface IHoldefiPrices {
	function getPrice(address asset) external view returns (uint256 price, uint256 priceDecimals);
}


contract HoldefiRead {

	address constant public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	string[8] private operationsList = [
		"supply",
		"withdrawSupply",
		"collateralize",
		"withdrawCollateral",
		"borrow",
		"repayBorrow",
		"liquidateBorrowerCollateral",
		"buyLiquidatedCollateral"
	];

	struct AccountMarketData {
		address market;
		uint256 balance;
		uint256 interest;
		uint256 index;
	}

	struct AccountCollateralData {
		address collateral;
		uint256 balance;
		uint256 timeSinceLastActivity;
		uint256 borrowPowerValue;
		uint256 totalBorrowValue;
		bool underCollateral;

		AccountMarketData[] userBorrows;
	}

	struct AccountAssetData {
		address asset;
		uint256 walletBalance;
		uint256 allowance;
		uint256 price;
		uint256 priceDecimals;
	}

	struct MarketData {
		address market;

		bool isExist;
		bool isActive;      

		uint256 borrowRate;
		uint256 supplyRate;

		uint256 suppliersShareRate;
		uint256 promotionRate;

		uint256 totalSupply;
		uint256 totalBorrow;

		uint256 supplyIndex;
		uint256 borrowIndex;

		uint256 price;
		uint256 priceDecimals;
	}

	struct CollateralData {
		address collateral;

		bool isExist;
		bool isActive;    

		uint256 valueToLoanRate; 
		uint256 penaltyRate;
		uint256 bonusRate;

		uint256 totalCollateral;
		uint256 totalLiquidatedCollateral;

		MarketDebtData[] marketDebt;

		uint256 price;
		uint256 priceDecimals;
	}

	struct OperationPauseStatus {
		string operation;
		bool pauseStatus;
	}

	struct MarketDebtData {
		address market;
		uint256 debt;
	}

	IHoldefi public holdefi;

	IHoldefiSettings public holdefiSettings;

	IHoldefiPrices public holdefiPrices;


	constructor(
		IHoldefi holdefiAddress,
		IHoldefiSettings holdefiSettingsAddress,
		IHoldefiPrices holdefiPricesAddress
	)
		public
	{
		holdefi = holdefiAddress;
		holdefiSettings = holdefiSettingsAddress;
		holdefiPrices = holdefiPricesAddress;
	}

	function getWalletBalance(address account, address asset) public view returns (uint256 res) {
		if (asset == ethAddress) {
			res = account.balance;
		}
		else {
			IERC20 token = IERC20(asset);
			res = token.balanceOf(account);
		}
	}

	function getWalletAllowance(address account, address asset) public view returns (uint256 res) {
		if (asset != ethAddress) {
			IERC20 token = IERC20(asset);
			res = token.allowance(account, address(holdefi));
		}
	}


	function getUserData(address userAddress, address[] memory marketList, address[] memory collateralList)
		public
		view
		returns(
			AccountMarketData[] memory userSupplies,
			AccountCollateralData[] memory userCollaterals,
			AccountAssetData[] memory userAssets
		)
	{
		userSupplies = new AccountMarketData[](marketList.length);
		userCollaterals = new AccountCollateralData[](collateralList.length);
		address[] memory assets = new address[](marketList.length + collateralList.length);

		bool isExist;
		uint256 index;
		uint256 i;
		uint256 j;
		for (i = 0 ; i < collateralList.length ; i++) {
			isExist = false;
			userCollaterals[i].collateral = collateralList[i];
			(
				userCollaterals[i].balance,
				userCollaterals[i].timeSinceLastActivity,
				userCollaterals[i].borrowPowerValue,
				userCollaterals[i].totalBorrowValue,
				userCollaterals[i].underCollateral
			) = holdefi.getAccountCollateral(userAddress, collateralList[i]);
			userCollaterals[i].userBorrows = new AccountMarketData[](marketList.length);
			for (j = 0 ; j < marketList.length ; j++) {
				if (i == 0) {
					userSupplies[j].market = marketList[j];
					(
						userSupplies[j].balance,
						userSupplies[j].interest,
						userSupplies[j].index
					) = holdefi.getAccountSupply(userAddress, marketList[j]);

					assets[j] = marketList[j];
					index = j + 1;
				}
				if (collateralList[i] == marketList[j]) {
					isExist = true;
				}

				userCollaterals[i].userBorrows[j].market = marketList[j];
				(
					userCollaterals[i].userBorrows[j].balance,
					userCollaterals[i].userBorrows[j].interest,
					userCollaterals[i].userBorrows[j].index
				) = holdefi.getAccountBorrow(userAddress, marketList[j], collateralList[i]);
				
			}

			if (!isExist) {
				assets[index] = collateralList[i];
				index = index + 1;
			}
		}

		userAssets = new AccountAssetData[](index);
		for (i = 0 ; i < index ; i++) {
			userAssets[i].asset = assets[i];
			(userAssets[i].price, userAssets[i].priceDecimals) = holdefiPrices.getPrice(assets[i]);
			userAssets[i].walletBalance = getWalletBalance(userAddress, assets[i]);
			userAssets[i].allowance = getWalletAllowance(userAddress, assets[i]);
		}
	}

	function getProtocolData(address[] memory marketList, address[] memory collateralList)
		public
		view
		returns(
			MarketData[] memory markets,
			CollateralData[] memory collaterals, 
			OperationPauseStatus[8] memory operations
		)
	{

		markets = new MarketData[](marketList.length);
		collaterals = new CollateralData[](collateralList.length);

		uint256 i;
		uint256 j;
		for (i = 0 ; i < marketList.length ; i++) {
			IHoldefi.Market memory holdefiMarket = holdefi.marketAssets(marketList[i]);

			markets[i].market = marketList[i];
			markets[i].totalSupply = holdefiMarket.totalSupply;
			markets[i].totalBorrow = holdefiMarket.totalBorrow;

			(
				markets[i].supplyIndex,
				markets[i].supplyRate,
			) = holdefi.getCurrentSupplyIndex(marketList[i]);


			(
				markets[i].borrowIndex,
				markets[i].borrowRate,
			) = holdefi.getCurrentBorrowIndex(marketList[i]);


			IHoldefiSettings.MarketSettings memory holdefiSettingsMarket = holdefiSettings.marketAssets(marketList[i]);
			markets[i].isExist = holdefiSettingsMarket.isExist;
			markets[i].isActive = holdefiSettingsMarket.isActive;
			markets[i].suppliersShareRate = holdefiSettingsMarket.suppliersShareRate;
			markets[i].promotionRate = holdefiSettingsMarket.promotionRate;

			(markets[i].price, markets[i].priceDecimals) = holdefiPrices.getPrice(marketList[i]);
		}

		for (i = 0 ; i < collateralList.length ; i++) {
			IHoldefi.Collateral memory holdefiCollateral = holdefi.collateralAssets(collateralList[i]);
			collaterals[i].collateral = collateralList[i];
			collaterals[i].totalCollateral = holdefiCollateral.totalCollateral;
			collaterals[i].totalLiquidatedCollateral = holdefiCollateral.totalLiquidatedCollateral;

			IHoldefiSettings.CollateralSettings memory holdefiSettingsCollateral = holdefiSettings.collateralAssets(collateralList[i]);
			collaterals[i].isExist = holdefiSettingsCollateral.isExist;
			collaterals[i].isActive = holdefiSettingsCollateral.isActive;
			collaterals[i].valueToLoanRate = holdefiSettingsCollateral.valueToLoanRate;
			collaterals[i].penaltyRate = holdefiSettingsCollateral.penaltyRate;
			collaterals[i].bonusRate = holdefiSettingsCollateral.bonusRate;

			(collaterals[i].price, collaterals[i].priceDecimals) = holdefiPrices.getPrice(collateralList[i]);

			collaterals[i].marketDebt = new MarketDebtData[](marketList.length);
			for (j = 0 ; j < marketList.length ; j++) {
				collaterals[i].marketDebt[j].market = marketList[j];
				collaterals[i].marketDebt[j].debt = holdefi.marketDebt(collateralList[i], marketList[j]);
			}
		}

		for (i = 0 ; i < operationsList.length ; i++) {
			operations[i].operation = operationsList[i];
			operations[i].pauseStatus = holdefi.isPaused(operationsList[i]);
		}
	}


	function getUserProtocolData(address userAddress, address[] memory marketList, address[] memory collateralList)
		public
		view
		returns(
			AccountMarketData[] memory userSupplies,
			AccountCollateralData[] memory userCollaterals,
			AccountAssetData[] memory userAssets,
			MarketData[] memory markets,
			CollateralData[] memory collaterals,
			OperationPauseStatus[8] memory operations
		)
	{
		(userSupplies, userCollaterals, userAssets) = getUserData(userAddress, marketList, collateralList);
		(markets, collaterals, operations) = getProtocolData(marketList, collateralList);
	}


	function getUserAssetsData(address userAddress, address[] memory marketList, address[] memory collateralList)
		public
		view
		returns(
			AccountAssetData[] memory userAssets
		)
	{
		address[] memory assets = new address[](marketList.length + collateralList.length);

		bool isExist;
		uint256 index;
		uint256 i;
		uint256 j;
		for (i = 0 ; i < collateralList.length ; i++) {
			isExist = false;
			for (j = 0 ; j < marketList.length ; j++) {
				if (i == 0) {
					assets[j] = marketList[j];
					index = j + 1;
				}

				if (collateralList[i] == marketList[j]) {
					isExist = true;
				}
			}

			if (!isExist) {
				assets[index] = collateralList[i];
				index = index + 1;
			}
		}

		userAssets = new AccountAssetData[](index);
		for (i = 0 ; i < index ; i++) {
			userAssets[i].asset = assets[i];
			(userAssets[i].price, userAssets[i].priceDecimals) = holdefiPrices.getPrice(assets[i]);
			userAssets[i].walletBalance = getWalletBalance(userAddress, assets[i]);
			userAssets[i].allowance = getWalletAllowance(userAddress, assets[i]);
		}
	}
}