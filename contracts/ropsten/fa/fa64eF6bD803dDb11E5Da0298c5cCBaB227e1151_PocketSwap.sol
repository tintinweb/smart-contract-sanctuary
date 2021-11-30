// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./pocketswap/interfaces/IPocket.sol";

contract Pocket is IPocket, ERC20("XPocket", "POCKET"), Ownable {
    mapping(address => bool) public override rewardsExcluded;
    mapping(address => uint256) public lastTotalDividends;
    uint256 public rewardsIncludedSupply;
    uint256 private totalDividends;

    constructor() {
        _mint(msg.sender, 50e6 ether);
        rewardsIncludedSupply = totalSupply();
        rewardsExcluded[address(this)] = true;
    }

    function _calcRewards(address account) internal view virtual returns (uint256) {
        if (account == address(this) || rewardsExcluded[account]) {
            return 0;
        }

        uint256 _balance = ERC20.balanceOf(account);
        if (_balance == 0) {
            return 0;
        }

        return (_balance * (totalDividends - lastTotalDividends[account])) / rewardsIncludedSupply;
    }

    modifier _distribute(address account) {
        uint256 rewards = _calcRewards(account);
        lastTotalDividends[account] = totalDividends;

        if (rewards > 0) {
            super._transfer(address(this), account, rewards);
        }
        _;
    }

    modifier _notExcluded(address account) {
        require(!rewardsExcluded[account], "Pocket: Already excluded from rewards");
        _;
    }

    modifier _excluded(address account) {
        require(rewardsExcluded[account], "Pocket: Not excluded from rewards");
        _;
    }

    function excludeFromRewards(address account)
    _notExcluded(account)
    _distribute(account)
    external onlyOwner {
        rewardsExcluded[account] = true;
        rewardsIncludedSupply -= ERC20.balanceOf(account);
    }

    function includeInRewards(address account)
    _excluded(account)
    external onlyOwner {
        delete rewardsExcluded[account];
        lastTotalDividends[account] = totalDividends;
        rewardsIncludedSupply += ERC20.balanceOf(account);
    }

    function addRewards(uint256 amount) override external returns (bool) {
        return transfer(address(this), amount);
    }

    /**
     * @dev See {ERC20-_transfer}.
     */
    function _transfer(address sender, address recipient, uint256 amount)
    _distribute(sender) _distribute(recipient)
    internal virtual override {
        if (recipient == address(this)) {
            totalDividends += amount;
        }
        super._transfer(sender, recipient, amount);
        if (rewardsExcluded[sender] && !rewardsExcluded[recipient]) {
            rewardsIncludedSupply += amount;
        } else if (!rewardsExcluded[sender] && rewardsExcluded[recipient]) {
            rewardsIncludedSupply -= amount;
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return ERC20.balanceOf(account) + _calcRewards(account);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import {PeripheryPayments} from "./pocketswap/abstract/PeripheryPayments.sol";
import {PeripheryImmutableState} from "./pocketswap/abstract/PeripheryImmutableState.sol";

import {IPocketSwapFactory} from "./pocketswap/interfaces/IPocketSwapFactory.sol";
import {IPocketSwapLiquidityRouter} from "./pocketswap/interfaces/IPocketSwapLiquidityRouter.sol";
import {IPocketSwapRouter} from "./pocketswap/interfaces/IPocketSwapRouter.sol";

import {PairAddress} from "./pocketswap/libraries/PairAddress.sol";

import {Pocket} from "./Pocket.sol";


contract PocketSwap is PeripheryImmutableState, PeripheryPayments {
    struct PocketSwapInitializeParams {
        address router;
        address factory;
        address pocket;
        address WETH9;
    }

    address public _owner;
    address public router;

    modifier onlyOwner() {
        if (msg.sender == _owner) _;
    }

    constructor(address router_, address factory_, address pocket_, address WETH9_)
    PeripheryImmutableState(factory_, WETH9_, pocket_) {
        _owner = msg.sender;
        router = router_;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function swap(IPocketSwapRouter.SwapParams calldata params)
    payable external {
        pay(params.tokenIn, msg.sender, address(this), params.amountIn);
        approve(params.tokenIn, router, params.amountIn);
        try IPocketSwapRouter(router).swap(params) {}
        catch Error(string memory reason) {
            revert(string(abi.encodePacked("NOK: ", reason)));
        }
    }

    function addLiquidity(IPocketSwapLiquidityRouter.AddLiquidityParams calldata params)
    payable external {
        // create the pair if it doesn't exist yet
        if (IPocketSwapFactory(factory).getPair(params.token0, params.token1) == address(0)) {
            IPocketSwapFactory(factory).createPair(params.token0, params.token1);
        }

        (uint amountA, uint amountB) = IPocketSwapLiquidityRouter(router).calcLiquidity(params);

        // sending tokens to router
        pay(params.token0, msg.sender, address(this), amountA);
        approve(params.token0, router, amountA);
        pay(params.token1, msg.sender, address(this), amountB);
        approve(params.token1, router, amountB);

        try IPocketSwapLiquidityRouter(router).addLiquidity(params) {}
        catch Error(string memory reason) {
            revert(string(abi.encodePacked("NOK: ", reason)));
        }
    }

    function removeLiquidity(IPocketSwapLiquidityRouter.RemoveLiquidityParams calldata params) external {
        // sending LP to router
        address pair = PairAddress.computeAddress(factory, params.tokenA, params.tokenB);
        pay(pair, msg.sender, address(this), params.liquidity);
        approve(pair, router, params.liquidity);

        try IPocketSwapLiquidityRouter(router).removeLiquidity(params) {}
        catch Error(string memory reason) {
            revert(string(abi.encodePacked("NOK: ", reason)));
        }
    }

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory) {
        return IPocketSwapRouter(router).getAmountsIn(amountOut, path);
    }

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory) {
        return IPocketSwapRouter(router).getAmountsOut(amountIn, path);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import '../interfaces/IPeripheryImmutableState.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override pocket;

    constructor(address _factory, address _WETH9, address _pocketToken) {
        factory = _factory;
        WETH9 = _WETH9;
        pocket = _pocketToken;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IPeripheryPayments.sol';
import '../interfaces/external/IWETH9.sol';

import '../libraries/TransferHelper.sol';

import './PeripheryImmutableState.sol';

abstract contract PeripheryPayments is IPeripheryPayments, PeripheryImmutableState {
    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        if (amountMinimum > 0) require(balanceWETH9 >= amountMinimum, 'Insufficient WETH9');

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        if (amountMinimum > 0) require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) TransferHelper.safeTransfer(token, recipient, balanceToken);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        uint256 selfBalance;
        if (token == WETH9 && (selfBalance = address(this).balance) >= value) {
            // pay with WETH9 generated from ETH
            IWETH9(WETH9).deposit{value : selfBalance}();
            // wrap whole balance
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }

    /// @param token The contract address of the token to be approved
    /// @param recipient The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function approve(
        address token,
        address recipient,
        uint256 value
    ) internal {
        // pull payment
        TransferHelper.safeApprove(token, recipient, value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the PocketSwap factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);

    /// @return Returns the address of POCKET token
    function pocket() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Sends the full amount of a token held by this contract to the given recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

interface IPocket {
    function addRewards(uint256 amount) external returns (bool);
    function rewardsExcluded(address) external view returns(bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.0;

interface IPocketSwapERC20 {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

interface IPocketSwapFactory {
    function fee() external view returns (uint256);

    function holdersFee() external view returns (uint256);

    function setFee(uint256) external;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeSetter(address) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

interface IPocketSwapLiquidityRouter {
    struct AddLiquidityParams {
        address token0; // Address of the First token in Pair
        address token1; // Address of the Second token in Pair
        address recipient; // address which will receive LP tokens
        uint256 amount0Desired; // Amount of the First token in Pair
        uint256 amount1Desired;// Amount of the Second token in Pair
        uint256 amount0Min; // mininum amount of the first token in pair
        uint256 amount1Min;// mininum amount of the second token in pair
        uint256 deadline; // reverts in case of transaction confirmed too late
    }

    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB, uint amountPocket, uint liquidity);

    function calcLiquidity(AddLiquidityParams calldata params) external view
    returns (uint amountA, uint amountB);

    struct RemoveLiquidityParams {
        address tokenA; // Address of the First token in Pair
        address tokenB; // Address of the Second token in Pair
        uint liquidity; // Amount of the LP tokens you want to remove
        uint amountAMin; // Minimum amount you're expecting to receive of the First token
        uint amountBMin;// Minimum amount you're expecting to receive of the Second token
        address rewards; // Address of the rewards token (USDT, WETH, POCKET)
        address recipient; // Address which will receive tokens and rewards
        uint deadline;// Reverts in case of transaction confirmed too late
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.0;

import "./IPocketSwapERC20.sol";

interface IPocketSwapPair is IPocketSwapERC20 {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import './callback/IPocketSwapCallback.sol';
import "./IPocketSwapPair.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IPocketSwapRouter is IPocketSwapCallback {
    function pairFor(
        address tokenA,
        address tokenB
    ) external view returns (IPocketSwapPair);

    struct SwapParams {
        address tokenIn; // Address of the token you're sending for a SWAP
        address tokenOut; // Address of the token you're going to receive
        address recipient; // Address which will receive tokenOut
        uint256 deadline; // will revert if transaction was confirmed too late
        uint256 amountIn; // amount of the tokenIn to be swapped
        uint256 amountOutMinimum; // minimum amount you're expecting to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `SwapParams` in calldata
    /// @return amountOut The amount of the received token
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut);

    struct SwapMultiParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `SwapMultiParams` in calldata
    /// @return amountOut The amount of the received token
    function swapMulti(SwapMultiParams calldata params) external payable returns (uint256 amountOut);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls TokenSwapActions#swap must implement this interface
interface IPocketSwapCallback {
    function pocketSwapCallback(
        uint256 amount0Delta,
        uint256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pair address from the factory, tokens, and the fee
library PairAddress {
    bytes32 internal constant PAIR_INIT_CODE_HASH = 0x6f9413fb6ab391fdd0608a5ec0dfb5ca95f899db515c4f3a6cacd1562e09392e;

    /// @notice Deterministically computes the pair address given the factory and PairKey
    /// @param factory The PocketSwap factory contract address
    /// @param tokenA The first token of a pair, unsorted
    /// @param tokenB The second token of a pair, unsorted
    /// @return pair The contract address of the pair
    function computeAddress(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            PAIR_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}