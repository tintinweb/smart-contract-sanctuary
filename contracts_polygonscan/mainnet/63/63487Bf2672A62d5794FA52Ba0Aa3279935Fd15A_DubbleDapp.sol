// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
import "./IERC20.sol";import "./CERC20.sol";import "./SafeMath.sol";
contract DubbleDapp is SafeMath {
    /*[ CONTRACT ADDRESSES ]--------------------------------------------------------------------------------------------------------*/
    address public owner = msg.sender;                                              /*                                              */
    address public developer = address(0x4f158D866CD0eb72bb642bBbD8D3c5Cc676E3551); /* Development Teams Address                    */
    address public marketing = address(0x08BFcad8b37ee488cd43fdAa87700a4c7FA2A9A3); /* Marketing Departments Address                */
    address public governor = address(0x4f158D866CD0eb72bb642bBbD8D3c5Cc676E3551);  /* Address for future governance contract       */
    /*[ USER DATA ]-----------------------------------------------------------------------------------------------------------------*/
    mapping(address => uint) public UID;                            /* Each users assigned ID number                                */
    mapping(address => bool) public isUser;                         /* Wether a User exists                                         */
    mapping(address => address) public usersReferrer;               /* Address of Referrer                                          */
    mapping(address => uint) public referralQty;                    /* Total Referral Quantity                                      */
    bool[][] public paywith_BAL;                                    /* [FID][UID] = Pay With Balance Preference                     */
    bool[][] public paywith_BON;                                    /* [FID][UID] = Pay With Bonus Preference                       */
    bool[][] public paywith_COM;                                    /* [FID][UID] = Pay With Commissions Preference                 */
    address[] public userID;                                        /* [UID] = A users address in relation to their ID              */
    uint256[][] public usersTicketQty;                              /* [FID][UID] = A Users Ticket quantity                         */
    uint256[][] public closedTickets;                               /* [FID][UID] = A Users Closed Ticket quantity                  */
    uint256[][] public totalPurchases;                              /* [FID][UID] = A Users Total amount of Deposits                */
    uint256[][] public usersBalance;                                /* [FID][UID] = A Users Token Balance                           */
    uint256[][] public totalReturns;                                /* [FID][UID] = Total Earned from Tickets                       */
    uint256[][] public usersBonus;                                  /* [FID][UID] = A Users Bonus Balance                           */
    uint256[][] public totalJackpots;                               /* [FID][UID] = Total Earned from Jackpots                      */
    uint256[][] public totalProcesses;                              /* [FID][UID] = Total Earned from Processing Yield Earned       */
    uint256[][] public usersCommissions;                            /* [FID][UID] = A Users Commissions Balance                     */
    uint256[][] public totalCommissions;                            /* [FID][UID] = Total Commissions Earned                        */
    /*[ CONTRACT DATA ]-------------------------------------------------------------------------------------------------------------*/
    address[] public TOKENaddy;                                     /* [FID] = TOKEN address                                        */
    address[] public cTOKENaddy;                                    /* [FID] = cTOKEN address                                       */
    uint256[] public decimals;                                      /* [FID] = The Decimal format                                   */
    uint256[] public purchasePrice;                                 /* [FID] = Purchase price of each Ticket                        */
    uint256[] public totalGlobalTickets;                            /* [FID] = The total Global Ticket numbers                      */
    uint256[][] public globalTickets;                               /* [FID][TID]  = UID of each Ticket holder (global)             */
    uint256[][] public roundsTickets_0;                             /* [RID][rTID] = UID of each Ticket holder (per round)          */
    uint256[][] public roundsTickets_1;                             /* [RID][rTID] = UID of each Ticket holder (per round)          */
    uint256[][] public roundsTickets_2;                             /* [RID][rTID] = UID of each Ticket holder (per round)          */
    uint256[][] public globalTicketBal;                             /* [FID][TID]  = Balance of each Ticket (global)                */
    uint256[][] public roundsTicketBal_0;                           /* [RID][rTID] = Balance of each Ticket (per round)             */
    uint256[][] public roundsTicketBal_1;                           /* [RID][rTID] = Balance of each Ticket (per round)             */
    uint256[][] public roundsTicketBal_2;                           /* [RID][rTID] = Balance of each Ticket (per round)             */
    uint256[][] public tickRoundStarted;                            /* [FID][RID]  = Global Ticket number each round Started on     */
    uint256[][] public tickRoundEnded;                              /* [FID][RID]  = Global Ticket number each round Ended on       */
    uint256[][] public timeRoundEnded;                              /* [FID][RID]  = UNIX Timestamp of when a Round Ended           */
    uint256[][] public totalRoundTickets;                           /* [FID][RID]  = The total Ticket numbers per Round             */
    uint256[] public globalTicket;                                  /* [FID] = The current Global Ticket number (aka TID)           */
    uint256[] public roundsTicket;                                  /* [FID] = The current Rounds Ticket number (aka rTID)          */
    uint256[] public pendingTicket;                                 /* [FID] = The current pending Global Ticket number (aka TID)   */
    uint256[] public currentRound;                                  /* [FID] = The current Round number (aka RID)                   */
    uint256[] public pendingRound;                                  /* [FID] = The current pending Round number (aka RID)           */
    uint256[] public lastPurchase;                                  /* [FID] = UNIX Timestamp of when the Last Purchase was made    */
    address[] public lastPurchaser;                                 /* [FID] = Address of the Last Purchaser                        */
    uint256[] public contractBalance;                               /* [FID] = Amount currently in the Contract                     */
    uint256[] public pendingYield;                                  /* [FID] = Amount waiting for Old Ticket Holders                */
    uint256[] public pendingProfit;                                 /* [FID] = Amount waiting for Current Ticket Holders            */
    uint256[] public totalReserves;                                 /* [FID] = Total Amount kept by Yield Farm                      */
    uint256[] public poolStatus;                                    /* [FID] = Pool Status: Created=0,Active=1,Paused=2,Ended=3     */
    uint256[] public farmStatus;                                    /* [FID] = Farm Status: Paused=0,Active=1                       */
    uint256[] public bonusPot;                                      /* [FID] = Total Amount currently in the Bonus Pot              */
    uint256[] public insurancePot;                                  /* [FID] = Total Amount reserved for crisis-compensation        */
    uint256[] public createDate;                                    /* [FID] = UNIX formatted date that a Farm was created          */
    uint256[] public startDelay;                                    /* [FID] = UNIX formatted time delay before a Farm goes live    */
    uint256[] public alarmClock;                                    /* [FID] = UNIX formatted time limit before a round ends        */
    uint256 public baseClock;                                       /* The Base UNIX formatted timelimit before a round ends        */
    uint256 public intermission;                                    /* UNIX formatted time limit before a new round begins          */
    uint256 public lastUID;                                         /* Last UID created                                             */
    uint256 public lastFID;                                         /* Last FID created                                             */   
    /*[ EVENTS ]--------------------------------------------------------------------------------------------------------------------*/
    event Purchase(address indexed user,uint256 indexed fID,uint256 rID,uint256 rTicket,uint256 gTicket,uint256 indexed time);/*    */
    event Process(address indexed user,uint256 indexed fID,uint256 rID,uint256 amount,uint256 indexed time);/*                      */
    event Cashout(address indexed user,uint256 indexed fID,uint256 method,uint256 amount,uint256 indexed time);/*                   */
    event Govern(address indexed user,uint256 indexed fID,uint256 method,uint256 amount,uint256 indexed time);/*                    */
    event RoundEnded(address indexed user,uint256 indexed fID,uint256 rID,uint256 indexed time);/*                                  */
    event Donation(address indexed user,uint256 indexed fID,uint256 amount,uint256 indexed time);/*                                 */
    /*[ DATA STRUCTURES ]-----------------------------------------------------------------------------------------------------------*/
    struct varData {/*                                                                                                              */
        address ref;uint256 uID;uint256 tID;uint256 rID;uint256 dID;uint256 fee;uint256 req;uint256 amt;uint256 cost;uint256 goal;/**/
        uint256 farm;uint256 rnd;uint256 tick;uint256 stamp;uint256 curRd;bool cont;/*                                              */
    }/*                                                                                                                             */
    /*[ BASIC FUNCTIONS ]-----------------------------------------------------------------------------------------------------------*/
    function getTime() public view returns(uint256) {return(block.timestamp);}
    function process(uint256 _fid) external {varData memory dat;
        require(isUser[msg.sender]==true,"NotUser");
        dat.amt=CERC20(cTOKENaddy[_fid]).balanceOfUnderlying(address(this));
        if(dat.amt>=totalReserves[_fid]){
            /*Farm intact - proceed*/
            dat.amt=sub(dat.amt,totalReserves[_fid]);
            pendingYield[_fid]=add(pendingYield[_fid],dat.amt);                          
            contractBalance[_fid]=add(contractBalance[_fid],dat.amt); 
        }else{/*Farm altered - update and prevent further supply*/
            totalReserves[_fid]=dat.amt;
            farmStatus[_fid]=0;
        }
        require(pendingYield[_fid]>0,"NoYield");
            /*GIVE CALLER 10% OF YIELD*/
        dat.tID=UID[msg.sender];
        dat.farm=pendingYield[_fid];
        dat.fee=div(pendingYield[_fid],10);/* ( 10%) => Callers Reward  */
        usersBonus[_fid][dat.tID]=add(usersBonus[_fid][dat.tID],dat.fee);
        totalProcesses[_fid][dat.tID]=add(totalProcesses[_fid][dat.tID],dat.fee);
        pendingYield[_fid]=sub(pendingYield[_fid],dat.fee);
            /*GIVE OLD HOLDERS 90% OF YIELD*/
        dat.goal=add(purchasePrice[_fid],div(purchasePrice[_fid],4));
        if(globalTicketBal[_fid][pendingTicket[_fid]]>=dat.goal){
            //pendingTicket already has more than the goal, Proceed to next Ticket
            dat.rnd = add(pendingRound[_fid],1);
            dat.tick= add(pendingTicket[_fid],1);
            if(dat.tick==tickRoundStarted[_fid][dat.rnd]){
                pendingTicket[_fid]=tickRoundEnded[_fid][dat.rnd];
                if(globalTicketBal[_fid][pendingTicket[_fid]]>=dat.goal){pendingTicket[_fid]=add(pendingTicket[_fid],1);}
                pendingRound[_fid]=add(pendingRound[_fid],1);
            }else{pendingTicket[_fid]=add(pendingTicket[_fid],1);}
        }

        dat.uID=globalTickets[_fid][pendingTicket[_fid]];
        dat.req=sub(dat.goal,globalTicketBal[_fid][pendingTicket[_fid]]);

        if(pendingYield[_fid]<dat.req){
            globalTicketBal[_fid][pendingTicket[_fid]]=add(globalTicketBal[_fid][pendingTicket[_fid]],pendingYield[_fid]);
            usersBalance[_fid][dat.uID]=add(usersBalance[_fid][dat.uID],pendingYield[_fid]);
            totalReturns[_fid][dat.uID]=add(totalReturns[_fid][dat.uID],pendingYield[_fid]);
            pendingYield[_fid]=0;
        }else
        if(pendingYield[_fid]>=dat.req){
            globalTicketBal[_fid][pendingTicket[_fid]]=add(globalTicketBal[_fid][pendingTicket[_fid]],dat.req);
            usersBalance[_fid][dat.uID]=add(usersBalance[_fid][dat.uID],dat.req);
            totalReturns[_fid][dat.uID]=add(totalReturns[_fid][dat.uID],dat.req);
            closedTickets[_fid][dat.uID]=add(closedTickets[_fid][dat.uID],1);
            pendingYield[_fid]=sub(pendingYield[_fid],dat.req);
            //Proceed to next Ticket
            dat.rnd = add(pendingRound[_fid],1);
            dat.tick= add(pendingTicket[_fid],1);
            if(dat.tick==tickRoundStarted[_fid][dat.rnd]){
                pendingTicket[_fid]=tickRoundEnded[_fid][dat.rnd];
                if(globalTicketBal[_fid][pendingTicket[_fid]]>=dat.goal){pendingTicket[_fid]=add(pendingTicket[_fid],1);}
                pendingRound[_fid]=add(pendingRound[_fid],1);
            }else{pendingTicket[_fid]=add(pendingTicket[_fid],1);}
        }

        if(dat.amt>0){/*PULL AMOUNT FROM FARM*/assert(CERC20(cTOKENaddy[_fid]).redeemUnderlying(dat.amt) == 0);}
        emit Process(msg.sender,_fid,pendingTicket[_fid],dat.farm,block.timestamp);
    }
    function endRound(uint256 _fid) external {varData memory dat;
        if(isUser[msg.sender]!=true){dat.cont=false;}else{dat.cont=true;}
        if(poolStatus[_fid]!=1){dat.cont=false;}
        dat.curRd=currentRound[_fid];
            //CHECK IF ROUND HASNT STARTED YET
        if((dat.curRd>1)&&(roundsTicket[_fid]==0)){ 
            dat.rnd=sub(dat.curRd,1);
            dat.stamp=timeRoundEnded[_fid][dat.rnd];
            dat.stamp=add(dat.stamp,intermission);
            if(block.timestamp<dat.stamp){dat.cont=false;}
        } 
            //MAKE SURE ROUND HAS ENDED
        if((dat.curRd>0)&&(roundsTicket[_fid]>0)&&(block.timestamp>add(lastPurchase[_fid],alarmClock[_fid]))){}else{dat.cont=false;}
        require(dat.cont==true,"ContErr");
        dat.tID=UID[msg.sender];
        dat.rID=UID[lastPurchaser[_fid]];
            //Initiate Round ending
        timeRoundEnded[_fid][dat.curRd]=block.timestamp;
        tickRoundEnded[_fid][dat.curRd]=globalTicket[_fid];
        currentRound[_fid]=add(dat.curRd,1);
        uint256 oldRd=dat.curRd;dat.curRd=add(dat.curRd,1);
        roundsTicket[_fid]=0;
        lastPurchase[_fid]=0;
        globalTicket[_fid]=add(totalGlobalTickets[_fid],1);
        if(_fid==0){roundsTickets_0.push([0]);roundsTicketBal_0.push([0]);}else
        if(_fid==1){roundsTickets_1.push([0]);roundsTicketBal_1.push([0]);}else
        if(_fid==2){roundsTickets_2.push([0]);roundsTicketBal_2.push([0]);}
        tickRoundStarted[_fid].push(globalTicket[_fid]);
        tickRoundEnded[_fid].push(0);
        timeRoundEnded[_fid].push(0);
        totalRoundTickets[_fid].push(0);
            //Give 90% of the Bonus Pot to the LastPurchaser
        dat.amt=mul(div(bonusPot[_fid],10),9);
        usersBonus[_fid][dat.rID]=add(usersBonus[_fid][dat.rID],dat.amt);
        totalJackpots[_fid][dat.rID]=add(totalJackpots[_fid][dat.rID],dat.amt);
        bonusPot[_fid]=sub(bonusPot[_fid],dat.amt);
            //Give 10% of the Bonus Pot to the msg.sender
        usersBonus[_fid][dat.tID]=add(usersBonus[_fid][dat.tID],bonusPot[_fid]);
        totalJackpots[_fid][dat.tID]=add(totalJackpots[_fid][dat.tID],bonusPot[_fid]);
        bonusPot[_fid]=0;
        emit RoundEnded(msg.sender,_fid,oldRd,block.timestamp);
    }
    function purchase(uint256 _fid,uint256 _amt,address _link,uint256 _useBal,uint256 _useBon,uint256 _useCom) external {varData memory dat;
        if(_amt==0){
            if(poolStatus[_fid]!=1){dat.cont=false;}else{dat.cont=true;}
            dat.curRd=currentRound[_fid];
                //CHECK IF FARM HASNT STARTED YET
            if(block.timestamp>=add(createDate[_fid],startDelay[_fid])){}else{dat.cont=false;}  
                //CHECK IF ROUND HASNT STARTED YET
            if((dat.curRd>1)&&(roundsTicket[_fid]==0)){ 
                dat.rnd=sub(dat.curRd,1);
                dat.stamp=timeRoundEnded[_fid][dat.rnd];
                dat.stamp=add(dat.stamp,intermission);
                if(block.timestamp<dat.stamp){dat.cont=false;}
            }  
                //MAKE SURE ROUND HAS NOT ENDED YET
            if((dat.curRd>0)&&(roundsTicket[_fid]>0)&&(block.timestamp>add(lastPurchase[_fid],alarmClock[_fid]))){dat.cont=false;}
            require(dat.cont==true,"ContErr");
                //PURCHASE TICKET
            if(isUser[msg.sender]){
                dat.tID=UID[msg.sender];
                dat.ref=usersReferrer[msg.sender];
                dat.rID=UID[dat.ref];
            }else{
                    /*CREATE USER ACCOUNT*/
                isUser[msg.sender]=true;
                lastUID=add(lastUID,1);
                dat.tID=lastUID;
                UID[msg.sender]=lastUID;
                userID.push(msg.sender);
                for(uint y=0;y<3;y++){
                    paywith_BAL[y].push(false);
                    paywith_BON[y].push(false);
                    paywith_COM[y].push(false);
                    usersTicketQty[y].push(0);
                    closedTickets[y].push(0);
                    totalPurchases[y].push(0);
                    usersBalance[y].push(0);
                    totalReturns[y].push(0);
                    usersBonus[y].push(0);
                    totalJackpots[y].push(0);
                    totalProcesses[y].push(0);
                    usersCommissions[y].push(0);
                    totalCommissions[y].push(0);
                }
                    /*ADD REFERRERS LINK*/
                dat.ref=_link;
                if(dat.ref==msg.sender){dat.ref=marketing;}
                if(!isUser[dat.ref]) { /*User does NOT exist, make Marketing their Referrer*/
                    usersReferrer[msg.sender]=marketing;
                    referralQty[marketing]=add(referralQty[marketing],1);
                    dat.rID=UID[marketing];
                    dat.ref=marketing;
                }else{ /*User DOES exist, make it their Referrer*/
                    usersReferrer[msg.sender]=dat.ref;
                    referralQty[dat.ref]=add(referralQty[dat.ref],1);
                    dat.rID=UID[dat.ref];
                }
            }
                //Calculate Wallet Pull ahead of time
            if((_useBal==1)||(_useBon==1)||(_useCom==1)){
                uint256 required = purchasePrice[_fid];
                if((_useBal==1)&&(usersBalance[_fid][dat.tID]>0)&&(required>0)){
                    if(required>=usersBalance[_fid][dat.tID]){required=sub(required,usersBalance[_fid][dat.tID]);usersBalance[_fid][dat.tID]=0;}
                    else{usersBalance[_fid][dat.tID]=sub(usersBalance[_fid][dat.tID],required);required=0;}
                }
                if((_useBon==1)&&(usersBonus[_fid][dat.tID]>0)&&(required>0)){
                    if(required>=usersBonus[_fid][dat.tID]){required=sub(required,usersBonus[_fid][dat.tID]);usersBonus[_fid][dat.tID]=0;}
                    else{usersBonus[_fid][dat.tID]=sub(usersBonus[_fid][dat.tID],required);required=0;}
                }
                if((_useCom==1)&&(usersCommissions[_fid][dat.tID]>0)&&(required>0)){
                    if(required>=usersCommissions[_fid][dat.tID]){required=sub(required,usersCommissions[_fid][dat.tID]);usersCommissions[_fid][dat.tID]=0;}
                    else{usersCommissions[_fid][dat.tID]=sub(usersCommissions[_fid][dat.tID],required);required=0;}
                }
                contractBalance[_fid]=sub(contractBalance[_fid],sub(purchasePrice[_fid],required));
                dat.cost=required;
            }else{dat.cost=purchasePrice[_fid];}
                /*PROCESS FEES*/
            dat.fee=div(purchasePrice[_fid],100);
            pendingProfit[_fid]=add(pendingProfit[_fid],mul(dat.fee,75));                        /* (75.0%) => Current Ticket  */
            if(farmStatus[_fid]==1){dat.farm=mul(dat.fee,21);}                                   /* (21.0%) => Lending Pool    */
            else{dat.farm=0;pendingYield[_fid]=add(pendingYield[_fid],mul(dat.fee,21));}
            bonusPot[_fid]=add(bonusPot[_fid],dat.fee);                                          /* ( 1.0%) => Bonus Pot       */
            insurancePot[_fid]=add(insurancePot[_fid],dat.fee);                                  /* ( 1.0%) => Insurance Pot   */
            usersCommissions[_fid][dat.rID]=add(usersCommissions[_fid][dat.rID],dat.fee);        /* ( 1.0%) => their Referrer  */
                usersCommissions[_fid][dat.dID]=add(usersCommissions[_fid][dat.dID],dat.fee);    /* ( 1.0%) => the Developers  */
            totalCommissions[_fid][dat.rID]=add(totalCommissions[_fid][dat.rID],dat.fee);
                totalCommissions[_fid][dat.dID]=add(totalCommissions[_fid][dat.dID],dat.fee);
                /*GIVE CURRENT HOLDER 75% OF PURCHASE (or place in Bonus Pot if FIRST purchase)*/
            if((globalTicket[_fid]==0)||(roundsTicket[_fid]==0)||(globalTicket[_fid]>totalGlobalTickets[_fid])){
                bonusPot[_fid]=add(bonusPot[_fid],pendingProfit[_fid]);pendingProfit[_fid]=0;
            }else{
                dat.goal=mul(purchasePrice[_fid],2);
                if(_fid==0){dat.uID=roundsTickets_0[dat.curRd][roundsTicket[_fid]];dat.req=sub(dat.goal,roundsTicketBal_0[dat.curRd][roundsTicket[_fid]]);}else
                if(_fid==1){dat.uID=roundsTickets_1[dat.curRd][roundsTicket[_fid]];dat.req=sub(dat.goal,roundsTicketBal_1[dat.curRd][roundsTicket[_fid]]);}else
                if(_fid==2){dat.uID=roundsTickets_2[dat.curRd][roundsTicket[_fid]];dat.req=sub(dat.goal,roundsTicketBal_2[dat.curRd][roundsTicket[_fid]]);}
                if(pendingProfit[_fid]<dat.req){
                        //Update each Ticket Balance
                    if(_fid==0){roundsTicketBal_0[dat.curRd][roundsTicket[_fid]]=add(roundsTicketBal_0[dat.curRd][roundsTicket[_fid]],pendingProfit[_fid]);}else
                    if(_fid==1){roundsTicketBal_1[dat.curRd][roundsTicket[_fid]]=add(roundsTicketBal_1[dat.curRd][roundsTicket[_fid]],pendingProfit[_fid]);}else
                    if(_fid==2){roundsTicketBal_2[dat.curRd][roundsTicket[_fid]]=add(roundsTicketBal_2[dat.curRd][roundsTicket[_fid]],pendingProfit[_fid]);}
                    globalTicketBal[_fid][globalTicket[_fid]]=add(globalTicketBal[_fid][globalTicket[_fid]],pendingProfit[_fid]);
                        //Update the Users Balance
                    usersBalance[_fid][dat.uID]=add(usersBalance[_fid][dat.uID],pendingProfit[_fid]);
                    totalReturns[_fid][dat.uID]=add(totalReturns[_fid][dat.uID],pendingProfit[_fid]);
                    pendingProfit[_fid]=0;
                }else
                if(pendingProfit[_fid]>=dat.req){
                        //Update each Ticket Balance
                    if(_fid==0){roundsTicketBal_0[dat.curRd][roundsTicket[_fid]]=add(roundsTicketBal_0[dat.curRd][roundsTicket[_fid]],dat.req);}else
                    if(_fid==1){roundsTicketBal_1[dat.curRd][roundsTicket[_fid]]=add(roundsTicketBal_1[dat.curRd][roundsTicket[_fid]],dat.req);}else
                    if(_fid==2){roundsTicketBal_2[dat.curRd][roundsTicket[_fid]]=add(roundsTicketBal_2[dat.curRd][roundsTicket[_fid]],dat.req);}
                    globalTicketBal[_fid][globalTicket[_fid]]=add(globalTicketBal[_fid][globalTicket[_fid]],dat.req);
                        //Update the Users Balance and closedTicket Qty
                    usersBalance[_fid][dat.uID]=add(usersBalance[_fid][dat.uID],dat.req);
                    totalReturns[_fid][dat.uID]=add(totalReturns[_fid][dat.uID],dat.req);
                    closedTickets[_fid][dat.uID]=add(closedTickets[_fid][dat.uID],1);
                        //Update the Pending Balance since we only took a little
                    pendingProfit[_fid]=sub(pendingProfit[_fid],dat.req);
                        //Proceed to next Ticket
                    globalTicket[_fid]=add(globalTicket[_fid],1);
                    roundsTicket[_fid]=add(roundsTicket[_fid],1);
                    if(dat.curRd==pendingRound[_fid]){pendingTicket[_fid]=add(pendingTicket[_fid],1);}
                }
            }
                /*UPDATE USER*/
            totalPurchases[_fid][dat.tID]=add(totalPurchases[_fid][dat.tID],purchasePrice[_fid]);
            usersTicketQty[_fid][dat.tID]=add(usersTicketQty[_fid][dat.tID],1);
            if(_useBal==0){paywith_BAL[_fid][dat.tID]=false;}else{paywith_BAL[_fid][dat.tID]=true;}
            if(_useBon==0){paywith_BON[_fid][dat.tID]=false;}else{paywith_BON[_fid][dat.tID]=true;}
            if(_useCom==0){paywith_COM[_fid][dat.tID]=false;}else{paywith_COM[_fid][dat.tID]=true;}
                /*UPDATE CONTRACT*/
            if(currentRound[_fid]==0){currentRound[_fid]=1;dat.curRd=1;}
            if(roundsTicket[_fid]==0){roundsTicket[_fid]=1;}
            if(globalTicket[_fid]==0){globalTicket[_fid]=1;}
            if(pendingTicket[_fid]==0){pendingTicket[_fid]=1;}
            totalGlobalTickets[_fid]=add(totalGlobalTickets[_fid],1);
            totalRoundTickets[_fid][dat.curRd]=add(totalRoundTickets[_fid][dat.curRd],1);
            globalTickets[_fid].push(dat.tID);
            globalTicketBal[_fid].push(0);
            if(_fid==0){roundsTickets_0[dat.curRd].push(dat.tID);roundsTicketBal_0[dat.curRd].push(0);}else
            if(_fid==1){roundsTickets_1[dat.curRd].push(dat.tID);roundsTicketBal_1[dat.curRd].push(0);}else
            if(_fid==2){roundsTickets_2[dat.curRd].push(dat.tID);roundsTicketBal_2[dat.curRd].push(0);}
            lastPurchase[_fid]=block.timestamp;
            lastPurchaser[_fid]=msg.sender;
            if(roundsTicket[_fid]==100){alarmClock[_fid]=(45 minutes);}else
            if(roundsTicket[_fid]==1000){alarmClock[_fid]=(30 minutes);}else
            if(roundsTicket[_fid]==10000){alarmClock[_fid]=(15 minutes);}else
            if(roundsTicket[_fid]==100000){alarmClock[_fid]=(5 minutes);}else
            if(roundsTicket[_fid]==1000000){alarmClock[_fid]=(60 seconds);}
            if(farmStatus[_fid]==1){contractBalance[_fid]=add(contractBalance[_fid],mul(dat.fee,79));
                totalReserves[_fid]=add(totalReserves[_fid],dat.farm);
            }else{contractBalance[_fid]=add(contractBalance[_fid],mul(dat.fee,100));}
        }else{
            dat.cost=_amt;
            contractBalance[_fid]=add(contractBalance[_fid],_amt);
            pendingYield[_fid]=add(pendingYield[_fid],_amt);
        }    

        if(dat.cost>0){
            require(IERC20(TOKENaddy[_fid]).balanceOf(msg.sender)>=dat.cost,"BalLow");
            require(IERC20(TOKENaddy[_fid]).allowance(msg.sender,address(this))>=dat.cost,"AllLow");
                /*DEPOSIT INTO CONTRACT*/
            require(IERC20(TOKENaddy[_fid]).transferFrom(msg.sender,address(this),dat.cost),"DepFail");
        }

        if(_amt==0){
            if(farmStatus[_fid]==1){/*APPROVE & SUPPLY TOKEN*/
                IERC20(TOKENaddy[_fid]).approve(address(CERC20(cTOKENaddy[_fid])), dat.farm);
                assert(CERC20(cTOKENaddy[_fid]).mint(dat.farm)==0);
            }
            emit Purchase(msg.sender,_fid,dat.curRd,roundsTicket[_fid],globalTicket[_fid],block.timestamp);
        }else{emit Donation(msg.sender,_fid,_amt,block.timestamp);}
    }
    function cashout(uint256 _fid,uint256 _meth) external {varData memory dat;
        if(isUser[msg.sender]!=true){dat.cont=false;}else{dat.cont=true;}
        dat.tID=UID[msg.sender];
        if(_meth==1){/*CASHOUT BALANCE*/dat.amt=usersBalance[_fid][dat.tID];usersBalance[_fid][dat.tID]=0;}else
        if(_meth==2){/*CASHOUT BONUSES*/dat.amt=usersBonus[_fid][dat.tID];usersBonus[_fid][dat.tID]=0;}else
        if(_meth==3){/*CASHOUT COMMISSIONS*/dat.amt=usersCommissions[_fid][dat.tID];usersCommissions[_fid][dat.tID]=0;}else
        if(_meth==4){/*CASHOUT EVERYTHING*/
            dat.amt=usersBalance[_fid][dat.tID];usersBalance[_fid][dat.tID]=0;
            dat.amt=add(dat.amt,usersBonus[_fid][dat.tID]);usersBonus[_fid][dat.tID]=0;
            dat.amt=add(dat.amt,usersCommissions[_fid][dat.tID]);usersCommissions[_fid][dat.tID]=0;
        }
        if(dat.amt<=0){dat.cont=false;}
        require(dat.cont==true,"ContErr");
            /*UPDATE CONTRACT*/
        contractBalance[_fid]=sub(contractBalance[_fid],dat.amt);    
            /*WITHDRAW FROM CONTRACT*/
        require(IERC20(TOKENaddy[_fid]).transfer(msg.sender,dat.amt), "TxnFai");
        emit Cashout(msg.sender,_fid,_meth,dat.amt,block.timestamp);
    }
    function govern(uint256 _fid,uint256 _meth,uint256 _amt,uint256 _num,address _addy,address _cTOKEN) external {
        require(msg.sender==governor,"NotGov");/*NOTE: A future governance contract will access these functions*/
        if(_meth==1){/*Change various Variables*/
            if(_num==1){governor=_addy;}else
            if(_num==2){baseClock=_amt;}else
            if(_num==3){intermission=_amt;}else
            if(_num==4){poolStatus[_fid]=_amt;}else
            if(_num==5){farmStatus[_fid]=_amt;}else
            if(_num==6){startDelay[_fid]=_amt;}else
            if(_num==7){purchasePrice[_fid]=_amt;}else
            if(_num==8){/*Pull from Insurance Fund to Pay Out Old Tickets*/
                insurancePot[_fid]=sub(insurancePot[_fid],_amt);
                pendingYield[_fid]=add(pendingYield[_fid],_amt);
            }else
            if(_num==9){/*Pull from the Total Reserves to Pay Out Old Tickets*/
                totalReserves[_fid]=sub(totalReserves[_fid],_amt);
                contractBalance[_fid]=add(contractBalance[_fid],_amt);
                pendingYield[_fid]=add(pendingYield[_fid],_amt);
                assert(CERC20(cTOKENaddy[_fid]).redeemUnderlying(_amt) == 0);
            }
        }else
        if(_meth==2){/*Create a new Farm*/
            if(lastUID==0){
                isUser[developer]=true;
                UID[developer]=0;
                userID.push(developer);
                isUser[marketing]=true;
                UID[marketing]=1;
                userID.push(marketing);
                lastUID=1;
                baseClock=(60 minutes);
                intermission=(6 hours);
            }
            paywith_BAL.push([false,false]);
            paywith_BON.push([false,false]);
            paywith_COM.push([false,false]);
            usersTicketQty.push([0,0]);
            closedTickets.push([0,0]);
            totalPurchases.push([0,0]);
            usersBalance.push([0,0]);
            totalReturns.push([0,0]);
            usersBonus.push([0,0]);
            totalJackpots.push([0,0]);
            totalProcesses.push([0,0]);
            usersCommissions.push([0,0]);
            totalCommissions.push([0,0]);
            if(lastFID==0){roundsTickets_0.push([0]);roundsTickets_0.push([0]);roundsTicketBal_0.push([0]);roundsTicketBal_0.push([0]);}else
            if(lastFID==1){roundsTickets_1.push([0]);roundsTickets_1.push([0]);roundsTicketBal_1.push([0]);roundsTicketBal_1.push([0]);}else
            if(lastFID==2){roundsTickets_2.push([0]);roundsTickets_2.push([0]);roundsTicketBal_2.push([0]);roundsTicketBal_2.push([0]);}
                /*UPDATE CONTRACT*/
            TOKENaddy.push(_addy);
            cTOKENaddy.push(_cTOKEN);
            decimals.push(_num);
            purchasePrice.push(_amt);
            totalGlobalTickets.push(0);
            totalRoundTickets.push([0,1]);
            globalTicket.push(0);
            globalTickets.push([0]);
            globalTicketBal.push([0]);
            tickRoundStarted.push([0,1]);
            tickRoundEnded.push([0,0]);
            timeRoundEnded.push([0,0]);
            roundsTicket.push(0);
            pendingTicket.push(0);
            currentRound.push(1);
            pendingRound.push(1);
            lastPurchase.push(0);
            lastPurchaser.push(address(0x0000000000000000000000000000000000000000));
            contractBalance.push(0);
            pendingYield.push(0);
            pendingProfit.push(0);
            totalReserves.push(0);
            poolStatus.push(0);
            farmStatus.push(1);
            bonusPot.push(0);
            insurancePot.push(0);
            alarmClock.push(baseClock);
            createDate.push(block.timestamp);
            startDelay.push(intermission);
            lastFID=add(lastFID,1);
        }
        emit Govern(msg.sender,_fid,_meth,_amt,block.timestamp);
    }
}