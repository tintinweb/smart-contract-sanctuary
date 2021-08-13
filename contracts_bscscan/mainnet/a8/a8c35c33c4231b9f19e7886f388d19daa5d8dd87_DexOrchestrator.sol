pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

contract DexOrchestrator {
    uint256 public cActions = 0;
    struct Action {
        address router;
        address token0;
        address token1;
    }
    mapping(uint256 => Action) actions;

    // Reusable variables
    address public targetRouter;

    // _sourceRouter:        [amount0, amount1, pairAddress]
    // _routers:        [router0, router1, router2]
    // _paths:          [[token0, token1], [token0, token1], [token0, token1]]
    function arbitrage_with_loan(
        address _sourceRouter,
        address _pair,
        uint256[] calldata _amounts,
        address[] calldata _routers,
        address[][] calldata _paths
    ) external {
        require(_amounts.length == 2, "dex_orchestrator: WRONG_AMOUNTS_FORMAT");
        require(
            _routers.length > 0,
            "dex_orchestrator: NO_ACTIONS_TO_BE_EXECUTED"
        );
        require(
            _routers.length == _paths.length,
            "dex_orchestrator: MISMATCH_BETWEEN_ROUTERS_AND_PATHS"
        );

        // Defining actions to be executed
        cActions = _routers.length;
        for (uint256 i = 0; i < _routers.length; i++) {
            targetRouter = _routers[i];
            actions[i] = Action(targetRouter, _paths[i][0], _paths[i][1]);
        }

        IUniswapV2Pair(_pair).swap(
            _amounts[0],
            _amounts[1],
            address(this),
            abi.encode(_sourceRouter)
        );
    }

    function loan_callback(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes memory _data
    ) internal {
        // Validating callback
        require(_amount0 == 0 || _amount1 == 0);

        uint256 deadline = block.timestamp + 10 minutes;
        address pairAddress = msg.sender;
        address sourceRouter = abi.decode(_data, (address));

        uint256 amount = _amount0 == 0 ? _amount1 : _amount0;
        uint256 amountToPay = 0;

        // Defining how much should be paid back in $lastToken
        address[] memory path = new address[](2);
        path[0] = actions[cActions - 1].token1; // Last token  (expected arbitrage result)
        path[1] = actions[0].token0; // First token

        amountToPay = IUniswapV2Router(sourceRouter).getAmountsIn(amount, path)[
                0
            ];

        uint256 minAmount = 100000;

        // Executing actions
        for (uint256 i = 0; i < cActions; i++) {
            targetRouter = actions[i].router;
            path[0] = actions[i].token0;
            path[1] = actions[i].token1;

            IERC20 token = IERC20(path[0]);
            token.approve(targetRouter, amount);

            amount = IUniswapV2Router(targetRouter).swapExactTokensForTokens(
                amount,
                minAmount,
                path,
                address(this),
                deadline
            )[1];
        }

        IERC20 lastToken = IERC20(path[1]);
        // Repaying loan
        lastToken.transfer(pairAddress, amountToPay);
        // Transfering profit
        lastToken.transfer(tx.origin, amount - amountToPay);
    }

    function BiswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function cafeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function jetswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function pantherCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function swapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function wardenCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }

    function waultSwapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        loan_callback(_sender, _amount0, _amount1, _data);
    }
}