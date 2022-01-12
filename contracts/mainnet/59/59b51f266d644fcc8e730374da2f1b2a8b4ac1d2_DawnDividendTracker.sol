// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
contract DawnDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public constant BASE = 10**18;
    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    mapping (address => bool) public isExcludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    event ExcludeFromDividends(address indexed account, bool exclude);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount);

    constructor() DividendPayingToken("Dawn Dividends","DAWN_D"){
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 860 * BASE; // 0.00088%
        //must buy at least 10M+ tokens to be eligibile for dividends
    }
    // view functions
    function withdrawDividend() public pure override{
        require(false, "disabled, use 'claim' function");
    }
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    function getAccount(address account) external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
            return _getAccount(account);
    }
    function _getAccount(address _account)
        private view returns (
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

        return _getAccount(account);
    }
    // state functions

    // // owner restricted
    function excludeFromDividends(address account, bool exclude) external onlyOwner {
    	require(isExcludedFromDividends[account] != exclude,"already has been set!");
    	isExcludedFromDividends[account] = exclude;
        uint256 bal = IERC20(owner()).balanceOf(account);
        if(exclude){
            _setBalance(account, 0);
    	    tokenHoldersMap.remove(account);
        }else{
            _setBalance(account, bal);
    		tokenHoldersMap.set(account, bal);
        }

    	emit ExcludeFromDividends(account,exclude);
    }
    function updateMinimumForDividends(uint256 amount) external onlyOwner{
        require((amount >= 100 * BASE) && (100000 * BASE >= amount),"should be 1M <= amount <= 10B");
        require(amount != minimumTokenBalanceForDividends,"value already assigned!");
        minimumTokenBalanceForDividends = amount;
    }
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "must be updated 1 to 24 hours");
        require(newClaimWait != claimWait, "same claimWait value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(isExcludedFromDividends[account]) {
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

    	_processAccount(account);
    }

    function processAccount(address payable account) external onlyOwner{
    	uint256 amount = _withdrawDividendOfUser(account);
        emit Claim(account,amount);
    }

    function _processAccount(address payable account) private returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
    		return true;
    	}

    	return false;
    }

    // // public functions
    function process(uint256 gas) external returns (uint256, uint256, uint256) {
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
    			if(_processAccount(payable(account))) {
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

    // private
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
}