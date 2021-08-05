/**
 *Submitted for verification at Etherscan.io on 2020-08-15
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface OneProtoInterface {
    function getExpectedReturn(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );

    function getExpectedReturnWithGas(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256 estimateGasAmount,
        uint256[] memory distribution
    );

    function getExpectedReturnWithGasMulti(
        TokenInterface[] calldata tokens,
        uint256 amount,
        uint256[] calldata parts,
        uint256[] calldata flags,
        uint256[] calldata destTokenEthPriceTimesGasPrices
    )
    external
    view
    returns(
        uint256[] memory returnAmounts,
        uint256 estimateGasAmount,
        uint256[] memory distribution
    );
}

interface OneProtoMappingInterface {
    function oneProtoAddress() external view returns(address);
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


contract Helpers is DSMath {

    /**
     * @dev get Ethereum address
     */
    function getAddressETH() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}


contract OneProtoHelpers is Helpers {
   /**
     * @dev Return 1proto mapping Address
     */
    function getOneProtoMappingAddress() internal pure returns (address payable) {
        return 0x8d0287AFa7755BB5f2eFe686AA8d4F0A7BC4AE7F;
    }

    /**
     * @dev Return 1proto Address
     */
    function getOneProtoAddress() internal view returns (address payable) {
        return payable(OneProtoMappingInterface(getOneProtoMappingAddress()).oneProtoAddress());
    }

    function getTokenDecimals(TokenInterface buy, TokenInterface sell) internal view returns(uint _buyDec, uint _sellDec){
        _buyDec = address(buy) == getAddressETH() ? 18 : buy.decimals();
        _sellDec = address(sell) == getAddressETH() ? 18 : sell.decimals();
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint expectedAmt,
        TokenInterface sellAddr,
        uint sellAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        (uint buyDec, uint sellDec) = getTokenDecimals(buyAddr, sellAddr);
        uint _sellAmt = convertTo18(sellDec, sellAmt);
        uint _buyAmt = convertTo18(buyDec, expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }
}


contract Resolver is OneProtoHelpers {

    function getBuyAmount(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint slippage,
        uint distribution,
        uint disableDexes
    ) public view returns (uint buyAmt, uint unitAmt, uint[] memory distributions) {
        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);
        (buyAmt, distributions) = OneProtoInterface(getOneProtoAddress())
                .getExpectedReturn(
                    _sellAddr,
                    _buyAddr,
                    sellAmt,
                    distribution,
                    disableDexes
                    );
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getBuyAmountWithGas(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint slippage,
        uint distribution,
        uint disableDexes,
        uint destTokenEthPriceTimesGasPrices
    ) public view returns (uint buyAmt, uint unitAmt, uint[] memory distributions, uint estimateGasAmount) {
        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);
        (buyAmt, estimateGasAmount, distributions) = OneProtoInterface(getOneProtoAddress())
                .getExpectedReturnWithGas(
                    _sellAddr,
                    _buyAddr,
                    sellAmt,
                    distribution,
                    disableDexes,
                    destTokenEthPriceTimesGasPrices
                    );
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }


    function getBuyAmountMultiWithGas(
        TokenInterface[] memory tokens,
        uint sellAmt,
        uint slippage,
        uint[] memory distribution,
        uint[] memory disableDexes,
        uint[] memory destTokenEthPriceTimesGasPrices
    )
    public
    view
    returns(
        uint buyAmt,
        uint unitAmt,
        uint[] memory distributions,
        uint[] memory returnAmounts,
        uint estimateGasAmount
    ) {
        uint len = tokens.length;
        (returnAmounts, estimateGasAmount, distributions) = OneProtoInterface(getOneProtoAddress())
                .getExpectedReturnWithGasMulti(
                    tokens,
                    sellAmt,
                    distribution,
                    disableDexes,
                    destTokenEthPriceTimesGasPrices
                    );
        buyAmt = returnAmounts[len - 2];
        unitAmt = getBuyUnitAmt(TokenInterface(tokens[len - 1]), buyAmt, TokenInterface(tokens[0]), sellAmt, slippage);
    }

    struct MultiTokenPaths {
        TokenInterface[] tokens;
        uint[] distribution;
        uint[] disableDexes;
        uint[] destTokenEthPriceTimesGasPrices;
    }

    struct MultiTokenPathsBuyAmt {
        uint buyAmt;
        uint unitAmt;
        uint[] distributions;
        uint[] returnAmounts;
        uint estimateGasAmount;
    }

    function getBuyAmountsMulti(
        MultiTokenPaths[] memory multiTokenPaths,
        uint sellAmt,
        uint slippage
    )
    public
    view
    returns (MultiTokenPathsBuyAmt[] memory)
    {
        uint len = multiTokenPaths.length;
        MultiTokenPathsBuyAmt[] memory data = new MultiTokenPathsBuyAmt[](len);
        for (uint i = 0; i < len; i++) {
            data[i] = MultiTokenPathsBuyAmt({
               buyAmt: 0,
               unitAmt: 0,
               distributions: new uint[](0),
               returnAmounts: new uint[](0),
               estimateGasAmount: 0
            });
            (
                data[i].buyAmt,
                data[i].unitAmt,
                data[i].distributions,
                data[i].returnAmounts,
                data[i].estimateGasAmount
            ) = getBuyAmountMultiWithGas(
                multiTokenPaths[i].tokens,
                sellAmt,
                slippage,
                multiTokenPaths[i].distribution,
                multiTokenPaths[i].disableDexes,
                multiTokenPaths[i].destTokenEthPriceTimesGasPrices
            );
        }
        return data;
    }
}


contract InstaOneProtoResolver is Resolver {
    string public constant name = "1Proto-Resolver-v1";
}