pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./models/staking/StakingPool.sol";
import "./models/staking/StakingPoolCreate.sol";

contract Treasury is Ownable, ReentrancyGuard{
    mapping(string => StakingPool) public StakingPools;

    //Emitted when transferring tokens
    event TokensTransferred(string stakingPoolId, uint256 amount);
    event StakingPoolCreated(string stakingPoolId);
    event TokensWithdrawn(string stakingPoolId, uint256 amount);

    /**
     * @dev Create a staking pool
     * @param stakingPoolinfo the required info struct for creation
    */
    function CreateStakingPool(StakingPoolCreate memory stakingPoolinfo) nonReentrant external{
        require(!StakingPoolExists(stakingPoolinfo.StakingPoolId), "Stakingpool already exists!");
        require(stakingPoolinfo.Startdate > block.timestamp, "Stakingpool should start in the future");
        require(IERC20(stakingPoolinfo.TokenAddress).allowance(_msgSender(), address(this)) >= stakingPoolinfo.TokenAmount , "Allowance for token is not set");

        StakingPools[stakingPoolinfo.StakingPoolId].OwnerAddress = _msgSender();
        StakingPools[stakingPoolinfo.StakingPoolId].TokenAddress = stakingPoolinfo.TokenAddress;
        StakingPools[stakingPoolinfo.StakingPoolId].TokenAmount = stakingPoolinfo.TokenAmount;
        StakingPools[stakingPoolinfo.StakingPoolId].RemainingAmount = stakingPoolinfo.TokenAmount;
        StakingPools[stakingPoolinfo.StakingPoolId].Startdate = stakingPoolinfo.Startdate;
        StakingPools[stakingPoolinfo.StakingPoolId].Enddate = stakingPoolinfo.Enddate;
        StakingPools[stakingPoolinfo.StakingPoolId].VestingTime = stakingPoolinfo.VestingTime;
        StakingPools[stakingPoolinfo.StakingPoolId].VestingPercentage = stakingPoolinfo.VestingPercentage;
        StakingPools[stakingPoolinfo.StakingPoolId].IsVesting = stakingPoolinfo.VestingTime != 0 && stakingPoolinfo.VestingPercentage != 0;
        if(StakingPools[stakingPoolinfo.StakingPoolId].IsVesting)
        {
            uint nrOfPeriods = 100 / stakingPoolinfo.VestingPercentage;
            uint remainder = 100 % stakingPoolinfo.VestingPercentage;
            if(remainder > 0) nrOfPeriods += 1;
            StakingPools[stakingPoolinfo.StakingPoolId].Enddate = stakingPoolinfo.Startdate + (nrOfPeriods * (stakingPoolinfo.VestingTime * 1 days));
        }
        StakingPools[stakingPoolinfo.StakingPoolId].Exists = true;
        emit StakingPoolCreated(stakingPoolinfo.StakingPoolId);

        IERC20(stakingPoolinfo.TokenAddress).transferFrom(_msgSender(), address(this), stakingPoolinfo.TokenAmount);
        emit TokensTransferred(stakingPoolinfo.StakingPoolId, stakingPoolinfo.TokenAmount);
    }

    /**
     * @dev Withdraw stakingpool tokens (to distribute amongst charities)
     * @param stakingPoolId the id of the staking pool
    */
    function WithdrawStakingPool(string memory stakingPoolId) onlyOwner() nonReentrant external{
        require(StakingPoolExists(stakingPoolId), "Stakingpool does not exist!");
        require(StakingPools[stakingPoolId].RemainingAmount > 0, "No tokens remaining for withdrawal");
        require(StakingPools[stakingPoolId].Startdate < block.timestamp, "Staking pool has not started");
        if(!StakingPools[stakingPoolId].IsVesting){// not vesting -> release all
            require(StakingPools[stakingPoolId].Enddate < block.timestamp, "Staking pool has not finished");
            StakingPools[stakingPoolId].RemainingAmount = 0;
            IERC20(StakingPools[stakingPoolId].TokenAddress).transfer(_msgSender(), StakingPools[stakingPoolId].TokenAmount);
            emit TokensWithdrawn(stakingPoolId, StakingPools[stakingPoolId].TokenAmount);
        }else{
            uint256 claimed = StakingPools[stakingPoolId].TokenAmount - StakingPools[stakingPoolId].RemainingAmount;
            uint256 elapsed = block.timestamp - StakingPools[stakingPoolId].Startdate;
            uint256 releaseTimes = elapsed / (StakingPools[stakingPoolId].VestingTime * 1 days);
            require(releaseTimes > 0, "No interval available!");
            uint256 toRelease = (((StakingPools[stakingPoolId].TokenAmount / 100) * StakingPools[stakingPoolId].VestingPercentage) * releaseTimes) - claimed;
            require(toRelease > 0, "Interval already withdrawed");
            if(toRelease > StakingPools[stakingPoolId].RemainingAmount) toRelease = StakingPools[stakingPoolId].RemainingAmount;
            StakingPools[stakingPoolId].RemainingAmount -= toRelease;
            IERC20(StakingPools[stakingPoolId].TokenAddress).transfer(_msgSender(), toRelease);
            emit TokensWithdrawn(stakingPoolId, toRelease);
        }
    }

    /**
     * @dev Check to see if staking pool exists
     * @param stakingPoolId the id of the staking pool
    */
    function StakingPoolExists(string memory stakingPoolId) public view returns (bool){
        return StakingPools[stakingPoolId].Exists;
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

pragma solidity 0.8.4;

struct StakingPoolCreate{
    string StakingPoolId;
    address TokenAddress;
    uint256 TokenAmount;
    uint256 Startdate;
    uint256 Enddate;
    uint256 VestingTime;
    uint256 VestingPercentage;
}

pragma solidity 0.8.4;

struct StakingPool{
    address TokenAddress;
    address OwnerAddress;
    bool Exists;
    uint256 Startdate;
    uint256 Enddate;
    uint256 VestingTime;
    uint256 VestingPercentage;
    bool IsVesting;
    uint256 TokenAmount;
    uint256 RemainingAmount;
}

