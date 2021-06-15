/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash =
      0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      isAdmin(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

abstract contract MinterRole is Context, AdminRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor() {
    _addMinter(_msgSender());
  }

  modifier onlyMinter() {
    require(
      isMinter(_msgSender()),
      'MinterRole: caller does not have the Minter role'
    );
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyAdmin {
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

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract IERC721 is IERC165 {
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

  function balanceOf(address owner)
    public
    view
    virtual
    returns (uint256 balance);

  function ownerOf(uint256 tokenId) public view virtual returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function approve(address to, uint256 tokenId) public virtual;

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public virtual;

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual;
}

abstract contract IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) public virtual returns (bytes4);
}

abstract contract ERC165 is IERC165 {
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  function supportsInterface(bytes4 interfaceId)
    external
    view
    override
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    _supportedInterfaces[interfaceId] = true;
  }
}

contract ERC721 is Context, ERC165, IERC721 {
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  Counters.Counter private _totalSupply;
  mapping(uint256 => address) private _tokenOwner;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => uint256[]) private _ownedTokenList;
  mapping(uint256 => uint256) private _tokenIdToOwnedTokenListIndex;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply.current();
  }

  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), 'ERC721: balance query for the zero address');

    return _ownedTokenList[owner].length;
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0), 'ERC721: owner query for nonexistent token');

    return owner;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256 tokenId)
  {
    require(index < _ownedTokenList[owner].length, 'ERC721: past end of index');
    return _ownedTokenList[owner][index];
  }

  function tokenListOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    return _ownedTokenList[owner];
  }

  function approve(address to, uint256 tokenId) public override {
    address owner = ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'ERC721: approve caller is not owner nor approved for all'
    );

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address to, bool approved) public override {
    require(to != _msgSender(), 'ERC721: approve to caller');

    _operatorApprovals[_msgSender()][to] = approved;
    emit ApprovalForAll(_msgSender(), to, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );

    _transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );
    _safeTransferFrom(from, to, tokenId, _data);
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal {
    _transferFrom(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    returns (bool)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
    address owner = ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, '');
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _tokenOwner[tokenId] = to;
    _addToOwnerList(to, tokenId);
    _totalSupply.increment();

    emit Transfer(address(0), to, tokenId);
  }

  function _addToOwnerList(address owner, uint256 tokenId) internal {
    _tokenIdToOwnedTokenListIndex[tokenId] = _ownedTokenList[owner].length;
    _ownedTokenList[owner].push(tokenId);
  }

  function _removeFromOwnerList(address owner, uint256 tokenId) internal {
    uint256 index = _tokenIdToOwnedTokenListIndex[tokenId];
    uint256 endIndex = _ownedTokenList[owner].length - 1;
    if (index < endIndex) {
      uint256 endTokenId = _ownedTokenList[owner][endIndex];
      _ownedTokenList[owner][index] = endTokenId;
      _tokenIdToOwnedTokenListIndex[endTokenId] = index;
    }
    _ownedTokenList[owner].pop();
  }

  function _burn(uint256 tokenId) internal {
    address owner = _tokenOwner[tokenId];
    _clearApproval(tokenId);
    _totalSupply.decrement();
    _removeFromOwnerList(owner, tokenId);
    delete _tokenIdToOwnedTokenListIndex[tokenId];
    delete _tokenOwner[tokenId];
    emit Transfer(owner, address(0), tokenId);
  }

  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(
      ownerOf(tokenId) == from,
      'ERC721: transfer of token that is not own'
    );
    require(to != address(0), 'ERC721: transfer to the zero address');

    _clearApproval(tokenId);

    _removeFromOwnerList(from, tokenId);
    _tokenOwner[tokenId] = to;
    _addToOwnerList(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (!to.isContract()) {
      return true;
    }

    bytes4 retval =
      IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

abstract contract IERC721Metadata is IERC721 {
  function name() external view virtual returns (string memory);

  function symbol() external view virtual returns (string memory);

  function tokenURI(uint256 tokenId)
    external
    view
    virtual
    returns (string memory);
}

abstract contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
  string private _name;
  string private _symbol;
  string private _baseURI;
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  constructor(string memory argName, string memory argSymbol) {
    _name = argName;
    _symbol = argSymbol;

    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    virtual
    override
    returns (string memory)
  {
    return _getTokenURI(tokenId);
  }

  function _getTokenURI(uint256 tokenId) internal view returns (string memory) {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    string memory _tokenURI = _tokenURIs[tokenId];

    if (bytes(_tokenURI).length == 0) {
      return '';
    } else {
      return string(abi.encodePacked(_baseURI, _tokenURI));
    }
  }

  function baseURI() external view returns (string memory) {
    return _baseURI;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    require(_exists(tokenId), 'ERC721Metadata: URI set of nonexistent token');
    _tokenURIs[tokenId] = _tokenURI;
  }

  function _setBaseURI(string memory newBaseURI) internal {
    _baseURI = newBaseURI;
  }
}

contract ERC721MetadataMintable is ERC721, ERC721Metadata, MinterRole {
  mapping(uint256 => uint256) private _tokenTokenMap;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI
  ) ERC721Metadata(name, symbol) {
    _setBaseURI(baseURI);
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string memory _tokenURI
  ) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    _setTokenURI(tokenId, _tokenURI);
    return true;
  }

  function mintMultipleWithTokenURI(
    address to,
    uint256 startTokenId,
    uint256 count,
    string memory _tokenURI
  ) public onlyMinter returns (bool) {
    _mint(to, startTokenId);
    _setTokenURI(startTokenId, _tokenURI);

    for (uint256 i = 1; i < count; i++) {
      uint256 tokenId = startTokenId + i;
      _mint(to, tokenId);
      _tokenTokenMap[tokenId] = startTokenId;
    }
    return true;
  }

  function burn(uint256 tokenId) public returns (bool) {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: burn caller is not owner nor approved'
    );
    _burn(tokenId);
    return true;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    uint256 _baseTokenId = _tokenTokenMap[tokenId];
    if (_baseTokenId == 0) {
      return _getTokenURI(tokenId);
    } else {
      return _getTokenURI(_baseTokenId);
    }
  }
}

contract HarbourNFTv3 is ERC721MetadataMintable {
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;
  bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
  bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;

  string private _contractURI;
  address payable private _royaltyReceiver;
  uint256 private _royaltyAmount;
  uint256 private _feeBps;
  uint96 private _royaltyValue;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    string memory argContractURI,
    address payable royaltyReceiver,
    uint256 royaltyAmount,
    uint256 feeBps,
    uint96 royaltyValue
  ) ERC721MetadataMintable(name, symbol, baseURI) {
    _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    _registerInterface(_INTERFACE_ID_ERC2981);
    _registerInterface(_INTERFACE_ID_FEES);
    _registerInterface(_INTERFACE_ID_ROYALTIES);

    _contractURI = argContractURI;
    _royaltyReceiver = royaltyReceiver;
    _royaltyAmount = royaltyAmount;
    _feeBps = feeBps;
    _royaltyValue = royaltyValue;
  }

  function setContractURI(string memory uri) public onlyAdmin {
    _contractURI = uri;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setRoyaltyReceiver(address payable _addr) public onlyAdmin {
    _royaltyReceiver = _addr;
  }

  function setRoyaltyAmount(uint256 _amount) public onlyAdmin {
    _royaltyAmount = _amount;
  }

  function setFeeBps(uint256 _amount) public onlyAdmin {
    _feeBps = _amount;
  }

  function setRoyaltyValue(uint96 _amount) public onlyAdmin {
    _royaltyValue = _amount;
  }

  function royaltyInfo(
    uint256,
    uint256 _value,
    bytes calldata
  )
    public
    view
    returns (
      address receiver,
      uint256 amount,
      bytes memory royaltyPaymentData
    )
  {
    return (_royaltyReceiver, (_value * _royaltyAmount) / 10000, '');
  }

  function getFeeRecipients(uint256)
    public
    view
    returns (address payable[] memory)
  {
    address payable[] memory result = new address payable[](1);
    result[0] = _royaltyReceiver;
    return result;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = _feeBps;
    return result;
  }

  struct Part {
    address payable account;
    uint96 value;
  }

  function getRoyalties(uint256) public view returns (Part[] memory) {
    Part[] memory result = new Part[](1);
    result[0].account = _royaltyReceiver;
    result[0].value = _royaltyValue;
    return result;
  }
}