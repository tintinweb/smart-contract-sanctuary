// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import './otter.sol';

contract Presale  {

    bool public _locked = true;
    uint256 public weiRaised = 0;
    address private owner;

    uint256 public otterLeft;
    // The Address of OTTER Token
    standardToken Otter = standardToken(0xE718EDA678AFF3F8d1592e784652BcbEeb49e352);
    
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    modifier isLocked() {
        require(!_locked, 'Contract is Locked');
        _;
    }

    constructor() {
        owner = msg.sender;
     }
    function Buy(address purchaser) public payable isLocked {
        uint256 weiAmount = msg.value;
        require (weiAmount >= 1 ether, 'Min buy of 1 Matic');
        require (weiAmount <= 500 ether, 'Max buy of 500 Matic');

        // Amount to be bought
        uint amountInEther = weiAmount/(1 ether);
        
        // Otter Tokens (in WEI) received per 1 Matic Spent 
        uint rate = 37 * 1 ether;
        uint tokens  = amountInEther * rate;

        // Check that presale contract still has the balance. Then send directly to purchaser
        require(Otter.balanceOf(address(this)) >= tokens, "No more Otter!");
        
        weiRaised = weiRaised += weiAmount;
        Otter.transfer(purchaser, tokens);
        otterLeft = Otter.balanceOf(address(this));
    }
    

    function setLock(bool locked) public isOwner {
        _locked = locked;
    }
    
    function releaseOtter(address payable recipient, uint amount) public isOwner {
        Otter.transfer(recipient, amount);
    }
    function releaseFunds(address payable recipient , uint amount) public isOwner {
        recipient.transfer(amount);
    }
    
   
}