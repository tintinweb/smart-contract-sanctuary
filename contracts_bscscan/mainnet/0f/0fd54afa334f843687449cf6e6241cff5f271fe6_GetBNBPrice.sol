/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}

contract GetBNBPrice{

    AggregatorInterface private BNBPrice;

    constructor() public{
        BNBPrice= AggregatorInterface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    }

    function GetBNBCurrentPrice() public view returns(int256){
        return BNBPrice.latestAnswer();
    }
   
}