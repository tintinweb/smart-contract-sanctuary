/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract TestLightYear is ERC721 {

    uint256 totalSupply = 0;
    mapping(address => uint256) private _ownerTokenAmountMap;
    mapping(uint256 => address) private _tokenIdOwnerMap;

    function balanceOf(address _owner) override external view returns (uint256){
        return _ownerTokenAmountMap[_owner];
    }

    function ownerOf(uint256 _tokenId) override external view returns (address){
        return _tokenIdOwnerMap[_tokenId];
    }

    function mint() public {
        uint256 _tokenId = totalSupply + 1;
        _ownerTokenAmountMap[msg.sender] += 1;
        _tokenIdOwnerMap[_tokenId] = msg.sender;
        emit Transfer(address(0), msg.sender, _tokenId);
        totalSupply += 1;
    }

    function transfer() public {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override external payable {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {

    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {

    }

    function approve(address _approved, uint256 _tokenId) override external payable {

    }

    function setApprovalForAll(address _operator, bool _approved) override external {

    }

    function getApproved(uint256 _tokenId) override external view returns (address){

    }

    function isApprovedForAll(address _owner, address _operator) override external view returns (bool){

    }

}