/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.2;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract PreSale{

    using SafeMath for uint256;

    address public immutable creator;
    address public immutable token;
    address public immutable router;
    uint256 public immutable start;
    uint256 public immutable end;
    uint256 public totalDeposits;
    mapping(address=>uint256) public deposits;//eth deposits
    uint256 public totalClaimed;//eth claimed
    uint256 public tokensClaimed;//tokens claimed
    mapping(address=>uint256) public claims;//tokens claimed
    uint256 public immutable softCap;
    uint256 public immutable hardCap;
    uint256 public immutable maxBuy;
    uint8 public immutable toLiquidity;//percent of ETH that goes to liquidity
    uint8 public result;// 0=unfinished, 1=failed, 2=success
    address[2] private path;

    constructor(address _token, address _router, uint16 _maxBuy, uint16 _softCap, uint16 _hardCap, uint256 _start, uint256 _end, uint8 liquidityPercentage){
        require(liquidityPercentage<100 && liquidityPercentage >0);
        require(_start < _end && _end > block.timestamp);
        require(_softCap <= _hardCap);
        creator = msg.sender;
        token = _token;
        router = _router;
        start = _start;
        end = _end;
        softCap = _softCap*10**18;
        hardCap = _hardCap*10**18;
        toLiquidity = liquidityPercentage;
        maxBuy = _maxBuy*10**18;
    }

    function deposit() external payable{
        require(msg.value > 0);
        uint256 _totalDeposits = msg.value.add(totalDeposits);
        require(_totalDeposits <= hardCap,"exceeded hardcap");
        uint256 _deposit = deposits[msg.sender].add(msg.value);
        require(_deposit <= maxBuy,"exceeded max buy");
        totalDeposits = _totalDeposits;
        deposits[msg.sender] = _deposit;
    }
    function finalize() external{
        require(result==0,"already finalized");
        require(hardCap==totalDeposits || end < block.timestamp,"unfinished");
        if(totalDeposits < softCap){
            result = 1;//fail
            IERC20(token).transfer(creator,IERC20(token).balanceOf(address(this)));
        }
        else{
            result = 2;
            address WETH = IUniswapV2Router01(router).WETH();
            address factory = IUniswapV2Router01(router).factory();
            path[0] = WETH;
            path[1] = token;
            try IUniswapV2Factory(factory).createPair(WETH,token){

            } catch{}
        }
    }
    function tokensToClaim() public view returns(uint256) {
        return IERC20(token).balanceOf(address(this)).mul(toLiquidity).div(100);
    }
    function tokensToClaim(address addy) public view returns(uint256) {
        return deposits[addy].mul(tokensToClaim()).div(totalDeposits);
    }
    function claim() external{
        require(result!=0,"unfinished");
        uint256 amount = tokensToClaim(msg.sender);
        uint256 balance = deposits[msg.sender];
        if(amount==0 || result==1){
            //refund
            totalDeposits = totalDeposits.sub(balance);
            deposits[msg.sender]=0;
            payable(msg.sender).transfer(balance);
            return;
        }
        //add to liquity, send tokens to msg.sender, send eth to creator
        require(claims[msg.sender]==0);
        uint256 tokens = IERC20(token).balanceOf(address(this)).mul(balance).div(totalDeposits-totalClaimed);
        uint256 liqTokens = tokens.mul(toLiquidity).div(100);
        uint256 liqEth = deposits[msg.sender].mul(toLiquidity).div(100);
        IUniswapV2Router01(router).addLiquidityETH{value:liqEth}(
            token,
            liqTokens,
            0,
            0,
            creator,
            type(uint256).max
        );
        claims[msg.sender] = tokens.sub(liqTokens);
        totalClaimed = totalClaimed.add(balance);
        tokensClaimed = tokensClaimed.add(claims[msg.sender]);
        IERC20(token).transfer(msg.sender,claims[msg.sender]);
        payable(creator).transfer(balance.sub(liqEth));
    }
}
//bsc testnet wbnb 0xae13d989dac2f0debff460ac112a837c89baa7cd
//bsc testnet router 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
//bsc testnet presale https://testnet.bscscan.com/address/0xdb4293deec92392386d12a046e1f9a2cd3d79520