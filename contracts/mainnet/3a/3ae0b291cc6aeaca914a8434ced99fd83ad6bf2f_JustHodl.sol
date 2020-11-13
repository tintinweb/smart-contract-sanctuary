// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

/*   __    __
    /  |  /  |
    $$ |  $$ |
    $$ |__$$ |
    $$    $$ |     Just Hodl
    $$$$$$$$ |     $JH
    $$ |  $$ |
    $$ |  $$ |
    $$ /  $$ /

    The Token For The Hodlers.

    More informations at https://justhodl.finance
*/

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts/JustHodlBase.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;





contract JustHodlBase is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    uint256 internal _totalHodlSinceLastBuy = 0;
    uint256 internal _totalHodlersCount = 0;
    uint256 internal _bonusSupply = 0;
    uint256 internal _holdersSupply = 0;

    mapping (address => uint256) internal _hodlerHodlTime;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function bonusSupply() public view returns (uint256) {
        return _bonusSupply;
    }

    function holdersSupply() public view returns (uint256) {
        return _holdersSupply;
    }

    function totalHodlSinceLastBuy() public view returns (uint256) {
        return _totalHodlSinceLastBuy;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        if (balance > 0 && hodlMinimumAchived(account)) {
            return balance + _getHodlBonus(account, balance);
        } else {
            return balance;
        }
    }

    function pureBalanceOf(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function pureBonusOf(address _address) public view returns (uint256) {
        return balanceOf(_address).sub(_balances[_address]);
    }

    function hodlTimeOf(address _address) public view returns (uint256) {
        return _hodlerHodlTime[_address];
    }

    function hodlMinimumAchived(address _address) public view returns (bool) {
        uint256 hodlTime = _hodlerHodlTime[_address];
        return hodlTime > 0 && (now - 7 days) > hodlTime;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "JustHodlBase: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "JustHodlBase: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "JustHodlBase: transfer from the zero address");
        require(recipient != address(0), "JustHodlBase: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 finalSenderAmount = amount;
        uint256 pureBalance = _balances[sender];
        uint256 totalBalance = balanceOf(sender);
        if (amount > pureBalance && amount <= totalBalance) {
            finalSenderAmount = pureBalance;
        }

        _balances[sender] = _balances[sender].sub(finalSenderAmount, "JustHodlBase: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "JustHodlBase: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _getMinHodlDiff() internal view returns (uint256) {
        return (now - 7 days);
    }

    function _getHoldDiff(address _address, uint256 _minHodlDiff) internal view returns (uint256) {
        return _minHodlDiff - _hodlerHodlTime[_address];
    }

    function _getHodlBonus(address _address, uint256 _balance) internal view returns (uint256) {
        uint256 minHodlDiff = _getMinHodlDiff();
        uint256 hodlDiff = _getHoldDiff(_address, minHodlDiff);
        uint256 totalHodlDiff = minHodlDiff.mul(_totalHodlersCount) - _totalHodlSinceLastBuy;
        return _bonusSupply.mul(((_balance*10**18).div(_holdersSupply).add((hodlDiff*10**18).div(totalHodlDiff))).div(2)).div(10**18);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "JustHodlBase: approve from the zero address");
        require(spender != address(0), "JustHodlBase: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/JustHodl.sol

// pragma solidity ^0.6.0;

contract JustHodl is JustHodlBase {
    address private owner;
    uint256 private penaltyRatio = 10;
    uint256 private maxSupply = 2000 * (10 ** 18);

    struct Addr {
        address _address;
        bool exists;
    }

    mapping (address => Addr) private senderExceptions;
    mapping (address => Addr) private recipientExceptions;
    mapping (address => mapping (address => Addr)) private whitelistedSenders;

    modifier _onlyOwner() {
        require(msg.sender == owner, "JustHodl: only owner can perform this action");
        _;
    }

    constructor() public payable JustHodlBase("JustHodl", "JH") {
        uint256 restTokens = maxSupply;
        uint256 time = now;
        owner = msg.sender;
        _mint(0x04689288b3d01d37a8fe85688042238c1Cd9e5FA, 6.21171493927601 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x04689288b3d01d37a8fe85688042238c1Cd9e5FA] = time;
        restTokens -= 6.21171493927601 * (10**18);
        _mint(0x048AAEA5D07a21196e6Df02E13cCDB23218f65Ae, 1.96477428231032 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x048AAEA5D07a21196e6Df02E13cCDB23218f65Ae] = time;
        restTokens -= 1.96477428231032 * (10**18);
        _mint(0x074abaaff265fD872F438D37d22d31bF1D93fdC8, 0.000000000000015438 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x074abaaff265fD872F438D37d22d31bF1D93fdC8] = time;
        restTokens -= 0.000000000000015438 * (10**18);
        _mint(0x15151Ac99BBa4eE669199EfbDCD0d3af6d70fCb6, 2.45174491323611 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x15151Ac99BBa4eE669199EfbDCD0d3af6d70fCb6] = time;
        restTokens -= 2.45174491323611 * (10**18);
        _mint(0x151c67BeCfd20664a8bfE016569eBCA04F71342E, 2.73602590645353 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x151c67BeCfd20664a8bfE016569eBCA04F71342E] = time;
        restTokens -= 2.73602590645353 * (10**18);
        _mint(0x17e00383A843A9922bCA3B280C0ADE9f8BA48449, 3.94812 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x17e00383A843A9922bCA3B280C0ADE9f8BA48449] = time;
        restTokens -= 3.94812 * (10**18);
        _mint(0x1c8ad03a5DE826D4E4bCb842E3604e1e2F3e8359, 23.9179371378008 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x1c8ad03a5DE826D4E4bCb842E3604e1e2F3e8359] = time;
        restTokens -= 23.9179371378008 * (10**18);
        _mint(0x1DF63e28C9ede182D6dfb6Bbc8C48D6fa537cCeF, 1.10783440633302 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x1DF63e28C9ede182D6dfb6Bbc8C48D6fa537cCeF] = time;
        restTokens -= 1.10783440633302 * (10**18);
        _mint(0x1F2FACAfF2A95027398F946D6868a7dBA5a97667, 91.3750565166852 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x1F2FACAfF2A95027398F946D6868a7dBA5a97667] = time;
        restTokens -= 91.3750565166852 * (10**18);
        _mint(0x205B7B1DAee38C4744C6F0b782E27BcA286c23db, 0.227673758895894 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x205B7B1DAee38C4744C6F0b782E27BcA286c23db] = time;
        restTokens -= 0.227673758895894 * (10**18);
        _mint(0x206971261B391763458134212FeEab2360874676, 1.77998731135435 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x206971261B391763458134212FeEab2360874676] = time;
        restTokens -= 1.77998731135435 * (10**18);
        _mint(0x25F0020A60aE7a375C0970750F5F85C6680bF9Bf, 10.3323681270537 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x25F0020A60aE7a375C0970750F5F85C6680bF9Bf] = time;
        restTokens -= 10.3323681270537 * (10**18);
        _mint(0x2759321Df4C0f0475c41BBf9d17891bd42E32C3c, 26.62505749454025 * (10**18)); // 0.5x
        _totalHodlersCount++;
        _hodlerHodlTime[0x2759321Df4C0f0475c41BBf9d17891bd42E32C3c] = time;
        restTokens -= 26.62505749454025 * (10**18);
        _mint(0x2b6336412636616e9158252999432e1D6938F89F, 3.14908742648611 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x2b6336412636616e9158252999432e1D6938F89F] = time;
        restTokens -= 3.14908742648611 * (10**18);
        _mint(0x34F63cF9E5347D6B00403907ED65eF148177668B, 3.99 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x34F63cF9E5347D6B00403907ED65eF148177668B] = time;
        restTokens -= 3.99 * (10**18);
        _mint(0x3BAAaffbB4eDe1fFA7b512bCEA490cedA2dB0EE6, 1 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x3BAAaffbB4eDe1fFA7b512bCEA490cedA2dB0EE6] = time;
        restTokens -= 1 * (10**18);
        _mint(0x3C9b75bfa82DDbb4613A0EAe58d636260436273A, 0.937153789480753 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x3C9b75bfa82DDbb4613A0EAe58d636260436273A] = time;
        restTokens -= 0.937153789480753 * (10**18);
        _mint(0x3F3FD86382f4d69E1C4e4CF5296B82B3d90FD693, 25.08251279989605 * (10**18)); // 0.5x
        _totalHodlersCount++;
        _hodlerHodlTime[0x3F3FD86382f4d69E1C4e4CF5296B82B3d90FD693] = time;
        restTokens -= 25.08251279989605 * (10**18);
        _mint(0x424dddc996c1dF3D3e9D3D9D89aa32eA5FaDb51f, 2.69635513967925 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x424dddc996c1dF3D3e9D3D9D89aa32eA5FaDb51f] = time;
        restTokens -= 2.69635513967925 * (10**18);
        _mint(0x449A7E1C10D2a0F68243FE104f9330fE16FeFe1A, 85.4291707701004 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x449A7E1C10D2a0F68243FE104f9330fE16FeFe1A] = time;
        restTokens -= 85.4291707701004 * (10**18);
        _mint(0x5139E12886d06C57F20A345c583AD7f3B67D3A5C, 0.672097642975642 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x5139E12886d06C57F20A345c583AD7f3B67D3A5C] = time;
        restTokens -= 0.672097642975642 * (10**18);
        _mint(0x52217443E3fBed2DdF2364F8E174deC88a72b3a6, 10.1 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x52217443E3fBed2DdF2364F8E174deC88a72b3a6] = time;
        restTokens -= 10.1 * (10**18);
        _mint(0x553C0A82a14F2fb77437917e87643A76FbEd8cf4, 1.2475 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x553C0A82a14F2fb77437917e87643A76FbEd8cf4] = time;
        restTokens -= 1.2475 * (10**18);
        _mint(0x56E2356c0754Fae16ac4AEB96D3C843bEc6aff67, 3.67995243382485 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x56E2356c0754Fae16ac4AEB96D3C843bEc6aff67] = time;
        restTokens -= 3.67995243382485 * (10**18);
        _mint(0x59d7b684bced2a28FedebFc09ce3A795F49a4620, 55.7747548243736 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x59d7b684bced2a28FedebFc09ce3A795F49a4620] = time;
        restTokens -= 55.7747548243736 * (10**18);
        _mint(0x5d1EE9f2A17ACcf72532Dd17ad36F0B8909a38CA, 5.13429897024556 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x5d1EE9f2A17ACcf72532Dd17ad36F0B8909a38CA] = time;
        restTokens -= 5.13429897024556 * (10**18);
        _mint(0x7527f8E3a272699f91065b13EF51292034437C7d, 1 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x7527f8E3a272699f91065b13EF51292034437C7d] = time;
        restTokens -= 1 * (10**18);
        _mint(0x78024ea589A845Fb72f285371901614BAA04C168, 2.23804228559044 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x78024ea589A845Fb72f285371901614BAA04C168] = time;
        restTokens -= 2.23804228559044 * (10**18);
        _mint(0x7944449Ed57CE81A6cF7fF557f3E917B7A468086, 2.37310923079961 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x7944449Ed57CE81A6cF7fF557f3E917B7A468086] = time;
        restTokens -= 2.37310923079961 * (10**18);
        _mint(0x830B69752e151Da5d31fb355fc6f636c3bf5e5f8, 2.43915888656735 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x830B69752e151Da5d31fb355fc6f636c3bf5e5f8] = time;
        restTokens -= 2.43915888656735 * (10**18);
        _mint(0x8A449393Ce741a3CeaBd9373008be53dB12Bf246, 4.29474339884683 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x8A449393Ce741a3CeaBd9373008be53dB12Bf246] = time;
        restTokens -= 4.29474339884683 * (10**18);
        _mint(0x8E09fC3D36B0595086538A92BEfE13D09C072661, 2.27418125998612 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x8E09fC3D36B0595086538A92BEfE13D09C072661] = time;
        restTokens -= 2.27418125998612 * (10**18);
        _mint(0x9016563F047fde2a42bf68D9D3670A91E746F1Bc, 1.57237850180211 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x9016563F047fde2a42bf68D9D3670A91E746F1Bc] = time;
        restTokens -= 1.57237850180211 * (10**18);
        _mint(0x9317d29f94f9f399ED27048a14bBaE81D7fd73fB, 7.95 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x9317d29f94f9f399ED27048a14bBaE81D7fd73fB] = time;
        restTokens -= 7.95 * (10**18);
        _mint(0x9853c360CcCaf3968f8DD46d50c133e61Ddb67b1, 125.215644991617 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x9853c360CcCaf3968f8DD46d50c133e61Ddb67b1] = time;
        restTokens -= 125.215644991617 * (10**18);
        _mint(0x9bb354ddf9e43648A06FB69420425FF6C059D231, 68.9075461951348 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x9bb354ddf9e43648A06FB69420425FF6C059D231] = time;
        restTokens -= 68.9075461951348 * (10**18);
        _mint(0x9d2c491a573114d5fBb7aaD5AFC29637F33F31a4, 3.98 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x9d2c491a573114d5fBb7aaD5AFC29637F33F31a4] = time;
        restTokens -= 3.98 * (10**18);
        _mint(0x9df06e44585d1A5B9869a5E5630709e1C74B3b3A, 0.225499390566651 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0x9df06e44585d1A5B9869a5E5630709e1C74B3b3A] = time;
        restTokens -= 0.225499390566651 * (10**18);
        _mint(0xA3544D5a648d8B4649455C836743b4aB49289bc1, 0.239580725432249 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xA3544D5a648d8B4649455C836743b4aB49289bc1] = time;
        restTokens -= 0.239580725432249 * (10**18);
        _mint(0xa574469c959803481f25f825b41f1137BAfcF095, 5.55941808192726 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xa574469c959803481f25f825b41f1137BAfcF095] = time;
        restTokens -= 5.55941808192726 * (10**18);
        _mint(0xa5AAd2CD204e43dC16e4F93c4A20F4A3036124CD, 16.6411113838537 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xa5AAd2CD204e43dC16e4F93c4A20F4A3036124CD] = time;
        restTokens -= 16.6411113838537 * (10**18);
        _mint(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1, 1.01188 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xAA3d85aD9D128DFECb55424085754F6dFa643eb1] = time;
        restTokens -= 1.01188 * (10**18);
        _mint(0xB086755a5B0b10BD53956936588555f586f5f49d, 74.9589937983907 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xB086755a5B0b10BD53956936588555f586f5f49d] = time;
        restTokens -= 74.9589937983907 * (10**18);
        _mint(0xB1Fe569478506aeFEC2bcc84321e8d2053FE3fBB, 9.55813705750499 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xB1Fe569478506aeFEC2bcc84321e8d2053FE3fBB] = time;
        restTokens -= 9.55813705750499 * (10**18);
        _mint(0xc07378E46f4a9D7de862f3d8a51182B48e5166b4, 3.85129183608496 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xc07378E46f4a9D7de862f3d8a51182B48e5166b4] = time;
        restTokens -= 3.85129183608496 * (10**18);
        _mint(0xC56c068C41149fAb578e6e9321517a6c43BE5920, 0.024279185132858 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xC56c068C41149fAb578e6e9321517a6c43BE5920] = time;
        restTokens -= 0.024279185132858 * (10**18);
        _mint(0xC7789B84995E56ef8c1902279695b7b72F6844C1, 2 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xC7789B84995E56ef8c1902279695b7b72F6844C1] = time;
        restTokens -= 2 * (10**18);
        _mint(0xe18bb5aF1c31177898Fe8EBb42E7C1A8F5d092D7, 3.53029091679964 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xe18bb5aF1c31177898Fe8EBb42E7C1A8F5d092D7] = time;
        restTokens -= 3.53029091679964 * (10**18);
        _mint(0xE20F75642b97c11Af651A81AfCBBc6D7B4E32981, 0.695620537288762 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xE20F75642b97c11Af651A81AfCBBc6D7B4E32981] = time;
        restTokens -= 0.695620537288762 * (10**18);
        _mint(0xe7bA0Da73b9d15f5D628BC99A2C014d839691762, 25.6815017450919 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xe7bA0Da73b9d15f5D628BC99A2C014d839691762] = time;
        restTokens -= 25.6815017450919 * (10**18);
        _mint(0xE950C23891E41E5bb3fe4a45DdE62752a4BBf9Fb, 0.0351835809405609 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xE950C23891E41E5bb3fe4a45DdE62752a4BBf9Fb] = time;
        restTokens -= 0.0351835809405609 * (10**18);
        _mint(0xEc1625f0Be12B31d8edfdd165f7750eE4630a475, 3.66244411786722 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xEc1625f0Be12B31d8edfdd165f7750eE4630a475] = time;
        restTokens -= 3.66244411786722 * (10**18);
        _mint(0xEe9EAFDdCDfbFFAb6B9E989B71a13684090cdfaa, 21.0815596983417 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xEe9EAFDdCDfbFFAb6B9E989B71a13684090cdfaa] = time;
        restTokens -= 21.0815596983417 * (10**18);
        _mint(0xf82fFEE7eda1DD212Dd0d867E57aa174dc207D7e, 3.19554497407819 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xf82fFEE7eda1DD212Dd0d867E57aa174dc207D7e] = time;
        restTokens -= 3.19554497407819 * (10**18);
        _mint(0xF872Ea3e3BC2d9EFcb660dE497A6F1c50E4ad25D, 25.6350510199272 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xF872Ea3e3BC2d9EFcb660dE497A6F1c50E4ad25D] = time;
        restTokens -= 25.6350510199272 * (10**18);
        _mint(0xFB04D99d7024bef7047cF6a16c4e33F48e1C4981, 1.79070215317426 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xFB04D99d7024bef7047cF6a16c4e33F48e1C4981] = time;
        restTokens -= 1.79070215317426 * (10**18);
        _mint(0xFC04Ec649be75e2b9bFe15d49e385F65277103b4, 2.1958520537044 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xFC04Ec649be75e2b9bFe15d49e385F65277103b4] = time;
        restTokens -= 2.1958520537044 * (10**18);
        _mint(0xFfe10BE9b63A4005DD1e631eE6fca3f6D6024269, 3.52247792997366 * (10**18));
        _totalHodlersCount++;
        _hodlerHodlTime[0xFfe10BE9b63A4005DD1e631eE6fca3f6D6024269] = time;
        restTokens -= 3.52247792997366 * (10**18);

        _holdersSupply = maxSupply - restTokens;
        _mint(msg.sender, restTokens);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address _address) public _onlyOwner {
        owner = _address;
    }

    function isSenderException(address _address) public view returns (bool) {
        return senderExceptions[_address].exists;
    }

    function addSenderException(address _address) public _onlyOwner returns (bool) {
        require(!isSenderException(_address), "JustHodl: address is already present in the sender exceptions list");
        senderExceptions[_address] = Addr(_address, true);
        return true;
    }

    function removeSenderException(address _address) public _onlyOwner returns (bool) {
        require(isSenderException(_address), "JustHodl: address is not present in the sender exceptions list");
        delete senderExceptions[_address];
        return true;
    }

    function isRecipientException(address _address) public view returns (bool) {
        return recipientExceptions[_address].exists;
    }

    function addRecipientException(address _address) public _onlyOwner returns (bool) {
        require(!isRecipientException(_address), "JustHodl: address is already present in the recipient exceptions list");
        recipientExceptions[_address] = Addr(_address, true);
        return true;
    }

    function removeRecipientException(address _address) public _onlyOwner returns (bool) {
        require(isRecipientException(_address), "JustHodl: address is not present in the recipient exceptions list");
        delete recipientExceptions[_address];
        return true;
    }

    function isWhitelistedSender(address _address) public view returns (bool) {
        return whitelistedSenders[msg.sender][_address].exists;
    }

    function addWhitelistedSender(address _address) public returns (bool) {
        require(!isWhitelistedSender(_address), "JustHodl: address is already present in the whitelist");
        whitelistedSenders[msg.sender][_address] = Addr(_address, true);
        return true;
    }

    function removeWhitelistedSender(address _address) public returns (bool) {
        require(isWhitelistedSender(_address), "JustHodl: address is not present in the whitelist");
        delete whitelistedSenders[msg.sender][_address];
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        bool isFromHodler = _isValidHodler(msg.sender);
        bool isToHodler = _isValidHodler(_to);
        if (_allowedToSend(msg.sender, _to)) {
            uint256 penalty = 0;
            uint256 finalValue = _value;
            uint256 pureFromBalanceBeforeThx = pureBalanceOf(msg.sender);
            uint256 pureToBalanceBeforeThx = pureBalanceOf(_to);
            if (isFromHodler && !hodlMinimumAchived(msg.sender)) {
                penalty = _value.mul(penaltyRatio).div(100);
                finalValue = _value.sub(penalty);
            }
            if (super.transfer(_to, finalValue)) {
                if (penalty > 0) {
                    _balances[msg.sender] = _balances[msg.sender].sub(penalty);
                }
                _updateTimer(msg.sender, _to, isFromHodler, isToHodler);
                _updateHodlersCount(msg.sender, isFromHodler, isToHodler, pureToBalanceBeforeThx);
                _updateBonusSupply(_value, penalty, pureFromBalanceBeforeThx);
                _updateHoldersSupply(isFromHodler, isToHodler, finalValue, penalty, pureFromBalanceBeforeThx);
                _updateAllowedSender(msg.sender, _to);
                return true;
            }
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        bool isFromHodler = _isValidHodler(_from);
        bool isToHodler = _isValidHodler(_to);
        if (_allowedToSend(_from, _to)) {
            uint256 penalty = 0;
            uint256 finalValue = _value;
            uint256 pureFromBalanceBeforeThx = pureBalanceOf(_from);
            uint256 pureToBalanceBeforeThx = pureBalanceOf(_to);
            if (isFromHodler && !hodlMinimumAchived(_from)) {
                penalty = _value.mul(penaltyRatio).div(100);
                finalValue = _value.sub(penalty);
            }
            if (super.transferFrom(_from, _to, finalValue)) {
                if (penalty > 0) {
                    _balances[_from] = _balances[_from].sub(penalty);
                }
                _updateTimer(_from, _to, isFromHodler, isToHodler);
                _updateHodlersCount(_from, isFromHodler, isToHodler, pureToBalanceBeforeThx);
                _updateBonusSupply(_value, penalty, pureFromBalanceBeforeThx);
                _updateHoldersSupply(isFromHodler, isToHodler, finalValue, penalty, pureFromBalanceBeforeThx);
                _updateAllowedSender(_from, _to);
                return true;
            }
        }
        return false;
    }

    function _allowedToSend(address _from, address _to) private view returns (bool) {
        require (
            _from == owner ||
            _isContract(_to) ||
            isSenderException(_from) ||
            isRecipientException(_to) ||
            whitelistedSenders[_to][_from].exists,
            "JustHodl: you are not allowed to send tokens to that address"
        );
        return true;
    }

    function _updateAllowedSender(address _from, address _to) private {
        if (!whitelistedSenders[_from][_to].exists) {
            whitelistedSenders[_from][_to] = Addr(_to, true);
        }
    }

    function _updateTimer(address _from, address _to, bool _isFromHodler, bool _isToHodler) private {
        if (_isFromHodler && _balances[_from] == 0) {
            _totalHodlSinceLastBuy = _totalHodlSinceLastBuy.sub(_hodlerHodlTime[_from]);
            _hodlerHodlTime[_from] = 0;
        }
        if (_isToHodler) {
            uint256 oldLastBuy = _hodlerHodlTime[_to];
            uint256 newLastBuy = now;
            _totalHodlSinceLastBuy = _totalHodlSinceLastBuy.add(newLastBuy).sub(oldLastBuy);
            _hodlerHodlTime[_to] = newLastBuy;
        }
    }

    function _updateHodlersCount(address _from, bool _isFromHodler, bool _isToHodler, uint256 _pureToBalanceBeforeThx) private {
        if (_isFromHodler && _balances[_from] == 0) {
            _totalHodlersCount--;
        }
        if (_isToHodler && _pureToBalanceBeforeThx == 0) {
            _totalHodlersCount++;
        }
    }

    function _updateBonusSupply(uint256 _value, uint256 _penalty, uint256 _pureFromBalanceBeforeThx) private {
        if (_value > _pureFromBalanceBeforeThx) {
            uint256 spentBonus = _value.sub(_pureFromBalanceBeforeThx);
            _bonusSupply = _bonusSupply.sub(spentBonus).add(_penalty);
        } else {
            _bonusSupply = _bonusSupply.add(_penalty);
        }
    }

    function _updateHoldersSupply(bool _isFromHodler, bool _isToHodler, uint256 _value, uint256 _penalty, uint256 _pureFromBalanceBeforeThx) private {
        uint256 finalValue = _holdersSupply;
        uint256 subValue = _value;
        if (_value > _pureFromBalanceBeforeThx) {
            subValue = _pureFromBalanceBeforeThx;
        }
        if (_isFromHodler) {
            finalValue = finalValue.sub(subValue).sub(_penalty);
        }
        if (_isToHodler) {
            finalValue = finalValue.add(_value);
        }
        _holdersSupply = finalValue;
    }

    function _isValidHodler(address _address) private view returns (bool) {
        return !_isContract(_address) && _address != owner;
    }

    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}