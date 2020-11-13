pragma solidity 0.4.25;

// File: contracts/sogur/interfaces/IPaymentQueue.sol

/**
 * @title Payment Queue Interface.
 */
interface IPaymentQueue {
    /**
     * @dev Retrieve the current number of payments.
     * @return The current number of payments.
     */
    function getNumOfPayments() external view returns (uint256);

    /**
     * @dev Retrieve the sum of all payments.
     * @return The sum of all payments.
     */
    function getPaymentsSum() external view returns (uint256);

    /**
     * @dev Retrieve the details of a payment.
     * @param _index The index of the payment.
     * @return The payment wallet address and amount.
     */
    function getPayment(uint256 _index) external view returns (address, uint256);

    /**
     * @dev Add a new payment.
     * @param _wallet The payment wallet address.
     * @param _amount The payment amount.
     */
    function addPayment(address _wallet, uint256 _amount) external;

    /**
     * @dev Update the first payment.
     * @param _amount The new payment amount.
     */
    function updatePayment(uint256 _amount) external;

    /**
     * @dev Remove the first payment.
     */
    function removePayment() external;
}

// File: contracts/sogur/interfaces/ISGRAuthorizationManager.sol

/**
 * @title SGR Authorization Manager Interface.
 */
interface ISGRAuthorizationManager {
    /**
     * @dev Determine whether or not a user is authorized to buy SGR.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedToBuy(address _sender) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to sell SGR.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedToSell(address _sender) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to transfer SGR to another user.
     * @param _sender The address of the source user.
     * @param _target The address of the target user.
     * @return Authorization status.
     */
    function isAuthorizedToTransfer(address _sender, address _target) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to transfer SGR from one user to another user.
     * @param _sender The address of the custodian user.
     * @param _source The address of the source user.
     * @param _target The address of the target user.
     * @return Authorization status.
     */
    function isAuthorizedToTransferFrom(address _sender, address _source, address _target) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized for public operation.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedForPublicOperation(address _sender) external view returns (bool);
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

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  /**
  * @dev Returns the largest of two numbers.
  */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
  * @dev Calculates the average of two numbers. Since these are integers,
  * averages of an even and odd number cannot be represented, and will be
  * rounded down.
  */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

// File: contracts/sogur/PaymentQueue.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Payment Queue.
 */
contract PaymentQueue is IPaymentQueue, ContractAddressLocatorHolder {
    string public constant VERSION = "2.0.0";

    using SafeMath for uint256;

    struct Payment {
        address wallet;
        uint256 amount;
    }

    Payment[] public payments;
    uint256 public first;
    uint256 public last;

    uint256 public sum = 0;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

    /**
     * @dev Return the contract which implements the ISGRAuthorizationManager interface.
     */
    function getSGRAuthorizationManager() public view returns (ISGRAuthorizationManager) {
        return ISGRAuthorizationManager(getContractAddress(_ISGRAuthorizationManager_));
    }

    /**
     * @dev assert if called when the queue is empty.
     */
    modifier assertNonEmpty() {
        assert(last > 0);
        _;
    }

    /**
     * @dev Retrieve the current number of payments.
     * @return The current number of payments.
     */
    function getNumOfPayments() external view returns (uint256) {
        return last.sub(first);
    }

    /**
     * @dev Retrieve the sum of all payments.
     * @return The sum of all payments.
     */
    function getPaymentsSum() external view returns (uint256) {
        return sum;
    }

    /**
     * @dev Retrieve the details of a payment.
     * @param _index The index of the payment.
     * @return The payment's wallet address and amount.
     */
    function getPayment(uint256 _index) external view assertNonEmpty returns (address, uint256)  {
        require(last.sub(first) > _index, "index out of range");
        Payment memory payment = payments[first.add(_index)];
        return (payment.wallet, payment.amount);
    }

    /**
     * @dev Add a new payment.
     * @param _wallet The payment wallet address.
     * @param _amount The payment amount.
     */
    function addPayment(address _wallet, uint256 _amount) external only(_IPaymentManager_) {
        assert(_wallet != address(0) && _amount > 0);
        Payment memory newPayment = Payment({wallet : _wallet, amount : _amount});
        if (payments.length > last)
            payments[last] = newPayment;
        else
            payments.push(newPayment);
        sum = sum.add(_amount);
        last = last.add(1);
    }

    /**
     * @dev Update the first payment.
     * @param _amount The new payment amount.
     */
    function updatePayment(uint256 _amount) external only(_IPaymentManager_) assertNonEmpty {
        assert(_amount > 0);
        sum = (sum.add(_amount)).sub(payments[first].amount);
        payments[first].amount = _amount;

    }

    /**
     * @dev Remove the first payment.
     */
    function removePayment() external only(_IPaymentManager_) assertNonEmpty {
        sum = sum.sub(payments[first].amount);
        payments[first] = Payment({wallet : address(0), amount : 0});
        uint256 newFirstPosition = first.add(1);
        if (newFirstPosition == last)
            first = last = 0;
        else
            first = newFirstPosition;
    }

    /**
     * @dev Clean the queue.
     * @param _maxCleanLength The maximum payments to clean.
     */
    function clean(uint256 _maxCleanLength) external {
        require(getSGRAuthorizationManager().isAuthorizedForPublicOperation(msg.sender), "clean queue is not authorized");
        uint256 paymentsQueueLength = payments.length;
        if (paymentsQueueLength > last) {
            uint256 totalPaymentsToClean = paymentsQueueLength.sub(last);
            payments.length = (totalPaymentsToClean < _maxCleanLength) ? last : paymentsQueueLength.sub(_maxCleanLength);
        }
        
    }
}