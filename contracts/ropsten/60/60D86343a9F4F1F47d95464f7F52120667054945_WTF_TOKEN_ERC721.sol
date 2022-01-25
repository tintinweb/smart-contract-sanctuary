/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity ^0.8.7;
 
contract WTF_TOKEN_ERC721 {
    address owner;
    string public name;
    string public symbol;
    uint public totalTokens;
    uint public totalSupply;
 
    mapping(uint => uint) private tokenIndex;
    mapping(uint => string) private tokenName;
    mapping(address => uint) private balances;
    mapping(uint => address) private tokenOwners;
    mapping(uint => bool) private tokenExists;
    mapping(address => mapping(uint => uint)) private ownerTokens;
    mapping(address => mapping (address => uint)) private allowed;
    mapping(address => mapping(address => bool)) private allowedAll;
    
    modifier isExists(uint _tokenId){
        require(tokenExists[_tokenId] == true, "This token does not exist");
        _;
    }
    modifier isTokenOwner(address _from, uint _tokenId){
        require(_from == tokenOwners[_tokenId], "The specified address is not the owner of the token");
        _;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint _tokenId);
    event ApprovalAll(address indexed _owner, address indexed _operator, bool _approved);
    
    constructor(string memory _name, string memory _symbol, uint _totalTokens){
        owner = msg.sender;
        totalTokens = _totalTokens;
        totalSupply = 0;
        symbol = _symbol;
        name = _name;
    }
 
    function mint(string memory _tokenName, address _to)public{
        require(msg.sender == owner, "You are not the owner of the contract");
        require(totalSupply + 1 <= totalTokens, "Issued maximum number of tokens");
        uint tokenId = uint(blockhash(block.number - 1)) / 10 + uint(keccak256(bytes(_tokenName))) / 10;
        require(tokenExists[tokenId] == false, "A token with this id already exists");
    
        tokenExists[tokenId] = true;
        tokenName[tokenId] = _tokenName;
        tokenOwners[tokenId] = _to;
        ownerTokens[_to][balances[_to]] = tokenId;
        balances[_to] += 1;
        tokenIndex[totalSupply] = tokenId;
        totalSupply += 1;
    }
    
    function balanceOf(address _owner) public view returns (uint){
        return balances[_owner];
    }
    
    function ownerOf(uint _tokenId) public view isExists(_tokenId) returns (address){
        return tokenOwners[_tokenId];
    }
    
    function approve(address _to, uint _tokenId) public isTokenOwner(msg.sender, _tokenId) {
        require(msg.sender != _to, "The owner of the token cannot grant permission to himself");
        allowed[msg.sender][_to] = _tokenId;
        emit Approval(msg.sender, _to, _tokenId);
    }
 
    function cancelApprove(address _to, uint _tokenId) public isExists(_tokenId) isTokenOwner(msg.sender, _tokenId) {
        require(msg.sender != _to, "The owner of the token cannot grant permission to himself");
        allowed[msg.sender][_to] = 0;
        emit Approval(msg.sender, _to, 0);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external{
        allowedAll[msg.sender][_operator] = _approved;
        emit ApprovalAll(msg.sender, _operator, _approved);
    }
 
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return allowedAll[_owner][_operator];
    }
    
    function transfer(address _from, address _to, uint256 _tokenId)internal{
        tokenOwners[_tokenId] = _to;
        uint index = 0;
        while(ownerTokens[_from][index] != _tokenId){
            index += 1;
        }
        for(uint i = index; i < balances[_from] - 1; i++){
            ownerTokens[_from][i] = ownerTokens[_from][i + 1];
        }
        ownerTokens[_to][balances[_to]] = _tokenId;
        balances[_from] -= 1;
        balances[_to] += 1;      
        emit Transfer(_from, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external isExists(_tokenId) isTokenOwner(msg.sender, _tokenId) {
        require(msg.sender == _from, "The specified address is not the owner of the token");
        require(_to != address(0), "Can't send token to zero address");
        transfer(_from, _to, _tokenId);
    }
 
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external isExists(_tokenId) isTokenOwner(_from, _tokenId) {
        require(_tokenId == allowed[_from][msg.sender] || allowedAll[_from][msg.sender] == true, "You do not have permission to dispose of this token");
        require(_to != address(0), "Can't send token to zero address");
        transfer(_from, _to, _tokenId);
        allowed[_from][msg.sender] = 0;
    }

    function tokenByIndex(uint _index) external view returns (uint){
        require(_index < totalSupply, "A token with such an index does not exist");
        return tokenIndex[_index];
    }
    
    function tokenOfOwnerByIndex(address _owner, uint _index) public view returns (uint tokenId){
        require(_index < balances[_owner], "The specified address does not have a token with this index");
        return ownerTokens[_owner][_index];
    }
    
    function getTokenNameById(uint _tokenId)public view isExists(_tokenId) returns(string memory){
        return tokenName[_tokenId];
    }
}