pragma solidity ^0.4.24;
contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;


function transfer(address _to, uint256 _value) public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

function approve(address _spender,uint256 _value) public returns (bool success);
function allowance(address _owner, address _spender) public view returns (uint256 remaining);

event Transfer(address indexed _from,address indexed _to,uint256 _value);
event Approval(address indexed _owner,address indexed _spender,uint256 _value);

}


contract ERC20 is ERC20Interface{

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) allowed;

    constructor (string _name) public {
        name = _name;
        symbol = "DSS";
        decimals = 18;
        totalSupply = 2000000000000000000000000000;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[ _to] + _value >= balanceOf[ _to]);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns(bool success){
        require(_to != address(0));
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner,address _spender) public view returns(uint256 remaining){
        return allowed[_owner][_spender];
    }
}

contract owned{
    address public owner;
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function tOS(address newOwer) public onlyOwner{
        owner = newOwer;
    }
}

contract DSSToken is ERC20,owned{

    mapping(address =>bool)public frozenAccount;

    event AddSupply(uint256 amount);
    event FrozenFunds(address target, bool frozen);
    event Burn(address target,uint256 amount);

    constructor(string _name) ERC20(_name) public{
    }

    function mine(address target, uint256 amount) public onlyOwner{
        require(balanceOf[target]+amount >= balanceOf[target]);
        totalSupply += amount;
        balanceOf[target] += amount;

        emit AddSupply(amount);
        emit Transfer(0,target,amount);
    }

    function freezeAccount(address target,bool freeze) public onlyOwner{
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     function burn(uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender]>= _value);
        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;
        emit Burn(msg.sender,_value);
        return true;
     }

     function burnFrom(address _from,uint256 _value) public returns (bool success){
        require(balanceOf[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Burn(msg.sender,_value);
        return true;
     }
}