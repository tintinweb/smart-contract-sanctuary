/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ISwapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
}

interface IBEP20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BinanceSmartChainArbitrage {

    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    constructor() {
    }

    function withDrawTokens(address _token) public {
        require(msg.sender == 0xA97F7EB14da5568153Ea06b2656ccF7c338d942f, "you do not deserve these tokens");
        IBEP20(_token).transfer(msg.sender, IBEP20(_token).balanceOf(address(this)));
    }

    function withdrawBNB(uint _amount) public {
        require(msg.sender == 0xA97F7EB14da5568153Ea06b2656ccF7c338d942f, "you do not deserve these tokens");
        payable(msg.sender).transfer(_amount);
    }

    uint256 MAX_INT = 2**256 - 1;

    function getTokenApproved(address _token, address _exchange) public {
        IBEP20(_token).approve(_exchange, MAX_INT);
        IBEP20(_token).approve(_exchange, MAX_INT);
    }

    function doArbitrage(address _token, address _buyFrom, address _sellTo) public payable {
        require(msg.sender == 0xA97F7EB14da5568153Ea06b2656ccF7c338d942f, "Please contact [email protected] at discord to get your contract.");
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = _token;
        uint[] memory cakeAmountOut = ISwapRouter(_buyFrom).getAmountsOut(msg.value, path);
        ISwapRouter(_buyFrom).swapExactETHForTokens{value : msg.value}(
            cakeAmountOut[1],
            path,
            address(this),
            block.timestamp + 5
        );
        address[] memory path_two = new address[](2);
        path_two[0] = _token;
        path_two[1] = WBNB;
        uint remainingBalance = IBEP20(_token).balanceOf(address(this));
        uint[] memory bnbAmountsOut = ISwapRouter(_sellTo).getAmountsOut(remainingBalance, path_two);
        ISwapRouter(_sellTo).swapExactTokensForETH(
            remainingBalance,
            bnbAmountsOut[1],
            path_two,
            address(msg.sender),
            block.timestamp + 5
        );
    }

}