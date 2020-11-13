pragma solidity ^0.5.10;

/// @title      ISPVConsumer
/// @author     Summa (https://summa.one)
/// @notice     This interface consumes validated transaction information.
///             It is the primary way that user contracts accept
/// @dev        Implement this interface to process transactions provided by
///             the Relay system.
interface ISPVConsumer {
    /// @notice     A consumer for Bitcoin transaction information.
    /// @dev        Users must implement this function. It handles Bitcoin
    ///             events that have been validated by the Relay contract.
    ///             It is VERY IMPORTANT that this function validates the
    ///             msg.sender. The callee must check the origin of the data
    ///             or risk accepting spurious information.
    /// @param _txid        The LE(!) txid of the bitcoin transaction that
    ///                     triggered the notification.
    /// @param _vin         The length-prefixed input vector of the bitcoin tx
    ///                     that triggered the notification.
    /// @param _vout        The length-prefixed output vector of the bitcoin tx
    ///                     that triggered the notification.
    /// @param _requestID   The ID of the event request that this notification
    ///                     satisfies. The ID is returned by
    ///                     OnDemandSPV.request and should be locally stored by
    ///                     any contract that makes more than one request.
    /// @param _inputIndex  The index of the input in the _vin that triggered
    ///                     the notification.
    /// @param _outputIndex The index of the output in the _vout that triggered
    ///                     the notification. Useful for subscribing to transactions
    ///                     that spend the newly-created UTXO.
    function spv(
        bytes32 _txid,
        bytes calldata _vin,
        bytes calldata _vout,
        uint256 _requestID,
        uint8 _inputIndex,
        uint8 _outputIndex) external;
}

/// @title      ISPVRequestManager
/// @author     Summa (https://summa.one)
/// @notice     The interface for using the OnDemandSPV system. This interface
///             allows you to subscribe to Bitcoin events.
/// @dev        Manage subscriptions to Bitcoin events. Register callbacks to
///             be called whenever specific Bitcoin transactions are made.
interface ISPVRequestManager {
    event NewProofRequest (
        address indexed _requester,
        uint256 indexed _requestID,
        uint64 _paysValue,
        bytes _spends,
        bytes _pays
    );

    event RequestClosed(uint256 indexed _requestID);
    event RequestFilled(bytes32 indexed _txid, uint256 indexed _requestID);

    /// @notice             Subscribe to a feed of Bitcoin transactions matching a request
    /// @dev                The request can be a spent utxo and/or a created utxo.
    ///
    ///                     The contract allows users to register a "consumer" contract
    ///                     that implements ISPVConsumer to handle Bitcoin events.
    ///
    ///                     Bitcoin transactions are composed of a vector of inputs,
    ///                     and a vector of outputs. The `_spends` parameter allows consumers
    ///                     to watch a specific UTXO, and receive an event when it is spent.
    ///
    ///                     The `_pays` and `_paysValue` param allow the user to watch specific
    ///                     Bitcoin output scripts. An output script is typically encoded
    ///                     as an address, but an address is not an in-protocol construction.
    ///                     In other words, consumers will receive an event whenever a specific
    ///                     address receives funds, or when a specific OP_RETURN is created.
    ///
    ///                     Either `_spends` or `_pays` MUST be set. Both MAY be set.
    ///                     If both are set, only notifications meeting both criteria
    ///                     will be triggered.
    ///
    /// @param  _spends     An outpoint that must be spent in acceptable transactions.
    ///                     The outpoint must be exactly 36 bytes, and composed of a
    ///                     LE txid (32 bytes), and an 4-byte LE-encoded index integer.
    ///                     In other words, the precise serialization format used in a
    ///                     serialized Bitcoin TxIn.
    ///
    ///                     Note that while we might expect a `_spends` event to fire at most
    ///                     one time, that expectation becomes invalid in long Bitcoin reorgs
    ///                     if there is a double-spend or a disconfirmation followed by
    ///                     reconfirmation.
    ///
    /// @param  _pays       An output script to watch for events. A filter with `_pays` set will
    ///                     validate any number of events that create new UTXOs with a specific
    ///                     output script.
    ///
    ///                     This is useful for watching an address and responding to incoming
    ///                     payments.
    ///
    /// @param  _paysValue  A minimum value in satoshi that must be paid to the output script.
    ///                     If this is set no any non-0 number, the Relay will only forward
    ///                     `_pays` notifications to the consumer if the value of the new UTXO is
    ///                     at least `_paysValue`.
    ///
    /// @param  _consumer   The address of a contract that implements the `ISPVConsumer` interface.
    ///                     Whenever events are available, the Relay will validate inclusion
    ///                     and confirmation, then call the `spv` function on the consumer.
    ///
    /// @param  _numConfs   The number of headers that must confirm the block
    ///                     containing the transaction. Used as a security parameter.
    ///                     More confirmations means less likely to revert due to a
    ///                     chain reorganization. Note that 1 confirmation is required,
    ///                     so the general "6 confirmation" rule would be expressed
    ///                     as `5` when calling this function
    ///
    /// @param  _notBefore  An Ethereum timestamp before which proofs will not be accepted.
    ///                     Used to control app flow for specific users.
    ///
    /// @return             A unique request ID.
    function request(
        bytes calldata _spends,
        bytes calldata _pays,
        uint64 _paysValue,
        address _consumer,
        uint8 _numConfs,
        uint256 _notBefore
    ) external returns (uint256);

    /// @notice                 Cancel an active bitcoin event request.
    /// @dev                    Prevents the relay from forwarding tx information
    /// @param  _requestID      The ID of the request to be cancelled
    /// @return                 True if succesful, error otherwise
    function cancelRequest(uint256 _requestID) external returns (bool);

    /// @notice             Retrieve info about a request
    /// @dev                Requests ids are numerical
    /// @param  _requestID  The numerical ID of the request
    /// @return             A tuple representation of the request struct.
    ///                     To save space`spends` and `pays` are stored as keccak256
    ///                     hashes of the original information. The `state` is
    ///                     `0` for "does not exist", `1` for "active" and `2` for
    ///                     "cancelled."
    function getRequest(
        uint256 _requestID
    ) external view returns (
        bytes32 spends,
        bytes32 pays,
        uint64 paysValue,
        uint8 state,
        address consumer,
        address owner,
        uint8 numConfs,
        uint256 notBefore
    );
}



interface IRelay {
    event Extension(bytes32 indexed _first, bytes32 indexed _last);
    event NewTip(bytes32 indexed _from, bytes32 indexed _to, bytes32 indexed _gcd);

    function getCurrentEpochDifficulty() external view returns (uint256);
    function getPrevEpochDifficulty() external view returns (uint256);
    function getRelayGenesis() external view returns (bytes32);
    function getBestKnownDigest() external view returns (bytes32);
    function getLastReorgCommonAncestor() external view returns (bytes32);

    function findHeight(bytes32 _digest) external view returns (uint256);

    function findAncestor(bytes32 _digest, uint256 _offset) external view returns (bytes32);

    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);

    function markNewHeaviest(
        bytes32 _ancestor,
        bytes calldata _currentBest,
        bytes calldata _newBest,
        uint256 _limit
    ) external returns (bool);
}
