/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

pragma solidity ^0.7.2;

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
}

contract TestAddLiquidity {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 

    IUniswap public uniswap;
    mapping(address => uint) public balances;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
    }

    fallback() external payable { }

    function updateBalance(uint newBalance, address sender) public {
        balances[sender] = balances[sender] + newBalance;
   }
    
    function addLiq(address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external payable {

        // updateBalance(amountTokenDesired, to);
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amountTokenDesired);
        uniswap.addLiquidityETH{ value: msg.value }(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            deadline
)       ;
    }
      
}