// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./INafter.sol";
import "./INafterMarketAuction.sol";
import "./IMarketplaceSettings.sol";
import "./INafterRoyaltyRegistry.sol";
import "./INafterTokenCreatorRegistry.sol";

/**
 * Nafter core contract.
 */

contract Nafter is
  Initializable,
  ERC1155Upgradeable,
  EIP712Upgradeable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  INafter
{
  struct TokenInfo {
    uint256 tokenId;
    address creator;
    uint256 tokenAmount;
    address[] owners;
    uint8 serviceFee;
    uint256 creationTime;
  }

  struct TokenOwnerInfo {
    bool isForSale;
    uint8 priceType; // 0 for fixed, 1 for Auction dates range, 2 for Auction Infinity
    uint256[] prices;
    uint256[] bids;
    address[] bidders;
  }

  // mapping of token info
  mapping(uint256 => TokenInfo) public tokenInfo;
  mapping(uint256 => mapping(address => TokenOwnerInfo)) public tokenOwnerInfo;

  mapping(uint256 => bool) public tokenIdsAvailable;

  uint256[] public tokenIds;
  uint256 public maxId;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // market auction to set the price
  INafterMarketAuction public marketAuction;
  IMarketplaceSettings public marketplaceSettings;
  INafterRoyaltyRegistry public royaltyRegistry;
  INafterTokenCreatorRegistry public tokenCreatorRegistry;

  // Event indicating metadata was updated.
  event AddNewToken(address user, uint256 tokenId);
  event DeleteTokens(address user, uint256 tokenId, uint256 amount);

  function __Nafter_init(string memory _uri) public initializer {
    __Ownable_init();
    __ERC1155_init(_uri);
    __AccessControl_init();
    __EIP712_init("NafterNFT", "1.1.0");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function creatorOfToken(uint256 _tokenId) external view override returns (address payable) {
    return payable(tokenInfo[_tokenId].creator);
  }

  /**
   * @dev Gets the token amount
   * @param _tokenId uint256 ID of the token
   */
  function getTokenAmount(uint256 _tokenId) external view returns (uint256) {
    return tokenInfo[_tokenId].tokenAmount;
  }

  /**
   * @dev Gets the owners
   * @param _tokenId uint256 ID of the token
   */
  function getOwners(uint256 _tokenId) external view override returns (address[] memory owners) {
    return tokenInfo[_tokenId].owners;
  }

  /**
   * @dev Gets the Service Fee
   * @param _tokenId uint256 ID of the token
   * @return get the service fee
   */
  function getServiceFee(uint256 _tokenId) external view override returns (uint8) {
    return tokenInfo[_tokenId].serviceFee;
  }

  /**
   * @dev Gets the creation time
   * @param _tokenId uint256 ID of the token
   */
  function getCreationTime(uint256 _tokenId) external view returns (uint256) {
    return tokenInfo[_tokenId].creationTime;
  }

  /**
   * @dev Gets the is for sale
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getIsForSale(uint256 _tokenId, address _owner) external view override returns (bool) {
    return tokenOwnerInfo[_tokenId][_owner].isForSale;
  }

  /**
   * @dev Gets the price type
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return get the price type
   */
  function getPriceType(uint256 _tokenId, address _owner) external view override returns (uint8) {
    return tokenOwnerInfo[_tokenId][_owner].priceType;
  }

  /**
   * @dev Gets the prices
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getPrices(uint256 _tokenId, address _owner) external view returns (uint256[] memory prices) {
    return tokenOwnerInfo[_tokenId][_owner].prices;
  }

  /**
   * @dev Gets the bids
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getBids(uint256 _tokenId, address _owner) external view returns (uint256[] memory bids) {
    return tokenOwnerInfo[_tokenId][_owner].bids;
  }

  /**
   * @dev Gets the bidders
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getBidders(uint256 _tokenId, address _owner) external view returns (address[] memory bidders) {
    return tokenOwnerInfo[_tokenId][_owner].bidders;
  }

  /**
   * @dev get tokenIds length
   */
  function getTokenIdsLength() external view override returns (uint256) {
    return tokenIds.length;
  }

  /**
   * @dev get token Id
   * @param _index uint256 index
   */

  function getTokenId(uint256 _index) external view override returns (uint256) {
    return tokenIds[_index];
  }

  /**
   * @dev get owner tokens
   * @param _owner address of owner.
   */

  function getOwnerTokens(address _owner)
    public
    view
    returns (TokenInfo[] memory tokens, TokenOwnerInfo[] memory ownerInfo)
  {
    uint256 totalValues;
    //calculate totalValues
    for (uint256 i = 0; i < tokenIds.length; i++) {
      TokenInfo memory info = tokenInfo[tokenIds[i]];
      if (info.owners[info.owners.length - 1] == _owner) {
        totalValues++;
      }
    }

    TokenInfo[] memory values = new TokenInfo[](totalValues);
    TokenOwnerInfo[] memory valuesOwner = new TokenOwnerInfo[](totalValues);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      TokenInfo memory info = tokenInfo[tokenId];
      if (info.owners[info.owners.length - 1] == _owner) {
        values[i] = info;
        valuesOwner[i] = tokenOwnerInfo[tokenId][_owner];
      }
    }

    return (values, valuesOwner);
  }

  /**
   * @dev get token paging
   * @param _offset offset of the records.
   * @param _limit limits of the records.
   */
  function getTokensPaging(uint256 _offset, uint256 _limit)
    public
    view
    returns (
      TokenInfo[] memory tokens,
      uint256 nextOffset,
      uint256 total
    )
  {
    uint256 tokenInfoLength = tokenIds.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > tokenInfoLength - _offset) {
      _limit = tokenInfoLength - _offset;
    }

    TokenInfo[] memory values = new TokenInfo[](_limit);
    for (uint256 i = 0; i < _limit; i++) {
      uint256 tokenId = tokenIds[_offset + i];
      values[i] = tokenInfo[tokenId];
    }

    return (values, _offset + _limit, tokenInfoLength);
  }

  /**
   * @dev Checks that the token was owned by the sender.
   * @param _tokenId uint256 ID of the token.
   */
  function _onlyTokenOwner(uint256 _tokenId) internal view {
    uint256 balance = balanceOf(msg.sender, _tokenId);
    require(balance > 0, "owner");
  }

  /**
   * @dev Checks that the token was created by the sender.
   * @param _tokenId uint256 ID of the token.
   */
  function _onlyTokenCreator(uint256 _tokenId) internal view {
    address creator = tokenInfo[_tokenId].creator;
    require(creator == msg.sender, "creator");
  }

  /**
   * @dev restore data from old contract, only call by owner
   * @param _oldAddress address of old contract.
   * @param _startIndex start index of array
   * @param _endIndex end index of array
   */
  function restore(
    address _oldAddress,
    uint256 _startIndex,
    uint256 _endIndex
  ) external onlyOwner {
    Nafter oldContract = Nafter(_oldAddress);

    for (uint256 i = _startIndex; i < _endIndex; i++) {
      uint256 tokenId = oldContract.getTokenId(i);
      tokenIds.push(tokenId);
      tokenInfo[tokenId] = TokenInfo(
        tokenId,
        oldContract.creatorOfToken(tokenId),
        oldContract.getTokenAmount(tokenId),
        oldContract.getOwners(tokenId),
        oldContract.getServiceFee(tokenId),
        oldContract.getCreationTime(tokenId)
      );

      address[] memory owners = tokenInfo[tokenId].owners;
      for (uint256 j = 0; j < owners.length; j++) {
        address owner = owners[j];
        tokenOwnerInfo[tokenId][owner] = TokenOwnerInfo(
          oldContract.getIsForSale(tokenId, owner),
          oldContract.getPriceType(tokenId, owner),
          oldContract.getPrices(tokenId, owner),
          oldContract.getBids(tokenId, owner),
          oldContract.getBidders(tokenId, owner)
        );

        uint256 ownerBalance = oldContract.balanceOf(owner, tokenId);
        if (ownerBalance > 0) {
          _mint(owner, tokenId, ownerBalance, "");
        }
      }
      tokenIdsAvailable[tokenId] = true;
    }
    maxId = oldContract.maxId();
  }

  /**
   * @dev update or mint token Amount only from token creator.
   * @param _tokenAmount token Amount
   * @param _tokenId uint256 id of the token.
   */
  function setTokenAmount(uint256 _tokenAmount, uint256 _tokenId) external {
    _onlyTokenCreator(_tokenId);
    tokenInfo[_tokenId].tokenAmount = tokenInfo[_tokenId].tokenAmount + _tokenAmount;
    _mint(msg.sender, _tokenId, _tokenAmount, "");
  }

  /**
   * @dev update is for sale only from token Owner.
   * @param _isForSale is For Sale
   * @param _tokenId uint256 id of the token.
   */
  function setIsForSale(bool _isForSale, uint256 _tokenId) external {
    _onlyTokenOwner(_tokenId);
    tokenOwnerInfo[_tokenId][msg.sender].isForSale = _isForSale;
  }

  /**
   * @dev update is for sale only from token Owner.
   * @param _priceType set the price type
   * @param _price price of the token
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function putOnSale(
    uint8 _priceType,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) external {
    _onlyTokenOwner(_tokenId);
    _putOnSale(_owner, _priceType, _price, _startTime, _endTime, _tokenId, _paymentMode);
  }

  /**
   * @dev remove token from sale
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _tokenId, address _owner) external override {
    uint256 balance = balanceOf(msg.sender, _tokenId);
    require(balance > 0 || msg.sender == address(marketAuction), "owner");

    tokenOwnerInfo[_tokenId][_owner].isForSale = false;
  }

  /**
   * @dev update price type from token Owner.
   * @param _priceType price type
   * @param _tokenId uint256 id of the token.
   */
  function setPriceType(uint8 _priceType, uint256 _tokenId) external {
    _onlyTokenOwner(_tokenId);
    tokenOwnerInfo[_tokenId][msg.sender].priceType = _priceType;
  }

  /**
   * @dev set marketAuction address to set the sale price
   * @param _marketAuction address of market auction.
   * @param _marketplaceSettings address of market auction.
   */
  function setMarketAddresses(
    address _marketAuction,
    address _marketplaceSettings,
    address _tokenCreatorRegistry,
    address _royaltyRegistry
  ) external onlyOwner {
    marketAuction = INafterMarketAuction(_marketAuction);
    marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    tokenCreatorRegistry = INafterTokenCreatorRegistry(_tokenCreatorRegistry);
    royaltyRegistry = INafterRoyaltyRegistry(_royaltyRegistry);
  }

  /**
   * @dev update price only from auction.
   * @param _price price of the token
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setPrice(
    uint256 _price,
    uint256 _tokenId,
    address _owner
  ) external override {
    require(msg.sender == address(marketAuction), "only nma");
    TokenOwnerInfo storage info = tokenOwnerInfo[_tokenId][_owner];
    info.prices.push(_price);
  }

  /**
   * @dev update bids only from auction.
   * @param _bid bid Amount
   * @param _bidder bidder address
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setBid(
    uint256 _bid,
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) external override {
    require(msg.sender == address(marketAuction), "only nma");
    TokenOwnerInfo storage info = tokenOwnerInfo[_tokenId][_owner];
    info.bids.push(_bid);
    info.bidders.push(_bidder);
  }

  // /**
  //  * @dev add token and set the price.
  //  * @param _price price of the item.
  //  * @param _tokenAmount total token amount available
  //  * @param _isForSale if is for sale
  //  * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
  //  * @param _royaltyPercentage royalty percentage of creator
  //  * @param _startTime start time of bid, pass 0 of _priceType is not 1
  //  * @param _endTime end time of bid, pass 0 of _priceType is not 1
  //  * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
  //  */
  // function addNewTokenAndSetThePrice(
  //   uint256 _tokenAmount,
  //   bool _isForSale,
  //   uint256 _price,
  //   uint8 _priceType,
  //   uint8 _royaltyPercentage,
  //   uint256 _startTime,
  //   uint256 _endTime,
  //   uint8 _paymentMode
  // ) external {
  //   uint256 tokenId = getTokenIdAvailable();
  //   addNewTokenAndSetThePriceWithId(
  //     _tokenAmount,
  //     _isForSale,
  //     _price,
  //     _priceType,
  //     _royaltyPercentage,
  //     _startTime,
  //     _endTime,
  //     tokenId,
  //     _paymentMode
  //   );
  // }

  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 ID of the token.
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function addNewTokenAndSetThePriceWithId(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode
  ) public {
    uint256 tokenId = _createTokenWithId(
      msg.sender,
      _tokenAmount,
      _isForSale,
      _price,
      _priceType,
      _royaltyPercentage,
      _tokenId,
      msg.sender
    );
    _putOnSale(msg.sender, _priceType, _price, _startTime, _endTime, tokenId, _paymentMode);

    emit AddNewToken(msg.sender, tokenId);
  }

  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 ID of the token.
   * @param _creator address of the creator
   * @param _minter address of minter
   */
  function addNewTokenAndSetThePriceWithIdAndMinter(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _creator,
    address _minter
  ) external override onlyRole(MINTER_ROLE) {
    _createTokenWithId(_creator, _tokenAmount, _isForSale, _price, _priceType, _royaltyPercentage, _tokenId, _minter);
  }

  /**
   * @dev Deletes the token with the provided ID.
   * @param _tokenId uint256 ID of the token.
   * @param _amount amount of the token to delete
   */
  function deleteToken(uint256 _tokenId, uint256 _amount) public {
    _onlyTokenOwner(_tokenId);
    bool activeBid = marketAuction.hasTokenActiveBid(_tokenId, msg.sender);
    uint256 balance = balanceOf(msg.sender, _tokenId);
    //2
    if (activeBid == true) require(balance - _amount > 0, "active bid");
    _burn(msg.sender, _tokenId, _amount);
    DeleteTokens(msg.sender, _tokenId, _amount);
  }

  /**
   * @dev internal function to put on sale.
   * @param _priceType set the price type
   * @param _price price of the token
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _owner owner of the token
   * @param _tokenId uint256 id of the token.
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function _putOnSale(
    address _owner,
    uint8 _priceType,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode
  ) internal {
    require(marketAuction.hasTokenActiveBid(_tokenId, msg.sender) == false, "bid");
    if (_priceType == 0) {
      marketAuction.setSalePrice(_tokenId, _price, _owner, _paymentMode);
    }
    if (_priceType == 1 || _priceType == 2) {
      marketAuction.setInitialBidPriceWithRange(_price, _startTime, _endTime, _owner, _tokenId, _paymentMode);
    }
    tokenOwnerInfo[_tokenId][_owner].isForSale = true;
    tokenOwnerInfo[_tokenId][_owner].priceType = _priceType;
  }

  /**
   * @dev redeem to add a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _signature data signature to return account information
   */
  function verify(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature
  ) external view override {
    require(tokenIdsAvailable[_tokenId] == false, "id exist");
    require(
      ECDSAUpgradeable.recover(
        _hash(
          _creator,
          _tokenAmount,
          _isForSale,
          _price,
          _priceType,
          _royaltyPercentage,
          _startTime,
          _endTime,
          _tokenId,
          _paymentMode
        ),
        _signature
      ) == _creator,
      "Invalid signature"
    );
  }

  /**
   * @dev Sets uri of tokens.
   *
   * Requirements:
   *
   * @param _uri new uri .
   */
  function setURI(string memory _uri) external onlyOwner {
    _setURI(_uri);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    //transfer case
    if (msg.sender != address(marketAuction)) {
      bool activeBid = marketAuction.hasTokenActiveBid(id, from);
      if (activeBid == true) require(balanceOf(from, id) - amount > 0, "active bid");
    }
    super.safeTransferFrom(from, to, id, amount, data);
    for (uint256 i = 0; i < tokenInfo[id].owners.length; i++) {
      if (tokenInfo[id].owners[i] == to)
        //incase owner already exists
        return;
    }
    tokenInfo[id].owners.push(to);
  }

  /**
   * @dev Internal function creating a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 token id
   */
  function _createTokenWithId(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _minter
  ) internal returns (uint256) {
    require(tokenIdsAvailable[_tokenId] == false, "id exist");

    tokenIdsAvailable[_tokenId] = true;
    tokenIds.push(_tokenId);

    maxId = maxId > _tokenId ? maxId : _tokenId;

    _mint(_minter, _tokenId, _tokenAmount, "");

    tokenInfo[_tokenId] = TokenInfo(
      _tokenId,
      _creator,
      _tokenAmount,
      new address[](0),
      marketplaceSettings.getMarketplaceFeePercentage(),
      block.timestamp
    );

    tokenInfo[_tokenId].owners.push(_creator);

    tokenOwnerInfo[_tokenId][_creator] = TokenOwnerInfo(
      _isForSale,
      _priceType,
      new uint256[](0),
      new uint256[](0),
      new address[](0)
    );
    tokenOwnerInfo[_tokenId][_creator].prices.push(_price);

    royaltyRegistry.setPercentageForTokenRoyalty(_tokenId, _royaltyPercentage);
    tokenCreatorRegistry.setTokenCreator(_tokenId, payable(_creator));

    return _tokenId;
  }

  /**
   * @dev calculate the hash internal function
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function _hash(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode
  ) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "NafterNFT(address _creator,uint256 _tokenAmount,bool _isForSale,uint256 _price,uint8 _priceType,uint8 _royaltyPercentage,uint256 _startTime,uint256 _endTime,uint256 _tokenId,uint8 _paymentMode)"
            ),
            _creator,
            _tokenAmount,
            _isForSale,
            _price,
            _priceType,
            _royaltyPercentage,
            _startTime,
            _endTime,
            _tokenId,
            _paymentMode
          )
        )
      );
  }

  /**
   * @dev get last token id
   */
  function getLastTokenId() external view returns (uint256) {
    return tokenIds[tokenIds.length - 1];
  }

  /**
   * @dev get the token id available
   */
  function getTokenIdAvailable() public view returns (uint256) {
    for (uint256 i = 0; i < maxId; i++) {
      if (tokenIdsAvailable[i] == false) return i;
    }
    return tokenIds.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 */
interface INafterTokenCreatorRegistry {
  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function tokenCreator(uint256 _tokenId) external view returns (address payable);

  /**
   * @dev Sets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @param _creator address of the creator for the token
   */
  function setTokenCreator(uint256 _tokenId, address payable _creator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC1155TokenCreator.sol";

/**
 * @title IERC1155CreatorRoyalty Token level royalty interface.
 */
interface INafterRoyaltyRegistry is IERC1155TokenCreator {
  /**
   * @dev Get the royalty fee percentage for a specific ERC1155 contract.
   * @param _tokenId uint256 token ID.
   * @return uint8 wei royalty fee.
   */
  function getTokenRoyaltyPercentage(uint256 _tokenId) external view returns (uint8);

  /**
   * @dev Utililty function to calculate the royalty fee for a token.
   * @param _tokenId uint256 token ID.
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculateRoyaltyFee(uint256 _tokenId, uint256 _amount) external view returns (uint256);

  /**
     * @dev Sets the royalty percentage set for an Nafter token
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract or the creator can call this method.
     * @param _tokenId uint256 token ID.
     * @param _percentage uint8 wei royalty fee.
     */
  function setPercentageForTokenRoyalty(uint256 _tokenId, uint8 _percentage) external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface INafterMarketAuction {
  /**
   * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
   * @param _tokenId uint256 ID of the token
   * @param _amount uint256 wei value that the item is for sale
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setSalePrice(
    uint256 _tokenId,
    uint256 _amount,
    address _owner,
    uint8 _paymentMode
  ) external;

  /**
   * @dev set
   * @param _bidAmount uint256 value in wei to bid.
   * @param _startTime end time of bid
   * @param _endTime end time of bid
   * @param _owner address of the token owner
   * @param _tokenId uint256 ID of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setInitialBidPriceWithRange(
    uint256 _bidAmount,
    uint256 _startTime,
    uint256 _endTime,
    address _owner,
    uint256 _tokenId,
    uint8 _paymentMode
  ) external;

  /**
   * @dev has active bid
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function hasTokenActiveBid(uint256 _tokenId, address _owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface for interacting with the Nafter contract that holds Nafter beta tokens.
 */
interface INafter {
  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function creatorOfToken(uint256 _tokenId) external view returns (address payable);

  /**
   * @dev Gets the Service Fee
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function getServiceFee(uint256 _tokenId) external view returns (uint8);

  /**
   * @dev Gets the price type
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return get the price type
   */
  function getPriceType(uint256 _tokenId, address _owner) external view returns (uint8);

  /**
   * @dev update price only from auction.
   * @param _price price of the token
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setPrice(
    uint256 _price,
    uint256 _tokenId,
    address _owner
  ) external;

  /**
   * @dev update bids only from auction.
   * @param _bid bid Amount
   * @param _bidder bidder address
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setBid(
    uint256 _bid,
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) external;

  /**
   * @dev remove token from sale
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _tokenId, address _owner) external;

  /**
   * @dev get tokenIds length
   */
  function getTokenIdsLength() external view returns (uint256);

  /**
   * @dev get token Id
   * @param _index uint256 index
   */
  function getTokenId(uint256 _index) external view returns (uint256);

  /**
   * @dev Gets the owners
   * @param _tokenId uint256 ID of the token
   */
  function getOwners(uint256 _tokenId) external view returns (address[] memory owners);

  /**
   * @dev Gets the is for sale
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getIsForSale(uint256 _tokenId, address _owner) external view returns (bool);

  // function getTokenInfo(uint256 _tokenId)
  //       external
  //       view
  //       returns (
  //           address,
  //           uint256,
  //           address[] memory,
  //           uint8,
  //           uint256
  // );
  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 ID of the token.
   * @param _creator address of the creator
   * @param _minter address of minter
   */
  function addNewTokenAndSetThePriceWithIdAndMinter(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _creator,
    address _minter
  ) external;

  /**
   * @dev redeem to add a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function verify(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature
  ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title IMarketplaceSettings Settings governing a marketplace.
 */
interface IMarketplaceSettings {
  /////////////////////////////////////////////////////////////////////////
  // Marketplace Min and Max Values
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Get the max value to be used with the marketplace.
   * @return uint256 wei value.
   */
  function getMarketplaceMaxValue() external view returns (uint256);

  /**
   * @dev Get the max value to be used with the marketplace.
   * @return uint256 wei value.
   */
  function getMarketplaceMinValue() external view returns (uint256);

  /////////////////////////////////////////////////////////////////////////
  // Marketplace Fee
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Get the marketplace fee percentage.
   * @return uint8 wei fee.
   */
  function getMarketplaceFeePercentage() external view returns (uint8);

  /**
   * @dev Utility function for calculating the marketplace fee for given amount of wei.
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculateMarketplaceFee(uint256 _amount) external view returns (uint256);

  /////////////////////////////////////////////////////////////////////////
  // Primary Sale Fee
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Get the primary sale fee percentage for a specific ERC1155 contract.
   * @return uint8 wei primary sale fee.
   */
  function getERC1155ContractPrimarySaleFeePercentage() external view returns (uint8);

  /**
   * @dev Utility function for calculating the primary sale fee for given amount of wei
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculatePrimarySaleFee(uint256 _amount) external view returns (uint256);

  /**
   * @dev Check whether the ERC1155 token has sold at least once.
   * @param _tokenId uint256 token ID.
   * @return bool of whether the token has sold.
   */
  function hasTokenSold(uint256 _tokenId) external view returns (bool);

  /**
     * @dev Mark a token as sold.

     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.

     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
  function markERC1155Token(uint256 _tokenId, bool _hasSold) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
interface IERC1155TokenCreator {
  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function tokenCreator(uint256 _tokenId) external view returns (address payable);
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

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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
        return msg.data;
    }
    uint256[50] private __gap;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

