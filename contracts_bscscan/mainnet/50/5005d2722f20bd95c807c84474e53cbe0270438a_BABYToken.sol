/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

pragma solidity ^0.5.0;

library SafeMathAres {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BABYToken {
    using SafeMathAres for uint256;
    string public constant name = "1BABY";
    string public constant symbol = "1baby";
    uint256 public constant decimals = 18;
    address public constant feesAddress = 0x14f3Ac67fDe71B8672C12B43B4E5249E39384DDA;
    uint256 public constant totalSupply = 1000000000000000 * 10 ** uint256(decimals);

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0), "not enough balance !");
        require((balances[msg.sender] >= _value), "");
        balances[msg.sender] = balances[msg.sender] - _value;
        
        uint256 fees = _value  * 0 / 100;
        uint256 toValue = _value - fees;
        assert(_value == toValue + fees);
        
        balances[_to] = balances[_to].add(toValue);
        balances[feesAddress] = balances[feesAddress].add(fees);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0), "not enough balance !");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "not enough allowed balance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // 实现一对多转账
    function batchTransfer(
        address payable[] memory _users,
        uint256[] memory _amounts
    )
    public
    returns (bool)
    {
        require(_users.length == _amounts.length,"not same length");
        for(uint8 i = 0; i < _users.length; i++){
            require(_users[i] != address(0),"address is zero");
            require(balances[msg.sender] >= _amounts[i] ,"not enough balance !");
            balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
            balances[_users[i]] = balances[_users[i]].add(_amounts[i]);
            emit Transfer(msg.sender, _users[i], _amounts[i]);
        }
        return true;
    }
}