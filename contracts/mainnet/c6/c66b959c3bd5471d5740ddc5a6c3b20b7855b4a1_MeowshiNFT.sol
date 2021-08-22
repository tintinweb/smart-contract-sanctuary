/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;
/// @notice Minimalist NFT minter for Meowshi holders.
contract MeowshiNFT {
    uint256 public totalSupply;
    string constant public name = "Meowshi NFT";
    string constant public symbol = "mNFT";
    address constant public meowTimelock = 0x148E15fdBc6403F8A52F17Bdd4332efa79e04564;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed approver, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function supportsInterface(bytes4 sig) external pure returns (bool) {
        return (sig == 0x80ac58cd || sig == 0x5b5e139f); // ERC-165
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function mint(uint256 tokenId, string calldata _tokenURI) external { 
        require(msg.sender == meowTimelock, '!meowDAO');
        require(ownerOf[tokenId] == address(0), 'tokenId !unique');
        totalSupply++;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenURI[tokenId] = _tokenURI;
        emit Transfer(address(0), msg.sender, tokenId); 
    }

    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], '!owner');
        balanceOf[msg.sender]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 
    }
    
    function transferFrom(address, address to, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || getApproved[tokenId] == msg.sender || isApprovedForAll[owner][msg.sender], '!owner/spender/operator');
        balanceOf[owner]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        emit Transfer(owner, to, tokenId); 
    }
}