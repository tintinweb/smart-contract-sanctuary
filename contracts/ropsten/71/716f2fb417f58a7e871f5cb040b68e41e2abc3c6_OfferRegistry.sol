/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract OfferRegistry {
    constructor() {

    }

    address _factoryAddress = 0xc21397C51fb05304d00BA93b7c603F390F16BCD3;
    address _studioAddress = 0xa5EDeaeCF39E0D4bD9295c9F840c49ACFE9D6691;

    // offer related mappings
    mapping(string => uint256) public _currentOfferOnPiece;        // pieceId / value of offer
    mapping(string => address) public _currentOfferOwner;          // pieceId / wallet address of person owning the offer

    // piece ownership register
    mapping(string => address) public _currentOwnerOfPiece;        // pieceId / owning wallet address
    mapping(string => address) public _pieceCreator;               // pieceId / creators address
    // minting register
    mapping(string => address) public _pieceContractAddress;       // pieceId / NFT address


    function setFactoryAddress(address newAddress) public {
        require(msg.sender == _studioAddress, "Address not valid for function usage");
        _factoryAddress = newAddress;
    }

    function getCurrentOfferAmount(string memory pieceId) public view returns (uint256 offerAmount) {
        return(_currentOfferOnPiece[pieceId]);
    }

    function getCurrentOfferOwner(string memory pieceId) public view returns (address offerOwner) {
        return(_currentOfferOwner[pieceId]);
    }

    function getCurrentOwnerOfPiece(string memory pieceId) public view returns (address currentOwner) {
        return(_currentOwnerOfPiece[pieceId]);
    }

    function getCreatorAddress(string memory pieceId) public view returns (address currentCreator) {
        return(_pieceCreator[pieceId]);
    }

    function getPieceContractAddress(string memory pieceId) public view returns (address pieceContractAddress) {
        return(_pieceContractAddress[pieceId]);
    }

    function setPieceCurrentOwner(string memory pieceId, address newOwner) public {
        require(msg.sender == _currentOwnerOfPiece[pieceId] || msg.sender == _studioAddress || msg.sender == _factoryAddress, "Address not valid for function usage");
        require(newOwner != address(0),"Zero address not valid assignee");
        _currentOwnerOfPiece[pieceId] = newOwner;
    }

    function setPieceCreator(string memory pieceId, address newCreator) public {
        require(msg.sender == _pieceCreator[pieceId] || msg.sender == _studioAddress, "Address not valid for function usage");
        _pieceCreator[pieceId] = newCreator;
    }

    function setPieceContractAddress(string memory pieceId, address newAddress) public {
        // this func is a last resort safety net
        require(msg.sender == _studioAddress, "Address not valid for function usage");
        _pieceContractAddress[pieceId] = newAddress;
    }

    function setPieceOfferAmount(string memory pieceId, uint256 amount) public {
        require(msg.sender == _studioAddress || msg.sender == _factoryAddress, "Address not valid for function usage");
        _currentOfferOnPiece[pieceId] = amount;

    }

    function setPieceOfferOwner(string memory pieceId, address newOfferOwner) public {
        require(msg.sender == _studioAddress || msg.sender == _factoryAddress, "Address not valid for function usage");
        _currentOfferOwner[pieceId] = newOfferOwner;
    }
}