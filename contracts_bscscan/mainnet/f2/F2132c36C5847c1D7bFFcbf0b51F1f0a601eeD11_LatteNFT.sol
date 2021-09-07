// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./ILatteNFT.sol";

contract LatteNFT is ILatteNFT, ERC721PausableUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // role for setting up non-sensitive data
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // role for minting stuff (owner + some delegated contract eg nft market)

  struct Category {
    string name;
    string categoryURI; // category URI, a super set of token's uri (it can be either uri or a path (if specify a base URI))
    uint256 timestamp;
  }

  // Used for generating the tokenId of new NFT minted
  CountersUpgradeable.Counter private _tokenIds;

  // Used for incrementing category id
  CountersUpgradeable.Counter private _categoryIds;

  // Map the latteName for a tokenId
  mapping(uint256 => string) public override latteNames;

  mapping(uint256 => Category) public override categoryInfo;

  mapping(uint256 => uint256) public override latteNFTToCategory;

  mapping(uint256 => EnumerableSetUpgradeable.UintSet) private _categoryToLatteNFTList;

  mapping(uint256 => string) private _tokenURIs;

  event AddCategoryInfo(uint256 indexed id, string name, string uri);
  event UpdateCategoryInfo(uint256 indexed id, string prevName, string newName, string newURI);
  event SetLatteName(uint256 indexed tokenId, string prevName, string newName);
  event SetTokenURI(uint256 indexed tokenId, string indexed prevURI, string indexed currentURI);
  event SetBaseURI(string indexed prevURI, string indexed currentURI);
  event SetTokenCategory(uint256 indexed tokenId, uint256 indexed categoryId);
  event Pause();
  event Unpause();

  /// @dev only the one having a GOVERNANCE_ROLE can continue an execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "LatteNFT::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @dev only the one having a MINTER_ROLE can continue an execution
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "LatteNFT::onlyMinter::only MINTER role");
    _;
  }

  modifier onlyExistingCategoryId(uint256 _categoryId) {
    require(_categoryIds.current() >= _categoryId, "LatteNFT::onlyExistingCategoryId::categoryId not existed");
    _;
  }

  function initialize(string memory _baseURI) public initializer {
    ERC721Upgradeable.__ERC721_init("LATTE NFT", "LATTE");
    ERC721PausableUpgradeable.__ERC721Pausable_init();
    OwnableUpgradeable.__Ownable_init();
    AccessControlUpgradeable.__AccessControl_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setBaseURI(_baseURI);
  }

  /// @notice getter function for getting a token id list with respect to category Id
  /// @param _categoryId category id
  /// @return return alist of nft tokenId
  function categoryToLatteNFTList(uint256 _categoryId)
    external
    view
    override
    onlyExistingCategoryId(_categoryId)
    returns (uint256[] memory)
  {
    uint256[] memory tokenIds = new uint256[](_categoryToLatteNFTList[_categoryId].length());
    for (uint256 i = 0; i < _categoryToLatteNFTList[_categoryId].length(); i++) {
      tokenIds[i] = _categoryToLatteNFTList[_categoryId].at(i);
    }
    return tokenIds;
  }

  /// @notice return latest token id
  /// @return uint256 of the current token id
  function currentTokenId() public view override returns (uint256) {
    return _tokenIds.current();
  }

  /// @notice return latest category id
  /// @return uint256 of the current category id
  function currentCategoryId() public view override returns (uint256) {
    return _categoryIds.current();
  }

  /// @notice add category (group of tokens)
  /// @param _name a name of a category
  /// @param _uri category URI, a super set of token's uri (it can be either uri or a path (if specify a base URI))
  function addCategoryInfo(string memory _name, string memory _uri) external onlyGovernance {
    uint256 newId = _categoryIds.current();
    _categoryIds.increment();
    categoryInfo[newId] = Category({ name: _name, timestamp: block.timestamp, categoryURI: _uri });

    emit AddCategoryInfo(newId, _name, _uri);
  }

  /// @notice view function for category URI
  /// @param _categoryId category id
  function categoryURI(uint256 _categoryId)
    external
    view
    override
    onlyExistingCategoryId(_categoryId)
    returns (string memory)
  {
    string memory _categoryURI = categoryInfo[_categoryId].categoryURI;
    string memory base = baseURI();

    // If there is no base URI, return the category URI.
    if (bytes(base).length == 0) {
      return _categoryURI;
    }
    // If both are set, concatenate the baseURI and categoryURI (via abi.encodePacked).
    if (bytes(_categoryURI).length > 0) {
      return string(abi.encodePacked(base, _categoryURI));
    }
    // If there is a baseURI but no categoryURI, concatenate the categoryId to the baseURI.
    return string(abi.encodePacked(base, _categoryId.toString()));
  }

  /**
   * @dev overrided tokenURI with a categoryURI replacement feature
   * @param _tokenId - token id
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable, IERC721MetadataUpgradeable)
    returns (string memory)
  {
    require(_exists(_tokenId), "LatteNFT::tokenURI:: token not existed");

    string memory _tokenURI = _tokenURIs[_tokenId];
    string memory base = baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    // If if category uri exists, use categoryURI as a tokenURI
    if (bytes(categoryInfo[latteNFTToCategory[_tokenId]].categoryURI).length > 0) {
      return string(abi.encodePacked(base, categoryInfo[latteNFTToCategory[_tokenId]].categoryURI));
    }

    // If there is a baseURI but neither have tokenURI nor categoryURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(base, _tokenId.toString()));
  }

  /// @notice update category (group of tokens)
  /// @param _categoryId a category id
  /// @param _newName a new updated name
  /// @param _newURI a new category URI
  function updateCategoryInfo(
    uint256 _categoryId,
    string memory _newName,
    string memory _newURI
  ) external onlyGovernance onlyExistingCategoryId(_categoryId) {
    Category storage category = categoryInfo[_categoryId];
    string memory prevName = category.name;
    category.name = _newName;
    category.categoryURI = _newURI;
    category.timestamp = block.timestamp;

    emit UpdateCategoryInfo(_categoryId, prevName, _newName, _newURI);
  }

  /// @notice update a token's categoryId
  /// @param _tokenId a token id to be updated
  /// @param _newCategoryId a new categoryId for the token
  function updateTokenCategory(uint256 _tokenId, uint256 _newCategoryId)
    external
    onlyGovernance
    onlyExistingCategoryId(_newCategoryId)
  {
    uint256 categoryIdToBeRemovedFrom = latteNFTToCategory[_tokenId];
    latteNFTToCategory[_tokenId] = _newCategoryId;
    require(
      _categoryToLatteNFTList[categoryIdToBeRemovedFrom].remove(_tokenId),
      "LatteNFT::updateTokenCategory::tokenId not found"
    );
    require(_categoryToLatteNFTList[_newCategoryId].add(_tokenId), "LatteNFT::updateTokenCategory::duplicated tokenId");

    emit SetTokenCategory(_tokenId, _newCategoryId);
  }

  /**
   * @dev Get the associated latteName for a unique tokenId.
   */
  function getLatteNameOfTokenId(uint256 _tokenId) external view override returns (string memory) {
    return latteNames[_tokenId];
  }

  /**
   * @dev Mint NFT. Only the minter can call it.
   */
  function mint(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI
  ) public virtual override onlyMinter onlyExistingCategoryId(_categoryId) returns (uint256) {
    uint256 newId = _tokenIds.current();
    _tokenIds.increment();
    latteNFTToCategory[newId] = _categoryId;
    require(_categoryToLatteNFTList[_categoryId].add(newId), "LatteNFT::mint::duplicated tokenId");
    _mint(_to, newId);
    _setTokenURI(newId, _tokenURI);
    emit SetTokenCategory(newId, _categoryId);
    return newId;
  }

  function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual override {
    require(_exists(_tokenId), "LatteNFT::_setTokenURI::tokenId not found");
    string memory prevURI = _tokenURIs[_tokenId];
    _tokenURIs[_tokenId] = _tokenURI;

    emit SetTokenURI(_tokenId, prevURI, _tokenURI);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyGovernance {
    _setTokenURI(_tokenId, _tokenURI);
  }

  /**
   * @dev function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function setBaseURI(string memory _baseURI) external onlyGovernance {
    string memory prevURI = baseURI();
    _setBaseURI(_baseURI);

    emit SetBaseURI(prevURI, _baseURI);
  }

  /**
   * @dev batch ming NFTs. Only the owner can call it.
   */
  function mintBatch(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI,
    uint256 _size
  ) external override onlyMinter onlyExistingCategoryId(_categoryId) returns (uint256[] memory tokenIds) {
    require(_size != 0, "LatteNFT::mintBatch::size must be granter than zero");
    tokenIds = new uint256[](_size);
    for (uint256 i = 0; i < _size; ++i) {
      tokenIds[i] = mint(_to, _categoryId, _tokenURI);
    }
    return tokenIds;
  }

  /**
   * @dev Set a unique name for each tokenId. It is supposed to be called once.
   */
  function setLatteName(uint256 _tokenId, string calldata _name) external onlyGovernance {
    string memory _prevName = latteNames[_tokenId];
    latteNames[_tokenId] = _name;

    emit SetLatteName(_tokenId, _prevName, _name);
  }

    function pause() external onlyGovernance whenNotPaused {
          _pause();

    emit Pause();
  }

  function unpause() external onlyGovernance whenPaused {
    _unpause();

    emit Unpause();
  }
}