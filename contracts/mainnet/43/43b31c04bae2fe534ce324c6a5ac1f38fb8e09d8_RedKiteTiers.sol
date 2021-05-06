/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File contracts/libraries/Ownable.sol

pragma solidity ^0.7.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


// File contracts/libraries/ReentrancyGuard.sol


pragma solidity >=0.6.0 <0.8.0;

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

    constructor () {
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


// File contracts/token/utils/Context.sol


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


// File contracts/token/ERC20/IERC20.sol


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


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.7.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/token/ERC20/ERC20.sol


pragma solidity >=0.6.0 <0.8.0;



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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = 1000000e18;
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


// File contracts/token/ERC721/IERC165.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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


// File contracts/token/ERC721/IERC721.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File contracts/token/ERC721/IERC721Receiver.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File contracts/tier/RedKiteTiers.sol

pragma solidity ^0.7.0;





contract RedKiteTiers is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user
    struct UserInfo {
        uint256 staked; // How many tokens the user has provided
        uint256 stakedTime; // Block timestamp when the user provided token
    }

    // RedKiteTiers allow to stake multi tokens to up your tier. Please
    // visit the website to get token list or use the token contract to
    // check it is supported or not.

    // Info of each Token
    // Currency Rate with PKF: amount * rate / 10 ** decimals
    // Default PKF: rate=1, decimals=0
    struct ExternalToken {
        address contractAddress;
        uint256 decimals;
        uint256 rate;
        bool isERC721;
        bool canStake;
    }

    uint256 constant MAX_NUM_TIERS = 10;
    uint8 currentMaxTier = 4;

    // Address take user's withdraw fee
    address public penaltyWallet;
    // The POLKAFOUNDRY TOKEN!
    address public PKF;

    // Info of each user that stakes tokens
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // Info of total Non-PKF token staked, converted with rate
    mapping(address => uint256) public userExternalStaked;
    // Minimum PKF need to stake each tier
    uint256[MAX_NUM_TIERS] tierPrice;
    // Percentage of penalties
    uint256[6] public withdrawFeePercent;
    // The maximum number of days of penalties
    uint256[5] public daysLockLevel;
    // Info of each token can stake
    mapping(address => ExternalToken) public externalToken;

    bool public canEmergencyWithdraw;

    event StakedERC20(address indexed user, address token, uint256 amount);
    event StakedSingleERC721(
        address indexed user,
        address token,
        uint128 tokenId
    );
    event StakedBatchERC721(
        address indexed user,
        address token,
        uint128[] tokenIds
    );
    event WithdrawnERC20(
        address indexed user,
        address token,
        uint256 indexed amount,
        uint256 fee,
        uint256 lastStakedTime
    );
    event WithdrawnSingleERC721(
        address indexed user,
        address token,
        uint128 tokenId,
        uint256 lastStakedTime
    );
    event WithdrawnBatchERC721(
        address indexed user,
        address token,
        uint128[] tokenIds,
        uint256 lastStakedTime
    );
    event EmergencyWithdrawnERC20(
        address indexed user,
        address token,
        uint256 amount,
        uint256 lastStakedTime
    );
    event EmergencyWithdrawnERC721(
        address indexed user,
        address token,
        uint128[] tokenIds,
        uint256 lastStakedTime
    );
    event AddExternalToken(
        address indexed token,
        uint256 decimals,
        uint256 rate,
        bool isERC721,
        bool canStake
    );
    event ExternalTokenStatsChange(
        address indexed token,
        uint256 decimals,
        uint256 rate,
        bool canStake
    );
    event ChangePenaltyWallet(address indexed penaltyWallet);

    constructor(address _pkf, address _sPkf, address _uniLp, address _penaltyWallet) {
        owner = msg.sender;
        penaltyWallet = _penaltyWallet;

        PKF = _pkf;

        addExternalToken(_pkf, 0, 1 , false, true);
        addExternalToken(_sPkf, 0, 1, false, true);
        addExternalToken(_uniLp, 0, 150, false, true);

        tierPrice[1] = 500e18;
        tierPrice[2] = 5000e18;
        tierPrice[3] = 20000e18;
        tierPrice[4] = 60000e18;

        daysLockLevel[0] = 10 days;
        daysLockLevel[1] = 20 days;
        daysLockLevel[2] = 30 days;
        daysLockLevel[3] = 60 days;
        daysLockLevel[4] = 90 days;
    }

    function depositERC20(address _token, uint256 _amount)
        external
        nonReentrant()
    {
        if (_token == PKF) {
            IERC20(PKF).transferFrom(msg.sender, address(this), _amount);
        } else {
            require(
                externalToken[_token].canStake == true,
                "TIER::TOKEN_NOT_ACCEPTED"
            );
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);

            ExternalToken storage token = externalToken[_token];
            userExternalStaked[msg.sender] = userExternalStaked[msg.sender].add(
                _amount.mul(token.rate).div(10**token.decimals)
            );
        }

        userInfo[msg.sender][_token].staked = userInfo[msg.sender][_token]
            .staked
            .add(_amount);
        userInfo[msg.sender][_token].stakedTime = block.timestamp;

        emit StakedERC20(msg.sender, _token, _amount);
    }

    function depositSingleERC721(address _token, uint128 _tokenId)
        external
        nonReentrant()
    {
        require(
            externalToken[_token].canStake == true,
            "TIER::TOKEN_NOT_ACCEPTED"
        );
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].add(
            token.rate
        );

        userInfo[msg.sender][_token].staked = userInfo[msg.sender][_token]
            .staked
            .add(1);
        userInfo[msg.sender][_token].stakedTime = block.timestamp;

        emit StakedSingleERC721(msg.sender, _token, _tokenId);
    }

    function depositBatchERC721(address _token, uint128[] memory _tokenIds)
        external
        nonReentrant()
    {
        require(
            externalToken[_token].canStake == true,
            "TIER::TOKEN_NOT_ACCEPTED"
        );
        _batchSafeTransferFrom(_token, msg.sender, address(this), _tokenIds);

        uint256 amount = _tokenIds.length;
        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].add(
            amount.mul(token.rate)
        );

        userInfo[msg.sender][_token].staked = userInfo[msg.sender][_token]
            .staked
            .add(amount);
        userInfo[msg.sender][_token].stakedTime = block.timestamp;

        emit StakedBatchERC721(msg.sender, _token, _tokenIds);
    }

    function withdrawERC20(address _token, uint256 _amount)
        external
        nonReentrant()
    {
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked >= _amount, "not enough amount to withdraw");

        if (_token != PKF) {
            ExternalToken storage token = externalToken[_token];
            userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
                _amount.mul(token.rate).div(10**token.decimals)
            );
        }

        uint256 toPunish = calculateWithdrawFee(msg.sender, _token, _amount);
        if (toPunish > 0) {
            IERC20(_token).transfer(penaltyWallet, toPunish);
        }

        user.staked = user.staked.sub(_amount);

        IERC20(_token).transfer(msg.sender, _amount.sub(toPunish));
        emit WithdrawnERC20(
            msg.sender,
            _token,
            _amount,
            toPunish,
            user.stakedTime
        );
    }

    function withdrawSingleERC721(address _token, uint128 _tokenId)
        external
        nonReentrant()
    {
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked >= 1, "not enough amount to withdraw");

        user.staked = user.staked.sub(1);

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            token.rate
        );

        IERC721(_token).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit WithdrawnSingleERC721(
            msg.sender,
            _token,
            _tokenId,
            user.stakedTime
        );
    }

    function withdrawBatchERC721(address _token, uint128[] memory _tokenIds)
        external
        nonReentrant()
    {
        UserInfo storage user = userInfo[msg.sender][_token];
        uint256 amount = _tokenIds.length;
        require(user.staked >= amount, "not enough amount to withdraw");

        user.staked = user.staked.sub(amount);

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            amount.mul(token.rate)
        );

        _batchSafeTransferFrom(_token, address(this), msg.sender, _tokenIds);
        emit WithdrawnBatchERC721(
            msg.sender,
            _token,
            _tokenIds,
            user.stakedTime
        );
    }

    function setPenaltyWallet(address _penaltyWallet) external onlyOwner {
        require(
            penaltyWallet != _penaltyWallet,
            "TIER::ALREADY_PENALTY_WALLET"
        );
        penaltyWallet = _penaltyWallet;

        emit ChangePenaltyWallet(_penaltyWallet);
    }

    function updateEmergencyWithdrawStatus(bool _status) external onlyOwner {
        canEmergencyWithdraw = _status;
    }

    function emergencyWithdrawERC20(address _token) external {
        require(canEmergencyWithdraw, "function disabled");
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked > 0, "nothing to withdraw");

        uint256 _amount = user.staked;
        user.staked = 0;

        if (_token != PKF) {
          ExternalToken storage token = externalToken[_token];
          userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
              _amount.mul(token.rate).div(10**token.decimals)
          );
        }

        IERC20(_token).transfer(msg.sender, _amount);
        emit EmergencyWithdrawnERC20(
            msg.sender,
            _token,
            _amount,
            user.stakedTime
        );
    }

    function emergencyWithdrawERC721(address _token, uint128[] memory _tokenIds)
        external
    {
        require(canEmergencyWithdraw, "function disabled");
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked > 0, "nothing to withdraw");

        uint256 _amount = user.staked;
        user.staked = 0;

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            _amount.mul(token.rate).div(10**token.decimals)
        );

        if (_amount == 1) {
            IERC721(_token).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[0]
            );
        } else {
            _batchSafeTransferFrom(
                _token,
                address(this),
                msg.sender,
                _tokenIds
            );
        }
        emit EmergencyWithdrawnERC721(
            msg.sender,
            _token,
            _tokenIds,
            user.stakedTime
        );
    }

    function addExternalToken(
        address _token,
        uint256 _decimals,
        uint256 _rate,
        bool _isERC721,
        bool _canStake
    ) public onlyOwner {
        ExternalToken storage token = externalToken[_token];

        require(_rate > 0, "TIER::INVALID_TOKEN_RATE");

        token.contractAddress = _token;
        token.decimals = _decimals;
        token.rate = _rate;
        token.isERC721 = _isERC721;
        token.canStake = _canStake;

        emit AddExternalToken(_token, _decimals, _rate, _isERC721, _canStake);
    }

    function setExternalToken(
        address _token,
        uint256 _decimals,
        uint256 _rate,
        bool _canStake
    ) external onlyOwner {
        ExternalToken storage token = externalToken[_token];

        require(token.contractAddress == _token, "TIER::TOKEN_NOT_EXISTS");
        require(_rate > 0, "TIER::INVALID_TOKEN_RATE");

        token.decimals = _decimals;
        token.rate = _rate;
        token.canStake = _canStake;

        emit ExternalTokenStatsChange(_token, _decimals, _rate, _canStake);
    }

    function updateTier(uint8 _tierId, uint256 _amount) external onlyOwner {
        require(_tierId > 0 && _tierId <= MAX_NUM_TIERS, "invalid _tierId");
        tierPrice[_tierId] = _amount;
        if (_tierId > currentMaxTier) {
            currentMaxTier = _tierId;
        }
    }

    function updateWithdrawFee(uint256 _key, uint256 _percent)
        external
        onlyOwner
    {
        require(_percent < 100, "too high percent");
        withdrawFeePercent[_key] = _percent;
    }

    function updatePunishTime(uint256 _key, uint256 _days) external onlyOwner {
        require(_days >= 0, "too short time");
        daysLockLevel[_key] = _days * 1 days;
    }

    function getUserTier(address _userAddress)
        external
        view
        returns (uint8 res)
    {
        uint256 totalStaked =
            userInfo[_userAddress][PKF].staked.add(
                userExternalStaked[_userAddress]
            );

        for (uint8 i = 1; i <= MAX_NUM_TIERS; i++) {
            if (tierPrice[i] == 0 || totalStaked < tierPrice[i]) {
                return res;
            }

            res = i;
        }
    }

    function calculateWithdrawFee(
        address _userAddress,
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress][_token];
        require(user.staked >= _amount, "not enough amount to withdraw");

        if (block.timestamp < user.stakedTime.add(daysLockLevel[0])) {
            return _amount.mul(withdrawFeePercent[0]).div(100); //30%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[1])) {
            return _amount.mul(withdrawFeePercent[1]).div(100); //25%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[2])) {
            return _amount.mul(withdrawFeePercent[2]).div(100); //20%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[3])) {
            return _amount.mul(withdrawFeePercent[3]).div(100); //10%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[4])) {
            return _amount.mul(withdrawFeePercent[4]).div(100); //5%
        }

        return _amount.mul(withdrawFeePercent[5]).div(100);
    }

    //frontend func
    function getTiers()
        external
        view
        returns (uint256[MAX_NUM_TIERS] memory buf)
    {
        for (uint8 i = 1; i < MAX_NUM_TIERS; i++) {
            if (tierPrice[i] == 0) {
                return buf;
            }
            buf[i - 1] = tierPrice[i];
        }

        return buf;
    }

    function userTotalStaked(address _userAddress) external view returns (uint256) {
        return
            userInfo[_userAddress][PKF].staked.add(
                userExternalStaked[_userAddress]
            );
    }

    function _batchSafeTransferFrom(
        address _token,
        address _from,
        address _recepient,
        uint128[] memory _tokenIds
    ) internal {
        for (uint256 i = 0; i != _tokenIds.length; i++) {
            IERC721(_token).safeTransferFrom(_from, _recepient, _tokenIds[i]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}