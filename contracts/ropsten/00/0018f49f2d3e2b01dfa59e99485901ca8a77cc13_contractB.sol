/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity >=0.4.0 <0.7.0;

contract contractB {
    uint public b;
    uint public balance;

    constructor() public payable{
        balance = balance +msg.value;
    }

    function freeFunds(address payable receiver) external returns(bool){
        return receiver.send(balance);
    }
}