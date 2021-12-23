// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISavageStock.sol";
import "./interfaces/IERC20Decimals.sol";
import "./dex/interfaces/IWETH.sol";


contract SavageStock is ISavageStock, Ownable {
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  function getTimestamp() internal virtual view returns (uint256) {
    return block.timestamp;
  }

  uint256 public constant PRIMARY_SALE_SYSTEM_FEE = 2;
  uint256 public constant SECONDARY_SALE_SYSTEM_FEE = 5;

  ICollateralPool private _collateralPool;
  address private _intermediateStablecoin;
  uint256 private _minimumPrice;
  ISavageNFT private _nft;
  EnumerableSet.AddressSet private _paymentTokens;
  IUniswapV2Router02 private _router;
  mapping (uint256 => Sale) private _sales;
  uint256 private _salesCount;
  uint256 private _savageDiscountPercent;
  address private _savageToken;
  address private _stripeToken;
  address private _systemFeeRecipient;
  address private _wrappedToken;

  function collateralPool() external view override(ISavageStock) returns (ICollateralPool) {
    return _collateralPool;
  }

  function intermediateStablecoin() external view override(ISavageStock) returns (address) {
    return _intermediateStablecoin;
  }

  function minimumPrice() external view override(ISavageStock) returns (uint256) {
    return _minimumPrice;
  }

  function nft() external view override(ISavageStock) returns (ISavageNFT) {
    return _nft;
  }

  function paymentTokens() external view override(ISavageStock) returns (address[] memory) {
    uint256 tokensCount_ = _paymentTokens.length();
    address[] memory tokens_ = new address[](tokensCount_);
    for(uint256 i = 0; i < tokensCount_; i++) {
      tokens_[i] = _paymentTokens.at(i);
    }
    return tokens_;
  }

  function paymentTokensLength() external view override(ISavageStock) returns (uint256) {
    return _paymentTokens.length();
  }

  function router() external view override(ISavageStock) returns (IUniswapV2Router02) {
    return _router;
  }

  function salesCount() external view override(ISavageStock) returns (uint256) {
    return _salesCount;
  }

  function savageDiscountPercent() external view override(ISavageStock) returns (uint256) {
    return _savageDiscountPercent;
  }

  function savageToken() external view override(ISavageStock) returns (address) {
    return _savageToken;
  }

  function stripeToken() external view override(ISavageStock) returns (address) {
    return _stripeToken;
  }

  function systemFeeRecipient() external view override(ISavageStock) returns (address) {
    return _systemFeeRecipient;
  }

  function wrappedToken() external view override(ISavageStock) returns (address) {
    return _wrappedToken;
  }

  function isPaymentTokenExist(address token) external view override(ISavageStock) returns (bool) {
    return _paymentTokens.contains(token);
  }

  function paymentToken(uint256 tokenId) external view override(ISavageStock) returns (address) {
    require(tokenId < _paymentTokens.length(), "Invalid token id");
    return _paymentTokens.at(tokenId);
  }

  function sale(uint256 saleId) external view override(ISavageStock) returns (SaleResponse memory) {
    require(saleId < _salesCount, "Sale is not exist");
    Sale storage sale_ = _sales[saleId];
    uint256 count = sale_.tokenIds.length();
    uint256[] memory ids = new uint256[](count);
    for (uint256 i = 0; i < count; i++) ids[i] = sale_.tokenIds.at(i);
    return SaleResponse({
      saleType: sale_.saleType,
      seller: sale_.seller,
      tokenIds: ids,
      price: sale_.price,
      stepPercent: sale_.stepPercent,
      step: sale_.step,
      bidder: sale_.bidder,
      tokenIn: sale_.tokenIn,
      startTimestamp: sale_.startTimestamp,
      endTimestamp: sale_.endTimestamp,
      isAuction: sale_.isAuction,
      active: sale_.active,
      stopped: sale_.stopped
    });
  }

  constructor(
    address router_,
    address nft_,
    address wrappedToken_,
    address savageToken_,
    address stripeToken_,
    address collateralPool_,
    address intermediateStablecoin_,
    uint256 savageDiscountPercent_,
    address systemFeeRecipient_,
    address[] memory paymentTokens_
  ) Ownable() {
    address zero = address(0);
    require(router_ != zero, "Router is zero address");
    require(wrappedToken_ != zero, "WrappedToken is zero address");
    require(nft_ != zero, "NFT is zero address");
    require(savageToken_ != zero, "SavageToken is zero address");
    require(stripeToken_ != zero, "StripeToken is zero address");
    require(collateralPool_ != zero, "CollateralPool is zero address");
    require(intermediateStablecoin_ != zero, "IntermediateStablecoin is zero address");
    require(savageDiscountPercent_ < 100, "SavageDiscountPercent gt 100");
    require(systemFeeRecipient_ != zero, "SystemFeeRecipient is zero address");
    _router = IUniswapV2Router02(router_);
    _wrappedToken = wrappedToken_;
    _nft = ISavageNFT(nft_);
    _savageToken = savageToken_;
    _stripeToken = stripeToken_;
    _collateralPool = ICollateralPool(collateralPool_);
    _intermediateStablecoin = intermediateStablecoin_;
    _savageDiscountPercent = savageDiscountPercent_;
    _systemFeeRecipient = systemFeeRecipient_;
    _minimumPrice = 10 ** IERC20Decimals(intermediateStablecoin_).decimals();
    for (uint256 i = 0; i < paymentTokens_.length; i++) {
      _paymentTokens.add(paymentTokens_[i]);
    }
    _paymentTokens.add(wrappedToken_);
    _paymentTokens.add(savageToken_);
    _paymentTokens.add(stripeToken_);
    _paymentTokens.add(intermediateStablecoin_);
  }

  function addPaymentToken(address token) external override(ISavageStock) returns (bool) {
    require(!_paymentTokens.contains(token), "Token already exists");
    _paymentTokens.add(token);
    emit PaymentTokenAdded(token, msg.sender);
    return true;
  }

  function bid(address bidder, uint256 saleId) external payable override(ISavageStock) returns (bool) {
    uint256 value = msg.value;
    require(_paymentTokens.contains(_wrappedToken), "WrappedToken is unsupported");
    IWETH(_wrappedToken).deposit{value: value}();
    return _bid(bidder, saleId, _wrappedToken, value, false);
  }

  function bid(
    address bidder,
    uint256 saleId,
    address tokenIn,
    uint256 amountIn
  ) external override(ISavageStock) returns (bool) {
    require(_paymentTokens.contains(tokenIn), "TokenIn is unsupported");
    return _bid(bidder, saleId, tokenIn, amountIn, true);
  }

  function buy(address buyer, uint256 saleId) external payable override(ISavageStock) returns (bool) {
    uint256 value = msg.value;
    require(_paymentTokens.contains(_wrappedToken), "WrappedToken is unsupported");
    IWETH(_wrappedToken).deposit{value: value}();
    return _buy(buyer, saleId, _wrappedToken, value, false);
  }

  function buy(
    address buyer,
    uint256 saleId,
    address tokenIn,
    uint256 amountIn
  ) external override(ISavageStock) returns (bool) {
    require(_paymentTokens.contains(tokenIn), "TokenIn is unsupported");
    return _buy(buyer, saleId, tokenIn, amountIn, true);
  }

  function createAndSaleNFT(
    address creator,
    uint256 count,
    string memory uri,
    uint256 creatorFee,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external onlyOwner override(ISavageStock) returns (uint256[] memory tokenIds, uint256 saleId) {
    if (count > 1) require(!isAuction, "Auction when count gt 1");
    tokenIds = _nft.mint(creator, creatorFee, address(this), count, uri);
    saleId = _sale(
      SaleType.PRIMARY,
      creator,
      tokenIds,
      isAuction,
      price,
      stepPercent,
      startTimestamp,
      endTimestamp
    );
  }

  function finishAuction(uint256 saleId) external override(ISavageStock) returns (bool) {
    address this_ = address(this);
    require(saleId < _salesCount, "Sale is not exist");
    Sale storage sale_ = _sales[saleId];
    require(sale_.active, "Sale not active");
    require(sale_.isAuction, "Finish method for auction sale");
    require(sale_.endTimestamp <= getTimestamp(), "Sale not expired");
    bool bidderExist = sale_.bidder != address(0);
    uint256 tokenId = sale_.tokenIds.at(0);
    if (bidderExist) {
      uint256 amountOut = sale_.price;
      if (sale_.tokenIn == _stripeToken) {
        amountOut = _collateralPool.swap(this_, amountOut);
      } else {
        amountOut = _swap(_getOutPath(_savageToken), amountOut);
      }
      if (sale_.tokenIn == _savageToken) {
        uint256 discountAmountOut = (amountOut * _savageDiscountPercent) / 100;
        if (discountAmountOut > 0) {
          amountOut -= discountAmountOut;
          _transferTokens(_savageToken, sale_.bidder, discountAmountOut);
        }
      }
      emit Sold(
        saleId,
        tokenId,
        msg.sender,
        sale_.bidder,
        sale_.tokenIn,
        sale_.price,
        _distributeSavage(sale_, tokenId, amountOut)
      );
    }
    _nft.transferFrom(this_, bidderExist ? sale_.bidder : sale_.seller, tokenId);
    sale_.active = false;
    return true;
  }

  function removePaymentToken(address token) external override(ISavageStock) returns (bool) {
    require(_paymentTokens.contains(token), "Token is not supported");
    _paymentTokens.remove(token);
    emit PaymentTokenRemoved(token, msg.sender);
    return true;
  }

  function saleNFT(
    address seller,
    uint256 tokenId,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external onlyOwner override(ISavageStock) returns (uint256 saleId) {
    _nft.safeTransferFrom(seller, address(this), tokenId);
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    saleId = _sale(
      SaleType.SECONDARY,
      seller,
      tokenIds,
      isAuction,
      price,
      stepPercent,
      startTimestamp,
      endTimestamp
    );
  }

  function stopSale(uint256 saleId) external override(ISavageStock) returns (bool) {
    address caller = msg.sender;
    address zero = address(0);
    require(saleId < _salesCount, "Sale is not exist");
    Sale storage sale_ = _sales[saleId];
    require(caller == sale_.seller || caller == owner(), "Caller is not seller or owner");
    require(sale_.active, "Sale not active");
    if (sale_.bidder != zero) {
      uint256 amountOut = sale_.price;
      if (sale_.tokenIn != _intermediateStablecoin && sale_.tokenIn != _stripeToken) {
        amountOut = _swap(_getOutPath(sale_.tokenIn), amountOut);
      }
      _transferTokens(sale_.tokenIn, sale_.bidder, amountOut);
      sale_.bidder = zero;
    }
    uint256 count = sale_.tokenIds.length();
    uint256[] memory ids = new uint256[](count);
    for (uint256 i = 0; i < count; i++) ids[i] = sale_.tokenIds.at(i);
    _nft.multiTransferFrom(address(this), sale_.seller, ids);
    sale_.price = 0;
    sale_.stopped = true;
    sale_.active = false;
    emit SaleStopped(saleId, caller);
    return sale_.stopped;
  }

  function updateFeeRecipient(address recipient) external onlyOwner override(ISavageStock) returns (bool) {
    require(recipient != address(0), "Recipient is zero address");
    _systemFeeRecipient = recipient;
    emit FeeRecipientUpdated(recipient);
    return true;
  }

  function _bid(
    address bidder,
    uint256 saleId,
    address tokenIn,
    uint256 amountIn,
    bool needTransferFrom
  ) private returns (bool success) {
    address caller = msg.sender;
    uint256 time = getTimestamp();
    require(bidder == caller || caller == owner(), "Invalid caller");
    require(saleId < _salesCount, "Sale is not exist");
    Sale storage sale_ = _sales[saleId];
    uint256 requiredStableAmount = sale_.price;
    require(sale_.active, "Sale not active");
    require(sale_.isAuction, "Bid method for auction sale");
    require(sale_.startTimestamp <= time, "Sale not started");
    require(sale_.endTimestamp > time, "Sale expired");
    if (sale_.bidder != address(0)) {
      uint256 amountOut = sale_.price;
      if (sale_.tokenIn != _intermediateStablecoin && sale_.tokenIn != _stripeToken) {
        amountOut = _swap(_getOutPath(sale_.tokenIn), amountOut);
      }
      _transferTokens(sale_.tokenIn, sale_.bidder, amountOut);
      requiredStableAmount += sale_.step;
    }
    if (needTransferFrom) IERC20(tokenIn).safeTransferFrom(bidder, address(this), amountIn);
    if (tokenIn != _intermediateStablecoin && tokenIn != _stripeToken) {
      amountIn = _swap(_getInPath(tokenIn, _intermediateStablecoin), amountIn);
    }
    success = amountIn >= requiredStableAmount;
    require(success, "Token amount not cover bid step");
    sale_.bidder = bidder;
    sale_.tokenIn = tokenIn;
    sale_.price = amountIn;
    emit Bidded(saleId, sale_.tokenIds.at(0), caller, bidder, tokenIn, amountIn);
  }

  function _buy(
    address buyer,
    uint256 saleId,
    address tokenIn,
    uint256 amountIn,
    bool needTransferFrom
  ) private returns (bool success) {
    address caller = msg.sender;
    uint256 time = getTimestamp();
    address this_ = address(this);
    require(buyer == caller || caller == owner(), "Invalid caller");
    require(saleId < _salesCount, "Sale is not exist");
    Sale storage sale_ = _sales[saleId];
    uint256 tokensCount = sale_.tokenIds.length();
    uint256 tokenId = sale_.tokenIds.at(tokensCount - 1);
    require(sale_.active, "Sale not active");
    require(!sale_.isAuction, "Buy method for fix price sale");
    require(sale_.startTimestamp <= time, "Sale not started");
    require(tokensCount > 0, "Not any tokens to buy");
    if (needTransferFrom) IERC20(tokenIn).safeTransferFrom(buyer, this_, amountIn);
    {
      uint256 stableAmount = amountIn;
      if (tokenIn != _intermediateStablecoin && tokenIn != _stripeToken) {
        uint256[] memory amounts = _router.getAmountsOut(amountIn, _getInPath(tokenIn, _intermediateStablecoin));
        stableAmount = amounts[amounts.length - 1];
      }
      success = stableAmount >= sale_.price;
    }
    require(success, "TokenIn amount not cover price");
    uint256 amountOut = amountIn;
    if (tokenIn == _stripeToken) {
      amountOut = _collateralPool.swap(this_, amountOut);
    } else if (tokenIn != _savageToken) {
      amountOut = _swap(_getInPath(tokenIn, _savageToken), amountOut);
    }
    if (sale_.tokenIn == _savageToken) {
      uint256 discountAmountOut = (amountOut * _savageDiscountPercent) / 100;
      if (discountAmountOut > 0) {
        amountOut -= discountAmountOut;
        _transferTokens(_savageToken, buyer, discountAmountOut);
      }
    }
    _nft.transferFrom(this_, buyer, tokenId);
    sale_.tokenIds.remove(tokenId);
    if (tokenId == 0) sale_.active = false;
    emit Sold(
      saleId,
      tokenId,
      caller,
      buyer,
      tokenIn,
      amountIn,
      _distributeSavage(sale_, tokenId, amountOut)
    );
  }

  function _distributeSavage(
    Sale storage sale_,
    uint256 tokenId,
    uint256 savageAmount
  ) private returns (SavageDistribution memory savageDistribution){
    IERC20 token = IERC20(_savageToken);
    savageDistribution.creator = _nft.tokenCreator(tokenId);
    savageDistribution.seller = sale_.seller;
    savageDistribution.systemFeeRecipient = _systemFeeRecipient;
    if (sale_.saleType == SaleType.PRIMARY) {
      savageDistribution.systemFeeAmount = savageAmount * PRIMARY_SALE_SYSTEM_FEE / 100;
      savageDistribution.creatorAmount = savageAmount - savageDistribution.systemFeeAmount;
    } else {
      savageDistribution.systemFeeAmount = savageAmount * SECONDARY_SALE_SYSTEM_FEE / 100;
      savageDistribution.creatorAmount = (savageAmount * _nft.tokenCreatorFee(tokenId)) / 100;
      savageDistribution.sellerAmount = savageAmount - (
        savageDistribution.systemFeeAmount + savageDistribution.creatorAmount);
    }
    _transferTokens(token, savageDistribution.systemFeeRecipient, savageDistribution.systemFeeAmount);
    _transferTokens(token, savageDistribution.creator, savageDistribution.creatorAmount);
    _transferTokens(token, savageDistribution.seller, savageDistribution.sellerAmount);
  }

  function _getInPath(address tokenFrom, address tokenTo) private view returns (address[] memory path) {
    uint256 length = tokenFrom == _wrappedToken ? 2 : 3;
    path = _getPath(length, tokenFrom, tokenTo);
  }

  function _getOutPath(address tokenTo) private view returns (address[] memory path) {
    uint256 length = tokenTo == _wrappedToken ? 2 : 3;
    path = _getPath(length, _intermediateStablecoin, tokenTo);
  }

  function _getPath(uint256 length, address tokenFrom, address tokenTo) private view returns (address[] memory path) {
    path = new address[](length);
    path[0] = tokenFrom;
    path[length - 1] = tokenTo;
    if (length > 2) path[1] = _wrappedToken;
  }

  function _sale(
    SaleType saleType,
    address seller,
    uint256[] memory tokenIds,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) private returns (uint256 saleId) {
    uint256 step = 0;
    require(price >= _minimumPrice, "Price lt minimum price");
    require(startTimestamp >= getTimestamp(), "StartTimemstamp lt current");
    if (isAuction) {
      require(endTimestamp > startTimestamp, "EndTimestmap lte StartTimestamp");
      require(stepPercent > 0, "StepPercent not positive");
      step = (price * stepPercent) / 100;
    }
    saleId = _salesCount;
    Sale storage sale_ = _sales[saleId];
    for (uint256 i = 0; i < tokenIds.length; i++) {
      sale_.tokenIds.add(tokenIds[i]);
    }
    sale_.saleType = saleType;
    sale_.seller = seller;
    sale_.price = price;
    sale_.stepPercent = stepPercent;
    sale_.step = step;
    sale_.startTimestamp = startTimestamp;
    sale_.endTimestamp = endTimestamp;
    sale_.isAuction = isAuction;
    sale_.active = true;
    _salesCount++;
    emit SaleCreated(
      saleType,
      seller,
      tokenIds,
      price,
      stepPercent,
      step,
      startTimestamp,
      endTimestamp,
      isAuction,
      saleId
    );
  }

  function _swap(address[] memory path, uint256 amount) private returns (uint256) {
    IERC20(path[0]).safeApprove(address(_router), amount);
    return _router.swapExactTokensForTokens(
      amount,
      1,
      path,
      address(this),
      getTimestamp()
    )[path.length - 1];
  }

  function _transferTokens(address token, address to, uint256 amount) private {
    if (amount > 0) IERC20(token).safeTransfer(to, amount);
  }

  function _transferTokens(IERC20 token, address to, uint256 amount) private {
    if (amount > 0) token.safeTransfer(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IStripeToken is IERC20 {
  function collateralPool() external view returns (address);
  function mint(address account, uint256 amount) external returns (bool);
  function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ISavageNFT.sol";
import "./ICollateralPool.sol";
import "../dex/interfaces/IUniswapV2Router02.sol";


interface ISavageStock {

  enum SaleType { PRIMARY, SECONDARY }

  struct SavageDistribution {
    address creator;
    uint256 creatorAmount;
    address seller;
    uint256 sellerAmount;
    address systemFeeRecipient;
    uint256 systemFeeAmount;
  }

  struct Sale {
    SaleType saleType;
    address seller;
    EnumerableSet.UintSet tokenIds;
    uint256 price;
    uint256 stepPercent;
    uint256 step;
    address bidder;
    address tokenIn;
    uint256 startTimestamp;
    uint256 endTimestamp;
    bool isAuction;
    bool active;
    bool stopped;
  }

  struct SaleResponse {
    SaleType saleType;
    address seller;
    uint256[] tokenIds;
    uint256 price;
    uint256 stepPercent;
    uint256 step;
    address bidder;
    address tokenIn;
    uint256 startTimestamp;
    uint256 endTimestamp;
    bool isAuction;
    bool active;
    bool stopped;
  }

  function collateralPool() external view returns (ICollateralPool);
  function intermediateStablecoin() external view returns (address);
  function minimumPrice() external view returns (uint256);
  function nft() external view returns (ISavageNFT);
  function paymentTokens() external view returns (address[] memory);
  function paymentTokensLength() external view returns (uint256);
  function router() external view returns (IUniswapV2Router02);
  function salesCount() external view returns (uint256);
  function savageDiscountPercent() external view returns (uint256);
  function savageToken() external view returns (address);
  function stripeToken() external view returns (address);
  function systemFeeRecipient() external view returns (address);
  function wrappedToken() external view returns (address);
  function isPaymentTokenExist(address token) external view returns (bool);
  function paymentToken(uint256 tokenId) external view returns (address);
  function sale(uint256 saleId) external view returns (SaleResponse memory);

  event AuctionFinished(
    uint256 saleId,
    uint256 indexed tokenId,
    address indexed caller
  );
  event Bidded(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    address caller,
    address indexed bidder,
    address tokenIn,
    uint256 amountIn
  );
  event FeeRecipientUpdated(address recipient);
  event IntermediateStablecoinUpdated(address intermediateStablecoin_);
  event MinimumPriceUpdated(uint256 minimumPrice_);
  event PaymentTokenAdded(address indexed token, address indexed sender);
  event PaymentTokenRemoved(address indexed token, address indexed sender);
  event SaleCreated(
    SaleType indexed saleType,
    address indexed seller,
    uint256[] tokenIds,
    uint256 price,
    uint256 stepPercent,
    uint256 step,
    uint256 startTimestamp,
    uint256 endTimestamp,
    bool indexed isAuction,
    uint256 saleId
  );
  event SaleStopped(uint256 saleId, address indexed sender);
  event SavageDistributed(
    uint256 indexed saleId,
    address creator,
    address seller,
    address feeRecipient,
    uint256 creatorAmount,
    uint256 sellerAmount,
    uint256 feeRecipientAmount
  );
  event Sold(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    address caller,
    address indexed buyer,
    address tokenIn,
    uint256 amountIn,
    SavageDistribution savageDistribution
  );

  function addPaymentToken(address token) external returns (bool);
  function bid(address bidder, uint256 saleId) external payable returns (bool);
  function bid(address bidder, uint256 saleId, address tokenIn, uint256 amountIn) external returns (bool);
  function buy(address buyer, uint256 saleId) external payable returns (bool);
  function buy(address buyer, uint256 saleId, address tokenIn, uint256 amountIn) external returns (bool);
  function createAndSaleNFT(
    address creator,
    uint256 count,
    string memory uri,
    uint256 creatorFee,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external returns (uint256[] memory tokenIds, uint256 saleId);
  function finishAuction(uint256 saleId) external returns (bool);
  function removePaymentToken(address token) external returns (bool);
  function saleNFT(
    address seller,
    uint256 tokenId,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external returns (uint256 saleId);
  function stopSale(uint256 saleId) external returns (bool);
  function updateFeeRecipient(address recipient) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ISavageNFT is IERC721 {
  struct Token {
    uint256 id;
    uint256 copyId;
  }

  function collectionsCount() external view returns (uint256);
  function tokensCount() external view returns (uint256);
  function tokenCreator(uint256 tokenId) external view returns (address);
  function tokenCreatorFee(uint256 tokenId) external view returns (uint256);
  function collection(uint256 collectionId) external view returns (Token[] memory);
  function collectionLength(uint256 collectionId) external view returns (uint256);

  event Minted(uint256 id, address indexed to, uint256 creatorFee, string uri);
  event CollectionMinted(Token[] tokens, address indexed to, uint256 collectionId, uint256 creatorFee, string uri);

  function mint(
    address creator,
    uint256 creatorFee,
    address to,
    uint256 count,
    string memory uri
  ) external returns (uint256[] memory tokenIds);
  function multiApprove(address to, uint256[] memory tokenIds) external returns (bool);
  function multiTransferFrom(address from, address to, uint256[] memory tokenIds) external returns (bool);
  function multiSafeTransferFrom(address from, address to, uint256[] memory tokenIds) external returns (bool);
  function multiSafeTransferFromWithData(
    address from,
    address to,
    uint256[] memory tokenIds,
    bytes memory data
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStripeToken.sol";
import "../dex/interfaces/IUniswapV2Router02.sol";


interface ICollateralPool {
  function inited() external view returns (bool);
  function reserve() external view returns (uint256);
  function router() external view returns (IUniswapV2Router02);
  function savage() external view returns (IERC20);
  function stable() external view returns (address);
  function stripe() external view returns (IStripeToken);
  function wrapped() external view returns (address);

  event ReserveDeposited(address indexed sender, uint256 amount);
  event ReserveWithdrawn(address indexed sender, address indexed to, uint256 amount);
  event Swapped(address indexed sender, address indexed account, uint256 stripeAmount, uint256 savageAmount);

  function depositReserve(uint256 amount) external returns (bool);
  function setContracts(
    address savage_,
    address stripe_,
    address stable_,
    address wrapped_,
    address router_
  ) external returns (bool);
  function swap(address account, uint256 amount) external returns (uint256);
  function withdrawReserve(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}