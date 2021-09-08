/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

//Beneficieries (validators) template
//import "../helpers/ValidatorsOperations.sol";
contract DPRBridge {

        IERC20 public token;
        using SafeERC20 for IERC20;
        using SafeMath for uint256;

        enum Status {PENDING,WITHDRAW, CANCELED, CONFIRMED, CONFIRMED_WITHDRAW}
        
        struct DepositInfo{
            uint256 last_deposit_time;
            uint256 deposit_amount;
        }

        struct WithdrawInfo{
            uint256 last_withdraw_time;
            uint256 withdraw_amount;
        }
        struct Message {
            bytes32 messageID;
            address spender;
            bytes32 substrateAddress;
            uint availableAmount;
            Status status;
        }

    

        event RelayMessage(bytes32 messageID, address sender, bytes32 recipient, uint amount);
        event RevertMessage(bytes32 messageID, address sender, uint amount);
        event WithdrawMessage(bytes32 MessageID, address recipient , bytes32 substrateSender, uint amount, bytes sig);
        event ConfirmWithdrawMessage(bytes32 messageID);
        

        bytes constant internal SIGN_HASH_PREFIX = "\x19Ethereum Signed Message:\n32";
        mapping(address => uint256) user_balance;
        mapping(bytes32 => Message) public messages;
        mapping(address => DepositInfo) public user_deposit_info;
        mapping(address => WithdrawInfo) public user_withdraw_info;
        DepositInfo public contract_deposit_info;
        WithdrawInfo public contract_withdraw_info;
        address public submiter;
        address public owner;
        uint256 private user_daily_max_deposit_and_withdraw_amount = 60000 * 10 ** 18; //init value
        uint256 private daily_max_deposit_and_withdraw_amount = 200000000 * 10 ** 18; //init value
        uint256 private user_min_deposit_and_withdraw_amount = 1000 * 10 ** 18; //init value
        uint256 private user_max_deposit_and_withdraw_amount = 20000 * 10 ** 18; //init value



       /**
       * @notice Constructor.
       * @param _token  Address of DPR token
       */

        constructor (IERC20 _token,address _submiter) public {

            token = _token;
            submiter = _submiter;
        }  

        /*
            check that message is valid
        */
        modifier validMessage(bytes32 messageID, address spender, bytes32 substrateAddress, uint availableAmount) {
            require((messages[messageID].spender == spender)
                && (messages[messageID].substrateAddress == substrateAddress)
                && (messages[messageID].availableAmount == availableAmount), "Data is not valid");
            _;
        }


        modifier pendingMessage(bytes32 messageID) {
            require(messages[messageID].status ==  Status.PENDING, "DPRBridge: Message is not pending");
            _;
        }

        // modifier approvedMessage(bytes32 messageID) {
        //     require(messages[messageID].status ==  Status.APPROVED, "DPRBridge: Message is not approved");
        //     _;
        // }

        modifier onlyOwner(){
            require(msg.sender == owner, "DPRBridge: Not Owner");
        _;
        }

        modifier withdrawMessage(bytes32 messageID) {
            require(messages[messageID].status ==  Status.WITHDRAW, "Message is not withdrawed");
            _;
        }

        modifier  updateUserDepositInfo(address user, uint256 amount) {
            require(amount >= user_min_deposit_and_withdraw_amount && amount <= user_max_deposit_and_withdraw_amount, "DPRBridge: Not in the range");
            DepositInfo storage di = user_deposit_info[user];
            uint256 last_deposit_time = di.last_deposit_time;
            if(last_deposit_time == 0){
                require(amount <= user_daily_max_deposit_and_withdraw_amount,"DPRBridge: Execeed the daily limit");
                di.last_deposit_time = block.timestamp;
                di.deposit_amount = amount;
            }else{
                uint256 pass_time = block.timestamp.sub(last_deposit_time);
                if(pass_time <= 1 days){
                    uint256 total_deposit_amount = di.deposit_amount.add(amount);
                    require(total_deposit_amount <= user_daily_max_deposit_and_withdraw_amount, "DPRBridge: Execeed the daily limit");
                    di.deposit_amount = total_deposit_amount;
                }else{
                    require(amount <= user_daily_max_deposit_and_withdraw_amount, "DPRBridge: Execeed the daily limit");
                    di.last_deposit_time = block.timestamp;
                    di.deposit_amount = amount;

                }
            }
            _;
        }

        modifier updateContractDepositInfo(uint256 amount){
            DepositInfo storage cdi = contract_deposit_info;
            uint256 last_deposit_time = cdi.last_deposit_time;
            if(last_deposit_time == 0){
                cdi.last_deposit_time = block.timestamp;
                cdi.deposit_amount += amount;
            }else{
                uint256 pass_time = block.timestamp.sub(last_deposit_time);
                if(pass_time <= 1 days){
                    uint256 total_deposit_amount = cdi.deposit_amount.add(amount);
                    require(total_deposit_amount <= daily_max_deposit_and_withdraw_amount, "DPRBridge: Execeed contract deposit limit");
                    cdi.deposit_amount = total_deposit_amount;
                }else{
                    cdi.deposit_amount = amount;
                    cdi.last_deposit_time = block.timestamp;
                }
                
            }
            _;
            
        }

        modifier updateContractWithdrawInfo(uint256 amount){
            WithdrawInfo storage cdi = contract_withdraw_info;
            uint256 last_withdraw_time = cdi.last_withdraw_time;
            if(last_withdraw_time == 0){
                cdi.last_withdraw_time = block.timestamp;
                cdi.withdraw_amount += amount;
            }else{
                uint256 pass_time = block.timestamp.sub(last_withdraw_time);
                if(pass_time <= 1 days){
                    uint256 total_withdraw_amount = cdi.withdraw_amount.add(amount);
                    require(total_withdraw_amount <= daily_max_deposit_and_withdraw_amount, "DPRBridge: Execeed contract deposit limit");
                    cdi.withdraw_amount = total_withdraw_amount;
                }else{
                    cdi.withdraw_amount = amount;
                    cdi.last_withdraw_time = block.timestamp;
                }
                
            }
            _;
            
        }

        modifier  updateUserWithdrawInfo(address user, uint256 amount) {
            require(amount >= user_min_deposit_and_withdraw_amount && amount <= user_max_deposit_and_withdraw_amount, "DPRBridge: Not in the range");
            WithdrawInfo storage ui = user_withdraw_info[user];
            uint256 last_withdraw_time = ui.last_withdraw_time;
            if(last_withdraw_time == 0){
                require(amount <= user_daily_max_deposit_and_withdraw_amount,"DPRBridge: Execeed the daily limit");
                ui.last_withdraw_time = block.timestamp;
                ui.withdraw_amount = amount;
            }else{
                uint256 pass_time = block.timestamp.sub(last_withdraw_time);
                if(pass_time <= 1 days){
                    uint256 total_withdraw_amount = ui.withdraw_amount.add(amount);
                    require(total_withdraw_amount <= user_daily_max_deposit_and_withdraw_amount, "DPRBridge: Execeed the daily limit");
                    ui.withdraw_amount = total_withdraw_amount;
                }else{
                    require(amount <= user_daily_max_deposit_and_withdraw_amount, "DPRBridge: Execeed the daily limit");
                    ui.last_withdraw_time = block.timestamp;
                    ui.withdraw_amount = amount;

                }
            }
            _;
        }

        // modifier onlyFeeSetter() {
        //     require(msg.sender == FeeSetter);
        //     _;
        // }

        function setUserDailyMax(uint256 max_amount) external onlyOwner returns(bool){
            user_daily_max_deposit_and_withdraw_amount = max_amount;
            return true;
        }

        function setDailyMax(uint256 max_amount) external onlyOwner returns(bool){
            daily_max_deposit_and_withdraw_amount = max_amount;
            return true;
        }

        function setUserMin(uint256 min_amount) external onlyOwner returns(bool){
            user_min_deposit_and_withdraw_amount = min_amount;
            return true;
        }

        // function setFeeSetter(address _feeSetter) external onlyOwner returns(bool){
        //     feeSetter = _feeSetter;
        // }

         function setUserMax(uint256 max_amount) external onlyOwner returns(bool){
            user_max_deposit_and_withdraw_amount = max_amount;
            return true;
        }

        function setWithdrawData(address user, uint256 amount) private{
            user_balance[user] = user_balance[user].add(amount);
        }

        // function setFee(uint256 _fee) external onlyFeeSetter returns(bool){
        //     fee = _fee;
        //     return true;
        // }

        function setTransfer(uint amount, bytes32 substrateAddress) public  
            updateUserDepositInfo(msg.sender, amount) 
            updateContractDepositInfo(amount){
            require(token.allowance(msg.sender, address(this)) >= amount, "contract is not allowed to this amount");
            
            token.transferFrom(msg.sender, address(this), amount);

            bytes32 messageID = keccak256(abi.encodePacked(now));

            Message  memory message = Message(messageID, msg.sender, substrateAddress, amount, Status.CONFIRMED);
            messages[messageID] = message;

            emit RelayMessage(messageID, msg.sender, substrateAddress, amount);
        }

        /*
        * Widthdraw finance by message ID when transfer pending
        */
        function revertTransfer(bytes32 messageID) public pendingMessage(messageID) {
            Message storage message = messages[messageID];
            require(message.spender == msg.sender, "DPRBridge: Not spender");
            message.status = Status.CANCELED;
            DepositInfo storage di = user_deposit_info[msg.sender];
            di.deposit_amount = di.deposit_amount.sub(message.availableAmount);
            DepositInfo storage cdi = contract_deposit_info;
            cdi.deposit_amount.sub(message.availableAmount);
            token.transfer(msg.sender, message.availableAmount);

            emit RevertMessage(messageID, msg.sender, message.availableAmount);
        }


        /*
        * Withdraw tranfer by message ID after approve from Substrate
        */
        function withdrawTransfer(bytes32  substrateSender, address recipient, uint availableAmount,bytes memory sig)  public
        updateContractWithdrawInfo(availableAmount)
         {  
            //require(msg.value == fee, "DPRBridge: Fee not match");
            require(token.balanceOf(address(this)) >= availableAmount, "DPRBridge: Balance is not enough");
            bytes32 messageID = keccak256(abi.encodePacked(substrateSender, recipient, availableAmount, block.timestamp));
            setMessageAndEmitEvent(messageID, substrateSender, recipient, availableAmount, sig);
        }

        function setMessageAndEmitEvent(bytes32 messageID, bytes32  substrateSender, address recipient, uint availableAmount, bytes memory sig) private {
             Message  memory message = Message(messageID, recipient, substrateSender, availableAmount, Status.WITHDRAW);
             messages[messageID] = message;
             emit WithdrawMessage(messageID,msg.sender , substrateSender, availableAmount, sig);
        }

        /*
        * Confirm Withdraw tranfer by message ID after approve from Substrate
        */
        function confirmWithdrawTransfer(bytes32 messageID, bytes memory signature) public withdrawMessage(messageID) 
        //onlyManyValidatorsConfirm(messageID, msg.sender) 
        {
            bytes32 data = keccak256(abi.encodePacked(messageID));
            bytes32 sign_data = keccak256(abi.encodePacked(SIGN_HASH_PREFIX, data));
            address recover_address = ECDSA.recover(sign_data, signature);
            require(recover_address == submiter, "DPRBridge: Address not match");
            Message storage message = messages[messageID];
            uint256 withdraw_amount = message.availableAmount;
            //setWithdrawData(message.spender, withdraw_amount);
            message.status = Status.CONFIRMED_WITHDRAW;
            token.safeTransfer(message.spender, withdraw_amount);
            emit ConfirmWithdrawMessage(messageID);
            
            
        }

        function withdrawAllTokens(IERC20 _token, uint256 amount) external onlyOwner{
            _token.safeTransfer(owner, amount);
        }

        function getUserBalance(address user) external view returns(uint256){
            return user_balance[user];
        }
}