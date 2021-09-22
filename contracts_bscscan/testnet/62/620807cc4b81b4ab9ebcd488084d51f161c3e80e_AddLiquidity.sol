/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

 /**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Calculation error");
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Calculation error");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a,"Calculation error");
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a,"Calculation error");
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b != 0,"Calculation error");
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeswap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

 /**
 * @title AddLiquidity
 * @dev AddLiquidity Contract to add liquidity in pancakeswap platform
 */
 contract AddLiquidity {
 
    using SafeMath for uint256;
    
    // variable to store pancakeswap router contract address
    address internal constant PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // variable for total added liquidity in contract
    uint256 public totalAddedLiquidityInContract = 0;

    IPancakeswap public pancakeswap;

    constructor() public {
        pancakeswap = IPancakeswap(PANCAKE_ROUTER_ADDRESS);
    }
    
    // function to add liquidity to pancakeswap platform
    function addLiquidity(address token,uint amountTokenDesired) external payable returns(bool) {
        require(token != address(0),"Invalid Token Address, Please Try Again!!!"); 
        require(amountTokenDesired > 0,"Amount is invalid or zero, Please Try Again!!!");
        IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        IERC20(token).approve(PANCAKE_ROUTER_ADDRESS, amountTokenDesired);
        pancakeswap.addLiquidityETH{value: msg.value}(token, amountTokenDesired, 10000000000000000, 10000000000000000, msg.sender, now + 3600);
        totalAddedLiquidityInContract = totalAddedLiquidityInContract.add(amountTokenDesired);
        return true;
    }
        
    receive() external payable {}
    fallback() external payable {}
 }