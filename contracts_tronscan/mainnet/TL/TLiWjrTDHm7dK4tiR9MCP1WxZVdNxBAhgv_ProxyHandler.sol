//SourceUnit: Access.sol

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

  modifier isSystem(address _addr) {
    require(systemHandler == _addr, "Restricted Access!");
    _;
  }

  modifier hasPayout(address _addr) {
    require(accounts[_addr].timestamp > 0, "Register Account First!");
    _;
  }

  modifier canInitiatePayout(address _addr) {
    require(payoutHandler == _addr, "Restricted Access!");
    _;
  }

  modifier isVelocity(address _addr) {
    require(velocityContract == _addr, "Restricted Access!");
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

import './SafeMath.sol';
import './LionShareABI.sol'; 
import './VelocityABI.sol';
import './VelocityHandlerABI.sol';

contract DataStorage {
  using SafeMath for uint256;  

  LionShareABI internal ls_handle;
  VelocityABI internal v_handle;
  VelocityHandlerABI internal vh_handle;

  struct Account {
    uint id;
    uint activeLevel;
    address sponsor;
    address payoutTo;
    mapping(uint => Matrix) x22Positions;
  }

  struct HandlerAccount {  
    uint timestamp;
    uint amount;
    uint payoutLast;
    uint packageTo;
    uint payoutClaimedTo;
    address sponsor;
    mapping(uint => Package) package;
  }

  struct Matrix {
    uint8 passup;
    uint8 cycle;
    uint8 reEntryCheck;
    uint8 placementLastLevel;
    uint8 placementSide;
    uint matrixNum;
    address sponsor;
    address[] placementFirstLevel;
    mapping(uint => address) placedUnder;
  }

  struct Payout {
    uint amount;
    address receiver;
  }

  struct PayoutInstance {
    uint timestamp;
    uint amount;
    uint valueOne;
  }

  struct Level {
    uint cost;
    uint direct;
    uint matrix;
    uint[] unilevel;
    uint transfer;
    uint system;
  }

  struct Package {
    uint timestamp;
    uint amount;
    uint payoutFrom;
  }

  mapping(uint => Level) public levelCost;
  mapping(uint => uint) public placedPayout;
  mapping(address => Account) public members;
  mapping(uint => address) public idToMember;
  mapping(address => HandlerAccount) public accounts;
  mapping(uint => PayoutInstance) public handlerPayout;

  uint internal constant MULTIPLIER = 1000000;
  uint internal constant REENTRY_REQ = 2;

  uint public orderId;
  uint public payoutId;
  uint public topLevel;
  uint public placedTotal;
  uint public payoutPeriodSetup;
  uint public payoutPeriodLimit;
  uint public handlerCommissionPercentage;
  bool public payoutEnabled;
  bool public contractEnabled;
  address internal owner;
  address internal payoutHandler;
  address internal systemHandler;
  address internal forfeitHandler;
  address internal failedReceiver;
  address internal systemReceiver;
  address internal velocityContract;
  address internal proxied;
}

//SourceUnit: Events.sol

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

contract Events {
  event Registration(address member, uint memberId, address sponsor, uint orderId);
  event Upgrade(address member, address sponsor, uint level, uint orderId);
  
  event Placement(address member, address sponsor, uint level, address placedUnder, uint8 placementSide, bool passup, uint orderId);
  event PlacementReEntry(address indexed member, address reEntryFrom, uint level, uint orderId);

  event Cycle(address indexed member, address fromPosition, uint level, uint orderId);

  event FundsPassup(address indexed member, address passupFrom, uint level, uint orderId);

  event CommissionTier(address indexed member, address payoutFrom, uint level, uint amount, uint orderId);
  event CommissionMatrix(address indexed member, address payoutFrom, uint level, uint amount, uint orderId);
  event CommissionUnilevel(address indexed member, address payoutFrom, uint level, uint tier, uint amount, uint orderId);

  event GrowthRegistration(address member, uint payoutId, uint package, uint amount, uint orderId);
  event HandlerPayout(uint payoutId, uint amount, uint valueOne, uint orderId);

  event PayoutTier(address indexed member, address payoutFrom, uint amount, uint orderId);
  event PayoutPackage(address indexed member, uint payoutId, uint amount, uint orderId);
}

//SourceUnit: LionShareABI.sol

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

abstract contract LionShareABI {

  function members(address) external view virtual returns (uint, address);
}

//SourceUnit: ProxyHandler.sol

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

import './DataStorage.sol';
import './Access.sol';
import './Events.sol';

contract ProxyHandler is DataStorage, Access, Events {
  
  constructor(address _proxied, address _failedReceiver) public {
    owner = msg.sender;
    proxied = _proxied;
    failedReceiver = _failedReceiver;

    reentryStatus = ENTRY_ENABLED;
    payoutEnabled = false;
    contractEnabled = false;
  }

  fallback() external payable {
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

  receive() external payable {
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

  function getTotal(address _addr) external view returns (uint) {
    return accounts[_addr].amount.add(getUnclaimedPayout(_addr));
  }

  function getTotalByPackage(address _addr, uint _package) external view returns (uint) {
    return accounts[_addr].package[_package].amount;
  }

  function getPendingPayout(address _addr) external view returns (uint) {  
    uint totalAmount = 0;
    
    HandlerAccount memory account = accounts[_addr];

    uint amount = account.amount.add(getUnclaimedPayout(_addr));

    for (uint i=(account.payoutLast + 1);i <= payoutId;i++) {
      totalAmount = totalAmount.add(amount.mul(handlerPayout[i].valueOne));
    }
  
    totalAmount = totalAmount.div(MULTIPLIER);

    uint commission = totalAmount.div(100).mul(handlerCommissionPercentage);
    
    return totalAmount.sub(commission);
  }

  function getUnclaimedPayout(address _addr) internal view returns (uint) {
    HandlerAccount memory account = accounts[_addr];

    uint amount = 0;
    uint claimedTo = account.payoutClaimedTo;
    uint packageTo = account.packageTo;

    if (claimedTo == packageTo) {
      return 0;
    }

    for (uint num=(claimedTo+1);num <= packageTo;num++) {
      amount = amount.add(accounts[_addr].package[num].amount);
    }
    
    return amount;
  }

  function setProxy(address _addr) external isOwner(msg.sender) {
    proxied = _addr;
  }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: VelocityABI.sol

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

abstract contract VelocityABI {

  function getPayoutAddress(address) external view virtual returns (address);
}

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