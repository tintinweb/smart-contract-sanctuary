/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-23
*/

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.4;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract Token is ERC20 {
    using SafeMath for uint256;
    address avax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // live avax
    // address avax = ; // testnet avax
    IERC20 token;
    uint256 internal _limitSupply;

    constructor() ERC20("LAVA", "LAVA") {
        _limitSupply = 1000000;
    }

    function limitSupply() public view returns (uint256) {
        return _limitSupply;
    }

    function availableSupply() public view returns (uint256) {
        return _limitSupply.sub(totalSupply());
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(availableSupply() >= amount, "Supply exceed");
        super._mint(account, amount);
    }
}

contract Lava is Token {
    using SafeMath for uint256;
    uint256 private startTime = 1111;
    address payable private ADMIN;

    uint256 public totalUsers;
    uint256 public totalAVAXStaked;
    uint256 public avaxDelegationFund;
    uint256 public totalTokenStaked;

    uint256 private constant ADV_FEE = 15; // Base 1.5%
    uint256 private constant DELEGATION_FEE = 50;

    uint256 private constant AVAX_DAILYPROFIT = 20;
    uint256 private constant TOKEN_DAILYPROFIT = 40;
    uint256 private constant PERCENT_DIVIDER = 1000;
    uint256 private constant PRICE_DIVIDER = 1 ether;
    uint256 private constant TIME_STEP = 1 days;
    uint256 private constant TIME_TO_UNSTAKE = 7 days;
    uint256 private constant SELL_LIMIT = 40000 ether;

    mapping(address => User) private users;
    mapping(uint256 => uint256) private sold;

    struct Stake {
        uint256 checkpoint;
        uint256 totalStaked;
        uint256 lastStakeTime;
        uint256 unClaimedTokens;
    }

    struct User {
        Stake sA;
        Stake sT;
    }

    event TokenOperation(
        address indexed account,
        string txType,
        uint256 tokenAmount,
        uint256 trxAmount
    );

    constructor() {
        token = IERC20(avax);

        ADMIN = payable(msg.sender);
        _mint(msg.sender, 1250);
    }

    modifier onlyOwner() {
        require(msg.sender == ADMIN, "Only owner can call this function");
        _;
    }

    function stakeAVAX(uint256 _amount) public payable {
        require(block.timestamp > 1639832400); // Saturday, December 18, 2021 1:00:00 PM GMT

        token.transferFrom(msg.sender, address(this), _amount); // added

        uint256 fee = _amount.mul(ADV_FEE).div(PERCENT_DIVIDER); // calculate fees on _amount and not msg.value
        uint256 delegationFee = _amount.mul(DELEGATION_FEE).div(
            PERCENT_DIVIDER
        );

        token.transfer(ADMIN, fee);

        User storage user = users[msg.sender];

        if (user.sA.totalStaked == 0) {
            user.sA.checkpoint = maxVal(block.timestamp, startTime);
            totalUsers++;
        } else {
            updateStakeAVAX_IP(msg.sender);
        }

        user.sA.lastStakeTime = block.timestamp;
        user.sA.totalStaked = user.sA.totalStaked.add(_amount);
        totalAVAXStaked = totalAVAXStaked.add(_amount);
        avaxDelegationFund = avaxDelegationFund.add(delegationFee);
    }

    function stakeToken(uint256 tokenAmount) public {
        User storage user = users[msg.sender];
        require(block.timestamp >= startTime, "Stake not available yet");
        require(
            tokenAmount <= balanceOf(msg.sender),
            "Insufficient Token Balance"
        );

        if (user.sT.totalStaked == 0) {
            user.sT.checkpoint = block.timestamp;
        } else {
            updateStakeToken_IP(msg.sender);
        }

        _transfer(msg.sender, address(this), tokenAmount);
        user.sT.lastStakeTime = block.timestamp;
        user.sT.totalStaked = user.sT.totalStaked.add(tokenAmount);
        totalTokenStaked = totalTokenStaked.add(tokenAmount);
    }

    function unStakeToken() public {
        User storage user = users[msg.sender];
        require(block.timestamp > user.sT.lastStakeTime.add(TIME_TO_UNSTAKE));
        updateStakeToken_IP(msg.sender);
        uint256 tokenAmount = user.sT.totalStaked;
        user.sT.totalStaked = 0;
        totalTokenStaked = totalTokenStaked.sub(tokenAmount);
        _transfer(address(this), msg.sender, tokenAmount);
    }

    function updateStakeAVAX_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeAVAX_IP(_addr);
        if (amount > 0) {
            user.sA.unClaimedTokens = user.sA.unClaimedTokens.add(amount);
            user.sA.checkpoint = block.timestamp;
        }
    }

    function getStakeAVAX_IP(address _addr)
        private
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        uint256 fr = user.sA.checkpoint;
        if (startTime > block.timestamp) {
            fr = block.timestamp;
        }
        uint256 Tarif = AVAX_DAILYPROFIT;
        uint256 to = block.timestamp;
        if (fr < to) {
            value = user
                .sA
                .totalStaked
                .mul(to - fr)
                .mul(Tarif)
                .div(TIME_STEP)
                .div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }

    function updateStakeToken_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeToken_IP(_addr);
        if (amount > 0) {
            user.sT.unClaimedTokens = user.sT.unClaimedTokens.add(amount);
            user.sT.checkpoint = block.timestamp;
        }
    }

    function getStakeToken_IP(address _addr)
        private
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        uint256 fr = user.sT.checkpoint;
        if (startTime > block.timestamp) {
            fr = block.timestamp;
        }
        uint256 Tarif = TOKEN_DAILYPROFIT;
        uint256 to = block.timestamp;
        if (fr < to) {
            value = user
                .sT
                .totalStaked
                .mul(to - fr)
                .mul(Tarif)
                .div(TIME_STEP)
                .div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }

    function claimToken_A() public {
        User storage user = users[msg.sender];

        updateStakeAVAX_IP(msg.sender);
        uint256 tokenAmount = user.sA.unClaimedTokens;
        user.sA.unClaimedTokens = 0;

        _mint(msg.sender, tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }

    function claimToken_T() public {
        User storage user = users[msg.sender];

        updateStakeToken_IP(msg.sender);
        uint256 tokenAmount = user.sT.unClaimedTokens;
        user.sT.unClaimedTokens = 0;

        _mint(msg.sender, tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }

    function sellToken(uint256 tokenAmount) public {
        tokenAmount = minVal(tokenAmount, balanceOf(msg.sender));
        require(tokenAmount > 0, "Token amount can not be 0");

        require(
            sold[getCurrentDay()].add(tokenAmount) <= SELL_LIMIT,
            "Daily Sell Limit exceed"
        );
        sold[getCurrentDay()] = sold[getCurrentDay()].add(tokenAmount);
        uint256 AVAXAmount = tokenToAVAX(tokenAmount);

        require(
            getContractAVAXBalance().sub(avaxDelegationFund) > AVAXAmount,
            "Insufficient Contract Balance"
        );
        _burn(msg.sender, tokenAmount);

        uint256 delegationFee = AVAXAmount.mul(DELEGATION_FEE).div(
            PERCENT_DIVIDER
        );
        avaxDelegationFund = avaxDelegationFund.add(delegationFee);
        token.transfer(msg.sender, AVAXAmount.sub(delegationFee));

        emit TokenOperation(msg.sender, "SELL", tokenAmount, AVAXAmount);
    }

    function getUserUnclaimedTokens_A(address _addr)
        public
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        return getStakeAVAX_IP(_addr).add(user.sA.unClaimedTokens);
    }

    function getUserUnclaimedTokens_T(address _addr)
        public
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        return getStakeToken_IP(_addr).add(user.sT.unClaimedTokens);
    }

    function pullDelegationFund() public onlyOwner {
        require(
            avaxDelegationFund >= 30,
            "Must have at least 30 AVAX in delegation fund"
        );
        token.transfer(ADMIN, avaxDelegationFund);
        avaxDelegationFund = 0;
    }

    function addToAvaxFund(uint256 _amount) public payable {
        require(_amount > 0, "Amount must be greater than 0");
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 delegationFee = _amount.mul(DELEGATION_FEE).div(
            PERCENT_DIVIDER
        );

        totalAVAXStaked = totalAVAXStaked.add(_amount);
        avaxDelegationFund = avaxDelegationFund.add(delegationFee);
    }

    function getContractAVAXBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function getAPY_M() public pure returns (uint256) {
        return AVAX_DAILYPROFIT.mul(365).div(10);
    }

    function getAPY_T() public pure returns (uint256) {
        return TOKEN_DAILYPROFIT.mul(365).div(10);
    }

    function getUserAVAXBalance(address _addr) public view returns (uint256) {
        return address(_addr).balance;
    }

    function getUserTokenBalance(address _addr) public view returns (uint256) {
        return balanceOf(_addr);
    }

    function getUserAVAXStaked(address _addr) public view returns (uint256) {
        return users[_addr].sA.totalStaked;
    }

    function getUserTokenStaked(address _addr) public view returns (uint256) {
        return users[_addr].sT.totalStaked;
    }

    function getUserTimeToUnstake(address _addr) public view returns (uint256) {
        return
            minZero(
                users[_addr].sT.lastStakeTime.add(TIME_TO_UNSTAKE),
                block.timestamp
            );
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 d1 = getContractAVAXBalance().mul(PRICE_DIVIDER);
        uint256 d2 = availableSupply().add(1);
        return d1.div(d2);
    }

    function AVAXToToken(uint256 AVAXAmount) public view returns (uint256) {
        return AVAXAmount.mul(PRICE_DIVIDER).div(getTokenPrice());
    }

    function tokenToAVAX(uint256 tokenAmount) public view returns (uint256) {
        return tokenAmount.mul(getTokenPrice()).div(PRICE_DIVIDER);
    }

    function getContractLaunchTime() public view returns (uint256) {
        return minZero(startTime, block.timestamp);
    }

    function getCurrentDay() public view returns (uint256) {
        return minZero(block.timestamp, startTime).div(TIME_STEP);
    }

    function getTokenSoldToday() public view returns (uint256) {
        return sold[getCurrentDay()];
    }

    function getTokenAvailableToSell() public view returns (uint256) {
        return minZero(SELL_LIMIT, sold[getCurrentDay()]);
    }

    function getTimeToNextDay() public view returns (uint256) {
        uint256 t = minZero(block.timestamp, startTime);
        uint256 g = getCurrentDay().mul(TIME_STEP);
        return g.add(TIME_STEP).sub(t);
    }

    function owner() public view returns (address) {
        return ADMIN;
    }

    function minZero(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    function maxVal(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    function minVal(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }
}