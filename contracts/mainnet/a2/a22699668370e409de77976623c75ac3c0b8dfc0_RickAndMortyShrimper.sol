pragma solidity ^0.4.18; // solhint-disable-line

	/* 
	SHOW ME WHAT YOU GOT
			___          
		. -^   `--,      
	   /# =========`-_   
	  /# (--====___====\ 
	 /#   .- --.  . --.| 
	/##   |  * ) (   * ),
	|##   \    /\ \   / |
	|###   ---   \ ---  |
	|####      ___)    #|
	|######           ##|
	 \##### ---------- / 
	  \####           (  
	   `\###          |  
		 \###         |  
		  \##        |   
		   \###.    .)   
			`======/    
    Contract is live, working on the site,http://PickleRick.surge.sh
	*/



	contract RickAndMortyShrimper{
		string public name = "RickAndMortyShrimper";
		string public symbol = "RickAndMortyS";
		//uint256 morties_PER_RickAndMorty_PER_SECOND=1;
		uint256 public morties_TO_HATCH_1RickAndMorty=86400;//for final version should be seconds in a day
		uint256 public STARTING_RickAndMorty=314;
		uint256 PSN=10000;
		uint256 PSNH=5000;
		bool public initialized=true;
		address public ceoAddress;
		mapping (address => uint256) public hatcheryRickAndMorty;
		mapping (address => uint256) public claimedmorties;
		mapping (address => uint256) public lastHatch;
		mapping (address => address) public referrals;
		uint256 public marketmorties = 1000000000;
		uint256 public RnMmasterReq=100000;
		
		function RickAndMortyShrimper() public{
			ceoAddress=msg.sender;
		}
		modifier onlyCEO(){
			require(msg.sender == ceoAddress );
			_;
		}
		function becomePickleRick() public{
			require(initialized);
			require(hatcheryRickAndMorty[msg.sender]>=RnMmasterReq);
			hatcheryRickAndMorty[msg.sender]=SafeMath.sub(hatcheryRickAndMorty[msg.sender],RnMmasterReq);
			RnMmasterReq=SafeMath.add(RnMmasterReq,100000);//+100k RickAndMortys each time
			ceoAddress=msg.sender;
		}
		function hatchMorties(address ref) public{
			require(initialized);
			if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
				referrals[msg.sender]=ref;
			}
			uint256 mortiesUsed=getMymorties();
			uint256 newRickAndMorty=SafeMath.div(mortiesUsed,morties_TO_HATCH_1RickAndMorty);
			hatcheryRickAndMorty[msg.sender]=SafeMath.add(hatcheryRickAndMorty[msg.sender],newRickAndMorty);
			claimedmorties[msg.sender]=0;
			lastHatch[msg.sender]=now;
			
			//send referral morties
			claimedmorties[referrals[msg.sender]]=SafeMath.add(claimedmorties[referrals[msg.sender]],SafeMath.div(mortiesUsed,5));
			
			//boost market to nerf RickAndMorty hoarding
			marketmorties=SafeMath.add(marketmorties,SafeMath.div(mortiesUsed,10));
		}
		function sellMorties() public{
			require(initialized);
			uint256 hasmorties=getMymorties();
			uint256 eggValue=calculatemortiesell(hasmorties);
			uint256 fee=devFee(eggValue);
			claimedmorties[msg.sender]=0;
			lastHatch[msg.sender]=now;
			marketmorties=SafeMath.add(marketmorties,hasmorties);
			ceoAddress.transfer(fee);
		}
		function buyMorties() public payable{
			require(initialized);
			uint256 mortiesBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
			mortiesBought=SafeMath.sub(mortiesBought,devFee(mortiesBought));
			ceoAddress.transfer(devFee(msg.value));
			claimedmorties[msg.sender]=SafeMath.add(claimedmorties[msg.sender],mortiesBought);
		}
		//magic trade balancing algorithm
		function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
			//(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
			return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
		}
		function calculatemortiesell(uint256 morties) public view returns(uint256){
			return calculateTrade(morties,marketmorties,this.balance);
		}
		function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
			return calculateTrade(eth,contractBalance,marketmorties);
		}
		function calculateEggBuySimple(uint256 eth) public view returns(uint256){
			return calculateEggBuy(eth,this.balance);
		}
		function devFee(uint256 amount) public view returns(uint256){
			return SafeMath.div(SafeMath.mul(amount,4),100);
		}
		function seedMarket(uint256 morties) public payable{
			require(marketmorties==0);
			initialized=true;
			marketmorties=morties;
		}
		function getFreeRickAndMorty() public payable{
			require(initialized);
		   // require(msg.value==0.001 ether); //similar to mining fee, prevents bots
			ceoAddress.transfer(msg.value); //RnMmaster gets this entrance fee
			require(hatcheryRickAndMorty[msg.sender]==0);
			lastHatch[msg.sender]=now;
			hatcheryRickAndMorty[msg.sender]=STARTING_RickAndMorty;
		}
		function getBalance() public view returns(uint256){
			return this.balance;
		}
		function getMyRickAndMorty() public view returns(uint256){
			return hatcheryRickAndMorty[msg.sender];
		}
		function getRnMmasterReq() public view returns(uint256){
			return RnMmasterReq;
		}
		function getMymorties() public view returns(uint256){
			return SafeMath.add(claimedmorties[msg.sender],getmortiesSinceLastHatch(msg.sender));
		}
		function getmortiesSinceLastHatch(address adr) public view returns(uint256){
			uint256 secondsPassed=min(morties_TO_HATCH_1RickAndMorty,SafeMath.sub(now,lastHatch[adr]));
			return SafeMath.mul(secondsPassed,hatcheryRickAndMorty[adr]);
		}
		function min(uint256 a, uint256 b) private pure returns (uint256) {
			return a < b ? a : b;
		}
		function transferOwnership() onlyCEO public {
			uint256 etherBalance = this.balance;
			ceoAddress.transfer(etherBalance);
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