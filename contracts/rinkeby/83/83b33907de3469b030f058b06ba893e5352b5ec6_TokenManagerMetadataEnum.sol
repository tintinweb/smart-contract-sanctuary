/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.8.4;


// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    // Recently mutability changed from pure to view
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

//pragma solidity ^0.4.20; // original pragma
/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external /*payable*/;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external /*payable*/;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
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

contract CheckerERC165 is ERC165 {
  mapping (bytes4 => bool) internal supportedInterfaces;

  constructor() {
    supportedInterfaces[this.supportsInterface.selector] = true;
  }

  /*  interfaceID : the XOR of all function selectors in the interface
  supportsInterface uses less than 30k gas
  */
  function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

//pragma solidity ^0.8.0; // original pragma
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//Path from root dir of the project
contract TokenManager is ERC721, CheckerERC165{
  using SafeMath for uint256;

  // The address of the contract creator
  address internal creator; // = GOD

  // The highest valid tokenId, for checking if a tokenId is valid
  uint256 internal maxId;

  // A mapping storing the balance of each address. i.e. how much objects someone has registered.
  mapping(address => uint256) internal balances;

  // A mapping of burnt tokens, for checking if a tokenId is valid
  mapping(uint256 => bool) internal burned;

  // A mapping of token owners
  mapping(uint256 => address) internal owners;

  // A mapping of the "approved" address for each token
  mapping (uint256 => address) internal allowance;

  // A nested mapping for managing "operators". Authorize sb to control all the token of another address.
  mapping (address => mapping (address => bool)) internal authorised;

  constructor() CheckerERC165(){
    creator = msg.sender;
    maxId = 0x0;

    supportedInterfaces[
      this.balanceOf.selector ^
      this.ownerOf.selector ^
      bytes4(keccak256("safeTransferFrom(address,address,uint256"))^
      bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes"))^
      this.transferFrom.selector ^
      this.approve.selector ^
      this.setApprovalForAll.selector ^
      this.getApproved.selector ^
      this.isApprovedForAll.selector
    ] = true;
  }

  function isValidToken(uint256 _tokenId) internal view returns(bool){
    return _tokenId != 0 && _tokenId <= maxId && !burned[_tokenId];
  }

  //external car pa utilisé dans TokenManager
  function balanceOf(address _owner) external view override returns (uint256){
    return balances[_owner];
  }

  //public : because used inside this contract
  function ownerOf(uint256 _tokenId) public view override returns (address){
    require(isValidToken(_tokenId));
    return owners[_tokenId];
  }

  /*
  Mint a token
  Associate metadata to it (Comming feature)
  Marked as virtual because enumerable override this function.
  */
  function mintToken() external virtual{
    //increment the number of token owned by the caller of mintToken
    balances[msg.sender] = balances[msg.sender].add(1);

    //The tokenId of the token currently being created is maxId after this operation. i.e. first token ID is 1
    maxId = maxId.add(1);

    //Set the ownership
    owners[maxId] = msg.sender;

    //Signal that a token has been created
    emit Transfer(address(0), msg.sender, maxId);
  }

  /*
  Burn - Destroy a token. It will no longer be attached to his metadata, and not transferable anymore.
  Marked as virtual because enumerable override this function.
  */
  function burnToken(uint256 _tokenId) external virtual {
    address owner = ownerOf(_tokenId);
    require(owner == msg.sender || allowance[_tokenId] == msg.sender
        || authorised[owner][msg.sender]);

    //Burning the tokens
    burned[_tokenId] = true;
    balances[owner]--;

    emit Transfer(owner, address(0), _tokenId);
  }

  /*
  Set authorised address for the sender.
  */
  function setApprovalForAll(address _operator, bool _approved) external override {
    emit ApprovalForAll(msg.sender, _operator, _approved);
    authorised[msg.sender][_operator] = _approved;
  }

  /*
  get the list of operator addresses having access to all tokens of the sender.
  */
  function isApprovedForAll(address _owner, address _operator) external view override returns (bool){
    return authorised[_owner][_operator];
  }

  /*
  Set authorisation for one token from the approved address of the sender. Only one person can be approved for a token at a time.
  */
  function approve(address _approved, uint256 _tokenId) external override {
    //Check for rights
    address owner = ownerOf(_tokenId);
    require(msg.sender == owner || authorised[owner][msg.sender]);

    //Approve the token access to _approved address
    emit Approval(owner, _approved, _tokenId);
    allowance[_tokenId] = _approved;
  }

  /*
  return if an address is approved / has the ownership of a token
  */
  function getApproved(uint256 _tokenId) external view override returns (address){
    require(isValidToken(_tokenId));
    return allowance[_tokenId];
  }

  /*
  Changed to not payable because the commission is taken from the amount transfered from the buyer to the owner.
  public because will be reused in this contract
  Marked as virtual because enumerable override this function.
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
    address owner = ownerOf(_tokenId);

    //Check requirements
    require(msg.sender == owner || msg.sender == allowance[_tokenId] || authorised[owner][msg.sender]);//implicitly check that token is valid
    require(_from == owner);
    require(_to != address(0));

    //Do the transferring
    emit Transfer(_from, _to, _tokenId);
    owners[_tokenId] = _to;
    balances[owner]--;
    balances[_to]++;
    if(allowance[_tokenId] != address(0)){
      delete allowance[_tokenId];
    }
  }

  /*
  Same comments as transferFrom for public and not payable.
  Check if _to is a valid ERC721 receiver contract.
  HERE added "calldata" to data location
  */
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
    transferFrom(_from, _to, _tokenId);

    //???
    uint32 size;
    assembly {
      size := extcodesize(_to)
    }

    if(size > 0){//if _to is a contract, not an externally owner address
      ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);//where was declared this method ???
      require(receiver.onERC721Received(msg.sender, _from, _tokenId, data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
    }
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

}

contract TokenManagerEnumerable is TokenManager, ERC721Enumerable {
  using SafeMath for uint256;
  uint[] internal tokenIndexes; // The list of all tokens created
  mapping(uint => uint) internal indexTokens;//From an index (in tokenIndexes array) gives the tokenID associated. i.e. it is tokenIndexes reversed access
  mapping(address => uint[]) internal ownerTokenIndexes;// Gives from an address the list of all the tokenId owned by it.
  mapping(uint => uint) internal tokenTokenIndexes;//From a tokenId, it gives the index of that token within the list of the owner's tokens.

  constructor() TokenManager(){
    supportedInterfaces[
        this.totalSupply.selector ^
        this.tokenByIndex.selector ^
        this.tokenOfOwnerByIndex.selector
    ] = true;
  }

  function totalSupply() external view override returns (uint256){
    return tokenIndexes.length;
  }

  function tokenByIndex(uint256 _index) external view override returns (uint256){
    require(_index < tokenIndexes.length);
    return tokenIndexes[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256){
    require(_index < balances[_owner]);
    return ownerTokenIndexes[_owner][_index];
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public override {
    address owner = ownerOf(_tokenId);

    //Check requirements
    require(msg.sender == owner || msg.sender == allowance[_tokenId] || authorised[owner][msg.sender]);//implicitly check that token is valid
    require(_from == owner);
    require(_to != address(0));

    //Do the transferring
    emit Transfer(_from, _to, _tokenId);
    owners[_tokenId] = _to;
    balances[owner]--;
    balances[_to]++;
    if(allowance[_tokenId] != address(0)){
      delete allowance[_tokenId];
    }

    //================Enumerable================
    //removing token in _from tokens list
    uint fromTokenIndex = tokenTokenIndexes[_tokenId];
    uint fromBalance = balances[_from];//Already decreased by one previously
    if(fromTokenIndex != fromBalance){//we have to do more than just decreasing the array length
      uint256 fromLastTokenId = ownerTokenIndexes[_from][fromBalance];
      ownerTokenIndexes[_from][fromTokenIndex] = fromLastTokenId;//If errors, Look here, the second index

      //update the index of the token we just moved within the list of _from's tokens
      tokenTokenIndexes[fromLastTokenId] = fromTokenIndex;
    }

    ownerTokenIndexes[_from].pop();

    //Add the token to _to list of token
    ownerTokenIndexes[_to].push(_tokenId);

    //update tokenTokenIndexes[_tokenId], to the new index of the tokenId within the list of tokens of _to
    tokenTokenIndexes[_tokenId] = balances[_to] - 1;
  }

  function burnToken(uint256 _tokenId) public override{
    address owner = ownerOf(_tokenId);
    require(owner == msg.sender || allowance[_tokenId] == msg.sender
        || authorised[owner][msg.sender]);

    //Burning the tokens
    burned[_tokenId] = true;
    balances[owner]--;
    emit Transfer(owner, address(0), _tokenId);

    //=====Enumerable=====
    uint fromTokenIndex = tokenTokenIndexes[_tokenId];
    uint fromBalance = balances[owner];//Already decreased by one previously
    if(fromTokenIndex != fromBalance){//we have to do more than just decreasing the array length
      uint256 fromLastTokenId = ownerTokenIndexes[owner][fromBalance];
      ownerTokenIndexes[owner][fromTokenIndex] = fromLastTokenId;//If errors, Look here, the second index

      //update the index of the token we just moved within the list of owner's tokens
      tokenTokenIndexes[fromLastTokenId] = fromTokenIndex;
    }

    ownerTokenIndexes[owner].pop();
    delete tokenTokenIndexes[_tokenId];

    //Dealing with tokenIndexes
    uint oldIndex = indexTokens[_tokenId];
    uint totalTokenCount = tokenIndexes.length;
    if(oldIndex != totalTokenCount - 1){
      tokenIndexes[oldIndex] = tokenIndexes[totalTokenCount-1];
    }
    tokenIndexes.pop();
  }

  //Function passed from 90k gas to 180k gas by adding the enumerable extension
  function mintToken() public override{
    //increment the number of token owned by the caller of mintToken
    balances[msg.sender] = balances[msg.sender].add(1);
    //The tokenId of the token currently being created is maxId after this operation. i.e. first token ID is 1
    maxId = maxId.add(1);
    //Set the ownership
    owners[maxId] = msg.sender;
    //Signal that a token has been created
    emit Transfer(address(0), msg.sender, maxId);

    //=====Enumerable=====
    tokenIndexes.push(maxId);
    indexTokens[maxId] = tokenIndexes.length-1;
    ownerTokenIndexes[msg.sender].push(maxId);
    tokenTokenIndexes[maxId] = ownerTokenIndexes[msg.sender].length-1;

  }

}

contract TokenManagerMetadataEnum is TokenManagerEnumerable, ERC721Metadata{
  string private __name;
  string private __symbol;
  bytes private __uriBase;//nexchange = neighbor exchange = next exchange = next change

  constructor(string memory _name, string memory _symbol, string memory _uriBase) public TokenManagerEnumerable(){
    __name = _name;
    __symbol = _symbol;
    __uriBase = bytes(_uriBase);

    //Add to ERC165 Interface Check
    //This is to notify that this contract implements ERC721Metadata
    supportedInterfaces[
      this.name.selector ^
      this.symbol.selector ^
      this.tokenURI.selector
    ] = true;//[0x5b5e139f]
  }

  function name() external view override returns (string memory _name){
    _name = __name;
  }

  function symbol() external view override returns (string memory _symbol){
    _symbol = __symbol;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory){
    require(isValidToken(_tokenId));

    //prepare our tokenId's byte array
    uint maxLength = 78;//length of uint256
    bytes memory reversed = new bytes(maxLength);
    uint i = 0;

    //loop through and add byte values to the array
    while (_tokenId != 0) {
        uint remainder = _tokenId % 10;
        _tokenId /= 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }

    //prepare the final array
    bytes memory s = new bytes(__uriBase.length + i);
    uint j;

    //concatenate
    //add the base to the final array
    for (j = 0; j < __uriBase.length; j++) {
        s[j] = __uriBase[j];
    }
    //add the tokenId to the final array
    for (j = 0; j < i; j++) {
        s[j + __uriBase.length] = reversed[i - 1 - j];
    }

    return string(s);
  }
}