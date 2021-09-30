/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >= 0.8.0;

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
    function withdraw(uint wad) external;
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

contract PrivmVPNSale{

    event Order(address indexed Account,address indexed Token,uint24 indexed index);
    event AffiliateOrder(address indexed Affiliate);
    event AddedToken(address indexed Token);
    event UnbannedToken(address indexed Token);
    event BannedToken(address indexed Token);
    event AddedRouter(address indexed Router);
    event RemovedRouter(address indexed Router);

    string public pubKey;//public key
    address private immutable owner;//contract creator

    //mapping(address=>bool) private admin;//allowed to make orders to possibly add other functionality
    address public router;//main router

    mapping(address=>bool) public routers;//allowed alternative routers

    address public USD;//stablecoin used to set token prices

    address private immutable WETH;//payments are converted to WETH

    uint256 public price = 10 * 10**18;//price in USD

    address public bank;

    uint8 public affiliatePercentage=50;
    
    uint256 initFee = 1 ether;
    mapping(address=>bool) public init;
    mapping(address=>bool) public banned;


    mapping(uint24=>string) public orders;
    uint24 orderIndex;
    bool paused;

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    modifier payBank(){
        //payable(bank).transfer(address(this).balance);
        //pass the rest of gas on
        _;
        require(address(this).balance>0);
        bank.call{value: address(this).balance, gas: gasleft()};
    }
    modifier payAffiliate(address affiliate){
        //pay affiliate
        _;
        payable(affiliate).transfer(address(this).balance*100/affiliatePercentage);
        emit AffiliateOrder(affiliate);
    }
    modifier checkToken(address token){
        //payable(bank).transfer(address(this).balance);
        //pass the rest of gas on
        require(init[token]==true&&banned[token]==false);
        _;
    }
    constructor(address _router, address _stablecoin){
        owner=msg.sender;
        router=_router;
        USD=_stablecoin;
        WETH = IUniswapV2Router02(_router).WETH();
        bank=msg.sender;
        init[_stablecoin]=true;
        emit AddedRouter(_router);
        emit AddedToken(_stablecoin);
    }

    function updatePubKey(string memory key)onlyOwner external{
        pubKey=key;
    }
    function updateBank(address addy)onlyOwner external{
        bank=addy;
    }
    function updateRouter(address addy)onlyOwner external{
        router=addy;
    }
    function updateInitFee(uint256 amount)onlyOwner external{
        initFee=amount;
    }
    function initToken(address token) external payable{
        require(msg.value<=initFee||owner==msg.sender);
        if(address(this).balance>0){
            payable(bank).transfer(address(this).balance);
        }
        init[token]=true;
        emit AddedToken(token);
    }
    function banToken(address token)onlyOwner external{
        banned[token]=true;
        emit BannedToken(token);
    }
    function unbanToken(address token)onlyOwner external{
        banned[token]=false;
        emit UnbannedToken(token);
    }
    function updateAffiliatePercentage(uint8 percent)onlyOwner external{
        require(percent<100&&percent>0);
        affiliatePercentage=percent;
    }
    function approveRouter(address _router)onlyOwner external{
        routers[_router]=true;
        emit AddedRouter(_router);
    }
    function rejectRouter(address _router)onlyOwner external{
        routers[_router]=false;
        emit RemovedRouter(_router);
    }
    function updateUSD(address token)onlyOwner external{
        USD=token;
    }
    function _order(string memory email,address Token) internal{
        orders[orderIndex]=email;
        emit Order(msg.sender,Token,orderIndex);
        orderIndex++;
    }

    function orderETH(string memory email) payBank payable external{
        //order with ETH
        require(msg.value>=getPrice());
        _order(email,address(0));
    }
    function orderETH(string memory email,address affiliate) payAffiliate(affiliate) payBank payable external{
        //order with ETH and affilite allowing .01% difference
        require(msg.value>=getPrice());
        _order(email,address(0));
    }
    function orderToken(string memory email,address token)checkToken(token) payBank external{
        //order with token
        uint256 amount = getPrice(token);
        require(IERC20(token).transferFrom(msg.sender,address(this),amount));
        if(token==WETH){
            IERC20(token).withdraw(amount);
        }
        else{
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).approve(router,amount);
            IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp+86400
                );
        }
        _order(email,address(0));
    }
    function orderToken(string memory email,address token,address affiliate)checkToken(token) payAffiliate(affiliate) payBank external{
        //order with token
        uint256 amount = getPrice(token);
        require(IERC20(token).transferFrom(msg.sender,address(this),amount));
        if(token==WETH){
            IERC20(token).withdraw(amount);
        }
        else{
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).approve(router,amount);
            IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp+86400
                );
        }
        _order(email,address(0));
    }
    function orderTokenWithRouter(string memory email,address token,address _router)checkToken(token) payBank external{
        require(routers[_router]);
        //order with token
        uint256 amount = getPrice(token);
        require(IERC20(token).transferFrom(msg.sender,address(this),amount));
        if(token==WETH){
            IERC20(token).withdraw(amount);
        }
        else{
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).approve(_router,amount);
            IUniswapV2Router02(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp+86400
                );
        }
        _order(email,address(0));
    }
    function orderTokenWithRouter(string memory email,address token,address _router,address affiliate)checkToken(token) payAffiliate(affiliate) payBank external{
        require(routers[_router]);
        //order with token
        uint256 amount = getPrice(token);
        require(IERC20(token).transferFrom(msg.sender,address(this),amount));
        if(token==WETH){
            IERC20(token).withdraw(amount);
        }
        else{
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).approve(_router,amount);
            IUniswapV2Router02(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp+86400
                );
        }
        _order(email,address(0));
    }
    function getPrice(address _router,address token) public view returns(uint256){
        //returns amount of tokens equal to price
        if(token==USD){return price;}
        //price returned as total amount of token to send
        address factory = IUniswapV2Router02(_router).factory();
        address pair = IUniswapV2Factory(factory).getPair(token,USD);
        //address pair = IUniswapV2Factory(FACTORY).getPair(token, WETH);
        (uint256 left, uint256 right,) = IUniswapV2Pair(pair).getReserves();
        (uint256 tokenReserves, uint256 usdReserves) = (token < USD) ? (left, right) : (right, left);
        return (tokenReserves/usdReserves)*price;
    }
    function getPrice(address token) public view returns(uint256){
        return getPrice(router,token);
    }
    function getPrice() public view returns(uint256){
        return getPrice(WETH);
    }
    /*function pancakePrice(uint256 coin,address token) public view returns(uint256){
        //uses IpancakeFactory(address).getPair(address,address);
        address pair = IUniswapFactoryV2(pancakeFactory).getPair(weth,token);
        (uint resEth, uint resToken,) = IUniswapPairV2(pair).getReserves();
        return(coin*(resToken/resEth));
    }*/
}