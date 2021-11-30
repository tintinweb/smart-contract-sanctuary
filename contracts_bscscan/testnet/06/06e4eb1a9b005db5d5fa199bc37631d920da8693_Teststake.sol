//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./DappToken.sol";
import "./DaiToken.sol";

contract Teststake {
    string public name = "testStake";
    uint public decimals = 18;
    address public owner;
    DappToken public sheepAddress;
    DaiToken public busdAddress;

    address[] public stakers;

    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    
    uint256 percentualRewards = 25;
    uint256 rewardsDividend = 1000000;
    uint percentualFeesToken = 6; // 6%

 
    constructor(DappToken _sheepAddress, DaiToken _busdAddress) public {
        sheepAddress = _sheepAddress;
        busdAddress = _busdAddress;
        owner = msg.sender;

    }


    //-------------- Sets Values ----------------------------
    function setSheepAddress(address _sheepAddress) public {
         require(msg.sender == owner);
        sheepAddress = DappToken(_sheepAddress);
    }

    function setBusdAddress(address _busdAddress) public {
         require(msg.sender == owner);
        busdAddress = DaiToken(_busdAddress);
    }
 
    function setPercentualRewards(uint newPercentual) public {
        require(msg.sender == owner);
        percentualRewards = newPercentual;
    }
    
    function setRewardsDividend(uint newDividend) public {
        require(msg.sender == owner);
        rewardsDividend = newDividend;
    }

    function setPercentualFees(uint256 newPercentualFees) public {
        require(msg.sender == owner);
        require(newPercentualFees > 0 && newPercentualFees <= 100);
        percentualFeesToken = newPercentualFees;
    }

    //----------------- gets values -------------------------------
    function PercentualRewardsValue() public  view returns (uint) {
     return percentualRewards;
    }

    function rewardsDividendsValue() public  view returns (uint) {
     return rewardsDividend;
    }

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

    // Issuing Tokens
    function issueTokens() public {
        // Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");

        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient]*10**9;
            uint amount = (balance/100)*percentualRewards/rewardsDividend;
            if(balance > 0) {
                busdAddress.transfer(recipient, amount);
                //daitoken = USDT 
            }
        }
    }
}