/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity >=0.7.0 <0.9.0;

contract OhSMS {
    
    address private owner;
    event Payment(uint256 amount, string refid);
    
    constructor() {
        owner = msg.sender;
    }
    
    function pay(string memory _refid) public payable {
        payable(owner).transfer(msg.value);
        emit Payment(msg.value, _refid);
    }
}