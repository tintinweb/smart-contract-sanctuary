// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract DummyImplementation {

    function enableProtocol(address protocol_) public {}

    function disableProtocol(address protocol_) public {}

    function setSupplyLimits(address protocol_, address token_, uint amount_) public {}

    function setBorrowLimits(address protocol_, address token_, uint amount_) public {}

}