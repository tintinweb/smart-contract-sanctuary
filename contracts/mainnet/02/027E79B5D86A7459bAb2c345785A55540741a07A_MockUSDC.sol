pragma solidity ^0.5.0;


import "./MintableERC20.sol";


contract MockUSDC is MintableERC20 {

    uint256 public decimals = 6;
    string public symbol = "USDC";
    string public name = "USD Coin";
}