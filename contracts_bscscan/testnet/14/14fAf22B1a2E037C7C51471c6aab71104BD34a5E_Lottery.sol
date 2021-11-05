// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IGateway.sol";
import "./interfaces/ILotteryPrize.sol";

/**
 * @title Lottery
 * @dev Implements noloss lottery and earn profit from deposit amount
 */
contract Lottery is PausableUpgradeable, OwnableUpgradeable {

    uint public constant TICKET_MULTIPLIER = 1e12;

    uint public roundTime;
    uint public expirePrizeTime;
    address public operator;
    uint public feeSystemPercent; // fee on interest
    address public takeFee;
    address public lotteryPrize;
    uint public fairplaytimelock; // timestamp
    uint public penaltyFeePercent; // decimal 10000
    uint public currentRound;
    uint public totalPoolWeight;
    uint public ticketPerBlock;
    uint public totalCBalance;

    struct TotalPrize {
        address erc20;
        uint amount;
    }
    struct Prize {
        uint percent; // decimal 10000
        uint n; // num of Prize
        address[] winners;
    }
    struct Round {
        TotalPrize[] totalPrizes; // update when open result
        Prize[] prize2winner; // set percent when open round and update user won when open result
        uint status; // 0 opening; 1 calculating; 2 finished
        mapping(address => bool) isTaken;
        uint startTimestamp;
        uint closeTimestamp;
    }

    struct Pool {
        IGateway gateway;
        string name;
        uint poolWeight;
        bool status; // true: enable, false: disable
        uint totalCBalance; // used for calculating amount that can be withdrawn on a pool
        uint totalPoint;
        uint accTicketPerPoint;
        uint lastTicketBlock;
    }

    struct User {
        uint balance;
        uint cBalance;  // used for calculating withdraw able amount on pool
        uint startTimestamp;  // used for check early withdraw on pool
        uint256 totalTicket;
        uint256 point;     // How many Point the user was provided.
        uint256 rewardDebt; // Ticket debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of alitas
        // entitled to a user but is pending to be distributed is:
        //
        //   pending ticket = (user.amount * TicketPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here is what happens:
        //   1. The TicketPerShare (and `lastTicketBlock`) gets updated.
        //   2. User receives the ticket.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    modifier onlyOperator() {
        require(_msgSender() == owner() || _msgSender() == operator, "Lottery: no permission");
        _;
    }

    Pool[] public pools;
    mapping(address => uint) public poolIds; // pool token => pool id

    mapping(uint => Round) public rounds; // round id => round;

    mapping(address => mapping(address => User)) public users; // pool id => wallet => User
    mapping(address => User) public userInfo;
    mapping(address => uint) public erc20PendingForPrize; // erc20 => amount

    event Initialize(address _operator, address _lotteryPrize, uint _ticketPerBlock);
    event Withdraw(address _user, address _pool);
    event Deposit(address _user, address _pool, uint _amount);
    event AddPool(string _name, address _gateway, address _token, uint _weight);
    event UpdatePoolWeight(uint _poolId, uint _weight);
    event UpdatePoolStatus(uint _poolId, bool _status);
    event UpdateTicketPerBlock(uint _ticketPerBlock);
    event OpenRound(TotalPrize[] _totalPrize, Prize[] _prizePercent);
    event CalculatingRound(uint _roundId);
    event HandleExpirePrize(uint _roundId);
    event ClaimPrize(address _user, uint _roundId);
    event Config(uint _feeSystemPercent, address _takeFee, uint _fairplaytimelock, uint _penaltyFeePercent);
    event SetOperator(address _operator);
    event SetRoundTime(uint _timestamp);
    event SetExpirePrizeTime(uint _timestamp);

    function initialize(address _operator, address _lotteryPrize, uint _ticketPerBlock) public initializer {
        __Ownable_init();

        roundTime = 1 weeks;
        expirePrizeTime = 14 days;

        operator = _operator;
        lotteryPrize = _lotteryPrize;
        ticketPerBlock = _ticketPerBlock;

        emit Initialize(_operator, _lotteryPrize, _ticketPerBlock);
    }

    function withdrawAbleAmount(address user, address _pool) public view returns (uint) {
        User memory _user = users[_pool][user];
        uint _totalLock = pools[poolIds[_pool]].gateway.getTotalLock();
        return _user.cBalance * _totalLock / pools[poolIds[_pool]].totalCBalance;
    }
    function withdrawAbleAmountAfterFee(address user, address _pool) public view returns (uint _amount, uint _fee, uint _feePenalty) {
        User memory _user = users[_pool][user];
        uint _totalAmount = withdrawAbleAmount(_msgSender(), _pool);
        uint _timeLock = block.timestamp - _user.startTimestamp;
        _fee = feeSystemPercent * _totalAmount / 10000;
        _feePenalty = _timeLock >= fairplaytimelock ? 0 : penaltyFeePercent * _totalAmount / 10000;
        _amount = _totalAmount - _fee - _feePenalty;
    }
    function withdraw(address _pool) public {
        User memory _user = users[_pool][_msgSender()];
        require(_user.balance > 0, "Lottery: not balance");

        uint _amount;
        uint _fee;
        uint _feePenalty;
        (_amount, _fee, _feePenalty) = withdrawAbleAmountAfterFee(_msgSender(), _pool);
        uint totalFee = _fee + _feePenalty;
        pools[poolIds[_pool]].gateway.withdraw(_msgSender(), _amount + totalFee, totalFee);
        if(_feePenalty > 0) IERC20(_pool).transfer(lotteryPrize, _feePenalty);
        if(_fee > 0) IERC20(_pool).transfer(takeFee, _fee);

        users[_pool][_msgSender()] = User(0, 0, 0, 0, 0, 0);
        pools[poolIds[_pool]].totalCBalance = pools[poolIds[_pool]].totalCBalance - _user.cBalance;
        emit Withdraw(_msgSender(), _pool);
    }

    function massUpdateTicketPools() public {
        uint256 length = pools.length;

        for (uint256 i = 1; i <= length; i++) {
            updateTicketPool(i);
        }
    }

    function updateTicketPool(uint _poolId) public {
        Pool storage pool = pools[_poolId - 1];

        if (block.number <= pool.lastTicketBlock) {
            return;
        }

        uint totalPoint = pool.totalPoint;

        if (totalPoint == 0 || pool.poolWeight == 0) {
            pool.lastTicketBlock = block.number;
            return;
        }

        uint256 numTickets = (block.number - pool.lastTicketBlock) * ticketPerBlock * pool.poolWeight / totalPoolWeight;

        pool.accTicketPerPoint += (numTickets * TICKET_MULTIPLIER / totalPoint);
        pool.lastTicketBlock = block.number;
    }

    function deposit(address _pool, uint _amount) public whenNotPaused { // token approve to gateway contract
        require(pools[poolIds[_pool]].status, "Lottery: pool is disabled");
        uint _totalLock = pools[poolIds[_pool]].gateway.getTotalLock();
        pools[poolIds[_pool]].gateway.deposit(_msgSender(), _amount);

        // update user info on pool
        User storage _user = users[_pool][_msgSender()];
        _user.startTimestamp = block.timestamp;
        _user.balance = _user.balance + _amount;

        // update cbalance on pool to check withdraw able amount

        uint _cBalance = pools[poolIds[_pool]].totalCBalance == 0 ? _amount : _amount * pools[poolIds[_pool]].totalCBalance / _totalLock;
        _user.cBalance = _user.cBalance + _cBalance;
        pools[poolIds[_pool]].totalCBalance = pools[poolIds[_pool]].totalCBalance + _cBalance;


        // update point to check ticket receiver
        uint _point = pools[poolIds[_pool]].gateway.getTokenPrice(_amount);
        _user.point = _user.point + _point;
        _user.rewardDebt = _user.point + pools[poolIds[_pool]].accTicketPerPoint / 1e12;
        emit Deposit(_msgSender(), _pool, _amount);
    }

    function addPool(IGateway _gateway, string memory _name, uint _weight, bool _withUpdate) public onlyOwner {
        address token = _gateway.erc20();

        require(poolIds[token] == 0, "Lottery: token has added");

        if (_withUpdate) {
            massUpdateTicketPools();
        }

        pools.push(Pool({
        gateway: _gateway,
        name: _name,
        poolWeight: _weight,
        status: true,
        totalCBalance: 0,
        totalPoint: 0,
        accTicketPerPoint: 0,
        lastTicketBlock: block.number
        }));

        poolIds[token] = pools.length - 1;

        totalPoolWeight += _weight;

        emit AddPool(_name, address(_gateway), token, _weight);
    }

    function getPools() public view returns (Pool[] memory) {
        return pools;
    }

    function updatePoolWeight(uint _poolId, uint _weight, bool _withUpdate) public onlyOwner {
        Pool storage pool = pools[_poolId - 1];

        if (_withUpdate) {
            massUpdateTicketPools();
        }

        totalPoolWeight = totalPoolWeight - pool.poolWeight + _weight;

        pool.poolWeight = _weight;

        emit UpdatePoolWeight(_poolId, _weight);
    }

    function updatePoolStatus(uint _poolId, bool _status) public onlyOwner {
        Pool storage pool = pools[_poolId - 1];

        pool.status = _status;

        emit UpdatePoolStatus(_poolId, _status);
    }

    function updateTicketPerBlock(uint _ticketPerBlock) public onlyOwner {
        massUpdateTicketPools();

        ticketPerBlock = _ticketPerBlock;

        emit UpdateTicketPerBlock(_ticketPerBlock);
    }

    function totalPrize() public view returns (uint) {}

    function openRound(TotalPrize[] memory _totalPrize, Prize[] memory _prizePercent) public onlyOperator {
        require(rounds[currentRound].status != 0, "Lottery: current round is running");
        currentRound += 1;
        for(uint i = 0; i < _totalPrize.length; i++) {
            rounds[currentRound].totalPrizes.push(_totalPrize[i]);
        }
        for(uint j = 0; j < _prizePercent.length; j++) {
            rounds[currentRound].prize2winner.push(_prizePercent[j]);
        }
        rounds[currentRound].startTimestamp = block.timestamp;
        emit OpenRound(_totalPrize, _prizePercent);
    }
    function _calculatingRound(uint _roundId) internal {
        Round storage _round = rounds[_roundId];
        TotalPrize[] memory _totalPrizes = _round.totalPrizes;
        address[] memory _erc20Prizes;
        for(uint i = 0; i < _totalPrizes.length; i++) {
            _erc20Prizes[i] = _totalPrizes[i].erc20;
        }
        uint[] memory _erc20PrizeBlances = ILotteryPrize(lotteryPrize).getTotalPrize(_erc20Prizes);
        for(uint i = 0; i < _totalPrizes.length; i++) {
            _round.totalPrizes[i].amount = _erc20PrizeBlances[i] - erc20PendingForPrize[_erc20Prizes[i]];
        }
        // todo find winner
        rounds[_roundId].status = 2;
    }
    function calculatingRound() public onlyOperator {
        require(rounds[currentRound].startTimestamp > 0 && rounds[currentRound].status == 0, "Lottery: no round is running");
        require(block.timestamp - rounds[currentRound].startTimestamp >= roundTime, "Lottery: Not meet round time");
        _calculatingRound(currentRound);
        rounds[currentRound].status = 1;
        emit CalculatingRound(currentRound);
    }

    function getPrizePercent(uint _roundId) public view returns(Prize[] memory) {
        return rounds[_roundId].prize2winner;
    }
    function getTotalPrize(uint _roundId) public view returns(TotalPrize[] memory) {
        return rounds[_roundId].totalPrizes;
    }

    function findWinners() public onlyOperator { // find out winners
        rounds[currentRound].status = 1;
    }
    function isExpirePrize(uint _roundId) public view returns (bool){
        return rounds[_roundId].startTimestamp > 0 && block.timestamp - rounds[_roundId].startTimestamp > expirePrizeTime;
    }
    function handleExpirePrize(uint _roundId) public {
        require(isExpirePrize(_roundId), "Lottery: Prize not expired");
        Round storage _round = rounds[_roundId];
        TotalPrize[] memory _totalPrizes = rounds[_roundId].totalPrizes;
        Prize[] memory _prizes = rounds[_roundId].prize2winner;
        for(uint i = 0; i < _prizes.length; i++) {
            for(uint j = 0; j < _prizes[i].winners.length; j++) {
                if(!_round.isTaken[_prizes[i].winners[j]]) {
                    uint _prizeAmount = _prizes[i].percent * _totalPrizes[i].amount / 10000;
                    erc20PendingForPrize[_totalPrizes[i].erc20] = erc20PendingForPrize[_totalPrizes[i].erc20] - _prizeAmount;
                }
            }
        }
        emit HandleExpirePrize(_roundId);
    }
    function harvest(address _pool) public {
        pools[poolIds[_pool]].gateway.harvest();
    }
    function claimPrize(uint _roundId) public {
        require(!isExpirePrize(_roundId), "Lottery: Prize expired");
        Round storage _round = rounds[_roundId];
        require(!_round.isTaken[_msgSender()], "Lottery: Claimed");
        TotalPrize[] memory _totalPrizes = rounds[_roundId].totalPrizes;
        Prize[] memory _prizes = rounds[_roundId].prize2winner;
        address[] memory slot;
        uint[] memory percent;
        for(uint i = 0; i < _prizes.length; i++) {
            for(uint j = 0; j < _prizes[i].winners.length; j++) {
                if(_prizes[i].winners[j] == _msgSender()) {
                    slot[slot.length] = _msgSender();
                    percent[percent.length] = _prizes[i].percent;
                }
            }
        }
        require(slot.length > 0, "Lottery: not win this round");

        for(uint i = 0; i < _totalPrizes.length; i++) {

            for(uint j = 0; j < slot.length; j++) {
                uint _prizeAmount = percent[j] * _totalPrizes[i].amount / 10000;
                IERC20(_totalPrizes[i].erc20).transferFrom(lotteryPrize, slot[j], _prizeAmount);
                erc20PendingForPrize[_totalPrizes[i].erc20] = erc20PendingForPrize[_totalPrizes[i].erc20] - _prizeAmount;
            }
        }
        _round.isTaken[_msgSender()] = true;
        emit ClaimPrize(_msgSender(), _roundId);
    }
    function claimPrizes(uint[] memory _roundIds) public {
        for(uint i = 0; i < _roundIds.length; i++) {
            claimPrize(_roundIds[i]);
        }
    }
    function config(uint _feeSystemPercent, address _takeFee, uint _fairplaytimelock, uint _penaltyFeePercent) public onlyOwner{
        feeSystemPercent = _feeSystemPercent;
        takeFee = _takeFee;
        fairplaytimelock = _fairplaytimelock;
        penaltyFeePercent = _penaltyFeePercent;
        emit Config(_feeSystemPercent, _takeFee, _fairplaytimelock, _penaltyFeePercent);
    }

    function configOperator(address _operator) public onlyOwner {
        operator = _operator;

        emit SetOperator(_operator);
    }

    function configRoundTime(uint _timestamp) public onlyOwner {
        roundTime = _timestamp;

        emit SetRoundTime(_timestamp);
    }

    function configExpirePrizeTime(uint _timestamp) public onlyOwner {
        expirePrizeTime = _timestamp;

        emit SetExpirePrizeTime(_timestamp);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGateway {
    function deposit(address _from, uint _amount) external;
    function withdraw(address _to, uint _amount, uint _fee) external;
    function getTotalLock() external view returns (uint);
    function getTokenPrice(uint _erc20Amount) external view returns (uint);
    function harvest() external;
    function erc20() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILotteryPrize {
    function getTotalPrize(address[] memory _erc20s) external view returns(uint[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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