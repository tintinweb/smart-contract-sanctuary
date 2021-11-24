/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IBEP20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Router {
  function addLiquidity(
       address tokenA,
       address tokenB,
       uint amountADesired,
       uint amountBDesired,
       uint amountAMin,
       uint amountBMin,
       address to,
       uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity) {}
  
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {}
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {}
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH) {}
}

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

contract MelviIncTokenPresaleLiquidity {
    using SafeMath for uint256;
    
    address owner;
    
    uint256 public maxContribution = 10000 ether; // Maximum contribution per wallet
    uint256 public tokensForSale; // Amount of tokens available for sale
    uint256 public durationIMO; // Duration of the Initial Melvi Offering
    address public routerLiquidity; // Router to add liquidity
    address public tokensContract; // Token Address
    uint256 public priceToken; // Price per token in BNB
    uint256 public totalRaised; // Total amount raised in BNB
    uint256 public toRaise; // Total amount to raise in BNB
    
    mapping (address => uint) public contributors; // Contributors Dictionary
    
    event Contribution(address contributor, uint256 amount);
    event Reclaimed(address contributor, uint256 amountToken, uint256 returnBNB);
    
    constructor() public {
        owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}
      
    function startIMO(uint256 _tokensForSale, uint256 _priceToken, uint256 _toRaise, address _tokensContract) onlyOwner public {
        tokensForSale = _tokensForSale;
        priceToken = _priceToken;
        tokensContract = _tokensContract;
        toRaise = _toRaise;
        durationIMO = block.timestamp + 5 minutes; //Cambiar a 12 hours
    }
    
    function contribute() public payable {
        require(durationIMO > block.timestamp, "MelviIncTokenPresaleLiquidity: Initial offer Melvi finished");
        require(maxContribution >= contributors[msg.sender].add(msg.value),  "MelviIncTokenPresaleLiquidity: You cannot contribute more than 10 BNB");
        
        contributors[msg.sender] = contributors[msg.sender].add(msg.value);
        totalRaised = totalRaised.add(msg.value);
        
        emit Contribution(msg.sender, msg.value);
    }
    
    function claim() public {
        require(durationIMO < block.timestamp, "MelviIncTokenPresaleLiquidity: Initial offering Melvi has not finished");
        require(contributors[msg.sender] > 0,  "MelviIncTokenPresaleLiquidity: You have not contributed or have already claimed your reward");
        
        IBEP20 MelviTokenContract  = IBEP20(tokensContract); // Token address
        
        uint256 percentageSold = (totalRaised.mul(10000)).div(toRaise);
        
        uint256 realContribution = (contributors[msg.sender].mul(10000)).div(percentageSold);
        
        uint256 returnsBNB = contributors[msg.sender].sub(realContribution);
        uint256 purchasedTokens = (realContribution.div(priceToken)).mul(1 ether);
        
        msg.sender.transfer(returnsBNB);
        
        MelviTokenContract.transfer(msg.sender, purchasedTokens);
        
        delete contributors[msg.sender];
        
        emit Reclaimed(msg.sender, purchasedTokens, returnsBNB);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    
    function setRouterLiquidity(address _routerLiquidity) onlyOwner public{
        require(msg.sender == owner, 'MelviIncTokenPresaleLiquidity: FORBIDDEN');
        routerLiquidity = _routerLiquidity;
    }
    
    function addLiquidity(address tokenA, address tokenB, uint amountA, uint amountB) onlyOwner public {
        Router router  = Router(routerLiquidity); // Router address
        
        IBEP20(tokenA).approve(address(router), amountA);
        IBEP20(tokenB).approve(address(router), amountB);
        
        router.addLiquidity(
           address(tokenA),
           address(tokenB),
           amountA,
           amountB,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function addLiquidityETH(address token, uint amount, uint ETH) onlyOwner public {
        Router router  = Router(routerLiquidity); // Router address
        
        IBEP20(token).approve(address(router), amount);

        router.addLiquidityETH{value: ETH}(
           address(token),
           amount,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, address pair) onlyOwner public {
        Router router  = Router(routerLiquidity); // Router address
        
        IBEP20(pair).approve(address(router), liquidity);
        
        router.removeLiquidity(
           address(tokenA),
           address(tokenB),
           liquidity,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function removeLiquidityETH(address token, uint liquidity, address pair) onlyOwner public {
        Router router  = Router(routerLiquidity); // Router address
        
        IBEP20(pair).approve(address(router), liquidity);
        
        router.removeLiquidityETH(
           address(token),
           liquidity,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
}