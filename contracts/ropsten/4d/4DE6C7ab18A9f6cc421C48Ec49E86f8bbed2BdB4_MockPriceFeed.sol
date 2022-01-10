/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity ^0.5.16;

interface IUniPool {
    function slot0(
    ) external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

contract MockPriceFeed {

    IUniPool uniPool = IUniPool(0x5c392AF7dc3aA0e45a1F95291de480761dbDd228);
    uint price = 4800000000000000000000;
    uint8 decimal = 8;

    function decimals() external view returns (uint8){
        return(decimal);
    }

    function latestAnswer() external view returns (uint){
        (uint160 sqrtPriceX96,,,,,,) = uniPool.slot0();
        return((uint(sqrtPriceX96) ** 2) * 1e8 / ((2 ** 96) ** 2));
    }

    function setPrice(uint _price) external{
        price = _price;
    }

    function setDecimals(uint8 _decimal) external{
        decimal = _decimal;
    }
}