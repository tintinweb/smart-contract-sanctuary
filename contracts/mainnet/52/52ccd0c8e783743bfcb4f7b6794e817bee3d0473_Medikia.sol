pragma solidity ^0.4.11;

 

contract Medikia  {

 

    string public name = "Medikia";      //  (token name)

    string public symbol = "MDK";           //  (token symbol)

    uint256 public decimals = 8;            //   (token digit)

 

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

 

    uint256 public totalSupply = 20000000 * (10**decimals);   // (total supply)

    address owner;

 

    modifier isOwner {

        assert(owner == msg.sender);

        _;

    }

    function Medikia () {

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

   

    function setName(string _name) isOwner

    {

        name = _name;

    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}