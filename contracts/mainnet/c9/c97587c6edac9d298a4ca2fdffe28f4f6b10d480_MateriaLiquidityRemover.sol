// SPDX-License-Identifier: GPL3
pragma solidity 0.8.0;

import './MateriaOperator.sol';
import './IMateriaOrchestrator.sol';
import './IMateriaPair.sol';
import './IERC20.sol';
import './IERC20WrapperV1.sol';

import './MateriaLibrary.sol';

contract MateriaLiquidityRemover is MateriaOperator {
    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountBridge, uint256 amountToken) {
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());
        address pair;

        {
            (bool ethItem, uint256 itemId) = _isEthItem(token, erc20Wrapper);
            token = ethItem ? token : address(IERC20WrapperV1(erc20Wrapper).asInteroperable(itemId));
            pair = MateriaLibrary.pairFor(address(IMateriaOrchestrator(address(this)).factory()), token, bridgeToken);
        }

        IMateriaPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IMateriaPair(pair).burn(to);
        (address token0, ) = MateriaLibrary.sortTokens(token, bridgeToken);
        (amountBridge, amountToken) = token0 == address(bridgeToken) ? (amount0, amount1) : (amount1, amount0);
        require(amountBridge >= bridgeAmountMin, 'INSUFFICIENT_BRIDGE_AMOUNT');
        require(amountToken >= tokenAmountMin, 'INSUFFICIENT_TOKEN_AMOUNT');
    }

    function removeLiquidityETH(
        uint256 liquidity,
        uint256 bridgeAmountMin,
        uint256 ethAmountMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountBridge, uint256 amountEth) {
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());
        address ieth = _tokenToInteroperable(address(0), erc20Wrapper);

        address pair =
            MateriaLibrary.pairFor(address(IMateriaOrchestrator(address(this)).factory()), ieth, bridgeToken);

        IMateriaPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IMateriaPair(pair).burn(address(this));
        (address token0, ) = MateriaLibrary.sortTokens(ieth, address(bridgeToken));
        (amountBridge, amountEth) = token0 == address(bridgeToken) ? (amount0, amount1) : (amount1, amount0);
        require(amountBridge >= bridgeAmountMin, 'INSUFFICIENT_BRIDGE_AMOUNT');
        require(amountEth >= ethAmountMin, 'INSUFFICIENT_TOKEN_AMOUNT');
        _unwrapEth(uint256(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID()), amountEth, erc20Wrapper, to);
    }

    function removeLiquidityWithPermit(
        address token,
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());

        address pair = MateriaLibrary.pairFor(factory, bridgeToken, token);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IMateriaPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        removeLiquidity(token, liquidity, tokenAmountMin, bridgeAmountMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        address factory = address(IMateriaOrchestrator(address(this)).factory());
        address bridgeToken = address(IMateriaOrchestrator(address(this)).bridgeToken());
        address erc20Wrapper = address(IMateriaOrchestrator(address(this)).erc20Wrapper());

        address pair = MateriaLibrary.pairFor(factory, bridgeToken, _tokenToInteroperable(address(0), erc20Wrapper));
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IMateriaPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        removeLiquidityETH(liquidity, bridgeAmountMin, tokenAmountMin, to, deadline);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
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