//SourceUnit: TRC721Token.sol

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}



library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}


contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

interface ITRC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ITRC721 is ITRC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);


    function ownerOf(uint256 tokenId) public view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


contract ITRC721Metadata is ITRC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract ITRC721Receiver {

    function onTRC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


contract TRC165 is ITRC165 {

    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_TRC165);
    }
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "TRC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract TRC721 is Context, TRC165, ITRC721,MinterRole {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    event Mint(address indexed to, uint256 indexed tokenId);
    bytes4 private constant _TRC721_RECEIVED = 0x5175f878;

    mapping (uint256 => address) private _tokenOwner;

    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => Counters.Counter) private _ownedTokensCount;

    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
     mapping (uint256 => AuthorDetail) public authorDetails;
    Counters.Counter  _tokenIdTracker;
    struct AuthorDetail {
        string author;
        string name;
        string pictureURL;
        string description;
        
    }
    bool public activeTran = true;

    modifier isActive(){
        require(activeTran,"Unopened transfer");
        _;
    }

    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_TRC721);
    }

    function openTran() external onlyMinter{
        activeTran = true;
    }
     function closeTran() external onlyMinter{
        activeTran = false;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "TRC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }


    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "TRC721: owner query for nonexistent token");

        return owner;
    }


    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "TRC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "TRC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }


    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "TRC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }


    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "TRC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

 
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }


    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnTRC721Received(from, to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

  
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "TRC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }


    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnTRC721Received(address(0), to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }


    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "TRC721: mint to the zero address");
        require(!_exists(tokenId), "TRC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        emit Mint(to,tokenId);
        emit Transfer(address(0), to, tokenId);
    }


    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "TRC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }


    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }


    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "TRC721: transfer of token that is not own");
        require(to != address(0), "TRC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }


    function _checkOnTRC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            ITRC721Receiver(to).onTRC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("TRC721: transfer to non TRC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _TRC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
    function transfer(address to, uint256 tokenId) public isActive {
         _transfer(_msgSender(), to, tokenId);
     }
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "TRC721: transfer of token that is not own");
        require(to != address(0), "TRC721: transfer to the zero address");
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
}


contract TRC721Metadata is Context, TRC165, TRC721, ITRC721Metadata {
    string private _name;

    string private _symbol;

    string private _baseURI;


    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;
    

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;


        _registerInterface(_INTERFACE_ID_TRC721_METADATA);
    }


    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "TRC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "TRC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function setsetBaseURI(string memory baseURI) public onlyMinter{
        _setBaseURI(baseURI);
    }

    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }


    function baseURI() external view returns (string memory) {
        return _baseURI;
    }


    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ITRC721Enumerable is ITRC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}


contract TRC721Enumerable is Context, TRC165, TRC721, ITRC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        _registerInterface(_INTERFACE_ID_TRC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "TRC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }


    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "TRC721Enumerable: global index out of bounds");
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

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        _ownedTokens[from].length--;
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

contract TRC721Token is  TRC721Metadata ,TRC721Enumerable{
    constructor() public TRC721Metadata("Non-fungible Token blueark", "BRK-NFT") {
    }
      function mint(address to,string memory names,string memory descriptions,string  memory pictureURLs,string  memory authors,string memory tokenURIs) public  onlyMinter returns (bool) {
        uint tokenId = _tokenIdTracker.current();
        super._safeMint(to, tokenId);
        authorDetails[tokenId] = AuthorDetail(authors,names,pictureURLs,descriptions);
        _setTokenURI(tokenId, tokenURIs);
        _tokenIdTracker.increment();
        return true;
    }
    function mint(address [] memory tos,string  [] memory names,string [] memory descriptions,string [] memory pictureURLs,string [] memory authors,string [] memory tokenURIs) public  onlyMinter returns(bool){
        uint256 length =  tos.length;
        require(length==pictureURLs.length&&length==authors.length);
        for(uint256 i = 0;i<length;i++){
        uint tokenId = _tokenIdTracker.current();
        super._safeMint(tos[i], tokenId);
        authorDetails[tokenId] = AuthorDetail(authors[i],names[i],pictureURLs[i],descriptions[i]);
         _setTokenURI(tokenId, tokenURIs[i]);
         _tokenIdTracker.increment();
        }
        return true;
    }
}