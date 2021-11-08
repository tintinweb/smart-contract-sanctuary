// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

//import "BetTypes.sol";
//import "Ownable.sol";
import "IGamblePool.sol";
import "IFund.sol";

contract FundHolders01 is IFund {

    struct UserInfo {
        uint256 accumulatedUserPoints;  // represent user's accruedPoints
        uint256 lastUpdatedAtBlock;     // last block when user's state has changed
        uint256 lastBalance;            // subj
        uint256 claimed;                // claimed reward amount
    }

    struct RewardEpoch {
        uint256 rewardAmount;
        uint256 rewardClaimed;
        uint256 closedAtBlock;
        uint256 accumulatedTotalPoints;
        uint256 totalStakedAtEpochClose; // TODO think anout remove
    }
    
    uint256 constant public SCALE = 1e18;
    uint256 immutable public fundStartBlock; 

    bool public registeredInPool;
    uint256 public currentEpoch;
    uint256 public rewardForCurrentEpoch;

    IGamblePool public  gamblePool;

    mapping(address => UserInfo[]) public usersReward;
    RewardEpoch[] internal rewardEpochs;

    event UserRewardUpdated(address indexed pool, address indexed user, uint256 currentEpoch, uint256 newBalance);
    event UserRewardClaimed(address indexed pool, address indexed user, uint256 epoch, uint256 reward);
    event NewEpoch(uint256 closedEpoch, uint256 closedEpochReward);
    
    constructor () {
            fundStartBlock = block.number;
            rewardEpochs.push();
    }

    modifier onlyFund() {
      require(msg.sender == address(gamblePool));
      _;
    }

    function registerFund() external override returns (bool) {
        require(!registeredInPool, "Already registered");
        gamblePool = IGamblePool(msg.sender);
        registeredInPool = true;
        return registeredInPool;
    }

    function joinFund(address _user) external override returns (bool) {
        return true;
    }

    ///  Claim from last available 
    function claimReward(address _user) external override onlyFund 
        returns 
    (uint256 userRewardAmount) 
    {
        if (currentEpoch > 0) {
            return claimRewardForEpoch(_user, currentEpoch - 1);
        } else {
            return 0;
        }    
    }

    function claimRewardForEpoch(address _user, uint256 _epoch) 
        public 
        override 
        onlyFund 
        returns 
    (uint256 userRewardAmount)
    {
        require(_epoch < currentEpoch, "Cant claim from currentEpoch");
        require(usersReward[_user][_epoch].claimed == 0, "Epoch already claimed");
       
        // calc reward
        userRewardAmount = _getUserRewardInEpoch(_user, _epoch);
        usersReward[_user][_epoch].claimed = userRewardAmount;
        rewardEpochs[_epoch].rewardClaimed += userRewardAmount;
        emit UserRewardClaimed(address(this), _user, _epoch, userRewardAmount);
        return userRewardAmount;
    }

    function newReward(uint256 _amount) external override onlyFund returns (bool) {
        rewardForCurrentEpoch += _amount;
        return true;
    }

    function updateUserState(address _user) external override onlyFund {
        uint256 newBalance = gamblePool.getUserBalance(_user);
        // check that this user already have array record for current epoch
        // we use cycle for case when user have no state updates during many epochs
        uint256 userEpCount = getUserEpochCount(_user);
        if (userEpCount <= currentEpoch ) {
            // THIS CASE when user have no state records about some past epoch
            UserInfo memory ui = getUserLastEpoch(_user); // get last epoch record
            for (uint256 i = userEpCount; usersReward[_user].length <= currentEpoch; i ++){
                usersReward[_user].push(); // create  unexisting epoch  record
                if (i <= currentEpoch) {
                    // populate new added records with values from last user existing epoch 
                    // except current epoch
                    usersReward[_user][i].accumulatedUserPoints = ui.accumulatedUserPoints;
                    usersReward[_user][i].lastUpdatedAtBlock = ui.lastUpdatedAtBlock;
                    usersReward[_user][i].lastBalance = ui.lastBalance; 
                }
            }
        }
        UserInfo storage currEp = usersReward[_user][currentEpoch];
        
        // Lets define balance decrement for case withdraw (or make bet)
        uint256 decrement;
        if  (newBalance < currEp.lastBalance) {
            decrement = currEp.lastBalance - newBalance;
        }

        uint256 pointsIncrement;
        // initial state change in current epoch
        if (currEp.lastBalance == 0) {
            currEp.lastUpdatedAtBlock = block.number + 1; //assume that user cant claim in currentblock
            pointsIncrement = newBalance 
                * 1 // how long last balance exist
                * SCALE
                / gamblePool.totalStaked();                  // subj
        } else {
            // main accrue points logic
            pointsIncrement = currEp.lastBalance 
                * (block.number - currEp.lastUpdatedAtBlock) // how long last balance exist
                * SCALE
                / gamblePool.totalStaked() + decrement;      // subj
            currEp.lastUpdatedAtBlock = block.number;
        }
        currEp.lastBalance = newBalance;
        currEp.accumulatedUserPoints += pointsIncrement;
        rewardEpochs[currentEpoch].accumulatedTotalPoints += pointsIncrement;
        emit UserRewardUpdated(address(this), _user, currentEpoch, newBalance);
    
    }

    /// Close current epoch and make it available for reward claim
    function closeCurrentEpoch() external  {
        // TODO  maybe need restrict users who can call this
        // for example only pool owner-  check befor production
        uint256 accTotalP = rewardEpochs[currentEpoch].accumulatedTotalPoints;
        rewardEpochs[currentEpoch].closedAtBlock = block.number;
        rewardEpochs[currentEpoch].rewardAmount = rewardForCurrentEpoch;
        rewardEpochs[currentEpoch].totalStakedAtEpochClose = gamblePool.totalStaked();
        emit NewEpoch(currentEpoch, rewardForCurrentEpoch);
        rewardForCurrentEpoch = 0;
        rewardEpochs.push();
        currentEpoch = rewardEpochs.length - 1;
        rewardEpochs[currentEpoch].accumulatedTotalPoints = accTotalP;
    }

    function getAvailableReward(address _user) external view override returns (uint256) {
        if (currentEpoch == 0) {
            return 0;
        }
        return _getUserRewardInEpoch(_user, currentEpoch - 1);
    }

    function getAvailableReward(address _user, uint256 _epoch) external view override returns (uint256) {
        if (currentEpoch == 0) {
            return 0;
        }
        return _getUserRewardInEpoch(_user, _epoch);
    }

    function getUser(address _user) external view returns (UserInfo[] memory user) {
        user = usersReward[_user];
        return user;
    }

    function getUserLastEpoch(address _user) public view returns (UserInfo memory user) {
        if (usersReward[_user].length == 0) {
           user = UserInfo(0,0,0,0);
        }  else {
           user = usersReward[_user][usersReward[_user].length -1];    
        }
        return user;
    }

    function getUserEpochCount(address _user) public view returns (uint256) {
        return usersReward[_user].length;
    }

    function getRewardEpoch(uint256 _index) external view returns (RewardEpoch memory rewardEpoch) {
        rewardEpoch = rewardEpochs[_index];
        return rewardEpoch;    
    }
     
    function getRewardEpochCount() external view returns (uint256 rewardEpochCount) {
        rewardEpochCount = rewardEpochs.length;
        return rewardEpochCount;    
    } 

    function isJoined(address _user) external view override returns (bool joined) {
        return usersReward[_user].length > 0;
    } 

    ////////////////// Internals ////////////////////////// 

    /// Main reward calclogiс 
    function _getUserRewardInEpoch(address _user, uint256 _epoch) internal view returns (uint256 r) {
        if (usersReward[_user].length  <= _epoch) {
            UserInfo memory ui = getUserLastEpoch(_user);
            r = ui.accumulatedUserPoints 
                * rewardEpochs[_epoch].rewardAmount 
                / rewardEpochs[_epoch].accumulatedTotalPoints
                - ui.claimed;
        } else {

            r = usersReward[_user][_epoch].accumulatedUserPoints 
                * rewardEpochs[_epoch].rewardAmount 
                / rewardEpochs[_epoch].accumulatedTotalPoints
                - usersReward[_user][_epoch].claimed;
        }
        return r;    
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

//abstract contract GamblingTypes {

    enum EventState  {Active, Hold, Finished, Canceled}
    enum CompareSign {Equal, MoreOrEqual, LessOrEqual, More, Less, NotEqual}
    enum GameState {Active, Deprecated, Expired}
    enum BetState {Done, Canceled, Claimed}
    enum BetResult {Undefined, Win, Lose}
    enum FundState {Active, Deprecated, Closed}
    
    //Game that available in GamePool
    struct Game {
        address eventContract;
        string name;
        address rewardModelContract;
        GameState state; 

    }

    //Users bet
    struct Bet {
        address eventContract;
        uint256 eventId;
        uint8 eventOutcomeIndex;
        uint256 betAmount;
        uint256 betTimestamp;
        BetState currentState;
        BetResult result;
    }

    //This  structure will used for reflect possible game event result
    // and bets that were made on this outcome
    struct Outcome {
        CompareSign compare;
        int256 expectedValue;
        int256 weiRaised;
        uint256 betCount;
        bool isWin;
    }
    
    struct GamblingEvent {
        address creator;
        EventState state;
        uint256 expirationTime;
        uint256 orderDeadLineTime;
        string  eventAssetSymbol;
        Outcome[2] outcome;
        int256 oraclePrice;
    }

    struct EventSettle {
        uint256 fundReward;
        uint256 creatorReward;
    }

    struct Fund {
        address contractAddress;
        uint256 sharePercent; //multiplyed on 100,  e.g 1% - 100, 22% - 2200
        FundState state;
        bool needUpdateWithUserState;
    }

    struct Rewards {
        uint256 pointsPerTokenPaid;
        uint256 points;
    }
//}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGamblePool  {
    function totalStaked() external view returns(uint256);
    
    // Main acount with amount of tokens that are frozen in bets.
    // Sub Account for totalStaked
    function inBetsAmount() external view returns(uint256);  
    
    //Main acount with amount of tokens in all funds
    function fundBalance() external view returns(uint256);

    function getGamesCount() external view returns (uint256);

    function getUsersBetsCount(address _user) external view returns (uint256);

    function getUsersBetAmountByIndex(address _user, uint256 _index) 
        external 
        view 
        returns (uint256);

    function getUserBalance(address _user) external view returns(uint256);

    //function accruedPoints(address _user) external view returns(uint256 points);

    function SCALE() external view returns (uint256);

    function owner() external view returns (address);

    function withdraw(uint256 _amount) external;

    function projectToken() external view returns(address);
    function lastSettledCreator() external view returns(address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IFund {

    function registerFund() external returns (bool); 

    function joinFund(address _user) external  returns (bool);

    function claimReward(address _user) external returns (uint256);

    function claimRewardForEpoch(address _user, uint256 _epoch) external returns (uint256);

    function updateUserState(address _user) external;

    function newReward(uint256 _amount) external returns (bool);

    function isJoined(address _user) external view returns (bool);

    function getAvailableReward(address _user) external view returns (uint256);

    function getAvailableReward(address _user, uint256 _epoch) external view returns (uint256); 
}