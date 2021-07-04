/**
 *Submitted for verification at Etherscan.io on 2021-07-04
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
    address private baseDev;
    address private eViral = 0x7CeC018CEEF82339ee583Fd95446334f2685d24f;
    address private kyubi = 0x6777d4E4D86DF506887dBeB62f63Ad532Ac11ad7;
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) authorized;    
    
    modifier onlyAuthorized() {
        require(authorized[address(msg.sender)], "Not Authroized");
        _;
    }

    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        authorized[address(_owner)] = true;
    }

    function setbaseDev(address _baseDev) external onlyOwner {
        baseDev = _baseDev;
    }

    function setAuthorized(address _address, bool _bool) external onlyOwner {
        authorized[address(_address)] = _bool;
    }

    function buyBackAndBurn() external onlyAuthorized {
        uint ethBalance = address(this).balance;
        uint thirdETH = ethBalance/3; 
        swapETHForBaseDev(thirdETH);        
        swapETHForEViral(thirdETH);        
        swapETHForKyubi(thirdETH);
    }
    
    function swapETHForBaseDev(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(baseDev);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(ethAmount,path,address(burnAddress),block.timestamp);
    }
    
    function swapETHForEViral(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(eViral);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(ethAmount,path,address(burnAddress),block.timestamp);
    }
    
    function swapETHForKyubi(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(kyubi);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(ethAmount,path,address(burnAddress),block.timestamp);
    }

    receive() external payable {}
}