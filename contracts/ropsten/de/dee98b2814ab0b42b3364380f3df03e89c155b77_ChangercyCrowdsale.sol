pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a / _b;
    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

interface ERC721Enumerable {

  function totalSupply() external view returns (uint256);
  function tokenByIndex(uint256 _index) external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC721 {

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function approve(address _approved, uint256 _tokenId) external;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721TokenReceiver {

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);    
}

library AddressUtils {

  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_addr) } // solium-disable-line security/no-inline-assembly
    return size > 0;
  }
}

interface ERC165 {

  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract SupportsInterface is ERC165 {

  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor() public {
    supportedInterfaces[0x01ffc9a7] = true;
  }

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return supportedInterfaces[_interfaceID];
  }
}

contract NFToken is ERC721, SupportsInterface {
  using SafeMath for uint256;
  using AddressUtils for address;

  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApprovals;
  mapping (address => uint256) internal ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;
  bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
  event Transfer(address indexed _from,address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  modifier canOperate(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

  modifier canTransfer(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || getApproved(_tokenId) == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }

  modifier validNFToken(uint256 _tokenId) {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

  constructor() public {
    supportedInterfaces[0x80ac58cd] = true;
  }

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToNFTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view returns (address _owner) {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));
    _transfer(_to, _tokenId);
  }

  function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);
    idToApprovals[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    require(_operator != address(0));
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(uint256 _tokenId) public view validNFToken(_tokenId) returns (address) {
    return idToApprovals[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    require(_owner != address(0));
    require(_operator != address(0));
    return ownerToOperators[_owner][_operator];
  }

  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) internal canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));
    _transfer(_to, _tokenId);
    if (_to.isContract()) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

  function _transfer(address _to, uint256 _tokenId) private {
    address from = idToOwner[_tokenId];
    clearApproval(_tokenId);
    removeNFToken(from, _tokenId);
    addNFToken(_to, _tokenId);
    emit Transfer(from, _to, _tokenId);
  }
   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_tokenId != 0);
    require(idToOwner[_tokenId] == address(0));
    addNFToken(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(address _owner, uint256 _tokenId) validNFToken(_tokenId) internal {
    clearApproval(_tokenId);
    removeNFToken(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  function clearApproval(uint256 _tokenId) private {
    if(idToApprovals[_tokenId] != 0)
    {
      delete idToApprovals[_tokenId];
    }
  }

  function removeNFToken(address _from, uint256 _tokenId) internal {
    require(idToOwner[_tokenId] == _from);
    assert(ownerToNFTokenCount[_from] > 0);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from].sub(1);
    delete idToOwner[_tokenId];
  }

  function addNFToken(address _to, uint256 _tokenId) internal {
    require(idToOwner[_tokenId] == address(0));
    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }
}

contract NFTokenEnumerable is NFToken, ERC721Enumerable {

  uint256[] internal tokens;
  mapping(uint256 => uint256) internal idToIndex;
  mapping(address => uint256[]) internal ownerToIds;
  mapping(uint256 => uint256) internal idToOwnerIndex;

  constructor() public {
    supportedInterfaces[0x780e9d63] = true;
  }

  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length.sub(1);
  }

  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);
    assert(tokens.length > 0);
    uint256 tokenIndex = idToIndex[_tokenId];
    assert(tokens[tokenIndex] == _tokenId);
    uint256 lastTokenIndex = tokens.length.sub(1);
    uint256 lastToken = tokens[lastTokenIndex];
    tokens[tokenIndex] = lastToken;
    tokens.length--;
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

  function removeNFToken(address _from, uint256 _tokenId) internal {
    super.removeNFToken(_from, _tokenId);
    assert(ownerToIds[_from].length > 0);
    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);
    uint256 lastToken = ownerToIds[_from][lastTokenIndex];
    ownerToIds[_from][tokenToRemoveIndex] = lastToken;
    ownerToIds[_from].length--;
    idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    idToOwnerIndex[_tokenId] = 0;
  }

  function addNFToken(address _to, uint256 _tokenId) internal {
    super.addNFToken(_to, _tokenId);
    uint256 length = ownerToIds[_to].length;
    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = length;
  }

  function totalSupply() external view returns (uint256) {
    return tokens.length;
  }

  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < tokens.length);
    assert(idToIndex[tokens[_index]] == _index);
    return tokens[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToIds[_owner].length);
    return ownerToIds[_owner][_index];
  }
}

interface ERC721Metadata {

  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string);
}

contract NFTokenMetadata is NFToken, ERC721Metadata {

  string internal nftName;
  string internal nftSymbol;
  mapping (uint256 => string) internal idToUri;

  constructor() public {
    supportedInterfaces[0x5b5e139f] = true;
  }

  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);
    if (bytes(idToUri[_tokenId]).length != 0) {
      delete idToUri[_tokenId];
    }
  }

  function _setTokenUri(uint256 _tokenId, string _uri) validNFToken(_tokenId) internal {
    idToUri[_tokenId] = _uri;
  }

  function name() external view returns (string _name) {
    _name = nftName;
  }

  function symbol() external view returns (string _symbol) {
    _symbol = nftSymbol;
  }

  function tokenURI(uint256 _tokenId) validNFToken(_tokenId) external view returns (string) {
    return idToUri[_tokenId];
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner public {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract MyXCY is NFTokenEnumerable, NFTokenMetadata, Ownable {
  using SafeMath for uint256;
  using AddressUtils for address;
  bytes4 internal nftConventionId;
  mapping (uint256 => string) internal idToProof;
  mapping (uint256 => bytes32[]) internal config;
  mapping (uint256 => bytes32[]) internal data;
  mapping (address => bool) internal addressToAuthorized;
  event AuthorizedAddress(address indexed _target, bool _authorized);

  modifier isAuthorized() {
    require(msg.sender == owner || addressToAuthorized[msg.sender]);
    _;
  }

  constructor() public {
    supportedInterfaces[0x6be14f75] = true;
  }

  function mint(address _to, uint256 _id, string _uri, string _proof, bytes32[] _config, bytes32[] _data) external isAuthorized() {
    require(_config.length > 0);
    require(bytes(_proof).length > 0);
    super._mint(_to, _id);
    super._setTokenUri(_id, _uri);
    idToProof[_id] = _proof;
    config[_id] = _config;
    data[_id] = _data;
  }

  function conventionId() external view returns (bytes4 _conventionId) {
    _conventionId = nftConventionId;
  }

  function tokenProof(uint256 _tokenId) validNFToken(_tokenId) external view returns(string) {
    return idToProof[_tokenId];
  }

  function tokenDataValue(uint256 _tokenId, uint256 _index) validNFToken(_tokenId) public view returns(bytes32 value) {
    require(_index < data[_tokenId].length);
    value = data[_tokenId][_index];
  }

  function tokenExpirationTime( uint256 _tokenId) validNFToken(_tokenId) external view returns(bytes32) {
    return config[_tokenId][0];
  }

  function setAuthorizedAddress(address _target, bool _authorized) onlyOwner external {
    require(_target != address(0));
    addressToAuthorized[_target] = _authorized;
    emit AuthorizedAddress(_target, _authorized);
  }

  function isAuthorizedAddress(address _target) external view returns (bool) {
    require(_target != address(0));
    return addressToAuthorized[_target];
  }
}

interface ERC20 {

  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function decimals() external view returns (uint8 _decimals);
  function totalSupply() external view returns (uint256 _totalSupply);
  function balanceOf(address _owner) external view returns (uint256 _balance);
  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20 {
  using SafeMath for uint256;

  string internal tokenName;
  string internal tokenSymbol;
  uint8 internal tokenDecimals;
  uint256 internal tokenTotalSupply;
  mapping (address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function name() external view returns (string _name) {
    _name = tokenName;
  }

  function symbol() external view returns (string _symbol) {
    _symbol = tokenSymbol;
  }

  function decimals() external view returns (uint8 _decimals) {
    _decimals = tokenDecimals;
  }

  function totalSupply() external view returns (uint256 _totalSupply) {
    _totalSupply = tokenTotalSupply;
  }

  function balanceOf(address _owner) external view returns (uint256 _balance) {
    _balance = balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool _success) {
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    _success = true;
  }

  function approve(address _spender, uint256 _value) public returns (bool _success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    _success = true;
  }

  function allowance(address _owner, address _spender) external view returns (uint256 _remaining) {
    _remaining = allowed[_owner][_spender];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    _success = true;
  }
}

contract Changercy is Token, Ownable {
  using SafeMath for uint256;

  bool internal transferEnabled;
  address public crowdsaleAddress;
  event Burn(address indexed _burner, uint256 _value);
  
  modifier validDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    require(_to != address(crowdsaleAddress));
    _;
  }

  modifier onlyWhenTransferAllowed() {
    require(transferEnabled || msg.sender == crowdsaleAddress);
    _;
  }

  constructor() public {
    tokenName = "Changercy";
    tokenSymbol = "XCY";
    tokenDecimals = 3;
    tokenTotalSupply = 114000000000000;
    transferEnabled = false;
    balances[owner] = tokenTotalSupply;
    emit Transfer(address(0x0), owner, tokenTotalSupply);
  }

  function transfer(address _to, uint256 _value) onlyWhenTransferAllowed() validDestination(_to) public returns (bool _success) {
    _success = super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyWhenTransferAllowed() validDestination(_to) public returns (bool _success) {
    _success = super.transferFrom(_from, _to, _value);
  }

  function enableTransfer() onlyOwner() external {
    transferEnabled = true;
  }

  function burn(uint256 _value) onlyOwner() external {
    require(_value <= balances[msg.sender]);
    balances[owner] = balances[owner].sub(_value);
    tokenTotalSupply = tokenTotalSupply.sub(_value);
    emit Burn(owner, _value);
    emit Transfer(owner, address(0x0), _value);
  }

  function setCrowdsaleAddress(address crowdsaleAddr) external onlyOwner() {
    crowdsaleAddress = crowdsaleAddr;
  }
}

contract ChangercyCrowdsale {
  using SafeMath for uint256;

  Changercy public token;
  MyXCY public xcyKYC;
  uint256 public startTimePresale;
  uint256 public startTimeSaleWithBonus;
  uint256 public startTimeSaleNoBonus;
  uint256 public bonusPresale;
  uint256 public bonusSale;
  uint256 public endTime;
  uint256 public minimumPresaleWeiDeposit;
  uint256 public preSaleXcyCap;
  uint256 public crowdSaleXcySupply;
  uint256 public xcySold;
  address public wallet;
  uint256 public rate;
  event TokenPurchase(address indexed _from, address indexed _to, uint256 _weiAmount, uint256 _tokenAmount);

  constructor(
    address _walletAddress,
    address _tokenAddress,
    address _xcyKYCAddress,
    uint256 _startTimePresale,
    uint256 _startTimeSaleWithBonus,
    uint256 _startTimeSaleNoBonus,
    uint256 _endTime,
    uint256 _rate,
    uint256 _presaleXcyCap,
    uint256 _crowdSaleXcySupply,
    uint256 _bonusPresale,
    uint256 _bonusSale,
    uint256 _minimumPresaleWeiDeposit
  ) public {
    require(_walletAddress != address(0));
    require(_tokenAddress != address(0));
    require(_xcyKYCAddress != address(0));
    require(_tokenAddress != _walletAddress);
    require(_tokenAddress != _xcyKYCAddress);
    require(_xcyKYCAddress != _walletAddress);

    token = Changercy(_tokenAddress);
    xcyKYC = MyXCY(_xcyKYCAddress);

    uint8 _tokenDecimals = token.decimals();
    require(_tokenDecimals == 3);
    wallet = _walletAddress;

    // Bonus should be > 0% and <= 100%
    require(_bonusPresale > 0 && _bonusPresale <= 100);
    require(_bonusSale > 0 && _bonusSale <= 100);

    bonusPresale = _bonusPresale;
    bonusSale = _bonusSale;

    require(_startTimeSaleWithBonus > _startTimePresale);
    require(_startTimeSaleNoBonus > _startTimeSaleWithBonus);

    startTimePresale = _startTimePresale;
    startTimeSaleWithBonus = _startTimeSaleWithBonus;
    startTimeSaleNoBonus = _startTimeSaleNoBonus;
    endTime = _endTime;

    require(_rate > 0);
    rate = _rate;

    require(_crowdSaleXcySupply > 0);
    require(token.totalSupply() >= _crowdSaleXcySupply);
    crowdSaleXcySupply = _crowdSaleXcySupply;

    require(_presaleXcyCap > 0 && _presaleXcyCap <= _crowdSaleXcySupply);
    preSaleXcyCap = _presaleXcyCap;

    xcySold = 17100000000000;

    require(_minimumPresaleWeiDeposit > 0);
    minimumPresaleWeiDeposit = _minimumPresaleWeiDeposit;
  }

  function() external payable {
    buyTokens();
  }

  function buyTokens() public payable {
    uint256 tokens;
    uint256 balance = xcyKYC.balanceOf(msg.sender);
    require(balance > 0);
    uint256 tokenId = xcyKYC.tokenOfOwnerByIndex(msg.sender, balance - 1);
    uint256 kycLevel = uint(xcyKYC.tokenDataValue(tokenId, 0));

    if (isInTimeRange(startTimePresale, startTimeSaleWithBonus)) {
      require(kycLevel > 1);
      require(msg.value >= minimumPresaleWeiDeposit);
      tokens = getTokenAmount(msg.value, bonusPresale);
      require(xcySold.add(tokens) <= preSaleXcyCap);
    }
    else if (isInTimeRange(startTimeSaleWithBonus, startTimeSaleNoBonus)) {
      require(kycLevel > 0);
      tokens = getTokenAmount(msg.value, bonusSale);
    }
    else if (isInTimeRange(startTimeSaleNoBonus, endTime)) {
      require(kycLevel > 0);
      tokens = getTokenAmount(msg.value, uint256(0));
    }
    else {
      revert("Purchase outside of token sale time windows");
    }

    require(xcySold.add(tokens) <= crowdSaleXcySupply);
    xcySold = xcySold.add(tokens);

    wallet.transfer(msg.value);
    require(token.transferFrom(token.owner(), msg.sender, tokens));
    emit TokenPurchase(msg.sender, msg.sender, msg.value, tokens);
  }

  function hasEnded() external view returns (bool) {
    bool capReached = xcySold >= crowdSaleXcySupply;
    bool endTimeReached = now >= endTime;
    return capReached || endTimeReached;
  }

  function isInTimeRange(uint256 _startTime, uint256 _endTime) internal view returns(bool) {
    if (now >= _startTime && now < _endTime) {
      return true;
    }
    else {
      return false;
    }
  }

  function getTokenAmount(uint256 weiAmount, uint256 bonusPercent) internal view returns(uint256) {
    uint256 tokens = weiAmount.mul(rate);

    if (bonusPercent > 0) {
      uint256 bonusTokens = tokens.mul(bonusPercent).div(uint256(100)); // tokens * bonus (%) / 100%
      tokens = tokens.add(bonusTokens);
    }

    return tokens;
  }
}