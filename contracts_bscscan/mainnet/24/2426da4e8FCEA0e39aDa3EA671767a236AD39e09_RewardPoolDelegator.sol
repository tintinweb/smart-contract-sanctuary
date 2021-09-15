/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.5.16;


contract RewardPoolDelegationStorage {
    // The FILST token address
    address public filstAddress;

    // The eFIL token address
    address public efilAddress;

    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active implementation
    */
    address public implementation;

    /**
    * @notice Pending implementation
    */
    address public pendingImplementation;
}

interface IRewardCalculator {
    function calculate(uint filstAmount, uint fromBlockNumber) external view returns (uint);
}

interface IRewardStrategy {
    // returns allocated result
    function allocate(address staking, uint rewardAmount) external view returns (uint stakingPart, address[] memory others, uint[] memory othersParts);
}

interface IFilstManagement {
    function getTotalMintedAmount() external view returns (uint);
    function getMintedAmount(string calldata miner) external view returns (uint);
}

contract RewardPoolStorage is RewardPoolDelegationStorage {
    // The IFilstManagement
    IFilstManagement public management;

    // The IRewardStrategy
    IRewardStrategy public strategy;

    // The IRewardCalculator contract
    IRewardCalculator public calculator;

    // The address of FILST Staking contract
    address public staking;

    // The last accrued block number
    uint public accrualBlockNumber;

    // The accrued reward for each participant
    mapping(address => uint) public accruedRewards;

    struct Debt {
        // accrued index of debts 
        uint accruedIndex;

        // accrued debts
        uint accruedAmount;

        // The last time the miner repay debts
        uint lastRepaymentBlock;
    }

    // The last accrued index of debts
    uint public debtAccruedIndex;

    // The accrued debts for each miner
    // minerId -> Debt
    mapping(string => Debt) public minerDebts;
}

contract RewardPoolDelegator is RewardPoolDelegationStorage {
    /**
      * @notice Emitted when pendingImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingImplementation is accepted, which means implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(address filstAddress_, address efilAddress_) public {
        filstAddress = filstAddress_;
        efilAddress = efilAddress_;

        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) external {
        require(msg.sender == admin, "admin check");

        address oldPendingImplementation = pendingImplementation;
        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
    * @notice Accepts new implementation. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() external {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "pendingImplementation check");

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;
        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "admin check");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "pendingAdmin check");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }


    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}