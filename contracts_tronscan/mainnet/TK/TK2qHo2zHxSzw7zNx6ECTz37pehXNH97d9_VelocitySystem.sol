//SourceUnit: VelocityHandlerABI.sol

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                                                                                  
*       ##### /           #######                    ##### /      ##       ##### ##       ##### /          # ###          # ###           #####  # /###           /   ##### /    ##   
*    ######  /          /       ###               ######  /    #####    ######  /### / ######  /         /  /###        /  /###  /     ######  /  /  ############/ ######  /  #####   
*   /#   /  /          /         ##              /#   /  /       ##### /#   /  / ###/ /#   /  /         /  /  ###      /  /  ###/     /#   /  /  /     #########  /#   /  /     ##### 
*  /    /  /           ##        #              /    /  ##       / ## /    /  /   ## /    /  /         /  ##   ###    /  ##   ##     /    /  /   #     /  #      /    /  ##     # ##  
*      /  /             ###                         /  ###      /         /  /           /  /         /  ###    ###  /  ###              /  /     ##  /  ##          /  ###     #     
*     ## ##            ## ###                      ##   ##      #        ## ##          ## ##        ##   ##     ## ##   ##             ## ##        /  ###         ##   ##     #     
*     ## ##             ### ###                    ##   ##      /        ## ##          ## ##        ##   ##     ## ##   ##             ## ##       ##   ##         ##   ##     #     
*     ## ##               ### ###                  ##   ##     /         ## ######      ## ##        ##   ##     ## ##   ##           /### ##       ##   ##         ##   ##     #     
*     ## ##                 ### /##                ##   ##     #         ## #####       ## ##        ##   ##     ## ##   ##          / ### ##       ##   ##         ##   ##     #     
*     ## ##                   #/ /##               ##   ##     /         ## ##          ## ##        ##   ##     ## ##   ##             ## ##       ##   ##         ##   ##     #     
*     #  ##                    #/ ##                ##  ##    /          #  ##          #  ##         ##  ##     ##  ##  ##        ##   ## ##        ##  ##          ##  ##     #     
*        /                      # /                  ## #     #             /              /           ## #      /    ## #      / ###   #  /          ## #      /     ## #      #     
*    /##/           / /##        /        #           ###     /         /##/         / /##/           / ###     /      ###     /   ###    /            ###     /       ###      #     
*   /  ############/ /  ########/        ###           ######/         /  ##########/ /  ############/   ######/        ######/     #####/              ######/         #########     
*  /     #########  /     #####           #              ###          /     ######   /     #########       ###            ###         ###                 ###             #### ###    
*  #                |                                                 #              #                                                                                          ###   
*   ##               \)                                                ##             ##                                                                            ########     ###  
*                                                                                                                                                                 /############  /#   
*                                                                                                                                                                /           ###/
* Lion's Share is the very first true follow-me matrix smart contract ever created.
* With Velocity we have now made history again by creating a first of a kind hybrid unilevel.
* https://www.lionsshare.io
* Get your share, join today!
*/

pragma solidity 0.6.12;

abstract contract VelocityHandlerABI {

  function tiePackage(address, address, uint, uint) external virtual returns (bool);

  function createPayout() external virtual payable;
}

//SourceUnit: VelocitySystem.sol

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import './VelocityHandlerABI.sol';

contract VelocitySystem {
  VelocityHandlerABI internal vh_handle;

  address internal owner;
  address internal payoutHandler;

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal reentry_status;

  modifier isOwner(address _addr) {
    require(owner == _addr, "Restricted Access!");
    _;
  }

  modifier isPayoutHandler(address _addr) {
    require(owner == _addr || payoutHandler == _addr, "Restricted Access!");
    _;
  }

  modifier blockReEntry() {
    require(reentry_status != ENTRY_DISABLED, "Security Block");
    reentry_status = ENTRY_DISABLED;

    _;

    reentry_status = ENTRY_ENABLED;
  }

  constructor(VelocityHandlerABI _addr) public {
    reentry_status = ENTRY_ENABLED;

    owner = msg.sender;
    vh_handle = _addr;
  }

  fallback() external payable blockReEntry() {
  }

  receive() external payable blockReEntry() {
  }
  
  function getSystemBalance() external view isPayoutHandler(msg.sender) returns (uint) {
    return address(this).balance;
  }
  
  function initiatePayout() external payable isPayoutHandler(msg.sender) blockReEntry() {
    vh_handle.createPayout{value:address(this).balance}();
  }

  function setPayoutHandler(address _addr) external isOwner(msg.sender) {
    payoutHandler = _addr;
  }
}