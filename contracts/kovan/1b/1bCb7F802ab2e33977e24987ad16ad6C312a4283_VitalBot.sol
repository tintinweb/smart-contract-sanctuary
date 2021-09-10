/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity >=0.6.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract VitalBot {

    address internal constant QUICKSWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant QUICKSWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f ;

    uint constant MAX_UINT = 2**256 - 1;
    mapping (address => uint[2]) resv;
    address payable owner;

    event Received(address sender, uint amount);

    constructor() public{
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
       require(
           msg.sender == owner, "Only owner can call this function."
       );
       _;
   }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function deposit() public payable onlyOwner {}

    function getReserves(address[] memory tokenAddress, address[] memory routerAddress) public view returns(uint[] memory resv0, uint[] memory resv1){
        uint[] memory resv0 = new uint[](tokenAddress.length);
        uint[] memory resv1 = new uint[](tokenAddress.length);
        uint resv_0;
        uint resv_1;
        for(uint i=0;i<tokenAddress.length;i++){
            (resv_0, resv_1) = getReserve(tokenAddress[i], routerAddress[i]);
            resv0[i] = resv_0;
            resv1[i] = resv_1;
        }
        // 0x223Fb59bF5C8724d7D7a1Dc4D655D13F293342f8
        return (resv0,resv1);
    }

    function getReserve(address tokenAddress, address routerAddress) public view returns(uint resv0, uint resv1){
        address factoryAddress;
        if(routerAddress == QUICKSWAP_ROUTER_ADDRESS){
            factoryAddress = QUICKSWAP_FACTORY_ADDRESS;
        }

        IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        IUniswapV2Pair pair;
        address pairAddress = factory.getPair(router.WETH(), tokenAddress);
        pair = IUniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        uint resv0;
        uint resv1;
        if(router.WETH() == pair.token0()){
            resv0 = reserve0;
            resv1 = reserve1;
        }
        else
        {
            resv0 = reserve1;
            resv1 = reserve0;
        }
        return (resv0, resv1);
    }

    function buyToken(uint ethAmount, address tokenAddress, address routerAddress) public payable onlyOwner {
        uint buyAmount;

        // if ethAmount > balance then change ethAmount to address balance
        if(ethAmount > address(this).balance){
            buyAmount = address(this).balance;
        }else{
            buyAmount = ethAmount;
        }
        require(buyAmount <= address(this).balance, "Not enough ETH");
        IERC20 token = IERC20(tokenAddress);
        if(token.allowance(address(this), routerAddress) < 1){
            require(token.approve(routerAddress, MAX_UINT),"FAIL TO APPROVE");
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;
        router.swapExactETHForTokens{value: buyAmount}(0, path, address(this), block.timestamp+60);
    }

    function sellToken(address tokenAddress, address routerAddress) public onlyOwner payable {
        IERC20 token = IERC20(tokenAddress);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WETH();
        uint tokenBalance = token.balanceOf(address(this));
        if(token.allowance(address(this), routerAddress) < tokenBalance){
            require(token.approve(routerAddress, MAX_UINT),"FAIL TO APPROVE");
        }
        router.swapExactTokensForETH(tokenBalance, 0, path, address(this), block.timestamp+60);
    }

    function emergencySell(address tokenAddress, address routerAddress) public onlyOwner payable returns (bool status){
        IERC20 token = IERC20(tokenAddress);
        uint tokenBalance = token.balanceOf(address(this));
        if(token.allowance(address(this), routerAddress) < tokenBalance){
            require(token.approve(routerAddress, MAX_UINT),"FAIL TO APPROVE");
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenBalance, 0, path, address(this), block.timestamp+60);
        return true;
    }

    function withdraw() public onlyOwner payable{
        owner.transfer(address(this).balance);
    }

    function withdrawToken(address tokenAddress, address to) public payable onlyOwner returns (bool res){
        IERC20 token = IERC20(tokenAddress);
        bool result = token.transfer(to, token.balanceOf(address(this)));
        return result;
    }
}