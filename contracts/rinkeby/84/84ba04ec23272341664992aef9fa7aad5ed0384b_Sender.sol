/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity >=0.8.2;
contract Sender {
    address private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function updateOwner(address newOwner) public {
        require(msg.sender == owner, "only current owner can update owner");
        owner = newOwner;
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
}