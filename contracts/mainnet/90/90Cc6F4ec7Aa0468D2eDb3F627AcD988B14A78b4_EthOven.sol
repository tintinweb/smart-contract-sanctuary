//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

import "./Oven.sol";

contract EthOven is Oven {

    receive() external payable {
        address(inputToken).call{value: msg.value}("");
        _depositTo(msg.value, _msgSender());
    }

    function depositEth() external payable {
        address(inputToken).call{value: msg.value}("");
        _depositTo(msg.value, _msgSender());
    }

    function depositEthTo(address _to) external payable {
        address(inputToken).call{value: msg.value}("");
        _depositTo(msg.value, _to);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IRecipe.sol";


contract Oven is AccessControl {
  using SafeERC20 for IERC20;
  using Math for uint256;

  bytes32 constant public BAKER_ROLE = keccak256(abi.encode("BAKER_ROLE"));
  uint256 constant public MAX_FEE = 10 * 10**16; //10%

  IERC20 public inputToken;
  IERC20 public outputToken;


  uint256 public roundSizeInputAmount;
  IRecipe public recipe;


  struct Round {
    uint256 totalDeposited;
    mapping(address => uint256) deposits;

    uint256 totalBakedInput;
    uint256 totalOutput;
  }

  struct ViewRound {
    uint256 totalDeposited;
    uint256 totalBakedInput;
    uint256 totalOutput;
  }

  Round[] public rounds;

  mapping(address => uint256[]) userRounds;

  uint256 public fee = 0; //default 0% (10**16 == 1%)
  address public feeReceiver;

  event Deposit(address indexed from, address indexed to, uint256 amount);
  event Withdraw(address indexed from, address indexed to, uint256 inputAmount, uint256 outputAmount);
  event FeeReceiverUpdate(address indexed previousReceiver, address indexed newReceiver);
  event FeeUpdate(uint256 previousFee, uint256 newFee);
  event RecipeUpdate(address indexed oldRecipe, address indexed newRecipe);
  event RoundSizeUpdate(uint256 oldRoundSize, uint256 newRoundSize);

  modifier onlyBaker() {
    require(hasRole(BAKER_ROLE, _msgSender()), "NOT_BAKER");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NOT_ADMIN");
    _;
  }

  function initialize(address _inputToken, address _outputToken, uint256 _roundSizeInputAmount, address _recipe) external {
    require(address(inputToken) == address(0), "Oven.initializer: Already initialized");
    
    require(_inputToken != address(0), "INPUT_TOKEN_ZERO");
    require(_outputToken != address(0), "OUTPUT_TOKEN_ZERO");
    require(_recipe != address(0), "RECIPE_ZERO");
    
    inputToken = IERC20(_inputToken);
    outputToken = IERC20(_outputToken);
    roundSizeInputAmount = _roundSizeInputAmount;
    recipe = IRecipe(_recipe);

    // create first empty round
    rounds.push();

    // approve input token
    IERC20(_inputToken).safeApprove(_recipe, type(uint256).max);

    //grant default admin role
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    //grant baker role
    _setRoleAdmin(BAKER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(BAKER_ROLE, _msgSender());
  }

  function deposit(uint256 _amount) external {
    depositTo(_amount, _msgSender());
  }

  function depositTo(uint256 _amount, address _to) public {
    IERC20 inputToken_ = inputToken;
    inputToken_.safeTransferFrom(_msgSender(), address(this), _amount);
    _depositTo(_amount, _to);
  }

  function _depositTo(uint256 _amount, address _to) internal {
    // if amount is zero return early
    if(_amount == 0) {
      return;
    }

    uint256 roundSizeInputAmount_ = roundSizeInputAmount; //gas saving

    uint256 currentRound = rounds.length - 1;
    uint256 deposited = 0;

    while(deposited < _amount) {
      //if the current round does not exist create it
      if(currentRound >= rounds.length) {
        rounds.push();
      }

      //if the round is already partially baked create a new round
      if(rounds[currentRound].totalBakedInput != 0) {
        currentRound ++;
        rounds.push();
      }

      Round storage round = rounds[currentRound];

      uint256 roundDeposit = (_amount - deposited).min(roundSizeInputAmount_ - round.totalDeposited);

      round.totalDeposited += roundDeposit;
      round.deposits[_to] += roundDeposit;

      deposited += roundDeposit;

      // only push rounds we are actually in
      if(roundDeposit != 0) {
        pushUserRound(_to, currentRound);
      }

      // if full amount assigned to rounds break the loop
      if(deposited == _amount) {
        break;
      }

      currentRound ++;
    }

    emit Deposit(_msgSender(), _to, _amount);
  }

  function pushUserRound(address _to, uint256 _roundId) internal {
    // only push when its not already added
    if(userRounds[_to].length == 0 || userRounds[_to][userRounds[_to].length - 1] != _roundId) {
      userRounds[_to].push(_roundId);
    }     
  }

  function withdraw(uint256 _roundsLimit) public {
    withdrawTo(_msgSender(), _roundsLimit);
  }


  function withdrawTo(address _to, uint256 _roundsLimit) public {
    uint256 inputAmount;
    uint256 outputAmount;
    
    uint256 userRoundsLength = userRounds[_msgSender()].length;
    uint256 numRounds = userRoundsLength.min(_roundsLimit);

    for(uint256 i = 0; i < numRounds; i ++) {
      // start at end of array for efficient popping of elements
      uint256 roundIndex = userRounds[_msgSender()][userRoundsLength - i - 1];
      Round storage round = rounds[roundIndex];

      //amount of input of user baked
      uint256 bakedInput = round.deposits[_msgSender()] * round.totalBakedInput / round.totalDeposited;
      //amount of output the user is entitled to

      uint256 userRoundOutput;
      if(bakedInput == 0) {
        userRoundOutput = 0;
      } else {
        userRoundOutput = round.totalOutput * bakedInput / round.totalBakedInput;
      }
      
      // unbaked input
      inputAmount += round.deposits[_msgSender()] - bakedInput;
      //amount of output the user is entitled to
      outputAmount += userRoundOutput;

      round.totalDeposited -= round.deposits[_msgSender()] - bakedInput;
      round.deposits[_msgSender()] = 0;
      round.totalBakedInput -= bakedInput;

      round.totalOutput -= userRoundOutput;

      //pop of user round
      userRounds[_msgSender()].pop();
    }

    if(inputAmount != 0) {
      // handle rounding issues due to integer division inaccuracies
      inputAmount = inputAmount.min(inputToken.balanceOf(address(this)));
      inputToken.safeTransfer(_to, inputAmount);
    }
    
    if(outputAmount != 0) {
      // handle rounding issues due to integer division inaccuracies
      outputAmount = outputAmount.min(outputToken.balanceOf(address(this)));
      outputToken.safeTransfer(_to, outputAmount);
    }

    emit Withdraw(_msgSender(), _to, inputAmount, outputAmount);
  }

  function bake(bytes calldata _data, uint256[] memory _rounds) external onlyBaker {
    uint256 maxInputAmount;

    //get input amount
    for(uint256 i = 0; i < _rounds.length; i ++) {
      
      // prevent round from being baked twice
      if(i != 0) {
        require(_rounds[i] > _rounds[i - 1], "Rounds out of order");
      }

      Round storage round = rounds[_rounds[i]];
      maxInputAmount += (round.totalDeposited - round.totalBakedInput);
    }

    // subtract fee amount from input
    uint256 maxInputAmountMinusFee = maxInputAmount * (10**18 - fee) / 10**18;

    //bake
    (uint256 inputUsed, uint256 outputAmount) = recipe.bake(address(inputToken), address(outputToken), maxInputAmountMinusFee, _data);

    uint256 inputUsedRemaining = inputUsed;

    for(uint256 i = 0; i < _rounds.length; i ++) {
      Round storage round = rounds[_rounds[i]];

      uint256 roundInputBaked = (round.totalDeposited - round.totalBakedInput).min(inputUsedRemaining);

      // skip round if it is already baked
      if(roundInputBaked == 0) {
        continue;
      }

  	  uint256 roundInputBakedWithFee = roundInputBaked * 10**18 / (10**18 - fee);

      uint256 roundOutputBaked = outputAmount * roundInputBaked / inputUsed;

      round.totalBakedInput += roundInputBakedWithFee;
      inputUsedRemaining -= roundInputBaked;
      round.totalOutput += roundOutputBaked;

      //sanity check
      require(round.totalBakedInput <= round.totalDeposited, "Input sanity check failed");
    }

    uint256 feeAmount = (inputUsed * 10**18 / (10**18 - fee)) - inputUsed;
    address feeReceiver_ = feeReceiver; //gas saving
    if(feeAmount != 0) {
      
      // if no fee receiver is set send it to the baker
      if(feeReceiver == address(0)) {
        feeReceiver_ = _msgSender();
      }
      inputToken.safeTransfer(feeReceiver_, feeAmount);
    }
    
  }

  function setFee(uint256 _newFee) external onlyAdmin {
    require(_newFee <= MAX_FEE, "INVALID_FEE");
    emit FeeUpdate(fee, _newFee);
    fee = _newFee;
  }

  function setRoundSize(uint256 _roundSize) external onlyAdmin {
    emit RoundSizeUpdate(roundSizeInputAmount, _roundSize);
    roundSizeInputAmount = _roundSize;
  }

  function setRecipe(address _recipe) external onlyAdmin {
    emit RecipeUpdate(address(recipe), _recipe);
    
    //revoke old approval
    if(address(recipe) != address(0)) {
      inputToken.approve(address(recipe), 0);
    }

    recipe = IRecipe(_recipe);

    //set new approval
    if(address(recipe) != address(0)) {
      inputToken.approve(address(recipe), type(uint256).max);
    }
  }

  function saveToken(address _token, address _to, uint256 _amount) external onlyAdmin {
    IERC20(_token).transfer(_to, _amount);
  }
  
  function saveEth(address payable _to, uint256 _amount) external onlyAdmin {
    _to.call{value: _amount}("");
  }

  function setFeeReceiver(address _feeReceiver) external onlyAdmin {
    emit FeeReceiverUpdate(feeReceiver, _feeReceiver);
    feeReceiver = _feeReceiver;
  }

  function roundInputBalanceOf(uint256 _round, address _of) public view returns(uint256) {
    Round storage round = rounds[_round];
    // if there are zero deposits the input balance of `_of` would be zero too
    if(round.totalDeposited == 0) {
      return 0;
    }
    uint256 bakedInput = round.deposits[_of] * round.totalBakedInput / round.totalDeposited;
    return round.deposits[_of] - bakedInput;
  }

  function inputBalanceOf(address _of) public view returns(uint256) {
    uint256 roundsCount = userRounds[_of].length;

    uint256 balance;

    for(uint256 i = 0; i < roundsCount; i ++) {
      balance += roundInputBalanceOf(userRounds[_of][i], _of);
    }

    return balance;
  }

  function roundOutputBalanceOf(uint256 _round, address _of) public view returns(uint256) {
    Round storage round = rounds[_round];

    if(round.totalBakedInput == 0) {
      return 0;
    }

    //amount of input of user baked
    uint256 bakedInput = round.deposits[_of] * round.totalBakedInput / round.totalDeposited;
    //amount of output the user is entitled to
    uint256 userRoundOutput = round.totalOutput * bakedInput / round.totalBakedInput;

    return userRoundOutput;
  }

  function outputBalanceOf(address _of) external view returns(uint256) {
    uint256 roundsCount = userRounds[_of].length;

    uint256 balance;

    for(uint256 i = 0; i < roundsCount; i ++) {
      balance += roundOutputBalanceOf(userRounds[_of][i], _of);
    }

    return balance;
  }

  function getUserRoundsCount(address _user) external view returns(uint256) {
    return userRounds[_user].length;
  }

  function getRoundsCount() external view returns(uint256) {
    return rounds.length;
  }

  // Gets all rounds. Might run out of gas after many rounds
  function getRounds() external view returns (ViewRound[] memory) {
    return getRoundsRange(0, rounds.length -1);
  }

  function getRoundsRange(uint256 _from, uint256 _to) public view returns(ViewRound[] memory) {
    ViewRound[] memory result = new ViewRound[](_to - _from + 1);

    for(uint256 i = _from; i <= _to; i ++) {
      Round storage round = rounds[i];
      result[i].totalDeposited = round.totalDeposited;
      result[i].totalBakedInput = round.totalBakedInput;
      result[i].totalOutput = round.totalOutput;
    }

    return result;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
    struct RoleData {
        mapping (address => bool) members;
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
        return _roles[role].members[account];
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
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

interface IRecipe {
    function bake(
        address _inputToken,
        address _outputToken,
        uint256 _maxInput,
        bytes memory _data
    ) external returns (uint256 inputAmountUsed, uint256 outputAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

