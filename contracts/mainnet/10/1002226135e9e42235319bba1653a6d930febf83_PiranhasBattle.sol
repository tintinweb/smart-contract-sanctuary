pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Payments {
  mapping(address => uint256) public payments; 
  
  function getBalance() public constant returns(uint256) {
	 return payments[msg.sender];
  }    

  function withdrawPayments() public {
	address payee = msg.sender;
	uint256 payment = payments[payee];

	require(payment != 0);
	require(this.balance >= payment);

	payments[payee] = 0;

	assert(payee.send(payment));
  }  
    
}

contract ERC721 {
  function totalSupply() constant returns (uint256);
  function ownerOf(uint256) constant returns (address);
}


contract PiranhasBattle is Ownable, Payments  {

  using SafeMath for uint256;
  

  mapping(uint256 => mapping(uint256 => uint256)) public fightersToBattle; //unique pair of the fighters
  mapping(uint256 => mapping(uint256 => uint256)) public battleToFighterToSize; //fighters sizes
  mapping(uint256 => mapping(uint256 => uint256)) public battleToFighterToBet; // Bets summ in power points

  mapping(uint256 => uint256) public battleToWinner; 
  
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public addressToBattleToFigterIdToBetPower;  
  
  uint256 public battleId;


  address[][] public betsOnFighter;
  

  
  ERC721 piranhas = ERC721(0x2B434a1B41AFE100299e5Be39c4d5be510a6A70C); 
  
  function piranhasTotalSupply() constant returns (uint256)  {
      return piranhas.totalSupply();
  }

  function ownerOfPiranha(uint256 _piranhaId) constant returns (address)  {
      return piranhas.ownerOf(_piranhaId);
  }
  
  function theBet(uint256 _piranhaFighter1, uint256 _piranhaFighter2, uint256 _betOnFighterId) public payable {
     
	  require (_piranhaFighter1 > 0 && _piranhaFighter2 > 0 && _piranhaFighter1 != _piranhaFighter2);
	  
	  uint256 curBattleId=fightersToBattle[_piranhaFighter1][_piranhaFighter2];
      require (battleToWinner[curBattleId] == 0); //battle not finished	  
	  
	  require (msg.value >= 0.001 ether && msg.sender != address(0));
	  
	  if (curBattleId == 0) { //new battle
 	      battleId = betsOnFighter.push([msg.sender]); //add gamer to the battle
		  fightersToBattle[_piranhaFighter1][_piranhaFighter2] = battleId;
		  battleToFighterToSize[battleId][_piranhaFighter1]=240; 
		  battleToFighterToSize[battleId][_piranhaFighter2]=240; 
	  } else {
	        if (addressToBattleToFigterIdToBetPower[msg.sender][battleId][_piranhaFighter1]==0 && addressToBattleToFigterIdToBetPower[msg.sender][battleId][_piranhaFighter2]==0)
				betsOnFighter[battleId-1].push(msg.sender); //add gamer to the battle
	  }
	  
	  uint256 fighter1Size = battleToFighterToSize[battleId][_piranhaFighter1];
	  uint256 fighter2Size = battleToFighterToSize[battleId][_piranhaFighter2];
	  uint256 theBetPower = SafeMath.div(msg.value,1000000000000000); 
	  
	  battleToFighterToBet[battleId][_betOnFighterId] += theBetPower;
	  
	  addressToBattleToFigterIdToBetPower[msg.sender][battleId][_betOnFighterId] += theBetPower;
	  
	  uint8 randNum = uint8(block.blockhash(block.number-1))%2;
	  
	  if (randNum==0) { //fighter1 the winner

			if ( fighter1Size+theBetPower >= 240) 
				battleToFighterToSize[battleId][_piranhaFighter1] = 240;
			else 
				battleToFighterToSize[battleId][_piranhaFighter1] += theBetPower;
				
	        if ( fighter2Size <= theBetPower) {
				battleToFighterToSize[battleId][_piranhaFighter2] = 0;
				_finishTheBattle(battleId, _piranhaFighter1, _piranhaFighter2, 1);
				
			}
			else 
				battleToFighterToSize[battleId][_piranhaFighter2] -= theBetPower;	
				
	  } else { //fighter2 the winner
			if ( fighter2Size+theBetPower >= 240) 
				battleToFighterToSize[battleId][_piranhaFighter2] = 240;
			else 
				battleToFighterToSize[battleId][_piranhaFighter2] += theBetPower;
				
	        if ( fighter1Size <= theBetPower) {
				battleToFighterToSize[battleId][_piranhaFighter1] = 0;
				_finishTheBattle(battleId, _piranhaFighter1, _piranhaFighter2, 2);
				
			}
			else 
				battleToFighterToSize[battleId][_piranhaFighter1] -= theBetPower;		        
	  }
	  
  }
  
  function _finishTheBattle (uint256 _battleId, uint256 _piranhaFighter1, uint256 _piranhaFighter2, uint8 _winner) private { 
  
	    uint256 winnerId=_piranhaFighter1;
		uint256 looserId=_piranhaFighter2;
		if (_winner==2) {
			winnerId=_piranhaFighter2;
			looserId=_piranhaFighter1;
			battleToWinner[_battleId]=_piranhaFighter2;
		} else {
			battleToWinner[_battleId]=_piranhaFighter1;
		}

		uint256 winPot=battleToFighterToBet[_battleId][looserId]*900000000000000; //90% in wei
		uint256 divsForPiranhaOwner=battleToFighterToBet[_battleId][looserId]*100000000000000; //10% in wei
		
		uint256 prizeUnit = uint256((battleToFighterToBet[_battleId][winnerId] * 1000000000000000 + winPot)  / battleToFighterToBet[_battleId][winnerId]);
		
		for (uint256 i=0; i < betsOnFighter[_battleId-1].length; i++) {
			if (addressToBattleToFigterIdToBetPower[betsOnFighter[_battleId-1][i]][_battleId][winnerId] != 0)
				payments[betsOnFighter[_battleId-1][i]] += prizeUnit * addressToBattleToFigterIdToBetPower[betsOnFighter[_battleId-1][i]][_battleId][winnerId];
		}
		
		if (divsForPiranhaOwner>0) {
			address piranhaOwner=ownerOfPiranha(winnerId);
			if (piranhaOwner!=address(0))
				piranhaOwner.send(divsForPiranhaOwner);
		}
		 
  }
  
}