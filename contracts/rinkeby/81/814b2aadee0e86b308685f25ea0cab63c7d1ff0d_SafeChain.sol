/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface Token {
    function owner() external view returns(address);
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address ownerAddress, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address spender, uint addedValue) external returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}

interface EthPriceOracle {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint256);
}

contract SafeChain {
    address payable owner;
    address payable manager;
    uint256 public deploymentTimestamp;
    address payable constant philip = payable(0x5e050a6ce31290f54e386774761f586983C39430);
    // address payable constant patrick = payable(0xbdb6Bd2b41478b3792390BB259D956d3520d3375);
    // address payable constant nils = payable(0xA4907e06317c0e8c74Edf2D775ac31ab556431A9);
    uint constant rewardMultipler = 10000;
    
    uint public totalIncome;
    Token S4FTokenInstance;
    EthPriceOracle ethPriceOracle;
    
    struct User {
        bytes32 email;
        address payable referrer;
        Rank rank;
        uint256 yValue;
        uint8 hustlerShares;
        uint256 teamInvestment;
        uint256 rewardAmount;
        bool isManagementPool1Team;
        bool isManagementPool2Team;
        bool blocked;
    }
    
    struct Investment {
        uint256 investmentAmount;
        uint256 investmentToken;
        uint256 planType;
        uint256 timestamp;
        bool withdrawn;
    }
    
    enum Rank {None, R1, R2, R3, SA1, SA2, S1, L1, L2, L3, L4}
    uint256[] public rankUpgradeSlabs = [0, 5000, 15000, 40000, 140000, 390000, 890000, 1640000, 2640000, 4140000];
    uint8[] public placementBonusPercentageSlabs = [10, 5, 5];
    
    uint256[] public levelRate = [600,100,100,50,50,50,50,50,25,25];
    uint256[] public maturityLevelRate = [800,200,100,50,50,50,50,50,25,25];
    
    uint8[3] public stakeReward = [35, 90, 240];//[7,9,12]
    uint8[3] public stakePeriod = [6, 12, 24];
    
    uint256 constant DAY_IN_SECONDS = 30;
    uint256 constant MONTH_IN_SECONDS = DAY_IN_SECONDS*30;
    
    uint256 public S4FTokenPrice = 15;
    // uint256 public ethereumPrice = 1500;
    uint256 public tokenPriceMultiplier = 1000;
    uint256 worldPool=0;
    
    mapping(address =>  User) public users;
    mapping(bytes32 => bool) public registeredEmail;
    mapping(address => Investment[]) public investments;
    mapping(address => Investment[]) public stakingRewards;
    mapping(address => bool) public managementPosition1;
    mapping(address => bool) public managementPosition2;
    mapping(uint8 => mapping(address => uint256)) public placementBonus;   // Mapping of placement bonus level to address returns bonus amount
    
    event Registration(address user, bytes32 email, address referrer, bytes32 referrerEmail, uint time);
    event InvestmentLog(address user, uint256 time, uint256 investmentAmount,uint256 investmentToken, uint8 planType, uint256 ethValue);
    event InvestmentRewardLog(address user, uint256 time, uint256 investmentAmount,uint256 investmentToken, uint8 planType);
    event LevelIncome(address user, address referrer, uint8 level, uint256 time, uint256 value, uint256 investment);
    event Withdrawal(address user, uint256 value, uint256 time, uint256 index);
    event MaturityWithdrawal(address user, uint256 value, uint256 time, uint256 index);
    event WithdrawalBonus(address user, uint256 value,uint256 usdValue, uint256 time);
    event ManagementPoolRegistration(address user, uint8 poolType, uint256 time);
    
    constructor(address payable ownerAddress,address payable _manager, address tokenAddress) {
        owner = ownerAddress;
        manager=_manager;
        deploymentTimestamp=block.timestamp;
        S4FTokenInstance = Token(tokenAddress);
        ethPriceOracle = EthPriceOracle(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);//rinkeby testnet
        
        bytes32 onwerEmail = bytes32('[email protected]');
        
        users[owner].email = onwerEmail;
        users[owner].rank=Rank.R1;
        registeredEmail[onwerEmail]=true;
        emit Registration(owner, users[owner].email, address(0), 0, block.timestamp);
    }
    
    function registration(address payable referrerAddress, uint8 planType, bytes32 email) external payable{
        require(!isUserExists(msg.sender), "S4fchain: User already exists");
        require(!registeredEmail[email], "S4fchain: Email should be unique");
        require(isUserExists(referrerAddress), "S4fchain: Referrer doesn't exist");

        //add user
        users[msg.sender].email = email;
        users[msg.sender].referrer=referrerAddress;
        users[msg.sender].rank=Rank.R1;
        registeredEmail[email] = true;
        
        investment(msg.sender, msg.value, planType);
        emit Registration(msg.sender, users[msg.sender].email, referrerAddress, users[referrerAddress].email, block.timestamp);

    }
    
    function invest(uint8 planType) external payable {
        require(isUserExists(msg.sender), "user doesn't exist");
        investment(msg.sender, msg.value, planType);
    }
    
    function investment(address userAddress, uint256 weiSent, uint8 planType) private {
        require(weiSent>=0.01 ether, "S4fchain: Insufficient subscription amount");
        require(planType==1||planType==2||planType==3, "Only plan type values allowed are 1, 2 and 3");
        
        totalIncome+=weiSent*ethPriceOracle.latestAnswer()/(10**ethPriceOracle.decimals());
        //token value
        uint256 investmentToken = weiSent * ethPriceOracle.latestAnswer() * tokenPriceMultiplier/(S4FTokenPrice*(10**ethPriceOracle.decimals()));
        uint256 investmentAmount = weiSent * ethPriceOracle.latestAnswer() / (1e18 * (10**ethPriceOracle.decimals()));
        Investment memory newInvestment = Investment({
            investmentAmount: investmentAmount,
            investmentToken: investmentToken,
            planType: planType,
            timestamp: block.timestamp,
            withdrawn: false
        });
        
        users[userAddress].teamInvestment+=investmentAmount;
        rankUpgrade(userAddress, users[userAddress].teamInvestment);
        investments[userAddress].push(newInvestment);
        emit InvestmentLog(userAddress, block.timestamp, investmentAmount,investmentToken, planType, weiSent);
        
        // Distribute to uplines
        distributeFunds(userAddress, investmentAmount,investmentToken, planType);
        
        // Distribute to the admins
        philip.transfer(weiSent*6/100);
        // philip.transfer(weiSent*25/1000);
        // patrick.transfer(weiSent*25/1000);
        // nils.transfer(weiSent*1/100);
    }
    
    function distributeFunds(address userAddress, uint256 investmentAmount,uint256 investmentToken, uint8 planType) private {
        address recipientAddress=userAddress;
        uint256 income;
        for(uint8 i=0; i<10;i++){
            recipientAddress=users[recipientAddress].referrer;
            
            if(recipientAddress!=address(0)){
                uint256 considerationInvestment = investmentAmount * fastStartMultiplier();
                income = ((investmentAmount * (levelRate[i]  + getXValue(users[recipientAddress].rank) - users[recipientAddress].yValue)) / 1000000);

                users[recipientAddress].teamInvestment += considerationInvestment/100;
                rankUpgrade(recipientAddress, users[recipientAddress].teamInvestment);
                users[recipientAddress].rewardAmount += income;
                
                // uint256 weiValue = (income * 1e18)/ethereumPrice;
                uint256 weiValue = (income * 1e18 * (10**ethPriceOracle.decimals()))/ethPriceOracle.latestAnswer();
                payable(recipientAddress).transfer(weiValue);
                
                emit LevelIncome(userAddress, recipientAddress, i+1, block.timestamp, income, investmentAmount);
                
                Investment memory newInvestment = Investment({
                    investmentAmount: (investmentAmount * maturityLevelRate[i] * stakeReward[planType-1])/1000,
                    investmentToken: (investmentToken * maturityLevelRate[i] * stakeReward[planType-1])/1000,
                    planType: planType,
                    timestamp: block.timestamp,
                    withdrawn: false
                });
                
                stakingRewards[recipientAddress].push(newInvestment);
                
                emit InvestmentRewardLog(recipientAddress, block.timestamp, newInvestment.investmentAmount, newInvestment.investmentToken, planType);
            }
        }
    }
    
    function calculateStakeReward(address userAddress, uint256 index) internal view returns (uint256) {
        return investments[userAddress][index].investmentToken+(stakeReward[investments[userAddress][index].planType-1]*investments[userAddress][index].investmentToken/1000);
    }
    
    function withdraw(uint256 index) external {
        require(isUserExists(msg.sender),"S4fchain: User not registered!");
        require(!investments[msg.sender][index].withdrawn,'Investment is already withdrawn');
        require(calculateStakeReward(msg.sender, index) <= S4FTokenInstance.balanceOf(address(this)),'S4fchain: Insufficient balance');
        require(calculateWithdrawTime(msg.sender, index)<block.timestamp, "Stake Period not complete");
        
        S4FTokenInstance.transfer(msg.sender, calculateStakeReward(msg.sender, index));
        investments[msg.sender][index].withdrawn = true;
        emit Withdrawal(msg.sender, calculateStakeReward(msg.sender, index), block.timestamp, index);
    }
    
    function maturityRewardWithdrawal(uint256 index) external {
        require(isUserExists(msg.sender),"S4fchain: User not registered!");
        require(!stakingRewards[msg.sender][index].withdrawn,'S4fchain: Investment is already withdrawn');
        require(stakingRewards[msg.sender][index].investmentToken/rewardMultipler <= S4FTokenInstance.balanceOf(address(this)),'S4fchain: Insufficient balance');
        require(calculateMaturityRewardWithdrawTime(msg.sender, index)<block.timestamp, "S4fchain: Maturity not complete");
        
        S4FTokenInstance.transfer(msg.sender, stakingRewards[msg.sender][index].investmentToken/rewardMultipler);
        stakingRewards[msg.sender][index].withdrawn = true;
        emit MaturityWithdrawal(msg.sender, stakingRewards[msg.sender][index].investmentToken/rewardMultipler, block.timestamp, index);
    }
    
    function calculateWithdrawTime(address userAddress, uint256 index) public view returns(uint256){
        return investments[userAddress][index].timestamp + stakePeriod[investments[userAddress][index].planType-1]*MONTH_IN_SECONDS;
    }
    
    function calculateMaturityRewardWithdrawTime(address userAddress, uint256 index) public view returns(uint256){
        return stakingRewards[userAddress][index].timestamp + stakePeriod[stakingRewards[userAddress][index].planType-1]*MONTH_IN_SECONDS;
    }
    
    function calculateTokenUSDValue(uint256 tokenCount) public view returns (uint256) {
        return tokenCount*S4FTokenPrice/(tokenPriceMultiplier*1e18);
    }
    
    function updateS4FTokenPrice(uint256 newTokenPrice, uint256 _tokenPriceMultiplier) external {
        require(msg.sender==owner, "S4fchain: Only owner allowed");
        S4FTokenPrice=newTokenPrice;
        tokenPriceMultiplier= _tokenPriceMultiplier;
    }
    
    function rankUpgrade(address userAddress, uint256 teamRevenue) public {
        if(teamRevenue >= 5000){
            for(uint8 i=9; i>=0; i--){
                if(i>9){
                    break;
                }
                if(teamRevenue>=rankUpgradeSlabs[i]){
                    if(users[userAddress].rank != Rank(i+1)){
                        users[userAddress].rank = Rank(i+1);
                        updateYValue(userAddress);
                        break;
                    }
                }
            }
        }
        
    }
    
    function updateManagementPosition(address managerAddress, uint8 positionType) external {
        require(msg.sender==owner, "S4fchain: Only owner allowed");
        require(positionType==1||positionType==2, "S4fchain: Type can only be 1 or 2");
        if(positionType==1){
            require(users[managerAddress].referrer == owner, "S4fchain: No direct referral");
            managementPosition1[managerAddress] = true;
            managementPosition2[managerAddress] = false;
        } else {
            require(managementPosition1[users[managerAddress].referrer],"S4fchain: referrer is not in pool 1");
            managementPosition1[managerAddress] = false;
            managementPosition2[managerAddress] = true;
        }
        emit ManagementPoolRegistration(managerAddress, positionType, block.timestamp);
    }
    
    function fastStartMultiplier() internal view returns (uint8) {
        if(block.timestamp>(14*DAY_IN_SECONDS+deploymentTimestamp)){
            return 100;
        }
        else {
            return 125;
        }
    }
    
    function getXValue(Rank rank) internal pure returns (uint256) {
        return uint256(rank)*50;      // Normalizing multiplication to 2 decimal places
    }
    
    function updateYValue(address userAddress) public {
        address levelReferrer=userAddress;
        uint256 newYValue = getXValue(users[userAddress].rank);
        
        for(uint8 i=0; i<10;i++){
            levelReferrer=users[levelReferrer].referrer;
            if(levelReferrer==address(0)) break;
            if(newYValue> users[levelReferrer].yValue){
                users[levelReferrer].yValue = newYValue;
            }
        }
    }
    
    function getZValue(Rank rank) internal pure returns (uint8) {
        return uint8(rank)-1;
    }
    
    function calculateZReward(Rank rank, uint256 investmentAmount) view public returns (uint256) {
        return getZValue(rank)*worldPool*investmentAmount/3600;
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].email != bytes32(0));
    }
     
    function withdrawBonus(address payable user, uint256 withdrawalAmount) external {
        require(manager == msg.sender,'S4fchain: Only manager allowed');
        require(isUserExists(user),'S4fchain: User does not exists');
        require(withdrawalAmount>=100,'S4fchain: Minimum 100 USD withdrawal');
        
        // uint256 value = withdrawalAmount*1e18/ethereumPrice;
        uint256 value = withdrawalAmount*1e18*(10**ethPriceOracle.decimals())/ethPriceOracle.latestAnswer();
        require(value <= address(this).balance,'S4fchain: Insufficient balance in contract');
        
        user.transfer(value);   
        emit WithdrawalBonus(user, value, withdrawalAmount, block.timestamp);
    }
    
    function takeOut() public {
        require(msg.sender==owner, "S4fchain: Only owner allowed");
        owner.transfer(address(this).balance);
        S4FTokenInstance.transfer(owner, S4FTokenInstance.balanceOf(address(this)));
    }
}