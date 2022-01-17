// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";
import "./DexUtils.sol";

contract AffinitySwapper is ReentrancyGuard, Ownable {
    IUniswapV2Router02 router;
    address public AFFINITY = 0x0cAE6c43fe2f43757a767Df90cf5054280110F3e;
    uint public fee; // 100 = 1%
    uint public standardization = 10000;
    address payable public feeWallet;
    event BoughtWithBnb(address);
    event BoughtWithToken(address, address); //sender, token
    event ERC20Bought(address tokenAddr, address to, address from, uint bnbVal, uint fee, uint tokenAmt);


    constructor () {
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
        // router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
        fee = 75;
        feeWallet = payable(0x3a339C136F4482f348e3921EDBa8b8Ebd6931f08);
    }

    receive() external payable {
        buyTokens(msg.value, msg.sender);
    }

    function getPath(address token0, address token1) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

    function buyTokens(uint amt, address to) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getPath(router.WETH(), AFFINITY),
            to,
            block.timestamp
        );
        emit BoughtWithBnb(to);
    }

    function buyERC20(address _tokenAddr, address _to) payable public {
        uint feeAmt = msg.value * fee / standardization;
        // v1.7 Fetch target token
        uint tokenAmt = fetchAmountsOut(msg.value - feeAmt, _tokenAddr)[1];

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value - feeAmt}(
            0,
            getPath(router.WETH(), _tokenAddr),
            _to,
            block.timestamp
        );
        feeWallet.transfer(feeAmt);
        
        emit ERC20Bought(_tokenAddr, _to, msg.sender, msg.value, feeAmt, tokenAmt);
    }

    function buyWithToken(uint amt, IERC20 token) external nonReentrant {
        require(token.allowance(msg.sender, address(router)) >= amt);
        try
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amt,
                0,
                getPath(address(token), AFFINITY),
                msg.sender,
                block.timestamp
            ) {
            emit BoughtWithToken(msg.sender, address(token));
        }
        catch {
            revert("Error swapping tokens");
        }
    }

    // Owner functions
    function setFee(uint _val) external onlyOwner {
        require(_val < 1000, "Max Fee is 10%");
        fee = _val;
    }
    function setFeeWallet(address _newFeeWallet) external onlyOwner {
        feeWallet = payable(_newFeeWallet);
    }

    // Utils
    function fetchAmountsOut(uint amountIn, address _tokenAddr) public view returns(uint[] memory amounts) {
        return PancakeLibrary.getAmountsOut(router.factory(), amountIn, getPath(router.WETH(), _tokenAddr));
    }
}