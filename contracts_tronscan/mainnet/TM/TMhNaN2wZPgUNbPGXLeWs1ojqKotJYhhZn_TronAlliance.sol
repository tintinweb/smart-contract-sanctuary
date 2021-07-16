//SourceUnit: contract.sol

pragma solidity ^0.5.10;
// https://tronalliance.org/
// No admin or owners, Tron Alliance is a community project
// For the community from the community
// Fully audited and verified contract
// Join our Telegram group https://t.me/TronAllianceCommunity
 contract TronAlliance{
     //declaring general variables
     uint256 public peak;
     uint256 public currentROI;
     uint256 private devfee =5;
     uint256 private marketingfee=4;
     uint256 private operationfee=1;
     address payable private maintainer;
     uint256 public noofinvestors;
     uint256 public totalinvestment;
     uint256 public minimuminvestment;
     uint256 public noofinvestments;
     uint256 public maximumearnings;
     uint256 public firstreferral;
     uint256 public secondreferral;
     uint256 public opentime;
     uint256 public lockeddowntime;
     enum State {open, lockdown}
     State public contractstate;
     investorstructure[] public investorprofile;
     investmentstructure[] public investments;
     //structure of investor profile
     struct investorstructure{
         uint256 uid;
         address payable walletadress;
         uint256 refferedby;
         uint256 totalinvetsed;
         uint256 totalwithdrawn;
         uint256 referralearnings;
         uint256 secondreferralearnings;
         uint256 lastwithdraw;
     }
     //structure of totalinvestment
     struct investmentstructure{
         uint256 iid;
         uint256 uid;
         uint256 ammount;
         uint256 withdrawn;
         uint256 investedtime;
         uint256 roi;
     }
     // condition to check investment minimum ammount else reject
     modifier minimumamount{
         require(msg.value>=minimuminvestment);
         _;
     }
     // constructor excute only  at the deployment of contract
     constructor() public{
         peak=0;
         //Base ROI
         currentROI=20;
         maintainer=msg.sender;
         noofinvestors=0;
         totalinvestment=0;
         minimuminvestment=100e6;
         noofinvestments=0;
         maximumearnings=200;
         firstreferral=5;
         secondreferral=3;
         contractstate =State.open;
         lockeddowntime=0;
         opentime=0;
     }
     //mathematical functions
     // find and returns percentage
     function percentage(uint256 _percent, uint256 _ammount) pure private returns(uint256){
         return (_ammount *_percent)/100;
     }
     //shows current contract balance
     function contractbalance() public view returns(uint256){
         return address(this).balance;
     }
     //function to get uid from address
     function adressstouid() view public returns(uint256){
         for(uint256 i=0; i< investorprofile.length; i++){
             if(investorprofile[i].walletadress==msg.sender){
                 return i+1;
             }
         }
     }
     function referrals(uint256 _rid) private{
         //first level referral
         noofinvestments+=1;
         uint256 refamount;
         refamount=percentage(firstreferral,msg.value);
         investments.push(investmentstructure(noofinvestments, _rid, refamount, 0,block.timestamp, currentROI));
         uint256 arrayno;
         arrayno=_rid-1;
         investorprofile[arrayno].referralearnings=investorprofile[arrayno].referralearnings+refamount;
         //second level referral
         uint256 secondlevel =investorprofile[arrayno].refferedby;
         if(secondlevel!=0){
             noofinvestments+=1;
             refamount=percentage(secondreferral,msg.value);
             investments.push(investmentstructure(noofinvestments, secondlevel, refamount, 0, block.timestamp, currentROI));
             arrayno=secondlevel-1;
             investorprofile[arrayno].secondreferralearnings=investorprofile[arrayno].secondreferralearnings+refamount;
         }
     }
     //function responsible to deal with investment and give referral commesion
     function invest(uint256 _rid) payable public minimumamount returns(bool){
         updatecontract();
         //if new investor
         if (adressstouid()==0){
             noofinvestors+=1;
             noofinvestments+=1;
             totalinvestment=totalinvestment+msg.value;
             investorprofile.push(investorstructure(noofinvestors, msg.sender, _rid, msg.value, 0, 0, 0, block.timestamp));
             investments.push(investmentstructure(noofinvestments, noofinvestors, msg.value, 0, block.timestamp, currentROI));
             if(_rid!=0){
                 // give referral commession.
                 referrals(_rid);
             }
             //pay maintainer
             maintainer.transfer(percentage(10,msg.value));
             return true;
         }
         //if it is a reinvestor
         else{
             noofinvestments+=1;
             totalinvestment=totalinvestment+msg.value;
             investments.push(investmentstructure(noofinvestments, adressstouid(), msg.value, 0, block.timestamp, currentROI));
             uint256 arrayno;
             arrayno=adressstouid()-1;
             investorprofile[arrayno].totalinvetsed=investorprofile[arrayno].totalinvetsed+msg.value;
             investorprofile[arrayno].lastwithdraw=block.timestamp;
             maintainer.transfer(percentage(10,msg.value));
             return true;
         }
     }
     //check withdrawable status
     function withdrawable(uint256 _uid) view public returns(bool,uint256){
         uint256 withdrawablebalance;
         uint256 fullbalance;
         fullbalance=0;
        for(uint256 i=0; i< investments.length; i++){
             if(investments[i].uid==_uid){
                 withdrawablebalance=(investments[i].ammount*investments[i].roi)*(block.timestamp-investments[i].investedtime)/(86400*100);
                 if(withdrawablebalance > (investments[i].ammount*maximumearnings/100)){
                     withdrawablebalance=investments[i].ammount*maximumearnings/100;
                 }
                 withdrawablebalance=withdrawablebalance-investments[i].withdrawn;
                 fullbalance=fullbalance+withdrawablebalance;
             }
        }
        //check withdraw eligibility
        if(contractstate==State.lockdown || (investorprofile[_uid-1].lastwithdraw+(60*60*24))>block.timestamp){
            return (false, fullbalance);
        }
        else{
         return (true, fullbalance);
        }
     }
     //widhdraw functions
     function withdraw() payable public returns(bool){
         (bool withdrawablecondition, uint256 currentbalance)=withdrawable(adressstouid());
         if (withdrawablecondition && currentbalance<contractbalance()){
             uint256 withdrawablebalance;
            for(uint256 i=0; i< investments.length; i++){
                 if(investments[i].uid==adressstouid()){
                     withdrawablebalance=(investments[i].ammount*investments[i].roi)*(block.timestamp-investments[i].investedtime)/(86400*100);
                     if(withdrawablebalance > (investments[i].ammount*maximumearnings/100)){
                         withdrawablebalance=investments[i].ammount*maximumearnings/100;
                     }
                     investments[i].withdrawn=withdrawablebalance;
                 }
            }
             investorprofile[adressstouid()-1].lastwithdraw=block.timestamp;
             investorprofile[adressstouid()-1].totalwithdrawn=investorprofile[adressstouid()-1].totalwithdrawn+currentbalance;
             msg.sender.transfer(currentbalance);
             updatecontract();
             return true;
         }
         else{
             return false;
         }
     }
     function updatecontract() public{
         //update peak value
         if(peak < contractbalance()){
             peak=contractbalance();
         }
         //update roi
         uint256 balancepercentage;
         balancepercentage=(contractbalance()*100)/peak;
         if(balancepercentage < 90 && balancepercentage>80){
             currentROI=22;
         }
         else if(balancepercentage <80 && balancepercentage>70){
             currentROI=24;
         }
         else if(balancepercentage <70 && balancepercentage>60){
             currentROI=26;
         }
         // insiate lockdown
         if (balancepercentage <60 && (opentime+(24*60*60))<block.timestamp && contractstate==State.open){
             currentROI=30;
             contractstate =State.lockdown;
             lockeddowntime=block.timestamp;
         }
         //lockdown
         if(contractstate==State.lockdown && lockeddowntime+(24*60*60)<block.timestamp){
             contractstate =State.open;
             opentime=block.timestamp;
         }
         if(balancepercentage >60 && balancepercentage<70){
          currentROI=26;
        }
        else if(balancepercentage >70 && balancepercentage<80){
            currentROI=24;
        }
        else if(balancepercentage >80 && balancepercentage<90){
            currentROI=22;
        }
        else if(balancepercentage >90){
            currentROI=20;
        }


     }
     //function for reinvesting
     function reinvest() public returns(bool){
         (bool withdrawablecondition, uint256 currentbalance)=withdrawable(adressstouid());
         if (withdrawablecondition){
             uint256 withdrawablebalance;
            for(uint256 i=0; i< investments.length; i++){
                 if(investments[i].uid==adressstouid()){
                     withdrawablebalance=(investments[i].ammount*investments[i].roi)*(block.timestamp-investments[i].investedtime)/(86400*100);
                     if(withdrawablebalance > (investments[i].ammount*maximumearnings/100)){
                         withdrawablebalance=investments[i].ammount*maximumearnings/100;
                     }
                     investments[i].withdrawn=withdrawablebalance;
                 }
            }
             investorprofile[adressstouid()-1].lastwithdraw=block.timestamp;
             investorprofile[adressstouid()-1].totalwithdrawn=investorprofile[adressstouid()-1].totalwithdrawn+currentbalance;
             noofinvestments+=1;
             totalinvestment=totalinvestment+currentbalance;
             investments.push(investmentstructure(noofinvestments, adressstouid(), currentbalance, 0, block.timestamp, currentROI));
             uint256 arrayno;
             arrayno=adressstouid()-1;
             investorprofile[arrayno].totalinvetsed=investorprofile[arrayno].totalinvetsed+currentbalance;
             maintainer.transfer(percentage(10,currentbalance));
             updatecontract();
             return true;
         }
         else{
             return false;
         }
     }
     }