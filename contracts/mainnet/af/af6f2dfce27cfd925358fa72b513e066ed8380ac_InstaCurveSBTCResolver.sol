/**
 *Submitted for verification at Etherscan.io on 2020-07-23
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ICurve {
    function get_virtual_price() external view returns (uint256 out);
    function coins(int128 tokenId) external view returns (address token);
    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256 amount);
    function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external view returns (uint256 buyTokenAmt);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256 amount);
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
     * @dev Return Curve sBTC Swap Address
     */
    function getCurveSwapAddr() internal pure returns (address) {
        return 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    }

    /**
     * @dev Return Curve sBTC Token Address
     */
    function getCurveTokenAddr() internal pure returns (address) {
        return 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    }

    function getTokenI(address token) internal pure returns (int128 i) {
        if (token == address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D)) {
            // renBTC Token
            i = 0;
        } else if (token == address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) {
            // WBTC Token
            i = 1;
        } else if (token == address(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6)) {
            // sBTC Token
            i = 2;
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
        buyAmt = curve.get_dy(getTokenI(sellAddr), getTokenI(buyAddr), sellAmt);
        virtualPrice = curve.get_virtual_price();
        unitAmt = getBuyUnitAmt(buyAddr, sellAddr, sellAmt, buyAmt, slippage);
    }

    function getDepositAmount(address token, uint depositAmt, uint slippage)
        public
        view
        returns (uint curveAmt, uint unitAmt, uint virtualPrice)
    {
        uint[3] memory amts;
        amts[uint(getTokenI(token))] = depositAmt;
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
        uint[3] memory amts;
        amts[uint(getTokenI(token))] = withdrawAmt;
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
        ICurve curve = ICurve(getCurveSwapAddr());
        tokenAmt = curve.calc_withdraw_one_coin(curveAmt, getTokenI(token));
        virtualPrice = curve.get_virtual_price();
        unitAmt = getWithdrawtUnitAmt(token, tokenAmt, curveAmt, slippage);
    }

    function getPosition(
        address user
    ) public view returns (
        uint userBal,
        uint totalSupply,
        uint virtualPrice,
        uint userShare,
        uint poolRenBtcBal,
        uint poolWbtcBal,
        uint poolSbtcBal
    ) {
        TokenInterface curveToken = TokenInterface(getCurveTokenAddr());
        userBal = curveToken.balanceOf(user);
        totalSupply = curveToken.totalSupply();
        userShare = wdiv(userBal, totalSupply);
        ICurve curveContract = ICurve(getCurveSwapAddr());
        virtualPrice = curveContract.get_virtual_price();
        poolRenBtcBal = TokenInterface(curveContract.coins(0)).balanceOf(getCurveSwapAddr());
        poolWbtcBal = TokenInterface(curveContract.coins(1)).balanceOf(getCurveSwapAddr());
        poolSbtcBal = TokenInterface(curveContract.coins(2)).balanceOf(getCurveSwapAddr());
    }
}


contract InstaCurveSBTCResolver is Resolver {
    string public constant name = "Curve-sBTC-Resolver-v1.1";
}