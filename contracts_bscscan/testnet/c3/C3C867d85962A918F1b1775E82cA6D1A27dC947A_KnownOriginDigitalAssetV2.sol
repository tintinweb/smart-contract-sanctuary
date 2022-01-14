pragma solidity ^0.4.24;

// allows for multi-address access controls to different functions
import "./AccessControl.sol";

// Prevents stuck ether
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";

// For safe maths operations
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

// Pause purchasing only in case of emergency/migration
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

// ERC721
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

// Utils only
import "./Strings.sol";

/**
* @title KnownOriginDigitalAsset - V2
*
* http://www.knownorigin.io/
*
* ERC721 compliant digital assets for real-world artwork.
*
* Base NFT Issuance Contract
*
* BE ORIGINAL. BUY ORIGINAL.
*
*/
contract KnownOriginDigitalAssetV2 is
ERC721Token,
AccessControl,
HasNoEther,
Pausable
{
  using SafeMath for uint256;

  ////////////
  // Events //
  ////////////

  // Emitted on purchases from within this contract
  event Purchase(
    uint256 indexed _tokenId,
    uint256 indexed _editionNumber,
    address indexed _buyer,
    uint256 _priceInWei
  );

  // Emitted on every mint
  event Minted(
    uint256 indexed _tokenId,
    uint256 indexed _editionNumber,
    address indexed _buyer
  );

  // Emitted on every edition created
  event EditionCreated(
    uint256 indexed _editionNumber,
    bytes32 indexed _editionData,
    uint256 indexed _editionType
  );

  ////////////////
  // Properties //
  ////////////////

  uint256 constant internal MAX_UINT32 = ~uint32(0);

  string public tokenBaseURI = "https://ipfs.infura.io/ipfs/";

  // simple counter to keep track of the highest edition number used
  uint256 public highestEditionNumber;

  // total wei been processed through the contract
  uint256 public totalPurchaseValueInWei;

  // number of assets minted of any type
  uint256 public totalNumberMinted;

  // number of assets available of any type
  uint256 public totalNumberAvailable;

  // the KO account which can receive commission
  address public koCommissionAccount;

  // Optional commission split can be defined per edition
  mapping(uint256 => CommissionSplit) editionNumberToOptionalCommissionSplit;

  // Simple structure providing an optional commission split per edition purchase
  struct CommissionSplit {
    uint256 rate;
    address recipient;
  }

  // Object for edition details
  struct EditionDetails {
    // Identifiers
    uint256 editionNumber;    // the range e.g. 10000
    bytes32 editionData;      // some data about the edition
    uint256 editionType;      // e.g. 1 = KODA V1, 2 = KOTA, 3 = Bespoke partnership
    // Config
    uint256 startDate;        // date when the edition goes on sale
    uint256 endDate;          // date when the edition is available until
    address artistAccount;    // artists account
    uint256 artistCommission; // base artists commission, could be overridden by external contracts
    uint256 priceInWei;       // base price for edition, could be overridden by external contracts
    string tokenURI;          // IPFS hash - see base URI
    bool active;              // Root control - on/off for the edition
    // Counters
    uint256 totalSupply;      // Total purchases or mints
    uint256 totalAvailable;   // Total number available to be purchased
  }

  // _editionNumber : EditionDetails
  mapping(uint256 => EditionDetails) internal editionNumberToEditionDetails;

  // _tokenId : _editionNumber
  mapping(uint256 => uint256) internal tokenIdToEditionNumber;

  // _editionNumber : [_tokenId, _tokenId]
  mapping(uint256 => uint256[]) internal editionNumberToTokenIds;
  mapping(uint256 => uint256) internal editionNumberToTokenIdIndex;

  // _artistAccount : [_editionNumber, _editionNumber]
  mapping(address => uint256[]) internal artistToEditionNumbers;
  mapping(uint256 => uint256) internal editionNumberToArtistIndex;

  // _editionType : [_editionNumber, _editionNumber]
  mapping(uint256 => uint256[]) internal editionTypeToEditionNumber;
  mapping(uint256 => uint256) internal editionNumberToTypeIndex;

  ///////////////
  // Modifiers // 
  ///////////////

  modifier onlyAvailableEdition(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].totalSupply < editionNumberToEditionDetails[_editionNumber].totalAvailable, "No more editions left to purchase");
    _;
  }

  modifier onlyActiveEdition(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].active, "Edition not active");
    _;
  }

  modifier onlyRealEdition(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].editionNumber > 0, "Edition number invalid");
    _;
  }

  modifier onlyValidTokenId(uint256 _tokenId) {
    require(exists(_tokenId), "Token ID does not exist");
    _;
  }

  modifier onlyPurchaseDuringWindow(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].startDate <= block.timestamp, "Edition not available yet");
    require(editionNumberToEditionDetails[_editionNumber].endDate >= block.timestamp, "Edition no longer available");
    _;
  }

  /*
   * Constructor
   */
  constructor () public payable ERC721Token("CryptoArtToken", "CART") {
    // set commission account to contract creator
    koCommissionAccount = msg.sender;
  }

  /**
   * @dev Creates an active edition from the given configuration
   * @dev Only callable from KO staff/addresses
   */
  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    return _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, true);
  }

  /**
   * @dev Creates an inactive edition from the given configuration
   * @dev Only callable from KO staff/addresses
   */
  function createInactiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    return _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, false);
  }

  /**
   * @dev Creates an active edition from the given configuration
   * @dev The concept of pre0minted editions means we can 'undermint' token IDS, good for holding back editions from public sale
   * @dev Only callable from KO staff/addresses
   */
  function createActivePreMintedEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, true);
    updateTotalSupply(_editionNumber, _totalSupply);
    return true;
  }

  /**
   * @dev Creates an inactive edition from the given configuration
   * @dev The concept of pre0minted editions means we can 'undermint' token IDS, good for holding back editions from public sale
   * @dev Only callable from KO staff/addresses
   */
  function createInactivePreMintedEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, false);
    updateTotalSupply(_editionNumber, _totalSupply);
    return true;
  }

  /**
   * @dev Internal factory method for building editions
   */
  function _createEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalAvailable,
    bool _active
  )
  internal
  returns (bool)
  {
    // Prevent missing edition number
    require(_editionNumber != 0, "Edition number not provided");

    // Prevent edition number lower than last one used
    require(_editionNumber > highestEditionNumber, "Edition number must be greater than previously used");

    // Check previously edition plus total available is less than new edition number
    require(highestEditionNumber.add(editionNumberToEditionDetails[highestEditionNumber].totalAvailable) < _editionNumber, "Edition number must be greater than previously used plus total available");

    // Prevent missing types
    require(_editionType != 0, "Edition type not provided");

    // Prevent missing token URI
    require(bytes(_tokenURI).length != 0, "Token URI is missing");

    // Prevent empty artists address
    require(_artistAccount != address(0), "Artist account not provided");

    // Prevent invalid commissions
    require(_artistCommission <= 100 && _artistCommission >= 0, "Artist commission cannot be greater than 100 or less than 0");

    // Prevent duplicate editions
    require(editionNumberToEditionDetails[_editionNumber].editionNumber == 0, "Edition already in existence");

    // Default end date to max uint256
    uint256 endDate = _endDate;
    if (_endDate == 0) {
      endDate = MAX_UINT32;
    }

    editionNumberToEditionDetails[_editionNumber] = EditionDetails({
      editionNumber : _editionNumber,
      editionData : _editionData,
      editionType : _editionType,
      startDate : _startDate,
      endDate : endDate,
      artistAccount : _artistAccount,
      artistCommission : _artistCommission,
      priceInWei : _priceInWei,
      tokenURI : _tokenURI,
      totalSupply : 0, // default to all available
      totalAvailable : _totalAvailable,
      active : _active
      });

    // Add to total available count
    totalNumberAvailable = totalNumberAvailable.add(_totalAvailable);

    // Update mappings
    _updateArtistLookupData(_artistAccount, _editionNumber);
    _updateEditionTypeLookupData(_editionType, _editionNumber);

    emit EditionCreated(_editionNumber, _editionData, _editionType);

    // Update the edition pointer if needs be
    highestEditionNumber = _editionNumber;

    return true;
  }

  function _updateEditionTypeLookupData(uint256 _editionType, uint256 _editionNumber) internal {
    uint256 typeEditionIndex = editionTypeToEditionNumber[_editionType].length;
    editionTypeToEditionNumber[_editionType].push(_editionNumber);
    editionNumberToTypeIndex[_editionNumber] = typeEditionIndex;
  }

  function _updateArtistLookupData(address _artistAccount, uint256 _editionNumber) internal {
    uint256 artistEditionIndex = artistToEditionNumbers[_artistAccount].length;
    artistToEditionNumbers[_artistAccount].push(_editionNumber);
    editionNumberToArtistIndex[_editionNumber] = artistEditionIndex;
  }

  /**
   * @dev Public entry point for purchasing an edition
   * @dev Reverts if edition is invalid
   * @dev Reverts if payment not provided in full
   * @dev Reverts if edition is sold out
   * @dev Reverts if edition is not active or available
   */
  function purchase(uint256 _editionNumber)
  public
  payable
  returns (uint256) {
    return purchaseTo(msg.sender, _editionNumber);
  }

  /**
   * @dev Public entry point for purchasing an edition on behalf of someone else
   * @dev Reverts if edition is invalid
   * @dev Reverts if payment not provided in full
   * @dev Reverts if edition is sold out
   * @dev Reverts if edition is not active or available
   */
  function purchaseTo(address _to, uint256 _editionNumber)
  public
  payable
  whenNotPaused
  onlyRealEdition(_editionNumber)
  onlyActiveEdition(_editionNumber)
  onlyAvailableEdition(_editionNumber)
  onlyPurchaseDuringWindow(_editionNumber)
  returns (uint256) {

    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    require(msg.value >= _editionDetails.priceInWei, "Value must be greater than price of edition");

    // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
    uint256 _tokenId = _nextTokenId(_editionNumber);

    // Create the token
    _mintToken(_to, _tokenId, _editionNumber, _editionDetails.tokenURI);

    // Splice funds and handle commissions
    _handleFunds(_editionNumber, _editionDetails.priceInWei, _editionDetails.artistAccount, _editionDetails.artistCommission);

    // Broadcast purchase
    emit Purchase(_tokenId, _editionNumber, _to, msg.value);

    return _tokenId;
  }

  /**
   * @dev Private (KO only) method for minting editions
   * @dev Payment not needed for this method
   */
  function mint(address _to, uint256 _editionNumber)
  public
  onlyIfMinter
  onlyRealEdition(_editionNumber)
  onlyAvailableEdition(_editionNumber)
  returns (uint256) {
    // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
    uint256 _tokenId = _nextTokenId(_editionNumber);

    // Create the token
    _mintToken(_to, _tokenId, _editionNumber, editionNumberToEditionDetails[_editionNumber].tokenURI);

    // Create the token
    return _tokenId;
  }

  /**
   * @dev Private (KO only) method for under minting editions
   * @dev Under minting allows for token IDs to be back filled if total supply is not set to zero by default
   * @dev Payment not needed for this method
   */
  function underMint(address _to, uint256 _editionNumber)
  public
  onlyIfUnderMinter
  onlyRealEdition(_editionNumber)
  returns (uint256) {
    // Under mint token, meaning it takes one from the already sold version
    uint256 _tokenId = _underMintNextTokenId(_editionNumber);

    // If the next tokenId generate is more than the available number, abort as we have reached maximum under mint
    if (_tokenId > _editionNumber.add(editionNumberToEditionDetails[_editionNumber].totalAvailable)) {
      revert("Reached max tokenId, cannot under mint anymore");
    }

    // Create the token
    _mintToken(_to, _tokenId, _editionNumber, editionNumberToEditionDetails[_editionNumber].tokenURI);

    // Create the token
    return _tokenId;
  }

  function _nextTokenId(uint256 _editionNumber) internal returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    // Bump number totalSupply
    _editionDetails.totalSupply = _editionDetails.totalSupply.add(1);

    // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
    return _editionDetails.editionNumber.add(_editionDetails.totalSupply);
  }

  function _underMintNextTokenId(uint256 _editionNumber) internal returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    // For old editions start the counter as edition + 1
    uint256 _tokenId = _editionDetails.editionNumber.add(1);

    // Work your way up until you find a free token based on the new _tokenIdd
    while (exists(_tokenId)) {
      _tokenId = _tokenId.add(1);
    }

    // Bump number totalSupply if we are now over minting new tokens
    if (_tokenId > _editionDetails.editionNumber.add(_editionDetails.totalSupply)) {
      _editionDetails.totalSupply = _editionDetails.totalSupply.add(1);
    }

    return _tokenId;
  }

  function _mintToken(address _to, uint256 _tokenId, uint256 _editionNumber, string _tokenURI) internal {

    // Mint new base token
    super._mint(_to, _tokenId);
    super._setTokenURI(_tokenId, _tokenURI);

    // Maintain mapping for tokenId to edition for lookup
    tokenIdToEditionNumber[_tokenId] = _editionNumber;

    // Get next insert position for edition to token Id mapping
    uint256 currentIndexOfTokenId = editionNumberToTokenIds[_editionNumber].length;

    // Maintain mapping of edition to token array for "edition minted tokens"
    editionNumberToTokenIds[_editionNumber].push(_tokenId);

    // Maintain a position index for the tokenId within the edition number mapping array, used for clean up token burn
    editionNumberToTokenIdIndex[_tokenId] = currentIndexOfTokenId;

    // Record sale volume
    totalNumberMinted = totalNumberMinted.add(1);

    // Emit minted event
    emit Minted(_tokenId, _editionNumber, _to);
  }

  function _handleFunds(uint256 _editionNumber, uint256 _priceInWei, address _artistAccount, uint256 _artistCommission) internal {

    // Extract the artists commission and send it
    uint256 artistPayment = _priceInWei.div(100).mul(_artistCommission);
    if (artistPayment > 0) {
      _artistAccount.transfer(artistPayment);
    }

    // Load any commission overrides
    CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];

    // Apply optional commission structure
    if (commission.rate > 0) {
      uint256 rateSplit = _priceInWei.div(100).mul(commission.rate);
      commission.recipient.transfer(rateSplit);
    }

    // Send remaining eth to KO
    uint256 remainingCommission = msg.value.sub(artistPayment).sub(rateSplit);
    koCommissionAccount.transfer(remainingCommission);

    // Record wei sale value
    totalPurchaseValueInWei = totalPurchaseValueInWei.add(msg.value);
  }

  /**
   * @dev Private (KO only) method for burning tokens which have been created incorrectly
   */
  function burn(uint256 _tokenId) public onlyIfKnownOrigin {

    // Clear from parents
    super._burn(ownerOf(_tokenId), _tokenId);

    // Get hold of the edition for cleanup
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];

    // Delete token ID mapping
    delete tokenIdToEditionNumber[_tokenId];

    // Delete tokens associated to the edition - this will leave a gap in the array of zero
    uint256[] storage tokenIdsForEdition = editionNumberToTokenIds[_editionNumber];
    uint256 editionTokenIdIndex = editionNumberToTokenIdIndex[_tokenId];
    delete tokenIdsForEdition[editionTokenIdIndex];
  }

  /**
   * @dev An extension to the default ERC721 behaviour, derived from ERC-875.
   * @dev Allowing for batch transfers from the sender, will fail if from does not own all the tokens
   */
  function batchTransfer(address _to, uint256[] _tokenIds) public {
    for (uint i = 0; i < _tokenIds.length; i++) {
      safeTransferFrom(ownerOf(_tokenIds[i]), _to, _tokenIds[i]);
    }
  }

  /**
   * @dev An extension to the default ERC721 behaviour, derived from ERC-875.
   * @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
   */
  function batchTransferFrom(address _from, address _to, uint256[] _tokenIds) public {
    for (uint i = 0; i < _tokenIds.length; i++) {
      transferFrom(_from, _to, _tokenIds[i]);
    }
  }

  //////////////////
  // Base Updates //
  //////////////////

  function updateTokenBaseURI(string _newBaseURI)
  external
  onlyIfKnownOrigin {
    require(bytes(_newBaseURI).length != 0, "Base URI invalid");
    tokenBaseURI = _newBaseURI;
  }

  function updateKoCommissionAccount(address _koCommissionAccount)
  external
  onlyIfKnownOrigin {
    require(_koCommissionAccount != address(0), "Invalid address");
    koCommissionAccount = _koCommissionAccount;
  }

  /////////////////////
  // Edition Updates //
  /////////////////////

  function updateEditionTokenURI(uint256 _editionNumber, string _uri)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].tokenURI = _uri;
  }

  function updatePriceInWei(uint256 _editionNumber, uint256 _priceInWei)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].priceInWei = _priceInWei;
  }

  function updateArtistCommission(uint256 _editionNumber, uint256 _rate)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].artistCommission = _rate;
  }

  function updateArtistsAccount(uint256 _editionNumber, address _artistAccount)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {

    EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

    uint256 editionArtistIndex = editionNumberToArtistIndex[_editionNumber];

    // Get list of editions old artist works with
    uint256[] storage editionNumbersForArtist = artistToEditionNumbers[_originalEditionDetails.artistAccount];

    // Remove edition from artists lists
    delete editionNumbersForArtist[editionArtistIndex];

    // Add new artists to the list
    uint256 newArtistsEditionIndex = artistToEditionNumbers[_artistAccount].length;
    artistToEditionNumbers[_artistAccount].push(_editionNumber);
    editionNumberToArtistIndex[_editionNumber] = newArtistsEditionIndex;

    // Update the edition
    _originalEditionDetails.artistAccount = _artistAccount;
  }

  function updateEditionType(uint256 _editionNumber, uint256 _editionType)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {

    EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

    // Get list of editions for old type
    uint256[] storage editionNumbersForType = editionTypeToEditionNumber[_originalEditionDetails.editionType];

    // Remove edition from old type list
    uint256 editionTypeIndex = editionNumberToTypeIndex[_editionNumber];
    delete editionNumbersForType[editionTypeIndex];

    // Add new type to the list
    uint256 newTypeEditionIndex = editionTypeToEditionNumber[_editionType].length;
    editionTypeToEditionNumber[_editionType].push(_editionNumber);
    editionNumberToTypeIndex[_editionNumber] = newTypeEditionIndex;

    // Update the edition
    _originalEditionDetails.editionType = _editionType;
  }

  function updateActive(uint256 _editionNumber, bool _active)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].active = _active;
  }

  function updateTotalSupply(uint256 _editionNumber, uint256 _totalSupply)
  public
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    require(tokensOfEdition(_editionNumber).length <= _totalSupply, "Can not lower totalSupply to below the number of tokens already in existence");
    editionNumberToEditionDetails[_editionNumber].totalSupply = _totalSupply;
  }

  function updateTotalAvailable(uint256 _editionNumber, uint256 _totalAvailable)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    require(_editionDetails.totalSupply <= _totalAvailable, "Unable to reduce available amount to the below the number totalSupply");

    uint256 originalAvailability = _editionDetails.totalAvailable;
    _editionDetails.totalAvailable = _totalAvailable;
    totalNumberAvailable = totalNumberAvailable.sub(originalAvailability).add(_totalAvailable);
  }

  function updateStartDate(uint256 _editionNumber, uint256 _startDate)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].startDate = _startDate;
  }

  function updateEndDate(uint256 _editionNumber, uint256 _endDate)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].endDate = _endDate;
  }

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    uint256 artistCommission = _editionDetails.artistCommission;

    if (_rate > 0) {
      require(_recipient != address(0), "Setting a rate must be accompanied by a valid address");
    }
    require(artistCommission.add(_rate) <= 100, "Cant set commission greater than 100%");

    editionNumberToOptionalCommissionSplit[_editionNumber] = CommissionSplit({rate : _rate, recipient : _recipient});
  }

  ///////////////////
  // Token Updates //
  ///////////////////

  function setTokenURI(uint256 _tokenId, string _uri)
  external
  onlyIfKnownOrigin
  onlyValidTokenId(_tokenId) {
    _setTokenURI(_tokenId, _uri);
  }

  ///////////////////
  // Query Methods //
  ///////////////////

  /**
   * @dev Lookup the edition of the provided token ID
   * @dev Returns 0 if not valid
   */
  function editionOfTokenId(uint256 _tokenId) public view returns (uint256 _editionNumber) {
    return tokenIdToEditionNumber[_tokenId];
  }

  /**
   * @dev Lookup all editions added for the given edition type
   * @dev Returns array of edition numbers, any zero edition ids can be ignore/stripped
   */
  function editionsOfType(uint256 _type) public view returns (uint256[] _editionNumbers) {
    return editionTypeToEditionNumber[_type];
  }

  /**
   * @dev Lookup all editions for the given artist account
   * @dev Returns empty list if not valid
   */
  function artistsEditions(address _artistsAccount) public view returns (uint256[] _editionNumbers) {
    return artistToEditionNumbers[_artistsAccount];
  }

  /**
   * @dev Lookup all tokens minted for the given edition number
   * @dev Returns array of token IDs, any zero edition ids can be ignore/stripped
   */
  function tokensOfEdition(uint256 _editionNumber) public view returns (uint256[] _tokenIds) {
    return editionNumberToTokenIds[_editionNumber];
  }

  /**
   * @dev Lookup all owned tokens for the provided address
   * @dev Returns array of token IDs
   */
  function tokensOf(address _owner) public view returns (uint256[] _tokenIds) {
    return ownedTokens[_owner];
  }

  /**
   * @dev Checks to see if the edition exists, assumes edition of zero is invalid
   */
  function editionExists(uint256 _editionNumber) public view returns (bool) {
    if (_editionNumber == 0) {
      return false;
    }
    EditionDetails storage editionNumber = editionNumberToEditionDetails[_editionNumber];
    return editionNumber.editionNumber == _editionNumber;
  }

  /**
   * @dev Lookup any optional commission split set for the edition
   * @dev Both values will be zero if not present
   */
  function editionOptionalCommission(uint256 _editionNumber) public view returns (uint256 _rate, address _recipient) {
    CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];
    return (commission.rate, commission.recipient);
  }

  /**
   * @dev Main entry point for looking up edition config/metadata
   * @dev Reverts if invalid edition number provided
   */
  function detailsOfEdition(uint256 editionNumber)
  public view
  onlyRealEdition(editionNumber)
  returns (
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable,
    bool _active
  ) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[editionNumber];
    return (
    _editionDetails.editionData,
    _editionDetails.editionType,
    _editionDetails.startDate,
    _editionDetails.endDate,
    _editionDetails.artistAccount,
    _editionDetails.artistCommission,
    _editionDetails.priceInWei,
    Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI),
    _editionDetails.totalSupply,
    _editionDetails.totalAvailable,
    _editionDetails.active
    );
  }

  /**
   * @dev Lookup a tokens common identifying characteristics
   * @dev Reverts if invalid token ID provided
   */
  function tokenData(uint256 _tokenId)
  public view
  onlyValidTokenId(_tokenId)
  returns (
    uint256 _editionNumber,
    uint256 _editionType,
    bytes32 _editionData,
    string _tokenURI,
    address _owner
  ) {
    uint256 editionNumber = tokenIdToEditionNumber[_tokenId];
    EditionDetails storage editionDetails = editionNumberToEditionDetails[editionNumber];
    return (
    editionNumber,
    editionDetails.editionType,
    editionDetails.editionData,
    tokenURI(_tokenId),
    ownerOf(_tokenId)
    );
  }

  function tokenURI(uint256 _tokenId) public view onlyValidTokenId(_tokenId) returns (string) {
    return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
  }

  function tokenURISafe(uint256 _tokenId) public view returns (string) {
    return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
  }

  function purchaseDatesToken(uint256 _tokenId) public view returns (uint256 _startDate, uint256 _endDate) {
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];
    return purchaseDatesEdition(_editionNumber);
  }

  function priceInWeiToken(uint256 _tokenId) public view returns (uint256 _priceInWei) {
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];
    return priceInWeiEdition(_editionNumber);
  }

  //////////////////////////
  // Edition config query //
  //////////////////////////

  function editionData(uint256 _editionNumber) public view returns (bytes32) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.editionData;
  }

  function editionType(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.editionType;
  }

  function purchaseDatesEdition(uint256 _editionNumber) public view returns (uint256 _startDate, uint256 _endDate) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return (
    _editionDetails.startDate,
    _editionDetails.endDate
    );
  }

  function artistCommission(uint256 _editionNumber) public view returns (address _artistAccount, uint256 _artistCommission) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return (
    _editionDetails.artistAccount,
    _editionDetails.artistCommission
    );
  }

  function priceInWeiEdition(uint256 _editionNumber) public view returns (uint256 _priceInWei) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.priceInWei;
  }

  function tokenURIEdition(uint256 _editionNumber) public view returns (string) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI);
  }

  function editionActive(uint256 _editionNumber) public view returns (bool) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.active;
  }

  function totalRemaining(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalAvailable.sub(_editionDetails.totalSupply);
  }

  function totalAvailableEdition(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalAvailable;
  }

  function totalSupplyEdition(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalSupply;
  }

}

pragma solidity ^0.4.19;

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

  function strConcat(string _a, string _b) internal pure returns (string) {
    return strConcat(_a, _b, "", "", "");
  }
}

pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/access/rbac/Roles.sol";

/**
 * @title Based on OpenZeppelin Whitelist & RBCA contracts
 * @dev The AccessControl contract provides different access for addresses, and provides basic authorization control functions.
 */
contract AccessControl {

  using Roles for Roles.Role;

  uint8 public constant ROLE_KNOWN_ORIGIN = 1;
  uint8 public constant ROLE_MINTER = 2;
  uint8 public constant ROLE_UNDER_MINTER = 3;

  event RoleAdded(address indexed operator, uint8 role);
  event RoleRemoved(address indexed operator, uint8 role);

  address public owner;

  mapping(uint8 => Roles.Role) private roles;

  modifier onlyIfKnownOrigin() {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_KNOWN_ORIGIN));
    _;
  }

  modifier onlyIfMinter() {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_KNOWN_ORIGIN) || hasRole(msg.sender, ROLE_MINTER));
    _;
  }

  modifier onlyIfUnderMinter() {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_KNOWN_ORIGIN) || hasRole(msg.sender, ROLE_UNDER_MINTER));
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  ////////////////////////////////////
  // Whitelist/RBCA Derived Methods //
  ////////////////////////////////////

  function addAddressToAccessControl(address _operator, uint8 _role)
  public
  onlyIfKnownOrigin
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  function removeAddressFromAccessControl(address _operator, uint8 _role)
  public
  onlyIfKnownOrigin
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  function checkRole(address _operator, uint8 _role)
  public
  view
  {
    roles[_role].check(_operator);
  }

  function hasRole(address _operator, uint8 _role)
  public
  view
  returns (bool)
  {
    return roles[_role].has(_operator);
  }

}

pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC721BasicToken.sol";
import "../../introspection/SupportsInterfaceWithLookup.sol";


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    ownedTokens[_from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

pragma solidity ^0.4.24;


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

pragma solidity ^0.4.24;

import "./ERC721Basic.sol";
import "./ERC721Receiver.sol";
import "../../math/SafeMath.sol";
import "../../AddressUtils.sol";
import "../../introspection/SupportsInterfaceWithLookup.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

pragma solidity ^0.4.24;

import "../../introspection/ERC165.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

pragma solidity ^0.4.24;

import "./ERC721Basic.sol";


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

pragma solidity ^0.4.24;


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

pragma solidity ^0.4.24;

import "./Ownable.sol";


/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

pragma solidity ^0.4.24;


import "../ownership/Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


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
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.24;

import "./ERC165.sol";


/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

pragma solidity ^0.4.24;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

pragma solidity ^0.4.24;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}