/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _manager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _manager = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function manager() public view virtual returns (address) {
        return _manager;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(manager() == _msgSender(), "Ownable: caller is not the owner");
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

interface IPancakeRouter {
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
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

interface ITreasury {
    function mintFairLaunch(uint256 _amount) external;

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount) external view returns (uint256 value_);
}

contract FairLaunch is Ownable {
    using SafeMath for uint256;

    // ==== STRUCTS ====

    struct UserInfo {
        uint256 purchased; // CST
        uint256 vesting; // time left to be vested
        uint256 lastTime;
    }

    // ==== CONSTANTS ====

    uint256 private constant MAX_PER_ADDR = 1000e18; // max 1k

    uint256 private constant MAX_FOR_SALE = 50000e18; // 50k

    uint256 private constant VESTING_TERM = 14 days;

    uint256 private constant EXCHANGE_RATE = 10; // 10 asset -> 1 CST

    uint256 private constant MARKET_PRICE = 14; // 1 CST: $14

    // ==== STORAGES ====

    uint256 public startVesting;

    IERC20 public BUSD;
    IERC20 public CST;

    // staking contract
    address public staking;

    // treasury contract
    address public treasury;

    // router address
    address public router;

    // factory address
    address public factory;

    // finalized status
    bool public finalized;

    // total asset purchased;
    uint256 public totalPurchased;

    // white list for private sale
    mapping(address => bool) public isWhitelist;
    mapping(address => UserInfo) public userInfo;

    // ==== EVENTS ====

    event Deposited(address indexed depositor, uint256 indexed amount);
    event Redeemed(address indexed recipient, uint256 payout, uint256 remaining);
    event WhitelistUpdated(address indexed depositor, bool indexed value);

    // ==== MODIFIERS ====

    modifier onlyWhitelisted(address _depositor) {
        require(isWhitelist[_depositor], "only whitelisted");
        _;
    }

    // ==== CONSTRUCTOR ====

    constructor(IERC20 _BUSD, uint256 _startVesting) {
        BUSD = _BUSD;
        startVesting = _startVesting;
    }

    // ==== VIEW FUNCTIONS ====

    function availableFor(address _depositor) public view returns (uint256 amount_) {
        amount_ = 0;

        if (isWhitelist[_depositor]) {
            UserInfo memory user = userInfo[_depositor];
            uint256 totalAvailable = MAX_FOR_SALE.sub(totalPurchased);
            uint256 assetPurchased = user.purchased.mul(EXCHANGE_RATE).mul(1e9);
            uint256 depositorAvailable = MAX_PER_ADDR.sub(assetPurchased);
            amount_ = totalAvailable > depositorAvailable ? depositorAvailable : totalAvailable;
        }
    }

    function payFor(uint256 _amount) public pure returns (uint256 CSTAmount_) {
        // CST decimals: 9
        // asset decimals: 18
        CSTAmount_ = _amount.mul(1e9).div(EXCHANGE_RATE).div(1e18);
    }

    function percentVestedFor(address _depositor) public view returns (uint256 percentVested_) {
        UserInfo memory user = userInfo[_depositor];

        if (block.timestamp < user.lastTime) return 0;

        uint256 timeSinceLast = block.timestamp.sub(user.lastTime);
        uint256 vesting = user.vesting;

        if (vesting > 0) {
            percentVested_ = timeSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = userInfo[_depositor].purchased;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    // ==== EXTERNAL FUNCTIONS ====

    function deposit(address _depositor, uint256 _amount) external onlyWhitelisted(_depositor) {
        require(!finalized, "already finalized");

        uint256 available = availableFor(_depositor);
        require(_amount <= available, "exceed limit");

        totalPurchased = totalPurchased.add(_amount);

        UserInfo storage user = userInfo[_depositor];
        user.purchased = user.purchased.add(payFor(_amount));
        user.vesting = VESTING_TERM;
        user.lastTime = startVesting;

        BUSD.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(_depositor, _amount);
    }

    function redeem(address _recipient, bool _stake) external {
        require(finalized, "not finalized yet");

        UserInfo memory user = userInfo[_recipient];

        uint256 percentVested = percentVestedFor(_recipient);
        if (block.timestamp < user.lastTime) return;

        if (percentVested >= 10000) {
            // if fully vested
            delete userInfo[_recipient]; // delete user info
            emit Redeemed(_recipient, user.purchased, 0); // emit bond data

            _stakeOrSend(_recipient, _stake, user.purchased); // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = user.purchased.mul(percentVested).div(10000);

            // store updated deposit info
            userInfo[_recipient] = UserInfo({
                purchased: user.purchased.sub(payout),
                vesting: user.vesting.sub(block.timestamp.sub(user.lastTime)),
                lastTime: block.timestamp
            });

            emit Redeemed(_recipient, payout, userInfo[_recipient].purchased);

            _stakeOrSend(_recipient, _stake, payout);
        }
    }

    // ==== INTERNAL FUNCTIONS ====

    function _stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal {
        if (!_stake) {
            // if user does not want to stake
            CST.transfer(_recipient, _amount); // send payout
        } else {
            // if user wants to stake
            CST.approve(staking, _amount);
            IStaking(staking).stake(_amount, _recipient);
            IStaking(staking).claim(_recipient);
        }
    }

    // ==== RESTRICT FUNCTIONS ====

    function setWhitelist(address _depositor, bool _value) external onlyOwner {
        isWhitelist[_depositor] = _value;
        emit WhitelistUpdated(_depositor, _value);
    }

    function toggleWhitelist(address[] memory _depositors) external onlyOwner {
        for (uint256 i = 0; i < _depositors.length; i++) {
            isWhitelist[_depositors[i]] = !isWhitelist[_depositors[i]];
            emit WhitelistUpdated(_depositors[i], isWhitelist[_depositors[i]]);
        }
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyManager {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(owner(), _amount);
        }
    }

    function setupContracts(
        IERC20 _CST,
        address _staking,
        address _treasury,
        address _router,
        address _factory
    ) external onlyOwner {
        CST = _CST;
        staking = _staking;
        treasury = _treasury;
        router = _router;
        factory = _factory;
    }

    // finalize the sale, init liquidity and deposit treasury
    // 100% public goes to LP pool and goes to treasury as liquidity asset
    // 100% private goes to treasury as stable asset
    function finalize() external onlyOwner {
        require(!finalized, "already finalized");
        require(address(CST) != address(0), "0 addr: CST");
        require(address(router) != address(0), "0 addr: router");
        require(address(factory) != address(0), "0 addr: factory");
        require(address(treasury) != address(0), "0 addr: treasury");
        require(address(staking) != address(0), "0 addr: staking");

        uint256 reserveAmount = totalPurchased.mul(30e18).div(100e18);
        uint256 liquidityAmount = totalPurchased.sub(reserveAmount);

        // uint256 mintForReserve = reserveAmount.div(EXCHANGE_RATE).div(1e9);
        // uint256 mintForLiquidity = liquidityAmount.div(EXCHANGE_RATE).div(1e9);
        // ITreasury(treasury).mintFairLaunch(mintForReserve.add(mintForLiquidity.mul(2)));
        uint256 mintForLiquidity = liquidityAmount.div(MARKET_PRICE).div(1e9);
        ITreasury(treasury).mintFairLaunch(totalPurchased.add(mintForLiquidity));

        BUSD.approve(treasury, 0);
        BUSD.approve(treasury, reserveAmount);
        uint256 profit = ITreasury(treasury).valueOf(address(BUSD), reserveAmount);
        ITreasury(treasury).deposit(reserveAmount, address(BUSD), profit);

        // add liquidity
        BUSD.approve(router, 0);
        BUSD.approve(router, liquidityAmount);
        CST.approve((router), 0);
        CST.approve((router), mintForLiquidity);
        IPancakeRouter(router).addLiquidity(
            address(BUSD),
            address(CST),
            liquidityAmount,
            mintForLiquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        // give treasury 100% LP, mint 50% CST
        // FAIR DEAL !!!!
        address liquidityPair = IPancakeFactory(factory).getPair(address(BUSD), address(CST));
        uint256 lpProfit = ITreasury(treasury).valueOf(liquidityPair, IERC20(liquidityPair).balanceOf(address(this)));

        IERC20(liquidityPair).approve(treasury, 0);
        IERC20(liquidityPair).approve(treasury, IERC20(liquidityPair).balanceOf(address(this)));
        ITreasury(treasury).deposit(IERC20(liquidityPair).balanceOf(address(this)), liquidityPair, lpProfit);

        finalized = true;
    }
}