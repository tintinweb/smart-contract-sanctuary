/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IUniRouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Worker is ReentrancyGuard{
    //address constant public wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    //address public pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant public wbnb = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // rinkeby weth
    address public pancakeRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // rinkeby sushi swap
    address public keeper;

    mapping(address=>uint256) public userBnbBalance; //user BNB balance
    mapping(address=>mapping(address=>uint256)) public userTknBalance; //user->token->balance
    uint256 feeNumerator = 100;
    uint256 feeDenominator = 10000;
    
    receive() external payable nonReentrant{}
    
    modifier onlyKeeper() {
        require(msg.sender == keeper, "not keeper!");
        _;
    }

    constructor(){
        keeper = msg.sender;
    }
    
    function deposit() external payable nonReentrant{
        userBnbBalance[tx.origin] += msg.value;
    }

    function withdrawBNB() external payable nonReentrant{
        uint256 amount = userBnbBalance[msg.sender];
        require(amount>0, "balanceOf BNB is 0");
        userBnbBalance[msg.sender];
        payable(msg.sender).transfer(amount);
    }

    function withdrawTkn(address tkn) external nonReentrant{
        uint256 amount = userTknBalance[msg.sender][tkn];
        require(amount>0, "balanceOf token is 0!");
        userTknBalance[msg.sender][tkn] = 0;
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function buyWork(address tkn, uint256 amt, address userAddr) public payable onlyKeeper{     
        require(userBnbBalance[userAddr]>=amt,"not enough BNB balance");
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = tkn;

        uint256 fee = amt * feeNumerator / feeDenominator; //fee 1%
        uint256 buyAmt = amt - fee;
        userBnbBalance[userAddr] -= amt;
        userBnbBalance[keeper] += fee;//fee to keeper
        
        uint256 tknBalanceBefore = IERC20(tkn).balanceOf(address(this));
        IUniRouter(pancakeRouter).swapExactETHForTokens{ value : buyAmt  }(0, path, address(this), block.timestamp);
        uint256 tknBalanceAfter = IERC20(tkn).balanceOf(address(this));

        require(tknBalanceAfter>tknBalanceBefore, "failed to buy token!");
        userTknBalance[userAddr][tkn] += tknBalanceAfter - tknBalanceBefore;
    }

    function sellWork(address tkn, uint256 amt, address userAddr) public payable onlyKeeper{
        require(userTknBalance[userAddr][tkn]>=amt,"not enough token balance");
        address[] memory path = new address[](2);
        path[0] = tkn;
        path[1] = wbnb;
    
        userTknBalance[userAddr][tkn] -= amt;

        uint256 balanceBef = address(this).balance;
        IERC20(tkn).approve(pancakeRouter, type(uint256).max);
        IUniRouter(pancakeRouter).swapExactTokensForETH(amt, 0, path, address(this), block.timestamp);
        uint256 balanceAft = address(this).balance;

        require(balanceAft>balanceBef, "balance decrease!");
        uint256 bnbAmt = balanceAft - balanceBef;
        uint256 fee = bnbAmt * feeNumerator / feeDenominator;
        userBnbBalance[keeper] += fee;
        userBnbBalance[userAddr] += bnbAmt - fee;
    }
}