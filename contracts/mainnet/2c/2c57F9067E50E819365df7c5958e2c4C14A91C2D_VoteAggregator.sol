// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../common/Constants.sol";

interface IGROVesting {
    function vestedBalance(address account) external view returns (uint256);

    function vestingBalance(address account) external view returns (uint256);
}

interface IGROBaseVesting {
    function totalBalance(address account) external view returns (uint256);

    function vestedBalance(address account) external view returns (uint256 vested, uint256 available);
}

struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
}

interface IGROStaker {
    function userInfo(uint256 poolId, address account) external view returns (UserInfo memory);
}

interface IUniswapV2Pool {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface IBalanceVault {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

interface IBalanceV2Pool {
    function getVault() external view returns (IBalanceVault);

    function getPoolId() external view returns (bytes32);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract VoteAggregator is Ownable, Constants {
    IERC20 public immutable GRO;
    IGROVesting public immutable MAIN_VESTING;
    IGROBaseVesting public immutable EMP_VESTINGS;
    IGROBaseVesting public immutable INV_VESTINGS;
    IGROStaker public immutable STAKER;

    // Make 0 pool in staker for single gro always
    uint256 public constant SINGLE_GRO_POOL_ID = 0;

    IUniswapV2Pool[] public uniV2Pools;
    IBalanceV2Pool[] public balV2Pools;

    // weight decimals is 4
    uint256 public groWeight;
    mapping(address => uint256[2]) public vestingWeights;
    mapping(address => uint256[]) public lpWeights;

    mapping(address => uint256) public groPools;

    event LogSetGroWeight(uint256 newWeight);
    event LogSetVestingWeight(address indexed vesting, uint256 newLockedWeight, uint256 newUnlockedWeight);
    event LogAddUniV2Pool(address pool, uint256[] weights, uint256 groPoolId);
    event LogRemoveUniV2Pool(address pool);
    event LogAddBalV2Pool(address pool, uint256[] weights, uint256 groPoolId);
    event LogRemoveBalV2Pool(address pool);
    event LogSetLPPool(address indexed pool, uint256[] weights, uint256 groPoolId);

    constructor(
        address gro,
        address mainVesting,
        address empVesting,
        address invVesting,
        address staker
    ) {
        GRO = IERC20(gro);
        MAIN_VESTING = IGROVesting(mainVesting);
        EMP_VESTINGS = IGROBaseVesting(empVesting);
        INV_VESTINGS = IGROBaseVesting(invVesting);
        STAKER = IGROStaker(staker);
    }

    function setGroWeight(uint256 weight) external onlyOwner {
        groWeight = weight;
        emit LogSetGroWeight(weight);
    }

    function setVestingWeight(
        address vesting,
        uint256 lockedWeight,
        uint256 unlockedWeight
    ) external onlyOwner {
        vestingWeights[vesting][0] = lockedWeight;
        vestingWeights[vesting][1] = unlockedWeight;
        emit LogSetVestingWeight(vesting, lockedWeight, unlockedWeight);
    }

    function addUniV2Pool(
        address pool,
        uint256[] calldata weights,
        uint256 groPoolId
    ) external onlyOwner {
        lpWeights[pool] = weights;
        groPools[pool] = groPoolId;
        uniV2Pools.push(IUniswapV2Pool(pool));
        emit LogAddUniV2Pool(pool, weights, groPoolId);
    }

    function removeUniV2Pool(address pool) external onlyOwner {
        uint256 len = uniV2Pools.length;
        bool find;
        for (uint256 i = 0; i < len - 1; i++) {
            if (find) {
                uniV2Pools[i] = uniV2Pools[i + 1];
            } else {
                if (pool == address(uniV2Pools[i])) {
                    find = true;
                    uniV2Pools[i] = uniV2Pools[i + 1];
                }
            }
        }
        uniV2Pools.pop();
        delete lpWeights[pool];
        delete groPools[pool];
        emit LogRemoveUniV2Pool(pool);
    }

    function addBalV2Pool(
        address pool,
        uint256[] calldata weights,
        uint256 groPoolId
    ) external onlyOwner {
        lpWeights[pool] = weights;
        groPools[pool] = groPoolId;
        balV2Pools.push(IBalanceV2Pool(pool));
        emit LogAddBalV2Pool(pool, weights, groPoolId);
    }

    function removeBalV2Pool(address pool) external onlyOwner {
        uint256 len = balV2Pools.length;
        bool find;
        for (uint256 i = 0; i < len - 1; i++) {
            if (find) {
                balV2Pools[i] = balV2Pools[i + 1];
            } else {
                if (pool == address(balV2Pools[i])) {
                    find = true;
                    balV2Pools[i] = balV2Pools[i + 1];
                }
            }
        }
        balV2Pools.pop();
        delete lpWeights[pool];
        delete groPools[pool];
        emit LogRemoveBalV2Pool(pool);
    }

    function setLPPool(
        address pool,
        uint256[] calldata weights,
        uint256 groPoolId
    ) external onlyOwner {
        if (weights.length > 0) {
            lpWeights[pool] = weights;
        }
        if (groPoolId > 0) {
            groPools[pool] = groPoolId;
        }
        emit LogSetLPPool(pool, weights, groPoolId);
    }

    function balanceOf(address account) external view returns (uint256 value) {
        // calculate gro weight amount

        uint256 amount = GRO.balanceOf(account);
        UserInfo memory ui = STAKER.userInfo(SINGLE_GRO_POOL_ID, account);
        amount += ui.amount;
        value = (amount * groWeight) / PERCENTAGE_DECIMAL_FACTOR;

        // calculate vesting weight amount

        // vestings[0] - main vesting address
        // vestings[1] - employee vesting address
        // vestings[2] - investor vesting address
        address[3] memory vestings;
        // amounts[0][0] - main vesting locked amount
        // amounts[0][1] - main vesting unlocked amount
        // amounts[1][0] - employee vesting locked amount
        // amounts[1][1] - employee vesting unlocked amount
        // amounts[2][0] - investor vesting locked amount
        // amounts[2][1] - investor vesting unlocked amount
        uint256[2][3] memory amounts;

        vestings[0] = address(MAIN_VESTING);
        amounts[0][0] = MAIN_VESTING.vestingBalance(account);
        amounts[0][1] = MAIN_VESTING.vestedBalance(account);

        amounts[1][0] = EMP_VESTINGS.totalBalance(account);
        if (amounts[1][0] > 0) {
            (amounts[1][1], ) = EMP_VESTINGS.vestedBalance(account);
            amounts[1][0] = amounts[1][0] - amounts[1][1];
            vestings[1] = address(EMP_VESTINGS);
        }

        amounts[2][0] = INV_VESTINGS.totalBalance(account);
        if (amounts[2][0] > 0) {
            (amounts[2][1], ) = INV_VESTINGS.vestedBalance(account);
            amounts[2][0] = amounts[2][0] - amounts[2][1];
            vestings[2] = address(INV_VESTINGS);
        }

        for (uint256 i = 0; i < vestings.length; i++) {
            if (amounts[i][0] > 0 || amounts[i][1] > 0) {
                uint256[2] storage weights = vestingWeights[vestings[i]];
                uint256 lockedWeight = weights[0];
                uint256 unlockedWeight = weights[1];
                value += (amounts[i][0] * lockedWeight + amounts[i][1] * unlockedWeight) / PERCENTAGE_DECIMAL_FACTOR;
            }
        }

        value += calculateUniWeight(account);
        value += calculateBalWeight(account);
    }

    function calculateUniWeight(address account) public view returns (uint256 uniValue) {
        uint256 len = uniV2Pools.length;
        for (uint256 i = 0; i < len; i++) {
            IUniswapV2Pool pool = uniV2Pools[i];
            uint256 lpAmount = pool.balanceOf(account);
            lpAmount += getLPAmountInStaker(address(pool), account);

            if (lpAmount > 0) {
                (uint112 res0, uint112 res1, ) = pool.getReserves();
                uint256 ts = pool.totalSupply();
                uint256[] memory amounts = new uint256[](2);
                amounts[0] = res0;
                amounts[1] = res1;
                address[] memory tokens = new address[](2);
                tokens[0] = pool.token0();
                tokens[1] = pool.token1();
                uint256[] memory weights = lpWeights[address(pool)];

                uniValue += calculateLPWeightValue(amounts, lpAmount, ts, tokens, weights);
            }
        }
    }

    function calculateBalWeight(address account) public view returns (uint256 balValue) {
        uint256 len = balV2Pools.length;
        for (uint256 i = 0; i < len; i++) {
            IBalanceV2Pool pool = balV2Pools[i];
            uint256 lpAmount = pool.balanceOf(account);
            lpAmount += getLPAmountInStaker(address(pool), account);

            if (lpAmount > 0) {
                IBalanceVault vault = pool.getVault();
                bytes32 poolId = pool.getPoolId();
                (address[] memory tokens, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
                uint256 ts = pool.totalSupply();
                uint256[] memory weights = lpWeights[address(pool)];

                balValue += calculateLPWeightValue(balances, lpAmount, ts, tokens, weights);
            }
        }
    }

    function getUniV2Pools() external view returns (IUniswapV2Pool[] memory) {
        return uniV2Pools;
    }

    function getBalV2Pools() external view returns (IBalanceV2Pool[] memory) {
        return balV2Pools;
    }

    function getVestingWeights(address vesting) external view returns (uint256[2] memory) {
        return vestingWeights[vesting];
    }

    function getLPWeights(address pool) external view returns (uint256[] memory) {
        return lpWeights[pool];
    }

    function getLPAmountInStaker(address lpPool, address account) private view returns (uint256 amount) {
        uint256 poolId = groPools[lpPool];
        if (poolId > 0) {
            UserInfo memory ui = STAKER.userInfo(poolId, account);
            amount = ui.amount;
        }
    }

    function calculateLPWeightValue(
        uint256[] memory tokenAmounts,
        uint256 lpAmount,
        uint256 lpTotalSupply,
        address[] memory tokens,
        uint256[] memory weights
    ) private view returns (uint256 value) {
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            uint256 amount = (tokenAmounts[i] * lpAmount) / lpTotalSupply;
            uint256 decimals = ERC20(tokens[i]).decimals();
            uint256 weight = weights[i];

            value += (amount * weight * DEFAULT_DECIMALS_FACTOR) / (uint256(10)**decimals) / PERCENTAGE_DECIMAL_FACTOR;
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

contract Constants {
    uint8 internal constant N_COINS = 3;
    uint8 internal constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 internal constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 internal constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 internal constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 internal constant PERCENTAGE_DECIMALS = 4;
    uint256 internal constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 internal constant CURVE_RATIO_DECIMALS = 6;
    uint256 internal constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
    uint256 internal constant ONE_YEAR_SECONDS = 31556952; // average year (including leap years) in seconds
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