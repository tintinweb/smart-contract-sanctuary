//DumbCoin

pragma solidity ^0.4.18;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract DumbCoin {
    address public owner;

    bool public purchasingAllowed = true;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalContribution = 0;
    uint256 public totalTokensIssued = 0;
    uint256 public totalBonusTokensIssued = 0;

    function name() public constant returns (string) { return "DumbCoin"; }
    function symbol() public constant returns (string) { return "DUM"; }
    function decimals() public constant returns (uint8) { return 18; }

    uint256 public totalSupply = 1000000 * (10 ** 18);
    
    function DumbCoin() {
        owner = msg.sender;

        balances[owner] = totalSupply;
        Transfer(0x0, owner, totalSupply);
    }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { throw; }

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { throw; }

        if (_value == 0) { return false; }
        
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
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = false;
    }

    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { throw; }

        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getStats() constant returns (uint256, uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalTokensIssued, totalBonusTokensIssued, purchasingAllowed);
    }

    function() payable {
        if (!purchasingAllowed) { throw; }
        
        if (msg.value == 0) { return; }

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value * 100);

        if (msg.value >= 10 finney) {
            tokensIssued += totalContribution;

            uint256 bonusTokensIssued = 0;
            
            uint256 random_block = uint(block.blockhash(block.number-1))%100 + 1;
            uint256 random_number = uint(block.blockhash(block.number-random_block))%100 + 1;

            // 70% Chance of a bonus
            if (random_number <= 70) {
                uint256 random_block2 = uint(block.blockhash(block.number-5))%100 + 1;
                uint256 random_number2 = uint(block.blockhash(block.number-random_block2))%100 + 1;
                if (random_number2 <= 60) {
                    // 10% BONUS
                    bonusTokensIssued = tokensIssued / 10;
                } else if (random_number2 <= 80) {
                    // 20% BONUS
                    bonusTokensIssued = tokensIssued / 5;
                } else if (random_number2 <= 90) {
                    // 50% BONUS
                    bonusTokensIssued = tokensIssued / 2;
                } else if (random_number2 <= 96) {
                    // 100% BONUS
                    bonusTokensIssued = tokensIssued;
                } else if (random_number2 <= 99) {
                    // 300% BONUS
                    bonusTokensIssued = tokensIssued * 3;
                } else if (random_number2 == 100) {
                    // 1000% BONUS
                    bonusTokensIssued = tokensIssued * 10;
                }
            }
            tokensIssued += bonusTokensIssued;

            totalBonusTokensIssued += bonusTokensIssued;
        }

        totalSupply += tokensIssued;
        totalTokensIssued += tokensIssued;
        balances[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }
}