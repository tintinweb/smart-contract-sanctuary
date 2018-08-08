pragma solidity ^0.4.19;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}
contract FootBall is Ownable,ERC721{
    using SafeMath for uint256;
    uint public drawFee = 0.05 ether;
    uint public defendFee = 0.01 ether;
    uint public inviteRate = 5;
    uint coolDownTime = 24 hours;
    uint public playerInDraw = 0;
    uint backFee = 75;
    event newPlayer(uint _id,uint16 _attack);
    event drawedPlayer(uint _id,address indexed _to,uint _time);
    event battleLog(uint _playerA,uint _playerB,uint _result,uint _rdId,address indexed _addressA,address indexed _addressB);
    event playerDefend(uint _id,uint _time);
    event playerBack(uint _id , address indexed _address);
    event purChase(uint _id, address _newowner, address _oldowner);
    event inviteBack(address _from,address _to, uint _fee);
    //name&pic store in db;
    struct Player{
        uint256 sellPrice;
        uint256 readytime;
        uint16 attack;
        uint16 winCount;
        uint16 lossCount;
        uint8 isSell;
        uint8 isDraw;
    }
    Player[] public players; 
    mapping(uint=>address) playerToOwner;
    mapping(address=>uint) ownerPlayerCount;
    mapping (uint => address) playerApprovals;
    //modifier
    modifier onlyOwnerOf(uint _id) {
        require(msg.sender == playerToOwner[_id]);
        _;
    }
    //owner draw _money
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    function() payable public{}
    //change fee
    function changeDrawFee(uint _money)public onlyOwner{ 
        drawFee = _money;
    }
    function changeDefendFee(uint _money) public onlyOwner{
        defendFee = _money;
    }
    function changeCoolDownTime(uint _time) public onlyOwner{
        coolDownTime = _time;
    }
    function changeInviteRate(uint _rate) public onlyOwner{
        inviteRate = _rate;
    }
    //create player;
    function createPlayer(uint16 _attack) public onlyOwner{ 
      uint id = players.push (Player(0 ether,0,_attack,0,0,0,0)) - 1;
      playerInDraw = playerInDraw.add(1);
      emit newPlayer(id,_attack);
    }
    //draw card
    function drawPlayer(address _address) public payable returns (uint playerId){
        require(msg.value == drawFee && playerInDraw > 0);
        for(uint i =0;i < players.length;i++){ 
            if(players[i].isDraw == 0){ 
                players[i].isDraw = 1;
                playerInDraw  = playerInDraw.sub(1);
                playerToOwner[i] = msg.sender;
                ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].add(1);
                if(_address != 0){ 
                 uint inviteFee = msg.value * 5 / 100;
                 _address.transfer(inviteFee);
                 emit inviteBack(msg.sender,_address,inviteFee);
                }
                emit drawedPlayer(i,msg.sender,now);
                return i;
            }
        }
    }
    //battle 
    function playerAttack(uint _playerA,uint _playerB) external{
        require(playerToOwner[_playerA] == msg.sender && players[_playerB].isDraw == 1 && playerToOwner[_playerA] != playerToOwner[_playerB]);
        require(now >= players[_playerB].readytime);
        uint rdId = uint256(keccak256(block.difficulty,now))%1000;
        uint attackA;
        uint attackB;
        address ownerOfB = playerToOwner[_playerB];
        if(rdId >= players[_playerA].attack){
            attackA = rdId -  players[_playerA].attack;
        }else{ 
            attackA =  players[_playerA].attack - rdId;
        }
        if(rdId >= players[_playerB].attack){
            attackB =  rdId -  players[_playerB].attack;
        }else{
            attackB =  players[_playerB].attack - rdId;
        }
        uint8 result= 0;
        if(attackA < attackB){
            result = 1;
            playerToOwner[_playerB] = msg.sender;
            ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].add(1);
            ownerPlayerCount[playerToOwner[_playerB]] = ownerPlayerCount[playerToOwner[_playerB]].sub(1);
        }else{ 
            result = 2;
            playerToOwner[_playerA] = playerToOwner[_playerB];
            ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].sub(1);
            ownerPlayerCount[playerToOwner[_playerB]] = ownerPlayerCount[playerToOwner[_playerB]].add(1);
        }
        emit battleLog(_playerA,_playerB,result,rdId,msg.sender,ownerOfB);
    }
    //defend
    function getPlayerDefend(uint _id) public payable{
        require(msg.value == defendFee && msg.sender == playerToOwner[_id]);
        players[_id].readytime = uint256(now + coolDownTime);
        emit playerDefend(_id,players[_id].readytime);
    }
    //sendback
    function sendPlayerBack(uint[] _id) public {
        for(uint i=0;i<_id.length;i++){ 
            uint256 id = _id[i];
            require(playerToOwner[id] == msg.sender);
            uint fee = drawFee * backFee/100;
            //init player info 
            players[id].isDraw = 0;
            players[id].isSell = 0;
            players[id].readytime = 0;
            players[id].sellPrice = 0 ether;
            playerToOwner[id] = 0;
            ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].sub(1);
            playerInDraw  = playerInDraw.add(1);
            if(address(this).balance >= fee){ 
                msg.sender.transfer(fee);    
            }  
            emit playerBack(id,msg.sender);
        }

    }
    //ERC721 functions;
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerPlayerCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return playerToOwner[_tokenId];
    }
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(_from != _to);
        ownerPlayerCount[_to] = ownerPlayerCount[_to].add(1) ;
        ownerPlayerCount[_from] = ownerPlayerCount[_from].sub(1);
        playerToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        playerApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    function takeOwnership(uint256 _tokenId) public {
        require(playerApprovals[_tokenId] == msg.sender && playerToOwner[_tokenId] != msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }
    //market functions
    function setPlayerPrice(uint _id,uint _price) public payable onlyOwnerOf(_id){ 
        require(msg.value == defendFee);
        players[_id].isSell = 1;
        players[_id].sellPrice = _price;
        players[_id].readytime = uint256(now + coolDownTime);
    }
    function playerTakeOff(uint _id) public onlyOwnerOf(_id){
        players[_id].isSell = 0;
    }
    function purchase(uint _id) public payable{
        require(players[_id].isSell == 1 && msg.value == players[_id].sellPrice &&msg.sender != playerToOwner[_id]);
        address owner = playerToOwner[_id];
        ownerPlayerCount[owner] = ownerPlayerCount[owner].sub(1) ;
        ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].add(1);
        playerToOwner[_id] = msg.sender;
        owner.transfer(msg.value);
        emit purChase(_id,msg.sender,owner);
    }
}