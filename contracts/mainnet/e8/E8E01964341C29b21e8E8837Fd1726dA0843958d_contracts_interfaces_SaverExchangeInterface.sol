pragma solidity ^0.6.0;


abstract contract SaverExchangeInterface {
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        uint256 _exchangeType
    ) public view virtual returns (address, uint256);
}
