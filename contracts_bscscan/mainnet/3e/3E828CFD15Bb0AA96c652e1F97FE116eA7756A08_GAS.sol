// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";

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

/**
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    *
    * - Addition cannot overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      return a + b;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      return a - b;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    *
    * - Multiplication cannot overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      return a * b;
  }

  /**
    * @dev Returns the integer division of two unsigned integers, reverting on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator.
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
  }
}


/**
  * @dev Interface for communication with NFT CARS Smart contract
*/
interface INFTCARS {
  /**
    * @dev Returns the total amount of tokens stored by the contract.
  */
  function totalSupply() external view returns (uint256);

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
}

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of BEP20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract GAS is Context, IBEP20, IBEP20Metadata {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 public constant SECONDS_IN_A_DAY = 86400;
  uint256 public constant emissionPerDay = 50 * 10**18; // 50 tokens per day
  uint256 public constant initialAllowment = 2000 * 10**18; // 2000 tokens for the first claim


  string private _name = "NFTCARS GAS";
  string private _symbol = "GAS";

  mapping(uint256 => uint256) private _lastClaim;
  mapping(uint256 => bool) private _claimedInitial;

  address public constant NFT_CARS_ADDRESS = 0x6D4E828af7911A9cDb83Ce4cB3BB5DaE8081defE;
  INFTCARS private CARS = INFTCARS(NFT_CARS_ADDRESS);

  /**
    * @dev Contract constructor
    */
  constructor() {}

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
    * Ether and Wei. This is the value {BEP20} uses, unless this function is
    * overridden;
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * {IBEP20-balanceOf} and {IBEP20-transfer}.
    */
  function decimals() public view virtual override returns (uint8) {
      return 18;
  }

  /**
    * @dev See {IBEP20-totalSupply}.
    */
  function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
  }

  /**
    * @dev See {IBEP20-balanceOf}.
    */
  function balanceOf(address account) public view virtual override returns (uint256) {
      return _balances[account];
  }

  /**
    * @dev See {IBEP20-transfer}.
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
    * @dev See {IBEP20-allowance}.
    */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }

  /**
    * @dev See {IBEP20-approve}.
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
    * @dev See {IBEP20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {BEP20}.
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
      require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
      unchecked {
          _approve(sender, _msgSender(), currentAllowance - amount);
      }

      return true;
  }

  /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IBEP20-approve}.
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
    * problems described in {IBEP20-approve}.
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
      require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
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
      require(sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero address");

      _beforeTokenTransfer(sender, recipient, amount);

      uint256 senderBalance = _balances[sender];
      require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
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
      require(account != address(0), "BEP20: mint to the zero address");

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
      require(account != address(0), "BEP20: burn from the zero address");

      _beforeTokenTransfer(account, address(0), amount);

      uint256 accountBalance = _balances[account];
      require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
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
      require(owner != address(0), "BEP20: approve from the zero address");
      require(spender != address(0), "BEP20: approve to the zero address");

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

  /**
    * @dev Returns number of GAS tokens available for claim for a spesific CARS token Id.
  */
  function getClaimableAmount(uint256 tokenId)  internal view returns (uint256) {
      require(CARS.ownerOf(tokenId) != address(0), "Owner cannot be 0 address");
      require(tokenId < CARS.totalSupply(), "CARS at index has not been minted yet");

      uint256 lastClaimed = _lastClaim[tokenId];

      if (lastClaimed != 0) {
        uint256 accumulationPeriod = block.timestamp;
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);
        return totalAccumulated;
      }
      
      return initialAllowment;
  }

    /**
    * @dev Returns number of GAS tokens available for claim for a spesific CARS token Id.
  */
  function getTotalClaimableAmount(uint256[] memory tokenIds)  public view returns (uint256) {
    uint256 totalClaimQty = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
        // Sanity check for non-minted index
        require(tokenIds[i] < CARS.totalSupply(), "Token at id has not been minted yet");
        // Duplicate token index check
        for (uint j = i + 1; j < tokenIds.length; j++) {
            require(tokenIds[i] != tokenIds[j], "Duplicate token index");
        }

        uint tokenId = tokenIds[i];
        uint256 claimQty = getClaimableAmount(tokenId);

        if (claimQty != 0) {
            totalClaimQty = totalClaimQty.add(claimQty);
        }
    }

    return totalClaimQty;
  }

  /**
    * @dev Public function for claiming GAS token. Can be triggered by CARS owner only.
  */
  function claim(uint256[] memory tokenIds) public returns (uint256) {
    uint256 totalClaimQty = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
        // Sanity check for non-minted index
        require(tokenIds[i] < CARS.totalSupply(), "Token at id has not been minted yet");
        // Duplicate token index check
        for (uint j = i + 1; j < tokenIds.length; j++) {
            require(tokenIds[i] != tokenIds[j], "Duplicate token index");
        }

        uint tokenId = tokenIds[i];
        require(CARS.ownerOf(tokenId) == msg.sender, "Sender is not the owner");

        uint256 claimQty = getClaimableAmount(tokenId);

        if (claimQty != 0) {
            totalClaimQty = totalClaimQty.add(claimQty);
            _lastClaim[tokenId] = block.timestamp;
        }

        if (!_claimedInitial[tokenId]) { _claimedInitial[tokenId] = true; }
    }

    require(totalClaimQty != 0, "No accumulated GAS");
    _mint(msg.sender, totalClaimQty);
    return totalClaimQty;
  }

  /**
    * @dev Returns boolean on wheather the initial 2000 tokens were allocated to a specific token ID or not yet.
  */
  function isClaimedInitial(uint256 tokenId) public view returns (bool) {
    require(CARS.ownerOf(tokenId) != address(0), "Owner cannot be 0 address");
    require(tokenId < CARS.totalSupply(), "CARS at index has not been minted yet");

    return _claimedInitial[tokenId];
  }

  /**
    * @dev Destroys `amountToBurn` tokens from msg.sender, reducing the
    * total supply.
  */
  function burn(uint256 amountToBurn) public {
    _burn(_msgSender(), amountToBurn);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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