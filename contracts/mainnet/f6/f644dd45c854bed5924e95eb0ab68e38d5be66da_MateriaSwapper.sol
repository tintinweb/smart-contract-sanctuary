// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import './MateriaOperator.sol';
import './IMateriaOrchestrator.sol';
import './IMateriaFactory.sol';
import './IMateriaPair.sol';
import './IERC20.sol';
import './IERC20WrapperV1.sol';
import './IEthItemMainInterface.sol';
import './MateriaLibrary.sol';
import './TransferHelper.sol';


contract MateriaSwapper is MateriaOperator {

    function _swap(address factory, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = MateriaLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? MateriaLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IMateriaPair(MateriaLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
 
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        
        (path[0], amountIn) = _wrapErc20(path[0], amountIn, erc20Wrapper);
        
        bool ethItemOut;
        uint itemId;
        address tokenOut;
        
        (ethItemOut, itemId) = _isEthItem(path[path.length - 1], erc20Wrapper);
        
        if (!ethItemOut && bridgeToken != path[path.length - 1]) {
            tokenOut = path[path.length - 1];
            amountOutMin = _adjustAmount(tokenOut, amountOutMin);
            path[path.length - 1] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
        }
        
        amounts = MateriaLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        if (ethItemOut) {
            _swap(factory, amounts, path, to);
        } else {
            _swap(factory, amounts, path, address(this));
            _unwrapErc20(itemId, tokenOut, amounts[amounts.length - 1], erc20Wrapper, to);
        }
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        
        address tokenIn = path[0];
        path[0] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(IERC20WrapperV1(erc20Wrapper).object(path[0])));
        
        bool ethItemOut;
        uint itemId;
        (ethItemOut, itemId) = _isEthItem(path[path.length - 1], erc20Wrapper);
        address tokenOut;
        
        if (!ethItemOut && address(IMateriaOrchestrator(address(this)).bridgeToken()) != path[path.length - 1]) {
            tokenOut = path[path.length - 1];
            amountOut =  _adjustAmount(tokenOut, amountOut);
            path[path.length - 1] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
        }

        amounts = MateriaLibrary.getAmountsIn(factory, amountOut, path);
        amounts[0] = amounts[0] / (10**(18 - IERC20Data(tokenIn).decimals())) + 1;

        require(amounts[0] <= amountInMax, 'EXCESSIVE_INPUT_AMOUNT');
        
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amounts[0]);
        
        (, amounts[0]) = _wrapErc20(tokenIn, amounts[0], erc20Wrapper);
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        if (ethItemOut) {
            _swap(factory, amounts, path, to);
        } else {
            _swap(factory, amounts, path, address(this));
            _unwrapErc20(itemId, tokenOut, amounts[amounts.length - 1], erc20Wrapper, to);
        }
    }
    
     function swapExactETHForTokens(
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) payable returns (uint[] memory amounts) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());

        path[0] = _wrapEth(msg.value, erc20Wrapper);
        
        bool ethItemOut;
        uint itemId;
        address tokenOut;
        
        (ethItemOut, itemId) = _isEthItem(path[path.length - 1], erc20Wrapper);
        
        if (!ethItemOut && bridgeToken != path[path.length - 1]) {
            tokenOut = path[path.length - 1];
            amountOutMin = _adjustAmount(tokenOut, amountOutMin);
            path[path.length - 1] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
        }
        
        amounts = MateriaLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        if (ethItemOut) {
            _swap(factory, amounts, path, to);
        } else {
            _swap(factory, amounts, path, address(this));
            _unwrapErc20(itemId, tokenOut, amounts[amounts.length - 1], erc20Wrapper, to);
        }
    }
   
    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        uint ethId = uint(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID());
        
        address token = path[0];
        path[0] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(IERC20WrapperV1(erc20Wrapper).object(path[0])));
        amountOut = amountOut * (10 ** (18 - IERC20Data(path[path.length - 1]).decimals()));

        amountInMax = _adjustAmount(token, amountInMax);
        amounts = MateriaLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'INSUFFICIENT_INPUT_AMOUNT');

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amounts[0]);
        
        (path[0], amounts[0]) = _wrapErc20(token, amounts[0], erc20Wrapper);
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        _swap(factory, amounts, path, address(this));
        _unwrapEth(ethId, amounts[amounts.length - 1], erc20Wrapper, to);
    }
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        uint ethId = uint(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID());

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        
        (path[0], amountIn) = _wrapErc20(path[0], amountIn, erc20Wrapper);
        
        amounts = MateriaLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        _swap(factory, amounts, path, address(this));
        _unwrapEth(ethId, amounts[amounts.length - 1], erc20Wrapper, to);
    }
    
    function swapETHForExactTokens(
        uint amountOut,
        address[] memory path,
        address to,
        uint deadline
    ) public payable ensure(deadline) returns (uint[] memory amounts) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());
        
        bool ethItemOut;
        uint itemId;
        address tokenOut;
        
        (ethItemOut, itemId) = _isEthItem(path[path.length - 1], erc20Wrapper);
        
        if (!ethItemOut && bridgeToken != path[path.length - 1]) {
            tokenOut = path[path.length - 1];
            amountOut = _adjustAmount(tokenOut, amountOut);
            path[path.length - 1] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
        }
        
        amounts = MateriaLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'INSUFFICIENT_INPUT_AMOUNT');
        
        path[0] = _wrapEth(amounts[0], erc20Wrapper);
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        if (ethItemOut) {
            _swap(factory, amounts, path, to);
        } else {
            _swap(factory, amounts, path, address(this));
            _unwrapErc20(itemId, tokenOut, amounts[amounts.length - 1], erc20Wrapper, to);
        }
        
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }
    
    function swapExactItemsForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) private ensure(deadline) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());

        bool ethItemOut;
        uint itemId;
        address tokenOut;
        
        (ethItemOut, itemId) = _isEthItem(path[path.length - 1], erc20Wrapper);
        
        if (!ethItemOut && address(IMateriaOrchestrator(address(this)).bridgeToken()) != path[path.length - 1]) {
            tokenOut = path[path.length - 1];
            amountOutMin = _adjustAmount(tokenOut, amountOutMin);
            path[path.length - 1] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
        }
        
        uint[] memory amounts = MateriaLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        if (ethItemOut) {
            _swap(factory, amounts, path, to);
        } else {
            _swap(factory, amounts, path, address(this));
            _unwrapErc20(itemId, tokenOut, amounts[amounts.length - 1], erc20Wrapper, to);
        }
    }
    
    function swapItemsForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address to,
        address from,
        uint deadline
    ) private ensure(deadline) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());

        bool ethItemOut;
        uint itemId;
        address tokenOut;
        
        (ethItemOut, itemId) = _isEthItem(path[path.length - 1], erc20Wrapper);
        
        if (!ethItemOut && address(IMateriaOrchestrator(address(this)).bridgeToken()) != path[path.length - 1]) {
            tokenOut = path[path.length - 1];
            amountOut = _adjustAmount(tokenOut, amountOut);
            path[path.length - 1] = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
        }
        
        uint[] memory amounts = MateriaLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'INSUFFICIENT_INPUT_AMOUNT');
        
        {
        uint amountBack;
        if ((amountBack = amountInMax - amounts[0]) > 0)
            TransferHelper.safeTransfer(path[0], from, amountBack);
        }
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        if (ethItemOut) {
            _swap(factory, amounts, path, to);
        } else {
            _swap(factory, amounts, path, address(this));
            _unwrapErc20(itemId, tokenOut, amounts[amounts.length - 1], erc20Wrapper, to);
        }
    }
    
    function swapExactItemsForEth(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) private ensure(deadline) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        uint ethId = uint(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID());

        uint[] memory amounts = MateriaLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        _swap(factory, amounts, path, address(this));
        
        IERC20WrapperV1(erc20Wrapper).burn(
            ethId,
            amounts[amounts.length - 1]
        );
        
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    
    function swapItemsForExactEth(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address to,
        address from,
        uint deadline
    ) private ensure(deadline) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        uint ethId = uint(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID());

        uint[] memory amounts = MateriaLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'INSUFFICIENT_INPUT_AMOUNT');
        
        {
        uint amountBack;
        if ((amountBack = amountInMax - amounts[0]) > 0)
            TransferHelper.safeTransfer(path[0], from, amountBack);
        }
        
        TransferHelper.safeTransfer(
            path[0], MateriaLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        _swap(factory, amounts, path, address(this));
        
        IERC20WrapperV1(erc20Wrapper).burn(
            ethId,
            amounts[amounts.length - 1]
        );
        
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function onERC1155Received(
        address,
        address from,
        uint,
        uint value,
        bytes calldata data
    ) public override returns(bytes4) {
        uint operation;
        uint amount;
        address[] memory path;
        address to;
        uint deadline;
        
        { //to avoid "stack too deep"
            bytes memory payload;
            (operation, payload) = abi.decode(data, (uint, bytes));
            (amount, path, to, deadline) = abi.decode(payload, (uint, address[], address, uint));
        }
        
        if (operation == 2) swapExactItemsForTokens(value, amount, path, to, deadline);
        else if (operation == 3) swapItemsForExactTokens(amount, value, path, to, from, deadline);
        else if (operation == 4) swapExactItemsForEth(value, amount, path, to, deadline);
        else if (operation == 5) swapItemsForExactEth(amount, value, path, to, from, deadline);
        else revert();
        
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public override pure returns(bytes4) {
        revert();
    }
    
    function supportsInterface(
        bytes4
    ) public override pure returns (bool) {
        return false;
    }
}