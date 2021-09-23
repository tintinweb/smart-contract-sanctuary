/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    function mint(address _to, uint _amount) external;
    
    function burn(address _from, uint _amount) external ;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract stakingContract {
    IERC20 public staketokenAdd;
    IERC20 public lptokenAdd;
    IERC20 public rewardtokenAdd;
    

    mapping (address => uint) public timeOfStaking;
    event Withdraw (address);
    event Stake (address);

    constructor(IERC20 _StakeToken, IERC20 _RewardToken, IERC20 _LPToken) {
        staketokenAdd =_StakeToken;
        rewardtokenAdd = _RewardToken;
        lptokenAdd = _LPToken;
    }

    function getStakeTokenBalofContract() public view returns(uint){
        return staketokenAdd.balanceOf(address(this));    
    }
    
    function getLPTokenBalofContract() public view returns(uint){
        return lptokenAdd.balanceOf(address(this));
    }
    
    function getRewardTokenBalofContract() public view returns(uint){
      return  rewardtokenAdd.balanceOf(address(this));
    }
    
    //gert amount curently staked by staker
    function getStakedAmount( address staker) public view returns(uint){
        return lptokenAdd.balanceOf(staker);
    }
    
    function timeOfstaking( address _staker) public view returns (uint) {
        return timeOfStaking[_staker] ;
    }
     
    function stake(uint _amountToBeStaked) public {
        require (staketokenAdd.balanceOf(msg.sender ) >= _amountToBeStaked , 'you have no stake tokens to stake');
        require(timeOfStaking[msg.sender] == 0, 'you cannot stake again until you claim previous reward from last stake');
    
        // transfer the stake token to the staking contract 
        staketokenAdd.transferFrom(msg.sender, address(this), _amountToBeStaked);
        
        //send lp tokens to the function caller. the lp tokens are evidence of amount of tokens staked.
        lptokenAdd.mint(msg.sender, _amountToBeStaked);

        //time tokens were staked by msg.sender
        timeOfStaking[msg.sender] = block.timestamp;

        emit Stake(msg.sender);
    } 
    
    
    function withdrawAndReward() public{ 
         //make sure lptokenBalOfSender is greater or less than the withdrawalAmount
        require(lptokenAdd.balanceOf(msg.sender) > 0, 'you have no staked tokens');
        uint lpamount = lptokenAdd.balanceOf(msg.sender);

        //burn lp token with msg.sender 
        lptokenAdd.burn(msg.sender, lpamount);

        // transfer staked tokens back to owner 
        staketokenAdd.transfer(msg.sender, lpamount);
        
        // calculate interest to be paid as reward tokens
        uint interest = lpamount/100;
        
        //transfer reward tokens to owner, they serve as interest on the Stake
        rewardtokenAdd.mint(msg.sender, interest);

        timeOfStaking[msg.sender] = 0;
        emit Withdraw(msg.sender);
    }
    
      
}