/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract ERC721 is IERC721 {

    string private _name;
    string private _symbol;
    address contractOwner;

    mapping(uint256 => address) _owners;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    modifier limited() {
        require(msg.sender == contractOwner || _operatorApprovals[contractOwner][msg.sender], "you can not call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        contractOwner = msg.sender;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        require (owner != address(0), "balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public override view returns (address) {

        require(_owners[tokenId] != address(0), "owner query for non existent token");
        return _owners[tokenId];
    }
    function name() public view returns(string memory) {
        return _name;
    }
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    // function tokenURI(uint256 tokenId) public override view returns (string memory) {}
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override;
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override;
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from != address(0), "transfer from address 0");
        require(to != address(0), "transfer from address 0");
        require(_owners[tokenId] != address(0), "token does not exist");
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
    function approve(address to, uint256 tokenId) public override {
        address owner = _owners[tokenId];
        require(owner != address(0), "token does not exist");
        require(to != owner, "approval to current owner");
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender]
        , "approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;

        emit Approval(msg.sender, to, tokenId);
    }
    function setApprovalForAll(address operator, bool _approved) public override {
        require(operator != msg.sender, "approve to caller");
        
        _operatorApprovals[msg.sender][operator] = _approved;

        emit ApprovalForAll(msg.sender, operator, _approved);
    }
    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_owners[tokenId] != address(0), "token does not exist");

        return _tokenApprovals[tokenId];
    }
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function mint(address to, uint256 tokenId) public limited {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] ++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
}