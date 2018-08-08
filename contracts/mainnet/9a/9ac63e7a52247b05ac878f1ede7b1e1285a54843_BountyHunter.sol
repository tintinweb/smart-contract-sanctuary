pragma solidity ^0.4.19;

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


contract BountyHunter {

  function() public payable { }

  string public constant NAME = "BountyHunter";
  string public constant SYMBOL = "BountyHunter";
  address ceoAddress = 0xc10A6AedE9564efcDC5E842772313f0669D79497;
  address hunter;
  address hunted;

  struct ContractData {
    address user;
    uint256 hunterPrice;
    uint256 last_transaction;
   
  }

  ContractData[8] data;
  

  
  function BountyHunter() public {
    for (uint i = 0; i < 8; i++) {
     
      data[i].hunterPrice = 5000000000000000;
      data[i].user = msg.sender;
      data[i].last_transaction = block.timestamp;
    }
  }


  function payoutOnPurchase(address previousHunterOwner, uint256 hunterPrice) private {
    previousHunterOwner.transfer(hunterPrice);
  }
  function transactionFee(address, uint256 hunterPrice) private {
    ceoAddress.transfer(hunterPrice);
  }
  function createBounty(uint256 hunterPrice) private {
    this.transfer(hunterPrice);
  }


  
  function hireBountyHunter(uint bountyHunterID) public payable returns (uint, uint) {
    require(bountyHunterID >= 0 && bountyHunterID <= 8);
    
    if ( data[bountyHunterID].hunterPrice == 5000000000000000 ) {
      data[bountyHunterID].hunterPrice = 10000000000000000;
    }
    else { 
      data[bountyHunterID].hunterPrice = data[bountyHunterID].hunterPrice * 2;
    }
    
    require(msg.value >= data[bountyHunterID].hunterPrice * uint256(1));

    createBounty((data[bountyHunterID].hunterPrice / 10) * (3));
    
    payoutOnPurchase(data[bountyHunterID].user,  (data[bountyHunterID].hunterPrice / 10) * (6));
    
    transactionFee(ceoAddress, (data[bountyHunterID].hunterPrice / 10) * (1));

    
    data[bountyHunterID].user = msg.sender;
    
    playerKiller();
    
    return (bountyHunterID, data[bountyHunterID].hunterPrice);

  }


  function getUsers() public view returns (address[], uint256[]) {
    address[] memory users = new address[](8);
    uint256[] memory hunterPrices =  new uint256[](8);
    for (uint i=0; i<8; i++) {
      if (data[i].user != ceoAddress){
        users[i] = (data[i].user);
      }
      else{
        users[i] = address(0);
      }
      
      hunterPrices[i] = (data[i].hunterPrice);
    }
    return (users,hunterPrices);
  }

  function rand(uint max) public returns (uint256){
        
    uint256 lastBlockNumber = block.number - 1;
    uint256 hashVal = uint256(block.blockhash(lastBlockNumber));

    uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
    return uint256(uint256( (hashVal) / FACTOR) + 1) % max;
  }
  
  
  function playerKiller() private {
    uint256 killshot = rand(31);

    if( (killshot < 8) &&  (msg.sender != data[killshot].user) ){
      hunter = msg.sender;
      if( ceoAddress != data[killshot].user){
        hunted = data[killshot].user;
      }
      else{
        hunted = address(0);
      }
      
      data[killshot].hunterPrice  = 5000000000000000;
      data[killshot].user  = 5000000000000000;

      msg.sender.transfer((this.balance / 10) * (9));
      ceoAddress.transfer((this.balance / 10) * (1));

    }
    
  }

  function killFeed() public view returns(address, address){
    return(hunter, hunted);
  }
  
}