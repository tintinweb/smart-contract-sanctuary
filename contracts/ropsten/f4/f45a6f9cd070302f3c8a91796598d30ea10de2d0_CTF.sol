/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.8.0;
 
 contract CTF {
    bytes32 public secret;
    address payable public withdrawAddress;
    event log (string logData, address player);
    mapping (address => bool) public winners;
    address payable public owner;
    
    constructor (string memory flagInit) payable{
        secret = keccak256(abi.encodePacked(flagInit));
        owner = payable(msg.sender);
    }
    
    receive () payable external{
        emit log("Someone knows sharing is caring <3: ", msg.sender);
    }
    
    function setWithdrawAddress(address payable a, string calldata handle, string calldata secretValue) payable public{
        require(msg.value >= 100000000000000000); //.1 ETH - You gotta be willing to wager that you're right!
        if (keccak256(abi.encodePacked(secretValue)) == secret){
            emit log(string(abi.encodePacked("Oooo - It seems you're on to something, ", handle, " aka ")), msg.sender);
           withdrawAddress = a;
        }else{
            emit log(string(abi.encodePacked("Oooof, so close. Guess you fell for the trap. Say goodbye to that precious ETH, ", handle, " aka ")), msg.sender);
        }
        
    }
    
    function withdrawPrizeMoney(string memory handle) external {
        require(withdrawAddress == msg.sender, "You dont wanna give other people money, do you?");
        if (winners[msg.sender]){
            emit log(string(abi.encodePacked("Uh oh, someone is getting a little greedy: ", handle, " aka ")), msg.sender);
        }else{
            emit log(string(abi.encodePacked("We have a winner! Congrats, ", handle, " aka ")), msg.sender);
            winners[withdrawAddress] = true; // No Reentrancy for y'all
            withdrawAddress.transfer(300000000000000000); // .3 ETH -> Even if you mess up once, triple your money!
        }
    }
    
    function ownerWithdraw() external{
        require(msg.sender == owner, "Hey! You're not... me!");
        owner.transfer(address(this).balance);
    }
}