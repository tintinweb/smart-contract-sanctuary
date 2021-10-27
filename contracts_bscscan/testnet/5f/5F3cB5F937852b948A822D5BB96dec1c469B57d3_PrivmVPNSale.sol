/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: Unlicensed
//0x5F3cB5F937852b948A822D5BB96dec1c469B57d3 //testnet contract
//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 //bsc testnet router
//0x78867bbeef44f2326bf8ddd1941a4439382ef2a7 //bsc testnet token
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
    event ApprovedToken(address indexed Affiliate);
    event RemovedToken(address indexed Token);
    event UpdatedRouter(address indexed Router);
    event UpdatedAlternateRouter(address indexed Token, address indexed Router);

    string public pubKey;//public key
    address private immutable owner;//contract creator

    //mapping(address=>bool) private admin;//allowed to make orders to possibly add other functionality
    address public router;//main router

    mapping(address=>address) public alternateRouters;//allowed alternative routers

    address public USD;//stablecoin used to set token prices

    address private immutable WETH;//payments are converted to WETH

    uint256 public price = 10 * 10**18;//price in USD

    address public bank;//gets paid eth coin

    uint8 public affiliatePercentage=50;

    mapping(address=>bool) public approvedTokens;

    mapping(uint24=>string) public orders;
    uint24 public orderIndex;
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
        require(msg.sender!=affiliate);
        _;
        payable(affiliate).transfer(address(this).balance*affiliatePercentage/100);
        emit AffiliateOrder(affiliate);
    }
    modifier checkToken(address token){
        //payable(bank).transfer(address(this).balance);
        //pass the rest of gas on
        require(approvedTokens[token]==true);
        _;
    }
    constructor(address _router, address _stablecoin){
        owner=msg.sender;
        router=_router;
        USD=_stablecoin;
        WETH = IUniswapV2Router02(_router).WETH();
        bank=msg.sender;
        approvedTokens[_stablecoin]=true;
        emit UpdatedRouter(_router);
        emit ApprovedToken(_stablecoin);
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
    function updateAlternateRouter(address _token, address _router)onlyOwner external{
        alternateRouters[_token]=_router;
        emit UpdatedAlternateRouter(_token,_router);
    }
    function approveToken(address token)onlyOwner external{
        require(!approvedTokens[token]);
        approvedTokens[token]=true;
        emit ApprovedToken(token);
    }
    function removeToken(address token)onlyOwner external{
        require(approvedTokens[token]);
        approvedTokens[token]=false;
        emit RemovedToken(token);
    }
    function updateAffiliatePercentage(uint8 percent)onlyOwner external{
        require(percent<100&&percent>0);
        affiliatePercentage=percent;
    }
    function updateUSD(address token)onlyOwner external{
        USD=token;
    }
    function _order(string memory email,address Token) internal{
        orders[orderIndex]=email;
        emit Order(msg.sender,Token,orderIndex);
        orderIndex++;
        if(orderIndex==0){
          orderIndex++;
        }
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
            address currentRouter;
            if(alternateRouters[token]!=address(0)){
                currentRouter=alternateRouters[token];
            }
            else{
                currentRouter=router;
            }
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).approve(currentRouter,amount);
            IUniswapV2Router02(currentRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
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
            address currentRouter;
            if(alternateRouters[token]!=address(0)){
                currentRouter=alternateRouters[token];
            }
            else{
                currentRouter=router;
            }
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).approve(currentRouter,amount);
            IUniswapV2Router02(currentRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp+86400
                );
        }
        _order(email,address(0));
    }
    function getPrice(address token) public view returns(uint256){
        //returns amount of tokens equal to price
        if(token==USD){return price;}
        address currentRouter;
        if(alternateRouters[token]!=address(0)){
            currentRouter=alternateRouters[token];
        }
        else{
            currentRouter=router;
        }
        //price returned as total amount of token to send
        address factory = IUniswapV2Router02(currentRouter).factory();
        address pair = IUniswapV2Factory(factory).getPair(token,USD);
        //address pair = IUniswapV2Factory(FACTORY).getPair(token, WETH);
        (uint256 left, uint256 right,) = IUniswapV2Pair(pair).getReserves();
        (uint256 tokenReserves, uint256 usdReserves) = (token < USD) ? (left, right) : (right, left);
        return (tokenReserves/usdReserves)*price;
    }
    function getPrice() public view returns(uint256){
        return getPrice(WETH);
    }
}