/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC20.sol";

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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC20.sol";
////import "./extensions/IERC20Metadata.sol";
////import "../../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8;

////import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


library Utils {
  struct TokenInfo {
    string name;
    string symbol;
    address _address;
    uint decimals;
    uint totalSupply;
  }

  address constant ZERO_ADDRESS = address(0);
  function calculateFee1000 (uint amount, uint pct) internal pure returns(uint) {
    uint fee = ((amount * pct) / (1000 - pct)) + 1;
    return fee;
  }

  function calculateFee10000 (uint amount, uint pct) internal pure returns(uint) {
    uint fee = ((amount * pct) / (10000 - pct)) + 1;
    return fee;
  }

  function _toLower(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
          // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
          bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }
  function _toUpper(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 112)) {
          // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) - 32);
      } else {
          bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  function _stringCompare (string memory str0, string memory str1) internal pure returns(bool) {
    return keccak256(abi.encodePacked(str0)) == keccak256(abi.encodePacked(str1));
  }
  function _stringConcat (string memory str0, string memory str1) internal pure returns(string memory) {
    return string(abi.encodePacked(str0, str1));

  }
  function _stringToBytes32(string memory source) public pure returns (bytes32 result) {
    // require(bytes(source).length <= 32); // causes error
    // but string have to be max 32 chars
    // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
    // http://solidity.readthedocs.io/en/latest/assembly.html
    assembly {
      result := mload(add(source, 32))
    }
  }//

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
  }
  function balanceOf (address _user) internal view returns(uint balance) {
    balance = address(_user).balance;
  }
  function balanceOf (address _user, address _token) internal view returns(uint balance) {
    balance = ERC20(_token).balanceOf(_user);
  }
  function _getTokenInfo (ERC20 _token) internal view returns(TokenInfo memory token) {
    token = TokenInfo(_token.name(), _token.symbol(), address(_token), _token.decimals(), _token.totalSupply());
    return token;
  }
  function getTokenInfo (ERC20[] memory _tokens) internal view returns(TokenInfo[] memory tokens) {
    uint tokensLen = _tokens.length;
    tokens = new TokenInfo[](tokensLen);
    ERC20 token;
    uint i;
    for (i = 0; i < tokensLen; i++) {
      token = _tokens[i];
      tokens[i] = TokenInfo(token.name(), token.symbol(), address(token), token.decimals(), token.totalSupply());
    }
  }
  function getMultiBalances (address[] memory _tokens) internal view returns(TokenInfo[] memory tokens, uint[] memory balances, uint ETH_BALANCE) {
    tokens = new TokenInfo[](_tokens.length);
    balances = new uint[](_tokens.length);
    address _user = msg.sender;
    for(uint i = 0; i < _tokens.length; i++) {
      tokens[i] = _getTokenInfo(ERC20(_tokens[i]));
      balances[i] = balanceOf(_user, _tokens[i]);
    }

    ETH_BALANCE = balanceOf(_user);
  }
  function getMultiBalances (address[] memory _tokens, address _user) internal view returns(
    TokenInfo[] memory tokens,
    uint[] memory balances,
    uint ETH_BALANCE
  ) {
    tokens = new TokenInfo[](_tokens.length);
    balances = new uint[](_tokens.length);

    for(uint i = 0; i < _tokens.length; i++) {
      tokens[i] = _getTokenInfo(ERC20(_tokens[i]));
      balances[i] = balanceOf(_user, _tokens[i]);
    }

    ETH_BALANCE = balanceOf(_user);
  }
}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.4;


/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC2612 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be `address(0)`.
     * - `spender` cannot be `address(0)`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
    
    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by EIP712.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// ////import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021

////import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// ////import "./IERC2612.sol";
// ////import "./IERC3156FlashLender.sol";

/// @dev Wrapped Ether v10 (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
interface IWETH10 is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}

interface IWETH is IWETH10 {}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity ^0.8;

////import "./interfaces/IWETH.sol";
////import "./libraries/Utils.sol";
////import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Common is Context {
  IWETH public WETH;
  
  struct AuthUser {
    address _address;
    string[] roles;
  }
  address owner;
  // uint unlocked = 1;
  AuthUser[] authorizedUsers;
  string[] roles;
  constructor (address _weth) {
    WETH = IWETH(_weth);
    this.addRole('root');
    this.addRole('admin');
  }

  event UpdatedOwner(address indexed oldOwner, address indexed newOwner);
  // modifier lock() {
  //     require(unlocked == 1, 'FraktalFinancial: LOCKED');
  //     unlocked = 0;
  //     _;
  //     unlocked = 1;
  // }

  modifier onlyOwner () {
    require(msg.sender == owner, 'Unauthorized User');
    _;
  }

  modifier onlyAuthorized () {
    bool isAuthorized = false;
    uint i;

    for(i = 0; i < authorizedUsers.length; i++) {
      if (msg.sender == authorizedUsers[i]._address) {
        isAuthorized = true;
        continue;
      }
    }
    require(isAuthorized, "Unauthoized Access");
    _;
  }
  modifier onlyHasRole(string memory _role) {
    bool isOwner = (msg.sender == owner);
    bool isAuthorized = isOwner;
    if (!isAuthorized) {

      for(uint i = 0; i < authorizedUsers.length; i++) {
        AuthUser memory user = authorizedUsers[i];
        for(uint n = 0; n < user.roles.length; n++) {
          string memory  role = user.roles[n];
          if (Utils._stringCompare(_role, role)) {
            isAuthorized = true;
            continue;
          }
        }
      }
    }
    require(isAuthorized || msg.sender == owner, 'Unauthorized User');
    _;
  }

  function addRole(string memory role) external onlyAuthorized {
    bool hasRole = false;
    for (uint i = 0; i < roles.length; i++) {
      if (Utils._stringCompare(role, roles[i])) {
        hasRole = true;
        continue;
      }
    }
    require(!hasRole, 'Role already exists');
    roles.push(role);
  }
  function addAuthorizedUser (address user, string[] memory _roles) external onlyHasRole('root') {
    bool hasUser;
    for (uint i = 0; i < authorizedUsers.length; i++) {
      if (authorizedUsers[i]._address == user) {
        hasUser = true;
        continue;
      }
    }
    require(!hasUser, "User already exitsts");
    authorizedUsers.push(AuthUser(user, _roles));
    
  }
  function updateOwner (address newOwner) external onlyOwner returns(bool success){
    require(owner != newOwner, "INVALID_OWNER: NO_SELF_UPDATE");
    owner = newOwner;
    emit UpdatedOwner(owner, newOwner);
  }
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity >=0.6.12;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    // using BoringERC20 for IERC20;
    function onBananaReward(uint256 pid, address user, address recipient, uint256 bananaAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 bananaAmount) external view returns (IERC20[] memory, uint256[] memory);
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity ^0.8;

////import "./libraries/Utils.sol";
////import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
////import "./Common.sol";

contract DataStore {
  event AddedContract (string indexed _name, address indexed _address, uint indexed _networkId, uint category);
  event AddedCategory (uint indexed _id, string _category);
  event AddedToken (string indexed symbol, address indexed _address, uint decimals);
  
  struct Contract {
    string _name;
    address _address;
    uint _networkId;
    uint categoryId;
  }

  Utils.TokenInfo[] tokens;

  struct Exchange {
    string _name;
    Contract[] contracts;
  }
  string[] public categories;
  Contract[] public contracts;

  function addContract (string memory _name, address _address, uint _networkId, uint categoryId) external {
    contracts.push(Contract(_name, _address, _networkId, categoryId));
    emit AddedContract(_name, _address, _networkId, categoryId);

  }

  function addCategory (string memory category) external returns (bool success) {
    if (categoryExists(category)) {
      success = false;
      return success;
    }
    uint catId = categories.length;
    categories.push(category);
    emit AddedCategory(catId, category);
    success = true;
    return true;

  }

  function categoryExists (string memory category) internal view returns(bool hasCategory) {
    hasCategory = false;
    if (categories.length == 0) return hasCategory;
    for (uint i = 0; i < categories.length; i++) {
      if (Utils._stringCompare(Utils._toLower(categories[i]), Utils._toLower(category))) {
        hasCategory = true;
        continue;
      }
    }
    return hasCategory;
  }

  function findContractsByCategoryId (uint categoryId) external view returns(Contract[] memory _contracts){
    uint _contractCount;
    uint _cID;

    for (uint i = 0;i < contracts.length;i++) {
      if (categoryId == contracts[i].categoryId) {
        _contractCount++;
      }
    }
    if (_contractCount == 0) return _contracts;
    _contracts = new Contract[](_contractCount);

    for (uint i = 0;i < contracts.length;i++) {
      if (categoryId == contracts[i].categoryId) {
        // _contractCount++;
        _contracts[_cID] = contracts[i];
        _cID++;
      }
    }
    return _contracts;
  }
  function hasToken (address _token) internal view returns(bool _hasToken) {
    uint tokenLen = tokens.length;
    uint i;
    for(i = 0; i < tokenLen; i++) {
      if (_token == tokens[i]._address) {
        _hasToken = true;
        return _hasToken;
      }
    }
    return _hasToken;

  }
  function addTokens (ERC20[] memory _token) external {
    Utils.TokenInfo[] memory info = Utils.getTokenInfo(_token);
    for (uint i = 0; i < info.length; i++) {
      if (!hasToken(address(_token[i]))) {
        tokens.push(info[i]);
        emit AddedToken(info[i].symbol, info[i]._address, info[i].decimals);
      }
    }
  }
}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity ^0.8;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "./IRewarder.sol";
interface IFarmer {
  struct UserInfo {
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
  }


  // /// @notice Info of each MCV2 pool.
  // /// `allocPoint` The amount of allocation points assigned to the pool.
  // /// Also known as the amount of BANANA to distribute per block.
  // struct PoolInfo {
  //   uint128 accSushiPerShare;
  //   uint64 lastRewardTime;
  //   uint64 allocPoint;
  // }

    // function poolInfo(uint256 pid) external view returns (IFarmer.PoolInfo memory);
  // function poolInfo (uint) external view returns(PoolInfo memory);

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

  function massUpdatePools(uint256[] calldata pids) external;
  function userInfo (uint, address) external view returns(UserInfo memory);
  function deposit(uint256 pid, uint256 amount, address to) external;
  function withdraw(uint256 pid, uint256 amount, address to) external;
  function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
  function emergencyWithdraw(uint256 pid, address to) external;
  function lpToken (uint) external view returns(IERC20);
  function totalAllocPoint() external view returns(uint256);

  function poolLength() external view returns (uint256 pools);

  
}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity ^0.8;

////import "../interfaces/farmer/IFarmer.sol";
////import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "../libraries/Utils.sol";
////import "../DataStore.sol";
////import "../Common.sol";

abstract contract Farmer is Common, IFarmer, ERC20 {

  DataStore dataStore;
  constructor (DataStore _dataStore) {
    owner = msg.sender;
    dataStore = _dataStore;
  }
  event Log(string message);
  event Log(string message, uint val);
  event LogBytes(bytes message);

  event ShowBalance(address user, address token, uint balance);
  function getPoolLength (address _farmer) external view returns(uint poolLen) {
    IFarmer farmer = IFarmer(_farmer);
    poolLen = farmer.poolLength();
    return poolLen;
  }
  function getUserInfo (address _farmer, address user, uint _farmId) external view returns (UserInfo memory farm) {
    IFarmer.UserInfo memory info = IFarmer(_farmer).userInfo(_farmId, user);
    return info;
  }
  function _sendTokenFromContract (address  _token, uint _amount, address payable _to) internal returns(bool success) {
    require(Utils.balanceOf(address(this) , _token) >= _amount, "Amount exceeds funds available");
    try IERC20(_token).transfer(_to, _amount) {
      success = true;
    } catch Error(string memory response) {
      emit Log(response);
      success = false;
    } catch {
      success = false;
    }
    return success;
  }
  function sendTokenFromContract(address _token, uint _amount, address payable _to) internal returns(bool success) {
    require(msg.sender == owner, "Resticted Method...");
    return _sendTokenFromContract(_token, _amount, _to);
  }

  function sendTokensFromContract (address[] memory tokens, uint[] memory amounts, address _to) external returns (bool[] memory success) {
    require(msg.sender == owner, "Resticted Method...");
    require(tokens.length == amounts.length);
    for(uint i = 0; i < tokens.length; i++) {
      success[i] = _sendTokenFromContract(tokens[i], amounts[i], payable(_to));
    }
    return success;
  }
  function destroy() external {
    require(msg.sender == owner, 'UNAUTHORIZED');
    selfdestruct(payable(owner));
  }

}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity >=0.6.12;

// ////import "../libraries/Boring.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "./IFarmer.sol";

interface ISushiMiniChef is IFarmer {
    // using BoringERC20 for IERC20;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);

}





/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity ^0.8;

contract FarmData {
  event LogError(string _error);
  event LogBytes(bytes _error);

  event AddedFarmer(string indexed _name, address indexed _address, string indexed strat);

  enum Strategies { HoneyFarm, MasterChef, MiniApeV2, Goose }

  struct UserFarm {
    address farmer;
    uint farmId;
    uint pending;
  }

  // isVault == single token

  struct FarmInfo {
    string _name;
    address _farmer;
    string strat;
    bool isVault;
    address[] tokens;
    address[] rewardToken;

  }

  struct FarmerInfo {
    string name;
    address _address;
    string strat;
  }
  FarmerInfo[] farmers;
  uint farmersLen;


  function farmerExists (address _address) internal view returns (bool success) {
    uint i;
    success = false;
    for (i = 0; i < farmersLen; i++) {
      if (farmers[i]._address == _address) {
        success = true;
        continue;
      }
    }
    return success;
  }
  function addFarmer (string memory _name, address _address, string memory strat) external {
    require(!farmerExists(_address), "Farmer already added...");
    farmers.push(
      FarmerInfo(_name, _address, strat)
    );
    emit AddedFarmer(_name, _address, strat);
    farmersLen++;
  }


  
}





/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity >=0.6.12;

// ////import "../libraries/Boring.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "./IFarmer.sol";

interface IMiniApeV2  is IFarmer {
  // using BoringMath for uint256;
  // using BoringMath128 for uint128;
  // using BoringERC20 for IERC20;
  // using SignedSafeMath for int256;

  /// @notice Info of each MCV2 user.
  /// `amount` LP token amount the user has provided.
  /// `rewardDebt` The amount of BANANA entitled to the user.
  event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
  event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
  event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accBananaPerShare);
  event LogBananaPerSecond(uint256 bananaPerSecond);

  function BANANA () external view returns(IERC20);
  
  function rewarder (uint) external view returns(IRewarder);
  function bananaPerSecond () external view returns(uint256);
  function ACC_BANANA_PRECISION() external view returns(uint256);
  function pendingBanana(uint256 _pid, address _user) external view returns (uint256 pending);
  function harvest(uint256 pid, address to) external;

}





/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
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

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  )
    external
    returns (uint[] memory amounts);
}

interface IUniswapV2Factory  {

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity ^0.8;

////import "../farmer/FarmData.sol";
////import "../interfaces/farmer/ISushiMiniChef.sol";
////import "../farmer/Farmer.sol";

abstract contract StrategySushi is Farmer {
  function getUserFarms (address _farmer, address user) external view returns(FarmData.UserFarm[] memory farms){
    ISushiMiniChef farmer = ISushiMiniChef(_farmer);
    uint _poolLen = this.getPoolLength(_farmer);
    uint i;
    uint _userFarmCount = this.getUserFarmCount(_farmer, user);
    farms = new FarmData.UserFarm[](_userFarmCount);

    for (i = 0; i < _poolLen; i++) {
      uint pendingSushi = this.getPendingSushi(_farmer, user, i);
      if (pendingSushi > 0) farms[i] = FarmData.UserFarm(_farmer, i, pendingSushi);
    }
    return farms;
  }
  function getPendingSushi (address _farmer, address user, uint _farmId) external view returns(uint) {
    ISushiMiniChef farmer = ISushiMiniChef(_farmer);
    return farmer.pendingSushi(_farmId, user);
  }
  function getUserFarmCount (address _farmer, address user) external view returns(uint) {
    ISushiMiniChef farmer = ISushiMiniChef(_farmer);
    uint _poolLen = this.getPoolLength(_farmer);
    uint i;
    uint _userFarmCount;

    for (i = 0; i < _poolLen; i++) {
      uint pendingSushi = this.getPendingSushi(_farmer, user, i);
      if (pendingSushi > 0) _userFarmCount++;
    }
    return _userFarmCount;
  }
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
pragma solidity ^0.8;

////import "../farmer/FarmData.sol";
////import "../interfaces/farmer/IMiniApeV2.sol";
////import "../farmer/Farmer.sol";

abstract contract StrategyApe is Farmer {
  function getUserFarms (address _farmer, address user) external view returns(FarmData.UserFarm[] memory farms){
    IMiniApeV2 farmer = IMiniApeV2(_farmer);
    uint _poolLen = this.getPoolLength(_farmer);
    uint i;
    uint _userFarmCount = this.getUserFarmCount(_farmer, user);
    farms = new FarmData.UserFarm[](_userFarmCount);

    for (i = 0; i < _poolLen; i++) {
      uint pendingBanana = this.getPendingBanana(_farmer, i, user);
      if (pendingBanana > 0) farms[i] = FarmData.UserFarm(_farmer, i, pendingBanana);
    }
  }
  function getPendingBanana (address _farmer, uint _farm, address user) external view returns(uint) {
    IMiniApeV2 farmer = IMiniApeV2(_farmer);
    return farmer.pendingBanana(_farm, user);
  }
  function getUserFarmCount (address _farmer, address user) external view returns(uint) {
    IMiniApeV2 farmer = IMiniApeV2(_farmer);
    uint _poolLen = this.getPoolLength(_farmer);
    uint i;
    uint _userFarmCount;

    for (i = 0; i < _poolLen; i++) {
      uint pendingBanana = this.getPendingBanana(_farmer, i, user);
      if (pendingBanana > 0) _userFarmCount++;
    }
    return _userFarmCount;
  }
}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8;

////import "hardhat/console.sol";
////import "./libraries/Utils.sol";
////import "./interfaces/IWETH.sol";
////import "./interfaces/IUniswapV2.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UniswapProtocolHelper {
  using SafeMath for uint;
  struct ResevresWithTokens {
    address factory;
    address pairAddress;
    uint reserve0;
    uint reserve1;
    uint timestamp;
    address token0;
    address token1;
  }

  struct PairInfo {
    address factory;
    address pairAddress;
    address token0;
    address token1;
    uint reserve0;
    uint reserve1;
    uint block;
    uint timestamp;
    uint price0CumulativeLast;
    uint price1CumulativeLast;
    uint totalSupply;
  }

  struct TokenInfo {
    string name;
    string symbol;
    address _address;
    uint decimals;
    uint totalSupply;
  }

  IWETH public WETH;
  address public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

  constructor (address _wmatic) {
    updateWethAddress(_wmatic);
  }

  receive () external payable {}
  fallback () external payable {}
  
  function walletBalance(address _user) external view returns(uint balance) {
    balance = Utils.balanceOf(_user);
  }
  function tokenBalance (address _user, address token) external view returns(uint balance) {
    balance = Utils.balanceOf(_user, address(token));
  }

  function updateWethAddress (address _wmatic) public {
    WETH = IWETH(_wmatic);
  }

  function weth () external view returns (address) {
    return address(WETH);
  }
  function getFactoryAddress (IUniswapV2Router02 router) public pure returns(address) {
    return router.factory();
  }
  function getAllPairsLength (IUniswapV2Factory factory) public view returns(uint) {
    return factory.allPairsLength();
  }
  function getReservesByPairs(IUniswapV2Pair[] calldata _pairs) external view returns (ResevresWithTokens[] memory result) {
    result = new ResevresWithTokens[](_pairs.length);
    for (uint i = 0; i < _pairs.length; i++) {

        (
          uint reserve0,
          uint reserve1,
          uint timestamp
          
        ) = _pairs[i].getReserves();

        result[i] = ResevresWithTokens(
          _pairs[i].factory(),
          address(_pairs[i]),
          reserve0,
          reserve1,
          timestamp,
          _pairs[i].token0(),
          _pairs[i].token1()
        );

        console.log("PAIR ADDRESS: %s", address(_pairs[i]));
        console.log("FACTORY: %s", _pairs[i].factory());

    }
    return result;
  }
  function _getPairInfo (IUniswapV2Pair pair) public view returns (PairInfo memory info) {
    (
      uint reserve0,
      uint reserve1,
      uint timestamp
    ) = pair.getReserves();

    info = PairInfo (
      pair.factory(),
      address(pair),
      pair.token0(),
      pair.token1(),
      reserve0,
      reserve1,
      block.number,
      timestamp,
      pair.price0CumulativeLast(),
      pair.price1CumulativeLast(),
      pair.totalSupply()
    );
  }
  function getPairInfo (IUniswapV2Factory factory, address token0, address token1) public view returns (PairInfo memory info) {
    IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0,token1));

    return _getPairInfo(pair);
  }
  function getMultiPairsInfo (IUniswapV2Pair[] memory pairs) public view returns (PairInfo[] memory info) {
    uint pairLen = pairs.length;
    uint i;
    info = new PairInfo[](pairLen);
    for(i = 0; i < pairLen; i++) {
      info[i] = _getPairInfo(pairs[i]);
    }
  }
  function getPairsByIndexRange(IUniswapV2Factory _uniswapFactory, uint256 _start, uint256 _stop) external view returns (address[3][] memory)  {
    uint256 _allPairsLength = _uniswapFactory.allPairsLength();
    if (_stop > _allPairsLength) {
      _stop = _allPairsLength;
    }
    require(_stop >= _start, "start cannot be higher than stop");
    uint256 _qty = _stop - _start;
    address[3][] memory result = new address[3][](_qty);
    for (uint i = 0; i < _qty; i++) {
      IUniswapV2Pair _uniswapPair = IUniswapV2Pair(_uniswapFactory.allPairs(_start + i));
      result[i][0] = _uniswapPair.token0();
      result[i][1] = _uniswapPair.token1();
      result[i][2] = address(_uniswapPair);
    }
    return result;
  }

  function getPairAddress (IUniswapV2Factory factory, address token0, address token1) public view returns(address) {
    return factory.getPair(token0, token1);
  }
  
  function getReserves(IUniswapV2Router02 router, address token0, address token1) public view returns (uint112, uint112, uint32){
    address pairAddress = getPairAddress(IUniswapV2Factory(router.factory()), token0, token1);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    return pair.getReserves();
  }

  function getReservesWithTokens(IUniswapV2Router02 router, address token0, address token1) public view returns (
    address,
    address,
    uint112, 
    uint112, 
    uint32
  ){
    address pairAddress = getPairAddress(IUniswapV2Factory(router.factory()), token0, token1);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockNum
    ) = pair.getReserves();

    return (
      pair.token0(),
      pair.token1(),
      reserve0,
      reserve1,
      blockNum
    );
  }

  function getAmountsOut(IUniswapV2Router02 router, uint amountIn, address[] memory path) external view returns (uint[] memory amounts) {
    return router.getAmountsOut(amountIn, path);
  }

  function getAmountsIn(IUniswapV2Router02 _router, uint amountOut, address[] memory path) external view returns (uint[] memory amounts) {
    // IUniswapV2Router02 router = IUniswapV2Router02(_router);
    return _router.getAmountsIn(amountOut, path);
  }
  function swap(
    IUniswapV2Router02 router,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address payable  _to
  ) public payable returns(uint[] memory amounts) {

    address[] memory path;
    if (_tokenIn == address(WETH) || _tokenOut == address(WETH)) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = address(WETH);
      path[2] = _tokenOut;
    }
    IERC20 tokenIn = IERC20(_tokenIn);
    IERC20 tokenOut = IERC20(_tokenOut);
    
    if (msg.value >= _amountIn && _tokenIn == address(0) && (msg.sender != address(this))) {
      WETH.deposit{value: msg.value}();
    } 
    else {
      require(tokenIn.transferFrom(msg.sender, address(this), _amountIn), 'Error Transferring [LINE: 246]');
    }
    tokenIn.approve(address(router), _amountIn);
    uint amounts;

    try router.swapExactTokensForTokens(
      _amountIn,
      _amountOutMin,
      path,
      address(this),
      block.timestamp + 120
    ) returns(uint[] memory) {
      console.log("SUCCESSFUL SWAP");

    } catch Error(string memory response) {
      console.log("ERROR:", response);
    } catch {
      console.log("UNSUCCESSFUL SWAP");

    }

    // if (_tokenOut == address(WETH) && WETH.balanceOf(address(this)) > 0 && address(this) != _to) {
    //   console.log("CONTRACT WETH BALANCE: %s", Utils.balanceOf(address(this), address(WETH)));
    //   console.log("_WETH: %s", address(WETH));
    //   // console.log("WETH: %s", WETH);
    //   uint WETH_BALANCE = WETH.balanceOf(address(this));

    //   WETH.withdraw(WETH_BALANCE);
    // }
    if (address(this).balance > 0) {
      // refund leftover ETH to user
      (bool success,) = msg.sender.call{ value: address(this).balance }("");
      require(success, "FAILED to transfer ETH to msg.sender");
      // sendMatic(_to, address(this).balance);
    }
    uint tokenOutBalance = tokenOut.balanceOf(address(this));

    if (tokenOut.balanceOf(address(this)) > 0 && address(this) != _to) {
      console.log("TOKEN OUT BALANCE: %s", tokenOutBalance);
      tokenOut.approve(address(this), tokenOutBalance);
      require(tokenOut.transferFrom(address(this), _to, tokenOutBalance), "UniHelper.swap: Problem transferring token... [LINE: 294]");
    }

    console.log("++++++++++++++++++++++++++++++++++++++");
  }

  function fromTokenToTokens (
    address _baseToken,
    address[] memory routers,
    address[] memory _receiveTokens,
    address _to,
    uint _amtBaseToken,
    uint slippageBips
  ) external returns(bool success) {
    uint tradeAmt = (_amtBaseToken.sub(1)).div(_receiveTokens.length);
    uint i = 0;
    address[] memory path = new address[](2);
    uint _amountOutMin;
    uint[] memory amounts;

    for (i = 0; i < _receiveTokens.length; i++) {
      path[0] = _baseToken;
      path[1] = _receiveTokens[i];

      amounts = IUniswapV2Router02(routers[i]).getAmountsOut(tradeAmt, path);
      _amountOutMin = amounts[1].sub(Utils.calculateFee10000(amounts[1], 50));

      IUniswapV2Router02(routers[i]).swapExactTokensForTokens(
        tradeAmt,
        _amountOutMin,
        path,
        _to,
        block.timestamp + 120
      );
    }
  }

}

/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/smart-contracts/contracts/FarmHelper.sol
*/

pragma solidity ^0.8;

////import "./interfaces/IWETH.sol";
////import "./UniswapProtocolHelper.sol";
////import "./interfaces/IUniswapV2.sol";
////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "./farmer/FarmData.sol";
////import "./interfaces/farmer/IMiniApeV2.sol";
////import "./farmer/StrategyApe.sol";
////import "./farmer/StrategySushi.sol";
////import "./interfaces/farmer/IFarmer.sol";
////import "./farmer/Farmer.sol";
////import "hardhat/console.sol";
////import "./DataStore.sol";

contract FarmHelper is FarmData {
  using SafeMath for uint256;

  struct Strategy {
    string name;
  }
  Strategy[] strategies;
  IWETH WETH;
  UniswapProtocolHelper uniHelper;
  DataStore dataStore;
  constructor (UniswapProtocolHelper _uniHelper, DataStore _dataStore, address _weth) {
    WETH = IWETH(_weth);
    uniHelper = _uniHelper;
    dataStore = _dataStore;
  }

 // ////import "@uniswap/lib/contracts/libraries/Babylonian.sol";
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0 (default value)
  }

  function getPendingReward (address _farmer, address user, uint _farmId, uint _farmStrat) external view returns(uint pendingReward) {
    if (_farmStrat == 0) {
      pendingReward = StrategySushi(_farmer).getPendingSushi(_farmer, user, _farmId);
      return pendingReward;
    }
    if (_farmStrat == 0) {
      pendingReward = StrategySushi(_farmer).getPendingSushi(_farmer, user, _farmId);
      return pendingReward;
    }
  }

  function getUserFarmCount (address _farmer, address user) external view returns(uint count) {
    uint len = this.getPoolLength(_farmer);
    uint i;
    for (i = 0; i < len; i++) {
      // event ShowUserInfo(address _farmer, address _farm, address _user, address _amount, address _reward);
      IFarmer.UserInfo memory info = IFarmer(_farmer).userInfo(i, user);
      if (info.amount > 0) count++;
    }

    return count;
  }

  function getUserFarms (address _farmer, address user) external view returns (FarmData.UserFarm[] memory farms) {
    uint userFarmLen = this.getUserFarmCount(_farmer, user);
    uint i;
    uint farmsLen = this.getPoolLength(_farmer);
    farms = new FarmData.UserFarm[](userFarmLen);

    for (i = 0; i < farmsLen; i++) {
      IFarmer.UserInfo memory info = IFarmer(_farmer).userInfo(i, user);
      if (info.amount > 0 && _farmer != address(0)) {
        farms[i].farmer = _farmer;
        farms[i].farmId = i;
        farms[i].pending = info.rewardDebt;
      }

    }
    return farms;
  }

  function getMultiUserFarms (address[] memory _farmers, address user) external view returns (
    FarmData.UserFarm[] memory farms
  ) {
    // require(_farmers.length > 0, "ZERO LENGTH: farmers");
    uint _farmCount;

    for (uint i = 0; i < _farmers.length; i++) {
      FarmData.UserFarm[] memory _farms = this.getUserFarms(_farmers[i], user);
      if (_farms.length > 0) {
        for (uint n = 0; n < _farms.length; n++) {
          // farms[i] = _farms[n];
          _farmCount++;
        }
      }
    }
    farms = new FarmData.UserFarm[](_farmCount);

    for (uint i = 0; i < _farmers.length; i++) {
      FarmData.UserFarm[] memory _farms = this.getUserFarms(_farmers[i], user);
      if (_farms.length > 0) {
        for (uint n = 0; n < _farms.length; n++) {
          farms[i] = _farms[n];
        }
      }
    }
    return farms;
  }

  function getPoolLength (address _farmer) external view returns (uint len) {
    len = IFarmer(_farmer).poolLength();
    return len;
  }

  function addLiquidityFromEth (
    address _router,
    address _token0,
    address _token1,
    uint _amountEth,
    address payable _to
  ) external payable returns(address pairAddress) {
    WETH.deposit{value: msg.value}();
    
    uint _amountIn = _amountEth.div(2);
    address[] memory path0 = new address[](2);
    address[] memory path1 = new address[](2);
    path0[0] = address(WETH);
    path0[1] =  _token0;
    path1[0] = address(WETH);
    path1[1] = _token1;

    pairAddress = uniHelper.getPairAddress(
      IUniswapV2Factory(IUniswapV2Router02(_router).factory()),
      _token0,
      _token1
    );
    
    IERC20(address(WETH)).approve(address(uniHelper), _amountEth);
    if (_token0 != address(WETH)) {

      console.log("getting token0");
      console.log("token0", _token0);
      uint[] memory amountOut = uniHelper.getAmountsOut(IUniswapV2Router02(_router), _amountIn, path0);
      uint _amountOutMin = amountOut[1];
      
      uint[] memory amounts0 = uniHelper.swap(
        IUniswapV2Router02(_router),
        path0[0],
        path0[1],
        _amountIn,
        _amountOutMin,
        payable(address(this))

      );
      console.log("got token0");
    }
    if (_token1 != address(WETH)) {
      console.log("getting token1");
      console.log("token1", _token1);
      uint[] memory amountOut = uniHelper.getAmountsOut(IUniswapV2Router02(_router), _amountIn, path1);
      uint _amountOutMin = amountOut[1].sub(amountOut[1].div(100));

      uint[] memory amounts1 = uniHelper.swap(
        IUniswapV2Router02(_router),
        path1[0],
        path1[1],
        _amountIn,
        _amountOutMin,
        payable(address(this))
      );
      console.log("got token1");
    }
    
    IERC20(_token0).approve(_router, Utils.balanceOf(address(this), _token0));
    IERC20(_token1).approve(_router, Utils.balanceOf(address(this), _token1));

    IUniswapV2Router02(_router).addLiquidity(
      _token0,
      _token1,
      IERC20(_token0).balanceOf(address(this)),
      IERC20(_token1).balanceOf(address(this)),
      0,
      0, 
      payable(address(this)),
      block.timestamp + 300
    );

    if (IERC20(_token0).balanceOf(address(this)) > 0 && _to != msg.sender) IERC20(_token0).transfer(_to, IERC20(_token0).balanceOf(address(this)));
    if (IERC20(_token1).balanceOf(address(this)) > 0 && _to != msg.sender) IERC20(_token1).transfer(_to, IERC20(_token1).balanceOf(address(this)));
    if (IERC20(pairAddress).balanceOf(address(this)) > 0 && _to != msg.sender) IERC20(pairAddress).transfer(_to, IERC20(pairAddress).balanceOf(address(this)));
    return pairAddress;
  }

  function addLiquidityFromToken (
    address _router,
    address _baseToken,
    address _token0,
    address _token1,
    uint _amountBaseToken,
    address payable _to
  ) external payable returns(bool success, address pairAddress) {

    if (msg.value > 0) {
      WETH.deposit{value: msg.value}();
    } else { 
      IERC20(_baseToken).transferFrom(msg.sender, address(this), _amountBaseToken);
    }
    // require(IERC20(_baseToken).balanceOf(msg.sender) >= _amountDaseToken, "Not enough baseToken");
    
    uint _amountIn = (_amountBaseToken.div(2)).sub(1);
    pairAddress = uniHelper.getPairAddress(
      IUniswapV2Factory(IUniswapV2Router02(_router).factory()),
      _token0,
      _token1
    );

    if (IERC20(address(_baseToken)).allowance(address(this), _router) < _amountBaseToken) IERC20(address(_baseToken)).approve(address(_router), (2 ** 112) -1);

    address[] memory path = new address[](2);
    if (_token0 != _baseToken) {
      path[0] = _baseToken;
      path[1] = _token0;

      uint[] memory _amounts = uniHelper.getAmountsIn(IUniswapV2Router02(_router), _amountIn, path);
      uint _amountOutMin = _amounts[1].sub(_amounts[1].div(100));
      try IUniswapV2Router02(_router).swapExactTokensForTokens(
        _amountIn,
        _amountOutMin,
        path,
        address(this),
        block.timestamp + 120
      ) {} catch Error(string memory reason) {
        emit LogError(Utils._stringConcat("_token0 ", reason));
        success = false;
        return (success, pairAddress);
      }
        catch (bytes memory reason) {
        emit LogBytes(reason);
        success = false;
        return (success, pairAddress);
      }
    } 

    if (_token1 != _baseToken) {
      path[0] = _baseToken;
      path[1] = _token1;
      uint[] memory _amounts = uniHelper.getAmountsIn(IUniswapV2Router02(_router), _amountIn, path);
      uint _amountOutMin = _amounts[1].sub(_amounts[1].div(100));
      try IUniswapV2Router02(_router).swapExactTokensForTokens(
        _amountIn,
        _amountOutMin,
        path,
        address(this),
        block.timestamp + 120
      ) {} catch Error(string memory reason) {
        emit LogError(Utils._stringConcat("_token1 ", reason));
        success = false;
        return (success, pairAddress);
      }
        catch (bytes memory reason) {
        emit LogBytes(reason);
        success = false;
        return (success, pairAddress);
      }
    }

    IERC20(_token0).approve(_router, Utils.balanceOf(address(this), _token0));
    IERC20(_token1).approve(_router, Utils.balanceOf(address(this), _token1));

    path[0] = _token0;
    path[1] = _token1;
    uint _token1Amount = IERC20(_token1).balanceOf(address(this)); 
    uint _token0Amount = IERC20(_token0).balanceOf(address(this));  
    try IUniswapV2Router02(_router).addLiquidity(
      _token0,
      _token1,
      _token0Amount,
      _token1Amount,
      0,
      0,
      _to,
      block.timestamp + 120
    ) {
      success = true;
    } catch Error(string memory reason) {
      emit LogError(Utils._stringConcat("addLiquidity", reason));
      success = false;
      return (success, pairAddress);
    }
      catch (bytes memory reason) {
      emit LogBytes(reason);
      success = false;
      return (success, pairAddress);
    }

    if (IERC20(_token0).balanceOf(address(this)) > 0)
      IERC20(_token0).transfer(_to, IERC20(_token0).balanceOf(address(this)));
    if (IERC20(_token1).balanceOf(address(this)) > 0) IERC20(_token1).transfer(_to, IERC20(_token1).balanceOf(address(this)));
    if (IERC20(pairAddress).balanceOf(address(this)) > 0) IERC20(pairAddress).transfer(_to, IERC20(pairAddress).balanceOf(address(this)));
         return (success, pairAddress);

  }

  function tokenToFarm (address _baseToken, address _farmer, uint _farmId, uint _baseTokenAmount) external returns(bool success) {
    uint _halfBaseToken = _baseTokenAmount.div(2);

    // require(tokenToFarmSupport, Utils._stringConcat(
    //   Utils._stringConcat(
    //     "Contract [ ", 
    //     Utils._toAsciiString(_farmer)
    //   ),
    //   " ]: not supported"
    // );
    
  }

  function farmLpToken (address _farmer, uint _farmId, uint amount, uint farmStrat) external returns(bool success) {
    if (farmStrat == 0) {

    }
  }
}