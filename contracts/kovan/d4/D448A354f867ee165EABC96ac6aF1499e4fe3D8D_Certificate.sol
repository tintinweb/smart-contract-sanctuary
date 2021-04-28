/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract Certificate {
    struct Cert {
        string ipfsHash;
        string url;
        string issuedBy;
    }

    mapping(address => Cert) certificates;

    function setCertificate(
        address _address,
        string memory _ipfsHash,
        string memory _url,
        string memory _issuedBy
    ) public {
        certificates[_address] = Cert(_ipfsHash, _url, _issuedBy);
    }

    function getCertificate(address _address)
        public
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        return (
            certificates[_address].ipfsHash,
            certificates[_address].url,
            certificates[_address].issuedBy
        );
    }
}