/**
 *Submitted for verification at Etherscan.io on 2021-09-30
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

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _admins.add(_msgSender());
    emit AdminAdded(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      _admins.has(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function addAdmin(address account) public onlyAdmin {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function renounceAdmin() public onlyAdmin {
    _admins.remove(_msgSender());
    emit AdminRemoved(_msgSender());
  }
}

abstract contract CreatorWithdraw is Context, AdminRole {
  address payable private _creator;

  constructor() {
    _creator = payable(_msgSender());
  }

  function withdraw(address erc20, uint256 amount) public onlyAdmin {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else {
      IERC20(erc20).transfer(_creator, amount);
    }
  }
}

abstract contract MinterRole is Context {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor() {
    _minters.add(_msgSender());
    emit MinterAdded(_msgSender());
  }

  modifier onlyMinter() {
    require(
      _minters.has(_msgSender()),
      'MinterRole: caller does not have the Minter role'
    );
    _;
  }

  function addMinter(address account) public onlyMinter {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public onlyMinter {
    _minters.remove(_msgSender());
    emit MinterRemoved(_msgSender());
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

abstract contract ERC721NonTransferable is Context, ERC165, IERC721 {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC1238 = 0xbef97c87;

  mapping(uint256 => address) private _tokenOwner;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => Counters.Counter) private _ownedTokensCount;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC1238);
  }

  function transfersEnabled() external pure returns (bool) {
    return false;
  }

  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), 'ERC721: balance query for the zero address');

    return _ownedTokensCount[owner].current();
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0), 'ERC721: owner query for nonexistent token');

    return owner;
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
    address,
    address,
    uint256
  ) public pure override {
    revert('ERC721: Non-transferable');
  }

  function safeTransferFrom(
    address,
    address,
    uint256
  ) public pure override {
    revert('ERC721: Non-transferable');
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public pure override {
    revert('ERC721: Non-transferable');
  }

  function burn(uint256 tokenId) public returns (bool) {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: burn caller is not owner nor approved'
    );
    _burn(tokenId);
    return true;
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

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to].increment();

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) private {
    address owner = _tokenOwner[tokenId];
    _clearApproval(tokenId);
    _ownedTokensCount[owner].decrement();
    _tokenOwner[tokenId] = address(0);
    emit Transfer(owner, address(0), tokenId);
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

abstract contract ERC721Metadata is
  ERC165,
  ERC721NonTransferable,
  IERC721Metadata
{
  string private _name;
  string private _symbol;
  string private _baseURI;
  string private _contractURI;
  mapping(uint256 => uint256) private _tokenTypes;
  mapping(uint256 => string) private _tokenTypeURIs;

  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

  constructor(
    string memory newName,
    string memory newSymbol,
    string memory newContractURI
  ) {
    _name = newName;
    _symbol = newSymbol;
    _contractURI = newContractURI;
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_CONTRACT_URI);
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );
    string memory _tokenURI = _tokenTypeURIs[_tokenTypes[tokenId]];
    if (bytes(_tokenURI).length == 0) {
      return '';
    } else {
      return string(abi.encodePacked(_baseURI, _tokenURI));
    }
  }

  function baseURI() external view returns (string memory) {
    return _baseURI;
  }

  function tokenType(uint256 tokenId) external view returns (uint256) {
    return _tokenTypes[tokenId];
  }

  function _setTokenURIForType(uint256 newType, string memory newURI) internal {
    _tokenTypeURIs[newType] = newURI;
  }

  function _setTokenType(uint256 tokenId, uint256 newType) internal {
    require(_exists(tokenId), 'ERC721Metadata: URI set of nonexistent token');
    _tokenTypes[tokenId] = newType;
  }

  function _setBaseURI(string memory newBaseURI) internal {
    _baseURI = newBaseURI;
  }

  function _typeExists(uint256 checkType) internal view returns (bool) {
    return bytes(_tokenTypeURIs[checkType]).length > 0;
  }
}

contract HarbourBadge is ERC721Metadata, MinterRole, CreatorWithdraw {
  constructor(
    string memory name,
    string memory symbol,
    string memory newContractURI,
    string memory baseURI
  ) ERC721Metadata(name, symbol, newContractURI) {
    _setBaseURI(baseURI);
  }

  function mintTokenType(uint256 tokenType, string memory tokenURI)
    public
    onlyMinter
    returns (bool)
  {
    require(!_typeExists(tokenType), 'HarbourBadge: Type already exist');
    _setTokenURIForType(tokenType, tokenURI);
    return true;
  }

  function mintWithTokenType(
    address to,
    uint256 tokenId,
    uint256 tokenType
  ) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    _setTokenType(tokenId, tokenType);
    return true;
  }
}