/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.6.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenApproval {
    function approveSushiswap() external {
        address alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
        address sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    
        IERC20(alcx).approve(sushiRouter, uint(-1));
    }
}