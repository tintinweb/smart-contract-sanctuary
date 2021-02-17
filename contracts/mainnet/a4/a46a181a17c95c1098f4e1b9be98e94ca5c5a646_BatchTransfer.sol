/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.4.26;
contract BatchTransfer {
    address private owner;
    constructor() {
        owner = msg.sender;
    }
    function () public payable {
    }
    function sendBatch(address[] addreses, uint256[] values) public payable {
        require(msg.sender == owner);
        for(uint i = 0; i < addreses.length; i++) {
            addreses[i].transfer(values[i]);
        }
    }
}