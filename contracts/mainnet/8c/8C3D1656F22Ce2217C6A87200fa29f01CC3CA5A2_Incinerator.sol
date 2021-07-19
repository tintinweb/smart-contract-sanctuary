// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "../interfaces/IUniswapRouter.sol";

contract Incinerator {

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapRouter router;
    address public management;
    mapping (address => uint) public tokensBurned;

    event TokensIncinerated(address tokenAddr, uint amount);
    event ManagementUpdated(address oldManagement, address newManagement);
    event RouterUpdated(address oldRouter, address newRouter);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address routerAddr, address mgmt) {
        router = IUniswapRouter(routerAddr);
        management = mgmt;
    }

    // change which exchange we send tokens to
    function setRouter(address newRouter) external managementOnly {
        address oldRouter = address(router);
        router = IUniswapRouter(newRouter);
        emit RouterUpdated(oldRouter, newRouter);
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    // buy tokens at market rate and burn them
    function incinerate(address tokenAddr) external payable {
        // set amountMin to 0 since we don't care how many tokens we burn
        uint amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddr;

        address burnAddress = address(0);
        uint deadline = block.timestamp + 1;
        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, burnAddress, deadline);
        tokensBurned[tokenAddr] += amounts[1];
        emit TokensIncinerated(tokenAddr, amounts[1]);
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

interface IUniswapRouter {

    event LiquidityAdded(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
//        virtual
//        override
        payable
//        ensure(deadline)
        returns (uint[] memory amounts);
//    {
//        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
//        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
//        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
//        IWETH(WETH).deposit{value: amounts[0]}();
//        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
//        _swap(amounts, path, to);
//    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}