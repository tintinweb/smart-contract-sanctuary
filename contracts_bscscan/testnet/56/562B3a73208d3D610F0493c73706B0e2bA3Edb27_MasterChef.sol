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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import './ZoinksToken.sol';
import './ShaggyToken.sol';
import './ScoobyToken.sol';

interface IMigratorChef {
    // Perform LP token migration from legacy PancakeSwap to CakeSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PancakeSwap LP tokens.
    // CakeSwap must mint EXACTLY the same amount of CakeSwap LP tokens or
    // else something bad will happen. Traditional PancakeSwap does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

contract MasterChef is Ownable {
    
    // Info of each user
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided
        uint256 zoinksRewardDebt;
        uint256 shaggyRewardDebt;
        uint256 scoobyRewardDebt;
    }

    // Info of each pool
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 zoinksAllocPoint; // How many allocation points assigned to this pool.
        uint256 shaggyAllocPoint; // How many allocation points assigned to this pool.
        uint256 scoobyAllocPoint; // How many allocation points assigned to this pool.
        uint256 zoinksLastRewardBlock; // Last block number that cakes distribution occurs.
        uint256 shaggyLastRewardBlock; // Last block number that cakes distribution occurs.
        uint256 scoobyLastRewardBlock; // Last block number that cakes distribution occurs.
        uint256 accZoinksPerShare; // Accumulated Zoinks per share. 
        uint256 accShaggyPerShare; // Accumulated Shaggy per share.
        uint256 accScoobyPerShare; // Accumulated Shaggy per share. 
    }

    // Zoinks Token!
    ZoinksToken public zoinks;

    // Scooby Token!
    ScoobyToken public scooby;

    // Shaggy Token!
    ShaggyToken public shaggy;

    // Dev Address.
    address public devAddr;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Scooby tokens created per block.
    uint256 public scoobyPerBlock = 100;

    // Shaggy tokens created per block.
    uint256 public shaggyPerBlock = 100;

    // Info of each pool
    PoolInfo[] public poolInfo;

    // Info of each user that statek LP tokens
    mapping(uint256 => mapping (address => UserInfo)) public userInfo;

    // Zoinks Total allocation Points. Must be the sum of all zoinks allocation points in all pools.
    uint256 public zoinksTotalAllocPoint = 0;

    // Scooby Total allocation Points. Must be the sum of all scooby allocation points in all pools.
    uint256 public scoobyTotalAllocPoint = 0;

    // Shaggy Total allocation Points. Must be the sum of all shaggy allocation points in all pools.
    uint256 public shaggyTotalAllocPoint = 0;
    
    // The block number when mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // constructor() public {}

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _zoinksAllocPoint,
        uint256 _scoobyAllocPoint,
        uint256 _shaggyAllocPoint,
        IBEP20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if(_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        zoinksTotalAllocPoint += _zoinksAllocPoint;
        scoobyTotalAllocPoint += _scoobyAllocPoint;
        shaggyTotalAllocPoint += _shaggyAllocPoint;

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            zoinksAllocPoint: _zoinksAllocPoint,
            scoobyAllocPoint: _scoobyAllocPoint,
            shaggyAllocPoint: _shaggyAllocPoint,
            zoinksLastRewardBlock: lastRewardBlock,
            scoobyLastRewardBlock: lastRewardBlock,
            shaggyLastRewardBlock: lastRewardBlock,
            accZoinksPerShare: 0,
            accShaggyPerShare: 0,
            accScoobyPerShare: 0
        }));
        updateStakingPool();
    }

    function set(
        uint256 _pid,
        uint256 _zoinksAllocPoint,
        uint256 _shaggyAllocPoint,
        uint256 _scoobyAllocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) massUpdatePools();

        uint256 prevZoinksAllocPoint = poolInfo[_pid].zoinksAllocPoint;
        uint256 prevShaggyAllocPoint = poolInfo[_pid].shaggyAllocPoint;
        uint256 prevScoobyAllocPoint = poolInfo[_pid].scoobyAllocPoint;
        poolInfo[_pid].zoinksAllocPoint = _zoinksAllocPoint;
        poolInfo[_pid].shaggyAllocPoint = _shaggyAllocPoint;
        poolInfo[_pid].scoobyAllocPoint = _scoobyAllocPoint;

        if(prevZoinksAllocPoint != _zoinksAllocPoint && prevShaggyAllocPoint != _shaggyAllocPoint && prevScoobyAllocPoint != _scoobyAllocPoint) {
            updateStakingPool();
        } else {
            if (prevZoinksAllocPoint != _zoinksAllocPoint) {
                zoinksTotalAllocPoint = zoinksTotalAllocPoint - prevZoinksAllocPoint + _zoinksAllocPoint;
                updateZoinksStakingPool();
            }

            if (prevShaggyAllocPoint != _shaggyAllocPoint) {
                shaggyTotalAllocPoint = shaggyTotalAllocPoint - prevShaggyAllocPoint + _shaggyAllocPoint;
                updateShaggyStakingPool();
            }

            if (prevScoobyAllocPoint != _scoobyAllocPoint) {
                scoobyTotalAllocPoint = scoobyTotalAllocPoint - prevScoobyAllocPoint + _scoobyAllocPoint;
                updateScoobyStakingPool();
            }
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 zoinksPoints = 0;
        uint256 shaggyPoints = 0;
        uint256 scoobyPoints = 0;

        for (uint256 pid = 1; pid < length; pid ++)
        {
            zoinksPoints = zoinksPoints + poolInfo[pid].zoinksAllocPoint;
            shaggyPoints = shaggyPoints + poolInfo[pid].shaggyAllocPoint;
            scoobyPoints = scoobyPoints + poolInfo[pid].scoobyAllocPoint;
        }

        if (zoinksPoints != 0) {
            zoinksTotalAllocPoint = zoinksTotalAllocPoint - poolInfo[0].zoinksAllocPoint + zoinksPoints;
            poolInfo[0].zoinksAllocPoint = zoinksPoints;
        }

        if (shaggyPoints != 0) {
            zoinksTotalAllocPoint = zoinksTotalAllocPoint - poolInfo[0].zoinksAllocPoint + shaggyPoints;
            poolInfo[0].shaggyAllocPoint = shaggyPoints;
        }

        if (scoobyPoints != 0) {
            scoobyTotalAllocPoint = scoobyTotalAllocPoint - poolInfo[0].scoobyAllocPoint + scoobyPoints;
            poolInfo[0].scoobyAllocPoint = scoobyPoints;
        }
    }

    function updateZoinksStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;

        for (uint256 pid = 1; pid < length; pid ++)
        {
            points = points + poolInfo[pid].zoinksAllocPoint;
        }

        if (points != 0) {
            zoinksTotalAllocPoint = zoinksTotalAllocPoint - poolInfo[0].zoinksAllocPoint + points;
            poolInfo[0].zoinksAllocPoint = points;
        }
    }

    function updateShaggyStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;

        for (uint256 pid = 1; pid < length; pid ++)
        {
            points = points + poolInfo[pid].shaggyAllocPoint;
        }

        if (points != 0) {
            shaggyTotalAllocPoint = shaggyTotalAllocPoint - poolInfo[0].shaggyAllocPoint + points;
            poolInfo[0].shaggyAllocPoint = points;
        }
    }

    function updateScoobyStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;

        for (uint256 pid = 1; pid < length; pid ++)
        {
            points = points + poolInfo[pid].scoobyAllocPoint;
        }

        if (points != 0) {
            scoobyTotalAllocPoint = scoobyTotalAllocPoint - poolInfo[0].scoobyAllocPoint + points;
            poolInfo[0].scoobyAllocPoint = points;
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust the migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        // lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        uint256 multiplier = _to - _from;
        return multiplier;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for(uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    // Update Reward variables of the given pool to be up-to-date
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        // if(block.number < pool.lastRewardBlock) return;

        uint256 accZoinksSupply = pool.accZoinksPerShare;
        uint256 accShaggySupply = pool.accShaggyPerShare;
        uint256 accScoobySupply = pool.accScoobyPerShare;

        if(accZoinksSupply == 0) {
            pool.zoinksLastRewardBlock = block.number;
            return;
        } else {
            uint256 multiplier = getMultiplier(pool.zoinksLastRewardBlock, block.number);
            uint256 zoinksReward = multiplier * pool.accZoinksPerShare * pool.zoinksAllocPoint / zoinksTotalAllocPoint;

            pool.accZoinksPerShare = pool.accZoinksPerShare + zoinksReward * (1e12) / accZoinksSupply;
            pool.zoinksLastRewardBlock = block.number;
        }

        if(accShaggySupply == 0) {
            pool.shaggyLastRewardBlock = block.number;
            return;
        } else {
            uint256 multiplier = getMultiplier(pool.shaggyLastRewardBlock, block.number);
            uint256 shaggyReward = multiplier * pool.accShaggyPerShare * pool.shaggyAllocPoint / shaggyTotalAllocPoint;

            shaggy.mintToRewardPools();

            pool.accShaggyPerShare = pool.accShaggyPerShare + shaggyReward * (1e12) / accShaggySupply;
            pool.shaggyLastRewardBlock = block.number;
        }

        if(accScoobySupply == 0) {
            pool.scoobyLastRewardBlock = block.number;
            return;
        } else {
            uint256 multiplier = getMultiplier(pool.scoobyLastRewardBlock, block.number);
            uint256 scoobyReward = multiplier * pool.accScoobyPerShare * pool.scoobyAllocPoint / scoobyTotalAllocPoint;

            scooby.mintToRewardPools();

            pool.accScoobyPerShare = pool.accScoobyPerShare + scoobyReward * (1e12) / accScoobySupply;
            pool.scoobyLastRewardBlock = block.number;
        }
    }

    // Deposit LP tokens
    function deposit(uint256 _pid, uint256 _amount) public {
        require(_pid != 0, 'deposit by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if(user.amount > 0) {
            uint256 zoinksPending = user.amount * pool.accZoinksPerShare / (1e12) - user.zoinksRewardDebt;
            if(zoinksPending > 0) {
                zoinks.transferFrom(address(this), msg.sender, zoinksPending);
            }

            uint256 shaggyPending = user.amount * pool.accShaggyPerShare / (1e12) - user.shaggyRewardDebt;
            if(shaggyPending > 0) {
                shaggy.transferFrom(address(this), msg.sender, shaggyPending);
            }

            uint256 scoobyPending = user.amount * pool.accScoobyPerShare / (1e12) - user.scoobyRewardDebt;
            if(scoobyPending > 0) {
                scooby.transferFrom(address(this), msg.sender, scoobyPending);
            }
        }

        if (_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
        }

        user.zoinksRewardDebt = user.amount * pool.accZoinksPerShare / (1e12);
        user.shaggyRewardDebt = user.amount * pool.accShaggyPerShare / (1e12);
        user.scoobyRewardDebt = user.amount * pool.accScoobyPerShare / (1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, 'withdraw zoinks by unstaking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 zoinksPending = user.amount * pool.accZoinksPerShare / (1e12) - user.zoinksRewardDebt;

        if(zoinksPending > 0) {
            zoinks.transferFrom(address(this), msg.sender, zoinksPending);
        }

        uint256 shaggyPending = user.amount * pool.accShaggyPerShare / (1e12) - user.shaggyRewardDebt;

        if(shaggyPending > 0) {
            shaggy.transferFrom(address(this), msg.sender, shaggyPending);
        }

        uint256 scoobyPending = user.amount * pool.accScoobyPerShare / (1e12) - user.scoobyRewardDebt;

        if(scoobyPending > 0) {
            scooby.transferFrom(address(this), msg.sender, scoobyPending);
        }

        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        user.zoinksRewardDebt = user.amount * pool.accZoinksPerShare / (1e12);
        user.shaggyRewardDebt = user.amount * pool.accShaggyPerShare / (1e12);
        user.scoobyRewardDebt = user.amount * pool.accScoobyPerShare / (1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        pool.lpToken.transfer(address(msg.sender), user.amount);

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.zoinksRewardDebt = 0;
        user.shaggyRewardDebt = 0;
        user.scoobyRewardDebt = 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ScoobyToken is ERC20, Ownable {

    /// @dev total Supply of scoobyToken
    uint256 private _totalSupply = 5000000;

    /// @dev initial supply of scoobytoken
    uint256 public constant INITIAL_SCOOBY_SUPPLY = 5000000;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public tokensPerBlock = 100;
    address public tokenContractAddress = address(this);

    struct RewardPools {
        address accountAddress;
        uint256 percentage;
    }

    RewardPools[] public rewardPools;

    constructor() ERC20("SCOOBY", "SCOOBY") {}

    function mint(address _address, uint256 _amount) public onlyOwner {
        _mint(_address, _amount);
    }

    function setRewardPool(address _account, uint256 _percentage) public onlyOwner {
        if(rewardPools.length <= 7) {
            RewardPools memory rewardPool;
            rewardPool.accountAddress = _account;
            rewardPool.percentage = _percentage;
            rewardPools.push(rewardPool);
        }
    }

    function mintToRewardPools() public onlyOwner {
        if(block.number % 100000 == 0 && tokensPerBlock != 5) tokensPerBlock -= 5;

        for(uint256 i = 0; i < rewardPools.length; i++) {
            uint256 amount = tokensPerBlock * rewardPools[i].percentage / 100;
            _mint(rewardPools[i].accountAddress, amount);
        }
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShaggyToken is ERC20, Ownable {

    /// @dev total Supply of shaggyToken
    uint256 private _totalSupply = 5000000;

    /// @dev initial supply of shaggytoken
    uint256 public constant INITIAL_SHAGGY_SUPPLY = 5000000;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public tokensPerBlock = 100;
    address public tokenContractAddress = address(this);

    struct RewardPools {
        address accountAddress;
        uint256 percentage;
    }

    RewardPools[] public rewardPools;

    constructor() ERC20("SHAGGY", "SHAGGY") {}

    function mint(address _address, uint256 _amount) public onlyOwner {
        _mint(_address, _amount);
    }

    function setRewardPool(address _account, uint256 _percentage) public onlyOwner {
        if(rewardPools.length <= 7) {
            RewardPools memory rewardPool;
            rewardPool.accountAddress = _account;
            rewardPool.percentage = _percentage;
            rewardPools.push(rewardPool);
        }
    }

    function mintToRewardPools() public onlyOwner {
        if(block.number % 100000 == 0 && tokensPerBlock != 5) tokensPerBlock -= 5;

        for(uint256 i = 0; i < rewardPools.length; i++) {
            uint256 amount = tokensPerBlock * rewardPools[i].percentage / 100;
            _mint(rewardPools[i].accountAddress, amount);
        }
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZoinksToken is ERC20, Ownable {

    /// @dev The total number of tokens in circulation
    uint256 private _totalSupply;

    /// @dev initial supply of zoinkstoken
    uint256 public constant INITIAL_ZOINKS_SUPPLY = 35000000000000;

    /// @dev initial LP of zoinks/busd for liquidity
    uint256 public constant INITIAL_ZOINKS_LIQUIDITY_SUPPLY = 1000;

    /// @dev The circulation value
    uint256 private _circulationSupply = 0;

    /// @dev the rebase contract address
    address private _rebaseContract;

    /// @dev Official percent of zoinks token balances for each account
    mapping (address => uint256) private _balances;

    /// @dev Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) private _allowances;

    struct InflationRewards {
        address accountAddress;
        uint256 percentage;
    }

    InflationRewards[] public inflationRewards;

    /**
     * @notice Construct a new Zoinks token
     */

    constructor() ERC20("ZOINKS", "ZOINKS") {}

    modifier onlyRebaseContract() {
        require(_rebaseContract == msg.sender, "not rebase contract");
        _;
    }

    function mint(address _address, uint256 _amount) public onlyOwner {
        _mint(_address, _amount);
    }

    function burnZoinks(uint256 _twap) external onlyRebaseContract {
        uint256 burnAmount = (1 - _twap) * _totalSupply;
        _burn(address(this), burnAmount);
    }

    function rebaseInflations(uint256 _twap) external onlyRebaseContract {
        uint256 inflationReward = (_twap - 1) * _circulationSupply / 5;

        for(uint256 i = 0; i < inflationRewards.length; i++)
        {
            uint256 amount = inflationReward * inflationRewards[i].percentage / 100;
            _transfer(address(this), inflationRewards[i].accountAddress, amount);

            _circulationSupply += amount;
        }
    }

    function setRebaseContract(address _account) external onlyOwner {
        _rebaseContract = _account;
    }

    function setInflationReward(address _account, uint256 _percentage) public onlyOwner {
        if(inflationRewards.length <= 7) {
            InflationRewards memory inflationReward;
            inflationReward.accountAddress = _account;
            inflationReward.percentage = _percentage;
            inflationRewards.push(inflationReward);
        }
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
}