//Make the Lender bankrupt

pragma solidity 0.8.0;

import "./Lender.sol";

contract Token {
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public dropped;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1_000_000 ether;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function getBalanceOf(address who) external view returns (uint){
        return balanceOf[who];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from != msg.sender) {
            allowance[from][to] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract FlashLoan {

    WETH9 public constant weth = WETH9(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    constructor() payable{
        require(msg.value == 0.1 ether);
        weth.deposit{value : msg.value}();
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = weth.balanceOf(address(this));
        require(amount <= balanceBefore, "Not enough token balance");

        weth.transfer(msg.sender, amount);

        (bool success,) = msg.sender.call(
            abi.encodeWithSignature(
                "receiveFlashLoan(uint256)",
                amount
            )
        );
        require(success, "External call failed");

        require(weth.balanceOf(address(this)) >= balanceBefore, "Flash loan not paid back");
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Setup {
    WETH9 public constant weth = WETH9(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    Token public token;
    IUniswapV2Pair public pair;
    Lender public lender;
    FlashLoan public flashloanPool;

    uint256 constant DECIMALS = 1 ether;
    uint256 totalBefore;

    constructor() payable {
        require(msg.value == 0.105 ether);
        weth.deposit{value : 0.005 ether}();
        
        token = new Token();
        pair = IUniswapV2Pair(factory.createPair(address(weth), address(token)));
        lender = new Lender(pair, ERC20Like(address(token)));
        token.transfer(address(lender), 500_000 * DECIMALS);

        weth.transfer(address(pair), 0.0025 ether);
        token.transfer(address(pair), 500_000 * DECIMALS);
        pair.mint(address(this));

        weth.approve(address(lender), type(uint256).max);
        lender.deposit(0.0025 ether);
        lender.borrow(250_000 * DECIMALS);

        totalBefore = weth.balanceOf(address(lender)) + token.balanceOf(address(lender)) / lender.rate();

        flashloanPool = (new FlashLoan){value : 0.1 ether}();
    }

    function isSolved() public view returns (bool) {
        return weth.balanceOf(address(lender)) < 0.0002 ether;
    }
}