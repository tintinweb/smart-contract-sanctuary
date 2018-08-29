pragma solidity ^0.4.24;

interface ERC721Receiver {

    function onERC721Received(address operator, address from, uint tokenId, bytes data) external returns (bytes4);
}

contract Emojisan {

    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool value);

    string public constant name = "emojisan.github.io";
    string public constant symbol = "EMJS";
    address public minter;
    mapping (bytes4 => bool) public supportsInterface;
    mapping (uint => address) private tokenToOwner;
    uint public totalSupply;
    uint[] public tokenByIndex;
    mapping (address => uint[]) public tokenOfOwnerByIndex;
    mapping (address => mapping (uint => uint)) private indexInTokenOfOwnerByIndex;
    mapping (uint => address) public getApproved;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    constructor() public {
        minter = msg.sender;
        supportsInterface[0x01ffc9a7] = true;
        supportsInterface[0x80ac58cd] = true;
        supportsInterface[0x780e9d63] = true;
        supportsInterface[0x5b5e139f] = true;
    }

    function ownerOf(uint tokenId) external view returns (address) {
        address owner = tokenToOwner[tokenId];
        require(owner != 0);
        return owner;
    }

    function tokens() external view returns (uint[]) {
        return tokenByIndex;
    }

    function tokensOfOwner(address owner) external view returns (uint[]) {
        return tokenOfOwnerByIndex[owner];
    }

    function balanceOf(address owner) external view returns (uint) {
        return tokenOfOwnerByIndex[owner].length;
    }

    function tokenURI(uint tokenId) public view returns (string) {
        require(tokenToOwner[tokenId] != 0);
        bytes memory base = "https://raw.githubusercontent.com/emojisan/data/master/tkn/";
        uint length = 0;
        uint tmp = tokenId;
        do {
            tmp /= 62;
            length++;
        } while (tmp != 0);
        bytes memory uri = new bytes(base.length + length);
        for (uint i = 0; i < base.length; i++) {
            uri[i] = base[i];
        }
        do {
            length--;
            tmp = tokenId % 62;
            if (tmp < 10) tmp += 48;
            else if (tmp < 36) tmp += 55;
            else tmp += 61;
            uri[base.length + length] = bytes1(tmp);
            tokenId /= 62;
        } while (length != 0);
        return string(uri);
    }

    function transferFrom(address from, address to, uint tokenId) public {
        require(to != address(this));
        require(to != 0);
        address owner = tokenToOwner[tokenId];
        address approved = getApproved[tokenId];
        require(from == owner);
        require(msg.sender == owner || msg.sender == approved || isApprovedForAll[owner][msg.sender]);
        tokenToOwner[tokenId] = to;
        uint index = indexInTokenOfOwnerByIndex[from][tokenId];
        uint lastIndex = tokenOfOwnerByIndex[from].length - 1;
        if (index != lastIndex) {
            uint lastTokenId = tokenOfOwnerByIndex[from][lastIndex];
            tokenOfOwnerByIndex[from][index] = lastTokenId;
            indexInTokenOfOwnerByIndex[from][lastTokenId] = index;
        }
        tokenOfOwnerByIndex[from].length--;
        uint length = tokenOfOwnerByIndex[to].push(tokenId);
        indexInTokenOfOwnerByIndex[to][tokenId] = length - 1;
        if (approved != 0) {
            delete getApproved[tokenId];
        }
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes data) public {
        transferFrom(from, to, tokenId);
        uint size;
        assembly { size := extcodesize(to) }
        if (size != 0) {
            bytes4 magic = ERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            require(magic == 0x150b7a02);
        }
    }

    function safeTransferFrom(address from, address to, uint tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function approve(address approved, uint tokenId) external {
        address owner = tokenToOwner[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender]);
        getApproved[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool value) external {
        isApprovedForAll[msg.sender][operator] = value;
        emit ApprovalForAll(msg.sender, operator, value);
    }

    function mint(uint tokenId) external {
        require(msg.sender == minter);
        require(tokenToOwner[tokenId] == 0);
        tokenToOwner[tokenId] = msg.sender;
        totalSupply++;
        tokenByIndex.push(tokenId);
        uint length = tokenOfOwnerByIndex[msg.sender].push(tokenId);
        indexInTokenOfOwnerByIndex[msg.sender][tokenId] = length - 1;
        emit Transfer(0, msg.sender, tokenId);
    }

    function setMinter(address newMinter) external {
        require(msg.sender == minter);
        minter = newMinter;
    }
}