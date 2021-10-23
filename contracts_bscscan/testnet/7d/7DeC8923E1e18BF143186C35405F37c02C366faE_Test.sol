pragma solidity ^0.8.0;

contract Test{
    uint public eamount = 0;
    receive() payable external{

    }

    function testsend(address to, uint amount) public{
        (bool success, ) = payable(to).call{value:amount}("");
        eamount = amount;
    }
}