pragma solidity >=0.5.0;

interface IHcTokenFactory {
    function transferOwnership(address newOwner) external;

    function createAToken(string calldata name_,string calldata symbol_,uint8 decimals,address originAddress_) external returns(address token);
}

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IHcSwapAvaxFactory.sol';
import './libraries/TransferHelper.sol';
import '../public/libraries/LPQueue.sol';
import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IHcToken.sol';
import './interfaces/IWETH.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IHcSwapAvaxPair.sol';
import './interfaces/IHcTokenFactory.sol';
import '../public/contract/Pausable.sol';
import "openzeppelin3/proxy/Initializable.sol";

contract HcSwapAvaxRouter is IUniswapV2Router02, Pausable, Initializable {
    using SafeMath for uint;

    address public override factory;
    address public override WETH;
    address public tokenFactory;

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

    constructor() public initializer {}

    function initialize(address _factory, address _WETH, address _tokenFactory) public initializer{
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {

}

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IHcSwapAvaxPair.sol';
import '../interfaces/IUniswapV2Factory.sol';

import "./SafeMath.sol";

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

pragma solidity >=0.5.0;
import './IERC20.sol';

interface IHcToken is IERC20 {
    function originAddress() external view returns(address);
    function superMint(address to_,uint256 amount_) external;
    function transferOwnership(address newOwner) external;
    function burn(uint256 amount_) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

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

pragma solidity >=0.6.2;

import './IUniswapV2Pair.sol';

interface IHcSwapAvaxPair is IUniswapV2Pair {
    function setCrossPair(bool status_) external;
    function crossPair() external view returns (bool);
    function burnQuery(uint liquidity) external view returns (uint amount0, uint amount1);
}

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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import './interfaces/IHcSwapBSCFactory.sol';
import './libraries/TransferHelper.sol';

import './interfaces/IHcSwapBSC.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IHcSwapBSCPair.sol';
import '../public/libraries/LPQueue.sol';
import '../public/contract/Pausable.sol';
import "openzeppelin3/proxy/Initializable.sol";

contract HcSwapV2Router02 is IHcSwapBSC, Pausable, Initializable {
    using SafeMath for uint;
    using LPQueue for LPQueue.Store;

    address public override factory;
    address public override WETH;

    address public owner;
    mapping(address => bool) public operator;

    uint private unlocked;
    uint public fee; //0.002 bnb
    address public crossFeeReceiver;
    LPQueue.Store public tasks;

    struct CrossAction {
        uint8 actionType; // 0 sync amount 1 mint lp 2 burn lp
        bytes32 checksum;//important!
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;// when type is sync, this field will be zero.
        bool success;
    }

    function getTask(uint256 id) public view returns (LPQueue.LPAction memory) {
        return tasks.queue[id];
    }

    event CrossLiquidity(uint256 indexed id, bytes32 indexed checksum, bool addLP, LPQueue.LPAction action);
    event CreateCrossLP(address indexed pair, address token0, address token1, uint amount0, uint amount1);
    event CrossTaskDone(uint256 indexed id, bool addLP, bool success);
    event SetCrossFee(uint fee);

    function setCrossFee(uint fee_) public onlyOwner {
        fee = fee_;
        emit SetCrossFee(fee);
    }

    function setCrossFeeReceiver(address receiver_) public onlyOwner {
        crossFeeReceiver = receiver_;
    }

    function isOperator(address sender) public view returns (bool){
        return operator[sender] || sender == owner;
    }

    modifier lock() {
        require(unlocked == 1, 'HcSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "HcSwapV2Router: ONLY_OWNER");
        _;
    }

    modifier onlyOperator(){
        require(isOperator(msg.sender), "HcSwapV2Router: ONLY_OPERATOR");
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'HcSwapV2Router: EXPIRED');
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setFactoryOwner(address _owner) onlyOwner public {
        if (IHcSwapBSCFactory(factory).owner() == address(this)) {
            IHcSwapBSCFactory(factory).setOwner(_owner);
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

    function setOperator(address[] memory _ops, bool[] memory _status) onlyOwner public {
        require(_ops.length == _status.length, "HcSwapV2Router:SET_OPERATOR_WRONG_DATA");
        for (uint i = 0; i < _ops.length; i++) {
            operator[_ops[i]] = _status[i];
        }
    }

    constructor() public initializer {}

    function initialize (address _factory, address _WETH) public initializer {
        factory = _factory;
        WETH = _WETH;
        owner = msg.sender;
        tasks.initStorage();
        crossFeeReceiver = msg.sender;
        unlocked = 1;
        fee = 2 finney; //0.002 bnb
    }

    receive() external payable {
        require(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    function onCrossSync(CrossAction[] calldata actions) external onlyOperator {
        for (uint256 i = 0; i < actions.length; i++) {
            CrossAction memory action = actions[i];
            IHcSwapBSCPair pair = IHcSwapBSCPair(UniswapV2Library.pairFor(factory, action.tokenA, action.tokenB));

            (address token0,address token1) = (pair.token0(), pair.token1());
            (uint256 amount0,uint256 amount1) = action.tokenA == pair.token0() ? (action.amountA, action.amountB) : (action.amountB, action.amountA);
            if (action.actionType == 0) {//sync
                if (IERC20(token0).balanceOf(address(pair)) < amount0) {
                    TransferHelper.safeTransferFrom(token0, msg.sender, address(pair), amount0.sub(IERC20(token0).balanceOf(address(pair))));
                }
                if (IERC20(token1).balanceOf(address(pair)) < amount1) {
                    TransferHelper.safeTransferFrom(token1, msg.sender, address(pair), amount1.sub(IERC20(token1).balanceOf(address(pair))));
                }
                pair.directlySync(amount0, amount1, msg.sender);
            } else {// mint lp
                pair.skim(msg.sender);
                LPQueue.LPAction storage task = tasks.readFirst();
                emit CrossTaskDone(tasks.currentIndex(), action.actionType == 1, action.success);
                if (action.actionType == 1) {
                    require(action.checksum == task.checksum, "HcSwap:CHECKSUM_ERROR");
                    (,,uint amountADesired,uint amountBDesired,,,,) = LPQueue.decodeAddLP(task.payload);
                    if (action.success) {
                        require(action.liquidity > 0, "HcSwap:ZERO_LIQUIDITY");
                        TransferHelper.safeTransfer(action.tokenA, address(pair), action.amountA);
                        TransferHelper.safeTransfer(action.tokenB, address(pair), action.amountB);

                        if (amountADesired > action.amountA) {
                            TransferHelper.safeTransfer(action.tokenA, task.to, amountADesired.sub(action.amountA));
                        }
                        if (amountBDesired > action.amountB) {
                            TransferHelper.safeTransfer(action.tokenB, task.to, amountBDesired.sub(action.amountB));
                        }
                        pair.directlyMint(action.liquidity, task.to);
                    } else {
                        TransferHelper.safeTransfer(action.tokenA, task.to, amountADesired);
                        TransferHelper.safeTransfer(action.tokenB, task.to, amountBDesired);
                    }
                    tasks.dequeue();
                } else if (action.actionType == 2) {
                    require(action.checksum == task.checksum, "HcSwap: INVALID_CHECKSUM");
                    //tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline
                    (,,uint liquidity,,,,) = LPQueue.decodeRemoveLP(task.payload);
                    require(action.liquidity == liquidity, "HcSwap: INVALID_LIQUIDITY");
                    if (action.success) {
                        pair.directlyBurn(action.liquidity, address(this), task.to, amount0, amount1);
                    } else {
                        TransferHelper.safeTransfer(address(pair), task.to, action.liquidity);
                    }
                    tasks.dequeue();
                } else {
                    revert('HcSwap:UNKNOWN_TYPE');
                }
            }
        }
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
        require(IHcSwapBSCFactory(factory).getPair(tokenA, tokenB) == address(0), "HcSwapBSC: PAIR_ALREADY_EXISTS");
        require(isOperator(msg.sender), "HcSwapBSC:NOT_OPERATOR");
        IHcSwapBSCPair pair = IHcSwapBSCPair(IHcSwapBSCFactory(factory).createPair(tokenA, tokenB));
        (uint amount0,uint amount1) = pair.token0() == tokenA ? (amountADesired, amountBDesired) : (amountBDesired, amountADesired);
        emit CreateCrossLP(address(pair), pair.token0(), pair.token1(), amount0, amount1);
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

    function addLiquidityFromUser(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        uint deadline
    ) external ensure(deadline) lock whenNotPaused payable returns (uint256 index) {
        require(msg.value == fee, "HcSwapBSC::addLiquidityFromUser: NEED_FEE");
        payable(crossFeeReceiver).transfer(msg.value);
        address to = msg.sender;
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        require(pair != address(0), "HcSwapBSC: ONLY_CREATED_LP_ALLOW");
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

        LPQueue.LPAction memory lpAction = LPQueue.encodeAddLP(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        tasks.enqueue(lpAction);
        index = tasks.last;
        emit CrossLiquidity(index, lpAction.checksum, true, lpAction);
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
    ) external virtual override ensure(deadline) onlyOperator returns (uint amountA, uint amountB, uint liquidity) {
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
    ) external virtual override payable ensure(deadline) onlyOperator returns (uint amountToken, uint amountETH, uint liquidity) {
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
    ) public virtual override ensure(deadline) onlyOperator returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'HcSwapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'HcSwapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityFromUser(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        uint deadline
    ) external ensure(deadline) lock whenNotPaused payable returns (uint256 index) {
        require(msg.value == fee, "HcSwapBSC::addLiquidityFromUser: NEED_FEE");
        payable(crossFeeReceiver).transfer(msg.value);
        address to = msg.sender;
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        require(pair != address(0), "HcSwapBSC:ONLY_CREATED_LP");
        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        LPQueue.LPAction memory lpAction = LPQueue.encodeRemoveLP(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
        tasks.enqueue(lpAction);
        index = tasks.last;
        emit CrossLiquidity(index, lpAction.checksum, false, lpAction);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) onlyOperator returns (uint amountToken, uint amountETH) {
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) onlyOperator returns (uint[] memory amounts) {
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
    ) external virtual override ensure(deadline) onlyOperator returns (uint[] memory amounts) {
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
    onlyOperator
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
    onlyOperator
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
    onlyOperator
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
    onlyOperator
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

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    public
    pure
    virtual
    override
    returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    public
    pure
    virtual
    override
    returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    // help some people save their money
    function refund(address token, address to) public onlyOwner {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }
}

pragma solidity >=0.5.0;

interface IHcSwapBSCFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function owner() external view returns (address);
    function setOwner(address _owner) external;
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

pragma solidity >=0.6.2;

interface IHcSwapBSC {
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IHcSwapBSCFactory.sol';

import "./SafeMath.sol";

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
        pair = IHcSwapBSCFactory(factory).getPair(tokenA, tokenB);
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

interface IHcSwapBSCPair {
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
    
    function directlyMint(uint liquidity, address to) external;
    function directlyBurn(uint liquidity, address from, address to, uint amount0, uint amount1) external;
    function directlySync(uint256 amount0, uint256 amount1, address to) external;
}

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

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
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

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.6.2;

import './interfaces/IHcSwapAvaxPair.sol';
import './interfaces/IHcSwapAvaxFactory.sol';
import './interfaces/IUniswapV2Factory.sol';
import './libraries/SafeMath.sol';
import './libraries/UniswapV2Library.sol';

contract HcSwapHelper {
    using SafeMath for uint;

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function calcMintFee(address _pair) public view returns (uint liquidity) {
        IHcSwapAvaxPair pair = IHcSwapAvaxPair(_pair);
        uint kLast = pair.kLast();
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (kLast != 0 && IUniswapV2Factory(pair.factory()).feeTo() != address(0)) {
            uint rootK = sqrt(uint(reserve0).mul(reserve1));
            uint rootKLast = sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator = pair.totalSupply().mul(rootK.sub(rootKLast));
                uint denominator = (rootK.mul(3) / 2).add(rootKLast);
                liquidity = numerator / denominator;
            }
        }
    }

    function calcReserve(address _pair, address _operator) public view returns (uint reserve0, uint reserve1) {
        IHcSwapAvaxPair pair = IHcSwapAvaxPair(_pair);
        (reserve0, reserve1,) = pair.getReserves();
        uint feeLp = pair.totalSupply().sub(pair.balanceOf(_operator)).sub(1000).add(calcMintFee(_pair));
        (uint amount0, uint amount1) = pair.burnQuery(feeLp);
        reserve0 = reserve0.sub(amount0);
        reserve1 = reserve1.sub(amount1);
    }

    function getReservesWithCross(address factory, address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB, bool cross) {
        (reserveA, reserveB, cross) = UniswapV2Library.getReservesWithCross(factory, tokenA, tokenB);
    }

    function getReserves(address factory, address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
    }

    function getAmountOutNoCross(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        return UniswapV2Library.getAmountOutNoCross(amountIn, reserveIn, reserveOut);
    }

    function getAmountInNoCross(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        return UniswapV2Library.getAmountInNoCross(amountOut, reserveIn, reserveOut);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
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