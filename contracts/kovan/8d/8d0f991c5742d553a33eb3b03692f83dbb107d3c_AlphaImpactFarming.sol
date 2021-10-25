/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

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
 * It accepts deposits of a pre-defined ERC-20 token(s), the "deposit" token.
 * The deposit token will be repaid with another ERC-20 token, the "repay"
 * token (e.g. a stable-coin), at a pre-defined rate.
 *
 * On top of the deposit token, a particular NFT (ERC-1155) instance may be
 * required to be deposited as well. If so, this exact NFT will be returned.
 *
 * Note the `treasury` account that borrows and repays tokens.
 */

contract TokenList {

    // "Listed" (hard-coded) tokens
    address private AlphaImpactAddr = 0x6d7a1E1A22255b5151ED029e778Ccd172aeEfaB1;

    // Index of _extraTokens[0] + 1
    uint256 private constant extraTokensStartId = 2;

    enum TokenType {unknown, Erc20, Erc721, Erc1155}

    struct Token {
        address addr;
        TokenType _type;
    }

    // Extra tokens (addition to the hard-coded tokens list)
    Token[] private _extraTokens;

    // Declared "internal virtual" to let tests (mocks) re-define it
    function _listedToken(
        uint8 tokenId
    ) internal view virtual returns(address, TokenType) {
        if (tokenId == 1) return (AlphaImpactAddr, TokenType.Erc20);

        return (address(0), TokenType.unknown);
    }

    function _tokenAddr(uint8 tokenId) internal view returns(address) {
        (address addr, ) = _token(tokenId);
        return addr;
    }

    function _token(
        uint8 tokenId
    ) internal view returns(address, TokenType) {
        if (tokenId < extraTokensStartId) return _listedToken(tokenId);

        uint256 i = tokenId - extraTokensStartId;
        Token memory token = _extraTokens[i];
        return (token.addr, token._type);
    }

    function _addTokens(
        address[] memory addresses,
        TokenType[] memory types
    ) internal {
        require(
            addresses.length + _extraTokens.length + extraTokensStartId <= 256,
            "TokList:TOO_MANY_TOKENS"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "TokList:INVALID_TOKEN_ADDRESS");
            require(types[i] != TokenType.unknown, "TokList:INVALID_TOKEN_TYPE");
            _extraTokens.push(Token(addresses[i], types[i]));
        }
    }
}


contract AlphaImpactFarming is Ownable, ReentrancyGuard, TokenList {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Limit {
        // Min token amount to deposit
        uint224 minAmount;
        // Max deposit amount multiplier, scaled by 1e+4
        // (no limit, if set to 0):
        // `maxAmount = minAmount * maxAmountFactor/1e4`
        uint32 maxAmountFactor;
    }

    struct TermSheet {
        // If depositing under this term sheet is enabled
        bool enabled;
        // ID of the ERC-20 token to deposit
        uint8 inTokenId;
        // ID of the ERC-1155 token (contract) to deposit
        // (if set to 0, no ERC-1155 token required)
        uint8 nfTokenId;
        // ID of the ERC-20 token to return instead of the deposited token
        uint8 outTokenId;
        // Maximum amount that may be withdrawn before the deposit period ends,
        // in 1/255 shares of the deposit amount
        // (it linearly increases with time from zero on depositing up to this
        // value by the deposit period end)
        uint8 earlyWithdrawShare;
        // Fees on early withdrawal, in 1/255 shares of the amount withdrawn
        // (fees linearly decline to zero towards the repayment time)
        uint8 earlyWithdrawFees;
        // ID (index in `_limits` array + 1) of the deposit amount limit
        // (if set to 0, no limitations applied)
        uint16 limitId;
        // Deposit period in hours
        uint16 depositHours;
        // Min time between interim (early) withdrawals
        // (if set to 0, interim withdrawals disallowed)
        uint16 minInterimHours;
        // Rate to compute the "repay" amount, scaled by 1e+6 (see (1))
        uint64 rate;
        // Bit-mask for NFT IDs (in the range 1..64) allowed to deposit
        // (if set to 0, no limitations on NFT IDs applied)
        uint64 allowedNftNumBitMask;
    }

    // On a deposit withdrawal, a user receives the "repay" token,
    // (but not the originally deposited ERC-20 token).
    // The amount, in the  "repay" token units, is calculated as:
    // `amountDue = Deposit.amount * TermSheet.rate/1e+6`         (1)

    struct Deposit {
        uint160 amountDue;      // Amount due, in "repay" token units
        uint32 repaymentTime;   // time the final withdrawal is allowed since
        uint32 lastWithdrawTime;// time of the most recent interim withdrawal
        uint16 termsId;         // Term Sheet ID (index in `_termSheets` + 1)
        uint16 nftId;           // ID of the deposited NFT instance, if any
    }

    // Deposits of a user
    struct UserDeposits {
        // Set of (unique) deposit IDs
        uint256[] ids;
        // Mapping from deposit ID to deposit data
        mapping(uint256 => Deposit) data;
    }

    // Number of deposits made so far
    uint32 public depositQty;

    // Account that controls the tokens deposited
    address public treasury;

    // Limits on "deposit" token amount
    Limit[] private _limits;

    // Info on each TermSheet
    TermSheet[] internal _termSheets;

    // Mappings from a "repay" token ID to the amount due
    mapping(uint256 => uint256) public amountsDue; // in "repay" token units

    // Mapping from user account to user deposits
    mapping(address => UserDeposits) internal deposits;

    event NewDeposit(
        uint256 indexed inTokenId,
        uint256 indexed outTokenId,
        address indexed user,
        uint256 depositId,
        uint256 termsId,
        uint256 amount, // amount deposited (in deposit token units)
        uint256 amountDue, // amount to be returned (in "repay" token units)
        uint256 repaymentTime // UNIX-time when the deposit is unlocked
    );

    // User withdraws the deposit
    event Withdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount // amount sent to user (in deposit token units)
    );

    event InterimWithdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount, // amount sent to user (in "repay" token units)
        uint256 fees // withheld fees (in "repay" token units)
    );

    // termsId is the index in the `_termSheets` array + 1
    event NewTermSheet(uint256 indexed termsId);
    event TermsEnabled(uint256 indexed termsId);
    event TermsDisabled(uint256 indexed termsId);

    constructor(address _treasury) public {
        _setTreasury(_treasury);
    }

    // Note, `serialNum` identifies a deposit, rest is for gas saving & UI sake
    function encodeDepositId(
        uint256 serialNum,     // Unique (incremental) ID
        uint256 outTokenId,    // ID of the ERC-20 to repay deposit in
        uint256 nfTokenId,     // ID of the (contract of) deposited ERC-1155
        uint256 nftId          // ID of the deposited NFT instance
    ) public pure returns (uint256 depositId) {
        depositId = serialNum<<32 | outTokenId<<24 | nfTokenId<<16 | nftId;
    }

    function decodeDepositId(uint256 depositId) public pure
    returns (
        uint256 serialNum,
        uint8 outTokenId,
        uint8 nfTokenId,
        uint16 nftId
    ) {
        serialNum = depositId >> 32;
        outTokenId = uint8(depositId >> 24);
        nfTokenId = uint8(depositId >> 16);
        nftId = uint16(depositId);
    }

    function depositIds(
        address user
    ) external view returns (uint256[] memory) {
        _revertZeroAddress(user);
        UserDeposits storage userDeposits = deposits[user];
        return userDeposits.ids;
    }

    function depositData(
        address user,
        uint256 depositId
    ) external view returns (Deposit memory) {
        return deposits[_nonZeroAddr(user)].data[depositId];
    }

    function termSheet(
        uint256 termsId
    ) external view returns (TermSheet memory) {
        return _termSheets[_validTermsID(termsId) - 1];
    }

    function termSheetsNum() external view returns (uint256) {
        return _termSheets.length;
    }

    function allTermSheets() external view returns(TermSheet[] memory) {
        return _termSheets;
    }

    function depositLimits(
        uint256 limitId
    ) external view returns (Limit memory) {
        return _limits[_validLimitID(limitId) - 1];
    }

    function depositLimitsNum() external view returns (uint256) {
        return _limits.length;
    }

    function allDepositLimits() external view returns(Limit[] memory)
    {
        return _limits;
    }

    function getTokenData(
        uint256 tokenId
    ) external view returns(address, TokenType) {
        return _token(uint8(tokenId));
    }

    function computeEarlyWithdrawal(
        address user,
        uint256 depositId
    ) external view returns (uint256 amountToUser, uint256 fees) {
        Deposit memory _deposit = deposits[user].data[depositId];
        require(_deposit.amountDue != 0, "AIFARM:unknown or repaid deposit");
        TermSheet memory tS = _termSheets[_deposit.termsId - 1];

        (amountToUser, fees) = _computeEarlyWithdrawal(_deposit, tS, now);
    }

    function deposit(
        uint256 termsId,    // term sheet ID
        uint256 amount,     // amount in deposit token units
        uint256 nftId       // ID of the NFT instance (0 if no NFT required)
    ) public nonReentrant {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        require(tS.enabled, "AIFARM:terms disabled or unknown");

        if (tS.limitId != 0) {
            Limit memory l = _limits[tS.limitId - 1];
            require(amount >= l.minAmount, "AIFARM:too small deposit amount");
            if (l.maxAmountFactor != 0) {
                require(
                    amount <=
                        uint256(l.minAmount).mul(l.maxAmountFactor).div(1e4),
                    "AIFARM:too big deposit amount"
                );
            }
        }

        uint256 serialNum = depositQty + 1;
        depositQty = uint32(serialNum); // overflow risk ignored

        uint256 depositId = encodeDepositId(
            serialNum,
            tS.outTokenId,
            tS.nfTokenId,
            nftId
        );

        uint256 amountDue = amount.mul(tS.rate).div(1e6);
        require(amountDue < 2**160, "AIFARM:O2");
        uint32 repaymentTime = safe32(now.add(uint256(tS.depositHours) *3600));

        if (tS.nfTokenId == 0) {
            require(nftId == 0, "AIFARM:unexpected non-zero nftId");
        } else {
            require(
                nftId < 2**16 &&
                _isAllowedNftId(nftId, tS.allowedNftNumBitMask),
                "AIFARM:disallowed NFT instance"
            );
        }

        IERC20(_tokenAddr(tS.inTokenId))
            .safeTransferFrom(msg.sender, treasury, amount);

        _registerDeposit(
            deposits[msg.sender],
            depositId,
            Deposit(
                uint160(amountDue),
                repaymentTime,
                safe32(now),
                uint16(termsId),
                uint8(nftId)
            )
        );
        amountsDue[tS.outTokenId] = amountsDue[tS.outTokenId].add(amountDue);

        emit NewDeposit(
            tS.inTokenId,
            tS.outTokenId,
            msg.sender,
            depositId,
            termsId,
            amount,
            amountDue,
            repaymentTime
        );
    }

    // Entirely withdraw the deposit (when the deposit period ends)
    function withdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, false);
    }

    // Early withdrawal of the unlocked "repay" token amount (beware of fees!!)
    function interimWithdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, true);
    }

    function addTerms(TermSheet[] memory termSheets) public onlyOwner {
        for (uint256 i = 0; i < termSheets.length; i++) {
            _addTermSheet(termSheets[i]);
        }
    }

    function enableTerms(uint256 termsId) external onlyOwner {
        _termSheets[_validTermsID(termsId) - 1].enabled = true;
        emit TermsEnabled(termsId);
    }

    function disableTerms(uint256 termsId) external onlyOwner {
        _termSheets[_validTermsID(termsId) - 1].enabled = false;
        emit TermsDisabled(termsId);
    }

    function addLimits(Limit[] memory limits) public onlyOwner {
        for (uint256 i = 0; i < limits.length; i++) {
            _addLimit(limits[i]);
        }
    }

    function addTokens(
        address[] memory addresses,
        TokenType[] memory types
    ) external onlyOwner {
        _addTokens(addresses, types);
    }

    function setTreasury(address _treasury) public onlyOwner {
        _setTreasury(_treasury);
    }

    // Save occasional airdrop or mistakenly transferred tokens
    function transferFromContract(IERC20 token, uint256 amount, address to)
        external
        onlyOwner
    {
        _revertZeroAddress(to);
        token.safeTransfer(to, amount);
    }

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Equals to `bytes4(keccak256("KingDecks"))`
    bytes private constant _NFT_PASS = abi.encodePacked(bytes4(0xb0e68bdd));

    // Implementation of the ERC721 Receiver
    function onERC721Received(address, address, uint256, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        // Only accept transfers with _NFT_PASS passed as `data`
        return (data.length == 4 && data[0] == 0xb0 && data[3] == 0xdd)
        ? _ERC721_RECEIVED
        : bytes4(0);
    }

    function _withdraw(uint256 depositId, bool isInterim) internal {
        UserDeposits storage userDeposits = deposits[msg.sender];
        Deposit memory _deposit = userDeposits.data[depositId];

        require(_deposit.amountDue != 0, "AIFARM:unknown or repaid deposit");

        uint256 amountToUser;
        uint256 amountDue = 0;
        uint256 fees = 0;

        ( , uint8 outTokenId, uint8 nfTokenId, ) = decodeDepositId(depositId);
        if (isInterim) {
            TermSheet memory tS = _termSheets[_deposit.termsId - 1];
            uint256 allowedTime = uint256(_deposit.lastWithdrawTime) +
                tS.minInterimHours * 3600;
            require(
                tS.minInterimHours != 0 && now >= allowedTime,
                "AIFARM:withdrawal not yet allowed"
            );

            (amountToUser, fees) = _computeEarlyWithdrawal(_deposit, tS, now);
            amountDue = uint256(_deposit.amountDue).sub(amountToUser).sub(fees);

            emit InterimWithdraw(msg.sender, depositId, amountToUser, fees);
        } else {
            require(now >= _deposit.repaymentTime, "AIFARM:deposit is locked");
            amountToUser = uint256(_deposit.amountDue);

            _deregisterDeposit(userDeposits, depositId);

            emit Withdraw(msg.sender, depositId, amountToUser);
        }

        _deposit.lastWithdrawTime = safe32(now);
        _deposit.amountDue = uint160(amountDue);
        userDeposits.data[depositId] = _deposit;

        amountsDue[outTokenId] = amountsDue[outTokenId]
            .sub(amountToUser)
            .sub(fees);

        IERC20(outTokenId)
            .safeTransferFrom(treasury, msg.sender, amountToUser);
    }

    function _computeEarlyWithdrawal(
        Deposit memory d,
        TermSheet memory tS,
        uint256 timeNow
    ) internal pure returns (uint256 amountToUser, uint256 fees) {
        amountToUser = 0;
        fees = 0;

        if (timeNow < d.repaymentTime) {
            // note, values are too small to overflow; otherwise, safemath used
            uint256 term = uint256(tS.depositHours) * 3600; // can't be zero
            uint256 timeLeft = d.repaymentTime - timeNow;

            {
                uint256 amountDue = uint256(d.amountDue);
                uint256 prevTimeLeft = d.repaymentTime - d.lastWithdrawTime;
                uint256 directShare = tS.earlyWithdrawShare; // scaled x255
                uint256 reversedShare = 255 - directShare;
                uint256 weightedTerm = reversedShare * term;

                // Debt linearly declines according to `tS.earlyWithdrawShare`
                uint256 newAmountDue = amountDue
                    .mul(weightedTerm + directShare * timeLeft)
                    .div(weightedTerm + directShare * prevTimeLeft);
                amountToUser = amountDue.sub(newAmountDue);
            }

            fees = amountToUser
                .mul(uint256(tS.earlyWithdrawFees))
                .div(255)               // `earlyWithdrawFees` scaled down
                .mul(timeLeft) / term;  // the rate linearly drops to zero

            amountToUser = amountToUser.sub(fees); // fees withheld
        }
    }

    function _addTermSheet(TermSheet memory tS) internal {
        ( , TokenType _type) = _token(tS.inTokenId);
        require(_type == TokenType.Erc20, "AIFARM:INVALID_DEPOSIT_TOKEN");
        ( , _type) = _token(tS.outTokenId);
        require(_type == TokenType.Erc20, "AIFARM:INVALID_REPAY_TOKEN");
        if (tS.nfTokenId != 0) {
            (, _type) = _token(tS.nfTokenId);
            require(_type == TokenType.Erc721, "AIFARM:INVALID_NFT_TOKEN");
        }

        if (tS.limitId != 0) _validLimitID(tS.limitId);
        require(
             tS.depositHours != 0 && tS.rate != 0,
            "AIFARM:INVALID_ZERO_PARAM"
        );

        // Risk of termsId (16 bits) overflow ignored
        _termSheets.push(tS);

        emit NewTermSheet(_termSheets.length);
        if (tS.enabled) emit TermsEnabled(_termSheets.length);
    }

    function _addLimit(Limit memory l) internal {
        require(l.minAmount != 0, "AIFARM:INVALID_minAmount");
        _limits.push(l);
    }

    function _isAllowedNftId(
        uint256 nftId,
        uint256 allowedBitMask
    ) internal pure returns(bool) {
        if (allowedBitMask == 0) return true;
        uint256 idBitMask = nftId == 1 ? 1 : (2 << (nftId - 2));
        return (allowedBitMask & idBitMask) != 0;
    }

    function _registerDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId,
        Deposit memory _deposit
    ) internal {
        userDeposits.data[depositId] = _deposit;
        userDeposits.ids.push(depositId);
    }

    function _deregisterDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId
    ) internal {
        _removeArrayElement(userDeposits.ids, depositId);
    }

    // Assuming the given array does contain the given element
    function _removeArrayElement(uint256[] storage arr, uint256 el) internal {
        uint256 lastIndex = arr.length - 1;
        if (lastIndex != 0) {
            uint256 replaced = arr[lastIndex];
            if (replaced != el) {
                // Shift elements until the one being removed is replaced
                do {
                    uint256 replacing = replaced;
                    replaced = arr[lastIndex - 1];
                    lastIndex--;
                    arr[lastIndex] = replacing;
                } while (replaced != el && lastIndex != 0);
            }
        }
        // Remove the last (and quite probably the only) element
        arr.pop();
    }

    function _setTreasury(address _treasury) internal {
        _revertZeroAddress(_treasury);
        treasury = _treasury;
    }

    function _revertZeroAddress(address _address) private pure {
        require(_address != address(0), "AIFARM:ZERO_ADDRESS");
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function _validTermsID(uint256 termsId) private view returns (uint256) {
        require(
            termsId != 0 && termsId <= _termSheets.length,
            "AIFARM:INVALID_TERMS_ID"
        );
        return termsId;
    }

    function _validLimitID(uint256 limitId) private view returns (uint256) {
        require(
            limitId != 0 && limitId <= _limits.length,
            "AIFARM:INVALID_LIMITS_ID"
        );
        return limitId;
    }

    function safe32(uint256 n) private pure returns (uint32) {
        require(n < 2**32, "AIFARM:UNSAFE_UINT32");
        return uint32(n);
    }
}