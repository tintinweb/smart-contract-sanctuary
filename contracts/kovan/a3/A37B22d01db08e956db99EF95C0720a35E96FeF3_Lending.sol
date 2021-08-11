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
import "./interfaces/ILending.sol";
import "./interfaces/IAaveLendingPool.sol";
import "./interfaces/IAaveAddressesProvider.sol";
import "./interfaces/IAavePriceOracle.sol";
import "./interfaces/DataTypes.sol";
import "./interfaces/ICompoundComptroller.sol";
import "./interfaces/ICompoundErc20.sol";
import "./interfaces/ICompoundPriceOracle.sol";
import "../common/interfaces/IERC20.sol";

contract Lending is ILending {

    address public adminAddress;
    address PrecogV2;
    address public usdc;
    IAaveLendingPool public aaveLendingPool;    
    ICompoundComptroller public compoundComptroller;
    mapping (address => ICompoundErc20) public compoundErc20;

    struct AAVEInfo {
        uint collateral;
        uint borrowedAmount;
        uint liquidationThreshold;
    }
    
    modifier onlyAdminAddress() {
        require(msg.sender == adminAddress, "Lending: NOT_ADMIN_ADDRESS");
        _;
    }
    constructor(
        address _usdc,
        address _aaveLendingPool, 
        address _compoundComptroller,
        address _compoundUsdc,
        address _adminAddress
    ) {
        aaveLendingPool = IAaveLendingPool(_aaveLendingPool); // kovan 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe
        compoundComptroller = ICompoundComptroller(_compoundComptroller); // kovan 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb
        compoundErc20[_usdc] = ICompoundErc20(_compoundUsdc); // kovan 0x4a92e71227d294f041bd82dd8f78591b75140d63
        usdc = _usdc;
        adminAddress = _adminAddress;
    }
    
    function getLendingPlatforms(uint256 index) override external view returns (address) {
        if (index == 1) return address(aaveLendingPool);
        if (index == 2) return address(compoundComptroller);
        return address(0);
    }

    function lendingPlatformsCount() override public pure returns (uint) {
        return 2;
    }

    function sendCollateral(uint platformIndex, address asset, uint256 amount) external override onlyAdminAddress {
        require(asset != usdc, "Lending: cannot use USDC as collateral!");
        if (platformIndex == 1) {
            IERC20(asset).approve(address(aaveLendingPool), type(uint256).max);
            aaveLendingPool.deposit(asset, amount, address(this), 0);
        }
        if (platformIndex == 2) {
            IERC20(asset).approve(address(compoundErc20[asset]), type(uint256).max);
            compoundErc20[asset].mint(amount);
        }
        revert("LENDING: Invalid Lending Platform index");
    }

    function createLoan(uint platformIndex, address borrowToken, uint borrowAmount) external override{
        if (platformIndex == 1) {
            aaveLendingPool.setUserUseReserveAsCollateral(borrowToken, true);
            aaveLendingPool.borrow(borrowToken, borrowAmount, 1, 0, address(this));
        }
        if (platformIndex == 2) {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(borrowToken);
            uint256[] memory errors = compoundComptroller.enterMarkets(cTokens);
            if (errors[0] != 0) {
                revert("Comptroller.enterMarkets failed.");
            }
            compoundErc20[borrowToken].borrow(borrowAmount);
        }
        revert("LENDING: Invalid Lending Platform index");
    }

    function repayLoan(uint platformIndex, address borrowToken, uint repayAmount) override external {
        if (platformIndex == 1) {
            aaveLendingPool.repay(borrowToken, repayAmount, 1, address(this));
        }
        if (platformIndex == 2) {
            compoundErc20[borrowToken].repayBorrow(repayAmount);
        }
        revert("LENDING: Invalid Lending Platform index");
    }
    
    function getLendingPlatformInfo(uint platformIndex, address borrowToken) 
        override
        public 
        view
        returns (uint availableBorrowAmount, uint interestRate)
	{  
        if (platformIndex == 1) {
            DataTypes.ReserveData memory reserveData = aaveLendingPool.getReserveData(borrowToken);
            interestRate = reserveData.currentStableBorrowRate;

            (,,uint availableBorrowAmountETH,,,) = aaveLendingPool.getUserAccountData(msg.sender);
            IAaveAddressesProvider addressesProvider = aaveLendingPool.getAddressesProvider();
            IAavePriceOracle oracle = addressesProvider.getPriceOracle();
            uint priceReserveETH = oracle.getAssetPrice(borrowToken);
            DataTypes.ReserveConfigurationMap memory reserveConfig = aaveLendingPool.getConfiguration(borrowToken);
            uint decimalReserve = reserveConfig.data & (48 << 55);
            availableBorrowAmount = (availableBorrowAmountETH / priceReserveETH) * (10 ** decimalReserve);
        }
        if (platformIndex == 2) {
            ICompoundPriceOracle oracle = compoundComptroller.oracle();
            
            (uint error, uint liquidity, uint shortfall) = compoundComptroller.getAccountLiquidity(msg.sender);
            if (error != 0) {
                revert("Comptroller.getAccountLiquidity failed.");
            }
            require(shortfall == 0, "account underwater");
            require(liquidity > 0, "account has excess collateral");
            
            uint underlyingPrice = oracle.getUnderlyingPrice(borrowToken);
            availableBorrowAmount = liquidity / underlyingPrice;  //need to check decimal
            interestRate = compoundErc20[borrowToken].borrowRatePerBlock();             
        }
        revert("LENDING: Invalid Lending Platform index");
    }

    function withdrawCollateralFromLendingPlatform(uint platformIndex, uint256 amount, address borrowToken) external override onlyAdminAddress {
        if (platformIndex == 1) {
            AAVEInfo memory infor;
            (uint collateralETH, uint borrowedAmountETH,, uint currentLiquidationThreshold,,) = aaveLendingPool.getUserAccountData(address(this));
            IAaveAddressesProvider addressesProvider = aaveLendingPool.getAddressesProvider();
            IAavePriceOracle oracle = addressesProvider.getPriceOracle();
            uint priceReserveETH = oracle.getAssetPrice(borrowToken);
            DataTypes.ReserveConfigurationMap memory reserveConfig = aaveLendingPool.getConfiguration(borrowToken);
            uint decimalReserve = reserveConfig.data & (48 << 55);

            infor.collateral = (collateralETH / priceReserveETH) * (10 ** decimalReserve);
            infor.borrowedAmount = ( borrowedAmountETH / priceReserveETH) * (10 ** decimalReserve);
            infor.liquidationThreshold = (currentLiquidationThreshold / priceReserveETH) * (10 ** decimalReserve);
            require((infor.collateral - amount) * infor.liquidationThreshold / infor.borrowedAmount > 2 , "LENDING: COLLATERAL_NOT_ENOUGH");
            IAaveLendingPool(address(aaveLendingPool)).withdraw(borrowToken, amount, msg.sender);
        }
        if (platformIndex == 2) {
            (uint error, uint liquidity, uint shortfall) = compoundComptroller.getAccountLiquidity(msg.sender);
            if (error != 0) {
                revert("Comptroller.getAccountLiquidity failed.");
            }
            require(shortfall == 0, "account underwater");
            require(liquidity > 0, "account has excess collateral");
            
            ICompoundPriceOracle oracle = compoundComptroller.oracle();
            uint availableWithdrawAmount = liquidity / oracle.getUnderlyingPrice(borrowToken);
            require(amount < availableWithdrawAmount, "LENDING: COLLATERAL_NOT_ENOUGH");
            compoundErc20[borrowToken].redeemUnderlying(amount);
        }
        revert("LENDING: Invalid Lending Platform index");
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

pragma solidity 0.8.0;

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
    function markets(address) external returns (bool, uint256);

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
    function mint(uint mintAmount) external returns (uint);
}

pragma solidity 0.8.0;

interface ICompoundPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

pragma solidity ^0.8.0;

interface ILending {
    function sendCollateral(uint platformIndex, address asset, uint256 amount) external;
    function createLoan(uint platformIndex, address borrowToken, uint borrowAmount) external;
    function withdrawCollateralFromLendingPlatform(uint platformIndex, uint256 amount, address borrowToken) external;
    function getLendingPlatforms(uint platformIndex) external view returns (address);
    function lendingPlatformsCount() external view returns (uint);
    function getLendingPlatformInfo(uint platformIndex, address loanToken) external view returns (uint, uint);
    function repayLoan(uint platformIndex, address borrowToken, uint repayAmount) external;
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