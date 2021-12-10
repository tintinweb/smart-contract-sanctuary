// File: node_modules\@openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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

// File: @openzeppelin\contracts-upgradeable\security\ReentrancyGuardUpgradeable.sol

// 
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// File: node_modules\@openzeppelin\contracts-upgradeable\utils\ContextUpgradeable.sol

// 
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin\contracts-upgradeable\access\OwnableUpgradeable.sol

// 
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;



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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}


// File: @openzeppelin\contracts-upgradeable\token\ERC20\IERC20Upgradeable.sol

// 
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: deployment-process\contracts-origin\contracts\interfaces\ISync.sol

pragma solidity >=0.8.0 <=0.8.6;

/**
 * @title The sync interface.
 * @author int(200/0), slidingpanda
 */
interface ISync {
    function sync() external;
}

// File: deployment-process\contracts-origin\contracts\token\TenToken.sol

pragma solidity >=0.8.0 <=0.8.6;






/**
 * @title The fabulous ten-Token contract. More Ether with Pether.
 * @author int(200/0), slidingpanda
 * @dev Generic contract for a pegged ten-Token.
 */
contract TenToken is ContextUpgradeable, IERC20Upgradeable, OwnableUpgradeable {
    string private _name;
    string private _symbol; 
    uint8 private _decimals;
    uint8 private _outDecimals;
    uint8 private _calcDecimals;

    struct Accounts {
        uint256 nettoBalance;     
        uint256 feeAccountMultiplier; 
    }

    address private _amm;
    address private _daoWallet;

    uint256 private _totalSupply;
    uint256 private _nettoSupply;
    uint256 private _feeReserve;
    uint256 private _gFeeMultiplier;

    uint32 private _fee;
    uint32 constant private FEE_DIVISOR = 1000;
    uint256 constant private MAX_POOLS = type(uint256).max; 
    uint32 constant private REFLOW_PER  = 10000;
    uint32 private _daoTxnFee;
    uint8 private _buyFeeMultiplier;
    uint8 private _buyFeeDivisor;
    uint8 private _sellFeeMultiplier;
    uint8 private _sellFeeDivisor;

    address[] private _syncAdr;

    mapping (address => Accounts) private _accounts;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _blacklisted;

    event Reflow(uint256 totalSupply, uint256 multiplier, uint256 feeReserve);

    /**
     * @dev Sets the contract owner and the ten-Token decimals, pegged token decimals,
     *      name of the ten-Token, the symbol of the ten-Token, the DAO wallet and
     *      checks the DAO wallet in (needed for reflow calculation on the wallet balance).
     * @param tenName name of the ten-Token
     * @param tenSymbol symbol of the ten-Token
     * @param pegDecimals pegged token decimals
     * @param calcDecimal decimals for calculating
     * @param daoWallet dao wallet address
     */
    function initialize(string memory tenName, string memory tenSymbol, uint8 pegDecimals, uint8 calcDecimal, address daoWallet) public initializer {
        __Ownable_init();
        _calcDecimals = calcDecimal;
        _decimals = pegDecimals + calcDecimal;
        _outDecimals = pegDecimals;
        _name = tenName;
        _symbol = tenSymbol;
        _daoWallet = daoWallet;
        _checkIn(_daoWallet);

        _gFeeMultiplier = 1;
        _fee = 10;
        _daoTxnFee = 2;
        _buyFeeMultiplier = 3;
        _buyFeeDivisor = 2;
        _sellFeeMultiplier= 1;
        _sellFeeDivisor = 2;
    }
    
    /**
     * @dev Synchronizes a specific UniswapV2 pool because they don't do it by themselves with rebase tokens.
     * @param inAdr address of the UniswapV2Pair
     */
    function doSync(address inAdr) public {
        ISync(inAdr).sync();
    }
    
    /**
     * @dev Synchronizes UniswapV2 pools because they don't do it by themselves with rebase tokens.
     */
    function doAnySync() public {
        _doAnySync();
    }
    
    /**
     * @dev Returns number of the sync addresses.
     * @return number of sync addresses
     */
    function getSyncAdrLength() public view returns (uint) {
        return _syncAdr.length;
    }

    /**
     * @dev Returns the name of the ten-Token.
     * @return name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the ten-Token.
     * @return symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the ten-Token.
     * @return decimals
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the out decimals of the ten-Token.
     * @return out decimals
     */
    function outDecimals() public view returns (uint8) {
        return _outDecimals;
    }

    /**
     * @dev Returns the calc decimals of the ten-Token.
     * @return calc decimals
     */
    function calcDecimals() public view returns (uint8) {
        return _calcDecimals;
    }

    /**
     * @dev Returns the total supply of the ten-Token.
     * @return total supply
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the netto supply of the ten-Token.
     * @return netto supply
     */
    function nettoSupply() external view returns (uint256) {
        return _nettoSupply;
    }

    /**
     * @dev Returns the ten-Token balance of a wallet.
     * @param account account address
     * @return ten-Token balance
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @dev Calculates and returns the ten-Token balance of a wallet.
     * @param account account address
     * @return ten-Token balance
     */
    function _balanceOf(address account) public view returns (uint256) {
        uint256 multiplier = _gFeeMultiplier - _accounts[account].feeAccountMultiplier;
        uint256 collectedReflows = _accounts[account].nettoBalance * multiplier / REFLOW_PER;

        return _accounts[account].nettoBalance + collectedReflows;
    }

    /**
     * @dev Returns the ten-Token netto balance of a specific account.
     * @param account account address
     * @return ten-Token netto balance
     */
    function nettoBalanceOf(address account) external view returns (uint256) {
        return _accounts[account].nettoBalance;
    }

    /**
     * @dev Transfers ten-Tokens.
     * @param recipient recipient address
     * @param amount token amount
     * @return bool 'true' if not reverted
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _doTransfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @dev Returns the allowance.
     * @param toAllow toAllow address
     * @param spender spender address
     * @return allowance
     */
    function allowance(address toAllow, address spender) external view override returns (uint256) {
        return _allowances[toAllow][spender];
    }

    /**
     * @dev Approves an amount to be transfered.
     * @param spender spender address
     * @param amount approve amount
     * @return bool 'true' if not reverted
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    /**
     * @dev Approves an amount to be transfered.
     * @param toAllow toAllow address
     * @param spender spender address
     * @param amount approve amount
     */
    function _approve(address toAllow, address spender, uint256 amount) private {
        require(toAllow != address(0), "_approve: approve from the zero address");
        require(spender != address(0), "_approve: approve to the zero address");

        _allowances[toAllow][spender] = amount;

        emit Approval(toAllow, spender, amount);
    }

    /**
     * @dev Transfers an amount from a sender to a recipient.
     * @param sender spender address
     * @param recipient recipient address
     * @param amount transfer amount
     * @return bool 'true' if not reverted
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _doTransfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "transferFrom: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    /**
     * @dev Increases the allowance.
     * @param spender spender address
     * @param addedValue added value
     * @return bool 'true' if not reverted
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;
    }

    /**
     * @dev Decreases the allowance.
     * @param spender spender address
     * @param subtractedValue subtracted value
     * @return bool 'true' if not reverted
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "decreaseAllowance: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);

        return true;
    }

    /**
     * @dev Transfers an amount from a sender to a recipient.
     * @param sender spender address
     * @param recipient recipient address
     * @param amount transfer amount
     */
    function _doTransfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "_doTransfer: transfer from the zero address");
        require(recipient != address(0), "_doTransfer: transfer to the zero address");
        require(amount > 0, "_doTransfer: Transfer amount must be greater than zero");
        require(_blacklisted[recipient] == false, "_doTransfer: This address is blacklisted");
        require(_balanceOf(sender) >= amount, "_doTransfer: transfer amount exceeds balance");

        _subFromBalance(amount, sender);

        uint256 toReserve = amount * _fee / FEE_DIVISOR;
        uint256 toDao = amount * _daoTxnFee / FEE_DIVISOR;
        uint256 afterFee = amount - toReserve - toDao;
        _feeReserve += toReserve;

        _addToBalance(toDao, _daoWallet);
        _addToBalance(afterFee, recipient);

        emit Transfer(sender, recipient, afterFee);
        emit Transfer(sender, _daoWallet, toDao);
    }

    /**
     * @dev Adds an amount to a wallet balance.
     * @param amount amount
     * @param to wallet address
     */
    function _addToBalance(uint256 amount, address to) internal {
        _nettoSupply -= _accounts[to].nettoBalance / REFLOW_PER;

        _accounts[to].nettoBalance = _balanceOf(to);
        _accounts[to].feeAccountMultiplier = _gFeeMultiplier;
        _accounts[to].nettoBalance += amount;

        _nettoSupply += _accounts[to].nettoBalance / REFLOW_PER;
    }

    /**
     * @dev Adds an amount to a wallet balance.
     * @param amount amount
     * @param from wallet address
     */
    function _subFromBalance(uint256 amount, address from) internal {
        _nettoSupply -= _accounts[from].nettoBalance / REFLOW_PER;

        _accounts[from].nettoBalance = _balanceOf(from);
        _accounts[from].feeAccountMultiplier = _gFeeMultiplier;

        _accounts[from].nettoBalance -= amount;

        _nettoSupply += _accounts[from].nettoBalance / REFLOW_PER;   
    }

    /**
     * @dev Returns if an account is blacklisted.
     * @param account account address
     * @return bool
     */
    function isBlacklisted(address account) external view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev Blacklists an account and put the account balance into the feereserve to prevent dead wallet collecting fees.
     * @param account account address
     * @return bool
     */
    function blacklistAccount(address account) external onlyOwner returns (bool) {
        _addToBalance(0, account);
        uint256 toReserve = balanceOf(account);

        _subFromBalance(toReserve, account);
        _feeReserve += toReserve;

        _blacklisted[account] = true;

        return _blacklisted[account];
    }

    /**
     * @dev Returns the fee account multiplier for a specific account.
     * @param account account address
     * @return bool
     */
    function getMultiplierOf(address account) external view returns (uint256) {
        return _accounts[account].feeAccountMultiplier;
    }

    /**
     * @dev Getter for _gFeeMultiplier.
     * @return global fee multiplier
     */
    function globalMultiplier() external view returns (uint256) {
        return _gFeeMultiplier;
    }

    /**
     * @dev Getter for FEE_DIVISOR.
     * @return fee divisor
     */
    function getFeeDivisor() public pure returns (uint256) {
        return FEE_DIVISOR;
    }

    /**
     * @dev Getter for _fee.
     * @return fee
     */
    function getFees() external view returns (uint256) {
        return _fee;
    }

    /**
     * @dev Getter for _daoTxnFee.
     * @return dao transaction fee
     */
    function getDaoTxFee() external view returns (uint256) {
        return _daoTxnFee;
    }

    /**
     * @dev Returns the actual fees.
     * @return actual fees
     */
    function getActualFees() external view returns (uint32, uint32) {
        return (FEE_DIVISOR, _fee + _daoTxnFee);
    }

    /**
     * @dev Returns the actual buy fees.
     * @return actual buy fees
     */
    function getActualBuyFees() external view returns (uint32, uint32) {
        uint32 buyFee = (_fee + _daoTxnFee) * _buyFeeMultiplier / _buyFeeDivisor;
        return (FEE_DIVISOR, buyFee);
    }

    /**
     * @dev Returns the actual sell fees.
     * @return actual buy fees
     */
    function getActualSellFees() external view returns (uint32, uint32) {
        uint32 buyFee = (_fee + _daoTxnFee) * _sellFeeMultiplier / _sellFeeDivisor;
        return (FEE_DIVISOR, buyFee);
    }

    /**
     * @dev Getter for buy multiplier.
     * @return dao transaction fee
     */
    function buyFeeMultiplier() external view returns (uint256) {
        return _buyFeeMultiplier;
    }

    /**
     * @dev Getter for buy divisor.
     * @return dao buy fee divisor
     */
    function buyFeeDivisor() external view returns (uint256) {
        return _buyFeeDivisor;
    }

    /**
     * @dev Getter for sell multiplier.
     * @return dao sell fee multiplier
     */
    function sellFeeMultiplier() external view returns (uint256) {
        return _sellFeeMultiplier;
    }

    /**
     * @dev Getter for sell divisor.
     * @return dao sell fee divisor
     */
    function sellFeeDivisor() external view returns (uint256) {
        return _sellFeeDivisor;
    }

    /**
     * @dev Getter for _feeReserve.
     * @return fee reserve
     */
    function feeReserve() external view returns (uint256) {
        return _feeReserve;
    }

    /**
     * @dev Getter for REFLOW_PER.
     * @return reflow trigger
     */
    function getReflowPer() pure public returns (uint32) {
        return REFLOW_PER;
    }

    /**
     * @dev Getter for _amm.
     * @return amm address
     */
    function ammOf() external view returns (address) {
        return _amm;
    }

    /**
     * @dev Setter for _fee.
     * @param fee fee
     */
    function setFees(uint16 fee) external onlyOwner {
        require(fee <= 100, "setFees: Too high transaction fees set. Max 10 % (uint 100)");

        _fee = fee;
    }

    /**
     * @dev Setter for _daoTxnFee.
     * @param fee dao tx fee
     */
    function setDaoTxFee(uint16 fee) external onlyOwner {
        require(fee <= 100, "setDaoTxFee: Too high dao fees set. Max 10 % (uint 100)");

        _daoTxnFee = fee;
    }

    /**
     * @dev Setter for buy and sell calculation of the fees.
     * @param bFeeMultiplier buy fee multiplier
     * @param bFeeDivisor buy fee divisor
     * @param sFeeMultiplier buy fee multiplier
     * @param sFeeDivisor sell fee divisor
     */
    function setBuyAndSellFeeMultiplier(uint8 bFeeMultiplier, uint8 bFeeDivisor, uint8 sFeeMultiplier, uint8 sFeeDivisor) external onlyOwner {
        require(sFeeDivisor > 0, "setBuyAndSellFeeMultiplier: sellFeeDivisor has to be greater than zero.");
        require(bFeeDivisor > 0, "setBuyAndSellFeeMultiplier: buyFeeDivisor has to be greater than zero.");

        _buyFeeMultiplier = bFeeMultiplier;
        _buyFeeDivisor = bFeeDivisor;
        _sellFeeMultiplier= sFeeMultiplier;
        _sellFeeDivisor = sFeeDivisor;
    }

    /**
     * @dev Setter for _daoWallet.
     * @param to dao wallet address
     */
    function setDaoWallet(address to) external onlyOwner {
        _daoWallet = to;
        _checkIn(_daoWallet);
    }

    /**
     * @dev Setter for _amm.
     * @param input amm address
     * @return bool 'true' if not reverted
     */
    function setAMM(address input) external onlyOwner returns (bool) {
        require(_amm == address(0), "setAMM: AMM already set");
        _amm = input;

        return true;
    }

    /**
     * @dev Compounds wallet with reflow.
     * @param account account address
     */
    function compoundWallet(address account) external {
        _reflow();
        _addToBalance(0, account);
    }

    /**
     * @dev Does reflow.
     */
    function doReflow() external {
        _reflow();
    }

    /**
     * @dev Fountains an amount.
     * @param amount fountain amount
     */
    function fountain(uint256 amount) external {
        require(_balanceOf(msg.sender) >= amount, "fountain: transfer amount exceeds balance");
        _subFromBalance(amount, msg.sender);
        _feeReserve += amount;
    }

    /**
     * @dev Mints a specific amount of tokens.
     * @param to recipient address
     * @param amount mint amount
     */
    function mint(address to, uint256 amount) external {
        require(amount > 0, "mint: Mint amount must be greater than zero");
        require(_amm == msg.sender, "mint: Caller is not the AMM. We don't do that here my fren...");
        
        _reflow();
        _mint(to, amount);
    }

    /**
     * @dev Mints tokens, triggers the global reflow and puts fees into the dao wallet.
     * @param account recipient address
     * @param iamount mint amount
     */
    function _mint(address account, uint256 iamount) internal{
        require(account != address(0), "_mint: mint to the zero address");

        uint256 amount = iamount * (10**_calcDecimals);

        uint256 daoFee = (_fee + _daoTxnFee) * _buyFeeMultiplier / _buyFeeDivisor;
        uint256 toDao = amount * daoFee / FEE_DIVISOR;
        uint256 afterFee = amount - toDao;

        _addToBalance(toDao, _daoWallet);
        _addToBalance(afterFee, account);

        _totalSupply += amount;
        
        emit Transfer(address(0), account, afterFee);
        emit Transfer(address(0), _daoWallet, toDao);
    }

    /**
     * @dev Triggers the global reflow and burns a specific amount of tokens.
     * @param to account address
     * @param amount burn amount
     */
    function burn(address to, uint256 amount) external returns (uint256) {
        require(_amm == msg.sender, "burn: Caller is not the AMM. We don't do that here my fren...");
        require(amount > 0, "burn: Burn amount must be greater than zero");

        return _burn(to, amount);
    }

    /**
     * @dev Burns tokens.
     * @param account account address
     * @param amount burn amount
     */
    function _burn(address account, uint256 amount) private returns (uint256) {
        require(account != address(0), "_burn: burn from the zero address");
        require(balanceOf(account) >= amount, "_burn: burn amount exceeds balance");

        uint256 daoFee = (_fee + _daoTxnFee) * _sellFeeMultiplier / _sellFeeDivisor;
        uint256 toDao = amount * daoFee / FEE_DIVISOR; 
        uint256 afterFee = amount - toDao;
        uint256 residual = afterFee % 10 ** _calcDecimals; 

        _addToBalance(toDao, _daoWallet);
        _subFromBalance(amount, account);
        _totalSupply = _totalSupply - afterFee + residual; 
        _feeReserve += residual;

        uint256 outAmount = afterFee / 10 ** _calcDecimals;

        emit Transfer(account, address(0), afterFee); //fix
        emit Transfer(account, _daoWallet, toDao); //fix

        _reflow();
        
        return outAmount;
    }

   
    /**
     * @dev Do reflow.
     */
    function _reflow() private {
        if (_feeReserve > _nettoSupply){
            uint256 multiplier = _feeReserve / _nettoSupply;
            uint256 modRes = _feeReserve % _nettoSupply;
            _feeReserve = modRes;
            _gFeeMultiplier += multiplier;

            _doAnySync();
            
            emit Reflow(_totalSupply, multiplier, _feeReserve);
        }
    }

    /**
     * @dev Sets the multiplier of the wallet to the actual multiplier.
     * @param account account address
     */
    function _checkIn(address account) private {
        uint256 balance = _accounts[account].nettoBalance;

        if(balance == 0) {
            _accounts[account].feeAccountMultiplier = _gFeeMultiplier;
        }
    }

    /**
     * @dev Does sync over all sync addresses.
     */
    function _doAnySync() internal {
        for (uint i = 0; i < _syncAdr.length; i++) {
            ISync(_syncAdr[i]).sync();
        }
    }

    /**
     * @dev Finds an address index with a given address.
     * @param inAdr account address
     * @return address index
     */
    function _findAdr(address inAdr) internal view returns (uint256) {
        uint addressIndex = MAX_POOLS;
        
        for (uint i = 0; i < _syncAdr.length; i++) {
            if (_syncAdr[i] == inAdr) {
                addressIndex = i;
            }
        }

        return addressIndex;
    }

    /**
     * @dev Finds an address index with a given address.
     * @param inAdr account address
     * @return address index
     */
    function findAdr(address inAdr) external view returns (uint256) {
        uint256 addressIndex = _findAdr(inAdr);

        require(addressIndex != type(uint256).max, "findAdr: Address not in sync-array.");

        return addressIndex;
    }

    /**
     * @dev Removes an index of the sync addresses.
     * @param index index
     * @return bool 'true' if not reverted
     */
    function removeIndex(uint index) public onlyOwner returns (bool) {
        require(index <= _syncAdr.length, "removeIndex: Index out of range.");
        require(_syncAdr.length >= 1, "removeIndex: array has too few elements.");

        _syncAdr[index] = _syncAdr[_syncAdr.length - 1];
        _syncAdr.pop();

        return true;
    }

    /**
     * @dev Removes an address of the sync addresses.
     * @param inAdr account address
     * @return bool
     */
    function removeAddress(address inAdr) public onlyOwner returns (bool) {
        uint256 index = _findAdr(inAdr);

        if (index != MAX_POOLS) {
             return removeIndex(index);
        } else {
            return false;
        }
    }

    /**
     * @dev Adds a sync address.
     * @param inAdr account address
     * @return bool
     */
    function addSyncAdr(address inAdr) public onlyOwner returns (bool) {
        require(_syncAdr.length <= MAX_POOLS - 1, "addSyncAdr: Too many addresses to sync.");

        if (_syncAdr.length != 0) {
            if (_findAdr(inAdr) == MAX_POOLS) {
                _syncAdr.push(inAdr);

                return true;
            } else {
                return false;
            }
        } else {
            _syncAdr.push(inAdr);

            return true;
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
     * @param from from address
     * @param to to address
     * @param amount transfer amount
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        // ...
    }
}

// File: deployment-process\contracts-origin\contracts\amm\AutomatedMarketMakerETH.sol

pragma solidity >=0.8.0 <=0.8.6;





/**
 * @title The marvelous automated market maker contract for ETH.
 * @author int(200/0), slidingpanda
 * @dev Provides a fix point to a fixed exchange rate for the pegged and ten-Token.
 */
contract AutomatedMarketMakerETH is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event Bought(address account, uint256 amount);
    event Sold(address account, uint256 amount);
    
    TenToken private _tenETH;

    bool private _canBuy;

    uint8 private _calcDecimals;

    /**
     * @dev Sets the contract owner and the ten-Token.
     * @param token address of the ten-Token
     */
    function initialize(address token) public initializer {
        __Ownable_init();
        _tenETH = TenToken(token);
        _calcDecimals = _tenETH.calcDecimals();
        _canBuy = false;
    }

    receive() external payable {
        // ...
    }

    /**
     * @dev Toggles the possibility to buy over the amm.
     * @return The actual state of _canBuy after toggle
     */
    function toggleBuy() external onlyOwner returns (bool) {
        _canBuy = !_canBuy;
        return _canBuy;
    }

    /**
     * @dev Getter for _canBuy.
     * @return current state of _canBuy
     */
    function canBuy() external view returns (bool) {
        return _canBuy;
    }

    /**
     * @dev Mints new ten-Tokens for the sent ETH.
     * @param tokenAmount buy amount
     * @return bool 'true' if not reverted
     */
    function buy(uint256 tokenAmount) external nonReentrant payable returns (bool) {
        require(msg.value == tokenAmount, "buy: Sent value is not equal to the amount");
        require(_canBuy == true, "buy: The buying function is not activated");

        _tenETH.mint(msg.sender, msg.value);

        emit Bought(msg.sender, tokenAmount);

        return true;
    }

    /**
     * @dev Burns ten-Tokens and sends the ETH amount.
     * @param tokenAmount sell amount
     * @return bool
     */
    function sell(uint256 tokenAmount) external nonReentrant returns (bool) {
        require(address(this).balance >= tokenAmount / 10**_calcDecimals, "sell: Too few pegged tokens locked");
        require(_tenETH.totalSupply() >= tokenAmount, "sell: That's too much");

        uint256 toSend = _tenETH.burn(msg.sender, tokenAmount);
        bool sendTx = payable(msg.sender).send(toSend);

        require(sendTx, "sell: No fallback function in contract"); //fix

        emit Sold(msg.sender, toSend);

        return sendTx;
    }

    /**
     * @dev Returns the actual price for swapping pegged token to ten-Token.
     * @param amount amount to calculate
     * @return price
     */
    function getInPrice(uint256 amount) external view returns (uint256) {
        uint256 divisor;
        uint256 multiplier;
        (divisor, multiplier) = _tenETH.getActualBuyFees();

        uint256 fee = amount * multiplier / divisor;
        uint256 price = amount - fee;

        return price * 10**_calcDecimals;
    }

    /**
     * @dev Returns the actual price for swapping ten-Token to pegged token.
     * @param amount amount to calculate
     * @return price
     */
    function getOutPrice(uint256 amount) external view returns (uint256) {
        uint32 divisor;
        uint32 multiplier;
        (divisor, multiplier) = _tenETH.getActualSellFees();

        uint256 fee = amount * multiplier / divisor;
        uint256 price = amount - fee;
        
        return price / 10**_calcDecimals;
    }
}