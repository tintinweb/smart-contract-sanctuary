/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity 0.5.16;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract DexUtils {
    
    function findPairInDex(address factory, address token0, address[] memory token1Array) public view returns (address) {
        IFactory factoryObj = IFactory(factory);
        for(uint32 i = 0; i < token1Array.length; i++) {
            address pair = factoryObj.getPair(token0, token1Array[i]);
            if(pair != address(0)){
                return pair;
            }
        }
        return address(0);
    }
    
    function getPairInfo(address pair) public view 
        returns (address token0, address token1, string memory symbol0, string memory symbol1, 
            uint8 decimals0, uint8 decimals1, uint112 reserve0, uint112 reserve1 ){
        if(pair != address(0)){
            IPair p = IPair(pair);
            token0 = p.token0();
            token1 = p.token1();
            (reserve0, reserve1, ) = p.getReserves();
            IERC20 t0 = IERC20(token0);
            symbol0 = t0.symbol();
            decimals0 = t0.decimals();
            IERC20 t1 = IERC20(token1);
            symbol1 = t1.symbol();
            decimals1 = t1.decimals();
        }
    }
    
    function findPair(address factory, address token0, address[] memory token1Array) public view 
        returns (address _pair, address _token0, address _token1, string memory _symbol0, string memory _symbol1, 
            uint8 _decimals0, uint8 _decimals1, uint112 _reserve0, uint112 _reserve1 ){
        _pair = findPairInDex(factory, token0, token1Array);
        (_token0, _token1, _symbol0, _symbol1, _decimals0, _decimals1, _reserve0, _reserve1) = getPairInfo(_pair);
    }
}