/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.4.0;

contract LastWill {
    
    address owner;
    
    uint256 public lastTouch;
    address [] public child; 
    event status (string msg, address user, uint256 time);
    
    function LastWill() payable {
        owner = msg.sender;
        lastTouch = block.timestamp;
        status('Last Will Contract Was Created', msg.sender, block.timestamp);
    } 
    
    function depositFunds () payable {
        status('Funds Were Deposited', msg.sender, block.timestamp);
        
    }
    
    function StillAlive() OnlyOwner {
        lastTouch = block.timestamp;
        status ('I am Still Alive', msg.sender, block.timestamp);
    }
    
    function isDead() {
        status('Asking if Dead', msg.sender, block.timestamp);
        if(block.timestamp > (lastTouch + 120)) {
            giveMoneyToChilds();
        } else {
             status ('I am Still Alive', msg.sender, block.timestamp);
        }
    }

    function giveMoneyToChilds() {
        status ('I Am Dead, Take My Money', msg.sender, block.timestamp);
        uint amountPerChild = this.balance/child.length;
        for(uint i = 0; i < child.length; i++) {
            child[i].transfer(amountPerChild);
            
        }
    }
    
    function addChild(address _address) OnlyOwner {
        status('New Child added', _address, block.timestamp);
        child.push(_address);
    
    }
    
    
    modifier OnlyOwner {
        if (msg.sender != owner) {
            revert ();
        } else {
            _;
        }
    }
}