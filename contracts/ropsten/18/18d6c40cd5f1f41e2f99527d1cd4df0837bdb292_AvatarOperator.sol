pragma solidity ^0.4.24;

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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets
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

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountTokenIds(address _owner,uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]); 
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);
}


/**
 * @title BitGuildAccessAdmin
 * @dev Allow two roles: &#39;owner&#39; or &#39;operator&#39;
 *      - owner: admin/superuser (e.g. with financial rights)
 *      - operator: can update configurations
 */
contract BitGuildAccessAdmin {
  address public owner;
  address[] public operators;

  uint public MAX_OPS = 20; // Default maximum number of operators allowed

  mapping(address => bool) public isOperator;

  event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
  );
  event OperatorAdded(address operator);
  event OperatorRemoved(address operator);

  // @dev The BitGuildAccessAdmin constructor: sets owner to the sender account
  constructor() public {
    owner = msg.sender;
  }

  // @dev Throws if called by any account other than the owner.
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // @dev Throws if called by any non-operator account. Owner has all ops rights.
  modifier onlyOperator {
    require(
      isOperator[msg.sender] || msg.sender == owner,
      "Permission denied. Must be an operator or the owner.");
    _;
  }

  /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(
      _newOwner != address(0),
      "Invalid new owner address."
    );
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  /**
    * @dev Allows the current owner or operators to add operators
    * @param _newOperator New operator address
    */
  function addOperator(address _newOperator) public onlyOwner {
    require(
      _newOperator != address(0),
      "Invalid new operator address."
    );

    // Make sure no dups
    require(
      !isOperator[_newOperator],
      "New operator exists."
    );

    // Only allow so many ops
    require(
      operators.length < MAX_OPS,
      "Overflow."
    );

    operators.push(_newOperator);
    isOperator[_newOperator] = true;

    emit OperatorAdded(_newOperator);
  }

  /**
    * @dev Allows the current owner or operators to remove operator
    * @param _operator Address of the operator to be removed
    */
  function removeOperator(address _operator) public onlyOwner {
    // Make sure operators array is not empty
    require(
      operators.length > 0,
      "No operator."
    );

    // Make sure the operator exists
    require(
      isOperator[_operator],
      "Not an operator."
    );

    // Manual array manipulation:
    // - replace the _operator with last operator in array
    // - remove the last item from array
    address lastOperator = operators[operators.length - 1];
    for (uint i = 0; i < operators.length; i++) {
      if (operators[i] == _operator) {
        operators[i] = lastOperator;
      }
    }
    operators.length -= 1; // remove the last element

    isOperator[_operator] = false;
    emit OperatorRemoved(_operator);
  }

  // @dev Remove ALL operators
  function removeAllOps() public onlyOwner {
    for (uint i = 0; i < operators.length; i++) {
      isOperator[operators[i]] = false;
    }
    operators.length = 0;
  } 

}

contract AvatarOperator is BitGuildAccessAdmin {

  // every user can own avatar count
  uint8 public PER_USER_MAX_AVATAR_COUNT = 1;

  event AvatarCreateSuccess(address indexed _owner, uint256 tokenId);

  AvatarService internal avatarService;
  address internal avatarAddress;

  modifier nameValid(string _name){
    bytes memory nameBytes = bytes(_name);
    require(nameBytes.length > 0);
    require(nameBytes.length < 16);
    for(uint8 i = 0; i < nameBytes.length; ++i) {
      uint8 asc = uint8(nameBytes[i]);
      require (
        asc == 95 || (asc >= 48 && asc <= 57) || (asc >= 65 && asc <= 90) || (asc >= 97 && asc <= 122), "Invalid name"); 
    }
    _;
  }

  function setMaxAvatarNumber(uint8 _maxNumber) external onlyOwner {
    PER_USER_MAX_AVATAR_COUNT = _maxNumber;
  }

  function injectAvatarService(address _addr) external onlyOwner {
    avatarService = AvatarService(_addr);
    avatarAddress = _addr;
  }
  
  function updateAvatarInfo(uint256 _tokenId, string _name, uint256 _dna) external nameValid(_name){
    avatarService.updateAvatarInfo(msg.sender, _tokenId, _name, _dna);
  }

  function createAvatar(string _name, uint256 _dna) external nameValid(_name) returns (uint256 _tokenId){
    require(ERC721(avatarAddress).balanceOf(msg.sender) < PER_USER_MAX_AVATAR_COUNT);
    _tokenId = avatarService.createAvatar(msg.sender, _name, _dna);
    emit AvatarCreateSuccess(msg.sender, _tokenId);
  }

  function getMountTokenIds(uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]){
    return avatarService.getMountTokenIds(msg.sender, _tokenId, _avatarItemAddress);
  }

  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna) {
    return avatarService.getAvatarInfo(_tokenId);
  }

  function getOwnedTokenIds() external view returns(uint256[] _tokenIds) {
    return avatarService.getOwnedTokenIds(msg.sender);
  }
  
}