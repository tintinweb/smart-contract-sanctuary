/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library EarnHubLib {
    struct User {
        address _address;
        uint256 lastPurchase;
        bool isReferral;
        uint256 referralBuyDiscount;
        uint256 referralSellDiscount;
        uint256 referralCount;
    }

    enum TransferType {
        Sale,
        Purchase,
        Transfer
    }

    struct Transfer {
        User user;
        uint256 amt;
        TransferType transferType;
        address from;
        address to;
    }
}