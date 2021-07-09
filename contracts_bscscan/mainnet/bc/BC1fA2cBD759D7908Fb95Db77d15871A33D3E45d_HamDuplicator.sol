/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract HamDuplicator {
    address public immutable hamAddress;
    address public immutable usdtAddress;
    address public immutable hamUsdtPair;
    address public immutable pancakeRouter;
    uint256 public constant discountRate = 50;
    uint256 public constant lockPeriod = 365 days;
    uint256 public constant shellCount = 10;
    address public owner;
    uint256 public totalBalance;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public sales;
    mapping (address => uint256) public lastPurchases;
    
    event Buy(address _address, address _referrer, uint256 _usdt, uint256 _reward);

    modifier onlyOwner {
        require(msg.sender == owner, "insufficient privilege");
        _;
    }

    modifier shellBreak {
        require(balances[msg.sender] * 10 <= sales[msg.sender] || block.timestamp >= lastPurchases[msg.sender] + lockPeriod, "locked");
        _;
    }

    // hamAddress: 0x0Be62cf4dD563eC326391b55Ec31e4DBf7db376D
    // usdtAddress: 0x55d398326f99059ff775485246999027b3197955
    // hamUsdtPair: 0x13bBcFaD06a18dE5Cef6F5e8bab0D01480112B2E
    // pancakeRouter: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor(address _hamAddress, address _usdtAddress, address _hamUsdtPair, address _pancakeRouter) {
        hamAddress = _hamAddress;
        usdtAddress = _usdtAddress;
        hamUsdtPair = _hamUsdtPair;
        pancakeRouter = _pancakeRouter;
        owner = msg.sender;

        IERC20 usdt = IERC20(_usdtAddress);
        IERC20 ham = IERC20(_hamAddress);
        usdt.approve(_pancakeRouter, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        ham.approve(_pancakeRouter, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function buy(uint256 _amount, address _referrer) external returns (bool) {
        IERC20 usdt = IERC20(usdtAddress);
        IERC20 pair = IERC20(hamUsdtPair);
        IPancakeRouter router = IPancakeRouter(pancakeRouter);

        address[] memory path = new address[](2);
        path[0] = usdtAddress;
        path[1] = hamAddress;

        // Swap USDT to HAM
        usdt.transferFrom(msg.sender, address(this), _amount);
        uint256 usdtLiq = _amount / 2;
        uint256[] memory amounts = router.swapExactTokensForTokens(usdtLiq, 0, path, address(this), block.timestamp + 20 minutes);

        // Add Liquidity
        uint256 hamLiq = amounts[0];
        router.addLiquidity(usdtAddress, hamAddress, usdtLiq, hamLiq, 0, 0, address(this), block.timestamp + 20 minutes);
        pair.transfer(owner, pair.balanceOf(address(this)));

        // Add Bonus
        uint256 reward = hamLiq * 100 / discountRate;
        balances[msg.sender] = balances[msg.sender] + reward;
        lastPurchases[msg.sender] = block.timestamp;
        totalBalance = totalBalance + reward;
        
        // Referrer Sales
        uint256 totalSales = sales[_referrer] + reward;
        uint256 maxSales = balances[_referrer] * shellCount;
        sales[_referrer] = totalSales <= maxSales ? totalSales : maxSales;

        emit Buy(msg.sender, _referrer, _amount, reward);

        return true;
    }

    function withdraw() external shellBreak returns (bool) {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        sales[msg.sender] = 0;
        lastPurchases[msg.sender] = block.timestamp;
        totalBalance = totalBalance - balance;

        IERC20 ham = IERC20(hamAddress);
        ham.transfer(msg.sender, balance);
        
        return true;
    }
    
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner returns (bool) {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
        return true;
    }
}