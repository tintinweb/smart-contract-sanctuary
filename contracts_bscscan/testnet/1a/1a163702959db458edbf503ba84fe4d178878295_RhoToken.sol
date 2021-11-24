//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../interfaces/IRhoTokenRewards.sol";
import "../interfaces/IRhoToken.sol";

contract RhoToken is IRhoToken, ERC20Upgradeable, AccessControlEnumerableUpgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev internally stored without any multiplier
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev rebase option will be set when user calls setRebasingOption()
     * default is UNKNOWN, determined by EOA/contract type
     */
    enum RebaseOption {
        UNKNOWN,
        REBASING,
        NON_REBASING
    }

    /**
     * @dev this mapping is valid only for addresses that have already changed their options.
     * To query an account's rebase option, call `isRebasingAccount()` externally
     * or `isRebasingAccountInternal()` internally.
     */
    mapping(address => RebaseOption) private _rebaseOptions;

    uint256 private _rebasingTotalSupply;
    uint256 private _nonRebasingTotalSupply;

    uint256 private constant ONE = 1e36;
    uint256 private multiplier;
    address public tokenRewardsAddress;
    uint256 public lastUpdateTime;

    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function __initialize(string memory name_, string memory symbol_) external initializer {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setMultiplier(ONE);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return _timesMultiplier(_rebasingTotalSupply) + _nonRebasingTotalSupply;
    }

    function adjustedRebasingSupply() external view override returns (uint256) {
        return _timesMultiplier(_rebasingTotalSupply);
    }

    function unadjustedRebasingSupply() external view override returns (uint256) {
        return _rebasingTotalSupply;
    }

    function nonRebasingSupply() external view override returns (uint256) {
        return _nonRebasingTotalSupply;
    }

    function balanceOf(address account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        if (isRebasingAccountInternal(account)) {
            return _timesMultiplier(_balances[account]);
        }
        return _balances[account];
    }

    function getOwner() external view override returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0) {
            return address(0);
        }
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override updateTokenRewards(sender) updateTokenRewards(recipient) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        // deducting from sender
        uint256 amountToDeduct = amount;
        if (isRebasingAccountInternal(sender)) {
            amountToDeduct = _dividedByMultiplier(amount);
            require(_balances[sender] >= amountToDeduct, "ERC20: transfer amount exceeds balance");
            _rebasingTotalSupply -= amountToDeduct;
        } else {
            require(_balances[sender] >= amountToDeduct, "ERC20: transfer amount exceeds balance");
            _nonRebasingTotalSupply -= amountToDeduct;
        }
        _balances[sender] -= amountToDeduct;
        // adding to recipient
        uint256 amountToAdd = amount;
        if (isRebasingAccountInternal(recipient)) {
            amountToAdd = _dividedByMultiplier(amount);
            _rebasingTotalSupply += amountToAdd;
        } else {
            _nonRebasingTotalSupply += amountToAdd;
        }
        _balances[recipient] += amountToAdd;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        uint256 amountToAdd = amount;
        if (isRebasingAccountInternal(account)) {
            amountToAdd = _dividedByMultiplier(amount);
            _rebasingTotalSupply += amountToAdd;
        } else {
            _nonRebasingTotalSupply += amountToAdd;
        }
        _balances[account] += amountToAdd;
        emit Transfer(address(0), account, amount);
        emit RhoTokenSupplyChanged(totalSupply(), _timesMultiplier(_rebasingTotalSupply), _nonRebasingTotalSupply);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);
        uint256 amountToDeduct = amount;
        if (isRebasingAccountInternal(account)) {
            amountToDeduct = _dividedByMultiplier(amount);
            require(_balances[account] >= amountToDeduct, "ERC20: burn amount exceeds balance");
            _rebasingTotalSupply -= amountToDeduct;
        } else {
            require(_balances[account] >= amountToDeduct, "ERC20: burn amount exceeds balance");
            _nonRebasingTotalSupply -= amountToDeduct;
        }
        _balances[account] -= amountToDeduct;
        emit Transfer(account, address(0), amount);
        emit RhoTokenSupplyChanged(totalSupply(), _timesMultiplier(_rebasingTotalSupply), _nonRebasingTotalSupply);
    }

    /* multiplier */
    function setMultiplier(uint256 multiplier_) external override onlyRole(VAULT_ROLE) updateTokenRewards(address(0)) {
        _setMultiplier(multiplier_);
        emit MultiplierChange(multiplier_);
        emit RhoTokenSupplyChanged(totalSupply(), _timesMultiplier(_rebasingTotalSupply), _nonRebasingTotalSupply);
    }

    function _setMultiplier(uint256 multiplier_) internal {
        multiplier = multiplier_;
        lastUpdateTime = block.timestamp;
    }

    function getMultiplier() external view override returns (uint256 _multiplier, uint256 _lastUpdateTime) {
        _multiplier = multiplier;
        _lastUpdateTime = lastUpdateTime;
    }

    function mint(address account, uint256 amount) external override onlyRole(MINTER_ROLE) updateTokenRewards(account) {
        require(amount > 0, "amount must be greater than zero");
        return _mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyRole(BURNER_ROLE) updateTokenRewards(account) {
        require(amount > 0, "amount must be greater than zero");
        return _burn(account, amount);
    }

    /* utils */
    function _timesMultiplier(uint256 input) internal view returns (uint256) {
        return (input * multiplier) / ONE;
    }

    function _dividedByMultiplier(uint256 input) internal view returns (uint256) {
        return (input * ONE) / multiplier;
    }

    function setRebasingOption(bool isRebasing) external override {
        if (isRebasingAccountInternal(_msgSender()) == isRebasing) {
            return;
        }
        uint256 userBalance = _balances[_msgSender()];
        if (isRebasing) {
            _rebaseOptions[_msgSender()] = RebaseOption.REBASING;
            _nonRebasingTotalSupply -= userBalance;
            _rebasingTotalSupply += _dividedByMultiplier(userBalance);
            _balances[_msgSender()] = _dividedByMultiplier(userBalance);
        } else {
            _rebaseOptions[_msgSender()] = RebaseOption.NON_REBASING;
            _rebasingTotalSupply -= userBalance;
            _nonRebasingTotalSupply += _timesMultiplier(userBalance);
            _balances[_msgSender()] = _timesMultiplier(userBalance);
        }
        emit RhoTokenSupplyChanged(totalSupply(), _timesMultiplier(_rebasingTotalSupply), _nonRebasingTotalSupply);
    }

    function isRebasingAccountInternal(address account) internal view returns (bool) {
        return
            (_rebaseOptions[account] == RebaseOption.REBASING) ||
            (_rebaseOptions[account] == RebaseOption.UNKNOWN && !account.isContract());
    }

    function isRebasingAccount(address account) external view override returns (bool) {
        return isRebasingAccountInternal(account);
    }

    /* token rewards */
    function setTokenRewards(address tokenRewards) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenRewardsAddress = tokenRewards;
    }

    // withdraw random token transfer into this contract
    function sweepERC20Token(address token, address to) external override onlyRole(SWEEPER_ROLE) {
        require(token != address(this), "!safe");
        IERC20Upgradeable tokenToSweep = IERC20Upgradeable(token);
        tokenToSweep.transfer(to, tokenToSweep.balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */
    modifier updateTokenRewards(address account) {
        if (tokenRewardsAddress != address(0)) {
            IRhoTokenRewards(tokenRewardsAddress).updateReward(account, address(this));
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IFlurryStakingRewards} from "../interfaces/IFlurryStakingRewards.sol";

/**
 * @title RhoToken Rewards Interface
 * @notice Interface for bonus FLURRY token rewards contract for RhoToken holders
 */
interface IRhoTokenRewards {
    /**
     * @notice checks whether the rewards for a rhoToken is supported by the reward scheme
     * @param rhoToken address of rhoToken contract
     * @return true if the reward scheme supports `rhoToken`, false otherwise
     */
    function isSupported(address rhoToken) external returns (bool);

    /**
     * @return list of addresses of rhoTokens registered in this contract
     */
    function getRhoTokenList() external view returns (address[] memory);

    /**
     * @return amount of FLURRY distributed for all rhoTokens per block
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Admin function - set reward rate earned for all rhoTokens per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param user The stakeholder to check rewards for.
     * @param rhoToken Address of rhoToken contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address rhoToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all rhoToken
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all rhoToken
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalClaimableRewardOf(address user) external view returns (uint256);

    /**
     * @notice Total accumulated reward per token
     * @param rhoToken Address of rhoToken contract
     * @return Reward entitlement for rho token
     */
    function rewardsPerToken(address rhoToken) external view returns (uint256);

    /**
     * @notice current reward rate per token staked
     * @param rhoToken Address of rhoToken contract
     * @return reward rate denominated in FLURRY per block
     */
    function rewardRatePerRhoToken(address rhoToken) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param rhoToken Address of rhoToken contract
     * @param rewardDuration Reward duration in number of blocks
     */
    function startRewards(address rhoToken, uint256 rewardDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     * @param rhoToken Address of rhoToken contract
     */
    function endRewards(address rhoToken) external;

    /**
     * @notice Calculate and allocate rewards token for address holder
     * Rewards should accrue from _lastUpdateBlock to lastBlockApplicable
     * rewardsPerToken is based on the total supply of the RhoToken, hence
     * this function needs to be called every time total supply changes
     * @dev intended to be called externally by RhoToken contract modifier, and internally
     * @param user the user to update reward for
     * @param rhoToken the rhoToken to update reward for
     */
    function updateReward(address user, address rhoToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for one rhoToken on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     * @param rhoToken Address of rhoToken contract
     */
    function claimReward(address onBehalfOf, address rhoToken) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for one rhoToken
     * @param rhoToken Address of rhoToken contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address rhoToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for all rhoTokens on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     */
    function claimAllReward(address onBehalfOf) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for all rhoTokens
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward() external;

    /**
     * @return true if rewards are locked for given rhoToken, false if rewards are unlocked or if rhoToken is not supported
     * @param rhoToken address of rhoToken contract
     */
    function isLocked(address rhoToken) external view returns (bool);

    /**
     * @notice Admin function - lock rewards for given rhoToken
     * @param rhoToken address of the rhoToken contract
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLock(address rhoToken, uint256 lockDuration) external;

    /**
     * @notice Admin function - lock rewards for given rhoToken until a specific block
     * @param rhoToken address of the rhoToken contract
     * @param lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlock(address rhoToken, uint256 lockEndBlock) external;

    /**
     * @notice Admin function - lock all rho Staking rewards
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLockForAllRho(uint256 lockDuration) external;

    /**
     * @notice Admin function - lock all rho Staking rewards until a specific block
     * @param lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlockForAllRho(uint256 lockEndBlock) external;

    /**
     * @notice Admin function - unlock rewards for given rhoToken
     * @param rhoToken address of the rhoToken contract
     */
    function earlyUnlock(address rhoToken) external;

    /**
     * @param rhoToken address of the rhoToken contract
     * @return the current lock end block number
     */
    function getLockEndBlock(address rhoToken) external view returns (uint256);

    /**
     * @notice Admin function - register a rhoToken to this contract
     * @param rhoToken address of the rhoToken to be registered
     * @param allocPoint allocation points (weight) assigned to the given rhoToken
     */
    function addRhoToken(address rhoToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - change the allocation points of a rhoToken registered in this contract
     * @param rhoToken address of the rhoToken subject to change
     * @param allocPoint allocation points (weight) assigned to the given rhoToken
     */
    function setRhoToken(address rhoToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @return reference to RhoToken Rewards contract
     */
    function flurryStakingRewards() external returns (IFlurryStakingRewards);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoToken is IERC20MetadataUpgradeable {
    event MultiplierChange(uint256 to);
    event RhoTokenSupplyChanged(uint256 totalSupply, uint256 rebasingSupply, uint256 nonRebasingSupply);

    /**
     * @notice specific to BEP-20 interface
     * @return the address of the contract owner
     */
    function getOwner() external view returns (address);

    /**
     * @dev adjusted supply is multiplied by multiplier from rebasing
     * @return issued amount of rhoToken that is rebasing
     * Total supply = adjusted rebasing supply + non-rebasing supply
     * Adjusted rebasing supply = unadjusted rebasing supply * multiplier
     */
    function adjustedRebasingSupply() external view returns (uint256);

    /**
     * @dev unadjusted supply is NOT multiplied by multiplier from rebasing
     * @return internally stored amount of rhoTokens that is rebasing
     */
    function unadjustedRebasingSupply() external view returns (uint256);

    /**
     * @return issued amount of rhoTokens that is non-rebasing
     */
    function nonRebasingSupply() external view returns (uint256);

    /**
     * @notice The multiplier is set during a rebase
     * @param multiplier - scaled by 1e36
     */
    function setMultiplier(uint256 multiplier) external;

    /**
     * @return multiplier - returns the muliplier of the rhoToken, scaled by 1e36
     * @return lastUpdate - last update time of the multiplier, equivalent to last rebase time
     */
    function getMultiplier() external view returns (uint256 multiplier, uint256 lastUpdate);

    /**
     * @notice function to mint rhoTokens - callable only by owner
     * @param account account for sending new minted tokens to
     * @param amount amount of tokens to be minted
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice function to burn rhoTokens - callable only by owner
     * @param account the account address for burning tokens from
     * @param amount amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice switches the account type of `msg.sender` between rebasing and non-rebasing
     * @param isRebasing true if setting to rebasing, false if setting to non-rebasing
     * NOTE: this function does nothing if caller is already in the same option
     */
    function setRebasingOption(bool isRebasing) external;

    /**
     * @param account address of account to check
     * @return true if `account` is a rebasing account
     */
    function isRebasingAccount(address account) external view returns (bool);

    /**
     * @notice Admin function - set reference token rewards contract
     * @param tokenRewards token rewards contract address
     */
    function setTokenRewards(address tokenRewards) external;

    /**
     * @notice Admin function to sweep ERC20s (other than rhoToken) accidentally sent to this contract
     * @param token token contract address
     * @param to which address to send sweeped ERC20s to
     */
    function sweepERC20Token(address token, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {ILPStakingRewards} from "../interfaces/ILPStakingRewards.sol";
import {IRhoTokenRewards} from "../interfaces/IRhoTokenRewards.sol";

/**
 * @title Flurry Staking Rewards Interface
 * @notice Interface for Flurry token staking functions
 *
 */
interface IFlurryStakingRewards {
    /**
     * @dev equals to balance of FLURRY minus total stakes
     * @return amount of FLURRY rewards available for the three reward schemes
     * (Flurry Staking, LP Token Staking and rhoToken Holding)
     */
    function totalRewardsPool() external view returns (uint256);

    /**
     * @return aggregated FLURRY stakes from all stakers (in wei)
     */
    function totalStakes() external view returns (uint256);

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param user Stakeholder address
     * @return user staked amount (in wei)
     */
    function stakeOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his claimable rewards.
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function claimableRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check all his rewards.
     * Includes Staking Rewards + RhoToken Rewards + LP Token Rewards
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholderto check his claimable rewards.
     * Includes Staking Rewards + RhoToken Rewards + LP Token Rewards
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalClaimableRewardOf(address user) external view returns (uint256);

    /**
     * @return amount of FLURRY distrubuted to all FLURRY stakers per block
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement per FLURRY token staked (in wei)
     */
    function rewardsPerToken() external view returns (uint256);

    /**
     * @notice current reward rate per FLURRY token staked
     * @return rewards rate in FLURRY per block per FLURRY staked scaled by 18 decimals
     */
    function rewardRatePerTokenStaked() external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(uint256 amount) external;

    /**
     * @notice A method to unstake.
     * @param amount amount to unstake (in wei)
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw his FLURRY staking rewards.
     */
    function claimReward() external;

    /**
     * @notice A method to allow a stakeholder to claim all his rewards.
     */
    function claimAllRewards() external;

    /**
     * @notice NOT for external use
     * @dev only callable by LPStakingRewards or RhoTokenRewards for FLURRY distribution
     * @param addr address of LP Token staker / rhoToken holder
     * @param amount amount of FLURRY token rewards to grant (in wei)
     * @return outstanding amount if claim is not successful, 0 if successful
     */
    function grantFlurry(address addr, uint256 amount) external returns (uint256);

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit() external;

    /**
     * @notice Admin function - set rewards rate earned for FLURRY staking per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice Admin function - A method to start rewards distribution
     * @param rewardsDuration rewards duration in number of blocks
     */
    function startRewards(uint256 rewardsDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     */
    function endRewards() external;

    /**
     * @return true if reward is locked, false otherwise
     */
    function isLocked() external view returns (bool);

    /**
     * @notice Admin function - lock all rewards for all users for a given duration
     * This function should be called BEFORE startRewards()
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLock(uint256 lockDuration) external;

    /**
     * @notice Admin function - unlock all rewards immediately, if there is a time lock
     */
    function earlyUnlock() external;

    /**
     * @notice Admin function - lock FLURRY staking rewards until a specific block
     * @param _lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlock(uint256 _lockEndBlock) external;

    /**
     * @notice Admin function - withdraw other ERC20 tokens sent to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Admin function - set RhoTokenReward contract reference
     */
    function setRhoTokenRewardContract(address rhoTokenRewardAddr) external;

    /**
     * @notice Admin function - set LP Rewards contract reference
     */
    function setLPRewardsContract(address lpRewardsAddr) external;

    /**
     * @return reference to LP Staking Rewards contract
     */
    function lpStakingRewards() external returns (ILPStakingRewards);

    /**
     * @return reference to RhoToken Rewards contract
     */
    function rhoTokenRewards() external returns (IRhoTokenRewards);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IFlurryStakingRewards} from "../interfaces/IFlurryStakingRewards.sol";

/**
 * @title LP Staking Rewards Interface
 * @notice Interface for FLURRY token rewards when staking LP tokens
 */
interface ILPStakingRewards {
    /**
     * @notice checks whether the staking of a LP token is supported by the reward scheme
     * @param lpToken address of LP Token contract
     * @return true if the reward scheme supports `lpToken`, false otherwise
     */
    function isSupported(address lpToken) external returns (bool);

    /**
     * @param user user address
     * @return list of addresses of LP user has engaged in
     */
    function getUserEngagedPool(address user) external view returns (address[] memory);

    /**
     * @return list of addresses of LP registered in this contract
     */
    function getPoolList() external view returns (address[] memory);

    /**
     * @return amount of FLURRY distrubuted for all LP per block,
     * to be shared by the staking pools according to allocation points
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Admin function - set rewards rate earned for all LP per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param addr Stakeholder address
     * @param lpToken Address of LP Token contract
     * @return user staked amount (in wei)
     */
    function stakeOf(address addr, address lpToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for one LP token
     * @param user The stakeholder to check rewards for
     * @param lpToken Address of LP Token contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address lpToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards earned for all LP token
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his claimble rewards for all LP token
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalClaimableRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param lpToken Address of LP Token contract
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(address lpToken, uint256 amount) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for one LP on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     * @param lpToken Address of LP Token contract
     */
    function claimReward(address onBehalfOf, address lpToken) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for one LP token
     * @param lpToken Address of LP Token contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address lpToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for all LP on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     */
    function claimAllReward(address onBehalfOf) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for all LP token
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward() external;

    /**
     * @notice A method to unstake.
     * @param lpToken Address of LP Token contract
     * @param amount amount to unstake (in wei)
     */
    function withdraw(address lpToken, uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * @param lpToken Address of LP Token contract
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit(address lpToken) external;

    /**
     * @notice Total accumulated reward per token
     * @param lpToken Address of LP Token contract
     * @return Reward entitlement per LP token staked (in wei)
     */
    function rewardsPerToken(address lpToken) external view returns (uint256);

    /**
     * @notice current reward rate per LP token staked
     * @param lpToken Address of LP Token contract
     * @return rewards rate in FLURRY per block per LP staked scaled by 18 decimals
     */
    function rewardRatePerTokenStaked(address lpToken) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param lpToken Address of LP Token contract
     * @param rewardDuration Reward Duration in number of blocks
     */
    function startRewards(address lpToken, uint256 rewardDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier if there is one running
     * @param lpToken Address of LP Token contract
     */
    function endRewards(address lpToken) external;

    /**
     * @return true if rewards are locked for given lpToken, false if rewards are unlocked or if lpTokenis not supported
     * @param lpToken address of LP Token contract
     */
    function isLocked(address lpToken) external view returns (bool);

    /**
     * @notice Admin function - lock rewards for given lpToken
     * @param lpToken address of the lpToken contract
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLock(address lpToken, uint256 lockDuration) external;

    /**
     * @notice Admin function - lock rewards for given lpToken until a specific block
     * @param lpToken address of the lpToken contract
     * @param lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlock(address lpToken, uint256 lockEndBlock) external;

    /**
     * @notice Admin function - lock all lpToken rewards
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLockForAllLPTokens(uint256 lockDuration) external;

    /**
     * @notice Admin function - lock all lpToken rewards until a specific block
     * @param lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlockForAllLPTokens(uint256 lockEndBlock) external;

    /**
     * @notice Admin function - unlock rewards for given lpToken
     * @param lpToken address of the lpToken contract
     */
    function earlyUnlock(address lpToken) external;

    /**
     * @param lpToken address of the lpToken contract
     * @return the current lock end block number
     */
    function getLockEndBlock(address lpToken) external view returns (uint256);

    /**
     * @notice Admin function - register a LP to this contract
     * @param lpToken address of the LP to be registered
     * @param allocPoint allocation points (weight) assigned to the given LP
     */
    function addLP(address lpToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - change the allocation points of a LP registered in this contract
     * @param lpToken address of the LP subject to change
     * @param allocPoint allocation points (weight) assigned to the given LP
     */
    function setLP(address lpToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @return reference to RhoToken Rewards contract
     */
    function flurryStakingRewards() external returns (IFlurryStakingRewards);
}