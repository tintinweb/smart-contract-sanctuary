pragma solidity ^0.4.24;

contract receiveandforward{
    function () external payable{} // needed to receive p3d divs
    function forward(address other) public payable{
        other.transfer(address(this).balance);
    }
    
}