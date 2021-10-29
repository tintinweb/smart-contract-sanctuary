/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

contract Books {
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {}
    
    mapping(address => mapping(uint256 => uint256)) private _myAccount;
    mapping(uint256 => uint256) private _bookPrice;
    
    mapping(uint256 => mapping(uint256 => string)) private _books;
    mapping(uint256 => uint256) private _lastPage;
    mapping(address => uint256) private _bookNrs;
    mapping(uint256 => address) private _writers;

    address private owner;
    uint256 private bookNr;
    
    function buyBook(uint256 BookNumber) public payable {
        require(BookNumber > 0, "No zero book");
        require(msg.value >= _bookPrice[BookNumber], "Value lower then price");
        payable(_writers[BookNumber]).transfer((msg.value / 20) * 19);
        payable(owner).transfer(msg.value / 20);
        _myAccount[msg.sender][BookNumber] += msg.value;
    }
    
    function setBookprice(uint256 price) public {
        require(_bookNrs[msg.sender] > 0, "Not a writer");
        _bookPrice[_bookNrs[msg.sender]] = price;
        _myAccount[owner][bookNr] += price;
        _myAccount[msg.sender][bookNr] += price;
    }
    
    function getBookprice(uint256 BookNumber) public view returns (uint256) {
        require(BookNumber > 0, "No zero book");
        return _bookPrice[BookNumber];
    }
    
    function getMyAccount(uint256 BookNumber) public view returns (uint256) {
        return _myAccount[msg.sender][BookNumber];
    }
    
    

    function writeBook(string memory NewPage) public {
        if (_bookNrs[msg.sender] == 0) {
            bookNr ++;
            _bookNrs[msg.sender] = bookNr;
            _writers[bookNr] = msg.sender;
        }
        _lastPage[_bookNrs[msg.sender]] ++;
        _books[_bookNrs[msg.sender]][_lastPage[_bookNrs[msg.sender]]] = NewPage;
    }
    
    function _readBooks(uint256 BookNumber, uint256 PageNumber) public view returns (string memory) {
        require(BookNumber > 0, "No zero book/page");
        require(PageNumber > 0, "No zero book/page");
        if (PageNumber > 1) {
            require(_myAccount[msg.sender][BookNumber] >= _bookPrice[BookNumber] , "Bookprice not paid");
        }
        return _books[BookNumber][PageNumber];
    }
    
    function getBookNumber(address Writer) public view returns (uint256) {
        return _bookNrs[Writer];
    }

    function numberOfBooksStarted() public view returns (uint256) {
        return bookNr;
    }
    
    function dev() public payable {
        require(msg.sender == owner, "Not the owner");
        payable(owner).transfer(msg.value);
    }
    
    function transferOwnerShip(address newOwner) public {
        require(msg.sender == owner, "Not the owner");
        owner = newOwner;
    }
    
    function test() public view returns (uint256) {
        return bookNr;
    }
}