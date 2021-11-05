/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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



interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function mint(address to) external returns (uint256);
}

interface IFarm{
    function DINO() external view returns (address);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function leaveStaking(uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function poolInfo(uint256) external view returns(address lpToken, uint allocPoint, uint lastRewardBlock, uint accSpiritPerShare, uint16 depositFeeBP);

}

// This strategy is for polygon network. DINO - USDC pair
contract StrategyDINO is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public constant withdrawFee = 15; // 15%
    uint256 public constant toleranceLevelPercent = 1; // 1% 

    uint256 public pid = 10;
    uint256 public totalLP;
    uint256 public totalCapital;
    uint256 public pendingFee; // in native tokens

    address public vault;
    address public liquidityRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public lpToken = 0x3324af8417844e70b81555A6D1568d78f4D4Bf1f;
    address public farm = 0x1948abC5400Aa1d72223882958Da3bec643fb4E5;
    address public token0;
    address public token1;
    address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public WETH;
    address public yelLiquidityRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public YELtoken = 0xD3b71117E6C1558c1553305b44988cd944e97300;

    string public nameOfRewardToken = "DINO";

    mapping(address => uint256) private pendingYel;

    event AutoCompound();
    event Earn(uint256 amount);
    event YELswapped(uint256 percent);
    event WithdrawFromStrategy(uint256 amount);

    // constructor(address _vault) {
    constructor() {
        token0 = IPair(lpToken).token0();
        token1 = IPair(lpToken).token1();
        // vault = _vault;
        vault = 0xBd52B44c9Dc5Fc5c4F1f49feD5CFCA10fbd052f1;
        WETH = IRouter(liquidityRouter).WETH();

        IERC20(lpToken).safeApprove(farm, type(uint256).max);
        IERC20(WETH).safeApprove(liquidityRouter, type(uint256).max);

        IERC20(token0).safeApprove(liquidityRouter, 0);
        IERC20(token0).safeApprove(liquidityRouter, type(uint256).max);

        IERC20(token1).safeApprove(liquidityRouter, 0);
        IERC20(token1).safeApprove(liquidityRouter, type(uint256).max);
    }

    receive() external payable onlyVault {
        deposit();
    }

    modifier onlyVault() {
        require(msg.sender == vault, "The sender is not vault");
        _;
    }

    function getRewardToken() public view returns (address){
        return IFarm(farm).DINO();
    }

    function earn() public {
        IFarm(farm).deposit(pid, _getBalanceOfToken(lpToken));
        emit Earn(_getBalanceOfToken(lpToken));
    }  

    function getAvalaibleWETH() public view returns (uint256) {
        return _getBalanceOfToken(WETH) - pendingFee;
    }

    function takeFee() internal {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDT;
        uint256 _balanceWETH = getAvalaibleWETH();
        if(_balanceWETH > 0) {
            uint256 rewardsFeeInWETH = _calculateAmountFee(_balanceWETH);
            if(rewardsFeeInWETH > 0) {
                uint256 amount = _getAmountsOut(rewardsFeeInWETH, path);
                if(amount > 100) {
                    _swapExactTokensForTokens(liquidityRouter, rewardsFeeInWETH, amount, path);
                    pendingFee = 0;
                } else {
                    pendingFee += rewardsFeeInWETH;
                }
            }
        }
    }

    function _swapExactTokensForTokens(
        address _liquidityRouter,
        uint256 _amount,
        uint256 _amount2,
        address[] memory _path) internal {
        IRouter(_liquidityRouter).swapExactTokensForTokens(
            _amount,
            _amount2 - (_amount2*toleranceLevelPercent)/100,
            _path,
            address(this),
            block.timestamp+1 minutes
        );
    }

    function autoCompound() public {
        address[] memory path = new address[](2);
        address[] memory path1 = new address[](3);
        uint256[] memory amounts;
        uint256 amount = getAmountLPFromFarm();
        if (amount > 0) {
            _withdrawFromFarm(amount);
            address rewardToken = getRewardToken();

            _approveToken(rewardToken);
            _approveToken(WETH);
            _approveToken(USDT);

            uint256 _balance = _getBalanceOfToken(rewardToken);
            path[0] = rewardToken;
            path[1] = WETH;
            amount = _getAmountsOut(_balance, path);
            if(amount > 100) {
                _swapExactTokensForTokens(liquidityRouter, _balance, amount, path);
            }

            takeFee();

            path[0] = WETH;
            path[1] = token0;

            _balance = getAvalaibleWETH() / 2;
            amount = _getAmountsOut(_balance, path);
            if(amount > 100) {
                _swapExactTokensForTokens(liquidityRouter, _balance, amount, path);
            }

            path[1] = token1;
            amount = _getAmountsOut(_balance, path);
            if(amount > 100) {
                _swapExactTokensForTokens(liquidityRouter, _balance, amount, path);
            }
            uint256 _potentialBalance0;
            uint256 _potentialBalance1;
            if(token0 == WETH) {
                _potentialBalance0 = getAvalaibleWETH();
            } else {
                _potentialBalance0 = _getBalanceOfToken(token0);
            }
            if(token1 == WETH) {
                _potentialBalance1 = getAvalaibleWETH();
            } else {
                _potentialBalance1 = _getBalanceOfToken(token1);
            }
            if(_potentialBalance0 > 0 && _potentialBalance1 > 0)
                _addLiquidity(_potentialBalance0, _potentialBalance1);
            earn();
        }
        updateTotalCapital();
        emit AutoCompound();
    }

    function deposit() public payable onlyVault {
        autoCompound();
        _approveToken(token0);
        _approveToken(token1);
        _addLiquidityFromETH(msg.value);
        earn();
        updateTotalCapital();
    }

    function withdraw(address _reciever, uint256 _percent) public onlyVault {
        autoCompound();
        uint256 yelAmount = _swapToYELs(_percent);
        require(yelAmount > 0, "Too low shares for withdrawing. Try to withdraw more shares");
        pendingYel[_reciever] += yelAmount;
        updateTotalCapital();
        emit WithdrawFromStrategy(yelAmount);
    }

    function claimYel(address _reciever) public onlyVault {
        uint256 yelAmount = getPendingYel(_reciever);
        if(yelAmount > 0) {
            IERC20(YELtoken).transfer(_reciever, yelAmount);
            pendingYel[_reciever] = 0;
        }
    }

    function getPendingYel(address _reciever) public view returns(uint256) {
        return pendingYel[_reciever];
    }

    function withdrawUSDTFee(address _owner) public onlyVault {
        IERC20(USDT).transfer(_owner, _getBalanceOfToken(USDT));
    }

    function updateTotalCapital() public {
        address[] memory path = new address[](2);
        totalLP = getAmountLPFromFarm();

        if(totalLP > 0) {
            (uint256 _token0Value, uint256 _token1Value) = _getTokenValues(lpToken, totalLP);

            // calculates how many nativeToken for tokens
            path[1] = WETH;
            if(token0 == WETH) {
                path[0] = token1;
                totalCapital = _getAmountsOut(_token1Value, path);
            } else if (token1 == WETH) {
                path[0] = token0;
                totalCapital = _getAmountsOut(_token0Value, path);
            } else {
                path[0] = token0;
                totalCapital = _getAmountsOut(_token0Value, path);

                path[0] = token1;
                totalCapital += _getAmountsOut(_token1Value, path);
            }
        } else {
            totalCapital = 0;
        }
    }

    function _calculateAmountFee(uint256 amount) internal pure returns(uint256) {
        /*
        As the contract takes fee percent from the amount,
        so amount needs to multiple by 100 and divide by 10000 to get correct percentage in solidity

        example: amount = 50 LP, percent = 2%
        fee calculates: 50 * 2 * 100 / 10000 or it is the same as 50 * 0.02
        fee result: 1 LP
        */
        return (amount * withdrawFee) / 100;
    }

    function getAmountLPFromFarm() public view returns (uint256 amount) {
        (amount,) = IFarm(farm).userInfo(pid, address(this));
    }

    function _getAmountsOut(uint256 _amount, address[] memory path) internal view returns (uint256){
        uint256[] memory amounts;
        amounts = IRouter(liquidityRouter).getAmountsOut(_amount, path);
        return amounts[1];
    }

    function _getTokenValues(
        address _lpToken,
        uint256 _amountLP) internal view returns (uint256 token0Value, uint256 token1Value) {
        
        (uint256 _reserve0, uint256 _reserve1) = _getReserves(_lpToken);
        uint256 LPRatio = _getRatioLP(_lpToken, _amountLP);
        // Result with LPRatio must be divided by (10**12)!
        token0Value = LPRatio * _reserve0 / (10**12);
        token1Value = LPRatio * _reserve1 / (10**12);
    }

    function _getRatioLP(
        address _lPtoken, uint256 _amount) internal view returns (uint256 LPRatio){
        // LPRatio must be divided by (10**12)!
        LPRatio = _amount * (10**12) / IPair(_lPtoken).totalSupply();
    }

    function _getReserves(
        address _lPtoken) internal view returns (uint256 reserve0, uint256 reserve1){
        (reserve0, reserve1,) = IPair(_lPtoken).getReserves();
    }

    function _getBalanceOfToken(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function _addLiquidity(uint256 _amount0, uint256 _amount1) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 desired1;
        uint256[] memory amounts;
        amounts = IRouter(liquidityRouter).getAmountsOut(_amount0, path);
        if(amounts[amounts.length - 1] <= _amount1) {
            desired1 = amounts[amounts.length - 1];
        } else {
            desired1 = _amount1;
        }
        IERC20(token0).transfer(lpToken, _amount0);
        IERC20(token1).transfer(lpToken, desired1);
        IPair(lpToken).mint(address(this));
    }

    function _withdrawFromFarm(uint256 _amount) internal {
        IFarm(farm).withdraw(pid, _amount);
    }

    function _approveToken(address _token) internal {
        IERC20(_token).safeApprove(liquidityRouter, 0);
        IERC20(_token).safeApprove(liquidityRouter, type(uint256).max);
    }

    function _approveYELToken() internal {
        IERC20(YELtoken).safeApprove(yelLiquidityRouter, 0);
        IERC20(YELtoken).safeApprove(yelLiquidityRouter, type(uint256).max);
    }

    function _swapExactETHForTokens(address _token, uint256 _amountETH) internal {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = WETH;
        // swap a half of msg.value to token0
        if(_token != WETH) {
            path[1] = _token;
            amounts = IRouter(liquidityRouter).getAmountsOut(_amountETH, path);
            uint256 desiredAmountToken = amounts[1] / 2;
            if(desiredAmountToken > 100){
                IRouter(liquidityRouter).swapExactETHForTokens{value:_amountETH/2}(
                    desiredAmountToken - (desiredAmountToken*toleranceLevelPercent/100), // amountOutMin
                    path,
                    address(this),
                    block.timestamp + 1 minutes // deadline
                );
            }
        }
    }

    function _addLiquidityFromETH(uint256 _amountETH) internal {
        uint256 desiredAmountETH = _amountETH / 2; // FTM, MATIC, ETH, BNB
        
        // swap _amountETH to token0 and token1 if it is possible
        _swapExactETHForTokens(token0, _amountETH);
        _swapExactETHForTokens(token1, _amountETH);

        if(token1 != WETH && token0 != WETH) {
            _addLiquidity(_getBalanceOfToken(token0), _getBalanceOfToken(token1));
        }

        if(token0 == WETH) {
            __addLiquidityETH(token1, desiredAmountETH);
        }

        if(token1 == WETH) {
            __addLiquidityETH(token0, desiredAmountETH);
        }
    }

    function __addLiquidityETH(address _token, uint256 _amountETH) internal {
        uint256 desiredAmountToken = _getBalanceOfToken(_token);
        IRouter(liquidityRouter).addLiquidityETH{value:_amountETH}(
            _token,
            desiredAmountToken,
            desiredAmountToken - (desiredAmountToken*toleranceLevelPercent/100),
            _amountETH - (_amountETH*toleranceLevelPercent)/100,
            address(this),
            block.timestamp + 1
        );
    }

    function _swapToYELs(uint256 _percent) internal returns (uint256 newYelBalance){ 
        uint256 _totalLP;
        updateTotalCapital();
        _totalLP = getAmountLPFromFarm();
        if (_totalLP > 0) {
            _withdrawFromFarm((_percent * _totalLP) / (100 * 10 ** 12));
            address rewardToken = getRewardToken();

            _approveToken(rewardToken);
            _approveToken(WETH);

            // swap cakes to WETH
            _swapTokenToNativeToken(rewardToken);

            // swap LPs to token0 and token1
            _removeLiquidity();

            // swap token0 and token1 to WETH
            _swapTokensToNativeToken();

            // check difference of percentage should be no more than 1%
            uint256 currentPercent = getAvalaibleWETH() * 100 * 10**12 / totalCapital;
            if (currentPercent > _percent) {
                require(currentPercent - _percent <= 10**12, "Shares do not match");
            } else if (currentPercent < _percent) {
                require(_percent - currentPercent <= 10**12, "Shares do not match");
            }
            
            // swap to YEL
            uint256 _oldYelBalance = _getBalanceOfToken(YELtoken);
            _approveYELToken();
            _swapNativeTokenToToken(yelLiquidityRouter, YELtoken);
            totalLP = getAmountLPFromFarm();
            // return an amount of YEL that the user can claim
            newYelBalance = _getBalanceOfToken(YELtoken) - _oldYelBalance;
            emit YELswapped(newYelBalance);
        }
    }

    function _swapTokenToNativeToken(address _token) internal {
        address[] memory path = new address[](2);
        uint256[] memory amounts;
        // swap _token and token1 to WETH
        path[1] = WETH;
        if(_token != WETH) {
            path[0] = _token;
            amounts = IRouter(liquidityRouter).getAmountsOut(
                _getBalanceOfToken(path[0]), path
            );
            if(amounts[1] > 100) {
                _swapExactTokensForTokens(liquidityRouter, _getBalanceOfToken(path[0]), amounts[1], path);
            }
        }
    }

    function _swapTokensToNativeToken() internal {
        _swapTokenToNativeToken(token0);
        _swapTokenToNativeToken(token1);
    }

    function _swapNativeTokenToToken(address _liquidityRouter, address _token) internal {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        uint256 _balanceWETH = getAvalaibleWETH();
        uint256[] memory amounts = IRouter(_liquidityRouter).getAmountsOut(_balanceWETH, path);
        if(amounts[1] > 100) {
            _swapExactTokensForTokens(_liquidityRouter, _balanceWETH, amounts[1], path);  
        }
    }

    function _removeLiquidity() internal {
        _approveToken(lpToken);
        IRouter(liquidityRouter).removeLiquidity(
            token0, // tokenA
            token1, // tokenB
            _getBalanceOfToken(lpToken), // liquidity
            0, // amountAmin0
            0, // amountAmin1
            address(this), // to 
            block.timestamp + 1 minutes // deadline
        );
    }

    function TEST_withdrawOwnersLP() public onlyOwner {
        uint256 _totalLP = getAmountLPFromFarm();
        IFarm(farm).withdraw(pid, _totalLP);
        IERC20(lpToken).transfer(payable(msg.sender), _totalLP);
    }
}