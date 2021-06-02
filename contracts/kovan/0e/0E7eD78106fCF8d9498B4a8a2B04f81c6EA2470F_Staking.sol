// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {

    uint256 private treasury = 0;
    uint256 private constant _WEEK = 604800;
    uint256[3] private _TIMES = [2592000,7776000,31104000];
    uint256[12] private _PERCENTAGES = [8,24,48,12,36,72,30,90,180,40,120,240];
    //mapping (address => uint256) public actualStakeIndex;
    mapping (address => StakeDetails[]) public allStakes;
    uint256[] private _bags;

    struct StakeDetails {
        uint256[3] indexes;
        uint256 time;
        uint256 amount;
        uint256 point;
    }

    struct State {
        uint256 time;
        uint256[3] BNBRecords;
        uint256[3] miniPoolAmounts;
    }

    struct Pool {
        uint256 points;
        State[] pointToState;
        address tokenAddress;
        uint256[3] currentMiniPoolAmounts;
    }

    address[] private validAddresses;
    mapping (uint256 => Pool[2]) public poolPairs;

    function harvest (address who, uint256 stakeIndex, uint256 pointsNumber) public nonReentrant returns (uint256) {
        (uint256 totalReward, uint256 toReturn, uint256 newPoint) = watch(who, stakeIndex, pointsNumber);
        allStakes[who][stakeIndex].point = newPoint;
        payable(who).transfer(totalReward);
        return (toReturn);
    }

    function stake (uint256 pairIndex, uint256 poolIndex, uint256 miniPoolIndex, uint256 amount) external nonReentrant {
        IERC20 token = IERC20(poolPairs[pairIndex][poolIndex].tokenAddress);
        token.transferFrom(_msgSender(), address(this), amount);
        poolPairs[pairIndex][poolIndex].currentMiniPoolAmounts[miniPoolIndex] += amount;
        allStakes[_msgSender()].push(StakeDetails([pairIndex, poolIndex, miniPoolIndex], block.timestamp, amount, poolPairs[pairIndex][poolIndex].points));
    }

    function watch (address who, uint256 stakeIndex, uint256 pointsNumber) public view returns (uint256, uint256, uint256) {
        StakeDetails memory toWatch = allStakes[who][stakeIndex];
        uint256 _point = toWatch.point;
        if (pointsNumber == 0) {
            pointsNumber = poolPairs[toWatch.indexes[0]][toWatch.indexes[1]].points;
        }
        else {
            pointsNumber += _point;
            require(pointsNumber <= poolPairs[toWatch.indexes[0]][toWatch.indexes[1]].points, "Not enogh points to look at");
        }
        uint256 totalReward = 0;
        uint256 toReturn = toWatch.amount;
        uint256 unstakeTime = toWatch.time + _TIMES[toWatch.indexes[2]];
        bool noComission = false;
        for (_point; _point < pointsNumber; _point++) {
            if (poolPairs[toWatch.indexes[0]][toWatch.indexes[1]].pointToState[_point].time > unstakeTime) {
                noComission = true;
                //добавить обновление actualStakeIndex если надо
                break;
            }
            else {
                uint256 totalAmountWhenReward = poolPairs[toWatch.indexes[0]][toWatch.indexes[1]].pointToState[_point].miniPoolAmounts[toWatch.indexes[2]];
                uint256 totalBNBWhenReward = poolPairs[toWatch.indexes[0]][toWatch.indexes[1]].pointToState[_point].BNBRecords[toWatch.indexes[2]];
                totalReward = totalReward + ((totalBNBWhenReward * toWatch.amount) / totalAmountWhenReward);
            }
        }
        if (noComission == false) {
            toReturn = (toReturn * 3) / 4;
        }
        return (totalReward, toReturn, _point);
    }

    function unstake (uint256 stakeIndex) external nonReentrant {
        address who = _msgSender();
        uint256 toReturn = harvest(who, stakeIndex, 0);
        IERC20 token = IERC20(poolPairs[allStakes[who][stakeIndex].indexes[0]][allStakes[who][stakeIndex].indexes[1]].tokenAddress);
        poolPairs[allStakes[who][stakeIndex].indexes[0]][allStakes[who][stakeIndex].indexes[1]].currentMiniPoolAmounts[allStakes[who][stakeIndex].indexes[2]] -= toReturn;
        token.transfer(who, toReturn);
    }

    function inputBNB (uint256 pairIndex) external payable {
        //добавить админ адрес параметры пул
        require(pairIndex <= validAddresses.length, "No poolpair with such index");
        if (pairIndex == 0) {
            for (uint256 i = 0; i < validAddresses.length; i++) {
                if (_msgSender() == validAddresses[i]) {
                    pairIndex = i+1;
                }
            }
        }
        require(pairIndex != 0, "Cannot put BNB into 0 pools");
        uint256 total = msg.value;
        uint256 remainder = msg.value;
        for (uint256 j = 0; j < 2; j++) {
            uint256 curpoint = poolPairs[pairIndex][j].points + 1;
            poolPairs[pairIndex][j].points = curpoint;
            poolPairs[pairIndex][j].pointToState.push(State(block.timestamp, [uint256(0),0,0], poolPairs[pairIndex][j].currentMiniPoolAmounts));
            for (uint256 k = 0; k < 3; k++) {
                uint256 toDeduct = (total * _PERCENTAGES[(j*3)+k]) / 1000;
                if (poolPairs[pairIndex][j].currentMiniPoolAmounts[k] == 0) {
                    _bags[pairIndex] += toDeduct;
                }
                else {
                    poolPairs[pairIndex][j].pointToState[curpoint].BNBRecords[k] = toDeduct;
                }
                remainder -= toDeduct;
            }
        }
        for (uint256 j = 0; j < 2; j++){
            uint256 curpoint = poolPairs[pairIndex][j].points + 1;
            poolPairs[pairIndex][j].points = curpoint;
            poolPairs[pairIndex][j].pointToState.push(State(block.timestamp, [uint256(0),0,0], poolPairs[pairIndex][j].currentMiniPoolAmounts));
            for (uint256 k = 0; k < 3; k++) {
                uint256 toDeduct = (total * _PERCENTAGES[(j*3)+k+6]) / 1000;
                poolPairs[pairIndex][j].pointToState[curpoint].BNBRecords[k] = toDeduct;
                remainder -= toDeduct;
            }
        }
        treasury += remainder;
    }

    function getTreasure() external onlyOwner nonReentrant {
        payable(_msgSender()).transfer(treasury);
        treasury = 0;
    }

    function setPoolPair (address token, address LPtoken) external onlyOwner nonReentrant {
        require(token != address(0) && LPtoken != address(0), "Cannot set zero address as token");
        poolPairs[0][0].points = 0;
    }
}

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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