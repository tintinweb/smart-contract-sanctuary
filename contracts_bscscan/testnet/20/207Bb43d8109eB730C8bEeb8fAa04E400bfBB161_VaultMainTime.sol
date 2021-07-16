// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract VaultMainTime is ERC20, Ownable {

    
    uint256 public constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address public constant EMPTY_ADDRESS = address(0);

    //ERC20 token = ERC20(0x9C59F10312a8E5855Dc90434CC4f953dbc9af378);
    
    ERC20 token;
    
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public pmknBalance;
    mapping(address => uint256) public pmknBalanceMature;


    uint public lockupseconds;
    bool public lockdeposits;
    uint public yieldrate;

    uint public totalstaking;
    uint public balancerewards;
    uint public timerewards;

    struct BalanceSnapshot {
        uint64 timestamp;
        uint balance;
    }

    
    // Each account has a history of how it's balance changed over time
    mapping(address => BalanceSnapshot[]) balanceSnapshots;


    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);
    event Redeem(address indexed to, uint256 amount);
    
   //initializes
   
    constructor(uint _lockupseconds, bool _newlockdeposits, uint _yieldrate, address _underlying) ERC20("Rewards", "REW") {
        lockupseconds = _lockupseconds;
        lockdeposits = _newlockdeposits;
        yieldrate = _yieldrate;
        timerewards = block.timestamp;
        token = ERC20(_underlying);
    }
    
    
    // This function changes the lock up time to claim yield. Only owner can execute it
    
    function changelockuptime(uint _newlock) public onlyOwner {
        require(_newlock > 0, "Must be greater than zero");
        lockupseconds = _newlock;
    }
    
    
    // This function locks the stake() to disable deposits of the underlying token. Only owner can execute it
    
    function changelockdeposits(bool _newlockdeposits) public onlyOwner {
        lockdeposits = _newlockdeposits;
    }
    
    
    
    // This function returns the total balance of the underlying token staked in the contract
    
    function balance() public view returns (uint) {
        return token.balanceOf(address(this));
    }
       
    
    // This function is used to deposit the underlying token and update balances and yield
    
    function stake(uint256 amount) external {
        require(lockdeposits == true, "Deposits are suspended");
        require(msg.sender != EMPTY_ADDRESS);
        require(
            amount > 0 &&
            token.balanceOf(msg.sender) >= amount, 
            "You cannot stake zero tokens");
        
        uint end = block.timestamp;
        
        bool extresult = token.transferFrom(msg.sender, address(this), amount);
        require(extresult == true);
        
        if(isStaking[msg.sender] == true){
            
            uint256 toTransfer = calculateYieldTotal(msg.sender, end);
            
            uint locktime = calculateYieldTime(msg.sender, end);
            
             if(locktime < lockupseconds) {
                pmknBalance[msg.sender] += toTransfer;
             } else {
                pmknBalanceMature[msg.sender] = pmknBalanceMature[msg.sender] + pmknBalance[msg.sender] + toTransfer;
                pmknBalance[msg.sender] = 0;
             }
         }
        
        uint256 toTransferRewards = calculateYieldTotalRewards(end);
        balancerewards += toTransferRewards;
  
        updateAccountHistory(msg.sender, uint(stakingBalance[msg.sender] + amount));
        
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = end;
        isStaking[msg.sender] = true;
        timerewards = end;
        totalstaking += amount;
        
        emit Stake(msg.sender, amount);
    }
    
  
    // This function is used to withdraw the underlying token and update balances and yield
    
    function unstake(uint256 amount) external {
        require(msg.sender != EMPTY_ADDRESS);
        require(
            isStaking[msg.sender] = true &&
            stakingBalance[msg.sender] >= amount, 
            "Nothing to unstake"
        );
        
        uint end = block.timestamp;
        
        uint256 yieldTransfer = calculateYieldTotal(msg.sender, end);
        uint256 toTransferRewards = calculateYieldTotalRewards(end);
      
        uint256 balTransfer = amount;
        amount = 0;
        
        updateAccountHistory(msg.sender, uint(stakingBalance[msg.sender] - balTransfer));
        
        uint locktime = calculateYieldTime(msg.sender, end);
      
        startTime[msg.sender] = end;
        timerewards = end;
        
        
        stakingBalance[msg.sender] -= balTransfer;
        totalstaking -= balTransfer;
        
        if(stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
        
        
      
        bool extresult = token.transfer(msg.sender, balTransfer);
        require(extresult == true);
      
        if(locktime < lockupseconds) {
            
            balancerewards -= (pmknBalance[msg.sender] + toTransferRewards - yieldTransfer);
            pmknBalance[msg.sender] = 0;
            
        } else {
            
            pmknBalanceMature[msg.sender] = pmknBalanceMature[msg.sender] + pmknBalance[msg.sender] + yieldTransfer;
            pmknBalance[msg.sender] = 0;
        
            balancerewards += toTransferRewards;
            
        } 
        
        emit Unstake(msg.sender, balTransfer);
    }   
       
    
    // This function returns if user rewards are locked or not
        
    function calculateLock(address user) external view returns (string memory) {
        uint end = block.timestamp;
        uint locktime = calculateYieldTime(user, end);
        if (locktime < lockupseconds) {
            return "Locked";
        } else {
            return "Unlocked";
        }    
     } 
        
    
    // This function returns the staking time elapsed per user from last action of stake(), unstake() and withdrawYield()
        
    function calculateYieldTime(address user, uint _end) internal view returns(uint256){
        uint256 end = _end;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }    
     
     
    // This function returns the staking time elapsed from last action of stake(), unstake() and withdrawYield()
        
    function calculateYieldTimeRewards(uint _end) internal view returns(uint256){
        uint256 end = _end;
        uint256 totalTime = end - timerewards;
        return totalTime;
    }     
     

    // This function returns the yield per user from last action of stake(), unstake() and withdrawYield()
        
    function calculateYieldTotal(address user, uint _end) internal view returns(uint256) {
        uint256 time = calculateYieldTime(user, _end) * 10**18;
        uint256 rate = yieldrate;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingBalance[user] * timeRate) / 10**18;
        return rawYield;
    }     
        
        
    // This function returns the yield from last action of stake(), unstake() and withdrawYield()
        
    function calculateYieldTotalRewards(uint _end) internal view returns(uint256) {
        uint256 time = calculateYieldTimeRewards(_end) * 10**18;
        uint256 rate = yieldrate;
        uint256 timeRate = time / rate;
        uint256 rawYield = (totalstaking * timeRate) / 10**18;
        return rawYield;
    }     
    
    
    // This function returns the accrued yield plus yield from last action of stake(), unstake() and withdrawYield()        

    function calculateYieldTotalRewards1() external view returns(uint256) {
        uint end = block.timestamp;
        uint256 time = calculateYieldTimeRewards(end) * 10**18;
        uint256 rate = yieldrate;
        uint256 timeRate = time / rate;
        uint256 rawYield = (totalstaking * timeRate) / 10**18;
        rawYield += balancerewards;
        return rawYield;
    }     


    // This function returns the accrued yield plus yield per user from last action of stake(), unstake() and withdrawYield()    
        
    function calculateYieldTotal1(address user) external view returns(uint256) {
        uint end = block.timestamp;
        uint256 time = calculateYieldTime(user, end) * 10**18;
        uint256 rate = yieldrate;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingBalance[user] * timeRate) / 10**18;
        rawYield += pmknBalance[user] + pmknBalanceMature[user];
        return rawYield;
    }         
        


    // This function returns the timeleft per user of locked rewards in seconds

    function calculateYieldTime1(address user) external view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        
        if(totalTime < lockupseconds) {
            uint timeleft = lockupseconds - totalTime;
            return timeleft;
        } else {
            return 0;
        }
    }

    
    // This function is used to withdraw the yield by minting the rewards token and updates balances and yield

    function withdrawYield() external {
        require(msg.sender != EMPTY_ADDRESS);
        
        uint end = block.timestamp;
        
        uint256 toTransfer = calculateYieldTotal(msg.sender, end);
        uint256 toTransferRewards = calculateYieldTotalRewards(end);

        uint locktime = calculateYieldTime(msg.sender, end);
        
        require(
            toTransfer > 0 ||
            pmknBalance[msg.sender] > 0 ||
            pmknBalanceMature[msg.sender] > 0,
            "Nothing to withdraw"
            );
            
        require
            (locktime > lockupseconds ||
            (locktime < lockupseconds && pmknBalanceMature[msg.sender] > 0),
            "Nothing to withdraw"
            );    
            
        if (locktime > lockupseconds) {
            uint256 oldBalance = pmknBalance[msg.sender] + pmknBalanceMature[msg.sender];
            pmknBalance[msg.sender] = 0;
            pmknBalanceMature[msg.sender] = 0;
            toTransfer += oldBalance;
        } else {
            pmknBalance[msg.sender] += toTransfer;
            uint256 oldBalance = pmknBalanceMature[msg.sender];
            pmknBalanceMature[msg.sender] = 0;
            toTransfer = oldBalance;
        }


        balancerewards = balancerewards + toTransferRewards - toTransfer; 
        
        startTime[msg.sender] = end;
        timerewards = end;
        
        _mint(msg.sender, toTransfer);
        
        emit YieldWithdraw(msg.sender, toTransfer);
    } 


    function redeem(uint _amount) external onlyOwner {
        require(_amount > 0, "amount cannot be 0");
        _burn(msg.sender, _amount);
        
        emit Redeem(msg.sender, _amount);
    }








    // This function returns a balance of the underlying token of the account at any moment of history
    
    function balanceAt(address account, uint64 timestamp) external view returns (uint) {
        BalanceSnapshot[] storage accountHistory = balanceSnapshots[account];

        // if the timestamp is earlier than the first balance snapshot - it's balance is 0
        // or if there is no history for account - it's balance is 0
        
        uint256 historyLength = accountHistory.length;
        if (historyLength == 0 || timestamp < accountHistory[0].timestamp) {
            return 0;
        }

        uint256 lastIndex = historyLength - 1;
        
        // if the timestamp is more recent than the last balance snapshot - it's balance is the last balance
        
        if (timestamp >= accountHistory[lastIndex].timestamp) {
            return accountHistory[lastIndex].balance;
        }

        // otherwise - binary search based lookup
        
        uint256 snapshotIdx = balanceSnapshotLookup(accountHistory, 0, lastIndex, timestamp);
        return accountHistory[snapshotIdx].balance;
    }


    // This function helps the user save some fee money, when they call some other function that
    // invokes balanceOf(account, timestamp). By calling this function the user deletes their history except the most
    // recent entry. The user should understand that after invoking that function, they are no longer able to prove their
    // balance history.
    
    function clearAccountHistory() external {
        BalanceSnapshot[] storage accountHistory = balanceSnapshots[_msgSender()];
        uint256 historyLength = accountHistory.length;

        // if the callers history is empty or contains only one snapshot - return
        
        if (historyLength < 2) {
            return;
        }

        // otherwise delete callers history except the most recent snapshot
        
        BalanceSnapshot memory recentSnapshot = accountHistory[historyLength - 1];

        delete balanceSnapshots[_msgSender()];

        accountHistory.push(recentSnapshot);
    }



    // This function is called on every stake() and unstake()
    
    function updateAccountHistory(address account, uint accountBalance) internal {
        BalanceSnapshot[] storage accountHistory = balanceSnapshots[account];

        // if history is empty - just add new entry
        
        uint256 historyLength = accountHistory.length;
        if (historyLength == 0) {
            accountHistory.push(BalanceSnapshot(uint64(block.timestamp), accountBalance));

        } else  {
            BalanceSnapshot storage lastSnapshot = accountHistory[historyLength - 1];

            if (lastSnapshot.timestamp == uint64(block.timestamp)) {
                // if there are multiple updates during one block - only save the most recent balance per block
                lastSnapshot.balance = accountBalance;
            } else {
                // otherwise just add new balance snapshot
                accountHistory.push(BalanceSnapshot(uint64(block.timestamp), accountBalance));
            }
        }
    }


    // This function uses binary search to find the closest to timestamp balance snapshot
    
    function balanceSnapshotLookup(
        BalanceSnapshot[] storage accountHistory,
        uint256 begin,
        uint256 end,
        uint64 timestamp
    ) internal view returns (uint256) {
        // split in half
        uint256 midLeft = begin +((end -(begin)) / 2);
        uint256 midRight = midLeft +(1);

        uint64 leftTimestamp = accountHistory[midLeft].timestamp;
        uint64 rightTimestamp = accountHistory[midRight].timestamp;

        // if we're in between (left is lower, right is higher) or if we found exact value - return its index
        if ((leftTimestamp <= timestamp && rightTimestamp > timestamp)) {
            return midLeft;
        }
        if (rightTimestamp == timestamp) {
            return midRight;
        }

        // if we're higher than both left and right, repeat for the left side
        if (leftTimestamp < timestamp && rightTimestamp < timestamp) {
            return balanceSnapshotLookup(accountHistory, midRight, end, timestamp);
        }

        // if we're lower than both left and right, repeat for the right side
        if (leftTimestamp > timestamp && rightTimestamp > timestamp) {
            return balanceSnapshotLookup(accountHistory, begin, midLeft, timestamp);
        }

        // it is impossible, because we checked boundaries before
        assert(false);
        return MAX_UINT;
    }



}