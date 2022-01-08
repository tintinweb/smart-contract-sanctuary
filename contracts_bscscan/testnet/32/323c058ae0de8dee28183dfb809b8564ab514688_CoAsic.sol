/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: Unlicensed
//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 bsc testnet router
pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    /*function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);*/
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract CoAsic is IERC20{


    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override immutable totalSupply;
    address public owner;
    address public miningWallet;
    address public devWallet;
    mapping(address=>uint256) public override balanceOf;
    mapping(address=>mapping(address=>uint256)) public override allowance;
    mapping(address=>bool) public pairs;
    address public immutable swapRouter;
    mapping(address=>bool) public excludedFromFees;
    bool public tradingEnabled;
    bool private swapping;
    uint8 public buyTax;
    uint8 public sellTax;
    uint8 public immutable maxTax = 30;
    uint256 toMiningWallet;
    uint256 toDevWallet;
    address private immutable WETH;
    uint256 public swapAmount=10000;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddPair(address indexed router);
    event IncludeToFees(address indexed account);
    event ExcludeFromFees(address indexed account);
    event TradingEnabled();
    event SetBuyTax(uint8 tax);
    event SetSellTax(uint8 tax);
    event SetMiningWallet(address account);
    event SetDevWallet(address account);

    modifier onlyOwner(){
        require(msg.sender==owner,"not owner");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner external{
        require(newOwner!=owner);
        owner = newOwner;
        emit OwnershipTransferred(msg.sender,newOwner);
    }

    function addPairAddress(address pair) onlyOwner external{
        require(pairs[pair]==false);
        pairs[pair] = true;
        excludedFromFees[pair] = true;
        emit AddPair(pair);
    }

    function excludeFromFees(address account) onlyOwner external{
        excludedFromFees[account] = true;
        emit ExcludeFromFees(account);
    }

    function includedToFees(address account) onlyOwner external{
        excludedFromFees[account] = false;
        emit IncludeToFees(account);
    }

    function enableTrading() onlyOwner external{
        require(tradingEnabled==false);
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setBuyTax(uint8 tax) onlyOwner external{
        require(sellTax+tax<=maxTax);
        buyTax = tax;
        emit SetBuyTax(tax);
    }

    function setSellTax(uint8 tax) onlyOwner external{
        require(buyTax+tax<=maxTax);
        sellTax = tax;
        emit SetSellTax(tax);
    }

    function setMiningWallet(address account) onlyOwner external{
        require(miningWallet!=account);
        miningWallet = account;
        emit SetMiningWallet(account);
    }

    function setDevWallet(address account) onlyOwner external{
        require(devWallet!=account);
        devWallet = account;
        emit SetDevWallet(account);
    }

    function setSwapAmount(uint256 amount) onlyOwner external{
        require(amount>=10000);
        swapAmount = amount;
    }

    function liquify(uint256 amount) onlyOwner external{
        swapping = true;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        allowance[address(this)][swapRouter] = amount;
        IUniswapV2Router02(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        swapping = false;
    }
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, address router){
        owner = msg.sender;
        miningWallet = msg.sender;
        devWallet = msg.sender;
        swapRouter = router;
        excludedFromFees[msg.sender] = true;
        excludedFromFees[address(this)] = true;
        uint256 t = (10**_decimals) * _totalSupply;
        (name,symbol,decimals,totalSupply) = (_name,_symbol,_decimals,t);
        balanceOf[owner] = t;
        address weth = IUniswapV2Router01(router).WETH();
        WETH = weth;
        address pair = IUniswapV2Factory(IUniswapV2Router01(router).factory()).createPair(address(this),weth);
        pairs[pair] = true;
    }
    
    function takeFee() private{
        swapping = true;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        allowance[address(this)][swapRouter] = balanceOf[address(this)];
        IUniswapV2Router02(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf[address(this)],
            0,
            path,
            address(this),
            block.timestamp
        );
        swapping = false;
        uint256 toDev = (address(this).balance * toDevWallet).div(toMiningWallet + toDevWallet);
        uint256 toMining = address(this).balance - toDev;
        if(toDev>0){
            payable(devWallet).transfer(toDev);
        }
        if (toMining>0){
            payable(miningWallet).transfer(toMining);
        }
    }
    function _transfer(address from, address to, uint256 amount) private{
        require(balanceOf[from]>=amount,"insuffficient balance");
        uint256 feeAmount;
        if(!swapping && tradingEnabled){
            if(pairs[from] && !excludedFromFees[to] && buyTax > 0){
                //buying
                feeAmount = amount.mul(buyTax)/100;
                toMiningWallet = toMiningWallet.add(feeAmount);
            }
            else if(pairs[to] && !excludedFromFees[from] && sellTax > 0){
                //selling
                feeAmount = amount.mul(sellTax)/100;
                toDevWallet = toDevWallet.add(feeAmount);
            }
            if(feeAmount>0){
                amount = amount - feeAmount;
                balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
            }
        }
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from,to,amount);

        if(balanceOf[address(this)] >= swapAmount){
            takeFee();
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(allowance[sender][msg.sender]>=amount,"Not Approved");
        allowance[sender][msg.sender] = allowance[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    receive() external payable {}
}