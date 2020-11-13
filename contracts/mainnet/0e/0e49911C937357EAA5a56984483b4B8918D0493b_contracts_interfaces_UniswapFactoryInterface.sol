pragma solidity ^0.6.0;

abstract contract UniswapFactoryInterface {
    function getExchange(address token) external view virtual returns (address exchange);
}
