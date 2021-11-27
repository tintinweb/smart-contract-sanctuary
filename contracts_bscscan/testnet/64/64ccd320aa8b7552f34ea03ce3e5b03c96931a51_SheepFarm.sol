//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./DappToken.sol";
import "./DaiToken.sol";

contract SheepFarm {
    string public name = "Sheep Stake";
    address public owner;
    DappToken public dappToken;
    DaiToken public daiToken;

    address[] public stakers;

    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    
    uint percentualRewards = 500000000000; //0.000025%
    uint percentualFeesToken = 6; // 6%

 
    constructor(DappToken _dappToken, DaiToken _daiToken) public {
        dappToken = _dappToken;
        daiToken = _daiToken;
        owner = msg.sender;

    }


    function setDappToken(address _dappToken) public {
         require(msg.sender == owner);
        dappToken = DappToken(_dappToken);
    }

    function setDaiToken(address _daiToken) public {
         require(msg.sender == owner);
        daiToken = DaiToken(_daiToken);
    }
 
    function setPercentualRewards(uint newPercentual) public {
        require(msg.sender == owner);
        percentualRewards = newPercentual;
    }
    
    function setPercentualFees(uint256 newPercentualFees) public {
        require(msg.sender == owner);
        require(newPercentualFees > 0 && newPercentualFees <= 100);
        percentualFeesToken = newPercentualFees;
    }

    function PercentualRewardsValue() public  view returns (uint) {
     return percentualRewards;
    }

    function PercentualTokenFees() public  view returns (uint) {
     return percentualFeesToken;
    }

    function stakeTokens(uint _amount) public {
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        uint txFee = ((_amount/100)*percentualFeesToken); //6% FEES SheepToken 
        uint totalAmount = _amount-txFee;

        // Trasnfer Mock Dai tokens to this contract for staking
        dappToken.transferFrom(msg.sender, address(this), _amount);

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
        dappToken.transfer(msg.sender, balance);

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
            uint balance = stakingBalance[recipient];
            uint rewards = ((balance/100)*percentualRewards);
            uint amount = rewards*1e9;
            if(balance > 0) {
                daiToken.transfer(recipient, amount);
                //daitoken = USDT 
            }
        }
    }
}