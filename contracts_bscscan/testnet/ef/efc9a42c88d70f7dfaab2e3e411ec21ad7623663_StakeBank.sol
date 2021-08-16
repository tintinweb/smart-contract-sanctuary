/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract StakeBank {
    
    //StakeBank
    string public name = "StakeBank";
    
    // create 2 state variables
    address public sa17test;
    address public rewardToken;


    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;


    // in constructor pass in the address for BUSDC token and your custom reward token
    // that will be used to pay interest
    constructor() public {
        sa17test = 0x92fFDEABD281E7b4d4825F856fCB308a345CbB1d;
        rewardToken = 0x92fFDEABD281E7b4d4825F856fCB308a345CbB1d;

    }


    // allow user to stake busd tokens in contract
    
    function stakeTokens(uint _amount) public {

        // Trasnfer busd tokens to contract for staking
        IERC20(sa17test).transferFrom(msg.sender, address(this), _amount);

        // Update the staking balance in map
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status to track
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

        // allow user to unstake total balance and withdraw BUSD from the contract
    
     function unstakeTokens() public {

    	// get the users staking balance in busd
    	uint balance = stakingBalance[msg.sender];
    
        // reqire the amount staked needs to be greater then 0
        require(balance > 0, "staking balance can not be 0");
    
        // transfer busd tokens out of this contract to the msg.sender
        IERC20(sa17test).transfer(msg.sender, balance);
    
        // reset staking balance map to 0
        stakingBalance[msg.sender] = 0;
    
        // update the staking status
        isStaking[msg.sender] = false;

} 


    // Issue Reward tokens as a reward for staking
    
    function issueRewardToken() public {
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            
    // if there is a balance transfer the SAME amount of bank tokens to the account that is staking as a reward
            
            if(balance >0 ) {
                IERC20(rewardToken).transfer(recipient, balance);
                
            }
            
        }
        
    }
}