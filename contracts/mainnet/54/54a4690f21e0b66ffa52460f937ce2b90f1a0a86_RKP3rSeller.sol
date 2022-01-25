/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.2;



// Part: IIbAMM

interface IIbAMM{
        function swap(address to, uint256 amount, uint256 minOut) external returns(bool);
        function quote(address to, uint256 amount) external returns(uint256);
}

// Part: ILiquidityPool

interface ILiquidityPool {
    /// @dev Borrow ETH/ERC20s from the liquidity pool. This function will (1)
    /// send an amount of tokens to the `msg.sender`, (2) call
    /// `msg.sender.call(_data)` from the KeeperDAO borrow proxy, and then (3)
    /// check that the balance of the liquidity pool is greater than it was
    /// before the borrow.
    ///
    /// @param _token The address of the ERC20 to be borrowed. ETH can be
    /// borrowed by specifying "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE".
    /// @param _amount The amount of the ERC20 (or ETH) to be borrowed. At least
    /// more than this amount must be returned to the liquidity pool before the
    /// end of the transaction, otherwise the transaction will revert.
    /// @param _data The calldata that encodes the callback to be called on the
    /// `msg.sender`. This is the mechanism through which the borrower is able
    /// to implement their custom keeper logic. The callback will be called from
    /// the KeeperDAO borrow proxy.
    function borrow(
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
}

// Part: IRKP3R

interface IRKP3R {
        function redeem(uint256 id) external;
        function claim(uint256 amount) external returns (uint256);
        function claim() external returns (uint256);
        function options(uint256) external view returns (uint256 amount, uint256 strike, uint256 expiry, bool exercised);
}

// Part: IStableSwap

interface IStableSwap {
        function calc_withdraw_one_coin(uint256, int128) external view returns(uint256);
        function calc_withdraw_one_coin(uint256, int128, bool) external view returns(uint256);
        function remove_liquidity_one_coin(uint256, int128, uint256, bool) external;
        function add_liquidity(uint256[2] calldata,uint256) external;
        function add_liquidity(uint256[2] calldata,uint256,address) external;
        function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}

// Part: IUniswap

interface IUniswap {
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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

        function swapExactTokensForTokens(
                uint amountIn,
                uint amountOutMin,
                address[] calldata path,
                address to,
                uint deadline
        ) external returns (uint[] memory amounts);

        function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// File: RKP3RSeller.sol

contract RKP3rSeller is Ownable {
        using SafeERC20 for IERC20;

        address internal constant KP3R = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
        address internal constant RKP3R = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;
        address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address internal constant MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
        address internal constant KEEPERDAO = 0x4F868C1aa37fCf307ab38D215382e88FCA6275E2;
        address internal constant BORROWER = 0x17a4C8F43cB407dD21f9885c5289E66E21bEcD9D;
        address internal constant SUSHI = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        address internal constant CURVE_MIM = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
        address internal constant IB_AMM = 0x8338Aa899fB3168598D871Edc1FE2B4F0Ca6BBEF;


        constructor() public {
        address ibEUR = 0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27;
        address ibGBP = 0x69681f8fde45345C3870BCD5eaf4A05a60E7D227;
        address ibCHF = 0x1CC481cE2BD2EC7Bf67d1Be64d4878b16078F309;
        address ibAUD = 0xFAFdF0C4c1CB09d430Bf88c75D88BB46DAe09967;
        address ibKRW = 0x95dFDC8161832e4fF7816aC4B6367CE201538253;
        address ibJPY = 0x5555f75e3d5278082200Fb451D1b6bA946D8e13b;

        address curveEUR = 0x19b080FE1ffA0553469D20Ca36219F17Fcf03859;
        address curveGBP = 0xD6Ac1CB9019137a896343Da59dDE6d097F710538;
        address curveCHF = 0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c;
        address curveAUD = 0x3F1B0278A9ee595635B61817630cC19DE792f506;
        address curveKRW = 0x8461A004b50d321CB22B7d034969cE6803911899;
        address curveJPY = 0x8818a9bb44Fbf33502bE7c15c500d0C783B73067;

        IERC20(USDC).approve(RKP3R, type(uint256).max);
        IERC20(USDC).approve(CURVE_MIM, type(uint256).max);
        IERC20(KP3R).approve(SUSHI, type(uint256).max);
        IERC20(MIM).approve(IB_AMM, type(uint256).max);

        IERC20(ibEUR).approve(curveEUR, type(uint256).max);
        IERC20(ibGBP).approve(curveGBP, type(uint256).max);
        IERC20(ibCHF).approve(curveCHF, type(uint256).max);
        IERC20(ibAUD).approve(curveAUD, type(uint256).max);
        IERC20(ibKRW).approve(curveKRW, type(uint256).max);
        IERC20(ibJPY).approve(curveJPY, type(uint256).max);
        }

        function initiateConvertRKP3RToIB(uint256 _amount, address _IBToken, address _factoryPool, address _receiver) external {
                IERC20(RKP3R).safeTransferFrom(msg.sender, address(this), _amount);
                uint256 nftId = IRKP3R(RKP3R).claim(_amount);
                (uint256 kprAmount, uint256 strike,,) = IRKP3R(RKP3R).options(nftId);
                bytes memory data = abi.encodeWithSelector(RKP3rSeller.fallbackSellKP3RToUSDCSushi.selector, kprAmount, nftId, strike);
                ILiquidityPool(KEEPERDAO).borrow(USDC, strike, data);
                // 2 is USDC, 0 is mim
                uint256 out = IStableSwap(CURVE_MIM).exchange_underlying(2, 0, IERC20(USDC).balanceOf(address(this)), 0);
                uint256 ibTokenAmount = IIbAMM(IB_AMM).quote(_IBToken, out);
                IIbAMM(IB_AMM).swap(_IBToken, out, 0);
                // Checked all pools, index 0 is always IB coin
                IStableSwap(_factoryPool).add_liquidity([ibTokenAmount, 0], 0, _receiver);
        }


        function fallbackSellKP3RToUSDCSushi(uint256 _KP3Ramount, uint256 _nftId, uint256 _repayAmount) external {
                require(msg.sender == BORROWER, "!keeperDAO");
                IRKP3R(RKP3R).redeem(_nftId);
                address[] memory path = new address[](3);
                path[0] = KP3R;
                path[1] = WETH;
                path[2] = USDC;
                IUniswap(SUSHI).swapExactTokensForTokens(
                        _KP3Ramount,
                        0,
                        path,
                        address(this),
                        block.timestamp
                );
                IERC20(USDC).safeTransfer(KEEPERDAO, _repayAmount);
        }

        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
                return RKP3rSeller.onERC721Received.selector;
        }

        function sweep(address _token) external onlyOwner {
                IERC20 tokenToSend = IERC20(_token);
                uint256 amountToSend = tokenToSend.balanceOf(address(this));
                tokenToSend.safeTransfer(owner(), amountToSend);
        }
}