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

interface FungibleChromaInterface {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract Chroma is IERC721 {
    using SafeMath for uint256;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint256 public numTokens;

    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(uint256 => address) public idToOwner;
    mapping(uint256 => address) internal idToApproval;
    mapping(address => mapping(address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) public ownerToIds;
    mapping(uint256 => uint256) public idToOwnerIndex;

    string internal nftName = "Chroma";
    string internal nftSymbol = unicode"■";

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

    constructor(address payable _adminAddress) {
        adminAddress = _adminAddress;
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }

    function _mintNFT(
        address _recipient,
        uint256 red,
        uint256 green,
        uint256 blue
    ) internal {
        _addNFToken(_recipient, _RGBToId(red, green, blue));
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(
            idToOwner[_tokenId] == address(0),
            "Cannot add, already owned."
        );
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
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        // revert("Invalid hex digit");
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

    function toHex(uint256 _id) external pure returns (string memory) {
        string memory r = toHexString(idToRed(_id));
        string memory g = toHexString(idToGreen(_id));
        string memory b = toHexString(idToBlue(_id));
        return string(abi.encodePacked(r, g, b));
    }

    function toRGBString(uint256 _id) public pure returns (string memory) {
        string memory r = toString(idToRed(_id));
        string memory g = toString(idToGreen(_id));
        string memory b = toString(idToBlue(_id));
        return string(abi.encodePacked("rgb(", r, ",", g, ",", b, ")"));
    }

    function idToRed(uint256 _id) public pure returns (uint256) {
        return _id >> 16;
    }

    function idToGreen(uint256 _id) public pure returns (uint256) {
        return (_id & 0xffff) >> 8;
    }

    function idToBlue(uint256 _id) public pure returns (uint256) {
        return _id & 0xff;
    }

    function _RGBToId(
        uint256 red,
        uint256 green,
        uint256 blue
    ) internal pure returns (uint256) {
        return (red << 16) + (green << 8) + blue;
    }

    function RGBToId(
        uint256 _red,
        uint256 _green,
        uint256 _blue
    ) public pure returns (uint256) {
        return _RGBToId(_red, _green, _blue);
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
    address public chromaticPlotAddress;
    address public fungibleChromaAddress;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin.");
        _;
    }

    function setAdmin(address payable _newAdmin) external onlyAdmin {
        adminAddress = _newAdmin;
    }

    function setChromaticPlotAddress(address _chromaticPlotAddress) external onlyAdmin {
        chromaticPlotAddress = _chromaticPlotAddress;
    }

    function setFungibleChromaAddress(address _fungibleChromaAddress)
        external
        onlyAdmin
    {
        fungibleChromaAddress = _fungibleChromaAddress;
    }

    //////////////////////////
    ////   Transmutation  ////
    //////////////////////////
    event PlotTransmutation(
        address indexed transmuter,
        uint256 index,
        uint256 count,
        uint256 blueStart,
        uint256 red,
        uint256 green
    );

    modifier onlyChromaticPlot() {
        require(msg.sender == chromaticPlotAddress, "Only Mint Plot.");
        _;
    }

    mapping(uint256 => uint256) public transmutationCount;

    function transmutePlotToNFTs(
        address _recipient,
        uint256 _plotId,
        uint256 _count
    ) external onlyChromaticPlot returns (bool) {
        return _transmute(_recipient, _plotId, _count);
    }

    function transmutePlotToERC20(
        address _recipient,
        uint256 _plotId,
        uint256 _count
    ) external onlyChromaticPlot returns (bool) {
        bool complete = _transmute(address(this), _plotId, _count);
        FungibleChromaInterface(fungibleChromaAddress).mint(_recipient, _count);
        return complete;
    }

    function _transmute(
        address _recipient,
        uint256 _plotId,
        uint256 _count
    ) internal returns (bool) {
        require(
            transmutationCount[_plotId] + _count <= 256,
            "exceeds chroma remaining"
        );
        require(
            _count <= 128,
            "cannot transmute more than 128 chroma at a time"
        );

        uint256 index = transmutationCount[_plotId];
        transmutationCount[_plotId] += _count;

        uint256 red = _plotId.div(256);
        uint256 green = _plotId.mod(256);

        emit PlotTransmutation(
            _recipient,
            numTokens,
            _count,
            index,
            red,
            green
        );

        for (uint256 blue = index; blue < index + _count; blue++) {
            _mintNFT(_recipient, red, green, blue);
        }
        if (transmutationCount[_plotId] == 256) return true;

        numTokens = numTokens + _count;
        return false;
    }

    function transmuteSingleToNFT(uint256 _id) external reentrancyGuard {
        require(
            idToOwner[_id] == address(this),
            "token must be owned by sender"
        );
        FungibleChromaInterface(fungibleChromaAddress).burn(msg.sender, 1);
        _transfer(msg.sender, _id);
    }

    function transmuteMultipleToNFT(uint256[] calldata _ids) external reentrancyGuard {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(
                idToOwner[id] == address(this),
                "token must be owned by sender"
            );
            _transfer(msg.sender, id);
        }
        FungibleChromaInterface(fungibleChromaAddress).burn(
            msg.sender,
            _ids.length
        );
    }

    function transmuteSingleToERC20(uint256 _id) external reentrancyGuard {
        require(idToOwner[_id] == msg.sender, "token must be owned by sender");
        _transfer(address(this), _id);
        FungibleChromaInterface(fungibleChromaAddress).mint(msg.sender, 1);
    }

    function transmuteMultipleToERC20(uint256[] calldata _ids) external reentrancyGuard {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                idToOwner[_ids[i]] == msg.sender,
                "token must be owned by sender"
            );
            _transfer(address(this), _ids[i]);
        }
        FungibleChromaInterface(fungibleChromaAddress).mint(
            msg.sender,
            _ids.length
        );
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


}