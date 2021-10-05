/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// Part: Context

/*
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

// Part: IERC20

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

// Part: IERC20Metadata

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

// Part: ERC20

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
     * will be to transferred to `to`.
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
}

// Part: tokenPrueba

contract tokenPrueba is ERC20("TokenPrueba","TKN"){
  constructor () public {
    _mint(msg.sender, 10000 ether);
  }
}

// File: Exchange.sol

contract Exchange is ERC20("COINSMOS LP","CLP"){

  event TokenPurchase(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
  event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
  event AddLiquidity(address indexed provider, uint256 indexed eth_suministrado, uint256 indexed token_suministrado);
  event RemoveLiquidity(address indexed provider, uint256 indexed eth_removido, uint256 indexed token_retirado);



  address token;


  function setup(address _token) external {
    require (token == address(0));
    require (_token != address(0));
    token = _token;

  }

  function getTokensWhenLiquidity(uint256 etherInput, uint256 tokenReserve, uint256 ethReserve) public returns(uint256){
    return (etherInput*tokenReserve)/ethReserve;
  }

  function addLiquidity(uint256 amountTokens) external payable returns(uint256){
    require (msg.value > 0);
    uint256 total_liquidity = totalSupply();
    if (total_liquidity > 0){
      uint256 eth_reserve = address(this).balance - msg.value;
      uint256 token_reserve = tokenPrueba(token).balanceOf(address(this));
      uint256 token_amount = msg.value*token_reserve/eth_reserve;
      uint256 liquidity_minted = msg.value*total_liquidity/eth_reserve;
      _mint(msg.sender, liquidity_minted);
      if (tokenPrueba(token).transferFrom(msg.sender, address(this), token_amount) == false){
        revert();
      }
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      return liquidity_minted;
    }
    else {
      require (msg.value >= 1000000000);
      uint256 token_amount = amountTokens;
      uint256 initial_liquidity = address(this).balance;
      _mint(msg.sender, initial_liquidity);
      if (tokenPrueba(token).transferFrom(msg.sender, address(this), token_amount) == false){
        revert();
      }
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      return initial_liquidity;

    }
  }

  function removeLiquidity() external returns(uint256,uint256){
      uint256 total_liquidity = totalSupply();
      uint256 amount = balanceOf(msg.sender);
      require (total_liquidity > 0);
      uint256 token_reserve = tokenPrueba(token).balanceOf(address(this));
      uint256 eth_amount = amount * address(this).balance / total_liquidity;
      uint256 token_amount = amount * token_reserve / total_liquidity;
      _burn(msg.sender, amount);
      payable(msg.sender).transfer(eth_amount);
      if (tokenPrueba(token).transfer(msg.sender, token_amount) == false){
        revert();
      }

      emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
      return (eth_amount, token_amount);
  }

  function ethToTokenSwapInput() external payable returns(uint256) {
    return ethToTokenInput(msg.value,msg.sender, msg.sender);
  }

  function ethToTokenSwapOutput(uint256 tokens_bought) external payable returns(uint256){
    return ethToTokenOutput(tokens_bought, msg.value, msg.sender, msg.sender);
  }

  function ethToTokenInput(uint256 eth_sold,address buyer, address recipient) internal returns(uint256){
    require (eth_sold > 0);
    uint token_reserve = tokenPrueba(token).balanceOf(address(this));
    uint tokens_bought = getInputPrice(eth_sold, address(this).balance - eth_sold, token_reserve);
    if (tokenPrueba(token).transfer(recipient, tokens_bought) == false){
      revert();
    }
    emit TokenPurchase(buyer, eth_sold, tokens_bought);
    return tokens_bought;

  }

  function ethToTokenOutput(uint256 tokens_bought, uint256 max_eth, address buyer, address recipient) internal returns(uint256){
    require (tokens_bought > 0);
    require (max_eth > 0);
    uint256 token_reserve = tokenPrueba(token).balanceOf(address(this));
    uint256 eth_sold = getOutputPrice(tokens_bought, address(this).balance - max_eth, token_reserve);
    uint256 eth_refund = max_eth - eth_sold;
    if (eth_refund > 0){
        payable(buyer).transfer(eth_refund);
    }
    if (tokenPrueba(token).transfer(recipient, tokens_bought) == false){
      revert();
    }
    return eth_sold;


  }

  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns(uint256){
    require (input_reserve > 0);
    require (output_reserve > 0);
    uint256 numerator = input_amount*output_reserve;
    uint256 denominator = input_reserve + input_amount;
    return numerator / denominator;
  }

  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public pure returns(uint256){
    require(input_reserve > 0);
    require(output_reserve > 0);
    uint256 numerator = input_reserve*output_amount;
    uint256 denominator = output_reserve-output_amount;
    return numerator/denominator;
  }

  function tokenToEthSwapInput(uint256 tokens_sold) external returns(uint256){
    return tokenToEthInput(tokens_sold, msg.sender, msg.sender);
  }

  function tokenToEthSwapOutput(uint256 eth_bought) external returns(uint256){
    return tokenToEthOutput(eth_bought, msg.sender, msg.sender);
  }

  function tokenToEthInput(uint256 tokens_sold, address buyer, address recipient) internal returns(uint256){
    require (tokens_sold > 0);

    uint256 token_reserve = tokenPrueba(token).balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);

    payable(recipient).transfer(eth_bought);
    if (tokenPrueba(token).transferFrom(buyer, address(this), tokens_sold) == false){
      revert();
    }
    emit EthPurchase(buyer, tokens_sold, eth_bought);
    return eth_bought;
  }

  function tokenToEthOutput(uint256 eth_bought,  address buyer, address recipient) internal returns(uint256){
    require(eth_bought > 0);
    uint256 token_reserve = tokenPrueba(token).balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(eth_bought, token_reserve, address(this).balance);

    payable(recipient).transfer(eth_bought);
    if (tokenPrueba(token).transferFrom(buyer, address(this), tokens_sold) == false){
      revert();
    }
    emit EthPurchase(buyer, tokens_sold, eth_bought);
    return tokens_sold;

  }

  function tokenAddress() external view returns(address){
    return token;
  }



}