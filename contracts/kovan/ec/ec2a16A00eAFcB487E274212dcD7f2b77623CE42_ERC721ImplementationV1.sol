// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract ERC721ImplementationV1 is Initializable, PausableUpgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

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

    // simple counter to keep track of the highest edition number used
    uint256 public highestEditionNumber;

    // total wei been processed through the contract
    uint256 public totalPurchaseValueInWei;

    // number of assets minted of any type
    uint256 public totalNumberMinted;

    // number of assets available of any type
    uint256 public totalNumberAvailable;

    // the account which can receive commission
    address public commissionAccount;

    // Optional commission split can be defined per edition
    mapping(uint256 => CommissionSplit) editionNumberToOptionalCommissionSplit;

    // Simple structure providing an optional commission split per edition purchase
    struct CommissionSplit {
        uint256 rate;
        address recipient;
    }
    //IPFS hash of each token
    mapping(uint256 => string) internal tokenURIs;

    //Access control roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string private _tokenBaseURI;

        // Object for edition details
    struct EditionDetails {
        // Identifiers
        uint256 editionNumber;    // the range e.g. 10000
        bytes32 editionData;      // some data about the edition
        uint256 editionType;      // e.g. 1 = KODA V1, 2 = KOTA, 3 = Bespoke partnership
        // Config
        address creatorAccount;    // creators account
        uint256 creatorCommission; // base creators commission, could be overridden by external contracts
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

    // _creatorAccount : [_editionNumber, _editionNumber]
    mapping(address => uint256[]) internal creatorToEditionNumbers;
    mapping(uint256 => uint256) internal editionNumberToCreatorIndex;

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
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE`, UPGRADER_ROLE to specified addresses.
     *
     */
    function initialize (string memory name, string memory symbol, address 
    _commissionAccount, address _defaultAdmin, address[] memory _minterPauserAddresses, address[] memory _adminAddresses) public initializer  {
        commissionAccount = _commissionAccount;
        _tokenBaseURI = "https://ipfs.infura.io/ipfs/";
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        for (uint256 i = 0; i < _adminAddresses.length; i++) {
            _setupRole(UPGRADER_ROLE, _adminAddresses[i]);
            _setupRole(BURN_ROLE, _adminAddresses[i]);
        }
        for (uint256 i = 0; i < _minterPauserAddresses.length; i++) {
            _setupRole(MINTER_ROLE, _minterPauserAddresses[i]);
            _setupRole(PAUSER_ROLE, _minterPauserAddresses[i]);
        }
        

        
        //Parent initializer call chain
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Pausable_init_unchained();
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init_unchained();
        __AccessControl_init_unchained();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }
        /**
    * @dev Creates an active edition from the given configuration
    * @dev Only callable from minter role addresses
    */
    function createActiveEdition(
        uint256 _editionNumber,
        bytes32 _editionData,
        uint256 _editionType,
        address _creatorAccount,
        uint256 _creatorCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
        uint256 _totalAvailable
    )
    public
    onlyRole(MINTER_ROLE)
    returns (bool)
    {
        return _createEdition(_editionNumber, _editionData, _editionType, _creatorAccount, _creatorCommission, _priceInWei, _tokenURI, _totalAvailable, true);
    }

    /**
    * @dev Creates an inactive edition from the given configuration
    * @dev Only callable from minter role addresses
    */
    function createInactiveEdition(
        uint256 _editionNumber,
        bytes32 _editionData,
        uint256 _editionType,
        address _creatorAccount,
        uint256 _creatorCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
        uint256 _totalAvailable
    )
    public
    onlyRole(MINTER_ROLE)
    returns (bool)
    {
        return _createEdition(_editionNumber, _editionData, _editionType, _creatorAccount, _creatorCommission, _priceInWei, _tokenURI, _totalAvailable, false);
    }

    /**
    * @dev Creates an active edition from the given configuration
    * @dev The concept of pre0minted editions means we can 'undermint' token IDS, good for holding back editions from public sale
    * @dev Only callable from minter role addresses
    */
    function createActivePreMintedEdition(
        uint256 _editionNumber,
        bytes32 _editionData,
        uint256 _editionType,
        address _creatorAccount,
        uint256 _creatorCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
        uint256 _totalSupply,
        uint256 _totalAvailable
    )
    public
    onlyRole(MINTER_ROLE)
    returns (bool)
    {
        _createEdition(_editionNumber, _editionData, _editionType, _creatorAccount, _creatorCommission, _priceInWei, _tokenURI, _totalAvailable, true);
        updateTotalSupply(_editionNumber, _totalSupply);
        return true;
    }

    /**
    * @dev Creates an inactive edition from the given configuration
    * @dev The concept of pre0minted editions means we can 'undermint' token IDS, good for holding back editions from public sale
    * @dev Only callable from minter role addresses
    */
    function createInactivePreMintedEdition(
        uint256 _editionNumber,
        bytes32 _editionData,
        uint256 _editionType,
        address _creatorAccount,
        uint256 _creatorCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
        uint256 _totalSupply,
        uint256 _totalAvailable
    )
    public
    onlyRole(MINTER_ROLE)
    returns (bool)
    {
        _createEdition(_editionNumber, _editionData, _editionType, _creatorAccount, _creatorCommission, _priceInWei, _tokenURI, _totalAvailable, false);
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
        address _creatorAccount,
        uint256 _creatorCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
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
        require((highestEditionNumber + editionNumberToEditionDetails[highestEditionNumber].totalAvailable) < _editionNumber, "Edition number must be greater than previously used plus total available");

        // Prevent missing types
        require(_editionType != 0, "Edition type not provided");

        // Prevent missing token URI
        require(bytes(_tokenURI).length != 0, "Token URI is missing");

        // Prevent empty creators address
        require(_creatorAccount != address(0), "Creator account not provided");

        // Prevent invalid commissions
        require(_creatorCommission <= 100 && _creatorCommission >= 0, "Creator commission cannot be greater than 100 or less than 0");

        // Prevent duplicate editions
        require(editionNumberToEditionDetails[_editionNumber].editionNumber == 0, "Edition already in existence");

        editionNumberToEditionDetails[_editionNumber] = EditionDetails({
        editionNumber : _editionNumber,
        editionData : _editionData,
        editionType : _editionType,
        creatorAccount : _creatorAccount,
        creatorCommission : _creatorCommission,
        priceInWei : _priceInWei,
        tokenURI : _tokenURI,
        totalSupply : 0, // default to all available
        totalAvailable : _totalAvailable,
        active : _active
        });

        // Add to total available count
        totalNumberAvailable += _totalAvailable;

        // Update mappings
        _updateCreatorLookupData(_creatorAccount, _editionNumber);
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

    function _updateCreatorLookupData(address _creatorAccount, uint256 _editionNumber) internal {
        uint256 creatorEditionIndex = creatorToEditionNumbers[_creatorAccount].length;
        creatorToEditionNumbers[_creatorAccount].push(_editionNumber);
        editionNumberToCreatorIndex[_editionNumber] = creatorEditionIndex;
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
    whenNotPaused
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
    returns (uint256) {

        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        require(msg.value >= _editionDetails.priceInWei, "Value must be greater than price of edition");

        // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
        uint256 _tokenId = _nextTokenId(_editionNumber);

        // Create the token
        _mintToken(_to, _tokenId, _editionNumber, _editionDetails.tokenURI);

        // Splice funds and handle commissions
        _handleFunds(_editionNumber, _editionDetails.priceInWei, _editionDetails.creatorAccount, _editionDetails.creatorCommission);

        // Broadcast purchase
        emit Purchase(_tokenId, _editionNumber, _to, msg.value);

        return _tokenId;
    }

    /**
    * @dev Private (minter role only) method for minting editions
    * @dev Payment not needed for this method
    */
    function mint(address _to, uint256 _editionNumber)
    public
    whenNotPaused
    onlyRole(MINTER_ROLE)
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
    * @dev Private (minter role only) method for under minting editions
    * @dev Under minting allows for token IDs to be back filled if total supply is not set to zero by default
    * @dev Payment not needed for this method
    */
    function underMint(address _to, uint256 _editionNumber)
    public
    whenNotPaused
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber)
    returns (uint256) {
        // Under mint token, meaning it takes one from the already sold version
        uint256 _tokenId = _underMintNextTokenId(_editionNumber);

        // If the next tokenId generate is more than the available number, abort as we have reached maximum under mint
        if (_tokenId > (_editionNumber + editionNumberToEditionDetails[_editionNumber].totalAvailable)) {
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
        _editionDetails.totalSupply++;

        // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
        return _editionDetails.editionNumber + _editionDetails.totalSupply;
    }

    function _underMintNextTokenId(uint256 _editionNumber) internal returns (uint256) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

        // For old editions start the counter as edition + 1
        uint256 _tokenId = _editionDetails.editionNumber++;

        // Work your way up until you find a free token based on the new _tokenIdd
        while (_exists(_tokenId)) {
        _tokenId++;
        }

        // Bump number totalSupply if we are now over minting new tokens
        if (_tokenId > (_editionDetails.editionNumber + _editionDetails.totalSupply)) {
        _editionDetails.totalSupply++;
        }

        return _tokenId;
    }

    function _mintToken(address _to, uint256 _tokenId, uint256 _editionNumber, string memory _tokenURI) internal {

        // Mint new base token
        super._mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        // Maintain mapping for tokenId to edition for lookup
        tokenIdToEditionNumber[_tokenId] = _editionNumber;

        // Get next insert position for edition to token Id mapping
        uint256 currentIndexOfTokenId = editionNumberToTokenIds[_editionNumber].length;

        // Maintain mapping of edition to token array for "edition minted tokens"
        editionNumberToTokenIds[_editionNumber].push(_tokenId);

        // Maintain a position index for the tokenId within the edition number mapping array, used for clean up token burn
        editionNumberToTokenIdIndex[_tokenId] = currentIndexOfTokenId;

        // Record sale volume
        totalNumberMinted++;

        // Emit minted event
        emit Minted(_tokenId, _editionNumber, _to);
    }

    function _setTokenURI(uint256 _tokenid, string memory _tokenURI) internal{
        tokenURIs[_tokenid] = _tokenURI;
    }

    function _handleFunds(uint256 _editionNumber, uint256 _priceInWei, address _creatorAccount, uint256 _creatorCommission) internal {

        // Extract the creators commission and send it
        uint256 creatorPayment = (_priceInWei / 100) * _creatorCommission;
        if (creatorPayment > 0) {
        payable(_creatorAccount).transfer(creatorPayment);
        }

        // Load any commission overrides
        CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];

        // Apply optional commission structure
        if (commission.rate > 0) {
        uint256 rateSplit = (_priceInWei / 100) * commission.rate;
        payable(commission.recipient).transfer(rateSplit);
        
        // Send remaining eth to commission account
        uint256 remainingCommission = (msg.value - creatorPayment) - rateSplit;
        payable(commissionAccount).transfer(remainingCommission);
        }

        // Record wei sale value
        totalPurchaseValueInWei += msg.value;
    }

    /**
   * @dev Private (burn role only) method for burning tokens which have been created incorrectly
   */
    function burn(uint256 _tokenId) public onlyRole(BURN_ROLE) whenNotPaused{

        // Clear from parents
        super._burn(_tokenId);

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
    function batchTransfer(address _to, uint256[] memory _tokenIds) public whenNotPaused {
        for (uint i = 0; i < _tokenIds.length; i++) {
        safeTransferFrom(ownerOf(_tokenIds[i]), _to, _tokenIds[i]);
        }
    }

    /**
    * @dev An extension to the default ERC721 behaviour, derived from ERC-875.
    * @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
    */
    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public whenNotPaused {
        for (uint i = 0; i < _tokenIds.length; i++) {
        transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    //////////////////
    // Base Updates //
    //////////////////

    function updateTokenBaseURI(string memory _newBaseURI)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        _tokenBaseURI = _newBaseURI;
    }

    function updateCommissionAccount(address _commissionAccount)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_commissionAccount != address(0), "Invalid address");
        commissionAccount = _commissionAccount;
    }

    /////////////////////
    // Edition Updates //
    /////////////////////

    function updateEditionTokenURI(uint256 _editionNumber, string memory _uri)
    external
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        editionNumberToEditionDetails[_editionNumber].tokenURI = _uri;
    }

    function updatePriceInWei(uint256 _editionNumber, uint256 _priceInWei)
    external
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        editionNumberToEditionDetails[_editionNumber].priceInWei = _priceInWei;
    }

    function updateCreatorCommission(uint256 _editionNumber, uint256 _rate)
    external
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        editionNumberToEditionDetails[_editionNumber].creatorCommission = _rate;
    }

    function updateCreatorsAccount(uint256 _editionNumber, address _creatorAccount)
    external
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {

        EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

        uint256 editionCreatorIndex = editionNumberToCreatorIndex[_editionNumber];

        // Get list of editions old creator works with
        uint256[] storage editionNumbersForCreator = creatorToEditionNumbers[_originalEditionDetails.creatorAccount];

        // Remove edition from creators lists
        delete editionNumbersForCreator[editionCreatorIndex];

        // Add new creators to the list
        uint256 newCreatorsEditionIndex = creatorToEditionNumbers[_creatorAccount].length;
        creatorToEditionNumbers[_creatorAccount].push(_editionNumber);
        editionNumberToCreatorIndex[_editionNumber] = newCreatorsEditionIndex;

        // Update the edition
        _originalEditionDetails.creatorAccount = _creatorAccount;
    }

    function updateEditionType(uint256 _editionNumber, uint256 _editionType)
    external
    onlyRole(MINTER_ROLE)
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
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        editionNumberToEditionDetails[_editionNumber].active = _active;
    }

    function updateTotalSupply(uint256 _editionNumber, uint256 _totalSupply)
    public
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        require(tokensOfEdition(_editionNumber).length <= _totalSupply, "Can not lower totalSupply to below the number of tokens already in existence");
        editionNumberToEditionDetails[_editionNumber].totalSupply = _totalSupply;
    }

    function updateTotalAvailable(uint256 _editionNumber, uint256 _totalAvailable)
    external
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

        require(_editionDetails.totalSupply <= _totalAvailable, "Unable to reduce available amount to the below the number totalSupply");

        uint256 originalAvailability = _editionDetails.totalAvailable;
        _editionDetails.totalAvailable = _totalAvailable;
        totalNumberAvailable = (totalNumberAvailable - originalAvailability) + _totalAvailable;
    }

    function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient)
    external
    onlyRole(MINTER_ROLE)
    onlyRealEdition(_editionNumber) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        uint256 _creatorCommission = _editionDetails.creatorCommission;

        if (_rate > 0) {
        require(_recipient != address(0), "Setting a rate must be accompanied by a valid address");
        }
        require((_creatorCommission + _rate) <= 100, "Cant set commission greater than 100%");

        editionNumberToOptionalCommissionSplit[_editionNumber] = CommissionSplit({rate : _rate, recipient : _recipient});
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
    function editionsOfType(uint256 _type) public view returns (uint256[] memory _editionNumbers) {
        return editionTypeToEditionNumber[_type];
    }

    /**
    * @dev Lookup all editions for the given creator account
    * @dev Returns empty list if not valid
    */
    function creatorsEditions(address _creatorsAccount) public view returns (uint256[] memory _editionNumbers) {
        return creatorToEditionNumbers[_creatorsAccount];
    }

    /**
    * @dev Lookup all tokens minted for the given edition number
    * @dev Returns array of token IDs, any zero edition ids can be ignore/stripped
    */
    function tokensOfEdition(uint256 _editionNumber) public view returns (uint256[] memory _tokenIds) {
        return editionNumberToTokenIds[_editionNumber];
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
        address _creatorAccount,
        uint256 _creatorCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
        uint256 _totalSupply,
        uint256 _totalAvailable,
        bool _active
    ) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[editionNumber];
        return (
        _editionDetails.editionData,
        _editionDetails.editionType,
        _editionDetails.creatorAccount,
        _editionDetails.creatorCommission,
        _editionDetails.priceInWei,
        concat(_tokenBaseURI, _editionDetails.tokenURI),
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
        string memory _tokenURI,
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

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return concat(_tokenBaseURI, tokenURIs[_tokenId]);
    }

    function tokenURISafe(uint256 _tokenId) public view onlyValidTokenId(_tokenId) returns (string memory ) {
        return concat(_tokenBaseURI, tokenURIs[_tokenId]);
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

    function creatorCommission(uint256 _editionNumber) public view returns (address _creatorAccount, uint256 _creatorCommission) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return (
        _editionDetails.creatorAccount,
        _editionDetails.creatorCommission
        );
    }

    function priceInWeiEdition(uint256 _editionNumber) public view returns (uint256 _priceInWei) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return _editionDetails.priceInWei;
    }

    function tokenURIEdition(uint256 _editionNumber) public view returns (string memory) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return concat(_tokenBaseURI, _editionDetails.tokenURI);
    }

    function editionActive(uint256 _editionNumber) public view returns (bool) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return _editionDetails.active;
    }

    function totalRemaining(uint256 _editionNumber) public view returns (uint256) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return _editionDetails.totalAvailable - _editionDetails.totalSupply;
    }

    function totalAvailableEdition(uint256 _editionNumber) public view returns (uint256) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return _editionDetails.totalAvailable;
    }

    function totalSupplyEdition(uint256 _editionNumber) public view returns (uint256) {
        EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
        return _editionDetails.totalSupply;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public onlyRole(PAUSER_ROLE){
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused(){
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public  override whenNotPaused() {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override whenNotPaused() {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    //Required override of _authorizeUpgrade from UUPSUpgradeable.sol
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {}

    //String concatination method
    function concat(string memory a, string memory b) internal pure returns(string memory){
        return string(abi.encodePacked(a, b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId
            || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}