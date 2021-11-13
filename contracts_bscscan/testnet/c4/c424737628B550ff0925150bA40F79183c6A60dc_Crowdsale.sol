//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

///@dev  OpenZeppelin modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

///@dev  interfaces

/** 
    @title Crowdsale 
    @notice This is a Natspec commented contract by AtomPad Development Team
    @notice Version v1.0.1  date: nov 11, 2021
*/

/// @author AtomPad Dev Team
/// @author JaWsome Orbit 
/// @author Ruwaifa Tahir

/** @notice What is Crowdsale?
    Crowdsale provides the initial launch system AtomPad. This smart contract is build from scratch 28.10.2021 by Ruwaifa Tahir and is  based on the
    OpenZeppelin v1.* and v2.* crowdsale documentation for a basic understanding of the standard appproach for crowdsales. The code structure and naming
    conventions are in lin with AtomPad contracts Presale and StakePool.
    Update v1.0.1. date 11 nov 2021 
    - add caps and check of token availability before buy
    - add time check for sync start of claiming with other claims
*/

/** @notice How the contract works
    Crowdsale is directly available for the crowd after deployment. 
    There is a reservation for startTime and endTime included, but not activated (v1.0.1).

    For Timing and synchronounce launches with all chains, there is a timing requirement for claiming tokens included
    /// @notice overwrite start of claiming
    /// @source:  https://www.epochconverter.com/
    /// Epoch timestamp: 1637445600 --> 2021-11-20 22:00 GMT <DEFAULT>
    /// Epoch timestamp: 1637438400 --> 2021-11-20 20:00 GMT

    The contract owner has to enable claiming and the timeblock has to pass the startClaim var before users can transfer their tokens.

    Rate is hardcoded 12.5 * (10 * ** 18)

    There is a provision for blacklisten and whitelisted addresses, but not activated

    Contract owner has full control over the token balances and can deposit and withdraw tokens without restrictrions
  
    After te crowdsale, the contract owner enables the claim process. 
    Claiming will only be available after timestamp in var claimTime which may or may not be changed during the crowdsale
    
    There is a counter implemented to measure traffic.
*/

/** @dev Contract status
    statusnumbers will be implemented in future versions of Crowdsale
    0 reset              -->    waiting for admin to set start variables
                                user : 
    
    1 deployed           -->    waiting for admin to deposit tokens
                                user : 
    
    2 tokens deposited   -->    waiting for timer to pass startTime
                                user : buy
    
    3 crowdsale started    -->  waiting for timer to pass endTimne
                                user : buy

    4 crowdsale ended      -->  waiting for admin to enable claimprocess
                                user : 

    5 claim no vesting   -->    waiting for user to  claims tokens
                                user : claim 
          
    6 retain tokens      -->    waiting admin to return tokens
                                user : 
         
    7 idle               -->    waiting admin to reset
                                user : 
*/



contract Crowdsale is  Ownable {

    /** @dev libraries
        @dev Ownable 
            Provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
            By default, the owner account will be the one that deploys the contract. This can later be changed with transferOwnership.
            This module is used through inheritance. It will make available the modifier onlyOwner, which can be applied to your functions to restrict their use to the owner.

        @dev SafeERC20 
            Wraps around ERC20 operations that throw on failure (when the token contract returns false). 
            Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful. 
    */

    using SafeERC20 for IERC20;


    /// @dev modifiers
      modifier claimDisabled {
        require(claimEnabled == false , "Claiming is still active!");
        _;
    }
      modifier enabledClaim {
        require(claimEnabled == true , "Claiming is inactive !");
        _;
    }

    /// @dev variables

    /// rate = wantToken per investToken
    //  Amount of wwantToken user get for 1 investToken
    uint public rate = 12500000000000000000; // 12.5 * 10 ** 18

    // Amount of wantToken actual in stock
    uint public tokenSupply;

    // Amount of wantToken reserved to transfer (because user invested already!)
    uint public reservedSupply;

    /// @dev control buttons for the admin
    //      bool public swapOn;     // set by owner, turns off/on swap process
    bool public claimEnabled;  // set by owner, turns off/on claim process

    /// @dev control start of claiming at particular time
    uint public claimTime; 


    mapping(address => uint) claims;

    /// @dev array of users participating. 
    /// in order to iterate
    address[] public userAdresses;  
    // in order to set maxIteration without failing
    uint public userLength;

    /// optional whitelist / blacklist
    /// mapping(address => bool) whiteList;
    /// mapping(address => bool) blackList;


    /// counter to measure traffic 
    uint public counter;
    /// status step of the contract - unused
    /// uint256 status;


    /// calling parameters
    IERC20 public wantToken;
    IERC20 public investToken;
    //    uint public startTime;
    //    uint public endTime;
    //    uint public hardCap;
    //    uint public softCap;

    /// @dev totalizer to follow the process by admin / frontEnd
    uint public weiRaised;      // absolute amount of wei raised
    uint public swapTotal;      // absolute total swapped investToken
    uint public wantTotal;      // absolute total deposited wantToken 
    uint public claimedTotal;   // absolute total claimed wantToken


    /// @dev events
    /*
    * Event for wantToken purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event Deposited(address indexed user, uint amount);
    event Invested(address indexed user, uint amount);
    event Claimed(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    /// @dev constructor
    /// @param _wantToken the token that is to be distributed
    /// @param _investToken the token to invest with 

    constructor (address _wantToken, address _investToken )  {
   
        require(_wantToken != address(0));
        require(_investToken != address(0));

        wantToken = IERC20(_wantToken);
        investToken = IERC20(_investToken);
        claimEnabled = false;
        counter = 0;
        userLength = 0;

        weiRaised = 0;
        swapTotal = 0;
        wantTotal = 0;
        claimedTotal = 0;

        reservedSupply = 0;
        tokenSupply = 0;

        /// start of claiming can be overwritten--> check setter setClaimTime()
        claimTime = 1637445600; 

    }
  
/// IMPORTANT
/// quick note JaWsome 10 nov !!!  USE PAYABLE FOR NATIVE TOKEN AND ADDRESSES ??? testnet is not NATIVE. mainnet may be !!


  /// Core routines
  

    // @param msg.sender
    /// @param _amount the amount of tokens to deposit for the crowdSale
    /// @notice admin to deposit the wantTokens (! no restriction on sender !)
    function depositTokens(uint _amount) external  { 
        /// do some checks 
        require(wantToken.balanceOf(msg.sender) >= _amount, "!amount");

        /// @dev set minimum amount of tokens for this crowdsale
        //require(_amount >= (10 *10**18) , "min amount is 10 tokens!");

        /// transfer _amount of wantToken to this crowdsale contract
        wantToken.safeTransferFrom(msg.sender, address(this), _amount);

        /// increase actual supply
        tokenSupply += _amount;

        /// also increase reserved supply
        reservedSupply += _amount;

        /// increase totalizer deposited
        wantTotal += _amount;

        emit Deposited(msg.sender, _amount);
    }





    // @param msg.sender
    /// @dev function called by user : msg.sender 
    /// @param _amount the amount of _wantTokens to invest by this user
    /// @notice user to swap the investTokens during the crowdsale BEFORE the claimEnable
    function buyTokens(uint _amount) external claimDisabled {
        /// do some checks 

        require(wantToken.balanceOf(msg.sender) >= _amount, "!amount");

        require (_amount >= uint(1 ether), "Min amount is 1 Token!");

        require (reservedSupply >= _amount, "You're too late! no reservedSupply :( ");

        /// check if user is not blacklisted ! ==> map whitelist
        /// check if user is in the system !  ==>  only 1 buy per user

        /// transfer _amount of investToken to this crowdsale contract
        investToken.safeTransferFrom(msg.sender, address(this), _amount);

        /// calculate the amount of wantTokens
        uint _wantAmount = _getTokenAmount(_amount);

        /// reserve the wantTokens
        reservedSupply -= _wantAmount; 

        /// alter totalizers
        weiRaised += _amount;

        /// @notice to obtain the number of sold wantTokens we can make the calculation
        /// (sold wantTokens) = wantTotal - reservedSupply

        /// create a claim for this user
        claims[msg.sender] += _wantAmount;

        // add a user to users array
        _checkOrAddUser(msg.sender);
 
        // measure traffic and emit
        counter ++;
        emit Invested(msg.sender, _amount);
    }


    /// @param msg.sender
    /// @notice user can receive the wantTokens
    /** @dev claimTokens
     *  to be excecuted after the crowdsale by the user in order to have
     *  the tokens delivered to their personal wallet 
     */
    function claimTokens() external enabledClaim {
        /// do some checks 
        require(claims[msg.sender] > 0, "No pending claims!");

        /// check balance
        require(tokenSupply > claims[msg.sender], "Contract has no sufficient balance!");

        /// check for claimTime to have passed
        require(block.timestamp >= claimTime, "Claiming tokens has not started yet!");

        /// retrieve the amount
        uint _amount = claims[msg.sender];

        /// reset the claim (before the transfer!)
        claims[msg.sender] = 0;

        // make he actual transfer to users wallet
        wantToken.safeTransfer(msg.sender,_amount);

        // deduct actual token supply
        tokenSupply -= _amount;

        /// increase totalizer claimed
        claimedTotal += _amount;

        // measure traffic and emit
        counter ++;
        emit Claimed(msg.sender, _amount);
    }


    // @param msg.sender
    /// @notice admin can forward the sold investTokens to the admin wallet
    /// @dev forwardInvestTokens
    ///  to be excecuted during or after the crowdsale by the admin in order to receive
    ///  the invested tokens
    function forwardInvestTokens() external onlyOwner  { // 
        /// do some checks 
        require (investToken.balanceOf(address(this))> 0,'!Amount');

        /// retrieve amount of tokens 
        uint _invested = investToken.balanceOf(address(this));

        /// make the actual transfer
        investToken.safeTransfer(msg.sender, _invested);

        emit Withdrawn(msg.sender, _invested);
    }

    // @param msg.sender
    /// @dev returnWantTokens
    /// @notice admin can return the unsold tokens
    ///  to be excecuted during or after the crowdsale by the admin in order to withdraw
    /// the remaining tokens that have not been sold. 
    /// be careful.!!  once initiated this will leave the remaining claims with zero tokens left.
    function returnWantTokens() external onlyOwner  { // 
        // do some checks 
        require (wantToken.balanceOf(address(this))> 0,'!Amount');

        /// retrieve amount of tokens 
        uint _remaining = wantToken.balanceOf(address(this));

        /// make the actual transfer
        wantToken.safeTransfer(msg.sender, _remaining);

        emit Withdrawn(msg.sender, _remaining);
    }


    /// @dev subroutines
    // @param msg.sender
    /// @notice uppdate or insert the userArrray
    function _checkOrAddUser(address _user) internal returns (bool) {
        bool _new = true;
        for(uint i = 0 ; i < userAdresses.length ; i++) {
            if (userAdresses[i] == _user) {
                _new = false;
                i = userAdresses.length ;
            }
        }
        if (_new){
            userAdresses.push(_user);
            userLength++;
        }
        return _new;
    }

    /// @notice calculate amount of wantTokens based on rate
    function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
        //If someone invests 2 TOKEN And rate is 12.5 ETHER. User will get 2 * 12.5 = 25
        uint _tokenAmount = (_weiAmount * rate) / ( 10**18 ); 

        // We are divding tokenAmount with 1 Ether to achieve accuracy
        return _tokenAmount;
    }


    /// Getters

    // @param msg.sender
    /// returns address of user from claims map
    function userClaims(address _address) view public returns(uint) {
        return claims[_address];
    }


    /// setters


    /// To enable or disable claims
    function setEnableClaim(bool _flag) external onlyOwner  {
        // do some checks 
        claimEnabled = _flag;
    }

    // @notice overwrite start of claiming
    // @source:  https://www.epochconverter.com/
    /// Epoch timestamp: 1637445600 --> 2021-11-20 22:00 GMT <DEFAULT>
    /// Epoch timestamp: 1637438400 --> 2021-11-20 20:00 GMT
    function setClaimTime(uint _timestamp) external onlyOwner {
        claimTime = _timestamp;
    }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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