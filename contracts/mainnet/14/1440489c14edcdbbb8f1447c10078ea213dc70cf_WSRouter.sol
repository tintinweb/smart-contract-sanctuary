/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


interface IWSFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}



interface IWSPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swapDiscount(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint discount) external;
    function skim(address to) external;
    function sync() external;
    function isLocked() external view returns (uint);

    function initialize(address _factory, address _token0, address _token1) external returns(bool);
}


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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

library WSLibrary {
    using SafeMath for uint;
    // Swap fee discount
    uint96 constant FEE_BORDER_01 = 100 * 1e18;
    uint96 constant FEE_BORDER_02 = 1000 * 1e18;
    uint96 constant FEE_BORDER_03 = 10_000 * 1e18;
    uint96 constant FEE_BORDER_04 = 100_000 * 1e18;
    uint96 constant FEE_BORDER_05 = 1_000_000 * 1e18;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'WSLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'WSLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'fad2a9a251fff38151d87d2aa4e39e75ad40feabd873069329d3c31ab9afe018' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IWSPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'WSLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'WSLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        return getAmountOut(amountIn, reserveIn, reserveOut, uint256(0));
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint discount) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'WSLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'WSLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9970 + discount);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10_000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint) {
        return getAmountIn(amountOut, reserveIn, reserveOut, uint(0));
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint discount) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'WSLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'WSLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10_000);
        uint denominator = reserveOut.sub(amountOut).mul(9970 + discount);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        return getAmountsOut(factory, amountIn, path, uint(0));
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path, uint256 discount) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'WSLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, discount);
        }
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        amounts = getAmountsIn(factory, amountOut, path, uint(0));
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path, uint discount) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'WSLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, discount);
        }
    }

    // Returns amount of discount for account
    function getDiscount(address account, uint256 balance) internal view returns (uint256) {
        if (isContract(account)) {
            return 0;
        }
        if (balance < FEE_BORDER_01) {
            return 0;
        } 
        if (balance < FEE_BORDER_02) {
            return 1;
        }
        if (balance < FEE_BORDER_03) {
            return 2;
        }
        if (balance < FEE_BORDER_04) {
            return 3;
        }
        if (balance < FEE_BORDER_05) {
            return 4;
        }
        return 5;
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface IWSRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(bool burnGasToken,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(bool burnGasToken,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(bool burnGasToken,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(bool burnGasToken,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(bool burnGasToken,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(bool burnGasToken,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(bool burnGasToken,uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(bool burnGasToken,uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(bool burnGasToken,uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(bool burnGasToken,uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(bool burnGasToken,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(bool burnGasToken,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(bool burnGasToken,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWSERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}



interface IChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IWSImplementation {
	function getImplementationType() external pure returns(uint256);
}

contract WSRouter is IWSRouter, IWSImplementation {
    using SafeMath for uint;

    bool private initialized;
    address public override factory;
    address public override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'WSRouter: EXPIRED');
        _;
    }

    modifier discountCHI(bool burnChi) {
        // strange if structure required for contract size optimization
        uint256 gasStart;
        if(burnChi) {
            gasStart = gasleft();
        }
        _;
        if(burnChi) {
            _freeChi(gasStart);
        }
    }

    function _freeChi(uint256 gasStart) internal {
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        _getChi().freeFromUpTo(msg.sender, (gasSpent + 14174) / 41947);
    }

    function initialize(address _factory, address _WETH) public returns(bool) {
        require(initialized == false, "WSRouter: Alredy initialized.");
        factory = _factory;
        WETH = _WETH;
        initialized = true;
        return true;
    }

    receive() external payable {
    }

    function _getChi() internal virtual pure returns(IChi) {
        return IChi(address(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c));
    }

    function _getWSE() internal virtual pure returns(IERC20) {
        return IERC20(address(0x77b8ae2E83c7d044d159878445841E2A9777Af38));
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IWSFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IWSFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = WSLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = WSLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'WSRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = WSLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'WSRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        bool burnGasToken,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override discountCHI(burnGasToken) ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // avoid stack too deep error
        address tokenAstacked = tokenA;
        address tokenBstacked = tokenB;
        address pair = WSLibrary.pairFor(factory, tokenAstacked, tokenBstacked);
        TransferHelper.safeTransferFrom(tokenAstacked, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenBstacked, msg.sender, pair, amountB);
        liquidity = IWSPair(pair).mint(to);
    }
    function addLiquidityETH(
        bool burnGasToken,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable discountCHI(burnGasToken) ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = WSLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IWSPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****

    // spacer function to avoid too big stack error
    function _makeLiquidityPermit(
        address tokenA,
        address tokenB, 
        uint256 liquidity, 
        bool approveMax, 
        uint256 deadline, 
        uint8 v, bytes32 r, bytes32 s
        ) internal {
        address pair = WSLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IWSERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    // spacer function to avoid too big stack error
    function _remLiqNoChi(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal returns(uint amountA, uint amountB) {
        (amountA, amountB) = removeLiquidity(false, tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidity(
        bool burnGasToken,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override discountCHI(burnGasToken) ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = WSLibrary.pairFor(factory, tokenA, tokenB);
        IWSERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // Avoid stack too big error
        (address tokenAstacked, address tokenBstacked) = (tokenA, tokenB);
        (uint amount0, uint amount1) = IWSPair(pair).burn(to);
        (address token0,) = WSLibrary.sortTokens(tokenAstacked, tokenBstacked);
        (amountA, amountB) = tokenAstacked == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'WSRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'WSRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override discountCHI(burnGasToken) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            false,
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        bool burnGasToken,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override discountCHI(burnGasToken) returns (uint amountA, uint amountB) {
        _makeLiquidityPermit(tokenA, tokenB, liquidity, approveMax, deadline, v, r, s);
        // address pair = WSLibrary.pairFor(factory, tokenA, tokenB);
        // uint value = approveMax ? uint(-1) : liquidity;
        // IWSERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = _remLiqNoChi(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override discountCHI(burnGasToken) returns (uint amountToken, uint amountETH) {
        _makeLiquidityPermit(token, WETH, liquidity, approveMax, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(false, token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override discountCHI(burnGasToken) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            false,
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        bool burnGasToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override discountCHI(burnGasToken) returns (uint amountETH) {
        _makeLiquidityPermit(token, WETH, liquidity, approveMax, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            false, token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to, uint discount) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = WSLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? WSLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IWSPair(WSLibrary.pairFor(factory, input, output)).swapDiscount(
                amount0Out, amount1Out, to, new bytes(0), discount
            );
        }
    }
    function swapExactTokensForTokens(
        bool burnGasToken,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override discountCHI(burnGasToken) ensure(deadline) returns (uint[] memory amounts) {
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        amounts = WSLibrary.getAmountsOut(factory, amountIn, path, discount);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, discount);
    }
    function swapTokensForExactTokens(
        bool burnGasToken,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override discountCHI(burnGasToken) ensure(deadline) returns (uint[] memory amounts) {
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        amounts = WSLibrary.getAmountsIn(factory, amountOut, path, discount);
        require(amounts[0] <= amountInMax, 'WSRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, discount);
    }
    function swapExactETHForTokens(bool burnGasToken,uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        discountCHI(burnGasToken)
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'WSRouter: INVALID_PATH');
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        amounts = WSLibrary.getAmountsOut(factory, msg.value, path, discount);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, discount);
    }
    function swapTokensForExactETH(bool burnGasToken,uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        discountCHI(burnGasToken)
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'WSRouter: INVALID_PATH');
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        amounts = WSLibrary.getAmountsIn(factory, amountOut, path, discount);
        require(amounts[0] <= amountInMax, 'WSRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), discount);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(bool burnGasToken,uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        discountCHI(burnGasToken)
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'WSRouter: INVALID_PATH');
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        amounts = WSLibrary.getAmountsOut(factory, amountIn, path, discount);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), discount);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(bool burnGasToken,uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        discountCHI(burnGasToken)
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'WSRouter: INVALID_PATH');
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        amounts = WSLibrary.getAmountsIn(factory, amountOut, path, discount);
        require(amounts[0] <= msg.value, 'WSRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, discount);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        uint discount = WSLibrary.getDiscount(msg.sender, _getWSE().balanceOf(msg.sender));
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = WSLibrary.sortTokens(input, output);
            IWSPair pair = IWSPair(WSLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = WSLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, discount);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? WSLibrary.pairFor(factory, output, path[i + 2]) : _to;
            uint _discount = discount; // Avoid stack too deep errors
            pair.swapDiscount(amount0Out, amount1Out, to, new bytes(0), _discount);
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        bool burnGasToken,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) discountCHI(burnGasToken) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        bool burnGasToken,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
        discountCHI(burnGasToken)
    {
        require(path[0] == WETH, 'WSRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(WSLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        bool burnGasToken,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        discountCHI(burnGasToken)
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'WSRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    // deleted

    function getImplementationType() external pure override returns(uint256) {
        /// 3 is a router type
        return 3;
    }
}