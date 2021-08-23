pragma solidity ^0.4.24;

// allows for multi-address access controls to different functions
import "./AccessControl.sol";

// Prevents stuck ether
import "./HasNoEther.sol";

// For safe maths operations
import "./SafeMath.sol";

// Pause purchasing only in case of emergency/migration
import "./Pausable.sol";

// ERC721
import "./ERC721Token.sol";

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