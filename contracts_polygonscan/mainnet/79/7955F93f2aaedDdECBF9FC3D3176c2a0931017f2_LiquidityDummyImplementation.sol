// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminModule {

    function enableProtocol(address protocol_) public {}

    function disableProtocol(address protocol_) public {}

    function setSupplyLimits(address protocol_, address token_, uint amount_) public {}

    function setBorrowLimits(address protocol_, address token_, uint amount_) public {}

}

contract ProtocolModule {

    function updateInterest(
        address token_
    ) public view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    ) {}

    function supply(
        address token_,
        uint amount_
    ) public returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {}

    function withdraw(
        address token_,
        uint amount_
    ) public returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {}

    function borrow(
        address token_,
        uint amount_
    ) public returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {}

    function payback(
        address token_,
        uint amount_
    ) public returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {}

}

contract ReadModule {

    function isProtocol(address protocol_) external view returns (bool) {}

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256) {}

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256) {}

    function totalSupplyRaw(address token_) external view returns (uint256) {}

    function totalBorrowRaw(address token_) external view returns (uint256) {}

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256) {}

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256) {}

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory) {}

}

contract LiquidityDummyImplementation is AdminModule, ProtocolModule, ReadModule {

    receive() external payable {}
    
}