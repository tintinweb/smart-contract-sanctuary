// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/iron/IIronMasterChef.sol";
import "../interfaces/iron/IIronSwap.sol";
import "../interfaces/iron/IIronSwapLP.sol";
import "../interfaces/common/IUniswapRouterV2.sol";

import "../strategy/FeeManager.sol";

/**
 * @dev Implementation of a yield optimizing strategy to manage yield reward funds. (Only on polygon chian)
 * This is the contract that control staking and distribute fees for a prize pool and any wallet such as 'harvester','strategist' and 'pinataFeeRecipient'.
 */
contract StrategyIronLP is Pausable, FeeManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========================== Variables ========================== */

    // Tokens Contracts
    address public outputToken; // Address of the output token.
    address public lpWant; // Address of the lp token required by masterchef for staking.
    address public depositToken; // Address of the token to be deposited.
    address public constant usdcToken =
        address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // Address of the USDC token.

    // Third-party Contracts
    address public masterchef; // Address of the masterchef that this strategy will go farm.
    address public pool; // Address of pool that this strategy will go add liquidity.
    address public unirouter; // Address of uniswap router.

    // Other Variables
    uint256 public poolId; // Id of pool in masterchef that this strategy will stake.
    uint256 public poolSize; // Number of tokens in pool.
    uint8 public depositIndex; // Index of the deposit token in pool.

    // Routes
    address[] public outputToDepositRoute; // Route for exchange the output token to the deposit token.
    address[] public outputToUSDCRoute; // Route for exchange the output token to the USDC token.

    /* ========================== Events ========================== */

    /**
     * @dev Emitted when someone call harvest.
     */
    event StrategyHarvest(address indexed harvester);

    /* ========================== Functions ========================== */

    /**
     * @dev Setting up contract's state, then give allowances for masterchef.
     * @param _outputToken address of the output token.
     * @param _lpWant address of the lp token required by masterchef for staking.
     * @param _masterchef address of the masterchef that this strategy will go farm.
     * @param _unirouter address of uniswap router.
     * @param _poolId id of pool in masterchef that this strategy will stake.
     * @param _depositIndex index of the deposit token in pool.
     * @param _outputToDepositRoute route for exchange the output token to the deposit token.
     * @param _manager address of PinataManager contract.
     */
    constructor(
        address _outputToken,
        address _lpWant,
        address _masterchef,
        address _unirouter,
        uint256 _poolId,
        uint8 _depositIndex,
        address[] memory _outputToDepositRoute,
        address _manager
    ) public PinataManageable(_manager) {
        outputToken = _outputToken;
        lpWant = _lpWant;
        masterchef = _masterchef;
        unirouter = _unirouter;

        poolId = _poolId;

        pool = IIronSwapLP(lpWant).swap();
        poolSize = IIronSwap(pool).getNumberOfTokens();
        depositToken = IIronSwap(pool).getToken(_depositIndex);

        require(
            _outputToDepositRoute[0] == outputToken,
            "StrategyIronLP: outputToDepositRoute[0] != outputToken"
        );
        require(
            _outputToDepositRoute[_outputToDepositRoute.length - 1] ==
                depositToken,
            "StrategyIronLP: Not depositToken!"
        );
        outputToDepositRoute = _outputToDepositRoute;

        outputToUSDCRoute = [outputToken, usdcToken];

        _giveAllowances();
    }

    /**
     * @dev stakes the funds to work in masterchef.
     */
    function deposit() public whenNotPaused {
        uint256 lpWantBal = IERC20(lpWant).balanceOf(address(this));

        if (lpWantBal > 0) {
            IIronMasterChef(masterchef).deposit(
                poolId,
                lpWantBal,
                address(this)
            );
        }
    }

    /**
     * @dev withdraw lpWant via the vault.
     * @param _amount amount of lpWant that want to widthraw.
     *  only allow to be call by vault.
     */
    function withdraw(uint256 _amount) external onlyVault {
        uint256 lpWantBal = IERC20(lpWant).balanceOf(address(this));

        if (lpWantBal < _amount) {
            IIronMasterChef(masterchef).withdraw(
                poolId,
                _amount.sub(lpWantBal),
                address(this)
            );
            lpWantBal = IERC20(lpWant).balanceOf(address(this));
        }

        if (lpWantBal > _amount) {
            lpWantBal = _amount;
        }

        if (getIfManager(tx.origin) || paused()) {
            // no fee.
            IERC20(lpWant).safeTransfer(getVault(), lpWantBal);
        } else {
            // have fee.
            uint256 withdrawalFeeAmount = lpWantBal.mul(WITHDRAWAL_FEE).div(
                WITHDRAWAL_MAX
            );
            IERC20(lpWant).safeTransfer(
                getVault(),
                lpWantBal.sub(withdrawalFeeAmount)
            );
        }
    }

    /**
     * @dev compounds earnings and charges performance fee.
     *  only allow to be call by end user (harvester).
     */
    function harvest()
        external
        whenNotPaused
        whenNotInState(IPinataManager.LOTTERY_STATE.WINNERS_PENDING)
    {
        require(
            msg.sender == tx.origin || msg.sender == address(manager),
            "StrategyCake: Can't call via the contract!"
        );

        IIronMasterChef(masterchef).harvest(poolId, address(this));
        _chargeFees();
        _addLiquidity();
        deposit();

        emit StrategyHarvest(msg.sender);
    }

    /**
     * @dev internal function to calulate and distribute fees.
     */
    function _chargeFees() internal {
        address prizePool = getPrizePool();
        address strategist = getStrategist();
        address pinataFeeRecipient = getPinataFeeRecipient();

        uint256 outputTokenBal = IERC20(outputToken).balanceOf(address(this));

        // transfer fee to prizePool. [default 50% outputTokenBal]
        uint256 prizePoolFeeAmount = outputTokenBal.mul(prizePoolFee).div(
            BALANCE_MAX
        );
        IERC20(outputToken).safeTransfer(prizePool, prizePoolFeeAmount);

        // 4.5% iceBal for common fees.
        outputTokenBal = outputTokenBal.sub(prizePoolFeeAmount).mul(45).div(
            1000
        );

        // transfer fee to harvester. [default 90% of 4.5% outputTokenBal]
        uint256 harvestCallFeeFeeAmount = outputTokenBal
            .mul(harvestCallFee)
            .div(MAX_FEE);
        IERC20(outputToken).safeTransfer(msg.sender, harvestCallFeeFeeAmount);

        // transfer fee to strategist. [default 10% of 4.5% outputTokenBal]
        uint256 strategistFeeAmount = outputTokenBal.mul(STRATEGIST_FEE).div(
            MAX_FEE
        );
        IERC20(outputToken).safeTransfer(strategist, strategistFeeAmount);

        // transfer fee to pinataFeeRecipient. [default 0% of 4.5% outputTokenBal]
        uint256 pinataFeeAmount = outputTokenBal.mul(pinataFee).div(MAX_FEE);
        if (pinataFeeAmount > 0) {
            // transfer with the usdc token
            IUniswapRouterV2(unirouter).swapExactTokensForTokens(
                pinataFeeAmount,
                0,
                outputToUSDCRoute,
                address(this),
                block.timestamp
            );
            pinataFeeAmount = IERC20(usdcToken).balanceOf(address(this));
            IERC20(usdcToken).safeTransfer(pinataFeeRecipient, pinataFeeAmount);
        }
    }

    /**
     * @dev add liquidity to the pool and get 'lpWant'.
     */
    function _addLiquidity() internal {
        uint256 outputTokenBal = IERC20(outputToken).balanceOf(address(this));

        IUniswapRouterV2(unirouter).swapExactTokensForTokens(
            outputTokenBal,
            0,
            outputToDepositRoute,
            address(this),
            block.timestamp
        );

        uint256 depositTokenBal = IERC20(depositToken).balanceOf(address(this));

        uint256[] memory amounts = new uint256[](poolSize);
        amounts[depositIndex] = depositTokenBal;

        IIronSwap(pool).addLiquidity(amounts, 0, block.timestamp);
    }

    /**
     * @dev calculate the total underlaying 'lpWant' held by the strategy.
     */
    function balanceOf() public view returns (uint256) {
        return balanceOfLpWant().add(balanceOfPool());
    }

    /**
     * @dev calculate how much 'lpWant' this contract holds.
     */
    function balanceOfLpWant() public view returns (uint256) {
        return IERC20(lpWant).balanceOf(address(this));
    }

    /**
     * @dev calculate how much 'lpWant' the strategy has working in the farm.
     */
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IIronMasterChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return _amount;
    }

    /**
     * @dev pending reward of strategy in masterchef.
     */
    function pendingReward() public view returns (uint256) {
        uint256 _pending = IIronMasterChef(masterchef).pendingReward(
            poolId,
            address(this)
        );
        return _pending;
    }

    /**
     * @dev return address of token that required by masterchef for staking.
     */
    function want() public view returns (address) {
        return lpWant;
    }

    /**
     * @dev called as part of strat migration. Sends all the available funds back to the vault.
     *  only allow to be call by vault.
     */
    function retireStrat() external onlyManager {
        IIronMasterChef(masterchef).emergencyWithdraw(poolId, address(this));

        uint256 lpWantBal = IERC20(lpWant).balanceOf(address(this));
        IERC20(lpWant).transfer(getVault(), lpWantBal);
    }

    /**
     * @dev pause deposits and withdraws all funds from the masterchef.
     *  only allow to be call by manager.
     */
    function panic() public onlyManager {
        pause();
        IIronMasterChef(masterchef).emergencyWithdraw(poolId, address(this));
    }

    /**
     * @dev pause this contract and remove allowance from related contracts.
     *  only allow to be call by manager.
     */
    function pause() public onlyManager {
        _pause();
        _removeAllowances();
    }

    /**
     * @dev unpause this contract, give allowances to related contracts and then continue staking in farm.
     *  only allow to be call by manager.
     */
    function unpause() external onlyManager {
        _unpause();
        _giveAllowances();
        deposit();
    }

    /**
     * @dev internal function to give allowances to related contracts.
     */
    function _giveAllowances() internal {
        IERC20(outputToken).safeApprove(unirouter, type(uint256).max);
        IERC20(lpWant).safeApprove(masterchef, type(uint256).max);
        IERC20(depositToken).safeApprove(pool, type(uint256).max);
    }

    /**
     * @dev internal function to remove allowance from related contracts.
     */
    function _removeAllowances() internal {
        IERC20(outputToken).safeApprove(unirouter, 0);
        IERC20(lpWant).safeApprove(masterchef, 0);
        IERC20(depositToken).safeApprove(pool, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IIronMasterChef {
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function poolLength() external view returns (uint256);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    function emergencyWithdraw(uint256 pid, address to) external;
    
    function pendingReward(uint256 pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IIronSwap {
    function getNumberOfTokens() external view returns (uint256);

    function getToken(uint8 index) external view returns (address);
    
    function addLiquidity(uint256[] memory amounts, uint256 minMintAmount, uint256 deadline) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IIronSwapLP {
    function swap() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IUniswapRouterV2 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../manager/PinataManageable.sol";

/**
 * @dev Base contract for strategy contract.
 * main purpose of it was to simply enable easier ways for setting any fees for the strategy.
 */
abstract contract FeeManager is PinataManageable {
    /* ========================== Variables ========================== */
    // Withdrawal fee
    uint256 public constant WITHDRAWAL_MAX = 1000;
    uint256 public constant WITHDRAWAL_FEE = 1;

    // Priza pool fee
    uint256 public constant BALANCE_MAX = 1000;
    uint256 public constant MAX_PRIZE_POOL_FEE = 500;
    uint256 public prizePoolFee = 500;

    // Common fee
    uint256 public constant MAX_FEE = 1000;
    uint256 public constant MAX_HARVEST_CALL_FEE = 900;
    uint256 public harvestCallFee = 900;
    uint256 public constant STRATEGIST_FEE = 100;
    uint256 public pinataFee = MAX_FEE - STRATEGIST_FEE - harvestCallFee;

    /* ========================== Functions ========================== */

    /**
     * @dev set new prizePoolFee.
     * @param _prizePoolFee new value of prizePoolFee.
     *  only allow to be call by manager.
     */
    function setPrizePoolFee(uint256 _prizePoolFee) external onlyManager {
        require(_prizePoolFee <= MAX_PRIZE_POOL_FEE, "FeeManager: Not cap!");

        prizePoolFee = _prizePoolFee;
    }

    /**
     * @dev set new harvestCallFee.
     * @param _harvestCallFee new value of harvestCallFee.
     *  only allow to be call by manager.
     */
    function setHarvestCallFee(uint256 _harvestCallFee) external onlyManager {
        require(
            _harvestCallFee <= MAX_HARVEST_CALL_FEE,
            "FeeManager: Not cap!"
        );

        harvestCallFee = _harvestCallFee;
        pinataFee = MAX_FEE - STRATEGIST_FEE - harvestCallFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPinataManager.sol";

/**
 * @dev Base contract for every contract which is part of Pinata Finance's Prize Farming Game pool.
 *  main purpose of it was to simply enable easier ways for reading PinataManager state.
 */
abstract contract PinataManageable {
    /* ========================== Variables ========================== */

    IPinataManager public manager; // PinataManager contract

    /* ========================== Constructor ========================== */

    /**
     * @dev Modifier to make a function callable only when called by random generator.
     *
     * Requirements:
     *
     * - The caller have to be setted as random generator.
     */
    modifier onlyRandomGenerator() {
        require(
            msg.sender == getRandomNumberGenerator(),
            "PinataManageable: Only random generator allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by manager.
     *
     * Requirements:
     *
     * - The caller have to be setted as manager.
     */
    modifier onlyManager() {
        require(
            msg.sender == address(manager) || manager.getIsManager(msg.sender),
            "PinataManageable: Only PinataManager allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by timekeeper.
     *
     * Requirements:
     *
     * - The caller have to be setted as timekeeper.
     */
    modifier onlyTimekeeper() {
        require(
            msg.sender == address(manager) || manager.getIsTimekeeper(msg.sender),
            "PinataManageable: Only Timekeeper allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by Vault.
     *
     * Requirements:
     *
     * - The caller have to be setted as vault.
     */
    modifier onlyVault() {
        require(
            msg.sender == getVault(),
            "PinataManageable: Only vault allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by prize pool.
     *
     * Requirements:
     *
     * - The caller have to be setted as prize pool.
     */
    modifier onlyPrizePool() {
        require(
            msg.sender == getPrizePool(),
            "PinataManageable: Only prize pool allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by strategy.
     *
     * Requirements:
     *
     * - The caller have to be setted as strategy.
     */
    modifier onlyStrategy() {
        require(
            msg.sender == getStrategy(),
            "PinataManageable: Only strategy allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when pool is not in undesired state.
     *
     * @param state is state wish to not allow.
     *
     * Requirements:
     *
     * - Must calling when pool is not in undesired state.
     *
     */
    modifier whenNotInState(IPinataManager.LOTTERY_STATE state) {
        require(getState() != state, "PinataManageable: Not in desire state!");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when pool is in desired state.
     *
     * @param state is state wish to allow.
     *
     * Requirements:
     *
     * - Must calling when pool is in desired state.
     *
     */
    modifier whenInState(IPinataManager.LOTTERY_STATE state) {
        require(getState() == state, "PinataManageable: Not in desire state!");
        _;
    }

    /* ========================== Functions ========================== */

    /**
     * @dev Linking to manager wishes to read its state.
     * @param _manager address of manager contract.
     */
    constructor(address _manager) public {
        manager = IPinataManager(_manager);
    }

    /* ========================== Getter Functions ========================== */

    /**
     * @dev Read current state of pool.
     */
    function getState() public view returns (IPinataManager.LOTTERY_STATE) {
        return manager.getState();
    }

    /**
     * @dev Read if address was manager.
     * @param _manager address wish to know.
     */
    function getIfManager(address _manager) public view returns (bool) {
        return manager.getIsManager(_manager);
    }

    /**
     * @dev Get current timeline of pool (openning, closing, drawing).
     */
    function getTimeline() public view returns (uint256, uint256, uint256) {
        return manager.getTimeline();
    }

    /**
     * @dev Read vault contract address.
     */
    function getVault() public view returns (address) {
        return manager.getVault();
    }

    /**
     * @dev Read strategy contract address.
     */
    function getStrategy() public view returns (address) {
        return manager.getStrategy();
    }

    /**
     * @dev Read prize pool contract address.
     */
    function getPrizePool() public view returns (address) {
        return manager.getPrizePool();
    }

    /**
     * @dev Read random number generator contract address.
     */
    function getRandomNumberGenerator() public view returns (address) {
        return manager.getRandomNumberGenerator();
    }

    /**
     * @dev Read strategist address.
     */
    function getStrategist() public view returns (address) {
        return manager.getStrategist();
    }

    /**
     * @dev Read pinata fee recipient address.
     */
    function getPinataFeeRecipient() public view returns (address) {
        return manager.getPinataFeeRecipient();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPinataManager {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER,
        WINNERS_PENDING,
        READY
    }

    function startNewLottery(uint256 _closingTime, uint256 _drawingTime)
        external;

    function closePool() external;

    function calculateWinners() external;

    function winnersCalculated() external;
    
    function rewardDistributed() external;

    function getState() external view returns (LOTTERY_STATE);

    function getTimeline()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getVault() external view returns (address);

    function getStrategy() external view returns (address);

    function getPrizePool() external view returns (address);

    function getRandomNumberGenerator() external view returns (address);

    function getStrategist() external view returns (address);

    function getPinataFeeRecipient() external view returns (address);

    function getIsManager(address manager) external view returns (bool);

    function getIsTimekeeper(address timekeeper) external view returns (bool);

    function setVault(address _vault) external;

    function setStrategy(address _strategy) external;

    function setPrizePool(address _prizePool) external;

    function setRandomNumberGenerator(address _randomNumberGenerator) external;

    function setStrategist(address _strategist) external;

    function setPinataFeeRecipient(address _pinataFeeRecipient) external;

    function setManager(address _manager, bool status) external;
}

