// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IEventDatabase {
    function events(uint256 eventId)
        external
        view
        returns (
            uint256, // id
            uint256, // startTime
            uint256, // endTime
            uint256, // eventType
            uint256, // result
            bool, // isEnded
            string memory, // description
            string memory, // teamA
            string memory // teamB
        );

    function totalEvents() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEventDatabase.sol";

contract PrivateSport is Ownable {
    enum Vote {
        A,
        B
    }

    enum Result {
        NONE,
        A,
        B,
        AB
    }

    struct Pool {
        uint256 id;
        uint256 eventId;
        uint256 aRate;
        uint256 bRate;
        uint256 balance;
        uint256 aBalance;
        uint256 bBalance;
        Result result;
        bool isEnded;
        address owner;
    }

    struct Participant {
        Vote vote;
        uint256 deposit;
        address owner;
        bool isClaimed;
    }

    struct Winner {
        Vote vote;
        uint256 deposit;
        uint256 award;
        address owner;
    }

    IERC20 private gfx_;
    IEventDatabase private eventdb_;

    Pool[] public pools;
    uint256 public totalPools;

    uint256 public creatorFee;
    uint256 public serviceFee;

    // pool id => participants
    mapping(uint256 => mapping(address => Participant)) public participants;
    // pool id => participants count
    mapping(uint256 => uint256) public totalParticipants;
    // pool id => winners
    mapping(uint256 => Winner[]) public winners;

    // owner address => event id => boolean
    mapping(address => mapping(uint256 => bool)) private creatorOwnership;

    event PoolCreated(uint256 poolId, uint256 eventId, address owner);
    event PoolRateUpdated(
        uint256 poolId,
        uint256 aRate,
        uint256 bRate,
        uint256 aBalance,
        uint256 bBalance,
        uint256 balance
    );
    event PoolEnded(uint256 poolId, uint256 result);
    event AwardClaimed(
        uint256 poolId,
        address winner,
        uint256 deposit,
        uint256 award
    );
    event WithdrawBalance(address target, address token, uint256 amount);

    constructor() {
        // 5%
        creatorFee = 5;
        // 5%
        serviceFee = 5;

        totalPools = 0;
    }

    function initialize(address _gfx, address _eventDB) public onlyOwner {
        gfx_ = IERC20(_gfx);
        eventdb_ = IEventDatabase(_eventDB);
    }

    modifier checkValidEvent(uint256 _eventId) {
        (, uint256 startTime, , , , , , , ) = eventdb_.events(_eventId);

        require(startTime > 0, "PrivateSport: Invalid Event ID");
        _;
    }

    modifier checkValidPool(uint256 _poolId) {
        require(
            _poolId < totalPools && _poolId >= 0,
            "PrivateSport: Invalid poolId"
        );
        _;
    }

    modifier canParticipate(
        uint256 _poolId,
        uint256 _vote,
        uint256 _amount
    ) {
        (, uint256 startTime, , , , bool isEnded, , , ) = eventdb_.events(
            pools[_poolId].eventId
        );
        require(
            startTime > block.timestamp && !isEnded && !pools[_poolId].isEnded,
            "PrivateSport: Can't participate"
        );

        require(
            participants[_poolId][msg.sender].deposit == 0,
            "PrivateSport: Already participated"
        );

        require(_vote < 2 && _vote >= 0, "PrivateSport: Invalid Vote");
        require(_amount > 0, "PrivateSport: Should be over than 0 GFX");
        _;
    }

    modifier canEndPool(uint256 _poolId) {
        (, , uint256 endTime, , uint256 result, bool isEnded, , , ) = eventdb_
            .events(pools[_poolId].eventId);

        require(
            endTime <= block.timestamp && isEnded && result > 0,
            "PrivateSport: Not ready to end"
        );

        require(
            participants[_poolId][msg.sender].deposit > 0,
            "PrivateSport: Only participant can end pool"
        );
        _;
    }

    function setCreatorFee(uint256 _creatorFee) external onlyOwner {
        require(_creatorFee > 0, "Invalid input");

        creatorFee = _creatorFee;
    }

    function createServiceFee(uint256 _serviceFee) external onlyOwner {
        require(_serviceFee > 0, "Invalid input");

        serviceFee = _serviceFee;
    }

    function createPool(uint256 _eventId) external checkValidEvent(_eventId) {
        require(
            creatorOwnership[msg.sender][_eventId] == false,
            "PrivateSport: Pool creation duplicated"
        );

        (, uint256 startTime, , , , bool isEnded, , , ) = eventdb_.events(
            _eventId
        );
        require(
            startTime > block.timestamp && !isEnded,
            "PrivateSport: Time over"
        );

        Pool memory pool;

        pool.id = totalPools;
        pool.eventId = _eventId;
        pool.aRate = 0;
        pool.bRate = 0;
        pool.balance = 0;
        pool.aBalance = 0;
        pool.bBalance = 0;
        pool.result = Result.NONE;
        pool.isEnded = false;
        pool.owner = msg.sender;
        pools.push(pool);

        totalParticipants[totalPools] = 0;
        creatorOwnership[msg.sender][_eventId] = true;

        emit PoolCreated(totalPools, _eventId, msg.sender);

        totalPools++;
    }

    function participatePool(
        uint256 _poolId,
        uint256 _vote,
        uint256 _amount
    ) external checkValidPool(_poolId) canParticipate(_poolId, _vote, _amount) {
        require(
            gfx_.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        participants[_poolId][msg.sender].owner = msg.sender;
        participants[_poolId][msg.sender].vote = Vote(_vote);
        participants[_poolId][msg.sender].deposit = _amount;
        participants[_poolId][msg.sender].isClaimed = false;

        totalParticipants[_poolId]++;

        creatorOwnership[msg.sender][pools[_poolId].eventId] = true;

        _updatePoolRate(_poolId, _vote, _amount);
    }

    function endPool(uint256 _poolId)
        external
        checkValidPool(_poolId)
        canEndPool(_poolId)
    {
        (, , , , uint256 result, , , , ) = eventdb_.events(
            pools[_poolId].eventId
        );

        pools[_poolId].isEnded = true;
        pools[_poolId].result = Result(result);

        emit PoolEnded(_poolId, result);
    }

    function claimAward(uint256 _poolId) external checkValidPool(_poolId) {
        require(
            participants[_poolId][msg.sender].deposit > 0,
            "PrivateSport: No participant"
        );

        require(
            uint256(participants[_poolId][msg.sender].vote) + 1 ==
                uint256(pools[_poolId].result) ||
                pools[_poolId].result == Result.AB,
            "PrivateSport: Loser can't claim"
        );

        require(
            participants[_poolId][msg.sender].isClaimed == false,
            "PrivateSport: Already claimed"
        );

        Winner memory winner;
        winner.vote = participants[_poolId][msg.sender].vote;
        winner.owner = msg.sender;
        winner.deposit = participants[_poolId][msg.sender].deposit;

        // If the event is draw
        if (pools[_poolId].result == Result.AB) {
            winner.award = participants[_poolId][msg.sender].deposit;
        } else {
            if (participants[_poolId][msg.sender].vote == Vote.A) {
                winner.award =
                    (participants[_poolId][msg.sender].deposit *
                        pools[_poolId].aRate) /
                    100;
            } else {
                winner.award =
                    (participants[_poolId][msg.sender].deposit *
                        pools[_poolId].bRate) /
                    100;
            }
            // Transfer award to winner
            winner.award =
                (winner.award * (100 - serviceFee - creatorFee)) /
                100;

            // Transfer fee to pool owner
            uint256 amount = (winner.award * creatorFee) / 100;
            require(
                gfx_.transfer(pools[_poolId].owner, amount),
                "GFX transfer failed"
            );
        }

        require(
            gfx_.transfer(winner.owner, winner.award),
            "GFX transfer failed"
        );

        winners[_poolId].push(winner);

        participants[_poolId][msg.sender].isClaimed = true;

        emit AwardClaimed(_poolId, msg.sender, winner.deposit, winner.award);
    }

    function _updatePoolRate(
        uint256 _poolId,
        uint256 _vote,
        uint256 _amount
    ) private {
        pools[_poolId].balance += _amount;

        if (_vote == 0) {
            pools[_poolId].aBalance += _amount;
            pools[_poolId].aRate =
                (pools[_poolId].aBalance * 100) /
                pools[_poolId].balance;
        } else {
            pools[_poolId].bBalance += _amount;
            pools[_poolId].bRate =
                (pools[_poolId].bBalance * 100) /
                pools[_poolId].balance;
        }

        emit PoolRateUpdated(
            _poolId,
            pools[_poolId].aRate,
            pools[_poolId].bRate,
            pools[_poolId].aBalance,
            pools[_poolId].bBalance,
            pools[_poolId].balance
        );
    }

    function withdrawBalance(
        address _target,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_target != address(0), "Invalid Target Address");
        require(_token != address(0), "Invalid Token Address");
        require(_amount > 0, "Amount should be bigger than 0");

        IERC20 token = IERC20(_token);
        require(token.transfer(_target, _amount), "Withdraw failed");

        emit WithdrawBalance(_target, _token, _amount);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}