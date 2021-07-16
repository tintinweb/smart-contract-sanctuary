/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

interface AggregatorV3Interface {

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

contract BnbPricePredictionBet is Ownable {
    using SafeMath for uint256;
    IERC20 public token;
    enum Position {Up, Down}
    struct Round {
        uint256 epoch;
        uint256 startTime;
        uint256 lockTime;
        uint256 endTime;
        int256 startPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 upAmount;
        uint256 downAmount;
        uint256 rewardBaseCalAmount;
        bool status;
        bool oracleCalled;
    }
    struct BetInfo {
        uint256 upAmount;
        uint256 downAmount;
        bool claimed; // default false
    }

    struct AddressInfo {
        uint256 val;
        bool isValue;
    }

    struct ledgerboard {
        address userAddress;
        uint256 betnum;
        uint256 won;
        uint256 lost;
        uint256 profit;
    }

    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;

    mapping(address => AddressInfo) public betAddressInfo;
    ledgerboard[] public ledgerInfo;

    uint256 public totalBetAmount;
    uint256 public currentEpoch;
    uint256 public roundTime = 60;
    uint256 public betTime = 15;
    uint256 public bufferTime = 2;
    uint256 public constant TOTAL_RATE = 100; // 100%
    uint256 public rewardRate = 96; // 96%
    uint256 public treasuryRate = 4; // 4%
    uint256 public minBetAmount = 0;

    address public adminAddress;
    uint256 public treasuryAmount;
    AggregatorV3Interface internal oracle;
    uint256 public oracleLatestRoundId;    

    bool public genesisStartOnce = false;
    bool public genesisLockOnce = false;

    event StartRound(uint256 indexed epoch, uint256 startTime, int256 price);
    event EndRound(uint256 indexed epoch, uint256 blockTime, int256 price);

    event BetUp(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event BetDown(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event Claim(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event ClaimTreasury(uint256 amount);
    event ResetRound(uint256 indexed epoch, uint256 endTime, int256 price);
    event RunRound(uint256 indexed epoch, uint256 endTime, int256 price);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    constructor(address tokenAddress) {
        oracle = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); //bsc mainnet
        token = IERC20(tokenAddress);
        adminAddress = _msgSender();
    }

    /**
     * @dev Start genesis round
     */
    function genesisStartRound() external onlyOwner {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        genesisStartOnce = true;
    }

    /**
     * @dev Start round     
     */
    function _safeStartRound() internal {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(block.timestamp >= rounds[currentEpoch].endTime, "Can only start new round after round n-1 endTime");
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
    }

    function _startRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.startTime = block.timestamp;
        round.lockTime = block.timestamp.add(betTime);
        round.endTime = block.timestamp.add(roundTime + betTime);
        round.epoch = epoch;
        ( , int256 currentPrice, , , ) = oracle.latestRoundData();
        round.startPrice = currentPrice;
        round.status = false;

        emit StartRound(epoch, block.timestamp, round.startPrice);
    }

    function getStatus() external view returns (uint256, uint256, uint256, int256, int256, bool, uint256) {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        ( , int256 price, , , ) = oracle.latestRoundData();  
        return (
                currentEpoch,
                rounds[currentEpoch].upAmount,
                rounds[currentEpoch].downAmount,
                price,
                rounds[currentEpoch].startPrice,
                rounds[currentEpoch].status,
                rounds[currentEpoch].endTime
            );
    }

    /**
     * @dev End round
     */
    function _safeEndRound() internal {
        require(block.timestamp >= rounds[currentEpoch].endTime, "Can only end round after endTime");
        ( , int256 currentPrice, , , ) = oracle.latestRoundData();
        Round storage round = rounds[currentEpoch];
        round.closePrice = currentPrice;
        round.oracleCalled = true;
        _calculateRewards(currentEpoch);

        emit EndRound(currentEpoch, block.timestamp, round.closePrice);

        _safeStartRound();
    }   

    /**
     * @dev Bet bear position
     */
    function betDown(uint256 betAmount) external {
        _checkRound();
        if(block.timestamp >= rounds[currentEpoch].endTime) {
            _safeEndRound();
        }
        
        uint256 userlastRound = 0;
        if (userRounds[msg.sender].length > 0) {
            userlastRound = userRounds[msg.sender][userRounds[msg.sender].length - 1];
        }
        if (userlastRound > 0 && userlastRound != currentEpoch && claimable(userlastRound, msg.sender)) {
            claim(userlastRound);
        }
        if (userRounds[msg.sender].length > 1) {
            userlastRound = userRounds[msg.sender][userRounds[msg.sender].length - 2];
        }
        if (userlastRound > 0 && userlastRound != currentEpoch && claimable(userlastRound, msg.sender)) {
            claim(userlastRound);
        }
        // require(_bettable(currentEpoch), "Round not bettable");
        require(betAmount >= minBetAmount, "Bet amount must be greater than minBetAmount");
        
        // require(ledger[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");

        if (betAmount != 0) {
            uint256 tempEpoch = currentEpoch;
            if(!_bettable(currentEpoch)) {
                tempEpoch = currentEpoch + 1;
            }
            token.transferFrom(msg.sender, address(this), betAmount);
            // Update round data
            uint256 amount = betAmount;
            Round storage round = rounds[tempEpoch];
            round.totalAmount = round.totalAmount.add(amount);
            round.downAmount = round.downAmount.add(amount);

            //total bet amount
            totalBetAmount = totalBetAmount.add(amount);

            ledgerboard memory tempLedgerBoard;
            if (!betAddressInfo[msg.sender].isValue) {
                betAddressInfo[msg.sender].isValue = true;
                betAddressInfo[msg.sender].val = ledgerInfo.length;
                tempLedgerBoard.userAddress = msg.sender;
                tempLedgerBoard.betnum = 1;
                tempLedgerBoard.won = 0;
                tempLedgerBoard.lost = 0;
                tempLedgerBoard.profit = 0;
                ledgerInfo.push(tempLedgerBoard);
            } else {
                tempLedgerBoard = ledgerInfo[betAddressInfo[msg.sender].val];
                tempLedgerBoard.betnum = tempLedgerBoard.betnum + 1;
                ledgerInfo[betAddressInfo[msg.sender].val] = tempLedgerBoard;
            }

            if (tempEpoch == currentEpoch && !round.status) checkRunningRound();
            // Update user data
            BetInfo storage betInfo = ledger[tempEpoch][msg.sender];
            // betInfo.position = Position.Down;
            betInfo.downAmount = betInfo.downAmount.add(amount);
            if (userRounds[msg.sender].length == 0 || userRounds[msg.sender].length > 0 && userRounds[msg.sender][userRounds[msg.sender].length - 1] != tempEpoch) {
                userRounds[msg.sender].push(tempEpoch);
            }

            emit BetDown(msg.sender, tempEpoch, amount);
        }
    }

    /**
     * @dev Bet bull position
     */
    function betUp(uint256 betAmount) external {
        _checkRound();
        if(block.timestamp >= rounds[currentEpoch].endTime) {
            _safeEndRound();
        }
        
        uint256 userlastRound = 0;
        if (userRounds[msg.sender].length > 0) {
            userlastRound = userRounds[msg.sender][userRounds[msg.sender].length - 1];
        }
        if (userlastRound > 0 && userlastRound != currentEpoch && claimable(userlastRound, msg.sender)) {
            claim(userlastRound);
        }
        if (userRounds[msg.sender].length > 1) {
            userlastRound = userRounds[msg.sender][userRounds[msg.sender].length - 2];
        }
        if (userlastRound > 0 && userlastRound != currentEpoch && claimable(userlastRound, msg.sender)) {
            claim(userlastRound);
        }
        // require(_bettable(currentEpoch), "Round not bettable");
        require(betAmount >= minBetAmount, "Bet amount must be greater than minBetAmount");
        // require(ledger[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        
        if (betAmount != 0) {
            uint256 tempEpoch = currentEpoch;
            if(!_bettable(currentEpoch)) {
                tempEpoch = currentEpoch + 1;
            }
            token.transferFrom(msg.sender, address(this), betAmount);
            // Update round data
            uint256 amount = betAmount;
            Round storage round = rounds[tempEpoch];
            round.totalAmount = round.totalAmount.add(amount);
            round.upAmount = round.upAmount.add(amount);
    
            //total bet amount
            totalBetAmount = totalBetAmount.add(amount);
    
            ledgerboard memory tempLedgerBoard;
            if (!betAddressInfo[msg.sender].isValue) {
                betAddressInfo[msg.sender].isValue = true;
                betAddressInfo[msg.sender].val = ledgerInfo.length;
                tempLedgerBoard.userAddress = msg.sender;
                tempLedgerBoard.betnum = 1;
                tempLedgerBoard.won = 0;
                tempLedgerBoard.lost = 0;
                tempLedgerBoard.profit = 0;
                ledgerInfo.push(tempLedgerBoard);
            } else {
                tempLedgerBoard = ledgerInfo[betAddressInfo[msg.sender].val];
                tempLedgerBoard.betnum = tempLedgerBoard.betnum + 1;
                ledgerInfo[betAddressInfo[msg.sender].val] = tempLedgerBoard;
            }
    
            if (tempEpoch == currentEpoch && !round.status) checkRunningRound();
            // Update user data
            BetInfo storage betInfo = ledger[tempEpoch][msg.sender];
            // betInfo.position = Position.Up;
            betInfo.upAmount = betInfo.upAmount.add(amount);
            if (userRounds[msg.sender].length == 0 || userRounds[msg.sender].length > 0 && userRounds[msg.sender][userRounds[msg.sender].length - 1] != tempEpoch) {
                userRounds[msg.sender].push(tempEpoch);
            }
    
            emit BetUp(msg.sender, tempEpoch, amount);
        }
    }
    
    function _checkRound() internal {
        Round storage round = rounds[currentEpoch];
        if((round.upAmount == 0 || round.downAmount == 0) && block.timestamp > round.lockTime) {        
            round.lockTime = block.timestamp.add(betTime);
            round.endTime = block.timestamp.add(roundTime + betTime);
            round.epoch = currentEpoch;

            emit ResetRound(currentEpoch, round.endTime, round.startPrice);
        }
    }
    
    function checkRunningRound() internal {
        Round storage round = rounds[currentEpoch];
        if(round.upAmount != 0 && round.downAmount != 0 && round.status == false) {
            round.status = true;
            round.lockTime = block.timestamp.add(betTime);
            round.endTime = block.timestamp.add(roundTime + betTime);

            emit RunRound(currentEpoch, round.endTime, round.startPrice);
        }
    }

    function stopRound() external onlyOwner {
        for(uint i = currentEpoch; i > 0; i--){
            delete rounds[i];
        }
        currentEpoch = 0;
        genesisStartOnce = false;
    }

    /**
     * @dev Claim reward
     */
    function claim(uint256 epoch) internal {
        require(rounds[epoch].startTime != 0, "Round has not started");
        require(block.timestamp > rounds[epoch].endTime, "Round has not ended");
        require(!ledger[epoch][msg.sender].claimed, "Rewards claimed");

        uint256 reward = 0;
        uint256 won = 0;
        uint256 lost = 0;
        // Round valid, claim rewards
        if (rounds[epoch].oracleCalled) {
            Round memory round = rounds[epoch];
            uint256 rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            if(rounds[epoch].closePrice > rounds[epoch].startPrice) {
                if (ledger[epoch][msg.sender].upAmount > 0) {
                    reward = ledger[epoch][msg.sender].upAmount.mul(rewardAmount).div(round.rewardBaseCalAmount);
                }
                won = ledger[epoch][msg.sender].upAmount;
                lost = ledger[epoch][msg.sender].downAmount;
            }
            else if (rounds[epoch].closePrice < rounds[epoch].startPrice) {
                if (ledger[epoch][msg.sender].downAmount > 0) {
                    reward = ledger[epoch][msg.sender].downAmount.mul(rewardAmount).div(round.rewardBaseCalAmount);
                }
                won = ledger[epoch][msg.sender].downAmount;
                lost = ledger[epoch][msg.sender].upAmount;
            }
            else {
                if (ledger[epoch][msg.sender].downAmount.add(ledger[epoch][msg.sender].upAmount) > 0) {
                    uint256 totalBet = ledger[epoch][msg.sender].downAmount.add(ledger[epoch][msg.sender].upAmount);
                    reward = totalBet.mul(rewardAmount).div(round.rewardBaseCalAmount);
                }
                won = ledger[epoch][msg.sender].downAmount.add(ledger[epoch][msg.sender].upAmount);
                lost = 0;
            }
        }
        // Round invalid, refund bet amount
        else {
            require(refundable(epoch), "Not eligible for refund");
            uint256 totalBet = ledger[epoch][msg.sender].downAmount.add(ledger[epoch][msg.sender].upAmount);
            reward = totalBet;
            won = 0;
            lost = 0;
        }

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.claimed = true;

        ledgerboard memory tempLedgerBoard = ledgerInfo[betAddressInfo[msg.sender].val];
        tempLedgerBoard.profit = tempLedgerBoard.profit + reward;
        tempLedgerBoard.won = tempLedgerBoard.won + won;
        tempLedgerBoard.lost = tempLedgerBoard.lost + lost;
        ledgerInfo[betAddressInfo[msg.sender].val] = tempLedgerBoard;
        
        if(reward > 0) {
            _safeTransferToken(address(msg.sender), reward);
            emit Claim(msg.sender, epoch, reward);
        }
    }

    /**
     * @dev Claim all rewards in treasury
     * callable by admin
     */
    function claimTreasury() public onlyOwner {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransferToken(adminAddress, currentTreasuryAmount);

        // emit ClaimTreasury(currentTreasuryAmount);
    }
    
    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        return !betInfo.claimed;
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(uint256 epoch) public view returns (bool) {
        Round memory round = rounds[epoch];
        return !round.oracleCalled && block.timestamp > round.endTime.add(bufferTime);
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(uint256 epoch) internal {
        require(rewardRate.add(treasuryRate) == TOTAL_RATE, "rewardRate and treasuryRate must add up to TOTAL_RATE");
        require(rounds[epoch].rewardBaseCalAmount == 0, "Rewards calculated");
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;

        rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);
        treasuryAmt = round.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        // Up wins
        if (round.closePrice > round.startPrice) {
            rewardBaseCalAmount = round.upAmount;
        }
        // Down wins
        else if (round.closePrice < round.startPrice) {
            rewardBaseCalAmount = round.downAmount;
        }
        // House wins
        else {
            rewardBaseCalAmount = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;

        // Add to treasury
        treasuryAmount = treasuryAmount.add(treasuryAmt);

        emit RewardsCalculated(epoch, rewardBaseCalAmount, round.totalAmount.mul(rewardRate).div(TOTAL_RATE), treasuryAmt);
    }

    /**
     * @dev Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid
     */
    function _getPriceFromOracle() internal returns (int256) {
        (uint80 roundId, int256 price, , , ) = oracle.latestRoundData();
        oracleLatestRoundId = uint256(roundId);
        return price;
    }

    function _safeTransferToken(address to, uint256 value) internal {
        token.transfer(to, value);
    }
   
    /**
     * @dev Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current time must be within startTime and endTime
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].startTime != 0 &&
            rounds[epoch].lockTime != 0 &&
            block.timestamp >= rounds[epoch].startTime &&
            block.timestamp < rounds[epoch].lockTime;
    }

    function viewLedgerAddressInfo(address _userAddress) public view returns (uint256, uint256, uint256) {
        uint256 _betnum = 0;
        uint256 _won = 0;
        uint256 _lost = 0;

        if (betAddressInfo[_userAddress].isValue) {
            ledgerboard memory tempLedgerBoard = ledgerInfo[betAddressInfo[msg.sender].val];
            _betnum = tempLedgerBoard.betnum;
            _won = tempLedgerBoard.won;
            _lost = tempLedgerBoard.lost;
        }
        return (_betnum, _won, _lost);
    }

    function viewAllLedgerInfo() public view returns(ledgerboard[] memory) {
        return ledgerInfo;
    }
}