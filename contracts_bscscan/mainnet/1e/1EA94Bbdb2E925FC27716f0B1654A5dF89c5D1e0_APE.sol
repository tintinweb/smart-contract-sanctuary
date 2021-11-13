/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity ^0.5.0;

//This works

contract APE {
    string  public name = "Baby Ape";
    string  public symbol = "BABYAPE";
    uint256 public totalSupply = 9000000*10**18; // 1 million tokens
    uint8   public decimals = 18;
    address public owner;

    event Transfer(
        address indexed _from,
        address indexed _to, 
        uint _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender, 
        uint _value
    );
    
    event Burn(
        address indexed _owner,
        uint _value
    );
    
    event Mint(
        address indexed _owner,
        uint _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        owner=msg.sender;
    }
    
    function burn(uint256 _value) public returns (bool success){
        require(msg.sender==owner);
        balanceOf[msg.sender] -= _value;
        totalSupply-=_value;
        emit Burn(msg.sender,_value);
        return true;
    }
    
    function mint(uint256 _value) public returns (bool success){
        require(msg.sender==owner);
        balanceOf[msg.sender] += _value;
        totalSupply+=_value;
        emit Mint(msg.sender,_value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require that the value is greater or equal for transfer
        require(balanceOf[msg.sender] >= _value);
         // transfer the amount and subtract the balance
        balanceOf[msg.sender] -= _value;
        // add the balance
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        // add the balance for transferFrom
        balanceOf[_to] += _value;
        // subtract the balance for transferFrom
        balanceOf[_from] -= _value;
        allowance[msg.sender][_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}