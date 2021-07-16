//SourceUnit: tronspot.sol

pragma solidity ^0.4.25;

contract TronSpot {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 50000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint public totalWithdraw = 0;
    bool public stabilized = true;
  
    uint private releaseTime = 1593702000;   
    

    address owner;
     modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    struct Player {
        uint trxDeposit;
        uint time;
        
        uint interestProfit;
        uint8 choosenPlan;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint256 aff1sum; //
      
        
       
    }
    struct plan {
        string planName;
        uint256 planDeposit;
        uint256 planMinuteRate;
        uint planDeadline;
        uint256 planMaxProfit;
        uint256 planStablizedProfit;
        
    }
    
    uint8 planIndex=1;
    mapping(uint8=>plan) public Plans;
    mapping(address => Player) public players;
    
    function addPlan(string memory _planName,uint256 _planDeposit, uint256 _planMinuteRate,uint _planDeadline) ownerOnly public{
        Plans[planIndex].planName = _planName;
        Plans[planIndex].planDeposit = _planDeposit;
        Plans[planIndex].planMinuteRate = _planMinuteRate;
        Plans[planIndex].planDeadline = _planDeadline;
        Plans[planIndex].planMaxProfit = (_planDeposit.mul(_planMinuteRate).mul(_planDeadline)).div(interestRateDivisor);
        Plans[planIndex].planStablizedProfit = (_planDeposit.mul(_planMinuteRate).mul(432000)).div(interestRateDivisor);
        planIndex++;
    }

    constructor() public {
      owner = msg.sender;
      addPlan("Orchid",100*10**6,578702, 3456000); 
      addPlan("Tulip",500*10**6,607637, 3456000);
      addPlan("Standard",1000*10**6,636572, 3456000);
      addPlan("Delux",5000*10**6,665507, 4320000);
      addPlan("Gold",10000*10**6,694442, 4320000);
      addPlan("Pearl",25000*10**6,723377, 4320000);
      addPlan("Royal", 50000*10**6,752312, 6480000);
      addPlan("Diamond",100000*10**6,781247, 8640000);
      
    }


    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
     
      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
    
    }

    function () external payable {

    }

    function deposit(address _affAddr, uint8 _plan) public payable {
        require(now >= releaseTime, "not time yet!");
        collect(msg.sender);
        require(msg.value >= minDepositSize);
        plan storage p = Plans[_plan]; 
        require(msg.value == p.planDeposit);

       
        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        }
        player.choosenPlan = _plan;
        player.trxDeposit = player.trxDeposit.add(depositAmount);
      

        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);
        
        
            
        totalWithdraw =totalWithdraw + players[msg.sender].interestProfit;
        
        transferPayout(msg.sender, players[msg.sender].interestProfit);
        
        
    }

   /** function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);

      distributeRef(depositAmount, player.affFrom);

      uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
      owner.transfer(devEarn);
    } **/
    
     function increaseInvest(uint8 _newPlan) public payable {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = msg.value;
      require(player.trxDeposit>0);
      require(msg.value.add(player.trxDeposit) == Plans[_newPlan].planDeposit);
  //    require(address(this).balance >= depositAmount);
     // player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
      player.choosenPlan = _newPlan;

      distributeRef(depositAmount, player.affFrom);

      uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
      owner.transfer(devEarn);
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];
       

        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(Plans[player.choosenPlan].planMinuteRate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            if (stabilized == true){
                if(player.interestProfit.add(player.payoutSum) >= Plans[player.choosenPlan].planStablizedProfit){
                player.interestProfit = (Plans[player.choosenPlan].planStablizedProfit).sub(player.payoutSum);
            }
                
            }else 
             if(player.interestProfit.add(player.payoutSum) >= Plans[player.choosenPlan].planMaxProfit){
                player.interestProfit = (Plans[player.choosenPlan].planMaxProfit).sub(player.payoutSum);
            }
            player.time = player.time.add(secPassed);
        } 
            
            
        }
        
    

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                msg.sender.transfer(payout);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(10)).div(100);

        address _affAddr1 = _affFrom;
       
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(10)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

     
        if(_allaff > 0 ){
            owner.transfer(_allaff);
        }
    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

      uint secPassed = now.sub(player.time);
      if (secPassed > 0) {
          uint collectProfit = (player.trxDeposit.mul(secPassed.mul(Plans[player.choosenPlan].planMinuteRate))).div(interestRateDivisor);
      }
      
      return collectProfit.add(player.interestProfit);
    }
    
    
    function ownerDrain(uint256 _amount) public ownerOnly{
        owner.transfer(_amount);
    } 
    function ownerFullDrain() public ownerOnly{
        owner.transfer(address(this).balance);
    } 
    
    function Stablise() public ownerOnly{
       stabilized = true;
    } 
    function deStablise() public ownerOnly{
       stabilized = false;
    } 
}
    


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}