/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity 0.8.7;

interface IRouter{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

pragma solidity 0.8.7;

interface ISLP{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns(address);
    function token1() external view returns(address);
}

pragma solidity 0.8.7;

interface IDAI{
    function mint(uint amount) external;
}

pragma solidity 0.8.7;

interface ERC20{
    function decimals() external view returns(uint8);
    function mint(address to, uint amount) external;
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

pragma solidity 0.8.7;

contract ArbMinter{

    IDAI public DAI = IDAI(0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108); 
    address public USDC = 0x14bFFDf158D0DbDA11E4e4105e6e2FE1D24F4D2e;   
    IRouter public Router = IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    function fixStablePool(ISLP _slp) external {
        //Get Ratio
        (uint112 reserve0,uint112 reserve1,) = _slp.getReserves();
        
        if(ERC20(_slp.token0()).decimals() == 6){
            reserve0 = reserve0*1e12;
        }

        if(ERC20(_slp.token1()).decimals() == 6){
            reserve0 = reserve0*1e12;
        }

        if(reserve0 == reserve1){
            return;
        }
        if(reserve0 > reserve1){
            //Mint USDC/DAI
            mintAndDeposit((reserve0-reserve1),_slp.token1(),_slp.token0(),address(_slp));
        }
        else{
            //Mint bUSD
            mintAndDeposit((reserve1-reserve0),_slp.token0(),_slp.token1(),address(_slp));
        }
        
    }

    function mintAndDeposit(uint256 _amount, address _sellToken, address _buyToken,address _slp) internal{
        //Mint DAI
        if(_sellToken == address(DAI)){
            DAI.mint(_amount);
        }
        //Mint USDC
        if(_sellToken == USDC){
            _amount = _amount/1e12;
            ERC20(_sellToken).mint(address(this),_amount);
        }
        //Mint other ERC20s
        else{
            ERC20(_sellToken).mint(address(this),_amount);
        }
        
        //address[] memory route = new address[](2);
        //route[0] = _sellToken;
        //route[1] = _buyToken;
        //Deposit (trade) token into pool
        //ERC20(_sellToken).approve(address(Router),_amount);
        //Router.swapExactTokensForTokens(_amount,0,route,0xC189Ca9C9168004B3c0eED5409c15A88B87a0702,block.timestamp+1);
        ERC20(_sellToken).transfer(_slp,_amount);
    }
}