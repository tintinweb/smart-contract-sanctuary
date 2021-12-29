// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface INFT {

event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

function balanceOf(address _owner) external view returns (uint256);
function ownerOf(uint256 _tokenId) external view returns (address);
function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
function approve(address _approved, uint256 _tokenId) external payable;
function setApprovalForAll(address _operator, bool _approved) external;
function getApproved(uint256 _tokenId) external view returns (address);
function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract NFT is INFT {

mapping(address=>uint256) private _balances;
mapping(uint256 => address) private _holders;
mapping(uint256 => address) private _approved;
mapping(address => mapping(address =>bool)) private _approvedForAll;

uint256 private _lastId =0;
uint256 immutable Max_Supply=5;

//constructor(uint256 maxSupply) {
//    Max_Supply = maxSupply;
//}
function balanceOf(address _holder) public view override returns (uint256) {
    return _balances[_holder];
}

function ownerOf(uint256 _tokenId) public view  override returns (address){
    return _holders[_tokenId];    
}
function transferFrom(address _from, address _to, uint256 _tokenId) external  override payable{
require(ownerOf(_tokenId) == _from);
    require(_from == msg.sender || getApproved(_tokenId) == msg.sender);
    
    _balances[_from] -= 1;
    _balances[_to] +=1;
    _holders[_tokenId] = _to;

    emit Transfer(_from, _to, _tokenId);
}
function approve(address approved, uint256 _tokenId) external override payable{
    require(msg.sender == ownerOf(_tokenId));
    _approved[_tokenId] = approved;

    emit Approval(msg.sender, approved, _tokenId);
}
function setApprovalForAll(address _operator, bool approved) external override {
    _approvedForAll[msg.sender][_operator] = approved;

    emit ApprovalForAll(msg.sender, _operator, approved);
}
function getApproved(uint256 _tokenId) public view override returns (address){
    require ( _tokenId >0 && _tokenId <= Max_Supply);
    return _approved[_tokenId];
}
function isApprovedForAll(address _holder, address _operator) external view override returns (bool){
    return _approvedForAll[_holder][_operator];
}
function _mint () internal {
    require(_lastId < Max_Supply);
    address _to = msg.sender;
    _lastId++;
    _balances[_to] +=1;
    _holders[_lastId] = _to;

    emit Transfer(address(0),msg.sender, _lastId);
}

}