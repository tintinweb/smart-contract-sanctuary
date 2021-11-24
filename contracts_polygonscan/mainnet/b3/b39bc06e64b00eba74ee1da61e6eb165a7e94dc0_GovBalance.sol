/**
 *Submitted for verification at polygonscan.com on 2021-11-23
*/

// File: _POOL_GOVERNANCE/contracts/lib/IAutoCrystl.sol


pragma solidity ^0.8.4;

interface IAutoCrystl {
    function balanceOf() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function userInfo(address) external view returns (uint256 shares, uint256, uint256, uint256);
}
// File: _POOL_GOVERNANCE/contracts/lib/IMasterChef.sol


pragma solidity ^0.8.4;

interface IMasterChef {
    function poolInfo(uint) external view returns (address, uint, uint, uint, uint16);
    function userInfo(uint, address) external view returns (uint256, uint256);
    function STAKE_TOKEN() external view returns (address);
}
// File: _POOL_GOVERNANCE/contracts/lib/IStakingPool.sol


pragma solidity ^0.8.4;

interface IStakingPool {
    function userInfo(address) external view returns (uint256, uint256);
    function STAKE_TOKEN() external view returns (address);
}
// File: _POOL_GOVERNANCE/contracts/lib/IUniPair.sol



pragma solidity ^0.8.4;



interface IUniPair {

    function token0() external view returns (address);

    function token1() external view returns (address);

    function mint(address to) external returns (uint liquidity);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function getReserves() external view returns (uint112, uint112, uint32);

}
// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol



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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol



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
abstract contract Ownable is Initializable, ContextUpgradeable {
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
    uint256[49] private __gap;
}

// File: _POOL_GOVERNANCE/contracts/GovBalance.sol



pragma solidity ^0.8.0;

/*
Join us at crystl.finance!
 █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █░░ 
 █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █░░ 
 ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀▀▀
*/







contract GovBalance is Ownable {

    struct MasterChefPool {
        IMasterChef chef;
        uint96 pid;
    }
    IERC20 immutable public GOV_TOKEN;
    bool private _init;
    
    mapping(IUniPair => bool) public govIsToken1;
    
    MasterChefPool[] public chefs;
    function chefsLength() external view returns (uint) { return chefs.length; }
    mapping(IUniPair => MasterChefPool[]) public lpChefs;
    function lpChefsLength(IUniPair pair) external view returns (uint) { return lpChefs[pair].length; }
    
    constructor(address _govToken) {
        GOV_TOKEN = IERC20(_govToken);
    }
    
    enum SourceType { NULL, LP, POOL, CHEF_GOV, CHEF_LP }
    
    IUniPair[] public lps;
    function lpsLength() external view returns (uint) { return lps.length; }
    IStakingPool[] public pools;
    function poolsLength() external view returns (uint) { return pools.length; }
    
    mapping(address => SourceType) sourceType;
    mapping(address => bool) public operators;
    IAutoCrystl autoCrystl;
    
    function setOperator(address user, bool isOp) public {
        require(operators[user] != isOp, "already set");
        operators[user] = true;
    }
    
    modifier onlyOperator() {
        require(operators[msg.sender], "!operator");
        _;
    }

    function balanceOf(address account) external view returns (uint256 amount) {
        address[] memory a = new address[](1);
        a[0] = account;
        return this.balancesOf(a)[0];
    }

    function totalSupply() external view returns (uint256) {
        return GOV_TOKEN.totalSupply() - GOV_TOKEN.balanceOf(address(0xdead));
    }

    function balancesOf(address[] calldata accounts) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](accounts.length);
        
        for (uint i; i < lps.length; i++) {
            IUniPair _lp = lps[i];
            (uint supply, uint govAmt) = lpStats(_lp);
            
            for (uint k; k < accounts.length; k++) {
                if (sourceType[accounts[k]] != SourceType.NULL) continue; //never allow double-voting
                uint lpAmount = IUniPair(_lp).balanceOf(accounts[k]); //lp tokens in wallet

                for (uint m; m < lpChefs[_lp].length; m++) {    //lp tokens staked in MC
                    MasterChefPool storage mc = lpChefs[_lp][m];
                    (uint mcLPAmt, ) = mc.chef.userInfo(mc.pid, accounts[k]);
                    lpAmount += mcLPAmt;
                }
                if (lpAmount > 0) 
                    amounts[k] = lpAmount * govAmt / supply; //underlying value
            }
        }
        
        uint autoSharesTotal = address(autoCrystl) == address(0) ? 0 : autoCrystl.totalShares();
        uint autoTotalCrystl = autoSharesTotal > 0 ? autoCrystl.balanceOf() : 0;
        
        for (uint k; k < accounts.length; k++) {
            if (sourceType[accounts[k]] != SourceType.NULL) continue; //never allow double-voting
            amounts[k] += GOV_TOKEN.balanceOf(accounts[k]);  // gov tokens in wallet

            if (autoTotalCrystl > 0) { //Auto Crystl pool
                (uint autoAmount,,,) = autoCrystl.userInfo(accounts[k]);
                if (autoAmount > 0) amounts[k] += autoAmount * autoTotalCrystl / autoSharesTotal;
            }

        
            for (uint i; i < chefs.length; i++) { //staked directly in MC
                MasterChefPool storage mc = chefs[i];
                (uint bal, ) = mc.chef.userInfo(mc.pid, accounts[k]);
                amounts[k] += bal;
            }
            for (uint i; i < pools.length; i++) {   //staked in pools
                (uint poolBal,) = pools[i].userInfo(accounts[k]);
                amounts[k] += poolBal;
            }
        }
    }
    
    function lpStats(IUniPair _lp) internal view returns (uint supply, uint govAmt) {
        supply = _lp.totalSupply(); // LP total supply
        if (supply == 0) return (0, 0);
        
        (uint reserve0, uint reserve1,) = _lp.getReserves(); //LP underlying value
        uint reserve = govIsToken1[_lp] ? reserve1 : reserve0;
        govAmt = GOV_TOKEN.balanceOf(address(_lp));
        govAmt = govAmt > reserve ? reserve : govAmt;
    }
    
    function addLP(IUniPair _lp) external onlyOperator {
        require(sourceType[address(_lp)] == SourceType.NULL, "already added");
        bool token1;
        if (_lp.token0() != address(GOV_TOKEN)) {
            require (_lp.token1() == address(GOV_TOKEN), "gov token must be part of LP");
            token1 = true;
            IUniPair(_lp).totalSupply();
        }
        
        lps.push() = _lp;
        govIsToken1[_lp] = token1;
        sourceType[address(_lp)] = SourceType.LP;
    }
    function delLP(IUniPair _lp) external onlyOperator {
        require(sourceType[address(_lp)] == SourceType.LP, "not a listed lp");
        for (uint i; i < lps.length; i++) {
            if (_lp == lps[i]) {
                lps[i] = lps[lps.length - 1];
                lps.pop();
                sourceType[address(_lp)] = SourceType.NULL;
                return;
            }
        }
        assert(false);
    }
    
    function addPool(address _pool) external onlyOperator {
        require(sourceType[_pool] == SourceType.NULL, "already added");
        require (IStakingPool(_pool).STAKE_TOKEN() == address(GOV_TOKEN), "gov token must be staked token");
        pools.push() = IStakingPool(_pool);
        
        sourceType[_pool] = SourceType.POOL;
    }
    function addPools(address[] calldata _pools) external onlyOperator {
        for (uint i; i < _pools.length; i++) {
            address pool = _pools[i];
            if (sourceType[pool] == SourceType.POOL) continue;
            if (sourceType[pool] == SourceType.NULL) {
                require (IStakingPool(pool).STAKE_TOKEN() == address(GOV_TOKEN), "gov token must be staked token");
                pools.push() = IStakingPool(pool);
                sourceType[pool] = SourceType.POOL;
            }
        }
    }
    
    function delPool(address _pool) external onlyOperator {
        require(sourceType[_pool] == SourceType.POOL, "not a listed pool");
        for (uint i; i < pools.length; i++) {
            if (IStakingPool(_pool) == pools[i]) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                sourceType[_pool] = SourceType.NULL;
                return;
            }
        }
        assert(false);
    }
    
    function addChefPool(address _chef, uint96 pid) external onlyOperator {
        require(sourceType[address(uint160(_chef) + pid)] == SourceType.NULL, "already added");
    
        (address staked,,,,) = IMasterChef(_chef).poolInfo(pid);
        MasterChefPool memory chef = MasterChefPool({
            chef: IMasterChef(_chef),
            pid: uint96(pid)
        });
        
        
        if (staked == address(GOV_TOKEN)) {
            chefs.push() = chef;
            sourceType[address(uint160(_chef) + pid)] = SourceType.CHEF_GOV;
        }
        else {
            require (sourceType[staked] == SourceType.LP, "staked token must be gov or gov-LP");
            sourceType[address(uint160(_chef) + pid)] = SourceType.CHEF_LP;
            
        }
        
    }
    function delChefPool(address _chef, uint96 pid) external onlyOperator {
        require(sourceType[address(uint160(_chef) + pid)] == SourceType.CHEF_GOV || sourceType[address(uint160(_chef) + pid)] == SourceType.CHEF_LP, "not a listed pool");
        for (uint i; i < pools.length; i++) {
            if (IMasterChef(_chef) == chefs[i].chef && pid == chefs[i].pid) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                sourceType[address(uint160(_chef) + pid)] = SourceType.NULL;
                return;
            }
        }
        assert(false);
    }
    function setAutoCrystl(address _auto) external onlyOperator {
        autoCrystl = IAutoCrystl(_auto);
    }
    
    function __init() external {
        __Ownable_init();
    }
}