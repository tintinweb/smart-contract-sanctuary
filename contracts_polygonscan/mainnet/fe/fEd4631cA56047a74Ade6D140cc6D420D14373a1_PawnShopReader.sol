// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../base/governance/Controllable.sol";
import "../infrastructure/IPriceCalculator.sol";
import "../loan/ITetuPawnShop.sol";

/// @title View data reader for using on website UI and other integrations
/// @author belbix
contract PawnShopReader is Initializable, Controllable {

  string public constant VERSION = "1.0.0";
  uint256 constant public PRECISION = 1e18;
  string private constant _CALCULATOR = "calculator";
  string private constant _SHOP = "shop";

  // DO NOT CHANGE NAMES OR ORDERING!
  mapping(bytes32 => address) internal tools;

  function initialize(address _controller, address _calculator, address _pawnshop) external initializer {
    Controllable.initializeControllable(_controller);
    tools[keccak256(abi.encodePacked(_CALCULATOR))] = _calculator;
    tools[keccak256(abi.encodePacked(_SHOP))] = _pawnshop;
  }

  event ToolAddressUpdated(string name, address newValue);

  // ************** READ FUNCTIONS **************

  function positions(uint256 from, uint256 to) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().positionCounter();
    if (size == 1) {
      return new ITetuPawnShop.Position[](0);
    }
    if (from == 0) {
      from = 1;
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(i);
      j++;
    }

    return result;
  }

  function openPositions(uint256 from, uint256 to) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().openPositionsSize();
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().openPositions(i));
      j++;
    }

    return result;
  }

  function positionsByCollateral(
    address collateral,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().positionsByCollateralSize(collateral);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().positionsByCollateral(collateral, i));
      j++;
    }

    return result;
  }

  function positionsByAcquired(
    address acquired,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().positionsByAcquiredSize(acquired);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().positionsByAcquired(acquired, i));
      j++;
    }

    return result;
  }

  function borrowerPositions(
    address borrower,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().borrowerPositionsSize(borrower);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().borrowerPositions(borrower, i));
      j++;
    }

    return result;
  }

  function lenderPositions(
    address lender,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().lenderPositionsSize(lender);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().lenderPositions(lender, i));
      j++;
    }

    return result;
  }

  function auctionBids(uint256 from, uint256 to) external view returns (ITetuPawnShop.AuctionBid[] memory){
    uint256 size = pawnshop().auctionBidCounter();
    if (size == 1) {
      return new ITetuPawnShop.AuctionBid[](0);
    }
    if (from == 0) {
      from = 1;
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.AuctionBid[] memory result = new ITetuPawnShop.AuctionBid[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getAuctionBid(i);
      j++;
    }

    return result;
  }

  function lenderAuctionBid(address lender, uint256 posId) external view returns (ITetuPawnShop.AuctionBid memory){
    uint256 index = pawnshop().lenderOpenBids(lender, posId) - 1;
    uint256 bidId = pawnshop().positionToBidIds(posId, index);
    return pawnshop().getAuctionBid(bidId);
  }

  function positionAuctionBids(uint256 posId, uint256 from, uint256 to) external view returns (ITetuPawnShop.AuctionBid[] memory){
    uint256 size = pawnshop().auctionBidSize(posId);
    if (size == 0) {
      return new ITetuPawnShop.AuctionBid[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.AuctionBid[] memory result = new ITetuPawnShop.AuctionBid[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getAuctionBid(pawnshop().positionToBidIds(posId, i));
      j++;
    }

    return result;
  }

  // ******************** COMMON VIEWS ********************

  // normalized precision
  //noinspection NoReturn
  function getPrice(address _token) public view returns (uint256) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try priceCalculator().getPriceWithDefaultOutput(_token) returns (uint256 price){
      return price;
    } catch {
      return 0;
    }
  }

  function normalizePrecision(uint256 amount, uint256 decimals) internal pure returns (uint256){
    return amount * PRECISION / (10 ** decimals);
  }

  function priceCalculator() public view returns (IPriceCalculator) {
    return IPriceCalculator(tools[keccak256(abi.encodePacked(_CALCULATOR))]);
  }

  function pawnshop() public view returns (ITetuPawnShop) {
    return ITetuPawnShop(tools[keccak256(abi.encodePacked(_SHOP))]);
  }

  // *********** GOVERNANCE ACTIONS *****************

  function setPriceCalculator(address newValue) external onlyControllerOrGovernance {
    tools[keccak256(abi.encodePacked(_CALCULATOR))] = newValue;
    emit ToolAddressUpdated(_CALCULATOR, newValue);
  }

  function setPawnShop(address newValue) external onlyControllerOrGovernance {
    tools[keccak256(abi.encodePacked(_SHOP))] = newValue;
    emit ToolAddressUpdated(_SHOP, newValue);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPriceCalculator {

  function getPrice(address token, address outputToken) external view returns (uint256);

  function getPriceWithDefaultOutput(address token) external view returns (uint256);

  function getLargestPool(address token, address[] memory usedLps) external view returns (address, uint256, address);

  function getPriceFromLp(address lpAddress, address token) external view returns (uint256);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Interface for Tetu PawnShop contract
/// @author belbix
interface ITetuPawnShop {

  event PositionOpened(uint256 posId);
  event PositionClosed(uint256 posId);
  event BidExecuted(uint256 posId, address lender, uint256 amount);
  event AuctionBidOpened(uint256 posId, uint256 bidId);
  event PositionClaimed(uint256 posId);
  event PositionRedeemed(uint256 posId);
  event AuctionBidAccepted(uint256 posId, uint256 bidId);
  event AuctionBidClosed(uint256 posId, uint256 bidId);

  enum AssetType {
    ERC20, // 0
    ERC721 // 1
  }

  enum IndexType {
    LIST, // 0
    BY_COLLATERAL, // 1
    BY_ACQUIRED, // 2
    BORROWER_POSITION, // 3
    LENDER_POSITION // 4
  }

  struct Position {
    uint256 id;
    address borrower;
    address depositToken;
    uint256 depositAmount;
    bool open;
    PositionInfo info;
    PositionCollateral collateral;
    PositionAcquired acquired;
    PositionExecution execution;
  }

  struct PositionInfo {
    uint256 posDurationBlocks;
    uint256 posFee;
    uint256 createdBlock;
    uint256 createdTs;
  }

  struct PositionCollateral {
    address collateralToken;
    AssetType collateralType;
    uint256 collateralAmount;
    uint256 collateralTokenId;
  }

  struct PositionAcquired {
    address acquiredToken;
    uint256 acquiredAmount;
  }

  struct PositionExecution {
    address lender;
    uint256 posStartBlock;
    uint256 posStartTs;
    uint256 posEndTs;
  }

  struct AuctionBid {
    uint256 id;
    uint256 posId;
    address lender;
    uint256 amount;
    bool open;
  }

  // ****************** VIEWS ****************************

  /// @dev PosId counter. Should start from 1 for keep 0 as empty value
  function positionCounter() external view returns (uint256);

  /// @notice Return Position for given id
  /// @dev AbiEncoder not able to auto generate functions for mapping with structs
  function getPosition(uint256 posId) external view returns (Position memory);

  /// @dev Hold open positions ids. Removed when position closed
  function openPositions(uint256 index) external view returns (uint256 posId);

  /// @dev Collateral token => PosIds
  function positionsByCollateral(address collateralToken, uint256 index) external view returns (uint256 posId);

  /// @dev Acquired token => PosIds
  function positionsByAcquired(address acquiredToken, uint256 index) external view returns (uint256 posId);

  /// @dev Borrower token => PosIds
  function borrowerPositions(address borrower, uint256 index) external view returns (uint256 posId);

  /// @dev Lender token => PosIds
  function lenderPositions(address lender, uint256 index) external view returns (uint256 posId);

  /// @dev index type => PosId => index
  ///      Hold array positions for given type of array
  function posIndexes(IndexType typeId, uint256 posId) external view returns (uint256 index);

  /// @dev BidId counter. Should start from 1 for keep 0 as empty value
  function auctionBidCounter() external view returns (uint256);

  /// @notice Return auction bid for given id
  /// @dev AbiEncoder not able to auto generate functions for mapping with structs
  function getAuctionBid(uint256 bidId) external view returns (AuctionBid memory);

  /// @dev lender => PosId => positionToBidIds + 1
  ///      Lender auction position for given PosId. 0 keep for empty position
  function lenderOpenBids(address lender, uint256 posId) external view returns (uint256 index);

  /// @dev PosId => bidIds. All open and close bids for the given position
  function positionToBidIds(uint256 posId, uint256 index) external view returns (uint256 bidId);

  /// @dev PosId => timestamp. Timestamp of the last bid for the auction
  function lastAuctionBidTs(uint256 posId) external view returns (uint256 ts);

  /// @dev Return amount required for redeem position
  function toRedeem(uint256 posId) external view returns (uint256 amount);

  /// @dev Return asset type ERC20 or ERC721
  function getAssetType(address _token) external view returns (AssetType);

  function isERC721(address _token) external view returns (bool);

  function isERC20(address _token) external view returns (bool);

  /// @dev Return size of active positions
  function openPositionsSize() external view returns (uint256);

  /// @dev Return size of all auction bids for given position
  function auctionBidSize(uint256 posId) external view returns (uint256);

  function positionsByCollateralSize(address collateral) external view returns (uint256);

  function positionsByAcquiredSize(address acquiredToken) external view returns (uint256);

  function borrowerPositionsSize(address borrower) external view returns (uint256);

  function lenderPositionsSize(address lender) external view returns (uint256);

  // ************* USER ACTIONS *************

  /// @dev Borrower action. Assume approve
  ///      Open a position with multiple options - loan / instant deal / auction
  function openPosition(
    address _collateralToken,
    uint256 _collateralAmount,
    uint256 _collateralTokenId,
    address _acquiredToken,
    uint256 _acquiredAmount,
    uint256 _posDurationBlocks,
    uint256 _posFee
  ) external returns (uint256);

  /// @dev Borrower action
  ///      Close not executed position. Return collateral and deposit to borrower
  function closePosition(uint256 id) external;

  /// @dev Lender action. Assume approve for acquired token
  ///      Place a bid for given position ID
  ///      It can be an auction bid if acquired amount is zero
  function bid(uint256 id, uint256 amount) external;

  /// @dev Lender action
  ///      Transfer collateral to lender if borrower didn't return the loan
  ///      Deposit will be returned to borrower
  function claim(uint256 id) external;

  /// @dev Borrower action. Assume approve on acquired token
  ///      Return the loan to lender, transfer collateral and deposit to borrower
  function redeem(uint256 id) external;

  /// @dev Borrower action. Assume that auction ended.
  ///      Transfer acquired token to borrower
  function acceptAuctionBid(uint256 posId) external;

  /// @dev Lender action. Requires ended auction, or not the last bid
  ///      Close auction bid and transfer acquired tokens to lender
  function closeAuctionBid(uint256 bidId) external;


  /// @dev Platform fee in range 0 - 500, with denominator 10000
  function setPlatformFee(uint256 _value) external;

  /// @dev Tokens amount that need to deposit for a new position
  ///      Will be returned when position closed
  function setPositionDepositAmount(uint256 _value) external;

  /// @dev Tokens that need to deposit for a new position
  function setPositionDepositToken(address _value) external;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function addToWhiteListMulti(address[] calldata _targets) external;

  function addToWhiteList(address _target) external;

  function removeFromWhiteListMulti(address[] calldata _targets) external;

  function removeFromWhiteList(address _target) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}