pragma solidity ^0.8.0;

contract Test{
    receive() payable external{

    }
    
    function testsend(address to, uint amount) public{
        (bool success, ) = payable(to).call{value:amount}("");
    }
}