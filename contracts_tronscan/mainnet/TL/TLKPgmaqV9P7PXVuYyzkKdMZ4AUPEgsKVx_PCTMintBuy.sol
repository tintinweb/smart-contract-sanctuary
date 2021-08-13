//SourceUnit: PCTMintBuy.sol

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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


contract PCTMintBuy {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public USDT;
    
    IERC20 public PCTtoken;
    
    struct MintBuyRecord {
        address userAddress;
        uint256 timestamp;
        uint256 mineID;
        uint256 amount;
    }

    
    address[5][6]  public projectAddress = [
        [
        0xc919e292A29bd77f5Ae38F5a3357260223d9991b,
        0xCa7B5a9551e00097BF90808E9AB59793Af8571FB,
        0x7cfC3D7E2b8E1636A3244580008C16512DA43Ad9,
        0x0d7990812b3aC5c11Adf0235c0Ab1e2cE0d14A76,
        0x1B36B93fF353BcD5EBFaac49Fa5e9F20d94c9780
        ],
        [
        0x714AFB557D866e0a50C9d025932ee03f652F6593,
        0x8eE67D1cd507Dae62feCa4454dd1CdCfD2f9AeE3,
        0xbeC926Fe94c7b977F0cBfE96229BC1a5e7cA389A,
        0x41feECb2Cc1FdF83d0a3bb39bBb3a8CdeA66db35,
        0x69c41AaF7a8e457B81376fc0e9F7770B9A399ed8
        ],
        [
        0x88E183b5911AD00c34D1aCd48f59869Cb411186A,
        0x04aB53308B39C721bcB5ca7123Ea64438DC1A57e,
        0xF9107AB619CDf40a3798ad0571511e27923DEEDe,
        0x955e51e0604295ABD296b1cA9DDC29953d242b60,
        0x2C7FD9BEb704640c2A8D5027027BBbE70259aEFA
        ],
        [
        0x1716f2d9028b0b44DeB4B4d92dC3Ff0EcA771ffe,
        0x2749da5bA1F299b512B2A966E010c88C53b5b22A,
        0x48a72029aF4d5Bb45EdA9602dFaA8ecdd31f872d,
        0x72D5395896DCFE67e99705ffBB3AC34699311005,
        0x64A5d9f235bE5A9F9537f24c57F24EDb05cea447
        ],
        [
        0x3372FafE145f9b37F33C30223BD14e0c1a07C3AE,
        0xC3748BC7AaeB5B804c9613ac899C994E79bc4E0a,
        0x0F9404056806A64Be2213C9ba65896b5aCF84D7D,
        0x7A42f9d9bcFC29EFa4D203f71A5f88C20103AEFd,
        0x0e4333536aAc86F15CA4D9456Be863708D37273A
        ],
        [
        0x4d03912348ae1CC3293D1D596FFAa74AA2C3E8E0,
        0xd395cD312C8B2d43c253deC0853CC2FC8fF19163,
        0x3309065DbDFa3397B2D3EBcd4Bb040884f1b7EEE,
        0xDac4804c5aB3FF83503C79456Dffe8506cB459e1,
        0x8Cc0bb0E99d03195Ba33e624F88446Ac3d7091eF
        ]];


    uint256 private addIndex = 0;
    
    
    mapping(address => mapping(uint256 => MintBuyRecord)) public userMintBuyRecord;
    
    
    address public contractOwner;
    
    address public burnAddress;

    event Swap(address account, uint256 amount);
    event MintBuy(uint256 mine_id, uint256 amount);
    event WithdrawUSDT(address account, uint256 amount);
    event WithdrawPCT(address account, uint256 amount);
    
    constructor(IERC20 _USDT, IERC20 _PCTtoken, address _burnAddress) public {
        
        contractOwner = msg.sender;
        
        USDT = _USDT;
        PCTtoken = _PCTtoken;
        burnAddress = _burnAddress;
    
    }


    function setUSDTToken(IERC20 _USDT) public {
        require(msg.sender == contractOwner, "Must be owner");
        USDT = _USDT;
    }
    
    function setPCTToken(IERC20 _PCTtoken) public {
        require(msg.sender == contractOwner, "Must be owner");
        PCTtoken = _PCTtoken;
    }
    

     
    function setOwner(address _contractOwner) public {
        require(msg.sender == contractOwner, "Must be owner");
        contractOwner = _contractOwner;
    }
    
    
    function mintBuy(uint256 timestamp, uint256 mine_id, uint256 amount) public payable returns(uint256){

        require(amount > 0, "amount must > 0");
        
        USDT.transferFrom(address(msg.sender), address(this), amount);
        
        
        userMintBuyRecord[msg.sender][timestamp].userAddress = msg.sender;
        userMintBuyRecord[msg.sender][timestamp].timestamp = timestamp;
        userMintBuyRecord[msg.sender][timestamp].mineID = mine_id;
        userMintBuyRecord[msg.sender][timestamp].amount = amount;
        
        
        if(addIndex == 6) {
            addIndex = 0;
        }
        safeTransfer(projectAddress[addIndex][0], amount.mul(20).div(100));
        safeTransfer(projectAddress[addIndex][1], amount.mul(20).div(100));
        safeTransfer(projectAddress[addIndex][2], amount.mul(20).div(100));
        safeTransfer(projectAddress[addIndex][3], amount.mul(20).div(100));
        safeTransfer(projectAddress[addIndex][4], amount.mul(20).div(100));
        
        addIndex ++;
       
        emit MintBuy(mine_id, amount);
        
        return mine_id;
    }
    
    
    function swap(address account, uint256 amount) public {
        
        require(amount > 0, "amount must > 0");
        
        require(msg.sender == contractOwner, "Must be owner");
        
        uint256 balance = PCTtoken.balanceOf(address(this)) ;
        
        if(balance > 0 ){
            if(balance > amount) {
                PCTtoken.safeTransfer(burnAddress, amount) ;
            } else {
                PCTtoken.safeTransfer(burnAddress, balance) ;
            }
            
        }
        
        emit Swap(account, amount);
    }
    

    function withdrawUSDT(address account, uint256 amount) public {
        
        require(amount > 0, "amount must > 0");
        
        require(msg.sender == contractOwner, "Must be owner");
        
        uint256 balance = USDT.balanceOf(address(this)) ;
        
        if(balance > 0 ){
            if(balance > amount) {
                 USDT.safeTransfer(account, amount) ;
            } else {
                USDT.safeTransfer(account, balance) ;
            }
            
        }
        
        emit WithdrawUSDT(account, amount);
    }
    
    
    function withdrawPCT(address account, uint256 amount) public {
        
        require(amount > 0, "amount must > 0");
        
        require(msg.sender == contractOwner, "Must be owner");
        
        uint256 balance = PCTtoken.balanceOf(address(this)) ;
        
        if(balance > 0 ){
            if(balance > amount) {
                PCTtoken.safeTransfer(account, amount) ;
            } else {
                PCTtoken.safeTransfer(account, balance) ;
            }
            
        }
        
        emit WithdrawPCT(account, amount);
    }
    

    
    
    function totalUSDTSupply()  external view returns (uint256) {
        
        return USDT.balanceOf(address(this));
        
    }
    
    function totalPCTSupply()  external view returns (uint256) {
        
        return PCTtoken.balanceOf(address(this));
        
    }
    
    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = USDT.balanceOf(address(this));
        if(_amount > tokenBalance) {
            USDT.safeTransfer(_to, tokenBalance);
        } else {
            USDT.safeTransfer(_to, _amount);
        }
        
    }
    

}