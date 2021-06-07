// SPDX-License-Identifier: DeNet

pragma solidity ^0.8.0;

import "SafeMath.sol";

contract SimpleNFT {
    using SafeMath for uint256;
  
    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;
    
    // Mapping from owner to token last token id
    
    

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(address owner, uint256 tokenId) internal {
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }
    
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }
    
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
}

contract SimpleMetaData is SimpleNFT {
    // Token name
    string internal _name;
    
    // Token symbol
    string internal _symbol;
    
    // Structure for Node
    struct DeNetNode{
        uint8[4] ip_address; // [127, 0,0,1]
        uint16 port;
        uint256 block_created;
        uint256 last_update;
        uint256 updates_count;
    }
    
    mapping(uint256 => DeNetNode) private _node;
    
    
    event UpdateNodeStatus(
        address indexed from,
        uint256 indexed tokenId,
        uint8[4]  ip_address,
        uint16 port
        
    );
    
    
    
    constructor(string  memory name_, string  memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function NodeInfo(uint256 tokenId) public view returns (DeNetNode memory) {
        require(_exists(tokenId));
        return _node[tokenId];
    }
    
    function _setNodeInfo(uint256 tokenId,  uint8[4] calldata ip, uint16 port) internal {
        require(_exists(tokenId));
        
        _node[tokenId].ip_address = ip;
        _node[tokenId].port = port;
        if (_node[tokenId].block_created == 0) {
            _node[tokenId].block_created = block.number;
        }
        
        _node[tokenId].last_update = block.number;
        _node[tokenId].updates_count += 1;
        
        emit UpdateNodeStatus(msg.sender, tokenId, ip, port);
    }
    
    function _burnNode(address owner, uint256 tokenId) internal  {
        super._burn(owner, tokenId);
        
        // Clear metadata (if any)
        if (_node[tokenId].block_created != 0) {
            delete _node[tokenId];
        }
    }
}

contract DeNetNodeNFT is SimpleMetaData {
    uint256 nodes_count = 0;
    
    constructor (
            string memory _name,
            string memory _symbol
        ) SimpleMetaData(_name, _symbol) {
            
        }
    mapping (address => uint256) private _token_by_owner;
     
    function createNode(uint8[4] calldata ip, uint16 port) public {
       
        // if user have not nodes
        require(_token_by_owner[msg.sender] == 0);
       
        _mint(msg.sender, nodes_count);
        _setNodeInfo(nodes_count, ip, port);
        _token_by_owner[msg.sender] = nodes_count;
        nodes_count += 1;
        
    }
    
    function updateNode(uint256 node_id, uint8[4] calldata ip, uint16 port) public {
        require(ownerOf(node_id) == msg.sender);
        _setNodeInfo(node_id, ip, port);
    }
    
    function getNodeById(uint256 node_id) public view returns (DeNetNode memory) {
        return NodeInfo(node_id);
    }
    
    function totalSupply() public  view returns (uint256) {
        return nodes_count;
    }
}