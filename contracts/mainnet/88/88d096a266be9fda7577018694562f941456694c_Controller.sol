// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/GasToken.sol";
import "./AccessControl.sol";

contract GasRelayer is AccessControl {
    bytes32 public constant GAS_TOKEN_USER_ROLE =
        keccak256(abi.encodePacked("GAS_TOKEN_USER"));

    address public admin;
    address public gasToken;

    constructor(address _gasToken) public {
        require(_gasToken != address(0), "gas token = zero address");

        admin = msg.sender;
        gasToken = _gasToken;

        _grantRole(GAS_TOKEN_USER_ROLE, admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    // @dev use CHI token from 1inch to burn gas token
    // https://medium.com/@1inch.exchange/1inch-introduces-chi-gastoken-d0bd5bb0f92b
    modifier useChi(uint _max) {
        uint gasStart = gasleft();
        _;
        uint gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        if (_max > 0) {
            GasToken(gasToken).freeUpTo(Math.min(_max, (gasSpent + 14154) / 41947));
        }
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    function authorized(address _addr) external view returns (bool) {
        return hasRole[GAS_TOKEN_USER_ROLE][_addr];
    }

    function authorize(address _addr) external onlyAdmin {
        _grantRole(GAS_TOKEN_USER_ROLE, _addr);
    }

    function unauthorize(address _addr) external onlyAdmin {
        _revokeRole(GAS_TOKEN_USER_ROLE, _addr);
    }

    function setGasToken(address _gasToken) external onlyAdmin {
        require(_gasToken != address(0), "gas token = zero address");
        gasToken = _gasToken;
    }

    function mintGasToken(uint _amount) external {
        GasToken(gasToken).mint(_amount);
    }

    function transferGasToken(address _to, uint _amount) external onlyAdmin {
        GasToken(gasToken).transfer(_to, _amount);
    }

    function relayTx(
        address _to,
        bytes calldata _data,
        uint _maxGasToken
    ) external onlyAuthorized(GAS_TOKEN_USER_ROLE) useChi(_maxGasToken) {
        (bool success, ) = _to.call(_data);
        require(success, "relay failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface GasToken {
    function mint(uint amount) external;

    function free(uint amount) external returns (bool);

    function freeUpTo(uint amount) external returns (uint);

    // ERC20
    function transfer(address _to, uint _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/GasToken.sol";

/* solium-disable */
contract MockGasToken is GasToken {
    // test helpers
    uint public _mintAmount_;
    uint public _freeAmount_;
    uint public _freeUpToAmount_;
    address public _transferTo_;
    uint public _transferAmount_;

    function mint(uint _amount) external override {
        _mintAmount_ = _amount;
    }

    function free(uint _amount) external override returns (bool) {
        _freeAmount_ = _amount;
        return true;
    }

    function freeUpTo(uint _amount) external override returns (uint) {
        _freeUpToAmount_ = _amount;
        return 0;
    }

    function transfer(address _to, uint _amount) external override returns (bool) {
        _transferTo_ = _to;
        _transferAmount_ = _amount;

        return true;
    }

    function balanceOf(address) external view override returns (uint) {
        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./protocol/IController.sol";
import "./protocol/IVault.sol";
import "./protocol/IStrategy.sol";
import "./AccessControl.sol";

contract Controller is IController, AccessControl {
    using SafeMath for uint;

    bytes32 public constant override ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant override HARVESTER_ROLE =
        keccak256(abi.encodePacked("HARVESTER"));

    address public override admin;
    address public override treasury;

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

    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external override onlyAuthorized(ADMIN_ROLE) {
        IVault(_vault).setStrategy(_strategy, _min);
    }

    function invest(address _vault) external override onlyAuthorized(HARVESTER_ROLE) {
        IVault(_vault).invest();
    }

    function harvest(address _strategy)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
    {
        IStrategy(_strategy).harvest();
    }

    function skim(address _strategy)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
    {
        IStrategy(_strategy).skim();
    }

    modifier checkWithdraw(address _strategy, uint _min) {
        address vault = IStrategy(_strategy).vault();
        address token = IVault(vault).token();

        uint balBefore = IERC20(token).balanceOf(vault);
        _;
        uint balAfter = IERC20(token).balanceOf(vault);

        require(balAfter.sub(balBefore) >= _min, "withdraw < min");
    }

    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    )
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).withdraw(_amount);
    }

    function withdrawAll(address _strategy, uint _min)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).withdrawAll();
    }

    function exit(address _strategy, uint _min)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(ADMIN_ROLE)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).exit();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IVault {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function timeLock() external view returns (address);

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
    @notice Returns the amount of token in the vault
    */
    function balanceInVault() external view returns (uint);

    /*
    @notice Returns the estimate amount of token in strategy
    @dev Output may vary depending on price of liquidity provider token
         where the underlying token is invested
    */
    function balanceInStrategy() external view returns (uint);

    /*
    @notice Returns amount of tokens invested strategy
    */
    function totalDebtInStrategy() external view returns (uint);

    /*
    @notice Returns the total amount of token in vault + total debt
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
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    */
    function setStrategy(address _strategy, uint _min) external;

    /*
    @notice Transfers token in vault to strategy
    */
    function invest() external;

    /*
    @notice Deposit undelying token into this vault
    @param _amount Amount of token to deposit
    */
    function deposit(uint _amount) external;

    /*
    @notice Calculate amount of token that can be withdrawn
    @param _shares Amount of shares
    @return Amount of token that can be withdrawn
    */
    function getExpectedReturn(uint _shares) external view returns (uint);

    /*
    @notice Withdraw token
    @param _shares Amount of shares to burn
    @param _min Minimum amount of token expected to return
    */
    function withdraw(uint _shares, uint _min) external;

    /*
    @notice Transfer token in vault to admin
    @param _token Address of token to transfer
    @dev _token must not be equal to vault token
    */
    function sweep(address _token) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IStrategy {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function vault() external view returns (address);

    /*
    @notice Returns address of underlying token
    */
    function underlying() external view returns (address);

    /*
    @notice Returns total amount of underlying transferred from vault
    */
    function totalDebt() external view returns (uint);

    function performanceFee() external view returns (uint);

    /*
    @notice Returns true if token cannot be swept
    */
    function assets(address _token) external view returns (bool);

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setPerformanceFee(uint _fee) external;

    /*
    @notice Returns amount of underlying stable coin locked in this contract
    @dev Output may vary depending on price of liquidity provider token
         where the underlying token is invested
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Deposit `amount` underlying token for yield token
    @param amount Amount of underlying token to deposit
    */
    function deposit(uint _amount) external;

    /*
    @notice Withdraw `amount` yield token to withdraw
    @param amount Amount of yield token to withdraw
    */
    function withdraw(uint _amount) external;

    /*
    @notice Withdraw all underlying token from strategy
    */
    function withdrawAll() external;

    function harvest() external;

    /*
    @notice Exit from strategy
    @dev Must transfer all underlying tokens back to vault
    */
    function exit() external;

    /*
    @notice Transfer profit over total debt to vault
    */
    function skim() external;

    /*
    @notice Transfer token in strategy to admin
    @param _token Address of token to transfer
    @dev Must transfer token to admin
    @dev _token must not be equal to underlying token
    @dev Used to transfer token that was accidentally sent or
         claim dust created from this strategy
    */
    function sweep(address _token) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./protocol/IStrategy.sol";
import "./protocol/IVault.sol";
import "./protocol/IController.sol";

/* potential hacks?
- directly send underlying token to this vault or strategy
- flash loan
    - flashloan make undelying token less valuable
    - vault deposit
    - flashloan make underlying token more valuable
    - vault withdraw
    - return loan
- front running?
*/

contract Vault is IVault, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event SetStrategy(address strategy);
    event ApproveStrategy(address strategy);
    event RevokeStrategy(address strategy);
    event SetWhitelist(address addr, bool approved);

    address public override admin;
    address public override controller;
    address public override timeLock;
    address public immutable override token;
    address public override strategy;

    // mapping of approved strategies
    mapping(address => bool) public override strategies;

    // percentange of token reserved in vault for cheap withdraw
    uint public override reserveMin = 500;
    uint private constant RESERVE_MAX = 10000;

    // Denominator used to calculate fees
    uint private constant FEE_MAX = 10000;

    uint public override withdrawFee;
    uint private constant WITHDRAW_FEE_CAP = 500; // upper limit to withdrawFee

    bool public override paused;

    // whitelisted addresses
    // used to prevent flash loah attacks
    mapping(address => bool) public override whitelist;

    /*
    @dev vault decimals must be equal to token decimals
    */
    constructor(
        address _controller,
        address _timeLock,
        address _token
    )
        public
        ERC20(
            string(abi.encodePacked("unagii_", ERC20(_token).name())),
            string(abi.encodePacked("u", ERC20(_token).symbol()))
        )
    {
        require(_controller != address(0), "controller = zero address");
        require(_timeLock != address(0), "time lock = zero address");

        _setupDecimals(ERC20(_token).decimals());

        admin = msg.sender;
        controller = _controller;
        token = _token;
        timeLock = _timeLock;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier onlyTimeLock() {
        require(msg.sender == timeLock, "!time lock");
        _;
    }

    modifier onlyAdminOrController() {
        require(msg.sender == admin || msg.sender == controller, "!authorized");
        _;
    }

    modifier whenStrategyDefined() {
        require(strategy != address(0), "strategy = zero address");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /*
    @dev modifier to prevent flash loan
    @dev caller is restricted to EOA or whitelisted contract
    @dev Warning: Users can have their funds stuck if shares is transferred to a contract
    */
    modifier guard() {
        require((msg.sender == tx.origin) || whitelist[msg.sender], "!whitelist");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    function setController(address _controller) external override onlyAdmin {
        require(_controller != address(0), "controller = zero address");
        controller = _controller;
    }

    function setTimeLock(address _timeLock) external override onlyTimeLock {
        require(_timeLock != address(0), "time lock = zero address");
        timeLock = _timeLock;
    }

    function setPause(bool _paused) external override onlyAdmin {
        paused = _paused;
    }

    function setWhitelist(address _addr, bool _approve) external override onlyAdmin {
        whitelist[_addr] = _approve;
        emit SetWhitelist(_addr, _approve);
    }

    function setReserveMin(uint _reserveMin) external override onlyAdmin {
        require(_reserveMin <= RESERVE_MAX, "reserve min > max");
        reserveMin = _reserveMin;
    }

    function setWithdrawFee(uint _fee) external override onlyAdmin {
        require(_fee <= WITHDRAW_FEE_CAP, "withdraw fee > cap");
        withdrawFee = _fee;
    }

    function _balanceInVault() private view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    /*
    @notice Returns balance of tokens in vault
    @return Amount of token in vault
    */
    function balanceInVault() external view override returns (uint) {
        return _balanceInVault();
    }

    function _balanceInStrategy() private view returns (uint) {
        if (strategy == address(0)) {
            return 0;
        }

        return IStrategy(strategy).totalAssets();
    }

    /*
    @notice Returns the estimate amount of token in strategy
    @dev Output may vary depending on price of liquidity provider token
         where the underlying token is invested
    */
    function balanceInStrategy() external view override returns (uint) {
        return _balanceInStrategy();
    }

    function _totalDebtInStrategy() private view returns (uint) {
        if (strategy == address(0)) {
            return 0;
        }
        return IStrategy(strategy).totalDebt();
    }

    /*
    @notice Returns amount of tokens invested strategy
    */
    function totalDebtInStrategy() external view override returns (uint) {
        return _totalDebtInStrategy();
    }

    function _totalAssets() private view returns (uint) {
        return _balanceInVault().add(_totalDebtInStrategy());
    }

    /*
    @notice Returns the total amount of tokens in vault + total debt
    @return Total amount of tokens in vault + total debt
    */
    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    function _minReserve() private view returns (uint) {
        return _totalAssets().mul(reserveMin) / RESERVE_MAX;
    }

    /*
    @notice Returns minimum amount of tokens that should be kept in vault for
            cheap withdraw
    @return Reserve amount
    */
    function minReserve() external view override returns (uint) {
        return _minReserve();
    }

    function _availableToInvest() private view returns (uint) {
        if (strategy == address(0)) {
            return 0;
        }

        uint balInVault = _balanceInVault();
        uint reserve = _minReserve();

        if (balInVault <= reserve) {
            return 0;
        }

        return balInVault - reserve;
    }

    /*
    @notice Returns amount of token available to be invested into strategy
    @return Amount of token available to be invested into strategy
    */
    function availableToInvest() external view override returns (uint) {
        return _availableToInvest();
    }

    /*
    @notice Approve strategy
    @param _strategy Address of strategy to revoke
    */
    function approveStrategy(address _strategy) external override onlyTimeLock {
        require(_strategy != address(0), "strategy = zero address");
        strategies[_strategy] = true;

        emit ApproveStrategy(_strategy);
    }

    /*
    @notice Revoke strategy
    @param _strategy Address of strategy to revoke
    */
    function revokeStrategy(address _strategy) external override onlyAdmin {
        require(_strategy != address(0), "strategy = zero address");
        strategies[_strategy] = false;

        emit RevokeStrategy(_strategy);
    }

    /*
    @notice Set strategy to approved strategy
    @param _strategy Address of strategy used
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    */
    function setStrategy(address _strategy, uint _min)
        external
        override
        onlyAdminOrController
    {
        require(strategies[_strategy], "!approved");
        require(_strategy != strategy, "new strategy = current strategy");
        require(
            IStrategy(_strategy).underlying() == token,
            "strategy.token != vault.token"
        );
        require(
            IStrategy(_strategy).vault() == address(this),
            "strategy.vault != vault"
        );

        // withdraw from current strategy
        if (strategy != address(0)) {
            IERC20(token).safeApprove(strategy, 0);

            uint balBefore = _balanceInVault();
            IStrategy(strategy).exit();
            uint balAfter = _balanceInVault();

            require(balAfter.sub(balBefore) >= _min, "withdraw < min");
        }

        strategy = _strategy;

        emit SetStrategy(strategy);
    }

    /*
    @notice Invest token from vault into strategy.
            Some token are kept in vault for cheap withdraw.
    */
    function invest()
        external
        override
        whenStrategyDefined
        whenNotPaused
        onlyAdminOrController
    {
        uint amount = _availableToInvest();
        require(amount > 0, "available = 0");

        IERC20(token).safeApprove(strategy, 0);
        IERC20(token).safeApprove(strategy, amount);

        IStrategy(strategy).deposit(amount);

        IERC20(token).safeApprove(strategy, 0);
    }

    /*
    @notice Deposit token into vault
    @param _amount Amount of token to transfer from `msg.sender`
    */
    function deposit(uint _amount) external override whenNotPaused nonReentrant guard {
        require(_amount > 0, "amount = 0");

        uint totalUnderlying = _totalAssets();
        uint totalShares = totalSupply();

        /*
        s = shares to mint
        T = total shares before mint
        d = deposit amount
        A = total assets in vault + strategy before deposit

        s / (T + s) = d / (A + d)
        s = d / A * T
        */
        uint shares;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = _amount.mul(totalShares).div(totalUnderlying);
        }

        _mint(msg.sender, shares);
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _getExpectedReturn(
        uint _shares,
        uint _balInVault,
        uint _balInStrat
    ) private view returns (uint) {
        /*
        s = shares
        T = total supply of shares
        w = amount of underlying token to withdraw
        U = total amount of redeemable underlying token in vault + strategy

        s / T = w / U
        w = s / T * U
        */

        /*
        total underlying = bal in vault + min(total debt, bal in strat)
        if bal in strat > total debt, redeemable = total debt
        else redeemable = bal in strat
        */
        uint totalDebt = _totalDebtInStrategy();
        uint totalUnderlying;
        if (_balInStrat > totalDebt) {
            totalUnderlying = _balInVault.add(totalDebt);
        } else {
            totalUnderlying = _balInVault.add(_balInStrat);
        }

        uint totalShares = totalSupply();
        if (totalShares > 0) {
            return _shares.mul(totalUnderlying) / totalShares;
        }
        return 0;
    }

    /*
    @notice Calculate amount of underlying token that can be withdrawn
    @param _shares Amount of shares
    @return Amount of underlying token that can be withdrawn
    */
    function getExpectedReturn(uint _shares) external view override returns (uint) {
        uint balInVault = _balanceInVault();
        uint balInStrat = _balanceInStrategy();

        return _getExpectedReturn(_shares, balInVault, balInStrat);
    }

    /*
    @notice Withdraw underlying token
    @param _shares Amount of shares to burn
    @param _min Minimum amount of underlying token to return
    @dev Keep `guard` modifier, else attacker can deposit and then use smart
         contract to attack from withdraw
    */
    function withdraw(uint _shares, uint _min) external override nonReentrant guard {
        require(_shares > 0, "shares = 0");

        uint balInVault = _balanceInVault();
        uint balInStrat = _balanceInStrategy();
        uint withdrawAmount = _getExpectedReturn(_shares, balInVault, balInStrat);

        // Must burn after calculating withdraw amount
        _burn(msg.sender, _shares);

        if (balInVault < withdrawAmount) {
            // maximize withdraw amount from strategy
            uint amountFromStrat = withdrawAmount;
            if (balInStrat < withdrawAmount) {
                amountFromStrat = balInStrat;
            }

            IStrategy(strategy).withdraw(amountFromStrat);

            uint balAfter = _balanceInVault();
            uint diff = balAfter.sub(balInVault);

            if (diff < amountFromStrat) {
                // withdraw amount - withdraw amount from strat = amount to withdraw from vault
                // diff = actual amount returned from strategy
                // NOTE: withdrawAmount >= amountFromStrat
                withdrawAmount = (withdrawAmount - amountFromStrat).add(diff);
            }

            // transfer to treasury
            uint fee = withdrawAmount.mul(withdrawFee) / FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                withdrawAmount = withdrawAmount - fee;
                IERC20(token).safeTransfer(treasury, fee);
            }
        }

        require(withdrawAmount >= _min, "withdraw < min");

        IERC20(token).safeTransfer(msg.sender, withdrawAmount);
    }

    /*
    @notice Transfer token != underlying token in vault to admin
    @param _token Address of token to transfer
    @dev Must transfer token to admin
    @dev _token must not be equal to underlying token
    @dev Used to transfer token that was accidentally sent to this vault
    */
    function sweep(address _token) external override onlyAdmin {
        require(_token != token, "token = vault.token");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../protocol/IController.sol";

/* solium-disable */
contract MockController is IController {
    bytes32 public constant override ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant override HARVESTER_ROLE =
        keccak256(abi.encodePacked("HARVESTER"));

    address public override admin;
    address public override treasury;

    constructor(address _treasury) public {
        admin = msg.sender;
        treasury = _treasury;
    }

    function setAdmin(address _admin) external override {}

    function setTreasury(address _treasury) external override {}

    function grantRole(bytes32 _role, address _addr) external override {}

    function revokeRole(bytes32 _role, address _addr) external override {}

    function invest(address _vault) external override {}

    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external override {}

    function harvest(address _strategy) external override {}

    function skim(address _strategy) external override {}

    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    ) external override {}

    function withdrawAll(address _strategy, uint _min) external override {}

    function exit(address _strategy, uint _min) external override {}

    /* test helper */
    function _setTreasury_(address _treasury) external {
        treasury = _treasury;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./protocol/IStrategy.sol";
import "./protocol/IController.sol";

abstract contract StrategyBase is IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public override admin;
    address public override controller;
    address public override vault;
    address public override underlying;

    // total amount of underlying transferred from vault
    uint public override totalDebt;

    // performance fee sent to treasury when harvest() generates profit
    uint public override performanceFee = 100;
    uint internal constant PERFORMANCE_FEE_MAX = 10000;

    // valuable tokens that cannot be swept
    mapping(address => bool) public override assets;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public {
        require(_controller != address(0), "controller = zero address");
        require(_vault != address(0), "vault = zero address");
        require(_underlying != address(0), "underlying = zero address");

        admin = msg.sender;
        controller = _controller;
        vault = _vault;
        underlying = _underlying;

        assets[underlying] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == admin || msg.sender == controller || msg.sender == vault,
            "!authorized"
        );
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    function setController(address _controller) external override onlyAdmin {
        require(_controller != address(0), "controller = zero address");
        controller = _controller;
    }

    function setPerformanceFee(uint _fee) external override onlyAdmin {
        require(_fee <= PERFORMANCE_FEE_MAX, "performance fee > max");
        performanceFee = _fee;
    }

    function _increaseDebt(uint _underlyingAmount) private {
        uint balBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransferFrom(vault, address(this), _underlyingAmount);
        uint balAfter = IERC20(underlying).balanceOf(address(this));

        totalDebt = totalDebt.add(balAfter.sub(balBefore));
    }

    function _decreaseDebt(uint _underlyingAmount) private {
        uint balBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, _underlyingAmount);
        uint balAfter = IERC20(underlying).balanceOf(address(this));

        uint diff = balBefore.sub(balAfter);
        if (diff > totalDebt) {
            totalDebt = 0;
        } else {
            totalDebt = totalDebt - diff;
        }
    }

    function _totalAssets() internal view virtual returns (uint);

    /*
    @notice Returns amount of underlying tokens locked in this contract
    */
    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    function _depositUnderlying() internal virtual;

    /*
    @notice Deposit underlying token into this strategy
    @param _underlyingAmount Amount of underlying token to deposit
    */
    function deposit(uint _underlyingAmount) external override onlyAuthorized {
        require(_underlyingAmount > 0, "underlying = 0");

        _increaseDebt(_underlyingAmount);
        _depositUnderlying();
    }

    /*
    @notice Returns total shares owned by this contract for depositing underlying
            into external Defi
    */
    function _getTotalShares() internal view virtual returns (uint);

    function _getShares(uint _underlyingAmount, uint _totalUnderlying)
        internal
        view
        returns (uint)
    {
        /*
        calculate shares to withdraw

        w = amount of underlying to withdraw
        U = total redeemable underlying
        s = shares to withdraw
        P = total shares deposited into external liquidity pool

        w / U = s / P
        s = w / U * P
        */
        if (_totalUnderlying > 0) {
            uint totalShares = _getTotalShares();
            return _underlyingAmount.mul(totalShares) / _totalUnderlying;
        }
        return 0;
    }

    function _withdrawUnderlying(uint _shares) internal virtual;

    /*
    @notice Withdraw undelying token to vault
    @param _underlyingAmount Amount of underlying token to withdraw
    @dev Caller should implement guard agains slippage
    */
    function withdraw(uint _underlyingAmount) external override onlyAuthorized {
        require(_underlyingAmount > 0, "underlying = 0");
        uint totalUnderlying = _totalAssets();
        require(_underlyingAmount <= totalUnderlying, "underlying > total");

        uint shares = _getShares(_underlyingAmount, totalUnderlying);
        if (shares > 0) {
            _withdrawUnderlying(shares);
        }

        // transfer underlying token to vault
        uint underlyingBal = IERC20(underlying).balanceOf(address(this));
        if (underlyingBal > 0) {
            _decreaseDebt(underlyingBal);
        }
    }

    function _withdrawAll() internal {
        uint totalShares = _getTotalShares();
        if (totalShares > 0) {
            _withdrawUnderlying(totalShares);
        }

        uint underlyingBal = IERC20(underlying).balanceOf(address(this));
        if (underlyingBal > 0) {
            _decreaseDebt(underlyingBal);
            totalDebt = 0;
        }
    }

    /*
    @notice Withdraw all underlying to vault
    @dev Caller should implement guard agains slippage
    */
    function withdrawAll() external override onlyAuthorized {
        _withdrawAll();
    }

    /*
    @notice Sell any staking rewards for underlying, deposit or transfer undelying
            depending on total debt
    */
    function harvest() external virtual override;

    /*
    @notice Transfer profit over total debt to vault
    */
    function skim() external override onlyAuthorized {
        uint totalUnderlying = _totalAssets();

        if (totalUnderlying > totalDebt) {
            uint profit = totalUnderlying - totalDebt;
            uint shares = _getShares(profit, totalUnderlying);
            if (shares > 0) {
                uint balBefore = IERC20(underlying).balanceOf(address(this));
                _withdrawUnderlying(shares);
                uint balAfter = IERC20(underlying).balanceOf(address(this));

                uint diff = balAfter.sub(balBefore);
                if (diff > 0) {
                    IERC20(underlying).safeTransfer(vault, diff);
                }
            }
        }
    }

    function exit() external virtual override;

    function sweep(address _token) external override onlyAdmin {
        require(!assets[_token], "asset");

        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../StrategyBase.sol";
import "./TestToken.sol";

/* solium-disable */
contract StrategyTest is StrategyBase {
    // test helper
    uint public _depositAmount_;
    uint public _withdrawAmount_;
    bool public _harvestWasCalled_;
    bool public _exitWasCalled_;
    // simulate strategy withdrawing less than requested
    uint public _maxWithdrawAmount_ = uint(-1);
    // mock liquidity provider
    address public constant _POOL_ = address(1);

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyBase(_controller, _vault, _underlying) {
        // allow this contract to freely withdraw from POOL
        TestToken(underlying)._approve_(_POOL_, address(this), uint(-1));
    }

    function _totalAssets() internal view override returns (uint) {
        return IERC20(underlying).balanceOf(_POOL_);
    }

    function _depositUnderlying() internal override {
        uint bal = IERC20(underlying).balanceOf(address(this));
        _depositAmount_ = bal;
        IERC20(underlying).transfer(_POOL_, bal);
    }

    function _getTotalShares() internal view override returns (uint) {
        return IERC20(underlying).balanceOf(_POOL_);
    }

    function _withdrawUnderlying(uint _shares) internal override {
        _withdrawAmount_ = _shares;

        if (_shares > _maxWithdrawAmount_) {
            _withdrawAmount_ = _maxWithdrawAmount_;
        }
        IERC20(underlying).transferFrom(_POOL_, address(this), _withdrawAmount_);
    }

    function harvest() external override onlyAuthorized {
        _harvestWasCalled_ = true;
    }

    function exit() external override onlyAuthorized {
        _exitWasCalled_ = true;
        _withdrawAll();
    }

    // test helpers
    function _setVault_(address _vault) external {
        vault = _vault;
    }

    function _setUnderlying_(address _token) external {
        underlying = _token;
    }

    function _setAsset_(address _token) external {
        assets[_token] = true;
    }

    function _mintToPool_(uint _amount) external {
        TestToken(underlying)._mint_(_POOL_, _amount);
    }

    function _setTotalDebt_(uint _debt) external {
        totalDebt = _debt;
    }

    function _setMaxWithdrawAmount_(uint _max) external {
        _maxWithdrawAmount_ = _max;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* solium-disable */
contract TestToken is ERC20 {
    constructor() public ERC20("test", "TEST") {
        _setupDecimals(18);
    }

    /* test helper */
    function _mint_(address _to, uint _amount) external {
        _mint(_to, _amount);
    }

    function _burn_(address _from, uint _amount) external {
        _burn(_from, _amount);
    }

    function _approve_(
        address _from,
        address _to,
        uint _amount
    ) external {
        _approve(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../protocol/IStrategy.sol";

/*
This is a "placeholder" strategy used during emergency shutdown
*/
contract StrategyNoOp is IStrategy {
    using SafeERC20 for IERC20;

    address public override admin;
    address public override controller;
    address public override vault;
    address public override underlying;

    uint public override totalDebt;
    uint public override performanceFee;

    mapping(address => bool) public override assets;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public {
        require(_controller != address(0), "controller = zero address");
        require(_vault != address(0), "vault = zero address");
        require(_underlying != address(0), "underlying = zero address");

        admin = msg.sender;
        controller = _controller;
        vault = _vault;
        underlying = _underlying;

        assets[underlying] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    // @dev variable name is removed to silence compiler warning
    function setController(address) external override {
        revert("no-op");
    }

    // @dev variable name is removed to silence compiler warning
    function setPerformanceFee(uint) external override {
        revert("no-op");
    }

    function totalAssets() external view override returns (uint) {
        return 0;
    }

    // @dev variable name is removed to silence compiler warning
    function deposit(uint) external override {
        revert("no-op");
    }

    // @dev variable name is removed to silence compiler warning
    function withdraw(uint) external override {
        revert("no-op");
    }

    function withdrawAll() external override {
        revert("no-op");
    }

    function harvest() external override {
        revert("no-op");
    }

    function skim() external override {
        revert("no-op");
    }

    function exit() external override {
        // left as blank so that Vault can call exit() during Vault.setStrategy()
    }

    function sweep(address _token) external override onlyAdmin {
        require(!assets[_token], "asset");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/uniswap/Uniswap.sol";

contract UseUniswap {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    // Uniswap //
    address private constant UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _swap(
        address _from,
        address _to,
        uint _amount
    ) internal {
        require(_to != address(0), "to = zero address");

        // Swap with uniswap
        IERC20(_from).safeApprove(UNISWAP, 0);
        IERC20(_from).safeApprove(UNISWAP, _amount);

        address[] memory path;

        if (_from == WETH || _to == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }

        Uniswap(UNISWAP).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface Uniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/pickle/PickleJar.sol";
import "../interfaces/pickle/MasterChef.sol";
import "../interfaces/pickle/PickleStaking.sol";
import "../StrategyBase.sol";
import "../UseUniswap.sol";

contract StrategyPdaiDai is StrategyBase, UseUniswap {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // Pickle //
    address private constant JAR = 0x6949Bb624E8e8A90F87cD2058139fcd77D2F3F87;
    address private constant CHEF = 0xbD17B1ce622d73bD438b9E658acA5996dc394b0d;
    address private constant PICKLE = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;
    address private constant STAKING = 0xa17a8883dA1aBd57c690DF9Ebf58fC194eDAb66F;

    // percentage of Pickle to sell, rest is staked
    uint public pickleSell = 5000;
    uint private constant PICKLE_SELL_MAX = 10000;

    // POOL ID for PDAI JAR
    uint private constant POOL_ID = 16;

    constructor(address _controller, address _vault)
        public
        StrategyBase(_controller, _vault, DAI)
    {
        // Assets that cannot be swept by admin
        assets[PICKLE] = true;
    }

    function setPickleSell(uint _sell) external onlyAdmin {
        require(_sell <= PICKLE_SELL_MAX, "sell > max");
        pickleSell = _sell;
    }

    // TODO security: vulnerable to price manipulation?
    function _totalAssets() internal view override returns (uint) {
        // getRatio() is multiplied by 10 ** 18
        uint pricePerShare = PickleJar(JAR).getRatio();
        (uint shares, ) = MasterChef(CHEF).userInfo(POOL_ID, address(this));

        return shares.mul(pricePerShare).div(1e18);
    }

    function _depositUnderlying() internal override {
        // deposit DAI into PICKLE
        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            IERC20(underlying).safeApprove(JAR, 0);
            IERC20(underlying).safeApprove(JAR, bal);
            PickleJar(JAR).deposit(bal);
        }

        // stake pDai
        uint pDaiBal = IERC20(JAR).balanceOf(address(this));
        if (pDaiBal > 0) {
            IERC20(JAR).safeApprove(CHEF, 0);
            IERC20(JAR).safeApprove(CHEF, pDaiBal);
            MasterChef(CHEF).deposit(POOL_ID, pDaiBal);
        }

        // stake PICKLE
        uint pickleBal = IERC20(PICKLE).balanceOf(address(this));
        if (pickleBal > 0) {
            IERC20(PICKLE).safeApprove(STAKING, 0);
            IERC20(PICKLE).safeApprove(STAKING, pickleBal);
            PickleStaking(STAKING).stake(pickleBal);
        }
    }

    function _getTotalShares() internal view override returns (uint) {
        (uint pDaiBal, ) = MasterChef(CHEF).userInfo(POOL_ID, address(this));
        return pDaiBal;
    }

    function _withdrawUnderlying(uint _pDaiAmount) internal override {
        // unstake
        MasterChef(CHEF).withdraw(POOL_ID, _pDaiAmount);

        // withdraw DAI from  PICKLE
        PickleJar(JAR).withdraw(_pDaiAmount);
        // Now we have underlying
    }

    function _swapWeth() private {
        uint wethBal = IERC20(WETH).balanceOf(address(this));
        if (wethBal > 0) {
            _swap(WETH, underlying, wethBal);
            // Now this contract has underlying token
        }
    }

    /*
    @notice Sell PICKLE and deposit most premium token into CURVE
    */
    function harvest() external override onlyAuthorized {
        // claim Pickle
        MasterChef(CHEF).deposit(POOL_ID, 0);

        // unsold amount will be staked in _depositUnderlying()
        uint pickleBal = IERC20(PICKLE).balanceOf(address(this));
        uint pickleAmount = pickleBal.mul(pickleSell).div(PICKLE_SELL_MAX);
        if (pickleAmount > 0) {
            _swap(PICKLE, underlying, pickleAmount);
            // Now this contract has underlying token
        }
        // get staking rewards WETH
        PickleStaking(STAKING).getReward();
        _swapWeth();

        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee).div(PERFORMANCE_FEE_MAX);
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                IERC20(underlying).safeTransfer(treasury, fee);
            }

            _depositUnderlying();
        }
    }

    /*
    @dev Caller should implement guard agains slippage
    */
    function exit() external override onlyAuthorized {
        /*
        PICKLE is minted on deposit / withdraw so here we
        0. Unstake PICKLE and claim WETH rewards
        1. Sell WETH
        2. Withdraw from MasterChef
        3. Sell PICKLE
        4. Transfer underlying to vault
        */
        uint staked = PickleStaking(STAKING).balanceOf(address(this));
        if (staked > 0) {
            PickleStaking(STAKING).exit();
            _swapWeth();
        }
        _withdrawAll();

        uint pickleBal = IERC20(PICKLE).balanceOf(address(this));
        if (pickleBal > 0) {
            _swap(PICKLE, underlying, pickleBal);
            // Now this contract has underlying token
        }

        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            IERC20(underlying).safeTransfer(vault, bal);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface PickleJar {
    /*
    @notice returns price of token / share
    @dev ratio is multiplied by 10 ** 18
    */
    function getRatio() external view returns (uint);

    function deposit(uint _amount) external;

    function withdraw(uint _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface MasterChef {
    function userInfo(uint _pid, address _user)
        external
        view
        returns (uint _amount, uint _rewardDebt);

    function deposit(uint _pid, uint _amount) external;

    function withdraw(uint _pid, uint _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface PickleStaking {
    function balanceOf(address account) external view returns (uint);

    function earned(address account) external view returns (uint);

    function stake(uint amount) external;

    function withdraw(uint amount) external;

    function getReward() external;

    function exit() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/StableSwap3.sol";
import "../interfaces/pickle/PickleJar.sol";
import "../interfaces/pickle/MasterChef.sol";

import "../StrategyBase.sol";
import "../UseUniswap.sol";

contract StrategyP3Crv is StrategyBase, UseUniswap {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // DAI = 0 | USDC = 1 | USDT = 2
    uint internal underlyingIndex;
    // precision to convert 10 ** 18  to underlying decimals
    uint internal precisionDiv = 1;

    // Curve //
    // 3Crv
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    // StableSwap3
    address private constant CURVE = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    // Pickle //
    address private constant JAR = 0x1BB74b5DdC1f4fC91D6f9E7906cf68bc93538e33;
    address private constant CHEF = 0xbD17B1ce622d73bD438b9E658acA5996dc394b0d;
    address private constant PICKLE = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;

    // POOL ID for 3Crv JAR
    uint private constant POOL_ID = 14;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyBase(_controller, _vault, _underlying) {
        // Assets that cannot be swept by admin
        assets[PICKLE] = true;
    }

    // TODO security: vulnerable to price manipulation
    function _totalAssets() internal view override returns (uint) {
        // getRatio() is multiplied by 10 ** 18
        uint pricePerShare = PickleJar(JAR).getRatio();
        (uint shares, ) = MasterChef(CHEF).userInfo(POOL_ID, address(this));

        return shares.mul(pricePerShare).div(precisionDiv) / 1e18;
    }

    function _deposit(address _token, uint _index) private {
        // token to THREE_CRV
        uint bal = IERC20(_token).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_token).safeApprove(CURVE, 0);
            IERC20(_token).safeApprove(CURVE, bal);
            // mint THREE_CRV
            uint[3] memory amounts;
            amounts[_index] = bal;
            StableSwap3(CURVE).add_liquidity(amounts, 0);
            // Now we have 3Crv
        }

        // deposit 3Crv into PICKLE
        uint threeBal = IERC20(THREE_CRV).balanceOf(address(this));
        if (threeBal > 0) {
            IERC20(THREE_CRV).safeApprove(JAR, 0);
            IERC20(THREE_CRV).safeApprove(JAR, threeBal);
            PickleJar(JAR).deposit(threeBal);
        }

        // stake p3crv
        uint p3crvBal = IERC20(JAR).balanceOf(address(this));
        if (p3crvBal > 0) {
            IERC20(JAR).safeApprove(CHEF, 0);
            IERC20(JAR).safeApprove(CHEF, p3crvBal);
            MasterChef(CHEF).deposit(POOL_ID, p3crvBal);
        }
        // TODO stake
    }

    function _depositUnderlying() internal override {
        _deposit(underlying, underlyingIndex);
    }

    function _getTotalShares() internal view override returns (uint) {
        (uint p3CrvBal, ) = MasterChef(CHEF).userInfo(POOL_ID, address(this));
        return p3CrvBal;
    }

    function _withdrawUnderlying(uint _p3CrvAmount) internal override {
        // unstake
        MasterChef(CHEF).withdraw(POOL_ID, _p3CrvAmount);

        // withdraw THREE_CRV from  PICKLE
        PickleJar(JAR).withdraw(_p3CrvAmount);

        // withdraw underlying
        uint threeBal = IERC20(THREE_CRV).balanceOf(address(this));
        // creates THREE_CRV dust
        StableSwap3(CURVE).remove_liquidity_one_coin(
            threeBal,
            int128(underlyingIndex),
            0
        );
        // Now we have underlying
    }

    /*
    @notice Returns address and index of token with lowest balance in CURVE pool
    */
    function _getMostPremiumToken() private view returns (address, uint) {
        uint[] memory balances = new uint[](3);
        balances[0] = StableSwap3(CURVE).balances(0); // DAI
        balances[1] = StableSwap3(CURVE).balances(1).mul(1e12); // USDC
        balances[2] = StableSwap3(CURVE).balances(2).mul(1e12); // USDT

        // DAI
        if (balances[0] <= balances[1] && balances[0] <= balances[2]) {
            return (DAI, 0);
        }

        // USDC
        if (balances[1] <= balances[0] && balances[1] <= balances[2]) {
            return (USDC, 1);
        }

        // USDT
        return (USDT, 2);
    }

    function _swapPickleFor(address _token) private {
        uint pickleBal = IERC20(PICKLE).balanceOf(address(this));
        if (pickleBal > 0) {
            _swap(PICKLE, _token, pickleBal);
            // Now this contract has underlying token
        }
    }

    /*
    @notice Sell PICKLE and deposit most premium token into CURVE
    */
    function harvest() external override onlyAuthorized {
        // TODO: claim Pickle
        // MasterChef(CHER).deposit(POOL_ID, 0);

        (address token, uint index) = _getMostPremiumToken();

        _swapPickleFor(token);

        uint bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee) / PERFORMANCE_FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                IERC20(token).safeTransfer(treasury, fee);
            }

            _deposit(token, index);
        }
    }

    /*
    @dev Caller should implement guard agains slippage
    */
    function exit() external override onlyAuthorized {
        // PICKLE is minted on withdraw so here we
        // 1. Withdraw from MasterChef
        // 2. Sell PICKLE
        // 3. Transfer underlying to vault
        _withdrawAll();
        _swapPickleFor(underlying);

        uint underlyingBal = IERC20(underlying).balanceOf(address(this));
        if (underlyingBal > 0) {
            IERC20(underlying).safeTransfer(vault, underlyingBal);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwap3 {
    /*
    @dev Returns price of 1 Curve LP token in USD
    */
    function get_virtual_price() external view returns (uint);

    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint token_amount,
        int128 i,
        uint min_uamount
    ) external;

    function balances(uint index) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyP3Crv.sol";

contract StrategyP3CrvUsdt is StrategyP3Crv {
    constructor(address _controller, address _vault)
        public
        StrategyP3Crv(_controller, _vault, USDT)
    {
        // usdt
        underlyingIndex = 2;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyP3Crv.sol";

contract StrategyP3CrvUsdc is StrategyP3Crv {
    constructor(address _controller, address _vault)
        public
        StrategyP3Crv(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 1;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyP3Crv.sol";

contract StrategyP3CrvDai is StrategyP3Crv {
    constructor(address _controller, address _vault)
        public
        StrategyP3Crv(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 0;
        precisionDiv = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/StableSwapGusd.sol";
import "../interfaces/curve/DepositGusd.sol";
import "../interfaces/curve/StableSwap3.sol";
import "./StrategyCurve.sol";

contract StrategyGusd is StrategyCurve {
    // 3Pool StableSwap
    address private constant BASE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // GUSD StableSwap
    address private constant SWAP = 0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956;
    address private constant GUSD = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // GUSD / 3CRV
        lp = 0xD2967f45c4f384DEEa880F807Be904762a3DeA07;
        // DepositGusd
        pool = 0x64448B78561690B70E17CBE8029a3e5c1bB7136e;
        // Gauge
        gauge = 0xC5cfaDA84E902aD92DD40194f0883ad49639b023;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwapGusd(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[4] memory amounts;
        amounts[_index] = _amount;
        DepositGusd(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        DepositGusd(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[4] memory balances;
        balances[0] = StableSwapGusd(SWAP).balances(0).mul(1e16); // GUSD
        balances[1] = StableSwap3(BASE_POOL).balances(0); // DAI
        balances[2] = StableSwap3(BASE_POOL).balances(1).mul(1e12); // USDC
        balances[3] = StableSwap3(BASE_POOL).balances(2).mul(1e12); // USDT

        uint minIndex = 0;
        for (uint i = 1; i < balances.length; i++) {
            if (balances[i] <= balances[minIndex]) {
                minIndex = i;
            }
        }

        if (minIndex == 0) {
            return (GUSD, 0);
        }
        if (minIndex == 1) {
            return (DAI, 1);
        }
        if (minIndex == 2) {
            return (USDC, 2);
        }
        return (USDT, 3);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwapGusd {
    function get_virtual_price() external view returns (uint);

    /*
    0 GUSD
    1 3CRV
    */
    function balances(uint index) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface DepositGusd {
    /*
    0 GUSD
    1 DAI
    2 USDC
    3 USDT
    */
    function add_liquidity(uint[4] memory amounts, uint min) external returns (uint);

    function remove_liquidity_one_coin(
        uint amount,
        int128 index,
        uint min
    ) external returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/Gauge.sol";
import "../interfaces/curve/Minter.sol";
import "../StrategyBase.sol";
import "../UseUniswap.sol";

/* potential hacks?
- front running?
- slippage when withdrawing all from strategy
*/

abstract contract StrategyCurve is StrategyBase, UseUniswap {
    // DAI = 0 | USDC = 1 | USDT = 2
    uint internal underlyingIndex;
    // precision to convert 10 ** 18  to underlying decimals
    uint internal precisionDiv = 1;

    // Curve //
    // liquidity provider token (cDAI/cUSDC or 3Crv)
    address internal lp;
    // ICurveFi2 or ICurveFi3
    address internal pool;
    // Gauge
    address internal gauge;
    // Minter
    address internal minter;
    // DAO
    address internal crv;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyBase(_controller, _vault, _underlying) {}

    function _getVirtualPrice() internal view virtual returns (uint);

    function _totalAssets() internal view override returns (uint) {
        uint lpBal = Gauge(gauge).balanceOf(address(this));
        uint pricePerShare = _getVirtualPrice();

        return lpBal.mul(pricePerShare).div(precisionDiv) / 1e18;
    }

    function _addLiquidity(uint _amount, uint _index) internal virtual;

    /*
    @notice deposit token into curve
    */
    function _deposit(address _token, uint _index) private {
        // token to lp
        uint bal = IERC20(_token).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_token).safeApprove(pool, 0);
            IERC20(_token).safeApprove(pool, bal);
            // mint lp
            _addLiquidity(bal, _index);
        }

        // stake into Gauge
        uint lpBal = IERC20(lp).balanceOf(address(this));
        if (lpBal > 0) {
            IERC20(lp).safeApprove(gauge, 0);
            IERC20(lp).safeApprove(gauge, lpBal);
            Gauge(gauge).deposit(lpBal);
        }
    }

    /*
    @notice Deposits underlying to Gauge
    */
    function _depositUnderlying() internal override {
        _deposit(underlying, underlyingIndex);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal virtual;

    function _getTotalShares() internal view override returns (uint) {
        return Gauge(gauge).balanceOf(address(this));
    }

    function _withdrawUnderlying(uint _lpAmount) internal override {
        // withdraw lp from  Gauge
        Gauge(gauge).withdraw(_lpAmount);
        // withdraw underlying
        uint lpBal = IERC20(lp).balanceOf(address(this));
        // creates lp dust
        _removeLiquidityOneCoin(lpBal);
        // Now we have underlying
    }

    /*
    @notice Returns address and index of token with lowest balance in Curve pool
    */
    function _getMostPremiumToken() internal view virtual returns (address, uint);

    function _swapCrvFor(address _token) private {
        Minter(minter).mint(gauge);

        uint crvBal = IERC20(crv).balanceOf(address(this));
        if (crvBal > 0) {
            _swap(crv, _token, crvBal);
            // Now this contract has token
        }
    }

    /*
    @notice Claim CRV and deposit most premium token into Curve
    */
    function harvest() external override onlyAuthorized {
        (address token, uint index) = _getMostPremiumToken();

        _swapCrvFor(token);

        uint bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee) / PERFORMANCE_FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                IERC20(token).safeTransfer(treasury, fee);
            }

            _deposit(token, index);
        }
    }

    /*
    @notice Exit strategy by harvesting CRV to underlying token and then
            withdrawing all underlying to vault
    @dev Must return all underlying token to vault
    @dev Caller should implement guard agains slippage
    */
    function exit() external override onlyAuthorized {
        _swapCrvFor(underlying);
        _withdrawAll();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

// https://github.com/curvefi/curve-contract/blob/master/contracts/gauges/LiquidityGauge.vy
interface Gauge {
    function deposit(uint) external;

    function balanceOf(address) external view returns (uint);

    function withdraw(uint) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/Minter.vy
interface Minter {
    function mint(address) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyGusd.sol";

contract StrategyGusdUsdt is StrategyGusd {
    constructor(address _controller, address _vault)
        public
        StrategyGusd(_controller, _vault, USDT)
    {
        // usdt
        underlyingIndex = 3;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyGusd.sol";

contract StrategyGusdUsdc is StrategyGusd {
    constructor(address _controller, address _vault)
        public
        StrategyGusd(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 2;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyGusd.sol";

contract StrategyGusdDai is StrategyGusd {
    constructor(address _controller, address _vault)
        public
        StrategyGusd(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 1;
        precisionDiv = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/StableSwapPax.sol";
import "../interfaces/curve/DepositPax.sol";
import "./StrategyCurve.sol";

contract StrategyPax is StrategyCurve {
    // PAX StableSwap
    address private constant SWAP = 0x06364f10B501e868329afBc005b3492902d6C763;
    address private constant PAX = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // DAI/USDC/USDT/PAX
        lp = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;
        // DepositPax
        pool = 0xA50cCc70b6a011CffDdf45057E39679379187287;
        // Gauge
        gauge = 0x64E3C23bfc40722d3B649844055F1D51c1ac041d;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwapPax(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[4] memory amounts;
        amounts[_index] = _amount;
        DepositPax(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        DepositPax(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0,
            false
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[4] memory balances;
        balances[0] = StableSwapPax(SWAP).balances(0); // DAI
        balances[1] = StableSwapPax(SWAP).balances(1).mul(1e12); // USDC
        balances[2] = StableSwapPax(SWAP).balances(2).mul(1e12); // USDT
        balances[3] = StableSwapPax(SWAP).balances(3); // PAX

        uint minIndex = 0;
        for (uint i = 1; i < balances.length; i++) {
            if (balances[i] <= balances[minIndex]) {
                minIndex = i;
            }
        }

        if (minIndex == 0) {
            return (DAI, 0);
        }
        if (minIndex == 1) {
            return (USDC, 1);
        }
        if (minIndex == 2) {
            return (USDT, 2);
        }
        return (PAX, 3);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwapPax {
    function get_virtual_price() external view returns (uint);

    /*
    0 DAI
    1 USDC
    2 USDT
    3 PAX
    */
    function balances(int128 index) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface DepositPax {
    /*
    0 DAI
    1 USDC
    2 USDT
    3 PAX
    */
    function add_liquidity(uint[4] memory amounts, uint min) external;

    function remove_liquidity_one_coin(
        uint amount,
        int128 index,
        uint min,
        bool donateDust
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyPax.sol";

contract StrategyPaxUsdt is StrategyPax {
    constructor(address _controller, address _vault)
        public
        StrategyPax(_controller, _vault, USDT)
    {
        // usdt
        underlyingIndex = 2;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyPax.sol";

contract StrategyPaxUsdc is StrategyPax {
    constructor(address _controller, address _vault)
        public
        StrategyPax(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 1;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyPax.sol";

contract StrategyPaxDai is StrategyPax {
    constructor(address _controller, address _vault)
        public
        StrategyPax(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 0;
        precisionDiv = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/StableSwap2.sol";
import "../interfaces/curve/Deposit2.sol";
import "./StrategyCurve.sol";

contract StrategyCusd is StrategyCurve {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address private constant SWAP = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // cDAI/cUSDC
        lp = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
        // DepositCompound
        pool = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
        // Gauge
        gauge = 0x7ca5b0a2910B33e9759DC7dDB0413949071D7575;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    /*
    @dev Returns USD price of 1 Curve Compound LP token
    */
    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwap2(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[2] memory amounts;
        amounts[_index] = _amount;
        Deposit2(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        Deposit2(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0,
            true
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[] memory balances = new uint[](2);
        balances[0] = StableSwap2(SWAP).balances(0); // DAI
        balances[1] = StableSwap2(SWAP).balances(1).mul(1e12); // USDC

        // DAI
        if (balances[0] < balances[1]) {
            return (DAI, 0);
        }

        return (USDC, 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwap2 {
    /*
    @dev Returns price of 1 Curve LP token in USD
    */
    function get_virtual_price() external view returns (uint);

    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint token_amount,
        int128 i,
        uint min_uamount,
        bool donate_dust
    ) external;

    function balances(int128 index) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface Deposit2 {
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint token_amount,
        int128 i,
        uint min_uamount,
        bool donate_dust
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyCusd.sol";

contract StrategyCusdUsdc is StrategyCusd {
    constructor(address _controller, address _vault)
        public
        StrategyCusd(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 1;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyCusd.sol";

contract StrategyCusdDai is StrategyCusd {
    constructor(address _controller, address _vault)
        public
        StrategyCusd(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 0;
        precisionDiv = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/StableSwapBusd.sol";
import "../interfaces/curve/DepositBusd.sol";
import "./StrategyCurve.sol";

contract StrategyBusd is StrategyCurve {
    // BUSD StableSwap
    address private constant SWAP = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // yDAI/yUSDC/yUSDT/yBUSD
        lp = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
        // DepositBusd
        pool = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
        // Gauge
        gauge = 0x69Fb7c45726cfE2baDeE8317005d3F94bE838840;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwapBusd(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[4] memory amounts;
        amounts[_index] = _amount;
        DepositBusd(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        DepositBusd(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0,
            false
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[4] memory balances;
        balances[0] = StableSwapBusd(SWAP).balances(0); // DAI
        balances[1] = StableSwapBusd(SWAP).balances(1).mul(1e12); // USDC
        balances[2] = StableSwapBusd(SWAP).balances(2).mul(1e12); // USDT
        balances[3] = StableSwapBusd(SWAP).balances(3); // BUSD

        uint minIndex = 0;
        for (uint i = 1; i < balances.length; i++) {
            if (balances[i] <= balances[minIndex]) {
                minIndex = i;
            }
        }

        if (minIndex == 0) {
            return (DAI, 0);
        }
        if (minIndex == 1) {
            return (USDC, 1);
        }
        if (minIndex == 2) {
            return (USDT, 2);
        }
        return (BUSD, 3);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwapBusd {
    function get_virtual_price() external view returns (uint);

    /*
    0 DAI
    1 USDC
    2 USDT
    3 BUSD
    */
    function balances(int128 index) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface DepositBusd {
    /*
    0 DAI
    1 USDC
    2 USDT
    3 BUSD
    */
    function add_liquidity(uint[4] memory amounts, uint min) external;

    function remove_liquidity_one_coin(
        uint amount,
        int128 index,
        uint min,
        bool donateDust
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyBusd.sol";

contract StrategyBusdUsdt is StrategyBusd {
    constructor(address _controller, address _vault)
        public
        StrategyBusd(_controller, _vault, USDT)
    {
        // usdt
        underlyingIndex = 2;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyBusd.sol";

contract StrategyBusdUsdc is StrategyBusd {
    constructor(address _controller, address _vault)
        public
        StrategyBusd(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 1;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyBusd.sol";

contract StrategyBusdDai is StrategyBusd {
    constructor(address _controller, address _vault)
        public
        StrategyBusd(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 0;
        precisionDiv = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../interfaces/curve/StableSwap3.sol";
import "./StrategyCurve.sol";

contract Strategy3Crv is StrategyCurve {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // 3Crv
        lp = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
        // 3 Pool
        pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        // Gauge
        gauge = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwap3(pool).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[3] memory amounts;
        amounts[_index] = _amount;
        StableSwap3(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        StableSwap3(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[] memory balances = new uint[](3);
        balances[0] = StableSwap3(pool).balances(0); // DAI
        balances[1] = StableSwap3(pool).balances(1).mul(1e12); // USDC
        balances[2] = StableSwap3(pool).balances(2).mul(1e12); // USDT

        // DAI
        if (balances[0] <= balances[1] && balances[0] <= balances[2]) {
            return (DAI, 0);
        }

        // USDC
        if (balances[1] <= balances[0] && balances[1] <= balances[2]) {
            return (USDC, 1);
        }

        return (USDT, 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./Strategy3Crv.sol";

contract Strategy3CrvUsdt is Strategy3Crv {
    constructor(address _controller, address _vault)
        public
        Strategy3Crv(_controller, _vault, USDT)
    {
        // usdt
        underlyingIndex = 2;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./Strategy3Crv.sol";

contract Strategy3CrvUsdc is Strategy3Crv {
    constructor(address _controller, address _vault)
        public
        Strategy3Crv(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 1;
        precisionDiv = 1e12;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./Strategy3Crv.sol";

contract Strategy3CrvDai is Strategy3Crv {
    constructor(address _controller, address _vault)
        public
        Strategy3Crv(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 0;
        precisionDiv = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./protocol/ITimeLock.sol";

contract TimeLock is ITimeLock {
    using SafeMath for uint;

    event NewAdmin(address admin);
    event NewDelay(uint delay);
    event Queue(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta
    );
    event Execute(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta
    );
    event Cancel(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta
    );

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MIN_DELAY = 1 days;
    uint public constant MAX_DELAY = 30 days;

    address public override admin;
    uint public override delay;

    mapping(bytes32 => bool) public override queued;

    constructor(uint _delay) public {
        admin = msg.sender;
        _setDelay(_delay);
    }

    receive() external payable override {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
        emit NewAdmin(_admin);
    }

    function _setDelay(uint _delay) private {
        require(_delay >= MIN_DELAY, "delay < min");
        require(_delay <= MAX_DELAY, "delay > max");
        delay = _delay;

        emit NewDelay(delay);
    }

    /*
    @dev Only this contract can execute this function
    */
    function setDelay(uint _delay) external override {
        require(msg.sender == address(this), "!timelock");

        _setDelay(_delay);
    }

    function _getTxHash(
        address target,
        uint value,
        bytes memory data,
        uint eta
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(target, value, data, eta));
    }

    function getTxHash(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external pure override returns (bytes32) {
        return _getTxHash(target, value, data, eta);
    }

    /*
    @notice Queue transaction
    @param target Address of contract or account to call
    @param value Ether value to send
    @param data Data to send to `target`
    @eta Execute Tx After. Time after which transaction can be executed.
    */
    function queue(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external override onlyAdmin returns (bytes32) {
        require(eta >= block.timestamp.add(delay), "eta < now + delay");

        bytes32 txHash = _getTxHash(target, value, data, eta);
        queued[txHash] = true;

        emit Queue(txHash, target, value, data, eta);

        return txHash;
    }

    function execute(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external payable override onlyAdmin returns (bytes memory) {
        bytes32 txHash = _getTxHash(target, value, data, eta);
        require(queued[txHash], "!queued");
        require(block.timestamp >= eta, "eta < now");
        require(block.timestamp <= eta.add(GRACE_PERIOD), "eta expired");

        queued[txHash] = false;

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        require(success, "tx failed");

        emit Execute(txHash, target, value, data, eta);

        return returnData;
    }

    function cancel(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external override onlyAdmin {
        bytes32 txHash = _getTxHash(target, value, data, eta);
        require(queued[txHash], "!queued");

        queued[txHash] = false;

        emit Cancel(txHash, target, value, data, eta);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface ITimeLock {
    event NewAdmin(address admin);
    event NewDelay(uint delay);
    event Queue(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta
    );
    event Execute(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta
    );
    event Cancel(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta
    );

    function admin() external view returns (address);

    function delay() external view returns (uint);

    function queued(bytes32 _txHash) external view returns (bool);

    function setAdmin(address _admin) external;

    function setDelay(uint _delay) external;

    receive() external payable;

    function getTxHash(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external pure returns (bytes32);

    function queue(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external returns (bytes32);

    function execute(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external payable returns (bytes memory);

    function cancel(
        address target,
        uint value,
        bytes calldata data,
        uint eta
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../protocol/IVault.sol";

/* solium-disable */
contract MockVault is IVault {
    address public override admin;
    address public override controller;
    address public override token;
    address public override strategy;
    address public override timeLock;
    uint public override reserveMin;
    uint public override withdrawFee;
    bool public override paused;

    mapping(address => bool) public override strategies;
    mapping(address => bool) public override whitelist;

    // test helpers
    uint public _setStrategyMin_;
    bool public _investWasCalled_;
    uint public _depositAmount_;
    uint public _withdrawAmount_;
    uint public _withdrawMin_;

    constructor(
        address _controller,
        address _timeLock,
        address _token
    ) public {
        admin = msg.sender;
        controller = _controller;
        timeLock = _timeLock;
        token = _token;
    }

    function setAdmin(address _admin) external override {}

    function setController(address _controller) external override {}

    function setTimeLock(address _timeLock) external override {}

    function setPause(bool _paused) external override {}

    function setWhitelist(address _addr, bool _approve) external override {}

    function setReserveMin(uint _min) external override {}

    function setWithdrawFee(uint _fee) external override {}

    function approveStrategy(address _strategy) external override {}

    function revokeStrategy(address _strategy) external override {}

    function setStrategy(address _strategy, uint _min) external override {
        strategy = _strategy;
        _setStrategyMin_ = _min;
    }

    function balanceInVault() external view override returns (uint) {
        return 0;
    }

    function balanceInStrategy() external view override returns (uint) {
        return 0;
    }

    function totalDebtInStrategy() external view override returns (uint) {
        return 0;
    }

    function totalAssets() external view override returns (uint) {
        return 0;
    }

    function minReserve() external view override returns (uint) {
        return 0;
    }

    function availableToInvest() external view override returns (uint) {
        return 0;
    }

    function invest() external override {
        _investWasCalled_ = true;
    }

    function deposit(uint _amount) external override {
        _depositAmount_ = _amount;
    }

    function getExpectedReturn(uint) external view override returns (uint) {
        return 0;
    }

    function withdraw(uint _shares, uint _min) external override {
        _withdrawAmount_ = _shares;
        _withdrawMin_ = _min;
    }

    function sweep(address _token) external override {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "../protocol/IVault.sol";

/* solium-disable */
contract MockTimeLock {
    // test helpers
    function _setTimeLock_(address _vault, address _timeLock) external {
        IVault(_vault).setTimeLock(_timeLock);
    }

    function _approveStrategy_(address _vault, address _strategy) external {
        IVault(_vault).approveStrategy(_strategy);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}