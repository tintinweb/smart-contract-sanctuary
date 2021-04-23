/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// File: contracts/interfaces/IPriceModule.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IPriceModule
{
    function getUSDPrice(address ) external view returns(uint256);
}

// File: contracts/aps/APContract.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
// pragma experimental ABIEncoderV2;



contract APContract
{

    address public yieldsterDAO;

    address public yieldsterTreasury;

    address public yieldsterGOD;

    address public emergencyVault;

    address public yieldsterExchange;

    address public stringUtils;

    address public whitelistModule;

    address public whitelistManager;

    address public proxyFactory;

    address public priceModule;

    address public platFormManagementFee;

    address public profitManagementFee;

    address public stockDeposit;

    address public stockWithdraw;

    address public safeMinter;

    address public safeUtils;

    address public oneInch;

    struct Asset{
        string name;
        string symbol;
        bool created;
    }

    struct Protocol{
        string name;
        string symbol;
        bool created;
    }

    struct Vault {
        mapping(address => bool) vaultAssets;
        mapping(address => bool) vaultDepositAssets;
        mapping(address => bool) vaultWithdrawalAssets;
        mapping(address => bool) vaultEnabledStrategy;
        address depositStrategy;
        address withdrawStrategy;
        address vaultAPSManager;
        address vaultStrategyManager;
        uint256[] whitelistGroup;
        bool created;
    }

    struct VaultActiveStrategy {
        mapping(address => bool) isActiveStrategy;
        mapping(address => uint256) activeStrategyIndex;
        address[] activeStrategyList;
    }

    struct Strategy{
        string strategyName;
        mapping(address => bool) strategyProtocols;
        bool created;
        address minter;
        address executor;
        address benefeciary;
        uint256 managementFeePercentage;
    }

    struct SmartStrategy{
        string smartStrategyName;
        address minter;
        address executor;
        bool created;
 
    }

    struct vaultActiveManagemetFee {
        mapping(address => bool) isActiveManagementFee;
        mapping(address => uint256) activeManagementFeeIndex;
        address[] activeManagementFeeList;
    }

    event VaultCreation(address vaultAddress);

    mapping(address => vaultActiveManagemetFee) managementFeeStrategies;

    mapping(address => mapping(address => mapping(address => bool))) vaultStrategyEnabledProtocols;

    mapping(address => VaultActiveStrategy) vaultActiveStrategies;
    
    mapping(address => Asset) assets;

    mapping(address => Protocol) protocols;

    mapping(address => Vault) vaults;

    mapping(address => Strategy) strategies;

    mapping(address => SmartStrategy) smartStrategies;

    mapping(address => address) safeOwner;
    
    mapping(address => bool) APSManagers;

    mapping(address => address) minterStrategyMap;

    
    constructor(
        address _whitelistModule,
        address _platformManagementFee,
        address _profitManagementFee,
        address _stringUtils,
        address _yieldsterExchange,
        address _oneInch,
        address _priceModule,
        address _safeUtils
    ) 
    public
    {
        yieldsterDAO = msg.sender;
        yieldsterTreasury = msg.sender;
        yieldsterGOD = msg.sender;
        emergencyVault = msg.sender;
        APSManagers[msg.sender] = true;
        whitelistModule = _whitelistModule;
        platFormManagementFee = _platformManagementFee;
        stringUtils = _stringUtils;
        yieldsterExchange = _yieldsterExchange;
        oneInch = _oneInch;
        priceModule = _priceModule;
        safeUtils = _safeUtils;
        profitManagementFee = _profitManagementFee;
    }

    /// @dev Function to add proxy Factory address to Yieldster.
    /// @param _proxyFactory Address of proxy factory.
    function addProxyFactory(address _proxyFactory)
        public
        onlyManager
    {
        proxyFactory = _proxyFactory;
    }

    function setProfitAndPlatformManagementFeeStrategies(address _platformManagement,address _profitManagement)
        public
        onlyYieldsterDAO
    {
        if (_profitManagement != address(0)) profitManagementFee = _profitManagement;
        if (_platformManagement != address(0)) platFormManagementFee = _platformManagement;
    }

//Modifiers
    modifier onlyYieldsterDAO{
        require(yieldsterDAO == msg.sender, "Only Yieldster DAO is allowed to perform this operation");
        _;
    }

    modifier onlyManager{
        require(APSManagers[msg.sender], "Only APS managers allowed to perform this operation!");
        _;
    }

    modifier onlySafeOwner{
        require(safeOwner[msg.sender] == tx.origin, "Only safe Owner can perform this operation");
        _;
    }


    function isVault( address _address) public view returns(bool){
       return vaults[_address].created;
    }


    /// @dev Function to add APS manager to Yieldster.
    /// @param _manager Address of the manager.
    function addManager(address _manager) 
        public
        onlyYieldsterDAO
    {
        APSManagers[_manager] = true;
    }

    /// @dev Function to remove APS manager from Yieldster.
    /// @param _manager Address of the manager.
    function removeManager(address _manager)
        public
        onlyYieldsterDAO
    {
        APSManagers[_manager] = false;
    } 

    /// @dev Function to change whitelist Manager.
    /// @param _whitelistManager Address of the whitelist manager.
    function changeWhitelistManager(address _whitelistManager)
        public
        onlyYieldsterDAO
    {
        whitelistManager = _whitelistManager;
    }

    /// @dev Function to set Yieldster GOD.
    /// @param _yieldsterGOD Address of the Yieldster GOD.
    function setYieldsterGOD(address _yieldsterGOD)
        public
    {
        require(msg.sender == yieldsterGOD, "Only Yieldster GOD can perform this operation");
        yieldsterGOD = _yieldsterGOD;
    }

    /// @dev Function to disable Yieldster GOD.
    function disableYieldsterGOD()
        public
    {
        require(msg.sender == yieldsterGOD, "Only Yieldster GOD can perform this operation");
        yieldsterGOD = address(0);
    }

    /// @dev Function to set Emergency vault.
    /// @param _emergencyVault Address of the Yieldster Emergency vault.
    function setEmergencyVault(address _emergencyVault)
        onlyYieldsterDAO
        public
    {
        emergencyVault = _emergencyVault;
    }


    /// @dev Function to set Safe Minter.
    /// @param _safeMinter Address of the Safe Minter.
    function setSafeMinter(address _safeMinter)
        onlyYieldsterDAO
        public
    {
        safeMinter = _safeMinter;
    }

    /// @dev Function to set safeUtils contract.
    /// @param _safeUtils Address of the safeUtils contract.
    function setSafeUtils(address _safeUtils)
        onlyYieldsterDAO
        public
    {
        safeUtils = _safeUtils;
    }

    /// @dev Function to set oneInch address.
    /// @param _oneInch Address of the oneInch.
    function setOneInch(address _oneInch)
        onlyYieldsterDAO
        public
    {
        oneInch = _oneInch;
    }

    /// @dev Function to get strategy address from minter.
    /// @param _minter Address of the minter.
    function getStrategyFromMinter(address _minter) 
        external 
        view 
        returns(address)
    {
       return minterStrategyMap[_minter];

    }

    /// @dev Function to set Yieldster Exchange.
    /// @param _yieldsterExchange Address of the Yieldster exchange.
    function setYieldsterExchange(address _yieldsterExchange)
        onlyYieldsterDAO
        public
    {
        yieldsterExchange = _yieldsterExchange;
    }

    /// @dev Function to set stock Deposit and Withdraw.
    /// @param _stockDeposit Address of the stock deposit contract.
    /// @param _stockWithdraw Address of the stock withdraw contract.
    function setStockDepositWithdraw(address _stockDeposit, address _stockWithdraw)
        onlyYieldsterDAO
        public
    {
        stockDeposit = _stockDeposit;
        stockWithdraw = _stockWithdraw;
    }


    /// @dev Function to change the APS Manager for a vault.
    /// @param _vaultAPSManager Address of the new APS Manager.
    function changeVaultAPSManager(address _vaultAPSManager)
        external
    {
        require(vaults[msg.sender].created, "Vault is not present");
        vaults[msg.sender].vaultAPSManager = _vaultAPSManager;
    }

    /// @dev Function to change the Strategy Manager for a vault.
    /// @param _vaultStrategyManager Address of the new Strategy Manager.
    function changeVaultStrategyManager(address _vaultStrategyManager)
        external
    {
        require(vaults[msg.sender].created, "Vault is not present");
        vaults[msg.sender].vaultStrategyManager = _vaultStrategyManager;
    }

//Price Module
    /// @dev Function to set Yieldster price module.
    /// @param _priceModule Address of the price module.
    function setPriceModule(address _priceModule)
        public
        onlyManager
    {
        priceModule = _priceModule;
    }

    /// @dev Function to get the USD price for a token.
    /// @param _tokenAddress Address of the token.
    function getUSDPrice(address _tokenAddress) 
        public 
        view
        returns(uint256)
    {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        return IPriceModule(priceModule).getUSDPrice(_tokenAddress);
    }


//Vaults
    /// @dev Function to create a vault.
    /// @param _owner Address of the owner of the vault.
    /// @param _vaultAddress Address of the new vault.
    function createVault(address _owner, address _vaultAddress)
    public
    {
        require(msg.sender == proxyFactory, "Only Proxy Factory can perform this operation");
        safeOwner[_vaultAddress] = _owner;
    }


    /// @dev Function to add a vault in the APS.
    /// @param _vaultAPSManager Address of the vaults APS Manager.
    /// @param _vaultStrategyManager Address of the vaults Strateg Manager.
    /// @param _whitelistGroup List of whitelist groups applied to the vault.
    /// @param _owner Address of the vault owner.
    function addVault(
        address _vaultAPSManager,
        address _vaultStrategyManager,
        uint256[] memory _whitelistGroup,
        address _owner
    )
    public
    {   
        require(safeOwner[msg.sender] == _owner, "Only owner can call this function");
        Vault memory newVault = Vault(
            {
            vaultAPSManager : _vaultAPSManager, 
            vaultStrategyManager : _vaultStrategyManager,
            whitelistGroup : _whitelistGroup,
            depositStrategy: stockDeposit,
            withdrawStrategy: stockWithdraw,
            created : true
            });
        vaults[msg.sender] = newVault;

        //applying Platform management fee
        managementFeeStrategies[msg.sender].isActiveManagementFee[platFormManagementFee] = true;
        managementFeeStrategies[msg.sender].activeManagementFeeIndex[platFormManagementFee] = managementFeeStrategies[msg.sender].activeManagementFeeList.length;
        managementFeeStrategies[msg.sender].activeManagementFeeList.push(platFormManagementFee);

        //applying Profit management fee
        managementFeeStrategies[msg.sender].isActiveManagementFee[profitManagementFee] = true;
        managementFeeStrategies[msg.sender].activeManagementFeeIndex[profitManagementFee] = managementFeeStrategies[msg.sender].activeManagementFeeList.length;
        managementFeeStrategies[msg.sender].activeManagementFeeList.push(profitManagementFee);
    }

    /// @dev Function to Manage the vault assets.
    /// @param _enabledDepositAsset List of deposit assets to be enabled in the vault.
    /// @param _enabledWithdrawalAsset List of withdrawal assets to be enabled in the vault.
    /// @param _disabledDepositAsset List of deposit assets to be disabled in the vault.
    /// @param _disabledWithdrawalAsset List of withdrawal assets to be disabled in the vault.
    function setVaultAssets(
        address[] memory _enabledDepositAsset,
        address[] memory _enabledWithdrawalAsset,
        address[] memory _disabledDepositAsset,
        address[] memory _disabledWithdrawalAsset
    )
    public
    {
        require(vaults[msg.sender].created, "Vault not present");

        for (uint256 i = 0; i < _enabledDepositAsset.length; i++) {
            address asset = _enabledDepositAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = true;
            vaults[msg.sender].vaultDepositAssets[asset] = true;
        }

        for (uint256 i = 0; i < _enabledWithdrawalAsset.length; i++) {
            address asset = _enabledWithdrawalAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = true;
            vaults[msg.sender].vaultWithdrawalAssets[asset] = true;
        }

        for (uint256 i = 0; i < _disabledDepositAsset.length; i++) {
            address asset = _disabledDepositAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = false;
            vaults[msg.sender].vaultDepositAssets[asset] = false;
        }

        for (uint256 i = 0; i < _disabledWithdrawalAsset.length; i++) {
            address asset = _disabledWithdrawalAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = false;
            vaults[msg.sender].vaultWithdrawalAssets[asset] = false;
        }
    }

    /// @dev Function to get the list of management fee strategies applied to the vault.
    function getVaultManagementFee()
        public
        view
        returns(address[] memory)
    {
        require(vaults[msg.sender].created, "Vault not present");
        return managementFeeStrategies[msg.sender].activeManagementFeeList;
    }

    /// @dev Function to get the deposit strategy applied to the vault.
    function getDepositStrategy()
        public
        view
        returns(address)
    {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].depositStrategy;
    }

    /// @dev Function to get the withdrawal strategy applied to the vault.
    function getWithdrawStrategy()
        public
        view
        returns(address)
    {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].withdrawStrategy;
    }

    /// @dev Function to set the management fee strategies applied to a vault.
    /// @param _vaultAddress Address of the vault.
    /// @param _managementFeeAddress Address of the management fee strategy.
    function setManagementFeeStrategies(address _vaultAddress, address _managementFeeAddress)
        public
    {
        require(vaults[_vaultAddress].created, "Vault not present");
        require(vaults[_vaultAddress].vaultStrategyManager == msg.sender, "Sender not Authorized");
        managementFeeStrategies[_vaultAddress].isActiveManagementFee[_managementFeeAddress] = true;
        managementFeeStrategies[_vaultAddress].activeManagementFeeIndex[_managementFeeAddress] = managementFeeStrategies[_vaultAddress].activeManagementFeeList.length;
        managementFeeStrategies[_vaultAddress].activeManagementFeeList.push(_managementFeeAddress);
    }

    /// @dev Function to deactivate a vault strategy.
    /// @param _managementFeeAddress Address of the Management Fee Strategy.
    function removeManagementFeeStrategies(address _vaultAddress, address _managementFeeAddress)
        public
    {
        require(vaults[_vaultAddress].created, "Vault not present");
        require(managementFeeStrategies[_vaultAddress].isActiveManagementFee[_managementFeeAddress], "Provided ManagementFee is not active");
        require(vaults[_vaultAddress].vaultStrategyManager == msg.sender || yieldsterDAO == msg.sender, "Sender not Authorized");
        require(platFormManagementFee != _managementFeeAddress || yieldsterDAO == msg.sender,"Platfrom Management only changable by dao!");
        managementFeeStrategies[_vaultAddress].isActiveManagementFee[_managementFeeAddress] = false;

        if(managementFeeStrategies[_vaultAddress].activeManagementFeeList.length == 1) {
            managementFeeStrategies[_vaultAddress].activeManagementFeeList.pop();
        } else {
            uint256 index = managementFeeStrategies[_vaultAddress].activeManagementFeeIndex[_managementFeeAddress];
            uint256 lastIndex = managementFeeStrategies[_vaultAddress].activeManagementFeeList.length - 1;
            delete managementFeeStrategies[_vaultAddress].activeManagementFeeList[index];
            managementFeeStrategies[_vaultAddress].activeManagementFeeIndex[managementFeeStrategies[_vaultAddress].activeManagementFeeList[lastIndex]] = index;
            managementFeeStrategies[_vaultAddress].activeManagementFeeList[index] = managementFeeStrategies[_vaultAddress].activeManagementFeeList[lastIndex];
            managementFeeStrategies[_vaultAddress].activeManagementFeeList.pop();
        }
    }

    /// @dev Function to set vault active strategy.
    /// @param _strategyAddress Address of the strategy.
    function setVaultActiveStrategy(address _strategyAddress)
        public
    {
        require(vaults[msg.sender].created, "Vault not present");
        require(strategies[_strategyAddress].created, "Strategy not present");
        vaultActiveStrategies[msg.sender].isActiveStrategy[_strategyAddress] = true;
        vaultActiveStrategies[msg.sender].activeStrategyIndex[_strategyAddress] = vaultActiveStrategies[msg.sender].activeStrategyList.length;
        vaultActiveStrategies[msg.sender].activeStrategyList.push(_strategyAddress);
    }

    /// @dev Function to deactivate a vault strategy.
    /// @param _strategyAddress Address of the strategy.
    function deactivateVaultStrategy(address _strategyAddress)
        public
    {
        require(vaults[msg.sender].created, "Vault not present");
        require(vaultActiveStrategies[msg.sender].isActiveStrategy[_strategyAddress], "Provided strategy is not active");
        vaultActiveStrategies[msg.sender].isActiveStrategy[_strategyAddress] = false;

        if(vaultActiveStrategies[msg.sender].activeStrategyList.length == 1) {
            vaultActiveStrategies[msg.sender].activeStrategyList.pop();
        } else {
            uint256 index = vaultActiveStrategies[msg.sender].activeStrategyIndex[_strategyAddress];
            uint256 lastIndex = vaultActiveStrategies[msg.sender].activeStrategyList.length - 1;
            delete vaultActiveStrategies[msg.sender].activeStrategyList[index];
            vaultActiveStrategies[msg.sender].activeStrategyIndex[vaultActiveStrategies[msg.sender].activeStrategyList[lastIndex]] = index;
            vaultActiveStrategies[msg.sender].activeStrategyList[index] = vaultActiveStrategies[msg.sender].activeStrategyList[lastIndex];
            vaultActiveStrategies[msg.sender].activeStrategyList.pop();
        }
    }

    /// @dev Function to get vault active strategy.
    function getVaultActiveStrategy(address _vaultAddress)
        public
        view
        returns(address[] memory)
    {
        require(vaults[_vaultAddress].created, "Vault not present");
        return vaultActiveStrategies[_vaultAddress].activeStrategyList;
    }

    function isStrategyActive(address _vaultAddress, address _strategyAddress)
        public
        view
        returns(bool)
    {
        return vaultActiveStrategies[_vaultAddress].isActiveStrategy[_strategyAddress];
    }

    function getStrategyManagementDetails(address _vaultAddress, address _strategyAddress)
        public
        view
        returns(address, uint256)
    {
        require(vaults[_vaultAddress].created, "Vault not present");
        require(strategies[_strategyAddress].created, "Strategy not present");
        require(vaultActiveStrategies[_vaultAddress].isActiveStrategy[_strategyAddress], "Strategy not Active");
        return (strategies[_strategyAddress].benefeciary, strategies[_strategyAddress].managementFeePercentage);
    }

    /// @dev Function to Manage the vault strategies.
    /// @param _vaultStrategy Address of the strategy.
    /// @param _enabledStrategyProtocols List of protocols that are enabled in the strategy.
    /// @param _disabledStrategyProtocols List of protocols that are disabled in the strategy.
    /// @param _assetsToBeEnabled List of assets that have to be enabled along with the strategy.
    function setVaultStrategyAndProtocol(
        address _vaultStrategy,
        address[] memory _enabledStrategyProtocols,
        address[] memory _disabledStrategyProtocols,
        address[] memory _assetsToBeEnabled
    )
    public
    {
        require(vaults[msg.sender].created, "Vault not present");
        require(strategies[_vaultStrategy].created, "Strategy not present");
        vaults[msg.sender].vaultEnabledStrategy[_vaultStrategy] = true;

        for (uint256 i = 0; i < _enabledStrategyProtocols.length; i++) {
            address protocol = _enabledStrategyProtocols[i];
            require(_isProtocolPresent(protocol), "Protocol not supported by Yieldster");
            vaultStrategyEnabledProtocols[msg.sender][_vaultStrategy][protocol] = true;
        }

        for (uint256 i = 0; i < _disabledStrategyProtocols.length; i++) {
            address protocol = _disabledStrategyProtocols[i];
            require(_isProtocolPresent(protocol), "Protocol not supported by Yieldster");
            vaultStrategyEnabledProtocols[msg.sender][_vaultStrategy][protocol] = false;
        }

        for (uint256 i = 0; i < _assetsToBeEnabled.length; i++) {
            address asset = _assetsToBeEnabled[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = true;
            vaults[msg.sender].vaultDepositAssets[asset] = true;
            vaults[msg.sender].vaultWithdrawalAssets[asset] = true;
        }

    }

    /// @dev Function to disable the vault strategies.
    /// @param _strategyAddress Address of the strategy.
    /// @param _assetsToBeDisabled List of assets that have to be disabled along with the strategy.
    function disableVaultStrategy(address _strategyAddress, address[] memory _assetsToBeDisabled)
        public
    {
        require(vaults[msg.sender].created, "Vault not present");
        require(strategies[_strategyAddress].created, "Strategy not present");
        require(vaults[msg.sender].vaultEnabledStrategy[_strategyAddress], "Strategy was not enabled");
        vaults[msg.sender].vaultEnabledStrategy[_strategyAddress] = false;

        for (uint256 i = 0; i < _assetsToBeDisabled.length; i++) {
            address asset = _assetsToBeDisabled[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = false;
            vaults[msg.sender].vaultDepositAssets[asset] = false;
            vaults[msg.sender].vaultWithdrawalAssets[asset] = false;
        }
    }

    /// @dev Function to set smart strategy applied to the vault.
    /// @param _smartStrategyAddress Address of the smart strategy.
    /// @param _type type of smart strategy(deposit or withdraw).
    function setVaultSmartStrategy(address _smartStrategyAddress, uint256 _type)
        public
    {
        require(vaults[msg.sender].created, "Vault not present");
        require(_isSmartStrategyPresent(_smartStrategyAddress),"Smart Strategy not Supported by Yieldster");
        if(_type == 1){
            vaults[msg.sender].depositStrategy = _smartStrategyAddress;
        }
        else if(_type == 2){
            vaults[msg.sender].withdrawStrategy = _smartStrategyAddress;
        }
        else{
            revert("Invalid type provided");
        }
    }

    /// @dev Function to check if a particular protocol is enabled in a strategy for a vault.
    /// @param _vaultAddress Address of the vault.
    /// @param _strategyAddress Address of the strategy.
    /// @param _protocolAddress Address of the protocol to check.
    function _isStrategyProtocolEnabled(
        address _vaultAddress, 
        address _strategyAddress, 
        address _protocolAddress
    )
    public
    view
    returns(bool)
    {
        if( vaults[_vaultAddress].created &&
            strategies[_strategyAddress].created &&
            protocols[_protocolAddress].created &&
            vaults[_vaultAddress].vaultEnabledStrategy[_strategyAddress] &&
            vaultStrategyEnabledProtocols[_vaultAddress][_strategyAddress][_protocolAddress]){
            return true;
        }
        else{
            return false;
        }
    }

    /// @dev Function to check if a strategy is enabled for the vault.
    /// @param _vaultAddress Address of the vault.
    /// @param _strategyAddress Address of the strategy.
    function _isStrategyEnabled(
        address _vaultAddress, 
        address _strategyAddress
    )
    public
    view
    returns(bool)
    {
        if(vaults[_vaultAddress].created &&
            strategies[_strategyAddress].created &&
            vaults[_vaultAddress].vaultEnabledStrategy[_strategyAddress]){
            return true;
        }
        else{
            return false;
        }
    }

    /// @dev Function to check if the asset is supported by the vault.
    /// @param cleanUpAsset Address of the asset.
    function _isVaultAsset(address cleanUpAsset)
        public
        view
        returns(bool)
    {
        require(vaults[msg.sender].created, "Vault is not present");
        return vaults[msg.sender].vaultAssets[cleanUpAsset];

    }
       

// Assets
    /// @dev Function to check if an asset is supported by Yieldster.
    /// @param _address Address of the asset.
    function _isAssetPresent(address _address) 
        private 
        view 
        returns(bool)
    {
        return assets[_address].created;
    }
    
    /// @dev Function to add an asset to the Yieldster.
    /// @param _symbol Symbol of the asset.
    /// @param _name Name of the asset.
    /// @param _tokenAddress Address of the asset.
    function addAsset(
        string memory _symbol, 
        string memory _name,
        address _tokenAddress
        ) 
        public 
        onlyManager
    {
        require(!_isAssetPresent(_tokenAddress),"Asset already present!");
        Asset memory newAsset = Asset({name:_name, symbol:_symbol, created:true});
        assets[_tokenAddress] = newAsset;
    }

    /// @dev Function to remove an asset from the Yieldster.
    /// @param _tokenAddress Address of the asset.
    function removeAsset(address _tokenAddress) 
        public 
        onlyManager
    {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        delete assets[_tokenAddress];
    }
    
    /// @dev Function to check if an asset is supported deposit asset in the vault.
    /// @param _assetAddress Address of the asset.
    function isDepositAsset(address _assetAddress)
        public
        view
        returns(bool)
    {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].vaultDepositAssets[_assetAddress];
    }

    /// @dev Function to check if an asset is supported withdrawal asset in the vault.
    /// @param _assetAddress Address of the asset.
    function isWithdrawalAsset(address _assetAddress)
        public
        view
        returns(bool)
    {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].vaultWithdrawalAssets[_assetAddress];
    }

//Strategies
    /// @dev Function to check if a strategy is supported by Yieldster.
    /// @param _address Address of the strategy.
    function _isStrategyPresent(address _address) 
        private 
        view 
        returns(bool)
    {
        return strategies[_address].created;
    }

    /// @dev Function to add a strategy to Yieldster.
    /// @param _strategyName Name of the strategy.
    /// @param _strategyAddress Address of the strategy.
    /// @param _strategyAddress List of protocols present in the strategy.
    /// @param _minter Address of strategy minter.
    /// @param _executor Address of strategy executor.
    function addStrategy(
        string memory _strategyName,
        address _strategyAddress,
        address[] memory _strategyProtocols,
        address _minter,
        address _executor,
        address _benefeciary,
        uint256 _managementFeePercentage
        ) 
        public 
        onlyManager
    {
        require(!_isStrategyPresent(_strategyAddress),"Strategy already present!");
        Strategy memory newStrategy = Strategy({ strategyName:_strategyName, created:true, minter:_minter, executor:_executor, benefeciary:_benefeciary, managementFeePercentage: _managementFeePercentage});
        strategies[_strategyAddress] = newStrategy;
        minterStrategyMap[_minter] = _strategyAddress;

        for (uint256 i = 0; i < _strategyProtocols.length; i++) {
            address protocol = _strategyProtocols[i];
            require(_isProtocolPresent(protocol), "Protocol not supported by Yieldster");
            strategies[_strategyAddress].strategyProtocols[protocol] = true;
        }
    }

    /// @dev Function to remove a strategy from Yieldster.
    /// @param _strategyAddress Address of the strategy.
    function removeStrategy(address _strategyAddress) 
        public 
        onlyManager
    {
        require(_isStrategyPresent(_strategyAddress),"Strategy not present!");
        delete strategies[_strategyAddress];
    }

    /// @dev Function to get strategy executor address.
    /// @param _strategy Address of the strategy.
    function strategyExecutor(address _strategy) 
        external 
        view 
        returns(address)
    {
        return strategies[_strategy].executor;
    }

    /// @dev Function to change executor of strategy.
    /// @param _strategyAddress Address of the strategy.
    /// @param _executor Address of the executor.
    function changeStrategyExecutor(address _strategyAddress, address _executor) 
        public 
        onlyManager
    {
        require(_isStrategyPresent(_strategyAddress),"Strategy not present!");
        strategies[_strategyAddress].executor = _executor;
    }

//Smart Strategy
    /// @dev Function to check if a smart strategy is supported by Yieldster.
    /// @param _address Address of the smart strategy.
    function _isSmartStrategyPresent(address _address) 
        private 
        view 
        returns(bool)
    {
        return smartStrategies[_address].created;
    }

    /// @dev Function to add a smart strategy to Yieldster.
    /// @param _smartStrategyName Name of the smart strategy.
    /// @param _smartStrategyAddress Address of the smart strategy.
    function addSmartStrategy(
        string memory _smartStrategyName,
        address _smartStrategyAddress,
        address _minter,
        address _executor
        ) 
        public 
        onlyManager
    {
        require(!_isSmartStrategyPresent(_smartStrategyAddress),"Smart Strategy already present!");
        SmartStrategy memory newSmartStrategy = SmartStrategy
            ({  smartStrategyName : _smartStrategyName,
                minter : _minter,
                executor : _executor,
                created : true });
        smartStrategies[_smartStrategyAddress] = newSmartStrategy;
        minterStrategyMap[_minter] = _smartStrategyAddress;
    }

    /// @dev Function to remove a smart strategy from Yieldster.
    /// @param _smartStrategyAddress Address of the smart strategy.
    function removeSmartStrategy(address _smartStrategyAddress) 
        public 
        onlyManager
    {
        require(!_isSmartStrategyPresent(_smartStrategyAddress),"Smart Strategy not present");
        delete smartStrategies[_smartStrategyAddress];
    }

    /// @dev Function to get ssmart strategy executor address.
    /// @param _smartStrategy Address of the strategy.
    function smartStrategyExecutor(address _smartStrategy) 
        external 
        view 
        returns(address)
    {
        return smartStrategies[_smartStrategy].executor;
    }

    /// @dev Function to change executor of smart strategy.
    /// @param _smartStrategy Address of the smart strategy.
    /// @param _executor Address of the executor.
    function changeSmartStrategyExecutor(address _smartStrategy, address _executor) 
        public 
        onlyManager
    {
        require(_isSmartStrategyPresent(_smartStrategy),"Smart Strategy not present!");
        smartStrategies[_smartStrategy].executor = _executor;
    }

// Protocols
    /// @dev Function to check if a protocol is supported by Yieldster.
    /// @param _address Address of the protocol.
    function _isProtocolPresent(address _address) 
        private 
        view 
        returns(bool)
    {
        return protocols[_address].created;
    }

    /// @dev Function to add a protocol to Yieldster.
    /// @param _symbol symbol of the protocol.
    /// @param _name Name of the protocol.
    /// @param _protocolAddress Address of the protocol.
    function addProtocol(
        string memory _symbol,
        string memory _name,
        address _protocolAddress
        ) 
        public 
        onlyManager
    {
        require(!_isProtocolPresent(_protocolAddress),"Protocol already present!");
        Protocol memory newProtocol = Protocol({ name:_name, created:true, symbol:_symbol });
        protocols[_protocolAddress] = newProtocol;
    }

    /// @dev Function to remove a protocol from Yieldster.
    /// @param _protocolAddress Address of the protocol.
    function removeProtocol(address _protocolAddress) 
        public 
        onlyManager
    {
        require(_isProtocolPresent(_protocolAddress),"Protocol not present!");
        delete protocols[_protocolAddress];
    }
}