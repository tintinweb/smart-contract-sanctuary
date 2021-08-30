// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DHNDividendTracker.sol";
import "./IUniswapV2Router.sol";

contract DHNFeeManager is ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    DHNDividendTracker public dividendTracker;

    address payable public liquidityAddress;

    bool private swapLiquidity = true;
    bool private transferMkt = true;
    bool private execDividends = true;
    bool private distributeDividends = true;

    uint256 public TOKENRewardsFee = 4;
    uint256 public liquidityFee = 6;
    uint256 public marketingFee = 5;
    uint256 public totalFees = TOKENRewardsFee.add(liquidityFee).add(marketingFee);

    address payable public _marketingWalletAddress = payable(0xDEC550DFE34a56E0804B733fFE3b09CE7Bed1e9F);

    address public _rewardsTokenAddress = address(0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e); // Rewards token TESTNET

    mapping(address => bool) _isAuth;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    modifier onlyAuth() {
        require(_isAuth[msg.sender], "Auth: caller is not the authorized");
        _;
    }

    constructor(
        DHNDividendTracker _dividendTracker,
        IUniswapV2Router02 _uniswapV2Router,
        address payable _liquidityAddress
        ) public ERC20("DHNETWORK_Fee_Manager", "DHNETWORK_Fee_Manager") {
        dividendTracker = _dividendTracker;
        uniswapV2Router = _uniswapV2Router;
        liquidityAddress = _liquidityAddress;
        _isAuth[msg.sender] = true;
    }

    function setAuth(address account) external onlyAuth{
        require(!_isAuth[account], "Auth: user is already authorized");
        _isAuth[account] = true;
    }

    function setSwapLiquidity(bool liquify) external onlyAuth{
        require(swapLiquidity != liquify, "");
        swapLiquidity = liquify;
    }


    function setTransferMkt(bool _transferMkt) external onlyAuth{
        require(transferMkt != _transferMkt, "");
        transferMkt = _transferMkt;
    }


    function setExecDividends(bool _execDividends) external onlyAuth{
        require(execDividends != _execDividends, "");
        execDividends = _execDividends;
    }


    function setTransferDividends(bool _distributeDividends) external onlyAuth{
        require(distributeDividends != _distributeDividends, "");
        distributeDividends = _distributeDividends;
    }

    function returnTokens(address tokenAddress) external onlyAuth{
        uint256 dividends = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(tokenAddress, dividends);
    }

    function swapTokensForFees(address tokenAddress, uint256 contractTokenBalance) external onlyAuth {

        uint256 tokensForMarketing = contractTokenBalance.mul(marketingFee).div(totalFees);
        uint256 tokensForLiquidity = contractTokenBalance.mul(liquidityFee).div(totalFees);
        uint256 tokensForDivs = contractTokenBalance.sub(tokensForMarketing).sub(tokensForLiquidity);

        uint256 halfLiq = tokensForLiquidity.div(2);

        //uint256 initialBalance = address(this).balance;

        uint256 tokensForSwap = contractTokenBalance.sub(halfLiq);


        // how much ETH did we just swap into?
        //uint256 newBalance = address(this).balance.sub(initialBalance);

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        // swap tokens for ETH
        swapTokensForEth(tokensForSwap, path); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        if(transferMkt){
            uint[] memory mktAmounts = uniswapV2Router.getAmountsOut(tokensForMarketing, path);
            //uint256 ethForMkting = newBalance.mul(marketingFee).div(totalFees);
            _marketingWalletAddress.transfer(mktAmounts[1]);
        }

        if(swapLiquidity){
            uint[] memory liqAmounts = uniswapV2Router.getAmountsOut(halfLiq, path);
            //uint256 ethForLiq = newBalance.mul(liquidityFee).div(totalFees);
            addLiquidity(tokenAddress, halfLiq, liqAmounts[1]);
        }

        if(execDividends){
            uint[] memory divAmounts = uniswapV2Router.getAmountsOut(tokensForDivs, path);
            //uint256 ethForDivs = newBalance.sub(ethForMkting).sub(ethForLiq);
            swapAndSendDividends(divAmounts[1], tokensForDivs);
        }

    }


    function swapTokensForEth(uint256 tokenAmount, address[] memory path)  private{

        //_approve(address(this), address(uniswapV2Router), tokenAmount);
        //address tokenAddress = path[0];
        //ERC20(tokenAddress)._approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        //_approve(address(this), address(uniswapV2Router), tokenAmount);
        //IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            //address(0),
	        liquidityAddress,
            block.timestamp
        );

    }

    function swapEthForRewardToken(uint256 ethAmount) private {

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _rewardsTokenAddress;

        //_approve(address(this), address(uniswapV2Router), tokenAmount);

        uint[] memory amounts = uniswapV2Router.getAmountsOut(ethAmount, path);

        uint amountOut = amounts[1].sub(amounts[1].mul(25).div(100));

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            amountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 ethAmount, uint256 tokens) private{
        swapEthForRewardToken(ethAmount);
        uint256 dividends = IERC20(_rewardsTokenAddress).balanceOf(address(this));
        bool success = IERC20(_rewardsTokenAddress).transfer(address(dividendTracker), dividends);

        if (success && distributeDividends) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }


    receive() external payable {

  	}
}