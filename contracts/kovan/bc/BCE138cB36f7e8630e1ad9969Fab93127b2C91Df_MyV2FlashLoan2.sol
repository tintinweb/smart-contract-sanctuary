/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

//SPDX-License-Identifier: UNLICENCED
//This uses tokens of KOVAN testnet
//To get testnet tokens:  https://testnet.aave.com/faucet
pragma solidity 0.6.12;




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  
  function approve(address spender, uint256 amount) external returns (bool);

}

interface IUniswapV2Router01 {
    
   

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
        ) external returns (uint[] memory amounts);

    
    
}


contract MyV2FlashLoan2 {
    
    address public LENDING_POOL = 0x9FE532197ad76c5a68961439604C037EB79681F0;
    address public UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public token1 = 0xBf50BfA20D4326cB5255024B133A2EE57cdB7519;
    
    uint[] public test;
    
    receive() external payable {}

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        returns (bool)
    {

        //
        // This contract now has the funds requested.
        //first give uniswap router approval to cut tokens from this smart contract
        IERC20(assets[0]).approve(UniswapV2Router02, (amounts[0] * 100));
        
        
        //now swap usdc to eth in uniswap
        address[] memory path = new address[](2);
        path[0] = assets[0];    //dai
        path[1] = token1;       //eat
        uint[] memory amountsFromSwap1 = IUniswapV2Router01(UniswapV2Router02).swapExactTokensForTokens((amounts[0] * 5 /100), 0, path, address(this), 1111111111111111111111111);
        
        uint[] memory amountsFromSwap2 = IUniswapV2Router01(UniswapV2Router02).swapExactTokensForTokens((amounts[0] * 95 /100), 0, path, address(this), 1111111111111111111111111);
        
        
        test = amountsFromSwap1;
        
        //give approval again to uniswap router
        IERC20(token1).approve(UniswapV2Router02, (amountsFromSwap1[1] + amountsFromSwap2[1]));
        
        //now swap hex to usdc
        address[] memory path2 = new address[](2);
        path2[0] = token1;    //hex
        path2[1] = assets[0]; //usdc
        IUniswapV2Router01(UniswapV2Router02).swapExactTokensForTokens(amountsFromSwap1[1], 0, path2, address(this), 1111111111111111111111111);
        
        IUniswapV2Router01(UniswapV2Router02).swapExactTokensForTokens(amountsFromSwap2[1], 0, path2, address(this), 1111111111111111111111111);
        
        
        
        
        
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        
        return true;
    }
}