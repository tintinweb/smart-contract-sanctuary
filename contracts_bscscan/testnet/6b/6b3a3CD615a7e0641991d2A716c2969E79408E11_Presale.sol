/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

//SPDX-License-Identifier: UNLICENSED

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
    constructor() {
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
     * by making the `nonReentrant` function external, and making it call a
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
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
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
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

contract Presale is  Ownable, Pausable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;
    
    event BuyOffer( address indexed user, uint indexed pSale, uint indexed _saleID, uint amount, uint qty, uint purchaseTime);
    event Claim( address indexed user, uint indexed pSale, uint indexed _saleID, uint releasedAmount, uint claimTime);
    
    mapping(address => mapping(uint => mapping(uint => UserInfo))) public userInfo; // user info
    mapping(uint => mapping(uint => uint)) public totalSoldTokens; // total sold token
    mapping(uint => mapping(uint => uint)) public totalOfferedTokens; // total released tokens
    mapping(uint => mapping(uint => uint)) public offeringAmount; // total amount of offeringToken that will offer
    
    struct UserInfo {
      uint balances; /* user offering token balance */
      uint lastClaimTime; /* last claim time in blocks */
      uint totalClaimAmount; /* total claim amount of the user */
      bool isClaimedAll; /* returns true if user claimed all his rewards */
    }
    
    // address of offering token
    IBEP20 public offeringToken;
    // The block number when presale starts
    uint256[2] public startBlock;
    // The block number when presale ends
    uint256[2] public endBlock;
    // price of offering token
    uint256[2] public offeringPrice = [0.00003e18, 0.00005e18];
    // total amount of raising tokens that have already raised
    uint256[2] public totalAmount;
    // The block time of 6 month for unlock period
    uint256[2] unlockBlock;  
    // The block time of offering release 
    uint256[2] releaseOfferingOnEvery; // one month
    // The block of launch
    uint256[2] public launchBlock;
    // THe block time of sale closed
    uint256[2] public closeBlock;
    uint[2] public claimRelease = [40 /* launch date */,10 /* month release */];
    // Number of current sale
    uint[2] public currentSale;
    
    // Active status of the presale
    bool[2] public isPresaleActive = [true, true];
    // Active status of the claim
    bool[2] public isClaimActive = [true, true];
    
    receive() external payable {
        revert("not active");
    }
    
    fallback() external {
        revert("No fallback calls");
    }
    
    modifier onlyPresales( uint _pSale) {
        require((_pSale == 0) || (_pSale == 1), "Presale :: onlyPresales : _pSale must be zero or one");
        _;
    }
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(IBEP20 _offeringToken) {
        require(_offeringToken != IBEP20(address(0)), "Presale :: initialize : offeringToken should not be zero address");
        offeringToken = _offeringToken;
    }
    
    function startNextSaleOne() external onlyOwner {
        uint256 _saleCloseBlock = launchBlock[0] + (unlockBlock[0] + closeBlock[0]);
        require(block.timestamp > _saleCloseBlock, "Presale :: startNextSaleOne : current time should be greater than close time");
        
        currentSale[0]++;
        totalSoldTokens[0][currentSale[0]] = 0;
        totalOfferedTokens[0][currentSale[0]] = 0;
    }
    
    function startNextSaleTwo() external onlyOwner {
        uint256 _saleCloseBlock = launchBlock[1] + (unlockBlock[1] + closeBlock[1]);
        require(block.timestamp > _saleCloseBlock, "Presale :: startNextSaleTwo : current time should be greater than close time");
        
        currentSale[1]++;
        totalSoldTokens[1][currentSale[1]] = 0;
        totalOfferedTokens[1][currentSale[1]] = 0;
    }
    
    /**
     * @dev Set launch block for sale one.
     * Can only be called by the current owner.
     */
    function setLaunchBlockSaleOne( uint256 _launchBlock) external onlyOwner {
        require(_launchBlock >= block.timestamp, "Presale :: setLaunchBlockSaleOne : _launchBlock should be greater than current time");
        require((endBlock[0] != 0) && (_launchBlock > endBlock[0]), "setLaunchBlockSaleOne : _launchBlock should be greater than end block");
        
        launchBlock[0] = _launchBlock;
    }
    
    /**
     * @dev Set launch block for sale two.
     * Can only be called by the current owner.
     */
    function setLaunchBlockSaleTwo( uint256 _launchBlock) external onlyOwner {
        require(_launchBlock >= block.timestamp, "Presale :: setLaunchBlockSaleTwo : _launchBlock should be greater than current time");
        require((endBlock[1] != 0) && (_launchBlock > endBlock[1]), "Presale :: setLaunchBlockSaleTwo : _launchBlock should be greater than end block");
        
        launchBlock[1] = _launchBlock;
    }
    
    /**
     * @dev Set sale one configuration.
     * Can only be called by the current owner.
     */
    function setSaleOneConfig(uint256 _startBlock, uint256 _endBlock, uint256 _offeringAmount ) external onlyOwner {
        require(_startBlock > block.timestamp, "Presale ::  start block should > current time");
        require(_startBlock < _endBlock, "Presale :: startBlock should < endBlock");
        require(_offeringAmount > 0, "Presale :: offeringAmount > 0");
        
        if(startBlock[0] != 0)
            require((launchBlock[0] > 0) && (_startBlock > (launchBlock[0] + (unlockBlock[0] + closeBlock[0]))), "Presale :: previous sale isn't closed yet");
        
        startBlock[0] = _startBlock;
        endBlock[0] = _endBlock;
        offeringAmount[0][currentSale[0]] = _offeringAmount;
    }
    
    /**
     * @dev Set sale two configuration.
     * Can only be called by the current owner.
     */
    function setSaleTwoConfig(uint256 _startBlock, uint256 _endBlock, uint256 _offeringAmount ) external onlyOwner {
        require(_startBlock > block.timestamp, "Presale ::  start block should > current time");
        require(_startBlock < _endBlock, "Presale :: startBlock should < endBlock");
        require(_offeringAmount > 0, "Presale :: offeringAmount > 0");
        
        if(startBlock[1] != 0)
            require((launchBlock[1] > 0) && (_startBlock > (launchBlock[1] + (unlockBlock[1] + closeBlock[1]))), "Presale :: previous sale isn't closed yet");
            
        startBlock[1] = _startBlock;
        endBlock[1] = _endBlock;
        offeringAmount[1][currentSale[1]] = _offeringAmount;
    }
    
    /**
     * @dev Set sale one unblock, offer release, close block.
     * Can only be called by the current owner.
     */
    function setUnlockBlockSaleOne( uint256 _unlockBlock, uint _releaseOfferingOnEvery,  uint256 _closeBlock, uint _totalOfferRelease) external onlyOwner {
        require(_unlockBlock > 0, "Presale :: unlockBlock > 0");
        require(_releaseOfferingOnEvery > 0, "Presale :: _releaseOfferingOnEvery should > 0");
        require(_totalOfferRelease > 0, "Presale :: _totalOfferRelease should > 0");
        require(_closeBlock == (_releaseOfferingOnEvery * _totalOfferRelease), "Presale :: total offer release should equal to close block");
        
        unlockBlock[0] = _unlockBlock;
        releaseOfferingOnEvery[0] = _releaseOfferingOnEvery;
        closeBlock[0] = _closeBlock;
    }
    
    /**
     * @dev Set sale one unblock, offer release, close block.
     * Can only be called by the current owner.
     */
    function setUnlockBlockSaleTwo( uint256 _unlockBlock, uint256 _releaseOfferingOnEvery,  uint256 _closeBlock, uint _totalOfferRelease) external onlyOwner {
        require(_unlockBlock > 0, "Presale :: unlockBlock > 0");
        require(_releaseOfferingOnEvery > 0, "Presale :: _releaseOfferingOnEvery should > 0");
        require(_totalOfferRelease > 0, "Presale :: _totalOfferRelease should > 0");
        require(_closeBlock == (_releaseOfferingOnEvery * _totalOfferRelease), "Presale :: total offer release should equal to close block");
        
        unlockBlock[1] = _unlockBlock;
        releaseOfferingOnEvery[1] = _releaseOfferingOnEvery;
        closeBlock[1] = _closeBlock;
    }
    
    /**
     * @dev Setting offer amount to the presale one.
     * Can only be called by the current owner.
     */
    function setOfferingAmountSaleOne(uint256 _offerAmount) external onlyOwner {
        require (block.timestamp < startBlock[0], "Presale :: setOfferingAmountSaleOne : cant change offering amount after start block.");
        offeringAmount[0][currentSale[0]] = _offerAmount;
    }
    
    /**
     * @dev Setting offer amount to the presale two.
     * Can only be called by the current owner.
     */
    function setOfferingAmountSaleTwo(uint256 _offerAmount) external onlyOwner {
        require (block.timestamp < startBlock[1], "Presale :: setOfferingAmountSaleTwo : cant change offering amount after start block.");
        offeringAmount[1][currentSale[1]] = _offerAmount;
    }
    
    /**
     * @dev Pauses the functions.
     * Can only be called by the current owner.
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpauses the functions.
     * Can only be called by the current owner.
     */
    function unPause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Pauses the presale.
     * Can only be called by the current owner.
     */
    function pausePresale( uint _pSale) external onlyOwner onlyPresales( _pSale) {
        isPresaleActive[_pSale] = false;
    }
    
    /**
     * @dev Unpause the presale.
     * Can only be called by the current owner.
     */
    function unPausePresale( uint _pSale) external onlyOwner onlyPresales( _pSale) {
        isPresaleActive[_pSale] = true;
    }
    
    /**
     * @dev Pauses the claim.
     * Can only be called by the current owner.
     */
    function pauseClaim( uint _pSale) external onlyOwner onlyPresales( _pSale) {
        isClaimActive[_pSale] = false;
    }
    
    /**
     * @dev Unpauses the claim.
     * Can only be called by the current owner.
     */
    function unPauseClaim( uint _pSale) external onlyOwner onlyPresales( _pSale) {
        isClaimActive[_pSale] = true;
    }
    
    /**
     * @dev Setting claim release percentage.
     * Can only be called by the current owner.
     */
    function setClaimRelease( uint[2] memory _claimRelease) external onlyOwner {
        require((_claimRelease[0]+_claimRelease[1]) <= 100);
        claimRelease = _claimRelease;
    }
    
    /**
     * @dev withdraw raised BNB.
     * Can only be called by the current owner.
     */
    function withdrawBNB() external onlyOwner{
        address _self = address(this);  
        
        require(_self.balance > 0 , "Presale :: withdrawBNB : no fund left.");
        payable(owner()).transfer(_self.balance);
    }
    
    /**
     * @dev withdraw unsold tokens.
     * Can only be called by the current owner.
     */
    function unsoldTokens( uint _pSale, uint _saleID ) external onlyOwner onlyPresales( _pSale) {
        require(!isPresaleActive[_pSale], "Presale :: getUnsoldTokens : cannot get tokens until the presale is closed.");
        require(_saleID <= currentSale[_pSale], "Presale :: _saleID < currentSale");
        require(offeringAmount[_pSale][_saleID] > totalSoldTokens[_pSale][_saleID], "Presale :: unsoldTokens : no unsold tokens left");
        
        uint _unsold = offeringAmount[_pSale][_saleID] - (totalSoldTokens[_pSale][_saleID] - totalOfferedTokens[_pSale][_saleID]);
        offeringAmount[_pSale][_saleID] -= _unsold;
        offeringToken.safeTransfer(owner(), _unsold);
    }
    
    /**
     * @dev purchase offering tokens.
     * @param _qty quantity of token user wish to purchase 1 = 1e6
     */
    function buyOffer( uint _pSale, uint _qty) external payable whenNotPaused onlyPresales( _pSale) {
        require(isPresaleActive[_pSale], "Presale :: buyOffer : presale is closed");
        require((block.timestamp >= startBlock[_pSale]) && (startBlock[_pSale] != 0), "Presale :: buyOffer : cannot buy token until start block");
        require(block.timestamp <= endBlock[_pSale], "Presale :: buyOffer : presale is closed, cannot buy token after end block");
        require(msg.value == calcualteOfferInBNB( _pSale, _qty), "Presale :: buyOffer : invalid amount");
        require((offeringToken.balanceOf(address(this)) - totalSoldTokens[_pSale][currentSale[_pSale]]) >= _qty, "Presale :: buyOffer : insufficient offering token"); 
        
        UserInfo storage _usrInfo = userInfo[_msgSender()][_pSale][currentSale[_pSale]];
        totalAmount[_pSale] += msg.value;
        _usrInfo.balances += _qty;
        totalSoldTokens[_pSale][currentSale[_pSale]] += _qty;
        
        emit BuyOffer( _msgSender(), _pSale, currentSale[_pSale], msg.value, _qty, block.timestamp);
    }
    
    struct Variables { // claim variables
        uint _currentBlock;
        uint _releaseAmount;
        uint _launchEndMonth;
        uint _month;
    }

    /**
     * @dev claim offering tokens.
     * _saleID sale id user wants to claim.
     */    
    function claim( uint _pSale, uint _saleID) external onlyPresales( _pSale) whenNotPaused nonReentrant {
        require(isClaimActive[_pSale], "Presale :: claim : not active");
        require(block.timestamp >= launchBlock[_pSale], "Presale :: claim : wait until claim period starts");
        require(_saleID <= currentSale[_pSale], "Presale :: _saleID < currentSale");
        
        UserInfo storage _usrInfo = userInfo[_msgSender()][_pSale][_saleID];
        Variables memory _var;
        
        require(!_usrInfo.isClaimedAll, "Presale :: claim : user has claimed all his offerings");
        require(_usrInfo.balances > 0, "Presale :: claim : user has no available offerings");
        
        _var._currentBlock = block.timestamp;
        _var._launchEndMonth = launchBlock[_pSale] + unlockBlock[_pSale];
        
        if(_usrInfo.lastClaimTime == 0) {
            _var._releaseAmount += (_usrInfo.balances*claimRelease[0])/10**2;
            
            if(isPresaleActive[_pSale]) 
                isPresaleActive[_pSale] = false;
           
            _usrInfo.lastClaimTime = _var._launchEndMonth - releaseOfferingOnEvery[_pSale];
            _usrInfo.balances -= _var._releaseAmount;  
            _usrInfo.totalClaimAmount += _var._releaseAmount;
        }
             
        if((_var._currentBlock >= (_usrInfo.lastClaimTime + releaseOfferingOnEvery[_pSale])) && (_usrInfo.balances > 0)) {
            
            if(_var._currentBlock > (_var._launchEndMonth + closeBlock[_pSale])) _var._currentBlock = _var._launchEndMonth + closeBlock[_pSale];
            
            _var._month = (_var._currentBlock - _usrInfo.lastClaimTime)/releaseOfferingOnEvery[_pSale];
        
            uint[2] memory _releaseOffering; // 0- totalvest 1- release fund.    
        
            _releaseOffering[0] = _usrInfo.totalClaimAmount + _usrInfo.balances;
            _releaseOffering[1] = _releaseOffering[0] * claimRelease[1]/10**2;
            _releaseOffering[1] = _releaseOffering[1] * _var._month;
            
            if(_releaseOffering[1] > _usrInfo.balances) _releaseOffering[1] = _usrInfo.balances;
            
            _usrInfo.lastClaimTime += releaseOfferingOnEvery[_pSale] * _var._month;
            _usrInfo.balances -= _releaseOffering[1];
            _var._releaseAmount += _releaseOffering[1];
            _usrInfo.totalClaimAmount += _releaseOffering[1];
            
            if(_usrInfo.balances == 0)
                _usrInfo.isClaimedAll = true;
        }
        
        if((_var._releaseAmount > 0) && (offeringAmount[_pSale][_saleID] >= _var._releaseAmount)) {
            offeringAmount[_pSale][_saleID] -= _var._releaseAmount;
            totalOfferedTokens[_pSale][_saleID] += _var._releaseAmount;
            offeringToken.safeTransfer(_msgSender(), _var._releaseAmount);
            emit Claim( _msgSender(), _pSale, _saleID, _var._releaseAmount, block.timestamp);
        }
        else revert("Presale :: claim : No offering token user has to wait till next release");
        
    }
    
    /**
     * @dev calculates offering tokens price in BNB.
     * @param _qty quantity of token user wish to purchase 1 = 1e6
     */
    function calcualteOfferInBNB( uint _pSale, uint _qty) public onlyPresales( _pSale) view  returns (uint _offer) {
      _offer = offeringPrice[_pSale]*_qty/1e6;
    }
  
}