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

//SourceUnit: VelocityHandler.sol

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

contract VelocityHandler is DataStorage, Access, Events {

  constructor(address _addr) public {
    owner = msg.sender;
    failedReceiver = _addr;

    reentryStatus = ENTRY_ENABLED;
    payoutEnabled = false;
    contractEnabled = false;
  }
  
  function init(address _payoutHandler, VelocityABI _velocityABI, address _velocityContract, uint _periodForSetup, uint _periodForLimit, uint _percentage) external isOwner(msg.sender) {
    require(payoutPeriodSetup == 0, "Already initiated!");
    
    v_handle = _velocityABI;
    payoutHandler = _payoutHandler;
    velocityContract = _velocityContract;
    
    payoutPeriodSetup = _periodForSetup;
    payoutPeriodLimit = _periodForLimit;

    payoutId = 1;
    handlerCommissionPercentage = _percentage;
  }

  function tiePackage(address _addr, address _sponsor, uint _package, uint _amount) external isVelocity(msg.sender) blockReEntry() returns (bool) {
    require(contractEnabled == true, "Closed For Maintenance");

    orderId++;

    HandlerAccount storage account = accounts[_addr];

    uint firstPayout = payoutId.add(payoutPeriodSetup);

    if (account.timestamp == 0) {
      account.timestamp = block.timestamp;
      account.amount = 0;
      account.payoutLast = firstPayout.sub(1);
      account.payoutClaimedTo = 0;
      account.sponsor = _sponsor;
    }
    
    account.packageTo = _package;
    account.package[_package] = Package({timestamp: block.timestamp, amount: _amount, payoutFrom: firstPayout});

    placedPayout[firstPayout] = placedPayout[firstPayout].add(_amount);

    emit GrowthRegistration(_addr, firstPayout, _package, _amount, orderId);

    return true;
  }

  function claimPayout() external hasPayout(msg.sender) blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");
    require(payoutEnabled == true, "Payout Closed");

    orderId++;

    Payout[] memory payout = calculatePayout(msg.sender);

    for (uint num=0;num < payout.length;num++) {
      if (payout[num].amount > 0) {
        (bool success, ) = address(uint160(payout[num].receiver)).call{ value: payout[num].amount, gas: 20000 }("");

        if (success == false) { //Failsafe to prevent malicious contracts from blocking
          (success, ) = address(uint160(failedReceiver)).call{ value: payout[num].amount, gas: 20000 }("");
          require(success, 'Transfer Failed');
        }
      }
    }
  }

  function checkForUnclaimedPayout(address _addr) internal {
    HandlerAccount storage account = accounts[_addr];

    uint claimedTo = account.payoutClaimedTo;
    uint packageTo = account.packageTo;

    if (claimedTo == packageTo) {
      return;
    }

    for (uint num=(claimedTo+1);num <= packageTo;num++) {
      
      if (account.package[num].payoutFrom <= payoutId) {
        account.payoutClaimedTo = num;
        account.amount = account.amount.add(account.package[num].amount);
      }
    }
  }

  function calculatePayout(address _addr) internal returns (Payout[] memory) {
    checkForUnclaimedPayout(_addr);

    Payout[] memory payout = new Payout[](2);

    uint totalAmount = 0;

    HandlerAccount storage account = accounts[_addr];

    for (uint i=(account.payoutLast+1);i <= payoutId;i++) {
      totalAmount = totalAmount.add(account.amount.mul(handlerPayout[i].valueOne));
    }

    totalAmount = totalAmount.div(MULTIPLIER);

    uint commission = totalAmount.div(100).mul(handlerCommissionPercentage);
    uint payoutAmount = totalAmount.sub(commission);

    require(payoutAmount > 0, "No pending payout");

    account.payoutLast = payoutId;
    
    payout = reviewPayout(_addr, payoutAmount, payout);
    payout = reviewPayout(v_handle.getPayoutAddress(account.sponsor), commission, payout);

    emit PayoutTier(account.sponsor, _addr, commission, orderId);
    emit PayoutPackage(_addr, payoutId, payoutAmount, orderId);
  
    return payout;
  }

  function reviewPayout(address _addr, uint _amount, Payout[] memory _payout) internal pure returns (Payout[] memory) {

    for (uint i=0;i < _payout.length;i++) {
      if (_addr == _payout[i].receiver) {
        _payout[i].amount = _payout[i].amount.add(_amount);
        break;
      } else if (_payout[i].amount == 0) {
        _payout[i] = Payout({receiver: _addr, amount: _amount});
        break;
      }
    }

    return _payout;
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

  function createPayout() external payable canInitiatePayout(msg.sender) blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");
    require(block.timestamp > (handlerPayout[payoutId].timestamp + payoutPeriodLimit), "Payout initiated too early");

    if (msg.value == 0 && handlerPayout[payoutId].timestamp == 0) {
      payoutId++;
      return;
    } else {
      require(msg.value > 0, "Payout needs to contain an amount");
    }

    orderId++;
    payoutId++;

    placedTotal = placedTotal.add(placedPayout[payoutId]);
    
    uint valueOne = msg.value.mul(MULTIPLIER).div(placedTotal);

    handlerPayout[payoutId] = PayoutInstance({amount: msg.value.mul(MULTIPLIER), valueOne: valueOne, timestamp: block.timestamp});

    emit HandlerPayout(payoutId, msg.value, valueOne, orderId);
  }

  function setCommissionPercentage(uint _percentage) external isOwner(msg.sender) {
    require(_percentage > 0 && _percentage < 100, "Invalid percentage");

    handlerCommissionPercentage = _percentage;
  }

  function changeContractStatus() external isOwner(msg.sender) {
    contractEnabled = !contractEnabled;
  }

  function changePayoutStatus() external isOwner(msg.sender) {
    payoutEnabled = !payoutEnabled;
  }

  function setPayoutPeriodForSetup(uint _period) external isOwner(msg.sender) {
    payoutPeriodSetup = _period;
  }

  function setPayoutPeriodForLimit(uint _period) external isOwner(msg.sender) {
    payoutPeriodLimit = _period;
  }

  function setFailedHandler(address _addr) external isOwner(msg.sender) {
    failedReceiver = _addr;
  }

  function setVelocityHandler(VelocityABI _addr) external isOwner(msg.sender) {
    v_handle = _addr;
  }

  function setVelocityContract(address _addr) external isOwner(msg.sender) {
    velocityContract = _addr;
  }

  function setPayoutHandler(address _addr) external isOwner(msg.sender) {
    payoutHandler = _addr;
  }
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