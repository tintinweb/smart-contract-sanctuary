// SPDX-License-Identifier: GPL-3.0
//        .-.                               .-.
//       / (_)         /      /       .--.-'
//      /      .-. ---/------/---.-. (  (_)`)    (  .-.   .-.
//     /      (  |   /      /  ./.-'_ `-.  /  .   )(  |   /  )
//  .-/.    .-.`-'-'/      /   (__.'_    )(_.' `-'  `-'-'/`-'
// (_/ `-._.                       (_.--'               /

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
import "./IOGPriceModel.sol";

contract OGNFTOffering is ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  struct OGNFTMetadataParam {
    uint256 nftCategoryId;
    uint256 cap;
    uint256 startBlock;
    uint256 endBlock;
  }

  struct OGNFTMetadata {
    uint256 cap;
    uint256 maxCap;
    uint256 startBlock;
    uint256 endBlock;
    bool isBidding;
    IERC20Upgradeable quoteBep20;
  }

  struct OGNFTBuyLimitMetadata {
    uint256 counter;
    uint256 cooldownStartBlock;
  }

  address public ogNFT;
  address public feeAddr;
  uint256 public feePercentBps;
  uint256 public buyLimitCount;
  uint256 public buyLimitPeriod;
  IWNativeRelayer public wNativeRelayer;
  IOGPriceModel public priceModel;
  address public wNative;
  mapping(uint256 => address) public tokenCategorySellers;

  // og nft original nft related
  mapping(uint256 => OGNFTMetadata) public ogNFTMetadata;
  mapping(address => mapping(uint256 => OGNFTBuyLimitMetadata)) public buyLimitMetadata;

  event Trade(address indexed seller, address indexed buyer, uint256 indexed nftCategoryId, uint256 price, uint256 fee);
  event SetQuoteBep20(address indexed seller, uint256 indexed nftCategoryId, IERC20Upgradeable quoteToken);
  event SetOGNFTMetadata(uint256 indexed nftCategoryId, uint256 cap, uint256 startBlock, uint256 endBlock);
  event CancelSellNFT(address indexed seller, uint256 indexed nftCategoryId);
  event FeeAddressTransferred(address indexed previousOwner, address indexed newOwner);
  event SetFeePercent(address indexed seller, uint256 oldFeePercent, uint256 newFeePercent);
  event SetPriceModel(IOGPriceModel indexed newPriceModel);
  event SetBuyLimitCount(uint256 buyLimitCount);
  event SetBuyLimitPeriod(uint256 buyLimitPeriod);
  event UpdateBuyLimit(uint256 counter, uint256 cooldownStartBlock);
  event Pause();
  event Unpause();

  function initialize(
    address _ogNFT,
    address _feeAddr,
    uint256 _feePercentBps,
    IWNativeRelayer _wNativeRelayer,
    address _wNative,
    IOGPriceModel _priceModel
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    ERC721HolderUpgradeable.__ERC721Holder_init();
    AccessControlUpgradeable.__AccessControl_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());

    require(_ogNFT != address(0), "OGNFTOffering::initialize:: og nft cannot be address(0)");
    require(address(_priceModel) != address(0), "OGNFTOffering::initialize:: price model cannot be address(0)");

    ogNFT = _ogNFT;
    priceModel = _priceModel;
    feeAddr = _feeAddr;
    feePercentBps = _feePercentBps;
    wNativeRelayer = _wNativeRelayer;
    wNative = _wNative;
    buyLimitCount = 5;
    buyLimitPeriod = 100; //100 blocks, 5 mins

    emit SetPriceModel(_priceModel);
    emit SetBuyLimitCount(buyLimitCount);
    emit SetBuyLimitPeriod(buyLimitPeriod);
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

  /// @notice only GOVERNANCE ROLE (role that can setup NON sensitive parameters) can continue the execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "OGNFTOffering::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @notice if the block number is not within the start and end block number, reverted
  modifier withinBlockRange(uint256 _categoryId) {
    require(
      block.number >= ogNFTMetadata[_categoryId].startBlock && block.number <= ogNFTMetadata[_categoryId].endBlock,
      "OGNFTOffering::withinBlockRange:: invalid block number"
    );
    _;
  }

  /// @notice only verified signature can continue a statement
  modifier permit(bytes calldata _sig) {
    address recoveredAddress = ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(SIGNATURE_HASH), _sig);
    require(recoveredAddress == _msgSender(), "OGNFTOffering::permit::INVALID_SIGNATURE");
    _;
  }

  /// @notice set price model for getting a price
  function setPriceModel(IOGPriceModel _priceModel) external onlyOwner {
    require(address(_priceModel) != address(0), "OGNFTOffering::permit::price model cannot be address(0)");
    priceModel = _priceModel;
    emit SetPriceModel(_priceModel);
  }

  /// @notice set the maximum amount of nfts that can be bought within the period
  function setBuyLimitCount(uint256 _buyLimitCount) external onlyOwner {
    buyLimitCount = _buyLimitCount;
    emit SetBuyLimitCount(_buyLimitCount);
  }

  /// @notice set the buy limit period (in block number)
  /// @dev this will be use for a buy limit mechanism
  /// within this period, the user can only buy nfts at limited amount. (using buyLimitCount as a comparator)
  function setBuyLimitPeriod(uint256 _buyLimitPeriod) external onlyOwner {
    buyLimitPeriod = _buyLimitPeriod;
    emit SetBuyLimitPeriod(_buyLimitPeriod);
  }

  /// @dev set OG NFT metadata consisted of cap, startBlock, and endBlock
  function setOGNFTMetadata(OGNFTMetadataParam[] calldata _params) external onlyGovernance {
    for (uint256 i = 0; i < _params.length; i++) {
      _setOGNFTMetadata(_params[i]);
    }
  }

  function _setOGNFTMetadata(OGNFTMetadataParam memory _param) internal {
    require(
      _param.startBlock > block.number && _param.endBlock > _param.startBlock,
      "OGNFTOffering::_setOGNFTMetadata::invalid start or end block"
    );
    OGNFTMetadata storage metadata = ogNFTMetadata[_param.nftCategoryId];
    metadata.cap = _param.cap;
    metadata.maxCap = _param.cap;
    metadata.startBlock = _param.startBlock;
    metadata.endBlock = _param.endBlock;

    emit SetOGNFTMetadata(_param.nftCategoryId, _param.cap, _param.startBlock, _param.endBlock);
  }

  /// @dev set a current quoteBep20 of an og with the following categoryId
  function setQuoteBep20(uint256 _categoryId, IERC20Upgradeable _quoteToken) external whenNotPaused onlyGovernance {
    _setQuoteBep20(_categoryId, _quoteToken);
  }

  function _setQuoteBep20(uint256 _categoryId, IERC20Upgradeable _quoteToken) internal {
    require(address(_quoteToken) != address(0), "OGNFTOffering::_setQuoteBep20::invalid quote token");
    ogNFTMetadata[_categoryId].quoteBep20 = _quoteToken;
    emit SetQuoteBep20(_msgSender(), _categoryId, _quoteToken);
  }

  /// @notice buyNFT based on its category id
  /// @param _categoryId - category id for each nft address
  /// @param _sig - signed signature using message sign
  function buyNFT(uint256 _categoryId, bytes calldata _sig)
    external
    payable
    whenNotPaused
    withinBlockRange(_categoryId)
    permit(_sig)
  {
    _buyNFTTo(_categoryId, _msgSender());
  }

  /// @dev use to decrease a total cap by 1, will get reverted if no more to be decreased
  function _decreaseCap(uint256 _categoryId, uint256 _size) internal {
    require(ogNFTMetadata[_categoryId].cap >= _size, "OGNFTOffering::_decreaseCap::maximum mint cap reached");
    ogNFTMetadata[_categoryId].cap = ogNFTMetadata[_categoryId].cap.sub(_size);
  }

  /// @dev internal method for buyNFTTo to avoid stack-too-deep
  function _buyNFTTo(uint256 _categoryId, address _to) internal {
    _decreaseCap(_categoryId, 1);
    OGNFTMetadata memory metadata = ogNFTMetadata[_categoryId];
    uint256 price = priceModel.getPrice(metadata.maxCap, metadata.cap, _categoryId);
    uint256 feeAmount = price.mul(feePercentBps).div(1e4);
    _updateBuyLimit(_categoryId, _to);
    require(buyLimitMetadata[_to][_categoryId].counter <= buyLimitCount, "OGNFTOffering::_buyNFTTo::exceed buy limit");
    _safeWrap(metadata.quoteBep20, price);
    if (feeAmount != 0) {
      metadata.quoteBep20.safeTransfer(feeAddr, feeAmount);
    }
    metadata.quoteBep20.safeTransfer(tokenCategorySellers[_categoryId], price.sub(feeAmount));
    ILatteNFT(ogNFT).mint(_to, _categoryId, "");
    emit Trade(tokenCategorySellers[_categoryId], _to, _categoryId, price, feeAmount);
  }

  function _updateBuyLimit(uint256 _category, address _buyer) internal {
    OGNFTBuyLimitMetadata storage _buyLimitMetadata = buyLimitMetadata[_buyer][_category];
    _buyLimitMetadata.counter = _buyLimitMetadata.counter.add(1);

    if (
      uint256(block.number).sub(_buyLimitMetadata.cooldownStartBlock) > buyLimitPeriod ||
      _buyLimitMetadata.cooldownStartBlock == 0
    ) {
      _buyLimitMetadata.counter = 1;
      _buyLimitMetadata.cooldownStartBlock = block.number;
    }

    emit UpdateBuyLimit(_buyLimitMetadata.counter, _buyLimitMetadata.cooldownStartBlock);
  }

  /// @notice this needs to be called when the seller want to SELL the token
  /// @param _categoryId - category id for each nft address
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToSellNFT(
    uint256 _categoryId,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20Upgradeable _quoteToken
  ) external whenNotPaused onlyGovernance {
    _readyToSellNFTTo(_categoryId, address(_msgSender()), _cap, _startBlock, _endBlock, _quoteToken);
  }

  /// @dev an internal function for readyToSellNFTTo
  function _readyToSellNFTTo(
    uint256 _categoryId,
    address _to,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20Upgradeable _quoteToken
  ) internal {
    require(ogNFTMetadata[_categoryId].startBlock == 0, "OGNFTOffering::_readyToSellNFTTo::duplicated entry");
    tokenCategorySellers[_categoryId] = _to;
    _setOGNFTMetadata(
      OGNFTMetadataParam({ cap: _cap, startBlock: _startBlock, endBlock: _endBlock, nftCategoryId: _categoryId })
    );
    _setQuoteBep20(_categoryId, _quoteToken);
  }

  /// @notice cancel selling token
  /// @param _categoryId - category id for each nft address
  function cancelSellNFT(uint256 _categoryId) external whenNotPaused onlyGovernance {
    _cancelSellNFT(_categoryId);
    emit CancelSellNFT(_msgSender(), _categoryId);
  }

  /// @dev internal function for cancelling a selling token
  function _cancelSellNFT(uint256 _categoryId) internal {
    delete tokenCategorySellers[_categoryId];
    delete ogNFTMetadata[_categoryId];
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
    require(feePercentBps != _feePercentBps, "OGNFTOffering::setFeePercent::Not need update");
    require(feePercentBps <= 1e4, "OGNFTOffering::setFeePercent::percent exceed 100%");
    emit SetFeePercent(_msgSender(), feePercentBps, _feePercentBps);
    feePercentBps = _feePercentBps;
  }

  function _safeWrap(IERC20Upgradeable _quoteBep20, uint256 _amount) internal {
    if (msg.value != 0) {
      require(address(_quoteBep20) == wNative, "OGNFTOffering::_safeWrap:: baseToken is not wNative");
      require(_amount == msg.value, "OGNFTOffering::_safeWrap:: value != msg.value");
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

  /// @dev Fallback function to accept BNB
  receive() external payable {}
}