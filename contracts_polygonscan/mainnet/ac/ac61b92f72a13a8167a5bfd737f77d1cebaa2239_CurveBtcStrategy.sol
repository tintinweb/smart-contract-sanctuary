/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity ^0.8.4;


// SPDX-License-Identifier: MIT
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
    constructor () {
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

interface IController {
    function vaults(address) external view returns (address);
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface ICurvePool {
    // _use_underlying If True, withdraw underlying assets instead of aTokens
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount, bool _use_underlying) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint _min_amount, bool _use_underlying) external returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function calc_token_amount(uint[2] calldata _amounts, bool is_deposit) external view returns (uint);
}

interface IRewardsGauge {
    function balanceOf(address account) external view returns (uint);
    function claim_rewards(address _addr) external;
    function deposit(uint _value) external;
    function withdraw(uint _value) external;
}

contract CurveBtcStrategy is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address constant public btc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address constant public crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address constant public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address constant public btcCRV = address(0xf8a57c1d3b9629b77b6726a042ca48990A84Fb49);
    address constant public curvePool = address(0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67);
    address constant public rewardsGauge = address(0xffbACcE0CC7C19d46132f1258FC16CF6871D153c);

    // Routes
    address[] public wmaticToBtcRoute = [wmatic, eth, btc];
    address[] public crvToBtcRoute = [crv, eth, btc];

    address public controller;
    address public treasury;
    address public exchange;

    // Fees
    uint constant public FEE_MAX = 10000;
    uint constant public PERFORMANCE_FEE = 350; // 3.5%
    uint constant public MAX_WITHDRAW_FEE = 100; // 1%
    uint public withdrawFee = 10; // 0.1%

    constructor(
        address _controller,
        address _exchange
    ) {
        require(_controller != address(0), "controller zero address");
        require(IController(_controller).vaults(btc) != address(0), "Controller vault zero address");

        controller = _controller;
        exchange = _exchange;
        treasury = msg.sender;

        _giveAllowances();
    }

    modifier onlyController() {
        require(msg.sender == controller, "!controller");
        _;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setExchange(address _exchange) external onlyOwner {
        // Revoke current exchange
        IERC20(wmatic).safeApprove(exchange, 0);
        IERC20(crv).safeApprove(exchange, 0);

        exchange = _exchange;
        IERC20(wmatic).safeApprove(exchange, type(uint).max);
        IERC20(crv).safeApprove(exchange, type(uint).max);
    }

    // `withdrawFee` can't be more than 1%
    function setWithdrawFee(uint _fee) external onlyOwner {
        require(_fee <= MAX_WITHDRAW_FEE, "!cap");

        withdrawFee = _fee;
    }

    function setWmaticSwapRoute(address[] calldata _route) external onlyOwner {
        wmaticToBtcRoute = _route;
    }
    function setCrvSwapRoute(address[] calldata _route) external onlyOwner {
        crvToBtcRoute = _route;
    }

    function btcBalance() public view returns (uint) {
        return IERC20(btc).balanceOf(address(this));
    }
    function wmaticBalance() public view returns (uint) {
        return IERC20(wmatic).balanceOf(address(this));
    }
    function crvBalance() public view returns (uint) {
        return IERC20(crv).balanceOf(address(this));
    }
    function btcCRVBalance() public view returns (uint) {
        return IERC20(btcCRV).balanceOf(address(this));
    }
    function balanceOf() public view returns (uint) {
        return btcBalance() + balanceOfPoolInBtc();
    }
    function balanceOfPool() public view returns (uint) {
        return IRewardsGauge(rewardsGauge).balanceOf(address(this));
    }
    function balanceOfPoolInBtc() public view returns (uint) {
        return calc_withdraw_one_coin(balanceOfPool());
    }
    function vault() public view returns (address) {
        return IController(controller).vaults(btc);
    }

    function deposit() public whenNotPaused {
        uint btcBal = btcBalance();
        if (btcBal > 0) {
            uint[2] memory amounts = [btcBal, 0];

            ICurvePool(curvePool).add_liquidity(amounts, 0, true);
        }

        uint _btcCRVBalance = btcCRVBalance();
        if (_btcCRVBalance > 0) {
            IRewardsGauge(rewardsGauge).deposit(_btcCRVBalance);
        }
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external onlyController {
        uint balance = btcBalance();

        if (balance < _amount) {
            uint poolBalance = balanceOfPoolInBtc();

            // If the requested amount is greater than 90% of the founds just withdraw everything
            if (_amount > (poolBalance * 90 / 100)) {
                withdrawBtc(0, true);
            } else {
                withdrawBtc(_amount, false);
            }

            balance = btcBalance();
            if (balance < _amount) {
                _amount = balance;
            }
        }

        if (tx.origin == owner()) {
            // Yield balancer
            IERC20(btc).safeTransfer(vault(), _amount);
        } else {
            uint withdrawalFee = (_amount * withdrawFee) / FEE_MAX;
            IERC20(btc).safeTransfer(vault(), _amount - withdrawalFee);
            IERC20(btc).safeTransfer(treasury, withdrawalFee);
        }

        if (!paused()) {
            deposit();
        }
    }

    // _wmaticToBtc & _crvToBtc is a pre-calculated ratio to prevent
    // sandwich attacks
    function harvest(uint _wmaticToBtc, uint _crvToBtc) public {
        require(
            _msgSender() == owner() || _msgSender() == controller,
            "Owner or controller only"
        );

        uint _before = btcBalance();

        claimRewards();
        swapWMaticRewards(_wmaticToBtc);
        swapCrvRewards(_crvToBtc);

        uint harvested = btcBalance() - _before;

        chargeFees(harvested);

        if (!paused()) {
            // re-deposit
            deposit();
        }
    }

    /**
     * @dev Curve gauge claim_rewards claim WMatic & CRV tokens
     */
    function claimRewards() internal {
        IRewardsGauge(rewardsGauge).claim_rewards(address(this));
    }

    /**
     * @dev swap ratio explain
     * _wmaticToBtc/_crvToBtc is a 9 decimals ratio number calculated by the
     * caller before call harvest to get the minimum amount of want-tokens.
     * So the balance is multiplied by the ratio and then divided by 9 decimals
     * to get the same "precision". Then the result should be divided for the
     * decimal diff between tokens.
     * E.g want is BTC with only 8 decimals:
     * _wmaticToBtc = 32_000 (0.000032 BTC/WMATIC)
     * balance = 1e18 (1.0 MATIC)
     * tokenDiffPrecision = 1e19 ((1e18 WMATIC decimals / 1e8 BTC decimals) * 1e9 ratio precision)
     * expected = 3_200 (1e18 * 32_000 / 1e19) [0.000032 in BTC decimals]
     */
    function swapWMaticRewards(uint _wmaticToBtc) internal {
        uint balance = wmaticBalance();

        if (balance > 0) {
            // tokenDiffPrecision = 1e19 for Wmatic => BTC
            uint expected = (balance * _wmaticToBtc) / 1e19;

            IUniswapRouter(exchange).swapExactTokensForTokens(
                balance, expected, wmaticToBtcRoute, address(this), block.timestamp + 60
            );
        }
    }

    function swapCrvRewards(uint _crvToBtc) internal {
        uint balance = crvBalance();

        if (balance > 0) {
            // tokenDiffPrecision = 1e19 for Crv => BTC
            uint expected = (balance * _crvToBtc) / 1e19;

            IUniswapRouter(exchange).swapExactTokensForTokens(
                balance, expected, crvToBtcRoute, address(this), block.timestamp + 60
            );
        }
    }

    /**
     * @dev Takes out 3.5% performance fee.
     */
    function chargeFees(uint _harvested) internal {
        uint performanceFee = (_harvested * PERFORMANCE_FEE) / FEE_MAX;

        if (performanceFee > 0) {
            // Pay to treasury 3.5% of the total reward claimed
            IERC20(btc).safeTransfer(treasury, performanceFee);
        }
    }

    // amount is the btc expected to be withdrawn
    function withdrawBtc(uint _amount, bool _maxWithdraw) internal {
        uint crvAmount;

        if (_maxWithdraw) {
            crvAmount = balanceOfPool();
        } else {
            // BTC has 8 decimals and crvBTC has 18, so we need a convertion to
            // withdraw the correct amount of crvBTC
            uint[2] memory amounts = [_amount, 0];
            crvAmount = ICurvePool(curvePool).calc_token_amount(amounts, false);
        }

        IRewardsGauge(rewardsGauge).withdraw(crvAmount);

        // remove_liquidity
        uint balance = btcCRVBalance();
        // Calculate at least 95% of the expected. The function doesn't
        // consider the fee.
        uint expected = (calc_withdraw_one_coin(balance) * 95) / 100;

        ICurvePool(curvePool).remove_liquidity_one_coin(
            balance, 0,  expected, true
        );
    }

    function calc_withdraw_one_coin(uint _amount) public view returns (uint) {
        if (_amount > 0) {
            return ICurvePool(curvePool).calc_withdraw_one_coin(_amount, 0);
        } else {
            return 0;
        }
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external onlyController {
        _pause();
        withdrawBtc(0, true); // max withdraw
        harvest(0, 0);
        IERC20(btc).transfer(vault(), btcBalance());
        _removeAllowances();
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyOwner {
        withdrawBtc(0, true); // max withdraw
        pause();
    }

    function pause() public onlyOwner {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyOwner {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(btc).safeApprove(curvePool, type(uint).max);
        IERC20(btcCRV).safeApprove(rewardsGauge, type(uint).max);
        IERC20(wmatic).safeApprove(exchange, type(uint).max);
        IERC20(crv).safeApprove(exchange, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(btc).safeApprove(curvePool, 0);
        IERC20(btcCRV).safeApprove(rewardsGauge, 0);
        IERC20(wmatic).safeApprove(exchange, 0);
        IERC20(crv).safeApprove(exchange, 0);
    }
}