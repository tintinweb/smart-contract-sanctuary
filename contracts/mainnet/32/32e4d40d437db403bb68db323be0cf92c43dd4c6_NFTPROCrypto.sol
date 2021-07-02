/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

/*

███╗░░██╗███████╗████████╗
████╗░██║██╔════╝╚══██╔══╝
██╔██╗██║█████╗░░░░░██║░░░
██║╚████║██╔══╝░░░░░██║░░░
██║░╚███║██║░░░░░░░░██║░░░
╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░

██████╗░██████╗░░█████╗░  
██╔══██╗██╔══██╗██╔══██╗  
██████╔╝██████╔╝██║░░██║  
██╔═══╝░██╔══██╗██║░░██║  
██║░░░░░██║░░██║╚█████╔╝  
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░  

░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░

https://nftprocrypto.com

𝑇ℎ𝑖𝑠 𝑖𝑠 𝑡ℎ𝑒 𝑟𝑒𝑎𝑙 𝑎𝑟𝑡 𝑓𝑟𝑜𝑚 𝑝𝑟𝑜𝑓𝑒𝑠𝑠𝑖𝑜𝑛𝑎𝑙𝑠 | 𝑁𝐹𝑇 + 𝑅𝐸𝐴𝐿 𝐴𝑅𝑇 = 𝑁𝐹𝑇 𝑃𝑅𝑂 𝐶𝑅𝑌𝑃𝑇𝑂

*/


pragma solidity ^0.5.0;


contract Context {
   
    constructor () internal { }
 
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}


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

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


pragma solidity ^0.5.0;


contract IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;


library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.5.5;


library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }


    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


pragma solidity ^0.5.0;



library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; 
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
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
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


pragma solidity ^0.5.0;


contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;


    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;


    mapping (uint256 => address) private _tokenOwner;


    mapping (uint256 => address) private _tokenApprovals;

 
    mapping (address => Counters.Counter) private _ownedTokensCount;


    mapping (address => mapping (address => bool)) private _operatorApprovals;


    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {

        _registerInterface(_INTERFACE_ID_ERC721);
    }


    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }


    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }


    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }


    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }


    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(address from, address to, uint256 tokenId) public {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }


    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

 
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
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


contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {

        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

  
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
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

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];


        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 


        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}


pragma solidity ^0.5.2;

contract ENSRegistryOwnerI {
    function owner(bytes32 node) public view returns (address);
}

contract ENSReverseRegistrarI {
    function setName(string memory name) public returns (bytes32 node);
}


pragma solidity ^0.5.0;



contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.5.0;





contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {

    string private _name;


    string private _symbol;

  
    mapping(uint256 => string) private _tokenURIs;


    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;


        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }


    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
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

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.0;

contract NFTPROCrypto is ERC721, ERC721Enumerable, ERC721Metadata("NFT PRO CRYPTO", "NFTPRO") {

    string public uribase;

    address public createControl;

    address public tokenAssignmentControl;
	
	bool public mintingFinished = false;

    uint256 constant finalSupply= 5000;


    constructor(address _createControl, address _tokenAssignmentControl)
    public
    {
        createControl = _createControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        uribase = "https://nftprocrypto.com/nft/procrypto/meta/";
 
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


	
    function totalSupply()
    public view
    returns (uint256) {
        return finalSupply;
    }

  
    function mintedSupply()
    public view
    returns (uint256) {
        return super.totalSupply();
    }


    function create(uint256 _tokenId, address _owner)
    public
    onlyCreateControl
	requireMinting
    {
       
        require(_tokenId == 0 || _exists(_tokenId.sub(1)), "Previous token ID has to exist.");
       
        _mint(_owner, _tokenId);
    }



    function createMulti(uint256 _tokenIdStart, address _owner, uint256 count)
    public
    onlyCreateControl
    requireMinting
    {
        
        require(_tokenIdStart == 0 || _exists(_tokenIdStart.sub(1)), "Previous token ID has to exist.");
        for (uint256 i = 0; i < count; i++) {
       
            _mint(_owner, _tokenIdStart + i);
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
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }


    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
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

/*


Learn more about NFT PRO CRYPTO 

NFT PRO CRYPTO©
Website:https://nftprocrypto.com

Social Media:
https://www.facebook.com/nftprocrypto
https://twitter.com/nftprocrypto





𝙰𝚞𝚝𝚑𝚘𝚛𝚒𝚣𝚎𝚍 𝚜𝚎𝚕𝚕𝚎𝚛 𝚏𝚘𝚛 𝚝𝚑𝚎 𝚜𝚊𝚕𝚎 𝚘𝚏 𝙽𝙵𝚃


░█████╗░██╗░░░░░██╗░░░░░███╗░░░███╗███████╗██████╗░░██████╗░██████╗░░█████╗░██╗░░░██╗██████╗░
██╔══██╗██║░░░░░██║░░░░░████╗░████║██╔════╝██╔══██╗██╔════╝░██╔══██╗██╔══██╗██║░░░██║██╔══██╗
███████║██║░░░░░██║░░░░░██╔████╔██║█████╗░░██║░░██║██║░░██╗░██████╔╝██║░░██║██║░░░██║██████╔╝
██╔══██║██║░░░░░██║░░░░░██║╚██╔╝██║██╔══╝░░██║░░██║██║░░╚██╗██╔══██╗██║░░██║██║░░░██║██╔═══╝░
██║░░██║███████╗███████╗██║░╚═╝░██║███████╗██████╔╝╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝██║░░░░░
╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚═╝░░░░░

░█████╗░░█████╗░██████╗░██████╗░░█████╗░██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██║░░╚═╝██║░░██║██████╔╝██████╔╝██║░░██║██████╔╝███████║░░░██║░░░██║██║░░██║██╔██╗██║
██║░░██╗██║░░██║██╔══██╗██╔═══╝░██║░░██║██╔══██╗██╔══██║░░░██║░░░██║██║░░██║██║╚████║
╚█████╔╝╚█████╔╝██║░░██║██║░░░░░╚█████╔╝██║░░██║██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║
░╚════╝░░╚════╝░╚═╝░░╚═╝╚═╝░░░░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝


𝐀𝐋𝐋𝐌𝐄𝐃 𝐆𝐑𝐎𝐔𝐏 𝐂𝐎𝐑𝐏𝐎𝐑𝐀𝐓𝐈𝐎𝐍

𝔘𝔫𝔦𝔱𝔢𝔡 𝔖𝔱𝔞𝔱𝔢𝔰 𝔬𝔣 𝔄𝔪𝔢𝔯𝔦𝔠𝔞 (𝚄𝚂𝙰)
𝙵𝚕𝚘𝚛𝚒𝚍𝚊 𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 𝚠𝚠𝚠.𝚍𝚘𝚜.𝚜𝚝𝚊𝚎.𝚏𝚕.𝚞𝚜 𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 ℙ𝟙𝟛𝟘𝟘𝟘𝟘𝟟𝟜𝟜𝟙𝟟𝟿 | 𝙵𝚎𝚍𝚎𝚛𝚊𝚕 𝚃𝚊𝚡 𝙸𝚍𝚎𝚗𝚝𝚒𝚏𝚒𝚌𝚊𝚝𝚒𝚘𝚗 𝙽𝚞𝚖𝚋𝚎𝚛 (𝙴𝙸𝙽) 𝟛𝟘-𝟘𝟟𝟡𝟞𝟞𝟜𝟘
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------
-----------------------------------------------
---------------------------------
----------------------
Website:
 https://allmedgroup.org/
 
[email protected]

Social Media: 
https://www.facebook.com/allmedgroup/
https://twitter.com/allmedgroup
https://www.instagram.com/allmedgroup/


Aʟʟ Rɪɢʜᴛs Rᴇsᴇʀᴠᴇᴅ. AʟʟᴍᴇᴅGʀᴏᴜᴘ Cᴏʀᴘᴏʀᴀᴛɪᴏɴ

*/