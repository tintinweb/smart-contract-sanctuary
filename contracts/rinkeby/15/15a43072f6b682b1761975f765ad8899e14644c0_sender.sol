/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.8.0;

contract sender {
    function sendMoney () external payable {
        //payable(address(0)).transfer(msg.value);
    }
     function sendMoney1 () external payable {
        payable(address(0)).transfer(msg.value);
    }    
    function sendMoney2 () external payable {
        payable(address(0)).transfer(msg.value);
            payable(address(1)).transfer(msg.value);

        
    }  

    
}