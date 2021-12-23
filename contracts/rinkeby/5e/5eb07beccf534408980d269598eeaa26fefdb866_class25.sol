/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

pragma solidity ^0.4.24;
contract class25{    
    mapping(address=>uint) public balances;
    uint public abc=0;
    function () public payable {
        //不能對此合約發送以太
        abc++;
    }
    // function () public payable{
    //     //可以對此合約發送以太
    // }
    
    function sendEther()public payable{
        balances[msg.sender] += msg.value;
    }

    function sendEtherNoPayable()public{
        balances[msg.sender] += msg.value;
    }

    //無名方法
    //payable
    //兩種方法return
}