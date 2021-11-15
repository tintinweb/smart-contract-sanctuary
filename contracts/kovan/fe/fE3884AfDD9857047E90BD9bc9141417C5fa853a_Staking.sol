//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Staking {

    IERC20 public hepa;

    IERC20 public xhepa;

    address public erm;

    mapping(address => uint256) public stakedAmounts;

    uint256 internal allStakes = 0;

    uint256 constant internal _magnitude = 2**128;

    uint256 internal _magnifiedRewardPerStake = 0; 

    mapping(address => int256) internal _magnifiedRewardCorrections;

    mapping(address => uint256) internal _withdrawals;

    // EVENTS

    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event DividendsDistributed(uint256 amount);

    // CONSTRUCTOR

    constructor(address hepa_, address xhepa_, address erm_) {
        require(hepa_ != address(0), "Invalid address of hepa");
        require(xhepa_ != address(0), "Invalid address of xhepa");
        require(erm_ != address(0), "Invalid addrerss of erm");

        hepa = IERC20(hepa_);
        xhepa = IERC20(xhepa_);
        erm = erm_;
    }

    function stake(uint256 amount) external {
        require(amount != 0, "Staking amount could not be zero");

        xhepa.transferFrom(msg.sender, address(this), amount);
        
        stakedAmounts[msg.sender] += amount;
        _magnifiedRewardCorrections[msg.sender] -= int256(_magnifiedRewardPerStake * amount);
        allStakes += amount;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount != 0, "Unstaking amount could not be zero");
        require(amount <= stakedAmounts[msg.sender], "User's stake is less than amount");
        
        stakedAmounts[msg.sender] -= amount;
        _magnifiedRewardCorrections[msg.sender] += int256(_magnifiedRewardPerStake * amount);
        allStakes -= amount;
        
        xhepa.transfer(msg.sender, amount);

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

