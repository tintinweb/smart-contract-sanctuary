/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// Automatically generated with Reach 0.1.3
pragma abicoder v2;

pragma solidity ^0.8.5;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
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
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


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


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
/*
  ReachToken essentially emulates Algorand Standard Assets on Ethereum, but doesn't include things like clawback or a separation of management and creator.
 */
contract ReachToken is ERC20 {
  address private _creator;
  string private _url;
  string private _metadata;

  constructor (
    string memory name_,
    string memory symbol_,
    string memory url_,
    string memory metadata_,
    uint256 supply_
  ) ERC20(name_, symbol_) {
    _creator = _msgSender();
    _mint(_creator, supply_);
    _url = url_;
    _metadata = metadata_;
  }

  function url() public view returns (string memory) { return _url; }

  function metadata() public view returns (string memory) { return _metadata; }

  function burn(uint256 amount) public virtual returns (bool) {
    require(_msgSender() == _creator, "must be creator");
    _burn(_creator, amount);
    return true;
  }

  function destroy() public virtual {
    require(_msgSender() == _creator, "must be creator");
    require(totalSupply() == 0, "must be no supply");
    selfdestruct(payable(_creator));
  }
}

// Generated code includes meaning of numbers
error ReachError(uint256 msg);

contract Stdlib {
  function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "add overflow"); }
  function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "sub wraparound"); }
  function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "mul overflow"); }

  function unsafeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked { z = x + y; } }
  function unsafeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked { z = x - y; } }
  function unsafeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked { z = x * y; } }

  function reachRequire(bool succ, uint256 errMsg) internal pure {
    if ( ! succ ) {
      revert ReachError(errMsg);
    }
  }

  function checkFunReturn(bool succ, bytes memory returnData, uint256 errMsg) internal pure returns (bytes memory) {
    if (succ) {
      return returnData;
    } else {
      if (returnData.length > 0) {
        assembly {
          let returnData_size := mload(returnData)
          revert(add(32, returnData), returnData_size)
        }
      } else {
        revert ReachError(errMsg);
      }
    }
  }

  function tokenAllowance(address payable token, address owner, address spender) internal returns (uint256 amt) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.allowance.selector, owner, spender));
    checkFunReturn(ok, ret, 0 /*'token.allowance'*/);
    amt = abi.decode(ret, (uint256));
  }

  function tokenTransferFrom(address payable token, address sender, address recipient, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.transferFrom.selector, sender, recipient, amt));
    checkFunReturn(ok, ret, 1 /*'token.transferFrom'*/);
    res = abi.decode(ret, (bool));
  }

  function tokenTransfer(address payable token, address recipient, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.transfer.selector, recipient, amt));
    checkFunReturn(ok, ret, 2 /*'token.transfer'*/);
    res = abi.decode(ret, (bool));
  }
  function safeTokenTransfer(address payable token, address recipient, uint256 amt) internal {
    require(tokenTransfer(token, recipient, amt));
  }

  function reachTokenBurn(address payable token, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(ReachToken.burn.selector, amt));
    checkFunReturn(ok, ret, 3 /*'token.burn'*/);
    res = abi.decode(ret, (bool));
  }
  function safeReachTokenBurn(address payable token, uint256 amt) internal {
    require(reachTokenBurn(token, amt));
  }
  
  function reachTokenDestroy(address payable token) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(ReachToken.destroy.selector));
    checkFunReturn(ok, ret, 4 /*'token.destroy'*/);
    res = true;
  }
  function safeReachTokenDestroy(address payable token) internal {
    require(reachTokenDestroy(token));
  }

  function readPayAmt(address sender, address payable token) internal returns (uint256 amt) {
    amt = tokenAllowance(token, sender, address(this));
    require(checkPayAmt(sender, token, amt));
  }

  function checkPayAmt(address sender, address payable token, uint256 amt) internal returns (bool) {
    return tokenTransferFrom(token, sender, address(this), amt);
  }

  function tokenApprove(address payable token, address spender, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.approve.selector, spender, amt));
    checkFunReturn(ok, ret, 5 /*'token.approve'*/);
    res = abi.decode(ret, (bool));
  }

  function tokenBalanceOf(address payable token, address owner) internal returns (uint256 res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0) }(abi.encodeWithSelector(IERC20.balanceOf.selector, owner));
    checkFunReturn(ok, ret, 6 /*'token.balanceOf'*/);
    res = abi.decode(ret, (uint256));
  }
}

struct T1 {
  address payable v67;
  uint256 v68;
  uint256 v69;
  uint256 v238;
  }
struct T2 {
  uint256 v68;
  uint256 v69;
  }
struct T3 {
  bool svs;
  T2 msg;
  }
struct T4 {
  address payable v67;
  uint256 v68;
  uint256 v69;
  address payable v77;
  }
struct T5 {
  uint256 v82;
  uint256 v262;
  uint256 v268;
  }
struct T6 {
  T4 svs;
  T5 msg;
  }
struct T7 {
  T1 svs;
  bool msg;
  }
struct T8 {
  address payable v67;
  uint256 v68;
  uint256 v69;
  address payable v77;
  uint256 v196;
  uint256 v268;
  }
struct T9 {
  address payable v67;
  uint256 v68;
  address payable v77;
  uint256 v82;
  }
struct T10 {
  T9 svs;
  bool msg;
  }
struct T11 {
  address payable v67;
  uint256 v68;
  uint256 v69;
  address payable v77;
  uint256 v106;
  uint256 v170;
  uint256 v268;
  }
struct T12 {
  uint256 v106;
  }
struct T13 {
  T8 svs;
  T12 msg;
  }
struct T14 {
  T8 svs;
  bool msg;
  }
struct T15 {
  address payable v67;
  uint256 v68;
  uint256 v69;
  address payable v77;
  uint256 v106;
  uint256 v116;
  uint256 v144;
  uint256 v268;
  }
struct T16 {
  uint256 v116;
  }
struct T17 {
  T11 svs;
  T16 msg;
  }
struct T18 {
  T11 svs;
  bool msg;
  }
struct T19 {
  uint256 v125;
  uint256 v126;
  }
struct T20 {
  T15 svs;
  T19 msg;
  }
struct T21 {
  T15 svs;
  bool msg;
  }


contract ReachContract is Stdlib {
  uint256 current_state;
  
  event e0();
  struct _F0 {
    uint256 v62;
    uint256 v63;
    }
  constructor() payable {
    emit e0();
    _F0 memory _f;
    _f.v62 = uint256(block.number);
    _f.v63 = uint256(block.timestamp);
    
    bool nsvs;
    current_state = uint256(keccak256(abi.encode(uint256(0), nsvs)));
    
    }
  
  
  
  
  event e1(T3 _a);
  struct _F1 {
    uint256 v238;
    }
  function m1(T3 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(0), _a.svs))), uint256(8) /*'state check at ./index.rsh:49:9:dot'*/);
    current_state = 0x0;
    
    _F1 memory _f;
    
    emit e1(_a);
    reachRequire(msg.value == _a.msg.v68, uint256(7) /*'(./index.rsh:49:9:dot,[],"verify network token pay amount")'*/);
    _f.v238 = uint256(block.number) + _a.msg.v69;
    T1 memory nsvs;
    nsvs.v67 = payable(msg.sender);
    nsvs.v68 = _a.msg.v68;
    nsvs.v69 = _a.msg.v69;
    nsvs.v238 = _f.v238;
    current_state = uint256(keccak256(abi.encode(uint256(1), nsvs)));
    
    
    }
  
  event e2(T7 _a);
  
  function m2(T7 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(1), _a.svs))), uint256(10) /*'state check at ./index.rsh:56:7:dot'*/);
    current_state = 0x0;
    
    
    reachRequire(uint256(block.number) < _a.svs.v238, uint256(11) /*'timeout check at ./index.rsh:56:7:dot'*/);
    
    emit e2(_a);
    reachRequire(msg.value == _a.svs.v68, uint256(9) /*'(./index.rsh:56:7:dot,[],"verify network token pay amount")'*/);
    T6 memory la;
    la.svs.v67 = _a.svs.v67;
    la.svs.v68 = _a.svs.v68;
    la.svs.v69 = _a.svs.v69;
    la.svs.v77 = payable(msg.sender);
    la.msg.v82 = uint256(1);
    la.msg.v262 = uint256(block.number);
    la.msg.v268 = (_a.svs.v68 + _a.svs.v68);
    l4(la);
    
    
    }
  
  event e3(T7 _a);
  
  function m3(T7 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(1), _a.svs))), uint256(14) /*'state check at reach standard library:209:7:dot'*/);
    current_state = 0x0;
    
    
    reachRequire(uint256(block.number) >= _a.svs.v238, uint256(15) /*'timeout check at reach standard library:209:7:dot'*/);
    
    emit e3(_a);
    reachRequire(msg.value == uint256(0), uint256(12) /*'(reach standard library:209:7:dot,[at ./index.rsh:57:37:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v67 == payable(msg.sender)), uint256(13) /*'(reach standard library:209:7:dot,[at ./index.rsh:57:37:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],Just "sender correct")'*/);
    _a.svs.v67.transfer(_a.svs.v68);
    current_state = 0x0;
    selfdestruct(payable(msg.sender));
    
    
    }
  
  struct _F4 {
    uint256 v196;
    }
  function l4(T6 memory _a)  internal {
    _F4 memory _f;
    
    if ((_a.msg.v82 == uint256(1))) {
      _f.v196 = _a.msg.v262 + _a.svs.v69;
      T8 memory nsvs;
      nsvs.v67 = _a.svs.v67;
      nsvs.v68 = _a.svs.v68;
      nsvs.v69 = _a.svs.v69;
      nsvs.v77 = _a.svs.v77;
      nsvs.v196 = _f.v196;
      nsvs.v268 = _a.msg.v268;
      current_state = uint256(keccak256(abi.encode(uint256(6), nsvs)));
      }
    else {
      T10 memory la;
      la.svs.v67 = _a.svs.v67;
      la.svs.v68 = _a.svs.v68;
      la.svs.v77 = _a.svs.v77;
      la.svs.v82 = _a.msg.v82;
      l5(la);
      }
    
    }
  
  
  function l5(T10 memory _a)  internal {
    
    
    ((_a.svs.v82 == uint256(2)) ? _a.svs.v67 : _a.svs.v77).transfer((uint256(2) * _a.svs.v68));
    current_state = 0x0;
    selfdestruct(payable(msg.sender));
    
    
    }
  
  event e6(T13 _a);
  struct _F6 {
    uint256 v170;
    }
  function m6(T13 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(6), _a.svs))), uint256(18) /*'state check at ./index.rsh:69:11:dot'*/);
    current_state = 0x0;
    
    _F6 memory _f;
    reachRequire(uint256(block.number) < _a.svs.v196, uint256(19) /*'timeout check at ./index.rsh:69:11:dot'*/);
    
    emit e6(_a);
    reachRequire(msg.value == uint256(0), uint256(16) /*'(./index.rsh:69:11:dot,[],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v67 == payable(msg.sender)), uint256(17) /*'(./index.rsh:69:11:dot,[],Just "sender correct")'*/);
    _f.v170 = uint256(block.number) + _a.svs.v69;
    T11 memory nsvs;
    nsvs.v67 = _a.svs.v67;
    nsvs.v68 = _a.svs.v68;
    nsvs.v69 = _a.svs.v69;
    nsvs.v77 = _a.svs.v77;
    nsvs.v106 = _a.msg.v106;
    nsvs.v170 = _f.v170;
    nsvs.v268 = _a.svs.v268;
    current_state = uint256(keccak256(abi.encode(uint256(8), nsvs)));
    
    
    }
  
  event e7(T14 _a);
  
  function m7(T14 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(6), _a.svs))), uint256(22) /*'state check at reach standard library:209:7:dot'*/);
    current_state = 0x0;
    
    
    reachRequire(uint256(block.number) >= _a.svs.v196, uint256(23) /*'timeout check at reach standard library:209:7:dot'*/);
    
    emit e7(_a);
    reachRequire(msg.value == uint256(0), uint256(20) /*'(reach standard library:209:7:dot,[at ./index.rsh:70:39:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v77 == payable(msg.sender)), uint256(21) /*'(reach standard library:209:7:dot,[at ./index.rsh:70:39:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],Just "sender correct")'*/);
    _a.svs.v77.transfer(_a.svs.v268);
    current_state = 0x0;
    selfdestruct(payable(msg.sender));
    
    
    }
  
  event e8(T17 _a);
  struct _F8 {
    uint256 v144;
    }
  function m8(T17 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(8), _a.svs))), uint256(26) /*'state check at ./index.rsh:77:9:dot'*/);
    current_state = 0x0;
    
    _F8 memory _f;
    reachRequire(uint256(block.number) < _a.svs.v170, uint256(27) /*'timeout check at ./index.rsh:77:9:dot'*/);
    
    emit e8(_a);
    reachRequire(msg.value == uint256(0), uint256(24) /*'(./index.rsh:77:9:dot,[],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v77 == payable(msg.sender)), uint256(25) /*'(./index.rsh:77:9:dot,[],Just "sender correct")'*/);
    _f.v144 = uint256(block.number) + _a.svs.v69;
    T15 memory nsvs;
    nsvs.v67 = _a.svs.v67;
    nsvs.v68 = _a.svs.v68;
    nsvs.v69 = _a.svs.v69;
    nsvs.v77 = _a.svs.v77;
    nsvs.v106 = _a.svs.v106;
    nsvs.v116 = _a.msg.v116;
    nsvs.v144 = _f.v144;
    nsvs.v268 = _a.svs.v268;
    current_state = uint256(keccak256(abi.encode(uint256(10), nsvs)));
    
    
    }
  
  event e9(T18 _a);
  
  function m9(T18 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(8), _a.svs))), uint256(30) /*'state check at reach standard library:209:7:dot'*/);
    current_state = 0x0;
    
    
    reachRequire(uint256(block.number) >= _a.svs.v170, uint256(31) /*'timeout check at reach standard library:209:7:dot'*/);
    
    emit e9(_a);
    reachRequire(msg.value == uint256(0), uint256(28) /*'(reach standard library:209:7:dot,[at ./index.rsh:78:39:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v67 == payable(msg.sender)), uint256(29) /*'(reach standard library:209:7:dot,[at ./index.rsh:78:39:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],Just "sender correct")'*/);
    _a.svs.v67.transfer(_a.svs.v268);
    current_state = 0x0;
    selfdestruct(payable(msg.sender));
    
    
    }
  
  event e10(T20 _a);
  
  function m10(T20 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(10), _a.svs))), uint256(35) /*'state check at ./index.rsh:85:11:dot'*/);
    current_state = 0x0;
    
    
    reachRequire(uint256(block.number) < _a.svs.v144, uint256(36) /*'timeout check at ./index.rsh:85:11:dot'*/);
    
    emit e10(_a);
    reachRequire(msg.value == uint256(0), uint256(32) /*'(./index.rsh:85:11:dot,[],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v67 == payable(msg.sender)), uint256(33) /*'(./index.rsh:85:11:dot,[],Just "sender correct")'*/);
    reachRequire((_a.svs.v106 == (uint256(keccak256(abi.encode(_a.msg.v125, _a.msg.v126))))), uint256(34) /*'(reach standard library:65:17:application,[at ./index.rsh:87:20:application call to "checkCommitment" (defined at: reach standard library:64:8:function exp)],Nothing)'*/);
    T6 memory la;
    la.svs.v67 = _a.svs.v67;
    la.svs.v68 = _a.svs.v68;
    la.svs.v69 = _a.svs.v69;
    la.svs.v77 = _a.svs.v77;
    la.msg.v82 = ((_a.msg.v126 + (uint256(4) - _a.svs.v116)) % uint256(3));
    la.msg.v262 = uint256(block.number);
    la.msg.v268 = _a.svs.v268;
    l4(la);
    
    
    }
  
  event e11(T21 _a);
  
  function m11(T21 calldata _a) external payable {
    reachRequire(current_state == uint256(keccak256(abi.encode(uint256(10), _a.svs))), uint256(39) /*'state check at reach standard library:209:7:dot'*/);
    current_state = 0x0;
    
    
    reachRequire(uint256(block.number) >= _a.svs.v144, uint256(40) /*'timeout check at reach standard library:209:7:dot'*/);
    
    emit e11(_a);
    reachRequire(msg.value == uint256(0), uint256(37) /*'(reach standard library:209:7:dot,[at ./index.rsh:86:39:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],"verify network token pay amount")'*/);
    reachRequire((_a.svs.v77 == payable(msg.sender)), uint256(38) /*'(reach standard library:209:7:dot,[at ./index.rsh:86:39:application call to "closeTo" (defined at: reach standard library:207:8:function exp)],Just "sender correct")'*/);
    _a.svs.v77.transfer(_a.svs.v268);
    current_state = 0x0;
    selfdestruct(payable(msg.sender));
    
    
    }
  
  
  receive () external payable {}
  }