/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
//    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract Marketplace {
    address admin;
    constructor(){
        admin = msg.sender;
    }
    ERC721 NFT = ERC721(0x2299fF4C3B44Da4dF6a2110B5e17045487547440);
    function buyToken(uint256 _tokenId) public payable {
    // check if the function caller is not an zero account address
    require(msg.sender != address(0));
    // check if the token id of the token being bought exists or not
    require(NFT.ownerOf(_tokenId)==NFT.ownerOf(_tokenId));
    // get the token's owner
    address tokenOwner = NFT.ownerOf(_tokenId);
    // token's owner should not be an zero address account
    require(tokenOwner != address(0));
    // the one who wants to buy the token should not be the token's owner
    require(tokenOwner != msg.sender);
    // price sent in to buy should be equal to or more than the token's price
    require(msg.value >= 0.001 ether);
    // transfer the token from owner to the caller of the function (buyer)
    NFT.transferFrom(tokenOwner, msg.sender, _tokenId);
    // send token's worth of ethers to the owner
    address sendTo;
    payable(sendTo).transfer(msg.value);
    }
    function withdraw() external{
        require(msg.sender == admin);
        payable(msg.sender).transfer(address(this).balance);
    }
    fallback() external {
        revert();
    }
    receive() external payable{
    }
}