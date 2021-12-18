// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol"; 
import "link.sol";

interface VaultV0 {
    function expiry() external returns (uint);  
    function COLLAT_ADDRESS() external returns (address); 
    function PRICE_FEED() external returns (address);
    function LINK_AGGREGATOR() external returns (address);
    
    /* Multisig Alpha */
    function setOwner(address newOwner) external;
    function settleStrike_MM(uint priceX1e6) external;
    function setExpiry(uint arbitraryExpiry) external;
    function setMaxCap(uint newDepositCap) external;
    function setMaker(address newMaker) external;
    function setPriceFeed(HistoricalPriceConsumerV3_1 newPriceFeed) external;
    function emergencyWithdraw() external;
    function depositOnBehalf(address tgt, uint256 amt) external;
    function setAllowInteraction(bool _flag) external;
}

contract OwnerProxy {

    address public multisigAlpha;
    address public multisigBeta;
    address public teamKey;

    address public multisigAlpha_pending;
    address public multisigBeta_pending;
    address public teamKey_pending;
    
    mapping(bytes32 => uint) public queuedPriceFeed;
    
    event PriceFeedQueued(address indexed _vault, address pricedFeed);
    
    constructor() {
      multisigAlpha = msg.sender;
      multisigBeta  = msg.sender;
      teamKey       = msg.sender;
    }
    
    function setMultisigAlpha(address _newMultisig) external {
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      multisigAlpha_pending = _newMultisig;
    }

    function setMultisigBeta(address _newMultisig) external {
      require(msg.sender == multisigAlpha || msg.sender == multisigBeta, "!multisigAlpha/Beta");
      multisigBeta_pending = _newMultisig;
    }
    
    function setTeamKey(address _newTeamKey) external {
      require(msg.sender == multisigAlpha || msg.sender == multisigBeta || msg.sender == teamKey, "!ownerKey");
      teamKey_pending = _newTeamKey;
    }
    
    function acceptMultisigAlpha() external {
      require(msg.sender == multisigAlpha_pending, "!multisigAlpha_pending");
      multisigAlpha = multisigAlpha_pending;
    }

    function acceptMultisigBeta() external {
      require(msg.sender == multisigBeta_pending, "!multisigBeta_pending");
      multisigBeta = multisigBeta_pending;
    }

    function acceptTeamKey() external {
      require(msg.sender == teamKey_pending, "!teamKey_pending");
      teamKey = teamKey_pending;
    }
    
    function setOwner(VaultV0 _vault, address _newOwner) external { 
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      _vault.setOwner(_newOwner);
    }
    
    function emergencyWithdraw(VaultV0 _vault) external { 
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      _vault.emergencyWithdraw();
      IERC20 COLLAT = IERC20(_vault.COLLAT_ADDRESS());
      COLLAT.transfer(multisigAlpha, COLLAT.balanceOf( address(this) ));
      require(COLLAT.balanceOf(address(this)) == 0, "eWithdraw transfer failed."); 
    }
    
    function queuePriceFeed(VaultV0 _vault, HistoricalPriceConsumerV3_1 _priceFeed) external {
      if        (msg.sender == multisigAlpha) {  // multisigAlpha can instantly change the price feed 
        _vault.setPriceFeed(_priceFeed);
        return;
      } else if (msg.sender == multisigBeta) {
        bytes32 hashedParams = keccak256(abi.encodePacked(_vault, _priceFeed));
        if (queuedPriceFeed[hashedParams] == 0) {
          queuedPriceFeed[hashedParams] = block.timestamp + 1 days;
          emit PriceFeedQueued(address(_vault), address(_priceFeed));
        } else {
          require(block.timestamp > queuedPriceFeed[hashedParams], "Timelocked"); 
          _vault.setPriceFeed(_priceFeed);
        }
      } else if (msg.sender == teamKey) {
        bytes32 hashedParams = keccak256(abi.encodePacked(_vault, _priceFeed));
        if (queuedPriceFeed[hashedParams] > 0) {
          require(block.timestamp > queuedPriceFeed[hashedParams], "Timelocked");
          _vault.setPriceFeed(_priceFeed);
        }
      }
    }

    function settleStrike_MM(VaultV0 _vault, uint _priceX1e6) external {
      if   (msg.sender == multisigAlpha) { // Arbitrary price setting
        _vault.settleStrike_MM(_priceX1e6);
      } else {
        uint curPrice = uint(HistoricalPriceConsumerV3_1(_vault.PRICE_FEED()).getLatestPriceX1e6(AggregatorV3Interface(_vault.LINK_AGGREGATOR())));
        uint upperBound = curPrice;
        uint lowerBound = curPrice; 
        if (msg.sender == multisigBeta) {   // +/- 20% price set
          upperBound = curPrice * 1200 / 1000;
          lowerBound = curPrice *  800 / 1000;
        } else if (msg.sender == teamKey) { // +/- 5% price set
          upperBound = curPrice * 1050 / 1000;
          lowerBound = curPrice *  950 / 1000;        
        } else {
          revert("Not Owner Keys");
        }
        if (_priceX1e6 > upperBound) revert("Price too high");
        if (_priceX1e6 < lowerBound) revert("Price too low");
        _vault.settleStrike_MM(_priceX1e6);       
      }
    }
    
    function setExpiry(VaultV0 _vault, uint _expiry) external {
      require(msg.sender == multisigBeta, "Not multisigBeta");
      require(_vault.expiry() > 0, "Expired");
      require(_expiry < _vault.expiry(), "Can only set expiry nearer");
      _vault.setExpiry(_expiry);
    }
    
    
    function depositOnBehalf(VaultV0 _vault, address _onBehalfOf, uint _amt) external {
      require(msg.sender == teamKey, "Not teamKey");
      IERC20 COLLAT = IERC20(_vault.COLLAT_ADDRESS()); 
      COLLAT.transferFrom(msg.sender, address(this), _amt);
      COLLAT.approve(address(_vault), _amt);
      _vault.depositOnBehalf(_onBehalfOf, _amt);
      require(COLLAT.balanceOf(address(this)) == 0, "Balance Left On OwnerProxy");
    }
    
    function setMaxCap(VaultV0 _vault, uint _maxCap) external {
      require(msg.sender == teamKey, "Not teamKey");
      _vault.setMaxCap(_maxCap);
    }   
    
    function setAllowInteraction(VaultV0 _vault, bool _flag) external {
      require(msg.sender == teamKey, "Not teamKey");
      require(_vault.expiry() == 0, "Not Expired");
      _vault.setAllowInteraction(_flag);
    }

    function setMaker(VaultV0 _vault, address _newMaker) external {
      if (msg.sender == multisigBeta) {  
        _vault.setMaker(_newMaker);
      } else if (msg.sender == teamKey) {
        require(_vault.expiry() == 0, "Not Expired");
        _vault.setMaker(_newMaker);
      } else {
       revert("!teamKey,!musigBeta");
      }
    }    
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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

import "IERC20.sol";

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

import "IERC20.sol";
import "Address.sol";

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function phaseId() external view returns (uint16);
  function latestRound() external view returns (uint256);
  function latestAnswer() external view returns (uint256);
  function latestTimestamp() external view returns (uint256);

}

interface HistoricalPriceConsumerV3 {
    function getHistoricalPrice(uint80 roundId) external view returns (int256); 
    function getLatestPrice() external view returns (int);
    function getPriceAfterTimestamp(uint timeStamp) external view returns (int256);
    function findBlockSamePhase(uint timeStamp, uint80 phaseOffset, uint80 start, uint80 mid, uint80 end) external view returns (uint80);
    function getLatestPriceX1e6() external view returns (int);
}



contract HistoricalPriceConsumerV3_1 {

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331

     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
     
    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(AggregatorV3Interface priceFeed, uint80 roundId) public view returns (int256) {
        (
            uint80 id, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function getPriceAfterTimestamp(AggregatorV3Interface priceFeed, uint timeStamp) public view returns (int256) {
        uint80 end = uint80(priceFeed.latestRound()) % (priceFeed.phaseId() * 2 ** 64);
        uint80 phaseOffset = priceFeed.phaseId() * 2 ** 64;        
        uint80 roundID = findBlockSamePhase(priceFeed, timeStamp, phaseOffset, 1, (end + 1) / 2, end );
        return getHistoricalPrice(priceFeed, roundID);
    }

    /*
      Binary search within current phase
      
      Failure modes:
      1. Block wanted is at start of new phase
      2. Too many incomplete rounds 
    */
    function findBlockSamePhase(AggregatorV3Interface priceFeed, uint timeStamp, uint80 phaseOffset, uint80 start, uint80 mid, uint80 end) public view returns (uint80) {    
        require(end >= mid + 1, "Block not found");

        ( , , , uint timeStamp_2, ) = priceFeed.getRoundData(mid + phaseOffset);
        ( , , , uint timeStamp_3, ) = priceFeed.getRoundData(end + phaseOffset);
        if (timeStamp_2 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid + 1, end);
        if (timeStamp_3 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid, end - 1);

        if (end == mid + 1) {
          if ((timeStamp_3 >= timeStamp) && ( timeStamp_2 < timeStamp )) {
            return phaseOffset + end;
          }            
        }
        
        require(timeStamp_3 >= timeStamp, "Block not found");                
        require(end > start             , "Block not found");                
        if (timeStamp_2 >= timeStamp) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, (start+mid) / 2, mid); 
        else                          return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, mid,   (mid + end) / 2, end);            
    }
    
    // Chainlink returns 8 decimal place, this normalises it to 1e6 convention in this contract
    // Note: Chainlink prices are signed
    function getLatestPriceX1e6(AggregatorV3Interface priceFeed) public view returns (int) {
      return getLatestPrice(priceFeed) / 1e2;
    }
}



contract HistoricalPriceConsumerV3_RATIO {

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     **/
     
    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    
     /* In situation where Chainlink only offers a ratio pair, e.g. LUNA/ETH, we use HistoricalPriceConsumerV3_RATIO, which exposes the same API but also routes */
     AggregatorV3Interface ratioQuote;
    
     constructor(address baseRatioAggregator) {
        ratioQuote = AggregatorV3Interface(baseRatioAggregator);
    }
     
    function getQuotePrice() public view returns (int256) {
      (
            , 
            int price,
            ,
            uint timeStamp,
        ) = ratioQuote.latestRoundData();
        require(timeStamp != 0, "RATIO_ORACLE_NOT_READY");
        return price;   
    }
        
    function getQuoteMantissa() internal view returns (int256) {
      return int256(10 ** ratioQuote.decimals());
    }
    
    // This returns RATIO in TERMS of QUOTE!
    function getHistoricalPrice(AggregatorV3Interface priceFeed, uint80 roundId) public view returns (int256) {
        (
            , 
            int price,
            ,
            uint timeStamp,
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    // This returns PRICE in TERMS of QUOTE!
    function getLatestPrice(AggregatorV3Interface priceFeed) public view returns (int) {
        (
            , 
            int price,
            ,
            uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp != 0, "PRICEFEED_TIMESTAMP_NOT_READY");
        return (10 ** 8) * price * getQuotePrice() / getQuoteMantissa() / int256(10 ** priceFeed.decimals());
    }
    
    function findPriceAfterTimestamp(AggregatorV3Interface priceFeed, uint timeStamp) public view returns (int256) {
        uint80 end = uint80(priceFeed.latestRound()) % (priceFeed.phaseId() * 2 ** 64);
        uint80 phaseOffset = priceFeed.phaseId() * 2 ** 64;        
        uint80 roundID = findBlockSamePhase(priceFeed, timeStamp, phaseOffset, 1, (end + 1) / 2, end );
        return getHistoricalPrice(priceFeed, roundID);
    }
    
    // Standard interface
    function getPriceAfterTimestamp(AggregatorV3Interface priceFeed, uint timeStamp) public view returns (int256) {
       return (10 ** 8) * findPriceAfterTimestamp(priceFeed, timeStamp) * findPriceAfterTimestamp(ratioQuote, timeStamp) / getQuoteMantissa() / int256(10 ** priceFeed.decimals());
    }

    /*
      Binary search within current phase
      
      Failure modes:
      1. Block wanted is at start of new phase
      2. Too many incomplete rounds 
    */
    function findBlockSamePhase(AggregatorV3Interface priceFeed, uint timeStamp, uint80 phaseOffset, uint80 start, uint80 mid, uint80 end) public view returns (uint80) {    
        require(end >= mid + 1, "Block not found");

        ( , , , uint timeStamp_2, ) = priceFeed.getRoundData(mid + phaseOffset);
        ( , , , uint timeStamp_3, ) = priceFeed.getRoundData(end + phaseOffset);
        if (timeStamp_2 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid + 1, end);
        if (timeStamp_3 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid, end - 1);

        if (end == mid + 1) {
          if ((timeStamp_3 >= timeStamp) && ( timeStamp_2 < timeStamp )) {
            return phaseOffset + end;
          }            
        }
        
        require(timeStamp_3 >= timeStamp, "Block not found");                
        require(end > start             , "Block not found");                
        if (timeStamp_2 >= timeStamp) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, (start+mid) / 2, mid); 
        else                          return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, mid,   (mid + end) / 2, end);            
    }
    
    // Chainlink returns 8 decimal place, this normalises it to 1e6 convention in this contract
    // Note: Chainlink prices are signed

    function getLatestPriceX1e6(AggregatorV3Interface priceFeed) public view returns (int) {
      return getLatestPrice(priceFeed) / 1e2;
    }
}

// For tokens without chainlink, this would act as temporary stand-in until there's a onchain pricefeed
// Each asset type will own price set by a oracle
// All functions will ignore address provided in call, since price feed address is not available yet
 
contract HistoricalPriceConsumerV3_FIXEDPRICE {

    int     public priceX1e6;
    uint    public priceTime;
    address public ORACLE;

    constructor() {
        ORACLE = msg.sender;
    }

    function setPrice(int _price) external {
        require(ORACLE == msg.sender, "NOT ORACLE");
        priceX1e6 = _price;
        priceTime = block.timestamp;
    }
    
    function setOracle(address _oracle) external {
        require(ORACLE == msg.sender, "NOT ORACLE");
        ORACLE = _oracle;
    }

    function getLatestPrice(address priceFeed) public view returns (int) {
        return priceX1e6;
    }
    
    function getPriceAfterTimestamp(address priceFeed, uint timeStamp) public view returns (int256) {
        if (timeStamp >= priceTime) return priceX1e6;  
        revert("Block not found"); 
    }

    // Chainlink returns 8 decimal place, this temporary oracle stores it as 1e6
    // Note: Chainlink prices are signed int
    function getLatestPriceX1e6(address priceFeed) public view returns (int) {
      return priceX1e6;
    }
}