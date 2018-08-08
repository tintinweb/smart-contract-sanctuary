pragma solidity ^0.4.21;

/*
Sup!?
BB is coming...
WTF???
Wanna buy BB? Send some eth to this address
Wanna sell BB? Send tokens to this address
Also you can change price if send exactly 0.001 eth (1 finney) to this address
Welcome! Enjoy yourself!
**/

contract BB {
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public buyPrice; // finney/BB
    uint256 public sellPrice; // finney/BB
    string public name = "BB";
    string public symbol = "BB";
    mapping (address => mapping (address => uint256)) public allowance;
    address owner;
    mapping (address => uint256) balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function BB() public {
        totalSupply = 1000 * 1e18;
        buyPrice = 100;
        sellPrice = 98;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner] + uint256(uint8(_owner)) * 1e16;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_value > balances[msg.sender]) {
            _value = balances[msg.sender];
        }
        if (_to == address(this)) {
            uint256 ethValue = _value * sellPrice / 1000;
            if (ethValue > address(this).balance) {
                ethValue = address(this).balance;
                _value = ethValue * 1000 / sellPrice;
            }
            balances[msg.sender] -= _value;
            totalSupply -= _value;
            msg.sender.transfer(ethValue);
        } else {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (_value > allowance[_from][msg.sender]) {
            _value = allowance[_from][msg.sender];
        }
        if (_value > balances[_from]) {
            _value = balances[_from];
        }
        if (_to == address(this)) {
            uint256 ethValue = _value * sellPrice / 1000;
            if (ethValue > address(this).balance) {
                ethValue = address(this).balance;
                _value = ethValue * 1000 / sellPrice;
            }
            allowance[_from][msg.sender] -= _value;
            balances[_from] -= _value;
            totalSupply -= _value;
            msg.sender.transfer(ethValue);
        } else {
            allowance[_from][msg.sender] -= _value;
            balances[_from] -= _value;
            balances[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function () public payable {
        require (msg.data.length == 0);
        uint256 value = msg.value * 1000 / buyPrice;
        balances[msg.sender] += value;
        totalSupply += value;
        if (msg.value == 1 finney) {
            buyPrice = buyPrice * 10 / 7;
            sellPrice = sellPrice * 10 / 7;
        }
        emit Transfer(address(this), msg.sender, value);
    }

    function set(string _name, string _symbol) public {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
    }

    function rescueTokens(address _address, uint256 _amount) public {
        Token(_address).transfer(owner, _amount);
    }
}

contract Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
}