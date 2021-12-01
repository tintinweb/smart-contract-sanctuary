/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity ^0.4.11;

contract BudCoin {

    string public name = "Bud Coin";      //  token name
    string public symbol = "BDC";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0 * (10**decimals);
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event SupplyBurn(uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }
    function BudCoin() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function TransferOwnership(address newOwner) isOwner 
    {
       require(newOwner != address(0));
       OwnershipTransferred(owner, newOwner);
       owner = newOwner;
    }

    function setName(string _name) isOwner 
    {
        name = _name;
    }
    function setSymbol(string _symbol) isOwner 
    {
        symbol = _symbol;
    }
    function burnSupply(uint256 _amount) isOwner
    {
        balanceOf[owner] -= _amount;
        SupplyBurn(_amount);
    }
    function burnTotalSupply(uint256 _amount) isOwner
    {
        totalSupply-= _amount;
    }
    function mintedTotal(uint256 _amount) isOwner
    {
        totalSupply+= _amount;
        balanceOf[owner] += _amount;
    }
    function mintedTo(uint256 _amount, address _to) isOwner
    {
        totalSupply+= _amount;
        balanceOf[_to] += _amount;
    }
}