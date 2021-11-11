/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

pragma solidity ^0.4.24;

contract CommunityBank {
    
    address private admin = 0xB6b0E7Bfafd4bcf7B8D964aeb8c1D1F5b2A22ade;

    constructor() public {
        admin = msg.sender;
    }

    function deposit() public payable {

    }

    function withdraw() public {
        require(msg.sender == admin, "Only admin");

        msg.sender.transfer(address(this).balance);
    }

    function setAdmin(address newAdmin) public {
        require(msg.sender == admin, "Only admin");

        admin = newAdmin;
    }
}