// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./DividendPayingToken.sol";
import "./Ownable.sol";
import "./IterableMapping.sol";

contract ScholarDogeDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    
    event WithdrawGasUpdated(uint256 gas);

    constructor()
        DividendPayingToken("$SDOGE_DT", "$SDOGE_Dividend_Tracker")
    {
    	claimWait = 60;// 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }
    
    function updateWithdrawGas(uint256 gas) external onlyOwner {
        require(
            gas > 0, 
            "$SDOGE_DT: <= 0"
        );
        
        withdrawGas = gas;
        
        emit WithdrawGasUpdated(gas);
    }
    
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "$SDOGE_DT: 1h < claimWait < 24h"
        );
        
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        
        claimWait = newClaimWait;
    }
    
    function withdrawDividend() public pure override {
        require(
            false, 
            "$SDOGE_DT: Use claim from $SDOGE"
        );
    }

    function _transfer(address, address, uint256) internal pure override {
        require(
            false,
            "$SDOGE_DT: Can't transfer"
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public 
        view 
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - (int256(lastProcessedIndex));
            } else {
                uint256 processesUntilEndOfArray
                    = tokenHoldersMap.keys.length > lastProcessedIndex ? 
                        tokenHoldersMap.keys.length - lastProcessedIndex :
                        0;

                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
            nextClaimTime - block.timestamp : 0;
    }

    function getAccountAtIndex(uint256 index)
        public
        view 
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
    	if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000, 
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp - lastClaimTime >= claimWait;
    }

    function setBalance(
        address payable account,
        uint256 newBalance
    ) 
        external
        onlyOwner
    {
    	if (excludedFromDividends[account])
    		return;

    	if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	} else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if (numberOfTokenHolders == 0)
    		return (0, 0, lastProcessedIndex);

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
 
    		if (_lastProcessedIndex >= tokenHoldersMap.keys.length)
    			_lastProcessedIndex = 0;

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if (canAutoClaim(lastClaimTimes[account]))
    			if (processAccount(payable(account), true))
    				claims++;

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if (gasLeft > newGasLeft)
    			gasUsed = gasUsed + gasLeft - newGasLeft;

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(
        address payable account,
        bool automatic
    )
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

    	if (amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
    		
            emit Claim(account, amount, automatic);
            
    		return true;
    	}

    	return false;
    }
}