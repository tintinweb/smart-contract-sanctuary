/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakePair {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ICoinfio {
    function storageReceivedDirect(address _who) external view returns(uint256);
    function storageReceivedFixed(address _who) external view returns(uint256);
    function storageReceivedGroup(address _who) external view returns(uint256);

    function receivedDirectCms(address _who) external view returns(uint256);
    function receivedFixedCms(address _who) external view returns(uint256);
    function receivedGroupCms(address _who) external view returns(uint256);

    function userFund(address _who) external view returns(uint256);
    function levelPackage(address _who) external view returns(uint256);
    function firstSalesBranch(address _who) external view returns(uint256);
    function firstBranch(address _who) external view returns(address);
    function secondSalesBranch(address _who) external view returns(uint256);
    function secondBranch(address _who) external view returns(address);
    function sales(address _who) external view returns(uint256);
    function rank(address _who) external view returns(uint256);
    function storageRank(address _who) external view returns(uint256);
    function parent(address _who) external view returns(address);
    function weight(address _who) external view returns(uint256);
    function start(address _who) external view returns(uint256);
    
    function salesPerBranch(address _who, address _parent) external view returns(uint256);
}

contract Price is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint112;

    uint256 public baseLocalPrice;
    uint256 public baseLocalDec;
    uint256 public fiatLocalPrice = 13;
    uint256 public fiatLocalDec = 100;

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getPairPrice(address _pair, bool _sig) public virtual view returns(uint256 _price) {
        IPancakePair pair = IPancakePair(_pair);
        (uint112 r0, uint112 r1, ) = pair.getReserves();
        _price = _sig ? r0.div(r1) : r1.div(r0);
    }

    function swapLocal(uint256 _value, address _pair, bool _sig) public virtual view returns (uint256 _out) {
        IPancakePair pair = IPancakePair(_pair);
        (uint112 r0, uint112 r1, ) = pair.getReserves();
        _out = _sig ? getAmountOut(_value, r0, r1) : getAmountOut(_value, r1, r0);
    }

    function setBaseLocalPrice(uint256 _price, uint256 _dec) public onlyOwner {
        baseLocalPrice = _price;
        baseLocalDec = _dec;
    }

    function setFiatLocalPrice(uint256 _price, uint256 _dec) public onlyOwner {
        fiatLocalPrice = _price;
        fiatLocalDec = _dec;
    }

    function getBasePrice() public virtual view returns (uint256 _price) {
        _price = getPairPrice(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16, false);
        // _price = 350;
    }

    function getTokenRate() public virtual view returns (uint256 _rate) {
        _rate = getBasePrice().mul(fiatLocalDec).div(fiatLocalPrice);
    }
}

contract Package is Ownable {
    using SafeMath for uint256;
    uint256[] public package = [0.3 ether, 3 ether, 10 ether, 30 ether, 50 ether, ~uint256(0)];
    uint256[] public fixedCms = [0, 50, 80, 100, 130, 150];
    uint256[] public directCms = [0, 80, 90, 100, 110, 120];

    uint256[] public reqPackage = [0, 0.3 ether, 0.3 ether, 3 ether, 10 ether, 30 ether, 50 ether, 50 ether];
    uint256[] public reqSales = [0, 80 ether, 250 ether, 750 ether, 1800 ether, 4000 ether, 8000 ether, 16000 ether];
    uint256[] public first = [0, 0, 0, 525 ether, 1080 ether, 2000 ether, 4800 ether, 8000 ether];
    uint256[] public second = [0, 0, 0, 0, 540 ether, 1200 ether, 1600 ether, 8000 ether];
    uint256[] public groupCms = [0, 60, 100, 130, 150, 180, 200, 250];

    uint256 public splitFixed = 500;
    uint256 public splitDirect = 500;
    uint256 public splitGroup = 1000;
    uint256 public splitWithdraw = 1000;
    uint256 public splitSwap = 900;

    uint256 public swapFee = 100; 
    uint256 public reinvest = 4000;
    uint256 public expired = 270 days;

    uint256 public mainDec = 1000;
    uint256 public rein = 4;
    uint256 public save = 900;

    function setPackage(uint256[] memory _package, uint256[] memory _fixedCms, uint256[] memory _directCms) public onlyOwner {
        require(_package.length == _fixedCms.length && _fixedCms.length == _directCms.length, "setPackage");
        package = _package;
        fixedCms = _fixedCms;
        directCms = _directCms;

    }

    function setGroup(uint256[] memory _reqPackage, uint256[] memory _reqSales, uint256[] memory _first, uint256[] memory _second, uint256[] memory _groupCms) public onlyOwner {
        require(_reqPackage.length == _reqSales.length && _first.length == _second.length && _reqSales.length == _groupCms.length, "setGroup");
        reqPackage = _reqPackage;
        reqSales = _reqSales;
        first = _first;
        second = _second;
        groupCms = _groupCms;
    }

    function setSplit(uint256 _splitFixed, uint256 _splitDirect, uint256 _splitGroup, uint256 _splitWithdraw, uint256 _splitSwap) public onlyOwner {
        splitFixed = _splitFixed;
        splitDirect = _splitDirect;
        splitGroup = _splitGroup;
        splitWithdraw = _splitWithdraw;
        splitSwap = _splitSwap;
    }

    function setNote(uint256 _swapFee, uint256 _reinvest, uint256 _expired, uint256 _mainDec, uint256 _rein, uint256 _save) public onlyOwner {
        swapFee = _swapFee;
        reinvest = _reinvest;
        expired = _expired;
        mainDec = _mainDec;
        rein = _rein;
        save = _save;
    }

    mapping(address => uint256) public levelPackage;
    mapping(address => uint256) public userFund;
    uint256 public totalFund;

    mapping(address => mapping(address => uint256)) public salesPerBranch;
    mapping(address => uint256) public firstSalesBranch;
    mapping(address => address) public firstBranch;
    mapping(address => uint256) public secondSalesBranch;
    mapping(address => address) public secondBranch;
    mapping(address => uint256) public sales;
    mapping(address => uint256) public rank;
    mapping(address => uint256) public storageRank;
    mapping(address => address) public parent;
    mapping(address => uint256) public weight;

    mapping(address => uint256[]) public investFundHistory;
    mapping(address => uint256[]) public investTimestamps;
    mapping(address => uint256) public start;

    function getLevel(uint256 _value) public view returns(uint256 _package) {
        for (uint256 i = 1; i < package.length; i++){
            if (package[i - 1] <= _value && _value < package[i]){
                return fixedCms[i];
            }
        }

        return fixedCms[0];
    }

    function setLevel(address _who, uint256 _addFund) internal returns(uint256 _package) {
        userFund[_who] += _addFund;
        totalFund += _addFund;

        address _temp = _who;
        for (uint256 i = 0; i < weight[_who]; i++){

            setRank(_temp, _addFund);
            _temp = parent[_temp];
        }

        investFundHistory[_who].push(_addFund);
        investTimestamps[_who].push(block.timestamp);

        start[_who] = block.timestamp;

        for (uint256 i = 1; i < package.length; i++){
            if (package[i - 1] <= userFund[_who] && userFund[_who] < package[i]){
                levelPackage[_who] = i;
                changeRank(_who);

                return i;
            }
        }
        return 0;
    }

    function setRank(address _who, uint256 _addFund) private {
        address _parent = parent[_who];

        salesPerBranch[_parent][_who] += _addFund;
        sales[_parent] += _addFund;
        uint256 _v = salesPerBranch[_parent][_who];

        if (_who != firstBranch[_parent]){
            if (_v >= firstSalesBranch[_parent]){
                secondSalesBranch[_parent] = firstSalesBranch[_parent];
                secondBranch[_parent] = firstBranch[_parent];

                firstSalesBranch[_parent] = _v;
                firstBranch[_parent] = _who;
            }

            if (firstSalesBranch[_parent] > _v && _v >= secondSalesBranch[_parent]){
                secondSalesBranch[_parent] = _v;
                secondBranch[_parent] = _who;
            }
        } else {
            firstSalesBranch[_parent] = _v;
        }
        
        changeRank(_parent);
    }

    function changeRank(address _who) private returns(uint256 _rank) {
        for (uint i = 1; i < reqPackage.length; i++){
            if (userFund[_who] < reqPackage[i] || sales[_who] < reqSales[i] ||
             firstSalesBranch[_who] < first[i] || secondSalesBranch[_who] < second[i]){
                 rank[_who] = i - 1;
                 return i - 1;
            }
        }
    }
}

contract ERC20Extend is ERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 public maxTransferRate = 100;
    uint256 public burnRate = 500;
    mapping(address => bool) excluded;

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        if (excluded[sender]){
            return super._transfer(sender, recipient, amount);   
        }

        require(amount > 0 && amount <= totalSupply().mul(maxTransferRate).div(10000), "_transfer");
        uint256 burnValue = amount.mul(burnRate).div(10000);
        super._transfer(sender, recipient, amount.sub(burnValue));
        if (burnValue > 0) {
            _burn(sender, burnValue); 
        }
    }

    function setMaxTransferRate(uint256 _v) public onlyOwner {
        maxTransferRate = _v;
    }

    function setBurnRate(uint256 _v) public onlyOwner {
        burnRate = _v;
    }

    function setExcluded(address _who, bool _s) public onlyOwner {
        excluded[_who] = _s;
    }

    function transferMany(address[] memory recipients, uint256[] memory amounts) public onlyOwner returns (bool) {
        require(recipients.length == amounts.length && amounts.length <= 10000, "The list is not uniform");
        for (uint256 i = 0; i < recipients.length; i++){
            _transfer(msg.sender ,recipients[i], amounts[i]);
        }
        return true;
    }
}

contract Bridge {
    function swap() public payable {}
}

contract Coinfio is Ownable, ERC20Extend, ReentrancyGuard, Price, Package {
    Bridge bridge;
    ICoinfio fio;
    IERC20Metadata token;

    using SafeMath for uint256;

    mapping(address => uint256) public storageReceivedDirect;
    mapping(address => uint256) public storageReceivedFixed;
    mapping(address => uint256) public storageReceivedGroup;

    mapping(address => uint256) public receivedDirectCms;
    mapping(address => uint256) public receivedFixedCms;
    mapping(address => uint256) public receivedGroupCms;
    mapping(address => bool) public migrated;

    event Pay(address indexed _who, uint256 indexed _value, address indexed _from, string _cmt);
    event Register(address indexed _who, uint256 indexed _value, address indexed _parent, uint256 _timestamp);

    constructor (address _bridge, address _fio) ERC20Extend("Chaos Token", "CHAOS") {
        _mint(msg.sender, 99 * 10**6 * 10 ** decimals());
        _mint(address(this), 1 * 10**6 * 10 ** decimals());
        setExcluded(msg.sender, true);
        setExcluded(address(this), true);

        bridge = Bridge(_bridge);
        fio = ICoinfio(_fio);
        token = IERC20Metadata(_fio);
    }

    fallback() external {}

    receive() external payable {
        
    }

    function invest(address _parent) public payable {
        require(fio.parent(msg.sender) == address(0) || migrated[msg.sender], "User");
        require(msg.value > 0 && msg.sender != _parent && (_parent == owner() || parent[_parent] != address(0)), "Invest");

        bridge.swap{value: msg.value.mul(save).div(mainDec)}();

        if (parent[msg.sender] == address(0)){
            // First
            parent[msg.sender] = _parent;
            weight[msg.sender] = weight[_parent] + 1;
            emit Register(msg.sender, msg.value, _parent, block.timestamp);
        }

        setLevel(msg.sender, msg.value);
        
        uint256 _directCms = msg.value.mul(directCms[levelPackage[parent[msg.sender]]]).div(mainDec);

        if (_directCms > 0){
            uint256 _directCmsBNB = _directCms.mul(splitDirect).div(mainDec);
            uint256 _directCmsToken = _directCms.sub(_directCmsBNB).mul(getTokenRate());

            sendBNB(parent[msg.sender], _directCmsBNB, msg.sender, "DirectBNB");
            sendToken(parent[msg.sender], _directCmsToken, msg.sender, "DirectToken");

            receivedDirectCms[parent[msg.sender]] += _directCms;
            storageReceivedDirect[parent[msg.sender]] += _directCms;

            handleX4(parent[msg.sender]);
        }
    }

    function sendBNB(address _who, uint256 _value, address _from, string memory _cmt) private {
        require(_who != address(0) && address(this).balance >= _value, "SendBNB");
        if (_value > 0){
            payable(_who).transfer(_value);
            emit Pay(_who, _value, _from, _cmt);
        }
    }

    function sendToken(address _who, uint256 _value, address _from, string memory _cmt) private {
        require(_who != address(0) && balanceOf(address(this)) >= _value, "SendToken");
        if (_value > 0){
            _transfer(address(this), _who, _value);
            emit Pay(_who, _value, _from, _cmt);
        }
    }

    function checkX4(address _who) public view returns(uint256 _multiples) {
        uint256 _received = receivedDirectCms[_who] + receivedFixedCms[_who] + receivedGroupCms[_who];
        _multiples = _received.mul(mainDec).div(userFund[_who]);
    }

    function handleX4(address _who) private {
        if (checkX4(_who) >= mainDec.mul(rein)){
            reset(_who);
        }
    }

    function calcFixedCms(address _who) public view returns(uint256 _fixedCms) {
        uint256[] memory _investFundHistory = investFundHistory[_who];
        uint256[] memory _investTimestamps = new uint256[](investTimestamps[_who].length +1);

        if (_investFundHistory.length > 0){

            for (uint256 i = 0; i < investTimestamps[_who].length; i++){
                _investTimestamps[i] = investTimestamps[_who][i];
            }
            
            _investTimestamps[_investTimestamps.length -1] = block.timestamp;

            for (uint256 i = 1; i < _investFundHistory.length; i++) {
                _investFundHistory[i] = _investFundHistory[i] + _investFundHistory[i - 1];
            }

            for (uint256 i = 0; i < _investFundHistory.length; i++) {
                uint256 _v = _investFundHistory[i];
                uint256 _eachSecond = _v.mul(getLevel(_v)).div(mainDec).div(30 days);
                uint256 _seconds = _investTimestamps[i + 1].sub(_investTimestamps[i]);

                _fixedCms += _eachSecond.mul(_seconds);

            }

            return _fixedCms;
        }

        return 0;
    }

    function filterGroup(address _who) public view returns (address[] memory _res) {
        address[] memory _member = new address[](groupCms.length);

        address _temp = parent[_who];
        for (uint256 i = 0; i < weight[_who]; i++){
            if (_member[rank[_temp]] == address(0)){
                _member[rank[_temp]] = _temp;
            }

            _temp = parent[_temp];
        }
        return _member;
    }

    function withdrawFixedCms() public {
        require(userFund[msg.sender] >= 0.3 ether, "withdrawFixedCms 1");
        
        uint256 _fixedCms = calcFixedCms(msg.sender);
        require(_fixedCms > 0, "withdrawFixedCms 2");

        uint256 _fixedCmsBNB = _fixedCms.mul(splitFixed).div(mainDec);
        uint256 _fixedCmsToken = _fixedCms.sub(_fixedCmsBNB).mul(getTokenRate());

        sendBNB(msg.sender, _fixedCmsBNB, address(this), "FixedBNB");
        sendToken(msg.sender, _fixedCmsToken, address(this), "FixedToken");

        receivedFixedCms[msg.sender] += _fixedCms;
        storageReceivedFixed[msg.sender] += _fixedCms;

        address[] memory _list = filterGroup(msg.sender);
        for (uint256 i = 1; i < _list.length; i++){
            if (_list[i] != address(0)){

                uint256 _groupCms = _fixedCms.mul(groupCms[i]).div(mainDec);
                
                sendBNB(_list[i], _groupCms, msg.sender, "GroupBNB");
                
                receivedGroupCms[_list[i]] += _groupCms;
                storageReceivedGroup[_list[i]] += _groupCms;

                handleX4(_list[i]);
            }
        }

        investFundHistory[msg.sender] = new uint256[](0);
        investTimestamps[msg.sender] = new uint256[](0);
        investFundHistory[msg.sender].push(userFund[msg.sender]);
        investTimestamps[msg.sender].push(block.timestamp);
        
        handleX4(msg.sender);
    }

    // function withdrawFund() public {
    //     require(start[msg.sender] != 0 && block.timestamp - start[msg.sender] >= expired && userFund[msg.sender] >= 0.3 ether, "withdrawFund");

    //     uint256 _fund = userFund[msg.sender];

    //     uint256 _fundBNB = _fund.mul(splitWithdraw).div(mainDec);
    //     uint256 _fundToken = _fund.sub(_fundBNB).mul(getTokenRate());

    //     sendBNB(msg.sender, _fundBNB, address(this), "WithdrawBNB");
    //     sendToken(msg.sender, _fundToken, address(this), "WithdrawToken");

    //     reset(msg.sender);
    // }

    function reset(address _who) private returns(bool) {
        totalFund -= userFund[_who];
        userFund[_who] = 0;
        
        levelPackage[_who] = 0;
        storageRank[_who] = rank[_who];
        rank[_who] = 0;

        investFundHistory[_who] = new uint256[](0);
        investTimestamps[_who] = new uint256[](0);

        start[_who] = 0;

        receivedDirectCms[_who] = 0;
        receivedFixedCms[_who] = 0;
        receivedGroupCms[_who] = 0;
        return true;
    }

    function swapSimp(uint256 _value) public {
        require(_value > 0 && balanceOf(msg.sender) >= _value, "swap 1");
        uint256 _p = getTokenRate();
        uint256 _real = _value.mul(splitSwap).div(mainDec);
        uint256 _bnb = _real.div(_p);
        require(_bnb > 0 && address(this).balance >= _bnb, "swap 2");
        
        _transfer(msg.sender, address(this), _real);
        _burn(msg.sender, _value - _real);
        sendBNB(msg.sender, _bnb, address(this), "SwapBNB");
    }

    struct V1 {
        uint256 _levelPackage;
        uint256 _userFund;
        uint256 _firstSalesBranch;
        uint256 _secondSalesBranch;
        uint256 _sales;
        uint256 _rank;
        uint256 _storageRank;
        address _parent; 
        uint256 _weight;
    }

    struct V2 {
        uint256[] _investFundHistory;
        uint256[] _investTimestamps;
        uint256 _start;
        uint256 _receivedDirectCms; 
        uint256 _receivedFixedCms; 
        uint256 _receivedGroupCms;
        uint256 _storageReceivedDirect; 
        uint256 _storageReceivedFixed; 
        uint256 _storageReceivedGroup;
    }

    function allView1(address _who) public view returns (V1 memory v1) {
        v1 = V1(levelPackage[_who], userFund[_who], firstSalesBranch[_who], secondSalesBranch[_who], sales[_who], rank[_who], storageRank[_who], parent[_who], weight[_who]);
    }

    function allView2(address _who) public view returns (V2 memory v2) {
        v2 = V2(investFundHistory[_who], investTimestamps[_who], start[_who], receivedDirectCms[_who], receivedFixedCms[_who], receivedGroupCms[_who], storageReceivedDirect[_who], storageReceivedFixed[_who], storageReceivedGroup[_who]);
    }

    function migrate(address addr) public {
        require(!migrated[addr], "migrate 1");
        require(fio.parent(addr) != address(0) && parent[addr] == address(0), "migrate 2");
        
        migrated[addr] = true;
        
        userFund[addr] = fio.userFund(addr);
        levelPackage[addr] = fio.levelPackage(addr);
        
        firstSalesBranch[addr] = fio.firstSalesBranch(addr);
        firstBranch[addr] = fio.firstBranch(addr);
        secondSalesBranch[addr] = fio.secondSalesBranch(addr);
        secondBranch[addr] = fio.secondBranch(addr);
        
        sales[addr] = fio.sales(addr);
        rank[addr] = fio.rank(addr);
        storageRank[addr] = fio.storageRank(addr);
        
        parent[addr] = fio.parent(addr);
        weight[addr] = fio.weight(addr);
        start[addr] = fio.start(addr);
        
        storageReceivedDirect[addr] = fio.storageReceivedDirect(addr);
        storageReceivedFixed[addr] = fio.storageReceivedFixed(addr);
        storageReceivedGroup[addr] = fio.storageReceivedGroup(addr);
        
        receivedDirectCms[addr] = fio.receivedDirectCms(addr);
        receivedFixedCms[addr] = fio.receivedFixedCms(addr);
        receivedGroupCms[addr] = fio.receivedGroupCms(addr);

        investFundHistory[addr].push(userFund[addr]);
        investTimestamps[addr].push(block.timestamp);

        salesPerBranch[parent[addr]][addr] += userFund[addr];
        totalFund += userFund[addr];
    }

    function fork() public {
        uint256 bal = token.balanceOf(msg.sender);
        require(bal > 0, "fork");
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), bal);
        _transfer(address(this), msg.sender, bal);
    }
}