// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDCACore} from "./interfaces/IDCACore.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {IWETH} from "./external/IWETH.sol";

contract DCACore is IDCACore, Ownable {
    using SafeERC20 for IERC20;

    Position[] public positions;
    IUniswapV2Router public uniRouter;
    address public executor;

    bool public paused;
    mapping(address => mapping(address => bool)) public allowedTokenPairs;
    uint256 public minSlippage = 25; // 0.25%

    address public constant ETH_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable weth;

    modifier onlyExecutor() {
        require(msg.sender == executor, "Only Executor");
        _;
    }

    modifier notPaused() {
        require(!paused, "System is paused");
        _;
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks

    constructor(
        address _uniRouter,
        address _executor,
        address _weth
    ) {
        uniRouter = IUniswapV2Router(_uniRouter);
        executor = _executor;
        weth = _weth;
        paused = false;
    }

    function createPositionAndDeposit(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountDCA,
        uint256 _intervalDCA,
        uint256 _maxSlippage
    ) external payable notPaused {
        uint256 amountIn;
        address tokenIn;
        if (_tokenIn == ETH_TOKEN) {
            tokenIn = weth;
            IWETH(weth).deposit{value: msg.value}();
            amountIn = msg.value;
        } else {
            tokenIn = _tokenIn;
            IERC20(_tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            amountIn = _amountIn;
        }

        require(allowedTokenPairs[tokenIn][_tokenOut], "Pair not allowed");
        require(
            amountIn > 0 &&
                _amountDCA > 0 &&
                _intervalDCA >= 60 &&
                _maxSlippage >= minSlippage,
            "Invalid inputs"
        );
        require(amountIn >= _amountDCA, "Deposit for at least 1 DCA");

        Position memory position;
        position.id = positions.length;
        position.owner = msg.sender;
        position.tokenIn = tokenIn;
        position.tokenOut = _tokenOut;
        position.balanceIn = amountIn;
        position.amountDCA = _amountDCA;
        position.intervalDCA = _intervalDCA;
        position.maxSlippage = _maxSlippage;

        positions.push(position);

        emit PositionCreated(
            position.id,
            msg.sender,
            tokenIn,
            _tokenOut,
            _amountDCA,
            _intervalDCA,
            _maxSlippage
        );
        emit Deposit(position.id, amountIn);
    }

    function updatePosition(
        uint256 _positionId,
        uint256 _amountDCA,
        uint256 _intervalDCA
    ) external {
        require(_amountDCA > 0 && _intervalDCA >= 60, "Invalid inputs");
        Position storage position = positions[_positionId];
        require(msg.sender == position.owner, "Sender must be owner");
        position.amountDCA = _amountDCA;
        position.intervalDCA = _intervalDCA;

        emit PositionUpdated(_positionId, _amountDCA, _intervalDCA);
    }

    function deposit(uint256 _positionId, uint256 _amount) external notPaused {
        require(_amount > 0, "_amount must be > 0");
        Position storage position = positions[_positionId];
        require(msg.sender == position.owner, "Sender must be owner");

        position.balanceIn = position.balanceIn + _amount;

        IERC20(position.tokenIn).safeTransferFrom(
            position.owner,
            address(this),
            _amount
        );

        emit Deposit(_positionId, _amount);
    }

    function depositETH(uint256 _positionId) external payable notPaused {
        require(msg.value > 0, "msg.value must be > 0");
        IWETH(weth).deposit{value: msg.value}();

        Position storage position = positions[_positionId];
        require(msg.sender == position.owner, "Sender must be owner");
        require(position.tokenIn == weth, "tokenIn must be WETH");

        position.balanceIn = position.balanceIn + msg.value;

        emit Deposit(_positionId, msg.value);
    }

    function withdrawTokenIn(uint256 _positionId, uint256 _amount) public {
        require(_amount > 0, "_amount must be > 0");
        Position storage position = positions[_positionId];
        require(msg.sender == position.owner, "Sender must be owner");

        position.balanceIn = position.balanceIn - _amount;
        _transfer(payable(position.owner), position.tokenIn, _amount);

        emit WithdrawTokenIn(_positionId, _amount);
    }

    function withdrawTokenOut(uint256 _positionId) public {
        Position storage position = positions[_positionId];
        require(msg.sender == position.owner, "Sender must be owner");
        require(position.balanceOut > 0, "DCA asset amount must be > 0");

        uint256 withdrawable = position.balanceOut;
        position.balanceOut = 0;
        _transfer(payable(position.owner), position.tokenOut, withdrawable);

        emit WithdrawTokenOut(_positionId, withdrawable);
    }

    function exit(uint256 _positionId) public {
        Position storage position = positions[_positionId];
        require(msg.sender == position.owner, "Sender must be owner");

        if (position.balanceIn > 0) {
            uint256 withdrawableTokenIn = position.balanceIn;
            position.balanceIn = 0;

            _transfer(
                payable(position.owner),
                position.tokenIn,
                withdrawableTokenIn
            );
            emit WithdrawTokenIn(_positionId, withdrawableTokenIn);
        }

        if (position.balanceOut > 0) {
            uint256 withdrawableTokenOut = position.balanceOut;
            position.balanceOut = 0;

            _transfer(
                payable(position.owner),
                position.tokenOut,
                withdrawableTokenOut
            );
            emit WithdrawTokenOut(_positionId, withdrawableTokenOut);
        }
    }

    function executeDCA(uint256 _positionId, DCAExtraData calldata _extraData)
        public
        override
        onlyExecutor
        notPaused
    {
        Position storage position = positions[_positionId];

        (bool ready, string memory notReadyReason) = _checkReadyDCA(position);
        if (!ready) revert(notReadyReason);

        require(
            position.tokenIn == _extraData.swapPath[0] &&
                position.tokenOut ==
                _extraData.swapPath[_extraData.swapPath.length - 1],
            "Invalid swap path"
        );

        position.lastDCA = block.timestamp; // solhint-disable-line not-rely-on-time
        position.balanceIn = position.balanceIn - position.amountDCA;

        IERC20(position.tokenIn).approve(
            address(uniRouter),
            position.amountDCA
        );

        uint256 amountOutMin = _extraData.swapAmountOutMin -
            ((_extraData.swapAmountOutMin * position.maxSlippage) / 10_000);
        uint256[] memory amounts = _swap(
            position.amountDCA,
            amountOutMin,
            _extraData.swapPath
        );
        position.balanceOut = position.balanceOut + amounts[amounts.length - 1];

        emit ExecuteDCA(_positionId);
    }

    // 1. multiple DCAs over the same pair could cause unexpected slippage
    // 2. unbounded loop could cause gas limit revert
    function executeDCAs(
        uint256[] calldata _positionIds,
        DCAExtraData[] calldata _extraDatas
    ) public override {
        require(
            _positionIds.length == _extraDatas.length,
            "Params lengths must be equal"
        );
        for (uint256 i = 0; i < _positionIds.length; i++) {
            executeDCA(_positionIds[i], _extraDatas[i]);
        }
    }

    function setAllowedTokenPair(
        address _tokenIn,
        address _tokenOut,
        bool _allowed
    ) external onlyOwner {
        require(_tokenIn != _tokenOut, "Duplicate tokens");
        require(
            allowedTokenPairs[_tokenIn][_tokenOut] != _allowed,
            "Same _allowed value"
        );
        allowedTokenPairs[_tokenIn][_tokenOut] = _allowed;

        emit AllowedTokenPairSet(_tokenIn, _tokenOut, _allowed);
    }

    function setMinSlippage(uint256 _minSlippage) external onlyOwner {
        require(minSlippage != _minSlippage, "Same slippage value");
        require(_minSlippage <= 1000, "Min slippage too large"); // sanity check max slippage under 10%
        minSlippage = _minSlippage;

        emit MinSlippageSet(_minSlippage);
    }

    function setSystemPause(bool _paused) external onlyOwner {
        require(paused != _paused, "Same _paused value");
        paused = _paused;

        emit PausedSet(_paused);
    }

    function _checkReadyDCA(Position memory _position)
        internal
        view
        returns (bool, string memory)
    {
        /* solhint-disable-next-line not-rely-on-time */
        if ((_position.lastDCA + _position.intervalDCA) > block.timestamp) {
            return (false, "Not time to DCA");
        }

        if (_position.balanceIn < _position.amountDCA) {
            return (false, "Insufficient fund");
        }
        if (!allowedTokenPairs[_position.tokenIn][_position.tokenOut]) {
            return (false, "Token pair not allowed");
        }
        return (true, "");
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) internal returns (uint256[] memory amounts) {
        return
            IUniswapV2Router(uniRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                _path,
                address(this),
                block.timestamp // solhint-disable-line not-rely-on-time,
            );
    }

    function _transfer(
        address payable _to,
        address _token,
        uint256 _amount
    ) internal {
        if (_token == weth) {
            IWETH(weth).withdraw(_amount);
            // solhint-disable-next-line avoid-low-level-calls,
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function getNextPositionId() external view returns (uint256) {
        return positions.length;
    }

    function getReadyPositionIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 activePositionsLength;
        for (uint256 i = 0; i < positions.length; i++) {
            (bool ready, ) = _checkReadyDCA(positions[i]);
            if (ready) activePositionsLength++;
        }

        uint256 counter;
        uint256[] memory positionIds = new uint256[](activePositionsLength);
        for (uint256 i = 0; i < positions.length; i++) {
            (bool ready, ) = _checkReadyDCA(positions[i]);
            if (ready) {
                positionIds[counter] = positions[i].id;
                counter++;
            }
        }
        return positionIds;
    }

    function getPositions(uint256[] calldata positionIds)
        external
        view
        override
        returns (Position[] memory)
    {
        Position[] memory selectedPositions = new Position[](
            positionIds.length
        );
        for (uint256 i = 0; i < positionIds.length; i++) {
            selectedPositions[i] = positions[positionIds[i]];
        }
        return selectedPositions;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
pragma solidity 0.8.0;

interface IDCACore {
    struct Position {
        uint256 id;
        address owner;
        address tokenIn;
        address tokenOut;
        uint256 balanceIn;
        uint256 balanceOut;
        uint256 amountDCA;
        uint256 intervalDCA;
        uint256 lastDCA; //timestamp
        uint256 maxSlippage;
    }

    struct DCAExtraData {
        // minimal swap output amount to prevent manipulation
        uint256 swapAmountOutMin;
        // swap path
        address[] swapPath;
    }

    event PositionCreated(
        uint256 indexed positionId,
        address indexed owner,
        address tokenIn,
        address tokenOut,
        uint256 amountDCA,
        uint256 intervalDCA,
        uint256 maxSlippage
    );
    event PositionUpdated(
        uint256 indexed positionId,
        uint256 indexed amountDCA,
        uint256 indexed intervalDCA
    );
    event Deposit(uint256 indexed positionId, uint256 indexed amount);
    event WithdrawTokenIn(uint256 indexed positionId, uint256 indexed amount);
    event WithdrawTokenOut(uint256 indexed positionId, uint256 indexed amount);
    event ExecuteDCA(uint256 indexed positionId);
    event AllowedTokenPairSet(
        address indexed tokenIn,
        address indexed tokenOut,
        bool indexed allowed
    );
    event MinSlippageSet(uint256 indexed minSlippage);
    event PausedSet(bool indexed paused);

    function executeDCA(uint256 _positionId, DCAExtraData calldata _extraData)
        external;

    function executeDCAs(
        uint256[] calldata _positionIds,
        DCAExtraData[] calldata _extraDatas
    ) external;

    function getReadyPositionIds() external view returns (uint256[] memory);

    function getPositions(uint256[] calldata positionIds)
        external
        view
        returns (Position[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

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