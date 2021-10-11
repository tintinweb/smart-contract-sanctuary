// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./access/Ownable.sol";

contract CrowdSales is Ownable, ReentrancyGuard {

  using SafeMath for uint256;
  
  struct Stage {

    uint256 openTime;
    uint256 closeTime;

    uint256 fundingGoal;
    uint256 amountRaised;

    uint256 tokenPrice;

    bool forwarded;
  }

  mapping(address => uint256) public balanceOf;
  
  Stage[] public stages;

  uint256 public minInvestFund;
  uint256 public maxInvestFund;

  uint256 public totalSold;

  mapping(address => uint256) public tokensClaimed;
  uint256 public totalClaimed;
  
  IERC20 ifansToken;

  uint256 public tge = 25;
  uint256 public duration = 12960000;    // 12960000 secs = 30 * 5 days, 5 months

  event Claimed(address _to, uint256 _amount);
  event Invested(address _to, uint256 _tokenAmount, uint256 _stageIndex);

  modifier _afterDeadline() {
    require(block.timestamp > stages[stages.length - 1].closeTime, "Sales not ended yet!");
    _;
  }

  constructor (address _ifansToken, uint256 _minInvestFund, uint256 _maxInvestFund) {
    ifansToken = IERC20(_ifansToken);
    minInvestFund = _minInvestFund;
    maxInvestFund = _maxInvestFund;
  }
  
  receive () external payable {
  }

  function stageCount() public view returns(uint256) {
    return stages.length;
  }

  function getCurrentStage() public view returns(uint256 stageIndex, bool isLive) {

    uint256 current = block.timestamp;
    
    for(uint256 i = 0; i < stages.length; i++) {
      Stage memory stage = stages[i];

      if (current >= stage.openTime && current <= stage.closeTime) {
        return (i, true);
      }

      if (current < stage.openTime) {
        return (i, false);
      }
    }
      
    return (stages.length, false);
  }

  function getAvailableToken(address investor) public view returns(uint256) {
    require(stages.length > 0, "iFans Sales: Invalid Stage Count");
    uint256 totalBalance = balanceOf[investor];
    if (totalBalance == 0) return 0;

    uint256 deadline = stages[stages.length - 1].closeTime;
    if (block.timestamp < deadline) return 0;

    uint256 timeEllapsed = block.timestamp - deadline;
    if (timeEllapsed >= duration)
      return totalBalance - tokensClaimed[investor];
    
    uint256 vesting = 100 - tge;
    uint256 percent = vesting.mul(timeEllapsed).div(duration);
    uint256 available = totalBalance.mul(percent + tge).div(100);
    return available - tokensClaimed[investor];
  }
  
  function addStage(
    uint256 _openTime, 
    uint256 _closeTime,
    uint256 _fundingGoal,
    uint256 _tokenPrice
  ) external onlyOwner {
    stages.push(Stage(_openTime, _closeTime, _fundingGoal, 0, _tokenPrice, false));
  }
  
  function setStage(
    uint256 stageIndex,
    uint256 _openTime, 
    uint256 _closeTime,
    uint256 _fundingGoal,
    uint256 _tokenPrice
  ) external onlyOwner {
    require(stageIndex < stages.length, "iFans Sales: Invalid Stage Index");
    stages[stageIndex].openTime = _openTime;
    stages[stageIndex].closeTime = _closeTime;
    stages[stageIndex].fundingGoal = _fundingGoal;
    stages[stageIndex].tokenPrice = _tokenPrice;
  }

  function setInvestRange(
    uint256 _min,
    uint256 _max
  ) external onlyOwner {
    require(_min < _max, "iFans Sales: Invalid Range");
    minInvestFund = _min;
    maxInvestFund = _max;
  }

  function setVestingStrategy(
    uint256 _tge,
    uint256 _duration
  ) external onlyOwner {

    require(_tge <= 100, "iFans Sales: invalid tge percentage");
    require(_duration > 0, "iFans Sales: invalid duration");

    tge = _tge;
    duration = _duration;
  }

  function setIFansToken(address _ifansToken) external onlyOwner {
    require(_ifansToken != address(0), "iFans Sales: zero token address");
    ifansToken = IERC20(_ifansToken);    
  }

  function invest() external payable {

    uint256 _bnbAmount = msg.value;

    require(_bnbAmount != 0, "iFans Sales: Zero Fund");
    require(_bnbAmount >= minInvestFund && _bnbAmount <= maxInvestFund, "iFans Sales: Invalid Investment Amount");

    (uint256 stageIndex, bool isLive) = getCurrentStage();

    require(isLive, "iFans: Stage is not live now");
  
    uint256 newAmountRaised = stages[stageIndex].amountRaised.add(_bnbAmount);
    require(newAmountRaised <= stages[stageIndex].fundingGoal, "iFans Sales: Too much investment");
    stages[stageIndex].amountRaised = newAmountRaised;

    uint256 tokenAmount = stages[stageIndex].tokenPrice.mul(_bnbAmount);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenAmount);

    totalSold = totalSold.add(tokenAmount);

    emit Invested(msg.sender, tokenAmount, stageIndex);
  }

  function claim() external  _afterDeadline nonReentrant {
    require(balanceOf[msg.sender] > 0, "iFans Sales: No tokens to claim");

    uint256 tokensAvailable = getAvailableToken(msg.sender);
    require(tokensAvailable > 0, "iFans Sales: No tokens to claim");

    ifansToken.transfer(msg.sender, tokensAvailable);
    tokensClaimed[msg.sender] = tokensClaimed[msg.sender].add(tokensAvailable);

    totalClaimed = totalClaimed.add(tokensAvailable);

    emit Claimed(msg.sender, balanceOf[msg.sender]);
  }
  
  function depositToken(uint256 _amount) external onlyOwner {
    ifansToken.transferFrom(msg.sender, address(this), _amount);
  }

  function forwardStageFunds(uint256 stageIndex, uint256 percent, address beneficiary) external onlyOwner {
    require(stageIndex < stages.length, "iFans Sales: invalid stage index");
    require(block.timestamp > stages[stageIndex].closeTime, "iFans Sales: stage not ended yet");
    require(stages[stageIndex].forwarded == false, "iFans Sales: stage funds already forwarded");

    require(percent <= 19, "iFans Sales: too much percent");

    uint256 totalAmount = stages[stageIndex].amountRaised;
    uint256 forwardBalance = totalAmount.mul(percent).div(100);

    require(forwardBalance <= address(this).balance, "iFans Sales: insufficient balance");

    stages[stageIndex].forwarded = true;
    payable(beneficiary).transfer(forwardBalance);
  }

  function withdrawToken() external _afterDeadline onlyOwner {

    uint256 currentBalance = ifansToken.balanceOf(address(this));

    uint256 withdrawBalance = currentBalance.add(totalClaimed).sub(totalSold);

    require(withdrawBalance > 0, "iFans Sales: Zero Token");

    ifansToken.transfer(msg.sender, withdrawBalance);
  }

  function withdrawBNB() external _afterDeadline onlyOwner {
    uint256 withdrawBalance = address(this).balance;
    payable(msg.sender).transfer(withdrawBalance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}