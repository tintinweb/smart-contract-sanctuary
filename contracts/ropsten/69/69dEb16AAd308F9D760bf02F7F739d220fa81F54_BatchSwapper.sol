// SPDX-License-Identifier: GPL3
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IBatchSwapper {
    
    struct TokenIn {
        address token;
        uint256 amount;
    }
    
    struct TokenOut {
        address token;
        uint256 millesimals;
        uint256 amountMin;
    }
    
    struct Settings {
        address factory;
        bytes32 pairHash;
        address bridgeToken;
        address weth;
        uint deadline;
        address to;
    }

    function batchSwap(
        TokenIn calldata tokenIn,
        TokenOut[] calldata tokensOut,
        Settings calldata settings
    ) external returns(uint[] memory amountsOut);
    
    function batchSwapEth(
        TokenOut[] calldata tokensOut,
        Settings calldata settings
    ) external payable returns(uint[] memory amountsOut);

    function getAmountsOut(
        TokenIn calldata tokenIn,
        TokenOut[] calldata tokensOut,
        Settings calldata settings
    ) view external returns(uint bridgeAmount, uint[] memory amountsOut);
}

contract BatchSwapper is IBatchSwapper{
    using SafeMath for uint256;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'Materia: Expired');
        _;
    }
    
    receive() external payable {}

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function sortTokens(address tokenA, address tokenB) private pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'MateriaLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MateriaLibrary: ZERO_ADDRESS');
    }

    /* Calculates the CREATE2 address for a pair without making any external calls */
    function pairFor(
        address factory,
        bytes32 pairHash,
        address tokenA,
        address tokenB
    ) private pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            pairHash // init code hash, depends solely on the MateriaPair contract
        )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        bytes32 pairHash,
        address tokenA,
        address tokenB
    ) private view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IMateriaPair(pairFor(factory, pairHash, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /* Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) private pure returns (uint256 amountOut) {
        require(amountIn > 0, 'MateriaLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MateriaLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    
    function batchSwap(
        TokenIn calldata tokenIn,
        TokenOut[] calldata tokensOut,
        Settings calldata settings
    ) ensure(settings.deadline) override external returns(uint[] memory amountsOut) {
        if (tokenIn.token == settings.bridgeToken) {
            safeTransferFrom(settings.bridgeToken, msg.sender, address(this), tokenIn.amount);
            amountsOut = _batchSwapOut(tokensOut, tokenIn.amount, settings);
        } else {
            address pair = pairFor(settings.factory, settings.pairHash, settings.bridgeToken, tokenIn.token);
            safeTransferFrom(tokenIn.token, msg.sender, pair, tokenIn.amount);
            (uint reserveBridge, uint reserveToken) = getReserves(settings.factory, settings.pairHash, settings.bridgeToken, tokenIn.token);
            
            uint amount;
    
            if (IMateriaPair(pair).token0() == tokenIn.token)
                IMateriaPair(pair).swap(0, amount = getAmountOut(tokenIn.amount, reserveToken, reserveBridge), address(this), new bytes(0));
            else
                IMateriaPair(pair).swap(amount = getAmountOut(tokenIn.amount, reserveToken, reserveBridge), 0, address(this), new bytes(0));
            
            amountsOut = _batchSwapOut(tokensOut, amount, settings);
        }
    }
    
    function batchSwapEth(
        TokenOut[] calldata tokensOut,
        Settings calldata settings
    ) ensure(settings.deadline) payable override external returns(uint[] memory amountsOut) {
        uint amount;
        IWETH(settings.weth).deposit{value: msg.value}();
        if (settings.weth != settings.bridgeToken) {
            address pair = pairFor(settings.factory, settings.pairHash, settings.bridgeToken, settings.weth);
            safeTransfer(settings.weth, pair, msg.value);
            (uint reserveBridge, uint reserveWEth) = getReserves(settings.factory, settings.pairHash, settings.bridgeToken, settings.weth);
            
            if (IMateriaPair(pair).token0() == settings.weth)
                IMateriaPair(pair).swap(0, amount = getAmountOut(msg.value, reserveWEth, reserveBridge), address(this), new bytes(0));
            else
                IMateriaPair(pair).swap(amount = getAmountOut(msg.value, reserveWEth, reserveBridge), 0, address(this), new bytes(0));
        } else
            amount = msg.value;

        amountsOut = _batchSwapOut(tokensOut, amount, settings);
    }

    function _batchSwapOut(
        TokenOut[] calldata tokensOut,
        uint amountIn,
        Settings memory settings
    ) private returns(uint[] memory amountsOut) {
        uint amountInRemainder = amountIn;
        amountsOut = new uint[](tokensOut.length);
        
        for(uint i = 0; i < tokensOut.length; i++) {
            uint partialAmountIn;
            
            if (i < tokensOut.length - 1){
                partialAmountIn = amountIn * tokensOut[i].millesimals / 1000;
                amountInRemainder -= partialAmountIn;
            } else
                partialAmountIn = amountInRemainder;

            if (tokensOut[i].token == settings.bridgeToken) {
                safeTransfer(settings.bridgeToken, settings.to, partialAmountIn);
                require(partialAmountIn >= tokensOut[i].amountMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
                amountsOut[i] = partialAmountIn;
                continue;
            }
            
            (uint reserveBridge, uint reserveToken) = getReserves(settings.factory, settings.pairHash, settings.bridgeToken, tokensOut[i].token != address(0) ? tokensOut[i].token : settings.weth);
            address pair = pairFor(settings.factory, settings.pairHash, settings.bridgeToken, tokensOut[i].token != address(0) ? tokensOut[i].token : settings.weth);
            
            uint amountOut = getAmountOut(partialAmountIn, reserveBridge, reserveToken);
            require(amountOut >= tokensOut[i].amountMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            amountsOut[i] = partialAmountIn;

            safeTransfer(settings.bridgeToken, pair, partialAmountIn);
            
            if (IMateriaPair(pair).token0() == settings.bridgeToken)
                if (tokensOut[i].token != address(0))
                    IMateriaPair(pair).swap(0, amountOut, settings.to, new bytes(0));
                else
                    IMateriaPair(pair).swap(0, amountOut, address(this), new bytes(0));
            else
                if (tokensOut[i].token != address(0))
                    IMateriaPair(pair).swap(amountOut, 0, settings.to, new bytes(0));
                else 
                    IMateriaPair(pair).swap(amountOut, 0, address(this), new bytes(0));
                    
            if (tokensOut[i].token == address(0)) {
                IWETH(settings.weth).withdraw(amountOut);
                safeTransferETH(settings.to, amountOut);
            }
        }
    }

    function getAmountsOut(
        TokenIn calldata tokenIn,
        TokenOut[] calldata tokensOut,
        Settings calldata settings
    ) override view external returns(uint bridgeAmount, uint[] memory amountsOut) {
        if (tokenIn.token == settings.bridgeToken)
            bridgeAmount = tokenIn.amount;
        else {
            (uint reserveBridge, uint reserveToken) = getReserves(settings.factory, settings.pairHash, settings.bridgeToken, tokenIn.token);
            bridgeAmount = getAmountOut(tokenIn.amount, reserveToken, reserveBridge);
        }

        uint amountInRemainder = bridgeAmount;
        amountsOut = new uint[](tokensOut.length);
        
        for(uint i = 0; i < tokensOut.length; i++) {
            uint partialAmountIn;
            if (i < tokensOut.length - 1){
                partialAmountIn = bridgeAmount * tokensOut[i].millesimals / 1000;
                amountInRemainder -= partialAmountIn;
            } else
                partialAmountIn = amountInRemainder;

            if (tokensOut[i].token == settings.bridgeToken) {
                amountsOut[i] = partialAmountIn;
                continue;
            }

            (uint reserveBridge, uint reserveToken) = getReserves(settings.factory, settings.pairHash, settings.bridgeToken, tokensOut[i].token != address(0) ? tokensOut[i].token : settings.weth);            
            amountsOut[i] = getAmountOut(partialAmountIn, reserveBridge, reserveToken);
        }
    }

}

interface IMateriaPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    function balanceOf(
        address account
    ) external view returns (
        uint256
    );
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (
        bool
    );
    function allowance(
        address owner,
        address spender
    ) external view returns (
        uint256
    );
    function approve(
        address spender,
        uint256 amount
    ) external returns (
        bool
    );
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (
        bool
    );
}

