/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.5.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



pragma solidity ^0.5.0;



contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}



pragma solidity ^0.5.0;


contract IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


pragma solidity ^0.5.0;


library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      
        require(b > 0);
        uint256 c = a / b;
       

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



pragma solidity ^0.5.0;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
       
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}



pragma solidity ^0.5.0;



contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}



pragma solidity ^0.5.0;




contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    
    mapping (uint256 => address) private _tokenOwner;

  
    mapping (uint256 => address) private _tokenApprovals;

   
    mapping (address => uint256) private _ownedTokensCount;

   
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    

    constructor () public {
        
        _registerInterface(_INTERFACE_ID_ERC721);
    }

  
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

   
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

  
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        emit Transfer(address(0), to, tokenId);
    }

    
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _ownedTokensCount[owner] = _ownedTokensCount[owner].sub(1);
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

   
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

   
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}



pragma solidity ^0.5.0;



contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}



pragma solidity ^0.5.0;







contract ERC721EnumerableSimple is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256 internal totalSupply_;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
   
    constructor () public {
        
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "Index is higher than number of tokens owned.");
        return _ownedTokens[owner][index];
    }

    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }


   
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "Index is out of bounds.");
        return index;
    }


    
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        totalSupply_ = totalSupply_.add(1);
    }

    
    function _burn(address /*owner*/, uint256 /*tokenId*/) internal {
        revert("This token cannot be burned.");
    }

    
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
       

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

       
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        
        _ownedTokens[from].length--;

        
    }
}



pragma solidity ^0.5.0;



contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



pragma solidity ^0.5.0;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *     bytes4(keccak256('name()')) ^
     *     bytes4(keccak256('symbol()')) ^
     *     bytes4(keccak256('tokenURI(uint256)'))
     */

   
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

   
    function name() external view returns (string memory) {
        return _name;
    }

    
    function symbol() external view returns (string memory) {
        return _symbol;
    }

   
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

    
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}



pragma solidity ^0.5.0;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.0;



contract Carnitina is ERC721, ERC721EnumerableSimple, ERC721Metadata("Carnitina 1", "CA1") {

    string public uribase;

    address public createControl;

    address public tokenAssignmentControl;

    bool public mintingFinished = false;

    constructor(address _createControl, address _tokenAssignmentControl)
    public
    {
        createControl = _createControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        uribase = "https://soccerindustry.org/CS1/meta/";
    }

    modifier onlyCreateControl()
    {
        require(msg.sender == createControl, "createControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier requireMinting() {
        require(mintingFinished == false, "This call only works when minting is not finished.");
        _;
    }

    
    function create(uint256 _tokenId, address _owner)
    public
    onlyCreateControl
    requireMinting
    {
        
        require(_tokenId == 0 || _exists(_tokenId.sub(1)), "Previous token ID has to exist.");
        
        _mint(_owner, _tokenId);
    }

    
    function createMulti(uint256 _tokenIdStart, address[] memory _owners)
    public
    onlyCreateControl
    requireMinting
    {
        
        require(_tokenIdStart == 0 || _exists(_tokenIdStart.sub(1)), "Previous token ID has to exist.");
        uint256 addrcount = _owners.length;
        for (uint256 i = 0; i < addrcount; i++) {
            
            _mint(_owners[i], _tokenIdStart + i);
        }
    }

    
    function finishMinting()
    public
    onlyCreateControl
    {
        mintingFinished = true;
    }

    
    function newUriBase(string memory _newUriBase)
    public
    onlyCreateControl
    {
        uribase = _newUriBase;
    }

    
    function tokenURI(uint256 _tokenId)
    external view
    returns (string memory)
    {
        require(_exists(_tokenId), "Token ID does not exist.");
        return string(abi.encodePacked(uribase, uint2str(_tokenId)));
    }

    
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    
    function uint2str(uint256 inp)
    internal pure
    returns (string memory)
    {
        if (inp == 0) return "0";
        uint i = inp;
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    
    function()
    external payable
    {
        revert("The contract cannot receive ETH payments.");
    }
}