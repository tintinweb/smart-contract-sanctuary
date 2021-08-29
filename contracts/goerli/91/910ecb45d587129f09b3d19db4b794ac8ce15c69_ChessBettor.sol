/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract ChessBettor is Ownable {
    
    using SafeMath for uint256;
    
    struct Game {
        uint gameId;
        bool gameExists;
        
        uint8 winner;
        bool isOn;
        
        uint totalAmount;
        uint amountWhite;
        uint amountBlack;
        
        uint numberBets;
        mapping(address => uint256) voteIndex;
        Vote[] voteList;
    }
    struct Vote {
        uint8 voteFor; // 0 or 1
        uint amount;
        bool claimed;
    }
    
    mapping (uint => Game) public existingGames;
    mapping(address => uint256[]) public allGamesPlayedByPlayers;
    mapping(address => uint256[]) public gamesWithUnclaimedBalancePerPlayer;
    
    uint256[] public activeGameIds;
    
    event gameCreated(uint _gameId, address _voter, uint _amount);
    event votePlaced(uint _gameId, address _voter, uint _amount, uint8 _side);
    event gameEnded(uint _gameId, uint8 winner);
    event rewardWithdraw(address _benificiary, uint _amount);
    
    function createGame(uint _gameId, uint _amount) internal {
       require(gameExists(_gameId) == false, "Game already exists");
       
       Game storage newGame = existingGames[_gameId];
       newGame.gameId = _gameId;
       newGame.gameExists = true;
       
       newGame.winner = 2;
       newGame.isOn = true;
       
       newGame.totalAmount = 0;
       newGame.amountWhite = 0;
       newGame.amountBlack = 0;
       
       newGame.numberBets = 0;
       
       activeGameIds.push(_gameId);
       emit gameCreated(_gameId, msg.sender, _amount);
    }
    
    function placeBet(uint _gameId, uint8 _vote, uint _amount) public payable {
       
       require(_amount <= msg.value, "Mismatch in sent amount");
       require(msg.value > 0, "Betting amount cannot be 0");
       require(_vote == 0 || _vote == 1, "Vote either 0 or 1");
       
       if(!gameExists(_gameId)) {
           createGame(_gameId, _amount);
       }
       
       Game storage game = existingGames[_gameId];
       require(game.voteIndex[msg.sender] == 0, "Player has already placed bet in this game");
       allGamesPlayedByPlayers[msg.sender].push(_gameId);
       gamesWithUnclaimedBalancePerPlayer[msg.sender].push(_gameId);
       
       if(_vote == 0) {
           game.amountWhite = game.amountWhite.add(_amount);
       } else {
           game.amountBlack = game.amountBlack.add(_amount);
       }
       
       game.totalAmount = game.totalAmount.add(_amount);
       game.numberBets = game.numberBets.add(1);
       
       game.voteIndex[msg.sender] = game.numberBets;
       game.voteList[game.numberBets] = Vote(_vote, _amount, false);  // Index 0 will always be empty, implying that the player has not placed bets in the current game.
       
       emit votePlaced(_gameId, msg.sender, _amount, _vote);
       
    }
    
    function endGame(uint _gameId, uint8 _winner) public onlyOwner {
       require(_winner == 0 || _winner == 1 || _winner == 2, "Invalid Winner");
       require(gameExists(_gameId), "Game does not exist");
       require(existingGames[_gameId].isOn, "Game has already ended");
       
       existingGames[_gameId].isOn = false;
       existingGames[_gameId].winner = _winner;
       
       uint index = getActiveGameIndex(_gameId);
       removeFromActiveList(index);
       
       emit gameEnded(_gameId, _winner);
    }
    
    function removeFromActiveList(uint index) internal {
        require(index < activeGameIds.length, "Invaild game index");
    
        for (uint i = index; i < activeGameIds.length - 1; i++) {
            activeGameIds[i] = activeGameIds[i + 1];
        }
        
        uint indexToDelete = activeGameIds.length - 1;
        delete activeGameIds[indexToDelete];
    }
    
    function claimRewards() external {
       (uint reward, uint256[] memory claimedGames) = calculateRewards(msg.sender);
       
       markVotesAsClaimedAndUpdateUnclaimedList(msg.sender, claimedGames);
       payable(msg.sender).transfer(reward);
       
       emit rewardWithdraw(msg.sender, reward);
    }
    
    function markVotesAsClaimedAndUpdateUnclaimedList(address _address, uint256[] memory claimedGames) internal {
        uint256 currentIndex = 0;
        uint256 max = claimedGames.length;
        uint256[] storage unclaimedGames = gamesWithUnclaimedBalancePerPlayer[_address];
        require(unclaimedGames.length >= max, "Length Mismatch Error.");
        
        for(uint256 i = 0; i < unclaimedGames.length; i++) {
            unclaimedGames[i - currentIndex] = unclaimedGames[i];
            
            if (currentIndex < max) {
                if (unclaimedGames[i] == claimedGames[currentIndex]) {
                    Game storage game = existingGames[claimedGames[currentIndex]];
                    game.voteList[game.voteIndex[_address]].claimed = true;
                    currentIndex++;
                }
            }
        }
        
        for (uint256 i = 0; i < max; i++) {
            unclaimedGames.pop();
        }
    }
    
    
    
    // -------------------- //
    // View Functions Below //
    // -------------------- //
    
    function gameExists(uint _gameId) public view returns(bool) {
        return existingGames[_gameId].gameExists;
    }
    
    function getActiveGames() public view returns(uint256[] memory) {
       uint256[] storage games = activeGameIds;
       return games;
    }
    
    function getGamesPlayedByPlayer(address _address) public view returns(uint256[] memory) {
        return allGamesPlayedByPlayers[_address];
    }
    
    function getGameDetails(uint _gameId) public view returns(uint8 winner, uint gameId, uint totalAmount, uint amountWhite, uint amountBlack, uint numberBets, bool isOn) {
       Game storage _game =  existingGames[_gameId];
       return (_game.winner, _game.gameId, _game.totalAmount, _game.amountWhite, _game.amountBlack, _game.numberBets, _game.isOn);
    }
    
    function getActiveGameIndex(uint _gameId) internal view returns(uint) {
       for(uint i = 0; i < activeGameIds.length; i++) {
           if (activeGameIds[i] == _gameId) {
               return i;
           }
       }
       
       return ~uint256(0);
    }
    
    function calculateRewards(address _address) public view returns(uint claimableReward, uint256[] memory gamesWithUnclaimedRewards) {
       uint reward = 0;
       uint gameReward = 0.5 ether; // TODO : Change this.
       
        // Get all the gameIds in which player has participated.
       uint256[] storage unclaimedGameIds = gamesWithUnclaimedBalancePerPlayer[_address];
       uint256[] memory removableGames;
       uint256 index = 0;
       
        // loop through all the votes, if he has won in that game then add to his balance the reward, otherwise reward = 0 
       for(uint i = 0; i < unclaimedGameIds.length; i++) {
            Game storage game = existingGames[unclaimedGameIds[i]];
            if(!game.isOn) {
                Vote storage vote = game.voteList[game.voteIndex[_address]];
                if(!vote.claimed) {
                    removableGames[index] = unclaimedGameIds[i];
                    index++;
                    
                    if(game.winner == 2) {
                        reward = reward.add(vote.amount);
                    } else if(vote.voteFor == game.winner) {
                        reward = reward.add(gameReward);
                    }
                }
            }
        }
        
        return (reward, removableGames);
    }
}