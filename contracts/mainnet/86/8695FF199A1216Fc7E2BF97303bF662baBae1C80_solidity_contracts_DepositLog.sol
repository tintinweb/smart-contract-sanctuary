pragma solidity 0.5.17;

import {TBTCDepositToken} from "./system/TBTCDepositToken.sol";


// solium-disable function-order
// Below, a few functions must be public to allow bytes memory parameters, but
// their being so triggers errors because public functions should be grouped
// below external functions. Since these would be external if it were possible,
// we ignore the issue.

contract DepositLog {
    /*
    Logging philosophy:
      Every state transition should fire a log
      That log should have ALL necessary info for off-chain actors
      Everyone should be able to ENTIRELY rely on log messages
    */

    // `TBTCDepositToken` mints a token for every new Deposit.
    // If a token exists for a given ID, we know it is a valid Deposit address.
    TBTCDepositToken tbtcDepositToken;

    // This event is fired when we init the deposit
    event Created(
        address indexed _depositContractAddress,
        address indexed _keepAddress,
        uint256 _timestamp
    );

    // This log event contains all info needed to rebuild the redemption tx
    // We index on request and signers and digest
    event RedemptionRequested(
        address indexed _depositContractAddress,
        address indexed _requester,
        bytes32 indexed _digest,
        uint256 _utxoValue,
        bytes _redeemerOutputScript,
        uint256 _requestedFee,
        bytes _outpoint
    );

    // This log event contains all info needed to build a witnes
    // We index the digest so that we can search events for the other log
    event GotRedemptionSignature(
        address indexed _depositContractAddress,
        bytes32 indexed _digest,
        bytes32 _r,
        bytes32 _s,
        uint256 _timestamp
    );

    // This log is fired when the signing group returns a public key
    event RegisteredPubkey(
        address indexed _depositContractAddress,
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY,
        uint256 _timestamp
    );

    // This event is fired when we enter the FAILED_SETUP state for any reason
    event SetupFailed(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when a funder requests funder abort after
    // FAILED_SETUP has been reached. Funder abort is a voluntary signer action
    // to return UTXO(s) that were sent to a signer-controlled wallet despite
    // the funding proofs having failed.
    event FunderAbortRequested(
        address indexed _depositContractAddress,
        bytes _abortOutputScript
    );

    // This event is fired when we detect an ECDSA fraud before seeing a funding proof
    event FraudDuringSetup(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when we enter the ACTIVE state
    event Funded(
        address indexed _depositContractAddress,
        bytes32 indexed _txid,
        uint256 _timestamp
    );

    // This event is called when we enter the COURTESY_CALL state
    event CourtesyCalled(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when we go from COURTESY_CALL to ACTIVE
    event ExitedCourtesyCall(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This log event is fired when liquidation
    event StartedLiquidation(
        address indexed _depositContractAddress,
        bool _wasFraud,
        uint256 _timestamp
    );

    // This event is fired when the Redemption SPV proof is validated
    event Redeemed(
        address indexed _depositContractAddress,
        bytes32 indexed _txid,
        uint256 _timestamp
    );

    // This event is fired when Liquidation is completed
    event Liquidated(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    //
    // Logging
    //

    /// @notice               Fires a Created event.
    /// @dev                  We append the sender, which is the deposit contract that called.
    /// @param  _keepAddress  The address of the associated keep.
    /// @return               True if successful, else revert.
    function logCreated(address _keepAddress) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Created(msg.sender, _keepAddress, block.timestamp);
    }

    /// @notice                 Fires a RedemptionRequested event.
    /// @dev                    This is the only event without an explicit timestamp.
    /// @param  _requester      The ethereum address of the requester.
    /// @param  _digest         The calculated sighash digest.
    /// @param  _utxoValue       The size of the utxo in sat.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _requestedFee   The requester or bump-system specified fee.
    /// @param  _outpoint       The 36 byte outpoint.
    /// @return                 True if successful, else revert.
    function logRedemptionRequested(
        address _requester,
        bytes32 _digest,
        uint256 _utxoValue,
        bytes memory _redeemerOutputScript,
        uint256 _requestedFee,
        bytes memory _outpoint
    ) public {
        // not external to allow bytes memory parameters
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit RedemptionRequested(
            msg.sender,
            _requester,
            _digest,
            _utxoValue,
            _redeemerOutputScript,
            _requestedFee,
            _outpoint
        );
    }

    /// @notice         Fires a GotRedemptionSignature event.
    /// @dev            We append the sender, which is the deposit contract that called.
    /// @param  _digest signed digest.
    /// @param  _r      signature r value.
    /// @param  _s      signature s value.
    function logGotRedemptionSignature(bytes32 _digest, bytes32 _r, bytes32 _s)
        external
    {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit GotRedemptionSignature(
            msg.sender,
            _digest,
            _r,
            _s,
            block.timestamp
        );
    }

    /// @notice     Fires a RegisteredPubkey event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logRegisteredPubkey(
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY
    ) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit RegisteredPubkey(
            msg.sender,
            _signingGroupPubkeyX,
            _signingGroupPubkeyY,
            block.timestamp
        );
    }

    /// @notice     Fires a SetupFailed event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logSetupFailed() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit SetupFailed(msg.sender, block.timestamp);
    }

    /// @notice     Fires a FunderAbortRequested event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFunderRequestedAbort(bytes memory _abortOutputScript) public {
        // not external to allow bytes memory parameters
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit FunderAbortRequested(msg.sender, _abortOutputScript);
    }

    /// @notice     Fires a FraudDuringSetup event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFraudDuringSetup() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit FraudDuringSetup(msg.sender, block.timestamp);
    }

    /// @notice     Fires a Funded event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFunded(bytes32 _txid) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Funded(msg.sender, _txid, block.timestamp);
    }

    /// @notice     Fires a CourtesyCalled event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logCourtesyCalled() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit CourtesyCalled(msg.sender, block.timestamp);
    }

    /// @notice             Fires a StartedLiquidation event.
    /// @dev                We append the sender, which is the deposit contract that called.
    /// @param _wasFraud    True if liquidating for fraud.
    function logStartedLiquidation(bool _wasFraud) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit StartedLiquidation(msg.sender, _wasFraud, block.timestamp);
    }

    /// @notice     Fires a Redeemed event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logRedeemed(bytes32 _txid) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Redeemed(msg.sender, _txid, block.timestamp);
    }

    /// @notice     Fires a Liquidated event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logLiquidated() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Liquidated(msg.sender, block.timestamp);
    }

    /// @notice     Fires a ExitedCourtesyCall event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logExitedCourtesyCall() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit ExitedCourtesyCall(msg.sender, block.timestamp);
    }

    /// @notice               Sets the tbtcDepositToken contract.
    /// @dev                  The contract is used by `approvedToLog` to check if the
    ///                       caller is a Deposit contract. This should only be called once.
    /// @param  _tbtcDepositTokenAddress  The address of the tbtcDepositToken.
    function setTbtcDepositToken(TBTCDepositToken _tbtcDepositTokenAddress)
        internal
    {
        require(
            address(tbtcDepositToken) == address(0),
            "tbtcDepositToken is already set"
        );
        tbtcDepositToken = _tbtcDepositTokenAddress;
    }

    //
    // AUTH
    //

    /// @notice             Checks if an address is an allowed logger.
    /// @dev                checks tbtcDepositToken to see if the caller represents
    ///                     an existing deposit.
    ///                     We don't require this, so deposits are not bricked if the system borks.
    /// @param  _caller     The address of the calling contract.
    /// @return             True if approved, otherwise false.
    function approvedToLog(address _caller) public view returns (bool) {
        return tbtcDepositToken.exists(uint256(_caller));
    }
}
