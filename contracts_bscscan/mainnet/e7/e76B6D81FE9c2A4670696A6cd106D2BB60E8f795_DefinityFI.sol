// SPDX-License-Identifier: BSD-3-Clause

/**
 *                               
 *       ##### ##                 /##                                                          ##### ##       #####  # 
 *    /#####  /##               #/ ###   #                 #                                ######  /### / ######  /   
 *  //    /  / ###             ##   ### ###               ###     #                        /#   /  /  ##/ /#   /  /    
 * /     /  /   ###            ##        #                 #     ##                       /    /  /    # /    /  /     
 *      /  /     ###           ##                                ##                           /  /           /  /      
 *     ## ##      ##    /##    ######  ###   ###  /###   ###   ######## ##   ####            ## ##          ## ##      
 *     ## ##      ##   / ###   #####    ###   ###/ #### / ### ########   ##    ###  /        ## ##          ## ##      
 *     ## ##      ##  /   ###  ##        ##    ##   ###/   ##    ##      ##     ###/         ## ######    /### ##      
 *     ## ##      ## ##    ### ##        ##    ##    ##    ##    ##      ##      ##          ## #####    / ### ##      
 *     ## ##      ## ########  ##        ##    ##    ##    ##    ##      ##      ##          ## ##          ## ##      
 *     #  ##      ## #######   ##        ##    ##    ##    ##    ##      ##      ##          #  ##     ##   ## ##      
 *        /       /  ##        ##        ##    ##    ##    ##    ##      ##      ##             #     ###   #  /       
 *   /###/       /   ####    / ##        ##    ##    ##    ##    ##      ##      ##         /####      ###    /        
 *  /   ########/     ######/  ##        ### / ###   ###   ### / ##       #########        /  #####     #####/         
 * /       ####        #####    ##        ##/   ###   ###   ##/   ##        #### ###      /    ###        ###          
 * #                                                                              ###     #                            
 *  ##          # #    ####    ##   #####  ###### #    # #   #             #####   ###     ##                          
 *             #   #  #    #  #  #  #    # #      ##  ##  # #            /#######  /#                                  
 *            #     # #      #    # #    # #####  # ## #   #            /      ###/                                    
 *            ####### #      ###### #    # #      #    #   #   
 *            #     # #    # #    # #    # #      #    #   #                                       
 *            #     #  ####  #    # #####  ###### #    #   #   
 *
 * Where education, community and opportunities go hand in hand.
 * https://www.definityfi.io
 * Start your education today!
 */
 
pragma solidity 0.8.4;

import './DataStorage.sol';
import './Access.sol';
import './Events.sol';
import './UUPS.sol';

contract DefinityFI is DataStorage, Access, Events, UUPS {

  constructor() {
    owner = msg.sender;

    reentryStatus = ENTRY_ENABLED;
    contractStatus = false;
    remoteStatus = false;
  }

  function locatePlacedUnder(address _addr, uint _package, uint _matrixNum, uint _timestamp) internal view returns (address, uint) {
    F1 storage position = members[_addr].x35Positions[_package];

    for (uint i=position.placedCount[_matrixNum];i > 0;i--) {
      F1Placement memory info = position.placedUnder[_matrixNum][i];
      
      if (info.timestamp <= _timestamp) {
        return (info.under, info.timestamp);
      }
    }
  }

  function locateMatrixReceiver(uint _payoutNum, address _addr, uint _package, uint _matrixNum, uint _timestamp) internal view returns (address, uint) {
    if (_payoutNum > 0 || members[_addr].accountType == TYPE_AFFILIATE) {      
      return locatePlacedUnder(_addr, _package, _matrixNum, _timestamp); 
    }

    address receiver = _addr;

    while (true) {
      receiver = members[receiver].sponsor;

      if (members[receiver].initPackage[_package] == true && members[receiver].x35Positions[_package].isActive == true) {
        break;
      }
    }

    (, uint position, ) = locatePosition(receiver, _package);
    
    receiver = getPlacedUnder(receiver, _package, position);

    return (receiver, members[receiver].x35Positions[_package].timestamp);
  }

  function getCommission(uint _amount, uint _percentage) internal pure returns (uint) {
    return (_amount * _percentage) / 100;
  }

  function handlePayout(address _addr, address _sponsor, address _activeSponsor, uint _package, uint _matrixNum, uint _amount, uint _systemPerc) internal {
    Payout[] memory payout = new Payout[](packageCost[_package].matrix.length + 2);

    payout = locateTierPayout(_addr, _sponsor, _activeSponsor, _package, _amount, payout);
    payout = locateMatrixPayout(_addr, _package, _matrixNum, _amount, payout);

    if (packageCost[_package].system > 0 && _systemPerc == 0) {
      payout = reviewPayout(systemReceiver, getCommission(_amount, packageCost[_package].system), payout);
    } else if (packageCost[_package].system > 0 && _systemPerc > 0) {
      payout = reviewPayout(cycleReceiver, getCommission(_amount, _systemPerc), payout);
    }

    for (uint num=0;num < payout.length;num++) {
      if (payout[num].amount > 0) {
        (bool success, ) = payable(payout[num].receiver).call{ value: payout[num].amount, gas: 20000 }("");

        if (success == false) { //Failsafe to prevent malicious contracts from blocking
          (success, ) = payable(members[idToMember[1]].payoutTo).call{ value: payout[num].amount, gas: 20000 }("");
          require(success, "E19");
        }
      }
    }
  }

  function locateTierPayout(address _addr, address _directSponsor, address _activeSponsor, uint _package, uint _amount, Payout[] memory _payout) internal returns (Payout[] memory) {
    F1 storage position = members[_activeSponsor].x35Positions[_package];
    uint amount = getCommission(_amount, packageCost[_package].tierUnpaid);

    if (_directSponsor != _activeSponsor && members[_directSponsor].accountType == TYPE_AFFILIATE) {
      _payout = reviewPayout(members[_directSponsor].payoutTo, amount, _payout);

      emit CommissionTierUnpaid(_directSponsor, _addr, _package, amount, orderId);

      amount = 0;
    }
    
    if (position.tierUnlocked < completeTierUnlock) {
      uint amount_tier2 = getCommission(_amount, packageCost[_package].tier[1]);
      
      _payout = reviewPayout(members[checkSponsor(position.sponsor)].payoutTo, amount_tier2, _payout);

      emit CommissionTier(checkSponsor(position.sponsor), _addr, _package, 2, amount_tier2, orderId);

      amount += getCommission(_amount, packageCost[_package].tier[0]);
    } else {
      amount += getCommission(_amount, packageCost[_package].tier[0] + packageCost[_package].tier[1]);
    }
    
    _payout = reviewPayout(members[_activeSponsor].payoutTo, amount, _payout);

    emit CommissionTier(_activeSponsor, _addr, _package, 1, amount, orderId);
    
    return _payout;
  }

  function locateMatrixPayout(address _addr, uint _package, uint _matrixNum, uint _amount, Payout[] memory _payout) internal returns (Payout[] memory) {
    address receiver = _addr;
    address passupReceiver;

    uint[] memory commission = packageCost[_package].matrix;
    
    uint amount;
    uint passupNum = 1;
    uint actualLevelDepth = 0;
    uint timestamp = block.timestamp;

    for (uint i=0;i < commission.length;i++) {
      amount = getCommission(_amount, commission[i]);

      do {
        if (passupReceiver != address(0x0)) {
          receiver = passupReceiver;
          passupReceiver = address(0x0);
        }

        actualLevelDepth++;
        (receiver, timestamp) = locateMatrixReceiver(i, receiver, _package, _matrixNum, timestamp);

        if (members[receiver].initPackage[_package] == false || members[receiver].x35Positions[_package].depthUnlocked < (i+1)) {
          emit PassupMatrix(receiver, _addr, _package, (i+1), amount, orderId);

          if (passupNum++ >= matrixPassupDepth) {
            passupReceiver = receiver;
            receiver = idToMember[1];
            break;
          }
        }
      } while (members[receiver].initPackage[_package] == false || members[receiver].x35Positions[_package].depthUnlocked < (i+1));
      
      _payout = reviewPayout(members[receiver].payoutTo, amount, _payout);
 
      emit CommissionMatrix(receiver, _addr, _package, (i+1), actualLevelDepth, amount, orderId);
    }

    return _payout;
  }

  function reviewPayout(address _addr, uint _amount, Payout[] memory _payout) internal pure returns (Payout[] memory) {

    for (uint i=0;i < _payout.length;i++) {
      if (_addr == _payout[i].receiver) {
        _payout[i].amount += _amount;
        break;
      } else if (_payout[i].amount == 0) {
        _payout[i] = Payout({receiver: _addr, amount: _amount});
        break;
      }
    }

    return _payout;
  }

  function createPosition(address _addr, address _sponsor, uint _package, bool _cycle) internal {
    (uint row, uint position, uint placementSide) = locatePosition(_sponsor, _package);
    
    address placedUnder = getPlacedUnder(_sponsor, _package, position);
    uint depth = members[placedUnder].x35Positions[_package].depth + 1;

    uint matrixNum = members[_sponsor].x35Positions[_package].matrixNum;

    if (_cycle == false) {
      createPositionRecord(_addr, _sponsor, _package, position, depth, initialDepthUnlock, 0, placementSide, matrixNum, placedUnder);
    } else {
      updatePositionRecord(_addr, _package, position, depth, placementSide, matrixNum, placedUnder);
    }

    updatePosition(_addr, _sponsor, _package, row, position, true);

    emit Placement(_addr, _sponsor, _package, matrixNum, position, placedUnder, _cycle, orderId);
    
    if (depth == 1) {
      return;
    }

    createPlacement(_addr, _sponsor, _package, depth, matrixNum);
  }

  function createPlacement(address _addr, address _sponsor, uint _package, uint _depth, uint _matrixNum) internal {
    uint num = 5;
    uint total = 6;
    uint row_depth = 5;
  
    uint[] memory sides = new uint[](6);
    address[] memory sponsors = new address[](6);

    if (_depth < 5) {
      num = _depth;
      total = _depth + 1;
      row_depth = _depth;
    }
      
    address account = _addr;
    uint timestamp = block.timestamp;
    
    for (;num > 0;num--) {
      sides[num] = members[account].x35Positions[_package].placementSide;

      (account, timestamp) = locatePlacedUnder(account, _package, _matrixNum, timestamp);

      sponsors[num] = account;
    }
    
    uint position;
    
    for (num = 1;num < total;num++) {
      if (sponsors[num] == _sponsor) {
        row_depth--;
        continue;
      }

      position = sides[num];

      for (uint i = (num+1);i < total;i++) {
        position = ((position * 3) + sides[i]);
      }

      updatePosition(_addr, sponsors[num], _package, row_depth, position, false);

      if (row_depth-- == 5) {
        checkIfCycle(_addr, sponsors[num], _package);
      }
    }

    checkIfCycle(_addr, _sponsor, _package); 
  }

  function checkIfCycle(address _from, address _addr, uint _package) internal {
    F1 storage position = members[_addr].x35Positions[_package];

    if (position.rows[5] < matrixRow[5].total) {
      return;
    }

    cycleId++;

    position.isActive = false;
    position.lastCycleId = cycleId;

    emit CycleEvent(_addr, _from, _package, cycleId, orderId);

    cycleEvent[cycleId] = Cycle({member: _addr, package: _package, payout: true, matrixNum: 0, amount: 0});
  
    if (position.handledCycle > 0 || _addr == idToMember[1]) {
      if (position.handledCycle > 0) {
        position.handledCycle -= 1;
      }

      handleCycle(_addr, _package, true);
    }

    bool success = b_handle.tieCycle(_addr, _package);

    require(success, "E16");    
  }

  function handleCycle(address _addr, uint _package, bool _handlePayout) internal {
    F1 storage position = members[_addr].x35Positions[_package];
    
    position.isActive = true;
    
    emit CycleProcess(_addr, position.lastCycleId, _handlePayout, orderId);

    for (uint i=0;i < 364;i++) {
      delete position.x35Matrix[i];
    }

    if (_addr == idToMember[1]) {
      updatePositionRecord(_addr, _package, 0, 0, 0, (position.matrixNum + 1), _addr);
    } else {
      createPosition(_addr, position.sponsor, _package, true);
    }

    cycleEvent[position.lastCycleId].payout = _handlePayout;
    cycleEvent[position.lastCycleId].matrixNum = position.matrixNum;
  }

  function handleCycleCheck(address _addr, uint _package) external isMember(_addr) isCycleHandler(msg.sender) {
    F1 storage position = members[_addr].x35Positions[_package];

    if (members[_addr].ownPackage[_package] != true) {
      handlePositionUnlock(_addr, members[_addr].accountType, members[_addr].sponsor, position.sponsor, _package, true);

      emit Upgrade(_addr, members[_addr].x35Positions[_package].sponsor, _package, members[_addr].accountType, 2, orderId);
    }

    if (position.isActive == true) {
      position.handledCycle++;

      orderId++;

      emit CyclePre(_addr, _package, orderId);

      return;
    }

    handleCycle(_addr, _package, true);
  }

  function handleCyclePayout(uint _cycleId, uint _package, address _addr, uint _total, uint _perc) external payable isCycleHandler(msg.sender) contractEnabled() blockReEntry() {
    require(cycleEvent[_cycleId].payout == true, "E4");
    require(cycleEvent[_cycleId].amount == 0, "E21");
    require(cycleEvent[_cycleId].member == _addr && cycleEvent[_cycleId].package == _package, "E8");

    orderId++;
    
    Cycle storage info = cycleEvent[_cycleId];

    info.amount = msg.value;

    emit CyclePayout(info.member, info.package, _cycleId, msg.value, orderId);

    address sponsor = members[info.member].sponsor;
    address activeSponsor = members[info.member].x35Positions[info.package].sponsor;

    uint transfer = msg.value;
    uint percentage = 0;

    if (packageCost[_package].system >= _perc) {
      transfer = _total;
      percentage = packageCost[_package].system - _perc;
    }

    handlePayout(info.member, sponsor, activeSponsor, info.package, info.matrixNum, transfer, percentage);
    handleReward(info.member, checkSponsor(sponsor), _package);
  }

  function handleReward(address _addr, address _sponsor, uint _package) internal {
    bool success;
  
    Reward memory rewardInfo = reward[_package];

    if (rewardInfo.amountAccount > 0) {
      success = t_handle.assignReward(_addr, rewardInfo.amountAccount);

      require(success, "E20");
    }

    if (rewardInfo.amountSponsor > 0) {
      success = t_handle.assignReward(_sponsor, rewardInfo.amountSponsor);

      emit CommissionToken(_sponsor, _addr, _package, rewardInfo.amountSponsor, orderId);
      
      require(success, "E20");
    }
  }
  
  function getPlacedUnder(address _addr, uint _package, uint _position) internal view returns (address) {
    if (_position <= 3) {
      return _addr;
    }

    uint position = (_position - 1) / 3;

    return members[_addr].x35Positions[_package].x35Matrix[position];
  }
  
  function updatePosition(address _addr, address _sponsor, uint _package, uint _row, uint _position, bool updateLastPosition) internal {
    F1 storage position = members[_sponsor].x35Positions[_package];

    position.rows[_row]++;
    position.x35Matrix[_position] = _addr;

    if (updateLastPosition == true) {
      position.lastPlacedPosition = _position;
    }
  }

  function locatePosition(address _addr, uint _package) internal view returns (uint, uint, uint) {
    F1 storage matrix = members[_addr].x35Positions[_package];

    uint row;
    uint total = 5;
    uint position;

    for (row = 1; row <= total; row++) {
      if (matrix.rows[row] >= matrixRow[row].total) {
        continue;
      }

      position = matrixRow[row].start;
      total = matrixRow[row].end;
      break;
    }

    if (matrix.lastPlacedPosition > position) {
      position = matrix.lastPlacedPosition + 1;
    }

    for(; position <= total; position++) {
        if (matrix.x35Matrix[position] != address(0x0)) {
          continue;
        }

        break;
      }

    return (row, position, positionSide[position]);
  }

 function findActiveSponsor(address _addr, address _sponsor, uint _package, bool _emit) internal returns (address) {
    address sponsorAddress = _sponsor;

    while (true) {
      if (members[sponsorAddress].initPackage[_package] == true && members[sponsorAddress].x35Positions[_package].isActive == true) {
        return sponsorAddress;
      }

      if (_emit == true && members[sponsorAddress].accountType == TYPE_AFFILIATE) {
        emit Passup(sponsorAddress, _addr, _package, orderId);
      }

      sponsorAddress = members[sponsorAddress].sponsor;
    }
  }

  function checkSponsor(address _sponsor) internal view returns (address) {
    if (members[_sponsor].accountType == TYPE_CUSTOMER_FORCE) {
      return idToMember[1];
    }

    return _sponsor;
  }

  function handlePackagePurchase(address _addr, uint _package, uint _amount, bool _handlePayout) internal {
    require((_package > 0 && _package <= topPackage), "E11");
    require(members[_addr].ownPackage[_package] != true, "E32");
    require(members[_addr].initPackage[_package] != true, "E33");

    if (_handlePayout == true) {
      require(confirmReceivedAmount(_amount, packageCost[_package].cost) == true, "E25");
    }
  
    orderId++;    

    handlePosition(_addr, members[_addr].sponsor, _package, _amount, members[_addr].accountType, _handlePayout);

    emit Upgrade(_addr, members[_addr].x35Positions[_package].sponsor, _package, members[_addr].accountType, 1, orderId);
  }

  function processUnlockDepth(address _addr, uint _package) internal {
    F1 storage position = members[_addr].x35Positions[_package];

    if (position.depthUnlocked < completeDepthUnlock) {
      position.depthUnlocked += depthToUnlock;
    }
  }

  function processUnlockTier(address _addr, uint _package) internal {
    F1 storage position = members[_addr].x35Positions[_package];

    if (position.tierUnlocked < completeTierUnlock) {
      position.tierUnlocked += 1;
    }
  }

  function purchasePackage(uint _package) external payable isMember(msg.sender) contractEnabled() blockReEntry() {
    handlePackagePurchase(msg.sender, _package, msg.value, true);
  }

  function purchaseBundle(uint[] calldata _packages) external payable isMember(msg.sender) contractEnabled() blockReEntry() {
    uint cost = 0;

    for (uint i=1;i < _packages.length;i++) {
      if (_packages[i] > 0) {
        cost += _packages[i];
      }
    }

    require(cost == msg.value, "E9");

    for (uint i=1;i < _packages.length;i++) {
      if (_packages[i] > 0) {
        handlePackagePurchase(msg.sender, i, _packages[i], true);
      }
    }
  }

  function preRegistration(address _addr, address _sponsor, uint _package, uint _type) internal contractEnabled() {
    require(confirmReceivedAmount(msg.value, packageCost[_package].cost) == true, "E25");

    lastId++;

    createAccount(lastId, _addr, checkSponsor(_sponsor), _type, false);

    handlePosition(_addr, checkSponsor(_sponsor), _package, msg.value, _type, true);
  }

  function handlePosition(address _addr, address _sponsor, uint _package, uint _amount, uint _type, bool _handlePayout) internal {
    address activeSponsor = findActiveSponsor(_addr, _sponsor, _package, true);
    
    if (_type == TYPE_AFFILIATE) {
      members[_addr].initPackage[_package] = true;

      createPosition(_addr, activeSponsor, _package, false);
    }

    handlePositionUnlock(_addr, _type, _sponsor, activeSponsor, _package, _handlePayout);

    if (_handlePayout == true) {
      uint matrixNum;

      if (_type == TYPE_AFFILIATE) {
        matrixNum = members[_addr].x35Positions[_package].matrixNum;
      } else {
        matrixNum = members[activeSponsor].x35Positions[_package].matrixNum;
      }
          
      handlePayout(_addr, _sponsor, activeSponsor, _package, matrixNum, _amount, 0);
      handleReward(_addr, checkSponsor(_sponsor), _package);

      if (_sponsor != activeSponsor) {
        handlePassup(_sponsor, _addr, _package);
      }
    }
  }

  function handlePositionUnlock(address _addr, uint _accountType, address _sponsor, address _activeSponsor, uint _package, bool _handlePayout) internal {
    members[_addr].ownPackage[_package] = true;

    if (_handlePayout == false) {
      return;
    }

    processUnlockDepth(_activeSponsor, _package);

    if (_sponsor == _activeSponsor) {
      processUnlockTier(_sponsor, _package);

      bool success = b_handle.tieSale(_sponsor, _package);

      require(success, "E17");
    }

    if (_package > 1 && _accountType == TYPE_AFFILIATE) {
      if (members[_addr].initPackage[(_package - 1)] == true) {
        processUnlockDepth(_addr, (_package - 1));  
      }
      
      if (members[_addr].initPackage[(_package + 1)] == true) {
        processUnlockDepth(_addr, _package);
      }
    }
  }

  function handlePassup(address _addr, address _addrPassup, uint _package) internal {
    Account storage member = members[_addr];

    if (member.accountType == TYPE_CUSTOMER || (member.initPackage[_package] == true && member.x35Positions[_package].isActive == true)) {
      return;
    }

    member.passPackage[_package] += 1;

    emit AccountPassup(_addr, _addrPassup, _package, orderId);    

    if (member.passPackage[_package] < passupReq) {
      return;
    }

    member.passPackage[_package] = 0;

    if (member.initPackage[_package] == true) {
      handleCycle(_addr, _package, false);

      emit AccountMatrix(_addr, _package, orderId);

      return;
    }

    member.initPackage[_package] = true;

    address activeSponsor = findActiveSponsor(_addr, member.sponsor, _package, false);
    
    createPosition(_addr, activeSponsor, _package, false);

    emit AccountCommission(_addr, _package, orderId);
  }

  function createPositionRecord(address _addr, address _sponsor, uint _package, uint _position, uint _depth, uint _depthUnlocked, uint _tierUnlocked, uint _placementSide, uint _matrixNum, address _placedUnder) internal {
    F1 storage position = members[_addr].x35Positions[_package];

    position.isActive = true;

    position.sponsor = _sponsor;
    position.position = _position;
    position.lastPlacedPosition = 0;
    position.matrixNum = _matrixNum;
    position.timestamp = block.timestamp;
    position.depth = _depth;
    position.depthUnlocked = _depthUnlocked;
    position.tierUnlocked = _tierUnlocked;
    position.placementSide = _placementSide;
    position.placedCount[_matrixNum] = 1;
    position.placedUnder[_matrixNum][1] = F1Placement({timestamp: block.timestamp, under: _placedUnder});
    position.rows = new uint[](6);
  }

  function updatePositionRecord(address _addr, uint _package, uint _position, uint _depth, uint _placementSide, uint _matrixNum, address _placedUnder) internal {
    F1 storage position = members[_addr].x35Positions[_package];

    position.position = _position;
    position.lastPlacedPosition = 0;
    position.matrixNum = _matrixNum;
    position.timestamp = block.timestamp;
    position.depth = _depth;
    position.placementSide = _placementSide;
    position.placedCount[_matrixNum]++;
    position.placedUnder[_matrixNum][position.placedCount[_matrixNum]] = F1Placement({timestamp: block.timestamp, under: _placedUnder});
    position.rows = new uint[](6);
  }

  function confirmReceivedAmount(uint _amount, uint _cost) internal view returns (bool) {
    require((block.timestamp - exchangeRateTimeout) < exchangeRateUpdated, "E18");

    if (calculateCost(_amount, _cost, exchangeRate) == true) {
      return true;
    }

    return calculateCost(_amount, _cost, exchangeRatePrevious);
  }

  function calculateCost(uint _amount, uint _cost, uint _exchangeRate) internal pure returns (bool) {
    return _amount == ((_cost * _exchangeRate) / 100);
  }

  function createAccount(uint _memberId, address _addr, address _sponsor, uint _type, bool _initial) internal {
    require(members[_addr].id == 0, "E30");

    if (_initial == false) {
      require(members[_sponsor].id > 0, "E29");
    }

    orderId++;

    Account storage member = members[_addr];

    member.id = _memberId;
    member.sponsor = _sponsor;
    member.payoutTo = _addr;
    member.accountType = _type;

    idToMember[_memberId] = _addr;

    if (_initial == false) {
      bool success = b_handle.setupAccount(_addr, _memberId);
      
      require(success, "E27");
    }

    emit Registration(_addr, _memberId, _sponsor, _type, orderId);
  }

  function registration(address _sponsor) external payable blockReEntry() {
    preRegistration(msg.sender, _sponsor, 1, TYPE_CUSTOMER);
  }

  function registrationAffiliate(address _sponsor) external payable blockReEntry() {
    preRegistration(msg.sender, _sponsor, 1, TYPE_AFFILIATE);
  }

  fallback() external payable blockReEntry() {
    preRegistration(msg.sender, bytesToAddress(msg.data), 1, TYPE_CUSTOMER);
  }

  receive() external payable blockReEntry() {
    preRegistration(msg.sender, idToMember[1], 1, TYPE_CUSTOMER);
  }

  function createAffiliate(address _sponsor) external contractEnabled() blockReEntry() {
    lastId++;

    createAccount(lastId, msg.sender, _sponsor, TYPE_AFFILIATE, false);
  }

  function becomeAffiliate() external isMember(msg.sender) contractEnabled() blockReEntry() {
    require(members[msg.sender].accountType == TYPE_CUSTOMER, "E31");
    
    orderId++;    

    Account storage member = members[msg.sender];

    emit AccountChangeInit(msg.sender, TYPE_AFFILIATE, orderId);

    uint processed = 0;
    uint loopEnd = topPackage + 1;
    
    for (uint i=1;i < loopEnd;i++) {
      if (i == topPackage) {
        member.accountType = TYPE_AFFILIATE;

        emit AccountChange(msg.sender, TYPE_AFFILIATE, orderId);
      }

      if (member.ownPackage[i] == true && member.initPackage[i] == false) {
        processed++;

        member.initPackage[i] = true;        

        address activeSponsor = findActiveSponsor(msg.sender, member.sponsor, i, false);

        createPosition(msg.sender, activeSponsor, i, false);

        uint lastPackage = i - 1;

        if (member.initPackage[lastPackage] == true) {
          processUnlockDepth(msg.sender, lastPackage);  
        }
      }

      if (processed >= 6) {
        break;
      }
    }
  }

  function handleEnforcement(address _addr, uint _period) external isEnforce(msg.sender) returns (bool) {
    require(members[_addr].accountType != TYPE_CUSTOMER_FORCE, "E23");    

    Account storage member = members[_addr];
    Enforce storage handle = enforce[_addr];

    handle.period = _period;
    handle.accountType = member.accountType;    

    for (uint i=1;i <= topPackage;i++) {
      if (member.initPackage[i] == true) {
        handle.initPackage[i] = true;
        member.initPackage[i] = false;

        if (member.x35Positions[i].isActive == true) {
          handle.activePackage[i] = true;
          member.x35Positions[i].isActive = false;
        }
      }
    }

    member.accountType = TYPE_CUSTOMER_FORCE;

    orderId++;
    
    emit AccountChange(_addr, TYPE_CUSTOMER_FORCE, orderId);

    return true;
  }

  function liftEnforcement(address _addr) external isEnforce(msg.sender) returns (bool) {
    require(members[_addr].accountType == TYPE_CUSTOMER_FORCE, "E23");
    require(enforce[_addr].period < block.timestamp, "E23");

    Account storage member = members[_addr];
    Enforce storage handle = enforce[_addr];

    uint accountType = handle.accountType;

    for (uint i=1;i <= topPackage;i++) {
      if (handle.initPackage[i] == true) {
        member.initPackage[i] = true;

        if (handle.activePackage[i] == true) {
          member.x35Positions[i].isActive = true;
        }
      } else if (member.ownPackage[i] == true)  {
        accountType = TYPE_CUSTOMER;
      }

      delete(handle.initPackage[i]);
      delete(handle.activePackage[i]);
    }

    member.accountType = accountType;
      
    orderId++;

    emit AccountChange(_addr, accountType, orderId);

    delete(enforce[_addr]);

    return true;
  }

  function bytesToAddress(bytes memory _source) internal pure returns (address addr) {
    assembly {
      addr := mload(add(_source, 20))
    }
  }

  function changeContractStatus() external isOwner(msg.sender) {
    contractStatus = !contractStatus;
  }

  function changeRemoteStatus() external isOwner(msg.sender) {
    remoteStatus = !remoteStatus;
  }

  function setExchangeRate(uint rate) public isExchangeHandler(msg.sender) {
    exchangeRateUpdated = block.timestamp;
    exchangeRatePrevious = exchangeRate;
    exchangeRate = rate;
  }

  function setupAccount(address _addr, address _sponsor, uint _type) external payable isRemoteHandler(msg.sender) remoteEnabled() blockReEntry() {
    require(confirmReceivedAmount(msg.value, packageCost[1].cost) == true, "E25");
    require(_type == TYPE_CUSTOMER || _type == TYPE_AFFILIATE, "E24");

    lastId++;

    createAccount(lastId, _addr, _sponsor, _type, false);
    handlePosition(_addr, _sponsor, 1, msg.value, _type, true);
  }

  function setupUpgrade(address _addr, uint _package) external payable isRemoteHandler(msg.sender) isMember(_addr) remoteEnabled() blockReEntry() {
    handlePackagePurchase(_addr, _package, msg.value, true);
  }

  function setupBundle(address _addr, address _sponsor, uint _type, uint[] calldata _packages) external payable isRemoteHandler(msg.sender) remoteEnabled() blockReEntry() {
    require(_type == TYPE_CUSTOMER || _type == TYPE_AFFILIATE, "E24");
    
    uint cost = 0;

    for (uint i=1;i < _packages.length;i++) {
      if (_packages[i] > 0) {
        cost += _packages[i];
      }
    }

    require(cost == msg.value, "E9");
    require(_packages[1] > 0 || members[_addr].id > 0, "E26");

    if (_packages[1] > 0) {
      require(confirmReceivedAmount(_packages[1], packageCost[1].cost) == true, "E25");

      lastId++;

      createAccount(lastId, _addr, _sponsor, _type, false);
      handlePosition(_addr, _sponsor, 1, _packages[1], _type, true);
    }

    for (uint i=2;i < _packages.length;i++) {
      if (_packages[i] > 0) {
        handlePackagePurchase(_addr, i, _packages[i], true);
      }
    }
  }
  
  function compAccount(address _addr, address _sponsor) external isOwner(msg.sender) {
    lastId++;

    createAccount(lastId, _addr, _sponsor, TYPE_AFFILIATE, false);
    handlePosition(_addr, _sponsor, 1, 0, TYPE_AFFILIATE, false);
  }

  function compPackage(address _addr, uint _package, uint _toPackage) external isOwner(msg.sender) isMember(_addr) {
    if (_package > 0) {
      handlePackagePurchase(_addr, _package, 0, false);
    } else if (_toPackage > 1) {
      for (uint num=2;num <= _toPackage;num++) {
        if (members[_addr].initPackage[num] != true) {
          handlePackagePurchase(_addr, num, 0, false);
        }
      }    
    }
  }
  
  function finalizeAddPackage() external contractMaintenance() isOwner(msg.sender) {
    require(members[idToMember[1]].ownPackage[topPackage] == false, "E21");

    createPositionRecord(idToMember[1], idToMember[1], topPackage, 0, 0, completeDepthUnlock, completeTierUnlock, 0, 1, idToMember[1]);
  }

  function init(address _addr) external contractMaintenance() isOwner(msg.sender) {
    require(lastId == 0, "E22");

    lastId++;

    createAccount(lastId, _addr, _addr, TYPE_AFFILIATE, true);

    members[_addr].ownPackage[1] = true;
    members[_addr].initPackage[1] = true;

    createPositionRecord(_addr, _addr, 1, 0, 0, completeDepthUnlock, completeTierUnlock, 0, 1, _addr);
  }

  function getPackageCost(uint _package) public view returns (uint) {
    return (packageCost[_package].cost * exchangeRate) / 100;
  }

  function getTokenCost(uint _amount) external view returns (uint) {
    return (_amount * (tokenCost * exchangeRate)) / 100;
  }
  
  function getBundleCost(uint _package) external view returns (uint, uint[] memory) {
    require((_package > 0 && _package <= topPackage), "E11");

    uint cost;
    uint total = 0;
    uint[] memory amount = new uint[](_package + 1);

    for (uint num = 1;num <= _package;num++) {
      if (members[msg.sender].ownPackage[num] != true && members[msg.sender].initPackage[num] != true) {
        cost = getPackageCost(num);

        total += cost;
        amount[num] = cost;
      }
    }

    return (total, amount);
  }

  function confirmPackageCost(uint _amount, uint _package) external view returns (bool) {
    return confirmReceivedAmount(_amount, packageCost[_package].cost);
  }

  function confirmTokenCost(uint _amount, uint _tokens) external view returns (bool) {
    return confirmReceivedAmount(_amount, (_tokens * tokenCost));
  }

  function ownPackage(address _addr, uint _package) external view returns (bool, bool, bool, uint) {
    return (members[_addr].ownPackage[_package], members[_addr].initPackage[_package], members[_addr].x35Positions[_package].isActive, members[_addr].passPackage[_package]);
  }

  function ownPackages(address _addr) external view returns (bool[] memory, bool[] memory, bool[] memory, uint[] memory) {
    
    bool[] memory own = new bool[](topPackage + 1);
    bool[] memory initiated = new bool[](topPackage + 1);
    bool[] memory active = new bool[](topPackage + 1);
    uint[] memory passup = new uint[](topPackage + 1);

    for (uint i=1;i < (topPackage + 1);i++) {
      own[i] = members[_addr].ownPackage[i];
      initiated[i] = members[_addr].initPackage[i];
      active[i] = members[_addr].x35Positions[i].isActive;
      passup[i] = members[_addr].passPackage[i];
    }
    
    return (own, initiated, active, passup);
  }

  function getContractStatus() external view returns (bool, bool) {
    return (contractStatus, remoteStatus);
  }

  function getExchangeRate() external view returns (uint, uint) {
    return (exchangeRate, exchangeRateUpdated);
  }

  function getSettings() external view returns (uint, uint, uint, uint, uint, uint, uint) {
    return(depthToUnlock, initialDepthUnlock, completeDepthUnlock, completeTierUnlock, matrixPassupDepth, passupReq, topPackage);
  }

  function getSystemPositions() external view returns (uint, uint, uint) {
    return (lastId, cycleId, orderId);
  }

  function getCycleEvent(uint _cycleId) external view returns (Cycle memory) {
    return cycleEvent[_cycleId];
  }

  function getPackageInfo(uint _package) external view returns (Package memory) {
    return packageCost[_package];
  }

  function getReward(uint _package) external view returns (Reward memory) {
    return reward[_package];
  }

  function getRewardPerc(uint _package) external view returns (uint) {
    return packageCost[_package].reward;
  }

  function getIdToMember(uint _id) external view returns (address) {
    return idToMember[_id];
  }

  function getMemberMatrix(address _addr, uint _package) external view returns (address, uint, uint, uint, uint, uint, uint) {
    require(members[_addr].id > 0, "E28");

    F1 storage position = members[_addr].x35Positions[_package];

    return (position.sponsor, position.matrixNum, position.position, position.placementSide, position.depth, position.lastPlacedPosition, position.lastCycleId);
  }

  function getMemberMatrixUnlock(address _addr, uint _package) external view returns (uint, uint ,uint) {
    require(members[_addr].id > 0, "E28");

    F1 storage position = members[_addr].x35Positions[_package];

    return (position.depthUnlocked, position.tierUnlocked, position.handledCycle);
  }
  
  function getMember(address _addr) external view returns (uint, address, uint) {
    require(members[_addr].id > 0, "E28");
    
    return (members[_addr].id, members[_addr].sponsor, members[_addr].accountType);
  }

  function getPayoutAddress(address _addr) external view returns (address) {
    require(members[_addr].id > 0, "E28");

    return members[_addr].payoutTo;
  }
}