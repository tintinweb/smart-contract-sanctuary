pragma solidity 0.4.25;

// File: contracts/sogur/interfaces/IModelDataSource.sol

/**
 * @title Model Data Source Interface.
 */
interface IModelDataSource {
    /**
     * @dev Get interval parameters.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @return Interval minimum amount of SGR.
     * @return Interval maximum amount of SGR.
     * @return Interval minimum amount of SDR.
     * @return Interval maximum amount of SDR.
     * @return Interval alpha value (scaled up).
     * @return Interval beta  value (scaled up).
     */
    function getInterval(uint256 _rowNum, uint256 _colNum) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Get interval alpha and beta.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @return Interval alpha value (scaled up).
     * @return Interval beta  value (scaled up).
     */
    function getIntervalCoefs(uint256 _rowNum, uint256 _colNum) external view returns (uint256, uint256);

    /**
     * @dev Get the amount of SGR required for moving to the next minting-point.
     * @param _rowNum Interval row index.
     * @return Required amount of SGR.
     */
    function getRequiredMintAmount(uint256 _rowNum) external view returns (uint256);
}

// File: contracts/sogur/interfaces/IMintingPointTimersManager.sol

/**
 * @title Minting Point Timers Manager Interface.
 */
interface IMintingPointTimersManager {
    /**
     * @dev Start a given timestamp.
     * @param _id The ID of the timestamp.
     * @notice When tested, this timestamp will be either 'running' or 'expired'.
     */
    function start(uint256 _id) external;

    /**
     * @dev Reset a given timestamp.
     * @param _id The ID of the timestamp.
     * @notice When tested, this timestamp will be neither 'running' nor 'expired'.
     */
    function reset(uint256 _id) external;

    /**
     * @dev Get an indication of whether or not a given timestamp is 'running'.
     * @param _id The ID of the timestamp.
     * @return An indication of whether or not a given timestamp is 'running'.
     * @notice Even if this timestamp is not 'running', it is not necessarily 'expired'.
     */
    function running(uint256 _id) external view returns (bool);

    /**
     * @dev Get an indication of whether or not a given timestamp is 'expired'.
     * @param _id The ID of the timestamp.
     * @return An indication of whether or not a given timestamp is 'expired'.
     * @notice Even if this timestamp is not 'expired', it is not necessarily 'running'.
     */
    function expired(uint256 _id) external view returns (bool);
}

// File: contracts/sogur/interfaces/IIntervalIterator.sol

/**
 * @title Interval Iterator Interface.
 */
interface IIntervalIterator {
    /**
     * @dev Move to a higher interval and start a corresponding timer if necessary.
     */
    function grow() external;

    /**
     * @dev Reset the timer of the current interval if necessary and move to a lower interval.
     */
    function shrink() external;

    /**
     * @dev Return the current interval.
     */
    function getCurrentInterval() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Return the current interval coefficients.
     */
    function getCurrentIntervalCoefs() external view returns (uint256, uint256);
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

// File: contracts/sogur/IntervalIterator.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Interval Iterator.
 */
contract IntervalIterator is IIntervalIterator, ContractAddressLocatorHolder {
    string public constant VERSION = "1.0.1";

    uint256 public constant MAX_GROW_ROW = 94;

    uint256 public row;
    uint256 public col;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

    /**
     * @dev Return the contract which implements the IModelDataSource interface.
     */
    function getModelDataSource() public view returns (IModelDataSource) {
        return IModelDataSource(getContractAddress(_IModelDataSource_));
    }

    /**
     * @dev Return the contract which implements the IMintingPointTimersManager interface.
     */
    function getMintingPointTimersManager() public view returns (IMintingPointTimersManager) {
        return IMintingPointTimersManager(getContractAddress(_IMintingPointTimersManager_));
    }

    /**
     * @dev Move to a higher interval and start a corresponding timer if necessary.
     */
    function grow() external only(_IMonetaryModel_) {
        if (col == 0) {
            row += 1;
            require(row <= MAX_GROW_ROW, "reached end of last interval");
            getMintingPointTimersManager().start(row);
        }
        else {
            col -= 1;
        }
    }

    /**
     * @dev Reset the timer of the current interval if necessary and move to a lower interval.
     */
    function shrink() external only(_IMonetaryModel_) {
        IMintingPointTimersManager mintingPointTimersManager = getMintingPointTimersManager();
        if (mintingPointTimersManager.running(row)) {
            mintingPointTimersManager.reset(row);
            assert(row > 0);
            row -= 1;
        }
        else {
            col += 1;
        }
    }

    /**
     * @dev Return the current interval.
     */
    function getCurrentInterval() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return getModelDataSource().getInterval(row, col);
    }

    /**
     * @dev Return the current interval coefficients.
     */
    function getCurrentIntervalCoefs() external view returns (uint256, uint256) {
        return getModelDataSource().getIntervalCoefs(row, col);
    }
}