pragma solidity ^0.5.16;
import "./Exponential.sol";
contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public wanttrollerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingWanttrollerImplementation;
}
contract WanttrollerV1Storage is UnitrollerAdminStorage, Exponential {
  struct WantDrop {
    /// @notice Total accounts requesting piece of drop 
    uint numRegistrants;
    
    /// @notice Total amount to be dropped
    uint totalDrop;
  }

  // @notice Total amount dropped
  uint public totalDropped;
  
  // @notice Min time between drops
  uint public waitblocks = 200; 

  // @notice Tracks beginning of this drop 
  uint public currentDropStartBlock;
  
  // @notice Tracks the index of the current drop
  uint public currentDropIndex;
  
  /// @notice Store total registered and total reward for that drop 
  mapping(uint => WantDrop) public wantDropState;

  /// @notice Any WANT rewards accrued but not yet collected 
  mapping(address => uint) public accruedRewards;
  
  /// @notice Track the last drop this account was part of 
  mapping(address => uint) public lastDropRegistered;

  address wantTokenAddress;

  address[] public accountsRegisteredForDrop;

  /// @notice Stores the current amount of drop being awarded
  uint public currentReward;
  
  /// @notice Each time rewards are distributed next rewards reduced by applying this factor
  uint public discountFactor = 0.9995e18;

  // Store faucet address 
  address public wantFaucetAddress;
}
