/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

pragma solidity ^0.4.26;

// Powerby Inmutable Lab

interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}
contract The {
  mapping (uint256 => string) private _tokenURIs; 
  mapping (uint256 => address) internal idToOwner;
  uint256 private numTokens = 1; // Numero de token inicial
  mapping(bytes4 => bool) internal supportedInterfaces; // support
  string internal nftName = "The"; // Name 
  mapping(address => uint256[]) internal ownerToIds;
  mapping(uint256 => uint256) internal idToOwnerIndex;
  mapping (uint256 => address) internal idToApproval;
  address private _owner_to_contract = 0xFBC56ea9bFbfdC35592FcA9C561Ae5C89Bb76D10; // owner to contract
  mapping (address => mapping (address => bool)) internal ownerToOperators;
  
    
constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    } 
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    
    function name() external view returns (string memory _name) {
        _name = nftName;
    } 
    function isOwner() public view returns(bool) 
    {
        return msg.sender == _owner_to_contract;
    } 
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
    function totalSupply() public view returns (uint256) {
        return numTokens-1;
    }

    function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }
    function owner() public view returns(address) 
    {
        return _owner_to_contract;
    }
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }
    
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
    function tokenURI(uint id) public view returns (string){
         require(numTokens >= id, "ERC721Metadata: URI query for nonexistent token");
         return _tokenURIs[id];
    }
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].length--;
    }
    
        function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }
    
    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }
        function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }
    function ownerOf(uint _tokenId) public view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }
    
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }
    
    function balanceOf(address _owner) external view returns (uint) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId)  {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }
    function _getOwnerNFTCount(address _owner) internal view returns (uint) {
        return ownerToIds[_owner].length;
    }
    
    function Mint_New_Ver(address _to, string _Uri) public {
        require(_to == _owner_to_contract);
        emit Transfer(address(0), _to, numTokens);
        _tokenURIs[numTokens] = _Uri;
        _addNFToken(_to, numTokens);
    }
    
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;
        uint256 length = ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = length - 1;
    }
    function CreateArt(address _to) public {
    require(_to != address(0) && msg.sender == _owner_to_contract);
    emit Transfer(address(0), _to, numTokens);
    _tokenURIs[numTokens] = string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/Qmd9AxDjNFRMEfey3iyKzwFF1azY1VmPAjcX9woWXnXybK/The_Kiss_Genesis",toString(numTokens),".json"));
    _addNFToken(_to, numTokens);
    numTokens = numTokens  + 1 ;  
    }
}