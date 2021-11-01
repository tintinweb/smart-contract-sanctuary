/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: LICENCED

pragma solidity ^0.6.6;


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
 * @title TokenVesting contract
 */
contract TokenVesting
{
    using SafeERC20 for IERC20;
    
    using SafeMath for uint256;
    
    IERC20 private token;
    
    struct Vesting {
        uint256 _endDate;
        uint256 _startDate;
        uint256 _cliffDate;
        uint256 _amount;
        uint256 _remaining;
        uint256 _nextDate;
        bool _revoked;
    }
    
    mapping(address => Vesting) private vestings;


    //events
    event VestedTokensReleased(address beneficiary, uint256 amount);
    
    event Revoked(address beneficiary);
    
    event TokenVested(address beneficiary, uint256 amount);
    
    //tokens
    uint256 totalTokensForVesting=500000000* 10 ** 18;
    uint256 tokensAddedForVesting=0;
    
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
    function endDate(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary]._endDate;
    }
    
    //@dev Get start time 
    function startTime(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary]._startDate;
    }
    
    //@dev Get cliffTime of vesting
    function cliffTime(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary]._cliffDate;
    }
    
    //@dev Get cliffTime of vesting
    function nextDate(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary]._nextDate;
    }

    //@dev Get amount of tokens vested for beneficiary
    function vestingAmount(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary]._amount;
    }
    
    //@dev Get remaining amount
    function remainingAmount(address _beneficiary) public view returns (uint256) {
        return vestings[_beneficiary]._remaining;
    }
    
     //@dev Get total tokens added for vesting
    function getTokensAddedForVesting() public view returns (uint256) {
        return tokensAddedForVesting;
    }
    
    /**
     * @param _beneficiary Beneficiary address
     * @dev Remove beneficiary from vesting
    */
    function removeVesting(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0x0),"Invalid address");
        Vesting storage vesting = vestings[_beneficiary];
        require(!vesting._revoked , "Vesting already revoked");
        vesting._revoked = true;
        emit Revoked(_beneficiary);
    }

    /**
     * @dev Add a new token grant for user `_beneficiary`. Only one grant per user is allowed
     *  @param _beneficiary Beneficiary address to be added
     *  @param _amount Amount of tokens vested for _beneficiary
    */
    
    function addVesting(address _beneficiary, uint256 _amount) public onlyOwner {
        require(_beneficiary != address(0x0), "Invalid address");
        require(tokensAddedForVesting.add(_amount)<=totalTokensForVesting,"Reached max vesting amount");
        tokensAddedForVesting = tokensAddedForVesting.add(_amount);
        vestings[_beneficiary] = Vesting({
            _endDate: block.timestamp+(60*12),
            _startDate:block.timestamp,
            _cliffDate: block.timestamp+(60*2),
            _amount: _amount,
            _remaining:_amount,
            _nextDate: block.timestamp+(60*2),
            _revoked:false
        });
        emit TokenVested(_beneficiary, _amount);
    }
     
    /** @dev Claim tokens after cliff or vesting scheduled completed
     *  @param _beneficiary Address 
    */
    function releaseTokens(address _beneficiary) public {
        require(_beneficiary != address(0x0),"Invalid address");
        Vesting storage vesting = vestings[_beneficiary];
        require(!vesting._revoked , "Vesting revoked");
        require(vesting._remaining>0,"Token vested");
        
        uint256 amount;
        if (now < vesting._cliffDate || now<vesting._nextDate) {
          amount=0;
        } else if (now >= vesting._endDate) {
          amount = vesting._remaining;
        } else {
          amount=vesting._amount.div(10);
          vesting._nextDate=vesting._nextDate.add(60*1);
        }
        require(amount>0,"No tokens for transfer");
        vesting._remaining=vesting._remaining.sub(amount);
        token.safeTransfer(_beneficiary,amount);
        emit VestedTokensReleased(_beneficiary,amount);
    }
    
   
}