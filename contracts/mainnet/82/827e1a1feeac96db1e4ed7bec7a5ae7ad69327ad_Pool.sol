// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
  address s_owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    s_owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == s_owner, "Ownable: not owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner virtual {
    require(newOwner != address(0), "Ownable: 0 cannot be owner");
    emit OwnershipTransferred(s_owner, newOwner);
    s_owner = newOwner;
  }

}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
abstract contract Claimable is Ownable {
  address s_pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == s_pendingOwner, "Claimable: not pending owner");
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner override {
    s_pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(s_owner, s_pendingOwner);
    s_owner = s_pendingOwner;
    s_pendingOwner = address(0);
  }
}

struct Account {
    uint256 nonce;  
    uint256 balance;
    uint256 issueBlock;
    uint256 pending;
    uint256 withdrawal;
    uint256 releaseBlock;
    bytes32 secretHash;
}

library AccountUtils {
    using SafeMath for uint256;

    function initNonce(Account storage self) internal {
        if (self.nonce == 0) {
            self.nonce =
                uint256(1) << 240 |
                uint256(blockhash(block.number-1)) << 80 >> 32 |
                now;
        }
    }

    function updateNonce(Account storage self) internal {
        uint256 count = self.nonce >> 240;
        uint256 nonce = 
            ++count << 240 |
            uint256(blockhash(block.number-1)) << 80 >> 32 |
            now;
        require(uint16(self.nonce) != uint16(nonce), "Pool: too soon");
        self.nonce = nonce;
    }
    
    function acceptPending(Account storage self, uint256 value) internal {
        uint256 pending = self.pending;
        require(pending > 0, "Pool: no pending tokens");
        require(pending == value, "Pool: value must equal issued tokens");
        self.secretHash = 0;
        self.pending = 0;
        self.balance = self.balance.add(pending);
    }

    function take(Account storage self, uint256 value) internal {
        self.balance = self.balance.add(value);
    }

    function payment(Account storage self, uint256 value) internal {
        self.balance = self.balance.sub(value);
    }

    function deposit(Account storage self, uint256 value) internal {
        self.balance = self.balance.add(value);
    }

    function withdraw(Account storage self, uint256 value) internal {
        self.withdrawal = 0;
        self.releaseBlock = 0;
        self.balance = self.balance.sub(value);
    }
}

struct Supply {
    uint256 total;
    uint256 minimum;
    uint256 pending;
}

library SupplyUtils {
    using SafeMath for uint256;

    // event MinimumReached(uint256 before, uint256 delta);

    modifier checkAvailability(Supply storage self) {
        _;
        require(self.total >= self.minimum.add(self.pending), "Pool: not enough available tokens");
    }

    // modifier safeReduceMinimum(Supply storage self, uint256 value) {
    //     self.minimum > value ? self.minimum -= value : self.minimum = 0; 
    //     if (self.minimum == 0) {
    //       emit MinimumReached(self.minimum, value);
    //     }
    //     _;
    // }

    function updatePending(Supply storage self, uint256 from, uint256 to) internal checkAvailability(self) { 
        self.pending = self.pending.add(to).sub(from, "Pool: not enough available tokens");       
    }

    function acceptPending(Supply storage self, uint256 value) internal {
        self.pending = self.pending.sub(value, "Pool: not enough pending");
        self.minimum = self.minimum.add(value);
    }

    function give(Supply storage self, uint256 value) internal checkAvailability(self) {
        self.minimum = self.minimum.add(value);
    }

    function payment(Supply storage self, uint256 value) internal /*safeReduceMinimum(self, value)*/ {
        self.minimum = self.minimum.sub(value); // this line should be remove if using safeReduceMinimum modifier
    }

    function deposit(Supply storage self, uint256 value) internal {
        self.minimum = self.minimum.add(value);
        self.total = self.total.add(value);
    }

    function widthdraw(Supply storage self, uint256 value) internal /*safeReduceMinimum(self, value)*/ checkAvailability(self) {
        self.minimum = self.minimum.sub(value); // this line should be remove if using safeReduceMinimum modifier
        self.total = self.total.sub(value);
    }

    function decrease(Supply storage self, uint256 value) internal checkAvailability(self) {
        self.total = self.total.sub(value, "Pool: value larger than total");
    }

    function update(Supply storage self, uint256 value) internal checkAvailability(self) {
        self.total = value;
    }

    function available(Supply storage self) internal view returns (uint256) {
        return self.total.sub(self.minimum.add(self.pending));
    }
}

struct Limits {
    uint256 releaseDelay;
    uint256 maxTokensPerIssue;
    uint256 maxTokensPerBlock;
}

struct Entities {
    address manager;
    address token;
    address wallet;
}

contract Pool is Claimable {
    using AccountUtils for Account;
    using SupplyUtils for Supply;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 private s_uid;
    Supply private s_supply;
    Limits private s_limits;
    Entities private s_entities;
    uint256 private s_lastIssuedBlock;
    uint256 private s_totalIssuedInBlock;

    mapping(address => Account) private s_accounts;

    uint8 public constant VERSION_NUMBER = 0x1;
    uint256 public constant MAX_RELEASE_DELAY = 11_520; // about 48h
    string public constant NAME = "Kirobo Pool";
    string public constant VERSION = "1";
    bytes32 public DOMAIN_SEPARATOR;
    bytes public DOMAIN_SEPARATOR_ASCII;
    uint256 public CHAIN_ID;

    // keccak256("acceptTokens(address recipient,uint256 value,bytes32 secretHash)");
    bytes32 public constant ACCEPT_TYPEHASH = 0xf728cfc064674dacd2ced2a03acd588dfd299d5e4716726c6d5ec364d16406eb;

    // keccak256("payment(address from,uint256 value,uint256 nonce)");
    bytes32 public constant PAYMENT_TYPEHASH = 0x841d82f71fa4558203bb763733f6b3326ecaf324143e12fb9b6a9ed958fc4ee0;

    // keccak256("buyTokens(address recipient,uint256 eth,uint256 kiro,uint256 expires)");
    bytes32 public constant BUY_TYPEHASH = 0x866880cdfbc2380b3f4581d70707601f3d190bc04c3ee9cfcdac070a5f87b758;

    event TokensIssued(address indexed account, uint256 value, bytes32 secretHash);
    event TokensAccepted(address indexed account, bool directCall);
    event TokensDistributed(address indexed account, uint256 value);
    event Payment(address indexed account, uint256 value);
    event Deposit(address indexed account, uint256 value);
    event WithdrawalRequested(address indexed account, uint256 value);
    event WithdrawalCanceled(address indexed account);
    event Withdrawal(address indexed account, uint256 value);
    event EtherTransfered(address indexed to, uint256 value);
    event TokensTransfered(address indexed to, uint256 value);
    event ManagerChanged(address from, address to);
    event WalletChanged(address from, address to);
    event ReleaseDelayChanged(uint256 from, uint256 to);
    event MaxTokensPerIssueChanged(uint256 from, uint256 to);
    event MaxTokensPerBlockChanged(uint256 from, uint256 to);

    modifier onlyAdmins() {
        require(msg.sender == s_owner || msg.sender == s_entities.manager, "Pool: not owner or manager");
        _;
    }

    constructor(address tokenContract) public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
     
        s_entities.token = tokenContract;
        s_limits = Limits({releaseDelay: 240, maxTokensPerIssue: 10*1000*(10**18), maxTokensPerBlock: 50*1000*(10**18)});
        s_uid = bytes32(
          uint256(VERSION_NUMBER) << 248 |
          uint256(blockhash(block.number-1)) << 192 >> 16 |
          uint256(address(this))
        );

        CHAIN_ID = chainId;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                chainId,
                address(this),
                s_uid
            )
        );
        DOMAIN_SEPARATOR_ASCII = _hashToAscii(
            DOMAIN_SEPARATOR
        );
    }

    receive () external payable {
        require(false, "Pool: not accepting ether");
    }


    // ----------- Owner Functions ------------


    function setManager(address manager) external onlyOwner() {
        require(manager != address(this), "Pool: self cannot be mananger");
        require(manager != s_entities.token, "Pool: token cannot be manager");
        emit ManagerChanged(s_entities.manager, manager);
        s_entities.manager = manager;
    }

    function setWallet(address wallet) external onlyOwner() {
        require(wallet != address(this), "Pool: self cannot be wallet");
        require(wallet != s_entities.token, "Pool: token cannot be wallt");
        emit WalletChanged(s_entities.wallet, wallet);
        s_entities.wallet = wallet;
    }

    function setReleaseDelay(uint256 blocks) external onlyOwner() {
        require(blocks <= MAX_RELEASE_DELAY, "Pool: exeeds max release delay");
        emit ReleaseDelayChanged(s_limits.releaseDelay, blocks);
        s_limits.releaseDelay = blocks;
    }

    function setMaxTokensPerIssue(uint256 tokens) external onlyOwner() {
        emit MaxTokensPerIssueChanged(s_limits.maxTokensPerIssue, tokens);
        s_limits.maxTokensPerIssue = tokens;
    }

    function setMaxTokensPerBlock(uint256 tokens) external onlyOwner() {
        emit MaxTokensPerBlockChanged(s_limits.maxTokensPerBlock, tokens);
        s_limits.maxTokensPerBlock = tokens;
    }

    function resyncTotalSupply(uint256 value) external onlyAdmins() returns (uint256) {
        uint256 tokens = ownedTokens();
        require(tokens >= s_supply.total, "Pool: internal error, check contract logic"); 
        require(value >= s_supply.total, "Pool: only transferTokens can decrease total supply");
        require(value <= tokens, "Pool: not enough tokens");
        s_supply.update(value);
    }


    // ----------- Admins Functions ------------


    function transferEther(uint256 value) external onlyAdmins() {
        require(s_entities.wallet != address(0), "Pool: wallet not set");
        payable(s_entities.wallet).transfer(value);
        emit EtherTransfered(s_entities.wallet, value);
    }

    function transferTokens(uint256 value) external onlyAdmins() {
        require(s_entities.wallet != address(0), "Pool: wallet not set");
        s_supply.decrease(value);
        IERC20(s_entities.token).safeTransfer(s_entities.wallet, value);
        emit TokensTransfered(s_entities.wallet, value);
    }

    function distributeTokens(address to, uint256 value) external onlyAdmins() {
        _distributeTokens(to, value);
    }
    
    function _distributeTokens(address to, uint256 value) private {
        require(value <= s_limits.maxTokensPerIssue, "Pool: exeeds max tokens per call");
        require(s_accounts[to].issueBlock < block.number, "Pool: too soon");
        _validateTokensPerBlock(value);
        Account storage sp_account = s_accounts[to];
        sp_account.issueBlock = block.number;
        sp_account.initNonce();
        s_supply.give(value);
        sp_account.take(value);
        emit TokensDistributed(to, value);
    }

    /**
     * @dev Issueing tokens for an address to be used for payments.
     * The owner of the receiving address must accept via a signed message or a direct call.
     * @param to The tokens recipient. 
     * @param value The number of tokens to issue.
     * @param secretHash The keccak256 of the confirmation secret.
    */
    function issueTokens(address to, uint256 value, bytes32 secretHash) external onlyAdmins() {
        require(value <= s_limits.maxTokensPerIssue, "Pool: exeeds max tokens per call");
        _validateTokensPerBlock(value);
        Account storage sp_account = s_accounts[to];
        uint256 prevPending = sp_account.pending;
        sp_account.initNonce();
        sp_account.secretHash = secretHash;
        sp_account.pending = value;
        sp_account.issueBlock = block.number;
        s_supply.updatePending(prevPending, value);
        emit TokensIssued(to, value, secretHash);
    }

    function executeAcceptTokens(
        address recipient,
        uint256 value,
        bytes calldata c_secret,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool eip712
    )
        external 
        onlyAdmins()
    {
        require(s_accounts[recipient].secretHash == keccak256(c_secret), "Pool: wrong secret");
        require(
            validateAcceptTokens(recipient, value, keccak256(c_secret), v, r ,s, eip712),
            "Pool: wrong signature or data"
        );
        _acceptTokens(recipient, value);
        emit TokensAccepted(recipient, false);
    }

    function executePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s, bool eip712)
        external
        onlyAdmins()
    {
        require(validatePayment(from, value, v, r, s, eip712), "Pool: wrong signature or data");
        Account storage sp_account = s_accounts[from];
        sp_account.updateNonce();
        sp_account.payment(value);
        s_supply.payment(value);
        emit Payment(from, value);
    }
  

    // ----------- External Functions ------------


    function executeBuyTokens(uint256 kiro, uint256 expires, uint8 v, bytes32 r, bytes32 s, bool eip712) 
        external
        payable
    {
        require(validateBuyTokens(msg.sender, msg.value, kiro, expires, v, r, s, eip712), "Pool: wrong signature or data");
        require(now <= expires, "Pool: too late");
        _distributeTokens(msg.sender, kiro);
    }

    function acceptTokens(uint256 value, bytes calldata c_secret) external {
        require(s_accounts[msg.sender].secretHash == keccak256(c_secret), "Pool: wrong secret");
        _acceptTokens(msg.sender, value);
        emit TokensAccepted(msg.sender, true);
    }

    function depositTokens(uint256 value) external {
        // require(
        //     IERC20(s_entities.token).allowance(msg.sender, address(this)) >= value,
        //    "IERC20 allowance too low"
        // );
        Account storage sp_account = s_accounts[msg.sender]; 
        sp_account.initNonce();
        sp_account.deposit(value);
        s_supply.deposit(value);
        IERC20(s_entities.token).safeTransferFrom(msg.sender, address(this), value);
        emit Deposit(msg.sender, value);
    }

    function requestWithdrawal(uint256 value) external {
        require(s_accounts[msg.sender].balance >= value, "Pool: not enough tokens");
        require(value > 0, "Pool: withdrawal value must be larger then 0");
        s_accounts[msg.sender].withdrawal = value;
        s_accounts[msg.sender].releaseBlock = block.number + s_limits.releaseDelay;
        emit WithdrawalRequested(msg.sender, value);
    }

    function cancelWithdrawal() external {
        s_accounts[msg.sender].withdrawal = 0;
        s_accounts[msg.sender].releaseBlock = 0;
        emit WithdrawalCanceled(msg.sender);
    }

    function withdrawTokens() external {
        Account storage sp_account = s_accounts[msg.sender];   
        require(sp_account.withdrawal > 0, "Pool: no withdraw request");
        require(sp_account.releaseBlock <= block.number, "Pool: too soon");
        uint256 value = sp_account.withdrawal > sp_account.balance ? sp_account.balance : sp_account.withdrawal;
        sp_account.withdraw(value);
        s_supply.widthdraw(value);
        IERC20(s_entities.token).safeTransfer(msg.sender, value);
        emit Withdrawal(msg.sender, value);
    }

    function account(address addr) external view
        returns (
            uint256 nonce,  
            uint256 balance,
            uint256 issueBlock,
            uint256 pending,
            uint256 withdrawal,
            uint256 releaseBlock,
            bytes32 secretHash,
            uint256 externalBalance
        ) 
    {
        Account storage sp_account = s_accounts[addr];
        uint256 extBalance = IERC20(s_entities.token).balanceOf(addr);
        return (
            sp_account.nonce,
            sp_account.balance,
            sp_account.issueBlock,
            sp_account.pending,
            sp_account.withdrawal,
            sp_account.releaseBlock,
            sp_account.secretHash,
            extBalance
        );
    }

    function entities() view external
        returns (
            address manager,
            address token,
            address wallet
        )
    {
        return (
            s_entities.manager,
            s_entities.token,
            s_entities.wallet
        );
    }

    function limits() external view
        returns (
            uint256 releaseDelay, 
            uint256 maxTokensPerIssue,
            uint256 maxTokensPerBlock
        )
    {
        return (
            s_limits.releaseDelay,
            s_limits.maxTokensPerIssue,
            s_limits.maxTokensPerBlock
        );
    }

    function supply() view external 
        returns (
            uint256 total,
            uint256 minimum,
            uint256 pending,
            uint256 available
        ) 
    {
        return (
            s_supply.total,
            s_supply.minimum,
            s_supply.pending,
            s_supply.available()
        );
    }

    function uid() view external returns (bytes32) {
        return s_uid;
    }

    function totalSupply() view external returns (uint256) {
        return s_supply.total;
    }

    function availableSupply() view external returns (uint256) {
        return s_supply.available();
    }


    // ----------- Public Functions ------------


    function generateBuyTokensMessage(address recipient, uint256 eth, uint256 kiro, uint256 expires)
        public view
        returns (bytes memory)
    {
        Account storage sp_account = s_accounts[recipient]; 
    
        return abi.encode(
            BUY_TYPEHASH,
            recipient,
            eth,
            kiro,
            expires,
            sp_account.issueBlock
        );
    }

    function generateAcceptTokensMessage(address recipient, uint256 value, bytes32 secretHash)
        public view 
        returns (bytes memory)
    {
        require(s_accounts[recipient].secretHash == secretHash, "Pool: wrong secret hash");
        require(s_accounts[recipient].pending == value, "Pool: value must equal pending(issued tokens)");
            
        return abi.encode(
            ACCEPT_TYPEHASH,
            recipient,
            value,
            secretHash
        );
    }

    function generatePaymentMessage(address from, uint256 value)
        public view
        returns (bytes memory)
    {
        Account storage sp_account = s_accounts[from]; 
        require(sp_account.balance >= value, "Pool: account balnace too low");
        
        return abi.encode(
            PAYMENT_TYPEHASH,
            from,
            value,
            sp_account.nonce
        );
    }

    function validateBuyTokens(
        address from,
        uint256 eth,
        uint256 kiro,
        uint256 expires,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool eip712
    )
        public view 
        returns (bool)
    {
        bytes32 message = _messageToRecover(
            keccak256(generateBuyTokensMessage(from, eth, kiro, expires)),
            eip712
        );
        address addr = ecrecover(message, v, r, s);
        return addr == s_entities.manager;      
    }

    function validateAcceptTokens(
        address recipient,
        uint256 value,
        bytes32 secretHash,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool eip712
    )
        public view 
        returns (bool)
    {
        bytes32 message = _messageToRecover(
            keccak256(generateAcceptTokensMessage(recipient, value, secretHash)),
            eip712
        );
        address addr = ecrecover(message, v, r, s);
        return addr == recipient;
    }

    function validatePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s, bool eip712)
        public view 
        returns (bool)
    {
        bytes32 message = _messageToRecover(
            keccak256(generatePaymentMessage(from, value)),
            eip712
        );
        address addr = ecrecover(message, v, r, s);
        return addr == from;      
    }

    function ownedTokens() view public returns (uint256) {
        return IERC20(s_entities.token).balanceOf(address(this));
    }


    // ----------- Private Functions ------------


    function _validateTokensPerBlock(uint256 value) private {
        if (s_lastIssuedBlock < block.number) {
            s_lastIssuedBlock = block.number;
            s_totalIssuedInBlock = value;
        } else {
            s_totalIssuedInBlock.add(value);
        }
        require(s_totalIssuedInBlock <= s_limits.maxTokensPerBlock, "Pool: exeeds max tokens per block");
    }

    function _acceptTokens(address recipient, uint256 value) private {
        require(s_accounts[recipient].issueBlock < block.number, "Pool: too soon");
        s_accounts[recipient].acceptPending(value);
        s_supply.acceptPending(value);
    }

    function _messageToRecover(bytes32 hashedUnsignedMessage, bool eip712)
        private view 
        returns (bytes32)
    {
        if (eip712) {
            return keccak256(abi.encodePacked
            (
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashedUnsignedMessage
            ));
        }
        return keccak256(abi.encodePacked
        (
            "\x19Ethereum Signed Message:\n128",
            DOMAIN_SEPARATOR_ASCII,
            _hashToAscii(hashedUnsignedMessage)
        ));
    }

    function _hashToAscii(bytes32 hash) private pure returns (bytes memory) {
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            byte  b = hash[i];
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return s;
    }

    function _char(byte b) private pure returns (byte c) {
        if (b < byte(uint8(10))) {
            return byte(uint8(b) + 0x30);
        } else {
            return byte(uint8(b) + 0x57);
        }
    }

}