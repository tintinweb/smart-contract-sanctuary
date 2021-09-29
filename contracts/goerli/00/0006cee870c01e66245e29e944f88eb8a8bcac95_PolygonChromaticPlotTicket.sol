/**
 *Submitted for verification at Etherscan.io on 2021-09-29
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

interface ChromaticPlotInterface {
    function getOwnedTokenIds(address owner)
        external
        view
        returns (uint256[] memory);


    function getOwnedTokenIdsSegment(
        address owner,
        uint256 startIndex,
        uint256 count
    ) external view returns (uint256[] memory);

    function getTransmutingTokenIds(address owner)
        external
        view
        returns (uint256[] memory);

    function getTransmutingTokenIdsSegment(
        address owner,
        uint256 startIndex,
        uint256 count
    ) external view returns (uint256[] memory);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transmutingBalanceOf(address transmuter) external view returns (uint256 balance);

}


contract PolygonChromaticPlotTicket is IERC721 {
    using SafeMath for uint256;

    /**
     * Event emitted when minting a new NFT. "createdVia" is the index of the Cryptopunk/Autoglyph that was used to mint, or 0 if not applicable.
     */
    event Mint(uint256 indexed index, address indexed minter);


    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint256 public networkId;
    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(uint256 => address) public idToOwner;
    mapping(uint256 => address) internal idToApproval;
    mapping(address => mapping(address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) public ownerToIds;
    mapping(uint256 => uint256) public idToOwnerIndex;
    mapping(uint256 => bool) public redeemed;

    string internal nftName = "Polygon Chromatic Plot Ticket";
    string internal nftSymbol = "ticket";

    uint256 public numTokens = 0;
    uint256 public numSales = 0;

    address public chromaticPlot;


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

    constructor(address payable _adminAddress, address _chromaticPlot, uint _networkId) {
        networkId = _networkId;
        adminAddress = _adminAddress;
        chromaticPlot = _chromaticPlot;

        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }

    function getReedamableCount(address _owner) external view returns(uint) {
        uint count = 0;
        uint[] memory ownedTokenIds = ChromaticPlotInterface(chromaticPlot).getOwnedTokenIds(_owner);
        for (uint i=0; i < ownedTokenIds.length; i++) {
            uint ownedId = ownedTokenIds[i];
            if (!redeemed[ownedId]) {
                count += 1;
            }
        }

        uint[] memory transmutingTokenIds = ChromaticPlotInterface(chromaticPlot).getTransmutingTokenIds(_owner);
        for (uint i=0; i < transmutingTokenIds.length; i++) {
            uint transmutingId = transmutingTokenIds[i];
            if (!redeemed[transmutingId]) {
                count += 1;
            }
        }
        return count;
    }

    function redeemAll() external reentrancyGuard {
        uint[] memory ownedTokenIds = ChromaticPlotInterface(chromaticPlot).getOwnedTokenIds(msg.sender);
        for (uint i=0; i < ownedTokenIds.length; i++) {
            uint ownedId = ownedTokenIds[i];
            if (!redeemed[ownedId]) {
                _mint(msg.sender, ownedId);
                redeemed[ownedId] = true;
            }
        }

        uint[] memory transmutingTokenIds = ChromaticPlotInterface(chromaticPlot).getTransmutingTokenIds(msg.sender);
        for (uint i=0; i < transmutingTokenIds.length; i++) {
            uint transmutingId = transmutingTokenIds[i];
            if (!redeemed[transmutingId]) {
                _mint(msg.sender, transmutingId);
                redeemed[transmutingId] = true;
            }
        }
    }

    function redeemOwnedFromIndex(uint _startIndex, uint256 _quantity) external reentrancyGuard {
        uint[] memory ownedTokenIds = ChromaticPlotInterface(chromaticPlot).getOwnedTokenIdsSegment(msg.sender, _startIndex, _quantity);
        for (uint i=0; i < ownedTokenIds.length; i++) {
            uint ownedId = ownedTokenIds[i];
            if (!redeemed[ownedId]) {
                _mint(msg.sender, ownedId);
                redeemed[ownedId] = true;
            }
        }
    }

    function redeemTransmutingFromIndex(uint _startIndex, uint256 _quantity) external reentrancyGuard {
        uint[] memory transmutingTokenIds = ChromaticPlotInterface(chromaticPlot).getTransmutingTokenIdsSegment(msg.sender, _startIndex, _quantity);
        for (uint i=0; i < transmutingTokenIds.length; i++) {
            uint transmutingId = transmutingTokenIds[i];
            if (!redeemed[transmutingId]) {
                _mint(msg.sender, transmutingId);
                redeemed[transmutingId] = true;
            }
        }
    }

    


    function _mint(address _to, uint _id) internal returns (uint256) {
        require(_to != address(0), "Cannot mint to 0x0.");
        numTokens = numTokens + 1;
        _addNFToken(_to, _id);
        emit Mint(_id, _to);
        emit Transfer(address(0), _to, _id);
        return _id;
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