/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

pragma solidity 0.8.7;
//SPDX-License-Identifier: MIT

contract Multisig {
    
    /**
     * @notice No Audits
     * @dev Use with caution!
     */
    
    address owner;
    address constant sig = 0xA1eb0F1f494854A6087cfb079D9Ca81101273Bbc;
    uint256 request = 0;
    
    /**
     * @dev Withdrawal and Deposit events are emitted once owner 
     * and sig accepts the request
     */
    
    event Withdrawal(uint256 amount);
    event Deposit(address sender, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlySig {
        require(msg.sender == sig);
        _;
    }
    
    modifier onlyAuth {
        require(msg.sender == sig || msg.sender == owner);
        _;
    }
    
    modifier withdrawalIssued {
        require(request != 0);
        _;
    }
    
    /**
     * @dev Owner issues withdrawal
     * @param _amount withdrawal amount in wei
     */
     
    function issueWithdrawal(uint256 _amount) onlyOwner public {
        request += _amount;
    }
    
    /**
     * @dev Owner or sig cancels withdrawal
     */
    
    function cancelWithdrawal() withdrawalIssued onlyAuth public {
        request = 0;
    }
    
    /**
     * @param _amount amount to be deducted from request
     */
    
    function deductRequest(uint256 _amount) withdrawalIssued onlyAuth public {
        request -= _amount;
    }
    
    /**
     * @dev The sig accepts and finalizes the withdrawal
     */
    
    function finalizeWithdrawal() withdrawalIssued onlySig public {
        payable(owner).transfer(request);
        request = 0;
        emit Withdrawal(request);
    }
    
    /**
     * @return request amount
     */
    
    function getRequest() view public returns (uint256) {
        return request;
    }
}