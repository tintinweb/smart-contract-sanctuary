pragma solidity ^0.4.24;

contract ERC20Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {

    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }

    address public owner;


    constructor() public{
        owner = msg.sender;
    }

    address public newOwner;

    function changeOwner(address _newOwner)public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}
contract StandardToken is ERC20Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)public returns (bool success) {

        require ((_value==0) || (allowed[msg.sender][_spender] ==0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
}
contract WFCTestToken is StandardToken, Owned {

    string public constant name = "Wifi Chain Test Token";
    string public constant symbol = "WFCTT";
    string public version = "1.0";
    uint256 public constant decimals = 8;
    bool public disabled = false;
    uint256 public constant MILLION = (10**6 * 10**decimals);
    // constructor
    constructor()public {
        totalSupply = 10000 * MILLION; 
        balances[msg.sender] = totalSupply;
    }

    function getATMTotalSupply() external constant returns(uint256) {
        return totalSupply;
    }
 
    function setDisabled(bool flag) external onlyOwner {
        disabled = flag;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!disabled);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        require(!disabled);
        return super.transferFrom(_from, _to, _value);
    }
    function kill() external onlyOwner {
        selfdestruct(owner);
    }
}