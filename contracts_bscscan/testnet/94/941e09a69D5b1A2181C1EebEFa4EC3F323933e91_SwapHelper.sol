pragma solidity =0.6.6;

import "./PancakeSwap.sol";

contract SwapHelper 
{
    address public owner;
    uint256 public amountResult = 0;
    
    address _route = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address _tokenTo = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //busd
    address _tokenFrom = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //wbnb

    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function swapOut() public payable onlyOwner returns (uint256) 
    {
        return swap(amountResult, _tokenFrom, _tokenTo);
        
        //IERC20(_tokenTo).transfer(msg.sender, IERC20(_tokenTo).balanceOf(address(this)));
        //IERC20(_tokenFrom).transfer(msg.sender, IERC20(_tokenFrom).balanceOf(address(this)));
    }
    
    function swapIn(uint amount, address tokenTo, address tokenFrom, address route) public payable onlyOwner returns (uint256)
    {
        _route = route;
        _tokenTo = tokenTo; 
        _tokenFrom = tokenFrom;
        
        return swap(amount, _tokenTo, _tokenFrom);
    }
    function swap(uint amount, address tokenTo, address tokenFrom) internal returns (uint256)
    {
        
        IPancakeRouter02 exchange = IPancakeRouter02(_route);
        IERC20(tokenTo).approve(address(exchange), amount);
         
        address[] memory path = new address[](2);
        path[0] = tokenTo;
        path[1] = tokenFrom;
        
        uint256 deadline = now + 3000;
         
        uint[] memory amounts = IPancakeRouter02(exchange).swapExactTokensForTokens(
            amount, 
            1, 
            path, 
            address(this), 
            deadline);
        
        amountResult = amounts[1];
        return amountResult;

    }
    function rugPull() public payable onlyOwner 
    {
        IERC20(_tokenTo).transfer(msg.sender, IERC20(_tokenTo).balanceOf(address(this)));
        IERC20(_tokenFrom).transfer(msg.sender, IERC20(_tokenFrom).balanceOf(address(this)));
    }
}