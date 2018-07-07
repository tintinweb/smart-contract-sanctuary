pragma solidity ^0.4.8;

contract RuletkaTestIo {
    
    /*** EVENTS ***/
    
    /// @dev A russian Roulette has been executed between 6 players
    /// in room roomId and unfortunately, victim got shot and didn&#39;t 
    /// make it out alive... RIP
    event partyOver(uint256 roomId, address victim, address[] winners);

    /// @dev A new player has enter a room
    event newPlayer(uint256 roomId, address player);
    
    /// @dev A room is full, we close the door. Game can start.
    event fullRoom(uint256 roomId);

    /*** Founders addresses ***/
    address CTO;
    address CEO;
    
     Room[] private allRooms;
     
     function () public payable {} // Give the ability of receiving ether

         
     // @dev A mapping from owner address to count of precious that address owns.
     //  Used internally inside balanceOf() to resolve ownership count.
     mapping (address => uint256) private playersToParty;

    function RuletkaTestIo() public {
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
        string name;  // Edition name like &#39;Monroe&#39;
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
    for(int i=0; i<5; i++){
        address(this).call.value(_entryPrice).gas(200000)(abi.encodeWithSignature(&quot;enter(uint256)&quot;,  allRooms.length-1));
    }
  }
    
    function enter(uint256 _roomId) public payable {
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn&#39;t exist in array, exits.
        
        if(!(msg.sender == CTO || msg.sender == address(this))){
            require(isEligibleToPlay(msg.sender));
        }
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        room.players.push(msg.sender);
        room.balance += room.entryPrice;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            executeRoom(_roomId);
        }
        
        uint256 value = playersToParty[msg.sender];
        playersToParty[msg.sender] = value + 1;
    }
    
    function enterWithReferral(uint256 _roomId, address referrer) public payable {
        
        
        if(!(msg.sender == CTO || msg.sender == address(this))){
            require(isEligibleToPlay(msg.sender));
        }
        
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
        
        uint256 value = playersToParty[msg.sender];
        playersToParty[msg.sender] = value + 1;
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
        
        for(int i=0; i<5; i++){
            address(this).call.value(room.entryPrice).gas(200000)(abi.encodeWithSignature(&quot;enter(uint256)&quot;,  _roomId));
        }
    }
    
    function isEligibleToPlay(address _player) public view returns (bool result) {
        if(playersToParty[_player] >= 3){
            result = false;
        }else{
            result = true;
        }
            return result;
    }
    
    
    function getNbrOfPartyFor(address _player) public view returns (uint256 result) {
        return playersToParty[_player];
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