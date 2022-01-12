/**
 *Submitted for verification at snowtrace.io on 2022-01-12
*/

// SPDX-License-Identifier: Unlicensed

/**

Shibies Router Wrapper forwards the UniSwap router functions
to the Trader Joe router. This is necessary because the
Trader Joe router has changed function names. 
Since we exclude this contract from the transaction fee,
you can also add Wrapped TREATS liquidity via this contract
without paying the fee.

WTREATS: 0xBBCA403C20aD0932d0509af0132897a25aB1ebe0
Trader Joe Router: 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
*/

// File: contracts/traderjoe/interfaces/IJoePair.sol

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/traderjoe/libraries/JoeLibrary.sol

pragma solidity >=0.5.0;

library JoeLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91"
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "JoeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "JoeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}
// File: contracts/traderjoe/interfaces/IJoeRouter01.sol

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/traderjoe/interfaces/IJoeRouter02.sol

pragma solidity >=0.6.2;

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/traderjoe/interfaces/IWAVAX.sol

pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity =0.6.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract ShibiesRouterWrapper is IUniswapV2Router02 {
    using SafeMath for uint;

    address public burnAddress = 0xdEAD000000000000000042069420694206942069;

    address public immutable override factory;
    address public immutable override WETH;

    address public immutable joePair;
    address public immutable JoeRouter;
    address public immutable WTREATS;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'JoeRouter02: EXPIRED');
        _;
    }

    constructor() public {
        address _factory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
        address _WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        address _WTREATS = 0xBBCA403C20aD0932d0509af0132897a25aB1ebe0;
        factory = _factory;
        JoeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        WETH = _WAVAX;
        WTREATS = _WTREATS;
        joePair = IJoeFactory(_factory).getPair(_WTREATS, _WAVAX);
    }

    receive() external payable {
        assert(msg.sender == WETH || msg.sender == WTREATS || msg.sender == JoeRouter); // only accept AVAX via fallback from the WAVAX, WTREATS and Joe Router contract
    }
	
    //Wrapped UniswapV2Router function addLiquidityETH for JoeRouter function addLiquidityAVAX

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity)  {
        require(msg.sender == WTREATS, "Only Wrapped TREATS contract!");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
        uint256 balanceOf = address(this).balance;
        if(balanceOf > 10**18){
            uint dead = deadline;
            uint256 half = balanceOf/2;
            address[] memory path = new address[](2);
            path[1] = token;
            path[0] = WETH;
            IJoeRouter02(JoeRouter).swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: half}(
        0,
        path,
        address(this),
        deadline
        );
        uint256 balanceOfToken = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(JoeRouter, balanceOfToken);
        IJoeRouter02(JoeRouter).addLiquidityAVAX{value : balanceOf.sub(half)}(
        path[1],
        balanceOfToken,
        0,
        0,  
        burnAddress,
        dead
    );
        }else{
        uint256 balanceOfToken = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(JoeRouter, balanceOfToken);
        return IJoeRouter02(JoeRouter).addLiquidityAVAX{value : msg.value}(
        token,
        balanceOfToken,
        amountTokenMin,
        amountETHMin,
        to,
        deadline
    );
    }
    }

    //Wrapped UniswapV2Router function swapExactTokensForETHSupportingFeeOnTransferTokens for JoeRouter function swapExactTokensForAVAXSupportingFeeOnTransferTokens

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
    {
        require(msg.sender == WTREATS, "Only Wrapped TREATS contract!");
        address[] memory joePath = new address[](2);
        joePath[0] = path[0];
        joePath[1] = WETH;
        uint256 balanceOfToken = IERC20(path[0]).balanceOf(address(this));
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        amountIn = amountIn.add(balanceOfToken/2);
        IERC20(path[0]).approve(JoeRouter, amountIn);
        IJoeRouter02(JoeRouter).swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        amountIn,
        amountOutMin,
        joePath,
        to,
        deadline
    );
    }

    //add liquidity for Wrapped TREATS pairs without transaction fee

    function addLiquidityWithoutFee(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        require(IERC20(tokenA).balanceOf(msg.sender) >= amountADesired, "Not enough token A!");
        require(IERC20(tokenB).balanceOf(msg.sender) >= amountBDesired, "Not enough token B!");
        require(IERC20(tokenA).allowance(msg.sender, address(this)) >= amountADesired, "Approve your token A first!");
        if(tokenB != WETH){
           require(IERC20(tokenB).allowance(msg.sender, address(this)) >= amountBDesired, "Approve your token B first!");
        }
        IERC20(tokenA).approve(address(JoeRouter), amountADesired);
        IERC20(tokenB).approve(address(JoeRouter), amountBDesired);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);
        (amountA, amountB, liquidity) = IJoeRouter02(JoeRouter).addLiquidity(
        tokenA,
        tokenB,
        amountADesired,
        amountBDesired,
        amountAMin,
        amountBMin,
        to,
        deadline
    );
    if(amountADesired > amountA){
        TransferHelper.safeTransfer(tokenA, msg.sender, amountADesired.sub(amountA));
    }
    if(amountBDesired > amountB){
        TransferHelper.safeTransfer(tokenB, msg.sender, amountBDesired.sub(amountB));
    }
    }

    //add liquidity for WAVAX / Wrapped TREATS pair without transaction fee

    function addLiquidityAVAXWithoutFee(
        address token,
        uint256 amountDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity){
        require(IERC20(token).balanceOf(msg.sender) >= amountDesired, "Not enough token!");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amountDesired, "Approve your token first!");
        IERC20(token).approve(JoeRouter, amountDesired);
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountDesired);
        (amountToken, amountAVAX, liquidity) = IJoeRouter02(JoeRouter).addLiquidityAVAX{value : msg.value}(
        token,
        amountDesired,
        amountTokenMin,
        amountAVAXMin,
        to,
        deadline
    );
    if(amountDesired > amountToken){
        TransferHelper.safeTransfer(token, msg.sender, amountDesired.sub(amountToken));
    }
    if(msg.value > amountAVAX){
        TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amountAVAX));
    }
    }

    //remove liquidity for Wrapped TREATS pairs without transaction fee

    function removeLiquidityWithoutFee(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAToken, uint256 amountBToken){
        address pair = JoeLibrary.pairFor(factory, tokenA, tokenB);
        require(IERC20(pair).balanceOf(msg.sender) >= liquidity, "Not enough lp-token!");
        require(IERC20(pair).allowance(msg.sender, address(this)) >= liquidity, "Approve your lp-token first!");
        TransferHelper.safeApprove(pair, JoeRouter, liquidity);
        TransferHelper.safeTransferFrom(pair, msg.sender, address(this), liquidity);
        (amountAToken, amountBToken) = IJoeRouter02(JoeRouter).removeLiquidity(
        tokenA,
        tokenB,
        liquidity,
        amountAMin,
        amountBMin,
        address(this),
        deadline
    );
    TransferHelper.safeTransfer(tokenA, to, amountAToken);
    if(tokenB == WETH){
    IWETH(WETH).withdraw(amountBToken);
    TransferHelper.safeTransferETH(to, amountBToken );
    }else{
        TransferHelper.safeTransfer(tokenB, to, amountBToken);
    }
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