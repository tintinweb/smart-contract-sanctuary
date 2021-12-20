/**
 *Submitted for verification at BscScan.com on 2021-12-20
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

    //Owner of the bank
    address public owner;

    // create 2 state variables
    address public usdc;      // The token you will accept
    address public bankToken; // The token that represents your bank that will be used to pay interest

    // create 1 array to add all your clients
    address[] public stakers;

    // create a 3 maps 
    mapping(address => uint) public stakingBalance; //Clients balance
    mapping(address => bool) public hasStaked; // Find out if this customer has created an account
    mapping(address => bool) public isStaking; // Find out if this customer is using their account

    // In constructor pass in the address for USDC token,  set your custom bank token and the owner will be who will deploy the contract
    constructor() public {
        usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        bankToken = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        owner = msg.sender;
    }

     // Change the ownership 
     function changeOwner(address newOwner) public {
    // require the permission of the current owner
        require(owner == msg.sender, "Your are not the current owner");
        owner = newOwner;
    }

    // allow user to deposit usdc tokens in your contract

    function deposit(uint _amount) public {

        // Transfer usdc tokens to contract
        IERC20(usdc).transferFrom(msg.sender, address(this), _amount);

        // Update the account balance in map
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status to track
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

     // allow user to withdraw total balance and withdraw USDC from the contract

     function withdrawTokens() public {

        // get the users staking balance in usdc
        uint balance = stakingBalance[msg.sender];

        // require the amount staked needs to be greater then 0
        require(balance > 0, "staking balance can not be 0");

        // transfer usdc tokens out of this contract to the msg.sender (client)
        IERC20(usdc).transfer(msg.sender, balance);

        // reset staking balance map to 0
        stakingBalance[msg.sender] = 0;

        // update the staking status
        isStaking[msg.sender] = false;
    } 

     // Send bank tokens as a reward for staking. You can change the way you need to give interest if you want

    function sendInterestToken() public {
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];

    // if there is a balance transfer the same amount of bank tokens to the account that is staking as interest

            if(balance >0 ) {
                IERC20(bankToken).transfer(recipient, balance);

            }

        }

    }
    
}