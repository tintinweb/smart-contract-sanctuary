// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './PredMarket.sol';

contract PredMarketFactory{

    address public owner;
    address public admin;

    //tokensPred + tokenStaked => market contract
    mapping(address => mapping(address => address)) public markets;

    event MarketCreated(
        address indexed tokenPred, 
        address indexed tokenStaked
        );

    event OwnerChanged(address oldOwner, address newOwner);
    event AdminChanged(address oldAdmin, address newAdmin);

    constructor(address _admin){
        owner = msg.sender;
        admin = _admin;
        emit OwnerChanged(address(0), msg.sender);
        emit AdminChanged(address(0), _admin);
    }

    function createMarket(
        string memory _name,
        address _tokenPred,
        address _tokenStaked,
        address _oracle,
        address[] memory _ownerAdminOperator,
        uint256 _lockInterval,
        uint256 _closeInterval,
        uint256 _buffer,
        uint256 _minBetAmount,
        uint256 _oracleUpdateAllowance
    )
    external
    onlyOwnerOrAdmin
    {
        require(
            markets[_tokenPred][_tokenStaked] == address(0), 
            "Already deployed"
            );
        
        PredMarket pred = new PredMarket(
            _name,
            _tokenPred,
            _tokenStaked,
            _oracle,
            _ownerAdminOperator,
            _lockInterval,
            _closeInterval,
            _buffer,
            _minBetAmount,
            _oracleUpdateAllowance
        );

        markets[_tokenPred][_tokenStaked] = address(pred);

        emit MarketCreated(_tokenPred, _tokenStaked);

    }

    function _onlyOwner() internal view{
        require(owner == msg.sender, "Only owner function");
    }

    function _onlyOwnerOrAdmin() internal view{
        require(
            owner == msg.sender ||
            admin == msg.sender,
            "Only admin or owner function"
            );
    }
    
    modifier onlyOwner{
        _onlyOwner();
        _;
    }
    
    modifier onlyOwnerOrAdmin{
        _onlyOwnerOrAdmin();
        _;
    }

    function changeOwner(address _owner) external onlyOwner{
        require(_owner != address(0), "Zero address");
        owner = _owner;
        emit OwnerChanged(msg.sender, owner);
    }

    function changeAdmin(address _admin) external onlyOwner{
        require(_admin != address(0), "Zero address");
        address oldAdmin = admin;
        admin = _admin;
        emit AdminChanged(oldAdmin, admin);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";

contract PredMarket is Pausable {
    using SafeMath for uint256;

    struct Round {
        uint256 epoch;
        uint256 startTime;
        uint256 lockTime;
        uint256 endTime;
        int256 openPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    enum Position {
        Bull,
        Bear
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    mapping(uint256 => Round) public rounds;
    //Checks if a round is bettable            
    mapping(uint256 => bool) public bettable;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;
    
    uint256 public currentEpoch;
    uint256 public lockInterval;
    uint256 public closeInterval;
    uint256 public buffer;
    address public owner;
    address public admin;
    address public operator;
    uint256 public treasuryAmount;
    AggregatorV3Interface internal oracle;
    uint256 public oracleRoundId;


    uint256 public constant TOTAL_RATE = 100; // 100%
    uint256 public rewardRate = 90; // 90%
    uint256 public treasuryRate = 10; // 10%
    uint256 public minBetAmount;
    uint256 public oracleUpdateAllowance; // seconds

    bool public genesisStartOnce = false;
    bool public genesisLockOnce = false;
    string public name;

    //Token on which prediction is performed
    address public tokenPred;
    //Token which is used for staking
    address public tokenStaked;

    event StartRound(uint256 indexed epoch, uint256 time, int256 price);
    event LockRound(uint256 indexed epoch, uint256 time);
    event EndRound(uint256 indexed epoch, uint256 time, int256 price);
    event Bet(
        Position indexed position,
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );

    event Claim(
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );
    event ClaimTreasury(uint256 amount);
    event RatesUpdated(
        uint256 indexed epoch,
        uint256 rewardRate,
        uint256 treasuryRate
    );
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );
    event Pause(uint256 epoch);
    event Unpause(uint256 epoch);
    
    constructor(
        string memory _name,
        address _tokenPred,
        address _tokenStaked,
        address _oracle,
        address[] memory _ownerAdminOperator,
        uint256 _lockInterval,
        uint256 _closeInterval,
        uint256 _buffer,
        uint256 _minBetAmount,
        uint256 _oracleUpdateAllowance
    ) {
        name = _name;
        tokenPred = _tokenPred;
        tokenStaked = _tokenStaked;
        oracle = AggregatorV3Interface(_oracle);
        owner = _ownerAdminOperator[0];
        admin = _ownerAdminOperator[1];
        operator = _ownerAdminOperator[2];
        lockInterval = _lockInterval;
        closeInterval = _closeInterval;
        buffer = _buffer;
        minBetAmount = _minBetAmount;
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }

    function _onlyOwner() private view{
        require(msg.sender == owner, "owner: wut?");
    }

    function _onlyAdmin() private view{
        require(msg.sender == admin, "admin: wut?");
    }

    function _onlyOperator() private view{
        require(msg.sender == operator, "operator: wut?");
    }

    function _notContract() private view{
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
    }

    modifier onlyOwner{
        _onlyOwner();
        _;
    }

    modifier onlyAdmin{
        _onlyAdmin();
        _;
    }

    modifier onlyOperator{
        _onlyOperator();
        _;
    }

    modifier notContract{
        _notContract();
        _;
    }

    /**
     * @dev set admin address
     * callable by owner
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    /**
     * @dev set operator address
     * callable by admin
     */
    function setOperator(address _operator) external onlyAdmin {
        require(_operator != address(0), "Cannot be zero address");
        operator = _operator;
    }

    /**
     * @dev set lock interval in seconds
     * callable by admin
     */
    function setLockInterval(uint256 _interval) external onlyAdmin {
        require(_interval <= closeInterval, "lock interval must be <= close interval");
        lockInterval = _interval;
    }

      /**
     * @dev set close interval in seconds
     * callable by admin
     */
    function setCloseInterval(uint256 _interval) external onlyAdmin {
        require(_interval >= lockInterval, "Close interval must be >= lock interval");
        closeInterval = _interval;
    }


    /**
     * @dev set buffer in seconds
     * callable by admin
     */
    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= lockInterval, "Cannot be more than interval");
        buffer = _buffer;
    }

    /**
     * @dev set Oracle address
     * callable by admin
     */
    function setOracle(address _oracle) external onlyAdmin {
        require(_oracle != address(0), "Cannot be zero address");
        oracle = AggregatorV3Interface(_oracle);
    }

    /**
     * @dev set oracle update allowance
     * callable by admin
     */
    function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance)
        external
        onlyAdmin
    {
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }

    /**
     * @dev set reward rate
     * callable by admin
     */
    function setRewardRate(uint256 _rewardRate) external onlyAdmin {
        require(
            _rewardRate <= TOTAL_RATE,
            "rewardRate cannot be > 100%"
        );
        rewardRate = _rewardRate;
        treasuryRate = TOTAL_RATE.sub(_rewardRate);

        emit RatesUpdated(currentEpoch, rewardRate, treasuryRate);
    }

    /**
     * @dev set minBetAmount
     * callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        minBetAmount = _minBetAmount;

        emit MinBetAmountUpdated(currentEpoch, minBetAmount);
    }

    /**
     * @dev Start genesis round
     */
    function genesisStartRound() external onlyOperator whenNotPaused {
        require(!genesisStartOnce, "Can only run once");
        int256 currentPrice = _getPriceFromOracle();
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch, currentPrice);
        genesisStartOnce = true;
    }

    /**
     * @dev Lock genesis round
     */
    function genesisLockRound() external onlyOperator whenNotPaused {
        require(
            genesisStartOnce,
            "Can only run after genesisStartRound is triggered"
        );
        require(!genesisLockOnce, "Can only run once");
        require(
            block.timestamp <= rounds[currentEpoch].lockTime.add(buffer),
            "Can only lock round within buffer"
        );

        int256 currentPrice = _getPriceFromOracle();
        _safeLockRound(currentEpoch);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch, currentPrice);
        genesisLockOnce = true;
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function executeRound() external onlyOperator whenNotPaused {
        require(
            genesisStartOnce && genesisLockOnce,
            "Can only run after genesis rounds"
        );

        int256 currentPrice = _getPriceFromOracle();
        // CurrentEpoch refers to previous round (n-1)
        _safeLockRound(currentEpoch);
        _safeEndRound(currentEpoch - 1, currentPrice);
        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch, currentPrice);
    }

    /**
     * @dev Bet bear position
     */
    function betBear(uint256 _amount) external whenNotPaused notContract {

        require(bettable[currentEpoch], "Round not bettable");
        
        require(
            ledger[currentEpoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        require(
            _amount >= minBetAmount,
            "_amount < minBetAmount"
        );

        require(
            IERC20(tokenStaked).transferFrom(msg.sender, address(this), _amount),
            "Failure in token transfer"
        );

        uint256 amount = _amount;

        // Update round data
        Round storage round = rounds[currentEpoch];
        round.totalAmount = round.totalAmount.add(amount);
        round.bearAmount = round.bearAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[msg.sender].push(currentEpoch);

        emit Bet(Position.Bear, msg.sender, currentEpoch, amount);
    }

    /**
     * @dev Bet bull position
     */
    function betBull(uint256 _amount) external whenNotPaused notContract {

        require(bettable[currentEpoch], "Round not bettable");
        
        require(
            ledger[currentEpoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        require(
            _amount >= minBetAmount,
            "_amount < minBetAmount"
        );

        require(
            IERC20(tokenStaked).transferFrom(msg.sender, address(this), _amount),
            "Failure in token transfer"
        );

        uint256 amount = _amount;

        // Update round data
        Round storage round = rounds[currentEpoch];
        round.totalAmount = round.totalAmount.add(amount);
        round.bullAmount = round.bullAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[msg.sender].push(currentEpoch);

        emit Bet(Position.Bull, msg.sender, currentEpoch, amount);
    }

    function claim(uint256 epoch) external notContract {
        require(rounds[epoch].startTime != 0, "Round not started");
        require(block.timestamp > rounds[epoch].endTime, "Round not ended");
        require(!ledger[epoch][msg.sender].claimed, "Rewards claimed");

        uint256 reward;
        // Round valid, claim rewards
        if (rounds[epoch].oracleCalled) {
            require(claimable(epoch, msg.sender), "Not eligible for claim");
            Round memory round = rounds[epoch];
            reward = ledger[epoch][msg.sender]
            .amount
            .mul(round.rewardAmount)
            .div(round.rewardBaseCalAmount);
        }
        // Round invalid, refund bet amount
        else {
            require(refundable(epoch, msg.sender), "Not eligible for refund");
            reward = ledger[epoch][msg.sender].amount;
        }

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.claimed = true;
        _safeTransferToken(address(msg.sender), reward);

        emit Claim(msg.sender, epoch, reward);
    }

    /**
     * @dev Claim all rewards in treasury
     * callable by admin
     */
    function claimTreasury() external onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransferToken(admin, currentTreasuryAmount);

        emit ClaimTreasury(currentTreasuryAmount);
    }

    /**
     * @dev Return round epochs that a user has participated
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
        }

        return (values, cursor + length);
    }

    /**
     * @dev called by the admin to pause, triggers stopped state
     */
    function pause() public onlyAdmin whenNotPaused {
        _pause();

        emit Pause(currentEpoch);
    }

    /**
     * @dev called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() public onlyAdmin whenPaused {
        genesisStartOnce = false;
        genesisLockOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        if (round.openPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled &&
            ((round.closePrice > round.openPrice &&
                betInfo.position == Position.Bull) ||
                (round.closePrice < round.openPrice &&
                    betInfo.position == Position.Bear));
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(uint256 epoch, address user)
        public
        view
        returns (bool)
    {
        return
            !rounds[epoch].oracleCalled &&
            block.timestamp > rounds[epoch].endTime.add(buffer) &&
            ledger[epoch][user].amount != 0;
    }

    /**
     * @dev Start round
     * Previous round n-2 must end
     */
    function _safeStartRound(uint256 epoch, int256 price) internal {
        require(
            genesisStartOnce,
            "genesisStartRound not triggered"
        );
        require(
            rounds[epoch - 2].endTime != 0,
            "Round n-2 not ended"
        );
        require(
            block.timestamp >= rounds[epoch - 2].endTime,
            "Round n-2 endTime not reached"
        );
        _startRound(epoch, price);
    }

    function _startRound(uint256 epoch, int256 price) internal {
        Round storage round = rounds[epoch];
        round.startTime = block.timestamp;
        round.lockTime = block.timestamp.add(lockInterval);
        round.endTime = block.timestamp.add(closeInterval);
        round.epoch = epoch;
        round.totalAmount = 0;
        round.openPrice = price;
        bettable[epoch] = true;

        emit StartRound(epoch, block.timestamp, price);
    }

    /**
     * @dev Lock round
     */
    function _safeLockRound(uint256 epoch) internal {
        require(
            rounds[epoch].startTime != 0,
            "Round not started"
        );
        require(
            block.timestamp >= rounds[epoch].lockTime &&
            block.timestamp <= rounds[epoch].lockTime.add(buffer),
            "Can only lock between lockTime & buffer"
        );

        _lockRound(epoch);
    }

    function _lockRound(uint256 epoch) internal{
        bettable[epoch] = false;
        emit LockRound(epoch, block.timestamp);
    }

    /**
     * @dev End round
     */
    function _safeEndRound(uint256 epoch, int256 price) internal {
        require(
            rounds[epoch].lockTime != 0,
            "round doesn't exist"
        );
        require(
            block.timestamp >= rounds[epoch].endTime &&
            block.timestamp <= rounds[epoch].endTime.add(buffer),
            "Can only end between endTime & buffer"
        );

        _endRound(epoch, price);
    }

    function _endRound(uint256 epoch, int256 price) internal {
        Round storage round = rounds[epoch];
        round.closePrice = price;
        round.oracleCalled = true;

        emit EndRound(epoch, block.timestamp, round.closePrice);
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(uint256 epoch) internal {
        require(
            rewardRate.add(treasuryRate) == TOTAL_RATE,
            "rewardRate+treasuryRate != 100"
        );
        require(
            rounds[epoch].rewardBaseCalAmount == 0 &&
            rounds[epoch].rewardAmount == 0,
            "Rewards calculated"
        );
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;
        // Bull wins
        if (round.closePrice > round.openPrice) {
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = round.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        // Bear wins
        else if (round.closePrice < round.openPrice) {
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = round.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount = treasuryAmount.add(treasuryAmt);

        emit RewardsCalculated(
            epoch,
            rewardBaseCalAmount,
            rewardAmount,
            treasuryAmt
        );
    }

    /**
     * @dev Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid
     */
    function _getPriceFromOracle() internal returns (int256) {
        uint256 allowedTime = block.timestamp.add(
            oracleUpdateAllowance
        );
        (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle
        .latestRoundData();
        require(
            timestamp <= allowedTime,
            "Oracle update exceeded max allowance"
        );
        require(
            roundId >= oracleRoundId,
            "Oracle update roundId < old id"
        );
        oracleRoundId = uint256(roundId);
        return price;
    }

    function _safeTransferToken(address to, uint256 value) internal {
        bool success = IERC20(tokenStaked).transfer(to, value);
        require(success, "Failure in token transfer");    
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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