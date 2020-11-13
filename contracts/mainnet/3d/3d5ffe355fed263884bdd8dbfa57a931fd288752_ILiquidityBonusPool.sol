pragma solidity >=0.5.0;

// LiquidityBonusPool Special Bonus
interface ILiquidityBonusPool{
    // Set Factory
    function setFactory(address factory)external;
    // Get The Factory
    function getFactory()external view returns (address);

    // Get The Target User Balance of Bonus
    function balanceOfBonus(address pair,address owner) external view returns (uint);
    // Get All Bonus of a address
    function balanceOfAllBonus(address pair,address owner) external view returns (uint paid,uint current);
    // Get specify pair's Liquidity Bonus
    function balanceOfPool(address pair) external view returns (uint);

    // add bonus of specify day
    function addBonusOfDay(address pair,uint day) external returns (uint);
    // add bonus of specify day
    function addBonusOfDay(address pair,address to,uint day) external returns (uint);
    // pay bonus of specify day
    function payBonusOfDay(address pair,uint day) external returns (uint);
    // get the bonus
    function getBonus(address pair)external returns (uint amount0,uint amount1);

    // do Liquidity mint
    function mintLiquidityBonus(address pair,address to,uint amount0In, uint amount1In,uint amount0Out, uint amount1Out,bytes calldata data)external;
    function burnLiquidityBonus(address pair,address to,uint amount0In, uint amount1In,uint amount0Out, uint amount1Out,bytes calldata data)external;

    // common method
    function mintLiquidityBonus(address pair,address to,bytes calldata data)external;
    function burnLiquidityBonus(address pair,address from)external returns (uint amount0,uint amount1);

    // common method
    function mintLiquidityBonus(address pair,bytes calldata data)external;
    function burnLiquidityBonus(address pair,bytes calldata data)external;

}
