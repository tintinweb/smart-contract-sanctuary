// SPDX-License-Identifier: GPL3
pragma solidity 0.8.0;

import './MateriaOperator.sol';
import './IMateriaOrchestrator.sol';
import './IMateriaFactory.sol';
import './IMateriaPair.sol';
import './IERC20.sol';
import './IERC20WrapperV1.sol';

import './MateriaLibrary.sol';
import './TransferHelper.sol';

contract MateriaLiquidityAdder is MateriaOperator {
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        address factory = address(IMateriaOrchestrator(address(this)).factory());

        // create the pair if it doesn't exist yet
        if (IMateriaFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IMateriaFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = MateriaLibrary.getReserves(address(factory), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = MateriaLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = MateriaLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _doAddLiquidity(
        address token,
        address bridgeToken,
        uint256 tokenAmountDesired,
        uint256 bridgeAmountDesired,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to
    )
        private
        returns (
            uint256 tokenAmount,
            uint256 bridgeAmount,
            uint256 liquidity
        )
    {
        (tokenAmount, bridgeAmount) = _addLiquidity(
            token,
            bridgeToken,
            tokenAmountDesired,
            bridgeAmountDesired,
            tokenAmountMin,
            bridgeAmountMin
        );

        address pair =
            MateriaLibrary.pairFor(address(IMateriaOrchestrator(address(this)).factory()), token, bridgeToken);
        TransferHelper.safeTransfer(token, pair, tokenAmount);
        TransferHelper.safeTransferFrom(bridgeToken, msg.sender, pair, bridgeAmount);
        liquidity = IMateriaPair(pair).mint(to);
    }

    function addLiquidity(
        address token,
        uint256 tokenAmountDesired,
        uint256 bridgeAmountDesired,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) {
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        address interoperable;

        tokenAmountMin = _adjustAmount(token, tokenAmountMin);

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), tokenAmountDesired);
        (interoperable, tokenAmountDesired) = _wrapErc20(token, tokenAmountDesired, erc20Wrapper);

        (uint256 tokenAmount, , ) =
            _doAddLiquidity(
                interoperable,
                address(IMateriaOrchestrator(address(this)).bridgeToken()),
                tokenAmountDesired,
                bridgeAmountDesired,
                tokenAmountMin,
                bridgeAmountMin,
                to
            );

        uint256 dust = tokenAmountDesired - tokenAmount;
        if (dust > 0) _unwrapErc20(IERC20WrapperV1(erc20Wrapper).object(token), token, dust, erc20Wrapper, msg.sender);
    }

    function addLiquidityETH(
        uint256 bridgeAmountDesired,
        uint256 ethAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    )
        public
        payable
        ensure(deadline)
        returns (
            uint256 ethAmount,
            uint256 bridgeAmount,
            uint256 liquidity
        )
    {
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());

        address ieth =
            address(
                IERC20WrapperV1(erc20Wrapper).asInteroperable(
                    uint256(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID())
                )
            );

        (ethAmount, bridgeAmount) = _addLiquidity(
            ieth,
            bridgeToken,
            msg.value,
            bridgeAmountDesired,
            ethAmountMin,
            bridgeAmountMin
        );

        _wrapEth(ethAmount, erc20Wrapper);

        address pair =
            MateriaLibrary.pairFor(address(IMateriaOrchestrator(address(this)).factory()), ieth, bridgeToken);
        TransferHelper.safeTransfer(ieth, pair, ethAmount);
        TransferHelper.safeTransferFrom(bridgeToken, msg.sender, pair, bridgeAmount);
        liquidity = IMateriaPair(pair).mint(to);

        uint256 dust;
        if ((dust = msg.value - ethAmount) > 0) TransferHelper.safeTransferETH(msg.sender, dust);
    }

    function addLiquidityItem(
        uint256 itemId,
        uint256 value,
        address from,
        bytes memory payload
    ) private returns (uint256 itemAmount, uint256 bridgeAmount) {
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());

        uint256 bridgeAmountDesired;
        address to;
        uint256 deadline;
        address token;

        (bridgeAmountDesired, itemAmount, bridgeAmount, to, deadline) = abi.decode(
            payload,
            (uint256, uint256, uint256, address, uint256)
        );

        _ensure(deadline);

        (itemAmount, bridgeAmount) = _addLiquidity(
            (token = address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId))),
            bridgeToken,
            value,
            bridgeAmountDesired,
            itemAmount,
            bridgeAmount
        );

        address pair =
            MateriaLibrary.pairFor(address(IMateriaOrchestrator(address(this)).factory()), token, bridgeToken);
        TransferHelper.safeTransfer(token, pair, itemAmount);
        TransferHelper.safeTransferFrom(bridgeToken, from, pair, bridgeAmount);
        IMateriaPair(pair).mint(to);

        // value now is for the possible dust
        if ((value = value - itemAmount) > 0) TransferHelper.safeTransfer(token, from, value);
        if ((value = bridgeAmountDesired - bridgeAmount) > 0) TransferHelper.safeTransfer(bridgeToken, from, value);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        uint256 operation;
        bytes memory payload;

        (operation, payload) = abi.decode(data, (uint256, bytes));

        if (operation == 1) {
            addLiquidityItem(id, value, from, payload);
        } else revert();

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    function supportsInterface(bytes4) public pure override returns (bool) {
        return false;
    }
}