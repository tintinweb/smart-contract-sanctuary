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
    function toHex(uint256 _id) external view returns (string memory);
}

contract ChromaticCanvas is IERC721 {
    using SafeMath for uint256;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(uint256 => address) public idToOwner;
    mapping(uint256 => address) internal idToApproval;
    mapping(address => mapping(address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) public ownerToIds;
    mapping(uint256 => uint256) public idToOwnerIndex;

    string internal nftName = "Chromatic Canvas";
    string internal nftSymbol = unicode"□";

    uint256 public numTokens = 0;

    address public chroma;

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
    uint256 public maxHeight = 64;
    uint256 public maxWidth = 64;
    uint256 public canvasCreationPrice = 0;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin.");
        _;
    }

    function setAdmin(address payable _newAdmin) external onlyAdmin {
        adminAddress = _newAdmin;
    }

    function setMaxDimensions(uint256 _maxHeight, uint256 _maxWidth)
        external
        onlyAdmin
    {
        require(
            _maxHeight <= uint128(-1) && _maxWidth <= uint128(-1),
            "exceeds max possible"
        );
        maxHeight = _maxHeight;
        maxWidth = _maxWidth;
    }


    function setCanvasCreationPrice(uint256 _price) external onlyAdmin {
        canvasCreationPrice = _price;
        emit CanvasCreationPriceChanged(_price);
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
        _unlockCanvas(_tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    //////////////////////////
    ////      Canvas      ////
    //////////////////////////

    event CanvasCreated(
        uint256 indexed canvasId,
        uint256 baseChromaId,
        uint256 height,
        uint256 width,
        string name,
        string author
    );
    event BaseChromaChanged(uint256 indexed canvasId, uint256 baseChromaId);
    event ChromaAddedToCanvas(uint256 indexed canvasId, uint256 chromaId);
    event ChromaRemovedFromCanvas(uint256 indexed canvasId, uint256 chromaId);
    event LocationAddedToChroma(
        uint256 indexed canvasId,
        uint256 chromaId,
        uint256 key,
        uint256 y,
        uint256 x
    );
    event LocationRemovedFromChroma(
        uint256 indexed canvasId,
        uint256 chromaId,
        uint256 key
    );
    event CanvasLocked(uint256 indexed canvasId, address owner);
    event CanvasUnlocked(uint256 indexed canvasId, address owner);
    event CanvasDestroyed(uint256 indexed canvasId, address destroyer);
    event CanvasCreationPriceChanged(uint256 newPrice);
    event NameChanged(uint256 indexed canvasId, string name);
    event AuthorChanged(uint256 indexed canvasId, string author);

    uint256 public tokenIndex = 0;

    mapping(uint256 => string) public idToName;
    mapping(uint256 => string) public idToAuthor;

    mapping(uint256 => uint128[2]) public idToDimensions;
    mapping(uint256 => uint256[]) public canvasToChroma;
    mapping(uint256 => uint256) public chromaToCanvasIndex;
    mapping(uint256 => uint256) public chromaToCanvas;
    mapping(uint256 => address) public lockedBy;

    mapping(uint256 => uint256) public baseChroma;
    mapping(uint256 => mapping(uint256 => uint256)) public locationToChroma;
    mapping(uint256 => mapping(uint256 => uint256)) public locationToChromaIndex;
    mapping(uint256 => uint256[]) public chromaToLocations;

    modifier notLocked(uint256 _canvasId) {
        require(lockedBy[_canvasId] == address(0), "must be unlocked");
        _;
    }

    modifier onlyCanvasOwner(uint256 _canvasId) {
        require(idToOwner[_canvasId] == msg.sender, "must be owner");
        _;
    }

    function lockUntilTransfer(uint256 _canvasId)
        external
        onlyCanvasOwner(_canvasId)
    {
        lockedBy[_canvasId] = msg.sender;
        emit CanvasLocked(_canvasId, msg.sender);
    }

    function _unlockCanvas(uint256 _canvasId) internal {
        require(lockedBy[_canvasId] != address(0), "must be locked");
        require(lockedBy[_canvasId] != idToOwner[_canvasId], "must be transferred");
        lockedBy[_canvasId] = address(0);
        emit CanvasUnlocked(_canvasId, msg.sender);
    }


    function changeName(uint256 _canvasId, string calldata _name)
        external
        onlyCanvasOwner(_canvasId)
        notLocked(_canvasId)
    {
        idToName[_canvasId] = _name;
        emit NameChanged(_canvasId, _name);
    }

    function changeAuthor(uint256 _canvasId, string calldata _author)
        external
        onlyCanvasOwner(_canvasId)
        notLocked(_canvasId)
    {
        idToAuthor[_canvasId] = _author;
        emit AuthorChanged(_canvasId, _author);
    }

    function createCanvas(
        uint256 _baseChromaId,
        uint128 _height,
        uint128 _width,
        string calldata _name,
        string calldata _author
    ) external payable reentrancyGuard {
        require(
            msg.value >= canvasCreationPrice,
            "Insufficient funds to purchase."
        );
        if (msg.value > canvasCreationPrice) {
            msg.sender.transfer(msg.value.sub(canvasCreationPrice));
        }
        adminAddress.transfer(canvasCreationPrice);
        IERC721(chroma).transferFrom(msg.sender, address(this), _baseChromaId);
        require(
            _height > 0 && _width > 0,
            "both dimensions must be larger than 0"
        );
        require(
            _height <= maxHeight && _width <= maxWidth,
            "exceeds max dimension"
        );
        numTokens += 1;
        tokenIndex += 1;
        uint256 id = tokenIndex;
        _addNFToken(msg.sender, id);
        baseChroma[id] = _baseChromaId;
        idToName[id] = _name;
        idToAuthor[id] = _author;
        idToDimensions[id] = [_height, _width];
        // idToHeight[id] = _height;
        // idToWidth[id] = _width;
        emit CanvasCreated(id, _baseChromaId, _height, _width, _name, _author);
        emit Transfer(address(0), msg.sender, id);
    }

    function destroyCanvas(uint256 _canvasId)
        external
        onlyCanvasOwner(_canvasId)
        notLocked(_canvasId)
    {
        while (canvasToChroma[_canvasId].length != 0) {
            _removeChromaFromCanvas(
                canvasToChroma[_canvasId][canvasToChroma[_canvasId].length - 1]
            );
        }

        IERC721(chroma).transferFrom(
            address(this),
            msg.sender,
            baseChroma[_canvasId]
        );
        baseChroma[_canvasId] = 0;
        _clearApproval(_canvasId);
        _removeNFToken(msg.sender, _canvasId);
        numTokens = numTokens - 1;
        emit Transfer(msg.sender, address(0), _canvasId);
        emit CanvasDestroyed(_canvasId, msg.sender);
    }

    function changeBaseChroma(uint256 _baseChromaId, uint256 _canvasId)
        external
        onlyCanvasOwner(_canvasId)
        notLocked(_canvasId)
    {
        IERC721(chroma).transferFrom(msg.sender, address(this), _baseChromaId);
        IERC721(chroma).transferFrom(
            address(this),
            msg.sender,
            baseChroma[_canvasId]
        );
        baseChroma[_canvasId] = _baseChromaId;
        emit BaseChromaChanged(_canvasId, _baseChromaId);
    }

    function addChromaToCanvas(
        uint256 _canvasId,
        uint256 _chromaId,
        uint128[][] calldata _locations
    ) external onlyCanvasOwner(_canvasId) notLocked(_canvasId) {
        IERC721(chroma).transferFrom(msg.sender, address(this), _chromaId);

        uint128[2] storage dimensions = idToDimensions[_canvasId];
        uint128 height = dimensions[0];
        uint128 width = dimensions[1];

        for (uint256 i = 0; i < _locations.length; i++) {
            uint256 y = _locations[i][0];
            uint256 x = _locations[i][1];
            require(y < height && x < width, "out of bounds");
            uint256 key = (y << 128) + x;
            _addChromaToLocation(_canvasId, _chromaId, key);
            emit LocationAddedToChroma(_canvasId, _chromaId, key, y, x);
        }
        chromaToCanvas[_chromaId] = _canvasId;
        canvasToChroma[_canvasId].push(_chromaId);
        chromaToCanvasIndex[_chromaId] = canvasToChroma[_canvasId].length.sub(1);
        emit ChromaAddedToCanvas(_canvasId, _chromaId);
    }

    function addChromaLocations(
        uint256 _canvasId,
        uint256 _chromaId,
        uint128[][] calldata _locations
    ) external onlyCanvasOwner(_canvasId) notLocked(_canvasId) {
        require(
            chromaToCanvas[_chromaId] == _canvasId || _chromaId == baseChroma[_canvasId],
            "chroma not in canvas"
        );
        if (_chromaId == baseChroma[_canvasId]) {
            _removeChromaFromLocation(_canvasId, _locations);
            return;
        }

        uint128[2] storage dimensions = idToDimensions[_canvasId];
        uint128 height = dimensions[0];
        uint128 width = dimensions[1];

        for (uint256 i = 0; i < _locations.length; i++) {
            uint256 y = _locations[i][0];
            uint256 x = _locations[i][1];
            require(y < height && x < width, "out of bounds");
            uint256 key = (y << 128) + x;
            _addChromaToLocation(_canvasId, _chromaId, key);
            emit LocationAddedToChroma(_canvasId, _chromaId, key, y, x);
        }
    }

    function removeChromaFromCanvas(uint256 _canvasId, uint256 _chromaId)
        external
        onlyCanvasOwner(_canvasId)
        notLocked(_canvasId)
    {
        require(chromaToCanvas[_chromaId] == _canvasId, "chroma not in canvas");
        _removeChromaFromCanvas(_chromaId);
    }

    function _removeChromaFromCanvas(uint256 _chromaId) internal {
        delete chromaToLocations[_chromaId];
        uint256 canvasId = chromaToCanvas[_chromaId];
        chromaToCanvas[_chromaId] = 0;

        uint256 chromaToRemoveIndex = chromaToCanvasIndex[_chromaId];
        uint256 lastTokenIndex = canvasToChroma[canvasId].length.sub(1);

        if (lastTokenIndex != chromaToRemoveIndex) {
            uint256 lastToken = canvasToChroma[canvasId][lastTokenIndex];
            canvasToChroma[canvasId][chromaToRemoveIndex] = lastToken;
            chromaToCanvasIndex[lastToken] = chromaToRemoveIndex;
        }
        canvasToChroma[canvasId].pop();

        IERC721(chroma).transferFrom(address(this), msg.sender, _chromaId);
        emit ChromaRemovedFromCanvas(canvasId, _chromaId);
    }

    function _addChromaToLocation(
        uint256 _canvasId,
        uint256 _chromaId,
        uint256 key
    ) internal {
        if (locationToChroma[_canvasId][key] == _chromaId) {
            // chroma already in location
            return;
        } else if (
            locationToChroma[_canvasId][key] != 0 &&
            chromaToCanvas[locationToChroma[_canvasId][key]] == _canvasId
        ) {
            // another chroma is in location
            _removeChromaFromLocation(
                _canvasId,
                locationToChroma[_canvasId][key],
                key
            );
        }
        locationToChroma[_canvasId][key] = _chromaId;
        chromaToLocations[_chromaId].push(key);
        locationToChromaIndex[_canvasId][key] = chromaToLocations[_chromaId]
            .length
            .sub(1);
    }

    function _removeChromaFromLocation(
        uint256 _canvasId,
        uint128[][] calldata _locations
    ) internal {
        uint128[2] storage dimensions = idToDimensions[_canvasId];
        uint128 height = dimensions[0];
        uint128 width = dimensions[1];
        for (uint256 i = 0; i < _locations.length; i++) {
            uint256 y = _locations[i][0];
            uint256 x = _locations[i][1];
            require(y < height && x < width, "out of bounds");
            uint256 key = (y << 128) + x;
            uint256 chromaId = locationToChroma[_canvasId][key];
            require(chromaId != 0);
            _removeChromaFromLocation(_canvasId, chromaId, key);
        }
    }

    function _removeChromaFromLocation(
        uint256 _canvasId,
        uint256 _chromaId,
        uint256 key
    ) internal {
        delete locationToChroma[_canvasId][key];

        uint256 locationToRemoveIndex = locationToChromaIndex[_canvasId][key];
        uint256 lastChromaIndex = chromaToLocations[_chromaId].length.sub(1);

        if (lastChromaIndex != locationToRemoveIndex) {
            uint256 lastToken = chromaToLocations[_chromaId][lastChromaIndex];
            chromaToLocations[_chromaId][locationToRemoveIndex] = lastToken;
            locationToChromaIndex[_canvasId][lastToken] = locationToRemoveIndex;
        }
        chromaToLocations[_chromaId].pop();
        if (chromaToLocations[_chromaId].length == 0) {
            _removeChromaFromCanvas(_chromaId);
        }
        emit LocationRemovedFromChroma(_canvasId, _chromaId, key);
    }

    function idToHeight(uint _id) public view returns(uint128) {
        return idToDimensions[_id][0];
    }

    function idToWidth(uint _id) public view returns(uint128) {
        return idToDimensions[_id][1];
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

    function getChromaCount(uint256 _canvasId) public view returns (uint) {
        return canvasToChroma[_canvasId].length;
    }


    function getChromaInCanvas(uint256 _canvasId)
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = canvasToChroma[_canvasId].length;
        uint256[] memory chromaIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            chromaIds[i] = canvasToChroma[_canvasId][i];
        }
        return chromaIds;
    }

    function getChromaInCanvasInHex(uint256 _canvasId)
        public
        view
        returns (string[] memory)
    {
        uint256 length = canvasToChroma[_canvasId].length;
        string[] memory chromaHexValues = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            chromaHexValues[i] = ChromaInterface(chroma).toHex(
                canvasToChroma[_canvasId][i]
            );
        }
        return chromaHexValues;
    }

    function getBaseChromaHex(uint256 _canvasId)
        public
        view
        returns (string memory)
    {
        return ChromaInterface(chroma).toHex(baseChroma[_canvasId]);
    }

    function getData(uint256 _canvasId) public view returns (string[][] memory) {
        uint128[2] storage dimensions = idToDimensions[_canvasId];
        uint128 height = dimensions[0];
        uint128 width = dimensions[1];
        string memory baseChromaHex = ChromaInterface(chroma).toHex(
            baseChroma[_canvasId]
        );
        string[][] memory canvas = new string[][](height);
        for (uint256 y = 0; y < height; y++) {
            string[] memory row = new string[](width);
            for (uint256 x = 0; x < width; x++) {
                row[x] = baseChromaHex;
            }
            canvas[y] = row;
        }

        uint256[] storage chromaIds = canvasToChroma[_canvasId];
        for (uint256 i = 0; i < chromaIds.length; i++) {
            uint256 chromaId = chromaIds[i];
            uint256[] storage locations = chromaToLocations[chromaId];
            string memory chromaHex = ChromaInterface(chroma).toHex(chromaId);
            for (uint256 j = 0; j < locations.length; j++) {
                uint128 y = uint128(locations[j] >> 128);
                uint128 x = uint128(locations[j] & 0xffffffffffffffff);
                canvas[y][x] = chromaHex;
            }
        }
        return canvas;
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