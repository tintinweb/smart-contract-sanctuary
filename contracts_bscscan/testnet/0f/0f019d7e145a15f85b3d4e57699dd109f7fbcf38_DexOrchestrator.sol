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
        uint256 amount0Out; // ordered
        uint256 amount1Out; // ordered
    }

    function pairStart(
        address _source,
        uint256[] calldata _amounts,
        address[] calldata _pairs,
        address[][] calldata _paths
    ) external {
        // _source:     pairAddress
        // _amounts:    [0, amount]
        // _pairs:      [p1, p2]
        // _paths:      [[t0, t1], [t1, t2]]

        Action[] memory actions = new Action[](_pairs.length);

        for (uint256 x = 0; x < actions.length; x++) {
            actions[x] = Action(
                _pairs[x],
                _paths[x][0],
                _paths[x][1],
                0,
                0,
                0,
                0
            );
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

        // Defining facts
        address token0;
        uint256 amount = _amount0 == 0 ? _amount1 : _amount0;

        Action[] memory actions = abi.decode(_data, (Action[]));

        token0 = actions[actions.length - 1].path1; // last loken
        address borrowedToken = actions[0].path0;

        // Defining how much should be paid back in $lastToken
        (uint256 reserveIn, uint256 reserveOut) = GenericV2Library.getReserves(
            msg.sender,
            token0,
            borrowedToken
        );

        uint256 amountToPay = GenericV2Library.getAmountIn(
            amount,
            reserveIn,
            reserveOut
        );
        uint256 amountNeeded = amountToPay;

        // Finding out [amountNeeded] to start whole operation
        for (uint256 i = actions.length - 1; i >= 0; i--) {
            (reserveIn, reserveOut) = GenericV2Library.getReserves(
                actions[i].pair,
                actions[i].path0,
                actions[i].path1
            );

            // Defining reserves to be used on swaps
            actions[i].reserveIn = reserveIn;
            actions[i].reserveOut = reserveOut;

            amountNeeded = GenericV2Library.getAmountIn(
                amountNeeded,
                reserveIn,
                reserveOut
            );

            // Defining amounts (ordered tokens)
            (token0, ) = GenericV2Library.sortTokens(
                actions[i].path0,
                actions[i].path1
            );
            actions[i].amount0Out = actions[i].path0 == token0
                ? amountNeeded
                : 0;
            actions[i].amount1Out = actions[i].path0 == token0
                ? 0
                : amountNeeded;
        }

        uint256 balance = IERC20(actions[0].path0).balanceOf(address(this));
        require(
            balance > amountNeeded,
            "PairOrchestrator: WONT_GET_ENOUGH_TOKENS"
        );
        uint256 profit = balance - amountNeeded;

        // Executing swaps
        address nextPair;
        IERC20(actions[0].path0).transfer(actions[0].pair, amountNeeded);

        for (uint256 i = 0; i < actions.length; i++) {
            amount = actions[i].amount0Out == 0
                ? actions[i].amount1Out
                : actions[i].amount0Out;

            if (i == actions.length - 1) {
                nextPair = msg.sender;
            } else {
                nextPair = actions[i + 1].pair;
            }

            IUniswapV2Pair(actions[i].pair).swap(
                actions[i].amount0Out,
                actions[i].amount1Out,
                nextPair,
                ""
            );
        }

        // Transfering profit
        IERC20(borrowedToken).transfer(tx.origin, profit);
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