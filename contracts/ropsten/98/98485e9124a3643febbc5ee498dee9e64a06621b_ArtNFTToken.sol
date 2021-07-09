/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
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

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

contract ArtNFTToken is IERC721, IERC721Metadata {
    
    using Strings for uint256;
    
    address public admin;
    
    string public _name;
    // string public _symbol;
    
    string[] public _allArts;
    
    mapping(string => bool) public addedArts;
    
    uint256[] public _allTokensIds;
    
    mapping (uint256 => address) public _tokenOwner;
    
    mapping (address => uint256) public _balanceOf;
    
    mapping (uint256 => address) public _tokenApprovals;
    
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only Admin of the contract can execute the function');
        _;
    }
    
    // constructor(string memory _Tname, string memory _Tsymbol) {
    constructor() {
        // _name = _Tname;
        // _symbol = _Tsymbol;
        admin = msg.sender;
    }
    
    function name() public override view returns (string memory) {
        return _name;
    }
    
    // function symbol() public override view returns (string memory) {
    //     return _symbol;
    // }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        uint256 _id = tokenId + 1;
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _id.toString()))
            : '';
    }
    
    function _baseURI() internal view virtual returns (string memory) {
        return "https://jsonplaceholder.typicode.com/photos/";
    }

    
    function totalSupply() public view virtual returns (uint256) {
        return _allTokensIds.length;
    }
    
    function balanceOf(address _owner) public override view returns (uint256) {
        require(_owner != address(0), 'Address cannot be zero');
        
        return _balanceOf[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public override view returns (address) {
        address owner = _tokenOwner[_tokenId];
        require(owner != address(0), 'Token Owner address cannot be 0');
        return owner;
    }
    
    function approve(address _approved, uint256 _tokenId) public override payable {
        address owner = ownerOf(_tokenId);
        
        require(_approved != address(0), 'To be approved address cannot be zero');
        
        require(owner == msg.sender, "Only token owner can approve someone to transfer token");
        
        require(owner != _approved, "Owner of the token cannot approve itself");
        
        _tokenApprovals[_tokenId] = _approved;
        
        emit Approval(owner, _approved, _tokenId);
    }
    
    function getApproved(uint256 _tokenId) public override view returns (address) {
        require(_exists(_tokenId), "_tokenId does not exist");
        
        return _tokenApprovals[_tokenId];
    }
    
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(_operator != address(0), 'Operator address cannot be 0');
        
        require(msg.sender != _operator, 'Caller cannot be the operator');
        
        _operatorApprovals[msg.sender][_operator] = _approved;
        
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool) {
        require(_owner != address(0), 'Owner address cannot be 0');
        
        require(_operator != address(0), 'Operator address cannot be 0');
        
        return _operatorApprovals[_owner][_operator];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override payable {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(_tokenId);
        require( (msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender)), "ERC721: transfer caller is not owner nor approved");
        
        transferFrom(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override payable {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(_tokenId);
        require( (msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender)), "ERC721: transfer caller is not owner nor approved");
        
        transferFrom(_from, _to, _tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override payable {
        require(from != address(0), 'From address cannot be 0');
        
        require(to != address(0), 'From address cannot be 0');
        
        require(_exists(tokenId), "tokenId does not exist");
        
        address owner = ownerOf(tokenId);
        require( (msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender)) , "transfer caller is not owner nor approved");
        
        require(ownerOf(tokenId) == from, "from address is not the owner of the token");

        _tokenApprovals[tokenId] = address(0);
        
        emit Approval(ownerOf(tokenId), address(0), tokenId);

        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    function _mint(address to, uint256 tokenId) public virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        
        _balanceOf[to] += 1;
        _tokenOwner[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        
        require(_exists(tokenId), "tokenId does not exist");
        
        require(owner != address(0), 'Token Owner address cannot be 0');
        
        require( (msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender)) , "transfer caller is not owner nor approved");

        _tokenApprovals[tokenId] = address(0);
        
        emit Approval(owner, address(0), tokenId);

        _balanceOf[owner] -= 1;
        delete _tokenOwner[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return _tokenOwner[_tokenId] != address(0);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    
    // ---------------------------------------------------- //
    
    function addArt(string memory _artName) public {
        
        require(addedArts[_artName] != true, 'Art already added');
        
        _allArts.push(_artName);
        
        uint256 _tokenId = _allArts.length - 1;
        _allTokensIds.push(_tokenId);
        
        _mint(msg.sender, _tokenId);
        
        addedArts[_artName] = true;
    }
    
    function removeArt(uint256 _tokenId) public {
        _burn(_tokenId);
        
        string memory _artName = _allArts[_tokenId];
        addedArts[_artName] = false;
        
        delete _allArts[_tokenId];
        for(uint256 i = 0; i < _allTokensIds.length; i++) {
            if(_tokenId == _allTokensIds[i]) {
                delete _allTokensIds[i];
            }
        }
        
    }
    
    function getAllArts() public view returns(string[] memory) {
        return _allArts;
    }
}