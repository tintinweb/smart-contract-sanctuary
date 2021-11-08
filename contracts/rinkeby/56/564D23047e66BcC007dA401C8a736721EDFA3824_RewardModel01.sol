// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "BetTypes.sol";
import "Ownable.sol";

contract RewardModel01 is  Ownable {
    function getFundPercent() external view returns (uint256) {
        return 20;
    }

    function getEventCreatorPercent() external view returns (uint256) {
        return 20;
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