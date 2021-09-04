/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 token) external view returns(address owner);
    function balanceOf(address owner) external view returns(uint256 balance);
    //function safeTransferFrom(address from, address to, uint256 tokenId) external;
    //function safeTransferFrom(address from, address to, uint256 toeknId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId)external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovalForAll(address owner, address operator) external view returns(bool);
    
}

contract ERC721 is IERC721 {
    string private name;
    string private symbol;
    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenApproval;
    mapping(address => mapping(address => bool)) private operatorApproval;
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    function ownerOf(uint tokenId) public override virtual view returns(address) {
        require(owners[tokenId] != address(0), "Address is not Valid");
        return owners[tokenId];
    }
    function balanceOf(address owner) public override virtual view returns(uint256){
        require(owner != address(0), "Address is not valid");
        return balances[owner];
    }
    function setApprovalForAll( address operator, bool approved) public override virtual {
        require(msg.sender != operator, "Invalid Address");
        operatorApproval[msg.sender][operator] = approved;
    }
    function isApprovalForAll(address owner, address operator) public override view returns(bool) {
        return operatorApproval[owner][operator];
    }
    
    function approve(address approved, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovalForAll(owner, msg.sender), "you are not authorised");
        tokenApproval[tokenId] = approved;
        
    }
    function exists(uint256 tokenId) public view returns(bool) {
        return owners[tokenId] != address(0);
    }
    
    function getApproved(uint256 tokenId) public override view returns(address){
        require(exists(tokenId),"The Toekn not exsists");
        return tokenApproval[tokenId];
    }
    
    function isApprovedOwner(address spender, uint256 tokenId) public view returns(bool) {
        require(exists(tokenId), "Invalid Toekn");
        address owner = owners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovalForAll(owner, spender));
        
    }
    
    function transfer(address from, address to, uint tokenId) public {
        require(exists(tokenId), "inavalid token");
        require(to != address(0),"Not a Valid address");
        balances[from] -= 1;
        balances[to] +=1;
        owners[tokenId] = to;
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(isApprovedOwner(msg.sender, tokenId), "The owner is not approved");
        transfer(from, to, tokenId);
    }
    
    function mint(address to, uint tokenId) public {
        require( to != address(0), "The address is not valid");
        require(!exists(tokenId), "The token already exsist");
        owners[tokenId] = to;
        balances[to] += 1;
        
    }
    
    function burn(uint256 tokenId) public {
        address owner = owners[tokenId];
        balances[owner] -= 1;
        delete owners[tokenId];
    
    }
    
    
}