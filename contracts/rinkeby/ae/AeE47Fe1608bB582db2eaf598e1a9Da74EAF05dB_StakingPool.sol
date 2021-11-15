// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IERC20.sol";
import "./lib/SafeMath.sol";

contract StakingPool{
    using SafeMath for uint256;
    
    /// @notice A structure representing a stake in the staking pool
    struct Stake {
        address holder;         //Address of the staker
        uint256 amount;         //Amount staked by the staker
        uint256 interest;       //Total calculated interest
        uint256 creationDate;   //Date of staking
        bool isClaimed;         //check whether the stake has been claimed or not
    }
    
    /// @notice The address of token for which we have created pool.
    address public tokenAddress;

    /// @notice Total tokens allocated to this pool that can be used for paying interests.
    uint256 public totalAllocation;

    /// @notice The period in seconds after which the stake will get matured for claiming.
    uint256 public period;

    /// @notice The interest rate to be paid for staking.
    uint256 public interestRate;

    /// @notice An array for storing stakes.
    Stake[] public stakes;

    /// @notice Count of stakes in the staking pool.
    uint256 public stakesCount;

    /// @dev Tokens left which can be used to pay interest.
    uint256 remainingAllocation;
    
    /**
     * @dev Gets the balance of the specified address.
     * @param _token The address of token for which we have created pool.
     * @param _allocation Total tokens allocated to this pool that can be used for paying interests.
     * @param _period The period in seconds after which the stake will get matured for claiming.
     * @param _interestRate The interest rate to be paid for staking.
     */
    constructor(
        address _token, 
        uint256 _allocation, 
        uint256 _period, 
        uint256 _interestRate
    )
    {
        tokenAddress = _token;
        totalAllocation = _allocation;
        period = _period;
        interestRate = _interestRate;
        stakesCount = 0;
        remainingAllocation = _allocation;
    }
    
    /**
     * @dev Function for staking tokens in the staking pool.
     * @param _amount The amount of tokens that has to be staked.
     */
    function stake(uint256 _amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= _amount, "Not enough balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");
        uint256 _interest = _amount.mul(interestRate).div(uint256(100));
        require(remainingAllocation >= _interest, "Not enough tokens left to pay interest");
        token.transferFrom(msg.sender, address(this), _amount);
        stakes.push(Stake(msg.sender, _amount, _interest, block.timestamp, false));
        stakesCount = stakesCount.add(uint256(1));
        remainingAllocation = remainingAllocation.sub(_interest);
    }
    
    /**
     * @dev Function for claiming all the matured and unclaimed tokens from the staking pool.
     */
    function claim() external {
        uint256 _totalAmount = 0;
        for(uint i=0; i < stakesCount; i++) {
            if(stakes[i].holder == msg.sender && stakes[i].isClaimed == false) {
                uint _maturity = stakes[i].creationDate + period;
                if(_maturity <= block.timestamp) {
                    _totalAmount = _totalAmount.add(stakes[i].amount).add(stakes[i].interest);
                    stakes[i].isClaimed = true;
                }
            }
        }
        require(_totalAmount > 0, "No tokens available to claim");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, _totalAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

