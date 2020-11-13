pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CreamSafetyRatio.sol";
import "./helpers/CreamSaverHelper.sol";


/// @title Gets data about cream positions
contract CreamLoanInfo is CreamSafetyRatio {

    struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint[] collAmounts;
        uint[] borrowAmounts;
    }

    struct TokenInfo {
        address cTokenAddress;
        address underlyingTokenAddress;
        uint collateralFactor;
        uint price;
    }

    struct TokenInfoFull {
        address underlyingTokenAddress;
        uint supplyRate;
        uint borrowRate;
        uint exchangeRate;
        uint marketLiquidity;
        uint totalSupply;
        uint totalBorrow;
        uint collateralFactor;
        uint price;
    }

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0xD06527D5e56A3495252A528C4987003b712860eE;


    /// @notice Calcualted the ratio of coll/debt for a cream user
    /// @param _user Address of the user
    function getRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        return getSafetyRatio(_user);
    }

    /// @notice Fetches cream prices for tokens
    /// @param _cTokens Arr. of cTokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address[] memory _cTokens) public view returns (uint[] memory prices) {
        prices = new uint[](_cTokens.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokens.length; ++i) {
            prices[i] = CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokens[i]);
        }
    }

    /// @notice Fetches cream collateral factors for tokens
    /// @param _cTokens Arr. of cTokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address[] memory _cTokens) public view returns (uint[] memory collFactors) {
        collFactors = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; ++i) {
            (, collFactors[i]) = comp.markets(_cTokens[i]);
        }
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in eth
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _user) public view returns (LoanData memory data) {
        address[] memory assets = comp.getAssetsIn(_user);
        address oracleAddr = comp.oracle();

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](assets.length),
            borrowAddr: new address[](assets.length),
            collAmounts: new uint[](assets.length),
            borrowAmounts: new uint[](assets.length)
        });

        uint collPos = 0;
        uint borrowPos = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(asset)});
            }

            // Sum up collateral in eth
            if (cTokenBalance != 0) {
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
                (, Exp memory tokensToEth) = mulExp(exchangeRate, oraclePrice);

                data.collAddr[collPos] = asset;
                (, data.collAmounts[collPos]) = mulScalarTruncate(tokensToEth, cTokenBalance);
                collPos++;
            }

            // Sum up debt in eth
            if (borrowBalance != 0) {
                data.borrowAddr[borrowPos] = asset;
                (, data.borrowAmounts[borrowPos]) = mulScalarTruncate(oraclePrice, borrowBalance);
                borrowPos++;
            }
        }

        data.ratio = uint128(getSafetyRatio(_user));

        return data;
    }

    function getTokenBalances(address _user, address[] memory _cTokens) public view returns (uint[] memory balances, uint[] memory borrows) {
        balances = new uint[](_cTokens.length);
        borrows = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; i++) {
            address asset = _cTokens[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
            (, balances[i]) = mulScalarTruncate(exchangeRate, cTokenBalance);

            borrows[i] = borrowBalance;
        }

    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in eth
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }

    /// @notice Calcualted the ratio of coll/debt for a cream user
    /// @param _users Addresses of the user
    /// @return ratios Array of ratios
    function getRatios(address[] memory _users) public view returns (uint[] memory ratios) {
        ratios = new uint[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            ratios[i] = getSafetyRatio(_users[i]);
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return tokens Array of cTokens infomartion
    function getTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfo[] memory tokens) {
        tokens = new TokenInfo[](_cTokenAddresses.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);

            tokens[i] = TokenInfo({
                cTokenAddress: _cTokenAddresses[i],
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                collateralFactor: collFactor,
                price: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokenAddresses[i])
            });
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return tokens Array of cTokens infomartion
    function getFullTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfoFull[] memory tokens) {
        tokens = new TokenInfoFull[](_cTokenAddresses.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);
            CTokenInterface cToken = CTokenInterface(_cTokenAddresses[i]);

            tokens[i] = TokenInfoFull({
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                supplyRate: cToken.supplyRatePerBlock(),
                borrowRate: cToken.borrowRatePerBlock(),
                exchangeRate: cToken.exchangeRateCurrent(),
                marketLiquidity: cToken.getCash(),
                totalSupply: cToken.totalSupply(),
                totalBorrow: cToken.totalBorrowsCurrent(),
                collateralFactor: collFactor,
                price: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokenAddresses[i])
            });
        }
    }

    /// @notice Returns the underlying address of the cToken asset
    /// @param _cTokenAddress cToken address
    /// @return Token address of the cToken specified
    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }
}
