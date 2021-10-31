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
    
    function readBookFirst10Pages(uint256 BookNumber) public view returns (string memory) {
        string memory page1 = bookz._readBooks(BookNumber, 1);
        string memory page2 = bookz._readBooks(BookNumber, 2);
        string memory page3 = bookz._readBooks(BookNumber, 3);
        string memory page4 = bookz._readBooks(BookNumber, 4);
        string memory page5 = bookz._readBooks(BookNumber, 5);
        string memory page6 = bookz._readBooks(BookNumber, 6);
        string memory page7 = bookz._readBooks(BookNumber, 7);
        string memory page8 = bookz._readBooks(BookNumber, 8);
        string memory page9 = bookz._readBooks(BookNumber, 9);
        string memory page10 = bookz._readBooks(BookNumber, 10);
        return string(abi.encodePacked
            (
                page1, page2, page3, page4, page5,
                page6, page7, page8, page9, page10));
    }
    
    function readBookSecond10Pages(uint256 BookNumber) public view returns (string memory) {
        string memory page11 = bookz._readBooks(BookNumber, 11);
        string memory page12 = bookz._readBooks(BookNumber, 12);
        string memory page13 = bookz._readBooks(BookNumber, 13);
        string memory page14 = bookz._readBooks(BookNumber, 14);
        string memory page15 = bookz._readBooks(BookNumber, 15);
        string memory page16 = bookz._readBooks(BookNumber, 16);
        string memory page17 = bookz._readBooks(BookNumber, 17);
        string memory page18 = bookz._readBooks(BookNumber, 18);
        string memory page19 = bookz._readBooks(BookNumber, 19);
        string memory page20 = bookz._readBooks(BookNumber, 20);
        return string(abi.encodePacked
            (
                page11, page12, page13, page14, page15,
                page16, page17, page18, page19, page20));
    }
    
    function readBookThird10Pages(uint256 BookNumber) public view returns (string memory) {
        string memory page21 = bookz._readBooks(BookNumber, 21);
        string memory page22 = bookz._readBooks(BookNumber, 22);
        string memory page23 = bookz._readBooks(BookNumber, 23);
        string memory page24 = bookz._readBooks(BookNumber, 24);
        string memory page25 = bookz._readBooks(BookNumber, 25);
        string memory page26 = bookz._readBooks(BookNumber, 26);
        string memory page27 = bookz._readBooks(BookNumber, 27);
        string memory page28 = bookz._readBooks(BookNumber, 28);
        string memory page29 = bookz._readBooks(BookNumber, 29);
        string memory page30 = bookz._readBooks(BookNumber, 30);
        return string(abi.encodePacked
            (
                page21, page22, page23, page24, page25,
                page26, page27, page28, page29, page30));
    }

    function readBookFourth10Pages(uint256 BookNumber) public view returns (string memory) {
        string memory page31 = bookz._readBooks(BookNumber, 31);
        string memory page32 = bookz._readBooks(BookNumber, 32);
        string memory page33 = bookz._readBooks(BookNumber, 33);
        string memory page34 = bookz._readBooks(BookNumber, 34);
        string memory page35 = bookz._readBooks(BookNumber, 35);
        string memory page36 = bookz._readBooks(BookNumber, 36);
        string memory page37 = bookz._readBooks(BookNumber, 37);
        string memory page38 = bookz._readBooks(BookNumber, 38);
        string memory page39 = bookz._readBooks(BookNumber, 39);
        return string(abi.encodePacked
            (
                page31, page32, page33, page34, page35,
                page36, page37, page38, page39));
   }
  
   function readBookFifth10Pages(uint256 BookNumber) public view returns (string memory) {
        string memory page41 = bookz._readBooks(BookNumber, 41);
        string memory page42 = bookz._readBooks(BookNumber, 42);
        string memory page43 = bookz._readBooks(BookNumber, 43);
        string memory page44 = bookz._readBooks(BookNumber, 44);
        string memory page45 = bookz._readBooks(BookNumber, 45);
        string memory page46 = bookz._readBooks(BookNumber, 46);
        string memory page47 = bookz._readBooks(BookNumber, 47);
        string memory page48 = bookz._readBooks(BookNumber, 48);
        string memory page49 = bookz._readBooks(BookNumber, 49);
        return string(abi.encodePacked
            (
                page41, page42, page43, page44, page45,
                page46, page47, page48, page49));
   }
}