//ISwapdexV2Callee contract

pragma solidity >=0.5.0;

interface ISwapdexV2Callee {
    function SwapdexV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
