// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./IBEP20.sol";

contract PrivateSale {

  using SafeMath for uint256;
  
  //BUSD FUNDING
  IBEP20 private token;
  address public saleAddress;
  uint256 public maxCap;
  uint256 public raised;
  uint256 public maxAllocation;
  uint256 public minPurchase;
  uint256 public maxPurchase;

  //VESTING
  IBEP20 public notableToken;
  uint256 public start;
  uint256 public duration;
  uint256 public initialReleasePercentage;

  mapping (address => uint256) internal _allocatedTokens;
  mapping (address => uint256) internal _claimedTokens;
  //mapping (address => uint256) internal investorsAllocation;
  
  // event amountAllocated(address indexed beneficiary, uint256 amount); !NOT USED
  event TokensAllocated(address indexed beneficiary, uint256 value);
  event TokensClaimed(address indexed beneficiary, uint256 value);

  constructor(
    address _saleAddress,
    address _token,
    address _notableToken,
    uint256 _maxCap,
    uint256 _maxAllocation,
    uint256 _minPurchase,
    uint256 _maxPurchase,
    uint256 _start,
    uint256 _duration,
    uint256 _initialReleasePercentage
  ) public{
    saleAddress = _saleAddress;
    token = IBEP20(_token);
    notableToken = IBEP20(_notableToken);
    maxCap = _maxCap;
    maxAllocation = _maxAllocation;
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
    start = _start;
    duration = _duration;
    initialReleasePercentage = _initialReleasePercentage;
  }

  modifier rightAmount(uint256 _amount) {
    require(_amount >= minPurchase, "Amount sent is lower than minimun purchase");
    require(_amount <= maxPurchase, "Amount sent is greater than maximimum purchase");
    _;
  }

  function buyAllocation(uint256 _busdAmount) public rightAmount(_busdAmount) {
    //require(_busdAmount >= minPurchase, "Amount sent is lower than minimun purchase");
    //require(_busdAmount <= maxPurchase, "Amount sent is greater than maximimum purchase");
    
    uint256 tokenAmount = tokenConversion(_busdAmount);
    
    require(_busdAmount.add(raised) <= maxCap, "Amount requested exceeds max cap");
    require(tokenAmount.add(_allocatedTokens[msg.sender]) <= maxAllocation, "Amount sent is greater than maxAllocation");
    
    require(token.allowance(msg.sender, address(this)) >= _busdAmount, "Insufficient funds");
    require(token.balanceOf(msg.sender) >=_busdAmount);

    token.transferFrom(msg.sender, saleAddress, _busdAmount);
    _allocatedTokens[msg.sender] = _allocatedTokens[msg.sender].add(tokenAmount);
    raised = raised.add(_busdAmount);

    _allocateTokens(msg.sender, tokenAmount);
  }

  function getAllowance(address _owner) public view returns (uint256) {
    return token.allowance(_owner, address(this));
  }

  function tokenConversion(uint256 _busdAmount) internal pure returns (uint256) {
    return (_busdAmount.mul(40)).div(3);
  }

  function claimTokens() public {
        uint256 claimableTokens = getClaimableTokens(msg.sender);
        require(claimableTokens > 0, "Vesting: no claimable tokens");

        _claimedTokens[msg.sender] += claimableTokens;
        notableToken.transfer(msg.sender, claimableTokens);

        emit TokensClaimed(msg.sender, claimableTokens);
    }

    function getAllocatedTokens(address beneficiary) public view returns (uint256 amount) {
        return _allocatedTokens[beneficiary];
    }

    function getClaimedTokens(address beneficiary) public view returns (uint256 amount) {
        return _claimedTokens[beneficiary];
    }

    function getClaimableTokens(address beneficiary) public view returns (uint256 amount) {
        uint256 releasedTokens = getReleasedTokensAtTimestamp(beneficiary, block.timestamp);
        return releasedTokens - _claimedTokens[beneficiary];
    }

    function getReleasedTokensAtTimestamp(address beneficiary, uint256 timestamp) 
        public
        view
        returns (uint256 amount)
    {
        if (timestamp < start) {
            return 0;
        }
        
        uint256 elapsedTime = timestamp - start;

        if (elapsedTime >= duration) {
            return _allocatedTokens[beneficiary];
        }

        uint256 initialRelease = _allocatedTokens[beneficiary] * initialReleasePercentage / 100;
        uint256 remainingTokensAfterInitialRelease = _allocatedTokens[beneficiary] - initialRelease;
        uint256 subsequentRelease = remainingTokensAfterInitialRelease * elapsedTime / duration;
        uint256 totalReleasedTokens = initialRelease + subsequentRelease;

        return totalReleasedTokens;
    }

    function _allocateTokens(address beneficiary, uint256 amount)
        internal
    {
        require(beneficiary != address(0), "Vesting: beneficiary is 0 address");
        _allocatedTokens[beneficiary] = amount;
        emit TokensAllocated(beneficiary, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
        return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
    * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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