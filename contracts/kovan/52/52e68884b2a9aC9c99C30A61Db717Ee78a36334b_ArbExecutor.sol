pragma solidity >=0.4.22 <0.8.0;
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

interface Uniswap_Factory_Interface {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
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

interface WETH_Interface {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
     function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
}

interface Uniswap_Router_Interface {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadlin
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function WETH() external returns (address);
}

interface ERC20_Interface {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract ArbExecutor {

    //ADDRESSES
    address public Uniswap_Router_Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public Uniswap_Factory_Address = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public WETH_Address = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;


    //INTERFACES
    Uniswap_Router_Interface Uniswap_Router;
    Uniswap_Factory_Interface Uniswap_Factory;
    WETH_Interface IWETH;

    //SECURITY
    //SETUP OWNER ADDRESS VARIABLE
    address payable public owner;
    mapping(address => bool) public operatorsMap;
    address[] public operators;

    event Received(address, uint256);
    event FinalEthOut(uint256);
    event SwapDebugger(address, uint256);

    struct Operation {
        address[] tokens;
        uint256[] minOuts;
    }

    constructor() payable {
        owner = msg.sender; //Setup owner value
        Uniswap_Router = Uniswap_Router_Interface(Uniswap_Router_Address);
        Uniswap_Factory = Uniswap_Factory_Interface(Uniswap_Factory_Address);
        IWETH = WETH_Interface(WETH_Address);
        operatorsMap[msg.sender] = true;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    

    function swapEthForToken(uint256 amountIn, address token, uint256 amountOutMin) public payable{
        address[] memory path = new address[](2);

        path[0] = WETH_Address;
        path[1] = token;

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(Uniswap_Factory_Address, amountIn, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'BSCBB: INSUFFICIENT_OUTPUT_AMOUNT');

        IWETH.deposit{value: amounts[0]}();
        assert(IWETH.transfer(UniswapV2Library.pairFor(Uniswap_Factory_Address, path[0], path[1]), amounts[0]));

        (address input, address output) = (path[0], path[1]);
        (address token0,) = UniswapV2Library.sortTokens(input, output);
        uint amountOut = amounts[1];
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        IUniswapV2Pair(UniswapV2Library.pairFor(Uniswap_Factory_Address, input, output)).swap(
                amount0Out, amount1Out, address(this), new bytes(0)
        );
    }

    function swapTokenForToken(uint256 amountIn, address tokenIn, address tokenOut, uint256 amountOutMin) public payable {
        address[] memory path = new address[](2);

        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(Uniswap_Factory_Address, amountIn, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'BSCBB: INSUFFICIENT_OUTPUT_AMOUNT');

        assert(ERC20_Interface(tokenIn).transfer(UniswapV2Library.pairFor(Uniswap_Factory_Address, path[0], path[1]), amounts[0]));

        (address input, address output) = (path[0], path[1]);
        (address token0,) = UniswapV2Library.sortTokens(input, output);
        uint amountOut = amounts[1];
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        IUniswapV2Pair(UniswapV2Library.pairFor(Uniswap_Factory_Address, input, output)).swap(
                amount0Out, amount1Out, address(this), new bytes(0)
        );
    }

    function swapTokenForEth(uint256 amountIn, address token, uint256 amountOutMin) public payable {
        address[] memory path = new address[](2);

        path[0] = token;
        path[1] = WETH_Address;

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(Uniswap_Factory_Address, amountIn, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'BSCBB: INSUFFICIENT_OUTPUT_AMOUNT');

        assert(ERC20_Interface(token).transfer(UniswapV2Library.pairFor(Uniswap_Factory_Address, path[0], path[1]), amounts[0]));

        (address input, address output) = (path[0], path[1]);
        (address token0,) = UniswapV2Library.sortTokens(input, output);
        uint amountOut = amounts[1];
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        IUniswapV2Pair(UniswapV2Library.pairFor(Uniswap_Factory_Address, input, output)).swap(
                amount0Out, amount1Out, address(this), new bytes(0)
        );

        IWETH.withdraw(amounts[amounts.length - 1]);
    }

    function swap(uint256 amountIn, address tokenIn, address tokenOut, uint256 amountOutMin) public payable {

        if(tokenIn == WETH_Address) {
            swapEthForToken(amountIn, tokenOut, amountOutMin);
        } else if(tokenOut == WETH_Address) {
            swapTokenForEth(amountIn, tokenIn, amountOutMin);
        } else {
            swapTokenForToken(amountIn, tokenIn, tokenOut, amountOutMin);
        }
    }
    

    /*

    function ST3(
        address[] memory _operationPath,
        uint256[] memory _minOuts,
        uint256 amountIn
    ) public {
        uint256 out1 =
            Uniswap_EthToToken(_operationPath[1], amountIn, _minOuts[0]);
        uint256 tempOut = out1;

        for (uint256 i = 1; i < (_operationPath.length - 2); i++) {
            uint256 newOut =
                Uniswap_TokenToToken(
                    _operationPath[i],
                    _operationPath[i + 1],
                    tempOut,
                    _minOuts[i]
                );
            tempOut = newOut;
        }

        uint256 finalOut =
            Uniswap_TokenToEth(
                _operationPath[_operationPath.length - 2],
                tempOut,
                _minOuts[_minOuts.length - 1]
            );
        emit FinalEthOut(finalOut);
    }

    */

    /*

    function ST4(Operation memory _operation, uint256 amountIn) public onlyOps {
        uint256 out1 =
            Uniswap_EthToToken(
                _operation.tokens[1],
                amountIn,
                _operation.minOuts[0]
            );
        uint256 tempOut = out1;

        for (uint256 i = 1; i < (_operation.tokens.length - 2); i++) {
            uint256 newOut =
                Uniswap_TokenToToken(
                    _operation.tokens[i],
                    _operation.tokens[i + 1],
                    tempOut,
                    _operation.minOuts[i]
                );
            tempOut = newOut;
        }

        uint256 finalOut =
            Uniswap_TokenToEth(
                _operation.tokens[_operation.tokens.length - 2],
                tempOut,
                _operation.minOuts[_operation.minOuts.length - 1]
            );
        emit FinalEthOut(finalOut);
    }

    */

    /*

    function ST1OP1(address token, uint256 amountIn) public {
        uint256 startGas = gasleft();

        uint256 out1 = Uniswap_EthToToken(token, amountIn, 1);
        uint256 out2 = Uniswap_TokenToEth(token, out1, 1);

        //require(out2 > amountIn, "Arbitrage operation was no longer available!");

        uint256 gasUsed = startGas - gasleft();
    }
    */

    /*

    //UNISWAP: ETH -> TOKEN
    function Uniswap_EthToToken(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) public payable onlyOps returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600; //10 Minutes

        path[0] = Uniswap_Router.WETH();
        path[1] = token;

        uint256[] memory amounts =
            Uniswap_Router.swapExactETHForTokens{value: amountIn}(
                amountOutMin, //MINIMUM TOKENS
                path,
                address(this),
                deadline
            );

        return amounts[amounts.length - 1];
    }

    //UNISWAP: TOKEN -> ETH
    function Uniswap_TokenToEth(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) public payable onlyOps returns (uint256 amountOut) {
        require(
            IERC20_Interface(token).approve(
                address(Uniswap_Router),
                (amountIn + 100000)
            ),
            "Smart contract approval failed"
        );
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600;

        path[0] = token;
        path[1] = WETH_Address;

        uint256[] memory amounts =
            Uniswap_Router.swapExactTokensForETH(
                amountIn,
                amountOutMin, //MIN FIXED TO 1 FOR TESTING
                path,
                address(this),
                deadline
            );

        return amounts[amounts.length - 1];
    }

    function Uniswap_TokenToToken(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) public payable onlyOps returns (uint256 amountOut) {
        require(
            IERC20_Interface(tokenIn).approve(
                address(Uniswap_Router),
                (amountIn + 100000)
            ),
            "Smart contract approval failed"
        );
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600;

        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts =
            Uniswap_Router.swapExactTokensForTokens(
                amountIn,
                amountOutMin, //MIN FIXED TO 1 FOR TESTING
                path,
                address(this),
                deadline
            );

        return amounts[amounts.length - 1];
    }

    */

    //SECURITY

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOps {
        require(operatorsMap[msg.sender] == true);
        _;
    }

    function addOperator(address operatorAddress) public onlyOwner {
        operatorsMap[operatorAddress] = true;
        operators.push(operatorAddress);
    }

    function removeOperator(address operatorAddress) public onlyOwner {
        operatorsMap[operatorAddress] = false;
    }

    function resetOperators() public onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            operatorsMap[operators[i]] = false;
        }
        delete operators;
    }

    function drain() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function byebye() public onlyOwner {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
        selfdestruct(msg.sender);
    }
}