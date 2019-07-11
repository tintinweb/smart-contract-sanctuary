/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.16;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract owned {
    address public owner;

    constructor() public {
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

contract Token {
    function totalSupply() public constant returns (uint256 supply);

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transferTo(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed _burner, uint256 _value);
}

contract StdToken is Token {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint public supply;

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferTo(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() public constant returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function _burn(address _burner, uint256 _value) internal returns (bool) {
        require(_value > 0);
        require(balances[_burner] > 0);
        balances[_burner] -= _value;
        supply -= _value;
        emit Burn(_burner, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract RVG is owned, StdToken {

    string public name = "Revolution Global";
    string public symbol = "RVG";
    string public website = "www.rvgtoken.io";
    uint public decimals = 18;

    uint256 public totalSupplied;
    uint256 public totalBurned;

    constructor(uint256 _totalSupply) public {
        supply = _totalSupply * (1 ether / 1 wei);
        totalBurned = 0;
        totalSupplied = 0;
        balances[address(this)] = supply;
    }

    function transferTo(address _to, uint256 _value) public onlyOwner returns (bool) {
        totalSupplied += _value;
        _transfer(address(this), _to, _value);
        return true;
    }

    function burn() public onlyOwner returns (bool) {
        uint256 remainBalance = supply - totalSupplied;
        uint256 burnAmount = remainBalance / 10;
        totalBurned += burnAmount;
        _burn(address(this), burnAmount);
        return true;
    }

    function burnByValue(uint256 _value) public onlyOwner returns (bool) {
        totalBurned += _value;
        _burn(address(this), _value);
        return true;
    }
}