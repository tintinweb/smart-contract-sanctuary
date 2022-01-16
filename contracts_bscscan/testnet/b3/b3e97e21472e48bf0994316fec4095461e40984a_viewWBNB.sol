/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.11;
interface IWBNB {function balanceOf(address owner) external returns (uint256);}
contract viewWBNB {
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IWBNB public _wbnb = IWBNB(WBNB);

    mapping(address => uint256) balWBNB;

    function balanceWBNB(address owner) public returns (uint256 balance) {
        _wbnb.balanceOf(owner);
        return balWBNB[owner];
    }
}