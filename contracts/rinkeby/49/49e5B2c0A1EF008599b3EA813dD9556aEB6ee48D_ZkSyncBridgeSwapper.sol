/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

//SPDX-License-Identifier: Unlicense
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


interface ICurvePool {
    function exchange(int128 _i, int128 _j, uint256 _dx, uint256 _min_dy) external returns (uint256);
}

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

interface IWstETH {
    function stETH() external returns (address);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}

interface IZkSync {
    function withdrawPendingBalance(address payable _owner, address _token, uint128 _amount) external;
    function depositETH(address _zkSyncAddress) external payable;
    function depositERC20(IERC20 _token, uint104 _amount, address _zkSyncAddress) external;
}

contract ZkSyncBridgeSwapper {

    // The ZkSync bridge contract
    address public immutable zkSync;
    // The L2 market maker account
    address public immutable l2Account;
    // The address of the stEth token
    address public immutable stEth;
    // The address of the wrapped stEth token
    address public immutable wStEth;
    // The address of the stEth/Eth Curve pool
    address public immutable stEthPool;
    // The referal address for Lido
    address public immutable lidoReferal;

    address constant internal ETH_TOKEN = address(0);

    event Swapped(address _in, uint256 _amountIn, address _out, uint256 _amountOut);

    constructor (
        address _zkSync,
        address _l2Account,
        address _wStEth,
        address _stEthPool,
        address _lidoReferal
    )
    {
        zkSync = _zkSync;
        l2Account = _l2Account;
        wStEth = _wStEth;
        stEth = IWstETH(_wStEth).stETH();
        stEthPool = _stEthPool;
        lidoReferal =_lidoReferal;
    }
    
    /**
    * @dev Withdraws wrapped stETH from the ZkSync bridge, unwrap it to stETH,
    * swap the stETH for ETH on Curve, and deposits the ETH back to the bridge.
    * @param _amountIn The amount of wrapped stETH to withdraw from ZkSync
    * @param _minAmountOut The minimum amount of ETH to receive and deposit back to ZkSync
    */
    function swapStEthForEth(uint256 _amountIn, uint256 _minAmountOut) external returns (uint256) {
        // withdraw wrapped stEth from the L2 bridge
        IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), wStEth, toUint128(_amountIn));
        // unwrap to stEth
        uint256 unwrapped = IWstETH(wStEth).unwrap(_amountIn);
        // swap stEth for ETH on Curve
        uint256 amountOut = ICurvePool(stEthPool).exchange(1, 0, unwrapped, _minAmountOut);
        // redundant but this way we don't rely on Curve for the check
        require (amountOut >= _minAmountOut, "out too small");
        // deposit Eth to L2 bridge
        IZkSync(zkSync).depositETH{value: amountOut}(l2Account);
        // emit event
        emit Swapped(wStEth, _amountIn, ETH_TOKEN, amountOut);
        // return deposited amount
        return amountOut;
    }

    /**
    * @dev Withdraws ETH from ZkSync bridge, swap it for stETH, wrap it, and deposit the wrapped stETH back to the bridge.
    * @param _amountIn The amount of ETH to withdraw from ZkSync
    * @param _minAmountOut The minimum amount of stETH to receive and deposit back to ZkSync
    */
    function swapEthForStEth(uint256 _amountIn, uint256 _minAmountOut) external returns (uint256) {
        // withdraw Eth from the L2 bridge
        IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), address(0), toUint128(_amountIn));
        // swap Eth for stEth on the Lido contract
        ILido(stEth).submit{value: _amountIn}(lidoReferal);
        // approve the wStEth contract to take the stEth
        IERC20(stEth).approve(wStEth, _amountIn);
        // wrap to wStEth
        uint256 amountOut = IWstETH(wStEth).wrap(_amountIn);
        // not needed, but we still check that we have received enough Eth
        require (amountOut >= _minAmountOut, "out too small");
        // approve the zkSync bridge to take the wrapped stEth
        IERC20(wStEth).approve(zkSync, amountOut);
        // deposit the wStEth to the L2 bridge
        IZkSync(zkSync).depositERC20(IERC20(wStEth), toUint104(amountOut), l2Account);
        // emit event
        emit Swapped(ETH_TOKEN, _amountIn, wStEth, amountOut);
        // return deposited amount
        return amountOut;
    }

    /**
    * @dev Safety method to recover ERC20 tokens that are sent to the contract by error.
    * The tokens are recovered by deposting them to the l2Account on zkSync.
    * @param _token The token to recover. Must be a token supported by ZkSync.
    */
    function recoverToken(address _token) external returns (uint256) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        address token = _token;
        if (token == stEth) {
            // wrap to wStEth
            IERC20(stEth).approve(wStEth, balance);
            balance = IWstETH(wStEth).wrap(balance);
            token = wStEth;
        }
        // approve the zkSync bridge to take the token
        IERC20(token).approve(zkSync, balance);
        // deposit the token to the L2 bridge
        IZkSync(zkSync).depositERC20(IERC20(token), toUint104(balance), l2Account);
        // return deposited amount
        return balance;
    }

    /**
     * @dev fallback method to make sure we can receive ETH from ZkSync or Curve.
     */
    receive() external payable {
        require(msg.sender == zkSync || msg.sender == stEthPool, "no ETH transfer");
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }
}