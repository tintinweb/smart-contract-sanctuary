// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MarketplaceStorage.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./SafeERC20.sol";

contract Marketplace is AccessControl, Pausable, MarketplaceStorage {
  using SafeERC20 for IERC20;
  using Address for address;
  using Counters for Counters.Counter;
  Counters.Counter private _orderIdCounter;

  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  uint256 public constant MILLION = 1000000;

  address public immutable owner;

  /**
   * @dev Initialize this contract. Acts as a constructor
   * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
   * @param _ownerCutPerMillion - owner cut per million
   * @param _publicationFeeInWei - publication fee in wei
   * @param _owner - marketplace owner
   */
  constructor(
    IERC20 _acceptedToken,
    uint256 _ownerCutPerMillion,
    uint256 _publicationFeeInWei,
    address _owner
  ) {
    require(_acceptedToken != IERC20(address(0)), "Invalid accepted token");
    require(_owner != address(0), "Invalid owner");

    acceptedToken = _acceptedToken;
    _setOwnerCutPerMillion(_ownerCutPerMillion);
    _setPublicationFee(_publicationFeeInWei);
    owner = _owner;

    _orderIdCounter.increment(); // order IDs start at 1 so that the null value is considered an invalid order ID

    _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    _setupRole(OPERATOR_ROLE, _owner);
  }

  /**
   * @dev Sets the publication fee that's charged to users to publish items
   * @param _publicationFeeInWei - Fee amount in wei this contract charges to publish an item
   */
  function setPublicationFee(uint256 _publicationFeeInWei)
    external
    onlyRole(OPERATOR_ROLE)
  {
    _setPublicationFee(_publicationFeeInWei);
  }

  /**
   * @dev See above
   */
  function _setPublicationFee(uint256 _publicationFeeInWei) private {
    publicationFeeInWei = _publicationFeeInWei;
    emit ChangedPublicationFee(publicationFeeInWei);
  }

  /**
   * @dev Sets the share cut for the owner of the contract that's
   *  charged to the seller on a successful sale
   * @param _ownerCutPerMillion - Share amount from 0 to MILLION
   */
  function setOwnerCutPerMillion(uint256 _ownerCutPerMillion)
    external
    onlyRole(OPERATOR_ROLE)
  {
    _setOwnerCutPerMillion(_ownerCutPerMillion);
  }

  /**
   * @dev See above
   */
  function _setOwnerCutPerMillion(uint256 _ownerCutPerMillion) private {
    require(_ownerCutPerMillion < MILLION, "Invalid owner cut");
    ownerCutPerMillion = _ownerCutPerMillion;
    emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
  }

  /**
   * @dev Creates a new order for an ERC20 or ERC721 token,
   *  passing the appropriate parameters depending on the token being sold. See below.
   * @param nftAddress - Non fungible registry address
   * @param assetId - ID of the ERC721 published NFT. Must be 0 if ERC20.
   * @param amount - amount of the ERC20 token. Must be 1 if ERC721.
   * @param priceInWei - Price in Wei for the supported coin
   * @param expiresAt - Duration of the order (in hours)
   */
  function createOrder(
    address nftAddress,
    uint256 assetId,
    uint256 amount,
    uint256 priceInWei,
    uint256 expiresAt
  ) external whenNotPaused {
    require(expiresAt < 10000000000, "Invalid expriration time");
    require(priceInWei > 0, "Price should be bigger than 0");
    // solhint-disable-next-line not-rely-on-time
    uint256 timestamp = block.timestamp;
    require(expiresAt > timestamp + 1 minutes, "Invalid expiration time");
    AssetType assetType = getAssetType(nftAddress);
    require(assetType != AssetType.NIL, "Invalid NFT address");

    if (assetType == AssetType.ERC20) {
      require(assetId == 0, "Invalid asset ID");
      IERC20 nft = IERC20(nftAddress);
      uint256 balance = nft.balanceOf(msg.sender);
      require(balance >= amount, "Insufficient balance");
      require(
        nft.allowance(msg.sender, address(this)) >= amount,
        "Marketplace unauthorized"
      );
    }
    // is AssetType.ERC721
    else {
      require(amount == 1, "Invalid amount");
      IERC721 nft = IERC721(nftAddress);
      address assetOwner = nft.ownerOf(assetId);

      require(msg.sender == assetOwner, "Only the owner can create orders");
      require(
        nft.getApproved(assetId) == address(this) ||
          nft.isApprovedForAll(assetOwner, address(this)),
        "Marketplace unauthorized"
      );
    }

    uint256 orderId = _orderIdCounter.current();
    _orderIdCounter.increment();

    _addOrder(
      Order({
        id: orderId,
        seller: msg.sender,
        nftAddress: nftAddress,
        tokenType: assetType,
        assetId: assetId,
        amount: amount,
        price: priceInWei,
        expiresAt: expiresAt
      })
    );

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInWei > 0) {
      acceptedToken.safeTransferFrom(msg.sender, owner, publicationFeeInWei);
    }

    emit OrderCreated(
      orderId,
      assetId,
      msg.sender,
      amount,
      nftAddress,
      priceInWei,
      expiresAt
    );
  }

  /**
   * @dev Cancel an already published order
   *  can only be canceled by seller or the contract owner
   * @param orderId - Order ID
   */
  function cancelOrder(uint256 orderId) external whenNotPaused {
    Order memory order = _getOrder(orderId);

    require(
      order.seller == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
      "Unauthorized user"
    );

    uint256 orderAssetId = order.assetId;
    address orderSeller = order.seller;
    address orderNftAddress = order.nftAddress;
    uint256 orderAmount = order.amount;

    _deleteOrder(orderId);

    emit OrderCancelled(
      orderId,
      orderAssetId,
      orderSeller,
      orderAmount,
      orderNftAddress
    );
  }

  /**
   * @dev Executes the sale for a published asset
   * @param orderId - Order ID
   */
  function executeOrder(uint256 orderId) external whenNotPaused {
    Order memory order = _getOrder(orderId);

    address seller = order.seller;
    require(seller != msg.sender, "Cannot sell to yourself");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < order.expiresAt, "The order expired");

    uint256 amount = order.amount;
    uint256 assetId = order.assetId;
    uint256 price = order.price;
    address nftAddress = order.nftAddress;
    AssetType assetType = order.tokenType;

    if (assetType == AssetType.ERC20) {
      IERC20 nft = IERC20(nftAddress);
      uint256 balance = nft.balanceOf(seller);
      require(balance >= amount, "Seller does not have balance");
    }
    // is AssetType.ERC721
    else {
      IERC721 nft = IERC721(nftAddress);
      require(seller == nft.ownerOf(assetId), "Seller is no longer the owner");
    }

    _deleteOrder(orderId);

    uint256 saleShareAmount = 0;
    if (ownerCutPerMillion > 0) {
      // Calculate sale share
      saleShareAmount = (price * ownerCutPerMillion) / MILLION;

      // Transfer share amount for marketplace Owner
      acceptedToken.safeTransferFrom(msg.sender, owner, saleShareAmount);
    }

    // Transfer sale amount to seller
    acceptedToken.safeTransferFrom(msg.sender, seller, price - saleShareAmount);

    // Transfer asset
    if (assetType == AssetType.ERC20) {
      IERC20 nft = IERC20(nftAddress);
      nft.safeTransferFrom(seller, msg.sender, amount);
    } else {
      IERC721 nft = IERC721(nftAddress);
      nft.safeTransferFrom(seller, msg.sender, assetId);
    }

    emit OrderExecuted(
      orderId,
      assetId,
      seller,
      amount,
      nftAddress,
      price,
      msg.sender
    );
  }

  function approveNFTs(NFT[] calldata _nfts) public onlyRole(OPERATOR_ROLE) {
    delete nfts;

    for (uint256 i = 0; i < _nfts.length; i++) {
      nfts.push(NFT({addr: _nfts[i].addr, tokenType: _nfts[i].tokenType}));
    }
  }

  function getAssetType(address nftAddress) public view returns (AssetType) {
    for (uint256 i = 0; i < nfts.length; i++) {
      if (nfts[i].addr == nftAddress) {
        return nfts[i].tokenType;
      }
    }
    return AssetType.NIL;
  }

  function getOrders() public view returns (Order[] memory) {
    return orders;
  }
}