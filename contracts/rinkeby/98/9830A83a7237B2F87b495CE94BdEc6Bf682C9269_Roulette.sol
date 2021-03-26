// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts/Interfaces.sol

pragma solidity >= 0.6.0 < 0.7.0;


interface IPool {
    function supportsIPool() external view returns (bool);
    function addBetToPool(address tokenAddress, uint256 betAmount) external payable;
    function rewardDisribution(address payable player, address tokenAddress, uint256 prize) external returns (bool);
    function maxBet(address tokenAddress, uint256 maxPercent) external view returns (uint256);
    function getOracleGasFee(address tokenAddress) external view returns (uint256);
}

interface IGame {
    function supportsIGame() external view returns (bool);
    function __callback(uint256 randomNumber, uint256 requestId) external;
}

interface IInternalToken is IERC20 {
    function supportsIInternalToken() external view returns (bool);
    function mint(address recipient, uint256 amount) external;
    function burnTokenFrom(address account, uint256 amount) external;
}

interface IOracle {
    function supportsIOracle() external view returns (bool);
    function createRandomNumberRequest() external returns (uint256);
    function acceptRandomNumberRequest(uint256 requestId) external;
}

// File: contracts/Oracle.sol

pragma solidity >= 0.6.0 < 0.7.0;




contract Oracle is IOracle, Ownable {
    IGame[] internal _games;
    address internal _operator;
    uint256 internal _nonce;
    mapping(uint256 => bool) internal _pendingRequests;

    event RandomNumberRequestEvent(address indexed callerAddress, uint256 indexed requestId);
    event RandomNumberEvent(uint256 randomNumber, address indexed callerAddress, uint256 indexed requestId);

    modifier onlyGame(address checkingAddress) {
        bool senderIsAGame = false;
        for (uint256 i = 0; i < _games.length; ++i) {
            if (checkingAddress == address(_games[i])) {
                senderIsAGame = true;
                break;
            }
        }
        require(senderIsAGame, "address is not a game");
        _;
    }

    modifier onlyOperator() {
        require(_msgSender() == _operator, "caller is not the operator");
        _;
    }

    constructor (address operatorAddress) public {
        _nonce = 0;
        _setOperatorAddress(operatorAddress);
    }

    function supportsIOracle() external view override returns (bool) {
        return true;
    }

    function getOperatorAddress() external view onlyOwner returns (address) {
        return _operator;
    }

    function setOperatorAddress(address operatorAddress) external onlyOwner {
        _setOperatorAddress(operatorAddress);
    }

    function getGamesCount() external view returns (uint256) {
        return _games.length;
    }

    function getGame(uint256 index) public view returns (address) {
        require(index < _games.length, "index out of range");
        return address(_games[index]);
    }

    function addGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        require(game.supportsIGame(), "gameAddress must be IGame");
        _games.push(game);
    }

    function removeGame(uint256 index) external onlyOwner {
        getGame(index); // for require check
        if (index != (_games.length - 1)) {
            _games[index] == _games[_games.length - 1];
        }
        _games.pop();
    }

    function getPendingRequests(uint256 requestId) external view onlyOwner returns (bool) {
        return _pendingRequests[requestId];
    }

    function createRandomNumberRequest() external onlyGame(_msgSender()) override returns (uint256) {
        uint256 requestId = 0;
        do {
            _nonce++;
            requestId = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _nonce)));
        } while (_pendingRequests[requestId]);
        _pendingRequests[requestId] = true;
        return requestId;
    }

    function acceptRandomNumberRequest(uint256 requestId) external onlyGame(_msgSender()) override {
        emit RandomNumberRequestEvent(_msgSender(), requestId);
    }

    function publishRandomNumber(uint256 randomNumber, address callerAddress, uint256 requestId) external onlyGame(callerAddress) onlyOperator {
        require(_pendingRequests[requestId], "request isn't in pending list");
        delete _pendingRequests[requestId];

        IGame(callerAddress).__callback(randomNumber, requestId);
        emit RandomNumberEvent(randomNumber, callerAddress, requestId);
    }

    function _setOperatorAddress(address operatorAddress) internal {
        require(operatorAddress != address(0), "invalid operator address");
        _operator = operatorAddress;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;





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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// File: contracts/GambolrUtils.sol

pragma solidity >= 0.6.0 < 0.7.0;

library GambolrUtils {
    address public constant ETH_ADDRESS = 0x0000000000000000000000000000000000000001;
    uint256 public constant PERCENT100 = 10 ** 18; // 100 %

    function checkSquare(uint256 square) external pure returns(bool) {
        return (square > 0) && (square < (1 << 37));
    }

    function getNumOfSquares(uint256 square) external pure returns(uint256 number) {
        number = 0;
        for (uint256 i =  0; i < 37; ++i) {
            if ((square & (1 << i)) > 0) // TODO: not optimized
                number++;
        }
        return number;
    }

    function isSquaresPlayed(uint256 squares, uint256 betNumber) external pure returns(bool) {
        return (squares & (1 << betNumber)) != 0;
    }

    function maximumBet(uint256[] calldata bets) external pure returns(uint256 maxBet) {
        maxBet = bets[0];
        for (uint256 i = 1; i < bets.length; ++i) {
            if (bets[i] > maxBet)
                maxBet = bets[i];
        }
        return maxBet;
    }

    function computeBet(uint256[] calldata bets) external pure returns(uint256 bet) {
        bet = bets[0];
        for (uint256 i = 1; i < bets.length; ++i) {
            bet = bet + bets[i];
            require(bet >= bets[i], "addition overflow");
        }
        return bet;
    }
}

// File: contracts/PoolController.sol

pragma solidity >= 0.6.0 < 0.7.0;






contract PoolController is IPool, Context, Ownable {
    using SafeMath for uint256;

    struct Pool {
        IInternalToken internalToken; // internal token (xEth or TOAST)
        uint256 amount;
        uint256 oracleGasFee;
        uint256 oracleFeeAmount;
        bool active;
    }

    address _oracleOperator;
    IGame[] internal _games;
    mapping(address => ERC20) internal _tokens; // external token address -> ERC20 token interface
    mapping(address => Pool) internal _pools; // external token (eth or BRED) -> pool

    modifier onlyGame() {
        bool senderIsAGame = false;
        for (uint256 i = 0; i < _games.length; ++i) {
            if (_msgSender() == address(_games[i])) {
                senderIsAGame = true;
                break;
            }
        }
        require(senderIsAGame, "caller is not allowed to do some");
        _;
    }

    modifier onlyOracleOperator() {
        require(_msgSender() == _oracleOperator, "caller is not the operator");
        _;
    }

    modifier activePool (address tokenAddress) {
        require(_pools[tokenAddress].active, "pool isn't active");
        _;
    }

    constructor (
        address bredTokenAddress,
        address TOASTTokenAddress,
        address xEthTokenAddress
    ) public {
        require(bredTokenAddress != address(0), "invalid BRED address");
        IInternalToken toastCandidate = IInternalToken(TOASTTokenAddress);
        IInternalToken xEthCandidate = IInternalToken(xEthTokenAddress);
        require(toastCandidate.supportsIInternalToken(), "invalid TOAST address");
        require(xEthCandidate.supportsIInternalToken(), "invalid xETH address");

        _pools[bredTokenAddress].internalToken = toastCandidate;
        _pools[bredTokenAddress].oracleGasFee = 120_000;
        _pools[bredTokenAddress].active = true;
        _tokens[bredTokenAddress] = ERC20(bredTokenAddress);

        _pools[GambolrUtils.ETH_ADDRESS].internalToken = xEthCandidate;
        _pools[GambolrUtils.ETH_ADDRESS].oracleGasFee = 120_000;
        _pools[GambolrUtils.ETH_ADDRESS].active = true;
    }

    receive() external payable {
        require(_pools[GambolrUtils.ETH_ADDRESS].active, "pool isn't active");
        _depositToken(GambolrUtils.ETH_ADDRESS, _msgSender(), msg.value);
    }

//                          Common getters functions                  //
    function activateToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid token address");
        require(!_pools[tokenAddress].active, "already activated");
        _pools[tokenAddress].active = true;
    }

    function deactivateToken(address tokenAddress) external onlyOwner {
        require(_pools[tokenAddress].active, "already deactivated");
        _pools[tokenAddress].active = false;
    }

    function setOracleGasFee(address tokenAddress, uint256 oracleGasFee) external onlyOwner {
        _pools[tokenAddress].oracleGasFee = oracleGasFee;
    }

    function setOracleOperator(address oracleOperator) external onlyOwner {
        _oracleOperator = oracleOperator;
    }

    function supportsIPool() external view override returns (bool) {
        return true;
    }

    function canWithdraw(address tokenAddress, uint256 amount) external view returns (uint256) {
        require(_pools[tokenAddress].active, "pool isn't active");
        return amount.mul(_getPrice(tokenAddress)).div(GambolrUtils.PERCENT100);
    }

    function getPoolInfo(address tokenAddress) external view returns (address, uint256, uint256, uint256, bool) {
        return (
            address(_pools[tokenAddress].internalToken),
            _pools[tokenAddress].amount,
            _pools[tokenAddress].oracleGasFee,
            _pools[tokenAddress].oracleFeeAmount,
            _pools[tokenAddress].active
        );
    }

    function getOracleGasFee(address tokenAddress) external override view returns (uint256) {
        return _pools[tokenAddress].oracleGasFee;
    }

    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }

    function getOracleFeeAmount(address tokenAddress) external view returns (uint256) {
        return _pools[tokenAddress].oracleFeeAmount;
    }

    //                      Deposit/Withdraw functions                      //
    function depositToken(address tokenAddress, uint256 amount) external activePool(tokenAddress) payable {
        if (tokenAddress == GambolrUtils.ETH_ADDRESS) {
            _depositToken(GambolrUtils.ETH_ADDRESS, _msgSender(), msg.value);
        } else {
            _tokens[tokenAddress].transferFrom(_msgSender(), address(this), amount);
            _depositToken(tokenAddress, _msgSender(), amount);
        }
    }

    function withdraw(address tokenAddress, uint256 amount) external activePool(tokenAddress) {
        require(_pools[tokenAddress].internalToken.balanceOf(_msgSender()) >= amount, "amount exceeds balance");
        uint256 withdrawAmount = amount.mul(_getPrice(tokenAddress)).div(GambolrUtils.PERCENT100);
        _pools[tokenAddress].amount = _pools[tokenAddress].amount.sub(withdrawAmount);
        if (tokenAddress == GambolrUtils.ETH_ADDRESS) {
            _msgSender().transfer(withdrawAmount);
        } else {
            _tokens[tokenAddress].transfer(_msgSender(), withdrawAmount);
        }
        _pools[tokenAddress].internalToken.burnTokenFrom(_msgSender(), amount);
    }

    //                      Game functions                      //
    function getGamesCount() external view returns (uint256) {
        return _games.length;
    }

    function getGame(uint256 index) public view returns (address) {
        require(index < _games.length, "index out of range");
        return address(_games[index]);
    }

    function addGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        require(game.supportsIGame(), "gameAddress must be IGame");
        _games.push(game);
    }

    function removeGame(uint256 index) external onlyOwner {
        getGame(index); // for require check
        if (index != (_games.length - 1)) {
            _games[index] == _games[_games.length - 1];
        }
        _games.pop();
    }

    function addBetToPool(address tokenAddress, uint256 betAmount) external onlyGame activePool(tokenAddress) override payable {
        uint256 oracleFeeAmount = _pools[tokenAddress].oracleGasFee;
        _pools[tokenAddress].amount = _pools[tokenAddress].amount.add(betAmount).sub(oracleFeeAmount);
        _pools[tokenAddress].oracleFeeAmount = _pools[tokenAddress].oracleFeeAmount.add(oracleFeeAmount);
    }

    function rewardDisribution(address payable player, address tokenAddress, uint256 prize) external onlyGame activePool(tokenAddress) override returns (bool) {
        if (tokenAddress != GambolrUtils.ETH_ADDRESS) {
            if (_tokens[tokenAddress].balanceOf(address(this)) < prize)
                return false;
            _tokens[tokenAddress].transfer(player, prize);
        } else {
            if (address(this).balance < prize)
                return false;
            player.transfer(prize);
        }
        _pools[tokenAddress].amount = _pools[tokenAddress].amount.sub(prize);
        return true;
    }

    function maxBet(address tokenAddress, uint256 maxPercent) external view override returns (uint256) {
        if (maxPercent > GambolrUtils.PERCENT100)
            return 0;
        if (!_pools[tokenAddress].active) {
            return 0;
        }
        return _pools[tokenAddress].amount.mul(maxPercent).div(GambolrUtils.PERCENT100);
    }

    //                      Oracle functions                                //
    function takeOracleFee(address tokenAddress) external onlyOracleOperator {
        uint256 oracleFeeAmount = _pools[tokenAddress].oracleFeeAmount;
        _pools[tokenAddress].oracleFeeAmount = 0;
        if (tokenAddress == GambolrUtils.ETH_ADDRESS) {
            _msgSender().transfer(oracleFeeAmount);
        } else {
            _tokens[tokenAddress].transfer(_msgSender(), oracleFeeAmount);
        }
    }

    //                      Utility internal functions                      //
    function _depositToken(address tokenAddress, address staker, uint256 amount) internal {
        uint256 tokenAmount = amount.mul(GambolrUtils.PERCENT100).div(_getPrice(tokenAddress));
        Pool memory pool = _pools[tokenAddress];
        _pools[tokenAddress].amount = pool.amount.add(amount);
        pool.internalToken.mint(staker, tokenAmount);
    }

    function _getPrice(address tokenAddress) internal view returns (uint256) {
        if (_pools[tokenAddress].internalToken.totalSupply() == 0)
            return GambolrUtils.PERCENT100;
        return (_pools[tokenAddress].amount).mul(GambolrUtils.PERCENT100).div(_pools[tokenAddress].internalToken.totalSupply());
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/GameController.sol

pragma solidity >= 0.6.0 < 0.7.0;




abstract contract GameController is IGame, Ownable {
    using SafeMath for uint256;

    enum Status { Unknown, Pending, Result }

    struct Numbers {
        uint256 result;
        uint64 timestamp;
        Status status;
    }

    uint256 constant private MIN_TIME_TO_HISTORY_OF_REQUESTS = 7 * 86400; // 1 week

    IOracle internal _oracle;
    uint256 internal _lastRequestId;
    mapping(uint256 => Numbers) internal _randomNumbers; // requestId -> Numbers

    modifier onlyOracle() {
        require(_msgSender() == address(_oracle), "caller is not the oracle");
        _;
    }

    constructor (address oracleAddress) public {
        _setOracle(oracleAddress);
    }

    function supportsIGame() external view override returns (bool) {
        return true;
    }

    function getOracle() external view returns (address) {
        return address(_oracle);
    }

    function setOracle(address oracleAddress) external onlyOwner {
        _setOracle(oracleAddress);
    }

    function getLastRequestId() external view onlyOwner returns (uint256) {
        return _lastRequestId;
    }

    function __callback(uint256 randomNumber, uint256 requestId) override onlyOracle external {
        Numbers storage number = _randomNumbers[requestId];
        number.timestamp = uint64(block.timestamp);
        require(number.status == Status.Pending, "request already closed");
        number.status = Status.Result;
        number.result = randomNumber;
        _publishResults(randomNumber, requestId);
    }

    function _updateRandomNumber() internal {
        uint256 requestId = _oracle.createRandomNumberRequest();
        require(_randomNumbers[requestId].timestamp <= (uint64(block.timestamp) - MIN_TIME_TO_HISTORY_OF_REQUESTS), "requestId already used");
        _oracle.acceptRandomNumberRequest(requestId);
        _randomNumbers[requestId].status = Status.Pending;
        _lastRequestId = requestId;
    }

    function _setOracle(address oracleAddress) internal {
        IOracle iOracleCandidate = IOracle(oracleAddress);
        require(iOracleCandidate.supportsIOracle(), "invalid IOracle address");
        _oracle = iOracleCandidate;
    }

    function _publishResults(uint256 randomNumber, uint256 requestId) internal virtual;
}

// File: contracts/RussianRoulette.sol

pragma solidity >= 0.6.0 < 0.7.0;







contract RussianRoulette is GameController, Pausable {
    using SafeMath for uint256;

    uint256 constant public FEE_PERCENT1 = 10 ** 16; // 1%
    uint256 constant public CYLINDER_SIZE = 100;

    struct Game {
        uint256 id;
        address payable player;
        address tokenAddress;
        uint256 bet;
        uint256 bulletsNumber;
    }

    struct GamesRequests {
        mapping(uint256 => Game) games; // index -> game
        uint256 headIndex;
        uint256 tailIndex;
    }

    event RussianRouletteRun(uint256 indexed id, address indexed player, address tokenAddress, uint256 bet, uint256 cylinderSize, uint256 bulletsNumber, uint256 requestId, uint256 gameIndex);
    event RussianRouletteResult(uint256 indexed id, address indexed player, bool win, uint256 result, uint256 requestId, uint256 gameIndex);

    IPool internal _poolController;

    mapping(uint256 => GamesRequests) internal requests; // requestId -> games

    uint256 internal _numberOfPublishedGames;

    constructor (address oracleAddress, address poolControllerAddress) GameController(oracleAddress) public {
        _setPoolController(poolControllerAddress);
        _numberOfPublishedGames = 10;
        _pause();
    }

    function setPoolController(address poolControllerAddress) onlyOwner external {
        _setPoolController(poolControllerAddress);
    }

    function setNumberOfPublishedGames(uint256 numberOfPublishedGames) external onlyOwner {
        _numberOfPublishedGames = numberOfPublishedGames;
    }

    function getNumberOfPublishedGames() external view returns (uint256) {
        return _numberOfPublishedGames;
    }

    function getRequestInfo(uint256 requestId) external view onlyOwner returns (uint256, uint64, Status, uint256) {
        return (
            _randomNumbers[requestId].result,
            _randomNumbers[requestId].timestamp,
            _randomNumbers[requestId].status,
            requests[requestId].tailIndex
        );
    }

    function getGameInfo(uint256 requestId, uint256 index) external view returns (uint256, address, address, uint256, uint256) {
        require(index < requests[requestId].tailIndex, "index out of range");
        Game memory game = requests[requestId].games[index];
        return (
            game.id,
            game.player,
            game.tokenAddress,
            game.bet,
            game.bulletsNumber
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function play(uint256 betId, address tokenAddress, uint256 betAmount, uint256 bulletsNumber) external whenNotPaused payable {
        require(bulletsNumber >= 1 && bulletsNumber < CYLINDER_SIZE, "incorrect bulletsNumber");
        uint256 gasFee = _poolController.getOracleGasFee(tokenAddress);
        require(betAmount >= gasFee, "incorrectly small bet");
        if (tokenAddress == GambolrUtils.ETH_ADDRESS) {
            require(msg.value >= betAmount, "incorrectly small bet");
        }
        uint256 maxWin = _poolController.maxBet(tokenAddress, 5 * (10 ** 17)); // 0.5 * 10^18 (50%)
        uint256 potentialWin = betAmount.mul(CYLINDER_SIZE).div(CYLINDER_SIZE.sub(bulletsNumber)); // bet * cylinderSize / (cylinderSize - bulletsNumber)
        require(potentialWin <= maxWin, "incorrectly large bet");
        if (tokenAddress != GambolrUtils.ETH_ADDRESS) {
            ERC20(tokenAddress).transferFrom(_msgSender(), address(_poolController), betAmount);
        }
        _poolController.addBetToPool{value: msg.value}(tokenAddress, betAmount);
        if (_randomNumbers[_lastRequestId].status != Status.Pending) {
            super._updateRandomNumber();
        }
        GamesRequests storage request = requests[_lastRequestId];
        request.games[request.tailIndex] = Game(betId, _msgSender(), tokenAddress, betAmount, bulletsNumber);
        request.tailIndex = request.tailIndex.add(1);
        emit RussianRouletteRun(betId, _msgSender(), tokenAddress, betAmount, CYLINDER_SIZE, bulletsNumber, _lastRequestId, request.tailIndex.sub(1));
    }

    function manualPublishResults(uint256 requestId, uint256 numberOfGames) external whenNotPaused {
        require(_randomNumbers[requestId].status == Status.Result, "waiting a random number");
        uint256 randomNumber = _randomNumbers[requestId].result;
        _calculateResults(randomNumber, requestId, numberOfGames);
    }

    function _publishResults(uint256 randomNumber, uint256 requestId) internal override {
        _calculateResults(randomNumber, requestId, _numberOfPublishedGames);
    }

    function _calculateResults(uint256 randomNumber, uint256 requestId, uint256 numberOfGames) internal {
        uint256 tailIndex = requests[requestId].tailIndex;
        uint256 counter = 0;
        for (uint256 index = requests[requestId].headIndex; index < tailIndex && counter < numberOfGames; index = index.add(1)) {
            Game storage currentGame = requests[requestId].games[index];
            uint256 winCondition = randomNumber % CYLINDER_SIZE;
            if (winCondition >= currentGame.bulletsNumber) {
                uint256 gasFee = _poolController.getOracleGasFee(currentGame.tokenAddress);
                uint256 winAmount = currentGame.bet.mul(CYLINDER_SIZE).div(CYLINDER_SIZE.sub(currentGame.bulletsNumber)); // bet * cylinderSize / (cylinderSize - bulletsNumber)
                winAmount = winAmount.sub(winAmount.mul(FEE_PERCENT1).div(GambolrUtils.PERCENT100)).sub(gasFee);
                if (_poolController.rewardDisribution(currentGame.player, currentGame.tokenAddress, winAmount) == false) {
                    requests[requestId].headIndex = index;
                    return;
                }
                emit RussianRouletteResult(currentGame.id, currentGame.player, true, winCondition, requestId, index);
            } else {
                emit RussianRouletteResult(currentGame.id, currentGame.player, false, winCondition, requestId, index);
            }
            counter = counter.add(1);
        }
        requests[requestId].headIndex = tailIndex;
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }
}

// File: contracts/EtherRisk.sol

pragma solidity >= 0.6.0 < 0.7.0;







contract EtherRisk is GameController, Pausable {
    using SafeMath for uint256;

    uint256 constant public FEE_PERCENT1 = 10 ** 16; // 1%
    uint256 constant public CYLINDER_SIZE = 100;

    struct Game {
        uint256 id;
        address payable player;
        address tokenAddress;
        uint256 bet;
        uint256 bulletsNumber;
    }

    struct GamesRequests {
        mapping(uint256 => Game) games; // index -> game
        uint256 headIndex;
        uint256 tailIndex;
    }

    event EtherRiskRun(uint256 indexed id, address indexed player, address tokenAddress, uint256 bet, uint256 cylinderSize, uint256 bulletsNumber, uint256 requestId, uint256 gameIndex);
    event EtherRiskResult(uint256 indexed id, address indexed player, bool win, uint256 result, uint256 requestId, uint256 gameIndex);

    IPool internal _poolController;

    mapping(uint256 => GamesRequests) internal requests; // requestId -> games

    uint256 internal _numberOfPublishedGames;

    constructor (address oracleAddress, address poolControllerAddress) GameController(oracleAddress) public {
        _setPoolController(poolControllerAddress);
        _numberOfPublishedGames = 10;
        _pause();
    }

    function setPoolController(address poolControllerAddress) onlyOwner external {
        _setPoolController(poolControllerAddress);
    }

    function setNumberOfPublishedGames(uint256 numberOfPublishedGames) external onlyOwner {
        _numberOfPublishedGames = numberOfPublishedGames;
    }

    function getNumberOfPublishedGames() external view returns (uint256) {
        return _numberOfPublishedGames;
    }

    function getRequestInfo(uint256 requestId) external view onlyOwner returns (uint256, uint64, Status, uint256) {
        return (
        _randomNumbers[requestId].result,
        _randomNumbers[requestId].timestamp,
        _randomNumbers[requestId].status,
        requests[requestId].tailIndex
        );
    }

    function getGameInfo(uint256 requestId, uint256 index) external view returns (uint256, address, address, uint256, uint256) {
        require(index < requests[requestId].tailIndex, "index out of range");
        Game memory game = requests[requestId].games[index];
        return (
        game.id,
        game.player,
        game.tokenAddress,
        game.bet,
        game.bulletsNumber
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function play(uint256 betId, address tokenAddress, uint256 betAmount, uint256 bulletsNumber) external whenNotPaused payable {
        require(bulletsNumber >= 1 && bulletsNumber < CYLINDER_SIZE, "incorrect bulletsNumber");
        uint256 gasFee = _poolController.getOracleGasFee(tokenAddress);
        require(betAmount >= gasFee, "incorrectly small bet");
        if (tokenAddress == GambolrUtils.ETH_ADDRESS) {
            require(msg.value >= betAmount, "incorrectly small bet");
        }
        uint256 maxWin = _poolController.maxBet(tokenAddress, 5 * (10 ** 17)); // 0.5 * 10^18 (50%)
        uint256 potentialWin = betAmount.mul(CYLINDER_SIZE).div(CYLINDER_SIZE.sub(bulletsNumber)); // bet * cylinderSize / (cylinderSize - bulletsNumber)
        require(potentialWin <= maxWin, "incorrectly large bet");
        if (tokenAddress != GambolrUtils.ETH_ADDRESS) {
            ERC20(tokenAddress).transferFrom(_msgSender(), address(_poolController), betAmount);
        }
        _poolController.addBetToPool{value: msg.value}(tokenAddress, betAmount);
        if (_randomNumbers[_lastRequestId].status != Status.Pending) {
            super._updateRandomNumber();
        }
        GamesRequests storage request = requests[_lastRequestId];
        request.games[request.tailIndex] = Game(betId, _msgSender(), tokenAddress, betAmount, bulletsNumber);
        request.tailIndex = request.tailIndex.add(1);
        emit EtherRiskRun(betId, _msgSender(), tokenAddress, betAmount, CYLINDER_SIZE, bulletsNumber, _lastRequestId, request.tailIndex.sub(1));
    }

    function manualPublishResults(uint256 requestId, uint256 numberOfGames) external whenNotPaused {
        require(_randomNumbers[requestId].status == Status.Result, "waiting a random number");
        uint256 randomNumber = _randomNumbers[requestId].result;
        _calculateResults(randomNumber, requestId, numberOfGames);
    }

    function _publishResults(uint256 randomNumber, uint256 requestId) internal override {
        _calculateResults(randomNumber, requestId, _numberOfPublishedGames);
    }

    function _calculateResults(uint256 randomNumber, uint256 requestId, uint256 numberOfGames) internal {
        uint256 tailIndex = requests[requestId].tailIndex;
        uint256 counter = 0;
        for (uint256 index = requests[requestId].headIndex; index < tailIndex && counter < numberOfGames; index = index.add(1)) {
            Game storage currentGame = requests[requestId].games[index];
            uint256 winCondition = randomNumber % CYLINDER_SIZE;
            if (winCondition >= currentGame.bulletsNumber) {
                uint256 gasFee = _poolController.getOracleGasFee(currentGame.tokenAddress);
                uint256 winAmount = currentGame.bet.mul(CYLINDER_SIZE).div(CYLINDER_SIZE.sub(currentGame.bulletsNumber)); // bet * cylinderSize / (cylinderSize - bulletsNumber)
                winAmount = winAmount.sub(winAmount.mul(FEE_PERCENT1).div(GambolrUtils.PERCENT100)).sub(gasFee);
                if (_poolController.rewardDisribution(currentGame.player, currentGame.tokenAddress, winAmount) == false) {
                    requests[requestId].headIndex = index;
                    return;
                }
                emit EtherRiskResult(currentGame.id, currentGame.player, true, winCondition, requestId, index);
            } else {
                emit EtherRiskResult(currentGame.id, currentGame.player, false, winCondition, requestId, index);
            }
            counter = counter.add(1);
        }
        requests[requestId].headIndex = tailIndex;
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }
}

// File: contracts/Roulette.sol

pragma solidity >= 0.6.0 < 0.7.0;







contract Roulette is GameController, Pausable {
    using SafeMath for uint256;

    struct Game {
        uint256 id;
        address payable player;
        address tokenAddress;
        uint256[] squares;
        uint256[] bets;
    }

    struct GamesRequests {
        mapping(uint256 => Game) games; // index -> game
        uint256 headIndex;
        uint256 tailIndex;
    }

    event RouletteRun(uint256 indexed id, address indexed player, address tokenAddress, uint256[] squares, uint256[] bets, uint256 requestId, uint256 gameIndex);
    event RouletteResult(uint256 indexed id, address indexed player, bool win, uint256 winNumber, uint256 requestId, uint256 gameIndex);

    IPool internal _poolController;

    mapping(uint256 => GamesRequests) internal requests; // requestId -> games

    uint256 internal _numberOfPublishedGames;
    uint256 internal _maxNumberOfBets;
    uint256 internal _maxBet;

    constructor (address oracleAddress, address poolControllerAddress) GameController(oracleAddress) public {
        _setPoolController(poolControllerAddress);
        _numberOfPublishedGames = 10;
        _maxNumberOfBets = 5;
        _maxBet = 108; // 36 + 18 + 18 + 18 + 18 (only for _maxNumberOfBets == 5)
        _pause();
    }

    function setPoolController(address poolControllerAddress) onlyOwner external {
        _setPoolController(poolControllerAddress);
    }

    function setNumberOfPublishedGames(uint256 numberOfPublishedGames) external onlyOwner {
        _numberOfPublishedGames = numberOfPublishedGames;
    }

    function getNumberOfPublishedGames() external view returns (uint256) {
        return _numberOfPublishedGames;
    }

    function setMaxNumberOfBets(uint256 maxNumberOfBets) external onlyOwner {
        _maxNumberOfBets = maxNumberOfBets;
    }

    function getMaxBets() external view returns (uint256) {
        return _maxBet;
    }

    function setMaxBets(uint256 maxBet) external onlyOwner {
        _maxBet = maxBet;
    }

    function getMaxNumberOfBets() external view returns (uint256) {
        return _maxNumberOfBets;
    }


    function getRequestInfo(uint256 requestId) external view onlyOwner returns (uint256, uint64, Status, uint256) {
        return (
            _randomNumbers[requestId].result,
            _randomNumbers[requestId].timestamp,
            _randomNumbers[requestId].status,
            requests[requestId].tailIndex
        );
    }

    function getGameInfo(uint256 requestId, uint256 index) external view returns (uint256, address, address, uint256) {
        require(index < requests[requestId].tailIndex, "index out of range");
        Game memory game = requests[requestId].games[index];
        return (
            game.id,
            game.player,
            game.tokenAddress,
            game.squares.length
        );
    }

    function getChipsInfo(uint256 requestId, uint256 index, uint256 indexChip) external view returns (uint256, uint256) {
        require(index < requests[requestId].tailIndex, "index out of range");
        Game memory game = requests[requestId].games[index];
        require(indexChip < game.squares.length, "index out of range");
        return (
            game.squares[indexChip],
            game.bets[indexChip]
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function play(uint256 betId, address tokenAddress, uint256[] calldata squares, uint256[] calldata bets) external whenNotPaused payable {
        uint256 length = squares.length;
        require(length > 0 && length <= _maxNumberOfBets, "incorrect number of bets");
        require(length == bets.length, "number of bets != bets amounts");
        uint256 gasFee = _poolController.getOracleGasFee(tokenAddress);
        uint256 betAmount = GambolrUtils.computeBet(bets);
        require(betAmount >= gasFee, "incorrectly small bet");
        if (tokenAddress == GambolrUtils.ETH_ADDRESS) {
            require(msg.value >= betAmount, "incorrectly small bet");
        }
        uint256 maxWin = _poolController.maxBet(tokenAddress, 5 * (10 ** 17)); // 0.5 * 10^18 (50%)
        uint256 potentialWin = GambolrUtils.maximumBet(bets).mul(_maxBet);
        require(potentialWin <= maxWin, "incorrectly large bet");
        for (uint256 i = 0; i < length; ++i) {
            require(GambolrUtils.checkSquare(squares[i]), "incorrectly squares");
        }
        if (tokenAddress != GambolrUtils.ETH_ADDRESS) {
            ERC20(tokenAddress).transferFrom(_msgSender(), address(_poolController), betAmount);
        }
        _poolController.addBetToPool{value: msg.value}(tokenAddress, betAmount);
        if (_randomNumbers[_lastRequestId].status != Status.Pending) {
            super._updateRandomNumber();
        }
        GamesRequests storage request = requests[_lastRequestId];
        request.games[request.tailIndex] = Game(betId, _msgSender(), tokenAddress, squares, bets);
        request.tailIndex = request.tailIndex.add(1);
        emit RouletteRun(betId, _msgSender(), tokenAddress, squares, bets, _lastRequestId, request.tailIndex.sub(1));
    }

    function manualPublishResults(uint256 requestId, uint256 numberOfGames) external whenNotPaused {
        require(_randomNumbers[requestId].status == Status.Result, "waiting a random number");
        uint256 randomNumber = _randomNumbers[requestId].result;
        _calculateResults(randomNumber, requestId, numberOfGames);
    }

    function _publishResults(uint256 randomNumber, uint256 requestId) internal override {
        _calculateResults(randomNumber, requestId, _numberOfPublishedGames);
    }

    function _calculateResults(uint256 randomNumber, uint256 requestId, uint256 numberOfGames) internal {
        uint256 tailIndex = requests[requestId].tailIndex;
        uint256 counter = 0;
        for (uint256 index = requests[requestId].headIndex; index < tailIndex && counter < numberOfGames; index = index.add(1)) {
            Game storage currentGame = requests[requestId].games[index];
            uint256 winCondition = randomNumber % 37;
            uint256 winAmount = 0;
            uint256[] memory squares = currentGame.squares;
            for (uint256 i = 0; i < squares.length; ++i) {
                if (GambolrUtils.isSquaresPlayed(squares[i], winCondition)) {
                    winAmount = winAmount.add((currentGame.bets[i]).mul(36).div(GambolrUtils.getNumOfSquares(squares[i])));
                }
            }
            if (winAmount > 0) {
                uint256 gasFee = _poolController.getOracleGasFee(currentGame.tokenAddress);
               // uint256 betAmount = GambolrUtils.computeBet(bets); // TODO: maybe gasFee = gasFee - betAmount
                winAmount = winAmount.sub(gasFee);
                if (_poolController.rewardDisribution(currentGame.player, currentGame.tokenAddress, winAmount) == false) {
                    requests[requestId].headIndex = index;
                    return;
                }
                emit RouletteResult(currentGame.id, currentGame.player, true, winCondition, requestId, index);
            } else {
                emit RouletteResult(currentGame.id, currentGame.player, false, winCondition, requestId, index);
            }
            counter = counter.add(1);
        }
        requests[requestId].headIndex = tailIndex;
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }

}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: contracts/xETH.sol

pragma solidity >= 0.6.0 < 0.7.0;





contract XETHToken is IInternalToken, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    address internal _poolController;

    modifier onlyPoolController() {
        require(_msgSender() == _poolController, "Caller is not pool controller");
        _;
    }

    constructor () public ERC20("xEthereum", "xETH") {
    }

    function supportsIInternalToken() external view override returns (bool) {
        return true;
    }

    function getPoolController() external view returns (address) {
        return _poolController;
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        IPool iPoolCandidate = IPool(poolControllerAddress);
        require(iPoolCandidate.supportsIPool(), "Invalid IPool address");
        _poolController = poolControllerAddress;
    }

    function burnTokenFrom(address account, uint256 amount) public onlyPoolController override {
        _burn(account, amount);
    }

    function mint(address recipient, uint256 amount) public onlyPoolController override {
        _mint(recipient, amount);
    }
}

// File: contracts/BredToken.sol

pragma solidity >= 0.6.0 < 0.7.0;



contract BredToken is ERC20Burnable {
    using SafeMath for uint256;

    constructor () public ERC20("BRED", "BRED") {
        _mint(_msgSender(), 250000000 * 10 ** uint256(decimals()));
    }
}

// File: contracts/TOASTToken.sol

pragma solidity >= 0.6.0 < 0.7.0;





contract TOASTToken is IInternalToken, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    address internal _poolController;

    modifier onlyPoolController() {
        require(_msgSender() == _poolController, "Caller is not pool controller");
        _;
    }

    constructor () public ERC20("TOAST", "TOAST") {
    }

    function supportsIInternalToken() external view override returns (bool) {
        return true;
    }

    function getPoolController() external view returns (address) {
        return _poolController;
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        IPool iPoolCandidate = IPool(poolControllerAddress);
        require(iPoolCandidate.supportsIPool(), "Invalid IPool address");
        _poolController = poolControllerAddress;
    }

    function burnTokenFrom(address account, uint256 amount) public onlyPoolController override {
        _burn(account, amount);
    }

    function mint(address recipient, uint256 amount) public onlyPoolController override {
        _mint(recipient, amount);
    }
}

// File: contracts/ForFlattened.sol

pragma solidity >= 0.6.0 < 0.7.0;

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/home/user/Documents/Projects/solidity/ewgr/contracts/Flattened.sol": {
      "GambolrUtils": "0xcF9245AC0b0e175A88f86eBB8C051084Be2479E3"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}