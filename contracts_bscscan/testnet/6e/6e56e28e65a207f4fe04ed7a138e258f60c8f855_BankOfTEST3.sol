// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./final.sol";

contract BankOfTEST3 is IBankOfTEST3 {
    using SafeMath for uint256;
    IBEP20 bep_token;

    struct BankAccount {
        uint256 amount;
        uint256 totalRealised;
        uint256 unlockedTokens;
        uint256 unpaidDividend;
        uint256 lockedTokens;
		uint256 unpaidSocialRewards;
		uint256 totalPaidSocialRewards;
		address referrer;
    }

    struct Locker {
        uint256 sharesFromLock;		
        uint256 lockAmount;
        uint256 unlockTime;
        uint256 lockTime;
        bool autoLock;
    }

    IBEP20 BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public tokenAddress = 0x847Ea07Aca6562A4E2FFF23EFa62c921166c16b3;
    address DATAPROVIDER;
    address owner;
    IDEXRouter router;
    address dexRouter_;

    address[] public clients;
    mapping (address => uint256) clientIndexes;

    mapping (address => BankAccount) public shares;
    mapping (address => Locker[]) public tokensLocker;    
    mapping (address => string[10]) public social;
    mapping (string => bool[10]) nameIsTaken;    
    string[10] label;
    uint256 totalSharesPool;
    uint256 public dividendPool;
    uint256 public totalDistributed;
    uint256 public dividendPoolTimestamp;

    uint256 public minTokens = 500 * (10 ** 18);
    uint256 public minUnpaidRewardToSend = 50;
    uint256 public annualShareMultiplier = 365;
    uint256 public penaltyPercentage = 40;
    uint256 public rewardFactor = 30;
    uint256 public dividendBUSDtrigger = 1 * (10 ** 18);
    uint256 public IntervalEstablishPool = 1 days;
    uint256 public lowerLimiter = 7;
    uint256 public upperLimiter = 365;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
       require(msg.sender == address(bep_token)); _;
    }

    modifier onlyClient() {
     require(shares[msg.sender].unlockedTokens + shares[msg.sender].lockedTokens > minTokens , "You are not a client"); _;
    }    

    constructor () {
        owner = msg.sender;
        dexRouter_ = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        DATAPROVIDER = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        router = IDEXRouter(dexRouter_);
        bep_token = IBEP20(tokenAddress);    
    }

    modifier onlyDATAPROVIDER() {
       require(msg.sender == DATAPROVIDER, "!DATAPROVIDER"); _;
    }

    modifier onlyOwner() {
       require(msg.sender == owner, "!OWNER"); _;
    } 

    function lockTokens(uint256 amount, uint256 lockTime, bool auto_Lock) external onlyClient{
        require(amount <= shares[msg.sender].unlockedTokens  && amount > 0
        && shares[msg.sender].unlockedTokens > 0, "Not enough unlocked tokens");     
         locker(msg.sender, amount, lockTime, auto_Lock, false);
    }

    function locker(address client, uint256 amount, uint256 lockTime, bool auto_Lock, bool lockFromReward) internal {
        uint256 lockIndex = tokensLocker[client].length;
        tokensLocker[client].push();

        if(lockTime < lowerLimiter ){ lockTime = lowerLimiter; }
        else if(lockTime > upperLimiter ){ lockTime = upperLimiter; }

        tokensLocker[client][lockIndex].autoLock = auto_Lock;
        tokensLocker[client][lockIndex].lockTime = lockTime;
        uint256 mulAmount = amount.div(100) * ((lockTime.mul(annualShareMultiplier)).div(365));
        mulAmount += amount;

        address referrer = shares[client].referrer;
		
		if(lockTime >= 150 
        && amount >= minTokens 
        && !lockFromReward 
        && bep_token.shouldPrintTokens() 
        && shares[referrer].lockedTokens >= minTokens.mul(5)){
			uint256 rewardAmount = amount.mul(rewardFactor).div(100);
            locker(referrer, rewardAmount.div(2), lockTime, true, true);
            locker(client, rewardAmount.div(2), lockTime, true, true);
            bep_token.printToken(rewardAmount);  
		}
				
        lockTime = lockTime * 1 days;		
        tokensLocker[client][lockIndex].unlockTime = block.timestamp + lockTime;
        tokensLocker[client][lockIndex].lockAmount = amount;
        tokensLocker[client][lockIndex].sharesFromLock = mulAmount;

        shares[client].lockedTokens += amount;
        shares[client].unlockedTokens -= amount;         
        shares[client].amount += mulAmount;
    }

    function unlocker(address client, uint256 lockIndex) internal {
        require(lockIndex <= tokensLocker[client].length, "Invalid lock index");     

        shares[client].lockedTokens -= tokensLocker[client][lockIndex].lockAmount;
        shares[client].unlockedTokens += tokensLocker[client][lockIndex].lockAmount;               
        shares[client].amount -= tokensLocker[client][lockIndex].sharesFromLock;
        if(tokensLocker[client][lockIndex].unlockTime > block.timestamp){
            uint256 penaltyAmount = tokensLocker[client][lockIndex].lockAmount.mul(penaltyPercentage).div(100);
            shares[client].unlockedTokens -= penaltyAmount; 
            bep_token.burn(penaltyAmount);    
        } 
        tokensLocker[client][lockIndex] = tokensLocker[client][tokensLocker[client].length - 1];
        tokensLocker[client].pop();      
    }   

    function depositToBank(address client, uint256 amount) external { 
        if(shares[client].unlockedTokens + shares[client].lockedTokens == 0){
            require(amount >= minTokens, "Not enough tokens to become a client");
            addclient(client);
        }
        shares[client].unlockedTokens += amount; 
    }

    function insertReferrer(address referrer) external onlyClient { 
        require(referrer != msg.sender, "You cannot refer yourself");
        shares[msg.sender].referrer = referrer;
    }

    function withdrawTokens(uint256 amount, bool breakLock) external onlyClient {
        address client = msg.sender;        
        unlockAllTokens(client, false, false);
        if(breakLock){
			uint256 i = 0;
            while(amount > shares[client].unlockedTokens && i < tokensLocker[client].length){
			unlocker(client, i); 
			i++;
			}
        }
		if(amount > shares[client].unlockedTokens){
			amount = shares[client].unlockedTokens;
		}
        //bep_token.transfer(client, amount);
        shares[client].unlockedTokens -=amount;
    }

    function unlockTokens(uint256 lock_index, bool breakLock, bool unlockAll) external onlyClient {
        address client = msg.sender; 		
		if(unlockAll){ unlockAllTokens(client, false, breakLock); }		
		else unlocker(client, lock_index);     
    }

    function getTotalShares() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < clients.length; i++) {
            total += shares[clients[i]].amount;
        }
        return total;
    }

    function getTotalLockedTokens() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < clients.length; i++) {
            total += shares[clients[i]].lockedTokens;
        }
        return total;
    }

    function unlockAllTokens(address client, bool lock, bool breakLock) internal {
        for (uint256 l = 0; l < tokensLocker[client].length; l++) {
            if(tokensLocker[client][l].unlockTime < block.timestamp && !breakLock){
                if(tokensLocker[client][l].autoLock && lock){
                    tokensLocker[client][l].unlockTime = block.timestamp + tokensLocker[client][l].lockTime;
                }
                else unlocker(client,l);
            }
            else if(breakLock){unlocker(client,l);}			
        }
    }

    function bankSettings(
        uint256 _minTokens,
        uint256 _minUnpaidRewardToSend,
        uint256 _annualShareMultiplier,
        uint256 _penaltyPercentage,
        uint256 _dividendBUSDtrigger,
        uint256 _IntervalEstablishPool,
        uint256 _lowerLimiter,
        uint256 _upperLimiter,
    	uint256 _rewardFactor
    ) external onlyOwner {
         minTokens = _minTokens * (10 ** 18);
         minUnpaidRewardToSend = _minUnpaidRewardToSend;
         annualShareMultiplier = _annualShareMultiplier;
         penaltyPercentage = _penaltyPercentage;
         dividendBUSDtrigger = _dividendBUSDtrigger * (10 ** 18);
         IntervalEstablishPool = _IntervalEstablishPool * 1 days;
         lowerLimiter = _lowerLimiter;
         upperLimiter = _upperLimiter;
    	 rewardFactor = _rewardFactor;
    }

    function setSocialAccountLabel(uint256 index, string memory _label) external onlyOwner {
        label[index] = _label;
    }    

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);
        dividendPool = dividendPool.add(amount);
    }
    
    function process(uint256 gas) external override onlyToken onlyDATAPROVIDER {
        uint256 clientCount = clients.length;
        if(clientCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < clientCount) {
            if(currentIndex >= clientCount){
                currentIndex = 0;
            }
            distributeDividend(clients[currentIndex]);
            
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }     
    }

    function establishPool() external override onlyToken {
        totalSharesPool = getTotalShares();
        if(shouldEstablishPool()){
            for (uint256 i = 0; i < clients.length; i++) {
                unlockAllTokens(clients[i], true, false);
                shares[clients[i]].unpaidDividend += forecastDividend(clients[i]);
            }
            dividendPool = 0;
            dividendPoolTimestamp = block.timestamp + IntervalEstablishPool;    
        }
    }

    function shouldEstablishPool() internal view returns (bool) {
        return totalSharesPool > 0
        && dividendPool >= dividendBUSDtrigger
        && dividendPoolTimestamp <= block.timestamp;
    }    

    function forecastDividend(address client) internal view returns (uint256) {
        if(shares[client].amount == 0){ return 0; }
        return shares[client].amount.mul(dividendPool).div(totalSharesPool);
    }

    function distributeDividend(address client) internal {
        uint256 amount = shares[client].unpaidDividend;
        if(amount > 0 && BUSD.balanceOf(address(this)) > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(client, amount);
            shares[client].unpaidDividend = 0;
            shares[client].totalRealised = shares[client].totalRealised.add(amount);
        }
    }

    function distributeSocialReward(address client) internal {
        if(bep_token.shouldPrintTokens()){
            uint256 amount = shares[client].unpaidSocialRewards;
            if(amount > minUnpaidRewardToSend){
                shares[client].unpaidSocialRewards = 0;
                shares[client].totalPaidSocialRewards += amount;
                shares[client].unlockedTokens += amount;
                bep_token.printToken(amount);
            }
        }
    }

    function claimDividend() external onlyClient {
        distributeDividend(msg.sender); 
    }

    function claimSocialReward() external onlyClient {
        distributeSocialReward(msg.sender);
    }

    function checkIsTaken(string memory name, uint256 index) internal view returns (bool) {
        return nameIsTaken[name][index]; 
    }    
 
    function addSocialMedia(string memory name, uint256 index) external onlyClient{
        require(!checkIsTaken(name, index), label[index]);
        if(bytes(name).length > 0){
            social[msg.sender][index] = name;
            nameIsTaken[name][index] = true;
        }
    }  

   function recalculationSocialRewards(address[] memory client, uint256[] memory amount) external onlyDATAPROVIDER{
        for (uint256 i; i < client.length; i++) {		
	        shares[client[i]].unpaidSocialRewards = amount[i];        
            }
    }	

    function addclient(address client) internal {
        clientIndexes[client] = clients.length;
        clients.push(client);
    }

    function removeclient(address client) internal {
        clients[clientIndexes[client]] = clients[clients.length-1];
        clientIndexes[clients[clients.length-1]] = clientIndexes[client];
        clients.pop();
    }
}