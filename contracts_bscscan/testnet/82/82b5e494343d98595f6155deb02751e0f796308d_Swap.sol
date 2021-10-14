/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface Router {
    function WETH() external pure returns (address);
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);
}

contract Swap {
    Router router;
    address WETH;
    
    constructor() {
        router = Router(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // pancake router testnet
    }
    
    function swap() external payable {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = 0x8a9424745056Eb399FD19a0EC26A14316684e274; // DAI token testnet
        
        uint256 _deadline = block.timestamp + 300;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(0, path, 0xFf6bE29c1AcFE3202761c213345198d0e3039F4a, _deadline);
    }

    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        
        uint256[] memory amountOutMins = router.getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }
}