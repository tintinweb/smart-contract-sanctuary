/**
 *Submitted for verification at polygonscan.com on 2021-11-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    function renounceOwnership() public virtual onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner() {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract ChessBettor is Ownable {

    using SafeMath for uint256;

    // 0 => No Explicit Winner
    // 1 => Black
    // 2 => White
    struct Vote {
        uint8 voteFor;
        uint256 amount;
        uint256 voteTimestamp;
        bool claimed;
    }

    struct Game {
        string gameId;
        bool gameExists;

        uint8 winner;
        uint256 gameEndTimestamp;
        bool isOn;

        uint256 totalAmount;
        uint256 amountWhite;
        uint256 amountBlack;

        uint256 numberBets;
        uint256 whiteBets;
        uint256 blackBets;

        mapping(address => uint256) voteIndex;
        address[] bettors;
        Vote[] voteList;
    }

    struct UserData {
        uint256 totalGames;
        uint256 wins;       // Only takes claimed games into consideration
        uint256 draws;      // Only takes claimed games into consideration
        uint256 losses;     // Only takes claimed games into consideration
        uint256 undetermined;

        string[] allGamesPlayed;
        string[] gamesWithUnclaimedBalance;
    }

    struct ReturnableGameData {
        string gameId;

        uint8 winner;
        uint256 gameEndTimestamp;
        bool isOn;

        uint256 totalAmount;
        uint256 amountWhite;
        uint256 amountBlack;

        uint256 numberBets;
        uint256 whiteBets;
        uint256 blackBets;
    }

    struct ReturnableGameSpecificUserData {
        ReturnableGameData gameData;
        Vote voteData;
        int8 result;
    }

    struct ReturnableUserData {
        uint256 totalGames;
        uint256 wins;
        uint256 draws;
        uint256 losses;
        uint256 undetermined;
        uint256 claimableRewardAmount;

        ReturnableGameSpecificUserData[] allGameData;
    }

    uint256 public minBetAmount = 0.001 ether;

    string[] private activeGameIds;
    string[] private existingGameIds;
    mapping(string => Game) private existingGames;
    mapping(address => UserData) private allPlayerData;

    uint256 public feePercent = 0;
    uint256 public totalFeeGenerated = 0;
    uint256 public remainingFeeBalance = 0;

    event gameCreated(string _gameId, address _voter, uint256 _amount);
    event votePlaced(string _gameId, address _voter, uint256 _amount, uint8 _side);
    event gameEnded(string _gameId, uint8 winner);
    event rewardWithdraw(address _benificiary, uint256 _amount);

    function createGame(string memory _gameId, uint256 _amount) internal {
        Game storage newGame = existingGames[_gameId];
        newGame.gameId = _gameId;
        newGame.gameExists = true;
        newGame.isOn = true;
        newGame.winner = 0;
        newGame.gameEndTimestamp = 0;

        newGame.totalAmount = 0;
        newGame.amountWhite = 0;
        newGame.amountBlack = 0;

        newGame.numberBets = 0;
        newGame.whiteBets = 0;
        newGame.blackBets = 0;

        if (newGame.winner == 3) {
            uint256 len = newGame.bettors.length;
            if (len > 0) {
                for (uint256 i = len - 1; (i >= 0); i--) {
                    newGame.voteIndex[newGame.bettors[i]] = 1;
                    newGame.bettors.pop();
                    newGame.voteList.pop();
                }
            }
        } else {
            newGame.voteList.push(Vote(0, 0, block.timestamp, true));  // This implies that player has not placed bet yet.
            newGame.voteList.push(Vote(0, 0, block.timestamp, true));  // This implies that player placed bet on a invalid game Id.
            existingGameIds.push(_gameId);
        }

        activeGameIds.push(_gameId);
        emit gameCreated(_gameId, msg.sender, _amount);
    }

    function placeBet(string memory _gameId, uint8 _vote, uint256 _amount) public payable {
        require(_amount <= msg.value, "Mismatch in sent amount");
        require(msg.value >= minBetAmount, "Betting amount cannot be less than minBetAmount");
        require(_vote == 1 || _vote == 2, "Vote can be either 1 or 2 only");

        if (gameExists(_gameId) && existingGames[_gameId].winner != 3) {
            require(existingGames[_gameId].isOn, "Cannot place bet on a game that has already ended...");
        } else {
            createGame(_gameId, _amount);
        }

        Game storage game = existingGames[_gameId];
        require(game.voteIndex[msg.sender] == 0, "Player has already placed bet in this game");

        allPlayerData[msg.sender].totalGames = allPlayerData[msg.sender].totalGames.add(1);
        allPlayerData[msg.sender].undetermined = allPlayerData[msg.sender].undetermined.add(1);
        allPlayerData[msg.sender].allGamesPlayed.push(_gameId);
        allPlayerData[msg.sender].gamesWithUnclaimedBalance.push(_gameId);

        if (_vote == 1) {
            game.amountBlack = game.amountBlack.add(_amount);
            game.blackBets += 1;
        } else {
            game.amountWhite = game.amountWhite.add(_amount);
            game.whiteBets += 1;
        }

        game.totalAmount = game.totalAmount.add(_amount);
        game.numberBets = game.numberBets.add(1);

        game.voteIndex[msg.sender] = game.numberBets + 1;
        game.voteList.push(Vote(_vote, _amount, block.timestamp, false));

        emit votePlaced(_gameId, msg.sender, _amount, _vote);
    }

    function endGame(string memory _gameId, uint8 _winner, uint256 _gameEndTimestamp) public onlyOwner() {
        require(_winner == 0 || _winner == 1 || _winner == 2 || _winner == 3, "Invalid Winner");
        require(gameExists(_gameId), "Game does not exist");
        require(existingGames[_gameId].isOn, "Game has already ended");

        existingGames[_gameId].isOn = false;
        existingGames[_gameId].winner = _winner;
        existingGames[_gameId].gameEndTimestamp = _gameEndTimestamp;
        
        uint256 offsetAmount = 0;
        uint256 checkAmount = 0;
        
        if (_winner == 1) {
            (, offsetAmount, checkAmount) = discardInvalidVotes(existingGames[_gameId]);
        } else if (_winner == 2) {
            (, checkAmount, offsetAmount) = discardInvalidVotes(existingGames[_gameId]);
        }
        
        if (checkAmount == 0 && offsetAmount > 0) {
            remainingFeeBalance += offsetAmount;
        }

        uint256 index = getActiveGameIndex(_gameId);
        removeFromActiveList(index);

        emit gameEnded(_gameId, _winner);
    }

    function claimRewards() external {

        (uint256 reward, uint256 fees, string[] memory claimedGames, int8[] memory results) = calculateRewards(msg.sender);

        updateAllClaimedVotesAndListOfUnclaimedVotes(msg.sender, claimedGames, results);
        totalFeeGenerated = totalFeeGenerated.add(fees);
        remainingFeeBalance = remainingFeeBalance.add(fees);
        payable(msg.sender).transfer(reward);

        emit rewardWithdraw(msg.sender, reward);
    }

    function removeFromActiveList(uint256 index) internal {
        require(index < activeGameIds.length, "Invalid game index");

        for (uint i = index; i < activeGameIds.length - 1; i++) {
            activeGameIds[i] = activeGameIds[i + 1];
        }

        activeGameIds.pop();
    }

    function updateAllClaimedVotesAndListOfUnclaimedVotes(address _address, string[] memory toBeClaimedGames, int8[] memory results) internal {
        require(toBeClaimedGames.length == results.length, "Length Mismatch Error");

        uint256 currentIndex = 0;
        uint256 max = toBeClaimedGames.length;
        string[] storage unclaimedGames = allPlayerData[_address].gamesWithUnclaimedBalance;
        UserData storage userData = allPlayerData[_address];

        require(unclaimedGames.length >= max, "Length Shortage Error");

        for (uint256 i = 0; i < unclaimedGames.length; i++) {
            unclaimedGames[i - currentIndex] = unclaimedGames[i];

            if ((currentIndex < max) && (areStringsEqual(unclaimedGames[i], toBeClaimedGames[currentIndex]))) {
                Game storage game = existingGames[toBeClaimedGames[currentIndex]];
                game.voteList[game.voteIndex[_address]].claimed = true;

                userData.undetermined = userData.undetermined.sub(1);
                if (results[currentIndex] == 0 || results[currentIndex] == -2) {
                    userData.draws = userData.draws.add(1);
                } else if (results[currentIndex] == 1) {
                    userData.wins = userData.wins.add(1);
                } else if (results[currentIndex] == - 1) {
                    userData.losses = userData.losses.add(1);
                }

                currentIndex++;
            }
        }

        for (uint256 i = 0; i < max; i++) {
            unclaimedGames.pop();
        }
    }

    function setMinBetAmount(uint256 amount) external onlyOwner() {
        require(amount > 0, "minBetAmount has to be greater than 0");
        minBetAmount = amount;
    }

    function setFeePercent(uint256 _feePercent) external onlyOwner() {
        require(_feePercent <= 100, "Fee percent cannot be greater than 100");
        feePercent = _feePercent;
    }

    function withdrawFees(uint256 amount, address payable to) external onlyOwner() {
        require(amount <= remainingFeeBalance, "Cannot withdraw more than remainingFeeBalance");
        to.transfer(amount);
        remainingFeeBalance = remainingFeeBalance.sub(amount);
    }



    // ----------------------------- //
    // Internal View Functions Below //
    // ----------------------------- //

    function areStringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function getActiveGameIndex(string memory _gameId) internal view returns (uint) {
        for (uint i = 0; i < activeGameIds.length; i++) {
            if (areStringsEqual(activeGameIds[i], _gameId)) {
                return i;
            }
        }

        return ~uint256(0);
    }

    function getCountOfClaimableGamesForAddress(address _address, string[] storage unclaimedGameIds) internal view returns (uint256) {
        uint256 count = 0;

        for (uint i = 0; i < unclaimedGameIds.length; i++) {
            Game storage game = existingGames[unclaimedGameIds[i]];
            Vote storage vote = game.voteList[game.voteIndex[_address]];

            if (!game.isOn || vote.claimed) {
                count++;
            }
        }

        return count;
    }

    function discardInvalidVotes(Game storage game) internal view returns (uint256, uint256, uint256) {
        uint256 totalAmount = 0;
        uint256 amountBlack = 0;
        uint256 amountWhite = 0;

        Vote[] storage voteList = game.voteList;

        for (uint256 i = 1; i < voteList.length; i++) {
            Vote storage vote = voteList[i];

            if (vote.voteTimestamp > game.gameEndTimestamp) {
                continue;
            } else if (vote.voteFor == 2) {
                totalAmount = totalAmount.add(vote.amount);
                amountWhite = amountWhite.add(vote.amount);
            } else if (vote.voteFor == 1) {
                totalAmount = totalAmount.add(vote.amount);
                amountBlack = amountBlack.add(vote.amount);
            }
        }

        return (totalAmount, amountWhite, amountBlack);
    }

    function getRewardAmountForPlayerForGame(Vote storage vote, Game storage game) internal view returns (uint256) {
        require(vote.voteFor == game.winner, "Voter has to be winner to calculate rewards");

        (uint256 totalAmount,uint256 amountWhite,uint256 amountBlack) = discardInvalidVotes(game);

        uint256 numerator = vote.amount.mul(totalAmount);
        uint256 denominator = (game.winner == 1) ? amountBlack : amountWhite;

        return numerator.div(denominator);
    }

    function formatData(address _address, string[] memory gameList, bool modifyWinsAndLosses) internal view returns (ReturnableUserData memory fullPlayerData) {
        uint256 maxIndex = gameList.length;

        fullPlayerData.totalGames = allPlayerData[_address].totalGames;
        fullPlayerData.wins = allPlayerData[_address].wins;
        fullPlayerData.draws = allPlayerData[_address].draws;
        fullPlayerData.losses = allPlayerData[_address].losses;
        fullPlayerData.undetermined = allPlayerData[_address].undetermined;
        (fullPlayerData.claimableRewardAmount,,,) = calculateRewards(_address);

        fullPlayerData.allGameData = new ReturnableGameSpecificUserData[](maxIndex);

        for (uint256 i = 0; i < maxIndex; i++) {
            string memory gameId = gameList[i];
            (ReturnableGameData memory returnableGameData,) = getGameDetails(gameId);

            Game storage game = existingGames[gameId];
            Vote storage vote = game.voteList[game.voteIndex[_address]];
            int8 result;

            if (game.isOn) {
                result = - 2;
            } else if (vote.voteTimestamp > game.gameEndTimestamp || game.winner == 0 || game.winner == 3 || game.voteIndex[_address] == 1) {
                result = 0;
                if (modifyWinsAndLosses && !vote.claimed) {
                    fullPlayerData.draws += 1;
                }
            } else if (vote.voteFor == game.winner) {
                result = 1;
                if (modifyWinsAndLosses && !vote.claimed) {
                    fullPlayerData.wins += 1;
                }
            } else {
                result = - 1;
                if (modifyWinsAndLosses && !vote.claimed) {
                    fullPlayerData.losses += 1;
                }
            }

            fullPlayerData.allGameData[i] = ReturnableGameSpecificUserData(returnableGameData, Vote(vote.voteFor, vote.amount, vote.voteTimestamp, vote.claimed), result);
        }

        return fullPlayerData;
    }



    // ----------------------------- //
    //  Public View Functions Below  //
    // ----------------------------- //

    function gameExists(string memory _gameId) public view returns (bool) {
        return existingGames[_gameId].gameExists;
    }

    function getGameDetails(string memory _gameId) public view returns (ReturnableGameData memory, Vote[] memory) {
        Game storage _game = existingGames[_gameId];

        ReturnableGameData memory returnableGameData = ReturnableGameData(
            _game.gameId,
            _game.winner,
            _game.gameEndTimestamp,
            _game.isOn,
            _game.totalAmount,
            _game.amountWhite,
            _game.amountBlack,
            _game.numberBets,
            _game.whiteBets,
            _game.blackBets
        );
        require(_game.gameExists, "No game exists for the given game id.");

        return (returnableGameData, _game.voteList);
    }

    function calculateRewards(address _address) public view returns (uint256 claimableReward, uint256 fees, string[] memory gamesHavingClaimableRewards, int8[] memory results) {
        uint reward = 0;
        uint256 index = 0;
        string[] storage unclaimedGameIds = allPlayerData[_address].gamesWithUnclaimedBalance;

        // Get all the gameIds in which player has participated.
        uint256 size = getCountOfClaimableGamesForAddress(_address, unclaimedGameIds);
        string[] memory removableGames = new string[](size);
        results = new int8[](size);

        // loop through all the votes, if he has won in that game then add to his balance the reward, otherwise reward = 0
        for (uint i = 0; i < unclaimedGameIds.length; i++) {
            Game storage game = existingGames[unclaimedGameIds[i]];
            Vote storage vote = game.voteList[game.voteIndex[_address]];

            if (!game.isOn || vote.claimed) {
                removableGames[index] = unclaimedGameIds[i];

                if (vote.claimed || game.winner == 3) {
                    results[index] = - 2;
                } else if (vote.voteTimestamp > game.gameEndTimestamp || game.winner == 0) {
                    reward = reward.add(vote.amount);
                    results[index] = 0;
                } else if (vote.voteFor == game.winner) {
                    reward = reward.add(getRewardAmountForPlayerForGame(vote, game));
                    results[index] = 1;
                } else {
                    results[index] = - 1;
                }

                index++;
            }
        }

        fees = (reward.mul(feePercent)).div(100);
        reward = reward.sub(fees);

        return (reward, fees, removableGames, results);
    }



    // ----------------------------- //
    // External View Functions Below //
    // ----------------------------- //

    function getActiveGames() external view returns (string[] memory) {
        return activeGameIds;
    }

    function getBulkGameDetails(string[] memory gameIdList) external view returns (ReturnableGameData[] memory returnList) {
        uint256 len = gameIdList.length;
        returnList = new ReturnableGameData[](len);

        for (uint256 i = 0; i < len; i++) {
            (returnList[i],) = getGameDetails(gameIdList[i]);
        }

        return returnList;
    }

    function getAllGamesCreatedTillDate() external view returns (string[] memory) {
        return existingGameIds;
    }

    function getGamesPlayedByPlayer(address _address) external view returns (string[] memory) {
        return allPlayerData[_address].allGamesPlayed;
    }

    function getPlayerStatsForUnclaimedGames(address _address, bool modifyWinsAndLosses) external view returns (ReturnableUserData memory) {
        return formatData(_address, allPlayerData[_address].gamesWithUnclaimedBalance, modifyWinsAndLosses);
    }

    function getPlayerStatsForAllGames(address _address, bool modifyWinsAndLosses) external view returns (ReturnableUserData memory) {
        return formatData(_address, allPlayerData[_address].allGamesPlayed, modifyWinsAndLosses);
    }
}