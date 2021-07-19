//SourceUnit: Tronfutures.sol

//TRON FUTURES
//Earn 3% - 5% per day up to 300%
//Join telegram group - t.me/tronfuturexx

/** DEFI PLATFORM WILL BE LAUNCHED MARCH 1st WEEK, 
FUTURES TOKEN (FTX) WILL BE ON PRE-SALE ON THE FIRST WEEK OF MARCH

PRESALE TOKENS is exclusive only for the investors of TRON FUTURES
*/




pragma solidity ^0.5.9;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
contract TronFutures is Ownable {
    struct User{
        uint256[] amount;
        uint256[] date;
        uint256[] plan;
        uint256[] paidout;
        uint256[3] affiliateBonus;
        uint256 referralPaidout;
        uint256 idUser;
        uint256 idAffiliate;
    }
    struct AddressUser{
        address userAddress; 
        bool isExist;
    }
    uint256 countUser = 100;
    uint256[] plans = [3,4,5]; //%
    uint256[] plansDay = [100,75,60];//days 
    uint256[] levelsAffiliate = [5,3,2];
    
    uint256 totalInvested = 0;
    
    address payable public owner;
    uint256 private ownerBalance = 0;
    
    address payable public developer;
    uint256 private developerBalance = 0;
    
    address payable public marketing;
    uint256 private marketingBalance = 0;
    

    uint256 private def = 0;
    
    uint private releaseTime = 1606998600;
    
    mapping(address => User) users;
    mapping(uint256 => AddressUser) usersId;
    address[] wallets;
    
    constructor() public{
        owner = msg.sender;
        developer = msg.sender;
        marketing = msg.sender;
        ownerBalance = 0;
        developerBalance = 0;
        marketingBalance = 0;
     }
    function investPlan(uint256 idRefer,uint8 idPlan) public payable returns (string memory) {
        require(now >= releaseTime, "Not Launched Yet!");
        require(idPlan >= 0 && idPlan <=2);
        require(msg.value >= 50);
        
        if(idRefer <= 0){
            idRefer = def;
        }
        
        if(!usersId[idRefer].isExist || usersId[idRefer].userAddress == msg.sender){
            idRefer = def;
        }
        
        
        if(users[msg.sender].idUser<=0){
            countUser=countUser+2;
            users[msg.sender].idUser = countUser;
            usersId[countUser].userAddress=msg.sender;
            usersId[countUser].isExist=true;
            users[msg.sender].referralPaidout=0;
        }
        if(users[msg.sender].idAffiliate<=0){
            if(idRefer!=0){
                users[msg.sender].idAffiliate = idRefer;
            }
        }
        users[msg.sender].amount.push(msg.value);
        users[msg.sender].date.push(now);
        users[msg.sender].plan.push(idPlan);
        users[msg.sender].paidout.push(0);
        
        if(users[msg.sender].idAffiliate>0){
            payAffiliate(msg.value,users[msg.sender].idAffiliate);
        }
        
        totalInvested+=msg.value;
        
        owner.transfer((msg.value * 1) / 100);
        developer.transfer((msg.value * 5) / 100);
        marketing.transfer((msg.value * 5) / 100);
        
        return "ok";
    }
    function getInvestList() public view returns(uint256[] memory,uint256[] memory, uint256[] memory,uint256[] memory,uint256[] memory){
        require(users[msg.sender].amount.length>0,"Not invested plan");
        uint256[] memory withdrawable=new uint256[](users[msg.sender].amount.length);
        for(uint i=0;i<users[msg.sender].amount.length;i++){
            uint256 porce = plansDay[users[msg.sender].plan[i]] * 86400; 
            uint256 dateInit = users[msg.sender].date[i];
            if( dateInit+ porce > now){
                uint256 diference = now - users[msg.sender].date[i];
                uint256 profits = ((diference * ((plans[users[msg.sender].plan[i]]*100000000) / 86400)) * users[msg.sender].amount[i])/(100*100000000);
                withdrawable[i]=(profits*1) - users[msg.sender].paidout[i];
            }else{
                withdrawable[i]=((users[msg.sender].amount[i]/100)*(plans[users[msg.sender].plan[i]]*plansDay[users[msg.sender].plan[i]])) - users[msg.sender].paidout[i];
            }
           
        }
        return (users[msg.sender].amount, users[msg.sender].date, users[msg.sender].plan, withdrawable, users[msg.sender].paidout);
    }
    function withdraw() public{
        require(users[msg.sender].amount.length > 0);
        
        uint256 totalRewards=0;
        uint256[] memory withdrawable=new uint256[](users[msg.sender].amount.length);
        for(uint i=0;i<users[msg.sender].amount.length;i++){
            uint256 porce = plansDay[users[msg.sender].plan[i]] * 86400; 
            uint256 dateInit = users[msg.sender].date[i];
            if( dateInit+ porce > now){
                uint256 diference = now - users[msg.sender].date[i];
                uint256 profits = ((diference * ((plans[users[msg.sender].plan[i]]*100000000) / 86400)) * users[msg.sender].amount[i])/(100*100000000);
                withdrawable[i]=(profits*1) - users[msg.sender].paidout[i];
            }else{
                withdrawable[i]=((users[msg.sender].amount[i]/100)*(plans[users[msg.sender].plan[i]]*plansDay[users[msg.sender].plan[i]])) - users[msg.sender].paidout[i];
            }
            users[msg.sender].paidout[i]=users[msg.sender].paidout[i]+withdrawable[i];
            
            
            totalRewards += withdrawable[i];
           
        }
        if(totalRewards>0){
            payout(msg.sender,totalRewards);
        }
    }
    function payout(address receiver, uint256 amount) internal {
        if (amount > 0 && receiver != address(0)) {
          uint contractBalance = address(this).balance;
            require(contractBalance > amount); 
            msg.sender.transfer(amount);
        }
    }
    function payAffiliate(uint256 amount, uint256 affiliate) internal {
        for(uint i=0;i<levelsAffiliate.length;i++){
            uint256 levelAmount = (amount * levelsAffiliate[i])/100;
            users[usersId[affiliate].userAddress].affiliateBonus[i] += levelAmount;
            affiliate = users[usersId[affiliate].userAddress].idAffiliate;
        }
        
    }
    function referCode() public view returns(uint256){
        require(users[msg.sender].idUser>0);
        return users[msg.sender].idUser;
    }
    function getReferralRewards() public view returns(uint256[3] memory, uint256){
        require(users[msg.sender].idUser>0);
        uint256[3] memory affiliateBonus = users[msg.sender].affiliateBonus;
        
        if(msg.sender==owner){
            affiliateBonus[0] += ownerBalance;
        }
        if(msg.sender==developer){
            affiliateBonus[0] += developerBalance;
        }
        if(msg.sender==marketing){
            affiliateBonus[0] += marketingBalance;
        }
        return (affiliateBonus, users[msg.sender].referralPaidout);
    }
    function withdrawReferralRewards() public {
        require(users[msg.sender].idUser>0);
        require(address(this).balance>5);
        uint256 totalRewards=0;
        for(uint i=0;i<levelsAffiliate.length;i++){
            totalRewards += users[msg.sender].affiliateBonus[i];
            users[msg.sender].affiliateBonus[i]=0;
        }
        
        if(msg.sender==owner){
            totalRewards+=ownerBalance;
            ownerBalance = 0;
        }
        if(msg.sender==developer){
            totalRewards += developerBalance;
            developerBalance = 0;
        }
        if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }

        users[msg.sender].referralPaidout += totalRewards;
        
        payout(msg.sender,totalRewards);
    }
    function getTotalInvested() public view returns(uint256){
        return totalInvested;
    }
    
    function setDeveloper(address payable _newDevAccount) public onlyOwner {
       require(_newDevAccount != address(0));
        developer = _newDevAccount;
    }
    function setMarketing(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketing = _newMarketingAccount;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
         require(_newOwner != address(0));
        owner = _newOwner;
   
    } 
    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketing;
    }
    
    function getOwnerAccount() public view onlyOwner returns (address) {
        return owner;
    }
    function getDevAccount() public view onlyOwner returns (address) {
        return developer;
    }
     function setDef(uint256 _def) public {
      require(msg.sender==owner);
      def = _def;
    } 
    
    function setReleaseTime(uint256 _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
}