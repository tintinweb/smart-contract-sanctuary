pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./GenericV2Library.sol";

contract PairOrchestrator {
    address public targetPair;

    function start(
        address[] calldata _sourcePair,
        address _targetPair,
        uint256[] calldata _amounts
    ) external {
        targetPair = _targetPair;

        IUniswapV2Pair(_sourcePair[0]).swap(
            _amounts[0],
            _amounts[1],
            address(this),
            abi.encode(_sourcePair[1], _sourcePair[2])
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
        address[] memory path = new address[](2);
        uint256 amount = _amount0 == 0 ? _amount1 : _amount0;

        (address token0, address token1) = abi.decode(
            _data,
            (address, address)
        );
        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;

        // Defining how much should be paid back in $otherToken
        (uint256 reserveIn, uint256 reserveOut) = GenericV2Library.getReserves(
            msg.sender,
            path[0],
            path[1]
        );

        uint256 amountToPay = GenericV2Library.getAmountIn(
            amount,
            reserveIn,
            reserveOut
        );

        // Defining facts for Swap
        (reserveIn, reserveOut) = GenericV2Library.getReserves(
            targetPair,
            path[0],
            path[1]
        );

        amount = GenericV2Library.getAmountIn(
            amountToPay,
            reserveIn,
            reserveOut
        );

        require(
            amount > amountToPay,
            "PairOrchestrator: WONT_GET_ENOUGH_TOKENS"
        );

        // Transfering to pair
        IERC20(path[0]).transfer(targetPair, amount);

        // Swaping and paying loan
        uint256 amount0Out = _amount0 == 0 ? amountToPay : 0;
        uint256 amount1Out = _amount0 == 0 ? 0 : amountToPay;

        IUniswapV2Pair(targetPair).swap(amount0Out, amount1Out, msg.sender, "");

        // Transfering profit
        IERC20(path[0]).transfer(tx.origin, amount - amountToPay);
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