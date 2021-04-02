/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract book1{
    // 一個名稱為list的mapping 用來記錄目前的操作者是否為合法的使用者
    mapping(address => bool) list;
    // mapping 設值
    function set(bool isLeagl) public {
        list[msg.sender] = isLeagl;
    }
    function get() public view returns(bool){
        return list[msg.sender];
    }
    
    struct Book{
        uint isbn;
        string name;
        uint price;
    }
    // 書本清單 (使用isbn當作key)
    mapping (uint => Book)books;
    // 新增Book 至 books裡
    function createBook(uint _isbn, string memory _name, uint _price) public {
        books[_isbn] = Book(_isbn, _name, _price);
    }
    // 用isbn去books把Book找出來
    function getBook(uint _isbn)public view returns(Book memory){
        return books[_isbn];
    }
    // 用isbn把去books找出目標書本Book的價格
    function getBookPrice(uint _isbn)public view returns(uint){
        return books[_isbn].price;
    }
}