/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

// File: contracts/Context.sol

pragma solidity >=0.4.22 <0.9.0;

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
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/SafeMath.sol

pragma solidity >=0.4.22 <0.9.0;

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

// File: contracts/ITRC20.sol

pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITRC20 {
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

// File: contracts/TRC20.sol

pragma solidity >=0.4.22 <0.9.0;




/**
 * @dev Implementation of the {ITRC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {TRC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of TRC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {ITRC20-approve}.
 */
contract TRC20 is Context, ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

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
     * Ether and Wei. This is the value {TRC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {ITRC20-balanceOf} and {ITRC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ITRC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ITRC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ITRC20-transfer}.
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
     * @dev See {ITRC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ITRC20-approve}.
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
     * @dev See {ITRC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {TRC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ITRC20-approve}.
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
     * problems described in {ITRC20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
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
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

// File: contracts/DGPToken.sol

pragma solidity >=0.4.22 <0.9.0;





interface IChildToken {
    function mint(address _account, uint256 _amount) external;
}

interface ITokenV2 {
    function balanceOf(address account) external view returns (uint256);

    function parents(address user) external view returns (address);
}

contract TEST is TRC20("TEST", "TEST") {
    using SafeMath for uint256;

    address private _owner;

    address private oldToken;
    address public childToken;

    struct User {
        address[] children;
        uint256 totalChildren;
    }

    /// @notice Who should not be in the inviting chain
    mapping(address => bool) public whiteList;

    /// @notice Inviting chain
    mapping(address => address) public parents;

    ///@notice Users
    mapping(address => User) public users;

    /// @notice Fund node users
    address[] public fundNodes;

    /// @notice Last distribute time
    uint256 public lastDistributeTime;

    /// @notice Admin address
    address payable private _admin;

    /// @notice Pair address
    address private _pair;

    uint256 private _noIndex = uint256(-1);

    constructor() public {
        _owner = _msgSender();
        _admin = _msgSender();
        // _mint(_msgSender(), 986000 * 10**18);

        lastDistributeTime = block.timestamp;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view onlyOwner returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            _owner == _msgSender() || _admin == _msgSender(),
            "Ownable: caller is not the owner"
        );
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
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        _owner = newOwner;
    }

    /**
     * @notice Set Admin
     */
    function setAdmin(address payable newer) public onlyOwner returns (bool) {
        _admin = newer;

        return true;
    }

    /**
     * @notice Set Child Token
     */
    function setChild(address _token) public onlyOwner returns (bool) {
        childToken = _token;

        return true;
    }

    /**
     * @notice Set Old Token
     */
    function setOld(address _token) public onlyOwner returns (bool) {
        oldToken = _token;

        return true;
    }

    /**
     * @notice Get Admin
     */
    function admin() public view onlyOwner returns (address) {
        return _admin;
    }

    /**
     * @notice Withdraw TRX
     */
    function withdrawTrx() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @notice Withdraw Token
     */
    function withdrawToken(address token) public onlyOwner returns (bool) {
        ITRC20 t = ITRC20(token);
        return t.transfer(msg.sender, t.balanceOf(address(this)));
    }

    /**
     * @notice Add node
     */
    function addNode(address node) public onlyOwner returns (bool) {
        if (getNodeIndex(node) == _noIndex) {
            fundNodes.push(node);

            return true;
        }

        return false;
    }

    /**
     * @notice Remove node
     */
    function removeNode(address node) public onlyOwner returns (bool) {
        uint256 index = getNodeIndex(node);
        if (index != _noIndex) {
            delete fundNodes[index];

            return true;
        }

        return false;
    }

    /**
     * @notice Get node index
     */
    function getNodeIndex(address node) public view returns (uint256) {
        for (uint256 index = 0; index < fundNodes.length; index++) {
            if (fundNodes[index] == node) return index;
        }

        return _noIndex;
    }

    /**
     * @notice Get node total
     */
    function getNodeCount() public view returns (uint256) {
        uint256 count = 0;

        for (uint256 index = 0; index < fundNodes.length; index++) {
            if (fundNodes[index] != address(0)) count++;
        }

        return count;
    }

    /**
     * @notice Set pair
     */
    function setPair(address newer) public onlyOwner {
        _pair = newer;
    }

    /**
     * @notice Get pair
     */
    function pair() public view onlyOwner returns (address) {
        return _pair;
    }

    /**
     * @notice Set who is in white list
     */
    function setWhiteList(address user, bool state)
        public
        onlyOwner
        returns (bool)
    {
        whiteList[user] = state;

        return true;
    }

    /**
     * @notice Set user's parent
     */
    function setParent(address _from, address _to) internal {
        if (_from == _pair || _to == _pair) return;

        if (_from == _to) return;

        if (parents[_to] != address(0)) return;

        if (parents[_from] == _to) return;

        parents[_to] = _from;

        users[_from].children.push(_to);
        users[_from].totalChildren = users[_from].totalChildren.add(1);
    }

    /**
     * @notice Set user's parent
     */
    function setUserParent(address _user, address _parent)
        public
        onlyOwner
        returns (bool)
    {
        setParent(_parent, _user);
        return true;
    }

    /**
     * @notice Clean user's parent
     */
    function cleanParent(address user) public onlyOwner returns (bool) {
        parents[user] = address(0);

        return true;
    }

    /**
     * @notice Get user's parent
     */
    function getParent(address user) public view returns (address) {
        if (parents[user] == address(0)) return _admin;

        return parents[user];
    }

    /**
     * @notice Set Distribute Time
     */
    function setDistributeTime(uint256 _time) public onlyOwner returns (bool) {
        lastDistributeTime = _time;

        return true;
    }

    /**
     * @notice Distribute node rewards
     */
    function distributeNodeRewards() public returns (bool) {
        if (lastDistributeTime + 7 days > block.timestamp) return false;

        uint256 nodeCount = getNodeCount();
        if (nodeCount == 0) return false;

        uint256 balance = balanceOf(address(this));
        if (balance == 0) return false;

        uint256 rewards = balance.div(nodeCount);
        if (rewards == 0) return false;

        _burn(address(this), balance);

        for (uint256 index = 0; index < fundNodes.length; index++) {
            address node = fundNodes[index];
            if (node != address(0)) {
                _mint(node, rewards);
            }
        }

        lastDistributeTime = block.timestamp;

        return true;
    }

    function actualAmount(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        distributeNodeRewards();

        if (totalSupply() <= 10000 * 10**18) return amount;

        if (whiteList[from] || whiteList[to]) return amount;

        address target;
        uint256 burned;
        uint256 part1;
        uint256 part2;
        uint256 part3;
        if (to == _pair) {
            //Sell
            target = from;

            //burns 10% per transaction
            burned = amount.div(9);

            //20% of the burned part is used to rewards to the reffer of the trader
            part1 = burned.mul(20).div(100);

            //50% of the burned part is accumulated to the pool
            part2 = burned.mul(50).div(100);

            //30% is directly burned
            part3 = burned.mul(30).div(100);

            require(
                balanceOf(from) >= amount.add(part1).add(part2).add(part3),
                "Insufficient balance"
            );

            _burn(from, part1.add(part2).add(part3));

            _mint(getParent(target), part1); //rewards to the reffer of the trader

            _mint(address(this), part2);

            setParent(from, to);

            return amount;
        } else {
            //Buy or transfer
            target = to;

            //burns 10% per transaction
            burned = amount.mul(10).div(100);

            //20% of the burned part is used to rewards to the reffer of the trader
            part1 = burned.mul(20).div(100);

            //50% of the burned part is accumulated to the pool
            part2 = burned.mul(50).div(100);

            //30% is directly burned
            part3 = burned.mul(30).div(100);

            _burn(from, part1.add(part2).add(part3));

            _mint(getParent(target), part1); //rewards to the reffer of the trader

            _mint(address(this), part2);

            setParent(from, to);

            if (from == _pair && childToken != address(0)) {
                IChildToken(childToken).mint(to, amount.div(10));
            }

            return amount.sub(part1).sub(part2).sub(part3);
        }
    }

    /**
     * @dev See {ITRC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        return
            super.transfer(
                recipient,
                actualAmount(_msgSender(), recipient, amount)
            );
    }

    /**
     * @dev See {ITRC20-transferFrom}.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        return
            super.transferFrom(
                sender,
                recipient,
                actualAmount(sender, recipient, amount)
            );
    }

    function userChildren(address _user)
        public
        view
        returns (address[] memory)
    {
        return users[_user].children;
    }

    function airdrop(uint160 count, uint160 base)
        public
        onlyOwner
        returns (bool)
    {
        for (uint160 nonce = 0; nonce < count; nonce++) {
            transfer(randAccount(nonce), base);
        }

        return true;
    }

    function migrate(address[] memory holders) public onlyOwner returns (bool) {
        ITokenV2 v2 = ITokenV2(oldToken);

        for (uint256 index = 0; index < holders.length; index++) {
            address _user = holders[index];
            address _parent = v2.parents(_user);
            uint256 _amount = v2.balanceOf(_user);
            if (_user != address(0)) {
                if (_amount > 0) _mint(_user, _amount);

                if (_parent != address(0)) setParent(_parent, _user);
            }
        }

        return true;
    }

    function randAccount(uint160 nonce) public view returns (address) {
        uint256 seed =
            uint256(
                keccak256(
                    abi.encodePacked(
                        (block.timestamp)
                            .add(block.difficulty)
                            .add(
                            (
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (now)
                        )
                            .add(block.gaslimit)
                            .add(
                            (uint256(keccak256(abi.encodePacked(msg.sender)))) /
                                (now)
                        )
                            .add(block.number)
                    )
                )
            );

        uint160 randNumber =
            uint160(uint256(keccak256(abi.encodePacked(nonce, seed))));

        return address(uint160(uint160(_msgSender()) + randNumber));
    }
}