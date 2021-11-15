// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Ownable {

    uint256 private treasury = 0;
    uint256 private constant _WEEK = 604800;
    uint256[3] private _TIMES = [2592000,7776000,31104000];
    uint256[12] private _PERCENTAGES = [8,24,48,12,36,72,3,9,18,4,12,24];
    mapping (address => uint256) public actualStakeIndex;
    mapping (address => StakeDetails[]) public allStakes;
    uint256[3][5] public miniPoolAmounts = [[0,1,2],[4,8,7],[45,67,23]];
    //uint256[] public 

    struct StakeDetails {
        uint256[3] indexes;
        uint256 time;
        uint256 amount;
    }

    struct BNBRecord {
        uint256 time;
    }

    // struct TimeAndPercentage {
    //     uint256 time;
    //     uint256 percentage;
    // }

    struct Pool {
        address tokenAddress;
        uint256[] BNBRecords;
        uint256[3][] miniPoolAmounts;
    }

    address[] private validAddresses;
    mapping (uint256 => Pool[2]) private poolPairs;

    function harvest() public {

    }

    function setTokenAddress(uint256 pairIndex, uint256 poolIndex, address _tokenAddress) external onlyOwner {
        poolPairs[pairIndex][poolIndex].tokenAddress = _tokenAddress;
    }

    function stake (uint256 pairIndex, uint256 poolIndex, uint256 miniPoolIndex, uint256 amount) external {
        IERC20 token = IERC20(poolPairs[pairIndex][poolIndex].tokenAddress);
        token.transferFrom(_msgSender(), address(this), amount);
        //poolPairs[pairIndex][poolIndex].miniPoolAmounts[miniPoolIndex] += amount;
        allStakes[_msgSender()].push(StakeDetails([pairIndex, poolIndex, miniPoolIndex], block.timestamp, amount));
    }

    function watch (address who, uint256 stakeIndex) public view returns (uint256) {

    }

    function unstake (uint256 stakeIndex) external {
        //harvest();
        //require(_msgSender() == );
        //allStakes[_msgSender()]
        // IERC20 token = IERC20(poolPairs[pairIndex][poolIndex].tokenAddress);
        // uint256 startTime = poolPairs[pairIndex][poolIndex].miniPools[miniPoolIndex].users[_msgSender()][stakeIndex].time;
        // uint256 timeToEnd = startTime + _TIMES[miniPoolIndex];
        // if (timeToEnd > block.timestamp) {
        //     token.transfer(_msgSender(), (poolPairs[pairIndex][poolIndex].miniPools[miniPoolIndex].users[_msgSender()][stakeIndex].amount * 3) / 4);
        //     // uint256 timeDiff = timeToEnd - block.timestamp;
        //     // uint256 penalty = calculatePenalty(timeDiff, poolIndex, stakeIndex);
        // }
        // else {
        //     token.transfer(_msgSender(), poolPairs[pairIndex][poolIndex].miniPools[miniPoolIndex].users[_msgSender()][stakeIndex].amount);
        // }


    }

    // function inputBNB() external payable {
    //     for (uint256 i = 0; i < validAddresses.length; i++) {
    //         if (_msgSender() == validAddresses[i]) {
    //             uint256 total = msg.value;
    //             for (uint256 j = 0; j < 2; j++) {
    //                 for (uint256 k = 0; k < 3; k++) {
    //                     uint256 toDeduct = (total * _PERCENTAGES[(j*3)+k]) / 1000;
    //                     poolPairs[i+1][j].miniPools[k].totalBNB += toDeduct;
    //                     total -= toDeduct;
    //                 }
    //             }
    //             for (uint256 j = 0; j < 2; j++){
    //                 for (uint256 k = 0; k < 3; k++) {
    //                     uint256 toDeduct = (total * _PERCENTAGES[(j*3)+k+6]) / 1000;
    //                     poolPairs[0][j].miniPools[k].totalBNB += toDeduct;
    //                     total -= toDeduct;
    //                 }
    //             }
    //             break;
    //         }
    //     }
    //     treasury += msg.value;
    // }

    // function calculatePenalty (uint256 diff, uint256 poolIndex, uint256 stakeIndex) private returns (uint256) {
    //     return 0;
    // }


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

