pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT


import './gym.sol';





contract GYMTokenVault is Ownable {
    using SafeMath for uint256;
    //using IERC20 for GYMToken;
    //using GYMToken for IERC20;
    
    /** Reserve allocations */
    mapping (address => uint256) public devWalletAmountAllocations;
    /** When timeLocks are over (UNIX Timestamp)*/
    mapping (address => uint256) public devWalletTimeLocks;
    /** How many tokens each reserve wallet has claimed */
    mapping (address => uint256) public claimed;
    
    uint256 public lockedAt = 0;
    GYM_Token public token;
    
    uint256 public devWalletAmount = 8888888888888 * 10**8;
    uint256 public walletTimeLock = 8 * 10 minutes;
    uint256 public VestingStages = 8;
    
    address private _caAddress;
    address public devWallet1 = 0xc694aE37e5b57788eEdC725693211037cBe3f7B5;
    address public devWallet2 = 0x0000000000000000000000000000000000000000;
    address public devWallet3 = 0x0000000000000000000000000000000000000000;
    address public devWallet4 = 0x0000000000000000000000000000000000000000;

    /** Allocated reserve tokens */
    event Allocated(address wallet, uint256 value);

    /** Distributed reserved tokens */
    event Distributed(address wallet, uint256 value);

    /** Tokens have been locked */
    event Locked(uint256 lockTime);

    //Any of the three reserve wallets

    modifier onlyReserveWallets { // 合约调用者的锁仓余额大于0才能查询锁仓余额
        require(devWalletAmountAllocations[msg.sender] > 0);
        _;
    }
    
    //Has not been locked yet
    modifier notLocked { // 未锁定
        require(lockedAt == 0);
        _;
    }
    
    modifier locked { // 锁定
        require(lockedAt > 0);
        _;
    }
    
    //Token allocations have not been set

    modifier notAllocated { // 没有为每个地址分配对应的锁仓金额时

        require(devWalletAmountAllocations[devWallet1] == 0);
        require(devWalletAmountAllocations[devWallet2] == 0);
        require(devWalletAmountAllocations[devWallet3] == 0);
        require(devWalletAmountAllocations[devWallet4] == 0);
        _;

    }
    
    // constructor (GYMToken _token) public {
    
    //   // owner = owner(); // msg.sender 是指直接调用当前合约的调用方地址
      
        
    //     token = _token;
    // }
    
    function allocate() public notLocked notAllocated onlyOwner {

        //Makes sure Token Contract has the exact number of tokens

        require(token.balanceOf(owner()) == devWalletAmount);
        
        uint256 half = devWalletAmount.div(2);
        uint256 otherHalf = devWalletAmount.sub(half);
        uint256 halfOfHalf = half.div(2);
        uint256 halfOfOtherHalf = otherHalf.div(2); 
        
        devWalletAmountAllocations[devWallet1] = halfOfHalf;
        devWalletAmountAllocations[devWallet2] = half.sub(halfOfHalf);
        devWalletAmountAllocations[devWallet3] = halfOfOtherHalf;
        devWalletAmountAllocations[devWallet4] = otherHalf.sub(halfOfOtherHalf);

        Allocated(devWallet1, halfOfHalf);
        Allocated(devWallet2, half.sub(halfOfHalf));
        Allocated(devWallet3, halfOfOtherHalf);
        Allocated(devWallet4, otherHalf.sub(halfOfOtherHalf));

        lock();

    }

    function lock() internal notLocked onlyOwner {
        lockedAt = block.timestamp; // 区块当前时间

        devWalletTimeLocks[devWallet1] = lockedAt.add(walletTimeLock);
        devWalletTimeLocks[devWallet2] = lockedAt.add(walletTimeLock);
        devWalletTimeLocks[devWallet3] = lockedAt.add(walletTimeLock);
        devWalletTimeLocks[devWallet4] = lockedAt.add(walletTimeLock);

        Locked(lockedAt);
    }
    
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

        // Transfer all tokens on this contract back to the owner

        require(token.transfer(owner(), token.balanceOf(address(this))));

    }
    
    // Total number of tokens currently in the vault

    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

    // Number of tokens that are still locked
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return devWalletAmountAllocations[msg.sender].sub(claimed[msg.sender]);

    }
    
    //Claim tokens for dev reserve wallets

    function claimTokenReserve() onlyReserveWallets locked public {
        
        address reserveWallet = msg.sender;
        
        uint256 vestingStage = VestingStage();

        //Amount of tokens the reserveWallet should have at this vesting stage

        uint256 totalUnlocked = vestingStage.mul(devWalletAmountAllocations[reserveWallet]).div(VestingStages);

        require(totalUnlocked <= devWalletAmountAllocations[reserveWallet]);
     
        //Previously claimed tokens must be less than what is unlocked

        require(claimed[reserveWallet] < totalUnlocked);

        uint256 amountOfThisStage = totalUnlocked.sub(claimed[reserveWallet]);

        claimed[reserveWallet] = totalUnlocked;

        require(token.transfer(reserveWallet, amountOfThisStage));

        Distributed(reserveWallet, amountOfThisStage);

    }
    
    // Now which stage
    function VestingStage() public view onlyReserveWallets returns(uint256){

        // one month

        uint256 vestingNumber = walletTimeLock.div(VestingStages);

        uint256 stage = (block.timestamp.sub(lockedAt)).div(vestingNumber);

        //Ensures team vesting stage doesn't go past VestingStages

        return stage;

    }
    
}