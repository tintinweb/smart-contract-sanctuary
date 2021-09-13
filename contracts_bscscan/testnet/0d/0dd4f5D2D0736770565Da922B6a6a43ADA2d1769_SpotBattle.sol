/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: BEP20.sol



pragma solidity 0.8.0;

interface IBEP20 {
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
}


pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BEP20 is Ownable, IBEP20 {
    using SafeMath for uint256;

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
    // constructor (string memory name, string memory symbol) public {
    //     _name = name;
    //     _symbol = symbol;
    //     _decimals = 18;
    // }
    
    function constructor1 (string memory name, string memory symbol) internal {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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

    function getOwner() public view virtual override returns (address) {
        return owner();
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
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
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
    function balanceOf(address account) public virtual view override returns (uint256) {
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
    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
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
     * Requirements:
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
     * Requirements:
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

// File: Spot.sol

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

}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

   

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract DataLayout is LibraryLock {
    address[] public markets;
    address public owner;
    address public versusToken;

    struct marketStruct {
        uint256 round;
        uint targetPrice;
        uint256 longBNB;
        uint256 shortBNB;
        uint256 roundEnd;
        address[] currentEntrants;
        uint256 nextRoundLong;
        uint256 nextRoundShort;
        address[] nextEntrants;
        uint[] targetHistory;
        uint256[] longHistory;
        uint256[] shortHistory;
        uint[] closingHistory;
    }
    mapping(address => marketStruct) public marketData; 
    mapping(address => mapping(uint256 => mapping(address => bool))) public entrantData;
    mapping(address => mapping(uint256 => mapping(address => bool))) public entrantPosition;

   
    //user => index => token address
    mapping(address => mapping(uint256 => address)) public userTokenHistory;
    //user => index => token address => round
    mapping(address => mapping(uint256 => mapping(address => uint256))) public userTokenRoundHistory;
    //user => index => token address => round => BNB
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) public userBNBHistory;
    //user => index => token address => round => bool
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public userPositionHistory;
    //user => index => token address => round => bool
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public userFreePredictionHistory;
    //user => index => token address => round => bool
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public userClaimHistory;
    //user => index => token address => round => winnings
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) public userWinHistory;
    //user => index
    mapping(address => uint256) public userCurrentIndex;
}



contract SpotBattle is DataLayout, Proxiable{

 
    using SafeMath for uint256;

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        
    }

    function updateCode(address newCode) public _onlyOwner delegatedOnly  {
        updateCodeAddress(newCode);
    }

    receive() external payable {
        
    }

    function battleConstructor(address _versusToken) public {
        require(!initialized, "Contract is already initialized");
        owner = msg.sender;
        versusToken = _versusToken;
        initialize();
    }

    
    function addMarket(address token) public _onlyOwner {
        markets.push(token);
        marketData[token].round = 1;
        marketData[token].targetPrice = uint(getLatestPrice(token)); // get price from chainlink price feed
        marketData[token].roundEnd = block.timestamp.add(5 minutes);//block.timestamp + 5 mins in blocks

        marketData[token].targetHistory.push(marketData[token].targetPrice);

    }

    function getLatestPrice(address token) public view returns (int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(token);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function setVersusToken(address token) public _onlyOwner {
        versusToken = token;
    }

    function nextRoundPrediction(address token, uint32 index, bool isLonging, bool freePrediction) public payable {
        require(markets[index] == token);
        //check if user has placed prediction in market
        bool hasPosition = entrantData[token][marketData[token].round+1][msg.sender];
        require(!hasPosition);

        uint256 BNBAmount;
        if (freePrediction) {
            require(msg.value == 0);
            //check if user has staked long enough for a free prediction
            uint256 contractBNB = address(this).balance;
            VersusToken(versusToken).hasFreePrediction(msg.sender);
            BNBAmount = address(this).balance.sub(contractBNB);
        }

        if (!freePrediction) {
            require (msg.value > 0);
            BNBAmount = msg.value;
        }
        
        //send 3% of value to token contract as fees
        uint256 fees = BNBAmount.mul(3).div(100);
        VersusToken(versusToken).returnPredictionFees{value: fees}();
        
        // set user position data
        userCurrentIndex[msg.sender] = userCurrentIndex[msg.sender] + 1;
        userTokenHistory[msg.sender][userCurrentIndex[msg.sender]] = token;
        userTokenRoundHistory[msg.sender][userCurrentIndex[msg.sender]][token] = marketData[token].round + 1;
        userBNBHistory[msg.sender][userCurrentIndex[msg.sender]][token][marketData[token].round + 1] = BNBAmount.sub(fees);
        userPositionHistory[msg.sender][userCurrentIndex[msg.sender]][token][marketData[token].round + 1] = isLonging;
        userFreePredictionHistory[msg.sender][userCurrentIndex[msg.sender]][token][marketData[token].round + 1] = freePrediction;
  
        if(isLonging) {
            marketData[token].nextRoundLong = marketData[token].nextRoundLong.add(BNBAmount.sub(fees));
        } else {
            marketData[token].nextRoundShort = marketData[token].nextRoundShort.add(BNBAmount.sub(fees));
        }

        entrantData[token][marketData[token].round+1][msg.sender] = true;
        entrantPosition[token][marketData[token].round+1][msg.sender] = isLonging;
        // claim(msg.sender);
        VersusToken(versusToken).updateStats(msg.sender, BNBAmount.sub(fees));
    }

    function expireRound(address token, uint32 index) public {
        require(markets[index] == token);
        require(block.timestamp >= marketData[token].roundEnd);
        marketData[token].longHistory.push(marketData[token].longBNB);
        marketData[token].shortHistory.push(marketData[token].shortBNB);
        uint closingPrice = uint(getLatestPrice(token)); //get current closing price
        marketData[token].targetHistory.push(marketData[token].targetPrice);
        marketData[token].closingHistory.push(closingPrice);
        marketData[token].targetPrice = closingPrice;

        marketData[token].longBNB = marketData[token].nextRoundLong;
        marketData[token].shortBNB = marketData[token].nextRoundShort;
        marketData[token].nextRoundLong = 0;
        marketData[token].nextRoundShort = 0;

        marketData[token].round = marketData[token].round + 1;
        marketData[token].roundEnd = block.timestamp.add(5 minutes);
        //reward function caller with amount of versus(maybe)

    }

    function getSpotInfo(address token, address user) public view returns(uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory, bool[] memory) {
        uint256[] memory currentInfo = new uint256[](5);
        currentInfo[0] = marketData[token].longBNB;
        currentInfo[1] = marketData[token].shortBNB;
        currentInfo[2] = marketData[token].roundEnd;
        currentInfo[3]= marketData[token].round;
        currentInfo[4]= marketData[token].targetPrice;
        

        uint256[] memory nextInfo = new uint256[](2);
        nextInfo[0] = marketData[token].nextRoundLong;
        nextInfo[1] = marketData[token].nextRoundShort;

        uint256[] memory pastInfo = new uint256[](3);
        if (marketData[token].round >= 2) {
            pastInfo[0] = marketData[token].longHistory[marketData[token].round-2];
            pastInfo[1] = marketData[token].shortHistory[marketData[token].round-2];
            pastInfo[2] = marketData[token].closingHistory[marketData[token].round-2];
        }
        

        
        return(
            currentInfo,
            nextInfo,
            pastInfo,
            getUserSpotEntry(token, user),
            getUserSpotPosition(token, user)
        );
    }
    
    function getUserSpotEntry(address token, address user) view internal returns(bool[] memory) {
        bool[] memory userInfo = new bool[](3);
        userInfo[0] = entrantData[token][marketData[token].round-1][user];
        userInfo[1] = entrantData[token][marketData[token].round][user];
        userInfo[2] = entrantData[token][marketData[token].round+1][user];
        
        return(userInfo);
    }
    
    function getUserSpotPosition(address token, address user) view internal returns(bool[] memory) {

        bool[] memory userPosition = new bool[](3);
        userPosition[0] = entrantPosition[token][marketData[token].round-1][user];
        userPosition[1] = entrantPosition[token][marketData[token].round][user];
        userPosition[2] = entrantPosition[token][marketData[token].round+1][user];
        
        return(userPosition);
    }

    function getUserMarketHistory(address user, uint256 sIndex, uint256 topLimit) public view returns(
        address[] memory,
        uint256[] memory,
        uint256[] memory,
        bool[] memory,
        bool[] memory) {
            
        address[] memory tokenHistory = new address[](topLimit);
        uint256[] memory roundHistory = new uint256[](topLimit);
        uint256[] memory BNBHistory = new uint256[](topLimit);
        bool[] memory positionHistory = new bool[](topLimit);
        bool[] memory winClaimed = new bool[](topLimit);
        
        for(uint i; i < topLimit; i++) {
            tokenHistory[i] = userTokenHistory[user][sIndex - i];
            roundHistory[i] = userTokenRoundHistory[user][sIndex - i][tokenHistory[i]];
            BNBHistory[i] = userBNBHistory[user][sIndex - i][tokenHistory[i]][roundHistory[i]];
            positionHistory[i] = userPositionHistory[user][sIndex - i][tokenHistory[i]][roundHistory[i]];
            // // //user => index => token address => round => bool
            winClaimed[i] = userClaimHistory[user][sIndex - i][tokenHistory[i]][roundHistory[i]];
        }
        return(
            tokenHistory,
            roundHistory,
            BNBHistory,
            positionHistory,
            winClaimed
        );
    }
    
    function claimCheck(address user, uint256 userIndex, bool short, address token, uint256 round) public view returns(uint256) {
        uint256 BNBUsed = userBNBHistory[user][userIndex][token][round];
        return marketData[token].longHistory[round-1];
        // if(short) {
        //     return BNBUsed.mul(100).div(marketData[token].longHistory[round-1]);
        // } else {
        //     return BNBUsed.mul(100).div(marketData[token].shortHistory[round-1]);
        // }
    }

    function claim(address user, uint256 userIndex) public {
        address token = userTokenHistory[user][userIndex];
        uint256 round = userTokenRoundHistory[user][userIndex][token];

        // make sure user has not claimed index yet
        
        if (!userClaimHistory[user][userIndex][token][round]) {
            bool longWon = marketData[token].targetHistory[round-1] > marketData[token].closingHistory[round-1];

            //if user guessed wrong
            if (userPositionHistory[user][userIndex][token][round] != longWon) {
                userClaimHistory[user][userIndex][token][round] = true;
                return;
            }
            
            uint256 BNBUsed = userBNBHistory[user][userIndex][token][round];
            uint256 percentageOwned;
            if (longWon) {
                percentageOwned = BNBUsed.mul(100).div(marketData[token].longHistory[round-1]);
            } else {
                percentageOwned = BNBUsed.mul(100).div(marketData[token].shortHistory[round-1]);
            }

            //add entered amount to winnings
            uint256 winnings;
            if (longWon) {
                winnings = marketData[token].longHistory[round-1].mul(percentageOwned).div(100);
            } else {
                winnings = marketData[token].shortHistory[round-1].mul(percentageOwned).div(100);
            }

            // // //send winnings to user after free prediction check and fees
            // if (userFreePredictionHistory[user][userIndex][token][round]) {
            //     //send 99% to token contract
            //     VersusToken(versusToken).returnFreeBNB{value: winnings.mul(99).div(100)}(user);
            //     //reduce winnings by 99%
            //     winnings = winnings.sub(winnings.mul(99).div(100));
            // }
            // msg.sender.call{value: winnings}("");

            // //send user Versus as reward, if not free prediction, how much though?

            // userClaimHistory[user][userIndex][token][round] = true;
            // // VersusToken(versusToken).updateUserWins(user, true);
            // return;
        } 

    }
    
}

interface VersusToken {
    function hasFreePrediction(address user) external returns(uint256);
    function returnPredictionFees() payable external;
    function returnFreeBNB(address user) payable external;
    function updateStats(address user, uint256 volume) external;
    function updateUserWins(address _user, bool _isWin) external;
}