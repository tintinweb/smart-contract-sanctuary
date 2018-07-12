pragma solidity ^0.4.19;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
}

contract ERC20 {
    uint public totalSupply;

    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function balanceOf(address _owner) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Burn(address indexed _from, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint;

    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) balances;

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        require(_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    function Ownable() public {
        owner = msg.sender;
    }

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0x0)) {
            owner = newOwner;
        }
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint _value, address _token, bytes _data) public;
}

contract BurnCoinToken is StandardToken, Ownable {
    string public constant name = &#39;Burn Coin&#39;;
    string public constant symbol = &#39;BRN&#39;;
    uint public constant decimals = 8;
    uint public totalSupply = 500000000 * 10 ** uint(decimals); //500,000,000
    mapping (address => bool) public frozenAccounts;

    event FrozenFunds(address _target, bool frozen);

    function BurnCoinToken () public {
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);
    }

    modifier validateDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    function transfer(address _to, uint _value) validateDestination(_to) public returns (bool) {
        require(!frozenAccounts[msg.sender]);
        require(!frozenAccounts[_to]);
        uint previousBalances = balances[msg.sender] + balances[_to];
        bool transferResult = super.transfer(_to, _value);
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        return transferResult;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(!frozenAccounts[_from]);
        require(!frozenAccounts[_to]);
        bool transferResult = super.transferFrom(_from, _to, _value);

    }

    function burn(uint _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint _value) public returns (bool) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }
}