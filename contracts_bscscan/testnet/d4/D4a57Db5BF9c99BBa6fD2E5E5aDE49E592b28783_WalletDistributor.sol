//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";

contract WalletDistributor is IOwnable {
    using SafeMath for uint256;
    
    address public override owner;
    mapping (address => uint256) public shares;
    mapping (address => uint256) private shareholderIndexes;
    address[] public shareholders;
    uint256 public totalShares;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        distribute();
    }
    
    function distribute() public {
        uint256 balance = address(this).balance;
        uint256 remaining = balance;
        for (uint256 i = 0; i < shareholders.length; i++) {
            uint256 share = balance.mul(shares[shareholders[i]]).div(totalShares);
            if (share < remaining) {
                payable(shareholders[i]).transfer(share);
            } else {
                payable(shareholders[i]).transfer(remaining);
            }
            remaining = remaining.sub(share);
        }
    }
    
    // Admin methods
    
    function changeOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
    
    function setShare(address shareholder, uint256 amount) public onlyOwner {

        if (amount > 0 && shares[shareholder] == 0) {
            addShareholder(shareholder);
        } else if(amount == 0 && shares[shareholder] > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder]).add(amount);
        shares[shareholder] = amount;
    }
    
        
    // Private methods
    
    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}