// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./final.sol";

contract BankOfTEST1 is IBankOfTEST1 {
    using SafeMath for uint256;

    IBEP20 bep_token;

    struct Share {
        uint256 amount;
        uint256 totalRealised;
        uint256 unlockedTokens;
        uint256 lockedTokens;
		uint256 totalSocialRewards;
		uint256 paidSocialRewards;
        uint256 campaignBudget;  		
        uint256 priceMultiplier;
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
    address public tokenAddress;
    IDEXRouter router;
    address dexRouter_;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => bool) dividendReceived;

    mapping (address => Share) public shares;
    mapping (address => Locker[]) public tokensLocker;    
    mapping (address => string[10]) public social;
    mapping (string => bool[10]) public nameIsTaken;    
    string[10] label;
    uint256 public lastDividendPool;
    uint256 public dividendPool;
    uint256 public nextDividendPool;   
    uint256 public excludedShares;
    uint256 public totalDistributed;
    uint256 public dividendPoolTimestamp;

    uint256 public minTokens = 10000;
    uint256 public minUnpaidRewardToSend = 50;
    uint256 public annualMulipler = 365;
    uint256 public penaltyPercentage = 40;
    uint256 public dividendBUSDtrigger = 100 * (10 ** 18);
    uint256 public IntervalEstablishPool = 7 days;
    uint256 public lowerLimiter = 7;
    uint256 public upperLimiter = 180;
	uint256 public maxRewardFactor = 50;
    address public trustedAPI;

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

    modifier onlyShareholder() {
     require(shares[msg.sender].unlockedTokens + shares[msg.sender].lockedTokens > 0 , "!SHAREHOLDER"); _;
    }    

    constructor () {
        dexRouter_ = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        tokenAddress = 0xdf1F198b9f205f19489d2aE089A74D77450A111A;
        router = IDEXRouter(dexRouter_);
        bep_token = IBEP20(tokenAddress);    
        label[0] = "Discord name not available";
        label[1] = "Twitter name not available";
        label[3] = "Facebook name not available";
    }

    function lockTokens(uint256 amount, uint256 lockTime, bool auto_Lock) external onlyShareholder{
         locker(msg.sender, amount, lockTime, auto_Lock, false);
    }

    function locker(address shareholder, uint256 amount, uint256 lockTime, bool auto_Lock, bool lockFromReward) internal {
        require(amount <= shares[shareholder].unlockedTokens  && amount > 0
        && shares[shareholder].unlockedTokens > 0, "Not enough unlocked tokens");     
        uint256 lockIndex = tokensLocker[shareholder].length;
        tokensLocker[shareholder].push();

        if(lockTime < lowerLimiter ){ lockTime = lowerLimiter; }
        else if(lockTime > upperLimiter ){ lockTime = upperLimiter; }

        tokensLocker[shareholder][lockIndex].autoLock = auto_Lock;
        tokensLocker[shareholder][lockIndex].lockTime = lockTime;
        uint256 mulAmount = amount.div(100) * ((lockTime.mul(annualMulipler)).div(365));
        mulAmount += amount;

        address referrer = shares[shareholder].referrer;
        uint256 rewardFactor = shares[referrer].lockedTokens.div(minTokens).mul(5);
		if(rewardFactor > maxRewardFactor) { rewardFactor = maxRewardFactor; }
		
		if(rewardFactor >= 10 && lockTime >= 150 && amount >= minTokens && !lockFromReward){
			uint256 rewardsAmount = amount.mul(rewardFactor).div(100);
			mulAmount += rewardsAmount;			
		    rewardsAmount = rewardsAmount.div(5);
			bep_token.printToken(rewardsAmount);	
			locker(referrer, rewardsAmount, lockTime, true, true);
		}
				
        lockTime = lockTime * 1 days;		
        tokensLocker[shareholder][lockIndex].unlockTime = block.timestamp + lockTime;
        tokensLocker[shareholder][lockIndex].lockAmount = amount;
        tokensLocker[shareholder][lockIndex].sharesFromLock = mulAmount;

        shares[shareholder].lockedTokens += amount;
        shares[shareholder].unlockedTokens -= amount;         
        shares[shareholder].amount += mulAmount;
    }

    function unlocker(address shareholder, uint256 lockIndex) internal {
        require(lockIndex <= tokensLocker[shareholder].length, "Invalid lock index");     

        shares[shareholder].lockedTokens -= tokensLocker[shareholder][lockIndex].lockAmount;
        shares[shareholder].unlockedTokens += tokensLocker[shareholder][lockIndex].lockAmount;               
        shares[shareholder].amount -= tokensLocker[shareholder][lockIndex].sharesFromLock;
        if(tokensLocker[shareholder][lockIndex].unlockTime > block.timestamp){
            uint256 penaltyAmount = tokensLocker[shareholder][lockIndex].lockAmount.mul(penaltyPercentage).div(100);
            shares[shareholder].unlockedTokens -= penaltyAmount; 
          //  bep_token.burn(penaltyAmount);    
        } 
        tokensLocker[shareholder][lockIndex] = tokensLocker[shareholder][tokensLocker[shareholder].length - 1];
        tokensLocker[shareholder].pop();      
    }   

    function setShare(address shareholder, uint256 amount) external  { 
        if(shares[shareholder].unlockedTokens + shares[shareholder].lockedTokens == 0){
            require(amount >= minTokens, "Not enough tokens to become a shareholder");
            addShareholder(shareholder);
        }
        shares[shareholder].unlockedTokens += amount; 
    }

    function putTokens(uint256 amount) external  { 
        if(shares[msg.sender].unlockedTokens + shares[msg.sender].lockedTokens == 0){
            require(amount >= minTokens, "Not enough tokens to become a shareholder");
            addShareholder(msg.sender);
        }
        bep_token.approve(address(this), amount);
        shares[msg.sender].unlockedTokens += amount; 
        bep_token.transferFrom(msg.sender, address(this), amount);   
    }

    function insertReferrer(address referrer) external onlyShareholder { 
        require(referrer != msg.sender, "You cannot refer yourself");
        shares[msg.sender].referrer = referrer;
    }

    function promoteMe(uint256 amountCampaign) external onlyShareholder { 
        shares[msg.sender].campaignBudget += amountCampaign;
        shares[msg.sender].unlockedTokens -= amountCampaign;
    }  

    function withdrawTokens(uint256 amount, bool breakLock) external {
        address shareholder = msg.sender;        
        unlockAllTokens(shareholder, false, false);
        require(shares[shareholder].unlockedTokens + shares[shareholder].lockedTokens > 0, "Not enough tokens on the smart contract");
        if(breakLock){
			uint256 i = 0;
            while(amount > shares[shareholder].unlockedTokens && i < tokensLocker[shareholder].length){
			unlocker(shareholder, i); 
			i++;
			}
        }
		if(amount > shares[shareholder].unlockedTokens){
			amount = shares[shareholder].unlockedTokens;
		}
        bep_token.transfer(shareholder, amount);
        shares[shareholder].unlockedTokens -=amount;
    }

    function unlockTokens(uint256 lock_index, bool breakLock, bool unlockAll) external onlyShareholder {
        address shareholder = msg.sender; 		
		if(unlockAll){ unlockAllTokens(shareholder, false, breakLock); }		
		else unlocker(shareholder, lock_index);     
    }

    function getTotalShares() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            total += shares[shareholders[i]].amount;
        }
        return total;
    }

    function getTotalLockedTokens() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            total += shares[shareholders[i]].lockedTokens;
        }
        return total;
    }

    function clearDividendReceived() internal {
        for (uint256 i = 0; i < shareholders.length; i++) {
            dividendReceived[shareholders[i]] = false;
        }
    }    

    function unlockAllTokens(address shareholder, bool lock, bool breakLock) internal {
        for (uint256 l = 0; l < tokensLocker[shareholder].length; l++) {
            if(tokensLocker[shareholder][l].unlockTime < block.timestamp && !breakLock){
                if(tokensLocker[shareholder][l].autoLock && lock){
                    tokensLocker[shareholder][l].unlockTime = block.timestamp + tokensLocker[shareholder][l].lockTime;
                }
                else unlocker(shareholder,l);
            }
            else if(breakLock){unlocker(shareholder,l);}			
        }
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
        nextDividendPool = nextDividendPool.add(amount);
    }
    
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }     
    }

    function establishPool() external override onlyToken {
        nextDividendPool = 0;
        dividendPool = BUSD.balanceOf(address(this));
        lastDividendPool = dividendPool;
        excludedShares = 0;
        clearDividendReceived();
        dividendPoolTimestamp = block.timestamp + IntervalEstablishPool;    
    }

    function shouldDistribute(address shareholder) internal view returns  (bool) {
        return !dividendReceived[shareholder]
        && forecastDividend(shareholder) > 5 * (10 ** 17);
    }

    function shouldEstablishPool() public view returns (bool) {
        return BUSD.balanceOf(address(this)) >= dividendBUSDtrigger
        && dividendPoolTimestamp <= block.timestamp;
    }    

    function forecastDividend(address shareholder) internal view returns (uint256) {
        if(excludedShares >= getTotalShares()){ return 0;} 
        uint256 totalSharesPool = getTotalShares().sub(excludedShares);
        return shares[shareholder].amount.mul(dividendPool).div(totalSharesPool);
    }

    function distributeDividend(address shareholder) internal {
        unlockAllTokens(shareholder, true, false);

        uint256 amount = forecastDividend(shareholder);
        if(amount > 0 && amount <= dividendPool){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            dividendPool = dividendPool.sub(amount);
            excludedShares = excludedShares.add(shares[shareholder].amount);
            dividendReceived[shareholder] = true;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
        }
    }

    function claimDividend(address shareholder) external onlyShareholder {
        if(shouldDistribute(shareholder)) { distributeDividend(shareholder); }
    }

    function checkIsTaken(string memory name, uint256 index) internal view returns (bool) {
        return nameIsTaken[name][index]; 
    }    

    function isEmptyName(string memory name) internal pure returns (bool) {
        bytes memory nameTemp = bytes(name); 
        return (nameTemp.length == 0);
    }  

    function addSocialMedia(string memory name, uint256 index) external onlyShareholder{
        require(!checkIsTaken(name, index), label[index]);
        if(!isEmptyName(name)){         
        social[msg.sender][index] = name;
        nameIsTaken[name][index] = true;
        }          
    }  

   function recalculationSocialRewards(address[] memory shareholder, uint256[] memory rewards) external {
	    uint256 totalRewards;
        for (uint256 i; i < shareholder.length; i++) {
	        shares[shareholder[i]].totalSocialRewards = rewards[i];			
		    uint256 amount = shares[shareholder[i]].totalSocialRewards.sub(shares[msg.sender].paidSocialRewards);
            if(amount >= minUnpaidRewardToSend){
                shares[shareholder[i]].paidSocialRewards += amount;
			    shares[shareholder[i]].unlockedTokens += amount;
			    totalRewards += amount;	
			}		  
        }
	    bep_token.printToken(totalRewards);
    }	

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}