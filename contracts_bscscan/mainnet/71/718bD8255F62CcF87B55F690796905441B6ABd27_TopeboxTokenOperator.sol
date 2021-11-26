/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity 0.6.3;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
        (bool success, ) = recipient.call{value: amount}("");
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
            target.call{value: value}(data);
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

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
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
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
contract Receiver is Ownable {
    /*
        @notice Send funds owned by this contract to another address
        @param tracker  - ERC20 token tracker ( DAI / MKR / etc. )
        @param amount   - Amount of tokens to send
        @param receiver - Address we're sending these tokens to
        @return true if transfer succeeded, false otherwise 
    */
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function sendFundsTo(address tracker, uint256 amount, address receiver) public onlyOwner returns ( bool ) {
        // callable only by the owner, not using modifiers to improve readability
        // Transfer tokens from this address to the receiver
        return IERC20(tracker).transfer(receiver, amount);
    }
}

/**
 * @title ERC20 Airdrop dapp smart contract
 */
contract TopeboxTokenOperator is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
  
    uint256 public maxSendlength = 1000;

    address public DPETAddress = 0xfb62AE373acA027177D1c18Ee0862817f9080d08;
    function setDpetAddress(address newAddress) public onlyOwner{
        DPETAddress = newAddress;
    }
	
	struct TokenLock {
    address tokenAddress;
    uint256 lockDate; // the date the token was locked
    uint256 amount; // the amount of tokens locked
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner;
    bool retrieved; // false if lock already retreieved
  }

  // Mapping of user to their locks
  mapping(address => mapping(uint256 => TokenLock)) public locks;

  // Num of locks for each user
  mapping(address => uint256) public numLocks;
  
   function lockTokens(address tokenAddress, uint256 amount, uint256 time) external returns (bool) {
    IERC20 token = IERC20(tokenAddress);
    TokenLock memory tokenLock;
    tokenLock.tokenAddress = tokenAddress;
    tokenLock.lockDate = block.timestamp;
    tokenLock.amount = amount;
    tokenLock.unlockDate = block.timestamp.add(time);
    tokenLock.lockID = numLocks[msg.sender];
    tokenLock.owner = msg.sender;
    tokenLock.retrieved = false;

    // Transferring token to smart contract
    token.transferFrom(msg.sender, address(this), amount);
    
    locks[msg.sender][numLocks[msg.sender]] = tokenLock;
    numLocks[msg.sender]++;

    return true;
  }
  
  function getLock(uint256 lockId) public view returns (address, uint256, uint256, uint256, uint256, address, bool) {
    return (
      locks[msg.sender][lockId].tokenAddress,
      locks[msg.sender][lockId].lockDate,
      locks[msg.sender][lockId].amount,
      locks[msg.sender][lockId].unlockDate,
      locks[msg.sender][lockId].lockID,
      locks[msg.sender][lockId].owner,
      locks[msg.sender][lockId].retrieved
    );
  }
  
  function getNumLocks() external view returns (uint256) {
    return numLocks[msg.sender];
  }

  function unlockTokens(uint256 lockId) external returns (bool) {
    // Make sure lock exists
    require(lockId < numLocks[msg.sender], "Lock doesn't exist");
    // Make sure lock is still locked
    require(locks[msg.sender][lockId].retrieved == false, "Lock was already unlocked");
    // Make sure tokens can be unlocked
    require(locks[msg.sender][lockId].unlockDate <= block.timestamp, "Tokens can't be unlocked yet");
    
    IERC20 token = IERC20(locks[msg.sender][lockId].tokenAddress);
    token.transfer(msg.sender, locks[msg.sender][lockId].amount);
    locks[msg.sender][lockId].retrieved = true;

    return true;
  }

  function changeOwner(address newOwner, uint256 lockId) external returns (bool) {
    // Make sure lock exists
    require(lockId < numLocks[msg.sender], "Lock doesn't exist");
    // Make sure lock is still locked
    require(locks[msg.sender][lockId].retrieved == false, "Lock was already unlocked");

    TokenLock memory tokenLock;
    tokenLock.tokenAddress = locks[msg.sender][lockId].tokenAddress;
    tokenLock.lockDate = locks[msg.sender][lockId].lockDate;
    tokenLock.amount = locks[msg.sender][lockId].amount;
    tokenLock.unlockDate = locks[msg.sender][lockId].unlockDate;
    tokenLock.lockID = numLocks[newOwner];
    tokenLock.owner = newOwner;
    tokenLock.retrieved = false;

    locks[newOwner][numLocks[newOwner]] = tokenLock;
    numLocks[newOwner]++;

    // If lock ownership is transferred its retrieved
    locks[msg.sender][lockId].retrieved = true;
  }



     /**
     * @dev dpetDistribute is the main method for DPET distribution
     * @param addresses address[] addresses to airdrop
     * @param values address[] values for each address
     */
    function dpetDistribute(address[] calldata addresses, uint256[] calldata values) external returns (uint256) {
        require(values.length==addresses.length, "Array Length Not Matched");
        require(values.length<=maxSendlength, "Array Length Too Large");
        IERC20 token = IERC20(DPETAddress);
        uint256 i = 0;

        while (i < addresses.length) {
            token.safeTransferFrom(msg.sender, addresses[i], values[i]);
            i += 1;
        }

        return i;
    }

     function setMaxSendLength(uint256 newLen) external onlyOwner {
         maxSendlength = newLen;
     }

    function withdrawDpetBalance() external onlyOwner {
      //  address(uint160(owner)).Transfer(address(this).balance);
        IERC20(DPETAddress).transfer(owner, getBalanceDpet());
    }

    function getBalanceDpet() view public returns(uint256) {
        return IERC20(DPETAddress).balanceOf(address(this));
    }


    /**
     * @dev tokenDistribute is the main method for distribution
     * @param token airdropped token address
     * @param addresses address[] addresses to airdrop
     * @param values address[] values for each address
     */
    function tokenDistribute(
        IERC20 token,
        address[] calldata addresses,
        uint256[] calldata values
    ) external returns (uint256) {
        require(values.length==addresses.length, "Array Length Not Matched");
        require(values.length<=maxSendlength, "Array Length Too Large");
        uint256 i = 0;

        while (i < addresses.length) {
            token.safeTransferFrom(msg.sender, addresses[i], values[i]);
            i += 1;
        }

        return i;
    }

   


    function withdrawTokenBalance( IERC20 token) external onlyOwner {
      //  address(uint160(owner)).Transfer(address(this).balance);
      token.transfer(owner, getBalanceToken(token));
    }

    function getBalanceToken(IERC20 token) view public returns(uint256) {
        return token.balanceOf(address(this));
    }

      /*
        Batch Collection - Should support a few hundred transansfers
        @param tracker           - ERC20 token tracker ( DAI / MKR / etc. )
        @param receiver          - Address we're sending tokens to
        @param contractAddresses - we send an array of addresses instead of ids, so we don't need to read them ( lower gas cost )
        @param amounts           - array of amounts 
    */
    function batchCollect( address tracker, address receiver, uint256[] memory amounts, address[] memory contractAddresses) public onlyOwner{
        
        require(contractAddresses.length == amounts.length);

        for(uint256 i = 0; i < contractAddresses.length; i++) {

            // add exception handling
            require(Receiver( contractAddresses[i] ).sendFundsTo( tracker, amounts[i], receiver), "batchCollect's call to sendFundsTo failed");
        }
    }
	
	  /**
     * @dev tokenDistribute is the main method for distribution
     * @param token airdropped token address
     * @param addresses address[] addresses to airdrop
     * @param values address[] values for each address
     */
    function tokenDistributeSelf(
        IERC20 token,
        address[] calldata addresses,
        uint256[] calldata values
    ) external  onlyOwner returns (uint256) {
        require(values.length==addresses.length, "Array Length Not Matched");
        require(values.length<=maxSendlength, "Array Length Too Large");
        uint256 needNum = 0;
        uint256 j = 0;
        while (j < values.length) {
            needNum += values[j];
             j += 1;
        }
        require(getBalanceToken(token)>=needNum, "Not Enought Balance");
        uint256 i = 0;

        while (i < addresses.length) {
            token.safeTransfer(addresses[i], values[i]);
            i += 1;
        }

        return i;
    }
	
	
     /**
     * @dev dpetDistribute is the main method for DPET distribution
     * @param addresses address[] addresses to airdrop
     * @param values address[] values for each address
     */
    function dpetDistributeSelf(address[] calldata addresses, uint256[] calldata values) external onlyOwner returns (uint256) {
        require(values.length==addresses.length, "Array Length Not Matched");
        require(values.length<=maxSendlength, "Array Length Too Large");
        uint256 needNum = 0;
        uint256 j = 0;
        while (j < values.length) {
            needNum += values[j];
            j += 1;
        }
        require(getBalanceDpet()>=needNum, "Not Enought Balance");

        IERC20 token = IERC20(DPETAddress);
        uint256 i = 0;
        while (i < addresses.length) {
            token.safeTransfer(addresses[i], values[i]);
            i += 1;
        }

        return i;
    }
}