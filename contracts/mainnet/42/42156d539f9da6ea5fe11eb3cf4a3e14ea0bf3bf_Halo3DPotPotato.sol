pragma solidity ^0.4.18; // solhint-disable-line

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract Halo3D {

    function buy(address) public payable returns(uint256);
    function transfer(address, uint256) public returns(bool);
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function reinvest() public;
}

/**
 * Definition of contract accepting Halo3D tokens
 * Games, casinos, anything can reuse this contract to support Halo3D tokens
 */
contract AcceptsHalo3D {
    Halo3D public tokenContract;

    function AcceptsHalo3D(address _tokenContract) public {
        tokenContract = Halo3D(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Halo3DPotPotato is AcceptsHalo3D {
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
    uint256 public START_PRICE=10 ether; // 10 TOKENS
    uint256 public CONTEST_INTERVAL= 1 days;//4 minutes;//1 week

    /*** DATATYPES ***/
    struct Potato {
        address owner;
        uint256 price;
    }

    /*** CONSTRUCTOR ***/
    function Halo3DPotPotato(address _baseContract)
      AcceptsHalo3D(_baseContract)
      public{
        ceoAddress=msg.sender;
        hotPotatoHolder=0;
        contestStartTime=now;
        for(uint i = 0; i<NUM_POTATOES; i++){
            Potato memory newpotato=Potato({owner:address(this),price: START_PRICE});
            potatoes.push(newpotato);
        }
    }
    
     /**
     * Fallback function for the contract, protect investors
     * NEED ALWAYS TO HAVE
     */
    function() payable public {
      // Not accepting Ether directly
      /* revert(); */
    }

    /*** PUBLIC FUNCTIONS ***/
    /**
    * Deposit Halo3D tokens to buy potato
    *
    * @dev Standard ERC677 function that will handle incoming token transfers.
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data)
      external
      onlyTokenContract
      returns (bool) {
        require(now > contestStartTime);
        require(!_isContract(_from));
        if(_endContestIfNeeded(_from, _value)){

        }
        else{
            // Byte data to index how to transfer?
            uint64 index = uint64(_data[0]);
            Potato storage potato=potatoes[index];
            require(_value >= potato.price);
            //allow calling transfer() on these addresses without risking re-entrancy attacks
            require(_from != potato.owner);
            require(_from != ceoAddress);
            uint256 sellingPrice=potato.price;
            uint256 purchaseExcess = SafeMath.sub(_value, sellingPrice);
            uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 76), 100));
            uint256 devFee= uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));
            //20 percent remaining in the contract goes to the pot
            //if the owner is the contract, this is the first purchase, and payment should go to the pot
            reinvest();
            if(potato.owner!=address(this)){
                tokenContract.transfer(potato.owner, payment);
            }
            tokenContract.transfer(ceoAddress, devFee);
            potato.price= SafeMath.div(SafeMath.mul(sellingPrice, 150), 76);
            potato.owner=_from;//transfer ownership
            hotPotatoHolder=_from;//becomes holder with potential to win the pot
            lastBidTime=now;
            TIME_TO_COOK=SafeMath.add(BASE_TIME_TO_COOK,SafeMath.mul(index,TIME_MULTIPLIER)); //pots have times to cook varying from 30-85 minutes

            tokenContract.transfer(_from, purchaseExcess); //returns excess eth
        }

        return true;
    }


    // Reinvest Halo3D PotPotato dividends
    // All the dividends this contract makes will be used to grow token fund for players
    // of the Halo3D PotPotato Game
    function reinvest() public {
       if(tokenContract.myDividends(true) > 1) {
         tokenContract.reinvest();
       }
       /*
       uint balance = address(this).balance;
       if (balance > 1) {
         tokenContract.buy.value(balance).gas(1000000)(msg.sender);
       } */ // Not possible because of contract protection
    }

    // Collect information about Halo3dPotPotato dividents amount
    function getContractDividends() public view returns(uint256) {
      return tokenContract.myDividends(true); // + this.balance;
    }

    // Get tokens balance of the Halo3D PotPotato
    function getBalance() public view returns(uint256 value){
        return tokenContract.myTokens();
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
    // Check transaction coming from the contract or not
    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function _endContestIfNeeded(address _from, uint256 _value) private returns(bool){
        if(timePassed()>=TIME_TO_COOK){
            //contest over, refund anything paid
            reinvest();
            tokenContract.transfer(_from, _value);
            lastPot=getBalance();
            lastHotPotatoHolder=hotPotatoHolder;
            tokenContract.transfer(hotPotatoHolder, tokenContract.myTokens());
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
        while(start < now){
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