// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract AdminManager {
  mapping(string => address) roles;

  modifier onlyOwner(string memory _role) {
    // abi.encodePacked() appends strings
    require(roles[_role] == msg.sender, string(abi.encodePacked("AdminManager: Not", _role)));
    _;
  }

  function onlyOwnerF(string memory _role) internal onlyOwner(_role) { }

  function setupRole(string memory _role, address _owner) public {
    require(roles[_role] == address(0), "AdminManager: RoleAlreadySet");
    roles[_role] = _owner;
  }

  function getRoleOwner(string memory _role) public view returns(address) {
    return roles[_role];
  }

  function safeGetRoleOwner(string memory _role) public view returns(address) {
    address _owner = roles[_role];
    require(_owner != address(0), "AdminManager: RoleNotSet");
    return _owner;
  }

  function transferOwnership(string memory _role, address _newOwner) public onlyOwner(_role) {
    roles[_role] = _newOwner;
  }
}

abstract contract MembersManager is AdminManager {
  struct Members {
    string    admin;
    mapping(address => bool) members;
  }
  mapping(string => Members) public groups;

  function createGroup(string memory _groupName, string memory _adminRole) external onlyOwner(_adminRole) {
    require(AdminManager.getRoleOwner(groups[_groupName].admin) == address(0), "GroupAlreadyCreated");
    groups[_groupName].admin = _adminRole;
  }

  function addMember(string memory _groupName, address _newMember) external onlyOwner(groups[_groupName].admin) {
    groups[_groupName].members[_newMember] = true;
  }

  function removeMember(string memory _groupName, address _memberToRemove) external onlyOwner(groups[_groupName].admin) {
    groups[_groupName].members[_memberToRemove] = false;
  }

  function isMember(string memory _groupName, address _member) public view returns(bool) {
    return groups[_groupName].members[_member];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract AuthorizedHolders {
    function isMember(address _member) external returns(bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AddressManager.sol";
import "./AuthorizedHolders.sol";

contract xToken is ERC20, MembersManager {
  using SafeMath for uint256;

  enum contractState {active, safeguard}
  contractState public state;

  struct MintRequest {
    address destination;
    bool completed;
  }
  mapping(uint256 => MintRequest) public mintRequests;
  uint256 mintRequestID;

  struct RedemptionRequest {
    address sender;
    address recipient;
    uint256 amount;
    bool completed;
  }
  mapping(uint256 => RedemptionRequest) public redemptionRequests;
  uint256 redemptionRequestID;

  mapping(address => uint256) public safeguardStakes;
  uint256 public totalStakes;

  uint256 constant hundredPercent = 10 ** 27;
  uint256 statePercent;
  string public verificationLink;

  AuthorizedHolders authorizedHolders;
  
  constructor(address _issuer, address _guardian, address _authorizedHolders, uint256 _statePercent, string memory _verificationLink) ERC20("xToken", "xToken") {
    statePercent = _statePercent;
    AdminManager.setupRole("Issuer", _issuer);
    AdminManager.setupRole("Guardian", _guardian);
    authorizedHolders = AuthorizedHolders(_authorizedHolders);
    verificationLink = _verificationLink;
  }

  modifier onlyIssuer {
    AdminManager.onlyOwnerF("Issuer");
    _;
  }

  function onlyIssuerF() onlyIssuer private { }

  modifier onlyGuardian {
    AdminManager.onlyOwnerF("Guardian");
    _;
  }

  function onlyGuardianF() onlyGuardian private { }

  modifier onlyAgent {
    require(MembersManager.isMember("Agent", msg.sender), "NotAgent");
    _;
  }

  function onlyAgentF() onlyAgent private { }

  modifier onlyAuthorizedHolder(address _holder) {
    require(authorizedHolders.isMember(_holder), "NotAuthorizedHoler");
    _;
  }

  function onlyAuthorizedHolderF(address _holder) onlyAuthorizedHolder(_holder) private { }

  function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
    //burn case
    if (_to != address(0)) {
      onlyAuthorizedHolderF(_to);
    }
  }

  function requestMint() external returns(uint256) {
    return _requestMint(msg.sender);
  }

  function requestMint(address _destination) external returns(uint256) {
    return _requestMint(_destination);
  }

  function _requestMint(address _destination) onlyAuthorizedHolder(_destination) private returns(uint256) {
    uint256 _mintRequestID = ++mintRequestID;

    mintRequests[_mintRequestID] = MintRequest(_destination, false);
    mintRequestID = _mintRequestID;
    return _mintRequestID;
  }

  function approveMint(uint256 _mintRequestID, uint256 _amount) onlyIssuer external {
    MintRequest memory _info = mintRequests[_mintRequestID];

    require(!_info.completed, "AlreadyCompleted");

    ERC20._mint(_info.destination, _amount);

    _info.completed = true;
    mintRequests[_mintRequestID] = _info;
  }

  function requestRedemption(uint256 _amount) external returns(uint256) {
    return _requestRedemption(msg.sender, msg.sender, _amount);
  }

  function requestRedemption(uint256 _amount, address _recipient) external returns(uint256) {
    return _requestRedemption(msg.sender, _recipient, _amount);
  }

  // todo Triggers instruction for contract admin (Issuer) / (Guardian)
  function _requestRedemption(address _sender, address _recipient, uint256 _amount) private returns(uint256) {
    contractState _state = state;

    if (_state == contractState.active) {
      onlyAgentF();
    }

    if (_state == contractState.safeguard) {
      onlyAuthorizedHolderF(msg.sender);
    }

    require(ERC20.balanceOf(_sender) >= _amount, "NotEnoughToRedeem");

    ERC20.approve(AdminManager.safeGetRoleOwner("Issuer"), _amount);

    uint256 _redemptionRequestID = ++redemptionRequestID;
    redemptionRequests[_redemptionRequestID] = RedemptionRequest(_sender, _recipient, _amount, false);
    redemptionRequestID = _redemptionRequestID;
    return _redemptionRequestID;
  }

  function burnRedeemed(uint256 _redemptionRequestID) external {
    contractState _state = state;

    if (_state == contractState.active) {
      onlyIssuerF();
    }

    if (_state == contractState.safeguard) {
      onlyGuardianF();
    }

    RedemptionRequest memory _info = redemptionRequests[_redemptionRequestID];

    require(!_info.completed, "AlreadyCompleted");

    ERC20._burn(_info.sender, _info.amount);
    _info.completed = true;
    redemptionRequests[_redemptionRequestID] = _info;
  }

  // todo also triggers instruction for contract owner (Guardian) to claim underlying assets In the ‘Safeguarded’ state
  function burn(uint256 _amount) external {
    ERC20._burn(msg.sender, _amount);

    // if (state == contractState.safeguard) {
    //   todo triggers instruction
    // }
  }

  function safeguardStake(uint256 _amount) external {
    ERC20._transfer(msg.sender, address(this), _amount);
    safeguardStakes[msg.sender] = safeguardStakes[msg.sender].add(_amount);
    uint256 _totalStakes = totalStakes.add(_amount);
    totalStakes = _totalStakes;

    if (_totalStakes.mul(hundredPercent).div(ERC20.totalSupply()) >= statePercent) {
      state = contractState.safeguard;
    }
  }

  function safeguardUnstake() external {
    _safeguardUnstake(safeguardStakes[msg.sender]);
  }

  function safeguardUnstake(uint256 _amount) external {
    _safeguardUnstake(_amount);
  }

  function _safeguardUnstake(uint256 _amount) private {
    safeguardStakes[msg.sender] = safeguardStakes[msg.sender].sub(_amount);
    totalStakes = totalStakes.sub(_amount);
    ERC20._transfer(address(this), msg.sender, _amount);
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

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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