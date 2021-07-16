//SourceUnit: LionShare.sol

/** 
*                                                                                                                                  
*       ##### /                                                             #######      /                                         
*    ######  /          #                                                 /       ###  #/                                          
*   /#   /  /          ###                                               /         ##  ##                                          
*  /    /  /            #                                                ##        #   ##                                          
*      /  /                                                               ###          ##                                          
*     ## ##           ###        /###    ###  /###         /###          ## ###        ##  /##      /###    ###  /###       /##    
*     ## ##            ###      / ###  /  ###/ #### /     / #### /        ### ###      ## / ###    / ###  /  ###/ #### /   / ###   
*     ## ##             ##     /   ###/    ##   ###/     ##  ###/           ### ###    ##/   ###  /   ###/    ##   ###/   /   ###  
*     ## ##             ##    ##    ##     ##    ##   k ####                  ### /##  ##     ## ##    ##     ##         ##    ### 
*     ## ##             ##    ##    ##     ##    ##   a   ###                   #/ /## ##     ## ##    ##     ##         ########  
*     #  ##             ##    ##    ##     ##    ##   i     ###                  #/ ## ##     ## ##    ##     ##         #######   
*        /              ##    ##    ##     ##    ##   z       ###                 # /  ##     ## ##    ##     ##         ##        
*    /##/           /   ##    ##    ##     ##    ##   e  /###  ##       /##        /   ##     ## ##    /#     ##         ####    / 
*   /  ############/    ### /  ######      ###   ###  n / #### /       /  ########/    ##     ##  ####/ ##    ###         ######/  
*  /     #########       ##/    ####        ###   ### -    ###/       /     #####       ##    ##   ###   ##    ###         #####   
*  #                                                  w               |                       /                                    
*   ##                                                e                \)                    /                                     
*                                                     b                                     /                                      
*                                                                                          /                                       
*
*
* Lion's Share's is the very first true follow-me matrix smart contract ever created.
* https://www.lionsshares.io
* Get your share, join today!
*/

pragma solidity 0.5.9;

contract LionShare {

  struct Account {
    uint id;
    uint[] activeLevel;
    address sponsor;
    mapping(uint => L1) x31Positions;
    mapping(uint => L2) x22Positions;
  }

  struct L1 {
    uint8 passup;
    uint8 reEntryCheck;
    uint8 placement;
    address sponsor;
  }

  struct L2 {
    uint8 passup;
    uint8 cycle;
    uint8 reEntryCheck;
    uint8 placementLastLevel;
    uint8 placementSide;
    address sponsor;
    address placedUnder;
    address[] placementFirstLevel;
  }

  struct Level {
    uint cost;
    uint commission;
    uint fee;
  }

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;
  uint internal constant REENTRY_REQ = 2;

  mapping(address => Account) public members;
  mapping(uint => address) public idToMember;
  mapping(uint => Level) public levelCost;
  
  uint internal reentryStatus;
  uint public lastId;
  uint public orderId;
  uint public topLevel;
  bool public contractEnabled;
  address internal owner;
  address internal holder;
  address internal feeSystem;

  event Registration(address member, uint memberId, address sponsor, uint orderId);
  event Upgrade(address member, address sponsor, uint matrix, uint level, uint orderId);
  event PlacementL1(address member, address sponsor, uint level, uint8 placement, bool passup, uint orderId);
  event PlacementL2(address member, address sponsor, uint level, address placedUnder, uint8 placementSide, bool passup, uint orderId);
  event Cycle(address indexed member, address fromPosition, uint matrix, uint level, uint orderId);
  event PlacementReEntry(address indexed member, address reEntryFrom, uint matrix, uint level, uint orderId);
  event FundsPayout(address indexed member, address payoutFrom, uint matrix, uint level, uint orderId);
  event FundsPassup(address indexed member, address passupFrom, uint matrix, uint level, uint orderId);

  modifier isOwner(address _account) {
    require(owner == _account, "Restricted Access!");
    _;
  }

  modifier isMember(address _addr) {
    require(members[_addr].id > 0, "Register Account First!");
    _;
  }
  
  modifier blockReEntry() {
    require(reentryStatus != ENTRY_DISABLED, "Security Block");
    reentryStatus = ENTRY_DISABLED;

    _;

    reentryStatus = ENTRY_ENABLED;
  }

  constructor(address _addr, address _holder) public {
    owner = msg.sender;
    holder = _holder;

    reentryStatus = ENTRY_ENABLED;
    contractEnabled = false;

    levelCost[1] = Level({cost: 100 trx, commission: 100 trx, fee: 0});
    topLevel = 1;

    lastId++;

    createAccount(lastId, _addr, _addr, true);
    handlePositionL1(_addr, _addr, _addr, 1, true);
    handlePositionL2(_addr, _addr, _addr, 1, true);
  }

  function() external payable blockReEntry() {
    bytes memory stringEmpty = bytes(msg.data);

    if (stringEmpty.length > 0) {
      preRegistration(msg.sender, bytesToAddress(msg.data));
    } else {
      preRegistration(msg.sender, idToMember[1]);
    }
  }

  function registration(address _sponsor) external payable blockReEntry() {
    preRegistration(msg.sender, _sponsor);
  }

  function preRegistration(address _addr, address _sponsor) internal {
    require(contractEnabled == true, "Closed For Maintenance");
    require((levelCost[1].cost * 2) == msg.value, "Require 200 trx to register!");

    lastId++;

    createAccount(lastId, _addr, _sponsor, false);
    
    handlePositionL1(_addr, _sponsor, _sponsor, 1, false);
    handlePositionL2(_addr, _sponsor, _sponsor, 1, false);
    
    handlePayout(_addr, 0, 1, true);
    handlePayout(_addr, 1, 1, true);
  }
  
  function createAccount(uint _memberId, address _addr, address _sponsor, bool _initial) internal {
    require(members[_addr].id == 0, "Already a member!");

    if (_initial == false) {
      require(members[_sponsor].id > 0, "Sponsor dont exist!");
    }

    orderId++;

    members[_addr] = Account({id: _memberId, sponsor: _sponsor, activeLevel: new uint[](2)});
    idToMember[_memberId] = _addr;
    
    emit Registration(_addr, _memberId, _sponsor, orderId);
  }

  function purchaseLevel(uint _matrix, uint _level) external payable isMember(msg.sender) blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");
    require((_matrix == 1 || _matrix == 2), "Invalid matrix identifier.");
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");

    uint activeLevel = members[msg.sender].activeLevel[(_matrix - 1)];
    uint otherMatrix = 1;

    if (_matrix == 2) {
      otherMatrix = 0;
    }

    require((activeLevel < _level), "Already active at level!");
    require((activeLevel == (_level - 1)), "Level upgrade req. in order!");
    require(((members[msg.sender].activeLevel[otherMatrix] * 2) >= _level), "Double upgrade exeeded.");
    require((msg.value == levelCost[_level].cost), "Wrong amount transferred.");
  
    orderId++;

    handleLevel(_matrix, _level);
  }

  function purchaseBundle(uint _level) external payable isMember(msg.sender) blockReEntry() {
    require(contractEnabled == true, "Closed For Maintenance");
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");

    uint activeLevel31 = members[msg.sender].activeLevel[0];
    uint activeLevel22 = members[msg.sender].activeLevel[1];
    
    require((activeLevel31 < _level || activeLevel22 < _level), "Already active at level!");

    uint amount = 0;

    for (uint num = (activeLevel31 + 1);num <= _level;num++) {
      amount += levelCost[num].cost;
    }

    for (uint num = (activeLevel22 + 1);num <= _level;num++) {
      amount += levelCost[num].cost;
    }

    require((msg.value == amount), "Wrong amount transferred.");

    orderId++;

    for (uint num = (activeLevel31 + 1);num <= _level;num++) {
      handleLevel(1, num);
    }

    for (uint num = (activeLevel22 + 1);num <= _level;num++) {
      handleLevel(2, num);
    }
  }

  function handleLevel(uint _matrix, uint _level) internal {
    address sponsor = members[msg.sender].sponsor;
    address activeSponsor = findActiveSponsor(msg.sender, sponsor, (_matrix - 1), _level, true);

    emit Upgrade(msg.sender, activeSponsor, _matrix, _level, orderId);

    if (_matrix == 1) {
      handlePositionL1(msg.sender, sponsor, activeSponsor, _level, false);
    } else {
      handlePositionL2(msg.sender, sponsor, activeSponsor, _level, false);
    }

    handlePayout(msg.sender, (_matrix - 1), _level, true);

    if (levelCost[_level].fee > 0) {
      processPayout(feeSystem, levelCost[_level].fee);
    }
  }

  function handlePositionL1(address _addr, address _mainSponsor, address _sponsor, uint _level, bool _initial) internal {
    Account storage member = members[_addr];

    member.activeLevel[0] = _level;
    member.x31Positions[_level] = L1({sponsor: _sponsor, placement: 0, passup: 0, reEntryCheck: 0});

    if (_initial == true) {
      return;
    } else if (_mainSponsor != _sponsor) {
      member.x31Positions[_level].reEntryCheck = 1;
    }
    
    sponsorPlaceL1(_addr, _sponsor, _level, false);
  }

  function sponsorPlaceL1(address _addr, address _sponsor, uint _level, bool passup) internal {
    L1 storage position = members[_sponsor].x31Positions[_level];

    emit PlacementL1(_addr, _sponsor, _level, (position.placement + 1), passup, orderId);

    if (position.placement >= 2) {
      emit Cycle(_sponsor, _addr, 1, _level, orderId);

      position.placement = 0;

      if (_sponsor != idToMember[1]) {
        position.passup++;

        sponsorPlaceL1(_sponsor, position.sponsor, _level, true);
      }
    } else {
      position.placement++;
    }
  }

  function handlePositionL2(address _addr, address _mainSponsor, address _sponsor, uint _level, bool _initial) internal {
    Account storage member = members[_addr];
    
    member.activeLevel[1] = _level;
    member.x22Positions[_level] = L2({sponsor: _sponsor, passup: 0, cycle: 0, reEntryCheck: 0, placementSide: 0, placedUnder: _sponsor, placementFirstLevel: new address[](0), placementLastLevel: 0});

    if (_initial == true) {
      return;
    } else if (_mainSponsor != _sponsor) {
      member.x22Positions[_level].reEntryCheck = 1;
    }

    sponsorPlaceL2(_addr, _sponsor, _level, false);
  }

  function sponsorPlaceL2(address _addr, address _sponsor, uint _level, bool passup) internal {
    L2 storage member = members[_addr].x22Positions[_level];
    L2 storage position = members[_sponsor].x22Positions[_level];

    if (position.placementFirstLevel.length < 2) {
      if (position.placementFirstLevel.length == 0) {
        member.placementSide = 1;
      } else {
        member.placementSide = 2;
      }
      
      member.placedUnder = _sponsor;

      if (_sponsor != idToMember[1]) {
        position.passup++;
      }
    } else {

      if ((position.placementLastLevel & 1) == 0) {
        member.placementSide = 1;
        member.placedUnder = position.placementFirstLevel[0];
        position.placementLastLevel += 1;
      } else if ((position.placementLastLevel & 2) == 0) {
        member.placementSide = 2;
        member.placedUnder = position.placementFirstLevel[0];
        position.placementLastLevel += 2;
      } else if ((position.placementLastLevel & 4) == 0) {
        member.placementSide = 1;
        member.placedUnder = position.placementFirstLevel[1];
        position.placementLastLevel += 4;
      } else {
        member.placementSide = 2;
        member.placedUnder = position.placementFirstLevel[1];
        position.placementLastLevel += 8;
      }

      if (member.placedUnder != idToMember[1]) {
        members[member.placedUnder].x22Positions[_level].placementFirstLevel.push(_addr);
      }
    }

    emit PlacementL2(_addr, _sponsor, _level, member.placedUnder, member.placementSide, passup, orderId); 
 
    if (position.placementFirstLevel.length < 2) {
      position.placementFirstLevel.push(_addr);

      positionPlaceLastLevelL2(_addr, _sponsor, position.placedUnder, position.placementSide, _level);
    }

    if ((position.placementLastLevel & 15) == 15) {
      emit Cycle(_sponsor, _addr, 2, _level, orderId);

      position.placementFirstLevel = new address[](0);
      position.placementLastLevel = 0;

      if (_sponsor != idToMember[1]) {
        position.cycle++;

        sponsorPlaceL2(_sponsor, position.sponsor, _level, true);
      }
    }
  }

  function positionPlaceLastLevelL2(address _addr, address _sponsor, address _position, uint8 _placementSide, uint _level) internal {
    L2 storage position = members[_position].x22Positions[_level];

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
      emit Cycle(_position, _addr, 2, _level, orderId);

      position.placementFirstLevel = new address[](0);
      position.placementLastLevel = 0;

      if (_position != idToMember[1]) {
        position.cycle++;

        sponsorPlaceL2(_position, position.sponsor, _level, true);
      }
    }
  }

  function findActiveSponsor(address _addr, address _sponsor, uint _matrix, uint _level, bool _emit) internal returns (address) {
    address sponsorAddress = _sponsor;

    while (true) {
      if (members[sponsorAddress].activeLevel[_matrix] >= _level) {
        return sponsorAddress;
      }

      if (_emit == true) {
        emit FundsPassup(sponsorAddress, _addr, (_matrix + 1), _level, orderId);
      }

      sponsorAddress = members[sponsorAddress].sponsor;
    }
  }

  function handleReEntryL1(address _addr, uint _level) internal {
    L1 storage member = members[_addr].x31Positions[_level];
    bool reentry = false;

    member.reEntryCheck++;

    if (member.reEntryCheck >= REENTRY_REQ) {
      address sponsor = members[_addr].sponsor;

      if (members[sponsor].activeLevel[0] >= _level) {
        member.reEntryCheck = 0;
        reentry = true;
      } else {
        sponsor = findActiveSponsor(_addr, sponsor, 0, _level, false);

        if (member.sponsor != sponsor && members[sponsor].activeLevel[0] >= _level) {
          reentry = true;
        }
      }

      if (reentry == true) {
        member.sponsor = sponsor;

        emit PlacementReEntry(sponsor, _addr, 1, _level, orderId);
      }
    }
  }

  function handleReEntryL2(address _addr, uint _level) internal {
    L2 storage member = members[_addr].x22Positions[_level];
    bool reentry = false;

    member.reEntryCheck++;

    if (member.reEntryCheck >= REENTRY_REQ) {
      address sponsor = members[_addr].sponsor;

      if (members[sponsor].activeLevel[1] >= _level) {
        member.reEntryCheck = 0;
        member.sponsor = sponsor;
        reentry = true;
      } else {
        address active_sponsor = findActiveSponsor(_addr, sponsor, 1, _level, false);

        if (member.sponsor != active_sponsor && members[active_sponsor].activeLevel[1] >= _level) {
          member.sponsor = active_sponsor;
          reentry = true;
        }
      }

      if (reentry == true) {
        emit PlacementReEntry(member.sponsor, _addr, 2, _level, orderId);
      }
    }
  }

  function findPayoutReceiver(address _addr, uint _matrix, uint _level) internal returns (address) {
    address from;
    address receiver;

    if (_matrix == 0) {
      receiver = members[_addr].x31Positions[_level].sponsor;

      while (true) {
        L1 storage member = members[receiver].x31Positions[_level];

        if (member.passup == 0) {
          return receiver;
        }

        member.passup = 0;
        from = receiver;
        receiver = member.sponsor;

        if (_level > 1 && member.reEntryCheck > 0) {
          handleReEntryL1(from, _level);
        }
      }
    } else {
      receiver = members[_addr].x22Positions[_level].sponsor;

      while (true) {
        L2 storage member = members[receiver].x22Positions[_level];

        if (member.passup == 0 && member.cycle == 0) {
          return receiver;
        }

        if (member.passup > 0) {
          member.passup = 0;
          receiver = member.placedUnder;
        } else {
          member.cycle = 0;
          from = receiver;
          receiver = member.sponsor;

          if (_level > 1 && member.reEntryCheck > 0) {
            handleReEntryL2(from, _level);
          }
        }
      }
    }
  }

  function handlePayout(address _addr, uint _matrix, uint _level, bool _transferPayout) internal {
    address receiver = findPayoutReceiver(_addr, _matrix, _level);

    emit FundsPayout(receiver, _addr, (_matrix + 1), _level, orderId);

    if (_transferPayout == true) {
      processPayout(receiver, levelCost[_level].commission);
    }
  }

  function processPayout(address _addr, uint _amount) internal {
    (bool success, ) = address(uint160(_addr)).call.gas(40000).value(_amount)("");

    if (success == false) { //Failsafe to prevent malicious contracts from blocking matrix
      (success, ) = address(uint160(idToMember[1])).call.gas(40000).value(_amount)("");
      require(success, 'Transfer Failed');
    }
  }

  function getAffiliateId() external view returns (uint) {
    return members[msg.sender].id;
  }

  function getAffiliateWallet(uint32 memberId) external view returns (address) {
    return idToMember[memberId];
  }

  function setupAccount(address _addr, address _sponsor, uint _level) external isOwner(msg.sender) {
    lastId++;

    createAccount(lastId, _addr, _sponsor, false);
    processCompLevel(_addr, 1, _level);
    processCompLevel(_addr, 2, _level);
  }

  function importAccount(uint _memberId, address _addr, address _sponsor, uint _level) external isOwner(msg.sender) {
    require(contractEnabled == false, "Require Closed For Maintenance!");
    require(idToMember[_memberId] == address(0), "Member id already exists!");

    if (_memberId > lastId) {
      lastId = _memberId;
    }

    createAccount(_memberId, _addr, _sponsor, false);
    processCompLevel(_addr, 1, _level);
    processCompLevel(_addr, 2, _level);
  }

  function compLevel(address _addr, uint _matrix, uint _level) public isOwner(msg.sender) isMember(_addr) {
    orderId++;

    processCompLevel(_addr, _matrix, _level);
  }

  function processCompLevel(address _addr, uint _matrix, uint _level) internal {
    require((_matrix == 1 || _matrix == 2), "Invalid matrix identifier.");
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");

    uint matrix = _matrix - 1;
    uint activeLevel = members[_addr].activeLevel[matrix];
    address sponsor = members[_addr].sponsor;

    require((activeLevel < _level), "Already active at level!");

    for (uint num = (activeLevel + 1);num <= _level;num++) {
      address activeSponsor = findActiveSponsor(_addr, sponsor, matrix, num, true);

      emit Upgrade(_addr, activeSponsor, _matrix, num, orderId);

      if (matrix == 0) {
        handlePositionL1(_addr, sponsor, activeSponsor, num, false);
        handlePayout(_addr, 0, num, false);
      } else {
        handlePositionL2(_addr, sponsor, activeSponsor, num, false);
        handlePayout(_addr, 1, num, false);
      }
    }
  }

  function addLevel(uint _levelPrice, uint _levelCommission, uint _levelFee) external isOwner(msg.sender) {
    require((levelCost[topLevel].cost < _levelPrice), "Check price point!");
    require((_levelCommission + _levelFee) == _levelPrice, "Check price point!");

    topLevel++;

    levelCost[topLevel] = Level({cost: _levelPrice, commission: _levelCommission, fee: _levelFee});

    handlePositionL1(idToMember[1], idToMember[1], idToMember[1], topLevel, true);
    handlePositionL2(idToMember[1], idToMember[1], idToMember[1], topLevel, true);
  }

  function updateLevelCost(uint _level, uint _levelPrice, uint _levelCommission, uint _levelFee) external isOwner(msg.sender) {
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");
    require((_levelPrice > 0), "Check price point!");
    require((_levelCommission + _levelFee) == _levelPrice, "Check price point!");

    if (_level > 1) {
      require((levelCost[(_level - 1)].cost < _levelPrice), "Check price point!");
    }

    if (_level < topLevel) {
      require((levelCost[(_level + 1)].cost > _levelPrice), "Check price point!");
    }

    levelCost[_level] = Level({cost: _levelPrice, commission: _levelCommission, fee: _levelFee});
  }

  function handleForfeitedBalance(address payable _addr) external {
    require((msg.sender == owner || msg.sender == holder), "Restricted Access!");
    
    (bool success, ) = _addr.call.value(address(this).balance)("");

    require(success, 'Failed');
  }

  function changeContractStatus() external isOwner(msg.sender) {
    contractEnabled = !contractEnabled;
    }

  function setHolder(address _addr) external isOwner(msg.sender) {
    holder = _addr;
  }

  function setOwner(address _addr) external isOwner(msg.sender) {
    owner = _addr;
  }

  function setFeeSystem(address _addr) external isOwner(msg.sender) {
    feeSystem = _addr;
  }

  function bytesToAddress(bytes memory _source) private pure returns (address addr) {
    assembly {
      addr := mload(add(_source, 20))
    }
  }
}