pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

pragma solidity ^0.8.0;

import "../common/interfaces/IERC20.sol";

contract Converter {
    
    function convert(address tokenIn, uint amount, address tokenOut) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenOut).transfer(msg.sender, amount);
    }
}

pragma solidity ^0.8.0;
import "../future-exchange/libraries/SafeMath.sol";
import "./interfaces/ILending.sol";
import "./interfaces/IAaveLendingPool.sol";
import "./interfaces/IAaveAddressesProvider.sol";
import "./interfaces/IAavePriceOracle.sol";
import "./interfaces/DataTypes.sol";
import "./interfaces/ICompoundComptroller.sol";
import "./interfaces/ICompoundErc20.sol";
import "./interfaces/ICompoundPriceOracle.sol";
import "./libraries/WadRayMath.sol";
import "../common/interfaces/IERC20.sol";
import "./Converter.sol";

contract Lending is ILending {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    address public admin;
    address public provider;

    address public usdc;
    address public dai;
    address public usdcAAVE;
    address public daiAAVE;
    address public converter;

    uint public compoundBorrowLimitPercent = 80;

    IAaveLendingPool public aaveLendingPool;
    ICompoundComptroller public compoundComptroller;
    mapping (address => ICompoundErc20) public compoundErc20;

    bool public flagAAVE = true;
    bool public flagCompound = true;

    struct AAVEInfo {
        uint collateral;
        uint borrowedAmount;
        uint liquidationThreshold;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "LENDING: Not admin address");
        _;
    }

    modifier onlyProvider() {
        require(msg.sender == provider, "LENDING: Not provider address");
        _;
    }

    constructor(address _admin, address _provider) {
        provider = _provider;
        admin = _admin;
    }

    function initiate(
        address _usdc,
        address _dai,
        address _usdcAAVE,
        address _daiAAVE,
        address _aaveLendingPool,
        address _compoundComptroller,
        address _compoundUsdc,
        address _compoundDai
    ) external onlyAdmin {
        aaveLendingPool = IAaveLendingPool(_aaveLendingPool); // kovan 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe
        compoundComptroller = ICompoundComptroller(_compoundComptroller); // kovan 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb
        compoundErc20[_usdc] = ICompoundErc20(_compoundUsdc); // kovan 0x4a92e71227d294f041bd82dd8f78591b75140d63
        compoundErc20[_dai] = ICompoundErc20(_compoundDai); // kovan 0x3f0a0ea2f86bae6362cf9799b523ba06647da018
        usdc = _usdc;
        dai = _dai;
        usdcAAVE = _usdcAAVE;
        daiAAVE = _daiAAVE;

        IERC20(_usdc).approve(_compoundUsdc, type(uint).max);
        IERC20(_dai).approve(_compoundDai, type(uint).max);
        IERC20(_usdcAAVE).approve(_aaveLendingPool, type(uint).max);
        IERC20(_daiAAVE).approve(_aaveLendingPool, type(uint).max);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setConverter(address _converter) external onlyAdmin {
        converter = _converter;
        IERC20(usdc).approve(_converter, type(uint).max);
        IERC20(dai).approve(_converter, type(uint).max);
        IERC20(usdcAAVE).approve(_converter, type(uint).max);
        IERC20(daiAAVE).approve(_converter, type(uint).max);
    }

    function setProvider(address _provider) external onlyAdmin {
        provider = _provider;
    }

    function setcompoundBorrowLimitPercent(uint _limit) external onlyAdmin {
        compoundBorrowLimitPercent = _limit;
    }

    function setStatusFlag(uint index, bool value) external onlyAdmin {
        if (index == 1) flagAAVE = value;
        if (index == 2) flagCompound = value;
    }

    function getLendingPlatforms(uint256 index) override external view returns (address) {
        if (index == 1) return address(aaveLendingPool);
        if (index == 2) return address(compoundComptroller);
        return address(0);
    }

    function lendingPlatformsCount() override public pure returns (uint) {
        return 2;
    }

    function createLoan(uint platformIndex, address borrowToken, uint borrowAmount) external override{
        require(borrowToken != address(0), "LENDING: Invalid borrow token!");
        if (platformIndex == 1) {
            require(flagAAVE == true, "LENDING: Lending platform not available");
            uint availableAmount = this.getBorrowableAmount(1, borrowToken);
            require (borrowAmount <= availableAmount, "LENDING: Borrow more than collateral");

            if (borrowToken == usdc && converter != address(0)) {
                aaveLendingPool.borrow(usdcAAVE, borrowAmount, 1, 0, address(this));
                Converter(converter).convert(usdcAAVE, borrowAmount, usdc);
            } else {
                require(borrowToken == daiAAVE || borrowToken == usdcAAVE, "Lending: Invalid borrow token!");
                aaveLendingPool.borrow(borrowToken, borrowAmount, 1, 0, address(this));
            }
        }
        else if (platformIndex == 2) {
            require(flagCompound == true, "LENDING: Lending platform not available");
            require(address(compoundErc20[borrowToken]) != address(0), "Lending: Invalid borrow token!");

            uint availableBorrowAmount = _getCompoundAvailableBorrowAmount(borrowToken, true);
            require(borrowAmount <= availableBorrowAmount * compoundBorrowLimitPercent / 100, "LENDING: Borrow more than collateral");
            compoundErc20[borrowToken].borrow(borrowAmount);
        }
        else revert("LENDING: Invalid Lending Platform index");
        IERC20(borrowToken).transfer(msg.sender, borrowAmount);
    }

    function repayLoan(uint platformIndex, address borrowToken, uint repayAmount) override external {
        require(borrowToken != address(0), "LENDING: Invalid borrow token!");
        IERC20(borrowToken).transferFrom(msg.sender, address(this), repayAmount);
        if (platformIndex == 1) {
            require(flagAAVE == true, "LENDING: Lending platform not available");
            uint borrowedAmount = this.getLendingPlatformBorrow(1, borrowToken);
            require (repayAmount <= borrowedAmount, "Lending: Repay more than allowed!");
            require (repayAmount != 0, "Lending: Repay a certain amount!");
            if (borrowToken == usdc && converter != address(0)) {
                Converter(converter).convert(usdc, repayAmount, usdcAAVE);
                aaveLendingPool.repay(usdcAAVE, repayAmount, 1, address(this));
            } else {
                require(borrowToken == daiAAVE || borrowToken == usdcAAVE, "Lending: Invalid borrow token!");
                aaveLendingPool.repay(borrowToken, repayAmount, 1, address(this));
            }
        }
        else if (platformIndex == 2) {
            require(flagCompound == true, "LENDING: Lending platform not available");
            require(address(compoundErc20[borrowToken]) != address(0), "Lending: Invalid borrow token!");
            uint borrowedAmount = this.getLendingPlatformBorrow(2, borrowToken);
            require (repayAmount <= borrowedAmount, "Lending: Repay more than allowed!");
            require (repayAmount != 0, "Lending: Repay a certain amount!");
            compoundErc20[borrowToken].repayBorrow(repayAmount);
        }
        else revert("LENDING: Invalid Lending Platform index");
    }

    function getBorrowableAmount(uint platformIndex, address borrowToken) override external view returns (uint availableBorrowAmount) {
        if (platformIndex == 1) {
            if (!flagAAVE) return 0;
            if (borrowToken != daiAAVE && borrowToken != usdcAAVE) {
                if (borrowToken == usdc && converter != address(0)) {
                    borrowToken = usdcAAVE;
                } else {
                    return 0;
                }
            }

            AAVEInfo memory infor;
            (uint collateralETH, uint borrowedAmountETH,, uint liquidationThreshold,,uint healthFactorETH) = aaveLendingPool.getUserAccountData(address(this));

            IAaveAddressesProvider addressesProvider = aaveLendingPool.getAddressesProvider();
            IAavePriceOracle oracle = addressesProvider.getPriceOracle();
            uint priceReserveETH = oracle.getAssetPrice(borrowToken);

            DataTypes.ReserveConfigurationMap memory reserveConfig = aaveLendingPool.getConfiguration(borrowToken);
            uint decimalReserve = (reserveConfig.data % (2 ** 55)) >> (48);

            infor.collateral = collateralETH * (10 ** decimalReserve)/ priceReserveETH;
            uint healthFactor = healthFactorETH / (10 ** 17);
            if(borrowedAmountETH > 0) {
                if(healthFactor <= 15) {
                    return 0;
                }
                else {
                    uint sumBorrowAmountETH = (collateralETH * liquidationThreshold) / 15000;
                    availableBorrowAmount = (sumBorrowAmountETH - borrowedAmountETH) * (10 ** decimalReserve) / priceReserveETH;
                }
            } else {
                availableBorrowAmount = (infor.collateral * liquidationThreshold) / 15000;
            }
        }
        if (platformIndex == 2) {
            if (!flagCompound) return 0;
            if (address(compoundErc20[borrowToken]) == address(0)) return 0;

            return _getCompoundAvailableBorrowAmount(borrowToken, false) * compoundBorrowLimitPercent / 100;
        }
    }

    function getDebtAmount(
        uint256 platformIndex,
        address borrowToken,
        uint256 borrowAmount,
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) override external view returns(uint debtAmount) {
        if (platformIndex == 1) {
            if (!flagAAVE) return 0;
            if (borrowToken != daiAAVE && borrowToken != usdcAAVE) {
                if (borrowToken == usdc && converter != address(0)) {
                    borrowToken = usdcAAVE;
                } else {
                    return 0;
                }
            }

            DataTypes.ReserveData memory reserveData = aaveLendingPool.getReserveData(borrowToken);
            uint interestRateAAVE = reserveData.currentStableBorrowRate;
            uint interestAAVE = this.calculateCompoundedInterest(interestRateAAVE, fromTimestamp, toTimestamp);
            debtAmount = (interestAAVE * borrowAmount) / 10 ** 27;
        }
        if (platformIndex == 2) {
            if (!flagCompound) return 0;
            if (address(compoundErc20[borrowToken]) == address(0)) return 0;

            uint blockNumber = (toTimestamp - fromTimestamp) / 13; // estimate block time = 13
            uint interestRate = compoundErc20[borrowToken].borrowRatePerBlock() * blockNumber;
            debtAmount =  borrowAmount + borrowAmount * interestRate / (10 ** 18);
        }
    }

    function calculateCompoundedInterest(
        uint256 rate,
        uint256 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) external pure returns (uint256) {
        uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

        if (exp == 0) {
          return WadRayMath.ray();
        }

        uint256 expMinusOne = exp - 1;

        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

        uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
        uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

        uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
        uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

        return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
    }

    function sendCollateral(uint platformIndex, address collateralToken, uint256 amount) external override onlyProvider {
        require(collateralToken != address(0), "LENDING: Invalid borrow token!");

        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        if (platformIndex == 1) {
            require(flagAAVE == true, "LENDING: Lending platform not available");
            require(collateralToken == daiAAVE, "LENDING: Invalid borrow token!");

            aaveLendingPool.deposit(collateralToken, amount, address(this), 0);
            aaveLendingPool.setUserUseReserveAsCollateral(collateralToken, true);
        }
        else if (platformIndex == 2) {
            require(flagCompound == true, "LENDING: Lending platform not available");
            require(address(compoundErc20[collateralToken]) != address(0), "LENDING: Invalid borrow token!");
            compoundErc20[collateralToken].mint(amount);

            address[] memory cTokens = new address[](1);
            cTokens[0] = address(compoundErc20[collateralToken]);
            uint256[] memory errors = compoundComptroller.enterMarkets(cTokens);
            require (errors[0] == 0, "COMPOUND: Enter market failed.");
        }
        else revert("LENDING: Invalid Lending Platform index");
    }

    function withdrawCollateral(uint platformIndex, address collateralToken, uint256 amount) external override onlyProvider {
        require(collateralToken != address(0), "Lending: Invalid borrow token!");

        if (platformIndex == 1) {
            require(flagAAVE == true, "LENDING: Lending platform not available");
            require(collateralToken == daiAAVE, "LENDING: Invalid borrow token!");

            (, uint borrowedAmountETH,,,,) = aaveLendingPool.getUserAccountData(address(this));
            (, uint withdrawAmount) = this.getLendingPlatformCollateral(1, collateralToken);
            require( amount <= withdrawAmount, "LENDING: COLLATERAL_NOT_ENOUGH");

            if (borrowedAmountETH > 0){
                aaveLendingPool.withdraw(collateralToken, amount, msg.sender);
            } else {
                aaveLendingPool.withdraw(collateralToken, amount, msg.sender);
            }
        }
        else if (platformIndex == 2) {
            require(flagCompound == true, "LENDING: Lending platform not available");
            require(address(compoundErc20[collateralToken]) != address(0), "Lending: Invalid borrow token!");

            uint error = compoundErc20[collateralToken].redeemUnderlying(amount);
            (, uint withdrawAmount) = this.getLendingPlatformCollateral(2, collateralToken);
            require(error == 0, "COMPOUND: Don't have enough balance/liquidity to withdraw");
            require(amount <= withdrawAmount, "LENDING: COLLATERAL_NOT_ENOUGH");
            IERC20(collateralToken).transfer(msg.sender, amount);
        }
        else revert("LENDING: Invalid Lending Platform index");

    }

    function _getCompoundAvailableBorrowAmount(address borrowToken, bool throwError) internal view returns(uint) {
        (uint error, uint liquidity, uint shortfall) = compoundComptroller.getAccountLiquidity(address(this));
        if (throwError) {
            require(error == 0, "COMPOUND: Get liquidity error");
            require(shortfall == 0, "COMPOUND: Account liquidity have low collateral");
        } else {
            if (error != 0 || shortfall != 0) return 0;
        }

        ICompoundPriceOracle oracle = compoundComptroller.oracle();
        uint underlyingPrice = oracle.getUnderlyingPrice(address(compoundErc20[borrowToken]));
        return liquidity * (10 ** 18) / underlyingPrice;
    }

    function getLendingPlatformCollateral(uint platformIndex, address collateralToken)
        override
        external
        returns (uint collateralAmount, uint withdrawableAmount)
	{
        require(collateralToken != address(0), "LENDING: Invalid borrow token!");
        if (platformIndex == 1) {
            if (!flagAAVE) return (0, 0);
            if (collateralToken != daiAAVE && collateralToken != usdcAAVE) {
                if (collateralToken == dai && converter != address(0)) {
                    collateralToken = daiAAVE;
                } else {
                    return (0, 0);
                }
            }

            (uint collateralETH, uint borrowedAmountETH,, uint liquidationThreshold,,) = aaveLendingPool.getUserAccountData(address(this));
            IAaveAddressesProvider addressesProvider = aaveLendingPool.getAddressesProvider();
            IAavePriceOracle oracle = addressesProvider.getPriceOracle();
            uint priceReserveETH = oracle.getAssetPrice(collateralToken);
            DataTypes.ReserveConfigurationMap memory reserveConfig = aaveLendingPool.getConfiguration(collateralToken);
            uint decimalReserve = (reserveConfig.data % (2 ** 55)) >> (48);

            collateralAmount = collateralETH * (10 ** decimalReserve)/ priceReserveETH;
            if (borrowedAmountETH > 0) {
                uint withdrawableAmountETH = collateralETH - (15000 * borrowedAmountETH / liquidationThreshold);
                withdrawableAmount = withdrawableAmountETH * (10 ** decimalReserve) / priceReserveETH;
            } else {
                withdrawableAmount = collateralAmount;
            }
        }
        else if (platformIndex == 2) {
            if (!flagCompound) return (0, 0);
            if (address(compoundErc20[collateralToken]) == address(0)) return (0, 0);

            collateralAmount = compoundErc20[collateralToken].balanceOfUnderlying(address(this));
            uint liquidity = _getCompoundAvailableBorrowAmount(collateralToken, false);
            if (liquidity > 0 && collateralAmount > 0) {
                (,uint factor,) = compoundComptroller.markets(address(compoundErc20[collateralToken]));
                withdrawableAmount = liquidity * 10 ** 18 / factor;
            } else {
                withdrawableAmount = collateralAmount;
            }
        }
    }

    function getLendingPlatformBorrow(uint platformIndex, address borrowToken)
        override
        external
        returns (uint borrowedAmount)
	{
	    require(borrowToken != address(0), "LENDING: Invalid borrow token!");
	    if (platformIndex == 1) {
            if (!flagAAVE) return (0);
            if (borrowToken != daiAAVE && borrowToken != usdcAAVE) {
                if (borrowToken == usdc && converter != address(0)) {
                    borrowToken = usdcAAVE;
                } else {
                    return 0;
                }
            }

            (, uint borrowedAmountETH,,,,) = aaveLendingPool.getUserAccountData(address(this));
            IAaveAddressesProvider addressesProvider = aaveLendingPool.getAddressesProvider();
            IAavePriceOracle oracle = addressesProvider.getPriceOracle();
            uint priceReserveETH = oracle.getAssetPrice(borrowToken);
            DataTypes.ReserveConfigurationMap memory reserveConfig = aaveLendingPool.getConfiguration(borrowToken);
            uint decimalReserve = (reserveConfig.data % (2 ** 55)) >> (48);
            borrowedAmount = borrowedAmountETH * (10 ** decimalReserve)/ priceReserveETH;
	    }
	    else if (platformIndex == 2) {
            if (!flagCompound) return (0);
            if (address(compoundErc20[borrowToken]) == address(0)) return (0);
            borrowedAmount = compoundErc20[borrowToken].borrowBalanceCurrent(address(this));
	    }
	}
}

pragma solidity ^0.8.0;

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
  
  struct BorrowInfo{
    uint256 platformIndex;
    uint256 borrowedAmount;
    uint256 interestRate;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

pragma solidity ^0.8.0;

import "./IAavePriceOracle.sol";

interface IAaveAddressesProvider {

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

  function getPriceOracle() external view returns (IAavePriceOracle);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IAaveAddressesProvider} from "./IAaveAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

interface IAaveLendingPool {

  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

  function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  function rebalanceStableBorrowRate(address asset, address user) external;

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

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

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (IAaveAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IAavePriceOracle {

    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns(address);

    function getFallbackOracle() external view returns(address);
}

pragma solidity ^0.8.0;

import "./ICompoundPriceOracle.sol";

interface ICompoundComptroller {
    function markets(address) external view returns (bool, uint256, bool);

    function oracle() external view returns (ICompoundPriceOracle);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (uint256, uint256, uint256);
}

pragma solidity ^0.8.0;

interface ICompoundErc20 {
    function borrowRatePerBlock() external view returns (uint256);
    function borrow(uint amount) external;
    function repayBorrow(uint256 amount) external;
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address account) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function mint(uint mintAmount) external returns (uint);
}

pragma solidity ^0.8.0;

interface ICompoundPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

pragma solidity ^0.8.0;

interface ILending {
    function sendCollateral(uint platformIndex, address borrowToken, uint256 amount) external;
    function withdrawCollateral(uint platformIndex, address borrowToken, uint256 amount) external;
    function getLendingPlatformCollateral(uint platformIndex, address borrowToken) external returns (uint, uint);
    function getLendingPlatformBorrow(uint platformIndex, address borrowToken) external returns (uint);
    function getLendingPlatforms(uint platformIndex) external view returns (address);
    function lendingPlatformsCount() external view returns (uint);
    
    function getBorrowableAmount(uint platformIndex, address borrowToken) external view returns (uint);
    function getDebtAmount(
        uint256 platformIndex, 
        address borrowToken,
        uint256 borrowAmount,
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) external view returns(uint);
    
    function createLoan(uint platformIndex, address borrowToken, uint borrowAmount) external;
    function repayLoan(uint platformIndex, address borrowToken, uint repayAmount) external;
}

pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfWAD) / b, "Errors.MATH_MULTIPLICATION_OVERFLOW");

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Errors.MATH_DIVISION_BY_ZERO");
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, "Errors.MATH_MULTIPLICATION_OVERFLOW");

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, "Errors.MATH_MULTIPLICATION_OVERFLOW");

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Errors.MATH_DIVISION_BY_ZERO");
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, "Errors.MATH_MULTIPLICATION_OVERFLOW");

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, "Errors.MATH_ADDITION_OVERFLOW");

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, "Errors.MATH_MULTIPLICATION_OVERFLOW");
    return result;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}