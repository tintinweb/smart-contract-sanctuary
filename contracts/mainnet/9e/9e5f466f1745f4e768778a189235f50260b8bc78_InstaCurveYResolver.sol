/**
 *Submitted for verification at Etherscan.io on 2020-07-19
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ICurve {
    function get_virtual_price() external view returns (uint256 out);
    function coins(int128 tokenId) external view returns (address token);
    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns (uint256 amount);
    function get_dy_underlying(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external view returns (uint256 buyTokenAmt);
}

interface ICurveZap {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256 amount);
}

interface YTokenInterface {
    function getPricePerFullShare() external view returns (uint256 amount);
}

interface TokenInterface {
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint);
}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}

contract CurveHelpers is DSMath {
    /**
  * @dev Return ycurve Swap Address
  */
  function getCurveSwapAddr() internal pure returns (address) {
    return 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
  }

  /**
  * @dev Return ycurve zap Address
  */
  function getCurveZapAddr() internal pure returns (address) {
    return 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
  }

  /**
  * @dev Return Curve Token Address
  */
  function getCurveTokenAddr() internal pure returns (address) {
    return 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
  }

    function getTokenI(address token) internal pure returns (int128 i) {
        if (token == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
        // DAI Token
        i = 0;
        } else if (token == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {
        // USDC Token
        i = 1;
        } else if (token == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)) {
        // USDT Token
        i = 2;
        } else if (token == address(0x0000000000085d4780B73119b644AE5ecd22b376)) {
        // USDT Token
        i = 3;
        } else {
        revert("token-not-found.");
        }
    }

    function getYtoken(address token) internal pure returns (address yTkn) {
        if (token == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
            // DAI Token
            yTkn = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;
        } else if (token == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {
            // USDC Token
            yTkn = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e;
        } else if (token == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)) {
            // USDT Token
            yTkn = 0x83f798e925BcD4017Eb265844FDDAbb448f1707D;
        } else if (token == address(0x0000000000085d4780B73119b644AE5ecd22b376)) {
            // USDT Token
            yTkn = 0x73a052500105205d34Daf004eAb301916DA8190f;
        } else {
        revert("token-not-found.");
        }
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function getBuyUnitAmt(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint buyAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _sellAmt = convertTo18(TokenInterface(sellAddr).decimals(), sellAmt);
        uint _buyAmt = convertTo18(TokenInterface(buyAddr).decimals(), buyAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getDepositUnitAmt(
        address token,
        uint depositAmt,
        uint curveAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _depositAmt = convertTo18(TokenInterface(token).decimals(), depositAmt);
        uint _curveAmt = convertTo18(TokenInterface(getCurveTokenAddr()).decimals(), curveAmt);
        unitAmt = wdiv(_curveAmt, _depositAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getWithdrawtUnitAmt(
        address token,
        uint withdrawAmt,
        uint curveAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _withdrawAmt = convertTo18(TokenInterface(token).decimals(), withdrawAmt);
        uint _curveAmt = convertTo18(TokenInterface(getCurveTokenAddr()).decimals(), curveAmt);
        unitAmt = wdiv(_curveAmt, _withdrawAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }
}


contract Resolver is CurveHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt, uint slippage)
        public
        view
        returns (uint buyAmt, uint unitAmt, uint virtualPrice)
    {
        ICurve curve = ICurve(getCurveSwapAddr());
        buyAmt = curve.get_dy_underlying(getTokenI(sellAddr), getTokenI(buyAddr), sellAmt);
        virtualPrice = curve.get_virtual_price();
        unitAmt = getBuyUnitAmt(buyAddr, sellAddr, sellAmt, buyAmt, slippage);
    }

    function getDepositAmount(address token, uint depositAmt, uint slippage)
        public
        view
        returns (uint curveAmt, uint unitAmt, uint virtualPrice)
    {
        uint sharePrice = YTokenInterface(getYtoken(token)).getPricePerFullShare();
        uint yAmt = wdiv(depositAmt, sharePrice);
        uint[4] memory amts;
        amts[uint(getTokenI(token))] = yAmt;
        ICurve curve = ICurve(getCurveSwapAddr());
        curveAmt = curve.calc_token_amount(amts, true);
        virtualPrice = curve.get_virtual_price();
        unitAmt = getDepositUnitAmt(token, depositAmt, curveAmt, slippage);
    }

    function getWithdrawAmount(address token, uint withdrawAmt, uint slippage)
        public
        view
        returns (uint curveAmt, uint unitAmt, uint virtualPrice)
    {
        uint sharePrice = YTokenInterface(getYtoken(token)).getPricePerFullShare();
        uint yAmt = wdiv(withdrawAmt, sharePrice);
        uint[4] memory amts;
        amts[uint(getTokenI(token))] = yAmt;
        ICurve curve = ICurve(getCurveSwapAddr());
        curveAmt = curve.calc_token_amount(amts, false);
        virtualPrice = curve.get_virtual_price();
        unitAmt = getWithdrawtUnitAmt(token, withdrawAmt, curveAmt, slippage);
    }

    function getWithdrawTokenAmount(address token, uint curveAmt, uint slippage)
        public
        view
        returns (uint tokenAmt, uint unitAmt, uint virtualPrice)
    {
        tokenAmt = ICurveZap(getCurveZapAddr()).calc_withdraw_one_coin(curveAmt, getTokenI(token));
        virtualPrice = ICurve(getCurveSwapAddr()).get_virtual_price();
        unitAmt = getWithdrawtUnitAmt(token, tokenAmt, curveAmt, slippage);
    }

    function getPosition(
        address user
    ) public view returns (
        uint userBal,
        uint totalSupply,
        uint virtualPrice,
        uint userShare,
        uint poolyDaiBal,
        uint poolyUsdcBal,
        uint poolyUsdtBal,
        uint poolyTusdBal
    ) {
        TokenInterface curveToken = TokenInterface(getCurveTokenAddr());
        userBal = curveToken.balanceOf(user);
        totalSupply = curveToken.totalSupply();
        userShare = wdiv(userBal, totalSupply);
        ICurve curveContract = ICurve(getCurveSwapAddr());
        virtualPrice = curveContract.get_virtual_price();
        poolyDaiBal = TokenInterface(curveContract.coins(0)).balanceOf(getCurveSwapAddr());
        poolyUsdcBal = TokenInterface(curveContract.coins(1)).balanceOf(getCurveSwapAddr());
        poolyUsdtBal = TokenInterface(curveContract.coins(2)).balanceOf(getCurveSwapAddr());
        poolyTusdBal = TokenInterface(curveContract.coins(3)).balanceOf(getCurveSwapAddr());
    }
}


contract InstaCurveYResolver is Resolver {
    string public constant name = "Curve-Y-Resolver-v1";
}