/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity 0.8.7;

interface IPriceFeed{
    function latestAnswer() external view returns (uint);
}

interface IRouter{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

     function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);   

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface ISLP{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns(address);
    function token1() external view returns(address);
}

interface IDAI{
    function mint(uint256 value) external returns (bool);
}

interface ERC20{
    function decimals() external view returns(uint8);
    function mint(address to, uint amount) external;
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

interface IUniMath{
     function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) pure external returns (bool aToB, uint256 amountIn);
}

contract ArbMinter{

    IDAI public DAI = IDAI(0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108); 
    address public USDC = 0x14bFFDf158D0DbDA11E4e4105e6e2FE1D24F4D2e;   
    address public WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    IRouter public Router = IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IPriceFeed public PriceFeed = IPriceFeed(0xDB18a8F1B75553711C0D63a8d510008363D59328);
    IUniMath UniMath = IUniMath(0xc8efE03728FE7Fe533dff31aBCe16f4a0892818D); 

    function fixStablePool(ISLP _slp) external {
        //Get Ratio
        (uint112 reserve0,uint112 reserve1,) = _slp.getReserves();
        //Get ethPrice
        uint ethPrice = PriceFeed.latestAnswer();
        
        if(ERC20(_slp.token0()).decimals() == 6){
            reserve0 = reserve0*1e12;
        }
        if(ERC20(_slp.token1()).decimals() == 6){
            reserve1 = reserve1*1e12;
        }

        if(address(_slp) == 0x02eA83301D1FFB7E9B1055eDA96A3468FF992000){
            if(reserve0 > reserve1){
                //mintAndDeposit(Router.getAmountIn((reserve0-reserve1) / 2, reserve1, reserve0),_slp.token1(),_slp.token0(),address(_slp));
            }
            else{
                //mintAndDeposit(Router.getAmountIn((reserve1-reserve0) / 2, reserve0, reserve1),_slp.token0(),_slp.token1(),address(_slp));
            }
            //return(0, address(0));
        }
        else{
            if((ethPrice/1e8) > (reserve1 / reserve0)){
                (bool aToB, uint256 amountIn) = UniMath.computeProfitMaximizingTrade(
                ethPrice,
                1e8,
                reserve0,
                reserve1);
                //return(amountIn,address(DAI));
                mintAndDeposit(amountIn,address(DAI),WETH,address(_slp));
            }
            else{
                (bool aToB, uint256 amountIn) = UniMath.computeProfitMaximizingTrade(
                ethPrice,
                1e8,
                reserve0,
                reserve1);
                //return(amountIn,WETH);
                mintAndDeposit(amountIn,WETH,address(DAI),address(_slp));
            }   
        }        
    }

    function mintAndDeposit(uint256 _amount, address _sellToken, address _buyToken,address _slp) internal{
        //Mint DAI
        if(_sellToken == address(DAI)){
            DAI.mint(_amount);
        }
        //Mint USDC
        else if(_sellToken == USDC){
            _amount = _amount/1e12;
            ERC20(_sellToken).mint(address(this),_amount);
        }
        
        address[] memory route = new address[](2);
        route[0] = _sellToken;
        route[1] = _buyToken;

        ERC20(_sellToken).approve(address(Router),_amount);
        if(_sellToken == WETH){
            Router.swapExactETHForTokens{value: _amount}(0, route, 0xC189Ca9C9168004B3c0eED5409c15A88B87a0702, block.timestamp+1);
            return;
        }
        if(_buyToken == WETH){
            Router.swapExactTokensForETH(_amount,0, route, 0xC189Ca9C9168004B3c0eED5409c15A88B87a0702, block.timestamp+1);
            return;
        }
        //Deposit (trade) token into pool
        Router.swapExactTokensForTokens(_amount,0,route,address(this),block.timestamp+1);        
    }

}