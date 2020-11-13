pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../interfaces/CompoundOracleInterface.sol";
import "../interfaces/ComptrollerInterface.sol";
import "../interfaces/CTokenInterface.sol";
import "../compound/helpers/Exponential.sol";


contract CreamSafetyRatio is Exponential, DSMath {
    // solhint-disable-next-line const-name-snakecase
    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);

    /// @notice Calcualted the ratio of debt / adjusted collateral
    /// @param _user Address of the user
    function getSafetyRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        address[] memory assets = comp.getAssetsIn(_user);
        address oracleAddr = comp.oracle();


        uint sumCollateral = 0;
        uint sumBorrow = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(asset)});
            }

            // Sum up collateral in Eth
            if (cTokenBalance != 0) {

                (, uint collFactorMantissa) = comp.markets(address(asset));

                Exp memory collateralFactor = Exp({mantissa: collFactorMantissa});
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});

                (, Exp memory tokensToEther) = mulExp3(collateralFactor, exchangeRate, oraclePrice);

                (, sumCollateral) = mulScalarTruncateAddUInt(tokensToEther, cTokenBalance, sumCollateral);
            }

            // Sum up debt in Eth
            if (borrowBalance != 0) {
                (, sumBorrow) = mulScalarTruncateAddUInt(oraclePrice, borrowBalance, sumBorrow);
            }
        }

        if (sumBorrow == 0) return uint(-1);

        uint borrowPowerUsed = (sumBorrow * 10**18) / sumCollateral;
        return wdiv(1e18, borrowPowerUsed);
    }
}
