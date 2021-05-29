/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

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

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}


contract TokenVesting
{
    using SafeERC20 for IERC20;
    
    using SafeMath for uint256;
    
    IERC20 private token;
    
    struct Vesting {
        uint256 releaseTime;
        uint256 cliffTime;
        uint256 amount;
        bool released;
        bool cliffReleased;
    }
    
    mapping(address => Vesting) public vestings;
    
    uint256 private tokensToVest = 0;

    event VestedTokenCliffReleased(address indexed beneficiary, uint256 amount);
    event TokenVestingRemoved(address indexed beneficiary, uint256 amount);
    event VestedTokenReleased(address indexed beneficiary, uint256 amount);
    event TokenVested(address indexed beneficiary, uint256 amount);
    
    address private _owner;
    constructor(address _address) public 
    {
        token=IERC20(_address);
        _owner=msg.sender;
    }
    
    modifier onlyOwner()
    {
        require(_owner==msg.sender,"Only owner");
        _;
    }

    function releaseTime(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary].releaseTime;
    }
    
    function cliffTime(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary].cliffTime;
    }

    function vestingAmount(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary].amount;
    }
    
    function removeVesting(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0x0),"Invalid address");
        Vesting storage vesting = vestings[_beneficiary];
        
        require(!vesting.released , "Vesting already realsed");
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        emit TokenVestingRemoved(_beneficiary, vesting.amount);
    }

    function addVesting(address _beneficiary, uint256 _amount) public onlyOwner {
        require(_beneficiary != address(0x0), "Invalid address");
        require(tokensToVest.add(_amount)<=2000000000,"Reached max vesting amount");
        tokensToVest = tokensToVest.add(_amount);
        vestings[_beneficiary] = Vesting({
            releaseTime: block.timestamp+(60*2),
            cliffTime: block.timestamp+(60),
            amount: _amount,
            released: false,
            cliffReleased:false
        });
        emit TokenVested(_beneficiary, _amount);
    }
    
    function releaseTokens(address _beneficiary) public {
        require(_beneficiary != address(0x0),"Invalid address");
        Vesting storage vesting = vestings[_beneficiary];
       
        require(!vesting.released , "Vesting already released");
        if (!vesting.cliffReleased && !vesting.released && block.timestamp >= vesting.cliffTime) {
            vesting.cliffReleased = true;
            uint256 _amount=vesting.amount.div(2);
            tokensToVest = tokensToVest.sub(_amount);
            vesting.amount=vesting.amount.sub(_amount);
            token.transfer(_beneficiary, _amount);
            emit VestedTokenCliffReleased(_beneficiary, vesting.amount);
        }

        if (!vesting.released && block.timestamp >= vesting.releaseTime) {
            uint256 _value=vesting.amount;
            tokensToVest = tokensToVest.sub(_value);
            vesting.released = true;
            vesting.amount=vesting.amount.sub(_value);
             token.transfer(_beneficiary,_value);
           emit VestedTokenReleased(_beneficiary, vesting.amount);
        }
    }
    
    function retrieveExcessTokens(uint256 _amount) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)).sub(tokensToVest), "INSUFFICIENT_BALANCE");
        token.safeTransfer(_owner, _amount);
    }
}