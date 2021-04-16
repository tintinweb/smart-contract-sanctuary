/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IUniswapV2Pair {
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
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface ISwapper {
    function swap(
        address fromAssetHash,
        uint64 toPoolId,
        uint64 toChainId,
        bytes calldata toAssetHash,
        bytes calldata toAddress,
        uint amount,
        uint minOutAmount,
        uint fee,
        uint id
    ) external payable returns (bool);
}

library Convert {
    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }
}

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

    function div(uint x, uint y) internal pure returns (uint z) {
        return x / y;
    }
}

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

contract O3SwapETHUniswapBridge is Ownable {
    using SafeMath for uint256;
    using Convert for bytes;

    event LOG_AGG_SWAP (
        uint256 amountOut, // Raw swapped token amount out without aggFee
        uint256 fee
    );

    address public WETH;
    address public uniswapFactory;
    address public polySwapper;
    uint public polySwapperId;

    uint256 public aggregatorFee = 3 * 10 ** 7; // Default to 0.3%
    uint256 public constant FEE_DENOMINATOR = 10 ** 10;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'O3SwapETHUniswapBridge: EXPIRED');
        _;
    }

    constructor (
        address _weth,
        address _factory,
        address _swapper,
        uint _swapperId
    ) public {
        WETH = _weth;
        uniswapFactory = _factory;
        polySwapper = _swapper;
        polySwapperId = _swapperId;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        uint amountOut = _swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, swapAmountOutMin, path);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);

        emit LOG_AGG_SWAP(amountOut, feeAmount);

        uint adjustedAmountOut = amountOut.sub(feeAmount);
        TransferHelper.safeTransfer(path[path.length - 1], to, adjustedAmountOut);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokensCrossChain(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path,
        bytes memory to,
        uint deadline,
        uint64 toPoolId,
        uint64 toChainId,
        bytes memory toAssetHash,
        uint polyMinOutAmount,
        uint fee
    ) external virtual payable ensure(deadline) returns (bool) {
        uint polyAmountIn;
        {
            uint amountOut = _swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, swapAmountOutMin, path);
            uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
            emit LOG_AGG_SWAP(amountOut, feeAmount);
            polyAmountIn = amountOut.sub(feeAmount);
        }

        return _cross(
            path[path.length - 1],
            toPoolId,
            toChainId,
            toAssetHash,
            to,
            polyAmountIn,
            polyMinOutAmount,
            fee
        );
    }

    function _swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path
    ) internal virtual returns (uint) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(uniswapFactory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(amountOut >= amountOutMin, 'O3SwapETHUniswapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        return amountOut;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint swapAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) {
        uint amountOut = _swapExactETHForTokensSupportingFeeOnTransferTokens(swapAmountOutMin, path, 0);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);

        emit LOG_AGG_SWAP(amountOut, feeAmount);

        uint adjustedAmountOut = amountOut.sub(feeAmount);
        TransferHelper.safeTransfer(path[path.length - 1], to, adjustedAmountOut);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokensCrossChain(
        uint swapAmountOutMin,
        address[] calldata path,
        bytes memory to,
        uint deadline,
        uint64 toPoolId,
        uint64 toChainId,
        bytes memory toAssetHash,
        uint polyMinOutAmount,
        uint fee
    ) external virtual payable ensure(deadline) returns (bool) {
        uint polyAmountIn;
        {
            uint amountOut = _swapExactETHForTokensSupportingFeeOnTransferTokens(swapAmountOutMin, path, fee);
            uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
            emit LOG_AGG_SWAP(amountOut, feeAmount);
            polyAmountIn = amountOut.sub(feeAmount);
        }

        return _cross(
            path[path.length - 1],
            toPoolId,
            toChainId,
            toAssetHash,
            to,
            polyAmountIn,
            polyMinOutAmount,
            fee
        );
    }

    function _swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint swapAmountOutMin,
        address[] calldata path,
        uint fee
    ) internal virtual returns (uint) {
        require(path[0] == WETH, 'O3SwapETHUniswapBridge: INVALID_PATH');
        uint amountIn = msg.value.sub(fee);
        require(amountIn > 0, 'O3SwapETHUniswapBridge: INSUFFICIENT_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(uniswapFactory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(amountOut >= swapAmountOutMin, 'O3SwapETHUniswapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        return amountOut;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        uint amountOut = _swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, swapAmountOutMin, path);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);

        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IWETH(WETH).withdraw(amountOut);
        uint adjustedAmountOut = amountOut.sub(feeAmount);
        TransferHelper.safeTransferETH(to, adjustedAmountOut);
    }

    function _swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path
    ) internal virtual returns (uint) {
        require(path[path.length - 1] == WETH, 'O3SwapETHUniswapBridge: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(uniswapFactory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(WETH).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this)).sub(balanceBefore);
        require(amountOut >= swapAmountOutMin, 'O3SwapETHUniswapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        return amountOut;
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(uniswapFactory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _cross(
        address fromAssetHash,
        uint64 toPoolId,
        uint64 toChainId,
        bytes memory toAssetHash,
        bytes memory toAddress,
        uint amount,
        uint minOutAmount,
        uint fee
    ) internal returns (bool) {
        // Allow `swapper contract` to transfer `amount` of `fromAssetHash` on belaof of this contract.
        TransferHelper.safeApprove(fromAssetHash, polySwapper, amount);

        bool result = ISwapper(polySwapper).swap{value: fee}(
            fromAssetHash,
            toPoolId,
            toChainId,
            toAssetHash,
            toAddress,
            amount,
            minOutAmount,
            fee,
            polySwapperId
        );
        require(result, "POLY CROSSCHAIN ERROR");

        return result;
    }

    receive() external payable { }

    function setPolySwapperId(uint _id) external onlyOwner {
        polySwapperId = _id;
    }

    function collect(address token) external onlyOwner {
        if (token == WETH) {
            uint256 wethBalance = IERC20(token).balanceOf(address(this));
            if (wethBalance > 0) {
                IWETH(WETH).withdraw(wethBalance);
            }
            TransferHelper.safeTransferETH(owner(), address(this).balance);
        } else {
            TransferHelper.safeTransfer(token, owner(), IERC20(token).balanceOf(address(this)));
        }
    }

    function setAggregatorFee(uint _fee) external onlyOwner {
        aggregatorFee = _fee;
    }

    function setUniswapFactory(address _factory) external onlyOwner {
        uniswapFactory = _factory;
    }

    function setPolySwapper(address _swapper) external onlyOwner {
        polySwapper = _swapper;
    }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }
}