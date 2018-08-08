pragma solidity ^0.4.13;

contract PRSToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract PRSTokenICO {
    address owner = msg.sender;

    bool private purchasingAllowed = true;

    mapping (address => uint256) balances;

    uint256 private totalContribution = 0;

    uint256 private totalSupply = 0;

    function name() constant returns (string) { return "Useless Ethereum Token 2"; }
    function symbol() constant returns (string) { return "UET2"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function enablePurchasing(bool enable) {
        if (msg.sender != owner) { revert(); }

        purchasingAllowed = enable;
    }
    
    function withdrawPRSTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { revert(); }

        PRSToken token = PRSToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getStats() constant returns (uint256, uint256, bool) {
        return (totalContribution, totalSupply, purchasingAllowed);
    }

    function() payable {
        if (!purchasingAllowed) { revert(); }
        
        if (msg.value == 0) { return; }

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value * 100);

        if (msg.value >= 10 finney) {
            tokensIssued += totalContribution;
        }

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        
    }
}