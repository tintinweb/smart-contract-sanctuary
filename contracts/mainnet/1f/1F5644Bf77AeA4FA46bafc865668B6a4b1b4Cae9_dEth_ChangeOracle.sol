/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: contracts/DSMath.sol

pragma solidity ^0.5.17;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {    
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// File: contracts/DSProxy.sol

pragma solidity ^0.5.17;

contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache; 

    constructor(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    function() external payable {}

    
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        returns (address target, bytes32 response)
    {
        target = cache.read(_code);
        if (target == address(0)) {
            
            target = cache.write(_code);
        }

        response = execute(target, _data);
    }

    function execute(address _target, bytes memory _data)
        public
        payable
        auth
        note
        returns (bytes32 response)
    {
        require(_target != address(0));
        
        assembly {
            let succeeded := delegatecall(
                sub(gas, 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                32
            )
            response := mload(0)
            switch iszero(succeeded)
                case 1 
                {
                    revert(0, 0)
                }
        }
    }

    
    function setCache(address _cacheAddr) public payable auth note returns (bool) {
        require(_cacheAddr != address(0)); 
        cache = DSProxyCache(_cacheAddr); 
        return true;
    }
}

contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {
                    
                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}

// File: contracts/dEth.sol

// todo:
// add disclaimer

pragma solidity ^0.5.17;





// Number typing guide
// The subsystems we use, use different decimal systems
// Additionally we use different number assumptions for convenience
// RAY -    10**27 - Maker decimal for high precision calculation
// WAD -    10**18 - Maker decimal for token values
// PERC -   10**16 - 1% of a WAD, with 100% == 1 WAD
// CLP -    10**8  - Chainlink price format
// RATIO -  10**32 - Ratio from Maker for a CDP's debt to GDP ratio. 

contract IDSGuard is DSAuthority
{
    function permit(address src, address dst, bytes32 sig) public;
}

contract IDSGuardFactory 
{
    function newGuard() public returns (IDSGuard guard);
}

// Note:
// This is included to avoid method signature collisions between already imported 
// DSProxy's two execute functions. 
contract IDSProxy
{
    function execute(address _target, bytes memory _data) public payable returns (bytes32);
}

contract IMCDSaverProxy
{
    function getCdpDetailedInfo(uint _cdpId) public view returns (uint collateral, uint debt, uint price, bytes32 ilk);
    function getRatio(uint _cdpId, bytes32 _ilk) public view returns (uint);
}

contract IChainLinkPriceOracle
{
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound);
}

contract IMakerOracle
{
    function read()
        public 
        view 
        returns(bytes32);
}

contract Oracle
{
    using SafeMath for uint256;

    uint constant ONE_PERC = 10**16; // 1.0%
    uint constant HUNDRED_PERC = 10**18; // 100.0%

    IMakerOracle public makerOracle;
    IChainLinkPriceOracle public daiUsdOracle;
    IChainLinkPriceOracle public ethUsdOracle;

    constructor (
            IMakerOracle _makerOracle, 
            IChainLinkPriceOracle _daiUsdOracle, 
            IChainLinkPriceOracle _ethUsdOracle) 
        public
    {
        makerOracle = _makerOracle;
        daiUsdOracle = _daiUsdOracle;
        ethUsdOracle = _ethUsdOracle;
    }   

    function getEthDaiPrice() 
        public
        view
        returns (uint _price)
    {
        // maker's price comes back as a decimal with 18 places
        uint makerEthUsdPrice = uint(makerOracle.read()); 

        // chainlink's price comes back as a decimal with 8 places
        (,int chainlinkEthUsdPrice,,,) = ethUsdOracle.latestRoundData();
        (,int chainlinkDaiUsdPrice,,,) = daiUsdOracle.latestRoundData();

        // chainlink's price comes back as a decimal with 8 places
        // multiplying two of them, produces 16 places
        // we need it in the WAD format which has 18, therefore .mul(10**2) at the end
        uint chainlinkEthDaiPrice = uint(chainlinkEthUsdPrice).mul(uint(chainlinkDaiUsdPrice)).mul(10**2);
    
        // if the differnce between the ethdai price from chainlink is more than 10% from the
        // maker oracle price, trust the maker oracle 
        uint percDiff = absDiff(makerEthUsdPrice, uint(chainlinkEthDaiPrice))
            .mul(HUNDRED_PERC)
            .div(makerEthUsdPrice);
        return percDiff > ONE_PERC.mul(10) ? 
            makerEthUsdPrice :
            chainlinkEthDaiPrice;
    }

    function absDiff(uint a, uint b)
        internal
        pure
        returns(uint)
    {
        return a > b ? a - b : b - a;
    }
}

// Description:
// This contract tokenizes ownership of a Maker CDP. It does so by allowing anyone to mint new
// tokens in exchange for collateral and issues tokens in proportion to the excess collateral
// that is already in the CDP. It also allows anyone with dEth tokens to redeem these tokens
// in exchange for the excess collateral in the CDP, proportional to their share of total dEth
// tokens.
// Furthermore the contract inherits from DSProxy which allows its CDP to be automated via the 
// DeFiSaver ecosystem. This automation is activated by calling the subscribe() method on the
// DeFiSaver SubscriptionsProxyV2 contract via the execute() method inherited from DSProxy.
// This automation will automatically increase the leverage of the CDP to a target ratio if the
// collateral increases in value and automatically decrease it to the target ratio if the 
// collateral falls in value. 
// SubscriptionsProxyV2 can be viewed here:
// https://etherscan.io/address/0xB78EbeD358Eb5a94Deb08Dc97846002F0632c99A#code
// An audit of the DeFiSaver system can be viewed here:
// https://github.com/DecenterApps/defisaver-contracts/blob/master/audits/Dedaub%20-%20DeFi%20Saver%20Automation%20Audit%20-%20February%202021.pdf

// When activate the automation makes the dEth contract a perpetually levered long position on
// the price of Ether in US dollars. 

// Details:
// The contract charges a protocol fee that is paid out to contract called the gulper. The fee
// is fixed at 0.9%. 
// Due to the sometimes extreme gas fees required to run the DefiSaver automations, an 
// additional automation fee is charged to anyone entering or exiting the system. This fee can 
// be increased or decreased as needed to compensate existing participants.
// There is a riskLimit parameter that prevents the system from acquiring too much collateral 
// before it has established a record of safety. This can also be used to prevent new 
// participants from minting new dEth in case an upgrade is necessary and dEth tokens need to 
// be migrated to a new version.
// The minRedemptionRatio parameter prevents too much collateral being removed at once from
// the CDP before DefiSaver has the opportunity to return the CDP to its target parameters. 

// Note: 
// What is not apparent explicitly in this contract is how calls to the "auth" methods are to
// be dealt with. All auth methods will initially be owned by the owner key of this contract. 
// The intent is to keep it under the control of the owner key until some history of use can be
// built up to increase confidence that the contract is indeed safe and stable in the wild.
// Thereafter the owner key will be given to an OpenZeppelin TimelockController contract with a
// 48 hour delay. The TimelockController in turn will be owned by the FoundryDAO and controlled
// via it's governance structures. This will give any participants at least 48 hours to take 
// action, should any change be unpalatable. 

// Note: 
// Since defisaver automation can be upgraded and since older versions of their subscription 
// contract are not guarenteed to be updated by their offchain services and since the calling 
// of the automation script involves passing in a custom contract to where a delgate call is
// made; it is safer to rather execute the automation script via an execute(_address, _data) 
// call inherited from DSProxy through the auth system.

contract dEth is 
    ERC20Detailed, 
    ERC20,
    DSMath,
    DSProxy
{
    using SafeMath for uint;

    string constant terms = "By interacting with this contract, you agree to be bound by the terms of service found at https://www.FoundryDao.com/dEthTerms/";

    uint constant ONE_PERC = 10**16;                    //   1.0% 
    uint constant HUNDRED_PERC = 10**18;                // 100.0%

    uint constant PROTOCOL_FEE_PERC = 9*10**15;         //   0.9%
    
    address payable public gulper;
    uint public cdpId;
    
    // Note:
    // Since these items are not available on test net and represent interactions
    // with the larger DeFi ecosystem, they are directly addressed here with the understanding
    // that testing occurs against simulated forks of the the Ethereum mainnet. 
    address constant public makerManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address constant public ethGemJoin = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address constant public saverProxy = 0xC563aCE6FACD385cB1F34fA723f412Cc64E63D47;
    address constant public saverProxyActions = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;

    Oracle public oracle;

    // automation variables
    uint public minRedemptionRatio; // the min % excess collateral that must remain after any ETH redeem action
    uint public automationFeePerc;  // the fee that goes to the collateral pool, on entry or exit, to compensate for potentially triggering a boost or redeem
    
    // Note:
    // riskLimit sets the maximum amount of excess collateral Eth the contract will place at risk
    // When exceeded it is no longer possible to issue dEth via the squander function
    // This can also be used to retire the contract by setting it to 0
    uint public riskLimit; 
    
    constructor(
            address payable _gulper,
            uint _cdpId,
            Oracle _oracle,
            address _initialRecipient,
            address _automationAuthority)
        public
        DSProxy(0x271293c67E2D3140a0E9381EfF1F9b01E07B0795) //_proxyCache on mainnet
        ERC20Detailed("Derived Ether", "dEth", 18)
    {
        gulper = _gulper;
        cdpId = _cdpId;

        oracle = _oracle;

        // Initial values of automation variables
        minRedemptionRatio = uint(160).mul(ONE_PERC).mul(10**18);
        automationFeePerc = ONE_PERC; // 1.0%
        riskLimit = 1000*10**18;      // sets an initial limit of 1000 ETH that the contract will risk. 

        // distributes the initial supply of dEth to the initial recipient at 1 ETH to 1 dEth
        uint excess = getExcessCollateral();
        _mint(_initialRecipient, excess);

        // set the automation authority to make sure the parameters can be adjusted later on
        IDSGuard guard = IDSGuardFactory(0x5a15566417e6C1c9546523066500bDDBc53F88C7).newGuard(); // DSGuardFactory
        guard.permit(
            _automationAuthority,
            address(this),
            bytes4(keccak256("changeSettings(uint256,uint256,uint256)")));
        setAuthority(guard);

        require(
            authority.canCall(
                _automationAuthority, 
                address(this), 
                bytes4(keccak256("changeSettings(uint256,uint256,uint256)"))),
            "guard setting failed");
    }

    function changeGulper(address payable _newGulper)
        public
        auth
    {
        gulper = _newGulper;
    }

    function giveCDPToDSProxy(address _dsProxy)
        public
        auth
    {
        bytes memory giveProxyCall = abi.encodeWithSignature(
            "give(address,uint256,address)", 
            makerManager, 
            cdpId, 
            _dsProxy);
        
        IDSProxy(address(this)).execute(saverProxyActions, giveProxyCall);

        // removes the ability to mint more dEth tokens
        riskLimit = 0;
    }

    function getCollateral()
        public
        view
        returns(uint _priceRAY, uint _totalCollateral, uint _debt, uint _collateralDenominatedDebt, uint _excessCollateral)
    {
        _priceRAY = getCollateralPriceRAY();
        (_totalCollateral, _debt,,) = IMCDSaverProxy(saverProxy).getCdpDetailedInfo(cdpId);
        _collateralDenominatedDebt = rdiv(_debt, _priceRAY);
        _excessCollateral = sub(_totalCollateral, _collateralDenominatedDebt);
    }

    function getCollateralPriceRAY()
        public
        view
        returns (uint _priceRAY)
    {
        // we multiply by 10^9 to cast the price to a RAY number as used by the Maker CDP
        _priceRAY = oracle.getEthDaiPrice().mul(10**9);
    }

    function getExcessCollateral()
        public
        view
        returns(uint _excessCollateral)
    {
        (,,,, _excessCollateral) = getCollateral();
    }

    function getRatio()
        public
        view
        returns(uint _ratio)
    {
        (,,,bytes32 ilk) = IMCDSaverProxy(saverProxy).getCdpDetailedInfo(cdpId);
        _ratio = IMCDSaverProxy(saverProxy).getRatio(cdpId, ilk);
    }

    function calculateIssuanceAmount(uint _suppliedCollateral)
        public
        view
        returns (
            uint _protocolFee,
            uint _automationFee,
            uint _actualCollateralAdded,
            uint _accreditedCollateral,
            uint _tokensIssued)
    {
        _protocolFee = _suppliedCollateral.mul(PROTOCOL_FEE_PERC).div(HUNDRED_PERC);
        _automationFee = _suppliedCollateral.mul(automationFeePerc).div(HUNDRED_PERC);
        _actualCollateralAdded = _suppliedCollateral.sub(_protocolFee); 
        _accreditedCollateral = _actualCollateralAdded.sub(_automationFee); 
        uint newTokenSupplyPerc = _accreditedCollateral.mul(HUNDRED_PERC).div(getExcessCollateral());
        _tokensIssued = totalSupply().mul(newTokenSupplyPerc).div(HUNDRED_PERC);
    }

    event Issued(
        address _receiver, 
        uint _suppliedCollateral,
        uint _protocolFee,
        uint _automationFee,
        uint _actualCollateralAdded,
        uint _accreditedCollateral,
        uint _tokensIssued);

    // Note: 
    // This method should have been called issue(address _receiver), but will remain this for meme value
    function squanderMyEthForWorthlessBeansAndAgreeToTerms(address _receiver)
        payable
        public
    { 
        // Goals:
        // 1. deposit eth into the vault 
        // 2. give the holder a claim on the vault for later withdrawal to the address they choose 
        // 3. pay the protocol

        require(getExcessCollateral() < riskLimit.add(msg.value), "risk limit exceeded");

        (uint protocolFee, 
        uint automationFee, 
        uint collateralToLock, 
        uint accreditedCollateral, 
        uint tokensToIssue)  = calculateIssuanceAmount(msg.value);

        bytes memory lockETHproxyCall = abi.encodeWithSignature(
            "lockETH(address,address,uint256)", 
            makerManager, 
            ethGemJoin,
            cdpId);
        IDSProxy(address(this)).execute.value(collateralToLock)(saverProxyActions, lockETHproxyCall);
        
        (bool protocolFeePaymentSuccess,) = gulper.call.value(protocolFee)("");
        require(protocolFeePaymentSuccess, "protocol fee transfer to gulper failed");

        // Note: 
        // The automationFee is left in the CDP to cover the gas implications of leaving or joining dEth
        // This is why it is not explicitly used in this method. 

        _mint(_receiver, tokensToIssue);
        
        emit Issued(
            _receiver, 
            msg.value, 
            protocolFee,
            automationFee, 
            collateralToLock, 
            accreditedCollateral,
            tokensToIssue);
    }

    function calculateRedemptionValue(uint _tokensToRedeem)
        public
        view
        returns (
            uint _protocolFee,
            uint _automationFee,
            uint _collateralRedeemed, 
            uint _collateralReturned)
    {
        // comment: a full check against the minimum ratio might be added in a future version
        // for now keep in mind that this function may return values greater than those that 
        // could be executed in one transaction. 
        require(_tokensToRedeem <= totalSupply(), "_tokensToRedeem exceeds totalSupply()");
        uint redeemTokenSupplyPerc = _tokensToRedeem.mul(HUNDRED_PERC).div(totalSupply());
        uint collateralAffected = getExcessCollateral().mul(redeemTokenSupplyPerc).div(HUNDRED_PERC);
        _protocolFee = collateralAffected.mul(PROTOCOL_FEE_PERC).div(HUNDRED_PERC);
        _automationFee = collateralAffected.mul(automationFeePerc).div(HUNDRED_PERC);
        _collateralRedeemed = collateralAffected.sub(_automationFee); // how much capital should exit the dEth contract
        _collateralReturned = _collateralRedeemed.sub(_protocolFee); // how much capital should return to the user
    }

    event Redeemed(
        address _redeemer,
        address _receiver, 
        uint _tokensRedeemed,
        uint _protocolFee,
        uint _automationFee,
        uint _collateralRedeemed,
        uint _collateralReturned);

    function redeem(address _receiver, uint _tokensToRedeem)
        public
    {
        // Goals:
        // 1. if the _tokensToRedeem being claimed does not drain the vault to below 160%
        // 2. pull out the amount of ether the senders' tokens entitle them to and send it to them

        (uint protocolFee, 
        uint automationFee, 
        uint collateralToFree,
        uint collateralToReturn) = calculateRedemptionValue(_tokensToRedeem);

        bytes memory freeETHProxyCall = abi.encodeWithSignature(
            "freeETH(address,address,uint256,uint256)",
            makerManager,
            ethGemJoin,
            cdpId,
            collateralToFree);
        IDSProxy(address(this)).execute(saverProxyActions, freeETHProxyCall);

        _burn(msg.sender, _tokensToRedeem);

        (bool protocolFeePaymentSuccess,) = gulper.call.value(protocolFee)("");
        require(protocolFeePaymentSuccess, "protocol fee transfer to gulper failed");

        // note: the automationFee is left in the CDP to cover the gas implications of leaving or joining dEth
        
        (bool payoutSuccess,) = _receiver.call.value(collateralToReturn)("");
        require(payoutSuccess, "eth send to receiver reverted");

        // this ensures that the CDP will be boostable by DefiSaver before it can be bitten
        // to prevent bites, getRatio() doesn't use oracle but the price set in the MakerCDP system 
        require(getRatio() >= minRedemptionRatio, "cannot violate collateral safety ratio");

        emit Redeemed(  
            msg.sender,
            _receiver, 
            _tokensToRedeem,
            protocolFee,
            automationFee,
            collateralToFree,
            collateralToReturn);
    }
    
    event SettingsChanged(
            uint _minRedemptionRatio,
            uint _automationFeePerc,
            uint _riskLimit);

    function changeSettings(
            uint _minRedemptionRatio,
            uint _automationFeePerc,
            uint _riskLimit)
        public
        auth
    {
        minRedemptionRatio = _minRedemptionRatio.mul(ONE_PERC).mul(10**18);
        automationFeePerc = _automationFeePerc;
        riskLimit = _riskLimit;

        emit SettingsChanged(
            minRedemptionRatio,
            automationFeePerc,
            riskLimit);
    }
}

contract EthDaiOracle
{
    using SafeMath for uint256;

    uint constant ONE_PERC = 10**16; // 1.0%
    uint constant HUNDRED_PERC = 10**18; // 100.0%

    IChainLinkPriceOracle public daiUsdOracle;
    IChainLinkPriceOracle public ethUsdOracle;

    constructor ( 
            IChainLinkPriceOracle _daiUsdOracle, 
            IChainLinkPriceOracle _ethUsdOracle) 
        public
    {
        daiUsdOracle = _daiUsdOracle;
        ethUsdOracle = _ethUsdOracle;
    }   

    function getEthDaiPrice() 
        public
        view
        returns (uint _price)
    {
        // chainlink's price comes back as a decimal with 8 places
        (,int chainlinkEthUsdPrice,,,) = ethUsdOracle.latestRoundData();
        (,int chainlinkDaiUsdPrice,,,) = daiUsdOracle.latestRoundData();

        // chainlink's price comes back as a decimal with 8 places
        // multiplying two of them, produces 16 places
        // we need it in the WAD format which has 18, therefore .mul(10**2) at the end
        uint chainlinkEthDaiPrice = uint(chainlinkEthUsdPrice).mul(uint(chainlinkDaiUsdPrice)).mul(10**2);
    
        return chainlinkEthDaiPrice;
    }
}

contract dEth_ChangeOracle is dEth 
{
    constructor(
            address payable _gulper,
            uint _cdpId,
            Oracle _oracle,
            address _initialRecipient,
            address _automationAuthority)
        public
        dEth (_gulper, _cdpId, _oracle, _initialRecipient, _automationAuthority)
    {

    }

    function changeOracle(Oracle _newOracle)
        public
    {
        oracle = _newOracle;
    }
}

// File: contracts/DeployMainnet_dEth.sol

pragma solidity ^0.5.0;


contract DeployMainnet_dEth 
{
    event LogContracts(Oracle _oracle, dEth _dEth);

    constructor()
        public
    {
        Oracle oracle = new Oracle(
            IMakerOracle(0x729D19f657BD0614b4985Cf1D82531c67569197B),                 //IMakerOracle _makerOracle,
            IChainLinkPriceOracle(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9),        //_daiUsdOracle
            IChainLinkPriceOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419));       //_ethUsdOracle

        dEth mainnet_dEth = new dEth(
            0xD7DFA44E3dfeB1A1E65544Dc54ee02B9CbE1e66d,                 //_gulper,
            18963,                                                      //_cdpId,
            oracle,                                                     //_oracle

            0xB7c6bB064620270F8c1daA7502bCca75fC074CF4,                 //_initialRecipient
            0x93fE7D1d24bE7CB33329800ba2166f4D28Eaa553);                //_foundryTreasury)

        mainnet_dEth.setOwner(msg.sender);

        emit LogContracts(oracle, mainnet_dEth);
    }
}

contract DeployMainnet_dEth_newOracle 
{
    event LogContracts(Oracle _oracle, dEth _dEth);

    constructor()
        public
    {
        EthDaiOracle oracle = new EthDaiOracle(
            IChainLinkPriceOracle(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9),        //_daiUsdOracle
            IChainLinkPriceOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419));       //_ethUsdOracle

        // this contract will only think it is a dEth contract. 
        // we're going to use to to call 
        dEth mainnet_dEth = new dEth_ChangeOracle(
            0xD7DFA44E3dfeB1A1E65544Dc54ee02B9CbE1e66d,                 //_gulper,
            18963,                                                      //_cdpId,
            Oracle(address(oracle)),                                    //_oracle

            0xB7c6bB064620270F8c1daA7502bCca75fC074CF4,                 //_initialRecipient
            0x93fE7D1d24bE7CB33329800ba2166f4D28Eaa553);                //_foundryTreasury)           

        mainnet_dEth.setOwner(msg.sender);

        emit LogContracts(Oracle(address(oracle)), mainnet_dEth);
    }
}