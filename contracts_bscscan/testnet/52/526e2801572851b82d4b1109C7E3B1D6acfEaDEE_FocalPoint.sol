/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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
    mapping(address => uint256) private _balances;

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


// File contracts/ISwap.sol


pragma solidity ^0.8.11;

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapRouter {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


// File contracts/token/FocalPoint.sol


pragma solidity ^0.8.11;

contract FocalPoint is ERC20, Ownable {
  ISwapRouter private _router;
  address private _routerAddress;
  address public swapPairAddress;

  uint256 private constant BUY = 1;
  uint256 private constant SELL = 2;
  uint256 private constant TRANSFER = 3;
  uint256 private constant CONTRACT = 4;
  uint256 private constant FEELESS = 5;

  event SwapAndLiquifyUpdated(bool _enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiquidity
  );
  bool public swapAndLiquifyEnabled = false;
  bool private _liquifying;

  bool public tradingEnabled = false;
  uint256 public maxTxAmount;
  uint256 private _minSwapTokens;

  event UpdatePlatformInfo(uint256 buyFee, uint256 sellFee, address addy);
  event UpdateMarketingInfo(uint256 buyFee, uint256 sellFee, address addy);
  event UpdateLiqudityFee(uint256 buyFee, uint256 sellFee);
  uint256 public platformBuyFee = 0;
  uint256 public platformSellFee = 0;
  uint256 private _tokensForPlatform;

  uint256 public marketingBuyFee = 0;
  uint256 public marketingSellFee = 0;
  uint256 private _tokensForMarketing;

  uint256 public liquidityBuyFee = 0;
  uint256 public liquiditySellFee = 0;
  uint256 private _tokensForLiquidity;

  address public platformAddress;
  address public marketingAddress;
  address public liquidityAddress;

  event AddFeeExemption(address addy);
  event RemoveFeeExemption(address addy);
  mapping(address => bool) public feelessAddresses;
  bool public feesEnabled = false;

  modifier lockTheSwap() {
    _liquifying = true;
    _;
    _liquifying = false;
  }

  constructor(
    address routerAddress,
    address mAddress,
    address pAddress
  ) ERC20("Focal Point", "FOCAL") {
    uint256 supply = 15000000;

    // mint total supply and set transaction limits
    _mint(msg.sender, supply * 10**decimals());
    maxTxAmount = (supply / 200) * 10**decimals(); // 0.5%
    _minSwapTokens = (supply / 2000) * 10**decimals(); // 0.05%

    // create pair on the swapping DEX with WETH
    _routerAddress = routerAddress;
    _router = ISwapRouter(_routerAddress);
    swapPairAddress = ISwapFactory(_router.factory()).createPair(
      address(this),
      _router.WETH()
    );

    // setup fee information
    liquidityAddress = msg.sender;
    marketingAddress = mAddress;
    platformAddress = pAddress;

    platformBuyFee = 2;
    marketingBuyFee = 2;
    liquidityBuyFee = 2;

    platformSellFee = 12;
    marketingSellFee = 4;
    liquiditySellFee = 4;

    setFeeless(address(this), true);
    setFeeless(msg.sender, true);
    setFeeless(mAddress, true);
    setFeeless(pAddress, true);
  }

  // To receive ETH from router when swapping
  receive() external payable {}

  function enableTrading() public onlyOwner {
    require(tradingEnabled == false);
    tradingEnabled = true;
    enableFees(true);
  }

  function enableFees(bool v) public onlyOwner {
    feesEnabled = v;
  }

  function setFeeless(address addy, bool value) public onlyOwner {
    feelessAddresses[addy] = value;
    if (value == true) {
      emit AddFeeExemption(addy);
    } else {
      emit RemoveFeeExemption(addy);
    }
  }

  // marketing wallet operations
  function setMarketingAddress(address addy) public onlyOwner {
    require(addy != address(0));
    marketingAddress = addy;
    emit UpdateMarketingInfo(marketingBuyFee, marketingSellFee, addy);
  }

  function setMarketingBuyFee(uint256 buyFee) public onlyOwner {
    require(buyFee <= 20 && buyFee > 0); // max tax 20%
    require((buyFee + platformBuyFee + liquidityBuyFee) <= 20);
    platformBuyFee = buyFee;
    emit UpdatePlatformInfo(buyFee, marketingSellFee, marketingAddress);
  }

  function setMarketingSellFee(uint256 sellFee) public onlyOwner {
    require(sellFee <= 20 && sellFee > 0); // max tax 20%
    require((sellFee + platformSellFee + liquiditySellFee) <= 20);
    marketingSellFee = sellFee;
    emit UpdateMarketingInfo(marketingBuyFee, sellFee, marketingAddress);
  }

  // platform wallet operations
  function setPlatformAddress(address addy) public onlyOwner {
    require(addy != address(0));
    platformAddress = addy;
    emit UpdatePlatformInfo(platformBuyFee, platformSellFee, addy);
  }

  function setPlatformBuyFee(uint256 buyFee) public onlyOwner {
    require(buyFee <= 20 && buyFee > 0); // max tax 20%
    require((buyFee + marketingBuyFee + liquidityBuyFee) <= 20);
    platformBuyFee = buyFee;
    emit UpdatePlatformInfo(buyFee, platformSellFee, platformAddress);
  }

  function setPlatformSellFee(uint256 sellFee) public onlyOwner {
    require(sellFee <= 20 && sellFee > 0); // max tax 20%
    require((sellFee + marketingSellFee + liquiditySellFee) <= 20);
    platformSellFee = sellFee;
    emit UpdatePlatformInfo(platformBuyFee, sellFee, platformAddress);
  }

  // liquidity fees
  function setLiquiditySellFee(uint256 sellFee) public onlyOwner {
    require(sellFee <= 20 && sellFee > 0); // max tax 20%
    require((sellFee + platformSellFee + marketingSellFee) <= 20);
    liquiditySellFee = sellFee;
    emit UpdateLiqudityFee(liquidityBuyFee, sellFee);
  }

  function setLiquidityBuyFee(uint256 buyFee) public onlyOwner {
    require(buyFee <= 20 && buyFee > 0); // max tax 20%
    require((buyFee + platformSellFee + marketingBuyFee) <= 20);
    liquidityBuyFee = buyFee;
    emit UpdateLiqudityFee(buyFee, liquiditySellFee);
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyUpdated(_enabled);
  }

  // token transfer logic
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    uint256 transferType = _getTransferType(sender, recipient);
    
    // prevent trading until manually enabled 
    if (transferType == BUY || transferType == SELL) {
      require(tradingEnabled == true);
      require(amount <= maxTxAmount);
    }
    // if fees are off just skip the checks
    if (feesEnabled == false) {
      super._transfer(sender, recipient, amount);
      return;
    }

    if (transferType == BUY) {
      _buyTransfer(sender, recipient, amount);
    } else if (transferType == SELL) {
      _sellTransfer(sender, recipient, amount);
    } else {
      // normal transfer if not a BUY or SELL
      super._transfer(sender, recipient, amount);
    }
  }

  function _calculateTokensForFee(uint256 amount, uint256 feePercent)
    private
    pure
    returns (uint256)
  {
    return (amount * feePercent) / (10**2);
  }

  function _getTransferType(address sender, address recipient)
    private
    view
    returns (uint256)
  {
    uint256 transferType = 0;
    if (feelessAddresses[sender] == true) {
      transferType = FEELESS;
    } else if (sender == address(this)) {
      transferType = CONTRACT;
    } else if (sender == swapPairAddress) {
      transferType = BUY;
    } else if (recipient == swapPairAddress) {
      transferType = SELL;
    } else {
      transferType = TRANSFER;
    }
    return transferType;
  }

  // calculate taxes for a BUY (sender is the pair)
  function _buyTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    uint256 newLiquidityTokens = _calculateTokensForFee(
      amount,
      liquidityBuyFee
    );
    uint256 newMarketingTokens = _calculateTokensForFee(
      amount,
      marketingBuyFee
    );
    uint256 newPlatformTokens = _calculateTokensForFee(amount, platformBuyFee);
    uint256 txFeeTokens = newLiquidityTokens +
      newMarketingTokens +
      newPlatformTokens;

    // track portion of collected tokens for each fee
    _tokensForLiquidity += newLiquidityTokens;
    _tokensForMarketing += newMarketingTokens;
    _tokensForPlatform += newPlatformTokens;

    // send the buyer the promised token amount
    super._transfer(sender, recipient, amount);
    // then force-send the tax fees back to self
    super._transfer(recipient, address(this), txFeeTokens);
  }

  // calculate taxes for a SELL (pair is the recipient)
  function _sellTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    // check if we should perform a liquify
    uint256 tokenBalance = balanceOf(address(this));
    if (
      !_liquifying && swapAndLiquifyEnabled && tokenBalance >= _minSwapTokens
    ) {
      // contract min balance of tokens must be high enough
      _swapAndLiquify(
        _tokensForLiquidity + _tokensForMarketing + _tokensForPlatform
      );
    }
    uint256 newLiquidityTokens = _calculateTokensForFee(
      amount,
      liquiditySellFee
    );
    uint256 newMarketingTokens = _calculateTokensForFee(
      amount,
      marketingSellFee
    );
    uint256 newPlatformTokens = _calculateTokensForFee(amount, platformSellFee);
    uint256 txFeeTokens = newLiquidityTokens +
      newMarketingTokens +
      newPlatformTokens;

    // track portion of collected tokens for each fee
    _tokensForLiquidity += newLiquidityTokens;
    _tokensForMarketing += newMarketingTokens;
    _tokensForPlatform += newPlatformTokens;

    // send the pair the promised token amount
    super._transfer(sender, recipient, amount);
    // then force-send the tax fees back to self
    super._transfer(recipient, address(this), txFeeTokens);
  }

  // autoliquidity and fee logic
  function _swapAndLiquify(uint256 tokensToLiquify) private lockTheSwap {
    uint256 tokenBalance = balanceOf(address(this));

    // Half of the collected tokens need to be sold
    // the rest are reserved for adding to liquidity
    uint256 tokensForLiquidity = tokensToLiquify / 2;
    uint256 amountToSwapForNative = tokenBalance - tokensForLiquidity;

    uint256 initialNativeBalance = address(this).balance;

    // sell the tokens and divide recieved amount to fee addresses
    _swapTokensForNative(amountToSwapForNative);
    uint256 nativeBalance = address(this).balance - initialNativeBalance;
    uint256 nativeForMarketing = (nativeBalance * _tokensForMarketing) /
      tokensToLiquify;
    uint256 nativeForPlatform = (nativeBalance * _tokensForPlatform) /
      tokensToLiquify;
    uint256 nativeForLiquidity = nativeBalance -
      nativeForMarketing -
      nativeForPlatform;

    // after a liquify reset our tracking variables
    _tokensForLiquidity = 0;
    _tokensForMarketing = 0;
    _tokensForPlatform = 0;
    
    // add the remaining native token as liquidity along with
    // reserved tokens
    _addLiquidity(tokensForLiquidity, nativeForLiquidity);
    emit SwapAndLiquify(
      amountToSwapForNative,
      nativeForLiquidity,
      tokensForLiquidity
    );

    // send the native token to the fee addresses
    (bool success, ) = address(marketingAddress).call{
      value: nativeForMarketing
    }("");
    (success, ) = address(platformAddress).call{value: nativeForPlatform}("");

    // move any remaining native tokens to the platform address
    if (address(this).balance > 1e17) {
      (success, ) = address(platformAddress).call{value: address(this).balance}(
        ""
      );
    }
  }

  function _swapTokensForNative(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _router.WETH();
    _approve(address(this), address(_routerAddress), tokenAmount);
    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(_routerAddress), tokenAmount);
    _router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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