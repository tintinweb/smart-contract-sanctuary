pragma solidity ^0.4.23;


/**
 * @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
 */
contract ERC721 {
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

  function implementsERC721() public pure returns (bool);
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function approve(address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}


/**
 * @title Interface of auction contract
 */
interface CurioAuction {
  function isCurioAuction() external returns (bool);
  function withdrawBalance() external;
  function setAuctionPriceLimit(uint256 _newAuctionPriceLimit) external;
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
    external;
}


/**
 * @title Curio
 * @dev Curio core contract implements ERC721 token.
 */
contract Curio is ERC721 {
  event Create(
    address indexed owner,
    uint256 indexed tokenId,
    string name
  );
  event ContractUpgrade(address newContract);

  struct Token {
    string name;
  }

  // Name and symbol of ERC721 token
  string public constant NAME = "Curio";
  string public constant SYMBOL = "CUR";

  // Array of token&#39;s data
  Token[] tokens;

  // A mapping from token IDs to the address that owns them
  mapping (uint256 => address) public tokenIndexToOwner;

  // A mapping from owner address to count of tokens that address owns
  mapping (address => uint256) ownershipTokenCount;

  // A mapping from token IDs to an address that has been approved
  mapping (uint256 => address) public tokenIndexToApproved;

  address public ownerAddress;
  address public adminAddress;

  bool public paused = false;

  // The address of new contract when this contract was upgraded
  address public newContractAddress;

  // The address of CurioAuction contract that handles sales of tokens
  CurioAuction public auction;

  // Restriction on release of tokens
  uint256 public constant TOTAL_SUPPLY_LIMIT = 900;

  // Count of released tokens
  uint256 public releaseCreatedCount;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == ownerAddress);
    _;
  }

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(msg.sender == adminAddress);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner or admin.
   */
  modifier onlyOwnerOrAdmin() {
    require(
      msg.sender == adminAddress ||
      msg.sender == ownerAddress
    );
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev Constructor function
   */
  constructor() public {
    // Contract paused after start
    paused = true;

    // Set owner and admin addresses
    ownerAddress = msg.sender;
    adminAddress = msg.sender;
  }


  // -----------------------------------------
  // External interface
  // -----------------------------------------


  /**
   * @dev Check implementing ERC721 standard (needed in auction contract).
   */
  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /**
   * @dev Default payable function rejects all Ether from being sent here, unless it&#39;s from auction contract.
   */
  function() external payable {
    require(msg.sender == address(auction));
  }

  /**
   * @dev Transfer all Ether from this contract to owner.
   */
  function withdrawBalance() external onlyOwner {
    ownerAddress.transfer(address(this).balance);
  }

  /**
   * @dev Returns the total number of tokens currently in existence.
   */
  function totalSupply() public view returns (uint) {
    return tokens.length;
  }

  /**
   * @dev Returns the number of tokens owned by a specific address.
   * @param _owner The owner address to check
   */
  function balanceOf(address _owner) public view returns (uint256 count) {
    return ownershipTokenCount[_owner];
  }

  /**
   * @dev Returns the address currently assigned ownership of a given token.
   * @param _tokenId The ID of the token
   */
  function ownerOf(uint256 _tokenId) external view returns (address owner) {
    owner = tokenIndexToOwner[_tokenId];

    require(owner != address(0));
  }

  /**
   * @dev Returns information about token.
   * @param _id The ID of the token
   */
  function getToken(uint256 _id) external view returns (string name) {
    Token storage token = tokens[_id];

    name = token.name;
  }

  /**
   * @dev Set new owner address. Only available to the current owner.
   * @param _newOwner The address of the new owner
   */
  function setOwner(address _newOwner) onlyOwner external {
    require(_newOwner != address(0));

    ownerAddress = _newOwner;
  }

  /**
   * @dev Set new admin address. Only available to owner.
   * @param _newAdmin The address of the new admin
   */
  function setAdmin(address _newAdmin) onlyOwner external {
    require(_newAdmin != address(0));

    adminAddress = _newAdmin;
  }

  /**
   * @dev Set new auction price limit.
   * @param _newAuctionPriceLimit Start and end price limit
   */
  function setAuctionPriceLimit(uint256 _newAuctionPriceLimit) onlyOwnerOrAdmin external {
    auction.setAuctionPriceLimit(_newAuctionPriceLimit);
  }

  /**
   * @dev Set the address of upgraded contract.
   * @param _newContract Address of new contract
   */
  function setNewAddress(address _newContract) onlyOwner whenPaused external {
    newContractAddress = _newContract;

    emit ContractUpgrade(_newContract);
  }

  /**
   * @dev Pause the contract. Called by owner or admin to pause the contract.
   */
  function pause() onlyOwnerOrAdmin whenNotPaused external {
    paused = true;
  }

  /**
   * @dev Unpause the contract. Can only be called by owner, since
   *      one reason we may pause the contract is when admin account is
   *      compromised. Requires auction contract addresses
   *      to be set before contract can be unpaused. Also, we can&#39;t have
   *      newContractAddress set either, because then the contract was upgraded.
   */
  function unpause() onlyOwner whenPaused public {
    require(auction != address(0));
    require(newContractAddress == address(0));

    paused = false;
  }

  /**
   * @dev Transfer a token to another address.
   * @param _to The address of the recipient, can be a user or contract
   * @param _tokenId The ID of the token to transfer
   */
  function transfer(
    address _to,
    uint256 _tokenId
  )
    whenNotPaused
    external
  {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_to != address(0));

    // Disallow transfers to this contract to prevent accidental misuse.
    // The contract should never own any tokens (except very briefly
    // after a release token is created and before it goes on auction).
    require(_to != address(this));

    // Disallow transfers to the auction contract to prevent accidental
    // misuse. Auction contracts should only take ownership of tokens
    // through the allow + transferFrom flow.
    require(_to != address(auction));

    // Check token ownership
    require(_owns(msg.sender, _tokenId));

    // Reassign ownership, clear pending approvals, emit Transfer event.
    _transfer(msg.sender, _to, _tokenId);
  }

  /**
   * @dev Grant another address the right to transfer a specific token via
   *      transferFrom(). This is the preferred flow for transfering NFTs to contracts.
   * @param _to The address to be granted transfer approval. Pass address(0) to
   *            clear all approvals
   * @param _tokenId The ID of the token that can be transferred if this call succeeds
   */
  function approve(
    address _to,
    uint256 _tokenId
  )
    whenNotPaused
    external
  {
    // Only an owner can grant transfer approval.
    require(_owns(msg.sender, _tokenId));

    // Register the approval (replacing any previous approval).
    _approve(_tokenId, _to);

    // Emit approval event.
    emit Approval(msg.sender, _to, _tokenId);
  }

  /**
   * @dev Transfers a token owned by another address, for which the calling address
   *      has previously been granted transfer approval by the owner.
   * @param _from The address that owns the token to be transferred
   * @param _to The address that should take ownership of the token. Can be any address,
   *            including the caller
   * @param _tokenId The ID of the token to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    whenNotPaused
    external
  {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_to != address(0));

    // Disallow transfers to this contract to prevent accidental misuse.
    // The contract should never own any tokens (except very briefly
    // after a release token is created and before it goes on auction).
    require(_to != address(this));

    // Check for approval and valid ownership
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));

    // Reassign ownership (also clears pending approvals and emits Transfer event).
    _transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Returns a list of all tokens assigned to an address.
   * @param _owner The owner whose tokens we are interested in
   * @notice This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
   *         expensive (it walks the entire token array looking for tokens belonging to owner),
   *         but it also returns a dynamic array, which is only supported for web3 calls, and
   *         not contract-to-contract calls.
   */
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;

      for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
        if (tokenIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }

      return result;
    }
  }

  /**
   * @dev Set the reference to the auction contract.
   * @param _address Address of auction contract
   */
  function setAuctionAddress(address _address) onlyOwner external {
    CurioAuction candidateContract = CurioAuction(_address);

    require(candidateContract.isCurioAuction());

    // Set the new contract address
    auction = candidateContract;
  }

  /**
   * @dev Put a token up for auction.
   * @param _tokenId ID of token to auction, sender must be owner
   * @param _startingPrice Price of item (in wei) at beginning of auction
   * @param _endingPrice Price of item (in wei) at end of auction
   * @param _duration Length of auction (in seconds)
   */
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    whenNotPaused
    external
  {
    // Auction contract checks input sizes
    // If token is already on any auction, this will throw because it will be owned by the auction contract
    require(_owns(msg.sender, _tokenId));

    // Set auction contract as approved for token
    _approve(_tokenId, auction);

    // Sale auction throws if inputs are invalid
    auction.createAuction(
      _tokenId,
      _startingPrice,
      _endingPrice,
      _duration,
      msg.sender
    );
  }

  /**
   * @dev Transfers the balance of the auction contract to this contract by owner or admin.
   */
  function withdrawAuctionBalance() onlyOwnerOrAdmin external {
    auction.withdrawBalance();
  }

  /**
   * @dev Creates a new release token with the given name and creates an auction for it.
   * @param _name Name ot the token
   * @param _startingPrice Price of item (in wei) at beginning of auction
   * @param _endingPrice Price of item (in wei) at end of auction
   * @param _duration Length of auction (in seconds)
   */
  function createReleaseTokenAuction(
    string _name,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    onlyAdmin
    external
  {
    // Check release tokens limit
    require(releaseCreatedCount < TOTAL_SUPPLY_LIMIT);

    // Create token and tranfer ownership to this contract
    uint256 tokenId = _createToken(_name, address(this));

    // Set auction address as approved for release token
    _approve(tokenId, auction);

    // Call createAuction in auction contract
    auction.createAuction(
      tokenId,
      _startingPrice,
      _endingPrice,
      _duration,
      address(this)
    );

    releaseCreatedCount++;
  }

  /**
   * @dev Creates free token and transfer it to recipient.
   * @param _name Name of the token
   * @param _to The address of the recipient, can be a user or contract
   */
  function createFreeToken(
    string _name,
    address _to
  )
    onlyAdmin
    external
  {
    require(_to != address(0));
    require(_to != address(this));
    require(_to != address(auction));

    // Check release tokens limit
    require(releaseCreatedCount < TOTAL_SUPPLY_LIMIT);

    // Create token and transfer to owner
    _createToken(_name, _to);

    releaseCreatedCount++;
  }


  // -----------------------------------------
  // Internal interface
  // -----------------------------------------


  /**
   * @dev Create a new token and stores it.
   * @param _name Token name
   * @param _owner The initial owner of this token, must be non-zero
   */
  function _createToken(
    string _name,
    address _owner
  )
    internal
    returns (uint)
  {
    Token memory _token = Token({
      name: _name
    });

    uint256 newTokenId = tokens.push(_token) - 1;

    // Check overflow newTokenId
    require(newTokenId == uint256(uint32(newTokenId)));

    emit Create(_owner, newTokenId, _name);

    // This will assign ownership
    _transfer(0, _owner, newTokenId);

    return newTokenId;
  }

  /**
   * @dev Check claimant address as token owner.
   * @param _claimant The address we are validating against
   * @param _tokenId Token id, only valid when > 0
   */
  function _owns(
    address _claimant,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    return tokenIndexToOwner[_tokenId] == _claimant;
  }

  /**
   * @dev Check if a given address currently has transferApproval for a particular token.
   * @param _claimant The address we are confirming token is approved for
   * @param _tokenId Token id, only valid when > 0
   */
  function _approvedFor(
    address _claimant,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    return tokenIndexToApproved[_tokenId] == _claimant;
  }

  /**
   * @dev Marks an address as being approved for transferFrom().
   *      Setting _approved to address(0) clears all transfer approval.
   *      NOTE: _approve() does NOT send the Approval event. This is intentional because
   *      _approve() and transferFrom() are used together for putting tokens on auction, and
   *      there is no value in spamming the log with Approval events in that case.
   */
  function _approve(
    uint256 _tokenId,
    address _approved
  )
    internal
  {
    tokenIndexToApproved[_tokenId] = _approved;
  }

  /**
   * @dev Assigns ownership of a specific token to an address.
   */
  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
  {
    ownershipTokenCount[_to]++;

    // Transfer ownership
    tokenIndexToOwner[_tokenId] = _to;

    // When creating new token _from is 0x0, but we can&#39;t account that address
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;

      // Clear any previously approved ownership exchange
      delete tokenIndexToApproved[_tokenId];
    }

    emit Transfer(_from, _to, _tokenId);
  }
}