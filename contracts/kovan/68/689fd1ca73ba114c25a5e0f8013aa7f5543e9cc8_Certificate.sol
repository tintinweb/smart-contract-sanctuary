/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract Certificate {
    struct Cert {
        string ipfsHash;
        string url;
        string certificateId;
        string objectIdentifier;
        string objectIdentifierType;
        string objectType;
        string title;
        string artist;
        string issuedBy;
    }
    mapping(address => Cert) certificates;
    address[] public certificateAccts;

    function setCertificate(
        address _address,
        string memory _ipfsHash,
        string memory _url,
        string memory _issuedBy
    ) public {
        Cert memory certificate = certificates[_address];

        certificate.ipfsHash = _ipfsHash;
        certificate.url = _url;
        certificate.issuedBy = _issuedBy;

        certificateAccts.push(_address) - 1;
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