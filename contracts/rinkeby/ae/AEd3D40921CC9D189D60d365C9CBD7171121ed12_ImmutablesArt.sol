// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

// Contract is not audited.
// Use authorized deployments of this contract at your own risk.

/*
██╗███╗   ███╗███╗   ███╗██╗   ██╗████████╗ █████╗ ██████╗ ██╗     ███████╗███████╗    █████╗ ██████╗ ████████╗
██║████╗ ████║████╗ ████║██║   ██║╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝   ██╔══██╗██╔══██╗╚══██╔══╝
██║██╔████╔██║██╔████╔██║██║   ██║   ██║   ███████║██████╔╝██║     █████╗  ███████╗   ███████║██████╔╝   ██║
██║██║╚██╔╝██║██║╚██╔╝██║██║   ██║   ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║   ██╔══██║██╔══██╗   ██║
██║██║ ╚═╝ ██║██║ ╚═╝ ██║╚██████╔╝   ██║   ██║  ██║██████╔╝███████╗███████╗███████║██╗██║  ██║██║  ██║   ██║
╚═╝╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
*/

pragma solidity ^0.8.9;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Clones.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./ImmutablesArtRoyaltyManager.sol";

/// @author Gutenblock.eth
/// @title ImmutablesAdmin
contract ImmutablesAdmin is Ownable, ReentrancyGuard {
  using Address for address payable;

  /// @dev Address of a third party curator.
  address public curator;
  /// @dev basis point (1/10,000th) share of third party curator on payout.
  uint16 public curatorPercent;

  /// @dev Address of a third party beneficiary.
  address public beneficiary;
  /// @dev basis point (1/10,000th) share of third party beneficiary on payout.
  uint16 public beneficiaryPercent;

  /// @dev Teammember administration mapping
  mapping(address => bool) public isTeammember;

  /// @dev MODIFIERS

  modifier onlyTeammember() {
      require(isTeammember[msg.sender], "team");
      _;
  }

  /// @dev EVENTS

  event AdminModifiedTeammembers(
    address indexed user,
    bool isTeammember
  );

  /** @dev Allows the contract owner to add a teammember.
    * @param _address of teammember to add.
    */
  function contractOwnerAddTeammember(address _address) external onlyOwner() {
      isTeammember[_address] = true;
      emit AdminModifiedTeammembers(_address, true);
  }

  /** @dev Allows the contract owner to remove a teammember.
    * @param _address of teammember to remove.
    */
  function contractOwnerRemoveTeammember(address _address) external onlyOwner() {
      isTeammember[_address] = false;
      emit AdminModifiedTeammembers(_address, false);
  }

  /// @dev FINANCIAL

  /** @dev Allows the contract owner to set a curator address and percentage.
    * @dev Force payout of any curator that was previously set
    * @dev so that funds paid with a curator set are paid out as promised.
    * @param _newCurator address of a curator teammember.
    * @param _newPercent the basis point (1/10,000th) share of contract revenue for the curator.
    */
  function contractOwnerUpdateCuratorAddressAndPercent(address _newCurator, uint16 _newPercent) external onlyOwner() nonReentrant() {
    // checks
    require(_newPercent <= (10000-beneficiaryPercent));

    // effects
    uint256 _startingBalance = address(this).balance;
    uint256 _curatorValue = _startingBalance * curatorPercent / 10000;
    uint256 _beneficiaryValue = _startingBalance * beneficiaryPercent / 10000;
    uint256 _contractValue = _startingBalance - _curatorValue - _beneficiaryValue;

    address oldCurator = curator;
    isTeammember[curator] = false;
    emit AdminModifiedTeammembers(curator, false);
    curator = _newCurator;
    isTeammember[_newCurator] = true;
    emit AdminModifiedTeammembers(_newCurator, true);
    curatorPercent = _newPercent;

    // interactions
    payable(this.owner()).sendValue(_contractValue);
    payable(oldCurator).sendValue(_curatorValue);
    payable(beneficiary).sendValue(_beneficiaryValue);
  }

  /** @dev Allows the contract owner to set a beneficiary address and percentage.
    * @dev Force payout of any beneficiary that was previously set
    * @dev so that funds paid with a beneficiary set are paid out as promised.
    * @param _newBeneficiary address of a beneficiary.
    * @param _newPercent the basis point (1/10,000th) share of contract revenue for the beneficiary.
    */
  function contractOwnerUpdateBeneficiaryAddressAndPercent(address _newBeneficiary, uint16 _newPercent) external onlyOwner() nonReentrant() {
    // checks
    require(_newPercent <= (10000-curatorPercent));

    // effects
    uint256 _startingBalance = address(this).balance;
    uint256 _curatorValue = _startingBalance * curatorPercent / 10000;
    uint256 _beneficiaryValue = _startingBalance * beneficiaryPercent / 10000;
    uint256 _contractValue = _startingBalance - _curatorValue - _beneficiaryValue;
    address oldBeneficiary = beneficiary;
    beneficiary = _newBeneficiary;
    beneficiaryPercent = _newPercent;

    // interactions
    payable(this.owner()).sendValue(_contractValue);
    payable(curator).sendValue(_curatorValue);
    payable(oldBeneficiary).sendValue(_beneficiaryValue);
  }

  /** @dev Allows the withdraw of funds.
    * @dev Everyone is paid and the contract balance is zeroed out.
    */
  function withdraw() external nonReentrant() {
    // checks
    // effects
    uint256 _startingBalance = address(this).balance;
    uint256 _curatorValue = _startingBalance * curatorPercent / 10000;
    uint256 _beneficiaryValue = _startingBalance * beneficiaryPercent / 10000;
    uint256 _contractValue = _startingBalance - _curatorValue - _beneficiaryValue;

    // interactions
    payable(this.owner()).sendValue(_contractValue);
    payable(curator).sendValue(_curatorValue);
    payable(beneficiary).sendValue(_beneficiaryValue);
  }
}

/// @author Gutenblock.eth
/// @title ImmutablesAdminProject
contract ImmutablesAdminProject is ImmutablesAdmin {
  /// @dev The fee paid to the contract to create a project.
  uint256 public projectFee;
  /// @dev The last projectId created.
  uint256 public currentProjectId;
  /// @dev Featured project.
  uint256 public featuredProjectId;

  /// @dev basis point (1/10,000th) share the artist receives of each sale.
  uint16 public artistPercent;
  /// @dev whether or not artists need to be pre-screened.
  bool public artistScreeningEnabled = false;

  /// @dev Template Cloneable Royalty Manager Contract
  ImmutablesArtRoyaltyManager public implementation;

  struct Project {
    // Name of the project and the corresponding Immutables.co page name.
    string name;
    // Name of the artist.
    string artist;
    // Project description.
    string description;

    // Current highest minted edition number.
    uint256 currentEditionId;
    // Maximum number of editions that can be minted.
    uint256 maxEditions;

    // The maximum number of editions to display at once in the grid view.
    // For works that are easier to generate many may be shown at once.
    // For more processor intensive works the artist may want to limit the
    // number on screen at any given time to reduce lag.
    uint8 maxGridDimension;

    // The Immutables.co Post transaction hash containing the generative art
    // script to run.
    string scriptTransactionHash;
    // The type of script that is referenced in the transaction hash.
    // Used to tell Grid what type of Cell to use for the script.
    string scriptType;

    // A category that can be assigned by a Teammember for curation.
    string category;

    // Whether the project is Active and available for third parties to view.
    bool active;
    // Whether the project minting is paused to the public.
    bool paused;
    // Whether or not the main project attributes are locked from editing.
    bool locked;
  }

  /// @dev Mappings between the page string and tokenId.
  mapping(uint256 => Project) public projects;

  /// @dev Mappings between the projectId, Price, and Artist Payees
  mapping(uint256 => address) public projectIdToArtistAddress;
  mapping(uint256 => uint256) public projectIdToPricePerEditionInWei;
  mapping(uint256 => address) public projectIdToAdditionalPayee;
  mapping(uint256 => uint16) public projectIdToAdditionalPayeePercent;

  /// @dev Allow for a per-project royalty address
  mapping(uint256 => address) public projectIdToRoyaltyAddress;

  /// @dev EIP2981 royaltyInfo basis point (1/10,000th) share of secondary
  ///      sales (for all projects).
  uint16 public secondaryRoyaltyPercent;

  /// @dev A mapping from a project to a base URL like a IPFS CAR file CID
  ///     (e.g., that can be obtained from from nft.storage)
  mapping(uint256 => string) public projectIdToImageURLBase;
  /// @dev The file extension for the individual items in the CAR file
  ///      (e.g., ".png")
  mapping(uint256 => string) public projectIdToImageURLExt;
  /// @dev Whether to use the Image URL in the Grid View instead of live render.
  mapping(uint256 => bool) public projectIdUseImageURLInGridView;

  /// @dev Mapping of artists authorized to use the platform
  ///      if artist screening is enabled.
  mapping(address => bool) public isAuthorizedArtist;

  /// @dev MODIFIERS

  modifier onlyUnlocked(uint256 _projectId) {
      require(!projects[_projectId].locked, "locked");
      _;
  }

  modifier onlyArtist(uint256 _projectId) {
    require(msg.sender == projectIdToArtistAddress[_projectId], "artist");
    _;
  }

  modifier onlyArtistOrTeammember(uint256 _projectId) {
      require(isTeammember[msg.sender] || msg.sender == projectIdToArtistAddress[_projectId], "artistTeam");
      _;
  }

  modifier onlyAuthorizedArtist() {
    if(artistScreeningEnabled) {
      require(isAuthorizedArtist[msg.sender], "auth");
    }
    _;
  }

  /// @dev EVENTS

  event AddressCreatedProject(
    address indexed artist,
    uint256 indexed projectId,
    string projectName
  );

  event AdminUpdatedAuthorizedArtist(
    address indexed user,
    bool isAuthorizedArtist
  );

  event AdminUpdatedProjectCategory(
      uint256 indexed projectId,
      string category
  );

  event CreatedImmutablesArtRoyaltyManagerForProjectId(
      address indexed royaltyManager,
      uint256 indexed projectId
  );

  /// @dev CONSTRUCTOR

  constructor() {
    implementation = new ImmutablesArtRoyaltyManager();
    implementation.initialize(address(this), 1, address(this), artistPercent, address(0), 0);
  }

  /** @dev Allows the teammember to add an artist.
    * @param _address of artist to add
    */
  function teamAddAuthorizedArtist(address _address) external onlyTeammember() {
      isAuthorizedArtist[_address] = true;
      emit AdminUpdatedAuthorizedArtist(_address, true);
  }

  /** @dev Allows the teammember to remove an artist.
    * @param _address of artist to remove
    */
  function teamRemoveAuthorizedArtist(address _address) external onlyTeammember() {
      isAuthorizedArtist[_address] = false;
      emit AdminUpdatedAuthorizedArtist(_address, false);
  }

  /** @dev Allows the teammember to set a featured project id
    * @param _projectId of featured project
    */
  function teamUpdateFeaturedProject(uint256 _projectId) external onlyTeammember() {
    require(_projectId <= currentProjectId);
    featuredProjectId = _projectId;
  }

  /** @dev Allows the contract owner to update the project fee.
    * @param _newProjectFee The new project fee in Wei.
    */
  function contractOwnerUpdateProjectFee(uint256 _newProjectFee) external onlyOwner() {
    projectFee = _newProjectFee;
  }

  /** @dev Allows the contract owner to update the artist cut of sales.
    * @param _percent The new artist percentage
    */
  function contractOwnerUpdateArtistPercent(uint16 _percent) external onlyOwner() {
    require(_percent >= 5000, ">=5000");   // minimum amount an artist should get 50.00%
    require(_percent <= 10000, "<=10000"); // maximum amount artists should get 100.00%
    artistPercent = _percent;
  }

  /** @dev Allows the contract owner to unlock a project.
    * @param _projectId of the project to unlock
    */
  function contractOwnerUnlockProject(uint256 _projectId) external onlyOwner() {
    projects[_projectId].locked = false;
  }

  /** @dev Allows the contract owner to set the royalty percent.
    * @param _newPercent royalty percent
    */
  function contractOwnerUpdateGlobalSecondaryRoyaltyPercent(uint16 _newPercent) external onlyOwner() {
    secondaryRoyaltyPercent = _newPercent;
  }

  /// @dev ANYONE - CREATING A PROJECT AND PROJECT ADMINISTRATION

  /** @dev Allows anyone to create a project _projectName, with _pricePerTokenInWei and _maxEditions.
    * @param _projectName A name of a project
    * @param _pricePerTokenInWei The price for each mint
    * @param _maxEditions The total number of editions for this project
    */
  function anyoneCreateProject(
    string calldata _projectName,
    string calldata _artistName,
    string calldata _description,
    uint256 _pricePerTokenInWei,
    uint256 _maxEditions,
    string calldata _scriptTransactionHash,
    string calldata _scriptType
  ) external payable onlyAuthorizedArtist() {
      require(msg.value >= projectFee, "project fee");
      require(bytes(_projectName).length > 0);
      require(bytes(_artistName).length > 0);
      require(_maxEditions > 0 && _maxEditions <= 1000000);

      currentProjectId++;
      uint256 _projectId = currentProjectId;
      projects[_projectId].name = _projectName;
      projects[_projectId].artist = _artistName;
      projects[_projectId].description = _description;

      projectIdToArtistAddress[_projectId] = msg.sender;
      projectIdToPricePerEditionInWei[_projectId] = _pricePerTokenInWei;
      projects[_projectId].currentEditionId = 0;
      projects[_projectId].maxEditions = _maxEditions;

      projects[_projectId].maxGridDimension = 10;

      projects[_projectId].scriptTransactionHash = _scriptTransactionHash;
      projects[_projectId].scriptType = _scriptType;

      projects[_projectId].active = false;
      projects[_projectId].paused = true;
      projects[_projectId].locked = false;

      setupImmutablesArtRoyaltyManagerForProjectId(_projectId);

      emit AddressCreatedProject(msg.sender, _projectId, _projectName);
  }

  /** @dev Clones a Royalty Manager Contract for a new Project ID
    * @param _projectId the projectId.
    */
  function setupImmutablesArtRoyaltyManagerForProjectId(uint256 _projectId) internal {
      // checks
      require(projectIdToRoyaltyAddress[_projectId] == address(0), "royalty manager already exists for _projectId");

      // effects
      address _newManager = Clones.clone(address(implementation));
      projectIdToRoyaltyAddress[_projectId] = address(_newManager);

      // interactions
      ImmutablesArtRoyaltyManager(payable(_newManager)).initialize(address(this), _projectId, projectIdToArtistAddress[_projectId], artistPercent, address(0), 0);
      emit CreatedImmutablesArtRoyaltyManagerForProjectId(address(_newManager), _projectId);
  }

  /** @dev Releases funds from a Royalty Manager for a Project Id
    * @param _projectId the projectId.
    */
  function releaseRoyaltiesForProject(uint256 _projectId) external {
      ImmutablesArtRoyaltyManager(payable(projectIdToRoyaltyAddress[_projectId])).release();
  }

  /// @dev ARTIST UPDATE FUNCTIONS

  /** @dev Allows the artist to update the artist's Eth address in the contract, and in the Royalty Manager.
    * @param _projectId the projectId.
    * @param _newArtistAddress the new Eth address for the artist.
    */
  function artistUpdateProjectArtistAddress(uint256 _projectId, address _newArtistAddress) external onlyArtist(_projectId) {
      projectIdToArtistAddress[_projectId] = _newArtistAddress;
      ImmutablesArtRoyaltyManager(payable(projectIdToRoyaltyAddress[_projectId])).artistUpdateAddress(_newArtistAddress);
  }

  /** @dev Allows the artist to update project additional payee info.
    * @param _projectId the projectId.
    * @param _additionalPayee the additional payee address.
    * @param _additionalPayeePercent the basis point (1/10,000th) share of project for the _additionalPayee up to artistPercent (e.g., 5000 = 50.0%).
    */
  function artistUpdateProjectAdditionalPayeeInfo(uint256 _projectId, address _additionalPayee, uint16 _additionalPayeePercent) external onlyArtist(_projectId)  {
      // effects
      projectIdToAdditionalPayee[_projectId] = _additionalPayee;
      projectIdToAdditionalPayeePercent[_projectId] = _additionalPayeePercent;

      // interactions
      ImmutablesArtRoyaltyManager(payable(projectIdToRoyaltyAddress[_projectId])).artistUpdateAdditionalPayeeInfo(_additionalPayee, _additionalPayeePercent);
  }

  // ARTIST OR TEAMMEMBER UPDATE FUNCTIONS

  /** @dev Allows the artist or team to update the price per token in wei for a project.
    * @param _projectId the projectId.
    * @param _pricePerTokenInWei new price per token for projectId
    */
  function artistTeamUpdateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) external onlyArtistOrTeammember(_projectId) {
      projectIdToPricePerEditionInWei[_projectId] = _pricePerTokenInWei;
  }

  /** @dev Allows the artist or team to update the maximum number of editions
    * @dev to display at once in the grid view.
    * @param _projectId the projectId.
    * @param _maxGridDimension the maximum number of editions per side of Grid View Square.
    */
  function artistTeamUpdateProjectMaxGridDimension(uint256 _projectId, uint8 _maxGridDimension) external onlyArtistOrTeammember(_projectId) {
      require(_maxGridDimension > 0);
      require(_maxGridDimension <= 255);
      projects[_projectId].maxGridDimension = _maxGridDimension;
  }

  /** @dev Allows the artist or team to update the maximum number of editions
    * @dev that can be minted for a project.
    * @param _projectId the projectId.
    * @param _maxEditions the maximum number of editions for a project.
    */
  function artistTeamUpdateProjectMaxEditions(uint256 _projectId, uint256 _maxEditions) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      require(_maxEditions >= projects[_projectId].currentEditionId);
      require(_maxEditions <= 1000000);
      projects[_projectId].maxEditions = _maxEditions;
  }

  /** @dev Allows the artist or team to update the project name.
    * @param _projectId the projectId.
    * @param _projectName the new project name.
    */
  function artistTeamUpdateProjectName(uint256 _projectId, string memory _projectName) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].name = _projectName;
  }

  /** @dev Allows the artist or team to update the artist's name.
    * @param _projectId the projectId.
    * @param _artistName the new artist name.
    */
  function artistTeamUpdateArtistName(uint256 _projectId, string memory _artistName) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].artist = _artistName;
  }

  /** @dev Allows the artist or team update project description.
    * @param _projectId the projectId.
    * @param _description the description for the project.
    */
  function artistTeamUpdateProjectDescription(uint256 _projectId, string calldata _description) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].description = _description;
  }

  /** @dev Allows the artist or team to update the project code transaction
    * @dev hash. The project code should be added to the referenced Immutables
    * @dev page as a Post starting with a line contaning three tick marks ```
    * @dev and ending with a line consisting of three tick marks ```.  The code
    * @dev will then be stored in a Post that has an Eth transaction hash.
    * @dev Add the transaction hash for the code Post to the project using this
    * @dev function. The code will then be pulled from this transaction hash
    * @dev for each render associated with this project.
    * @param _projectId the projectId.
    * @param _scriptTransactionHash the Ethereum transaction hash storing the code.
    */
  function artistTeamUpdateProjectScriptTransactionHash(uint256 _projectId, string memory _scriptTransactionHash) external onlyUnlocked(_projectId) onlyArtistOrTeammember(_projectId) {
      projects[_projectId].scriptTransactionHash = _scriptTransactionHash;
  }

  /** @dev Allows the artist or team to update the project script type.
    * @dev The code contained in the transaction hash will be interpreted
    * @dev by the front end based on the script type.
    * @param _projectId the projectId.
    * @param _scriptType the script type (e.g., p5js)
    */
  function artistTeamUpdateProjectScriptType(uint256 _projectId, string memory _scriptType) external onlyUnlocked(_projectId) onlyArtistOrTeammember(_projectId) {
         projects[_projectId].scriptType = _scriptType;
  }

  /** @dev Allows the artist or team toggle whether the project is paused.
    * @dev A paused project can only be minted by the artist or team.
    * @param _projectId the projectId.
    */
  function artistTeamToggleProjectIsPaused(uint256 _projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].paused = !projects[_projectId].paused;
  }

  /** @dev Allows the artist or team to set an image URL and file extension.
    * @dev Once project editions are minted, an IPFS CAR file can be created.
    * @dev The CAR file can contain image files with filenames corresponding to
    * @dev the Immutables.art tokenIds for the project. The CAR file can be
    * @dev stored on IPFS, the conract updated with the _newImageURLBase and
    * @dev _newFileExtension and then token images can be found by going to:
    * @dev _newImageBase = ipfs://[cid for the car file]/
    * @dev _newImageURLExt = ".png"
    * @dev Resulting URL = ipfs://[cid for the car file]/[tokenId].png
    * @param _projectId the projectId.
    * @param _newImageURLBase the base for the image url (e.g., "ipfs://[cid]/" )
    * @param _newImageURLExt the file extension for the image file (e.g., ".png" , ".gif" , etc.).
    * @param _useImageURLInGridView bool whether to use the ImageURL in the Grid instead of a live render.
    */
  function artistTeamUpdateProjectImageURLInfo(uint256 _projectId,
                                      string calldata _newImageURLBase,
                                      string calldata _newImageURLExt,
                                      bool _useImageURLInGridView)
                                      external onlyArtistOrTeammember(_projectId) {
    projectIdToImageURLBase[_projectId] = _newImageURLBase;
    projectIdToImageURLExt[_projectId] = _newImageURLExt;
    projectIdUseImageURLInGridView[_projectId] = _useImageURLInGridView;
  }

  /** @dev Allows the artist or team to lock a project.
    * @dev Projects that are locked cannot have certain attributes modified.
    * @param _projectId the projectId.
    */
  function artistTeamLockProject(uint256 _projectId) external onlyUnlocked(_projectId) onlyArtistOrTeammember(_projectId) {
      projects[_projectId].locked = true;
  }

  // TEAMMEMBER ONLY UPDATE FUNCTIONS

  /** @dev Allows the team to set a category for a project.
    * @param _projectId the projectId.
    * @param _category string category name for the project.
    */
  function teamUpdateProjectCategory(uint256 _projectId, string calldata _category) external onlyTeammember() {
      projects[_projectId].category = _category;
      emit AdminUpdatedProjectCategory(_projectId, _category);
  }

  /** @dev Allows the team toggle whether the project is active.
    * @dev Only active projects are visible to the public.
    * @param _projectId the projectId.
    */
  function teamToggleProjectIsActive(uint256 _projectId) external onlyTeammember() {
      projects[_projectId].active = !projects[_projectId].active;
  }

  /** @dev Allows the team to toggle whether or not only approved artists are
    * @dev allowed to create projects.
    */
  function teamToggleArtistScreeningEnabled() external onlyTeammember() {
      artistScreeningEnabled = !artistScreeningEnabled;
  }
}

/// @author Gutenblock.eth
/// @title ImmutablesOptionalMetadataServer
contract ImmutablesOptionalMetadataServer is Ownable {
    /// @dev Stores the base web address for the Immutables web server.
    string public immutablesWEB;
    /// @dev Stores the base URI for the Immutables Metadata server.
    string public immutablesURI;
    /// @dev Whether to serve metadata from the server, or from the contract.
    bool public useMetadataServer;

    constructor () {
      immutablesWEB = "http://immutables.art/#/";
      immutablesURI = "http://nft.immutables.art/";
      useMetadataServer = false;
    }

    /** @dev Allows the contract owner to update the website URL.
      * @param _newImmutablesWEB The new website URL as a string.
      */
    function contractOwnerUpdateWebsite(string calldata _newImmutablesWEB) external onlyOwner() {
      immutablesWEB = _newImmutablesWEB;
    }

    /** @dev Allows the contract owner to update the metadata server URL.
      * @param _newImmutablesURI The new metadata server url as a string.
      */
    function contractOwnerUpdateAPIURL(string calldata _newImmutablesURI) external onlyOwner() {
      immutablesURI = _newImmutablesURI;
    }

    /** @dev Allows the contract owner to set the metadata source.
      * @param _shouldUseMetadataServer true or false
      */
    function contractOwnerUpdateUseMetadataServer(bool _shouldUseMetadataServer) external onlyOwner() {
      useMetadataServer = _shouldUseMetadataServer;
    }
}

/// @author Gutenblock.eth
/// @title ImmutablesArt
contract ImmutablesArt is ImmutablesAdminProject, ImmutablesOptionalMetadataServer, ERC721, IERC2981 {
    using Strings for uint256;
    using Address for address payable;

    /// @dev GLOBAL VARIABLES

    /// @dev The total suppliy of tokens (Editions of all Projects).
    uint256 public maxTotalSupply;
    /// @dev The last tokenId minted.
    uint256 public currentTokenId;

    /// @dev Mappings between the tokenId, projectId, editionIds, and Hashes
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256) public tokenIdToEditionId;
    mapping(uint256 => uint256[]) public projectIdToTokenIds;

    /// @dev MODIFIERS

    modifier onlyOwnerOfToken(uint256 _tokenId) {
      require(msg.sender == ownerOf(_tokenId), "must own");
      _;
    }

    modifier onlyArtistOrOwnerOfToken(uint256 _tokenId) {
      require(msg.sender == ownerOf(_tokenId) || msg.sender == projectIdToArtistAddress[tokenIdToProjectId[_tokenId]], "artistOwner");
      _;
    }

    /// @dev EVENTS

    event PaymentReceived(address from, uint256 amount);

    event AddressMintedProjectEditionAsToken(
      address indexed purchaser,
      uint256 indexed projectId,
      uint256 editionId,
      uint256 indexed tokenId
    );

    event TokenUpdatedWithMessage(
      address indexed user,
      uint256 indexed tokenId,
      string message
    );

    /// @dev CONTRACT CONSTRUCTOR

    constructor () ERC721("Immutables.art", "][art") ImmutablesOptionalMetadataServer() {
      projectFee = 0 ether;

      maxTotalSupply = ~uint256(0);
      currentTokenId = 0;

      currentProjectId = 0;

      artistScreeningEnabled = false;
      artistPercent = 9000; // 90.00%

      curator = address(0);
      curatorPercent = 0;

      beneficiary = address(0);
      beneficiaryPercent = 0;

      secondaryRoyaltyPercent = 1000; // 10.00%

      isTeammember[msg.sender] = true;

      emit AdminModifiedTeammembers(msg.sender, true);
    }

    /// @dev FINANCIAL

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /// @dev HELPER FUNCTIONS

    /** @dev Returns a list of tokenIds for a given projectId.
      * @param _projectId the projectId.
      * @return _tokenIds an array of tokenIds for the given project.
      */
    function getTokenIdsForProjectId(uint256 _projectId) external view returns (uint256[] memory _tokenIds) {
        return projectIdToTokenIds[_projectId];
    }

    /** @dev Used if a web2.0 style metadata server is required for more full
      * @dev featured legacy marketplace compatability.
      * @return _ the metadata server baseURI if a metadata server is used.
      */
    function _baseURI() internal view override returns (string memory) {
      return immutablesURI;
    }

    /** @dev Returns a string from a uint256
      * @param value uint256 data type string
      * @return _ string data type.
      */
    function toString(uint256 value) internal pure returns (string memory) {
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

    /** @dev Returns an image reference for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ an IPFS url to an image, or an SVG image if there is no IPFS image.
      */
    function getImageForTokenId(uint256 _tokenId) internal view returns (string memory) {
      string memory _base = projectIdToImageURLBase[tokenIdToProjectId[_tokenId]];
      string memory _ext = projectIdToImageURLExt[tokenIdToProjectId[_tokenId]];
      if(bytes(_base).length > 0 && bytes(_ext).length > 0) {
        return string(abi.encodePacked(_base,toString(_tokenId),_ext));
      } else {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(getSVGForTokenId(_tokenId)))));
      }
    }

    /** @dev Returns an SVG string for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ a SVG image string.
      */
    function getSVGForTokenId(uint256 _tokenId) public view returns (string memory) {
      string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .edition { fill: #ffffff; font-family: Open Sans; font-size: 12px; } .base { fill: #ffffff; font-family: Open Sans; font-size: 180px; } </style> <rect width="100%" height="100%" fill="#9400D3" /> <text class="edition" x="50%" y="5%" dominant-baseline="middle" text-anchor="middle">';
      output = string(abi.encodePacked(output, projects[tokenIdToProjectId[_tokenId]].name, ' # ', toString(tokenIdToEditionId[_tokenId])));
      output = string(abi.encodePacked(output,'</text><text class="edition" x="50%" y="10%" dominant-baseline="middle" text-anchor="middle">][art # ', toString(_tokenId)));
      output = string(abi.encodePacked(output,'</text><text class="base" x="50%" y = "50%" dominant-baseline="middle" text-anchor="middle">][</text></svg>'));
      return output;
    }

    /** @dev Returns a metadata attributes string for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ a metadata attributes string.
      */
    function getMetadataAttributesStringForTokenId(uint256 _tokenId) internal view returns (string memory) {
      uint256 _projectId = tokenIdToProjectId[_tokenId];
      string memory output = string(
        abi.encodePacked(
          '"attributes": [',
                '{"trait_type": "Project", "value": "', projects[_projectId].name,'"},',
                '{"trait_type": "Artist", "value": "', projects[_projectId].artist,'"},',
                '{"trait_type": "Category","value": "', projects[_projectId].category,'"}',
          ']'
        )
      );
      return output;
    }

    /** @dev Returns a metadata string for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ a metadata string.
      */
    function getMetadataStringForTokenId(uint256 _tokenId) internal view returns (string memory) {
      uint256 _projectId = tokenIdToProjectId[_tokenId];
      string memory _url = string(abi.encodePacked(immutablesWEB, toString(_projectId), '/', toString(tokenIdToEditionId[_tokenId])));
      //string memory _collection = string(abi.encodePacked(projects[_projectId].name, " by ", projects[_projectId].artist));
      string memory output = string(
        abi.encodePacked(
          '{"name": "', projects[_projectId].name, ' # ', toString(tokenIdToEditionId[_tokenId]),
          '", "description": "', projects[_projectId].description,
          '", "external_url": "', _url,
          '", ', getMetadataAttributesStringForTokenId(_tokenId)
        )
      );
      return output;
    }

    /** @dev Returns a tokenURI URL or Metadata string depending on useMetadataServer
      * @param _tokenId the _tokenId.
      * @return _ String of a URI or Base64 encoded metadata and image string.
      */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      if(useMetadataServer) { // IF THE METADATA SERVER IS IN USE RETURN A URL
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
      } else { // ELSE WE ARE SERVERLESS AND RETURN METADATA DIRECTLY h/t DEAFBEEF FIRST NFT
        string memory json = Base64.encode(
          bytes(
            string(
              abi.encodePacked(
                getMetadataStringForTokenId(_tokenId),
                ', "image": "',
                getImageForTokenId(_tokenId),
                '"}'
              )
            )
          )
        );
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
      }
    }

    /// @dev royaltiesAddress - IERC2981

    /** @dev Returns the ERC2981 royaltyInfo.
      * @param _tokenId the _tokenId.
      * @param _salePrice the sales price to use for the royalty calculation.
      * @return receiver the recipient of the royalty payment.
      * @return royaltyAmount the calcualted royalty amount.
      */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
      require(_tokenId <= currentTokenId, "tokenId");
      return (projectIdToRoyaltyAddress[tokenIdToProjectId[_tokenId]], _salePrice * secondaryRoyaltyPercent / 10000);
    }

    /// @dev CONTRACT ADMINISTRATION

    /** @dev The artist or owner of a token can post a message associated with
      * @dev an edition of the project.
      * @param _tokenId the tokenId.
      * @param _message the message to add to the token.
      */
    function artistOwnerUpdateTokenWithMessage(uint256 _tokenId, string calldata _message) external onlyArtistOrOwnerOfToken(_tokenId) {
      require(bytes(_message).length > 0);
      emit TokenUpdatedWithMessage(msg.sender, _tokenId, _message);
    }

    /// @dev ANYONE - MINTING AN EDITION

    /** @dev Anyone can mint an edition of a project.
      * @param _projectId the projectId of the project to mint.
      */
    function anyoneMintProjectEdition(uint256 _projectId) external payable {
      // checks
      require(msg.value >= projectIdToPricePerEditionInWei[_projectId], "mint fee");
      require(projects[_projectId].currentEditionId < projects[_projectId].maxEditions, "sold out");
      // require project to be active or the artist or teammember to be trying to mint
      require(projects[_projectId].active || msg.sender == projectIdToArtistAddress[_projectId] || isTeammember[msg.sender], "not active");
      // require project to be unpaused or the artist or teammember to be trying to mint
      require(!projects[_projectId].paused || msg.sender == projectIdToArtistAddress[_projectId] || isTeammember[msg.sender], "paused");

      // effects
      uint256 _newTokenId = ++currentTokenId;
      uint256 _newEditionId = ++projects[_projectId].currentEditionId;

      tokenIdToProjectId[_newTokenId] = _projectId;
      tokenIdToEditionId[_newTokenId] = _newEditionId;
      projectIdToTokenIds[_projectId].push(_newTokenId);

      // interactions
      _mint(msg.sender, _newTokenId);
      //(bool success, ) = payable(projectIdToRoyaltyAddress[_projectId]).call{value:msg.value}("");
      //require(success, "Transfer to Royalty Manager contract failed.");
      payable(projectIdToRoyaltyAddress[_projectId]).sendValue(msg.value);

      emit AddressMintedProjectEditionAsToken(msg.sender, _projectId, _newEditionId, _newTokenId);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}