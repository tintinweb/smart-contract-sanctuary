pragma solidity ^0.4.18;

/**
 * Etheropoly Board Game without Developer Fee taken out.
 */

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract Etheropoly {

    function buy(address) public payable returns(uint256);
    function transfer(address, uint256) public returns(bool);
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function reinvest() public;
}

/**
 * Definition of contract accepting Etheropoly tokens
 * Games, casinos, anything can reuse this contract to support Etheropoly tokens
 */
contract AcceptsEtheropoly {
    Etheropoly public tokenContract;

    function AcceptsEtheropoly(address _tokenContract) public {
        tokenContract = Etheropoly(_tokenContract);
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

// 50 Tokens, seeded market of 8640000000 Eggs
contract EtheropolyShrimpFarmer is AcceptsEtheropoly {
    //uint256 EGGS_PER_SHRIMP_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400;//for final version should be seconds in a day
    uint256 public STARTING_SHRIMP=300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;

    function EtheropolyShrimpFarmer(address _baseContract)
      AcceptsEtheropoly(_baseContract)
      public{
        ceoAddress=msg.sender;
    }

    /**
     * Fallback function for the contract if sent ethereum by mistake
     */
    function() payable public {
        ceoAddress.transfer(msg.value);
      /* revert(); */
    }

    /**
    * Deposit Etheropoly tokens to buy eggs in farm
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
        require(initialized);
        require(!_isContract(_from));
        require(_value >= 1 finney); // 0.001 OPOLY token

        uint256 EtheropolyBalance = tokenContract.myTokens();

        uint256 eggsBought=calculateEggBuy(_value, SafeMath.sub(EtheropolyBalance, _value));
        reinvest();
        claimedEggs[_from]=SafeMath.add(claimedEggs[_from],eggsBought);

        return true;
    }

    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newShrimp=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender]=SafeMath.add(hatcheryShrimp[msg.sender],newShrimp);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;

        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));

        //boost market to nerf shrimp hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
    }

    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        reinvest();
        tokenContract.transfer(msg.sender, eggValue);
    }

    // Dev should initially seed the game before start
    function seedMarket(uint256 eggs) public {
        require(marketEggs==0);
        require(msg.sender==ceoAddress); // only CEO can seed the market
        initialized=true;
        marketEggs=eggs;
    }

    // Reinvest Etheropoly Shrimp Farm dividends
    // All the dividends this contract makes will be used to grow token fund for players
    // of the Etheropoly Schrimp Farm
    function reinvest() public {
       if(tokenContract.myDividends(true) > 1) {
         tokenContract.reinvest();
       }
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    // Calculate trade to sell eggs
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs, tokenContract.myTokens());
    }

    // Calculate trade to buy eggs
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    // Calculate eggs to buy simple
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth, tokenContract.myTokens());
    }

    // Get amount of Shrimps user has
    function getMyShrimp() public view returns(uint256){
        return hatcheryShrimp[msg.sender];
    }

    // Get amount of eggs of current user
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }

    // Get number of doges since last hatch
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SHRIMP,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryShrimp[adr]);
    }

    // Collect information about doge farm dividends amount
    function getContractDividends() public view returns(uint256) {
      return tokenContract.myDividends(true); // + this.balance;
    }

    // Get tokens balance of the doge farm
    function getBalance() public view returns(uint256){
        return tokenContract.myTokens();
    }

    // Check transaction coming from the contract or not
    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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