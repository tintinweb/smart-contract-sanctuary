/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

pragma solidity >=0.5.17 <0.9.0;


interface IToken {
    function comptroller() external view returns (address);
    function redeem(uint redeemTokens) external returns (uint);
    function underlying() external view returns (address);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function symbol() external view returns (bytes32);
    function getAccountSnapshot(address account) external view returns(uint, uint, uint, uint);
}

interface IEthToken is IToken {
    function liquidateBorrow(address borrower, address collateral) external payable;
}

interface IErcToken is IToken {
    function liquidateBorrow(address borrower, uint repayAmount, address collateral) external returns (uint);
}

interface IComptroller {
    function closeFactorMantissa() external view returns (uint256);
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address pToken) external view returns (bool);
    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
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

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;
}

//interface IERC20 {
//    function totalSupply() external view returns (uint256);
//
//    function balanceOf(address account) external view returns (uint256);
//
//    function transfer(address recipient, uint256 amount) external returns (bool);
//
//    function allowance(address owner, address spender) external view returns (uint256);
//
//    function approve(address spender, uint256 amount) external returns (bool);
//
//    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//
//    function name() external view returns (string memory);
//
//    function decimals() external view returns (uint8);
//
//    event Transfer(address indexed from, address indexed to, uint256 value);
//    event Approval(address indexed owner, address indexed spender, uint256 value);
//}
interface IWETH {
    function withdraw(uint) external;

    function deposit() external payable;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

contract LiquidateLends is Ownable {

    using SafeERC20 for IERC20;

    enum SwapType {SimpleLoan, SimpleSwap, TriangularSwap}
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public ethTokens;
    address public WETH;
    IUniswapV2Factory public uniswapV2Factory;

    constructor(address _factory, address _WETH) {
        WETH = _WETH;
        uniswapV2Factory = IUniswapV2Factory(_factory);
    }

    // 设置eth代币
    function setEthTokens(address[] memory tokens, bool status) public onlyOwner {
        uint count = tokens.length;
        for (uint i = 0; i < count; i++) {
            address token = tokens[i];
            ethTokens[token] = status;
        }
    }


    function liquidate(address borrower, address tokenCollateral, address tokenBorrow, uint repayAmount, address flashBorrowPair, address flashPayPair, address againstToken) external {

        bytes memory data = abi.encode(tokenBorrow, tokenCollateral, borrower, repayAmount, flashBorrowPair, flashPayPair, againstToken);

        address _tokenBorrow;
        address _tokenPay;
        if (_isEthToken(tokenBorrow)) {
            _tokenBorrow = address(ETH);
        } else {
            _tokenBorrow = IErcToken(tokenBorrow).underlying();
        }
        if (_isEthToken(tokenCollateral)) {
            _tokenPay = address(ETH);
        } else {
            _tokenPay = IErcToken(tokenCollateral).underlying();
        }

        startSwap(_tokenBorrow, repayAmount, _tokenPay, data);

    }

    function startSwap(address _tokenBorrow, uint _amount, address _tokenPay, bytes memory _userData) public {

        bool isBorrowingEth;
        bool isPayingEth;
        address tokenBorrow = _tokenBorrow;
        address tokenPay = _tokenPay;

        if (tokenBorrow == ETH) {
            isBorrowingEth = true;
            tokenBorrow = WETH;
        }
        if (tokenPay == ETH) {
            isPayingEth = true;
            tokenPay = WETH;
        }

        if (tokenBorrow == tokenPay || tokenBorrow == WETH || tokenPay == WETH) {
            simpleFlashLoan(tokenBorrow, _amount, tokenBorrow, isBorrowingEth, isPayingEth, _userData);
            return;
        } else {
            triangularFlashLoan(tokenBorrow, _amount, tokenPay, _userData);
            return;
        }

    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {

        // decode data
        (
        SwapType _swapType,
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _triangleData,
        bytes memory _userData
        ) = abi.decode(_data, (SwapType, address, uint, address, bool, bool, bytes, bytes));

        if (_swapType == SwapType.SimpleLoan) {
            simpleFlashLoanExecute(_tokenBorrow, _amount, _tokenPay, msg.sender, _isBorrowingEth, _isPayingEth, _userData);
            return;
        } else {
            triangularFlashLoanExecute(_tokenBorrow, _amount, _tokenPay, _triangleData, _userData);
            return;
        }

    }

    function simpleFlashLoan(address _tokenBorrow, uint256 _amount, address _tokenPay, bool _isBorrowingEth, bool _isPayingEth, bytes memory _userData) private {

        (,,,, address pairAddress,,) = abi.decode(_userData, (address, address, address, uint, address, address, address));
        require(pairAddress != address(0), "Requested _token is not available.");

        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(
            SwapType.SimpleLoan,
            _tokenBorrow,
            _amount,
            _tokenBorrow,
            _isBorrowingEth,
            _isPayingEth,
            bytes(""),
            _userData
        );
        // note _tokenBorrow == _tokenPay
        IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), data);
    }

    function simpleFlashLoanExecute(address _tokenBorrow, uint _amount, address _tokenPay, address _pairAddress, bool _isBorrowingEth, bool _isPayingEth, bytes memory _userData) private {
        if (_isBorrowingEth) {
            IWETH(WETH).withdraw(_amount);
        }

        // compute amount of tokens that need to be paid back
        uint amountToRepay;
        if (_isBorrowingEth || _isPayingEth) {
            uint pairBalanceTokenBorrow = IERC20(_tokenBorrow).balanceOf(_pairAddress);
            uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(_pairAddress);
            amountToRepay = ((1000 * pairBalanceTokenPay * _amount) / (997 * pairBalanceTokenBorrow)) + 1;
        } else {
            uint fee = ((_amount * 3) / 997) + 1;
            amountToRepay = _amount + fee;
        }

        address tokenBorrowed = _isBorrowingEth ? ETH : _tokenBorrow;
        address tokenToRepay = _isPayingEth ? ETH : _tokenPay;

        // do whatever the user wants
        execute(tokenBorrowed, _amount, tokenToRepay, amountToRepay, _userData);

        if (_isPayingEth) {
            IWETH(WETH).deposit{value : amountToRepay}();
        }

        _approveMaxInternal(_tokenBorrow,_pairAddress,amountToRepay);
        IERC20(_tokenBorrow).transfer(_pairAddress, amountToRepay);
    }

    function triangularFlashLoan(address _tokenBorrow, uint _amount, address _tokenPay, bytes memory _userData) private {

        (,,,, address borrowPairAddress,address payPairAddress,address againstToken) = abi.decode(_userData, (address, address, address, uint, address, address, address));

        // STEP 1: Compute how much againstToken will be needed to get _amount of _tokenBorrow out of the _tokenBorrow/againstToken pool
        uint pairBalanceTokenBorrowBefore = IERC20(_tokenBorrow).balanceOf(borrowPairAddress);
        require(pairBalanceTokenBorrowBefore >= _amount, "_amount is too big");
        uint pairBalanceTokenBorrowAfter = pairBalanceTokenBorrowBefore - _amount;
        uint pairBalanceAgainstToken = IERC20(againstToken).balanceOf(borrowPairAddress);
        uint amountOfAgainstToken = ((1000 * pairBalanceAgainstToken * _amount) / (997 * pairBalanceTokenBorrowAfter)) + 1;


        triangularFlashLoanHelp(payPairAddress, borrowPairAddress, againstToken, amountOfAgainstToken, _tokenBorrow, _amount, _tokenPay, _userData);
    }

    function triangularFlashLoanHelp(address payPairAddress, address borrowPairAddress, address againstToken, uint amountOfAgainstToken, address _tokenBorrow, uint _amount, address _tokenPay, bytes memory _userData) internal {
        // Step 2: Flash-borrow amountOfAgainstToken AgainstToken from the _tokenPay/AgainstToken pool
        address token0 = IUniswapV2Pair(payPairAddress).token0();
        address token1 = IUniswapV2Pair(payPairAddress).token1();
        uint amount0Out = againstToken == token0 ? amountOfAgainstToken : 0;
        uint amount1Out = againstToken == token1 ? amountOfAgainstToken : 0;
        bytes memory triangleData = abi.encode(borrowPairAddress, amountOfAgainstToken);
        bytes memory data = abi.encode(SwapType.TriangularSwap, _tokenBorrow, _amount, _tokenPay, false, false, triangleData, _userData);

        // initiate the flash swap from UniswapV2
        IUniswapV2Pair(payPairAddress).swap(amount0Out, amount1Out, address(this), data);
    }

    function triangularFlashLoanExecute(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        bytes memory _triangleData,
        bytes memory _userData
    ) private {

        // decode _triangleData
        (address _borrowPairAddress, uint _amountOfAgainstToken) = abi.decode(_triangleData, (address, uint));
        (,,,,,address _payPairAddress,address againstToken) = abi.decode(_userData, (address, address, address, uint, address, address, address));

        // Step 3: Using a normal swap, trade that WETH for _tokenBorrow
        //        address token0 = IUniswapV2Pair(_borrowPairAddress).token0();
        //        address token1 = IUniswapV2Pair(_borrowPairAddress).token1();
        uint amount0Out = _tokenBorrow == IUniswapV2Pair(_borrowPairAddress).token0() ? _amount : 0;
        uint amount1Out = _tokenBorrow == IUniswapV2Pair(_borrowPairAddress).token1() ? _amount : 0;
        IERC20(againstToken).transfer(_borrowPairAddress, _amountOfAgainstToken);

        // send our flash-borrowed againstToken to the pair
        IUniswapV2Pair(_borrowPairAddress).swap(amount0Out, amount1Out, address(this), bytes(""));

        // gas efficiency
        uint pairBalanceAgainstToken = IERC20(againstToken).balanceOf(_payPairAddress);
        uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(_payPairAddress);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amountOfAgainstToken) / (997 * pairBalanceAgainstToken)) + 1;

        // Step 4: Do whatever the user wants (arb, liqudiation, etc)
        execute(_tokenBorrow, _amount, _tokenPay, amountToRepay, _userData);

        // Step 5: Pay back the flash-borrow to the _tokenPay/WETH pool
        _approveMaxInternal(_tokenPay,_payPairAddress,amountToRepay);
        IERC20(_tokenPay).transfer(_payPairAddress, amountToRepay);

    }



    // 执行
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {

        (address _marketBorrow, address _marketCollateral, address borrower, uint repayAmount,,,) = abi.decode(_userData, (address, address, address, uint, address, address, address));

        _enterMarket(_marketBorrow, _marketCollateral);

        // 执行清算
        if (_isEthToken(_marketBorrow)) {
            IEthToken(_marketBorrow).liquidateBorrow{value : repayAmount}(borrower, _marketCollateral);
        } else {
            _approveMaxInternal(IErcToken(_marketBorrow).underlying(), _marketBorrow, repayAmount);
            IErcToken(_marketBorrow).liquidateBorrow(borrower, repayAmount, _marketCollateral);
        }

        // 执行赎回
        uint collateralBalance = IToken(_marketCollateral).balanceOf(address(this));
        require(collateralBalance > 0, "collateralBalance is zero");
        IToken(_marketCollateral).redeem(collateralBalance);

    }


    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) public view returns (uint) {
        if (_input == ETH) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }

    function transfer(address _asset, address payable _to, uint _amount) public onlyOwner {
        uint balance = getBalanceOf(_asset);
        if (balance < _amount) {
            _amount = balance;
        }

        if (_asset == ETH) {
            (bool success,) = _to.call{value : _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_asset).safeTransfer(_to, _amount);
    }

    function _enterMarket(address _tokenBorrow, address _tokenCollateral) internal {
        IComptroller comptroller = IComptroller(IToken(_tokenBorrow).comptroller());
        address[] memory pTokens = new address[](2);
        pTokens[0] = _tokenBorrow;
        pTokens[1] = _tokenCollateral;
        comptroller.enterMarkets(pTokens);
    }

    function _approveMaxInternal(address _asset, address _spender, uint amount) internal {
        IERC20 erc20 = IERC20(_asset);
        uint allowance = erc20.allowance(address(this), _spender);
        if (allowance < amount) {
            uint MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            erc20.safeApprove(_spender, MAX_INT);
        }
    }


    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _isEthToken(address ethToken) internal view returns (bool){
        return ethTokens[ethToken];
    }

    receive() payable external {}
}