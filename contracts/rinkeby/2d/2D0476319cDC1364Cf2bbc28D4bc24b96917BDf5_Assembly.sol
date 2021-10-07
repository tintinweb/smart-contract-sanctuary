/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.2;
pragma abicoder v2;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract  IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) public virtual view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    function approve(address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public virtual view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public virtual;
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
}
abstract contract IERC721Enumerable is IERC721 {
    function totalSupply() public virtual view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public virtual view returns (uint256);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}
abstract contract IERC721Metadata is IERC721 {
    function name() external virtual view returns (string memory);
    function symbol() external virtual view returns (string memory);
    function tokenURI(uint256 tokenId) external virtual view returns (string memory);
}
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor ()  {
        _registerInterface(_INTERFACE_ID_ERC165);
    }
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() public {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract ERC721 is ERC165, IERC721 , Ownable  {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _ownedTokensCount[owner].current();
    }
    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public override {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferFrom(from, to, tokenId);
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
    function _mint(address to, uint256 tokenId) internal virtual{
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        emit Transfer(address(0), to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal virtual{
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");
        _clearApproval(tokenId);
        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);
        emit Transfer(owner, address(0), tokenId);
    }
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal virtual{
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
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    using SafeMath for *;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] internal _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor () {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function allTokens(address owner) public view returns(uint256[] memory){
        return _ownedTokens[owner];
    }
    function totalSupply() public override view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public override view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal virtual override {
        super._transferFrom(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal virtual override {
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
        delete _ownedTokens[from][lastTokenIndex];
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokens[lastTokenIndex];
        _allTokensIndex[tokenId] = 0;
    }
}
contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }
    function name() external override view returns (string memory) {
        return _name;
    }
    function symbol() external override view returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }
}

abstract contract MarketPlace is ERC721Enumerable , ReentrancyGuard ,ERC721Metadata {
    uint256 public startTime;
    uint256 public endTime;
    struct TokenSale {
        uint256 price;
        bool sale;
    }
    address payable assemblyWallet;
    constructor(address payable _assembyWallet){
        assemblyWallet = _assembyWallet;
    }
    mapping (uint256 => TokenSale) private _tokenMeta;
    function getAllOnSale () public view returns( TokenSale[] memory ) {
        TokenSale[] memory tokensOnSale = new TokenSale[](_allTokens.length);
        uint256 counter = 0;

        for(uint i = 1; i < _allTokens.length + 1; i++) {
            if(_tokenMeta[i].sale == true) {
                tokensOnSale[counter] = _tokenMeta[i];
                counter++;
            }
        }
        return tokensOnSale;
    }
     function setTokenPrice(uint256 _tokenId, uint256 _price) public {
        require(_exists(_tokenId), "ERC721Metadata: Price set of nonexistent token");
        require(ownerOf(_tokenId) == msg.sender);
        _tokenMeta[_tokenId].price = _price;
    }
    function setTokenSale(uint256 _tokenId, bool _sale, uint256 _price) public {
        require(_exists(_tokenId), "ERC721Metadata: Sale set of nonexistent token");
        require(_price > 0);
        require(ownerOf(_tokenId) == msg.sender);

        _tokenMeta[_tokenId].sale = _sale;
        setTokenPrice(_tokenId, _price);
    }
    function tokenPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: Price query for nonexistent token");
        return _tokenMeta[tokenId].price;
    }
    function purchaseToken(uint256 _tokenId) public payable nonReentrant {
        require(msg.sender != address(0) && msg.sender != ownerOf(_tokenId));
        require(msg.value >= _tokenMeta[_tokenId].price);
        address tokenSeller = ownerOf(_tokenId);
        setApprovalForAll(tokenSeller, true);
        _transferFrom(tokenSeller, msg.sender, _tokenId);
        _tokenMeta[_tokenId].sale = false;
        processRoyalties(_tokenId);
    }
    function setConsignmentPeriod(uint256 _startTime, uint256 _endTime) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }
    function processRoyalties(uint256 _tokenId) internal {
        if(isPrimarySale(_tokenId)){
            require(assemblyWallet.send(_tokenMeta[_tokenId].price));
        }
        if(!isPrimarySale(_tokenId)){
            uint256 royalityFortyPrecentToAssembly;
            uint256 royalitySixtyPrecentToArtist;
            if(isConsignmentOn()){
            royalityFortyPrecentToAssembly = (_tokenMeta[_tokenId].price * 40 ) / 100;
            royalitySixtyPrecentToArtist = (_tokenMeta[_tokenId].price * 60 ) / 100;
            require(assemblyWallet.send(royalityFortyPrecentToAssembly));
            require(payable(ownerOf(_tokenId)).send(royalitySixtyPrecentToArtist));
            }
            if(!isConsignmentOn()){
            require(payable(ownerOf(_tokenId)).send(_tokenMeta[_tokenId].price));
            }
        }
    }
    function isConsignmentOn() internal view returns(bool){
        return block.timestamp > startTime && block.timestamp < endTime;
    }
    function isPrimarySale(uint256 _tokenId) internal view returns(bool){
        return ownerOf(_tokenId) == owner();
    }
    function _setTokensSale(uint256 _tokenId, TokenSale memory _meta) internal {
        require(_exists(_tokenId));
        require(ownerOf(_tokenId) == msg.sender);
        _tokenMeta[_tokenId] = _meta;
    }
    function _burn(address owner,uint256 tokenId) internal virtual override(ERC721,ERC721Enumerable) {
        ERC721Enumerable._burn(owner, tokenId);
    }
    function _mint(address owner,uint256 tokenId) internal virtual override(ERC721,ERC721Enumerable) {
        ERC721Enumerable._mint(owner, tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal virtual override(ERC721,ERC721Enumerable) {
        ERC721Enumerable._transferFrom(from, to,tokenId);
    }
}
contract Assembly is MarketPlace  {
    constructor (string memory name, string memory symbol,address payable assemblyWallet)  ERC721Metadata(name, symbol) MarketPlace(assemblyWallet){
    }
    function mint(uint256 _id,string memory _uri) public {
        require(!_exists(_id), "Already exist");
        _mint(msg.sender, _id);
        _setTokenURI(_id,_uri);
        TokenSale memory meta = TokenSale(0,false);
        _setTokensSale(_id, meta);
    }
    function setTokenURI(uint256 tokenId, string calldata uri) external {
        _setTokenURI(tokenId,uri);
    }
}