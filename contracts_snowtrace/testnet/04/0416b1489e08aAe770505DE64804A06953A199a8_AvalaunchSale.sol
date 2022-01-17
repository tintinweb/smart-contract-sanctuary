/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract AvalaunchSale {
    
    address _saleToken;

    function setSaleToken(
        address saleToken
    )
    external
    {
        _saleToken = saleToken;
    }
}