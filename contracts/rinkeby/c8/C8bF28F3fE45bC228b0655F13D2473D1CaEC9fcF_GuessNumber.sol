/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

contract GuessNumber
{
    
    address public contract_owner;
    address public contract_kill_address = 0xbF788b242FdcCeb19c47703dd4A346971807B315;
    
    uint public player_guess;
    uint public casino_answer;
    
    // deposit 1000000 gwei (0.001 ether) into bank
    // when the contract is created
    constructor() payable
    {
        require(msg.value == 0.001 ether);
        contract_owner = msg.sender;
    }
    
    
    // VULNERABLE !!!
    // THE RANDOM FUNCTION MIGHT BE ATTACKED
    // IF THE MINER CHOOSE TO DETERMINE THE BLOCK INFOMATION
    function GetRandom(address sender) private view returns(uint)
    {
       return uint(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), sender)));
    }
    // get the bank currently balance
    function GetBalance() public view returns(uint)
    {
        return address(this).balance;
    }
    
    
    
    // mamnully deposit the bank balance
    function BalanceAdd() public payable
    {
        require(msg.value == 0.001 ether);
    }
    
    // player can gambling by calling the function
    // the bet is 100000 gwei (0.0001 ether) each round
    // only the 50% chance the player cant get reward
    // 200000 gwei (0.0002 ether)
    // loser get nothing !
    function Play(uint player_input) public payable
    {
        // player take 100000 gwei (0.0001 ether)
        // from there pocket
        require(msg.value == 0.0001 ether);
        // bank must be affordable the rewawrd
        // which is 200000 gwei (0.0002 ether)
        require(address(this).balance >= 0.0002 ether);
        
        // the player must guess number between 1 to 6
        require(player_input >= 1 && player_input <= 6);
        
        player_guess = player_input; 
        // the casino real answer
        casino_answer = GetRandom(msg.sender) % 6 + 1;
        
        if(player_guess == casino_answer)
        {
            payable(msg.sender).transfer(0.0002 ether);
        }
    }
    // the contract might be selfdestruct as the movie
    // which just same as movie needs president fingerprint
    // the contract needs specific address as pass code
    // after the destruction
    // the balance will be send back to contract creator
    function ContractKill() public
    {
        require(msg.sender == contract_kill_address);
        selfdestruct(payable(msg.sender));
    }
}