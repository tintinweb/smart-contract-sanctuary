/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;



// File: CurriculumVitae.sol

// SPDX-License-Identifier: MIT


contract CurriculumVitae {
    address private provider;
    string[] certificates;

    mapping(address => string[]) addressToCertificates;
    event Awarded(address from, address to, string certificate);

    constructor() public {
        provider = msg.sender;
    }

    function awardCertificate(address _recipient, string memory certificate) public {
        addressToCertificates[_recipient].push(certificate);
        emit Awarded(provider, _recipient, certificate);
    }

    function certificatesOf(address owner) public view returns (string[] memory _certificates)  { 
        return addressToCertificates[owner];
    }

}