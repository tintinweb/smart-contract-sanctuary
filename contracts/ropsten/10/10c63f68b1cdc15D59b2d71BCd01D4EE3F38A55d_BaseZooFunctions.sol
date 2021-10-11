pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./interfaces/IZooFunctions.sol";
import "./NftBattleArena.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract BaseZooFunctions.
/// @notice Contracts for base implementation of some ZooDao functions.
contract BaseZooFunctions is IZooFunctions, Ownable
{
	using SafeMath for uint256;

	NftBattleArena public nftbattlearena;

	constructor () {}

	/// @notice Function for setting address of NftbattleArena contract.
	/// @param nftBattleArena - address of nftBattleArena contract.
	function init(address nftBattleArena) external onlyOwner {

		nftbattlearena = NftBattleArena(nftBattleArena);

		renounceOwnership();
	}

	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint votesForA, uint votesForB, uint random) override external pure returns (bool)
	{
		uint mod = random % (votesForA + votesForB);
		return mod < votesForA;
	}

	/// @notice Function for generating random number.
	/// @param seed - multiplier for random number.
	/// @return random - generated random number.
	function getRandomNumber(uint256 seed) override external view returns (uint random) {

		random = uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)) + seed))); // Get random number.
	}

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint amount) override external view returns (uint votes)
	{
		if (block.timestamp < nftbattlearena.epochStartDate().add(nftbattlearena.firstStageDuration().add(30 minutes)))//2 days))) todo: change time
		{
			votes = amount.mul(13).div(10);                                          // 1.3 multiplier for votes.
		}
		else if (block.timestamp < nftbattlearena.epochStartDate().add(nftbattlearena.firstStageDuration().add(30 minutes)))//5 days)))
		{
			votes = amount;                                                          // 1.0 multiplier for votes.
		}
		else
		{
			votes = amount.mul(7).div(10);                                           // 0.7 multiplier for votes.
		}
	}

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint amount) override external view returns (uint votes)
	{
		if (block.timestamp < nftbattlearena.epochStartDate().add(nftbattlearena.firstStageDuration().add(nftbattlearena.secondStageDuration().add(30 minutes))))//2 days))))
		{
			votes = amount.mul(13).div(10);                                         // 1.3 multiplier for votes.
		}
		else if (block.timestamp < nftbattlearena.epochStartDate().add(nftbattlearena.firstStageDuration().add(nftbattlearena.secondStageDuration().add(30 minutes))))//4 days))))
		{
			votes = amount;                                                         // 1.0 multiplier for votes.
		}
		else
		{
			votes = amount.mul(7).div(10);                                          // 0.7 multiplier for votes.
		}
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

import "../../utils/Context.sol";
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
pragma solidity ^0.7.0;

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
    * - Subtraction cannot overflow.
    */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {
	
	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint votesForA, uint votesForB, uint random) external view returns (bool);

	/// @notice Function for generating random number.
	/// @param seed - multiplier for random number.
	/// @return random - generated random number.
	function getRandomNumber(uint256 seed) external view returns (uint random);

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint amount) external view returns (uint);

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint amount) external view returns (uint);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface VaultAPI {
    function deposit(uint256 amount) external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function pricePerShare() external view returns (uint256);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./interfaces/IZooFunctions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	using SafeMath for uint;

	address public zooFunctions;                    // Address of contract with Zoo functions.
	IERC20 public zooToken;

	/// @notice Contract constructor.
	/// @param baseZooFunctions - address of baseZooFunctions contract.
	/// @param aragon - address of aragon zoo dao agent.
	constructor(address baseZooFunctions, address aragon) {

		zooFunctions = baseZooFunctions;

		transferOwnership(aragon);            // Sets owner to aragon.
	}

    /// @notice Function for vote for changing Zoo fuctions.
	/// @param newZooFunctions - address of new zoo functions contract.
	function changeZooFunctionsContract(address newZooFunctions) external onlyOwner
	{
		zooFunctions = newZooFunctions;
	}
   
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IZooFunctions.sol";
import "./ZooGovernance.sol";

/// @title NftBattleArena contract.
/// @notice Contract for staking ZOO-Nft for participate in battle votes.
contract NftBattleArena is Ownable
{
	using SafeMath for uint256;
	
	ERC20 public zoo;                      // Zoo token interface.
	ERC20 public dai;                      // DAI token interface
	VaultAPI public vault;                 // Yearn interface.
	ZooGovernance public zooGovernance;    // zooGovernance contract.
	IZooFunctions public zooFunctions;     // zooFunctions contract.

	/// @notice Struct for stages of vote battle.
	enum Stage
	{
		FirstStage,
		SecondStage,
		ThirdStage,
		FourthStage
	}

	/// @notice Struct for vote records.
	struct VoteRecord
	{
		uint256 daiInvested;           // Amount of DAI invested.
		uint256 yTokensNumber;         // amount of yTokens.
		uint256 zooInvested;           // Amount of Zoo invested.
		uint256 votes;                 // Amount of votes.
		bool daiHaveWithdrawed;        // Returns true if Dai were withdrawed.
		bool zooHaveWithdrawed;        // Returns true if Zoo were withdrawed.
	}

	/// @notice Struct for records about staked Nfts.
	struct NftRecord
	{
		address token;                 // Address of Nft contract.
		uint256 id;                    // Id of Nft.
		uint256 votes;                 // Amount of votes for this Nft.
	}

	// Struct for records about pairs of Nfts for battle.
	struct NftPair
	{
		address token1;                // Address of Nft contract of 1st Nft candidate.
		uint256 id1;                   // Id of 1st Nft candidate.
		address token2;                // Address of Nft contract of 2nd Nft candidate.
		uint256 id2;                   // Id of 2nd Nft candidate.
		bool win;                      // Boolean where true is when 1st candidate wins, and false for 2nd.
	}

	/// @notice Event records address of allowed nft contract.
	/// @param token - address of contract.
	event newContractAllowed (address token);

	/// @notice Event records info about staked nft in this pool.
	/// @param staker - address of nft staker.
	/// @param token - address of nft contract.
	/// @param id - id of staked nft.
	event StakedNft(address indexed staker, address indexed token, uint256 indexed id);

	/// @notice Event records info about withdrawed nft from this pool.
	/// @param staker - address of nft staker.
	/// @param token - address of nft contract.
	/// @param id - id of staked nft.
	event WithdrawedNft(address staker, address indexed token, uint256 indexed id);

	/// @notice Event records info about vote using Dai.
	/// @param voter - address voter.
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param amount - amount of votes.
	event VotedWithDai(address voter, address indexed token, uint256 indexed id, uint256 amount);

	/// @notice Event records info about vote using Zoo.
	/// @param voter - address voter.
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param amount - amount of votes.
	event VotedWithZoo(address voter, address indexed token, uint256 indexed id, uint256 amount);

	/// @notice Event records info about reVote again using Zoo.
	/// @param epoch - epoch number
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param votes - amount of votes.
	event ReVotedWithZoo(uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 votes);

	/// @notice Event records info about reVote again using Dai
	/// @param epoch - epoch number
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param votes - amount of votes.
	event ReVotedWithDai(uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 votes);

	/// @notice Event records info about claimed reward for staker.
	/// @param staker -address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	/// @param income - amount of reward.
	event StakerRewardClaimed(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 income);

	/// @notice Event records info about claimed reward for voter.
	/// @param staker - address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	/// @param income - amount of reward.
	event VoterRewardClaimed(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 income);

	/// @notice Event records info about withdrawed dai from votes.
	/// @param staker - address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	event WithdrawedDai(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id);

	/// @notice Event records info about withdrawed Zoo from votes.
	/// @param staker - address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	event WithdrawedZoo(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id);

	/// @notice Event records info about nft paired for vote battle.
	/// @param date - date of function call.
	/// @param participants - amount of participants for vote battles.
	event NftPaired(uint256 currentEpoch, uint256 date, uint256 participants);

	/// @notice Event records info about winners in battles.
	/// @param currentEpoch - number of currentEpoch.
	/// @param i - index of battle.
	/// @param random - random number get for calculating winner.
	event Winner(uint256 currentEpoch, uint256 i, uint256 random);

	uint256 public epochStartDate;                 // Start date of battle contract.
	uint256 public currentEpoch = 0;               // Counter for battle epochs.

	uint256 public firstStageDuration = 30 minutes;		//todo:change time //3 days;    // Duration of first stage.
	uint256 public secondStageDuration = 30 minutes;		//todo:change time//7 days;   // Duration of second stage.
	uint256 public thirdStageDuration = 30 minutes;		//todo:change time//5 days;    // Duration third stage.
	uint256 public fourthStage = 30 minutes;		//todo:change time//2 days;           // Duration of fourth stage.
	uint256 public epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStage; // Total duration of battle epoch.

	// Epoch => address of NFT => id => VoteRecord
	mapping (uint256 => mapping(address => mapping(uint256 => VoteRecord))) public votesForNftInEpoch;

	// Epoch => address of NFT => id => investor => VoteRecord
	mapping (uint256 => mapping(address => mapping(uint256 => mapping(address => VoteRecord)))) public investedInVoting;

	// Epoch => address of NFT => id => voter => is voter rewarded?
	mapping (uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public isVoterRewarded;

	// Epoch => address of NFT => id => incomeFromInvestment
	mapping (uint256 => mapping(address => mapping(uint256 => uint256))) public incomeFromInvestments;

	// Epoch => address of NFT => id => is staker rewarded?
	mapping (uint256 => mapping(address => mapping(uint256 => bool))) public isStakerRewared;

	// Epoch => dai deposited in epoch.
	mapping (uint256 => uint256) public daiInEpochDeposited;

	// Nft contract => allowed or not.
	mapping (address => bool) public allowedForStaking;                     // Records NFT contracts available for staking.

	// nft contract => nft id => address staker.
	mapping (address => mapping (uint256 => address)) public tokenStakedBy; // Records that nft staked or not.

	// epoch number => amount of nfts.
	mapping (uint256 => NftRecord[]) public nftsInEpoch;                    // Records amount of nft in battle epoch.

	// epoch number => amount of pairs of nfts.
	mapping (uint256 => NftPair[]) public pairsInEpoch;                     // Records amount of pairs in battle epoch.

	/// @notice Contract constructor.
	/// @param _zoo - address of Zoo token contract.
	/// @param _dai - address of DAI token contract.
	/// @param _vault - address of yearn
	/// @param _zooGovernance - address of ZooDao Governance contract.
	constructor (address _zoo, address _dai, address _vault, address _zooGovernance) Ownable()
	{
		zoo = ERC20(_zoo);
		dai = ERC20(_dai);
		vault = VaultAPI(_vault);
		zooGovernance = ZooGovernance(_zooGovernance);

		epochStartDate = block.timestamp;//todo:change time for prod +  14 days;                              // Start date of 1st battle.
	}

	/// @notice Function for updating functions according last governance resolutions.
	function updateZooFunctions() external onlyOwner
	{
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!"); // Requires to be at first stage in battle epoch.

		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());              // Sets ZooFunctions to contract specified in zooGovernance.
	}

	/// @notice Function to allow new NFT contract available for stacking.
	/// @param token - address of new Nft contract.
	function allowNewContractForStaking(address token) external onlyOwner
	{
		allowedForStaking[token] = true;                                         // Boolean for contract to be allowed for staking.

		emit newContractAllowed(token);
	}

	/// @notice Function for staking NFT in this pool.
	/// @param token - address of Nft token to stake
	/// @param id - id of nft token
	function stakeNft(address token, uint256 id) public
	{
		require(allowedForStaking[token] = true, "Nft not allowed!");             // Requires for nft-token to be from allowed contract.
		require(tokenStakedBy[token][id] == address(0), "Already staked!");       // Requires for token to be non-staked before.
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!");  // Requires to be at first stage in battle epoch.

		IERC721(token).transferFrom(msg.sender, address(this), id);               // Sends NFT token to this contract.

		tokenStakedBy[token][id] = msg.sender;                                    // Records that token now staked.

		emit StakedNft(msg.sender, token, id);                                    // Emits StakedNft event.
	}

	/// @notice Function for withdrawal Nft token back to owner.
	/// @param token - address of Nft token to unstake.
	/// @param id - id of nft token.
	function withdrawNft(address token, uint256 id) public
	{
		require(tokenStakedBy[token][id] == msg.sender, "Must be staked by you!");// Requires for token to be staked in this contract.
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!");  // Requires to be at first stage in battle epoch.

		IERC721(token).transferFrom(address(this), msg.sender, id);               // Transfers token back to owner.

		tokenStakedBy[token][id] = address(0);                                    // Records that token is unstaked.

		emit WithdrawedNft(msg.sender, token, id);                                // Emits withdrawedNft event.
	}

	/// @notice Function for voting with DAI in battle epoch.
	/// @param token - address of Nft token voting for.
	/// @param id - id of voter.
	/// @param amount - amount of votes in DAI.
	/// @return votes - calculated amount of votes from dai for nft.
	function voteWithDai(address token, uint256 id, uint256 amount) public returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.SecondStage, "Must be at 2nd stage!");   // Requires to be at second stage of battle epoch.
		require(tokenStakedBy[token][id] != address(0), "Must be staked!");
		dai.transferFrom(msg.sender, address(this), amount);                        // Transfers DAI to this contract for vote.

		votes = zooFunctions.computeVotesByDai(amount);                             // Calculates amount of votes.

		dai.approve(address(vault), amount);                                        // Approves Dai for address of yearn vault for amount
		uint256 yTokensNumber = vault.deposit(amount);                              // deposits to yearn vault and record yTokens.

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;                 // Adds amount of votes for this epoch, contract and id.
		votesForNftInEpoch[currentEpoch][token][id].daiInvested += amount;          // Adds amount of Dai invested for this epoch, contract and id.
		votesForNftInEpoch[currentEpoch][token][id].yTokensNumber += yTokensNumber; // Adds amount of yTokens invested for this epoch, contract and id.

		investedInVoting[currentEpoch][token][id][msg.sender].daiInvested += amount;// Adds amount of Dai invested for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][msg.sender].votes += votes;       // Adds amount of votes for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][msg.sender].yTokensNumber += yTokensNumber;// Adds amount of yToken invested for this epoch, contract and id for msg.sender.

		uint256 length = nftsInEpoch[currentEpoch].length;                          // Sets amount of Nfts in current epoch.

		daiInEpochDeposited[currentEpoch] += amount;                                // Adds amount of Dai deposited in current epoch.

		emit VotedWithDai(msg.sender, token, id, amount);                           // Records in VotedWithDai event.

		uint256 i;
		for (i = 0; i < length; i++)
		{
			if (nftsInEpoch[currentEpoch][i].token == token && nftsInEpoch[currentEpoch][i].id == id)
			{
				nftsInEpoch[currentEpoch][i].votes += votes;
				break;
			}
		}

		if (i == length)
		{
			nftsInEpoch[currentEpoch].push(NftRecord(token, id, votes));
		}

		return votes;
	}

	/// @notice Function for making battle pairs.
	/// @return success - returns true for success.
	function truncateAndPair() public returns (bool success)
	{
		require(getCurrentStage() == Stage.ThirdStage, "Must be at 3rd stage!");          // Requires to be at 3rd stage of battle epoch.
		require(nftsInEpoch[currentEpoch].length != 0, "Already paired!");

		emit NftPaired(currentEpoch, block.timestamp, nftsInEpoch[currentEpoch].length);

		if (nftsInEpoch[currentEpoch].length % 2 == 1)                                    // If number of nft participants is odd.
		{
			uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))); // Generate random number.
			uint256 index = random % nftsInEpoch[currentEpoch].length;                    // Pick random participant.
			uint256 length = nftsInEpoch[currentEpoch].length;                            // Get list of participants.
			nftsInEpoch[currentEpoch][index] = nftsInEpoch[currentEpoch][length - 1];     // Truncate list.
			nftsInEpoch[currentEpoch].pop();                                              // Remove random unused participant from list.
		}

		uint256 i = 1;

		while (nftsInEpoch[currentEpoch].length != 0)                                     // Get pairs of nft until where are zero left in list.
		{
			uint256 length = nftsInEpoch[currentEpoch].length;                            // Get list.

			uint256 random1 = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - 1)) + i++))) % length; // Generate random number.
			uint256 random2 = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - 1)) + i++))) % length; // Generate 2nd random number.

			address token1 = nftsInEpoch[currentEpoch][random1].token; // Pick random nft contract address.
			uint256 id1 = nftsInEpoch[currentEpoch][random1].id;       // Pick random nft id.

			address token2 = nftsInEpoch[currentEpoch][random2].token; // Pick random nft contract address.
			uint256 id2 = nftsInEpoch[currentEpoch][random2].id;       // Pick random nft id.

			pairsInEpoch[currentEpoch].push(NftPair(token1, id1, token2, id2, false));  // Push pair.

			nftsInEpoch[currentEpoch][random1] = nftsInEpoch[currentEpoch][length - 1];
			nftsInEpoch[currentEpoch][random2] = nftsInEpoch[currentEpoch][length - 2];

			nftsInEpoch[currentEpoch].pop();                           // Remove from array.
			nftsInEpoch[currentEpoch].pop();                           // Remove from array.
		}
		return true;
	}

	/// @notice Function for boost\multiply votes with Zoo.
	/// @param token - address of nft.
	/// @param id - id of voter.
	/// @param amount - amount of Zoo.
	/// @return votes - amount of votes.
	function voteWithZoo(address token, uint256 id, uint256 amount) public returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.ThirdStage, "Must be at 3rd stage!");      // Requires to be at 3rd stage.
		//todo:add require for staked before this.
		zoo.transferFrom(msg.sender, address(this), amount);                          // Transfers Zoo from sender to this contract.

		votes = zooFunctions.computeVotesByZoo(amount);                               // Calculates amount of votes.

		require(votes <= investedInVoting[currentEpoch][token][id][msg.sender].votes, "votes amount more than invested!"); // Reverts if votes more than tokens invested.

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;                  // Adds votes for this epoch, token and id.
		votesForNftInEpoch[currentEpoch][token][id].zooInvested += amount;           // Adds amount of Zoo for this epoch, token and id.

		investedInVoting[currentEpoch][token][id][msg.sender].votes += votes;        // Adds votes for this epoch, token and id for msg.sender.
		investedInVoting[currentEpoch][token][id][msg.sender].zooInvested += amount; // Adds amount of Zoo for this epoch, token and id for msg.sender.
		
		emit VotedWithZoo(msg.sender, token, id, amount);                            // Records in VotedWithZoo event.

		return votes;
	}

	/// @notice Function for chosing winner.
	/// @dev should be changed for chainlink VRF. TODO:
	function chooseWinners() public
	{
		require(getCurrentStage() == Stage.FourthStage, "Must be at 4th stage!");    // Requires to be at 4th stage.

		for (uint256 i = 0; i < pairsInEpoch[currentEpoch].length; i++)
		{
			uint256 random = zooFunctions.getRandomNumber(i);                        // Get random number.

			address token1 = pairsInEpoch[currentEpoch][i].token1;                   // Address of 1st candidate.
			uint256 id1 = pairsInEpoch[currentEpoch][i].id1;                         // Id of 1st candidate.
			uint256 votesForA = votesForNftInEpoch[currentEpoch][token1][id1].votes; // Votes for 1st candidate.
			
			address token2 = pairsInEpoch[currentEpoch][i].token2;                   // Address of 2nd candidate.
			uint256 id2 = pairsInEpoch[currentEpoch][i].id2;                         // Id of 2nd candidate.
			uint256 votesForB = votesForNftInEpoch[currentEpoch][token2][id2].votes; // Votes for 2nd candidate.

			pairsInEpoch[currentEpoch][i].win = zooFunctions.decideWins(votesForA, votesForB, random); // Calculates winner and records it.

			uint256 undeposited1 = vault.withdraw(_sharesToTokens(votesForNftInEpoch[currentEpoch][token1][id1].yTokensNumber)); // Withdraws tokens from yearn vault for 1st candidate.
			uint256 undeposited2 = vault.withdraw(_sharesToTokens(votesForNftInEpoch[currentEpoch][token2][id2].yTokensNumber)); // Withdraws tokens from yearn vault for 2nd candidate.

			uint256 income = (undeposited1.add(undeposited2)).sub(votesForNftInEpoch[currentEpoch][token1][id1].daiInvested).sub(votesForNftInEpoch[currentEpoch][token2][id2].daiInvested); // Calculates income.

			if (pairsInEpoch[currentEpoch][i].win)                                // If 1st candidate wins.
			{
				incomeFromInvestments[currentEpoch][token1][id1] = income;        // Records income to 1st candidate.
			}
			else                                                                  // If 2nd candidate wins.
			{
				incomeFromInvestments[currentEpoch][token2][id2] = income;        // Records income to 2nd candidate.
			}
			emit Winner(currentEpoch, i, random);                                 // Records in Winner event.
		}

		epochStartDate += epochDuration;                                          // Increments epochStartDate for this epoch duration.
		currentEpoch++;                                                           // Increments currentEpoch.
	}

	/// @notice Function for claiming reward for Nft stakers.
	/// @param epoch - number of epoch.
	/// @param token - address of nft contract.
	/// @param id - Id of nft.
	function claimRewardForStakers(uint256 epoch, address token, uint256 id) public
	{
		require(tokenStakedBy[token][id] == msg.sender, "Must be staked by msg.sender!"); // Requires for token to be staked by msg.sender.
		require(!isStakerRewared[epoch][token][id], "Already rewarded!");           // Requires to be not rewarded before.

		uint256 income = incomeFromInvestments[epoch][token][id];                   // Gets income amount for this epoch, token and id.

		if (income != 0)
		{
			dai.transfer(msg.sender, income.mul(2).div(100));                       // Transfers Dai to msg.sender for 2% from income
		}

		isStakerRewared[epoch][token][id] = true;                                   // Records that staker was rewarded.

		emit StakerRewardClaimed(msg.sender, epoch, token, id, income);             // Records in StakerRewardClaimed event. 
	}

	/// @notice Function for claiming rewards for voter.
	/// @param epoch - number of epoch when voted.
	/// @param token - address of contract nft voted for.
	/// @param id - Id of nft voted for.
	function claimRewardForVoter(uint256 epoch, address token, uint256 id) public
	{
		require(!isVoterRewarded[epoch][token][id][msg.sender], "Already rewarded!");// Requires to be not rewarded before.

		uint256 votes = investedInVoting[epoch][token][id][msg.sender].votes;        // Gets amount of votes for this epoch, nft, id from msg.sender.
		uint256 income = incomeFromInvestments[epoch][token][id];                    // Gets income amount for this epoch, token and id.
		uint256 totalVotes = votesForNftInEpoch[epoch][token][id].votes;             // Gets amount of total votes for this nft in this epoch.

		if (income != 0)
			dai.transfer(msg.sender, (((income.mul(98)).mul(votes)).div(100)).div(totalVotes)); // Transfers reward.

		isVoterRewarded[epoch][token][id][msg.sender] = true;                        // Records what voter has been rewarded.

		emit VoterRewardClaimed(msg.sender, epoch, token, id, income);               // Records in VoterRewardClaimed event. 
	}
	
	/// @notice Function to view pending rewards for voter.
	/// @param epoch - epoch number.
	/// @param token - token address.
	/// @param id - id of token.
	/// @return pendingReward - pending reward from this battle.
	function getPendingVoterRewards(uint256 epoch, address token, uint256 id) public view returns(uint256 pendingReward) {
		uint256 votes = investedInVoting[epoch][token][id][msg.sender].votes;        // Gets amount of votes for this epoch, nft, id from msg.sender.
		uint256 income = incomeFromInvestments[epoch][token][id];                    // Gets income amount for this epoch, token and id.
		uint256 totalVotes = votesForNftInEpoch[epoch][token][id].votes;             // Gets amount of total votes for this nft in this epoch.
		pendingReward = (((income.mul(98)).mul(votes)).div(100)).div(totalVotes);
	}

	/// @notice Function to view pending rewards for staker.
	/// @param epoch - epoch number.
	/// @param token - token address.
	/// @param id - id of token.
	/// @return pendingReward - pending reward from this battle.
	function getPendingStakerReward(uint256 epoch, address token, uint256 id) public view returns(uint256 pendingReward) {
		uint256 income = incomeFromInvestments[epoch][token][id];                   // Gets income amount for this epoch, token and id.
		pendingReward = (income.mul(2)).div(100);
	}

	/// @notice Function for withdraw Dai from votes.
	/// @param epoch - epoch number.
	/// @param token - address of nft contract.
	/// @param id - id of nft.
	function withdrawDai(uint256 epoch, address token, uint256 id) public
	{
		require(epoch < currentEpoch, "Not in current epoch!");                               // Withdraw allowed from previous epochs.
		require(!investedInVoting[epoch][token][id][msg.sender].daiHaveWithdrawed, "Dai tokens were withdrawed!"); // Requires for tokens to be not withdrawed or reVoted yet.

		dai.transfer(msg.sender, investedInVoting[epoch][token][id][msg.sender].daiInvested); // Transfers dai.

		investedInVoting[epoch][token][id][msg.sender].daiHaveWithdrawed = true;              // Records that tokens were reVoted.

		emit WithdrawedDai(msg.sender, epoch, token, id);                                     // Records in WithdrawedDai event.
	}

	/// @notice Function for withdraw Zoo from votes.
	/// @param epoch - epoch number.
	/// @param token - address of nft contract.
	/// @param id - id of nft.
	function withdrawZoo(uint256 epoch, address token, uint256 id) public
	{
		require(epoch < currentEpoch, "Not in current epoch!");                  // Withdraw allowed from previous epochs.
		require(!investedInVoting[epoch][token][id][msg.sender].zooHaveWithdrawed,"Zoo tokens were withdrawed!");// Requires for tokens to be not withdrawed or reVoted yet.

		zoo.transfer(msg.sender, investedInVoting[epoch][token][id][msg.sender].zooInvested); // Transfers Zoo.

		investedInVoting[epoch][token][id][msg.sender].zooHaveWithdrawed = true; // Records that tokens were reVoted.

		emit WithdrawedZoo(msg.sender, epoch, token, id);                        // Records in WithdrawedZoo event.
	}

	/// @notice Function for repeat vote using Dai in next battle epoch.
	/// @param epoch - number of epoch vote was made.
	/// @param token - address of nft contract vote was made for.
	/// @param id - id of nft vote was made for.
	/// @param voter - address of votes owner.
	function reVoteInDai(uint256 epoch, address token, uint256 id, address voter) public
	{
		require(getCurrentStage() == Stage.SecondStage, "Must be at 2nd stage!");   // Requires to be at second stage of battle epoch.
		require(!investedInVoting[epoch - 1][token][id][voter].daiHaveWithdrawed, "dai tokens were withdrawed!"); // Requires for tokens to be not withdrawed or reVoted yet.

		uint256 amount = investedInVoting[epoch - 1][token][id][voter].daiInvested;
		require(amount != 0, "nothing to re-vote!");
		uint256 votes = zooFunctions.computeVotesByDai(amount);                     // Calculates amount of votes.

		dai.approve(address(vault), amount);                                        // Approves Dai for address of yearn vault for amount
		uint256 yTokensNumber = vault.deposit(amount);                              // Records number of Dai transfered to yearn vault.

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;                 // Adds amount of votes for this epoch, contract and id.
		votesForNftInEpoch[currentEpoch][token][id].daiInvested += amount;          // Adds amount of Dai invested for this epoch, contract and id.
		votesForNftInEpoch[currentEpoch][token][id].yTokensNumber += yTokensNumber; // Adds amount of yTokens invested for this epoch, contract and id.

		investedInVoting[currentEpoch][token][id][voter].daiInvested += amount;// Adds amount of Dai invested for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][voter].votes += votes;       // Adds amount of votes for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][voter].yTokensNumber += yTokensNumber;// Adds amount of yToken invested for this epoch, contract and id for msg.sender.

		uint256 length = nftsInEpoch[currentEpoch].length;                          // Sets amount of Nfts in current epoch.

		daiInEpochDeposited[currentEpoch] += amount;                                // Adds amount of Dai deposited in current epoch.

		uint256 i;
		for (i = 0; i < length; i++)
		{
			if (nftsInEpoch[currentEpoch][i].token == token && nftsInEpoch[currentEpoch][i].id == id)
			{
				nftsInEpoch[currentEpoch][i].votes += votes;
				break;
			}
		}

		if (i == length)
		{
			nftsInEpoch[currentEpoch].push(NftRecord(token, id, votes));
		}

		investedInVoting[epoch - 1][token][id][msg.sender].daiHaveWithdrawed = true;

		emit ReVotedWithDai(epoch, token, id, votes);                               // Records in ReVotedWithDai event.
	}

	/// @notice Function for repeat vote using Zoo in next battle epoch.
	/// @param epoch - number of epoch vote was made.
	/// @param token - address of nft contract vote was made for.
	/// @param id - id of nft vote was made for.
	/// @param voter - address of votes owner.
	function reVoteInZoo(uint256 epoch, address token, uint256 id, address voter) public
	{
		require(getCurrentStage() == Stage.ThirdStage, "Must be at 3rd stage!");
		require(!investedInVoting[epoch - 1][token][id][voter].zooHaveWithdrawed, "Zoo tokens were withdrawed!");
		uint256 amount = investedInVoting[epoch - 1][token][id][voter].zooInvested;
		require(amount != 0, "nothing to re-vote!");

		uint256 votes = zooFunctions.computeVotesByZoo(amount);                 // Calculates amount of votes.

		require(votes <= investedInVoting[currentEpoch][token][id][voter].votes, "votes amount more than invested!"); // Reverts if votes more than tokens invested.

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;             // Adds votes for this epoch, token and id.
		votesForNftInEpoch[currentEpoch][token][id].zooInvested += amount;      // Adds amount of Zoo for this epoch, token and id.

		investedInVoting[currentEpoch][token][id][voter].votes += votes;        // Adds votes for this epoch, token and id for msg.sender.
		investedInVoting[currentEpoch][token][id][voter].zooInvested += amount; // Adds amount of Zoo for this epoch, token and id for msg.sender.

		investedInVoting[epoch - 1][token][id][voter].zooHaveWithdrawed = true; // Records that tokens were reVoted.

		emit ReVotedWithZoo(epoch, token, id, votes);                                // Records in ReVotedWithZoo event.
	}

	/// @notice Function calculate amount of shares.
	/// @param _sharesAmount - amount of shares.
	/// @return shares - calculated amount of shares.
	function _sharesToTokens(uint256 _sharesAmount) public view returns (uint256 shares) ///todo:make internal
	{
		return _sharesAmount.mul(vault.pricePerShare()).div(10 ** dai.decimals()); // Calculate amount of shares.
	}

	/// @notice Function to view current stage in battle epoch.
	/// @return stage - current stage.
	function getCurrentStage() public view returns (Stage)
	{
		if (block.timestamp < epochStartDate + firstStageDuration)
		{
			return Stage.FirstStage;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration)
		{
			return Stage.SecondStage;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration)
		{
			return Stage.ThirdStage;
		}
		else
		{
			return Stage.FourthStage;
		}
	}
}