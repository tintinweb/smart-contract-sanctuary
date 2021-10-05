/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Library {
    
    // Requirements
    // Xây dựng mạng lưới library trong thành phố giúp quản lý sách 
    // trong từng thư viện
    
    // Struct 
    struct Book{
        string title;
        string author;
    }
    
    // Mappings
    mapping (address => mapping (uint => Book)) public libraryBooks;
    uint public bookCount;
    
    function addBookToLibrary(string memory _title, string memory _author) public{
        libraryBooks[msg.sender][bookCount] = Book(_title, _author);
        bookCount++;
    }    
}