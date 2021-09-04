/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
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
contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}
contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
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
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
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
    function uint2str(uint i) internal pure returns (string memory){
        if (i == 0) return "0";
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
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint j = 0; j < _bb.length; j++) bab[k++] = _bb[j];
        return string(bab);
    }
}

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
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

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
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
    
    
    
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;
    constructor () internal {
        _addMinter(msg.sender);
    }
    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
        //return true;
    }
    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }
    function renounceMinter() public {
        _removeMinter(msg.sender);
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
contract ERC721Mintable is ERC721, MinterRole {
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract hfFactory is ERC721Full, ERC721Mintable, Ownable {
    using SafeMath for uint256;
    mapping (uint256 => mapping (address => uint256)) values;
    
    IERC20 public payToken;
    bool private  isStart = true;
    
    uint256 public tokenIdIdex;
    
    string public _uri;
    
        //rewardToken hft
    IERC20    public rewardToken  = IERC20(0x3c91B301f80cCB055e97d2405523C95e72892D30);
    
    uint256   public rewardsLimit    = 100000;
    uint256   public rewardsUsed;
    uint256   public rewardsPerTrans = 1e18;
    uint256   public starttime;
    
    event minted(address user,uint256 tokenIdIdex , address[] erc20Address , uint256[] erc20Value  ,uint256 rewardsPerTrans);
    //event setPayTokened(address tokenaddr);
    //event tokenURIed(uint256 tokenId ,string infoUrl);

    
    
    constructor (string memory _name, string memory _symbol, string memory uri) public
        ERC721Mintable()
        ERC721Full(_name, _symbol){
            _uri = uri;
            tokenIdIdex = 0;
            starttime   = block.timestamp;
        }
    
    modifier checkStart() {
        require(isStart);
        _;
    }
    /**
    function setPayToken(address tokenaddr) public onlyOwner  returns (bool) 
    {
        payToken = IERC20(tokenaddr);
        isStart  = true;
        
        emit setPayTokened(tokenaddr);
    }
    **/
    
    modifier updateRewardsLimit(){
        //100000 per day
        if((block.timestamp - starttime) > 86400){
            rewardsUsed  = 0;
            starttime    = block.timestamp;
        }
        _;
    }
    
    function setRewardsLimit(uint256 newLimit) onlyOwner public {
        rewardsLimit = newLimit;
    }
    
    function setRewardsPerTrans(uint256 newReward) onlyOwner public {
        rewardsPerTrans = newReward;
    }
    
    
    function transfer(address _to, uint256 _tokenId) public checkStart {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }
    
    function transferAll(address _to, uint256[] memory _tokenId) public checkStart {
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to, _tokenId[i]);
        }
    }
    
    function batchMint(address _to, uint256[] memory _tokenId) public onlyMinter checkStart {
        for (uint i = 0; i < _tokenId.length; i++) {
            _mint(_to, _tokenId[i]);
        }
    }
    
    function batchAddrMint(address[] memory _to, uint256 _tokenId) public onlyMinter checkStart{
        for (uint i = 0; i < _to.length; i++) {
            _mint(_to[i], _tokenId.add(i));
        }
    }
    
    function MintWithValue(address[] memory erc20Address, uint256[] memory erc20Value) public  checkStart updateRewardsLimit{
        
        require(erc20Address.length == erc20Value.length);
        tokenIdIdex += 1;
        _mint(msg.sender, tokenIdIdex);
        for (uint i = 0; i < erc20Address.length; i++){
            IERC20(erc20Address[i]).transferFrom(msg.sender, address(this), erc20Value[i]);
            values[tokenIdIdex][erc20Address[i]] = erc20Value[i];
        }
        //payToken.transferFrom(msg.sender, owner(), amount);
        if(rewardsUsed < rewardsLimit){
            rewardToken.transfer(msg.sender,rewardsPerTrans);
            rewardsUsed += 1;
        }
        
        emit minted( msg.sender,tokenIdIdex , erc20Address ,erc20Value  ,rewardsPerTrans);
    }
    
    function withdraw(uint256 _tokenId, address[] memory erc20Address, uint256[] memory erc20Value) public onlyOwner checkStart{
        withDrawValue(msg.sender,_tokenId,erc20Address,erc20Value);
    }
    
    function withDrawValue(address _to, uint256 _tokenId, address[] memory erc20Address, uint256[] memory erc20Value) public checkStart {
        
        require(ownerOf(_tokenId) == msg.sender);
        require(erc20Address.length == erc20Value.length);
        
        for (uint i = 0; i < erc20Address.length; i++){
            if (values[_tokenId][erc20Address[i]] > 0){
                values[_tokenId][erc20Address[i]] = 0;
                IERC20(erc20Address[i]).transfer(_to, erc20Value[i]);
                //values[_tokenId][erc20Address[i]] = 0;
            }
        }
    }
    
    function setUri(string memory uri) public onlyMinter {
        _uri = uri;
    }
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        
        require(_exists(tokenId));
        string memory infoUrl;
        infoUrl = strConcat(_uri, uint2str(tokenId));
        
        //emit tokenURIed(tokenId,infoUrl);

        return infoUrl;
        
        //emit tokenURIed(tokenId,infoUrl);
    }
    
}