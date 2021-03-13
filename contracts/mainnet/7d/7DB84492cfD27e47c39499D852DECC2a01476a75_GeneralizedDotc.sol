/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity 0.6.6;

// File: @openzeppelin/contracts/GSN/Context.sol



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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol







/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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

// File: contracts/oracle/LatestPriceOracleInterface.sol

pragma solidity 0.6.6;


/**
 * @dev Interface of the price oracle.
 */
interface LatestPriceOracleInterface {
    /**
     * @dev Returns `true`if oracle is working.
     */
    function isWorking() external returns (bool);

    /**
     * @dev Returns the last updated price. Decimals is 8.
     **/
    function latestPrice() external returns (uint256);

    /**
     * @dev Returns the timestamp of the last updated price.
     */
    function latestTimestamp() external returns (uint256);
}

// File: contracts/oracle/PriceOracleInterface.sol

pragma solidity 0.6.6;



/**
 * @dev Interface of the price oracle.
 */
interface PriceOracleInterface is LatestPriceOracleInterface {
    /**
     * @dev Returns the latest id. The id start from 1 and increments by 1.
     */
    function latestId() external returns (uint256);

    /**
     * @dev Returns the historical price specified by `id`. Decimals is 8.
     */
    function getPrice(uint256 id) external returns (uint256);

    /**
     * @dev Returns the timestamp of historical price specified by `id`.
     */
    function getTimestamp(uint256 id) external returns (uint256);
}

// File: contracts/oracle/OracleInterface.sol

pragma solidity 0.6.6;


// Oracle referenced by OracleProxy must implement this interface.
interface OracleInterface is PriceOracleInterface {
    function getVolatility() external returns (uint256);

    function lastCalculatedVolatility() external view returns (uint256);
}

// File: contracts/oracle/VolatilityOracleInterface.sol

pragma solidity 0.6.6;

interface VolatilityOracleInterface {
    function getVolatility(uint64 untilMaturity)
        external
        view
        returns (uint64 volatilityE8);
}

// File: contracts/util/TransferETHInterface.sol

pragma solidity 0.6.6;


interface TransferETHInterface {
    receive() external payable;

    event LogTransferETH(address indexed from, address indexed to, uint256 value);
}

// File: contracts/bondToken/BondTokenInterface.sol

pragma solidity 0.6.6;




interface BondTokenInterface is IERC20 {
    event LogExpire(uint128 rateNumerator, uint128 rateDenominator, bool firstTime);

    function mint(address account, uint256 amount) external returns (bool success);

    function expire(uint128 rateNumerator, uint128 rateDenominator)
        external
        returns (bool firstTime);

    function simpleBurn(address account, uint256 amount) external returns (bool success);

    function burn(uint256 amount) external returns (bool success);

    function burnAll() external returns (uint256 amount);

    function getRate() external view returns (uint128 rateNumerator, uint128 rateDenominator);
}

// File: contracts/bondMaker/BondMakerInterface.sol

pragma solidity 0.6.6;



interface BondMakerInterface {
    event LogNewBond(
        bytes32 indexed bondID,
        address indexed bondTokenAddress,
        uint256 indexed maturity,
        bytes32 fnMapID
    );

    event LogNewBondGroup(
        uint256 indexed bondGroupID,
        uint256 indexed maturity,
        uint64 indexed sbtStrikePrice,
        bytes32[] bondIDs
    );

    event LogIssueNewBonds(
        uint256 indexed bondGroupID,
        address indexed issuer,
        uint256 amount
    );

    event LogReverseBondGroupToCollateral(
        uint256 indexed bondGroupID,
        address indexed owner,
        uint256 amount
    );

    event LogExchangeEquivalentBonds(
        address indexed owner,
        uint256 indexed inputBondGroupID,
        uint256 indexed outputBondGroupID,
        uint256 amount
    );

    event LogLiquidateBond(
        bytes32 indexed bondID,
        uint128 rateNumerator,
        uint128 rateDenominator
    );

    function registerNewBond(uint256 maturity, bytes calldata fnMap)
        external
        returns (
            bytes32 bondID,
            address bondTokenAddress,
            bytes32 fnMapID
        );

    function registerNewBondGroup(
        bytes32[] calldata bondIDList,
        uint256 maturity
    ) external returns (uint256 bondGroupID);

    function reverseBondGroupToCollateral(uint256 bondGroupID, uint256 amount)
        external
        returns (bool success);

    function exchangeEquivalentBonds(
        uint256 inputBondGroupID,
        uint256 outputBondGroupID,
        uint256 amount,
        bytes32[] calldata exceptionBonds
    ) external returns (bool);

    function liquidateBond(uint256 bondGroupID, uint256 oracleHintID)
        external
        returns (uint256 totalPayment);

    function collateralAddress() external view returns (address);

    function oracleAddress() external view returns (PriceOracleInterface);

    function feeTaker() external view returns (address);

    function decimalsOfBond() external view returns (uint8);

    function decimalsOfOraclePrice() external view returns (uint8);

    function maturityScale() external view returns (uint256);

    function nextBondGroupID() external view returns (uint256);

    function getBond(bytes32 bondID)
        external
        view
        returns (
            address bondAddress,
            uint256 maturity,
            uint64 solidStrikePrice,
            bytes32 fnMapID
        );

    function getFnMap(bytes32 fnMapID)
        external
        view
        returns (bytes memory fnMap);

    function getBondGroup(uint256 bondGroupID)
        external
        view
        returns (bytes32[] memory bondIDs, uint256 maturity);

    function generateFnMapID(bytes calldata fnMap)
        external
        view
        returns (bytes32 fnMapID);

    function generateBondID(uint256 maturity, bytes calldata fnMap)
        external
        view
        returns (bytes32 bondID);
}

// File: contracts/bondPricer/Enums.sol

pragma solidity 0.6.6;

/**
    Pure SBT:
        ___________
       /
      /
     /
    /

    LBT Shape:
              /
             /
            /
           /
    ______/

    SBT Shape:
              ______
             /
            /
    _______/

    Triangle:
              /\
             /  \
            /    \
    _______/      \________
 */
enum BondType {NONE, PURE_SBT, SBT_SHAPE, LBT_SHAPE, TRIANGLE}

// File: contracts/bondPricer/BondPricerInterface.sol

pragma solidity 0.6.6;


interface BondPricerInterface {
    /**
     * @notice Calculate bond price and leverage by black-scholes formula.
     * @param bondType type of target bond.
     * @param points coodinates of polyline which is needed for price calculation
     * @param spotPrice is a oracle price.
     * @param volatilityE8 is a oracle volatility.
     * @param untilMaturity Remaining period of target bond in second
     **/
    function calcPriceAndLeverage(
        BondType bondType,
        uint256[] calldata points,
        int256 spotPrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) external view returns (uint256 price, uint256 leverageE8);
}

// File: @openzeppelin/contracts/math/SignedSafeMath.sol



/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: @openzeppelin/contracts/utils/SafeCast.sol




/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/math/UseSafeMath.sol

pragma solidity 0.6.6;




/**
 * @notice ((a - 1) / b) + 1 = (a + b -1) / b
 * for example a.add(10**18 -1).div(10**18) = a.sub(1).div(10**18) + 1
 */

library SafeMathDivRoundUp {
    using SafeMath for uint256;

    function divRoundUp(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        require(b > 0, errorMessage);
        return ((a - 1) / b) + 1;
    }

    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return divRoundUp(a, b, "SafeMathDivRoundUp: modulo by zero");
    }
}

/**
 * @title UseSafeMath
 * @dev One can use SafeMath for not only uint256 but also uin64 or uint16,
 * and also can use SafeCast for uint256.
 * For example:
 *   uint64 a = 1;
 *   uint64 b = 2;
 *   a = a.add(b).toUint64() // `a` become 3 as uint64
 * In addition, one can use SignedSafeMath and SafeCast.toUint256(int256) for int256.
 * In the case of the operation to the uint64 value, one needs to cast the value into int256 in
 * advance to use `sub` as SignedSafeMath.sub not SafeMath.sub.
 * For example:
 *   int256 a = 1;
 *   uint64 b = 2;
 *   int256 c = 3;
 *   a = a.add(int256(b).sub(c)); // `a` becomes 0 as int256
 *   b = a.toUint256().toUint64(); // `b` becomes 0 as uint64
 */
abstract contract UseSafeMath {
    using SafeMath for uint256;
    using SafeMathDivRoundUp for uint256;
    using SafeMath for uint64;
    using SafeMathDivRoundUp for uint64;
    using SafeMath for uint16;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
}

// File: contracts/util/Polyline.sol

pragma solidity 0.6.6;


contract Polyline is UseSafeMath {
    struct Point {
        uint64 x; // Value of the x-axis of the x-y plane
        uint64 y; // Value of the y-axis of the x-y plane
    }

    struct LineSegment {
        Point left; // The left end of the line definition range
        Point right; // The right end of the line definition range
    }

    /**
     * @notice Return the value of y corresponding to x on the given line. line in the form of
     * a rational number (numerator / denominator).
     * If you treat a line as a line segment instead of a line, you should run
     * includesDomain(line, x) to check whether x is included in the line's domain or not.
     * @dev To guarantee accuracy, the bit length of the denominator must be greater than or equal
     * to the bit length of x, and the bit length of the numerator must be greater than or equal
     * to the sum of the bit lengths of x and y.
     */
    function _mapXtoY(LineSegment memory line, uint64 x)
        internal
        pure
        returns (uint128 numerator, uint64 denominator)
    {
        int256 x1 = int256(line.left.x);
        int256 y1 = int256(line.left.y);
        int256 x2 = int256(line.right.x);
        int256 y2 = int256(line.right.y);

        require(x2 > x1, "must be left.x < right.x");

        denominator = uint64(x2 - x1);

        // Calculate y = ((x2 - x) * y1 + (x - x1) * y2) / (x2 - x1)
        // in the form of a fraction (numerator / denominator).
        int256 n = (x - x1) * y2 + (x2 - x) * y1;

        require(n >= 0, "underflow n");
        require(n < 2**128, "system error: overflow n");
        numerator = uint128(n);
    }

    /**
     * @notice Checking that a line segment is a valid format.
     */
    function assertLineSegment(LineSegment memory segment) internal pure {
        uint64 x1 = segment.left.x;
        uint64 x2 = segment.right.x;
        require(x1 < x2, "must be left.x < right.x");
    }

    /**
     * @notice Checking that a polyline is a valid format.
     */
    function assertPolyline(LineSegment[] memory polyline) internal pure {
        uint256 numOfSegment = polyline.length;
        require(numOfSegment != 0, "polyline must not be empty array");

        LineSegment memory leftSegment = polyline[0]; // mutable
        int256 gradientNumerator = int256(leftSegment.right.y) -
            int256(leftSegment.left.y); // mutable
        int256 gradientDenominator = int256(leftSegment.right.x) -
            int256(leftSegment.left.x); // mutable

        // The beginning of the first line segment's domain is 0.
        require(
            leftSegment.left.x == uint64(0),
            "the x coordinate of left end of the first segment must be 0"
        );
        // The value of y when x is 0 is 0.
        require(
            leftSegment.left.y == uint64(0),
            "the y coordinate of left end of the first segment must be 0"
        );

        // Making sure that the first line segment is a correct format.
        assertLineSegment(leftSegment);

        // The end of the domain of a segment and the beginning of the domain of the adjacent
        // segment must coincide.
        LineSegment memory rightSegment; // mutable
        for (uint256 i = 1; i < numOfSegment; i++) {
            rightSegment = polyline[i];

            // Make sure that the i-th line segment is a correct format.
            assertLineSegment(rightSegment);

            // Checking that the x-coordinates are same.
            require(
                leftSegment.right.x == rightSegment.left.x,
                "given polyline has an undefined domain."
            );

            // Checking that the y-coordinates are same.
            require(
                leftSegment.right.y == rightSegment.left.y,
                "given polyline is not a continuous function"
            );

            int256 nextGradientNumerator = int256(rightSegment.right.y) -
                int256(rightSegment.left.y);
            int256 nextGradientDenominator = int256(rightSegment.right.x) -
                int256(rightSegment.left.x);
            require(
                nextGradientNumerator * gradientDenominator !=
                    nextGradientDenominator * gradientNumerator,
                "the sequential segments must not have the same gradient"
            );

            leftSegment = rightSegment;
            gradientNumerator = nextGradientNumerator;
            gradientDenominator = nextGradientDenominator;
        }

        // rightSegment is lastSegment

        // About the last line segment.
        require(
            gradientNumerator >= 0 && gradientNumerator <= gradientDenominator,
            "the gradient of last line segment must be non-negative, and equal to or less than 1"
        );
    }

    /**
     * @notice zip a LineSegment structure to uint256
     * @return zip uint256( 0 ... 0 | x1 | y1 | x2 | y2 )
     */
    function zipLineSegment(LineSegment memory segment)
        internal
        pure
        returns (uint256 zip)
    {
        uint256 x1U256 = uint256(segment.left.x) << (64 + 64 + 64); // uint64
        uint256 y1U256 = uint256(segment.left.y) << (64 + 64); // uint64
        uint256 x2U256 = uint256(segment.right.x) << 64; // uint64
        uint256 y2U256 = uint256(segment.right.y); // uint64
        zip = x1U256 | y1U256 | x2U256 | y2U256;
    }

    /**
     * @notice unzip uint256 to a LineSegment structure
     */
    function unzipLineSegment(uint256 zip)
        internal
        pure
        returns (LineSegment memory)
    {
        uint64 x1 = uint64(zip >> (64 + 64 + 64));
        uint64 y1 = uint64(zip >> (64 + 64));
        uint64 x2 = uint64(zip >> 64);
        uint64 y2 = uint64(zip);
        return
            LineSegment({
                left: Point({x: x1, y: y1}),
                right: Point({x: x2, y: y2})
            });
    }

    /**
     * @notice unzip the fnMap to uint256[].
     */
    function decodePolyline(bytes memory fnMap)
        internal
        pure
        returns (uint256[] memory)
    {
        return abi.decode(fnMap, (uint256[]));
    }
}

// File: contracts/bondPricer/DetectBondShape.sol

pragma solidity 0.6.6;




contract DetectBondShape is Polyline {
    /**
     * @notice Detect bond type by polyline of bond.
     * @param bondID bondID of target bond token
     * @param submittedType if this parameter is BondType.NONE, this function checks up all bond types. Otherwise this function checks up only one bond type.
     * @param success whether bond detection succeeded or notice
     * @param points coodinates of polyline which is needed for price calculation
     **/
    function getBondTypeByID(
        BondMakerInterface bondMaker,
        bytes32 bondID,
        BondType submittedType
    )
        public
        view
        returns (
            bool success,
            BondType,
            uint256[] memory points
        )
    {
        (, , , bytes32 fnMapID) = bondMaker.getBond(bondID);
        bytes memory fnMap = bondMaker.getFnMap(fnMapID);
        return _getBondType(fnMap, submittedType);
    }

    /**
     * @notice Detect bond type by polyline of bond.
     * @param fnMap Function mapping of target bond token
     * @param submittedType If this parameter is BondType.NONE, this function checks up all bond types. Otherwise this function checks up only one bond type.
     * @param success Whether bond detection succeeded or not
     * @param points Coodinates of polyline which are needed for price calculation
     **/
    function getBondType(bytes calldata fnMap, BondType submittedType)
        external
        pure
        returns (
            bool success,
            BondType,
            uint256[] memory points
        )
    {
        uint256[] memory polyline = decodePolyline(fnMap);
        LineSegment[] memory segments = new LineSegment[](polyline.length);
        for (uint256 i = 0; i < polyline.length; i++) {
            segments[i] = unzipLineSegment(polyline[i]);
        }
        assertPolyline(segments);

        return _getBondType(fnMap, submittedType);
    }

    function _getBondType(bytes memory fnMap, BondType submittedType)
        internal
        pure
        returns (
            bool success,
            BondType,
            uint256[] memory points
        )
    {
        if (submittedType == BondType.NONE) {
            (success, points) = _isSBT(fnMap);
            if (success) {
                return (success, BondType.PURE_SBT, points);
            }

            (success, points) = _isSBTShape(fnMap);
            if (success) {
                return (success, BondType.SBT_SHAPE, points);
            }

            (success, points) = _isLBTShape(fnMap);
            if (success) {
                return (success, BondType.LBT_SHAPE, points);
            }

            (success, points) = _isTriangle(fnMap);
            if (success) {
                return (success, BondType.TRIANGLE, points);
            }

            return (false, BondType.NONE, points);
        } else if (submittedType == BondType.PURE_SBT) {
            (success, points) = _isSBT(fnMap);
            if (success) {
                return (success, BondType.PURE_SBT, points);
            }
        } else if (submittedType == BondType.SBT_SHAPE) {
            (success, points) = _isSBTShape(fnMap);
            if (success) {
                return (success, BondType.SBT_SHAPE, points);
            }
        } else if (submittedType == BondType.LBT_SHAPE) {
            (success, points) = _isLBTShape(fnMap);
            if (success) {
                return (success, BondType.LBT_SHAPE, points);
            }
        } else if (submittedType == BondType.TRIANGLE) {
            (success, points) = _isTriangle(fnMap);
            if (success) {
                return (success, BondType.TRIANGLE, points);
            }
        }

        return (false, BondType.NONE, points);
    }

    function _isLBTShape(bytes memory fnMap)
        internal
        pure
        returns (bool isOk, uint256[] memory points)
    {
        uint256[] memory zippedLines = decodePolyline(fnMap);
        if (zippedLines.length != 2) {
            return (false, points);
        }
        LineSegment memory secondLine = unzipLineSegment(zippedLines[1]);
        if (
            secondLine.left.x != 0 &&
            secondLine.left.y == 0 &&
            secondLine.right.x > secondLine.left.x &&
            secondLine.right.y != 0
        ) {
            uint256[] memory _lines = new uint256[](3);
            _lines[0] = secondLine.left.x;
            _lines[1] = secondLine.right.x;
            _lines[2] = secondLine.right.y;
            return (true, _lines);
        }
        return (false, points);
    }

    function _isTriangle(bytes memory fnMap)
        internal
        pure
        returns (bool isOk, uint256[] memory points)
    {
        uint256[] memory zippedLines = decodePolyline(fnMap);
        if (zippedLines.length != 4) {
            return (false, points);
        }
        LineSegment memory secondLine = unzipLineSegment(zippedLines[1]);
        LineSegment memory thirdLine = unzipLineSegment(zippedLines[2]);
        LineSegment memory forthLine = unzipLineSegment(zippedLines[3]);
        if (
            secondLine.left.x != 0 &&
            secondLine.left.y == 0 &&
            secondLine.right.x > secondLine.left.x &&
            secondLine.right.y != 0 &&
            thirdLine.right.x > secondLine.right.x &&
            thirdLine.right.y == 0 &&
            forthLine.right.x > thirdLine.right.x &&
            forthLine.right.y == 0
        ) {
            uint256[] memory _lines = new uint256[](4);
            _lines[0] = secondLine.left.x;
            _lines[1] = secondLine.right.x;
            _lines[2] = secondLine.right.y;
            _lines[3] = thirdLine.right.x;
            return (true, _lines);
        }
        return (false, points);
    }

    function _isSBTShape(bytes memory fnMap)
        internal
        pure
        returns (bool isOk, uint256[] memory points)
    {
        uint256[] memory zippedLines = decodePolyline(fnMap);
        if (zippedLines.length != 3) {
            return (false, points);
        }
        LineSegment memory secondLine = unzipLineSegment(zippedLines[1]);
        LineSegment memory thirdLine = unzipLineSegment(zippedLines[2]);
        if (
            secondLine.left.x != 0 &&
            secondLine.left.y == 0 &&
            secondLine.right.x > secondLine.left.x &&
            secondLine.right.y != 0 &&
            thirdLine.right.x > secondLine.right.x &&
            thirdLine.right.y == secondLine.right.y
        ) {
            uint256[] memory _lines = new uint256[](3);
            _lines[0] = secondLine.left.x;
            _lines[1] = secondLine.right.x;
            _lines[2] = secondLine.right.y;
            return (true, _lines);
        }
        return (false, points);
    }

    function _isSBT(bytes memory fnMap)
        internal
        pure
        returns (bool isOk, uint256[] memory points)
    {
        uint256[] memory zippedLines = decodePolyline(fnMap);
        if (zippedLines.length != 2) {
            return (false, points);
        }
        LineSegment memory secondLine = unzipLineSegment(zippedLines[1]);

        if (
            secondLine.left.x != 0 &&
            secondLine.left.y == secondLine.left.x &&
            secondLine.right.x > secondLine.left.x &&
            secondLine.right.y == secondLine.left.y
        ) {
            uint256[] memory _lines = new uint256[](1);
            _lines[0] = secondLine.left.x;
            return (true, _lines);
        }

        return (false, points);
    }
}

// File: contracts/util/Time.sol

pragma solidity 0.6.6;

abstract contract Time {
    function _getBlockTimestampSec() internal view returns (uint256 unixtimesec) {
        unixtimesec = block.timestamp; // solhint-disable-line not-rely-on-time
    }
}

// File: contracts/generalizedDotc/BondExchange.sol

pragma solidity 0.6.6;









abstract contract BondExchange is UseSafeMath, Time {
    uint256 internal constant MIN_EXCHANGE_RATE_E8 = 0.000001 * 10**8;
    uint256 internal constant MAX_EXCHANGE_RATE_E8 = 1000000 * 10**8;

    int256 internal constant MAX_SPREAD_E8 = 10**8; // 100%

    /**
     * @dev the sum of decimalsOfBond of the bondMaker.
     * This value is constant by the restriction of `_assertBondMakerDecimals`.
     */
    uint8 internal constant DECIMALS_OF_BOND = 8;

    /**
     * @dev the sum of decimalsOfOraclePrice of the bondMaker.
     * This value is constant by the restriction of `_assertBondMakerDecimals`.
     */
    uint8 internal constant DECIMALS_OF_ORACLE_PRICE = 8;

    BondMakerInterface internal immutable _bondMakerContract;
    PriceOracleInterface internal immutable _priceOracleContract;
    VolatilityOracleInterface internal immutable _volatilityOracleContract;
    LatestPriceOracleInterface internal immutable _volumeCalculator;
    DetectBondShape internal immutable _bondShapeDetector;

    /**
     * @param bondMakerAddress is a bond maker contract.
     * @param volumeCalculatorAddress is a contract to convert the unit of a strike price to USD.
     */
    constructor(
        BondMakerInterface bondMakerAddress,
        VolatilityOracleInterface volatilityOracleAddress,
        LatestPriceOracleInterface volumeCalculatorAddress,
        DetectBondShape bondShapeDetector
    ) public {
        _assertBondMakerDecimals(bondMakerAddress);
        _bondMakerContract = bondMakerAddress;
        _priceOracleContract = bondMakerAddress.oracleAddress();
        _volatilityOracleContract = VolatilityOracleInterface(
            volatilityOracleAddress
        );
        _volumeCalculator = volumeCalculatorAddress;
        _bondShapeDetector = bondShapeDetector;
    }

    function bondMakerAddress() external view returns (BondMakerInterface) {
        return _bondMakerContract;
    }

    function volumeCalculatorAddress()
        external
        view
        returns (LatestPriceOracleInterface)
    {
        return _volumeCalculator;
    }

    /**
     * @dev Get the latest price (USD) and historical volatility using oracle.
     * If the oracle is not working, `latestPrice` reverts.
     * @return priceE8 (10^-8 USD)
     */
    function _getLatestPrice(LatestPriceOracleInterface oracle)
        internal
        returns (uint256 priceE8)
    {
        return oracle.latestPrice();
    }

    /**
     * @dev Get the implied volatility using oracle.
     * @return volatilityE8 (10^-8)
     */
    function _getVolatility(
        VolatilityOracleInterface oracle,
        uint64 untilMaturity
    ) internal view returns (uint256 volatilityE8) {
        return oracle.getVolatility(untilMaturity);
    }

    /**
     * @dev Returns bond tokenaddress, maturity,
     */
    function _getBond(BondMakerInterface bondMaker, bytes32 bondID)
        internal
        view
        returns (
            ERC20 bondToken,
            uint256 maturity,
            uint256 sbtStrikePrice,
            bytes32 fnMapID
        )
    {
        address bondTokenAddress;
        (bondTokenAddress, maturity, sbtStrikePrice, fnMapID) = bondMaker
            .getBond(bondID);

        // Revert if `bondTokenAddress` is zero.
        bondToken = ERC20(bondTokenAddress);
    }

    /**
     * @dev Removes a decimal gap from the first argument.
     */
    function _applyDecimalGap(
        uint256 baseAmount,
        uint8 decimalsOfBase,
        uint8 decimalsOfQuote
    ) internal pure returns (uint256 quoteAmount) {
        uint256 n;
        uint256 d;

        if (decimalsOfBase > decimalsOfQuote) {
            d = decimalsOfBase - decimalsOfQuote;
        } else if (decimalsOfBase < decimalsOfQuote) {
            n = decimalsOfQuote - decimalsOfBase;
        }

        // The consequent multiplication would overflow under extreme and non-blocking circumstances.
        require(n < 19 && d < 19, "decimal gap needs to be lower than 19");
        return baseAmount.mul(10**n).div(10**d);
    }

    function _calcBondPriceAndSpread(
        BondPricerInterface bondPricer,
        bytes32 bondID,
        int16 feeBaseE4
    ) internal returns (uint256 bondPriceE8, int256 spreadE8) {
        (, uint256 maturity, , ) = _getBond(_bondMakerContract, bondID);
        (
            bool isKnownBondType,
            BondType bondType,
            uint256[] memory points
        ) = _bondShapeDetector.getBondTypeByID(
            _bondMakerContract,
            bondID,
            BondType.NONE
        );
        require(isKnownBondType, "cannot calculate the price of this bond");

        uint256 untilMaturity = maturity.sub(
            _getBlockTimestampSec(),
            "the bond should not have expired"
        );
        uint256 oraclePriceE8 = _getLatestPrice(_priceOracleContract);
        uint256 oracleVolatilityE8 = _getVolatility(
            _volatilityOracleContract,
            untilMaturity.toUint64()
        );

        uint256 leverageE8;
        (bondPriceE8, leverageE8) = bondPricer.calcPriceAndLeverage(
            bondType,
            points,
            oraclePriceE8.toInt256(),
            oracleVolatilityE8.toInt256(),
            untilMaturity.toInt256()
        );
        spreadE8 = _calcSpread(oracleVolatilityE8, leverageE8, feeBaseE4);
    }

    function _calcSpread(
        uint256 oracleVolatilityE8,
        uint256 leverageE8,
        int16 feeBaseE4
    ) internal pure returns (int256 spreadE8) {
        uint256 volE8 = oracleVolatilityE8 < 10**8
            ? 10**8
            : oracleVolatilityE8 > 2 * 10**8
            ? 2 * 10**8
            : oracleVolatilityE8;
        uint256 volTimesLevE16 = volE8 * leverageE8;
        // assert(volTimesLevE16 < 200 * 10**16);
        spreadE8 =
            (feeBaseE4 *
                (
                    feeBaseE4 < 0 || volTimesLevE16 < 10**16
                        ? 10**16
                        : volTimesLevE16
                )
                    .toInt256()) /
            10**12;
        spreadE8 = spreadE8 > MAX_SPREAD_E8 ? MAX_SPREAD_E8 : spreadE8;
    }

    /**
     * @dev Calculate the exchange volume on the USD basis.
     */
    function _calcUsdPrice(uint256 amount) internal returns (uint256) {
        return amount.mul(_getLatestPrice(_volumeCalculator)) / 10**8;
    }

    /**
     * @dev Restirct the bond maker.
     */
    function _assertBondMakerDecimals(BondMakerInterface bondMaker)
        internal
        view
    {
        require(
            bondMaker.decimalsOfOraclePrice() == DECIMALS_OF_ORACLE_PRICE,
            "the decimals of oracle price must be 8"
        );
        require(
            bondMaker.decimalsOfBond() == DECIMALS_OF_BOND,
            "the decimals of bond token must be 8"
        );
    }

    function _assertExpectedPriceRange(
        uint256 actualAmount,
        uint256 expectedAmount,
        uint256 range
    ) internal pure {
        if (expectedAmount != 0) {
            require(
                actualAmount.mul(1000 + range).div(1000) >= expectedAmount,
                "out of expected price range"
            );
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol






/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/generalizedDotc/BondVsErc20Exchange.sol

pragma solidity 0.6.6;



abstract contract BondVsErc20Exchange is BondExchange {
    using SafeERC20 for ERC20;

    struct VsErc20Pool {
        address seller;
        ERC20 swapPairToken;
        LatestPriceOracleInterface swapPairOracle;
        BondPricerInterface bondPricer;
        int16 feeBaseE4;
        bool isBondSale;
    }
    mapping(bytes32 => VsErc20Pool) internal _vsErc20Pool;

    event LogCreateErc20ToBondPool(
        bytes32 indexed poolID,
        address indexed seller,
        address indexed swapPairAddress
    );

    event LogCreateBondToErc20Pool(
        bytes32 indexed poolID,
        address indexed seller,
        address indexed swapPairAddress
    );

    event LogUpdateVsErc20Pool(
        bytes32 indexed poolID,
        address swapPairOracleAddress,
        address bondPricerAddress,
        int16 feeBase // decimal: 4
    );

    event LogDeleteVsErc20Pool(bytes32 indexed poolID);

    event LogExchangeErc20ToBond(
        address indexed buyer,
        bytes32 indexed bondID,
        bytes32 indexed poolID,
        uint256 bondAmount, // decimal: 8
        uint256 swapPairAmount, // decimal: ERC20.decimals()
        uint256 volume // USD, decimal: 8
    );

    event LogExchangeBondToErc20(
        address indexed buyer,
        bytes32 indexed bondID,
        bytes32 indexed poolID,
        uint256 bondAmount, // decimal: 8
        uint256 swapPairAmount, // decimal: ERC20.decimals()
        uint256 volume // USD, decimal: 8
    );

    /**
     * @dev Reverts when the pool ID does not exist.
     */
    modifier isExsistentVsErc20Pool(bytes32 poolID) {
        require(
            _vsErc20Pool[poolID].seller != address(0),
            "the exchange pair does not exist"
        );
        _;
    }

    /**
     * @notice Exchange buyer's ERC20 token to the seller's bond.
     * @dev Ensure the seller has approved sufficient bonds and
     * you approve ERC20 token to pay before executing this function.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param swapPairAmount is the exchange pair token amount to pay.
     * @param expectedAmount is the bond amount to receive.
     * @param range (decimal: 3)
     */
    function exchangeErc20ToBond(
        bytes32 bondID,
        bytes32 poolID,
        uint256 swapPairAmount,
        uint256 expectedAmount,
        uint256 range
    ) external returns (uint256 bondAmount) {
        bondAmount = _exchangeErc20ToBond(
            msg.sender,
            bondID,
            poolID,
            swapPairAmount
        );
        // assert(bondAmount != 0);
        _assertExpectedPriceRange(bondAmount, expectedAmount, range);
    }

    /**
     * @notice Exchange buyer's bond to the seller's ERC20 token.
     * @dev Ensure the seller has approved sufficient ERC20 token and
     * you approve bonds to pay before executing this function.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param bondAmount is the bond amount to pay.
     * @param expectedAmount is the exchange pair token amount to receive.
     * @param range (decimal: 3)
     */
    function exchangeBondToErc20(
        bytes32 bondID,
        bytes32 poolID,
        uint256 bondAmount,
        uint256 expectedAmount,
        uint256 range
    ) external returns (uint256 swapPairAmount) {
        swapPairAmount = _exchangeBondToErc20(
            msg.sender,
            bondID,
            poolID,
            bondAmount
        );
        // assert(swapPairAmount != 0);
        _assertExpectedPriceRange(swapPairAmount, expectedAmount, range);
    }

    /**
     * @notice Returns the exchange rate including spread.
     */
    function calcRateBondToErc20(bytes32 bondID, bytes32 poolID)
        external
        returns (uint256 rateE8)
    {
        (rateE8, , , ) = _calcRateBondToErc20(bondID, poolID);
    }

    /**
     * @notice Returns pool ID generated by the immutable pool settings.
     */
    function generateVsErc20PoolID(
        address seller,
        address swapPairAddress,
        bool isBondSale
    ) external view returns (bytes32 poolID) {
        return _generateVsErc20PoolID(seller, swapPairAddress, isBondSale);
    }

    /**
     * @notice Register a new vsErc20Pool.
     */
    function createVsErc20Pool(
        ERC20 swapPairAddress,
        LatestPriceOracleInterface swapPairOracleAddress,
        BondPricerInterface bondPricerAddress,
        int16 feeBaseE4,
        bool isBondSale
    ) external returns (bytes32 poolID) {
        return
            _createVsErc20Pool(
                msg.sender,
                swapPairAddress,
                swapPairOracleAddress,
                bondPricerAddress,
                feeBaseE4,
                isBondSale
            );
    }

    /**
     * @notice Update the mutable pool settings.
     */
    function updateVsErc20Pool(
        bytes32 poolID,
        LatestPriceOracleInterface swapPairOracleAddress,
        BondPricerInterface bondPricerAddress,
        int16 feeBaseE4
    ) external {
        require(
            _vsErc20Pool[poolID].seller == msg.sender,
            "not the owner of the pool ID"
        );

        _updateVsErc20Pool(
            poolID,
            swapPairOracleAddress,
            bondPricerAddress,
            feeBaseE4
        );
    }

    /**
     * @notice Delete the pool settings.
     */
    function deleteVsErc20Pool(bytes32 poolID) external {
        require(
            _vsErc20Pool[poolID].seller == msg.sender,
            "not the owner of the pool ID"
        );

        _deleteVsErc20Pool(poolID);
    }

    /**
     * @notice Returns the pool settings.
     */
    function getVsErc20Pool(bytes32 poolID)
        external
        view
        returns (
            address seller,
            ERC20 swapPairAddress,
            LatestPriceOracleInterface swapPairOracleAddress,
            BondPricerInterface bondPricerAddress,
            int16 feeBaseE4,
            bool isBondSale
        )
    {
        return _getVsErc20Pool(poolID);
    }

    /**
     * @dev Exchange buyer's ERC20 token to the seller's bond.
     * Ensure the seller has approved sufficient bonds and
     * buyer approve ERC20 token to pay before executing this function.
     * @param buyer is the buyer address.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param swapPairAmount is the exchange pair token amount to pay.
     * @return bondAmount is the received bond amount.
     */
    function _exchangeErc20ToBond(
        address buyer,
        bytes32 bondID,
        bytes32 poolID,
        uint256 swapPairAmount
    ) internal returns (uint256 bondAmount) {
        (
            address seller,
            ERC20 swapPairToken,
            ,
            ,
            ,
            bool isBondSale
        ) = _getVsErc20Pool(poolID);
        require(isBondSale, "This pool is for buying bond");

        (ERC20 bondToken, , , ) = _getBond(_bondMakerContract, bondID);
        require(address(bondToken) != address(0), "the bond is not registered");

        uint256 volumeE8;
        {
            (
                uint256 rateE8,
                ,
                uint256 swapPairPriceE8,

            ) = _calcRateBondToErc20(bondID, poolID);
            require(
                rateE8 > MIN_EXCHANGE_RATE_E8,
                "exchange rate is too small"
            );
            require(
                rateE8 < MAX_EXCHANGE_RATE_E8,
                "exchange rate is too large"
            );
            uint8 decimalsOfSwapPair = swapPairToken.decimals();
            bondAmount =
                _applyDecimalGap(
                    swapPairAmount,
                    decimalsOfSwapPair,
                    DECIMALS_OF_BOND + 8
                ) /
                rateE8;
            require(bondAmount != 0, "must transfer non-zero bond amount");
            volumeE8 = swapPairPriceE8.mul(swapPairAmount).div(
                10**uint256(decimalsOfSwapPair)
            );
        }

        require(
            bondToken.transferFrom(seller, buyer, bondAmount),
            "fail to transfer bonds"
        );
        swapPairToken.safeTransferFrom(buyer, seller, swapPairAmount);

        emit LogExchangeErc20ToBond(
            buyer,
            bondID,
            poolID,
            bondAmount,
            swapPairAmount,
            volumeE8
        );
    }

    /**
     * @dev Exchange buyer's bond to the seller's ERC20 token.
     * Ensure the seller has approved sufficient ERC20 token and
     * buyer approve bonds to pay before executing this function.
     * @param buyer is the buyer address.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param bondAmount is the bond amount to pay.
     * @return swapPairAmount is the received swap pair token amount.
     */
    function _exchangeBondToErc20(
        address buyer,
        bytes32 bondID,
        bytes32 poolID,
        uint256 bondAmount
    ) internal returns (uint256 swapPairAmount) {
        (
            address seller,
            ERC20 swapPairToken,
            ,
            ,
            ,
            bool isBondSale
        ) = _getVsErc20Pool(poolID);
        require(!isBondSale, "This pool is not for buying bond");

        (ERC20 bondToken, , , ) = _getBond(_bondMakerContract, bondID);
        require(address(bondToken) != address(0), "the bond is not registered");

        uint256 volumeE8;
        {
            (uint256 rateE8, uint256 bondPriceE8, , ) = _calcRateBondToErc20(
                bondID,
                poolID
            );
            require(
                rateE8 > MIN_EXCHANGE_RATE_E8,
                "exchange rate is too small"
            );
            require(
                rateE8 < MAX_EXCHANGE_RATE_E8,
                "exchange rate is too large"
            );
            uint8 decimalsOfSwapPair = swapPairToken.decimals();
            swapPairAmount = _applyDecimalGap(
                bondAmount.mul(rateE8),
                DECIMALS_OF_BOND + 8,
                decimalsOfSwapPair
            );
            require(swapPairAmount != 0, "must transfer non-zero token amount");
            volumeE8 = bondPriceE8.mul(bondAmount).div(
                10**uint256(DECIMALS_OF_BOND)
            );
        }

        require(
            bondToken.transferFrom(buyer, seller, bondAmount),
            "fail to transfer bonds"
        );
        swapPairToken.safeTransferFrom(seller, buyer, swapPairAmount);

        emit LogExchangeBondToErc20(
            buyer,
            bondID,
            poolID,
            bondAmount,
            swapPairAmount,
            volumeE8
        );
    }

    function _calcRateBondToErc20(bytes32 bondID, bytes32 poolID)
        internal
        returns (
            uint256 rateE8,
            uint256 bondPriceE8,
            uint256 swapPairPriceE8,
            int256 spreadE8
        )
    {
        (
            ,
            ,
            LatestPriceOracleInterface erc20Oracle,
            BondPricerInterface bondPricer,
            int16 feeBaseE4,
            bool isBondSale
        ) = _getVsErc20Pool(poolID);
        swapPairPriceE8 = _getLatestPrice(erc20Oracle);
        (bondPriceE8, spreadE8) = _calcBondPriceAndSpread(
            bondPricer,
            bondID,
            feeBaseE4
        );
        bondPriceE8 = _calcUsdPrice(bondPriceE8);
        rateE8 = bondPriceE8.mul(10**8).div(
            swapPairPriceE8,
            "ERC20 oracle price must be non-zero"
        );

        // `spreadE8` is less than 0.15 * 10**8.
        if (isBondSale) {
            rateE8 = rateE8.mul(uint256(10**8 + spreadE8)) / 10**8;
        } else {
            rateE8 = rateE8.mul(10**8) / uint256(10**8 + spreadE8);
        }
    }

    function _generateVsErc20PoolID(
        address seller,
        address swapPairAddress,
        bool isBondSale
    ) internal view returns (bytes32 poolID) {
        return
            keccak256(
                abi.encode(
                    "Bond vs ERC20 exchange",
                    address(this),
                    seller,
                    swapPairAddress,
                    isBondSale
                )
            );
    }

    function _setVsErc20Pool(
        bytes32 poolID,
        address seller,
        ERC20 swapPairToken,
        LatestPriceOracleInterface swapPairOracle,
        BondPricerInterface bondPricer,
        int16 feeBaseE4,
        bool isBondSale
    ) internal {
        require(seller != address(0), "the pool ID already exists");
        require(
            address(swapPairToken) != address(0),
            "swapPairToken should be non-zero address"
        );
        require(
            address(swapPairOracle) != address(0),
            "swapPairOracle should be non-zero address"
        );
        require(
            address(bondPricer) != address(0),
            "bondPricer should be non-zero address"
        );
        _vsErc20Pool[poolID] = VsErc20Pool({
            seller: seller,
            swapPairToken: swapPairToken,
            swapPairOracle: swapPairOracle,
            bondPricer: bondPricer,
            feeBaseE4: feeBaseE4,
            isBondSale: isBondSale
        });
    }

    function _createVsErc20Pool(
        address seller,
        ERC20 swapPairToken,
        LatestPriceOracleInterface swapPairOracle,
        BondPricerInterface bondPricer,
        int16 feeBaseE4,
        bool isBondSale
    ) internal returns (bytes32 poolID) {
        poolID = _generateVsErc20PoolID(
            seller,
            address(swapPairToken),
            isBondSale
        );
        require(
            _vsErc20Pool[poolID].seller == address(0),
            "the pool ID already exists"
        );

        {
            uint256 price = _getLatestPrice(swapPairOracle);
            require(
                price != 0,
                "swapPairOracle has latestPrice() function which returns non-zero value"
            );
        }

        _setVsErc20Pool(
            poolID,
            seller,
            swapPairToken,
            swapPairOracle,
            bondPricer,
            feeBaseE4,
            isBondSale
        );

        if (isBondSale) {
            emit LogCreateErc20ToBondPool(
                poolID,
                seller,
                address(swapPairToken)
            );
        } else {
            emit LogCreateBondToErc20Pool(
                poolID,
                seller,
                address(swapPairToken)
            );
        }

        emit LogUpdateVsErc20Pool(
            poolID,
            address(swapPairOracle),
            address(bondPricer),
            feeBaseE4
        );
    }

    function _updateVsErc20Pool(
        bytes32 poolID,
        LatestPriceOracleInterface swapPairOracle,
        BondPricerInterface bondPricer,
        int16 feeBaseE4
    ) internal isExsistentVsErc20Pool(poolID) {
        (
            address seller,
            ERC20 swapPairToken,
            ,
            ,
            ,
            bool isBondSale
        ) = _getVsErc20Pool(poolID);
        _setVsErc20Pool(
            poolID,
            seller,
            swapPairToken,
            swapPairOracle,
            bondPricer,
            feeBaseE4,
            isBondSale
        );

        emit LogUpdateVsErc20Pool(
            poolID,
            address(swapPairOracle),
            address(bondPricer),
            feeBaseE4
        );
    }

    function _deleteVsErc20Pool(bytes32 poolID)
        internal
        isExsistentVsErc20Pool(poolID)
    {
        delete _vsErc20Pool[poolID];

        emit LogDeleteVsErc20Pool(poolID);
    }

    function _getVsErc20Pool(bytes32 poolID)
        internal
        view
        isExsistentVsErc20Pool(poolID)
        returns (
            address seller,
            ERC20 swapPairToken,
            LatestPriceOracleInterface swapPairOracle,
            BondPricerInterface bondPricer,
            int16 feeBaseE4,
            bool isBondSale
        )
    {
        VsErc20Pool memory exchangePair = _vsErc20Pool[poolID];
        seller = exchangePair.seller;
        swapPairToken = exchangePair.swapPairToken;
        swapPairOracle = exchangePair.swapPairOracle;
        bondPricer = exchangePair.bondPricer;
        feeBaseE4 = exchangePair.feeBaseE4;
        isBondSale = exchangePair.isBondSale;
    }
}

// File: contracts/util/TransferETH.sol

pragma solidity 0.6.6;


abstract contract TransferETH is TransferETHInterface {
    receive() external payable override {
        emit LogTransferETH(msg.sender, address(this), msg.value);
    }

    function _hasSufficientBalance(uint256 amount) internal view returns (bool ok) {
        address thisContract = address(this);
        return amount <= thisContract.balance;
    }

    /**
     * @notice transfer `amount` ETH to the `recipient` account with emitting log
     */
    function _transferETH(
        address payable recipient,
        uint256 amount,
        string memory errorMessage
    ) internal {
        require(_hasSufficientBalance(amount), errorMessage);
        (bool success, ) = recipient.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        require(success, "transferring Ether failed");
        emit LogTransferETH(address(this), recipient, amount);
    }

    function _transferETH(address payable recipient, uint256 amount) internal {
        _transferETH(recipient, amount, "TransferETH: transfer amount exceeds balance");
    }
}

// File: contracts/generalizedDotc/BondVsEthExchange.sol

pragma solidity 0.6.6;



abstract contract BondVsEthExchange is BondExchange, TransferETH {
    uint8 internal constant DECIMALS_OF_ETH = 18;

    struct VsEthPool {
        address seller;
        LatestPriceOracleInterface ethOracle;
        BondPricerInterface bondPricer;
        int16 feeBaseE4;
        bool isBondSale;
    }
    mapping(bytes32 => VsEthPool) internal _vsEthPool;

    mapping(address => uint256) internal _depositedEth;

    event LogCreateEthToBondPool(
        bytes32 indexed poolID,
        address indexed seller
    );

    event LogCreateBondToEthPool(
        bytes32 indexed poolID,
        address indexed seller
    );

    event LogUpdateVsEthPool(
        bytes32 indexed poolID,
        address ethOracleAddress,
        address bondPricerAddress,
        int16 feeBase // decimal: 4
    );

    event LogDeleteVsEthPool(bytes32 indexed poolID);

    event LogExchangeEthToBond(
        address indexed buyer,
        bytes32 indexed bondID,
        bytes32 indexed poolID,
        uint256 bondAmount, // decimal: 8
        uint256 swapPairAmount, // decimal: 18
        uint256 volume // USD, decimal: 8
    );

    event LogExchangeBondToEth(
        address indexed buyer,
        bytes32 indexed bondID,
        bytes32 indexed poolID,
        uint256 bondAmount, // decimal: 8
        uint256 swapPairAmount, // decimal: 18
        uint256 volume // USD, decimal: 8
    );

    /**
     * @dev Reverts when the pool ID does not exist.
     */
    modifier isExsistentVsEthPool(bytes32 poolID) {
        require(
            _vsEthPool[poolID].seller != address(0),
            "the exchange pair does not exist"
        );
        _;
    }

    /**
     * @notice Exchange buyer's ETH to the seller's bond.
     * @dev Ensure the seller has approved sufficient bonds and
     * you deposit ETH to pay before executing this function.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param ethAmount is the exchange pair token amount to pay.
     * @param expectedAmount is the bond amount to receive.
     * @param range (decimal: 3)
     */
    function exchangeEthToBond(
        bytes32 bondID,
        bytes32 poolID,
        uint256 ethAmount,
        uint256 expectedAmount,
        uint256 range
    ) external returns (uint256 bondAmount) {
        bondAmount = _exchangeEthToBond(msg.sender, bondID, poolID, ethAmount);
        // assert(bondAmount != 0);
        _assertExpectedPriceRange(bondAmount, expectedAmount, range);
    }

    /**
     * @notice Exchange buyer's bond to the seller's ETH.
     * @dev Ensure the seller has deposited sufficient ETH and
     * you approve bonds to pay before executing this function.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param bondAmount is the bond amount to pay.
     * @param expectedAmount is the ETH amount to receive.
     * @param range (decimal: 3)
     */
    function exchangeBondToEth(
        bytes32 bondID,
        bytes32 poolID,
        uint256 bondAmount,
        uint256 expectedAmount,
        uint256 range
    ) external returns (uint256 ethAmount) {
        ethAmount = _exchangeBondToEth(msg.sender, bondID, poolID, bondAmount);
        // assert(ethAmount != 0);
        _assertExpectedPriceRange(ethAmount, expectedAmount, range);
    }

    /**
     * @notice Returns the exchange rate including spread.
     */
    function calcRateBondToEth(bytes32 bondID, bytes32 poolID)
        external
        returns (uint256 rateE8)
    {
        (rateE8, , , ) = _calcRateBondToEth(bondID, poolID);
    }

    /**
     * @notice Returns pool ID generated by the immutable pool settings.
     */
    function generateVsEthPoolID(address seller, bool isBondSale)
        external
        view
        returns (bytes32 poolID)
    {
        return _generateVsEthPoolID(seller, isBondSale);
    }

    /**
     * @notice Register a new vsEthPool.
     */
    function createVsEthPool(
        LatestPriceOracleInterface ethOracleAddress,
        BondPricerInterface bondPricerAddress,
        int16 feeBaseE4,
        bool isBondSale
    ) external returns (bytes32 poolID) {
        return
            _createVsEthPool(
                msg.sender,
                ethOracleAddress,
                bondPricerAddress,
                feeBaseE4,
                isBondSale
            );
    }

    /**
     * @notice Update the mutable pool settings.
     */
    function updateVsEthPool(
        bytes32 poolID,
        LatestPriceOracleInterface ethOracleAddress,
        BondPricerInterface bondPricerAddress,
        int16 feeBaseE4
    ) external {
        require(
            _vsEthPool[poolID].seller == msg.sender,
            "not the owner of the pool ID"
        );

        _updateVsEthPool(
            poolID,
            ethOracleAddress,
            bondPricerAddress,
            feeBaseE4
        );
    }

    /**
     * @notice Delete the pool settings.
     */
    function deleteVsEthPool(bytes32 poolID) external {
        require(
            _vsEthPool[poolID].seller == msg.sender,
            "not the owner of the pool ID"
        );

        _deleteVsEthPool(poolID);
    }

    /**
     * @notice Returns the pool settings.
     */
    function getVsEthPool(bytes32 poolID)
        external
        view
        returns (
            address seller,
            LatestPriceOracleInterface ethOracleAddress,
            BondPricerInterface bondPricerAddress,
            int16 feeBaseE4,
            bool isBondSale
        )
    {
        return _getVsEthPool(poolID);
    }

    /**
     * @notice Transfer ETH to this contract and allow this contract to pay ETH when exchanging.
     */
    function depositEth() external payable {
        _addEthAllowance(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw all deposited ETH.
     */
    function withdrawEth() external returns (uint256 amount) {
        amount = _depositedEth[msg.sender];
        _transferEthFrom(msg.sender, msg.sender, amount);
    }

    /**
     * @notice Returns deposited ETH amount.
     */
    function ethAllowance(address owner)
        external
        view
        returns (uint256 amount)
    {
        amount = _depositedEth[owner];
    }

    /**
     * @dev Exchange buyer's ETH to the seller's bond.
     * Ensure the seller has approved sufficient bonds and
     * buyer deposit ETH to pay before executing this function.
     * @param buyer is the buyer address.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param swapPairAmount is the exchange pair token amount to pay.
     * @return bondAmount is the received bond amount.
     */
    function _exchangeEthToBond(
        address buyer,
        bytes32 bondID,
        bytes32 poolID,
        uint256 swapPairAmount
    ) internal returns (uint256 bondAmount) {
        (address seller, , , , bool isBondSale) = _getVsEthPool(poolID);
        require(isBondSale, "This pool is for buying bond");

        (ERC20 bondToken, , , ) = _getBond(_bondMakerContract, bondID);
        require(address(bondToken) != address(0), "the bond is not registered");

        uint256 volumeE8;
        {
            (uint256 rateE8, , uint256 swapPairPriceE8, ) = _calcRateBondToEth(
                bondID,
                poolID
            );
            require(
                rateE8 > MIN_EXCHANGE_RATE_E8,
                "exchange rate is too small"
            );
            require(
                rateE8 < MAX_EXCHANGE_RATE_E8,
                "exchange rate is too large"
            );
            bondAmount =
                _applyDecimalGap(
                    swapPairAmount,
                    DECIMALS_OF_ETH,
                    DECIMALS_OF_BOND + 8
                ) /
                rateE8;
            require(bondAmount != 0, "must transfer non-zero bond amount");
            volumeE8 = swapPairPriceE8.mul(swapPairAmount).div(
                10**uint256(DECIMALS_OF_ETH)
            );
        }

        require(
            bondToken.transferFrom(seller, buyer, bondAmount),
            "fail to transfer bonds"
        );
        _transferEthFrom(buyer, seller, swapPairAmount);

        emit LogExchangeEthToBond(
            buyer,
            bondID,
            poolID,
            bondAmount,
            swapPairAmount,
            volumeE8
        );
    }

    /**
     * @dev Exchange buyer's bond to the seller's ETH.
     * Ensure the seller has deposited sufficient ETH and
     * buyer approve bonds to pay before executing this function.
     * @param buyer is the buyer address.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param bondAmount is the bond amount to pay.
     * @return swapPairAmount is the received ETH amount.
     */
    function _exchangeBondToEth(
        address buyer,
        bytes32 bondID,
        bytes32 poolID,
        uint256 bondAmount
    ) internal returns (uint256 swapPairAmount) {
        (address seller, , , , bool isBondSale) = _getVsEthPool(poolID);
        require(!isBondSale, "This pool is not for buying bond");

        (ERC20 bondToken, , , ) = _getBond(_bondMakerContract, bondID);
        require(address(bondToken) != address(0), "the bond is not registered");

        uint256 volumeE8;
        {
            (uint256 rateE8, uint256 bondPriceE8, , ) = _calcRateBondToEth(
                bondID,
                poolID
            );
            require(
                rateE8 > MIN_EXCHANGE_RATE_E8,
                "exchange rate is too small"
            );
            require(
                rateE8 < MAX_EXCHANGE_RATE_E8,
                "exchange rate is too large"
            );
            swapPairAmount = _applyDecimalGap(
                bondAmount.mul(rateE8),
                DECIMALS_OF_BOND + 8,
                DECIMALS_OF_ETH
            );
            require(swapPairAmount != 0, "must transfer non-zero token amount");
            volumeE8 = bondPriceE8.mul(bondAmount).div(
                10**uint256(DECIMALS_OF_BOND)
            );
        }

        require(
            bondToken.transferFrom(buyer, seller, bondAmount),
            "fail to transfer bonds"
        );
        _transferEthFrom(seller, buyer, swapPairAmount);

        emit LogExchangeBondToEth(
            buyer,
            bondID,
            poolID,
            bondAmount,
            swapPairAmount,
            volumeE8
        );
    }

    function _calcRateBondToEth(bytes32 bondID, bytes32 poolID)
        internal
        returns (
            uint256 rateE8,
            uint256 bondPriceE8,
            uint256 swapPairPriceE8,
            int256 spreadE8
        )
    {
        (
            ,
            LatestPriceOracleInterface ethOracle,
            BondPricerInterface bondPricer,
            int16 feeBaseE4,
            bool isBondSale
        ) = _getVsEthPool(poolID);
        swapPairPriceE8 = _getLatestPrice(ethOracle);
        (bondPriceE8, spreadE8) = _calcBondPriceAndSpread(
            bondPricer,
            bondID,
            feeBaseE4
        );
        bondPriceE8 = _calcUsdPrice(bondPriceE8);
        rateE8 = bondPriceE8.mul(10**8).div(
            swapPairPriceE8,
            "ERC20 oracle price must be non-zero"
        );

        // `spreadE8` is less than 0.15 * 10**8.
        if (isBondSale) {
            rateE8 = rateE8.mul(uint256(10**8 + spreadE8)) / 10**8;
        } else {
            rateE8 = rateE8.mul(uint256(10**8 - spreadE8)) / 10**8;
        }
    }

    function _generateVsEthPoolID(address seller, bool isBondSale)
        internal
        view
        returns (bytes32 poolID)
    {
        return
            keccak256(
                abi.encode(
                    "Bond vs ETH exchange",
                    address(this),
                    seller,
                    isBondSale
                )
            );
    }

    function _setVsEthPool(
        bytes32 poolID,
        address seller,
        LatestPriceOracleInterface ethOracle,
        BondPricerInterface bondPricer,
        int16 feeBaseE4,
        bool isBondSale
    ) internal {
        require(seller != address(0), "the pool ID already exists");
        require(
            address(ethOracle) != address(0),
            "ethOracle should be non-zero address"
        );
        require(
            address(bondPricer) != address(0),
            "bondPricer should be non-zero address"
        );
        _vsEthPool[poolID] = VsEthPool({
            seller: seller,
            ethOracle: ethOracle,
            bondPricer: bondPricer,
            feeBaseE4: feeBaseE4,
            isBondSale: isBondSale
        });
    }

    function _createVsEthPool(
        address seller,
        LatestPriceOracleInterface ethOracle,
        BondPricerInterface bondPricer,
        int16 feeBaseE4,
        bool isBondSale
    ) internal returns (bytes32 poolID) {
        poolID = _generateVsEthPoolID(seller, isBondSale);
        require(
            _vsEthPool[poolID].seller == address(0),
            "the pool ID already exists"
        );

        {
            uint256 price = ethOracle.latestPrice();
            require(
                price != 0,
                "ethOracle has latestPrice() function which returns non-zero value"
            );
        }

        _setVsEthPool(
            poolID,
            seller,
            ethOracle,
            bondPricer,
            feeBaseE4,
            isBondSale
        );

        if (isBondSale) {
            emit LogCreateEthToBondPool(poolID, seller);
        } else {
            emit LogCreateBondToEthPool(poolID, seller);
        }

        emit LogUpdateVsEthPool(
            poolID,
            address(ethOracle),
            address(bondPricer),
            feeBaseE4
        );
    }

    function _updateVsEthPool(
        bytes32 poolID,
        LatestPriceOracleInterface ethOracle,
        BondPricerInterface bondPricer,
        int16 feeBaseE4
    ) internal isExsistentVsEthPool(poolID) {
        (address seller, , , , bool isBondSale) = _getVsEthPool(poolID);
        _setVsEthPool(
            poolID,
            seller,
            ethOracle,
            bondPricer,
            feeBaseE4,
            isBondSale
        );

        emit LogUpdateVsEthPool(
            poolID,
            address(ethOracle),
            address(bondPricer),
            feeBaseE4
        );
    }

    function _deleteVsEthPool(bytes32 poolID)
        internal
        isExsistentVsEthPool(poolID)
    {
        delete _vsEthPool[poolID];

        emit LogDeleteVsEthPool(poolID);
    }

    function _getVsEthPool(bytes32 poolID)
        internal
        view
        isExsistentVsEthPool(poolID)
        returns (
            address seller,
            LatestPriceOracleInterface ethOracle,
            BondPricerInterface bondPricer,
            int16 feeBaseE4,
            bool isBondSale
        )
    {
        VsEthPool memory exchangePair = _vsEthPool[poolID];
        seller = exchangePair.seller;
        ethOracle = exchangePair.ethOracle;
        bondPricer = exchangePair.bondPricer;
        feeBaseE4 = exchangePair.feeBaseE4;
        isBondSale = exchangePair.isBondSale;
    }

    function _transferEthFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _subEthAllowance(sender, amount);
        _transferETH(payable(recipient), amount);
    }

    function _addEthAllowance(address sender, uint256 amount) internal {
        _depositedEth[sender] += amount;
        require(_depositedEth[sender] >= amount, "overflow allowance");
    }

    function _subEthAllowance(address owner, uint256 amount) internal {
        require(_depositedEth[owner] >= amount, "insufficient allowance");
        _depositedEth[owner] -= amount;
    }
}

// File: contracts/generalizedDotc/BondVsBondExchange.sol

pragma solidity 0.6.6;


abstract contract BondVsBondExchange is BondExchange {
    /**
     * @dev the sum of decimalsOfBond and decimalsOfOraclePrice of the bondMaker.
     * This value is constant by the restriction of `_assertBondMakerDecimals`.
     */
    uint8 internal constant DECIMALS_OF_BOND_VALUE = DECIMALS_OF_BOND +
        DECIMALS_OF_ORACLE_PRICE;

    struct VsBondPool {
        address seller;
        BondMakerInterface bondMakerForUser;
        VolatilityOracleInterface volatilityOracle;
        BondPricerInterface bondPricerForUser;
        BondPricerInterface bondPricer;
        int16 feeBaseE4;
    }
    mapping(bytes32 => VsBondPool) internal _vsBondPool;

    event LogCreateBondToBondPool(
        bytes32 indexed poolID,
        address indexed seller,
        address indexed bondMakerForUser
    );

    event LogUpdateVsBondPool(
        bytes32 indexed poolID,
        address bondPricerForUser,
        address bondPricer,
        int16 feeBase // decimal: 4
    );

    event LogDeleteVsBondPool(bytes32 indexed poolID);

    event LogExchangeBondToBond(
        address indexed buyer,
        bytes32 indexed bondID,
        bytes32 indexed poolID,
        uint256 bondAmount, // decimal: 8
        uint256 swapPairAmount, // USD, decimal: 8
        uint256 volume // USD, decimal: 8
    );

    /**
     * @dev Reverts when the pool ID does not exist.
     */
    modifier isExsistentVsBondPool(bytes32 poolID) {
        require(
            _vsBondPool[poolID].seller != address(0),
            "the exchange pair does not exist"
        );
        _;
    }

    /**
     * @notice Exchange the seller's bond to buyer's multiple bonds.
     * @dev Ensure the seller has approved sufficient bonds and
     * Approve bonds to pay before executing this function.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param amountInDollarsE8 is the exchange pair token amount to pay. (decimals: 8)
     * @param expectedAmount is the bond amount to receive. (decimals: 8)
     * @param range (decimal: 3)
     */
    function exchangeBondToBond(
        bytes32 bondID,
        bytes32 poolID,
        bytes32[] calldata bondIDs,
        uint256 amountInDollarsE8,
        uint256 expectedAmount,
        uint256 range
    ) external returns (uint256 bondAmount) {
        uint256 amountInDollars = _applyDecimalGap(
            amountInDollarsE8,
            8,
            DECIMALS_OF_BOND_VALUE
        );
        bondAmount = _exchangeBondToBond(
            msg.sender,
            bondID,
            poolID,
            bondIDs,
            amountInDollars
        );
        _assertExpectedPriceRange(bondAmount, expectedAmount, range);
    }

    /**
     * @notice Returns the exchange rate including spread.
     */
    function calcRateBondToUsd(bytes32 bondID, bytes32 poolID)
        external
        returns (uint256 rateE8)
    {
        (rateE8, , , ) = _calcRateBondToUsd(bondID, poolID);
    }

    /**
     * @notice Returns pool ID generated by the immutable pool settings.
     */
    function generateVsBondPoolID(address seller, address bondMakerForUser)
        external
        view
        returns (bytes32 poolID)
    {
        return _generateVsBondPoolID(seller, bondMakerForUser);
    }

    /**
     * @notice Register a new vsBondPool.
     */
    function createVsBondPool(
        BondMakerInterface bondMakerForUserAddress,
        VolatilityOracleInterface volatilityOracleAddress,
        BondPricerInterface bondPricerForUserAddress,
        BondPricerInterface bondPricerAddress,
        int16 feeBaseE4
    ) external returns (bytes32 poolID) {
        return
            _createVsBondPool(
                msg.sender,
                bondMakerForUserAddress,
                volatilityOracleAddress,
                bondPricerForUserAddress,
                bondPricerAddress,
                feeBaseE4
            );
    }

    /**
     * @notice Update the mutable pool settings.
     */
    function updateVsBondPool(
        bytes32 poolID,
        VolatilityOracleInterface volatilityOracleAddress,
        BondPricerInterface bondPricerForUserAddress,
        BondPricerInterface bondPricerAddress,
        int16 feeBaseE4
    ) external {
        require(
            _vsBondPool[poolID].seller == msg.sender,
            "not the owner of the pool ID"
        );

        _updateVsBondPool(
            poolID,
            volatilityOracleAddress,
            bondPricerForUserAddress,
            bondPricerAddress,
            feeBaseE4
        );
    }

    /**
     * @notice Delete the pool settings.
     */
    function deleteVsBondPool(bytes32 poolID) external {
        require(
            _vsBondPool[poolID].seller == msg.sender,
            "not the owner of the pool ID"
        );

        _deleteVsBondPool(poolID);
    }

    /**
     * @notice Returns the pool settings.
     */
    function getVsBondPool(bytes32 poolID)
        external
        view
        returns (
            address seller,
            BondMakerInterface bondMakerForUserAddress,
            VolatilityOracleInterface volatilityOracle,
            BondPricerInterface bondPricerForUserAddress,
            BondPricerInterface bondPricerAddress,
            int16 feeBaseE4,
            bool isBondSale
        )
    {
        return _getVsBondPool(poolID);
    }

    /**
     * @notice Returns the total approved bond amount in U.S. dollars.
     * Unnecessary bond must not be included in bondIDs.
     */
    function totalBondAllowance(
        bytes32 poolID,
        bytes32[] calldata bondIDs,
        uint256 maturityBorder,
        address owner
    ) external returns (uint256 allowanceInDollarsE8) {
        (
            ,
            BondMakerInterface bondMakerForUser,
            VolatilityOracleInterface volatilityOracle,
            BondPricerInterface bondPricerForUser,
            ,
            ,

        ) = _getVsBondPool(poolID);
        uint256 allowanceInDollars = _totalBondAllowance(
            bondMakerForUser,
            volatilityOracle,
            bondPricerForUser,
            bondIDs,
            maturityBorder,
            owner
        );
        allowanceInDollarsE8 = _applyDecimalGap(
            allowanceInDollars,
            DECIMALS_OF_BOND_VALUE,
            8
        );
    }

    /**
     * @dev Exchange the seller's bond to buyer's multiple bonds.
     * Ensure the seller has approved sufficient bonds and
     * buyer approve bonds to pay before executing this function.
     * @param buyer is the buyer address.
     * @param bondID is the target bond ID.
     * @param poolID is the target pool ID.
     * @param amountInDollars is the exchange pair token amount to pay. (decimals: 16)
     * @return bondAmount is the received bond amount.
     */
    function _exchangeBondToBond(
        address buyer,
        bytes32 bondID,
        bytes32 poolID,
        bytes32[] memory bondIDs,
        uint256 amountInDollars
    ) internal returns (uint256 bondAmount) {
        require(bondIDs.length != 0, "must input bonds for payment");

        BondMakerInterface bondMakerForUser;
        {
            bool isBondSale;
            (, bondMakerForUser, , , , , isBondSale) = _getVsBondPool(poolID);
            require(isBondSale, "This pool is for buying bond");
        }

        (ERC20 bondToken, uint256 maturity, , ) = _getBond(
            _bondMakerContract,
            bondID
        );
        require(address(bondToken) != address(0), "the bond is not registered");

        {
            (uint256 rateE8, , , ) = _calcRateBondToUsd(bondID, poolID);
            require(
                rateE8 > MIN_EXCHANGE_RATE_E8,
                "exchange rate is too small"
            );
            require(
                rateE8 < MAX_EXCHANGE_RATE_E8,
                "exchange rate is too large"
            );
            bondAmount =
                _applyDecimalGap(
                    amountInDollars,
                    DECIMALS_OF_BOND_VALUE,
                    bondToken.decimals() + 8
                ) /
                rateE8;
            require(bondAmount != 0, "must transfer non-zero bond amount");
        }

        {
            (
                address seller,
                ,
                VolatilityOracleInterface volatilityOracle,
                BondPricerInterface bondPricerForUser,
                ,
                ,

            ) = _getVsBondPool(poolID);
            require(
                bondToken.transferFrom(seller, buyer, bondAmount),
                "fail to transfer bonds"
            );

            address buyerTmp = buyer; // avoid `stack too deep` error
            uint256 amountInDollarsTmp = amountInDollars; // avoid `stack too deep` error
            require(
                _batchTransferBondFrom(
                    bondMakerForUser,
                    volatilityOracle,
                    bondPricerForUser,
                    bondIDs,
                    maturity,
                    buyerTmp,
                    seller,
                    amountInDollarsTmp
                ),
                "fail to transfer ERC20 token"
            );
        }

        uint256 volumeE8 = _applyDecimalGap(
            amountInDollars,
            DECIMALS_OF_BOND_VALUE,
            8
        );
        emit LogExchangeBondToBond(
            buyer,
            bondID,
            poolID,
            bondAmount,
            amountInDollars,
            volumeE8
        );
    }

    function _calcRateBondToUsd(bytes32 bondID, bytes32 poolID)
        internal
        returns (
            uint256 rateE8,
            uint256 bondPriceE8,
            uint256 swapPairPriceE8,
            int256 spreadE8
        )
    {
        (
            ,
            ,
            ,
            ,
            BondPricerInterface bondPricer,
            int16 feeBaseE4,

        ) = _getVsBondPool(poolID);
        (bondPriceE8, spreadE8) = _calcBondPriceAndSpread(
            bondPricer,
            bondID,
            feeBaseE4
        );
        bondPriceE8 = _calcUsdPrice(bondPriceE8);
        swapPairPriceE8 = 10**8;
        rateE8 = bondPriceE8.mul(uint256(10**8 + spreadE8)) / 10**8;
    }

    function _generateVsBondPoolID(address seller, address bondMakerForUser)
        internal
        view
        returns (bytes32 poolID)
    {
        return
            keccak256(
                abi.encode(
                    "Bond vs SBT exchange",
                    address(this),
                    seller,
                    bondMakerForUser
                )
            );
    }

    function _setVsBondPool(
        bytes32 poolID,
        address seller,
        BondMakerInterface bondMakerForUser,
        VolatilityOracleInterface volatilityOracle,
        BondPricerInterface bondPricerForUser,
        BondPricerInterface bondPricer,
        int16 feeBaseE4
    ) internal {
        require(seller != address(0), "the pool ID already exists");
        require(
            address(bondMakerForUser) != address(0),
            "bondMakerForUser should be non-zero address"
        );
        require(
            address(bondPricerForUser) != address(0),
            "bondPricerForUser should be non-zero address"
        );
        require(
            address(bondPricer) != address(0),
            "bondPricer should be non-zero address"
        );
        _assertBondMakerDecimals(bondMakerForUser);
        _vsBondPool[poolID] = VsBondPool({
            seller: seller,
            bondMakerForUser: bondMakerForUser,
            volatilityOracle: volatilityOracle,
            bondPricerForUser: bondPricerForUser,
            bondPricer: bondPricer,
            feeBaseE4: feeBaseE4
        });
    }

    function _createVsBondPool(
        address seller,
        BondMakerInterface bondMakerForUser,
        VolatilityOracleInterface volatilityOracle,
        BondPricerInterface bondPricerForUser,
        BondPricerInterface bondPricer,
        int16 feeBaseE4
    ) internal returns (bytes32 poolID) {
        poolID = _generateVsBondPoolID(seller, address(bondMakerForUser));
        require(
            _vsBondPool[poolID].seller == address(0),
            "the pool ID already exists"
        );

        _assertBondMakerDecimals(bondMakerForUser);
        _setVsBondPool(
            poolID,
            seller,
            bondMakerForUser,
            volatilityOracle,
            bondPricerForUser,
            bondPricer,
            feeBaseE4
        );

        emit LogCreateBondToBondPool(poolID, seller, address(bondMakerForUser));
        emit LogUpdateVsBondPool(
            poolID,
            address(bondPricerForUser),
            address(bondPricer),
            feeBaseE4
        );
    }

    function _updateVsBondPool(
        bytes32 poolID,
        VolatilityOracleInterface volatilityOracle,
        BondPricerInterface bondPricerForUser,
        BondPricerInterface bondPricer,
        int16 feeBaseE4
    ) internal isExsistentVsBondPool(poolID) {
        (
            address seller,
            BondMakerInterface bondMakerForUser,
            ,
            ,
            ,
            ,

        ) = _getVsBondPool(poolID);
        _setVsBondPool(
            poolID,
            seller,
            bondMakerForUser,
            volatilityOracle,
            bondPricerForUser,
            bondPricer,
            feeBaseE4
        );

        emit LogUpdateVsBondPool(
            poolID,
            address(bondPricerForUser),
            address(bondPricer),
            feeBaseE4
        );
    }

    function _deleteVsBondPool(bytes32 poolID)
        internal
        isExsistentVsBondPool(poolID)
    {
        delete _vsBondPool[poolID];

        emit LogDeleteVsBondPool(poolID);
    }

    function _getVsBondPool(bytes32 poolID)
        internal
        view
        isExsistentVsBondPool(poolID)
        returns (
            address seller,
            BondMakerInterface bondMakerForUser,
            VolatilityOracleInterface volatilityOracle,
            BondPricerInterface bondPricerForUser,
            BondPricerInterface bondPricer,
            int16 feeBaseE4,
            bool isBondSale
        )
    {
        VsBondPool memory exchangePair = _vsBondPool[poolID];
        seller = exchangePair.seller;
        bondMakerForUser = exchangePair.bondMakerForUser;
        volatilityOracle = exchangePair.volatilityOracle;
        bondPricerForUser = exchangePair.bondPricerForUser;
        bondPricer = exchangePair.bondPricer;
        feeBaseE4 = exchangePair.feeBaseE4;
        isBondSale = true;
    }

    /**
     * @dev Transfer multiple bonds in one method.
     * Unnecessary bonds can be included in bondIDs.
     */
    function _batchTransferBondFrom(
        BondMakerInterface bondMaker,
        VolatilityOracleInterface volatilityOracle,
        BondPricerInterface bondPricer,
        bytes32[] memory bondIDs,
        uint256 maturityBorder,
        address sender,
        address recipient,
        uint256 amountInDollars
    ) internal returns (bool ok) {
        uint256 oraclePriceE8 = _getLatestPrice(bondMaker.oracleAddress());

        uint256 rest = amountInDollars; // mutable
        for (uint256 i = 0; i < bondIDs.length; i++) {
            ERC20 bond;
            uint256 oracleVolE8;
            {
                uint256 maturity;
                (bond, maturity, , ) = _getBond(bondMaker, bondIDs[i]);
                if (maturity > maturityBorder) continue; // skip transaction
                uint256 untilMaturity = maturity.sub(
                    _getBlockTimestampSec(),
                    "the bond should not have expired"
                );
                oracleVolE8 = _getVolatility(
                    volatilityOracle,
                    untilMaturity.toUint64()
                );
            }

            uint256 allowance = bond.allowance(sender, address(this));
            if (allowance == 0) continue; // skip transaction

            BondMakerInterface bondMakerTmp = bondMaker; // avoid `stack too deep` error
            BondPricerInterface bondPricerTmp = bondPricer; // avoid `stack too deep` error
            bytes32 bondIDTmp = bondIDs[i]; // avoid `stack too deep` error
            uint256 bondPrice = _calcBondPrice(
                bondMakerTmp,
                bondPricerTmp,
                bondIDTmp,
                oraclePriceE8,
                oracleVolE8
            );
            if (bondPrice == 0) continue; // skip transaction

            if (rest <= allowance.mul(bondPrice)) {
                // assert(ceil(rest / bondPrice) <= allowance);
                return
                    bond.transferFrom(
                        sender,
                        recipient,
                        rest.divRoundUp(bondPrice)
                    );
            }

            require(
                bond.transferFrom(sender, recipient, allowance),
                "fail to transfer bonds"
            );
            rest -= allowance * bondPrice;
        }

        revert("insufficient bond allowance");
    }

    /**
     * @dev Returns the total approved bond amount in U.S. dollars.
     * Unnecessary bond must not be included in bondIDs.
     */
    function _totalBondAllowance(
        BondMakerInterface bondMaker,
        VolatilityOracleInterface volatilityOracle,
        BondPricerInterface bondPricer,
        bytes32[] memory bondIDs,
        uint256 maturityBorder,
        address sender
    ) internal returns (uint256 allowanceInDollars) {
        uint256 oraclePriceE8 = _getLatestPrice(bondMaker.oracleAddress());

        for (uint256 i = 0; i < bondIDs.length; i++) {
            ERC20 bond;
            uint256 oracleVolE8;
            {
                uint256 maturity;
                (bond, maturity, , ) = _getBond(bondMaker, bondIDs[i]);
                if (maturity > maturityBorder) continue; // skip
                uint256 untilMaturity = maturity.sub(
                    _getBlockTimestampSec(),
                    "the bond should not have expired"
                );
                oracleVolE8 = _getVolatility(
                    volatilityOracle,
                    untilMaturity.toUint64()
                );
            }

            uint256 balance = bond.balanceOf(sender);
            require(balance != 0, "includes no bond balance");

            uint256 allowance = bond.allowance(sender, address(this));
            require(allowance != 0, "includes no approved bond");

            uint256 bondPrice = _calcBondPrice(
                bondMaker,
                bondPricer,
                bondIDs[i],
                oraclePriceE8,
                oracleVolE8
            );
            require(bondPrice != 0, "includes worthless bond");

            allowanceInDollars = allowanceInDollars.add(
                allowance.mul(bondPrice)
            );
        }
    }

    /**
     * @dev Calculate bond price by bond ID.
     */
    function _calcBondPrice(
        BondMakerInterface bondMaker,
        BondPricerInterface bondPricer,
        bytes32 bondID,
        uint256 oraclePriceE8,
        uint256 oracleVolatilityE8
    ) internal view returns (uint256) {
        int256 untilMaturity;
        {
            (, uint256 maturity, , ) = _getBond(bondMaker, bondID);
            untilMaturity = maturity
                .sub(
                _getBlockTimestampSec(),
                "the bond should not have expired"
            )
                .toInt256();
        }

        BondType bondType;
        uint256[] memory points;
        {
            bool isKnownBondType;
            (isKnownBondType, bondType, points) = _bondShapeDetector
                .getBondTypeByID(bondMaker, bondID, BondType.NONE);
            if (!isKnownBondType) {
                revert("unknown bond type");
                // return 0;
            }
        }

        try
            bondPricer.calcPriceAndLeverage(
                bondType,
                points,
                oraclePriceE8.toInt256(),
                oracleVolatilityE8.toInt256(),
                untilMaturity
            )
        returns (uint256 bondPriceE8, uint256) {
            return bondPriceE8;
        } catch {
            return 0;
        }
    }
}

// File: contracts/generalizedDotc/GeneralizedDotc.sol

pragma solidity 0.6.6;




contract GeneralizedDotc is
    BondVsBondExchange,
    BondVsErc20Exchange,
    BondVsEthExchange
{
    constructor(
        BondMakerInterface bondMakerAddress,
        VolatilityOracleInterface volatilityOracleAddress,
        LatestPriceOracleInterface volumeCalculatorAddress,
        DetectBondShape bondShapeDetector
    )
        public
        BondExchange(
            bondMakerAddress,
            volatilityOracleAddress,
            volumeCalculatorAddress,
            bondShapeDetector
        )
    {}
}