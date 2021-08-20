/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]




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


// File @openzeppelin/contracts/proxy/[email protected]


/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/interfaces/IFarmFactory.sol



interface IFarmFactory {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function getFarm(address depositToken, address rewardToken, uint version) external view returns (address farm);
    function getFarmIndex(address depositToken, address rewardToken) external view returns (uint fID);

    function whitelist(address _address) external view returns (bool);
    function governance() external view returns (address);
    function incinerator() external view returns (address);
    function harvestFee() external view returns (uint);
    function gfi() external view returns (address);
    function feeManager() external view returns (address);
    function allFarms(uint fid) external view returns (address); 
    function createFarm(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external;
    function farmVersion(address deposit, address reward) external view returns(uint);
}


// File contracts/interfaces/IFarmV2.sol


struct UserInfo {
        uint256 amount;     // LP tokens provided.
        uint256 rewardDebt; // Reward debt.
}

struct FarmInfo {
    IERC20 lpToken;
    IERC20 rewardToken;
    uint startBlock;
    uint blockReward;
    uint bonusEndBlock;
    uint bonus;
    uint endBlock;
    uint lastRewardBlock;  // Last block number that reward distribution occurs.
    uint accRewardPerShare; // rewards per share, times 1e12
    uint farmableSupply; // total amount of tokens farmable
    uint numFarmers; // total amount of farmers
}

interface IFarmV2 {

    function initialize() external;
    function withdrawRewards(uint256 amount) external;
    function FarmFactory() external view returns(address);
    function init(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external; 
    function pendingReward(address _user) external view returns (uint256);

    function userInfo(address user) external view returns (UserInfo memory);
    function farmInfo() external view returns (FarmInfo memory);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    
}


// File @openzeppelin/contracts/proxy/utils/[email protected]


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


// File contracts/helper/ERC20Initializable.sol





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
contract ERC20Initializable is Context, IERC20, IERC20Metadata, Initializable {
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
    /*
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    */
    function initializeERC20(string memory name_, string memory symbol_) internal initializer{
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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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


// File @openzeppelin/contracts/utils/[email protected]


/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}


// File contracts/DeFi/ERC20SnapshotInitializable.sol




/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotInitializable is ERC20Initializable {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}


// File contracts/interfaces/ICompounderFactory.sol


struct ShareInfo{
    address depositToken;
    address rewardToken;
    address shareToken;
    uint minHarvest;
    uint maxCallerReward;
    uint callerFeePercent;
    bool lpFarm;
    address lpA; //only applies to lpFarms
    address lpB;
}

interface ICompounderFactory {

    function farmAddressToShareInfo(address farm) external view returns(ShareInfo memory);
    function tierManager() external view returns(address);
    function getFarm(address shareToken) external view returns(address);
    function gfi() external view returns(address);
    function swapFactory() external view returns(address);
    function createCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external;
}


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Pair.sol


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function HOLDING_ADDRESS() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function destroy(uint value) external returns(bool);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;

    function handleEarnings() external returns(uint amount);
}


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Factory.sol


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function weth() external view returns (address);
    function wbtc() external view returns (address);
    function gfi() external view returns (address);
    function earningsManager() external view returns (address);
    function feeManager() external view returns (address);
    function dustPan() external view returns (address);
    function governor() external view returns (address);
    function priceOracle() external view returns (address);
    function pathOracle() external view returns (address);
    function router() external view returns (address);
    function paused() external view returns (bool);
    function slippage() external view returns (uint);


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}


// File contracts/DeFi/Share.sol









contract Share is ERC20SnapshotInitializable {


    ICompounderFactory public CompounderFactory;
    //At the time of snapshot save these values so we can use them to evaluate shares worth later
    uint public shareToDepositToken;
    uint public depositTokenToGFI;

    function initialize() external initializer{
        CompounderFactory = ICompounderFactory(msg.sender);
        initializeERC20("Gravity Finance Farm Share", "GFI-FS");
    }

    modifier onlyFactory() {
        require(msg.sender == address(CompounderFactory));
        _;
    }

    modifier onlyTierManager() {
        require(msg.sender == CompounderFactory.tierManager());
        _;
    }

    function mint(address to, uint _amount) external onlyFactory returns(bool){
        _mint(to, _amount);
        return true;
    }

    function burn(address from, uint _amount) external onlyFactory returns(bool){
        _burn(from, _amount);
        return true;
    }

    function takeSnapshot() external onlyTierManager{
        _snapshot();

        //record shareToDepositToken evaluation
        address farm = CompounderFactory.getFarm(address(this));
        UserInfo memory stats = IFarmV2(farm).userInfo(address(CompounderFactory));
        shareToDepositToken = (10 ** decimals()) * stats.amount/totalSupply(); 

        //record depositTokenToGFI evaluation
        ShareInfo memory shareStats = CompounderFactory.farmAddressToShareInfo(farm);
        if(CompounderFactory.gfi()  == shareStats.depositToken){
            depositTokenToGFI = (10 ** decimals());
        }
        else if(shareStats.lpFarm){
            address pair = IUniswapV2Factory(CompounderFactory.swapFactory()).getPair(shareStats.lpA, shareStats.lpB);
            uint GFIinPair = IERC20(CompounderFactory.gfi()).balanceOf(pair);
            depositTokenToGFI = ( (10 ** decimals()) * GFIinPair ) / IUniswapV2Pair(pair).totalSupply();
        }
        else{
            depositTokenToGFI = 0; //deposit token is not an Lp token or GFI so there is no conversion
        }

    }

    function getSharesGFIWorthAtLastSnapshot(address _address) view external returns(uint shareValuation){
        //grab the amount of shares _address had at last snapshot, then use  shareToDepositToken, and depositTokenToGFI
        //to calculate GFI worth
        uint userSnapshotBalance = balanceOfAt(_address, _getCurrentSnapshotId());
        shareValuation = ( ( (userSnapshotBalance * shareToDepositToken) / (10 ** decimals()) ) * depositTokenToGFI ) / (10 ** decimals());
    } 

    function getSharesGFICurrentWorth(address _address) view external returns(uint shareValuation){
        //record shareToDepositToken evaluation
        address farm = CompounderFactory.getFarm(address(this));
        UserInfo memory stats = IFarmV2(farm).userInfo(address(CompounderFactory));
        uint tmpshareToDepositToken = ( (10 ** decimals()) * stats.amount ) / totalSupply(); 

        //record depositTokenToGFI evaluation
        uint tmpdepositTokenToGFI;
        ShareInfo memory shareStats = CompounderFactory.farmAddressToShareInfo(farm);
        if(CompounderFactory.gfi()  == shareStats.depositToken){
            tmpdepositTokenToGFI = (10 ** decimals());
        }
        else if(shareStats.lpFarm){
            address pair = IUniswapV2Factory(CompounderFactory.swapFactory()).getPair(shareStats.lpA, shareStats.lpB);
            uint GFIinPair = IERC20(CompounderFactory.gfi()).balanceOf(pair);
            tmpdepositTokenToGFI = ( (10 ** decimals()) * GFIinPair ) / IUniswapV2Pair(pair).totalSupply();
        }
        else{
            tmpdepositTokenToGFI = 0; //deposit token is not an Lp token or GFI so there is no conversion
        }

        shareValuation = ( ( (balanceOf(_address) * tmpshareToDepositToken) / (10 ** decimals()) ) * tmpdepositTokenToGFI ) / (10 ** decimals());
    }

    function viewCurrentSnapshotID() external view returns(uint ID){
        ID = _getCurrentSnapshotId();
    }

}


// File contracts/interfaces/IShare.sol


interface IShare is IERC20{
    function mint(address to, uint _amount) external returns(bool);
    function burn(address from, uint _amount) external returns(bool);
    function initialize() external;
    function initializeERC20(string memory name_, string memory symbol_) external;
    function getSharesGFIWorthAtLastSnapshot(address _address) view external returns(uint);
}


// File contracts/interfaces/iGravityToken.sol


interface iGravityToken is IERC20 {

    function setGovernanceAddress(address _address) external;

    function changeGovernanceForwarding(bool _bool) external;

    function burn(uint256 _amount) external returns (bool);
}


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Router01.sol


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Router02.sol


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/interfaces/IPriceOracle.sol



interface IPriceOracle {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */

    struct oracle {
        uint[2] price0Cumulative;
        uint[2] price1Cumulative;
        uint32[2] timeStamp;
        uint8 index; // 0 or 1
    }

    function getPrice(address pairAddress) external returns (uint price0Average, uint price1Average, uint timeTillValid);

    function calculateMinAmount(address from, uint256 slippage, uint256 amount, address pairAddress) external returns (uint minAmount, uint timeTillValid);

    function getOracleTime(address pairAddress) external view returns(uint currentTimestamp, uint otherTimestamp);

    function priceValidStart() external view returns(uint);
    function priceValidEnd() external view returns(uint);
}


// File contracts/interfaces/ITierManager.sol



interface ITierManager {
    function checkTier(address caller) external returns(uint);
}


// File contracts/DeFi/CompounderFactory.sol
















contract CompounderFactory is Ownable{
    mapping(address => ShareInfo) public farmAddressToShareInfo;
    iGravityToken GFI;
    IFarmFactory Factory;
    address public ShareTokenImplementation;
    mapping(address => address) public getShareToken;//input the farm address to get it's share token
    mapping(address => address) public getFarm;//input the share address to get it's farm
    address[] public allShareTokens;
    uint public vaultFee = 4; //Default 4% range 0 -> 5%
    uint public rewardBalance;
    mapping(address => uint) public lastHarvestDate;

    address public dustPan;
    address public feeManager;
    address public priceOracle;
    address public swapFactory;
    address public router;
    address public tierManager;
    address public gfi;
    uint public slippage = 0;
    uint public requiredTier;
    bool public checkTiers;
    mapping(address => bool) public whitelist;

    /**
    @dev emitted when a new compounder is created
    **/
    event CompounderCreated(address _farmAddress, uint requiredTier);

    /**
    * @dev emitted when owner changes the whitelist
    * @param _address the address that had its whitelist status changed
    * @param newBool the new state of the address
    **/
    event whiteListChanged(address _address, bool newBool);

    event VaultFeeChanged(uint newFee);

    event TierManagerChanged(address newManager);

    event TierCheckingUpdated(bool newState);

    event ShareInfoUpdated(address farmAddress, uint _minHarvest, uint _maxCallerReward, uint _callerFeePercent);

    event SharedVariablesUpdated(address _dustPan, address _feeManager, address _priceOracle, address _swapFactory, address _router, uint _slippage);

    modifier compounderExists(address farmAddress){
        require(getShareToken[farmAddress] != address(0), "Compounder does not exist!");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Caller is not in whitelist!");
        _;
    }

    constructor(address gfiAddress, address farmFactoryAddress, uint _requiredTier, address _tierManager) {
        GFI = iGravityToken(gfiAddress);
        Factory = IFarmFactory(farmFactoryAddress);
        Share ShareTokenRoot = new Share();
        ShareTokenImplementation = address(ShareTokenRoot);
        requiredTier = _requiredTier;
        tierManager = _tierManager;
    }

    function adjustWhitelist(address _address, bool _bool) external onlyOwner {
        whitelist[_address] = _bool;
        emit whiteListChanged(_address, _bool);
    }

    function changeVaultFee(uint newFee) external onlyOwner{
        require(newFee <= 5, 'Gravity Finance: FORBIDDEN');
        vaultFee = newFee;
        emit VaultFeeChanged(vaultFee);
    }

    function changeTierManager(address _tierManager) external onlyOwner{
        tierManager = _tierManager;
        emit TierManagerChanged(tierManager);
    }
    
    function changeCheckTiers(bool _bool) external onlyOwner{
        checkTiers = _bool;
        emit TierCheckingUpdated(checkTiers);
    }

    function changeShareInfo(address farmAddress, uint _minHarvest, uint _maxCallerReward, uint _callerFeePercent) external onlyOwner compounderExists(farmAddress){
        require(_callerFeePercent <= 100, 'Gravity Finance: INVALID CALLER FEE PERCENT');

        farmAddressToShareInfo[farmAddress].minHarvest = _minHarvest;
        farmAddressToShareInfo[farmAddress].maxCallerReward = _maxCallerReward;
        farmAddressToShareInfo[farmAddress].callerFeePercent = _callerFeePercent;
        emit ShareInfoUpdated(farmAddress, _minHarvest, _maxCallerReward, _callerFeePercent);
    }

    function updateSharedVariables(address _dustPan, address _feeManager, address _priceOracle, address _swapFactory, address _router, uint _slippage) external onlyOwner{
        require(slippage <= 100, 'Gravity Finance: INVALID SLIPPAGE');
        dustPan = _dustPan;
        feeManager = _feeManager;
        priceOracle = _priceOracle;
        swapFactory = _swapFactory;
        router = _router;
        slippage = _slippage;
        emit SharedVariablesUpdated(_dustPan, _feeManager, _priceOracle, _swapFactory, _router, _slippage);
    }

    function createCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external onlyWhitelist{
        if(_lpFarm){
            require(_rewardToken != _lpA, "Set lpB equal to reward token");
        }
        require(getShareToken[_farmAddress] == address(0), "Share token already exists!");
        require(_callerFee <= 100, 'Gravity Finance: INVALID CALLER FEE PERCENT');

        //Create the clone proxy, and add it to the getFarm mappping, and allFarms array
        bytes32 salt = keccak256(abi.encodePacked(_farmAddress));
        address shareClone = Clones.cloneDeterministic(ShareTokenImplementation, salt);
        getShareToken[_farmAddress] = shareClone;
        getFarm[shareClone] = _farmAddress;
        allShareTokens.push(shareClone);
        farmAddressToShareInfo[_farmAddress] = ShareInfo({
            depositToken: _depositToken,
            rewardToken: _rewardToken,
            shareToken: shareClone,
            minHarvest: _minHarvest,
            maxCallerReward: _maxCallerReward,
            callerFeePercent: _callerFee,
            lpFarm: _lpFarm,
            lpA: _lpA,
            lpB: _lpB
        });
        IShare(shareClone).initialize();
        emit CompounderCreated(_farmAddress, requiredTier);
    }

    /**
    * @dev allows caller to deposit the depositToken corresponding to the given fid. 
    * In return caller is minted Shares for that farm
    **/
    function depositCompounding(address farmAddress, uint amountToDeposit) external compounderExists(farmAddress){
        if(checkTiers){
            require(ITierManager(tierManager).checkTier(msg.sender) >= requiredTier, "Caller does not hold high enough tier");
        }
        IERC20 DepositToken = IERC20(farmAddressToShareInfo[farmAddress].depositToken);
        IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
        IShare ShareToken = IShare(farmAddressToShareInfo[farmAddress].shareToken);
        IFarmV2 Farm = IFarmV2(farmAddress);

        //require deposit tokens are transferred into compounder
        require(DepositToken.transferFrom(msg.sender, address(this), amountToDeposit), 'Gravity Finance: TRANSFERFROM FAILED');

        //figure out the amount of shares owed to caller
        uint sharesOwed;
        if(Farm.userInfo(address(this)).amount != 0){
            sharesOwed = amountToDeposit * ShareToken.totalSupply()/Farm.userInfo(address(this)).amount;
        }
        else{
            sharesOwed = 10**18; //1 share distrbuted NOTE Share uses 18 decimals
        }

        //deposit tokens into farm, but keep track of how much reward token we get
        DepositToken.approve(address(Farm), amountToDeposit);
        uint rewardBalbefore = RewardToken.balanceOf(address(this));
        if (farmAddressToShareInfo[farmAddress].depositToken == farmAddressToShareInfo[farmAddress].rewardToken){//make sure to remove amount user just submitted
            rewardBalbefore = rewardBalbefore - amountToDeposit;
        }
        Farm.deposit(amountToDeposit);
        uint rewardToReinvest = RewardToken.balanceOf(address(this)) - rewardBalbefore;

        //mint caller their share tokens
        require(ShareToken.mint(msg.sender, sharesOwed), 'Gravity Finance: SHARE MINT FAILED');

        rewardBalance += rewardToReinvest;
    }

    /**
    * @dev allows caller to exchange farm share tokens for corresponding farms deposit token
    **/
    function withdrawCompounding(address farmAddress, uint amountToWithdraw) external compounderExists(farmAddress){
        IERC20 DepositToken = IERC20(farmAddressToShareInfo[farmAddress].depositToken);
        IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
        IShare ShareToken = IShare(farmAddressToShareInfo[farmAddress].shareToken);
        IFarmV2 Farm = IFarmV2(farmAddress);

        //figure out the amount of deposit tokens owed to caller
        uint depositTokensOwed = amountToWithdraw * Farm.userInfo(address(this)).amount/ShareToken.totalSupply();

        //require shares are burned
        require(ShareToken.burn(msg.sender, amountToWithdraw), 'Gravity Finance: SHARE BURN FAILED');

        //withdraw depositTokensOwed but keep track of rewards harvested
        uint rewardBalbefore = RewardToken.balanceOf(address(this));
        Farm.withdraw(depositTokensOwed);
        uint rewardToReinvest = RewardToken.balanceOf(address(this)) - rewardBalbefore;
        if (farmAddressToShareInfo[farmAddress].depositToken == farmAddressToShareInfo[farmAddress].rewardToken){//make sure to remove amount user just submitted to withdraw
            rewardToReinvest = rewardToReinvest - depositTokensOwed;
        }

        //Transfer depositToken to caller
        require(DepositToken.transfer(msg.sender, depositTokensOwed), 'Gravity Finance: TRANSFER FAILED');

        rewardBalance += rewardToReinvest;
    }

    /**
    * @dev allows caller to harvest compounding farms pending rewards, in exchange for a callers fee(paid in reward token)
    use rewardBalance and reinvest that
    * If reward token and deposit token are the same, then it just reinvests teh tokens.
    * If the deposit token is an LP token, then it swaps half the reward token for deposittokens
    **/
    function harvestCompounding(address farmAddress) external compounderExists(farmAddress) returns(uint timeTillValid) {

        //check if reward and deposit are the same, if they aren't then we need to use the price oracle
        if(farmAddressToShareInfo[farmAddress].depositToken != farmAddressToShareInfo[farmAddress].rewardToken){
            if(farmAddressToShareInfo[farmAddress].lpFarm){
                (,,timeTillValid) = IPriceOracle(priceOracle).getPrice(farmAddressToShareInfo[farmAddress].depositToken);
                address pairAddress = IUniswapV2Factory(swapFactory).getPair(farmAddressToShareInfo[farmAddress].lpA, farmAddressToShareInfo[farmAddress].rewardToken);
                (,,uint timeTillValidOther) = IPriceOracle(priceOracle).getPrice(pairAddress);
                if (timeTillValid < timeTillValidOther){
                    timeTillValid = timeTillValidOther;
                }
            }
            else{
                address pairAddress = IUniswapV2Factory(swapFactory).getPair(farmAddressToShareInfo[farmAddress].depositToken, farmAddressToShareInfo[farmAddress].rewardToken);
                (,,timeTillValid) = IPriceOracle(priceOracle).getPrice(pairAddress);
            }
        }

        //If timeTillValid is 0 or the reward and deposit token are the same, then proceed with the rest of the reinvest
        if(timeTillValid == 0){//Ensure swap price is valid
            IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
            uint rewardToReinvest;
            {
                IFarmV2 Farm = IFarmV2(farmAddress);

                //make sure pending reward is greater than min harvest
                require((Farm.pendingReward(address(this)) + rewardBalance) >= farmAddressToShareInfo[farmAddress].minHarvest, 'Gravity Finance: MIN HARVEST NOT MET');

                //harvest reward keeping track of rewards harvested
                uint rewardBalbefore = RewardToken.balanceOf(address(this));
                Farm.deposit(0);
                rewardToReinvest = RewardToken.balanceOf(address(this)) - rewardBalbefore;
                rewardToReinvest += rewardBalance;
            }
            uint reward = _reinvest(farmAddress, rewardToReinvest);
            rewardBalance = 0;

            lastHarvestDate[farmAddress] = block.timestamp;
            require(RewardToken.transfer(msg.sender, reward), 'Gravity Finance: TRANSFER FAILED');
        }
    }

    /**
    * @dev called at the end of harvestCompounding
    * to take any harvested rewards, convert them into the deposit token, and reinvest them
    * In order for single sided farms with different reward and deposit tokens to work, their needs to be
    * a swap pair with the reward and deposit tokens
    * In order for LP farms to work, there needs to be swap pair between reward, and lpA
    **/
    function _reinvest(address farmAddress, uint amountToReinvest) internal returns(uint callerReward){
        IERC20 DepositToken = IERC20(farmAddressToShareInfo[farmAddress].depositToken);
        IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
        IFarmV2 Farm = IFarmV2(farmAddress);

        if(vaultFee > 0){//handle vault fee
            uint fee = vaultFee * amountToReinvest / 100;
            amountToReinvest = amountToReinvest - fee;
            if(farmAddressToShareInfo[farmAddress].rewardToken == address(GFI)){//burn it
                GFI.burn(fee);
            }
            else{//send it to fee manager
                RewardToken.transfer(feeManager, fee);
            }
        }
        //handle caller reward
        if(farmAddressToShareInfo[farmAddress].callerFeePercent > 0){
            callerReward = farmAddressToShareInfo[farmAddress].callerFeePercent * amountToReinvest / 100;
            if (callerReward > farmAddressToShareInfo[farmAddress].maxCallerReward){
                callerReward = farmAddressToShareInfo[farmAddress].maxCallerReward;
            }
            amountToReinvest = amountToReinvest - callerReward;
        } 

        //check if the deposit token and the reward token are not the same
        if (farmAddressToShareInfo[farmAddress].depositToken != farmAddressToShareInfo[farmAddress].rewardToken){
            address[] memory path = new address[](2);
            uint[] memory amounts = new uint[](2);

            if (farmAddressToShareInfo[farmAddress].lpFarm){//Dealing with an LP farm so swap half the reward for deposit and supply liqduity
                
                path[0] = farmAddressToShareInfo[farmAddress].rewardToken;
                path[1] = farmAddressToShareInfo[farmAddress].lpA;
                RewardToken.approve(router, amountToReinvest);
                (uint minAmount,) = IPriceOracle(priceOracle).calculateMinAmount(path[0], slippage, amountToReinvest, IUniswapV2Factory(swapFactory).getPair(path[0], path[1]));
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    amountToReinvest,
                    minAmount,
                    path,
                    address(this),
                    block.timestamp
                );

                path[0] = farmAddressToShareInfo[farmAddress].lpA;
                path[1] = farmAddressToShareInfo[farmAddress].lpB;
                IERC20(path[0]).approve(router, amounts[1]/2);
                (minAmount,) = IPriceOracle(priceOracle).calculateMinAmount(path[0], slippage, amounts[1] / 2, address(DepositToken));
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    amounts[1] / 2,
                    minAmount,
                    path,
                    address(this),
                    block.timestamp
                );
                
                IERC20(path[0]).approve(router, amounts[0]);
                IERC20(path[1]).approve(router, amounts[1]);
                //Don't need to use minAmounts here bc amounts array was set by using minAmounts to make the initial swap
                uint token0Var = (slippage * amounts[0]) / 100; 
                uint token1Var = (slippage * amounts[1]) / 100;
                (token0Var, token1Var,) = IUniswapV2Router02(router).addLiquidity(
                    path[0],
                    path[1],
                    amounts[0],
                    amounts[1],
                    token0Var,
                    token1Var,
                    address(this),
                    block.timestamp
                );
                
                amountToReinvest = DepositToken.balanceOf(address(this));//The amount of LP tokens we have

                //if((amounts[0] - token0Var) > 0){IERC20(path[0]).transfer(dustPan, (amounts[0] - token0Var));}
                //if((amounts[1] - token1Var) > 0){IERC20(path[1]).transfer(dustPan, (amounts[1] - token1Var));}

            }
            else{//need to swap all reward for deposit token
                address pairAddress = IUniswapV2Factory(swapFactory).getPair(farmAddressToShareInfo[farmAddress].depositToken, farmAddressToShareInfo[farmAddress].rewardToken);
                path[0] = farmAddressToShareInfo[farmAddress].rewardToken;
                path[1] = farmAddressToShareInfo[farmAddress].depositToken;
                RewardToken.approve(router, amountToReinvest);
                (uint minAmount,) = IPriceOracle(priceOracle).calculateMinAmount(farmAddressToShareInfo[farmAddress].rewardToken, slippage, amountToReinvest, pairAddress);
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    amountToReinvest,
                    minAmount,
                    path,
                    address(this),
                    block.timestamp
                );
                amountToReinvest = amounts[1]; //What we got out of the swap
            }
        }
        DepositToken.approve(address(Farm), amountToReinvest);
        Farm.deposit(amountToReinvest);
    }
}