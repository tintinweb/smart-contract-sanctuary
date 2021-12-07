/**
 *Submitted for verification at FtmScan.com on 2021-12-07
*/

// File: @openzeppelin/contracts/utils/math/Math.sol



pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: Crowdsale/Crowdsale_new.sol



pragma solidity ^0.8.0;






/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */

contract Crowdsale is Context, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    
    // the token being sold
    IERC20 private token;

    // the token being invested
    IERC20 private tokenToDeposit;
    
    // address where funds are collected
    address private wallet;
    
    // number of tokens bought by the investor
    mapping(address => uint256) public balanceToClaim;
    
    // amount of fund deposited by the investor
    mapping(address => uint256) public balanceDeposited;
    
    // tracks the amount of project tokens to be claimed
    uint256 public totalTokensToBeClaimed;
    
    // tracks the total supply of project tokens for the ICO
    uint256 public crowdsaleCap;
    
    bool public onSale;
    bool public canWithdraw;
    
    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private rate;
    
    // amount of wei raised
    uint256 private _weiRaised;
    
    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    /**
     * Event for token withdrawn logging
     * @param beneficiary who paid for the tokens
     * @param amount amount of tokens withdrawn
     */
    event TokensWithdrawn(address indexed beneficiary, uint256 indexed amount);
    
    /**
     * rate Number of token units a buyer gets per wei
     * @dev The _rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    constructor (uint256 _rate, uint256 _crowdsaleCap, address  _wallet, IERC20 _token, IERC20 _tokenToDeposit)
    {
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(_token) != address(0), "Crowdsale: token is the zero address");
        require(address(_tokenToDeposit) != address(0), "_tokenToDeposit: ETHtoken is the zero address");

        rate = _rate;
        crowdsaleCap = _crowdsaleCap;
        wallet = _wallet;
        token = _token;
        tokenToDeposit = _tokenToDeposit;
        canWithdraw = false;
    }
    
    //------------------------------------------------------------------------------//
    //                              CLIENT FUNCTIONS                                //
    //------------------------------------------------------------------------------//
    
    /**
     * @param _beneficiary address of the benefeciary that withdraw their tokens.
     */
    function claimTokens(address _beneficiary) public nonReentrant
    {
        require(canWithdraw == true, "You cannot claim yet.");
        uint256 _claimTokens = balanceToClaim[_beneficiary];
        balanceToClaim[_beneficiary] = 0;
        _deliverTokens(_beneficiary, _claimTokens);
        
        emit TokensWithdrawn(_beneficiary, _claimTokens);
    }
    
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function buyTokens(address _beneficiary, uint256 value) public nonReentrant
    {
        require(onSale == true , "The crowdsale has (not started) / (ended).");
    
        // calculate token amount to be created
        uint256 tokens = getTokenAmount(value);
        _preValidatePurchase(_beneficiary, value, tokens);
        _forwardFunds(value);

        // allocate the number of tokens to the investor
        _processPurchase(_beneficiary, tokens, value);
        
        emit TokensPurchased(_msgSender(), _beneficiary, value, tokens);
    
        _updatePurchasingState(_beneficiary, value);
        _postValidatePurchase(_beneficiary, value);
    }
    
    //------------------------------------------------------------------------------//
    //                              VIEW FUNCTIONS                                  //
    //------------------------------------------------------------------------------//

    /**
     * @return the token being sold.
     */
    function getProjectToken() public view returns (IERC20) {
        return token;
    }

    /**
     * @return the token being deposited.
     */
    function getTokenToDeposit() public view returns (IERC20) {
        return tokenToDeposit;
    }
    
    /**
     * @return the address where funds are collected.
     */
    function getCrowdsaleWallet() public view returns (address ) {
        return wallet;
    }
    
    /**
     * @return the number of token units a buyer gets per wei.
     */
    function getRate() public view returns (uint256) {
        return rate;
    }

    function getRemainingICOBalance() public view returns (uint256) {
        return crowdsaleCap - totalTokensToBeClaimed;
    }
    
    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        return weiAmount * rate;
    }
    
    //------------------------------------------------------------------------------//
    //                              ADMIN FUNCTIONS                                 //
    //------------------------------------------------------------------------------//
    
    /**
     * starts the Crowdsale.
     */
    function startCrowdsale()
        public
        onlyOwner
    {
        onSale = true;
    }
    
    /**
     * ends the Crowdsale.
     */
    function endCrowdsale()
        public
        onlyOwner
    {
        onSale = false; // revert -- crowdsale has not concluded
    }
    
    /**
     * enables the investors to withdraw their tokens.
     * only after the Crowdsale has ended.
     */
    function enableWithdraw()
        public
        onlyOwner
    {
        require(onSale == false);
        canWithdraw = true;
    }
    
    //------------------------------------------------------------------------------//
    //                              INTERNAL FUNCTIONS                              //
    //------------------------------------------------------------------------------//

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount)
        internal
        virtual
    {
        // implemented in AllowanceCrowdsale
        // token.transfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 _value)
        internal
    {
        tokenToDeposit.safeTransferFrom(msg.sender, wallet, _value);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        // ssh -- unused
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 _tokens)
        internal
        virtual
    {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount, uint256 value)
        internal
    {
        balanceToClaim[beneficiary] = balanceToClaim[beneficiary] + tokenAmount;
        balanceDeposited[beneficiary] = balanceDeposited[beneficiary] + value;
        totalTokensToBeClaimed = totalTokensToBeClaimed + tokenAmount;

        // update state
        _weiRaised = _weiRaised + value;
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount)
       internal
    {
        // ssh -- unused
        // solhint-disable-previous-line no-empty-blocks
    }
    
}
// File: Crowdsale/AllowanceCrowdsale_new.sol



pragma solidity ^0.8.0;





/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
abstract contract AllowanceCrowdsale is Crowdsale {
    using SafeERC20 for IERC20;

    address private projectTokenWallet;

    /**
     * @dev Constructor, takes token wallet address.
     * @param _projectTokenWallet Address holding the tokens, which has approved allowance to the crowdsale.
     */
    constructor (address _projectTokenWallet) {
        require(_projectTokenWallet != address(0), "AllowanceCrowdsale: project token wallet is the zero address");
        projectTokenWallet = _projectTokenWallet;
    }

    /**
     * @return the address of the wallet that will hold the tokens.
     */
    function getProjectTokenWallet() public view returns (address) {
        return projectTokenWallet;
    }

    /**
     * @dev Checks the amount of tokens left in the allowance.
     * @return Amount of tokens left in the allowance
     */
    function remainingTokens() public view returns (uint256) {
        return Math.min(getProjectToken().balanceOf(projectTokenWallet), getProjectToken().allowance(projectTokenWallet, address(this)));
    }

    /**
     * @dev Overrides parent behavior by transferring tokens from wallet.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual override {
        getProjectToken().safeTransferFrom(projectTokenWallet, beneficiary, tokenAmount);
    }
    
}

// File: Crowdsale/crowdsale.sol



pragma solidity ^0.8.0;




contract ICOSale is Ownable, Crowdsale, AllowanceCrowdsale {
    
    /**
     * Individual allocations.
     * maxCap refers to the maximum allocation (in terms of ETH).
     * minCap refers to the minimum allocation (in terms of ETH).
    */
    uint256 public minCap;
    uint256 public maxCap;
    
    // people whitelisted for the Stage1 of the crowdsale.
    mapping(address => bool) public isWhitelisted;
    
    /**
     * @param Stage1 representing the stage when only whitelisted people can invest.
     * @param Stage2 representing the stage when anyone can invest.
     * can be changed by calling the setCrowdsaleStage function.
     * By default it is initiated as Stage1.
    */
    enum CrowdsaleStage { Stage1, Stage2 }
    CrowdsaleStage public crowdsaleStage = CrowdsaleStage.Stage1;
    
    /**
     * Reference - https://docs.openzeppelin.com/contracts/2.x/api/crowdsale#Crowdsale-constructor-uint256-address-payable-contract-IERC20-
    */
    constructor(
        uint256 _rate,
        uint256 _crowdsaleCap,
        address _wallet,
        IERC20 _token,
        IERC20 _tokenToDeposit,
        address _projectTokenWallet,
        uint256 _minCap,
        uint256 _maxCap
    )
    Crowdsale(_rate, _crowdsaleCap, _wallet, _token, _tokenToDeposit)
    AllowanceCrowdsale(_projectTokenWallet)
    {
        minCap = _minCap;
        maxCap = _maxCap;
    }
    
    receive() external payable {
        revert();
    }

    //------------------------------------------------------------------------------//
    //                              ADMIN FUNCTIONS                                 //
    //------------------------------------------------------------------------------//
    
    // Add a single person to whitelist.
    function addToWhitelist(address _beneficiary)
        external
        onlyOwner
    {
      isWhitelisted[_beneficiary] = true;
    }
    
    // Add an array of people to whitelist.
    function addManyToWhitelist(address[] calldata _beneficiaries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            isWhitelisted[_beneficiaries[i]] = true;
        }
    }
    
    // Set the stage of the Crowdsale.
    function setCrowdsaleStage(uint256 _stage)
        public
        onlyOwner
    {
        require(_stage == 0 || _stage == 1, "Crowdsale: Stage can be either 0 or 1.");
        if (uint8(CrowdsaleStage.Stage1) == _stage) {
            crowdsaleStage = CrowdsaleStage.Stage1;
        } else if (uint8(CrowdsaleStage.Stage2) == _stage) {
            crowdsaleStage = CrowdsaleStage.Stage2;
        }
    }
    
    //------------------------------------------------------------------------------//
    //                              INTERNAL FUNCTIONS                              //
    //------------------------------------------------------------------------------//
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokens)
        internal
        view
        override
    {
        require((_beneficiary != address(0)) || (msg.sender != address(0)), "Crowdsale: zero address");
        require(_weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(balanceDeposited[_beneficiary] + _weiAmount >= minCap &&
                balanceDeposited[_beneficiary] + _weiAmount <= maxCap, "Crowdsale: cannot buy outside the allocated range.");
        require(_tokens <= getRemainingICOBalance(), "Crowdsale: insufficient crowdsale token balance.");
        
        if (crowdsaleStage == CrowdsaleStage.Stage1) {
            require(isWhitelisted[_beneficiary], "Crowdsale: This address has not been whitelisted.");
        } 
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
        virtual
        override(Crowdsale, AllowanceCrowdsale)
    {
        super._deliverTokens(_beneficiary, _tokenAmount);
    }
  
}