// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;


/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//      ██████╗░███████╗███████╗████████╗░██████╗██████╗░░█████╗░░█████╗░      //
//      ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗      //
//      ██████╦╝█████╗░░█████╗░░░░░██║░░░╚█████╗░██║░░██║███████║██║░░██║      //
//      ██╔══██╗██╔══╝░░██╔══╝░░░░░██║░░░░╚═══██╗██║░░██║██╔══██║██║░░██║      //
//      ██████╦╝███████╗███████╗░░░██║░░░██████╔╝██████╔╝██║░░██║╚█████╔╝      //
//      ╚═════╝░╚══════╝╚══════╝░░░╚═╝░░░╚═════╝░╚═════╝░╚═╝░░╚═╝░╚════╝░      //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
 * External Sources:
 * https://github.com/yosriady/PatronageCollectibles
 * https://github.com/simondlr/thisartworkisalwaysonsale
 */

/**
 * @title ERC721 token for HarbergerAsset
 * @dev Assets are controlled through the property rights enforced by Harberger taxation
 *
 * @author swaHili
 */
contract HarbergerAsset is ERC721URIStorage, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // Base time interval in seconds used to calculate foreclosure date (24 hours)
  uint256 public constant BASE_INTERVAL = 86400 seconds;

  // Percentage of sales price shows how royalty amount is calculated
  uint256 public constant ROYALTY_PERCENTAGE = 10;

  // Percentage of sales price shows how tax amount is calculated
  uint256 public constant TAX_PERCENTAGE = 10;

  // Denominator used to calculate royalty amount
  uint256 private constant ROYALTY_DENOMINATOR = 100 / ROYALTY_PERCENTAGE;

  // Denominator used to calculate tax amount
  uint256 private constant TAX_DENOMINATOR = 100 / TAX_PERCENTAGE;

  // Base tax denominator used to caculated daily tax rate (36.5% annual tax rate)
  uint256 private baseTaxDenominator = 1000;

  // Owner of contract
  address public admin;

  // Mapping tokenId to Asset struct
  mapping(uint64 => Asset) public assets;

  // Mapping tokenId to base tax value which is used to calculate foreclosure date
  mapping(uint64 => uint256) public baseTaxValues;

  // Mapping tokenId to IPFS CID hash of metadata
  mapping(uint64 => string) public ipfsMetadataHashes;

  // Mapping tokenId to address of tax collector account
  mapping(uint64 => address) public taxCollectors;

  /**
   * @dev Object that represents the current state of each asset
   * `tokenId` ID of the token
   * `creator` Address of the artist who created the asset
   * `priceAmount` Price amount of the asset
   * `taxAmount` Minimum tax amount of the asset
   * `totalDepositAmount` Total amount deposited by the current owner of the asset
   * `previousListingPrice` Price of asset when it was previously listed by the current owner
   * `foreclosureTimestamp` Timestamp of the foreclosure for which taxes must be paid by the current owner
   */
  struct Asset {
    uint64 tokenId;
    address creator;
    uint256 priceAmount;
    uint256 taxAmount;
    uint256 totalDepositAmount;
    uint256 previousListingPrice;
    uint256 foreclosureTimestamp;
  }

  /**
   * @dev List of possible events emitted after every transaction.
   */
  event Mint       (uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, address to);
  event List       (uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, uint256 value);
  event Deposit    (uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, address to, uint256 value);
  event Sale       (uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, address to, uint256 value);
  event Refund     (uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, address to, uint256 value);
  event Collect    (uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, address to, uint256 value);
  event Foreclosure(uint256 indexed timestamp, uint64 indexed tokenId, address indexed from, address to);

  /**
   * @dev Initializes contract and sets `admin` to specified owner of contract.
   * @param _admin Address of the contract admin
   */
  constructor(address _admin) ERC721("HarbergerAsset", "ASSET") {
    admin = _admin;
  }

  /**
   * @dev Modifier that checks if `admin` is equal to `msgSender()`.
   */
  modifier onlyAdmin() {
    require(admin == _msgSender(), "You are not authorized to perform this action");
    _;
  }

  /**
   * @dev Modifier that checks if `creator` of asset is equal to `msgSender()`.
   * @param _tokenId ID of the token
   */
  modifier onlyCreator(uint64 _tokenId) {
    require(assets[_tokenId].creator == _msgSender(), "You are not the creator of this asset");
    _;
  }

  /**
   * @dev Modifier that checks if `admin` or `creator` of asset is equal to `msgSender()`.
   * @param _tokenId ID of the token
   */
  modifier onlyAdminOrCreator(uint64 _tokenId) {
    require(admin == _msgSender() || assets[_tokenId].creator == _msgSender(), "You are not the admin nor creator of this asset");
    _;
  }

  /**
   * @dev Modifier that checks if `owner` of asset is equal to `msgSender()`.
   * @param _tokenId ID of the token
   */
  modifier onlyOwner(uint64 _tokenId) {
    require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this asset");
    _;
  }

  /**
   * @dev Modifier that checks if `tokenId` exists.
   * @param _tokenId ID of the token
   */
  modifier validToken(uint64 _tokenId) {
    require(_exists(_tokenId), "Token does not exist");
    _;
  }

  /**
   * @dev See {ERC721-baseURI}.
   */
  function _baseURI() override internal view virtual returns (string memory) {
    return "https://arweave.net/";
  }

  /**
   * @dev Mints `tokenId`, transfers it to `creator`, sets `tokenURI` and initializes asset state.
   * @param _arweaveId Arweave ID used for tokenURI
   * @param _ipfsMetadataHash IPFS CID hash of metadata
   * @param _creator Address of artist who created the asset
   * @param _taxCollector Address of tax collector account
   * @return the newly created `tokenId`
   *
   * Requirements:
   *
   * - `admin` must be equal to `msgSender()`.
   *
   * Emits a {Mint & Transfer} event.
   */
  function mintAsset(string memory _arweaveId, string memory _ipfsMetadataHash, address _creator, address _taxCollector) public onlyAdmin returns (uint256) {
    _tokenIds.increment();
    uint64 newItemId = uint64(_tokenIds.current());

    emit Mint(block.timestamp, newItemId, address(0), _creator);

    _safeMint(_creator, newItemId);
    _setTokenURI(newItemId, _arweaveId);
    ipfsMetadataHashes[newItemId] = _ipfsMetadataHash;

    assets[newItemId].tokenId = newItemId;
    assets[newItemId].creator = _creator;
    taxCollectors[newItemId] = _taxCollector;
    initializeAsset(newItemId);

    return newItemId;
  }

  /**
   * @dev Lists asset for sale in wei and sets corresponding tax price.
   * @param _tokenId ID of the token
   * @param _priceAmount Price amount of the asset
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   * - `owner` of asset must be equal to `msgSender()`.
   * - 'priceAmount' of asset must be greater than 0.
   * - 'foreclosure()' of asset must not be in process OR `msgSender()` must be equal to creator OR `msgSender() must be equal to admin`.
   *
   * Emits a {List} event.
   */
  function listAssetInWei(uint64 _tokenId, uint256 _priceAmount) public validToken(_tokenId) onlyOwner(_tokenId) {
    require(_priceAmount > 0, "You must set a sales price greater than 0");
    require(assets[_tokenId].priceAmount != _priceAmount, "Your listing price must be different than the current price");
    require(foreclosure(_tokenId) == false || assets[_tokenId].creator == _msgSender() || admin == _msgSender(), "A foreclosure on this asset has already begun");

    assets[_tokenId].priceAmount = _priceAmount;
    assets[_tokenId].taxAmount = _priceAmount / TAX_DENOMINATOR;
    uint256 newBaseTaxValue = _priceAmount / baseTaxDenominator;
    uint256 currentBaseTaxValue = baseTaxValues[_tokenId];

    if (assets[_tokenId].previousListingPrice != _priceAmount && assets[_tokenId].totalDepositAmount > 0) {
      uint256 timeRemaining = assets[_tokenId].foreclosureTimestamp - block.timestamp - BASE_INTERVAL;
      uint256 depositRemaining = (timeRemaining * currentBaseTaxValue) / BASE_INTERVAL;

      assets[_tokenId].foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
      assets[_tokenId].foreclosureTimestamp += (depositRemaining * BASE_INTERVAL) / newBaseTaxValue;
      assets[_tokenId].previousListingPrice = _priceAmount;
    }

    baseTaxValues[_tokenId] = newBaseTaxValue;
    emit List(block.timestamp, _tokenId, _msgSender(), _priceAmount);
  }

  /**
   * @dev Deposits taxes into contract.
   * @param _tokenId ID of the token
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   * - `owner` of asset must be equal to `msgSender()`.
   * - `priceAmount` of asset must be greater than 0.
   * - `msg.value` must be greater than or equal to `taxAmount`.
   * - 'foreclosure()' of asset must not be in process.
   *
   * Emits a {Deposit} event.
   */
  function depositTax(uint64 _tokenId) public payable validToken(_tokenId) onlyOwner(_tokenId) nonReentrant {
    require(assets[_tokenId].priceAmount > 0, "You must first set a sales price");
    require(msg.value >= assets[_tokenId].taxAmount, "Your tax deposit must not be less than the current tax price");
    require(foreclosure(_tokenId) == false, "A foreclosure on this asset has already begun");

    assets[_tokenId].totalDepositAmount += msg.value;
    assets[_tokenId].foreclosureTimestamp += (msg.value * BASE_INTERVAL) / baseTaxValues[_tokenId];

    emit Deposit(block.timestamp, _tokenId, _msgSender(), address(this), msg.value);
  }

  /**
   * @dev Purchase of asset triggers tax refund, payment transfers and asset transfer.
   * @param _tokenId ID of the token
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   * - `owner` of asset must not be equal to `msgSender()`.
   * - `priceAmount` of asset must be greater than 0.
   * - `priceAmount` of asset must be equal to `msg.value`.
   *
   * Emits a {Sale} event.
   */
  function buyAsset(uint64 _tokenId) public payable validToken(_tokenId) nonReentrant {
    require(ownerOf(_tokenId) != _msgSender(), "You are already the owner of this asset");
    require(assets[_tokenId].priceAmount > 0, "This asset is currently not up for sale");
    require(assets[_tokenId].priceAmount == msg.value, "Invalid payment amount");

    address creator = assets[_tokenId].creator;
    address currentOwner = ownerOf(_tokenId);
    uint256 baseTaxValue = baseTaxValues[_tokenId];
    uint256 refundAmount = refundTax(_tokenId, currentOwner, baseTaxValue);

    collectTax(_tokenId, currentOwner, refundAmount);
    initializeAsset(_tokenId);

    transferPayments(msg.value, currentOwner, creator);
    emit Sale(block.timestamp, _tokenId, _msgSender(), currentOwner, msg.value);
    this.safeTransferFrom(currentOwner, _msgSender(), _tokenId);
  }

  /**
   * @dev Refunds `currentOwner` the remaining tax amount. Since taxes are paid in advance based on a time interval,
     if the asset is purchased before the foreclosure date is reached, the `currentOwner` receives a portion of those taxes back.
     The refund calculation is simply the reverse of how the asset foreclosure date is calculated.
   * @param _tokenId ID of the token
   * @param _currentOwner Address of current owner of the asset
   * @param _baseTaxValue Base tax value currently set for the asset at the time of purchase or new tax deposit
   * @return refund amount from excess of taxes deposited
   *
   * Emits a {Refund} event if `timeRemaining` is more than `block.timestmap` plus `BASE_INTERVAL`.
   */
  function refundTax(uint64 _tokenId, address _currentOwner, uint256 _baseTaxValue) internal returns(uint256) {
    if (_currentOwner == assets[_tokenId].creator || _currentOwner == admin) return 0;

    uint256 foreclosureTimestamp = assets[_tokenId].foreclosureTimestamp;

    if (foreclosureTimestamp > block.timestamp + BASE_INTERVAL) {
      uint256 remainingTimestamp = foreclosureTimestamp - block.timestamp - BASE_INTERVAL;
      uint256 refundAmount = (remainingTimestamp * _baseTaxValue) / BASE_INTERVAL;

      payable(_currentOwner).transfer(refundAmount);
      emit Refund(block.timestamp, _tokenId, address(this), _currentOwner, refundAmount);

      return refundAmount;
    }

    return 0;
  }

  /**
   * @dev Transfers deposit amount after refund to tax collector account.
   * @param _tokenId ID of the token
   * @param _currentOwner Address of current owner of the asset
   * @param _refundAmount Amount refunded to current owner
   *
   * Emits a {Collect} event.
   */
  function collectTax(uint64 _tokenId, address _currentOwner, uint256 _refundAmount) internal {
    if (_currentOwner == assets[_tokenId].creator || _currentOwner == admin) return;

    address taxCollector = taxCollectors[_tokenId];
    uint256 totalDepositAmount = assets[_tokenId].totalDepositAmount;
    uint256 depositAfterRefund = totalDepositAmount - _refundAmount;

    payable(taxCollector).transfer(depositAfterRefund);
    emit Collect(block.timestamp, _tokenId, address(this), address(taxCollector), depositAfterRefund);
  }

  /**
   * @dev Transfers royalties to `admin` and `creator` of asset and transfers remaining payment to `currentOwner`.
   * @param _payment Value paid by the new owner
   * @param _currentOwner Address of current owner of the asset
   * @param _creator Address of artist who created the asset
   */
  function transferPayments(uint256 _payment, address _currentOwner, address _creator) internal {
    uint256 royaltyAmount = _payment / ROYALTY_DENOMINATOR;
    uint256 paymentAmount = _payment - royaltyAmount;

    payable(admin).transfer(royaltyAmount / 2);
    payable(_creator).transfer(royaltyAmount / 2);
    payable(_currentOwner).transfer(paymentAmount);
  }

  /**
   * @dev Reclaims asset and transfers it back to `creator`.
   * @param _tokenId ID of the token
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   * - `creator` must be equal to `msgSender()`.
   * - `foreclosure()` of asset must be equal to true.
   * - `creator` must not be current owner of the asset.
   *
   * Emits a {Foreclosure} event.
   */
  function reclaimAsset(uint64 _tokenId) public validToken(_tokenId) onlyAdminOrCreator(_tokenId) {
    require(foreclosure(_tokenId), "Time has not yet expired for you to reclaim this asset");
    require(ownerOf(_tokenId) != _msgSender(), "You are already the owner of this asset");

    address currentOwner = ownerOf(_tokenId);
    emit Foreclosure(block.timestamp, _tokenId, _msgSender(), currentOwner);

    safeTransferFrom(currentOwner, _msgSender(), _tokenId);
    initializeAsset(_tokenId);
  }

  /**
   * @dev Checks if current time is greater than `foreclosure` timestamp of asset.
   * @param _tokenId ID of the token
   * @return boolean value to determine status of asset foreclosure
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function foreclosure(uint64 _tokenId) public view validToken(_tokenId) returns (bool) {
    return block.timestamp >= assets[_tokenId].foreclosureTimestamp;
  }

  /**
   * @dev Resets asset and base tax value to initial state.
   * @param _tokenId ID of the token
   */
  function initializeAsset(uint64 _tokenId) private {
    assets[_tokenId].priceAmount = 0;
    assets[_tokenId].taxAmount = 0;
    assets[_tokenId].totalDepositAmount = 0;
    assets[_tokenId].previousListingPrice = 0;
    assets[_tokenId].foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
    baseTaxValues[_tokenId] = 0;
  }

  /**
   * @dev Resets the `foreclosureTimestamp` of the asset due to one-off events, such as auctions performed through third party contracts.
   * @param _tokenId ID of the token
   *
   * Requirements:
   *
   * - `admin` must be equal to `_msgSender()`.
   * - `foreclosure()` of asset must be equal to true.
   */
  function resetAssetForeclosure(uint64 _tokenId) public onlyAdmin {
    require(foreclosure(_tokenId) == true, "A foreclosure on this asset has not yet begun");

    assets[_tokenId].foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
  }

  /**
   * @dev Updates the `admin` account for controlling this contract.
   * @param _account Address of new admin account
   *
   * Requirements:
   *
   * - `admin` must be equal to `_msgSender()`.
   * - `address` must be different than the current address.
   */
  function setAdmin(address _account) public onlyAdmin {
    require(admin != _account, "New address must be different than the current address");

    admin = _account;
  }

  /**
   * @dev Updates the `baseTaxDenominator` used to calculate daily tax rate.
   * @param _value Denomination value
   *
   * Requirements:
   *
   * - `admin` must be equal to `_msgSender()`.
   * - `value` must be different than the current value.
   */
  function setBaseTaxDenominator(uint256 _value) public onlyAdmin {
    require(baseTaxDenominator != _value, "New value must be different than the current value");

    baseTaxDenominator = _value;
  }

  /**
   * @dev Returns the total supply of tokens minted on this contract.
   */
  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   *
   * Requirements:
   *
   * - `currentOwner` or `approvedAccount` must be equal to `msgSender()` OR
   * - `admin` or `creator` must be equal to `msgSender()` AND `foreclosure()` of asset must be equal to true.
   */
  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
    ) public virtual override {
    uint64 _tokenId = uint64(tokenId);
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId) ||
      ((admin == _msgSender() || assets[_tokenId].creator == _msgSender()) && foreclosure(_tokenId)),
      "Transfer caller is not owner nor approved OR a foreclosure on this asset has not yet begun"
    );

    _safeTransfer(from, to, tokenId, _data);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
interface IERC721Receiver {
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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