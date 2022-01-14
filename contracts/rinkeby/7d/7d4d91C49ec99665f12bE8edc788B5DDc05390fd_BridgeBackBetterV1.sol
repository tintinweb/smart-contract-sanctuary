// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IBBBPoolV1.sol";

/**
 * @title Contract allowing users to bridge assets from Arbitrum to mainnet faster by selling their withdrawals.
 * @author Theo Ilie
 */
contract BridgeBackBetterV1 {
    struct ValidWithdrawalClaim {
        uint amount; // In wei
        uint withdrawalId;
        uint timestampToSlashAt; // The block after which the user can be slashed for the pool not receiving a valid withdrawal
    }

    struct NodeOperator {
        uint bondedBalance; // In wei
        uint lockedBondedBalance; // Balance is locked after verifying a transaction until the transaction completes
        ValidWithdrawalClaim[] withdrawalClaims;
    }

    address public owner;
    IBBBPoolV1[] public liqPools;
    mapping(address => NodeOperator) public nodeOperators;
    uint public totalAvailableBonded; // Total bonded that's not slashed or locked
    uint public stakerFee; // In wei
    uint public nodeOperatorFee; // In wei

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can do this");
        _;
    }

    constructor(uint _stakerFee, uint _nodeOperatorFee) {
        owner = msg.sender;
        stakerFee = _stakerFee;
        nodeOperatorFee = _nodeOperatorFee;
    }

    function setStakerFee(uint _stakerFee) external onlyOwner {
        stakerFee = _stakerFee;
    }

    function setNodeOperatorFee(uint _nodeOperatorFee) external onlyOwner {
        nodeOperatorFee = _nodeOperatorFee;
    }

    function addLiqPool(IBBBPoolV1 liqPool) external onlyOwner {
        liqPools.push(liqPool);
    }

    /// Bond ether that can be slashed for verifying a transaction that turns out to be invalid.
    function bond() external payable {
        nodeOperators[msg.sender].bondedBalance += msg.value;
        totalAvailableBonded += msg.value;
    }

    /// Unbond `amount`.
    function unbond(uint amount) external {
        NodeOperator storage nodeOperator = nodeOperators[msg.sender];
        require(nodeOperator.bondedBalance >= amount, "Insufficient unlocked balance");

        nodeOperator.bondedBalance -= amount;
        totalAvailableBonded -= amount;
    }

    /**
     * Verify that a withdrawal is valid and claim a fee.
     * Only callable by node operators with a high enough bond to cover losses.
     * @dev If `withdrawId` doesn't add `amount` to the pool within 7 days then the bonder will be slashed.
     * @param recipient The address that should receive the funds
     * @param amount The amount that the recipient should receive
     * @param withdrawalId The ID that was generated on Arbitrum and will be passed with a valid transaction in 7 days
     */
    function verifyWithdrawal(address recipient, uint amount, uint withdrawalId) external {
        // Only node operators can verify withdrawals, and they must have enough bonded to be slashed for incorrect verification
        require(nodeOperators[msg.sender].bondedBalance >= amount, "Not enough bonded");

        // Send the recipient the money for their withdraw (minus fees)
        liqPools[0].advanceWithdrawal(recipient, amount - nodeOperatorFee, stakerFee);

        // Update the bonder's and contract's balance
        nodeOperators[msg.sender].bondedBalance -= amount;
        nodeOperators[msg.sender].lockedBondedBalance += amount + nodeOperatorFee;
        totalAvailableBonded -= amount;

        // Add a claim saying that there will be a withdrawal with the ID 'withdrawalId' after
        // the challenge period (7 days) or else the node operator will be slashed
        nodeOperators[msg.sender].withdrawalClaims.push(ValidWithdrawalClaim(amount, withdrawalId, block.timestamp + 7 days));
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