/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity >=0.6.0 <0.7.0;

contract PiggyBank {
    
 
    address payable public  owner;
    constructor() public {
        owner = msg.sender;
    }
    receive ()  external  payable {
        require (msg.value == 1e18);
           }
    function howmuch () public view returns (uint) {
        require(msg.sender == owner);
        return address(this).balance;
    }
    function withdraw () public {
        require(msg.sender == owner);
        owner.transfer (address(this).balance);
    }
}