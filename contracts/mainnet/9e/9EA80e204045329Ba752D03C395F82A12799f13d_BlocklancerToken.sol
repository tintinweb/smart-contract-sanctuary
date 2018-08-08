//--------------------------------------------------------------//
//---------------------BLOCKLANCER TOKEN -----------------------//
//--------------------------------------------------------------//

pragma solidity ^0.4.8;

/// Migration Agent
/// allows us to migrate to a new contract should it be needed
/// makes blocklancer future proof
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract ERC20Interface {
     // Get the total token supply
     function totalSupply() constant returns (uint256 totalSupply);
  
     // Get the account balance of another account with address _owner
     function balanceOf(address _owner) constant returns (uint256 balance);
  
     // Send _value amount of tokens to address _to
     function transfer(address _to, uint256 _value) returns (bool success);
  
     // Send _value amount of tokens from address _from to address _to
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     // this function is required for some DEX functionality
     function approve(address _spender, uint256 _value) returns (bool success);
  
     // Returns the amount which _spender is still allowed to withdraw from _owner
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
     // Triggered when tokens are transferred.
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
     // Triggered whenever approve(address _spender, uint256 _value) is called.
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/// Blocklancer Token (LNC) - crowdfunding code for Blocklancer Project
contract BlocklancerToken is ERC20Interface {
    string public constant name = "Lancer Token";
    string public constant symbol = "LNC";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETH.

    // The funding cap in weis.
    uint256 public constant tokenCreationCap = 1000000000* 10**18;
    uint256 public constant tokenCreationMin = 150000000* 10**18;
    
    mapping(address => mapping (address => uint256)) allowed;

    uint public fundingStart;
    uint public fundingEnd;

    // The flag indicates if the LNC contract is in Funding state.
    bool public funding = true;

    // Receives ETH and its own LNC endowment.
    address public master;

    // The current total token supply.
    uint256 totalTokens;
    
    //needed to calculate the price after the power day
    //the price increases by 1 % for every 10 million LNC sold after power day
    uint256 soldAfterPowerHour;

    mapping (address => uint256) balances;
    mapping (address => uint) lastTransferred;
    
    //needed to refund everyone should the ICO fail
    // needed because the price per LNC isn&#39;t linear
    mapping (address => uint256) balancesEther;

    //address of the contract that manages the migration
    //can only be changed by the creator
    address public migrationAgent;
    
    //total amount of token migrated
    //allows everyone to see the progress of the migration
    uint256 public totalMigrated;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);
    
    //total amount of participants in the ICO
    uint totalParticipants;

    function BlocklancerToken() {
        master = msg.sender;
        fundingStart = 1501977600;
        //change first number!
        fundingEnd = fundingStart + 31 * 1 days;//now + 1000 * 1 minutes;
    }
    
    //returns the total amount of participants in the ICO
    function getAmountofTotalParticipants() constant returns (uint){
        return totalParticipants;
    }
    
    //set
    function getAmountSoldAfterPowerDay() constant external returns(uint256){
        return soldAfterPowerHour;
    }

    /// allows to transfer token to another address
    function transfer(address _to, uint256 _value) returns (bool success) {
        // Don&#39;t allow in funding state
        if(funding) throw;

        var senderBalance = balances[msg.sender];
        //only allow if the balance of the sender is more than he want&#39;s to send
        if (senderBalance >= _value && _value > 0) {
            //reduce the sender balance by the amount he sends
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            
            //increase the balance of the receiver by the amount we reduced the balance of the sender
            balances[_to] += _value;
            
            //saves the last time someone sent LNc from this address
            //is needed for our Token Holder Tribunal
            //this ensures that everyone can only vote one time
            //otherwise it would be possible to send the LNC around and everyone votes again and again
            lastTransferred[msg.sender]=block.timestamp;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        //transfer failed
        return false;
    }

    //returns the total amount of LNC in circulation
    //get displayed on the website whilst the crowd funding
    function totalSupply() constant returns (uint256 totalSupply) {
        return totalTokens;
    }
    
    //retruns the balance of the owner address
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    //returns the amount anyone pledged into this contract
    function EtherBalanceOf(address _owner) constant returns (uint256) {
        return balancesEther[_owner];
    }
    
    //time left before the crodsale ends
    function TimeLeft() external constant returns (uint256) {
        if(fundingEnd>block.timestamp)
            return fundingEnd-block.timestamp;
        else
            return 0;
    }
    
    //time left before the crodsale begins
    function TimeLeftBeforeCrowdsale() external constant returns (uint256) {
        if(fundingStart>block.timestamp)
            return fundingStart-block.timestamp;
        else
            return 0;
    }

    // allows us to migrate to anew contract
    function migrate(uint256 _value) external {
        // can only be called if the funding ended
        if(funding) throw;
        
        //the migration agent address needs to be set
        if(migrationAgent == 0) throw;

        // must migrate more than nothing
        if(_value == 0) throw;
        
        //if the value is higher than the sender owns abort
        if(_value > balances[msg.sender]) throw;

        //reduce the balance of the owner
        balances[msg.sender] -= _value;
        
        //reduce the token left in the old contract
        totalTokens -= _value;
        totalMigrated += _value;
        
        //call the migration agent to complete the migration
        //credits the same amount of LNC in the new contract
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    //sets the address of the migration agent
    function setMigrationAgent(address _agent) external {
        //not possible in funding mode
        if(funding) throw;
        
        //only allow to set this once
        if(migrationAgent != 0) throw;
        
        //anly the owner can call this function
        if(msg.sender != master) throw;
        
        //set the migration agent
        migrationAgent = _agent;
    }
    
    //return the current exchange rate -> LNC per Ether
    function getExchangeRate() constant returns(uint){
        //15000 LNC at power day
        if(fundingStart + 1 * 1 days > block.timestamp){
            return 15000;
        }
        //otherwise reduce by 1 % every 10 million LNC sold
        else{
            uint256 decrease=100-(soldAfterPowerHour/10000000/1000000000000000000);
            if(decrease<70){
                decrease=70;
            }
            return 10000*decrease/100;
        }
    }
    
    //returns if the crowd sale is still open
    function ICOopen() constant returns(bool){
        if(!funding) return false;
        else if(block.timestamp < fundingStart) return false;
        else if(block.timestamp > fundingEnd) return false;
        else if(tokenCreationCap <= totalTokens) return false;
        else return true;
    }

    // Crowdfunding:

    //when someone send ether to this contract
    function() payable external {
        //not possible if the funding has ended
        if(!funding) throw;
        
        //not possible before the funding started
        if(block.timestamp < fundingStart) throw;
        
        //not possible after the funding ended
        if(block.timestamp > fundingEnd) throw;

        // Do not allow creating 0 or more than the cap tokens.
        if(msg.value == 0) throw;
        
        //don&#39;t allow to create more token than the maximum cap
        if((msg.value  * getExchangeRate()) > (tokenCreationCap - totalTokens)) throw;

        //calculate the amount of LNC the sender receives
        var numTokens = msg.value * getExchangeRate();
        totalTokens += numTokens;
        
        //increase the amount of token sold after power day
        //allows us to calculate the 1 % price increase per 10 million LNC sold
        if(getExchangeRate()!=15000){
            soldAfterPowerHour += numTokens;
        }

        // increase the amount of token the sender holds
        balances[msg.sender] += numTokens;
        
        //increase the amount of ether the sender pledged into the contract
        balancesEther[msg.sender] += msg.value;
        
        //icrease the amount of people that sent ether to this contract
        totalParticipants+=1;

        // Log token creation
        Transfer(0, msg.sender, numTokens);
    }

    //called after the crodsale ended
    //needed to allow everyone to send their LNC around
    function finalize() external {
        // not possible if the funding already ended
        if(!funding) throw;
        
        //only possible if funding ended and the minimum cap is reached - or
        //the total amount of token is the same as the maximum cap
        if((block.timestamp <= fundingEnd ||
             totalTokens < tokenCreationMin) &&
            (totalTokens+5000000000000000000000) < tokenCreationCap) throw;

        // allows to tranfer token to another address
        // disables buying LNC
        funding = false;

        //send 12% of the token to the devs
        //10 % for the devs
        //2 % for the bounty participants
        uint256 percentOfTotal = 12;
        uint256 additionalTokens = totalTokens * percentOfTotal / (100 - percentOfTotal);
        totalTokens += additionalTokens;
        balances[master] += additionalTokens;
        Transfer(0, master, additionalTokens);

        // Transfer ETH to the Blocklancer address.
        if (!master.send(this.balance)) throw;
    }

    //everyone needs to call this function should the minimum cap not be reached
    //refunds the sender
    function refund() external {
        // not possible after the ICO was finished
        if(!funding) throw;
        
        //not possible before the ICO ended
        if(block.timestamp <= fundingEnd) throw;
        
        //not possible if more token were created than the minimum
        if(totalTokens >= tokenCreationMin) throw;

        var lncValue = balances[msg.sender];
        var ethValue = balancesEther[msg.sender];
        if (lncValue == 0) throw;
        
        //set the amount of token the sender has to 0
        balances[msg.sender] = 0;
        
        //set the amount of ether the sender owns to 0
        balancesEther[msg.sender] = 0;
        totalTokens -= lncValue;

        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }
	
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
     // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     // fees in sub-currencies; the command should fail unless the _from account has
     // deliberately authorized the sender of the message via some mechanism; we propose
     // these standardized APIs for approval:
     function transferFrom(address _from,address _to,uint256 _amount) returns (bool success) {
         if(funding) throw;
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount) returns (bool success) {
         if(funding) throw;
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
}