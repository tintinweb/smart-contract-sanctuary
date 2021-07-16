//SourceUnit: TronBanks.sol

 pragma solidity ^0.5.4;

contract TronBanks {

    using SafeMath for uint256;

    uint public totalMembers = 0;
    uint public id = 0;
    uint public depositid = 0;
 
    uint public ultraCount = 0;
    uint public totalInvestments;
    uint private compRatioPrinciple = 60;
    uint private compRatioProfit = 40;
    uint private sunny = 1000000;
    uint public devCommission = 10; 

    uint private noOfDays = 100;  

    uint public minDepositSize = 500*sunny; // 500 Tron
    uint public maxDepositSize = 1000000*sunny; // 1000,000 Tron
    uint private daySeconds = 86400; //86400 
    uint private ultraBiz = 10000000*sunny; //10000000
    uint private ultraElg = 4000000*sunny; //4000000
    uint public club1 = 50000*sunny; // 50000
    uint public club2 = 200000*sunny; // 200000
  
    uint private ultraMaxCount = 4;

    uint public club1MembersCount = 0;
    uint public club2MembersCount = 0;
    uint public club1Reserve = 0;
    uint public club2Reserve = 0;
    uint public globalPaid =0;

    uint public club1share = 0;
    uint public club2share = 0; 
     
      uint level1 = 25;
      uint level2 = 10;
      uint level3 = 5;
      uint level4 = 5;
      uint level5 = 5;
      uint level6 = 5;
      uint level7 = 5;
      uint level8 = 5;
      uint level9 = 10;
      uint level10 = 25;
      uint totalLevel = 20; 
      address payable owner;
      uint percentDivisor = 1000000;
      uint [51]percent  = 

[
12000,
24240,
49360,
75396,
102376,
130340,
159320,
189352,
220476,
252732,
286160,
320804,
356708,
393916,
432480,
472444,
513864,
556788,
601272,
647376,
695156,
744672,
795988,
849172,
904288,
961408,
1020604,
1081952,
1145532,
1211424,
1279712,
1350484,
1423828,
1499840,
1578616,
1660256,
1744864,
1832548,
1923420,
2017596,
2115196,
2216344,
2321172,
2429808,
2542396,
2659076,
2780000,
2905320,
3035196,
3169796,
3309288

];

 
    struct Member {
        
        uint totalInvested;
        uint maxRec;
        uint totalPaid;
        uint avlBalance;
        uint time;
        uint isUltra;
        uint lastDeposit;
        uint totalRewards;
        uint id; 
        uint totalBiz;
        uint level1Count;
        uint depositCount;
        uint isActive;
        address payable refFrom;

      }
      
      struct Member2 {
               
        uint id;
        uint roiRewards;
        uint roiClaim;
        uint roiMax;
        uint level1Biz; // club
        uint bigPlayerRewards; 
        uint bigLeaderRewards; 
        uint clubRewards; 
        uint ultraRewards; 
        uint GenerationRewards; 
        uint levelRewards;
        uint isClub1;
        uint isClub2;
        uint clubPaidTime;
      }
      
    struct Team {
        
        uint256 ref1sum; //10 levels
        uint256 ref2sum;
        uint256 ref3sum;
        uint256 ref4sum;
        uint256 ref5sum;
        uint256 ref6sum;
        uint256 ref7sum;
        uint256 ref8sum;
        uint256 ref9sum;
        uint256 ref10sum; 
     }

    struct UltraUser {
         uint ultraid;
         address payable memberAddress; 
     }

    struct DepositMap {

         uint depositid;
         uint depositCount;
         address payable memberAddress;
         uint depositValue;
         uint cumDeposit;
         uint time;
          uint depActive;
         address payable referredBy;
    } 

    struct Userid {
        uint id;
        address payable userAddress;
    }

    struct BigPlayer {
        uint id;
        uint deposit;
        address payable player;
        address payable introducer;
        uint time;
    }
      event eventDeposit(
        address indexed _addr
    );
    event eventWithdraw(
        address indexed _addr
    );
    

    
    mapping(address => Member) public members;
    mapping(address => Member2) public members2;
    mapping(address => Team) public teams;
    mapping(uint => UltraUser) public ultraUsers;
    mapping(uint => BigPlayer) public bigPlayers;
    mapping(uint => Userid) public idToAddress;
    mapping(uint => DepositMap) public deposits;
  
 
    constructor() public {

        owner = msg.sender;
        id ++;
        depositid ++;
        totalMembers ++;
        Userid storage user = idToAddress[id];
        user.userAddress = msg.sender;
 
       Member storage member = members[msg.sender];
       Member2 storage member2 = members2[msg.sender];
       member.totalInvested = 200000*sunny;
       member.maxRec = member.totalInvested*333333/10;
        member.time = now;
       member.depositCount = 1;  
        member.lastDeposit = 100000*sunny;
        member.isActive = 1;
        member.id = id;
        member2.id = id;
        member2.isClub2 = 1;

       DepositMap storage dep = deposits[depositid];
       dep.depositValue = 200000*sunny;
       dep.cumDeposit = 200000*sunny;
       dep.memberAddress = msg.sender;
       dep.time = now;
       dep.depositCount = 1;
       dep.depActive = 1;
       totalInvestments = totalInvestments + 10000*sunny; 

       teams[msg.sender] = Team(10,1,1,1,1,1,1,1,1,1);
     }  

    
    function () external payable {

    }
     //starts here
    function invest(address payable _refAddr) public payable {
        
        require(msg.value >= minDepositSize && msg.value <= maxDepositSize); 
         
         Member storage member = members[msg.sender];
         Member2 storage member2 = members2[msg.sender];
         member.totalInvested = msg.value;
         member2.clubPaidTime = now + daySeconds; 

         club1Reserve = club1Reserve + (msg.value*1/100);
         club2Reserve = club2Reserve + (msg.value*2/100); 
            
            if(msg.value >= club2){
                if(member2.isClub1 == 1 ){
                   club2MembersCount ++;
                   member2.isClub2 = 1;
                   club1MembersCount --;
                   member2.isClub1 = 0;
                } else if(member2.isClub2 == 0){
                   club2MembersCount ++;
                   member2.isClub2 = 1;
                } 
            } else if (msg.value >= club1){
              if(member2.isClub1 == 0){
                   club1MembersCount ++;
                   member2.isClub1 = 1;
              }
            }

            Member2 storage refer = members2[member.refFrom];
            if(refer.level1Biz >= 2*club1 && refer.isClub1 == 0 ){
              refer.isClub1 = 1;
              club1MembersCount++;
            }
            if(refer.level1Biz >= 2*club2 && refer.isClub1 == 1 ){
              if(refer.isClub2 != 0){

               refer.isClub2 = 1;
              club2MembersCount++;
               refer.isClub1 = 0;
              club1MembersCount--;
            
              }}
              if(refer.level1Biz >= 2*club2 && refer.isClub2 == 0 ){
              refer.isClub2 = 1;
              club2MembersCount++;
            }

 
        member.lastDeposit = msg.value;
        member.maxRec =  member.totalInvested*33/10;
        member.time = now;
        member.depositCount = 1;
        member.isActive = 1; 
        totalInvestments = totalInvestments + msg.value; 
        member.refFrom = _refAddr;
        member.level1Count = 0;

        Member storage refr = members[_refAddr];
        refr.level1Count += 1; 

           id ++;
           totalMembers++;
            member.id = id;
            member2.id = id;

         Userid storage user = idToAddress[id];
         user.userAddress = msg.sender;
 
         depositid ++;

           DepositMap storage dep = deposits[depositid];
           dep.depositValue = msg.value;
           dep.cumDeposit = msg.value;
           dep.referredBy = _refAddr;
           dep.memberAddress = msg.sender;
           dep.time = now;
           dep.depositCount = 1;
           dep.depActive = 1; 
   
        uint256 _fullRewards = msg.value*totalLevel/100;
        uint256 _totalReffRewards = 0;
        uint256 _rewardsRemaining = _fullRewards;

        address payable _refAddr1 = _refAddr;
        if(_refAddr1 != address(0) && members[_refAddr1].isActive == 1 ){
          _totalReffRewards = _fullRewards.mul(level1).div(100);
          members[_refAddr1].totalBiz = members[_refAddr1].totalBiz + msg.value; 
          members2[_refAddr1].level1Biz += msg.value;
       if(members[_refAddr1].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr1);
       }
          transferRewards(_totalReffRewards,_refAddr1);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref1 = teams[_refAddr1];
         ref1.ref1sum = ref1.ref1sum + 1; 
         }

        address payable _refAddr2 = members[_refAddr1].refFrom;
        if(_refAddr2 != address(0) && members[_refAddr2].isActive == 1 ){
          _totalReffRewards = _fullRewards.mul(level2).div(100);
          members[_refAddr2].totalBiz = members[_refAddr2].totalBiz + msg.value; 
       if(members[_refAddr2].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr2);
       }
          transferRewards(_totalReffRewards,_refAddr2);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref2 = teams[_refAddr2];
         ref2.ref2sum = ref2.ref2sum + 1; 
         }
        address payable _refAddr3 = members[_refAddr2].refFrom;
        if(_refAddr3 != address(0) && members[_refAddr3].isActive == 1 ){
         _totalReffRewards = _fullRewards.mul(level3).div(100);
          members[_refAddr3].totalBiz = members[_refAddr3].totalBiz + msg.value; 
    if(members[_refAddr3].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr3);
       }
             transferRewards(_totalReffRewards,_refAddr3);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref3 = teams[_refAddr3];
         ref3.ref3sum = ref3.ref3sum + 1; 
        }

        address payable _refAddr4 = members[_refAddr3].refFrom;
        if(_refAddr4 != address(0) && members[_refAddr4].isActive == 1 ){
         _totalReffRewards = _fullRewards.mul(level4).div(100);
          members[_refAddr4].totalBiz = members[_refAddr4].totalBiz + msg.value; 
        if(members[_refAddr4].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr4);
       }
              transferRewards(_totalReffRewards,_refAddr4);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref4 = teams[_refAddr4];
         ref4.ref4sum = ref4.ref4sum + 1; 
        }
        address payable _refAddr5 = members[_refAddr4].refFrom;
        if(_refAddr5 != address(0) && members[_refAddr5].isActive == 1 ){
        _totalReffRewards = _fullRewards.mul(level5).div(100);
          members[_refAddr5].totalBiz = members[_refAddr5].totalBiz + msg.value; 
  if(members[_refAddr5].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr5);
       }
            transferRewards(_totalReffRewards,_refAddr5);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref5 = teams[_refAddr5];
         ref5.ref5sum = ref5.ref5sum + 1; 
         }
       address payable _refAddr6 = members[_refAddr5].refFrom;
        if(_refAddr6 != address(0) && members[_refAddr6].isActive == 1 ){
        _totalReffRewards = _fullRewards.mul(level6).div(100);
          members[_refAddr6].totalBiz = members[_refAddr6].totalBiz + msg.value; 
    if(members[_refAddr6].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr6);
       }
          transferRewards(_totalReffRewards,_refAddr6);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref6 = teams[_refAddr6];
         ref6.ref6sum = ref6.ref6sum + 1; 
         }
       address payable _refAddr7 = members[_refAddr6].refFrom;
        if(_refAddr7 != address(0) && members[_refAddr7].isActive == 1 ){
        _totalReffRewards = _fullRewards.mul(level7).div(100);
          members[_refAddr7].totalBiz = members[_refAddr7].totalBiz + msg.value; 
    if(members[_refAddr7].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr7);
       }
          transferRewards(_totalReffRewards,_refAddr7);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref7 = teams[_refAddr7];
         ref7.ref7sum = ref7.ref7sum + 1; 
        }

       address payable _refAddr8 = members[_refAddr7].refFrom;
        if(_refAddr8 != address(0) && members[_refAddr8].isActive == 1 ){
           _totalReffRewards = _fullRewards.mul(level8).div(100);
          members[_refAddr8].totalBiz = members[_refAddr8].totalBiz + msg.value; 
   
    if(members[_refAddr8].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr8);
       }
          transferRewards(_totalReffRewards,_refAddr8);
            _rewardsRemaining -= _totalReffRewards; 

         Team storage ref8 = teams[_refAddr8];
         ref8.ref8sum = ref8.ref8sum + 1; 
      }
  
         address payable _refAddr9 = members[_refAddr8].refFrom;
        if(_refAddr9 != address(0) && members[_refAddr9].isActive == 1 ){
            if(members[_refAddr9].level1Count >= 10){
                
           _totalReffRewards = _fullRewards.mul(level9).div(100);
          members[_refAddr9].totalBiz = members[_refAddr9].totalBiz + msg.value; 
          transferRewards(_totalReffRewards,_refAddr9);
            _rewardsRemaining -= _totalReffRewards; 

            }
         Team storage ref9 = teams[_refAddr9];
         ref9.ref9sum = ref9.ref9sum + 1; 
      } 

        address payable _refAddr10 = members[_refAddr9].refFrom;
        if(_refAddr10 != address(0) && members[_refAddr10].isActive == 1 ){
            if(members[_refAddr10].level1Count >= 10){
                
           _totalReffRewards = msg.value*5/100; 
           members[_refAddr10].totalBiz = members[_refAddr10].totalBiz + msg.value; 
           transferRewards(_totalReffRewards,_refAddr10);
            _rewardsRemaining -= _totalReffRewards; 

            }
         Team storage ref10 = teams[_refAddr10];
         ref10.ref10sum = ref10.ref10sum + 1; 
      } 
 
       uint _tempAmt = msg.value;

         uint devEarn = _tempAmt.mul(devCommission).div(100);
         devEarn += _rewardsRemaining;
         owner.transfer(devEarn); 

        uint _remTrx;
        uint ultraTotal = 4;
        address payable _userAddr;
           globalPaid += msg.value*4/100;

        //ultra bonus
        if(ultraCount >= 0){

            if(ultraCount > ultraMaxCount){
                ultraCount = ultraMaxCount;
            }
            
            for(uint _i = 1; _i <= ultraCount; _i++){
        
             _userAddr = ultraUsers[_i].memberAddress ;
              uint _trx = msg.value*1/100; // 1 percent
             _userAddr.transfer(_trx);
            
             members[_userAddr].totalPaid +=_trx;
             globalPaid += _trx;
             members[_userAddr].totalRewards += _trx;
             members2[_userAddr].ultraRewards += _trx;
            
             ultraTotal = ultraTotal - 1; 
            }
        _remTrx = msg.value*ultraTotal/100;
        owner.transfer(_remTrx); 
     }
      updateBigPlayer();
      emit eventDeposit(msg.sender);
 }

 function withdrawClub() public payable {

   Member2 storage member2 = members2[msg.sender];  
   Member storage member = members[msg.sender];  

   require (now > (member2.clubPaidTime + daySeconds) && member.isActive == 1);
   require (member2.isClub1 == 1 || member2.isClub2 == 1);
   
   club1share = club1Reserve/(club1MembersCount*2);
   club2share = club2Reserve/(club2MembersCount*2) ; 

  if(member2.isClub2 == 1){ 
      msg.sender.transfer(club2share);
      club2Reserve -= club2share;
      member2.clubRewards += club2share;
      member.totalRewards += club2share;
      member.totalPaid += club2share; 
      member2.clubPaidTime = now + daySeconds;
      globalPaid += club2share; 

  } else if(member2.isClub1 == 1){
     msg.sender.transfer(club1share);
      club1Reserve -= club1share;
      member2.clubRewards += club1share;
      member.totalRewards += club1share;
      member.totalPaid += club1share; 
      member2.clubPaidTime = now + daySeconds;

            globalPaid += club1share; 

  }
      emit eventWithdraw(msg.sender);

 }
  function collect(address payable _addr) public  {

    Member storage member = members[msg.sender];
    Member2 storage member2 = members2[msg.sender];
    uint _roi = 0;
    
     for(uint _j = 1; _j <= depositid; _j++){
       DepositMap storage _dep = deposits[_j];
                
        if(_dep.memberAddress == _addr && _dep.depActive == 1){
          
           
              uint _days = toDays(_dep.time);
             if(_days >= noOfDays){
               _days = noOfDays;
              }

 
             if(_dep.depActive != 0){
               if(_days == 1){
                  _roi += percent[_days - 1]*_dep.depositValue/percentDivisor;
                } else {
                uint  _realDays = _days/2;

                 if(_days % 2 == 0 && _days > 1){
 
                 _roi += percent[_realDays]*_dep.depositValue/percentDivisor;
               
                } else {

                uint _newPercent = (percent[_realDays]+percent[_realDays+1])/2;
                _roi +=  _newPercent*_dep.depositValue/percentDivisor;
                
                }
              } 
           }
        }
      } 
                member2.roiRewards  = _roi;
                member2.roiMax = member.maxRec - member.totalRewards;
                member2.roiClaim = member.totalPaid - member.totalRewards;

                  if(_roi >= member2.roiMax){
                      member2.roiRewards = member2.roiMax;
                  }      

                member.avlBalance = member2.roiRewards - member2.roiClaim;

    }

    function toDays(uint _time) internal view returns (uint) {
        uint _sec = now  - _time;
        uint _tomin = _sec/60;
         uint _tohour = _tomin/60;
       uint _todays = _tohour/24;
       if(_todays > 100){
        _todays = 100;
      }
           return _todays; // _todays
    }


   function updateBigPlayer() private {
        
         BigPlayer storage big1 = bigPlayers[1];
         BigPlayer storage big2 = bigPlayers[2];

         big1.player.transfer(msg.value*2/100);
         members[big1.player].totalPaid += msg.value*2/100;
               globalPaid += msg.value*2/100; 

         members[big1.player].totalRewards += msg.value*2/100;
         members2[big1.player].bigPlayerRewards += msg.value*2/100;

         big1.introducer.transfer(msg.value*1/100);
         members[big1.introducer].totalPaid += msg.value*1/100;
               globalPaid += msg.value*1/100; 
         members[big1.introducer].totalRewards += msg.value*1/100;
         members2[big1.introducer].bigLeaderRewards += msg.value*1/100;



         if(big1.player == address(0)){
               big1.player = msg.sender;
               big1.time = now;
               big1.introducer = members[msg.sender].refFrom;
               big1.deposit = msg.value;
         }

         if(big2.player == address(0)){
               big2.player = msg.sender;
               big2.time = now;
               big2.introducer = members[msg.sender].refFrom;
               big2.deposit = msg.value;
         }

         if(msg.value > big2.deposit || now > (big2.time + daySeconds)){
               big2.player = msg.sender;
               big2.time = now;
               big2.introducer = members[msg.sender].refFrom;
               big2.deposit = msg.value;
         }  

         if(now > (big1.time + daySeconds) && now < (big2.time + daySeconds)){
           big1.player = big2.player ;
               big1.time = big2.time ;
               big1.introducer = big2.introducer ;
               big1.deposit = big2.deposit ;
         } 
         
          if(msg.value > big1.deposit){
             big1.player = msg.sender;
               big1.time = now;
               big1.introducer = members[msg.sender].refFrom;
               big1.deposit = msg.value;
         }
           

       
   }

     function transferRewards(uint _trx1, address payable _addr) private {
         uint _trx = _trx1;
         address payable _user = _addr;
     
     Member storage member = members[_addr];
     uint _maxRec = member.maxRec;
     uint _totalPaid = member.totalPaid;
     uint _avlBalance = member.avlBalance;
     uint _totalRec = _totalPaid + _avlBalance;
     uint _totalRecTrx = _totalPaid + _trx;

     if(_totalRec >= _maxRec){
         uint _transferrable = _maxRec - _totalPaid;
         _user.transfer(_transferrable);
         member.avlBalance = 0;
         member.isActive = 0;

          members[_addr].totalPaid = _transferrable.add(members[_addr].totalPaid);
                         globalPaid += _transferrable; 

         members[_addr].totalRewards = _transferrable.add(members[_addr].totalRewards);
         members2[_addr].GenerationRewards = _transferrable.add(members2[_addr].GenerationRewards);
          
     }
        else if(_totalRecTrx >= _maxRec){
         uint _transferrable2 = _maxRec - _totalPaid;
         _user.transfer(_transferrable2);
         member.avlBalance = 0;
         member.isActive = 0;
          
            members[_addr].totalPaid = _transferrable2.add(members[_addr].totalPaid);
                                     globalPaid += _transferrable2; 

            members[_addr].totalRewards = _transferrable2.add(members[_addr].totalRewards);
          members2[_addr].GenerationRewards = _transferrable2.add(members2[_addr].GenerationRewards);
         
         } else {
             _user.transfer(_trx);
              
            members[_addr].totalPaid = _trx.add(members[_addr].totalPaid);
                                     globalPaid += _trx; 

            members[_addr].totalRewards = _trx.add(members[_addr].totalRewards);
            members2[_addr].GenerationRewards = _trx.add(members2[_addr].GenerationRewards);

            if(members[_addr].totalPaid >= members[_addr].maxRec){
              members[_addr].isActive = 0;
            } 
         } 
     }
     
     function reinvest() public payable {
        
        require(msg.value >= minDepositSize && msg.value <= maxDepositSize); 
         
        require(msg.value >= members[msg.sender].lastDeposit );  
 
        Member storage member = members[msg.sender];
        Member2 storage member2 = members2[msg.sender];
        address payable _refAddr = member.refFrom;

         club1Reserve = club1Reserve + (msg.value*1/100);
         club2Reserve = club2Reserve + (msg.value*2/100); 
            
            if(msg.value >= club2){
                if(member2.isClub1 == 1 ){
                   club2MembersCount ++;
                   member2.isClub2 = 1;
                   club1MembersCount --;
                   member2.isClub1 = 0;
                } else if(member2.isClub2 == 0){
                   club2MembersCount ++;
                   member2.isClub2 = 1;
                } 
            } else if (msg.value >= club1){
              if(member2.isClub1 == 0){
                   club1MembersCount ++;
                   member2.isClub1 = 1;
              }
            }

            Member2 storage refer = members2[member.refFrom];
            if(refer.level1Biz >= 2*club1 && refer.isClub1 == 0 ){
              refer.isClub1 = 1;
              club1MembersCount++;
            }
            if(refer.level1Biz >= 2*club2 && refer.isClub1 == 1 ){
              if(refer.isClub2 != 0){

               refer.isClub2 = 1;
              club2MembersCount++;
               refer.isClub1 = 0;
              club1MembersCount--;
            
              }}
              if(refer.level1Biz >= 2*club2 && refer.isClub2 == 0 ){
              refer.isClub2 = 1;
              club2MembersCount++;
            }

        member.lastDeposit = msg.value;
        member.totalInvested = member.totalInvested + msg.value;
        member.maxRec = member.totalInvested*33/10;
        member.time = now;
        member.isActive = 1; 
        totalInvestments = totalInvestments + msg.value;
        member.depositCount = member.depositCount + 1;

           depositid ++;
           DepositMap storage dep = deposits[depositid];
           dep.depositValue = msg.value;
           dep.cumDeposit = msg.value;
           dep.depositCount = dep.depositCount + 1; 
           dep.memberAddress = msg.sender;
           dep.referredBy = _refAddr;
           dep.time = now;
           dep.depActive = 1; 
  
             uint256 _fullRewards = msg.value*totalLevel/100;
             uint256 _totalReffRewards = 0;
             uint256 _rewardsRemaining = _fullRewards;

        address payable _refAddr1 = _refAddr;
        if(_refAddr1 != address(0) && members[_refAddr1].isActive == 1 ){
          _totalReffRewards = _fullRewards.mul(level1).div(100);
          members[_refAddr1].totalBiz = members[_refAddr1].totalBiz + msg.value; 
          members2[_refAddr1].level1Biz += msg.value;
          transferRewards(_totalReffRewards,_refAddr1);
       
        if(members[_refAddr1].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr1);
               }
                 _rewardsRemaining -= _totalReffRewards; 
        }

        address payable _refAddr2 = members[_refAddr1].refFrom;
        if(_refAddr2 != address(0) && members[_refAddr2].isActive == 1 ){
          _totalReffRewards = _fullRewards.mul(level2).div(100);
          members[_refAddr2].totalBiz = members[_refAddr2].totalBiz + msg.value; 
                      if(members[_refAddr2].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr2);
       } 
          transferRewards(_totalReffRewards,_refAddr2);
            _rewardsRemaining -= _totalReffRewards; 

          }

        address payable _refAddr3 = members[_refAddr2].refFrom;
        if(_refAddr3 != address(0) && members[_refAddr3].isActive == 1 ){
         _totalReffRewards = _fullRewards.mul(level3).div(100);
          members[_refAddr3].totalBiz = members[_refAddr3].totalBiz + msg.value; 
                     if(members[_refAddr3].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr3);
       } 
          transferRewards(_totalReffRewards,_refAddr3);
            _rewardsRemaining -= _totalReffRewards; 

          }

        address payable _refAddr4 = members[_refAddr3].refFrom;
        if(_refAddr4 != address(0) && members[_refAddr4].isActive == 1 ){
         _totalReffRewards = _fullRewards.mul(level4).div(100);
          members[_refAddr4].totalBiz = members[_refAddr4].totalBiz + msg.value; 
                     if(members[_refAddr4].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr4);
       } 
          transferRewards(_totalReffRewards,_refAddr4);
            _rewardsRemaining -= _totalReffRewards; 

          }

        address payable _refAddr5 = members[_refAddr4].refFrom;
        if(_refAddr5 != address(0) && members[_refAddr5].isActive == 1 ){
        _totalReffRewards = _fullRewards.mul(level5).div(100);
          members[_refAddr5].totalBiz = members[_refAddr5].totalBiz + msg.value; 
                     if(members[_refAddr5].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr5);
       } 
          transferRewards(_totalReffRewards,_refAddr5);
            _rewardsRemaining -= _totalReffRewards; 

          }

       address payable _refAddr6 = members[_refAddr5].refFrom;
        if(_refAddr6 != address(0) && members[_refAddr6].isActive == 1 ){
        _totalReffRewards = _fullRewards.mul(level6).div(100);
          members[_refAddr6].totalBiz = members[_refAddr6].totalBiz + msg.value; 
                     if(members[_refAddr6].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr6);
       } 
          transferRewards(_totalReffRewards,_refAddr6);
            _rewardsRemaining -= _totalReffRewards; 

          }

       address payable _refAddr7 = members[_refAddr6].refFrom;
        if(_refAddr7 != address(0) && members[_refAddr7].isActive == 1 ){
        _totalReffRewards = _fullRewards.mul(level7).div(100);
          members[_refAddr7].totalBiz = members[_refAddr7].totalBiz + msg.value; 
                     if(members[_refAddr7].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr7);
       } 
          transferRewards(_totalReffRewards,_refAddr7);
            _rewardsRemaining -= _totalReffRewards; 

          }

       address payable _refAddr8 = members[_refAddr7].refFrom;
        if(_refAddr8 != address(0) && members[_refAddr8].isActive == 1 ){
           _totalReffRewards = _fullRewards.mul(level8).div(100);
          members[_refAddr8].totalBiz = members[_refAddr8].totalBiz + msg.value; 
                     if(members[_refAddr8].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr8);
       } 
          transferRewards(_totalReffRewards,_refAddr8);
            _rewardsRemaining -= _totalReffRewards; 

          }

        address payable _refAddr9 = members[_refAddr8].refFrom;
        if(_refAddr9 != address(0) && members[_refAddr9].isActive == 1 ){
            if(members[_refAddr9].level1Count >= 10){
                
           _totalReffRewards = _fullRewards.mul(level9).div(100);
          members[_refAddr9].totalBiz = members[_refAddr9].totalBiz + msg.value; 
                     if(members[_refAddr9].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr9);
       } 
          transferRewards(_totalReffRewards,_refAddr9);
            _rewardsRemaining -= _totalReffRewards; 

            }
          } 

        address payable _refAddr10 = members[_refAddr9].refFrom;
        if(_refAddr10 != address(0) && members[_refAddr10].isActive == 1 ){
            if(members[_refAddr10].level1Count >= 10){
                
           _totalReffRewards = msg.value*5/100;
           
           members[_refAddr10].totalBiz = members[_refAddr10].totalBiz + msg.value;
                      if(members[_refAddr10].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
             checkUltraUser(_refAddr10);
       } 
           transferRewards(_totalReffRewards,_refAddr10);
            _rewardsRemaining -= _totalReffRewards; 

            }
          } 
      

        uint _tempAmt = msg.value;

         uint devEarn = _tempAmt.mul(devCommission).div(100);
         owner.transfer(devEarn); 
        uint _remTrx;
        uint ultraTotal = 10;
        address payable _userAddr;

        //ultra bonus
        if(ultraCount >= 0){

            if(ultraCount > ultraMaxCount){
                ultraCount = ultraMaxCount;
            }
            
            for(uint _i = 1; _i <= ultraCount; _i++){
        
             _userAddr = ultraUsers[_i].memberAddress ;
              uint _trx = msg.value*1/100; // 1 percent
             _userAddr.transfer(_trx);

              members[_userAddr].totalPaid +=_trx;
                  globalPaid += _trx; 

             members[_userAddr].totalRewards += _trx;
             members2[_userAddr].ultraRewards += _trx;
            
             ultraTotal = ultraTotal - 1; 
            
            }
        _remTrx = msg.value*ultraTotal/100;
        owner.transfer(_remTrx); 
      } 
          updateBigPlayer();
            emit eventDeposit(msg.sender); 
    }
 
    function checkActive(address _ref) internal {
        if(members[_ref].totalPaid >= members[_ref].maxRec){
            members[_ref].isActive = 0;
            for (uint _j=1; _j<= depositid ; _j++){
                
                DepositMap storage _dep = deposits[depositid];
                if(_dep.memberAddress == _ref){
                    _dep.depActive = 0;

                }
            }
        } 
    }

    function withdraw() public payable{ 

         require(members[msg.sender].isActive == 1); 

         collect(msg.sender);
         uint _trx = members[msg.sender].avlBalance; 
         Member storage member = members[msg.sender]; 
          members2[msg.sender].roiClaim += _trx;
         uint256 _allref = (_trx.mul(40)).div(100); 

        address payable _refAddr1 = member.refFrom;
        address payable _refAddr2 = members[_refAddr1].refFrom;
        address payable _refAddr3 = members[_refAddr2].refFrom;
        address payable _refAddr4 = members[_refAddr3].refFrom;
        address payable _refAddr5 = members[_refAddr4].refFrom;
        address payable _refAddr6 = members[_refAddr5].refFrom;
        address payable _refAddr7 = members[_refAddr6].refFrom;
        address payable _refAddr8 = members[_refAddr7].refFrom; 
        address payable _refAddr9 = members[_refAddr8].refFrom;
        address payable _refAddr10 = members[_refAddr9].refFrom; 
  
        owner.transfer(_allref);
        uint256 _totalReffRewards = 0;
         _totalReffRewards = _allref*10/100;
         members[msg.sender].totalPaid += _trx ; 
         globalPaid += _trx; 

         msg.sender.transfer(_trx); 
  
        if (_refAddr1 != address(0) && members[_refAddr1].isActive == 1) {
            _allref = _allref.sub(_totalReffRewards); 
             members[_refAddr1].totalPaid = _totalReffRewards.add(members[_refAddr1].totalPaid);
                          globalPaid += _totalReffRewards; 

            members[_refAddr1].totalRewards = _totalReffRewards.add(members[_refAddr1].totalRewards);
            members2[_refAddr1].levelRewards = _totalReffRewards.add(members2[_refAddr1].levelRewards);
            _refAddr1.transfer(_totalReffRewards);
            checkActive(_refAddr1);
             
         }

        if (_refAddr2 != address(0) && members[_refAddr2].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
             members[_refAddr2].totalPaid = _totalReffRewards.add(members[_refAddr2].totalPaid);
                          globalPaid += _totalReffRewards; 

            members[_refAddr2].totalRewards = _totalReffRewards.add(members[_refAddr2].totalRewards);
            members2[_refAddr2].levelRewards = _totalReffRewards.add(members2[_refAddr2].levelRewards);
            _refAddr2.transfer(_totalReffRewards);
            checkActive(_refAddr2);
        }

        if (_refAddr3 != address(0) && members[_refAddr3].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
             members[_refAddr3].totalPaid = _totalReffRewards.add(members[_refAddr3].totalPaid);
                          globalPaid += _totalReffRewards; 

            members[_refAddr3].totalRewards = _totalReffRewards.add(members[_refAddr3].totalRewards);
            members2[_refAddr3].levelRewards = _totalReffRewards.add(members2[_refAddr3].levelRewards);
            _refAddr3.transfer(_totalReffRewards);
            checkActive(_refAddr3);
        }

        if (_refAddr4 != address(0) && members[_refAddr4].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
            
            members[_refAddr4].totalPaid = _totalReffRewards.add(members[_refAddr4].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr4].totalRewards = _totalReffRewards.add(members[_refAddr4].totalRewards);
            members2[_refAddr4].levelRewards = _totalReffRewards.add(members2[_refAddr4].levelRewards);
            _refAddr4.transfer(_totalReffRewards);
            checkActive(_refAddr4);

             
        }

        if (_refAddr5 != address(0) && members[_refAddr5].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
            
            members[_refAddr5].totalPaid = _totalReffRewards.add(members[_refAddr5].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr5].totalRewards = _totalReffRewards.add(members[_refAddr5].totalRewards);
            members2[_refAddr5].levelRewards = _totalReffRewards.add(members2[_refAddr5].levelRewards);
            _refAddr5.transfer(_totalReffRewards);
            checkActive(_refAddr5);
             
        }

        if (_refAddr6 != address(0) && members[_refAddr6].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
            
            members[_refAddr6].totalPaid = _totalReffRewards.add(members[_refAddr6].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr6].totalRewards = _totalReffRewards.add(members[_refAddr6].totalRewards);
            members2[_refAddr6].levelRewards = _totalReffRewards.add(members2[_refAddr6].levelRewards);
            _refAddr6.transfer(_totalReffRewards);
            checkActive(_refAddr6);

             
        }

        if (_refAddr7 != address(0) && members[_refAddr7].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
            
            members[_refAddr7].totalPaid = _totalReffRewards.add(members[_refAddr7].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr7].totalRewards = _totalReffRewards.add(members[_refAddr7].totalRewards);
            members2[_refAddr7].levelRewards = _totalReffRewards.add(members2[_refAddr7].levelRewards);
             _refAddr7.transfer(_totalReffRewards);

             checkActive(_refAddr7);
        }

        if (_refAddr8 != address(0) && members[_refAddr8].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
            
            members[_refAddr8].totalPaid = _totalReffRewards.add(members[_refAddr8].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr8].totalRewards = _totalReffRewards.add(members[_refAddr8].totalRewards);
            members2[_refAddr8].levelRewards = _totalReffRewards.add(members2[_refAddr8].levelRewards);
            _refAddr8.transfer(_totalReffRewards);

             checkActive(_refAddr8);
        }
         if (_refAddr9 != address(0) && members[_refAddr9].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);
            if(members[_refAddr9].level1Count  >= 10){
            _refAddr9.transfer(_totalReffRewards);
 
             
             checkActive(_refAddr9);
            members[_refAddr9].totalPaid = _totalReffRewards.add(members[_refAddr9].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr9].totalRewards = _totalReffRewards.add(members[_refAddr9].totalRewards);
            members2[_refAddr9].levelRewards = _totalReffRewards.add(members2[_refAddr9].levelRewards);

            } else {
                owner.transfer(_totalReffRewards);
            }
        }
         if (_refAddr10 != address(0) && members[_refAddr10].isActive == 1) {
            
            _allref = _allref.sub(_totalReffRewards);

              if(members[_refAddr10].level1Count >= 10){
           
            members[_refAddr10].totalPaid = _totalReffRewards.add(members[_refAddr10].totalPaid);
                         globalPaid += _totalReffRewards; 

            members[_refAddr10].totalRewards = _totalReffRewards.add(members[_refAddr10].totalRewards);
            members2[_refAddr10].levelRewards = _totalReffRewards.add(members2[_refAddr10].levelRewards);
            _refAddr10.transfer(_totalReffRewards);
             checkActive(_refAddr10);

            } else {
                owner.transfer(_totalReffRewards);
            }
        }

        if(_allref > 0 ){
            owner.transfer(_allref);
        }
              emit eventWithdraw(msg.sender);

    } 
//stopped here 
    function getNow() public view returns (uint) {
       return now;
       }
 
    function checkUltraUser(address payable _addr) private {

      if(members[_addr].totalBiz >= ultraBiz && ultraCount < ultraMaxCount){
      uint _flag = 1;

         if(members[_addr].isUltra == 1){
          _flag=0;
        }
 
      if(_flag == 1){
         uint _j = 0;
         address payable _tempRefAddr = _addr;
         address payable _prevUser;

        
        for(uint _i = 1; _i <= depositid ; _i++) {
        
            if(deposits[_i].referredBy == _tempRefAddr){
               address payable   _downUserAddr = deposits[_i].memberAddress;
                
       if((members[_downUserAddr].totalBiz + members[_downUserAddr].totalInvested) >= ultraElg ){ 

            if(_downUserAddr == deposits[_i].memberAddress  ){
                 if(_prevUser != _downUserAddr){
                
                    _j++; 
                 _prevUser = _downUserAddr;
 
                   }
                }
              }
            } 
          }
           if(_j >= 2){

                    ultraCount++;
                    UltraUser storage user = ultraUsers[ultraCount];
                    user.memberAddress = _addr;
                    
                    Member storage member = members[_addr];
                    member.isUltra = 1; 
          }
        }
      }       
     }

    function transferOwnerShip(address payable _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function checkOwner()public view returns(address payable){
        require(msg.sender == owner);
        return owner;
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