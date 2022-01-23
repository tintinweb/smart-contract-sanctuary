/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Pptdeal{

    address public MyAddress;
    uint256 public Balance;
    address payable paytothis = payable(0x60c4fBD84213896dE8E6480c53Ea8922b577DcD0);
    

    constructor(){
        MyAddress = msg.sender;
    }

    receive() payable external{
        Balance = Balance + msg.value; 
    }

    function Approve (bool b) public {

        require(msg.sender == MyAddress,"Only Reddy can Approve this");
        require(100000000000000000<=Balance,"Insufficient Funds");

        if (b = true){
                paytothis.transfer(100000000000000000);
                Balance = Balance - 100000000000000000;
        }



    }
  

}