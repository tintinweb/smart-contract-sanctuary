pragma solidity ^0.8.1;
contract Hello{
    constructor(){}
    function test() public view returns(address){
        return msg.sender;
    }
}