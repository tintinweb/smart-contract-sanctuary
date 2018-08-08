// https://theethereum.wiki/w/index.php/ERC20_Token_Standard

pragma solidity ^0.4.11;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract VilijavisShares {
    address owner = msg.sender;

    function name() constant returns (string) { 
        return "Vilijavis Shares";
    }
    
    function symbol() constant returns (string) { 
        return "VLJ";
    }
    
    function decimals() constant returns (uint8) {
        return 18;
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function isCrowdsaleAllowed() constant returns (bool) {
        return (currentRoundIndex > 0) && (currentRoundMultiplier > 0) && (currentRoundBudget > 0);
    }
    
    function roundParameters(uint256 _roundIndex) constant returns (uint256, uint256) {
        if (_roundIndex == 1) {
            return (200,   500 ether);
        }
        if (_roundIndex == 2) {
            return (175,  2500 ether);
        }
        if (_roundIndex == 3) {
            return (160,  6000 ether);
        }
        if (_roundIndex == 4) {
            return (150, 11000 ether);
        }
        return (0, 0);
    }
    
    function currentRoundParameters() constant returns (uint256, uint256) {
        return roundParameters(currentRoundIndex);
    }
    
    uint256 public currentRoundIndex = 0;
    uint256 public currentRoundMultiplier = 0;
    uint256 public currentRoundBudget = 0;

    uint256 public totalContribution = 0;
    uint256 public totalIssued = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if(msg.data.length < (2 * 32) + 4) {
            throw;
        }

        if (_value == 0) {
            return false;
        }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) {
            throw;
        }

        if (_value == 0) {
            return false;
        }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {
            return false;
        }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) {
            throw;
        }
        
        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        
        return token.transfer(owner, amount);
    }

    function startCrowdsale() {
        if (msg.sender != owner) {
            throw;
        }
        
        if (currentRoundIndex == 0) {
            currentRoundIndex = 1;
            (currentRoundMultiplier, currentRoundBudget) = currentRoundParameters();
        } else {
            throw;
        }
    }

    function stopCrowdsale() {
        if (msg.sender != owner) {
            throw;
        }
        
        if (currentRoundIndex == 0) {
            throw;
        }
        
        do {
            currentRoundIndex++;
        } while (isCrowdsaleAllowed());
        
        currentRoundMultiplier = 0;
        currentRoundBudget = 0;
    }

    function getStats() constant returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        uint256 maxContribution = 0;
        uint256 maxIssued = 0;

        uint256 multiplier;
        uint256 budget;

        uint256 round = 1;
        do {
            (multiplier, budget) = roundParameters(round);
            maxContribution += budget;
            maxIssued += budget * multiplier;
            round++;
        } while ((multiplier > 0) && (budget > 0));
        
        var (currentRoundMultiplier, currentRoundBudget) = currentRoundParameters();

        return (totalContribution, maxContribution, totalIssued, maxIssued, currentRoundMultiplier, currentRoundBudget, isCrowdsaleAllowed());
    }

    function setOwner(address _owner) {
        if (msg.sender != owner) {
            throw;
        }
        
        owner = _owner;
    }

    function() payable {
        if (!isCrowdsaleAllowed()) {
            throw;
        }
        
        if (msg.value < 1 szabo) {
            throw;
        }
        
        uint256 ethersReceived = msg.value;
        uint256 ethersContributed = 0;
        
        uint256 tokensIssued = 0;
            
        do {
            if (ethersReceived >= currentRoundBudget) {
                ethersContributed += currentRoundBudget;
                tokensIssued += currentRoundBudget * currentRoundMultiplier;

                ethersReceived -= currentRoundBudget;

                currentRoundIndex += 1;
                (currentRoundMultiplier, currentRoundBudget) = currentRoundParameters();
            } else {
                ethersContributed += ethersReceived;
                tokensIssued += ethersReceived * currentRoundMultiplier;
                
                currentRoundBudget -= ethersReceived;

                ethersReceived = 0;
            }
        } while ((ethersReceived > 0) && (isCrowdsaleAllowed()));
        
        owner.transfer(ethersContributed);
        
        if (ethersReceived > 0) {
            msg.sender.transfer(ethersReceived);
        }

        totalContribution += ethersContributed;

        balances[msg.sender] += tokensIssued;
        totalIssued += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }
}