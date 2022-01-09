/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: lottery-test.sol


pragma solidity ^0.8.0;



/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISTAKING {
    function stakedBalance(address account) external view returns (uint256);

    function stakingStartTime(address account) external view returns (uint256);
}

interface IFARMING {
    function poolInfo(address lpToken)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function userInfo(address account, IBEP20 lpToken)
        external
        view
        returns (
            uint256,
            uint256,
            bool,
            bool,
            uint256
        );
}

contract EinsteinLottery is Ownable, Pausable {
    /**
     * Info of each pool
     *
     * Params - pool id, nft level, points for tickets, number of winners
     */
    struct Pool {
        uint256 poolId;
        uint256 nftLevel;
        uint256 pointsForTicket;
        uint256 totalWinners;
        uint256 minStakeAmount;
        uint256 minFarmAmount;
        uint256 maxTicketsPerUser;
    }

    /**
     * Info of each game
     *
     * Params - game number, pool Id, start time, end time, winner address
     */
    struct Game {
        uint256 gameNumber;
        uint256 poolId;
        uint256 startTime;
        uint256 endTime;
        address[] winners;
        bool isGameOver;
    }

    /**
     * Info of each ticket
     *
     * Params - ticket number, owner, game number
     */
    struct Ticket {
        uint256 ticketNumber;
        uint256 poolId;
        address owner;
        uint256 gameNumber;
        uint256 timestamp;
    }

    /**
     * Info of each user points
     *
     * Params - ticket number, owner nft levels, game number, start date
     */
    struct UserPoints {
        uint256 points;
        uint256 lastUpdate;
    }

    mapping(uint256 => Pool) public poolInfo;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Ticket))) public ticketInfo; // poolId => gameId => ticketNumber => Ticket
    mapping(uint256 => mapping(uint256 => Game)) public gameInfo; //poolID => GameNumber = >Game Struct
    mapping(address => UserPoints) public userPoints;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public isGameParticipant; // poolId => gameId => userAddress => bool
    mapping(uint256 => mapping(uint256 => address[]))
        public perGameTotalParticipants; // poolId => gameId => addresses
    mapping(uint256 => mapping(uint256 => uint256[])) public perGameTickets; // poolId => gameId => Tickets
    mapping(uint256 => uint256) public poolGameCounter; // poolId => gameCounter
    mapping(uint256 => mapping(uint256 => uint256)) public gameTicketCounter; // poolId => gameId => ticketCounter
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public userTicketCounter; // user => poolId => gameId => ticketCounter
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public isAlreadyWinner; //poolId => gameId => address => is winner bool

    uint256 public totalLotteryPoints;
    ISTAKING public stakingToken;
    IFARMING public farmingToken;
    uint256 public pointInterval;
    uint256 public stakePointRate;
    uint256 public farmPointRate;
    uint256 public poolCounter;
    IBEP20[] public farmingLpPools;
    uint256 private _randomNumberNonce;
    address public BUSDAddress;
    uint256 public perPointCostInUSD; // Value should be in wei

    event AddedPool(
        uint256 poolId,
        uint256 nftLevel,
        uint256 pointsForTicket,
        uint256 totalWinners
    );
    event CreateGame(
        uint256 gameNumber,
        uint256 poolId,
        uint256 startTime,
        uint256 endTime
    );
    event BuyTickets(
        uint256 ticketNumber,
        uint256 indexed poolId,
        uint256 indexed gameId,
        uint256 pointsSpent
    );
    event GameEndTimeChanged(
        uint256 poolId,
        uint256 gameNumber,
        uint256 endTime
    );
    event WinnersAnnounced(
        uint256 poolId,
        uint256 gameNumber,
        address[] winners
    );
    event StakingTokenUpdated(address indexed _stakingToken);
    event FarmingTokenUpdated(address indexed _farmingToken);
    event PoolPointsForTicketUpdated(uint256 _poolId, uint256 _points);
    event PoolTotalWinnerUpdated(uint256 _poolId, uint256 _winnersCount);
    event ExternalTokenTransferred(
        address indexed externalAddress,
        address indexed toAddress,
        uint256 amount
    );
    event UserBoughtPoints(
        address indexed _whoBought,
        uint256 _howMuchPoints,
        uint256 _howMuchCost
    );
    event PointCostChanged(uint256 _newCost);

    constructor() {
        stakingToken = ISTAKING(0x40Ead45129FB294AE492BD9935F85B6da3657617);
        farmingToken = IFARMING(0x2925B45d6bEa03fc8058b8abA3346Ab8560528F9);
        IBEP20[1] memory _lpPools = [IBEP20(0xf7faC3522eC142ef549ACB39B4c9D4F29b96f7e6)];
        pointInterval = 60;
        stakePointRate = 1;
        farmPointRate = 1;
        BUSDAddress = 0xf7faC3522eC142ef549ACB39B4c9D4F29b96f7e6;
        perPointCostInUSD = 1 * (10**18);
        for (uint256 i = 0; i < _lpPools.length; i++) {
            farmingLpPools.push(_lpPools[i]);
        }
    }

    function distributeLotteryPoints(address recipient, uint256 _amount)
        public
        onlyOwner
    {
        userPoints[recipient].points += _amount;
        userPoints[recipient].lastUpdate = block.timestamp;
        totalLotteryPoints += _amount;
    }

    function getUserPoints(address _user) external view returns (uint256) {
        return userPoints[_user].points;
    }

    function addPool(
        uint256 _nftLevel,
        uint256 _pointsForTicket,
        uint256 _totalWinners,
        uint256 _minStakeAmount,
        uint256 _minFarmAmount,
        uint256 _maxTicketsPerUser
    ) external onlyOwner returns (bool) {
        uint256 nextPoolId = poolCounter + 1;
        require(
            poolInfo[nextPoolId].poolId != nextPoolId,
            "Pool already exists"
        );
        poolInfo[nextPoolId].poolId = nextPoolId;
        poolInfo[nextPoolId].nftLevel = _nftLevel;
        poolInfo[nextPoolId].pointsForTicket = _pointsForTicket;
        poolInfo[nextPoolId].totalWinners = _totalWinners;
        poolInfo[nextPoolId].minStakeAmount = _minStakeAmount;
        poolInfo[nextPoolId].minFarmAmount = _minFarmAmount;
        poolInfo[nextPoolId].maxTicketsPerUser = _maxTicketsPerUser;

        // initializing game pool counter
        emit AddedPool(nextPoolId, _nftLevel, _pointsForTicket, _totalWinners);
        poolCounter += 1;
        return true;
    }

    function createGame(
        uint256 _poolId,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (bool) {
        require(poolInfo[_poolId].poolId == _poolId, "Pool does not exist");
        uint256 nextGameId = poolGameCounter[_poolId] + 1;
        gameInfo[_poolId][nextGameId].poolId = _poolId;
        gameInfo[_poolId][nextGameId].startTime = _startTime;
        gameInfo[_poolId][nextGameId].endTime = _endTime;
        gameInfo[_poolId][nextGameId]
            .gameNumber = nextGameId;
        emit CreateGame(
            nextGameId,
            _poolId,
            _startTime,
            _endTime
        );
        gameTicketCounter[_poolId][poolGameCounter[_poolId]] = 1;
        poolGameCounter[_poolId]++;
        return true;
    }

    function buyTickets(uint256 _poolId, uint256 _ticketCount)
        external
        returns (bool)
    {
        require(_ticketCount > 0, "Ticket count cannot be 0");
        require(
            userTicketCounter[msg.sender][_poolId][poolGameCounter[_poolId]] +
                _ticketCount <=
                poolInfo[_poolId].maxTicketsPerUser,
            "A single address can only buy a maximum of 5 tickets per game"
        );
        //Get current game Number
        uint256 currentGameNumber = poolGameCounter[_poolId];
        require(
            block.timestamp >= gameInfo[_poolId][currentGameNumber].startTime,
            "Game has not yet started"
        );
        require(gameInfo[_poolId][currentGameNumber].startTime > 0, "Game does not exist");
        require(
            block.timestamp < gameInfo[_poolId][currentGameNumber].endTime,
            "Game has ended"
        );

        uint256 deductiblePoints = poolInfo[
            gameInfo[_poolId][currentGameNumber].poolId
        ].pointsForTicket * _ticketCount;
        require(
            userPoints[msg.sender].points >= deductiblePoints,
            "No sufficient points to buy ticket"
        );

        uint256 currentTicketNumber = gameTicketCounter[_poolId][
            currentGameNumber
        ] + 1;
        for (uint256 i = 0; i < _ticketCount; i++) {
            ticketInfo[_poolId][currentGameNumber][currentTicketNumber].ticketNumber = currentTicketNumber;
            ticketInfo[_poolId][currentGameNumber][currentTicketNumber].owner = msg.sender;
            ticketInfo[_poolId][currentGameNumber][currentTicketNumber].gameNumber = currentGameNumber;
            ticketInfo[_poolId][currentGameNumber][currentTicketNumber].timestamp = block.timestamp;
            ticketInfo[_poolId][currentGameNumber][currentTicketNumber].poolId = _poolId;
            perGameTotalParticipants[_poolId][currentGameNumber].push(
                msg.sender
            );
            perGameTickets[_poolId][currentGameNumber].push(
                currentTicketNumber
            );
            emit BuyTickets(
                currentTicketNumber,
                _poolId,
                currentGameNumber,
                poolInfo[gameInfo[_poolId][currentGameNumber].poolId]
                    .pointsForTicket
            );
            currentTicketNumber++;
        }
        isGameParticipant[_poolId][currentGameNumber][msg.sender] = true;
        gameTicketCounter[_poolId][currentGameNumber] += _ticketCount;
        userTicketCounter[msg.sender][_poolId][
            currentGameNumber
        ] += _ticketCount;
        userPoints[msg.sender].points -= deductiblePoints;
        totalLotteryPoints -= deductiblePoints;
        return true;
    }

    /*
    @Dev getPoints gives the actual balance correct balance
    */
    function getTotalAvailablePoints(address account)
        public
        view
        returns (uint256)
    {
        uint256 stakingPoints = getStakingPoints(account);
        uint256 farmingPoints = getFarmingPoints(account);
        return (stakingPoints + farmingPoints);
    }

    function getStakingPoints(address _account) public view returns (uint256) {
        uint256 stakedBalance = ISTAKING(stakingToken).stakedBalance(_account);
        uint256 stakingPoints = calculateStakingPoints(
            _account,
            stakedBalance
        ) * 10**18;
        return stakingPoints;
    }

    function getFarmingPoints(address _account) public view returns (uint256) {
        uint256 farmingPoints;
        for (uint256 i = 0; i < farmingLpPools.length; i++) {
            (uint256 farmedAmount, uint256 farmingStartTime, , , ) = IFARMING(
                farmingToken
            ).userInfo(_account, farmingLpPools[i]);
            farmingPoints +=
                calculateFarmingPoints(
                    _account,
                    farmedAmount,
                    farmingStartTime
                ) *
                10**18;
        }
        return farmingPoints;
    }

    function claimStakingAndFarmingPoints(uint256 poolId)
        public
        returns (uint256)
    {
        uint256 minStakeAmount = poolInfo[poolId].minStakeAmount;
        uint256 minFarmAmount = poolInfo[poolId].minFarmAmount;
        uint256 stakedBalance = ISTAKING(stakingToken).stakedBalance(
            msg.sender
        );
        if (stakedBalance > 0) {
            require(
                stakedBalance >= minStakeAmount,
                "Staked amount is less than threshold"
            );
        }
        uint256 stakingPoints = calculateStakingPoints(
            msg.sender,
            stakedBalance
        );
        uint256 farmingPoints = 0;
        uint256 totalFarmAmount;
        for (uint256 i = 0; i < farmingLpPools.length; i++) {
            (uint256 farmedAmount, uint256 farmingStartTime, , , ) = IFARMING(
                farmingToken
            ).userInfo(msg.sender, farmingLpPools[i]);
            totalFarmAmount += farmedAmount;
            farmingPoints += calculateFarmingPoints(
                msg.sender,
                farmedAmount,
                farmingStartTime
            );
        }
        if (totalFarmAmount > 0) {
            require(
                totalFarmAmount >= minFarmAmount,
                "Farmed amount is less than threshold"
            );
        }
        userPoints[msg.sender].points +=
            (stakingPoints + farmingPoints) *
            10**18;
        userPoints[msg.sender].lastUpdate = block.timestamp;
        totalLotteryPoints += (stakingPoints + farmingPoints) * 10**18;

        return userPoints[msg.sender].points;
    }

    function calculateStakingPoints(address account, uint256 stakedBalance)
        internal
        view
        returns (uint256)
    {
        uint256 timeDifferences;
        if (userPoints[account].lastUpdate > 0) {
            timeDifferences = block.timestamp - userPoints[account].lastUpdate;
        } else {
            timeDifferences =
                block.timestamp -
                ISTAKING(stakingToken).stakingStartTime(account);
        }

        // staking points calculation
        // Staking Points  = Staked Amount * Point Rate (APY) *  TimeDiff / Point Interval
        uint256 timeFactor = timeDifferences / pointInterval;
        uint256 stakingPoints = ((stakedBalance * timeFactor * stakePointRate) /
            100) / (10**18);
        return stakingPoints;
    }

    function calculateFarmingPoints(
        address account,
        uint256 farmedAmount,
        uint256 farmingStartTime
    ) internal view returns (uint256) {
        uint256 timeDifferences;
        if (userPoints[account].lastUpdate > 0) {
            timeDifferences = block.timestamp - userPoints[account].lastUpdate;
        } else {
            timeDifferences = block.timestamp - farmingStartTime;
        }

        // farming points calculation
        // Farming Points  = Farmed Amount * Point Rate (APY) *  TimeDiff / Point Interval
        uint256 timeFactor = timeDifferences / pointInterval;
        uint256 farmingPoints = ((farmedAmount * timeFactor * farmPointRate) /
            100) / (10**18);
        return farmingPoints;
    }

    function getPointsFromBUSD(uint256 points) external returns (bool) {
        require(points > 0, "Points cannot be 0");
        uint256 totalUSDRequired = points * perPointCostInUSD;
        IBEP20 BUSDContract = IBEP20(BUSDAddress);
        bool transferStatus = BUSDContract.transferFrom(
            msg.sender,
            address(this),
            totalUSDRequired
        );
        if (transferStatus) {
            userPoints[msg.sender].points += points;
            emit UserBoughtPoints(msg.sender, points, totalUSDRequired);
            totalLotteryPoints += points;
        }
        return transferStatus;
    }

    function setStakingToken(ISTAKING _stakingToken) external onlyOwner {
        stakingToken = _stakingToken;
        emit StakingTokenUpdated(address(stakingToken));
    }

    function setFarmingToken(IFARMING _farmingToken) external onlyOwner {
        farmingToken = _farmingToken;
        emit FarmingTokenUpdated(address(farmingToken));
    }

    function setFarmingLpPools(IBEP20[] memory _farmingLpPools)
        external
        onlyOwner
    {
        require(_farmingLpPools.length > 0, "Farming Lp pools cant be empty");
        farmingLpPools = _farmingLpPools;
    }

    function setPointInterval(uint256 _intervalInSeconds) external onlyOwner {
        require(_intervalInSeconds > 0, "Interval cant be zero");
        pointInterval = _intervalInSeconds;
    }

    function setStakePointRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate cant be zero");
        stakePointRate = _rate;
    }

    function setFarmPointRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate cant be zero");
        farmPointRate = _rate;
    }

    // Set Pool params
    function setPoolTotalWinner(uint256 _poolId, uint256 _totalWinners)
        external
        onlyOwner
    {
        require(poolInfo[_poolId].poolId == _poolId, "Pool dont exists");
        require(_totalWinners > 0, "Winners count cant be zero");
        poolInfo[_poolId].totalWinners = _totalWinners;
        emit PoolTotalWinnerUpdated(_poolId, _totalWinners);
    }

    function setPoolPointsForTicket(uint256 _poolId, uint256 _points)
        external
        onlyOwner
    {
        require(poolInfo[_poolId].poolId == _poolId, "Pool dont exists");
        require(_points > 0, "Points cant be zero");
        poolInfo[_poolId].pointsForTicket = _points;
        emit PoolPointsForTicketUpdated(_poolId, _points);
    }

    function setCostOfPoints(uint256 _rateInWei) external onlyOwner {
        require(_rateInWei > 0, "Value cannot be 0");
        perPointCostInUSD = _rateInWei;
        emit PointCostChanged(_rateInWei);
    }

    function setMinStakeAmount(uint256 _poolId, uint256 _minStakeAmount)
        external
        onlyOwner
    {
        require(poolInfo[_poolId].poolId == _poolId, "Pool dont exists");
        poolInfo[_poolId].minStakeAmount = _minStakeAmount;
    }

    function setMinFarmAmount(uint256 _poolId, uint256 _minFarmAmount)
        external
        onlyOwner
    {
        require(poolInfo[_poolId].poolId == _poolId, "Pool dont exists");
        poolInfo[_poolId].minFarmAmount = _minFarmAmount;
    }

    // Set Game params
    function setGameEndTime(
        uint256 _poolId,
        uint256 _gameNumber,
        uint256 _endTime
    ) external onlyOwner {
        require(
            _endTime > block.timestamp,
            "End time cant be below current block time"
        );
        gameInfo[_poolId][_gameNumber].endTime = _endTime;
        emit GameEndTimeChanged(_poolId, _gameNumber, _endTime);
    }

    function _setGameWinners(
        uint256 _poolId,
        uint256 _gameNumber,
        address[] memory _winners
    ) internal onlyOwner {
        require(_winners.length > 0, "Winners cant be empty");
        require(
            gameInfo[_poolId][_gameNumber].winners.length == 0,
            "Winners already updated"
        );
        require(
            block.timestamp > gameInfo[_poolId][_gameNumber].endTime,
            "Pool endTime has not reached"
        );
        gameInfo[_poolId][_gameNumber].winners = _winners;
        gameInfo[_poolId][_gameNumber].isGameOver = true;
        //updating the winners in global state
        emit WinnersAnnounced(_poolId, _gameNumber, _winners);
    }

    function _genSeed() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / block.timestamp) +
                        block.gaslimit +
                        (uint256(keccak256(abi.encodePacked(msg.sender)))) /
                        block.timestamp +
                        block.number
                )
            )
        );
        return seed;
    }

    function _genRandomNumber(
        uint256 _poolId,
        uint256 _gameNumber,
        uint256 seed
    ) private view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(seed, _poolId, _gameNumber, _randomNumberNonce)
            )
        );
        return randomNumber;
    }

    function announceWinners(uint256 _poolId, uint256 _gameNumber)
        public
        onlyOwner
        returns (address[] memory)
    {
        require(
            gameInfo[_poolId][_gameNumber].winners.length <
                poolInfo[_poolId].totalWinners,
            "All winners have been announced already"
        );
        require(
            block.timestamp > gameInfo[_poolId][_gameNumber].endTime,
            "Pool endTime has not reached"
        );
        require(
            perGameTotalParticipants[_poolId][_gameNumber].length > 0,
            "No game participants"
        );
        address[] memory participants = perGameTotalParticipants[_poolId][
            _gameNumber
        ];

        // Setting limit for the loop depending on the number of participants
        address[] memory winners;
        uint256 limit;
        if (participants.length >= poolInfo[_poolId].totalWinners) {
            limit = poolInfo[_poolId].totalWinners;
        } else {
            limit = participants.length;
        }

        winners = new address[](limit);
        uint256 seed;
        uint256 randomNumber;
        uint256 winningTicketNumber;
        address currentWinner;
        // Announce all the winners for a particular pool
        for (uint256 i = 0; i < limit; ) {
            // Calculating the random winner
            seed = _genSeed();
            randomNumber = _genRandomNumber(_poolId, _gameNumber, seed);
            winningTicketNumber =
                randomNumber %
                perGameTickets[_poolId][_gameNumber].length;
            if (winningTicketNumber != 0) {
                currentWinner = ticketInfo[_poolId][_gameNumber][
                    perGameTickets[_poolId][_gameNumber][winningTicketNumber]
                ].owner;
                // Condition to check, same winner repetition
                if (!isAlreadyWinner[_poolId][_gameNumber][currentWinner]) {
                    //updating states
                    isAlreadyWinner[_poolId][_gameNumber][currentWinner] = true;
                    winners[i] = currentWinner;
                    i++;
                }
            }
            _randomNumberNonce = uint256(
                keccak256(abi.encodePacked(seed, randomNumber))
            );
        }
        _setGameWinners(_poolId, _gameNumber, winners);
        return gameInfo[_poolId][_gameNumber].winners;
        // return _randomNumberNonce;
    }

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        require(_tokenContract != address(0), "Address cant be zero address");
        IBEP20 tokenContract = IBEP20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit ExternalTokenTransferred(_tokenContract, msg.sender, _amount);
    }
}