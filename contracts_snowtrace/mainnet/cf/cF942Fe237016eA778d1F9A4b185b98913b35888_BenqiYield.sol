// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IYieldAdapter.sol";
import "../interfaces/benqi/IQiErc20.sol";
import "../interfaces/benqi/IComptroller.sol";
import "../interfaces/dex/IAvaxDexRouter.sol";
import {IWETH as IWAVAX} from "../interfaces/IWETH.sol";

/**
 * @title Benqi Yield contract
 * @notice Implements the functions to deposit/withdraw into Benqi
 * @author Symphony Finance
 **/
contract BenqiYield is IYieldAdapter {
    using SafeERC20 for IERC20;

    address public immutable yolo;
    address public manager;
    address internal immutable tokenAddress;

    // Address related to Benqi
    IQiErc20 public immutable qiAsset;
    IComptroller public immutable comptroller;

    // reward relater to reward
    uint8 public constant REWARD_QI = 0;
    uint8 public constant REWARD_AVAX = 1;
    address public immutable wavax;
    address public immutable qiToken;

    // Addresses related to swap
    address[] qiSwapRoute;
    address[] wavaxSwapRoute;
    IAvaxDexRouter public router;
    IAvaxDexRouter public backupRouter;
    uint256 public harvestMaxGas = 1600000; // 1600k wei

    modifier onlyYolo() {
        require(
            msg.sender == yolo,
            "BenqiYield: only yolo contract can invoke this function"
        );
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "BenqiYield: only manager can invoke this function"
        );
        _;
    }

    /**
     * @dev To initialize the contract addresses interacting with this contract
     **/
    constructor(
        address _yolo,
        address _manager,
        address _tokenAddress,
        IQiErc20 _qiAsset,
        IComptroller _comptroller,
        address _wavax
    ) {
        require(_yolo != address(0), "yolo:: zero address");
        require(_manager != address(0), "manager:: zero address");
        require(
            address(_comptroller) != address(0),
            "comptroller:: zero address"
        );
        yolo = _yolo;
        manager = _manager;
        comptroller = _comptroller;
        tokenAddress = _tokenAddress;
        qiToken = comptroller.qiAddress();
        wavax = _wavax;

        require(
            _qiAsset.underlying() == _tokenAddress,
            "incorrect qiAsset address"
        );
        qiAsset = _qiAsset;
        _maxApprove(_tokenAddress, address(_qiAsset));
    }

    /**
     * @dev Used to deposit tokens
     **/
    function deposit(address, uint256 amount) external override onlyYolo {
        _depositERC20(amount);
    }

    /**
     * @dev Used to withdraw tokens
     **/
    function withdraw(address, uint256 amount) external override onlyYolo {
        _withdrawERC20(amount);
    }

    /**
     * @dev Withdraw all tokens from the strategy
     **/
    function withdrawAll(address) external override onlyYolo {
        uint256 amount = qiAsset.balanceOf(address(this));
        if (amount > 0) {
            _withdrawERC20(amount);
        }
    }

    /**
     * @dev Used to claim reward and do auto compound
     **/
    function harvestReward() external returns (uint256 tokenBal) {
        address _wavax = wavax;
        address _qiToken = qiToken;
        address _tokenAddress = tokenAddress;

        comptroller.claimReward(REWARD_QI, payable(address(this)));
        uint256 qiBalance = IQiErc20(_qiToken).balanceOf(address(this));
        if (qiBalance > 0) {
            _swapQi(qiBalance);
        }

        comptroller.claimReward(REWARD_AVAX, payable(address(this)));
        uint256 avaxBalance = address(this).balance;

        // reimburse function caller
        uint256 reimbursementAmt = harvestMaxGas * tx.gasprice;
        if (avaxBalance > reimbursementAmt) {
            avaxBalance -= reimbursementAmt;
            _safeTransferAvax(msg.sender, reimbursementAmt);
        }

        IWAVAX(_wavax).deposit{value: avaxBalance}();

        if (avaxBalance > 0) {
            if (_tokenAddress != _wavax) {
                _swapWavax(avaxBalance);
            }
        }

        tokenBal = IERC20(_tokenAddress).balanceOf(address(this));
        if (tokenBal > 0) {
            _depositERC20(tokenBal);
        }
    }

    // *************** //
    // *** GETTERS *** //
    // *************** //

    /**
     * @dev Used to get amount of underlying tokens
     * @return amount amount of underlying tokens
     **/
    function getTotalUnderlying(address)
        public
        override
        returns (uint256 amount)
    {
        amount = qiAsset.balanceOfUnderlying(address(this));
    }

    /**
     * @dev Used to get IOU token address
     **/
    function getIouTokenAddress(address)
        public
        view
        override
        returns (address iouToken)
    {
        iouToken = address(qiAsset);
    }

    // ************************** //
    // *** MANAGER METHODS *** //
    // ************************** //

    function updateManager(address _manager) external onlyManager {
        require(
            _manager != address(0),
            "BenqiYield::updateManager: zero address"
        );
        manager = _manager;
    }

    function updateRouter(IAvaxDexRouter _router) external onlyManager {
        require(
            address(_router) != address(0),
            "BenqiYield::updateRouter: zero address"
        );
        address _wavax = wavax;
        address _qiToken = qiToken;
        address previousRouterAddr = address(router);
        if (previousRouterAddr != address(0)) {
            IERC20(_wavax).approve(previousRouterAddr, 0);
            IERC20(_qiToken).approve(previousRouterAddr, 0);
        }
        router = _router;
        if (address(_router) != address(0)) {
            IERC20(_wavax).approve(address(_router), type(uint256).max);
            IERC20(_qiToken).approve(address(_router), type(uint256).max);
        }
    }

    function updateBackupRouter(IAvaxDexRouter _router) external onlyManager {
        require(
            address(_router) != address(0),
            "BenqiYield::updateBackupRouter: zero address"
        );
        address _wavax = wavax;
        address _qiToken = qiToken;
        address previousRouterAddr = address(backupRouter);
        if (previousRouterAddr != address(0)) {
            IERC20(_wavax).approve(previousRouterAddr, 0);
            IERC20(_qiToken).approve(previousRouterAddr, 0);
        }
        backupRouter = _router;
        if (address(_router) != address(0)) {
            IERC20(_wavax).approve(address(_router), type(uint256).max);
            IERC20(_qiToken).approve(address(_router), type(uint256).max);
        }
    }

    function updateWavaxRoute(address[] memory _route) external onlyManager {
        require(
            _route[0] == wavax && _route[_route.length - 1] == tokenAddress,
            "BenqiYield::updateRoute: incorrect route"
        );
        wavaxSwapRoute = _route;
    }

    function updateQiRoute(address[] memory _route) external onlyManager {
        require(
            _route[0] == qiToken && _route[_route.length - 1] == wavax,
            "BenqiYield::updateRoute: incorrect route"
        );
        qiSwapRoute = _route;
    }

    function updateHarvestGas(uint256 _gas) external onlyManager {
        harvestMaxGas = _gas;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    function _depositERC20(uint256 _amount) internal {
        uint256 mintResult = IQiErc20(qiAsset).mint(_amount);
        require(
            mintResult == 0,
            "BenqiYield:: error calling mint on Benqi token: error code not equal to 0."
        );
    }

    function _withdrawERC20(uint256 _amount) internal {
        uint256 redeemResult = IQiErc20(qiAsset).redeemUnderlying(_amount);
        require(
            redeemResult == 0,
            "BenqiYield:: error calling redeemUnderlying on Benqi token: error code not equal to 0."
        );
        IERC20(tokenAddress).safeTransfer(yolo, _amount);
    }

    function _maxApprove(address _token, address _qiAsset) internal {
        IERC20(_token).safeApprove(_qiAsset, type(uint256).max);
    }

    function _swapWavax(uint256 _amount) internal {
        address[] memory _wavaxSwapRoute = wavaxSwapRoute;
        try
            router.swapExactTokensForTokens(
                _amount,
                0,
                _wavaxSwapRoute,
                address(this),
                block.timestamp
            )
        {} catch {
            backupRouter.swapExactTokensForTokens(
                _amount,
                0,
                _wavaxSwapRoute,
                address(this),
                block.timestamp
            );
        }
    }

    function _swapQi(uint256 _amount) internal {
        address[] memory _qiSwapRoute = qiSwapRoute;
        try
            router.swapExactTokensForAVAX(
                _amount,
                0,
                _qiSwapRoute,
                address(this),
                block.timestamp
            )
        {} catch {
            backupRouter.swapExactTokensForAVAX(
                _amount,
                0,
                _qiSwapRoute,
                address(this),
                block.timestamp
            );
        }
    }

    function _safeTransferAvax(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "AVAX_TRANSFER_FAILED");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IYieldAdapter {
    /**
     * @dev Used to deposit token
     * @param asset the address of token to invest
     * @param amount the amount of asset
     **/
    function deposit(address asset, uint256 amount) external;

    /**
     * @dev Used to withdraw from available protocol
     * @param asset the address of underlying token
     * @param amount the amount of liquidity shares to unlock
     **/
    function withdraw(address asset, uint256 amount) external;

    /**
     * @dev Withdraw all tokens from the strategy
     * @param asset the address of token
     **/
    function withdrawAll(address asset) external;

    /**
     * @dev Used to get amount of underlying tokens
     * @param asset the address of token
     * @return tokensAmount amount of underlying tokens
     **/
    function getTotalUnderlying(address asset)
        external
        returns (uint256 tokensAmount);

    /**
     * @dev Used to get IOU token address
     * @param asset the address of token
     * @return iouToken address of IOU token
     **/
    function getIouTokenAddress(address asset)
        external
        view
        returns (address iouToken);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @title Benqi's Erc20 Interface
 * @notice QiTokens which wrap an EIP-20 underlying
 */
interface IQiErc20 {
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IComptroller {
    /**
     * @notice Claim all the benqi accrued by holder in all markets
     * @param rewardType  0: Qi, 1: Avax
     * @param holder The address to claim BENQI for
     */
    function claimReward(uint8 rewardType, address payable holder) external;

    function getBlockTimestamp() external view returns (uint256);

    function qiAddress() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IAvaxDexRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
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

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
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

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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