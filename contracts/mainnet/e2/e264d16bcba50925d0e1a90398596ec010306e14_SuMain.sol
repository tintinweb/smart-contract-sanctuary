pragma solidity ^0.4.24;

/******************************************************************************\
*..................................SU SQUARES..................................*
*.......................Blockchain rentable advertising........................*
*..............................................................................*
* First, I just want to say we are so excited and humbled to get this far and  *
* that you&#39;re even reading this. So thank you!                                 *
*                                                                              *
* This file is organized into multiple contracts that separate functionality   *
* into logical parts. The deployed contract, SuMain, is at the bottom and      *
* includes the rest of the file using inheritance.                             *
*                                                                              *
*  - ERC165, ERC721: These interfaces follow the official EIPs                 *
*  - AccessControl: A reusable CEO/CFO/COO access model                        *
*  - SupportsInterface: An implementation of ERC165                            *
*  - SuNFT: An implementation of ERC721                                        *
*  - SuOperation: The actual square data and the personalize function          *
*  - SuPromo, SuVending: How we grant or sell squares                          *
*..............................................................................*
*............................Su & William Entriken.............................*
*...................................(c) 2018...................................*
\******************************************************************************/

/* AccessControl.sol **********************************************************/

/// @title Reusable three-role access control inspired by CryptoKitties
/// @author William Entriken (https://phor.net)
/// @dev Keep the CEO wallet stored offline, I warned you.
contract AccessControl {
    /// @notice The account that can only reassign executive accounts
    address public executiveOfficerAddress;

    /// @notice The account that can collect funds from this contract
    address public financialOfficerAddress;

    /// @notice The account with administrative control of this contract
    address public operatingOfficerAddress;

    constructor() internal {
        executiveOfficerAddress = msg.sender;
    }

    /// @dev Only allowed by executive officer
    modifier onlyExecutiveOfficer() {
        require(msg.sender == executiveOfficerAddress);
        _;
    }

    /// @dev Only allowed by financial officer
    modifier onlyFinancialOfficer() {
        require(msg.sender == financialOfficerAddress);
        _;
    }

    /// @dev Only allowed by operating officer
    modifier onlyOperatingOfficer() {
        require(msg.sender == operatingOfficerAddress);
        _;
    }

    /// @notice Reassign the executive officer role
    /// @param _executiveOfficerAddress new officer address
    function setExecutiveOfficer(address _executiveOfficerAddress)
        external
        onlyExecutiveOfficer
    {
        require(_executiveOfficerAddress != address(0));
        executiveOfficerAddress = _executiveOfficerAddress;
    }

    /// @notice Reassign the financial officer role
    /// @param _financialOfficerAddress new officer address
    function setFinancialOfficer(address _financialOfficerAddress)
        external
        onlyExecutiveOfficer
    {
        require(_financialOfficerAddress != address(0));
        financialOfficerAddress = _financialOfficerAddress;
    }

    /// @notice Reassign the operating officer role
    /// @param _operatingOfficerAddress new officer address
    function setOperatingOfficer(address _operatingOfficerAddress)
        external
        onlyExecutiveOfficer
    {
        require(_operatingOfficerAddress != address(0));
        operatingOfficerAddress = _operatingOfficerAddress;
    }

    /// @notice Collect funds from this contract
    function withdrawBalance() external onlyFinancialOfficer {
        financialOfficerAddress.transfer(address(this).balance);
    }
}

/* ERC165.sol *****************************************************************/

/// @title ERC-165 Standard Interface Detection
/// @dev Reference https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/* ERC721.sol *****************************************************************/

/// @title ERC-721 Non-Fungible Token Standard
/// @dev Reference https://eips.ethereum.org/EIPS/eip-721
interface ERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
interface ERC721Metadata /* is ERC721 */ {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
interface ERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/* SupportsInterface.sol ******************************************************/

/// @title A reusable contract to comply with ERC-165
/// @author William Entriken (https://phor.net)
contract SupportsInterface is ERC165 {
    /// @dev Every interface that we support, do not set 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() internal {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID] && (interfaceID != 0xffffffff);
    }
}

/* SuNFT.sol ******************************************************************/

/// @title Compliance with ERC-721 for Su Squares
/// @dev This implementation assumes:
///  - A fixed supply of NFTs, cannot mint or burn
///  - ids are numbered sequentially starting at 1.
///  - NFTs are initially assigned to this contract
///  - This contract does not externally call its own functions
/// @author William Entriken (https://phor.net)
contract SuNFT is ERC165, ERC721, ERC721Metadata, ERC721Enumerable, SupportsInterface {
    /// @dev The authorized address for each NFT
    mapping (uint256 => address) internal tokenApprovals;

    /// @dev The authorized operators for each address
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    /// @dev Guarantees msg.sender is the owner of _tokenId
    /// @param _tokenId The token to validate belongs to msg.sender
    modifier onlyOwnerOf(uint256 _tokenId) {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // assert(msg.sender != address(this))
        require(msg.sender == owner);
        _;
    }

    modifier mustBeOwnedByThisContract(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY);
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(owner == address(0) || owner == address(this));
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        // assert(msg.sender != address(this))
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(msg.sender == owner || operatorApprovals[owner][msg.sender]);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        // assert(msg.sender != address(this))
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(msg.sender == owner ||
          msg.sender == tokenApprovals[_tokenId] ||
          operatorApprovals[msg.sender][msg.sender]);
        _;
    }

    modifier mustBeValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY);
        _;
    }

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _tokensOfOwnerWithSubstitutions[_owner].length;
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (address _owner)
    {
        _owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Handle substitutions
        if (_owner == address(0)) {
            _owner = address(this);
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        payable
        mustBeValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Handle substitutions
        if (owner == address(0)) {
            owner = address(this);
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
        external
        payable
        // assert(mustBeValidToken(_tokenId))
        canOperate(_tokenId)
    {
        address _owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Handle substitutions
        if (_owner == address(0)) {
            _owner = address(this);
        }
        tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to
    ///  manage all of `msg.sender`&#39;s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (address)
    {
        return tokenApprovals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    // COMPLIANCE WITH ERC721Metadata //////////////////////////////////////////

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string) {
        return "Su Squares";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string) {
        return "SU";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (string _tokenURI)
    {
        _tokenURI = "https://tenthousandsu.com/erc721/00000.json";
        bytes memory _tokenURIBytes = bytes(_tokenURI);
        _tokenURIBytes[33] = byte(48+(_tokenId / 10000) % 10);
        _tokenURIBytes[34] = byte(48+(_tokenId / 1000) % 10);
        _tokenURIBytes[35] = byte(48+(_tokenId / 100) % 10);
        _tokenURIBytes[36] = byte(48+(_tokenId / 10) % 10);
        _tokenURIBytes[37] = byte(48+(_tokenId / 1) % 10);

    }

    // COMPLIANCE WITH ERC721Enumerable ////////////////////////////////////////

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one
    ///  has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < TOTAL_SUPPLY);
        return _index + 1;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId) {
        require(_owner != address(0));
        require(_index < _tokensOfOwnerWithSubstitutions[_owner].length);
        _tokenId = _tokensOfOwnerWithSubstitutions[_owner][_index];
        // Handle substitutions
        if (_owner == address(this)) {
            if (_tokenId == 0) {
                _tokenId = _index + 1;
            }
        }
    }

    // INTERNAL INTERFACE //////////////////////////////////////////////////////

    /// @dev Actually do a transfer, does NO precondition checking
    function _transfer(uint256 _tokenId, address _to) internal {
        // Here are the preconditions we are not checking:
        // assert(canTransfer(_tokenId))
        // assert(mustBeValidToken(_tokenId))
        require(_to != address(0));

        // Find the FROM address
        address fromWithSubstitution = _tokenOwnerWithSubstitutions[_tokenId];
        address from = fromWithSubstitution;
        if (fromWithSubstitution == address(0)) {
            from = address(this);
        }

        // Take away from the FROM address
        // The Entriken algorithm for deleting from an indexed, unsorted array
        uint256 indexToDeleteWithSubstitution = _ownedTokensIndexWithSubstitutions[_tokenId];
        uint256 indexToDelete;
        if (indexToDeleteWithSubstitution == 0) {
            indexToDelete = _tokenId - 1;
        } else {
            indexToDelete = indexToDeleteWithSubstitution - 1;
        }
        if (indexToDelete != _tokensOfOwnerWithSubstitutions[from].length - 1) {
            uint256 lastNftWithSubstitution = _tokensOfOwnerWithSubstitutions[from][_tokensOfOwnerWithSubstitutions[from].length - 1];
            uint256 lastNft = lastNftWithSubstitution;
            if (lastNftWithSubstitution == 0) {
                // assert(from ==  address(0) || from == address(this));
                lastNft = _tokensOfOwnerWithSubstitutions[from].length;
            }
            _tokensOfOwnerWithSubstitutions[from][indexToDelete] = lastNft;
            _ownedTokensIndexWithSubstitutions[lastNft] = indexToDelete + 1;
        }
        delete _tokensOfOwnerWithSubstitutions[from][_tokensOfOwnerWithSubstitutions[from].length - 1]; // get gas back
        _tokensOfOwnerWithSubstitutions[from].length--;
        // Right now _ownedTokensIndexWithSubstitutions[_tokenId] is invalid, set it below based on the new owner

        // Give to the TO address
        _tokensOfOwnerWithSubstitutions[_to].push(_tokenId);
        _ownedTokensIndexWithSubstitutions[_tokenId] = (_tokensOfOwnerWithSubstitutions[_to].length - 1) + 1;

        // External processing
        _tokenOwnerWithSubstitutions[_tokenId] = _to;
        tokenApprovals[_tokenId] = address(0);
        emit Transfer(from, _to, _tokenId);
    }

    // PRIVATE STORAGE AND FUNCTIONS ///////////////////////////////////////////

    // See Solidity issue #3356, it would be clearer to initialize in SuMain
    uint256 private constant TOTAL_SUPPLY = 10000;

    bytes4 private constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @dev The owner of each NFT
    ///  If value == address(0), NFT is owned by address(this)
    ///  If value != address(0), NFT is owned by value
    ///  assert(This contract never assigns awnerhip to address(0) or destroys NFTs)
    ///  See commented out code in constructor, saves hella gas
    mapping (uint256 => address) private _tokenOwnerWithSubstitutions;

    /// @dev The list of NFTs owned by each address
    ///  Nomenclature: this[key][index] = value
    ///  If key != address(this) or value != 0, then value represents an NFT
    ///  If key == address(this) and value == 0, then index + 1 is the NFT
    ///  assert(0 is not a valid NFT)
    ///  See commented out code in constructor, saves hella gas
    mapping (address => uint256[]) private _tokensOfOwnerWithSubstitutions;

    /// @dev (Location + 1) of each NFT in its owner&#39;s list
    ///  Nomenclature: this[key] = value
    ///  If value != 0, _tokensOfOwnerWithSubstitutions[owner][value - 1] = nftId
    ///  If value == 0, _tokensOfOwnerWithSubstitutions[owner][key - 1] = nftId
    ///  assert(2**256-1 is not a valid NFT)
    ///  See commented out code in constructor, saves hella gas
    mapping (uint256 => uint256) private _ownedTokensIndexWithSubstitutions;

    // Due to implementation choices (no mint, no burn, contiguous NFT ids), it
    // is not necessary to keep an array of NFT ids nor where each NFT id is
    // located in that array.
    // address[] private nftIds;
    // mapping (uint256 => uint256) private nftIndexOfId;

    constructor() internal {
        // Publish interfaces with ERC-165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x8153916a] = true; // ERC721 + 165 (not needed)

        // The effect of substitution makes storing address(this), address(this)
        // ..., address(this) for a total of TOTAL_SUPPLY times unnecessary at
        // deployment time
        // for (uint256 i = 1; i <= TOTAL_SUPPLY; i++) {
        //     _tokenOwnerWithSubstitutions[i] = address(this);
        // }

        // The effect of substitution makes storing 1, 2, ..., TOTAL_SUPPLY
        // unnecessary at deployment time
        _tokensOfOwnerWithSubstitutions[address(this)].length = TOTAL_SUPPLY;
        // for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
        //     _tokensOfOwnerWithSubstitutions[address(this)][i] = i + 1;
        // }
        // for (uint256 i = 1; i <= TOTAL_SUPPLY; i++) {
        //     _ownedTokensIndexWithSubstitutions[i] = i - 1;
        // }
    }

    /// @dev Actually perform the safeTransferFrom
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data)
        private
        mustBeValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Handle substitutions
        if (owner == address(0)) {
            owner = address(this);
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);

        // Do the callback after everything is done to avoid reentrancy attack
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
        require(retval == ERC721_RECEIVED);
    }
}

/* SuOperation.sol ************************************************************/

/// @title The features that square owners can use
/// @author William Entriken (https://phor.net)
contract SuOperation is SuNFT {
    /// @dev The personalization of a square has changed
    event Personalized(uint256 _nftId);

    /// @dev The main SuSquare struct. The owner may set these properties,
    ///  subject to certain rules. The actual 10x10 image is rendered on our
    ///  website using this data.
    struct SuSquare {
        /// @dev This increments on each update
        uint256 version;

        /// @dev A 10x10 pixel image, stored 8-bit RGB values from left-to-right
        ///  and top-to-bottom order (normal English reading order). So it is
        ///  exactly 300 bytes. Or it is an empty array.
        ///  So the first byte is the red channel for the top-left pixel, then
        ///  the blue, then the green, and then next is the red channel for the
        ///  pixel to the right of the first pixel.
        bytes rgbData;

        /// @dev The title of this square, at most 64 bytes,
        string title;

        /// @dev The URL of this square, at most 100 bytes, or empty string
        string href;
    }

    /// @notice All the Su Squares that ever exist or will exist. Each Su Square
    ///  represents a square on our webpage in a 100x100 grid. The squares are
    ///  arranged in left-to-right, top-to-bottom order. In other words, normal
    ///  English reading order. So suSquares[1] is the top-left location and
    ///  suSquares[100] is the top-right location. And suSquares[101] is
    ///  directly below suSquares[1].
    /// @dev There is no suSquares[0] -- that is an unused array index.
    SuSquare[10001] public suSquares;

    /// @notice Update the contents of your square, the first 3 personalizations
    ///  for a square are free then cost 100 finney (0.01 ether) each
    /// @param _squareId The top-left is 1, to its right is 2, ..., top-right is
    ///  100 and then 101 is below 1... the last one at bottom-right is 10000
    /// @param _squareId A 10x10 image for your square, in 8-bit RGB words
    ///  ordered like the squares are ordered. See Imagemagick&#39;s command
    ///  convert -size 10x10 -depth 8 in.rgb out.png
    /// @param _title A description of your square (max 64 bytes UTF-8)
    /// @param _href A hyperlink for your square (max 96 bytes)
    function personalizeSquare(
        uint256 _squareId,
        bytes _rgbData,
        string _title,
        string _href
    )
        external
        onlyOwnerOf(_squareId)
        payable
    {
        require(bytes(_title).length <= 64);
        require(bytes(_href).length <= 96);
        require(_rgbData.length == 300);
        suSquares[_squareId].version++;
        suSquares[_squareId].rgbData = _rgbData;
        suSquares[_squareId].title = _title;
        suSquares[_squareId].href = _href;
        if (suSquares[_squareId].version > 3) {
            require(msg.value == 10 finney);
        }
        emit Personalized(_squareId);
    }
}

/* SuPromo.sol ****************************************************************/

/// @title A limited pre-sale and promotional giveaway
/// @author William Entriken (https://phor.net)
contract SuPromo is AccessControl, SuNFT {
    uint256 constant PROMO_CREATION_LIMIT = 5000;

    /// @notice How many promo squares were granted
    uint256 public promoCreatedCount;

    /// @notice BEWARE, this does not use a safe transfer mechanism!
    ///  You must manually check the receiver can accept NFTs
    function grantToken(uint256 _tokenId, address _newOwner)
        external
        onlyOperatingOfficer
        mustBeValidToken(_tokenId)
        mustBeOwnedByThisContract(_tokenId)
    {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        promoCreatedCount++;
        _transfer(_tokenId, _newOwner);
    }
}

/* SuVending.sol **************************************************************/

/// @title A token vending machine
/// @author William Entriken (https://phor.net)
contract SuVending is SuNFT {
    uint256 constant SALE_PRICE = 500 finney; // 0.5 ether

    /// @notice The price is always 0.5 ether, and you can buy any available square
    ///  Be sure you are calling this from a regular account (not a smart contract)
    ///  or if you are calling from a smart contract, make sure it can use
    ///  ERC-721 non-fungible tokens
    function purchase(uint256 _nftId)
        external
        payable
        mustBeValidToken(_nftId)
        mustBeOwnedByThisContract(_nftId)
    {
        require(msg.value == SALE_PRICE);
        _transfer(_nftId, msg.sender);
    }
}

/* SuMain.sol *****************************************************************/

/// @title The features that deed owners can use
/// @author William Entriken (https://phor.net)
contract SuMain is AccessControl, SuNFT, SuOperation, SuVending, SuPromo {
    constructor() public {
    }
}