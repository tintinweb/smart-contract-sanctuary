/**
 *Submitted for verification at Etherscan.io on 2020-04-28
*/

pragma solidity ^0.6.0;

interface OasisInterface {
    function getMinSell(TokenInterface pay_gem) external view returns (uint);
    function getBuyAmount(address dest, address src, uint srcAmt) external view returns(uint);
	function getPayAmount(address src, address dest, uint destAmt) external view returns (uint);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function decimals() external view returns (uint);
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


contract Helpers is DSMath {
    /**
     * @dev get Ethereum address
     */
    function getAddressETH() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}


contract OasisHelpers is Helpers {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return Oasis Address
     */
    function getOasisAddr() internal pure returns (address) {
        return 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getAddressETH() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getAddressETH() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint expectedAmt,
        TokenInterface sellAddr,
        uint sellAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _sellAmt = convertTo18((sellAddr).decimals(), sellAmt);
        uint _buyAmt = convertTo18(buyAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getSellUnitAmt(
        TokenInterface sellAddr,
        uint expectedAmt,
        TokenInterface buyAddr,
        uint buyAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _buyAmt = convertTo18(buyAddr.decimals(), buyAmt);
        uint _sellAmt = convertTo18(sellAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_sellAmt, _buyAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }

}


contract Resolver is OasisHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt, uint slippage) public view returns (uint buyAmt, uint unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        buyAmt = OasisInterface(getOasisAddr()).getBuyAmount(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(address buyAddr, address sellAddr, uint buyAmt, uint slippage) public view returns (uint sellAmt, uint unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        sellAmt = OasisInterface(getOasisAddr()).getPayAmount(address(_sellAddr), address(_buyAddr), buyAmt);
        unitAmt = getBuyUnitAmt(_sellAddr, sellAmt, _buyAddr, buyAmt, slippage);
    }

    function getMinSellAmount(address sellAddr) public view returns (uint minAmt) {
        (, TokenInterface _sellAddr) = changeEthAddress(getAddressETH(), sellAddr);
        minAmt = OasisInterface(getOasisAddr()).getMinSell(_sellAddr);
    }

}


contract InstaOasisResolver is Resolver {
    string public constant name = "Oasis-Resolver-v1";
}