/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity >=0.4.4;


contract incoginto{
    
    mapping(address=>uint) public pbalance;
    mapping(address=>uint) public balance;
    function tranfer(address incognitoAddress) public payable {
    require(msg.value + address(this).balance <= 10**27 );
    pbalance[address(incognitoAddress)]+=msg.value;
    }


function withdraw(uint amount) public payable{

    require(amount <= pbalance[address(msg.sender)]);
     payable (msg.sender).transfer(amount);
    pbalance[msg.sender]-=amount;
}


}