// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BToken.sol";
import "./BMath.sol";
import "../../interfaces/IIndexPool.sol";
import "../../interfaces/ICompLikeToken.sol";


contract IndexPool is BToken, BMath, IIndexPool {
  bool internal _mutex;
  address internal _controller;
  bool internal _publicSwap;
  address[] internal _tokens;
  mapping(address => Record) internal _records;
  uint256 internal _totalWeight;
  mapping(address => uint256) internal _minimumBalances;
  uint256 internal _maxPoolTokens;
  address internal _oracle;
  address internal _router;
  address internal _exitFeeRecipient;
  address internal _exitFeeRecipientAdditional;

  function oracle() external view override returns (address) {
    return _oracle;
  }

  function router() external view override returns (address) {
    return _router;
  }

  function isPublicSwap() external view override returns (bool) {
    return _publicSwap;
  }

  function getExitFee() external pure override  returns (uint256) {
    return EXIT_FEE;
  }

  function getController() external view override returns (address) {
    return _controller;
  }

  function getMaxPoolTokens() external view override returns (uint256) {
    return _maxPoolTokens;
  }

  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  function getNumTokens() external view override returns (uint256) {
    return _tokens.length;
  }

  function getCurrentTokens() external view override _viewlock_ returns (address[] memory) {
    return _tokens;
  }

  function getCurrentDesiredTokens() external view override _viewlock_ returns (address[] memory tokens) {
    address[] memory tempTokens = _tokens;
    tokens = new address[](tempTokens.length);
    uint256 usedIndex = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tempTokens[i];
      if (_records[token].desiredDenorm > 0) {
        tokens[usedIndex++] = token;
      }
    }
    assembly { mstore(tokens, usedIndex) }
  }

  function getDenormalizedWeight(address token) external view override _viewlock_ returns (uint256) {
    require(_records[token].bound, "BiShares: Token not bound");
    return _records[token].denorm;
  }

  function getTokenRecord(address token) external view override _viewlock_ returns (Record memory record) {
    record = _records[token];
    require(record.bound, "BiShares: Token not bound");
  }

  function extrapolatePoolValueFromToken() external view override _viewlock_ returns (
    address token,
    uint256 extrapolatedValue
  ) {
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      token = _tokens[i];
      Record storage record = _records[token];
      if (record.ready && record.desiredDenorm > 0) {
        extrapolatedValue = bmul(
          record.balance,
          bdiv(_totalWeight, record.denorm)
        );
        break;
      }
    }
    require(extrapolatedValue > 0, "BiShares: Extrapolated value is zero");
  }

  function getTotalDenormalizedWeight() external view override _viewlock_ returns (uint256) {
    return _totalWeight;
  }

  function getBalance(address token) external view override _viewlock_ returns (uint256) {
    Record storage record = _records[token];
    require(record.bound, "BiShares: Token not bound");
    return record.balance;
  }

  function getMinimumBalance(address token) external view override _viewlock_ returns (uint256) {
    Record memory record = _records[token];
    require(record.bound, "BiShares: Token not bound");
    require(!record.ready, "BiShares: Token already ready");
    return _minimumBalances[token];
  }

  function getUsedBalance(address token) external view override _viewlock_ returns (uint256) {
    Record memory record = _records[token];
    require(record.bound, "BiShares: Token not bound");
    if (!record.ready) {
      return _minimumBalances[token];
    }
    return record.balance;
  }

  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);
  event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);
  event LOG_TOKEN_REMOVED(address token);
  event LOG_TOKEN_ADDED(address indexed token, uint256 desiredDenorm, uint256 minimumBalance);
  event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);
  event LOG_TOKEN_READY(address indexed token);
  event LOG_PUBLIC_SWAP_ENABLED();
  event LOG_MAX_TOKENS_UPDATED(uint256 maxPoolTokens);
  event LOG_EXIT_FEE_RECIPIENT_UPDATED(address exitFeeRecipient);

  function configure(
    address controller,
    string memory name,
    string memory symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeRecipient,
    address exitFeeRecipientAdditional
  ) external override returns (bool) {
    address zero = address(0);
    require(_controller == zero, "BiShares: Already configured");
    require(controller != zero, "BiShares: Controller is zero address");
    require(
      exitFeeRecipient != zero
      && exitFeeRecipientAdditional != zero,
      "BiShares: Fee recipient is zero address"
    );
    require(uniswapV2oracle != zero, "BiShares: Oracle is zero address");
    require(uniswapV2router != zero, "BiShares: Router is zero address");
    _controller = controller;
    _initializeToken(name, symbol);
    _oracle = uniswapV2oracle; 
    _router = uniswapV2router;
    _exitFeeRecipient = exitFeeRecipient;
    _exitFeeRecipientAdditional = exitFeeRecipientAdditional;
    return true;
  }

  function initialize(
    address[] memory tokens,
    uint256[] memory balances,
    uint96[] memory denorms,
    address tokenProvider
  ) external override _control_ returns (bool) {
    require(_tokens.length == 0, "BiShares: Already initialized");
    uint256 len = tokens.length;
    require(len >= MIN_BOUND_TOKENS, "BiShares: Min bound tokens overflow");
    require(len <= MAX_BOUND_TOKENS, "BiShares: Max bound tokens overflow");
    require(balances.length == len && denorms.length == len, "BiShares: Invalid arrays length");
    uint256 totalWeight = 0;
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint96 denorm = denorms[i];
      uint256 balance = balances[i];
      require(denorm >= MIN_WEIGHT, "BiShares: Min weight overflow");
      require(denorm <= MAX_WEIGHT, "BiShares: Max weight overflow");
      require(balance >= MIN_BALANCE, "BiShares: Min balance overflow");
      _records[token] = Record({
        bound: true,
        ready: true,
        lastDenormUpdate: uint40(block.timestamp),
        denorm: denorm,
        desiredDenorm: denorm,
        index: uint8(i),
        balance: balance
      });
      _tokens.push(token);
      totalWeight = badd(totalWeight, denorm);
      _pullUnderlying(token, tokenProvider, balance);
    }
    require(totalWeight <= MAX_TOTAL_WEIGHT, "BiShares: Max total weight overflow");
    _totalWeight = totalWeight;
    _publicSwap = true;
    emit LOG_PUBLIC_SWAP_ENABLED();
    _mintPoolShare(INIT_POOL_SUPPLY);
    _pushPoolShare(tokenProvider, INIT_POOL_SUPPLY);
    return true;
  }

  function setMaxPoolTokens(uint256 maxPoolTokens) external override _control_ returns (bool) {
    _maxPoolTokens = maxPoolTokens;
    emit LOG_MAX_TOKENS_UPDATED(maxPoolTokens);
    return true;
  }

  function setExitFeeRecipient(address exitFeeRecipient_, bool additional) external override _control_ returns (bool) {
    require(exitFeeRecipient_ != address(0), "BiShares: Fee recipient is zero address");
    if (additional) {
      _exitFeeRecipientAdditional = exitFeeRecipient_;
    } else {
      _exitFeeRecipient = exitFeeRecipient_;
    }
    emit LOG_EXIT_FEE_RECIPIENT_UPDATED(exitFeeRecipient_);
    return true;
  }

  function delegateCompLikeToken(address token, address delegatee) external override _control_ returns (bool) {
    ICompLikeToken(token).delegate(delegatee);
    return true;
  }

  function reweighTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms
  ) external override _lock_ _control_ returns (bool) {
    require(desiredDenorms.length == tokens.length, "BiShares: Invalid arrays length");
    for (uint256 i = 0; i < tokens.length; i++) _setDesiredDenorm(tokens[i], desiredDenorms[i]);
    return true;
  }

  function reindexTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms,
    uint256[] memory minimumBalances
  ) external override _lock_ _control_ returns (bool) {
    require(
      desiredDenorms.length == tokens.length
      && minimumBalances.length == tokens.length,
      "BiShares: Invalid arrays length"
    );
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      bool notBound = !_records[token].bound;
      if (notBound) _setDesiredDenorm(token, 0);
      uint96 denorm = desiredDenorms[i];
      if (denorm < MIN_WEIGHT) denorm = uint96(MIN_WEIGHT);
      if (notBound) {
        _bind(token, minimumBalances[i], denorm);
      } else {
        _setDesiredDenorm(token, denorm);
      }
    }
    return true;
  }

  function setMinimumBalance(
    address token,
    uint256 minimumBalance
  ) external override _control_ returns (bool) {
    Record storage record = _records[token];
    require(record.bound, "BiShares: Token not bound");
    require(!record.ready, "BiShares: Token already ready");
    _minimumBalances[token] = minimumBalance;
    emit LOG_MINIMUM_BALANCE_UPDATED(token, minimumBalance);
    return true;
  }

  function joinPool(
    uint256 poolAmountOut,
    uint256[] memory maxAmountsIn
  ) external override _lock_ _public_ returns (bool) {
    address caller = msg.sender;
    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    require(ratio != 0, "BiShares: Invalid ratio");
    require(maxAmountsIn.length == _tokens.length, "BiShares: Invalid arrays length");
    uint256 maxPoolTokens = _maxPoolTokens;
    if (maxPoolTokens > 0) require(
      badd(poolTotal, poolAmountOut) <= maxPoolTokens,
      "BiShares: Max pool tokens overflow"
    );
    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      address t = _tokens[i];
      (Record memory record, uint256 realBalance) = _getInputToken(t);
      uint256 tokenAmountIn = bmul(ratio, record.balance);
      require(tokenAmountIn != 0, "BiShares: Token amount in is zero");
      require(tokenAmountIn <= maxAmountsIn[i], "BiShares: Max amount in overflow");
      _updateInputToken(t, record, badd(realBalance, tokenAmountIn));
      emit LOG_JOIN(caller, t, tokenAmountIn);
      _pullUnderlying(t, caller, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(caller, poolAmountOut);
    return true;
  }

  function exitPool(
    uint256 poolAmountIn,
    uint256[] memory minAmountsOut
  ) external override _lock_ returns (bool) {
    address caller = msg.sender;
    require(minAmountsOut.length == _tokens.length, "BiShares: Invalid arrays length");
    uint256 poolTotal = totalSupply();
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
    uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
    require(ratio != 0, "BiShares: Invalid ratio");
    _pullPoolShare(caller, poolAmountIn);
    _pushPoolShare(_exitFeeRecipient, exitFee / 2);
    _pushPoolShare(_exitFeeRecipientAdditional, exitFee - (exitFee / 2));
    _burnPoolShare(pAiAfterExitFee);
    for (uint256 i = 0; i < minAmountsOut.length; i++) {
      address t = _tokens[i];
      Record memory record = _records[t];
      if (record.ready) {
        uint256 tokenAmountOut = bmul(ratio, record.balance);
        require(tokenAmountOut != 0, "BiShares: Token amount out is zero");
        require(tokenAmountOut >= minAmountsOut[i], "BiShares: Min amount out overflow");
        _records[t].balance = bsub(record.balance, tokenAmountOut);
        emit LOG_EXIT(caller, t, tokenAmountOut);
        _pushUnderlying(t, caller, tokenAmountOut);
      } else {
        require(minAmountsOut[i] == 0, "BiShares: Min amount out overflow");
      }
    }
    return true;
  }

  function _pullPoolShare(address from, uint256 amount) internal {
    _pull(from, amount);
  }

  function _pushPoolShare(address to, uint256 amount) internal {
    _push(to, amount);
  }

  function _mintPoolShare(uint256 amount) internal {
    _mint(amount);
  }

  function _burnPoolShare(uint256 amount) internal {
    _burn(amount);
  }

  function _pullUnderlying(address erc20, address from, uint256 amount) internal {
    (bool success, bytes memory data) = erc20.call(
      abi.encodeWithSelector(
        IERC20.transferFrom.selector,
        from,
        address(this),
        amount
      )
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "BiShares: Pull underlying fail"
    );
  }

  function _pushUnderlying(address erc20, address to, uint256 amount) internal {
    (bool success, bytes memory data) = erc20.call(
      abi.encodeWithSelector(
        IERC20.transfer.selector,
        to,
        amount
      )
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "BiShares: Push underlying fail"
    );
  }

  function _bind(address token, uint256 minimumBalance, uint96 desiredDenorm) internal {
    require(!_records[token].bound, "BiShares: Token already bound");
    require(desiredDenorm >= MIN_WEIGHT, "BiShares: Min weight overflow");
    require(desiredDenorm <= MAX_WEIGHT, "BiShares: Max weight overflow");
    require(minimumBalance >= MIN_BALANCE, "BiShares: Min balance overflow");
    _records[token] = Record({
      bound: true,
      ready: false,
      lastDenormUpdate: 0,
      denorm: 0,
      desiredDenorm: desiredDenorm,
      index: uint8(_tokens.length),
      balance: 0
    });
    _tokens.push(token);
    _minimumBalances[token] = minimumBalance;
    emit LOG_TOKEN_ADDED(token, desiredDenorm, minimumBalance);
  }

  function _unbind(address token) internal {
    Record memory record = _records[token];
    uint256 index = record.index;
    uint256 last = _tokens.length - 1;
    if (index != last) {
      _tokens[index] = _tokens[last];
      _records[_tokens[index]].index = uint8(index);
    }
    _tokens.pop();
    _records[token] = Record({
      bound: false,
      ready: false,
      lastDenormUpdate: 0,
      denorm: 0,
      desiredDenorm: 0,
      index: 0,
      balance: 0
    });
    emit LOG_TOKEN_REMOVED(token);
  }

  function _setDesiredDenorm(address token, uint96 desiredDenorm) internal {
    Record storage record = _records[token];
    require(record.bound, "BiShares: Token not bound");
    require(desiredDenorm >= MIN_WEIGHT || desiredDenorm == 0, "BiShares: Min weight overflow");
    require(desiredDenorm <= MAX_WEIGHT, "BiShares: Max weight overflow");
    record.desiredDenorm = desiredDenorm;
    emit LOG_DESIRED_DENORM_SET(token, desiredDenorm);
  }

  function _increaseDenorm(Record memory record, address token) internal {
    uint256 time = block.timestamp;
    if (
      record.denorm >= record.desiredDenorm ||
      !record.ready ||
      time - record.lastDenormUpdate < WEIGHT_UPDATE_DELAY
    ) return;
    uint96 oldWeight = record.denorm;
    uint96 denorm = record.desiredDenorm;
    uint256 maxDiff = bmul(oldWeight, WEIGHT_CHANGE_PCT);
    uint256 diff = bsub(denorm, oldWeight);
    if (diff > maxDiff) {
      denorm = uint96(badd(oldWeight, maxDiff));
      diff = maxDiff;
    }
    _totalWeight = badd(_totalWeight, diff);
    require(_totalWeight <= MAX_TOTAL_WEIGHT, "BiShares: Max total weight overflow");
    record.denorm = denorm;
    _records[token].denorm = denorm;
    _records[token].lastDenormUpdate = uint40(time);
    emit LOG_DENORM_UPDATED(token, denorm);
  }

  function _decreaseDenorm(Record memory record, address token) internal {
    uint256 time = block.timestamp;
    if (
      record.denorm <= record.desiredDenorm ||
      !record.ready ||
      time - record.lastDenormUpdate < WEIGHT_UPDATE_DELAY
    ) return;
    uint96 oldWeight = record.denorm;
    uint96 denorm = record.desiredDenorm;
    uint256 maxDiff = bmul(oldWeight, WEIGHT_CHANGE_PCT);
    uint256 diff = bsub(oldWeight, denorm);
    if (diff > maxDiff) {
      denorm = uint96(bsub(oldWeight, maxDiff));
      diff = maxDiff;
    }
    if (denorm <= MIN_WEIGHT) {
      denorm = 0;
      _totalWeight = bsub(_totalWeight, denorm);
      _unbind(token);
    } else {
      _totalWeight = bsub(_totalWeight, diff);
      record.denorm = denorm;
      _records[token].denorm = denorm;
      _records[token].lastDenormUpdate = uint40(time);
      emit LOG_DENORM_UPDATED(token, denorm);
    }
  }

  function _updateInputToken(address token, Record memory record, uint256 realBalance) internal {
    if (!record.ready) {
      if (realBalance >= record.balance) {
        _minimumBalances[token] = 0;
        _records[token].ready = true;
        record.ready = true;
        emit LOG_TOKEN_READY(token);
        uint256 additionalBalance = bsub(realBalance, record.balance);
        uint256 balRatio = bdiv(additionalBalance, record.balance);
        record.denorm = uint96(badd(MIN_WEIGHT, bmul(MIN_WEIGHT, balRatio)));
        _records[token].denorm = record.denorm;
        _records[token].lastDenormUpdate = uint40(block.timestamp);
        _totalWeight = badd(_totalWeight, record.denorm);
        emit LOG_DENORM_UPDATED(token, record.denorm);
      } else {
        uint256 realToMinRatio = bdiv(
          bsub(record.balance, realBalance),
          record.balance
        );
        uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
        record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
      }
    } else {
      _increaseDenorm(record, token);
    }
    _records[token].balance = realBalance;
  }

  function _getInputToken(
    address token
  ) internal view returns (Record memory record, uint256 realBalance) {
    record = _records[token];
    require(record.bound, "BiShares: Token not bound");
    realBalance = record.balance;
    if (!record.ready) {
      record.balance = _minimumBalances[token];
      uint256 realToMinRatio = bdiv(
        bsub(record.balance, realBalance),
        record.balance
      );
      uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
      record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
    }
  }

  modifier _lock_ {
    require(!_mutex, "BiShares: Locked");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, "BiShares: Locked view");
    _;
  }

  modifier _control_ {
    require(msg.sender == _controller, "BiShares: Caller is not controller");
    _;
  }

  modifier _public_ {
    require(_publicSwap, "BiShares: Pool is not public");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string memory name,
    string memory symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeReciver,
    address exitFeeReciverAdditional
  ) external returns (bool);
  function initialize(
    address[] memory tokens,
    uint256[] memory balances,
    uint96[] memory denorms,
    address tokenProvider
  ) external returns (bool);
  function setMaxPoolTokens(uint256 maxPoolTokens) external returns (bool);
  function delegateCompLikeToken(address token, address delegatee) external returns (bool);
  function setExitFeeRecipient(address exitFeeRecipient_, bool additional) external returns (bool);
  function reweighTokens(address[] memory tokens, uint96[] memory desiredDenorms) external returns (bool);
  function reindexTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms,
    uint256[] memory minimumBalances
  ) external returns (bool);
  function setMinimumBalance(address token, uint256 minimumBalance) external returns (bool);
  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external returns (bool);
  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external returns (bool);

  function oracle() external view returns (address);
  function router() external view returns (address);
  function isPublicSwap() external view returns (bool);
  function getController() external view returns (address);
  function getMaxPoolTokens() external view returns (uint256);
  function isBound(address t) external view returns (bool);
  function getNumTokens() external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory tokens);
  function getCurrentDesiredTokens() external view returns (address[] memory tokens);
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getTokenRecord(address token) external view returns (Record memory record);
  function extrapolatePoolValueFromToken() external view returns (address token, uint256 extrapolatedValue);
  function getTotalDenormalizedWeight() external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getMinimumBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
  function getExitFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface ICompLikeToken {
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BNum.sol";


contract BTokenBase is BNum {
  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  uint256 internal _totalSupply;

  function _onTransfer(address from, address to, uint256 amount) internal virtual {}

  function _mint(uint256 amt) internal {
    address this_ = address(this);
    _balance[this_] = badd(_balance[this_], amt);
    _totalSupply = badd(_totalSupply, amt);
    _onTransfer(address(0), this_, amt);
  }

  function _burn(uint256 amt) internal {
    address this_ = address(this);
    require(_balance[this_] >= amt, "BiShares: insufficient balance");
    _balance[this_] = bsub(_balance[this_], amt);
    _totalSupply = bsub(_totalSupply, amt);
    _onTransfer(this_, address(0), amt);
  }

  function _move(address src, address dst, uint256 amt) internal {
    require(_balance[src] >= amt, "BiShares: insufficient balance");
    _balance[src] = bsub(_balance[src], amt);
    _balance[dst] = badd(_balance[dst], amt);
    _onTransfer(src, dst, amt);
  }

  function _push(address to, uint256 amt) internal {
    _move(address(this), to, amt);
  }

  function _pull(address from, uint256 amt) internal {
    _move(from, address(this), amt);
  }
}


contract BToken is BTokenBase, IERC20 {
  uint8 private constant DECIMALS = 18;
  string private _name;
  string private _symbol;

  function _initializeToken(string memory name_, string memory symbol_) internal {
    require(
      bytes(_name).length == 0 &&
      bytes(name_).length != 0 &&
      bytes(symbol_).length != 0,
      "BiShares: BToken already initialized"
    );
    _name = name_;
    _symbol = symbol_;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external pure returns (uint8) {
    return DECIMALS;
  }

  function allowance(address owner, address spender) external override(IERC20) view returns (uint256) {
    return _allowance[owner][spender];
  }

  function balanceOf(address account) external override(IERC20) view returns (uint256) {
    return _balance[account];
  }

  function totalSupply() public override(IERC20) view returns (uint256) {
    return _totalSupply;
  }

  function approve(address spender, uint256 amount) external override(IERC20) returns (bool) {
    address caller = msg.sender;
    _allowance[caller][spender] = amount;
    emit Approval(caller, spender, amount);
    return true;
  }

  function increaseApproval(address dst, uint256 amt) external returns (bool) {
    address caller = msg.sender;
    _allowance[caller][dst] = badd(_allowance[caller][dst], amt);
    emit Approval(caller, dst, _allowance[caller][dst]);
    return true;
  }

  function decreaseApproval(address dst, uint256 amt) external returns (bool) {
    address caller = msg.sender;
    uint256 oldValue = _allowance[caller][dst];
    if (amt > oldValue) {
      _allowance[caller][dst] = 0;
    } else {
      _allowance[caller][dst] = bsub(oldValue, amt);
    }
    emit Approval(caller, dst, _allowance[caller][dst]);
    return true;
  }

  function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool) {
    _move(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool) {
    address caller = msg.sender;
    require(caller == sender || amount <= _allowance[sender][caller], "BiShares: BToken bad caller");
    _move(sender, recipient, amount);
    if (caller != sender && _allowance[sender][caller] != uint256(-1)) {
      _allowance[sender][caller] = bsub(_allowance[sender][caller], amount);
      emit Approval(caller, recipient, _allowance[sender][caller]);
    }
    return true;
  }

  function _onTransfer(address from, address to, uint256 amount) internal override {
    emit Transfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./BConst.sol";


contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "BiShares: Add overflow");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "BiShares: Sub overflow");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "BiShares: Mul overflow");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "BiShares: Mul overflow");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "BiShares: Div zero");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "BiShares: Div overflow");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "BiShares: Div overflow");
    uint256 c2 = c1 / b;
    return c2;
  }

  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;
    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);
      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "BiShares: Bpow base too low");
    require(base <= MAX_BPOW_BASE, "BiShares: Bpow base too high");
    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);
    uint256 wholePow = bpowi(base, btoi(whole));
    if (remain == 0) {
      return wholePow;
    }
    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;
      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }
    return sum;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./BNum.sol";


contract BMath is BConst, BNum {
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
    uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
    uint256 y = bdiv(tokenBalanceOut, diff);
    uint256 foo = bpow(y, weightRatio);
    foo = bsub(foo, BONE);
    tokenAmountIn = bsub(BONE, swapFee);
    tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
    return tokenAmountIn;
  }

  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));
    uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
    uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);
    uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    poolAmountOut = bsub(newPoolSupply, poolSupply);
    return poolAmountOut;
  }

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }

  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
    uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);
    uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
    uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);
    uint256 tokenAmountOutBeforeSwapFee = bsub(
      tokenBalanceOut,
      newTokenBalanceOut
    );
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
    return tokenAmountOut;
  }

  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    uint256 zoo = bsub(BONE, normalizedWeight);
    uint256 zar = bmul(zoo, swapFee);
    uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));
    uint256 newTokenBalanceOut = bsub(
      tokenBalanceOut,
      tokenAmountOutBeforeSwapFee
    );
    uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);
    uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);
    poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
    return poolAmountIn;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract BConst {
  uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;
  uint256 internal constant WEIGHT_CHANGE_PCT = BONE / 100;
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BOUND_TOKENS = 2;
  uint256 internal constant MAX_BOUND_TOKENS = 25;
  uint256 internal constant EXIT_FEE = 1e16;
  uint256 internal constant MIN_WEIGHT = BONE / 8;
  uint256 internal constant MAX_WEIGHT = BONE * 25;
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 26;
  uint256 internal constant MIN_BALANCE = BONE / 10**12;
  uint256 internal constant INIT_POOL_SUPPLY = BONE * 100;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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