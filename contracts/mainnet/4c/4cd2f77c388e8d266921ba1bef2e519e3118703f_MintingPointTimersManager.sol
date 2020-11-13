pragma solidity 0.4.25;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/sogur/MintingPointTimersManager.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Minting Point Timers Manager.
 */
contract MintingPointTimersManager is IMintingPointTimersManager, ContractAddressLocatorHolder {
    string public constant VERSION = "1.0.1";

    using SafeMath for uint256;

    struct Timestamp {
        bool valid;
        uint256 value;
    }

    uint256 public timeout;
    Timestamp[95] public timestamps;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     * @param _timeout The number of seconds elapsed between 'running' and 'expired'.
     * @notice Each timestamp can be in either one of 3 states: 'running', 'expired' or 'invalid'.
     */
    constructor(IContractAddressLocator _contractAddressLocator, uint256 _timeout) ContractAddressLocatorHolder(_contractAddressLocator) public {
        timeout = _timeout;
    }

    /**
     * @dev Start a given timestamp.
     * @param _id The ID of the timestamp.
     * @notice When tested, this timestamp will be either 'running' or 'expired'.
     */
    function start(uint256 _id) external only(_IIntervalIterator_) {
        Timestamp storage timestamp = timestamps[_id];
        assert(!timestamp.valid);
        timestamp.valid = true;
        timestamp.value = time();
    }

    /**
     * @dev Reset a given timestamp.
     * @param _id The ID of the timestamp.
     * @notice When tested, this timestamp will be neither 'running' nor 'expired'.
     */
    function reset(uint256 _id) external only(_IIntervalIterator_) {
        Timestamp storage timestamp = timestamps[_id];
        assert(timestamp.valid);
        timestamp.valid = false;
        timestamp.value = 0;
    }

    /**
     * @dev Get an indication of whether or not a given timestamp is 'running'.
     * @param _id The ID of the timestamp.
     * @return An indication of whether or not a given timestamp is 'running'.
     * @notice Even if this timestamp is not 'running', it is not necessarily 'expired'.
     */
    function running(uint256 _id) external view returns (bool) {
        Timestamp storage timestamp = timestamps[_id];
        if (!timestamp.valid)
            return false;
        return timestamp.value.add(timeout) >= time();
    }

    /**
     * @dev Get an indication of whether or not a given timestamp is 'expired'.
     * @param _id The ID of the timestamp.
     * @return An indication of whether or not a given timestamp is 'expired'.
     * @notice Even if this timestamp is not 'expired', it is not necessarily 'running'.
     */
    function expired(uint256 _id) external view returns (bool) {
        Timestamp storage timestamp = timestamps[_id];
        if (!timestamp.valid)
            return false;
        return timestamp.value.add(timeout) < time();
    }

    /**
     * @dev Return the current time (equivalent to `block.timestamp`).
     * @notice This function can be overridden in order to perform artificial time-simulation.
     */
    function time() internal view returns (uint256) {
        return now;
    }
}