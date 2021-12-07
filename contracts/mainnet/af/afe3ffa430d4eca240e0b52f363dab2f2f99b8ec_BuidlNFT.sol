// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "./ILootBox.sol";
import "./ERC721.sol";
import "./ERC20_transfer.sol";
import "./Ownable.sol";
import "./AddressUtils.sol";
import "./SafeMath.sol";
import "./String.sol";

contract BuidlNFT is ERC721, Ownable {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Token name
  string constant private _name = "Open Source BUIDL Token";

  // Token symbol
  string constant private _symbol = "BUIDL";

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant private ERC721_RECEIVED = 0xf0b9e5ba;

  // Provide verification of the relationship between buidler and BUIDL
  address public verifier;

  // Public URL
  string public publicURL;

  // Mapping from token ID to owner
  mapping(uint256 => address) internal _tokenOwner;

  // Mapping from token ID to approved address
  mapping(uint256 => address) internal _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping(address => uint256) internal _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  // Array with all token ids, used for enumeration
  uint256[] internal _allTokens;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal _ownedTokensIndex;

  struct Buidl {
    uint256 originalPrice;
    uint256 currentPrice;
    uint256 txs;
    address buidler;
  }
  mapping(uint256 => Buidl) internal _buidls;
  mapping(uint256 => address) internal _lootBox;

  // ERC20 token used in NFT transaction
  ERC20 public currency;

  bool public miningTax;
  bool public initialized;

  uint256 constant public UNIT = 1000;
  uint256 constant public BUIDLER_TAX = 20; // 2%
  uint256 constant public PROTOCOL_TAX = 10; // 1%
  uint256 constant public OWNER_INCOME = 700; // 70%
  uint256 constant public BUIDLER_INCOME = 200; // 20%
  // uint256 constant public PROTOCOL_INCOME = 100; // 1 - OWNER_INCOME - BUIDLER_INCOME = 10%

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
  bytes4 constant private INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
  bytes4 constant private INTERFACE_SIGNATURE_ERC721METADATA = 0x5b5e139f;
  bytes4 constant private INTERFACE_SIGNATURE_ERC721ENUMERABLE = 0x780e9d63;

  function supportsInterface(bytes4 _interfaceId) override external pure returns (bool) {
    if (
      _interfaceId == INTERFACE_SIGNATURE_ERC165 ||
      _interfaceId == INTERFACE_SIGNATURE_ERC721 ||
      _interfaceId == INTERFACE_SIGNATURE_ERC721METADATA ||
      _interfaceId == INTERFACE_SIGNATURE_ERC721ENUMERABLE
    ) {
      return true;
    }

    return false;
  }

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

  event PublicURL(string _url);
  event MiningTax(bool _state);
  event Verifier(address _verifier);
  event LootBox(uint256 indexed _tokenId, address indexed _lootBox);
  event HarbergerBuy(uint256 indexed _tokenId, address indexed _buyer, uint256 _price, uint256 _txs);

  function initialize(ERC20 _currency, address _verifier) public {
    require(!initialized);
    initialized = true;
    admin = msg.sender;
    publicURL = "https://hackerlink.io/buidl/";
    currency = _currency;
    verifier = _verifier;
    emit Verifier(_verifier);
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(_isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() override external pure returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() override external pure returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Gets the token url
   * @param _tokenId uint256 ID of the token to validate
   * @return string representing the token url
   */
  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    Buidl storage buidl = _buidls[_tokenId];
    require(buidl.buidler != address(0));
    return (String.appendUintToString(publicURL, _tokenId));
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) override public view returns (uint256) {
    require(_owner != address(0));
    return _ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) override public view returns (address) {
    address owner = _tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) override external view returns (uint256) {
    require(_index < balanceOf(_owner));
    return _ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() override public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) override external view returns (uint256) {
    require(_index < totalSupply());
    return _allTokens[_index];
  }

  /**
   * @dev Sets the public URL by administrator
   * @param _url new public URL
   */
  function setPublicURL(string memory _url) external onlyOwner {
    publicURL = _url;
    emit PublicURL(_url);
  }

  /**
   * @dev Sets whether to charge mining tax or not by administrator
   * @param _state mining tax state
   */
  function setMiningTax(bool _state) external onlyOwner {
    miningTax = _state;
    emit MiningTax(_state);
  }

  function setVerifier(address _newVerifier) external onlyOwner {
    verifier = _newVerifier;
    emit Verifier(_newVerifier);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) override external {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      _tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 _tokenId) override public view returns (address) {
    return _tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) override external {
    require(_to != msg.sender);
    _operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) override public view returns (bool) {
    return _operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) override public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    _clearApproval(_from, _tokenId);
    _removeTokenFrom(_from, _tokenId);
    _addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) override public canTransfer(_tokenId) {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) override public canTransfer(_tokenId) {
    transferFrom(_from, _to, _tokenId);
    require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

////////////////////////////////////////////// MAIN //////////////////////////////////////////////

  function mint(uint256 _initPrice, uint256 _bid, address _lootBoxAddr, bytes calldata _sign) external {
    mint(_initPrice, _bid, _sign);
    setLootBox(_bid, _lootBoxAddr);
  }

  function mint(uint256 _initPrice, uint256 _bid, bytes calldata _sign) public {
    _checkBid(_bid, _sign);
    if (miningTax) {
      uint256 tax = _initPrice.mul(PROTOCOL_TAX) / UNIT;
      require(currency.transferFrom(msg.sender, address(this), tax), "no mint tax");
    }
    _mint(msg.sender, _bid);
    _buidls[_bid] = Buidl(_initPrice, _initPrice, 0, msg.sender);
  }

  function mintFor(
    address[] memory _buidler,
    uint256[] memory _initPrice,
    uint256[] memory _currentPrice,
    uint256[] memory _bid,
    address[] memory _owner,
    uint256[] memory _txs
  ) external {
    require(!initialized);
    for (uint256 i = 0; i < _buidler.length; i++) {
      uint256 bid = _bid[i];
      address buidler = _buidler[i];
      address owner = _owner[i];

      _buidls[bid] = Buidl(_initPrice[i], _currentPrice[i], _txs[i], buidler);
      _addTokenTo(owner, bid);
      _allTokens.push(bid);

      emit Transfer(address(0), buidler, bid);
      if (owner != buidler) {
        emit Transfer(buidler, owner, bid);
      }
    }
  }

  function setLootBox(uint256 _tokenId, address _lootBoxAddr) public {
    require(msg.sender == ownerOf(_tokenId));
    Buidl storage buidl = _buidls[_tokenId];
    require(msg.sender == buidl.buidler);

    _lootBox[_tokenId] = _lootBoxAddr;
    emit LootBox(_tokenId, _lootBoxAddr);
  }

  function harbergerBuy(uint256 _tokenId, uint256 _newPrice) external {
    address owner = ownerOf(_tokenId);

    Buidl storage buidl = _buidls[_tokenId];
    uint256 currentPrice = buidl.currentPrice;
    require(_newPrice > currentPrice);

    // |<------------------ newPrice ------------------>|
    // |<-------- currentPrice -------->|<-- premium -->|<- tax ->|
    // |<----------------------- totalSpend --------------------->|

    // |<---------------- premium ---------------->|
    // |<--------- 7 --------->|<--- 2 --->|<- 1 ->|
    // |          OWNER        |  BUIDLER  | PRTCL |
  
    // |<------ tax ------>|
    // |<--- 2 --->|<- 1 ->|
    // |  BUIDLER  | PRTCL |

    uint256 premium = _newPrice - currentPrice;
    uint256 ownerIncome = premium.mul(OWNER_INCOME) / UNIT;
    uint256 buidlerIncome = premium.mul(BUIDLER_INCOME) / UNIT;
  
    uint256 buidlerTax = _newPrice.mul(BUIDLER_TAX) / UNIT;
    uint256 protocolTax = _newPrice.mul(PROTOCOL_TAX) / UNIT;

    uint256 totalSpend = _newPrice.add(protocolTax).add(buidlerTax);

    require(currency.transferFrom(msg.sender, address(this), totalSpend));
    require(currency.transfer(owner, ownerIncome.add(currentPrice)));
    require(currency.transfer(buidl.buidler, buidlerIncome.add(buidlerTax)));

    uint256 txs = buidl.txs.add(1);
    buidl.currentPrice = _newPrice;
    buidl.txs = txs;

    _clearApproval(owner, _tokenId);
    _removeTokenFrom(owner, _tokenId);
    _addTokenTo(msg.sender, _tokenId);

    require(_checkAndCallSafeTransfer(owner, msg.sender, _tokenId, "BUY"));

    // If NFT has an existing Loot Box, it will actively notify the LootBox
    address lootBox = _lootBox[_tokenId];
    if (lootBox != address(0)) {
      try ILootBox(lootBox).afterHarbergerBuy(_tokenId, msg.sender) {} catch {}
    }

    emit Transfer(owner, msg.sender, _tokenId);
    emit HarbergerBuy(_tokenId, msg.sender, _newPrice, txs);
  }

  function withdraw(uint256 _amount) external onlyOwner {
    require(currency.transfer(admin, _amount));
  }

  function metadataOf(uint256 _tokenId) external view returns (
    address owner,
    uint256 bid,
    uint256 originalPrice,
    uint256 currentPrice,
    uint256 txs,
    address buidler,
    string memory url,
    address lootBox
  ) {
    owner = ownerOf(_tokenId);
    Buidl storage buidl = _buidls[_tokenId];
    bid = _tokenId;
    originalPrice = buidl.originalPrice;
    currentPrice = buidl.currentPrice;
    txs = buidl.txs;
    buidler = buidl.buidler;
    url = tokenURI(_tokenId);
    lootBox = _lootBox[_tokenId];
  }

////////////////////////////////////////////// MAIN //////////////////////////////////////////////

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  function _checkBid(uint256 _bid, bytes calldata _sign) internal view {
    require(_sign.length == 65, "invalid sign");
    bytes32 h = keccak256(abi.encodePacked(msg.sender, _bid));
    uint8 v = uint8(bytes1(_sign[64:]));
    (bytes32 r, bytes32 s) = abi.decode(_sign[:64], (bytes32, bytes32));
    address signer = ecrecover(h, v, r, s);
    require(signer == verifier, "wrong signer");
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_tokenOwner[_tokenId] == address(0));
    require(_to != address(0));
    _addTokenTo(_to, _tokenId);
    _allTokens.push(_tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (_tokenApprovals[_tokenId] != address(0)) {
      _tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address _to, uint256 _tokenId) internal {
    require(_tokenOwner[_tokenId] == address(0));
    _tokenOwner[_tokenId] = _to;
    _ownedTokensCount[_to] = _ownedTokensCount[_to].add(1);
  
    uint256 length = _ownedTokens[_to].length;
    _ownedTokens[_to].push(_tokenId);
    _ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    _ownedTokensCount[_from] = _ownedTokensCount[_from].sub(1);
    _tokenOwner[_tokenId] = address(0);

    uint256 tokenIndex = _ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = _ownedTokens[_from].length.sub(1);
    uint256 lastToken = _ownedTokens[_from][lastTokenIndex];

    _ownedTokens[_from][tokenIndex] = lastToken;
    _ownedTokensIndex[lastToken] = tokenIndex;

    _ownedTokens[_from].pop();
    _ownedTokensIndex[_tokenId] = 0;
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * @dev The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}