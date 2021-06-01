/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.5.0;

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
}

// File: contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.5.0;



interface ICoFixFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (IUniswapV2Pair pair);
    function allPairsLength() external view returns (uint);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/UniswapV2Helper.sol

pragma solidity ^0.5.12;


pragma experimental ABIEncoderV2;

contract CoFixHelper {
    
    struct Pair {
        address pair;
        address token0;
        address token1;
    }

    ICoFixFactory constant factory =  ICoFixFactory(0x39816B841436a57729723d9DA127805755d2CB51);

    function getPairs() external view returns (Pair[] memory pairs) {

        uint256 pairsCount = factory.allPairsLength();
        Pair[] memory allPairs = new Pair[](pairsCount);

        uint256 notEmptyLength;
        for (uint i; i < pairsCount; i++) {
            IUniswapV2Pair pair = factory.allPairs(i);
            address token0 = pair.token0();
            address token1 = pair.token1();
             
            if (IERC20(token0).balanceOf(address(pair)) > 0) {
                allPairs[notEmptyLength] = Pair({
                    pair: address(pair),
                    token0: token0,
                    token1: token1
                });
                notEmptyLength++;
            }
        }

        pairs = new Pair[](notEmptyLength);
        for (uint i; i < notEmptyLength; i++) {
            pairs[i] = allPairs[i];
        }
    }

}