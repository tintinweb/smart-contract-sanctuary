/**
 *Submitted for verification at polygonscan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
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


contract DefiBank {
    
    // call it DefiBank
    string public name = "DefiBank";
    
    // create 2 state variables
    address public usdc;
    address public bankToken;


    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;


    // in constructor pass in the address for USDC token and your custom bank token
    // that will be used to pay interest
    constructor() public {
        usdc = 0xEdc9bD98e01D92ad4F8f0C19beF725D2F4d7C8A3;
        bankToken = 0x167322e0f7020Ea94E3BA8a5E544161cFb18dc4F;

    }


    // allow user to stake usdc tokens in contract
    
    function stakeTokens(uint _amount) public {

        // Trasnfer usdc tokens to contract for staking
        IERC20(usdc).transferFrom(msg.sender, address(this), _amount);

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

        // allow user to unstake total balance and withdraw USDC from the contract
    
     function unstakeTokens() public {

    	// get the users staking balance in usdc
    	uint balance = stakingBalance[msg.sender];
    
        // reqire the amount staked needs to be greater then 0
        require(balance > 0, "staking balance can not be 0");
    
        // transfer usdc tokens out of this contract to the msg.sender
        IERC20(usdc).transfer(msg.sender, balance);
    
        // reset staking balance map to 0
        stakingBalance[msg.sender] = 0;
    
        // update the staking status
        isStaking[msg.sender] = false;

} 


    // Issue bank tokens as a reward for staking
    
    function issueInterestToken() public {
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            
    // if there is a balance transfer the SAME amount of bank tokens to the account that is staking as a reward
            
            if(balance >0 ) {
                IERC20(bankToken).transfer(recipient, balance);
                
            }
            
        }
        
    }
}