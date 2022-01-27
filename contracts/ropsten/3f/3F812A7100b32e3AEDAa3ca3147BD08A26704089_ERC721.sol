/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.0 < 0.9.0;


contract ERC721{
    string private _name;
   string private _symbol;

   
    mapping(uint256 => address) public _owners;
  
    mapping(address => uint256) public _balances;
    
    mapping(uint256 => address) public _tokenApprovals;
   
    mapping(address => mapping(address => bool)) public _operatorApprovals;
    function balanceOf(address owner) public view returns (uint256) {
        
        require(owner != address(0), "ERC721: balance query for the zero address");
        
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        
        address owner_of_token = _owners[tokenId];
        return owner_of_token;
    }
    
    function approve(address to, uint256 tokenId) public {
         _tokenApprovals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from,address to,uint256 tokenId) public {
        // Clear approvals from the previous owner
        approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
    }


    function safeTransferFrom(address from,address to,uint256 tokenId) public {
        approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
    }
    
    
  
    
  
}