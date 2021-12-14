// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
import "./IERC20.sol";import "./CERC20.sol";import "./VRFConsumerBase.sol";
contract NoLLo is VRFConsumerBase {
    /*[ SAFEMATH ]----------------------------------------------------------------------------------------------------------------------*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c=a*b;assert(a==0 || c / a==b);return c;}/*             */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b;return c;}/*                                  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a);return a - b;}/*                                 */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;assert(c >= a);return c;}/*                   */
    /*[ CONTRACT ADDRESSES ]------------------------------------------------------------------------------------------------------------*/
    address public owner = msg.sender;                                              /*                                                  */
    address public blank = address(0x0000000000000000000000000000000000000000);     /* A blank Address                                  */
    address public developer = address(0x4f158D866CD0eb72bb642bBbD8D3c5Cc676E3551); /* Development Teams Address                        */
    address public marketing = address(0x08BFcad8b37ee488cd43fdAa87700a4c7FA2A9A3); /* Marketing Teams Address                          */
    address public governor = address(0x4f158D866CD0eb72bb642bBbD8D3c5Cc676E3551);  /* Address for future governance contract           */
    address constant LINK_address = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;     /* LINK token      - Polygon                        */
    address constant VFRC_address = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;     /* VRF Coordinator - Polygon                        */
    /*[ CHAINLINK DATA ]----------------------------------------------------------------------------------------------------------------*/
    uint256 internal LINK_fee;                                      /* LINK fee to use the VRF service = 0.0001 LINK                    */
    bytes32 internal keyHash;                                       /* For final VRF step                                               */
    /*[ USER DATA ]---------------------------------------------------------------------------------------------------------------------*/
    mapping(address => uint) public UID;                            /* Each users assigned ID number                                    */
    mapping(address => bool) public isUser;                         /* Wether a User exists                                             */
    mapping(address => address) public usersReferrer;               /* Address of Referrer                                              */
    mapping(address => uint) public referralQty;                    /* Total Referral Quantity                                          */
    address[] public userID;                                        /* [UID] = A users address in relation to their ID                  */
    uint256[][] public usersTicketNum;                              /* [PID][UID] = A Users Current Ticket Number                       */
    uint256[][] public usersDeposit;                                /* [PID][UID] = A Users Deposited Amount                            */
    uint256[][] public usersWinnings;                               /* [PID][UID] = A Users Winnings Balance                            */
    uint256[][] public totalWinnings;                               /* [PID][UID] = A Users Total Winnings Earned                       */
    uint256[][] public totalWins;                                   /* [PID][UID] = A Users Total Number of Wins                        */
    uint256[][] public usersBonuses;                                /* [PID][UID] = A Users Bonuses Balance                             */
    uint256[][] public totalBonuses;                                /* [PID][UID] = A Users Total Bonuses Earned                        */
    uint256[][] public usersCommissions;                            /* [PID][UID] = A Users Commissions Balance                         */
    uint256[][] public totalCommissions;                            /* [PID][UID] = A Users Total Commissions Earned                    */
    /*[ CONTRACT DATA ]-----------------------------------------------------------------------------------------------------------------*/
    bytes32[] public tokenName;                                     /* [PID] = TOKEN name                                               */
    address[] public TOKENaddy;                                     /* [PID] = TOKEN address                                            */
    address[] public cTOKENaddy;                                    /* [PID] = cTOKEN address                                           */
    uint256[] public decimals;                                      /* [PID] = The Decimal format                                       */
    uint256[] public purchasePrice;                                 /* [PID] = Purchase price for each Ticket                           */
    uint256[] public requiredYield;                                 /* [PID] = Required Yield amount to trigger a Draw                  */
    uint256[] public totalTickets;                                  /* [PID] = Total Amount of Tickets                                  */
    uint256[] public totalDrawings;                                 /* [PID] = Total Amount of Drawings                                 */
    uint256[] public totalDeposited;                                /* [PID] = Total Amount Deposited into the Protocol                 */
    uint256[] public totalCompounded;                               /* [PID] = Total Amount Compounding in the Protocol                 */
    uint256[] public poolStatus;                                    /* [PID] = Pool Status: Created=0,Active=1,Paused=2,Ended=3         */
    uint256 public lastUID;                                         /* Last UID created                                                 */
    uint256 public lastPID;                                         /* Last PID created                                                 */
    uint256[] public lastDID;                                       /* [PID] = Last DID created                                         */
    /*[ TICKET DATA ]-------------------------------------------------------------------------------------------------------------------*/
    bool[][] public ticketStatus;                                   /* [PID][TID] = Wether a Ticket is in Play                          */
    uint256[][] public ticketUsersID;                               /* [PID][TID] = A Ticket Owners UID                                 */
    address[][] public ticketUsersAddy;                             /* [PID][TID] = A Ticket Owners Address                             */
    /*[ DRAW DATA ]---------------------------------------------------------------------------------------------------------------------*/
    mapping(bytes32 => bool) public isReqID;                        /* Wether a ReqID exists                                            */
    mapping(bytes32 => uint256) public reqDID;                      /* A ReqID in relation to the DID its located at                    */
    mapping(bytes32 => uint256) public reqPID;                      /* A ReqID in relation to the PID its located in                    */
    bytes32[][] public drawReqId;                                   /* [PID][RID] = The RequestID for a specific Round                  */
    uint256[][] public drawTimestamp;                               /* [PID][DID] = A Drawings Timestamp                                */
    uint256[][] public drawResponse;                                /* [PID][DID] = A Drawings Response from Chainlink                  */
    uint256[][] public drawModResult;                               /* [PID][DID] = A Drawings Modulated Result from Chainlink          */
    uint256[][] public drawWinnersAmt;                               /* [PID][DID] = A Drawings Winners UID                              */
    uint256[][] public drawCallersID;                               /* [PID][DID] = A Drawings Callers UID                              */
    uint256[][] public drawWinnersID;                               /* [PID][DID] = A Drawings Winners UID                              */
    address[][] public drawWinnersAddy;                             /* [PID][DID] = A Drawings Winners Address                          */
    /*[ EVENTS ]------------------------------------------------------------------------------------------------------------------------*/
    event Deposit(address indexed user,uint256 indexed PID,uint256 tID,uint256 indexed time);/*                                        */
    event Cashout(address indexed user,uint256 indexed PID,uint256 method,uint256 amount,uint256 indexed time);/*                       */
    event Withdraw(address indexed user,uint256 indexed PID,uint256 ticket,uint256 amount,uint256 indexed time);/*                       */
    event Draw(address indexed user,uint256 indexed PID,uint256 dID,uint256 indexed time);/*                                            */
    event Results(address indexed user,uint256 indexed PID,uint256 dID,uint256 amount,uint256 indexed time);/*                          */
    event Govern(address indexed user,uint256 indexed PID,uint256 method,uint256 amount,uint256 indexed time);/*                        */
    /*[ DATA STRUCTURES ]---------------------------------------------------------------------------------------------------------------*/
    struct varData {/*                                                                                                                  */
        address ref;address addy;uint256 uID;uint256 rID;uint256 tID;uint256 pID;uint256 dID;uint256 cost;bool cont;uint256 farm;/*     */
        uint256 tick;uint256 amt;uint256 fee;uint256 req;/*                                                                             */
    }/*                                                                                                                                 */
    /*[ CONSTRUCTORS ]------------------------------------------------------------------------------------------------------------------*/
    constructor() VRFConsumerBase(VFRC_address, LINK_address) {
        LINK_fee = 0.0001*10**18;keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    }
    /*[ MODIFIERS ]-------------------------------------------------------------------------------------------------------------------*/
    modifier onlyVFRC() {require(msg.sender == VFRC_address,'NotVFRC');_;}
    /*[ BASIC FUNCTIONS ]---------------------------------------------------------------------------------------------------------------*/
    function deposit(uint256 _PID,address _link,uint256 _amt) external {varData memory dat;
        require(poolStatus[_PID]==1,"NotAct");
        require(_amt>=purchasePrice[_PID],"NotAct");dat.cost=_amt;
        require(IERC20(TOKENaddy[_PID]).balanceOf(msg.sender)>=dat.cost,"BalLow");
        require(IERC20(TOKENaddy[_PID]).allowance(msg.sender,address(this))>=dat.cost,"AllLow");
        if(isUser[msg.sender]){
            dat.tID=UID[msg.sender];
            dat.tick=usersTicketNum[_PID][dat.tID];
            if(dat.tick!=0){require(ticketStatus[_PID][dat.tick]==false,"Tiks>0");}
            dat.ref=usersReferrer[msg.sender];
        }else{
            /*CREATE USER ACCOUNT*/
            isUser[msg.sender]=true;
            lastUID=add(lastUID,1);
            dat.tID=lastUID;
            UID[msg.sender]=lastUID;
            userID.push(msg.sender);
            for(uint y=0;y<3;y++){
                usersTicketNum[y].push(0);
                usersDeposit[y].push(0);
                usersWinnings[y].push(0);
                totalWinnings[y].push(0);
                totalWins[y].push(0);
                usersBonuses[y].push(0);
                totalBonuses[y].push(0);
                usersCommissions[y].push(0);
                totalCommissions[y].push(0);
            }
            /*ADD REFERRERS LINK*/
            dat.ref=_link;
            if(dat.ref==blank){/*Having no referrer will support Marketing*/dat.ref=marketing;}else
            if(dat.ref==msg.sender){/*Referring yourself will only backfire ;p*/dat.ref=developer;}else
            if(!isUser[dat.ref]) {/*Referrer does NOT exist, Create an Account for them*/
                isUser[dat.ref]=true;
                referralQty[dat.ref]=0;
                lastUID=add(lastUID,1);
                UID[dat.ref]=lastUID;
                userID.push(dat.ref);
                for(uint y=0;y<3;y++){
                    usersTicketNum[y].push(0);
                    usersDeposit[y].push(0);
                    usersWinnings[y].push(0);
                    totalWinnings[y].push(0);
                    totalWins[y].push(0);
                    usersBonuses[y].push(0);
                    totalBonuses[y].push(0);
                    usersCommissions[y].push(0);
                    totalCommissions[y].push(0);
                }
            }else{/*Referrer DOES exist, do nothing*/}
            usersReferrer[msg.sender]=dat.ref;
            referralQty[dat.ref]=add(referralQty[dat.ref],1);
            dat.tick=0;
        }
            /*PURCHASE A TICKET*/
        if(dat.tick==0){
            ticketStatus[_PID].push(true);
            ticketUsersID[_PID].push(dat.tID);
            ticketUsersAddy[_PID].push(msg.sender);
            usersTicketNum[_PID][dat.tID]=add(totalTickets[_PID],1);
            totalTickets[_PID]=add(totalTickets[_PID],1);
        }else{ticketStatus[_PID][dat.tick]=true;}
            /*UPDATE USER*/
        usersDeposit[_PID][dat.tID]=dat.cost;
            /*UPDATE CONTRACT*/
        totalDeposited[_PID]=add(totalDeposited[_PID],dat.cost);    
            /*DEPOSIT INTO CONTRACT*/
        require(IERC20(TOKENaddy[_PID]).transferFrom(msg.sender,address(this),dat.cost),"DepFail");
            /*APPROVE & SUPPLY TO PROTOCOL*/
        IERC20(TOKENaddy[_PID]).approve(address(CERC20(cTOKENaddy[_PID])), dat.cost);
        assert(CERC20(cTOKENaddy[_PID]).mint(dat.cost)==0);
            /*EMIT EVENT*/
        emit Deposit(msg.sender,_PID,totalTickets[_PID],block.timestamp);
    }
    function withdraw(uint256 _PID) external {varData memory dat;
        if(isUser[msg.sender]!=true){dat.cont=false;}else{dat.cont=true;}
        dat.tID=UID[msg.sender];
        dat.amt=usersDeposit[_PID][dat.tID];
        dat.tick=usersTicketNum[_PID][dat.tID];
        ticketStatus[_PID][dat.tick]=false;
        dat.farm=CERC20(cTOKENaddy[_PID]).balanceOfUnderlying(address(this));
        if((dat.amt<=0)||(dat.amt>dat.farm)){dat.cont=false;}
        require(dat.cont==true,"ContErr");
            /*UPDATE USER*/
        usersDeposit[_PID][dat.tID]=0;
            /*UPDATE CONTRACT*/
        totalDeposited[_PID]=sub(totalDeposited[_PID],dat.amt); 
            /*WITHDRAW FROM PROTOCOL*/
        assert(CERC20(cTOKENaddy[_PID]).redeemUnderlying(dat.amt) == 0);
            /*WITHDRAW FROM CONTRACT*/
        require(IERC20(TOKENaddy[_PID]).transfer(msg.sender,dat.amt), "TxnFai");
            /*EMIT EVENT*/
        emit Withdraw(msg.sender,_PID,dat.tick,dat.amt,block.timestamp);
    }
    function cashout(uint256 _PID,uint256 _meth) external {varData memory dat;
        if(isUser[msg.sender]!=true){dat.cont=false;}else{dat.cont=true;}
        dat.tID=UID[msg.sender];
        if(_meth==1){/*CASHOUT WINNINGS*/ dat.amt=usersWinnings[_PID][dat.tID];usersWinnings[_PID][dat.tID]=0;}else
        if(_meth==2){/*CASHOUT BONUSES*/ dat.amt=usersBonuses[_PID][dat.tID];usersBonuses[_PID][dat.tID]=0;}else
        if(_meth==3){/*CASHOUT COMMISSIONS*/ dat.amt=usersCommissions[_PID][dat.tID];usersCommissions[_PID][dat.tID]=0;}else
        if(_meth==4){/*CASHOUT ALL 3*/
            dat.amt=usersWinnings[_PID][dat.tID];usersWinnings[_PID][dat.tID]=0;
            dat.amt=add(dat.amt,usersBonuses[_PID][dat.tID]);usersBonuses[_PID][dat.tID]=0;
            dat.amt=add(dat.amt,usersCommissions[_PID][dat.tID]);usersCommissions[_PID][dat.tID]=0;
        }
        dat.farm=CERC20(cTOKENaddy[_PID]).balanceOfUnderlying(address(this));
        if((dat.amt<=0)||(dat.amt>dat.farm)){dat.cont=false;}
        require(dat.cont==true,"ContErr");
            /*UPDATE CONTRACT*/
        totalDeposited[_PID]=sub(totalDeposited[_PID],dat.amt); 
            /*WITHDRAW FROM PROTOCOL*/
        assert(CERC20(cTOKENaddy[_PID]).redeemUnderlying(dat.amt) == 0);
            /*WITHDRAW FROM CONTRACT*/
        require(IERC20(TOKENaddy[_PID]).transfer(msg.sender,dat.amt), "TxnFai");
            /*EMIT EVENT*/
        emit Cashout(msg.sender,_PID,_meth,dat.amt,block.timestamp);
    }
    function draw(uint256 _PID, uint256 _seed) external returns (bool) {varData memory dat;
        if(isUser[msg.sender]!=true){dat.cont=false;}else{dat.cont=true;}
        dat.tID=UID[msg.sender];
        dat.amt=CERC20(cTOKENaddy[_PID]).balanceOfUnderlying(address(this));
        dat.farm=add(totalDeposited[_PID],totalCompounded[_PID]);
        if(dat.amt<=dat.farm){dat.cont=false;}
        dat.amt=sub(dat.amt,dat.farm);
        dat.req=requiredYield[_PID];
        if(dat.amt<dat.req){dat.cont=false;}
        dat.amt=dat.req;
        require(dat.cont==true,"ContErr");
            /*UPDATE DRAWING DATA*/
        drawTimestamp[_PID].push(block.timestamp);
        drawResponse[_PID].push(0);
        drawModResult[_PID].push(0);
        drawCallersID[_PID].push(dat.tID);
        drawWinnersAmt[_PID].push(0);
        drawWinnersID[_PID].push(0);
        drawWinnersAddy[_PID].push(blank);
        dat.dID=lastDID[_PID];
        lastDID[_PID]=add(lastDID[_PID],1);
        bytes32 requestId=getRandomNumber(_seed);
        isReqID[requestId]=true;
        reqDID[requestId]=dat.dID;
        reqPID[requestId]=_PID;
        drawReqId[_PID].push(requestId);
            /*PULL AMOUNT FROM FARM*/
        totalDeposited[_PID]=add(totalDeposited[_PID],dat.amt);
            /*EMIT EVENT*/
        emit Draw(msg.sender,_PID,dat.dID,block.timestamp);
        return true;
    }
    function getRandomNumber(uint256 _seed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this))>LINK_fee,"NoLINK");
        return requestRandomness(keyHash,LINK_fee,_seed);
    }
    function fulfillRandomness (bytes32 _reqId, uint256 randomness) internal override {varData memory dat;
        uint256 _rand = randomness;
        if(isReqID[_reqId]){
            dat.dID=reqDID[_reqId];
            dat.pID=reqPID[_reqId];
            drawResponse[dat.pID][dat.dID]=_rand;
            dat.tID=drawCallersID[dat.pID][dat.dID];
                /*MODULATE THE NUMBER WITHIN OUR RANGE*/
            uint256 modd=_rand%totalTickets[dat.pID];
            if(modd<=1){modd=2;}modd=sub(modd,1);
            drawModResult[dat.pID][dat.dID]=modd;
            /*91.00% => Winners Take
               0.91% => Winners Referrer
               6.08% => Compounded
               1.00% => Callers Take
               0.01% => Callers Referrers Take
               1.00% => Developers Take*/
                /*CHECK TICKET STATUS*/
            dat.uID=ticketUsersID[dat.pID][modd];
            uint256 jackpot = requiredYield[dat.pID];
            dat.fee = div(jackpot,10000);
            dat.amt=mul(dat.fee,9100);
            
            if(ticketStatus[dat.pID][modd]==false){
                    /*Callers Referrer*/
                dat.addy=userID[dat.tID];address Raddy=usersReferrer[dat.addy];dat.rID=UID[Raddy];
                    /*Ticket is Inactive - Reward Caller + Callers Referrer, but put back whats left for next drawing*/
                usersBonuses[dat.pID][dat.tID]=add(usersBonuses[dat.pID][dat.tID],mul(dat.fee,100));
                    totalBonuses[dat.pID][dat.tID]=add(totalBonuses[dat.pID][dat.tID],mul(dat.fee,100));
                usersCommissions[dat.pID][dat.rID]=add(usersCommissions[dat.pID][dat.rID],dat.fee);
                    totalCommissions[dat.pID][dat.rID]=add(totalCommissions[dat.pID][dat.rID],dat.fee);
                totalDeposited[dat.pID]=sub(totalDeposited[dat.pID],sub(jackpot,mul(dat.fee,101)));dat.amt=0;
            }else{
                    /*Winners Referrer*/
                dat.addy=userID[dat.uID];address Raddy=usersReferrer[dat.addy];dat.rID=UID[Raddy];
                    /*Ticket is Active - Reward all involved, dont put back any*/
                usersBonuses[dat.pID][dat.tID]=add(usersBonuses[dat.pID][dat.tID],mul(dat.fee,109));
                    totalBonuses[dat.pID][dat.tID]=add(totalBonuses[dat.pID][dat.tID],mul(dat.fee,109));
                usersWinnings[dat.pID][dat.uID]=add(usersWinnings[dat.pID][dat.uID],dat.amt);
                    totalWinnings[dat.pID][dat.uID]=add(totalWinnings[dat.pID][dat.uID],dat.amt);
                usersCommissions[dat.pID][dat.rID]=add(usersCommissions[dat.pID][dat.rID],mul(dat.fee,91));
                    totalCommissions[dat.pID][dat.rID]=add(totalCommissions[dat.pID][dat.rID],mul(dat.fee,91));
                usersCommissions[dat.pID][0]=add(usersCommissions[dat.pID][0],mul(dat.fee,100));
                    totalCommissions[dat.pID][0]=add(totalCommissions[dat.pID][0],mul(dat.fee,100));
                totalCompounded[dat.pID]=add(totalCompounded[dat.pID],mul(dat.fee,608));
                totalDeposited[dat.pID]=sub(totalDeposited[dat.pID],mul(dat.fee,608));
                totalWins[dat.pID][dat.uID]=add(totalWins[dat.pID][dat.uID],1);
                    /*Callers Referrer*/
                dat.addy=userID[dat.tID];Raddy=usersReferrer[dat.addy];dat.rID=UID[Raddy];
                usersCommissions[dat.pID][dat.rID]=add(usersCommissions[dat.pID][dat.rID],dat.fee);
                    totalCommissions[dat.pID][dat.rID]=add(totalCommissions[dat.pID][dat.rID],dat.fee);
            }
            drawWinnersAmt[dat.pID][dat.dID]=dat.amt;
            drawWinnersID[dat.pID][dat.dID]=dat.uID;
            drawWinnersAddy[dat.pID][dat.dID]=dat.addy;
          emit Results(dat.addy,dat.pID,dat.dID,dat.amt,block.timestamp);
        }
    }
    function govern(uint256 _PID,uint256 _meth,uint256 _amt,uint256 _num,address _addy,address _cTOKEN,bytes32 _name) external {
        require(msg.sender==governor,"NotGov");/*NOTE: A future governance contract will access these functions*/
        if(_meth==1){/*Change the Governors Address*/governor=_addy;}else
        if(_meth==2){/*Change the Pools Status*/poolStatus[_PID]=_amt;}else
        if(_meth==3){/*Change the Required Yield*/requiredYield[_PID]=_amt;}else
        if(_meth==4){/*Release Compounded Yield for Winning*/totalCompounded[_PID]=sub(totalCompounded[_PID],_amt);}else
        if(_meth==5){/*Withdraw LINK from contract*/
            require(LINK.balanceOf(address(this))>=_amt,'BalLow');
            require(LINK.transfer(msg.sender, _amt),'SendErr');
        }else
        if(_meth==6){/*Create a new Farm*/
            if(lastUID==0){
                isUser[developer]=true;
                UID[developer]=0;
                userID.push(developer);
                isUser[marketing]=true;
                UID[marketing]=1;
                userID.push(marketing);
                lastUID=1;
            }
                /*UPDATE DEVELOPER + MARKETING*/
            usersTicketNum.push([0,0]);
            usersDeposit.push([0,0]);
            usersWinnings.push([0,0]);
            totalWinnings.push([0,0]);
            totalWins.push([0,0]);
            usersBonuses.push([0,0]);
            totalBonuses.push([0,0]);
            usersCommissions.push([0,0]);
            totalCommissions.push([0,0]);
                /*UPDATE CONTRACT*/
            tokenName.push(_name);
            TOKENaddy.push(_addy);
            cTOKENaddy.push(_cTOKEN);
            decimals.push(_num);
            purchasePrice.push(_amt);
            requiredYield.push(mul(_amt,110));
            totalTickets.push(0);
            totalDrawings.push(0);
            totalDeposited.push(0);
            totalCompounded.push(0);
            poolStatus.push(1);
            lastPID=add(lastPID,1);
                /*UPDATE TICKET DATA*/
            ticketStatus.push([false]);
            ticketUsersID.push([0]);
            ticketUsersAddy.push([blank]);
                /*UPDATE DRAW DATA*/
            drawReqId.push([_name]);
            drawTimestamp.push([0]);
            drawResponse.push([0]);
            drawModResult.push([0]);
            drawCallersID.push([0]);
            drawWinnersAmt.push([0]);
            drawWinnersID.push([0]);
            drawWinnersAddy.push([blank]);
            lastDID.push(1);
        }
        emit Govern(msg.sender,_PID,_meth,_amt,block.timestamp);
    }
}