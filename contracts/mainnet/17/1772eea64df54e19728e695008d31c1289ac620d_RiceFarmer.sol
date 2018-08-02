pragma solidity ^0.4.18; // solhint-disable-line

//==============================================================================
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================

interface Lucky8DInterface {
    function redistribution() external payable;
}

contract RiceFarmer{

    uint256 public SEEDS_TO_HATCH_1RICE=86400;//for final version should be seconds in a day
    uint256 public STARTING_RICE=300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryRice;
    mapping (address => uint256) public claimedSeeds;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketSeeds;


    Lucky8DInterface constant private Divies = Lucky8DInterface(0xe7BBBC53d2D1B9e1099BeF0E3E2F2C74cd1D2B98);


    function RiceFarmer() public{
        ceoAddress=msg.sender;
    }


    function hatchSeeds(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMySeeds();
        uint256 newRice=SafeMath.div(eggsUsed,SEEDS_TO_HATCH_1RICE);
        hatcheryRice[msg.sender]=SafeMath.add(hatcheryRice[msg.sender],newRice);
        claimedSeeds[msg.sender]=0;
        lastHatch[msg.sender]=now;

        //send referral eggs
        claimedSeeds[referrals[msg.sender]]=SafeMath.add(claimedSeeds[referrals[msg.sender]],SafeMath.div(eggsUsed,5));

        //boost market to nerf rice hoarding
        marketSeeds=SafeMath.add(marketSeeds,SafeMath.div(eggsUsed,10));
    }
    function sellSeeds() public{
        require(initialized);
        uint256 hasSeeds=getMySeeds();
        uint256 eggValue=calculateSeedSell(hasSeeds);
        uint256 fee=devFee(eggValue);
        claimedSeeds[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketSeeds=SafeMath.add(marketSeeds,hasSeeds);

        Divies.redistribution.value(fee)();

        msg.sender.transfer(SafeMath.sub(eggValue,fee));
    }
    function buySeeds() public payable{
        require(initialized);
        uint256 eggsBought=calculateSeedBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));

        Divies.redistribution.value(devFee(msg.value))();

        claimedSeeds[msg.sender]=SafeMath.add(claimedSeeds[msg.sender],eggsBought);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateSeedSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketSeeds,this.balance);
    }
    function calculateSeedBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketSeeds);
    }
    function calculateSeedBuySimple(uint256 eth) public view returns(uint256){
        return calculateSeedBuy(eth,this.balance);
    }

    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }

    function seedMarket(uint256 eggs) public payable{
        require(marketSeeds==0);
        initialized=true;
        marketSeeds=eggs;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyRice() public view returns(uint256){
        return hatcheryRice[msg.sender];
    }
    function getMySeeds() public view returns(uint256){
        return SafeMath.add(claimedSeeds[msg.sender],getSeedsSinceLastHatch(msg.sender));
    }
    function getSeedsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(SEEDS_TO_HATCH_1RICE,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryRice[adr]);
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