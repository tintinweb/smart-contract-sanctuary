pragma solidity 0.4.25;

// File: contracts/saga-genesis/interfaces/IMintManager.sol

/**
 * @title Mint Manager Interface.
 */
interface IMintManager {
    /**
     * @dev Return the current minting-point index.
     */
    function getIndex() external view returns (uint256);
}

// File: contracts/saga-genesis/interfaces/ISGNTokenManager.sol

/**
 * @title SGN Token Manager Interface.
 */
interface ISGNTokenManager {
    /**
     * @dev Get the current SGR worth of a given SGN amount.
     * @param _sgnAmount The amount of SGN to convert.
     * @return The equivalent amount of SGR.
     */
    function convertSgnToSga(uint256 _sgnAmount) external view returns (uint256);

    /**
     * @dev Exchange SGN for SGR.
     * @param _sender The address of the sender.
     * @param _sgnAmount The amount of SGN received.
     * @return The amount of SGR that the sender is entitled to.
     */
    function exchangeSgnForSga(address _sender, uint256 _sgnAmount) external returns (uint256);

    /**
     * @dev Handle direct SGN transfer.
     * @param _sender The address of the sender.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransfer(address _sender, address _to, uint256 _value) external;

    /**
     * @dev Handle custodian SGN transfer.
     * @param _sender The address of the sender.
     * @param _from The address of the source account.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransferFrom(address _sender, address _from, address _to, uint256 _value) external;

    /** 
     * @dev Upon minting of SGN vested in delay.
     * @param _value The amount of SGN to mint.
     */
    function uponMintSgnVestedInDelay(uint256 _value) external;
}

// File: contracts/saga-genesis/interfaces/ISGNConversionManager.sol

/**
 * @title SGN Conversion Manager Interface.
 */
interface ISGNConversionManager {
    /**
     * @dev Compute the SGR worth of a given SGN amount at a given minting-point.
     * @param _amount The amount of SGN.
     * @param _index The minting-point index.
     * @return The equivalent amount of SGR.
     */
    function sgn2sgr(uint256 _amount, uint256 _index) external view returns (uint256);
}

// File: contracts/saga-genesis/interfaces/ISGNAuthorizationManager.sol

/**
 * @title SGN Authorization Manager Interface.
 */
interface ISGNAuthorizationManager {
    /**
     * @dev Determine whether or not a user is authorized to sell SGN.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedToSell(address _sender) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to transfer SGN to another user.
     * @param _sender The address of the source user.
     * @param _target The address of the target user.
     * @return Authorization status.
     */
    function isAuthorizedToTransfer(address _sender, address _target) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to transfer SGN from one user to another user.
     * @param _sender The address of the custodian user.
     * @param _source The address of the source user.
     * @param _target The address of the target user.
     * @return Authorization status.
     */
    function isAuthorizedToTransferFrom(address _sender, address _source, address _target) external view returns (bool);
}

// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingLimiter.sol

/**
 * @title Wallets Trading Limiter Interface.
 */
interface IWalletsTradingLimiter {
    /**
     * @dev Increment the limiter value of a wallet.
     * @param _wallet The address of the wallet.
     * @param _value The amount to be updated.
     */
    function updateWallet(address _wallet, uint256 _value) external;
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

// File: contracts/saga-genesis/SGNTokenManager.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title SGN Token Manager.
 */
contract SGNTokenManager is ISGNTokenManager, ContractAddressLocatorHolder {
    string public constant VERSION = "1.0.1";

    event ExchangeSgnForSgrCompleted(address indexed _user, uint256 _input, uint256 _output);
    event MintSgnVestedInDelayCompleted(uint256 _value);

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

    /**
     * @dev Return the contract which implements the ISGNAuthorizationManager interface.
     */
    function getSGNAuthorizationManager() public view returns (ISGNAuthorizationManager) {
        return ISGNAuthorizationManager(getContractAddress(_ISGNAuthorizationManager_));
    }

    /**
     * @dev Return the contract which implements the ISGNConversionManager interface.
     */
    function getSGNConversionManager() public view returns (ISGNConversionManager) {
        return ISGNConversionManager(getContractAddress(_ISGNConversionManager_));
    }

    /**
     * @dev Return the contract which implements the IMintManager interface.
     */
    function getMintManager() public view returns (IMintManager) {
        return IMintManager(getContractAddress(_IMintManager_));
    }

    /**
     * @dev Return the contract which implements the IWalletsTradingLimiter interface.
     */
    function getWalletsTradingLimiter() public view returns (IWalletsTradingLimiter) {
        return IWalletsTradingLimiter(getContractAddress(_WalletsTradingLimiter_SGNTokenManager_));
    }

    /**
     * @dev Get the current SGR worth of a given SGN amount.
       function name is convertSgnToSga and not convertSgnToSgr for backward compatibility.
     * @param _sgnAmount The amount of SGN to convert.
     * @return The equivalent amount of SGR.
     */
    function convertSgnToSga(uint256 _sgnAmount) external view returns (uint256) {
        return convertSgnToSgrFunc(_sgnAmount);
    }

    /**
     * @dev Exchange SGN for SGR.
       function name is exchangeSgnForSga and not exchangeSgnForSgr for backward compatibility.
     * @param _sender The address of the sender.
     * @param _sgnAmount The amount of SGN received.
     * @return The amount of SGR that the sender is entitled to.
     */
    function exchangeSgnForSga(address _sender, uint256 _sgnAmount) external only(_ISGNToken_) returns (uint256) {
        require(getSGNAuthorizationManager().isAuthorizedToSell(_sender), "exchanging SGN for SGR is not authorized");
        uint256 sgrAmount = convertSgnToSgrFunc(_sgnAmount);
        require(sgrAmount > 0, "returned amount is zero");
        emit ExchangeSgnForSgrCompleted(_sender, _sgnAmount, sgrAmount);
        return sgrAmount;
    }

    /**
     * @dev Handle direct SGN transfer.
     * @param _sender The address of the sender.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransfer(address _sender, address _to, uint256 _value) external only(_ISGNToken_) {
        require(getSGNAuthorizationManager().isAuthorizedToTransfer(_sender, _to), "direct-transfer of SGN is not authorized");
        getWalletsTradingLimiter().updateWallet(_to, _value);
        _value;
    }

    /**
     * @dev Handle custodian SGN transfer.
     * @param _sender The address of the sender.
     * @param _from The address of the source account.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransferFrom(address _sender, address _from, address _to, uint256 _value) external only(_ISGNToken_) {
        require(getSGNAuthorizationManager().isAuthorizedToTransferFrom(_sender, _from, _to), "custodian-transfer of SGN is not authorized");
        getWalletsTradingLimiter().updateWallet(_to, _value);
        _value;
    }

    /** 
     * @dev Upon minting of SGN vested in delay.
     * @param _value The amount of SGN to mint.
     */
    function uponMintSgnVestedInDelay(uint256 _value) external only(_ISGNToken_) {
        emit MintSgnVestedInDelayCompleted(_value);
    }

    /**
     * @dev  Get the amount of SGR received upon conversion of a given SGN amount.
     * @param _sgnAmount the amount of SGN to convert.
     * @return The amount of SGR received upon conversion .
     */
    function convertSgnToSgrFunc(uint256 _sgnAmount) private view returns (uint256) {
        return getSGNConversionManager().sgn2sgr(_sgnAmount, getMintManager().getIndex());
    }
}