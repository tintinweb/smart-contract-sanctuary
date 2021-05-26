pragma solidity 0.8.1;

import "./AccessControl.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/**
  ETH/BCUG price oracle designed for TokenRegistry and presale system.
  Function ETHPrice returns how many BCUG token can be bought by 1 ETH
  1 ETH = X BCUG
**/
contract BCUGPriceOracle is AccessControl {

    address public bcug;
    IUniswapV2Pair public pool;

    uint8 private slot;

    constructor(address _bcug, IUniswapV2Pair _pool) {
        bcug = _bcug;
        setPool(_pool);
    }

    function setPool(IUniswapV2Pair _pool) public onlyOwner {
        require(_pool.token0() == bcug || _pool.token1() == bcug, "Wrong pool for BCUG provided");
        pool = _pool;
        slot = _pool.token0() == bcug ? 0 : 1;
    }

    // @dev returns amount of token0 needed to buy token1
    function ETHPrice() external view returns (uint) {
        (uint Res0, uint Res1) = getReserves();
        uint res0 = Res0 * 1 ether; // * 10 ^ 18
        return res0 / Res1;
    }

    function getReserves() private view returns (uint Res0, uint Res1) {
        if (slot == 0) {
            (Res0, Res1,) = pool.getReserves();
        } else {
            (Res1, Res0,) = pool.getReserves();
        }
    }
}