pragma solidity ^0.4.19;

contract MadeTest{    
    struct aprTx{
        uint startBlock;
        uint tearBlock;
    }   
    mapping (uint  => aprTx) aprTxs;

    struct disputeTx{
        uint startTx;
        uint escrow_duration;
        bool disputed;
    }   
    mapping (uint  => disputeTx) disputeTxs;
    
    struct madeTX {
        uint txId;
        address customer;
        address vendor;
        uint txVal;
        uint atdtime;
        uint escrow_duration;
        uint fee;
        uint award_cost;
        uint award_escrow_duration;
        
    }
    madeTX[] madeTXs;

    struct fundTX{
        uint funded;
        uint funders;
        uint fulfill;
    }
    mapping (uint  => fundTX) fundTXs;
    
    struct userTX {
        uint txId;
        uint txVal;
        uint participant;
    }
    mapping (address  => userTX[]) userTXs;

    address[] public users;    
    
    mapping (address => uint) balances;
    
    uint tearBalance = 0;

    function deposit()public payable {
        balances[msg.sender] = balances[msg.sender]+ msg.value;
    }

    function withDraw(uint amount)public{
        if(balances[msg.sender]>amount){
            balances[msg.sender] = balances[msg.sender]-amount;
            msg.sender.send(amount);
        } 
    }

    function getTearBalance()public constant returns(uint){
        return tearBalance;
    }    
   
    function getUserBalance(address user)public constant returns(uint){
        return balances[user];
    }    
    
    function addUsers(address user){
        uint occur = 0;
       for(uint i=0;i<users.length;i++){
            if(users[i]==user){
                occur = 1;
                break;
            }    
        }
        if(occur == 0)
        {
            users.push(user);
        }
    }

    function getFundTX(address user,uint index)public constant returns(uint){
        return userTXs[user][index].txVal;
    }
    
    function getAwardCost(uint txId)public constant returns(uint){
        return madeTXs[txId].award_cost;
    }
    
    function getUserTearAward(address fuser,uint iutx,uint award)public constant returns(uint){
        return  (balances[fuser] + userTXs[fuser][iutx].txVal + (userTXs[fuser][iutx].txVal*award));
                  
    }
    function getTearAward(address fuser,uint iutx,uint award)public constant returns(uint){
        return  (userTXs[fuser][iutx].txVal + (userTXs[fuser][iutx].txVal*award));
                  
    }
    
    function addFundTX(uint txId,uint participant)public payable{
        uint txVal = 0;
        if(fundTXs[txId].funders==0){
            if(msg.value==madeTXs[txId].txVal/2)
            {
                
            }else if(msg.value<madeTXs[txId].txVal/2){
                revert();
            }else{
                
            }    
        }
        if(madeTXs[txId].txVal== fundTXs[txId].funded) {
            msg.sender.send(msg.value);
            revert();
        }    
        
        addUsers(msg.sender);
            
        if(madeTXs[txId].txVal>=(msg.value+fundTXs[txId].funded)){
            txVal = msg.value;
            
        }    
        else
            txVal = madeTXs[txId].txVal - fundTXs[txId].funded;
        
        fundTXs[txId].funders = fundTXs[txId].funders +1;
        fundTXs[txId].funded = fundTXs[txId].funded + txVal;
        
        if(madeTXs[txId].txVal== fundTXs[txId].funded)   
            fundTXs[txId].fulfill = 0;            
            
        bool uoccur = false;
        for(uint i = 0;i<(userTXs[msg.sender].length);i++){
            if(userTXs[msg.sender][i].participant == 2 && userTXs[msg.sender][i].txId == txId){
                uoccur = true;
                userTXs[msg.sender][i].txVal = userTXs[msg.sender][i].txVal+txVal;
                break;
            }
        }
        if(uoccur == false){
            userTXs[msg.sender].push(userTX(txId,txVal,2));
        }
        
        
    }
   
    function getFundAllTx(uint txId)public constant returns(uint) {
        return (madeTXs[txId].txVal-fundTXs[txId].funded);
    }
    
    function addFullFundTX(uint txId,uint participant)public payable{
        uint txVal = 0;
        if(madeTXs[txId].txVal== fundTXs[txId].funded){
            msg.sender.send(msg.value);
            revert();
        }
            
        addUsers(msg.sender);
            
        txVal = madeTXs[txId].txVal-fundTXs[txId].funded;
        fundTXs[txId].fulfill = 0;        
        fundTXs[txId].funders = fundTXs[txId].funders +1;
        fundTXs[txId].funded = fundTXs[txId].funded + txVal;
        
        bool uoccur = false;
        for(uint i = 0;i<(userTXs[msg.sender].length);i++){
            if(userTXs[msg.sender][i].participant == 2 && userTXs[msg.sender][i].txId == txId){
                uoccur = true;
                userTXs[msg.sender][i].txVal = userTXs[msg.sender][i].txVal+txVal;
                break;
            }
        }
        if(uoccur == false){
            userTXs[msg.sender].push(userTX(txId,txVal,2));
        }
    }
    
    function getMadeTXCount() public constant returns(uint) {
        return madeTXs.length;
    }
    
    function getUserTXCount() public constant returns(uint) {
        return userTXs[msg.sender].length;
    }
    
    function disputeTX(uint txId) public payable{
        disputeTxs[txId].disputed = true;  
       // disputeTxs[txId].startTx  = block.timestamp;
    }
   
    function fulFillTX(uint txId) public payable{
        fundTXs[txId].fulfill = 1;     
  //      oraclize_query(2, "URL", "");
        // configure auto teardown
       /* scheduler.scheduleCall.value(1)(
            address(this),               // the address that should be called.
            txId,
            bytes4(sha3("testCallBack()")),  // 4-byte abi signature of callback fn
            block.number+10          // the block number to execute the call
        );*/
    }
    
    /*function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        // do something, 1 day after contract creation
            tearBalance =5; 
    }*/
    
    function testCallBack(uint txId) public{
        tearBalance = tearBalance +  txId;  
    }
    
    function autoDestruct() public payable {
        for(uint i=0;i<madeTXs.length;i++){
            uint txId = madeTXs[i].txId;
            addUsers(msg.sender);

            if(madeTXs[txId].atdtime<block.timestamp)
            if(fundTXs[txId].funded!=madeTXs[txId].txVal)
            if(fundTXs[txId].fulfill != 2){
                fundTXs[txId].fulfill = 2;        
                address vendor = madeTXs[txId].vendor;
                uint ul = users.length;
                address customer = madeTXs[txId].customer;
                balances[vendor] = balances[vendor] - tx.gasprice;
                balances[msg.sender] = balances[msg.sender] + tx.gasprice;
                for(uint iu = 0;iu<ul;iu++){
                    address fuser = users[iu];
                    uint utl= userTXs[fuser].length;
                    for(uint iutx = 0;iutx<utl;iutx++){
                        if(userTXs[fuser][iutx].participant == 2 && userTXs[fuser][iutx].txId == txId){
                            balances[fuser] = balances[fuser] + userTXs[fuser][iutx].txVal +  ((madeTXs[txId].award_cost*userTXs[fuser][iutx].txVal)/1000000000000000000);
                            break;
                        }
                    }
                }
            }    
        }
    }
    
    function autoTearDownAndDestruct() public payable {
        for(uint i=0;i<madeTXs.length;i++){
            uint txId = madeTXs[i].txId;
            addUsers(msg.sender);

            if(madeTXs[txId].atdtime<block.timestamp)
            if(fundTXs[txId].fulfill != 2)
            if(fundTXs[txId].funded==madeTXs[txId].txVal){
                fundTXs[txId].fulfill = 2;        
                address vendor = madeTXs[txId].vendor;
                balances[vendor] = balances[vendor]+madeTXs[txId].txVal;
                uint ul = users.length;
                aprTxs[txId].tearBlock = block.number;
                //uint awardallocate = ((aprTxs[txId].tearBlock - aprTxs[txId].startBlock)*1000000000000000000/10000);
                address customer = madeTXs[txId].customer;
                balances[vendor] = balances[vendor] - tx.gasprice;
                balances[msg.sender] = balances[msg.sender] + tx.gasprice;
                for(uint iu = 0;iu<ul;iu++){
                    address fuser = users[iu];
                    uint utl= userTXs[fuser].length;
                    for(uint iutx = 0;iutx<utl;iutx++){
                        if(userTXs[fuser][iutx].participant == 2 && userTXs[fuser][iutx].txId == txId){
                            if(disputeTxs[txId].disputed==false){
                              //  balances[fuser] = balances[fuser] + userTXs[fuser][iutx].txVal + (userTXs[fuser][iutx].txVal*awardallocate/(1000000000000000000));
                              balances[fuser] = balances[fuser] + userTXs[fuser][iutx].txVal +  ((madeTXs[txId].award_cost*userTXs[fuser][iutx].txVal)/1000000000000000000);
                            }else{
                              //  balances[fuser] = balances[fuser] + (userTXs[fuser][iutx].txVal*awardallocate/(1000000000000000000));
                                balances[fuser] = balances[fuser] + ((madeTXs[txId].award_cost*userTXs[fuser][iutx].txVal)/1000000000000000000);
                                balances[customer] = balances[customer]+userTXs[fuser][iutx].txVal;
                            }
                            //fuser.send(userTXs[fuser][iu].txVal);
                            break;
                        }
                    }
                }
            }else{
                fundTXs[txId].fulfill = 2;        
                vendor = madeTXs[txId].vendor;
                ul = users.length;
                customer = madeTXs[txId].customer;
                balances[vendor] = balances[vendor] - tx.gasprice;
                balances[msg.sender] = balances[msg.sender] + tx.gasprice;
                for(iu = 0;iu<ul;iu++){
                    fuser = users[iu];
                    utl= userTXs[fuser].length;
                    for(iutx = 0;iutx<utl;iutx++){
                        if(userTXs[fuser][iutx].participant == 2 && userTXs[fuser][iutx].txId == txId){
                            balances[fuser] = balances[fuser] + userTXs[fuser][iutx].txVal +  ((madeTXs[txId].award_cost*userTXs[fuser][iutx].txVal)/1000000000000000000);
                            break;
                        }
                    }
                }
            }        
        }
    }
    
    function tearDown(uint txId) public payable{
        if(fundTXs[txId].funded==madeTXs[txId].txVal)
        if(fundTXs[txId].fulfill != 2){
            fundTXs[txId].fulfill = 2;        
            address vendor = madeTXs[txId].vendor;
            balances[vendor] = balances[vendor]+madeTXs[txId].txVal;
            uint ul = users.length;
            aprTxs[txId].tearBlock = block.number;
           // uint awardallocate = madeTXs[txId].fee*(aprTxs[txId].tearBlock - aprTxs[txId].startBlock)/10000;
            uint awardallocate = madeTXs[txId].fee;
            if((block.timestamp - disputeTxs[txId].startTx)<disputeTxs[txId].escrow_duration)
                awardallocate = madeTXs[txId].fee/disputeTxs[txId].escrow_duration*(disputeTxs[txId].escrow_duration-(block.timestamp - disputeTxs[txId].startTx));
          //  uint useraward = madeTXs[txId].award-awardallocate;
            address customer = madeTXs[txId].customer;
            balances[customer] = balances[customer]+madeTXs[txId].fee-awardallocate;
            for(uint iu = 0;iu<ul;iu++){
                address fuser = users[iu];
                uint utl= userTXs[fuser].length;
                for(uint iutx = 0;iutx<utl;iutx++){
                    if(userTXs[fuser][iutx].participant == 2 && userTXs[fuser][iutx].txId == txId){
                        if(disputeTxs[txId].disputed==false){
                            balances[fuser] = balances[fuser] + userTXs[fuser][iutx].txVal + ((userTXs[fuser][iutx].txVal*awardallocate)/(1000000000000000000));
                        }else{
                            balances[fuser] = balances[fuser] + ((userTXs[fuser][iutx].txVal*awardallocate)/(1000000000000000000));
                            balances[customer] = balances[customer]+userTXs[fuser][iutx].txVal;
                        }
                        //fuser.send(userTXs[fuser][iu].txVal);
                        break;
                    }
                }
            }
        }    
    }
    
    
    function getDisputeTX(uint index) public constant returns(uint, uint,bool){
        return(disputeTxs[index].startTx,disputeTxs[index].escrow_duration,disputeTxs[index].disputed);
    }
    
    function getUserTX(address user,uint index) public constant returns(address, uint, uint, uint,uint){
        return(user, userTXs[user][index].txId,userTXs[user][index].txVal,userTXs[user][index].participant,fundTXs[userTXs[user][index].txId].fulfill);
    } 
    
    function getMadeTX(uint index) public constant returns(uint, address, address, uint, uint, uint){
        return(madeTXs[index].txId,madeTXs[index].customer,madeTXs[index].vendor,madeTXs[index].txVal,madeTXs[index].escrow_duration,madeTXs[index].fee);
    } 
  
    function getMadeTXFund(uint index) public constant returns(uint, uint){
        return(fundTXs[index].funded,fundTXs[index].funders);
    } 
    
    function getAPRTx(uint index) public constant returns(uint, uint){
        return(aprTxs[index].startBlock,aprTxs[index].tearBlock);
    }    

    function addMadeTX(address vendor,uint escrow_duration,uint fee,uint award_cost,uint award_escrow_duration) public payable {
        if(fee>balances[vendor])  {
            msg.sender.send(msg.value);
            revert();
        }    
        
        uint index = getMadeTXCount();
        aprTxs[index]  = aprTx(block.number,0);
        //uint atdtime = block.timestamp +(escrow_duration*86400 ) + (2*86400);//currentime+expiretime+challengeperiod = autoteartime
        uint atdtime = block.timestamp +(escrow_duration) + (90);
        madeTXs.push(madeTX(index,msg.sender,vendor,msg.value,atdtime,escrow_duration,fee,award_cost,award_escrow_duration));
        fundTXs[index] = fundTX(0,0,3);
        userTXs[msg.sender].push(userTX(index,msg.value,1));
        userTXs[vendor].push(userTX(index,fee,0));
        disputeTxs[index] = disputeTx(block.timestamp,escrow_duration,false);
        addUsers(msg.sender);
        addUsers(vendor);
        balances[vendor] = balances[vendor] - fee;
    }   

}