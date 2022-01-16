/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.11;
interface IWBNB {function balanceOf(address owner) external pure returns (uint256);}
interface IBUSD {
    function approve(address spender,uint256 amount) external pure returns (uint256);
    }

contract viewSALDO {
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    IWBNB public _wbnb = IWBNB(WBNB);
    IBUSD public _busd = IBUSD(BUSD);

    mapping(address => uint256) balWBNB;

    function balanceWBNB(address owner) public view returns (uint256) {
        _wbnb.balanceOf(owner);
        return balWBNB[owner];
    }

    function approveBUSD(address spender, uint256 amount) public view returns(bool){
        _busd.approve(spender, amount);
        return true;
    }

}