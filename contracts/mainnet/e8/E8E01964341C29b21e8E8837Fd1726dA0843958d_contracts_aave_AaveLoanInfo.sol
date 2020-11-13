pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AaveSafetyRatio.sol";

contract AaveLoanInfo is AaveSafetyRatio {

	struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint256[] collAmounts;
        uint256[] borrowAmounts;
    }

    struct TokenInfo {
        address aTokenAddress;
        address underlyingTokenAddress;
        uint256 collateralFactor;
        uint256 price;
    }

    struct TokenInfoFull {
    	address aTokenAddress;
        address underlyingTokenAddress;
        uint256 supplyRate;
        uint256 borrowRate;
        uint256 borrowRateStable;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalBorrow;
        uint256 collateralFactor;
        uint256 liquidationRatio;
        uint256 price;
        bool usageAsCollateralEnabled;
    }

    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _user Address of the user
    function getRatio(address _user) public view returns (uint256) {
        // For each asset the account is in
        return getSafetyRatio(_user);
    }

    /// @notice Fetches Aave prices for tokens
    /// @param _tokens Arr. of tokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address[] memory _tokens) public view returns (uint256[] memory prices) {
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();
        prices = new uint[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; ++i) {
            prices[i] = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokens[i]);
        }
    }

    /// @notice Fetches Aave collateral factors for tokens
    /// @param _tokens Arr. of tokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address[] memory _tokens) public view returns (uint256[] memory collFactors) {
    	address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        collFactors = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; ++i) {
        	(,collFactors[i],,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_tokens[i]);
        }
    }

    function getTokenBalances(address _user, address[] memory _tokens) public view returns (uint256[] memory balances, uint256[] memory borrows, bool[] memory enabledAsCollateral) {
    	address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        balances = new uint256[](_tokens.length);
        borrows = new uint256[](_tokens.length);
        enabledAsCollateral = new bool[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address asset = _tokens[i];

            (balances[i], borrows[i],,,,,,,,enabledAsCollateral[i]) = ILendingPool(lendingPoolAddress).getUserReserveData(asset, _user);
        }
    }

    /// @notice Calcualted the ratio of coll/debt for an aave user
    /// @param _users Addresses of the user
    /// @return ratios Array of ratios
    function getRatios(address[] memory _users) public view returns (uint256[] memory ratios) {
        ratios = new uint256[](_users.length);

        for (uint256 i = 0; i < _users.length; ++i) {
            ratios[i] = getSafetyRatio(_users[i]);
        }
    }

    /// @notice Information about reserves
    /// @param _tokenAddresses Array of tokens addresses
    /// @return tokens Array of reserves infomartion
    function getTokensInfo(address[] memory _tokenAddresses) public view returns(TokenInfo[] memory tokens) {
    	address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
    	address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        tokens = new TokenInfo[](_tokenAddresses.length);

        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
        	(,uint256 ltv,,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_tokenAddresses[i]);

            tokens[i] = TokenInfo({
                aTokenAddress: ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(_tokenAddresses[i]),
                underlyingTokenAddress: _tokenAddresses[i],
                collateralFactor: ltv,
                price: IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddresses[i])
            });
        }
    }

    /// @notice Information about reserves
    /// @param _tokenAddresses Array of token addresses
    /// @return tokens Array of reserves infomartion
    function getFullTokensInfo(address[] memory _tokenAddresses) public view returns(TokenInfoFull[] memory tokens) {
    	address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
    	address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        tokens = new TokenInfoFull[](_tokenAddresses.length);

        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
        	(,uint256 ltv, uint256 liqRatio, bool usageAsCollateralEnabled) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_tokenAddresses[i]);

            tokens[i] = TokenInfoFull({
            	aTokenAddress: ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(_tokenAddresses[i]),
                underlyingTokenAddress: _tokenAddresses[i],
                supplyRate: ILendingPool(lendingPoolCoreAddress).getReserveCurrentLiquidityRate(_tokenAddresses[i]),
                borrowRate: ILendingPool(lendingPoolCoreAddress).getReserveCurrentVariableBorrowRate(_tokenAddresses[i]),
                borrowRateStable: ILendingPool(lendingPoolCoreAddress).getReserveCurrentStableBorrowRate(_tokenAddresses[i]),
                totalSupply: ILendingPool(lendingPoolCoreAddress).getReserveTotalLiquidity(_tokenAddresses[i]),
                availableLiquidity: ILendingPool(lendingPoolCoreAddress).getReserveAvailableLiquidity(_tokenAddresses[i]),
                totalBorrow: ILendingPool(lendingPoolCoreAddress).getReserveTotalBorrowsVariable(_tokenAddresses[i]),
                collateralFactor: ltv,
                liquidationRatio: liqRatio,
                price: IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddresses[i]),
                usageAsCollateralEnabled: usageAsCollateralEnabled
            });
        }
    }


    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _user) public view returns (LoanData memory data) {
        address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        address[] memory reserves = ILendingPool(lendingPoolAddress).getReserves();

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](reserves.length),
            borrowAddr: new address[](reserves.length),
            collAmounts: new uint[](reserves.length),
            borrowAmounts: new uint[](reserves.length)
        });

        uint64 collPos = 0;
        uint64 borrowPos = 0;

        for (uint64 i = 0; i < reserves.length; i++) {
            address reserve = reserves[i];

            (uint256 aTokenBalance, uint256 borrowBalance,,,,,,,,) = ILendingPool(lendingPoolAddress).getUserReserveData(reserve, _user);
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(reserves[i]);

            if (aTokenBalance > 0) {
            	uint256 userTokenBalanceEth = wmul(aTokenBalance, price) * (10 ** (18 - _getDecimals(reserve)));
            	data.collAddr[collPos] = reserve;
                data.collAmounts[collPos] = userTokenBalanceEth;
                collPos++;
        	}

            // Sum up debt in Eth
            if (borrowBalance > 0) {
            	uint256 userBorrowBalanceEth = wmul(borrowBalance, price) * (10 ** (18 - _getDecimals(reserve)));
                data.borrowAddr[borrowPos] = reserve;
                data.borrowAmounts[borrowPos] = userBorrowBalanceEth;
                borrowPos++;
            }
        }

        data.ratio = uint128(getSafetyRatio(_user));

        return data;
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }
}