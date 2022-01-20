/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity >=0.4.23 <0.6.0;

contract MyLeaders {
    struct User {
        uint32 id;
        address referrer;
        mapping(uint8 => bool) eligibility;
        mapping(uint8 => mapping(uint8 => uint16)) premiumReinvestCount;
        mapping(uint8 => mapping(uint8 => bool)) reinvestEligibility;
        mapping(uint8 => uint256) accumulatedReward;              // Rewards accumulated if the user is not active
        // All mappings use key matrixCode to refer to Millionaire or Junior Club which is a uint8
        mapping(uint8 => uint256) partnersCount;
        mapping(uint8 => bool) firstReferral;  // Whether the user was the first direct referral to his referrer
        mapping(uint8 => bool) isActive;
        mapping(uint8 => mapping(uint8 => bool)) activeBonusMatrixLevels;
        mapping(uint8 => bool) activePrimaryMatrixLevels;
        mapping(uint8 => bool) thirdLinePayout;
        mapping(uint8 => Matrix3x3) primaryMatrix;
        mapping(uint8 => mapping(uint8 => bool)) activeEliteMatrixLevels;
        mapping(uint8 => bool) activeBillionaireMatrixLevels;
    }
    
    struct Matrix3x3 {
        address currentReferrer;
        uint8 level;
        uint64 position;
        mapping(uint8 => mapping(uint64 => address))levelReferrals;
        mapping(uint8 => uint64) levelReferralCount;
    }
    
    uint8 constant base = 3;
    bool initializer;
    uint8 public MATRIX_CODE;
    address payable public owner;
    address payable public manager;
    uint32 public lastUserId;
    
    mapping(address => User) public users;
    mapping(uint32 => address) public idToAddress;
    mapping(address => uint) public balances; 
    mapping(uint8 =>  mapping(uint8 => uint)) public rewards;           // Mapping of various reward payouts
    mapping(uint8 => uint) public matrixCodePrice;
    
    mapping(uint8 => mapping(uint8 => mapping(uint8 => uint8))) globalTreeLevel;  // Mapping MATRIX_CODE => matrixType => matrixLevel => treeLevel;
    mapping(uint8 => mapping(uint8 => mapping(uint8 => mapping(uint8 => address[])))) globalTreePosition;   // mapping MATRIX_CODE => matrixType => matrixLevel => treeLevel => address[]
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint8 matrixCode, uint32 timestamp);
    event SubAccountRegistration(address indexed user, address indexed parent, uint indexed userId, uint32 timestamp);

    event NewUserPlace(address indexed user, uint256 userId, address indexed referrer, uint8 matrixType, uint8 matrixCode, uint64 place, uint8 level, uint256 cycleCount, uint32 timestamp);
    event EthPayout(uint256 userId, uint8 matrixCode, uint8 payoutType, uint256 amount, uint32 timestamp);

    event Reinvest(address indexed user, uint8 matrix, uint8 matrixType, uint8 level, uint32 timestamp);

    function initialize(address payable ownerAddress, address payable managerAddress) public {
        require(!initializer, "MyLeaders: Already initialized");
        initializer=true;
        MATRIX_CODE=3;
        lastUserId=2;
        matrixCodePrice[1] = 6 ether;
        matrixCodePrice[2] = 1.25 ether;
        matrixCodePrice[3] = 0.25 ether;
        matrixCodePrice[0] = 7.25 ether;        // JUMP Start
        

        /**Reward Type:
         * 1) Direct Partner: 6 ETH / 1.25 ETH
         * 2) Bonus Profit II: 18 ETH / 3.75 ETH
         * 3) Elite II: 200 ETH / 0 ETH
         * 4) Elite III: 400 ETH / 0 ETH
         * 5) Elite IV: 800 ETH / 0 ETH
         * 6) Final Elite (Position 1): 480 ETH (1480-1000) / 104 ETH
         * 7) Final Elite (Position 2/3): 1546 ETH / 117.75 ETH
         * 8) All 27 positions filled: 24 ETH / 5 ETH
         * 9) Final Billionaire (Position 1): 8000 ETH / 0 ETH
         * 10) Final Billionaire (Position 2/3): 9000 ETH
         **/
        
        rewards[1][1] = 6 ether;
        rewards[2][1] = 1.25 ether;
        rewards[1][2] = 18 ether;
        rewards[2][2] = 3.75 ether;
        rewards[1][3] = 200 ether;
        rewards[1][4] = 400 ether;
        rewards[1][5] = 800 ether;
        rewards[1][6] = 480 ether;
        rewards[2][6] = 104 ether;
        rewards[1][7] = 1546 ether;
        rewards[2][7] = 117.75 ether;
        rewards[1][8] = 24 ether;
        rewards[2][8] = 5 ether;
        rewards[1][9] = 8000 ether;
        rewards[1][10] = 9000 ether;
        
        owner = ownerAddress;
        manager = managerAddress;
        
        users[ownerAddress].id = 1;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= MATRIX_CODE; i++) {
            users[ownerAddress].activePrimaryMatrixLevels[i] = true;
            users[ownerAddress].primaryMatrix[i].position=1;
            users[ownerAddress].primaryMatrix[i].levelReferrals[0][1]=ownerAddress;
            emit Registration(ownerAddress, address(0), 1, 0, i, uint32(block.timestamp));
            for (uint8 j = 1; j <= 5; j++) {
                if(j<=2){
                    users[owner].activeBonusMatrixLevels[i][j] = true;
                    globalTreePosition[i][1][j][0].push(owner);
                    globalTreeLevel[i][1][j] = 1;
                    
                }
                if((i==2&&j<=3) || i==1){
                    users[owner].activeEliteMatrixLevels[i][j] = true;
                    globalTreePosition[i][2][j][0].push(owner);
                    globalTreeLevel[i][2][j] = 1;
                }
                
                if(i==1 && j<=3) {
                    // Registering the Billionaire Club
                    users[owner].activeBillionaireMatrixLevels[j] = true;
                    globalTreePosition[1][3][j][0].push(owner);
                    globalTreeLevel[1][3][j] = 1;
                }
            }
        }
    }
    
    function millionaireRegistrationExt(address newAddress) external {
        require(users[msg.sender].eligibility[1], "Not eligible");
        delete users[msg.sender].eligibility[1];
        emit SubAccountRegistration(newAddress, msg.sender, lastUserId, uint32(block.timestamp));
        registration(newAddress, msg.sender, 1);
    }
    
    function adminRegistrationExt(address referrerAddress, address userAddress, uint8 matrixCode) external payable {
        require(msg.sender==manager, "Unauthorized");
        require(matrixCode>=0 && matrixCode<=MATRIX_CODE, "Invalid Matrix Code");
        
        if(matrixCode==0) {
            require(!isRegisteredUser(userAddress, 1), "User already exists in this matrixCode");
            require(!isRegisteredUser(userAddress, 2), "User already exists in this matrixCode");

            registration(userAddress, referrerAddress, 1);
            registration(userAddress, referrerAddress, 2);
        }
        else {
            require(!isRegisteredUser(userAddress, matrixCode), "User already exists in this matrixCode");
            registration(userAddress, referrerAddress, matrixCode);
        }
    }

    function registrationExt(address referrerAddress, uint8 matrixCode) external payable {
        require(matrixCode>=0 && matrixCode<=MATRIX_CODE, "Invalid Matrix Code");
        require(msg.value == matrixCodePrice[matrixCode], "Invalid Registration Cost");


        if(matrixCode==0) {
            require(!isRegisteredUser(msg.sender, 1), "User already exists in this matrixCode");
            require(!isRegisteredUser(msg.sender, 2), "User already exists in this matrixCode");

            registration(msg.sender, referrerAddress, 1);
            registration(msg.sender, referrerAddress, 2);
        }
        else {
            require(!isRegisteredUser(msg.sender, matrixCode), "User already exists in this matrixCode");
            registration(msg.sender, referrerAddress, matrixCode);
        }
    }
    
    function bilionaireRegistrationExt(uint8 choice) external payable {
        require(users[msg.sender].eligibility[4], "Unauthorized");
        require(choice==1||choice==2, "Only 2 choices");
        if(choice==1){
            users[msg.sender].eligibility[4]=false;
            userSecondaryPlacement(msg.sender, 1, 1, 3);
        } else {
            delete users[msg.sender].eligibility[4];
            msg.sender.transfer(1000 ether);
            emit EthPayout(users[msg.sender].id, 1, 11, 1000 ether, uint32(block.timestamp));

            
        }
    }
    
    function registration(address userAddress, address referrerAddress, uint8 matrixCode) private {
        
        require(users[referrerAddress].id != 0, "Referrer does not exist");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Cannot be a contract");
        
        if(users[userAddress].id==0) {
            //Registering user in User Address Directory
            users[userAddress].id = lastUserId;
            users[userAddress].referrer = referrerAddress;
            
            idToAddress[lastUserId] = userAddress;
            users[userAddress].referrer = referrerAddress;
            lastUserId++;
        }
        users[userAddress].activePrimaryMatrixLevels[matrixCode] = true;
        users[userAddress].primaryMatrix[matrixCode].position=1;
        users[userAddress].primaryMatrix[matrixCode].levelReferrals[0][1]=userAddress;
        address currentReferrer = referrerAddress;
        
        if(!isRegisteredUser(referrerAddress, matrixCode)){
            currentReferrer = findFreeReferrer(referrerAddress, matrixCode);    // Finding referrer for cross buying cases
        }
        
        // Direct Partners
        users[referrerAddress].partnersCount[matrixCode]++;
                
        /** Making referrer active partner
         * Active Partner is Partner with at least 3 direct associates
         **/
        if(users[referrerAddress].partnersCount[matrixCode]==3){
            users[referrerAddress].isActive[matrixCode] = true; 
            if(users[referrerAddress].accumulatedReward[matrixCode]>0){
                delete users[referrerAddress].accumulatedReward[matrixCode];
                address(uint160(referrerAddress)).transfer(users[referrerAddress].accumulatedReward[matrixCode]);
            }
        }
        
        if(users[referrerAddress].partnersCount[matrixCode]==1){
            // Sending reward for first direct associate
            sendRewards(referrerAddress, matrixCode, 1);
            users[userAddress].firstReferral[matrixCode] = true;
        }
        
        userPlacement(currentReferrer, userAddress, matrixCode);             // Primary Placement in TurboPower3x3
        
        address partner = users[users[userAddress].primaryMatrix[matrixCode].currentReferrer].primaryMatrix[matrixCode].currentReferrer; 
        address superPartner = users[partner].primaryMatrix[matrixCode].currentReferrer; 

         // Bonus Matrix Logic
        if(checkBonusMatrixCriteria(partner, matrixCode)){
            userSecondaryPlacement(partner, matrixCode, 1, 1);
            users[partner].activeBonusMatrixLevels[matrixCode][1] = true;
        }
        
        // Elite Matrix Logic
        if(checkEliteMatrixCriteria(superPartner, matrixCode)) {
            userSecondaryPlacement(superPartner, matrixCode, 1, 2);
            users[superPartner].activeEliteMatrixLevels[matrixCode][1] = true;
        }
        
        // Third Line payout
        if(checkThirdLineCriteria(superPartner, matrixCode)) {
            sendRewards(superPartner, matrixCode, 8);
            users[superPartner].thirdLinePayout[matrixCode] = true;
        }
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, matrixCode, uint32(block.timestamp));
    }
    
    function findFreeReferrer(address referrerAddress, uint8 matrixCode) private view returns(address) {
        while (referrerAddress!=address(0)) {
            if (usersActivePrimaryMatrixLevels(referrerAddress, matrixCode)) {
                return referrerAddress;
            }
            
            referrerAddress = users[referrerAddress].referrer;
        }
        return owner;
    }

    function checkBonusMatrixCriteria(address partnerAddress, uint8 matrixCode) private view returns(bool) {
        if(partnerAddress==owner) {
            return false;
        }
        else if(users[partnerAddress].activeBonusMatrixLevels[matrixCode][1]){ // Check is Partner already has a bonus Matrix
            return false;
        }
        else if(partnerAddress!=address(0)){
            if(users[partnerAddress].primaryMatrix[matrixCode].levelReferralCount[2]<2){  // Minimum two users in second line
                return false;
            }
            else {
                for(uint64 i=0; i<users[partnerAddress].primaryMatrix[matrixCode].levelReferralCount[2]; i++){
                    if(!users[users[partnerAddress].primaryMatrix[matrixCode].levelReferrals[2][i]].firstReferral[matrixCode]){
                        return true;
                    }
                }
                return false;
            }
        }
        else {
            return false;
        }
            
    }
    
    function checkEliteMatrixCriteria(address superPartner, uint8 matrixCode) public view returns(bool) {
        // Elite Matrix Logic
        return (superPartner!=owner && 
                !users[superPartner].activeEliteMatrixLevels[matrixCode][1] &&                   // Check is Partner already has a bonus Matrix
                users[superPartner].isActive[matrixCode] &&                                     // If Super Partner is active 
                users[superPartner].primaryMatrix[matrixCode].levelReferralCount[2]==9 &&   //Partner on the second line has all 9 positions filled
                users[superPartner].primaryMatrix[matrixCode].levelReferralCount[3]>=21);  // any 21 of the 27 positions in the third line
    }
    
    function checkThirdLineCriteria(address superPartner, uint8 matrixCode) private view returns(bool) {
        return (!users[superPartner].thirdLinePayout[matrixCode] &&                             // Check if Super Partner has already claimed thirdLinePayout
                users[superPartner].isActive[matrixCode] &&                                    // If Super Partner is active 
                users[superPartner].primaryMatrix[matrixCode].levelReferralCount[3]==27);  // All 27 positions in the third line are filled
    }
    
    function usersActivePrimaryMatrixLevels(address userAddress, uint8 matrixCode) public view returns(bool) {
        return users[userAddress].activePrimaryMatrixLevels[matrixCode];
    }

    function usersActiveBonusMatrixLevels(address userAddress, uint8 matrixCode, uint8 level) private view returns(bool) {
        return users[userAddress].activeBonusMatrixLevels[matrixCode][level];
    }
    
    function usersActiveEliteMatrixLevels(address userAddress, uint8 matrixCode, uint8 level) private view returns(bool) {
        return users[userAddress].activeEliteMatrixLevels[matrixCode][level];
    }
    
    function usersActiveBonusMatrixLevelsExt(address userAddress, uint8 matrixCode) external view returns(bool, bool) {
        return (users[userAddress].activeBonusMatrixLevels[matrixCode][1], users[userAddress].activeBonusMatrixLevels[matrixCode][2]);
    }
    
    function usersActiveEliteMatrixLevelsExt(address userAddress, uint8 matrixCode) external view returns(bool, bool, bool, bool, bool) {
        return (users[userAddress].activeEliteMatrixLevels[matrixCode][1], 
                users[userAddress].activeEliteMatrixLevels[matrixCode][2],
                users[userAddress].activeEliteMatrixLevels[matrixCode][3],
                users[userAddress].activeEliteMatrixLevels[matrixCode][4],
                users[userAddress].activeEliteMatrixLevels[matrixCode][5]);
    }

    function isRegisteredUser(address user, uint8 matrixCode) public view returns (bool) {
        return (users[user].activePrimaryMatrixLevels[matrixCode]);
    }
    
    function userPlacement(address referrerAddress, address userAddress, uint8 matrixCode) private {
        for(uint i = users[referrerAddress].primaryMatrix[matrixCode].position; i<=(base)**users[referrerAddress].primaryMatrix[matrixCode].level; i++) {
            address firstReferrer = users[referrerAddress].primaryMatrix[matrixCode].levelReferrals[users[referrerAddress].primaryMatrix[matrixCode].level][users[referrerAddress].primaryMatrix[matrixCode].position];
            users[userAddress].primaryMatrix[matrixCode].currentReferrer=firstReferrer;
            if(users[firstReferrer].primaryMatrix[matrixCode].levelReferralCount[1] < base) {
                updatePosition(userAddress,firstReferrer, matrixCode);
                if(users[firstReferrer].primaryMatrix[matrixCode].levelReferralCount[1] == base) {
                    updateLevel(referrerAddress, matrixCode);
                }
                break;
            }
            else {
                updateLevel(referrerAddress, matrixCode);
            }
        }
    }
    
    function userSecondaryPlacement(address userAddress, uint8 matrixCode, uint8 matrixLevel, uint8 secondaryMatrixType) private {
        uint8 currentTreeLevel = globalTreeLevel[matrixCode][secondaryMatrixType][matrixLevel];
        address referrerAddress = globalTreePosition[matrixCode][secondaryMatrixType][matrixLevel][currentTreeLevel-1][(globalTreePosition[matrixCode][secondaryMatrixType][matrixLevel][currentTreeLevel].length)/3];
        globalTreePosition[matrixCode][secondaryMatrixType][matrixLevel][currentTreeLevel].push(userAddress);
        emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, secondaryMatrixType+1, matrixCode, uint64(globalTreePosition[matrixCode][secondaryMatrixType][matrixLevel][currentTreeLevel].length-1)%3+1, matrixLevel, users[referrerAddress].premiumReinvestCount[matrixCode][secondaryMatrixType]+1, uint32(block.timestamp));
        
        // For Bonus Matrix Level 2 Rewards
        if(matrixLevel==2 && secondaryMatrixType==1) {
            sendRewards(referrerAddress, matrixCode, 2); 
        }
        
        uint256 positionModulus = globalTreePosition[matrixCode][secondaryMatrixType][matrixLevel][currentTreeLevel].length%3;
        
        if(positionModulus== 0) {
            //Upgrade referrerAddress
            if(referrerAddress!=owner && 
                ((secondaryMatrixType==1 && matrixLevel<2) ||       // Bonus Matrix upgrades max to level 2
                (secondaryMatrixType==2 && ((matrixCode==1 && matrixLevel<5) || ((matrixCode==2||matrixCode==3) && matrixLevel<3))) ||
                (secondaryMatrixType==3 && matrixLevel<3)
            )) {         
                // Upgrade partner to next level 
                userSecondaryPlacement(referrerAddress, matrixCode, matrixLevel+1, secondaryMatrixType);
                if(secondaryMatrixType==1)
                    users[referrerAddress].activeBonusMatrixLevels[matrixCode][matrixLevel+1] = true;
                else if(secondaryMatrixType==2)
                    users[referrerAddress].activeEliteMatrixLevels[matrixCode][matrixLevel+1] = true;
                else 
                    users[referrerAddress].activeBillionaireMatrixLevels[matrixLevel+1] = true;
            }
            
            if(secondaryMatrixType==2 || secondaryMatrixType==3){             
               if((matrixCode==1 && matrixLevel==5) ||((matrixCode==2||matrixCode==3||secondaryMatrixType==3) && matrixLevel==3)) {
                    if(users[referrerAddress].reinvestEligibility[matrixCode][secondaryMatrixType]){
                        users[referrerAddress].premiumReinvestCount[matrixCode][secondaryMatrixType]++;     
                        delete users[referrerAddress].reinvestEligibility[matrixCode][secondaryMatrixType];
                    }
                    sendRewards(referrerAddress, matrixCode, secondaryMatrixType==3? 10: 7);
                }
            } else if(secondaryMatrixType==3 && matrixLevel==3){
                sendRewards(referrerAddress, matrixCode, 10);
            }
            
            
            if(globalTreePosition[matrixCode][secondaryMatrixType][matrixLevel][currentTreeLevel].length==3**uint256(currentTreeLevel)){
                // Updating the tree level
                globalTreeLevel[matrixCode][secondaryMatrixType][matrixLevel] = currentTreeLevel+1;
            }
            
        } else if(secondaryMatrixType==2||secondaryMatrixType==3) {
            if(positionModulus == 1) {
                if((matrixCode==2||matrixCode==3) && matrixLevel==2){
                    // Register in Millionaire/Junior club
                    if(!isRegisteredUser(referrerAddress, 1)) {
                        registration(referrerAddress, users[referrerAddress].referrer, matrixCode-1);
                    } else {
                        users[referrerAddress].eligibility[matrixCode-1] = true;
                    }
                } else if((matrixCode==1 && matrixLevel==5) ||((matrixCode==2||matrixCode==3||secondaryMatrixType==3) && matrixLevel==3)){
                    // Bonus Auto Reinvest
                    users[referrerAddress].reinvestEligibility[matrixCode][secondaryMatrixType]=true;
                    userSecondaryPlacement(referrerAddress, matrixCode, 1, secondaryMatrixType);
                    emit Reinvest(referrerAddress, matrixCode, secondaryMatrixType, matrixLevel, uint32(block.timestamp));
                    // Premium Elite Profits
                    sendRewards(referrerAddress, matrixCode, secondaryMatrixType==3 ? 9: 6);
                    if(matrixCode==1 && secondaryMatrixType==2 && referrerAddress!=owner){
                        users[referrerAddress].eligibility[4]=true;
                    }
                }
                
            } else if(positionModulus == 2) {
                // Premium Elite Profits
                if(matrixCode==1 && matrixLevel>=2 && matrixLevel<5 && secondaryMatrixType!=3) {
                    sendRewards(referrerAddress, matrixCode, matrixLevel+1);
                } else if((matrixCode==1 && matrixLevel==5) ||((matrixCode==2||matrixCode==3||secondaryMatrixType==3) && matrixLevel==3)) {
                    sendRewards(referrerAddress, matrixCode, secondaryMatrixType==3? 10: 7);
                }
            }
        }
    }
        
    function updateLevel(address referrerAddress, uint8 matrixCode) private {
        users[referrerAddress].primaryMatrix[matrixCode].position++;
        if(users[referrerAddress].primaryMatrix[matrixCode].position > base**(users[referrerAddress].primaryMatrix[matrixCode].level)) {
            users[referrerAddress].primaryMatrix[matrixCode].level++;
            users[referrerAddress].primaryMatrix[matrixCode].position = 1;
        }
    }
    
    function updatePosition(address userAddress,address firstReferrer, uint8 matrixCode) private {
        uint8 _level=1;
        uint index;
        uint64 pos;
        address startUser = userAddress;
        while(firstReferrer!= address(0)) {
            users[firstReferrer].primaryMatrix[matrixCode].levelReferralCount[_level]++;
            if(_level == 1){
              pos = users[firstReferrer].primaryMatrix[matrixCode].levelReferralCount[_level];
            }else{
              for(uint64 i = 1;i <= (users[firstReferrer].primaryMatrix[matrixCode].levelReferralCount[1]);i++){
                    if(userAddress==users[firstReferrer].primaryMatrix[matrixCode].levelReferrals[1][i]){
                         index = i;
                    } 
                }
                pos = pos + uint64(3**(uint256(_level)-1)*(index-1));
            }
            if(_level<=3){
              emit NewUserPlace(startUser, users[startUser].id, firstReferrer, 1, matrixCode, pos, _level, 1, uint32(block.timestamp));
            }
            users[firstReferrer].primaryMatrix[matrixCode].levelReferrals[_level][pos] = startUser;
            _level++;
            userAddress = firstReferrer; 
            firstReferrer = users[firstReferrer].primaryMatrix[matrixCode].currentReferrer;   
        }
    }
    
    function userInfo(address userAddress, uint8 matrixCode) public view returns(uint256, bool, bool, bool, bool){
        return (users[userAddress].accumulatedReward[matrixCode], users[userAddress].isActive[matrixCode], users[userAddress].eligibility[4], users[userAddress].eligibility[1], users[userAddress].eligibility[2]);
    }

    function sendRewards(address recipient, uint8 matrixCode, uint8 rewardType) private {
        uint256 rewardAmount;
        if(matrixCode==3){
            rewardAmount = rewards[2][rewardType]/5;
        }
        else {
            rewardAmount = rewards[matrixCode][rewardType];
        }
        if (rewardAmount!=0) {
            if(rewardType==2 && !users[recipient].isActive[matrixCode]){
                users[recipient].accumulatedReward[matrixCode]+=rewardAmount;
            }
            else {
                emit EthPayout(users[recipient].id, matrixCode, rewardType, rewardAmount, uint32(block.timestamp));
                return address(uint160(recipient)).transfer(rewardAmount);
            }
        }
    }
    
    function smartContractBalance() external view returns (uint256) {
        return (address(this).balance);
    }
    
    function adminWithdrawal() external {
        require(msg.sender==owner, "Unauthorized access");
        owner.transfer(address(this).balance);
    }

    function transferManager(address payable managerAddress) external {
        require(msg.sender==manager, "Unauthorized access");
        manager=managerAddress;
    }
    
    // Deposit Fallback
    function() external payable {}

}