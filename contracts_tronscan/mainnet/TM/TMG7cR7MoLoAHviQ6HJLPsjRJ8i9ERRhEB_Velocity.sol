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

//SourceUnit: Velocity.sol

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

contract Velocity is DataStorage, Access, Events {

  constructor(address _addr) public {
    owner = msg.sender;
    forfeitHandler = _addr;

    reentryStatus = ENTRY_ENABLED;
    contractEnabled = false;
  }

  function init(address _addr) external isOwner(msg.sender) {
    require(topLevel == 0, "Already initiated!");

    uint[] memory unilevel = new uint[](7);
    unilevel[0] = 40 trx;
    unilevel[1] = 20 trx;
    unilevel[2] = 20 trx;
    unilevel[3] = 40 trx;
    unilevel[4] = 20 trx;
    unilevel[5] = 20 trx;
    unilevel[6] = 40 trx;

    levelCost[1] = Level({cost: 1000 trx, direct: 50 trx, matrix: 100 trx, unilevel: unilevel, system: 650 trx, transfer: 550 trx});
    topLevel = 1;

    createAccount(_addr, true);
    createPosition(_addr, _addr, 1, true);
  }

  fallback() external payable blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");

    preRegistration(msg.sender);
  }

  receive() external payable blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");

    preRegistration(msg.sender);
  }

  function registration() external payable blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");

    preRegistration(msg.sender);
  }

  function preRegistration(address _addr) internal {
    require(levelCost[1].cost == msg.value, "Check price point!");

    address sponsor = createAccount(_addr, false);

    createPosition(_addr, sponsor, 1, false);

    handleTransfer(_addr, sponsor, 1);
    handlePayout(_addr, sponsor, sponsor, 1, true);
  }

  function createAccount(address _addr, bool _initial) internal returns (address) {
    require(members[_addr].id == 0, "Already a member!");

    //Get the member details from LionShare contract
    (uint memberId, address sponsor) = ls_handle.members(_addr);

    require(memberId != 0, "Lions Share account required!");

    address activeSponsor = (_initial == false)?findActiveSponsor(_addr, sponsor, 1, true):sponsor;

    orderId++;

    members[_addr] = Account({id: memberId, sponsor: activeSponsor, payoutTo: _addr, activeLevel: 0});
    idToMember[memberId] = _addr;
    
    emit Registration(_addr, memberId, activeSponsor, orderId);

    return activeSponsor;
  }

  function purchaseLevel(uint _level) external payable isMember(msg.sender) blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");
    
    handleLevelPurchase(msg.sender, _level);
  }

  function handleLevelPurchase(address _addr, uint _level) internal {
    require((members[_addr].activeLevel > 0), "Need active account.");
    require((_level > 0 && _level <= topLevel), "Invalid level.");

    uint activeLevel = members[_addr].activeLevel;

    require((activeLevel < _level), "Already active at level!");
    require((activeLevel == (_level - 1)), "Level upgrade req. in order!");
    require((msg.value == levelCost[_level].cost), "Check price point!");    

    address sponsor = members[_addr].sponsor;
    address activeSponsor = findActiveSponsor(_addr, sponsor, _level, true);

    orderId++;

    emit Upgrade(_addr, activeSponsor, _level, orderId);

    createPosition(_addr, activeSponsor, _level, false);

    handleTransfer(_addr, activeSponsor, _level);
    handlePayout(_addr, sponsor, activeSponsor, _level, true);
  }

  function findActiveSponsor(address _addr, address _sponsor, uint _level, bool _emit) internal returns (address) {
    address sponsorAddress = _sponsor;
    uint memberId;

    while (true) {
      if (members[sponsorAddress].activeLevel >= _level) {
        return sponsorAddress;
      }

      if (_emit == true) {
        emit FundsPassup(sponsorAddress, _addr, _level, orderId);
      }

      if (members[sponsorAddress].activeLevel >= _level) {
        sponsorAddress = members[sponsorAddress].x22Positions[_level].sponsor;
      } else if (members[sponsorAddress].id > 0) {
        sponsorAddress = members[sponsorAddress].sponsor;
      } else {
        (memberId, sponsorAddress) = ls_handle.members(sponsorAddress);

        if (memberId == 0) {
          sponsorAddress = idToMember[1];
        }
      }
    }
  }

  function createPosition(address _addr, address _sponsor, uint _level, bool _initial) internal {
    Account storage member = members[_addr];
    
    uint matrixNum = (_initial == false)?members[_sponsor].x22Positions[_level].matrixNum:1;
    
    member.activeLevel = _level;

    Matrix storage position = member.x22Positions[_level];

    position.passup = 0;
    position.cycle = 0;
    position.reEntryCheck = 0;
    position.placementSide = 0;
    position.matrixNum = matrixNum;
    position.sponsor = _sponsor;
    position.placementFirstLevel =  new address[](0);
    position.placementLastLevel = 0;
    position.placedUnder[matrixNum] = _sponsor;

    if (_initial == true) {
      return;
    } else if (member.sponsor != _sponsor) {
      member.x22Positions[_level].reEntryCheck = 1;
    }

    sponsorPlace(_addr, _sponsor, _level, false);
  }

  function sponsorPlace(address _addr, address _sponsor, uint _level, bool passup) internal {
    Matrix storage member = members[_addr].x22Positions[_level];
    Matrix storage position = members[_sponsor].x22Positions[_level];

    if (position.placementFirstLevel.length < 2) {
      if (position.placementFirstLevel.length == 0) {
        member.placementSide = 1;
      } else {
        member.placementSide = 2;
      }
      
      member.placedUnder[member.matrixNum] = _sponsor;

      if (_sponsor != idToMember[1]) {
        position.passup++;
      }
    } else {

      if ((position.placementLastLevel & 1) == 0) {
        member.placementSide = 1;
        member.placedUnder[member.matrixNum] = position.placementFirstLevel[0];
        position.placementLastLevel += 1;
      } else if ((position.placementLastLevel & 2) == 0) {
        member.placementSide = 2;
        member.placedUnder[member.matrixNum] = position.placementFirstLevel[0];
        position.placementLastLevel += 2;
      } else if ((position.placementLastLevel & 4) == 0) {
        member.placementSide = 1;
        member.placedUnder[member.matrixNum] = position.placementFirstLevel[1];
        position.placementLastLevel += 4;
      } else {
        member.placementSide = 2;
        member.placedUnder[member.matrixNum] = position.placementFirstLevel[1];
        position.placementLastLevel += 8;
      }

      if (member.placedUnder[member.matrixNum] != idToMember[1]) {
        members[member.placedUnder[member.matrixNum]].x22Positions[_level].placementFirstLevel.push(_addr);
      }
    }

    emit Placement(_addr, _sponsor, _level, member.placedUnder[member.matrixNum], member.placementSide, passup, orderId); 
 
    if (position.placementFirstLevel.length < 2) {
      position.placementFirstLevel.push(_addr);

      positionPlaceLastLevel(_addr, _sponsor, position.placedUnder[member.matrixNum], position.placementSide, _level);
    }

    if ((position.placementLastLevel & 15) == 15) {
      emit Cycle(_sponsor, _addr, _level, orderId);

      position.placementFirstLevel = new address[](0);
      position.placementLastLevel = 0;

      if (_sponsor == idToMember[1]) {
        position.matrixNum++;
      } else {
        position.cycle++;

        sponsorPlace(_sponsor, position.sponsor, _level, true);
      }
    }
  }

  function positionPlaceLastLevel(address _addr, address _sponsor, address _position, uint8 _placementSide, uint _level) internal {
    Matrix storage position = members[_position].x22Positions[_level];

    if (position.placementSide == 0 && _sponsor == idToMember[1]) {
      return;
    }

    if (_placementSide == 1) {
      if ((position.placementLastLevel & 1) == 0) {
        position.placementLastLevel += 1;
      } else {
        position.placementLastLevel += 2;
      }
    } else {
      if ((position.placementLastLevel & 4) == 0) {
        position.placementLastLevel += 4;
      } else {
        position.placementLastLevel += 8;
      }
    }

    if ((position.placementLastLevel & 15) == 15) {
      emit Cycle(_position, _addr, _level, orderId);

      position.placementFirstLevel = new address[](0);
      position.placementLastLevel = 0;

      if (_position == idToMember[1]) {
        position.matrixNum++;
      } else {
        position.cycle++;

        sponsorPlace(_position, position.sponsor, _level, true);
      }
    }
  }

  function handleReEntry(address _addr, uint _level) internal {
    Matrix storage member = members[_addr].x22Positions[_level];
    bool reentry = false;

    member.reEntryCheck++;

    if (member.reEntryCheck >= REENTRY_REQ) {
      address sponsor = members[_addr].sponsor;

      if (members[sponsor].activeLevel >= _level) {
        member.reEntryCheck = 0;
        member.sponsor = sponsor;
        reentry = true;
      } else {
        address active_sponsor = findActiveSponsor(_addr, sponsor, _level, false);

        if (member.sponsor != active_sponsor && members[active_sponsor].activeLevel >= _level) {
          member.sponsor = active_sponsor;
          reentry = true;
        }
      }

      if (reentry == true) {
        emit PlacementReEntry(member.sponsor, _addr, _level, orderId);
      }
    }
  }

  function locateDirectPayout(address _addr, address _directSponsor, uint _level, Payout[] memory _payout) internal returns (Payout[] memory) {    
    uint amount = levelCost[_level].direct;

    emit CommissionTier(_directSponsor, _addr, _level, amount, orderId);

    return reviewPayout(members[_directSponsor].payoutTo, amount, _payout);
  }

  function locateMatrixPayout(address _addr, address _activeSponsor, uint _level, Payout[] memory _payout) internal returns (Payout[] memory) {    
    address from;
    address receiver = _activeSponsor;
    uint amount = levelCost[_level].matrix;
    
    while (true) {
      Matrix storage member = members[receiver].x22Positions[_level];

      if (member.passup == 0 && member.cycle == 0) {
        break;
      }

      if (member.passup > 0) {
        member.passup = 0;
        receiver = member.placedUnder[member.matrixNum];
      } else {
        member.cycle = 0;
        from = receiver;
        receiver = member.sponsor;

        if (_level > 1 && member.reEntryCheck > 0) {
          handleReEntry(from, _level);
        }
      }
    }
   
    emit CommissionMatrix(receiver, _addr, _level, amount, orderId);
  
    return reviewPayout(members[receiver].payoutTo, amount, _payout);
  }

  function locateUnilevelPayout(address _addr, address _activeSponsor, uint _level, uint _matrixNum, Payout[] memory _payout) internal returns (Payout[] memory) {
    address receiver = _activeSponsor;
    
    uint[] memory commission = levelCost[_level].unilevel;
    
    uint amount;

    for (uint i=0;i < commission.length;i++) {
      amount = commission[i];

      receiver = members[receiver].x22Positions[_level].placedUnder[_matrixNum];
        
      _payout = reviewPayout(members[receiver].payoutTo, amount, _payout);
 
      emit CommissionUnilevel(receiver, _addr, _level, (i+1), amount, orderId);
    }

    return _payout;
  }

  function handlePayout(address _addr, address _sponsor, address _activeSponsor, uint _level, bool _transferPayout) internal {
    Payout[] memory payout = new Payout[](levelCost[_level].unilevel.length + 3);

    payout = locateDirectPayout(_addr, _sponsor, _level, payout);
    payout = locateMatrixPayout(_addr, _activeSponsor, _level, payout);
    payout = locateUnilevelPayout(_addr, _activeSponsor, _level, members[_addr].x22Positions[_level].matrixNum, payout);

    if (_transferPayout == false) {
      return;
    }

    if (levelCost[_level].system > 0) {
      payout = reviewPayout(systemReceiver, levelCost[_level].system, payout);
    }

    for (uint num=0;num < payout.length;num++) {
      if (payout[num].amount > 0) {
        (bool success, ) = address(uint160(payout[num].receiver)).call{ value: payout[num].amount, gas: 40000 }("");

        if (success == false) { //Failsafe to prevent malicious contracts from blocking
          (success, ) = address(uint160(failedReceiver)).call{ value: payout[num].amount, gas: 40000 }("");
          require(success, 'Transfer Failed');
        }
      }
    }
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

  function handleTransfer(address _addr, address _sponsor, uint _level) internal {
    if (levelCost[_level].transfer == 0) {
      return;
    }

    bool success = vh_handle.tiePackage(_addr, _sponsor, _level, levelCost[_level].transfer);

    require(success, 'Transfer Failed');
  }

  function getPayoutAddress(address _addr) external view returns (address) {
    return members[_addr].payoutTo;
  }

  function setupAccount(address _addr) external payable isSystem(msg.sender) blockReEntry() {
    preRegistration(_addr);
  }

  function setupLevel(address _addr, uint _level) external payable isSystem(msg.sender) blockReEntry() {
    handleLevelPurchase(_addr, _level);
  }
  
  function compAccount(address _addr, uint _level) external isOwner(msg.sender) {
    createAccount(_addr, false);
    processCompLevel(_addr, _level);
  }

  function compLevel(address _addr, uint _level) external isOwner(msg.sender) isMember(_addr) {
    orderId++;

    processCompLevel(_addr, _level);
  }

  function processCompLevel(address _addr, uint _level) internal {
    require((_level > 0 && _level <= topLevel), "Invalid level.");

    uint activeLevel = members[_addr].activeLevel;
    address sponsor = members[_addr].sponsor;

    require((activeLevel < _level), "Already active at level!");

    for (uint num = (activeLevel+1);num <= _level;num++) {
      address activeSponsor = findActiveSponsor(_addr, sponsor, num, true);

      emit Upgrade(_addr, activeSponsor, num, orderId);

      createPosition(_addr, activeSponsor, num, false);
      handlePayout(_addr, sponsor, activeSponsor, num, false);
    }
  }

  function addLevel(uint _price, uint _direct, uint _matrix, uint[] calldata _unilevel, uint _system, uint _transfer) external isOwner(msg.sender) {
    require((levelCost[topLevel].cost < _price), "Check price point!");
    uint commission = _direct + _matrix;

    for (uint i=0;i < _unilevel.length;i++) {
      commission += _unilevel[i];
    }

    require((commission + _system) == _price, "Check price point!");
    require(_system >= _transfer, "Check price point!");

    topLevel++;

    levelCost[topLevel] = Level({cost: _price, direct: _direct, matrix: _matrix, unilevel: _unilevel, system: _system, transfer: _transfer});

    createPosition(idToMember[1], idToMember[1], topLevel, true);
  }

  function updateLevelCost(uint _level, uint _price, uint _direct, uint _matrix, uint[] calldata _unilevel, uint _system, uint _transfer) external isOwner(msg.sender) {
    require((_level > 0 && _level <= topLevel), "Invalid level.");
    require((_price > 0), "Check price point!");
    uint commission = _direct + _matrix;

    for (uint i=0;i < _unilevel.length;i++) {
      commission += _unilevel[i];
    }

    require((commission + _system) == _price, "Check price point!");
    require(_system >= _transfer, "Check price point!");

    if (_level > 1) {
      require((levelCost[(_level - 1)].cost < _price), "Check price point!");
    }

    if (_level < topLevel) {
      require((levelCost[(_level + 1)].cost > _price), "Check price point!");
    }

    levelCost[_level] = Level({cost: _price, direct: _direct, matrix: _matrix, unilevel: _unilevel, system: _system, transfer: _transfer});
  }

  function handleForfeitedBalance(address payable _addr) external {
    require((msg.sender == owner || msg.sender == forfeitHandler), "Restricted Access!");
    
    (bool success, ) = _addr.call{value: address(this).balance}("");

    require(success, 'Failed');
  }

  function changeContractStatus() external isOwner(msg.sender) {
    contractEnabled = !contractEnabled;
    }

  function setForfeithHandler(address _addr) external isOwner(msg.sender) {
    forfeitHandler = _addr;
  }

  function setSystemHandler(address _addr) external isOwner(msg.sender) {
    systemHandler = _addr;
  }

  function setSystemReceiver(address _addr) external isOwner(msg.sender) {
    systemReceiver = _addr;
  }

  function setLionShareContract(LionShareABI _addr) external isOwner(msg.sender) {
    ls_handle = _addr;
  }

  function setVelocityContract(VelocityHandlerABI _addr) external isOwner(msg.sender) {
    vh_handle = _addr;
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