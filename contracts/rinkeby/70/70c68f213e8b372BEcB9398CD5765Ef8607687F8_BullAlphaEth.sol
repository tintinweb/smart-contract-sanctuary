// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/SafeERC20.sol";
import "../utils/Pausable.sol";
import "./AlphaTokenEth.sol";

/**
 * @title BullAlpha
 * @dev Implementation of the contract BullAlpha.
 * Receive  deposited asset (stablecoin) from users.
 * Create LP token in return for deposited assets.
 * Burn LP and return assets (deposited asset + FORM based on a pre-defined APY).
 * Charge and send deposit and withdrawal fees to treasury wallet.
 * Calculate current TVL (value of all Alpha tokens).
 */

contract BullAlphaEth is Pausable, AlphaTokenEth {
    using SafeERC20 for IERC20;

    // helpers
    uint256 constant COEFF_SCALE_DECIMALS = 1e4;
    uint256 constant COEFF_SCALE_WEI = 1e18;

    // fees
    uint256 public DEPOSIT_FEES = 0;
    uint256 public PROFIT_FEES = 0;
    uint256 public MANAGEMENT_FEES = 0;
    uint256 public DEPOSIT_FEE_RATE = 20;
    uint256 public MANAGEMENT_FEE_RATE = 41;
    uint256 public PROFIT_FEE_RATE = 20;

    // Alpha token variables
    uint256 public NAV = 0;
    uint256 public ALPHA_PRICE = 1; // int or wei?
    uint256 public ALPHA_PRICE_WAVG = 1; // int or wei?

    // withdrawals
    uint256 public LOCKUP_PERIOD = 1 hours; // for testing purposes
    uint256 public totalPendingWithdrawalAmount;

    enum State {
        NONE,
        PENDING,
        READY
    }

    struct Pending {
        State state;
        uint256 amountAlpha;
        uint256 amountStable;
    }

    mapping(address => Pending) public pendingWithdrawal;
    address[] public usersOnPendingWithdrawal;

    // deposits
    uint256 public MIN_AMOUNT = 100 * 1e18;
    mapping(address => uint256) public lastDepositTime;

    // portfolio management
    address public MANAGER;

    // stable token instance
    IERC20 public _stableToken;

    /**
     * @dev Events emmited by the contract.
     */
    event LogDeposit(address indexed _user, uint256 _amount);
    event LogWithdraw(address indexed _user, uint256 _amount);
    event LogWithdrawRequested(address indexed _user, uint256 _amount);
    event LogVaultWithdrawal(address indexed _receiver, uint256 _amount);
    event LogChangeNAV(uint256 _nav);
    event LogChangeManager(address indexed _manager);
    event LogChangeLockupPeriod(uint256 _period);
    event LogMintDepositFees(uint256 _amount);
    event LogMintProfitFees(uint256 _amount);
    event LogMintManagementFees(uint256 _amount);
    event LogChangeDepositFeeRate(uint256 _fee);
    event LogChangeManagementFeeRateDay(uint256 _fee);
    event LogChangeProfitFeeRate(uint256 _fee);
    event LogSetStateToReady(address indexed _user);

    /**
     * Init
     */

    constructor(address _stableTokenAddress) {
        require(
            _stableTokenAddress != address(0),
            "Alpha: Stable token address is the zero address"
        );
        _stableToken = IERC20(_stableTokenAddress);
    }

    /*
     *  Modifiers
     */

    modifier onlyManager() {
        require(msg.sender == MANAGER);
        _;
    }

    /**
     * @dev getter functions.
     */

    function getTVL() public view returns (uint256) {
        return ALPHA_PRICE * totalSupply() * COEFF_SCALE_WEI;
    }

    /**
     * @dev setter functions.
     */

    // owner functions
    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Alpha: MANAGER address is the zero address"
        );
        MANAGER = _manager;
        emit LogChangeManager(_manager);
    }

    // manager functions
    function setLockupPeriod(uint256 _lockupPeriod) external onlyManager {
        LOCKUP_PERIOD = _lockupPeriod; // how to pass sth like '1 weeks' though?
        emit LogChangeLockupPeriod(_lockupPeriod);
    }

    function setDepositFeeRate(uint256 _fee) external onlyManager {
        DEPOSIT_FEE_RATE = _fee;
        emit LogChangeDepositFeeRate(_fee);
    }

    function setManagementFeeRateDay(uint256 _fee) external onlyManager {
        MANAGEMENT_FEE_RATE = _fee;
        emit LogChangeManagementFeeRateDay(_fee);
    }

    function setProfitFeeRate(uint256 _fee) external onlyManager {
        PROFIT_FEE_RATE = _fee;
        emit LogChangeProfitFeeRate(_fee);
    }

    function removeUsersFromPendingWithdrawal() external onlyManager {
        require(usersOnPendingWithdrawal.length != 0, "Alpha: no users with pending withdrawals");
        uint256 _index;
        uint256 _indexMax;
        for (uint256 i = 0; i < usersOnPendingWithdrawal.length; i++) {
            pendingWithdrawal[usersOnPendingWithdrawal[i]].state = State.READY;
            _index = find(usersOnPendingWithdrawal[i]);
            _indexMax = usersOnPendingWithdrawal.length;
            usersOnPendingWithdrawal[_index] = usersOnPendingWithdrawal[
                _indexMax - 1
            ];
            usersOnPendingWithdrawal.pop(); // need to verify if that is the best approach
            emit LogSetStateToReady(usersOnPendingWithdrawal[i]);
        }
    }

    function removeSelectedUsersFromPendingWithdrawal(address[] calldata _users) external onlyManager {
        uint256 _index;
        uint256 _indexMax;
        for (uint256 i = 0; i < _users.length; i++) {
            pendingWithdrawal[_users[i]].state = State.READY;
            _index = find(_users[i]);
            _indexMax = usersOnPendingWithdrawal.length;
            usersOnPendingWithdrawal[_index] = usersOnPendingWithdrawal[
                _indexMax - 1
            ];
            usersOnPendingWithdrawal.pop(); // need to verify if that is the best approach
            emit LogSetStateToReady(_users[i]);
        }
    }

    function calculateProfitFees() external onlyManager {
        PROFIT_FEES = (totalSupply() * max(0, (ALPHA_PRICE - ALPHA_PRICE_WAVG)) * PROFIT_FEE_RATE) / COEFF_SCALE_DECIMALS;
        if (ALPHA_PRICE > ALPHA_PRICE_WAVG) {
            ALPHA_PRICE_WAVG = ALPHA_PRICE;
        }
    }

    function calculateManagementFees() external onlyManager {
        MANAGEMENT_FEES = (totalSupply() * MANAGEMENT_FEE_RATE) / COEFF_SCALE_DECIMALS;
    }

    // function mintProfitFees() external onlyManager {
    //     uint256 alphaFeeAmount = PROFIT_FEES / ALPHA_PRICE;
    //     ALPHA_PRICE = NAV / (totalSupply() + alphaFeeAmount);
    //     _mint(msg.sender, alphaFeeAmount);
    //     PROFIT_FEES = 0;
    //     emit LogMintProfitFees(alphaFeeAmount);
    // }

    function mintProfitFees() external onlyManager {
        _mint(msg.sender, PROFIT_FEES);
        PROFIT_FEES = 0;
        emit LogMintDepositFees(PROFIT_FEES);
    }

    function mintDepositFees() external onlyManager {
        _mint(msg.sender, DEPOSIT_FEES);
        DEPOSIT_FEES = 0;
        emit LogMintDepositFees(DEPOSIT_FEES);
    }

    function mintManagementFees() external onlyManager {
        _mint(msg.sender, MANAGEMENT_FEES);
        MANAGEMENT_FEES = 0;
        emit LogMintManagementFees(MANAGEMENT_FEES);
    }

    function updatePortfolioValue(uint256 _nav) external onlyManager {
        NAV = _nav;
        ALPHA_PRICE = NAV / totalSupply(); // int or wei?
        emit LogChangeNAV(_nav);
    }

    /**
     * @dev money management
     */

    function vaultStableWithdrawal(uint256 _amount) external {
        require(msg.sender == MANAGER, "Alpha: incorrect receiver");
        require(
            _stableToken.balanceOf(address(this)) >= _amount,
            "Alpha: _amount exceeds contract balance"
        );
        _stableToken.safeTransferFrom(address(this), msg.sender, _amount);
        emit LogVaultWithdrawal(msg.sender, _amount);
    }

    function vaultFeesWithdrawal() external onlyManager {
        uint256 totalFees = DEPOSIT_FEES + PROFIT_FEES + MANAGEMENT_FEES;
        _transfer(address(this), MANAGER, totalFees);
        DEPOSIT_FEES = 0;
        PROFIT_FEES = 0;
        MANAGEMENT_FEES = 0;
    }

    /**
     * @dev user actions
     */

    function deposit(uint256 _amount) external whenNotPaused {
        require(_amount >= MIN_AMOUNT, "Alpha: amount does not satisfy minimum deposit amount");

        uint256 _alphaAmount = _amount / ALPHA_PRICE;
        
        uint256 _feeAlpha = (_alphaAmount * DEPOSIT_FEE_RATE) /
            COEFF_SCALE_DECIMALS;

        uint256 _depositAlpha = _amount - _feeAlpha;

        DEPOSIT_FEES = DEPOSIT_FEES + _feeAlpha;

        ALPHA_PRICE_WAVG =
            ((ALPHA_PRICE_WAVG * totalSupply()) + (_alphaAmount * ALPHA_PRICE)) /
            (totalSupply() + _alphaAmount);

        lastDepositTime[msg.sender] = block.timestamp;

        _stableToken.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _depositAlpha);
        emit LogDeposit(msg.sender, _amount);
    }

    function _requestWithdrawal(uint256 _amount) external whenNotPaused {
        require(
            block.timestamp - lastDepositTime[msg.sender] >= LOCKUP_PERIOD,
            "Alpha: Position locked"
        );

        require(
            (balanceOf(msg.sender)) >= _amount,
            "Alpha: _amount exceeds user balance"
        );
        require(
            pendingWithdrawal[msg.sender].amountStable == 0,
            "Alpha: request pending"
        );

        uint256 _amountStable = _amount * ALPHA_PRICE;

        pendingWithdrawal[msg.sender].amountAlpha = _amount;
        pendingWithdrawal[msg.sender].amountStable = _amountStable;
        pendingWithdrawal[msg.sender].state = State.PENDING;

        totalPendingWithdrawalAmount = totalPendingWithdrawalAmount + _amountStable;

        usersOnPendingWithdrawal.push(msg.sender);

        emit LogWithdrawRequested(msg.sender, _amountStable);
    }

    function withdraw() external whenNotPaused {
        Pending memory _pendingWithdrawal = pendingWithdrawal[msg.sender];

        uint256 _amountLP = _pendingWithdrawal.amountAlpha;
        uint256 _amountStable = _pendingWithdrawal.amountStable;
        State _state = _pendingWithdrawal.state;

        require(
            _state == State.READY,
            " Alpha: requested amount not yet ready"
        );
        require(
            _stableToken.balanceOf(address(this)) >= _amountStable,
            "Alpha: amount exceeds available amount"
        );
        require(
            balanceOf(msg.sender) >= _amountLP,
            "Alpha: amount exceeds available amount"
        );

        pendingWithdrawal[msg.sender].amountAlpha = 0;
        pendingWithdrawal[msg.sender].amountStable = 0;
        pendingWithdrawal[msg.sender].state = State.NONE;

        totalPendingWithdrawalAmount = totalPendingWithdrawalAmount - _amountStable;

        _stableToken.safeTransferFrom(address(this), msg.sender, _amountStable);
        _transfer(msg.sender, address(this), _amountLP);
        _burn(address(this), _amountLP);
        emit LogWithdraw(msg.sender, _amountStable);
    }

    function find(address _address) internal view returns (uint256) {
        address[] memory _usersOnPendingWithdrawal = usersOnPendingWithdrawal;
        uint256 i = 0;
        while (_usersOnPendingWithdrawal[i] != _address) {
            i++;
        }
        return i;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Transaction is not available");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Transaction is available");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x95d89b41)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x06fdde03)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x313ce567)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TransferFrom failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title AlphaToken
 * @dev Implementation of the LP Token "ALPHA".
 */

contract AlphaTokenEth is ERC20 {
    constructor() ERC20("Alpha token", "ALPHA") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
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