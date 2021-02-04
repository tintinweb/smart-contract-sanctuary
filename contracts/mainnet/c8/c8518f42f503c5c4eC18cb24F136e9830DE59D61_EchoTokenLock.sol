pragma solidity ^0.4.18;

import "./EchoToken.sol";



contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



  constructor() public {

    owner = msg.sender;

  }


  modifier onlyOwner() {

    require(msg.sender == owner);

    _;

  }


  function transferOwnership(address newOwner) public onlyOwner {

    require(newOwner != address(0));

    emit OwnershipTransferred(owner, newOwner);

    owner = newOwner;

  }

}



contract EchoTokenLock is Ownable {

    using SafeMath for uint256;

 
    address public firstReserveWallet = 0xc6f2b171ce9c0d53dfEbE6428346895204345EE6;

    address public secondReserveWallet = 0x456EF4ecfe42f3351D0006E9E219131022BC2700;
    
    address public fiveReserveWallet = 0x849b8168aD6F255A23c87b8B059231Cf74f6C976;
    
    address public sixReserveWallet = 0x9bEE59F321Ef10bCF7A1B5B87E22c32273544157;

    address public sevenReserveWallet = 0xbB2e9ACBa084Ae0d804cBAA81776318199416E35;

    address public eightReserveWallet = 0xec510cff20247E2b2A89ADfb7420d6361F07D32C;


    uint256 public firstReserveAllocation = 3 * (10 ** 7) * (10 ** 18);

    uint256 public secondReserveAllocation = 2 * (10 ** 7) * (10 ** 18);
    
    uint256 public fiveReserveAllocation = 5 * (10 ** 8) * (10 ** 18);

    uint256 public sixReserveAllocation = 1 * (10 ** 7) * (10 ** 18);

    uint256 public sevenReserveAllocation = 2 * (10 ** 7) * (10 ** 18);

    uint256 public eightReserveAllocation = 2 * (10 ** 7) * (10 ** 18);

    
    uint256 public totalAllocation = 6 * (10 ** 8) * (10 ** 18);

    

    uint256 public firstReserveTimeLock = 4 * 365 days;
    uint256 public firstLockStages = 4;

 
    uint256 public secondReserveTimeLock = 10 * 365 days;
    uint256 public secondLockStages = 10;
    
   
    uint256 public fiveReserveTimeLock = 5 * 365 days;
    uint256 public fiveLockStages = 1;
    

    uint256 public sixReserveTimeLock = 2 * 365 days;
    uint256 public sixLockStages = 4;
    

    uint256 public sevenReserveTimeLock = 2 * 365 days;
    uint256 public sevenLockStages = 4;

  
    uint256 public eightReserveTimeLock = 2 * 365 days;
    uint256 public eightLockStages = 4;
    

    


    mapping(address => uint256) public vestingStages; 
    


    mapping(address => uint256) public lockedLockStages;  
    


    mapping(address => uint256) public allocations;  



    mapping(address => uint256) public timeLocks; 
    
    mapping(address => uint256) public nextTimeLocks;  

    

    mapping(address => uint256) public claimed;  



    uint256 public lockedAt = 0;

    EchoToken public token;



    event Allocated(address wallet, uint256 value);

  

    event Distributed(address wallet, uint256 value);

 

    event Locked(uint256 lockTime);

   

    modifier onlyReserveWallets {  

        require(allocations[msg.sender] > 0);

        _;

    }




    modifier onlyFirstReserve {
    
        require(msg.sender == firstReserveWallet || msg.sender == secondReserveWallet || msg.sender == fiveReserveWallet || msg.sender == sixReserveWallet || msg.sender == sevenReserveWallet || msg.sender == eightReserveWallet);

        require(allocations[msg.sender] > 0);

        _;
        
    }
   

  

    modifier notLocked {  // 未锁定

        require(lockedAt == 0);

        _;

    }

    modifier locked { // 锁定

        require(lockedAt > 0);

        _;

    }

   

    modifier notAllocated {  

        require(allocations[firstReserveWallet] == 0);

        require(allocations[secondReserveWallet] == 0);
        
        require(allocations[fiveReserveWallet] == 0);

        require(allocations[sixReserveWallet] == 0);
        
        require(allocations[sevenReserveWallet] == 0);
        
        require(allocations[eightReserveWallet] == 0);

        _;

    }

    constructor(ERC20 _token) public {  

        owner = msg.sender; 

        token = EchoToken(_token);

    }

    function allocate() public notLocked notAllocated onlyOwner { 

        //Makes sure Token Contract has the exact number of tokens

        require(token.balanceOf(address(this)) == totalAllocation, "TokenLock: Makes sure Token Contract has the exact number of tokens"); 

        allocations[firstReserveWallet] = firstReserveAllocation;

        allocations[secondReserveWallet] = secondReserveAllocation;

        allocations[fiveReserveWallet] = fiveReserveAllocation;
        
        allocations[sixReserveWallet] = sixReserveAllocation;

        allocations[sevenReserveWallet] = sevenReserveAllocation;

        allocations[eightReserveWallet] = eightReserveAllocation;
        
        
        emit Allocated(firstReserveWallet, firstReserveAllocation);

        emit Allocated(secondReserveWallet, secondReserveAllocation);

        emit Allocated(fiveReserveWallet, fiveReserveAllocation);
        
        emit Allocated(sixReserveWallet, sixReserveAllocation);

        emit Allocated(sevenReserveWallet, sevenReserveAllocation);

        emit Allocated(eightReserveWallet, eightReserveAllocation);

        lock();

    }

    function getlockedLockStage(address reserveWallet) public view  returns(uint256){

        uint256 vestingStage = vestingStages[reserveWallet];
        uint256 reserveTimeLock = timeLocks[reserveWallet];
        uint256 vestingMonths = reserveTimeLock.div(vestingStage);
        
        return vestingMonths;

    }

    function lock() internal notLocked onlyOwner {
        
        vestingStages[firstReserveWallet] = firstLockStages;

        vestingStages[secondReserveWallet] = secondLockStages;

        vestingStages[fiveReserveWallet] = fiveLockStages;
        
        vestingStages[sixReserveWallet] = sixLockStages;

        vestingStages[sevenReserveWallet] = sevenLockStages;

        vestingStages[eightReserveWallet] = eightLockStages;
        
        
        timeLocks[firstReserveWallet] = firstReserveTimeLock;

        timeLocks[secondReserveWallet] = secondReserveTimeLock;
        
        timeLocks[fiveReserveWallet] = fiveReserveTimeLock;

        timeLocks[sixReserveWallet] = sixReserveTimeLock;

        timeLocks[sevenReserveWallet] = sevenReserveTimeLock;

        timeLocks[eightReserveWallet] = eightReserveTimeLock;
        
        
        lockedAt = block.timestamp; // 区块当前时间
                
        nextTimeLocks[firstReserveWallet] = lockedAt.add(getlockedLockStage(firstReserveWallet));

        nextTimeLocks[secondReserveWallet] = lockedAt.add(getlockedLockStage(secondReserveWallet));
        
        nextTimeLocks[fiveReserveWallet] = lockedAt.add(getlockedLockStage(fiveReserveWallet));

        nextTimeLocks[sixReserveWallet] = lockedAt.add(getlockedLockStage(sixReserveWallet));

        nextTimeLocks[sevenReserveWallet] = lockedAt.add(getlockedLockStage(sevenReserveWallet));

        nextTimeLocks[eightReserveWallet] = lockedAt.add(getlockedLockStage(eightReserveWallet));
        

        emit Locked(lockedAt);

    }
    

    function recoverFailedLock() external notLocked notAllocated onlyOwner {

       

        require(token.transfer(owner, token.balanceOf(address(this))));

    }

   

    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

    // Number of tokens that are still locked

    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]); 

    }
    
    
    function claimFirstReserve() onlyFirstReserve locked public {
        
        address reserveWallet = msg.sender;
        uint256 nextTime = nextTimeLocks[reserveWallet];
        
        // Can't claim before Lock ends
        require(block.timestamp >= nextTime, "TokenLock: release time is before current time"); 

        uint256 payment = allocations[reserveWallet].div(vestingStages[reserveWallet]); // 总的解锁量
        require(payment <= allocations[reserveWallet], "TokenLock: no enough tokens to reserve");
        
        uint256 totalLocked = claimed[reserveWallet].add(payment);
        require(totalLocked <= allocations[reserveWallet], "TokenLock: total release exceeded"); 

        claimed[reserveWallet] = totalLocked;
        nextTimeLocks[reserveWallet] = nextTime.add(getlockedLockStage(reserveWallet));
        
        require(token.transfer(reserveWallet, payment), "TokenLock: transfer failed"); 
        
        emit Distributed(reserveWallet, payment);
       
    }
}