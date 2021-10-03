/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract EtherCasino {
    address admin;
    uint256 session;

    modifier onlyAdmin() {
        require(msg.sender == admin, "You're not an admin.");
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function setSession(uint256 _session) public payable {
        session = _session;
    }

    function getSession() public view returns (uint256) {
        return session;
    }
}