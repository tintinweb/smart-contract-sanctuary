/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 ▄▄▄▄▄▄   ▄███▄      ▄   █  █▀ ████▄ 
▀   ▄▄▀   █▀   ▀      █  █▄█   █   █ 
 ▄▀▀   ▄▀ ██▄▄    ██   █ █▀▄   █   █ 
 ▀▀▀▀▀▀   █▄   ▄▀ █ █  █ █  █  ▀████ 
          ▀███▀   █  █ █   █         
                  █   ██  ▀       */
/// 🦊🌾 Special thanks to Keno / Boring / Gonpachi / Karbon for review and continued inspiration.
pragma solidity 0.8.6;

interface IERC20 {} interface IBentoHelper {
    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
}

interface ICompoundHelper {
    function getCash() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IKashiHelper {
    function asset() external view returns (IERC20);
    function totalAsset() external view returns (Rebase memory);
    function totalBorrow() external view returns (Rebase memory);
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }
}

/// @notice Helper for Inari SushiZap calculations.
contract Zenko {
    IBentoHelper constant bento = IBentoHelper(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966); // BENTO vault contract (multinet)
    
    // **** BENTO 
    function toBento(IERC20 token, uint256 amount) external view returns (uint256 share) {
        share = bento.toShare(token, amount, false);
    }
    
    function fromBento(IERC20 token, uint256 share) external view returns (uint256 amount) {
        amount = bento.toAmount(token, share, false);
    }
    
    // **** COMPOUND/CREAM
    function toCtoken(ICompoundHelper cToken, uint256 underlyingAmount) public view returns (uint256 cTokenAmount) {
        cTokenAmount = divScalarByExpTruncate(underlyingAmount, Exp({mantissa: exchangeRateStoredInternal(cToken)}));
    }
    
    function fromCtoken(ICompoundHelper cToken, uint256 cTokenAmount) public view returns (uint256 underlyingAmount) {
        underlyingAmount = mulScalarTruncate(Exp({mantissa: exchangeRateStoredInternal(cToken)}), cTokenAmount);
    }

    // **** KASHI - ASSET
    function toKashi(IKashiHelper kmToken, uint256 underlyingAmount) external view returns (uint256 fraction) {
        IERC20 token = kmToken.asset();
        uint256 share = bento.toShare(token, underlyingAmount, false);
        uint256 allShare = kmToken.totalAsset().elastic + bento.toShare(token, kmToken.totalBorrow().elastic, true);
        fraction = allShare == 0 ? share : share * kmToken.totalAsset().base / allShare;
    }
    
    function fromKashi(IKashiHelper kmToken, uint256 kmAmount) external view returns (uint256 share) {
        uint256 allShare = kmToken.totalAsset().elastic + bento.toShare(kmToken.asset(), kmToken.totalBorrow().elastic, true);
        share = kmAmount * allShare / kmToken.totalAsset().base;
    }
    
    // **************
    // CTOKEN HELPERS
    // **************
    struct Exp {
        uint256 mantissa;
    }
    function addUInt(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function subUInt(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function addThenSubUInt(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 sum = addUInt(a, b);
        return subUInt(sum, c);
    }
    function mulUInt(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function divUInt(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function getExp(uint256 num, uint256 denom) pure internal returns (Exp memory) {
        uint256 scaledNumerator = mulUInt(num, 1e18);
        uint256 rational = divUInt(scaledNumerator, denom);
        return Exp({mantissa: rational});
    }
    function truncate(Exp memory exp) pure internal returns (uint256) {
        return exp.mantissa / 1e18;
    }
    function divScalarByExp(uint256 scalar, Exp memory divisor) pure internal returns (Exp memory) {
        uint256 numerator = mulUInt(1e18, scalar);
        return getExp(numerator, divisor.mantissa);
    }
    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) pure internal returns (uint256) {
        Exp memory fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }
    function mulScalar(Exp memory a, uint256 scalar) pure internal returns (Exp memory) {
        uint256 scaledMantissa = mulUInt(a.mantissa, scalar);
        return Exp({mantissa: scaledMantissa});
    }
    function mulScalarTruncate(Exp memory a, uint256 scalar) pure internal returns (uint256) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product);
    }
    function exchangeRateStoredInternal(ICompoundHelper cToken) public view returns (uint256) {
        uint256 _totalSupply = cToken.totalSupply();
        /*
         *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
         */
        uint256 totalCash = cToken.getCash();
        uint256 cashPlusBorrowsMinusReserves;
        Exp memory exchangeRate;
        cashPlusBorrowsMinusReserves = addThenSubUInt(totalCash, cToken.totalBorrows(), cToken.totalReserves());
        exchangeRate = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
        return exchangeRate.mantissa;
    }
}