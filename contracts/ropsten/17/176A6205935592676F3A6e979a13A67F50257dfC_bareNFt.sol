/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract bareNFt {
    uint256 public totalsupply;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => uint256) public _balances;
    mapping(uint256 => address) public _ownerOf;
    mapping(address => mapping(uint256 => address)) public _isApproved;
    mapping(address => mapping(address => bool)) public _isApprovedForAll;


    constructor() {
        _balances[msg.sender] = totalsupply;
        for(uint8 i = 0; i < 7; i++){
            _ownerOf[i] = msg.sender;
        }
        totalsupply = 7;
    }

    // function balanceOf(address _owner) public view returns(uint256){}
    // function ownerOf(uint256 _tokenId) public view returns(address){}
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {}
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {}
    function transferFrom(address _from, address _to, uint256 _tokenId) public{
        require(_from != address(0), "transfer from address 0");
        require(_to != address(0), "transfer from address 0");
        require(_tokenId < 7, "token dos not exist");
        require(_from == _ownerOf[_tokenId], "address _from is not the owner of tokenId");
        require(msg.sender == _from || msg.sender == _isApproved[_from][_tokenId] || _isApprovedForAll[_from][msg.sender]
        , "You are not the owner nor approved to transfer this tokenId");

        _balances[_from] --;
        _balances[_to] ++;
        _ownerOf[_tokenId] = _to;
        
        emit Transfer(_from, _to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) public{
        require(_tokenId < 7, "token dos not exist");
        require(msg.sender == _ownerOf[_tokenId], "address _from is not the owner of tokenId");

        _isApproved[msg.sender][_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) public{
        _isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    // function getApproved(uint256 _tokenId) public view returns(address){}
    // function isApprovedForAll(address _owner, address _operator) public view returns(bool){}
}