// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "../interfaces/INiftyswapExchange20.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/DelegatedOwnable.sol";
import "../interfaces/IERC2981.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155MintBurn.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * This Uniswap-like implementation supports ERC-1155 standard tokens
 * with an ERC-20 based token used as a currency instead of Ether.
 *
 * Liquidity tokens are also ERC-1155 tokens you can find the ERC-1155
 * implementation used here:
 *    https://github.com/horizon-games/multi-token-standard/tree/master/contracts/tokens/ERC1155
 *
 * @dev Like Uniswap, tokens with 0 decimals and low supply are susceptible to significant rounding
 *      errors when it comes to removing liquidity, possibly preventing them to be withdrawn without
 *      some collaboration between liquidity providers.
 */
contract NiftyswapExchange20 is ReentrancyGuard, ERC1155MintBurn, INiftyswapExchange20, DelegatedOwnable {
  using SafeMath for uint256;

  /***********************************|
  |       Variables & Constants       |
  |__________________________________*/

  // Variables
  IERC1155 internal immutable token;              // address of the ERC-1155 token contract
  address internal immutable currency;            // address of the ERC-20 currency used for exchange
  address internal immutable factory;             // address for the factory that created this contract
  uint256 internal constant FEE_MULTIPLIER = 990; // multiplier that calculates the LP fee (1.0%)

  // Royalty variables
  bool internal immutable IS_ERC2981; // whether token contract supports ERC-2981
  uint256 internal globalRoyaltyFee;        // global royalty fee multiplier if ERC2981 is not used
  address internal globalRoyaltyRecipient;  // global royalty fee recipient if ERC2981 is not used

  // Mapping variables
  mapping(uint256 => uint256) internal totalSupplies;    // Liquidity pool token supply per Token id
  mapping(uint256 => uint256) internal currencyReserves; // currency Token reserve per Token id
  mapping(address => uint256) internal royalties;        // Mapping tracking how much royalties can be claimed per address


  /***********************************|
  |            Constructor           |
  |__________________________________*/

  /**
   * @notice Create instance of exchange contract with respective token and currency token
   * @dev If token supports ERC-2981, then royalty fee will be queried per token on the 
   *      token contract. Else royalty fee will need to be manually set by admin.
   * @param _tokenAddr     The address of the ERC-1155 Token
   * @param _currencyAddr  The address of the ERC-20 currency Token
   * @param _currencyAddr  Address of the admin, which should be the same as the factory owner
   */
  constructor(address _tokenAddr, address _currencyAddr) DelegatedOwnable(msg.sender) {
    require(
      _tokenAddr != address(0) && _currencyAddr != address(0),
      "NiftyswapExchange20#constructor:INVALID_INPUT"
    );

    factory = msg.sender;
    token = IERC1155(_tokenAddr);
    currency = _currencyAddr;

    // If global royalty, lets check for ERC-2981 support
    try IERC1155(_tokenAddr).supportsInterface(type(IERC2981).interfaceId) returns (bool supported) {
      IS_ERC2981 = supported;
    } catch {}
  }


  /***********************************|
  |        Exchange Functions         |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   */
  function _currencyToToken(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient
  )
    internal nonReentrant() returns (uint256[] memory currencySold)
  {
    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_currencyToToken: DEADLINE_EXCEEDED");

    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;
    uint256 totalRefundCurrency = _maxCurrency;

    // Initialize variables
    currencySold = new uint256[](nTokens); // Amount of currency tokens sold per ID

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the currency Tokens are already received by contract, but not
    // the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idBought = _tokenIds[i];
      uint256 amountBought = _tokensBoughtAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      require(amountBought > 0, "NiftyswapExchange20#_currencyToToken: NULL_TOKENS_BOUGHT");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idBought];

      // Get amount of currency tokens to send for purchase
      // Neither reserves amount have been changed so far in this transaction, so
      // no adjustment to the inputs is needed
      uint256 currencyAmount = getBuyPrice(amountBought, currencyReserve, tokenReserve);

      // If royalty, increase amount buyer will need to pay after LP fees were calculated
      // Note: Royalty will be a bit higher since LF fees are added first
      (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(idBought, currencyAmount);
      if (royaltyAmount > 0) {
        royalties[royaltyRecipient] = royalties[royaltyRecipient].add(royaltyAmount);
      }

      // Calculate currency token amount to refund (if any) where whatever is not used will be returned
      // Will throw if total cost exceeds _maxCurrency
      totalRefundCurrency = totalRefundCurrency.sub(currencyAmount).sub(royaltyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencySold[i] = currencyAmount.add(royaltyAmount);

      // Update individual currency reseve amount (royalty is not added to liquidity)
      currencyReserves[idBought] = currencyReserve.add(currencyAmount);
    }

    // Refund currency token if any
    if (totalRefundCurrency > 0) {
      TransferHelper.safeTransfer(currency, _recipient, totalRefundCurrency);
    }

    // Send Tokens all tokens purchased
    token.safeBatchTransferFrom(address(this), _recipient, _tokenIds, _tokensBoughtAmounts, "");
    return currencySold;
  }

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    // Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange20#getBuyPrice: EMPTY_RESERVE");

    // Calculate price with fee
    uint256 numerator = _assetSoldReserve.mul(_assetBoughtAmount).mul(1000);
    uint256 denominator = (_assetBoughtReserve.sub(_assetBoughtAmount)).mul(FEE_MULTIPLIER);
    (price, ) = divRound(numerator, denominator);
    return price; // Will add 1 if rounding error
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _tokenId            Id ot token being sold
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPriceWithRoyalty(
    uint256 _tokenId,
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public view returns (uint256 price)
  {
    uint256 cost = getBuyPrice(_assetBoughtAmount, _assetSoldReserve, _assetBoughtReserve);
    (, uint256 royaltyAmount) = getRoyaltyInfo(_tokenId, cost);
    return cost.add(royaltyAmount);
  }

  /**
   * @notice Convert Tokens _id to currency tokens and transfers Tokens to recipient.
   * @dev User specifies EXACT Tokens _id sold and MINIMUM currency tokens received.
   * @dev Assumes that all trades will be valid, or the whole tx will fail
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _tokenIds           Array of Token IDs that are sold
   * @param _tokensSoldAmounts  Array of Amount of Tokens sold for each id in _tokenIds.
   * @param _minCurrency        Minimum amount of currency tokens to receive
   * @param _deadline           Timestamp after which this transaction will be reverted
   * @param _recipient          The address that receives output currency tokens.
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencyBought How much currency was actually purchased.
   */
  function _tokenToCurrency(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensSoldAmounts,
    uint256 _minCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  )
    internal nonReentrant() returns (uint256[] memory currencyBought)
  {
    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;

    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_tokenToCurrency: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 totalCurrency = 0; // Total amount of currency tokens to transfer
    currencyBought = new uint256[](nTokens);

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the Tokens ids are already received by contract, but not
    // the Tokens Ids. Will return cards not sold if invalid price.

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idSold = _tokenIds[i];
      uint256 amountSold = _tokensSoldAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // If 0 tokens send for this ID, revert
      require(amountSold > 0, "NiftyswapExchange20#_tokenToCurrency: NULL_TOKENS_SOLD");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idSold];

      // Get amount of currency that will be received
      // Need to sub amountSold because tokens already added in reserve, which would bias the calculation
      // Don't need to add it for currencyReserve because the amount is added after this calculation
      uint256 currencyAmount = getSellPrice(amountSold, tokenReserve.sub(amountSold), currencyReserve);

      // If royalty, substract amount seller will receive after LP fees were calculated
      // Note: Royalty will be a bit lower since LF fees are substracted first
      (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(idSold, currencyAmount);
      if (royaltyAmount > 0) {
        royalties[royaltyRecipient] = royalties[royaltyRecipient].add(royaltyAmount);
      }

      // Increase total amount of currency to receive (minus royalty to pay)
      totalCurrency = totalCurrency.add(currencyAmount.sub(royaltyAmount));

      // Update individual currency reseve amount
      currencyReserves[idSold] = currencyReserve.sub(currencyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencyBought[i] = currencyAmount.sub(royaltyAmount);
    }

    // Set the extra fees aside to recipients after sale
    for (uint256 i = 0; i < _extraFeeAmounts.length; i++) {
      if (_extraFeeAmounts[i] > 0) {
        totalCurrency = totalCurrency.sub(_extraFeeAmounts[i]);
        royalties[_extraFeeRecipients[i]] = royalties[_extraFeeRecipients[i]].add(_extraFeeAmounts[i]);
      }
    }

    // If minCurrency is not met
    require(totalCurrency >= _minCurrency, "NiftyswapExchange20#_tokenToCurrency: INSUFFICIENT_CURRENCY_AMOUNT");

    // Transfer currency here
    TransferHelper.safeTransfer(currency, _recipient, totalCurrency);
    return currencyBought;
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    //Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange20#getSellPrice: EMPTY_RESERVE");

    // Calculate amount to receive (with fee) before royalty
    uint256 _assetSoldAmount_withFee = _assetSoldAmount.mul(FEE_MULTIPLIER);
    uint256 numerator = _assetSoldAmount_withFee.mul(_assetBoughtReserve);
    uint256 denominator = _assetSoldReserve.mul(1000).add(_assetSoldAmount_withFee);
    return numerator / denominator; //Rounding errors will favor Niftyswap, so nothing to do
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _tokenId            Id ot token being sold
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPriceWithRoyalty(
    uint256 _tokenId,
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public view returns (uint256 price)
  {
    uint256 sellAmount = getSellPrice(_assetSoldAmount, _assetSoldReserve, _assetBoughtReserve);
    (, uint256 royaltyAmount) = getRoyaltyInfo(_tokenId, sellAmount);
    return sellAmount.sub(royaltyAmount);
  }

  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /**
   * @notice Deposit less than max currency tokens && exact Tokens (token ID) at current ratio to mint liquidity pool tokens.
   * @dev min_liquidity does nothing when total liquidity pool token supply is 0.
   * @dev Assumes that sender approved this contract on the currency
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider      Address that provides liquidity to the reserve
   * @param _tokenIds      Array of Token IDs where liquidity is added
   * @param _tokenAmounts  Array of amount of Tokens deposited corresponding to each ID provided in _tokenIds
   * @param _maxCurrency   Array of maximum number of tokens deposited for each ID provided in _tokenIds.
   *                       Deposits max amount if total liquidity pool token supply is 0.
   * @param _deadline      Timestamp after which this transaction will be reverted
   */
  function _addLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _tokenAmounts,
    uint256[] memory _maxCurrency,
    uint256 _deadline)
    internal nonReentrant()
  {
    // Requirements
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_addLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length; // Number of Token IDs to deposit
    uint256 totalCurrency = 0;          // Total amount of currency tokens to transfer

    // Initialize arrays
    uint256[] memory liquiditiesToMint = new uint256[](nTokens);
    uint256[] memory currencyAmounts = new uint256[](nTokens);

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes tokens _ids are deposited already, but not currency tokens
    // as this is calculated and executed below.

    // Loop over all Token IDs to deposit
    for (uint256 i = 0; i < nTokens; i ++) {
      // Store current id and amount from argument arrays
      uint256 tokenId = _tokenIds[i];
      uint256 amount = _tokenAmounts[i];

      // Check if input values are acceptable
      require(_maxCurrency[i] > 0, "NiftyswapExchange20#_addLiquidity: NULL_MAX_CURRENCY");
      require(amount > 0, "NiftyswapExchange20#_addLiquidity: NULL_TOKENS_AMOUNT");

      // Current total liquidity calculated in currency token
      uint256 totalLiquidity = totalSupplies[tokenId];

      // When reserve for this token already exists
      if (totalLiquidity > 0) {

        // Load currency token and Token reserve's supply of Token id
        uint256 currencyReserve = currencyReserves[tokenId]; // Amount not yet in reserve
        uint256 tokenReserve = tokenReserves[i];

        /**
        * Amount of currency tokens to send to token id reserve:
        * X/Y = dx/dy
        * dx = X*dy/Y
        * where
        *   X:  currency total liquidity
        *   Y:  Token _id total liquidity (before tokens were received)
        *   dy: Amount of token _id deposited
        *   dx: Amount of currency to deposit
        *
        * Adding .add(1) if rounding errors so to not favor users incorrectly
        */
        (uint256 currencyAmount, bool rounded) = divRound(amount.mul(currencyReserve), tokenReserve.sub(amount));
        require(_maxCurrency[i] >= currencyAmount, "NiftyswapExchange20#_addLiquidity: MAX_CURRENCY_AMOUNT_EXCEEDED");

        // Update currency reserve size for Token id before transfer
        currencyReserves[tokenId] = currencyReserve.add(currencyAmount);

        // Update totalCurrency
        totalCurrency = totalCurrency.add(currencyAmount);

        // Proportion of the liquidity pool to give to current liquidity provider
        // If rounding error occured, round down to favor previous liquidity providers
        // See https://github.com/0xsequence/niftyswap/issues/19
        liquiditiesToMint[i] = (currencyAmount.sub(rounded ? 1 : 0)).mul(totalLiquidity) / currencyReserve;
        currencyAmounts[i] = currencyAmount;

        // Mint liquidity ownership tokens and increase liquidity supply accordingly
        totalSupplies[tokenId] = totalLiquidity.add(liquiditiesToMint[i]);

      } else {
        uint256 maxCurrency = _maxCurrency[i];

        // Otherwise rounding error could end up being significant on second deposit
        require(maxCurrency >= 1000000000, "NiftyswapExchange20#_addLiquidity: INVALID_CURRENCY_AMOUNT");

        // Update currency  reserve size for Token id before transfer
        currencyReserves[tokenId] = maxCurrency;

        // Update totalCurrency
        totalCurrency = totalCurrency.add(maxCurrency);

        // Initial liquidity is amount deposited (Incorrect pricing will be arbitraged)
        // uint256 initialLiquidity = _maxCurrency;
        totalSupplies[tokenId] = maxCurrency;

        // Liquidity to mints
        liquiditiesToMint[i] = maxCurrency;
        currencyAmounts[i] = maxCurrency;
      }
    }

    // Mint liquidity pool tokens
    _batchMint(_provider, _tokenIds, liquiditiesToMint, "");

    // Transfer all currency to this contract
    TransferHelper.safeTransferFrom(currency, _provider, address(this), totalCurrency);

    // Emit event
    emit LiquidityAdded(_provider, _tokenIds, _tokenAmounts, currencyAmounts);
  }

  /**
   * @dev Burn liquidity pool tokens to withdraw currency  && Tokens at current ratio.
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider         Address that removes liquidity to the reserve
   * @param _tokenIds         Array of Token IDs where liquidity is removed
   * @param _poolTokenAmounts Array of Amount of liquidity pool tokens burned for each Token id in _tokenIds.
   * @param _minCurrency      Minimum currency withdrawn for each Token id in _tokenIds.
   * @param _minTokens        Minimum Tokens id withdrawn for each Token id in _tokenIds.
   * @param _deadline         Timestamp after which this transaction will be reverted
   */
  function _removeLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _poolTokenAmounts,
    uint256[] memory _minCurrency,
    uint256[] memory _minTokens,
    uint256 _deadline)
    internal nonReentrant()
  {
    // Input validation
    require(_deadline > block.timestamp, "NiftyswapExchange20#_removeLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length;                        // Number of Token IDs to deposit
    uint256 totalCurrency = 0;                                 // Total amount of currency  to transfer
    uint256[] memory tokenAmounts = new uint256[](nTokens);    // Amount of Tokens to transfer for each id
    uint256[] memory currencyAmounts = new uint256[](nTokens); // Amount of currency to transfer for each id

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes NIFTY liquidity tokens are already received by contract, but not
    // the currency nor the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 id = _tokenIds[i];
      uint256 amountPool = _poolTokenAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // Load total liquidity pool token supply for Token _id
      uint256 totalLiquidity = totalSupplies[id];
      require(totalLiquidity > 0, "NiftyswapExchange20#_removeLiquidity: NULL_TOTAL_LIQUIDITY");

      // Load currency and Token reserve's supply of Token id
      uint256 currencyReserve = currencyReserves[id];

      // Calculate amount to withdraw for currency and Token _id
      uint256 currencyAmount = amountPool.mul(currencyReserve) / totalLiquidity;
      uint256 tokenAmount = amountPool.mul(tokenReserve) / totalLiquidity;

      // Verify if amounts to withdraw respect minimums specified
      require(currencyAmount >= _minCurrency[i], "NiftyswapExchange20#_removeLiquidity: INSUFFICIENT_CURRENCY_AMOUNT");
      require(tokenAmount >= _minTokens[i], "NiftyswapExchange20#_removeLiquidity: INSUFFICIENT_TOKENS");

      // Update total liquidity pool token supply of Token _id
      totalSupplies[id] = totalLiquidity.sub(amountPool);

      // Update currency reserve size for Token id
      currencyReserves[id] = currencyReserve.sub(currencyAmount);

      // Update totalCurrency and tokenAmounts
      totalCurrency = totalCurrency.add(currencyAmount);
      tokenAmounts[i] = tokenAmount;
      currencyAmounts[i] = currencyAmount;
    }

    // Burn liquidity pool tokens for offchain supplies
    _batchBurn(address(this), _tokenIds, _poolTokenAmounts);

    // Transfer total currency and all Tokens ids
    TransferHelper.safeTransfer(currency, _provider, totalCurrency);
    token.safeBatchTransferFrom(address(this), _provider, _tokenIds, tokenAmounts, "");

    // Emit event
    emit LiquidityRemoved(_provider, _tokenIds, tokenAmounts, currencyAmounts);
  }

  /***********************************|
  |     Receiver Methods Handler      |
  |__________________________________*/

  // Method signatures for onReceive control logic

  // bytes4(keccak256(
  //   "_tokenToCurrency(uint256[],uint256[],uint256,uint256,address,address[],uint256[])"
  // ));
  bytes4 internal constant SELLTOKENS_SIG = 0xade79c7a;

  //  bytes4(keccak256(
  //   "_addLiquidity(address,uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant ADDLIQUIDITY_SIG = 0x82da2b73;

  // bytes4(keccak256(
  //    "_removeLiquidity(address,uint256[],uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant REMOVELIQUIDITY_SIG = 0x5c0bf259;

  // bytes4(keccak256(
  //   "DepositTokens()"
  // ));
  bytes4 internal constant DEPOSIT_SIG = 0xc8c323f9;

  /***********************************|
  |           Buying Tokens           |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   * @dev User specifies MAXIMUM inputs (_maxCurrency) and EXACT outputs.
   * @dev Assumes that all trades will be successful, or revert the whole tx
   * @dev Exceeding currency tokens sent will be refunded to recipient
   * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit)
   * @param _tokenIds            Array of Tokens ID that are bought
   * @param _tokensBoughtAmounts Amount of Tokens id bought for each corresponding Token id in _tokenIds
   * @param _maxCurrency         Total maximum amount of currency tokens to spend for all Token ids
   * @param _deadline            Timestamp after which this transaction will be reverted
   * @param _recipient           The address that receives output Tokens and refund
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencySold How much currency was actually sold.
   */
  function buyTokens(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  )
    override external returns (uint256[] memory)
  {
    require(_deadline >= block.timestamp, "NiftyswapExchange20#buyTokens: DEADLINE_EXCEEDED");
    require(_tokenIds.length > 0, "NiftyswapExchange20#buyTokens: INVALID_CURRENCY_IDS_AMOUNT");

    // Transfer the tokens for purchase
    TransferHelper.safeTransferFrom(currency, msg.sender, address(this), _maxCurrency);

    address recipient = _recipient == address(0x0) ? msg.sender : _recipient;

    // Set the extra fee aside to recipients ahead of purchase, if any.
    uint256 maxCurrency = _maxCurrency;
    uint256 nExtraFees = _extraFeeRecipients.length;
    require(nExtraFees == _extraFeeAmounts.length, "NiftyswapExchange20#buyTokens: EXTRA_FEES_ARRAYS_ARE_NOT_SAME_LENGTH");
    
    for (uint256 i = 0; i < nExtraFees; i++) {
      if (_extraFeeAmounts[i] > 0) {
        maxCurrency = maxCurrency.sub(_extraFeeAmounts[i]);
        royalties[_extraFeeRecipients[i]] = royalties[_extraFeeRecipients[i]].add(_extraFeeAmounts[i]);
      }
    }

    // Execute trade and retrieve amount of currency spent
    uint256[] memory currencySold = _currencyToToken(_tokenIds, _tokensBoughtAmounts, maxCurrency, _deadline, recipient);
    emit TokensPurchase(msg.sender, recipient, _tokenIds, _tokensBoughtAmounts, currencySold);

    return currencySold;
  }

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(
    address, // _operator,
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data)
    override public returns(bytes4)
  {
    // This function assumes that the ERC-1155 token contract can
    // only call `onERC1155BatchReceived()` via a valid token transfer.
    // Users must be responsible and only use this Niftyswap exchange
    // contract with ERC-1155 compliant token contracts.

    // Obtain method to call via object signature
    bytes4 functionSignature = abi.decode(_data, (bytes4));

    /***********************************|
    |           Selling Tokens          |
    |__________________________________*/

    if (functionSignature == SELLTOKENS_SIG) {

      // Tokens received need to be Token contract
      require(msg.sender == address(token), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKENS_TRANSFERRED");

      // Decode SellTokensObj from _data to call _tokenToCurrency()
      SellTokensObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, SellTokensObj));
      address recipient = obj.recipient == address(0x0) ? _from : obj.recipient;

      // Validate fee arrays
      require(obj.extraFeeRecipients.length == obj.extraFeeAmounts.length, "NiftyswapExchange20#buyTokens: EXTRA_FEES_ARRAYS_ARE_NOT_SAME_LENGTH");
    
      // Execute trade and retrieve amount of currency received
      uint256[] memory currencyBought = _tokenToCurrency(_ids, _amounts, obj.minCurrency, obj.deadline, recipient, obj.extraFeeRecipients, obj.extraFeeAmounts);
      emit CurrencyPurchase(_from, recipient, _ids, _amounts, currencyBought);

    /***********************************|
    |      Adding Liquidity Tokens      |
    |__________________________________*/

    } else if (functionSignature == ADDLIQUIDITY_SIG) {
      // Only allow to receive ERC-1155 tokens from `token` contract
      require(msg.sender == address(token), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKEN_TRANSFERRED");

      // Decode AddLiquidityObj from _data to call _addLiquidity()
      AddLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, AddLiquidityObj));
      _addLiquidity(_from, _ids, _amounts, obj.maxCurrency, obj.deadline);

    /***********************************|
    |      Removing iquidity Tokens     |
    |__________________________________*/

    } else if (functionSignature == REMOVELIQUIDITY_SIG) {
      // Tokens received need to be NIFTY-1155 tokens
      require(msg.sender == address(this), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_NIFTY_TOKENS_TRANSFERRED");

      // Decode RemoveLiquidityObj from _data to call _removeLiquidity()
      RemoveLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, RemoveLiquidityObj));
      _removeLiquidity(_from, _ids, _amounts, obj.minCurrency, obj.minTokens, obj.deadline);

    /***********************************|
    |      Deposits & Invalid Calls     |
    |__________________________________*/

    } else if (functionSignature == DEPOSIT_SIG) {
      // Do nothing for when contract is self depositing
      // This could be use to deposit currency "by accident", which would be locked
      require(msg.sender == address(currency), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKENS_DEPOSITED");

    } else {
      revert("NiftyswapExchange20#onERC1155BatchReceived: INVALID_METHOD");
    }

    return ERC1155_BATCH_RECEIVED_VALUE;
  }

  /**
   * @dev Will pass to onERC115Batch5Received
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes memory _data)
    override public returns(bytes4)
  {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);

    ids[0] = _id;
    amounts[0] = _amount;

    require(
      ERC1155_BATCH_RECEIVED_VALUE == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
      "NiftyswapExchange20#onERC1155Received: INVALID_ONRECEIVED_MESSAGE"
    );

    return ERC1155_RECEIVED_VALUE;
  }

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("NiftyswapExchange20:UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Royalty Functions         |
  |__________________________________*/

  /**
   * @notice Will set the royalties fees and recipient for contracts that don't support ERC-2981
   * @param _fee       Fee pourcentage with a 1000 basis (e.g. 0.3% is 3 and 1% is 10 and 100% is 1000)
   * @param _recipient Address where to send the fees to
   */
  function setRoyaltyInfo(uint256 _fee, address _recipient) onlyOwner public {
    // Don't use IS_ERC2981 in case token contract was updated
    bool isERC2981 = token.supportsInterface(type(IERC2981).interfaceId);
    require(!isERC2981, "NiftyswapExchange20#setRoyaltyInfo: TOKEN SUPPORTS ERC-2981");
    require(_fee < FEE_MULTIPLIER, "NiftyswapExchange20#setRoyaltyInfo: ROYALTY_FEE_IS_TOO_HIGH");
    globalRoyaltyFee = _fee;
    globalRoyaltyRecipient = _recipient;
    emit RoyaltyChanged(_recipient, _fee);
  }

  /**
   * @notice Will send the royalties that _royaltyRecipient can claim, if any 
   * @dev Anyone can call this function such that payout could be distributed 
   *      regularly instead of being claimed. 
   * @param _royaltyRecipient Address that is able to claim royalties
   */
  function sendRoyalties(address _royaltyRecipient) override external {
    uint256 royaltyAmount = royalties[_royaltyRecipient];
    royalties[_royaltyRecipient] = 0;
    TransferHelper.safeTransfer(currency, _royaltyRecipient, royaltyAmount);
  }

  /**
   * @notice Will return how much of currency need to be paid for the royalty 
   * @param _tokenId ID of the erc-1155 token being traded
   * @param _cost    Amount of currency sent/received for the trade
   * @return recipient Address that will be able to claim the royalty
   * @return royalty Amount of currency that will be sent to royalty recipient
   */
  function getRoyaltyInfo(uint256 _tokenId, uint256 _cost) public view returns (address recipient, uint256 royalty) {
    if (IS_ERC2981) {
      // Add a try/catch in-case token *removed* ERC-2981 support
      try IERC2981(address(token)).royaltyInfo(_tokenId, _cost) returns(address _r, uint256 _c) {
        return (_r, _c);
      } catch {
        // Default back to global setting if error occurs
        return (globalRoyaltyRecipient, (_cost.mul(globalRoyaltyFee)).div(1000));
      }

    } else {
      return (globalRoyaltyRecipient, (_cost.mul(globalRoyaltyFee)).div(1000));
    }
  }


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(
    uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory currencyReservesReturn = new uint256[](nIds);
    for (uint256 i = 0; i < nIds; i++) {
      currencyReservesReturn[i] = currencyReserves[_ids[i]];
    }
    return currencyReservesReturn;
  }

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids           Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(
    uint256[] calldata _ids,
    uint256[] calldata _tokensBought)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);
      prices[i] = getBuyPriceWithRoyalty(_ids[i], _tokensBought[i], currencyReserves[_ids[i]], tokenReserve);
    }

    // Return prices
    return prices;
  }

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(
    uint256[] calldata _ids,
    uint256[] calldata _tokensSold)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);
      prices[i] = getSellPriceWithRoyalty(_ids[i], _tokensSold[i], tokenReserve, currencyReserves[_ids[i]]);
    }

    // Return price
    return prices;
  }

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() override external view returns (address) {
    return address(token);
  }

  /**
   * @return Address of the currency contract that is used as currency
   */
  function getCurrencyInfo() override external view returns (address) {
    return (address(currency));
  }

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    // Number of ids
    uint256 nIds = _ids.length;

    // Variables
    uint256[] memory batchTotalSupplies = new uint256[](nIds);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < nIds; i++) {
      batchTotalSupplies[i] = totalSupplies[_ids[i]];
    }

    return batchTotalSupplies;
  }

  /**
   * @return Address of factory that created this exchange.
   */
  function getFactoryAddress() override external view returns (address) {
    return factory;
  }

  /**
   * @return Global royalty fee % if not supporting ERC-2981
   */
  function getGlobalRoyaltyFee() override external view returns (uint256) {
    return globalRoyaltyFee;
  }

  /**
   * @return Global royalty recipient if token not supporting ERC-2981
   */
  function getGlobalRoyaltyRecipient() override external view returns (address) {
    return globalRoyaltyRecipient;
  }

  /**
   * @return Get amount of currency in royalty an address can claim
   * @param _royaltyRecipient Address to check the claimable royalties
   */
  function getRoyalties(address _royaltyRecipient) override external view returns (uint256) {
    return royalties[_royaltyRecipient];
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Divides two numbers and add 1 if there is a rounding error
   * @param a Numerator
   * @param b Denominator
   */
  function divRound(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    return a % b == 0 ? (a/b, false) : ((a/b).add(1), true);
  }

  /**
   * @notice Return Token reserves for given Token ids
   * @dev Assumes that ids are sorted from lowest to highest with no duplicates.
   *      This assumption allows for checking the token reserves only once, otherwise
   *      token reserves need to be re-checked individually or would have to do more expensive
   *      duplication checks.
   * @param _tokenIds Array of IDs to query their Reserve balance.
   * @return Array of Token ids' reserves
   */
  function _getTokenReserves(
    uint256[] memory _tokenIds)
    internal view returns (uint256[] memory)
  {
    uint256 nTokens = _tokenIds.length;

    // Regular balance query if only 1 token, otherwise batch query
    if (nTokens == 1) {
      uint256[] memory tokenReserves = new uint256[](1);
      tokenReserves[0] = token.balanceOf(address(this), _tokenIds[0]);
      return tokenReserves;

    } else {
      // Lazy check preventing duplicates & build address array for query
      address[] memory thisAddressArray = new address[](nTokens);
      thisAddressArray[0] = address(this);

      for (uint256 i = 1; i < nTokens; i++) {
        require(_tokenIds[i-1] < _tokenIds[i], "NiftyswapExchange20#_getTokenReserves: UNSORTED_OR_DUPLICATE_TOKEN_IDS");
        thisAddressArray[i] = address(this);
      }
      return token.balanceOfBatch(thisAddressArray, _tokenIds);
    }
  }

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more thsan 5,000 gas.
   * @return Whether a given interface is supported
   */
  function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
    return interfaceID == type(IERC20).interfaceId ||
      interfaceID == type(IERC165).interfaceId || 
      interfaceID == type(IERC1155).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface INiftyswapExchange20 {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event TokensPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensBoughtIds,
    uint256[] tokensBoughtAmounts,
    uint256[] currencySoldAmounts
  );

  event CurrencyPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensSoldIds,
    uint256[] tokensSoldAmounts,
    uint256[] currencyBoughtAmounts
  );

  event LiquidityAdded(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

  event LiquidityRemoved(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

  event RoyaltyChanged(
    address indexed royaltyRecipient,
    uint256 royaltyFee
  );

  struct SellTokensObj {
    address recipient;            // Who receives the currency
    uint256 minCurrency;          // Total minimum number of currency  expected for all tokens sold
    address[] extraFeeRecipients; // Array of addresses that will receive extra fee
    uint256[] extraFeeAmounts;    // Array of amounts of currency that will be sent as extra fee
    uint256 deadline;             // Timestamp after which the tx isn't valid anymore
  }

  struct AddLiquidityObj {
    uint256[] maxCurrency; // Maximum number of currency to deposit with tokens
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }

  struct RemoveLiquidityObj {
    uint256[] minCurrency; // Minimum number of currency to withdraw
    uint256[] minTokens;   // Minimum number of tokens to withdraw
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }


  /***********************************|
  |        Purchasing Functions       |
  |__________________________________*/
  
  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   * @dev User specifies MAXIMUM inputs (_maxCurrency) and EXACT outputs.
   * @dev Assumes that all trades will be successful, or revert the whole tx
   * @dev Exceeding currency tokens sent will be refunded to recipient
   * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit)
   * @param _tokenIds            Array of Tokens ID that are bought
   * @param _tokensBoughtAmounts Amount of Tokens id bought for each corresponding Token id in _tokenIds
   * @param _maxCurrency         Total maximum amount of currency tokens to spend for all Token ids
   * @param _deadline            Timestamp after which this transaction will be reverted
   * @param _recipient           The address that receives output Tokens and refund
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencySold How much currency was actually sold.
   */
  function buyTokens(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  ) external returns (uint256[] memory);

  /***********************************|
  |         Royalties Functions       |
  |__________________________________*/

  /**
   * @notice Will send the royalties that _royaltyRecipient can claim, if any 
   * @dev Anyone can call this function such that payout could be distributed 
   *      regularly instead of being claimed. 
   * @param _royaltyRecipient Address that is able to claim royalties
   */
  function sendRoyalties(address _royaltyRecipient) external;

  /***********************************|
  |        OnReceive Functions        |
  |__________________________________*/

  /**
   * @notice Handle which method is being called on Token transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _operator The address which called the `safeTransferFrom` function
   * @param _from     The address which previously owned the token
   * @param _id       The id of the token being transferred
   * @param _amount   The amount of tokens being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(address, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _tokenId            Id ot token being sold
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPriceWithRoyalty(uint256 _tokenId, uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external view returns (uint256 price);

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(uint256 _assetSoldAmount,uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _tokenId            Id ot token being sold
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPriceWithRoyalty(uint256 _tokenId, uint256 _assetSoldAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external view returns (uint256 price);

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids          Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(uint256[] calldata _ids, uint256[] calldata _tokensBought) external view returns (uint256[] memory);

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(uint256[] calldata _ids, uint256[] calldata _tokensSold) external view returns (uint256[] memory);

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() external view returns (address);

  /**
   * @return Address of the currency contract that is used as currency
   */
  function getCurrencyInfo() external view returns (address);

  /**
   * @return Address of factory that created this exchange.
   */
  function getFactoryAddress() external view returns (address);

  /**
   * @return Global royalty fee % if not supporting ERC-2981
   */
  function getGlobalRoyaltyFee() external view returns (uint256);  

  /**
   * @return Global royalty recipient if token not supporting ERC-2981
   */
  function getGlobalRoyaltyRecipient() external view returns (address);

  /**
   * @return Get amount of currency in royalty an address can claim
   * @param _royaltyRecipient Address to check the claimable royalties
   */
  function getRoyalties(address _royaltyRecipient) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "../interfaces/INiftyswapExchange.sol";
import "../utils/ReentrancyGuard.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155MintBurn.sol";


/**
 * This Uniswap-like implementation supports ERC-1155 standard tokens
 * with an ERC-1155 based token used as a currency instead of Ether.
 *
 * See https://github.com/0xsequence/erc20-meta-token for a generalized
 * ERC-20 => ERC-1155 token wrapper
 *
 * Liquidity tokens are also ERC-1155 tokens you can find the ERC-1155
 * implementation used here:
 *    https://github.com/horizon-games/multi-token-standard/tree/master/contracts/tokens/ERC1155
 *
 * @dev Like Uniswap, tokens with 0 decimals and low supply are susceptible to significant rounding
 *      errors when it comes to removing liquidity, possibly preventing them to be withdrawn without
 *      some collaboration between liquidity providers.
 */
contract NiftyswapExchange is ReentrancyGuard, ERC1155MintBurn, INiftyswapExchange {
  using SafeMath for uint256;

  /***********************************|
  |       Variables & Constants       |
  |__________________________________*/

  // Variables
  IERC1155 internal token;                        // address of the ERC-1155 token contract
  IERC1155 internal currency;                     // address of the ERC-1155 currency used for exchange
  bool internal currencyPoolBanned;               // Whether the currency token ID can have a pool or not
  address internal factory;                       // address for the factory that created this contract
  uint256 internal currencyID;                    // ID of currency token in ERC-1155 currency contract
  uint256 internal constant FEE_MULTIPLIER = 995; // Multiplier that calculates the fee (1.0%)

  // Mapping variables
  mapping(uint256 => uint256) internal totalSupplies;    // Liquidity pool token supply per Token id
  mapping(uint256 => uint256) internal currencyReserves; // currency Token reserve per Token id


  /***********************************|
  |            Constructor           |
  |__________________________________*/

  /**
   * @notice Create instance of exchange contract with respective token and currency token
   * @param _tokenAddr     The address of the ERC-1155 Token
   * @param _currencyAddr  The address of the ERC-1155 currency Token
   * @param _currencyID    The ID of the ERC-1155 currency Token
   */
  constructor(address _tokenAddr, address _currencyAddr, uint256 _currencyID) public {
    require(
      address(_tokenAddr) != address(0) && _currencyAddr != address(0),
      "NiftyswapExchange#constructor:INVALID_INPUT"
    );
    factory = msg.sender;
    token = IERC1155(_tokenAddr);
    currency = IERC1155(_currencyAddr);
    currencyID = _currencyID;

    // If token and currency are the same contract,
    // need to prevent currency/currency pool to be created.
    currencyPoolBanned = _currencyAddr == _tokenAddr ? true : false;
  }

  /***********************************|
  |        Exchange Functions         |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   * @dev User specifies MAXIMUM inputs (_maxCurrency) and EXACT outputs.
   * @dev Assumes that all trades will be successful, or revert the whole tx
   * @dev Exceeding currency tokens sent will be refunded to recipient
   * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit)
   * @param _tokenIds             Array of Tokens ID that are bought
   * @param _tokensBoughtAmounts  Amount of Tokens id bought for each corresponding Token id in _tokenIds
   * @param _maxCurrency          Total maximum amount of currency tokens to spend for all Token ids
   * @param _deadline             Timestamp after which this transaction will be reverted
   * @param _recipient            The address that receives output Tokens and refund
   * @return currencySold How much currency was actually sold.
   */
  function _currencyToToken(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient)
    internal nonReentrant() returns (uint256[] memory currencySold)
  {
    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange#_currencyToToken: DEADLINE_EXCEEDED");

    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;
    uint256 totalRefundCurrency = _maxCurrency;

    // Initialize variables
    currencySold = new uint256[](nTokens); // Amount of currency tokens sold per ID
    uint256[] memory tokenReserves = new uint256[](nTokens);  // Amount of tokens in reserve for each Token id

    // Get token reserves
    tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes he currency Tokens are already received by contract, but not
    // the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idBought = _tokenIds[i];
      uint256 amountBought = _tokensBoughtAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      require(amountBought > 0, "NiftyswapExchange#_currencyToToken: NULL_TOKENS_BOUGHT");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idBought];

      // Get amount of currency tokens to send for purchase
      // Neither reserves amount have been changed so far in this transaction, so
      // no adjustment to the inputs is needed
      uint256 currencyAmount = getBuyPrice(amountBought, currencyReserve, tokenReserve);

      // Calculate currency token amount to refund (if any) where whatever is not used will be returned
      // Will throw if total cost exceeds _maxCurrency
      totalRefundCurrency = totalRefundCurrency.sub(currencyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencySold[i] = currencyAmount;

      // Update individual currency reseve amount
      currencyReserves[idBought] = currencyReserve.add(currencyAmount);
    }

    // Refund currency token if any
    if (totalRefundCurrency > 0) {
      currency.safeTransferFrom(address(this), _recipient, currencyID, totalRefundCurrency, "");
    }

    // Send Tokens all tokens purchased
    token.safeBatchTransferFrom(address(this), _recipient, _tokenIds, _tokensBoughtAmounts, "");
    return currencySold;
  }

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    // Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange#getBuyPrice: EMPTY_RESERVE");

    // Calculate price with fee
    uint256 numerator = _assetSoldReserve.mul(_assetBoughtAmount).mul(1000);
    uint256 denominator = (_assetBoughtReserve.sub(_assetBoughtAmount)).mul(FEE_MULTIPLIER);
    (price, ) = divRound(numerator, denominator);
    return price; // Will add 1 if rounding error
  }

  /**
   * @notice Convert Tokens _id to currency tokens and transfers Tokens to recipient.
   * @dev User specifies EXACT Tokens _id sold and MINIMUM currency tokens received.
   * @dev Assumes that all trades will be valid, or the whole tx will fail
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _tokenIds          Array of Token IDs that are sold
   * @param _tokensSoldAmounts Array of Amount of Tokens sold for each id in _tokenIds.
   * @param _minCurrency       Minimum amount of currency tokens to receive
   * @param _deadline          Timestamp after which this transaction will be reverted
   * @param _recipient         The address that receives output currency tokens.
   * @return currencyBought How much currency was actually purchased.
   */
  function _tokenToCurrency(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensSoldAmounts,
    uint256 _minCurrency,
    uint256 _deadline,
    address _recipient)
    internal nonReentrant() returns (uint256[] memory currencyBought)
  {
    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;

    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange#_tokenToCurrency: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 totalCurrency = 0; // Total amount of currency tokens to transfer
    currencyBought = new uint256[](nTokens);
    uint256[] memory tokenReserves = new uint256[](nTokens);

    // Get token reserves
    tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the Tokens ids are already received by contract, but not
    // the Tokens Ids. Will return cards not sold if invalid price.

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idSold = _tokenIds[i];
      uint256 amountSold = _tokensSoldAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // If 0 tokens send for this ID, revert
      require(amountSold > 0, "NiftyswapExchange#_tokenToCurrency: NULL_TOKENS_SOLD");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idSold];

      // Get amount of currency that will be received
      // Need to sub amountSold because tokens already added in reserve, which would bias the calculation
      // Don't need to add it for currencyReserve because the amount is added after this calculation
      uint256 currencyAmount = getSellPrice(amountSold, tokenReserve.sub(amountSold), currencyReserve);

      // Increase cost of transaction
      totalCurrency = totalCurrency.add(currencyAmount);

      // Update individual currency reseve amount
      currencyReserves[idSold] = currencyReserve.sub(currencyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencyBought[i] = currencyAmount;
    }

    // If minCurrency is not met
    require(totalCurrency >= _minCurrency, "NiftyswapExchange#_tokenToCurrency: INSUFFICIENT_CURRENCY_AMOUNT");

    // Transfer currency here
    currency.safeTransferFrom(address(this), _recipient, currencyID, totalCurrency, "");

    return currencyBought;
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    //Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange#getSellPrice: EMPTY_RESERVE");

    // Calculate amount to receive (with fee)
    uint256 _assetSoldAmount_withFee = _assetSoldAmount.mul(FEE_MULTIPLIER);
    uint256 numerator = _assetSoldAmount_withFee.mul(_assetBoughtReserve);
    uint256 denominator = _assetSoldReserve.mul(1000).add(_assetSoldAmount_withFee);
    return numerator / denominator; //Rounding errors will favor Niftyswap, so nothing to do
  }

  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /**
   * @notice Deposit less than max currency tokens && exact Tokens (token ID) at current ratio to mint liquidity pool tokens.
   * @dev min_liquidity does nothing when total liquidity pool token supply is 0.
   * @dev Assumes that sender approved this contract on the currency
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider      Address that provides liquidity to the reserve
   * @param _tokenIds      Array of Token IDs where liquidity is added
   * @param _tokenAmounts  Array of amount of Tokens deposited corresponding to each ID provided in _tokenIds
   * @param _maxCurrency   Array of maximum number of tokens deposited for each ID provided in _tokenIds.
   *                       Deposits max amount if total liquidity pool token supply is 0.
   * @param _deadline      Timestamp after which this transaction will be reverted
   */
  function _addLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _tokenAmounts,
    uint256[] memory _maxCurrency,
    uint256 _deadline)
    internal nonReentrant()
  {
    // Requirements
    require(_deadline >= block.timestamp, "NiftyswapExchange#_addLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length; // Number of Token IDs to deposit
    uint256 totalCurrency = 0;          // Total amount of currency tokens to transfer

    // Initialize arrays
    uint256[] memory liquiditiesToMint = new uint256[](nTokens);
    uint256[] memory currencyAmounts = new uint256[](nTokens);
    uint256[] memory tokenReserves = new uint256[](nTokens);

    // Get token reserves
    tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes tokens _ids are deposited already, but not currency tokens
    // as this is calculated and executed below.

    // Loop over all Token IDs to deposit
    for (uint256 i = 0; i < nTokens; i ++) {
      // Store current id and amount from argument arrays
      uint256 tokenId = _tokenIds[i];
      uint256 amount = _tokenAmounts[i];

      // Check if input values are acceptable
      require(_maxCurrency[i] > 0, "NiftyswapExchange#_addLiquidity: NULL_MAX_CURRENCY");
      require(amount > 0, "NiftyswapExchange#_addLiquidity: NULL_TOKENS_AMOUNT");

      // If the token contract and currency contract are the same, prevent the creation
      // of a currency pool.
      if (currencyPoolBanned) {
        require(tokenId != currencyID, "NiftyswapExchange#_addLiquidity: CURRENCY_POOL_FORBIDDEN");
      }

      // Current total liquidity calculated in currency token
      uint256 totalLiquidity = totalSupplies[tokenId];

      // When reserve for this token already exists
      if (totalLiquidity > 0) {

        // Load currency token and Token reserve's supply of Token id
        uint256 currencyReserve = currencyReserves[tokenId]; // Amount not yet in reserve
        uint256 tokenReserve = tokenReserves[i];

        /**
        * Amount of currency tokens to send to token id reserve:
        * X/Y = dx/dy
        * dx = X*dy/Y
        * where
        *   X:  currency total liquidity
        *   Y:  Token _id total liquidity (before tokens were received)
        *   dy: Amount of token _id deposited
        *   dx: Amount of currency to deposit
        *
        * Adding .add(1) if rounding errors so to not favor users incorrectly
        */
        (uint256 currencyAmount, bool rounded) = divRound(amount.mul(currencyReserve), tokenReserve.sub(amount));
        require(_maxCurrency[i] >= currencyAmount, "NiftyswapExchange#_addLiquidity: MAX_CURRENCY_AMOUNT_EXCEEDED");

        // Update currency reserve size for Token id before transfer
        currencyReserves[tokenId] = currencyReserve.add(currencyAmount);

        // Update totalCurrency
        totalCurrency = totalCurrency.add(currencyAmount);

        // Proportion of the liquidity pool to give to current liquidity provider
        // If rounding error occured, round down to favor previous liquidity providers
        // See https://github.com/0xsequence/niftyswap/issues/19
        liquiditiesToMint[i] = (currencyAmount.sub(rounded ? 1 : 0)).mul(totalLiquidity) / currencyReserve;
        currencyAmounts[i] = currencyAmount;

        // Mint liquidity ownership tokens and increase liquidity supply accordingly
        totalSupplies[tokenId] = totalLiquidity.add(liquiditiesToMint[i]);

      } else {
        uint256 maxCurrency = _maxCurrency[i];

        // Otherwise rounding error could end up being significant on second deposit
        require(maxCurrency >= 1000000000, "NiftyswapExchange#_addLiquidity: INVALID_CURRENCY_AMOUNT");

        // Update currency  reserve size for Token id before transfer
        currencyReserves[tokenId] = maxCurrency;

        // Update totalCurrency
        totalCurrency = totalCurrency.add(maxCurrency);

        // Initial liquidity is amount deposited (Incorrect pricing will be arbitraged)
        // uint256 initialLiquidity = _maxCurrency;
        totalSupplies[tokenId] = maxCurrency;

        // Liquidity to mints
        liquiditiesToMint[i] = maxCurrency;
        currencyAmounts[i] = maxCurrency;
      }
    }

    // Mint liquidity pool tokens
    _batchMint(_provider, _tokenIds, liquiditiesToMint, "");

    // Transfer all currency to this contract
    currency.safeTransferFrom(_provider, address(this), currencyID, totalCurrency, abi.encode(DEPOSIT_SIG));

    // Emit event
    emit LiquidityAdded(_provider, _tokenIds, _tokenAmounts, currencyAmounts);
  }

  /**
   * @dev Burn liquidity pool tokens to withdraw currency  && Tokens at current ratio.
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider         Address that removes liquidity to the reserve
   * @param _tokenIds         Array of Token IDs where liquidity is removed
   * @param _poolTokenAmounts Array of Amount of liquidity pool tokens burned for each Token id in _tokenIds.
   * @param _minCurrency      Minimum currency withdrawn for each Token id in _tokenIds.
   * @param _minTokens        Minimum Tokens id withdrawn for each Token id in _tokenIds.
   * @param _deadline         Timestamp after which this transaction will be reverted
   */
  function _removeLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _poolTokenAmounts,
    uint256[] memory _minCurrency,
    uint256[] memory _minTokens,
    uint256 _deadline)
    internal nonReentrant()
  {
    // Input validation
    require(_deadline > block.timestamp, "NiftyswapExchange#_removeLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length;                        // Number of Token IDs to deposit
    uint256 totalCurrency = 0;                                 // Total amount of currency  to transfer
    uint256[] memory tokenAmounts = new uint256[](nTokens);    // Amount of Tokens to transfer for each id
    uint256[] memory currencyAmounts = new uint256[](nTokens); // Amount of currency to transfer for each id
    uint256[] memory tokenReserves = new uint256[](nTokens);

    // Get token reserves
    tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes NIFTY liquidity tokens are already received by contract, but not
    // the currency  nor the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 id = _tokenIds[i];
      uint256 amountPool = _poolTokenAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // Load total liquidity pool token supply for Token _id
      uint256 totalLiquidity = totalSupplies[id];
      require(totalLiquidity > 0, "NiftyswapExchange#_removeLiquidity: NULL_TOTAL_LIQUIDITY");

      // Load currency and Token reserve's supply of Token id
      uint256 currencyReserve = currencyReserves[id];

      // Calculate amount to withdraw for currency  and Token _id
      uint256 currencyAmount = amountPool.mul(currencyReserve) / totalLiquidity;
      uint256 tokenAmount = amountPool.mul(tokenReserve) / totalLiquidity;

      // Verify if amounts to withdraw respect minimums specified
      require(currencyAmount >= _minCurrency[i], "NiftyswapExchange#_removeLiquidity: INSUFFICIENT_CURRENCY_AMOUNT");
      require(tokenAmount >= _minTokens[i], "NiftyswapExchange#_removeLiquidity: INSUFFICIENT_TOKENS");

      // Update total liquidity pool token supply of Token _id
      totalSupplies[id] = totalLiquidity.sub(amountPool);

      // Update currency reserve size for Token id
      currencyReserves[id] = currencyReserve.sub(currencyAmount);

      // Update totalCurrency and tokenAmounts
      totalCurrency = totalCurrency.add(currencyAmount);
      tokenAmounts[i] = tokenAmount;
      currencyAmounts[i] = currencyAmount;
    }

    // Burn liquidity pool tokens for offchain supplies
    _batchBurn(address(this), _tokenIds, _poolTokenAmounts);

    // Transfer total currency  and all Tokens ids
    currency.safeTransferFrom(address(this), _provider, currencyID, totalCurrency, "");
    token.safeBatchTransferFrom(address(this), _provider, _tokenIds, tokenAmounts, "");

    // Emit event
    emit LiquidityRemoved(_provider, _tokenIds, tokenAmounts, currencyAmounts);
  }

  /***********************************|
  |     Receiver Methods Handler      |
  |__________________________________*/

  // Method signatures for onReceive control logic

  // bytes4(keccak256(
  //   "_currencyToToken(uint256[],uint256[],uint256,uint256,address)"
  // ));
  bytes4 internal constant BUYTOKENS_SIG = 0xb2d81047;

  // bytes4(keccak256(
  //   "_tokenToCurrency(uint256[],uint256[],uint256,uint256,address)"
  // ));
  bytes4 internal constant SELLTOKENS_SIG = 0xdb08ec97;

  //  bytes4(keccak256(
  //   "_addLiquidity(address,uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant ADDLIQUIDITY_SIG = 0x82da2b73;

  // bytes4(keccak256(
  //    "_removeLiquidity(address,uint256[],uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant REMOVELIQUIDITY_SIG = 0x5c0bf259;

  // bytes4(keccak256(
  //   "DepositTokens()"
  // ));
  bytes4 internal constant DEPOSIT_SIG = 0xc8c323f9;

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(
    address, // _operator,
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data)
    override public returns(bytes4)
  {
    // This function assumes that the ERC-1155 token contract can
    // only call `onERC1155BatchReceived()` via a valid token transfer.
    // Users must be responsible and only use this Niftyswap exchange
    // contract with ERC-1155 compliant token contracts.

    // Obtain method to call via object signature
    bytes4 functionSignature = abi.decode(_data, (bytes4));

    /***********************************|
    |           Buying Tokens           |
    |__________________________________*/

    if (functionSignature == BUYTOKENS_SIG) {
      // Tokens received need to be currency contract
      require(msg.sender == address(currency), "NiftyswapExchange#onERC1155BatchReceived: INVALID_CURRENCY_TRANSFERRED");
      require(_ids.length == 1, "NiftyswapExchange#onERC1155BatchReceived: INVALID_CURRENCY_IDS_AMOUNT");
      require(_ids[0] == currencyID, "NiftyswapExchange#onERC1155BatchReceived: INVALID_CURRENCY_ID");

      // Decode BuyTokensObj from _data to call _currencyToToken()
      BuyTokensObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, BuyTokensObj));
      address recipient = obj.recipient == address(0x0) ? _from : obj.recipient;

      // Execute trade and retrieve amount of currency spent
      uint256[] memory currencySold = _currencyToToken(obj.tokensBoughtIDs, obj.tokensBoughtAmounts, _amounts[0], obj.deadline, recipient);
      emit TokensPurchase(_from, recipient, obj.tokensBoughtIDs, obj.tokensBoughtAmounts, currencySold);

    /***********************************|
    |           Selling Tokens          |
    |__________________________________*/

    } else if (functionSignature == SELLTOKENS_SIG) {

      // Tokens received need to be Token contract
      require(msg.sender == address(token), "NiftyswapExchange#onERC1155BatchReceived: INVALID_TOKENS_TRANSFERRED");

      // Decode SellTokensObj from _data to call _tokenToCurrency()
      SellTokensObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, SellTokensObj));
      address recipient = obj.recipient == address(0x0) ? _from : obj.recipient;

      // Execute trade and retrieve amount of currency received
      uint256[] memory currencyBought = _tokenToCurrency(_ids, _amounts, obj.minCurrency, obj.deadline, recipient);
      emit CurrencyPurchase(_from, recipient, _ids, _amounts, currencyBought);

    /***********************************|
    |      Adding Liquidity Tokens      |
    |__________________________________*/

    } else if (functionSignature == ADDLIQUIDITY_SIG) {
      // Only allow to receive ERC-1155 tokens from `token` contract
      require(msg.sender == address(token), "NiftyswapExchange#onERC1155BatchReceived: INVALID_TOKEN_TRANSFERRED");

      // Decode AddLiquidityObj from _data to call _addLiquidity()
      AddLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, AddLiquidityObj));
      _addLiquidity(_from, _ids, _amounts, obj.maxCurrency, obj.deadline);

    /***********************************|
    |      Removing iquidity Tokens     |
    |__________________________________*/

    } else if (functionSignature == REMOVELIQUIDITY_SIG) {
      // Tokens received need to be NIFTY-1155 tokens
      require(msg.sender == address(this), "NiftyswapExchange#onERC1155BatchReceived: INVALID_NIFTY_TOKENS_TRANSFERRED");

      // Decode RemoveLiquidityObj from _data to call _removeLiquidity()
      RemoveLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, RemoveLiquidityObj));
      _removeLiquidity(_from, _ids, _amounts, obj.minCurrency, obj.minTokens, obj.deadline);

    /***********************************|
    |      Deposits & Invalid Calls     |
    |__________________________________*/

    } else if (functionSignature == DEPOSIT_SIG) {
      // Do nothing for when contract is self depositing
      // This could be use to deposit currency "by accident", which would be locked
      require(msg.sender == address(currency), "NiftyswapExchange#onERC1155BatchReceived: INVALID_TOKENS_DEPOSITED");
      require(_ids[0] == currencyID, "NiftyswapExchange#onERC1155BatchReceived: INVALID_CURRENCY_ID");

    } else {
      revert("NiftyswapExchange#onERC1155BatchReceived: INVALID_METHOD");
    }

    return ERC1155_BATCH_RECEIVED_VALUE;
  }

  /**
   * @dev Will pass to onERC115Batch5Received
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes memory _data)
    override public returns(bytes4)
  {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);

    ids[0] = _id;
    amounts[0] = _amount;

    require(
      ERC1155_BATCH_RECEIVED_VALUE == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
      "NiftyswapExchange#onERC1155Received: INVALID_ONRECEIVED_MESSAGE"
    );

    return ERC1155_RECEIVED_VALUE;
  }

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("NiftyswapExchange:UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(
    uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory currencyReservesReturn = new uint256[](nIds);
    for (uint256 i = 0; i < nIds; i++) {
      currencyReservesReturn[i] = currencyReserves[_ids[i]];
    }
    return currencyReservesReturn;
  }

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids           Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(
    uint256[] calldata _ids,
    uint256[] calldata _tokensBought)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);
      prices[i] = getBuyPrice(_tokensBought[i], currencyReserves[_ids[i]], tokenReserve);
    }

    // Return prices
    return prices;
  }

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(
    uint256[] calldata _ids,
    uint256[] calldata _tokensSold)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);
      prices[i] = getSellPrice(_tokensSold[i], tokenReserve, currencyReserves[_ids[i]]);
    }

    // Return price
    return prices;
  }

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() override external view returns (address) {
    return address(token);
  }

  /**
   * @return Address of the currency contract that is used as currency and its corresponding id
   */
  function getCurrencyInfo() override external view returns (address, uint256) {
    return (address(currency), currencyID);
  }

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    // Number of ids
    uint256 nIds = _ids.length;

    // Variables
    uint256[] memory batchTotalSupplies = new uint256[](nIds);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < nIds; i++) {
      batchTotalSupplies[i] = totalSupplies[_ids[i]];
    }

    return batchTotalSupplies;
  }

  /**
   * @return Address of factory that created this exchange.
   */
  function getFactoryAddress() override external view returns (address) {
    return factory;
  }

  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Divides two numbers and add 1 if there is a rounding error
   * @param a Numerator
   * @param b Denominator
   */
  function divRound(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    return a % b == 0 ? (a/b, false) : ((a/b).add(1), true);
  }

  /**
   * @notice Return Token reserves for given Token ids
   * @dev Assumes that ids are sorted from lowest to highest with no duplicates.
   *      This assumption allows for checking the token reserves only once, otherwise
   *      token reserves need to be re-checked individually or would have to do more expensive
   *      duplication checks.
   * @param _tokenIds Array of IDs to query their Reserve balance.
   * @return Array of Token ids' reserves
   */
  function _getTokenReserves(
    uint256[] memory _tokenIds)
    internal view returns (uint256[] memory)
  {
    uint256 nTokens = _tokenIds.length;

    // Regular balance query if only 1 token, otherwise batch query
    if (nTokens == 1) {
      uint256[] memory tokenReserves = new uint256[](1);
      tokenReserves[0] = token.balanceOf(address(this), _tokenIds[0]);
      return tokenReserves;

    } else {
      // Lazy check preventing duplicates & build address array for query
      address[] memory thisAddressArray = new address[](nTokens);
      thisAddressArray[0] = address(this);

      for (uint256 i = 1; i < nTokens; i++) {
        require(_tokenIds[i-1] < _tokenIds[i], "NiftyswapExchange#_getTokenReserves: UNSORTED_OR_DUPLICATE_TOKEN_IDS");
        thisAddressArray[i] = address(this);
      }
      return token.balanceOfBatch(thisAddressArray, _tokenIds);
    }
  }

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more thsan 5,000 gas.
   * @return Whether a given interface is supported
   */
  function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(IERC1155).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;        
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface INiftyswapExchange {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event TokensPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensBoughtIds,
    uint256[] tokensBoughtAmounts,
    uint256[] currencySoldAmounts
  );

  event CurrencyPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensSoldIds,
    uint256[] tokensSoldAmounts,
    uint256[] currencyBoughtAmounts
  );

  event LiquidityAdded(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

  event LiquidityRemoved(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

    // OnReceive Objects
  struct BuyTokensObj {
    address recipient;             // Who receives the tokens
    uint256[] tokensBoughtIDs;     // Token IDs to buy
    uint256[] tokensBoughtAmounts; // Amount of token to buy for each ID
    uint256 deadline;              // Timestamp after which the tx isn't valid anymore
  }

  struct SellTokensObj {
    address recipient;   // Who receives the currency
    uint256 minCurrency; // Total minimum number of currency  expected for all tokens sold
    uint256 deadline;    // Timestamp after which the tx isn't valid anymore
  }

  struct AddLiquidityObj {
    uint256[] maxCurrency; // Maximum number of currency to deposit with tokens
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }

  struct RemoveLiquidityObj {
    uint256[] minCurrency; // Minimum number of currency to withdraw
    uint256[] minTokens;   // Minimum number of tokens to withdraw
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }

  /***********************************|
  |        OnReceive Functions        |
  |__________________________________*/

  /**
   * @notice Handle which method is being called on Token transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _operator The address which called the `safeTransferFrom` function
   * @param _from     The address which previously owned the token
   * @param _id       The id of the token being transferred
   * @param _amount   The amount of tokens being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(address, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(uint256 _assetSoldAmount,uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids          Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(uint256[] calldata _ids, uint256[] calldata _tokensBought) external view returns (uint256[] memory);

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(uint256[] calldata _ids, uint256[] calldata _tokensSold) external view returns (uint256[] memory);

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() external view returns (address);

  /**
   * @return Address of the currency contract that is used as currency and its corresponding id
   */
  function getCurrencyInfo() external view returns (address, uint256);

  /**
   * @return Address of factory that created this exchange.
   */
  function getFactoryAddress() external view returns (address);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

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
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
  bool private _notEntered;

  constructor () {
    // Storing an initial non-zero value makes deployment a bit more
    // expensive, but in exchange the refund on every call to nonReentrant
    // will be lower in amount. Since refunds are capped to a percetange of
    // the total transaction's gas, it is best to keep them low in cases
    // like this one, to increase the likelihood of the full refund coming
    // into effect.
    _notEntered = true;
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
    require(_notEntered, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _notEntered = false;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _notEntered = true;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './IERC165.sol';


interface IERC1155 is IERC165 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "./ERC1155.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";
import "../../utils/ERC165.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

pragma solidity 0.7.4;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

pragma solidity 0.7.4;
import "../interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual override public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "./NiftyswapExchange.sol";
import "../interfaces/INiftyswapFactory.sol";


contract NiftyswapFactory is INiftyswapFactory {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  // tokensToExchange[erc1155_token_address][currency_address][currency_token_id]
  mapping(address => mapping(address => mapping(uint256 => address))) public override tokensToExchange;

  /***********************************|
  |             Functions             |
  |__________________________________*/

  /**
   * @notice Creates a NiftySwap Exchange for given token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _currencyID The id of the currency token
   */
  function createExchange(address _token, address _currency, uint256 _currencyID) public override {
    require(tokensToExchange[_token][_currency][_currencyID] == address(0x0), "NiftyswapFactory#createExchange: EXCHANGE_ALREADY_CREATED");

    // Create new exchange contract
    NiftyswapExchange exchange = new NiftyswapExchange(_token, _currency, _currencyID);

    // Store exchange and token addresses
    tokensToExchange[_token][_currency][_currencyID] = address(exchange);

    // Emit event
    emit NewExchange(_token, _currency, _currencyID, address(exchange));
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface INiftyswapFactory {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event NewExchange(address indexed token, address indexed currency, uint256 indexed currencyID, address exchange);


  /***********************************|
  |         Public  Functions         |
  |__________________________________*/

  /**
   * @notice Creates a NiftySwap Exchange for given token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _currencyID The id of the currency token
   */
  function createExchange(address _token, address _currency, uint256 _currencyID) external;

  /**
   * @notice Return address of exchange for corresponding ERC-1155 token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _currencyID The id of the currency token
   */
  function tokensToExchange(address _token, address _currency, uint256 _currencyID) external view returns (address);

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155Meta.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155MintBurn.sol";


/**
 * @notice Allows users to wrap any amount of any ERC-20 token with a 1:1 ratio
 *   of corresponding ERC-1155 tokens with native metaTransaction methods. Each
 *   ERC-20 is assigned an ERC-1155 id for more efficient CALLDATA usage when
 *   doing transfers.
 */
contract MetaERC20Wrapper is ERC1155Meta, ERC1155MintBurn {

  // Variables
  uint256 internal nTokens = 1;                         // Number of ERC-20 tokens registered
  uint256 constant internal ETH_ID = 0x1;               // ID fo tokens representing Ether is 1
  address constant internal ETH_ADDRESS = address(0x1); // Address for tokens representing Ether is 0x00...01
  mapping (address => uint256) internal addressToID;    // Maps the ERC-20 addresses to their metaERC20 id
  mapping (uint256 => address) internal IDtoAddress;    // Maps the metaERC20 ids to their ERC-20 address


  /***********************************|
  |               Events              |
  |__________________________________*/

  event TokenRegistration(address token_address, uint256 token_id);

  /***********************************|
  |            Constructor            |
  |__________________________________*/

  // Register ETH as ID #1 and address 0x1
  constructor() public {
    addressToID[ETH_ADDRESS] = ETH_ID;
    IDtoAddress[ETH_ID] = ETH_ADDRESS;
  }

  /***********************************|
  |         Deposit Functions         |
  |__________________________________*/

  /**
   * Fallback function
   * @dev Deposit ETH in this contract to receive wrapped ETH
   * No parameters provided
   */
  receive () external payable {
    // Deposit ETH sent with transaction
    deposit(ETH_ADDRESS, msg.sender, msg.value);
  }

  /**
   * @dev Deposit ERC20 tokens or ETH in this contract to receive wrapped ERC20s
   * @param _token     The addess of the token to deposit in this contract
   * @param _recipient Address that will receive the ERC-1155 tokens
   * @param _value     The amount of token to deposit in this contract
   * Note: Users must first approve this contract addres on the contract of the ERC20 to be deposited
   */
  function deposit(address _token, address _recipient, uint256 _value)
    public payable
  {
    require(_recipient != address(0x0), "MetaERC20Wrapper#deposit: INVALID_RECIPIENT");

    // Internal ID of ERC-20 token deposited
    uint256 id;

    // Deposit ERC-20 tokens or ETH
    if (_token != ETH_ADDRESS) {

      // Check if transfer passes
      require(msg.value == 0, "MetaERC20Wrapper#deposit: NON_NULL_MSG_VALUE");
      IERC20(_token).transferFrom(msg.sender, address(this), _value);
      require(checkSuccess(), "MetaERC20Wrapper#deposit: TRANSFER_FAILED");

      // Load address token ID
      uint256 addressId = addressToID[_token];

      // Register ID if not already done
      if (addressId == 0) {
        nTokens += 1;             // Increment number of tokens registered
        id = nTokens;             // id of token is the current # of tokens
        IDtoAddress[id] = _token; // Map id to token address
        addressToID[_token] = id; // Register token

        // Emit registration event
        emit TokenRegistration(_token, id);

      } else {
        id = addressId;
      }

    } else {
      require(_value == msg.value, "MetaERC20Wrapper#deposit: INCORRECT_MSG_VALUE");
      id = ETH_ID;
    }

    // Mint meta tokens
    _mint(_recipient, id, _value, "");
  }


  /***********************************|
  |         Withdraw Functions        |
  |__________________________________*/

  /**
   * @dev Withdraw wrapped ERC20 tokens in this contract to receive the original ERC20s or ETH
   * @param _token The addess of the token to withdrww from this contract
   * @param _to The address where the withdrawn tokens will go to
   * @param _value The amount of tokens to withdraw
   */
  function withdraw(address _token, address payable _to, uint256 _value) public {
    uint256 tokenID = getTokenID(_token);
    _withdraw(msg.sender, _to, tokenID, _value);
  }

  /**
   * @dev Withdraw wrapped ERC20 tokens in this contract to receive the original ERC20s or ETH
   * @param _from    Address of users sending the Meta tokens
   * @param _to      The address where the withdrawn tokens will go to
   * @param _tokenID The token ID of the ERC-20 token to withdraw from this contract
   * @param _value   The amount of tokens to withdraw
   */
  function _withdraw(
    address _from,
    address payable _to,
    uint256 _tokenID,
    uint256 _value)
    internal
  {
    // Burn meta tokens
    _burn(_from, _tokenID, _value);

     // Withdraw ERC-20 tokens or ETH
    if (_tokenID != ETH_ID) {
      address token = IDtoAddress[_tokenID];
      IERC20(token).transfer(_to, _value);
      require(checkSuccess(), "MetaERC20Wrapper#withdraw: TRANSFER_FAILED");

    } else {
      require(_to != address(0), "MetaERC20Wrapper#withdraw: INVALID_RECIPIENT");
      (bool success, ) = _to.call{value: _value}("");
      require(success, "MetaERC20Wrapper#withdraw: TRANSFER_FAILED");
    }


  }
  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _value     The amount of tokens being transferred
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address, address payable _from, uint256 _id, uint256 _value, bytes memory)
    public returns(bytes4)
  {
    // Only ERC-1155 from this contract are valid
    require(msg.sender == address(this), "MetaERC20Wrapper#onERC1155Received: INVALID_ERC1155_RECEIVED");
    getIdAddress(_id); // Checks if id is registered

    // Tokens are received, hence need to burn them here
    _withdraw(address(this), _from, _id, _value);

    return ERC1155_RECEIVED_VALUE;
  }

  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _values    An array containing amounts of each token being transferred
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address, address payable _from, uint256[] memory _ids, uint256[] memory _values, bytes memory)
    public returns(bytes4)
  {
    // Only ERC-1155 from this contract are valid
    require(msg.sender == address(this), "MetaERC20Wrapper#onERC1155BatchReceived: INVALID_ERC1155_RECEIVED");

    // Withdraw all tokens
    for ( uint256 i = 0; i < _ids.length; i++) {
      // Checks if id is registered
      getIdAddress(_ids[i]);

      // Tokens are received, hence need to burn them here
      _withdraw(address(this), _from, _ids[i], _values[i]);
    }

    return ERC1155_BATCH_RECEIVED_VALUE;
  }

  /**
   * @notice Return the Meta-ERC20 token ID for the given ERC-20 token address
   * @param _token ERC-20 token address to get the corresponding Meta-ERC20 token ID
   * @return tokenID Meta-ERC20 token ID
   */
  function getTokenID(address _token) public view returns (uint256 tokenID) {
    tokenID = addressToID[_token];
    require(tokenID != 0, "MetaERC20Wrapper#getTokenID: UNREGISTERED_TOKEN");
    return tokenID;
  }

  /**
   * @notice Return the ERC-20 token address for the given Meta-ERC20 token ID
   * @param _id Meta-ERC20 token ID to get the corresponding ERC-20 token address
   * @return token ERC-20 token address
   */
  function getIdAddress(uint256 _id) public view returns (address token) {
    token = IDtoAddress[_id];
    require(token != address(0x0), "MetaERC20Wrapper#getIdAddress: UNREGISTERED_TOKEN");
    return token;
  }

  /**
   * @notice Returns number of tokens currently registered
   */
  function getNTokens() external view returns (uint256) {
    return nTokens;
  }



  /***********************************|
  |          Helper Functions         |
  |__________________________________*/

  /**
    * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
    * function returned 0 bytes or 32 bytes that are not all-zero.
    * Code taken from: https://github.com/dydxprotocol/solo/blob/10baf8e4c3fb9db4d0919043d3e6fdd6ba834046/contracts/protocol/lib/Token.sol
    */
  function checkSuccess()
    private pure
    returns (bool)
  {
    uint256 returnValue = 0;

    /* solium-disable-next-line security/no-inline-assembly */
    assembly {
      // check number of bytes returned from last function call
      switch returndatasize()

        // no bytes returned: assume success
        case 0x0 {
          returnValue := 1
        }

        // 32 bytes returned: check if non-zero
        case 0x20 {
          // copy 32 bytes into scratch space
          returndatacopy(0x0, 0x0, 0x20)

          // load those bytes into returnValue
          returnValue := mload(0x0)
        }

        // not sure what was returned: dont mark as success
        default { }
      
    }

    return returnValue != 0;
  }

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(IERC1155).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;        
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/LibBytes.sol";
import "../../utils/SignatureValidator.sol";


/**
 * @dev ERC-1155 with native metatransaction methods. These additional functions allow users
 *      to presign function calls and allow third parties to execute these on their behalf
 */
contract ERC1155Meta is ERC1155, SignatureValidator {
  using LibBytes for bytes;

  /***********************************|
  |       Variables and Structs       |
  |__________________________________*/

  /**
   * Gas Receipt
   *   feeTokenData : (bool, address, ?unit256)
   *     1st element should be the address of the token
   *     2nd argument (if ERC-1155) should be the ID of the token
   *     Last element should be a 0x0 if ERC-20 and 0x1 for ERC-1155
   */
  struct GasReceipt {
    uint256 gasFee;           // Fixed cost for the tx
    uint256 gasLimitCallback; // Maximum amount of gas the callback in transfer functions can use
    address feeRecipient;     // Address to send payment to
    bytes feeTokenData;       // Data for token to pay for gas
  }

  // Which token standard is used to pay gas fee
  enum FeeTokenType {
    ERC1155,    // 0x00, ERC-1155 token - DEFAULT
    ERC20,      // 0x01, ERC-20 token
    NTypes      // 0x02, number of signature types. Always leave at end.
  }

  // Signature nonce per address
  mapping (address => uint256) internal nonces;


  /***********************************|
  |               Events              |
  |__________________________________*/

  event NonceChange(address indexed signer, uint256 newNonce);


  /****************************************|
  |     Public Meta Transfer Functions     |
  |_______________________________________*/

  /**
   * @notice Allows anyone with a valid signature to transfer _amount amount of a token _id on the bahalf of _from
   * @param _from     Source address
   * @param _to       Target address
   * @param _id       ID of the token type
   * @param _amount   Transfered amount
   * @param _isGasFee Whether gas is reimbursed to executor or not
   * @param _data     Encodes a meta transfer indicator, signature, gas payment receipt and extra transfer data
   *   _data should be encoded as (
   *   (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *   (GasReceipt g, ?bytes transferData)
   * )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   */
  function metaSafeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bool _isGasFee,
    bytes memory _data)
    public
  {
    require(_to != address(0), "ERC1155Meta#metaSafeTransferFrom: INVALID_RECIPIENT");

    // Initializing
    bytes memory transferData;
    GasReceipt memory gasReceipt;

    // Verify signature and extract the signed data
    bytes memory signedData = _signatureValidation(
      _from,
      _data,
      abi.encode(
        META_TX_TYPEHASH,
        _from, // Address as uint256
        _to,   // Address as uint256
        _id,
        _amount,
        _isGasFee ? uint256(1) : uint256(0)  // Boolean as uint256
      )
    );

    // Transfer asset
    _safeTransferFrom(_from, _to, _id, _amount);

    // If Gas is being reimbursed
    if (_isGasFee) {
      (gasReceipt, transferData) = abi.decode(signedData, (GasReceipt, bytes));

      // We need to somewhat protect relayers against gas griefing attacks in recipient contract.
      // Hence we only pass the gasLimit to the recipient such that the relayer knows the griefing
      // limit. Nothing can prevent the receiver to revert the transaction as close to the gasLimit as
      // possible, but the relayer can now only accept meta-transaction gasLimit within a certain range.
      _callonERC1155Received(_from, _to, _id, _amount, gasReceipt.gasLimitCallback, transferData);

      // Transfer gas cost
      _transferGasFee(_from, gasReceipt);

    } else {
      _callonERC1155Received(_from, _to, _id, _amount, gasleft(), signedData);
    }
  }

  /**
   * @notice Allows anyone with a valid signature to transfer multiple types of tokens on the bahalf of _from
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _isGasFee Whether gas is reimbursed to executor or not
   * @param _data     Encodes a meta transfer indicator, signature, gas payment receipt and extra transfer data
   *   _data should be encoded as (
   *   (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *   (GasReceipt g, ?bytes transferData)
   * )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   */
  function metaSafeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bool _isGasFee,
    bytes memory _data)
    public
  {
    require(_to != address(0), "ERC1155Meta#metaSafeBatchTransferFrom: INVALID_RECIPIENT");

    // Initializing
    bytes memory transferData;
    GasReceipt memory gasReceipt;

    // Verify signature and extract the signed data
    bytes memory signedData = _signatureValidation(
      _from,
      _data,
      abi.encode(
        META_BATCH_TX_TYPEHASH,
        _from, // Address as uint256
        _to,   // Address as uint256
        keccak256(abi.encodePacked(_ids)),
        keccak256(abi.encodePacked(_amounts)),
        _isGasFee ? uint256(1) : uint256(0)  // Boolean as uint256
      )
    );

    // Transfer assets
    _safeBatchTransferFrom(_from, _to, _ids, _amounts);

    // If gas fee being reimbursed
    if (_isGasFee) {
      (gasReceipt, transferData) = abi.decode(signedData, (GasReceipt, bytes));

      // We need to somewhat protect relayers against gas griefing attacks in recipient contract.
      // Hence we only pass the gasLimit to the recipient such that the relayer knows the griefing
      // limit. Nothing can prevent the receiver to revert the transaction as close to the gasLimit as
      // possible, but the relayer can now only accept meta-transaction gasLimit within a certain range.
      _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasReceipt.gasLimitCallback, transferData);

      // Handle gas reimbursement
      _transferGasFee(_from, gasReceipt);

    } else {
      _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), signedData);
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Approve the passed address to spend on behalf of _from if valid signature is provided
   * @param _owner     Address that wants to set operator status  _spender
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   * @param _isGasFee  Whether gas will be reimbursed or not, with vlid signature
   * @param _data      Encodes signature and gas payment receipt
   *   _data should be encoded as (
   *     (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *     (GasReceipt g)
   *   )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   */
  function metaSetApprovalForAll(
    address _owner,
    address _operator,
    bool _approved,
    bool _isGasFee,
    bytes memory _data)
    public
  {
    // Verify signature and extract the signed data
    bytes memory signedData = _signatureValidation(
      _owner,
      _data,
      abi.encode(
        META_APPROVAL_TYPEHASH,
        _owner,                              // Address as uint256
        _operator,                           // Address as uint256
        _approved ? uint256(1) : uint256(0), // Boolean as uint256
        _isGasFee ? uint256(1) : uint256(0)  // Boolean as uint256
      )
    );

    // Update operator status
    operators[_owner][_operator] = _approved;

    // Emit event
    emit ApprovalForAll(_owner, _operator, _approved);

    // Handle gas reimbursement
    if (_isGasFee) {
      GasReceipt memory gasReceipt = abi.decode(signedData, (GasReceipt));
      _transferGasFee(_owner, gasReceipt);
    }
  }


  /****************************************|
  |      Signature Validation Functions     |
  |_______________________________________*/

  // keccak256(
  //   "metaSafeTransferFrom(address,address,uint256,uint256,bool,bytes)"
  // );
  bytes32 internal constant META_TX_TYPEHASH = 0xce0b514b3931bdbe4d5d44e4f035afe7113767b7db71949271f6a62d9c60f558;

  // keccak256(
  //   "metaSafeBatchTransferFrom(address,address,uint256[],uint256[],bool,bytes)"
  // );
  bytes32 internal constant META_BATCH_TX_TYPEHASH = 0xa3d4926e8cf8fe8e020cd29f514c256bc2eec62aa2337e415f1a33a4828af5a0;

  // keccak256(
  //   "metaSetApprovalForAll(address,address,bool,bool,bytes)"
  // );
  bytes32 internal constant META_APPROVAL_TYPEHASH = 0xf5d4c820494c8595de274c7ff619bead38aac4fbc3d143b5bf956aa4b84fa524;

  /**
   * @notice Verifies signatures for this contract
   * @param _signer     Address of signer
   * @param _sigData    Encodes signature, gas payment receipt and transfer data (if any)
   * @param _encMembers Encoded EIP-712 type members (except nonce and _data), all need to be 32 bytes size
   * @dev _data should be encoded as (
   *   (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *   (GasReceipt g, ?bytes transferData)
   * )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   * @dev A valid nonce is a nonce that is within 100 value from the current nonce
   */
  function _signatureValidation(
    address _signer,
    bytes memory _sigData,
    bytes memory _encMembers)
    internal returns (bytes memory signedData)
  {
    bytes memory sig;

    // Get signature and data to sign
    (sig, signedData) = abi.decode(_sigData, (bytes, bytes));

    // Get current nonce and nonce used for signature
    uint256 currentNonce = nonces[_signer];        // Lowest valid nonce for signer
    uint256 nonce = uint256(sig.readBytes32(65));  // Nonce passed in the signature object

    // Verify if nonce is valid
    require(
      (nonce >= currentNonce) && (nonce < (currentNonce + 100)),
      "ERC1155Meta#_signatureValidation: INVALID_NONCE"
    );

    // Take hash of bytes arrays
    bytes32 hash = hashEIP712Message(keccak256(abi.encodePacked(_encMembers, nonce, keccak256(signedData))));

    // Complete data to pass to signer verifier
    bytes memory fullData = abi.encodePacked(_encMembers, nonce, signedData);

    //Update signature nonce
    nonces[_signer] = nonce + 1;
    emit NonceChange(_signer, nonce + 1);

    // Verify if _from is the signer
    require(isValidSignature(_signer, hash, fullData, sig), "ERC1155Meta#_signatureValidation: INVALID_SIGNATURE");
    return signedData;
  }

  /**
   * @notice Returns the current nonce associated with a given address
   * @param _signer Address to query signature nonce for
   */
  function getNonce(address _signer)
    public view returns (uint256 nonce)
  {
    return nonces[_signer];
  }


  /***********************************|
  |    Gas Reimbursement Functions    |
  |__________________________________*/

  /**
   * @notice Will reimburse tx.origin or fee recipient for the gas spent execution a transaction
   *         Can reimbuse in any ERC-20 or ERC-1155 token
   * @param _from  Address from which the payment will be made from
   * @param _g     GasReceipt object that contains gas reimbursement information
   */
  function _transferGasFee(address _from, GasReceipt memory _g)
      internal
  {
    // Pop last byte to get token fee type
    uint8 feeTokenTypeRaw = uint8(_g.feeTokenData.popLastByte());

    // Ensure valid fee token type
    require(
      feeTokenTypeRaw < uint8(FeeTokenType.NTypes),
      "ERC1155Meta#_transferGasFee: UNSUPPORTED_TOKEN"
    );

    // Convert to FeeTokenType corresponding value
    FeeTokenType feeTokenType = FeeTokenType(feeTokenTypeRaw);

    // Declarations
    address tokenAddress;
    address feeRecipient;
    uint256 tokenID;
    uint256 fee = _g.gasFee;

    // If receiver is 0x0, then anyone can claim, otherwise, refund addresse provided
    feeRecipient = _g.feeRecipient == address(0) ? msg.sender : _g.feeRecipient;

    // Fee token is ERC1155
    if (feeTokenType == FeeTokenType.ERC1155) {
      (tokenAddress, tokenID) = abi.decode(_g.feeTokenData, (address, uint256));

      // Fee is paid from this ERC1155 contract
      if (tokenAddress == address(this)) {
        _safeTransferFrom(_from, feeRecipient, tokenID, fee);

        // No need to protect against griefing since recipient (if contract) is most likely owned by the relayer
        _callonERC1155Received(_from, feeRecipient, tokenID, gasleft(), fee, "");

      // Fee is paid from another ERC-1155 contract
      } else {
        IERC1155(tokenAddress).safeTransferFrom(_from, feeRecipient, tokenID, fee, "");
      }

    // Fee token is ERC20
    } else {
      tokenAddress = abi.decode(_g.feeTokenData, (address));
      require(
        IERC20(tokenAddress).transferFrom(_from, feeRecipient, fee),
        "ERC1155Meta#_transferGasFee: ERC20_TRANSFER_FAILED"
      );
    }
  }
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/

pragma solidity 0.7.4;


library LibBytes {
  using LibBytes for bytes;

  /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

  /**
   * @dev Pops the last byte off of a byte array by modifying its length.
   * @param b Byte array that will be modified.
   * @return result The byte that was popped off.
   */
  function popLastByte(bytes memory b)
    internal
    pure
    returns (bytes1 result)
  {
    require(
      b.length > 0,
      "LibBytes#popLastByte: GREATER_THAN_ZERO_LENGTH_REQUIRED"
    );

    // Store last byte.
    result = b[b.length - 1];

    assembly {
      // Decrement length of byte array.
      let newLen := sub(mload(b), 1)
      mstore(b, newLen)
    }
    return result;
  }


  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    require(
      b.length >= index + 32,
      "LibBytes#readBytes32: GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
    );

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }
}

pragma solidity 0.7.4;

import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";
import "./LibEIP712.sol";


/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator is LibEIP712 {
  using LibBytes for bytes;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // bytes4(keccak256("isValidSignature(bytes,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

  // Allowed signature types.
  enum SignatureType {
    Illegal,         // 0x00, default value
    EIP712,          // 0x01
    EthSign,         // 0x02
    WalletBytes,     // 0x03 To call isValidSignature(bytes, bytes) on wallet contract
    WalletBytes32,   // 0x04 To call isValidSignature(bytes32, bytes) on wallet contract
    NSignatureTypes  // 0x05, number of signature types. Always leave at end.
  }


  /***********************************|
  |        Signature Functions        |
  |__________________________________*/

  /**
   * @dev Verifies that a hash has been signed by the given signer.
   * @param _signerAddress  Address that should have signed the given hash.
   * @param _hash           Hash of the EIP-712 encoded data
   * @param _data           Full EIP-712 data structure that was hashed and signed
   * @param _sig            Proof that the hash has been signed by signer.
   *      For non wallet signatures, _sig is expected to be an array tightly encoded as
   *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
   * @return isValid True if the address recovered from the provided signature matches the input signer address.
   */
  function isValidSignature(
    address _signerAddress,
    bytes32 _hash,
    bytes memory _data,
    bytes memory _sig
  )
    public
    view
    returns (bool isValid)
  {
    require(
      _sig.length > 0,
      "SignatureValidator#isValidSignature: LENGTH_GREATER_THAN_0_REQUIRED"
    );

    require(
      _signerAddress != address(0x0),
      "SignatureValidator#isValidSignature: INVALID_SIGNER"
    );

    // Pop last byte off of signature byte array.
    uint8 signatureTypeRaw = uint8(_sig.popLastByte());

    // Ensure signature is supported
    require(
      signatureTypeRaw < uint8(SignatureType.NSignatureTypes),
      "SignatureValidator#isValidSignature: UNSUPPORTED_SIGNATURE"
    );

    // Extract signature type
    SignatureType signatureType = SignatureType(signatureTypeRaw);

    // Variables are not scoped in Solidity.
    uint8 v;
    bytes32 r;
    bytes32 s;
    address recovered;

    // Always illegal signature.
    // This is always an implicit option since a signer can create a
    // signature array with invalid type or length. We may as well make
    // it an explicit option. This aids testing and analysis. It is
    // also the initialization value for the enum type.
    if (signatureType == SignatureType.Illegal) {
      revert("SignatureValidator#isValidSignature: ILLEGAL_SIGNATURE");


    // Signature using EIP712
    } else if (signatureType == SignatureType.EIP712) {
      require(
        _sig.length == 97,
        "SignatureValidator#isValidSignature: LENGTH_97_REQUIRED"
      );
      r = _sig.readBytes32(0);
      s = _sig.readBytes32(32);
      v = uint8(_sig[64]);
      recovered = ecrecover(_hash, v, r, s);
      isValid = _signerAddress == recovered;
      return isValid;


    // Signed using web3.eth_sign() or Ethers wallet.signMessage()
    } else if (signatureType == SignatureType.EthSign) {
      require(
        _sig.length == 97,
        "SignatureValidator#isValidSignature: LENGTH_97_REQUIRED"
      );
      r = _sig.readBytes32(0);
      s = _sig.readBytes32(32);
      v = uint8(_sig[64]);
      recovered = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
      );
      isValid = _signerAddress == recovered;
      return isValid;


    // Signature verified by wallet contract with data validation.
    } else if (signatureType == SignatureType.WalletBytes) {
      isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
      return isValid;


    // Signature verified by wallet contract without data validation.
    } else if (signatureType == SignatureType.WalletBytes32) {
      isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
      return isValid;
    }

    // Anything else is illegal (We do not return false because
    // the signature may actually be valid, just not in a format
    // that we currently support. In this case returning false
    // may lead the caller to incorrectly believe that the
    // signature was invalid.)
    revert("SignatureValidator#isValidSignature: UNSUPPORTED_SIGNATURE");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


interface  IERC1271Wallet {

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   *
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);
}

/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity 0.7.4;


contract LibEIP712 {

  /***********************************|
  |             Constants             |
  |__________________________________*/

  // keccak256(
  //   "EIP712Domain(address verifyingContract)"
  // );
  bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

  // EIP-191 Header
  string constant internal EIP191_HEADER = "\x19\x01";

  /***********************************|
  |          Hashing Function         |
  |__________________________________*/

  /**
   * @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
   * @param hashStruct The EIP712 hash struct.
   * @return result EIP712 hash applied to this EIP712 Domain.
   */
  function hashEIP712Message(bytes32 hashStruct)
      internal
      view
      returns (bytes32 result)
  {
    return keccak256(
      abi.encodePacked(
        EIP191_HEADER,
        keccak256(
          abi.encode(
            DOMAIN_SEPARATOR_TYPEHASH,
            address(this)
          )
        ),
        hashStruct
    ));
  }
}

pragma solidity 0.7.4;

import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";

interface IERC20Wrapper is IERC1155 {

  /***********************************|
  |         Deposit Functions         |
  |__________________________________*/

  /**
   * Fallback function
   * @dev Deposit ETH in this contract to receive wrapped ETH
   */
  receive () external payable;

  /**
   * @dev Deposit ERC20 tokens or ETH in this contract to receive wrapped ERC20s
   * @param _token     The addess of the token to deposit in this contract
   * @param _recipient Address that will receive the ERC-1155 tokens
   * @param _value     The amount of token to deposit in this contract
   * Note: Users must first approve this contract addres on the contract of the ERC20 to be deposited
   */
  function deposit(address _token, address _recipient, uint256 _value) external payable;


  /***********************************|
  |         Withdraw Functions        |
  |__________________________________*/

  /**
   * @dev Withdraw wrapped ERC20 tokens in this contract to receive the original ERC20s or ETH
   * @param _token The addess of the token to withdrww from this contract
   * @param _to The address where the withdrawn tokens will go to
   * @param _value The amount of tokens to withdraw
   */
  function withdraw(address _token, address payable _to, uint256 _value) external;


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Return the Meta-ERC20 token ID for the given ERC-20 token address
   * @param _token ERC-20 token address to get the corresponding Meta-ERC20 token ID
   * @return tokenID Meta-ERC20 token ID
   */
  function getTokenID(address _token) external view returns (uint256 tokenID);

  /**
   * @notice Return the ERC-20 token address for the given Meta-ERC20 token ID
   * @param _id Meta-ERC20 token ID to get the corresponding ERC-20 token address
   * @return token ERC-20 token address
   */
  function getIdAddress(uint256 _id) external view returns (address token) ;

  /**
   * @notice Returns number of tokens currently registered
   */
  function getNTokens() external view;


  /***********************************|
  |        OnReceive Functions        |
  |__________________________________*/

  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _value     The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address payable _from, uint256 _id, uint256 _value, bytes calldata _data ) external returns(bytes4);

  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _values    An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address payable _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../interfaces/INiftyswapExchange.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc20-meta-token/contracts/interfaces/IERC20Wrapper.sol";

/**
 * @notice Will allow users to wrap their  ERC-20 into ERC-1155 tokens
 *         and pass their order to niftyswap. All funds will be returned
 *         to original owner and this contact should never hold any funds
 *         outside of a given wrap transaction.
 * @dev Hardcoding addresses for simplicity, easy to generalize if arguments
 *      are passed in functions, but adds a bit of complexity.
 */
contract WrapAndNiftyswap {

  IERC20Wrapper immutable public tokenWrapper; // ERC-20 to ERC-1155 token wrapper contract
  address immutable public exchange;           // Niftyswap exchange to use
  address immutable public erc20;              // ERC-20 used in niftyswap exchange
  address immutable public erc1155;            // ERC-1155 used in niftyswap exchange

  uint256 immutable internal wrappedTokenID; // ID of the wrapped token
  bool internal isInNiftyswap;               // Whether niftyswap is being called

  /**
   * @notice Registers contract addresses
   */
  constructor(
    address payable _tokenWrapper,
    address _exchange,
    address _erc20,
    address _erc1155
  ) public {
    require(
      _tokenWrapper != address(0x0) &&
      _exchange != address(0x0) &&
      _erc20 != address(0x0) &&
      _erc1155 != address(0x0),
      "INVALID CONSTRUCTOR ARGUMENT"
    );

    tokenWrapper = IERC20Wrapper(_tokenWrapper);
    exchange = _exchange;
    erc20 = _erc20;
    erc1155 = _erc1155;

    // Approve wrapper contract for ERC-20
    // NOTE: This could potentially fail in some extreme usage as it's only
    // set once, but can easily redeploy this contract if that's the case.
    IERC20(_erc20).approve(_tokenWrapper, 2**256-1);

    // Store wrapped token ID
    wrappedTokenID = IERC20Wrapper(_tokenWrapper).getTokenID(_erc20);
  }

  /**
   * @notice Wrap ERC-20 to ERC-1155 and swap them
   * @dev User must approve this contract for ERC-20 first
   * @param _maxAmount       Maximum amount of ERC-20 user wants to spend
   * @param _recipient       Address where to send tokens
   * @param _niftyswapOrder  Encoded Niftyswap order passed in data field of safeTransferFrom()
   */
  function wrapAndSwap(
    uint256 _maxAmount,
    address _recipient,
    bytes calldata _niftyswapOrder
  ) external
  {
    // Decode niftyswap order
    INiftyswapExchange.BuyTokensObj memory obj;
    (, obj) = abi.decode(_niftyswapOrder, (bytes4, INiftyswapExchange.BuyTokensObj));
    
    // Force the recipient to not be set, otherwise wrapped token refunded will be 
    // sent to the user and we won't be able to unwrap it.
    require(
      obj.recipient == address(0x0) || obj.recipient == address(this), 
      "WrapAndNiftyswap#wrapAndSwap: ORDER RECIPIENT MUST BE THIS CONTRACT"
    );

    // Pull ERC-20 amount specified in order
    IERC20(erc20).transferFrom(msg.sender, address(this), _maxAmount);

    // Wrap ERC-20s
    tokenWrapper.deposit(erc20, address(this), _maxAmount);

    // Swap on Niftyswap
    isInNiftyswap = true;
    tokenWrapper.safeTransferFrom(address(this), exchange, wrappedTokenID, _maxAmount, _niftyswapOrder);
    isInNiftyswap = false;

    // Unwrap ERC-20 and send to receiver, if any received
    uint256 wrapped_token_amount = tokenWrapper.balanceOf(address(this), wrappedTokenID);
    if (wrapped_token_amount > 0) {
      tokenWrapper.withdraw(erc20, payable(_recipient), wrapped_token_amount);
    }

    // Transfer tokens purchased
    IERC1155(erc1155).safeBatchTransferFrom(address(this), _recipient, obj.tokensBoughtIDs, obj.tokensBoughtAmounts, "");
  }

  /**
   * @notice Accepts only tokenWrapper tokens 
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155Received(address, address, uint256, uint256, bytes calldata)
    external returns(bytes4)
  {
    if (msg.sender != address(tokenWrapper)) {
      revert("WrapAndNiftyswap#onERC1155Received: INVALID_ERC1155_RECEIVED");
    }
    return IERC1155TokenReceiver.onERC1155Received.selector;
  }

  /**
   * @notice If receives tracked ERC-1155, it will send a sell order to niftyswap and unwrap received
   *         wrapped token. The unwrapped tokens will be sent to the sender.
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address, 
    address _from, 
    uint256[] calldata _ids, 
    uint256[] calldata _amounts, 
    bytes calldata _niftyswapOrder
  )
    external returns(bytes4)
  { 
    // If coming from niftyswap or wrapped token, ignore
    if (isInNiftyswap || msg.sender == address(tokenWrapper)){
      return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
    } else if (msg.sender != erc1155) {
      revert("WrapAndNiftyswap#onERC1155BatchReceived: INVALID_ERC1155_RECEIVED");
    }

    // Decode transfer data
    INiftyswapExchange.SellTokensObj memory obj;
    (,obj) = abi.decode(_niftyswapOrder, (bytes4, INiftyswapExchange.SellTokensObj));

    require(
      obj.recipient == address(0x0) || obj.recipient == address(this), 
      "WrapAndNiftyswap#onERC1155BatchReceived: ORDER RECIPIENT MUST BE THIS CONTRACT"
    );

    // Swap on Niftyswap
    isInNiftyswap = true;
    IERC1155(msg.sender).safeBatchTransferFrom(address(this), exchange, _ids, _amounts, _niftyswapOrder);
    isInNiftyswap = false;

    // Send to recipient the unwrapped ERC-20, if any
    uint256 wrapped_token_amount = tokenWrapper.balanceOf(address(this), wrappedTokenID);
    if (wrapped_token_amount > 0) {
      // Doing it in 2 calls so tx history is more consistent
      tokenWrapper.withdraw(erc20, payable(address(this)), wrapped_token_amount);
      IERC20(erc20).transfer(_from, wrapped_token_amount);
    }

    return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";
import "../../utils/ERC165.sol";


/**
 * @dev Implementation of Multi-Token Standard contract. This implementation of the ERC-1155 standard
 *      utilizes the fact that balances of different token ids can be concatenated within individual
 *      uint256 storage slots. This allows the contract to batch transfer tokens more efficiently at
 *      the cost of limiting the maximum token balance each address can hold. This limit is
 *      2^IDS_BITS_SIZE, which can be adjusted below. In practice, using IDS_BITS_SIZE smaller than 16
 *      did not lead to major efficiency gains.
 */
contract ERC1155PackedBalance is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Constants regarding bin sizes for balance packing
  // IDS_BITS_SIZE **MUST** be a power of 2 (e.g. 2, 4, 8, 16, 32, 64, 128)
  uint256 internal constant IDS_BITS_SIZE   = 32;                  // Max balance amount in bits per token ID
  uint256 internal constant IDS_PER_UINT256 = 256 / IDS_BITS_SIZE; // Number of ids per uint256

  // Operations for _updateIDBalance
  enum Operations { Add, Sub }

  // Token IDs balances ; balances[address][id] => balance (using array instead of mapping for efficiency)
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operators
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155PackedBalance#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155PackedBalance#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155PackedBalance#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155PackedBalance#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    //Update balances
    _updateIDBalance(_from, _id, _amount, Operations.Sub); // Subtract amount from sender
    _updateIDBalance(_to,   _id, _amount, Operations.Add); // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas:_gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155PackedBalance#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    uint256 nTransfer = _ids.length; // Number of transfer to execute
    require(nTransfer == _amounts.length, "ERC1155PackedBalance#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    if (_from != _to && nTransfer > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balFrom = _viewUpdateBinValue(balances[_from][bin], index, _amounts[0], Operations.Sub);
      uint256 balTo = _viewUpdateBinValue(balances[_to][bin], index, _amounts[0], Operations.Add);

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          balances[_from][lastBin] = balFrom;
          balances[_to][lastBin] = balTo;

          balFrom = balances[_from][bin];
          balTo = balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balFrom = _viewUpdateBinValue(balFrom, index, _amounts[i], Operations.Sub);
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      balances[_from][bin] = balFrom;
      balances[_to][bin] = balTo;

    // If transfer to self, just make sure all amounts are valid
    } else {
      for (uint256 i = 0; i < nTransfer; i++) {
        require(balanceOf(_from, _ids[i]) >= _amounts[i], "ERC1155PackedBalance#_safeBatchTransferFrom: UNDERFLOW");
      }
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155PackedBalance#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |     Public Balance Functions      |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    uint256 bin;
    uint256 index;

    //Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);
    return getValueInBin(balances[_owner][bin], index);
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders (sorted owners will lead to less gas usage)
   * @param _ids    ID of the Tokens (sorted ids will lead to less gas usage
   * @return The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    uint256 n_owners = _owners.length;
    require(n_owners == _ids.length, "ERC1155PackedBalance#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // First values
    (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);
    uint256 balance_bin = balances[_owners[0]][bin];
    uint256 last_bin = bin;

    // Initialization
    uint256[] memory batchBalances = new uint256[](n_owners);
    batchBalances[0] = getValueInBin(balance_bin, index);

    // Iterate over each owner and token ID
    for (uint256 i = 1; i < n_owners; i++) {
      (bin, index) = getIDBinIndex(_ids[i]);

      // SLOAD if bin changed for the same owner or if owner changed
      if (bin != last_bin || _owners[i-1] != _owners[i]) {
        balance_bin = balances[_owners[i]][bin];
        last_bin = bin;
      }

      batchBalances[i] = getValueInBin(balance_bin, index);
    }

    return batchBalances;
  }


  /***********************************|
  |      Packed Balance Functions     |
  |__________________________________*/

  /**
   * @notice Update the balance of a id for a given address
   * @param _address    Address to update id balance
   * @param _id         Id to update balance of
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to id balance
   *   Operations.Sub: Substract _amount from id balance
   */
  function _updateIDBalance(address _address, uint256 _id, uint256 _amount, Operations _operation)
    internal
  {
    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // Update balance
    balances[_address][bin] = _viewUpdateBinValue(balances[_address][bin], index, _amount, _operation);
  }

  /**
   * @notice Update a value in _binValues
   * @param _binValues  Uint256 containing values of size IDS_BITS_SIZE (the token balances)
   * @param _index      Index of the value in the provided bin
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to value in _binValues at _index
   *   Operations.Sub: Substract _amount from value in _binValues at _index
   */
  function _viewUpdateBinValue(uint256 _binValues, uint256 _index, uint256 _amount, Operations _operation)
    internal pure returns (uint256 newBinValues)
  {
    uint256 shift = IDS_BITS_SIZE * _index;
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    if (_operation == Operations.Add) {
      newBinValues = _binValues + (_amount << shift);
      require(newBinValues >= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW");
      require(
        ((_binValues >> shift) & mask) + _amount < 2**IDS_BITS_SIZE, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW"
      );

    } else if (_operation == Operations.Sub) {
      newBinValues = _binValues - (_amount << shift);
      require(newBinValues <= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW");
      require(
        ((_binValues >> shift) & mask) >= _amount, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW"
      );

    } else {
      revert("ERC1155PackedBalance#_viewUpdateBinValue: INVALID_BIN_WRITE_OPERATION"); // Bad operation
    }

    return newBinValues;
  }

  /**
  * @notice Return the bin number and index within that bin where ID is
  * @param _id  Token id
  * @return bin index (Bin number, ID"s index within that bin)
  */
  function getIDBinIndex(uint256 _id)
    public pure returns (uint256 bin, uint256 index)
  {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 _index)
    public pure returns (uint256)
  {
    // require(_index < IDS_PER_UINT256) is not required since getIDBinIndex ensures `_index < IDS_PER_UINT256`

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    // Shift amount
    uint256 rightShift = IDS_BITS_SIZE * _index;
    return (_binValues >> rightShift) & mask;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "../../interfaces/IERC1155Metadata.sol";
import "../../utils/ERC165.sol";


/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is IERC1155Metadata, ERC165 {
  // URI's default URI prefix
  string internal baseMetadataURI;

  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   * @return URI string
   */
  function uri(uint256 _id) public override view returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


interface IERC1155Metadata {

  event URI(string _uri, uint256 indexed _id);

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../tokens/ERC1155PackedBalance/ERC1155MintBurnPackedBalance.sol";
import "../tokens/ERC1155/ERC1155Metadata.sol";


contract ERC1155MintBurnPackedBalanceMock is ERC1155MintBurnPackedBalance, ERC1155Metadata {

  /***********************************|
  |               ERC165              |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @dev Parent contract inheriting multiple contracts with supportsInterface()
   *      need to implement an overriding supportsInterface() function specifying
   *      all inheriting contracts that have a supportsInterface() function.
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(
    bytes4 _interfaceID
  ) public override(
    ERC1155PackedBalance,
    ERC1155Metadata
  ) pure virtual returns (bool) {
    return super.supportsInterface(_interfaceID);
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @dev Mint _value of tokens of a given id
   * @param _to The address to mint tokens to.
   * @param _id token id to mint
   * @param _value The amount to be minted
   * @param _data Data to be passed if receiver is contract
   */
  function mintMock(address _to, uint256 _id, uint256 _value, bytes memory _data)
    public
  {
    _mint(_to, _id, _value, _data);
  }

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to The address to mint tokens to.
   * @param _ids Array of ids to mint
   * @param _values Array of amount of tokens to mint per id
   * @param _data Data to be passed if receiver is contract
   */
  function batchMintMock(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data)
    public
  {
    _batchMint(_to, _ids, _values, _data);
  }


  /***********************************|
  |         Burning Functions         |
  |__________________________________*/

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _id token id to burn
   * @param _value The amount to be burned
   */
  function burnMock(address _from, uint256 _id, uint256 _value)
    public
  {
    _burn(_from, _id, _value);
  }

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _ids Array of token ids to burn
   * @param _values Array of the amount to be burned
   */
  function batchBurnMock(address _from, uint256[] memory _ids, uint256[] memory _values)
    public
  {
    _batchBurn(_from, _ids, _values);
  }


  /***********************************|
  |       Unsupported Functions       |
  |__________________________________*/

  fallback () external {
    revert("ERC1155MetaMintBurnPackedBalanceMock: INVALID_METHOD");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "./ERC1155PackedBalance.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions.
 */
contract ERC1155MintBurnPackedBalance is ERC1155PackedBalance {

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    //Add _amount
    _updateIDBalance(_to,   _id, _amount, Operations.Add); // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each (_ids[i], _amounts[i]) pair
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurnPackedBalance#_batchMint: INVALID_ARRAYS_LENGTH");

    if (_ids.length > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balTo = _viewUpdateBinValue(balances[_to][bin], index, _amounts[0], Operations.Add);

      // Number of transfer to execute
      uint256 nTransfer = _ids.length;

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          balances[_to][lastBin] = balTo;
          balTo = balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      balances[_to][bin] = balTo;
    }

    // //Emit event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    // Substract _amount
    _updateIDBalance(_from, _id, _amount, Operations.Sub);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @dev This batchBurn method does not implement the most efficient way of updating
   *      balances to reduce the potential bug surface as this function is expected to
   *      be less common than transfers. EIP-2200 makes this method significantly
   *      more efficient already for packed balances.
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of burning to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurnPackedBalance#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all burning
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      _updateIDBalance(_from,   _ids[i], _amounts[i], Operations.Sub); // Add amount to recipient
    }

    // Emit batch burn event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@0xsequence/erc-1155/contracts/mocks/ERC1155MintBurnPackedBalanceMock.sol";


contract ERC1155PackedBalanceMock is ERC1155MintBurnPackedBalanceMock {

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../tokens/ERC1155/ERC1155MintBurn.sol";
import "../tokens/ERC1155/ERC1155Metadata.sol";


contract ERC1155MintBurnMock is ERC1155MintBurn, ERC1155Metadata {

  /**
   * @notice Query if a contract implements an interface
   * @dev Parent contract inheriting multiple contracts with supportsInterface()
   *      need to implement an overriding supportsInterface() function specifying
   *      all inheriting contracts that have a supportsInterface() function.
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(
    bytes4 _interfaceID
  ) public override(
    ERC1155,
    ERC1155Metadata
  ) pure virtual returns (bool) {
    return super.supportsInterface(_interfaceID);
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @dev Mint _value of tokens of a given id
   * @param _to The address to mint tokens to.
   * @param _id token id to mint
   * @param _value The amount to be minted
   * @param _data Data to be passed if receiver is contract
   */
  function mintMock(address _to, uint256 _id, uint256 _value, bytes memory _data)
    public
  {
    super._mint(_to, _id, _value, _data);
  }

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to The address to mint tokens to.
   * @param _ids Array of ids to mint
   * @param _values Array of amount of tokens to mint per id
   * @param _data Data to be passed if receiver is contract
   */
  function batchMintMock(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data)
    public
  {
    super._batchMint(_to, _ids, _values, _data);
  }


  /***********************************|
  |         Burning Functions         |
  |__________________________________*/

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _id token id to burn
   * @param _value The amount to be burned
   */
  function burnMock(address _from, uint256 _id, uint256 _value)
    public
  {
    super._burn(_from, _id, _value);
  }

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _ids Array of token ids to burn
   * @param _values Array of the amount to be burned
   */
  function batchBurnMock(address _from, uint256[] memory _ids, uint256[] memory _values)
    public
  {
    super._batchBurn(_from, _ids, _values);
  }
  
  /***********************************|
  |       Unsupported Functions       |
  |__________________________________*/

  fallback () virtual external {
    revert("ERC1155MetaMintBurnMock: INVALID_METHOD");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@0xsequence/erc-1155/contracts/mocks/ERC1155MintBurnMock.sol";
import "../interfaces/IERC2981.sol";


contract ERC1155RoyaltyMock is ERC1155MintBurnMock {
  using SafeMath for uint256;
  uint256 public royaltyFee;
  address public royaltyRecipient;
  uint256 public royaltyFee666;
  address public royaltyRecipient666;


  /** 
   * @notice Called with the sale price to determine how much royalty
   *         is owed and to whom.
   * @param _tokenId - the NFT asset queried for royalty information
   * @param _salePrice - the sale price of the NFT asset specified by _tokenId
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for _salePrice
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    if (_tokenId == 666) {
      uint256 fee = _salePrice.mul(royaltyFee666).div(1000);
      return (royaltyRecipient666, fee);
    } else {
      uint256 fee = _salePrice.mul(royaltyFee).div(1000);
      return (royaltyRecipient, fee);
    }
  }

  function setFee(uint256 _fee) public {
    require(_fee < 1000, "FEE IS TOO HIGH");
    royaltyFee = _fee;
  }

  function set666Fee(uint256 _fee) public {
    require(_fee < 1000, "FEE IS TOO HIGH");
    royaltyFee666 = _fee;
  }

  function setFeeRecipient(address _recipient) public {
    royaltyRecipient = _recipient;
  }

  function set666FeeRecipient(address _recipient) public {
    royaltyRecipient666 = _recipient;
  }

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC1155MintBurnMock) virtual pure returns (bool) {
    // Should be 0x2a55205a
    if (_interfaceID == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";

/** 
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
  /** 
   * @notice Called with the sale price to determine how much royalty
   *         is owed and to whom.
   * @param _tokenId - the NFT asset queried for royalty information
   * @param _salePrice - the sale price of the NFT asset specified by _tokenId
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for _salePrice
   */
  function royaltyInfo(
      uint256 _tokenId,
      uint256 _salePrice
  ) external view returns (
      address receiver,
      uint256 royaltyAmount
  );
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../interfaces/IOwnable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract inherits the owner of a parent contract as its owner, 
 * and provides basic authorization control functions, this simplifies the 
 * implementation of "user permissions".
 */
contract DelegatedOwnable {
  address internal ownableParent;

  event ParentOwnerChanged(address indexed previousParent, address indexed newParent);

  /**
   * @dev The Ownable constructor sets the original `ownableParent` of the contract to the specied address
   * @param _firstOwnableParent Address of the first ownable parent contract
   */
  constructor (address _firstOwnableParent) {
    try IOwnable(_firstOwnableParent).getOwner() {
      // Do nothing if parent has ownable function
    } catch {
      revert("PARENT IS NOT OWNABLE");
    }
    ownableParent = _firstOwnableParent;
    emit ParentOwnerChanged(address(0), _firstOwnableParent);
  }

  /**
   * @dev Throws if called by any account other than the master owner.
   */
  modifier onlyOwner() {
    require(msg.sender == getOwner(), "DelegatedOwnable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Will use the owner address of another parent contract
   * @param _newParent Address of the new owner
   */
  function changeOwnableParent(address _newParent) public onlyOwner {
    require(_newParent != address(0), "DelegatedOwnable#changeOwnableParent: INVALID_ADDRESS");
    ownableParent = _newParent;
    emit ParentOwnerChanged(ownableParent, _newParent);
  }

  /**
   * @notice Returns the address of the owner.
   */
  function getOwner() public view returns (address) {
    return IOwnable(ownableParent).getOwner();
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IOwnable {
  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) external;

  /**
   * @notice Returns the address of the owner.
   */
  function getOwner() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "./NiftyswapExchange20.sol";
import "../utils/Ownable.sol";
import "../interfaces/INiftyswapFactory20.sol";

contract NiftyswapFactory20 is INiftyswapFactory20, Ownable {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  // tokensToExchange[erc1155_token_address][currency_address]
  mapping(address => mapping(address => mapping(uint256 => address))) public override tokensToExchange;
  mapping(address => mapping(address => address[])) internal pairExchanges;

  /**
   * @notice Will set the initial Niftyswap admin
   * @param _admin Address of the initial niftyswap admin to set as Owner
   */
  constructor(address _admin) Ownable(_admin) { }

  /***********************************|
  |             Functions             |
  |__________________________________*/
  /**
   * @notice Creates a NiftySwap Exchange for given token contract
   * @param _token    The address of the ERC-1155 token contract
   * @param _currency The address of the ERC-20 token contract
   * @param _instance Instance # that allows to deploy new instances of an exchange.
   *                  This is mainly meant to be used for tokens that change their ERC-2981 support.
   */
  function createExchange(address _token, address _currency, uint256 _instance) public override {
    require(tokensToExchange[_token][_currency][_instance] == address(0x0), "NiftyswapFactory20#createExchange: EXCHANGE_ALREADY_CREATED");

    // Create new exchange contract
    NiftyswapExchange20 exchange = new NiftyswapExchange20(_token, _currency);

    // Store exchange and token addresses
    tokensToExchange[_token][_currency][_instance] = address(exchange);
    pairExchanges[_token][_currency].push(address(exchange));

    // Emit event
    emit NewExchange(_token, _currency, _instance, address(exchange));
  }

  /**
   * @notice Returns array of exchange instances for a given pair
   * @param _token    The address of the ERC-1155 token contract
   * @param _currency The address of the ERC-20 token contract
   */
  function getPairExchanges(address _token, address _currency) public override view returns (address[] memory) {
    return pairExchanges[_token][_currency];
  }

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the specied address
   * @param _firstOwner Address of the first owner
   */
  constructor (address _firstOwner) {
    owner = _firstOwner;
    emit OwnershipTransferred(address(0), _firstOwner);
  }

  /**
   * @dev Throws if called by any account other than the master owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  /**
   * @notice Returns the address of the owner.
   */
  function getOwner() public view returns (address) {
    return owner;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface INiftyswapFactory20 {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event NewExchange(address indexed token, address indexed currency, uint256 indexed salt, address exchange);


  /***********************************|
  |         Public  Functions         |
  |__________________________________*/

  /**
   * @notice Creates a NiftySwap Exchange for given token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _instance Instance # that allows to deploy new instances of an exchange.
   *                  This is mainly meant to be used for tokens that change their ERC-2981 support.
   */
  function createExchange(address _token, address _currency, uint256 _instance) external;

  /**
   * @notice Return address of exchange for corresponding ERC-1155 token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _instance Instance # that allows to deploy new instances of an exchange.
   *                  This is mainly meant to be used for tokens that change their ERC-2981 support.
   */
  function tokensToExchange(address _token, address _currency, uint256 _instance) external view returns (address);

  /**
   * @notice Returns array of exchange instances for a given pair
   * @param _token    The address of the ERC-1155 token contract
   * @param _currency The address of the ERC-20 token contract
   */
  function getPairExchanges(address _token, address _currency) external view returns (address[] memory);
}

pragma solidity 0.7.4;

import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
    * @dev Total number of tokens in existence
    */
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
  function balanceOf(address owner) public override view returns (uint256) {
    return _balances[owner];
  }

  /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  function allowance(address owner, address spender) public override view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
  function approve(address spender, uint256 value) public override returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
    * @dev Approve an address to spend another addresses' tokens.
    * @param owner The address that owns the tokens.
    * @param spender The address that will spend the tokens.
    * @param value The number of tokens that can be spent.
    */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * Emits an Approval event (reflecting the reduced allowance).
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }

}

contract ERC20Mock is ERC20 {
  constructor() public { }

  function mockMint(address _address, uint256 _amount) public {
    _mint(_address, _amount);
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "@0xsequence/erc20-meta-token/contracts/mocks/ERC20Mock.sol";

contract ERC20TokenMock is ERC20Mock {

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@0xsequence/erc-1155/contracts/mocks/ERC1155MintBurnMock.sol";


contract ERC1155Mock is ERC1155MintBurnMock {

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@0xsequence/erc20-meta-token/contracts/wrapper/MetaERC20Wrapper.sol";


contract ERC20WrapperMock is MetaERC20Wrapper {

}