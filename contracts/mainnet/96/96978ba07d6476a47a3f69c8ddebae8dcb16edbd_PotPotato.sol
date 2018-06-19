pragma solidity ^0.4.18; // solhint-disable-line



contract PotPotato{
    address public ceoAddress;
    address public hotPotatoHolder;
    address public lastHotPotatoHolder;
    uint256 public lastBidTime;
    uint256 public contestStartTime;
    uint256 public lastPot;

    Potato[] public potatoes;
    
    uint256 public BASE_TIME_TO_COOK=30 minutes;//60 seconds;
    uint256 public TIME_MULTIPLIER=5 minutes;//5 seconds;//time per index of potato
    uint256 public TIME_TO_COOK=BASE_TIME_TO_COOK; //this changes
    uint256 public NUM_POTATOES=12;
    uint256 public START_PRICE=0.001 ether;
    uint256 public CONTEST_INTERVAL=1 weeks;//4 minutes;//1 week
    
    /*** DATATYPES ***/
    struct Potato {
        address owner;
        uint256 price;
    }
    
    /*** CONSTRUCTOR ***/
    function PotPotato() public{
        ceoAddress=msg.sender;
        hotPotatoHolder=0;
        contestStartTime=1520799754;//sunday march 11
        for(uint i = 0; i<NUM_POTATOES; i++){
            Potato memory newpotato=Potato({owner:address(this),price: START_PRICE});
            potatoes.push(newpotato);
        }
    }
    
    /*** PUBLIC FUNCTIONS ***/
    function buyPotato(uint256 index) public payable{
        require(block.timestamp>contestStartTime);
        if(_endContestIfNeeded()){ 

        }
        else{
            Potato storage potato=potatoes[index];
            require(msg.value >= potato.price);
            //allow calling transfer() on these addresses without risking re-entrancy attacks
            require(msg.sender != potato.owner);
            require(msg.sender != ceoAddress);
            uint256 sellingPrice=potato.price;
            uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
            uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 76), 100));
            uint256 devFee= uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));
            //20 percent remaining in the contract goes to the pot
            //if the owner is the contract, this is the first purchase, and payment should go to the pot
            if(potato.owner!=address(this)){
                potato.owner.transfer(payment);
            }
            ceoAddress.transfer(devFee);
            potato.price= SafeMath.div(SafeMath.mul(sellingPrice, 150), 76);
            potato.owner=msg.sender;//transfer ownership
            hotPotatoHolder=msg.sender;//becomes holder with potential to win the pot
            lastBidTime=block.timestamp;
            TIME_TO_COOK=SafeMath.add(BASE_TIME_TO_COOK,SafeMath.mul(index,TIME_MULTIPLIER)); //pots have times to cook varying from 30-85 minutes
            msg.sender.transfer(purchaseExcess);//returns excess eth
        }
    }
    
    function getBalance() public view returns(uint256 value){
        return this.balance;
    }
    function timePassed() public view returns(uint256 time){
        if(lastBidTime==0){
            return 0;
        }
        return SafeMath.sub(block.timestamp,lastBidTime);
    }
    function timeLeftToContestStart() public view returns(uint256 time){
        if(block.timestamp>contestStartTime){
            return 0;
        }
        return SafeMath.sub(contestStartTime,block.timestamp);
    }
    function timeLeftToCook() public view returns(uint256 time){
        return SafeMath.sub(TIME_TO_COOK,timePassed());
    }
    function contestOver() public view returns(bool){
        return timePassed()>=TIME_TO_COOK;
    }
    
    /*** PRIVATE FUNCTIONS ***/
    function _endContestIfNeeded() private returns(bool){
        if(timePassed()>=TIME_TO_COOK){
            //contest over, refund anything paid
            msg.sender.transfer(msg.value);
            lastPot=this.balance;
            lastHotPotatoHolder=hotPotatoHolder;
            hotPotatoHolder.transfer(this.balance);
            hotPotatoHolder=0;
            lastBidTime=0;
            _resetPotatoes();
            _setNewStartTime();
            return true;
        }
        return false;
    }
    function _resetPotatoes() private{
        for(uint i = 0; i<NUM_POTATOES; i++){
            Potato memory newpotato=Potato({owner:address(this),price: START_PRICE});
            potatoes[i]=newpotato;
        }
    }
    function _setNewStartTime() private{
        uint256 start=contestStartTime;
        while(start<block.timestamp){
            start=SafeMath.add(start,CONTEST_INTERVAL);
        }
        contestStartTime=start;
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