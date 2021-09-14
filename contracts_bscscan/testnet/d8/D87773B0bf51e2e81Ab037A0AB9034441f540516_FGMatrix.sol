/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract FGMatrix {
   using SafeMath for uint256;
 
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX2Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X2) x2Matrix;
        mapping(uint8 => uint256) holdAmount;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X2 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint256 RefvID;
    }

    uint8 public constant LAST_LEVEL = 18;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address public owner;
    address public reward;
    address public club1;
    address public club2;
    address public magicalpool;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => uint) public alevelPrice;
    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event GlobalDeduction(uint256 magicalpool,uint256 owner,uint256 club1,uint256 club2,uint256 daily_reward,uint256 weekly_reward,uint8 _for);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event BiNarical(address userAddress,address referrerAddress,uint level);
    event UserIncome(address sender ,address receiver,uint256 amount ,string _for);
    event ReEntry(address user);
    
    constructor(address ownerAddress,address _magicalpool,address _club1,address _club2,address _reward) public {
        magicalpool=_magicalpool;
        club1=_club1;
        club2=_club2;
        reward=_reward;
        
        levelPrice[1] =1100*1e14; 
        levelPrice[2] =400*1e14;
        for(uint8 i=3;i<=LAST_LEVEL;i++){
          levelPrice[i]=levelPrice[i-1]+200*1e14;
        }
        
        blevelPrice[1]=500*1e14;
        for(uint8 j=2;j<=LAST_LEVEL;j++){
        blevelPrice[j]=blevelPrice[j-1]*2;
        }
        
        alevelPrice[1]=100*1e14;
        for(uint8 k=2;k<=LAST_LEVEL;k++){
        alevelPrice[k]=alevelPrice[k-1]*2;
        }
        
        owner = ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            x3vId_number[i][1]=owner;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
            
            x2vId_number[i][1]=owner;
            x2Index[i]=1;
            x2CurrentvId[i]=1;
        }
        
        users[ownerAddress].activeX3Levels[1] = true;
        users[ownerAddress].activeX6Levels[1] = true;
        userIds[1] = ownerAddress;
    
        emit Registration(ownerAddress, address(0), users[ownerAddress].id, 0);
        emit Upgrade(msg.sender, users[msg.sender].referrer, 1, 1);
        emit Upgrade(msg.sender, users[msg.sender].referrer, 2, 1);
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1], "registration cost 1100 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
    
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        address(uint160(referrerAddress)).transfer(240*1e14);
        emit UserIncome(msg.sender,referrerAddress,240*1e14,"Referral Income");
        _calculateReferrerReward(240*1e14,referrerAddress,msg.sender);
        globalDeduction(600*1e14,1);
        address freeX6Referrer = findFreeX6Referrer(1);
        users[msg.sender].x6Matrix[1].currentReferrer = freeX6Referrer;
        updateX6Referrer(msg.sender, freeX6Referrer, 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
	    emit Upgrade(msg.sender, users[msg.sender].referrer, 1, 1);
        emit Upgrade(msg.sender, users[msg.sender].referrer, 2, 1);
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=18,"not valid level");
        if(referrerAddress==userAddress) return ;
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        if(users[referrerAddress].x6Matrix[level].referrals.length < 5) {
          users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
          users[referrerAddress].holdAmount[level]+=blevelPrice[level];
          emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
          if(!(users[referrerAddress].activeX3Levels[level+1]) && users[referrerAddress].holdAmount[level]>=levelPrice[level+1])
          {
            autoUpgradeLevel(referrerAddress, (level+1));  
          }
        if(users[referrerAddress].holdAmount[level]>=blevelPrice[level+1] 
        && !(users[referrerAddress].activeX6Levels[level+1])&&users[referrerAddress].x6Matrix[level].referrals.length==5)
            {
                x3CurrentvId[level]=x3CurrentvId[level]+1;  
                // matrix upgrade
                autoUpgrade(referrerAddress, (level+1)); 

                //bi-noriacal pool user added
                address freeX2Referrer = findFreeX2Referrer(level);
                users[userAddress].x2Matrix[level].currentReferrer = freeX2Referrer;
                updateX2Referrer(referrerAddress, freeX2Referrer, level);
                
                 // 20% goes to globalDeduction
                globalDeduction(users[referrerAddress].holdAmount[level],2);
                
                 // 10% goes to direct sponcer
                if(users[referrerAddress].referrer!=address(0)){
                address(uint160(users[referrerAddress].referrer)).transfer(users[referrerAddress].holdAmount[level].mul(10).div(100));
                emit UserIncome(msg.sender,users[referrerAddress].referrer,users[referrerAddress].holdAmount[level].mul(10).div(100),"Pool Direct Sponcer");
                }
                
                 //for global deduction
               uint256 global_deduct = users[referrerAddress].holdAmount[level].mul(20).div(100);
               
                //for direct sponcer
                uint256 direct_sp = users[referrerAddress].holdAmount[level].mul(10).div(100);

                 // rentry in same matrix 
                users[referrerAddress].x6Matrix[level].referrals = new address[](0);
                users[referrerAddress].x6Matrix[level].reinvestCount+=1;
                uint256 all_deduction =direct_sp.add(global_deduct).add(blevelPrice[level]);
                
                // reentry fee  matrix deducted
                users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-all_deduction;
        
                //pending holding ammount sent to users
                address(uint160(referrerAddress)).transfer(users[referrerAddress].holdAmount[level]);
                emit UserIncome(msg.sender,referrerAddress,users[referrerAddress].holdAmount[level],"Global Pool");
                users[referrerAddress].holdAmount[level]=0;
    
                emit ReEntry(referrerAddress);
                
             }  
        }

            // if(level==18 && users[referrerAddress].x6Matrix[level].referrals.length==0)
            // {
            //     users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            //     emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            //     emit ReEntry(referrerAddress);
            //     // address(uint160(owner)).transferToken((blevelPrice[level]*5)/100,tokenId);
            //     // uint256 ded=(blevelPrice[level]*5)/100+(blevelPrice[1]);
            //     // address(uint160(referrerAddress)).transferToken(blevelPrice[level]-ded,tokenId);
            //     address freeX6Referrer = findFreeX6Referrer(1);
            //     users[referrerAddress].activeX6Levels[1] = true;
            //     updateX6Referrer(referrerAddress, freeX6Referrer, 1);
            //     emit Upgrade(referrerAddress, freeX6Referrer, 2, 1);
            //     return;
            // }

            
            // if(users[referrerAddress].referrer!=address(0))
            // {
            // // address(uint160(users[referrerAddress].referrer)).transferToken(sponsorBonus[level],tokenId);
            // // emit SponsorBonus(users[referrerAddress].referrer,referrerAddress,sponsorBonus[level],1);
            // }
            // else
            // address(uint160(owner)).transferToken(sponsorBonus[level],tokenId);
            // users[referrerAddress].x6Matrix[level].referrals = new address[](0);
            // users[referrerAddress].activeX6Levels[level]=false;
            // x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        // }
        
    }
    
    function updateX2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=18,"not valid level");
        if(referrerAddress==userAddress) return ;
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userAddress;
        x2Index[level]=newIndex;
        if(users[referrerAddress].x2Matrix[level].referrals.length < 2) {
          users[referrerAddress].x2Matrix[level].referrals.push(userAddress);
          emit NewUserPlace(userAddress, referrerAddress,3, level, uint8(users[referrerAddress].x2Matrix[level].referrals.length));
        }
        if(users[referrerAddress].x2Matrix[level].referrals.length==2){
          users[referrerAddress].x2Matrix[level].referrals= new address[](0); 
          x2CurrentvId[level]=x2CurrentvId[level]+1; 
          address(uint160(referrerAddress)).transfer(alevelPrice[level]*2);
          emit UserIncome(userAddress,referrerAddress,alevelPrice[level]*2,"Bi-Narical Income");
        }

    }

    function autoUpgradeLevel(address _user, uint8 level) private {
        if(!users[_user].activeX3Levels[level])
        {
           users[_user].activeX3Levels[level] = true;
           users[_user].activeX2Levels[level-1]=true;
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-levelPrice[level];
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-alevelPrice[level-1];
           emit Upgrade(_user, users[_user].referrer, 1, level);
        }
    }
    
    function autoUpgrade(address _user, uint8 level) private {
        users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1].sub(blevelPrice[level]);
        users[_user].activeX6Levels[level] = true;
        
        address freeX6Referrer = findFreeX6Referrer(level-1);
        updateX6Referrer(_user, freeX6Referrer, level-1);
        
        freeX6Referrer = findFreeX6Referrer(level);
        updateX6Referrer(_user, freeX6Referrer, level);
        emit Upgrade(_user, freeX6Referrer, 2, level);
    }
    
    function globalDeduction(uint256 holdAmount,uint8 _for) private {
        //magical pool 10%
         address(uint160(magicalpool)).transfer(holdAmount.mul(10).div(100));
        // admin 5%
         address(uint160(owner)).transfer(holdAmount.mul(5).div(100));
         address(uint160(club1)).transfer(holdAmount.mul(1).div(100));
         address(uint160(club2)).transfer(holdAmount.mul(2).div(100));
         address(uint160(reward)).transfer(holdAmount.mul(2).div(100));
         emit GlobalDeduction(holdAmount.mul(10).div(100),holdAmount.mul(5).div(100),holdAmount.mul(1).div(100),holdAmount.mul(2).div(100),holdAmount.mul(1).div(100),holdAmount.mul(1).div(100),_for);
        
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function _calculateReferrerReward(uint256 _investment, address _referrer,address sender) private {
	     for(uint8 i=1;i<18;i++)
	     {
	        if(_referrer!=address(0)){
                address(uint160(_referrer)).transfer(_investment.div(18)); 
                emit UserIncome(sender,_referrer,_investment.div(18),"Level Income");
             if(users[_referrer].referrer!=address(0))
                _referrer=users[_referrer].referrer;
            else
                break;
	         }
	         else{
	            i=18;
	         }
	     }
     }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(uint8 level) public view returns(address){
        uint256 id=x3CurrentvId[level];
        return x3vId_number[level][id];
    }
    
    function findFreeX2Referrer(uint8 level) public view returns(address){
        uint256 id=x2CurrentvId[level];
        return x2vId_number[level][id];
    }
    
    function withdraw(uint256 amt,address payable adr) public payable{
        require(msg.sender==owner,"only Owner");
        adr.transfer(amt);
    }

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersActiveX2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX2Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount
                );
    }
    
    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function usersX2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x2Matrix[level].currentReferrer,
                users[userAddress].x2Matrix[level].referrals,
                users[userAddress].x2Matrix[level].blocked,
                users[userAddress].x2Matrix[level].reinvestCount);
    }
    
    function getHoldingAmt(address userAddress ,uint8 level) public view returns (uint256) {
        return users[userAddress].holdAmount[level];
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}