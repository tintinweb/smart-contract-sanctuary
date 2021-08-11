//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IPancakeSwapRouterV2.sol";
import "./IBEP20.sol";
import "./Context.sol";


pragma solidity >=0.6.0 <0.8.0;
contract Banks is Ownable {
    IPancakeSwapRouterV2 public pancakeSwapRouterV2;
    address public tokenAddress;
    
    event Deposited(address indexed payee, uint256 weiAmount);
    
    constructor() public {
        IPancakeSwapRouterV2 _pancakeSwapRouterV2 = IPancakeSwapRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeSwapRouterV2 = _pancakeSwapRouterV2;

    }
    
    function deposit() public payable onlyOwner {
        emit Deposited(msg.sender, msg.value);
    }
    
    function setTokensAddress(address Bep20Token) public onlyOwner {
        tokenAddress = Bep20Token;
    }
    
    function withdrawRemainingBEP20Token(address account) public onlyOwner {
        uint256 balance = IBEP20(tokenAddress).balanceOf(address(this));
        IBEP20(tokenAddress).transfer(account, balance);
    }
    
    function withdrawRemainingETH(address payable account) public onlyOwner {
        account.transfer(address(this).balance);
    }
    
    function swapETHForTokens() public {
        uint256 amount = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouterV2.WETH();
        path[1] = address(this);

      // make the swap
        pancakeSwapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            address(this), // Burn address
            block.timestamp
        );
    }
    
    function swapTokensForEth() public {
        // generate the uniswap pair path of token -> weth
        uint256 tokenAmount = IBEP20(tokenAddress).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapRouterV2.WETH();

        IBEP20(tokenAddress).approve(address(pancakeSwapRouterV2), tokenAmount);

        // make the swap
        pancakeSwapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }
    
}