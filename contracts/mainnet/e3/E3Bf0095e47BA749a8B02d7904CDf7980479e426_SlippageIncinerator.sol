// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IUniswapRouter.sol";
import "IIncinerator.sol";

contract SlippageIncinerator is IIncinerator {

    // WETH(mainnet) 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // WETH(rinkeby) 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public WETH;
    IUniswapRouter public router;
    address public management;
    mapping (address => uint) public tokensBurned;

    event TokensIncinerated(address tokenAddr, uint amount);
    event ManagementUpdated(address oldManagement, address newManagement);
    event RouterUpdated(address oldRouter, address newRouter);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address routerAddr, address mgmt, address weth) {
        router = IUniswapRouter(routerAddr);
        management = mgmt;
        WETH = weth;
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
    // need to pass amountOutMin manually to avoid being frontrun :/
    function incinerate(address tokenAddr, uint amountOutMin) external payable {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddr;

        address burnAddress = address(0);
        uint deadline = block.timestamp + 1;
        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, burnAddress, deadline);
        tokensBurned[tokenAddr] += amounts[1];
        emit TokensIncinerated(tokenAddr, amounts[1]);
    }

//    function incineratePath(address[] memory path, address inputToken) external payable {
//        // set amountMin to 0 since we don't care how many tokens we burn
//        uint amountOutMin = 0;
//
//        address burnAddress = address(0);
//        uint deadline = block.timestamp + 1;
//        uint[] memory amounts = router.swapTokensForExactTokens(amountOutMin, path, burnAddress, deadline);
//        uint lastAmount = amounts[amounts.length - 1];
//        address lastAddress = path[path.length - 1];
//        tokensBurned[lastAddress] += lastAmount;
//        emit TokensIncinerated(lastAddress, lastAmount);
//    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

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

        function swapTokensForExactTokens(
            uint amountOut,
            uint amountInMax,
            address[] calldata path,
            address to,
            uint deadline)
        external
//        virtual
//        override
        returns (uint[] memory amounts);
//    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
//        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
//        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
//        TransferHelper.safeTransferFrom(
//            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
//        );
//        _swap(amounts, path, to);
//    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IIncinerator {

    function incinerate(address tokenAddr, uint amountOutMin) external payable;
}