/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

pragma solidity 0.8.6;


interface Router {
    
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;    
    
    function getAmountsOut(uint amountIn, address[] memory path) external  view returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
    
}


interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract root {

    uint256 public acceptableProfit = 1000000000000000000;
    address public owner = msg.sender;
    uint256 public percentageLoss = 990;
    uint256 public buyQuantity = 100000000000000000000;
    uint256 public deadline = 120;
    
    address to = address(this);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
    }
    
    receive() external payable {}

    
    function setTo(address _to) public onlyOwner {
        to = _to;
    }
    
    function setDeadline(uint256 _deadline) public onlyOwner {
        deadline = _deadline;
    }
    
    function setAcceptableProfit(uint256 profit) public onlyOwner {
        acceptableProfit = profit;
    }
    
    function setBuyQuantity(uint256 _quantity) public onlyOwner {
        buyQuantity = _quantity;
    }
    
    function setPercentageLoss(uint256 loss) public onlyOwner {
        percentageLoss = loss;
    }

    function setOwner(address addr) public onlyOwner {
        owner = addr;
    }
    
    function withdraw(address tokenaddr) public onlyOwner {
        IBEP20 token = IBEP20(tokenaddr);
        token.transfer(owner, token.balanceOf(to));
    }

    function approve2(address tokenaddr, address routerAddr) public onlyOwner {
        IBEP20 token = IBEP20(tokenaddr);
        token.approve(routerAddr, 2**256 - 1);
    }    

    function allowance (address tokenaddr, address routerAddr) public view returns (uint256){
        IBEP20 token = IBEP20(tokenaddr);
        return token.allowance(address(this), routerAddr);
    }
    
    function removeApproval(address tokenaddr, address routerAddr) public onlyOwner {
        IBEP20 token = IBEP20(tokenaddr);
        token.approve(routerAddr, 0);
    }        

    
    function getTokenBalance (address addr) public view returns (uint256){
        IBEP20 token = IBEP20(addr);
        return token.balanceOf(address(this));
    }
 
    function estProfit (address _addrA, address _addrB,address[] calldata buyPath, address[] calldata sellPath) public view returns (uint256){
        uint256 buyAmountA = Router(_addrA).getAmountsOut(buyQuantity, buyPath)[buyPath.length - 1];
        uint256 _profit = Router(_addrB).getAmountsOut(buyAmountA, sellPath)[sellPath.length - 1];
        if(_profit > buyQuantity) return _profit - buyQuantity;
        return 0;
    }
        
    function swap (address _addrA, address _addrB, address[] calldata buyPath, address[] calldata sellPath) public onlyOwner {
        Router _routerA = Router(_addrA);
        Router _routerB = Router(_addrB);
        uint256 buyAmount = _routerA.getAmountsOut(buyQuantity, buyPath)[buyPath.length - 1];
        IBEP20 tokenToSell = IBEP20(sellPath[0]);
        IBEP20 tokenToSpend = IBEP20(buyPath[0]);
        uint256 startingAmount = tokenToSpend.balanceOf(to);
        _routerA.swapExactTokensForTokens(buyQuantity, buyAmount * percentageLoss / 1000, buyPath, to, block.timestamp + deadline);
        uint256 tokensToSell = tokenToSell.balanceOf(to);
        require(tokensToSell > 0);
        uint256 sellAmount = _routerB.getAmountsIn(tokensToSell, sellPath)[0] * percentageLoss/1000;
        _routerB.swapExactTokensForTokens(tokensToSell, sellAmount, sellPath, to, block.timestamp + deadline);
        require(tokenToSpend.balanceOf(to) > startingAmount + acceptableProfit);
    }
    
    function estProfit2 (address _addrA, address _addrB,address[] calldata buyPath, address[] calldata sellPath, uint256 _buyQuantity) public view returns (uint256){
        uint256 buyAmountA = Router(_addrA).getAmountsOut(_buyQuantity, buyPath)[buyPath.length - 1];
        uint256 _profit = Router(_addrB).getAmountsOut(buyAmountA, sellPath)[sellPath.length - 1];
        if(_profit > _buyQuantity) return _profit - _buyQuantity;
        return 0;
    }
        
    function swap2 (address _addrA, address _addrB, address[] calldata buyPath, address[] calldata sellPath, uint256 _buyQuantity) public onlyOwner {
        Router _routerA = Router(_addrA);
        Router _routerB = Router(_addrB);
        uint256 buyAmount = _routerA.getAmountsOut(_buyQuantity, buyPath)[buyPath.length - 1];
        IBEP20 tokenToSell = IBEP20(sellPath[0]);
        IBEP20 tokenToSpend = IBEP20(buyPath[0]);
        uint256 startingAmount = tokenToSpend.balanceOf(to);
        _routerA.swapExactTokensForTokens(_buyQuantity, buyAmount * percentageLoss / 1000, buyPath, to, block.timestamp + deadline);
        uint256 tokensToSell = tokenToSell.balanceOf(to);
        require(tokensToSell > 0);
        uint256 sellAmount = _routerB.getAmountsIn(tokensToSell, sellPath)[0] * percentageLoss/1000;
        _routerB.swapExactTokensForTokens(tokensToSell, sellAmount, sellPath, to, block.timestamp + deadline);
        require(tokenToSpend.balanceOf(to) > startingAmount + acceptableProfit);
    }
    
}