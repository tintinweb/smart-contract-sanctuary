/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: openzeppelin-solidity/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/EIP712Base.sol

pragma solidity 0.6.6;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    constructor(string memory name) public {
        _setDomainSeperator(name);
    }
    
    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// File: contracts/NativeMetaTransaction.sol

pragma solidity 0.6.6;



contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name) public EIP712Base(name){
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;


contract EthermonEnum {

    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }
    
    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;


contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonDataBase.sol

pragma solidity 0.6.6;

interface EtheremonDataBase {

    // write
    function withdrawEther(address _sendTo, uint _amount) external returns(EthermonEnum.ResultCode);
    function addElementToArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);
    function updateIndexOfArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint _index, uint8 _value) external returns(uint);
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) external returns(uint32);
    function addMonsterObj(uint32 _classId, address _trainer, string calldata _name) external returns(uint64);
    function setMonsterObj(uint64 _objId, string calldata _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) external;
    function increaseMonsterExp(uint64 _objId, uint32 amount) external;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function clearMonsterReturnBalance(uint64 _monsterId) external returns(uint256 amount);
    function collectAllReturnBalance(address _trainer) external returns(uint256 amount);
    function transferMonster(address _from, address _to, uint64 _monsterId) external returns(EthermonEnum.ResultCode);
    function addExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function deductExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function setExtraBalance(address _trainer, uint256 _amount) external;
    
    // read
    function totalMonster() external view returns(uint256);
    function totalClass() external view returns(uint32);
    function getSizeArrayType(EthermonEnum.ArrayType _type, uint64 _id) external view returns(uint);
    function getElementInArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint _index) external view returns(uint8);
    function getMonsterClass(uint32 _classId) external view returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) external view returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterName(uint64 _objId) external view returns(string memory name);
    function getExtraBalance(address _trainer) external view returns(uint256);
    function getMonsterDexSize(address _trainer) external view returns(uint);
    function getMonsterObjId(address _trainer, uint index) external view returns(uint64);
    function getExpectedBalance(address _trainer) external view returns(uint256);
    function getMonsterReturn(uint64 _objId) external view returns(uint256 current, uint256 total);
}

// File: contracts/EtheremonWorld.sol

pragma solidity 0.6.6;








contract SafeMathEthermon {

    function safeAdd(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

abstract contract EtheremonGateway is EthermonEnum, BasicAccessControl {
    // using for battle contract later
    function increaseMonsterExp(uint64 _objId, uint32 amount) public virtual;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) public virtual;
    
    // read 
    function isGason(uint64 _objId) external view virtual returns(bool);
    function getObjBattleInfo(uint64 _objId) external view virtual returns(uint32 classId, uint32 exp, bool gason, 
        uint ancestorLength, uint xfactorsLength);
    function getClassPropertySize(uint32 _classId, PropertyType _type) external view virtual returns(uint);
    function getClassPropertyValue(uint32 _classId, PropertyType _type, uint index) external view virtual returns(uint32);
}

contract EtheremonWorld is EtheremonGateway, SafeMathEthermon, NativeMetaTransaction {
    using SafeERC20 for IERC20;

    // old processor
    address public ethermonProcessor;
    uint8 public constant STAT_COUNT = 6;
    uint8 public constant STAT_MAX = 32;
    uint8 public constant GEN0_NO = 24;
    
    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint createTime;
    }
    
    // Gen0 has return price & no longer can be caught when this contract is deployed
    struct Gen0Config {
        uint32 classId;
        uint256 originalPrice;
        uint256 returnPrice;
        uint32 total; // total caught (not count those from eggs)
    }
    
    struct GenXProperty {
        uint32 classId;
        bool isGason;
        uint32[] ancestors;
        uint32[] xfactors;
    }
    
    mapping(uint32 => Gen0Config) public gen0Config;
    mapping(uint32 => GenXProperty) public genxProperty;
    uint256 public totalCashout = 0; // for admin
    uint256 public totalEarn = 0; // exclude gen 0
    uint16 public priceIncreasingRatio = 1000;
    uint public maxDexSize = 500;
    
    address private lastHunter = address(0x0);

    // data contract
    address public dataContract;
    
    // event
    event EventCatchMonster(address indexed trainer, uint64 objId);
    event EventCashOut(address indexed trainer, ResultCode result, uint256 amount);
    event EventWithdrawEther(address indexed sendTo, ResultCode result, uint256 amount);

    //wrapped ether on matic
    IERC20 public weth;

    constructor(
        string memory name,
        address _weth,
        address _dataContract,
        address _ethermonProcessor
    )
        public
        NativeMetaTransaction(name)
    {
        weth = IERC20(_weth);
        dataContract = _dataContract;
        ethermonProcessor = _ethermonProcessor;
    }
 
     // admin & moderators
    function setMaxDexSize(uint _value) external onlyModerators {
        maxDexSize = _value;
    }
    
    function setOriginalPriceGen0() external onlyModerators {
        gen0Config[1] = Gen0Config(1, 0.3 ether, 0.003 ether, 374);
        gen0Config[2] = Gen0Config(2, 0.3 ether, 0.003 ether, 408);
        gen0Config[3] = Gen0Config(3, 0.3 ether, 0.003 ether, 373);
        gen0Config[4] = Gen0Config(4, 0.2 ether, 0.002 ether, 437);
        gen0Config[5] = Gen0Config(5, 0.1 ether, 0.001 ether, 497);
        gen0Config[6] = Gen0Config(6, 0.3 ether, 0.003 ether, 380); 
        gen0Config[7] = Gen0Config(7, 0.2 ether, 0.002 ether, 345);
        gen0Config[8] = Gen0Config(8, 0.1 ether, 0.001 ether, 518); 
        gen0Config[9] = Gen0Config(9, 0.1 ether, 0.001 ether, 447);
        gen0Config[10] = Gen0Config(10, 0.2 ether, 0.002 ether, 380); 
        gen0Config[11] = Gen0Config(11, 0.2 ether, 0.002 ether, 354);
        gen0Config[12] = Gen0Config(12, 0.2 ether, 0.002 ether, 346);
        gen0Config[13] = Gen0Config(13, 0.2 ether, 0.002 ether, 351); 
        gen0Config[14] = Gen0Config(14, 0.2 ether, 0.002 ether, 338);
        gen0Config[15] = Gen0Config(15, 0.2 ether, 0.002 ether, 341);
        gen0Config[16] = Gen0Config(16, 0.35 ether, 0.0035 ether, 384);
        gen0Config[17] = Gen0Config(17, 0.1 ether, 0.001 ether, 305); 
        gen0Config[18] = Gen0Config(18, 0.1 ether, 0.001 ether, 427);
        gen0Config[19] = Gen0Config(19, 0.1 ether, 0.001 ether, 304);
        gen0Config[20] = Gen0Config(20, 0.4 ether, 0.005 ether, 82);
        gen0Config[21] = Gen0Config(21, 1, 1, 123);
        gen0Config[22] = Gen0Config(22, 0.2 ether, 0.001 ether, 468);
        gen0Config[23] = Gen0Config(23, 0.5 ether, 0.0025 ether, 302);
        gen0Config[24] = Gen0Config(24, 1 ether, 0.005 ether, 195);
    }

    function getEarningAmount() public view returns(uint256) {
        // calculate value for gen0
        uint256 totalValidAmount = 0;
        for (uint32 classId=1; classId <= GEN0_NO; classId++) {
            // make sure there is a class
            Gen0Config storage gen0 = gen0Config[classId];
            if (gen0.total >0 && gen0.classId == classId && gen0.originalPrice > 0 && gen0.returnPrice > 0) {
                uint256 rate = gen0.originalPrice/gen0.returnPrice;
                if (rate < gen0.total) {
                    totalValidAmount += (gen0.originalPrice + gen0.returnPrice) * rate / 2;
                    totalValidAmount += (gen0.total - rate) * gen0.returnPrice;
                } else {
                    totalValidAmount += (gen0.originalPrice + gen0.returnPrice * (rate - gen0.total + 1)) / 2 * gen0.total;
                }
            }
        }
        
        // add in earn from genx
        totalValidAmount = safeAdd(totalValidAmount, totalEarn);
        // deduct amount of cashing out 
        totalValidAmount = safeSubtract(totalValidAmount, totalCashout);
        
        return totalValidAmount;
    }
    
    function withdrawEther(
        address _sendTo,
        uint _amount
    )
        external
        onlyModerators
        returns(ResultCode)
    {
        uint256 balance = weth.balanceOf(address(this));
        if (_amount > balance) {
            EventWithdrawEther(_sendTo, ResultCode.ERROR_INVALID_AMOUNT, 0);
            return ResultCode.ERROR_INVALID_AMOUNT;
        }
        
        uint256 totalValidAmount = getEarningAmount();
        if (_amount > totalValidAmount) {
            EventWithdrawEther(_sendTo, ResultCode.ERROR_INVALID_AMOUNT, 0);
            return ResultCode.ERROR_INVALID_AMOUNT;
        }
        
        weth.safeTransfer(_sendTo, _amount);
        totalCashout += _amount;
        EventWithdrawEther(_sendTo, ResultCode.SUCCESS, _amount);
        return ResultCode.SUCCESS;
    }

    // convenient tool to add monster
    function addMonsterClassBasic(uint32 _classId, uint8 _type, uint256 _price, uint256 _returnPrice,
        uint8 _ss1, uint8 _ss2, uint8 _ss3, uint8 _ss4, uint8 _ss5, uint8 _ss6) external onlyModerators {
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        // can add only one time
        if (_classId == 0 || class.classId == _classId)
            revert();

        data.setMonsterClass(_classId, _price, _returnPrice, true);
        data.addElementToArrayType(ArrayType.CLASS_TYPE, uint64(_classId), _type);
        
        // add stat step
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss1);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss2);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss3);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss4);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss5);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss6);
        
    }
    
    function addMonsterClassExtend(uint32 _classId, uint8 _type2, uint8 _type3, 
        uint8 _st1, uint8 _st2, uint8 _st3, uint8 _st4, uint8 _st5, uint8 _st6 ) external onlyModerators {

        EtheremonDataBase data = EtheremonDataBase(dataContract);
        if (_classId == 0 || data.getSizeArrayType(ArrayType.STAT_STEP, uint64(_classId)) > 0)
            revert();

        if (_type2 > 0) {
            data.addElementToArrayType(ArrayType.CLASS_TYPE, uint64(_classId), _type2);
        }
        if (_type3 > 0) {
            data.addElementToArrayType(ArrayType.CLASS_TYPE, uint64(_classId), _type3);
        }
        
        // add stat base
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st1);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st2);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st3);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st4);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st5);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st6);
    }
    
    function setCatchable(uint32 _classId, bool catchable) external onlyModerators {
        // can not edit gen 0 - can not catch forever
        Gen0Config storage gen0 = gen0Config[_classId];
        if (gen0.classId == _classId)
            revert();
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        data.setMonsterClass(class.classId, class.price, class.returnPrice, catchable);
    }
    
    function setPriceIncreasingRatio(uint16 _ratio) external onlyModerators {
        priceIncreasingRatio = _ratio;
    }
    
    function setGason(uint32 _classId, bool _isGason) external onlyModerators {
        GenXProperty storage pro = genxProperty[_classId];
        pro.isGason = _isGason;
    }
    
    function addClassProperty(uint32 _classId, PropertyType _type, uint32 value) external onlyModerators {
        GenXProperty storage pro = genxProperty[_classId];
        pro.classId = _classId;
        if (_type == PropertyType.ANCESTOR) {
            pro.ancestors.push(value);
        } else {
            pro.xfactors.push(value);
        }
    }
    
    // gate way 
    function increaseMonsterExp(uint64 _objId, uint32 amount) public override onlyModerators {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.increaseMonsterExp(_objId, amount);
    }
    
    function decreaseMonsterExp(uint64 _objId, uint32 amount) public override onlyModerators {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.decreaseMonsterExp(_objId, amount);
    }
    
    // helper
    function getRandom(uint8 maxRan, uint8 index, address priAddress) public view returns(uint8) {
        uint256 genNum = uint256(blockhash(block.number-1)) + uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i ++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }

    //MATIC: REPLACEMENT OF FALLBACK METHOD
    function depositEth(uint256 amount) external {
        require(msgSender() == ethermonProcessor, "Invalid access!!");

        //User needs to approve this contract to take weth on his/her behalf
        weth.safeTransferFrom(msgSender(), address(this), amount);

    }
    /**
    function () payable public {
        if (msgSender() != ethermonProcessor)
            revert();
    }*/
    
    // public
    
    function isGason(uint64 _objId) external view override returns(bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        GenXProperty storage pro = genxProperty[obj.classId];
        return pro.isGason;
    }
    
    function getObjIndex(uint64 _objId) public view returns(uint32 classId, uint32 createIndex, uint32 lastClaimIndex) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.createIndex, obj.lastClaimIndex);
    }
    
    function getObjBattleInfo(uint64 _objId) external view override returns(uint32 classId, uint32 exp, bool gason, 
        uint ancestorLength, uint xfactorsLength) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        GenXProperty storage pro = genxProperty[obj.classId];
        return (obj.classId, obj.exp, pro.isGason, pro.ancestors.length, pro.xfactors.length);
    }
    
    function getClassPropertySize(uint32 _classId, PropertyType _type) external view override returns(uint) {
        if (_type == PropertyType.ANCESTOR) 
            return genxProperty[_classId].ancestors.length;
        else
            return genxProperty[_classId].xfactors.length;
    }
    
    function getClassPropertyValue(uint32 _classId, PropertyType _type, uint index) external view override returns(uint32) {
        if (_type == PropertyType.ANCESTOR)
            return genxProperty[_classId].ancestors[index];
        else
            return genxProperty[_classId].xfactors[index];
    }
    
    // only gen 0
    function getGen0COnfig(uint32 _classId) public view returns(uint32, uint256, uint32) {
        Gen0Config storage gen0 = gen0Config[_classId];
        return (gen0.classId, gen0.originalPrice, gen0.total);
    }
    
    // only gen 0
    function getReturnFromMonster(uint64 _objId) public view returns(uint256 current, uint256 total) {
        /*
        1. Gen 0 can not be caught anymore.
        2. Egg will not give return.
        */
        
        uint32 classId = 0;
        uint32 createIndex = 0;
        uint32 lastClaimIndex = 0;
        (classId, createIndex, lastClaimIndex) = getObjIndex(_objId);
        Gen0Config storage gen0 = gen0Config[classId];
        if (gen0.classId != classId) {
            return (0, 0);
        }
        
        uint32 currentGap = 0;
        uint32 totalGap = 0;
        if (lastClaimIndex < gen0.total)
            currentGap = gen0.total - lastClaimIndex;
        if (createIndex < gen0.total)
            totalGap = gen0.total - createIndex;
        return (safeMult(currentGap, gen0.returnPrice), safeMult(totalGap, gen0.returnPrice));
    }
    
    // write access
    
    function moveDataContractBalanceToWorld() external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint256 balance = weth.balanceOf(address(data));
        data.withdrawEther(address(this), balance);
    }
    
    function renameMonster(uint64 _objId, string calldata name) external isActive  {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId || obj.trainer != msgSender()) {
            revert();
        }
        data.setMonsterObj(_objId, name, obj.exp, obj.createIndex, obj.lastClaimIndex);
    }
    
    //MATIC: HANDLING FOR ETH
    function catchMonster(
        uint32 _classId,
        string calldata _name,
        uint256 amount
    )
        external
        isActive
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        if (class.classId == 0 || class.catchable == false) {
            revert();
        }

        // can not keep too much etheremon
        if (data.getMonsterDexSize(msgSender()) > maxDexSize)
            revert();

        //User needs to approve this contract to transfer weth on his/her behalf
        weth.safeTransferFrom(msgSender(), address(this), amount);
        uint256 totalBalance = safeAdd(
            amount,
            data.getExtraBalance(msgSender())
        );
        uint256 payPrice = class.price;
        // increase price for each etheremon created
        if (class.total > 0)
            payPrice += class.price*(class.total-1)/priceIncreasingRatio;
        if (payPrice > totalBalance) {
            revert();
        }
        totalEarn += payPrice;
        
        // deduct the balance
        data.setExtraBalance(msgSender(), safeSubtract(totalBalance, payPrice));
        
        // add monster
        uint64 objId = data.addMonsterObj(_classId, msgSender(), _name);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            uint8 value = getRandom(STAT_MAX, uint8(i), lastHunter) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }
        
        lastHunter = msgSender();
        EventCatchMonster(msgSender(), objId);
    }


    function cashOut(uint256 _amount) public returns(ResultCode) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        uint256 totalAmount = data.getExtraBalance(msgSender());
        uint64 objId = 0;

        // collect gen 0 return price 
        uint dexSize = data.getMonsterDexSize(msgSender());
        for (uint i = 0; i < dexSize; i++) {
            objId = data.getMonsterObjId(msgSender(), i);
            if (objId > 0) {
                MonsterObjAcc memory obj;
                (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(objId);
                Gen0Config storage gen0 = gen0Config[obj.classId];
                if (gen0.classId == obj.classId) {
                    if (obj.lastClaimIndex < gen0.total) {
                        uint32 gap = uint32(safeSubtract(gen0.total, obj.lastClaimIndex));
                        if (gap > 0) {
                            totalAmount += safeMult(gap, gen0.returnPrice);
                            // reset total (except name is cleared :( )
                            data.setMonsterObj(obj.monsterId, " name me ", obj.exp, obj.createIndex, gen0.total);
                        }
                    }
                }
            }
        }
        
        // default to cash out all
        if (_amount == 0) {
            _amount = totalAmount;
        }
        if (_amount > totalAmount) {
            revert();
        }
        
        // check contract has enough money
        uint256 dataBalance = weth.balanceOf(address(data));
        uint256 balance = weth.balanceOf(address(this));

        if (balance + dataBalance < _amount){
            revert();
        } else if (balance < _amount) {
            data.withdrawEther(address(this), dataBalance);
        }
        
        if (_amount > 0) {
            data.setExtraBalance(msgSender(), totalAmount - _amount);
            (bool success,) = address(weth).call(abi.encodeWithSelector(IERC20.transfer.selector, msgSender(), _amount));

            if (!success) {
                data.setExtraBalance(msgSender(), totalAmount);
                EventCashOut(msgSender(), ResultCode.ERROR_SEND_FAIL, 0);
                return ResultCode.ERROR_SEND_FAIL;
            }
        }
        
        EventCashOut(msgSender(), ResultCode.SUCCESS, _amount);
        return ResultCode.SUCCESS;
    }
    
    // read access
    
    function getTrainerEarn(address _trainer) public view returns(uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint256 returnFromMonster = 0;
        // collect gen 0 return price 
        uint256 gen0current = 0;
        uint256 gen0total = 0;
        uint64 objId = 0;
        uint dexSize = data.getMonsterDexSize(_trainer);
        for (uint i = 0; i < dexSize; i++) {
            objId = data.getMonsterObjId(_trainer, i);
            if (objId > 0) {
                (gen0current, gen0total) = getReturnFromMonster(objId);
                returnFromMonster += gen0current;
            }
        }
        return returnFromMonster;
    }
    
    function getTrainerBalance(address _trainer) external view returns(uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        uint256 userExtraBalance = data.getExtraBalance(_trainer);
        uint256 returnFromMonster = getTrainerEarn(_trainer);

        return (userExtraBalance + returnFromMonster);
    }
    
    function getMonsterClassBasic(uint32 _classId) external view returns(uint256, uint256, uint256, bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        return (class.price, class.returnPrice, class.total, class.catchable);
    }

}

// File: contracts/EthermonTransformData.sol

/**
 *Submitted for verification at Etherscan.io on 2018-01-29
*/

pragma solidity 0.6.6;







// copyright [email protected]

contract EthermonTransformData is EthermonEnum, BasicAccessControl, SafeMathEthermon {

    struct MonsterEgg {
        uint64 eggId;
        uint64 objId;
        uint32 classId;
        address trainer;
        uint hatchTime;
        uint64 newObjId;
    }

    mapping(uint64 => uint64) public transformed; //objId -> newObjId

    // only moderators
    /*
    TO AVOID ANY BUGS, WE ALLOW MODERATORS TO HAVE PERMISSION TO ALL THESE FUNCTIONS AND UPDATE THEM IN EARLY BETA STAGE.
    AFTER THE SYSTEM IS STABLE, WE WILL REMOVE OWNER OF THIS SMART CONTRACT AND ONLY KEEP ONE MODERATOR WHICH IS ETHEREMON BATTLE CONTRACT.
    HENCE, THE DECENTRALIZED ATTRIBUTION IS GUARANTEED.
    */
    function setTranformed(uint64 _objId, uint64 _newObjId) onlyModerators external {
        transformed[_objId] = _newObjId;
    }

    function getTranformedId(uint64 _objId) view external returns(uint64) {
        return transformed[_objId];
    }
}

// File: contracts/EtheremonTransform.sol

/**
 *Submitted for verification at Etherscan.io on 2018-08-28
 */

pragma solidity 0.6.6;





// copyright [email protected]

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) external view returns (bool);
}

interface EtheremonMonsterNFTInterface {
    function mintMonster(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint256);

    function burnMonster(uint64 _tokenId) external;
}

interface EtheremonTransformSettingInterface {
    function getRandomClassId(uint256 _seed) external view returns (uint32);

    function getTransformInfo(uint32 _classId)
        external
        view
        returns (uint32 transformClassId, uint8 level);

    function getClassTransformInfo(uint32 _classId)
        external
        view
        returns (
            uint8 layingLevel,
            uint8 layingCost,
            uint8 transformLevel,
            uint32 transformCLassId
        );
}

contract EtheremonTransform is
    EthermonEnum,
    BasicAccessControl,
    SafeMathEthermon
{
    using SafeERC20 for IERC20;

    uint8 public constant STAT_COUNT = 6;
    uint8 public constant STAT_MAX = 32;
    uint8 public constant GEN0_NO = 24;
    IERC20 public weth;

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    struct BasicObjInfo {
        uint32 classId;
        address owner;
        uint8 level;
        uint32 exp;
    }

    mapping(uint8 => uint32) public levelExps;

    // linked smart contract
    address public dataContract;
    address public worldContract;
    address public transformDataContract;
    address public transformSettingContract;
    address public tradeContract;
    address public monsterNFTContract;

    // events
    event EventTransform(
        address indexed trainer,
        uint256 oldObjId,
        uint256 newObjId
    );

    // constructor
    constructor(
        address _dataContract,
        address _worldContract,
        address _transformDataContract,
        address _transformSettingContract,
        //address _battleContract,
        address _tradeContract,
        address _monsterNFTContract,
        address _weth
    ) public {
        dataContract = _dataContract;
        worldContract = _worldContract;
        transformDataContract = _transformDataContract;
        transformSettingContract = _transformSettingContract;
        //battleContract = _battleContract;
        tradeContract = _tradeContract;
        monsterNFTContract = _monsterNFTContract;

        weth = IERC20(_weth);
    }

    // admin & moderators
    function setContract(
        address _dataContract, //X
        address _worldContract, //X
        address _transformDataContract, //X
        address _transformSettingContract, //X
        address _tradeContract, //X
        address _monsterNFTContract //X
    ) external onlyModerators {
        dataContract = _dataContract;
        worldContract = _worldContract;
        transformDataContract = _transformDataContract;
        transformSettingContract = _transformSettingContract;
        tradeContract = _tradeContract;
        monsterNFTContract = _monsterNFTContract;
    }

    // write access
    function withdrawEther(address _sendTo, uint256 _amount) public onlyOwner {
        uint256 balance = weth.balanceOf(address(this));

        require(_amount <= balance, "Not enough balance!!");

        weth.safeTransfer(_sendTo, _amount);
    }

    /**
    Requires at least once initlization to generate required experience.
    */
    function genLevelExp() external onlyModerators {
        uint8 level = 1;
        uint32 requirement = 100;
        uint32 sum = requirement;
        while (level <= 100) {
            levelExps[level] = sum;
            level += 1;
            requirement = (requirement * 11) / 10 + 5;
            sum += requirement;
        }
    }

    // public

    function ceil(uint256 a, uint256 m) public pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

    function getLevel(uint32 exp) public view returns (uint8) {
        uint8 minIndex = 1;
        uint8 maxIndex = 100;
        uint8 currentIndex;

        while (minIndex < maxIndex) {
            currentIndex = (minIndex + maxIndex) / 2;
            if (exp < levelExps[currentIndex]) maxIndex = currentIndex;
            else minIndex = currentIndex + 1;
        }

        return minIndex;
    }

    function getObjClassExp(uint64 _objId)
        public
        view
        returns (
            uint32,
            address,
            uint32
        )
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        return (obj.classId, obj.trainer, obj.exp);
    }

    function getClassCheckOwner(uint64 _objId, address _trainer)
        public
        view
        returns (uint32)
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            _,
            _,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        if (_trainer != obj.trainer) return 0;
        return obj.classId;
    }

    /**
    Check mon_id or 1000+ mon_id(polygon verison) are both compatible as ancestor.
    */
    function checkAncestors(
        uint32 _classId,
        address _trainer,
        uint64 _a1,
        uint64 _a2,
        uint64 _a3
    ) public view returns (bool) {
        EtheremonWorld world = EtheremonWorld(worldContract);
        uint256 index = 0;
        uint32 temp = 0;
        // check ancestor
        uint32[3] memory ancestors;
        uint32[3] memory requestAncestors;
        index = world.getClassPropertySize(_classId, PropertyType.ANCESTOR);
        while (index > 0) {
            index -= 1;
            ancestors[index] = world.getClassPropertyValue(
                _classId,
                PropertyType.ANCESTOR,
                index
            );
        }

        if (_a1 > 0) {
            temp = getClassCheckOwner(_a1, _trainer);
            if (temp == 0) return false;
            requestAncestors[0] = temp;
        }
        if (_a2 > 0) {
            temp = getClassCheckOwner(_a2, _trainer);
            if (temp == 0) return false;
            requestAncestors[1] = temp;
        }
        if (_a3 > 0) {
            temp = getClassCheckOwner(_a3, _trainer);
            if (temp == 0) return false;
            requestAncestors[2] = temp;
        }

        if (
            requestAncestors[0] > 0 &&
            (requestAncestors[0] == requestAncestors[1] ||
                requestAncestors[0] == requestAncestors[2])
        ) return false;
        if (
            requestAncestors[1] > 0 &&
            (requestAncestors[1] == requestAncestors[2])
        ) return false;

        /**
    Update the logic for ancestor for mon_id and mon_id +1000(polygon version)
 */
        for (index = 0; index < ancestors.length; index++) {
            temp = ancestors[index];
            if (
                temp > 0 &&
                temp != requestAncestors[0] &&
                temp != requestAncestors[1] &&
                temp != requestAncestors[2]
            ) return false;
        }

        return true;
    }

    function transform(
        uint64 _objId,
        uint64 _a1,
        uint64 _a2,
        uint64 _a3
    ) external payable isActive {
        EthermonTransformData transformData = EthermonTransformData(
            transformDataContract
        );
        if (transformData.getTranformedId(_objId) > 0) revert();

        // if (battleContract != null) {
        //     EtheremonBattle battle = EtheremonBattle(battleContract);
        //     if (battle.isOnBattle(_objId)) revert();
        // }
        if (tradeContract != address(0)) {
            EtheremonTradeInterface trade = EtheremonTradeInterface(
                tradeContract
            );
            if (trade.isOnTrading(_objId)) revert();
        }

        BasicObjInfo memory objInfo;
        (objInfo.classId, objInfo.owner, objInfo.exp) = getObjClassExp(_objId);
        objInfo.level = getLevel(objInfo.exp);
        if (objInfo.classId == 0 || objInfo.owner != msg.sender) revert();

        uint32 transformClass;
        uint8 transformLevel;
        (transformClass, transformLevel) = EtheremonTransformSettingInterface(
            transformSettingContract
        ).getTransformInfo(objInfo.classId);
        if (transformClass == 0 || transformLevel == 0) revert();
        if (objInfo.level < transformLevel) revert();

        if (objInfo.classId > GEN0_NO)
            if (!checkAncestors(objInfo.classId, msg.sender, _a1, _a2, _a3))
                revert();

        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(
            monsterNFTContract
        );
        uint256 newObjId = monsterNFT.mintMonster(
            transformClass,
            msg.sender,
            "..name me..."
        );
        monsterNFT.burnMonster(_objId);

        transformData.setTranformed(_objId, uint64(newObjId));
        EventTransform(msg.sender, _objId, newObjId);
    }
}