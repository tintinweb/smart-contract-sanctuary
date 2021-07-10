// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICustomizable.sol";
import "./Address.sol";
import "./CustomizableERC1155.sol";

contract Customizable is ICustomizable, CustomizableERC1155 {
// #region function modifiers
    bool internal _deprecated;
    modifier notDeprecated () {
        require (!_deprecated, "Contract is deprecated, no new tokens can be minted");
        _;
    }

    modifier ownerOnly () {
        require (msg.sender == _owner, "Owner only method called by non-owner");
        _;
    }

    modifier approvedListOnly () {
        require ((msg.sender == _owner) || (_approvedList[msg.sender] == true), "ApprovedList only method called by non-approved");
        _;
    }

// #region constructor & ownerOnly functions
    constructor() {
        require(_owner == msg.sender, "_owner not msg.sender");
        _deprecated = false;
    }

    function setDeprecated(bool deprecated) external override ownerOnly {
        _deprecated = deprecated;
    }

    function setOwner(address newOwnerAddress) external override ownerOnly {
        _owner = newOwnerAddress;
    }

    function addToApprovedList(address addressToAdd) external override ownerOnly notDeprecated {
        if (_approvedList[addressToAdd] != true) {
            _approvedList[addressToAdd] = true;
        }
    }

    function removeFromApprovedList(address addressToRemove) external override ownerOnly {
        if (_approvedList[addressToRemove] != false) {
            _approvedList[addressToRemove] = false;
        }
    }

    function createType(uint256 typeId, string memory uri) external override ownerOnly notDeprecated {
        require ((bytes(uri).length > 0), "uri is not valid");
        require (_allTypes[typeId].length == 0, "type already exists");
    
        _allTypes[typeId] = bytes(uri);
        emit TransferSingle(msg.sender, address(0x0), address(0x0), typeId, 0);
        emit URI(uri, typeId);
    }

    function updateType(uint256 typeId, string memory uri) external override ownerOnly {
        require (bytes(uri).length > 0, "uri is not valid");
        require (_allTypes[typeId].length > 0, "type doesn't exist");

        _allTypes[typeId] = bytes(uri);
        emit URI(uri, typeId);
    }

// #region token functions
    function mintNFT(uint256 typeId, address toAddress, string memory uri) external override approvedListOnly notDeprecated {
        require (_allTypes[typeId].length > 0, "type doesn't exist");
        require (toAddress != address(0x0), "to Address isn't valid");
        require (bytes(uri).length > 0, "uri is not valid");

        uint256 nftId = typeId << 128 | _nonce++;
        _nftOwners[nftId] = toAddress;
        _uris[nftId] = bytes(uri);

        emit TransferSingle(msg.sender, address(0x0), toAddress, nftId, 1);
        emit URI(uri, nftId);

        if (Address.isContract(toAddress)) {
            _doSafeTransferAcceptanceCheck(msg.sender, address(0x0), toAddress, nftId, 1, '');
        }
    }

    function burnNFT(uint256 nftId) external override {
        require (_nftOwners[nftId] == msg.sender, "msg.sender is not owner");

        delete _nftOwners[nftId];

        emit TransferSingle(msg.sender, msg.sender, address(0x0), nftId, 1);
    }

    function mintFT(uint256 typeId, string memory uri, uint256 quantity) external override approvedListOnly notDeprecated {
        require (_allTypes[typeId].length > 0, "type doesn't exist");
        require (bytes(uri).length > 0, "uri is not valid");

        uint256 ftId = typeId << 128 | _nonce++;
        _ftOwners[ftId][msg.sender] = quantity;
        _uris[ftId] = bytes(uri);

        emit TransferSingle(msg.sender, address(0x0), msg.sender, ftId, quantity);
        emit URI(uri, ftId);

        if (Address.isContract(msg.sender)) {
            _doSafeTransferAcceptanceCheck(msg.sender, address(0x0), msg.sender, ftId, quantity, '');
        }
    }

    function burnFT(uint256 ftId, uint256 quantity) external override {
        require (_ftOwners[ftId][msg.sender] != 0, "msg.sender is not owner");
        require (quantity != 0, "quantity cannot be zero");
        require (_ftOwners[ftId][msg.sender] > quantity || _ftOwners[ftId][msg.sender] == quantity, "msg.sender owns less than quantity");

        _ftOwners[ftId][msg.sender] = (_ftOwners[ftId][msg.sender]-quantity);
        _ftOwners[ftId][address(0x0)] += quantity;
        emit TransferSingle(msg.sender, msg.sender, address(0x0), ftId, quantity);
    }

    function getTypeFromCustomizable(uint256 tokenId) external view override returns (uint256 typeId) {
        uint256 tokenType = tokenId >> 128;
        require (_allTypes[tokenType].length > 0, "tokenId doesn't contain a valid type");
        typeId = tokenType;
    }

    function updateTokenUri(uint256 tokenId, string memory uri) external override approvedListOnly {
        require (bytes(uri).length > 0, "uri is not valid");
        require (_uris[tokenId].length > 0, "tokenId does not exist");
        
        _uris[tokenId] = bytes(uri);
        emit URI(uri, tokenId);
    }

}