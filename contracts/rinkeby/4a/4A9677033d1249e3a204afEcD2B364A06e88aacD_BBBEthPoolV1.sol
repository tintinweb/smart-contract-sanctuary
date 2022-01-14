// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IBBBPoolV1.sol";

/**
 * @title Pool for providing ether liquidity for Arbitrum fast withdrawals.
 * @author Theo Ilie
 */
contract BBBEthPoolV1 is IBBBPoolV1 {
    struct Balance {
        uint staked;
        UnstakingBalance[] unstaking;
    }

    struct UnstakingBalance {
        uint amount;
        uint timestampUnlocked; // TODO: With node operators we probably don't need a 7-day lockup anymore
    }

    /// Balances of stakers
    mapping(address => Balance) public balances;

    /// Amount of wei that's locked and ready to be used for fast withdrawals
    uint public availableLiq;

    /// Address of the BridgeBackBetterV1 contract
    address public protocol;

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only the B3 protocol can do this");
        _;
    }

    constructor (address _protocol) {
        protocol = _protocol;
    }

    // TODO: Analyze this for attacks like reentrancy
    function advanceWithdrawal(address recipient, uint amount, uint fee) external override onlyProtocol {
        require(availableLiq >= amount, "Not enough liquidity staked");
        availableLiq -= amount;
        (bool success,) = recipient.call{ value: amount - fee }("");
        require(success, "Transfer failed");
        // TODO: Add fee accounting to the pool
    }

    function distributeFee(uint amount) external override {
        // TODO
     }

    function provideLiq() external payable override {
        Balance storage balance = balances[msg.sender];
        balance.staked += msg.value;
        availableLiq += msg.value;
    }

    function unstake(uint amount) external override {
        Balance storage balance = balances[tx.origin];

        require(balance.staked >= amount, "Amount requested exceeds staked balance");

        balance.staked -= amount;
        balance.unstaking.push(UnstakingBalance(amount, block.timestamp + 7 days));
    }

    function withdrawBalance(uint amount) external override {
        // TODO: Withdraw as many elements of balances[tx.sender].unstaking as needed
    }

    function getTotalBalance(address farmer) external view override returns (uint) {
        return this.getStakedBalance(farmer) + this.getUnstakedBalance(farmer) + this.getWithdrawableBalance(farmer);
    }

    function getStakedBalance(address farmer) external view override returns (uint) {
        return balances[farmer].staked;
    }

    function getUnstakedBalance(address farmer) external view override returns (uint unstaked_) {
        Balance storage balance = balances[farmer];
        for (uint i = 0; i < balance.unstaking.length; i++) {
            UnstakingBalance storage unstaking = balance.unstaking[i];

            // Balance is still unstaking and not withdrawable until the current blocktime is at least `timestampUnlocked`
            if (block.timestamp < unstaking.timestampUnlocked) {
                unstaked_ += unstaking.amount;
            }
        }
    }

    function getWithdrawableBalance(address farmer) external view override returns (uint withdrawable_) {
        Balance storage balance = balances[farmer];
        for (uint i = 0; i < balance.unstaking.length; i++) {
            UnstakingBalance storage unstaking = balance.unstaking[i];

            // Balance is withdrawable once the current blocktime is at least `timestampUnlocked`
            if (block.timestamp >= unstaking.timestampUnlocked) {
                withdrawable_ += unstaking.amount;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title A pool to provide liquidity for "fast withdrawals" on Arbitrum.
 * @notice This pool only supports ether and requires staking for 15 days.
           If no one uses the ether within the first 8 days of staking, then they will
           be unlocked for withdrawal and not count as liquidity in the pool since they must
           be locked at least 7 days (the challenge period for Arbitrum).
 * @author Theo Ilie
 */
interface IBBBPoolV1 {
    /**
     * @notice Advance the withdrawal funds of a recipient immediately (don't make them wait 7 days).
     * @param recipient The address to send funds to
     * @param amount The amount of wei to send to the recipient
     * @param fee The amount of wei that the pool gets to keep in exchange for advancing the withdrawal
     */
    function advanceWithdrawal(address recipient, uint amount, uint fee) external;

    /**
     * @notice Distribute a fee (paid by withdrawer) to stakers, in proportion to each staker's stake
     * @param amount The total fee, in wei, to distribute
     */
    function distributeFee(uint amount) external;

    /// @notice Stake ether. Unstaking takes 7 days.
    function provideLiq() external payable;

    /// Start unstaking `amount` wei. Will be available to withdraw in 7 days.
    function unstake(uint amount) external;

    /// Withdraw `amount` wei.
    function withdrawBalance(uint amount) external;
    
    /**
     * @param farmer The address of the wallet to view total ether staked
     * @return Amount of ether that the address has in the pool, including ether that is unstaked or in the process of unstaking
     */
    function getTotalBalance(address farmer) external view returns (uint);

    /**
     * @param farmer The address of the wallet to view staked ether
     * @return Amount of ether that the address has staked
     */
    function getStakedBalance(address farmer) external view returns (uint);

    /**
     * @param farmer The address of the wallet to view unstaked ether
     * @return Amount of ether that the address has started unstaking but cannot withdraw yet
     */
    function getUnstakedBalance(address farmer) external view returns (uint);

    /**
     * @param farmer The address of the wallet to view withdrawable ether
     * @return Amount of ether that the address has unstaked and can withdraw
     */
    function getWithdrawableBalance(address farmer) external view returns (uint);
}