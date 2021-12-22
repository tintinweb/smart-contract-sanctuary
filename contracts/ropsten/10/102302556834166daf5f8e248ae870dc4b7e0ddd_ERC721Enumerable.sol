/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract ERC721 {
    mapping(address =>  mapping(address => bool)) approvedForAll;

    mapping(uint => address) tokens;
    mapping(uint => address) approved;

    mapping(address => uint[] ) balance;
    
    uint cost;
    address ow;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    
    constructor(uint _baseCost){
        cost = _baseCost;
        ow = msg.sender;
    }

    modifier ownerOnly(address _add, uint _id){
        require(tokens[_id] == _add);
        _;
    }

    modifier nonZeroReceiver(address _add){
        require(address(0) != _add);
        _;
    }

    function balanceOf(address _owner) public view returns(uint256){
        return balance[_owner].length;
    }

    function ownerOf(uint256 _tokenId) public view returns(address){
        return tokens[_tokenId];
    }
    
    function _transferFrom(address _from, address _to, uint256 _tokenId) internal{
        approved[_tokenId] = address(0);
        tokens[_tokenId] = _to;
        balance[_to].push( _tokenId );
        delete balance[_from];
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public ownerOnly(msg.sender, _tokenId) nonZeroReceiver(_to) payable{
        require(_from == msg.sender);
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public ownerOnly(_from, _tokenId) nonZeroReceiver(_to) payable{
        require(_from == msg.sender || approved[_tokenId] == msg.sender);
        _transferFrom(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public ownerOnly(msg.sender, _tokenId) nonZeroReceiver(_approved) payable{
        approved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public nonZeroReceiver(_operator){
        approvedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns(address){
        return approved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns(bool){
        return approvedForAll[_owner][_operator];
    }

    function mint(address _owner, uint _uniqId) public virtual nonZeroReceiver(_owner) payable{
        require(msg.value >= cost);
        require(tokens[_uniqId] == address(0));
        cost += 10000;
        balance[_owner].push( _uniqId );
    }

    function getCurrentCost() public view returns(uint){
        return cost;
    }

    function getAll() public{
        require(ow == msg.sender);
        payable(ow).transfer(address(this).balance);
    }

    function setCost(uint _cost) public{
        require(ow == msg.sender);
        cost = _cost;
    }
}

contract ERC721Enumerable is ERC721(0){

    uint[] indexes;

    constructor(uint _baseCost){
        cost = _baseCost;
    }

    function totalSupply() public view returns(uint){
        return indexes.length;
    }

    function tokenByIndex(uint _index) public view returns(uint){
        require(_index < indexes.length);
        return indexes[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint _index) public view nonZeroReceiver(_owner) returns(uint){
        require(_index < balance[_owner].length);
        return balance[_owner][_index];
    }

    function mint(address _owner, uint _uniqId) public override nonZeroReceiver(_owner) payable{
        require(msg.value >= cost);
        require(tokens[_uniqId] == address(0));
        cost += 10000;
        balance[_owner].push( _uniqId );
        indexes.push( _uniqId );
    }
}