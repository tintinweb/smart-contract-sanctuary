/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

//SPDX-License-Identifier: None
pragma solidity =0.7.6;

interface IFlareXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToAmount() external view returns (uint);
    function feeBase() external view returns (uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function approvePairsTokenSpender(address pair, address token, address spender, uint value) external returns (bool);
}

interface IFlareXPair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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
    function swapNoFee(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function approveTokenSpender(address token, address spender, uint value) external returns (bool);

    function initialize(address, address) external;
}

interface IFlareXRouter {
    function factory() external view returns (address);
    function WFLR() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityFLR(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFLRMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountFLR, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityFLR(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFLRMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFLR);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityFLRWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFLRMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFLR);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokensYFLRFee(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokensYFLRFee(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactFLRForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapExactFLRForTokensYFLRFee(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapTokensForExactFLR(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapTokensForExactFLRYFLRFee(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    
    function swapExactTokensForFLR(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactTokensForFLRYFLRFee(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapFLRForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapFLRForExactTokensYFLRFee(uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut);
    function getAmountOutNoFee(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn);
    function getAmountInNoFee(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOutYFLRFee(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsInYFLRFee(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

interface IWFLR {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract FlareXRouter is IFlareXRouter {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WFLR;
    IERC20 public immutable YFLR;
    
    uint public feeYFLR;
    address public feeSetter;
    
    event ChangeFee(uint newFee, string feeType);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'FlareXRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WFLR, address _yflr, address _feeSetter) {
        factory = _factory;
        WFLR = _WFLR;
        YFLR = IERC20(_yflr);
        feeYFLR = 30;
        feeSetter = _feeSetter;
    }

    receive() external payable {
        assert(msg.sender == WFLR); // only accept FLR via fallback from the WFLR contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal view virtual returns (uint amountA, uint amountB) {
        require(IFlareXFactory(factory).getPair(tokenA, tokenB) != address(0), "FlareXRouter: PAIR_NOT_EXISTS");
        (uint reserveA, uint reserveB) = FlareXLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = FlareXLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'FlareXRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = FlareXLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'FlareXRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = FlareXLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IFlareXPair(pair).mint(to);
    }
    function addLiquidityFLR(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFLRMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountFLR, uint liquidity) {
        (amountToken, amountFLR) = _addLiquidity(token, WFLR, amountTokenDesired, msg.value, amountTokenMin, amountFLRMin);
        address pair = FlareXLibrary.pairFor(factory, token, WFLR);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWFLR(WFLR).deposit{value: amountFLR}();
        assert(IWFLR(WFLR).transfer(pair, amountFLR));
        liquidity = IFlareXPair(pair).mint(to);
        // refund dust flr, if any
        if (msg.value > amountFLR) TransferHelper.safeTransferFLR(msg.sender, msg.value - amountFLR);
    }

    // **** REMOVE LIQUIDITY ****
    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        address yflrTo
    ) internal virtual returns (uint amountA, uint amountB) {
        address pair = FlareXLibrary.pairFor(factory, tokenA, tokenB);
        IFlareXPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair //TODO: check functions order
        if (tokenA != address(YFLR) && tokenB != address(YFLR)) {
            uint yflrBalance = YFLR.balanceOf(pair);
            if (yflrBalance != 0) {
                uint totalLiquidity = IFlareXPair(pair).totalSupply();
                uint yflrAmount = yflrBalance.mul(liquidity) / totalLiquidity;
                YFLR.transferFrom(pair, yflrTo, yflrAmount);
            }
        }
        (uint amount0, uint amount1) = IFlareXPair(pair).burn(to);
        (address token0,) = FlareXLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'FlareXRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'FlareXRouter: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        return _removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, to);
    }

    function removeLiquidityFLR(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFLRMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountFLR) {
        (amountToken, amountFLR) = _removeLiquidity(
            token,
            WFLR,
            liquidity,
            amountTokenMin,
            amountFLRMin,
            address(this),
            to
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWFLR(WFLR).withdraw(amountFLR);
        TransferHelper.safeTransferFLR(to, amountFLR);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        { //scope to avoid stack too deep errors
        address pair = FlareXLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IFlareXPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s); //check deadline in permit
        }
        (amountA, amountB) = _removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, to);
    }

    function removeLiquidityFLRWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFLRMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountFLR) {
        address pair = FlareXLibrary.pairFor(factory, token, WFLR);
        uint value = approveMax ? uint(-1) : liquidity;
        IFlareXPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s); 
        (amountToken, amountFLR) = removeLiquidityFLR(token, liquidity, amountTokenMin, amountFLRMin, to, deadline);
    }


    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to, bool isBaseFee) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            uint amount0Out;
            uint amount1Out;
            address to;
            address pair;
            {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = FlareXLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (amount0Out, amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            to = i < path.length - 2 ? FlareXLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair = FlareXLibrary.pairFor(factory, input, output);
            }
            if (isBaseFee) {
                IFlareXPair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
            } else {
                IFlareXPair(pair).swapNoFee(amount0Out, amount1Out, to, new bytes(0));
                YFLR.transferFrom(msg.sender, pair, amounts[i + path.length]);
            }
        }
    }



    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = FlareXLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'FlareXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, true);
    }

    function swapExactTokensForTokensYFLRFee(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] != address(YFLR) && path[path.length - 1] != address(YFLR), "FlareXRouter: YFLR_IN_BASE_PAIR");
        amounts = FlareXLibrary.getAmountsOutYFLRFee(factory, address(YFLR), amountIn, path, feeYFLR);
        require(amounts[path.length - 1] >= amountOutMin, 'FlareXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, false);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = FlareXLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'FlareXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, true);
    }

    function swapTokensForExactTokensYFLRFee(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] != address(YFLR) && path[path.length - 1] != address(YFLR), "FlareXRouter: YFLR_IN_BASE_PAIR");
        amounts = FlareXLibrary.getAmountsInYFLRFee(factory, address(YFLR), amountOut, path, feeYFLR);
        require(amounts[0] <= amountInMax, 'FlareXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, false);
    }



    function swapExactFLRForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WFLR, 'FlareXRouter: INVALID_PATH');
        amounts = FlareXLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'FlareXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWFLR(WFLR).deposit{value: amounts[0]}();
        assert(IWFLR(WFLR).transfer(FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, true);
    }

    function swapExactFLRForTokensYFLRFee(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WFLR, 'FlareXRouter: INVALID_PATH');
        require(path[path.length - 1] != address(YFLR), "FlareXRouter: YFLR_IN_BASE_PAIR");
        amounts = FlareXLibrary.getAmountsOutYFLRFee(factory, address(YFLR), msg.value, path, feeYFLR);    
        require(amounts[path.length - 1] >= amountOutMin, 'FlareXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWFLR(WFLR).deposit{value: amounts[0]}();
        assert(IWFLR(WFLR).transfer(FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, false);
    }

    function swapTokensForExactFLR(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WFLR, 'FlareXRouter: INVALID_PATH');
        amounts = FlareXLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'FlareXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), true);
        IWFLR(WFLR).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferFLR(to, amounts[amounts.length - 1]);
    }

    function swapTokensForExactFLRYFLRFee(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WFLR, 'FlareXRouter: INVALID_PATH');
        require(path[0] != address(YFLR), "FlareXRouter: YFLR_IN_BASE_PAIR");
        amounts = FlareXLibrary.getAmountsInYFLRFee(factory, address(YFLR), amountOut, path, feeYFLR);
        require(amounts[0] <= amountInMax, 'FlareXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), false);
        IWFLR(WFLR).withdraw(amounts[path.length - 1]);
        TransferHelper.safeTransferFLR(to, amounts[path.length - 1]);
    }



    function swapExactTokensForFLR(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WFLR, 'FlareXRouter: INVALID_PATH');
        amounts = FlareXLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'FlareXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), true);
        IWFLR(WFLR).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferFLR(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForFLRYFLRFee(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WFLR, 'FlareXRouter: INVALID_PATH');
        require(path[0] != address(YFLR), "FlareXRouter: YFLR_IN_BASE_PAIR");
        amounts = FlareXLibrary.getAmountsOutYFLRFee(factory, address(YFLR), amountIn, path, feeYFLR);
        require(amounts[path.length - 1] >= amountOutMin, 'FlareXRouter: INSUFFICIENT_OUTPUT_AMOUNT'); 
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), false);
        IWFLR(WFLR).withdraw(amounts[path.length - 1]);
        TransferHelper.safeTransferFLR(to, amounts[path.length - 1]);
    }

    function swapFLRForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WFLR, 'FlareXRouter: INVALID_PATH');
        amounts = FlareXLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'FlareXRouter: EXCESSIVE_INPUT_AMOUNT');
        IWFLR(WFLR).deposit{value: amounts[0]}();
        assert(IWFLR(WFLR).transfer(FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, true);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferFLR(msg.sender, msg.value - amounts[0]);
    }

    function swapFLRForExactTokensYFLRFee(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WFLR, 'FlareXRouter: INVALID_PATH');
        require(path[path.length - 1] != address(YFLR), "FlareXRouter: YFLR_IN_BASE_PAIR");
        amounts = FlareXLibrary.getAmountsInYFLRFee(factory, address(YFLR), amountOut, path, feeYFLR);
        require(amounts[0] <= msg.value, 'FlareXRouter: EXCESSIVE_INPUT_AMOUNT');
        IWFLR(WFLR).deposit{value: amounts[0]}();
        assert(IWFLR(WFLR).transfer(FlareXLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, false);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferFLR(msg.sender, msg.value - amounts[0]);
    }


    // **** OWNER FUNCTIONS ****
    function setFeeToSetter(address _feeSetter) external {
        require(msg.sender == feeSetter, 'FlareXRouter: FORBIDDEN');
        feeSetter = _feeSetter;
    }

    function changeYFLRFee(uint newFee) external { 
        require (msg.sender == feeSetter, "FlareXRouter: FORBIDDEN");
        require (newFee > 0 && newFee <= 10000, "FlareXRouter: WRONG_FEE_AMOUNT");
        feeYFLR = newFee;
        emit ChangeFee(newFee, "feeYFLR");
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual override returns (uint amountB) {
        return FlareXLibrary.quote(amountA, reserveA, reserveB);
    }

    function getPairReserves(address tokenA, address tokenB)  external view virtual returns (uint reserveA, uint reserveB) {
        return FlareXLibrary.getReserves(factory, tokenA, tokenB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view virtual override returns (uint amountOut) {
        return FlareXLibrary.getAmountOut(amountIn, reserveIn, reserveOut, IFlareXFactory(factory).feeBase());
    }

    function getAmountOutNoFee(uint amountIn, uint reserveIn, uint reserveOut) external pure virtual override returns (uint amountOut) {
        return FlareXLibrary.getAmountOutNoFee(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view virtual override returns (uint amountIn) {
        return FlareXLibrary.getAmountIn(amountOut, reserveIn, reserveOut, IFlareXFactory(factory).feeBase());
    }

    function getAmountInNoFee(uint amountOut, uint reserveIn, uint reserveOut) external pure virtual override returns (uint amountIn) {
        return FlareXLibrary.getAmountInNoFee(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) external view virtual override returns (uint[] memory amounts) {
        return FlareXLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsOutYFLRFee(uint amountIn, address[] memory path) external view override virtual returns (uint[] memory amounts) {
        return FlareXLibrary.getAmountsOutYFLRFee(factory, address(YFLR), amountIn, path, feeYFLR);
    }

    function getAmountsIn(uint amountOut, address[] memory path) external view virtual override returns (uint[] memory amounts) {
        return FlareXLibrary.getAmountsIn(factory, amountOut, path);
    }

    function getAmountsInYFLRFee(uint amountOut, address[] memory path) external view override virtual returns (uint[] memory amounts) {       
        return FlareXLibrary.getAmountsInYFLRFee(factory, address(YFLR), amountOut, path, feeYFLR);
    }
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

library FlareXLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'FlareXLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'FlareXLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'4a6cccabe4c47c39df297b8d5b739706898c8748102d77c349b8f2b51c2bc4b5'
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IFlareXPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'FlareXLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'FlareXLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'FlareXLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FlareXLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(10000 - fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountOutNoFee(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'FlareXLibrary: INSUFFICIENT_INPUT_NO_FEE_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FlareXLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }

    function getYFLRFeeAmount(address factory, address yflr, address token, uint amountIn, uint fee) internal view returns (uint amountOut) {
        require(amountIn > 0, 'FlareXLibrary: INSUFFICIENT_INPUT_AMOUNT');
        (uint reserveToken, uint reserveYflr) = getReserves(factory, token, yflr);
        require(reserveToken > 0 && reserveYflr > 0, "FlareXLibrary: NO_YFLR_PAIR_FOR_TOKEN");
        uint amountInWithFee = amountIn.mul(fee);
        uint numerator = amountInWithFee.mul(reserveYflr);
        uint denominator = reserveToken.add(amountIn).mul(10000);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'FlareXLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FlareXLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(10000 - fee);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountInNoFee(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'FlareXLibrary: INSUFFICIENT_OUTPUT_NO_FEE_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FlareXLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FlareXLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        uint fee = IFlareXFactory(factory).feeBase();
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    function getAmountsOutYFLRFee(address factory, address yflr, uint amountIn, address[] memory path, uint fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FlareXLibrary: INVALID_PATH');
        //amounts = new uint[](path.length);
        amounts = new uint[](path.length * 2 - 1);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (address token0,) = sortTokens(path[i], path[i + 1]);
            address pair = pairFor(factory, path[i], path[i + 1]);
            (uint reserve0, uint reserve1,) = IFlareXPair(pair).getReserves();
            (uint reserveIn, uint reserveOut) = path[i] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amounts[i + 1] = getAmountOutNoFee(amounts[i], reserveIn, reserveOut);
            amounts[i + path.length] = getYFLRFeeAmount(factory, yflr, path[i], amounts[i], fee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FlareXLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        uint fee = IFlareXFactory(factory).feeBase();
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    function getAmountsInYFLRFee(address factory, address yflr, uint amountOut, address[] memory path, uint fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FlareXLibrary: INVALID_PATH');
        //amounts = new uint[](path.length);
        amounts = new uint[](path.length * 2 - 1);
        amounts[path.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (address token0,) = sortTokens(path[i - 1], path[i]);
            address pair = pairFor(factory, path[i - 1], path[i]);
            (uint reserve0, uint reserve1,) = IFlareXPair(pair).getReserves();
            (uint reserveIn, uint reserveOut) = path[i - 1] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amounts[i - 1] = getAmountInNoFee(amounts[i], reserveIn, reserveOut);
            amounts[i + path.length - 1] = getYFLRFeeAmount(factory, yflr, path[i - 1], amounts[i - 1], fee);
        }
    }    
}

// helper methods for interacting with ERC20 tokens and sending FLR that do not consistently return true/false
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

    function safeTransferFLR(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: FLR_TRANSFER_FAILED');
    }
}