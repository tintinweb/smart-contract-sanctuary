pragma solidity ^0.4.23;

contract ZschopauToken {
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public approvals;
    address public owner;
    uint public totalSupply = 100;

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    event TransferFund(address _transferTo, address _transferFrom, uint amount);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balanceOf[_owner];
    }

    function transfer(address _to, uint _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient funds");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit TransferFund(_to, msg.sender, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(approvals[_from][_to] <= _value, "This amount is not approved!");
        require(balanceOf[_from] >= _value, "Insufficient funds");

        approvals[_to][_from] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit TransferFund(_to, _from, _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        approvals[_spender][msg.sender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return  approvals[_owner][_spender];
    }
}