/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AutoSwap {
    address private _admin;
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public token;
    
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not admin");
        _;
    }
    
    constructor(address _token) {
        _admin = msg.sender;
        token = _token;
    }
    
    function exchange() external payable returns (bool) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        uniV2Router02.swapExactETHForTokens{value:msg.value}(1, path, msg.sender, type(uint256).max);
        return true;
    }
    
    function setAdmin(address newAdmin) external onlyAdmin {
        _admin = newAdmin;
    }
    
    function seize(address _token, address to) external onlyAdmin returns (bool) {
        if (_token != address(0)) {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(to, amount);
        }
        else {
            uint256 amount = address(this).balance;
            payable(to).transfer(amount);
        }
        return true;
    }
    
    fallback () external payable { }
    receive () external payable { }
}