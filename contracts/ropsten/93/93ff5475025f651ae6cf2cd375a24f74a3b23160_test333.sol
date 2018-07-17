pragma solidity ^0.4.18;

contract ERC20 {

    function totalSupply() public returns (uint256 totalSupply) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract StandToken is ERC20 {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(_value > 0);
        require(balances[msg.sender] + _value >= balances[msg.sender]);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    
    mapping (address => uint256) balances;
    uint256 public totalSupply;
}

contract test333 is StandToken {

    string public name;
    uint8 public decimals;
    string public symbol;
    address public creator;
    uint256 public dec_multiple;

    constructor() public {
        name = &quot;test333&quot;;
        decimals = 18;
        symbol = &quot;TS&quot;;
        dec_multiple = 10 ** uint256(decimals);

        //totalSupply = 3 * 1000 * 1000 * 1000 * dec_multiple;
        creator = msg.sender;
    }
     function set_totalSupply (uint256 _totalSupply) public {
        require(msg.sender == creator);
        totalSupply = _totalSupply;
    }
   
    
}