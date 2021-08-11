// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AvacusccPayContract is Initializable {
    struct SwapData {
        bytes16 swapId;
        address spender;
        address receiver;
        address tokenSpend;
        uint256 amountSpend;
        address tokenReceive;
        uint256 amountReceive;
        uint256 deadline;
    }

    mapping(bytes16 => SwapData) public swaps;

    event SwapCreated(bytes16 swapId, SwapData swapData);
    event SwapExecuted(bytes16 swapId, address tokenSpend, uint256 amountSpend);

    address public uniswapV2Factory;
    address public uniswapV2Router;

    function initialize() public {
        uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }

    address public sender;

    // Create new swap
    // At create, receiver should be non
    // SwapId shouldn't exist before
    // SwapId should be valid (not zero and is a bytes16)
    // information about token spend (amount, address) should be valid
    // the spender of swap will be the sender
    // *
    // Event: SwapCreated(bytes16 swapId, SwapData swapData)
    function createSwap(bytes16 _swapId, SwapData memory _swapData) external {
        require(_swapId != bytes16(0), "Non valid swap id");
        require(_swapId == _swapData.swapId, "Not same swap id");
        require(swaps[_swapId].swapId == bytes16(0), "Existed swap id");
        require(_swapData.tokenReceive != address(0), "Non valid token spend");
        require(_swapData.amountReceive > 0, "Non valid spend amount");
        require(
            _swapData.receiver != address(0),
            "receiver should be non at creating"
        );

        _swapData.receiver = msg.sender;
        swaps[_swapId] = _swapData;

        emit SwapCreated(_swapId, _swapData);
    }

    // receiver apply & swap
    function applySwap(
        bytes16 _swapId,
        address _tokenSpend,
        address _paiAddress,
        address to
    ) public payable {
        require(swaps[_swapId].spender == address(0), "This swap was applied");
        // valid pair Address && approval amount
        IUniswapV2Pair pair = IUniswapV2Pair(_paiAddress);
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);
        IERC20 tokenSpend = IERC20(_tokenSpend);
        uint256 amountInt;
        uint256 amount0Out;
        uint256 amount1Out;
        // this block to prevent too deep stack
        // Get amount in to validate approval (allowance of sender)
        // After valid, transfer to contract
        // getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn)
        {
            address _tokenReceive = swaps[_swapId].tokenReceive;
            uint256 _amountReceive = swaps[_swapId].amountReceive;
            (address token0, address token1) = _tokenSpend < _tokenReceive
                ? (_tokenSpend, _tokenReceive)
                : (_tokenReceive, _tokenSpend);
            require(
                pair.token0() == token0 && pair.token1() == token1,
                "invalid_pair"
            );
            // defult: reserve0 <-> In = spend, reserve1 <-> Out = receive
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint32 blockTimestampLast
            ) = pair.getReserves();
            // we need to redefine
            // In <-> token spend =>
            // Out <-> token receive
            if (token0 == _tokenReceive) {
                (reserveIn, reserveOut) = (reserveOut, reserveIn);
                amount0Out = _amountReceive;
                amount1Out = 0;
            } else {
                amount1Out = _amountReceive;
                amount0Out = 0;
            }
            // define reversIn and reverseOut
            amountInt = router.getAmountIn(
                _amountReceive,
                reserveIn,
                reserveOut
            );
            require(
                tokenSpend.allowance(msg.sender, address(this)) >= amountInt,
                "issuficient_approval"
            );
        }
        // After pass validator, transfer spend token to PayContract
        tokenSpend.transferFrom(msg.sender, address(this), amountInt);

        // make swap
        //function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)
        pair.swap(amount0Out, amount1Out, to, ""); // used for test
        // pair.swap(amount0Out, amount1Out, swaps[_swapId].receiver, "");
        // assign information
        swaps[_swapId].spender = msg.sender;
        swaps[_swapId].tokenSpend = _tokenSpend;

        emit SwapExecuted(_swapId, _tokenSpend, amountInt);
    }

    // Estimate amout receive token based on rate from uniswap
    function estimateAmountSpend(
        bytes16 _swapId,
        address _tokenSpend,
        address _paiAddress
    ) public view returns (uint256 amountIn) {
        require(swaps[_swapId].spender == address(0), "This swap was applied");
        // valid pair Address && approval amount
        IUniswapV2Pair pair = IUniswapV2Pair(_paiAddress);
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);
        IERC20 tokenSpend = IERC20(_tokenSpend);
        // this block to prevent too deep stack
        // Get amount in to validate approval (allowance of sender)
        // After valid, transfer to contract
        // getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn)
        {
            address _tokenReceive = swaps[_swapId].tokenReceive;
            uint256 _amountReceive = swaps[_swapId].amountReceive;
            (address token0, address token1) = _tokenSpend < _tokenReceive
                ? (_tokenSpend, _tokenReceive)
                : (_tokenReceive, _tokenSpend);
            require(
                pair.token0() == token0 && pair.token1() == token1,
                "invalid_pair"
            );
            // defult: reserve0 <-> In = spend, reserve1 <-> Out = receive
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint256 blockTimestampLast
            ) = pair.getReserves();
            // we need to redefine
            // In <-> token spend =>
            // Out <-> token receive
            if (token0 == _tokenReceive) {
                (reserveIn, reserveOut) = (reserveOut, reserveIn);
            }
            // define reversIn and reverseOut
            amountIn = router.getAmountIn(
                _amountReceive,
                reserveIn,
                reserveOut
            );
            require(
                tokenSpend.allowance(msg.sender, address(this)) >= amountIn,
                "issuficient_approval"
            );
        }
    }

    receive() external payable {}

    fallback() external payable {}
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

pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function setValue(string memory value) external returns (address);

    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}