/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.7.4;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public admin;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    admin = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newAdmin The address to transfer ownership to.
   */
  function transferOwnership(address newAdmin) external onlyOwner {
    require(newAdmin != address(0));
    emit OwnershipTransferred(admin, newAdmin);
    admin = newAdmin;
  }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);

  function approve(address _to, uint256 _tokenId) external;
  function getApproved(uint256 _tokenId) external view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Enumerable is ERC721Basic {
  function totalSupply() external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) external view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Metadata is ERC721Basic {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-165 Standard Interface Detection
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata, ERC165 {}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
interface ERC721Receiver {
  function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {
  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library String {
  // From https://ethereum.stackexchange.com/questions/10811/solidity-concatenate-uint-into-a-string

  function appendUintToString(string memory inStr, uint v) internal pure returns (string memory str) {
    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
      uint remainder = v % 10;
      v = v / 10;
      reversed[i++] = byte(uint8(48 + remainder));
    }
    bytes memory inStrb = bytes(inStr);
    bytes memory s = new bytes(inStrb.length + i);
    uint j;
    for (j = 0; j < inStrb.length; j++) {
      s[j] = inStrb[j];
    }
    for (j = 0; j < i; j++) {
      s[j + inStrb.length] = reversed[i - 1 - j];
    }
    str = string(s);
  }
}

contract Main is ERC721, Ownable {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Token name
  string constant private _name = "OSS BUIDL Token";

  // Token symbol
  string constant private _symbol = "BUIDL";

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant private ERC721_RECEIVED = 0xf0b9e5ba;

  // Public URL
  string public publicURL = "https://hackerlink.io/buidl/";

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
    uint256 cid;
    uint256 originalPrice;
    uint256 currentPrice;
    uint256 txs;
    address miner;
    string remarks;
  }
  mapping(uint256 => Buidl) internal _buidls;

  // ERC20 token used in NFT transaction
  ERC20 public currency;

  bool public miningTax = true;

  uint256 constant public UNIT = 1000;
  uint256 constant public MINER_TAX = 20; // 2%
  uint256 constant public PLATFORM_TAX = 10; // 1%
  uint256 constant public OWNER_INCOME = 700; // 70%
  uint256 constant public MINER_INCOME = 200; // 20%
  // uint256 constant public PLATFORM_INCOME = 100; // 1 - OWNER_INCOME - MINER_INCOME = 10%

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
  event HarbergeBuy(uint256 indexed _tokenId, address indexed _buyer, uint256 _price, uint256 _txs);

  constructor(ERC20 _currency) {
    currency = _currency;
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
    require(buidl.miner != address(0));
    return (String.appendUintToString(publicURL, buidl.cid));
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
    // solium-disable-next-line arg-overflow
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
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

////////////////////////////////////////////// MAIN //////////////////////////////////////////////

  function mint(uint256 _initPrice, uint256 _cId, string memory _remarks) external {
    uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, _cId)));
    if (miningTax) {
      uint256 tax = _initPrice.mul(PLATFORM_TAX) / UNIT;
      require(currency.transferFrom(msg.sender, address(this), tax));
    }
    _mint(msg.sender, tokenId);
    _buidls[tokenId] = Buidl(_cId, _initPrice, _initPrice, 0, msg.sender, _remarks);
  }

  function harbergeBuy(uint256 _tokenId, uint256 _newPrice) external {
    address owner = ownerOf(_tokenId);

    Buidl storage buidl = _buidls[_tokenId];
    uint256 currentPrice = buidl.currentPrice;
    require(_newPrice > currentPrice);

    // |<------------------ newPrice ------------------>|
    // |<-------- currentPrice -------->|<-- growing -->|<- tax ->|
    // |<----------------------- totalSpend --------------------->|

    // |<---------------- growing ---------------->|
    // |<--------- 7 --------->|<--- 2 --->|<- 1 ->|
    // |          OWNER        |   MINER   | PLATF |
  
    // |<------ tax ------>|
    // |<--- 2 --->|<- 1 ->|
    // |   MINER   | PLATF |

    uint256 growing = _newPrice - currentPrice;
    uint256 ownerIncome = growing.mul(OWNER_INCOME) / UNIT;
    uint256 minerIncome = growing.mul(MINER_INCOME) / UNIT;
  
    uint256 minerTax = _newPrice.mul(MINER_TAX) / UNIT;
    uint256 platformTax = _newPrice.mul(PLATFORM_TAX) / UNIT;

    uint256 totalSpend = _newPrice.add(platformTax).add(minerTax);

    require(currency.transferFrom(msg.sender, address(this), totalSpend));
    require(currency.transfer(owner, ownerIncome.add(currentPrice)));
    require(currency.transfer(buidl.miner, minerIncome.add(minerTax)));

    uint256 txs = buidl.txs.add(1);
    buidl.currentPrice = _newPrice;
    buidl.txs = txs;

    _clearApproval(owner, _tokenId);
    _removeTokenFrom(owner, _tokenId);
    _addTokenTo(msg.sender, _tokenId);

    require(_checkAndCallSafeTransfer(owner, msg.sender, _tokenId, "BUY"));

    emit Transfer(owner, msg.sender, _tokenId);
    emit HarbergeBuy(_tokenId, msg.sender, _newPrice, txs);
  }

  function withdraw(uint256 _amount) external onlyOwner {
    require(currency.transfer(admin, _amount));
  }

  function metadataOf(uint256 _tokenId) external view returns (
    address owner,
    uint256 cid,
    uint256 originalPrice,
    uint256 currentPrice,
    uint256 txs,
    address miner,
    string memory url,
    string memory remarks
  ) {
    owner = ownerOf(_tokenId);
    Buidl storage buidl = _buidls[_tokenId];
    cid = buidl.cid;
    originalPrice = buidl.originalPrice;
    currentPrice = buidl.currentPrice;
    txs = buidl.txs;
    miner = buidl.miner;
    url = tokenURI(_tokenId);
    remarks = buidl.remarks;
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