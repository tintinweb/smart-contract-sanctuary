/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: UNLICENSED

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface PancakeRouter {
    function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external returns (uint[] memory amounts);
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface GummyPrice {
    function getReserves() external view returns(uint112, uint112, uint32);
}

interface GummyToken { 
     function transfer(address recipient, uint256 amount) external; 
     function balanceOf(address account) external view returns (uint256); 
} 
contract tokenRoulette {
    using SafeMath for uint256;
    address public pancakeAddress = 0xCb9f150592FEAf15c7CE54D5e934B9CE3A2Ceb6E;
    address public pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    GummyToken public token;
    uint256 public ticketprice = 1e17;
    address trusted = 0x0a20B5F17C72aB7b3CD882804D2DB5b2ce8b96A6;
    uint256 constant tokendecimal = 1e18;
    uint256 constant bnbdecimal = 1e18;
    address[] path = [0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, 0xA2C34a855812f1D95032f4C7626eb488CDfb6D0e];
    uint256 public rewardTier1;
    uint256 public rewardTier2;
    uint256 public rewardTier3;
    uint256 public jackpot;
    event outcome(address indexed _from, uint256 colour, uint256 number,uint256 remainingTickets, uint256 betType, uint256 isWinner, uint256 bnbTransferred); 
    event ticketPurchase(address indexed _from, uint256 remainingTickets );
    event seedTracker(address indexed _from, uint generatedNumber);
    mapping (address => uint) public tickets;
    constructor( 
        GummyToken _token, uint256 tier1, uint256 tier2, uint256 tier3, uint256 _jackpot ) { 
        token = _token; 
        rewardTier1 = tier1;
        rewardTier2 = tier2;
        rewardTier3 = tier3;
        jackpot = _jackpot;
    } 
    receive() payable external { 
        purchaseTickets(); 
    } 
    
    function purchaseTickets() payable public {
        require (msg.value >= ticketprice,"Not enough BNB to buy tickets" );
        require (msg.value.mod(ticketprice) == 0);
        uint256 ticketQuantity = msg.value.div(ticketprice);
        tickets[msg.sender] = tickets[msg.sender].add(ticketQuantity);
        emit ticketPurchase(msg.sender, tickets[msg.sender]);
    }
    function getCurrentPricePerBNB() public view returns(uint112) {
       
       (uint112 Res0, uint112 Res1,uint32 blockTimeStamp) = GummyPrice(pancakeAddress).getReserves(); 
       if (Res0 == 0) {
           Res0 = 100;
       }
       if (Res1 == 0) {
           Res1 = 100;
       }
       
       uint112 currentTokensPerBNB = Res0/Res1;
       return currentTokensPerBNB;
   }
   function getAmountsOut(uint256 amountIn) public view returns (uint256) {
       uint256[] memory amountOut = PancakeRouter(pancakeRouterAddress).getAmountsOut(amountIn, path);
       uint256 amountRequired = amountOut[1];
       return amountRequired;
   }
    function buyGummiesIfDeficit() internal {
        uint256 amountIn = (ticketprice * (jackpot/100));
        uint256 amountOut = getAmountsOut(amountIn);
        PancakeRouter(pancakeRouterAddress).swapExactTokensForTokens(amountIn,amountOut,path,address(this), block.timestamp);
  }
  
    function checkForGummies() internal view returns (uint256){
        uint256 tokenPrice = getCurrentPricePerBNB();
        uint256 requiredGummies = tokenPrice * (jackpot/100);
        uint256 availableGummies = token.balanceOf(address(this));
        uint256 ifRequired = 0;
        if (requiredGummies >= availableGummies) {
            ifRequired = 1;
        }
        return ifRequired;
        
    }
    function play(uint256 betChoice) public {
        
        require (tickets[msg.sender] >= 1, "You need to have tickets to be able to play");
        uint256 tokenAmount;
        uint256 genNum = uint256(blockhash(block.number - 1));
        uint256 wheelNumber = processRandomNumbers(genNum);
        uint256 numberColour = processNumberColor(wheelNumber);
        uint256 betType = getbetType(betChoice);
        uint256 isWinner = determineIfWinner(betType,wheelNumber,numberColour,betChoice);
        tickets[msg.sender] = tickets[msg.sender] - 1;
        uint256 checkIfGummyRequired = checkForGummies();
        if (checkIfGummyRequired == 1) {
            buyGummiesIfDeficit();
        }
        if (isWinner == 1) {
            
            tokenAmount = processPrizeAmount(betType);
            require (token.balanceOf(address(this)) >= tokenAmount, "Not enough Gummy Tokens.");
            token.transfer(msg.sender, tokenAmount);
        }
        
        emit outcome(msg.sender, numberColour, wheelNumber,tickets[msg.sender], betType, isWinner, tokenAmount);
    }

    function processRandomNumbers(uint256 genNum) internal pure returns (uint256) {
        
        uint256 polish = genNum.mod(37);
        return polish;
    }
    
    /*
    
    0 = green
    1 = black
    2 = red
    
    */
    
    function processNumberColor(uint256 generatedNum) internal pure returns (uint256) {
        uint256 colour;
        uint256 processNumber2 = generatedNum.mod(2);
        if ( generatedNum == 0) {
            colour = 0;
        }
        else {
            if (processNumber2 == 1) {
                colour = 2;
            }
            else {
                colour = 1;
            }
        }
        return colour;
        
    }
    
    /* bettypes
    0-36 - 1 - numbers
    37 - 2 - 1-34 2to1
    38 - 3 - 2-35 2to1
    39 - 4 - 3-36 2to1
    40 - 5 - 1st 12
    41 - 6 - 2nd 12
    42 - 7 - 3rd 12
    43 - 8 - even
    44 - 9 - odd
    45 - 10 - red
    46 - 11 - black
    47 - 12 - 1 to 18
    48 - 13 - 18 - 36
    */
    
    function getbetType(uint256 betChoice) internal pure returns(uint256) {
        uint256 betType;
        if (betChoice >=0 && betChoice <=36) {
            betType = 1; 
        }
        if (betChoice == 37) {
            betType = 2; 
        }
        if (betChoice == 38) {
            betType = 3; 
        }
        if (betChoice == 39) {
            betType = 4; 
        }
        if (betChoice == 40) {
            betType = 5;
        }
        if (betChoice == 41) {
            betType = 6; 
        }
        if (betChoice == 42) {
            betType = 7; 
        }
        if (betChoice == 43) {
            betType = 8; 
        }
        if (betChoice == 44) {
            betType = 9;
        }
        if (betChoice == 45) {
            betType = 10; 
        }
        if (betChoice == 46) {
            betType = 11; 
        }
        if (betChoice == 47) {
            betType = 12; 
        }
        if (betChoice == 48) {
            betType = 13;
        }
        
    return betType;
    }
    function determineIfWinner(uint256 betType, uint256 wheelNumber, uint256 colour, uint256 betChoice) internal pure returns (uint256) {
        uint256 ifWinner = 0;
        if (betType == 1) {
            if (betChoice == wheelNumber) {
                ifWinner = 1;
            }
        }
       if (betType == 2) {
            if (wheelNumber == 1 ||
                wheelNumber == 4 || 
                wheelNumber == 7 || 
                wheelNumber == 10 || 
                wheelNumber == 13 || 
                wheelNumber == 16 || 
                wheelNumber == 19 ||
                wheelNumber == 22 ||
                wheelNumber == 25 ||
                wheelNumber == 28 ||
                wheelNumber == 31 ||
                wheelNumber == 34) {
                ifWinner = 1;
            }
        }
        if (betType == 3) {
            if (wheelNumber == 2 ||
                wheelNumber == 5 || 
                wheelNumber == 8 || 
                wheelNumber == 11 || 
                wheelNumber == 14 || 
                wheelNumber == 17 || 
                wheelNumber == 20 ||
                wheelNumber == 23 ||
                wheelNumber == 26 ||
                wheelNumber == 29 ||
                wheelNumber == 32 ||
                wheelNumber == 35) {
                ifWinner = 1;
            }
        }
        
        if (betType == 4) {
            if (wheelNumber == 3 ||
                wheelNumber == 6 || 
                wheelNumber == 9 || 
                wheelNumber == 12 || 
                wheelNumber == 15 || 
                wheelNumber == 18 || 
                wheelNumber == 21 ||
                wheelNumber == 24 ||
                wheelNumber == 27 ||
                wheelNumber == 30 ||
                wheelNumber == 33 ||
                wheelNumber == 36) {
                ifWinner = 1;
            }
        }
        if (betType == 5) {
            if (wheelNumber >= 1 && wheelNumber <=12) {
                ifWinner = 1;
            }
        }
        if (betType == 6) {
            if (wheelNumber >= 13 && wheelNumber <=24) {
                ifWinner = 1;
            }
        }
        if (betType == 7) {
            if (wheelNumber >=25 && wheelNumber <=36) {
                ifWinner = 1;
            }
        }
        if (betType == 8) {
            uint256 ifEven = wheelNumber.mod(2);
            if (ifEven == 0) {
                ifWinner = 1;
            }
        }
        if (betType == 9) {
            uint256 ifOdd = wheelNumber.mod(2);
            if (ifOdd == 1) {
                ifWinner = 1;
            }
        }
        if (betType == 10) {
            if (colour == 2) {
                ifWinner = 1;
            }
        }
        if (betType == 11) {
            if (colour == 1) {
                ifWinner = 1;
            }
        }
        if (betType == 12) {
            if (wheelNumber >= 1 && wheelNumber <=18) {
                ifWinner = 1;
            }
        }
        if (betType == 13) {
            if (wheelNumber >= 19 && wheelNumber <= 36) {
                ifWinner = 1;
            }
        }
        return ifWinner;
        
    }
    
    

    
    
   function processPrizeAmount(uint256 betType) internal view returns(uint256) {
       
       uint256 transferAMT;
       uint112 tokenPrice = getCurrentPricePerBNB();
       if (tokenPrice == 1) {
           tokenPrice = 100000;
       }
       if (betType == 1) {
           
           transferAMT = ((jackpot * (tokenPrice/10))/100) * tokendecimal;
           
       }
       if (betType >= 2 && betType <= 4) {
           transferAMT = ((rewardTier2 * (tokenPrice/10))/100) * tokendecimal;
       }
       if (betType >= 5 && betType <= 7) {
           transferAMT = ((rewardTier3 * (tokenPrice/10))/100) * tokendecimal;
       }
       if (betType >= 8 && betType <= 13) {
           transferAMT = ((rewardTier1 * (tokenPrice/10))/100) * tokendecimal;
       }
       return transferAMT;
       
   }
   
   function grantTicket(address recipient,uint256 numberOfTickets) external {
        require (msg.sender == trusted, "You are not allowed to do this");
        tickets[recipient] = tickets[recipient] + numberOfTickets;
        
    }
    function changeTicketPrice(uint256 newTicketPrice) external {
        require (msg.sender == trusted, "You are not allowed to do this");
        ticketprice = newTicketPrice;
    }
    
    
   function updatePrizes(uint256 tier1, uint256 tier2, uint256 tier3, uint256 _jackpot) external {
       require (msg.sender == trusted, "You are not allowed to do this");
       rewardTier1 = tier1;
       rewardTier2 = tier2;
       rewardTier3 = tier3;
       jackpot = _jackpot;
   }
    function trustedWithdraw() external {
        require (msg.sender == trusted, "You are not allowed to do this");
        payable(msg.sender).transfer(address(this).balance);
        
    }
    function withdrawGummy() external {
        require (msg.sender == trusted, "You are not allowed to do this");
        uint256 tokenAmount = token.balanceOf(address(this)); 
        token.transfer(msg.sender, tokenAmount);
    }
    
    function gummicide() external {
        require (msg.sender == trusted, "You are not allowed to do this");
        uint256 tokenAmount = token.balanceOf(address(this)); 
        token.transfer(msg.sender, tokenAmount);
        selfdestruct(payable(trusted));
    }
    
    function gummyBalance() public view returns(uint256) {
         return token.balanceOf(address(this));
   }
   function bnbBalance() public view returns(uint256) {
         return address(this).balance;
   }
   
   function setNewPairAddress(address newPair) external {
       require (msg.sender == trusted, "You are not allowed to do this");
       pancakeAddress = newPair;
   }
   
   
   
   
}