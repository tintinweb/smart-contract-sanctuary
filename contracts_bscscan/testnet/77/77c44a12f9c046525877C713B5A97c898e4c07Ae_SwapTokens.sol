// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Imports
import "./ReentrancyGuard.sol";

// Interfaces
interface IERC20 {
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SwapTokens is ReentrancyGuard {
    IERC20 public token; // Token "from".
    IDEXRouter router; // Router del swap.
    address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // WBNB Testnet.

    constructor(IERC20 _token) {
        token = _token;
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Testnet
    }

    function swapTokens(uint _amount, address _newToken) public nonReentrant {
        require(_amount > 0, "Incorrect Amount.");
        
        uint _tokenBalance = token.balanceOf(msg.sender);
        require(_tokenBalance >= _amount, "Insufficient Balance.");

        uint balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _amount); // Envía los tokens desde la cuenta del inversor a la del contrato.
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter > balanceBefore, 'Transfer Error'); // Comprueba que el balance del contrato ha aumentado.

        address[] memory path = new address[](3);
        path[0] = address(token);
        path[1] = router.WETH();
        path[2] = _newToken;

        token.approve(address(router), _amount);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount, 
            0, 
            path, 
            address(msg.sender), 
            block.timestamp
        );
    }

}