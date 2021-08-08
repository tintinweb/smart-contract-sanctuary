/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.7.0;

interface IPancakeswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
        function WETH() external pure returns (address);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}



contract TradeBot {
    //Array mit whitelisted Accounts, die die swap() methode benutzen dürfen?
    address payable public manager;
    IPancakeswap pancakeswap;
    
    constructor(address _pancakeswap) {
        manager = msg.sender;
        pancakeswap = IPancakeswap(_pancakeswap);
    }
    
    function giveWBNB()public payable{
        require(msg.value > 0);
    }
    
    function getWBNB(uint amount) public restricted payable {
        manager.transfer(amount);
    }
    
    function swap(address token1, address token2, uint amountIn, uint amountOutMin, uint deadline) external restrictedv2{
            //IERC20(token1).transferFrom(msg.sender, address(this), amountIn);
            address[] memory path = new address[](2);
            path[0] = token1;
            path[1] = token2;
            IERC20(token1).approve(address(pancakeswap), amountIn);
            pancakeswap.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),      //msg.sender,
                deadline
            );
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    modifier restrictedv2() {
        _;
    }
}