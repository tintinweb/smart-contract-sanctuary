pragma solidity ^0.4.19;

contract Aqo {
    string public constant name = "Aqo"; // ERC20
    string public constant symbol = "AQO"; // ERC20
    uint8 public constant decimals = 18; // ERC20
    uint256 public totalSupply; // ERC20
    mapping (address => uint256) public balanceOf; // ERC20
    mapping (address => mapping (address => uint256)) public allowance; // ERC20 

    event Transfer(address indexed from, address indexed to, uint256 value); // ERC20
    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC20

    function Aqo() public {
        uint256 initialSupply = 1000000000000000000000;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    // ERC20
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        if (_to == address(this)) {
            if (_value > address(this).balance) {
                _value = address(this).balance;
            }
            balanceOf[msg.sender] -= _value;
            totalSupply -= _value;
            msg.sender.transfer(_value);
        } else {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ERC20
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        if (_to == address(this)) {
            if (_value > address(this).balance) {
                _value = address(this).balance;
            }
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from] -= _value;
            totalSupply -= _value;
            msg.sender.transfer(_value);
        } else {
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    // ERC20
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function () public payable {
        require (msg.data.length == 0);
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(this), msg.sender, msg.value);
    }
}