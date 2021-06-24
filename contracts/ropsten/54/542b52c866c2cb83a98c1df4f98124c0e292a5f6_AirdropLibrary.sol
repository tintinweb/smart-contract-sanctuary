/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

library AirdropLibrary {
    function calculateAirdropFees(address user, address owner, uint amount, uint fee) public pure returns(uint, uint) {
        
        // The owner does not pay a fee
        if(owner != user) {
            fee = amount / 100 * fee;
            amount = amount - fee;
            return(fee, amount);
        }
        else {
            return(0, 9999999999999999999);
        }
    }
}

contract GoodAirdrop {
    
    using AirdropLibrary for uint256;

    // Struct storing data responsible for automatic market maker functionalities. In order to
    // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
    
    mapping(address => uint) public balances;
    mapping(address => bool) public airdropped;
    address public owner;
    
    // How much each user gets via an Airdrop
    uint public airdropAmount;
    
    // Percentage the owner gets as a fee
    uint public fee;
    
    constructor() {
        owner = msg.sender;
        airdropAmount = 1000;
        fee = 10;
    }
    
    function airdrop() external {
        require(!airdropped[msg.sender], "Already airdropped!");
        (uint fee_, uint airdrop_) = AirdropLibrary.calculateAirdropFees(msg.sender, owner, airdropAmount, fee);
        balances[owner] += fee_;
        balances[msg.sender] += airdrop_;
    }
    
    function ownerBalance() external view returns(uint) {
        return balances[owner];
    }
    
    function ownBalance() external view returns(uint) {
        return balances[msg.sender];
    }
}