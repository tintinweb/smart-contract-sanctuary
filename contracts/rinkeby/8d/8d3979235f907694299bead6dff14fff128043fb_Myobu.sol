// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Snapshot.sol";

contract Myobu is ERC20Snapshot {
    address public override DAO; // solhint-disable-line
    address public override myobuSwap;

    bool private antiLiqBot;

    constructor(address payable addr1) MyobuBase(addr1) {
        setFees(Fees(1, 10, 10, 10));
    }

    modifier onlySupportedPair(address pair) {
        require(taxedPair(pair), "Pair is not supported");
        _;
    }

    modifier onlyMyobuswapOnAntiLiq() {
        require(!antiLiqBot || _msgSender() == myobuSwap, "Use MyobuSwap");
        _;
    }

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction expired");
        _;
    }

    function setDAO(address newDAO) external onlyOwner {
        DAO = newDAO;
        emit DAOChanged(newDAO);
    }

    function setMyobuSwap(address newMyobuSwap) external onlyOwner {
        myobuSwap = newMyobuSwap;
        emit MyobuSwapChanged(newMyobuSwap);
    }

    function snapshot() external returns (uint256) {
        require(_msgSender() == owner() || _msgSender() == DAO);
        return _snapshot();
    }

    function setAntiLiqBot(bool setTo) public virtual onlyOwner {
        antiLiqBot = setTo;
    }

    function noFeeAddLiquidityETH(LiquidityETHParams calldata params)
        external
        payable
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        onlyMyobuswapOnAntiLiq
        lockTheSwap
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        _transfer(_msgSender(), address(this), params.amountTokenOrLP);
        uint256 beforeBalance = address(this).balance - msg.value;
        (amountToken, amountETH, liquidity) = IUniswapV2Router(
            _routerFor[params.pair]
        ).addLiquidityETH{value: msg.value}(
            address(this),
            params.amountTokenOrLP,
            params.amountTokenMin,
            params.amountETHMin,
            params.to,
            block.timestamp
        );
        // router refunds to this address, refund all back to sender
        if (address(this).balance > beforeBalance) {
            payable(_msgSender()).transfer(
                address(this).balance - beforeBalance
            );
        }
        emit LiquidityAddedETH(params.pair, amountToken, amountETH, liquidity);
    }

    function noFeeRemoveLiquidityETH(LiquidityETHParams calldata params)
        external
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        lockTheSwap
        returns (uint256 amountToken, uint256 amountETH)
    {
        MyobuLib.transferTokens(
            params.pair,
            _msgSender(),
            address(this),
            params.amountTokenOrLP
        );
        (amountToken, amountETH) = IUniswapV2Router(_routerFor[params.pair])
            .removeLiquidityETH(
                address(this),
                params.amountTokenOrLP,
                params.amountTokenMin,
                params.amountETHMin,
                params.to,
                block.timestamp
            );
        emit LiquidityRemovedETH(
            params.pair,
            amountToken,
            amountETH,
            params.amountTokenOrLP
        );
    }

    function noFeeAddLiquidity(AddLiquidityParams calldata params)
        external
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        onlyMyobuswapOnAntiLiq
        lockTheSwap
        returns (
            uint256 amountMyobu,
            uint256 amountToken,
            uint256 liquidity
        )
    {
        address token = MyobuLib.tokenFor(params.pair);
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        _transfer(_msgSender(), address(this), params.amountToken);
        MyobuLib.transferTokens(
            token,
            _msgSender(),
            address(this),
            params.amountTokenB
        );
        (amountToken, amountMyobu, liquidity) = IUniswapV2Router(
            _routerFor[params.pair]
        ).addLiquidity(
                token,
                address(this),
                params.amountTokenB,
                params.amountToken,
                params.amountTokenBMin,
                params.amountTokenMin,
                params.to,
                block.timestamp
            );
        // router refunds to this address, refund all back to sender
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        if (currentBalance > beforeBalance) {
            IERC20(token).transfer(
                _msgSender(),
                currentBalance - beforeBalance
            );
        }
        emit LiquidityAdded(params.pair, amountMyobu, amountToken, liquidity);
    }

    function noFeeRemoveLiquidity(RemoveLiquidityParams calldata params)
        external
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        lockTheSwap
        returns (uint256 amountMyobu, uint256 amountToken)
    {
        MyobuLib.transferTokens(
            params.pair,
            _msgSender(),
            address(this),
            params.amountLP
        );
        (amountToken, amountMyobu) = IUniswapV2Router(_routerFor[params.pair])
            .removeLiquidity(
                MyobuLib.tokenFor(params.pair),
                address(this),
                params.amountLP,
                params.amountTokenBMin,
                params.amountTokenMin,
                params.to,
                block.timestamp
            );
        emit LiquidityRemoved(
            params.pair,
            amountMyobu,
            amountToken,
            params.amountLP
        );
    }
}