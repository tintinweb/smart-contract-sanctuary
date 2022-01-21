/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

pragma solidity ^0.8.7;


contract Blockmsg{

    mapping(address => mapping(uint => string)) private datas;
    mapping(address => uint) private userlen;

    function addUrl(string memory data) public{
        userlen[msg.sender] += 1;
        datas[msg.sender][userlen[msg.sender]] = data;

    }

    function showUrl(address addr, uint count) public view returns(string memory){
        return datas[addr][count];
    }




}