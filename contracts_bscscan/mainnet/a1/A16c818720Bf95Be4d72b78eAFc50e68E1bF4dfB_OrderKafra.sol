// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IProntera.sol";
import "./interfaces/IOrderFeeKafra.sol";
import "./interfaces/IIzludeV2.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract OrderKafra is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    IWETH public constant WETH = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    IProntera public immutable prontera;
    IERC20 public immutable ksw;
    uint256 public eligibleAmount;
    address public worker;

    enum OrderType {
        SWAP,
        REMOVE_LIQUIDITY
    }

    enum OrderStatus {
        PENDING,
        MATCHED,
        CANCELED
    }

    struct OrderItem {
        OrderType orderType;
        OrderStatus status;
        uint40 tpValue;
        uint40 slValue;
        address owner;
        // ------
        address izlude;
        // ------
        uint256 jellopy;
        // ------
        uint128 gasValue;
        uint32 gasPrice;
        uint96 tip;
        // -----
        address receiveToken;
        // -----
        uint256[] amountOutMins;
    }

    uint256 public totalOrder;
    mapping(uint256 => OrderItem) public orders;

    // management
    mapping(address => bool) public allowReceiveToken;
    mapping(address => bool) public allowIzlude;

    // Juno transportation
    address public juno;

    uint256 public leftoverGas;

    event Created(uint256 indexed id, address indexed owner);
    event Canceled(uint256 indexed id);
    event EmergencyCanceled(uint256 indexed id);
    event UpdateOrderGas(uint256 indexed id, uint32 gasPrice, uint128 gasValue);

    event Matched(uint256 indexed id, address indexed executor, uint40 matchedPrice);

    event SetAllowReceiveToken(address token, bool allow);
    event SetAllowIzlude(address izlude, bool allow);
    event SetJuno(address juno);
    event SetEligibleAmount(uint256 amount);
    event SetWorker(address worker);
    event WithdrawLeftoverGas(uint256 amount);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "OrderKafra: EXPIRED");
        _;
    }

    constructor(
        IProntera _prontera,
        address _ksw,
        address _worker,
        address _juno
    ) {
        prontera = _prontera;
        ksw = IERC20(_ksw);
        worker = _worker;
        juno = _juno;
    }

    modifier onlyWorker() {
        require(msg.sender == worker, "!worker");
        _;
    }

    struct createOrderParam {
        OrderType orderType;
        uint40 tpValue;
        uint40 slValue;
        address izlude;
        // ------
        uint256 jellopy;
        // ------
        uint128 gasValue;
        uint32 gasPrice;
        uint96 tip;
        // -----
        address receiveToken;
        // -----
        uint256[] amountOutMins;
    }

    function createOrder(createOrderParam calldata req)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 orderId)
    {
        require(req.jellopy > 0, "jellopy is zero");
        require(req.tpValue > 0 || req.slValue > 0, "tp or sl value required");
        if (req.orderType == OrderType.SWAP) {
            require(allowReceiveToken[req.receiveToken], "receive token not supported");
        }
        require(allowIzlude[req.izlude], "pool not supported");
        require(req.gasValue + req.tip == msg.value, "invalid value");
        require(isAccountEligible(msg.sender), "account is not eligible");

        prontera.storeKeepJellopy(msg.sender, req.izlude, req.jellopy);

        orderId = totalOrder++;
        OrderItem storage order = orders[orderId];
        order.orderType = req.orderType;
        // order.status = OrderStatus.PENDING;
        order.owner = msg.sender;
        order.izlude = req.izlude;
        order.jellopy = req.jellopy;
        order.tpValue = req.tpValue;
        order.slValue = req.slValue;
        order.gasValue = req.gasValue;
        order.gasPrice = req.gasPrice;
        order.tip = req.tip;
        order.receiveToken = req.receiveToken;
        order.amountOutMins = req.amountOutMins;
        emit Created(orderId, msg.sender);
    }

    function updateOrderGas(uint256 orderId, uint32 gasPrice) external payable nonReentrant {
        OrderItem storage order = orders[orderId];
        require(order.owner == msg.sender, "!owner");
        require(order.status == OrderStatus.PENDING, "!pending");

        if (order.gasValue > 0) {
            payable(order.owner).transfer(order.gasValue);
        }

        order.gasPrice = gasPrice;
        order.gasValue = uint128(msg.value);
        emit UpdateOrderGas(orderId, gasPrice, uint128(msg.value));
    }

    function cancelOrder(uint256 orderId) external nonReentrant {
        OrderItem storage order = orders[orderId];
        require(order.owner == msg.sender || owner() == msg.sender, "!owner"); // let admin cancel when order has problem
        require(order.status == OrderStatus.PENDING, "!pending");

        order.status = OrderStatus.CANCELED;
        prontera.storeReturnJellopy(order.owner, order.izlude, order.jellopy);

        uint256 returnEther = order.gasValue + order.tip;
        if (returnEther > 0) {
            payable(order.owner).transfer(returnEther);
        }
        emit Canceled(orderId);
    }

    function emergencyCancelOrder(uint256 orderId) external nonReentrant {
        OrderItem storage order = orders[orderId];
        require(order.owner == msg.sender, "!owner");
        require(order.status == OrderStatus.PENDING, "!pending");

        order.status = OrderStatus.CANCELED;
        prontera.storeReturnJellopy(order.owner, order.izlude, order.jellopy);

        leftoverGas += order.gasValue;
        leftoverGas += order.tip;
        emit EmergencyCanceled(orderId);
    }

    function userDeposited(uint256 orderId) public view returns (uint256) {
        OrderItem storage order = orders[orderId];
        return (IIzludeV2(order.izlude).balance() * order.jellopy) / IIzludeV2(order.izlude).totalSupply();
    }

    function getOrders(uint256[] calldata orderIds) external view returns (OrderItem[] memory) {
        OrderItem[] memory os = new OrderItem[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            os[i] = orders[orderIds[i]];
        }
        return os;
    }

    function executeOrder(
        uint256 orderId,
        uint40 matchedPrice,
        uint8 side, // 0 = tp, 1 = sl
        uint256[] calldata workerAmountOutMins,
        uint256 deadline,
        bytes calldata data
    ) external ensure(deadline) onlyWorker {
        OrderItem storage order = orders[orderId];
        require(order.status == OrderStatus.PENDING, "!pending");

        order.status = OrderStatus.MATCHED;

        // withdraw
        uint256 wantAmountOut;
        IERC20 want = IERC20(prontera.poolInfo(order.izlude).want);
        {
            uint256 wantBefore = want.balanceOf(address(this));
            prontera.storeWithdraw(order.owner, order.izlude, order.jellopy);
            uint256 wantAfter = want.balanceOf(address(this));
            wantAmountOut = wantAfter - wantBefore;
            require(wantAmountOut > 0, "!out");
        }

        if (order.orderType == OrderType.SWAP) {
            _withdrawToken(order, want, wantAmountOut, order.amountOutMins[side], workerAmountOutMins[0], data);
        } else if (order.orderType == OrderType.REMOVE_LIQUIDITY) {
            _removeLiquidity(
                order,
                removeLiquidityParam({
                    want: want,
                    amountIn: wantAmountOut,
                    amountOutMin0: order.amountOutMins[side * 2],
                    amountOutMin1: order.amountOutMins[(side * 2) + 1],
                    workerAmountOutMin0: workerAmountOutMins[0],
                    workerAmountOutMin1: workerAmountOutMins[1],
                    data: data
                })
            );
        } else {
            revert("unreachable");
        }

        payable(msg.sender).sendValue(order.gasValue + order.tip);
        emit Matched(orderId, msg.sender, matchedPrice);
    }

    function _withdrawToken(
        OrderItem storage order,
        IERC20 want,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 workerAmountOutMin,
        bytes calldata data
    ) private {
        IERC20 token = IERC20(order.receiveToken);
        uint256 amountOut;

        // convert want to token
        if (want != token) {
            uint256 tokenBeforeBal = token.balanceOf(address(this));
            want.safeTransfer(juno, amountIn);
            juno.functionCall(data, "juno: failed");
            uint256 tokenAfterBal = token.balanceOf(address(this));
            amountOut = tokenAfterBal - tokenBeforeBal;
            require(amountOut >= amountOutMin, "insufficient output amount");
            require(amountOut >= workerAmountOutMin, "worker: insufficient output amount");
        }

        _unwrapAndTransfer(token, order.owner, amountOut);
    }

    struct removeLiquidityParam {
        IERC20 want;
        uint256 amountIn;
        uint256 amountOutMin0;
        uint256 amountOutMin1;
        uint256 workerAmountOutMin0;
        uint256 workerAmountOutMin1;
        bytes data;
    }

    function _removeLiquidity(OrderItem storage order, removeLiquidityParam memory p) private {
        IUniswapV2Pair pair = IUniswapV2Pair(address(p.want));
        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());

        uint256 token0BalBefore = token0.balanceOf(address(this));
        uint256 token1BalBefore = token1.balanceOf(address(this));

        p.want.safeTransfer(juno, p.amountIn);
        juno.functionCall(p.data, "juno: failed");

        uint256 token0BalAfter = token0.balanceOf(address(this));
        uint256 token1BalAfter = token1.balanceOf(address(this));
        uint256 amountOut0 = token0BalAfter - token0BalBefore;
        uint256 amountOut1 = token1BalAfter - token1BalBefore;

        require(amountOut0 >= p.amountOutMin0, "insufficient output amount 0");
        require(amountOut1 >= p.amountOutMin1, "insufficient output amount 1");
        require(amountOut0 >= p.workerAmountOutMin0, "worker: insufficient output amount 0");
        require(amountOut1 >= p.workerAmountOutMin1, "worker: insufficient output amount 1");

        _unwrapAndTransfer(token0, order.owner, amountOut0);
        _unwrapAndTransfer(token1, order.owner, amountOut1);
    }

    function _unwrapAndTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) private {
        if (token == WETH) {
            WETH.withdraw(amount);
            payable(to).sendValue(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function isAccountEligible(address account) public view returns (bool) {
        uint256 holdingAmount = ksw.balanceOf(account);
        return holdingAmount >= eligibleAmount;
    }

    // onlyOwner functions
    function setAllowReceiveToken(address token, bool allow) external onlyOwner {
        allowReceiveToken[token] = allow;
        emit SetAllowReceiveToken(token, allow);
    }

    function setAllowIzlude(address izlude, bool allow) external onlyOwner {
        allowIzlude[izlude] = allow;
        emit SetAllowIzlude(izlude, allow);
    }

    function setEligibleAmount(uint256 amount) external onlyOwner {
        eligibleAmount = amount;
        emit SetEligibleAmount(amount);
    }

    function setJuno(address _juno) external onlyOwner {
        juno = _juno;
        emit SetJuno(_juno);
    }

    function setWorker(address _worker) external onlyOwner {
        worker = _worker;
        emit SetWorker(_worker);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawLeftoverGas() external onlyOwner nonReentrant {
        require(leftoverGas > 0, "no left gas");
        payable(msg.sender).transfer(leftoverGas);
        emit WithdrawLeftoverGas(leftoverGas);
        leftoverGas = 0;
    }

    receive() external payable {
        require(msg.sender == address(WETH), "reject");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProntera {
    struct UserInfo {
        uint256 jellopy;
        uint256 rewardDebt;
        uint256 storedJellopy;
    }

    function userInfo(address npc, address user) external view returns (UserInfo memory);

    struct PoolInfo {
        address want;
        address izlude;
        uint256 accKSWPerJellopy;
        uint64 allocPoint;
        uint64 lastRewardTime;
    }

    function poolInfo(address izlude) external view returns (PoolInfo memory);

    function pendingKSW(address izlude, address _user) external view returns (uint256);

    function deposit(address izlude, uint256 amount) external;

    function depositFor(
        address user,
        address izlude,
        uint256 amount
    ) external;

    function withdraw(address izlude, uint256 jellopyAmount) external;

    function emergencyWithdraw(address izlude) external;

    function storeWithdraw(
        address _user,
        address izlude,
        uint256 jellopyAmount
    ) external;

    function storeKeepJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external;

    function storeReturnJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external;

    function juno() external returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOrderFeeKafra {
    function TOTAL_FEE() external view returns (uint256);

    function fee() external view returns (uint256);

    function treasuryFee() external view returns (uint256);

    function kswFee() external view returns (uint256);

    function executorFee() external view returns (uint256);

    function calculateFee(uint256 wantAmount) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IByalan.sol";

interface IIzludeV2 {
    function totalSupply() external view returns (uint256);

    function prontera() external view returns (address);

    function want() external view returns (IERC20);

    function deposit(address user, uint256 amount) external returns (uint256 jellopy);

    function withdraw(address user, uint256 jellopy) external returns (uint256);

    function balance() external view returns (uint256);

    function byalan() external view returns (IByalan);

    function feeKafra() external view returns (address);

    function allocKafra() external view returns (address);

    function calculateWithdrawFee(uint256 amount, address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IByalanIsland.sol";
import "./ISailor.sol";

interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function balanceOfMasterChef() external view returns (uint256);

    function pendingRewardTokens() external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts);

    function harvest() external;

    function retireStrategy() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IByalanIsland {
    function izlude() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISailor {
    function MAX_FEE() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function callFee() external view returns (uint256);

    function kswFee() external view returns (uint256);
}