//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IShoController.sol";
import "./interfaces/IWallets.sol";
import "./ShoStorage.sol";


/// @title ShoController, this contract keeps all data about last/current SHOs
/// @author DAO.MAKER
/// @notice This is logical implementation, which can be upgraded
/// @dev This contract is allowed to call privileges methods from Wallets contract, especially able to claim funds from there
contract ShoController is AccessControl, ShoStorage, IShoController {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ContractInited(address wallets, address organizer);
  event NewSho(uint256 id, address token, address acceptedToken, uint256 allocation);
  event UserJoined(uint256 id, address user);
  event ShoClosed(uint256 id, address[] winners, bool isFinished);
  event ShoTokenAdded(uint256 id, address token);
  event WinnerClaimedTokens(uint256 id, address winners);
  event ShoOrganizerChanged(uint256 id, address newOrganizer);


  //  -------------------------
  //  SETTERS (PUBLIC)
  //  -------------------------


  /// @dev Initialization method for saving main params after proxy contract development
  /// @param wallets The DAO.MAKER global wallet contract address, where users keep their funds
  /// @param organizer The one of the organizer addresses, who should be able to manage the processes
  function init(address wallets, address organizer) external override {
    require(_wallets == address(0), "init: Already initialized!");
    require(wallets != address(0) && organizer != address(0), "init: Invalid params!");

    _wallets = wallets;
    _setupRole(ORGANIZER_ROLE, organizer);

    emit ContractInited(wallets, organizer);
  }

  /// @dev Join to existing SHO
  /// Before calling this method user need to deposit required allocation tokens to Wallets contract
  function joinSho(uint256 shoId) public override {
    _validShoId(shoId);
    _validateShoForJoin(shoId);
    _validateUserParticipation(shoId, msg.sender);

    _isShoParticipant[shoId][msg.sender] = true;
    _shoInfo[shoId].participantsCount++;

    emit UserJoined(shoId, msg.sender);
  }

  /// @dev Deposit tokens to wallet + Join to existing SHO
  /// Before calling this method user need to approve tokens to Wallet contract
  function joinShoWithDeposit(uint256 shoId) external override {
    // 1) Deposit funds to wallet contract
    IWallets(_wallets).depositFromUser(msg.sender, _shoInfo[shoId].acceptedToken, _shoInfo[shoId].allocation);

    // 2) Join to SHO
    joinSho(shoId);
  }

  /// @dev Receive won tokens
  /// If user won, and owner approved tokens for users, user can receive his won tokens with this method
  function receiveWonTokens(uint256 shoId) external override {
    _validShoId(shoId);
    _validateShoForWinner(shoId, msg.sender);

    // After claim won tokens disable user participation
    _isShoParticipant[shoId][msg.sender] = false;
    IERC20(_shoInfo[shoId].token).safeTransfer(msg.sender, _shoWinnings[shoId][msg.sender]);

    emit WinnerClaimedTokens(shoId, msg.sender);
  }


  //  -------------------------
  //  SETTERS (ORGANIZER)
  //  -------------------------


  /// @dev Organizer role creates new SHO's
  /// This access can be transferred to another Organizer address
  function newSho(
    uint256 deadline,
    uint256 allocation,
    address token,
    address acceptedToken
  ) external override {
    require(hasRole(ORGANIZER_ROLE, msg.sender), "newSho: Only organizers can call this method!");
    require(deadline > block.timestamp, "newSho: Deadline can not be smaller from current time!");
    require(acceptedToken != address(0), "newSho: Accepted token can not be empty!");

    uint256 id = _lastId;
    _shoInfo[id] = Sho({
      state: State.OPEN,
      deadline: deadline,
      allocation: allocation,
      participantsCount: 0,
      winnersCount: 0,
      token: token,
      acceptedToken: acceptedToken,
      organizer: msg.sender
    });

    // If this accepted token not approved on wallets contracts, enable it
    if (!_isAssetDepositAllowed(acceptedToken)) {
      _acceptAssetDeposit(acceptedToken);
    }

    // Auto-increase _lastId after each SHO creation
    _lastId++;

    emit NewSho(id, token, acceptedToken, allocation);
  }

  /// @dev Organizer posting results of the existing SHO's, if deadline time is reached
  /// Method contains array of winners and custom allocation tokens, which they will receive in the future
  /// Organizer can call this method many times, but need to call with "isLastTx" = "true" during the last transaction
  function postShoResults(
    uint256 shoId,
    address[] calldata winners,
    uint256[] calldata allocations,
    bool isLastTx
  ) external override {
    require(winners.length == allocations.length, "postShoResults: Winners and allocations are not equal!");

    _validShoId(shoId);
    _validateOrganizerAccess(shoId);
    _validateShoForClose(shoId, winners.length);

    Sho storage _sho = _shoInfo[shoId];

    for (uint256 i = 0; i < winners.length; i++) {
      _setUserAsWinner(shoId, winners[i], allocations[i]);
      IWallets(_wallets).withdrawFromUser(winners[i], _sho.acceptedToken, _sho.allocation);
    }

    IERC20(_sho.acceptedToken).safeTransfer(msg.sender, winners.length.mul(_sho.allocation));

    _sho.winnersCount = _sho.winnersCount.add(winners.length);

    if (isLastTx) {
      _sho.state = State.CLOSED;
    }

    emit ShoClosed(shoId, winners, isLastTx);
  }

  /// @dev Add prize token address to the existing SHO
  /// Sometimes token will be known after SHO, so we need to make it flexible
  function setShoToken(uint256 shoId, address token) external override {
    _validShoId(shoId);
    _validateOrganizerAccess(shoId);

    _shoInfo[shoId].token = token;

    emit ShoTokenAdded(shoId, token);
  }

  /// @dev Organizer transfer access to another organizer
  /// Even if organizer removed from that role, he will be able to transfer access
  function changeOrganizerAddress(uint256 shoId, address newShoOrganizer) external override {
    _validShoId(shoId);

    // Main admin always can change organizer address as well
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      _validateOrganizerAccess(shoId);
    }

    _shoInfo[shoId].organizer = newShoOrganizer;

    emit ShoOrganizerChanged(shoId, newShoOrganizer);
  }


  //  -------------------------
  //  GETTERS
  //  -------------------------


  function getShoDetails(uint256 shoId) external view override returns (
    uint8,
    uint256,
    uint256,
    uint256,
    uint256,
    address,
    address,
    address
  ) {
    Sho memory _sho = _shoInfo[shoId];
    return (
      uint8(_sho.state),
      _sho.deadline,
      _sho.allocation,
      _sho.participantsCount,
      _sho.winnersCount,
      _sho.token,
      _sho.acceptedToken,
      _sho.organizer
    );
  }

  function getLastShoId() external view override returns (uint256) {
    return _lastId == 0 ? _lastId : _lastId.sub(1);
  }

  function getClaimableWonTokens(uint256 shoId, address user) external view override returns (uint256) {
    if (_isShoParticipant[shoId][user]) {
      return _shoWinnings[shoId][user];
    } else {
      return 0;
    }
  }

  function isUserShoWinner(uint256 shoId, address user) external view override returns (bool) {
    return _shoWinnings[shoId][user] > 0;
  }

  function isUserShoParticipant(uint256 shoId, address user) external view override returns (bool) {
    return _isShoParticipant[shoId][user];
  }

  function getWalletContractAddress() external view override returns (address) {
    return _wallets;
  }


  //  -------------------------
  //  INTERNAL
  //  -------------------------


  function _acceptAssetDeposit(address asset) internal {
    IWallets(_wallets).changeAssetDepositState(asset, true);
  }

  function _setUserAsWinner(uint256 id, address user, uint256 allocation) internal {
    require(_isShoParticipant[id][user], "_setUserAsWinner: User not participated to this SHO!");
    require(_shoWinnings[id][user] == 0, "_setUserAsWinner: User already marked as winner!");

    _shoWinnings[id][user] = allocation;
  }

  function _isAssetDepositAllowed(address asset) internal view returns (bool) {
    return IWallets(_wallets).isAssetAllowed(asset);
  }

  function _validShoId(uint256 id) internal view {
    require(id < _lastId, "_validShoId: Invalid SHO id!");
  }

  function _validateOrganizerAccess(uint256 id) internal view {
    require(hasRole(ORGANIZER_ROLE, msg.sender), "_validateOrganizerChanges: Only organizers can call this method!");
    require(msg.sender == _shoInfo[id].organizer, "_validateOrganizerChanges: Only the organizer of this sho can call this method!");
  }

  function _validateShoForJoin(uint256 id) internal view {
    Sho memory _sho = _shoInfo[id];

    require(_sho.state == State.OPEN, "_validateShoForJoin: SHO is not open!");
    require(_sho.deadline > block.timestamp, "_validateShoForJoin: SHO time is finished!");
  }

  function _validateUserParticipation(uint256 id, address user) internal view {
    Sho memory _sho = _shoInfo[id];
    uint256 userBalance = IWallets(_wallets).getUserAvailableBalance(user, _sho.acceptedToken);

    require(_isShoParticipant[id][user] == false, "_validateUserParticipation: User already joined to this SHO!");
    require(userBalance >= _sho.allocation, "_validateUserParticipation: Not enough locked tokens!");
  }

  function _validateShoForWinner(uint256 id, address user) internal view {
    Sho memory _sho = _shoInfo[id];
    uint256 availableBalance = IERC20(_sho.token).balanceOf(address(this));

    require(availableBalance >= _shoWinnings[id][user], "_validateShoForWinner: Project tokens are not enough for claim!");
    require(_sho.state == State.CLOSED, "_validateShoForWinner: SHO is not finished!");
    require(_isShoParticipant[id][user] == true, "_validateShoForWinner: User have not won or already received his tokens!");
    require(_shoWinnings[id][user] > 0, "_validateShoForWinner: User was not won this SHO!");
  }

  function _validateShoForClose(uint256 id, uint256 winnersCount) internal view {
    Sho memory _sho = _shoInfo[id];

    require(block.timestamp >= _sho.deadline, "_validateShoForClose: Its to early to close SHO!");
    require(_sho.state == State.OPEN, "_validateShoForClose: SHO is not open!");
    require(_sho.participantsCount >= _sho.winnersCount.add(winnersCount), "_validateShoForClose: Winners count is too big!");
  }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;


interface IShoController {
  function init(address wallets, address organizer) external;
  function joinSho(uint256 shoId) external;
  function joinShoWithDeposit(uint256 shoId) external;
  function receiveWonTokens(uint256 shoId) external;
  function newSho(uint256 deadline, uint256 allocation, address token, address acceptedToken) external;
  function postShoResults(uint256 shoId, address[] calldata winners, uint256[] calldata allocations, bool isLastTx) external;
  function setShoToken(uint256 shoId, address token) external;
  function changeOrganizerAddress(uint256 shoId, address newShoOrganizer) external;

  function getShoDetails(uint256 shoId) external view returns (uint8, uint256, uint256, uint256, uint256, address, address, address);
  function getLastShoId() external view returns (uint256);
  function isUserShoWinner(uint256 shoId, address user) external view returns (bool);
  function isUserShoParticipant(uint256 shoId, address user) external view returns (bool);
  function getWalletContractAddress() external view returns (address);
  function getClaimableWonTokens(uint256 shoId, address user) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;


interface IWallets {
  function depositWallet(address asset, uint256 amount) external;
  function withdrawFromWallet(address asset, uint256 amount) external;
  function depositEthWallet() external payable;
  function withdrawEthFromWallet(uint256 amount) external;
  function depositFromUser(address user, address asset, uint256 amount) external;
  function withdrawFromUser(address user, address asset, uint256 amount) external;
  function changeAssetDepositState(address asset, bool isAllowed) external;

  function getUserAvailableBalance(address user, address asset) external view returns (uint256);
  function getUserTotalData(address user, address asset) external view returns (uint256, uint256);
  function isAssetAllowed(address asset) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IShoController.sol";
import "./Wallets.sol";


contract ShoStorage is AccessControl {
  uint256 internal _lastId;
  address internal _wallets;

  enum State { NOT_EXIST, OPEN, CLOSED, DECLINED }

  bytes32 public constant ORGANIZER_ROLE = keccak256("ORGANIZER_ROLE");

  struct Sho {
    State state;

    uint256 deadline;
    uint256 allocation;

    uint256 participantsCount;
    uint256 winnersCount;

    address token;
    address acceptedToken;
    address organizer;
  }

  // SHO ID => Sho
  mapping(uint256 => Sho) internal _shoInfo;
  // SHO ID => User => Winning amount
  mapping(uint256 => mapping(address => uint256)) internal _shoWinnings;
  // SHO ID => User => Is participant
  mapping(uint256 => mapping(address => bool)) internal _isShoParticipant;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IWallets.sol";


/// @title A Global Wallet contract, where users can deposit/withdraw for participating DAO projects
/// @author DAO Maker
/// @notice DO NOT SEND assets to this contracts directly, they will be blocked forever!
contract Wallets is AccessControl, IWallets {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  bytes32 public constant DAO_CONTRACT = keccak256("DAO_CONTRACT");
  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  struct Balance {
    uint256 available;

    uint256 totalDeposited;
    uint256 totalWithdrawn;
  }

  // Token => Is deposit allowed
  mapping(address => bool) internal _allowedTokens;
  // User => Asset balance => Balancce
  mapping(address => mapping(address => Balance)) internal _balances;

  event NewDeposit(address user, address asset, uint256 amount);
  event NewWithdraw(address user, address asset, uint256 amount);
  event DaoWithdraw(address user, address asset, uint256 amount);


  //  -------------------------
  //  CONSTRUCTOR
  //  -------------------------


  constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }


  //  -------------------------
  //  SETTERS (PUBLIC)
  //  -------------------------


  /// @dev Before calling deposit method users need to approve it for Wallet contract.
  /// Only accepted by admin tokens can be deposited by users.
  function depositWallet(address asset, uint256 amount) public override {
    require(amount > 0, "depositWallet: Amount should be bigger 0!");
    require(_isAllowedAsset(asset), "depositWallet: Asset is not allowed!");

    IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    _depositStateChange(msg.sender, asset, amount);

    emit NewDeposit(msg.sender, asset, amount);
  }

  /// @dev Withdraw assets from contract.
  /// Users can withdraw funds, even if asset has been disabled by admin.
  function withdrawFromWallet(address asset, uint256 amount) public override {
    require(amount > 0, "withdrawFromWallet: Amount should be bigger 0!");
    require(_balances[msg.sender][asset].available >= amount, "withdrawFromWallet: Not enough funds!");

    _withdrawStateChange(msg.sender, asset, amount);
    IERC20(asset).safeTransfer(msg.sender, amount);

    emit NewWithdraw(msg.sender, asset, amount);
  }

  /// @dev Similar to ERC20 `deposit` method, can be used in the future.
  /// ETH deposit should be approved by DAO contracts, then users can deposit it.
  function depositEthWallet() public payable override {
    require(_isAllowedAsset(ETH_ADDRESS), "depositEthWallet: ETH is not allowed!");

    _depositStateChange(msg.sender, ETH_ADDRESS, msg.value);

    emit NewDeposit(msg.sender, ETH_ADDRESS, msg.value);
  }

  /// @dev Similar to ERC20 `withdraw` method, can be used in the future.
  function withdrawEthFromWallet(uint256 amount) public override {
    require(amount > 0, "withdrawEthFromWallet: Amount should be bigger 0!");
    require(_balances[msg.sender][ETH_ADDRESS].available >= amount, "withdrawEthFromWallet: Not enough funds!");

    _withdrawStateChange(msg.sender, ETH_ADDRESS, amount);
    msg.sender.transfer(amount);

    emit NewWithdraw(msg.sender, ETH_ADDRESS, amount);
  }


  //  -------------------------
  //  SETTERS (DAO CONTRACTS)
  //  -------------------------


  /// @dev Deposit tokens, can be called by DAO contracts only.
  /// It is done for combining 2 method in 1 transaction (eg deposit + join SHO and etc).
  function depositFromUser(address user, address asset, uint256 amount) public override {
    require(hasRole(DAO_CONTRACT, msg.sender), "depositFromUser: Only DAO contracts can call this method!");

    IERC20(asset).safeTransferFrom(user, address(this), amount);
    _depositStateChange(user, asset, amount);

    emit NewDeposit(user, asset, amount);
  }

  /// @dev When winners are known the SHO contract should be able to receive tokens of the users.
  /// Assets will be transferred to SHO contract, and then to the project wallet address.
  function withdrawFromUser(address user, address asset, uint256 amount) public override {
    require(hasRole(DAO_CONTRACT, msg.sender), "withdrawFromUser: Only DAO contracts can claim users deposits!");
    require(_balances[user][asset].available >= amount, "withdrawFromUser: Not enough deposited assets!");

    _withdrawStateChange(user, asset, amount);
    IERC20(asset).safeTransfer(msg.sender, amount);

    emit DaoWithdraw(user, asset, amount);
  }

  /// @dev If asset deposit state is enabled, user can deposit that assets to Wallet contract.
  function changeAssetDepositState(address asset, bool isAllowed) public override {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_CONTRACT, msg.sender), "changeAssetDepositState: Only admin or DAO contracts can call this method!");

    _allowedTokens[asset] = isAllowed;
  }


  //  -------------------------
  //  GETTERS
  //  -------------------------


  /// @dev Get user balance, which can be locked for SHO or withdraw by user.
  function getUserAvailableBalance(address user, address asset) public view override returns (uint256) {
    return _balances[user][asset].available;
  }

  /// @dev It will be used for statistics only, returns amount of total deposits and withdraws.
  function getUserTotalData(address user, address asset) public view override returns (uint256, uint256) {
    return (
      _balances[user][asset].totalDeposited,
      _balances[user][asset].totalWithdrawn
    );
  }

  /// @dev Is provided asset accepted for deposits for the provided sho contract
  /// The list will be modified in the future by DAO contracts.
  function isAssetAllowed(address asset) public view override returns (bool) {
    return _isAllowedAsset(asset);
  }


  //  -------------------------
  //  INTERNAL
  //  -------------------------


  function _isAllowedAsset(address asset) internal view returns (bool) {
    return _allowedTokens[asset];
  }

  function _depositStateChange(address user, address asset, uint256 amount) internal {
    _balances[user][asset].available = _balances[user][asset].available.add(amount);
    _balances[user][asset].totalDeposited = _balances[user][asset].totalDeposited.add(amount);
  }

  function _withdrawStateChange(address user, address asset, uint256 amount) internal {
    _balances[user][asset].available = _balances[user][asset].available.sub(amount);
    _balances[user][asset].totalWithdrawn = _balances[user][asset].totalWithdrawn.add(amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

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

