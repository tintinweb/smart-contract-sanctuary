/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  
    /**
        * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
      * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
        * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Mod two numbers.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 {

    function totalSupply() external view returns (uint256);

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
  
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
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

    //@dev Get releaseTime of vesting
    function releaseTime(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary].releaseTime;
    }
    
    //@dev Get cliffTime of vesting
    function cliffTime(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary].cliffTime;
    }

    //@dev Get amount of tokens vested for beneficiary
    function vestingAmount(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary].amount;
    }
    
    
    /**
     * Remove _beneficiary 
    */
    function removeVesting(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0x0),"Invalid address");
        Vesting storage vesting = vestings[_beneficiary];
        
        require(!vesting.released , "Vesting already realsed");
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        emit TokenVestingRemoved(_beneficiary, vesting.amount);
    }

    /**
     *Add a new token grant for user `_beneficiary`. Only one grant per user is allowed
     *  @param _beneficiary Beneficiary address to be added
     *  @param _amount Amount of tokens vested for _beneficiary
    */
    
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
    
    /** Claim tokens after cliff or vesting scheduled completed
     *  @param _beneficiary Address 
    */
    function releaseTokens(address _beneficiary) public {
        require(_beneficiary != address(0x0),"Invalid address");
        Vesting storage vesting = vestings[_beneficiary];
       
        require(!vesting.released , "Vesting already released");
        if (!vesting.cliffReleased && !vesting.released && block.timestamp >= vesting.cliffTime) {
            vesting.cliffReleased = true;
            uint256 _amount=vesting.amount.div(2);
            tokensToVest = tokensToVest.sub(_amount);
            vesting.amount=vesting.amount.sub(_amount);
            token.safeTransfer(_beneficiary, _amount);
            emit VestedTokenCliffReleased(_beneficiary, vesting.amount);
        }

        if (!vesting.released && block.timestamp >= vesting.releaseTime) {
            uint256 _value=vesting.amount;
            tokensToVest = tokensToVest.sub(_value);
            vesting.released = true;
            vesting.amount=vesting.amount.sub(_value);
             token.safeTransfer(_beneficiary,_value);
           emit VestedTokenReleased(_beneficiary, vesting.amount);
        }
    }
    
    /** 
     *  @dev Transfer remaining tokens to owner account
    */
    function getRemainingTokens(uint256 _amount) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)).sub(tokensToVest), "Balance low");
        token.safeTransfer(_owner, _amount);
    }
}