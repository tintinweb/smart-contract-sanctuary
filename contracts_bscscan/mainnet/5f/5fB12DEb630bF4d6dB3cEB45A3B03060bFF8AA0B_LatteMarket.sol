// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./ILatteNFT.sol";
import "./IWNativeRelayer.sol";
import "./IWETH.sol";
import "./SafeToken.sol";

contract LatteMarket is ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  struct BidEntry {
    address bidder;
    uint256 price;
  }

  struct LatteNFTMetadataParam {
    address nftAddress;
    uint256 nftCategoryId;
    uint256 cap;
    uint256 startBlock;
    uint256 endBlock;
  }

  struct LatteNFTMetadata {
    uint256 cap;
    uint256 startBlock;
    uint256 endBlock;
    bool isBidding;
    uint256 price;
    IERC20Upgradeable quoteBep20;
  }

  mapping(address => bool) public isNFTSupported;
  address public feeAddr;
  uint256 public feePercentBps;
  IWNativeRelayer public wNativeRelayer;
  address public wNative;
  mapping(address => mapping(uint256 => address)) public tokenCategorySellers;
  mapping(address => mapping(uint256 => BidEntry)) public tokenBid;

  // latte original nft related
  mapping(address => mapping(uint256 => LatteNFTMetadata)) public latteNFTMetadata;

  event Trade(
    address indexed seller,
    address indexed buyer,
    address nftAddress,
    uint256 indexed nftCategoryId,
    uint256 price,
    uint256 fee,
    uint256 size
  );
  event Ask(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    uint256 price,
    IERC20Upgradeable quoteToken
  );
  event SetLatteNFTMetadata(
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    uint256 cap,
    uint256 startBlock,
    uint256 endBlock
  );
  event CancelSellNFT(address indexed seller, address indexed nftAddress, uint256 indexed nftCategoryId);
  event FeeAddressTransferred(address indexed previousOwner, address indexed newOwner);
  event SetFeePercent(address indexed seller, uint256 oldFeePercent, uint256 newFeePercent);
  event Bid(address indexed bidder, address indexed nftAddress, uint256 indexed nftCategoryId, uint256 price);
  event CancelBidNFT(address indexed bidder, address indexed nftAddress, uint256 indexed nftCategoryId);
  event SetSupportNFT(address indexed nftAddress, bool isSupported);
  event Pause();
  event Unpause();

  function initialize(
    address _feeAddr,
    uint256 _feePercentBps,
    IWNativeRelayer _wNativeRelayer,
    address _wNative
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    ERC721HolderUpgradeable.__ERC721Holder_init();
    AccessControlUpgradeable.__AccessControl_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());

    feeAddr = _feeAddr;
    feePercentBps = _feePercentBps;
    wNativeRelayer = _wNativeRelayer;
    wNative = _wNative;
    emit FeeAddressTransferred(address(0), feeAddr);
    emit SetFeePercent(_msgSender(), 0, feePercentBps);
  }

  /**
   * @notice check address
   */
  modifier validAddress(address _addr) {
    require(_addr != address(0));
    _;
  }

  /// @notice check whether this particular nft address is supported by the contract
  modifier onlySupportedNFT(address _nft) {
    require(isNFTSupported[_nft], "LatteMarket::onlySupportedNFT::unsupported nft");
    _;
  }

  /// @notice only GOVERNANCE ROLE (role that can setup NON sensitive parameters) can continue the execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "LatteMarket::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @notice if the block number is not within the start and end block number, reverted
  modifier withinBlockRange(address _nftAddress, uint256 _categoryId) {
    require(
      block.number >= latteNFTMetadata[_nftAddress][_categoryId].startBlock &&
        block.number <= latteNFTMetadata[_nftAddress][_categoryId].endBlock,
      "LatteMarket::withinBlockRange:: invalid block number"
    );
    _;
  }

  /// @notice only verified signature can continue a statement
  modifier permit(bytes calldata _sig) {
    address recoveredAddress = ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(SIGNATURE_HASH), _sig);
    require(recoveredAddress == _msgSender(), "LatteMarket::permit::INVALID_SIGNATURE");
    _;
  }

  modifier onlyBiddingNFT(address _nftAddress, uint256 _categoryId) {
    require(
      latteNFTMetadata[_nftAddress][_categoryId].isBidding,
      "LatteMarket::onlyBiddingNFT::only bidding token can be used here"
    );
    _;
  }

  modifier onlyNonBiddingNFT(address _nftAddress, uint256 _categoryId) {
    require(
      !latteNFTMetadata[_nftAddress][_categoryId].isBidding,
      "LatteMarket::onlyNonBiddingNFT::only selling token can be used here"
    );
    _;
  }

  /// @dev set LATTE NFT metadata consisted of cap, startBlock, and endBlock
  function setLatteNFTMetadata(LatteNFTMetadataParam[] calldata _params) external onlyGovernance {
    for (uint256 i = 0; i < _params.length; i++) {
      require(isNFTSupported[_params[i].nftAddress], "LatteMarket::setLatteNFTMetadata::unsupported nft");
      _setLatteNFTMetadata(_params[i]);
    }
  }

  function _setLatteNFTMetadata(LatteNFTMetadataParam memory _param) internal {
    require(
      _param.startBlock > block.number && _param.endBlock > _param.startBlock,
      "LatteMarket::_setLatteNFTMetadata::invalid start or end block"
    );
    LatteNFTMetadata storage metadata = latteNFTMetadata[_param.nftAddress][_param.nftCategoryId];
    metadata.cap = _param.cap;
    metadata.startBlock = _param.startBlock;
    metadata.endBlock = _param.endBlock;

    emit SetLatteNFTMetadata(_param.nftAddress, _param.nftCategoryId, _param.cap, _param.startBlock, _param.endBlock);
  }

  /// @dev set supported NFT for the contract
  function setSupportNFT(address[] calldata _nft, bool _isSupported) external onlyGovernance {
    for (uint256 i = 0; i < _nft.length; i++) {
      isNFTSupported[_nft[i]] = _isSupported;
      emit SetSupportNFT(_nft[i], _isSupported);
    }
  }

  /// @notice buyNFT based on its category id
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _sig - signed signature using message sign
  function buyNFT(
    address _nftAddress,
    uint256 _categoryId,
    bytes calldata _sig
  )
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    withinBlockRange(_nftAddress, _categoryId)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    permit(_sig)
  {
    _buyNFTTo(_nftAddress, _categoryId, _msgSender(), 1);
  }

  /// @notice buyNFT based on its category id
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _size - amount to buy
  /// @param _sig - signed signature using message sign
  function buyBatchNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _size,
    bytes calldata _sig
  )
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    permit(_sig)
  {
    LatteNFTMetadata memory metadata = latteNFTMetadata[_nftAddress][_categoryId];
    /// re-use a storage usage by using the same metadata to validate
    /// multiple modifiers can cause stack too deep exception
    require(
      block.number >= metadata.startBlock && block.number <= metadata.endBlock,
      "LatteMarket::buyBatchNFT:: invalid block number"
    );
    _buyNFTTo(_nftAddress, _categoryId, _msgSender(), _size);
  }

  /// @dev use to decrease a total cap by 1, will get reverted if no more to be decreased
  function _decreaseCap(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _size
  ) internal {
    require(
      latteNFTMetadata[_nftAddress][_categoryId].cap >= _size,
      "LatteMarket::_decreaseCap::maximum mint cap reached"
    );
    latteNFTMetadata[_nftAddress][_categoryId].cap = latteNFTMetadata[_nftAddress][_categoryId].cap.sub(_size);
  }

  /// @notice buyNFT based on its category id
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _to whom this will be bought to
  /// @param _sig - signed signature using message sign
  function buyNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    address _to,
    bytes calldata _sig
  )
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    withinBlockRange(_nftAddress, _categoryId)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    permit(_sig)
  {
    _buyNFTTo(_nftAddress, _categoryId, _to, 1);
  }

  /// @dev internal method for buyNFTTo to avoid stack-too-deep
  function _buyNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    address _to,
    uint256 _size
  ) internal {
    _decreaseCap(_nftAddress, _categoryId, _size);
    LatteNFTMetadata memory metadata = latteNFTMetadata[_nftAddress][_categoryId];
    uint256 totalPrice = metadata.price.mul(_size);
    uint256 feeAmount = totalPrice.mul(feePercentBps).div(1e4);
    _safeWrap(metadata.quoteBep20, totalPrice);
    if (feeAmount != 0) {
      metadata.quoteBep20.safeTransfer(feeAddr, feeAmount);
    }
    metadata.quoteBep20.safeTransfer(tokenCategorySellers[_nftAddress][_categoryId], totalPrice.sub(feeAmount));
    ILatteNFT(_nftAddress).mintBatch(_to, _categoryId, "", _size);
    emit Trade(
      tokenCategorySellers[_nftAddress][_categoryId],
      _to,
      _nftAddress,
      _categoryId,
      totalPrice,
      feeAmount,
      _size
    );
  }

  /// @dev set a current price of a nftaddress with the following categoryId
  function setCurrentPrice(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    IERC20Upgradeable _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    _setCurrentPrice(_nftAddress, _categoryId, _price, _quoteToken);
  }

  function _setCurrentPrice(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    IERC20Upgradeable _quoteToken
  ) internal {
    require(address(_quoteToken) != address(0), "LatteMarket::_setCurrentPrice::invalid quote token");
    latteNFTMetadata[_nftAddress][_categoryId].price = _price;
    latteNFTMetadata[_nftAddress][_categoryId].quoteBep20 = _quoteToken;
    emit Ask(_msgSender(), _nftAddress, _categoryId, _price, _quoteToken);
  }

  /// @notice this needs to be called when the seller want to SELL the token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _price - price of a token
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToSellNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20Upgradeable _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    _readyToSellNFTTo(
      _nftAddress,
      _categoryId,
      _price,
      address(_msgSender()),
      _cap,
      _startBlock,
      _endBlock,
      _quoteToken
    );
  }

  /// @notice this needs to be called when the seller want to start AUCTION the token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _price - starting price of a token
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToStartAuction(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20Upgradeable _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    latteNFTMetadata[_nftAddress][_categoryId].isBidding = true;
    _readyToSellNFTTo(
      _nftAddress,
      _categoryId,
      _price,
      address(_msgSender()),
      _cap,
      _startBlock,
      _endBlock,
      _quoteToken
    );
  }

  /// @notice this needs to be called when the seller want to start AUCTION the token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _price - starting price of a token
  /// @param _to - whom this token is selling to
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToSellNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    address _to,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20Upgradeable _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    _readyToSellNFTTo(_nftAddress, _categoryId, _price, _to, _cap, _startBlock, _endBlock, _quoteToken);
  }

  /// @dev an internal function for readyToSellNFTTo
  function _readyToSellNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    address _to,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20Upgradeable _quoteToken
  ) internal {
    require(
      latteNFTMetadata[_nftAddress][_categoryId].startBlock == 0,
      "LatteMarket::_readyToSellNFTTo::duplicated entry"
    );
    tokenCategorySellers[_nftAddress][_categoryId] = _to;
    _setLatteNFTMetadata(
      LatteNFTMetadataParam({
        cap: _cap,
        startBlock: _startBlock,
        endBlock: _endBlock,
        nftAddress: _nftAddress,
        nftCategoryId: _categoryId
      })
    );
    _setCurrentPrice(_nftAddress, _categoryId, _price, _quoteToken);
  }

  /// @notice cancel selling token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  function cancelSellNFT(address _nftAddress, uint256 _categoryId)
    external
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    onlyGovernance
  {
    _cancelSellNFT(_nftAddress, _categoryId);
    emit CancelSellNFT(_msgSender(), _nftAddress, _categoryId);
  }

  /// @notice cancel a bidding token, similar to cancel sell, with functionalities to return bidding amount back to the user
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  function cancelBiddingNFT(address _nftAddress, uint256 _categoryId)
    external
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyGovernance
    onlyBiddingNFT(_nftAddress, _categoryId)
  {
    BidEntry memory bidEntry = tokenBid[_nftAddress][_categoryId];
    require(bidEntry.bidder == address(0), "LatteMarket::cancelBiddingNFT::auction already has a bidder");
    _delBidByCompositeId(_nftAddress, _categoryId);
    _cancelSellNFT(_nftAddress, _categoryId);
    emit CancelBidNFT(bidEntry.bidder, _nftAddress, _categoryId);
  }

  /// @dev internal function for cancelling a selling token
  function _cancelSellNFT(address _nftAddress, uint256 _categoryId) internal {
    delete tokenCategorySellers[_nftAddress][_categoryId];
    delete latteNFTMetadata[_nftAddress][_categoryId];
  }

  function pause() external onlyGovernance whenNotPaused {
    _pause();
    emit Pause();
  }

  function unpause() external onlyGovernance whenPaused {
    _unpause();
    emit Unpause();
  }

  /// @dev set a new feeAddress
  function setTransferFeeAddress(address _feeAddr) external onlyOwner {
    feeAddr = _feeAddr;
    emit FeeAddressTransferred(_msgSender(), feeAddr);
  }

  /// @dev set a new fee Percentage BPS
  function setFeePercent(uint256 _feePercentBps) external onlyOwner {
    require(feePercentBps != _feePercentBps, "LatteMarket::setFeePercent::Not need update");
    require(feePercentBps <= 1e4, "LatteMarket::setFeePercent::percent exceed 100%");
    emit SetFeePercent(_msgSender(), feePercentBps, _feePercentBps);
    feePercentBps = _feePercentBps;
  }

  /// @notice use for only bidding token, this method is for bidding the following nft
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id
  /// @param _price - bidding price
  /// @param _sig - signature
  function bidNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    bytes calldata _sig
  )
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    withinBlockRange(_nftAddress, _categoryId)
    onlyBiddingNFT(_nftAddress, _categoryId)
    permit(_sig)
  {
    _bidNFT(_nftAddress, _categoryId, _price);
  }

  function _bidNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price
  ) internal {
    address _seller = tokenCategorySellers[_nftAddress][_categoryId];
    address _to = address(_msgSender());
    require(_seller != _to, "LatteMarket::_bidNFT::Owner cannot bid");
    require(
      latteNFTMetadata[_nftAddress][_categoryId].price < _price,
      "LatteMarket::_bidNFT::price cannot be lower than or equal to the starting bid"
    );
    if (tokenBid[_nftAddress][_categoryId].bidder != address(0)) {
      require(
        tokenBid[_nftAddress][_categoryId].price < _price,
        "LatteMarket::_bidNFT::price cannot be lower than or equal to the latest bid"
      );
    }
    BidEntry memory prevBid = tokenBid[_nftAddress][_categoryId];
    _delBidByCompositeId(_nftAddress, _categoryId);
    tokenBid[_nftAddress][_categoryId] = BidEntry({ bidder: _to, price: _price });
    if (prevBid.bidder != address(0)) {
      _safeUnwrap(latteNFTMetadata[_nftAddress][_categoryId].quoteBep20, prevBid.bidder, prevBid.price);
    }
    _safeWrap(latteNFTMetadata[_nftAddress][_categoryId].quoteBep20, _price);
    emit Bid(_msgSender(), _nftAddress, _categoryId, _price);
  }

  function _delBidByCompositeId(address _nftAddress, uint256 _categoryId) internal {
    delete tokenBid[_nftAddress][_categoryId];
  }

  /// @notice this is like a process of releasing an nft for a quoteBep20, only used when the seller is satisfied with the bidding price
  /// @param _nftAddress an nft address
  /// @param _categoryId an nft category id
  function concludeAuction(address _nftAddress, uint256 _categoryId)
    external
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyBiddingNFT(_nftAddress, _categoryId)
    onlyGovernance
  {
    _concludeAuction(_nftAddress, _categoryId);
  }

  /// @dev internal function for sellNFTTo to avoid stack-too-deep
  function _concludeAuction(address _nftAddress, uint256 _categoryId) internal {
    require(
      block.number >= latteNFTMetadata[_nftAddress][_categoryId].endBlock,
      "LatteMarket::_concludeAuction::Unable to conclude auction now, bad block number"
    );
    address _seller = tokenCategorySellers[_nftAddress][_categoryId];
    _decreaseCap(_nftAddress, _categoryId, 1);
    BidEntry memory bidEntry = tokenBid[_nftAddress][_categoryId];
    require(bidEntry.price != 0, "LatteMarket::_concludeAuction::Bidder does not exist");
    uint256 price = bidEntry.price;
    uint256 feeAmount = price.mul(feePercentBps).div(1e4);
    _delBidByCompositeId(_nftAddress, _categoryId);
    if (feeAmount != 0) {
      latteNFTMetadata[_nftAddress][_categoryId].quoteBep20.safeTransfer(feeAddr, feeAmount);
    }
    latteNFTMetadata[_nftAddress][_categoryId].quoteBep20.safeTransfer(_seller, price.sub(feeAmount));
    ILatteNFT(_nftAddress).mint(bidEntry.bidder, _categoryId, "");
    emit Trade(
      tokenCategorySellers[_nftAddress][_categoryId],
      bidEntry.bidder,
      _nftAddress,
      _categoryId,
      price,
      feeAmount,
      1
    );
  }

  function _safeWrap(IERC20Upgradeable _quoteBep20, uint256 _amount) internal {
    if (msg.value != 0) {
      require(address(_quoteBep20) == wNative, "latteMarket::_safeWrap:: baseToken is not wNative");
      require(_amount == msg.value, "latteMarket::_safeWrap:: value != msg.value");
      IWETH(wNative).deposit{ value: msg.value }();
    } else {
      _quoteBep20.safeTransferFrom(_msgSender(), address(this), _amount);
    }
  }

  function _safeUnwrap(
    IERC20Upgradeable _quoteBep20,
    address _to,
    uint256 _amount
  ) internal {
    if (address(_quoteBep20) == wNative) {
      _quoteBep20.safeTransfer(address(wNativeRelayer), _amount);
      wNativeRelayer.withdraw(_amount);
      SafeToken.safeTransferETH(_to, _amount);
    } else {
      _quoteBep20.safeTransfer(_to, _amount);
    }
  }

  /// @notice get all bidding entries of the following nft
  function getBid(address _nftAddress, uint256 _categoryId) external view returns (BidEntry memory) {
    return tokenBid[_nftAddress][_categoryId];
  }

  /// @dev Fallback function to accept ETH. Workers will send ETH back the pool.
  receive() external payable {}
}