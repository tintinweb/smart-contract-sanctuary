pragma solidity ^0.4.15;

contract ERC20Basic {

    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 amount) returns (bool result);

    event Transfer(address _from, address _to, uint256 amount);
}

contract TrueVeganCoin is ERC20Basic {

    string public tokenName = "True Vegan Coin";  
    string public tokenSymbol = "TVC"; 

    uint256 public constant decimals = 18;

    mapping(address => uint256) balances;

    function TrueVeganCoin() {
        totalSupply = 55 * (10**6) * 10**decimals; // 55 millions
        balances[msg.sender] += totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 amount) returns (bool result) {
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[_to] += amount;
        Transfer(msg.sender, _to, amount);
        return true;
    }
}