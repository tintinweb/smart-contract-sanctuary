/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity 0.8.6;

//https://pancake.kiemtienonline360.com/#/swap
//


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
    
    
    Router public routerA = Router(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3));
    Router public routerB = Router(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3));

    uint256 acceptableProfit = 1000000000000000000;
    address owner = 0x0c1CD4Bd4eC3a79CBE7f065988350402d814eA06;
    uint256 percentageLoss = 990;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    

receive() external payable { 
    
}

function initRouterA (address addr) public onlyOwner {
    routerA = Router(addr);
}

function initRouterB (address addr) public onlyOwner {
    routerB = Router(addr);
}


function setAcceptableProfit(uint256 profit) public onlyOwner {
    acceptableProfit = profit;
}

function setPercentageLoss(uint256 loss) public onlyOwner {
    percentageLoss = loss;
}


function swapTest (uint256 amount_in, uint256 amount_out, address[] calldata path) public onlyOwner {
    
    routerA.swapExactTokensForTokens(amount_in, amount_out, path, address(this), 234234);

    
}


function swap (address[] calldata buyPath, address[] memory sellPath) public onlyOwner {
    
    address[] memory reversedSellPath;
    
    for(uint256 i = 0; i < sellPath.length; i++) {
        reversedSellPath[i] = sellPath[ sellPath.length - i - 1];
    }

    swap2(buyPath, reversedSellPath, sellPath);

}

function swap2 (address[] calldata buyPath, address[] memory reversedSellPath, address[] memory sellPath) public onlyOwner {
    
    
    uint256 quantity = 100000000000000000000;
    uint256 buyAmountA = routerA.getAmountsOut(quantity, buyPath)[buyPath.length - 1];
    uint256 buyAmountB = routerB.getAmountsOut(quantity, reversedSellPath)[reversedSellPath.length - 1] * percentageLoss/1000;
    
    IBEP20 token = IBEP20(address(sellPath[0]));
    require(buyAmountB > buyAmountA);
    uint256 profit = buyAmountB - buyAmountA;
    
    if(profit > acceptableProfit) {
            
        routerA.swapExactTokensForTokens(quantity, buyAmountA * percentageLoss / 1000, buyPath, address(this), block.timestamp + 120);
        uint256 tokensToSell = token.balanceOf(address(this));
        uint256 sellAmount = routerB.getAmountsIn(tokensToSell, sellPath)[0] * percentageLoss/1000;
        routerB.swapExactTokensForTokens(tokensToSell, sellAmount, sellPath, address(this), block.timestamp + 120);
            
    }
    
    
}

function withdraw(address tokenaddr) public onlyOwner {
    require(msg.sender == owner);
    IBEP20 token = IBEP20(tokenaddr);
    token.transferFrom(address(this), owner, token.balanceOf(address(this)));
}

function swap3 (address[] calldata buyPath, address[] calldata reversedSellPath, address[] calldata sellPath) public onlyOwner {
    
    
    uint256 quantity = 100000000000000000000;
    uint256 buyAmountA = routerA.getAmountsOut(quantity, buyPath)[buyPath.length - 1];
    uint256 buyAmountB = routerB.getAmountsOut(quantity, reversedSellPath)[reversedSellPath.length - 1] * percentageLoss/1000;
    
    IBEP20 token = IBEP20(address(sellPath[0]));
    require(buyAmountB > buyAmountA);
    uint256 profit = buyAmountB - buyAmountA;
    
    if(profit > acceptableProfit) {
            
        routerA.swapExactTokensForTokens(quantity, buyAmountA * percentageLoss / 1000, buyPath, address(this), block.timestamp + 120);
        uint256 tokensToSell = token.balanceOf(address(this));
        uint256 sellAmount = routerB.getAmountsIn(tokensToSell, sellPath)[0] * percentageLoss/1000;
        routerB.swapExactTokensForTokens(tokensToSell, sellAmount, sellPath, address(this), block.timestamp + 120);
            
    }

}





}