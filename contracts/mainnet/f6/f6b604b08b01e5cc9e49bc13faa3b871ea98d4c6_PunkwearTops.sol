/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

/*
 ____              _                               _                  
|  _ \ _   _ _ __ | | ____      _____  __ _ _ __  | |_ ___  _ __  ___ 
| |_) | | | | '_ \| |/ /\ \ /\ / / _ \/ _` | '__| | __/ _ \| '_ \/ __|
|  __/| |_| | | | |   <  \ V  V /  __/ (_| | |    | || (_) | |_) \__ \
|_|    \__,_|_| |_|_|\_\  \_/\_/ \___|\__,_|_|     \__\___/| .__/|___/
                                                           |_|    
*/
pragma solidity 0.8.10;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface CryptopunksInterface {
    function punkIndexToAddress(uint index) external view returns(address);
}

interface WrappedPunksInterface {
    function ownerOf(uint index) external view returns(address);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

contract PunkwearTops is IERC721 {

    event Mint(uint indexed index, address indexed minter, uint createdVia);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    bool public metadataIsLocked;


    // Hash of the 10k tops image (run `openssl dgst -sha256 10k_tops.png`) 
    bytes public constant contentHash = "0x31a9260a4f3b032c13a9b9c11164dcd8ade0f23a70ffcf3f98d1fc9b09e98522";

    bytes32 internal _setOfIds;
    bytes32 internal constant mask = hex"0000000000000000000000000000000000000000000000000000000000003fff";
    uint public constant TOKEN_LIMIT = 10000;
    uint public constant SALE_LIMIT = 9250;
    uint public constant DEV_MAX = 750;
    uint public devMints;
    uint public constant MAX_MINTS_PER_CALL = 20;

    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping (uint256 => address) internal idToOwner;
    bool[10000] public punkIDsUsed;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) internal ownerToIds;
    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal _name = "Punkwear Tops";
    string internal _symbol = "PWT";
    string public baseURI = "https://www.punkwear.xyz/metadata/";
    string public _contractURI = "ipfs://QmaZYMyb5dfajhSEL4BpzmVXyqgWqrELDL9jBmV77unb5b";

    uint internal numTokens;

    // Cryptopunks contract
    address internal punksContract = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    // Wrapped Cryptopunks contract
    address internal wrappedPunksContract = 0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6;

    address payable public owner;
    uint public constant price = 0.04 ether;

    //// Random index assignment
    uint internal nonce = 0;
    uint[TOKEN_LIMIT] internal indices;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner.");
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Cannot operate.");
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender], "Cannot transfer."
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
	    owner = payable(msg.sender);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    function isContract(address _addr) internal view returns (bool addressCheck) {
        addressCheck = _addr.code.length > 0;
    }

    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0));
        return ownerToIds[_owner].length;
    }

    function ownerOf(uint256 _tokenId) external view override returns (address _owner) {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) external view override validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function randomIndex() internal returns (uint) {
        uint totalSize = TOKEN_LIMIT - numTokens;
        //I know it's pseudorandom but because the metadata is not public, it's ok.
        //However, because the team can mint too, it's important that they get random ones (any manipulation would be obvious)
        uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        
        return value;
    }
    
    function getBoolean(uint256 _packedBools, uint256 _boolNumber) public pure returns(bool) {
        uint256 flag = (_packedBools >> _boolNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }
    
    function mintWithPunks(bytes32[] memory _allIds, uint256 _numberOfPunks, uint256 _areWrappedBools, uint256 _additionalMints) external payable {
        require(numTokens + _additionalMints + _numberOfPunks <= SALE_LIMIT, "Qty would exceed max supply");
        for (uint i=0;i<_numberOfPunks;i++) {
            if (i%18 == 0) {
                _setOfIds = _allIds[i/18];
            }
        //Uncompress punk ids and read them one by one
            uint _punkId = uint16(bytes2((_setOfIds & mask) << 240));
            require(_punkId >= 0 && _punkId < 10000, "Invalid punk index.");
            require(!punkIDsUsed[_punkId], "Already minted with this punk");
            punkIDsUsed[_punkId] = true;
            if (!getBoolean(_areWrappedBools,i)) {
                require(CryptopunksInterface(punksContract).punkIndexToAddress(_punkId) == msg.sender, "Not the owner of this punk.");
            } else {
                require(WrappedPunksInterface(wrappedPunksContract).ownerOf(_punkId) == msg.sender, "Not the owner of this punk.");
            }
            _mint(msg.sender, _punkId);
            _setOfIds >>= 14;
        }
        if (_additionalMints>0) {
            mint(_additionalMints);
        }
    }

    function mint(uint _quantity) public payable {
        require(numTokens + _quantity <= SALE_LIMIT, "Qty would exceed max supply");
        require(_quantity <= MAX_MINTS_PER_CALL,"Max ");
        require(msg.value == price*_quantity, "Incorrect funds");
        for (uint i;i<_quantity;i++) {
            _mint(msg.sender, 10000);
        }
    }

    function _mint(address _to, uint createdVia) internal returns (uint) {
        require(_to != address(0), "Cannot mint to 0x0.");
        require(numTokens < TOKEN_LIMIT, "Token limit reached.");
        
        uint id = randomIndex();
        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        emit Mint(id, _to, createdVia);
        emit Transfer(address(0), _to, id);
        
        return id;
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "Cannot add, already owned.");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length-1;
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length-1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }


    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }


    function devMint(uint quantity, address recipient) external onlyOwner {
        require(devMints + quantity <= DEV_MAX);
        devMints = devMints + quantity;
        for (uint i; i < quantity; i++) {
            _mint(recipient, 10000);
        }
    }

    
    //// Enumerable
    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }


    //// Metadata

    function lockMetadata() external onlyOwner {
        metadataIsLocked = true;
    }


    function setContractURI(string memory _newContractURI) external onlyOwner {
        require(!metadataIsLocked,"Metadata is locked");
        _contractURI = _newContractURI;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!metadataIsLocked,"Metadata is locked");
        baseURI = newBaseURI;
    }
    
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 tmp = _i;
        uint256 length;
        while (tmp != 0) {
            length++;
            tmp /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        tmp = _i;
        while (tmp != 0) {
            bstr[--k] = bytes1(uint8(48 + tmp % 10));
            tmp /= 10;
        }
        str = string(bstr);
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

}