/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity ^0.8.4;

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

interface ERC721TokenReceiver
{
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

contract meebmod is IERC721 {

    event Mint(uint indexed index, address indexed minter, uint createdVia);
    event SaleBegins();
    event CommunityGrantEnds();

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    // IPFS Hash to the NFT content
    string public contentHash = "QmfXYgfX1qNfzQ6NRyFnupniZusasFPMeiWn5aaDnx7YXo";

    uint public constant TOKEN_LIMIT = 10000;
    uint public constant SALE_LIMIT = 9000;

    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping (uint256 => address) internal idToOwner;
    
    uint256 public punkIDsUsed;
    
    mapping (uint256 => address) internal idToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;

    mapping(address => uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "meebmod";
    string internal nftSymbol = "MOOD";

    uint internal numTokens = 0;
    uint internal numSales = 0;

    // Cryptopunks contract
    address internal punksContract;
    
    // Wrapped Cryptopunks contract
    address internal wrappedPunksContract;

    address payable internal deployer;
    address payable internal beneficiary;
    bool public communityGrant = true;
    bool public publicSale = false;
    uint private price;
    uint public saleStartTime;
    uint public saleDuration;

    //// Random index assignment
    uint internal nonce = 0;
    uint[TOKEN_LIMIT] internal indices;

    //// Market
    bool public marketPaused;
    bool public contractSealed;
    mapping (address => uint256) public ethBalance;
    mapping (bytes32 => bool) public cancelledOffers;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
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

    constructor(address _punks, address _wrappedPunks, address payable _beneficiary) {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
        deployer = payable(msg.sender);
        punksContract = _punks;
        wrappedPunksContract= _wrappedPunks;
        beneficiary = _beneficiary;
    }

    function startSale(uint _price, uint _saleDuration) external onlyDeployer {
        require(!publicSale);
        price = _price;
        saleDuration = _saleDuration;
        saleStartTime = block.timestamp;
        publicSale = true;
        emit SaleBegins();
    }

    function endCommunityGrant() external onlyDeployer {
        require(communityGrant);
        communityGrant = false;
        emit CommunityGrantEnds();
    }

    function pauseMarket(bool _paused) external onlyDeployer {
        require(!contractSealed, "Contract sealed.");
        marketPaused = _paused;
    }

    function sealContract() external onlyDeployer {
        contractSealed = true;
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
        return _getOwnerNFTCount(_owner);
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
        // Don't allow a zero index, start counting at 1
        return value+1;
    }

    // Calculate the mint price
    function getPrice() public view returns (uint) {
        require(publicSale, "Sale not started.");
        uint elapsed = block.timestamp - saleStartTime;
        if (elapsed >= saleDuration) {
            return 0;
        } else {
            return saleDuration - elapsed * price / saleDuration;
        }
    }

    // The deployer can mint in bulk without paying
    function devMint(uint quantity, address recipient) external onlyDeployer {
        for (uint i = 0; i < quantity; i++) {
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
    
    /**
     * Community grant minting.
     */
    function mintWithPunks(uint[] calldata _punkIds, bool _isWrapped) external reentrancyGuard returns (uint) {
        require(communityGrant);
        require(!marketPaused);
        for (uint i; i < _punkIds.length; i++) {
            uint _punkId = _punkIds[i];
            require(_punkId >= 0 && _punkId < 10000, "Invalid punk index.");
            require(!getBoolean(punkIDsUsed,_punkId), "Already minted with this punk");
        
            // Make sure the sender owns the punk
            if (_isWrapped) {
                require(CryptopunksInterface(punksContract).punkIndexToAddress(_punkId) == msg.sender, "Not the owner of this punk.");
            } else {
                require(WrappedPunksInterface(wrappedPunksContract).ownerOf(_punkId) == msg.sender, "Not the owner of this punk.");
            }
            setBoolean(punkIDsUsed,_punkId,true);
            return _mint(msg.sender, _punkId);
        }
    }

    /**
     * Public sale minting.
     */
    function mint() external payable reentrancyGuard returns (uint) {
        require(publicSale, "Sale not started.");
        require(!marketPaused);
        require(numSales < SALE_LIMIT, "Sale limit reached.");
        uint salePrice = getPrice();
        require(msg.value >= salePrice, "Insufficient funds to purchase.");
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value-salePrice);
        }
        beneficiary.transfer(salePrice);
        numSales++;
        return _mint(msg.sender, 10000);
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

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
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

    function tokenByIndex(uint256 index) public pure returns (uint256) {
        require(index >= 0 && index < TOKEN_LIMIT);
        return index + 1;
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
        return string(abi.encodePacked("https://meebits.larvalabs.com/meebit/", toString(_tokenId)));
    }

}