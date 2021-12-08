// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

/*
██╗███╗   ███╗███╗   ███╗██╗   ██╗████████╗ █████╗ ██████╗ ██╗     ███████╗███████╗
██║████╗ ████║████╗ ████║██║   ██║╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
██║██╔████╔██║██╔████╔██║██║   ██║   ██║   ███████║██████╔╝██║     █████╗  ███████╗
██║██║╚██╔╝██║██║╚██╔╝██║██║   ██║   ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
██║██║ ╚═╝ ██║██║ ╚═╝ ██║╚██████╔╝   ██║   ██║  ██║██████╔╝███████╗███████╗███████║
╚═╝╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝
*/

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Clones.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./ImmutablesPageRoyaltyManager.sol";

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

  /// @dev whether or not users need to be pre-screened.
  bool public userScreeningEnabled = false;

  /// @dev Teammember administration mapping
  mapping(address => bool) public isTeammember;

  /// @dev Allowed user administration mapping
  mapping(address => bool) public isAllowedUser;

  /// @dev MODIFIERS

  modifier onlyTeammember() {
      require(isTeammember[msg.sender], "team");
      _;
  }

  modifier onlyAllowedUser() {
    if(userScreeningEnabled) {
      require(isAllowedUser[msg.sender] || isTeammember[msg.sender], "auth");
    }
    _;
  }
  /// @dev EVENTS

  event AdminModifiedTeammembers(
    address indexed user,
    bool isTeammember
  );

  event AdminModifiedAllowedUsers(
    address indexed user,
    bool isAllowedUser
  );

  /** @dev Allows the contract owner to add a teammember.
    * @param _address of teammember to add
    */
  function contractOwnerAddTeammember(address _address) external onlyOwner() {
      isTeammember[_address] = true;
      emit AdminModifiedTeammembers(_address, true);
  }

  /** @dev Allows the contract owner to remove a teammember.
    * @param _address of teammember to remove
    */
  function contractOwnerRemoveTeammember(address _address) external onlyOwner() {
      isTeammember[_address] = false;
      emit AdminModifiedTeammembers(_address, false);
  }

  /** @dev Allows the contract owner to add a user.
    * @param _address of user to add
    */
  function teamAddAllowedUser(address _address) external onlyTeammember() {
      isAllowedUser[_address] = true;
      emit AdminModifiedAllowedUsers(_address, true);
  }

  /** @dev Allows the contract owner to remove a user.
    * @param _address of a user to remove
    */
  function teamRemoveAllowedUser(address _address) external onlyTeammember() {
      isAllowedUser[_address] = false;
      emit AdminModifiedAllowedUsers(_address, false);
  }

  function teamToggleUserScreeningEnabled() external onlyTeammember() {
    userScreeningEnabled = !userScreeningEnabled;
  }

  // FINANCIAL

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
/// @title ImmutablesAdminPostPage
contract ImmutablesAdminPostPage is ImmutablesAdmin {
    /// @dev GLOBAL VARIABLES
    /// @dev The fee paid to the contract to post an Immutables.
    uint256 public postingFee;
    /// @dev The fee paid into the contract to purchase a Page.
    uint256 public pageFee;

    /// @dev The basis point (1/10,000ths) percentage of value the contract gets
    ///      when payment made to a post.
    uint16 public contractTipPercentage;
    /// @dev The basis point (1/10,000ths) percentage of value the poster gets
    ///      when payment made to a post.
    uint16 public posterTipPercentage;

    /// @dev The basis point (1/10,000ths) percentage of value the poster gets
    ///      when payment made to a post.
    uint16 public contractSecondaryRoyaltyPercentage;

    /// @dev EVENTS
    event AddressPostedPageTagContent(
      address indexed poster,
      bytes32 indexed pageHash,
      bytes32 indexed tagHash,
      string page,
      string tag,
      string content
    );

    event AddressPaidPageTagValue(
      address indexed poster,
      bytes32 indexed pageHash,
      bytes32 indexed tagHash,
      string page,
      string tag,
      uint256 value
    );

    /// @dev HELPER FUNCTIONS

    /** @dev Determines if a string is a valid page (a-z|A-Z|0-9| |_|-) cannot start with 0
      * @param _str The proposed page name.
      * @return _ Whether the page contains only valid characters.
      */
    function isValidPageName(string calldata _str) public pure returns (bool) {
       bytes memory b = bytes(_str);
       require(b.length > 0, "can not be empty string");
       require(b[0] != 0x30 && b[0] != 0x20, "page cannot start with 0 or space");
       for(uint i; i < b.length; i++) {
            // if not 0-9, A-Z, a-z, space ' ', dash - or underscore _ return false
           if(!(((b[i] >= 0x30) && (b[i] <= 0x39)) || ((b[i] >= 0x41) && (b[i] <= 0x5A)) || ((b[i] >= 0x61) && (b[i] <= 0x7A)) || (b[i] == 0x20) || (b[i] == 0x2D) || (b[i] == 0x5F))) {
              return false;
            }
       }
       // otherwise, the string is OK to use as a page
       return true;
     }

    // @dev CONTRACT ADMINISTRATION

    /** @dev Allows the contract owner to update the posting fee.
      * @param _newPostingFee The new posting fee in Wei.
      */
    function contractOwnerUpdatePostingFee(uint256 _newPostingFee) external onlyOwner() {
      postingFee = _newPostingFee;
    }

    /** @dev Allows the contract owner to update the page fee.
      * @param _newPageFee The new posting fee in Wei.
      */
    function contractOwnerUpdatePageFee(uint256 _newPageFee) external onlyOwner() {
      pageFee = _newPageFee;
    }

    /** @dev Allows the contract owner to update the contractTipPercentage.
      * @param _newcontractTipPercentage The new contractTipPercentage fee in basis point (1/10,000th)s (e.g., 200 = 2.00%).
      */
    function contractOwnerUpdatecontractTipPercentage(uint16 _newcontractTipPercentage) external onlyOwner() {
      contractTipPercentage = _newcontractTipPercentage;
    }

    /** @dev Allows the contract owner to update the posterTipPercentage.
      * @param _newposterTipPercentage The new posterTipPercentage fee in basis point (1/10,000th)s (e.g., 1000 = 10.00%).
      */
    function contractOwnerUpdateposterTipPercentage(uint16 _newposterTipPercentage) external onlyOwner() {
      posterTipPercentage = _newposterTipPercentage;
    }

    /** @dev Allows the contract owner to update the contractSecondaryRoyaltyPercentage.
      * @param _newContractSecondaryRoyaltyPercentage The new contractSecondaryRoyaltyPercentage fee in basis point (1/10,000th)s (e.g., 20 = 10.0%).
      */
    function contractOwnerUpdateContractSecondaryRoyaltyPercentage(uint16 _newContractSecondaryRoyaltyPercentage) external onlyOwner() {
      require(_newContractSecondaryRoyaltyPercentage <= 1000, "too big");
      contractSecondaryRoyaltyPercentage = _newContractSecondaryRoyaltyPercentage;
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
      immutablesWEB = "http://immutables.co/";
      immutablesURI = "http://nft.immutables.co/";
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
/// @title Immutables - Ownable Pages
contract Immutables is ImmutablesAdminPostPage, ImmutablesOptionalMetadataServer, ERC721, IERC2981 {
    using Strings for uint256;
    using Address for address payable;

    /// @dev GLOBAL VARIABLES
    /// @dev The total suppliy of tokens (Pages).
    uint256 public maxTotalSupply;
    /// @dev The last tokenId minted.
    uint256 public currentTokenId;

    /// @dev The metadata description provided by the contract for all tokens.
    string public globalMetadataDescription;

    /// @dev Template Cloneable Royalty Manager Contract
    ImmutablesPageRoyaltyManager public implementation;

    /// @dev Mappings between the page string and tokenId.
    mapping(string => uint256) public pageToTokenId;
    mapping(uint256 => string) public tokenIdToPage;

    mapping(uint256 => address) public tokenIdToRoyaltyAddress;
    mapping(uint256 => uint16) public tokenIdToSecondaryRoyaltyPercent;

    /// @dev EVENTS

    event PaymentReceived(address from, uint256 amount);

    event AddressReservedPage(address indexed owner, uint256 tokenId, string page, address manager);

    // @dev CONSTRUCTOR

    constructor() ERC721("Immutables", "][") ImmutablesOptionalMetadataServer() {
      postingFee = 0 ether;
      pageFee = 0 ether;

      maxTotalSupply = ~uint256(0);
      currentTokenId = 0;

      curator = address(0);
      curatorPercent = 0;

      beneficiary = address(0);
      beneficiaryPercent = 0;

      contractTipPercentage = 250; //  2.50%
      posterTipPercentage = 1000;  // 10.00%
      contractSecondaryRoyaltyPercentage = 1000; // 10.00%

      globalMetadataDescription = "Immutables are NFTs stored completely on the Ethereum Blockchain.";

      isTeammember[msg.sender] = true;
      emit AdminModifiedTeammembers(msg.sender, true);

      implementation = new ImmutablesPageRoyaltyManager();
      implementation.initialize(address(this), 1, "I", address(this), 10000, address(0), 0);
    }

    /// @dev FINANCIAL

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // @dev HELPER FUNCTIONS

    function _baseURI() internal view override returns (string memory) {
      return immutablesURI;
    }

    // @dev DATA INSERTION: TEXT

    /** @dev Allows anyone to log data into the contract with a page _page, optional citation _tag, and content.
      * @param _page A page value (like an account)
      * @param _tag A citation to other data (like a parent post, another transaction, etc.)
      * @param _content A content string to log into the page with the optional citation.
      */
    function anyonePostPageTagContent(string calldata _page, string calldata _tag, string calldata _content) external payable {
        require(msg.value >= postingFee, "posting fee");
        require(bytes(_page).length > 0, "page name");
        if(userScreeningEnabled) {
          // If user screening is enabled,
          //    the user must be an allowed user, or the owner of the page, and
          //    the user must be posting in a public page, or the page they own.
          require(
            (isAllowedUser[msg.sender] || ownerOf(pageToTokenId[_page]) == msg.sender) &&
            (!this.isValidPageName(_page) || ownerOf(pageToTokenId[_page]) == msg.sender)
          , "auth");
        } else {
          // If user screening is not enabled,
          //    Anyone can post in a public page, or
          //    a page that they own.
          require(!this.isValidPageName(_page) || ownerOf(pageToTokenId[_page]) == msg.sender, "auth");
        }
        bytes32 _pageHash = keccak256(abi.encodePacked(_page));
        bytes32 _tagHash = keccak256(abi.encodePacked(_tag));

        emit AddressPostedPageTagContent(msg.sender, _pageHash, _tagHash, _page, _tag, _content);
    }

    // @dev DATA INSERTION: VALUE

    /** @dev Allows anyone to pay into the contract with a page _page, optional post transaction Hash, and poster address.
      * @dev Payment is split between page owner, poster, and contract.
      * @param _page An optional page value.
      * @param _postTransactionHash An optional citation to a post transaction hash.
      * @param _poster The address of the poster of the post to tip.
      */
    function anyonePayPagePostPosterValue(string calldata _page, string calldata _postTransactionHash, address _poster) external payable nonReentrant() {
        // checks
        require(msg.value > 0, "value");
        require(bytes(_postTransactionHash).length == 66, "txhash");

        // effects
        bytes32 _pageHash = "";
        bytes32 _tagHash = keccak256(abi.encodePacked('V',_postTransactionHash));
        string memory _tag = string(abi.encodePacked('V',_postTransactionHash));

        if(bytes(_page).length == 0) {
          // If there is no page specified
          uint256 _contractValue = msg.value * contractTipPercentage / 10000;
          uint256 _posterValue = msg.value - _contractValue;
          // interaction: pay the poster
          payable(_poster).sendValue(_posterValue);
        } else {
          // If a page is specified
          address _pageOwner = ownerOf(pageToTokenId[_page]);
          _pageHash = keccak256(abi.encodePacked(_page));

          uint256 _contractValue = msg.value * contractTipPercentage / 10000;
          uint256 _posterValue = msg.value * posterTipPercentage / 10000;
          uint256 _pageOwnerValue = msg.value - _contractValue - _posterValue;

          // interaction: pay the page owner, and pay the poster
          payable(_pageOwner).sendValue(_pageOwnerValue);
          payable(_poster).sendValue(_posterValue);
        }
        emit AddressPaidPageTagValue(msg.sender, _pageHash, _tagHash, _page, _tag, msg.value);
    }

    // @dev RESERVE PAGE

    /** @dev Allows anyone to reserve an unclaimed reservable page.
      * @param _page A page name to reserve.
      */
    function anyoneReserveUnclaimedPage(string calldata _page) external payable onlyAllowedUser() {
      require(msg.value >= pageFee, "page fee");
      require(currentTokenId < maxTotalSupply, "sold out");
      require(isValidPageName(_page), "invalid name");
      require(pageToTokenId[_page] == 0, "page taken");

      currentTokenId++;
      uint256 _newTokenId = currentTokenId;
      _mint(msg.sender, _newTokenId);

      pageToTokenId[_page] = _newTokenId;
      tokenIdToPage[_newTokenId] = _page;

      setupImmutablesPageRoyaltyManagerForTokenId(_newTokenId);

      emit AddressReservedPage(msg.sender, _newTokenId, _page, tokenIdToRoyaltyAddress[_newTokenId]);
    }

    /** @dev Clones a Royalty Manager Contract for a new Token ID
      * @param _tokenId the TokenId.
      */
    function setupImmutablesPageRoyaltyManagerForTokenId(uint256 _tokenId) internal {
        // checks
        require(tokenIdToRoyaltyAddress[_tokenId] == address(0), "royalty manager already exists for _tokenId");

        // effects
        address _newManager = Clones.clone(address(implementation));
        tokenIdToRoyaltyAddress[_tokenId] = address(_newManager);
        tokenIdToSecondaryRoyaltyPercent[_tokenId] = 1000;  // 10.00%

        // interactions
        ImmutablesPageRoyaltyManager(payable(_newManager)).initialize(
            address(this),
            _tokenId, tokenIdToPage[_tokenId],
            ownerOf(_tokenId), 10000-contractSecondaryRoyaltyPercentage,
            address(0), 0
        );
    }

    // @dev ROYALTIES - IERC2981

    /** @dev IERC2981 royaltyInfo function
      * @param _tokenId The tokenId for which royaltyInfo is being requested.
      * @param _salePrice The sales price to calculate the royalty from.
      * @return receiver the royalty recipient.
      * @return royaltyAmount the royalty amount.
      */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
      return (tokenIdToRoyaltyAddress[_tokenId], _salePrice * tokenIdToSecondaryRoyaltyPercent[_tokenId] / 10000);
    }

    /** @dev Allows contract owner or the current royalty recipient to change
      * @dev the receiver or percentage for a specified tokenId.
      * @param _tokenId The tokenId.
      * @param _newRoyaltyRecipient The new royalty receipient.
      * @param _royaltyPercent The new royalty percent.
      */
    function royaltyRecipientUpdateRoyaltyInfo(uint256 _tokenId, address _newRoyaltyRecipient, uint16 _royaltyPercent) external {
      require(ImmutablesPageRoyaltyManager(payable(tokenIdToRoyaltyAddress[_tokenId])).royaltyRecipient() == msg.sender, "auth");
      require(_royaltyPercent >= 0 && _royaltyPercent <= 1000, "percent"); // 0% to 10.00%
      ImmutablesPageRoyaltyManager(payable(tokenIdToRoyaltyAddress[_tokenId])).royaltyRecipientUpdateAddress(_newRoyaltyRecipient);
      tokenIdToSecondaryRoyaltyPercent[_tokenId] = _royaltyPercent;
    }

    /** @dev Allows the royaltyRecipient to update additional payee info for a
      * @dev spedified tokenId.
      * @param _tokenId the tokenId.
      * @param _additionalPayee the additional payee address.
      * @param _additionalPayeePercent the basis point (1/10,000th) share for the _additionalPayee up to artistPercent (e.g., 5000 = 50.0%).
      */
    function royaltyRecipientUpdateTokenAdditionalPayeeInfo(uint256 _tokenId, address _additionalPayee, uint16 _additionalPayeePercent) external  {
        // checks
        require(ImmutablesPageRoyaltyManager(payable(tokenIdToRoyaltyAddress[_tokenId])).royaltyRecipient() == msg.sender, "auth");
        // effects
        // interactions
        ImmutablesPageRoyaltyManager(payable(tokenIdToRoyaltyAddress[_tokenId])).royaltyRecipientUpdateAdditionalPayeeInfo(_additionalPayee, _additionalPayeePercent);
    }

    /** @dev Releases funds from a Royalty Manager for a Token Id
      * @param _tokenId the tokenId.
      */
    function releaseRoyaltiesForTokenId(uint256 _tokenId) external {
        ImmutablesPageRoyaltyManager(payable(tokenIdToRoyaltyAddress[_tokenId])).release();
    }

    // @dev METADATA

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

    /** @dev Returns a simple SVG for a tokenId
      * @param _tokenId uint256 tokenId to get the SVG for
      * @return _ string SVG for image of tokenId
      */
    function getSVGForTokenId(uint256 _tokenId) internal view returns (string memory) {
      string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .edition { fill: #F5F5F5; font-family: Open Sans; font-size: 12px; } .base { fill: #F5F5F5; font-family: Open Sans; font-size: 180px; } </style> <rect width="100%" height="100%" fill="#708090" /> <text class="edition" x="50%" y="5%" dominant-baseline="middle" text-anchor="middle">';
      output = string(abi.encodePacked(output, tokenIdToPage[_tokenId]));
      output = string(abi.encodePacked(output,'</text><text class="edition" x="50%" y="10%" dominant-baseline="middle" text-anchor="middle">][ # ', toString(_tokenId)));
      output = string(abi.encodePacked(output,'</text><text class="base" x="50%" y = "50%" dominant-baseline="middle" text-anchor="middle">][</text></svg>'));
      return output;
    }

    /** @dev Allows the contract owner to update the globalMetadataDescription.
      * @param _newDescription The new desciption text
      */
    function contractOwnerUpdateGlobalMetadataDescription(string calldata _newDescription) external onlyOwner() {
      globalMetadataDescription = _newDescription;
    }

    function getMetadataStringForTokenId(uint256 _tokenId) internal view returns (string memory) {
      string memory _url = string(abi.encodePacked(immutablesWEB, '#/', tokenIdToPage[_tokenId]));
      string memory output = string(
        abi.encodePacked(
          '{"name": "][ ',
          tokenIdToPage[_tokenId],
          '", "description": "', globalMetadataDescription, ' ( ', _url, ' ).", "external_url": "', _url
        )
      );
      return output;
    }

    /** @dev Returns a tokenURI URL or Metadata string depending on useMetadataServer
      * @param _tokenId The _token to return the URI or Metadata for.
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
                '", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(getSVGForTokenId(_tokenId))),
                '"}'
              )
            )
          )
        );
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
      }
    }

    /** @dev Determines if a string is a valid page that is not taken.
      * @param _str The proposed page name.
      * @return _ Whether the page is valid and available to purchase.
      */
    function isValidAndAvailablePageName(string calldata _str) public view returns (bool) {
      bool vaild = isValidPageName(_str);
      return ((pageToTokenId[_str] == 0) && vaild);
    }

    /** @dev Allows the contract owner to update the max number of pages.
      * @param _newMaxTotalSupply The new max total supply.
      */
    function contractOwnerUpdateMaxTotalSupply(uint256 _newMaxTotalSupply) external onlyOwner() {
      require(_newMaxTotalSupply >= currentTokenId, "Can not set maxTotalSupply to a value lower than currentTokenId.");
      maxTotalSupply = _newMaxTotalSupply;
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