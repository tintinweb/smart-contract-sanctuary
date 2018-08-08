pragma solidity ^0.4.24;

/**
 * @title Contract for keeping ledger of credit.
 * Credit will be divided into two and shall be assigned
 * to beneficiary 1 and beneficiary 2
 * Revision# 04: Incorporating Review comments by Rob.
 * Changes:
 *      1. Making contract more simpler by changing ownership mechanisim.
 **/
contract FundsSplitter {    


    bool public paused;
    address public owner;

    mapping(address => uint) public balances;
        
    
    event LogSplit(address indexed from, address receiver1, address receiver2, uint amount); /*Commit#4: Refactoring*/ 
    event LogWithdrawl(address indexed who, uint amount, uint balance); /*Commit#3: Index withdrawal */    
    event LogPause(address initiator);
    event LogUnPause(address initiator);
    
    /**
     * Modifier for checking if the procedure is called
     * by owner 
     */
    modifier ownerOnly{
        require(msg.sender == owner, "[ER01] Invalid owner address");
        _;
    }

    /**
     * Modifier to validate if contract is not paused
     */
    modifier whenNotPaused(){
        require(!paused, "[ER05] Contract is paused");
        _;
    }

    /**
     * Modifier to validate if the contract is paused
     */
    modifier whenPaused(){
        require(paused, "[ER06] Contract is not paused");
        _;
    }

    /**
     * Procedure no longer depends on any arguments.
     */ 
    constructor() public {
        owner = msg.sender;
    }
       
    /**
     * Refactored! Proecure will take receiver address and does 
     * not depends on the owner.
     **/
    function splitFunds(address receiver1, address receiver2) public payable whenNotPaused returns(bool success)  {                
        require(receiver1 != address(0), "[ER02] Invalid address");
        require(receiver2 != address(0), "[ER02] Invalid address");
        require(receiver1 != receiver2, "[ER02] Invalid address");
        require(msg.value > 0, "[ER04] Invalid Values");
        uint amount = msg.value / 2;                
        balances[receiver1] += amount;
        balances[receiver2] += msg.value - amount;
        emit LogSplit(msg.sender, receiver1,receiver2, msg.value);
        return true;
    }

    /**
     * Procedure for withdrawing debited amount to the 
     * specific owner
     * @param amount Funds to withdraw
     */
    function withdrawFunds(uint amount) whenNotPaused public{
        require(amount > 0); // Funds can not be <= 0
        require(balances[msg.sender] > 0, "[ER03] Invalid address");
        require(balances[msg.sender] >= amount, "[ER04] Not enough Funds");
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    

    /**
     * Procedure to pause the contract
     */
    function pause() ownerOnly whenNotPaused public{
        paused = true;
        emit LogPause(msg.sender);
    }

    /**
     * Procedure to unpause the contract
     */
    function unpause() ownerOnly whenPaused public{
        paused = false;
        emit LogUnPause(msg.sender);
    }
    
}