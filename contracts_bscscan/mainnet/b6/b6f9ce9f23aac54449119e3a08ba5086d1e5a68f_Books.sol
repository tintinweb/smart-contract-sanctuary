/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

contract Books {
    
    constructor(string memory PM) {
        pM = PM;
    }
    
    mapping(uint256 => mapping(uint256 => string)) private _books;
    mapping(uint256 => uint256) private _lastPage;
    mapping(address => uint256) private _bookNrs;
    mapping(uint256 => address) private _writers;
    mapping(uint256 => string) private _message;
    
    string private pM;

    uint256 private bookNr;
    uint256 private messageNr;

    function _writeBook(string memory NewPage) public {
        if (_bookNrs[msg.sender] == 0) {
            bookNr ++;
            _bookNrs[msg.sender] = bookNr;
            _writers[bookNr] = msg.sender;
        }
        _lastPage[_bookNrs[msg.sender]] ++;
        _books[_bookNrs[msg.sender]][_lastPage[_bookNrs[msg.sender]]] = NewPage;
    }
    
    function _readBooks(uint256 BookNr, uint256 PageNr) public view returns (string memory) {
        return _books[BookNr][PageNr];
    }
    
    function _writeMessage(string memory text) public {
        _message[messageNr] = text;
    }
    
    function _readMessages(uint256 MessageNr) public view returns (string memory) {
        return _message[MessageNr];
    }
    
    function getBookNumber(address Writer) public view returns (uint256) {
        return _bookNrs[Writer];
    }

    function numberOfBooksStarted() public view returns (uint256) {
        return bookNr;
    }
    
    function numberOfMessages() public view returns (uint256) {
        return messageNr;
    }
    
    function donateWriter(uint256 BookNumber) public payable {
        payable(_writers[BookNumber]).transfer(msg.value);
    }
    
    function _publicMessage() public view returns (string memory) {
        return pM;
    }
}