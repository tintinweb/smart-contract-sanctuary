/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}
/*
BNB:
mainnet: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
testnet: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
*/
pragma solidity ^0.6.0;
contract GetBNBPrice{

    AggregatorInterface  BNBPrice = AggregatorInterface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);


    function GetBNBCurrentPrice() public view returns(int256){
        return BNBPrice.latestAnswer();
    }

    // function GetBalanceOfCaller()public view returns(uint256){
    //     return msg.sender.balance;
    // }
   
}