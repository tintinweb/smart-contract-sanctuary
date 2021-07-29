//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IRelayLock.sol";

/// @title RelayLock
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract RelayLock is IRelayLock {

    /// @inheritdoc IRelayLock
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IRelayLock
    IWETH public override wnative;
    /// @inheritdoc IRelayLock
    IUniswapV2Router01 public override router;
    /// @inheritdoc IRelayLock
    IERC20 public override gton;

    /// @inheritdoc IRelayLock
    mapping (string => uint256) public override feeMin;
    /// @inheritdoc IRelayLock
    /// @dev 30000 = 30%, 200 = 0.2%, 1 = 0.001%
    mapping (string => uint256) public override feePercent;

    constructor (IWETH _wnative, IUniswapV2Router01 _router, IERC20 _gton) {
        owner = msg.sender;
        wnative = _wnative;
        router = _router;
        gton = _gton;
    }

    /// @inheritdoc IRelayLock
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IRelayLock
    function setFees(string calldata destination, uint256 _feeMin, uint256 _feePercent) external override {
        feeMin[destination] = _feeMin;
        feePercent[destination] = _feePercent;
    }

    /// @inheritdoc IRelayLock
    function lock(string calldata destination, bytes calldata receiver) external payable override {
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
        // check that the amount is larger than the fee
        require(amountMinusFee > 0, "RL1");
        // emit event to notify oracles and initiate crosschain transfer
        emit Lock(destination, receiver, destination, receiver, amountMinusFee);
    }

    /// @inheritdoc IRelayLock
    function reclaimERC20(IERC20 token) external override isOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @inheritdoc IRelayLock
    function reclaimNative(uint256 amount) external override isOwner {
        payable(msg.sender).transfer(amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Router01.sol";

/// @title The interface for Graviton relay lock
/// @notice Trades native tokens for gton, starts crosschain transfer
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IRelayLock {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`)
    /// @dev Can only be called by the current owner
    function setOwner(address _owner) external;

    /// @notice ERC20 wrapped version of the native token
    function wnative() external view returns (IWETH);

    /// @notice UniswapV2 router
    function router() external view returns (IUniswapV2Router01);

    /// @notice relay token
    function gton() external view returns (IERC20);

    /// @notice minimum fee for a destination
    function feeMin(string calldata destination) external view returns (uint256);

    /// @notice percentage fee for a destination
    function feePercent(string calldata destination) external view returns (uint256);

    /// @notice Sets fees for a destination
    /// @param _feeMin Minimum fee
    /// @param _feePercent Percentage fee
    function setFees(string calldata destination, uint256 _feeMin, uint256 _feePercent) external;

    /// @notice Trades native tokens for relay, takes fees,
    /// emits event to start crosschain transfer
    /// @param destination The blockchain that will receive native tokens
    /// @param receiver The account that will receive native tokens
    function lock(string calldata destination, bytes calldata receiver) external payable;

    /// @notice Transfers locked ERC20 tokens to owner
    function reclaimERC20(IERC20 token) external;

    /// @notice Transfers locked native tokens to owner
    function reclaimNative(uint256 amount) external;

    /// @notice Event emitted when the owner changes via #setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

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