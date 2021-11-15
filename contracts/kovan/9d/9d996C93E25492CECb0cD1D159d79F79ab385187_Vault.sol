pragma solidity 0.5.16;


contract Storage {

    address public governance;
    address public controller;
    address public dev;

    constructor() public {
        governance = msg.sender;
        dev = msg.sender;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender) || isDev(msg.sender), "S0");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "S1");
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0), "S2");
        controller = _controller;
    }

    function isGovernance(address account) public view returns (bool) {
        return account == governance;
    }

    function isController(address account) public view returns (bool) {
        return account == controller;
    }

    function isDev(address account) public view returns (bool) {
        return account == dev;
    }
}

pragma solidity 0.5.16;

import "./library/SafeMath.sol";
import "./library/Address.sol";
import "./library/SafeERC20.sol";
import "./library/Math.sol";

import "./interface/IController.sol";
import "./interface/IERC20.sol";
import "./interface/IVault.sol";

import "./Storage.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
        _transfer(msg.sender, recipient, amount);
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "V1"));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "V2"));
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
        require(sender != address(0), "V3");
        require(recipient != address(0), "V4");

        _balances[sender] = _balances[sender].sub(amount, "V5");
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
        require(account != address(0), "V6");

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
        require(account != address(0), "V7");

        _balances[account] = _balances[account].sub(amount, "V8");
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
        require(owner != address(0), "V9");
        require(spender != address(0), "V10");

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
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "V11"));
    }

    uint256[50] private ______gap;
}


contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function initialize(string memory name, string memory symbol, uint8 decimals) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit {

    // uint256(keccak256("eip1967.governableInit.storage")) - 1 = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc
    bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

    modifier onlyGovernance(){
        require(Storage(_storage()).isGovernance(msg.sender), "V12");
        _;
    }
    modifier onlyControllerOrGovernance(){
        require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)), "V13");
        _;
    }

    constructor() public {
    }

    function _setStorage(address newStorage) internal {
        bytes32 slot = _STORAGE_SLOT;
        assembly {
            sstore(slot, newStorage)
        }
    }

    function setStorage(address _store) public onlyGovernance {
        require(_store != address(0), "V14");
        _setStorage(_store);
    }

    function _storage() internal view returns (address str) {
        bytes32 slot = _STORAGE_SLOT;
        assembly {
            str := sload(slot)
        }
    }


    function governance() public view returns (address) {
        return Storage(_storage()).governance();
    }

    function controller() public view returns (address) {
        return Storage(_storage()).controller();
    }
}

interface IStrategy {

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function withdrawStrategy(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
}

contract VaultStorage {
    uint256 public numerator;
    uint256 public denominator;
    uint256 public underlyingUnit;
    address public underlying;
    bool public initialized;
    bool public allowSharePriceDecrease;

    function initialize(
        uint256 _numerator,
        uint256 _denominator,
        address _underlying,
        uint256 _underlyingUnit
    ) internal {
        require(initialized == false, "initialized");
        numerator = _numerator;
        denominator = _denominator;
        underlyingUnit = _underlyingUnit;
        underlying = _underlying;
        allowSharePriceDecrease = true;
        initialized = true;
    }

    uint256[50] private ______gap;
}

contract Vault is ERC20, ERC20Detailed, ControllableInit, VaultStorage, IVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    address public strategy;

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    ) external {
        require(_toInvestNumerator <= _toInvestDenominator, "V15");
        require(_toInvestDenominator != 0, "V16");
        ERC20Detailed.initialize("aiUSDT_v2", "aiUSDT_v2", 6);
        VaultStorage.initialize(_toInvestNumerator, _toInvestDenominator, _underlying,
            10 ** uint256(ERC20Detailed(address(_underlying)).decimals()));
        _setStorage(_storage);
    }

    function setAllowSharePriceDecrease(bool _value) public onlyGovernance {
        allowSharePriceDecrease = _value;
    }


    function whenStrategyDefined() private view {
        require(strategy != address(0), "V17");
    }

    function defense() private view {
        require(!IController(controller()).greyList(msg.sender), "V18");
    }

    function doHardWork() public onlyControllerOrGovernance {
        whenStrategyDefined();
        uint256 sharePriceBeforeHardWork = getPricePerFullShare();
        invest();
        IStrategy(strategy).doHardWork();
        if (!allowSharePriceDecrease) {
            require(sharePriceBeforeHardWork <= getPricePerFullShare(), "V19");
        }
    }


    function underlyingBalanceInVault() view public returns (uint256) {
        return IERC20(underlying).balanceOf(address(this));
    }

    function underlyingBalanceWithInvestment() view public returns (uint256) {
        return strategy == address(0) ? underlyingBalanceInVault() : underlyingBalanceInVault().add(investedTokenAmount());
    }

    function investedTokenAmount() view public returns (uint256){
        return IStrategy(strategy).investedUnderlyingBalance();
    }

    function getPricePerFullShare() public view returns (uint256) {
        return totalSupply() == 0 ? underlyingUnit : underlyingUnit.mul(underlyingBalanceWithInvestment()).div(totalSupply());
    }

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return balanceOf(holder).mul(getPricePerFullShare()).div(underlyingUnit);
    }

    function setStrategy(address _strategy) external onlyGovernance {
        require(IStrategy(_strategy).vault() == address(this), "V20");
        require(IStrategy(_strategy).underlying() == underlying, "V21");
        if (strategy != address(0)) {
            withdrawAll();
        }
        strategy = _strategy;
        IERC20(underlying).safeApprove(address(strategy), 0);
        IERC20(underlying).safeApprove(address(strategy), uint256(~0));
    }

    function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external onlyGovernance {
        require(denominator > 0, "V22");
        require(numerator <= denominator, "V23");
        numerator = _numerator;
        denominator = _denominator;

    }

    function rebalance(uint256 amount) public onlyControllerOrGovernance {
        require(amount < investedTokenAmount(), "V24");
        whenStrategyDefined();
        IStrategy(strategy).withdrawStrategy(amount);
    }

    function availableToInvestOut() public view returns (uint256) {
        uint256 wantInvestInTotal = underlyingBalanceWithInvestment().mul(numerator).div(denominator);
        uint256 alreadyInvested = investedTokenAmount();
        if (alreadyInvested >= wantInvestInTotal) {
            return 0;
        } else {
            uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
            return remainingToInvest <= underlyingBalanceInVault() ? remainingToInvest : underlyingBalanceInVault();
        }
    }

    function invest() internal {
        whenStrategyDefined();
        uint256 availableAmount = availableToInvestOut();
        if (availableAmount > 0) {
            IERC20(underlying).safeTransfer(strategy, availableAmount);
        }
    }

    function deposit(uint256 amount) external {
        defense();
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address holder) public {
        defense();
        _deposit(amount, msg.sender, holder);
    }

    function withdrawAll() public onlyControllerOrGovernance {
        whenStrategyDefined();
        IStrategy(strategy).withdrawAllToVault();
    }

    function withdraw(uint256 numberOfShares) external {
        require(totalSupply() > 0, "V25");
        require(numberOfShares > 0, "V26");
        uint256 totalSupply = totalSupply();
        _burn(msg.sender, numberOfShares);
        uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment().mul(numberOfShares).div(totalSupply);
        if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
            if (numberOfShares == totalSupply) {
                IStrategy(strategy).withdrawAllToVault();
            } else {
                uint256 missingUnderlying = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
                IStrategy(strategy).withdrawToVault(missingUnderlying);
            }
            underlyingAmountToWithdraw = Math.min(underlyingBalanceWithInvestment().mul(numberOfShares)
            .div(totalSupply), underlyingBalanceInVault());
        }

        IERC20(underlying).safeTransfer(msg.sender, underlyingAmountToWithdraw);
    }

    function _deposit(uint256 amount, address sender, address beneficiary) internal {
        require(amount > 0, "V27");
        require(beneficiary != address(0), "V28");

        if (address(strategy) != address(0)) {
            require(IStrategy(strategy).depositArbCheck(), "V29");
        }
        uint256 toMint = amount.mul(underlyingUnit).div(
            getPricePerFullShare()
        );
        _mint(beneficiary, toMint);

        IERC20(underlying).safeTransferFrom(sender, address(this), amount);
    }

    function salvage(address _token, address to, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(to, _amount);
    }
}

pragma solidity 0.5.16;

interface IController {

    function setOracleAddress(address _address) external;

    function setRewardPool(address _rewardPool) external;

    function addHardWorker(address _worker) external;

    function removeHardWorker(address _worker) external;

    function hasVault(address _vault) external returns (bool);

    function addToGreyList(address _target) external;

    function removeFromGreyList(address _target) external;

    function salvage(address _token, uint256 _amount, address to) external;

    function notifyFee(address underlying, uint256 fee) external;

    function setNewWeight(bytes calldata data) external;

    function requestFutureWeights(address _vault, address _requestConsumer) external;

    function cancelRequestFutureStrategy(address _vault) external;

    function addVaultAndStrategy(address _vault, address[] calldata _strategies, address[] calldata _bridgeStrategies, uint256[] calldata _weights) external;

    function doHardWork(address _vault) external;

    function greyList(address _target) external view returns (bool);

    function profitSharingNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);
}

pragma solidity 0.5.16;
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

pragma solidity 0.5.16;

interface IVault {

    function setAllowSharePriceDecrease(bool _value) external;

    function doHardWork() external;

    function underlyingBalanceInVault() view external returns (uint256);

    function underlyingBalanceWithInvestment() view external returns (uint256);

    function investedTokenAmount() view external returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    function setStrategy(address _strategy) external;

    function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external;

    function rebalance(uint256 amount) external;

    function availableToInvestOut() external view returns (uint256);

    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function strategy() external view returns (address);
}

pragma solidity 0.5.16;


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
        assembly {codehash := extcodehash(account)}
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.5.16;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity 0.5.16;

import "../interface/IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.16;
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

