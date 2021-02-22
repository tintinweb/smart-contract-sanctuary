/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity ^0.6.0;


// SPDX-License-Identifier: MIT
interface ITokenGeyserManager {
    /**
        @dev Retrieves total rewards earned for a specific staking token
        @param token - address of the ERC20 token
    */
    function getEarned(address token) external view returns (uint256);

    /**
        @dev Retrieves staked amount for a specific token address
        @param token - address of the ERC20 token
    */
    function getStake(address token) external view returns (uint256);

    /**
        @dev Retrieves total rewards earned for all the staking tokens
    */
    function getEarnings()
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
        @dev Retrieves all stakes for sender
     */
    function getStakes()
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
        @dev Stakes all tokens sent
        @param tokens - array of tokens' addresses you want to stake
        @param amounts - stake amount you want for each token
     */
    function stake(
        address[] calldata tokens,
        uint256[] calldata amounts,
        int256 nftId
    ) external returns (bool);

    /**
        @dev Unstakes all tokens sent
        @param tokens - array of tokens' addresses you want to unstake
        @param amounts - unstake amount you want for each token
     */
    function unstake(address[] calldata tokens, uint256[] calldata amounts)
        external;

    /**
        @dev Retrives current user's rewards amount
        @param tokens - array of tokens' addresses you want to unstake
        @param amounts - unstake amount you want for each token
     */
    function unstakeQuery(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external returns (address[] memory, uint256[] memory);

    /**
        @dev Adds a new geyser in the team
        @param token - address of the staking token for which the geyser was created
        @param geyser - address of the geyser
     */
    function addGeyser(address token, address geyser) external returns (bool);

    event Staked(address indexed sender, address indexed token, uint256 amount);
    event Unstaked(
        address indexed sender,
        address indexed token,
        uint256 amount
    );

    event GeyserAdded(
        address indexed sender,
        address indexed geyser,
        address token
    );
    event GeyserManagerCreated(
        address indexed sender,
        address indexed geyserManager
    );
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
/**
 * @title Staking interface, as defined by EIP-900.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
interface IStaking {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );

    function unstake(address staker, uint256 amount, bytes calldata data) external;

    function totalStakedFor(address addr) external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function token() external view returns (address);

    function supportsHistory() external pure returns (bool);
}

// SPDX-License-Identifier: MIT
/**
 * @title Staking interface, as defined by EIP-900.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
interface IStakeWithNFT {
    function stake(
        address staker,
        uint256 amount,
        bytes calldata data,
        int256 nftId
    ) external;

    function stakeFor(
        address staker,
        address user,
        uint256 amount,
        bytes calldata data,
        int256 nftId
    ) external;
}

// SPDX-License-Identifier: MIT
/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable {
    IERC20 public token;
    bool private _isTokenRescuable;

    constructor(IERC20 _token) public {
        token = _token;
        _isTokenRescuable = false;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function setRescuable(bool rescuable) public onlyOwner {
        _isTokenRescuable = rescuable;
    }

    function transfer(address to, uint256 value)
        external
        onlyOwner
        returns (bool)
    {
        return token.transfer(to, value);
    }

    function rescueFunds(
        address tokenToRescue,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        if (!_isTokenRescuable) {
            require(
                address(token) != tokenToRescue,
                "TokenPool: Cannot claim token held by the contract"
            );
        }

        return IERC20(tokenToRescue).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
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
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

/*
    uint256 public constant socialNftIdentifier = uint256(1);
    uint256 public constant rareNftIdentifier = uint256(2);
    uint256 public constant epicNftIdentifier = uint256(4);
    uint256 public constant legendaryNftIdentifier = uint256(8);
*/
contract WarpNFT is Ownable, ERC721Pausable {
    uint256 public idTracker;

    // converts id -> token type
    mapping(uint256 => uint256) public tokenType;

    /**
    @notice the constructor function is fired only once during contract deployment
    @dev assuming all NFT URI metadata is based on a URL he baseURI would be something like https://
    **/
    constructor() public ERC721("Warp Finance", "WNFT") {
        idTracker = 0;
    }

    /**
    @notice mintNewNFT allows the owner of this contract to mint an input address a newNFT
    @param _to is the address the NFT is being minted to
    **/
    function mintNewNFT(
        address _to,
        uint256 _type,
        string memory _tokenURI
    ) public onlyOwner {
        _safeMint(_to, idTracker);
        _setTokenURI(idTracker, _tokenURI);
        tokenType[idTracker] = _type;
        idTracker++;
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
/**
 * @title Token Geyser
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by
 *      Compound and Uniswap.
 *
 *      Distribution tokens are added to a locked pool in the contract and become unlocked over time
 *      according to a once-configurable unlock schedule. Once unlocked, they are available to be
 *      claimed by users.
 *
 *      A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share
 *      is a function of the number of tokens deposited as well as the length of time deposited.
 *      Specifically, a user's share of the currently-unlocked pool equals their "deposit-seconds"
 *      divided by the global "deposit-seconds". This aligns the new token distribution with long
 *      term supporters of the project, addressing one of the major drawbacks of simple airdrops.
 *
 *      More background and motivation available at:
 *      https://github.com/ampleforth/RFCs/blob/master/RFCs/rfc-1.md
 */
contract TokenGeyser is IStaking, IStakeWithNFT, Ownable {
    using SafeMath for uint256;

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensLocked(uint256 amount, uint256 durationSec, uint256 total);
    // amount: Unlocked tokens, total: Total locked tokens
    event TokensUnlocked(uint256 amount, uint256 total);

    TokenPool private _stakingPool;
    TokenPool private _unlockedPool;
    TokenPool private _lockedPool;

    //
    // Time-bonus params
    //
    uint256 public bonusDecimals = 2;
    uint256 public startBonus = 0;
    uint256 public bonusPeriodSec = 0;

    //
    // Global accounting state
    //
    uint256 public totalLockedShares = 0;
    uint256 public totalStakingShares = 0;
    uint256 private _totalStakingShareSeconds = 0;
    uint256 private _lastAccountingTimestampSec = now;
    uint256 private _maxUnlockSchedules = 0;
    uint256 private _initialSharesPerToken = 0;

    //
    // User accounting state
    //
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        uint256 stakingShares;
        uint256 timestampSec;
    }

    // Caches aggregated values from the User->Stake[] map to save computation.
    // If lastAccountingTimestampSec is 0, there's no entry for that user.
    struct UserTotals {
        uint256 stakingShares;
        uint256 stakingShareSeconds;
        uint256 lastAccountingTimestampSec;
    }

    // Aggregated staking values per user
    mapping(address => UserTotals) private _userTotals;

    // The collection of stakes for each user. Ordered by timestamp, earliest to latest.
    mapping(address => Stake[]) private _userStakes;


    //
    // Locked/Unlocked Accounting state
    //
    struct UnlockSchedule {
        uint256 initialLockedShares;
        uint256 unlockedShares;
        uint256 lastUnlockTimestampSec;
        uint256 endAtSec;
        uint256 durationSec;
    }

    UnlockSchedule[] public unlockSchedules;

    WarpNFT public _warpNFT;
    address public geyserManager;
    mapping(address => uint256) public originalAmounts;
    mapping(address => uint256) public extraAmounts;
    uint256 public totalExtra;
    mapping(address => uint256) userEarnings;

    /**
     * @param stakingToken The token users deposit as stake.
     * @param distributionToken The token users receive as they unstake.
     * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
     * @param startBonus_ Starting time bonus
     *                    e.g. 25% means user gets 25% of max distribution tokens.
     * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
     * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
     * @param bonusDecimals_ The number of decimals for shares
     */
    constructor(
        IERC20 stakingToken,
        IERC20 distributionToken,
        uint256 maxUnlockSchedules,
        uint256 startBonus_,
        uint256 bonusPeriodSec_,
        uint256 initialSharesPerToken,
        uint256 bonusDecimals_,
        address warpNFT,
        address managerAddress
    ) public {
        // The start bonus must be some fraction of the max. (i.e. <= 100%)
        require(
            startBonus_ <= 10**bonusDecimals_,
            "TokenGeyser: start bonus too high"
        );
        // If no period is desired, instead set startBonus = 100%
        // and bonusPeriod to a small value like 1sec.
        require(bonusPeriodSec_ != 0, "TokenGeyser: bonus period is zero");
        require(
            initialSharesPerToken > 0,
            "TokenGeyser: initialSharesPerToken is zero"
        );

        require(bonusDecimals_ > 0, "TokenGeyser: bonusDecimals_ is zero");

        _stakingPool = new TokenPool(stakingToken);
        _unlockedPool = new TokenPool(distributionToken);
        _lockedPool = new TokenPool(distributionToken);
        _unlockedPool.setRescuable(true);

        geyserManager = managerAddress;
        startBonus = startBonus_;
        bonusDecimals = bonusDecimals_;
        bonusPeriodSec = bonusPeriodSec_;
        _maxUnlockSchedules = maxUnlockSchedules;
        _initialSharesPerToken = initialSharesPerToken;
        _warpNFT = WarpNFT(warpNFT);
    }

    /**
     * @return Total earnings for a user
    */
    function getEarnings(address user) public view returns (uint256) {
        return userEarnings[user];
    }

    /**
     * @dev Rescue rewards
     */
    function rescueRewards(address user) external onlyOwner {
        require(totalUnlocked() > 0, "TokenGeyser: Nothing to rescue");
        require(
            _unlockedPool.transfer(user, _unlockedPool.balance()),
            "TokenGeyser: rescue rewards from rewards pool failed"
        );
    }

    /**
     * @return The token users deposit as stake.
     */
    function getStakingToken() public view returns (IERC20) {
        return _stakingPool.token();
    }

    /**
     * @return The token users receive as they unstake.
     */
    function getDistributionToken() public view returns (IERC20) {
        assert(_unlockedPool.token() == _lockedPool.token());
        return _unlockedPool.token();
    }

    /**
     * @dev Transfers amount of deposit tokens from the user.
     * @param amount Number of deposit tokens to stake.
     * @param data Not used.
     */
    function stake(
        address staker,
        uint256 amount,
        bytes calldata data,
        int256 nftId
    ) external override {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _stakeFor(staker, staker, amount, nftId);
    }

    /**
     * @dev Transfers amount of deposit tokens from the caller on behalf of user.
     * @param user User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     * @param data Not used.
     */
    function stakeFor(
        address staker,
        address user,
        uint256 amount,
        bytes calldata data,
        int256 nftId
    ) external override onlyOwner {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _stakeFor(staker, user, amount, nftId);
    }

    /**
     * @dev Retrieves the boost you get for a specific NFT
     * @param beneficiary The address who receives the bonus
     * @param amount The amount for which the bonus is calculated
     * @param nftId The NFT identifier
     */
    function getNftBoost(
        address beneficiary,
        uint256 amount,
        int256 nftId
    ) public view returns (uint256) {
        if (nftId < 0) return 0;
        if (_warpNFT.ownerOf(uint256(nftId)) != beneficiary) return 0;

        uint256 nftType = _warpNFT.tokenType(uint256(nftId));
        if (nftType == uint256(1)) return 0;

        // 1 | Social - no boost
        // 2 | Rare - 15% boost
        // 4 | Epic - 75% boost
        // 8 | Legendary - 150% boost

        uint256 bonus = 1;

        if (nftType == uint256(2)) {
            bonus = 15;
        }
        if (nftType == uint256(4)) {
            bonus = 75;
        }
        if (nftType == uint256(8)) {
            bonus = 150;
        }

        uint256 result = (amount * bonus) / 100;
        return result;
    }

    /**
     * @dev Private implementation of staking methods.
     * @param staker User address who deposits tokens to stake.
     * @param beneficiary User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     */
    function _stakeFor(
        address staker,
        address beneficiary,
        uint256 amount,
        int256 nftId
    ) private {
        require(amount > 0, "TokenGeyser: stake amount is zero");
        require(
            beneficiary != address(0),
            "TokenGeyser: beneficiary is zero address"
        );
        require(
            totalStakingShares == 0 || totalStaked() > 0,
            "TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do"
        );
        uint256 sentAmount = 0;
        sentAmount += amount;

        uint256 extra = getNftBoost(beneficiary, amount, nftId);
        originalAmounts[beneficiary] += amount;
        extraAmounts[beneficiary] += extra;
        amount += extra;
        uint256 mintedStakingShares =
            (totalStakingShares > 0)
                ? totalStakingShares.mul(amount).div(totalStaked())
                : amount.mul(_initialSharesPerToken);
        totalExtra += extra;

        require(
            mintedStakingShares > 0,
            "TokenGeyser: Stake amount is too small"
        );

        updateAccounting(beneficiary);

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];
        totals.stakingShares = totals.stakingShares.add(mintedStakingShares);
        totals.lastAccountingTimestampSec = now;

        Stake memory newStake = Stake(mintedStakingShares, now);
        _userStakes[beneficiary].push(newStake);

        // 2. Global Accounting
        totalStakingShares = totalStakingShares.add(mintedStakingShares);
        // Already set in updateAccounting()
        // _lastAccountingTimestampSec = now;

        // interactions
        require(
            _stakingPool.token().transferFrom(
                staker,
                address(_stakingPool),
                sentAmount
            ),
            "TokenGeyser: transfer into staking pool failed"
        );

        emit Staked(beneficiary, sentAmount, totalStakedFor(beneficiary), "");
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @param data Not used.
     */
    function unstake(address staker, uint256 amount, bytes calldata data) external override {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _unstake(staker, amount);
    }

    /**
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens that would be rewarded.
     */
    function unstakeQuery(address staker, uint256 amount) public returns (uint256) {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        return _unstake(staker, amount);
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens rewarded.
     */
    function _unstake(address user, uint256 amount) private returns (uint256) {
        updateAccounting(user);

        // checks
        require(amount == 0, "TokenGeyser: only full unstake is allowed");

        amount = originalAmounts[user] + extraAmounts[user];
        uint256 stakingSharesToBurn =
            totalStakingShares.mul(amount).div(totalStaked());

        require(
            stakingSharesToBurn > 0,
            "TokenGeyser: Unable to unstake amount this small"
        );

        // 1. User Accounting
        UserTotals storage totals = _userTotals[user];
        Stake[] storage accountStakes = _userStakes[user];

        // Redeem from most recent stake and go backwards in time.
        uint256 stakingShareSecondsToBurn = 0;
        uint256 sharesLeftToBurn = stakingSharesToBurn;
        uint256 rewardAmount = 0;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = accountStakes[accountStakes.length - 1];
            uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
            uint256 newStakingShareSecondsToBurn = 0;

            if (lastStake.stakingShares <= sharesLeftToBurn) {
                newStakingShareSecondsToBurn = lastStake.stakingShares.mul(
                    stakeTimeSec
                );
                rewardAmount = computeNewReward(
                    rewardAmount,
                    newStakingShareSecondsToBurn,
                    stakeTimeSec
                );

                stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
                    newStakingShareSecondsToBurn
                );
                sharesLeftToBurn = sharesLeftToBurn.sub(
                    lastStake.stakingShares
                );
                accountStakes.pop();
            } else {
                newStakingShareSecondsToBurn = sharesLeftToBurn.mul(
                    stakeTimeSec
                );
                rewardAmount = computeNewReward(
                    rewardAmount,
                    newStakingShareSecondsToBurn,
                    stakeTimeSec
                );
                stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
                    newStakingShareSecondsToBurn
                );
                lastStake.stakingShares = lastStake.stakingShares.sub(
                    sharesLeftToBurn
                );
                sharesLeftToBurn = 0;
            }
        }
        totals.stakingShareSeconds = totals.stakingShareSeconds.sub(
            stakingShareSecondsToBurn
        );
        totals.stakingShares = totals.stakingShares.sub(stakingSharesToBurn);
        // Already set in updateAccounting
        // totals.lastAccountingTimestampSec = now;

        // 2. Global Accounting
        _totalStakingShareSeconds = _totalStakingShareSeconds.sub(
            stakingShareSecondsToBurn
        );
        totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);
        // Already set in updateAccounting
        // _lastAccountingTimestampSec = now;

        // interactions
        require(
            _stakingPool.transfer(user, originalAmounts[user]),
            "TokenGeyser: transfer out of staking pool failed"
        );

        //in case rescueRewards was called, there are no rewards to be transfered
        if (totalUnlocked() >= rewardAmount) {
            require(
                _unlockedPool.transfer(user, rewardAmount),
                "TokenGeyser: transfer out of unlocked pool failed"
            );
            emit TokensClaimed(user, rewardAmount);

            userEarnings[user] += rewardAmount;
        }
        

        emit Unstaked(user, amount, totalStakedFor(user), "");

        require(
            totalStakingShares == 0 || totalStaked() > 0,
            "TokenGeyser: Error unstaking. Staking shares exist, but no staking tokens do"
        );

        totalExtra -= extraAmounts[user];
        originalAmounts[user] = 0;
        extraAmounts[user] = 0;

        return rewardAmount;
    }

    /**
     * @dev Applies an additional time-bonus to a distribution amount. This is necessary to
     *      encourage long-term deposits instead of constant unstake/restakes.
     *      The bonus-multiplier is the result of a linear function that starts at startBonus and
     *      ends at 100% over bonusPeriodSec, then stays at 100% thereafter.
     * @param currentRewardTokens The current number of distribution tokens already alotted for this
     *                            unstake op. Any bonuses are already applied.
     * @param stakingShareSeconds The stakingShare-seconds that are being burned for new
     *                            distribution tokens.
     * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate
     *                     the time-bonus.
     * @return Updated amount of distribution tokens to award, with any bonus included on the
     *         newly added tokens.
     */
    function computeNewReward(
        uint256 currentRewardTokens,
        uint256 stakingShareSeconds,
        uint256 stakeTimeSec
    ) private view returns (uint256) {
        uint256 newRewardTokens =
            totalUnlocked().mul(stakingShareSeconds).div(
                _totalStakingShareSeconds
            );

        if (stakeTimeSec >= bonusPeriodSec) {
            return currentRewardTokens.add(newRewardTokens);
        }

        uint256 oneHundredPct = 10**bonusDecimals;
        uint256 bonusedReward =
            startBonus
                .add(
                oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(
                    bonusPeriodSec
                )
            )
                .mul(newRewardTokens)
                .div(oneHundredPct);

        return currentRewardTokens.add(bonusedReward);
    }


    /**
     * @param addr The user to look up staking information for.
     * @return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address addr)
        public
        view
        override
        returns (uint256)
    {
        uint256 amountWithExtra =
            totalStakingShares > 0
                ? totalStaked().mul(_userTotals[addr].stakingShares).div(
                    totalStakingShares
                )
                : 0;

        if (amountWithExtra == 0) return amountWithExtra;
        return amountWithExtra - extraAmounts[addr];
    }

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() public view override returns (uint256) {
        return _stakingPool.balance() + totalExtra;
    }

    /**
     * @dev Note that this application has a staking token as well as a distribution token, which
     * may be different. This function is required by EIP-900.
     * @return The deposit token used for staking.
     */
    function token() external view override returns (address) {
        return address(getStakingToken());
    }

    /**
     * @dev A globally callable function to update the accounting state of the system.
     *      Global state and state for the caller are updated.
     * @return [0] balance of the locked pool
     * @return [1] balance of the unlocked pool
     * @return [2] caller's staking share seconds
     * @return [3] global staking share seconds
     * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
     * @return [5] block timestamp
     */
    function updateAccounting(address user)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        _unlockTokens();

        // Global accounting
        uint256 newStakingShareSeconds =
            now.sub(_lastAccountingTimestampSec).mul(totalStakingShares);
        _totalStakingShareSeconds = _totalStakingShareSeconds.add(
            newStakingShareSeconds
        );
        _lastAccountingTimestampSec = now;

        // User Accounting
        UserTotals storage totals = _userTotals[user];
        uint256 newUserStakingShareSeconds =
            now.sub(totals.lastAccountingTimestampSec).mul(
                totals.stakingShares
            );
        totals.stakingShareSeconds = totals.stakingShareSeconds.add(
            newUserStakingShareSeconds
        );
        totals.lastAccountingTimestampSec = now;

        uint256 totalUserRewards =
            (_totalStakingShareSeconds > 0)
                ? totalUnlocked().mul(totals.stakingShareSeconds).div(
                    _totalStakingShareSeconds
                )
                : 0;

        return (
            totalLocked(),
            totalUnlocked(),
            totals.stakingShareSeconds,
            _totalStakingShareSeconds,
            totalUserRewards,
            now
        );
    }

    /**
     * @return Total number of locked distribution tokens.
     */
    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }

    /**
     * @return Total number of unlocked distribution tokens.
     */
    function totalUnlocked() public view returns (uint256) {
        return _unlockedPool.balance();
    }

    /**
     * @return Number of unlock schedules.
     */
    function unlockScheduleCount() public view returns (uint256) {
        return unlockSchedules.length;
    }

    /**
     * @dev This funcion allows the contract owner to add more locked distribution tokens, along
     *      with the associated "unlock schedule". These locked tokens immediately begin unlocking
     *      linearly over the duraction of durationSec timeframe.
     * @param amount Number of distribution tokens to lock. These are transferred from the caller.
     * @param durationSec Length of time to linear unlock the tokens.
     */
    function lockTokens(uint256 amount, uint256 durationSec)
        external
        onlyOwner
    {
        require(
            unlockSchedules.length < _maxUnlockSchedules,
            "TokenGeyser: reached maximum unlock schedules"
        );

        // Update lockedTokens amount before using it in computations after.
        updateAccounting(msg.sender);

        uint256 lockedTokens = totalLocked();
        uint256 mintedLockedShares =
            (lockedTokens > 0)
                ? totalLockedShares.mul(amount).div(lockedTokens)
                : amount.mul(_initialSharesPerToken);

        UnlockSchedule memory schedule;
        schedule.initialLockedShares = mintedLockedShares;
        schedule.lastUnlockTimestampSec = now;
        schedule.endAtSec = now.add(durationSec);
        schedule.durationSec = durationSec;
        unlockSchedules.push(schedule);

        totalLockedShares = totalLockedShares.add(mintedLockedShares);

        require(
            _lockedPool.token().transferFrom(
                msg.sender,
                address(_lockedPool),
                amount
            ),
            "TokenGeyser: transfer into locked pool failed"
        );
        emit TokensLocked(amount, durationSec, totalLocked());
    }

    /**
     * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the
     *      previously defined unlock schedules. Publicly callable.
     * @return Number of newly unlocked distribution tokens.
     */
    function unlockTokens() public onlyOwner returns (uint256) {
        _unlockTokens();
    }

    function _unlockTokens() private returns (uint256) {
        uint256 unlockedTokens = 0;
        uint256 lockedTokens = totalLocked();

        if (totalLockedShares == 0) {
            unlockedTokens = lockedTokens;
        } else {
            uint256 unlockedShares = 0;
            for (uint256 s = 0; s < unlockSchedules.length; s++) {
                unlockedShares = unlockedShares.add(unlockScheduleShares(s));
            }
            unlockedTokens = unlockedShares.mul(lockedTokens).div(
                totalLockedShares
            );
            totalLockedShares = totalLockedShares.sub(unlockedShares);
        }

        if (unlockedTokens > 0) {
            require(
                _lockedPool.transfer(address(_unlockedPool), unlockedTokens),
                "TokenGeyser: transfer out of locked pool failed"
            );
            emit TokensUnlocked(unlockedTokens, totalLocked());
        }

        return unlockedTokens;
    }

    /**
     * @dev Returns the number of unlockable shares from a given schedule. The returned value
     *      depends on the time since the last unlock. This function updates schedule accounting,
     *      but does not actually transfer any tokens.
     * @param s Index of the unlock schedule.
     * @return The number of unlocked shares.
     */
    function unlockScheduleShares(uint256 s) private returns (uint256) {
        UnlockSchedule storage schedule = unlockSchedules[s];

        if (schedule.unlockedShares >= schedule.initialLockedShares) {
            return 0;
        }

        uint256 sharesToUnlock = 0;
        // Special case to handle any leftover dust from integer division
        if (now >= schedule.endAtSec) {
            sharesToUnlock = (
                schedule.initialLockedShares.sub(schedule.unlockedShares)
            );
            schedule.lastUnlockTimestampSec = schedule.endAtSec;
        } else {
            sharesToUnlock = now
                .sub(schedule.lastUnlockTimestampSec)
                .mul(schedule.initialLockedShares)
                .div(schedule.durationSec);
            schedule.lastUnlockTimestampSec = now;
        }

        schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);
        return sharesToUnlock;
    }

    /**
     * @dev Lets the owner rescue funds air-dropped to the staking pool.
     * @param tokenToRescue Address of the token to be rescued.
     * @param to Address to which the rescued funds are to be sent.
     * @param amount Amount of tokens to be rescued.
     * @return Transfer success.
     */
    function rescueFundsFromStakingPool(
        address tokenToRescue,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        return _stakingPool.rescueFunds(tokenToRescue, to, amount);
    }

    function supportsHistory() external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
/**
 * @title Staking interface, as defined by EIP-900.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
interface IStake {
    function stake(
        address staker,
        uint256 amount,
        bytes calldata data
    ) external;

    function stakeFor(
        address staker,
        address user,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
/**
 * @title Non Nft Token Geyser
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by
 *      Compound and Uniswap.
 *
 *      Distribution tokens are added to a locked pool in the contract and become unlocked over time
 *      according to a once-configurable unlock schedule. Once unlocked, they are available to be
 *      claimed by users.
 *
 *      A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share
 *      is a function of the number of tokens deposited as well as the length of time deposited.
 *      Specifically, a user's share of the currently-unlocked pool equals their "deposit-seconds"
 *      divided by the global "deposit-seconds". This aligns the new token distribution with long
 *      term supporters of the project, addressing one of the major drawbacks of simple airdrops.
 *
 *      More background and motivation available at:
 *      https://github.com/ampleforth/RFCs/blob/master/RFCs/rfc-1.md
 */
contract TokenGeyserWithoutNFT is IStaking, IStake, Ownable {
    using SafeMath for uint256;

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensLocked(uint256 amount, uint256 durationSec, uint256 total);
    // amount: Unlocked tokens, total: Total locked tokens
    event TokensUnlocked(uint256 amount, uint256 total);

    TokenPool private _stakingPool;
    TokenPool private _unlockedPool;
    TokenPool private _lockedPool;

    //
    // Time-bonus params
    //
    uint256 public bonusDecimals = 2;
    uint256 public startBonus = 0;
    uint256 public bonusPeriodSec = 0;

    //
    // Global accounting state
    //
    uint256 public totalLockedShares = 0;
    uint256 public totalStakingShares = 0;
    uint256 private _totalStakingShareSeconds = 0;
    uint256 private _lastAccountingTimestampSec = now;
    uint256 private _maxUnlockSchedules = 0;
    uint256 private _initialSharesPerToken = 0;

    //
    // User accounting state
    //
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        uint256 stakingShares;
        uint256 timestampSec;
    }

    // Caches aggregated values from the User->Stake[] map to save computation.
    // If lastAccountingTimestampSec is 0, there's no entry for that user.
    struct UserTotals {
        uint256 stakingShares;
        uint256 stakingShareSeconds;
        uint256 lastAccountingTimestampSec;
    }

    // Aggregated staking values per user
    mapping(address => UserTotals) private _userTotals;

    // The collection of stakes for each user. Ordered by timestamp, earliest to latest.
    mapping(address => Stake[]) private _userStakes;

    mapping(address => uint256) userEarnings;

    //
    // Locked/Unlocked Accounting state
    //
    struct UnlockSchedule {
        uint256 initialLockedShares;
        uint256 unlockedShares;
        uint256 lastUnlockTimestampSec;
        uint256 endAtSec;
        uint256 durationSec;
    }

    UnlockSchedule[] public unlockSchedules;

    address public geyserManager;

    /**
     * @param stakingToken The token users deposit as stake.
     * @param distributionToken The token users receive as they unstake.
     * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
     * @param startBonus_ Starting time bonus
     *                    e.g. 25% means user gets 25% of max distribution tokens.
     * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
     * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
     * @param bonusDecimals_ The number of decimals for shares
     */
    constructor(
        IERC20 stakingToken,
        IERC20 distributionToken,
        uint256 maxUnlockSchedules,
        uint256 startBonus_,
        uint256 bonusPeriodSec_,
        uint256 initialSharesPerToken,
        uint256 bonusDecimals_,
        address managerAddress
    ) public {
        // The start bonus must be some fraction of the max. (i.e. <= 100%)
        require(
            startBonus_ <= 10**bonusDecimals_,
            "TokenGeyser: start bonus too high"
        );
        // If no period is desired, instead set startBonus = 100%
        // and bonusPeriod to a small value like 1sec.
        require(bonusPeriodSec_ != 0, "TokenGeyser: bonus period is zero");
        require(
            initialSharesPerToken > 0,
            "TokenGeyser: initialSharesPerToken is zero"
        );

        require(bonusDecimals_ > 0, "TokenGeyser: bonusDecimals_ is zero");

        _stakingPool = new TokenPool(stakingToken);
        _unlockedPool = new TokenPool(distributionToken);
        _lockedPool = new TokenPool(distributionToken);
        _unlockedPool.setRescuable(true);

        geyserManager = managerAddress;
        startBonus = startBonus_;
        bonusDecimals = bonusDecimals_;
        bonusPeriodSec = bonusPeriodSec_;
        _maxUnlockSchedules = maxUnlockSchedules;
        _initialSharesPerToken = initialSharesPerToken;
    }

    /**
     * @return Total earnings for a user
    */
    function getEarnings(address user) public view returns (uint256) {
        return userEarnings[user];
    }

    /**
     * @dev Rescue rewards
     */
    function rescueRewards(address user) external onlyOwner {
        require(totalUnlocked() > 0, "TokenGeyser: Nothing to rescue");
        require(
            _unlockedPool.transfer(user, _unlockedPool.balance()),
            "TokenGeyser: rescue rewards from rewards pool failed"
        );
    }

    /**
     * @return The token users deposit as stake.
     */
    function getStakingToken() public view returns (IERC20) {
        return _stakingPool.token();
    }

    /**
     * @return The token users receive as they unstake.
     */
    function getDistributionToken() public view returns (IERC20) {
        assert(_unlockedPool.token() == _lockedPool.token());
        return _unlockedPool.token();
    }

    event log(string s);
    event log(uint256 s);
    event log(address s);

    /**
     * @dev Transfers amount of deposit tokens from the user.
     * @param amount Number of deposit tokens to stake.
     * @param data Not used.
     */
    function stake(
        address staker,
        uint256 amount,
        bytes calldata data
    ) external override {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _stakeFor(staker, staker, amount);
    }

    /**
     * @dev Transfers amount of deposit tokens from the caller on behalf of user.
     * @param user User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     * @param data Not used.
     */
    function stakeFor(
        address staker,
        address user,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _stakeFor(staker, user, amount);
    }

    /**
     * @dev Private implementation of staking methods.
     * @param staker User address who deposits tokens to stake.
     * @param beneficiary User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     */
    function _stakeFor(
        address staker,
        address beneficiary,
        uint256 amount
    ) private {
        require(amount > 0, "TokenGeyser: stake amount is zero");
        require(
            beneficiary != address(0),
            "TokenGeyser: beneficiary is zero address"
        );
        require(
            totalStakingShares == 0 || totalStaked() > 0,
            "TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do"
        );


        uint256 mintedStakingShares =
            (totalStakingShares > 0)
                ? totalStakingShares.mul(amount).div(totalStaked())
                : amount.mul(_initialSharesPerToken);

        require(
            mintedStakingShares > 0,
            "TokenGeyser: Stake amount is too small"
        );

        updateAccounting(beneficiary);

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];
        totals.stakingShares = totals.stakingShares.add(mintedStakingShares);
        totals.lastAccountingTimestampSec = now;

        Stake memory newStake = Stake(mintedStakingShares, now);
        _userStakes[beneficiary].push(newStake);

        // 2. Global Accounting
        totalStakingShares = totalStakingShares.add(mintedStakingShares);
        // Already set in updateAccounting()
        // _lastAccountingTimestampSec = now;

        // interactions
        require(
            _stakingPool.token().transferFrom(
                staker,
                address(_stakingPool),
                amount
            ),
            "TokenGeyser: transfer into staking pool failed"
        );

        emit Staked(beneficiary, amount, totalStakedFor(beneficiary), "");
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @param data Not used.
     */
    function unstake(
        address staker,
        uint256 amount,
        bytes calldata data
    ) external override {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _unstake(staker, amount);
    }

    /**
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens that would be rewarded.
     */
    function unstakeQuery(address staker, uint256 amount)
        public
        returns (uint256)
    {
        require(
            geyserManager == msg.sender,
            "This method can be called by the geyser manager only"
        );
        return _unstake(staker, amount);
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens rewarded.
     */
    function _unstake(address user, uint256 amount) private returns (uint256) {
        updateAccounting(user);

        uint256 stakingSharesToBurn =
            totalStakingShares.mul(amount).div(totalStaked());

        require(
            stakingSharesToBurn > 0,
            "TokenGeyser: Unable to unstake amount this small"
        );

        // 1. User Accounting
        UserTotals storage totals = _userTotals[user];
        Stake[] storage accountStakes = _userStakes[user];

        // Redeem from most recent stake and go backwards in time.
        uint256 stakingShareSecondsToBurn = 0;
        uint256 sharesLeftToBurn = stakingSharesToBurn;
        uint256 rewardAmount = 0;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = accountStakes[accountStakes.length - 1];
            uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
            uint256 newStakingShareSecondsToBurn = 0;

            if (lastStake.stakingShares <= sharesLeftToBurn) {
                newStakingShareSecondsToBurn = lastStake.stakingShares.mul(
                    stakeTimeSec
                );
                rewardAmount = computeNewReward(
                    rewardAmount,
                    newStakingShareSecondsToBurn,
                    stakeTimeSec
                );

                stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
                    newStakingShareSecondsToBurn
                );
                sharesLeftToBurn = sharesLeftToBurn.sub(
                    lastStake.stakingShares
                );
                accountStakes.pop();
            } else {
                newStakingShareSecondsToBurn = sharesLeftToBurn.mul(
                    stakeTimeSec
                );
                rewardAmount = computeNewReward(
                    rewardAmount,
                    newStakingShareSecondsToBurn,
                    stakeTimeSec
                );
                stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
                    newStakingShareSecondsToBurn
                );
                lastStake.stakingShares = lastStake.stakingShares.sub(
                    sharesLeftToBurn
                );
                sharesLeftToBurn = 0;
            }
        }
        totals.stakingShareSeconds = totals.stakingShareSeconds.sub(
            stakingShareSecondsToBurn
        );
        totals.stakingShares = totals.stakingShares.sub(stakingSharesToBurn);
        // Already set in updateAccounting
        // totals.lastAccountingTimestampSec = now;

        // 2. Global Accounting
        _totalStakingShareSeconds = _totalStakingShareSeconds.sub(
            stakingShareSecondsToBurn
        );
        totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);
        // Already set in updateAccountingF
        // _lastAccountingTimestampSec = now;

        // interactions
        require(
            _stakingPool.transfer(user, amount),
            "TokenGeyser: transfer out of staking pool failed"
        );

        //in case rescueRewards was called, there are no rewards to be transfered
        if (totalUnlocked() >= rewardAmount) {
            require(
                _unlockedPool.transfer(user, rewardAmount),
                "TokenGeyser: transfer out of unlocked pool failed"
            );
            emit TokensClaimed(user, rewardAmount);
            
             userEarnings[user] += rewardAmount;
        }

        emit Unstaked(user, amount, totalStakedFor(user), "");

        require(
            totalStakingShares == 0 || totalStaked() > 0,
            "TokenGeyser: Error unstaking. Staking shares exist, but no staking tokens do"
        );

        return rewardAmount;
    }

    /**
     * @dev Applies an additional time-bonus to a distribution amount. This is necessary to
     *      encourage long-term deposits instead of constant unstake/restakes.
     *      The bonus-multiplier is the result of a linear function that starts at startBonus and
     *      ends at 100% over bonusPeriodSec, then stays at 100% thereafter.
     * @param currentRewardTokens The current number of distribution tokens already alotted for this
     *                            unstake op. Any bonuses are already applied.
     * @param stakingShareSeconds The stakingShare-seconds that are being burned for new
     *                            distribution tokens.
     * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate
     *                     the time-bonus.
     * @return Updated amount of distribution tokens to award, with any bonus included on the
     *         newly added tokens.
     */
    function computeNewReward(
        uint256 currentRewardTokens,
        uint256 stakingShareSeconds,
        uint256 stakeTimeSec
    ) private view returns (uint256) {
        uint256 newRewardTokens =
            totalUnlocked().mul(stakingShareSeconds).div(
                _totalStakingShareSeconds
            );

        if (stakeTimeSec >= bonusPeriodSec) {
            return currentRewardTokens.add(newRewardTokens);
        }

        uint256 oneHundredPct = 10**bonusDecimals;
        uint256 bonusedReward =
            startBonus
                .add(
                oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(
                    bonusPeriodSec
                )
            )
                .mul(newRewardTokens)
                .div(oneHundredPct);

        return currentRewardTokens.add(bonusedReward);
    }

    /**
     * @param addr The user to look up staking information for.
     * @return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address addr)
        public
        view
        override
        returns (uint256)
    {
        return
            totalStakingShares > 0
                ? totalStaked().mul(_userTotals[addr].stakingShares).div(
                    totalStakingShares
                )
                : 0;
    }

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() public view override returns (uint256) {
        return _stakingPool.balance();
    }

    /**
     * @dev Note that this application has a staking token as well as a distribution token, which
     * may be different. This function is required by EIP-900.
     * @return The deposit token used for staking.
     */
    function token() external view override returns (address) {
        return address(getStakingToken());
    }

    /**
     * @dev A globally callable function to update the accounting state of the system.
     *      Global state and state for the caller are updated.
     * @return [0] balance of the locked pool
     * @return [1] balance of the unlocked pool
     * @return [2] caller's staking share seconds
     * @return [3] global staking share seconds
     * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
     * @return [5] block timestamp
     */
    function updateAccounting(address user)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        _unlockTokens();

        // Global accounting
        uint256 newStakingShareSeconds =
            now.sub(_lastAccountingTimestampSec).mul(totalStakingShares);
        _totalStakingShareSeconds = _totalStakingShareSeconds.add(
            newStakingShareSeconds
        );
        _lastAccountingTimestampSec = now;

        // User Accounting
        UserTotals storage totals = _userTotals[user];
        uint256 newUserStakingShareSeconds =
            now.sub(totals.lastAccountingTimestampSec).mul(
                totals.stakingShares
            );
        totals.stakingShareSeconds = totals.stakingShareSeconds.add(
            newUserStakingShareSeconds
        );
        totals.lastAccountingTimestampSec = now;

        uint256 totalUserRewards =
            (_totalStakingShareSeconds > 0)
                ? totalUnlocked().mul(totals.stakingShareSeconds).div(
                    _totalStakingShareSeconds
                )
                : 0;

        return (
            totalLocked(),
            totalUnlocked(),
            totals.stakingShareSeconds,
            _totalStakingShareSeconds,
            totalUserRewards,
            now
        );
    }

    /**
     * @return Total number of locked distribution tokens.
     */
    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }

    /**
     * @return Total number of unlocked distribution tokens.
     */
    function totalUnlocked() public view returns (uint256) {
        return _unlockedPool.balance();
    }

    /**
     * @return Number of unlock schedules.
     */
    function unlockScheduleCount() public view returns (uint256) {
        return unlockSchedules.length;
    }

    /**
     * @dev This funcion allows the contract owner to add more locked distribution tokens, along
     *      with the associated "unlock schedule". These locked tokens immediately begin unlocking
     *      linearly over the duraction of durationSec timeframe.
     * @param amount Number of distribution tokens to lock. These are transferred from the caller.
     * @param durationSec Length of time to linear unlock the tokens.
     */
    function lockTokens(uint256 amount, uint256 durationSec)
        external
        onlyOwner
    {
        require(
            unlockSchedules.length < _maxUnlockSchedules,
            "TokenGeyser: reached maximum unlock schedules"
        );

        // Update lockedTokens amount before using it in computations after.
        updateAccounting(msg.sender);

        uint256 lockedTokens = totalLocked();
        uint256 mintedLockedShares =
            (lockedTokens > 0)
                ? totalLockedShares.mul(amount).div(lockedTokens)
                : amount.mul(_initialSharesPerToken);

        UnlockSchedule memory schedule;
        schedule.initialLockedShares = mintedLockedShares;
        schedule.lastUnlockTimestampSec = now;
        schedule.endAtSec = now.add(durationSec);
        schedule.durationSec = durationSec;
        unlockSchedules.push(schedule);

        totalLockedShares = totalLockedShares.add(mintedLockedShares);

        require(
            _lockedPool.token().transferFrom(
                msg.sender,
                address(_lockedPool),
                amount
            ),
            "TokenGeyser: transfer into locked pool failed"
        );
        emit TokensLocked(amount, durationSec, totalLocked());
    }

    /**
     * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the
     *      previously defined unlock schedules. Publicly callable.
     * @return Number of newly unlocked distribution tokens.
     */
    function unlockTokens() public onlyOwner returns (uint256) {
        _unlockTokens();
    }

    function _unlockTokens() private returns (uint256) {
        uint256 unlockedTokens = 0;
        uint256 lockedTokens = totalLocked();

        if (totalLockedShares == 0) {
            unlockedTokens = lockedTokens;
        } else {
            uint256 unlockedShares = 0;
            for (uint256 s = 0; s < unlockSchedules.length; s++) {
                unlockedShares = unlockedShares.add(unlockScheduleShares(s));
            }
            unlockedTokens = unlockedShares.mul(lockedTokens).div(
                totalLockedShares
            );
            totalLockedShares = totalLockedShares.sub(unlockedShares);
        }

        if (unlockedTokens > 0) {
            require(
                _lockedPool.transfer(address(_unlockedPool), unlockedTokens),
                "TokenGeyser: transfer out of locked pool failed"
            );
            emit TokensUnlocked(unlockedTokens, totalLocked());
        }

        return unlockedTokens;
    }

    /**
     * @dev Returns the number of unlockable shares from a given schedule. The returned value
     *      depends on the time since the last unlock. This function updates schedule accounting,
     *      but does not actually transfer any tokens.
     * @param s Index of the unlock schedule.
     * @return The number of unlocked shares.
     */
    function unlockScheduleShares(uint256 s) private returns (uint256) {
        UnlockSchedule storage schedule = unlockSchedules[s];

        if (schedule.unlockedShares >= schedule.initialLockedShares) {
            return 0;
        }

        uint256 sharesToUnlock = 0;
        // Special case to handle any leftover dust from integer division
        if (now >= schedule.endAtSec) {
            sharesToUnlock = (
                schedule.initialLockedShares.sub(schedule.unlockedShares)
            );
            schedule.lastUnlockTimestampSec = schedule.endAtSec;
        } else {
            sharesToUnlock = now
                .sub(schedule.lastUnlockTimestampSec)
                .mul(schedule.initialLockedShares)
                .div(schedule.durationSec);
            schedule.lastUnlockTimestampSec = now;
        }

        schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);
        return sharesToUnlock;
    }

    /**
     * @dev Lets the owner rescue funds air-dropped to the staking pool.
     * @param tokenToRescue Address of the token to be rescued.
     * @param to Address to which the rescued funds are to be sent.
     * @param amount Amount of tokens to be rescued.
     * @return Transfer success.
     */
    function rescueFundsFromStakingPool(
        address tokenToRescue,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        return _stakingPool.rescueFunds(tokenToRescue, to, amount);
    }

    function supportsHistory() external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
/** @title Token Geyser Manager */
contract TokenGeyserManager is Ownable, ITokenGeyserManager {
    bool public hasNFTBonus;
    mapping(address => address) public geysers;
    address[] public tokens;

    /**
       @dev Creates an empty Geyser token managers
    
     */
    constructor(bool _hasNftBonus) public {
        hasNFTBonus = _hasNftBonus;

        emit GeyserManagerCreated(msg.sender, address(this));
    }

    /**
        @dev Adds a new geyser in the team
        @param token - address of the staking token for which the geyser was created
        @param geyser - address of the geyser
     */
    function addGeyser(address token, address geyser)
        public
        override
        onlyOwner
        returns (bool)
    {
        require(token != address(0), "TokenGeyserManager: token is invalid");

        require(geyser != address(0), "TokenGeyserManager: geyser is invalid");
        tokens.push(token);
        geysers[token] = geyser;

        emit GeyserAdded(msg.sender, geyser, token);
        return true;
    }

    /**
        @dev Retrieves total rewards earned for a specific staking token
        @param token - address of the ERC20 token
    */
    function getEarned(address token) public view override returns (uint256) {
        if (hasNFTBonus) {
            return TokenGeyser(geysers[token]).getEarnings(msg.sender);
        }
        return TokenGeyserWithoutNFT(geysers[token]).getEarnings(msg.sender);
    }

    /**
        @dev Retrieves total rewards earned for all the staking tokens
    */
     function getEarnings() public view override returns (address[] memory, uint256[] memory){
        address[] memory addresses = new address[](tokens.length);
        uint256[] memory amounts = new uint256[](tokens.length);

        for (uint8 i = 0; i < tokens.length; i++) {
            addresses[i] = tokens[i];
            if (hasNFTBonus) {
                amounts[i] = TokenGeyser(geysers[tokens[i]]).getEarnings(
                    msg.sender
                );
            } else {
                amounts[i] = TokenGeyserWithoutNFT(geysers[tokens[i]])
                    .getEarnings(msg.sender);
            }
        }

        return (addresses, amounts);
     }


    /**
        @dev Retrieves staked amount for a specific token address
        @param token - address of the ERC20 token
    */
    function getStake(address token) public view override returns (uint256) {
        if (hasNFTBonus) {
            return TokenGeyser(geysers[token]).totalStakedFor(msg.sender);
        }
        return TokenGeyserWithoutNFT(geysers[token]).totalStakedFor(msg.sender);
    }


    /**
        @dev Retrieves all stakes for sender
     */
    function getStakes()
        public
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addresses = new address[](tokens.length);
        uint256[] memory amounts = new uint256[](tokens.length);

        for (uint8 i = 0; i < tokens.length; i++) {
            addresses[i] = tokens[i];
            if (hasNFTBonus) {
                amounts[i] = TokenGeyser(geysers[tokens[i]]).totalStakedFor(
                    msg.sender
                );
            } else {
                amounts[i] = TokenGeyserWithoutNFT(geysers[tokens[i]])
                    .totalStakedFor(msg.sender);
            }
        }

        return (addresses, amounts);
    }


    /**
        @dev Stakes all tokens sent
        @param _tokens - array of tokens' addresses you want to stake
        @param amounts - stake amount you want for each token
     */
    function stake(
        address[] calldata _tokens,
        uint256[] calldata amounts,
        int256 nftId
    ) external override returns (bool) {
        //validation
        require(tokens.length > 0, "TokenGeyserManager: _tokens is empty");
        require(amounts.length > 0, "TokenGeyserManager: amounts is empty");
        require(
            _tokens.length == amounts.length,
            "TokenGeyserManager: tokens and amounts need to  be the same length"
        );

        for (uint8 i = 0; i < _tokens.length; i++) {
            ERC20 currentToken = ERC20(_tokens[i]);
            uint256 currentTokenBalance = currentToken.balanceOf(msg.sender);
            uint256 sentAmount = amounts[i];
            string memory tokenName = currentToken.name();

            require(
                currentTokenBalance >= sentAmount,
                string(
                    abi.encodePacked(
                        "TokenGeyserManager: Token ",
                        tokenName,
                        " balance is lower than the amount sent"
                    )
                )
            );
        }
        //actions
        for (uint8 i = 0; i < _tokens.length; i++) {
            if (hasNFTBonus) {
                TokenGeyser(geysers[_tokens[i]]).stake(
                    msg.sender,
                    amounts[i],
                    "",
                    nftId
                );
            } else {
                TokenGeyserWithoutNFT(geysers[_tokens[i]]).stake(
                    msg.sender,
                    amounts[i],
                    ""
                );
            }

            emit Staked(msg.sender, tokens[i], amounts[i]);
        }

        return true;
    }

    /**
        @dev Unstakes all tokens sent
        @param _tokens - array of tokens' addresses you want to unstake
        @param amounts - unstake amount you want for each token
     */
    function unstake(address[] calldata _tokens, uint256[] calldata amounts)
        external
        override
    {
        //validation
        require(tokens.length > 0, "TokenGeyserManager: _tokens is empty");
        require(amounts.length > 0, "TokenGeyserManager: amounts is empty");
        require(
            _tokens.length == amounts.length,
            "TokenGeyserManager: tokens and amounts need to  be the same length"
        );

        for (uint8 i = 0; i < _tokens.length; i++) {
            if (hasNFTBonus) {
                require(
                    amounts[i] == 0,
                    "TokenGeyserManager: only full unstake is allowed"
                );
                TokenGeyser(geysers[_tokens[i]]).unstake(
                    msg.sender,
                    amounts[i],
                    ""
                );
            } else {
                TokenGeyserWithoutNFT(geysers[_tokens[i]]).unstake(
                    msg.sender,
                    amounts[i],
                    ""
                );
            }

            emit Unstaked(msg.sender, _tokens[i], amounts[i]);
        }
    }


        /**
        @dev get current eligible rewards from all farms
     */
    function unstakeQuery(address[] calldata _tokens, uint256[] calldata amounts)
        external
        override
        returns (address[] memory, uint256[] memory)
    {
        //validation
        require(tokens.length > 0, "TokenGeyserManager: _tokens is empty");
        require(amounts.length > 0, "TokenGeyserManager: amounts is empty");
        require(
            _tokens.length == amounts.length,
            "TokenGeyserManager: tokens and amounts need to  be the same length"
        );

        address[] memory addresses = new address[](tokens.length);
        uint256[] memory values = new uint256[](tokens.length);

        for (uint8 i = 0; i < _tokens.length; i++) {
            addresses[i] = _tokens[i];
            if (hasNFTBonus) {
                require(
                    amounts[i] == 0,
                    "TokenGeyserManager: only full unstake is allowed"
                );
                values[i] = TokenGeyser(geysers[_tokens[i]]).unstakeQuery(
                    msg.sender,
                    amounts[i]
                );
            } else {
                values[i] = TokenGeyserWithoutNFT(geysers[_tokens[i]]).unstakeQuery(
                    msg.sender,
                    amounts[i]
                );
            }

            emit Unstaked(msg.sender, _tokens[i], values[i]);

            return (addresses, values);
        }
    }
}