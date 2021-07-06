// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./Orders.sol";

contract MateCore is Orders {
    constructor(address _addressRegistry) Orders(_addressRegistry) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniswapHandler.sol";

contract Orders is UniswapHandler {
    IERC20 MATE;

    constructor(address _addressRegistry) UniswapHandler(_addressRegistry) {
        MATE = IERC20(addressRegistry.getTokenAddr());
    }

    enum Status {
        Expired,
        Open,
        Closed,
        Canceled
    }

    struct Order {
        bytes32 id;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
        address creator;
        uint256 createdAt;
        uint256 expiration;
        Status status;
    }

    mapping(bytes32 => Order) public orders;
    mapping(address => uint256) private _nonces;

    bytes32[] public openOrders;

    event OrderPlaced(
        bytes32 indexed orderId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address indexed recipient,
        address indexed creator,
        uint256 expiration,
        uint256 timestamp
    );

    event OrderCanceled(bytes32 indexed orderId, uint256 timestamp);

    event OrderExecuted(
        bytes32 indexed orderId,
        address indexed executor,
        uint256 timestamp
    );

    function placeOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient,
        uint256 _expiration
    ) external {
        require(_tokenIn != address(0), "Invalid input token address");
        require(_tokenOut != address(0), "Invalid output token address");
        require(_amountIn > 0, "Invalid input amount");
        require(_amountOutMin > 0, "Invalid output amount");
        require(_recipient != address(0), "Invalid recipient address");
        require(_expiration > block.timestamp, "Invalid expiration timestamp");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _nonces[msg.sender]++)
        );

        Order storage order = orders[id];
        order.id = id;
        order.tokenIn = _tokenIn;
        order.tokenOut = _tokenOut;
        order.amountIn = _amountIn;
        order.amountOutMin = _amountOutMin;
        order.recipient = _recipient;
        order.creator = msg.sender;
        order.createdAt = block.timestamp;
        order.expiration = _expiration;

        _addOpenOrder(order);

        emit OrderPlaced(
            id,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _recipient,
            msg.sender,
            _expiration,
            block.timestamp
        );
    }

    function cancelOrder(bytes32 _orderId) external {
        Order storage order = orders[_orderId];
        require(msg.sender == order.creator, "Only order creator");
        require(order.status == Status.Open, "Cannot cancel unopen order");
        require(order.createdAt > 0, "Invalid order");
        order.status = Status.Canceled;
        _removeOpenOrder(_orderId);
        emit OrderCanceled(_orderId, block.timestamp);
    }

    function canExecuteOrder(bytes32 _orderId, address[] memory _path)
        external
        view
        returns (bool)
    {
        Order storage order = orders[_orderId];

        if (order.status != Status.Open) return false;

        uint256 amountOutMin = getAmountOutMin(order.amountIn, _path);

        if (amountOutMin < order.amountOutMin) return false;

        if (isExpiredOrder(_orderId)) return false;

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        if (allowance < order.amountIn) return false;

        return true;
    }

    function getPair(address _tokenIn, address _tokenOut)
        public
        view
        returns (address)
    {
        return uniswapFactory.getPair(_tokenIn, _tokenOut);
    }

    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function getReserves(address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        // address token0 = _tokenIn < _tokenOut ? _tokenIn : _tokenOut;
        // address token1 = _tokenIn > _tokenOut ? _tokenIn : _tokenOut;
        IUniswapV2Pair pair = IUniswapV2Pair(getPair(_tokenIn, _tokenOut));
        if (address(pair) != address(0)) {
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

            // uint256 rate = _tokenIn < _tokenOut
            //     ? (reserve1 * 1e18) / reserve0
            //     : reserve0 / reserve1;
            return
                _tokenIn < _tokenOut
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
        } else return (0, 0);
    }

    function executeOrder(bytes32 _orderId, address[] memory _path)
        external
        onlyExecutor
    {
        Order storage order = orders[_orderId];

        require(order.status == Status.Open, "Cannot execute unopen order");

        uint256 amountOutMin = getAmountOutMin(order.amountIn, _path);

        require(
            amountOutMin >= order.amountOutMin,
            "Insufficient output amount"
        );

        require(!isExpiredOrder(_orderId), "Cannot execute expired order");

        IERC20(order.tokenIn).transferFrom(
            order.creator,
            address(this),
            order.amountIn
        );

        require(
            swap(_path, order.amountIn, order.amountOutMin, order.recipient),
            "Swap failed"
        );

        order.status = Status.Closed;
        _removeOpenOrder(_orderId);

        emit OrderExecuted(_orderId, msg.sender, block.timestamp);
    }

    function getNonce(address _addr) external view returns (uint256) {
        return _nonces[_addr];
    }

    function getStatus(bytes32 _orderId) external view returns (Status) {
        Order storage order = orders[_orderId];

        if (order.status == Status.Open) {
            if (block.timestamp >= order.expiration) return Status.Expired;
        }

        return order.status;
    }

    function isExpiredOrder(bytes32 _orderId) public view returns (bool) {
        Order storage order = orders[_orderId];
        return block.timestamp >= order.expiration;
    }

    modifier onlyExecutor() {
        require(
            IStaking(addressRegistry.getStakingAddr()).isExecutor(msg.sender),
            "Only executor"
        );
        _;
    }

    function _removeOpenOrder(bytes32 _orderId) private {
        uint256 length = openOrders.length;
        for (uint256 i = 0; i < length; i++) {
            if (openOrders[i] == _orderId) {
                openOrders[i] = openOrders[length - 1];
                openOrders.pop();
                break;
            }
        }
    }

    function _addOpenOrder(Order storage _order) private {
        _order.status = Status.Open;
        openOrders.push(_order.id);
    }

    function getOrder(bytes32 _orderId)
        public
        view
        returns (
            bytes32 id,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOutMin,
            address recipient,
            address creator,
            uint256 createdAt,
            uint256 expiration,
            uint8 status
        )
    {
        Order storage order = orders[_orderId];
        id = order.id;
        tokenIn = order.tokenIn;
        tokenOut = order.tokenOut;
        amountIn = order.amountIn;
        amountOutMin = order.amountOutMin;
        recipient = order.recipient;
        createdAt = order.createdAt;
        creator = order.creator;
        expiration = order.expiration;
        status = uint8(order.status);
    }

    function getOpenOrders() external view returns (bytes32[] memory) {
        return openOrders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";

contract UniswapHandler {
    IAddressRegistry public addressRegistry;
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;

    constructor(address _addressRegistry) {
        addressRegistry = IAddressRegistry(_addressRegistry);
        uniswapRouter = IUniswapV2Router02(
            addressRegistry.getUniswapRouterAddr()
        );
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
    }

    /**
     * @dev Function to swap tokens
     * @param _path An array of addresses from tokenIn to tokenOut
     * @param _amountIn Amount of input tokens
     * @param _amountOutMin Mininum amount of output tokens
     * @param _recipient Address to send output tokens to
     */
    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient
    ) public returns (bool) {
        IERC20(_path[0]).approve(address(uniswapRouter), _amountIn);

        uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _recipient,
            block.timestamp + 5 minutes
        );

        return true;
    }

    /**
     * @dev Function to get the minumum amount from a swap
     * @param _amountIn Amount of input token
     * @param _path An array of addresses from tokenIn to tokenOut
     * @return Minumim amount out
     */
    function getAmountOutMin(uint256 _amountIn, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amountOutMins = uniswapRouter.getAmountsOut(
            _amountIn,
            _path
        );

        return amountOutMins[_path.length - 1];
    }

    function getPath(address _tokenIn, address _tokenOut)
        public
        view
        returns (address[] memory path)
    {
        if (
            _tokenIn == uniswapRouter.WETH() ||
            _tokenOut == uniswapRouter.WETH()
        ) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = uniswapRouter.WETH();
            path[2] = _tokenOut;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAddressRegistry {
    function getCoreAddr() external view returns (address);

    function getStakingAddr() external view returns (address);

    function getTokenAddr() external view returns (address);

    function getUniswapRouterAddr() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStaking {
    function isExecutor(address _executor) external view returns (bool);
}