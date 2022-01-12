// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITulipArt.sol";
import "./interfaces/ITulipToken.sol";
import "./libraries/SortitionSumTreeFactory.sol";
import "./libraries/UniformRandomNumber.sol";

contract TulipArt is ITulipArt, Ownable {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice We use this enum to identify and enforce the
    /// states that this contract will go through.
    enum RoundState {
        OPEN,
        DRAWING,
        CLOSED
    }

    /// @notice `roundId` is the current round identifier, incremented each round.
    /// `roundState` is the current state this round is in, progression goes
    /// from OPEN to DRAWING to CLOSED.
    struct RoundInfo {
        uint256 roundId;
        RoundState roundState;
    }

    /// @notice `implementation` is the next lottery contract to be implemented.
    /// `proposedTime` is the time at which this upgrade can happen.
    struct LotteryCandidate {
        address implementation;
        uint256 proposedTime;
    }

    bytes32 private constant TREE_KEY = keccak256("TulipArt/Staking");
    uint256 private constant MAX_TREE_LEAVES = 5;

    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

    address public landToken;
    address public tulipNFTToken;
    address public lotteryContract;

    /// The minimum time it has to pass before a lottery candidate can be approved.
    uint256 public immutable approvalDelay;

    /// The last proposed lottery to switch to.
    LotteryCandidate public lotteryCandidate;

    /// Array that stores all the rounds and their information
    RoundInfo[] public roundInfo;

    event NewLotteryCandidate(address implementation);
    event UpgradeLottery(address implementation);
    event RoundUpdated(uint256 roundId, RoundState roundState);
    event WinnerSet(address winner);

    /// @notice On contract deployment a new round (1) is created and users can
    /// deposit tokens from the start.
    /// @param _landToken: address of the LAND ERC20 token used for staking.
    /// @param _tulipNFTToken: address of the NFT reward to be minted.
    /// @param _approvalDelay: time it takes to upgrade a lottery contract.
    constructor(
        address _landToken,
        address _tulipNFTToken,
        uint256 _approvalDelay
    ) public {
        landToken = _landToken;
        tulipNFTToken = _tulipNFTToken;
        approvalDelay = _approvalDelay;
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);

        _createNextRound(1);
    }

    /// @notice A user can only enter staking during the open phase of a round.
    /// The tokens are first transfered to this contract and afterwards
    /// the sortitionSumTree is updated.
    /// @param _amount: Is the amount of tokens a user wants to stake.
    function enterStaking(uint256 _amount) external override {
        require(_amount > 0, "TulipArt/amounts-0-or-less-not-allowed");
        require(
            roundInfo[_currentRound()].roundState == RoundState.OPEN,
            "TulipArt/round-not-open"
        );

        IERC20(landToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        sortitionSumTrees.set(
            TREE_KEY,
            userStake(msg.sender).add(_amount),
            bytes32(uint256(msg.sender))
        );
    }

    /// @notice A user can only leave staking during the open phase of a round.
    /// Firstly the sortitionSumTree is updated and then the tokens are
    /// transfered out of this contract.
    /// @param _amount: Is the amount of tokens a user wants to unstake.
    function leaveStaking(uint256 _amount) external override {
        require(_amount > 0, "TulipArt/amounts-0-or-less-not-allowed");
        require(
            _amount <= userStake(msg.sender),
            "TulipArt/insufficient-amount-staked"
        );
        require(
            roundInfo[_currentRound()].roundState == RoundState.OPEN,
            "TulipArt/round-not-open"
        );

        sortitionSumTrees.set(
            TREE_KEY,
            userStake(msg.sender).sub(_amount),
            bytes32(uint256(msg.sender))
        );

        IERC20(landToken).safeTransfer(address(msg.sender), _amount);
    }

    /// @notice The lottery can set the state of this contract to DRAW
    /// which will disable all functions except `finishDraw()`.
    /// It will also enable the function `setWinner()` as we are now in
    /// draw phase.
    function startDraw() external override onlyLottery {
        uint256 currentRound = _currentRound();
        RoundInfo storage round = roundInfo[currentRound];

        require(totalStaked() > 0, "TulipArt/no-users");
        require(
            round.roundState == RoundState.OPEN,
            "TulipArt/round-is-not-open"
        );

        round.roundState = RoundState.DRAWING;

        emit RoundUpdated(currentRound, RoundState.DRAWING);
    }

    /// @notice The lottery can set the state of this contract to CLOSED
    /// to state that this round has finished. This function will
    /// also create a new round which will enable deposits and
    /// withdrawals.
    function finishDraw() external override onlyLottery {
        uint256 currentRound = _currentRound();
        RoundInfo storage round = roundInfo[currentRound];

        require(
            round.roundState == RoundState.DRAWING,
            "TulipArt/round-is-not-drawing"
        );

        round.roundState = RoundState.CLOSED;

        _createNextRound(totalRounds().add(1));

        emit RoundUpdated(currentRound, RoundState.CLOSED);
    }

    /// @notice The random number is used to then generate a number of traits of the NFT.
    /// We set communicate to the NFT the winner and the random number achieved.
    /// The user can then go and mint the token from the NFT contract.
    /// @param _winner: address of the winner.
    /// @param _randomNumber: the randomNumber that was drawn for the winner.
    function setWinner(address _winner, uint256 _randomNumber)
        external
        override
        onlyLottery
    {
        require(
            roundInfo[_currentRound()].roundState == RoundState.DRAWING,
            "TulipArt/round-is-not-drawing"
        );
        ITulipToken(tulipNFTToken).setTokenWinner(_winner, _randomNumber);

        emit WinnerSet(_winner);
    }

    /// @notice This function removes tokens sent to this contract. It cannot remove
    /// the LAND token from this contract.
    /// @param _token: address of the token to remove from this contract.
    /// @param _to: address of the location to send this token.
    /// @param _amount: amount of tokens to remove from this contract.
    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_token != landToken, "TulipArt/cannot-drain-land-tokens");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Returns the user's chance of winning with 6 decimal places or more.
    /// If a user's chance of winning are 25.3212315673% this function will return
    /// 25.321231%.
    /// @param _user: address of a staker.
    /// @return returns the % chance of victory for this user.
    function chanceOf(address _user) external view override returns (uint256) {
        return
            sortitionSumTrees
                .stakeOf(TREE_KEY, bytes32(uint256(_user)))
                .mul(100000000)
                .div(totalStaked());
    }

    /// @notice Selects a user using a random number. The random number will
    /// be uniformly bounded to the total Stake.
    /// @param randomNumber The random number to use to select a user.
    /// @return The winner.
    function draw(uint256 randomNumber)
        external
        view
        override
        returns (address)
    {
        address selected;
        if (totalStaked() == 0) {
            selected = address(0);
        } else {
            uint256 token = UniformRandomNumber.uniform(
                randomNumber,
                totalStaked()
            );
            selected = address(
                uint256(sortitionSumTrees.draw(TREE_KEY, token))
            );
        }
        return selected;
    }

    /// @notice Sets the candidate for the new lottery to use with this staking
    /// contract.
    /// @param _implementation The address of the candidate lottery.
    function proposeLottery(address _implementation) public onlyOwner {
        lotteryCandidate = LotteryCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
        });

        emit NewLotteryCandidate(_implementation);
    }

    /// @notice It switches the active lottery for the lottery candidate.
    /// After upgrading, the candidate implementation is set to the 0x00 address,
    /// and proposedTime to a time happening in +100 years for safety.
    function upgradeLottery() public onlyOwner {
        require(
            roundInfo[_currentRound()].roundState == RoundState.OPEN,
            "TulipArt/round-not-open"
        );
        require(
            lotteryCandidate.implementation != address(0),
            "TulipArt/there-is-no-candidate"
        );

        if (lotteryContract != address(0)) {
            require(
                lotteryCandidate.proposedTime.add(approvalDelay) <
                    block.timestamp,
                "TulipArt/delay-has-not-passed"
            );
        }

        emit UpgradeLottery(lotteryCandidate.implementation);

        lotteryContract = lotteryCandidate.implementation;
        lotteryCandidate.implementation = address(0);
        lotteryCandidate.proposedTime = 5000000000;
    }

    /// @return the total rounds that have been played till now.
    function totalRounds() public view returns (uint256) {
        return roundInfo.length;
    }

    /// @param _user: address of an account.
    /// @return returns the total tokens deposited by the user.
    function userStake(address _user) public view override returns (uint256) {
        return sortitionSumTrees.stakeOf(TREE_KEY, bytes32(uint256(_user)));
    }

    /// @return total amount of tokens currently staked in this contract.
    function totalStaked() public view returns (uint256) {
        return sortitionSumTrees.total(TREE_KEY);
    }

    /// @notice internal function to help with the creation of new rounds.
    /// @param _id: the number of the round that is to be created.
    function _createNextRound(uint256 _id) internal {
        roundInfo.push(RoundInfo({roundId: _id, roundState: RoundState.OPEN}));
        emit RoundUpdated(_id, RoundState.OPEN);
    }

    /// @return returns the current round this contract is in.
    function _currentRound() internal view returns (uint256) {
        return roundInfo.length.sub(1);
    }

    /// @notice ensure only a lottery can execute functions with this modifier
    modifier onlyLottery() {
        require(msg.sender == lotteryContract, "TulipArt/error-not-lottery");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface ITulipArt {
    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function setWinner(address _winner, uint256 randomNumber) external;

    function startDraw() external;

    function finishDraw() external;

    function chanceOf(address user) external view returns (uint256);

    function userStake(address user) external view returns (uint256);

    function draw(uint256 randomNumber) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface ITulipToken {
    function setBaseURI(string memory _newURI) external;

    function isController(address _controllerAddress)
        external
        view
        returns (bool);

    function changeControllerRole(address _controller, bool _role) external;

    function setTokenWinner(address _to, uint256 _randomNumber) external;

    function mint(uint256 _id) external;

    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */

pragma solidity ^0.6.12;

/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint256 K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf.
        // This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint256[] stack;
        uint256[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node,
        // and means the ID does not have a node.
        mapping(bytes32 => uint256) IDsToNodeIndexes;
        mapping(uint256 => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* internal */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _K
    ) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint256[](0);
        tree.nodes = new uint256[](0);
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _value,
        bytes32 _ID
    ) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint256 treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) {
            // No existing node.
            if (_value != 0) {
                // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) {
                    // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {
                        // Is first child.
                        uint256 parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint256 newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else {
                    // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else {
            // Existing node.
            if (_value == 0) {
                // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint256 value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {
                // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint256 plusOrMinusValue = plusOrMinus
                    ? _value - tree.nodes[treeIndex]
                    : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(
                    self,
                    _key,
                    treeIndex,
                    plusOrMinus,
                    plusOrMinusValue
                );
            }
        }
    }

    /* internal Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree
     *       is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start
     *  @return values The values of the returned leaves
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _cursor,
        uint256 _count
    )
        internal
        view
        returns (
            uint256 startIndex,
            uint256[] memory values,
            bool hasMore
        )
    {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint256 i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint256 loopStartIndex = startIndex + _cursor;
        values = new uint256[](
            loopStartIndex + _count > tree.nodes.length
                ? tree.nodes.length - loopStartIndex
                : _count
        );
        uint256 valuesIndex = 0;
        for (uint256 j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts
     *       if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _drawnNumber
    ) internal view returns (bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint256 treeIndex = 0;
        uint256 currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while (
            (tree.K * treeIndex) + 1 < tree.nodes.length // While it still has children.
        )
            for (uint256 i = 1; i <= tree.K; i++) {
                // Loop over children.
                uint256 nodeIndex = (tree.K * treeIndex) + i;
                uint256 nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue)
                    currentDrawnNumber -= nodeValue; // Go to the next child.
                else {
                    // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }

        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(
        SortitionSumTrees storage self,
        bytes32 _key,
        bytes32 _ID
    ) internal view returns (uint256 value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint256 treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    function total(SortitionSumTrees storage self, bytes32 _key)
        internal
        view
        returns (uint256)
    {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        if (tree.nodes.length == 0) {
            return 0;
        } else {
            return tree.nodes[0];
        }
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _treeIndex,
        bool _plusOrMinus,
        uint256 _value
    ) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint256 parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus
                ? tree.nodes[parentIndex] + _value
                : tree.nodes[parentIndex] - _value;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
Copyright 2019 PoolTogether LLC

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.0 <0.8.0;

/**
 * @author Brendan Asselstine
 * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
 * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
 */
library UniformRandomNumber {
    /// @notice Select a random number without modulo bias using a random seed and upper bound
    /// @param _entropy The seed for randomness
    /// @param _upperBound The upper bound of the desired number
    /// @return A random number less than the _upperBound
    function uniform(uint256 _entropy, uint256 _upperBound)
        internal
        pure
        returns (uint256)
    {
        require(_upperBound > 0, "UniformRand/min-bound");
        uint256 min = -_upperBound % _upperBound;
        uint256 random = _entropy;
        while (true) {
            if (random >= min) {
                break;
            }
            random = uint256(keccak256(abi.encodePacked(random)));
        }
        return random % _upperBound;
    }
}