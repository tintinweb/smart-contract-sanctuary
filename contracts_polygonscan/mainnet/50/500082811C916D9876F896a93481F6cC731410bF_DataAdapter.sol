// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IProtocolDataProvider.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IMemory.sol";
import "../interfaces/IComptroller.sol";

contract DataAdapter {
	using SafeMath for uint256;
	IProtocolDataProvider protocolData =
		IProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);
	IComptroller compTroller =
		IComptroller(0x20CA53E2395FA571798623F1cFBD11Fe2C114c24);
	ILendingPool lendingPool;
	IMemory memoryContract;

	/**
		@dev Struct for the user data in aave.
	**/
	struct UserDataAave {
		uint256 totalCollateralETH;
		uint256 totalDebtETH;
		uint256 availableBorrowsETH;
		uint256 currentLiquidationThreshold;
		uint256 ltv;
		uint256 healthFactor;
	}

	/**
		@dev Struct for the asset data in aave.
	**/
	struct AssetDataAave {
		uint256 availableLiquidity;
		uint256 totalVariableDebt;
		uint256 liquidityRate;
		uint256 variableBorrowRate;
		uint256 ltv;
		uint256 liquidationThreshold;
	}

	/**
		@dev Struct for the user data in aave.
	**/
	struct UserDataCream {
		uint256 totalCollateralETH;
		uint256 totalDebtETH;
		uint256 availableBorrowsETH;
		uint256 currentLiquidationThreshold;
		uint256 ltv;
		uint256 healthFactor;
	}

	/**
		@dev Struct for the asset data in cream.
	**/
	struct AssetDataCream {
		uint256 availableLiquidity;
		uint256 totalVariableDebt;
		uint256 liquidityRate;
		uint256 variableBorrowRate;
		uint256 liquidationThreshold;
		uint256 ltv;
	}

	/**
		@dev Struct for the all the information of the asset in both protocols.
	**/
	struct DataAssetOfProtocols {
		AssetDataAave dataAssetAave;
		AssetDataCream dataAssetCream;
	}

	/**
		@dev Struct for the all the information of the user in both protocols.
	**/
	struct DataUserOfProtocols {
		UserDataAave dataUserAave;
		UserDataCream dataUserCream;
	}

	constructor(ILendingPool _lendingPool, IMemory _memoryContract) {
		lendingPool = _lendingPool;
		memoryContract = _memoryContract;
	}

	/**
		@dev Get all the data from a lendingPool for a
		specific user.
		@param _user the user that we want to get the data.
	**/
	function getDataForUserAave(address _user)
		public
		view
		returns (UserDataAave memory data)
	{
		(
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		) = lendingPool.getUserAccountData(_user);

		data = UserDataAave(
			totalCollateralETH,
			totalDebtETH,
			availableBorrowsETH,
			currentLiquidationThreshold,
			ltv,
			healthFactor
		);
	}

	/**
		@dev Get all the data from a lendingPool for a
		specific asset.
		@param _asset the asset that we want to get the data.
	**/
	function getDataForAssetAave(address _asset)
		public
		view
		returns (AssetDataAave memory data)
	{
		(
			uint256 availableLiquidity,
			,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate,
			,
			,
			,
			,

		) = protocolData.getReserveData(_asset);

		(
			,
			uint256 ltv,
			uint256 liquidationThreshold,
			,
			,
			,
			,
			,
			,

		) = protocolData.getReserveConfigurationData(_asset);

		data = AssetDataAave(
			availableLiquidity,
			totalVariableDebt,
			liquidityRate,
			variableBorrowRate,
			ltv,
			liquidationThreshold
		);
	}

	/**
		@dev Get all the data from a lendingPool for a
		specific user.
		@param _user the user that we want to get the data.
	**/
	function getDataForUserCream(address _user)
		public
		view
		returns (UserDataCream memory data)
	{
		address[] memory assetsIn = compTroller.getAssetsIn(_user);
		uint256 totalSupplyETH;
		uint256 totalDebtETH;
		uint256 ltv;

		for (uint256 tokenIndex; tokenIndex < assetsIn.length; tokenIndex++) {
			ICToken crToken = ICToken(
				memoryContract.getCrToken(assetsIn[tokenIndex])
			);
			totalSupplyETH += crToken.balanceOf(_user);
			totalDebtETH += crToken.borrowBalanceStored(_user);
		}

		if (totalDebtETH != 0) {
			ltv = totalDebtETH.div(totalSupplyETH);
		}

		(, uint256 availableBorrowsETH, ) = compTroller.getAccountLiquidity(
			_user
		);

		data = UserDataCream(
			totalSupplyETH,
			totalDebtETH,
			availableBorrowsETH,
			0,
			ltv,
			0
		);
	}

	/**
		@dev Get all the data from a CToken for a
		specific asset.
		@param _asset the asset that we want to get the data.
	**/
	function getDataForAssetCream(address _asset)
		public
		view
		returns (AssetDataCream memory data)
	{
		ICToken crAsset = ICToken(memoryContract.getCrToken(_asset));
		uint256 availableLiquidity = crAsset.getCash();
		uint256 totalVariableDebt = crAsset.totalBorrows();
		uint256 liquidityRate = crAsset.supplyRatePerBlock();
		uint256 variableBorrowRate = crAsset.borrowRatePerBlock();
		(, uint256 collateralFactor, ) = compTroller.markets(address(crAsset));

		data = AssetDataCream(
			availableLiquidity,
			totalVariableDebt,
			liquidityRate,
			variableBorrowRate,
			0,
			collateralFactor
		);
	}

	/**
		@dev Get the general data of both protocols for the _asset.
		@param _asset asset to get the data from both protocols.
	**/
	function getDataAssetOfProtocols(address _asset)
		public
		view
		returns (DataAssetOfProtocols memory data)
	{
		data = DataAssetOfProtocols(
			getDataForAssetAave(_asset),
			getDataForAssetCream(_asset)
		);
	}

	/**
		@dev Get the general data of both protocols for the _user.
		@param _user user to get the data from both protocols.
	**/
	function getDataUserOfProtocols(address _user)
		public
		view
		returns (DataUserOfProtocols memory data)
	{
		data = DataUserOfProtocols(
			getDataForUserAave(_user),
			getDataForUserCream(_user)
		);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
	function redeem(uint256 redeemTokens) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral
	) external returns (uint256);

	function liquidateBorrow(address borrower, address cTokenCollateral)
		external
		payable;

	function exchangeRateCurrent() external returns (uint256);

	function getCash() external view returns (uint256);

	function borrowRatePerBlock() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function reserveFactorMantissa() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function borrowBalanceStored(address owner)
		external
		view
		returns (uint256 balance);

	function allowance(address, address) external view returns (uint256);

	function approve(address, uint256) external;

	function transfer(address, uint256) external returns (bool);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function getAccountSnapshot(address)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
	function enterMarkets(address[] calldata cTokens)
		external
		returns (uint256[] memory);

	function exitMarket(address cTokenAddress) external returns (uint256);

	function getAssetsIn(address account)
		external
		view
		returns (address[] memory);

	function getAccountLiquidity(address account)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function markets(address cTokenAddress)
		external
		view
		returns (
			bool,
			uint256,
			uint8
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPool {
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMemory {
	function getUint(uint256) external view returns (uint256);

	function setUint(uint256 id, uint256 value) external;

	function getAToken(address asset) external view returns (address);

	function setAToken(address asset, address _aToken) external;

	function getCrToken(address asset) external view returns (address);

	function setCrToken(address asset, address _crToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
	struct TokenData {
		string symbol;
		address tokenAddress;
	}

	function ADDRESSES_PROVIDER()
		external
		view
		returns (ILendingPoolAddressesProvider);

	function getAllReservesTokens() external view returns (TokenData[] memory);

	function getAllATokens() external view returns (TokenData[] memory);

	function getReserveConfigurationData(address asset)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		);

	function getReserveData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate,
			uint256 stableBorrowRate,
			uint256 averageStableBorrowRate,
			uint256 liquidityIndex,
			uint256 variableBorrowIndex,
			uint40 lastUpdateTimestamp
		);

	function getUserReserveData(address asset, address user)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);

	function getReserveTokensAddresses(address asset)
		external
		view
		returns (
			address aTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);
}