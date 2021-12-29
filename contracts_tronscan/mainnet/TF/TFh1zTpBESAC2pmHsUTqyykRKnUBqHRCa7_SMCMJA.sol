//SourceUnit: SMC-Rev-24 -Test.sol

//000		     000	000	      00	00000000    00000000     000               000         000          00000000      000000000000             000        0000000
//000		     000	00 00     00    000         000          00 00           00 00        00 00         00    00      000000000000             000      00       00
//000		     000	00  00    00    000         000          00  00         00  00       00   00        00    00           000                 000     00         00
//000		     000	00   00   00    0000000     00000000     00   00       00   00      00 000 00       00000000           000                 000     00          00
//000		     000	00    00  00    0000000     00000000     00    00     00    00     00 00000 00      00    00           000                 000     00          00
//000		     000	00     00 00    000              000     00     00   00     00    00         00     00     00          000                 000      00        00
//00000000000    000	00      00 0    000              000     00      00 00      00   00           00    00      00         000       0000      000       00      00
//00000000000    000	00       000    00000000    00000000     00       000       00  000           000   00       000       000       0000      000         000000
pragma solidity 0.5.14;
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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
contract SMCMJA{

    struct UserStruct{
        bool isRegister;
        uint referreid;
        uint idintree;
        uint nodelevel;
        mapping (uint => mapping(uint => mapping(uint=>uint)))paidfromplans;
        mapping(uint => mapping(uint => uint[]))referrals;
        mapping(uint => mapping(uint => bool))activenewplan;
        mapping (uint => mapping(uint => mapping(uint=>mapping(uint => uint))))LevelPaid;
    }

    uint public LastNode;
    address payable adminwallet;
    using SafeMath for uint256;
    mapping (uint => uint) private planprice;
    mapping (uint => address payable) private AdminAddress;
    mapping(address => UserStruct) public users;
    mapping (uint => address payable) public userlist;
    mapping (uint => mapping (uint => mapping(uint => uint[])))LastIDLevelArray;
    mapping(uint=>uint) PlanList;
    event Registration(uint indexed user, uint indexed referrer, uint indexed parentid,uint level,uint timestamp);
    event SendCommission(uint indexed fromadd,uint indexed sendTo,uint indexed amount,uint timestamp);
    event ActivePlan(uint indexed user,uint indexed PlanId,uint indexed activator,uint MainPlanId,uint timestamp);
    event ActiveMPlan(uint indexed user,uint indexed MainPlanId,uint timestamp);
    constructor() public { 
        //TQPD8TG71iXGuob4qX18ps9uf7WFDQ6s1S
        adminwallet=0x9e1bd9B9274432C21904cBbC73a4FB956720656E; 
        LastNode++;
        planprice[1]=314000000;
        planprice[2]=628000000;
        planprice[3]=1884000000;
        planprice[4]=7536000000;
        planprice[5]=37680000000;
        planprice[6]=226080000000;
        planprice[7]=1582560000000;
        UserStruct memory userStruct;
        userStruct = UserStruct({
            isRegister:true,
            referreid:1,
            idintree:1,
            nodelevel:1
        });
        users[0x9e1bd9B9274432C21904cBbC73a4FB956720656E] = userStruct;
        userlist[LastNode] = adminwallet;
        for(uint i=1;i<=7;i++){
            users[adminwallet].activenewplan[i][1]=true;
            users[adminwallet].activenewplan[i][2]=true;
            users[adminwallet].activenewplan[i][3]=true;

            users[adminwallet].paidfromplans[i][2][1]=2;
            users[adminwallet].paidfromplans[i][3][4]=5;
        }
        
        UserStruct memory userStruct1;
        UserStruct memory userStruct2;
        UserStruct memory userStruct3;
        UserStruct memory userStruct4;
        UserStruct memory userStruct5;
        userStruct1 = UserStruct({
            isRegister:true,
            referreid:1,
            idintree:2,
            nodelevel:1
        });
        userStruct2 = UserStruct({
            isRegister:true,
            referreid:1,
            idintree:3,
            nodelevel:1
        });
        userStruct3 = UserStruct({
            isRegister:true,
            referreid:1,
            idintree:4,
            nodelevel:1
        });
        userStruct4 = UserStruct({
            isRegister:true,
            referreid:1,
            idintree:5,
            nodelevel:1
        });
        userStruct5 = UserStruct({
            isRegister:true,
            referreid:1,
            idintree:6,
            nodelevel:1
        });
        //TMdrivHY1SLn8Snoz9ZLcFP5Uzs59H1dte
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880]=userStruct1;
        //TSzvM2p5s8vsnWpnRZekGdkyZA1fZ7N86i
        users[0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239]=userStruct2;
        //TRJhSQNK8K2ZermyLEx1qurS5uo6qmaAeP
        users[0xa839872C97A9a4cF942751150d26C9371ACE3b24]=userStruct3;
        //TDMW2AgPnsgcWtzpa4MC36Xmw8K8xZR78M
        users[0x251fbC40160bab052baFA3FcDCb4a04b7D8F4A4D]=userStruct4;
        //TH1xNi725obCHGGtCGztg3rKtyCXCvR5G7
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379]=userStruct5;
        LastNode++;
        userlist[LastNode] = 0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880;
        users[adminwallet].referrals[1][1].push(LastNode);

        LastNode++;
        userlist[LastNode] = 0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239;
        users[adminwallet].referrals[1][1].push(LastNode);
        LastNode++;
        userlist[LastNode] = 0xa839872C97A9a4cF942751150d26C9371ACE3b24;
        users[adminwallet].referrals[1][1].push(LastNode);
        LastNode++;
        userlist[LastNode] = 0x251fbC40160bab052baFA3FcDCb4a04b7D8F4A4D;
        users[adminwallet].referrals[1][1].push(LastNode);
        LastNode++;
        userlist[LastNode] = 0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379;
        users[adminwallet].referrals[1][1].push(LastNode);
        //2
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880].activenewplan[1][1]=true;
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880].activenewplan[2][1]=true;
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880].activenewplan[3][1]=true;
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880].activenewplan[4][1]=true;
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880].activenewplan[5][1]=true;
        users[0x7FF8ADbE68dAf71b19f3fe7c2677Ed55d66E8880].activenewplan[6][1]=true;
        //3
        users[0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239].activenewplan[1][1]=true;
        users[0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239].activenewplan[2][1]=true;
        users[0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239].activenewplan[3][1]=true;
        users[0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239].activenewplan[4][1]=true;
        users[0xBACD111B42c4798b7c9ff3b8B14Fda4DF183f239].activenewplan[5][1]=true;
        //4
        users[0xa839872C97A9a4cF942751150d26C9371ACE3b24].activenewplan[1][1]=true;
        users[0xa839872C97A9a4cF942751150d26C9371ACE3b24].activenewplan[2][1]=true;
        users[0xa839872C97A9a4cF942751150d26C9371ACE3b24].activenewplan[3][1]=true;
        users[0xa839872C97A9a4cF942751150d26C9371ACE3b24].activenewplan[4][1]=true;
        users[0xa839872C97A9a4cF942751150d26C9371ACE3b24].activenewplan[5][1]=true;
        //5
        users[0x251fbC40160bab052baFA3FcDCb4a04b7D8F4A4D].activenewplan[1][1]=true;
        users[0x251fbC40160bab052baFA3FcDCb4a04b7D8F4A4D].activenewplan[2][1]=true;
        users[0x251fbC40160bab052baFA3FcDCb4a04b7D8F4A4D].activenewplan[3][1]=true;
        users[0x251fbC40160bab052baFA3FcDCb4a04b7D8F4A4D].activenewplan[4][1]=true;
        //6
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379].activenewplan[1][1]=true;
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379].activenewplan[2][1]=true;
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379].activenewplan[3][1]=true;
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379].activenewplan[4][1]=true;
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379].activenewplan[5][1]=true;
        users[0x4D4Deb29aC1E649DEEbB65570A6c1e9CA3eBB379].activenewplan[6][1]=true;
    }
    function() payable external {}
    function divnum(uint _n1,uint _n2)private pure returns(uint){
        return zoj(_n1  / _n2);
    }
    function zoj(uint _n1)private pure returns(uint){
        if(_n1 % 2==0){
            return 0;
        }
        else
        {
            return 1;
        }
    }
    function RegistrUser(uint _referaluserid,uint planreg)public payable returns(string memory){
         uint planpricereg=0;
        if(planreg==1){
            planpricereg=planprice[1];
        }
        else if(planreg==2){
            planpricereg=planprice[1]+planprice[2];
        }
        require(_referaluserid > 0 && _referaluserid <= LastNode, "Incorrect referrer Id");
        require(users[msg.sender].isRegister == false, "User exist");
        require(users[userlist[_referaluserid]].idintree != 0,"This Node invalid");
        require(msg.value == planpricereg, "Your wallet balance is not enough");
        address userAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        LastNode++;
        uint parentid=_referaluserid;
        uint placeid=users[userlist[parentid]].referrals[1][1].length % 5;
        bool place2=false;
        if(placeid==1){
            place2=true;
        }
        UserStruct memory userStruct;
        userStruct = UserStruct({
            isRegister:true,
            referreid:_referaluserid,
            idintree:LastNode,
            nodelevel:(users[userlist[parentid]].nodelevel)+1
        });
        users[msg.sender] = userStruct;
        userlist[LastNode] = msg.sender;
        users[userlist[parentid]].referrals[1][1].push(LastNode);
        users[msg.sender].activenewplan[1][1]=true;
        users[msg.sender].activenewplan[1][2]=false; 
        users[msg.sender].activenewplan[1][3]=false;
        if(planreg==1){
             BuyMainPlan(msg.sender,1,place2);
        }
        else if(planreg==2){
             BuyMainPlan(msg.sender,1,place2);
             BuyMainPlan(msg.sender,2,place2);
        }
        emit Registration(users[msg.sender].idintree,parentid,parentid,0,now);
    }
    
    function ActivenewPlan(uint _referrId,uint _planId,uint _mainplanId,uint nodeactivator,bool active)private {
            users[userlist[_referrId]].activenewplan[_mainplanId][_planId]=active;
            if(_planId==2){
                if(findNodeUpline(_referrId,0)!=1){
                    users[userlist[findNodeUpline(_referrId,1)]].referrals[_mainplanId][2].push(_referrId);
                }
            }
            else if(_planId==3){
                 if(findNodeUpline(_referrId,1)!=1){
                    users[userlist[findNodeUpline(_referrId,2)]].referrals[_mainplanId][3].push(_referrId);
                }
            }
            emit ActivePlan(_referrId, _planId,nodeactivator,_mainplanId,now);
    }
    function ActiveMainPlan(uint _referrId,uint _mainplanId,bool active)private {
            users[userlist[_referrId]].activenewplan[_mainplanId][1]=active;
            emit ActiveMPlan(_referrId,_mainplanId,now);
    }
    function withdraw(address payable _referraddress,address payable _uplineaddress ,uint adminamountt,uint uplineamount)public payable {
        uint referrid=users[_referraddress].idintree;
        if(_uplineaddress==adminwallet){
            //TQPD8TG71iXGuob4qX18ps9uf7WFDQ6s1S
            0x9e1bd9B9274432C21904cBbC73a4FB956720656E.transfer((adminamountt+uplineamount) * 44 / 100);
            //TNhrHZUo7dmvGRu48Rz3PRYDPjAJb3uQge
            0x8BB21a74D618f496C352C7894f3c811Bcd326EAf.transfer((adminamountt+uplineamount) * 25 / 100);
            //TTqADdXiU7yU2HA9dtG7WYFTysWCeRE4bf
            0xC3eC9Cf28525ab06d07e45539f6ba2fC4490b73a.transfer((adminamountt+uplineamount) * 25 / 100);
            //TNZtfk4mj7jxgG8yWy29pS8nyuhJybKC1Y
            0x8A30c3B16c91C484a000bD57a3Dbd0D8528E9085.transfer((adminamountt+uplineamount) * 6 / 100);
        }
        else{
            0x9e1bd9B9274432C21904cBbC73a4FB956720656E.transfer(adminamountt * 44 / 100);
            0x8BB21a74D618f496C352C7894f3c811Bcd326EAf.transfer(adminamountt * 25 / 100);
            0xC3eC9Cf28525ab06d07e45539f6ba2fC4490b73a.transfer(adminamountt * 25 / 100);
            0x8A30c3B16c91C484a000bD57a3Dbd0D8528E9085.transfer(adminamountt * 6 / 100);
            _uplineaddress.transfer(uplineamount);
        }
        emit SendCommission(referrid,users[_uplineaddress].idintree,uplineamount,now);
        emit SendCommission(referrid,1,adminamountt,now);
    } 
    function BuyMainPlan(address payable _referrid,uint mainplan,bool placeidMP1)public payable returns(string memory){
        uint amountplan=planprice[mainplan];
        require(mainplan <= 6,"Main Plan ID Invalid!");
        require(mainplan >= 1,"Main Plan ID Invalid!");
        if(mainplan>1){
            require(checkactiveplan(users[_referrid].idintree,1,mainplan)==false,"Already You Bought This Plan ID !");
            require(checkactiveplan(users[_referrid].idintree,1,mainplan-1)==true,"First you must Buy Previews Plan !");
        }
        require(users[_referrid].idintree > 0 && users[_referrid].idintree <= LastNode, "Incorrect referrer Id");
        require(msg.value >= amountplan, "Your wallet balance is not enough");
        address userAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        uint parentid;
        uint _referridselect;
        uint newplace;
        uint placeid;

        parentid=users[_referrid].referreid;
        _referridselect=users[_referrid].idintree;
        newplace=LastIDLevelArray[findNodeUpline(_referridselect,2)][mainplan][2].length+1;
         if(mainplan>1){
             if(checkactiveplan(parentid,1,mainplan)==true){
                placeid=LastIDLevelArray[parentid][mainplan][1].length % 5;
                LastIDLevelArray[parentid][mainplan][1].push(_referridselect);
             }
             else{
                users[userlist[parentid]].LevelPaid[mainplan][1][1][4]+=(amountplan * 75 / 100) / 1000000;
                users[adminwallet].LevelPaid[mainplan][1][1][7]+=(amountplan * 25 / 100) / 1000000;
                users[adminwallet].LevelPaid[mainplan][1][1][8]+=(amountplan * 75 / 100) / 1000000;
                withdraw(_referrid,adminwallet,amountplan * 25 / 100,amountplan * 75 / 100);
                ActiveMainPlan(_referridselect,mainplan,true);
                return "Done!";
             }
        }
        bool place2=false;
        if(mainplan==1){
            place2=placeidMP1;
        }
        else if(placeid==1) {
            place2=true;
        }
        if(place2){
            users[userlist[findNodeUpline(_referridselect,0)]].LevelPaid[mainplan][1][1][3]+=(amountplan * 75 / 100) / 1000000;
            if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,2)]].idintree,1,mainplan)==true){
                LastIDLevelArray[users[userlist[findNodeUpline(_referridselect,2)]].idintree][mainplan][2].push(_referridselect);
                if(newplace==3 || newplace==1){
                    users[userlist[findNodeUpline(_referridselect,2)]].paidfromplans[mainplan][2][1]=users[userlist[findNodeUpline(_referridselect,2)]].paidfromplans[mainplan][2][1]+1;
                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,2)]].idintree,2,mainplan)==true){
                        users[adminwallet].LevelPaid[mainplan][1][2][7]+=(amountplan * 25 / 100) / 1000000;
                        users[userlist[findNodeUpline(_referridselect,2)]].LevelPaid[mainplan][2][1][1]+=(amountplan * 75 / 100) / 1000000;
                        users[userlist[findNodeUpline(_referridselect,2)]].LevelPaid[mainplan][2][1][2]++;
                        withdraw(_referrid,userlist[findNodeUpline(_referridselect,2)],amountplan * 25 / 100,amountplan * 75 / 100 );
                    }//ok
                    else {
                        users[userlist[findNodeUpline(_referridselect,2)]].LevelPaid[mainplan][1][2][3]+=(amountplan * 75 / 100) / 1000000;
                        if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,4)]].idintree,1,mainplan)==true){
                            if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,4)]].idintree,2,mainplan)==true){
                                users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]=users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]+1;
                                if((users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]>=3 && users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]<=4) || (users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]>=7 && users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]<=8) || (users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]>=11 && users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]<=12) || (users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]>=15 && users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]<=16) || (users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]>=19 && users[userlist[findNodeUpline(_referridselect,4)]].paidfromplans[mainplan][2][2]<=20)){
                                    users[userlist[findNodeUpline(_referridselect,4)]].LevelPaid[mainplan][2][1][3]+=(amountplan * 50 / 100) / 1000000;
                                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,8)]].idintree,1,mainplan)==true){
                                        if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,8)]].idintree,2,mainplan)==true){
                                            users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][2][3]=users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][2][3]+1;
                                            ////////////////////////////////////////////
                                            ////////////////////////////////////////////
                                            ////////////////////////////////////////////
                                            if(divnum((users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][2][3])-1,10)==1 && ((users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][2][3])/10)<10){
                                                users[userlist[findNodeUpline(_referridselect,8)]].LevelPaid[mainplan][2][2][3]+=(amountplan * 50 / 100) / 1000000;
                                                if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,14)]].idintree,1,mainplan)==true){
                                                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,14)]].idintree,2,mainplan)==true){
                                                        users[userlist[findNodeUpline(_referridselect,14)]].LevelPaid[mainplan][2][3][1]+=(amountplan * 50 / 100) / 1000000;
                                                        users[userlist[findNodeUpline(_referridselect,14)]].LevelPaid[mainplan][2][3][2]++;
                                                        users[adminwallet].LevelPaid[mainplan][1][2][7]+=(amountplan * 25 / 100) / 1000000;
                                                        users[adminwallet].LevelPaid[mainplan][2][3][7]+=(amountplan * 25 / 100) / 1000000;
                                                        withdraw(_referrid,userlist[findNodeUpline(_referridselect,14)],amountplan * 50 / 100 ,amountplan * 50 / 100 );
                                                    }//ok
                                                    else{
                                                        Statics(userlist[findNodeUpline(_referridselect,14)],mainplan,2,3,3,amountplan);
                                                        withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                                    }//ok
                                                }
                                                else{
                                                    
                                                    Statics(userlist[findNodeUpline(_referridselect,14)],mainplan,2,3,3,amountplan);
                                                    withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                                }
                                            }
                                            else{
                                                users[adminwallet].LevelPaid[mainplan][1][2][7]+=(amountplan * 25 / 100) / 1000000;
                                                users[adminwallet].LevelPaid[mainplan][2][2][7]+=(amountplan * 25 / 100) / 1000000;
                                                users[userlist[findNodeUpline(_referridselect,8)]].LevelPaid[mainplan][2][2][1]+=(amountplan * 50 / 100) / 1000000;
                                                users[userlist[findNodeUpline(_referridselect,8)]].LevelPaid[mainplan][2][2][2]++;
                                                withdraw(_referrid,userlist[findNodeUpline(_referridselect,8)],amountplan * 50 / 100,amountplan * 50 / 100);
                                            }//ok    
                                        
                                        }
                                        else{
                                            
                                            Statics(userlist[findNodeUpline(_referridselect,8)],mainplan,2,2,3,amountplan);
                                            withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                        }//ok
                                    }
                                    else{
                                        
                                        Statics(userlist[findNodeUpline(_referridselect,8)],mainplan,2,2,3,amountplan);
                                        withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                    }
                                }
                                else{
                                    users[adminwallet].LevelPaid[mainplan][1][2][7]+=(amountplan * 25 / 100) / 1000000;
                                    users[adminwallet].LevelPaid[mainplan][2][1][7]+=(amountplan * 25 / 100) / 1000000;
                                    users[userlist[findNodeUpline(_referridselect,4)]].LevelPaid[mainplan][2][1][1]+=(amountplan * 50 / 100) / 1000000;
                                    users[userlist[findNodeUpline(_referridselect,4)]].LevelPaid[mainplan][2][1][2]++;
                                    withdraw(_referrid,userlist[findNodeUpline(_referridselect,4)],amountplan * 50 / 100,amountplan * 50 / 100);
                                }//ok
                            }
                            else{
                                
                                Statics(userlist[findNodeUpline(_referridselect,4)],mainplan,2,1,3,amountplan);
                                withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                            }//ok
                        }
                        else{
                            
                            Statics(userlist[findNodeUpline(_referridselect,4)],mainplan,2,1,3,amountplan);
                            withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                        }
                    }
                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,2)]].idintree,2,mainplan)==false && newplace==3){
                        ActivenewPlan(users[userlist[findNodeUpline(_referridselect,2)]].idintree,2,mainplan,_referridselect,true);
                    }
                }
                else if(newplace==2 || newplace==4 || newplace==6 || newplace==8 || newplace==10){//new plan 3
                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,2)]].idintree,1,mainplan)==true){
                        users[userlist[findNodeUpline(_referridselect,2)]].LevelPaid[mainplan][1][2][3]+=(amountplan * 75 / 100) / 1000000;
                        if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,5)]].idintree,1,mainplan)==true){
                            users[userlist[findNodeUpline(_referridselect,5)]].paidfromplans[mainplan][3][4]=users[userlist[findNodeUpline(_referridselect,5)]].paidfromplans[mainplan][3][4]+1;
                            if(users[userlist[findNodeUpline(_referridselect,5)]].paidfromplans[mainplan][3][4]<6){
                                
                                if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,5)]].idintree,3,mainplan)==true){
                                    users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][3][1][1]+=(amountplan * 75 / 100) / 1000000;
                                    users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][3][1][2]++;
                                    users[adminwallet].LevelPaid[mainplan][1][3][7]+=(amountplan * 25 / 100) / 1000000;
                                    withdraw(_referrid,userlist[findNodeUpline(_referridselect,5)],amountplan * 25 / 100,amountplan * 75 / 100);
                                }//ok
                                else{
                                    users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][1][3][3]+=(amountplan * 50 / 100) / 1000000;
                                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,8)]].idintree,1,mainplan)==true){
                                        if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,8)]].idintree,3,mainplan)==true){
                                            users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][3][5]=users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][3][5]+1;
                                            //////////////////////////////////////////////
                                            /////////////////////////////////////////////
                                            /////////////////////////////////////////////
                                            if(divnum((users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][3][5])-1,5)==1 && ((users[userlist[findNodeUpline(_referridselect,8)]].paidfromplans[mainplan][3][5])/5)<10){
                                                users[userlist[findNodeUpline(_referridselect,8)]].LevelPaid[mainplan][3][1][3]+=(amountplan * 50 / 100) / 1000000;
                                                if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,14)]].idintree,1,mainplan)==true){
                                                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,14)]].idintree,3,mainplan)==true){
                                                        users[userlist[findNodeUpline(_referridselect,14)]].LevelPaid[mainplan][3][2][1]+=(amountplan * 50 / 100) / 1000000;
                                                        users[userlist[findNodeUpline(_referridselect,14)]].LevelPaid[mainplan][3][2][2]++;
                                                        users[adminwallet].LevelPaid[mainplan][1][3][7]+=(amountplan * 25 / 100) / 1000000;
                                                        users[adminwallet].LevelPaid[mainplan][3][2][7]+=(amountplan * 25 / 100) / 1000000;
                                                        withdraw(_referrid,userlist[findNodeUpline(_referridselect,14)],amountplan * 50 / 100,amountplan * 50 / 100);
                                                    }//ok
                                                    else{
                                                        Statics(userlist[findNodeUpline(_referridselect,14)],mainplan,3,2,2,amountplan);
                                                        withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                                    }//ok
                                                }
                                                else{
                                                    Statics(userlist[findNodeUpline(_referridselect,14)],mainplan,3,2,2,amountplan);
                                                    withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                                }
                                            }
                                            else{
                                                users[userlist[findNodeUpline(_referridselect,8)]].LevelPaid[mainplan][3][1][1]+=(amountplan * 50 / 100) / 1000000;
                                                users[userlist[findNodeUpline(_referridselect,8)]].LevelPaid[mainplan][3][1][2]++;
                                                users[adminwallet].LevelPaid[mainplan][1][3][7]+=(amountplan * 25 / 100) / 1000000;
                                                users[adminwallet].LevelPaid[mainplan][3][1][7]+=(amountplan * 25 / 100) / 1000000;
                                                users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][1][3][3]+=(amountplan * 50 / 100) / 1000000;
                                                withdraw(_referrid,userlist[findNodeUpline(_referridselect,8)],amountplan * 50 / 100,amountplan * 50 / 100);
                                            }//ok
                                        }
                                        else{
                                            Statics(userlist[findNodeUpline(_referridselect,8)],mainplan,3,1,2,amountplan);
                                            withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                        }//ok
                                    }
                                    else{
                                    Statics(userlist[findNodeUpline(_referridselect,8)],mainplan,3,1,2,amountplan);
                                        withdraw(_referrid,adminwallet,amountplan * 50 / 100,amountplan * 50 / 100);
                                    }
                                }
                                if(users[userlist[findNodeUpline(_referridselect,5)]].paidfromplans[mainplan][3][4]==5)
                                {
                                    ActivenewPlan(users[userlist[findNodeUpline(_referridselect,5)]].idintree,3,mainplan,_referridselect,true);
                                }
                            }
                            else
                            {
                                
                                if(divnum((users[userlist[findNodeUpline(_referridselect,5)]].paidfromplans[mainplan][3][4])-1,5)==1 && ((users[userlist[findNodeUpline(_referridselect,5)]].paidfromplans[mainplan][3][4])/5)<10){
                                    users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][1][3][3]+=(amountplan * 75 / 100) / 1000000;
                                    if(checkactiveplan(users[userlist[findNodeUpline(_referridselect,9)]].idintree,1,mainplan)==true){
                                        users[userlist[findNodeUpline(_referridselect,9)]].LevelPaid[mainplan][1][4][1]+=(amountplan * 75 / 100) / 1000000;
                                        users[userlist[findNodeUpline(_referridselect,9)]].LevelPaid[mainplan][1][4][2]++;
                                        users[adminwallet].LevelPaid[mainplan][1][4][7]+=(amountplan * 25 / 100) / 1000000;
                                        withdraw(_referrid,userlist[findNodeUpline(_referridselect,9)],amountplan * 25 / 100,amountplan * 75 / 100);
                                    }
                                    else{
                                        users[userlist[findNodeUpline(_referridselect,9)]].LevelPaid[mainplan][1][4][4]+=(amountplan * 75 / 100) / 1000000;
                                        users[adminwallet].LevelPaid[mainplan][1][4][7]+=(amountplan * 25 / 100) / 1000000;
                                        users[adminwallet].LevelPaid[mainplan][1][4][8]+=(amountplan * 75 / 100) / 1000000;
                                        Statics(userlist[findNodeUpline(_referridselect,9)],mainplan,1,4,1,amountplan);
                                        withdraw(_referrid,adminwallet,amountplan * 25 / 100,amountplan * 75 / 100);
                                    }
                                }//ok
                                else{
                                    users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][1][3][1]+=(amountplan * 75 / 100) / 1000000;
                                    users[userlist[findNodeUpline(_referridselect,5)]].LevelPaid[mainplan][1][3][2]++;
                                    users[adminwallet].LevelPaid[mainplan][1][3][7]+=(amountplan * 25 / 100) / 1000000;
                                    withdraw(_referrid,userlist[findNodeUpline(_referridselect,5)],amountplan * 25 / 100,amountplan * 75 / 100);
                                }//ok
                            }
                        }
                        else{
                            Statics(userlist[findNodeUpline(_referridselect,5)],mainplan,1,3,1,amountplan);
                            withdraw(_referrid,adminwallet,amountplan * 25 / 100,amountplan * 75 / 100);
                        }
                    }
                    else{
                        Statics(userlist[findNodeUpline(_referridselect,2)],mainplan,1,1,1,amountplan);
                        withdraw(_referrid,adminwallet,amountplan * 25 / 100,amountplan * 75 / 100);
                    }
                }
                else{
                    users[userlist[findNodeUpline(_referridselect,2)]].LevelPaid[mainplan][1][2][1]+=(amountplan * 75 / 100) / 1000000;
                    users[userlist[findNodeUpline(_referridselect,2)]].LevelPaid[mainplan][1][2][2]++;
                    users[adminwallet].LevelPaid[mainplan][1][2][7]+=(amountplan * 25 / 100) / 1000000;
                    withdraw(_referrid,userlist[findNodeUpline(_referridselect,2)],amountplan * 25 / 100,amountplan * 75 / 100);
                }//ok
            }
            else{
                Statics(userlist[findNodeUpline(_referridselect,2)],mainplan,1,1,1,amountplan);
                withdraw(_referrid,adminwallet,amountplan * 25 / 100,amountplan * 75 / 100);
            }
        }
        else{
            if(checkactiveplan(parentid,1,mainplan)==true){
                users[userlist[findNodeUpline(_referridselect,0)]].LevelPaid[mainplan][1][1][1]+=(amountplan * 75 / 100) / 1000000;
                users[userlist[findNodeUpline(_referridselect,0)]].LevelPaid[mainplan][1][1][2]++;
                users[adminwallet].LevelPaid[mainplan][1][1][7]+=(amountplan * 25 / 100) / 1000000;
                withdraw(_referrid,userlist[parentid],amountplan * 25 / 100,amountplan * 75 / 100);
            }
            else{
                Statics(userlist[findNodeUpline(_referridselect,0)],mainplan,1,1,1,amountplan);//ok
                withdraw(_referrid,adminwallet,amountplan * 25 / 100,amountplan * 75 / 100);
            }
        }//ok
        ActiveMainPlan(_referridselect,mainplan,true);
        return "Done!";   
    }
    function Statics(address _referralAddress,uint mainplanid,uint newplanid,uint levelid,uint typereport,uint amountplan )private{
        if(typereport==1){
                users[_referralAddress].LevelPaid[mainplanid][newplanid][levelid][4]+=(amountplan * 75 / 100) / 1000000;
                users[adminwallet].LevelPaid[mainplanid][newplanid][levelid][7]+=(amountplan * 25 / 100) / 1000000;
                users[adminwallet].LevelPaid[mainplanid][newplanid][levelid][8]+=(amountplan * 75 / 100) / 1000000;
        }
        else if(typereport==2){
            users[_referralAddress].LevelPaid[mainplanid][newplanid][levelid][4]+=(amountplan * 50 / 100) / 1000000;
            users[adminwallet].LevelPaid[mainplanid][1][3][7]+=(amountplan * 25 / 100) / 1000000;
            users[adminwallet].LevelPaid[mainplanid][newplanid][levelid][7]+=(amountplan * 25 / 100) / 1000000;
            users[adminwallet].LevelPaid[mainplanid][newplanid][levelid][8]+=(amountplan * 50 / 100) / 1000000;
        }
        else if (typereport==3){
            users[adminwallet].LevelPaid[mainplanid][1][2][7]+=(amountplan * 25 / 100) / 1000000;
            users[adminwallet].LevelPaid[mainplanid][newplanid][levelid][7]+=(amountplan * 25 / 100) / 1000000;
            users[adminwallet].LevelPaid[mainplanid][newplanid][levelid][8]+=(amountplan * 50 / 100) / 1000000;                        
            users[_referralAddress].LevelPaid[mainplanid][newplanid][levelid][4]+=(amountplan * 50 / 100) / 1000000;
        }
        
    }
    function BuyNewPlan(address payable referreralid ,uint planid,uint _mainplanid)public payable  returns(string memory){
        uint countpay=0;
        uint planamount=planprice[_mainplanid];
        countpay=PlanPaidNewPlan(users[referreralid].idintree,planid,_mainplanid);
        require(checkactiveplan(users[referreralid].idintree,planid-1,_mainplanid)==true,"You Should Buy Previews New Plan!");
        require(checkactiveplan(users[referreralid].idintree,planid,_mainplanid)==false,"Already You Bought This New Plan!");
        require(users[referreralid].idintree > 0 && users[referreralid].idintree <= LastNode, "Incorrect referrer Id");
        require(users[referreralid].isRegister == true, "User Not exist");
        uint referrisselect=users[referreralid].idintree;
        address userAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        if(planid==2)
        {
            uint amountPlan=(2 - countpay) * (planamount * 75 / 100);
            require(msg.value == amountPlan, "Your wallet balance is not enough");

            for(uint i=0;i<2-countpay;i++){
                if(checkactiveplan(findNodeUpline(referrisselect,1),1,_mainplanid)==true){
                    if(checkactiveplan(findNodeUpline(referrisselect,1),planid,_mainplanid)==true){
                        users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]=users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]+1;
                        if((users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]>=3 && users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]<=4) || (users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]>=7 && users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]<=8) || (users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]>=11 && users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]<=12) || (users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]>=15 && users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]<=16) || (users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]>=19 && users[userlist[findNodeUpline(referrisselect,1)]].paidfromplans[_mainplanid][planid][2]<=20)){
                            users[userlist[findNodeUpline(referrisselect,1)]].LevelPaid[_mainplanid][2][1][3]+=(amountPlan * 50 / 100) / 1000000;
                             if(checkactiveplan(findNodeUpline(referrisselect,5),1,_mainplanid)==true){
                                if(checkactiveplan(findNodeUpline(referrisselect,5),planid,_mainplanid)==true){
                                    users[userlist[findNodeUpline(referrisselect,5)]].paidfromplans[_mainplanid][planid][3]=users[userlist[findNodeUpline(referrisselect,5)]].paidfromplans[_mainplanid][planid][3]+1;
                                    if(divnum((users[userlist[findNodeUpline(referrisselect,5)]].paidfromplans[_mainplanid][planid][3])-1,10)==1 && ((users[userlist[findNodeUpline(referrisselect,5)]].paidfromplans[_mainplanid][planid][3])/10)<10){
                                        users[userlist[findNodeUpline(referrisselect,5)]].LevelPaid[_mainplanid][2][2][3]+=(amountPlan * 50 / 100) / 1000000;
                                        if(checkactiveplan(findNodeUpline(referrisselect,7),1,_mainplanid)==true){
                                            if(checkactiveplan(findNodeUpline(referrisselect,7),planid,_mainplanid)==true){
                                                users[userlist[findNodeUpline(referrisselect,7)]].LevelPaid[_mainplanid][2][3][1]+=(planamount * 50 / 100)/1000000;
                                                users[userlist[findNodeUpline(referrisselect,7)]].LevelPaid[_mainplanid][2][3][2]++;
                                                users[adminwallet].LevelPaid[_mainplanid][1][2][7]+=(planamount * 25 / 100)/ 1000000;
                                                users[adminwallet].LevelPaid[_mainplanid][2][3][7]+=(planamount * 25 / 100)/ 1000000;
                                                withdraw(referreralid,userlist[findNodeUpline(referrisselect,7)],(planamount * 25 / 100),(planamount * 50 / 100));
                                            }
                                            else{
                                                Statics(userlist[findNodeUpline(referrisselect,7)],_mainplanid,2,3,3,planamount);
                                                withdraw(referreralid,adminwallet,(planamount * 25 / 100),(planamount * 50 / 100));
                                            }
                                        }
                                        else{
                                            Statics(userlist[findNodeUpline(referrisselect,7)],_mainplanid,2,3,3,planamount);
                                            withdraw(referreralid,adminwallet,(planamount * 25 / 100),(planamount * 50 / 100));
                                        }
                                    }
                                    else{
                                        users[adminwallet].LevelPaid[_mainplanid][1][2][7]+=(planamount * 25 / 100)/ 1000000;
                                        users[adminwallet].LevelPaid[_mainplanid][2][2][7]+=(planamount * 25 / 100)/ 1000000;
                                        users[userlist[findNodeUpline(referrisselect,5)]].LevelPaid[_mainplanid][2][2][1]+=(planamount * 50 / 100) / 1000000;
                                        users[userlist[findNodeUpline(referrisselect,5)]].LevelPaid[_mainplanid][2][2][2]++;
                                        withdraw(referreralid,userlist[findNodeUpline(referrisselect,5)],(planamount * 25 / 100) ,(planamount * 50 / 100));
                                    }    
                                    
                                }
                                else{
                                    Statics(userlist[findNodeUpline(referrisselect,5)],_mainplanid,2,2,3,planamount);
                                    withdraw(referreralid,adminwallet,(planamount * 25 / 100),(planamount * 50 / 100));
                                }
                             }
                             else{
                                Statics(userlist[findNodeUpline(referrisselect,5)],_mainplanid,2,2,3,planamount);
                                withdraw(referreralid,adminwallet,(planamount * 25 / 100),(planamount * 50 / 100));
                             }
                        }
                        else{
                            users[adminwallet].LevelPaid[_mainplanid][1][2][7]+=(planamount * 25 / 100)/ 1000000;
                            users[adminwallet].LevelPaid[_mainplanid][2][1][7]+=(planamount * 25 / 100)/ 1000000;
                            users[userlist[findNodeUpline(referrisselect,1)]].LevelPaid[_mainplanid][2][1][1]+=(planamount * 50 / 100) / 1000000;
                            users[userlist[findNodeUpline(referrisselect,1)]].LevelPaid[_mainplanid][2][1][2]++;
                            withdraw(referreralid,userlist[findNodeUpline(referrisselect,1)],(planamount * 25 / 100),(planamount * 50 / 100));
                        }
                    }
                    else{
                        Statics(userlist[findNodeUpline(referrisselect,1)],_mainplanid,2,1,3,planamount);
                        withdraw(referreralid,adminwallet,(planamount * 25 / 100),(planamount * 50 / 100));
                    }
                    
                }
                else{
                    Statics(userlist[findNodeUpline(referrisselect,1)],_mainplanid,2,1,3,planamount);
                    withdraw(referreralid,adminwallet,(planamount * 25 / 100),(planamount * 50 / 100));
                }
           }
           users[referreralid].paidfromplans[_mainplanid][planid][1]=2; 
        }
        else if(planid==3){
            uint amountPlan=(5-countpay) * (planamount* 75 / 100);
            require(checkactiveplan(referrisselect,2,_mainplanid)==true,"First you must Buy New Plan 2!");
            require(msg.value == amountPlan, "Your wallet balance is not enough");
            for(uint i=0;i<5-countpay;i++){
                if(checkactiveplan(findNodeUpline(referrisselect,2),1,_mainplanid)==true){
                    if(checkactiveplan(findNodeUpline(referrisselect,2),3,_mainplanid)==true){
                        users[userlist[findNodeUpline(referrisselect,2)]].paidfromplans[_mainplanid][planid][5]=users[userlist[findNodeUpline(referrisselect,2)]].paidfromplans[_mainplanid][planid][5]+1;
                        if(divnum((users[userlist[findNodeUpline(referrisselect,2)]].paidfromplans[_mainplanid][planid][5])-1,5)==1 && ((users[userlist[findNodeUpline(referrisselect,2)]].paidfromplans[_mainplanid][planid][5])/5)<10){
                            users[userlist[findNodeUpline(referrisselect,2)]].LevelPaid[_mainplanid][3][1][3]+=(amountPlan * 50 / 100) / 1000000;
                            if(checkactiveplan(findNodeUpline(referrisselect,8),1,_mainplanid)==true){
                                if(checkactiveplan(findNodeUpline(referrisselect,8),3,_mainplanid)==true){
                                    users[userlist[findNodeUpline(referrisselect,8)]].LevelPaid[_mainplanid][3][2][1]+=(planamount * 50 / 100)/1000000;
                                    users[userlist[findNodeUpline(referrisselect,8)]].LevelPaid[_mainplanid][3][2][2]++;
                                    users[adminwallet].LevelPaid[_mainplanid][1][3][7]+=(planamount * 25 / 100)/ 1000000;
                                    withdraw(referreralid,userlist[findNodeUpline(referrisselect,8)],(planamount * 25 /100),(planamount * 50 / 100));
                                }
                                else{
                                    Statics(userlist[findNodeUpline(referrisselect,8)],_mainplanid,3,2,2,planamount);
                                    withdraw(referreralid,adminwallet,(planamount * 25 /100),(planamount * 50 / 100));
                                }
                            }
                            else{
                                Statics(userlist[findNodeUpline(referrisselect,8)],_mainplanid,3,2,2,planamount);
                                withdraw(referreralid,adminwallet,(planamount * 25 /100),(planamount * 50 / 100));
                            }
                        }
                        else{
                            users[userlist[findNodeUpline(referrisselect,2)]].LevelPaid[_mainplanid][3][1][1]+=(planamount * 50 / 100)/1000000 ;
                            users[userlist[findNodeUpline(referrisselect,2)]].LevelPaid[_mainplanid][3][1][2]++;
                            users[adminwallet].LevelPaid[_mainplanid][1][3][7]+=(planamount * 25 / 100)/ 1000000;
                            users[adminwallet].LevelPaid[_mainplanid][3][1][7]+=(planamount * 25 / 100)/ 1000000;
                            withdraw(referreralid,userlist[findNodeUpline(referrisselect,2)],(planamount * 25 /100),(planamount * 50 / 100));
                        }
                    }
                    else{
                        Statics(userlist[findNodeUpline(referrisselect,2)],_mainplanid,3,1,2,planamount);
                        withdraw(referreralid,adminwallet,(planamount * 25 /100),(planamount * 50 / 100));
                    }
                }
                else{
                    Statics(userlist[findNodeUpline(referrisselect,2)],_mainplanid,3,1,2,planamount);
                    withdraw(referreralid,adminwallet,(planamount * 25 /100),(planamount * 50 / 100));
                    
                }
            }
            users[referreralid].paidfromplans[_mainplanid][planid][4]=5;
        }
        ActivenewPlan(referrisselect,planid,_mainplanid,referrisselect,true);
        return "Done!";  
    }
    function findNodeUpline(uint _nodeid,uint uplineid) view public returns(uint){
        uint parentid= users[userlist[_nodeid]].referreid;
        for(uint i=0;i<uplineid;i++){
            parentid=getParent(parentid);
        }
        return parentid;
    }
    function getParent(uint _nodeid)view public returns(uint) {
        return users[userlist[_nodeid]].referreid;
    }
    function checkactiveplan(uint _referrid,uint _planid,uint _mainplan)public view returns(bool) {
        if(users[userlist[_referrid]].activenewplan[_mainplan][_planid]==true){
            return true;
        }
        else{
            return false;
        }
    }
    function PlanPaidNewPlan(uint _referrid,uint _planid,uint _mainplanid)public view returns(uint) {
        if(_planid==2){
            return users[userlist[_referrid]].paidfromplans[_mainplanid][_planid][1];
        }
        else  if(_planid==3){
            return users[userlist[_referrid]].paidfromplans[_mainplanid][_planid][4];
        }
        
    }
    function ReturnAllDataReport(address referraddress,uint MainPlan,uint planid,uint levelid)public view returns(uint,uint,uint,uint){
       if(referraddress==adminwallet){
        return(users[referraddress].LevelPaid[MainPlan][planid][levelid][1],
       users[referraddress].LevelPaid[MainPlan][planid][levelid][2],
       users[referraddress].LevelPaid[MainPlan][planid][levelid][7],
       users[referraddress].LevelPaid[MainPlan][planid][levelid][8]);
       }else{
        return(users[referraddress].LevelPaid[MainPlan][planid][levelid][1],
       users[referraddress].LevelPaid[MainPlan][planid][levelid][2],
       users[referraddress].LevelPaid[MainPlan][planid][levelid][3],
       users[referraddress].LevelPaid[MainPlan][planid][levelid][4]);
       }
       

    }
    function ReturnPlansStatuse(address referraddress)public view returns(uint,uint ){
        if(users[referraddress].activenewplan[6][3]==true){
            return (6,3);
        }
        else if(users[referraddress].activenewplan[6][2]==true){
                return (6,2);
        }
        else if(users[referraddress].activenewplan[6][1]==true){
                return (6,1);
        }
        else if(users[referraddress].activenewplan[5][3]==true){
            return (5,3);
        }
        else if(users[referraddress].activenewplan[5][2]==true){
                return (5,2);
        }
        else if(users[referraddress].activenewplan[5][1]==true){
                return (5,1);
        }
        else if(users[referraddress].activenewplan[4][3]==true){
            return (4,3);
        }
        else if(users[referraddress].activenewplan[4][2]==true){
                return (4,2);
        }
        else if(users[referraddress].activenewplan[4][1]==true){
                return (4,1);
        }
        else if(users[referraddress].activenewplan[3][3]==true){
            return (3,3);
        }
        else if(users[referraddress].activenewplan[3][2]==true){
                return (3,2);
        }
        else if(users[referraddress].activenewplan[3][1]==true){
                return (3,1);
        }
        else if(users[referraddress].activenewplan[2][3]==true){
            return (2,3);
        }
        else if(users[referraddress].activenewplan[2][2]==true){
                return (2,2);
        }
        else if(users[referraddress].activenewplan[2][1]==true){
                return (2,1);
        }
        else if(users[referraddress].activenewplan[1][3]==true){
            return (1,3);
        }
        else if(users[referraddress].activenewplan[1][2]==true){
                return (1,2);
        }
        else{
                return (1,1);
        }
    }
    function getAllNodeActive(uint _nodeid) public view returns (uint[] memory){
        uint[] memory ret = new uint[](users[userlist[_nodeid]].referrals[1][1].length);
        for (uint i = 0; i < users[userlist[_nodeid]].referrals[1][1].length; i++) {
            ret[i] = users[userlist[_nodeid]].referrals[1][1][i];
        }
        return ret;
    }
}