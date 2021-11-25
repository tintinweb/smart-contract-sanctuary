/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity ^0.8.4;

contract DeathCoin {
    //BEP20 standard compliance
    string public name = "RageCoin";
    string public symbol = "RAGE";
    uint8 public decimals = 4;
    uint256 public totalSupply = 1 * (10 ** 4);
    address public owner;
    address[] public holders;
    
    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function renounce() external onlyOwner {
        owner = address(0);
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender]>=_value, "You do not have enough RAGE.");
        
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowances[msg.sender][_from] >=_value, "You cannot spend this much of the owner's RAGE.");
        
        balances[_to] += _value;
        balances[_from] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}