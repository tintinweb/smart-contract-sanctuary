/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
// based on https://github.com/ConsenSys/artifaqt/blob/master/contract/contracts/eip721
// Use for educational purposes only // without approval functions
pragma solidity ^0.8.0;

contract EIP721 {  
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    string public  name;
    string public  symbol;
    address public  admin;
    uint256 public  counter = 10;
    uint256[]                      internal allTokens; 
    mapping(uint256 => uint256)    internal allTokensIndex;      
    mapping(address => uint256[])  internal ownedTokens;  
    mapping(uint256 => uint256)    internal ownedTokensIndex;     
    mapping(uint256 => address)    internal ownerOfToken;
    mapping(uint256 => string)     internal tokenURIs; 
    
    address public receivedOperator;    // public to easily check
    address public receivedFrom;        // public to easily check
    uint256 public receivedTokenId;     // public to easily check
    bytes   public receivedData;        // public to easily check
    bytes4 internal constant ERC721_BASE_INTERFACE_SIGNATURE = 0x80ac58cd;
    bytes4 internal constant ERC721_METADATA_INTERFACE_SIGNATURE = 0x5b5e139f;
    bytes4 internal constant ERC721_ENUMERABLE_INTERFACE_SIGNATURE = 0x780e9d63;
    bytes4 internal constant ONERC721RECEIVED_FUNCTION_SIGNATURE = 0x150b7a02;

    modifier tokenExists(uint256 _tokenId) {
        require(ownerOfToken[_tokenId] != address(0));
        _;
    }
    constructor (string memory _name, string memory _symbol) {
        admin = msg.sender;
        name = _name;
        symbol = _symbol;
    }
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4) {
        receivedOperator = _operator;
        receivedFrom     = _from;
        receivedTokenId  = _tokenId;
        receivedData     = _data;
        return ONERC721RECEIVED_FUNCTION_SIGNATURE;    
    } 
    modifier allowedToTransfer(address _from, address _to, uint256 _tokenId) {
        require(ownerOfToken[_tokenId] == _from);
        require(_to != address(0)); //not allowed to burn in transfer method
        _;
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable
    tokenExists(_tokenId)
    allowedToTransfer(_from, _to, _tokenId) {       
        settleTransfer(_from, _to, _tokenId);
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable
    tokenExists(_tokenId)
    allowedToTransfer(_from, _to, _tokenId) {
        settleTransfer(_from, _to, _tokenId);
        uint256 size;
        assembly { size := extcodesize(_to) }  // solhint-disable-line no-inline-assembly
        if (size > 0) {
            require(EIP721(_to).onERC721Received(msg.sender, _from, _tokenId, data) == ONERC721RECEIVED_FUNCTION_SIGNATURE);
        }
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable
    tokenExists(_tokenId)
    allowedToTransfer(_from, _to, _tokenId) {
        settleTransfer(_from, _to, _tokenId);
        uint256 size;
        assembly { size := extcodesize(_to) }  // solhint-disable-line no-inline-assembly
        if (size > 0) {
            require(EIP721(_to).onERC721Received(msg.sender, _from, _tokenId, "") == ONERC721RECEIVED_FUNCTION_SIGNATURE);
        }
    }
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }
    function ownerOf(uint256 _tokenId) external view
    tokenExists(_tokenId) returns (address) {
        return ownerOfToken[_tokenId];
    }
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < allTokens.length);
        return allTokens[_index];
    }
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view
    tokenExists(_tokenId) returns (uint256 _tokenId) {
        require(_index < ownedTokens[_owner].length);
        return ownedTokens[_owner][_index];
    }
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURIs[_tokenId];
    }
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        if (interfaceID == ERC721_BASE_INTERFACE_SIGNATURE ||
        interfaceID == ERC721_METADATA_INTERFACE_SIGNATURE ||
        interfaceID == ERC721_ENUMERABLE_INTERFACE_SIGNATURE) {
            return true;
        } else { return false; }
    }
    function settleTransfer(address _from, address _to, uint256 _tokenId) internal {
        removeToken(_from, _tokenId);
        addToken(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }
    function addToken(address _to, uint256 _tokenId) internal {
        allTokens.push(_tokenId);
        allTokensIndex[_tokenId] = allTokens.length-1;
        ownerOfToken[_tokenId] = _to;        
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = ownedTokens[_to].length-1;
    }
    function removeToken(address _from, uint256 _tokenId) internal {
        uint256 allIndex = allTokensIndex[_tokenId];
        uint256 allTokensLength = allTokens.length;
        allTokens[allIndex] = allTokens[allTokensLength - 1];
        allTokensIndex[allTokens[allTokensLength-1]] = allIndex;
        
        allTokens.pop();
        
        uint256 ownerIndex = ownedTokensIndex[_tokenId];
        uint256 ownerLength = ownedTokens[_from].length;
        ownedTokens[_from][ownerIndex] = ownedTokens[_from][ownerLength-1];
        ownedTokensIndex[ownedTokens[_from][ownerLength-1]] = ownerIndex;
        ownedTokens[_from].pop();
        
        delete ownerOfToken[_tokenId];
    }
    function createToken(address _minter) public {
        require(msg.sender == admin);
        addToken(_minter, counter);
        emit Transfer(address(0), _minter, counter);
        counter += 1; // every new token gets a new ID
    }
    function burnToken(uint256 _tokenId) public {
        require(ownerOfToken[_tokenId] == msg.sender); //token should be in control of owner
        removeToken(msg.sender, _tokenId);
        emit Transfer(msg.sender, address(0), _tokenId);
    }
    function setTokenURI(uint256 _tokenID, string memory URI) public {
        require(msg.sender == admin);
        tokenURIs[_tokenID] = URI;
    }
}