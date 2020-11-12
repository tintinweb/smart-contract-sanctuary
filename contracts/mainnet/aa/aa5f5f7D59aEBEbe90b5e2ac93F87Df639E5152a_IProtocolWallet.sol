// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
import "./IERC20.sol";

/// @title Protocol Wallet interface
interface IProtocolWallet {
    event FundsAddedToPool(uint256 added, uint256 total);

    /*
    * External functions
    */

    /// @dev Returns the address of the underlying staked token.
    /// @return balance uint256 the balance
    function getBalance() external view returns (uint256 balance);

    /// @dev Transfers the given amount of orbs tokens form the sender to this contract an update the pool.
    function topUp(uint256 amount) external;

    /// @dev Withdraw from pool to a the sender's address, limited by the pool's MaxRate.
    /// A maximum of MaxRate x time period since the last Orbs transfer may be transferred out.
    function withdraw(uint256 amount) external; /* onlyClient */


    /*
    * Governance functions
    */

    event ClientSet(address client);
    event MaxAnnualRateSet(uint256 maxAnnualRate);
    event EmergencyWithdrawal(address addr);
    event OutstandingTokensReset(uint256 startTime);

    /// @dev Sets a new transfer rate for the Orbs pool.
    function setMaxAnnualRate(uint256 annual_rate) external; /* onlyMigrationManager */

    function getMaxAnnualRate() external view returns (uint256);

    /// @dev transfer the entire pool's balance to a new wallet.
    function emergencyWithdraw() external; /* onlyMigrationManager */

    /// @dev sets the address of the new contract
    function setClient(address client) external; /* onlyFunctionalManager */

    function resetOutstandingTokens(uint256 startTime) external; /* onlyMigrationOwner */

    }
