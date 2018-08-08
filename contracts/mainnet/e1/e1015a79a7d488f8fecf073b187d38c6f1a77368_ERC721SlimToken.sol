pragma solidity ^0.4.19;

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