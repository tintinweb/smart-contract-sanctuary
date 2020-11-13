pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../exchange/SaverExchangeCore.sol";

contract ExchangeDataParser {
     function decodeExchangeData(
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (address[4] memory, uint[4] memory, bytes memory) {
        return (
         [exchangeData.srcAddr, exchangeData.destAddr, exchangeData.exchangeAddr, exchangeData.wrapper],
         [exchangeData.srcAmount, exchangeData.destAmount, exchangeData.minPrice, exchangeData.price0x],
         exchangeData.callData
        );
    }

    function encodeExchangeData(
        address[4] memory exAddr, uint[4] memory exNum, bytes memory callData
    ) internal pure returns (SaverExchangeCore.ExchangeData memory) {
        return SaverExchangeCore.ExchangeData({
            srcAddr: exAddr[0],
            destAddr: exAddr[1],
            srcAmount: exNum[0],
            destAmount: exNum[1],
            minPrice: exNum[2],
            wrapper: exAddr[3],
            exchangeAddr: exAddr[2],
            callData: callData,
            price0x: exNum[3]
        });
    }
}
