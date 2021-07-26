pragma solidity =0.6.6;

import "./PancakeSwap.sol";

contract SwapHelper 
{
    using SafeMath for uint256;
    
    address public owner;
    uint256 public amountResult = 0;
    uint256 public amountOutMin = 0;
    uint public _slippage = 50;
    
    //test
    //address _route = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //address _tokenTo = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //busd
    //address _tokenFrom = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //wbnb
    
    //mainnet
    address _route = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F; //route2
    address _tokenTo = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //busd
    address _tokenFrom = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //wbnb
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD

    address public currentToken;

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
        return swap(amountResult, _tokenFrom, _tokenTo, false);
    }
    
    function swapOutFee() public payable onlyOwner returns (uint256) 
    {
        return swap(amountResult, _tokenFrom, _tokenTo, true);
    }
    
    function swapBNBtoToken(uint amount, address tokenFrom, bool feeSupporting) public payable onlyOwner
    {
        swapIn(amount, WBNB, tokenFrom, _route, feeSupporting);
    }
   
    function swapIn(uint amount, address tokenTo, address tokenFrom, address route, bool feeSupporting) public payable onlyOwner returns (uint256)
    {
        _route = route;
        _tokenTo = tokenTo; 
        _tokenFrom = tokenFrom;
        
        return swap(amount, _tokenTo, _tokenFrom, feeSupporting);
    }
    function swap(uint amount, address tokenTo, address tokenFrom, bool feeSupporting) internal returns (uint256)
    {
        IPancakeRouter02 exchange = IPancakeRouter02(_route);
        IERC20(tokenTo).approve(address(exchange), amount);
   
        address[] memory path = new address[](2);
        path[0] = tokenTo;
        path[1] = tokenFrom;
        
        uint256 deadline = now + 3000;
        
        uint[] memory minOuts = exchange.getAmountsOut(amount, path);
        
        uint256 _amountOut = minOuts[1];
        amountOutMin = _amountOut.mul(50).div(100);
        
       if(feeSupporting==false)
       {
            uint[] memory amounts = exchange.swapExactTokensForTokens(
                amount, 
                amountOutMin, 
                path, 
                address(this), 
                deadline);
                
            amountResult = amounts[1];
       }
       else
       {
            exchange.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, 
                amountOutMin, 
                path, 
                address(this), 
                deadline);
            
            amountResult = IERC20(tokenFrom).balanceOf(address(this));
       }
        currentToken = tokenFrom;
        
        return amountResult;
    }
    function request(address token) public payable onlyOwner 
    {
         IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    function rugPull() public payable onlyOwner 
    {
        IERC20(_tokenTo).transfer(msg.sender, IERC20(_tokenTo).balanceOf(address(this)));
        IERC20(_tokenFrom).transfer(msg.sender, IERC20(_tokenFrom).balanceOf(address(this)));
    }
}