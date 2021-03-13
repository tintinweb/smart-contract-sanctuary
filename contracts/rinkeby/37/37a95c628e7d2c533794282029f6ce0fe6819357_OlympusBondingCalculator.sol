/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IBondingCalculator {
  function calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) external returns ( uint debtRatio_ );
  function calcBondPremium( uint debtRatio_, uint bondConstantValue_ ) external returns ( uint premium_ );
  function calcPrincipleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_ ) external pure returns ( uint principleValuation_ );
  function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external returns ( uint principleValuation_ );
  function calculateBondInterest( address treasury_, address reserveToken_, address principleTokenAddress_, uint amountDeposited_, uint bondConstantValue_ ) external returns ( uint interestDue_ );
}

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function kLast() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

library FixedPoint {
    struct uq112x112 {
        uint224 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(uq112x112 memory self) internal pure returns (uint) {
    return uint(self._x) / 5192296858534827;
  }


    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

interface ITreasury {
    function getManagedTokenForReserveToken(address reserveToken_) external view returns (address);
    function getDebtAmountDueForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (uint);
}

contract OlympusBondingCalculator is IBondingCalculator {

  using FixedPoint for *;
  using SafeMath for uint;
  using SafeMath for uint112;

  event BondPremium( uint debtRatio_, uint bondConstantValue_, uint premium_ );
  event PrincipleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_, uint principleValuation_  );
  event BondInterest( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_, uint pendingDebtDue_, uint managedTokenTotalSupply_, uint bondConstantValue_, uint interestDue_ );

  function _calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) internal pure returns ( uint debtRatio_ ) {    
    debtRatio_ = FixedPoint.fraction( 
      // Must move the decimal to the right by 9 places to avoid math underflow error
      pendingDebtDue_.mul( 1e9 ), 
      managedTokenTotalSupply_
    ).decode112with18()
    // Must move the decimal tot he left 18 places to account for the 9 places added above and the 19 signnificant digits added by FixedPoint.
    .div(1e18);

  }

  function calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) external pure override returns ( uint debtRatio_ ) {
    debtRatio_ = _calcDebtRatio( pendingDebtDue_, managedTokenTotalSupply_ );
  }

  // Premium is 2 extra deciamls i.e. 250 = 2.5 premium
  function _calcBondPremium( uint debtRatio_, uint bondConstantValue_ ) internal pure returns ( uint premium_ ) {
    // premium_ = uint( uint(1).mul( 1e9 ).add( debtRatio_ ) ** bondConstantValue_);
    premium_ = bondConstantValue_.mul( (debtRatio_) ).add( uint(1010000000) ).div( 1e7 );
  }

  function calcBondPremium( uint debtRatio_, uint bondConstantValue_ ) external pure override returns ( uint premium_ ) {
    premium_ = _calcBondPremium( debtRatio_, bondConstantValue_ );
  }

  function _principleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_ ) internal pure returns ( uint principleValuation_ ) {
    principleValuation_ = k_.sqrrt().mul(2).mul( FixedPoint.fraction( amountDeposited_, totalSupplyOfTokenDeposited_ ).decode112with18().div( 1e9 ) );
  }

  function calcPrincipleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_ ) external pure override returns ( uint principleValuation_ ) {
    principleValuation_ = _principleValuation( k_, amountDeposited_, totalSupplyOfTokenDeposited_ );
  }

  function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external view override returns ( uint principleValuation_ ) {
    uint k_ = IUniswapV2Pair( principleTokenAddress_ ).kLast();
    uint principleTokenTotalSupply_ = IUniswapV2Pair( principleTokenAddress_ ).totalSupply();
    principleValuation_ = _principleValuation( k_, amountDeposited_, principleTokenTotalSupply_ );
  }

  function _calculateBondInterest( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_, uint pendingDebtDue_, uint managedTokenTotalSupply_, uint bondConstantValue_ ) internal returns ( uint interestDue_ ) {
    uint principleValuation_ = _principleValuation( k_, amountDeposited_, totalSupplyOfTokenDeposited_ );

    uint debtRatio_ = _calcDebtRatio( pendingDebtDue_, managedTokenTotalSupply_ );

    uint premium_ = _calcBondPremium( debtRatio_, bondConstantValue_ );
    interestDue_ = FixedPoint.fraction(
      principleValuation_,
     premium_
    ).decode()
    .mul(100);
    emit BondInterest( k_, amountDeposited_, totalSupplyOfTokenDeposited_, pendingDebtDue_, managedTokenTotalSupply_, bondConstantValue_, interestDue_ );
  }

  function calculateBondInterest( address treasury_, address reserveToken_, address principleTokenAddress_, uint amountDeposited_, uint bondConstantValue_ ) external override returns ( uint interestDue_ ) {
    uint k_ = IUniswapV2Pair( principleTokenAddress_ ).kLast();

    uint principleTokenTotalSuply_ = IUniswapV2Pair( principleTokenAddress_ ).totalSupply();

    address managedToken_ = ITreasury( treasury_ ).getManagedTokenForReserveToken( reserveToken_ );

    uint managedTokenTotalSuply_ = IUniswapV2Pair( managedToken_ ).totalSupply();

    uint outstandingDebtAmount_ = ITreasury( treasury_ ).getDebtAmountDueForPrincipleTokenForReserveToken( principleTokenAddress_, reserveToken_ );

    interestDue_ = _calculateBondInterest( k_, amountDeposited_, principleTokenTotalSuply_, outstandingDebtAmount_, managedTokenTotalSuply_, bondConstantValue_ );
  }
}