pragma solidity ^0.8.0;

contract ethPool {    
    address owner;
    modifier onlyowner { require(msg.sender == owner, "INVALID USER"); _; }
    uint totalDeposit = 0;
    
    struct depositorInfo {
        uint amount;
        bool isExist;
    }
    
    mapping(address => depositorInfo) depositors;
    mapping(address => depositorInfo) depositorsReward;
    uint256[] depositorsIds;
    address[] allDepositors;

    event Deposit(
        address indexed depositor,
        uint amount
    );
    
    event RewardDistributed(
        uint amount
    );
    
    event Withdraw(
        address indexed depositor,
        uint amount
    );
    
    constructor() {
        owner = msg.sender;
    }
    
    // joinPool by depositors
    function joinPool() public payable returns(bool) {
        address from = msg.sender;
        uint depositAmount = msg.value;
        
        if(depositors[from].isExist) revert();
        require(from != owner, 'YOU ARE NOT ALLOWED TO DEPOSIT');
        require(depositAmount > 0, 'DEPOSIT AMOUNT MUST BE GREATER THAN 0');
        uint senderBalance = address(from).balance;
        require(senderBalance > depositAmount, 'INSUFFICIENT AMOUNT IN ACCOUNT');
        // payable(owner).transfer(depositAmount);
        totalDeposit += depositAmount;
        
        depositorInfo storage newDepositor = depositors[from];
        newDepositor.amount = depositAmount;
        newDepositor.isExist = true;
        allDepositors.push(from);
        
        emit Deposit(from, depositAmount);
        return true;
    }
    
    // distribute rewards to depositors
    function giveReward() public payable onlyowner returns(bool) {
        uint rewardedAmount = msg.value;
        require(rewardedAmount > 0, 'REWARD AMOUNT SHOULD BE GREATER THAN 0');

        for(uint i = 0; i < allDepositors.length; i++) {
            uint rewardAmount = (uint(rewardedAmount) * ((uint(depositors[allDepositors[i]].amount) * 100) / uint(totalDeposit))) / 100;
            if(depositors[allDepositors[i]].isExist == true) {
                if(depositorsReward[allDepositors[i]].isExist == true) {
                    depositorsReward[allDepositors[i]].amount += rewardAmount;
                }
                else {
                    depositorInfo storage newRewardDepositor = depositorsReward[allDepositors[i]];
                    newRewardDepositor.amount = rewardAmount;
                    newRewardDepositor.isExist = true;
                }   
            }
        }
        
        emit RewardDistributed(rewardedAmount);
        return true;
    }
    
    // withdraw deposit Amount & reward
    function withdraw() public payable returns(bool) {
        require(depositors[msg.sender].isExist == true, "YOU HAVEN'T DEPOSIT ANY AMOUNT");
        
        uint amountToWithDraw = depositors[msg.sender].amount + depositorsReward[msg.sender].amount;
        depositors[msg.sender].amount = 0;
        depositors[msg.sender].isExist = false;
        depositorsReward[msg.sender].amount = 0;
        depositorsReward[msg.sender].isExist = false;
        
        payable(msg.sender).transfer(amountToWithDraw);
        
        emit Withdraw(msg.sender, amountToWithDraw);
        return true;
    }
    
    // get total deposit amount
    function getTotalDeposit() public view returns(uint) {
        return totalDeposit;
    }
    
    // get specific depositor deposited amount
    function getDepositorAmount(address despositorAddress) public view returns(uint) {
        return depositors[despositorAddress].amount;
    }
    
    // get specific depositor reward amount
    function getDepositorRewardedAmount(address despositorAddress) public view returns(uint) {
        return depositorsReward[despositorAddress].amount;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}