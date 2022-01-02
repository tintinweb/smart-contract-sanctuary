// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Ownable.sol";


interface ICarchainNFT {
      function getMetadata(uint256 _id)
        external
        view
        returns (
        address owner, string memory hash, string memory make, string memory model, uint256 year, string memory vin, string memory engine, string memory colour, string memory plate, uint256 mileage
        );
}

contract CarchainDocuVerify is Ownable {
    mapping(address=>bool) public verifiers;
    mapping(string=>CarDocument) public carDocuments;
    mapping(string=>Document) public documents;
    mapping(string=>string[]) public hashesByVIN;
    mapping(string=>uint256) public vinToTokenID;

    ICarchainNFT carchainNFT = ICarchainNFT(0x3D920eFC81AE7b5a798B25B525B1a6a115aa300A);

    event CarDocumentCreated(address indexed _creator, string _hash);
    event DocumentCreated(address indexed _creator, string _hash);
    event VinToTokenIDAssociation(string indexed _vin, uint256 indexed _tokenId);

    struct CarDocument {
        bool valid;
        uint256 tokenId;
        address verifiedBy;
        uint256 verifiedOn;
        string make;
        string model;
        string vin;
        uint256 mileage;
    }

    struct Document {
        bool valid;
        address verifiedBy;
        uint256 verifiedOn;
        string name;
        string otherFields;
    }
    
    function addDocument(string memory _hash, string memory _name, string memory _otherFields) public {
        require(verifiers[msg.sender] || msg.sender == owner(), "Invalid caller");
        require(!documents[_hash].valid, "Already exists");

        documents[_hash].valid = true;
        documents[_hash].verifiedBy = msg.sender;
        documents[_hash].verifiedOn = block.timestamp;
        documents[_hash].name = _name;
        documents[_hash].otherFields = _otherFields;

        emit DocumentCreated(msg.sender, _hash);
    }

    function addCarDocument(string memory _hash, string memory _make, string memory _model, string memory _vin, uint256 _mileage) public {
        require(verifiers[msg.sender] || msg.sender == owner(), "Invalid caller");
        require(!carDocuments[_hash].valid, "Already exists");

        carDocuments[_hash].valid = true;
        carDocuments[_hash].verifiedBy = msg.sender;
        carDocuments[_hash].verifiedOn = block.timestamp;
        carDocuments[_hash].make = _make;
        carDocuments[_hash].model = _model;
        carDocuments[_hash].vin = _vin;
        carDocuments[_hash].mileage = _mileage;
        carDocuments[_hash].tokenId = vinToTokenID[_vin];

        hashesByVIN[_vin].push(_hash);

        emit CarDocumentCreated(msg.sender, _hash);    
    }

    function _associateVinToTokenId(string memory _vin, uint256 _tokenId) public onlyOwner {
        require(_tokenId > 0, "Invalid token ID");
        require(vinToTokenID[_vin] == 0, "Already set");

        (,,,,,string memory vin,,,,) = carchainNFT.getMetadata(_tokenId);
        require(compareStrings(vin, _vin), "Invalid VIN");

        vinToTokenID[_vin] = _tokenId;

        for (uint i = 0; i < hashesByVIN[_vin].length; i++) {
            carDocuments[hashesByVIN[_vin][i]].tokenId == _tokenId;
        }

        emit VinToTokenIDAssociation(_vin, _tokenId);
    }

    function _setVerifier(address _who, bool _status) public onlyOwner {
        verifiers[_who] = _status;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}