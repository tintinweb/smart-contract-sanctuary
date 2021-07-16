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
  
  modifier isFeeSystem(address _addr) {
    require(feeSystem == _addr, "Restricted Access!");
    _;
  }

  modifier isMember(address _addr) {
    (uint memberId, address sponsor) = sc_handle.members(_addr);

    require(memberId > 0, "Register Account First!");
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

import './SmartChoiceABI.sol';

contract DataStorage {

  SmartChoiceABI internal sc_handle;

  struct Account { 
    uint number;
    bool active;
    mapping(uint => Subscription) level;
  }

  struct Subscription {
    uint periodPaid;
    uint nextPayment;
    uint paidUntil;
  }
 
  struct Level {
    uint cost;
    uint commission;
    uint fee;
  }

  uint internal constant SYSTEM = 3;
  uint internal constant PERIOD = 2592000;
  uint internal constant PERIOD_BEFORE = 259200;

  mapping(address => Account) public members;
  mapping(uint => Level) public levelCost;
  
  uint public orderId;
  uint public topLevel;
  bool public contractEnabled;
  address internal owner;
  address internal holder;
  address internal feeSystem;
  address internal proxied;
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
  event Initiate(address member, uint system, uint level, uint period, uint orderId);
  event Process(address member, uint system, uint level, uint execute, uint orderId);
  event Payment(address member, uint system, uint level, uint orderId);
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

  function subscriptionCost(uint _level, uint _period) external view isMember(msg.sender) returns (uint) {
    require((_level > 0 && _level <= topLevel), "Invalid system level.");
    require((_period > 0), "Invalid period");

    (uint[] memory level) = locatePeriodsRequired(msg.sender, _level, _period);
    (uint cost, uint fee) = calculateCost(level);
    
    return cost;
  }

  function locatePeriodsRequired(address _addr, uint _level, uint _period) internal view returns (uint[] memory) {
    uint[] memory level = new uint[](topLevel + 1);
    uint expireTime = block.timestamp + (_period * PERIOD);
    
    for (uint num=1;num <= _level;num++) {
      (uint position, address sponsor, uint expire, uint finalExpire) = sc_handle.getAffiliatePositionP24R(_addr, num);

      if (finalExpire > 0 && expireTime > finalExpire) {
        uint period = 0;

        while (expireTime > finalExpire) {
          period += 1;
          finalExpire += PERIOD;
        }

        level[num] = period;
      }
    }

    return level;
  }

  function calculateCost(uint[] memory _level) internal view returns (uint, uint) {
    uint fee = 0;
    uint cost = 0;

    for (uint num=1;num < _level.length;num++) {
      if (_level[num] > 0) {
        fee += levelCost[num].fee * _level[num];
        cost += levelCost[num].cost * _level[num];
      }
    }

    return (cost, fee);
  }

  function getSubscription(address _addr, uint _level) external view returns (uint, uint, uint) {
    return (members[_addr].level[_level].periodPaid, members[_addr].level[_level].nextPayment, members[_addr].level[_level].paidUntil);
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

//SourceUnit: SmartChoiceABI.sol

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

contract SmartChoiceABI {
  
  function members(address) external view returns (uint, address);

  function processRecurring(address, uint) external payable;

  function setupRecurring(address, uint, uint) external;

  function getAffiliatePositionP24R(address, uint) external view returns (uint, address, uint, uint);
}