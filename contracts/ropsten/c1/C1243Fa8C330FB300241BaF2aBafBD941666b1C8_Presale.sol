//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IToken {
  function transfer(address receiver, uint256 numTokens) external payable returns (bool);
  function approve(address delegate, uint256 numTokens) external returns (bool);
}

interface IRouter {
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Presale{
  uint256 unused = 0;
  //uint256 can over/underflow, so SafeMath prevents fuckups
  using SafeMath for uint256;

  //Public can be access from outside the contract
  //View is constant
  //Events can trigger external applications
  address public tokenAddress;
  uint256 public constant MAXSALE = 8 ether;
  uint256 public constant MAXALLOCATION = 2 ether;
  uint256 public currentSale = 0 ether;
  uint256 public presaleStartTime;
  uint256 public presaleStartTime2;
  address payable public deployerAddress;
  bool public open = false;
  address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public WNATIVE = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

  mapping(address => uint256) originalTokenBalances;
  mapping(address => uint256) tokenBalances;
  mapping(address => uint256) tokenBalances2;

  constructor(
    address tokenAddress_,
    uint256 timestamp,
    uint256 timestamp2
  ) {
    deployerAddress = payable(msg.sender);
    tokenAddress = tokenAddress_;
    presaleStartTime = timestamp;
    presaleStartTime2 = timestamp2;
  }

  function maxSale() public pure returns (uint256) {
    //Returns the maximum amount of ether the presale can hold
    return MAXSALE;
  }

  function maxAllocation() public pure returns (uint256) {
    //Returns the maximum amount a wallet can send as presale allocation
    return MAXALLOCATION;
  }

  function getOpen() public view returns (bool) {
    //Returns the variable that determines if the presale is open or not
    return open;
  }

  function setOpen(bool newValue) public returns (bool) {
    //Allows deployer to open presale
    require(msg.sender == deployerAddress, "Bad address");
    open = newValue;
    return true;
  }

  function setPresaleStartTime(uint256 startTime, uint256 startTime2) public returns (bool) {
    //Allows deployer to open presale
    require(msg.sender == deployerAddress, "Bad address");
    presaleStartTime = startTime;
    presaleStartTime2 = startTime2;
    return true;
  }

  function getCurrentSale() public view returns (uint256) {
    //Returns the amount of ether currently held
    return currentSale;
  }

  function setCurrentSale(uint256 amount) public returns (uint256) {
    //Used to close the sale
    require(msg.sender == deployerAddress, "Only deployer can use this function");
    currentSale = amount;
    return currentSale;
  }

  function viewOriginalAllocation(address userAddress) public view returns (uint256) {
    //Returns a wallet's original allocation
    return originalTokenBalances[userAddress];
  }

  function viewAllocation(address userAddress) public view returns (uint256) {
    //Returns a wallet's 1st phase allocation
    return tokenBalances[userAddress];
  }

  function viewAllocation2(address userAddress) public view returns (uint256) {
    //Returns a wallet's 2nd phase allocation
    return tokenBalances2[userAddress];
  }

  function canClaimTokens() public view returns (bool, bool){
    bool claim = false;
    bool claim2 = false;

    if(block.timestamp >= presaleStartTime) { claim = true; }
    if(block.timestamp >= presaleStartTime2) { claim2 = true; }

    return (claim, claim2);
  }

  function claimTokens() public returns (bool) {
    //Allows a wallet to claim the first phase of tokens
    require(block.timestamp >= presaleStartTime, "Bad block timestamp");
    require(tokenBalances[msg.sender] > 0, "No tokens to claim");
    uint256 tempBal = 0;
    tempBal = tokenBalances[msg.sender];
    tokenBalances[msg.sender] = 0;
    IToken(tokenAddress).transfer(msg.sender, tempBal);
    return true;
  }

  function claimTokens2() public returns (bool) {
    //Allows wallet to claim second phase of tokens (and first phase if not already claimed)
    require(block.timestamp >= presaleStartTime2, "Bad block timestamp");
    require(tokenBalances2[msg.sender] > 0, "No tokens to claim");
    uint256 tempBal = 0;
    uint256 tempBal2 = 0;
    tempBal = tokenBalances[msg.sender];
    tempBal2 = tokenBalances2[msg.sender];
    tokenBalances2[msg.sender] = 0;
    tokenBalances[msg.sender] = 0;
    IToken(tokenAddress).transfer(msg.sender, tempBal + tempBal2);
    return true;
  }

  function releaseEther() public returns (bool) {
    //Releases ether to deployer address to be used for liquidity
    require(msg.sender == deployerAddress, "Address does not match deployer address");

    deployerAddress.transfer(((address(this).balance)/100)*35);

    IToken(tokenAddress).approve(routerAddress, type(uint256).max);

    IRouter(routerAddress).addLiquidityETH{ value: ((address(this).balance)/100)*60 }(
      tokenAddress,//Token address
      4000,//amountTokenDesired
      4000,//amountTokenMin
      (((address(this).balance)/100)*60),//amountEthMin
      deployerAddress,//addressTo
      block.timestamp + (60 * 10)//deadline
    );
    return true;
  }

  receive() external payable {
    // On receive ether
    require(msg.value >= 0.001 ether, "Must send more than minimum allocation");
    require(originalTokenBalances[msg.sender] == 0, "Already participated in presale");
    require(currentSale + msg.value < MAXSALE, "Sale cannot exceed capacity");
    require(open == true || deployerAddress == msg.sender);

    originalTokenBalances[msg.sender] = msg.value * 1000;
    tokenBalances[msg.sender] = msg.value * 500;
    tokenBalances2[msg.sender] = msg.value * 500;
    currentSale = currentSale + msg.value;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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