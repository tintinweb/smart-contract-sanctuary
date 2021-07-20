/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/

pragma solidity =0.6.6;

interface IUniswapV2Factory {
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



interface IAcyV1Arbitrage {
    //function addTokenPair(address tokenA, address tokenB) external returns (address);
    function getIndirectToken(address inputToken, address outputToken) external view returns ( address );
    function calculOutputAmount(uint112 inputAmount, address inputToken, address outputToken) external view returns ( uint112 outputTokenAmount);
    function getOutputAmountAPI(uint112 inputAmount, address tokenAddress,address pairAddress) external view returns (uint112);
    function getPairForAPI(address tokenA, address tokenB) external view returns (address);
    function initToken(address _tokenAA,address _tokenBB,address _tokenCC) external;
}


contract AcyV1Arbitrage is IAcyV1Arbitrage{
    using SafeMath for uint;
    
    address public factory;
    
    // official version
    //mapping(address => address[]) public tokenPairs;
    // beta version
    mapping(address => mapping(address => address)) indirectTokens;
    
    
    address tokenAA;
    address tokenBB;
    address tokenCC;
    
    
    constructor() public {
        factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        tokenAA = 0x5F59f7fdAa5816f366477888ABC404A51E6a89fb;
        tokenBB = 0xaCDbbAD9921653B076a7dDe2e1375bCD3D262894;
        tokenCC = 0xED8524117020869b4BA1b699Cf3b032e39bBBe92;
        indirectTokens[tokenAA][tokenBB] = tokenCC;
        indirectTokens[tokenBB][tokenCC] = tokenAA;
        indirectTokens[tokenBB][tokenAA] = tokenCC;
        indirectTokens[tokenCC][tokenAA] = tokenBB;
        indirectTokens[tokenCC][tokenBB] = tokenAA;
    }
    
    function initToken(address _tokenAA,address _tokenBB,address _tokenCC)  override external {
        tokenAA = _tokenAA;
        tokenBB = _tokenBB;
        tokenCC = _tokenCC;
        indirectTokens[tokenAA][tokenBB] = tokenCC;
        // indirectTokens[tokenAA][tokenCC] = tokenBB;
        indirectTokens[tokenBB][tokenCC] = tokenAA;
        indirectTokens[tokenBB][tokenAA] = tokenCC;
        indirectTokens[tokenCC][tokenAA] = tokenBB;
        indirectTokens[tokenCC][tokenBB] = tokenAA;
    }
    
    event PrintError(bool success, address data, address factory, address fromtoken, address token, address pair_address, uint amount);
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
        
    }
    
    // token2token swap
    function swap(uint amountIn,address inputToken,address outputToken) payable external {
        address[] memory arr = new address[](2);
        arr[0] = inputToken;
        arr[1] = outputToken;
        //uint deadline = block.timestamp + 300;
        //uint amountOutMin = (uint(this.getOutputAmountAPI(uint112(amountIn), inputToken, outputToken))/100)*50;
        // require(amountOutMin > 0 ,"amountIn error");
        // bool approveFlag = IBEP20(inputToken).approve(msg.sender, amountIn);
        // require(approveFlag,"approve token error");
        // require(IBEP20(inputToken).allowance(msg.sender, address(this))>=amountIn,"allowance error");
        
        //IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn,amountOutMin, arr, msg.sender, deadline);
        
        // router.delegatecall(
        //     abi.encodeWithSignature("swapExactTokensForTokensSupportingFeeOnTransferTokens(uint,uint,address[] calldata,address,uint)",
        //     amountIn,amountOutMin, arr, msg.sender, deadline)
        // );
        address pair_address = UniswapV2Library.pairFor(factory, arr[0], arr[1]);
        (bool success, bytes memory data) = inputToken.call(abi.encodeWithSelector(0x23b872dd, msg.sender, pair_address, amountIn));
        emit PrintError(success, msg.sender, factory, arr[0], arr[1], pair_address, amountIn);
        
        // IERC20(inputToken).approve(address(router), amountIn);
        // this.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     amountIn,
        //     uint256(0), // accept any amount of pair token
        //     arr,
        //     address(this),
        //     now.add(1800)
        // );
    }
    
    
    function returnSwap() external view returns(address) {
        return msg.sender;
    }
    
    function getIndirectToken(address inputToken, address outputToken) override external view returns ( address indirectToken ){
        indirectToken = indirectTokens[inputToken][outputToken];
    }
    
    // 仅适用于三角套利数量计算
    function calculOutputAmount(uint112 inputAmount, address inputToken, address outputToken) override external view returns ( uint112 outputTokenAmount){
        outputTokenAmount = this.getOutputAmountAPI(
                this.getOutputAmountAPI(
                    inputAmount,
                    inputToken,
                    this.getIndirectToken(inputToken,outputToken)),
            this.getIndirectToken(inputToken,outputToken),
            outputToken);
    }


    function getOutputAmountAPI(uint112 inputAmount, address inputTokenAddress,address outputTokenAddress) override external view returns (uint112 amountOut){
        address pairAddress = this.getPairForAPI(inputTokenAddress,outputTokenAddress);
        require(pairAddress != address(0),"pairAddress error");
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        require(inputTokenAddress == IUniswapV2Pair(pairAddress).token0() || inputTokenAddress == IUniswapV2Pair(pairAddress).token1(),"token error");
        
        if(inputTokenAddress == IUniswapV2Pair(pairAddress).token1()){
            uint112 tmp = reserve1;
            reserve1 = reserve0;
            reserve0 = tmp;
        } 
        require(inputAmount < reserve0 ,"inputAmount error");
        return uint112(UniswapV2Library.getAmountOut(uint(inputAmount), uint(reserve0), uint(reserve1)));
    }
    
    function getPairForAPI(address tokenA, address tokenB) override external view returns (address){
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external{
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
        // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
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