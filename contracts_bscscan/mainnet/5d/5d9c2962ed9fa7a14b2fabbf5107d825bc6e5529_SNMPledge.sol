/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

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

contract SNMPledge {
    IERC20 public snmToken;
    IERC20 public rewardToken;
    uint256 public rewardAmount;
    mapping(address => bool) private owner;

    constructor() public {
        owner[msg.sender] = true;
    }

    function redeemSnmToken(address to, uint256 amount) public {
        require(owner[msg.sender] == true);
        if (amount > 0) {
            snmToken.transfer(to, amount);
        }
    }
    
    function reward(address to, uint256 amount) public {
        require(owner[msg.sender] == true);
        if (amount > 0) {
            rewardToken.transfer(to, amount);
        }
    }
    
    function setRewardAmount(uint256 _rewardAmount) public {
        require(owner[msg.sender] == true);
        rewardAmount = _rewardAmount;
    }
    
    function setRewardToken(IERC20 _rewardToken) public {
        require(owner[msg.sender] == true);
        rewardToken = _rewardToken;
    }
    
    function setSnmToken(IERC20 _SnmToken) public {
        require(owner[msg.sender] == true);
        snmToken = _SnmToken;
    }
    
    function setOwner(address account) public {
         require(owner[msg.sender] == true);
         owner[account] = true;
    }
    
    
}