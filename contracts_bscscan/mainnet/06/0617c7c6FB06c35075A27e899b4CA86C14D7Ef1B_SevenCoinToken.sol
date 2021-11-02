// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Authorized.sol";
import "./IPancake.sol";
import "./SwapHelper.sol";

contract SevenCoinToken is Authorized, ERC20 {
  address constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address constant ZERO = 0x0000000000000000000000000000000000000000;
  address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  string constant _name = "7coin Token";
  string constant _symbol = "7coin";

  // Token supply control
  uint8 constant decimal = 18;
  uint8 constant decimalBUSD = 18;  
  uint256 constant maxSupply = 21_000_000 * (10 ** decimal);
  
  uint256 public _maxTxAmount = maxSupply;
  uint256 public _maxAccountAmount = maxSupply;
  
  uint256 public totalBurned;

  // Fees
  uint256 public feeAdministrationWallet = 700; // 7%

  uint256 public feePool = 300; // 3%

  bool internal pausedToken = false;
  bool internal pausedStake = false;

  mapping (address => bool) public exemptOperatePausedToken;

  // special wallet permissions
  mapping (address => bool) public exemptFee;
  mapping (address => bool) public exemptFeeReceiver;
  mapping (address => bool) public exemptTxLimit;
  mapping (address => bool) public exemptAmountLimit;
  mapping (address => bool) public exemptStaker;

  // trading pairs
  address[] public liquidityPool;

  address public administrationWallet;

  SwapHelper private swapHelper;

  address WBNB_BUSD_PAIR = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
  address WBNB_COIN_PAIR;

  bool private _noReentrancy = false;

  function getOwner() external view returns (address) { return owner(); }

  function getFeeTotal() public view returns(uint256) { return feePool + feeAdministrationWallet; }

  function togglePauseToken(bool pauseState) external isAuthorized(0) { pausedToken = pauseState; }

  function togglePauseStake(bool pauseState) external isAuthorized(0) { pausedStake = pauseState; }

  function getSwapHelperAddress() external view returns (address) { return address(swapHelper); }

  function setFees(uint256 pool) external isAuthorized(1) {
    feePool = pool;
  }

  function setFeesDirectWallet(uint256 administration) external isAuthorized(1) {
    feeAdministrationWallet = administration;
  }

  function setMaxTxAmountWithDecimals(uint256 decimalAmount) public isAuthorized(1) {
    require(decimalAmount <= maxSupply, "Amount is bigger then maximum supply token");
    _maxTxAmount = decimalAmount;
  }

  function setMaxTxAmount(uint256 amount) external isAuthorized(1) { setMaxTxAmountWithDecimals(amount * (10 ** decimal)); }

  function setMaxAccountAmountWithDecimals(uint256 decimalAmount) public isAuthorized(1) {
    require(decimalAmount <= maxSupply, "Amount is bigger then maximum supply token");
    _maxAccountAmount = decimalAmount;
  }

  function setMaxAccountAmount(uint256 amount) external isAuthorized(1) { setMaxAccountAmountWithDecimals(amount * (10 ** decimal)); }

  // Excempt Controllers
  function setExemptOperatePausedToken(address account, bool operation) public isAuthorized(0) {exemptOperatePausedToken[account] = operation; }
  function setExemptFee(address account, bool operation) public isAuthorized(2) { exemptFee[account] = operation; }
  function setExemptFeeReceiver(address account, bool operation) public isAuthorized(2) { exemptFeeReceiver[account] = operation; }
  function setExemptTxLimit(address account, bool operation) public isAuthorized(2) { exemptTxLimit[account] = operation; }
  function setExemptAmountLimit(address account, bool operation) public isAuthorized(2) { exemptAmountLimit[account] = operation; }
  function setExemptStaker(address account, bool operation) public isAuthorized(2) { exemptStaker[account] = operation; }

  // Special Wallets
  function setAdministrationWallet(address account) public isAuthorized(0) { administrationWallet = account; }
  
  receive() external payable { }

  constructor()ERC20(_name, _symbol) {
    PancakeRouter router = PancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    WBNB_COIN_PAIR = address(PancakeFactory(router.factory()).createPair(WBNB, address(this)));

    // Liquidity pair
    liquidityPool.push(WBNB_COIN_PAIR);
    exemptAmountLimit[WBNB_COIN_PAIR] = true;
    exemptTxLimit[WBNB_COIN_PAIR] = true;
    exemptStaker[WBNB_COIN_PAIR] = true;
    
    // Token address
    exemptFee[address(this)] = true;
    exemptTxLimit[address(this)] = true;
    exemptAmountLimit[address(this)] = true;
    exemptStaker[address(this)] = true;

    // DEAD Waller
    exemptTxLimit[DEAD] = true;
    exemptAmountLimit[DEAD] = true;
    exemptStaker[DEAD] = true;
    exemptFee[DEAD] = true;

    // Zero Waller
    exemptTxLimit[ZERO] = true;
    exemptAmountLimit[ZERO] = true;
    exemptStaker[ZERO] = true;

    //Owner wallet
    address ownerWallet = _msgSender();
    exemptFee[ownerWallet] = true;
    exemptTxLimit[ownerWallet] = true;
    exemptAmountLimit[ownerWallet] = true;
    exemptStaker[ownerWallet] = true;
    exemptOperatePausedToken[ownerWallet] = true;
    
    administrationWallet = 0x0918e8DF56f555169aadbDB11a38dA02bd0A2a9f;

    exemptFee[administrationWallet] = true;
    exemptTxLimit[administrationWallet] = true;
    exemptAmountLimit[administrationWallet] = true;

    swapHelper = new SwapHelper();
    swapHelper.safeApprove(WBNB, address(this), type(uint256).max);

    _mint(ownerWallet, maxSupply);

    pausedToken = true;
  }

  function decimals() public view override returns (uint8) { 
    return decimal;
  }

  function _mint(address account, uint256 amount) internal override {
    require(maxSupply >= ERC20.totalSupply() + amount && maxSupply >= amount, "Maximum supply already minted");
    super._mint(account, amount);
  }

  function _beforeTokenTransfer( address from, address, uint256 amount ) internal view override {
    require(amount <= _maxTxAmount || exemptTxLimit[from], "Excedded the maximum transaction limit");
    require(!pausedToken || exemptOperatePausedToken[from], "Token is paused");
  }

  function _afterTokenTransfer( address, address to, uint256 ) internal view override {
    require(_balances[to] <= _maxAccountAmount || exemptAmountLimit[to], "Excedded the maximum tokens that an wallet can hold");
  }

  function _transfer( address sender, address recipient,uint256 amount ) internal override {
    require(!_noReentrancy, "ReentrancyGuard: reentrant call happens");
    _noReentrancy = true;
    
    require(sender != address(0) && recipient != address(0), "transfer from the zero address");
    
    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "transfer amount exceeds your balance");
    uint256 newSenderBalance = senderBalance - amount;
    _balances[sender] = newSenderBalance;

    uint256 feeAmount = 0;
    if (!exemptFee[sender] && !exemptFeeReceiver[recipient]) feeAmount = (getFeeTotal() * amount) / 10000;

    exchangeFeeParts(feeAmount);
    uint256 newRecipentAmount = _balances[recipient] + (amount - feeAmount);
    _balances[recipient] = newRecipentAmount;

    _afterTokenTransfer(sender, recipient, amount);

    _noReentrancy = false;
    emit Transfer(sender, recipient, amount);
  }

  function exchangeFeeParts(uint256 incomingFeeTokenAmount) private returns (bool){
    if (incomingFeeTokenAmount == 0) return false;
    _balances[address(this)] += incomingFeeTokenAmount;
    
    address pairWbnbCoin = WBNB_COIN_PAIR;
    if (_msgSender() == pairWbnbCoin || pausedStake) return false;
    uint256 feeTokenAmount = _balances[address(this)];
    _balances[address(this)] = 0;

    // Gas optimization
    address wbnbAddress = WBNB;
    (uint112 reserve0, uint112 reserve1) = getTokenReserves(pairWbnbCoin);
    bool reversed = isReversed(pairWbnbCoin, wbnbAddress);
    if (reversed) { uint112 temp = reserve0; reserve0 = reserve1; reserve1 = temp; }
    _balances[pairWbnbCoin] += feeTokenAmount;
    address swapHelperAddress = address(swapHelper);
    uint256 wbnbBalanceBefore = getTokenBalanceOf(wbnbAddress, swapHelperAddress);
    
    uint256 wbnbAmount = getAmountOut(feeTokenAmount, reserve1, reserve0);
    swapToken(pairWbnbCoin, reversed ? 0 : wbnbAmount, reversed ? wbnbAmount : 0, swapHelperAddress);
    uint256 wbnbBalanceNew = getTokenBalanceOf(wbnbAddress, swapHelperAddress);  
    require(wbnbBalanceNew == wbnbBalanceBefore + wbnbAmount, "Wrong amount of swapped on WBNB");
    // Deep Stack problem avoid
    {
      // Gas optimization
      address busdAddress = BUSD;
      address pairWbnbBusd = WBNB_BUSD_PAIR;
      (reserve0, reserve1) = getTokenReserves(pairWbnbBusd);
      reversed = isReversed(pairWbnbBusd, wbnbAddress);
      if (reversed) { uint112 temp = reserve0; reserve0 = reserve1; reserve1 = temp; }

      uint256 busdBalanceBefore = getTokenBalanceOf(busdAddress, address(this));
      tokenTransferFrom(wbnbAddress, swapHelperAddress, pairWbnbBusd, wbnbAmount);
      uint256 busdAmount = getAmountOut(wbnbAmount, reserve0, reserve1);
      swapToken(pairWbnbBusd, reversed ? busdAmount : 0, reversed ? 0 : busdAmount, address(this));
      uint256 busdBalanceNew = getTokenBalanceOf(busdAddress, address(this));
      require(busdBalanceNew == busdBalanceBefore + busdAmount, "Wrong amount swapped on BUSD");
      if (feeAdministrationWallet > 0) tokenTransfer(busdAddress, administrationWallet, (busdAmount * feeAdministrationWallet) / getFeeTotal());
    }
    return true;
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
    totalBurned += amount;
  }

  function buyBackAndHold(uint256 amount, address receiver) external isAuthorized(3) { buyBackAndHoldWithDecimals(amount * (10 ** decimalBUSD), receiver); }

  function buyBackAndHoldWithDecimals(uint256 decimalAmount, address receiver) public isAuthorized(3) { buyBackWithDecimals(decimalAmount, receiver); }

  function buyBackAndBurn(uint256 amount) external isAuthorized(3) { buyBackAndBurnWithDecimals(amount * (10 ** decimalBUSD)); }

  function buyBackAndBurnWithDecimals(uint256 decimalAmount) public isAuthorized(3) { buyBackWithDecimals(decimalAmount, address(0)); }

  function buyBackWithDecimals(uint256 decimalAmount, address destAddress) private {
    uint256 maxBalance = getTokenBalanceOf(BUSD, address(this));
    if (maxBalance < decimalAmount) revert(string(abi.encodePacked("insufficient BUSD amount[", Strings.toString(decimalAmount), "] on contract[", Strings.toString(maxBalance), "]")));

    (uint112 reserve0,uint112 reserve1) = getTokenReserves(WBNB_BUSD_PAIR);
    bool reversed = isReversed(WBNB_BUSD_PAIR, BUSD);
    if (reversed) { uint112 temp = reserve0; reserve0 = reserve1; reserve1 = temp; }

    tokenTransfer(BUSD, WBNB_BUSD_PAIR, decimalAmount);
    uint256 wbnbAmount = getAmountOut(decimalAmount, reserve0, reserve1);
    swapToken(WBNB_BUSD_PAIR, reversed ? wbnbAmount : 0, reversed ? 0 : wbnbAmount, address(this));

    bool previousExemptFeeState = exemptFee[WBNB_COIN_PAIR];
    exemptFee[WBNB_COIN_PAIR] = true;
    
    address pairWbnbCoin = WBNB_COIN_PAIR;
    address swapHelperAddress = address(swapHelper);
    (reserve0, reserve1) = getTokenReserves(pairWbnbCoin);
    reversed = isReversed(pairWbnbCoin, WBNB);
    if (reversed) { uint112 temp = reserve0; reserve0 = reserve1; reserve1 = temp; }

    tokenTransfer(WBNB, pairWbnbCoin, wbnbAmount);
    
    uint256 coinAmount = getAmountOut(wbnbAmount, reserve0, reserve1);
    if (destAddress == address(0)) {
      swapToken(pairWbnbCoin, reversed ? coinAmount : 0, reversed ? 0 : coinAmount, swapHelperAddress);
      _burn(swapHelperAddress, coinAmount);
      totalBurned += coinAmount;
    } else {
      swapToken(pairWbnbCoin, reversed ? coinAmount : 0, reversed ? 0 : coinAmount, destAddress);
    }
    exemptFee[WBNB_COIN_PAIR] = previousExemptFeeState;
  }
 
  function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, 'Insufficient amount in');
    require(reserveIn > 0 && reserveOut > 0, 'Insufficient liquidity');
    uint256 amountInWithFee = amountIn * 9975;
    uint256 numerator = amountInWithFee  * reserveOut;
    uint256 denominator = (reserveIn * 10000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // gas optimization on get Token0 from a pair liquidity pool
  function isReversed(address pair, address tokenA) internal view returns (bool) {
    address token0;
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x0dfe168100000000000000000000000000000000000000000000000000000000)
      failed := iszero(staticcall(gas(), pair, emptyPointer, 0x04, emptyPointer, 0x20))
      token0 := mload(emptyPointer)
    }
    if (failed) revert(string(abi.encodePacked("Unable to check direction of token ", Strings.toHexString(uint160(tokenA), 20) ," from pair ", Strings.toHexString(uint160(pair), 20))));
    return token0 != tokenA;
  }

  // gas optimization on transfer token
  function tokenTransfer(address token, address recipient, uint256 amount) internal {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
      mstore(add(emptyPointer, 0x04), recipient)
      mstore(add(emptyPointer, 0x24), amount)
      failed := iszero(call(gas(), token, 0, emptyPointer, 0x44, 0, 0))
    }
    if (failed) revert(string(abi.encodePacked("Unable to transfer ", Strings.toString(amount), " of token [", Strings.toHexString(uint160(token), 20) ,"] to address ", Strings.toHexString(uint160(recipient), 20))));
  }

  // gas optimization on transfer from token method
  function tokenTransferFrom(address token, address from, address recipient, uint256 amount) internal {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
      mstore(add(emptyPointer, 0x04), from)
      mstore(add(emptyPointer, 0x24), recipient)
      mstore(add(emptyPointer, 0x44), amount)
      failed := iszero(call(gas(), token, 0, emptyPointer, 0x64, 0, 0)) 
    }
    if (failed) revert(string(abi.encodePacked("Unable to transfer from [", Strings.toHexString(uint160(from), 20)  ,"] ", Strings.toString(amount), " of token [", Strings.toHexString(uint160(token), 20) ,"] to address ", Strings.toHexString(uint160(recipient), 20))));
  }

  // gas optimization on swap operation using a liquidity pool
  function swapToken(address pair, uint amount0Out, uint amount1Out, address receiver) internal {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
      mstore(add(emptyPointer, 0x04), amount0Out)
      mstore(add(emptyPointer, 0x24), amount1Out)
      mstore(add(emptyPointer, 0x44), receiver)
      mstore(add(emptyPointer, 0x64), 0x80)
      mstore(add(emptyPointer, 0x84), 0)
      failed := iszero(call(gas(), pair, 0, emptyPointer, 0xa4, 0, 0))
    }
    if (failed) revert(string(abi.encodePacked("Unable to swap ", Strings.toString(amount0Out == 0 ? amount1Out : amount0Out), " on Pain [", Strings.toHexString(uint160(pair), 20)  ,"] to receiver ", Strings.toHexString(uint160(receiver), 20) )));
  }

  // gas optimization on get balanceOf fron BEP20 or ERC20 token
  function getTokenBalanceOf(address token, address holder) internal view returns (uint112 tokenBalance) {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x70a0823100000000000000000000000000000000000000000000000000000000)
      mstore(add(emptyPointer, 0x04), holder)
      failed := iszero(staticcall(gas(), token, emptyPointer, 0x24, emptyPointer, 0x40))
      tokenBalance := mload(emptyPointer)
    }
    if (failed) revert(string(abi.encodePacked("Unable to get balance from wallet [", Strings.toHexString(uint160(holder), 20) ,"] of token [", Strings.toHexString(uint160(token), 20) ,"] ")));
  }

  // gas optimization on get reserves from liquidity pool
  function getTokenReserves(address pairAddress) internal view returns (uint112 reserve0, uint112 reserve1) {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
      failed := iszero(staticcall(gas(), pairAddress, emptyPointer, 0x4, emptyPointer, 0x40))
      reserve0 := mload(emptyPointer)
      reserve1 := mload(add(emptyPointer, 0x20))
    }
    if (failed) revert(string(abi.encodePacked("Unable to get reserves from pair [", Strings.toHexString(uint160(pairAddress), 20), "]")));
  }

  function walletHolder(address account) private view returns (address holder) {
    return exemptStaker[account] ? address(0x00) : account;
  }

  function setWBNB_COIN_PAIR(address newPair) external isAuthorized(0) { WBNB_COIN_PAIR = newPair; }
  function setWBNB_BUSD_Pair(address newPair) external isAuthorized(0) { WBNB_BUSD_PAIR = newPair; }
  function getWBNB_COIN_PAIR() external view returns(address) { return WBNB_COIN_PAIR; }
  function getWBNB_BUSD_Pair() external view returns(address) { return WBNB_BUSD_PAIR; }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Authorized is Ownable {
  mapping(uint8 => mapping(address => bool)) public permissions;
  string[] public permissionIndex;

  constructor() {
    permissionIndex.push("admin");
    permissionIndex.push("financial");
    permissionIndex.push("controller");
    permissionIndex.push("operator");

    permissions[0][_msgSender()] = true;
  }

  modifier isAuthorized(uint8 index) {
    if (!permissions[index][_msgSender()]) {
      revert(string(abi.encodePacked("Account ",Strings.toHexString(uint160(_msgSender()), 20)," does not have ", permissionIndex[index], " permission")));
    }
    _;
  }

  function safeApprove(address token, address spender, uint256 amount) external isAuthorized(0) {
    ERC20(token).approve(spender, amount);
  }

  function safeWithdraw() external isAuthorized(0) {
    uint256 contractBalance = address(this).balance;
    payable(_msgSender()).transfer(contractBalance);
  }

  function grantPermission(address operator, uint8[] memory grantedPermissions) external isAuthorized(0) {
    for (uint8 i = 0; i < grantedPermissions.length; i++) permissions[grantedPermissions[i]][operator] = true;
  }

  function revokePermission(address operator, uint8[] memory revokedPermissions) external isAuthorized(0) {
    for (uint8 i = 0; i < revokedPermissions.length; i++) permissions[revokedPermissions[i]][operator]  = false;
  }

  function grantAllPermissions(address operator) external isAuthorized(0) {
    for (uint8 i = 0; i < permissionIndex.length; i++) permissions[i][operator]  = true;
  }

  function revokeAllPermissions(address operator) external isAuthorized(0) {
    for (uint8 i = 0; i < permissionIndex.length; i++) permissions[i][operator]  = false;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
interface PancakeFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PancakeRouter {
  function factory() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwapHelper is Ownable {
  constructor() {}

  function safeApprove(address token, address spender, uint256 amount) external onlyOwner { ERC20(token).approve(spender, amount); }

  function safeWithdraw() external onlyOwner { payable(_msgSender()).transfer(address(this).balance); }
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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