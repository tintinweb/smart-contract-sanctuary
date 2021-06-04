/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT
// pragma solidity ^0.7.0;


// //import the ERC20 interface
// interface IERC20 {
//     function totalSupply() external view returns (uint);
//     function balanceOf(address account) external view returns (uint);
//     function transfer(address recipient, uint amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint);
//     function approve(address spender, uint amount) external returns (bool);
//     function transferFrom(
//         address sender,
//         address recipient,
//         uint amount
//     ) external returns (bool);
//     event Transfer(address indexed from, address indexed to, uint value);
//     event Approval(address indexed owner, address indexed spender, uint value);
// }

// interface IUniswapV2Router01 {
//     function factory() external pure returns (address);
//     function WETH() external pure returns (address);

//     function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
//     external payable returns (uint amountToken, uint amountETH, uint liquidity);
// }

// contract addliquidity {
    
//     //address of the uniswap v2 router
//     address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
//     function addLiquidity(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (bool) {
//     //IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
//     IERC20(token).approve(UNISWAP_V2_ROUTER, amountTokenDesired);
//     IUniswapV2Router01(UNISWAP_V2_ROUTER).addLiquidityETH{value: msg.value}(token,amountTokenDesired,amountTokenMin,amountETHMin,to,deadline);
//     return true;
//         //return(amountToken,amountETH,liquidity);
//     }
        
    
// }


pragma solidity ^0.6.6;

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
    
    mapping (address => mapping (address => uint256)) private _allowed;
    event Approval(address indexed owner, address indexed spender, uint256 value);


    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ropsten

    IUniswap public uniswap;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
    }
    
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
      _approve(msg.sender, spender, value);
      return true;
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
      require(value > 0, "Invalid Amount");
      _allowed[owner][spender] = value;
      emit Approval(owner, spender, value);
    }
    
    function addLiq(address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external payable {
            
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amountTokenDesired);
        //IERC20(token).approve(address(this), amountTokenDesired);
        //IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        //approve(UNISWAP_ROUTER_ADDRESS,amountTokenDesired);
        //IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        uniswap.addLiquidityETH{value:msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
    }
    
      
}