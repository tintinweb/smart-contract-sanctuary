// DEx.top - Instant Trading on Chain
//
// Author: DEx.top Team

pragma solidity 0.4.21;
pragma experimental "v0.5.0";

interface Token {
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract Dex2 {
  //------------------------------ Struct Definitions: ---------------------------------------------

  struct TokenInfo {
    string  symbol;       // e.g., "ETH", "ADX"
    address tokenAddr;    // ERC20 token address
    uint64  scaleFactor;  // <original token amount> = <scaleFactor> x <DEx amountE8> / 1e8
    uint    minDeposit;   // mininum deposit (original token amount) allowed for this token
  }

  struct TraderInfo {
    address withdrawAddr;
    uint8   feeRebatePercent;  // range: [0, 100]
  }

  struct TokenAccount {
    uint64 balanceE8;          // available amount for trading
    uint64 pendingWithdrawE8;  // the amount to be transferred out from this contract to the trader
  }

  struct Order {
    uint32 pairId;  // <cashId>(16) <stockId>(16)
    uint8  action;  // 0 means BUY; 1 means SELL
    uint8  ioc;     // 0 means a regular order; 1 means an immediate-or-cancel (IOC) order
    uint64 priceE8;
    uint64 amountE8;
    uint64 expireTimeSec;
  }

  struct Deposit {
    address traderAddr;
    uint16  tokenCode;
    uint64  pendingAmountE8;   // amount to be confirmed for trading purpose
  }

  struct DealInfo {
    uint16 stockCode;          // stock token code
    uint16 cashCode;           // cash token code
    uint64 stockDealAmountE8;
    uint64 cashDealAmountE8;
  }

  struct ExeStatus {
    uint64 logicTimeSec;       // logic timestamp for checking order expiration
    uint64 lastOperationIndex; // index of the last executed operation
  }

  //----------------- Constants: -------------------------------------------------------------------

  uint constant MAX_UINT256 = 2**256 - 1;
  uint16 constant MAX_FEE_RATE_E4 = 60;  // upper limit of fee rate is 0.6% (60 / 1e4)

  // <original ETH amount in Wei> = <DEx amountE8> * <ETH_SCALE_FACTOR> / 1e8
  uint64 constant ETH_SCALE_FACTOR = 10**18;

  uint8 constant ACTIVE = 0;
  uint8 constant CLOSED = 2;

  bytes32 constant HASHTYPES =
      keccak256(&#39;string title&#39;, &#39;address market_address&#39;, &#39;uint64 nonce&#39;, &#39;uint64 expire_time_sec&#39;,
                &#39;uint64 amount_e8&#39;, &#39;uint64 price_e8&#39;, &#39;uint8 immediate_or_cancel&#39;, &#39;uint8 action&#39;,
                &#39;uint16 cash_token_code&#39;, &#39;uint16 stock_token_code&#39;);

  //----------------- States that cannot be changed once set: --------------------------------------

  address public admin;                         // admin address, and it cannot be changed
  mapping (uint16 => TokenInfo) public tokens;  // mapping of token code to token information

  //----------------- Other states: ----------------------------------------------------------------

  uint8 public marketStatus;        // market status: 0 - Active; 1 - Suspended; 2 - Closed

  uint16 public makerFeeRateE4;     // maker fee rate (* 10**4)
  uint16 public takerFeeRateE4;     // taker fee rate (* 10**4)
  uint16 public withdrawFeeRateE4;  // withdraw fee rate (* 10**4)

  uint64 public lastDepositIndex;   // index of the last deposit operation

  ExeStatus public exeStatus;       // status of operation execution

  mapping (address => TraderInfo) public traders;     // mapping of trade address to trader information
  mapping (uint176 => TokenAccount) public accounts;  // mapping of trader token key to its account information
  mapping (uint224 => Order) public orders;           // mapping of order key to order information
  mapping (uint64  => Deposit) public deposits;       // mapping of deposit index to deposit information

  //------------------------------ Dex2 Events: ----------------------------------------------------

  event DeployMarketEvent();
  event ChangeMarketStatusEvent(uint8 status);
  event SetTokenInfoEvent(uint16 tokenCode, string symbol, address tokenAddr, uint64 scaleFactor, uint minDeposit);
  event SetWithdrawAddrEvent(address trader, address withdrawAddr);

  event DepositEvent(address trader, uint16 tokenCode, string symbol, uint64 amountE8, uint64 depositIndex);
  event WithdrawEvent(address trader, uint16 tokenCode, string symbol, uint64 amountE8, uint64 lastOpIndex);
  event TransferFeeEvent(uint16 tokenCode, uint64 amountE8, address toAddr);

  // `balanceE8` is the total balance after this deposit confirmation
  event ConfirmDepositEvent(address trader, uint16 tokenCode, uint64 balanceE8);
  // `amountE8` is the post-fee initiated withdraw amount
  // `pendingWithdrawE8` is the total pending withdraw amount after this withdraw initiation
  event InitiateWithdrawEvent(address trader, uint16 tokenCode, uint64 amountE8, uint64 pendingWithdrawE8);
  event MatchOrdersEvent(address trader1, uint64 nonce1, address trader2, uint64 nonce2);
  event HardCancelOrderEvent(address trader, uint64 nonce);
  event SetFeeRatesEvent(uint16 makerFeeRateE4, uint16 takerFeeRateE4, uint16 withdrawFeeRateE4);
  event SetFeeRebatePercentEvent(address trader, uint8 feeRebatePercent);

  //------------------------------ Contract Initialization: ----------------------------------------

  function Dex2(address admin_) public {
    admin = admin_;
    setTokenInfo(0 /*tokenCode*/, "ETH", 0 /*tokenAddr*/, ETH_SCALE_FACTOR, 0 /*minDeposit*/);
    emit DeployMarketEvent();
  }

  //------------------------------ External Functions: ---------------------------------------------

  function() external {
    revert();
  }

  // Change the market status of DEX.
  function changeMarketStatus(uint8 status_) external {
    if (msg.sender != admin) revert();
    if (marketStatus == CLOSED) revert();  // closed is forever

    marketStatus = status_;
    emit ChangeMarketStatusEvent(status_);
  }

  // Each trader can specify a withdraw address (but cannot change it later). Once a trader&#39;s
  // withdraw address is set, following withdrawals of this trader will go to the withdraw address
  // instead of the trader&#39;s address.
  function setWithdrawAddr(address withdrawAddr) external {
    if (withdrawAddr == 0) revert();
    if (traders[msg.sender].withdrawAddr != 0) revert();  // cannot change withdrawAddr once set
    traders[msg.sender].withdrawAddr = withdrawAddr;
    emit SetWithdrawAddrEvent(msg.sender, withdrawAddr);
  }

  // Deposit ETH from msg.sender for the given trader.
  function depositEth(address traderAddr) external payable {
    if (marketStatus != ACTIVE) revert();
    if (traderAddr == 0) revert();
    if (msg.value < tokens[0].minDeposit) revert();
    if (msg.data.length != 4 + 32) revert();  // length condition of param count

    uint64 pendingAmountE8 = uint64(msg.value / (ETH_SCALE_FACTOR / 10**8));  // msg.value is in Wei
    if (pendingAmountE8 == 0) revert();

    uint64 depositIndex = ++lastDepositIndex;
    setDeposits(depositIndex, traderAddr, 0, pendingAmountE8);
    emit DepositEvent(traderAddr, 0, "ETH", pendingAmountE8, depositIndex);
  }

  // Deposit token (other than ETH) from msg.sender for a specified trader.
  //
  // After the deposit has been confirmed enough times on the blockchain, it will be added to the
  // trader&#39;s token account for trading.
  function depositToken(address traderAddr, uint16 tokenCode, uint originalAmount) external {
    if (marketStatus != ACTIVE) revert();
    if (traderAddr == 0) revert();
    if (tokenCode == 0) revert();  // this function does not handle ETH
    if (msg.data.length != 4 + 32 + 32 + 32) revert();  // length condition of param count

    TokenInfo memory tokenInfo = tokens[tokenCode];
    if (originalAmount < tokenInfo.minDeposit) revert();
    if (tokenInfo.scaleFactor == 0) revert();  // unsupported token

    // Need to make approval by calling Token(address).approve() in advance for ERC-20 Tokens.
    if (!Token(tokenInfo.tokenAddr).transferFrom(msg.sender, this, originalAmount)) revert();

    if (originalAmount > MAX_UINT256 / 10**8) revert();  // avoid overflow
    uint amountE8 = originalAmount * 10**8 / uint(tokenInfo.scaleFactor);
    if (amountE8 >= 2**64 || amountE8 == 0) revert();

    uint64 depositIndex = ++lastDepositIndex;
    setDeposits(depositIndex, traderAddr, tokenCode, uint64(amountE8));
    emit DepositEvent(traderAddr, tokenCode, tokens[tokenCode].symbol, uint64(amountE8), depositIndex);
  }

  // Withdraw ETH from the contract.
  function withdrawEth(address traderAddr) external {
    if (traderAddr == 0) revert();
    if (msg.data.length != 4 + 32) revert();  // length condition of param count

    uint176 accountKey = uint176(traderAddr);
    uint amountE8 = accounts[accountKey].pendingWithdrawE8;
    if (amountE8 == 0) return;

    // Write back to storage before making the transfer.
    accounts[accountKey].pendingWithdrawE8 = 0;

    uint truncatedWei = amountE8 * (ETH_SCALE_FACTOR / 10**8);
    address withdrawAddr = traders[traderAddr].withdrawAddr;
    if (withdrawAddr == 0) withdrawAddr = traderAddr;
    withdrawAddr.transfer(truncatedWei);
    emit WithdrawEvent(traderAddr, 0, "ETH", uint64(amountE8), exeStatus.lastOperationIndex);
  }

  // Withdraw token (other than ETH) from the contract.
  function withdrawToken(address traderAddr, uint16 tokenCode) external {
    if (traderAddr == 0) revert();
    if (tokenCode == 0) revert();  // this function does not handle ETH
    if (msg.data.length != 4 + 32 + 32) revert();  // length condition of param count

    TokenInfo memory tokenInfo = tokens[tokenCode];
    if (tokenInfo.scaleFactor == 0) revert();  // unsupported token

    uint176 accountKey = uint176(tokenCode) << 160 | uint176(traderAddr);
    uint amountE8 = accounts[accountKey].pendingWithdrawE8;
    if (amountE8 == 0) return;

    // Write back to storage before making the transfer.
    accounts[accountKey].pendingWithdrawE8 = 0;

    uint truncatedAmount = amountE8 * uint(tokenInfo.scaleFactor) / 10**8;
    address withdrawAddr = traders[traderAddr].withdrawAddr;
    if (withdrawAddr == 0) withdrawAddr = traderAddr;
    if (!Token(tokenInfo.tokenAddr).transfer(withdrawAddr, truncatedAmount)) revert();
    emit WithdrawEvent(traderAddr, tokenCode, tokens[tokenCode].symbol, uint64(amountE8),
                       exeStatus.lastOperationIndex);
  }

  // Transfer the collected fee out of the contract.
  function transferFee(uint16 tokenCode, uint64 amountE8, address toAddr) external {
    if (msg.sender != admin) revert();
    if (toAddr == 0) revert();
    if (msg.data.length != 4 + 32 + 32 + 32) revert();

    TokenAccount memory feeAccount = accounts[uint176(tokenCode) << 160];
    uint64 withdrawE8 = feeAccount.pendingWithdrawE8;
    if (amountE8 < withdrawE8) {
      withdrawE8 = amountE8;
    }
    feeAccount.pendingWithdrawE8 -= withdrawE8;
    accounts[uint176(tokenCode) << 160] = feeAccount;

    TokenInfo memory tokenInfo = tokens[tokenCode];
    uint originalAmount = uint(withdrawE8) * uint(tokenInfo.scaleFactor) / 10**8;
    if (tokenCode == 0) {  // ETH
      toAddr.transfer(originalAmount);
    } else {
      if (!Token(tokenInfo.tokenAddr).transfer(toAddr, originalAmount)) revert();
    }
    emit TransferFeeEvent(tokenCode, withdrawE8, toAddr);
  }

  // Replay the trading sequence from the off-chain ledger exactly onto the on-chain ledger.
  function exeSequence(uint header, uint[] body) external {
    if (msg.sender != admin) revert();

    uint64 nextOperationIndex = uint64(header);
    if (nextOperationIndex != exeStatus.lastOperationIndex + 1) revert();  // check sequence index

    uint64 newLogicTimeSec = uint64(header >> 64);
    if (newLogicTimeSec < exeStatus.logicTimeSec) revert();

    for (uint i = 0; i < body.length; nextOperationIndex++) {
      uint bits = body[i];
      uint opcode = bits & 0xFFFF;
      bits >>= 16;
      if ((opcode >> 8) != 0xDE) revert();  // check the magic number

      // ConfirmDeposit: <depositIndex>(64)
      if (opcode == 0xDE01) {
        confirmDeposit(uint64(bits));
        i += 1;
        continue;
      }

      // InitiateWithdraw: <amountE8>(64) <tokenCode>(16) <traderAddr>(160)
      if (opcode == 0xDE02) {
        initiateWithdraw(uint176(bits), uint64(bits >> 176));
        i += 1;
        continue;
      }

      //-------- The rest operation types are allowed only when the market is active ---------
      if (marketStatus != ACTIVE) revert();

      // MatchOrders
      if (opcode == 0xDE03) {
        uint8 v1 = uint8(bits);
        bits >>= 8;            // bits is now the key of the maker order

        Order memory makerOrder;
        if (v1 == 0) {         // order already in storage
          if (i + 1 >= body.length) revert();  // at least 1 body element left
          makerOrder = orders[uint224(bits)];
          i += 1;
        } else {
          if (orders[uint224(bits)].pairId != 0) revert();  // order must not be already in storage
          if (i + 4 >= body.length) revert();  // at least 4 body elements left
          makerOrder = parseNewOrder(uint224(bits) /*makerOrderKey*/, v1, body, i);
          i += 4;
        }

        uint8 v2 = uint8(body[i]);
        uint224 takerOrderKey = uint224(body[i] >> 8);
        Order memory takerOrder;
        if (v2 == 0) {         // order already in storage
          takerOrder = orders[takerOrderKey];
          i += 1;
        } else {
          if (orders[takerOrderKey].pairId != 0) revert();  // order must not be already in storage
          if (i + 3 >= body.length) revert();  // at least 3 body elements left
          takerOrder = parseNewOrder(takerOrderKey, v2, body, i);
          i += 4;
        }

        matchOrder(uint224(bits) /*makerOrderKey*/, makerOrder, takerOrderKey, takerOrder);
        continue;
      }

      // HardCancelOrder: <nonce>(64) <traderAddr>(160)
      if (opcode == 0xDE04) {
        hardCancelOrder(uint224(bits) /*orderKey*/);
        i += 1;
        continue;
      }

      // SetFeeRates: <withdrawFeeRateE4>(16) <takerFeeRateE4>(16) <makerFeeRateE4>(16)
      if (opcode == 0xDE05) {
        setFeeRates(uint16(bits), uint16(bits >> 16), uint16(bits >> 32));
        i += 1;
        continue;
      }

      // SetFeeRebatePercent: <rebatePercent>(8) <traderAddr>(160)
      if (opcode == 0xDE06) {
        setFeeRebatePercent(address(bits) /*traderAddr*/, uint8(bits >> 160) /*rebatePercent*/);
        i += 1;
        continue;
      }
    } // for loop

    setExeStatus(newLogicTimeSec, nextOperationIndex - 1);
  } // function exeSequence

  //------------------------------ Public Functions: -----------------------------------------------

  // Set information of a token.
  function setTokenInfo(uint16 tokenCode, string symbol, address tokenAddr, uint64 scaleFactor,
                        uint minDeposit) public {
    if (msg.sender != admin) revert();
    if (marketStatus != ACTIVE) revert();
    if (scaleFactor == 0) revert();

    TokenInfo memory info = tokens[tokenCode];
    if (info.scaleFactor != 0) {  // this token already exists
      // For an existing token only the minDeposit field can be updated.
      tokens[tokenCode].minDeposit = minDeposit;
      emit SetTokenInfoEvent(tokenCode, info.symbol, info.tokenAddr, info.scaleFactor, minDeposit);
      return;
    }

    tokens[tokenCode].symbol = symbol;
    tokens[tokenCode].tokenAddr = tokenAddr;
    tokens[tokenCode].scaleFactor = scaleFactor;
    tokens[tokenCode].minDeposit = minDeposit;
    emit SetTokenInfoEvent(tokenCode, symbol, tokenAddr, scaleFactor, minDeposit);
  }

  //------------------------------ Private Functions: ----------------------------------------------

  function setDeposits(uint64 depositIndex, address traderAddr, uint16 tokenCode, uint64 amountE8) private {
    deposits[depositIndex].traderAddr = traderAddr;
    deposits[depositIndex].tokenCode = tokenCode;
    deposits[depositIndex].pendingAmountE8 = amountE8;
  }

  function setExeStatus(uint64 logicTimeSec, uint64 lastOperationIndex) private {
    exeStatus.logicTimeSec = logicTimeSec;
    exeStatus.lastOperationIndex = lastOperationIndex;
  }

  function confirmDeposit(uint64 depositIndex) private {
    Deposit memory deposit = deposits[depositIndex];
    uint176 accountKey = (uint176(deposit.tokenCode) << 160) | uint176(deposit.traderAddr);
    TokenAccount memory account = accounts[accountKey];

    // Check that pending amount is non-zero and no overflow would happen.
    if (account.balanceE8 + deposit.pendingAmountE8 <= account.balanceE8) revert();
    account.balanceE8 += deposit.pendingAmountE8;

    deposits[depositIndex].pendingAmountE8 = 0;
    accounts[accountKey].balanceE8 += deposit.pendingAmountE8;
    emit ConfirmDepositEvent(deposit.traderAddr, deposit.tokenCode, account.balanceE8);
  }

  function initiateWithdraw(uint176 tokenAccountKey, uint64 amountE8) private {
    uint64 balanceE8 = accounts[tokenAccountKey].balanceE8;
    uint64 pendingWithdrawE8 = accounts[tokenAccountKey].pendingWithdrawE8;

    if (balanceE8 < amountE8 || amountE8 == 0) revert();
    balanceE8 -= amountE8;

    uint64 feeE8 = calcFeeE8(amountE8, withdrawFeeRateE4, address(tokenAccountKey));
    amountE8 -= feeE8;

    if (pendingWithdrawE8 + amountE8 < amountE8) revert();  // check overflow
    pendingWithdrawE8 += amountE8;

    accounts[tokenAccountKey].balanceE8 = balanceE8;
    accounts[tokenAccountKey].pendingWithdrawE8 = pendingWithdrawE8;

    // Note that the fee account has a dummy trader address of 0.
    if (accounts[tokenAccountKey & (0xffff << 160)].pendingWithdrawE8 + feeE8 >= feeE8) {  // no overflow
      accounts[tokenAccountKey & (0xffff << 160)].pendingWithdrawE8 += feeE8;
    }

    emit InitiateWithdrawEvent(address(tokenAccountKey), uint16(tokenAccountKey >> 160) /*tokenCode*/,
                               amountE8, pendingWithdrawE8);
  }

  function getDealInfo(uint32 pairId, uint64 priceE8, uint64 amount1E8, uint64 amount2E8)
      private pure returns (DealInfo deal) {
    deal.stockCode = uint16(pairId);
    deal.cashCode = uint16(pairId >> 16);
    if (deal.stockCode == deal.cashCode) revert();  // we disallow homogeneous trading

    deal.stockDealAmountE8 = amount1E8 < amount2E8 ? amount1E8 : amount2E8;

    uint cashDealAmountE8 = uint(priceE8) * uint(deal.stockDealAmountE8) / 10**8;
    if (cashDealAmountE8 >= 2**64) revert();
    deal.cashDealAmountE8 = uint64(cashDealAmountE8);
  }

  function calcFeeE8(uint64 amountE8, uint feeRateE4, address traderAddr)
      private view returns (uint64) {
    uint feeE8 = uint(amountE8) * feeRateE4 / 10000;
    feeE8 -= feeE8 * uint(traders[traderAddr].feeRebatePercent) / 100;
    return uint64(feeE8);
  }

  function settleAccounts(DealInfo deal, address traderAddr, uint feeRateE4, bool isBuyer) private {
    uint16 giveTokenCode = isBuyer ? deal.cashCode : deal.stockCode;
    uint16 getTokenCode = isBuyer ? deal.stockCode : deal.cashCode;

    uint64 giveAmountE8 = isBuyer ? deal.cashDealAmountE8 : deal.stockDealAmountE8;
    uint64 getAmountE8 = isBuyer ? deal.stockDealAmountE8 : deal.cashDealAmountE8;

    uint176 giveAccountKey = uint176(giveTokenCode) << 160 | uint176(traderAddr);
    uint176 getAccountKey = uint176(getTokenCode) << 160 | uint176(traderAddr);

    uint64 feeE8 = calcFeeE8(getAmountE8, feeRateE4, traderAddr);
    getAmountE8 -= feeE8;

    // Check overflow.
    if (accounts[giveAccountKey].balanceE8 < giveAmountE8) revert();
    if (accounts[getAccountKey].balanceE8 + getAmountE8 < getAmountE8) revert();

    // Write storage.
    accounts[giveAccountKey].balanceE8 -= giveAmountE8;
    accounts[getAccountKey].balanceE8 += getAmountE8;

    if (accounts[uint176(getTokenCode) << 160].pendingWithdrawE8 + feeE8 >= feeE8) {  // no overflow
      accounts[uint176(getTokenCode) << 160].pendingWithdrawE8 += feeE8;
    }
  }

  function setOrders(uint224 orderKey, uint32 pairId, uint8 action, uint8 ioc,
                     uint64 priceE8, uint64 amountE8, uint64 expireTimeSec) private {
    orders[orderKey].pairId = pairId;
    orders[orderKey].action = action;
    orders[orderKey].ioc = ioc;
    orders[orderKey].priceE8 = priceE8;
    orders[orderKey].amountE8 = amountE8;
    orders[orderKey].expireTimeSec = expireTimeSec;
  }

  function matchOrder(uint224 makerOrderKey, Order makerOrder,
                      uint224 takerOrderKey, Order takerOrder) private {
    // Check trading conditions.
    if (marketStatus != ACTIVE) revert();
    if (makerOrderKey == takerOrderKey) revert();  // the two orders must not have the same key
    if (makerOrder.pairId != takerOrder.pairId) revert();
    if (makerOrder.action == takerOrder.action) revert();
    if (makerOrder.priceE8 == 0 || takerOrder.priceE8 == 0) revert();
    if (makerOrder.action == 0 && makerOrder.priceE8 < takerOrder.priceE8) revert();
    if (takerOrder.action == 0 && takerOrder.priceE8 < makerOrder.priceE8) revert();
    if (makerOrder.amountE8 == 0 || takerOrder.amountE8 == 0) revert();
    if (makerOrder.expireTimeSec <= exeStatus.logicTimeSec) revert();
    if (takerOrder.expireTimeSec <= exeStatus.logicTimeSec) revert();

    DealInfo memory deal = getDealInfo(
        makerOrder.pairId, makerOrder.priceE8, makerOrder.amountE8, takerOrder.amountE8);

    // Update accounts.
    settleAccounts(deal, address(makerOrderKey), makerFeeRateE4, (makerOrder.action == 0));
    settleAccounts(deal, address(takerOrderKey), takerFeeRateE4, (takerOrder.action == 0));

    // Update orders.
    if (makerOrder.ioc == 1) {  // IOC order
      makerOrder.amountE8 = 0;
    } else {
      makerOrder.amountE8 -= deal.stockDealAmountE8;
    }
    if (takerOrder.ioc == 1) {  // IOC order
      takerOrder.amountE8 = 0;
    } else {
      takerOrder.amountE8 -= deal.stockDealAmountE8;
    }

    // Write orders back to storage.
    setOrders(makerOrderKey, makerOrder.pairId, makerOrder.action, makerOrder.ioc,
              makerOrder.priceE8, makerOrder.amountE8, makerOrder.expireTimeSec);
    setOrders(takerOrderKey, takerOrder.pairId, takerOrder.action, takerOrder.ioc,
              takerOrder.priceE8, takerOrder.amountE8, takerOrder.expireTimeSec);

    emit MatchOrdersEvent(address(makerOrderKey), uint64(makerOrderKey >> 160) /*nonce*/,
                          address(takerOrderKey), uint64(takerOrderKey >> 160) /*nonce*/);
  }

  function hardCancelOrder(uint224 orderKey) private {
    orders[orderKey].pairId = 0xFFFFFFFF;
    orders[orderKey].amountE8 = 0;
    emit HardCancelOrderEvent(address(orderKey) /*traderAddr*/, uint64(orderKey >> 160) /*nonce*/);
  }

  function setFeeRates(uint16 makerE4, uint16 takerE4, uint16 withdrawE4) private {
    if (makerE4 > MAX_FEE_RATE_E4) revert();
    if (takerE4 > MAX_FEE_RATE_E4) revert();
    if (withdrawE4 > MAX_FEE_RATE_E4) revert();

    makerFeeRateE4 = makerE4;
    takerFeeRateE4 = takerE4;
    withdrawFeeRateE4 = withdrawE4;
    emit SetFeeRatesEvent(makerE4, takerE4, withdrawE4);
  }

  function setFeeRebatePercent(address traderAddr, uint8 feeRebatePercent) private {
    if (feeRebatePercent > 100) revert();

    traders[traderAddr].feeRebatePercent = feeRebatePercent;
    emit SetFeeRebatePercentEvent(traderAddr, feeRebatePercent);
  }

  function parseNewOrder(uint224 orderKey, uint8 v, uint[] body, uint i) private view returns (Order) {
    // bits: <expireTimeSec>(64) <amountE8>(64) <priceE8>(64) <ioc>(8) <action>(8) <pairId>(32)
    uint240 bits = uint240(body[i + 1]);
    uint64 nonce = uint64(orderKey >> 160);
    address traderAddr = address(orderKey);
    if (traderAddr == 0) revert();  // check zero addr early since `ecrecover` returns 0 on error

    // verify the signature of the trader
    bytes32 hash1 = keccak256("\x19Ethereum Signed Message:\n70DEx2 Order: ", address(this), nonce, bits);
    if (traderAddr != ecrecover(hash1, v, bytes32(body[i + 2]), bytes32(body[i + 3]))) {
      bytes32 hashValues = keccak256("DEx2 Order", address(this), nonce, bits);
      bytes32 hash2 = keccak256(HASHTYPES, hashValues);
      if (traderAddr != ecrecover(hash2, v, bytes32(body[i + 2]), bytes32(body[i + 3]))) revert();
    }

    Order memory order;
    order.pairId = uint32(bits); bits >>= 32;
    order.action = uint8(bits); bits >>= 8;
    order.ioc = uint8(bits); bits >>= 8;
    order.priceE8 = uint64(bits); bits >>= 64;
    order.amountE8 = uint64(bits); bits >>= 64;
    order.expireTimeSec = uint64(bits);
    return order;
  }

}  // contract