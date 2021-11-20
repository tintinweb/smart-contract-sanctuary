// SPDX-License-Identifier: GPLv3-or-later



// File contracts/avax/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/avax/interfaces/IHcSwapAvaxFactory.sol

pragma solidity >=0.5.0;

interface IHcSwapAvaxFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function owner() external view returns (address);
    function setOwner(address _owner) external;
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function createAToken(string calldata name,string calldata symbol,uint8 decimals,address originAddress_) external returns(address token);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/avax/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/public/libraries/LPQueue.sol

pragma solidity =0.6.6;

library LPQueue {
    struct LPAction {
        bool addLP;
        address to;
        bytes32 checksum;
        bytes payload;
    }

    struct Store {
        mapping(uint256 => LPAction) queue;
        uint256 first;
        uint256 last;
        bool init;
    }

    function initStorage(Store storage s) internal {
        s.first = 1;
        s.last = 0;
        s.init = true;
    }

    function currentIndex(Store storage s) internal view returns (uint256) {
        require(s.init == true);
        require(s.last >= s.first, "Queue is Empty");
        return s.first;
    }

    function enqueue(Store storage s, LPAction memory data)
    internal
    returns (LPAction memory)
    {
        require(s.init == true);
        s.last += 1;
        s.queue[s.last] = data;

        return data;
    }

    function encodeAddLP(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal pure returns(LPQueue.LPAction memory) {
        bytes memory payload = abi.encode(tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin,to,deadline);
        bytes32 checksum = keccak256(abi.encode(true, to, payload));
        return LPAction(true,to,checksum,payload);
    }

    //tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin,to,deadline
    function decodeAddLP(bytes memory payload) internal pure returns(address,address,uint,uint,uint,uint,address,uint){
        return abi.decode(payload,(address,address,uint,uint,uint,uint,address,uint));
    }

    function encodeRemoveLP(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal pure returns(LPQueue.LPAction memory) {
        bytes memory payload = abi.encode(tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline);
        bytes32 checksum = keccak256(abi.encode(false, to, payload));
        return LPAction(false,to,checksum,payload);
    }

    //tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline
    function decodeRemoveLP(bytes memory payload) internal pure returns(address,address,uint,uint,uint,address,uint){
        return abi.decode(payload,(address,address,uint,uint,uint,address,uint));
    }

    function checkData(LPQueue.LPAction memory action) internal pure returns(bool){
        return action.checksum == keccak256(abi.encode(action.addLP, action.to, action.payload));
    }

    function readFirst(Store storage s)
    internal
    view
    returns (LPAction storage data)
    {
        data = s.queue[currentIndex(s)];
    }

    function readFirstPayload(Store storage s) internal view returns(bytes memory payload){
        return s.queue[currentIndex(s)].payload;
    }

    function dequeue(Store storage s) internal {
        require(s.init == true);
        require(s.last >= s.first, "Queue is Empty");
        delete s.queue[s.first];
        s.first += 1;
    }
}


// File contracts/avax/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}


// File contracts/avax/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {

}


// File contracts/avax/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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


// File contracts/avax/interfaces/IHcSwapAvaxPair.sol

pragma solidity >=0.6.2;

interface IHcSwapAvaxPair is IUniswapV2Pair {
    function setCrossPair(bool status_) external;
    function crossPair() external view returns (bool);
    function burnQuery(uint liquidity) external view returns (uint amount0, uint amount1);
}


// File contracts/avax/libraries/SafeMath.sol

pragma solidity >=0.5.16;

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


// File contracts/avax/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getReservesWithCross(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB, bool cross) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair = pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        cross = IHcSwapAvaxPair(pair).crossPair();
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
        uint amountInWithFee = amountIn.mul(995);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(995);
        amountIn = (numerator / denominator).add(1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutNoCross(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInNoCross(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
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
            (uint reserveIn, uint reserveOut, bool cross) = getReservesWithCross(factory, path[i], path[i + 1]);
            amounts[i + 1] = cross?getAmountOut(amounts[i], reserveIn, reserveOut):getAmountOutNoCross(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, bool cross) = getReservesWithCross(factory, path[i - 1], path[i]);
            amounts[i - 1] = cross?getAmountIn(amounts[i], reserveIn, reserveOut):getAmountInNoCross(amounts[i], reserveIn, reserveOut);
        }
    }
}


// File contracts/avax/interfaces/IERC20.sol

pragma solidity >=0.5.0;

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


// File contracts/avax/interfaces/IHcToken.sol

pragma solidity >=0.5.0;

interface IHcToken is IERC20 {
    function originAddress() external view returns(address);
    function superMint(address to_,uint256 amount_) external;
    function transferOwnership(address newOwner) external;
    function burn(uint256 amount_) external;
}


// File contracts/avax/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/avax/interfaces/IHcTokenFactory.sol

pragma solidity >=0.5.0;

interface IHcTokenFactory {
    function transferOwnership(address newOwner) external;

    function createAToken(string calldata name_,string calldata symbol_,uint8 decimals,address originAddress_) external returns(address token);
}


// File contracts/public/contract/Pausable.sol

pragma solidity =0.6.6;

abstract contract Pausable {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


// File contracts/avax/HcSwapAvaxRouter.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;














contract HcSwapAvaxRouter is IUniswapV2Router02, Pausable {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable tokenFactory;

    address public owner;
    mapping(address => bool) public operator;
    mapping(address => address) public BSCToAvax;
    mapping(address => bool) public crossToken;

    uint256 public tasksIndex;
    enum CrossActionStatus{FAIL, SUCCESS, CROSS_EXPIRED, INSUFFICIENT_A_AMOUNT, INSUFFICIENT_B_AMOUNT, NO_PAIR}

    struct TokenInfo {
        address originAddress;// address from BSC
        string name;
        string symbol;
        uint8 decimal;
        uint256 amount;//init amount
        address specialAddress;// use custom token address
    }

    struct CrossAction {
        uint8 actionType; // 0 sync amount 1 mint lp 2 burn lp
        bytes32 checksum;//important!
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;// when type is sync, this field will be zero.
    }

    //status 0 = fail 1 = success >1=fail with message
    event CrossActionDone(uint256 indexed id, CrossActionStatus status, CrossAction result);
    event CrossLiquidityCreated(address indexed pair, uint liquidity, TokenInfo tokenA, TokenInfo tokenB);

    modifier onlyOwner(){
        require(msg.sender == owner, "HcSwapV2Router: ONLY_OWNER");
        _;
    }

    modifier onlyOperator(){
        require(isOperator(), "HcSwapV2Router:ONLY_OPERATOR");
        _;
    }

    function isOperator() public view returns (bool){
        return operator[msg.sender] || msg.sender == owner;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'HcSwapV2Router: EXPIRED');
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setFactoryOwner(address _owner) onlyOwner public {
        if (IHcSwapAvaxFactory(factory).owner() == address(this)) {
            IHcSwapAvaxFactory(factory).setOwner(_owner);
        }
    }

    function setPause(bool _status) onlyOwner public {
        if (_status && !paused()) {
            _pause();
        }

        if (!_status && paused()) {
            _unpause();
        }
    }

    function setCrossToken(address[] memory _token, bool[] memory _status) onlyOwner public {
        require(_token.length == _status.length, "HcSwapV2Router:SET_CROSS_TOKEN_WRONG_DATA");
        for (uint i = 0; i < _token.length; i++) {
            crossToken[_token[i]] = _status[i];
        }
    }

    function setBscToAvax(address[] memory _tokenBsc, address[] memory _tokenAvax) onlyOwner public {
        require(_tokenBsc.length == _tokenAvax.length, "HcSwapAvaxRouter: SET_BSC_AVAX_WRONG_DATA");
        for (uint i = 0; i < _tokenBsc.length; i++) {
            BSCToAvax[_tokenBsc[i]] = _tokenAvax[i];
        }
    }

    function setOperator(address[] memory _ops, bool[] memory _status) onlyOwner public {
        require(_ops.length == _status.length, "HcSwapV2Router:SET_OPERATOR_WRONG_DATA");
        for (uint i = 0; i < _ops.length; i++) {
            operator[_ops[i]] = _status[i];
        }
    }

    constructor(address _factory, address _WETH, address _tokenFactory) public {
        factory = _factory;
        WETH = _WETH;
        tokenFactory = _tokenFactory;
        owner = msg.sender;
        tasksIndex = 1;
    }

    receive() external payable {
        require(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    // **** CROSS ACTION ****
    function initBSCToken(TokenInfo memory token) internal returns (address tokenAddress){
        tokenAddress = BSCToAvax[token.originAddress] == address(0) ? token.specialAddress : BSCToAvax[token.originAddress];
        if (tokenAddress != address(0)) {
            if (crossToken[tokenAddress]) {
                IHcToken(tokenAddress).superMint(address(this), token.amount);
            } else {
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), token.amount);
            }
        } else {
            tokenAddress = IHcTokenFactory(tokenFactory).createAToken(token.name, token.symbol, token.decimal, token.originAddress);
            crossToken[tokenAddress] = true;
            IHcToken(tokenAddress).superMint(address(this), token.amount);
            IHcToken(tokenAddress).transferOwnership(owner);
        }
        BSCToAvax[token.originAddress] = tokenAddress;
    }

    function CreateBSCCrossLiquidity(TokenInfo memory tokenA, TokenInfo memory tokenB) onlyOperator public {
        address tokenAAddress = initBSCToken(tokenA);
        address tokenBAddress = initBSCToken(tokenB);

        require(IUniswapV2Factory(factory).getPair(tokenAAddress, tokenBAddress) == address(0));
        IUniswapV2Factory(factory).createPair(tokenAAddress, tokenBAddress);
        address pair = UniswapV2Library.pairFor(factory, tokenAAddress, tokenBAddress);
        IHcSwapAvaxPair(pair).setCrossPair(true);

        TransferHelper.safeTransfer(tokenAAddress, pair, tokenA.amount);
        TransferHelper.safeTransfer(tokenBAddress, pair, tokenB.amount);
        uint liquidity = IUniswapV2Pair(pair).mint(msg.sender);
        emit CrossLiquidityCreated(pair, liquidity, tokenA, tokenB);
    }

    function onCrossTask(LPQueue.LPAction[] memory actions, uint256[] memory ids) onlyOperator public {
        require(actions.length == ids.length, 'HcSwapV2RouterAvax:WRONG_DATA');

        for (uint i = 0; i < actions.length; i++) {
            uint current = ids[i];
            require(current == tasksIndex, 'HcSwapV2RouterAvax:WRONG_INDEX');
            LPQueue.LPAction memory action = actions[i];
            require(LPQueue.checkData(action), "HcSwapV2RouterAvax:WRONG_CHECKSUM");

            if (action.addLP) {
                (address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity, CrossActionStatus success) = onAddLPCrossTask(action);
                onEmitCrossAction(current, action.checksum, true, tokenA, tokenB, amountA, amountB, liquidity, success);
            } else {
                (address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity, CrossActionStatus success) = onRemoveLPCrossTask(action);
                onEmitCrossAction(current, action.checksum, false, tokenA, tokenB, amountA, amountB, liquidity, success);
            }

            tasksIndex++;
        }
    }

    function onAddLPCrossTask(LPQueue.LPAction memory action) internal returns (address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity, CrossActionStatus success){
        (address bscTokenA, address bscTokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,,uint deadline) = LPQueue.decodeAddLP(action.payload);
        (tokenA, tokenB) = _mappingBSCTokenToAvax(bscTokenA, bscTokenB);
        // require(deadline >= block.timestamp, 'HcSwapV2Router: CROSS_EXPIRED');
        if (deadline >= block.timestamp) {
            address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
            require(pair != address(0), "HcSwapV2Router::onRemoveLPCrossTask: NO_PAIR");

            (amountA, amountB, success) = _addLiquidityNoRevert(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
            if (success == CrossActionStatus.SUCCESS) {
                IHcToken(tokenA).superMint(pair, amountA);
                IHcToken(tokenB).superMint(pair, amountB);
                liquidity = IUniswapV2Pair(pair).mint(msg.sender);
            }
        } else {
            success = CrossActionStatus.CROSS_EXPIRED;
        }
        return (bscTokenA, bscTokenB, amountA, amountB, liquidity, success);
    }

    function onRemoveLPCrossTask(LPQueue.LPAction memory action) internal returns (address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity, CrossActionStatus success){
        uint amountAMin;
        uint amountBMin;
        uint deadline;
        address bscTokenA;
        address bscTokenB;
        (bscTokenA, bscTokenB, liquidity, amountAMin, amountBMin,, deadline) = LPQueue.decodeRemoveLP(action.payload);
        (tokenA, tokenB) = _mappingBSCTokenToAvax(bscTokenA, bscTokenB);

        if (deadline >= block.timestamp) {
            address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
            require(pair != address(0), "HcSwapV2Router::onRemoveLPCrossTask: NO_PAIR");

            (uint amount0, uint amount1) = IHcSwapAvaxPair(pair).burnQuery(liquidity);
            (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
            (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
            if (amountA >= amountAMin && amountB >= amountBMin) {
                IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
                // send liquidity to pair
                (amount0, amount1) = IUniswapV2Pair(pair).burn(address(this));
                (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
                // require(amount0 == amountAMin, "HcSwapV2Router::onRemoveLPCrossTask: AMOUNT0_WRONG");
                // require(amount1 == amountBMin, "HcSwapV2Router::onRemoveLPCrossTask: AMOUNT1_WRONG");
                IHcToken(tokenA).burn(amountA);
                IHcToken(tokenB).burn(amountB);
                success = CrossActionStatus.SUCCESS;
            } else {
                if (amountA < amountAMin) {
                    success = CrossActionStatus.INSUFFICIENT_A_AMOUNT;
                }

                if (amountB < amountBMin) {
                    success = CrossActionStatus.INSUFFICIENT_B_AMOUNT;
                }
            }
        } else {
            success = CrossActionStatus.CROSS_EXPIRED;
        }
        return (bscTokenA, bscTokenB, amountA, amountB, liquidity, success);
    }

    function onEmitCrossAction(uint id, bytes32 checksum, bool addLP, address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity, CrossActionStatus success) internal {
        emit CrossActionDone(id, success, CrossAction({
        actionType : addLP ? 1 : 2,
        checksum : checksum,
        tokenA : tokenA,
        tokenB : tokenB,
        amountA : amountA,
        amountB : amountB,
        liquidity : liquidity
        }));
    }

    function _mappingBSCTokenToAvax(address bscTokenA, address bscTokenB) internal view returns (address tokenA, address tokenB){
        tokenA = BSCToAvax[bscTokenA];
        tokenB = BSCToAvax[bscTokenB];
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
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        // create the pair if it doesn't exist yet
        if (pair == address(0)) {
            require(!(crossToken[tokenA] && crossToken[tokenB]), "HcSwapV2Router::_addLiquidity CROSS_TOKEN_NOT_ALLOW_CREATE");
            pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        if (IHcSwapAvaxPair(pair).crossPair()) {
            require(isOperator(), "HcSwapV2Router::_addLiquidity ONLY_OP_CAN_ADD_CROSS_LP");
        }

        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'HcSwapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'HcSwapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _addLiquidityNoRevert(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual view returns (uint amountA, uint amountB, CrossActionStatus success){
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            return (amountA, amountB, CrossActionStatus.NO_PAIR);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                // require(amountBOptimal >= amountBMin, 'HcSwapV2Router: INSUFFICIENT_B_AMOUNT');
                if (amountBOptimal < amountBMin) {
                    return (amountA, amountB, CrossActionStatus.INSUFFICIENT_B_AMOUNT);
                }
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                // assert(amountAOptimal <= amountADesired);
                // require(amountAOptimal >= amountAMin, 'HcSwapV2Router: INSUFFICIENT_A_AMOUNT');
                if (amountAOptimal > amountADesired || amountAOptimal < amountAMin) {
                    return (amountA, amountB, CrossActionStatus.INSUFFICIENT_A_AMOUNT);
                }
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        success = CrossActionStatus.SUCCESS;
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
    ) public virtual override ensure(deadline) whenNotPaused returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) whenNotPaused returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value : amountETH}();
        require(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
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
    ) public virtual override ensure(deadline) whenNotPaused returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'HcSwapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'HcSwapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) whenNotPaused returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
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

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
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
    ) external virtual override ensure(deadline) whenNotPaused returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HcSwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) whenNotPaused returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'HcSwapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    whenNotPaused
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'HcSwapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HcSwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value : amounts[0]}();
        require(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    whenNotPaused
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'HcSwapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'HcSwapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    whenNotPaused
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'HcSwapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HcSwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    whenNotPaused
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'HcSwapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'HcSwapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value : amounts[0]}();
        require(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }
}