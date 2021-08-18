/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: 0BSD



// $$\   $$\  $$$$$$\  $$\      $$\ $$$$$$\       $$\                          $$\                           
// $$$\  $$ |$$  __$$\ $$$\    $$$ |\_$$  _|      $$ |                         $$ |                          
// $$$$\ $$ |$$ /  \__|$$$$\  $$$$ |  $$ |        $$ |      $$$$$$\   $$$$$$$\ $$ |  $$\  $$$$$$\   $$$$$$\  
// $$ $$\$$ |$$ |$$$$\ $$\$$\$$ $$ |  $$ |        $$ |     $$  __$$\ $$  _____|$$ | $$  |$$  __$$\ $$  __$$\ 
// $$ \$$$$ |$$ |\_$$ |$$ \$$$  $$ |  $$ |        $$ |     $$ /  $$ |$$ /      $$$$$$  / $$$$$$$$ |$$ |  \__|
// $$ |\$$$ |$$ |  $$ |$$ |\$  /$$ |  $$ |        $$ |     $$ |  $$ |$$ |      $$  _$$<  $$   ____|$$ |      
// $$ | \$$ |\$$$$$$  |$$ | \_/ $$ |$$$$$$\       $$$$$$$$\\$$$$$$  |\$$$$$$$\ $$ | \$$\ \$$$$$$$\ $$ |      
// \__|  \__| \______/ \__|     \__|\______|      \________|\______/  \_______|\__|  \__| \_______|\__|      
                                                                                                          
                                                                                                          
// Brought to you by the NGMI Finance team.

// This smart contract serves as a vault for depositing tokens with a lock period. Once tokens have been deposited, they cannot be withdrawn until the lock period has expired.
// Tokens deposited by an address can only be withdrawn using that same address. Withdrawal through a proxy is not allowed.

// Initial deposit/lock fee is 0.1 BNB
// This number is subject to change. depending on the price of BNB.

// Holding NGMI token will grant a 50$ discount to all fees when using this contract. 
// Current minimal amount of NGMI is 1000, which at the time of writing this equals to ~50 USD. 
// This number is also subject to change, depending on the price of NGMI Token.

// Join our social channels through the links below:
//  
// Telegram: https://t.me/ngmifinance
// Twitter: https://twitter.com/ngmif
// Website: https://ngmi.cc
// Old meme website: https://ngmi.one

// Made by Lizard
// If you have any difficulties using the contract or the website, please send an email over to [email protected] or join us in the official Telegram (linked above)

contract BEP20 {
    function balanceOf(address) external view returns(uint256) {}
    function transfer(address, uint256) external returns(bool) {}
    function transferFrom(address, address, uint256) external returns(bool) {}
}

contract NgmiBEP20Locker {
    
    mapping(uint256 => LockLog) private _aLockLogs;
    mapping(address => uint256[]) private _oLockLogs;
    mapping(address => uint256[]) private _tLockLogs;
    
    address private _owner;
    bool private _active;
    
    uint256 private _counter;

    // These variables must be initialized after deployment
    uint256 private _fee;
    uint256 private _discountFee;
    
    BEP20 private _ngmi;
    uint256 private _minNgmiBalance;
    

    constructor() {
        _owner = msg.sender;
        _active = true;
        _counter = 1;
        _ngmi = BEP20(0x309118620CCd4F5760CB2cC53a7479c1d7246400);
    }
    
    event Lock(address owner, address tokenAddress, uint256 amount, uint256 timestamp);
    event Unlock(address owner, address tokenAddress, uint256 amount);
    
    struct LockLog {
        uint256 id;     // Each LockLog has a unique ID
        
        address owner;      // Wallet locking funds
        address tokenAddress; // Address of the token being locked
        
        uint256 amount;     // Amount of the token to be locked (must be approved)
        uint256 timestamp;  // Unlock date
        
        bool withdrawn;     // Flag to indicate whether the Lock has been released
    }
    
    // Modifiers 
    
    modifier lizzy {
        require(msg.sender == _owner); _;
    }
    
    modifier active {
        require(_active, "NGMI Locker is not accepting new deposits at this time."); _;
    }
    
    modifier withFee {
        uint256 ngmiBalance = _ngmi.balanceOf(msg.sender);
        uint256 fee;
        
        if (ngmiBalance >= _minNgmiBalance) {
            fee = _discountFee;
        }
        else {
            fee = _fee;
        }
        
        require(msg.value >= fee, "Insufficient fee for locking."); _;
    }

    
    // Owner contract management functions 
    
    function setFee(uint256 feeWei) external lizzy {
        _fee = feeWei;
    } 
    
    function setDiscountFee(uint256 feeWei) external lizzy {
        _discountFee = feeWei;
    } 
    
    function setMinNgmiAmount(uint256 amount) external lizzy {
        _minNgmiBalance = amount;
    }
    
    function stopDeposits() external lizzy {
        _active = false;
    }
    
    function startDeposits() external lizzy {
        _active = true;
    }
    
    function setNgmiContractAddress(address ngmiAddress) external lizzy {
        _ngmi = BEP20(ngmiAddress);
    }
    
    /** Lock the given amount of the given token for the given amount of time */
    function lock(address tokenAddress, uint256 amount, uint256 until) 
    external payable 
    active withFee {
            
        BEP20 unsafeTokenContract = BEP20(tokenAddress);
        
        uint256 balanceBefore = unsafeTokenContract.balanceOf(address(this));
        unsafeTokenContract.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = unsafeTokenContract.balanceOf(address(this));
        
        require(balanceAfter == balanceBefore + amount);
        
        _aLockLogs[_counter] = LockLog(_counter, msg.sender, tokenAddress, amount, until, false);
        _oLockLogs[msg.sender].push(_counter);
        _tLockLogs[tokenAddress].push(_counter);
        
        _counter += 1;
        
        emit Lock(msg.sender, tokenAddress, amount, until);
    }
    
    /** Unlocks the given locked batch of tokens */
    function unlock(uint256 id) external {
        LockLog storage log = _aLockLogs[id];
        
        require(log.id != 0, "Lock log does not exist.");
        require(!log.withdrawn, "Already withdrawn.");
        require(log.owner == msg.sender, "You can only withdraw your own tokens.");
        require(log.timestamp < block.timestamp, "Lock is still active.");
        
        BEP20 unsafeTokenContract = BEP20(log.tokenAddress);
        log.withdrawn = true;
        
        uint256 balanceBefore = unsafeTokenContract.balanceOf(address(this));
        unsafeTokenContract.transfer(log.owner, log.amount);
        uint256 balanceAfter = unsafeTokenContract.balanceOf(address(this));
        
        require(balanceAfter == balanceBefore - log.amount);
        emit Unlock(log.owner, log.tokenAddress, log.amount);
    }
    
    
    /** Withdraw the fees collected within the contract to the owner */
    function withdrawFees() external lizzy {
        (bool success, bytes memory data) = payable(_owner).call{value: address(this).balance}("");
        if (!success) {
            emit BytesLog(data);
        }
    }
    event BytesLog(bytes data);
    
    /** Returns an array of LockLog objects for the given token address */
    function getLockLogsForToken(address tokenAddress) external view returns(LockLog[] memory) {
        uint256[] storage logIndexes = _tLockLogs[tokenAddress];
        uint256 len = logIndexes.length;
        uint256 i = 0;
        LockLog[] memory logs = new LockLog[](len);
        
        for (i; i < len; i++) {
            logs[i] = _aLockLogs[logIndexes[i]];
        }
        
        return logs;
    }
    
    /** Returns a LockLog with the specified ID. Throws if such a LockLog is not found */
    function getLockLogById(uint256 id) external view returns(LockLog memory) {
        LockLog storage log = _aLockLogs[id];
        require(log.id != 0, "Lock log with that ID does not exist.");
        return log;
    }
    
    /** Returns an array of LockLog objects for the caller */
    function getLockLogsForSelf() external view returns(LockLog[] memory) {
        uint256[] storage logIndexes = _oLockLogs[msg.sender];
        uint256 len = logIndexes.length;
        uint256 i = 0;
        LockLog[] memory logs = new LockLog[](len);
        
        for (i; i < len; i++) {
            logs[i] = _aLockLogs[logIndexes[i]];
        }
        
        return logs;
    }
}