/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract RevocationRegistry {

    mapping(bytes32 => mapping(address => uint)) private revocations;

    function revoke(bytes32 digest) public {
        require (revocations[digest][msg.sender] == 0, "claim has been already revocated");
        revocations[digest][msg.sender] = block.number;
        emit Revoked(msg.sender, digest);
    }

    function revoked(address issuer, bytes32 digest) public view returns (uint) {
        return revocations[digest][issuer];
    }

    event Revoked(address issuer, bytes32 digest);
}