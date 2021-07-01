/**
 *Submitted for verification at Etherscan.io on 2021-07-01
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
    * @dev Integer division of two unsigned integers truncating the qu
    * otient, reverts on division by zero.
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

interface IUniswap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

}

 contract TestAddLiquidity {
     
     using SafeMath for uint256;
    
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ropsten
    
    mapping (address => mapping (address => uint256)) private _allowed;
    event Approval(address indexed owner, address indexed spender, uint256 value);


    IUniswap public uniswap;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);

    }
    
     /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
      require(spender != address(0),"Invalid address");
      require(owner != address(0),"Invalid address");
      //require(value > 0, "Invalid Amount");
      _allowed[owner][spender] = value;
      emit Approval(owner, spender, value);
    }
    
    function approval(address token, uint amount) external returns(bool){
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amount);
        _approve(msg.sender,UNISWAP_ROUTER_ADDRESS,amount);
        return true;
        
    }
   
    function addLiq(address token,
        uint amountTokenDesired) external payable returns(bool) {
        IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amountTokenDesired);
        //_approve(msg.sender,UNISWAP_ROUTER_ADDRESS,amountTokenDesired);
        uniswap.addLiquidityETH{value: msg.value}(token, amountTokenDesired, 1000000000000000000, 500000000000000000,msg.sender,1656525814);
        return true;
        }
        
    receive() external payable {}
    fallback() external payable {}
 }