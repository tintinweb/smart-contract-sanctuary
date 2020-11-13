pragma solidity 0.5.17;

import "./CloneFactory.sol";
import "../deposit/Deposit.sol";
import "../system/TBTCSystem.sol";
import "../system/TBTCToken.sol";
import "../system/FeeRebateToken.sol";
import "../system/TBTCSystemAuthority.sol";
import {TBTCDepositToken} from "../system/TBTCDepositToken.sol";


/// @title Deposit Factory
/// @notice Factory for the creation of new deposit clones.
/// @dev We avoid redeployment of deposit contract by using the clone factory.
/// Proxy delegates calls to Deposit and therefore does not affect deposit state.
/// This means that we only need to deploy the deposit contracts once.
/// The factory provides clean state for every new deposit clone.
contract DepositFactory is CloneFactory, TBTCSystemAuthority{

    // Holds the address of the deposit contract
    // which will be used as a master contract for cloning.
    address payable public masterDepositAddress;
    TBTCDepositToken tbtcDepositToken;
    TBTCSystem public tbtcSystem;
    TBTCToken public tbtcToken;
    FeeRebateToken public feeRebateToken;
    address public vendingMachineAddress;

    constructor(address _systemAddress)
        TBTCSystemAuthority(_systemAddress)
    public {}

    /// @dev                          Set the required external variables.
    /// @param _masterDepositAddress  The address of the master deposit contract.
    /// @param _tbtcSystem            Tbtc system contract.
    /// @param _tbtcToken             TBTC token contract.
    /// @param _tbtcDepositToken      TBTC Deposit Token contract.
    /// @param _feeRebateToken        AFee Rebate Token contract.
    /// @param _vendingMachineAddress Address of the Vending Machine contract.
    function setExternalDependencies(
        address payable _masterDepositAddress,
        TBTCSystem _tbtcSystem,
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        address _vendingMachineAddress
    ) external onlyTbtcSystem {
        masterDepositAddress = _masterDepositAddress;
        tbtcDepositToken = _tbtcDepositToken;
        tbtcSystem = _tbtcSystem;
        tbtcToken = _tbtcToken;
        feeRebateToken = _feeRebateToken;
        vendingMachineAddress = _vendingMachineAddress;
    }

    event DepositCloneCreated(address depositCloneAddress);

    /// @notice Creates a new deposit instance and mints a TDT. This function is
    ///         currently the only way to create a new deposit.
    /// @dev Calls `Deposit.initializeDeposit` to initialize the instance. Mints
    ///      the TDT to the function caller. (See `TBTCDepositToken` for more
    ///      info on TDTs). Reverts if new deposits are currently paused, if the
    ///      specified lot size is not currently permitted, or if the selection
    ///      of the signers fails for any reason. Also reverts if the bonds
    ///      collateralizing the deposit would not be enough to cover a refund
    ///      of the deposit creation fee, should the signer group fail to
    ///      complete its setup process.
    /// @return The address of the new deposit.
    function createDeposit(uint64 _lotSizeSatoshis) external payable returns(address) {
        address cloneAddress = createClone(masterDepositAddress);
        emit DepositCloneCreated(cloneAddress);

        TBTCDepositToken(tbtcDepositToken).mint(msg.sender, uint256(cloneAddress));

        Deposit deposit = Deposit(address(uint160(cloneAddress)));
        deposit.initialize(address(this));
        deposit.initializeDeposit.value(msg.value)(
                tbtcSystem,
                tbtcToken,
                tbtcDepositToken,
                feeRebateToken,
                vendingMachineAddress,
                _lotSizeSatoshis
            );

        return cloneAddress;
    }
}
