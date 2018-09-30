pragma solidity ^0.4.24;

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

/// @notice The BrokerVerifier interface defines the functions that a settlement
/// layer&#39;s broker verifier contract must implement.
interface BrokerVerifier {

    /// @notice The function signature that will be called when a trader opens
    /// an order.
    ///
    /// @param _trader The trader requesting the withdrawal.
    /// @param _signature The 65-byte signature from the broker.
    /// @param _orderID The 32-byte order ID.
    function verifyOpenSignature(
        address _trader,
        bytes _signature,
        bytes32 _orderID
    ) external returns (bool);
}

/// @notice The Settlement interface defines the functions that a settlement
/// layer must implement.
/// Docs: https://github.com/republicprotocol/republic-sol/blob/nightly/docs/05-settlement.md
interface Settlement {
    function submitOrder(
        bytes _details,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external;

    function submissionGasPriceLimit() external view returns (uint256);

    function settle(
        bytes32 _buyID,
        bytes32 _sellID
    ) external;

    /// @notice orderStatus should return the status of the order, which should
    /// be:
    ///     0  - Order not seen before
    ///     1  - Order details submitted
    ///     >1 - Order settled, or settlement no longer possible
    function orderStatus(bytes32 _orderID) external view returns (uint8);
}

/// @notice SettlementRegistry allows a Settlement layer to register the
/// contracts used for match settlement and for broker signature verification.
contract SettlementRegistry is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    struct SettlementDetails {
        bool registered;
        Settlement settlementContract;
        BrokerVerifier brokerVerifierContract;
    }

    // Settlement IDs are 64-bit unsigned numbers
    mapping(uint64 => SettlementDetails) public settlementDetails;

    // Events
    event LogSettlementRegistered(uint64 settlementID, Settlement settlementContract, BrokerVerifier brokerVerifierContract);
    event LogSettlementUpdated(uint64 settlementID, Settlement settlementContract, BrokerVerifier brokerVerifierContract);
    event LogSettlementDeregistered(uint64 settlementID);

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    constructor(string _VERSION) public {
        VERSION = _VERSION;
    }

    /// @notice Returns the settlement contract of a settlement layer.
    function settlementRegistration(uint64 _settlementID) external view returns (bool) {
        return settlementDetails[_settlementID].registered;
    }

    /// @notice Returns the settlement contract of a settlement layer.
    function settlementContract(uint64 _settlementID) external view returns (Settlement) {
        return settlementDetails[_settlementID].settlementContract;
    }

    /// @notice Returns the broker verifier contract of a settlement layer.
    function brokerVerifierContract(uint64 _settlementID) external view returns (BrokerVerifier) {
        return settlementDetails[_settlementID].brokerVerifierContract;
    }

    /// @param _settlementID A unique 64-bit settlement identifier.
    /// @param _settlementContract The address to use for settling matches.
    /// @param _brokerVerifierContract The decimals to use for verifying
    ///        broker signatures.
    function registerSettlement(uint64 _settlementID, Settlement _settlementContract, BrokerVerifier _brokerVerifierContract) public onlyOwner {
        bool alreadyRegistered = settlementDetails[_settlementID].registered;
        
        settlementDetails[_settlementID] = SettlementDetails({
            registered: true,
            settlementContract: _settlementContract,
            brokerVerifierContract: _brokerVerifierContract
        });

        if (alreadyRegistered) {
            emit LogSettlementUpdated(_settlementID, _settlementContract, _brokerVerifierContract);
        } else {
            emit LogSettlementRegistered(_settlementID, _settlementContract, _brokerVerifierContract);
        }
    }

    /// @notice Deregisteres a settlement layer, clearing the details.
    /// @param _settlementID The unique 64-bit settlement identifier.
    function deregisterSettlement(uint64 _settlementID) external onlyOwner {
        require(settlementDetails[_settlementID].registered, "not registered");

        delete settlementDetails[_settlementID];

        emit LogSettlementDeregistered(_settlementID);
    }
}