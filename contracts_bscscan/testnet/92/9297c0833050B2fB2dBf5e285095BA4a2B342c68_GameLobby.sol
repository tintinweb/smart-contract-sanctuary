/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/math/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File contracts/GameLobby.sol



pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;




contract GameLobby is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Lobby {
        uint256 epoch;
        string gameName;
        bool open;
        address creator;
        address joiner;
        uint256 scoreCreator;
        uint256 scoreJoiner;
        address winner;
        uint256 bet;
        bool claimed;
    }

    address constant public DRAW = address(1);

    Lobby[] private lobby;

    address private operator;

    uint256 private treasury;
    uint256 private rewardRate;
    uint256 private treasuryRate;
    uint256 private minBetAmount;

    address public token;
    string[] public gamesList;
    mapping(string => bool) public gamesMapping;
    mapping(uint256 => mapping(address => bool)) public lobbyClaimedBy;

    event SetOperator(address indexed oldOperator, address indexed newOperator);
    event CreateGame(string name);
    event SetMinBetAmount(uint256 amount);
    event SetTreasuryRate(uint256 rate);
    event SetRewardRate(uint256 rate);
    event CreateLobby(uint256 indexed epoch, string indexed gameName, address indexed creator, uint256 bet);
    event JoinLobby(uint256 indexed epoch, string indexed gameName, address indexed joiner);
    event SetScore(uint256 indexed epoch, string indexed gameName, address indexed target, uint256 score);
    event CloseLobby(uint256 indexed epoch, string indexed gameName, address indexed winner);
    event Claim(uint256 indexed epoch, string indexed gameName, address indexed target, uint256 reward);
    event AdminWithdraw(uint256 amount);

    constructor(uint256 _rewardRate, uint256 _minBetAmount, address _operator, address _token) public {
        require(_rewardRate <= 100, "GameLobby: RewardRate can't be more than 100");
        require(_token != address(0), "GameLobby: Zero address token");

        rewardRate = _rewardRate;
        treasuryRate = uint256(100).sub(_rewardRate);
        treasury = uint256(0);
        minBetAmount = _minBetAmount;
        operator = _operator;
        token = _token;
    }

    function setOperator(address newOperator) external onlyOwner returns(bool) {
        emit SetOperator(operator, newOperator);

        operator = newOperator;

        return true;
    }

    function setGame(string memory name) external onlyOwner returns(bool) {
        require(gamesMapping[name] == false, "GameLobby: game already exist");

        // add new game
        gamesMapping[name] = true;
        gamesList.push(name);

        emit CreateGame(name);

        return true;
    }

    function setRewardRate(uint256 rate) external onlyOwner returns(bool) {
        require(rate <= 100, "GameLobby: RewardRate can't be more than 100");
        require(rate > 0, "GameLobby: RewardRate can't be less than 1");

        rewardRate = rate;
        treasuryRate = uint256(100).sub(rate);

        emit SetRewardRate(rate);

        return true;
    }

    function setTreasuryRate(uint256 rate) external onlyOwner returns(bool) {
        require(rate <= 100, "GameLobby: TreasuryRate can't be more than 100");
        require(rate > 0, "GameLobby: TreasuryRate can't be less than 1");

        treasuryRate = rate;
        rewardRate = uint256(100).sub(rate);

        emit SetTreasuryRate(rate);

        return true;
    }

    function setMinBetAmount(uint256 amount) external onlyOwner returns(bool) {
        minBetAmount = amount;

        emit SetMinBetAmount(amount);

        return true;
    }

    function adminWithdraw() public onlyOwner returns(bool) {
        require(treasury > 0, "GameLobby: zero-value treasury");  

        uint256 sendValue = treasury;
        treasury = 0;
        IERC20(token).safeTransfer(msg.sender, sendValue);

        emit AdminWithdraw(sendValue);

        return true;
    }

    function createLobby(string memory gameName, uint256 betAmount) external returns(uint256 epoch) {
        require(betAmount >= minBetAmount, "GameLobby: min bet error");
        require(gamesMapping[gameName] == true, "GameLobby: game not found");

        IERC20(token).safeTransferFrom(msg.sender, address(this), betAmount);

        uint256 newEpoch = lobby.length;
        Lobby memory newLobby = Lobby({ 
            epoch: lobby.length,
            gameName: gameName,
            open: true,
            creator: msg.sender,
            joiner: address(0),
            scoreCreator: 0,
            scoreJoiner: 0,
            winner: address(0),
            bet: betAmount,
            claimed: false
        });
        lobby.push(newLobby);

        emit CreateLobby(newEpoch, gameName, msg.sender, betAmount);

        return newEpoch;
    }

    function joinLobby(uint256 epoch, uint256 betAmount) external returns(bool) {
        require(epoch < lobby.length, "GameLobby: lobby does not exist");
        require(lobby[epoch].open == true, "GameLobby: the lobby is already closed");
        require(lobby[epoch].creator != msg.sender, "GameLobby: joining the lobby by the creator");
        require(lobby[epoch].joiner == address(0), "GameLobby: the lobby is already in use");
        require(betAmount == lobby[epoch].bet, "GameLobby: bet amount error");

        IERC20(token).safeTransferFrom(msg.sender, address(this), betAmount);

        Lobby storage targetLobby = lobby[epoch];
        targetLobby.joiner = msg.sender;

        emit JoinLobby(epoch, lobby[epoch].gameName, msg.sender);

        return true;
    }

    function setScore(uint256 epoch, uint256 newScore, address target) external returns(bool) {
        require(msg.sender == operator, "GameLobby: only operator"); // only Operator
        require(epoch < lobby.length, "GameLobby: lobby does not exist");
        require(lobby[epoch].open == true, "GameLobby: the lobby is already closed");

        Lobby storage targetLobby = lobby[epoch];

        if (target == targetLobby.creator) {
            require(targetLobby.scoreCreator == 0, "GameLobby: score already set");
            targetLobby.scoreCreator = newScore;
        } else if (target == targetLobby.joiner) {
            require(targetLobby.scoreJoiner == 0, "GameLobby: score already set");
            targetLobby.scoreJoiner = newScore;
        } else {
            revert("GameLobby: wrong target");
        }

        emit SetScore(epoch, targetLobby.gameName, target, newScore);

        if (targetLobby.scoreCreator > 0 && targetLobby.scoreJoiner > 0) {
            closeLobby(epoch);
        }

        return true;
    }

    function closeLobby(uint256 epoch) public returns(bool) {
        require(msg.sender == operator, "GameLobby: only operator");  // only Operator
        require(epoch < lobby.length, "GameLobby: lobby does not exist");
        require(lobby[epoch].open == true, "GameLobby: the lobby is already closed");

        address winner;
        if (lobby[epoch].scoreCreator > lobby[epoch].scoreJoiner) {
            winner = lobby[epoch].creator;
        } else if (lobby[epoch].scoreCreator < lobby[epoch].scoreJoiner) {
            winner = lobby[epoch].joiner;
        } else {
            winner = DRAW;
        }

        Lobby storage targetLobby = lobby[epoch];
        targetLobby.winner = winner;
        targetLobby.open = false;

        treasury = treasury.add((targetLobby.bet.mul(2)).mul(treasuryRate).div(100));

        emit CloseLobby(epoch, lobby[epoch].gameName, winner);

        return true;
    }

    function claim(uint256 epoch) public returns(uint256 reward) {
        require(epoch < lobby.length, "GameLobby: lobby does not exist");

        Lobby storage targetLobby = lobby[epoch];

        require(targetLobby.open == false, "GameLobby: the lobby must be closed");
        require(targetLobby.winner != address(0), "GameLobby: zero winner error");
        require(targetLobby.claimed == false, "GameLobby: the prize is already claimed");

        uint256 prize;
        if (targetLobby.winner != DRAW) {
            require(msg.sender == targetLobby.winner, "GameLobby: not winner");
            prize = ((targetLobby.bet.mul(2)).mul(rewardRate).div(100));
            lobbyClaimedBy[epoch][msg.sender] = true;
            targetLobby.claimed = true;
        }
        else {
            require(msg.sender == targetLobby.creator || msg.sender == targetLobby.joiner, "GameLobby: not player");
            require(!lobbyClaimedBy[epoch][msg.sender], "GameLobby: already claimed");
            prize = ((targetLobby.bet).mul(rewardRate).div(100));
            lobbyClaimedBy[epoch][msg.sender] = true;
            if (lobbyClaimedBy[epoch][targetLobby.creator] && lobbyClaimedBy[epoch][targetLobby.joiner]) {
                targetLobby.claimed = true;
            }
        }

        IERC20(token).safeTransfer(msg.sender, prize);

        emit Claim(epoch, lobby[epoch].gameName, msg.sender, prize);

        return prize;
    }

    function getLobby(uint256 index) external view returns(Lobby memory) {
        require(index < lobby.length, "GameLobby: lobby does not exist");
        return lobby[index];
    }

    function getGames() external view returns(string[] memory) {
        return gamesList;
    }

    function getMinBetAmount() external view returns(uint256) {
        return minBetAmount;
    }

    function getTreasuryRate() external view returns(uint256) {
        return treasuryRate;
    }

    function getRewardRate() external view returns(uint256) {
        return rewardRate;
    }

    function getTreasury() external view returns(uint256) {
        return treasury;
    }

    function getOperator() external view returns(address) {
        return operator;
    }

}