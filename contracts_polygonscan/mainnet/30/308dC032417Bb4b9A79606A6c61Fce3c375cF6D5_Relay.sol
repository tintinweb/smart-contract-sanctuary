//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IRelay.sol";

/// @title Relay
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract Relay is IRelay {

    /// @inheritdoc IOracleRouterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IRelay
    IWETH public override wnative;
    /// @inheritdoc IRelay
    IUniswapV2Router01 public override router;
    /// @inheritdoc IRelay
    IERC20 public override gton;

    /// @inheritdoc IRelay
    mapping (string => uint256) public override feeMin;
    /// @inheritdoc IRelay
    /// @dev 30000 = 30%, 200 = 0.2%, 1 = 0.001%
    mapping (string => uint256) public override feePercent;

    /// @inheritdoc IRelay
    mapping(string => uint256) public override lowerLimit;

    /// @inheritdoc IRelay
    mapping(string => uint256) public override upperLimit;

    /// @inheritdoc IRelay
    bytes32 public override relayTopic;

    /// @inheritdoc IOracleRouterV2
    mapping(address => bool) public override canRoute;

    /// @inheritdoc IRelay
    mapping(string => bool) public override isAllowedChain;

    receive() external payable {
        // only accept ETH via fallback from the WETH contract
        assert(msg.sender == address(wnative));
    }

    constructor (
        IWETH _wnative,
        IUniswapV2Router01 _router,
        IERC20 _gton,
        bytes32 _relayTopic,
        string[] memory allowedChains,
        uint[2][] memory fees,
        uint[2][] memory limits
    ) {
        owner = msg.sender;
        wnative = _wnative;
        router = _router;
        gton = _gton;
        relayTopic = _relayTopic;
        for (uint256 i = 0; i < allowedChains.length; i++) {
            isAllowedChain[allowedChains[i]] = true;
            feeMin[allowedChains[i]] = fees[i][0];
            feePercent[allowedChains[i]] = fees[i][1];
            lowerLimit[allowedChains[i]] = limits[i][0];
            upperLimit[allowedChains[i]] = limits[i][1];
        }
    }

    /// @inheritdoc IOracleRouterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IRelay
    function setIsAllowedChain(string calldata chain, bool newBool)
        external
        override
        isOwner
    {
        isAllowedChain[chain] = newBool;
        emit SetIsAllowedChain(chain, newBool);
    }

    /// @inheritdoc IRelay
    function setFees(string calldata destination, uint256 _feeMin, uint256 _feePercent) external override isOwner {
        feeMin[destination] = _feeMin;
        feePercent[destination] = _feePercent;
        emit SetFees(destination, _feeMin, _feePercent);
    }

    /// @inheritdoc IRelay
    function setLimits(string calldata destination, uint256 _lowerLimit, uint256 _upperLimit) external override isOwner {
        lowerLimit[destination] = _lowerLimit;
        upperLimit[destination] = _upperLimit;
        emit SetLimits(destination, _lowerLimit, _upperLimit);
    }

    /// @inheritdoc IRelay
    function lock(string calldata destination, bytes calldata receiver) external payable override {
        require(isAllowedChain[destination], "R1");
        require(msg.value > lowerLimit[destination], "R2");
        require(msg.value < upperLimit[destination], "R3");
        // wrap native tokens
        wnative.deposit{value: msg.value}();
        // trade wrapped native tokens for relay tokens
        wnative.approve(address(router), msg.value);
        address[] memory path = new address[](2);
        path[0] = address(wnative);
        path[1] = address(gton);
        uint256[] memory amounts = router.swapExactTokensForTokens(msg.value, 0, path, address(this), block.timestamp+3600);
        // subtract fee
        uint256 amountMinusFee;
        uint256 fee = amounts[1] * feePercent[destination] / 100000;
        if (fee > feeMin[destination]) {
            amountMinusFee = amounts[1] - fee;
        } else {
            amountMinusFee = amounts[1] - feeMin[destination];
        }
        emit CalculateFee(amounts[0], amounts[1], feeMin[destination], feePercent[destination], fee, amountMinusFee);
        // check that remainder after subtracting fees is larger than 0
        require(amountMinusFee > 0, "R4");
        // emit event to notify oracles and initiate crosschain transfer
        emit Lock(destination, receiver, destination, receiver, amountMinusFee);
    }

    /// @inheritdoc IRelay
    function reclaimERC20(IERC20 token, uint256 amount) external override isOwner {
        token.transfer(msg.sender, amount);
    }

    /// @inheritdoc IRelay
    function reclaimNative(uint256 amount) external override isOwner {
        payable(msg.sender).transfer(amount);
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

    /// @inheritdoc IRelay
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
            // trade relay tokens for wrapped native tokens
            gton.approve(address(router), amount);
            address[] memory path = new address[](2);
            path[0] = address(gton);
            path[1] = address(wnative);
            uint[] memory amounts = router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp+3600);
            // unwrap to get native tokens
            wnative.withdraw(amounts[1]);
            // transfer native tokens to the receiver
            address payable user = payable(deserializeAddress(receiver, 0));
            user.transfer(amounts[1]);
            emit DeliverRelay(user, amounts[0], amounts[1]);
        }
        emit RouteValue(uuid, chain, emiter, token, sender, receiver, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./IWETH.sol";
import "./IOracleRouterV2.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

/// @title The interface for Graviton relay contract
/// @notice Trades native tokens for gton to start crosschain swap,
/// trades gton for native tokens to compelete crosschain swap
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IRelay is IOracleRouterV2 {
    /// @notice ERC20 wrapped version of the native token
    function wnative() external view returns (IWETH);

    /// @notice UniswapV2 router
    function router() external view returns (IUniswapV2Router01);

    /// @notice relay token
    function gton() external view returns (IERC20);

    /// @notice chains for relay swaps to and from
    function isAllowedChain(string calldata chain) external view returns (bool);

    /// @notice allow/forbid chain to relay swap
    /// @param chain blockchain name, e.g. 'FTM', 'PLG'
    /// @param newBool new permission for the chain
    function setIsAllowedChain(string calldata chain, bool newBool) external;

    /// @notice minimum fee for a destination
    function feeMin(string calldata destination) external view returns (uint256);

    /// @notice percentage fee for a destination
    function feePercent(string calldata destination) external view returns (uint256);

    /// @notice Sets fees for a destination
    /// @param _feeMin Minimum fee
    /// @param _feePercent Percentage fee
    function setFees(string calldata destination, uint256 _feeMin, uint256 _feePercent) external;

    /// @notice minimum amount of native tokens allowed to swap
    function lowerLimit(string calldata destination) external view returns (uint256);

    /// @notice maximum amount of native tokens allowed to swap
    function upperLimit(string calldata destination) external view returns (uint256);

    /// @notice Sets limits for a destination
    /// @param _lowerLimit Minimum amount of native tokens allowed to swap
    /// @param _upperLimit Maximum amount of native tokens allowed to swap
    function setLimits(string calldata destination, uint256 _lowerLimit, uint256 _upperLimit) external;

    /// @notice topic0 of the event associated with initiating a relay transfer
    function relayTopic() external view returns (bytes32);

    /// @notice Sets topic0 of the event associated with initiating a relay transfer
    function setRelayTopic(bytes32 _relayTopic) external;

    /// @notice Trades native tokens for relay, takes fees,
    /// emits event to start crosschain transfer
    /// @param destination The blockchain that will receive native tokens
    /// @param receiver The account that will receive native tokens
    function lock(string calldata destination, bytes calldata receiver) external payable;

    /// @notice Transfers locked ERC20 tokens to owner
    function reclaimERC20(IERC20 token, uint256 amount) external;

    /// @notice Transfers locked native tokens to owner
    function reclaimNative(uint256 amount) external;

    /// @notice Event emitted when native tokens equivalent to
    /// `amount` of relay tokens are locked via `#lock`
    /// @dev Oracles read this event and unlock
    /// equivalent amount of native tokens on the destination chain
    /// @param destinationHash The blockchain that will receive native tokens
    /// @dev indexed string returns keccak256 of the value
    /// @param receiverHash The account that will receive native tokens
    /// @dev indexed bytes returns keccak256 of the value
    /// @param destination The blockchain that will receive native tokens
    /// @param receiver The account that will receive native tokens
    /// @param amount The amount of relay tokens equivalent to the
    /// amount of locked native tokens
    event Lock(
        string indexed destinationHash,
        bytes indexed receiverHash,
        string destination,
        bytes receiver,
        uint256 amount
    );

    /// @notice Event emitted when fees are calculated
    /// @param amountIn Native tokens sent to dex
    /// @param amountOut Relay tokens received on dex
    /// @param feeMin Minimum fee
    /// @param feePercent Percentage for the fee in %
    /// @dev precision 3 decimals
    /// @param fee Percentage fee in relay tokens
    /// @param amountMinusFee Relay tokens minus fees
    event CalculateFee(
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeMin,
        uint256 feePercent,
        uint256 fee,
        uint256 amountMinusFee
    );

    /// @notice Event emitted when the relay tokens are traded for
    /// `amount0` of gton swaped for native tokens via '#routeValue'
    /// `amount1` of native tokens sent to the `user` via '#routeValue'
    event DeliverRelay(address user, uint256 amount0, uint256 amount1);

    /// @notice Event emitted when the RelayTopic is set via '#setRelayTopic'
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetRelayTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice Event emitted when the wallet is set via '#setWallet'
    /// @param walletOld The previous wallet address
    /// @param walletNew The new wallet address
    event SetWallet(address indexed walletOld, address indexed walletNew);

    /// @notice Event emitted when permission for a chain is set via '#setIsAllowedChain'
    /// @param chain Name of blockchain whose permission is changed, i.e. "FTM", "PLG"
    /// @param newBool Updated permission
    event SetIsAllowedChain(string chain, bool newBool);

    /// @notice Event emitted when fees are set via '#setFees'
    /// @param _feeMin Minimum fee
    /// @param _feePercent Percentage fee
    event SetFees(string destination, uint256 _feeMin, uint256 _feePercent);

    /// @notice Event emitted when limits are set via '#setLimits'
    /// @param _lowerLimit Minimum fee
    /// @param _upperLimit Percentage fee
    event SetLimits(string destination, uint256 _lowerLimit, uint256 _upperLimit);
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

pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint amount) external;

    function transfer(address to, uint amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
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

