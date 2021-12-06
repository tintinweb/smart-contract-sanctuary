/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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

    // IPFS Hash to the NFT content
    string public contentHash;

    bytes32 internal _setOfIds;

    bytes32 public constant mask = hex"0000000000000000000000000000000000000000000000000000000000003fff";
    uint public constant TOKEN_LIMIT = 10000;
    uint public constant SALE_LIMIT = 9000;
    uint public constant MAX_MINTS_PER_CALL = 15;

    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping (uint256 => address) internal idToOwner;
    bool[10000] public punkIDsUsed;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) internal ownerToIds;
    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "Punkwear Tops";
    string internal nftSymbol = "PWT";
    string public baseURI = "https://www.punkwear.xyz/metadata/";
    string public contractURI;

    uint public numTokens;
    uint internal numMints;

    // Cryptopunks contract
    address internal punksContract;
    // Wrapped Cryptopunks contract
    address internal wrappedPunksContract;

    address payable public owner;
    uint public price = 1 wei;

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

    constructor(address _punks, address _wrappedPunks, string memory _contentHash) {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
	owner = payable(msg.sender);
        punksContract = _punks;
        wrappedPunksContract= _wrappedPunks;
        contentHash = _contentHash;
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) }  //solhint-disable-line
        addressCheck = size > 0;
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

    // The deployer can mint in bulk without paying
    function devMint(uint quantity, address recipient) external onlyOwner {
        for (uint i; i < quantity; i++) {
            _mint(recipient, 10000);
        }
    }
    
    function getBoolean(uint256 _packedBools, uint256 _boolNumber) public pure returns(bool) {
        uint256 flag = (_packedBools >> _boolNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }
    
    function setBoolean(uint256 _packedBools, uint256 _boolNumber, bool _value) public pure returns(uint256) {
        if (_value) {
            return _packedBools | uint256(1) << _boolNumber;
        } else {
            return _packedBools & ~(uint256(1) << _boolNumber);
        }
    }
    

    /*
    // Community grant minting.
    function mintWithPunks(uint[] calldata _punkIds, uint256 _areWrappedBools, uint _additionalMints) external payable {
        require(numMints < SALE_LIMIT, "All wear has been minted");
        for (uint i; i < _punkIds.length; i++) {
            uint _punkId = _punkIds[i];
            require(_punkId >= 0 && _punkId < 10000, "Invalid punk index.");
            require(!punkIDsUsed[_punkId], "Already minted with this punk");
        
            // Make sure the sender owns the punk
            if (!getBoolean(_areWrappedBools,i)) {
                require(CryptopunksInterface(punksContract).punkIndexToAddress(_punkId) == msg.sender, "Not the owner of this punk.");
            } else {
                require(WrappedPunksInterface(wrappedPunksContract).ownerOf(_punkId) == msg.sender, "Not the owner of this punk.");
            }
        }
        
        if (_additionalMints>0) {
            mint(_additionalMints);
        }
    }
*/

    function mintWithPunksOpti(bytes32[] memory _allIds, uint256 _numberOfPunks, uint256 _areWrappedBools, uint256 _additionalMints) external payable {
        require(numMints + _additionalMints + _numberOfPunks < SALE_LIMIT, "All wear has been minted");
        for (uint i=0;i<_numberOfPunks;i++) {
            if (i%18 == 0) {
                _setOfIds = _allIds[i/18];
            }
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
/*
    uint[] public uids;
    function test() public {
        //require(_value.length * 18 >= _numberOfPunks);
        for (uint i=0;i<_numberOfPunks;i++) {
            if (i%18 == 0) {
                _setOfIds = _allIds[i/18];
            }
            uint _punkId = uint16(bytes2((_setOfIds & mask) << 240));
            //check if punks function allow 0x val
            uids.push(_punkId);
            _setOfIds >>= 14;
        }
    }
*/

    /**
     * Public sale minting.
     */
    function mint(uint _quantity) public payable {
        require(numMints + _quantity < SALE_LIMIT, "Quantity would exceed max supply");
        require(numMints <= MAX_MINTS_PER_CALL,"Quantity is too high");
        require(msg.value == price*_quantity, "Insufficient funds to purchase.");
        numMints+=_quantity;
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

    //// Enumerable
    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    //// Metadata

    /**
      * @dev Converts a `uint256` to its ASCII `string` representation.
      */
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

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return _name Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return _tokenId URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

}