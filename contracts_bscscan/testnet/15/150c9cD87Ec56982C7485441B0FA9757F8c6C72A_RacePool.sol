// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import './IBEP20.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';

contract RacePool is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IBEP20;


  enum state { DESTROY, OPEN, READY, FULLFILL }
  struct pool {
    uint id;
    address creator;
    uint entranceFee;
    uint creatorTax;
    uint contractTax;
    uint startDate;
    uint8 participantCount;
    address[] participants;
    uint8 winnerCount;
    uint[] rewards;
    address[] claimers;
    bool[] rewardClaims;
    state status;
  }

  bytes public version = '1.0.1';
  IBEP20 private bep20;
  address private admin;
  string private name;
  string private symbol;
  uint8 private decimals;
  uint private tax;
  uint private activeRoom;
  bool[] private index;

  mapping (uint => pool) private room;

  modifier onlyAdmin() {
    require(
      (owner() == msg.sender) || (admin == msg.sender), 
      'ERR01'
    );
    _;
  }

  modifier onlyCreator(uint id) {
    require(
      (owner() == msg.sender) || (admin == msg.sender) || (room[id].creator == msg.sender), 
      'ERR02'
    );
    _;
  }

  modifier onlyExistRoom(uint id) {
    require(room[id].id != 0, 'ERR03');
    _;
  }

  modifier onlyStatus(state status, uint id) {
    require(room[id].status == status, 'ERR04');
    _;
  }

  constructor(
    address bep20ContractAddress,
    string memory contractName,
    string memory contractSymbol,
    address contractAdmin,
    uint contractTax
  ) {
    name = contractName;
    symbol = contractSymbol;
    admin = contractAdmin;
    tax = contractTax;
    bep20 = IBEP20(bep20ContractAddress);
  }

  event Contract (bool changed);
  function setContract(address bep20ContractAddress) external onlyOwner {
    bep20 = IBEP20(bep20ContractAddress);

    emit Contract(true);
  }

  event Admin (address admin);
  function setAdmin(address walletAddress) external onlyOwner {
    admin = walletAddress;

    emit Admin(admin);
  }

  event Tax(uint tax);
  function setTax(uint contractTax) external onlyOwner {
    tax = contractTax;

    emit Tax(tax);
  }

  function getTax() external view returns (uint contractTax) {
    return tax;
  }

  event CreateRoom(pool room);
  function createRoom(
    address creator,
    uint entranceFee,
    uint startDate,
    uint8 participantCount,
    uint8 winnerCount,
    uint creatorTax
  ) external {
    require(entranceFee > 0, 'ERR05');
    require(participantCount > 0, 'ERR06');
    require(winnerCount > 0, 'ERR07');

    uint newId = index.length + 1;
    pool storage newRoom = room[newId];

    newRoom.id = newId;
    newRoom.creator = creator;
    newRoom.entranceFee = entranceFee;
    newRoom.startDate = startDate;
    newRoom.participantCount = participantCount;
    newRoom.winnerCount = winnerCount;
    newRoom.creatorTax = creatorTax;
    newRoom.contractTax = tax;
    newRoom.status = state.OPEN;
    index.push(true);
    activeRoom += 1;

    bep20.safeTransferFrom(
      newRoom.creator,
      address(this),
      newRoom.entranceFee
    );
    
    emit CreateRoom(newRoom);
  }

  function getRoom(uint id) view external returns (pool memory) {
    return room[id];
  }

  function getRooms(uint startedBefore) external view returns (pool[] memory) {
    pool[] memory rooms = new pool[](activeRoom);
    uint pointer = 0;
    
    for (uint i = 0; i < index.length; i++) {
      if (index[i] && (room[i].startDate >= startedBefore)) {
        rooms[pointer] = room[i + 1];
        pointer += 1;
      }
    }  
    return rooms;
  }

  event DestroyRoom(state status);
  function destroyRoom(uint id)
  onlyCreator(id) onlyExistRoom(id) onlyStatus(state.OPEN, id) external {
    index[id - 1] = false;
    room[id].status = state.DESTROY;
    activeRoom -= 1;

    bep20.safeTransfer(
      room[id].creator,
      room[id].entranceFee
    );

    emit DestroyRoom(room[id].status);
  }

  event EntranceFee(uint entraceFee);
  function setEntranceFee(uint id, uint balance)
  onlyCreator(id) onlyExistRoom(id) onlyStatus(state.OPEN, id) external {
    require(balance > 0, 'ERR05');
    require(room[id].participants.length == 0, 'ERR08');

    if (balance > room[id].entranceFee) {
      bep20.safeTransferFrom(
        room[id].creator,
        address(this),
        balance.sub(room[id].entranceFee)
      );
    } else if (balance < room[id].entranceFee) {
      bep20.safeTransfer(
        room[id].creator,
        room[id].entranceFee.sub(balance)
      );
    }

    room[id].entranceFee = balance;

    emit EntranceFee(room[id].entranceFee);
  }

  event StartDate(uint timestamp);
  function setStartDate(uint id, uint timestamp)
  onlyCreator(id) onlyExistRoom(id) onlyStatus(state.OPEN, id) external {
    // ! Make sure requester do validate:
    // ! new start date (timestamp) greater than or equal than current date (timestamp)
    room[id].startDate = timestamp;

    emit StartDate(room[id].startDate);
  }

  event ParticipantCount(uint participantCount);
  function setParticipantCount(uint id, uint8 count) 
  onlyCreator(id) onlyExistRoom(id) onlyStatus(state.OPEN, id) external {
    require(count > 0, 'ERR06');
    require(
      (room[id].participants.length == 0) || (room[id].participants.length < count), 
      'ERR09'
    );

    room[id].participantCount = count;

    emit ParticipantCount(room[id].participantCount);
  }

  event JoinRoom(address[] participants);
  function joinRoom(uint id) 
  onlyExistRoom(id) onlyStatus(state.OPEN, id) external {
    for (uint8 i = 0; i < room[id].participants.length; i++) {
      if (room[id].participants[i] == msg.sender) {
        revert('ERR18');
      }
    }

    room[id].participants.push(msg.sender);

    // auto lock room when last participants join
    if (room[id].participants.length == room[id].participantCount) {
      room[id].status = state.READY;
    }

    emit JoinRoom(room[id].participants);
  }

  event LeaveRoom(address[] participants);
  function leaveRoom(uint id) 
  onlyExistRoom(id) onlyStatus(state.OPEN, id) external returns (bool left) {
    bool success = false;
    for (uint8 i = 0; i < room[id].participants.length; i++) {
      if (room[id].participants[i] == msg.sender) {
        room[id].participants[i] = room[id].participants[room[id].participants.length - 1];
        success = true;
        break;
      }
    }

    if (success) {
      room[id].participants.pop();
    }

    emit LeaveRoom(room[id].participants);
    return success;
  }

  event KickParticipant(address[] participants);
  function kickParticipant(uint id, address user) 
  onlyCreator(id) onlyExistRoom(id) onlyStatus(state.OPEN, id) external returns (bool left) {
    require(user != address(0), 'ERR10');

    bool success = false;
    for (uint8 i = 0; i < room[id].participants.length; i++) {
      if (room[id].participants[i] == user) {
        if (i != room[id].participants.length - 1) {
          for (uint8 j = i; j < room[id].participants.length - 1; j++){
            room[id].participants[j] = room[id].participants[j+1];
          }
        }
        
        success = true;
        room[id].participants.pop();
        break;
      }
    }

    emit KickParticipant(room[id].participants);
    return success;
  }

  event WinnerCount(uint winnerCount);
  function setWinnerCount(uint id, uint8 count) 
  onlyCreator(id) onlyExistRoom(id) onlyStatus(state.OPEN, id) external {
    require(count > 0, 'ERR07');

    room[id].winnerCount = count;

    emit WinnerCount(room[id].winnerCount);
  }

  event Rewards(uint[] rewards);
  function setRewards(uint id, uint[] memory ratios) 
  onlyAdmin onlyExistRoom(id) onlyStatus(state.READY, id) external {
    require(ratios.length == room[id].winnerCount, 'ERR11');

    // admin reward balance
    room[id].rewards[0] = room[id].entranceFee - (room[id].entranceFee * room[id].contractTax.div(10));
    
    // room creator reward balance
    room[id].rewards[1] = room[id].entranceFee - (room[id].entranceFee * room[id].creatorTax.div(10));

    uint total;
    for (uint8 i = 0; i < ratios.length; i++) {
      total = total.add(ratios[i]);
      require(total <= 1000, 'ERR12');
      
      // winners[i] reward balance
      room[id].rewards.push(
        room[id].entranceFee
        - (room[id].entranceFee * ratios[i].div(10)) 
        - (room[id].rewards[0] * ratios[i].div(10)) 
        - (room[id].rewards[1] * ratios[i].div(10))
      );
    }

    require(total >= 999, 'ERR13');

    emit Rewards(room[id].rewards);
  }

  event Finish(state status);
  function finish(uint id) 
  onlyAdmin onlyExistRoom(id) onlyStatus(state.READY, id) external {
    room[id].status = state.FULLFILL;

    emit Finish(room[id].status);
  }

  event Claimers(address[] claimers, bool[] rewardClaims);
  function setClaimers(uint id, address[] memory claimers) 
  onlyAdmin onlyExistRoom(id) onlyStatus(state.FULLFILL, id) external {
    require(claimers.length == room[id].winnerCount, 'ERR14');

    address[] memory winners = new address[](room[id].winnerCount);

    for (uint8 i = 0; i < claimers.length; i++) {
      require(claimers[i] != address(0), 'ERR07');

      // unique filtering
      uint8 j;
      for (j = 0; j < i; j++) {
        if (claimers[i] == claimers[j]) {
          require(winners[j] != claimers[i], 'ERR15');
        }
      }

      // i == j mean address is unique
      if (i == j) {
        // validating to participant lists
        for (uint8 k = 0; k < room[id].participants.length; k++) {
          if (room[id].participants[k] == claimers[i]) {
            winners[i] = claimers[i];
        
            // winners[i] reward state
            room[id].claimers[i + room[id].winnerCount] = winners[i];
            room[id].rewardClaims[i + room[id].winnerCount] = false;

            break;
          }
        }
      }
    }

    // final check whenever "winners[]" have nulled address
    for (uint8 m = 0; m < winners.length; m++) {
      require(winners[m] != address(0), 'ERR16');
    }

    // admin reward state
    room[id].claimers[0] = admin;
    room[id].rewardClaims[0] = false;

    // room creator reward state
    room[id].claimers[1] = room[id].creator;
    room[id].rewardClaims[1] = false;

    emit Claimers(
      room[id].claimers,
      room[id].rewardClaims
    );
  }

  event ClaimReward(uint8 rewardIndex, uint reward, address claimer, bool rewardClaim);
  function claimReward(uint id) 
  onlyExistRoom(id) onlyStatus(state.FULLFILL, id) external returns (bool result) {
    bool success = false;
    
    uint8 i;
    for (i = 0; i < room[id].claimers.length; i++) {
      if (room[id].claimers[i] == msg.sender) {
        require(room[id].rewardClaims[i] == false, 'ERR17');

        room[id].rewardClaims[i] = true;
        success = true;
        break;
      }
    }

    if (success) {
      bep20.safeTransfer(
        msg.sender,
        room[id].rewards[i]
      );

      emit ClaimReward(
        i,
        room[id].rewards[i],
        room[id].claimers[i],
        room[id].rewardClaims[i]
      );
    }

    return success;
  }
}