/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

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
    event Paused(address account, string symbol);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account, string symbol);

    //    bool private _paused;
    mapping(string => bool) private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused['BNB'] = false;
        _paused['BAT'] = false;
        _paused['TRX'] = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(string memory _symbol) public view virtual returns (bool) {
        return _paused[_symbol];
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(string memory _symbol) {
        require(!paused(_symbol), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused(string memory _symbol) {
        require(paused(_symbol), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause(string memory _symbol) internal virtual whenNotPaused(_symbol) {
        _paused[_symbol] = true;
        emit Paused(_msgSender(), _symbol);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause(string memory _symbol) internal virtual whenPaused(_symbol) {
        _paused[_symbol] = false;
        emit Unpaused(_msgSender(), _symbol);
    }
}

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function addRoundId() external;

    function decimals()
    external
    view
    returns (
        uint8
    );

    function description()
    external
    view
    returns (
        string memory
    );

    function version()
    external
    view
    returns (
        uint256
    );

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}


interface IPledge {
    function capitalInjection() external payable;
}


pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title PredictionV2
 */
contract Prediction_MATIC_Abridgment is Ownable, Pausable, ReentrancyGuard,KeeperCompatibleInterface {
    using SafeERC20 for IERC20;

    AggregatorV3Interface public oracle;

    string [] public symbols;
    mapping(string => address) symbolOracle;
    mapping(string => uint) symbolSwitch;

    mapping(string => bool) public genesisLockOnce;
    mapping(string => bool) public genesisStartOnce;

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator

    mapping(string => uint256) public bufferSeconds; // number of seconds for valid execution of a prediction round
    mapping(string => uint256) public intervalSeconds; // interval in seconds between two prediction rounds

    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    mapping(string => uint256) public currentEpochMap; // current epoch for prediction round


    mapping(string => uint256) oracleLatestRoundId; // converted from uint80 (Chainlink)
    uint256 public oracleUpdateAllowance; // seconds

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%

    mapping(string => mapping(uint256 => mapping(address => BetInfo))) ledger;
    mapping(string => mapping(uint256 => Round)) public rounds;
    mapping(string => mapping(address => uint256[])) public userRounds;
    mapping(string => mapping(uint256 => uint256)) public roundsAverageMining;

    //手续费分配
    uint256 public TOTAL_FEE = 100;
    uint256 public destroyRate = 50;
    uint256 public teamRate = 50;
    bool public openRepurchase = false;
    address public teamAddress;

    //token 合约地址
    address tokenAddress = 0x6B8Ed1F1926Ff51E74b1FC91fe50F3a6A0b4525D;
    address blackHoleAddress = 0x000000000000000000000000000000000000dEaD;

    //奖励递减周期
    uint256 public decrementPeriod = 274910;
    //当前每assetUnit挖取PT的数量
    uint256 public averageMining = 10 * 10 ** 9;

    uint256 public minMining = 1 * 10 ** 9;
    //1 = ?wei
    uint256 public assetUnit = 1000000000000000000;
    //递减 1000
    uint256 public decreasingRatio = 20;
    //挖矿开始区块
    uint256 public miningStartBlock = 0;
    //质押合约地址
    address public PledgeContractAddress;

    //质押的分配比例
    uint256 public rewardCardProportion = 500;
    //质押的分配比例全部占比
    uint256 public rewardCardAllProportion = 1000;

    enum Position {
        Bull,
        Bear
    }

    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
        bool miningRewards; // default false
    }

    event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount, string symbol, uint256 miningAmount);
    event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount, string symbol, uint256 miningAmount);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount, string symbol);
    event EndRound(uint256 indexed epoch, uint256 indexed roundId, int256 price, string symbol);
    event LockRound(uint256 indexed epoch, uint256 indexed roundId, int256 price, string symbol);

    event NewAdminAddress(address admin);
    event NewBufferAndIntervalSeconds(uint256 bufferSeconds, uint256 intervalSeconds, string symbol);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewOperatorAddress(address operator);
    event NewOracle(address oracle, string symbol);
    event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);

    event Pause(uint256 indexed epoch, string symbol);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount,
        string symbol
    );

    event StartRound(uint256 indexed epoch, string symbol);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch, string symbol);
    event TotalFeeUpdated(uint256 epoch, uint256 destroyRate, uint256 teamRate);
    event ClaimTreasury(uint256 destroyAmount, uint256 teamAmount);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function setPledgeContractAddress(address _PledgeContractAddress) external onlyAdmin {
        PledgeContractAddress = _PledgeContractAddress;
    }

    function setRewardCardProportion(uint256 _rewardCardProportion) external onlyAdmin {
        rewardCardProportion = _rewardCardProportion;
    }

    function setPRewardCardAllProportion(uint256 _rewardCardAllProportion) external onlyAdmin {
        rewardCardAllProportion = _rewardCardAllProportion;
    }

    function setPtToken(address _ptToken) external onlyAdmin {
        require(_ptToken != address(0), "Cannot be zero address");
        tokenAddress = _ptToken;
    }

    function setRepurchase(bool _openRepurchase) external onlyAdmin {
        openRepurchase = _openRepurchase;
    }

    function setTeamAddress(address _teamAddress) external onlyAdmin {
        require(_teamAddress != address(0), "Cannot be zero address");
        teamAddress = _teamAddress;
    }


    function setDecrementPeriod(uint256 _decrementPeriod) external onlyAdmin {
        decrementPeriod = _decrementPeriod;
    }

    function setAverageMining(uint256 _averageMining) external onlyAdmin {
        averageMining = _averageMining;
    }

    function setMinMining(uint256 _minMining) external onlyAdmin {
        minMining = _minMining;
    }

    function setDecreasingRatio(uint256 _decreasingRatio) external onlyAdmin {
        decreasingRatio = _decreasingRatio;
    }


    /**
    * @dev set DestroyRate
    * callable by admin
    */
    function setDestroyRate(uint256 _destroyRate) external onlyAdmin {
        require(_destroyRate <= TOTAL_FEE, "rewardRate cannot be more than 100%");
        destroyRate = _destroyRate;
        teamRate = TOTAL_FEE - _destroyRate;

        emit TotalFeeUpdated(currentEpochMap["BNB"], destroyRate, teamRate);
    }

    function _claimTreasury() internal {
        uint256 destroy = 0;
        uint256 team = treasuryAmount - destroy;
        treasuryAmount = 0;
        _safeTransfer(teamAddress, team);
        emit ClaimTreasury(destroy, team);
    }


    constructor(
        address _teamAddress,
        address _adminAddress,
        address _operatorAddress,
        uint256 _minBetAmount,
        uint256 _oracleUpdateAllowance,
        uint256 _treasuryFee
    ) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

//        symbolOracle['BAT'] = 0x0e4fcEC26c9f85c3D714370c98f43C4E02Fc35Ae;
//        symbolOracle['TRX'] = 0x9477f0E5bfABaf253eacEE3beE3ccF08b46cc79c;
        symbolOracle['BTC'] = 0x0E9B68AdEE218056586bc21d0B25767981665c94;
//        symbolSwitch['BAT'] = 1;
//        symbolSwitch['TRX'] = 1;
        symbolSwitch['BTC'] = 1;
        intervalSeconds['BTC'] = 180;
//        intervalSeconds['TRX'] = 2000;
//        intervalSeconds['BAT'] = 2000;
        bufferSeconds['BTC'] = 100;
//        bufferSeconds['TRX'] = 2000;
//        bufferSeconds['BAT'] = 2000;
//        symbols.push('BAT');
//        symbols.push('TRX');
        symbols.push('BTC');
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        minBetAmount = _minBetAmount;
        oracleUpdateAllowance = _oracleUpdateAllowance;
        treasuryFee = _treasuryFee;
        teamAddress = _teamAddress;
    }

    /**
     * @notice Bet bear position
     * @param epoch: epoch
     */
    function betBear(uint256 epoch, string memory _symbol) external payable whenNotPaused(_symbol) nonReentrant notContract {
        require(symbolSwitch[_symbol] == 1, "the_currency_is_not_yet_open");
        require(epoch == currentEpochMap[_symbol], "Bet is too early/late");
        require(_bettable(_symbol, epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[_symbol][epoch][msg.sender].amount == 0, "Can only bet once per round");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[_symbol][epoch];
        round.totalAmount = round.totalAmount + amount;
        round.bearAmount = round.bearAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[_symbol][epoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[_symbol][msg.sender].push(epoch);

        emit BetBear(msg.sender, epoch, amount, _symbol, betInfo.amount * roundsAverageMining[_symbol][epoch] / assetUnit);
    }

    /**
     * @notice Bet bull position
     * @param epoch: epoch
     */
    function betBull(uint256 epoch, string memory _symbol) external payable whenNotPaused(_symbol) nonReentrant notContract {
        require(symbolSwitch[_symbol] == 1, "the_currency_is_not_yet_open");
        require(epoch == currentEpochMap[_symbol], "Bet is too early/late");
        require(_bettable(_symbol, epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[_symbol][epoch][msg.sender].amount == 0, "Can only bet once per round");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[_symbol][epoch];
        round.totalAmount = round.totalAmount + amount;
        round.bullAmount = round.bullAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[_symbol][epoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[_symbol][msg.sender].push(epoch);

        emit BetBull(msg.sender, epoch, amount, _symbol, betInfo.amount * roundsAverageMining[_symbol][epoch] / assetUnit);
    }

    /**
     * @notice Claim reward for an array of epochs
     * @param epochs: array of epochs
     */
    function claim(string memory _symbol, uint256[] calldata epochs) external nonReentrant notContract {
        uint256 reward;
        // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(rounds[_symbol][epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > rounds[_symbol][epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (rounds[_symbol][epochs[i]].oracleCalled) {
                require(claimable(_symbol, epochs[i], msg.sender), "Not eligible for claim");
                Round memory round = rounds[_symbol][epochs[i]];
                addedReward = (ledger[_symbol][epochs[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(_symbol, epochs[i], msg.sender), "Not eligible for refund");
                addedReward = ledger[_symbol][epochs[i]][msg.sender].amount;
            }

            ledger[_symbol][epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward, _symbol);
        }

        if (reward > 0) {
            _safeTransfer(address(msg.sender), reward);
        }
    }

    function miningRewardsBalance(string memory _symbol, uint256 epoch) public view returns (uint256){
        return ledger[_symbol][epoch][msg.sender].amount * roundsAverageMining[_symbol][epoch] / assetUnit;
    }

    event miningRewards(address indexed sender, uint256 indexed epoch, uint256 amount, string symbol);

    function mining(string memory _symbol, uint256[] calldata epochs) external nonReentrant notContract {
        uint256 reward;
        // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(rounds[_symbol][epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > rounds[_symbol][epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;
            uint256 numberOfInputs = 0;
            // Round valid, claim rewards
            if (rounds[_symbol][epochs[i]].oracleCalled) {
                require(mineable(_symbol, epochs[i], msg.sender), "Not eligible for claim");
                numberOfInputs = ledger[_symbol][epochs[i]][msg.sender].amount;
                if (miningStartBlock == 0) {
                    miningStartBlock = block.number;
                }
                if (block.number > miningStartBlock + decrementPeriod) {
                    miningStartBlock = miningStartBlock + decrementPeriod;
                    averageMining = averageMining - (averageMining * (1000 - decreasingRatio) / 1000);
                    if (averageMining < 1000000000) {
                        averageMining = 1000000000;
                    }
                }
                addedReward = numberOfInputs * roundsAverageMining[_symbol][epochs[i]] / assetUnit;
            }
            ledger[_symbol][epochs[i]][msg.sender].miningRewards = true;
            reward += addedReward;

            emit miningRewards(msg.sender, epochs[i], addedReward, _symbol);
        }

        if (reward > 0) {
            IERC20(tokenAddress).safeTransfer(address(msg.sender), reward);
        }
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        string memory _symbol = string(checkData);
        require(
            genesisStartOnce[_symbol] && genesisLockOnce[_symbol],
            "Can only run after genesisStartRound and genesisLockRound is triggered"
        );
        _safeLockRoundRequire(_symbol, currentEpochMap[_symbol]);
        _safeEndRoundRequire(_symbol, currentEpochMap[_symbol] - 1);
        _calculateRewardsRequire(_symbol, currentEpochMap[_symbol] - 1);
        _safeStartRoundRequire(_symbol, currentEpochMap[_symbol]+1);
        performData = checkData;
        upkeepNeeded = true;
    }

    function performUpkeep(bytes calldata performData) external override {
        string memory _symbol = string(performData);
        executeRoundCall(_symbol);
    }

    function executeRoundCall(string memory _symbol) internal{
        require(
            genesisStartOnce[_symbol] && genesisLockOnce[_symbol],
            "Can only run after genesisStartRound and genesisLockRound is triggered"
        );

        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle(_symbol);

        oracleLatestRoundId[_symbol] = uint256(currentRoundId);
        AggregatorV3Interface(symbolOracle[_symbol]).addRoundId();
        // CurrentEpoch refers to previous round (n-1)
        _safeLockRound(_symbol, currentEpochMap[_symbol], currentRoundId, currentPrice);
        _safeEndRound(_symbol, currentEpochMap[_symbol] - 1, currentRoundId, currentPrice);
        _calculateRewards(_symbol, currentEpochMap[_symbol] - 1);

        // Increment currentEpoch to current round (n)
        currentEpochMap[_symbol] = currentEpochMap[_symbol] + 1;
        _safeStartRound(_symbol, currentEpochMap[_symbol]);
    }

    /**
     * @notice Start the next round n, lock price for round n-1, end round n-2
     * @dev Callable by operator
     */
    function executeRound(string memory _symbol) external whenNotPaused(_symbol) onlyOperator {
        executeRoundCall(_symbol);
    }

    /**
     * @notice Lock genesis round
     * @dev Callable by operator
     */
    function genesisLockRound(string memory _symbol) external whenNotPaused(_symbol) onlyOperator {
        require(genesisStartOnce[_symbol], "Can only run after genesisStartRound is triggered");
        require(!genesisLockOnce[_symbol], "Can only run genesisLockRound once");
        AggregatorV3Interface(symbolOracle[_symbol]).addRoundId();
        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle(_symbol);

        oracleLatestRoundId[_symbol] = uint256(currentRoundId);

        _safeLockRound(_symbol, currentEpochMap[_symbol], currentRoundId, currentPrice);

        currentEpochMap[_symbol] = currentEpochMap[_symbol] + 1;
        _startRound(_symbol, currentEpochMap[_symbol]);
        genesisLockOnce[_symbol] = true;
    }

    /**
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function genesisStartRound(string memory _symbol) external whenNotPaused(_symbol) onlyOperator {
        require(!genesisStartOnce[_symbol], "Can only run genesisStartRound once");

        currentEpochMap[_symbol] = currentEpochMap[_symbol] + 1;
        _startRound(_symbol, currentEpochMap[_symbol]);
        genesisStartOnce[_symbol] = true;
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause(string memory _symbol) external whenNotPaused(_symbol) onlyAdminOrOperator {
        _pause(_symbol);

        emit Pause(currentEpochMap[_symbol], _symbol);
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        _claimTreasury();
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause(string memory _symbol) external whenPaused(_symbol) onlyAdmin {
        genesisStartOnce[_symbol] = false;
        genesisLockOnce[_symbol] = false;
        _unpause(_symbol);

        emit Unpause(currentEpochMap[_symbol], _symbol);
    }

    /**
     * @notice Set buffer and interval (in seconds)
     * @dev Callable by admin
     */
    function setBufferAndIntervalSeconds(string memory _symbol, uint256 _bufferSeconds, uint256 _intervalSeconds)
    external
    whenPaused(_symbol)
    onlyAdmin
    {
        require(_bufferSeconds < _intervalSeconds, "bufferSeconds must be inferior to intervalSeconds");
        bufferSeconds[_symbol] = _bufferSeconds;
        intervalSeconds[_symbol] = _intervalSeconds;

        emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds, _symbol);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinBetAmount(string memory _symbol, uint256 _minBetAmount) external whenPaused(_symbol) onlyAdmin {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(currentEpochMap[_symbol], minBetAmount);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Set Oracle address
     * @dev Callable by admin
     */
    function setOracle(string memory _symbol, address _oracle) external whenPaused(_symbol) onlyAdmin {
        require(_oracle != address(0), "Cannot be zero address");
        oracleLatestRoundId[_symbol] = 0;
        symbolOracle[_symbol] = _oracle;
        oracle = AggregatorV3Interface(_oracle);

        // Dummy check to make sure the interface implements this function properly
        oracle.latestRoundData();

        emit NewOracle(_oracle, _symbol);
    }

    /**
     * @notice Set oracle update allowance
     * @dev Callable by admin
     */
    function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external whenPaused("BNB") onlyAdmin {
        oracleUpdateAllowance = _oracleUpdateAllowance;

        emit NewOracleUpdateAllowance(_oracleUpdateAllowance);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(string memory _symbol, uint256 _treasuryFee) external whenPaused(_symbol) onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentEpochMap[_symbol], treasuryFee);
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }
    /**
    *   添加新币种
    *
    */
    function setSymbol(string memory _symbol, uint256 _bufferSeconds, uint256 _intervalSeconds, address _oracleAddress) external onlyAdmin {
        require(symbolOracle[_symbol] == address(0), "cannotAddRepeatedly");
        symbols.push(_symbol);
        bufferSeconds[_symbol] = _bufferSeconds;
        intervalSeconds[_symbol] = _intervalSeconds;
        symbolSwitch[_symbol] = 1;
        symbolOracle[_symbol] = _oracleAddress;

    }

    /**
     * @notice Returns round epochs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        string memory _symbol,
        address user,
        uint256 cursor,
        uint256 size
    )
    external
    view
    returns (
        uint256[] memory,
        BetInfo[] memory,
        uint256
    )
    {
        uint256 length = size;

        if (length > userRounds[_symbol][user].length - cursor) {
            length = userRounds[_symbol][user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[_symbol][user][cursor + i];
            betInfo[i] = ledger[_symbol][values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(string memory _symbol, address user) external view returns (uint256) {
        return userRounds[_symbol][user].length;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function claimable(string memory _symbol, uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[_symbol][epoch][user];
        Round memory round = rounds[_symbol][epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
        round.oracleCalled &&
        betInfo.amount != 0 &&
        !betInfo.claimed &&
        ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
        (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    function mineable(string memory _symbol, uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[_symbol][epoch][user];
        Round memory round = rounds[_symbol][epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
        round.oracleCalled &&
        betInfo.amount != 0 &&
        !betInfo.miningRewards &&
        ((round.closePrice < round.lockPrice && betInfo.position == Position.Bull) ||
        (round.closePrice > round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(string memory _symbol, uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[_symbol][epoch][user];
        Round memory round = rounds[_symbol][epoch];
        return
        !round.oracleCalled &&
        !betInfo.claimed &&
        block.timestamp > round.closeTimestamp + bufferSeconds[_symbol] &&
        betInfo.amount != 0;
    }


    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(string memory _symbol, uint256 epoch) internal {
        _calculateRewardsRequire(_symbol,epoch);
        Round storage round = rounds[_symbol][epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        // Bull wins
        if (round.closePrice > round.lockPrice && round.bullAmount > 0) {
            rewardBaseCalAmount = round.bullAmount;
            treasuryAmt = (round.totalAmount * treasuryFee) / 10000;
            rewardAmount = round.totalAmount - treasuryAmt;
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice && round.bearAmount > 0) {
            rewardBaseCalAmount = round.bearAmount;
            treasuryAmt = (round.totalAmount * treasuryFee) / 10000;
            rewardAmount = round.totalAmount - treasuryAmt;
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        uint256 thePledgeToInject = 0;
        if (treasuryAmt > 0) {
            thePledgeToInject = treasuryAmt * rewardCardProportion / rewardCardAllProportion;
        }
        IPledge(PledgeContractAddress).capitalInjection{value : thePledgeToInject}();
        treasuryAmt = treasuryAmt - thePledgeToInject;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount, treasuryAmt, _symbol);
    }


    /**
     * @notice End round
     * @param epoch: epoch
     * @param roundId: roundId
     * @param price: price of the round
     */
    function _safeEndRound(
        string memory _symbol,
        uint256 epoch,
        uint256 roundId,
        int256 price
    ) internal {
        _safeEndRoundRequire(_symbol,epoch);
        Round storage round = rounds[_symbol][epoch];
        round.closePrice = price;
        round.closeOracleId = roundId;
        round.oracleCalled = true;
        emit EndRound(epoch, roundId, round.closePrice, _symbol);
    }



    /**
     * @notice Lock round
     * @param epoch: epoch
     * @param roundId: roundId
     * @param price: price of the round
     */
    function _safeLockRound(
        string memory _symbol,
        uint256 epoch,
        uint256 roundId,
        int256 price
    ) internal {
        _safeLockRoundRequire(_symbol,epoch);
        Round storage round = rounds[_symbol][epoch];
        round.closeTimestamp = block.timestamp + intervalSeconds[_symbol];
        round.lockPrice = price;
        round.lockOracleId = roundId;

        emit LockRound(epoch, roundId, round.lockPrice, _symbol);
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     */
    function _safeStartRound(string memory _symbol, uint256 epoch) internal {
        _safeStartRoundRequire(_symbol,epoch);
        _startRound(_symbol, epoch);
    }

    /**
     * @notice Transfer  in a safe way
     * @param to: address to transfer  to
     * @param value:  amount to transfer (in wei)
     */
    function _safeTransfer(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     */
    function _startRound(string memory _symbol, uint256 epoch) internal {
        Round storage round = rounds[_symbol][epoch];
        round.startTimestamp = block.timestamp;
        round.lockTimestamp = block.timestamp + intervalSeconds[_symbol];
        round.closeTimestamp = block.timestamp + (2 * intervalSeconds[_symbol]);
        round.epoch = epoch;
        round.totalAmount = 0;
        _claimTreasury();
        roundsAverageMining[_symbol][epoch] = averageMining;
        emit StartRound(epoch, _symbol);
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable(string memory _symbol, uint256 epoch) internal view returns (bool) {
        return
        rounds[_symbol][epoch].startTimestamp != 0 &&
        rounds[_symbol][epoch].lockTimestamp != 0 &&
        block.timestamp > rounds[_symbol][epoch].startTimestamp &&
        block.timestamp < rounds[_symbol][epoch].lockTimestamp;
    }

    /**
     * @notice Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid.
     */
    function _getPriceFromOracle(string memory _symbol) internal view returns (uint80, int256) {
        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
        (uint80 roundId, int256 price, , uint256 timestamp,) = AggregatorV3Interface(symbolOracle[_symbol]).latestRoundData();
        require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
        require(
            uint256(roundId) > oracleLatestRoundId[_symbol],
            "Oracle update roundId must be larger than oracleLatestRoundId"
        );
        return (roundId, price);
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _safeLockRoundRequire(string memory _symbol,uint256 epoch) internal view{
        require(rounds[_symbol][epoch].startTimestamp != 0, "Can only lock round after round has started");
        require(block.timestamp >= rounds[_symbol][epoch].lockTimestamp, "Can only lock round after lockTimestamp");
        require(
            block.timestamp <= rounds[_symbol][epoch].lockTimestamp + bufferSeconds[_symbol],
            "Can only lock round within bufferSeconds"
        );
    }

    function _calculateRewardsRequire(string memory _symbol, uint256 epoch) internal view{
        require(rounds[_symbol][epoch].rewardBaseCalAmount == 0 && rounds[_symbol][epoch].rewardAmount == 0, "Rewards calculated");
    }

    function _safeEndRoundRequire(
        string memory _symbol,
        uint256 epoch
    ) internal view{
        require(rounds[_symbol][epoch].lockTimestamp != 0, "Can only end round after round has locked");
        require(block.timestamp >= rounds[_symbol][epoch].closeTimestamp, "Can only end round after closeTimestamp");
        require(
            block.timestamp <= rounds[_symbol][epoch].closeTimestamp + bufferSeconds[_symbol],
            "Can only end round within bufferSeconds"
        );
    }

    function _safeStartRoundRequire(string memory _symbol, uint256 epoch) internal view{
        require(genesisStartOnce[_symbol], "Can only run after genesisStartRound is triggered");
        require(rounds[_symbol][epoch - 2].closeTimestamp != 0, "Can only start round after round n-2 has ended");
        require(
            block.timestamp >= rounds[_symbol][epoch - 2].closeTimestamp,
            "Can only start new round after round n-2 closeTimestamp"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}