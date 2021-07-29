pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libs/IERC20.sol";
import "../libs/ERC20.sol";

// PreMyFriends
contract PreMyFriends is ERC20('PREMYFRIENDS', 'PREMYFRIENDS'), ReentrancyGuard {

    address public constant feeAddress = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;

    address public constant usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // 500k USDC
    uint256 public constant usdcPresaleSize = 5 * (10 ** 5) * (10 ** 6);
    uint256 public constant usdcPerAccountMaxBuy = 3 * (10 ** 3) * (10 ** 6);

    uint256 public preMyFriendsSaleINVPriceE35 = 3 * (10 ** 33);
    uint256 public preArcadiumSaleINVPriceE35 = 15 * (10 ** 33);

    uint256 public preMyFriendsMaximumSupply = ((10 ** 12) *
            usdcPresaleSize * preMyFriendsSaleINVPriceE35) / 1e35;
    uint256 public preArcadiumMaximumSupply = ((10 ** 12) *
            usdcPresaleSize * preArcadiumSaleINVPriceE35) / 1e35;

    uint256 public maxPreMyFriendsPurchase = ((10 ** 12) *
            usdcPerAccountMaxBuy * preMyFriendsSaleINVPriceE35) / 1e35;
    uint256 public maxPreArcadiumPurchase = ((10 ** 12) *
            usdcPerAccountMaxBuy * preArcadiumSaleINVPriceE35) / 1e35;

    // We use a counter to defend against people sending pre{MyFriends,Arcadium} back
    uint256 public preMyFriendsRemaining = preMyFriendsMaximumSupply;
    uint256 public preArcadiumRemaining = preArcadiumMaximumSupply;

    uint256 oneHourMatic = 1800;
    uint256 oneDayMatic = oneHourMatic * 24;
    uint256 twoDaysMatic = oneDayMatic * 2;

    uint256 public startBlock;
    uint256 public endBlock;

    mapping(address => uint256) public userPreMyFriendsTally;
    mapping(address => uint256) public userPreArcadiumTally;

    address public preArcadiumAddress;

    event prePurchased(address sender, uint256 usdcSpent, uint256 preMyFriendsReceived, uint256 preArcadiumReceived);
    event startBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event saleINVPricesE35Changed(uint256 newMyFriendsSaleINVPriceE35, uint256 newArcadiumSaleINVPriceE35);

    constructor(uint256 _startBlock, address _preArcadiumAddress) {
        require(block.number < _startBlock, "cannot set start block in the past!");
        require(_preArcadiumAddress != address(0), "_preArcadiumAddress cannot be the zero address");
        startBlock = _startBlock;
        endBlock   = _startBlock + twoDaysMatic;
        preArcadiumAddress = _preArcadiumAddress;
        _mint(feeAddress, uint256(80000 * (10 ** 18)));
    }

    function buyL2Presale(uint256 usdcToSpend) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preMyFriendsRemaining > 0 && preArcadiumRemaining > 0, "No more presale tokens remaining! Come back next time!");
        require(IERC20(address(this)).balanceOf(address(this)) > 0, "No more preMyFriends left! Come back next time!");
        require(IERC20(preArcadiumAddress).balanceOf(address(this)) > 0, "No more preMyFriends left! Come back next time!");
        require(usdcToSpend > 1e4, "not enough usdc provided");
        require(usdcToSpend <= 3e22, "too much usdc provided");

        require(userPreMyFriendsTally[msg.sender] < maxPreMyFriendsPurchase &&
            userPreArcadiumTally[msg.sender] < maxPreArcadiumPurchase, "user has already purchased too much of the presale!");

        // The difference between the presale tokens decimal precision and
        // usdc decimal precision is 12, so we multiply by 10^12.
        // USDC is a fixed constant address and has decimals=6
        // while our presale tokens have decimals 18, which we control.
        uint256 originalPreMyFriendsAmount = ((10 ** 12) *
            usdcToSpend * preMyFriendsSaleINVPriceE35) / 1e35;
        uint256 originalPreArcadiumAmount = ((10 ** 12) *
            usdcToSpend * preArcadiumSaleINVPriceE35) / 1e35;

        uint256 preMyFriendsPurchaseAmount = originalPreMyFriendsAmount;
        uint256 preArcadiumPurchaseAmount = originalPreArcadiumAmount;

        if (preMyFriendsPurchaseAmount > maxPreMyFriendsPurchase)
            preMyFriendsPurchaseAmount = maxPreMyFriendsPurchase;

        if (preArcadiumPurchaseAmount > maxPreArcadiumPurchase)
            preArcadiumPurchaseAmount = maxPreArcadiumPurchase;

        if ((userPreMyFriendsTally[msg.sender] + preMyFriendsPurchaseAmount) > maxPreMyFriendsPurchase)
            preMyFriendsPurchaseAmount = maxPreMyFriendsPurchase - userPreMyFriendsTally[msg.sender];

        if ((userPreArcadiumTally[msg.sender] + preArcadiumPurchaseAmount) > maxPreArcadiumPurchase)
            preArcadiumPurchaseAmount = maxPreArcadiumPurchase - userPreArcadiumTally[msg.sender];

        // if we dont have enough left, give them the rest.
        if (preMyFriendsRemaining < preMyFriendsPurchaseAmount)
            preMyFriendsPurchaseAmount = preMyFriendsRemaining;

        if (preArcadiumRemaining < preArcadiumPurchaseAmount)
            preArcadiumPurchaseAmount = preArcadiumRemaining;

        require(preMyFriendsPurchaseAmount > 0, "user cannot purchase 0 preMyFriends");
        require(preArcadiumPurchaseAmount > 0, "user cannot purchase 0 preArcadium");

        // shouldn't be possible to fail these asserts.
        assert(preMyFriendsPurchaseAmount <= preMyFriendsRemaining);
        assert(preMyFriendsPurchaseAmount <= IERC20(address(this)).balanceOf(address(this)));

        assert(preArcadiumPurchaseAmount <= preArcadiumRemaining);
        assert(preArcadiumPurchaseAmount <= IERC20(preArcadiumAddress).balanceOf(address(this)));

        require(IERC20(address(this)).transfer(msg.sender, preMyFriendsPurchaseAmount), "failed sending preMyFriends");
        require(IERC20(preArcadiumAddress).transfer(msg.sender, preArcadiumPurchaseAmount), "failed sending preMyFriends");

        preMyFriendsRemaining = preMyFriendsRemaining - preMyFriendsPurchaseAmount;
        userPreMyFriendsTally[msg.sender] = userPreMyFriendsTally[msg.sender] + preMyFriendsPurchaseAmount;

        preArcadiumRemaining = preArcadiumRemaining - preArcadiumPurchaseAmount;
        userPreArcadiumTally[msg.sender] = userPreArcadiumTally[msg.sender] + preArcadiumPurchaseAmount;

        uint256 usdcSpent = usdcToSpend;
        if (preMyFriendsPurchaseAmount < originalPreMyFriendsAmount) {
            // max PurchaseAmount = 6e20, max USDC 3e9
            // overfow check: 6e20 * 3e9 * 1e24 = 1.8e67 < type(uint256).max
            // Rounding errors by integer division, reduce magnitude of end result.
            // We accept any rounding error (tiny) as a reduction in PAYMENT, not refund.
            usdcSpent = ((preMyFriendsPurchaseAmount * usdcToSpend * 1e24) / originalPreMyFriendsAmount) / 1e24;
        }

        if (usdcSpent > 0)
            require(ERC20(usdcAddress).transferFrom(msg.sender, feeAddress, usdcSpent), "failed to send usdc to fee address");

        emit prePurchased(msg.sender, usdcSpent, preMyFriendsPurchaseAmount, preArcadiumPurchaseAmount);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + twoDaysMatic;

        emit startBlockChanged(_newStartBlock, endBlock);
    }

    function setSaleINVPriceE35(uint256 _newPreMyFriendsSaleINVPriceE35, uint256 _newPreArcadiumSaleINVPriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourMatic * 4), "cannot change price 4 hours before start block");
        require(_newPreMyFriendsSaleINVPriceE35 >= 3 * (10 ** 33), "new myfriends price is to high!");
        require(_newPreMyFriendsSaleINVPriceE35 <= 5 * (10 ** 33), "new myfriends price is too low!");

        require(_newPreArcadiumSaleINVPriceE35 >= 15 * (10 ** 33), "new arcadium price is to high!");
        require(_newPreArcadiumSaleINVPriceE35 <= 25 * (10 ** 33), "new arcadium price is too low!");

        preMyFriendsSaleINVPriceE35 = _newPreMyFriendsSaleINVPriceE35;
        preArcadiumSaleINVPriceE35 = _newPreArcadiumSaleINVPriceE35;


        preMyFriendsMaximumSupply = ((10 ** 12) *
            usdcPresaleSize * preMyFriendsSaleINVPriceE35) / 1e35;
        preArcadiumMaximumSupply = ((10 ** 12) *
            usdcPresaleSize * preArcadiumSaleINVPriceE35) / 1e35;

        preMyFriendsRemaining = preMyFriendsMaximumSupply;
        preArcadiumRemaining = preArcadiumMaximumSupply;

        maxPreMyFriendsPurchase = ((10 ** 12) *
            usdcPerAccountMaxBuy * preMyFriendsSaleINVPriceE35) / 1e35;
        maxPreArcadiumPurchase = ((10 ** 12) *
            usdcPerAccountMaxBuy * preArcadiumSaleINVPriceE35) / 1e35;

        emit saleINVPricesE35Changed(preMyFriendsSaleINVPriceE35, preArcadiumSaleINVPriceE35);
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

import "./IERC20.sol";
import "./IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
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

import "./IERC20.sol";

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
        return msg.data;
    }
}