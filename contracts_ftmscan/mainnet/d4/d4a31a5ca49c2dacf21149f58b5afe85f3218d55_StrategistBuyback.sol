/**
 *Submitted for verification at FtmScan.com on 2021-11-29
*/

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



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


// File @openzeppelin/contracts-upgradeable/access/[email protected]



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


// File contracts/BIFI/interfaces/common/IUniswapRouterETH.sol



pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
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

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


// File contracts/BIFI/utils/StrategistBuyback.sol



pragma solidity ^0.8.0;
interface IStrategy_StrategistBuyback {
    function strategist() external view returns (address);
    function setStrategist(address) external;
}

interface IVault_StrategistBuyback {
    function depositAll() external;
    function withdrawAll() external;
    function strategy() external view returns (address);
}

interface IERC20_StrategistBuyback {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract StrategistBuyback is OwnableUpgradeable {
    // Tokens used
    address public native;
    address public want;

    address public bifiMaxi;
    address public unirouter;

    address[] public nativeToWantRoute;

    address[] public trackedVaults; // 1 indexed due to mapping having default value of 0.
    mapping(address => uint256) public trackedVaultsArrayIndex; // there will be dummy vault at index 0

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 mooTokenBalance);
    event WithdrawToken(address indexed token, uint256 amount);
    event TrackingVault(address indexed vaultAddress);
    event UntrackingVault(address indexed vaultAddress);

    function initialize(
        address _bifiMaxi,
        address _unirouter,
        address[] memory _nativeToWantRoute
    ) public initializer {
        __Ownable_init();

        bifiMaxi = _bifiMaxi;
        unirouter = _unirouter;

        _setNativeToWantRoute(_nativeToWantRoute);

        IERC20_StrategistBuyback(native).approve(unirouter, type(uint256).max);
        // approve spending by bifiMaxi
        IERC20_StrategistBuyback(native).approve(bifiMaxi, type(uint256).max);
        IERC20_StrategistBuyback(want).approve(bifiMaxi, type(uint256).max);

        trackVault(address(0)); // dummy vault to overcome issue where mapping values are defaulted to 0;
    }

    function depositVaultWantIntoBifiMaxi() external onlyOwner {
        _depositVaultWantIntoBifiMaxi();
    }

    function withdrawVaultWantFromBifiMaxi() external onlyOwner {
        _withdrawVaultWantFromBifiMaxi();
    }

    // Convert and send to beefy maxi
    function harvest() public {
        uint256 nativeBal = IERC20_StrategistBuyback(native).balanceOf(address(this));
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(nativeBal, 0, nativeToWantRoute, address(this), block.timestamp);

        uint256 wantHarvested = balanceOfWant();
        _depositVaultWantIntoBifiMaxi();

        emit StratHarvest(msg.sender, wantHarvested, balanceOfMooTokens());
    }

    function setVaultStrategist(address _vault, address _newStrategist) external onlyOwner {
        address strategy = address(IVault_StrategistBuyback(_vault).strategy());
        address strategist = IStrategy_StrategistBuyback(strategy).strategist();
        require(strategist == address(this), "Strategist buyback is not the strategist for the target vault");
        IStrategy_StrategistBuyback(strategy).setStrategist(_newStrategist);
    }

    function setUnirouter(address _unirouter) external onlyOwner {
        IERC20_StrategistBuyback(native).approve(_unirouter, type(uint256).max);
        IERC20_StrategistBuyback(native).approve(unirouter, 0);

        unirouter = _unirouter;
    }

    function setNativeToWantRoute(address[] memory _route) external onlyOwner {
        _setNativeToWantRoute(_route);
    }
    
    function withdrawToken(address _token) external onlyOwner {
        uint256 amount = IERC20_StrategistBuyback(_token).balanceOf(address(this));
        IERC20_StrategistBuyback(_token).transfer(msg.sender, amount);

        emit WithdrawToken(_token, amount);
    }

    function _depositVaultWantIntoBifiMaxi() internal {
        IVault_StrategistBuyback(bifiMaxi).depositAll();
    }

    function _withdrawVaultWantFromBifiMaxi() internal {
        IVault_StrategistBuyback(bifiMaxi).withdrawAll();
    }

    function _setNativeToWantRoute(address[] memory _route) internal {
        native = _route[0];
        want = _route[_route.length - 1];
        nativeToWantRoute = _route;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20_StrategistBuyback(want).balanceOf(address(this));
    }

    function balanceOfMooTokens() public view returns (uint256) {
        return IERC20_StrategistBuyback(bifiMaxi).balanceOf(address(this));
    }

    function trackVault(address _vaultAddress) public onlyOwner {
        trackedVaults.push(_vaultAddress);
        trackedVaultsArrayIndex[_vaultAddress] = trackedVaults.length - 1; // new vault will have last index of 
        emit TrackingVault(_vaultAddress);
    }

    function untrackVault(address _vaultAddress) external onlyOwner {
        require(trackedVaults.length > 1, "No vaults are being tracked.");
        uint256 foundVaultIndex = trackedVaultsArrayIndex[_vaultAddress];

        require(foundVaultIndex > 0, "Vault is not being tracked.");

        // make address at found index the address at last index, then pop last index.
        uint256 lastVaultIndex = trackedVaults.length - 1;

        address lastVaultAddress = trackedVaults[lastVaultIndex];
        // make vault to untrack point to 0 index (not tracked).
        trackedVaultsArrayIndex[_vaultAddress] = 0;
        // fix mapping so that the address of last vault index to now points to removed vault index.
        trackedVaultsArrayIndex[lastVaultAddress] = foundVaultIndex;
        // make remove vault index point to the last vault, as its taken its spot.
        trackedVaults[foundVaultIndex] = lastVaultAddress;
        trackedVaults.pop();

        emit UntrackingVault(_vaultAddress);
    }
}