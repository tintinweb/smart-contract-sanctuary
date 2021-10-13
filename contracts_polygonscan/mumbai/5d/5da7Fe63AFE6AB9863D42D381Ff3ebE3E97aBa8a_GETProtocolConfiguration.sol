/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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


// File contracts/utils/ContextUpgradeable.sol


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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/utils/OwnableUpgradeable.sol


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
    uint256[49] private __gap;
}


// File contracts/interfaces/IsyncConfiguration.sol

pragma solidity ^0.8.0;

interface IsyncConfiguration {
    function syncConfiguration() external returns(bool);
}


// File contracts/interfaces/IGETProtocolConfiguration.sol

pragma solidity ^0.8.0;

interface IGETProtocolConfiguration {

    function GETgovernanceAddress() external view returns(address);
    function feeCollectorAddress() external view returns(address);
    function treasuryDAOAddress() external view returns(address);
    function stakingContractAddress() external view returns(address);
    function emergencyAddress() external view returns(address);
    function bufferAddress() external view returns(address);


    function AccessControlGET_proxy_address() external view returns(address);
    function baseGETNFT_proxy_address() external view returns(address);
    function getNFT_ERC721_proxy_address() external view returns(address);
    function eventMetadataStorage_proxy_address() external view returns(address);
    function getEventFinancing_proxy_address() external view returns(address);
    function economicsGET_proxy_address() external view returns(address);
    function fueltoken_get_address() external view returns(address);

    function basicTaxRate() external view returns(uint256);
    
    function priceGETUSD() external view returns(uint256);

    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external;

}


// File contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

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
}


// File contracts/GETProtocolConfiguration.sol

pragma solidity ^0.8.0;





contract GETProtocolConfiguration is Initializable, ContextUpgradeable, OwnableUpgradeable {

    address public GETgovernanceAddress;
    address payable public feeCollectorAddress; 
    address payable public treasuryDAOAddress;
    address payable public stakingContractAddress;
    address payable public emergencyAddress; 
    address payable public bufferAddress;

    address private proxyAdminAddress;
    address public AccessControlGET_proxy_address;
    address public baseGETNFT_proxy_address;
    address public getNFT_ERC721_proxy_address;
    address public eventMetadataStorage_proxy_address;
    address public getEventFinancing_proxy_address;
    address public economicsGET_proxy_address;
    address public fueltoken_get_address;

    /// global economics configurations (Work in progress)
    uint256 public basicTaxRate;

    /// GET and USD price oracle/price feed configurations (work in progress)
    uint256 public priceGETUSD; // x1000
    IUniswapV2Pair public liquidityPoolGETETH;
    IUniswapV2Pair public liquidityPoolETHUSDC;

    function __GETProtocolConfiguration_init_unchained() public initializer {}

    function __GETProtocolConfiguration_init() public initializer {
        __Context_init();
        __Ownable_init();
        __GETProtocolConfiguration_init_unchained();
    }

    /// EVENTS

    event UpdateAccessControl(address _old, address _new);
    event UpdatebaseGETNFT(address _old, address _new);
    event UpdateERC721(address _old, address _new);
    event UpdateMetdata(address _old, address _new);
    event UpdateFinancing(address _old, address _new);
    event UpdateEconomics(address _old, address _new);
    event UpdateFueltoken(address _old, address _new);

    event UpdateGoverance(address _old, address _new);
    event UpdateFeeCollector(address _old, address _new);
    event UpdateTreasuryDAO(address _old, address _new);
    event UpdateStakingContract(address _old, address _new);
    event UpdateBasicTaxRate(uint256 _old, uint256 _new);
    event UpdateGETUSD(uint256 _old, uint256 _new);

    event UpdateLiquidityPoolAddress(
        address _oldPoolGETETH, 
        address _oldPoolUSDCETH, 
        address _newPoolGETETH, 
        address _newPoolUSDCETH
    );
    

    event SyncComplete(
        address new_baseGETNFT_proxy_address,
        address new_economicsGET_proxy_address,
        address new_eventMetadataStorage_proxy_address,
        address new_getEventFinancing_proxy_address,
        address new_getNFT_ERC721_proxy_address,
        address new_accesscontrol_proxy_address
    );

    /// INITIALIZATION


    // this function only needs to be used once, after the initial deploy
    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external onlyOwner {
        // require(isContract(_access_control_proxy), "_access_control_proxy not a contract");
        AccessControlGET_proxy_address = _access_control_proxy;

        // require(isContract(_base_proxy), "_base_proxy not a contract");
        baseGETNFT_proxy_address = _base_proxy;

        // require(isContract(_erc721_proxy), "_erc721_proxy not a contract");
        getNFT_ERC721_proxy_address = _erc721_proxy;

        // require(isContract(_metadata_proxy), "_metadata_proxy not a contract");
        eventMetadataStorage_proxy_address = _metadata_proxy;

        // require(isContract(_financing_proxy), "_financing_proxy not a contract");
        getEventFinancing_proxy_address = _financing_proxy;

        // require(isContract(_economics_proxy), "_economics_proxy not a contract");
        economicsGET_proxy_address = _economics_proxy;
    
        // sync the change across all proxies
        _callSync();

    }

    // setting a new AccessControlGET_proxy_address Proxy address
    function setAccessControlGETProxy(
        address _access_control_proxy
        ) external onlyOwner {
        
        require(isContract(_access_control_proxy), "_access_control_proxy not a contract");

        emit UpdateAccessControl(
            AccessControlGET_proxy_address, 
            _access_control_proxy
        );

        AccessControlGET_proxy_address = _access_control_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setBASEProxy(
        address _base_proxy) external onlyOwner {
        
        require(isContract(_base_proxy), "_base_proxy not a contract");

        emit UpdatebaseGETNFT(
            baseGETNFT_proxy_address, 
            _base_proxy
        );

         baseGETNFT_proxy_address = _base_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setERC721Proxy(
        address _erc721_proxy) external onlyOwner {
        
        require(isContract(_erc721_proxy), "_erc721_proxy not a contract");

        emit UpdateERC721(
            getNFT_ERC721_proxy_address, 
            _erc721_proxy
        );

        getNFT_ERC721_proxy_address = _erc721_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setMetaProxy(
        address _metadata_proxy) external onlyOwner {
        
        require(isContract(_metadata_proxy), "_metadata_proxy not a contract");

        emit UpdateMetdata(
            eventMetadataStorage_proxy_address, 
            _metadata_proxy
        );

        eventMetadataStorage_proxy_address = _metadata_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setFinancingProxy(
        address _financing_proxy) external onlyOwner {
        
        require(isContract(_financing_proxy), "_financing_proxy not a contract");

        emit UpdateFinancing(
            getEventFinancing_proxy_address, 
            _financing_proxy
        );

        getEventFinancing_proxy_address = _financing_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setEconomicsProxy(
        address _economics_proxy) external onlyOwner {
        
        require(isContract(_economics_proxy), "_economics_proxy not a contract");

        emit UpdateEconomics(
            economicsGET_proxy_address, 
            _economics_proxy
        );

        economicsGET_proxy_address = _economics_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setgetNFT_ERC721(address _getNFT_ERC721) external onlyOwner {

        require(isContract(_getNFT_ERC721), "_getNFT_ERC721 not a contract");

        emit UpdateERC721(getNFT_ERC721_proxy_address, _getNFT_ERC721);

        getNFT_ERC721_proxy_address = _getNFT_ERC721;

        // sync the change across all proxies
        _callSync();

    }    

    function setFueltoken(address _fueltoken_get_address) external onlyOwner {

        require(isContract(_fueltoken_get_address), "_fueltoken_get_address not a contract");

        emit UpdateFueltoken(fueltoken_get_address, _fueltoken_get_address);

        fueltoken_get_address = _fueltoken_get_address;

        // sync the change across all proxies
        _callSync();
        
    }  

    /**
    @notice internal function calling all proxy contracts of the protocol and updating all the global values
     */
    function _callSync() internal {

        // UPDATE BASE
        require(IsyncConfiguration(baseGETNFT_proxy_address).syncConfiguration(), "FAILED_UPDATE_BASE");

        // UPDATE ECONOMICS
        require(IsyncConfiguration(economicsGET_proxy_address).syncConfiguration(), "FAILED_UPDATE_ECONOMICS");

        // UPDATE METADATA
        require(IsyncConfiguration(eventMetadataStorage_proxy_address).syncConfiguration(), "FAILED_UPDATE_METADATA");

        // UPDATE FINANCING 
        require(IsyncConfiguration(getEventFinancing_proxy_address).syncConfiguration(), "FAILED_UPDATE_FINANCE");

        // // UPDATE ERC721
        // require(IsyncConfiguration(getNFT_ERC721_proxy_address).syncConfiguration(), "FAILED_UPDATE_ERC721");

        // ACCESSCONTROL DOESNT NEED TO BE UPDATED, SINCE THE CONTRACT IS UNAWARE OF OTHER CONTRACTS

        emit SyncComplete(
            baseGETNFT_proxy_address,
            economicsGET_proxy_address,
            eventMetadataStorage_proxy_address,
            getEventFinancing_proxy_address,
            getNFT_ERC721_proxy_address,
            AccessControlGET_proxy_address
        );

    }

    // MANAGING GLOBAL VALUES


    function setGovernance(
        address _newGovernance
    ) external onlyOwner {

        // require(isContract(_newGovernance), "_newGovernance not a contract");

        emit UpdateGoverance(GETgovernanceAddress, _newGovernance);
        
        GETgovernanceAddress = _newGovernance;
        
    }

    function setFeeCollector(
        address payable _newFeeCollector
    ) external onlyOwner {

        require(_newFeeCollector != address(0), "_newFeeCollector cannot be burn address");
        
        emit UpdateFeeCollector(feeCollectorAddress, _newFeeCollector);

        feeCollectorAddress = _newFeeCollector;
        
    }    

    function setBufferAddress(
        address payable _newBuffer
    ) external onlyOwner {

        require(_newBuffer != address(0), "_newBuffer cannot be burn address");
        
        // emit updateFeeCollector(feeCollectorAddress, _newFeeCollector); TODO ADD EVENT

        bufferAddress = _newBuffer;
        
    }    

    function setTreasuryDAO(
        address payable _newTreasury
    ) external onlyOwner {

        require(_newTreasury != address(0), "_newTreasury cannot be 0x0");

        emit UpdateTreasuryDAO(treasuryDAOAddress, _newTreasury);

        treasuryDAOAddress = _newTreasury;

    }

    function setStakingContract(
        address payable _newStaking
    ) external onlyOwner {

        // require(isContract(_newStaking), "_newStaking not a contract");

        emit UpdateStakingContract(stakingContractAddress, _newStaking);

        stakingContractAddress = _newStaking;
        
    }

    function setBasicTaxRate(
        uint256 _basicTaxRate
    ) external onlyOwner {

        require(_basicTaxRate >= 0, "TAXRATE_INVALID");

        emit UpdateBasicTaxRate(basicTaxRate, _basicTaxRate);

        basicTaxRate = _basicTaxRate;
        
    }
    

    /** function that manually sets the price of GET in USD
    @notice this is a temporary approach, in the future it would make most sense to use LP pool TWAP oracles
    @dev as for every other contract the USD value is multiplied by 1000
     */
    function setGETUSD(
        uint256 _newGETUSD
    ) external onlyOwner {
        emit UpdateGETUSD(priceGETUSD, _newGETUSD);
        priceGETUSD = _newGETUSD;
    }

    // function setLiquidityPoolAddresses(
    //     address _poolGETETH,
    //     address _poolUSDCETH
    // ) external onlyOwner {
    //     liquidityPoolGETETH = IUniswapV2Pair(_poolGETETH);
    //     liquidityPoolETHUSDC = IUniswapV2Pair(_poolUSDCETH);
        
    //     emit UpdateLiquidityPoolAddress(
    //         liquidityPoolGETETH,
    //         liquidityPoolETHUSDC,
    //         _poolGETETH,
    //         _poolUSDCETH
    //     );
    // }    

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }


}