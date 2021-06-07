// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {

    mapping(address => uint256) public accumulatedComissions;
    uint256[2][] public poolPairs;
    uint256 constant YDR_PAIR_INDEX = 0;
    mapping (address => StakeDetails[]) public allStakes;
    //mapping (address => uint256) public actualStakeIndex;

    // contains indexes of associated pairs
    mapping(address => uint256) private bindedPairs;

    uint256 private treasury = 0;
    uint256[3] private _TIMES = [2592000,7776000,31104000];
    uint256[6] private _PERCENTAGES = [8,24,48,12,36,72];
    uint256[6] private _YDR_PERCENTAGES = [30,90,180,40,120,240];
    
    uint256[] private _bags;
    mapping(address => uint256) private _pairIndexes; // token address

    struct StakeDetails {
        uint256 pairIndex; // maybe uint32?
        uint256 poolIndex;
        uint256 miniPoolIndex;

        uint256 time;
        uint256 amount;
        uint256 point;
    }

    struct State {
        uint256 time;
        uint256[3] BNBRecords; // can be packed also
        uint256[3] miniPoolAmounts;
    }

    struct Pool {
        uint256[] pointersToStates;
        address tokenAddress;
        uint256[3] currentMiniPoolAmounts;
    }

    State[] private states;
    Pool[] private pools;

    constructor (address YDR, address YDRLP) {
        _addPoolPair(YDR, YDRLP);
    }

    // reentrancy-safe
    function stake(uint256 pairIndex, uint256 poolIndex, uint256 miniPoolIndex, uint256 amount) external 
    returns(uint256 stakeIndex) {
        Pool storage _pool = _getPool(pairIndex, poolIndex);

        IERC20 token = IERC20(_pool.tokenAddress);
        token.transferFrom(_msgSender(), address(this), amount);
        _pool.currentMiniPoolAmounts[miniPoolIndex] += amount;
        
        allStakes[_msgSender()].push(
            StakeDetails(
                pairIndex, 
                poolIndex, 
                miniPoolIndex, 
                block.timestamp, 
                amount, 
                _pool.pointersToStates.length)
            );
        return allStakes[_msgSender()].length - 1;
    }

    function unstake (uint256 stakeIndex) external {
        address _sender = _msgSender();
        (uint256 toReturn, uint256 comission) = harvest(_sender, stakeIndex, 0);

        StakeDetails storage _stake = allStakes[_sender][stakeIndex];
        Pool storage _pool = _getPool(_stake.pairIndex, _stake.poolIndex);
        
        address tokenAddress = _pool.tokenAddress;
        _pool.currentMiniPoolAmounts[_stake.miniPoolIndex] -= (toReturn + comission);
        accumulatedComissions[tokenAddress] += comission;

        IERC20(tokenAddress).transfer(_sender, toReturn);
        //добавить обновление actualStakeIndex если надо, если от actualStakeIndex до какого-то стейка все стейки закрыты, обновляем
    }

    // reentrancy-safe
    function inputBNB (uint256 pairIndex) external payable {
        require(pairIndex < poolPairs.length, "No poolpair with such index");
        if (pairIndex == 0) {
            pairIndex = bindedPairs[_msgSender()];
        }
        require(pairIndex != YDR_PAIR_INDEX, "Cannot put BNB into YDR pools");
        
        uint256 totalBNB = msg.value + _bags[pairIndex-1];
        uint256 remainder = totalBNB;
        _bags[pairIndex-1] = 0;

        uint256[2] memory _pair = poolPairs[pairIndex];
        for (uint256 poolIndex = 0; poolIndex < 2; poolIndex++) {
            Pool storage _pool = pools[_pair[poolIndex]];
            remainder -= _deductBNB(_pool, totalBNB, pairIndex, poolIndex, false);
        }

        uint256[2] memory _YDR_pair = poolPairs[YDR_PAIR_INDEX];
        for (uint256 poolIndex = 0; poolIndex < 2; poolIndex++){
            Pool storage _pool = pools[_YDR_pair[poolIndex]];
            remainder -= _deductBNB(_pool, totalBNB, pairIndex, poolIndex, true);
        }

        treasury += remainder;
    }

    // reentrancy-safe
    function withdrawTreasure() external onlyOwner {
        uint256 _treasury = treasury;
        treasury = 0;
        payable(_msgSender()).transfer(_treasury);
    }

    // reentrancy-safe
    function withdrawComission(address tokenAdress) external onlyOwner {
        uint256 amount = accumulatedComissions[tokenAdress];
        accumulatedComissions[tokenAdress] = 0;
        IERC20(tokenAdress).transfer(_msgSender(), amount);
    }

    function addPoolPair(address token, address LPtoken, address validAddress) external onlyOwner 
    returns(uint256 pairIndex) {
        require(token != address(0) && LPtoken != address(0), "Cannot set zero address as token");
        pairIndex = _addPoolPair(token, LPtoken);
        bindedPairs[validAddress] = pairIndex;
        _bags.push(0);
    }

    function getPairIndex(address token) external view returns(uint256) {
        return _pairIndexes[token];
    }

    function getUserStakes(address user) external view returns(StakeDetails[] memory) {
        return allStakes[user];
    }

    function getPoolInfo(address token, bool getLPpool) external view returns(Pool memory) {
        return _getPool(_pairIndexes[token], getLPpool ? 1 : 0);
    }

    function watchStake(address owner, uint256 stakeIndex, uint256 pointsNumber) 
    public view returns (uint256, uint256, uint256, uint256) {
        StakeDetails memory stakeToWatch = allStakes[owner][stakeIndex];
        uint256 _point = stakeToWatch.point;

        Pool storage _pool = _getPool(stakeToWatch.pairIndex, stakeToWatch.poolIndex);

        uint256[] memory _pointersToStates = _pool.pointersToStates;
        if (pointsNumber == 0) {
            pointsNumber = _pointersToStates.length;
        }
        else {
            pointsNumber += _point;
            require(pointsNumber <= _pointersToStates.length, "Not enough points to look at");
        }
        uint256 totalReward = 0;
        uint256 toReturn = stakeToWatch.amount;
        uint256 unstakeTime = stakeToWatch.time + _TIMES[stakeToWatch.miniPoolIndex];
        uint256 comission = 1;

        for (_point; _point < pointsNumber; _point++) {
            State storage _state = states[_pointersToStates[_point]];
            if (_state.time > unstakeTime) {
                comission = 0;
                break;
            }
            else {
                uint256 totalAmountWhenReward =_state.miniPoolAmounts[stakeToWatch.miniPoolIndex];
                uint256 totalBNBWhenReward = _state.BNBRecords[stakeToWatch.miniPoolIndex];
                totalReward = totalReward + ((totalBNBWhenReward * stakeToWatch.amount) / totalAmountWhenReward);
            }
        }

        if (comission == 1) {
            toReturn = (toReturn * 3) / 4;
            comission = stakeToWatch.amount - toReturn;
        }
        return (totalReward, toReturn, comission, _point);
    }

    function harvest(address who, uint256 stakeIndex, uint256 pointsNumber) public returns (uint256, uint256) {
        (uint256 totalReward, uint256 toReturn, uint256 comission, uint256 newPoint) = watchStake(who, stakeIndex, pointsNumber);
        allStakes[who][stakeIndex].point = newPoint;
        payable(who).transfer(totalReward);
        //помечать стейк как закрытый если надо
        return (toReturn, comission);
    }


    function _deductBNB(Pool storage _pool, uint256 totalBNB, uint256 pairIndex, uint256 poolIndex, bool forYDR)
    private returns(uint256 deducted) {
        uint256[3] memory _currentMiniPoolAmounts = _pool.currentMiniPoolAmounts;
        State memory st = State(block.timestamp, [uint256(0),0,0], _currentMiniPoolAmounts);
        
        for (uint256 k = 0; k < 3; k++) {
            uint256 toDeduct;
            if (forYDR) {
                toDeduct = (totalBNB * _YDR_PERCENTAGES[(poolIndex*3) + k]) / 1000;
            } else {
                toDeduct = (totalBNB * _PERCENTAGES[(poolIndex*3) + k]) / 1000;
            }

            if (_currentMiniPoolAmounts[k] == 0) {
                _bags[pairIndex-1] += toDeduct;
            }
            else {
                st.BNBRecords[k] = toDeduct;
            }
            deducted += toDeduct;
        }

        _pushState(_pool, st);
        return deducted;
    }

    function _addPoolPair(address token, address LPtoken) private returns(uint256 pairIndex){
        //потому что для YDR не нужна сумка и валид аддресс
        poolPairs.push([pools.length, pools.length + 1]);
        uint256[] memory pointersToStates;
        pools.push(Pool(pointersToStates, token, [uint256(0), 0, 0]));
        pools.push(Pool(pointersToStates, LPtoken, [uint256(0), 0, 0]));

        pairIndex = poolPairs.length - 1;
        _pairIndexes[token] = pairIndex;
    }

    function _pushState(Pool storage _pool, State memory _state) private {
        _pool.pointersToStates.push(states.length);
        states.push(_state);
    }

    function _getPool(uint256 pairIndex, uint256 poolIndex) private view returns(Pool storage) {
        uint256[2] memory _pair = poolPairs[pairIndex];
        return pools[_pair[poolIndex]];
    }

    function _getState(Pool storage _pool, uint256 index) private view returns (State storage) {
        return states[_pool.pointersToStates[index]];
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