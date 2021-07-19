//SourceUnit: ISwapspaceFactory.sol

pragma solidity ^0.5.15;

interface ISwapspaceFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB,address owner) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


//SourceUnit: ISwapspacePair.sol

pragma solidity ^0.5.15;

interface ISwapspacePair {
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
    //function _swap(uint amount, address token, address to ) external;
    //function test(address token,address to,uint amount) external ;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


//SourceUnit: ISwapspaceRouter01.sol

pragma solidity ^0.5.15;

interface ISwapspaceRouter01 {
    function factory() external pure returns (address);
    function WTRX() external pure returns (address);

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
    function addLiquidityTRX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountTRX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityTRX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline
    ) external returns (uint amountToken, uint amountTRX);
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
    function removeLiquidityTRXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountTRX);
    function swapExactTokensForTokens(
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
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address payable to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address payable to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


//SourceUnit: ISwapspaceRouter02.sol

pragma solidity ^0.5.15;

interface ISwapspaceRouter02  {
    function removeLiquidityTRXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline
    ) external returns (uint amountTRX);
    function removeLiquidityTRXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountTRX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTRXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTRXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external;
}


//SourceUnit: ITRC20.sol

pragma solidity ^0.5.15;

interface ITRC20 {
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


//SourceUnit: IWTRX.sol

pragma solidity ^0.5.15;

contract IWTRX {
    function deposit() public payable;
    function transfer(address to, uint value) public returns (bool);
    function withdraw(uint) public;
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.15;

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


//SourceUnit: SwapspaceLibrary.sol

pragma solidity ^0.5.15;

import "./ISwapspacePair.sol";

import "./ISwapspaceFactory.sol";

import "./SafeMath.sol";


library SwapspaceLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
    {
        require(tokenA != tokenB, "SwapspaceLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
        ? (tokenA, tokenB)
        : (tokenB, tokenA);
        require(token0 != address(0), "SwapspaceLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        /*pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );*/
        pair = ISwapspaceFactory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        //address token0 = tokenA;
        // address pair = pairFor(factory, tokenA, tokenB);
        //(uint256 reserve0, uint256 reserve1, ) = ISwapspacePair(pair).getReserves();

        (uint256 reserve0, uint256 reserve1, ) = ISwapspacePair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();


        //uint256 reserve0 = 1000;
        //uint256 reserve1 = 1000;

        (reserveA, reserveB) = tokenA == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
        //reserveA = reserve0;
        // reserveB = reserve1;

    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "SwapspaceLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "SwapspaceLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }


    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        //确认输入数额大于0
        require(amountIn > 0, "SwapspaceLibrary: INSUFFICIENT_INPUT_AMOUNT");
        //确认储备量In和储备量Out大于0
        require(
            reserveIn > 0 && reserveOut > 0,
            "SwapspaceLibrary: INSUFFICIENT_LIQUIDITY"
        );
        //税后输入数额 = 输入数额 * 997
        uint256 amountInWithFee = amountIn.mul(997);
        //分子 = 税后输入数额 * 储备量Out
        uint256 numerator = amountInWithFee.mul(reserveOut);
        //分母 = 储备量In * 1000 + 税后输入数额
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        //输出数额 = 分子 / 分母
        amountOut = numerator / denominator;
    }


    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        //确认输出数额大于0
        require(amountOut > 0, "SwapspaceLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        //确认储备量In和储备量Out大于0
        require(
            reserveIn > 0 && reserveOut > 0,
            "SwapspaceLibrary: INSUFFICIENT_LIQUIDITY"
        );
        //分子 = 储备量In * 储备量Out * 1000
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        //分母 = 储备量Out - 输出数额 * 997
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        //输入数额 = (分子 / 分母) + 1
        amountIn = (numerator / denominator).add(1);
    }


    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        //确认路径数组长度大于2
        require(path.length >= 2, "SwapspaceLibrary: INVALID_PATH");
        //初始化数额数组
        amounts = new uint256[](path.length);
        //数额数组[0] = 输入数额
        amounts[0] = amountIn;
        //遍历路径数组,path长度-1
        for (uint256 i; i < path.length - 1; i++) {
            //(储备量In,储备量Out) = 获取储备(当前路径地址,下一个路径地址)
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            //下一个数额 = 获取输出数额(当前数额,储备量In,储备量Out)
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        //确认路径数组长度大于2
        require(path.length >= 2, "SwapspaceLibrary: INVALID_PATH");
        //初始化数额数组
        amounts = new uint256[](path.length);
        //数额数组最后一个元素 = 输出数额
        amounts[amounts.length - 1] = amountOut;
        //从倒数第二个元素倒叙遍历路径数组
        for (uint256 i = path.length - 1; i > 0; i--) {
            //(储备量In,储备量Out) = 获取储备(上一个路径地址,当前路径地址)
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            //上一个数额 = 获取输入数额(当前数额,储备量In,储备量Out)
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


//SourceUnit: TransferHelper.sol

pragma solidity ^0.5.15;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    //address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        /* if (token == USDTAddr) {
             return success;
         }*/
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

}


//SourceUnit: online.sol

pragma solidity ^0.5.15;

import './ISwapspaceFactory.sol';
import './TransferHelper.sol';
import './ISwapspaceRouter01.sol';
import './ISwapspaceRouter02.sol';
import './SwapspaceLibrary.sol';
import './SafeMath.sol';
import './ITRC20.sol';
import './IWTRX.sol';

contract SwapspaceRouter02 is ISwapspaceRouter01,ISwapspaceRouter02 {
    using SafeMath for uint;
    using TransferHelper for address;

    address public factory;
    address public WTRX;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'SwapspaceRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WTRX) public {
        factory = _factory;
        WTRX = _WTRX;
    }

    function() external payable {
        //断言调用者为weth合约地址
        assert(msg.sender == WTRX); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address owner
    ) internal returns (uint amountA, uint amountB)
    {
        // create the pair if it doesn't exist yet
        if (ISwapspaceFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISwapspaceFactory(factory).createPair(tokenA, tokenB,owner);

        }


        (uint reserveA, uint reserveB) = SwapspaceLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0)
        {
            (amountA, amountB) = (amountADesired, amountBDesired);
        }
        else
        {
            uint amountBOptimal = SwapspaceLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SwapspaceRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SwapspaceLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SwapspaceRouter: INSUFFICIENT_A_AMOUNT');
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
    ) external  ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin,msg.sender);
        address pair = SwapspaceLibrary.pairFor(factory, tokenA, tokenB);
        //TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        //TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        //require(address(tokenA).safeTransferFrom(msg.sender, pair, amountA), "transfer failed");
        //require(address(tokenB).safeTransferFrom(msg.sender, pair, amountB), "transfer failed");
        _safeTransferFrom(tokenA,msg.sender,pair,amountA);
        _safeTransferFrom(tokenB,msg.sender,pair,amountB);


        liquidity = ISwapspacePair(pair).mint(to);
    }

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _amount
    ) internal  {
        //TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        //TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        require(address(_token).safeTransferFrom(_from, _to, _amount), "transfer failed");
    }


    /*      function _safeTransfer(
          address _token,
          address _to,
          uint _amount
      ) internal  {
          //TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
          //TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
          require(address(_token).safeTransfer(address(_to), _amount), "transfer failed");
      }*/






    function addLiquidityTRX(
        address _token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountTRX, uint liquidity) {
        (amountToken, amountTRX) = _addLiquidity(
            _token,
            WTRX,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountTRXMin,
            msg.sender
        );
        address pair = SwapspaceLibrary.pairFor(factory, _token, WTRX);
        //TransferHelper.safeTransferFrom(_token, msg.sender, pair, amountToken);
        _safeTransferFrom(_token, msg.sender, pair, amountToken);
        IWTRX(WTRX).deposit.value(amountTRX)();
        assert(IWTRX(WTRX).transfer(pair, amountTRX));
        liquidity = ISwapspacePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountTRX)
        {
            msg.sender.transfer(msg.value - amountTRX);
        }
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = SwapspaceLibrary.pairFor(factory, tokenA, tokenB);
        ISwapspacePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISwapspacePair(pair).burn(to);
        (address token0,) = SwapspaceLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SwapspaceRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SwapspaceRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityTRX(
        address _token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountTRX) {
        (amountToken, amountTRX) = removeLiquidity(
            _token,
            WTRX,
            liquidity,
            amountTokenMin,
            amountTRXMin,
            address(this),
            deadline
        );
        //TransferHelper.safeTransfer(_token, to, amountToken);
        //_safeTransfer(_token, to, amountToken);
        // require(address(_token).safeTransfer(address(to), amountToken));
        //require(ITRC20(_token).transfer(to,amountToken));
        (bool success, ) = _token.call(abi.encodeWithSelector(0xa9059cbb, to, amountToken));
        require(success,"transfer failed");
        IWTRX(WTRX).withdraw(amountTRX);
        to.transfer(amountTRX);
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
    ) external returns (uint amountA, uint amountB) {
        address pair = SwapspaceLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        ISwapspacePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityTRXWithPermit(
        address _token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountTRX) {
        address pair = SwapspaceLibrary.pairFor(factory, _token, WTRX);
        uint value = approveMax ? uint(-1) : liquidity;
        ISwapspacePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountTRX) = removeLiquidityTRX(_token, liquidity, amountTokenMin, amountTRXMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityTRXSupportingFeeOnTransferTokens(
        address _token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline
    ) public ensure(deadline) returns (uint amountTRX) {
        (, amountTRX) = removeLiquidity(
            _token,
            WTRX,
            liquidity,
            amountTokenMin,
            amountTRXMin,
            address(this),
            deadline
        );
        //TransferHelper.safeTransfer(_token, to, ITRC20(token).balanceOf(address(this)));
        //_safeTransfer(_token,to,ITRC20(_token).balanceOf(address(this)));
        //require(address(_token).safeTransfer(address(to), ITRC20(_token).balanceOf(address(this))));
        //ITRC20(_token).transfer(to,ITRC20(_token).balanceOf(address(this)));
        //require(ITRC20(_token).transfer(to,ITRC20(_token).balanceOf(address(this))), "transfer failed");
        (bool success, ) = _token.call(abi.encodeWithSelector(0xa9059cbb, to, ITRC20(_token).balanceOf(address(this))));
        require(success,"transfer failed");
        IWTRX(WTRX).withdraw(amountTRX);
        to.transfer(amountTRX);
    }
    function removeLiquidityTRXWithPermitSupportingFeeOnTransferTokens(
        address _token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address payable to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountTRX) {
        address pair = SwapspaceLibrary.pairFor(factory, _token, WTRX);
        uint value = approveMax ? uint(-1) : liquidity;
        ISwapspacePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountTRX = removeLiquidityTRXSupportingFeeOnTransferTokens(
            _token, liquidity, amountTokenMin, amountTRXMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapspaceLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SwapspaceLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ISwapspacePair(SwapspaceLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external  ensure(deadline) returns (uint[] memory amounts)
    {
        amounts = SwapspaceLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapspaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        /*TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );*/
        _safeTransferFrom(path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external  ensure(deadline) returns (uint[] memory amounts) {
        amounts = SwapspaceLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SwapspaceRouter: EXCESSIVE_INPUT_AMOUNT');
        /*TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );*/
        _safeTransferFrom(path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WTRX, 'SwapspaceRouter: INVALID_PATH');
        amounts = SwapspaceLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapspaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWTRX(WTRX).deposit.value(amounts[0])();
        assert(IWTRX(WTRX).transfer(SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address payable to, uint deadline)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WTRX, 'SwapspaceRouter: INVALID_PATH');
        amounts = SwapspaceLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SwapspaceRouter: EXCESSIVE_INPUT_AMOUNT');
        /*TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );*/
        _safeTransferFrom(path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWTRX(WTRX).withdraw(amounts[amounts.length - 1]);
        to.transfer(amounts[amounts.length - 1]);
    }
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address payable to, uint deadline)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WTRX, 'SwapspaceRouter: INVALID_PATH');
        amounts = SwapspaceLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapspaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        /*TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );*/
        _safeTransferFrom(path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWTRX(WTRX).withdraw(amounts[amounts.length - 1]);
        to.transfer(amounts[amounts.length - 1]);
    }
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WTRX, 'SwapspaceRouter: INVALID_PATH');
        amounts = SwapspaceLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'SwapspaceRouter: EXCESSIVE_INPUT_AMOUNT');
        IWTRX(WTRX).deposit.value(amounts[0])();
        assert(IWTRX(WTRX).transfer(SwapspaceLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) msg.sender.transfer(msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapspaceLibrary.sortTokens(input, output);
            ISwapspacePair pair = ISwapspacePair(SwapspaceLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = ITRC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = SwapspaceLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SwapspaceLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) {
        /* TransferHelper.safeTransferFrom(
             path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amountIn
         );*/

        _safeTransferFrom(path[0],msg.sender,SwapspaceLibrary.pairFor(factory, path[0], path[1]),amountIn);
        uint balanceBefore = ITRC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ITRC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SwapspaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTRXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    payable
    ensure(deadline)
    {
        require(path[0] == WTRX, 'SwapspaceRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWTRX(WTRX).deposit.value(amountIn)();
        assert(IWTRX(WTRX).transfer(SwapspaceLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = ITRC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ITRC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SwapspaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForTRXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address payable to,
        uint deadline
    )
    external
    ensure(deadline)
    {
        require(path[path.length - 1] == WTRX, 'SwapspaceRouter: INVALID_PATH');
        /*TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapspaceLibrary.pairFor(factory, path[0], path[1]), amountIn
        );*/

        _safeTransferFrom(path[0],msg.sender,SwapspaceLibrary.pairFor(factory, path[0], path[1]),amountIn);
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = ITRC20(WTRX).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'SwapspaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWTRX(WTRX).withdraw(amountOut);
        to.transfer(amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {
        return SwapspaceLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    public
    pure
    returns (uint amountOut)
    {
        return SwapspaceLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    public
    pure
    returns (uint amountIn)
    {
        return SwapspaceLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    returns (uint[] memory amounts)
    {
        return SwapspaceLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    returns (uint[] memory amounts)
    {
        return SwapspaceLibrary.getAmountsIn(factory, amountOut, path);
    }

/*
    function getAllReserves(address[] memory path)
    public
    view
    returns (uint[] memory amounts)
    {
        require(path.length >= 2, "SwapspaceLibrary: INVALID_PATH");
        //初始化数额数组
        amounts = new uint256[](path.length);

        //遍历路径数组,path长度-1
        for (uint256 i; i < path.length; i=i+2)
        {
            //(储备量In,储备量Out) = 获取储备(当前路径地址,下一个路径地址)
            (uint256 reserve0, uint256 reserve1) = SwapspaceLibrary.getReserves(
                factory,
                path[i],
                path[i + 1]
            );
                amounts[i] = reserve0;
                amounts[i + 1] = reserve1;
        }
    }
*/

    function getAllReserves(address[] memory path)
    public
    view
    returns (uint[] memory amounts)
    {
        uint j = 0;

        require(path.length >= 2, "SwapspaceLibrary: INVALID_PATH");
        //初始化数额数组
        amounts = new uint256[](path.length *3 /2);

        //遍历路径数组,path长度-1
        for (uint256 i; i < path.length; i=i+2)
        {
            //(储备量In,储备量Out) = 获取储备(当前路径地址,下一个路径地址)
            (uint256 reserve0, uint256 reserve1) = SwapspaceLibrary.getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[j] = reserve0;
            amounts[j + 1] = reserve1;
            amounts[j + 2] = getLPSupply(path[i],path[i+1]);
            j= j+3;
        }
    }



    function getLPBalance(
        address tokenA,
        address tokenB,
        address to
    ) external view  returns (uint LPAmount)
    {
        require(tokenA != tokenB, "SwapspaceLibrary: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
        ? (tokenA, tokenB)
        : (tokenB, tokenA);
        require(token0 != address(0), "SwapspaceLibrary: ZERO_ADDRESS");

        address pair = ISwapspaceFactory(factory).getPair(token0, token1);

        LPAmount = ISwapspacePair(pair).balanceOf(to);
    }


    function getLPSupply(
        address tokenA,
        address tokenB
    ) public view  returns (uint LPAmount)
    {
        require(tokenA != tokenB, "SwapspaceLibrary: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
        ? (tokenA, tokenB)
        : (tokenB, tokenA);
        require(token0 != address(0), "SwapspaceLibrary: ZERO_ADDRESS");

        address pair = ISwapspaceFactory(factory).getPair(token0, token1);

        LPAmount = ISwapspacePair(pair).totalSupply();
    }

    /*   function getAllLPSupply(address[] memory path)
   public
   view
   returns (uint[] memory amounts)
   {
       require(path.length >= 2, "SwapspaceLibrary: INVALID_PATH");
       //初始化数额数组
       amounts = new uint256[](path.length);

       //遍历路径数组,path长度-1
       for (uint256 i; i < path.length; i=i+2)
       {
           //(储备量In,储备量Out) = 获取储备(当前路径地址,下一个路径地址
           if(i ==0)
           {
               amounts[i] = getLPSupply();
           }
           else
           {
               amounts[i/2] = reserve0;
           }
       }
   }*/




}