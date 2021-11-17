//SourceUnit: CNFGlobe.sol


pragma solidity ^0.5.0;

//SPDX-License-Identifier: UNLICENSED

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CNFGlobe {

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
        uint256 join_timestamp;
        uint256 locked_amount;
        uint256 total_income;
        uint256 total_withdrawn;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
    }
    
    struct X2 {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
    }

    uint8 public constant LAST_LEVEL = 13;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address public owner;
    address public rewardwallet;
    address public social_cause;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => uint) public alevelPrice;
    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;
    
    bool public holdingwithdraw;
    
    IERC20 public CNFToken;
    function () external payable {}
    event Multisended(uint256 value ,address indexed sender,string _type);
    event Airdropped(address indexed _userAddress, uint256 _amount,string _type);
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event GlobalDeduction(uint256 magicalpool,uint256 owner,uint256 social_cause,uint256 daily_reward,uint256 weekly_reward,uint8 _for);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event BiNarical(address userAddress,address referrerAddress,uint level);
    event UserIncome(address sender ,address receiver,uint256 amount ,string _for);
    event ReEntry(address user,uint8 level);
    event ClaimHolding(address user ,uint256 amount);
    event Withdraw(address user ,uint256 amount,string  _type);
    
    constructor(address ownerAddress,address _rewardwallet,address _social_cause,IERC20 _token) public {
        rewardwallet=_rewardwallet;
        owner = ownerAddress;
        social_cause=_social_cause;
        CNFToken=_token;
        
        levelPrice[1] =500*1e18; 
        levelPrice[2] =150*1e18;
        for(uint8 i=3;i<=LAST_LEVEL;i++){
          levelPrice[i]=levelPrice[i-1].mul(2);
        }
        
        blevelPrice[1]=250*1e18;
        for(uint8 j=2;j<=LAST_LEVEL;j++){
        blevelPrice[j]=blevelPrice[j-1].mul(2);
        }
        
        alevelPrice[1]=50*1e18;
        for(uint8 k=2;k<=LAST_LEVEL;k++){
        alevelPrice[k]=alevelPrice[k-1].mul(2);
        }
        
        users[ownerAddress].id=1;
        users[ownerAddress].referrer=address(0);
        users[ownerAddress].partnersCount=uint(0);
        users[ownerAddress].join_timestamp= block.timestamp;
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
        emit Upgrade(ownerAddress, users[ownerAddress].referrer, 1, 1);
        emit Upgrade(ownerAddress, users[ownerAddress].referrer, 2, 1);
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(CNFToken.balanceOf(userAddress)>=(levelPrice[1]),"Low Balance ! Registration cost 500 CNF");
        require(CNFToken.allowance(userAddress,address(this))>=levelPrice[1],"Invalid allowance amount");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        CNFToken.transferFrom(userAddress ,address(this), levelPrice[1]);
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        users[userAddress].id=lastUserId;
        users[userAddress].referrer=referrerAddress;
        users[userAddress].partnersCount=uint(0);
        users[userAddress].join_timestamp = block.timestamp;
        users[userAddress].locked_amount = 150*1e18;
        idToAddress[lastUserId] = userAddress;
        
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
    
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        
        //40% sponcer income
        users[referrerAddress].total_income=users[referrerAddress].total_income.add(40*1e18);
        // CNFToken.transfer(referrerAddress,40*1e18);
        
        emit UserIncome(userAddress,referrerAddress,40*1e18,"Referral Income");
        //40% Level distribution
        _calculateReferrerReward(40*1e18,referrerAddress,userAddress);
        //20%  globalDeduction
        globalDeduction(100*1e18,1);
        
        address freeX6Referrer = findFreeX6Referrer(1);
        users[userAddress].x6Matrix[1].currentReferrer = freeX6Referrer;
        updateX6Referrer(userAddress, freeX6Referrer, 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
	    emit Upgrade(userAddress, users[userAddress].referrer, 1, 1);
        emit Upgrade(userAddress, users[userAddress].referrer, 2, 1);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=LAST_LEVEL,"not valid level");
        if(referrerAddress==userAddress) return ;
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        if(users[referrerAddress].x6Matrix[level].referrals.length < 5) {
          users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
          users[referrerAddress].holdAmount[level]+=blevelPrice[level];
          emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));

            if(level<LAST_LEVEL && users[referrerAddress].holdAmount[level]>=blevelPrice[level+1]&&users[referrerAddress].x6Matrix[level].referrals.length==5)
            {
        
                    //ReEntry deduction in holdAmount
                    users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-blevelPrice[level];
                    users[referrerAddress].x6Matrix[level].referrals = new address[](0);
                    users[referrerAddress].x6Matrix[level].reinvestCount+=1;
                    
                    //Next Pool Upgradation 
                    users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-blevelPrice[level+1];
                    x3CurrentvId[level]=x3CurrentvId[level]+1;  
                    autoUpgrade(referrerAddress, (level+1)); 
                    uint256 _amount= users[referrerAddress].holdAmount[level];
                    //Next Level Upgradation 
                    autoUpgradeLevel(referrerAddress, (level+1));  
                    //bi-noriacal pool user added
                    address freeX2Referrer = findFreeX2Referrer(level);
                    users[userAddress].x2Matrix[level].currentReferrer = freeX2Referrer;
                    updateX2Referrer(referrerAddress, freeX2Referrer, level);
                    emit Upgrade(referrerAddress,freeX2Referrer,3,level);
                    
             
                     // 20% goes to globalDeduction
                    uint256 global_deduct = _amount.mul(20).div(100);
                    globalDeduction(_amount,2);
                     // 10% goes to direct sponcer
                    uint256 direct_sp = _amount.mul(10).div(100);
                    if(users[referrerAddress].referrer!=address(0)){

                        // CNFToken.transfer(users[referrerAddress].referrer,direct_sp);
                        users[users[referrerAddress].referrer].total_income= users[users[referrerAddress].referrer].total_income.add(direct_sp);
                        
                        emit UserIncome(referrerAddress,users[referrerAddress].referrer,direct_sp,"Pool Direct Sponcer");
                    }
                    
                  
                    uint256 all_deduction =direct_sp.add(global_deduct);
                    users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-all_deduction;
                    //net holding ammount sent to users
                    // address(uint160(referrerAddress)).transfer(users[referrerAddress].holdAmount[level]);
                    if(referrerAddress!=address(0)){
                    // CNFToken.transfer(referrerAddress,users[referrerAddress].holdAmount[level]);
                    users[referrerAddress].total_income= users[referrerAddress].total_income.add(users[referrerAddress].holdAmount[level]);
                    }
                    emit UserIncome(referrerAddress,referrerAddress,users[referrerAddress].holdAmount[level],"Global Pool");
                    users[referrerAddress].holdAmount[level]=0;
                    emit ReEntry(referrerAddress,level);
                 } 
            if(level==LAST_LEVEL && users[referrerAddress].x6Matrix[level].referrals.length==5)
            {
                //REEntry  
                users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-blevelPrice[level];
                users[referrerAddress].x6Matrix[level].referrals = new address[](0);
                users[referrerAddress].x6Matrix[level].reinvestCount+=1;
                //Global Pool Income
                
                // address(uint160(referrerAddress)).transfer(users[referrerAddress].holdAmount[level]);
                if(referrerAddress!=address(0)){
                    // CNFToken.transfer(referrerAddress,users[referrerAddress].holdAmount[level]);
                    users[referrerAddress].total_income = users[referrerAddress].total_income.add(users[referrerAddress].holdAmount[level]);
                 }
                emit UserIncome(referrerAddress,referrerAddress,users[referrerAddress].holdAmount[level],"Global Pool");
                users[referrerAddress].holdAmount[level]=0;
            }
        }

        
    }
    
    function updateX2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=LAST_LEVEL,"not valid level");
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

        if(referrerAddress!=address(0)){
        //   CNFToken.transfer(referrerAddress,alevelPrice[level]*2);
          users[referrerAddress].total_income=users[referrerAddress].total_income.add(alevelPrice[level]*2);
        }
          emit UserIncome(userAddress,referrerAddress,alevelPrice[level]*2,"Bi-Narical Income");
        }

    }
    
    function autoUpgradeLevel(address _user, uint8 level) private {
           users[_user].activeX3Levels[level] = true;
           users[_user].activeX2Levels[level-1]=true;
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-levelPrice[level];
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-alevelPrice[level-1];
           
        // address(uint160(users[_user].referrer)).transfer(levelPrice[level].mul(40).div(100));
        if(users[_user].referrer!=address(0)){
            // CNFToken.transfer(users[_user].referrer,levelPrice[level].mul(40).div(100));
            users[users[_user].referrer].total_income=users[users[_user].referrer].total_income.add(levelPrice[level].mul(40).div(100));
        }
        emit UserIncome(_user,users[_user].referrer,levelPrice[level].mul(40).div(100),"Referral Level Upgrade");
        _calculateReferrerReward(levelPrice[level].mul(40).div(100), users[_user].referrer,_user);
        globalDeduction(levelPrice[level],3);
        emit Upgrade(_user, users[_user].referrer, 1, level);
    }
    
    function autoUpgrade(address _user, uint8 level) private {
        users[_user].activeX6Levels[level] = true;
        address freeX6Referrer = findFreeX6Referrer(level-1);
        users[_user].x6Matrix[level-1].currentReferrer = freeX6Referrer;
        updateX6Referrer(_user, freeX6Referrer, level-1);
        
        freeX6Referrer = findFreeX6Referrer(level);
        users[_user].x6Matrix[level].currentReferrer = freeX6Referrer;
        updateX6Referrer(_user, freeX6Referrer, level);
        emit Upgrade(_user, freeX6Referrer, 2, level);
    }
    
    function globalDeduction(uint256 holdAmount,uint8 _for) private {
        //magical pool 10%
        //  address(uint160(magicalpool)).transfer(holdAmount.mul(10).div(100));
        // CNFToken.transfer(magicalpool,holdAmount.mul(10).div(100));
        // admin 4%
        //  address(uint160(owner)).transfer(holdAmount.mul(5).div(100));
        CNFToken.transfer(owner,holdAmount.mul(5).div(100));
        // address(uint160(social_cause)).transfer(holdAmount.mul(1).div(100));
        CNFToken.transfer(social_cause,holdAmount.mul(1).div(100));
        //  address(uint160(daily_reward)).transfer(holdAmount.mul(2).div(100));
        // CNFToken.transfer(daily_reward,holdAmount.mul(2).div(100));
        CNFToken.transfer(rewardwallet,holdAmount.mul(14).div(100));
        //  address(uint160(weekly_reward)).transfer(holdAmount.mul(2).div(100));
         emit GlobalDeduction(holdAmount.mul(10).div(100),holdAmount.mul(5).div(100),holdAmount.mul(1).div(100),holdAmount.mul(2).div(100),holdAmount.mul(2).div(100),_for);
        
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function _calculateReferrerReward(uint256 _investment, address _referrer,address sender) private {
	     for(uint8 i=1;i<=LAST_LEVEL;i++)
	     {
	        if(_referrer!=address(0)){
                // CNFToken.transfer(_referrer,_investment.div(LAST_LEVEL));
                users[_referrer].total_income=users[_referrer].total_income.add(_investment.div(LAST_LEVEL));
                emit UserIncome(sender,_referrer,_investment.div(LAST_LEVEL),"Level Income");
             if(users[_referrer].referrer!=address(0))
                _referrer=users[_referrer].referrer;
            else
                break;
	         }
	         else{
	            i=LAST_LEVEL;
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

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersActiveX2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX2Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].reinvestCount
                );
    }
    
    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function usersX2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint256) {
        return (users[userAddress].x2Matrix[level].currentReferrer,
                users[userAddress].x2Matrix[level].referrals,
                users[userAddress].x2Matrix[level].reinvestCount);
    }
    
    function withdrawETH(uint256 amt,address payable adr) public onlyOwner{
        adr.transfer(amt);
    }
    
    function withdrawToken (IERC20 _Token ,address payable _address,uint256 _amt) public onlyOwner{
        _Token.transfer(_address,_amt);
    }
    
    function ChangeWallet(address adr,uint8 _type) public onlyOwner{
        if(_type==1)
        rewardwallet=adr;
        else 
        social_cause=adr;
    }
    
    function changeHoldingWithdraw(bool _enable) public onlyOwner {
        holdingwithdraw=_enable;
    }
    
    function claimHoldAmount() public {
        require(isUserExists(msg.sender),"user not exists");
        require(holdingwithdraw,"holding withdraw disble now!");
        require(users[msg.sender].locked_amount!=0,"Already claimed");
        require(CNFToken.balanceOf(address(this))>0,"Contract Token Balance Low!");
        CNFToken.transfer(msg.sender,users[msg.sender].locked_amount);
        emit ClaimHolding(msg.sender,users[msg.sender].locked_amount);
        users[msg.sender].locked_amount=0;
    }
    
    function withdrawTotalIncome() public {
         require(isUserExists(msg.sender),"user not exists");
         require(users[msg.sender].total_income>0,"invalid withdraw amount!");
         CNFToken.transfer(msg.sender,users[msg.sender].total_income);
         users[msg.sender].total_withdrawn=users[msg.sender].total_withdrawn.add(users[msg.sender].total_income);
         emit Withdraw(msg.sender,users[msg.sender].total_income,"total_income");
         users[msg.sender].total_income = 0;
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}