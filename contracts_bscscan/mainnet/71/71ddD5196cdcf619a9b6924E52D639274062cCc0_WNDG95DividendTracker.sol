// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./RewardsPayingToken.sol";
import "./Ownable.sol";
import "./IterableMapping.sol";

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract WNDG95DividendTracker is Ownable, RewardsPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    using Address for address payable;

    IterableMapping.Map private tokenHoldersMap;
    
    address public token;
    address public marketingContract;
    
    bool public rewardsEnabled;
    
    uint256 rewardsPart = 50;
    uint256 marketingPart = 50;
    
    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;
    
    uint256 public lastProcessedIndex;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    uint256 gasForProcessing = 300000;


    event ExcludeFromDividends(address indexed account, bool value);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event ProcessedDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(address tokenAdd, address _marketingContract)  RewardsPayingToken("WNDG95_Dividen_Tracker", "WNDG95_Dividend_Tracker", tokenAdd) {
        token = tokenAdd;
        marketingContract = _marketingContract;
    	claimWait = 3600;
    	minimumTokenBalanceForDividends = 1000 * (10**9); //must hold 10000 tokens
    }
    
    receive() external payable {
        forwardFunds(msg.value * marketingPart / 100);
        if(rewardsEnabled){
          distributeDividends(msg.value * rewardsPart / 100);
          process(gasForProcessing);
        }
    }
    
    function setMinimumTokenBalance(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount;
    }
    
    function rescueBEP20(address tokenAdd, uint256 amount) external onlyOwner{
        require(IERC20(tokenAdd).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(tokenAdd).transfer(owner(), amount);
    }
    
    function rescueBNB(uint256 amount) external onlyOwner{
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }
    
    function setGasForProcessing(uint256 gas) external onlyOwner{
        gasForProcessing = gas;
    }
    
    function setRewardsEnabled(bool enabled) external onlyOwner{
        rewardsEnabled = enabled;
    }
    
    function setTokenAdd(address newToken) external onlyOwner{
        token = newToken;
    }
    
    function setMarketingContract(address newContract) external onlyOwner{
        marketingContract = newContract;
    }
    
    function setParts(uint256 _rewards, uint256 _marketing) external onlyOwner{
        rewardsPart = _rewards;
        marketingPart = _marketing;
    }
    
    function forwardFunds(uint256 weiAmount) internal{
        payable(marketingContract).sendValue(weiAmount);
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "WNDG95_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(rewardsEnabled, "Rewards not enabled");
        _updateBalance(msg.sender);
        require(block.timestamp.sub(lastClaimTimes[msg.sender]) >= claimWait, "You must wait claimWait");
		processAccount(msg.sender, false);
    }

    function excludeFromDividends(address account, bool value) external onlyOwner {
    	require(excludedFromDividends[account] != value);
    	excludedFromDividends[account] = value;
      if(value == true){
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
      }
      else{
        _setBalance(account, balanceOf(account));
        tokenHoldersMap.set(account, balanceOf(account));
      }
      emit ExcludeFromDividends(account, value);

    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "WNDG95_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "WNDG95_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
    
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
    
    function updateBalance() external{
        _updateBalance(msg.sender);
    }
    
    function _updateBalance(address account) internal {
        uint256 newBalance = IERC20(token).balanceOf(account);
        if(excludedFromDividends[account]) {
    		return;
    	}
    	
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        require(rewardsEnabled, "Rewards not enabled");
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(account, true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address account, bool automatic) internal returns (bool) {
        _updateBalance(account);
        uint256 amount = _withdrawDividendOfUser(payable(account));

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}