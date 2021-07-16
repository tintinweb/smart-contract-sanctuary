//SourceUnit: easyToEarn.sol

pragma solidity >=0.4.22 <0.7.0;

interface E2EToken {
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address spender, uint addedValue) external returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}

contract EZY2ERN {
    E2EToken public E2ECoin;
    struct UserDetail {
        uint id;
        address referralAddress;
        address currentReferrer;
        uint totalIncome;
        uint reinvestCount;
        uint256 userCoins;
        uint earnReferralCoins;
        uint earnUserCoins;
        uint coinAmount;
        uint lostIncome;
        uint totalCoinsWithdrawn;
        uint totalRefCoinsWithdrawn;
        uint referralCount;
        mapping(uint => CycleData) cycleDetails;
        mapping(uint =>  address []) levelReferrals;
    }  
    
    struct CycleData {
        uint cycleIncome;
        uint investment;
        uint Roi;
        uint reffralIncome;
        uint commision;
        uint totalFundsWithdrawn;
        uint poolIncome;
        uint holdIncome;
        uint totalWithDrawnIncome;
        uint completedAt;
        uint256 date;
        bool isCompleted;
    }
    
    uint256  public decimals = 8;
    uint256 public  decimalFactor = 10 ** uint256(decimals);
    address public owner;
    address admin;
    uint public userId;
    uint public deploymentTime;
    uint Days_In_Second = 43200;
    uint day;
    uint [] poolIncomeDetail;
    uint [] comissionDetails;
    uint freeIds = 13;
    uint tokenDistributionLimit = 200000 * decimalFactor;
    uint tokenDistributed;
    uint withdrwanCoins;
    mapping(address => UserDetail) public users;
    mapping(uint => address) public idToAddress;

    
    event Registration (address user,address referrer,uint userid,uint referrerid);
    event ReInvestment (address user,address referrer,uint userid, uint investment,uint reinvestCount);
    event RoiIncome(address user, address referrer, uint userId,uint amount,uint incomeLimit,uint reinvestCount);
    event ReferBonus(address from, address reciever, uint amount, uint referrerReinvestCount);
    event UserIncome(address from, address reciever, uint amount, uint referrerReinvestCount);
    event NextPoolInvestment (uint nextPoolAmount);
    event HoldIncome(address user,uint amount, uint reinvestCount);
    event PoolIncome(address user, uint amount,uint reinvestCount);
    event WithdrawnIncome(address user,uint userId,uint amount,uint reinvestCount,uint time);
    event UserCoinBonus(address user, uint userId, uint coinAmount);
    event ReferCoinBonus(address user, address referrer,uint amount);
    event Donation(address user,uint amount);
    event LostHoldIncome(address user,uint amount);
    event HoldIncomeRecieved(address user,uint amount, uint reinvestCount);
    event CoinsStatus(string,uint);
    event NewUserPlaced(address user, address currentReferrer, address indexed referrerAddress, uint level, uint256 place);
    event MatchingCommision(address user, address referrer, uint amount,uint level,uint reinvestCount);
    
    modifier onlyOwner() {
        require(msg.sender == admin,"Only owner have access to this function.");
        _;
    }
    
    constructor(address ownerAddress, address adminAddress, address tokenAddress) public {
        owner = ownerAddress;
        admin = adminAddress;
        E2ECoin = E2EToken(tokenAddress);
        userId = 1;
        users[owner].id = userId;
        idToAddress[userId] = owner;
        
        deploymentTime = now;
        poolIncomeDetail = [30,20,15,10,8,5,4,4,2,2];
        comissionDetails = [50,15,15,15,10,10,10,5,5,5];
        emit Registration(owner,address(0),userId,uint(0));
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function depositPrice(uint count,uint penality) private view returns(bool) {
        if(count == 1) {
            require((msg.value >= 510 *1e6),'Amount should be greater than or equal to 100');
            return true;
        } else if(count > 1) {
            require((msg.value >= (users[msg.sender].cycleDetails[count-1].investment + penality + 10 *1e6)),'Amount should be greater or equal than previous investment');
            return true;
        } else {
            return false;
        }
    }
    
    function investment(address referralAddress) external payable {
        if(!isUserExists(msg.sender)) {
            register(referralAddress);
        } else {
            uint currentCount = users[msg.sender].reinvestCount;
            if(currentCount >0 && users[msg.sender].id > freeIds) {
                require(users[msg.sender].cycleDetails[currentCount].isCompleted,'ouYou have not get 325% increment of your investment.');
            }
        }
        investmentPrivate();
    }
    
    function register(address referralAddress) private{
        require(users[referralAddress].reinvestCount>0,'Your referral have to do  first investment first');
        ++userId;
        users[msg.sender].id = userId;
        users[msg.sender].referralAddress = referralAddress;
        
        idToAddress[userId] = msg.sender;
        
        emit Registration(msg.sender,referralAddress,users[msg.sender].id,users[referralAddress].id);
    }
    
    function investmentPrivate() private returns(bool) {
     
        address referralAddress = users[msg.sender].referralAddress;
        uint currentCount = users[msg.sender].reinvestCount;
        
        if(currentCount > 0 && users[msg.sender].id > freeIds) {
            require(users[msg.sender].cycleDetails[currentCount].isCompleted,'You have not get 325% increment of your investment.');
        }
        uint256 incomeLimit = ((users[msg.sender].cycleDetails[currentCount].investment)*325)/100;
        uint hold;
        if(users[msg.sender].cycleDetails[currentCount].cycleIncome > incomeLimit) {
            hold = users[msg.sender].cycleDetails[currentCount].cycleIncome - incomeLimit;
        }
            
        uint penality;
        uint diffDays;
        if(users[msg.sender].reinvestCount>0 && users[msg.sender].id > freeIds) {                                 
            diffDays = (now - users[msg.sender].cycleDetails[currentCount].completedAt)/Days_In_Second;
            if(diffDays > 4) {
                penality = (diffDays - 4) * 25 *1e6;
            }
        }
        uint gassFee;
        if(users[msg.sender].id > 4) {
            require(depositPrice(currentCount+1,penality),'Enter valid amount');
            gassFee = 10 *1e6;
            address(uint160(owner)).transfer(gassFee);
        }
        
        users[msg.sender].reinvestCount++;
        
        if(currentCount>0 && users[msg.sender].id>freeIds) {
            diffDays = (now - users[msg.sender].cycleDetails[currentCount].completedAt)/Days_In_Second;
            if(diffDays <= 4) {
                users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].cycleIncome+= hold;
                users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].totalWithDrawnIncome+= hold;
                emit HoldIncomeRecieved(msg.sender,hold,users[msg.sender].reinvestCount);
                users[msg.sender].cycleDetails[currentCount].holdIncome = 0;
            }
            else {
                emit LostHoldIncome(msg.sender,hold);
                users[msg.sender].cycleDetails[currentCount].holdIncome = 0;
                users[msg.sender].lostIncome+=hold;
            }
        }
        if(users[msg.sender].id<=freeIds) {
            users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].cycleIncome+= users[msg.sender].cycleDetails[currentCount].totalWithDrawnIncome;
            users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].totalWithDrawnIncome+= users[msg.sender].cycleDetails[currentCount].totalWithDrawnIncome;
        }
        uint investAmount = msg.value - penality;
        
        if(users[msg.sender].id <= 4) {
            users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].investment = 100000 *1e6;
            users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].date = now;
        }
        else {
            users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].investment = investAmount - gassFee;
            users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].date = now;
        }
        
        if(users[msg.sender].reinvestCount == 1) {
                     users[msg.sender].userCoins = ((users[msg.sender].cycleDetails[1].investment * 10)/100);
                     users[msg.sender].userCoins = (users[msg.sender].userCoins * decimalFactor)/10**6;
                     
                     tokenDistributed += users[msg.sender].userCoins;
                     
                     if(tokenDistributed >tokenDistributionLimit){
                         uint extra = tokenDistributed - tokenDistributionLimit;
                         tokenDistributed -= extra;
                         users[msg.sender].userCoins -= extra;
                     }
                
                getFirstReferrer(msg.sender,referralAddress);
        }
        if(referralAddress != address(0)) {
            sendRewards(referralAddress, msg.value - gassFee);
        }
        users[referralAddress].referralCount++;
        
        emit ReInvestment(msg.sender,referralAddress,users[msg.sender].id,users[msg.sender].cycleDetails[users[msg.sender].reinvestCount].investment,users[msg.sender].reinvestCount);
        return true;
    }
    
    
    
    function getFirstReferrer(address userAddress,address referrerAddress) public {
        uint256 size;
        address firstReferrer;
        
        for (uint8 i=1; i<=10; i++) {
            size = users[referrerAddress].levelReferrals[i].length;
            if (i == 1 && size < 3) {
                users[userAddress].currentReferrer = referrerAddress;
                return updateMatrixGenealogy(userAddress, referrerAddress,referrerAddress);
            }
            if (size < 3 ** uint256(i)) {
                if (i<=5) {
                    uint8 pos;
                    uint8 len;
                    uint8 minimum = 3;
                    for (uint8 j=0; j<(uint8(3)**(i-1)); j++) {
                        len = uint8(users[users[referrerAddress].levelReferrals[i-1][j]].levelReferrals[1].length);
                        if (len < minimum) {
                            minimum = len;
                            pos = j;
                        }
                    }
                    
                    firstReferrer = users[referrerAddress].levelReferrals[i-1][pos];
                    users[userAddress].currentReferrer = firstReferrer;
                    return updateMatrixGenealogy(userAddress, firstReferrer, referrerAddress);
                } else {
                    for (uint8 j=0; j<(uint8(3)**(i-1)); j++) {
                        if (users[users[referrerAddress].levelReferrals[i-1][j]].levelReferrals[1].length < 3) {
                            
                            firstReferrer = users[referrerAddress].levelReferrals[i-1][j];
                            users[userAddress].currentReferrer = firstReferrer;
                            return updateMatrixGenealogy(userAddress, firstReferrer, referrerAddress);
                        }
                    }
                }
            }
        }
    }
    
    function updateMatrixGenealogy(address userAddress, address referrerAddress, address parent) private {
        address user = userAddress;
        uint index;
        uint256 place;
        for (uint i=1; i<=10; i++) {
            if (referrerAddress != address(0)) {
                users[referrerAddress].levelReferrals[i].push(userAddress);
                if (i<=3) {
                    for(uint j=0;j<=users[referrerAddress].levelReferrals[1].length-1;j++){
                        if(user == users[referrerAddress].levelReferrals[1][j]){
                            index=j+1;
                        }
                    }
                    place += (3**(i-1) * (index-1));
                    if(i-1 == 0){
                        place++;
                    }
                    emit NewUserPlaced(userAddress, referrerAddress, parent, i, place);
                    user = referrerAddress;
                }
                else{
                    emit NewUserPlaced(userAddress, referrerAddress, parent, i, 0);
                }
                referrerAddress = users[referrerAddress].currentReferrer;
            }
        }
    }
    
    
    function matchingCommision(uint amount,address userAddress)private {
    	address currentReferrer = users[userAddress].currentReferrer;
    	for(uint i=0; i<10; i++) {
    		if(currentReferrer == address(0)) {
    			return;
    		}
    		else {
    			if(users[currentReferrer].referralCount >= i+1 || currentReferrer == owner) {
    			    uint balance = (amount * comissionDetails[i])/100;
    				users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].commision += balance;
    				users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].cycleIncome += balance;
    				users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].totalWithDrawnIncome += balance;
    				emit MatchingCommision(userAddress,currentReferrer,balance,i+1,users[currentReferrer].reinvestCount);
    				
    				uint256 incomeLimit = ((users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].investment)*325)/100;
    				if(users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].isCompleted) {
                        if(users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].cycleIncome > incomeLimit) {
                            uint hold = users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].cycleIncome - incomeLimit;
                            users[currentReferrer].cycleDetails[users[currentReferrer].reinvestCount].holdIncome = hold;
                            emit HoldIncome(currentReferrer,hold,users[currentReferrer].reinvestCount);
                        }
                    }
    			}
    		}
    		
    		currentReferrer = users[currentReferrer].currentReferrer;
    	}
    }
    
    function getCycleDetails(uint cycle) public view returns (uint roi,uint reffralIncome,uint totalWithDrawnIncome, uint cycleIncome,uint holdIncome) {
        return (users[msg.sender].cycleDetails[cycle].Roi,users[msg.sender].cycleDetails[cycle].reffralIncome,users[msg.sender].cycleDetails[cycle].totalWithDrawnIncome,users[msg.sender].cycleDetails[cycle].cycleIncome,users[msg.sender].cycleDetails[cycle].holdIncome);
    }
    
    function DailyTopSponserPool(address [] memory topPoolUsers,uint160 totalInvestment) public payable onlyOwner() {
        require(topPoolUsers.length > 0,'No user register in last 12 hour');
        require(totalInvestment > 0, 'Total investment of top pool users can not zero');
        uint poolIncome = (totalInvestment * 3)/100;
        uint distributeIncome = (poolIncome * 10)/100;
        uint adminIncome = (poolIncome * 40)/100;
        uint nextPoolIncome = (poolIncome * 50)/100;

        for(uint k=0;k<10;k++) {
            uint amount = (distributeIncome * poolIncomeDetail[k]) / 100;
            if(k<=topPoolUsers.length-1) {
                uint cycle = users[topPoolUsers[k]].reinvestCount;
                users[topPoolUsers[k]].cycleDetails[cycle].poolIncome += amount;
                users[topPoolUsers[k]].cycleDetails[cycle].cycleIncome += amount;
                users[topPoolUsers[k]].cycleDetails[cycle].totalWithDrawnIncome += amount;
                emit PoolIncome(topPoolUsers[k],amount,cycle);
                uint256 incomeLimit = ((users[topPoolUsers[k]].cycleDetails[cycle].investment)*325)/100;
                if(users[topPoolUsers[k]].cycleDetails[users[topPoolUsers[k]].reinvestCount].isCompleted) {
                    if(users[topPoolUsers[k]].cycleDetails[cycle].cycleIncome > incomeLimit) {
                        uint hold = users[topPoolUsers[k]].cycleDetails[cycle].cycleIncome - incomeLimit;
                        users[topPoolUsers[k]].cycleDetails[users[topPoolUsers[k]].reinvestCount].holdIncome = hold;
                        emit HoldIncome(topPoolUsers[k],hold,users[topPoolUsers[k]].reinvestCount);
                    }
                }
            }
            else {
                nextPoolIncome += amount;
            }
        }
        address(uint160(owner)).transfer(adminIncome);
        emit NextPoolInvestment(nextPoolIncome);
    }
    
    
    function Roi() private{
        uint amount;
        uint depositCount = users[msg.sender].reinvestCount;
      
        require(depositCount > 0,'Please invest to get Roi income.');
        uint256 incomeLimit = ((users[msg.sender].cycleDetails[depositCount].investment)*325)/100;

        if(users[msg.sender].cycleDetails[depositCount].cycleIncome < incomeLimit) {
            uint ROI = calculateROI(msg.sender,depositCount);
             if(ROI > users[msg.sender].cycleDetails[depositCount].totalFundsWithdrawn){
                 amount= ROI- users[msg.sender].cycleDetails[depositCount].totalFundsWithdrawn;
                  if(address(this).balance < amount ){
                    amount = address(this).balance;
                }
             }
            users[msg.sender].cycleDetails[depositCount].totalFundsWithdrawn += amount;
            users[msg.sender].cycleDetails[depositCount].Roi += amount;
            users[msg.sender].cycleDetails[depositCount].cycleIncome += amount;
            users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome += amount;

            matchingCommision(amount,msg.sender);
            
            emit RoiIncome (msg.sender,users[msg.sender].referralAddress,users[msg.sender].id,amount,incomeLimit,users[msg.sender].reinvestCount);
        }
    }
    
    function getCoins()private{
                uint COINS = calculateCoins(msg.sender);
                if(COINS > users[msg.sender].userCoins) {
                    uint extra = COINS - users[msg.sender].userCoins;
                    COINS = COINS - extra;
                }
                if(COINS > users[msg.sender].totalCoinsWithdrawn) {
                        uint coins = COINS - users[msg.sender].totalCoinsWithdrawn;
                        uint coinBal = coinBalance();
                        
                        if(coinBal < coins) {
                            coins = coinBal;
                        }
                        if(coinBal>0) {
                            E2ECoin.transfer(msg.sender,coins);
                        
                            users[msg.sender].earnUserCoins += coins;
                            users[msg.sender].coinAmount += coins;
                            users[msg.sender].totalCoinsWithdrawn += coins;
                            withdrwanCoins += coins;
                            emit UserCoinBonus(msg.sender,users[msg.sender].id,coins);
                        }
                        if(users[msg.sender].referralAddress != address(0)){
                            uint coinBalnce = coinBalance();
                            uint refCoins = ((coins*10)/100);
                            if(coinBalnce < refCoins) {
                                refCoins = coinBalnce;
                            }
                            if(coinBal > 0) {
                                E2ECoin.transfer(users[msg.sender].referralAddress,refCoins);
                                users[users[msg.sender].referralAddress].coinAmount += ((coins*10)/100);
                                tokenDistributed += refCoins;
                                withdrwanCoins += refCoins;
                                emit ReferCoinBonus(msg.sender,users[msg.sender].referralAddress,((coins*10)/100));
                            }

                        }
                }
                else {
                    emit CoinsStatus('Coins Completed',users[msg.sender].earnUserCoins);
                }
    }
    
    function calculateROI (address user, uint count) private  view returns(uint value){
        uint intrest = (users[user].cycleDetails[count].investment * 1)/100;
        uint daysOver = ((now - users[user].cycleDetails[count].date)/Days_In_Second);
        return daysOver * intrest;
    }
    
    function calculateCoins(address user) private view returns(uint coin) {
        uint daysOver;
        uint coins = ((users[user].userCoins)/100) ;
        daysOver = ((now - users[user].cycleDetails[1].date)/Days_In_Second);
        uint256 totalCoins = daysOver * coins;
        return totalCoins;
    }
    
    function totalWithDrawn() public returns(bool) {
        uint depositCount = users[msg.sender].reinvestCount;
     
        uint256 incomeLimit = ((users[msg.sender].cycleDetails[depositCount].investment)*325)/100;
        getCoins();
        if((!users[msg.sender].cycleDetails[depositCount].isCompleted) && (users[msg.sender].id>freeIds)) {
            Roi();
            if(users[msg.sender].cycleDetails[depositCount].cycleIncome>=incomeLimit){
                users[msg.sender].cycleDetails[depositCount].isCompleted = true;
                users[msg.sender].cycleDetails[depositCount].holdIncome = users[msg.sender].cycleDetails[depositCount].cycleIncome - incomeLimit;
                users[msg.sender].cycleDetails[depositCount].completedAt = now;
                
                emit HoldIncome(msg.sender,users[msg.sender].cycleDetails[depositCount].holdIncome,users[msg.sender].reinvestCount);
                
                users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome = users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome - users[msg.sender].cycleDetails[depositCount].holdIncome;
            } 
            address(uint160(msg.sender)).transfer(users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome);
            users[msg.sender].totalIncome += users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome;
            emit WithdrawnIncome(msg.sender,users[msg.sender].id,users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome,depositCount,users[msg.sender].cycleDetails[depositCount].completedAt);
            users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome = 0;
        }
        if(users[msg.sender].id<=freeIds) {
            if((!users[msg.sender].cycleDetails[depositCount].isCompleted)) {
                Roi();
                if(users[msg.sender].cycleDetails[depositCount].cycleIncome >= incomeLimit){
                    users[msg.sender].cycleDetails[depositCount].isCompleted = true;
                    // emit CoinsStatus('You achieved 325% income',users[msg.sender].cycleDetails[depositCount].cycleIncome);
                    users[msg.sender].cycleDetails[depositCount].completedAt = now;
                }
            }
            address(uint160(msg.sender)).transfer(users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome);
            users[msg.sender].totalIncome += users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome;
            emit WithdrawnIncome(msg.sender,users[msg.sender].id,users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome,depositCount,users[msg.sender].cycleDetails[depositCount].completedAt);
            users[msg.sender].cycleDetails[depositCount].totalWithDrawnIncome = 0;
        }
        return true;
    }
    
    
    function sendRewards(address referralAddress, uint total) private {
        uint amount = (total)* 15/100;
        uint256 incomeLimit = ((users[msg.sender].cycleDetails[users[referralAddress].reinvestCount].investment)*325)/100;
        users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].reffralIncome += amount;
        users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].cycleIncome += amount;
        users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].totalWithDrawnIncome += amount;
        users[referralAddress].totalIncome += amount; 
        
        if(users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].isCompleted) {
            if(users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].cycleIncome > incomeLimit) {
                uint hold = users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].cycleIncome - incomeLimit;
                users[referralAddress].cycleDetails[users[referralAddress].reinvestCount].holdIncome = hold;
                emit HoldIncome(referralAddress,hold,users[referralAddress].reinvestCount);
            }
        }
        
        emit ReferBonus(msg.sender,referralAddress,amount,users[referralAddress].reinvestCount);
    }
    
    function  coinBalance () public view returns(uint) {
        return E2ECoin.balanceOf(address(this));
    }

    function contractBalance () public view returns (uint) {
        return address(this).balance;
    }
    
    function donation() public payable {
        require(msg.value>0,'Amount can not be zero');
        emit Donation(msg.sender,msg.value);
    }
}