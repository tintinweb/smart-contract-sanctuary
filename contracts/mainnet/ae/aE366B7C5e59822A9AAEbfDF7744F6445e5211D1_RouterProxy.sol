//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IRouterProxy.sol";
import "./interfaces/IRouterDiamond.sol";
import "./interfaces/IERC2612Permit.sol";

/**
 * @dev If we are paying the fee in something other than ALBT or transferring
 * native currency, we use this proxy contract instead of the bridge router.
 */
contract RouterProxy is IRouterProxy, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public routerAddress;
    address public albtToken;
    mapping(address => uint256) public feeAmountByToken;
    uint8 private immutable _decimals;

    /**
     *  @notice Constructs a new RouterProxy contract
     *  @param routerAddress_ The address of the underlying router
     *  @param albtToken_ The address of the (w)ALBT contract
     *  @param tokenName_ The name for the ERC20 token representing the native currency
     *  @param tokenSymbol_ The symbol for the ERC20 token representing the native currency
     *  @param decimals_ The number of decimals for the ERC20 token representing the native currency
     */
    constructor(
        address routerAddress_, address albtToken_, string memory tokenName_, string memory tokenSymbol_, uint8 decimals_
    ) ERC20(tokenName_, tokenSymbol_) {
        require(routerAddress_ != address(0), "Router address must be non-zero");
        require(albtToken_ != address(0), "ALBT address must be non-zero");
        routerAddress = routerAddress_;
        albtToken = albtToken_;
        _decimals = decimals_;
    }

    /**
     *  @notice Set the fee amount for a token
     *  @param tokenAddress_ The address of the ERC20 token contract
     *  @param fee_ The fee amount when paying with this token
     */
    function setFee(address tokenAddress_, uint256 fee_) external override onlyOwner {
        emit FeeSet(tokenAddress_, feeAmountByToken[tokenAddress_], fee_);
        feeAmountByToken[tokenAddress_] = fee_;
    }

    /**
     *  @param tokenAddress_ The address of the ERC20 token contract
     *  @return The fee amount for the token
     */
    function _fee(address tokenAddress_) view internal virtual returns (uint256) {
        require(feeAmountByToken[tokenAddress_] > 0, "Unsupported token");
        return feeAmountByToken[tokenAddress_];
    }

    /**
     *  @notice Set the address for the router contract
     *  @param routerAddress_ The address of the router contract
     */
    function setRouterAddress(address routerAddress_) external override onlyOwner {
        emit RouterAddressSet(routerAddress, routerAddress_);
        routerAddress = routerAddress_;
    }

    /**
     *  @notice Set the address for the (w)ALBT contract
     *  @param albtToken_ The address of the (w)ALBT contract
     */
    function setAlbtToken(address albtToken_) external override onlyOwner {
        emit AlbtAddressSet(albtToken, albtToken_);
        albtToken = albtToken_;
    }

    /**
     *  @param tokenAddress_ The address of the token contract
     *  @return Checks if the supplied token address is representing the native currency
     */
    function _isNativeCurrency(address tokenAddress_) internal view returns(bool) {
        return tokenAddress_ == address(this);
    }

    /**
     *  @notice Gets the user's funds and approves their transfer to the router, covering the fee in (w)ALBT
     *  @param feeToken_ Token the user is paying the fee in
     *  @param transferToken_ Token the user wants to transfer
     *  @param amount_ Amount the user wants to transfer
     */
    function _setupProxyPayment(address feeToken_, address transferToken_, uint256 amount_) internal nonReentrant {
        uint256 currencyLeft = msg.value;
        bool isTransferTokenNativeCurrency = _isNativeCurrency(transferToken_);

        if (isTransferTokenNativeCurrency) {
            require(currencyLeft >= amount_, "Not enough funds sent to transfer");
            currencyLeft -= amount_;
            _mint(address(this), amount_);
        }
        else {
            IERC20(transferToken_).safeTransferFrom(msg.sender, address(this), amount_);
        }

        uint256 feeOwed = _fee(feeToken_);
        if (_isNativeCurrency(feeToken_)) {
            require(currencyLeft >= feeOwed, "Not enough funds sent to pay the fee");
            currencyLeft -= feeOwed;

            (bool success, bytes memory returndata) = owner().call{value: feeOwed}("");
            require(success, string(returndata));
        }
        else {
            IERC20(feeToken_).safeTransferFrom(msg.sender, owner(), feeOwed);
        }
        emit FeeCollected(feeToken_, feeOwed);

        uint256 albtApproveAmount = IRouterDiamond(routerAddress).serviceFee() + IRouterDiamond(routerAddress).externalFee();
        if (transferToken_ == albtToken) {
            albtApproveAmount += amount_;
        }
        else if (isTransferTokenNativeCurrency) {
            _approve(address(this), routerAddress, amount_);
        }
        else {
            IERC20(transferToken_).approve(routerAddress, amount_);
        }
        IERC20(albtToken).approve(routerAddress, albtApproveAmount);

        if (currencyLeft > 0) {
            (bool success, bytes memory returndata) = msg.sender.call{value: currencyLeft}("");
            require(success, string(returndata));
        }
    }

    /**
     *  @notice Transfers `amount` native tokens to the router contract.
                The router must be authorised to transfer both the native token and the ALBT tokens for the fees.
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The target chain for the bridging operation
     *  @param nativeToken_ The token to be bridged
     *  @param amount_ The amount of tokens to bridge
     *  @param receiver_ The address of the receiver in the target chain
     */
    function lock(
        address feeToken_,
        uint8 targetChain_,
        address nativeToken_,
        uint256 amount_,
        bytes calldata receiver_
    ) public override payable {
        _setupProxyPayment(feeToken_, nativeToken_, amount_);
        IRouterDiamond(routerAddress).lock(targetChain_, nativeToken_, amount_, receiver_);
        emit ProxyLock(feeToken_, targetChain_, nativeToken_, amount_, receiver_);
    }

    /**
     *  @notice Locks the provided amount of nativeToken using an EIP-2612 permit and initiates a bridging transaction
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The chain to bridge the tokens to
     *  @param nativeToken_ The native token to bridge
     *  @param amount_ The amount of nativeToken to lock and bridge
     *  @param deadline_ The deadline for the provided permit
     *  @param v_ The recovery id of the permit's ECDSA signature
     *  @param r_ The first output of the permit's ECDSA signature
     *  @param s_ The second output of the permit's ECDSA signature
     */
    function lockWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address nativeToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override payable {
        IERC2612Permit(nativeToken_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        lock(feeToken_, targetChain_, nativeToken_, amount_, receiver_);
    }

    /**
     *  @notice Calls burn on the given wrapped token contract with `amount` wrapped tokens from `msg.sender`.
                The router must be authorised to transfer the ABLT tokens for the fees.
     *  @param feeToken_ Token used to pay the fee
     *  @param wrappedToken_ The wrapped token to burn
     *  @param amount_ The amount of wrapped tokens to be bridged
     *  @param receiver_ The address of the user in the original chain for this wrapped token
     */
    function burn(
        address feeToken_, address wrappedToken_, uint256 amount_, bytes memory receiver_
    ) public override payable {
        _setupProxyPayment(feeToken_, wrappedToken_, amount_);
        IRouterDiamond(routerAddress).burn(wrappedToken_, amount_, receiver_);
        emit ProxyBurn(feeToken_, wrappedToken_, amount_, receiver_);
    }

    /**
     *  @notice Burns `amount` of `wrappedToken` using an EIP-2612 permit and initializes a bridging transaction to the original chain
     *  @param feeToken_ Token used to pay the fee
     *  @param wrappedToken_ The address of the wrapped token to burn
     *  @param amount_ The amount of `wrappedToken` to burn
     *  @param receiver_ The receiving address in the original chain for this wrapped token
     *  @param deadline_ The deadline of the provided permit
     *  @param v_ The recovery id of the permit's ECDSA signature
     *  @param r_ The first output of the permit's ECDSA signature
     *  @param s_ The second output of the permit's ECDSA signature
     */
    function burnWithPermit(
        address feeToken_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override payable {
        IERC2612Permit(wrappedToken_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        burn(feeToken_, wrappedToken_, amount_, receiver_);
    }

    /**
     *  @notice Calls burn on the given wrapped token contract with `amount` wrapped tokens from `msg.sender`.
                The router must be authorised to transfer the ABLT tokens for the fees.
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The target chain for the bridging operation
     *  @param wrappedToken_ The wrapped token to burn
     *  @param amount_ The amount of wrapped tokens to be bridged
     *  @param receiver_ The address of the user in the original chain for this wrapped token
     */
    function burnAndTransfer(
        address feeToken_,
        uint8 targetChain_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_
    ) public override payable {
        _setupProxyPayment(feeToken_, wrappedToken_, amount_);
        IRouterDiamond(routerAddress).burnAndTransfer(targetChain_, wrappedToken_, amount_, receiver_);
        emit ProxyBurnAndTransfer(feeToken_, targetChain_, wrappedToken_, amount_, receiver_);
    }

    /**
     *  @notice Burns `amount` of `wrappedToken` using an EIP-2612 permit and initializes a bridging transaction to the original chain
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The target chain for the bridging operation
     *  @param wrappedToken_ The address of the wrapped token to burn
     *  @param amount_ The amount of `wrappedToken` to burn
     *  @param receiver_ The receiving address in the original chain for this wrapped token
     *  @param deadline_ The deadline of the provided permit
     *  @param v_ The recovery id of the permit's ECDSA signature
     *  @param r_ The first output of the permit's ECDSA signature
     *  @param s_ The second output of the permit's ECDSA signature
     */
    function burnAndTransferWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override payable {
        IERC2612Permit(wrappedToken_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        burnAndTransfer(feeToken_, targetChain_, wrappedToken_, amount_, receiver_);
    }

    /**
    * @dev Invoked by the router when unlocking tokens
    * Overriden so unlocking automatically unwraps to native currency
    */
    function transfer(address recipient_, uint256 amount_) public override returns (bool) {
        bool success = false;

        if (msg.sender == routerAddress) {
            bytes memory returndata;

            _burn(msg.sender, amount_);
            (success, returndata) = recipient_.call{value: amount_}("");
            require(success, string(returndata));
        }

        return success;
    }

    /**
     *  @notice Get the ERC20 decimal count
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     *  @notice Send contract's tokens to the owner's address
     *  @param tokenAddress_ The token we want to claim
     *  @dev In case we want to take out the (w)ALBT
     */
    function claimTokens(address tokenAddress_) external override onlyOwner {
        uint256 amount = IERC20(tokenAddress_).balanceOf(address(this));
        IERC20(tokenAddress_).safeTransfer(owner(), amount);
        emit TokensClaimed(tokenAddress_, amount);
    }

    /**
     *  @notice Send the contract's currency to the owner's address
     *  @dev In case we want to replace the RouterProxy contract
     */
    function claimCurrency() external override onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, bytes memory returndata) = owner().call{value: amount}("");
        require(success, string(returndata));

        emit CurrencyClaimed(amount);
    }

    /**
     *  @notice Loads the bridge with native currency
     *  @dev Usable when you add a pre-existing WrappedToken contract for native currency
     */
    function bridgeAirdrop() external override payable onlyOwner {
        require(msg.value > 0, "Expected funds");
        _mint(routerAddress, msg.value);
        emit BridgeAirdrop(msg.value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IRouterProxy {

    /// @notice An event emitted when setting the fee amount for a token
    event FeeSet(address token_, uint256 oldFee_, uint256 newFee_);
    /// @notice An event emitted when setting a new Router address
    event RouterAddressSet(address oldRouter_, address newRouter_);
    /// @notice An event emitted when setting a new ALBT address
    event AlbtAddressSet(address oldAlbt_, address newAlbt_);
    /// @notice An event emitted once a Lock transaction is proxied
    event ProxyLock(address feeToken_, uint8 targetChain_, address nativeToken_, uint256 amount_, bytes receiver_);
    /// @notice An event emitted once a Burn transaction is proxied
    event ProxyBurn(address feeToken_, address wrappedToken_, uint256 amount_, bytes receiver_);
    /// @notice An event emitted once a BurnAndTransfer transaction is proxied
    event ProxyBurnAndTransfer(address feeToken_, uint8 targetChain_, address wrappedToken_, uint256 amount_, bytes receiver_);
    /// @notice An event emitted when the proxy collects a fee
    event FeeCollected(address token_, uint256 amount_);
    /// @notice An event emitted when contract's tokens are sent to the owner
    event TokensClaimed(address token_, uint256 amount_);
    /// @notice An event emitted when the contract's currency is sent to the owner
    event CurrencyClaimed(uint256 amount);
    /// @notice An event emitted when currency is manually sent to the bridge
    event BridgeAirdrop(uint256 amount_);

    function setFee(address tokenAddress_, uint256 fee_) external;

    function setRouterAddress(address routerAddress_) external;

    function setAlbtToken(address albtToken_) external;

    function lock(address feeToken_, uint8 targetChain_, address nativeToken_, uint256 amount_, bytes calldata receiver_) external payable;

    function lockWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address nativeToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function burn(address feeToken_, address wrappedToken_, uint256 amount_, bytes calldata receiver_) external payable;

    function burnWithPermit(
        address feeToken_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function burnAndTransfer(address feeToken_, uint8 targetChain_, address wrappedToken_, uint256 amount_, bytes calldata receiver_)
        external payable;

    function burnAndTransferWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function claimTokens(address tokenAddress_) external;
    function claimCurrency() external;

    function bridgeAirdrop() external payable;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";
import "./IFeeCalculator.sol";
import "./IFeeExternal.sol";
import "./IRouter.sol";
import "./IGovernance.sol";
import "./IUtility.sol";

interface IRouterDiamond is IGovernance, IDiamondCut, IDiamondLoupe, IFeeCalculator, IFeeExternal, IUtility, IRouter {}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612Permit {
    /**
     * @dev Sets `_amount` as the allowance of `_spender` over `_owner`'s tokens,
     * given `_owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     * - `_deadline` must be a timestamp in the future.
     * - `_v`, `_r` and `_s` must be a valid `secp256k1` signature from `_owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``_owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `_owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``_owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address _owner) external view returns (uint256);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    /// @param _signatures The signatures of between n/2 and n validators for this upgrade
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata,
        bytes[] memory _signatures
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IFeeCalculator {
    /// @notice An event emitted once the service fee is modified
    event ServiceFeeSet(address account, uint256 newServiceFee);
    /// @notice An event emitted once a member claims fees accredited to him
    event Claim(address member, uint256 amount);

    /**
     *  @notice Construct a new FeeCalculator contract
     *  @param _serviceFee The initial service fee in ALBT tokens (flat)
     */
    function initFeeCalculator(uint256 _serviceFee) external;

    /// @return The currently set service fee
    function serviceFee() external view returns (uint256);

    /**
     *  @notice Sets the service fee for this chain
     *  @param _serviceFee The new service fee
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function setServiceFee(uint256 _serviceFee, bytes[] calldata _signatures) external;

    /// @return The current feesAccrued counter
    function feesAccrued() external view returns (uint256);

    /// @return The feesAccrued counter before the last reward distribution
    function previousAccrued() external view returns (uint256);

    /// @return The current accumulator counter
    function accumulator() external view returns (uint256);

    /**
     *  @param _account The address of a validator
     *  @return The total amount of ALBT claimed by the provided validator address
     */
    function claimedRewardsPerAccount(address _account) external view returns (uint256);

    /// @notice Sends out the reward in ALBT accumulated by the caller
    function claim() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IFeeExternal {
    /// @notice An event emitted once the external fee is modified
    event ExternalFeeSet(address account, uint256 newExternalFee);
    /// @notice An event emitted once a the external fee account is modified
    event ExternalFeeAddressSet(address account, address newExternalFeeAddress);

    /**
     *  @notice Construct a new FeeExternal contract
     *  @param _externalFee The initial external fee in ALBT tokens (flat)
     */
    function initFeeExternal(uint256 _externalFee, address _externalFeeAddress) external;
    function externalFee() external view returns (uint256);
    function externalFeeAddress() external view returns (address);
    function setExternalFee(uint256 _externalFee, bytes[] calldata _signatures) external;
    function setExternalFeeAddress(address _externalFeeAddress, bytes[] calldata _signatures) external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibRouter.sol";

struct WrappedTokenParams {
    string name;
    string symbol;
    uint8 decimals;
}

interface IRouter {
    /// @notice An event emitted once a Lock transaction is executed
    event Lock(uint8 targetChain, address token, bytes receiver, uint256 amount, uint256 serviceFee);
    /// @notice An event emitted once a Burn transaction is executed
    event Burn(address token, uint256 amount, bytes receiver);
    /// @notice An event emitted once a BurnAndTransfer transaction is executed
    event BurnAndTransfer(uint8 targetChain, address token, uint256 amount, bytes receiver);
    /// @notice An event emitted once an Unlock transaction is executed
    event Unlock(address token, uint256 amount, address receiver);
    /// @notice An even emitted once a Mint transaction is executed
    event Mint(address token, uint256 amount, address receiver);
    /// @notice An event emitted once a new wrapped token is deployed by the contract
    event WrappedTokenDeployed(uint8 sourceChain, bytes nativeToken, address wrappedToken);
    /// @notice An event emitted when collecting fees
    event Fees(uint256 serviceFee, uint256 externalFee);

    function initRouter(uint8 _chainId, address _albtToken) external;
    function nativeToWrappedToken(uint8 _chainId, bytes memory _nativeToken) external view returns (address);
    function wrappedToNativeToken(address _wrappedToken) external view returns (LibRouter.NativeTokenWithChainId memory);
    function hashesUsed(uint8 _chainId, bytes32 _ethHash) external view returns (bool);
    function albtToken() external view returns (address);
    function lock(uint8 _targetChain, address _nativeToken, uint256 _amount, bytes memory _receiver) external;

    function lockWithPermit(
        uint8 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unlock(
        uint8 _sourceChain,
        bytes memory _transactionId,
        address _nativeToken,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures
    ) external;

    function burn(address _wrappedToken, uint256 _amount, bytes memory _receiver) external;

    function burnWithPermit(
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function burnAndTransfer(uint8 _targetChain, address _wrappedToken, uint256 _amount, bytes memory _receiver) external;

    function burnAndTransferWithPermit(
        uint8 _targetChain,
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function mint(
        uint8 _nativeChain,
        bytes memory _nativeToken,
        bytes memory _transactionId,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures,
        WrappedTokenParams memory _tokenParams
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IGovernance {
    /// @notice An event emitted once member is updated
    event MemberUpdated(address member, bool status);

    /**
     *  @notice Initializes the Governance facet with an initial set of members
     *  @param _members The initial set of members
     */
    function initGovernance(address[] memory _members) external;

    /**
     *  @notice Adds/removes a member account
     *  @param _account The account to be modified
     *  @param _status Whether the account will be set as member or not
     *  @param _signatures The signatures of the validators authorizing this member update
     */
    function updateMember(address _account, bool _status, bytes[] calldata _signatures) external;

    /// @return True/false depending on whether a given address is member or not
    function isMember(address _member) external view returns (bool);

    /// @return The count of members in the members set
    function membersCount() external view returns (uint256);

    /// @return The address of a member at a given index
    function memberAt(uint256 _index) external view returns (address);

    /// @return The current administrative nonce
    function administrativeNonce() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IUtility {
    enum TokenAction {Pause, Unpause}

    function pauseToken(address _tokenAddress, bytes[] calldata _signatures) external;
    function unpauseToken(address _tokenAddress, bytes[] calldata _signatures) external;

    function setWrappedToken(uint8 _nativeChainId, bytes memory _nativeToken, address _wrappedToken, bytes[] calldata _signatures) external;
    function unsetWrappedToken(address _wrappedToken, bytes[] calldata _signatures) external;

    event TokenPause(address _account, address _token);
    event TokenUnpause(address _account, address _token);
    event WrappedTokenSet(uint8 _nativeChainId, bytes _nativeToken, address _wrappedToken);
    event WrappedTokenUnset(address _wrappedToken);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

library LibRouter {
    bytes32 constant STORAGE_POSITION = keccak256("router.storage");

    /// @notice Struct containing information about a token's address and its native chain
    struct NativeTokenWithChainId {
        uint8 chainId;
        bytes token;
    }

    struct Storage {
        bool initialized;

        // Maps chainID => (nativeToken => wrappedToken)
        mapping(uint8 => mapping(bytes => address)) nativeToWrappedToken;

        // Maps wrapped tokens in the current chain to their native chain + token address
        mapping(address => NativeTokenWithChainId) wrappedToNativeToken;

        // Storage metadata for transfers. Maps sourceChain => (transactionId => metadata)
        mapping(uint8 => mapping(bytes32 => bool)) hashesUsed;

        // Address of the ALBT token in the current chain
        address albtToken;

        // The chainId of the current chain
        uint8 chainId;
    }

    function routerStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}