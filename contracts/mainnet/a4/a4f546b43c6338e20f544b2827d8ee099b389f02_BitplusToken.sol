pragma solidity ^0.4.4;


/// @title Bitplus Token (BPNT) - crowdfunding code for Bitplus Project
contract BitplusToken {
    string public constant name = "Bitplus Token";
    string public constant symbol = "BPNT";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETH.

    uint256 public constant tokenCreationRate = 1000;

    // The funding cap in weis.
    uint256 public constant tokenCreationCap = 25000 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 2500 ether * tokenCreationRate;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    // The flag indicates if the contract is in Funding state.
    bool public funding = true;

    // Receives ETH
    address public bitplusAddress;

    // The current total token supply.
    uint256 totalTokens;

    mapping (address => uint256) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    struct EarlyBackerCondition {
        address backerAddress;
        uint256 deposited;
        uint256 agreedPercentage;
        uint256 agreedEthPrice;
    }
    
    EarlyBackerCondition[] public earlyBackers;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);
    event EarlyBackerDeposit(address indexed _from, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function BitplusToken(uint256 _fundingStartBlock,
                          uint256 _fundingEndBlock) {

        address _bitplusAddress = 0x286e0060d9DBEa0231389485D455A80f14648B3c;
        if (_bitplusAddress == 0) throw;
        if (_fundingStartBlock <= block.number) throw;
        if (_fundingEndBlock   <= _fundingStartBlock) throw;
        
        // special conditions for the early backers
        earlyBackers.push(EarlyBackerCondition({
            backerAddress: 0xa1cfc9ebdffbffe9b27d741ae04cfc2e78af527a,
            deposited: 0,
            agreedPercentage: 1000,
            agreedEthPrice: 250 ether
        }));
        
        // conditions for the company / developers
        earlyBackers.push(EarlyBackerCondition({
            backerAddress: 0x37ef1168252f274D4cA5b558213d7294085BCA08,
            deposited: 0,
            agreedPercentage: 500,
            agreedEthPrice: 0.1 ether
        }));
        
        earlyBackers.push(EarlyBackerCondition({
            backerAddress: 0x246604643ac38e96526b66ba91c1b2ec0c39d8de,
            deposited: 0,
            agreedPercentage: 500,
            agreedEthPrice: 0.1 ether
        }));        
        
        bitplusAddress = _bitplusAddress;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }

    /// @notice Transfer `_value` BPNT tokens from sender&#39;s account
    /// `msg.sender` to provided account address `_to`.
    /// @notice This function is disabled during the funding.
    /// @dev Required state: Operational
    /// @param _to The address of the tokens recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool) {
        // Abort if not in Operational state.
        if (funding) throw;

        var senderBalance = balances[msg.sender];
        if (senderBalance >= _value && _value > 0) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) returns (bool success) {
        // Abort if not in Operational state.
        if (funding) throw;         
         
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             return true;
         } else {
             return false;
         }
    }    

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }

    /// @notice Create tokens when funding is active.
    /// @dev Required state: Funding Active
    /// @dev State transition: -> Funding Success (only if cap reached)
    function create() payable external {
        // Abort if not in Funding Active state.
        // The checks are split (instead of using or operator) because it is
        // cheaper this way.
        if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;

        // Do not allow creating 0 tokens.
        if (msg.value == 0) throw;
        
        bool isEarlyBacker = false;
        
        for (uint i = 0; i < earlyBackers.length; i++) {
            if(earlyBackers[i].backerAddress == msg.sender) {
                earlyBackers[i].deposited += msg.value;
                isEarlyBacker = true;
                EarlyBackerDeposit(msg.sender, msg.value);
            }
        }
        
        
        if(!isEarlyBacker) {
            // do not allow to create more then cap tokens
            if (msg.value > (tokenCreationCap - totalTokens) / tokenCreationRate)
                throw;

            var numTokens = msg.value * tokenCreationRate;
            totalTokens += numTokens;

            // Assign new tokens to the sender
            balances[msg.sender] += numTokens;
            
            // Log token creation event
            Transfer(0, msg.sender, numTokens);            
        }
    }

    /// @notice Finalize crowdfunding
    /// @dev If cap was reached or crowdfunding has ended then:
    /// create BPNT for the early backers,
    /// transfer ETH to the Bitplus address.
    /// @dev Required state: Funding Success
    /// @dev State transition: -> Operational Normal
    function finalize() external {
        // Abort if not in Funding Success state.
        if (!funding) throw;
        if ((block.number <= fundingEndBlock ||
             totalTokens < tokenCreationMin) &&
             totalTokens < tokenCreationCap) throw;

        // Switch to Operational state. This is the only place this can happen.
        funding = false;
        // Transfer ETH to the Bitplus address.
        if (!bitplusAddress.send(this.balance)) throw;
        
        for (uint i = 0; i < earlyBackers.length; i++) {
            if(earlyBackers[i].deposited != uint256(0)) {
                uint256 percentage = (earlyBackers[i].deposited * earlyBackers[i].agreedPercentage / earlyBackers[i].agreedEthPrice);
                uint256 additionalTokens = totalTokens * percentage / (10000 - percentage);
                address backerAddr = earlyBackers[i].backerAddress;
                balances[backerAddr] = additionalTokens;
                totalTokens += additionalTokens;
                Transfer(0, backerAddr, additionalTokens);
			}
        }
    }

    /// @notice Get back the ether sent during the funding in case the funding
    /// has not reached the minimum level.
    /// @dev Required state: Funding Failure
    function refund() external {
        // Abort if not in Funding Failure state.
        if (!funding) throw;
        if (block.number <= fundingEndBlock) throw;
        if (totalTokens >= tokenCreationMin) throw;
        
        bool isEarlyBacker = false;
        uint256 ethValue;
        for (uint i = 0; i < earlyBackers.length; i++) {
            if(earlyBackers[i].backerAddress == msg.sender) {
                isEarlyBacker = true;
                ethValue = earlyBackers[i].deposited;
                if (ethValue == 0) throw;
            }
        }

        if(!isEarlyBacker) {
            var bpntValue = balances[msg.sender];
            if (bpntValue == 0) throw;
            balances[msg.sender] = 0;
            totalTokens -= bpntValue;
            ethValue = bpntValue / tokenCreationRate;
        }
        
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    // Just a safeguard for people who might invest and then loose the key
    // If 2 weeks after an unsuccessful end of the campaign there are unclaimed
    // funds, transfer those to Bitplus address - the funds will be returned to 
    // respective owners from it
    function safeguard() {
        if(block.number > (fundingEndBlock + 71000)) {
            if (!bitplusAddress.send(this.balance)) throw;
        }
    }
}