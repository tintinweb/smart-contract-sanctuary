pragma solidity 0.8.5;

// SPDX-License-Identifier: MIT

import { IPancakeRouter02 } from "PancakeRouter.sol";
import { ReentrancyGuard } from "ReentrancyGuard.sol";
import "IBEP20.sol";

contract MakaSwapper is ReentrancyGuard {
    IPancakeRouter02 private _router;
    
    address WETH;   // BNB
    address MAKA;  //MAKA Test 0x9000959a575b05920ed9dd722dcf25b959e8ce5e || Main 0x75b429A3D699e6E711BDBC8C0d00cca6a6da4CfE 
    
    event BoughtWithBnb(address);
    event BoughtWithToken(address, address); //sender, token

    //Router TESTNET: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 || other 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    constructor(address router, address token)  {
        //Router MAINNET: 0x10ed43c718714eb63d5aa57b78b54704e256024e
        _router = IPancakeRouter02(router);
        WETH = _router.WETH();
        MAKA = token;
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
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getPath(WETH, MAKA),
            to,
            block.timestamp
        );

        emit BoughtWithBnb(to);
    }

    function buyWithToken(uint amt, IBEP20 token) external nonReentrant {
        require(token.allowance(msg.sender, address(_router)) >= amt);
        try
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amt,
                0,
                getPath(address(token), MAKA),
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