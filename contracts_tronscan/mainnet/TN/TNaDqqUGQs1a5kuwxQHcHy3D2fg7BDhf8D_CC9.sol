//SourceUnit: token.sol

pragma solidity >=0.4.23 <0.6.0;

contract CC9{ // 
    
    uint public entryAmount;
    uint public level3Prices;
    uint public payout3Price;
    uint public compTransfer;
    uint public votingpoolAmount = 0;
    
   
    address public ownerAddress=address(0x4154E77A4748EC282DED4CE76AB9AF7B72D0BAB9F1);  // THi94XDmFacxfj1n4kNUsfCJqWEo95n52E
    address public TokenContract=address(0x41F221B4A6301674640156EF66FE487D5B1BB85B9B);  // TY3UuPi4FWXJeHezmXe53ompXSB8m7s3U9  // koel coin
    ///////////////////////////////////////
    address public SlotContract=address(0x41386E87C8B9C7D1BDD412D271E99CCBDCC845BC7E);   // TF7bFb6wEu5Sw2wNgYGkyJ5pzwVQeiLTfM
    address public CompanyMatrixContract=address(0x41C19457570F3FA254D983D16F424D62989228727F);  // TTcm81PqbP4zZcGpqts27iHJJK7vXPA5kG
    address public TwoLevelMatrix=address(0x4156668B14D865FB5BFBE0CB1A88312F852CFD4A1C);       // THr3xPWUugBV5ZX8QAaceGPa8TY6EeQx9E
    ///////////////////////////////////////
    
    Callee1 c = Callee1(TokenContract); // Token Contract
    Callee2 d = Callee2(SlotContract); // Slot Contract
    Callee3 e = Callee3(CompanyMatrixContract); // companyMatrix
    Callee4 f = Callee4(TwoLevelMatrix);
    uint8 public rentryID=0;
    uint8 public currentUserId = 0;
    mapping(address => uint) public TotalEarning;
    
    
    struct UserStruct {
        bool isExist;
        address referrer;
        uint balances;
        uint xbalances;
        bytes32 username;
        /////////////////
        mapping(uint8 => bool) activeX39Levels;
        mapping(uint8 => X39) x39Matrix;
        ////////////////
    }
    struct X39 {
        address currentReferrer;
        address[] directReferrerals;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
        uint8 reEntryCount;
        bool reEntry;
    }
    mapping(address => address) public currentReferrerfor100;
    mapping (address => UserStruct) public users;
    ////////////////////////////
    ////////////////////////////
    mapping(bytes32 => bool) public nameExist;
    mapping(bytes32 => address) public nameToAddress;
    /////////////////////////////
    //////////////////////////////
    
    
    function setEntryPrice(uint8 entryprice ,uint8 distribution,uint8 payoutOutPrice , uint8 companytransfer) public{
            require(msg.sender==ownerAddress,"Must Be Owner !");
            entryAmount=entryprice;
            level3Prices=distribution;
            payout3Price=payoutOutPrice; // RENTRY PRICE
            compTransfer=companytransfer;
    }
    
    constructor() public{
        /////////////////
        entryAmount=1875;
        level3Prices=375;
        payout3Price=1875; // RENTRY PRICE
        compTransfer=500;
        /////////////////
        
        //////////////////
        UserStruct memory user=UserStruct({
            isExist:true,
            referrer:address(0),
            balances:0,
            xbalances:0,
            username:'JaiMataDi'
        });
        ////////////////////////
        nameExist['JaiMataDi']=true;
        nameToAddress['JaiMataDi']=ownerAddress;
        /////////////////////////
        
        users[ownerAddress] = user;
        
        users[ownerAddress].activeX39Levels[1] = true;
        users[ownerAddress].x39Matrix[1].reEntryCount=1;
        /////////100 matrix
        //users[ownerAddress].activeX100Levels[1] = true;
        
     }
     ////////////////////////////////////////////////////////////////////////////////////////////////////
    
     /////////////////////////////////////////////////vote***********************************************
    
    function voteResult() public{
        require(msg.sender==ownerAddress);
        //c.transfer(SlotContract,votingpoolAmount*1000000000000000000);
        votingpoolAmount=0;
        //d.selectWinners(msg.sender,votingpoolAmount);
    }
    
///////////////////////////////////////////////////
    
    
    function enter(uint256 amount,address referrerAddress , bytes32 uname) public{
        require(!nameExist[uname],"UserName Exist");
        require(amount==entryAmount,"Invalid Amount");
        require(!users[msg.sender].isExist,"User Exists");
        require(users[referrerAddress].isExist,"Referrer Doesnot Exists");
        c.transferFrom(msg.sender,address(this),amount*100000000);
        d.saveUsers(msg.sender,referrerAddress); // Vote Contract
        f.SaveUsers2LevelMAtrix(msg.sender,referrerAddress);//Level2Matrix
        //e.updateCompanyMatrix(msg.sender,referrerAddress);
        
        UserStruct memory user = UserStruct({
            isExist:true,
            referrer: referrerAddress,
            balances:0,           
            xbalances:0,
            username:uname
        });
        users[msg.sender]=user;
        //username[name]=true;
        //////////////////////////
        nameExist[uname]=true;
        nameToAddress[uname]=msg.sender;
        /////////////////////////
        /////////////////////////////////////////////
        users[msg.sender].activeX39Levels[1] = true;
        users[msg.sender].x39Matrix[1].reEntryCount=1;
        updateX39Referrer(msg.sender,referrerAddress ,1);
        
        //////////save directReferrer
        users[referrerAddress].x39Matrix[1].directReferrerals.push(msg.sender);
        currentReferrerfor100[msg.sender]=referrerAddress;
        
        votingpoolAmount = votingpoolAmount + entryAmount*8/100;
        /////////////////////////////////////////////
        //users[msg.sender].x39Matrix[level].currentReferrer = referrerAddress;
        users[msg.sender].x39Matrix[1].currentReferrer = referrerAddress;
    }
   
    function updateX39Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX39Levels[level], "Referrer not active");
        ///////////////////////////// companyMatrix
        c.transfer(CompanyMatrixContract,compTransfer*100000000);
        e.updateCompanyMatrix(userAddress,referrerAddress);
        
        /////////////////////////////////////////////
         
         if (users[referrerAddress].x39Matrix[level].firstLevelReferrals.length < 3){
            users[referrerAddress].x39Matrix[level].firstLevelReferrals.push(userAddress);
            //Send Balance
            users[referrerAddress].balances=users[referrerAddress].balances+level3Prices;
            //////reentry
            if(users[referrerAddress].balances>=payout3Price){
                users[referrerAddress].balances=users[referrerAddress].balances-payout3Price;
                /////////////
                TotalEarning[referrerAddress]=TotalEarning[referrerAddress]+payout3Price;
                //////////////
                if(users[referrerAddress].x39Matrix[1].reEntry)
                    {
                    //reentryx39(userAddress,referrerAddress,level);
                    ///////////////////////////   
                    e.companyMatrix(referrerAddress,referrerAddress);
                    c.transfer(CompanyMatrixContract,compTransfer*100000000);
                    users[referrerAddress].x39Matrix[1].reEntry=false;
                    users[referrerAddress].x39Matrix[1].reEntryCount=users[referrerAddress].x39Matrix[1].reEntryCount+1;
                    updateX39Referrer(referrerAddress,referrerAddress,level);
                    ////////////////////////////
                    }
                else{
                    users[referrerAddress].x39Matrix[1].reEntry=true;
                    c.transfer(referrerAddress,payout3Price*100000000);
                    }
                
            }
            

            if (referrerAddress == ownerAddress) {
                return;
            }
            //level 2
            address ref = users[referrerAddress].x39Matrix[level].currentReferrer;            
            users[ref].x39Matrix[level].secondLevelReferrals.push(userAddress); 
                //Send Balance
                users[ref].balances=users[ref].balances+level3Prices;
            ///////reentry
            if(users[ref].balances>=payout3Price){
                users[ref].balances=users[ref].balances-payout3Price;
                ///////////
                TotalEarning[ref]=TotalEarning[ref]+payout3Price;
                ///////////
                if(users[ref].x39Matrix[1].reEntry)
                    {
                    //reentryx39(userAddress,ref,level);
                     ///////////////////////////////;     
                    users[ref].x39Matrix[1].reEntry=false;
                    users[ref].x39Matrix[1].reEntryCount=users[ref].x39Matrix[1].reEntryCount+1;
                    e.companyMatrix(ref,ref);
                    c.transfer(CompanyMatrixContract,compTransfer*100000000);
                    updateX39Referrer(ref,ref,level);
                    ///////////////////////////////
                    }
                else{
                    users[ref].x39Matrix[1].reEntry=true;
                    c.transfer(ref,payout3Price*100000000);
                    }
            }
            ///////////////////
            if (ref == ownerAddress) {
                return;
            }
            //level 3
            address refref = users[ref].x39Matrix[level].currentReferrer;
            users[refref].x39Matrix[level].thirdLevelReferrals.push(userAddress);
                //Send Balance
                users[refref].balances=users[refref].balances+level3Prices;
            ///////////reentry
            if(users[refref].balances>=payout3Price){
                users[refref].balances=users[refref].balances-payout3Price;
                ////////
                 TotalEarning[refref]=TotalEarning[refref]+payout3Price;
                ///////
                 if(users[refref].x39Matrix[1].reEntry)
                    {
                    //reentryx39(userAddress,refref,level);
                    ////////////////////////////////////
                    users[refref].x39Matrix[1].reEntryCount=users[refref].x39Matrix[1].reEntryCount+1;
                    users[refref].x39Matrix[1].reEntry=false;
                    e.companyMatrix(refref,refref);
                    c.transfer(CompanyMatrixContract,compTransfer*100000000);
                    updateX39Referrer(refref,refref,level);
                    ///////////////////////////////////
                    }
                else{
                    users[refref].x39Matrix[1].reEntry=true;
                    c.transfer(refref,payout3Price*100000000);
                }
            }
            if(ref == ownerAddress){
                return;
            }
            
            
            else{
                
            }
            ///////////////////
         }
         
         else if(users[referrerAddress].x39Matrix[level].secondLevelReferrals.length < 9){
            users[referrerAddress].x39Matrix[level].secondLevelReferrals.push(userAddress);
            //users[userAddress].x39Matrix[level].currentReferrer = referrerAddress;
                //Send Balance
                users[referrerAddress].balances=users[referrerAddress].balances+level3Prices;
            ///////reentry
            if(users[referrerAddress].balances>=payout3Price){
                users[referrerAddress].balances=users[referrerAddress].balances-payout3Price;
                //////////
                    TotalEarning[referrerAddress]=TotalEarning[referrerAddress]+payout3Price;
                //////////
                if(users[referrerAddress].x39Matrix[1].reEntry)
                    {
                    //reentryx39(userAddress,referrerAddress,level);
                    ///////////////////////////////////////////////     
                    users[referrerAddress].x39Matrix[1].reEntryCount=users[referrerAddress].x39Matrix[1].reEntryCount+1;
                    users[referrerAddress].x39Matrix[1].reEntry=false;   
                    e.companyMatrix(referrerAddress,referrerAddress);
                    c.transfer(CompanyMatrixContract,compTransfer*100000000);
                    updateX39Referrer(referrerAddress,referrerAddress,level);
                    ///////////////////////////////////////////////
                    }
                else{
                    users[referrerAddress].x39Matrix[1].reEntry=true;
                    c.transfer(referrerAddress,payout3Price*100000000);
                }
            }
            else{
               
            }
            ///////////////////
            if (referrerAddress == ownerAddress) {
                return;
            }
            
            //////////////////
            
            address ref2 = users[referrerAddress].x39Matrix[level].currentReferrer;
            users[ref2].x39Matrix[level].thirdLevelReferrals.push(userAddress); 
            //Send Balance
                users[ref2].balances=users[ref2].balances+level3Prices;
            //reEntry
            if(users[ref2].balances>=payout3Price){
                users[ref2].balances=users[ref2].balances-payout3Price;
                ///////////////////
                TotalEarning[ref2]=TotalEarning[ref2]+payout3Price;
                ///////////////////
                if(users[ref2].x39Matrix[1].reEntry)
                    {
                    //reentryx39(userAddress,ref2,level);
                    //////////////////////////////////////
                    users[ref2].x39Matrix[1].reEntryCount=users[ref2].x39Matrix[1].reEntryCount+1;
                    users[ref2].x39Matrix[1].reEntry=false;
                    e.companyMatrix(ref2,ref2);
                    c.transfer(CompanyMatrixContract,compTransfer*100000000);
                    updateX39Referrer(ref2,ref2,level);
                    /////////////////////////////////////////
                    }
                else{
                    users[ref2].x39Matrix[1].reEntry=true;
                    c.transfer(ref2,payout3Price*100000000);
                }
            }
            else{
                
            }
            ///////////////////
            
         }
         
         else if(users[referrerAddress].x39Matrix[level].thirdLevelReferrals.length < 27){
             //users[userAddress].x39Matrix[level].currentReferrer = referrerAddress;
            users[referrerAddress].x39Matrix[level].thirdLevelReferrals.push(userAddress);
            
            //Send Balance
                users[referrerAddress].balances=users[referrerAddress].balances+level3Prices;
            //reEntry
             if(users[referrerAddress].balances>=payout3Price){
                 users[referrerAddress].balances=users[referrerAddress].balances-payout3Price;
                 /////////
                    TotalEarning[referrerAddress]=TotalEarning[referrerAddress]+payout3Price;
                 ////////
                 if(users[referrerAddress].x39Matrix[1].reEntry)
                    {
                    //reentryx39(userAddress,referrerAddress,level);
                    ///////////////////////////////////////////////
                    users[referrerAddress].x39Matrix[1].reEntryCount=users[referrerAddress].x39Matrix[1].reEntryCount+1;
                    users[referrerAddress].x39Matrix[1].reEntry=false;
                    e.companyMatrix(referrerAddress,referrerAddress);
                    c.transfer(CompanyMatrixContract,compTransfer*100000000);
                    updateX39Referrer(referrerAddress,referrerAddress,level);
                    //////////////////////////////////////////////
                    }
                else{
                    users[referrerAddress].x39Matrix[1].reEntry=true;
                    c.transfer(referrerAddress,payout3Price*100000000);
                }
            }
            else{
               
            }
            ///////////////////
         }
         else{
             //updateX39Referrer(userAddress,referrerAddress, users[referrerAddress].x39Matrix[1].reEntryCount);
            
             for(uint8 i=2;i<=users[referrerAddress].x39Matrix[1].reEntryCount;i++){
             if(users[referrerAddress].activeX39Levels[i]&&((users[referrerAddress].x39Matrix[i].firstLevelReferrals.length+users[referrerAddress].x39Matrix[i].secondLevelReferrals.length+users[referrerAddress].x39Matrix[i].thirdLevelReferrals.length)<39)){
                 return updateX39Referrer(userAddress,referrerAddress, i);
                }
             }
            ////////////////////////////////////////////////////
            users[referrerAddress].x39Matrix[1].reEntryCount= users[referrerAddress].x39Matrix[1].reEntryCount+1;
            uint8 levelnew = users[referrerAddress].x39Matrix[1].reEntryCount;
            users[referrerAddress].activeX39Levels[levelnew] = true;
            
            e.companyMatrix(referrerAddress,referrerAddress);
            c.transfer(CompanyMatrixContract,compTransfer*100000000);
            
            return updateX39Referrer(userAddress,referrerAddress,levelnew);
            /////////////////////////////////////////////////////
         }
         
     }
     
     /*
     ///////////////////////////////////////////////////////////////
     //////////////////////////////////////////////////////////////
     
   */
   
    function Drain(uint amount) public{
        require(msg.sender==ownerAddress);
        c.transfer(ownerAddress,amount*100000000);
    }
    function resetpool() public{
        require(msg.sender==ownerAddress);
        votingpoolAmount=0;
        
    }
    function usersX39Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address[] memory,uint8,bool) {
        return (users[userAddress].x39Matrix[level].currentReferrer,
                users[userAddress].x39Matrix[level].firstLevelReferrals,
                users[userAddress].x39Matrix[level].secondLevelReferrals,
                users[userAddress].x39Matrix[level].thirdLevelReferrals,
                users[userAddress].x39Matrix[level].reEntryCount,
                users[userAddress].x39Matrix[level].reEntry);
    }
    
   
    /*
    function users2level(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,uint8,bool) {
        return (users[userAddress].x100Matrix[level].currentReferrer,
                users[userAddress].x100Matrix[level].firstLevelReferrals,
                users[userAddress].x100Matrix[level].secondLevelReferrals,
                users[userAddress].x100Matrix[level].reEntryCount,
                users[userAddress].x100Matrix[level].reEntry);
    }
    */
    function checkName(bytes32 usrname) public view returns(bool){
        return (nameExist[usrname]);
    }
    
    function nametoadd(bytes32 usname) public view returns(address){
        return (nameToAddress[usname]);
    }
  
     
}
contract Callee4{
    function SaveUsers2LevelMAtrix(address useraddress , address referrerAddress)public;
}
contract Callee3{
    function updateCompanyMatrix(address useraddress,address referrerAddress) public;
    function companyMatrix(address userAddress, address referrerAddress) public;
}

contract Callee2{
    function saveUsers(address useraddress,address referrerAddress) public;
    //function selectWinners(address sender ,uint VotePoolAmount) public;
}

contract Callee1 {
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    function transfer(address to, uint value) public;
}