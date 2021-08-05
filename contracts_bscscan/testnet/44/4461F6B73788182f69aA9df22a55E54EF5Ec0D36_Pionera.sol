/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

/**
 *Submitted for verification at Etherscan.io on 2019-08-29
*/

/**
 * 
 * ██████╗░██╗░█████╗░███╗░░██╗███████╗██████╗░░█████╗░
 * ██╔══██╗██║██╔══██╗████╗░██║██╔════╝██╔══██╗██╔══██╗
 * ██████╔╝██║██║░░██║██╔██╗██║█████╗░░██████╔╝███████║
 * ██╔═══╝░██║██║░░██║██║╚████║██╔══╝░░██╔══██╗██╔══██║
 * ██║░░░░░██║╚█████╔╝██║░╚███║███████╗██║░░██║██║░░██║
 * ╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝              
 *      
 * My URL: 
 * 
 */

pragma solidity 0.6.12;




/**
 *Submitted for verification at BscScan.com on 2021-05-31
*/

// SPDX-License-Identifier: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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


/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}





contract Pionera {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public ownerWallet;

    IERC20 public depositToken = IERC20(0xb883C5E72AC27c5f0B8A5233C6b9c8cf034C5371);         //add BUSD address here

    uint256 private ownerFee = 1;       //1 percent owner fee of all transactions   

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        uint currentLevel;
    }

    uint REFERRER_1_LEVEL_LIMIT = 2;

    mapping(uint => uint) public LEVEL_PRICE;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);

    constructor() public {
        ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 10 ether;            //10 BUSD
        LEVEL_PRICE[2] = 15 ether;            //15 BUSD
        LEVEL_PRICE[3] = 40 ether;             //40 BUSD
        LEVEL_PRICE[4] = 110 ether;            //110 BUSD
        LEVEL_PRICE[5] = 120 ether;            //120 BUSD
        LEVEL_PRICE[6] = 180 ether;            //180 BUSD
        LEVEL_PRICE[7] = 440 ether;            //440 BUSD
        LEVEL_PRICE[8] = 300 ether;            //300 BUSD
        LEVEL_PRICE[9] = 600 ether;            //600 BUSD

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referral: new address[](0),
            currentLevel: 1
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

    }

    function changeOwnerFee(uint256 newFee) public {
        require(msg.sender == ownerWallet);
        ownerFee = newFee;
    }

    function changeDepositToken(address tokenAddress) public {
        require(msg.sender == ownerWallet);
        depositToken = IERC20(address(tokenAddress));
    }
    
    // function giveAllowanceToContract(uint256 amount) public{
    //     depositToken.approve(msg.sender, address(this), amount);
    // }

    function userRegistrationWithoutReferal(uint levelSelected, uint256 amountSent) external  {
        uint level;

        if (levelSelected == 1 && amountSent == LEVEL_PRICE[1]) level = 1;
        else if (levelSelected == 2 && amountSent == LEVEL_PRICE[2]) level = 2;
        else if (levelSelected == 3 && amountSent == LEVEL_PRICE[3]) level = 3;
        else if (levelSelected == 4 && amountSent == LEVEL_PRICE[4]) level = 4;
        else if (levelSelected == 5 && amountSent == LEVEL_PRICE[5]) level = 5;
        else if (levelSelected == 6 && amountSent == LEVEL_PRICE[6]) level = 6;
        else if (levelSelected == 7 && amountSent == LEVEL_PRICE[7]) level = 7;
        else if (levelSelected == 8 && amountSent == LEVEL_PRICE[8]) level = 8;
        else if (levelSelected == 9 && amountSent == LEVEL_PRICE[9]) level = 9;
        else revert('Incorrect Value send');

        if(users[msg.sender].isExist) buyLevel(level, amountSent);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(users[referrer].isExist) refId = users[referrer].id;
            else revert('Incorrect referrer');
            regUser(refId,amountSent);
        }
        else revert('Please buy first level for 10BUSD');
    }

    function regUser(uint _referrerID, uint256 amountSent) public {

        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(amountSent == LEVEL_PRICE[1], 'Incorrect Value');

        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            currentLevel: 1
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender, amountSent);

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint _level, uint256 amountSent) public {
        require(users[msg.sender].isExist, 'User not exist'); 
        require(_level > 0 && _level <= 9, 'Incorrect level');

        if(_level == 1 || users[msg.sender].currentLevel == 9) {
            require(amountSent == LEVEL_PRICE[1], 'Incorrect Value');
        }
        else {
            require(amountSent == LEVEL_PRICE[_level], 'Incorrect Value');

            require(users[msg.sender].currentLevel + 1 == _level , 'Buy the Previous level before buying this level');

        }

        payForLevel(_level, msg.sender, amountSent);

        emit buyLevelEvent(msg.sender, _level, now);
    }
    

    function payForLevel(uint _level, address _user, uint256 amountSend) internal {
        address referer;
        address referer1;
        address referer2;

        uint256 toOwner = amountSend.mul(ownerFee).div(100);
        uint256 toReferer = amountSend.sub(toOwner);

        if(_level == 1 || _level == 4 || _level == 7) {
            referer = userList[users[_user].referrerID];
        }
        else if(_level == 2 || _level == 5 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        }
        else if(_level == 3 || _level == 6 || _level == 9) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        }

        if(!users[referer].isExist) referer = userList[1];

        // bool sent = false;

        depositToken.safeTransferFrom(msg.sender, address(ownerWallet), toOwner);
        depositToken.safeTransferFrom(msg.sender, address(uint160(referer)), toReferer);
        emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
        users[_user].currentLevel = _level;

        // if(!sent) {
        //     emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

        //     payForLevel(_level, referer);
        // }
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function getUserDetails(address _user) public view returns (bool, uint, uint, uint)
    {
        bool isExist = users[_user].isExist;
        uint id = users[_user].id;
        uint referrerID = users[_user].referrerID;
        uint currentLevel = users[_user].currentLevel;

        return (isExist, id, referrerID, currentLevel);
    }



}