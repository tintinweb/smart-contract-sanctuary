/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity 0.7.6;
pragma abicoder v2;

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, throws on overflow.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        return a % b;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

interface ChromaInterface {
    function transmutePlotToNFTs(
        address _recipient,
        uint256 _plotId,
        uint256 _count
    ) external returns (bool);

    function transmutePlotToERC20(
        address _recipient,
        uint256 _plotId,
        uint256 _count
    ) external returns (bool);

    function toHex(uint256 _id) external view returns (string memory);
}

contract ChromaticPlot is IERC721 {
    using SafeMath for uint256;

    /**
     * Event emitted when minting a new NFT. "createdVia" is the index of the Cryptopunk/Autoglyph that was used to mint, or 0 if not applicable.
     */
    event Mint(uint256 indexed index, address indexed minter, bool isDevMint);

    /**
     * Event emitted when the public sale begins.
     */
    event ReleaseBegins(
        uint256 price,
        uint256 minPrice,
        uint256 startTime,
        uint256 duration,
        uint256 quantity
    );

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint256 public constant TOKEN_LIMIT = 65536;
    uint256 public constant TOTAL_SALE_LIMIT = 52428;

    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(uint256 => address) public idToOwner;
    mapping(uint256 => address) internal idToApproval;
    mapping(address => mapping(address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) public ownerToIds;
    mapping(uint256 => uint256) public idToOwnerIndex;

    string internal nftName = "Chromatic Plot";
    string internal nftSymbol = unicode"▦";

    uint256 public numTokens = 0;
    uint256 public numSales = 0;

    address public chroma;

    bool public publicSale = false;
    uint256 public minPrice;
    uint256 private price;
    uint256 public saleStartTime;
    uint256 public saleDuration;
    uint256 public saleCount;

    //// Random index assignment
    uint256 internal nonce = 0;
    uint256[TOKEN_LIMIT] internal indices;

    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "Cannot transfer."
        );
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "Cannot operate."
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    constructor(address payable _adminAddress, address _chroma) {
        adminAddress = _adminAddress;
        chroma = _chroma;

        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }

    function startRelease(
        uint256 _price,
        uint256 _minPrice,
        uint256 _saleDuration,
        uint256 _quantity
    ) external onlyAdmin {
        require(!publicSale);
        require(saleCount + _quantity <= TOTAL_SALE_LIMIT);
        minPrice = _minPrice;
        price = _price;
        saleDuration = _saleDuration;
        saleStartTime = block.timestamp;
        publicSale = true;
        saleCount = numSales + _quantity;
        emit ReleaseBegins(
            _price,
            _minPrice,
            saleStartTime,
            saleDuration,
            _quantity
        );
    }

    function interruptRelease() external onlyAdmin {
        publicSale = false;
    }

    function mintsRemaining() external view returns (uint256) {
        return saleCount.sub(numSales);
    }

    function randomIndex() internal returns (uint256) {
        uint256 totalSize = TOKEN_LIMIT - numTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
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
        return value.add(1);
    }

    // Calculate the mint price
    function getPrice() public view returns (uint256) {
        require(publicSale, "Sale not started.");
        uint256 elapsed = block.timestamp.sub(saleStartTime);
        if (elapsed >= saleDuration) {
            return minPrice;
        } else {
            return
                saleDuration.sub(elapsed).mul(price).div(saleDuration) >
                    minPrice
                    ? saleDuration.sub(elapsed).mul(price).div(saleDuration)
                    : minPrice;
        }
    }

    function mint(uint256 _quantity) external payable reentrancyGuard {
        require(publicSale, "Sale not started.");
        require(numSales + _quantity <= saleCount, "Exceeds sale limit.");
        require(_quantity > 0 && _quantity <= 8, "Invalid quantity.");
        uint256 salePrice = getPrice();
        require(
            msg.value >= salePrice.mul(_quantity),
            "Insufficient funds to purchase."
        );
        if (msg.value > salePrice.mul(_quantity)) {
            msg.sender.transfer(msg.value.sub(salePrice.mul(_quantity)));
        }
        adminAddress.transfer(salePrice.mul(_quantity));
        numSales = numSales + _quantity;
        for (uint256 i = 0; i < _quantity; i++) {
            _mint(msg.sender, false);
        }
    }

    function devMint(uint256 quantity, address recipient) external onlyAdmin {
        for (uint256 i = 0; i < quantity; i++) {
            _mint(recipient, true);
        }
    }

    function _mint(address _to, bool _isDevMint) internal returns (uint256) {
        require(_to != address(0), "Cannot mint to 0x0.");
        require(numSales < TOKEN_LIMIT, "Sale limit reached.");

        uint256 id = randomIndex();
        numTokens = numTokens + 1;
        _addNFToken(_to, id);
        emit Mint(id, _to, _isDevMint);
        emit Transfer(address(0), _to, id);
        return id;
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        idToOwner[_tokenId] = _to;
        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

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

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //////////////////////////
    ////    Enumerable    ////
    //////////////////////////

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256)
    {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    //////////////////////////
    ////  Administration  ////
    //////////////////////////
    address payable public adminAddress;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin.");
        _;
    }

    function setAdmin(address payable _newAdmin) external onlyAdmin {
        adminAddress = _newAdmin;
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////
    function isContract(address _addr)
        internal
        view
        returns (bool addressCheck)
    {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        } // solhint-disable-line
        addressCheck = size > 0;
    }

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        override
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        override
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address _owner)
    {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    //////////////////////////
    ////   Transmutation  ////
    //////////////////////////

    event TransmutationToNFT(uint256 indexed plotId, uint256 count);
    event TransmutationToERC20(uint256 indexed plotId, uint256 count);

    mapping(uint256 => address) public idToTransmuter;
    mapping(address => uint256[]) public transmuterToIds;
    mapping(uint256 => uint256) public idToTransmuterIndex;

    function _addToTransmutations(address _to, uint256 _tokenId) internal {
        idToTransmuter[_tokenId] = _to;
        transmuterToIds[_to].push(_tokenId);
        idToTransmuterIndex[_tokenId] = transmuterToIds[_to].length.sub(1);
    }

    function _removeFromTransmutations(address _from, uint256 _tokenId)
        internal
    {
        require(idToTransmuter[_tokenId] == _from, "Incorrect owner.");
        delete idToTransmuter[_tokenId];

        uint256 tokenToRemoveIndex = idToTransmuterIndex[_tokenId];
        uint256 lastTokenIndex = transmuterToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = transmuterToIds[_from][lastTokenIndex];
            transmuterToIds[_from][tokenToRemoveIndex] = lastToken;
            idToTransmuterIndex[lastToken] = tokenToRemoveIndex;
        }

        transmuterToIds[_from].pop();
    }

    function transmuteChromaNFT(uint256 _plotId, uint256 _count) external {
        require(
            idToOwner[_plotId] == msg.sender ||
                idToTransmuter[_plotId] == msg.sender,
            "No access rights to transmute."
        );
        require(_count > 0, "count must be greater than 0");
        emit TransmutationToNFT(_plotId, _count);

        if (idToOwner[_plotId] == msg.sender) {
            _clearApproval(_plotId);
            _removeNFToken(msg.sender, _plotId);
            idToTransmuter[_plotId] = msg.sender;
            _addToTransmutations(msg.sender, _plotId);
            emit Transfer(msg.sender, address(0), _plotId);
        }
        bool complete = ChromaInterface(chroma).transmutePlotToNFTs(
            msg.sender,
            _plotId,
            _count
        );
        if (complete) _removeFromTransmutations(msg.sender, _plotId);
    }

    function transmuteChromaERC20(uint256 _plotId, uint256 _count) external {
        require(
            idToOwner[_plotId] == msg.sender ||
                idToTransmuter[_plotId] == msg.sender,
            "No access rights to transmute."
        );
        require(_count > 0, "count must be greater than 0");
        emit TransmutationToERC20(_plotId, _count);

        if (idToOwner[_plotId] == msg.sender) {
            _clearApproval(_plotId);
            _removeNFToken(msg.sender, _plotId);
            idToTransmuter[_plotId] = msg.sender;
            _addToTransmutations(msg.sender, _plotId);
            emit Transfer(msg.sender, address(0), _plotId);
        }
        bool complete = ChromaInterface(chroma).transmutePlotToERC20(
            msg.sender,
            _plotId,
            _count
        );
        if (complete) _removeFromTransmutations(msg.sender, _plotId);
    }

    function getOwnedTokenIds(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = ownerToIds[owner].length;
        uint256[] memory owned = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            owned[i] = ownerToIds[owner][i];
        }
        return owned;
    }

    function getTransmutingTokenIds(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = transmuterToIds[owner].length;
        uint256[] memory transmuting = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            transmuting[i] = transmuterToIds[owner][i];
        }
        return transmuting;
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }

    function toHexString(uint256 a) public pure returns (string memory) {
        uint256 count = 2;
        uint256 b = a;
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(res);
    }

    function toHex(
        uint256 _red,
        uint256 _green,
        uint256 _blue
    ) public pure returns (string memory) {
        string memory r = toHexString(_red);
        string memory g = toHexString(_green);
        string memory b = toHexString(_blue);
        return string(abi.encodePacked(r, g, b));
    }

    function getData(uint256 _plotId) public pure returns (string[][] memory) {
        string[][] memory plot = new string[][](16);
        uint256 red = _plotId.div(256);
        uint256 green = _plotId.mod(256);

        uint256 blue = 0;
        for (uint256 y = 0; y < 16; y++) {
            string[] memory row = new string[](16);
            for (uint256 x = 0; x < 16; x++) {
                row[x] = toHex(red, green, blue);
                blue = blue + 1;
            }
            plot[y] = row;
        }
        return plot;
    }

    //////////////////////////
    ////     Metadata     ////
    //////////////////////////

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
}