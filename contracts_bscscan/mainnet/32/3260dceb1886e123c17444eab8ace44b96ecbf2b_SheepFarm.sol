//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./DappToken.sol";
import "./DaiToken.sol";

contract SheepFarm {
    string public name = "SheepFarm";
    uint public decimals = 18;
    address public owner;
    DappToken public sheepAddress;
    DaiToken public busdAddress;

    address[] public stakers;
    bool public lockClaim = true;

    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) claimAfter;
    
    uint256 percentualRewards = 25;
    uint256 rewardsDividend = 1000000;
    uint percentualFeesToken = 6; // 6%
    
    uint256 public timeLock = 86400; //time for unlock
   
   
 
    constructor(DappToken _sheepAddress, DaiToken _busdAddress) public {
        sheepAddress = _sheepAddress;
        busdAddress = _busdAddress;
        owner = msg.sender;

    }

    //-------------- Sets Values ----------------------------
    function setSheepAddress(address _sheepAddress) external {
         require(msg.sender == owner);
        sheepAddress = DappToken(_sheepAddress);
    }

    function setBusdAddress(address _busdAddress) external {
         require(msg.sender == owner);
        busdAddress = DaiToken(_busdAddress);
    }

    function UnlockClaim(bool setLockClaim) external{
        //lockClaim = false => Unlock
        //lockClaim = true = block
        require(msg.sender == owner);
        lockClaim = setLockClaim;
    }
 
    function setPercentualRewards(uint newPercentual) external {
        require(msg.sender == owner);
        percentualRewards = newPercentual;
    }
    
    function setRewardsDividend(uint newDividend) external {
        require(msg.sender == owner);
        rewardsDividend = newDividend;
    }

    function setPercentualFees(uint256 newPercentualFees) external {
        require(msg.sender == owner);
        require(newPercentualFees > 0 && newPercentualFees <= 100);
        percentualFeesToken = newPercentualFees;
    }

    //set timelocks in secounds
    function setTimeLock(uint256 _timeLock) external {
        require(msg.sender == owner);
        timeLock = _timeLock;
    }

    //----------------- gets values -------------------------------

    function getClaimUnlockTime(address _address ) public view returns(uint256){
       return claimAfter[_address];
    }

    function PercentualRewardsValue() public  view returns (uint) {
     return percentualRewards;
    }

    //Dividend denominator 
    function rewardsDividendsValue() public  view returns (uint) {
     return rewardsDividend;
    }

    // Percentual tokens TaxFees 
    function PercentualTokenFeesValue() public  view returns (uint) {
     return percentualFeesToken;
    }

    //------------- Actions ------------------------------------
    function stakeTokens(uint _amount) public {
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        uint txFee = ((_amount/100)*percentualFeesToken); //6% FEES SheepToken 
        uint totalAmount = _amount-txFee;

        // Trasnfer Mock Dai tokens to this contract for staking
        sheepAddress.transferFrom(msg.sender, address(this), _amount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + totalAmount ;

        // Add user to stakers array *only* if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        // Fetch staking balance
      
        uint balance = stakingBalance[msg.sender];
        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer Mock Dai tokens to this contract for staking
        sheepAddress.transfer(msg.sender, balance);

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Update staking status
        isStaking[msg.sender] = false;
    }

    // Claim rewards
    function claim() external{
        require(claimAfter[msg.sender] < block.timestamp, "You have already made a claim, please wait for the next release.");
        require(lockClaim == false, "Claim is blocked, wait for the next release");
        require(isStaking[msg.sender] == true, "you didn't stake");
        // amount to claim
        uint balance = stakingBalance[msg.sender]*10**9;
        uint amount = (balance/100)*percentualRewards/rewardsDividend;
        if(balance > 0) {
            busdAddress.transfer(msg.sender, amount);
        }
        //block for  timelocks secounds
        claimAfter[msg.sender] = block.timestamp + timeLock;
    }

    //
    function allRewardsDelivery() public {
        // Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");
        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
             uint balance = stakingBalance[msg.sender]*10**9;
             uint amount = (balance/100)*percentualRewards/rewardsDividend;
            if(balance > 0) {
                busdAddress.transfer(recipient, amount);
            }
        }
    }
}