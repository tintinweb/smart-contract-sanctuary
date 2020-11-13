pragma solidity ^0.6.12;

interface DaiErc20 {
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function approve(address,uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
}
