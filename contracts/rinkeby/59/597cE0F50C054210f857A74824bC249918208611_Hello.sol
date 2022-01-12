pragma solidity 0.8.0;

contract Hello {
    function test() public view returns(address){
       return msg.sender; 
    }
}