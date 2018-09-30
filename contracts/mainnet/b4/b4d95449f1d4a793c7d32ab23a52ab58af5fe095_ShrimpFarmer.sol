pragma solidity ^0.4.18; // solhint-disable-line



contract VerifyToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    bool public activated;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
contract EthVerifyCore{
  mapping (address => bool) public verifiedUsers;
}
contract ShrimpFarmer is ApproveAndCallFallBack{
    using SafeMath for uint;
    address vrfAddress=0x5BD574410F3A2dA202bABBa1609330Db02aD64C2;
    VerifyToken vrfcontract=VerifyToken(vrfAddress);

    //257977574257854071311765966
    //                10000000000
    //uint256 EGGS_PER_SHRIMP_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400;//86400
    uint public VRF_EGG_COST=(1000000000000000000*300)/EGGS_TO_HATCH_1SHRIMP;
    uint256 public STARTING_SHRIMP=300;
    uint256 PSN=100000000000000;
    uint256 PSNH=50000000000000;
    uint public potDrainTime=2 hours;//
    uint public POT_DRAIN_INCREMENT=1 hours;
    uint public POT_DRAIN_MAX=3 days;
    uint public HATCH_COOLDOWN_MAX=6 hours;//6 hours;
    bool public initialized=false;
    //bool public completed=false;

    address public ceoAddress;
    address public dev2;
    mapping (address => uint256) public hatchCooldown;//the amount of time you must wait now varies per user
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => bool) public hasClaimedFree;
    uint256 public marketEggs;
    EthVerifyCore public ethVerify=EthVerifyCore(0x1c307A39511C16F74783fCd0091a921ec29A0b51);

    uint public lastBidTime;//last time someone bid for the pot
    address public currentWinner;
    uint public potEth=0;//eth specifically set aside for the pot
    uint public totalHatcheryShrimp=0;
    uint public prizeEth=0;

    function ShrimpFarmer() public{
        ceoAddress=msg.sender;
        dev2=address(0x95096780Efd48FA66483Bc197677e89f37Ca0CB5);
        lastBidTime=now;
        currentWinner=msg.sender;
    }
    function finalizeIfNecessary() public{
      if(lastBidTime.add(potDrainTime)<now){
        currentWinner.transfer(this.balance);//winner gets everything
        initialized=false;
        //completed=true;
      }
    }
    function getPotCost() public view returns(uint){
        return totalHatcheryShrimp.div(100);
    }
    function stealPot() public {

      if(initialized){
          _hatchEggs(0);
          uint cost=getPotCost();
          hatcheryShrimp[msg.sender]=hatcheryShrimp[msg.sender].sub(cost);//cost is 1% of total shrimp
          totalHatcheryShrimp=totalHatcheryShrimp.sub(cost);
          setNewPotWinner();
          hatchCooldown[msg.sender]=0;
      }
    }
    function setNewPotWinner() private {
      finalizeIfNecessary();
      if(initialized && msg.sender!=currentWinner){
        potDrainTime=lastBidTime.add(potDrainTime).sub(now).add(POT_DRAIN_INCREMENT);//time left plus one hour
        if(potDrainTime>POT_DRAIN_MAX){
          potDrainTime=POT_DRAIN_MAX;
        }
        lastBidTime=now;
        currentWinner=msg.sender;
      }
    }
    function isHatchOnCooldown() public view returns(bool){
      return lastHatch[msg.sender].add(hatchCooldown[msg.sender])<now;
    }
    function hatchEggs(address ref) public{
      require(isHatchOnCooldown());
      _hatchEggs(ref);
    }
    function _hatchEggs(address ref) private{
        require(initialized);

        uint256 eggsUsed=getMyEggs();
        uint256 newShrimp=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender]=SafeMath.add(hatcheryShrimp[msg.sender],newShrimp);
        totalHatcheryShrimp=totalHatcheryShrimp.add(newShrimp);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        hatchCooldown[msg.sender]=HATCH_COOLDOWN_MAX;
        //send referral eggs
        require(ref!=msg.sender);
        if(ref!=0){
          claimedEggs[ref]=claimedEggs[ref].add(eggsUsed.div(7));
        }
        //boost market to nerf shrimp hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,7));
    }
    function getHatchCooldown(uint eggs) public view returns(uint){
      uint targetEggs=marketEggs.div(50);
      if(eggs>=targetEggs){
        return HATCH_COOLDOWN_MAX;
      }
      return (HATCH_COOLDOWN_MAX.mul(eggs)).div(targetEggs);
    }
    function reduceHatchCooldown(address addr,uint eggs) private{
      uint reduction=getHatchCooldown(eggs);
      if(reduction>=hatchCooldown[addr]){
        hatchCooldown[addr]=0;
      }
      else{
        hatchCooldown[addr]=hatchCooldown[addr].sub(reduction);
      }
    }
    function sellEggs() public{
        require(initialized);
        finalizeIfNecessary();
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        //uint256 fee=devFee(eggValue);
        uint potfee=potFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        //ceoAddress.transfer(fee);
        prizeEth=prizeEth.add(potfee);
        msg.sender.transfer(eggValue.sub(potfee));
    }
    function buyEggs() public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought=eggsBought.sub(devFee(eggsBought));
        eggsBought=eggsBought.sub(devFee2(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        dev2.transfer(devFee2(msg.value));
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        reduceHatchCooldown(msg.sender,eggsBought); //reduce the hatching cooldown based on eggs bought

        //steal the pot if bought enough
        uint potEggCost=getPotCost().mul(EGGS_TO_HATCH_1SHRIMP);//the equivalent number of eggs to the pot cost in shrimp
        if(eggsBought>potEggCost){
          //hatcheryShrimp[msg.sender]=hatcheryShrimp[msg.sender].add(getPotCost());//to compensate for the shrimp that will be lost when calling the following
          //stealPot();
          setNewPotWinner();
        }
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,this.balance.sub(prizeEth));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance.sub(prizeEth),marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,this.balance);
    }
    function potFee(uint amount) public view returns(uint){
        return SafeMath.div(SafeMath.mul(amount,20),100);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function devFee2(uint256 amount) public view returns(uint256){
        return SafeMath.div(amount,100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(msg.sender==ceoAddress);
        require(!initialized);
        //require(marketEggs==0);
        initialized=true;
        marketEggs=eggs;
        lastBidTime=now;
    }
    //Tokens are exchanged for shrimp by sending them to this contract with ApproveAndCall
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public{
        require(!initialized);
        require(msg.sender==vrfAddress);
        require(ethVerify.verifiedUsers(from));//you must now be verified for this
        require(claimedEggs[from].add(tokens.div(VRF_EGG_COST))<=1001*EGGS_TO_HATCH_1SHRIMP);//you may now trade for a max of 1000 eggs
        vrfcontract.transferFrom(from,this,tokens);
        claimedEggs[from]=claimedEggs[from].add(tokens.div(VRF_EGG_COST));
    }
    //allow sending eth to the contract
    function () public payable {}

    function claimFreeEggs() public{
//  RE ENABLE THIS BEFORE DEPLOYING MAINNET
        require(ethVerify.verifiedUsers(msg.sender));
        require(initialized);
        require(!hasClaimedFree[msg.sender]);
        claimedEggs[msg.sender]=claimedEggs[msg.sender].add(getFreeEggs());
        _hatchEggs(0);
        hatchCooldown[msg.sender]=0;
        hasClaimedFree[msg.sender]=true;
        //require(hatcheryShrimp[msg.sender]==0);
        //lastHatch[msg.sender]=now;
        //hatcheryShrimp[msg.sender]=hatcheryShrimp[msg.sender].add(STARTING_SHRIMP);
    }
    function getFreeEggs() public view returns(uint){
        return min(calculateEggBuySimple(this.balance.div(400)),calculateEggBuySimple(0.01 ether));
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyShrimp() public view returns(uint256){
        return hatcheryShrimp[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SHRIMP,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryShrimp[adr]);
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