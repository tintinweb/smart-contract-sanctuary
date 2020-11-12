pragma solidity 0.4.25;

// File: contracts/sogur/interfaces/IMonetaryModel.sol

/**
 * @title Monetary Model Interface.
 */
interface IMonetaryModel {
    /**
     * @dev Buy SGR in exchange for SDR.
     * @param _sdrAmount The amount of SDR received from the buyer.
     * @return The amount of SGR that the buyer is entitled to receive.
     */
    function buy(uint256 _sdrAmount) external returns (uint256);

    /**
     * @dev Sell SGR in exchange for SDR.
     * @param _sgrAmount The amount of SGR received from the seller.
     * @return The amount of SDR that the seller is entitled to receive.
     */
    function sell(uint256 _sgrAmount) external returns (uint256);
}

// File: contracts/sogur/interfaces/IReconciliationAdjuster.sol

/**
 * @title Reconciliation Adjuster Interface.
 */
interface IReconciliationAdjuster {
    /**
     * @dev Get the buy-adjusted value of a given SDR amount.
     * @param _sdrAmount The amount of SDR to adjust.
     * @return The adjusted amount of SDR.
     */
    function adjustBuy(uint256 _sdrAmount) external view returns (uint256);

    /**
     * @dev Get the sell-adjusted value of a given SDR amount.
     * @param _sdrAmount The amount of SDR to adjust.
     * @return The adjusted amount of SDR.
     */
    function adjustSell(uint256 _sdrAmount) external view returns (uint256);
}

// File: contracts/sogur/interfaces/ITransactionManager.sol

/**
 * @title Transaction Manager Interface.
 */
interface ITransactionManager {
    /**
     * @dev Buy SGR in exchange for ETH.
     * @param _ethAmount The amount of ETH received from the buyer.
     * @return The amount of SGR that the buyer is entitled to receive.
     */
    function buy(uint256 _ethAmount) external returns (uint256);

    /**
     * @dev Sell SGR in exchange for ETH.
     * @param _sgrAmount The amount of SGR received from the seller.
     * @return The amount of ETH that the seller is entitled to receive.
     */
    function sell(uint256 _sgrAmount) external returns (uint256);
}

// File: contracts/sogur/interfaces/ITransactionLimiter.sol

/**
 * @title Transaction Limiter Interface.
 */
interface ITransactionLimiter {
    /**
     * @dev Reset the total buy-amount and the total sell-amount.
     */
    function resetTotal() external;

    /**
     * @dev Increment the total buy-amount.
     * @param _amount The amount to increment by.
     */
    function incTotalBuy(uint256 _amount) external;

    /**
     * @dev Increment the total sell-amount.
     * @param _amount The amount to increment by.
     */
    function incTotalSell(uint256 _amount) external;
}

// File: contracts/sogur/interfaces/IETHConverter.sol

/**
 * @title ETH Converter Interface.
 */
interface IETHConverter {
    /**
     * @dev Get the current SDR worth of a given ETH amount.
     * @param _ethAmount The amount of ETH to convert.
     * @return The equivalent amount of SDR.
     */
    function toSdrAmount(uint256 _ethAmount) external view returns (uint256);

    /**
     * @dev Get the current ETH worth of a given SDR amount.
     * @param _sdrAmount The amount of SDR to convert.
     * @return The equivalent amount of ETH.
     */
    function toEthAmount(uint256 _sdrAmount) external view returns (uint256);

    /**
     * @dev Get the original SDR worth of a converted ETH amount.
     * @param _ethAmount The amount of ETH converted.
     * @return The original amount of SDR.
     */
    function fromEthAmount(uint256 _ethAmount) external view returns (uint256);
}

// File: contracts/contract_address_locator/interfaces/IContractAddressLocator.sol

/**
 * @title Contract Address Locator Interface.
 */
interface IContractAddressLocator {
    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) external view returns (address);

    /**
     * @dev Determine whether or not a contract address relates to one of the identifiers.
     * @param _contractAddress The contract address to look for.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the contract address relates to one of the identifiers.
     */
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

// File: contracts/contract_address_locator/ContractAddressLocatorHolder.sol

/**
 * @title Contract Address Locator Holder.
 * @dev Hold a contract address locator, which maps a unique identifier to every contract address in the system.
 * @dev Any contract which inherits from this contract can retrieve the address of any contract in the system.
 * @dev Thus, any contract can remain "oblivious" to the replacement of any other contract in the system.
 * @dev In addition to that, any function in any contract can be restricted to a specific caller.
 */
contract ContractAddressLocatorHolder {
    bytes32 internal constant _IAuthorizationDataSource_ = "IAuthorizationDataSource";
    bytes32 internal constant _ISGNConversionManager_    = "ISGNConversionManager"      ;
    bytes32 internal constant _IModelDataSource_         = "IModelDataSource"        ;
    bytes32 internal constant _IPaymentHandler_          = "IPaymentHandler"            ;
    bytes32 internal constant _IPaymentManager_          = "IPaymentManager"            ;
    bytes32 internal constant _IPaymentQueue_            = "IPaymentQueue"              ;
    bytes32 internal constant _IReconciliationAdjuster_  = "IReconciliationAdjuster"      ;
    bytes32 internal constant _IIntervalIterator_        = "IIntervalIterator"       ;
    bytes32 internal constant _IMintHandler_             = "IMintHandler"            ;
    bytes32 internal constant _IMintListener_            = "IMintListener"           ;
    bytes32 internal constant _IMintManager_             = "IMintManager"            ;
    bytes32 internal constant _IPriceBandCalculator_     = "IPriceBandCalculator"       ;
    bytes32 internal constant _IModelCalculator_         = "IModelCalculator"        ;
    bytes32 internal constant _IRedButton_               = "IRedButton"              ;
    bytes32 internal constant _IReserveManager_          = "IReserveManager"         ;
    bytes32 internal constant _ISagaExchanger_           = "ISagaExchanger"          ;
    bytes32 internal constant _ISogurExchanger_           = "ISogurExchanger"          ;
    bytes32 internal constant _SgnToSgrExchangeInitiator_ = "SgnToSgrExchangeInitiator"          ;
    bytes32 internal constant _IMonetaryModel_               = "IMonetaryModel"              ;
    bytes32 internal constant _IMonetaryModelState_          = "IMonetaryModelState"         ;
    bytes32 internal constant _ISGRAuthorizationManager_ = "ISGRAuthorizationManager";
    bytes32 internal constant _ISGRToken_                = "ISGRToken"               ;
    bytes32 internal constant _ISGRTokenManager_         = "ISGRTokenManager"        ;
    bytes32 internal constant _ISGRTokenInfo_         = "ISGRTokenInfo"        ;
    bytes32 internal constant _ISGNAuthorizationManager_ = "ISGNAuthorizationManager";
    bytes32 internal constant _ISGNToken_                = "ISGNToken"               ;
    bytes32 internal constant _ISGNTokenManager_         = "ISGNTokenManager"        ;
    bytes32 internal constant _IMintingPointTimersManager_             = "IMintingPointTimersManager"            ;
    bytes32 internal constant _ITradingClasses_          = "ITradingClasses"         ;
    bytes32 internal constant _IWalletsTradingLimiterValueConverter_        = "IWalletsTLValueConverter"       ;
    bytes32 internal constant _BuyWalletsTradingDataSource_       = "BuyWalletsTradingDataSource"      ;
    bytes32 internal constant _SellWalletsTradingDataSource_       = "SellWalletsTradingDataSource"      ;
    bytes32 internal constant _WalletsTradingLimiter_SGNTokenManager_          = "WalletsTLSGNTokenManager"         ;
    bytes32 internal constant _BuyWalletsTradingLimiter_SGRTokenManager_          = "BuyWalletsTLSGRTokenManager"         ;
    bytes32 internal constant _SellWalletsTradingLimiter_SGRTokenManager_          = "SellWalletsTLSGRTokenManager"         ;
    bytes32 internal constant _IETHConverter_             = "IETHConverter"   ;
    bytes32 internal constant _ITransactionLimiter_      = "ITransactionLimiter"     ;
    bytes32 internal constant _ITransactionManager_      = "ITransactionManager"     ;
    bytes32 internal constant _IRateApprover_      = "IRateApprover"     ;
    bytes32 internal constant _SGAToSGRInitializer_      = "SGAToSGRInitializer"     ;

    IContractAddressLocator private contractAddressLocator;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) internal {
        require(_contractAddressLocator != address(0), "locator is illegal");
        contractAddressLocator = _contractAddressLocator;
    }

    /**
     * @dev Get the contract address locator.
     * @return The contract address locator.
     */
    function getContractAddressLocator() external view returns (IContractAddressLocator) {
        return contractAddressLocator;
    }

    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) internal view returns (address) {
        return contractAddressLocator.getContractAddress(_identifier);
    }



    /**
     * @dev Determine whether or not the sender relates to one of the identifiers.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the sender relates to one of the identifiers.
     */
    function isSenderAddressRelates(bytes32[] _identifiers) internal view returns (bool) {
        return contractAddressLocator.isContractAddressRelates(msg.sender, _identifiers);
    }

    /**
     * @dev Verify that the caller is mapped to a given identifier.
     * @param _identifier The identifier.
     */
    modifier only(bytes32 _identifier) {
        require(msg.sender == getContractAddress(_identifier), "caller is illegal");
        _;
    }

}

// File: contracts/sogur/TransactionManager.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Transaction Manager.
 */
contract TransactionManager is ITransactionManager, ContractAddressLocatorHolder {
    string public constant VERSION = "1.0.1";

    event TransactionManagerBuyCompleted(uint256 _amount);
    event TransactionManagerSellCompleted(uint256 _amount);

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

    /**
     * @dev Return the contract which implements the IMonetaryModel interface.
     */
    function getMonetaryModel() public view returns (IMonetaryModel) {
        return IMonetaryModel(getContractAddress(_IMonetaryModel_));
    }

    /**
     * @dev Return the contract which implements the IReconciliationAdjuster interface.
     */
    function getReconciliationAdjuster() public view returns (IReconciliationAdjuster) {
        return IReconciliationAdjuster(getContractAddress(_IReconciliationAdjuster_));
    }

    /**
     * @dev Return the contract which implements the ITransactionLimiter interface.
     */
    function getTransactionLimiter() public view returns (ITransactionLimiter) {
        return ITransactionLimiter(getContractAddress(_ITransactionLimiter_));
    }

    /**
     * @dev Return the contract which implements the IETHConverter interface.
     */
    function getETHConverter() public view returns (IETHConverter) {
        return IETHConverter(getContractAddress(_IETHConverter_));
    }

    /**
     * @dev Buy SGR in exchange for ETH.
     * @param _ethAmount The amount of ETH received from the buyer.
     * @return The amount of SGR that the buyer is entitled to receive.
     */
    function buy(uint256 _ethAmount) external only(_ISGRTokenManager_) returns (uint256) {
        uint256 sdrAmount = getETHConverter().toSdrAmount(_ethAmount);
        uint256 newAmount = getReconciliationAdjuster().adjustBuy(sdrAmount);
        uint256 sgrAmount = getMonetaryModel().buy(newAmount);
        getTransactionLimiter().incTotalBuy(sdrAmount);
        emit TransactionManagerBuyCompleted(sdrAmount);
        return sgrAmount;
    }

    /**
     * @dev Sell SGR in exchange for ETH.
     * @param _sgrAmount The amount of SGR received from the seller.
     * @return The amount of ETH that the seller is entitled to receive.
     */
    function sell(uint256 _sgrAmount) external only(_ISGRTokenManager_) returns (uint256) {
        uint256 sdrAmount = getMonetaryModel().sell(_sgrAmount);
        uint256 newAmount = getReconciliationAdjuster().adjustSell(sdrAmount);
        uint256 ethAmount = getETHConverter().toEthAmount(newAmount);
        getTransactionLimiter().incTotalSell(sdrAmount);
        emit TransactionManagerSellCompleted(newAmount);
        return ethAmount;
    }
}