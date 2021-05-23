/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity >=0.7.0 <0.8.0;

contract Token{
    string  public name = "SafeGood";
    string  public symbol = "SGOOD";
    uint256 public totalsupply = 1000000000000000000000000;
    uint8   public decimals = 18;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    
    event Approval(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() public {
        balanceOf[msg.sender] = totalsupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferfrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    
}