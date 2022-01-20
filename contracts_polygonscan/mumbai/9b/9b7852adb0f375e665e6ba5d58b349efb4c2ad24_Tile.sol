/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity ^0.5.2;

contract Tile {
    mapping (address => bool) contractors;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    function getContractor(address _addr) public view returns(bool) {   
        return contractors[_addr];
    }

    function addContractor(address _addr) public {
        require(owner == msg.sender, "You are not an owner!");
        contractors[_addr] = true;
    }
}