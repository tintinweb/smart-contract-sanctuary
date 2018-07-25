pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract LAWOwner {
    address public owner;
    event SetOwner(address indexed lastOwner,address newOwner);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) onlyOwner public {
        require(newOwner != 0x0);
        owner = newOwner;
        SetOwner(msg.sender,newOwner);
    }
}

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }
}

contract LAWStop is LAWOwner {
    bool public stopped = false;

    event SetStop(address sender,bool stopped);

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() onlyOwner public {
        stopped = true;
        SetStop(msg.sender,stopped);
    }

    function start() onlyOwner public {
        stopped = false;
        SetStop(msg.sender,stopped);
    }
}

contract LAWCoin is LAWStop,DSMath {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function LAWCoin(uint256 initialSupply, string tokenName, string tokenSymbol, address _owner) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[_owner] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = _owner;
    }

    function _transfer(address _from, address _to, uint _value) stoppable internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = add(balanceOf[_from],balanceOf[_to]);
        // uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] = sub(balanceOf[_from],_value);
        // balanceOf[_from] -= _value;
        balanceOf[_to] = add(balanceOf[_to],_value);
        // balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(add(balanceOf[_from],balanceOf[_to]) == previousBalances);
        // assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) stoppable public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) stoppable public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender],_value);
        // allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)  stoppable public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) stoppable public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) stoppable public returns (bool success) {   
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = sub(balanceOf[msg.sender],_value);
        // balanceOf[msg.sender] -= _value;
        totalSupply = sub(totalSupply,_value);
        // totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) stoppable public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = sub(balanceOf[_from],_value);
        // balanceOf[_from] -= _value;
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender],_value);
        // allowance[_from][msg.sender] -= _value;
        totalSupply = sub(totalSupply,_value);
        // totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}