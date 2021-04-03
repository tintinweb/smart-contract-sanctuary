/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// File: original_contracts/IWhitelisted.sol

pragma solidity 0.7.5;


interface IWhitelisted {

    function hasRole(
        bytes32 role,
        address account
    )
        external
        view
        returns (bool);

    function WHITELISTED_ROLE() external view returns(bytes32);
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: original_contracts/lib/IExchange.sol

pragma solidity 0.7.5;



/**
* @dev This interface should be implemented by all exchanges which needs to integrate with the paraswap protocol
*/
interface IExchange {

    /**
   * @dev The function which performs the swap on an exchange.
   * Exchange needs to implement this method in order to support swapping of tokens through it
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param exchange Internal exchange or factory contract address for the exchange. For example Registry address for the Uniswap
   * @param payload Any exchange specific data which is required can be passed in this argument in encoded format which
   * will be decoded by the exchange. Each exchange will publish it's own decoding/encoding mechanism
   */
   //TODO: REMOVE RETURN STATEMENT
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload) external payable;

  /**
   * @dev The function which performs the swap on an exchange.
   * Exchange needs to implement this method in order to support swapping of tokens through it
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Max Amount of source tokens to be swapped
   * @param toAmount Destination token amount expected out of this swap
   * @param exchange Internal exchange or factory contract address for the exchange. For example Registry address for the Uniswap
   * @param payload Any exchange specific data which is required can be passed in this argument in encoded format which
   * will be decoded by the exchange. Each exchange will publish it's own decoding/encoding mechanism
   */
    function buy(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload) external payable;

    /**
   * @dev This function is used to perform onChainSwap. It build all the parameters onchain. Basically the information
   * encoded in payload param of swap will calculated in this case
   * Exchange needs to implement this method in order to support swapping of tokens through it
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   */
    function onChainSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) external payable returns (uint256);

    /**
    * @dev Certain adapters/exchanges needs to be initialized.
    * This method will be called from Augustus
    */
    function initialize(bytes calldata data) external;

    /**
    * @dev Returns unique identifier for the adapter
    */
    function getKey() external pure returns(bytes32);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: original_contracts/lib/SafeERC20.sol

pragma solidity 0.7.5;




library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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


library SafeERC20 {
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: original_contracts/ITokenTransferProxy.sol

pragma solidity 0.7.5;


interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;

    function freeReduxTokens(address user, uint256 tokensToFree) external;
}

// File: original_contracts/lib/Utils.sol

pragma solidity 0.7.5;






library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    address constant WETH_ADDRESS = address(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );

    uint256 constant MAX_UINT = 2 ** 256 - 1;

    /**
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param referrer referral id
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Utils.Path[] path;

    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Utils.MegaSwapPath[] path;
    }

    struct BuyData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Utils.BuyRoute[] route;
    }

    struct Route {
        address payable exchange;
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Route[] routes;
    }

    struct BuyRoute {
        address payable exchange;
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    function ethAddress() internal pure returns (address) {return ETH_ADDRESS;}

    function wethAddress() internal pure returns (address) {return WETH_ADDRESS;}

    function maxUint() internal pure returns (uint256) {return MAX_UINT;}

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
    internal
    {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{value: amount, gas: 4000}("");
                require(result, "Failed to transfer Ether");
            }
            else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }

    }

    function tokenBalance(
        address token,
        address account
    )
    internal
    view
    returns (uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /**
    * @dev Helper method to refund gas using gas tokens
    */
    function refundGas(
        address account,
        address tokenTransferProxy,
        uint256 initialGas
    )
        internal
    {
        uint256 freeBase = 14154;
        uint256 freeToken = 6870;
        uint256 reimburse = 24000;

        uint256 tokens = initialGas.sub(
            gasleft()).add(freeBase).div(reimburse.mul(2).sub(freeToken)
        );

        freeGasTokens(account, tokenTransferProxy, tokens);
    }

    /**
    * @dev Helper method to free gas tokens
    */
    function freeGasTokens(address account, address tokenTransferProxy, uint256 tokens) internal {

        uint256 tokensToFree = tokens;
        uint256 safeNumTokens = 0;
        uint256 gas = gasleft();

        if (gas >= 27710) {
            safeNumTokens = gas.sub(27710).div(1148 + 5722 + 150);
        }

        if (tokensToFree > safeNumTokens) {
            tokensToFree = safeNumTokens;
        }
        ITokenTransferProxy(tokenTransferProxy).freeReduxTokens(account, tokensToFree);
    }
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: original_contracts/IReduxToken.sol

pragma solidity 0.7.5;

interface IReduxToken {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function mint(uint256 value) external;
}

// File: original_contracts/TokenTransferProxy.sol

pragma solidity 0.7.5;







/**
* @dev Allows owner of the contract to transfer tokens on behalf of user.
* User will need to approve this contract to spend tokens on his/her behalf
* on Paraswap platform
*/
contract TokenTransferProxy is Ownable, ITokenTransferProxy {
    using SafeERC20 for IERC20;

    IReduxToken public reduxToken;

    constructor(address _reduxToken) public {
        reduxToken = IReduxToken(_reduxToken);
    }

    /**
    * @dev Allows owner of the contract to transfer tokens on user's behalf
    * @dev Swapper contract will be the owner of this contract
    * @param token Address of the token
    * @param from Address from which tokens will be transferred
    * @param to Receipent address of the tokens
    * @param amount Amount of tokens to transfer
    */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external
        override
        onlyOwner
    {
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    function freeReduxTokens(address user, uint256 tokensToFree) external override onlyOwner {
        reduxToken.freeFromUpTo(user, tokensToFree);
    }

}

// File: original_contracts/IPartnerRegistry.sol

pragma solidity 0.7.5;


interface IPartnerRegistry {

    function getPartnerContract(string calldata referralId) external view returns(address);

}

// File: original_contracts/IPartner.sol

pragma solidity 0.7.5;


interface IPartner {

    function getPartnerInfo() external view returns(
        address payable feeWallet,
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare,
        bool positiveSlippageToUser,
        bool noPositiveSlippage
    );
}

// File: original_contracts/lib/TokenFetcherAugustus.sol

pragma solidity 0.7.5;



contract TokenFetcherAugustus {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    /**
    * @dev Allows owner of the contract to transfer any tokens which are assigned to the contract
    * This method is for safety if by any chance tokens or ETHs are assigned to the contract by mistake
    * @dev token Address of the token to be transferred
    * @dev destination Recepient of the token
    * @dev amount Amount of tokens to be transferred
    */
    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
        external
        onlyOwner
    {
        Utils.transferTokens(token, destination, amount);
    }
}

// File: original_contracts/IWETH.sol

pragma solidity 0.7.5;



abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}

// File: original_contracts/IUniswapProxy.sol

pragma solidity 0.7.5;


interface IUniswapProxy {
    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        returns (uint256);

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        returns (uint256);

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        returns (uint256 tokensSold);

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        returns (uint256 tokensSold);

   function setupTokenSpender(address tokenSpender) external;

}

// File: original_contracts/AdapterStorage.sol

pragma solidity 0.7.5;



contract AdapterStorage {

    mapping (bytes32 => bool) internal adapterInitialized;
    mapping (bytes32 => bytes) internal adapterVsData;
    ITokenTransferProxy internal _tokenTransferProxy;

    function isInitialized(bytes32 key) public view returns(bool) {
        return adapterInitialized[key];
    }

    function getData(bytes32 key) public view returns(bytes memory) {
        return adapterVsData[key];
    }

    function getTokenTransferProxy() public view returns (address) {
        return address(_tokenTransferProxy);
    }
}

// File: original_contracts/AugustusSwapper.sol

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;













contract AugustusSwapper is AdapterStorage, TokenFetcherAugustus {
    using SafeMath for uint256;

    IWhitelisted private _whitelisted;

    IPartnerRegistry private _partnerRegistry;

    address payable private _feeWallet;

    address private _uniswapProxy;

    address private _pendingUniswapProxy;

    uint256 private _changeRequestedBlock;

    //Number of blocks after which UniswapProxy change can be confirmed
    uint256 private _timelock;

    event Swapped(
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount,
        string referrer
    );

    event Bought(
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        string referrer
    );

    event FeeTaken(
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare
    );

    event AdapterInitialized(address indexed adapter);

    modifier onlySelf() {
        require(
            msg.sender == address(this),
            "AugustusSwapper: Invalid access"
        );
        _;
    }

    receive () payable external {

    }

    function getTimeLock() external view returns(uint256) {
      return _timelock;
    }

    function initialize(
        address whitelist,
        address reduxToken,
        address partnerRegistry,
        address payable feeWallet,
        address uniswapProxy,
        uint256 timelock
    )
        external
    {
        require(address(_tokenTransferProxy) == address(0), "Contract already initialized!!");
        _partnerRegistry = IPartnerRegistry(partnerRegistry);
        TokenTransferProxy lTokenTransferProxy = new TokenTransferProxy(reduxToken);
        _tokenTransferProxy = ITokenTransferProxy(lTokenTransferProxy);
        _whitelisted = IWhitelisted(whitelist);
        _feeWallet = feeWallet;
        _uniswapProxy = uniswapProxy;
        _owner = msg.sender;
        _timelock = timelock;
    }

    function initializeAdapter(address adapter, bytes calldata data) external onlyOwner {

        require(
            _whitelisted.hasRole(_whitelisted.WHITELISTED_ROLE(), adapter),
            "Exchange not whitelisted"
        );
        (bool success,) = adapter.delegatecall(abi.encodeWithSelector(IExchange.initialize.selector, data));
        require(success, "Failed to initialize adapter");
        emit AdapterInitialized(adapter);
    }

    function getPendingUniswapProxy() external view returns(address) {
      return  _pendingUniswapProxy;
    }

    function getChangeRequestedBlock() external view returns(uint256) {
      return _changeRequestedBlock;
    }

    function getUniswapProxy() external view returns(address) {
        return _uniswapProxy;
    }

    function getVersion() external view returns(string memory) {
        return "4.0.0";
    }

    function getPartnerRegistry() external view returns(address) {
        return address(_partnerRegistry);
    }

    function getWhitelistAddress() external view returns(address) {
        return address(_whitelisted);
    }

    function getFeeWallet() external view returns(address) {
        return _feeWallet;
    }

    function changeUniswapProxy(address uniswapProxy) external onlyOwner {
        require(uniswapProxy != address(0), "Invalid address");
        _changeRequestedBlock = block.number;
        _pendingUniswapProxy = uniswapProxy;
    }

    function confirmUniswapProxyChange() external onlyOwner {
        require(
            block.number >= _changeRequestedBlock.add(_timelock),
            "Time lock check failed"
        );

        require(_pendingUniswapProxy != address(0), "No pending request");

        _changeRequestedBlock = 0;
        _uniswapProxy = _pendingUniswapProxy;
        _pendingUniswapProxy = address(0);
    }

    function setFeeWallet(address payable feeWallet) external onlyOwner {
        require(feeWallet != address(0), "Invalid address");
        _feeWallet = feeWallet;
    }

    function setPartnerRegistry(address partnerRegistry) external onlyOwner {
        require(partnerRegistry != address(0), "Invalid address");
        _partnerRegistry = IPartnerRegistry(partnerRegistry);
    }

    function setWhitelistAddress(address whitelisted) external onlyOwner {
        require(whitelisted != address(0), "Invalid whitelist address");
        _whitelisted = IWhitelisted(whitelisted);
    }

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable
    {
        //DELEGATING CALL TO THE ADAPTER
        (bool success, bytes memory result) = _uniswapProxy.delegatecall(
            abi.encodeWithSelector(
                IUniswapProxy.swapOnUniswap.selector,
                amountIn,
                amountOutMin,
                path
            )
        );
        require(success, "Call to uniswap proxy failed");

    }

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable
    {
        //DELEGATING CALL TO THE ADAPTER
        (bool success, bytes memory result) = _uniswapProxy.delegatecall(
            abi.encodeWithSelector(
                IUniswapProxy.buyOnUniswap.selector,
                amountInMax,
                amountOut,
                path
            )
        );
        require(success, "Call to uniswap proxy failed");

    }

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable
    {
        //DELEGATING CALL TO THE ADAPTER
        (bool success, bytes memory result) = _uniswapProxy.delegatecall(
            abi.encodeWithSelector(
                IUniswapProxy.buyOnUniswapFork.selector,
                factory,
                initCode,
                amountInMax,
                amountOut,
                path
            )
        );
        require(success, "Call to uniswap proxy failed");

    }

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable

    {
        //DELEGATING CALL TO THE ADAPTER
        (bool success, bytes memory result) = _uniswapProxy.delegatecall(
            abi.encodeWithSelector(
                IUniswapProxy.swapOnUniswapFork.selector,
                factory,
                initCode,
                amountIn,
                amountOutMin,
                path
            )
        );
        require(success, "Call to uniswap proxy failed");

    }

    function simplBuy(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        external
        payable

    {
        beneficiary = beneficiary == address(0) ? msg.sender : beneficiary;
        uint receivedAmount = performSimpleSwap(
            fromToken,
            toToken,
            fromAmount,
            toAmount,
            toAmount,//expected amount and to amount are same in case of buy
            callees,
            exchangeData,
            startIndexes,
            values,
            beneficiary,
            referrer,
            useReduxToken
        );

        uint256 remainingAmount = Utils.tokenBalance(
            fromToken,
            address(this)
        );

        if (remainingAmount > 0) {
            Utils.transferTokens(address(fromToken), msg.sender, remainingAmount);
        }

        emit Bought(
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            referrer
        );
    }

    function approve(
        address token,
        address to,
        uint256 amount
    )
        external
        onlySelf
    {
        Utils.approve(to, token, amount);
    }

    function simpleSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        public
        payable
        returns (uint256 receivedAmount)
    {
        beneficiary = beneficiary == address(0) ? msg.sender : beneficiary;
        receivedAmount = performSimpleSwap(
            fromToken,
            toToken,
            fromAmount,
            toAmount,
            expectedAmount,
            callees,
            exchangeData,
            startIndexes,
            values,
            beneficiary,
            referrer,
            useReduxToken
        );

        emit Swapped(
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            expectedAmount,
            referrer
        );

        return receivedAmount;
    }

    function transferTokensFromProxy(
        address token,
        uint256 amount
    )
      private
    {
        if (token != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                token,
                msg.sender,
                address(this),
                amount
            );
        }
    }

    function performSimpleSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        private
        returns (uint256 receivedAmount)
    {
        require(toAmount > 0, "toAmount is too low");
        require(
            callees.length + 1 == startIndexes.length,
            "Start indexes must be 1 greater then number of callees"
        );

        uint initialGas = gasleft();

        //If source token is not ETH than transfer required amount of tokens
        //from sender to this contract
        transferTokensFromProxy(fromToken, fromAmount);

        for (uint256 i = 0; i < callees.length; i++) {
            require(
                callees[i] != address(_tokenTransferProxy),
                "Can not call TokenTransferProxy Contract"
            );

            bool result = externalCall(
                callees[i], //destination
                values[i], //value to send
                startIndexes[i], // start index of call data
                startIndexes[i + 1].sub(startIndexes[i]), // length of calldata
                exchangeData// total calldata
            );
            require(result, "External call failed");
        }

        receivedAmount = Utils.tokenBalance(
            toToken,
            address(this)
        );

        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected"
        );

        takeFeeAndTransferTokens(
            toToken,
            expectedAmount,
            receivedAmount,
            beneficiary,
            referrer
        );

        if (useReduxToken) {
            Utils.refundGas(msg.sender, address(_tokenTransferProxy), initialGas);
        }

        return receivedAmount;
    }

    /**
   * @dev This function sends the WETH returned during the exchange to the user.
   * @param token: The WETH Address
   */
    function withdrawAllWETH(IWETH token) external onlySelf {
        uint256 amount = token.balanceOf(address(this));
        token.withdraw(amount);
    }

    /**
   * @dev The function which performs the multi path swap.
   * @param data Data required to perform swap.
   */
    function multiSwap(
        Utils.SellData memory data
    )
        public
        payable
        returns (uint256)
    {
        uint initialGas = gasleft();

        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 toAmount = data.toAmount;
        uint256 expectedAmount = data.expectedAmount;
        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;
        string memory referrer = data.referrer;
        Utils.Path[] memory path = data.path;
        address toToken = path[path.length - 1].to;
        bool useReduxToken = data.useReduxToken;

        //Referral can never be empty
        require(bytes(referrer).length > 0, "Invalid referrer");

        require(toAmount > 0, "To amount can not be 0");

        //if fromToken is not ETH then transfer tokens from user to this contract
        if (fromToken != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                fromToken,
                msg.sender,
                address(this),
                fromAmount
            );
        }

        performSwap(
            fromToken,
            fromAmount,
            path
        );


        uint256 receivedAmount = Utils.tokenBalance(
            toToken,
            address(this)
        );

        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected"
        );


        takeFeeAndTransferTokens(
            toToken,
            expectedAmount,
            receivedAmount,
            beneficiary,
            referrer
        );

        if (useReduxToken) {
            Utils.refundGas(msg.sender, address(_tokenTransferProxy), initialGas);
        }

        emit Swapped(
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            expectedAmount,
            referrer
        );

        return receivedAmount;
    }

    /**
   * @dev The function which performs the mega path swap.
   * @param data Data required to perform swap.
   */
    function megaSwap(
        Utils.MegaSwapSellData memory data
    )
        public
        payable
        returns (uint256)
    {
        uint initialGas = gasleft();

        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 toAmount = data.toAmount;
        uint256 expectedAmount = data.expectedAmount;
        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;
        string memory referrer = data.referrer;
        Utils.MegaSwapPath[] memory path = data.path;
        address toToken = path[0].path[path[0].path.length - 1].to;
        bool useReduxToken = data.useReduxToken;

        //Referral can never be empty
        require(bytes(referrer).length > 0, "Invalid referrer");

        require(toAmount > 0, "To amount can not be 0");

        //if fromToken is not ETH then transfer tokens from user to this contract
        if (fromToken != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                fromToken,
                msg.sender,
                address(this),
                fromAmount
            );
        }

        for (uint8 i = 0; i < uint8(path.length); i++) {
            uint256 _fromAmount = fromAmount.mul(path[i].fromAmountPercent).div(10000);
            if (i == path.length - 1) {
                _fromAmount = Utils.tokenBalance(address(fromToken), address(this));
            }
            performSwap(
                fromToken,
                _fromAmount,
                path[i].path
            );
        }

        uint256 receivedAmount = Utils.tokenBalance(
            toToken,
            address(this)
        );

        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected"
        );


        takeFeeAndTransferTokens(
            toToken,
            expectedAmount,
            receivedAmount,
            beneficiary,
            referrer
        );

        if (useReduxToken) {
            Utils.refundGas(msg.sender, address(_tokenTransferProxy), initialGas);
        }

        emit Swapped(
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            expectedAmount,
            referrer
        );

        return receivedAmount;
    }

    /**
   * @dev The function which performs the single path buy.
   * @param data Data required to perform swap.
   */
    function buy(
        Utils.BuyData memory data
    )
        public
        payable
        returns (uint256)
    {

        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 toAmount = data.toAmount;
        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;
        string memory referrer = data.referrer;
        Utils.BuyRoute[] memory route = data.route;
        address toToken = data.toToken;
        bool useReduxToken = data.useReduxToken;

        //Referral id can never be empty
        require(bytes(referrer).length > 0, "Invalid referrer");

        require(toAmount > 0, "To amount can not be 0");

        uint256 receivedAmount = performBuy(
            fromToken,
            toToken,
            fromAmount,
            toAmount,
            route,
            useReduxToken
        );

        takeFeeAndTransferTokens(
            toToken,
            toAmount,
            receivedAmount,
            beneficiary,
            referrer
        );

        uint256 remainingAmount = Utils.tokenBalance(
            fromToken,
            address(this)
        );

        if (remainingAmount > 0) {
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        }

        emit Bought(
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            referrer
        );

        return receivedAmount;
    }

    //Helper function to transfer final amount to the beneficiaries
    function takeFeeAndTransferTokens(
        address toToken,
        uint256 expectedAmount,
        uint256 receivedAmount,
        address payable beneficiary,
        string memory referrer

    )
        private
    {
        uint256 remainingAmount = receivedAmount;

        address partnerContract = _partnerRegistry.getPartnerContract(referrer);

        //Take partner fee
        ( uint256 fee ) = _takeFee(
            toToken,
            receivedAmount,
            expectedAmount,
            partnerContract
        );
        remainingAmount = receivedAmount.sub(fee);

        //If there is a positive slippage after taking partner fee then 50% goes to paraswap and 50% to the user
        if ((remainingAmount > expectedAmount) && fee == 0) {
            uint256 positiveSlippageShare = remainingAmount.sub(expectedAmount).div(2);
            remainingAmount = remainingAmount.sub(positiveSlippageShare);
            Utils.transferTokens(toToken, _feeWallet, positiveSlippageShare);
        }

        Utils.transferTokens(toToken, beneficiary, remainingAmount);


    }

    /**
    * @dev Source take from GNOSIS MultiSigWallet
    * @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
    */
    function externalCall(
        address destination,
        uint256 value,
        uint256 dataOffset,
        uint dataLength,
        bytes memory data
    )
    private
    returns (bool)
    {
        bool result = false;

        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)

            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                add(d, dataOffset),
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    //Helper function to perform swap
    function performSwap(
        address fromToken,
        uint256 fromAmount,
        Utils.Path[] memory path
    )
        private
    {

        require(path.length > 0, "Path not provided for swap");

        //Assuming path will not be too long to reach out of gas exception
        for (uint i = 0; i < path.length; i++) {
            //_fromToken will be either fromToken or toToken of the previous path
            address _fromToken = i > 0 ? path[i - 1].to : fromToken;
            address _toToken = path[i].to;

            uint256 _fromAmount = i > 0 ? Utils.tokenBalance(_fromToken, address(this)) : fromAmount;
            if (i > 0 && _fromToken == Utils.ethAddress()) {
                _fromAmount = _fromAmount.sub(path[i].totalNetworkFee);
            }

            for (uint j = 0; j < path[i].routes.length; j++) {
                Utils.Route memory route = path[i].routes[j];

                //Check if exchange is supported
                require(
                    _whitelisted.hasRole(_whitelisted.WHITELISTED_ROLE(), route.exchange),
                    "Exchange not whitelisted"
                );

                //Calculating tokens to be passed to the relevant exchange
                //percentage should be 200 for 2%
                uint fromAmountSlice = _fromAmount.mul(route.percent).div(10000);
                uint256 value = route.networkFee;

                if (i > 0 && j == path[i].routes.length.sub(1)) {
                    uint256 remBal = Utils.tokenBalance(address(_fromToken), address(this));

                    fromAmountSlice = remBal;

                    if (address(_fromToken) == Utils.ethAddress()) {
                        //subtract network fee
                        fromAmountSlice = fromAmountSlice.sub(value);
                    }
                }

                //DELEGATING CALL TO THE ADAPTER
                (bool success,) = route.exchange.delegatecall(
                    abi.encodeWithSelector(
                        IExchange.swap.selector,
                        _fromToken,
                        _toToken,
                        fromAmountSlice,
                        1,
                        route.targetExchange,
                        route.payload
                    )
                );

                require(success, "Call to adapter failed");
            }
        }
    }

    //Helper function to perform swap
    function performBuy(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        Utils.BuyRoute[] memory routes,
        bool useReduxToken
    )
        private
        returns(uint256)
    {
        uint initialGas = gasleft();

        //if fromToken is not ETH then transfer tokens from user to this contract
        if (fromToken != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                fromToken,
                msg.sender,
                address(this),
                fromAmount
            );
        }

        for (uint j = 0; j < routes.length; j++) {
            Utils.BuyRoute memory route = routes[j];

            //Check if exchange is supported
            require(
                _whitelisted.hasRole(_whitelisted.WHITELISTED_ROLE(), route.exchange),
                "Exchange not whitelisted"
            );

            //delegate Call to the exchange
            (bool success,) = route.exchange.delegatecall(
                abi.encodeWithSelector(
                    IExchange.buy.selector,
                    fromToken,
                    toToken,
                    route.fromAmount,
                    route.toAmount,
                    route.targetExchange,
                    route.payload
                )
            );
            require(success, "Call to adapter failed");
        }

        uint256 receivedAmount = Utils.tokenBalance(
            toToken,
            address(this)
        );
        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected tokens"
        );

        if (useReduxToken) {
            Utils.refundGas(msg.sender, address(_tokenTransferProxy), initialGas);
        }
        return receivedAmount;
    }

    function _takeFee(
        address toToken,
        uint256 receivedAmount,
        uint256 expectedAmount,
        address partnerContract
    )
        private
        returns(uint256 fee)
    {
        //If there is no partner associated with the referral id then no fee will be taken
        if (partnerContract == address(0)) {
            return (0);
        }

        (
            address payable partnerFeeWallet,
            uint256 feePercent,
            uint256 partnerSharePercent,
            ,
            bool positiveSlippageToUser,
            bool noPositiveSlippage
        ) = IPartner(partnerContract).getPartnerInfo();

        uint256 partnerShare = 0;
        uint256 paraswapShare = 0;

        if (!noPositiveSlippage && feePercent <= 50 && receivedAmount > expectedAmount) {
            uint256 halfPositiveSlippage = receivedAmount.sub(expectedAmount).div(2);
            //Calculate total fee to be taken
            fee = expectedAmount.mul(feePercent).div(10000);
            //Calculate partner's share
            partnerShare = fee.mul(partnerSharePercent).div(10000);
            //All remaining fee is paraswap's share
            paraswapShare = fee.sub(partnerShare);
            paraswapShare = paraswapShare.add(halfPositiveSlippage);

            fee = fee.add(halfPositiveSlippage);

            if (!positiveSlippageToUser) {
                partnerShare = partnerShare.add(halfPositiveSlippage);
                fee = fee.add(halfPositiveSlippage);
            }
        }
        else {
            //Calculate total fee to be taken
            fee = receivedAmount.mul(feePercent).div(10000);
            //Calculate partner's share
            partnerShare = fee.mul(partnerSharePercent).div(10000);
            //All remaining fee is paraswap's share
            paraswapShare = fee.sub(partnerShare);
        }
        Utils.transferTokens(toToken, partnerFeeWallet, partnerShare);
        Utils.transferTokens(toToken, _feeWallet, paraswapShare);

        emit FeeTaken(fee, partnerShare, paraswapShare);
        return (fee);
    }
}