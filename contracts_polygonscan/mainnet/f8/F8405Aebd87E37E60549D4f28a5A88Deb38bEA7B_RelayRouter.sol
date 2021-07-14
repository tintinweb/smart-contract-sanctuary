//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IRelayRouter.sol";

/// @title RelayRouter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract RelayRouter is IRelayRouter {
    /// @inheritdoc IOracleRouterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IRelayRouter
    bytes32 public override relayTopic;
    /// @inheritdoc IRelayRouter
    address public override wallet;
    /// @inheritdoc IRelayRouter
    IERC20 public override gton;
    /// @inheritdoc IRelayRouter
    IWETH public override wnative;
    /// @inheritdoc IRelayRouter
    IUniswapV2Router01 public override router;

    /// @inheritdoc IOracleRouterV2
    mapping(address => bool) public override canRoute;

    receive() external payable {
        assert(msg.sender == address(wnative)); // only accept ETH via fallback from the WETH contract
    }

    constructor(
        address _wallet,
        IERC20 _gton,
        bytes32 _relayTopic,
        IWETH _wnative,
        IUniswapV2Router01 _router
    ) {
        owner = msg.sender;
        wallet = _wallet;
        gton = _gton;
        relayTopic = _relayTopic;
        wnative = _wnative;
        router = _router;
    }

    /// @inheritdoc IOracleRouterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IRelayRouter
    function setWallet(address _wallet) public override isOwner {
        address walletOld = wallet;
        wallet = _wallet;
        emit SetWallet(walletOld, _wallet);
    }

    /// @inheritdoc IOracleRouterV2
    function setCanRoute(address parser, bool _canRoute)
        external
        override
        isOwner
    {
        canRoute[parser] = _canRoute;
        emit SetCanRoute(msg.sender, parser, canRoute[parser]);
    }

    /// @inheritdoc IRelayRouter
    function setRelayTopic(bytes32 _relayTopic) external override isOwner {
        bytes32 topicOld = relayTopic;
        relayTopic = _relayTopic;
        emit SetRelayTopic(topicOld, _relayTopic);
    }

    function equal(bytes32 a, bytes32 b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) internal pure returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint256 startPos)
        internal
        pure
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    /// @inheritdoc IOracleRouterV2
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external override {
        require(canRoute[msg.sender], "ACR");
        if (equal(topic0, relayTopic)) {
            gton.transferFrom(wallet, address(this), amount);
            gton.approve(address(router), amount);
            address[] memory path = new address[](2);
            path[0] = address(gton);
            path[1] = address(wnative);
            address pair = IUniswapV2Factory(router.factory()).getPair(address(gton), address(wnative));
            uint112 reserve0;
            uint112 reserve1;
            (reserve0, reserve1,) = IUniswapV2Pair(pair).getReserves();
            uint256 quote = router.getAmountOut(amount, reserve0, reserve1);
            uint[] memory amounts = router.swapExactTokensForTokens(amount, quote, path, address(this), block.timestamp+3600);
            wnative.withdraw(amounts[1]);
            address payable user = payable(deserializeAddress(receiver, 0));
            user.transfer(amounts[1]);
            emit DeliverRelay(user, amounts[0]);
        }
        emit RouteValue(uuid, chain, emiter, token, sender, receiver, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IOracleRouterV2.sol";
import "./IWETH.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

interface IRelayRouter is IOracleRouterV2 {
    function relayTopic() external view returns (bytes32);

    function wallet() external view returns (address);

    function gton() external view returns (IERC20);

    function wnative() external view returns (IWETH);

    function router() external view returns (IUniswapV2Router01);

    function setWallet(address _wallet) external;

    function setRelayTopic(bytes32 _relayTopic) external;

    event DeliverRelay(address user, uint256 amount);

    event SetRelayTopic(bytes32 topicOld, bytes32 topicNew);

    event SetWallet(address walletOld, address walletNew);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton oracle router
/// @notice Forwards data about crosschain locking/unlocking events to balance keepers
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IOracleRouterV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if `user` can route data to balance keepers
    function canRoute(address user) external view returns (bool);

    /// @notice Sets the permission to route data to balance keepers
    /// @dev Can only be called by the current owner.
    function setCanRoute(address parser, bool _canRoute) external;

    /// @notice Routes value to balance keepers according to the type of event associated with topic0
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param topic0 Unique identifier of the event
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external;

    /// @notice Event emitted when the owner changes via #setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `parser` permission is updated via `#setCanRoute`
    /// @param owner The owner account at the time of change
    /// @param parser The account whose permission to route data was updated
    /// @param newBool Updated permission
    event SetCanRoute(
        address indexed owner,
        address indexed parser,
        bool indexed newBool
    );

    /// @notice Event emitted when data is routed
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event RouteValue(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );
}

pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}