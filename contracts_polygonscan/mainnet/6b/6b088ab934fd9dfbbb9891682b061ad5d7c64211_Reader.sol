/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface Books {
    function _readBooks(uint256 BookNr, uint256 PageNr) external view returns (string memory);
}

contract Reader {
    
    constructor (address book_) {
        bookz = Books(book_);
    }

    Books bookz;

    function read3PagesFromBook(uint8 BookNumber, uint8 pageX, uint8 pageY, uint8 pageZ) public view returns (string memory) {
       
        string memory page1 = bookz._readBooks(BookNumber, pageX);
        string memory page2 = bookz._readBooks(BookNumber, pageY);
        string memory page3 = bookz._readBooks(BookNumber, pageZ);
        
        return string(abi.encodePacked(page1, page2, page3));
  }
}