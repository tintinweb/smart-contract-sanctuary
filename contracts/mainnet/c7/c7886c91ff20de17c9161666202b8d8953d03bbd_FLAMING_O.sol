/**
 *Submitted for verification at Etherscan.io on 2020-11-19
*/

/*
███████╗██╗      █████╗ ███╗   ███╗██╗███╗   ██╗ ██████╗          ██████╗ 
██╔════╝██║     ██╔══██╗████╗ ████║██║████╗  ██║██╔════╝         ██╔═══██╗
█████╗  ██║     ███████║██╔████╔██║██║██╔██╗ ██║██║  ███╗        ██║   ██║
██╔══╝  ██║     ██╔══██║██║╚██╔╝██║██║██║╚██╗██║██║   ██║        ██║   ██║
██║     ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝███████╗╚██████╔╝
╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚═════╝
// SPDX-License-Identifier: MIT
*/
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IMOLMember {
    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of voting shares assigned to this member
        uint256 loot; // the loot amount available to this member (combined with shares on ragequit)
        bool exists; // always true once a member has been created
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
        uint256 jailed; // set to proposalIndex of a passing guild kick proposal for this member, prevents voting on and sponsoring proposals
    }
    
    function members(address account) external returns (Member memory); // check member against mapping
}

contract FLAMING_O { // based on GAMMA nft (Γ) - 0xeF0ff94B152C00ED4620b149eE934f2F4A526387
    address public lao = 0x43310Bd1c8F261Ee7B9025662207ED95329aa193; // lao from where members claim nft mint
    uint256 public totalSupply;
    uint256 public totalSupplyCap = 100;
    string public name = "FLAMING_O";
    string public symbol = "FL_O";
    
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public claimer;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed holder, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
    }
    
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    
    function mint() external { 
        require(IMOLMember(lao).members(msg.sender).exists, "!member");
        require(!claimer[msg.sender], "claimed");
        claimer[msg.sender] = true; // record claim
        totalSupply++;
        uint256 total = totalSupply;
        require(total <= totalSupplyCap, "capped");
        uint256 tokenId = total;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenByIndex[tokenId - 1] = tokenId;
        tokenURI[tokenId] = "https://gateway.pinata.cloud/ipfs/QmSNPcPhuAMzoA6EkQWz6Z8yeDvDSap8HU63ctvsJc8PZo";
        tokenOfOwnerByIndex[msg.sender][tokenId - 1] = tokenId;
        emit Transfer(address(0), msg.sender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        tokenOfOwnerByIndex[from][tokenId - 1] = 0;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(from, to, tokenId); 
    }
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        _transfer(msg.sender, to, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        _transfer(from, to, tokenId);
    }
}