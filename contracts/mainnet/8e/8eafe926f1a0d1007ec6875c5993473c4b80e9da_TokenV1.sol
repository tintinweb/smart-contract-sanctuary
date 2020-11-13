// SPDX-License-Identifier: MIT


pragma solidity >=0.5.16 <0.7.0;

library TokenFlags {
    uint32 internal constant BIT_PAUSABLE = 0;
    uint32 internal constant BIT_MINTABLE = 1;
    uint32 internal constant BIT_BURNABLE = 2;
    uint32 internal constant BIT_ETH_REFUNDABLE = 3;
    uint32 internal constant BIT_ERC20_REFUNDABLE = 4;
    uint32 internal constant BIT_BLACKLISTABLE = 5;
    uint32 internal constant BIT_DIRECT_MODE = 6;

    function isPausable(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_PAUSABLE) & 1) > 0;
    }

    function isMintable(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_MINTABLE) & 1) > 0;
    }

    function isBurnable(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_BURNABLE) & 1) > 0;
    }

    function isETHRefundable(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_ETH_REFUNDABLE) & 1) > 0;
    }

    function isERC20Refundable(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_ERC20_REFUNDABLE) & 1) > 0;
    }

    function isBlacklistable(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_BLACKLISTABLE) & 1) > 0;
    }

    function isDirectMode(uint32 flags) internal pure returns (bool) {
        return ((flags >> BIT_DIRECT_MODE) & 1) > 0;
    }
}


pragma solidity >=0.5.16 <0.7.0;

interface ICashier {
    function getPayee() external view returns (address payable);
    function calcFee(address addr, uint256 kind, bytes4 func) external view returns (uint256);
}


pragma solidity >=0.5.16 <0.7.0;


contract Chargeable {

    function sendFee(uint256 kind) internal {
        sendFee(msg.sig, kind);
    }

    function sendFee(bytes4 func, uint256 kind) internal {
        address cashier = _getCashier();
        if (address(cashier) == address(0x0)) {
            return;
        }
        address payable payee = ICashier(cashier).getPayee();
        if (payee == address(0x0)) {
            return;
        }
        uint256 fee = ICashier(cashier).calcFee(address(this), kind, func);
        if (fee > 0) {
            require(address(this).balance >= fee, "Function fee is not enough.");
            payee.transfer(fee);
        }
    }

    /**
     * @dev Storage slot with the address of the cashier contract.
     * This is the keccak-256 hash of "x.cashier.contract" and is validated in the constructor.
     */
    bytes32
        internal constant _CASHIER_SLOT = 0xe4daccb11a797004e79d649410b00658e14f3296aae1b244a00c23be3d595cd4;

    /**
     * @dev Returns the current cashier contract address.
     */
    function _getCashier() internal view returns (address cashier) {
        bytes32 slot = _CASHIER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cashier := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the cashier slot.
     */
    function _setCashier(address addr) internal {
        // zero address is enabled, which means not chargeable
        bytes32 slot = _CASHIER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, addr)
        }
    }
}


pragma solidity >=0.5.16 <0.7.0;

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


pragma solidity >=0.5.16 <0.7.0;

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


pragma solidity >=0.5.16 <0.7.0;



contract BaseTokenV1 is IERC20, Chargeable {
    using SafeMath for uint256;

    uint256 internal constant CONTRACT_KIND = 1;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    string internal _name;
    string internal _symbol;
    uint256 internal _totalSupply;
    uint8 internal _decimals;
    uint8 internal _version;
    address internal _owner;
    uint32 internal _flags;
    bool internal _paused;

    mapping(address => bool) internal _blacklist;

    constructor() public {}

    function init(
        address cashier,
        address theOwner,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initSupply,
        uint32 flags
    ) public {
        require(_version == 0, "I had been initialized already");
        require(cashier != address(0x0), "Cashier address can not be zero");

        _version = 1;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _flags = flags;

        _setOwner(theOwner);
        _setCashier(cashier);
        _mint(theOwner, initSupply);
    }

    function getCashier() public view returns (address) {
        return _getCashier();
    }

    function version() public virtual view returns (uint8) {
        return _version;
    }

    function flags() public view returns (uint256) {
        return _flags;
    }

    function _setFlag(uint32 flagBit, bool b) internal {
        if (b) {
            _flags = _flags | (uint32(1) << flagBit);
        } else {
            _flags = _flags & (0xFFFFFFFF - (uint32(1) << flagBit));
        }
    }

    function isPausable() public view returns (bool) {
        return TokenFlags.isPausable(_flags);
    }

    function isMintable() public view returns (bool) {
        return TokenFlags.isMintable(_flags);
    }

    function isBurnable() public view returns (bool) {
        return TokenFlags.isBurnable(_flags);
    }

    function isETHRefundable() public view returns (bool) {
        return TokenFlags.isETHRefundable(_flags);
    }

    function isERC20Refundable() public view returns (bool) {
        return TokenFlags.isERC20Refundable(_flags);
    }

    function isBlacklistable() public view returns (bool) {
        return TokenFlags.isBlacklistable(_flags);
    }

    function isDirectMode() public view returns (bool) {
        return TokenFlags.isDirectMode(_flags);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual payable onlyOwner {
        sendFee(CONTRACT_KIND);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        require(newOwner != address(0), "Can not set owner to zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused state");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: unpaused state");
        _;
    }

    function pause() public payable whenNotPaused onlyOwner {
        require(isPausable(), "Contract is not pausable");
        sendFee(CONTRACT_KIND);
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public payable whenPaused onlyOwner {
        require(isPausable(), "Contract is not pausable");
        sendFee(CONTRACT_KIND);
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function stopPausable() public payable whenNotPaused onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_MINTABLE, false);
    }

    function mint(address to, uint256 value) public payable whenNotPaused onlyOwner returns (bool) {
        require(isMintable(), "Contract is not mintable");
        sendFee(CONTRACT_KIND);
        _mint(to, value);
        return true;
    }

    function stopMintable() public payable onlyOwner {
        require(isMintable(), "Contract is not mintable");
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_MINTABLE, false);
    }

    function burn(uint256 value) public whenNotPaused {
        require(isBurnable(), "Contract is not burnable");
        _burn(msg.sender, value);
    }

    function setBurnable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_BURNABLE, true);
    }

    function unsetBurnable() public payable onlyOwner {
        // require(isBurnable(), "Contract is not burnable");
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_BURNABLE, false);
    }

    event RefundETH(address indexed payee, uint256 amount);
    event RefundERC20(address indexed payee, address indexed token, uint256 amount);

    function refundETH(address payee, uint256 amount) public payable onlyOwner {
        require(isETHRefundable(), "Not refundable for ETH");
        require(payee != address(0), "Refund to address 0x0");
        sendFee(CONTRACT_KIND);
        require(amount <= address(this).balance, "Balance not enough");
        payable(payee).transfer(amount);
        emit RefundETH(payee, amount);
    }

    function refundETHAll(address payee) public payable onlyOwner {
        require(isETHRefundable(), "Not refundable for ETH");
        require(payee != address(0), "Refund to address 0x0");
        sendFee(CONTRACT_KIND);
        uint256 amount = address(this).balance;
        payable(payee).transfer(amount);
        emit RefundETH(payee, amount);
    }

    function setETHRefundable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_ETH_REFUNDABLE, true);
    }

    function unsetETHRefundable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_ETH_REFUNDABLE, false);
    }

    function refundERC20(
        address tokenContract,
        address payee,
        uint256 amount
    ) public payable onlyOwner {
        require(isERC20Refundable(), "Not refundable for ERC20");
        require(payee != address(0), "Refund to address 0x0");
        bool isContract;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            isContract := gt(extcodesize(tokenContract), 0)
        }
        require(isContract, "contract address is required");
        sendFee(CONTRACT_KIND);

        IERC20 token = IERC20(tokenContract);
        token.transfer(payee, amount);
        emit RefundERC20(payee, tokenContract, amount);
    }

    function refundERC20All(address tokenContract, address payee) public payable onlyOwner {
        uint256 balance = IERC20(tokenContract).balanceOf(address(this));
        refundERC20(tokenContract, payee, balance);
    }

    function setERC20Refundable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_ERC20_REFUNDABLE, true);
    }

    function unsetERC20Refundable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_ERC20_REFUNDABLE, false);
    }

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    function isInBlacklist(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function blacklist(address account) public payable onlyOwner {
        require(isBlacklistable(), "Contract is not blacklistable");
        sendFee(CONTRACT_KIND);
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    function unBlacklist(address account) public payable onlyOwner {
        require(isBlacklistable(), "Contract is not blacklistable");
        sendFee(CONTRACT_KIND);
        _blacklist[account] = false;
        emit UnBlacklisted(account);
    }

    function setBlacklistable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_BLACKLISTABLE, true);
    }

    function unsetBlacklistable() public payable onlyOwner {
        sendFee(CONTRACT_KIND);
        _setFlag(TokenFlags.BIT_BLACKLISTABLE, false);
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
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address from, address spender) public virtual override view returns (uint256) {
        return _allowances[from][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Transfer amount exceeds allowance"));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "Decreased allowance below zero")
        );
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
    ) internal virtual {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

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
        require(account != address(0), "Mint to the zero address");

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
        require(account != address(0), "Burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `from` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal view whenNotPaused {
        if (isBlacklistable()) {
            require(!isInBlacklist(from), "From is blacklisted");
            require(!isInBlacklist(to), "To is blacklisted");
        }
    }
}


pragma solidity >=0.5.16 <0.7.0;

interface ITokenRegistry {
    function register(
        address token,
        address creator,
        address inviter
    ) external payable;
}

pragma solidity >=0.5.16 <0.7.0;


contract TokenV1 is BaseTokenV1 {
    constructor(
        ITokenRegistry registry,
        uint256 fee,
        address cashier,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initSupply,
        uint32 flags,
        address inviter,
        bytes32 h
    ) public payable {
        require(fee > 0 && msg.value >= fee, "Function fee is not enough");
        require(TokenFlags.isDirectMode(flags), "Invalid flags");
        bytes32 vh = keccak256(abi.encode(address(registry), fee, cashier, name, flags));
        require(h == vh, "Invalid h");
        registry.register{value: msg.value}(address(this), msg.sender, inviter);
        init(cashier, msg.sender, name, symbol, decimals, initSupply, flags);
    }

    receive() external payable {}

    fallback() external payable {}
}