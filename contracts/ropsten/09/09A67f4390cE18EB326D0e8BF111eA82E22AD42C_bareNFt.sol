/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract bareNFt {
    uint256 public totalsupply;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed _approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool _approved);

    mapping(address => uint256) public _balances;
    mapping(uint256 => address) public _owners;
    mapping(uint256 => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals;


    constructor() {
        _balances[msg.sender] = totalsupply;
        for(uint8 i = 0; i < 7; i++){
            _owners[i] = msg.sender;
        }
        totalsupply = 7;
    }

    // function balanceOf(address owner) public view returns(uint256){}
    // function ownerOf(uint256 tokenId) public view returns(address){}
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {}
    // function safeTransferFrom(address from, address to, uint256 tokenId) public {}
    function transferFrom(address from, address to, uint256 tokenId) public{
        require(from != address(0), "transfer from address 0");
        require(to != address(0), "transfer from address 0");
        require(tokenId < 7, "token dos not exist");
        require(from == _owners[tokenId], "address from is not the owner of tokenId");
        require(msg.sender == from || msg.sender == _tokenApprovals[tokenId] || _operatorApprovals[from][msg.sender]
        , "You are not the owner nor approved to transfer this tokenId");

        _tokenApprovals[tokenId] = address(0);
        emit Approval(from, address(0), tokenId);

        _balances[from] --;
        _balances[to] ++;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    function approve(address to, uint256 tokenId) public{
        require(tokenId < 7, "token dos not exist");
        address owner = _owners[tokenId];
        require(to != owner, "approval to current owner");
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender]
        , "approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;

        emit Approval(msg.sender, to, tokenId);
    }
    function setApprovalForAll(address operator, bool _approved) public{
        require(operator != msg.sender, "approve to caller");

        _operatorApprovals[msg.sender][operator] = _approved;

        emit ApprovalForAll(msg.sender, operator, _approved);
    }
    // function getApproved(uint256 tokenId) public view returns(address){}
    // function isApprovedForAll(address owner, address operator) public view returns(bool){}
}