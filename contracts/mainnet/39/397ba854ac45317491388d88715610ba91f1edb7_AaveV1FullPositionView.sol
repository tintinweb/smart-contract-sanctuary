/**
 *Submitted for verification at Etherscan.io on 2020-12-24
*/

pragma solidity ^0.7.0;    
pragma experimental ABIEncoderV2;



contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}    


abstract contract IFlashLoanParamsGetter {
	function getFlashLoanParams(bytes memory _data) public view virtual returns (address[] memory tokens, uint256[] memory amount, uint256[] memory modes);
}    



abstract contract ILendingPoolAddressesProvider {
    function getLendingPool() public view virtual returns (address);

    function setLendingPoolImpl(address _pool) public virtual;

    function getLendingPoolCore() public view virtual returns (address payable);

    function setLendingPoolCoreImpl(address _lendingPoolCore) public virtual;

    function getLendingPoolConfigurator() public view virtual returns (address);

    function setLendingPoolConfiguratorImpl(address _configurator) public virtual;

    function getLendingPoolDataProvider() public view virtual returns (address);

    function setLendingPoolDataProviderImpl(address _provider) public virtual;

    function getLendingPoolParametersProvider() public view virtual returns (address);

    function setLendingPoolParametersProviderImpl(address _parametersProvider) public virtual;

    function getTokenDistributor() public view virtual returns (address);

    function setTokenDistributor(address _tokenDistributor) public virtual;

    function getFeeProvider() public view virtual returns (address);

    function setFeeProviderImpl(address _feeProvider) public virtual;

    function getLendingPoolLiquidationManager() public view virtual returns (address);

    function setLendingPoolLiquidationManager(address _manager) public virtual;

    function getLendingPoolManager() public view virtual returns (address);

    function setLendingPoolManager(address _lendingPoolManager) public virtual;

    function getPriceOracle() public view virtual returns (address);

    function setPriceOracle(address _priceOracle) public virtual;

    function getLendingRateOracle() public view virtual returns (address);

    function setLendingRateOracle(address _lendingRateOracle) public virtual;
}

library EthAddressLib {
    function ethAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}    


abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external virtual payable;
	function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external virtual;
	function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external virtual;
	function repay( address _reserve, uint256 _amount, address payable _onBehalfOf) external virtual payable;
	function swapBorrowRateMode(address _reserve) external virtual;
    function getReserves() external virtual view returns(address[] memory);

    /// @param _reserve underlying token address
    function getReserveData(address _reserve)
        external virtual
        view
        returns (
            uint256 totalLiquidity,               // reserve total liquidity
            uint256 availableLiquidity,           // reserve available liquidity for borrowing
            uint256 totalBorrowsStable,           // total amount of outstanding borrows at Stable rate
            uint256 totalBorrowsVariable,         // total amount of outstanding borrows at Variable rate
            uint256 liquidityRate,                // current deposit APY of the reserve for depositors, in Ray units.
            uint256 variableBorrowRate,           // current variable rate APY of the reserve pool, in Ray units.
            uint256 stableBorrowRate,             // current stable rate APY of the reserve pool, in Ray units.
            uint256 averageStableBorrowRate,      // current average stable borrow rate
            uint256 utilizationRate,              // expressed as total borrows/total liquidity.
            uint256 liquidityIndex,               // cumulative liquidity index
            uint256 variableBorrowIndex,          // cumulative variable borrow index
            address aTokenAddress,                // aTokens contract address for the specific _reserve
            uint40 lastUpdateTimestamp            // timestamp of the last update of reserve data
        );

    /// @param _user users address
    function getUserAccountData(address _user)
        external virtual
        view
        returns (
            uint256 totalLiquidityETH,            // user aggregated deposits across all the reserves. In Wei
            uint256 totalCollateralETH,           // user aggregated collateral across all the reserves. In Wei
            uint256 totalBorrowsETH,              // user aggregated outstanding borrows across all the reserves. In Wei
            uint256 totalFeesETH,                 // user aggregated current outstanding fees in ETH. In Wei
            uint256 availableBorrowsETH,          // user available amount to borrow in ETH
            uint256 currentLiquidationThreshold,  // user current average liquidation threshold across all the collaterals deposited
            uint256 ltv,                          // user average Loan-to-Value between all the collaterals
            uint256 healthFactor                  // user current Health Factor
    );    

    /// @param _reserve underlying token address
    /// @param _user users address
    function getUserReserveData(address _reserve, address _user)
        external virtual
        view
        returns (
            uint256 currentATokenBalance,         // user current reserve aToken balance
            uint256 currentBorrowBalance,         // user current reserve outstanding borrow balance
            uint256 principalBorrowBalance,       // user balance of borrowed asset
            uint256 borrowRateMode,               // user borrow rate mode either Stable or Variable
            uint256 borrowRate,                   // user current borrow rate APY
            uint256 liquidityRate,                // user current earn rate on _reserve
            uint256 originationFee,               // user outstanding loan origination fee
            uint256 variableBorrowIndex,          // user variable cumulative index
            uint256 lastUpdateTimestamp,          // Timestamp of the last data update
            bool usageAsCollateralEnabled         // Whether the user's current reserve is enabled as a collateral
    );

    function getReserveConfigurationData(address _reserve)
        external virtual
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
    );

    // ------------------ LendingPoolCoreData ------------------------
    function getReserveATokenAddress(address _reserve) public virtual view returns (address);
    function getReserveConfiguration(address _reserve)
        external virtual
        view
        returns (uint256, uint256, uint256, bool);
    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public virtual
        view
        returns (uint256);

    function getReserveCurrentLiquidityRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentStableBorrowRate(address _reserve) 
        public virtual
        view
        returns (uint256);
    function getReserveTotalLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveAvailableLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalBorrowsVariable(address _reserve)
        public virtual
        view
        returns (uint256);

    // ---------------- LendingPoolDataProvider ---------------------
    function calculateUserGlobalData(address _user)
        public virtual
        view
        returns (
            uint256 totalLiquidityBalanceETH,
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            uint256 currentLiquidationThreshold,
            uint256 healthFactor,
            bool healthFactorBelowThreshold
        );
}    







/// @title Getter contract for positions from Aave protocol
contract AaveV1FullPositionView is DSMath, IFlashLoanParamsGetter {

    address public constant AAVE_V1_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    struct UserBorrows {
        address[] borrowAddr;
        uint256[] borrowAmounts;
        uint256[] borrowRateModes;
    }

    function getUserBorrows(address _user, address[] memory _borrTokens) public view returns (UserBorrows memory borrowsData) {
        address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_V1_LENDING_POOL_ADDRESSES).getLendingPool();

        borrowsData = UserBorrows({
            borrowAddr: new address[](_borrTokens.length),
            borrowAmounts: new uint[](_borrTokens.length),
            borrowRateModes: new uint[](_borrTokens.length)
        });

        uint64 borrowPos = 0;

        for (uint64 i = 0; i < _borrTokens.length; i++) {
            address reserve = _borrTokens[i];

            (,uint256 borrowBalance,,uint256 borrowRateMode,,,,,,) = ILendingPool(lendingPoolAddress).getUserReserveData(reserve, _user);

            // Sum up debt in Eth
            if (borrowBalance > 0) {
                borrowsData.borrowAddr[borrowPos] = reserve;
                borrowsData.borrowAmounts[borrowPos] = borrowBalance;
                borrowsData.borrowRateModes[borrowPos] = borrowRateMode;
                borrowPos++;
            }
        }

        return borrowsData;
    }


    function getFlashLoanParams(bytes memory _data) public view override returns (address[] memory tokens, uint256[] memory amount, uint256[] memory modes) {
        (address account, address[] memory borrTokens) = abi.decode(_data, (address,address[]));

        UserBorrows memory borrowsData = getUserBorrows(account, borrTokens);

        return (borrowsData.borrowAddr, borrowsData.borrowAmounts, borrowsData.borrowRateModes);
    }
}