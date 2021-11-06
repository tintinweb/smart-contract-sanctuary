// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter02.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";

contract AffinitySwapper is ReentrancyGuard {
    IPancakeRouter02 router;
    address constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant AFFINITY = 0x0cAE6c43fe2f43757a767Df90cf5054280110F3e;
    event BoughtWithBnb(address);
    event BoughtWithToken(address, address); //sender, token


    constructor () public  {
        router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    receive() external payable {
        buyTokens(msg.value, msg.sender);
    }

    function getPath(address token0, address token1) internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

    function buyTokens(uint amt, address to) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getPath(WETH, AFFINITY),
            to,
            block.timestamp
        );

        emit BoughtWithBnb(to);
    }

    function buyWithToken(uint amt, IBEP20 token) external nonReentrant {
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
}