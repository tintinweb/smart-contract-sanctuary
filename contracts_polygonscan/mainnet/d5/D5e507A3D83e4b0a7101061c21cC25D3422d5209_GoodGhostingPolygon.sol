/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/aave/ILendingPoolAddressesProvider.sol



pragma solidity 0.6.11;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

abstract contract ILendingPoolAddressesProvider {

    function getLendingPool() public virtual view returns (address);
    function setLendingPoolImpl(address _pool) public virtual;
    function getAddress(bytes32 id) public virtual view returns (address);

    function getLendingPoolCore() public virtual view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) public virtual;

    function getLendingPoolConfigurator() public virtual view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) public virtual;

    function getLendingPoolDataProvider() public virtual view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) public virtual;

    function getLendingPoolParametersProvider() public virtual view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public virtual;

    function getTokenDistributor() public virtual view returns (address);
    function setTokenDistributor(address _tokenDistributor) public virtual;


    function getFeeProvider() public virtual view returns (address);
    function setFeeProviderImpl(address _feeProvider) public virtual;

    function getLendingPoolLiquidationManager() public virtual view returns (address);
    function setLendingPoolLiquidationManager(address _manager) public virtual;

    function getLendingPoolManager() public virtual view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) public virtual;

    function getPriceOracle() public virtual view returns (address);
    function setPriceOracle(address _priceOracle) public virtual;

    function getLendingRateOracle() public virtual view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) public virtual;

}

// File: contracts/aave/ILendingPool.sol



pragma solidity 0.6.11;

interface ILendingPool {
    function deposit(address _reserve, uint256 _amount, address onBehalfOf, uint16 _referralCode) external;
    //see: https://github.com/aave/aave-protocol/blob/1ff8418eb5c73ce233ac44bfb7541d07828b273f/contracts/tokenization/AToken.sol#L218
    function withdraw(address asset, uint amount, address to) external;
}

interface AaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset) external view returns(address, address, address);
}

// File: contracts/aave/AToken.sol



pragma solidity 0.6.11;

interface AToken {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint amount) external returns (bool);
}

// File: contracts/aave/IncentiveController.sol



pragma solidity 0.6.11;

interface IncentiveController {
  function getRewardsBalance(address[] calldata assets, address user) external view returns(uint256);

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
    ) external returns (uint256);
}

// File: contracts/aave/IWETHGateway.sol

pragma solidity 0.6.11;

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    //see: https://github.com/aave/aave-protocol/blob/1ff8418eb5c73ce233ac44bfb7541d07828b273f/contracts/tokenization/AToken.sol#L218
    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address to
    ) external;
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: @openzeppelin/contracts/utils/Pausable.sol



pragma solidity >=0.6.0 <0.8.0;


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

// File: contracts/GoodGhosting.sol



pragma solidity 0.6.11;








/// @title GoodGhosting Game Contract
/// @notice Used for games deployed on Ethereum Mainnet using Aave (v2) as the underlying pool, or for games deployed on Celo using Moola (v2) as the underlying pool
/// @author Francis Odisi & Viraz Malhotra
contract GoodGhosting is Ownable, Pausable {
    using SafeMath for uint256;

    /// @notice Ownership Control flag
    bool public allowRenouncingOwnership = false;
    /// @notice Controls if tokens were redeemed or not from the pool
    bool public redeemed;
    /// @notice controls if admin withdrew or not the performance fee.
    bool public adminWithdraw;
    /// @notice Address of the token used for depositing into the game by players (DAI)
    IERC20 public immutable daiToken;
    /// @notice Address of the interest bearing token received when funds are transferred to the external pool
    AToken public immutable adaiToken;
    /// @notice Which Aave instance we use to swap DAI to interest bearing aDAI
    ILendingPoolAddressesProvider public immutable lendingPoolAddressProvider;
    /// @notice Lending pool address
    ILendingPool public lendingPool;
    /// @notice Defines an optional token address used to provide additional incentives to users. Accepts "0x0" adresses when no incentive token exists.
    IERC20 public immutable incentiveToken;

    /// @notice total amount of incentive tokens to be distributed among winners
    uint256 public totalIncentiveAmount = 0;
    /// @notice Controls the amount of active players in the game (ignores players that early withdraw)
    uint256 public activePlayersCount = 0;
    /// @notice Stores the total amount of net interest received in the game.
    uint256 public totalGameInterest;
    /// @notice total principal amount
    uint256 public totalGamePrincipal;
    /// @notice performance fee amount allocated to the admin
    uint256 public adminFeeAmount;
    /// @notice The amount to be paid on each segment
    uint256 public immutable segmentPayment;
    /// @notice The number of segments in the game (segment count)
    uint256 public immutable lastSegment;
    /// @notice When the game started (deployed timestamp)
    uint256 public immutable firstSegmentStart;
    /// @notice The time duration (in seconds) of each segment
    uint256 public immutable segmentLength;
    /// @notice Defines the max quantity of players allowed in the game
    uint256 public immutable maxPlayersCount;
    /// @notice winner counter to track no of winners
    uint256 public winnerCount = 0;
    /// @notice The early withdrawal fee (percentage)
    uint8 public immutable earlyWithdrawalFee;
    /// @notice The performance admin fee (percentage)
    uint8 public immutable customFee;

    struct Player {
        bool withdrawn;
        bool canRejoin;
        bool isWinner;
        address addr;
        uint256 mostRecentSegmentPaid;
        uint256 amountPaid;
        uint256 winnerIndex;
    }

    /// @notice Stores info about the players in the game
    mapping(address => Player) public players;
    /// @notice controls the amount deposited in each segment that was not yet transferred to the external underlying pool
    /// @notice list of players
    address[] public iterablePlayers;
    /// @notice list of winners
    address[] public winners;

    event JoinedGame(address indexed player, uint256 amount);
    event Deposit(
        address indexed player,
        uint256 indexed segment,
        uint256 amount
    );
    event Withdrawal(
        address indexed player,
        uint256 amount,
        uint256 playerReward,
        uint256 playerIncentive
    );
    event FundsRedeemedFromExternalPool(
        uint256 totalAmount,
        uint256 totalGamePrincipal,
        uint256 totalGameInterest,
        uint256 rewards,
        uint256 totalIncentiveAmount
    );
    event WinnersAnnouncement(address[] winners);
    event EarlyWithdrawal(
        address indexed player,
        uint256 amount,
        uint256 totalGamePrincipal
    );
    event AdminWithdrawal(
        address indexed admin,
        uint256 totalGameInterest,
        uint256 adminFeeAmount,
        uint256 adminIncentiveAmount
    );

    modifier whenGameIsCompleted() {
        require(isGameCompleted(), "Game is not completed");
        _;
    }

    modifier whenGameIsNotCompleted() {
        require(!isGameCompleted(), "Game is already completed");
        _;
    }

    /**
        Creates a new instance of GoodGhosting game
        @param _inboundCurrency Smart contract address of inbound currency used for the game.
        @param _lendingPoolAddressProvider Smart contract address of the lending pool adddress provider.
        @param _segmentCount Number of segments in the game.
        @param _segmentLength Lenght of each segment, in seconds (i.e., 180 (sec) => 3 minutes).
        @param _segmentPayment Amount of tokens each player needs to contribute per segment (i.e. 10*10**18 equals to 10 DAI - note that DAI uses 18 decimal places).
        @param _earlyWithdrawalFee Fee paid by users on early withdrawals (before the game completes). Used as an integer percentage (i.e., 10 represents 10%).
        @param _customFee performance fee charged by admin. Used as an integer percentage (i.e., 10 represents 10%). Does not accept "decimal" fees like "0.5".
        @param _dataProvider id for getting the data provider contract address 0x1 to be passed.
        @param _maxPlayersCount max quantity of players allowed to join the game
        @param _incentiveToken optional token address used to provide additional incentives to users. Accepts "0x0" adresses when no incentive token exists.
     */
    constructor(
        IERC20 _inboundCurrency,
        ILendingPoolAddressesProvider _lendingPoolAddressProvider,
        uint256 _segmentCount,
        uint256 _segmentLength,
        uint256 _segmentPayment,
        uint8 _earlyWithdrawalFee,
        uint8 _customFee,
        address _dataProvider,
        uint256 _maxPlayersCount,
        IERC20 _incentiveToken
    ) public {
        require(_customFee <= 20, "_customFee must be less than or equal to 20%");
        require(_earlyWithdrawalFee <= 10, "_earlyWithdrawalFee must be less than or equal to 10%");
        require(_earlyWithdrawalFee > 0,  "_earlyWithdrawalFee must be greater than zero");
        require(_maxPlayersCount > 0, "_maxPlayersCount must be greater than zero");
        require(address(_inboundCurrency) != address(0), "invalid _inboundCurrency address");
        require(address(_lendingPoolAddressProvider) != address(0), "invalid _lendingPoolAddressProvider address");
        require(_segmentCount > 0, "_segmentCount must be greater than zero");
        require(_segmentLength > 0, "_segmentLength must be greater than zero");
        require(_segmentPayment > 0, "_segmentPayment must be greater than zero");
        require(_dataProvider != address(0), "invalid _dataProvider address");
        // Initializes default variables
        firstSegmentStart = block.timestamp; //gets current time
        lastSegment = _segmentCount;
        segmentLength = _segmentLength;
        segmentPayment = _segmentPayment;
        earlyWithdrawalFee = _earlyWithdrawalFee;
        customFee = _customFee;
        daiToken = _inboundCurrency;
        lendingPoolAddressProvider = _lendingPoolAddressProvider;
        AaveProtocolDataProvider dataProvider =
            AaveProtocolDataProvider(_dataProvider);
        // lending pool needs to be approved in v2 since it is the core contract in v2 and not lending pool core
        lendingPool = ILendingPool(
            _lendingPoolAddressProvider.getLendingPool()
        );
        // atoken address in v2 is fetched from data provider contract
        (address adaiTokenAddress, , ) =
            dataProvider.getReserveTokensAddresses(address(_inboundCurrency));
        adaiToken = AToken(adaiTokenAddress);
        maxPlayersCount = _maxPlayersCount;
        incentiveToken = _incentiveToken;
    }

    /// @notice pauses the game. This function can be called only by the contract's admin.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice unpauses the game. This function can be called only by the contract's admin.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Renounces Ownership.
    function renounceOwnership() public override onlyOwner {
        require(allowRenouncingOwnership, "Not allowed");
        super.renounceOwnership();
    }

    /// @notice Unlocks renounceOwnership.
    function unlockRenounceOwnership() external onlyOwner {
        allowRenouncingOwnership = true;
    }

    /// @notice Allows the admin to withdraw the performance fee, if applicable. This function can be called only by the contract's admin.
    /// @dev Cannot be called before the game ends.
    function adminFeeWithdraw() external virtual onlyOwner whenGameIsCompleted {
        require(redeemed, "Funds not redeemed from external pool");
        require(!adminWithdraw, "Admin has already withdrawn");
        adminWithdraw = true;

        // when there are no winners, admin will be able to withdraw the
        // additional incentives sent to the pool, avoiding locking the funds.
        uint256 adminIncentiveAmount = 0;
        if (winnerCount == 0 && totalIncentiveAmount > 0) {
            adminIncentiveAmount = totalIncentiveAmount;
        }

        emit AdminWithdrawal(owner(), totalGameInterest, adminFeeAmount, adminIncentiveAmount);

        if (adminFeeAmount > 0) {
            require(
                IERC20(daiToken).transfer(owner(), adminFeeAmount),
                "Fail to transfer ER20 tokens to admin"
            );
        }

        if (adminIncentiveAmount > 0) {
            require(
                IERC20(incentiveToken).transfer(owner(), adminIncentiveAmount),
                "Fail to transfer ER20 incentive tokens to admin"
            );
        }
    }

    /// @notice Allows a player to join the game
    function joinGame()
        external
        virtual
        whenNotPaused
    {
        _joinGame();
    }

    /// @notice Allows a player to withdraw funds before the game ends. An early withdrawal fee is charged.
    /// @dev Cannot be called after the game is completed.
    function earlyWithdraw() external virtual whenNotPaused whenGameIsNotCompleted {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;
        activePlayersCount = activePlayersCount.sub(1);
        if (winnerCount > 0 && player.isWinner) {
            winnerCount = winnerCount.sub(uint(1));
            player.isWinner = false;
            winners[player.winnerIndex] = address(0);
        }

        // In an early withdraw, users get their principal minus the earlyWithdrawalFee % defined in the constructor.
        uint256 withdrawAmount =
            player.amountPaid.sub(
                player.amountPaid.mul(earlyWithdrawalFee).div(100)
            );
        // Decreases the totalGamePrincipal on earlyWithdraw
        totalGamePrincipal = totalGamePrincipal.sub(player.amountPaid);
        uint256 currentSegment = getCurrentSegment();

        // Users that early withdraw during the first segment, are allowed to rejoin.
        if (currentSegment == 0) {
            player.canRejoin = true;
        }

        emit EarlyWithdrawal(msg.sender, withdrawAmount, totalGamePrincipal);

        lendingPool.withdraw(address(daiToken), withdrawAmount, address(this));
        require(
            IERC20(daiToken).transfer(msg.sender, withdrawAmount),
            "Fail to transfer ERC20 tokens on early withdraw"
        );
    }

    /// @notice Allows player to withdraw their funds after the game ends with no loss (fee). Winners get a share of the interest earned.
    function withdraw() external virtual {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;

        // First player to withdraw redeems everyone's funds
        if (!redeemed) {
            redeemFromExternalPool();
        }

        uint256 payout = player.amountPaid;
        uint256 playerIncentive = 0;
        if (player.mostRecentSegmentPaid == lastSegment.sub(1)) {
            // Player is a winner and gets a bonus!
            payout = payout.add(totalGameInterest.div(winnerCount));
            // If there's additional incentives, distributes them to winners
            if (totalIncentiveAmount > 0) {
                playerIncentive = totalIncentiveAmount.div(winnerCount);
            }
        }
        emit Withdrawal(msg.sender, payout, 0, playerIncentive);

        require(
            IERC20(daiToken).transfer(msg.sender, payout),
            "Fail to transfer ERC20 tokens on withdraw"
        );

        if (playerIncentive > 0) {
            require(
                IERC20(incentiveToken).transfer(msg.sender, playerIncentive),
                "Fail to transfer ERC20 incentive tokens on withdraw"
            );
        }
    }

    /// @notice Allows players to make deposits for the game segments, after joining the game.
    function makeDeposit() external whenNotPaused {
        Player storage player = players[msg.sender];
        require(
            !player.withdrawn,
            "Player already withdraw from game"
        );
        // only registered players can deposit
        require(
            player.addr == msg.sender,
            "Sender is not a player"
        );

        uint256 currentSegment = getCurrentSegment();
        // User can only deposit between segment 1 and segment n-1 (where n is the number of segments for the game).
        // Details:
        // Segment 0 is paid when user joins the game (the first deposit window).
        // Last segment doesn't accept payments, because the payment window for the last
        // segment happens on segment n-1 (penultimate segment).
        // Any segment greater than the last segment means the game is completed, and cannot
        // receive payments
        require(
            currentSegment > 0 && currentSegment < lastSegment,
            "Deposit available only between segment 1 and segment n-1 (penultimate)"
        );

        //check if current segment is currently unpaid
        require(
            player.mostRecentSegmentPaid != currentSegment,
            "Player already paid current segment"
        );

        // check if player has made payments up to the previous segment
        require(
            player.mostRecentSegmentPaid == currentSegment.sub(1),
            "Player didn't pay the previous segment - game over!"
        );
 
        emit Deposit(msg.sender, currentSegment, segmentPayment);
        _transferDaiToContract();
    }

    /// @notice gets the number of players in the game
    /// @return number of players
    function getNumberOfPlayers() external view returns (uint256) {
        return iterablePlayers.length;
    }

    /// @notice Redeems funds from the external pool and updates the internal accounting controls related to the game stats.
    /// @dev Can only be called after the game is completed.
    function redeemFromExternalPool() public virtual whenGameIsCompleted {
        require(!redeemed, "Redeem operation already happened for the game");
        redeemed = true;
        // Withdraws funds (principal + interest + rewards) from external pool
        if (adaiToken.balanceOf(address(this)) > 0) {
            lendingPool.withdraw(
                address(daiToken),
                type(uint256).max,
                address(this)
            );
        }
        uint256 totalBalance = IERC20(daiToken).balanceOf(address(this));
        // If there's an incentive token address defined, sets the total incentive amount to be distributed among winners.
        if (address(incentiveToken) != address(0)) {
            totalIncentiveAmount = IERC20(incentiveToken).balanceOf(address(this));
        }

        // calculates gross interest
        uint256 grossInterest = 0;

        // Sanity check to avoid reverting due to overflow in the "subtraction" below.
        // This could only happen in case Aave changes the 1:1 ratio between
        // aToken vs. Token in the future (i.e., 1 aDAI is worth less than 1 DAI)
        if (totalBalance > totalGamePrincipal) {
            grossInterest = totalBalance.sub(totalGamePrincipal);
        }
        // calculates the performance/admin fee (takes a cut - the admin percentage fee - from the pool's interest).
        // calculates the "gameInterest" (net interest) that will be split among winners in the game
        uint256 _adminFeeAmount;
        if (customFee > 0) {
            _adminFeeAmount = (grossInterest.mul(customFee)).div(100);
            totalGameInterest = grossInterest.sub(_adminFeeAmount);
        } else {
            _adminFeeAmount = 0;
            totalGameInterest = grossInterest;
        }

        // when there's no winners, admin takes all the interest + rewards
        if (winnerCount == 0) {
            adminFeeAmount = grossInterest;
        } else {
            adminFeeAmount = _adminFeeAmount;
        }

        emit FundsRedeemedFromExternalPool(
            totalBalance,
            totalGamePrincipal,
            totalGameInterest,
            0,
            totalIncentiveAmount
        );
        emit WinnersAnnouncement(winners);
    }

    /// @notice Calculates the current segment of the game.
    /// @return current game segment
    function getCurrentSegment() public view returns (uint256) {
        return block.timestamp.sub(firstSegmentStart).div(segmentLength);
    }

    /// @notice Checks if the game is completed or not.
    /// @return "true" if completeted; otherwise, "false".
    function isGameCompleted() public view returns (bool) {
        // Game is completed when the current segment is greater than "lastSegment" of the game.
        return getCurrentSegment() > lastSegment;
    }

    /**
        @dev Manages the transfer of funds from the player to the contract, recording
        the required accounting operations to control the user's position in the pool.
     */
    function _transferDaiToContract() internal virtual {
        require(
            daiToken.allowance(msg.sender, address(this)) >= segmentPayment,
            "You need to have allowance to do transfer DAI on the smart contract"
        );

        uint256 currentSegment = getCurrentSegment();
        players[msg.sender].mostRecentSegmentPaid = currentSegment;
        players[msg.sender].amountPaid = players[msg.sender].amountPaid.add(
            segmentPayment
        );
        // check if this is deposit for the last segment. If yes, the player is a winner.
        // since both join game and deposit method call this method so having it here
        if (currentSegment == lastSegment.sub(1)) {
            winners.push(msg.sender);
            // array indexes start from 0
            players[msg.sender].winnerIndex = winners.length.sub(uint(1));
            winnerCount = winnerCount.add(uint(1));
            players[msg.sender].isWinner = true;
        }
        
        totalGamePrincipal = totalGamePrincipal.add(segmentPayment);
        require(
            daiToken.transferFrom(msg.sender, address(this), segmentPayment),
            "Transfer failed"
        );


        // Allows the lending pool to convert DAI deposited on this contract to aDAI on lending pool
        uint256 contractBalance = daiToken.balanceOf(address(this));
        require(
            daiToken.approve(address(lendingPool), contractBalance),
            "Fail to approve allowance to lending pool"
        );

        lendingPool.deposit(address(daiToken), contractBalance, address(this), 155);
    }

    /// @notice Allows a player to join the game and controls
    function _joinGame() internal {
        require(getCurrentSegment() == 0, "Game has already started");
        require(
            players[msg.sender].addr != msg.sender ||
                players[msg.sender].canRejoin,
            "Cannot join the game more than once"
        );

        activePlayersCount = activePlayersCount.add(1);
        require(activePlayersCount <= maxPlayersCount, "Reached max quantity of players allowed");

        bool canRejoin = players[msg.sender].canRejoin;
        Player memory newPlayer =
            Player({
                addr: msg.sender,
                mostRecentSegmentPaid: 0,
                amountPaid: 0,
                withdrawn: false,
                canRejoin: false,
                isWinner: false,
                winnerIndex: 0
            });
        players[msg.sender] = newPlayer;
        if (!canRejoin) {
            iterablePlayers.push(msg.sender);
        }
        emit JoinedGame(msg.sender, segmentPayment);
        _transferDaiToContract();
    }

    // Fallback Functions for calldata and reciever for handling only ether transfer
    // receive() external payable {}
}

// File: contracts/polygon/WMatic.sol

pragma solidity 0.6.11;

/// BASED ON WMATIC CODE AVAILABLE ON https://polygonscan.com/address/0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270#code


interface WMaticToken {

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

}


/**
 *Submitted for verification at polygonscan.com on 2021-06-09
*/

// https://firebird.finance DeFi multi-chain yield farms deployer & DEXs aggregator.

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

// File: contracts/GoodGhostingPolygon.sol



pragma solidity 0.6.11;










/// @title GoodGhosting Game Contract
/// @author Francis Odisi & Viraz Malhotra
/// @notice Used for the games deployed on Polygon using Aave as the underlying external pool.
contract GoodGhostingPolygon is GoodGhosting {
    IncentiveController public incentiveController;
    IERC20 public immutable matic;
    // we can make this immutable by removing the if else in constructor ****
    IWETHGateway public wethGateway;
    uint256 public rewardsPerPlayer;

    /**
        Creates a new instance of GoodGhosting game
        @param _inboundCurrency Smart contract address of inbound currency used for the game.
        @param _lendingPoolAddressProvider Smart contract address of the lending pool adddress provider.
        @param _segmentCount Number of segments in the game.
        @param _segmentLength Lenght of each segment, in seconds (i.e., 180 (sec) => 3 minutes).
        @param _segmentPayment Amount of tokens each player needs to contribute per segment (i.e. 10*10**18 equals to 10 DAI - note that DAI uses 18 decimal places).
        @param _earlyWithdrawalFee Fee paid by users on early withdrawals (before the game completes). Used as an integer percentage (i.e., 10 represents 10%). Does not accept "decimal" fees like "0.5".
        @param _customFee performance fee charged by admin. Used as an integer percentage (i.e., 10 represents 10%). Does not accept "decimal" fees like "0.5".
        @param _dataProvider id for getting the data provider contract address 0x1 to be passed.
        @param _maxPlayersCount max quantity of players allowed to join the game
        @param _incentiveToken optional token address used to provide additional incentives to users. Accepts "0x0" adresses when no incentive token exists.
        @param _incentiveController matic reward claim contract.
        @param _matic wmatic token address.
        @param _wethGateway needed if the deposit token is wmatic
     */
    constructor(
        IERC20 _inboundCurrency,
        ILendingPoolAddressesProvider _lendingPoolAddressProvider,
        uint256 _segmentCount,
        uint256 _segmentLength,
        uint256 _segmentPayment,
        uint8 _earlyWithdrawalFee,
        uint8 _customFee,
        address _dataProvider,
        uint256 _maxPlayersCount,
        IERC20 _incentiveToken,
        address _incentiveController,
        IERC20 _matic,
        IWETHGateway _wethGateway
    )
        public
        GoodGhosting(
            _inboundCurrency,
            _lendingPoolAddressProvider,
            _segmentCount,
            _segmentLength,
            _segmentPayment,
            _earlyWithdrawalFee,
            _customFee,
            _dataProvider,
            _maxPlayersCount,
            _incentiveToken
        )
    {
        require(
            _incentiveController != address(0),
            "invalid _incentiveController address"
        );
        require(address(_matic) != address(0), "invalid _matic address");
        if (address(_matic) == address(_inboundCurrency)) {
            require(
                address(_wethGateway) != address(0),
                "invalid _wethGateway address"
            );
            wethGateway = _wethGateway;
        } else {
            wethGateway = IWETHGateway(address(0));
        }
        // initializing incentiveController contract
        incentiveController = IncentiveController(_incentiveController);
        matic = _matic;
    }

    /// @notice Allows the admin to withdraw the performance fee, if applicable. This function can be called only by the contract's admin.
    /// @dev Cannot be called before the game ends.
    function adminFeeWithdraw()
        external
        override
        onlyOwner
        whenGameIsCompleted
    {
        require(redeemed, "Funds not redeemed from external pool");
        require(!adminWithdraw, "Admin has already withdrawn");
        adminWithdraw = true;

        // when there are no winners, admin will be able to withdraw the
        // additional incentives sent to the pool, avoiding locking the funds.
        uint256 adminIncentiveAmount = 0;
        // if totalIncentiveAmount = 0 either there is no incentive or the incentive token address is same as the deposit or matic token or same as both
        if (winnerCount == 0 && totalIncentiveAmount > 0) {
            adminIncentiveAmount = totalIncentiveAmount;
        }

        emit AdminWithdrawal(
            owner(),
            totalGameInterest,
            adminFeeAmount,
            adminIncentiveAmount
        );
        // in the instance daiToken is similar to matic or incentive or both then also only the adminFeeAmount will get sent
        if (adminFeeAmount > 0) {
            require(
                IERC20(daiToken).transfer(owner(), adminFeeAmount),
                "Fail to transfer ER20 tokens to admin"
            );
        }

        if (adminIncentiveAmount > 0) {
            require(
                IERC20(incentiveToken).transfer(owner(), adminIncentiveAmount),
                "Fail to transfer ER20 incentive tokens to admin"
            );
        }
        // rewardsPerPlayer will be 0 in case of same token address as deposit token
        // in the instance the maitic token is not same as the daiToken then only the matic balance will be sent
        if (rewardsPerPlayer == 0 && address(daiToken) != address(matic)) {
            uint256 balance = IERC20(matic).balanceOf(address(this));
            require(
                IERC20(matic).transfer(owner(), balance),
                "Fail to transfer ERC20 rewards tokens to admin"
            );
        }
    }

    /// @notice Allows a player to withdraw funds before the game ends. An early withdrawal fee is charged.
    /// @dev Cannot be called after the game is completed.
    function earlyWithdraw()
        external
        override
        whenNotPaused
        whenGameIsNotCompleted
    {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;
        activePlayersCount = activePlayersCount.sub(1);
        if (winnerCount > 0 && player.isWinner) {
            winnerCount = winnerCount.sub(uint256(1));
            player.isWinner = false;
            winners[player.winnerIndex] = address(0);
        }

        // In an early withdraw, users get their principal minus the earlyWithdrawalFee % defined in the constructor.
        uint256 withdrawAmount = player.amountPaid.sub(
            player.amountPaid.mul(earlyWithdrawalFee).div(100)
        );
        // Decreases the totalGamePrincipal on earlyWithdraw
        totalGamePrincipal = totalGamePrincipal.sub(player.amountPaid);
        uint256 currentSegment = getCurrentSegment();

        // Users that early withdraw during the first segment, are allowed to rejoin.
        if (currentSegment == 0) {
            player.canRejoin = true;
        }

        emit EarlyWithdrawal(msg.sender, withdrawAmount, totalGamePrincipal);

        if (address(daiToken) != address(matic)) {
            lendingPool.withdraw(
                address(daiToken),
                withdrawAmount,
                address(this)
            );
        } else {
            require(
                adaiToken.approve(address(wethGateway), withdrawAmount),
                "Fail to approve allowance to wethGateway"
            );

            wethGateway.withdrawETH(
                address(lendingPool),
                withdrawAmount,
                address(this)
            );
            // Wraps MATIC back into WMATIC
            WMaticToken(address(matic)).deposit{value: withdrawAmount}();
        }

        require(
            IERC20(daiToken).transfer(msg.sender, withdrawAmount),
            "Fail to transfer ERC20 tokens on early withdraw"
        );
    }

    /// @notice Allows player to withdraw their funds after the game ends with no loss (fee). Winners get a share of the interest earned.
    function withdraw() external override {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;

        // First player to withdraw redeems everyone's funds
        if (!redeemed) {
            redeemFromExternalPool();
        }

        uint256 payout = player.amountPaid;
        uint256 playerIncentive = 0;
        uint256 playerReward = 0;
        if (player.mostRecentSegmentPaid == lastSegment.sub(1)) {
            // Player is a winner and gets a bonus!
            payout = payout.add(totalGameInterest.div(winnerCount));
            playerReward = rewardsPerPlayer;
            // If there's additional incentives, distributes them to winners
            if (totalIncentiveAmount > 0) {
                playerIncentive = totalIncentiveAmount.div(winnerCount);
            }
        }
        emit Withdrawal(msg.sender, payout, playerReward, playerIncentive);

        require(
            IERC20(daiToken).transfer(msg.sender, payout),
            "Fail to transfer ERC20 tokens on withdraw"
        );

        if (playerIncentive > 0) {
            require(
                IERC20(incentiveToken).transfer(msg.sender, playerIncentive),
                "Fail to transfer ERC20 incentive tokens on withdraw"
            );
        }

        if (playerReward > 0 && address(daiToken) != address(matic)) {
            require(
                IERC20(matic).transfer(msg.sender, playerReward),
                "Fail to transfer ERC20 rewards on withdraw"
            );
        }
    }

    /// @notice Redeems funds from the external pool and updates the internal accounting controls related to the game stats.
    /// @dev Can only be called after the game is completed.
    function redeemFromExternalPool() public override whenGameIsCompleted {
        require(!redeemed, "Redeem operation already happened for the game");
        redeemed = true;
        // Withdraws funds (principal + interest + rewards) from external pool
        if (adaiToken.balanceOf(address(this)) > 0) {
            if (address(daiToken) != address(matic)) {
                lendingPool.withdraw(
                    address(daiToken),
                    type(uint256).max,
                    address(this)
                );
            } else {
                require(
                    adaiToken.approve(address(wethGateway), type(uint256).max),
                    "Fail to approve allowance to wethGateway"
                );

                wethGateway.withdrawETH(
                    address(lendingPool),
                    type(uint256).max,
                    address(this)
                );

                // Wraps MATIC back into WMATIC
                WMaticToken(address(matic)).deposit{value: address(this).balance}();
            }
            // Claims the rewards from the external pool
            address[] memory assets = new address[](1);
            assets[0] = address(adaiToken);
            uint256 claimableRewards = incentiveController.getRewardsBalance(
                assets,
                address(this)
            );
            if (claimableRewards > 0) {
                incentiveController.claimRewards(
                    assets,
                    claimableRewards,
                    address(this)
                );
            }
        }
        uint256 totalBalance = IERC20(daiToken).balanceOf(address(this));
        uint256 rewardsAmount = 0;
        if (address(daiToken) != address(matic)) {
            rewardsAmount = IERC20(matic).balanceOf(address(this));
        }

        // If there's an incentive token address defined, sets the total incentive amount to be distributed among winners.
        if (
            address(incentiveToken) != address(0) &&
            address(matic) != address(incentiveToken)
        ) {
            totalIncentiveAmount = IERC20(incentiveToken).balanceOf(
                address(this)
            );
        }

        // calculates gross interest
        uint256 grossInterest = 0;
        // Sanity check to avoid reverting due to overflow in the "subtraction" below.
        // This could only happen in case Aave changes the 1:1 ratio between
        // aToken vs. Token in the future (i.e., 1 aDAI is worth less than 1 DAI)
        if (totalBalance > totalGamePrincipal) {
            grossInterest = totalBalance.sub(totalGamePrincipal);
        }
        // calculates the performance/admin fee (takes a cut - the admin percentage fee - from the pool's interest).
        // calculates the "gameInterest" (net interest) that will be split among winners in the game
        uint256 _adminFeeAmount;
        if (customFee > 0) {
            _adminFeeAmount = (grossInterest.mul(customFee)).div(100);
            totalGameInterest = grossInterest.sub(_adminFeeAmount);
        } else {
            _adminFeeAmount = 0;
            totalGameInterest = grossInterest;
        }

        // when there's no winners, admin takes all the interest + rewards
        if (winnerCount == 0) {
            rewardsPerPlayer = 0;
            adminFeeAmount = grossInterest;
        } else {
            rewardsPerPlayer = rewardsAmount.div(winnerCount);
            adminFeeAmount = _adminFeeAmount;
        }

        emit FundsRedeemedFromExternalPool(
            totalBalance,
            totalGamePrincipal,
            totalGameInterest,
            rewardsAmount,
            totalIncentiveAmount
        );
        emit WinnersAnnouncement(winners);
    }

    /**
        @dev Manages the transfer of funds from the player to the contract, recording
        the required accounting operations to control the user's position in the pool.
     */
    function _transferDaiToContract() internal override {
        if (address(daiToken) != address(matic)) {
            require(
                daiToken.allowance(msg.sender, address(this)) >= segmentPayment,
                "You need to have allowance to do transfer DAI on the smart contract"
            );
        }

        uint256 currentSegment = getCurrentSegment();
        players[msg.sender].mostRecentSegmentPaid = currentSegment;
        players[msg.sender].amountPaid = players[msg.sender].amountPaid.add(
            segmentPayment
        );
        // check if this is deposit for the last segment. If yes, the player is a winner.
        // since both join game and deposit method call this method so having it here
        if (currentSegment == lastSegment.sub(1)) {
            winners.push(msg.sender);
            // array indexes start from 0
            players[msg.sender].winnerIndex = winners.length.sub(uint256(1));
            winnerCount = winnerCount.add(uint256(1));
            players[msg.sender].isWinner = true;
        }

        totalGamePrincipal = totalGamePrincipal.add(segmentPayment);

        require(
            daiToken.transferFrom(
                msg.sender,
                address(this),
                segmentPayment
            ),
            "Transfer failed"
        );
        // Allows the lending pool to convert depositToken deposited on this contract to aToken on lending pool
        uint256 contractBalance = daiToken.balanceOf(address(this));

        if (address(daiToken) != address(matic)) {
            require(
                daiToken.approve(address(lendingPool), contractBalance),
                "Fail to approve allowance to lending pool"
            );


            lendingPool.deposit(
                address(daiToken),
                contractBalance,
                address(this),
                155
            );
        } else {
            // unwraps WMATIC back into MATIC
            WMaticToken(address(matic)).withdraw(contractBalance);
            // Deposits MATIC into the pool
            wethGateway.depositETH{value: contractBalance}(
                address(lendingPool),
                address(this),
                155
            );
        }
    }
}