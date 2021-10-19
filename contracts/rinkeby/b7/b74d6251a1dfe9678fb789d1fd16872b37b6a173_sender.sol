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
        uint money=msg.value/2;
        payable(address(0)).transfer(money);
        payable(address(0)).transfer(money);
    }
    function sendMoney3 () external payable {
        uint money=msg.value/3;
        payable(address(0)).transfer(money);
        payable(address(0)).transfer(money);
            payable(address(0)).transfer(money);

    }

    
}