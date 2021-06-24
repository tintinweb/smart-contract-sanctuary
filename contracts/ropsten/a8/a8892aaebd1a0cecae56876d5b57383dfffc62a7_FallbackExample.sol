/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FallbackExample {
    
    //event logFallback(string information);
    //event logBalance(uint balance);

    receive() external payable{
        //emit logFallback("receive Excuting");
        //emit logBalance(address(this).balance);
    }

    fallback()  external payable {
        
        //emit logFallback("fallbak Excuting");
        //emit logBalance(address(this).balance);
    }
   
    constructor() payable{}
    address[] addressLogs ;
    function Transfer_To_Contract(uint amount)  external {
        payable(address(this)).transfer(amount * 1 ether);
    }
    function Transfer_To_Msg(uint amount)  external {
        payable(msg.sender).transfer(amount * 1 ether);
    }
    
    function Get_C_MAddr() external returns(address[]  memory ){
       addressLogs.push(address(this));
       addressLogs.push(msg.sender);
       return addressLogs;
    }
}