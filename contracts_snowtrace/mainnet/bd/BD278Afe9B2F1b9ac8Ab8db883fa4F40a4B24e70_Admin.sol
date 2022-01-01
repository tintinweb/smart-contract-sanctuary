// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.11;

// import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
// import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SYSTEM {
    Admin public ADMIN;

    constructor(Admin admin_) {
      ADMIN = admin_; 
    }


    function KEYCODE() external view virtual returns (bytes3) {}


    modifier onlyPolicy {
        require (ADMIN.APPROVED_POLICIES( msg.sender ), "Only installed APPROVED_Policies can call this function");
        _;
    }
}

contract POLICY {
  Admin public ADMIN;

  constructor(Admin admin_) {
      ADMIN = admin_; 
  }


  function _requireSystem(bytes3 keycode_) internal view returns (address) {
    require( ADMIN.SYSTEMS( keycode_ ) != address(0), 
             "cannot _requireSytem(): system does not exist" );
    
    return ADMIN.SYSTEMS( keycode_ );
  }

}

contract Admin {


  /////////////////////////////////////////////////////////////////////////////////////
  //                                  EPOCH STUFF                                    //
  /////////////////////////////////////////////////////////////////////////////////////


  uint256 public startingEpochTimestamp; 
  uint256 public constant epochLength = 60 * 60 * 24 * 7; // number of seconds in a week
  bool public started;


  function currentEpoch() external view returns (uint16) {
    if ( block.timestamp >= startingEpochTimestamp ) {
      return uint16((( block.timestamp - startingEpochTimestamp ) / epochLength ) + 1);
    } else {
      return 0;
    }
  }


  function setStartingEpoch() external {
    require (started == false, "cannot setStartingEpoch(): operator is already started");
    startingEpochTimestamp = ((( block.timestamp / epochLength ) + 1 ) * epochLength );
    started = true;
  }


  ///////////////////////////////////////////////////////////////////////////////////////
  //                                 DEPENDENCY MANAGEMENT                             //
  ///////////////////////////////////////////////////////////////////////////////////////

  address public executive; 
  mapping(bytes3 => address) public SYSTEMS; // get contract for system keycode
  mapping(address => bool) public APPROVED_POLICIES; // whitelisted apps
  

  modifier onlyExecutive() {
    require ( msg.sender == executive, "onlyExecutive(): only the assigned executive can call the function" );
    _;
  }


  constructor() {
    executive = msg.sender;
  }
 

  function changeExecutive( address newExecutive_ ) external onlyExecutive {
    executive = newExecutive_;
  }


  function installSystem( SYSTEM system_ ) external onlyExecutive {
    require( SYSTEMS[ system_.KEYCODE() ] == address(0), "Existing system already present" );
    SYSTEMS[ system_.KEYCODE() ] = address(system_);
  }


  // function uninstallSystem( bytes2 keycode_ ) external onlyExecutive {
  //   require( SYSTEMS[ keycode_ ] != address(0), "Existing system must be present" );
  //   SYSTEMS[ keycode_ ] = address(0);
  // }


  function approvePolicy( address policy_ ) external onlyExecutive {
    require( APPROVED_POLICIES[policy_] == false, "Policy is already installed" );
    APPROVED_POLICIES[policy_] = true;
  }


  // function disablePolicy( POLICY policy_ ) external onlyExecutive {
  //   require( APPROVED_POLICIES[address( app )] == false, "Policy is already installed" );
  //   APPROVED_POLICIES[ address( app )] = false;

  //   for (uint16 i=0; i < Policy.systemPermissions.length; i++) {
  //     IsActivePolicy[ Policy.systemPermissions[ i ]][ app ] = false; // turn the policy off
  //     TotalActiveAPPROVED_POLICIES[ Policy.systemPermissions[ i ]][ app ]--;
  //   }
  // }

}