//SourceUnit: Access.sol

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                           
*        #######                                                           # ###      /                                            
*      /       ###                                                       /  /###  / #/                    #                        
*     /         ##                                          #           /  /  ###/  ##                   ###                       
*     ##        #                                          ##          /  ##   ##   ##                    #                        
*      ###                                                 ##         /  ###        ##                                             
*     ## ###      ### /### /###     /###   ###  /###     ########    ##   ##        ##  /##      /###   ###       /###      /##    
*      ### ###     ##/ ###/ /##  / / ###  / ###/ #### / ########     ##   ##        ## / ###    / ###  / ###     / ###  /  / ###   
*        ### ###    ##  ###/ ###/ /   ###/   ##   ###/     ##        ##   ##        ##/   ###  /   ###/   ##    /   ###/  /   ###  
*          ### /##  ##   ##   ## ##    ##    ##            ##  k     ##   ##        ##     ## ##    ##    ##   ##        ##    ### 
*            #/ /## ##   ##   ## ##    ##    ##            ##  a     ##   ##        ##     ## ##    ##    ##   ##        ########  
*             #/ ## ##   ##   ## ##    ##    ##            ##  i      ##  ##        ##     ## ##    ##    ##   ##        #######   
*              # /  ##   ##   ## ##    ##    ##            ##  z       ## #      /  ##     ## ##    ##    ##   ##        ##        
*    /##        /   ##   ##   ## ##    /#    ##            ##  e        ###     /   ##     ## ##    ##    ##   ###     / ####    / 
*   /  ########/    ###  ###  ### ####/ ##   ###           ##  n         ######/    ##     ##  ######     ### / ######/   ######/  
*  /     #####       ###  ###  ### ###   ##   ###           ## -           ###       ##    ##   ####       ##/   #####     #####   
*  #                                                           w                           /                                       
*   ##                                                         e                          /                                        
*                                                              b                         /                                         
*                                                                                       /                                        
*
* Start Receiving TRON to Your Personal Wallet within 5-Minutes, SmartChoice Crowdfunding System Makes it Easy!
* https://www.smartchoiceofficial.io
* Make a smart choice, join today!
*/


pragma solidity 0.5.12;

import './DataStorage.sol';

contract Access is DataStorage {

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal reentryStatus;

  modifier isOwner(address _addr) {
    require(owner == _addr, "Restricted Access!");
    _;
  }

  modifier isMember(address _addr) {
    require(members[_addr].id > 0, "Register Account First!");
    _;
  }

  modifier isRecurring(address _addr) {
    require(recurSystem == _addr, "Restricted Access!");
    _;
  }
  
  modifier blockReEntry() {
    require(reentryStatus != ENTRY_DISABLED, "Security Block");
    reentryStatus = ENTRY_DISABLED;

    _;

    reentryStatus = ENTRY_ENABLED;
  }
}

//SourceUnit: DataStorage.sol

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                           
*        #######                                                           # ###      /                                            
*      /       ###                                                       /  /###  / #/                    #                        
*     /         ##                                          #           /  /  ###/  ##                   ###                       
*     ##        #                                          ##          /  ##   ##   ##                    #                        
*      ###                                                 ##         /  ###        ##                                             
*     ## ###      ### /### /###     /###   ###  /###     ########    ##   ##        ##  /##      /###   ###       /###      /##    
*      ### ###     ##/ ###/ /##  / / ###  / ###/ #### / ########     ##   ##        ## / ###    / ###  / ###     / ###  /  / ###   
*        ### ###    ##  ###/ ###/ /   ###/   ##   ###/     ##        ##   ##        ##/   ###  /   ###/   ##    /   ###/  /   ###  
*          ### /##  ##   ##   ## ##    ##    ##            ##  k     ##   ##        ##     ## ##    ##    ##   ##        ##    ### 
*            #/ /## ##   ##   ## ##    ##    ##            ##  a     ##   ##        ##     ## ##    ##    ##   ##        ########  
*             #/ ## ##   ##   ## ##    ##    ##            ##  i      ##  ##        ##     ## ##    ##    ##   ##        #######   
*              # /  ##   ##   ## ##    ##    ##            ##  z       ## #      /  ##     ## ##    ##    ##   ##        ##        
*    /##        /   ##   ##   ## ##    /#    ##            ##  e        ###     /   ##     ## ##    ##    ##   ###     / ####    / 
*   /  ########/    ###  ###  ### ####/ ##   ###           ##  n         ######/    ##     ##  ######     ### / ######/   ######/  
*  /     #####       ###  ###  ### ###   ##   ###           ## -           ###       ##    ##   ####       ##/   #####     #####   
*  #                                                           w                           /                                       
*   ##                                                         e                          /                                        
*                                                              b                         /                                         
*                                                                                       /                                        
*
* Start Receiving TRON to Your Personal Wallet within 5-Minutes, SmartChoice Crowdfunding System Makes it Easy!
* https://www.smartchoiceofficial.io
* Make a smart choice, join today!
*/

pragma solidity 0.5.12;

contract DataStorage {

  struct Account {
    uint id;
    uint[] activeLevel;
    address sponsor;
    mapping(uint => S1) x31Positions;
    mapping(uint => S2) p24Positions;
    mapping(uint => S3) p24RPositions;
  }

  struct S1 {
    uint8 passup;
    uint8 reEntryCheck;
    uint8 placement;
    uint cycle;
    address sponsor;
  }

  struct S2 {
    uint insert;
    uint position;
    address sponsor;
  }

  struct S3 {
    uint insert;
    uint position;
    uint expire;
    uint finalExpire;
    address sponsor;
  }
 
  struct Level {
    uint id;
    uint[] cost;
    uint[] commission;
    uint[] fee;
  }

  uint internal constant REENTRY_REQ = 2;
  uint internal constant PERIOD_SETUP = 1924992000;
  uint internal constant PERIOD = 2592000;
  uint internal constant PERIOD_BEFORE = 259200;

  mapping(address => Account) public members;
  mapping(uint => address) public idToMember;
  mapping(uint => Level) public levelCost;
  
  uint public lastId;
  uint public orderId;
  uint public topLevel;
  bool public contractEnabled;
  address internal owner;
  address internal holder;
  address internal proxied;
  address internal feeSystem;
  address internal recurSystem;
}

//SourceUnit: Events.sol

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                           
*        #######                                                           # ###      /                                            
*      /       ###                                                       /  /###  / #/                    #                        
*     /         ##                                          #           /  /  ###/  ##                   ###                       
*     ##        #                                          ##          /  ##   ##   ##                    #                        
*      ###                                                 ##         /  ###        ##                                             
*     ## ###      ### /### /###     /###   ###  /###     ########    ##   ##        ##  /##      /###   ###       /###      /##    
*      ### ###     ##/ ###/ /##  / / ###  / ###/ #### / ########     ##   ##        ## / ###    / ###  / ###     / ###  /  / ###   
*        ### ###    ##  ###/ ###/ /   ###/   ##   ###/     ##        ##   ##        ##/   ###  /   ###/   ##    /   ###/  /   ###  
*          ### /##  ##   ##   ## ##    ##    ##            ##  k     ##   ##        ##     ## ##    ##    ##   ##        ##    ### 
*            #/ /## ##   ##   ## ##    ##    ##            ##  a     ##   ##        ##     ## ##    ##    ##   ##        ########  
*             #/ ## ##   ##   ## ##    ##    ##            ##  i      ##  ##        ##     ## ##    ##    ##   ##        #######   
*              # /  ##   ##   ## ##    ##    ##            ##  z       ## #      /  ##     ## ##    ##    ##   ##        ##        
*    /##        /   ##   ##   ## ##    /#    ##            ##  e        ###     /   ##     ## ##    ##    ##   ###     / ####    / 
*   /  ########/    ###  ###  ### ####/ ##   ###           ##  n         ######/    ##     ##  ######     ### / ######/   ######/  
*  /     #####       ###  ###  ### ###   ##   ###           ## -           ###       ##    ##   ####       ##/   #####     #####   
*  #                                                           w                           /                                       
*   ##                                                         e                          /                                        
*                                                              b                         /                                         
*                                                                                       /                                        
*
* Start Receiving TRON to Your Personal Wallet within 5-Minutes, SmartChoice Crowdfunding System Makes it Easy!
* https://www.smartchoiceofficial.io
* Make a smart choice, join today!
*/

pragma solidity 0.5.12;

contract Events {
  event Registration(address member, uint memberId, address sponsor, uint orderId);
  event Upgrade(address member, address sponsor, uint system, uint level, uint orderId);
  event Recurring(address member, address sponsor, uint system, uint level, uint orderId);
  event PlacementS1(address member, address sponsor, uint level, uint cycle, uint8 placement, bool passup, uint orderId);
  event PlacementS2(address member, address sponsor, uint level, uint position, bool powerline, uint orderId);
  event PlacementS3(address member, address sponsor, uint level, uint position, bool powerline, uint orderId);
  event PlacementChange(address member, address oldSponsor, uint system, uint level, uint oldPosition, uint orderId);
  event PlacementExpire(address member, uint system, uint level, uint expire, uint finalExpire, uint orderId);
  event Cycle(address member, address fromPosition, uint system, uint level, uint orderId);
  event Powerline(address member, address fromPosition, uint system, uint level, uint orderId);
  event PlacementReEntry(address member, address reEntryFrom, uint system, uint level, uint orderId);
  event FundsPayout(address member, address payoutFrom, uint system, uint level, uint orderId);
  event FundsPassup(address member, address passupFrom, uint system, uint level, uint orderId);
}

//SourceUnit: Proxy.sol

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                           
*        #######                                                           # ###      /                                            
*      /       ###                                                       /  /###  / #/                    #                        
*     /         ##                                          #           /  /  ###/  ##                   ###                       
*     ##        #                                          ##          /  ##   ##   ##                    #                        
*      ###                                                 ##         /  ###        ##                                             
*     ## ###      ### /### /###     /###   ###  /###     ########    ##   ##        ##  /##      /###   ###       /###      /##    
*      ### ###     ##/ ###/ /##  / / ###  / ###/ #### / ########     ##   ##        ## / ###    / ###  / ###     / ###  /  / ###   
*        ### ###    ##  ###/ ###/ /   ###/   ##   ###/     ##        ##   ##        ##/   ###  /   ###/   ##    /   ###/  /   ###  
*          ### /##  ##   ##   ## ##    ##    ##            ##  k     ##   ##        ##     ## ##    ##    ##   ##        ##    ### 
*            #/ /## ##   ##   ## ##    ##    ##            ##  a     ##   ##        ##     ## ##    ##    ##   ##        ########  
*             #/ ## ##   ##   ## ##    ##    ##            ##  i      ##  ##        ##     ## ##    ##    ##   ##        #######   
*              # /  ##   ##   ## ##    ##    ##            ##  z       ## #      /  ##     ## ##    ##    ##   ##        ##        
*    /##        /   ##   ##   ## ##    /#    ##            ##  e        ###     /   ##     ## ##    ##    ##   ###     / ####    / 
*   /  ########/    ###  ###  ### ####/ ##   ###           ##  n         ######/    ##     ##  ######     ### / ######/   ######/  
*  /     #####       ###  ###  ### ###   ##   ###           ## -           ###       ##    ##   ####       ##/   #####     #####   
*  #                                                           w                           /                                       
*   ##                                                         e                          /                                        
*                                                              b                         /                                         
*                                                                                       /                                        
*
* Start Receiving TRON to Your Personal Wallet within 5-Minutes, SmartChoice Crowdfunding System Makes it Easy!
* https://www.smartchoiceofficial.io
* Make a smart choice, join today!
*/

pragma solidity 0.5.12;

import './DataStorage.sol';
import './Access.sol';
import './Events.sol';

contract Proxy is DataStorage, Access, Events {
  
  constructor(address _proxied, address _holder) public {
    owner = msg.sender;
    holder = _holder;
    proxied = _proxied;

    reentryStatus = ENTRY_ENABLED;
    contractEnabled = false;
  }

  function () external payable {
    address proxy = proxied;

    assembly {
      calldatacopy(0, 0, calldatasize())
        let result := delegatecall(gas(), proxy, 0, calldatasize(), 0, 0)
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 { revert(0, returndatasize()) }
        default { return(0, returndatasize()) }
    }
  }

  function getAffiliateId() external view returns (uint) {
    return members[msg.sender].id;
  }

  function getAffiliateWallet(uint32 memberId) external view returns (address) {
    return idToMember[memberId];
  }

  function getAffiliatePositionX31(address _addr, uint _level) external view returns (uint, address) {
    return (members[_addr].x31Positions[_level].placement, members[_addr].x31Positions[_level].sponsor);
  }

  function getAffiliatePositionP24(address _addr, uint _level) external view returns (uint, address) {
    return (members[_addr].p24Positions[_level].position, members[_addr].p24Positions[_level].sponsor);
  }

  function getAffiliatePositionP24R(address _addr, uint _level) external view returns (uint, address, uint, uint) {
    return (members[_addr].p24RPositions[_level].position, members[_addr].p24RPositions[_level].sponsor, members[_addr].p24RPositions[_level].expire, members[_addr].p24RPositions[_level].finalExpire);
  }

  function bundleCost(uint _level) external view isMember(msg.sender) returns (uint) {
    require(contractEnabled == true, "Closed For Maintenance");
    require((_level > 0 && _level <= topLevel), "Invalid level.");

    uint amount = 0;

    for (uint num = (members[msg.sender].activeLevel[0] + 1);num <= _level;num++) {
      amount += levelCost[num].cost[0];
    }

    for (uint num = (members[msg.sender].activeLevel[1] + 1);num <= _level;num++) {
      amount += levelCost[num].cost[1];
    }

    for (uint num = (members[msg.sender].activeLevel[2] + 1);num <= _level;num++) {
      if (members[msg.sender].p24RPositions[num].finalExpire < block.timestamp) {
        amount += levelCost[num].cost[2];
      }
    }

    require((amount > 0), "Already active at level!");

    return amount;
  }

  function handleForfeitedBalance(address payable _addr) external {
    require((msg.sender == owner || msg.sender == holder), "Restricted Access!");
    
    (bool success, ) = _addr.call.value(address(this).balance)("");

    require(success, 'Failed');
  }

  function setProxy(address _addr) external isOwner(msg.sender) {
    proxied = _addr;
  }
}