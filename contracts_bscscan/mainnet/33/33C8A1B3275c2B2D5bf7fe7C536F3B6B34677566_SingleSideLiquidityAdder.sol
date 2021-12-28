// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./RootedTransferGate.sol";

// Contract to add 1 sided liquidty after buys via 
// selling and setting the "to" address as the pool

contract SingleSideLiquidityAdder is TokensRecoverable {    
    address public bot;
    IPancakeRouter02 immutable private pancakeRouter;
    RootedTransferGate immutable private gate;
    IERC20 immutable private rooted;
    address immutable private base;
    address immutable private pool;
    
    constructor (address _base, IERC20 _rooted, address _pool, RootedTransferGate _gate, IPancakeRouter02 _pancakeRouter) {
        base = _base;
        rooted = _rooted;
        pool = _pool;
        gate = _gate;
        pancakeRouter = _pancakeRouter;
        _rooted.approve(address(_pancakeRouter), uint(-1));
    }

    function setBot(address _bot) public ownerOnly() {
        bot = _bot;
    }

    function addSingleSideLiquidity(uint256 amount, uint256 minAmountOut) public {
        require(msg.sender == bot, "Bot only");
        require(rooted.balanceOf(address(this)) >= amount, "Not enough upToken Balance");

        gate.setUnrestricted(true);

        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = base;
        pancakeRouter.swapExactTokensForTokens(amount, minAmountOut, path, pool, block.timestamp);

        gate.setUnrestricted(false);
    }
}