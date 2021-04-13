/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// File: contracts\gsn\Context.sol

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

// File: contracts\access\Ownable.sol

pragma solidity ^0.5.0;


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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

}

// File: contracts\libs\SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");

        return a - b;
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
        require(b > 0, "SafeMath: division by zero");

        return a / b;
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
        require(b > 0, "SafeMath: modulo by zero");

        return a % b;
    }

}

// File: contracts\token\erc20\IERC20.sol

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

// File: contracts\token\erc20\ERC20.sol

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

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
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

        _balances[sender] = _balances[sender].sub(amount);
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

        _balances[account] = _balances[account].sub(amount);
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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount));
    }

}

// File: contracts\libs\RealMath.sol

pragma solidity ^0.5.0;

/**
 * Reference: https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
 */

library RealMath {

    uint256 private constant BONE           = 10 ** 18;
    uint256 private constant MIN_BPOW_BASE  = 1 wei;
    uint256 private constant MAX_BPOW_BASE  = (2 * BONE) - 1 wei;
    uint256 private constant BPOW_PRECISION = BONE / 10 ** 10;

    /**
     * @dev 
     */
    function rtoi(uint256 a)
        internal
        pure 
        returns (uint256)
    {
        return a / BONE;
    }

    /**
     * @dev 
     */
    function rfloor(uint256 a)
        internal
        pure
        returns (uint256)
    {
        return rtoi(a) * BONE;
    }

    /**
     * @dev 
     */
    function radd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;

        require(c >= a, "ERR_ADD_OVERFLOW");
        
        return c;
    }

    /**
     * @dev 
     */
    function rsub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        (uint256 c, bool flag) = rsubSign(a, b);

        require(!flag, "ERR_SUB_UNDERFLOW");

        return c;
    }

    /**
     * @dev 
     */
    function rsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);

        } else {
            return (b - a, true);
        }
    }

    /**
     * @dev 
     */
    function rmul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c0 = a * b;

        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");

        uint256 c1 = c0 + (BONE / 2);

        require(c1 >= c0, "ERR_MUL_OVERFLOW");

        return c1 / BONE;
    }

    /**
     * @dev 
     */
    function rdiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, "ERR_DIV_ZERO");

        uint256 c0 = a * BONE;

        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");

        uint256 c1 = c0 + (b / 2);

        require(c1 >= c0, "ERR_DIV_INTERNAL");

        return c1 / b;
    }

    /**
     * @dev 
     */
    function rpowi(uint256 a, uint256 n)
        internal
        pure
        returns (uint256)
    {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = rmul(a, a);

            if (n % 2 != 0) {
                z = rmul(z, a);
            }
        }

        return z;
    }

    /**
     * @dev Computes b^(e.w) by splitting it into (b^e)*(b^0.w).
     * Use `rpowi` for `b^e` and `rpowK` for k iterations of approximation of b^0.w
     */
    function rpow(uint256 base, uint256 exp)
        internal
        pure
        returns (uint256)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = rfloor(exp);   
        uint256 remain = rsub(exp, whole);

        uint256 wholePow = rpowi(base, rtoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = rpowApprox(base, remain, BPOW_PRECISION);

        return rmul(wholePow, partialResult);
    }

    /**
     * @dev 
     */
    function rpowApprox(uint256 base, uint256 exp, uint256 precision)
        internal
        pure
        returns (uint256)
    {
        (uint256 x, bool xneg) = rsubSign(base, BONE);

        uint256 a = exp;
        uint256 term = BONE;
        uint256 sum = term;

        bool negative = false;

        // term(k) = numer / denom 
        //         = (product(a - i - 1, i = 1--> k) * x ^ k) / (k!)
        // Each iteration, multiply previous term by (a - (k - 1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;

            (uint256 c, bool cneg) = rsubSign(a, rsub(bigK, BONE));

            term = rmul(term, rmul(c, x));
            term = rdiv(term, bigK);

            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;

            if (negative) {
                sum = rsub(sum, term);

            } else {
                sum = radd(sum, term);
            }
        }

        return sum;
    }

}

// File: contracts\libs\Address.sol

pragma solidity ^0.5.0;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

}

// File: contracts\pak\ICollection.sol

pragma solidity ^0.5.0;

interface ICollection {

    // ERC721
    function transferFrom(address from, address to, uint256 tokenId) external;

    // ERC1155
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data) external;

}

// File: contracts\pak\ASH.sol

pragma solidity ^0.5.0;






contract ASH is Ownable, ERC20 {

    using RealMath for uint256;
    using Address for address;

    bytes4 private constant _ERC1155_RECEIVED = 0xf23a6e61;

    event CollectionWhitelist(address collection, bool status);
    event AssetWhitelist(address collection, uint256 assetId, bool status);

    event CollectionBlacklist(address collection, bool status);
    event AssetBlacklist(address collection, uint256 assetId, bool status);

    event Swapped(address collection, uint256 assetId, address account, uint256 amount, bool isWhitelist, bool isERC721);

    // Mapping "collection" whitelist
    mapping(address => bool) private _collectionWhitelist;

    // Mapping "asset" whitelist
    mapping(address => mapping(uint256 => bool)) private _assetWhitelist;

    // Mapping "collection" blacklist
    mapping(address => bool) private _collectionBlacklist;

    // Mapping "asset" blacklist
    mapping(address => mapping(uint256 => bool)) private _assetBlacklist;

    bool public isStarted = false;

    bool public isERC721Paused = false;
    bool public isERC1155Paused = true;

    /**
     * @dev Throws if NFT swapping does not start yet
     */
    modifier started() {
        require(isStarted, "ASH: NFT swapping does not start yet");
        _;
    }

    /**
     * @dev Throws if collection or asset is in blacklist
     */
    modifier notInBlacklist(address collection, uint256 assetId) {
        require(!_collectionBlacklist[collection] && !_assetBlacklist[collection][assetId], "ASH: collection or asset is in blacklist");
        _;
    }

    /**
     * @dev Initializes the contract settings
     */
    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol, 18)
    {}

    /**
     * @dev Starts to allow NFT swapping
     */
    function start()
        public
        onlyOwner
    {
        isStarted = true;
    }

    /**
     * @dev Pauses NFT (everything) swapping
     */
    function pause(bool erc721)
        public
        onlyOwner
    {
        if (erc721) {
            isERC721Paused = true;

        } else {
            isERC1155Paused = true;
        }
    }

    /**
     * @dev Resumes NFT (everything) swapping
     */
    function resume(bool erc721)
        public
        onlyOwner
    {
        if (erc721) {
            isERC721Paused = false;

        } else {
            isERC1155Paused = false;
        }
    }

    /**
     * @dev Adds or removes collections in whitelist
     */
    function updateWhitelist(address[] memory collections, bool status)
        public
        onlyOwner
    {
        uint256 length = collections.length;

        for (uint256 i = 0; i < length; i++) {
            address collection = collections[i];

            if (_collectionWhitelist[collection] != status) {
                _collectionWhitelist[collection] = status;

                emit CollectionWhitelist(collection, status);
            }
        }
    }

    /**
     * @dev Adds or removes assets in whitelist
     */
    function updateWhitelist(address[] memory collections, uint256[] memory assetIds, bool status)
        public
        onlyOwner
    {
        uint256 length = collections.length;

        require(length == assetIds.length, "ASH: length of arrays is not equal");

        for (uint256 i = 0; i < length; i++) {
            address collection = collections[i];
            uint256 assetId = assetIds[i];

            if (_assetWhitelist[collection][assetId] != status) {
                _assetWhitelist[collection][assetId] = status;

                emit AssetWhitelist(collection, assetId, status);
            }
        }
    }

    /**
      * @dev Returns true if collection is in whitelist
      */
    function isWhitelist(address collection)
        public
        view
        returns (bool)
    {
        return _collectionWhitelist[collection];
    }

    /**
      * @dev Returns true if asset is in whitelist
      */
    function isWhitelist(address collection, uint256 assetId)
        public
        view
        returns (bool)
    {
        return _assetWhitelist[collection][assetId];
    }

    /**
     * @dev Adds or removes collections in blacklist
     */
    function updateBlacklist(address[] memory collections, bool status)
        public
        onlyOwner
    {
        uint256 length = collections.length;

        for (uint256 i = 0; i < length; i++) {
            address collection = collections[i];

            if (_collectionBlacklist[collection] != status) {
                _collectionBlacklist[collection] = status;

                emit CollectionBlacklist(collection, status);
            }
        }
    }

    /**
     * @dev Adds or removes assets in blacklist
     */
    function updateBlacklist(address[] memory collections, uint256[] memory assetIds, bool status)
        public
        onlyOwner
    {
        uint256 length = collections.length;

        require(length == assetIds.length, "ASH: length of arrays is not equal");

        for (uint256 i = 0; i < length; i++) {
            address collection = collections[i];
            uint256 assetId = assetIds[i];

            if (_assetBlacklist[collection][assetId] != status) {
                _assetBlacklist[collection][assetId] = status;

                emit AssetBlacklist(collection, assetId, status);
            }
        }
    }

    /**
      * @dev Returns true if collection is in blacklist
      */
    function isBlacklist(address collection)
        public
        view
        returns (bool)
    {
        return _collectionBlacklist[collection];
    }

    /**
      * @dev Returns true if asset is in blacklist
      */
    function isBlacklist(address collection, uint256 assetId)
        public
        view
        returns (bool)
    {
        return _assetBlacklist[collection][assetId];
    }

    /**
     * @dev Burns tokens with a specific `amount`
     */
    function burn(uint256 amount)
        public
    {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Calculates token amount that user will receive when burn
     */
    function calculateToken(address collection, uint256 assetId)
        public
        view
        returns (bool, uint256)
    {
        bool whitelist = false;

        // Checks if collection or asset in whitelist
        if (_collectionWhitelist[collection] || _assetWhitelist[collection][assetId]) {
            whitelist = true;
        }

        uint256 exp = totalSupply().rdiv(1000000 * (10 ** 18));

        uint256 multiplier = RealMath.rdiv(1, 2).rpow(exp);

        uint256 result;

        // Calculates token amount that will issue
        if (whitelist) {
            result = multiplier.rmul(1000 * (10 ** 18));

        } else {
            result = multiplier.rmul(multiplier).rmul(2 * (10 ** 18));
        }

        return (whitelist, result);
    }

    /**
     * @dev Issues ERC20 tokens
     */
    function _issueToken(address collection, uint256 assetId, address account, bool isERC721)
        private
    {
        (bool whitelist, uint256 amount) = calculateToken(collection, assetId);

        if (!whitelist) {
            if (isERC721) {
                require(!isERC721Paused, "ASH: ERC721 swapping paused");

            } else {
                require(!isERC1155Paused, "ASH: ERC1155 swapping paused");
            }
        }

        require(amount > 0, "ASH: amount is invalid");

        // Issues tokens
        _mint(account, amount);

        emit Swapped(collection, assetId, account, amount, whitelist, isERC721);
    }

    /**
     * @dev Swaps ERC721 to ERC20
     */
    function swapERC721(address collection, uint256 assetId)
        public
        started()
        notInBlacklist(collection, assetId)
    {
        address msgSender = _msgSender();

        require(!msgSender.isContract(), "ASH: caller is invalid");

        // Transfers ERC721 and lock in this smart contract
        ICollection(collection).transferFrom(msgSender, address(this), assetId);

        // Issues ERC20 tokens for caller
        _issueToken(collection, assetId, msgSender, true);
    }

    /**
     * @dev Swaps ERC1155 to ERC20
     */
    function swapERC1155(address collection, uint256 assetId)
        public
        started()
        notInBlacklist(collection, assetId)
    {
        address msgSender = _msgSender();

        require(!msgSender.isContract(), "ASH: caller is invalid");

        // Transfers ERC1155 and lock in this smart contract
        ICollection(collection).safeTransferFrom(msgSender, address(this), assetId, 1, "");

        // Issues ERC20 tokens for caller
        _issueToken(collection, assetId, msgSender, false);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
        returns (bytes4)
    {
        return _ERC1155_RECEIVED;
    }

}