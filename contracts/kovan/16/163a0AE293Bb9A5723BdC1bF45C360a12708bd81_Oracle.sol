// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Ownable } from "./roles/Ownable.sol";
import { IOracle } from "./interfaces/IOracle.sol";


interface IFeed
{
  function latestAnswer () external view returns (int256);
}

contract Oracle is IOracle, Ownable
{
  address private constant _DAI = address(0xC22780731758d1E309B9774009027D2Eb325F66f);
  address private constant _WETH = address(0xd67AB1D41c1bf29B0F8a2284B26f395B40d9F6B6);

  uint256 private constant _DECIMALS = 1e18;

  mapping(address => address) private _ETHFeed;
  mapping(address => address) private _USDFeed;
  mapping(address => uint256) private _decimal;


  constructor ()
  {
    address BNT = 0xfae6315a60964c3C6647D7B4DD426e9953129468;
    address COMP = 0x6eEbF3069a5dcd836C127fd55E2C33EF37397722;
    address LINK = 0xC5e2569C401698f701610682988953ac924A010D;
    address USDC = 0x10fa2511aB6945F48Cc637A5d4817a24c3688e9b;
    address WBTC = 0x27EA102C03f356309A2fc59D9eCEA64502967790;

    
    _decimal[BNT] = ERC20(BNT).decimals();
    _decimal[COMP] = ERC20(COMP).decimals();
    _decimal[LINK] = ERC20(LINK).decimals();
    _decimal[USDC] = ERC20(USDC).decimals();
    _decimal[WBTC] = ERC20(WBTC).decimals();
    _decimal[_DAI] = ERC20(_DAI).decimals();
    _decimal[_WETH] = ERC20(_WETH).decimals();
    
    _ETHFeed[_DAI] = address(0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541);
    _ETHFeed[LINK] = address(0x3Af8C569ab77af5230596Acf0E8c2F9351d24C38);
    _ETHFeed[USDC] = address(0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838);
    _ETHFeed[WBTC] = address(0xF7904a295A029a3aBDFFB6F12755974a958C7C25);

    _USDFeed[BNT] = address(0x8e67A0CFfbbF6A346ce87DFe06daE2dc782b3219);
    _USDFeed[COMP] = address(0xECF93D14d25E02bA2C13698eeDca9aA98348EFb6);
    _USDFeed[_WETH] = address(0x9326BFA02ADD2366b30bacB125260Af641031331);
  }

  function getFeed (address token) external view returns (address, bool)
  {
    bool hasEthFeed = _ETHFeed[token] != address(0);

    return (hasEthFeed ? _ETHFeed[token] : _USDFeed[token], hasEthFeed);
  }

  function setFeeds (address[] calldata tokens, address[] calldata feeds, bool isUSDFeeds) external onlyOwner
  {
    require(tokens.length == feeds.length, "!=");

    if (isUSDFeeds)
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _USDFeed[token] = feeds[i];
        _decimal[token] = ERC20(token).decimals();
      }
    }
    else
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _ETHFeed[token] = feeds[i];
        _decimal[token] = ERC20(token).decimals();
      }
    }
  }


  function _uintify (int256 rate) private pure returns (uint256)
  {
    require(rate > 0, "feed err");


    return uint256(rate);
  }

  function _calcTokenETHRate (address token) private view returns (uint256)
  {
    if (_ETHFeed[token] != address(0))
    {
      return _uintify(IFeed(_ETHFeed[token]).latestAnswer());
    }
    else if (_USDFeed[token] != address(0))
    {
      return ( _uintify(IFeed(_USDFeed[token]).latestAnswer()) * _DECIMALS ) / _uintify(IFeed(_USDFeed[_WETH]).latestAnswer());
    }
    else
    {
      return _uintify(0);
    }
  }

  function getRate (address from, address to) public view override returns (uint256)
  {
    if (from == to && to == _DAI)
    {
      return _DECIMALS;
    }


    // fromToken rate / destToken rate
    return ((from == _WETH ? _DECIMALS : _calcTokenETHRate(from)) * _DECIMALS) / (to == _WETH ? _DECIMALS : _calcTokenETHRate(to));
  }

  function _calcDestQty (uint256 srcQty, address from, address to, uint256 rate) private view returns (uint256)
  {
    /*uint256 srcDecimals = ERC20(from).decimals();
    uint256 destDecimals = ERC20(to).decimals();*/
    uint256 srcDecimals = _decimal[from];
    uint256 destDecimals = _decimal[to];


    if (destDecimals >= srcDecimals)
    {
      return (srcQty * rate * (10 ** (destDecimals - srcDecimals))) / _DECIMALS;
    }
    else
    {
      return (srcQty * rate) / (_DECIMALS * (10 ** (srcDecimals - destDecimals)));
    }
  }

  function _calcDestQty2 (uint256 srcQty, address from, address to, uint256 rate) private view returns (uint256)
  {
    /*uint256 srcDecimals = ERC20(from).decimals();
    uint256 destDecimals = ERC20(to).decimals();
    uint256 srcDecimals = _decimal[from];
    uint256 destDecimals = _decimal[to];*/


    if (_decimal[to] >= _decimal[from])
    {
      return (srcQty * rate * (10 ** (_decimal[to] - _decimal[from]))) / _DECIMALS;
    }
    else
    {
      return (srcQty * rate) / (_DECIMALS * (10 ** (_decimal[from] - _decimal[to])));
    }
  }

  function convertFromUSD (address to, uint256 amount) external view override returns (uint256)
  {
    return _calcDestQty(amount, _DAI, to, getRate(_DAI, to));
  }

  function convertToUSD (address from, uint256 amount) external view override returns (uint256)
  {
    return _calcDestQty(amount, from, _DAI, getRate(from, _DAI));
  }

  function convert (address from, address to, uint256 amount) external view override returns (uint256)
  {
    return _calcDestQty(amount, from, to, getRate(from, to));
  }

  function convert2 (address from, address to, uint256 amount) external view returns (uint256)
  {
    return _calcDestQty2(amount, from, to, getRate(from, to));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IOracle
{
  function getRate (address from, address to) external view returns (uint256);

  function convertFromUSD (address to, uint256 amount) external view returns (uint256);

  function convertToUSD (address from, uint256 amount) external view returns (uint256);

  function convert (address from, address to, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


contract Ownable
{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  modifier onlyOwner ()
  {
    require(msg.sender == _owner, "!owner");
    _;
  }

  constructor ()
  {
    _owner = msg.sender;

    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner () public view returns (address)
  {
    return _owner;
  }

  function renounceOwnership () public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));

    _owner = address(0);
  }

  function transferOwnership (address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addr");

    emit OwnershipTransferred(_owner, newOwner);

    _owner = newOwner;
  }
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