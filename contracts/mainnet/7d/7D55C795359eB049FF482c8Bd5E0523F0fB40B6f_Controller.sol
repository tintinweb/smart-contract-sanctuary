/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// File: @openzeppelin/contracts/math/SafeMath.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        uint c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
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
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
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
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

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
        uint amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// File: contracts/protocol/IController.sol

interface IController {
    function ADMIN_ROLE() external view returns (bytes32);

    function HARVESTER_ROLE() external view returns (bytes32);

    function admin() external view returns (address);

    function treasury() external view returns (address);

    function setAdmin(address _admin) external;

    function setTreasury(address _treasury) external;

    function grantRole(bytes32 _role, address _addr) external;

    function revokeRole(bytes32 _role, address _addr) external;

    /*
    @notice Set strategy for vault
    @param _vault Address of vault
    @param _strategy Address of strategy
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    */
    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external;

    // calls to strategy
    /*
    @notice Invest token in vault into strategy
    @param _vault Address of vault
    */
    function invest(address _vault) external;

    function harvest(address _strategy) external;

    function skim(address _strategy) external;

    /*
    @notice Withdraw from strategy to vault
    @param _strategy Address of strategy
    @param _amount Amount of underlying token to withdraw
    @param _min Minimum amount of underlying token to withdraw
    */
    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    ) external;

    /*
    @notice Withdraw all from strategy to vault
    @param _strategy Address of strategy
    @param _min Minimum amount of underlying token to withdraw
    */
    function withdrawAll(address _strategy, uint _min) external;

    /*
    @notice Exit from strategy
    @param _strategy Address of strategy
    @param _min Minimum amount of underlying token to withdraw
    */
    function exit(address _strategy, uint _min) external;
}

// File: contracts/protocol/IVault.sol

/*
version 1.2.0

Changes
- function deposit(uint) declared in IERC20Vault
*/

interface IVault {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function timeLock() external view returns (address);

    /*
    @notice For EthVault, must return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    */
    function token() external view returns (address);

    function strategy() external view returns (address);

    function strategies(address _strategy) external view returns (bool);

    function reserveMin() external view returns (uint);

    function withdrawFee() external view returns (uint);

    function paused() external view returns (bool);

    function whitelist(address _addr) external view returns (bool);

    function setWhitelist(address _addr, bool _approve) external;

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setTimeLock(address _timeLock) external;

    function setPause(bool _paused) external;

    function setReserveMin(uint _reserveMin) external;

    function setWithdrawFee(uint _fee) external;

    /*
    @notice Returns the amount of asset (ETH or ERC20) in the vault
    */
    function balanceInVault() external view returns (uint);

    /*
    @notice Returns the estimate amount of asset in strategy
    @dev Output may vary depending on price of liquidity provider token
         where the underlying asset is invested
    */
    function balanceInStrategy() external view returns (uint);

    /*
    @notice Returns amount of tokens invested strategy
    */
    function totalDebtInStrategy() external view returns (uint);

    /*
    @notice Returns the total amount of asset in vault + total debt
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Returns minimum amount of tokens that should be kept in vault for
            cheap withdraw
    @return Reserve amount
    */
    function minReserve() external view returns (uint);

    /*
    @notice Returns the amount of tokens available to be invested
    */
    function availableToInvest() external view returns (uint);

    /*
    @notice Approve strategy
    @param _strategy Address of strategy
    */
    function approveStrategy(address _strategy) external;

    /*
    @notice Revoke strategy
    @param _strategy Address of strategy
    */
    function revokeStrategy(address _strategy) external;

    /*
    @notice Set strategy
    @param _min Minimum undelying asset current strategy must return. Prevents slippage
    */
    function setStrategy(address _strategy, uint _min) external;

    /*
    @notice Transfers asset in vault to strategy
    */
    function invest() external;

    /*
    @notice Calculate amount of asset that can be withdrawn
    @param _shares Amount of shares
    @return Amount of asset that can be withdrawn
    */
    function getExpectedReturn(uint _shares) external view returns (uint);

    /*
    @notice Withdraw asset
    @param _shares Amount of shares to burn
    @param _min Minimum amount of asset expected to return
    */
    function withdraw(uint _shares, uint _min) external;

    /*
    @notice Transfer asset in vault to admin
    @param _token Address of asset to transfer
    @dev _token must not be equal to vault asset
    */
    function sweep(address _token) external;
}

// File: contracts/protocol/IStrategy.sol

/*
version 1.2.0

Changes

Changes listed here do not affect interaction with other contracts (Vault and Controller)
- removed function assets(address _token) external view returns (bool);
- remove function deposit(uint), declared in IStrategyERC20
- add function setSlippage(uint _slippage);
- add function setDelta(uint _delta);
*/

interface IStrategy {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function vault() external view returns (address);

    /*
    @notice Returns address of underlying asset (ETH or ERC20)
    @dev Must return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH strategy
    */
    function underlying() external view returns (address);

    /*
    @notice Returns total amount of underlying transferred from vault
    */
    function totalDebt() external view returns (uint);

    function performanceFee() external view returns (uint);

    function slippage() external view returns (uint);

    /* 
    @notice Multiplier used to check total underlying <= total debt * delta / DELTA_MIN
    */
    function delta() external view returns (uint);

    /*
    @dev Flag to force exit in case normal exit fails
    */
    function forceExit() external view returns (bool);

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setPerformanceFee(uint _fee) external;

    function setSlippage(uint _slippage) external;

    function setDelta(uint _delta) external;

    function setForceExit(bool _forceExit) external;

    /*
    @notice Returns amount of underlying asset locked in this contract
    @dev Output may vary depending on price of liquidity provider token
         where the underlying asset is invested
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Withdraw `_amount` underlying asset
    @param amount Amount of underlying asset to withdraw
    */
    function withdraw(uint _amount) external;

    /*
    @notice Withdraw all underlying asset from strategy
    */
    function withdrawAll() external;

    /*
    @notice Sell any staking rewards for underlying and then deposit undelying
    */
    function harvest() external;

    /*
    @notice Increase total debt if profit > 0 and total assets <= max,
            otherwise transfers profit to vault.
    @dev Guard against manipulation of external price feed by checking that
         total assets is below factor of total debt
    */
    function skim() external;

    /*
    @notice Exit from strategy
    @dev Must transfer all underlying tokens back to vault
    */
    function exit() external;

    /*
    @notice Transfer token accidentally sent here to admin
    @param _token Address of token to transfer
    @dev _token must not be equal to underlying token
    */
    function sweep(address _token) external;
}

// File: contracts/AccessControl.sol

contract AccessControl {
    event GrantRole(bytes32 indexed role, address indexed addr);
    event RevokeRole(bytes32 indexed role, address indexed addr);

    mapping(bytes32 => mapping(address => bool)) public hasRole;

    modifier onlyAuthorized(bytes32 _role) {
        require(hasRole[_role][msg.sender], "!authorized");
        _;
    }

    function _grantRole(bytes32 _role, address _addr) internal {
        require(_addr != address(0), "address = zero");

        hasRole[_role][_addr] = true;

        emit GrantRole(_role, _addr);
    }

    function _revokeRole(bytes32 _role, address _addr) internal {
        require(_addr != address(0), "address = zero");

        hasRole[_role][_addr] = false;

        emit RevokeRole(_role, _addr);
    }
}

// File: contracts/Controller.sol

/*
version 1.2.0

Changes from Controller 1.1.0
- Check vault and strategy are approved by admin.
  Protect from arbitrary contract to be passed into invest, harvest, skim, etc...
- compatible with ERC20 and ETH vault / strategy
  (checks withdraw min for ERC20 and ETH strategies)
- add setStrategyAndInvest
*/

contract Controller is IController, AccessControl {
    using SafeMath for uint;

    event ApproveVault(address vault, bool approved);
    event ApproveStrategy(address strategy, bool approved);

    // WARNING: not address of ETH, used as placeholder
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant override ADMIN_ROLE =
        0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    // keccak256(abi.encodePacked("HARVESTER"));
    bytes32 public constant override HARVESTER_ROLE =
        0x27e3e4d29d60af3ae6456513164bb5db737d6fc8610aa36ad458736c9efb884c;

    address public override admin;
    // treasury must be able to receive ETH from ETH vault and strategy
    address public override treasury;

    // approved vaults
    mapping(address => bool) public vaults;
    // approved strategies
    mapping(address => bool) public strategies;

    constructor(address _treasury) public {
        require(_treasury != address(0), "treasury = zero address");

        admin = msg.sender;
        treasury = _treasury;

        _grantRole(ADMIN_ROLE, admin);
        _grantRole(HARVESTER_ROLE, admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier onlyApprovedVault(address _vault) {
        require(vaults[_vault], "!approved vault");
        _;
    }

    modifier onlyApprovedStrategy(address _strategy) {
        require(strategies[_strategy], "!approved strategy");
        _;
    }

    modifier isCurrentStrategy(address _strategy) {
        address vault = IStrategy(_strategy).vault();
        /*
        Check that _strategy is the current strategy used by the vault.
        */
        require(IVault(vault).strategy() == _strategy, "!strategy");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");

        _revokeRole(ADMIN_ROLE, admin);
        _revokeRole(HARVESTER_ROLE, admin);

        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(HARVESTER_ROLE, _admin);

        admin = _admin;
    }

    function setTreasury(address _treasury) external override onlyAdmin {
        require(_treasury != address(0), "treasury = zero address");
        treasury = _treasury;
    }

    function grantRole(bytes32 _role, address _addr) external override onlyAdmin {
        require(_role == ADMIN_ROLE || _role == HARVESTER_ROLE, "invalid role");
        _grantRole(_role, _addr);
    }

    function revokeRole(bytes32 _role, address _addr) external override onlyAdmin {
        require(_role == ADMIN_ROLE || _role == HARVESTER_ROLE, "invalid role");
        _revokeRole(_role, _addr);
    }

    function approveVault(address _vault) external onlyAdmin {
        require(!vaults[_vault], "already approved vault");
        vaults[_vault] = true;
        emit ApproveVault(_vault, true);
    }

    function revokeVault(address _vault) external onlyAdmin {
        require(vaults[_vault], "!approved vault");
        vaults[_vault] = false;
        emit ApproveVault(_vault, false);
    }

    function approveStrategy(address _strategy) external onlyAdmin {
        require(!strategies[_strategy], "already approved strategy");
        strategies[_strategy] = true;
        emit ApproveStrategy(_strategy, true);
    }

    function revokeStrategy(address _strategy) external onlyAdmin {
        require(strategies[_strategy], "!approved strategy");
        strategies[_strategy] = false;
        emit ApproveStrategy(_strategy, false);
    }

    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    )
        external
        override
        onlyAuthorized(ADMIN_ROLE)
        onlyApprovedVault(_vault)
        onlyApprovedStrategy(_strategy)
    {
        IVault(_vault).setStrategy(_strategy, _min);
    }

    function invest(address _vault)
        external
        override
        onlyAuthorized(HARVESTER_ROLE)
        onlyApprovedVault(_vault)
    {
        IVault(_vault).invest();
    }

    /*
    @notice Set strategy for vault and invest
    @param _vault Address of vault
    @param _strategy Address of strategy
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    @dev Set strategy and invest in single transaction to avoid front running
    */
    function setStrategyAndInvest(
        address _vault,
        address _strategy,
        uint _min
    )
        external
        onlyAuthorized(ADMIN_ROLE)
        onlyApprovedVault(_vault)
        onlyApprovedStrategy(_strategy)
    {
        IVault(_vault).setStrategy(_strategy, _min);
        IVault(_vault).invest();
    }

    function harvest(address _strategy)
        external
        override
        onlyAuthorized(HARVESTER_ROLE)
        onlyApprovedStrategy(_strategy)
        isCurrentStrategy(_strategy)
    {
        IStrategy(_strategy).harvest();
    }

    function skim(address _strategy)
        external
        override
        onlyAuthorized(HARVESTER_ROLE)
        onlyApprovedStrategy(_strategy)
        isCurrentStrategy(_strategy)
    {
        IStrategy(_strategy).skim();
    }

    modifier checkWithdraw(address _strategy, uint _min) {
        address vault = IStrategy(_strategy).vault();
        address token = IVault(vault).token();

        uint balBefore;
        uint balAfter;
        if (token == ETH) {
            balBefore = address(vault).balance;
            _;
            balAfter = address(vault).balance;
        } else {
            balBefore = IERC20(token).balanceOf(vault);
            _;
            balAfter = IERC20(token).balanceOf(vault);
        }

        require(balAfter.sub(balBefore) >= _min, "withdraw < min");
    }

    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    )
        external
        override
        onlyAuthorized(HARVESTER_ROLE)
        onlyApprovedStrategy(_strategy)
        isCurrentStrategy(_strategy)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).withdraw(_amount);
    }

    function withdrawAll(address _strategy, uint _min)
        external
        override
        onlyAuthorized(HARVESTER_ROLE)
        onlyApprovedStrategy(_strategy)
        isCurrentStrategy(_strategy)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).withdrawAll();
    }

    function exit(address _strategy, uint _min)
        external
        override
        onlyAuthorized(ADMIN_ROLE)
        onlyApprovedStrategy(_strategy)
        isCurrentStrategy(_strategy)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).exit();
    }
}