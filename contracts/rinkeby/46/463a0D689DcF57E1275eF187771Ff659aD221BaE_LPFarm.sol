//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./LPToken.sol";

contract LPFarm is Ownable {

    // base APR
    uint256 public BASE_APR;
    uint256 public MULTIPLIER;
    uint256 public FEE = 3;
    uint256 private FEE_BALANCE = 0;
    address private FEE_TO;
    address private FEE_TO_SETTER;
    uint256 private ONE_YEAR = 31536000;
    uint256 private ONE_ETH = 1000000000000000000;
    // user's staking balance
    mapping(address => uint256) public stakingBalance;
    // staking start timestamp
    mapping(address => uint256) public startTime;
    // user's yield to claim
    mapping(address => uint256) public yieldBalance;
    // user's index
    mapping(address => uint256) public trenchIndex;
    // Trenches
    uint256[2][] public trenches;
    // Staking and rewards token interface
    IERC20 public lpToken;
    IERC20 public formToken;

    // contract's events
    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);
    event FeeWithdraw(address indexed to, uint256 amount);

    constructor(
        IERC20 _formToken,
        IERC20 _lpToken,
        uint256 initialAPR,
        uint256 initialMultiplier,
        address _feeToSetter
        ) {
        formToken = _formToken;
        lpToken = _lpToken;
        BASE_APR = initialAPR;
        MULTIPLIER = initialMultiplier;
        FEE_TO_SETTER = _feeToSetter;
        FEE_TO = _feeToSetter;
        trenches.push([block.timestamp, BASE_APR*MULTIPLIER]);
    }

    /// APR and multiplier calculations
    function getAPRValue() external view returns(uint256) {
        return BASE_APR*MULTIPLIER;
    }
    function setMultiplier(uint256 newMultiplier) onlyOwner external {
        MULTIPLIER = newMultiplier;
        trenches.push([block.timestamp, BASE_APR*MULTIPLIER]);
    }
    function setFee(uint256 newFee) onlyOwner external {
        FEE = newFee;
    }
    function sendFeeTo(address feeTo) external {
        require(msg.sender == FEE_TO_SETTER, 'FORBIDDEN');
        FEE_TO = feeTo;
    }
    function setFeeToSetter(address newSetter) external {
        require(msg.sender == FEE_TO_SETTER, 'FORBIDDEN');
        FEE_TO_SETTER = newSetter;
    }
    function getFee() external view returns(uint256) {
        return FEE_BALANCE;
    }

    /// Yield calculations
    function _calculateYield(address user) private view returns(uint256) {
        // end means now
        uint256 end = block.timestamp;
        uint256 totalYield;
        // loop through trenches
        for(uint256 i = trenchIndex[user]; i < trenches.length; i++){
            // how long the user was staking during the trench
            uint256 stakingTimeWithinTier;
            // if comparing to the last trench then
            // check how long user was staking during that trench
            if (i + 1 == trenches.length) {
                if (startTime[user] > trenches[i][0]) {
                    stakingTimeWithinTier = end - startTime[user];
                } else {
                    stakingTimeWithinTier = end - trenches[i][0];
                    // if no at all, then work is done
                    if (stakingTimeWithinTier < 0) {
                        continue;
                    }
                }
            } else {
                // check if user was staking during that trench
                // if no skip to another trench
                if (startTime[user] >= trenches[i + 1][0]) {
                    continue;
                } else {
                    // check if user was staking during the entire trench or partially
                    uint256 stakingTimeRelative = trenches[i + 1][0] - startTime[user];
                    uint256 tierTime = trenches[i + 1][0] - trenches[i][0];
                    // that means entire timespan (even more)
                    if (stakingTimeRelative >= tierTime) {
                        stakingTimeWithinTier = tierTime;
                    } else {
                        // that means partially
                        stakingTimeWithinTier = stakingTimeRelative;
                    }
                }
            }
            // calculate yield earned during the trench
            uint256 yieldEarnedWithinTier = (((trenches[i][1] * ONE_ETH) / ONE_YEAR) * stakingTimeWithinTier) / 100;
            uint256 netYield = stakingBalance[user] * yieldEarnedWithinTier;
            uint256 netYieldFormatted = netYield / ONE_ETH;
            // add to total yield (from all trenches eventually)
            totalYield += netYieldFormatted;
        }
        return totalYield;
    }

    function getUsersYieldAmount(address user) public view returns(uint256) {
        require(
            stakingBalance[user] > 0,
            "You do not stake any tokens");
        uint256 yieldEarned = _calculateYield(user);
        uint256 yieldUpToDate = yieldBalance[msg.sender];
        uint256 yieldTotal = yieldEarned + yieldUpToDate;
        return yieldTotal;
    }

    /// Core functions
    function stake(uint256 amount) external {
        // amount to stake and user's balance can not be 0
        require(
            amount > 0 &&
            lpToken.balanceOf(msg.sender) >= amount, 
            "You cannot stake zero tokens");
        
        // if user is already staking, calculate up-to-date yield
        if(stakingBalance[msg.sender] > 0){
            uint256 yieldEarned = getUsersYieldAmount(msg.sender);
            yieldBalance[msg.sender] = yieldEarned;
        }

        lpToken.transferFrom(msg.sender, address(this), amount); // add LP tokens to the staking pool
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp; // upserting the staking schedule whether user is already staking or not
        trenchIndex[msg.sender] = trenches.length - 1;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(
            stakingBalance[msg.sender] >= amount, 
            "Nothing to unstake"
        );

        uint256 lpFeeValue = amount * FEE / 1000;
        uint256 lpTransferValue = amount - lpFeeValue;
        uint256 formTransferValue = getUsersYieldAmount(msg.sender);

        lpToken.transfer(msg.sender, lpTransferValue); // transfer LP tokens
        formToken.transfer(msg.sender, formTransferValue); // transfer FORM tokens
        yieldBalance[msg.sender] = 0;
        FEE_BALANCE += lpFeeValue;
        startTime[msg.sender] = block.timestamp;
        stakingBalance[msg.sender] -= amount;
        trenchIndex[msg.sender] = trenches.length - 1;

        emit Unstake(msg.sender, amount);
    }
    
    function withdrawYield() external {
        uint256 yieldEarned = getUsersYieldAmount(msg.sender);
        require(yieldEarned > 0, "Nothing to withdraw");

        uint256 transferValue = yieldEarned;

        formToken.transfer(msg.sender, transferValue);

        startTime[msg.sender] = block.timestamp;
        yieldBalance[msg.sender] = 0;
        trenchIndex[msg.sender] = trenches.length - 1;

        emit YieldWithdraw(msg.sender, transferValue);
    }

    function withdrawFee() external {
        require(FEE_BALANCE > 0, "Nothing to withdraw");
        require(msg.sender == FEE_TO, 'FORBIDDEN');
        uint256 transferValue = FEE_BALANCE;
        lpToken.transfer(msg.sender, transferValue);
        FEE_BALANCE = 0;
        emit FeeWithdraw(msg.sender, transferValue);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        return msg.data;
    }
}