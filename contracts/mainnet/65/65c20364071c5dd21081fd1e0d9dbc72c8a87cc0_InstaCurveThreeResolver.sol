pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ICurve {
    function get_virtual_price() external view returns (uint256 out);
    function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external view returns (uint256 buyTokenAmt);
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
    * @dev Return Curve 3pool Swap Address
    */
    function getCurveSwapAddr() internal pure returns (address) {
        return 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    }

    /**
    * @dev Return Curve 3pool Token Address
    */
    function getCurveTokenAddr() internal pure returns (address) {
        return 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
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
}


contract InstaCurveThreeResolver is Resolver {
    string public constant name = "Curve-3pool-Resolver-v1.0";
}