pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./GenericV2Library.sol";

contract DexOrchestrator {
    struct Action {
        address pair;
        address path0;
        address path1;
        uint256 reserveIn;
        uint256 reserveOut;
    }

    function pairStart(
        address _source,
        uint256[] calldata _amounts,
        address[] calldata _pairs,
        address[] calldata _path
    ) external {
        // _source:     pairAddress
        // _amounts:    [0, amount]
        // _pairs:      [p1, p2]
        // _path:       [t0, t1, t0]

        Action[] memory actions = new Action[](_pairs.length);

        for (uint256 x = 0; x < actions.length; x++) {
            actions[x] = Action(_pairs[x], _path[x], _path[x + 1], 0, 0);
        }

        IUniswapV2Pair(_source).swap(
            _amounts[0],
            _amounts[1],
            address(this),
            abi.encode(actions)
        );
    }

    function fs_callback(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes memory _data
    ) internal {
        require(_amount0 == 0 || _amount1 == 0);

        // 1. Defining facts
        Action[] memory actions = abi.decode(_data, (Action[]));

        uint256 amount = _amount0 == 0 ? _amount1 : _amount0;
        address token0 = actions[actions.length - 1].path1; // last loken
        address borrowedToken = actions[0].path0;
        uint256 i;

        // 2. Defining how much should be paid back in $lastToken
        (uint256 reserveIn, uint256 reserveOut) = GenericV2Library.getReserves(
            msg.sender,
            token0,
            borrowedToken
        );

        // amount needed
        uint256 amountNeeded = GenericV2Library.getAmountIn(
            amount,
            reserveIn,
            reserveOut
        );

        // 3. Reversive loop to:
        //   . Set reserves
        //   . Find out [amountNeeded]
        for (i = actions.length; i > 0; i--) {
            (reserveIn, reserveOut) = GenericV2Library.getReserves(
                actions[i - 1].pair,
                actions[i - 1].path0,
                actions[i - 1].path1
            );

            actions[i - 1].reserveIn = reserveIn;
            actions[i - 1].reserveOut = reserveOut;

            amountNeeded = GenericV2Library.getAmountIn(
                amountNeeded,
                reserveIn,
                reserveOut
            );
        }

        // Here, [amount] is borrowed amount
        require(
            amount > amountNeeded,
            "PairOrchestrator: WONT_GET_ENOUGH_TOKENS"
        );

        // 4. Executing swaps
        address nextPair;
        uint256 amount0Out;
        uint256 amount1Out;
        amount = amountNeeded;

        IERC20(borrowedToken).transfer(actions[0].pair, amountNeeded);

        for (i = 0; i < actions.length; i++) {
            nextPair = i == actions.length - 1
                ? msg.sender
                : actions[i + 1].pair;

            // Defining amountsOut (ordered tokens)
            // Here, [amountNeeded] is used as [amountIn]
            amount = GenericV2Library.getAmountOut(
                amount,
                actions[i].reserveIn,
                actions[i].reserveOut
            );

            (token0, ) = GenericV2Library.sortTokens(
                actions[i].path0,
                actions[i].path1
            );

            amount0Out = actions[i].path0 == token0 ? 0 : amount;
            amount1Out = actions[i].path0 == token0 ? amount : 0;

            IUniswapV2Pair(actions[i].pair).swap(
                amount0Out,
                amount1Out,
                nextPair,
                ""
            );
        }

        // Transfering profit
        amount = IERC20(borrowedToken).balanceOf(address(this));
        IERC20(borrowedToken).transfer(tx.origin, amount);
    }

    function babyCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function BiswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function BSCswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function cafeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function jetswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function pantherCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function swapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function wardenCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }

    function waultSwapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        fs_callback(_sender, _amount0, _amount1, _data);
    }
}