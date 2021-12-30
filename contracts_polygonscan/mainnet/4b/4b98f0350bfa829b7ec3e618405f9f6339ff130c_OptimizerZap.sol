/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


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
contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {

            require(newOwner != address(0) || renounce, "Ownable: zero address");

            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            pendingOwner = newOwner;
        }
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}
interface IPopsicleV3Optimizer {
    function token0() external view returns (address);
    function token1() external view returns (address);
 
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external ;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

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

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;
}

contract OptimizerZap is Ownable {
    using SafeERC20 for IERC20;

    address constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant weth = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public immutable DAO;
    mapping(address => bool) public approvedTargets;

    struct TokenData {
        uint256 amount;
        address swapTarget;
        bytes swapData;
    }

    constructor(address _DAO) {
        DAO = _DAO;
        approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
    }

    function DepositInEth(address optimizer, address to, address fromTokenAddress, uint256 amount) external payable {
        address token0 = IPopsicleV3Optimizer(optimizer).token0();
        address token1 = IPopsicleV3Optimizer(optimizer).token1();
        require(token0 == weth || token1 == weth, "BO");
        uint256 toInvest = _pullTokens(fromTokenAddress, amount);
        uint256 wethToInvest = msg.value;
        IWETH9(weth).deposit{value: wethToInvest}();
        if (token0 == weth) {
            require(token1 == fromTokenAddress, "TNA");
            _approveToken(weth, optimizer, wethToInvest);
            _approveToken(token1, optimizer, toInvest);
            (, uint256 amount0, uint256 amount1) = IPopsicleV3Optimizer(optimizer).deposit(wethToInvest, toInvest, to);
            uint256 res0 = wethToInvest-amount0;
            uint256 res1 = toInvest-amount1;
            if (res0 > 0 ) TransferHelper.safeTransfer(token0, to, res0);
            if (res1 > 0 ) TransferHelper.safeTransfer(token1, to, res1);
        } else {
            require(token0 == fromTokenAddress, "TNA");
            _approveToken(token0, optimizer, toInvest);
            _approveToken(weth, optimizer, wethToInvest);
            (, uint256 amount0,uint256 amount1) = IPopsicleV3Optimizer(optimizer).deposit(toInvest, wethToInvest,  to);
            uint256 res0 = toInvest-amount0;
            uint256 res1 = wethToInvest-amount1;
            if (res0 > 0 ) TransferHelper.safeTransfer(token0, to, res0);
            if (res1 > 0 ) TransferHelper.safeTransfer(token1, to, res1);
        }
    }

    function ZapIn(address optimizer, address to, address fromTokenAddress, TokenData calldata tokenData0, TokenData calldata tokenData1) external payable {
        address token0 = IPopsicleV3Optimizer(optimizer).token0();
        address token1 = IPopsicleV3Optimizer(optimizer).token1();
        _pullTokens(fromTokenAddress, tokenData0.amount + tokenData1.amount);
        if (_IsEth(fromTokenAddress)) fromTokenAddress = weth;
        uint256 toInvest0 = _fillQuote(fromTokenAddress, token0, tokenData0.amount, tokenData0.swapTarget, tokenData0.swapData);
        uint256 toInvest1 = _fillQuote(fromTokenAddress, token1, tokenData1.amount, tokenData1.swapTarget, tokenData1.swapData);
        _approveToken(token0, optimizer, toInvest0);
        _approveToken(token1, optimizer, toInvest1);
        (, uint256 amount0, uint256 amount1) = IPopsicleV3Optimizer(optimizer).deposit(toInvest0, toInvest1, to);
        uint256 res0 = toInvest0-amount0;
        uint256 res1 = toInvest1-amount1;
        if (res0 > 0 ) TransferHelper.safeTransfer(token0, to, res0);
        if (res1 > 0 ) TransferHelper.safeTransfer(token1, to, res1);
    }

    function setApprovedTarget(
        address target,
        bool isApproved
    ) external onlyOwner {
            approvedTargets[target] = isApproved;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (_fromTokenAddress == _toTokenAddress) return _amount;

        _approveToken(_fromTokenAddress, _swapTarget, _amount);

        IERC20 targetToken = IERC20(_toTokenAddress);
        uint256 initialBalance = targetToken.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = targetToken.balanceOf(address(this)) - initialBalance;
        
        require(amountBought > 0, "Swapped value not allowed");
    }

    function _pullTokens(
        address token,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "Invalid token amount");
        if (_IsEth(token)) {
            require(msg.value == amount, "No enough eth sent");
            IWETH9(weth).deposit{ value: amount }();
            return amount;
        }
        //transfer token

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        return amount;
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    function _IsEth(address token) internal pure returns(bool) {
        return token == eth || token == address(0);
    }
    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        TransferHelper.safeTransfer(_token, DAO, IERC20( _token ).balanceOf( address(this)));
        return true;
    }

    function refundETH() external returns ( bool ) {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(DAO, address(this).balance);
        return true;
    }
}