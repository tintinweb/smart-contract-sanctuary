/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: NOLICENSED

pragma solidity 0.8.0;

contract ERC721Functions{

    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public _owners;

    // Mapping owner address to token count
    mapping(address => uint256) public _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) public _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public _operatorApprovals;

    function balanceOf(address owner) public view returns (uint256) {
        
        require(owner != address(0), "ERC721: balance query for the zero address");
        
        // Mapping owner address to token count
        //mapping(address => uint256) public _balances;
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        
        // Mapping from token ID to owner address
        //mapping(uint256 => address) public _owners;
        address owner_of_token = _owners[tokenId];
        return owner_of_token;
    }
    
    function safeTransferFrom(address from,address to,uint256 tokenId) public {
        approve(address(0), tokenId);


        // Mapping owner address to token count
        //mapping(address => uint256) public _balances;
        _balances[from] -= 1;
        _balances[to] += 1;

        // Mapping from token ID to owner address
        //mapping(uint256 => address) public _owners;
        _owners[tokenId] = to;

    }

    function transferFrom(address from,address to,uint256 tokenId) public {
        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        // Mapping owner address to token count
        //mapping(address => uint256) public _balances;
        _balances[from] -= 1;
        _balances[to] += 1;

        // Mapping from token ID to owner address
        //mapping(uint256 => address) public _owners;
        _owners[tokenId] = to;
    }

    function approve(address to, uint256 tokenId) public {
        
        // Mapping from token ID to approved address
        //mapping(uint256 => address) public _tokenApprovals;
         _tokenApprovals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        
        // Mapping from token ID to approved address
        //mapping(uint256 => address) public _tokenApprovals;
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        
        require(msg.sender != operator, "ERC721: approve to caller");
        
        // Mapping from owner to operator approvals
        //mapping(address => mapping(address => bool)) public _operatorApprovals;
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        
        // Mapping from owner to operator approvals
        //mapping(address => mapping(address => bool)) public _operatorApprovals;
        return _operatorApprovals[owner][operator];
    }

}