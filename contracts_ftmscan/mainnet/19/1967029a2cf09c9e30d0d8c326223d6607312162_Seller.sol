/**
 *Submitted for verification at FtmScan.com on 2021-12-06
*/

pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Seller {
    IUniswapV2Router02 constant knightDEX = IUniswapV2Router02(0x045312C737a6b7a115906Be0aD0ef53A6AA38106);
    IERC20 constant wftm = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    uint256 constant wftmMantissa = 0.327293456249409 * 1e18;
    IERC20 constant usdt = IERC20(0x049d68029688eAbF473097a2fC38ef61633A3C7A);
    uint256 constant usdtMantissa = 0.065587329585821 * 1e18;
    IERC20 constant usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    uint256 constant usdcMantissa = 0.580719528255744 * 1e18;
    IERC20 constant dknight = IERC20(0x6cc0E0AedbbD3C35283e38668D959F6eb3034856);

    address immutable owner;
    constructor() {
        owner = msg.sender;
    }

    function sell(uint256 amount) external {
        dknight.transferFrom(msg.sender, address(this), amount);
        dknight.approve(address(knightDEX), amount);
        
        address[] memory kToWftm = new address[](2); 
        kToWftm[0] = address(dknight);
        kToWftm[1] = address(wftm);
        knightDEX.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount * wftmMantissa / 1e18,
            0,
            kToWftm,
            msg.sender,
            block.timestamp
        );

        address[] memory kToUSDC = new address[](2); 
        kToUSDC[0] = address(dknight);
        kToUSDC[1] = address(usdc);
        knightDEX.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount * usdcMantissa / 1e18,
            0,
            kToUSDC,
            msg.sender,
            block.timestamp
        );

        address[] memory kToUSDT = new address[](2); 
        kToUSDT[0] = address(dknight);
        kToUSDT[1] = address(usdt);
        knightDEX.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount * usdtMantissa / 1e18,
            0,
            kToUSDT,
            msg.sender,
            block.timestamp
        );
    }


    function inCaseTokensGetStuck(
        address _token
    ) public {
        require(msg.sender == owner);
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}