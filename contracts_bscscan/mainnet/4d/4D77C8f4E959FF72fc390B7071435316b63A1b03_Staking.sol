//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Staking is Ownable {

    IERC20 public hepa;

    IERC20 public xhepa;

    address public erm;

    address public dev;

    mapping(address => uint256) public stakedAmounts;

    uint256 internal allStakes = 0;

    uint256 constant internal _magnitude = 2**128;

    uint256 internal _magnifiedRewardPerStake = 0; 

    mapping(address => int256) internal _magnifiedRewardCorrections;

    mapping(address => uint256) internal _withdrawals;

    // Fees for unstaking
    uint256[] public feeStages;
    uint256[] public feeTimes;

    mapping(address => uint256) public lastStakingTimes;

    // EVENTS

    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event DividendsDistributed(uint256 amount);

    // CONSTRUCTOR

    constructor(
        address hepa_,
        address xhepa_,
        address erm_,
        address dev_,
        uint256[] memory feeStages_,
        uint256[] memory feeTimes_
    ) {
        require(hepa_ != address(0), "Invalid address of hepa");
        require(xhepa_ != address(0), "Invalid address of xhepa");
        require(erm_ != address(0), "Invalid addrerss of erm");
        require(dev_ != address(0), "Invalid address of dev");

        hepa = IERC20(hepa_);
        xhepa = IERC20(xhepa_);
        erm = erm_;
        dev = dev_;
        
        _setFees(feeStages_, feeTimes_);
    }

    function stake(uint256 amount) external {
        require(amount != 0, "Staking amount could not be zero");

        xhepa.transferFrom(msg.sender, address(this), amount);
        
        stakedAmounts[msg.sender] += amount;
        _magnifiedRewardCorrections[msg.sender] -= int256(_magnifiedRewardPerStake * amount);
        allStakes += amount;

        lastStakingTimes[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount != 0, "Unstaking amount could not be zero");
        require(amount <= stakedAmounts[msg.sender], "User's stake is less than amount");
        
        stakedAmounts[msg.sender] -= amount;
        _magnifiedRewardCorrections[msg.sender] += int256(_magnifiedRewardPerStake * amount);
        allStakes -= amount;
        
        uint256 fee = amount * _getFeePercent(msg.sender) / 100;
        xhepa.transfer(dev, fee);
        xhepa.transfer(msg.sender, amount - fee);

        emit Unstaked(msg.sender, amount);
    }

    function accumulativeRewardOf(address stakeholder) public view returns(uint256) {
        return uint256(int256(stakedAmounts[stakeholder] * _magnifiedRewardPerStake) 
                       + _magnifiedRewardCorrections[stakeholder]) / _magnitude;
    }

    function withdrawnRewardOf(address stakeholder) public view returns(uint256) {
        return _withdrawals[stakeholder];
    }

    function withdrawableRewardOf(address stakeholder) public view returns(uint256) {
        return accumulativeRewardOf(stakeholder) - withdrawnRewardOf(stakeholder);
    }

    function withdrawReward() external {
        uint256 withdrawable = withdrawableRewardOf(msg.sender);

        require(withdrawable > 0, "Nothing to withdraw");

        hepa.transfer(msg.sender, withdrawable);
        _withdrawals[msg.sender] += withdrawable;
    }

    function distribute(uint256 amount) external {
        require(msg.sender == erm, "Only ERM can call distribute");

        if (amount > 0 && allStakes > 0) {
            _magnifiedRewardPerStake += (_magnitude * amount) / allStakes;
            emit DividendsDistributed(amount);
        }
    }

    // RESTRICTED FUNCTIONS

    function setDev(address dev_) external onlyOwner {
        dev = dev_;
    }

    function setFees(uint256[] memory feeStages_, uint256[] memory feeTimes_) external onlyOwner {
        _setFees(feeStages_, feeTimes_);
    }

    // INTERNAL FUNCTIONS

    function _setFees(uint256[] memory feeStages_, uint256[] memory feeTimes_) private {
        require(feeStages_.length == feeTimes_.length, "Stages and times length mismatch");
        for (uint256 i = 0; i < feeStages_.length; i++) {
            require(feeStages_[i] <= 100, "Fee can't be more than 100%");
            if (i > 0) {
                require(feeStages_[i] < feeStages_[i - 1], "Fee stages should be decreasing");
                require(feeTimes_[i] > feeTimes_[i - 1], "Fee times should be increasing");
            }
        }

        feeStages = feeStages_;
        feeTimes = feeTimes_;
    }

    function _getFeePercent(address account) private view returns (uint256) {
        for (uint256 i = 0; i < feeTimes.length; i++) {
            if (block.timestamp < lastStakingTimes[account] + feeTimes[i]) {
                return feeStages[i];
            }
        }
        return 0;
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

