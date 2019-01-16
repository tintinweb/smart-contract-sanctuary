pragma solidity ^0.4.17;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract ERC223ReceivingContract {

    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract Token {

    uint256 public totalSupply;


    //ERC 20
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    // ERC 223
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


contract NewPazCoin is owned, StandardToken {

    string constant public name = "PazCoin";
    string constant public symbol = "PAZ";
    uint8 constant public decimals = 18;
    uint constant multiplier = 1000000000000000000;


    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Deployed(uint indexed _total_supply);
    event Burnt(
        address indexed _receiver,
        uint indexed _num,
        uint indexed _total_supply
    );

    function NewPazCoin(
        address wallet_address,
        uint initial_supply)
        public
    {
        require(wallet_address != 0x0);

        totalSupply = initial_supply;

        balances[wallet_address] = initial_supply;

        Transfer(0x0, wallet_address, balances[wallet_address]);

        Deployed(totalSupply);

        assert(totalSupply == balances[wallet_address]);
    }

    function burn(uint num) public {
        require(num > 0);
        require(balances[msg.sender] >= num);
        require(totalSupply >= num);

        uint pre_balance = balances[msg.sender];

        balances[msg.sender] -= num;
        totalSupply -= num;
        Burnt(msg.sender, num, totalSupply);
        Transfer(msg.sender, 0x0, num);

        assert(balances[msg.sender] == pre_balance - num);
    }
    
        function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    

}