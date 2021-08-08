/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.6;

interface IUniswapV2Router01 {

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function WETH() external pure returns (address);

}

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface ILendingPool {
 

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

}

// USDC 0xe22da380ee6b445bb8273c81944adeb6e8450422

contract TestSimpliFi {
    
    IERC20 constant USDC = IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422);
    
    ILendingPool constant AAVE = ILendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    
    IERC20 constant AUSDC = IERC20(0xe12AFeC5aa12Cf614678f9bFeeB98cA9Bb95b5B0);
    
    IUniswapV2Router01 constant uniswapV2Router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    
    function approveDepositAndAddToLiquidity(uint amount) external {
        USDC.transferFrom(tx.origin, address(this), amount);
        USDC.approve(address(AAVE), amount);
        AAVE.deposit(address(USDC), amount, address(this), 0);
        uint balanceAUSDC = AUSDC.balanceOf(address(this));
        AAVE.withdraw(address(USDC), balanceAUSDC, address(this));
        uint balanceUSDC = USDC.balanceOf(address(this));
        splitAndAddLiquidity(balanceUSDC);
    }
    
    receive() external payable {}
    
    
    function splitAndAddLiquidity(uint256 contractBalance) private {
        uint256 half = contractBalance / 2;
        uint256 otherHalf = contractBalance - (half);
        uint256 initialEthBalance = address(this).balance;

        swapUSDCForEth(half);
        
        uint256 newEthBalance = address(this).balance - initialEthBalance;
        
        addLiquidity(otherHalf, newEthBalance);
    }
    
    function addLiquidity(uint256 USDCAmount, uint256 ethAmount) private {
        USDC.approve(address(uniswapV2Router), USDCAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(USDC),
            USDCAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tx.origin,
            block.timestamp
        );
    }
    
    function swapUSDCForEth(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = uniswapV2Router.WETH();

        USDC.approve(address(uniswapV2Router), amount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}