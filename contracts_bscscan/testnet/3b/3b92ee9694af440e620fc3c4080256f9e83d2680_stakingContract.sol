/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


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

contract stakingContract {

    IERC20 public token;
    uint256 minTxAmount = 100000 * 10 ** 8;

    struct userDetails {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool status;
    }

    mapping(address => userDetails) private user;
    mapping(uint256 => uint256) private levelPercentage;

    constructor (IERC20 _token, uint256 rRate1, uint256 rRate2, uint256 rRate3) {
        token = _token;
        levelPercentage[1] = rRate1;
        levelPercentage[2] = rRate2;
        levelPercentage[3] = rRate3;   
    }

    function staking(uint256 amount, uint256 level) public returns(bool) {
        require(amount >= minTxAmount, "amount is less than maxTxAmount");
        require(!(user[msg.sender].status),"user already exist");
        user[msg.sender].amount = amount;
        user[msg.sender].level = level;
        setlevel(level);
        user[msg.sender].initialTime = block.timestamp;
        user[msg.sender].status = true;
        token.transferFrom(msg.sender, address(this), amount);
        return true;
    }

    function setlevel(uint256 level) internal {
        if(level == 1) {
            user[msg.sender].endTime = 0;
        }
        else if(level == 2) {
            user[msg.sender].endTime = block.timestamp + 60 days;
        }
        else if(level == 3) {
            user[msg.sender].endTime = block.timestamp + 90 days;
        }
    }

    function getRewards(address account) public view returns(uint256) {
        require(user[account].status, "user not exist");
        uint256 stakeAmount = user[account].amount;
        uint256 timeDiff;
        require(block.timestamp >= user[account].initialTime, "Time exceeds");
        unchecked {
            timeDiff = block.timestamp - user[account].initialTime;
        }
        uint256 rewardRate = levelPercentage[user[account].level];
        uint256 rewardAmount = (stakeAmount*(rewardRate)/100)*timeDiff/365 days;
        return rewardAmount;
    }

    function withdraw() public returns(bool) {
        require(user[msg.sender].status, "user not exist");
        require(user[msg.sender].endTime <= block.timestamp, "staking end time is not reached ");
        uint256 rewardAmount = getRewards(msg.sender);
        token.transfer(msg.sender, rewardAmount);
        user[msg.sender].amount = 0;
        user[msg.sender].withdrawAmount += rewardAmount; 
        user[msg.sender].status = false; 
        return true;
    }

    function emergencyWithdraw() public returns(bool) {
        require(user[msg.sender].status, "user not exist");
        uint256 stakedAmount = user[msg.sender].amount;
        token.transfer(msg.sender, stakedAmount);
        user[msg.sender].amount = 0;
        user[msg.sender].status = false;
        return true;
    }

    function getUserDetails() public view returns(userDetails memory) {
        return userDetails(user[msg.sender].level, user[msg.sender].amount, user[msg.sender].initialTime, user[msg.sender].endTime, user[msg.sender].rewardAmount, user[msg.sender].withdrawAmount, user[msg.sender].status);
    }

    function setrTokenAddress(address _token) public returns (bool){
        token = IERC20(_token);
        return true;
    }

}