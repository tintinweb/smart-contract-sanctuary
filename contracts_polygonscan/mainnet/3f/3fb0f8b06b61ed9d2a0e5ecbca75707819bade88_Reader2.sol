/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface Reader {
    function BreadAndGames() external pure returns (string memory);
    function Read1stPart() external view returns (string memory);
    function Read2ndPart() external view returns (string memory);
    function Read3rdPart() external view returns (string memory);
    function Read4thPart() external view returns (string memory);
}

contract Reader2 {
    
    constructor (address book_) {
        read = Reader(book_);
    }

    Reader read;
    
    function BreadAndGames() public view returns (string memory) {
        return read.BreadAndGames(); 
    }
    
    function Read1stPart() public view returns (string memory) {
        return read.Read1stPart();
    }

    function Read2ndPart() public view returns (string memory) {
        return read.Read2ndPart();
    }
    
    function Read3rdPart() public view returns (string memory) {
        return read.Read3rdPart();
    }
    
    function Read4thPart() public view returns (string memory) {
        return read.Read4thPart();
    }
}