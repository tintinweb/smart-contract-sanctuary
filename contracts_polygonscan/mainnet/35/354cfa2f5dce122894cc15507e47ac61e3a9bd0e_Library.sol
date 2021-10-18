/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Library {
    
    mapping(uint256 => mapping(uint256 => string)) private book;
    mapping(uint256 => uint256) private lastPage;
    mapping(address => uint256) private _bookIndexNrs;

    uint256 private bookIndexnr;

    function writeBook(string memory newPage) public {
        if(_bookIndexNrs[msg.sender] == 0) {
            bookIndexnr ++;
            _bookIndexNrs[msg.sender] = bookIndexnr;
        }
        lastPage[_bookIndexNrs[msg.sender]] ++;
        book[_bookIndexNrs[msg.sender]][lastPage[_bookIndexNrs[msg.sender]]] = newPage;
    }
    
    function _readBooks(uint256 bookindexnr_, uint256 page_) public view returns (string memory) {
        return book[bookindexnr_][page_];
    }
    
    function getBookIndexNr(address Writer) public view returns (uint256) {
        return _bookIndexNrs[Writer];
    }

    function numberOfBooksStarted() public view returns (uint256) {
        return bookIndexnr;
    }
}