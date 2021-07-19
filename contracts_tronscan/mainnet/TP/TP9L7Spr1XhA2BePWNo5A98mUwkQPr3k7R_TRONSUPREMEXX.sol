//SourceUnit: supremexx.sol

pragma solidity ^0.5.8;

contract TRONSUPREMEXX {
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
    uint256 countUser = 7777;
    uint256[] plans = [10,20,30]; //%
    uint256[] plansDay = [20,14,7];//days 
    uint256[] levelsAffiliate = [7,3,2];
    
    uint256 totalInvested = 0;
    
    address payable private owner;
    uint256 private ownerBalance = 0;
    
    address payable private developer;
    uint256 private developerBalance = 0;
    
    address payable private marketing;
    uint256 private marketingBalance = 0;

    address payable private admin;
    uint256 private adminBalance = 0;

    address payable private support1;
    uint256 private support1Balance = 0;

    address payable private support2;
    uint256 private support2Balance = 0;

    address payable private shareholder1;
    uint256 private shareholder1Balance = 0;

    address payable private shareholder2;
    uint256 private shareholder2Balance = 0;

    address payable private shareholder3;
    uint256 private shareholder3Balance = 0;

    address payable private shareholder4;
    uint256 private shareholder4Balance = 0;

    address payable private shareholder5;
    uint256 private shareholder5Balance = 0;

    address payable private shareholder6;
    uint256 private shareholder6Balance = 0;

    address payable private shareholder7;
    uint256 private shareholder7Balance = 0;

    address payable private shareholder8;
    uint256 private shareholder8Balance = 0;

    address payable private shareholder9;
    uint256 private shareholder9Balance = 0;

    address payable private shareholder10;
    uint256 private shareholder10Balance = 0;

    
    uint256 private def = 0;
    
    uint private releaseTime = 1606998600;
    
    mapping(address => User) users;
    mapping(uint256 => AddressUser) usersId;
    address[] wallets;
    
    constructor() public{
        owner = msg.sender;
        developer = msg.sender;
        marketing = msg.sender;
	admin = msg.sender;
	support1 = msg.sender;
	support2 = msg.sender;
	shareholder1 = msg.sender;
	shareholder2 = msg.sender;
	shareholder3 = msg.sender;
	shareholder4 = msg.sender;
	shareholder5 = msg.sender;
	shareholder6 = msg.sender;
	shareholder7 = msg.sender;
	shareholder8 = msg.sender;
	shareholder9 = msg.sender;
	shareholder10 = msg.sender;



        ownerBalance = 0;
        developerBalance = 0;
        marketingBalance = 0;
	adminBalance = 0;
	support1Balance = 0;
	support2Balance = 0;
	shareholder1Balance = 0;
	shareholder2Balance = 0;
	shareholder3Balance = 0;
	shareholder4Balance = 0;
	shareholder5Balance = 0;
	shareholder6Balance = 0;
	shareholder7Balance = 0;
	shareholder8Balance = 0;
	shareholder9Balance = 0;
	shareholder10Balance = 0;



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
        
        developer.transfer((msg.value * 10) / 100);
        marketing.transfer((msg.value * 10) / 100);
	admin.transfer((msg.value * 4) / 100);
	support1.transfer((msg.value * 4) / 100);
	support2.transfer((msg.value * 4) / 100);
	shareholder1.transfer((msg.value * 0) / 100);
	shareholder2.transfer((msg.value * 0) / 100);
	shareholder3.transfer((msg.value * 0) / 100);
	shareholder4.transfer((msg.value * 0) / 100);
	shareholder5.transfer((msg.value * 0) / 100);
	shareholder6.transfer((msg.value * 0) / 100);
	shareholder7.transfer((msg.value * 0) / 100);
	shareholder8.transfer((msg.value * 0) / 100);
	shareholder9.transfer((msg.value * 0) / 100);
	shareholder10.transfer((msg.value * 0) / 100);

        
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
	if(msg.sender==admin){
            affiliateBonus[0] += adminBalance;
        }
	if(msg.sender==support1){
            affiliateBonus[0] += support1Balance;
        }
	if(msg.sender==support2){
            affiliateBonus[0] += support2Balance;
        }
	if(msg.sender==shareholder1){
            affiliateBonus[0] += shareholder2Balance;
        }
	if(msg.sender==shareholder2){
            affiliateBonus[0] += shareholder2Balance;
        }
	if(msg.sender==shareholder3){
            affiliateBonus[0] += shareholder3Balance;
        }
	if(msg.sender==shareholder4){
            affiliateBonus[0] += shareholder4Balance;
        }
	if(msg.sender==shareholder5){
            affiliateBonus[0] += shareholder5Balance;
        }
	if(msg.sender==shareholder6){
            affiliateBonus[0] += shareholder6Balance;
        }
	if(msg.sender==shareholder7){
            affiliateBonus[0] += shareholder7Balance;
        }
	if(msg.sender==shareholder8){
            affiliateBonus[0] += shareholder8Balance;
        }
	if(msg.sender==shareholder9){
            affiliateBonus[0] += shareholder9Balance;
        }
	if(msg.sender==shareholder10){
            affiliateBonus[0] += shareholder10Balance;
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
	if(msg.sender==admin){
            totalRewards += adminBalance;
            marketingBalance = 0;
        }
	if(msg.sender==support1){
            totalRewards += support1Balance;
            marketingBalance = 0;
        }
	if(msg.sender==support2){
            totalRewards += support2Balance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
        }
	if(msg.sender==marketing){
            totalRewards += marketingBalance;
            marketingBalance = 0;
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
    
    function setDeveloper(address payable _address) public {
        require(msg.sender == owner);
        developer = _address;
    }
    function setMarketing(address payable _address) public {
        require(msg.sender == owner);
        marketing = _address;
    }
    function setOwner(address payable _address) public {
        require(msg.sender == owner);
        owner = _address;
    }
     function setDef(uint256 _def) public {
      require(msg.sender==owner);
      def = _def;
     }
    function setsupport1(address payable _address) public {
        require(msg.sender == owner);
        support1 = _address;
     }
    function setsupport2(address payable _address) public {
        require(msg.sender == owner);
        support2 = _address;
     }
    function setshareholder1(address payable _address) public {
        require(msg.sender == owner);
        shareholder1 = _address;
     }
    function setshareholder2(address payable _address) public {
        require(msg.sender == owner);
        shareholder2 = _address;
    }
    function setshareholder3(address payable _address) public {
        require(msg.sender == owner);
        shareholder3 = _address;
     }
    function setshareholder4(address payable _address) public {
        require(msg.sender == owner);
        shareholder4 = _address;
    }
    function setshareholder5(address payable _address) public {
        require(msg.sender == owner);
        shareholder5 = _address;
     }
    function setshareholder6(address payable _address) public {
        require(msg.sender == owner);
        shareholder6 = _address;
    }
    function setshareholder7(address payable _address) public {
        require(msg.sender == owner);
        shareholder7 = _address;
    }
    function setshareholder8(address payable _address) public {
        require(msg.sender == owner);
        shareholder8 = _address;
    }
    function setshareholder9(address payable _address) public {
        require(msg.sender == owner);
        shareholder9 = _address;
    }
    function setshareholder10(address payable _address) public {
        require(msg.sender == owner);
        shareholder10 = _address;

     } 
    
    function setReleaseTime(uint256 _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
}