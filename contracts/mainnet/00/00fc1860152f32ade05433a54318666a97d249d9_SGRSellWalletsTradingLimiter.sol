pragma solidity 0.4.25;

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

// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingDataSource.sol

/**
 * @title Wallets Trading Data Source Interface.
 */
interface IWalletsTradingDataSource {
    /**
     * @dev Increment the value of a given wallet.
     * @param _wallet The address of the wallet.
     * @param _value The value to increment by.
     * @param _limit The limit of the wallet.
     */
    function updateWallet(address _wallet, uint256 _value, uint256 _limit) external;
}

// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingLimiterValueConverter.sol

/**
 * @title Wallets Trading Limiter Value Converter Interface.
 */
interface IWalletsTradingLimiterValueConverter {
    /**
     * @dev Get the current limiter currency worth of a given SGR amount.
     * @param _sgrAmount The amount of SGR to convert.
     * @return The equivalent amount of the limiter currency.
     */
    function toLimiterValue(uint256 _sgrAmount) external view returns (uint256);
}

// File: contracts/wallet_trading_limiter/interfaces/ITradingClasses.sol

/**
 * @title Trading Classes Interface.
 */
interface ITradingClasses {
    /**
     * @dev Get the complete info of a class.
     * @param _id The id of the class.
     * @return complete info of a class.
     */
    function getInfo(uint256 _id) external view returns (uint256, uint256, uint256);

    /**
     * @dev Get the action-role of a class.
     * @param _id The id of the class.
     * @return The action-role of the class.
     */
    function getActionRole(uint256 _id) external view returns (uint256);

    /**
     * @dev Get the sell limit of a class.
     * @param _id The id of the class.
     * @return The sell limit of the class.
     */
    function getSellLimit(uint256 _id) external view returns (uint256);

    /**
     * @dev Get the buy limit of a class.
     * @param _id The id of the class.
     * @return The buy limit of the class.
     */
    function getBuyLimit(uint256 _id) external view returns (uint256);
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

// File: contracts/authorization/interfaces/IAuthorizationDataSource.sol

/**
 * @title Authorization Data Source Interface.
 */
interface IAuthorizationDataSource {
    /**
     * @dev Get the authorized action-role of a wallet.
     * @param _wallet The address of the wallet.
     * @return The authorized action-role of the wallet.
     */
    function getAuthorizedActionRole(address _wallet) external view returns (bool, uint256);

    /**
     * @dev Get the authorized action-role and trade-class of a wallet.
     * @param _wallet The address of the wallet.
     * @return The authorized action-role and class of the wallet.
     */
    function getAuthorizedActionRoleAndClass(address _wallet) external view returns (bool, uint256, uint256);

    /**
     * @dev Get all the trade-limits and trade-class of a wallet.
     * @param _wallet The address of the wallet.
     * @return The trade-limits and trade-class of the wallet.
     */
    function getTradeLimitsAndClass(address _wallet) external view returns (uint256, uint256, uint256);


    /**
     * @dev Get the buy trade-limit and trade-class of a wallet.
     * @param _wallet The address of the wallet.
     * @return The buy trade-limit and trade-class of the wallet.
     */
    function getBuyTradeLimitAndClass(address _wallet) external view returns (uint256, uint256);

    /**
     * @dev Get the sell trade-limit and trade-class of a wallet.
     * @param _wallet The address of the wallet.
     * @return The sell trade-limit and trade-class of the wallet.
     */
    function getSellTradeLimitAndClass(address _wallet) external view returns (uint256, uint256);
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/wallet_trading_limiter/WalletsTradingLimiterBase.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Wallets Trading Limiter Base.
 */
contract WalletsTradingLimiterBase is IWalletsTradingLimiter, ContractAddressLocatorHolder, Claimable {
    string public constant VERSION = "1.1.0";

    bytes32 public walletsTradingDataSourceIdentifier;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator, bytes32 _walletsTradingDataSourceIdentifier) ContractAddressLocatorHolder(_contractAddressLocator) public {
        walletsTradingDataSourceIdentifier = _walletsTradingDataSourceIdentifier;
    }

    /**
     * @dev Return the contract which implements the IAuthorizationDataSource interface.
     */
    function getAuthorizationDataSource() public view returns (IAuthorizationDataSource) {
        return IAuthorizationDataSource(getContractAddress(_IAuthorizationDataSource_));
    }

    /**
     * @dev Return the contract which implements the ITradingClasses interface.
     */
    function getTradingClasses() public view returns (ITradingClasses) {
        return ITradingClasses(getContractAddress(_ITradingClasses_));
    }

    /**
     * @dev Return the contract which implements the IWalletsTradingDataSource interface.
     */
    function getWalletsTradingDataSource() public view returns (IWalletsTradingDataSource) {
        return IWalletsTradingDataSource(getContractAddress(walletsTradingDataSourceIdentifier));
    }

    /**
     * @dev Return the contract which implements the IWalletsTradingLimiterValueConverter interface.
     */
    function getWalletsTradingLimiterValueConverter() public view returns (IWalletsTradingLimiterValueConverter) {
        return IWalletsTradingLimiterValueConverter(getContractAddress(_IWalletsTradingLimiterValueConverter_));
    }

    /**
     * @dev Get the contract locator identifier that is permitted to perform update wallet.
     * @return The contract locator identifier.
     */
    function getUpdateWalletPermittedContractLocatorIdentifier() public pure returns (bytes32);

    /**
     * @dev Get the wallet override trade-limit and class.
     * @return The wallet override trade-limit and class.
     */
    function getOverrideTradeLimitAndClass(address _wallet) public view returns (uint256, uint256);

    /**
     * @dev Get the wallet trade-limit.
     * @return The wallet trade-limit.
     */
    function getTradeLimit(uint256 _tradeClassId) public view returns (uint256);

    /**
     * @dev Get the limiter value.
     * @param _value The amount to be converted to the limiter value.
     * @return The limiter value worth of the given amount.
     */
    function getLimiterValue(uint256 _value) public view returns (uint256);


    /**
     * @dev Increment the limiter value of a wallet.
     * @param _wallet The address of the wallet.
     * @param _value The amount to be updated.
     */
    function updateWallet(address _wallet, uint256 _value) external only(getUpdateWalletPermittedContractLocatorIdentifier()) {
        uint256 limiterValue = getLimiterValue(_value);

        (uint256 overrideTradeLimit, uint256 tradeClassId) = getOverrideTradeLimitAndClass(_wallet);

        uint256 tradeLimit = overrideTradeLimit > 0 ? overrideTradeLimit : getTradeLimit(tradeClassId);

        getWalletsTradingDataSource().updateWallet(_wallet, limiterValue, tradeLimit);
    }
}

// File: contracts/sogur/SGRWalletsTradingLimiter.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title SGR Wallets Trading Limiter.
 */
contract SGRWalletsTradingLimiter is WalletsTradingLimiterBase {
    string public constant VERSION = "1.1.0";

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator, bytes32 _walletsTradingDataSourceIdentifier) WalletsTradingLimiterBase(_contractAddressLocator, _walletsTradingDataSourceIdentifier) public {}


    /**
     * @dev Get the contract locator identifier that is permitted to perform update wallet.
     * @return The contract locator identifier.
     */
    function getUpdateWalletPermittedContractLocatorIdentifier() public pure returns (bytes32){
        return _ISGRTokenManager_;
    }

    /**
     * @dev Get the limiter value.
     * @param _value The SGR amount to convert to limiter value.
     * @return The limiter value worth of the given SGR amount.
     */
    function getLimiterValue(uint256 _value) public view returns (uint256){
        return getWalletsTradingLimiterValueConverter().toLimiterValue(_value);
    }
}

// File: contracts/sogur/SGRSellWalletsTradingLimiter.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title SGR sell Wallets Trading Limiter.
 */
contract SGRSellWalletsTradingLimiter is SGRWalletsTradingLimiter {
    string public constant VERSION = "2.0.0";

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) SGRWalletsTradingLimiter(_contractAddressLocator, _SellWalletsTradingDataSource_) public {}


    /**
     * @dev Get the wallet override trade-limit and class.
     * @return The wallet override trade-limit and class.
     */
    function getOverrideTradeLimitAndClass(address _wallet) public view returns (uint256, uint256){
        return getAuthorizationDataSource().getSellTradeLimitAndClass(_wallet);

    }

    /**
     * @dev Get the wallet trade-limit.
     * @return The wallet trade-limit.
     */
    function getTradeLimit(uint256 _tradeClassId) public view returns (uint256){
        return getTradingClasses().getSellLimit(_tradeClassId);
    }
}