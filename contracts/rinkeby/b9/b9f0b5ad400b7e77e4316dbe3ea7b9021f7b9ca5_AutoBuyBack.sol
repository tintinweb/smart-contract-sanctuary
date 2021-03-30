/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AutoBuyBack {
    address public _admin;
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public WETH = uniV2Router02.WETH();
    address public token;
    address[] path;
    
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not admin");
        _;
    }
    
    constructor(address _token) {
        _admin = msg.sender;
        
        require(_token != address(0), "Invalid address");
        
        token = _token;
        
        path.push(WETH);
        path.push(_token);
    }
    
    function exchange() external payable {
        uniV2Router02.swapExactETHForTokens{value:msg.value}(1, path, msg.sender, type(uint256).max);
    }
    
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        _admin = _newAdmin;
    }
    
    function seize(address _token, address to) external onlyAdmin {
        if (_token != address(0)) {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(to, amount);
        }
        else {
            uint256 amount = address(this).balance;
            payable(to).transfer(amount);
        }
    }
    
    fallback () external payable { }
    receive () external payable { }
}