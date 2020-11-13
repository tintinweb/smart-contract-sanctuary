pragma solidity 0.5.17;

import {DepositLog} from "../DepositLog.sol";
import {DepositUtils} from "./DepositUtils.sol";

library OutsourceDepositLogging {


    /// @notice               Fires a Created event.
    /// @dev                  `DepositLog.logCreated` fires a Created event with
    ///                       _keepAddress, msg.sender and block.timestamp.
    ///                       msg.sender will be the calling Deposit's address.
    /// @param  _keepAddress  The address of the associated keep.
    function logCreated(DepositUtils.Deposit storage _d, address _keepAddress) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logCreated(_keepAddress);
    }

    /// @notice                 Fires a RedemptionRequested event.
    /// @dev                    This is the only event without an explicit timestamp.
    /// @param  _redeemer       The ethereum address of the redeemer.
    /// @param  _digest         The calculated sighash digest.
    /// @param  _utxoValue       The size of the utxo in sat.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _requestedFee   The redeemer or bump-system specified fee.
    /// @param  _outpoint       The 36 byte outpoint.
    /// @return                 True if successful, else revert.
    function logRedemptionRequested(
        DepositUtils.Deposit storage _d,
        address _redeemer,
        bytes32 _digest,
        uint256 _utxoValue,
        bytes memory _redeemerOutputScript,
        uint256 _requestedFee,
        bytes memory _outpoint
    ) public { // not external to allow bytes memory parameters
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRedemptionRequested(
            _redeemer,
            _digest,
            _utxoValue,
            _redeemerOutputScript,
            _requestedFee,
            _outpoint
        );
    }

    /// @notice         Fires a GotRedemptionSignature event.
    /// @dev            We append the sender, which is the deposit contract that called.
    /// @param  _digest Signed digest.
    /// @param  _r      Signature r value.
    /// @param  _s      Signature s value.
    /// @return         True if successful, else revert.
    function logGotRedemptionSignature(
        DepositUtils.Deposit storage _d,
        bytes32 _digest,
        bytes32 _r,
        bytes32 _s
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logGotRedemptionSignature(
            _digest,
            _r,
            _s
        );
    }

    /// @notice     Fires a RegisteredPubkey event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logRegisteredPubkey(
        DepositUtils.Deposit storage _d,
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRegisteredPubkey(
            _signingGroupPubkeyX,
            _signingGroupPubkeyY);
    }

    /// @notice     Fires a SetupFailed event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logSetupFailed(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logSetupFailed();
    }

    /// @notice     Fires a FunderAbortRequested event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFunderRequestedAbort(
        DepositUtils.Deposit storage _d,
        bytes memory _abortOutputScript
    ) public { // not external to allow bytes memory parameters
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFunderRequestedAbort(_abortOutputScript);
    }

    /// @notice     Fires a FraudDuringSetup event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFraudDuringSetup(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFraudDuringSetup();
    }

    /// @notice     Fires a Funded event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFunded(DepositUtils.Deposit storage _d, bytes32 _txid) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFunded(_txid);
    }

    /// @notice     Fires a CourtesyCalled event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logCourtesyCalled(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logCourtesyCalled();
    }

    /// @notice             Fires a StartedLiquidation event.
    /// @dev                We append the sender, which is the deposit contract that called.
    /// @param _wasFraud    True if liquidating for fraud.
    function logStartedLiquidation(DepositUtils.Deposit storage _d, bool _wasFraud) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logStartedLiquidation(_wasFraud);
    }

    /// @notice     Fires a Redeemed event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logRedeemed(DepositUtils.Deposit storage _d, bytes32 _txid) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRedeemed(_txid);
    }

    /// @notice     Fires a Liquidated event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logLiquidated(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logLiquidated();
    }

    /// @notice     Fires a ExitedCourtesyCall event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logExitedCourtesyCall(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logExitedCourtesyCall();
    }
}
