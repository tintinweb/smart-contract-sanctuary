pragma solidity ^0.4.8;

contract RuletkaIo {
    
    /*** EVENTS ***/
    
    /// @dev A russian Roulette has been executed between 6 players
    /// in room roomId and unfortunately, victim got shot and didn&#39;t 
    /// make it out alive... RIP
    event partyOver(uint256 roomId, address victim, address[] winners);

    /// @dev A new player has enter a room
    event newPlayer(uint256 roomId, address player);
    
    /// @dev A room is full, we close the door. Game can start.
    event fullRoom(uint256 roomId);
    
    /// @dev A safety mechanism has been triggered to empty the room and refund entirely the players (Should never happen)
    event  roomRefunded(uint256 _roomId, address[] refundedPlayers);

    /*** Founders addresses ***/
    address CTO;
    address CEO;
    
     Room[] private allRooms;

    function () public payable {} // Give the ability of receiving ether

    function RuletkaIo() public {
        CTO = msg.sender;
        CEO = msg.sender;
    }
    
    /*** ACCESS MODIFIERS ***/
    /// @dev Access modifier for CTO-only functionality
    modifier onlyCTO() {
        require(msg.sender == CTO);
        _;
    }
    
    /// @dev Assigns a new address to act as the CTO.
    /// @param _newCTO The address of the new CTO
    function setCTO(address _newCTO) public onlyCTO {
        require(_newCTO != address(0));
        CTO = _newCTO;
    }
    
    /// @dev Assigns a new address to act as the CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) public onlyCTO {
        require(_newCEO != address(0));
        CEO = _newCEO;
    }
    
    /*** DATATYPES ***/
      struct Room {
        string name;
        uint256 entryPrice; //  The price to enter the room and play Russian Roulette
        uint256 balance;
        address[] players;
      }
    
    
    /// For creating Room
  function createRoom(string _name, uint256 _entryPrice) public onlyCTO{
    address[] memory players;
    Room memory _room = Room({
      name: _name,
      players: players,
      balance: 0,
      entryPrice: _entryPrice
    });

    allRooms.push(_room);
  }
    
    function enter(uint256 _roomId) public payable {
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn&#39;t exist in array, exits.
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        room.players.push(msg.sender);
        room.balance += room.entryPrice;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            executeRoom(_roomId);
        }
    }
    
    function enterWithReferral(uint256 _roomId, address referrer) public payable {
        
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn&#39;t exist in array, exits.
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        uint256 referrerCut = SafeMath.div(room.entryPrice, 100); // Referrer get one percent of the bet as reward
        referrer.transfer(referrerCut);
         
        room.players.push(msg.sender);
        room.balance += room.entryPrice - referrerCut;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            emit fullRoom(_roomId);
            executeRoom(_roomId);
        }
    }
    
    function executeRoom(uint256 _roomId) public {
        
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn&#39;t exist in array, exits.
        
        //Check if the room is really full before shooting people...
        require(room.players.length == 6);
        
        uint256 halfFee = SafeMath.div(room.entryPrice, 20);
        CTO.transfer(halfFee);
        CEO.transfer(halfFee);
        room.balance -= halfFee * 2;
        
        uint256 deadSeat = random();
        
        distributeFunds(_roomId, deadSeat);
        
        delete room.players;
    }
    
    function distributeFunds(uint256 _roomId, uint256 _deadSeat) private returns(uint256) {
        
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn&#39;t exist in array, exits.
        uint256 balanceToDistribute = SafeMath.div(room.balance,5);
        
        address victim = room.players[_deadSeat];
        address[] memory winners = new address[](5);
        uint256 j = 0; 
        for (uint i = 0; i<6; i++) {
            if(i != _deadSeat){
               room.players[i].transfer(balanceToDistribute);
               room.balance -= balanceToDistribute;
               winners[j] = room.players[i];
               j++;
            }
        }
        
        emit partyOver(_roomId, victim, winners);
       
        return address(this).balance;
    }
    
     /// @dev Empty the room and refund each player. Safety mechanism which shouldn&#39;t be used.
    /// @param _roomId The Room id to empty and refund
    function refundPlayersInRoom(uint256 _roomId) public onlyCTO{
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn&#39;t exist in array, exits.
        uint256 nbrOfPlayers = room.players.length;
        uint256 balanceToRefund = SafeMath.div(room.balance,nbrOfPlayers);
        for (uint i = 0; i<nbrOfPlayers; i++) {
             room.players[i].transfer(balanceToRefund);
             room.balance -= balanceToRefund;
        }
        
        emit roomRefunded(_roomId, room.players);
        delete room.players;
    }
    
    
    /// @dev A clean and efficient way to generate random and make sure that it
    /// will remain the same accross the executing nodes of random value 
    /// Ethereum Blockchain. We base our computation on the block.timestamp
    /// and difficulty which will remain the same accross the nodes to ensure
    /// same result for the same execution.
    function random() private view returns (uint256) {
        return uint256(uint256(keccak256(block.timestamp, block.difficulty))%6);
    }
    
    function getRoom(uint256 _roomId) public view returns (
    string name,
    address[] players,
    uint256 entryPrice,
    uint256 balance
  ) {
    Room storage room = allRooms[_roomId-1];
    name = room.name;
    players = room.players;
    entryPrice = room.entryPrice;
    balance = room.balance;
  }
  
  function payout(address _to) public onlyCTO {
    _payout(_to);
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      CTO.transfer(SafeMath.div(address(this).balance, 2));
      CEO.transfer(address(this).balance);
    } else {
      _to.transfer(address(this).balance);
    }
  }
  
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}