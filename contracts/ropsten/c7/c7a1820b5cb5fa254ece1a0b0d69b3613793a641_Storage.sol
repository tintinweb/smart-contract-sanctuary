// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./Ownable.sol";

contract Storage is Ownable{

    // user to year to farming input
    mapping (string => mapping (uint => string)) farmerToYearToDocumentHash;

    event CIResultStored(string farmer, uint year, string fileHash);

    function addCIResult (string memory _farmer, uint _year, string memory _hash) public onlyOwner{
        farmerToYearToDocumentHash[_farmer][_year] = _hash;
        emit CIResultStored(_farmer, _year, _hash);
    }

    function getCIResult(string memory _farmer, uint _year) public view returns (string memory) {
        return farmerToYearToDocumentHash[_farmer][_year];
    }

}