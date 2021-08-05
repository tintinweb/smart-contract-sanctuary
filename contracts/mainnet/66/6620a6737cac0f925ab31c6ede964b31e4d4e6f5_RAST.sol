/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

pragma solidity ^0.7.0;

contract RAST {
    string public name;
    string public symbol;
    uint8 public  decimals;
    uint public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) internal allowed;

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    constructor() public {
        totalSupply = 500000000000000000000000000; 
        name = "Roll A Snowball";
        symbol = "RAST";
        decimals = 18;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(msg.sender != _to, "Transfer money to yourself?");
        require(_to != address(0), "Please make sure the address is correct!");
        require(_value <= balanceOf[msg.sender], "Insufficient amount!");
        require(balanceOf[_to] + _value >= balanceOf[_to], "The recipient amount has reached the upper limit!");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
        require(_from != _to, "_from and _to use the same address!");
        require(_to != address(0), "Please make sure the address is correct!");
        require(_value <= balanceOf[_from], "Insufficient amount!");
        require(_value <= allowed[_from][msg.sender], "Insufficient amount!transferFrom");
        require(balanceOf[_to] + _value >= balanceOf[_to], "The recipient amount has reached the upper limit!");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)public  returns (bool) {
        require(_spender != address(0), "Please make sure the address is correct!");
        require(_spender != msg.sender, "Only other users can be authorized!");

        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)public  view returns (uint256) {
        require(_owner != _spender, "Only other users can be authorized!");
        
        return allowed[_owner][_spender];
    }

}