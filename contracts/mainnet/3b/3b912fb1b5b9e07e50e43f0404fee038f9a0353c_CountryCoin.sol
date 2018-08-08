pragma solidity ^0.4.4;

contract CountryCoin {

    string public constant name = "CountryCoin";
    string public constant symbol = "CCN";
    uint public constant decimals = 8;
    uint public totalSupply;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    uint constant oneCent = 4642857142857;
    mapping (uint16 => uint) rating;
    mapping (uint16 => mapping( address => uint)) votes;
    mapping (address => uint16[]) history;

    address owner;

    function CountryCoin() {
        totalSupply = 750000000000000000;
        balances[this] = totalSupply;
        owner = msg.sender;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(allowed[_from][_to] >= _value);
        require(balances[_to] + _value > balances[_to]);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][_to] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function () payable {
        uint tokenAmount = msg.value*100000000 / oneCent;
        require(tokenAmount <= balances[this]);

        balances[this] -= tokenAmount;
        balances[msg.sender] += tokenAmount;
    }

    function vote(uint16 _country, uint _amount) {
        require(balances[msg.sender] >= _amount);
        require(_country < 1000);

        if (votes[_country][msg.sender] == 0) {
            history[msg.sender].push(_country);
        }
        balances[msg.sender] -= _amount;
        rating[_country] += _amount;
        votes[_country][msg.sender] += _amount;
    }

    function reset() {
        for(uint16 i=0; i<history[msg.sender].length; i++) {
            uint16 country = history[msg.sender][i];
            uint amount = votes[country][msg.sender];
            balances[msg.sender] += amount;
            rating[country] -= amount;
            votes[country][msg.sender] = 0;
        }
        history[msg.sender].length = 0;
    }

    function ratingOf(uint16 _country) constant returns (uint) {
        require(_country < 1000);
        return rating[_country];
    }

    function ratingList() constant returns (uint[] memory r) {
        r = new uint[](1000);
        for(uint16 i=0; i<r.length; i++) {
            r[i] = rating[i];
        }
    }

    function withdraw() {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }

}