/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0;

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

contract TestNft is ERC721 {

    uint256 public totalSupply = 0;
    mapping(address => uint256) public _ownerTokenAmountMap;
    mapping(uint256 => address) public _tokenIdOwnerMap;
    mapping(uint256 => address) public _tokenIdApproveMap;

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

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override external payable {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {

    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
        address owner = _tokenIdOwnerMap[_tokenId];
        require(owner == _from);

        bool o1 = _tokenIdOwnerMap[_tokenId] == msg.sender;
        bool o2 = _tokenIdApproveMap[_tokenId] == msg.sender;
        require(o1 || o2);

        _tokenIdOwnerMap[_tokenId] = _to;
        _ownerTokenAmountMap[_from] -= 1;
        _ownerTokenAmountMap[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) override external payable {
        address owner = _tokenIdOwnerMap[_tokenId];
        require(owner == msg.sender);

        _tokenIdApproveMap[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) override external view returns (address){
        return _tokenIdApproveMap[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) override external {

    }

    function isApprovedForAll(address _owner, address _operator) override external view returns (bool){

    }

}