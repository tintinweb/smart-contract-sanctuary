/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

contract MyNFT {
    address private owner = msg.sender;
    string public name;
    string public symbol;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => uint256) private tokenBalances;
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping (address => bool)) private operatorApprovals;
    mapping(uint256 => bool) private validToken;
    mapping(uint256 => string) private tokenURI;

    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        require(!validToken[_tokenId]);
        tokenOwners[_tokenId] = _to;
        tokenURI[_tokenId] = _tokenURI;
        tokenBalances[_to] += 1;
        validToken[_tokenId] = true;
    }

    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0));
        return tokenBalances[_owner];
    }
    function ownerOf(uint256 _tokenId) external view returns (address){
        return tokenOwners[_tokenId];
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable{
        require(_from != msg.sender);
        require(_to != address(0));
        require(tokenOwners[_tokenId] == msg.sender);
        tokenOwners[_tokenId] = _to;
        emit Transfer(_from,  _to, _tokenId);
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        require(_from != msg.sender);
        require(_to != address(0));
        require(tokenOwners[_tokenId] == msg.sender);
        tokenOwners[_tokenId] = _to;
        emit Transfer(_from,  _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
        require(_from != msg.sender || tokenApprovals[_tokenId] != address(0) || operatorApprovals[_from][msg.sender]);
        require(_to != address(0));
        require(tokenOwners[_tokenId] == msg.sender || tokenApprovals[_tokenId] != address(0) || operatorApprovals[_from][msg.sender]);
        tokenOwners[_tokenId] = _to;
        emit Transfer(_from,  _to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) external payable{
        require(tokenOwners[_tokenId] == msg.sender);
        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) external view returns (address){
        require(validToken[_tokenId]);
        return tokenApprovals[_tokenId];
    }
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return operatorApprovals[_owner][_operator];
    }
}