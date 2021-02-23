// SPDX-License-Identifier: GPL3

pragma solidity 0.8.0;

import './IMVDFunctionalitiesManager.sol';
import './IDoubleProxy.sol';
import './IMVDProxy.sol';

import './IMateriaOrchestrator.sol';
import './IMateriaFactory.sol';

import './IEthItemInteroperableInterface.sol';
import './IERC20WrapperV1.sol';

import './MateriaLibrary.sol';
import './TransferHelper.sol';

abstract contract Proxy {
    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}

contract MateriaOrchestrator is Proxy, IMateriaOrchestrator {
    IDoubleProxy public override doubleProxy;

    address public override swapper;
    address public override liquidityAdder;
    address public override liquidityRemover;

    IMateriaFactory public override factory;
    IERC20WrapperV1 public override erc20Wrapper;
    IERC20 public override bridgeToken;
    uint256 public override ETHEREUM_OBJECT_ID;

    constructor(
        address initialFactory,
        address initialBridgeToken,
        address initialErc20Wrapper,
        address initialDoubleProxy,
        address initialLiquidityAdder,
        address initialLiquidityRemover,
        address initialSwapper
    ) {
        factory = IMateriaFactory(initialFactory);
        bridgeToken = IERC20(initialBridgeToken);
        erc20Wrapper = IERC20WrapperV1(initialErc20Wrapper);
        ETHEREUM_OBJECT_ID = uint256(keccak256(bytes('THE ETHEREUM OBJECT IT')));
        doubleProxy = IDoubleProxy(initialDoubleProxy);
        liquidityAdder = initialLiquidityAdder;
        liquidityRemover = initialLiquidityRemover;
        swapper = initialSwapper;
    }

    function setDoubleProxy(address newDoubleProxy) external override onlyDFO {
        doubleProxy = IDoubleProxy(newDoubleProxy);
    }

    function setBridgeToken(address newBridgeToken) external override onlyDFO {
        bridgeToken = IERC20(newBridgeToken);
    }

    function setErc20Wrapper(address newErc20Wrapper) external override onlyDFO {
        erc20Wrapper = IERC20WrapperV1(newErc20Wrapper);
    }

    function setFactory(address newFactory) external override onlyDFO {
        factory = IMateriaFactory(newFactory);
    }

    function setEthereumObjectId(uint256 newEthereumObjectId) external override onlyDFO {
        ETHEREUM_OBJECT_ID = newEthereumObjectId;
    }

    function setSwapper(address _swapper) external override onlyDFO {
        swapper = _swapper;
    }

    function setLiquidityAdder(address _adder) external override onlyDFO {
        liquidityAdder = _adder;
    }

    function setLiquidityRemover(address _remover) external override onlyDFO {
        liquidityRemover = _remover;
    }

    function retire(address newOrchestrator) external override onlyDFO {
        factory.transferOwnership(newOrchestrator);
    }

    function setFees(
        address token,
        uint256 materiaFee,
        uint256 swapFee
    ) external override onlyDFO {
        factory.setFees(MateriaLibrary.pairFor(address(factory), address(bridgeToken), token), materiaFee, swapFee);
    }

    function setDefaultFees(uint256 materiaFee, uint256 swapFee) external override onlyDFO {
        factory.setDefaultMateriaFee(materiaFee);
        factory.setDefaultSwapFee(swapFee);
    }

    function setFeeTo(address feeTo) external override onlyDFO {
        factory.setFeeTo(feeTo);
    }

    //better be safe than sorry
    function getCrumbs(
        address token,
        uint256 amount,
        address receiver
    ) external override onlyDFO {
        TransferHelper.safeTransfer(token, receiver, amount);
    }

    modifier onlyDFO() {
        require(IMVDFunctionalitiesManager(IMVDProxy(doubleProxy.proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized");
        _;
    }

    receive() external payable {
        require(msg.sender == address(erc20Wrapper), 'Only EthItem can send ETH to this contract');
    }

    /**
     * As ERC1155 receiver Materia Orchestrator implements onERC1155Received and onERC1155BatchReceived.
     * onERC1155Received exposes the delegate call to the Liquidity Adder, Remover Liquidity and to the Swapper contracts.
     * Calling with a callback you will be able to specify the operation needed.
     * onERC1155BatchReceived will be implemented with batch/lego operation.
     */

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata payload
    ) external override returns (bytes4) {
        (uint256 operation, ) = abi.decode(payload, (uint256, bytes));
        if (operation == 1) {
            //Adding liquidity
            _delegate(liquidityAdder);
        } else if (operation == 2 || operation == 3 || operation == 4 || operation == 5) {
            //Remove liquidity
            _delegate(swapper); //Swapping
        } else {
            revert();
        }

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert();
    }

    /**
     * Liquidity adding methods are exposed to call the Liquidity Adder contract via a secure channel such as the Orchestrator.
     * Both addLiquidity and addLiquidityETH methods are provided. addLiquidity can be used for ERC20 and ITEMs.
     */

    function addLiquidity(
        address token,
        uint256 tokenAmountDesired,
        uint256 bridgeAmountDesired,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        _delegate(liquidityAdder);
    }

    function addLiquidityETH(
        uint256 bridgeAmountDesired,
        uint256 EthAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        _delegate(liquidityAdder);
    }

    /**
     * Liquidity removing methods are exposed to call the Liquidity Remover contract via a secure channel such as the Orchestrator.
     * The following methods are provided:
     * removeLiquidity, removeLiquidityETH, removeLiquidityWithPermit and removeLiquidityETHWithPermit
     */

    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    ) public override {
        _delegate(liquidityRemover);
    }

    function removeLiquidityETH(
        uint256 liquidity,
        uint256 bridgeAmountMin,
        uint256 EthAmountMin,
        address to,
        uint256 deadline
    ) public override {
        _delegate(liquidityRemover);
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
    ) public override {
        _delegate(liquidityRemover);
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
    ) public override {
        _delegate(liquidityRemover);
    }

    /**
     * Swapping methods are exposed to call the Swapper Operator contract via a secure channel such as the Orchestrator.
     * The following methods are provided:
     * swapExactTokensForTokens, swapTokensForExactTokens, swapExactETHForTokens, swapTokensForExactETH, swapExactTokensForETH and swapETHForExactTokens
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) public override returns (uint256[] memory amounts) {
        _delegate(swapper);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) public override returns (uint256[] memory amounts) {
        _delegate(swapper);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) public payable override {
        _delegate(swapper);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) public override {
        _delegate(swapper);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) public override {
        _delegate(swapper);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 deadline
    ) public payable override {
        _delegate(swapper);
    }

    /**
     * Methods are exposed for the UI to retrive useful information such as quote, getAmountOut, getAmountIn, getAmountsOut, getAmountsIn
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure override returns (uint256 amountB) {
        return MateriaLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountOut) {
        return MateriaLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountIn) {
        return MateriaLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        override
        returns (uint256[] memory amounts)
    {
        return MateriaLibrary.getAmountsOut(address(factory), amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        override
        returns (uint256[] memory amounts)
    {
        return MateriaLibrary.getAmountsIn(address(factory), amountOut, path);
    }

    /**
     * isEthItem is a custom implementation to check whether a token is an ITEM or a standard ERC20.
     */

    function isEthItem(address token)
        public
        view
        override
        returns (
            address collection,
            bool ethItem,
            uint256 itemId
        )
    {
        if (token == address(0)) {
            return (address(0), false, 0);
        } else {
            try IEthItemInteroperableInterface(token).mainInterface() returns (address mainInterface) {
                return (mainInterface, true, IEthItemInteroperableInterface(token).objectId());
            } catch {
                return (address(0), false, 0);
            }
        }
    }
}