// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0 ;

import "./IPublicLock.sol";

contract ReservationContract
{
    IPublicLock public publicLock;

    constructor() public{
        publicLock = IPublicLock(0x9D3BAd7746Df8941d88377f65edE7f5F42c88e1b);
    }

    function createReservation() external payable
    {
        publicLock.purchase(publicLock.keyPrice(), msg.sender, address(0), "");
    }
}