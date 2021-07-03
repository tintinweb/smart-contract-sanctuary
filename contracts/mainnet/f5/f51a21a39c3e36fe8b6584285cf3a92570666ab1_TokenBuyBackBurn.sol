/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address internal _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function WETH() external pure returns (address);
}

contract TokenBuyBackBurn is Ownable {

    IUniswapV2Router02 private uniswapV2Router;
    address public token;
    address public burnAddress;
    mapping(address => bool) authorized;    
    mapping(address => mapping(address => uint256)) private _allowances;
    
    modifier onlyAuthorized() {
        require(authorized[address(msg.sender)], "Not Authroized");
        _;
    }

    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        authorized[address(_owner)] = true;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function setAuthorized(address _address, bool _bool) external onlyOwner {
        authorized[address(_address)] = _bool;
    }

    function buyBackAndBurn() external onlyAuthorized {
        uint ethBalance = address(this).balance;
        swapETHForToken(ethBalance);
    }
    
    function swapETHForToken(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(token);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(ethAmount,path,address(burnAddress),block.timestamp);
    }

    receive() external payable {}
}