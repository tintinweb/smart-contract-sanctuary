pragma solidity ^0.4.21;

interface BancorConverter {
    // _path is actually IERC20Token[] type
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
}

contract BancorHandler {
    // State variables
    uint256 public MAX_UINT = 2**256 -1;
    BancorConverter public exchange;
    // address public bancorQuickConvertAddress = address(0xcf1cc6ed5b653def7417e3fa93992c3ffe49139b);

    // Constructor
    function BancorHandler(address _exchange) public {
        exchange = BancorConverter(_exchange);
    }

    // Public functions
    function getAvailableAmount(
        address[21] orderAddresses, // conversion path (max length 21)
        uint256[6] orderValues, // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
        uint256 exchangeFee, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external returns (uint256) {
        // Just return a massive number, as there&#39;s nothing else we can do here
        return MAX_UINT;
    }

    function performBuy(
        address[21] orderAddresses, // conversion path (max length 21)
        uint256[6] orderValues, // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
        uint256 exchangeFee, // ignore
        uint256 amountToFill, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external payable returns (uint256) {
        return trade(orderAddresses, orderValues);
    }

    function performSell(
        address[21] orderAddresses, // conversion path (max length 21)
        uint256[6] orderValues, // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
        uint256 exchangeFee, // ignore
        uint256 amountToFill, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external returns (uint256) {
        return trade(orderAddresses, orderValues);
    }

    function trade(
        address[21] orderAddresses, // conversion path (max length 21)
        uint256[6] orderValues // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
    ) internal returns (uint256) {
        // Find the length of the conversion path
        uint256 len = 0;
        for(; len < orderAddresses.length; len++) {
            if(orderAddresses[len] == 0) {
                break;
            }
        }
        // Create an array of that length
        address[] memory conversionPath = new address[](len);

        // Move the contents from orderAddresses to conversionPath
        for(uint256 i = 0; i < len; i++) {
            conversionPath[i] = orderAddresses[i];
        }

        return exchange.quickConvert.value(msg.value)(conversionPath, orderValues[0], orderValues[1]);
    }

    function() public payable {
        // require(msg.sender == bancorQuickConvertAddress);
    }
}