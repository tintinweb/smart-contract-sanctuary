// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;


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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IPowerKeeper {
    function usePower(address master) external returns (uint256);
    function power(address master) external view returns (uint256);
    function totalPower() external view returns (uint256);
    event PowerGained(address indexed master, uint256 amount);
    event PowerUsed(address indexed master, uint256 amount);
}

interface IMilker {
    function bandits(uint256 percent) external returns (uint256, uint256, uint256);
    function sheriffsVaultCommission() external returns (uint256);
    function sheriffsPotDistribution() external returns (uint256);
    function isWhitelisted(address holder) external view returns (bool);
    function getPeriod() external view returns (uint256);
}


contract Milk is Ownable, IMilker {
    using SafeMath for uint256;

    // Token details.
    string public constant name = "Cowboy.Finance";
    string public constant symbol = "MILK";
    uint256 public constant decimals = 18;

    // Token supply limitations.
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_TOKENS = 15 * 10**6;
    uint256 private constant MAX_SUPPLY = MAX_TOKENS * 10**decimals;
    uint256 private constant TOTAL_UNITS = MAX_UINT256 - (MAX_UINT256 % MAX_SUPPLY);

    // Tokenomics parameters.
    uint256 private constant INITIAL_PRODUCTION = 25_000 * 10**decimals;
    uint256 private constant PERIOD_LENGTH = 6 hours;
    uint256 private constant REDUCING_PERIODS = 28;
    uint256 private constant REDUCING_FACTOR = 10;

    // Hardcoded address to collect 5% dev team share.
    address private constant DEV_TEAM_ADDRESS = 0xFFCF83437a1Eb718933f39ebE75aD96335BC1BE4;

    // Address of StableV2 contracts staking COW, COW:WETH and MILK:WETH tokens.
    IPowerKeeper private _stableCow;    // COW
    IPowerKeeper private _stableCowLP;  // UniswapV2 Pair COW:WETH
    IPowerKeeper private _stableMilkLP; // UniswapV2 Pair MILK:WETH

    // Address of controller contract from which base refase functions can be called.
    address private _controller;

    // Token holders balances "in hand", balances in vaults, and spending allowances.
    mapping(address => uint256) private _balances; // in units
    mapping(address => uint256) private _vaults;   // in units
    mapping(address => mapping (address => uint256)) private _allowances;

    // Whitelisted balances are stored separately.
    mapping(address => uint256) private _whitelistedBalances; // in units
    mapping(address => bool) private _whitelist;

    // Token current state.
    uint256 private _startTime = MAX_UINT256;
    uint256 private _distributed;
    uint256 private _totalSupply;

    // Token supply (divided to several parts).
    uint256 private _supplyInBalances;
    uint256 private _supplyWhitelisted;
    uint256 private _supplyInSheriffsPot;
    uint256 private _supplyInSheriffsVault;

    // Values needed to convert between units and tokens (divided to several parts).
    uint256 private _maxBalancesSupply = MAX_SUPPLY;
    uint256 private _maxWhitelistedSupply = MAX_SUPPLY;
    uint256 private _maxSheriffsVaultSupply = MAX_SUPPLY;
    uint256 private _unitsPerTokenInBalances = TOTAL_UNITS.div(_maxBalancesSupply);
    uint256 private _unitsPerTokenWhitelisted = TOTAL_UNITS.div(_maxWhitelistedSupply);
    uint256 private _unitsPerTokenInSheriffsVault = TOTAL_UNITS.div(_maxSheriffsVaultSupply);

    // Contract configuration events
    event StartTimeSetUp(uint256 indexed startTime);
    event StableCowSetUp(address indexed stableCow);
    event StableCowLPSetUp(address indexed stableCowLP);
    event StableMilkLPSetUp(address indexed stableMilkLP);
    event ControllerSetUp(address indexed controller);
    event AddedToWhitelist(address indexed holder);
    event RemovedFromWhitelist(address indexed holder);

    // ERC20 token related events
    event Mint(address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Tokenomics mechanics events
    event Bandits(uint256 percent, uint256 totalAmount, uint256 arrestedAmount, uint256 burntAmount);
    event SheriffsVaultCommission(uint256 amount);
    event SheriffsPotDistribution(uint256 amount);
    event SheriffsVaultDeposit(address indexed holder, uint256 amount);
    event SheriffsVaultWithdraw(address indexed holder, uint256 amount);


    modifier validRecipient(address account) {
        require(account != address(0x0), "Milk: unable to send tokens to zero address");
        require(account != address(this), "Milk: unable to send tokens to the token contract");
        _;
    }

    modifier onlyController() {
        require(_controller == _msgSender(), "Milk: caller is not the controller");
        _;
    }


    constructor() public {
        _whitelist[DEV_TEAM_ADDRESS] = true;
        emit AddedToWhitelist(DEV_TEAM_ADDRESS);
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        _startTime = startTime;
        emit StartTimeSetUp(startTime);
    }

    function setStableCow(address stableCow) external onlyOwner {
        _stableCow = IPowerKeeper(stableCow);
        emit StableCowSetUp(stableCow);
    }

    function setStableCowLP(address stableCowLP) external onlyOwner {
        _stableCowLP = IPowerKeeper(stableCowLP);
        emit StableCowLPSetUp(stableCowLP);
    }

    function setStableMilkLP(address stableMilkLP) external onlyOwner {
        _stableMilkLP = IPowerKeeper(stableMilkLP);
        emit StableMilkLPSetUp(stableMilkLP);
    }

    function setController(address controller) external onlyOwner {
        _controller = controller;
        emit ControllerSetUp(controller);
    }

    ////////////////////////////////////////////////////////////////
    // Whitelist management
    ////////////////////////////////////////////////////////////////

    function addToWhitelist(address holder) external onlyOwner {
        require(address(_stableCow) != address(0), "Milk: StableV2 contract staking COW tokens is not set up");
        require(!_whitelist[holder], "Milk: already whitelisted");
        require(_stableCow.power(holder) == 0, "Milk: unable to whitelist COW tokens staker");
        _whitelist[holder] = true;
        uint256 tokens = _balances[holder].div(_unitsPerTokenInBalances);
        if (tokens > 0) {
            _whitelistedBalances[holder] = tokens.mul(_unitsPerTokenWhitelisted);
            _balances[holder] = 0;
            _supplyInBalances = _supplyInBalances.sub(tokens);
            _supplyWhitelisted = _supplyWhitelisted.add(tokens);
        }
        emit AddedToWhitelist(holder);
    }

    function removeFromWhitelist(address holder) external onlyOwner {
        require(address(_stableCow) != address(0), "Milk: StableV2 contract staking COW tokens is not set up");
        require(_whitelist[holder], "Milk: not whitelisted");
        _whitelist[holder] = false;
        uint256 tokens = _whitelistedBalances[holder].div(_unitsPerTokenWhitelisted);
        if (tokens > 0) {
            _balances[holder] = tokens.mul(_unitsPerTokenInBalances);
            _whitelistedBalances[holder] = 0;
            _supplyInBalances = _supplyInBalances.add(tokens);
            _supplyWhitelisted = _supplyWhitelisted.sub(tokens);
        }
        emit RemovedFromWhitelist(holder);
    }

    ////////////////////////////////////////////////////////////////
    // [Event] Bandits are coming!
    ////////////////////////////////////////////////////////////////

    function bandits(uint256 percent) external override onlyController returns (
        uint256 banditsAmount,
        uint256 arrestedAmount,
        uint256 burntAmount
    ) {
        uint256 undistributedAmount = getProductedAmount().sub(_distributed);
        // how many MILK has to be redistributed?
        uint256 banditsTotalAmount = _supplyInBalances.mul(percent).div(100);
        uint256 undistributedBanditsTotalAmount = undistributedAmount.mul(percent).div(100);
        // share for sheriffs pot - 90%
        uint256 banditsToPotAmount = banditsTotalAmount.mul(90).div(100);
        uint256 undistributedBanditsToPotAmount = undistributedBanditsTotalAmount.mul(90).div(100);
        // share to burn - 10%
        uint256 banditsBurnAmount = banditsTotalAmount.sub(banditsToPotAmount);
        uint256 undistributedBanditsBurnAmount = undistributedBanditsTotalAmount.sub(undistributedBanditsToPotAmount);

        // calc new total supply based on burn
        _totalSupply = _totalSupply.sub(banditsBurnAmount);
        // calc new supply in pot
        _supplyInSheriffsPot = _supplyInSheriffsPot.add(banditsToPotAmount).add(undistributedBanditsToPotAmount);
        // calc new total supply in balances - ignoring burn here
        _supplyInBalances = _supplyInBalances.sub(banditsTotalAmount);

        // calc new max supply
        _maxBalancesSupply = _maxBalancesSupply.sub(_maxBalancesSupply.mul(percent).div(100));
        // recalc units per milk for regular balances
        _unitsPerTokenInBalances = TOTAL_UNITS.div(_maxBalancesSupply);

        _distributed = _distributed.add(undistributedBanditsBurnAmount).add(undistributedBanditsToPotAmount);

        banditsAmount = banditsTotalAmount.add(undistributedBanditsTotalAmount);
        arrestedAmount = banditsToPotAmount.add(undistributedBanditsToPotAmount);
        burntAmount = banditsBurnAmount.add(undistributedBanditsBurnAmount);

        emit Bandits(percent, banditsAmount, arrestedAmount, burntAmount);
    }

    ////////////////////////////////////////////////////////////////
    // [Event] Sheriff's Vault commission
    ////////////////////////////////////////////////////////////////

    function sheriffsVaultCommission() external override onlyController returns (uint256 commission) {
        commission = _supplyInSheriffsVault.div(100);
        _supplyInSheriffsVault = _supplyInSheriffsVault.sub(commission);
        _supplyInSheriffsPot = _supplyInSheriffsPot.add(commission);
        _maxSheriffsVaultSupply = _maxSheriffsVaultSupply.sub(_maxSheriffsVaultSupply.div(100));
        _unitsPerTokenInSheriffsVault = TOTAL_UNITS.div(_maxSheriffsVaultSupply);
        emit SheriffsVaultCommission(commission);
    }

    ////////////////////////////////////////////////////////////////
    // [Event] Sheriff's Pot distribution
    ////////////////////////////////////////////////////////////////

    function sheriffsPotDistribution() external override onlyController returns (uint256 amount) {
        amount = _supplyInSheriffsPot;
        if (amount > 0 && _supplyInBalances > 0) {
            uint256 maxBalancesSupplyDelta = _maxBalancesSupply.mul(amount).div(_supplyInBalances);
            _supplyInBalances = _supplyInBalances.add(amount);
            _supplyInSheriffsPot = 0;
            _maxBalancesSupply = _maxBalancesSupply.add(maxBalancesSupplyDelta);
            _unitsPerTokenInBalances = TOTAL_UNITS.div(_maxBalancesSupply);
        }
        emit SheriffsPotDistribution(amount);
    }

    ////////////////////////////////////////////////////////////////
    // Sheriff's Vault
    ////////////////////////////////////////////////////////////////

    function putToSheriffsVault(uint256 amount) external {
        address holder = msg.sender;
        require(!_whitelist[holder], "Milk: whitelisted holders cannot use Sheriff's Vault");
        _updateBalance(holder);
        uint256 unitsInBalances = amount.mul(_unitsPerTokenInBalances);
        uint256 unitsInSheriffsVault = amount.mul(_unitsPerTokenInSheriffsVault);
        _balances[holder] = _balances[holder].sub(unitsInBalances);
        _vaults[holder] = _vaults[holder].add(unitsInSheriffsVault);
        _supplyInBalances = _supplyInBalances.sub(amount);
        _supplyInSheriffsVault = _supplyInSheriffsVault.add(amount);
        emit SheriffsVaultDeposit(holder, amount);
    }

    function takeFromSheriffsVault(uint256 amount) external {
        address holder = msg.sender;
        require(!_whitelist[holder], "Milk: whitelisted holders cannot use Sheriff's Vault");
        _updateBalance(holder);
        uint256 unitsInBalances = amount.mul(_unitsPerTokenInBalances);
        uint256 unitsInSheriffsVault = amount.mul(_unitsPerTokenInSheriffsVault);
        _balances[holder] = _balances[holder].add(unitsInBalances);
        _vaults[holder] = _vaults[holder].sub(unitsInSheriffsVault);
        _supplyInBalances = _supplyInBalances.add(amount);
        _supplyInSheriffsVault = _supplyInSheriffsVault.sub(amount);
        emit SheriffsVaultWithdraw(holder, amount);
    }

    ////////////////////////////////////////////////////////////////
    // [Token] Minting token
    // NOTE: Function mint() will be blocked when rewards
    // for stacking COWs to StableV1 are distributed.
    ////////////////////////////////////////////////////////////////

    function mint(address recipient, uint256 value) public validRecipient(recipient) onlyOwner returns (bool) {
        if (isWhitelisted(recipient)) {
            uint256 wunits = value.mul(_unitsPerTokenWhitelisted);
            _whitelistedBalances[recipient] = _whitelistedBalances[recipient].add(wunits);
            _supplyWhitelisted = _supplyWhitelisted.add(value);
        } else {
            uint256 units = value.mul(_unitsPerTokenInBalances);
            _balances[recipient] = _balances[recipient].add(units);
            _supplyInBalances = _supplyInBalances.add(value);
        }
        _totalSupply = _totalSupply.add(value);
        emit Mint(recipient, value);
        emit Transfer(0x0000000000000000000000000000000000000000, recipient, value);
        return true;
    }

    ////////////////////////////////////////////////////////////////
    // [Token] Transferring token
    ////////////////////////////////////////////////////////////////

    function transfer(address to, uint256 value) public validRecipient(to) returns (bool) {
        address from = msg.sender;
        _updateBalance(from);
        uint256 units = value.mul(_unitsPerTokenInBalances);
        uint256 wunits = value.mul(_unitsPerTokenWhitelisted);
        if (isWhitelisted(from) && isWhitelisted(to)) {
            _whitelistedBalances[from] = _whitelistedBalances[from].sub(wunits);
            _whitelistedBalances[to] = _whitelistedBalances[to].add(wunits);
        } else if (isWhitelisted(from)) {
            _whitelistedBalances[from] = _whitelistedBalances[from].sub(wunits);
            _balances[to] = _balances[to].add(units);
            _supplyInBalances = _supplyInBalances.add(value);
            _supplyWhitelisted = _supplyWhitelisted.sub(value);
        } else if (isWhitelisted(to)) {
            _balances[from] = _balances[from].sub(units);
            _whitelistedBalances[to] = _whitelistedBalances[to].add(wunits);
            _supplyInBalances = _supplyInBalances.sub(value);
            _supplyWhitelisted = _supplyWhitelisted.add(value);
        } else {
            _balances[from] = _balances[from].sub(units);
            _balances[to] = _balances[to].add(units);
        }
        emit Transfer(from, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public validRecipient(to) returns (bool) {
        _updateBalance(from);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        uint256 units = value.mul(_unitsPerTokenInBalances);
        uint256 wunits = value.mul(_unitsPerTokenWhitelisted);
        if (isWhitelisted(from) && isWhitelisted(to)) {
            _whitelistedBalances[from] = _whitelistedBalances[from].sub(wunits);
            _whitelistedBalances[to] = _whitelistedBalances[to].add(wunits);
        } else if (isWhitelisted(from)) {
            _whitelistedBalances[from] = _whitelistedBalances[from].sub(wunits);
            _balances[to] = _balances[to].add(units);
            _supplyInBalances = _supplyInBalances.add(value);
            _supplyWhitelisted = _supplyWhitelisted.sub(value);
        } else if (isWhitelisted(to)) {
            _balances[from] = _balances[from].sub(units);
            _whitelistedBalances[to] = _whitelistedBalances[to].add(wunits);
            _supplyInBalances = _supplyInBalances.sub(value);
            _supplyWhitelisted = _supplyWhitelisted.add(value);
        } else {
            _balances[from] = _balances[from].sub(units);
            _balances[to] = _balances[to].add(units);
        }
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    ////////////////////////////////////////////////////////////////
    // Contract getters
    ////////////////////////////////////////////////////////////////

    function isWhitelisted(address holder) public view override returns (bool) {
        return _whitelist[holder];
    }

    function getPeriod() public view override returns (uint256) {
        if (block.timestamp <= _startTime) {
            return 0;
        }
        return block.timestamp.sub(_startTime).div(PERIOD_LENGTH);
    }

    function getPeriodPart() public view returns (uint256) {
        if (block.timestamp <= _startTime) {
            return 0;
        }
        uint256 durationFromPeriodStart = block.timestamp
            .sub(_startTime.add(getPeriod().mul(PERIOD_LENGTH)));
        return durationFromPeriodStart.mul(10**18).div(PERIOD_LENGTH);
    }

    function getProductionAmount() public view returns(uint256) {
        uint256 reducings = getPeriod().div(REDUCING_PERIODS);
        uint256 production = INITIAL_PRODUCTION;
        for (uint256 i = 0; i < reducings; i++) {
            production = production.sub(production.div(REDUCING_FACTOR));
        }
        return production;
    }

    function getProductedAmount() public view returns(uint256) {
        uint256 period = getPeriod();
        uint256 reducings = period.div(REDUCING_PERIODS);
        uint256 productionAmount = INITIAL_PRODUCTION;
        uint256 productedAmount = 0;
        for (uint256 i = 0; i < reducings; i++) {
            productedAmount = productedAmount.add(productionAmount.mul(REDUCING_PERIODS));
            productionAmount = productionAmount.sub(productionAmount.div(REDUCING_FACTOR));
        }
        productedAmount = productedAmount.add(productionAmount.mul(period.sub(reducings.mul(REDUCING_PERIODS))));
        productedAmount = productedAmount.add(productionAmount.mul(getPeriodPart()).div(10**18));
        return productedAmount;
    }

    function getDistributedAmount() public view returns(uint256) {
        return _distributed;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.add(getProductedAmount()).sub(_distributed);
    }

    function holdersSupply() public view returns (uint256) {
        return _supplyInBalances;
    }

    function whitelistedSupply() public view returns (uint256) {
        return _supplyWhitelisted;
    }

    function sheriffsPotSupply() public view returns (uint256) {
        return _supplyInSheriffsPot;
    }

    function sheriffsVaultSupply() public view returns (uint256) {
        return _supplyInSheriffsVault;
    }

    function balanceOf(address account) public view returns (uint256) {

        // Calculate total amount of undistributed MILK tokens and divide it to shares
        uint256 undistributed = getProductedAmount().sub(_distributed);
        uint256 undistributedCow = undistributed.div(5); // 20%
        uint256 undistributedCowLP = (undistributed.sub(undistributedCow)).div(2); // 40%
        uint256 undistributedMilkLP = (undistributed.sub(undistributedCow)).sub(undistributedCowLP); // 40%

        // Calculate holder's amounts of undistributed MILK tokens
        if (address(_stableCow) != address(0)) {
            (uint256 power, uint256 totalPower) = (_stableCow.power(account), _stableCow.totalPower());
            undistributedCow = totalPower > 0 ? undistributedCow.mul(power).div(totalPower) : 0;
        } else {
            undistributedCow = 0;
        }
        if (address(_stableCowLP) != address(0)) {
            (uint256 power, uint256 totalPower) = (_stableCowLP.power(account), _stableCowLP.totalPower());
            undistributedCowLP = totalPower > 0 ? undistributedCowLP.mul(power).div(totalPower) : 0;
        } else {
            undistributedCowLP = 0;
        }
        if (address(_stableMilkLP) != address(0)) {
            (uint256 power, uint256 totalPower) = (_stableMilkLP.power(account), _stableMilkLP.totalPower());
            undistributedMilkLP = totalPower > 0 ? undistributedMilkLP.mul(power).div(totalPower) : 0;
        } else {
            undistributedMilkLP = 0;
        }

        // Substruct 5% from each amount to transfer to the developers team
        uint256 devTeamFee = (undistributedCow.add(undistributedCowLP).add(undistributedMilkLP)).div(20);

        // Calculate final MILK tokens amount to transfer to the holder
        undistributed = (undistributedCow.add(undistributedCowLP).add(undistributedMilkLP)).sub(devTeamFee);

        // Calculate whitelisted MILK tokens if any
        uint256 whitelisted = _whitelistedBalances[account].div(_unitsPerTokenWhitelisted);

        return (_balances[account].div(_unitsPerTokenInBalances)).add(undistributed).add(whitelisted);
    }

    function vaultOf(address account) public view returns (uint256) {
        return _vaults[account].div(_unitsPerTokenInSheriffsVault);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    ////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////

    function _updateBalance(address holder) private {

        // Calculate total amount of undistributed MILK tokens and divide it to shares
        uint256 undistributed = getProductedAmount().sub(_distributed);
        uint256 undistributedCow = undistributed.div(5); // 20%
        uint256 undistributedCowLP = (undistributed.sub(undistributedCow)).div(2); // 40%
        uint256 undistributedMilkLP = (undistributed.sub(undistributedCow)).sub(undistributedCowLP); // 40%

        // Calculate holder's amounts of undistributed MILK tokens
        if (address(_stableCow) != address(0)) {
            (uint256 power, uint256 totalPower) = (_stableCow.power(holder), _stableCow.totalPower());
            if (power > 0) {
                power = _stableCow.usePower(holder);
                undistributedCow = totalPower > 0 ? undistributedCow.mul(power).div(totalPower) : 0;
            }
        } else {
            undistributedCow = 0;
        }
        if (address(_stableCowLP) != address(0)) {
            (uint256 power, uint256 totalPower) = (_stableCowLP.power(holder), _stableCowLP.totalPower());
            if (power > 0) {
                power = _stableCowLP.usePower(holder);
                undistributedCowLP = totalPower > 0 ? undistributedCowLP.mul(power).div(totalPower) : 0;
            }
        } else {
            undistributedCowLP = 0;
        }
        if (address(_stableMilkLP) != address(0)) {
            (uint256 power, uint256 totalPower) = (_stableMilkLP.power(holder), _stableMilkLP.totalPower());
            if (power > 0) {
                power = _stableMilkLP.usePower(holder);
                undistributedMilkLP = totalPower > 0 ? undistributedMilkLP.mul(power).div(totalPower) : 0;
            }
        } else {
            undistributedMilkLP = 0;
        }

        // Substruct 5% from each amount to transfer to the developers team
        uint256 devTeamFee = (undistributedCow.add(undistributedCowLP).add(undistributedMilkLP)).div(20);

        // Calculate final MILK tokens amount to transfer to the holder
        uint256 tokens = undistributedCow.add(undistributedCowLP).add(undistributedMilkLP).sub(devTeamFee);

        // Transfer all MILK tokens farmed by the holder and not yet distributed
        _balances[holder] = _balances[holder].add(tokens.mul(_unitsPerTokenInBalances));
        _balances[DEV_TEAM_ADDRESS] = _balances[DEV_TEAM_ADDRESS].add(devTeamFee.mul(_unitsPerTokenWhitelisted));
        _distributed = _distributed.add(tokens).add(devTeamFee);
        _totalSupply = _totalSupply.add(tokens).add(devTeamFee);
        if (isWhitelisted(holder)) {
            _supplyWhitelisted = _supplyWhitelisted.add(tokens);
        } else {
            _supplyInBalances = _supplyInBalances.add(tokens);
        }
        if (isWhitelisted(DEV_TEAM_ADDRESS)) {
            _supplyWhitelisted = _supplyWhitelisted.add(devTeamFee);
        } else {
            _supplyInBalances = _supplyInBalances.add(devTeamFee);
        }
    }
}