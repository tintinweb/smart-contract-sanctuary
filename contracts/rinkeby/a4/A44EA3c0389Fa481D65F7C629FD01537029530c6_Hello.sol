pragma solidity 0.8.0;

contract Hello {

    constructor(){

    }

    function test() public view returns(address){
       return msg.sender; 
    }
}