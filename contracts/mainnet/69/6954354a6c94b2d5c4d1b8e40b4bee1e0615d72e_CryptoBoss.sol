pragma solidity ^0.4.17;

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */

/* solium-disable zeppelin/missing-natspec-comments */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) external;
  function setApprovalForAll(address _to, bool _approved) external;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}
library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}
contract ERC721SlimToken is Ownable, ERC721, ERC165, ERC721Metadata {
  using SafeMath for uint256;

  string public constant NAME = "EtherLoot";
  string public constant SYMBOL = "ETLT";
  string public tokenMetadataBaseURI = "http://api.etherloot.moonshadowgames.com/tokenmetadata/";

  struct AddressAndTokenIndex {
    address owner;
    uint32 tokenIndex;
  }

  mapping (uint256 => AddressAndTokenIndex) private tokenOwnerAndTokensIndex;

  mapping (address => uint256[]) private ownedTokens;

  mapping (uint256 => address) private tokenApprovals;

  mapping (address => mapping (address => bool)) private operatorApprovals;

  mapping (address => bool) private approvedContractAddresses;

  bool approvedContractsFinalized = false;

  function implementsERC721() external pure returns (bool) {
    return true;
  }



  function supportsInterface(
    bytes4 interfaceID)
    external view returns (bool)
  {
    return
      interfaceID == this.supportsInterface.selector || // ERC165
      interfaceID == 0x5b5e139f || // ERC721Metadata
      interfaceID == 0x6466353c; // ERC-721
  }

  function name() external pure returns (string) {
    return NAME;
  }

  function symbol() external pure returns (string) {
    return SYMBOL;
  }

  function setTokenMetadataBaseURI(string _tokenMetadataBaseURI) external onlyOwner {
    tokenMetadataBaseURI = _tokenMetadataBaseURI;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    returns (string infoUrl)
  {
    return Strings.strConcat(
      tokenMetadataBaseURI,
      Strings.uint2str(tokenId));
  }

  /**
  * @notice Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender, "not owner");
    _;
  }

  /**
  * @notice Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0), "null owner");
    return ownedTokens[_owner].length;
  }

  /**
  * @notice Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
  * @notice Enumerate NFTs assigned to an owner
  * @dev Throws if `_index` >= `balanceOf(_owner)` or if
  *  `_owner` is the zero address, representing invalid NFTs.
  * @param _owner An address where we are interested in NFTs owned by them
  * @param _index A counter less than `balanceOf(_owner)`
  * @return The token identifier for the `_index`th NFT assigned to `_owner`,
  */
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner), "invalid index");
    return ownedTokens[_owner][_index];
  }

  /**
  * @notice Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address _owner = tokenOwnerAndTokensIndex[_tokenId].owner;
    require(_owner != address(0), "invalid owner");
    return _owner;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    address _owner = tokenOwnerAndTokensIndex[_tokenId].owner;
    return (_owner != address(0));
  }

  /**
   * @notice Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @notice Tells whether the msg.sender is approved to transfer the given token ID or not
   * Checks both for specific approval and operator approval
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether transfer by msg.sender is approved for the given token ID or not
   */
  function isSenderApprovedFor(uint256 _tokenId) internal view returns (bool) {
    return
      ownerOf(_tokenId) == msg.sender ||
      isSpecificallyApprovedFor(msg.sender, _tokenId) ||
      isApprovedForAll(ownerOf(_tokenId), msg.sender);
  }

  /**
   * @notice Tells whether the msg.sender is approved for the given token ID or not
   * @param _asker address of asking for approval
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
    return getApproved(_tokenId) == _asker;
  }

  /**
   * @notice Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
  * @notice Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId)
    external
    onlyOwnerOf(_tokenId)
  {
    _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @notice Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId)
    external
    onlyOwnerOf(_tokenId)
  {
    address _owner = ownerOf(_tokenId);
    require(_to != _owner, "already owns");
    if (getApproved(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(_owner, _to, _tokenId);
    }
  }

  /**
  * @notice Enable or disable approval for a third party ("operator") to manage all your assets
  * @dev Emits the ApprovalForAll event
  * @param _to Address to add to the set of authorized operators.
  * @param _approved True if the operators is approved, false to revoke approval
  */
  function setApprovalForAll(address _to, bool _approved)
    external
  {
    if(_approved) {
      approveAll(_to);
    } else {
      disapproveAll(_to);
    }
  }

  /**
  * @notice Approves another address to claim for the ownership of any tokens owned by this account
  * @param _to address to be approved for the given token ID
  */
  function approveAll(address _to)
    public
  {
    require(_to != msg.sender, "cant approve yourself");
    require(_to != address(0), "invalid owner");
    operatorApprovals[msg.sender][_to] = true;
    emit ApprovalForAll(msg.sender, _to, true);
  }

  /**
  * @notice Removes approval for another address to claim for the ownership of any
  *  tokens owned by this account.
  * @dev Note that this only removes the operator approval and
  *  does not clear any independent, specific approvals of token transfers to this address
  * @param _to address to be disapproved for the given token ID
  */
  function disapproveAll(address _to)
    public
  {
    require(_to != msg.sender, "cant unapprove yourself");
    delete operatorApprovals[msg.sender][_to];
    emit ApprovalForAll(msg.sender, _to, false);
  }

  /**
  * @notice Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId)
   external
  {
    require(isSenderApprovedFor(_tokenId), "not approved");
    _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
  * @notice Transfer a token owned by another address, for which the calling address has
  *  previously been granted transfer approval by the owner.
  * @param _from The address that owns the token
  * @param _to The address that will take ownership of the token. Can be any address, including the caller
  * @param _tokenId The ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    address tokenOwner = ownerOf(_tokenId);
    require(isSenderApprovedFor(_tokenId) || 
      (approvedContractAddresses[msg.sender] && tokenOwner == tx.origin), "not an approved sender");
    require(tokenOwner == _from, "wrong owner");
    _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
  }

  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev Throws unless `msg.sender` is the current owner, an authorized
  * operator, or the approved address for this NFT. Throws if `_from` is
  * not the current owner. Throws if `_to` is the zero address. Throws if
  * `_tokenId` is not a valid NFT. When transfer is complete, this function
  * checks if `_to` is a smart contract (code size > 0). If so, it calls
  * `onERC721Received` on `_to` and throws if the return value is not
  * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
  * @param _from The current owner of the NFT
  * @param _to The new owner
  * @param _tokenId The NFT to transfer
  * @param _data Additional data with no specified format, sent in call to `_to`
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    require(_to != address(0), "invalid target address");
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
      bytes4 tokenReceiverResponse = ERC721TokenReceiver(_to).onERC721Received.gas(50000)(
        _from, _tokenId, _data
      );
      require(tokenReceiverResponse == bytes4(keccak256("onERC721Received(address,uint256,bytes)")), "invalid receiver respononse");
    }
  }

  /*
   * @notice Transfers the ownership of an NFT from one address to another address
   * @dev This works identically to the other function with an extra data parameter,
   *  except this function just sets data to ""
   * @param _from The current owner of the NFT
   * @param _to The new owner
   * @param _tokenId The NFT to transfer
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
  * @notice Approve a contract address for minting tokens and transferring tokens, when approved by the owner
  * @param contractAddress The address that will be approved
  */
  function addApprovedContractAddress(address contractAddress) public onlyOwner
  {
    require(!approvedContractsFinalized);
    approvedContractAddresses[contractAddress] = true;
  }

  /**
  * @notice Unapprove a contract address for minting tokens and transferring tokens
  * @param contractAddress The address that will be unapproved
  */
  function removeApprovedContractAddress(address contractAddress) public onlyOwner
  {
    require(!approvedContractsFinalized);
    approvedContractAddresses[contractAddress] = false;
  }

  /**
  * @notice Finalize the contract so it will be forever impossible to change the approved contracts list
  */
  function finalizeApprovedContracts() public onlyOwner {
    approvedContractsFinalized = true;
  }

  /**
  * @notice Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function mint(address _to, uint256 _tokenId) public {
    require(
      approvedContractAddresses[msg.sender] ||
      msg.sender == owner, "minter not approved"
    );
    _mint(_to, _tokenId);
  }

  /**
  * @notice Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0), "invalid target address");
    require(tokenOwnerAndTokensIndex[_tokenId].owner == address(0), "token already exists");
    _addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

  /**
  * @notice Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0), "invalid target address");
    require(_to != ownerOf(_tokenId), "already owns");
    require(ownerOf(_tokenId) == _from, "wrong owner");

    _clearApproval(_from, _tokenId);
    _removeToken(_from, _tokenId);
    _addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  /**
  * @notice Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function _clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner, "wrong owner");
    if (tokenApprovals[_tokenId] != 0) {
      tokenApprovals[_tokenId] = 0;
      emit Approval(_owner, 0, _tokenId);
    }
  }

  /**
  * @notice Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function _addToken(address _to, uint256 _tokenId) private {
    uint256 newTokenIndex = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);

    // I don&#39;t expect anyone to own 4 billion tokens, but just in case...
    require(newTokenIndex == uint256(uint32(newTokenIndex)), "overflow");

    tokenOwnerAndTokensIndex[_tokenId] = AddressAndTokenIndex({owner: _to, tokenIndex: uint32(newTokenIndex)});
  }

  /**
  * @notice Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function _removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from, "wrong owner");

    uint256 tokenIndex = tokenOwnerAndTokensIndex[_tokenId].tokenIndex;
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;

    ownedTokens[_from].length--;
    tokenOwnerAndTokensIndex[lastToken] = AddressAndTokenIndex({owner: _from, tokenIndex: uint32(tokenIndex)});
  }

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}
/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function smax256(int256 a, int256 b) internal pure returns (int256) {
    return a >= b ? a : b;
  }
}

contract ContractAccessControl {

  event ContractUpgrade(address newContract);
  event Paused();
  event Unpaused();

  address public ceoAddress;

  address public cfoAddress;

  address public cooAddress;

  address public withdrawalAddress;

  bool public paused = false;

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress ||
      msg.sender == cfoAddress
    );
    _;
  }

  modifier onlyCEOOrCFO() {
    require(
      msg.sender == cfoAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

  modifier onlyCEOOrCOO() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  function setWithdrawalAddress(address _newWithdrawalAddress) external onlyCEO {
    require(_newWithdrawalAddress != address(0));
    withdrawalAddress = _newWithdrawalAddress;
  }

  function withdrawBalance() external onlyCEOOrCFO {
    require(withdrawalAddress != address(0));
    withdrawalAddress.transfer(this.balance);
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyCLevel whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
    emit Unpaused();
  }
}

contract CryptoBoss is ContractAccessControl {

  address constant tokenContractAddress = 0xe1015a79a7d488f8fecf073b187d38c6f1a77368;
  ERC721SlimToken constant tokenContract = ERC721SlimToken(tokenContractAddress);

  event Participating(address indexed player, uint encounterId);
  event LootClaimed(address indexed player, uint encounterId);
  event DailyLootClaimed(uint day);

  struct ParticipantData {
    uint32 damage;
    uint64 cumulativeDamage;
    uint8 forgeWeaponRarity;
    uint8 forgeWeaponDamagePure;
    bool lootClaimed;
    bool consolationPrizeClaimed;
  }

  struct Encounter {
    mapping (address => ParticipantData) participantData;
    address[] participants;
  }

  //encounterId is the starting block number / encounterBlockDuration
  mapping (uint => Encounter) encountersById;

  mapping (uint => address) winnerPerDay;
  mapping (uint => mapping (address => uint)) dayToAddressToScore;
  mapping (uint => bool) dailyLootClaimedPerDay;

   uint constant encounterBlockDuration = 80;
   uint constant blocksInADay = 5760;

//   uint constant encounterBlockDuration = 20;
//   uint constant blocksInADay = 60;    // must be a multiple of encounterBlockDuration

  uint256 gasRefundForClaimLoot = 279032000000000;
  uint256 gasRefundForClaimConsolationPrizeLoot = 279032000000000;
  uint256 gasRefundForClaimLootWithConsolationPrize = 279032000000000;

  uint participateFee = 0.002 ether;
  uint participateDailyLootContribution = 0.001 ether;

  constructor() public {

    paused = false;

    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    withdrawalAddress = msg.sender;
  }
  
  function setGasRefundForClaimLoot(uint256 _gasRefundForClaimLoot) external onlyCEO {
      gasRefundForClaimLoot = _gasRefundForClaimLoot;
  }

  function setGasRefundForClaimConsolationPrizeLoot(uint256 _gasRefundForClaimConsolationPrizeLoot) external onlyCEO {
      gasRefundForClaimConsolationPrizeLoot = _gasRefundForClaimConsolationPrizeLoot;
  }

  function setGasRefundForClaimLootWithConsolationPrize(uint256 _gasRefundForClaimLootWithConsolationPrize) external onlyCEO {
      gasRefundForClaimLootWithConsolationPrize = _gasRefundForClaimLootWithConsolationPrize;
  }

  function setParticipateFee(uint _participateFee) public onlyCLevel {
    participateFee = _participateFee;
  }

  function setParticipateDailyLootContribution(uint _participateDailyLootContribution) public onlyCLevel {
    participateDailyLootContribution = _participateDailyLootContribution;
  }

  function getFirstEncounterIdFromDay(uint day) internal pure returns (uint) {
    return (day * blocksInADay) / encounterBlockDuration;
  }

  function leaderboardEntries(uint day) public view returns
    (uint etherPot, bool dailyLootClaimed, uint blockDeadline, address[] memory entryAddresses, uint[] memory entryDamages) {    

    dailyLootClaimed = dailyLootClaimedPerDay[day];
    blockDeadline = (((day+1) * blocksInADay) / encounterBlockDuration) * encounterBlockDuration;

    uint participantCount = 0;
    etherPot = 0;

    for (uint encounterId = getFirstEncounterIdFromDay(day); encounterId < getFirstEncounterIdFromDay(day+1); encounterId++)
    {
      address[] storage participants = encountersById[encounterId].participants;
      participantCount += participants.length;
      etherPot += participateDailyLootContribution * participants.length;
    }

    entryAddresses = new address[](participantCount);
    entryDamages = new uint[](participantCount);

    participantCount = 0;

    for (encounterId = getFirstEncounterIdFromDay(day); encounterId < getFirstEncounterIdFromDay(day+1); encounterId++)
    {
      participants = encountersById[encounterId].participants;
      mapping (address => ParticipantData) participantData = encountersById[encounterId].participantData;
      for (uint i = 0; i < participants.length; i++)
      {
        address participant = participants[i];
        entryAddresses[participantCount] = participant;
        entryDamages[participantCount] = participantData[participant].damage;
        participantCount++;
      }
    }
  }

  function claimDailyLoot(uint day) public {
    require(!dailyLootClaimedPerDay[day]);
    require(winnerPerDay[day] == msg.sender);

    uint firstEncounterId = day * blocksInADay / encounterBlockDuration;
    uint firstEncounterIdTomorrow = ((day+1) * blocksInADay / encounterBlockDuration);
    uint etherPot = 0;
    for (uint encounterId = firstEncounterId; encounterId < firstEncounterIdTomorrow; encounterId++)
    {
      etherPot += participateDailyLootContribution * encountersById[encounterId].participants.length;
    }

    dailyLootClaimedPerDay[day] = true;

    msg.sender.transfer(etherPot);

    emit DailyLootClaimed(day);
  }

  function blockBeforeEncounter(uint encounterId) private pure returns (uint) {
    return encounterId*encounterBlockDuration - 1;
  }

  function getEncounterDetails() public view
    returns (uint encounterId, uint encounterFinishedBlockNumber, bool isParticipating, uint day, uint monsterDna) {
    encounterId = block.number / encounterBlockDuration;
    encounterFinishedBlockNumber = (encounterId+1) * encounterBlockDuration;
    Encounter storage encounter = encountersById[encounterId];
    isParticipating = (encounter.participantData[msg.sender].damage != 0);
    day = (encounterId * encounterBlockDuration) / blocksInADay;
    monsterDna = uint(blockhash(blockBeforeEncounter(encounterId)));
  }

  function getParticipants(uint encounterId) public view returns (address[]) {

    Encounter storage encounter = encountersById[encounterId];
    return encounter.participants;
  }

  function calculateWinner(uint numParticipants, Encounter storage encounter, uint blockToHash) internal view returns
    (address winnerAddress, uint rand, uint totalDamageDealt) {

    if (numParticipants == 0) {
      return;
    }

    totalDamageDealt = encounter.participantData[encounter.participants[numParticipants-1]].cumulativeDamage;

    rand = uint(keccak256(blockhash(blockToHash)));
    uint winnerDamageValue = rand % totalDamageDealt;

    uint winnerIndex = numParticipants;

    // binary search for a value winnerIndex where
    // winnerDamageValue < cumulativeDamage[winnerIndex] and 
    // winnerDamageValue >= cumulativeDamage[winnerIndex-1]

    uint min = 0;
    uint max = numParticipants - 1;
    while(max >= min) {
      uint guess = (min+max)/2;
      if (guess > 0 && winnerDamageValue < encounter.participantData[encounter.participants[guess-1]].cumulativeDamage) {
        max = guess-1;
      }
      else if (winnerDamageValue >= encounter.participantData[encounter.participants[guess]].cumulativeDamage) {
        min = guess+1;
      } else {
        winnerIndex = guess;
        break;
      }

    }

    require(winnerIndex < numParticipants, "error in binary search");

    winnerAddress = encounter.participants[winnerIndex];
  }

  function getBlockToHashForResults(uint encounterId) public view returns (uint) {
      
    uint blockToHash = (encounterId+1)*encounterBlockDuration - 1;
    
    require(block.number > blockToHash);
    
    uint diff = block.number - (blockToHash+1);
    if (diff > 255) {
        blockToHash += (diff/256)*256;
    }
    
    return blockToHash;
  }
  
  function getEncounterResults(uint encounterId, address player) public view returns (
    address winnerAddress, uint lootTokenId, uint consolationPrizeTokenId,
    bool lootClaimed, uint damageDealt, uint totalDamageDealt) {

    uint blockToHash = getBlockToHashForResults(encounterId);

    Encounter storage encounter = encountersById[encounterId];
    uint numParticipants = encounter.participants.length;
    if (numParticipants == 0) {
      return (address(0), 0, 0, false, 0, 0);
    }

    damageDealt = encounter.participantData[player].damage;

    uint rand;
    (winnerAddress, rand, totalDamageDealt) = calculateWinner(numParticipants, encounter, blockToHash);

    lootTokenId = constructWeaponTokenIdForWinner(rand, numParticipants);

    lootClaimed = true;
    consolationPrizeTokenId = getConsolationPrizeTokenId(encounterId, player);

    if (consolationPrizeTokenId != 0) {
        lootClaimed = encounter.participantData[player].consolationPrizeClaimed;
        
        // This way has problems:
    //   lootClaimed = tokenContract.exists(consolationPrizeTokenId);
    }
  }
  
    function getLootClaimed(uint encounterId, address player) external view returns (bool, bool) {
        ParticipantData memory participantData = encountersById[encounterId].participantData[player];
        return (
            participantData.lootClaimed,
            participantData.consolationPrizeClaimed
        );
    }

  function constructWeaponTokenIdForWinner(uint rand, uint numParticipants) pure internal returns (uint) {

    uint rarity = 0;
    if (numParticipants > 1) rarity = 1;
    if (numParticipants > 10) rarity = 2;

    return constructWeaponTokenId(rand, rarity, 0);
  }

  function getWeaponRarityFromTokenId(uint tokenId) pure internal returns (uint) {
    return tokenId & 0xff;
  }  

  // damageType: 0=physical 1=magic 2=water 3=earth 4=fire
  function getWeaponDamageFromTokenId(uint tokenId, uint damageType) pure internal returns (uint) {
    return ((tokenId >> (64 + damageType*8)) & 0xff);
  }  

  function getPureWeaponDamageFromTokenId(uint tokenId) pure internal returns (uint) {
    return ((tokenId >> (56)) & 0xff);
  }  

  function getMonsterDefenseFromDna(uint monsterDna, uint damageType) pure internal returns (uint) {
    return ((monsterDna >> (64 + damageType*8)) & 0xff);
  }


  // constant lookup table

  bytes10 constant elementsAvailableForCommon =     hex"01020408100102040810";   // Each byte has 1 bit set
  bytes10 constant elementsAvailableForRare =       hex"030506090A0C11121418";   // Each byte has 2 bits set
  bytes10 constant elementsAvailableForEpic =       hex"070B0D0E131516191A1C";   // 3 bits
  bytes10 constant elementsAvailableForLegendary =  hex"0F171B1D1E0F171B1D1E";   // 4 bits

  // rarity 0: common (1 element)
  // rarity 1: rare (2 elements)
  // rarity 2: epic (3 elements)
  // rarity 3: legendary (4 elements)
  // rarity 4: ultimate (all 5 elements)
  function constructWeaponTokenId(uint rand, uint rarity, uint pureDamage) pure internal returns (uint) {
    uint lootTokenId = (rand & 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) + rarity;

    bytes10[4] memory elementsAvailablePerRarity = [
      elementsAvailableForCommon,
      elementsAvailableForRare,
      elementsAvailableForEpic,
      elementsAvailableForLegendary
      ];

    bytes10 elementsAvailable = elementsAvailablePerRarity[rarity];
    // Select a random byte in elementsAvailable
    uint8 elementsUsed = uint8(elementsAvailable[((rand >> 104) & 0xffff) % 10]);
    // The bits of elementsUsed represent which elements we will allow this weapon to deal damage for
    // Zero out the other element damages
    for (uint i = 0; i < 5; i++) {
      if ((elementsUsed & (1 << i)) == 0) {
        lootTokenId = lootTokenId & ~(0xff << (64 + i*8));
      }
    }

    pureDamage = Math.min256(100, pureDamage);

    lootTokenId = lootTokenId | (pureDamage << 56);

    return lootTokenId;
  }

  function weaponTokenIdToDamageForEncounter(uint weaponTokenId, uint encounterId) view internal returns (uint) {
    uint monsterDna = uint(blockhash(encounterId*encounterBlockDuration - 1));

    uint physicalDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 0)) - int(getMonsterDefenseFromDna(monsterDna, 0))));
    uint fireDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 4)) - int(getMonsterDefenseFromDna(monsterDna, 4))));
    uint earthDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 3)) - int(getMonsterDefenseFromDna(monsterDna, 3))));
    uint waterDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 2)) - int(getMonsterDefenseFromDna(monsterDna, 2))));
    uint magicDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 1)) - int(getMonsterDefenseFromDna(monsterDna, 1))));
    uint pureDamage = getPureWeaponDamageFromTokenId(weaponTokenId);

    uint damage = physicalDamage + fireDamage + earthDamage + waterDamage + magicDamage + pureDamage;
    damage = Math.max256(1, damage);

    return damage;
  }

  function forgeWeaponPureDamage(uint sacrificeTokenId1, uint sacrificeTokenId2, uint sacrificeTokenId3, uint sacrificeTokenId4)
    internal pure returns (uint8) {
    if (sacrificeTokenId1 == 0) {
      return 0;
    }
    return uint8(Math.min256(255,
        getPureWeaponDamageFromTokenId(sacrificeTokenId1) +
        getPureWeaponDamageFromTokenId(sacrificeTokenId2) +
        getPureWeaponDamageFromTokenId(sacrificeTokenId3) +
        getPureWeaponDamageFromTokenId(sacrificeTokenId4)));
  }

  function forgeWeaponRarity(uint sacrificeTokenId1, uint sacrificeTokenId2, uint sacrificeTokenId3, uint sacrificeTokenId4)
    internal pure returns (uint8) {
    if (sacrificeTokenId1 == 0) {
      return 0;
    }
    uint rarity = getWeaponRarityFromTokenId(sacrificeTokenId1);
    rarity = Math.min256(rarity, getWeaponRarityFromTokenId(sacrificeTokenId2));
    rarity = Math.min256(rarity, getWeaponRarityFromTokenId(sacrificeTokenId3));
    rarity = Math.min256(rarity, getWeaponRarityFromTokenId(sacrificeTokenId4)) + 1;
    require(rarity < 5, "cant forge an ultimate weapon");
    return uint8(rarity);
  }

  function participate(uint encounterId, uint weaponTokenId,
    uint sacrificeTokenId1, uint sacrificeTokenId2, uint sacrificeTokenId3, uint sacrificeTokenId4) public whenNotPaused payable {
    require(msg.value >= participateFee);  // half goes to dev, half goes to ether pot

    require(encounterId == block.number / encounterBlockDuration, "a new encounter is available");

    Encounter storage encounter = encountersById[encounterId];

    require(encounter.participantData[msg.sender].damage == 0, "you are already participating");

    uint damage = 1;
    // weaponTokenId of zero means they are using their fists
    if (weaponTokenId != 0) {
      require(tokenContract.ownerOf(weaponTokenId) == msg.sender, "you dont own that weapon");
      damage = weaponTokenIdToDamageForEncounter(weaponTokenId, encounterId);
    }

    uint day = (encounterId * encounterBlockDuration) / blocksInADay;
    uint newScore = dayToAddressToScore[day][msg.sender] + damage;
    dayToAddressToScore[day][msg.sender] = newScore;

    if (newScore > dayToAddressToScore[day][winnerPerDay[day]] &&
      winnerPerDay[day] != msg.sender) {
      winnerPerDay[day] = msg.sender;
    }

    uint cumulativeDamage = damage;
    if (encounter.participants.length > 0) {
      cumulativeDamage = cumulativeDamage + encounter.participantData[encounter.participants[encounter.participants.length-1]].cumulativeDamage;
    }

    if (sacrificeTokenId1 != 0) {

      // the requires in the transfer functions here will verify
      // that msg.sender owns all of these tokens and they are unique

      // burn all four input tokens

      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId1);
      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId2);
      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId3);
      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId4);
    }

    encounter.participantData[msg.sender] = ParticipantData(uint32(damage), uint64(cumulativeDamage), 
      forgeWeaponRarity(sacrificeTokenId1, sacrificeTokenId2, sacrificeTokenId3, sacrificeTokenId4),
      forgeWeaponPureDamage(sacrificeTokenId1, sacrificeTokenId2, sacrificeTokenId3, sacrificeTokenId4),
      false, false);
    encounter.participants.push(msg.sender);

    emit Participating(msg.sender, encounterId);
  }

  function claimLoot(uint encounterId, address player) public whenNotPaused {
    address winnerAddress;
    uint lootTokenId;
    uint consolationPrizeTokenId;
    (winnerAddress, lootTokenId, consolationPrizeTokenId, , ,,) = getEncounterResults(encounterId, player);
    require(winnerAddress == player, "player is not the winner");

    ParticipantData storage participantData = encountersById[encounterId].participantData[player];

    require(!participantData.lootClaimed, "loot already claimed");

    participantData.lootClaimed = true;
    tokenContract.mint(player, lootTokenId);

    // The winner also gets a consolation prize
    // It&#39;s possible he called claimConsolationPrizeLoot first, so allow that

    require(consolationPrizeTokenId != 0, "consolation prize invalid");

    if (!participantData.consolationPrizeClaimed) {
        participantData.consolationPrizeClaimed = true;
        // this will throw if the token already exists
        tokenContract.mint(player, consolationPrizeTokenId);

        // refund gas
        msg.sender.transfer(gasRefundForClaimLootWithConsolationPrize);
    } else {
        
        // refund gas
        msg.sender.transfer(gasRefundForClaimLoot);
    }

    emit LootClaimed(player, encounterId);
  }

  function getConsolationPrizeTokenId(uint encounterId, address player) internal view returns (uint) {

    ParticipantData memory participantData = encountersById[encounterId].participantData[player];
    if (participantData.damage == 0) {
      return 0;
    }

    uint blockToHash = getBlockToHashForResults(encounterId);

    uint rand = uint(keccak256(uint(blockhash(blockToHash)) ^ uint(player)));

    if (participantData.forgeWeaponRarity != 0) {
      return constructWeaponTokenId(rand, participantData.forgeWeaponRarity, participantData.forgeWeaponDamagePure);
    }

    return constructWeaponTokenId(rand, 0, 0);
  }

  function claimConsolationPrizeLoot(uint encounterId, address player) public whenNotPaused {
    uint lootTokenId = getConsolationPrizeTokenId(encounterId, player);
    require(lootTokenId != 0, "player didnt participate");

    ParticipantData storage participantData = encountersById[encounterId].participantData[player];
    require(!participantData.consolationPrizeClaimed, "consolation prize already claimed");

    participantData.consolationPrizeClaimed = true;
    tokenContract.mint(player, lootTokenId);

    msg.sender.transfer(gasRefundForClaimConsolationPrizeLoot);

    emit LootClaimed(player, encounterId);
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return tokenContract.balanceOf(_owner);
  }

  function tokensOf(address _owner) public view returns (uint256[]) {
    return tokenContract.tokensOf(_owner);
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    return tokenContract.tokenOfOwnerByIndex(_owner, _index);
  }
}