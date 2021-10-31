/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Book {

    constructor(string memory message_) {
    PublicMessage =  message_;       
    }

    mapping(uint256 => mapping(uint256 => string)) private _books;
    mapping(uint256 => uint256) private _lastPage;
    mapping(address => uint256) private _bookIDs;
    mapping(uint256 => address) private _writers;
    mapping(uint256 => string) private _message;

    string private PublicMessage;

    uint256 private bookNr;
    uint256 private messageNr;
    uint256 private promoBook;
    uint256 private promoPage;
    uint256 private lockTime;

    function _writeBook(string memory NewPage) public {
        if (_bookIDs[msg.sender] == 0) {
            bookNr ++;
            _bookIDs[msg.sender] = bookNr;
            _writers[bookNr] = msg.sender;
        }
        _lastPage[_bookIDs[msg.sender]] ++;
        _books[_bookIDs[msg.sender]][_lastPage[_bookIDs[msg.sender]]] = NewPage;
    }

    function _readBook(uint256 BookID, uint256 PageNr) public view returns (string memory) {
        return _books[BookID][PageNr];
    }

    function _readFivePagesFromBook(uint256 BookID, uint256 fromPageNr) public view returns (string memory) {
        return string(abi.encodePacked
        (
            _books[BookID][fromPageNr],
            _books[BookID][fromPageNr + 1],
            _books[BookID][fromPageNr + 2],
            _books[BookID][fromPageNr + 3],
            _books[BookID][fromPageNr + 4]
         ));
    }

    function _PromotedPage() public view returns (string memory) {
        return _books[promoBook][promoPage];
    }

    function setPromotedPage(uint256 BookID, uint256 PageNr) public {
        require(block.timestamp > lockTime , "Wait one day");
        promoBook = BookID;
        promoPage = PageNr;
        lockTime = block.timestamp + 24 hours;
    }

    function howManyPagesHasBook(uint256 BookID) public view returns (uint256) {
        return _lastPage[BookID];
    }

    function _writeMessage(string memory text) public {
        messageNr ++;
        _message[messageNr] = text;
    }

    function _readMessages(uint256 MessageNr) public view returns (string memory) {
        return _message[MessageNr];
    }

    function getBookNumber(address Writer) public view returns (uint256) {
        return _bookIDs[Writer];
    }

    function numberOfBooksStarted() public view returns (uint256) {
        return bookNr;
    }

    function numberOfMessages() public view returns (uint256) {
        return messageNr;
    }

    function donateWriter(uint256 BookID) public payable {
        payable(_writers[BookID]).transfer(msg.value);
    }

    function _PublicMessage() public view returns (string memory) {
        return PublicMessage;
    }

    function zlocktime() public view returns (uint256) {
        return lockTime;
    }
}