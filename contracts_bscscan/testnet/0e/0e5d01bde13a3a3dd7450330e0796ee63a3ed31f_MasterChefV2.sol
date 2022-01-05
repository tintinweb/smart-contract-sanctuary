/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity 0.6.12;


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    //  MasterChef contract that can mint the reward token
    address private _chef;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    constructor() public {
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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'ERC20: burn amount exceeds allowance')
        );
    }
}

library SafeERC20 {
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

interface ILibre is IERC20 {
    function chef()external view returns (address);
    function setChef(address chef) external;
    function mint(address _to, uint256 _amount) external;
}

interface IWETH {
     function transfer(address recipient, uint256 amount) external;
     function withdraw(uint wad) external;
}

interface IUniswapRouter {
    function WETH() external view returns (uint256);
    
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
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}

interface IUniswapPair {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}


contract MasterChefV2 is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        address[] lpPath;
        address routerAddress;
        uint256 accLibPerShare; // Accumulated LIBs per share, times 1e12. See below.
        bool isETHPair; // non-Libre LP will be charged 5% fee on withdraw
    }
    // The LIB TOKEN!
    ILibre public lib;
    // Dev address.
    address public devaddr;
    // Lib tokens created per block.
    uint256 public libPerBlock;
    // Lib tokens burn per block.
    IUniswapRouter public uniRouter;
    IUniswapRouter public libreRouter;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    //set true after a new lp be added
    mapping (address=>uint256) public pidMapping;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    uint256 public totalStaked = 0;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 token1Amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    IWETH public WETH;
    constructor(
        address[]memory _lib,
        address _devaddr,
        address _libRouter,
        address _uniRouter,
        uint256 _libPerBlock
    ) public {
        require(_devaddr != address(0),"_devaddr cannot be 0");
        lib = ILibre(_lib[0]);
        libreRouter = IUniswapRouter(_libRouter);
        uniRouter = IUniswapRouter(_uniRouter);
        devaddr = _devaddr;
        // startBlock = block.number;
        libPerBlock = _libPerBlock;
        totalAllocPoint = totalAllocPoint.add(10);
        WETH = IWETH(uniRouter.WETH());
        poolInfo.push(
            PoolInfo({
                lpToken: lib,
                allocPoint: 10,
                routerAddress: address(0),
                lpPath:_lib,
                lastRewardBlock: 0,
                accLibPerShare: 0,
                isETHPair: false
            })
        );
    }
    function setLibrePerBlock(uint256 _libPerBlock) external onlyOwner{
        libPerBlock = _libPerBlock;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function getPoolInfo(uint256 _pid)external view returns(address lp, uint256 allocPoint, uint256 lastRewardBlock, address[]memory lpPath, uint256 accLibPerShare, bool isETHpair, address router){
        PoolInfo storage pool = poolInfo[_pid];
        return (address(pool.lpToken), pool.allocPoint, pool.lastRewardBlock, pool.lpPath, pool.accLibPerShare, pool.isETHPair, pool.routerAddress);
    }
    function setRouter(address _router, uint8 index)external onlyOwner{
        require(_router != address(0),"_uniRouter cannot be 0");
        if(index == 0) uniRouter = IUniswapRouter(_router);
        else if(index == 1)libreRouter = IUniswapRouter(_router);
    }
    function forAPYC(uint8 _pid)external view returns(IERC20, address[]memory, uint256){
        return (poolInfo[_pid].lpToken, poolInfo[_pid].lpPath, poolInfo[_pid].allocPoint);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        address[] memory _lpPath,
        bool _withUpdate,
        bool _isETHPair
    ) external onlyOwner {
        require(pidMapping[address(_lpToken)]==0,"LP already in pool");
        require(address(_lpToken) != address(lib), "LP cannot be LIBRE");
        pidMapping[address(_lpToken)] = poolInfo.length;
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        IERC20 token0 = IERC20(_lpPath[0]);
        IERC20 token1 = IERC20(_lpPath[1]);
        IUniswapPair pair = IUniswapPair(address(_lpToken));
        require((pair.token0() == _lpPath[0] && pair.token1() == _lpPath[1]) || (pair.token0() == _lpPath[1] && pair.token1() == _lpPath[0]), "pair does not exist");
        token0.approve(address(uniRouter),2**95);
        token1.approve(address(uniRouter),2**95);
        token0.approve(address(libreRouter),2**95);
        token1.approve(address(libreRouter),2**95);
        _lpToken.approve(address(uniRouter),2**95);
        _lpToken.approve(address(libreRouter),2**95);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lpPath:_lpPath,
                lastRewardBlock: lastRewardBlock,
                routerAddress: address(uniRouter),
                accLibPerShare: 0,
                isETHPair: _isETHPair
            })
        );
    }
    
    // Update the given pool's allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address[] memory _lpPath,
        address _router,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid){
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lpPath = _lpPath;
        poolInfo[_pid].routerAddress = _router;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256){
        require(_from >= startBlock, "_from can not less than startBlock!");
        return _to.sub(_from);
    }
    // View function to see pending SUSHIs on frontend.
    function pendingLib(uint256 _pid, address _user)
        external
        view validatePoolByPid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLibPerShare = pool.accLibPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 libReward =  multiplier.mul(libPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accLibPerShare = accLibPerShare.add(
                libReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accLibPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePoolByPid(_pid){
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = _pid == 0 ?totalStaked :pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 libReward =
            multiplier.mul(libPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        lib.mint(address(this),libReward);
        pool.accLibPerShare = pool.accLibPerShare.add(
            libReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }
    function stake(uint256 _amount) public nonReentrant{
        lib.transferFrom(msg.sender, address(this), _amount);
        updatePool(0);
        totalStaked = totalStaked.add(_amount);
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        emit Deposit(msg.sender, 0, _amount, 0);
    }
    function unstake(uint256 _amount)public nonReentrant{
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        if(lib.chef() == address(this))updatePool(0);
        totalStaked = totalStaked.sub(_amount);
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending =
            user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                user.rewardDebt
            );
        uint256 fee = pending.mul(2).div(100);

        user.amount = user.amount.sub(_amount);
        safeLibreTransfer(msg.sender, pending.sub(fee));
        safeLibreTransfer(devaddr, fee);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        safeLibreTransfer(address(msg.sender),_amount);
        emit Withdraw(msg.sender, 0, _amount);
    }
    function claimReward(uint256 _pid)public validatePoolByPid(_pid) nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(lib.chef() == address(this),"Libre: Farm is closed");
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
        }
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        
    }
    function restake()public nonReentrant{
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(lib.chef() == address(this),"Libre: Farm is closed");
        updatePool(0);

        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            // safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
            uint256 amount = pending.sub(fee);
            user.amount = user.amount.add(amount);        
            totalStaked = totalStaked.add(amount);
        }
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);

    }
    function depositLP(uint256 _pid, uint256 _amount)public validatePoolByPid(_pid) nonReentrant {
        require(_pid>0,"pool 0 is for staking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IUniswapPair poolLP = IUniswapPair(address(pool.lpToken));
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
    }
    // function depositBoth(uint256 _pid, uint _amount0, uint _amount1) public validatePoolByPid(_pid) nonReentrant payable{
    //     require(_pid>0,"pool 0 is for staking");
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     uint256 lpBefore = pool.lpToken.balanceOf(address(this));
    //     if(pool.lpPath[0]!= address(WETH))IERC20(pool.lpPath[0]).transferFrom(msg.sender, address(this), _amount0);
    //     if(pool.lpPath[1]!= address(WETH))IERC20(pool.lpPath[1]).transferFrom(msg.sender, address(this), _amount1);
    //     uint256 token0init = pool.isETHPair ?address(this).balance :IERC20(pool.lpPath[0]).balanceOf(address(this));
    //     uint256 token1Before = pool.isETHPair ?address(this).balance :IERC20(pool.lpPath[1]).balanceOf(address(this));
    //     _addLibLiquidity(msg.sender, pool.isETHPair, msg.value, IERC20(pool.lpPath[0]), IERC20(pool.lpPath[1]), token0init, token1Before, _amount0, _amount1);
    //     uint256 lpAmount = pool.lpToken.balanceOf(address(this)).sub(lpBefore);
    //     uint256 fee = lpAmount.mul(2).div(100);
    //     lpAmount = lpAmount.sub(fee);
    //     pool.lpToken.transfer(devaddr,fee);
    //     user.amount = user.amount.add(lpAmount);
    //     user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
    //     emit Deposit(msg.sender, _pid, _amount0, lpAmount);
    // }
    function deposit(uint256 _pid, uint256 _amount, uint8 _slippage, bool _revert) public validatePoolByPid(_pid) nonReentrant payable{
        require(_pid>0,"pool 0 is for staking");
        require(_slippage<=20,"slippage range not greater than 2%");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
        }
        uint256 lpBefore = pool.lpToken.balanceOf(address(this));
        if(msg.value>0 && pool.isETHPair && !_revert) _amount = msg.value;

        address[] memory lpPath = new address[](2);
        lpPath[0] = _revert ?pool.lpPath[1]:pool.lpPath[0];
        lpPath[1] = _revert ?pool.lpPath[0]:pool.lpPath[1];
        
        uint256 token1Amount=_swap(msg.sender, lpPath, _amount,_slippage, IUniswapRouter(pool.routerAddress));
        uint256 lpAmount = pool.lpToken.balanceOf(address(this)).sub(lpBefore);

        uint256 fee = lpAmount.mul(2).div(100);
        lpAmount = lpAmount.sub(fee);
        pool.lpToken.transfer(devaddr,fee);
        user.amount = user.amount.add(lpAmount);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount, token1Amount);
    }

    function _swap(address payable _to, address[]memory lpPath, uint256 _amount, uint8 _slippage, IUniswapRouter _uniRouter)private returns (uint256){
        IERC20 token0 = IERC20(lpPath[0]);
        IERC20 token1 = IERC20(lpPath[1]);
        // bool _isETH = lpPath[0] == address(WETH);
        uint256 token0init = lpPath[0] == address(WETH)?address(this).balance :token0.balanceOf(address(this));
        if(lpPath[0] != address(WETH))token0.transferFrom(_to, address(this), _amount);
    
        uint256 token1Before = lpPath[1] == address(WETH)? address(this).balance:token1.balanceOf(address(this));

        uint256 minAmount = _slippageCalculate(token0, token1, _amount.div(2), _slippage, _uniRouter);
        if(lpPath[0] == address(WETH)) _uniRouter.swapExactETHForTokens{value: _amount.div(2)}(minAmount, lpPath, address(this), block.timestamp);
        else _uniRouter.swapExactTokensForTokens(_amount.div(2), minAmount, lpPath, address(this), block.timestamp);
        
       
        uint256 token0Amount = lpPath[0] == address(WETH) ?_amount.div(2) :token0init.add(_amount).sub(token0.balanceOf(address(this))); 
        uint256 token1Amount = token1.balanceOf(address(this)).sub(token1Before);
        bool _isETH = lpPath[0] == address(WETH);
        _addLibLiquidity(_to, _isETH, _amount, token0, token1, token0init, token1Before, token0Amount, token1Amount);

        return token1Amount;
    }
    function _addLibLiquidity(address payable _to, bool _isETH, uint256 _amount, IERC20 token0, IERC20 token1, uint256 token0init, uint256 token1Before,uint256 token0Amount, uint256 token1Amount)private{
        if(address(token0) == address(WETH)) libreRouter.addLiquidityETH{value: token0Amount}(address(token1),token1Amount,0,0,address(this), block.timestamp);
        else libreRouter.addLiquidity(address(token0), address(token1), token0Amount, token1Amount, 0 , 0, address(this), block.timestamp);
        uint256 token0leftOver = address(token0) == address(WETH) ?address(this).balance.sub(token0init.sub(_amount)) :token0.balanceOf(address(this)).sub(token0init); 
        uint256 token1leftOver = token1.balanceOf(address(this)).sub(token1Before); 
        
        if(token0leftOver>0 && !_isETH)token0.transfer(_to, token0leftOver);
        else if(token0leftOver>0 && _isETH)_to.transfer(token0leftOver);
        if(token1leftOver>0)token1.transfer(_to, token1leftOver);

    }
    function _slippageCalculate(IERC20 token0, IERC20 token1, uint256 input, uint8 _slippage, IUniswapRouter _uniRouter)private view returns(uint256){
        address[] memory t = new address[](2);
        t[0] = address(token0);
        t[1] = address(token1);
        // uint256 exceptedAmount = uniRouter.getAmountsOut(input, t)[1].mul(1000-_slippage).div(1000);
        return _uniRouter.getAmountsOut(input, t)[1].mul(1000-_slippage).div(1000);
    }
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public validatePoolByPid(_pid) nonReentrant payable{
        require(_pid>0,"pool 0 is for staking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IERC20 token0 = IERC20(pool.lpPath[0]);
        IERC20 token1 = IERC20(pool.lpPath[1]);

        require(user.amount >= _amount, "withdraw: not good");
        if(lib.chef() == address(this))updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                user.rewardDebt
            );
        uint256 fee = pending.mul(2).div(100);
        uint256 token0Before = token0.balanceOf(address(this));
        uint256 token1Before = token1.balanceOf(address(this));

        libreRouter.removeLiquidity(address(token0), address(token1), _amount, 0 , 0, address(this), block.timestamp);
        uint256 token0Amount = token0.balanceOf(address(this)).sub(token0Before);
        uint256 token1Amount = token1.balanceOf(address(this)).sub(token1Before);
        user.amount = user.amount.sub(_amount);
        safeLibreTransfer(msg.sender, pending.sub(fee));
        safeLibreTransfer(devaddr, fee);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        if(pool.isETHPair){
            WETH.withdraw(uint(token0Amount));
            msg.sender.transfer(token0Amount);
            // token0.transfer(address(msg.sender),token0Amount);
        }
        else token0.transfer(address(msg.sender),token0Amount);
        token1.transfer(address(msg.sender),token1Amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    receive() external payable {}
    
    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough Libres.
    function safeLibreTransfer(address _to, uint256 _amount) internal {
        uint256 libBal = lib.balanceOf(address(this));
        if (_amount > libBal) {
            lib.transfer(_to, libBal);
        } else {
            lib.transfer(_to, _amount);
        }
    }

   
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(_pid>0) pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        else{
            safeLibreTransfer(address(msg.sender),user.amount);
            totalStaked = totalStaked.sub(user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        
        user.amount = 0;
        user.rewardDebt = 0;
    }
    modifier validatePoolByPid(uint256 _pid){
        require(_pid<poolInfo.length, "Pool does not exist");
        _;
    }
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}