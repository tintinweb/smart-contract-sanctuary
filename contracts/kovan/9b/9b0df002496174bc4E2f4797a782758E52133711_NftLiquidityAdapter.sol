// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/ERC20.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/IERC721Receiver.sol";
import "../Governance.sol";
import "../NFT/MascotsNFT.sol";
import "./RewardPool.sol";
import "./ERC20NftLiquidityToken.sol";
import "../openzeppelin/Initializable.sol";
import "../ContextUpgradeSafe.sol";

// receive NFT from user, representing the user to join the reward pool.
contract NftLiquidityAdapter is Initializable, ContextUpgradeSafe, IERC721Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public governance;
    address private pendingGovernance;

    RewardPool public mRewardPool;

    struct NftLp {
        address lpToken; // token representing for NFT
        address nftToken;
        uint256 typeNft; // type NFT
    }
    mapping(uint256 => NftLp) public mNftLps;

    // pId => user address => listNftId
    mapping(uint256 => mapping(address => uint256[])) public mListNftId;

    event AddNftLq(address tokenLp, address nftlp, uint256 typeNft, uint256 pId);

    event DepositNFT(address sender, uint256 pId, address nftToken, uint256[] listId);

    event WithdrawNFT(address sender, uint256 pId, address nftToken, uint256 amount);

    event EmergencyWithdrawForNftPool(address sender, uint256 pId, address nftToken);

    event ClaimReward(address sender, uint256 pId);

    function _init_(address _rewardPool) public initializer {
        __Context_init_unchained();
        governance = msg.sender;
        mRewardPool = RewardPool(_rewardPool);
    }

    modifier onlyGovernance() {
        require(_msgSender() == governance, "NftLiquidityAdapter: !governance");
        _;
    }

    modifier checkNft(uint256 _pId, uint256[] memory _listId) {
        require(mNftLps[_pId].typeNft > 0, "NftLiquidityAdapter: is not exist");
        address _nftToken = mNftLps[_pId].nftToken;
        for (uint256 i = 0; i < _listId.length; i++) {
            require(MascotsNFT(_nftToken).ownerOf(_listId[i]) == msg.sender, "NftLiquidityAdapter: !owner");
            require(mNftLps[_pId].typeNft == MascotsNFT(_nftToken).getTokenMetadata(_listId[i]).rarity, "NftLiquidityAdapter: ! typeNft");
        }
        _;
    }

    function setGovernance(address governance_) external virtual onlyGovernance {
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(_msgSender() == pendingGovernance, "NftLiquidityAdapter: !pendingGovernance");
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function balanceNft(uint256 _pId, address _user) public view returns (uint256) {
        return mListNftId[_pId][_user].length;
    }

    function addNftLq(
        address _nftToken,
        uint256 _typeNft,
        uint256 _pId
    ) public onlyGovernance {
        require(_typeNft >= 1, "NftLiquidityAdapter: typeNft >= 1");

        (IERC20 _lpToken, , , , , , , , , ) = mRewardPool.mPoolInfo(_pId);

        require(address(_lpToken) != address(0) && _nftToken != address(0), "NftLiquidityAdapter: zero address");

        mNftLps[_pId] = NftLp({lpToken: address(_lpToken), nftToken: _nftToken, typeNft: _typeNft});
        ERC20NftLiquidityToken(address(_lpToken)).mint(address(this), 10000000000 ether);
        emit AddNftLq(address(_lpToken), _nftToken, _typeNft, _pId);
    }

    function depositNFT(uint256 _pId, uint256[] memory _listId) external virtual checkNft(_pId, _listId) {
        address sender = msg.sender;
        uint256 lenNft = _listId.length;
        uint256 allocPoint = 0;
        address _nftToken = mNftLps[_pId].nftToken;

        for (uint256 i = 0; i < lenNft; i++) {
            mListNftId[_pId][sender].push(_listId[i]);
            uint256 level = MascotsNFT(_nftToken).getTokenMetadata(_listId[i]).level;
            allocPoint = allocPoint.add(level);
            IERC721(_nftToken).safeTransferFrom(sender, address(this), _listId[i]);
        }

        mRewardPool.depositForNftPool(sender, _pId, allocPoint);
        emit DepositNFT(sender, _pId, _nftToken, _listId);
    }

    function withdrawNFT(uint256 _pId) external virtual {
        require(mNftLps[_pId].typeNft > 0, "NftLiquidityAdapter: is not exist");

        address sender = msg.sender;
        uint256 lenNft = mListNftId[_pId][sender].length;

        require(lenNft > 0, "NftLiquidityAdapter:  zero nft");

        address _nftToken = mNftLps[_pId].nftToken;
        uint256 allocPoint = 0;
        uint256[] memory _listNftId = mListNftId[_pId][sender];
        delete mListNftId[_pId][sender];

        for (uint256 i = 0; i < lenNft; i++) {
            allocPoint = allocPoint.add(MascotsNFT(_nftToken).getTokenMetadata(_listNftId[i]).level);
            IERC721(_nftToken).transferFrom(address(this), sender, _listNftId[i]);
        }

        mRewardPool.withdrawForNftPool(sender, _pId, allocPoint);

        emit WithdrawNFT(sender, _pId, _nftToken, lenNft);
    }

    function claimReward(uint256 _pId) external virtual {
        require(mNftLps[_pId].typeNft > 0, "NftLiquidityAdapter: is not exist");

        address sender = msg.sender;
        mRewardPool.withdrawForNftPool(sender, _pId, 0);

        emit ClaimReward(sender, _pId);
    }

    function emergencyWithdrawForNftPool(uint256 _pId) external {
        require(mNftLps[_pId].typeNft > 0, "NftLiquidityAdapter: is not exist");

        address sender = msg.sender;
        uint256 lenNft = mListNftId[_pId][sender].length;

        require(lenNft > 0, "NftLiquidityAdapter:  zero nft");

        address _nftToken = mNftLps[_pId].nftToken;

        uint256[] memory _listNftId = mListNftId[_pId][sender];

        delete mListNftId[_pId][sender];
        for (uint256 i = 0; i < lenNft; i++) {
            IERC721(_nftToken).transferFrom(address(this), sender, _listNftId[i]);
        }

        mRewardPool.emergencyWithdrawForNftPool(address(this), _pId);

        emit EmergencyWithdrawForNftPool(sender, _pId, _nftToken);
    }

    function approveForSpender(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyGovernance {
        _token.safeApprove(_spender, _amount);
    }

    function safeTokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _tokenBal = IERC20(_token).balanceOf(address(this));
        if (_amount > _tokenBal) {
            _amount = _tokenBal;
        }
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Governance {
    address public governance;
    address private pendingGovernance;
    mapping(address => bool) public minters;

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Governance: !governance");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Governance: !minter");
        _;
    }

    function setGovernance(address governance_) external virtual onlyGovernance {
        require(governance_ != address(0), "Governance: new governance is the zero address");
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(msg.sender == pendingGovernance, "Governance: !pendingGovernance");
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function addMinter(address minter_) external virtual onlyGovernance {
        require(minter_ != address(0), "Governance: minter is the zero address");
        minters[minter_] = true;
    }

    function removeMinter(address minter_) external virtual onlyGovernance {
        require(minter_ != address(0), "Governance: minter is the zero address");
        minters[minter_] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/ERC721.sol";
import "../openzeppelin/Pausable.sol";
import "../openzeppelin/Counters.sol";
import "../openzeppelin/ERC721Enumerable.sol";

// MascotsNFT base on ERC721Enumerable with Governance
contract MascotsNFT is ERC721Enumerable, Pausable {
    using Counters for Counters.Counter;

    address public governance;
    address private pendingGovernance;
    mapping(address => bool) public minters;

    // Auto increase token id
    Counters.Counter private _tokenIdTracker;

    // Base URI of all token
    string public _baseTokenURI;

    struct TokenMetadata {
        string uri;
        string name;
        string image;
        string name_rarity;
        uint256 rarity;
        uint256 level; // 1-(0-99), 2-(100-399), 3-(400-999), 4-(100~)
        uint256 exp; // Experience points
        uint256 createdAt;
    }

    // Mapping from token ID to token metadata
    mapping(uint256 => TokenMetadata) private _tokenMetadatas;

    event IncreaseExp(uint256 tokenId_, uint256 exp);
    event AddNewToken(uint256 tokenId_);
    event RemoveToken(uint256 tokenId_);

    constructor() Pausable() ERC721("Mascots", "MASC") {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "MascotsNFT: !governance");
        _;
    }

    function setGovernance(address governance_)
        external
        virtual
        onlyGovernance
    {
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(
            msg.sender == pendingGovernance,
            "MascotsNFT: !pendingGovernance"
        );
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function addMinter(address minter_) external virtual onlyGovernance {
        minters[minter_] = true;
    }

    function removeMinter(address minter_) external virtual onlyGovernance {
        minters[minter_] = false;
    }

    /**
     * @dev Pauses all token transfers. See {Pausable-_pause}.
     */
    function pause() external virtual onlyGovernance {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. See {Pausable-_unpause}.
     */
    function unpause() external virtual onlyGovernance {
        _unpause();
    }

    function getNextTokenId() external view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function increaseExp(uint256 tokenId_, uint256 amount_) external virtual {
        require(
            msg.sender == governance || minters[msg.sender],
            "MascotsNFT: !governance && !minter"
        );
        require(
            _exists(tokenId_),
            "MascotsNFT: Increase Exp for nonexistent token"
        );
        require(amount_ > 0, "MascotsNFT: !EXP");
        uint256 exp = _tokenMetadatas[tokenId_].exp + amount_;

        _tokenMetadatas[tokenId_].exp = exp;

        emit IncreaseExp(tokenId_, exp);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function setBaseURI(string memory baseURI_)
        external
        virtual
        onlyGovernance
    {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     *
     * See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            "MascotsNFT: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenMetadatas[tokenId_].uri;
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId_);
    }

    /**
     * @dev Sets `tokenURI` for `tokenId`.
     */
    function setTokenURI(uint256 tokenId_, string memory tokenURI_)
        external
        virtual
        onlyGovernance
    {
        require(_exists(tokenId_), "MascotsNFT: URI set of nonexistent token");
        _tokenMetadatas[tokenId_].uri = tokenURI_;
    }

    /**
     * @dev Get token matadata of token id
     */
    function getTokenMetadata(uint256 tokenId_)
        external
        view
        virtual
        returns (TokenMetadata memory)
    {
        require(
            _exists(tokenId_),
            "MascotsNFT: Metadata query for nonexistent token"
        );
        return _tokenMetadatas[tokenId_];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, tokenId_);

        require(!paused(), "MascotsNFT: token transfer while paused");
    }

    /**
     * @dev Creates `amount` new token for `to`. See {ERC721-_safeMint}.
     *
     * Requirements:
     * - the caller must have the governance or minter.
     */
    function mint(
        address to_,
        string memory uri_,
        string memory name_,
        string memory image_,
        string memory name_rarity_,
        uint256 rarity_,
        uint256 level_,
        uint256 exp_
    ) external virtual {
        require(
            msg.sender == governance || minters[msg.sender],
            "MascotsNFT: !governance && !minter"
        );
        require(rarity_ >= 1 && rarity_ <= 6, "MascotsNFT: !rarity");
        require(level_ >= 1 && level_ <= 4, "MascotsNFT: !rarity");

        uint256 id = _tokenIdTracker.current();

        _tokenMetadatas[id] = TokenMetadata({
            uri: uri_,
            name: name_,
            image: image_,
            name_rarity: name_rarity_,
            rarity: rarity_,
            level: level_,
            exp: exp_,
            // solium-disable-next-line security/no-block-members
            createdAt: block.timestamp
        });

        _safeMint(to_, id);

        _tokenIdTracker.increment();

        emit AddNewToken(id);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId_) external virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "MascotsNFT: caller is not owner nor approved"
        );

        delete _tokenMetadatas[tokenId_];

        _burn(tokenId_);

        emit RemoveToken(tokenId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/IERC20.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/EnumerableSet.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Initializable.sol";

import "../ERC20/OxiToken.sol";
import "../interfaces/ILiquidityMigrator.sol";
import "../ContextUpgradeSafe.sol";

/// @title  weekly the governance will mint OXI and send reward to this pool.
/// @author Ken
/// @notice Explain to an end user what this does
contract RewardPool is Initializable, ContextUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public governance;
    address private pendingGovernance;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken; // address for LP token
        uint256 allocPoint; // The allocation point assigned this poll
        uint256 lastRewardBlock; // Last block number Oxi distribution occurs
        uint256 accOxiPerShare; // Accumulated OXIs per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
        bool isNftPool; // pool for NFT
        uint16 depositFee; // Deposit fee in basis points, except nft pool
        uint16 withdrawFee; // withdraw fee in basis points, except nft pool
        uint16 rewardFee; // fee when claim reward
        uint256 timeEmergency; // uint = block;  user will be charged rewardFee if current block withdraw < timeEmergency + block start;
    }

    mapping(uint256 => uint256) mBlockStart; // pool id to block start

    // governance
    address public mOperator;

    address public mNftOperator;

    // The liquidity migrator contract. It has a lot of power. Can only be set through governance (owner).
    ILiquidityMigrator public mMigrator;

    address public mOxi;

    address public mTreasury;

    // oxi tokens created per block.
    uint256 public mOxiPerBlock;

    PoolInfo[] public mPoolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public mUserInfo;

    uint256 public mTotalAllocPoint = 0;

    uint256 public mStartBlock;

    uint256 public mNextHalvingBlock;

    uint256 public constant BLOCKS_PER_DAY = 40696;

    uint256 public constant BLOCKS_PER_WEEK = 284872;

    uint256 public constant BLOCKS_PER_MONTH = 1220880;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event RewardPaid(address indexed user, uint256 amount);

    function _init_(
        address _oxi,
        uint256 _oxiPerBlock,
        uint256 _startBlock,
        address _operator,
        address _treasury
    ) public initializer {
        __Context_init_unchained();

        mOxi = _oxi;
        mOxiPerBlock = _oxiPerBlock;
        mStartBlock = _startBlock;
        mNextHalvingBlock = mStartBlock.add(BLOCKS_PER_MONTH);

        mOperator = _operator;
        mTreasury = _treasury;
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(_msgSender() == governance, "OxiRewardPool: !governance");
        _;
    }

    modifier onlyOperator() {
        require(mOperator == _msgSender(), "OxiRewardPool: caller is not the operator");
        _;
    }

    modifier onlyNftOperator() {
        require(mNftOperator == _msgSender(), "OxiRewardPool: caller is not the mNftOperator");
        _;
    }

    modifier checkHalving() {
        while (block.number >= mNextHalvingBlock) {
            updateAllPools();
            mOxiPerBlock = mOxiPerBlock.mul(9000).div(10000); // x90% (10% decreased every-month)
            mNextHalvingBlock = mNextHalvingBlock.add(BLOCKS_PER_MONTH);
        }
        _;
    }

    function setGovernance(address governance_) external virtual onlyGovernance {
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(_msgSender() == pendingGovernance, "OxiRewardPool: !pendingGovernance");
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function setOperator(address _operator) external onlyGovernance {
        mOperator = _operator;
    }

    function setNftOperator(address _nftOperator) external onlyGovernance {
        mNftOperator = _nftOperator;
    }

    function setTreasury(address _treasury) external onlyOperator {
        mTreasury = _treasury;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(ILiquidityMigrator _migrator) public onlyOperator {
        mMigrator = _migrator;
    }

    function setStartBlock(uint256 _startBlock) public onlyOperator {
        require(mStartBlock < block.number, "OxiRewardPool: pool is working");
        require(_startBlock > block.number, "OxiRewardPool: must > current block");
        mStartBlock = _startBlock;
    }

    // Migrate lp token to another lp contract.
    function migrate(uint256 _pId) public onlyOperator {
        require(block.number >= mStartBlock + BLOCKS_PER_WEEK * 4, "OxiRewardPool: DON'T migrate too soon sir!");
        require(address(mMigrator) != address(0), "OxiRewardPool: no migrator");
        PoolInfo storage pool = mPoolInfo[_pId];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(mMigrator), bal);
        IERC20 newLpToken = mMigrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "OxiRewardPool: migrate error");
        pool.lpToken = newLpToken;
    }

    function poolLength() external view returns (uint256) {
        return mPoolInfo.length;
    }

    function setOxiPerBlock(uint256 _oxiPerBlock) public onlyOperator {
        updateAllPools();
        mOxiPerBlock = _oxiPerBlock;
    }

    function isExistPool(IERC20 _lpToken) internal view {
        uint256 length = mPoolInfo.length;
        for (uint256 pId = 0; pId < length; pId++) {
            require(mPoolInfo[pId].lpToken != _lpToken, "OxiRewardPool: existing pool?");
        }
    }

    function addNewPool(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _lastRewardBlock,
        bool _isNftPool,
        uint16 _depositFee,
        uint16 _withdrawFee,
        uint16 _rewardFee,
        uint256 _timeEmergency
    ) public onlyOperator {
        require(_allocPoint <= 500000, "OxiRewardPool: too high allocation point"); // <= 500x
        require(_depositFee >= 0 && _depositFee <= 2000, "OxiRewardPool: invalid deposit fee"); // <=20%
        require(_withdrawFee >= 0 && _withdrawFee <= 2000, "OxiRewardPool: invalid withdraw fee");
        require(_rewardFee >= 0 && _rewardFee < 2000, "OxiRewardPool: invalid claimReward fee");

        isExistPool(_lpToken);
        updateAllPools();

        if (block.number < mStartBlock) {
            if (_lastRewardBlock == 0 || _lastRewardBlock < mStartBlock) {
                _lastRewardBlock = mStartBlock;
            }
        } else {
            // pool is working
            if (_lastRewardBlock == 0 || _lastRewardBlock < block.number) {
                _lastRewardBlock = block.number;
            }
        }

        bool _isStarted = (_lastRewardBlock <= mStartBlock) || (_lastRewardBlock <= block.number);
        mPoolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: _lastRewardBlock,
                accOxiPerShare: 0,
                isStarted: _isStarted,
                isNftPool: _isNftPool,
                depositFee: _depositFee,
                withdrawFee: _withdrawFee,
                rewardFee: _rewardFee,
                timeEmergency: _timeEmergency
            })
        );
        mBlockStart[mPoolInfo.length.sub(1)] = _lastRewardBlock;
        if (_isStarted) {
            mTotalAllocPoint = mTotalAllocPoint.add(_allocPoint);
        }
    }

    // update reward for all pool.
    function updateAllPools() public checkHalving {
        uint256 length = mPoolInfo.length;
        for (uint256 pId = 0; pId < length; pId++) {
            updatePool(pId);
        }
    }

    function updatePool(uint256 _pid) public checkHalving {
        PoolInfo storage pool = mPoolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            mTotalAllocPoint = mTotalAllocPoint.add(pool.allocPoint);
        }
        if (mTotalAllocPoint > 0) {
            uint256 _generatedReward = getRewardBlocks(pool.lastRewardBlock, block.number).mul(mOxiPerBlock);
            uint256 _oxiReward = _generatedReward.mul(pool.allocPoint).div(mTotalAllocPoint);
            pool.accOxiPerShare = pool.accOxiPerShare.add(_oxiReward.mul(1e18).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }

    // Update the given pool's OXI allocation point. Can only be called by the onlyOperator.
    function updateAllcPoint(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFee,
        uint16 _withdrawFee,
        uint16 _rewardFee
    ) public onlyOperator {
        require(_allocPoint <= 500000, "OxiRewardPool: too high allocation point"); // <= 500x
        require(_depositFee >= 0 && _depositFee <= 2000, "OxiRewardPool: invalid deposit fee");
        require(_withdrawFee >= 0 && _withdrawFee <= 2000, "OxiRewardPool: invalid withdraw fee");
        require(_rewardFee >= 0 && _rewardFee < 2000, "OxiRewardPool: invalid claimReward fee");
        updateAllPools();
        PoolInfo storage pool = mPoolInfo[_pid];
        if (pool.isStarted) {
            mTotalAllocPoint = mTotalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;
        pool.withdrawFee = _withdrawFee;
        pool.rewardFee = _rewardFee;
    }

    function setLastRewardBlock(uint256 _pId, uint256 _lastRewardBlock) public onlyOperator {
        require(!mPoolInfo[_pId].isStarted, "lastRewardBlock has passed");
        require(_lastRewardBlock > block.number, "lastRewardBlock must > current block");
        mPoolInfo[_pId].lastRewardBlock = _lastRewardBlock;
    }

    // Return accumulate rewarded blocks over the given _from to _to block.
    function getRewardBlocks(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_from >= _to) return 0;
        if (_to <= mStartBlock) {
            return 0;
        } else {
            if (_from <= mStartBlock) {
                return _to.sub(mStartBlock);
            } else {
                return _to.sub(_from);
            }
        }
    }

    // View function to see pending OXI on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = mPoolInfo[_pid];
        UserInfo storage user = mUserInfo[_pid][_user];
        uint256 accOxiPerShare = pool.accOxiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 _generatedReward = getRewardBlocks(pool.lastRewardBlock, block.number).mul(mOxiPerBlock);
            uint256 _oxiReward = _generatedReward.mul(pool.allocPoint).div(mTotalAllocPoint);
            accOxiPerShare = accOxiPerShare.add(_oxiReward.mul(1e18).div(lpSupply));
        }

        uint256 _pendingReward = user.amount.mul(accOxiPerShare).div(1e18).sub(user.rewardDebt);
        if (pool.rewardFee > 0) {
            uint256 _rewardFee = _pendingReward.mul(pool.rewardFee).div(10000);
            _pendingReward = _pendingReward.sub(_rewardFee);
        }

        return _pendingReward;
    }

    function harvestReward(uint256 _pId, address _account) internal {
        PoolInfo storage pool = mPoolInfo[_pId];
        UserInfo storage user = mUserInfo[_pId][_account];
        uint256 _pendingReward = user.amount.mul(pool.accOxiPerShare).div(1e18).sub(user.rewardDebt);

        if (_pendingReward > 0) {
            if (pool.rewardFee > 0) {
                uint256 _rewardFee = _pendingReward.mul(pool.rewardFee).div(10000);
                _pendingReward = _pendingReward.sub(_rewardFee);
                safeOxiMint(mTreasury, _rewardFee);
            }

            safeOxiMint(_account, _pendingReward);
            emit RewardPaid(_account, _pendingReward);
        }
    }

    // Deposit LP tokens to OxiFactory for Oxi allocation.
    function deposit(uint256 _pId, uint256 _amount) external checkHalving {
        address _sender = _msgSender();
        PoolInfo storage pool = mPoolInfo[_pId];
        require(!pool.isNftPool, "OxiRewardPool: Nft pool");
        UserInfo storage user = mUserInfo[_pId][_sender];

        updatePool(_pId);

        if (user.amount > 0) {
            harvestReward(_pId, _sender);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_sender, address(this), _amount);

            if (pool.depositFee > 0) {
                uint256 _depositFee = _amount.mul(pool.depositFee).div(10000);
                user.amount = user.amount.add(_amount).sub(_depositFee);
                pool.lpToken.safeTransfer(mTreasury, _depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accOxiPerShare).div(1e18);
        emit Deposit(_sender, _pId, _amount);
    }

    // only nft operator
    function depositForNftPool(
        address _receiver,
        uint256 _pId,
        uint256 _amount
    ) external checkHalving onlyNftOperator {
        address _sender = _msgSender();
        PoolInfo storage pool = mPoolInfo[_pId];
        require(pool.isNftPool, "OxiRewardPool: Not Nft pool");
        UserInfo storage user = mUserInfo[_pId][_receiver];

        updatePool(_pId);

        if (user.amount > 0) {
            harvestReward(_pId, _receiver);
        }
        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            pool.lpToken.safeTransferFrom(_sender, address(this), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accOxiPerShare).div(1e18);
        emit Deposit(_receiver, _pId, _amount);
    }

    function withdraw(uint256 _pId, uint256 _amount) external checkHalving {
        address _sender = _msgSender();
        PoolInfo storage pool = mPoolInfo[_pId];
        require(!pool.isNftPool, "OxiRewardPool: Nft pool");
        UserInfo storage user = mUserInfo[_pId][_sender];

        require(user.amount >= _amount, "OxiRewardPool: withdraw !amount");

        updatePool(_pId);
        harvestReward(_pId, _sender);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (pool.withdrawFee > 0 && block.number <= (pool.timeEmergency + mBlockStart[_pId])) {
                uint256 _withdrawFee = _amount.mul(pool.withdrawFee).div(10000);
                _amount = _amount.sub(_withdrawFee);
                pool.lpToken.safeTransfer(mTreasury, _withdrawFee);
            }
            pool.lpToken.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accOxiPerShare).div(1e18);

        emit Withdraw(_sender, _pId, _amount);
    }

    // only nft operator
    function withdrawForNftPool(
        address _receiver,
        uint256 _pId,
        uint256 _amount
    ) external checkHalving onlyNftOperator {
        address _sender = _msgSender();
        PoolInfo storage pool = mPoolInfo[_pId];
        require(pool.isNftPool, "OxiRewardPool: Not Nft pool");
        UserInfo storage user = mUserInfo[_pId][_receiver];

        require(user.amount >= _amount, "OxiRewardPool: withdraw !amount");

        updatePool(_pId);
        harvestReward(_pId, _receiver);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accOxiPerShare).div(1e18);

        emit Withdraw(_receiver, _pId, _amount);
    }

    function safeOxiMint(address _to, uint256 _amount) internal {
        if (OxiToken(mOxi).minters(address(this)) && _to != address(0)) {
            uint256 _totalSupply = IERC20(mOxi).totalSupply();
            uint256 _cap = OxiToken((mOxi)).cap();
            uint256 _mintAmount = (_totalSupply.add(_amount) <= _cap) ? _amount : _cap.sub(_totalSupply);
            if (_mintAmount > 0) {
                OxiToken((mOxi)).mint(address(this), _mintAmount);
                IERC20(mOxi).safeTransfer(_to, _mintAmount);
            }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pId) external checkHalving {
        PoolInfo storage pool = mPoolInfo[_pId];
        require(!pool.isNftPool, "OxiRewardPool: Nft pool");
        UserInfo storage user = mUserInfo[_pId][_msgSender()];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        if (_amount > 0) {
            if (pool.withdrawFee > 0 && block.number <= (pool.timeEmergency + mBlockStart[_pId])) {
                uint256 _withdrawFee = _amount.mul(pool.withdrawFee).div(10000);
                _amount = _amount.sub(_withdrawFee);
                pool.lpToken.safeTransfer(mTreasury, _withdrawFee);
            }
        }
        pool.lpToken.safeTransfer(_msgSender(), _amount);
        emit EmergencyWithdraw(_msgSender(), _pId, _amount);
    }

    function emergencyWithdrawForNftPool(address _receiver, uint256 _pid) external checkHalving onlyNftOperator {
        PoolInfo storage pool = mPoolInfo[_pid];
        require(!pool.isNftPool, "OxiRewardPool: Nft pool");
        UserInfo storage user = mUserInfo[_pid][_receiver];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(_msgSender(), _amount);
        emit EmergencyWithdraw(_receiver, _pid, _amount);
    }

    // Safe oxi transfer function, just in case if rounding error causes pool to not have enough OXI.
    function safeTokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _tokenBal = IERC20(_token).balanceOf(address(this));
        if (_amount > _tokenBal) {
            _amount = _tokenBal;
        }
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    // This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        if (block.number < mStartBlock + BLOCKS_PER_WEEK * 104) {
            // do not allow to drain lpToken if less than 2 years
            uint256 length = mPoolInfo.length;
            for (uint256 pId = 0; pId < length; pId++) {
                PoolInfo storage pool = mPoolInfo[pId];
                // cant take staked asset
                require(_token != pool.lpToken, "OxiRewardPool: !pool.lpToken");
            }
        }
        _token.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/ERC20.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Pausable.sol";

// LP token represent NFT
contract ERC20NftLiquidityToken is ERC20, Pausable {
    using SafeMath for uint256;
    address private governance;
    address private pendingGovernance;

    mapping(address => bool) private minters;

    constructor(string memory _name, string memory _symbol) Pausable() ERC20(_name, _symbol) {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "ERC20NftLiquidityToken: !governance");
        _;
    }

    function setGovernance(address governance_) external virtual onlyGovernance {
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(msg.sender == pendingGovernance, "ERC20NftLiquidityToken: !pendingGovernance");
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function addMinter(address minter_) external virtual onlyGovernance {
        minters[minter_] = true;
    }

    function removeMinter(address minter_) external virtual onlyGovernance {
        minters[minter_] = false;
    }

    /**
     * @dev Pauses all token transfers. See {Pausable-_pause}.
     *
     * Requirements:
     * - the caller must be the governance.
     */
    function pause() external virtual onlyGovernance {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. See {Pausable-_unpause}.
     *
     * Requirements:
     * - the caller must be the governance.
     */
    function unpause() external virtual onlyGovernance {
        _unpause();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, amount_);

        require(!paused(), "ERC20NftLiquidityToken: token transfer while paused");
    }

    /**
     * @dev Creates `amount` new tokens for `to`. See {ERC20-_mint}.
     *
     * Requirements:
     * - the caller must have the governance or minter.
     */
    function mint(address to_, uint256 amount_) external virtual {
        require(msg.sender == governance || minters[msg.sender], "ERC20NftLiquidityToken: !governance && !minter");

        _mint(to_, amount_);
    }

    /**
     * @dev Destroys `amount` tokens from the caller. See {ERC20-_burn}.
     */
    function burn(uint256 amount_) external virtual {
        _burn(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
        require(_initializing || isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/Initializable.sol";

contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

pragma solidity ^0.8.0;

import "./IERC721.sol";

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
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
pragma solidity ^0.8.0;

import "../openzeppelin/ERC20.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Pausable.sol";

// GRBEToken with Governance
contract OxiToken is ERC20, Pausable {
    using SafeMath for uint256;

    address private governance;
    address private pendingGovernance;
    mapping(address => bool) public minters;

    // max amount token: 1 billion
    uint256 public cap = 1000000000 ether;

    constructor() Pausable() ERC20("OXI", "OXI") {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "OxiToken: !governance");
        _;
    }

    function setGovernance(address governance_) external virtual onlyGovernance {
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(msg.sender == pendingGovernance, "OxiToken: !pendingGovernance");
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function addMinter(address minter_) external virtual onlyGovernance {
        minters[minter_] = true;
    }

    function removeMinter(address minter_) external virtual onlyGovernance {
        minters[minter_] = false;
    }

    function setCap(uint256 _cap) external onlyGovernance {
        require(_cap >= totalSupply(), "_cap is below current total supply");
        cap = _cap;
    }

    /**
     * @dev Pauses all token transfers. See {Pausable-_pause}.
     *
     * Requirements:
     * - the caller must be the governance.
     */
    function pause() external virtual onlyGovernance {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. See {Pausable-_unpause}.
     *
     * Requirements:
     * - the caller must be the governance.
     */
    function unpause() external virtual onlyGovernance {
        _unpause();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, amount_);

        require(!paused(), "OxiToken: token transfer while paused");
    }

    /**
     * @dev Creates `amount` new tokens for `to`. See {ERC20-_mint}.
     *
     * Requirements:
     * - the caller must have the governance or minter.
     */
    function mint(address to_, uint256 amount_) external virtual {
        require(msg.sender == governance || minters[msg.sender], "OxiToken: !governance && !minter");
        _mint(to_, amount_);
    }

    /**
     * @dev Destroys `amount` tokens from the caller. See {ERC20-_burn}.
     */
    function burn(uint256 amount_) external virtual {
        _burn(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/IERC20.sol";

interface ILiquidityMigrator {
    function migrate(IERC20 token) external returns (IERC20);
}

