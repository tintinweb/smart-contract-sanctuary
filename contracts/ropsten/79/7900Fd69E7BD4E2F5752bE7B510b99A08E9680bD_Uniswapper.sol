/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract UniInterface {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external virtual payable returns (uint[] memory amounts);
}

contract Uniswapper  {
    address private _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniInterface UniContract = UniInterface(_uniRouter);
    
    constructor() {
        
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts) {
        return UniContract.swapExactETHForTokens(amountOutMin, path, to, deadline);
    }
    
    
}