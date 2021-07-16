//SourceUnit: SantaToken.sol

pragma solidity ^0.4.25;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract SantaToken
{
    address owner;
    uint8 public decimals = 6;
    uint256 public totalSupply = 99000000000000 * (10 ** uint256(decimals));
    string public name = "Santa";
    string public symbol = "Santa";

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    constructor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }


    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner);
        require(_newOwner != address(0) && _newOwner != owner);
        owner = _newOwner;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        uint256 oldFromVal = balances[_from];
        require(_value > 0 && oldFromVal >= _value);
        uint256 oldToVal = balances[_to];
        uint256 newToVal = oldToVal + _value;
        require(newToVal > oldToVal);
        uint256 newFromVal = oldFromVal - _value;
        balances[_from] = newFromVal;
        balances[_to] = newToVal;

        assert((oldFromVal + oldToVal) == (newFromVal + newToVal));
        emit Transfer(_from, _to, _value);

        return true;
    }


    function _burn(address account, uint256 _value) external {
        require(account != address(0));

        totalSupply = totalSupply - _value;
        balances[account] = balances[account]- _value;
        emit Transfer(account, address(0), _value);
    }

    function _burnFrom(address account, uint256 _value) internal {
        allowed[account][msg.sender] = allowed[account][msg.sender] - _value;
        emit Burn(account, _value);
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
}