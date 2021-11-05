// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./Ownable.sol";

contract Storage is Ownable{

    // ipfs peer address
    string public peerAddress;

    // user to year to farming input
    mapping (string => mapping (uint => string)) farmerToYearToDocumentHash;

    event PeerAddressUpdated(string peerAddress);
    event CIResultStored(string indexed farmer, uint indexed year, string fileHash);

    function addCIResult (string memory _farmer, uint _year, string memory _hash) public onlyOwner{
        farmerToYearToDocumentHash[_farmer][_year] = _hash;
        emit CIResultStored(_farmer, _year, _hash);
    }

    function getCIResult(string memory _farmer, uint _year) public view returns (string memory) {
        return farmerToYearToDocumentHash[_farmer][_year];
    }

    function setPeerAddress(string memory _peerAddress) public onlyOwner {
        peerAddress = _peerAddress;
        emit PeerAddressUpdated(peerAddress);
    }

}